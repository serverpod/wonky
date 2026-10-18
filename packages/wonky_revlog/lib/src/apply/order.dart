import '../rows/row_change.dart';
import '../schema/rev_schema.dart';

/// Orders [changes] so that every insert or update comes after the insert
/// of a parent row created by the same op (RevLog spec 03 §4.1).
///
/// Planners sort by table rank, which orders different tables but not rows
/// of one self-referencing table (Slides `slide_element.parentId`): a group
/// created in the same op as its children may come after them, and the
/// sequencer would drop the children (`parentMissing`). The parent insert is
/// moved to just before the first change that needs it; everything else
/// keeps its order. Returns [changes] itself when nothing moves.
List<RowChange> parentsFirst(RevSchema schema, List<RowChange> changes) {
  // Inserts by key, for parents created in this op.
  final inserts = <(String, String), int>{};
  for (var i = 0; i < changes.length; i++) {
    final c = changes[i];
    if (c.op == RowOp.insert) inserts[(c.table, c.rowId)] ??= i;
  }
  if (inserts.isEmpty) return changes;

  final out = <RowChange>[];
  final emitted = List<bool>.filled(changes.length, false);
  var moved = false;

  void emit(int i, Set<int> path) {
    if (emitted[i] || !path.add(i)) return;
    final c = changes[i];
    if (c.op != RowOp.delete) {
      final t = schema.tryTable(c.table);
      for (final p in t?.parents ?? const <RevParent>[]) {
        final id = c.columnsAfter[p.column];
        if (id is! String) continue;
        final j = inserts[(p.table, id)];
        if (j != null && j > i && !emitted[j]) {
          moved = true;
          emit(j, path);
        }
      }
    }
    emitted[i] = true;
    out.add(c);
  }

  for (var i = 0; i < changes.length; i++) {
    emit(i, {});
  }
  return moved ? out : changes;
}
