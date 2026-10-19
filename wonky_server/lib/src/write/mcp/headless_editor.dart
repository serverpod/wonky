import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/roles.dart';
import '../../platform/common/time.dart';
import '../../platform/config/wonky_config.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/users/user_service.dart';
import '../ot/document_bus.dart';
import '../ot/document_cache.dart';
import '../ot/document_service.dart';
import '../ot/document_store.dart';
import '../ot/ot_service.dart';
import '../../platform/cluster/cluster_bus.dart';

/// A Write document resolved for a tool call.
class WriteTarget {
  WriteTarget(this.document, this.item, this.role);

  final Document document;
  final DriveItem item;
  final Role role;
}

/// `expected_revision`, `mode` and `label` of mutating tools (Write 09 §1.2).
class MutationOptions {
  const MutationOptions({this.expectedRevision, this.mode, this.label});

  factory MutationOptions.of(ToolArgs a) => MutationOptions(
    expectedRevision: a.integer('expected_revision'),
    mode: a.string('mode'),
    label: a.string('label'),
  );

  final int? expectedRevision;

  /// `edit`, `suggest` or null (role default).
  final String? mode;
  final String? label;
}

/// How a change is applied.
enum HeadlessMode {
  /// A direct edit (Editors).
  edit,

  /// Rewritten into a suggestion (`sug_*` marks, `via: mcp`).
  suggest,

  /// Overlay-only changes (comment anchors) applied as they are.
  overlay,
}

/// The server-side OT client of headless tools (Write 09 §1.4): resolves
/// addresses against the head, builds one change with the shared
/// `DocumentEdits` builders, optionally rewrites it into a suggestion and
/// submits it through the same `OtService.submit` path as the apps
/// (`actorKind: mcp`, `clientOpId = change_id`), records a [HeadlessChange]
/// for `changes.revert` and shows the agent as a transient participant.
abstract final class HeadlessDocumentEditor {
  static const changeRetention = Duration(hours: 24);
  static const presenceTtl = Duration(seconds: 20);

  // ------------------------------------------------------------- resolving

  /// Resolves [uuid] (drive item uuid or document uuid) to a document the
  /// actor holds at least [min] on.
  static Future<WriteTarget> resolve(
    Session session,
    Actor actor,
    UuidValue uuid, {
    Role min = Role.viewer,
  }) async {
    var doc = await DocumentStore.byUuid(session, uuid);
    if (doc == null) {
      final item = await AccessService.findItem(session, uuid);
      if (item != null && item.kind == DriveItemKind.document) {
        doc = await DocumentStore.byItem(session, item.id!);
      } else if (item != null) {
        // Only reveal the kind to people with access.
        final role = await AccessService.effectiveRole(
          session,
          actor.userId,
          item,
        );
        if (role != null) {
          throw McpToolException(
            McpErrorCode.invalidArgs,
            'The item is a ${item.kind.name}, not a document.',
          );
        }
      }
    }
    if (doc == null) throw Errors.notFound('Document');
    final (d, item, role) = await DocumentService.require(
      session,
      actor,
      doc.uuid,
      min: min,
    );
    if (item.trashedAt != null && min > Role.viewer) {
      throw McpToolException(
        McpErrorCode.forbidden,
        'The document is in the trash. Restore it first (drive.restore).',
      );
    }
    return WriteTarget(d, item, role);
  }

  /// The current head of [doc] (caught up with the op log).
  static Future<DocumentState> head(Session session, Document doc) async {
    final state = await DocumentCache.of(session, doc);
    final fresh = await Document.db.findById(session, doc.id!);
    if (fresh == null) throw Errors.notFound('Document');
    await state.lock(() => state.catchUp(session, fresh.headRevision));
    return state;
  }

  // -------------------------------------------------------------- mutating

  /// Applies one change built by [build] against the head of [uuid].
  ///
  /// [build] receives the head and returns the change (normalized against
  /// that head). Returns the §1.3 result map (`change_id`, `revision`,
  /// `applied_range`, `suggestion_id`, `summary`, `warnings` plus the
  /// builder's extras).
  static Future<Map<String, Object?>> mutate(
    ToolContext ctx, {
    required UuidValue documentUuid,
    required String toolName,
    required MutationOptions options,
    required EditResult Function(Delta head, DocumentEdits edits) build,
    bool overlayOnly = false,
    bool allowSuggest = true,
    bool forceSuggest = false,
    Role minEditRole = Role.editor,
    DocumentOpKind kind = DocumentOpKind.content,
    int? baseRevisionOverride,
    String? defaultLabel,
    void Function(String changeId, int revision, Delta after)? afterCommit,
  }) async {
    final session = ctx.session;
    final target = await resolve(
      session,
      ctx.actor,
      documentUuid,
      min: Role.commenter,
    );
    final role = target.role;
    final HeadlessMode mode;
    if (overlayOnly) {
      mode = HeadlessMode.overlay;
    } else {
      final requested =
          options.mode ??
          (forceSuggest || role < minEditRole ? 'suggest' : 'edit');
      if (requested == 'edit') {
        if (role < minEditRole) {
          throw McpToolException(
            McpErrorCode.forbidden,
            role == Role.commenter
                ? 'You have comment access: use mode "suggest" to propose '
                      'changes.'
                : 'You do not have permission to edit this document.',
            details: {'role': role.name},
          );
        }
        mode = HeadlessMode.edit;
      } else {
        if (!allowSuggest) {
          throw McpToolException(
            McpErrorCode.unsupportedInSuggestMode,
            '$toolName cannot run in suggest mode.',
          );
        }
        mode = HeadlessMode.suggest;
      }
    }

    final state = await head(session, target.document);
    // Keeps this state cached until the change is committed and read back.
    DocumentCache.retain(state);
    try {
      final headDelta = state.content;
      final baseRevision = baseRevisionOverride ?? state.revision;
      if (baseRevision > state.revision) {
        throw McpToolException(
          McpErrorCode.revisionMismatch,
          'Revision $baseRevision does not exist yet (head is '
          '${state.revision}).',
          details: {'current_revision': state.revision},
        );
      }
      final expected = options.expectedRevision;
      if (expected != null && expected != state.revision) {
        throw McpToolException(
          McpErrorCode.revisionMismatch,
          'The document is at revision ${state.revision}, not $expected. '
          'Re-read it or use quote addressing.',
          details: {
            'current_revision': state.revision,
            'changes_since': await _changesSince(
              session,
              target.document,
              expected,
              state.revision,
            ),
          },
        );
      }

      final edits = DocumentEdits(
        maxDocumentChars: WonkyConfig.current.maxDocumentChars,
      );
      final result = build(headDelta, edits);
      final warnings = [
        for (final w in result.warnings)
          {'code': w.kind.name, 'message': w.message, 'line': ?w.line},
      ];
      if (result.isNoop) {
        return {
          'change_id': null,
          'revision': state.revision,
          'applied_range': result.appliedRange?.toJson(),
          'summary': result.summary.isEmpty
              ? 'Nothing to change'
              : '${result.summary} (no change)',
          'warnings': warnings,
          ...result.extra,
        };
      }

      // AI destructive guard (Write 09 §5.8) and similar checks.
      if (mode != HeadlessMode.overlay) {
        ctx.changeGuard?.call(headDelta, result.change, toolName);
      }

      final ai = ctx.actor.kind == ActorKind.ai;
      var change = result.change;
      String? suggestionId;
      if (mode == HeadlessMode.suggest) {
        suggestionId = const Uuid().v7();
        change = const SuggestionRewriter().rewrite(
          headDelta,
          change,
          SuggestionContext(
            userUuid: ctx.actor.authUserId.uuid,
            nowMs: clock.now().millisecondsSinceEpoch,
            suggestionId: suggestionId,
            via: ai ? 'ai' : 'mcp',
          ),
        );
      }

      final changeId = const Uuid().v7obj();
      final agentSession = await AgentPresence.sessionFor(ctx, target);
      final actor = ctx.actor.copyWith(sessionId: agentSession);
      final CommittedOp committed;
      try {
        committed = await OtService.submit(
          session,
          actor: actor,
          document: target.document,
          item: target.item,
          role: role,
          clientOpId: changeId,
          baseRevision: baseRevision,
          deltaJson: jsonEncode(change.toJson()),
          kind: ai && kind == DocumentOpKind.content
              ? DocumentOpKind.aiEdit
              : kind,
          sessionId: agentSession,
          groupId: ctx.groupId ?? changeId.uuid,
          onBehalfOfSessionId: ctx.onBehalfOfSessionId,
        );
      } on OpRejection catch (r) {
        throw McpToolException(switch (r.code) {
          DocRejectCode.forbiddenForRole => McpErrorCode.forbidden,
          DocRejectCode.tooLarge => McpErrorCode.tooLarge,
          _ => McpErrorCode.validationFailed,
        }, r.message);
      }
      final revision = committed.revision;

      // Offsets of the result in the committed revision: transform through
      // ops that landed between our base and our op.
      ResolvedRange? applied = result.appliedRange;
      if (mode == HeadlessMode.suggest && suggestionId != null) {
        applied = _suggestionRange(state.content, suggestionId) ?? applied;
      } else if (applied != null && revision > baseRevision + 1) {
        final between = [
          for (final op in state.recent)
            if (op.revision > baseRevision && op.revision < revision) op.delta,
        ];
        var (s, l) = (applied.start, applied.length);
        for (final op in between) {
          (s, l) = WonkyOt.transformRange(op, s, l);
        }
        applied = ResolvedRange(s, l);
      }

      final opRow = await DocumentOp.db.findFirstRow(
        session,
        where: (t) =>
            t.documentId.equals(target.document.id!) &
            t.clientOpId.equals(changeId),
      );
      await recordChange(
        session,
        HeadlessChange(
          changeId: changeId,
          kind: 'content',
          itemId: target.item.id!,
          documentId: target.document.id,
          revision: revision,
          inverseJson: opRow?.inverseJson,
          userId: ctx.actor.userId,
          actorKind: ctx.actor.kind,
          label: options.label ?? defaultLabel,
          toolName: toolName,
          createdAt: nowUtc(),
        ),
      );
      afterCommit?.call(changeId.uuid, revision, state.content);
      await AgentPresence.flash(ctx, target, agentSession, revision, applied);
      return {
        'change_id': changeId.uuid,
        'revision': revision,
        'applied_range': applied?.toJson(),
        'suggestion_id': ?suggestionId,
        'mode': mode.name,
        'summary': result.summary,
        'warnings': warnings,
        ...result.extra,
      };
    } finally {
      DocumentCache.release(state);
    }
  }

  static ResolvedRange? _suggestionRange(Delta doc, String id) {
    final info = SuggestionIndex.list(
      doc,
    ).where((s) => s.id == id).firstOrNull;
    if (info == null || info.parts.isEmpty) return null;
    final start = info.parts.first.start;
    final last = info.parts.last;
    return ResolvedRange(start, last.start + last.length - start);
  }

  static Future<String> _changesSince(
    Session session,
    Document doc,
    int from,
    int to,
  ) async {
    if (from >= to) return 'The expected revision is ahead of the head.';
    final ops = await DocumentOp.db.find(
      session,
      where: (t) =>
          t.documentId.equals(doc.id!) &
          (t.revision > from) &
          (t.revision <= to),
      orderBy: (t) => t.revision,
      limit: 200,
    );
    final authors = await UserService.summaries(session, [
      for (final o in ops) o.authorId,
    ]);
    final names = {
      for (final o in ops) authors[o.authorId]?.displayName ?? o.actorKind.name,
    };
    return '${to - from} change(s) by ${names.join(', ')}';
  }

  // --------------------------------------------------------------- changes

  static DateTime _lastPurge = DateTime.fromMillisecondsSinceEpoch(0);

  /// Stores [change] and purges expired ones (at most every 10 minutes).
  static Future<void> recordChange(
    Session session,
    HeadlessChange change,
  ) async {
    await HeadlessChange.db.insertRow(session, change);
    final now = nowUtc();
    if (now.difference(_lastPurge) > const Duration(minutes: 10)) {
      _lastPurge = now;
      await HeadlessChange.db.deleteWhere(
        session,
        where: (t) => t.createdAt < now.subtract(changeRetention),
      );
    }
  }

  /// Records a metadata change (`write.update_page_setup`,
  /// `write.apply_theme`); returns its change id.
  static Future<String> recordMetaChange(
    ToolContext ctx,
    WriteTarget target, {
    required String toolName,
    required String field,
    required String beforeValueJson,
    required String afterValueJson,
    String? label,
  }) async {
    final id = const Uuid().v7obj();
    await recordChange(
      ctx.session,
      HeadlessChange(
        changeId: id,
        kind: 'meta',
        itemId: target.item.id!,
        documentId: target.document.id,
        metaField: field,
        metaBeforeJson: beforeValueJson,
        metaAfterJson: afterValueJson,
        userId: ctx.actor.userId,
        actorKind: ctx.actor.kind,
        label: label,
        toolName: toolName,
        createdAt: nowUtc(),
      ),
    );
    return id.uuid;
  }

  /// `changes.revert` (suite 09 §4): submits the inverse of a content change
  /// rebased through every later op (like undo), or restores the previous
  /// metadata value. The revert is itself a change (revertible).
  static Future<Map<String, Object?>> revert(
    ToolContext ctx,
    String changeId,
  ) async {
    final session = ctx.session;
    UuidValue id;
    try {
      id = UuidValue.withValidation(changeId);
    } on FormatException {
      throw McpToolException(McpErrorCode.invalidArgs, 'Invalid change_id.');
    }
    final change = await HeadlessChange.db.findFirstRow(
      session,
      where: (t) => t.changeId.equals(id),
    );
    if (change == null || change.userId != ctx.actor.userId) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Change not found. Only your own changes of the last 24 hours can '
        'be reverted.',
      );
    }
    if (nowUtc().difference(change.createdAt) > changeRetention) {
      throw McpToolException(
        McpErrorCode.expired,
        'Changes can only be reverted within 24 hours.',
      );
    }
    if (change.revertedAt != null) {
      throw McpToolException(
        McpErrorCode.conflict,
        'This change was already reverted.',
      );
    }
    final doc = change.documentId == null
        ? null
        : await Document.db.findById(session, change.documentId!);
    if (doc == null) throw Errors.notFound('Document');
    Map<String, Object?> result;
    if (change.kind == 'meta') {
      final target = await resolve(
        session,
        ctx.actor,
        doc.uuid,
        min: Role.editor,
      );
      final current = await Document.db.findById(session, doc.id!);
      final now = metaValueJson(current!, change.metaField!);
      await DocumentService.updateMeta(
        session,
        ctx.actor,
        doc.uuid,
        DocumentMetaPatch(
          field: change.metaField!,
          valueJson: change.metaBeforeJson!,
        ),
        const Uuid().v7obj(),
      );
      final newId = await recordMetaChange(
        ctx,
        target,
        toolName: 'changes.revert',
        field: change.metaField!,
        beforeValueJson: now,
        afterValueJson: change.metaBeforeJson!,
        label: 'Revert ${change.label ?? change.toolName}',
      );
      result = {
        'change_id': newId,
        'reverted_change_id': changeId,
        'document_uuid': target.item.uuid.uuid,
        'summary': 'Restored the previous ${change.metaField}',
      };
    } else {
      final target = await resolve(
        session,
        ctx.actor,
        doc.uuid,
        min: Role.commenter,
      );
      final inverse = DocumentStore.decodeDelta(change.inverseJson ?? '[]');
      final newId = const Uuid().v7obj();
      final agentSession = await AgentPresence.sessionFor(ctx, target);
      final CommittedOp committed;
      try {
        committed = await OtService.submit(
          session,
          actor: ctx.actor.copyWith(sessionId: agentSession),
          document: target.document,
          item: target.item,
          role: target.role,
          clientOpId: newId,
          baseRevision: change.revision!,
          deltaJson: jsonEncode(inverse.toJson()),
          sessionId: agentSession,
          groupId: newId.uuid,
        );
      } on OpRejection catch (r) {
        throw McpToolException(switch (r.code) {
          DocRejectCode.forbiddenForRole => McpErrorCode.forbidden,
          DocRejectCode.rebaseTooOld => McpErrorCode.expired,
          _ => McpErrorCode.conflict,
        }, 'The change cannot be reverted: ${r.message}');
      }
      final opRow = await DocumentOp.db.findFirstRow(
        session,
        where: (t) => t.documentId.equals(doc.id!) & t.clientOpId.equals(newId),
      );
      await recordChange(
        session,
        HeadlessChange(
          changeId: newId,
          kind: 'content',
          itemId: target.item.id!,
          documentId: doc.id,
          revision: committed.revision,
          inverseJson: opRow?.inverseJson,
          userId: ctx.actor.userId,
          actorKind: ctx.actor.kind,
          label: 'Revert ${change.label ?? change.toolName}',
          toolName: 'changes.revert',
          createdAt: nowUtc(),
        ),
      );
      await AgentPresence.flash(
        ctx,
        target,
        agentSession,
        committed.revision,
        null,
      );
      result = {
        'change_id': newId.uuid,
        'reverted_change_id': changeId,
        'document_uuid': target.item.uuid.uuid,
        'revision': committed.revision,
        'summary': committed.delta.isEmpty
            ? 'Nothing left to revert (the text was changed since)'
            : 'Reverted ${change.label ?? change.toolName}',
      };
    }
    await HeadlessChange.db.updateRow(
      session,
      change.copyWith(revertedAt: nowUtc()),
    );
    return result;
  }

  /// The JSON value of a metadata field (as `document.updateMeta` takes
  /// it).
  static String metaValueJson(Document doc, String field) => switch (field) {
    'themeId' => jsonEncode(doc.themeId?.uuid),
    'pageSetup' => doc.pageSetupJson,
    'language' => jsonEncode(doc.language),
    'frontMatter' => jsonEncode(doc.frontMatter),
    _ => 'null',
  };
}

/// Shows MCP agents as transient participants of a document (Write 08 §5):
/// one participant per user, document and agent, kept while calls continue
/// and removed [HeadlessDocumentEditor.presenceTtl] after the last one.
///
/// With several instances (specs/13 §4) calls of one agent may land on
/// different instances: the session id is derived from the user, document
/// and agent, so every instance announces the same participant, and active
/// agents re-announce themselves (`beat`) so the documents' heartbeat
/// expiry keeps them.
abstract final class AgentPresence {
  static final Map<String, _AgentEntry> _entries = {};

  /// How often an active agent re-announces itself.
  static Duration get _beatEvery => HeadlessDocumentEditor.presenceTtl ~/ 2;

  static String _key(ToolContext ctx, WriteTarget t) =>
      '${ctx.actor.userId}|${t.document.uuid.uuid}|${ctx.agentLabel}';

  /// The agent's session id on the document, announcing it when new.
  static Future<String> sessionFor(ToolContext ctx, WriteTarget target) async {
    final key = _key(ctx, target);
    final existing = _entries[key];
    if (existing != null) {
      existing.touch();
      final now = clock.now();
      if (now.difference(existing.announcedAt) >= _beatEvery) {
        existing.announcedAt = now;
        await DocumentBus.post(
          ctx.session,
          target.document.uuid,
          DocBusMessage(
            type: 'beat',
            originSessionId: existing.sessionId,
            participant: existing.participant,
          ),
        );
      }
      return existing.sessionId;
    }
    final summary = await UserService.summary(ctx.session, ctx.actor.userId);
    final sessionId =
        '${ctx.actor.kind == ActorKind.ai ? 'ai' : 'mcp'}-'
        '${const Uuid().v5(Namespace.url.value, 'wonky:agent:$key')}';
    final participant = Participant(
      sessionId: sessionId,
      userId: ctx.actor.userId,
      userUuid: ctx.actor.authUserId,
      displayName: '${summary?.displayName ?? 'User'} · ${ctx.agentLabel}',
      avatarUrl: summary?.avatarUrl,
      colorIndex: UserService.colorIndexFor(ctx.actor.authUserId),
      role: target.role.access,
      actorKind: ctx.actor.kind,
      state: PresenceState.active,
      joinedAt: nowUtc(),
    );
    final entry = _AgentEntry(sessionId, target.document.uuid, participant);
    _entries[key] = entry;
    entry.touch(
      onExpire: () {
        _entries.remove(key);
        unawaited(
          ClusterBus.postOn(
            Serverpod.instance,
            DocumentBus.channel(target.document.uuid),
            DocBusMessage(type: 'left', originSessionId: sessionId),
          ),
        );
      },
    );
    await DocumentBus.post(
      ctx.session,
      target.document.uuid,
      DocBusMessage(
        type: 'hello',
        originSessionId: sessionId,
        participant: participant,
      ),
    );
    return sessionId;
  }

  /// Moves the agent cursor to the end of [range] (a flash of the edit).
  static Future<void> flash(
    ToolContext ctx,
    WriteTarget target,
    String sessionId,
    int revision,
    ResolvedRange? range,
  ) async {
    if (range == null) return;
    await DocumentBus.post(
      ctx.session,
      target.document.uuid,
      DocBusMessage(
        type: 'cursor',
        originSessionId: sessionId,
        cursor: DocRemoteCursor(
          sessionId: sessionId,
          userId: ctx.actor.userId,
          revision: revision,
          anchor: range.start,
          head: range.end,
          focused: true,
        ),
      ),
    );
  }

  /// Forgets all agents (tests).
  static void clear() {
    for (final e in _entries.values) {
      e.timer?.cancel();
    }
    _entries.clear();
  }
}

class _AgentEntry {
  _AgentEntry(this.sessionId, this.documentUuid, this.participant)
    : announcedAt = clock.now();

  final String sessionId;
  final UuidValue documentUuid;
  final Participant participant;
  DateTime announcedAt;
  Timer? timer;
  void Function()? _onExpire;

  void touch({void Function()? onExpire}) {
    _onExpire = onExpire ?? _onExpire;
    timer?.cancel();
    timer = Timer(HeadlessDocumentEditor.presenceTtl, () => _onExpire?.call());
  }
}
