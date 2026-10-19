import 'row_change.dart';

/// Collapses sequentially applied [changes] into one net change per row, so
/// the result can be inverted against the current state in one pass
/// ([UndoInverter]): `A→B` then `B→C` of a column becomes `A→C`.
///
/// Concatenating the lists instead would make the inverse of the earlier
/// change look like a collaborator's conflict (the current value is `C`, not
/// its `B`) and the skip rule would drop it — undo would stop at `B`.
///
/// Rows keep the position of their first change, so parents still precede
/// children. An insert followed by a delete of the same row cancels out.
List<RowChange> composeRowChanges(Iterable<RowChange> changes) {
  final order = <(String, String)>[];
  final byRow = <(String, String), RowChange>{};
  for (final c in changes) {
    final key = (c.table, c.rowId);
    final prev = byRow[key];
    if (prev == null) {
      byRow[key] = c;
      order.add(key);
      continue;
    }
    final composed = _compose(prev, c);
    if (composed == null) {
      byRow.remove(key);
      order.remove(key);
    } else {
      byRow[key] = composed;
    }
  }
  return [for (final k in order) byRow[k]!];
}

RowChange? _compose(RowChange a, RowChange b) {
  RowChange make(
    RowOp op,
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) => RowChange(
    table: a.table,
    rowId: a.rowId,
    op: op,
    columnsBefore: before,
    columnsAfter: after,
  );
  switch ((a.op, b.op)) {
    case (RowOp.insert, RowOp.update):
      return make(RowOp.insert, const {}, {
        ...a.columnsAfter,
        ...b.columnsAfter,
      });
    case (RowOp.insert, RowOp.delete):
      return null;
    case (RowOp.update, RowOp.update):
      // The earliest before-value of each column wins.
      return make(
        RowOp.update,
        {...b.columnsBefore, ...a.columnsBefore},
        {...a.columnsAfter, ...b.columnsAfter},
      );
    case (RowOp.update, RowOp.delete):
      // The full row as it was before the update.
      return make(RowOp.delete, {
        ...b.columnsBefore,
        ...a.columnsBefore,
      }, const {});
    case (RowOp.delete, RowOp.insert):
      // Revived within the same step: net effect is an update.
      return make(RowOp.update, a.columnsBefore, b.columnsAfter);
    default:
      // Not produced by planners (insert after insert, update after delete…):
      // keep the later change.
      return b;
  }
}
