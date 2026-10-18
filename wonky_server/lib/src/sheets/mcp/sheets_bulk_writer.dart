import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/model.dart'
    show ChangeKinds, ChangeSummary, MutationPlan, RowChange;

import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../revlog/sheets_server_writes.dart';

export 'sheets_change_records.dart';

/// Tool mutations committed as RevLog ops (RevLog spec 05 §8): the plans'
/// summaries and detail become the ops' summary and detail. A facade over
/// [SheetsServerWrites] that keeps the call sites unchanged.
abstract final class SheetsBulkWriter {
  /// Changes per op (RevLog chunks plans into groups of ops of this size).
  static const chunkSize = 5000;

  /// Commits [changes] (planner order) for [actor] on [item] as a
  /// revertible change.
  static Future<(UuidValue, AppliedChanges)> applyRecorded(
    Session session, {
    required Actor actor,
    required DriveItem item,
    required List<RowChange> changes,
    required String label,
    required List<MutationPlan> plans,
    Duration lifetime = const Duration(hours: 24),
    bool skipChanged = false,
    Set<String> kinds = const {},
  }) => SheetsServerWrites.applyRecorded(
    session,
    actor: actor,
    item: item,
    changes: changes,
    label: label,
    summary: summaryOf(plans, kinds, changes),
    detailJson: plans.length == 1 ? plans.single.detailJson : null,
    lifetime: lifetime,
    skipChanged: skipChanged,
  );

  /// The merged summary of [plans] (plus [kinds] and [changes]' structure).
  static ChangeSummary summaryOf(
    List<MutationPlan> plans,
    Set<String> kinds,
    List<RowChange> changes, [
    ChangeSummary? extra,
  ]) {
    final s = ChangeSummary(kinds: {...kinds});
    for (final p in [
      ...plans.map((p) => p.summary),
      ?extra,
      if (plans.isEmpty && extra == null) ChangeSummary.ofChanges(changes),
    ]) {
      s.kinds.addAll(p.kinds);
      s.sheets.addAll(p.sheets);
      for (final r in p.ranges) {
        s.addRange(r);
      }
      p.deleted.forEach((k, ids) {
        for (final id in ids) {
          s.addDeleted(k, id);
        }
      });
      p.revived.forEach((k, ids) {
        for (final id in ids) {
          s.addRevived(k, id);
        }
      });
    }
    for (final c in changes) {
      final sheetId = c.columnsAfter['sheetId'] ?? c.columnsBefore['sheetId'];
      if (sheetId != null) s.sheets.add('$sheetId');
    }
    if (s.kinds.isEmpty) s.kinds.add(ChangeKinds.values);
    return s;
  }

  /// Commits [changes] in groups of ops. [summary] is merged into the
  /// plans' summary (callers without plans: reverts, scripts).
  static Future<AppliedChanges> apply(
    Session session, {
    required Actor actor,
    required UuidValue spaceUuid,
    required List<RowChange> changes,
    required String label,
    required List<MutationPlan> plans,
    bool skipChanged = false,
    Set<String> kinds = const {},
    ChangeSummary? summary,
    UuidValue? recordId,
    void Function(int done, int total)? onProgress,
  }) => SheetsServerWrites.apply(
    session,
    actor: actor,
    fileUuid: spaceUuid,
    changes: changes,
    label: label,
    summary: summaryOf(plans, kinds, changes, summary),
    detailJson: plans.length == 1 ? plans.single.detailJson : null,
    skipChanged: skipChanged,
    recordId: recordId,
    onProgress: onProgress,
  );
}
