import '../codec/change_set.dart';
import '../codec/rev_codec.dart';
import '../rows/compose_row_changes.dart';
import '../rows/row_change.dart';
import '../apply/order.dart';
import '../apply/validation.dart';

/// Splits a plan into ops of ≤ [RevLimits.maxChangesPerOp] changes and
/// roughly ≤ [RevLimits.targetOpBytes] compressed (RevLog spec 06 §4.1).
/// The chunks of one plan form a group (RD-21).
abstract final class RevChunker {
  /// Uncompressed bytes per op that compress to about the target size.
  static int uncompressedBudget(RevLimits limits) => limits.targetOpBytes * 4;

  /// Chunks of [cs]; a single element when it fits. [newId] creates client
  /// op ids for chunks after the first.
  static List<ChangeSet> split(
    ChangeSet cs,
    RevCodec codec,
    String Function() newId, {
    RevLimits limits = RevLimits.defaults,
  }) {
    final changes = parentsFirst(codec.schema, cs.changes);
    final pieces = <List<RowChange>>[];
    var current = <RowChange>[];
    var bytes = 0;
    final budget = uncompressedBudget(limits);
    for (final ch in changes) {
      final size = _estimate(ch);
      if (current.isNotEmpty &&
          (current.length >= limits.maxChangesPerOp || bytes + size > budget)) {
        pieces.add(current);
        current = [];
        bytes = 0;
      }
      current.add(ch);
      bytes += size;
    }
    if (current.isNotEmpty) pieces.add(current);
    if (pieces.length <= 1) {
      return [
        identical(changes, cs.changes) ? cs : cs.copyWith(changes: changes),
      ];
    }
    final groupId = cs.groupId ?? cs.clientOpId;
    final detailFits = _detailCells(cs.detail) <= 200;
    return [
      for (var i = 0; i < pieces.length; i++)
        ChangeSet(
          clientOpId: i == 0 ? cs.clientOpId : newId(),
          baseRevision: cs.baseRevision,
          changes: pieces[i],
          label: cs.label,
          actorKind: cs.actorKind,
          summary: i == 0 ? cs.summary : null,
          detail: i == 0 && detailFits ? cs.detail : null,
          groupId: groupId,
          groupIndex: i,
          groupLast: i == pieces.length - 1,
          offline: cs.offline,
          createdAt: cs.createdAt,
        ),
    ];
  }

  static int _estimate(RowChange c) {
    var n = 64;
    for (final v in c.columnsAfter.values) {
      n += 8 + (v is String ? v.length : 12);
    }
    for (final v in c.columnsBefore.values) {
      n += 8 + (v is String ? v.length : 12);
    }
    return n;
  }

  static int _detailCells(Map<String, Object?>? d) =>
      (d?['cells'] as List?)?.length ?? 0;
}

/// Composes a buffered op with a newer local change set (RevLog spec 06
/// §4.2): `composeRowChanges`, merged summary, capped detail, OR-ed
/// `offline`. Returns null when they must stay separate.
ChangeSet? composeChangeSets(
  ChangeSet older,
  ChangeSet newer, {
  required Duration window,
  RevLimits limits = RevLimits.defaults,
}) {
  final sameGroup = older.groupId != null && older.groupId == newer.groupId;
  final plain = older.groupId == null && newer.groupId == null;
  if (!sameGroup && !plain) return null;
  if (older.actorKind != newer.actorKind) return null;
  if (older.isRepair != newer.isRepair) return null;
  if (plain && newer.createdAt.difference(older.createdAt) > window) {
    return null;
  }
  final changes = composeRowChanges([...older.changes, ...newer.changes]);
  if (changes.length > limits.maxChangesPerOp) return null;
  return ChangeSet(
    clientOpId: older.clientOpId,
    baseRevision: older.baseRevision,
    changes: changes,
    label: older.label == newer.label ? older.label : 'Edits',
    actorKind: older.actorKind,
    summary: mergeSummaries(older.summary, newer.summary),
    detail: _mergeDetail(older.detail, newer.detail),
    groupId: older.groupId,
    groupIndex: older.groupIndex,
    groupLast: newer.groupLast,
    offline: older.offline || newer.offline,
    createdAt: older.createdAt,
  );
}

/// Union of two summary objects: lists are unioned (order kept), maps merged
/// recursively, other values taken from [b].
Map<String, Object?>? mergeSummaries(
  Map<String, Object?>? a,
  Map<String, Object?>? b,
) {
  if (a == null) return b;
  if (b == null) return a;
  final out = <String, Object?>{...a};
  for (final e in b.entries) {
    final x = out[e.key], y = e.value;
    if (x is List && y is List) {
      out[e.key] = [
        ...x,
        for (final v in y)
          if (!x.contains(v)) v,
      ];
    } else if (x is Map && y is Map) {
      out[e.key] = mergeSummaries(
        x.cast<String, Object?>(),
        y.cast<String, Object?>(),
      );
    } else {
      out[e.key] = y;
    }
  }
  return out;
}

Map<String, Object?>? _mergeDetail(
  Map<String, Object?>? a,
  Map<String, Object?>? b,
) {
  if (a == null || b == null) return a ?? b;
  final ca = a['cells'], cb = b['cells'];
  if (ca is! List || cb is! List) return null;
  final cells = [...ca, ...cb];
  if (cells.length > 200) return null;
  return {...a, ...b, 'cells': cells};
}
