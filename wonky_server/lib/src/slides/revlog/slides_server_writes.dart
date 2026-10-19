import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/rows.dart' show RowChange, RowOp;
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/ops.dart' show SlidesChangeSummary;
import 'package:wonky_slides_core/schema.dart' show SlidesUndoHooks;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/keyed_lock.dart';
import '../../platform/common/models.dart';
import '../../platform/revlog/headless_file_cache.dart';
import '../../platform/revlog/rev_file_state.dart';
import '../../platform/revlog/rev_log_service.dart';
import '../../platform/revlog/server_change_records.dart';
import '../../platform/sharing/access_service.dart';
import 'slides_rev_binding.dart';
import 'slides_revlog.dart';

/// Outcome of a server write to a deck.
class DeckAppliedChanges {
  DeckAppliedChanges(this.applied, this.skipped, this.revision);

  /// The applied forms (with the previous values): their inverse undoes
  /// exactly what was written.
  final List<RowChange> applied;

  /// Columns/rows not written by a revert (changed by others, deleted).
  final List<RevertSkip> skipped;

  /// The last committed revision (0 when nothing was committed).
  final int revision;
}

/// A recorded server write ([SlidesServerWrites.applyRecorded]).
class DeckRecordedWrite {
  DeckRecordedWrite(this.changeId, this.result);

  /// The `ServerChangeRecord.changeId` (`slides.revertChange`, MCP
  /// `changes.revert`); null when nothing changed.
  final UuidValue? changeId;

  /// What was written.
  final DeckAppliedChanges result;

  /// MCP `sync_version`: the revision of the write as a string, like Sheets
  /// (null when nothing was
  /// written).
  String? get syncVersion => result.revision == 0 ? null : '${result.revision}';
}

/// Server-originated deck changes over RevLog (RevLog spec 05 §8, 08 §7):
/// MCP, AI, maintenance repairs, version restores, reverts and the drive
/// title mirror. Recorded writes join their ops with a record id and store
/// a [ServerChangeRecord] so `slides.revertChange` / MCP `changes.revert`
/// can undo them from the ops' applied forms.
abstract final class SlidesServerWrites {
  /// Fails a waiting [withWriteLock] after this long.
  static Duration get lockTimeout => _lock.timeout;
  static set lockTimeout(Duration v) => _lock.timeout = v;

  static final _lock = KeyedLock();

  /// Runs [body] holding the planning lock of the deck [fileUuid] (Slides
  /// 11 §2.1: server-side planners of one deck are serialized per
  /// instance). `busy` after [lockTimeout].
  static Future<T> withWriteLock<T>(
    UuidValue fileUuid,
    Future<T> Function() body,
  ) => _lock.run(
    fileUuid.uuid,
    body,
    busy: () => Errors.busy(
      'Another change to this presentation is still running. Try again.',
    ),
  );

  /// Commits [changes] (planner order) as [actor] to the deck [fileUuid].
  ///
  /// With [skipChanged] (revert/reapply/AI apply), a column whose current
  /// value differs from the change's `before` is not written
  /// (`changed_by_other`) — together with its coupled columns (02 P4) — a
  /// reverted table-cell insert keeps the columns others changed, updates
  /// of deleted rows are reported (`row_deleted`) and inserts of existing
  /// rows write all their columns.
  ///
  /// With [revives] (default: [skipChanged]) inserts count as *revived* in
  /// the summary (undo of a delete), so comment threads orphaned by the
  /// deletion come back (09 §3.2). [repair] marks maintenance repairs
  /// (`"repair": true`, 03 §6).
  static Future<DeckAppliedChanges> apply(
    Session session, {
    required Actor actor,
    required UuidValue fileUuid,
    required List<RowChange> changes,
    required String label,
    SlidesChangeSummary? summary,
    Map<String, Object?>? detail,
    bool skipChanged = false,
    bool? revives,
    bool repair = false,
    UuidValue? recordId,
    String? onBehalfOfSessionId,
  }) async {
    final binding = SlidesRevBinding.instance;
    final state = await RevFileStates.of(session, binding, fileUuid);
    if (state == null) throw Errors.notFound('Presentation');
    final lease = RevFileStates.retain(state);
    final models = HeadlessModelAccess(session, binding, fileUuid);
    try {
      final revived = revives ?? skipChanged;
      final skipped = <RevertSkip>[];
      var toApply = changes;
      DeckModel? current;
      if (skipChanged || summary == null) {
        current = await SlidesRevlog.model(session, fileUuid);
      }
      if (skipChanged) toApply = _skipChanged(current!, changes, skipped);
      if (toApply.isEmpty) return DeckAppliedChanges(const [], skipped, 0);
      final s =
          summary ??
          SlidesChangeSummary.of(
            toApply,
            current: current,
            wasDeleted: revived ? (_, _) => true : null,
          );
      final result = await RevLogService.submitServerChange(
        session,
        binding: binding,
        state: state,
        submitter: RevSubmitter(
          userId: actor.userId,
          authUuid: actor.authUserId,
          sessionId: 'server:${actor.kind.name}',
          onBehalfOfSessionId: onBehalfOfSessionId ?? actor.sessionId,
        ),
        actorKind: actor.kind.name,
        label: label,
        changes: toApply,
        summary: {...s.toJson(), if (repair) 'repair': true},
        detail: detail,
        recordId: recordId,
        models: models,
      );
      return DeckAppliedChanges(
        [for (final c in result.commits) ...?c.applied],
        skipped,
        result.toRevision,
      );
    } on RevRejection catch (r) {
      throw toWonky(r);
    } finally {
      models.release();
      lease.release();
    }
  }

  /// The app error of a RevLog rejection.
  static WonkyException toWonky(RevRejection r) => switch (r.reason) {
    RevRejectReason.forbidden ||
    RevRejectReason.forbiddenForRole ||
    RevRejectReason.fileReadOnly => Errors.forbidden(r.message),
    RevRejectReason.limitExceeded => Errors.limit(r.message),
    RevRejectReason.notFound => Errors.notFound('Presentation'),
    RevRejectReason.tooLarge => Errors.tooLarge(r.message),
    _ => Errors.invalid(r.message),
  };

  // ------------------------------------------------------------ skip rule

  /// Identity columns never compared by the revert skip rule.
  static const _keyColumns = {
    'id',
    'elementId',
    'rowId',
    'columnId',
    'createdAt',
  };

  static Object? _jsonValue(Object? v) => switch (v) {
    DateTime() => v.toUtc().toIso8601String(),
    UuidValue() => v.uuid,
    String() when v.length > 19 && v[10] == 'T' => _isoUtc(v),
    _ => v,
  };

  static String _isoUtc(String v) {
    final t = DateTime.tryParse(v);
    return t == null ? v : t.toUtc().toIso8601String();
  }

  static bool _same(Object? a, Object? b) {
    final x = _jsonValue(a), y = _jsonValue(b);
    if (x is num && y is num) return x == y;
    return jsonEncode(x) == jsonEncode(y);
  }

  static RevertSkip _skip(RowChange c, String column, String reason) =>
      RevertSkip(
        table: c.table,
        rowId: UuidValue.fromString(c.rowId),
        column: column,
        reason: reason,
      );

  static List<RowChange> _skipChanged(
    DeckModel model,
    List<RowChange> changes,
    List<RevertSkip> skipped,
  ) {
    final out = <RowChange>[];
    // Rows inserted by earlier changes of this list (no current row yet).
    final inserted = <(String, String)>{};
    for (final c in changes) {
      final cur = inserted.contains((c.table, c.rowId))
          ? null
          : model.currentColumns(c.table, c.rowId);
      switch (c.op) {
        case RowOp.delete:
          if (cur == null) continue;
          final identity = SlidesUndoHooks.columnwise.identityColumns(c.table);
          if (identity != null) {
            // Reverting a cell insert: values others changed since stay.
            final changed = {
              for (final e in c.columnsBefore.entries)
                if (!_keyColumns.contains(e.key) &&
                    !identity.contains(e.key) &&
                    !_same(cur[e.key], e.value))
                  e.key,
            };
            if (changed.isNotEmpty) {
              for (final col in changed) {
                skipped.add(_skip(c, col, 'changed_by_other'));
              }
              final clear = {
                for (final e in c.columnsBefore.entries)
                  if (!_keyColumns.contains(e.key) &&
                      !identity.contains(e.key) &&
                      !changed.contains(e.key) &&
                      e.value != null)
                    e.key: null,
              };
              if (clear.isNotEmpty) {
                out.add(
                  RowChange.update(c.table, c.rowId, {
                    for (final k in clear.keys) k: cur[k],
                  }, clear),
                );
              }
              continue;
            }
          }
          out.add(RowChange.delete(c.table, c.rowId, cur));
        case RowOp.insert:
          if (cur == null) {
            inserted.add((c.table, c.rowId));
            out.add(c);
            continue;
          }
          // The row exists: write every column (an insert merge would
          // leave the columns it sets to null).
          final after = <String, Object?>{};
          final before = <String, Object?>{};
          for (final e in c.columnsAfter.entries) {
            if (e.key == 'id' || _same(cur[e.key], e.value)) continue;
            after[e.key] = e.value;
            before[e.key] = cur[e.key];
          }
          if (after.isNotEmpty) {
            out.add(RowChange.update(c.table, c.rowId, before, after));
          }
        case RowOp.update:
          if (cur == null) {
            if (inserted.contains((c.table, c.rowId))) {
              out.add(c);
            } else {
              skipped.add(_skip(c, '*', 'row_deleted'));
            }
            continue;
          }
          // Skipped columns take their coupled group along (P4).
          final skip = <String>{};
          for (final e in c.columnsAfter.entries) {
            if (e.key == 'id' || !c.columnsBefore.containsKey(e.key)) continue;
            if (_same(cur[e.key], c.columnsBefore[e.key])) continue;
            skip.add(e.key);
            skip.addAll(
              SlidesUndoHooks.coupled.groupOf(c.table, e.key) ?? const {},
            );
          }
          final after = <String, Object?>{};
          final before = <String, Object?>{};
          for (final e in c.columnsAfter.entries) {
            if (e.key == 'id') continue;
            if (skip.contains(e.key)) {
              skipped.add(_skip(c, e.key, 'changed_by_other'));
              continue;
            }
            if (_same(cur[e.key], e.value)) continue;
            after[e.key] = e.value;
            before[e.key] = cur[e.key];
          }
          if (after.isNotEmpty) {
            out.add(RowChange.update(c.table, c.rowId, before, after));
          }
      }
    }
    return out;
  }

  // -------------------------------------------------------------- records

  /// Applies [changes] for [actor] on the deck [item] as one revertible
  /// change (a new record id joins its ops; the record lives [lifetime]).
  static Future<DeckRecordedWrite> applyRecorded(
    Session session, {
    required Actor actor,
    required DriveItem item,
    required List<RowChange> changes,
    required String label,
    SlidesChangeSummary? summary,
    Map<String, Object?>? detail,
    bool skipChanged = false,
    bool? revives,
    Duration lifetime = const Duration(hours: 24),
  }) async {
    final recordId = const Uuid().v7obj();
    final result = await apply(
      session,
      actor: actor,
      fileUuid: item.contentRef!,
      changes: changes,
      label: label,
      summary: summary,
      detail: detail,
      skipChanged: skipChanged,
      revives: revives,
      recordId: recordId,
    );
    if (result.applied.isEmpty) return DeckRecordedWrite(null, result);
    final changeId = await ServerChangeRecords.store(
      session,
      actor: actor,
      fileUuid: item.contentRef!,
      label: label,
      recordId: recordId,
      cellsAffected: result.applied.length,
      lifetime: lifetime,
    );
    return DeckRecordedWrite(changeId, result);
  }

  /// The forward changes of a record: the applied forms (with `before`) of
  /// its ops in revision order (empty once pruned).
  static Future<List<RowChange>> forward(
    Session session,
    ServerChangeRecord r,
  ) => ServerChangeRecords.forward(
    session,
    SlidesRevBinding.instance.codec,
    r,
  );

  /// The inverse changes of a record (reverse order).
  static Future<List<RowChange>> inverse(
    Session session,
    ServerChangeRecord r,
  ) => ServerChangeRecords.inverse(
    session,
    SlidesRevBinding.instance.codec,
    r,
  );

  /// The record [changeId] (with [orRevert], also the record a revert
  /// [changeId] reverted) and its deck, checked for Editor+.
  static Future<(ServerChangeRecord, DriveItem)> _recordAndItem(
    Session session,
    Actor actor,
    UuidValue changeId, {
    bool orRevert = false,
  }) async {
    final record = await ServerChangeRecords.find(
      session,
      changeId,
      orRevert: orRevert,
    );
    if (record == null) throw Errors.notFound('Change');
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) =>
          t.contentRef.equals(record.fileUuid) &
          t.kind.equals(DriveItemKind.presentation),
    );
    if (item == null) throw Errors.notFound('Change');
    await AccessService.requireRole(session, actor, item, Role.editor);
    ServerChangeRecords.requireLive(record);
    return (record, item);
  }

  /// Reverts a recorded deck change with the per-column skip rule
  /// (`slides.revertChange`, MCP `changes.revert`).
  static Future<RevertResult> revert(
    Session session,
    Actor actor,
    UuidValue changeId,
  ) async {
    final (record, item) = await _recordAndItem(session, actor, changeId);
    if (record.revertedAt != null) {
      throw Errors.conflict('The change was already undone.');
    }
    final inv = await inverse(session, record);
    if (inv.isEmpty) {
      throw Errors.expired('The change can no longer be undone.');
    }
    final write = await withWriteLock(
      item.contentRef!,
      () => applyRecorded(
        session,
        actor: actor,
        item: item,
        changes: inv,
        label: 'Undo ${record.label}',
        skipChanged: true,
      ),
    );
    final revertId = write.changeId ?? const Uuid().v7obj();
    await ServerChangeRecords.markReverted(session, record, revertId);
    return RevertResult(
      changeId: revertId,
      revertedCells: write.result.applied.length,
      skipped: write.result.skipped,
    );
  }

  /// Re-applies a reverted deck change (redo; [changeId] of the original
  /// or of its revert) with the same skip rule.
  static Future<RevertResult> reapply(
    Session session,
    Actor actor,
    UuidValue changeId,
  ) async {
    final (record, item) = await _recordAndItem(
      session,
      actor,
      changeId,
      orRevert: true,
    );
    final fwd = await forward(session, record);
    if (fwd.isEmpty) {
      throw Errors.expired('The change can no longer be redone.');
    }
    final write = await withWriteLock(
      item.contentRef!,
      () => applyRecorded(
        session,
        actor: actor,
        item: item,
        changes: fwd,
        label: record.label,
        skipChanged: true,
      ),
    );
    return RevertResult(
      changeId: write.changeId ?? const Uuid().v7obj(),
      revertedCells: write.result.applied.length,
      skipped: write.result.skipped,
    );
  }
}
