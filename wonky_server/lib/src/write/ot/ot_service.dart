import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/config/wonky_config.dart';
import '../collab/overlay_lifecycle.dart';
import 'cell_upgrader.dart';
import 'document_bus.dart';
import 'document_cache.dart';
import 'document_store.dart';

/// Thrown by [OtService.submit] when an op is rejected (sent to the client
/// as `DocOpRejected`).
class OpRejection implements Exception {
  OpRejection(this.code, this.message);
  final DocRejectCode code;
  final String message;

  @override
  String toString() => 'OpRejection(${code.name}: $message)';
}

/// Result of a committed (or idempotently re-acknowledged) op.
class CommittedOp {
  CommittedOp(
    this.revision,
    this.delta, {
    this.duplicate = false,
    Future<void>? sideEffects,
  }) : sideEffects = sideEffects ?? Future.value();
  final int revision;
  final Delta delta;
  final bool duplicate;

  /// Completes when the post-commit side effects of the op have run (they
  /// run after the per-document lock is released). Never fails.
  final Future<void> sideEffects;
}

/// Server-authoritative OT (Write 03 §2).
abstract final class OtService {
  static const statsEvery = 50;

  /// Ops larger than this (UTF-8 bytes of `deltaJson`) are rejected with
  /// `tooLarge` before they are decoded (Write 03 §2).
  static const maxOpBytes = 1024 * 1024;

  /// Ops with more components than this are rejected with `tooLarge`
  /// before they are transformed under the document lock.
  static const maxOpComponents = 20000;

  /// The unique index on `(documentId, clientOpId)`.
  static const _clientOpIndex = 'document_op_client_idx';

  /// Applies a client op based on [baseRevision].
  ///
  /// 1. idempotency on [clientOpId] (checked again under the row lock);
  /// 2. role, size and op shape; 3. row lock; 4. transform against ops
  /// since the base (server ops win ties); 5. normalize + validate;
  /// 6. persist op, inverse and head; 7. fan-out; 8. after the lock is
  /// released: snapshots and the overlay lifecycle queued in commit order
  /// per document, and the activity, version and drive bookkeeping counted
  /// in memory and written in batches ([DocumentState.edits]).
  ///
  /// With [awaitSideEffects] (the default, for server-side callers that
  /// read their results) the call returns once the side effects ran and
  /// the bookkeeping was written;
  /// editing connections pass false and acknowledge right after the
  /// commit. [enforceOpLimits] applies [maxOpBytes] and [maxOpComponents]
  /// (off for server-computed changes such as restores). With [atHead] the
  /// op must be based on the head: it is rejected with `rebaseTooOld`
  /// instead of being transformed (server changes computed from the head
  /// that must not be rebased, such as the table upgrade).
  ///
  /// An op of a system actor (`ActorKind.system`) is stored and broadcast
  /// without an author and adds no edit bookkeeping. After an op whose
  /// result still holds a legacy table or grid embed, the upgrade is queued
  /// ([CellUpgrader], Write 12 §1.5).
  static Future<CommittedOp> submit(
    Session session, {
    required Actor actor,
    required Document document,
    required DriveItem item,
    required Role role,
    required UuidValue clientOpId,
    required int baseRevision,
    required String deltaJson,
    DocumentOpKind kind = DocumentOpKind.content,
    String? sessionId,
    String? groupId,
    String? onBehalfOfSessionId,
    bool awaitSideEffects = true,
    bool enforceOpLimits = true,
    bool atHead = false,
  }) async {
    final system = actor.kind == ActorKind.system;
    final duplicate = await _duplicate(session, document, clientOpId);
    if (duplicate != null) return duplicate;
    if (role < Role.commenter) {
      throw OpRejection(
        DocRejectCode.forbiddenForRole,
        'Viewers cannot edit this document.',
      );
    }
    if (enforceOpLimits && _utf8Length(deltaJson) > maxOpBytes) {
      throw OpRejection(
        DocRejectCode.tooLarge,
        'The change is too large (more than ${maxOpBytes ~/ 1024} KiB).',
      );
    }
    Delta incoming;
    try {
      incoming = DocumentStore.decodeDelta(deltaJson);
    } on Object {
      throw OpRejection(
        DocRejectCode.invalidOp,
        'The op is not a valid delta.',
      );
    }
    final components = incoming.toList();
    if (enforceOpLimits && components.length > maxOpComponents) {
      throw OpRejection(
        DocRejectCode.tooLarge,
        'The change has too many parts (more than $maxOpComponents).',
      );
    }
    if (components.any(
      (o) => (o.length ?? 0) <= 0 && !(o.isInsert && o.data is Map),
    )) {
      throw OpRejection(
        DocRejectCode.invalidOp,
        'Empty operations are invalid.',
      );
    }

    final state = await DocumentCache.of(session, document);
    var legacy = false;
    final committed = await state.lock(() async {
      final now = nowUtc();
      _Commit? commit;
      CommittedOp? resent;
      try {
        await session.db.transaction((tx) async {
          final locked = await Document.db.findById(
            session,
            document.id!,
            transaction: tx,
            lockMode: LockMode.forUpdate,
          );
          if (locked == null) {
            DocumentCache.evict(document.uuid, deleted: true);
            throw OpRejection(
              DocRejectCode.invalidOp,
              'The document was deleted.',
            );
          }
          // A resend of the same op may have committed (another socket or
          // instance) after the check above: the row lock orders this
          // transaction after it, so it is visible now.
          resent = await _duplicate(
            session,
            document,
            clientOpId,
            transaction: tx,
          );
          if (resent != null) return;
          if (atHead && baseRevision != locked.headRevision) {
            throw OpRejection(
              DocRejectCode.rebaseTooOld,
              'The document changed since revision $baseRevision.',
            );
          }
          await state.catchUp(session, locked.headRevision, transaction: tx);
          commit = await _apply(
            session,
            tx,
            state,
            document: document,
            actor: actor,
            role: role,
            incoming: incoming,
            baseRevision: baseRevision,
            head: locked.headRevision,
            now: now,
          );
          await DocumentOp.db.insertRow(
            session,
            DocumentOp(
              documentId: document.id!,
              revision: commit!.revision,
              clientOpId: clientOpId,
              authorId: system ? null : actor.userId,
              actorKind: actor.kind,
              sessionId: sessionId,
              kind: kind,
              baseRevision: baseRevision,
              deltaJson: commit!.opJson,
              inverseJson: jsonEncode(commit!.inverse.toJson()),
              createdAt: now,
            ),
            transaction: tx,
          );
          final revision = commit!.revision;
          final text = revision % statsEvery == 0
              ? DeltaUtils.text(commit!.after)
              : null;
          await Document.db.updateWhere(
            session,
            columnValues: (t) => [
              t.headRevision(revision),
              t.updatedAt(now),
              if (text != null) t.charCount(text.length),
              if (text != null) t.wordCount(DocumentStore.wordCount(text)),
            ],
            where: (t) => t.id.equals(document.id!),
            transaction: tx,
          );
        });
      } on DatabaseQueryException catch (e) {
        // Backstop for the check under the lock: a concurrent insert of
        // the same clientOpId is a resend, not an error.
        if (!_isClientOpConflict(e)) rethrow;
        resent = await _duplicate(session, document, clientOpId);
        if (resent == null) rethrow;
      }
      if (resent != null) return resent!;
      final c = commit!;

      // Committed: update the in-memory state.
      final transitions = state.overlays.apply(c.op, c.inverse);
      state.content = c.after;
      state.revision = c.revision;
      state.remember(c.revision, c.op);

      try {
        await DocumentBus.post(
          session,
          document.uuid,
          DocBusMessage(
            type: 'op',
            originSessionId: sessionId,
            op: DocRemoteOp(
              revision: c.revision,
              deltaJson: c.opJson,
              authorId: system ? null : actor.userId,
              authorUuid: system ? null : actor.authUserId,
              authorSessionId: sessionId,
              actorKind: actor.kind,
              kind: kind,
              onBehalfOfSessionId: onBehalfOfSessionId,
              groupId: groupId,
            ),
          ),
        );
      } on Object catch (e, st) {
        // Committed anyway: other sessions fill the gap on the next op.
        session.log(
          'Publishing ${document.uuid} r${c.revision} failed: $e',
          level: LogLevel.error,
          stackTrace: st,
        );
      }
      // Bookkeeping (activity, versions, drive) is only counted here and
      // written in batches; the per-op work is queued. System ops (the
      // table upgrade) are nobody's edit.
      if (!system) {
        state.edits.add(
          session,
          item,
          actor,
          op: c.op,
          revision: c.revision,
          after: c.after,
        );
      }
      legacy =
          kind != DocumentOpKind.system &&
          !state.upgradeBlocked &&
          CellUpgrade.hasLegacy(c.after);
      final snapshot = c.revision % WonkyConfig.current.snapshotEveryNOps == 0;
      final effects = snapshot || transitions.isNotEmpty
          ? state.runSideEffect(
              () => _afterCommit(
                session,
                document,
                item,
                actor,
                before: c.before,
                op: c.op,
                after: c.after,
                revision: c.revision,
                snapshot: snapshot,
                transitions: transitions,
              ),
            )
          : null;
      return CommittedOp(c.revision, c.op, sideEffects: effects);
    });
    // Old clients and restores can still write legacy embeds (Write 12
    // §1.5): upgrade them right after this op. [DocumentState.settle]
    // waits for the upgrade.
    if (legacy) {
      unawaited(CellUpgrader.schedule(session, document, state, item: item));
    }
    if (awaitSideEffects) {
      await committed.sideEffects;
      await state.settle();
    }
    return committed;
  }

  /// Steps 4–5 of [submit]: transforms [incoming] to the head, checks it
  /// and normalizes it.
  static Future<_Commit> _apply(
    Session session,
    Transaction tx,
    DocumentState state, {
    required Document document,
    required Actor actor,
    required Role role,
    required Delta incoming,
    required int baseRevision,
    required int head,
    required DateTime now,
  }) async {
    if (baseRevision > head) {
      throw OpRejection(
        DocRejectCode.unknownBase,
        'Revision $baseRevision does not exist yet.',
      );
    }
    var transformed = incoming;
    if (baseRevision < head) {
      var since = state.opsSince(baseRevision);
      if (since == null) {
        final ops = await DocumentOp.db.find(
          session,
          where: (t) =>
              t.documentId.equals(document.id!) &
              (t.revision > baseRevision) &
              (t.revision <= head),
          orderBy: (t) => t.revision,
          transaction: tx,
        );
        if (ops.length != head - baseRevision) {
          throw OpRejection(
            DocRejectCode.rebaseTooOld,
            'The change is based on a revision that is no longer kept.',
          );
        }
        since = [for (final o in ops) DocumentStore.decodeDelta(o.deltaJson)];
      }
      transformed = WonkyOt.rebaseOnServer(incoming, since);
    }
    final before = state.content;
    if (DeltaUtils.baseLength(transformed) >
        DeltaUtils.documentLength(before)) {
      throw OpRejection(
        DocRejectCode.invalidOp,
        'The change does not fit the document.',
      );
    }
    if (role < Role.editor) {
      final violation = OpShapeValidator.validateCommenterOp(
        before,
        transformed,
        actor.authUserId.uuid,
      );
      if (violation != null) {
        throw OpRejection(
          DocRejectCode.forbiddenForRole,
          'Commenters can only comment and suggest: ${violation.message}',
        );
      }
    }
    final NormalizeChangeResult normalized;
    try {
      normalized = const WonkyDeltaNormalizer().normalizeChange(
        before,
        transformed,
        suggestionTimestamp: now.millisecondsSinceEpoch,
      );
    } on Object catch (e) {
      throw OpRejection(
        DocRejectCode.invalidOp,
        'The change is invalid: $e',
      );
    }
    final after = normalized.document;
    final validation = WonkyDeltaValidator(
      maxDocumentChars: WonkyConfig.current.maxDocumentChars,
    ).validate(after);
    if (!validation.isValid) {
      final tooLong =
          DeltaUtils.documentLength(after) >
          WonkyConfig.current.maxDocumentChars;
      throw OpRejection(
        tooLong ? DocRejectCode.tooLarge : DocRejectCode.invalidOp,
        tooLong
            ? 'The document would exceed the maximum length.'
            : 'The result is not a valid document: $validation',
      );
    }
    final op = normalized.change;
    return _Commit(
      revision: head + 1,
      before: before,
      op: op,
      opJson: jsonEncode(op.toJson()),
      after: after,
      inverse: WonkyOt.invert(op, before),
    );
  }

  /// The committed op of [clientOpId], as a duplicate acknowledgement.
  static Future<CommittedOp?> _duplicate(
    Session session,
    Document document,
    UuidValue clientOpId, {
    Transaction? transaction,
  }) async {
    final row = await DocumentOp.db.findFirstRow(
      session,
      where: (t) =>
          t.documentId.equals(document.id!) & t.clientOpId.equals(clientOpId),
      transaction: transaction,
    );
    if (row == null) return null;
    return CommittedOp(
      row.revision,
      DocumentStore.decodeDelta(row.deltaJson),
      duplicate: true,
    );
  }

  static bool _isClientOpConflict(DatabaseQueryException e) =>
      e.code == '23505' &&
      (e.constraintName == _clientOpIndex ||
          e.message.contains(_clientOpIndex));

  /// UTF-8 length of [s], computed only when it could exceed [maxOpBytes].
  static int _utf8Length(String s) {
    if (s.length > maxOpBytes) return s.length;
    if (s.length * 3 <= maxOpBytes) return s.length;
    return utf8.encode(s).length;
  }

  /// Per-op post-commit work, queued per document after the lock is
  /// released: a snapshot every `snapshotEveryNOps` revisions and the
  /// comment/suggestion thread lifecycle of overlay transitions. Never
  /// throws: a failure is logged and the next op's side effects still run.
  static Future<void> _afterCommit(
    Session session,
    Document document,
    DriveItem item,
    Actor actor, {
    required Delta before,
    required Delta op,
    required Delta after,
    required int revision,
    required bool snapshot,
    required List<OverlayTransition> transitions,
  }) async {
    try {
      if (snapshot) {
        await DocumentStore.writeSnapshot(session, document, revision, after);
      }
      await OverlayLifecycle.handle(
        session,
        item: item,
        documentUuid: document.uuid,
        actor: actor,
        before: before,
        op: op,
        transitions: transitions,
      );
    } on Object catch (e, st) {
      session.log(
        'Post-commit work for ${document.uuid} r$revision failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    }
  }

  /// Transforms a selection given at [revision] to the head of [state].
  static (int, int) transformCursor(
    DocumentState state,
    int revision,
    int anchor,
    int head,
  ) {
    final ops = state.opsSince(revision);
    if (ops == null) return (anchor, head);
    var a = anchor;
    var h = head;
    for (final op in ops) {
      a = WonkyOt.transformPosition(op, a);
      h = WonkyOt.transformPosition(op, h);
    }
    final length = DeltaUtils.documentLength(state.content);
    return (a.clamp(0, length - 1), h.clamp(0, length - 1));
  }

  /// Submits a server-computed change on behalf of [actor] (restores, MCP,
  /// AI), based on the current head.
  static Future<CommittedOp> submitServerChange(
    Session session, {
    required Actor actor,
    required Document document,
    required DriveItem item,
    required Delta Function(Delta head) build,
    DocumentOpKind kind = DocumentOpKind.content,
    String? groupId,
    String? onBehalfOfSessionId,
  }) async {
    final state = await DocumentCache.of(session, document);
    final fresh = await Document.db.findById(session, document.id!);
    await state.lock(() => state.catchUp(session, fresh!.headRevision));
    final head = state.content;
    final change = build(head);
    return submit(
      session,
      actor: actor,
      document: document,
      item: item,
      role: Role.owner,
      clientOpId: const Uuid().v7obj(),
      baseRevision: state.revision,
      deltaJson: jsonEncode(change.toJson()),
      kind: kind,
      sessionId: actor.sessionId,
      groupId: groupId,
      onBehalfOfSessionId: onBehalfOfSessionId,
      // A restore can differ from the head in every paragraph.
      enforceOpLimits: false,
    );
  }
}

/// An op ready to be persisted (steps 4–5 of [OtService.submit]).
class _Commit {
  _Commit({
    required this.revision,
    required this.before,
    required this.op,
    required this.opJson,
    required this.after,
    required this.inverse,
  });

  final int revision;
  final Delta before;
  final Delta op;
  final String opJson;
  final Delta after;
  final Delta inverse;
}
