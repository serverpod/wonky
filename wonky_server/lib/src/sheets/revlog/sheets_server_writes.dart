import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/rows.dart' show RowChange, RowOp;
import 'package:wonky_sheets_core/model.dart'
    show ChangeKinds, ChangeSummary, SheetsTables;

import '../mcp/sheets_change_records.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/revlog/headless_file_cache.dart';
import '../../platform/revlog/rev_file_state.dart';
import '../../platform/revlog/rev_log_service.dart';
import '../../platform/revlog/server_change_records.dart';
import '../headless/headless_workbook.dart';
import 'sheets_rev_binding.dart';

/// Outcome of applying row changes server-side.
class AppliedChanges {
  AppliedChanges(this.applied, this.skipped, {this.recordId});

  /// The changes as applied (the applied forms, with the previous values).
  final List<RowChange> applied;

  /// Columns a revert/reapply left alone (changed by someone else).
  final List<RevertSkip> skipped;

  /// The record the ops joined (revertible changes).
  final UuidValue? recordId;

  int get cellsAffected =>
      applied.where((c) => c.table == SheetsTables.cell).length;
}

/// Server-originated spreadsheet changes over RevLog (RevLog spec 05 §8):
/// MCP, AI, scripts, imports, version restores and reverts.
abstract final class SheetsServerWrites {
  /// Identity columns never compared by the revert skip rule.
  static const _keyColumns = {
    'id',
    'sheetId',
    'rowId',
    'columnId',
    'createdAt',
  };

  /// Commits [changes] (planner order) as [actor] to the spreadsheet
  /// [fileUuid]. With [skipChanged] (revert/reapply), a column whose
  /// current value differs from the change's `before` is left alone and
  /// reported; a reverted cell insert keeps the columns others changed.
  /// Without [summary], it is computed from the changes plus [kinds] (the
  /// change kinds; `values` when empty).
  ///
  /// Server-side Sheets writes (scripts, MCP, imports, versions) all come
  /// here; this is the one entry point (the old `ServerSheetsWriter` facade
  /// is gone, CQ-56).
  static Future<AppliedChanges> apply(
    Session session, {
    required Actor actor,
    required UuidValue fileUuid,
    required List<RowChange> changes,
    required String label,
    ChangeSummary? summary,
    Set<String> kinds = const {},
    String? detailJson,
    bool skipChanged = false,
    UuidValue? recordId,
    String? onBehalfOfSessionId,
    void Function(int done, int total)? onProgress,
  }) async {
    final binding = SheetsRevBinding.instance;
    final state = await RevFileStates.of(session, binding, fileUuid);
    if (state == null) throw Errors.notFound('Spreadsheet');
    final lease = RevFileStates.retain(state);
    final models = HeadlessModelAccess(session, binding, fileUuid);
    try {
      var toApply = changes;
      final skipped = <RevertSkip>[];
      if (skipChanged) {
        final wb = await models.atPrevious() as HeadlessWorkbook;
        await state.ensureAtLeast(session, state.revision);
        toApply = _skipChanged(wb, changes, skipped);
      }
      final s =
          summary ?? (ChangeSummary.ofChanges(toApply)..kinds.addAll(kinds));
      if (s.kinds.isEmpty) s.kinds.add(ChangeKinds.values);
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
        summary: s.toJson(),
        detail: detailJson == null
            ? null
            : (jsonDecode(detailJson) as Map).cast<String, Object?>(),
        recordId: recordId,
        models: models,
        onProgress: onProgress,
      );
      return AppliedChanges(
        [for (final c in result.commits) ...?c.applied],
        skipped,
        recordId: recordId,
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
    RevRejectReason.protectedRange => Errors.protectedRange(
      r.message,
      detailsJson: r.details == null ? null : jsonEncode(r.details),
    ),
    RevRejectReason.limitExceeded => Errors.limit(r.message),
    RevRejectReason.notFound => Errors.notFound('Spreadsheet'),
    RevRejectReason.tooLarge => Errors.tooLarge(r.message),
    _ => Errors.invalid(r.message),
  };

  static List<RowChange> _skipChanged(
    HeadlessWorkbook wb,
    List<RowChange> changes,
    List<RevertSkip> skipped,
  ) {
    final model = wb.model;
    final out = <RowChange>[];
    String norm(Object? v) => jsonEncode(switch (v) {
      DateTime() => v.toUtc().millisecondsSinceEpoch,
      num() => v.toDouble(),
      _ => v,
    });
    for (final c in changes) {
      final cur = model.currentColumns(c.table, c.rowId);
      switch (c.op) {
        case RowOp.delete:
          if (cur == null) continue;
          if (c.table == SheetsTables.cell) {
            final changed = {
              for (final e in c.columnsBefore.entries)
                if (!_keyColumns.contains(e.key) &&
                    norm(cur[e.key]) != norm(e.value))
                  e.key,
            };
            if (changed.isNotEmpty) {
              for (final col in changed) {
                skipped.add(_skip(c, col, 'changed_by_other'));
              }
              final clear = {
                for (final e in c.columnsBefore.entries)
                  if (!_keyColumns.contains(e.key) &&
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
          out.add(c);
        case RowOp.insert:
          out.add(c);
        case RowOp.update:
          if (cur == null) {
            skipped.add(_skip(c, '*', 'row_deleted'));
            continue;
          }
          final after = <String, Object?>{};
          final before = <String, Object?>{};
          for (final e in c.columnsAfter.entries) {
            if (c.columnsBefore.containsKey(e.key) &&
                norm(cur[e.key]) != norm(c.columnsBefore[e.key])) {
              skipped.add(_skip(c, e.key, 'changed_by_other'));
              continue;
            }
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

  static RevertSkip _skip(RowChange c, String column, String reason) =>
      RevertSkip(
        table: c.table,
        rowId: UuidValue.fromString(c.rowId),
        column: column,
        reason: reason,
      );

  // -------------------------------------------------------------- records

  /// Commits [changes] as a revertible change: a new record id joins its
  /// ops, and a [ServerChangeRecord] lets `changes.revert` undo them.
  static Future<(UuidValue, AppliedChanges)> applyRecorded(
    Session session, {
    required Actor actor,
    required DriveItem item,
    required List<RowChange> changes,
    required String label,
    ChangeSummary? summary,
    String? detailJson,
    Duration lifetime = const Duration(hours: 24),
    bool skipChanged = false,
    void Function(int done, int total)? onProgress,
  }) async {
    final recordId = const Uuid().v7obj();
    final AppliedChanges applied;
    try {
      applied = await apply(
        session,
        actor: actor,
        fileUuid: item.contentRef!,
        changes: changes,
        label: label,
        summary: summary,
        detailJson: detailJson,
        skipChanged: skipChanged,
        recordId: recordId,
        onProgress: onProgress,
      );
    } on Object {
      // A large change commits in several ops (RevLog chunks); when a
      // later one fails the earlier ones stay. They get their record, so
      // the partial change can still be reverted (CQ-36).
      await recordPartial(
        session,
        actor: actor,
        item: item,
        label: label,
        recordId: recordId,
        lifetime: lifetime,
      );
      rethrow;
    }
    final changeId = await storeRecord(
      session,
      actor: actor,
      item: item,
      label: label,
      recordId: recordId,
      cellsAffected: applied.cellsAffected,
      lifetime: lifetime,
    );
    return (changeId, applied);
  }

  /// Stores the record of the ops of [recordId] that were committed before
  /// a failure, if there are any ("<label> (incomplete)"). Returns the
  /// change id, or null when nothing was committed.
  static Future<UuidValue?> recordPartial(
    Session session, {
    required Actor actor,
    required DriveItem item,
    required String label,
    required UuidValue recordId,
    Duration lifetime = const Duration(hours: 24),
  }) async {
    try {
      final committed = await RevOp.db.count(
        session,
        where: (t) => t.recordId.equals(recordId),
      );
      if (committed == 0) return null;
      return await storeRecord(
        session,
        actor: actor,
        item: item,
        label: '$label (incomplete)',
        recordId: recordId,
        cellsAffected: 0,
        lifetime: lifetime,
      );
    } on Object catch (e, st) {
      session.log(
        'Recording the partial change $recordId failed: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Stores the record of the ops of [recordId].
  static Future<UuidValue> storeRecord(
    Session session, {
    required Actor actor,
    required DriveItem item,
    required String label,
    required UuidValue recordId,
    required int cellsAffected,
    Duration lifetime = const Duration(hours: 24),
  }) => ServerChangeRecords.store(
    session,
    actor: actor,
    fileUuid: item.contentRef!,
    label: label,
    recordId: recordId,
    cellsAffected: cellsAffected,
    lifetime: lifetime,
  );

  /// The forward changes of a record: the applied forms (with `before`) of
  /// its ops in revision order.
  static Future<List<RowChange>> forward(
    Session session,
    ServerChangeRecord r,
  ) => ServerChangeRecords.forward(
    session,
    SheetsRevBinding.instance.codec,
    r,
  );

  /// The inverse changes of a record (reverse order).
  static Future<List<RowChange>> inverse(
    Session session,
    ServerChangeRecord r,
  ) => ServerChangeRecords.inverse(
    session,
    SheetsRevBinding.instance.codec,
    r,
  );

  static Future<ServerChangeRecord> _requireRecord(
    Session session,
    UuidValue changeId,
    DriveItem item,
  ) async {
    final record = await ServerChangeRecords.find(session, changeId);
    if (record == null || record.fileUuid != item.contentRef) {
      throw Errors.notFound('Change');
    }
    ServerChangeRecords.requireLive(record);
    return record;
  }

  /// Reverts a recorded change with the per-column skip rule (05 §8.2).
  static Future<RevertResult> revert(
    Session session,
    Actor actor,
    DriveItem item,
    UuidValue changeId,
  ) async {
    final record = await _requireRecord(session, changeId, item);
    if (record.revertedAt != null) {
      throw Errors.conflict('The change was already undone.');
    }
    // Legacy records (composite assistant changes) keep their inverse
    // inline or in a file.
    final inv = await SheetsChangeRecords.inverse(session, record);
    if (inv.isEmpty) {
      throw Errors.expired('The change can no longer be undone.');
    }
    final (revertId, result) = await applyRecorded(
      session,
      actor: actor,
      item: item,
      changes: inv,
      label: 'Undo ${record.label}',
      skipChanged: true,
    );
    await ServerChangeRecords.markReverted(session, record, revertId);
    return RevertResult(
      changeId: revertId,
      revertedCells: result.cellsAffected,
      skipped: result.skipped,
    );
  }

  /// Re-applies a reverted change (redo) with the same skip rule.
  static Future<RevertResult> reapply(
    Session session,
    Actor actor,
    DriveItem item,
    UuidValue changeId,
  ) async {
    final record = await _requireRecord(session, changeId, item);
    final fwd = await SheetsChangeRecords.forward(session, record);
    if (fwd.isEmpty) {
      throw Errors.expired('The change can no longer be redone.');
    }
    final (redoId, result) = await applyRecorded(
      session,
      actor: actor,
      item: item,
      changes: fwd,
      label: record.label,
      skipChanged: true,
    );
    return RevertResult(
      changeId: redoId,
      revertedCells: result.cellsAffected,
      skipped: result.skipped,
    );
  }
}
