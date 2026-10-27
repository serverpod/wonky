/// The upgrade of legacy `table` and `grid` embeds to cell and grid item
/// lines (specs/wonky_write/12-native-cells.md §1.5).
library;

import 'package:wonky_rich_text/wonky_rich_text.dart';

import 'cells.dart';
import 'document.dart';
import 'embeds.dart';

/// Converts legacy `table` and `grid` embeds (Write 12 §1.5).
abstract final class CellUpgrade {
  /// Whether [document] still holds a legacy `table` or `grid` embed.
  static bool hasLegacy(Delta document) {
    for (final op in document.toList()) {
      final data = op.data;
      if (data is Map &&
          (data.containsKey(TableEmbed.typeKey) ||
              data.containsKey(GridEmbed.typeKey))) {
        return true;
      }
    }
    return false;
  }

  /// The change that replaces every legacy embed line of [document] with
  /// cell or grid item lines, or `null` when there is none. The embed id is
  /// kept as the table or grid id; row ids come from [rowId] (random by
  /// default); the embed line's `box` goes on every new line; overlays of
  /// the embed (comments, suggestions) are dropped.
  static Delta? upgradeChange(Delta document, {String Function()? rowId}) {
    if (!hasLegacy(document)) return null;
    final doc = WonkyDocument(document);
    final change = Delta();
    var cursor = 0;
    var changed = false;
    for (final line in doc.lines) {
      if (!line.isEmbedLine || !line.hasNewline) continue;
      final embed = WonkyEmbed.tryParse(line.segments.single.data);
      final box = line.attributes[WonkyAttr.box];
      final Delta lines;
      if (embed is TableEmbed) {
        lines = tableLines(embed, box: box, rowId: rowId);
      } else if (embed is GridEmbed) {
        lines = gridLines(embed, box: box);
      } else {
        continue;
      }
      if (line.start > cursor) change.retain(line.start - cursor);
      change.delete(line.length);
      for (final op in lines.toList()) {
        change.push(op);
      }
      cursor = line.end;
      changed = true;
    }
    return changed ? change : null;
  }

  /// [document] with every legacy embed upgraded.
  static Delta upgrade(Delta document, {String Function()? rowId}) {
    final change = upgradeChange(document, rowId: rowId);
    return change == null ? document : document.compose(change);
  }

  /// The lines of a legacy table embed.
  static Delta tableLines(
    TableEmbed table, {
    Object? box,
    String Function()? rowId,
  }) {
    final padded = table.padded();
    return CellLines.table(
      id: table.id,
      rows: [
        for (final row in padded.rows)
          [for (final c in row) CellLines.markdown(c)],
      ],
      align: padded.align,
      box: box,
      rowId: rowId,
    );
  }

  /// The lines of a legacy grid embed.
  static Delta gridLines(GridEmbed grid, {Object? box}) => CellLines.grid(
    id: grid.id,
    items: [for (final item in grid.items) CellLines.markdown(item)],
    columns: grid.columns,
    bullets: grid.bullets,
    box: box,
  );
}
