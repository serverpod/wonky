import 'package:wonky_core/wonky_core.dart'
    show RemoteChange, UndoConflict, UndoEntry, UndoEntryDecoder, UndoHandler;

import '../rows/compose_row_changes.dart';
import '../rows/row_change.dart';
import '../rows/undo_inverter.dart';

/// One undo entry of a synced-rows domain (`sheets.rows`, `slides.rows`;
/// suite 08 §3.3): the [RowChange]s a plan applied, in order. Undo writes
/// their inverse against the current state with the per-column skip rule
/// ([UndoInverter]), so collaborators' later edits are never reverted.
class RowsUndoEntry extends UndoEntry {
  /// Creates an entry of [domain].
  RowsUndoEntry(
    this.domain,
    List<RowChange> changes, {
    this.label = '',
    this.groupId,
  }) : changes = List.unmodifiable(changes);

  @override
  final String domain;

  /// The applied changes, in order.
  final List<RowChange> changes;

  /// The plan label ("Paste", "Insert 3 rows").
  final String label;

  /// The RevLog group of the op(s) this entry recorded when it was chunked
  /// (RevLog spec 06 §4.6): undo of a partly rejected group is skipped.
  final String? groupId;

  /// An entry of the same kind and domain holding [changes] (subclasses
  /// return their own type).
  RowsUndoEntry withChanges(List<RowChange> changes) =>
      RowsUndoEntry(domain, changes, label: label, groupId: groupId);

  /// Remote changes are handled at undo time by the skip rule.
  @override
  UndoEntry? rebase(RemoteChange change) => this;

  /// Entries of one step on the same stack merge into one net change per
  /// row ([composeRowChanges]), so undo restores the state before the first
  /// entry even when several entries touched the same columns.
  @override
  UndoEntry? coalesce(UndoEntry next) =>
      next is RowsUndoEntry && next.domain == domain
      ? withChanges(composeRowChanges([...changes, ...next.changes]))
      : null;

  @override
  Map<String, Object?> toJson() => {
    'label': label,
    'changes': [for (final c in changes) c.toJson()],
  };

  /// The `(changes, label)` of persisted [json], or null when malformed.
  static (List<RowChange>, String)? decode(Map<String, Object?> json) {
    final raw = json['changes'];
    if (raw is! List) return null;
    try {
      return (
        [for (final c in raw) RowChange.fromJson((c as Map).cast())],
        json['label'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// What undo/redo of a rows domain writes through: the open file's session
/// (Sheets' `WorkbookSession`, Slides' `DeckSession`).
abstract interface class RowsUndoTarget {
  /// The current rows (the in-memory model).
  CurrentRowReader get currentRows;

  /// Applies and persists precomputed [changes].
  void applyChanges(
    List<RowChange> changes, {
    required String label,
    String actorKind = 'user',
  });
}

/// Applies the entries of a rows domain through a [RowsUndoTarget].
///
/// Undo and redo are the same operation: invert the entry's changes against
/// the current rows (skipping columns someone else changed since, with the
/// table hooks [coupled] and [columnwise]) and apply the result; the
/// returned entry holds what was applied, so its inversion is the next
/// redo/undo. A fully skipped entry throws [UndoConflict].
abstract class RowsUndoHandler<E extends RowsUndoEntry> extends UndoHandler<E> {
  /// Creates the handler.
  RowsUndoHandler({this.coupled, this.columnwise, this.onPartial});

  /// The open file's session at undo time.
  RowsUndoTarget get target;

  /// Coupled-column groups skipped as a unit.
  final CoupledColumns? coupled;

  /// Tables whose inserts undo column by column.
  final ColumnwiseInserts? columnwise;

  /// Called when some (not all) columns were skipped.
  final void Function()? onPartial;

  /// A new entry holding the applied [changes] (same label as [from]).
  E entryFor(E from, List<RowChange> changes);

  /// Decodes a persisted entry.
  E? decode(Map<String, Object?> json);

  @override
  UndoEntryDecoder? get decoder => decode;

  @override
  Future<E> undo(E entry) async => apply(entry, 'Undo');

  @override
  Future<E> redo(E entry) async => apply(entry, 'Redo');

  /// Inverts and applies [entry]; [verb] prefixes the change-log label.
  E apply(E entry, String verb) {
    final t = target;
    var skipped = 0;
    final inverse = UndoInverter.invertChanges(
      entry.changes,
      t.currentRows,
      coupled: coupled,
      columnwise: columnwise,
      skipped: (_, _, _) => skipped++,
    );
    if (inverse.isEmpty) {
      if (entry.changes.isEmpty) return entry;
      throw const UndoConflict('Changed by someone else');
    }
    t.applyChanges(
      inverse,
      label: entry.label.isEmpty ? verb : '$verb ${entry.label}',
    );
    if (skipped > 0) onPartial?.call();
    return entryFor(entry, inverse);
  }
}
