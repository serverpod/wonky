import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_sheets_core/formula.dart' show CellPos, GridRect;
import 'package:wonky_sheets_core/model.dart';

import 'spill_blockers_layer.dart';
import 'smart_chips.dart';
import '../cell_editor/cell_editor_controller.dart' show EditMode;
import '../data_validation/dv_controller.dart';
import '../grid/paint/grid_layer.dart';
import '../grid/viewport/grid_geometry.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'cell_cards.dart';
import 'cell_popups.dart';
import 'in_cell_paint.dart';

/// Popovers anchored to a cell (03 §14).
enum CellPopupKind { dropdown, date, note, smartChip }

/// An open cell popover.
@immutable
class CellPopup {
  const CellPopup(this.kind, this.sheetId, this.row, this.col);

  final CellPopupKind kind;
  final String sheetId;
  final int row;
  final int col;

  String get a1 => CellPos(row, col).a1;

  @override
  bool operator ==(Object other) =>
      other is CellPopup &&
      other.kind == kind &&
      other.sheetId == sheetId &&
      other.row == row &&
      other.col == col;

  @override
  int get hashCode => Object.hash(kind, sheetId, row, col);
}

/// The cell whose info card shows (hover or active cell).
@immutable
class CellCardTarget {
  const CellCardTarget(this.sheetId, this.row, this.col, {this.hover = true});

  final String sheetId;
  final int row;
  final int col;

  /// From hovering (else: the selected cell's link / help text).
  final bool hover;

  @override
  bool operator ==(Object other) =>
      other is CellCardTarget &&
      other.sheetId == sheetId &&
      other.row == row &&
      other.col == col &&
      other.hover == hover;

  @override
  int get hashCode => Object.hash(sheetId, row, col, hover);
}

/// In-cell widgets and cell popovers of an open spreadsheet (03 §14):
/// checkbox clicks, dropdown chips with the [DropdownPickerPopover], the
/// date picker of date-validated cells, the note editor, and the hover
/// cards (links, notes, errors, `#SPILL!`, invalid data, help text).
class InCellController extends ChangeNotifier {
  InCellController._(this.editor) {
    _hit = _InCellHitHandler(this);
    editor.gridHooks.hitHandlers.add(_hit);
    editor.gridHooks.hover.addListener(_onHover);
    editor.gridHooks.overlays.value = [
      ...editor.gridHooks.overlays.value,
      _overlay,
    ];
    editor.selection.addListener(_onSelection);
    editor.scroll.addListener(_onScroll);
    editor.editor.addListener(_onEditing);
    editor.layers.add(_spillBlockers);
    editor.editor.text.addListener(_onEditorText);
    editor.onDispose(dispose);
  }

  /// Typing `@` into an empty cell opens the smart chip menu (03 §14.3):
  /// the edit is dropped and the menu takes over (its search continues the
  /// text; *Insert "@…" as text* keeps it as plain text).
  void _onEditorText() {
    final ce = editor.editor;
    final s = ce.session;
    if (s == null || s.mode != EditMode.enter || ce.text.text != '@') return;
    if (!editor.canEdit) return;
    final sheet = editor.model.sheet(s.sheetId);
    if (sheet == null) return;
    final row = sheet.rows.indexOf(s.rowId);
    final col = sheet.columns.indexOf(s.colId);
    if (row < 0 || col < 0) return;
    scheduleMicrotask(() {
      if (_disposed || !identical(ce.session, s) || ce.text.text != '@') {
        return;
      }
      ce.cancel();
      openSmartChipMenu(s.sheetId, row, col);
    });
  }

  /// Opens the smart chip menu at the cell (`sheets.insert.smartChip`).
  void openSmartChipMenu(String sheetId, int row, int col) =>
      _open(CellPopup(CellPopupKind.smartChip, sheetId, row, col));

  /// Opens the date picker at the cell (date chips, date rules).
  void openDatePicker(String sheetId, int row, int col) =>
      _open(CellPopup(CellPopupKind.date, sheetId, row, col));

  /// Outlines the cells blocking a selected `#SPILL!` array (03 §14.8).
  static const _spillBlockers = SpillBlockersLayer();

  /// The in-cell controller of [editor] (created on first use).
  static InCellController of(SheetEditorController editor) =>
      editor.extension(InCellController, () => InCellController._(editor));

  final SheetEditorController editor;
  late final _InCellHitHandler _hit;

  /// Delay before a hover card shows (03 §14.4–14.7).
  static const hoverDelay = Duration(milliseconds: 400);

  /// Delay before a hover card hides after the pointer left its cell.
  static const hideDelay = Duration(milliseconds: 250);

  /// The open popover.
  final ValueNotifier<CellPopup?> popup = ValueNotifier(null);

  /// The cell whose info card shows.
  final ValueNotifier<CellCardTarget?> card = ValueNotifier(null);

  Timer? _hoverTimer;
  Timer? _hideTimer;
  bool _overCard = false;
  bool _disposed = false;

  DataValidationController get dv => DataValidationController.of(editor);

  Widget _overlay(BuildContext context) => InCellOverlay(controller: this);

  // ---------------------------------------------------------------------------
  // Popovers.

  /// Opens the dropdown picker (dropdown rules) or the date picker (date
  /// rules) of the cell; false when the cell has neither.
  bool openDropdown(String sheetId, int row, int col) {
    final kind = popupKindAt(sheetId, row, col);
    if (kind == null) return false;
    _open(CellPopup(kind, sheetId, row, col));
    return true;
  }

  /// The picker the cell offers (Alt+↓, chip click), or null.
  CellPopupKind? popupKindAt(String sheetId, int row, int col) {
    final rule = dv.ruleAt(sheetId, row, col);
    final criteria = rule?.criteria;
    if (criteria == null) return null;
    if (criteria.isDropdown) return CellPopupKind.dropdown;
    if (criteria is DvConditionCriteria &&
        (criteria.condition.type.family == ConditionFamily.date ||
            criteria.condition.type.family == ConditionFamily.dateValidity)) {
      return CellPopupKind.date;
    }
    return null;
  }

  /// Opens the note editor of the cell (Shift+F2, Insert › Note).
  void openNoteEditor(String sheetId, int row, int col) =>
      _open(CellPopup(CellPopupKind.note, sheetId, row, col));

  void _open(CellPopup p) {
    if (editor.activeSheetId != p.sheetId) editor.activateSheet(p.sheetId);
    final sel = editor.selection.resolved;
    if (sel.activeRow != p.row || sel.activeCol != p.col) {
      editor.selection.selectCell(p.row, p.col);
    }
    editor.revealCell(p.row, p.col);
    _hideCard();
    popup.value = p;
  }

  /// Closes the open popover and returns focus to the grid.
  void closePopup() {
    if (popup.value == null) return;
    popup.value = null;
    editor.gridFocus.requestFocus();
  }

  void _onSelection() {
    final p = popup.value;
    if (p != null) {
      final sel = editor.selection.resolved;
      if (sel.sheetId != p.sheetId ||
          sel.activeRow != p.row ||
          sel.activeCol != p.col) {
        // Note editors save on blur (they listen themselves).
        if (p.kind != CellPopupKind.note) popup.value = null;
      }
    }
    _refreshActiveCard();
  }

  void _onScroll() {
    final p = popup.value;
    if (p != null && p.kind != CellPopupKind.note) popup.value = null;
    if (card.value?.hover ?? false) _hideCard();
  }

  void _onEditing() {
    if (editor.editor.isEditing) {
      if (popup.value?.kind != CellPopupKind.note) popup.value = null;
      _hideCard();
    } else {
      _refreshActiveCard();
    }
  }

  // ---------------------------------------------------------------------------
  // Info cards.

  /// What the card of a cell shows (null when there is nothing to show).
  CellInfo? infoAt(String sheetId, int row, int col, {required bool hover}) {
    final sheet = editor.model.sheet(sheetId);
    if (sheet == null) return null;
    final d = editor.cells.displayAt(sheetId, row, col);
    final note = sheet.cellAt(row, col)?.note;
    final link = d?.linkUrl;
    final value = d?.value;
    String? error;
    String? errorTitle;
    if (value is ErrorValue &&
        (d!.isFormula || editor.engine.overlayAt(sheetId, row, col) != null) &&
        (value.kind != CellErrorKind.na || value.message != null)) {
      errorTitle = value.kind.literal;
      error = value.message;
    }
    String? invalid;
    String? help;
    if (sheet.dvRules.isNotEmpty) {
      final v = dv.validate(sheetId, row, col);
      if (!v.valid) invalid = v.message ?? v.defaultMessage;
      if (!hover) help = dv.ruleAt(sheetId, row, col)?.helpText;
    }
    final info = CellInfo(
      sheetId: sheetId,
      row: row,
      col: col,
      note: hover && (note?.isNotEmpty ?? false) ? note : null,
      link: link,
      errorTitle: hover ? errorTitle : null,
      error: hover ? error : null,
      invalid: hover ? invalid : null,
      help: (help?.isNotEmpty ?? false) ? help : null,
      person: PersonChip.mayBe(sheet.cellAt(row, col)?.content)
          ? PersonChip.of(sheet.cellAt(row, col)?.decoded)
          : null,
      file: PersonChip.mayBe(sheet.cellAt(row, col)?.content)
          ? FileChip.of(sheet.cellAt(row, col)?.decoded)
          : null,
    );
    return info.isEmpty ? null : info;
  }

  void _onHover() {
    final h = editor.gridHooks.hover.value;
    _hoverTimer?.cancel();
    if (h == null || popup.value != null || editor.editor.isEditing) {
      _scheduleHide();
      return;
    }
    final current = card.value;
    if (current != null &&
        current.hover &&
        current.sheetId == h.sheetId &&
        current.row == h.row &&
        current.col == h.col) {
      _hideTimer?.cancel();
      return;
    }
    if (infoAt(h.sheetId, h.row, h.col, hover: true) == null) {
      _scheduleHide();
      return;
    }
    _hoverTimer = Timer(hoverDelay, () {
      final now = editor.gridHooks.hover.value;
      if (_disposed || now != h || popup.value != null) return;
      _hideTimer?.cancel();
      card.value = CellCardTarget(h.sheetId, h.row, h.col);
    });
  }

  void _scheduleHide() {
    if (!(card.value?.hover ?? false)) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(hideDelay, () {
      if (_disposed || _overCard) return;
      if (editor.gridHooks.hover.value == null ||
          editor.gridHooks.hover.value !=
              (
                sheetId: card.value?.sheetId ?? '',
                row: card.value?.row ?? -1,
                col: card.value?.col ?? -1,
              )) {
        card.value = null;
        _refreshActiveCard();
      }
    });
  }

  /// The pointer entered/left the card (keeps it open while over it).
  void setOverCard(bool over) {
    _overCard = over;
    if (!over) _scheduleHide();
  }

  void _hideCard() {
    _hoverTimer?.cancel();
    _hideTimer?.cancel();
    card.value = null;
  }

  /// Shows the active cell's link / help text card (03 §14.4).
  void _refreshActiveCard() {
    if (_disposed) return;
    if (card.value?.hover ?? false) return;
    final sel = editor.selection.resolved;
    final s = editor.activeSheet;
    if (s == null ||
        editor.editor.isEditing ||
        popup.value != null ||
        !_singleCell(s, sel.activeRange.rect)) {
      card.value = null;
      return;
    }
    final info = infoAt(s.id, sel.activeRow, sel.activeCol, hover: false);
    card.value = info == null
        ? null
        : CellCardTarget(s.id, sel.activeRow, sel.activeCol, hover: false);
  }

  bool _singleCell(SheetModel s, GridRect r) =>
      r.isSingleCell || s.mergeAt(r.top, r.left) == r;

  // ---------------------------------------------------------------------------
  // Geometry.

  /// The on-screen rect (grid coordinates) of a cell or its merge.
  Rect? cellRect(String sheetId, int row, int col) {
    final g = editor.geometry;
    if (g == null || g.sheet.id != sheetId) return null;
    final m = g.sheet.mergeAt(row, col);
    return m == null ? g.cellRect(row, col) : g.rangeRect(m);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _hoverTimer?.cancel();
    _hideTimer?.cancel();
    editor.gridHooks.hitHandlers.remove(_hit);
    editor.gridHooks.hover.removeListener(_onHover);
    editor.gridHooks.overlays.value = [
      for (final o in editor.gridHooks.overlays.value)
        if (o != _overlay) o,
    ];
    editor.selection.removeListener(_onSelection);
    editor.scroll.removeListener(_onScroll);
    editor.layers.remove(_spillBlockers);
    editor.editor.text.removeListener(_onEditorText);
    editor.editor.removeListener(_onEditing);
    popup.dispose();
    card.dispose();
    super.dispose();
  }
}

/// Checkbox and dropdown-chip clicks, double-click on date cells (03 §14).
class _InCellHitHandler extends GridHitHandler {
  _InCellHitHandler(this.c);

  final InCellController c;
  DateTime? _lastDown;
  Offset? _lastPos;

  SheetEditorController get ed => c.editor;

  (int, int, Rect)? _cell(GridGeometry g, Offset p) {
    if (p.dx < g.rowHeaderWidth || p.dy < g.colHeaderHeight) return null;
    final pane = g.paneAt(p);
    if (pane == null) return null;
    final (row, col) = pane.cellAt(p);
    final m = g.sheet.mergeAt(row, col);
    final rect = m == null ? pane.cellRect(row, col) : pane.rangeRect(m);
    return m == null ? (row, col, rect) : (m.top, m.left, rect);
  }

  bool _onCheckbox(GridGeometry g, Rect rect, CellDisplay d, Offset p) {
    if (d.widget.kind != CellWidgetKind.checkbox) return false;
    final box = InCellGeometry.checkboxBox(rect, g.zoom);
    return box != null && box.inflate(3).contains(p);
  }

  bool _onDropdown(GridGeometry g, Rect rect, CellDisplay d, Offset p) {
    switch (d.widget.kind) {
      case CellWidgetKind.dropdownChip:
        if (d.text.isEmpty) {
          return InCellGeometry.arrow(rect, g.zoom).contains(p);
        }
        final w = chipTextWidth(ed.textCache, d, g.zoom);
        return InCellGeometry.chip(rect, w, g.zoom).inflate(2).contains(p);
      case CellWidgetKind.dropdownArrow:
        return InCellGeometry.arrow(rect, g.zoom).contains(p);
      default:
        return false;
    }
  }

  bool get _modifiers {
    final kb = HardwareKeyboard.instance;
    return kb.isShiftPressed ||
        kb.isControlPressed ||
        kb.isMetaPressed ||
        kb.isAltPressed;
  }

  bool _isDouble(Offset p) {
    final now = DateTime.now();
    final last = _lastDown;
    final pos = _lastPos;
    _lastDown = now;
    _lastPos = p;
    return last != null &&
        pos != null &&
        now.difference(last) < const Duration(milliseconds: 400) &&
        (p - pos).distance < 6;
  }

  @override
  bool onPointerDown(GridGeometry g, Offset local, PointerDownEvent event) {
    final dbl = _isDouble(local);
    if (ed.editor.isEditing || _modifiers || !ed.canEdit) return false;
    final hit = _cell(g, local);
    if (hit == null) return false;
    final (row, col, rect) = hit;
    final sid = g.sheet.id;
    final d = ed.cells.displayAt(sid, row, col);
    if (d != null && _onCheckbox(g, rect, d, local)) {
      ed.selection.selectCell(row, col);
      unawaited(
        ed.invokeCommand('sheets.dv.toggleCheckbox', {
          'cells': [CellPos(row, col).a1],
        }),
      );
      return true;
    }
    if (d != null && _onDropdown(g, rect, d, local)) {
      ed.selection.selectCell(row, col);
      c.openDropdown(sid, row, col);
      return true;
    }
    if (dbl && c.popupKindAt(sid, row, col) == CellPopupKind.date) {
      c.openDropdown(sid, row, col);
      return true;
    }
    return false;
  }

  @override
  MouseCursor? cursorAt(GridGeometry g, Offset local) {
    if (!ed.canEdit || ed.editor.isEditing) return null;
    final hit = _cell(g, local);
    if (hit == null) return null;
    final (row, col, rect) = hit;
    final d = ed.cells.displayAt(g.sheet.id, row, col);
    if (d == null) return null;
    if (_onCheckbox(g, rect, d, local) || _onDropdown(g, rect, d, local)) {
      return SystemMouseCursors.click;
    }
    return null;
  }
}
