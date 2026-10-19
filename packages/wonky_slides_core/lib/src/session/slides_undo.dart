import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_revlog/undo.dart'
    show RowsUndoEntry, RowsUndoHandler, RowsUndoTarget;

import '../schema/slides_undo_hooks.dart';

/// Undo domain of synced-row changes of Slides (02 §12.2, suite 08 §3.3).
const slidesRowsDomain = 'slides.rows';

/// Undo domain of server-executed changes (version restore, headless
/// MCP/AI runs surfaced in the UI; 02 §12.2) — `{changeId}` →
/// `SlidesEndpoint.revertChange` / `reapplyChange` (SL-39).
const slidesServerChangeDomain = 'slides.serverChange';

/// One `slides.rows` undo entry: the [RowChange]s a plan applied, in order
/// (the shared kit's [RowsUndoEntry]).
class SlidesRowsUndoEntry extends RowsUndoEntry {
  /// Creates an entry.
  SlidesRowsUndoEntry(
    List<RowChange> changes, {
    String label = '',
    String? groupId,
  }) : super(slidesRowsDomain, changes, label: label, groupId: groupId);

  @override
  SlidesRowsUndoEntry withChanges(List<RowChange> changes) =>
      SlidesRowsUndoEntry(changes, label: label, groupId: groupId);

  /// Decodes a persisted entry, or null when malformed.
  static SlidesRowsUndoEntry? fromJson(Map<String, Object?> json) {
    final decoded = RowsUndoEntry.decode(json);
    if (decoded == null) return null;
    return SlidesRowsUndoEntry(decoded.$1, label: decoded.$2);
  }
}

/// Applies `slides.rows` entries through the open deck session (the kit's
/// [RowsUndoHandler] with the Slides table hooks: coupled columns, P4, and
/// column-wise table cell inserts, `SlidesUndoHooks`).
///
/// Undo and redo are the same operation: invert the entry's changes against
/// the current model (skipping columns someone else changed since) and
/// apply the result; the returned entry holds what was applied.
class SlidesRowsUndoHandler extends RowsUndoHandler<SlidesRowsUndoEntry> {
  /// Creates the handler; [target] returns the open session at undo time
  /// (`DeckSession`, `MemoryDeck`).
  SlidesRowsUndoHandler(this._target, {super.onPartial})
    : super(
        coupled: SlidesUndoHooks.coupled,
        columnwise: SlidesUndoHooks.columnwise,
      );

  final RowsUndoTarget Function() _target;

  @override
  String get domain => slidesRowsDomain;

  @override
  RowsUndoTarget get target => _target();

  @override
  SlidesRowsUndoEntry entryFor(
    SlidesRowsUndoEntry from,
    List<RowChange> changes,
  ) => SlidesRowsUndoEntry(changes, label: from.label);

  @override
  SlidesRowsUndoEntry? decode(Map<String, Object?> json) =>
      SlidesRowsUndoEntry.fromJson(json);
}
