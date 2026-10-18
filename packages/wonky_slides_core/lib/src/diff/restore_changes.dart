import 'package:wonky_revlog/rows.dart';

import '../schema/slides_schema.dart';
import '../snapshot/slides_snapshot.dart';
import 'deck_diff.dart';

/// Rows of a deck by table and id (`table → id → columns`).
typedef DeckRowsByTable = Map<String, Map<String, Map<String, Object?>>>;

/// The row changes that turn the current deck into a version (Slides 09
/// §4.4 step 2, as Sheets 10 §5.3): rows only in the version are inserted
/// with the same id (reviving tombstones), rows only in the current deck
/// are deleted, rows in both are updated naming exactly the columns that
/// differ. Deletes come first, children before parents; then inserts and
/// updates in dependency order, group elements before their children.
/// The change log is never restored.
abstract final class SlidesRestoreChanges {
  /// Columns never written by a restore.
  static const _skip = {SlidesCols.id, 'spaceId'};

  /// The changes from [current] to [target].
  static List<RowChange> between(
    DeckRowsByTable current,
    DeckRowsByTable target,
  ) {
    final deletes = <RowChange>[];
    final upserts = <RowChange>[];
    for (final table in SlidesTables.dependencyOrder) {
      if (SlidesSnapshotCodec.excludedTables.contains(table)) continue;
      final cur = current[table] ?? const <String, Map<String, Object?>>{};
      final tgt = target[table] ?? const <String, Map<String, Object?>>{};
      var targetRows = tgt.values.toList();
      if (table == SlidesTables.slideElement) {
        targetRows = SlidesSnapshotCodec.parentsFirst(targetRows);
      }
      for (final row in targetRows) {
        final id = '${row[SlidesCols.id]}';
        final now = cur[id];
        if (now == null) {
          upserts.add(
            RowChange.insert(table, id, {
              for (final e in row.entries)
                if (e.key != 'spaceId') e.key: e.value,
            }),
          );
          continue;
        }
        final before = <String, Object?>{};
        final after = <String, Object?>{};
        for (final col in {...row.keys, ...now.keys}) {
          if (_skip.contains(col)) continue;
          if (DeckDiff.sameValue(now[col], row[col])) continue;
          before[col] = now[col];
          after[col] = row[col];
        }
        if (after.isNotEmpty) {
          upserts.add(RowChange.update(table, id, before, after));
        }
      }
      var currentRows = [
        for (final e in cur.entries)
          if (!tgt.containsKey(e.key)) e.value,
      ];
      if (table == SlidesTables.slideElement) {
        currentRows = SlidesSnapshotCodec.parentsFirst(currentRows);
      }
      for (final row in currentRows) {
        deletes.add(RowChange.delete(table, '${row[SlidesCols.id]}', row));
      }
    }
    return [...deletes.reversed, ...upserts];
  }
}
