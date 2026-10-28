import 'package:flutter/material.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show CellAlign, GridBullets;

import '../../../l10n/write_l10n.dart';
import '../mapping/wonky_schema.dart';
import '../pagination/pagination.dart';
import '../styles/editor_theme.dart';
import '../styles/write_stylesheet.dart' show strongTextDirection;
import 'box_frames.dart';
import 'editor_services.dart';
import 'wonky_components.dart';

/// Where a table cell or grid item node sits, read from the document
/// (Write 12 §3.2).
@immutable
class CellSlot {
  const CellSlot.cell({
    required this.group,
    required this.row,
    required this.column,
    required this.align,
    this.direction = TextDirection.ltr,
  }) : index = 0,
       columns = 0,
       bullets = GridBullets.none;

  const CellSlot.item({
    required this.group,
    required this.index,
    required this.columns,
    required this.bullets,
    this.direction = TextDirection.ltr,
  }) : row = 0,
       column = 0,
       align = null;

  /// The table or grid id.
  final String group;
  final int row;
  final int column;
  final int index;
  final int columns;
  final GridBullets bullets;

  /// The column's alignment (the header cell's, Write 12 §1.1).
  final CellAlign? align;

  /// The table's or grid's direction (Write 12 §3.10): its first strong
  /// character's, in document order.
  final TextDirection direction;

  bool get isRtl => direction == TextDirection.rtl;

  CellSlot withDirection(TextDirection direction) => isCell
      ? CellSlot.cell(
          group: group,
          row: row,
          column: column,
          align: align,
          direction: direction,
        )
      : CellSlot.item(
          group: group,
          index: index,
          columns: columns,
          bullets: bullets,
          direction: direction,
        );

  bool get isCell => columns == 0;

  @override
  bool operator ==(Object other) =>
      other is CellSlot &&
      other.group == group &&
      other.row == row &&
      other.column == column &&
      other.index == index &&
      other.columns == columns &&
      other.bullets == bullets &&
      other.align == align &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(
    group,
    row,
    column,
    index,
    columns,
    bullets,
    align,
    direction,
  );
}

/// The slots of every table cell and grid item of a document, kept current
/// as the document changes; notifies when one changes.
class CellSlots extends ChangeNotifier {
  CellSlots(this.document) {
    _rebuild();
    document.addListener(_onChange);
  }

  final Document document;
  var _slots = <String, CellSlot>{};

  /// The slot of [nodeId], or `null` when it is no cell or item.
  CellSlot? operator [](String nodeId) => _slots[nodeId];

  void _onChange(DocumentChangeLog _) {
    if (_rebuild()) notifyListeners();
  }

  /// Recomputes the slots; whether any changed.
  bool _rebuild() {
    final next = <String, CellSlot>{};
    // Group → its direction, from its first strong character.
    final directions = <String, TextDirection?>{};
    void detect(String group, DocumentNode node) {
      if (directions[group] != null || node is! TextNode) return;
      directions[group] = strongTextDirection(node.text.toPlainText());
    }

    String? table;
    String? row;
    var r = -1;
    var c = 0;
    // The header's alignments of the current table.
    final header = <CellAlign?>[];
    String? grid;
    var item = 0;
    int? columns;
    GridBullets? bullets;
    for (final node in document) {
      final cell = cellOf(node);
      if (cell != null) {
        if (cell.table != table) {
          table = cell.table;
          row = null;
          r = -1;
          header.clear();
        }
        if (cell.row != row) {
          row = cell.row;
          r++;
          c = 0;
        }
        if (r == 0) header.add(cell.align);
        detect('t:${cell.table}', node);
        next[node.id] = CellSlot.cell(
          group: 't:${cell.table}',
          row: r,
          column: c,
          align: c < header.length ? header[c] : null,
        );
        c++;
        grid = null;
        continue;
      }
      table = null;
      final g = gridItemOf(node);
      if (g != null) {
        if (g.id != grid) {
          grid = g.id;
          item = 0;
          // The first item's values are the grid's (Write 12 §1.2).
          columns = g.columns;
          bullets = g.bullets;
        }
        detect('g:${g.id}', node);
        next[node.id] = CellSlot.item(
          group: 'g:${g.id}',
          index: item++,
          columns: columns!,
          bullets: bullets!,
        );
        continue;
      }
      grid = null;
    }
    for (final e in next.entries) {
      if (directions[e.value.group] == TextDirection.rtl) {
        next[e.key] = e.value.withDirection(TextDirection.rtl);
      }
    }
    final changed = !_sameMaps(next, _slots);
    _slots = next;
    return changed;
  }

  static bool _sameMaps(Map<String, CellSlot> a, Map<String, CellSlot> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    document.removeListener(_onChange);
    super.dispose();
  }
}

/// Write's [DocumentCellLayout] (Write 12 §3.2): table cells in rows with
/// borders and a header background, grid items in a flow with their
/// bullets; the group sits in its containers' frames and has the table's
/// or grid's chrome.
class WriteCellLayout extends ChangeNotifier implements DocumentCellLayout {
  WriteCellLayout(this.slots, {this.pagination}) {
    slots.addListener(notifyListeners);
    pagination?.addListener(_onPagination);
  }

  final CellSlots slots;

  /// The page breaks (Pages layout): a row pushed to the next page has its
  /// gap as space before it (Write 12 §3.8).
  final PaginationController? pagination;
  var _gaps = const <String, double>{};

  void _onPagination() {
    final gaps = {
      for (final e in pagination!.gaps.entries)
        if (slots[e.key] != null) e.key: e.value,
    };
    if (_sameGaps(gaps, _gaps)) return;
    _gaps = gaps;
    notifyListeners();
  }

  static bool _sameGaps(Map<String, double> a, Map<String, double> b) =>
      a.length == b.length &&
      a.entries.every((e) => (b[e.key] ?? -1) == e.value);

  /// Set by the editor on every build.
  EditorTheme theme = EditorTheme.fallback(Brightness.light);
  double zoom = 1;
  bool editable = true;
  EditorBlockCallbacks callbacks = const EditorBlockCallbacks();

  /// Frames the group in its containers (the editor's frame builder).
  BoxFrameComponentBuilder? frames;

  /// Takes the editor's values. Called while building: a theme or zoom
  /// change also changes the stylesheet, which rebuilds the layout.
  void update({
    required EditorTheme theme,
    required double zoom,
    required bool editable,
    required EditorBlockCallbacks callbacks,
    required BoxFrameComponentBuilder frames,
  }) {
    this.theme = theme;
    this.zoom = zoom;
    this.editable = editable;
    this.callbacks = callbacks;
    this.frames = frames;
  }

  double get _bulletSize => (theme.body.fontSize ?? 14.67) * zoom * 1.3;

  /// The room of a grid item for its bullet (on its start side).
  double bulletRoom(GridBullets bullets) =>
      bullets == GridBullets.none ? 0 : _bulletSize * 1.45;

  /// The padding of a cell's text.
  EdgeInsets get cellPadding =>
      EdgeInsets.symmetric(horizontal: 8 * zoom, vertical: 4 * zoom);

  @override
  DocumentCellPlacement? placementOf(String nodeId) {
    final slot = slots[nodeId];
    if (slot == null) return null;
    if (slot.isCell) {
      return DocumentCellPlacement.rows(
        group: slot.group,
        row: slot.row,
        column: slot.column,
        minColumnWidth: 48 * zoom,
        spaceBefore: _gaps[nodeId] ?? 0,
        textDirection: slot.direction,
      );
    }
    return DocumentCellPlacement.flow(
      group: slot.group,
      index: slot.index,
      maxColumns: slot.columns,
      // Three columns from about 480 px (Write 11 §7.2).
      minColumnWidth: 140 * zoom,
      gap: theme.wonky.gridColumnGap * zoom,
      spaceBefore: _gaps[nodeId] ?? 0,
      textDirection: slot.direction,
    );
  }

  @override
  Widget wrapGroup(
    BuildContext context,
    DocumentCellGroup group,
    Widget child,
  ) {
    final document = slots.document;
    final first = document.getNodeById(group.nodeIds.first);
    final last = document.getNodeById(group.nodeIds.last);
    final l = writeL10n(context);
    final isTable = group.kind == DocumentCellGroupKind.rows;
    final id = group.id.substring(2);
    final firstSlot = slots[group.nodeIds.first];
    Widget body;
    if (isTable) {
      final rows = group.nodeIds.isEmpty
          ? 0
          : slots[group.nodeIds.last]!.row + 1;
      final columns = group.nodeIds.fold(0, (n, nodeId) {
        final c = slots[nodeId]?.column ?? 0;
        return c + 1 > n ? c + 1 : n;
      });
      body = Semantics(
        container: true,
        label: l.editorTableLabel(columns, rows),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * zoom),
          child: _chrome(
            child,
            !editable || callbacks.onEditTable == null
                ? null
                : EditorChromeButton(
                    key: ValueKey('${WonkyEditorKeys.tableEdit}.$id'),
                    icon: Icons.edit_outlined,
                    tooltip: l.editorEditTable,
                    onTap: (_) => callbacks.onEditTable!(id),
                  ),
          ),
        ),
      );
    } else {
      final gridCallbacks = editable ? callbacks.grid : null;
      final columns = firstSlot?.columns ?? 3;
      final bullets = firstSlot?.bullets ?? GridBullets.check;
      body = Semantics(
        container: true,
        label: l.editorGridLabel(group.nodeIds.length, columns),
        child: Padding(
          padding: EdgeInsets.only(
            top: theme.wonky.gridSpaceBefore * zoom,
            bottom: theme.wonky.gridSpaceAfter * zoom,
          ),
          child: _chrome(
            child,
            gridCallbacks == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EditorChromeButton(
                        key: ValueKey('write.editor.grid.columns.$id'),
                        label: l.editorGridColumns(columns),
                        tooltip: l.cmdGridSetColumns,
                        onTap: (rect) => gridCallbacks.onColumnsTap(id, rect),
                      ),
                      const SizedBox(width: 4),
                      EditorChromeButton(
                        key: ValueKey('write.editor.grid.bullets.$id'),
                        icon: switch (bullets) {
                          GridBullets.check => LucideIcons.check,
                          GridBullets.circle => LucideIcons.circleSmall,
                          GridBullets.none => LucideIcons.minus,
                        },
                        tooltip: l.cmdGridSetBullets,
                        onTap: (rect) => gridCallbacks.onBulletsTap(id, rect),
                      ),
                      const SizedBox(width: 4),
                      EditorChromeButton(
                        key: ValueKey('write.editor.grid.add.$id'),
                        icon: LucideIcons.plus,
                        tooltip: l.cmdGridAddItem,
                        onTap: (_) => gridCallbacks.onAddItem(id),
                      ),
                      const SizedBox(width: 4),
                      EditorChromeButton(
                        key: ValueKey('write.editor.grid.menu.$id'),
                        icon: LucideIcons.ellipsis,
                        tooltip: l.editorGridMenu,
                        onTap: (rect) => gridCallbacks.onMenu(id, rect),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }
    final frames = this.frames;
    if (frames == null || first == null || last == null) return body;
    return frames.frameGroup(first, last, body);
  }

  Widget _chrome(Widget child, Widget? chrome) => chrome == null
      ? child
      : EditorHoverChrome(above: true, chrome: chrome, child: child);

  @override
  void paintGroup(
    Canvas canvas,
    Offset offset,
    DocumentCellGroupGeometry geometry,
  ) {
    if (geometry.group.kind == DocumentCellGroupKind.flow) {
      _paintBullets(canvas, offset, geometry);
      return;
    }
    if (geometry.rowCount == 0 || geometry.columnCount == 0) return;
    final left = geometry.columnEdges.first;
    final right = geometry.columnEdges.last;
    // The header row's background.
    canvas.drawRect(
      Rect.fromLTRB(
        left,
        geometry.rowEdges.first,
        right,
        geometry.rowBottoms.first,
      ).shift(offset),
      Paint()..color = theme.tableHeaderBackground,
    );
    final line = Paint()
      ..color = theme.tableBorderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // Each row's box and column lines (rows may be apart: page breaks).
    for (var r = 0; r < geometry.rowCount; r++) {
      final top = geometry.rowEdges[r];
      final bottom = geometry.rowBottoms[r];
      canvas.drawRect(
        Rect.fromLTRB(
          left + 0.5,
          top + 0.5,
          right - 0.5,
          bottom - 0.5,
        ).shift(offset),
        line,
      );
      for (var c = 1; c < geometry.columnCount; c++) {
        final x = geometry.columnEdges[c];
        canvas.drawLine(
          Offset(x, top) + offset,
          Offset(x, bottom) + offset,
          line,
        );
      }
    }
  }

  void _paintBullets(
    Canvas canvas,
    Offset offset,
    DocumentCellGroupGeometry geometry,
  ) {
    final first = slots[geometry.group.nodeIds.first];
    final bullets = first?.bullets ?? GridBullets.none;
    final icon = switch (bullets) {
      GridBullets.check => LucideIcons.check,
      GridBullets.circle => LucideIcons.circleSmall,
      GridBullets.none => null,
    };
    if (icon == null) return;
    final size = _bulletSize;
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          height: 1,
          color: theme.wonky.gridBulletColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rtl = first?.isRtl ?? false;
    for (final rect in geometry.slotRects.values) {
      painter.paint(
        canvas,
        (rtl ? rect.topRight - Offset(painter.width, 0) : rect.topLeft) +
            offset +
            Offset(0, size * 0.05 + _textTopInset),
      );
    }
    painter.dispose();
  }

  /// The bullet's offset from the item's top (the first line's leading).
  double get _textTopInset {
    final fontSize = (theme.body.fontSize ?? 14.67) * zoom;
    final height = theme.body.height ?? 1.4;
    return ((fontSize * height) - _bulletSize).clamp(0, double.infinity) / 2;
  }

  @override
  void dispose() {
    slots.removeListener(notifyListeners);
    pagination?.removeListener(_onPagination);
    super.dispose();
  }
}

/// Styles table cells and grid items (Write 12 §3.3): cells get their
/// padding, their column's alignment and, in the header row, bold text;
/// grid items room for their bullet.
class CellStylePhase extends SingleColumnLayoutStylePhase {
  CellStylePhase(this.layout);

  WriteCellLayout layout;

  final _headerBuilders = Expando<AttributionStyleBuilder>();

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    var changed = false;
    final models = <SingleColumnLayoutComponentViewModel>[];
    for (final model in viewModel.componentViewModels) {
      final slot = layout.slots[model.nodeId];
      if (slot == null || model is! TextComponentViewModel) {
        models.add(model);
        continue;
      }
      final copy = model.copy();
      final text = copy as TextComponentViewModel;
      if (slot.isCell) {
        copy.padding = layout.cellPadding;
        // No alignment: the start of the cell's own text (Write 04 §38).
        text.textAlignment = switch (slot.align) {
          CellAlign.left => TextAlign.left,
          CellAlign.center => TextAlign.center,
          CellAlign.right => TextAlign.right,
          null => TextAlign.start,
        };
        if (slot.row == 0) {
          final base = text.textStyleBuilder;
          text.textStyleBuilder = _headerBuilders[base] ??= (attributions) =>
              base(attributions).copyWith(fontWeight: FontWeight.w600);
        }
      } else {
        final room = layout.bulletRoom(slot.bullets);
        copy.padding = slot.isRtl
            ? EdgeInsets.only(right: room)
            : EdgeInsets.only(left: room);
      }
      changed = true;
      models.add(copy);
    }
    if (!changed) return viewModel;
    return SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: models,
    );
  }
}
