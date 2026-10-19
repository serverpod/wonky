import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart'
    show
        FormulaEngine,
        FormulaLocale,
        GridRect,
        CellPos,
        ColumnLetters,
        RecalcBatch;
import 'package:wonky_sheets_core/model.dart';

import '../../l10n/sheets_l10n.dart';
import '../cell_editor/cell_editor_controller.dart';
import '../clipboard/clipboard_service.dart';
import '../grid/paint/cell_render_cache.dart';
import '../grid/paint/grid_layer.dart';
import '../grid/paint/layers/loading_layer.dart';
import '../grid/paint/text_layout_cache.dart';
import '../grid/selection/data_edge_finder.dart';
import '../grid/selection/grid_selection.dart';
import '../grid/selection/grid_selection_controller.dart';
import '../grid/viewport/grid_geometry.dart';
import '../grid/viewport/grid_scroll_controller.dart';
import '../model/loading_formula_source.dart';
import '../model/loading_gate.dart';
import '../model/sheets_undo.dart';
import '../model/workbook_session.dart';
import '../status/selection_stats.dart';
import 'write_gate.dart';

/// A repaint signal.
class GridSignal extends ChangeNotifier {
  /// Incremented by [fire] (cache keys).
  int get generation => _generation;
  int _generation = 0;

  void fire() {
    _generation++;
    notifyListeners();
  }
}

/// The copied/cut range shown with marching ants (03 §12.2).
@immutable
class ClipMark {
  const ClipMark(this.sheetId, this.rect, {this.cut = false, this.displayRect});

  final String sheetId;
  final GridRect rect;
  final bool cut;

  /// The copied rows on screen when they were copied in a sorted filter
  /// view's display order (07 §4.4), else null.
  final GridRect? displayRect;
}

/// Feedback painted while dragging (fill handle, resize, freeze bars, move).
sealed class DragFeedback {
  const DragFeedback();
}

/// Fill-handle preview (dashed outline over the target).
class FillDragFeedback extends DragFeedback {
  const FillDragFeedback(this.target);
  final GridRect target;
}

/// Drag-move preview (thick outline at the drop position).
class MoveDragFeedback extends DragFeedback {
  const MoveDragFeedback(this.target, {this.copy = false});
  final GridRect target;
  final bool copy;
}

/// Header resize guide line.
class ResizeDragFeedback extends DragFeedback {
  const ResizeDragFeedback({
    required this.columns,
    required this.index,
    required this.size,
  });

  final bool columns;
  final int index;

  /// New size at 100 % zoom.
  final double size;
}

/// Row/column header move: drop line before index [before].
class HeaderMoveDragFeedback extends DragFeedback {
  const HeaderMoveDragFeedback({required this.columns, required this.before});
  final bool columns;
  final int before;
}

/// Freeze bar drag (rows or columns count under the pointer).
class FreezeDragFeedback extends DragFeedback {
  const FreezeDragFeedback({required this.rows, required this.count});
  final bool rows;
  final int count;
}

/// Paint format armed state (06 §2).
@immutable
class PaintFormatState {
  const PaintFormatState(this.sheetId, this.source, {this.sticky = false});

  final String sheetId;
  final GridRect source;
  final bool sticky;
}

/// The spreadsheet editor (03 §1.1): wires the [WorkbookSession] (model,
/// engine, writes), the active sheet, selection, scroll/zoom, the cell
/// editor, the clipboard and the grid's repaint signals. Commands receive
/// it through `SheetsDocumentController.editor`; no widget writes the model
/// directly.
class SheetEditorController extends ChangeNotifier {
  SheetEditorController({
    required this.services,
    required this.session,
    String? initialSheetId,
    ClipboardService Function(SheetEditorController editor)? clipboard,
  }) {
    final first = _firstVisibleSheet();
    _activeSheetId =
        initialSheetId != null && model.sheet(initialSheetId) != null
        ? initialSheetId
        : first;
    selection = GridSelectionController(model, sheetId: _activeSheetId)
      ..rowOrder = (sid) => gridHooks.rowOrder?.call(sid);
    cells = CellRenderCache(
      model,
      session.rowLoading.complete
          ? session.engine.engine
          : LoadingFormulaSource(
              session.engine.engine,
              session.engine.engine,
              model,
              session.rowLoading,
            ),
    );
    editor = CellEditorController(this);
    this.clipboard = clipboard?.call(this) ?? ClipboardService(this);
    hooks = EngineFormulaHooks(
      model,
      engine: session.engine.engine,
      view: session.engine.view,
      // Formulas show in the spreadsheet's display language (04 §11.1).
      displayLanguage: true,
    );
    model.addListener(_onBatch);
    _recalc = engine.changes.listen(_onRecalc);
    selection.addListener(_onSelection);
    scroll.addListener(overlaySignal.fire);
    _watchLoading();
  }

  /// While rows stream in (02 §6): skeleton layer, and no edits of rows
  /// that aren't loaded (03 §2.8).
  void _watchLoading() {
    final loading = session.rowLoading;
    if (loading.complete) return;
    late final LoadingLayer layer;
    void gate(CommandContext? ctx, SheetsOperation op) {
      try {
        LoadingGate.checkRanges(op, model, loading);
      } on PlanException catch (e) {
        throw WriteRefused(e.message, code: e.code);
      }
    }

    // Formulas reading rows that arrive show "Loading…" until then.
    loading.addListener(_invalidateCells);
    _disposers.add(() => loading.removeListener(_invalidateCells));
    layer = LoadingLayer(
      loading,
      onDone: () {
        layers.remove(layer);
        writeGates.remove(gate);
        overlaySignal.fire();
      },
    );
    layers.add(layer);
    writeGates.add(gate);
    _disposers.add(layer.dispose);
  }

  final ShellServices services;
  final WorkbookSession session;

  WorkbookModel get model => session.model;
  FormulaEngine get engine => session.engine.engine;

  late String _activeSheetId;
  late final GridSelectionController selection;
  late final CellRenderCache cells;
  late final CellEditorController editor;
  late final ClipboardService clipboard;
  late final FormulaHooks hooks;

  final GridScrollController scroll = GridScrollController();
  final TextLayoutCache textCache = TextLayoutCache();
  final GridLayerRegistry layers = GridLayerRegistry();

  /// Feature hooks into grid painting and hit testing (filters, groups).
  final GridHooks gridHooks = GridHooks();

  /// Per-editor feature controllers (data tools, …) keyed by their type;
  /// see [extension].
  final Map<Object, Object> _extensions = {};
  final List<VoidCallback> _disposers = [];

  /// The feature controller under [key], created by [create] on first use.
  T extension<T extends Object>(Object key, T Function() create) =>
      _extensions.putIfAbsent(key, create) as T;

  /// The feature controller under [key], or null.
  T? extensionOrNull<T extends Object>(Object key) => _extensions[key] as T?;

  /// Runs [f] when the editor is disposed (feature controllers).
  void onDispose(VoidCallback f) => _disposers.add(f);

  /// Checks run by [apply] before an operation is written (protected
  /// ranges, data validation of typed input); see [WriteGate].
  final List<WriteGate> writeGates = [];

  /// Called after [apply] wrote an operation, inside the command's undo
  /// transaction (comments moving with cut cells record their entries).
  final List<
    void Function(CommandContext? ctx, SheetsOperation op, MutationPlan plan)
  >
  applyListeners = [];

  /// Fired when cell content/format/structure changes (content pass).
  final GridSignal contentSignal = GridSignal();

  /// Fired when selection, editing or drag state changes (overlay pass).
  final GridSignal overlaySignal = GridSignal();

  final ValueNotifier<ClipMark?> clipMark = ValueNotifier(null);

  /// Marching-ants animation phase (px).
  final ValueNotifier<double> antsPhase = ValueNotifier(0);
  final ValueNotifier<DragFeedback?> drag = ValueNotifier(null);
  final ValueNotifier<PaintFormatState?> paintFormat = ValueNotifier(null);

  /// Grid focus (keyboard scope `grid`).
  final FocusNode gridFocus = FocusNode(debugLabel: 'sheets.grid');

  /// Name box focus (`sheets.nav.goTo` focuses it).
  final FocusNode nameBoxFocus = FocusNode(debugLabel: 'sheets.nameBox');

  /// Sheet tab being renamed inline (`sheets.sheet.startRename`).
  final ValueNotifier<String?> renamingSheet = ValueNotifier(null);

  StreamSubscription<Object?>? _recalc;

  /// The grid viewport's size and device pixel ratio, set by the grid's
  /// layout (null before the first layout).
  Size? _viewSize;
  double _viewDpr = 1;

  /// Called by the grid's layout with its size (S-06).
  void setViewport(Size size, double devicePixelRatio) {
    _viewSize = size;
    _viewDpr = devicePixelRatio;
  }

  /// The geometry of the grid viewport at the current scroll, zoom and model
  /// state (hit testing, overlays, both paint passes), or null before the
  /// grid's first layout. Computed once per change and shared, so widgets
  /// built before this frame's paint position with this frame's geometry
  /// (S-06, CQ-41).
  GridGeometry? get geometry {
    final size = _viewSize;
    return size == null ? null : geometryFor(size, _viewDpr);
  }

  GridGeometry? _memoGeometry;
  Object? _memoKey;

  bool _viewMode = false;
  bool showFormulas = false;
  bool showFormulaBar = true;
  bool formulaBarExpanded = false;

  /// Column where a Tab sequence started (Enter returns there, 03 §7.1).
  int? tabStartCol;

  /// The aggregate shown by the selection stats button (null = default).
  SelectionStat? shownStat;

  /// Opens the cell context menu at the active cell (Shift+F10); set by the
  /// screen.
  VoidCallback? openContextMenu;

  /// Called instead of the generic toast when the cell being edited is
  /// deleted remotely (collaboration names who deleted it, 03 §15.3).
  void Function(String sheetId, String rowId, String colId)?
  onEditedCellDeleted;

  /// Last formatting/structure command for `sheets.edit.repeatLast`.
  (String, Map<String, Object?>)? lastRepeatable;

  /// Handlers of a double-click on a cell before editing starts (pivot
  /// drill-down); return true when handled.
  final List<bool Function(int row, int col)> cellDoubleClickHandlers = [];

  // ---------------------------------------------------------------------------
  // State.

  String get activeSheetId => _activeSheetId;

  SheetModel? get activeSheet => model.sheet(_activeSheetId);

  /// The user's role on the drive item (the session's role may be broader
  /// while the data layer doesn't know the share yet).
  Role _itemRole = Role.owner;
  Role get itemRole => _itemRole;
  set itemRole(Role r) {
    if (r == _itemRole) return;
    _itemRole = r;
    if (!roleCanEdit) editor.cancel();
    notifyListeners();
    overlaySignal.fire();
  }

  bool _readOnlyView = false;

  /// The mobile read-only view (suite 02 §6.1): no editing whatever the
  /// role, and View › Mode › Editing is off.
  bool get readOnlyView => _readOnlyView;
  set readOnlyView(bool v) {
    if (v == _readOnlyView) return;
    _readOnlyView = v;
    if (v) editor.cancel();
    notifyListeners();
    overlaySignal.fire();
  }

  /// Whether the role allows editing (editor or owner; never in the mobile
  /// read-only view).
  bool get roleCanEdit =>
      !_readOnlyView && session.canEdit && _itemRole >= Role.editor;

  /// Whether the user may edit (role ≥ editor and not in Viewing mode).
  bool get canEdit => roleCanEdit && !_viewMode;

  /// View mode chosen by the user (View › Mode › Viewing) or forced by role.
  bool get viewMode => _viewMode || !roleCanEdit;

  set viewMode(bool v) {
    if (v == _viewMode) return;
    _viewMode = v;
    if (v) editor.cancel();
    notifyListeners();
    overlaySignal.fire();
  }

  String get locale => model.spreadsheet.locale;

  /// The formula locale of the editor UI: separators of [locale], function
  /// names and booleans in the display language (04 §11.1, P2).
  FormulaLocale get formulaLocale => FormulaLocale.forId(
    locale,
  ).withLanguage(model.spreadsheet.displayLanguage);

  SheetsLocalizations get l10n => sheetsL10nOf(services);

  String _firstVisibleSheet() {
    final visible = model.visibleSheets;
    if (visible.isNotEmpty) return visible.first.id;
    final all = model.sheets;
    return all.isEmpty ? '' : all.first.id;
  }

  void _onBatch(WorkbookChangeBatch batch) {
    _reorderedRows.clear();
    for (final e in batch.events) {
      if (e is StructureChanged && e.order && e.dimension == Dimension.rows) {
        _reorderedRows.add(e.sheetId);
      }
    }
    if (model.sheet(_activeSheetId) == null ||
        (model.sheet(_activeSheetId)?.record?.hidden ?? false)) {
      final next = _firstVisibleSheet();
      if (next.isNotEmpty && next != _activeSheetId) {
        _activeSheetId = next;
        selection.setSheet(next);
      }
    }
    final editing = editor.session;
    if (editing != null) {
      final s = model.sheet(editing.sheetId);
      if (s == null ||
          !s.rows.contains(editing.rowId) ||
          !s.columns.contains(editing.colId)) {
        editor.cancel();
        final hook = onEditedCellDeleted;
        if (hook != null) {
          hook(editing.sheetId, editing.rowId, editing.colId);
        } else {
          services.toasts.show(l10n.toastEditedRowDeleted);
        }
      }
    }
    cells.invalidateBatch(batch);
    _repaintCells();
    selection.modelChanged();
    notifyListeners();
  }

  void _invalidateCells() {
    cells.invalidate();
    _repaintCells();
  }

  /// Recalculated values: only those cells leave the render cache (03 §2.7).
  void _onRecalc(RecalcBatch batch) {
    cells.invalidateRecalc(batch);
    _repaintCells();
  }

  void _repaintCells() {
    contentSignal.fire();
    overlaySignal.fire();
  }

  void _onSelection() {
    overlaySignal.fire();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Writes.

  /// Plans and applies [op]; records the plan as one `sheets.rows` undo
  /// entry in the open transaction of [ctx]. Throws `PlanException`.
  MutationPlan apply(CommandContext? ctx, SheetsOperation op) {
    for (final gate in List.of(writeGates)) {
      gate(ctx, op);
    }
    final plan = session.execute(op);
    if (!plan.isEmpty && ctx?.transaction != null) {
      ctx!.record(
        SheetsRowsUndoEntry(
          plan.changes,
          label: plan.label,
          groupId: session.groupOf(plan),
        ),
      );
    }
    for (final l in List.of(applyListeners)) {
      l(ctx, op, plan);
    }
    return plan;
  }

  /// Invokes a command from a grid control (typing commit, drags, tabs).
  /// Failures show a toast; returns whether the command succeeded.
  Future<bool> invokeCommand(
    String id, [
    Map<String, Object?> args = const {},
    InvocationSource source = InvocationSource.ui,
  ]) async => (await services.invokeWithToasts(
    id,
    args: args,
    source: source,
    context: services.navigatorContext,
  )).isOk;

  /// The selected ranges (all of them) as core ranges.
  List<ResolvedRange> get selectedRanges =>
      selection.resolved.toResolvedRanges();

  /// The active range only.
  ResolvedRange get activeRange {
    final r = selection.resolved;
    final x = r.activeRange;
    return ResolvedRange(
      r.sheetId,
      x.rect,
      wholeRows: x.wholeRows,
      wholeColumns: x.wholeColumns,
    );
  }

  // ---------------------------------------------------------------------------
  // Sheets.

  /// Activates [sheetId] (03 §6.4: selections and scroll are kept per sheet).
  void activateSheet(String sheetId) {
    if (sheetId == _activeSheetId || model.sheet(sheetId) == null) return;
    if (editor.isEditing && !editor.isFormula) editor.commitSync();
    scroll.switchSheet(_activeSheetId, sheetId);
    _activeSheetId = sheetId;
    selection.setSheet(sheetId);
    clipMark.value = clipMark.value?.sheetId == sheetId ? clipMark.value : null;
    contentSignal.fire();
    overlaySignal.fire();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Selection snapshots (undo).

  static const selectionDomain = 'sheets.grid';

  /// The selection by ids plus the index rectangles it covered (`idx`):
  /// undoing/redoing a reorder (sort, randomize) restores the indices, so
  /// the selection stays where it was instead of following the rows
  /// (as `applyKeepingSelection` does for the command itself).
  SelectionSnapshot captureSelection() {
    final r = selection.resolved;
    return SelectionSnapshot(selectionDomain, {
      ...selection.selection.toJson(),
      'idx': {
        'ranges': [
          for (final x in r.ranges)
            [x.kind.name, x.rect.top, x.rect.left, x.rect.bottom, x.rect.right],
        ],
        'i': r.activeRangeIndex,
        'ar': r.activeRow,
        'ac': r.activeCol,
        'nr': r.anchorRow,
        'nc': r.anchorCol,
      },
    });
  }

  void restoreSelection(SelectionSnapshot snapshot) {
    if (snapshot.domain != selectionDomain) return;
    final sel = GridSelection.fromJson(snapshot.data);
    if (sel == null || model.sheet(sel.sheetId) == null) return;
    if (sel.sheetId != _activeSheetId) activateSheet(sel.sheetId);
    final idx = snapshot.data['idx'];
    if (_reorderedRows.contains(sel.sheetId) && idx is Map) {
      _reorderedRows.clear();
      if (_restoreIndices(idx)) {
        revealActive();
        return;
      }
    }
    selection.restore(sel);
    revealActive();
  }

  /// Sheets whose rows were reordered (same count, new order) by the last
  /// model batch: an undo/redo of a sort.
  final Set<String> _reorderedRows = {};

  bool _restoreIndices(Map<dynamic, dynamic> idx) {
    final raw = idx['ranges'];
    if (raw is! List || raw.isEmpty) return false;
    final ranges = <(SelectionKind, GridRect)>[];
    for (final e in raw) {
      if (e is! List || e.length != 5) return false;
      final kind = SelectionKind.values
          .where((k) => k.name == e[0])
          .firstOrNull;
      if (kind == null) return false;
      ranges.add((
        kind,
        GridRect(e[1] as int, e[2] as int, e[3] as int, e[4] as int),
      ));
    }
    selection.setRanges(
      ranges,
      activeIndex: idx['i'] as int?,
      activeRow: idx['ar'] as int?,
      activeCol: idx['ac'] as int?,
      anchorRow: idx['nr'] as int?,
      anchorCol: idx['nc'] as int?,
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Geometry and scrolling.

  /// The geometry for a viewport of [size]; the one of the laid-out grid
  /// viewport is memoized until the scroll, zoom, sheet or a repaint signal
  /// changes, and keeps the scroll limits up to date.
  GridGeometry? geometryFor(Size size, double dpr) {
    final s = activeSheet;
    if (s == null) return null;
    final viewport = size == _viewSize && dpr == _viewDpr;
    final key = viewport
        ? (
            s,
            size,
            dpr,
            scroll.zoom,
            scroll.x,
            scroll.y,
            contentSignal.generation,
            overlaySignal.generation,
          )
        : null;
    if (key != null && key == _memoKey) return _memoGeometry;
    final g = _computeGeometry(s, size, dpr);
    if (key != null) {
      _memoKey = key;
      _memoGeometry = g;
      scroll.updateLimits(
        maxX: g.maxScrollX,
        maxY: g.maxScrollY,
        viewport: g.main.rect.size,
      );
    }
    return g;
  }

  GridGeometry _computeGeometry(SheetModel s, Size size, double dpr) {
    final gutters = gridHooks.gutters?.call(s);
    return GridGeometry(
      sheet: s,
      size: size,
      zoom: scroll.zoom,
      scrollX: scroll.x,
      scrollY: scroll.y,
      devicePixelRatio: dpr,
      rowGutter: gutters?.rows ?? 0,
      colGutter: gutters?.cols ?? 0,
      rowOrder: gridHooks.rowOrder?.call(s.id),
    );
  }

  /// The row display order of the active sheet (a sorted filter view,
  /// 07 §4.4), or null.
  ViewRowOrder? get rowOrder => gridHooks.rowOrder?.call(_activeSheetId);

  /// Whether rows of [r] are shown in a sorted display order: drags that
  /// work on model rows (fill handle, move, row reorder) are off there.
  bool rowsPermuted(GridRect r) {
    final o = rowOrder;
    return o != null && r.bottom >= o.top && r.top <= o.bottom;
  }

  /// Sets the zoom (50–200 %), keeping the active cell in view.
  void setZoom(double zoom) {
    scroll.setZoom(zoom);
    notifyZoom();
    WidgetsBinding.instance.addPostFrameCallback((_) => revealActive());
  }

  /// Zoom changed (toolbar label, text layouts).
  void notifyZoom() {
    contentSignal.fire();
    overlaySignal.fire();
    notifyListeners();
  }

  /// Scrolls minimally so that (row, col) is fully visible.
  void revealCell(int row, int col) {
    final g = geometry;
    if (g == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (geometry != null) revealCell(row, col);
      });
      return;
    }
    final fresh = geometryFor(g.size, g.devicePixelRatio)!;
    final t = fresh.scrollToReveal(row, col);
    if (t != null) scroll.jumpTo(t.x, t.y);
  }

  void revealActive() {
    final r = selection.resolved;
    revealCell(r.activeRow, r.activeCol);
  }

  // ---------------------------------------------------------------------------
  // Navigation (03 §6–7).

  DataEdgeFinder edgeFinder() => DataEdgeFinder(
    activeSheet!,
    hasValue: (r, c) =>
        engine.overlayAt(_activeSheetId, r, c) != null ||
        (session.engine.view.overlays?.inputAt(_activeSheetId, r, c) != null &&
            model.cellAt(_activeSheetId, r, c)?.content == null),
  );

  /// Moves (or extends) the active cell one visible cell / to the data edge.
  void moveActive(NavDirection d, {bool extend = false, bool toEdge = false}) {
    final s = activeSheet;
    if (s == null) return;
    final r = selection.resolved;
    tabStartCol = null;
    // When extending, move the focus corner (opposite the anchor).
    var row = r.activeRow;
    var col = r.activeCol;
    // A sorted filter view navigates rows in display order (07 §4.4).
    final order = rowOrder;
    if (extend) {
      final rect = r.activeRange.rect;
      final shown = r.activeRange.displayRect;
      if (order != null) {
        // The focus corner on screen: the display end away from the anchor.
        final dRect =
            shown ??
            GridRect(
              order.displayRow(rect.top),
              rect.left,
              order.displayRow(rect.bottom),
              rect.right,
            );
        final da = order.displayRow(r.anchorRow);
        row = order.modelRow(da == dRect.top ? dRect.bottom : dRect.top);
      } else {
        row = r.anchorRow == rect.top ? rect.bottom : rect.top;
      }
      col = r.anchorCol == rect.left ? rect.right : rect.left;
    } else {
      // Step over the merge containing the active cell.
      final m = s.mergeAt(row, col);
      if (m != null) {
        row = d == NavDirection.down
            ? m.bottom
            : (d == NavDirection.up ? m.top : row);
        col = d == NavDirection.right
            ? m.right
            : (d == NavDirection.left ? m.left : col);
      }
    }
    int nr;
    int nc;
    if (toEdge && order != null && d.vertical && order.contains(row)) {
      // Inside a sorted block: its first/last row on screen.
      nc = col;
      final edge = d.dRow > 0 ? order.bottom : order.top;
      final dr = s.rows.isHidden(order.modelRow(edge))
          ? order.nextVisibleDisplay(s.rows, edge, -d.dRow)
          : edge;
      nr = dr == null ? row : order.modelRow(dr);
    } else if (toEdge) {
      (nr, nc) = edgeFinder().next(row, col, d);
    } else {
      nr = row;
      nc = col;
      if (d.vertical && order != null) {
        final dn = order.nextVisibleDisplay(
          s.rows,
          order.displayRow(row),
          d.dRow,
        );
        if (dn != null) nr = order.modelRow(dn);
      } else if (d.vertical) {
        final next = row + d.dRow;
        if (next >= 0 && next < s.rows.length) {
          nr = s.rows.nextVisible(next, d.dRow) ?? row;
        }
      } else {
        final next = col + d.dCol;
        if (next >= 0 && next < s.columns.length) {
          nc = s.columns.nextVisible(next, d.dCol) ?? col;
        }
      }
    }
    if (extend) {
      selection.extendTo(nr, nc);
    } else {
      selection.selectCell(nr, nc);
    }
    revealCell(nr, nc);
  }

  /// Enter / Shift+Enter (03 §7.1): down/up, cycling inside a multi-cell
  /// selection; after Tabs, returns to the column where they started.
  void enterMove({bool reverse = false}) {
    final s = activeSheet;
    if (s == null) return;
    final r = selection.resolved;
    final range = r.activeRange.rect;
    if (range.cellCount > 1 && !_isSingleMerge(s, range)) {
      final (row, col) = _cycle(
        s,
        range,
        r.activeRow,
        r.activeCol,
        rowMajor: false,
        reverse: reverse,
      );
      selection.setActiveInSelection(r.activeRangeIndex, row, col);
      revealCell(row, col);
      return;
    }
    final startCol = tabStartCol;
    if (startCol != null && !reverse) {
      tabStartCol = null;
      final order = rowOrder;
      final shownNext = order?.nextVisibleDisplay(
        s.rows,
        order.displayRow(range.bottom),
        1,
      );
      final next = order != null
          ? (shownNext == null ? null : order.modelRow(shownNext))
          : s.rows.nextVisible(
              math.min(s.rows.length - 1, range.bottom + 1),
              1,
            );
      final row = next ?? range.bottom;
      selection.selectCell(row, startCol);
      revealCell(row, startCol);
      return;
    }
    moveActive(reverse ? NavDirection.up : NavDirection.down);
  }

  /// Tab / Shift+Tab.
  void tabMove({bool reverse = false}) {
    final s = activeSheet;
    if (s == null) return;
    final r = selection.resolved;
    final range = r.activeRange.rect;
    if (range.cellCount > 1 && !_isSingleMerge(s, range)) {
      final (row, col) = _cycle(
        s,
        range,
        r.activeRow,
        r.activeCol,
        rowMajor: true,
        reverse: reverse,
      );
      selection.setActiveInSelection(r.activeRangeIndex, row, col);
      revealCell(row, col);
      return;
    }
    final start = tabStartCol ?? r.activeCol;
    moveActive(reverse ? NavDirection.left : NavDirection.right);
    tabStartCol = reverse ? null : start;
  }

  bool _isSingleMerge(SheetModel s, GridRect rect) =>
      s.mergeAt(rect.top, rect.left) == rect;

  (int, int) _cycle(
    SheetModel s,
    GridRect range,
    int row,
    int col, {
    required bool rowMajor,
    required bool reverse,
  }) {
    var r = row;
    var c = col;
    final step = reverse ? -1 : 1;
    for (var guard = 0; guard < range.cellCount + 1; guard++) {
      if (rowMajor) {
        c += step;
        if (c > range.right) {
          c = range.left;
          r = r >= range.bottom ? range.top : r + 1;
        } else if (c < range.left) {
          c = range.right;
          r = r <= range.top ? range.bottom : r - 1;
        }
      } else {
        r += step;
        if (r > range.bottom) {
          r = range.top;
          c = c >= range.right ? range.left : c + 1;
        } else if (r < range.top) {
          r = range.bottom;
          c = c <= range.left ? range.right : c - 1;
        }
      }
      if (s.rows.isHidden(r) || s.columns.isHidden(c)) continue;
      final m = s.mergeAt(r, c);
      if (m != null && (m.top != r || m.left != c)) continue;
      return (r, c);
    }
    return (row, col);
  }

  /// Home / End / Mod+Home / Mod+End.
  void jumpTo(int row, int col, {bool extend = false}) {
    final s = activeSheet;
    if (s == null) return;
    final r = row.clamp(0, s.rows.length - 1);
    final c = col.clamp(0, s.columns.length - 1);
    if (extend) {
      selection.extendTo(r, c);
    } else {
      selection.selectCell(r, c);
    }
    revealCell(r, c);
  }

  /// PageUp/PageDown (vertical) or Alt+PageUp/Down (horizontal).
  void page(NavDirection d) {
    final g = geometry;
    final s = activeSheet;
    if (g == null || s == null) return;
    final r = selection.resolved;
    if (d.vertical) {
      final visible = math.max(
        1,
        g.main.displayRowEnd - g.main.displayRowStart,
      );
      final row = g.modelRow(
        (g.displayRow(r.activeRow) + d.dRow * visible).clamp(
          0,
          s.rows.length - 1,
        ),
      );
      scroll.scrollBy(0, d.dRow * g.main.rect.height);
      selection.selectCell(row, r.activeCol);
      revealCell(row, r.activeCol);
    } else {
      final visible = math.max(1, g.main.colEnd - g.main.colStart);
      final col = (r.activeCol + d.dCol * visible).clamp(
        0,
        s.columns.length - 1,
      );
      scroll.scrollBy(d.dCol * g.main.rect.width, 0);
      selection.selectCell(r.activeRow, col);
      revealCell(r.activeRow, col);
    }
  }

  /// Selects an A1 target (`B4`, `A1:C3`, `Sheet2!B5`, a named range).
  /// Returns false when it doesn't resolve.
  bool goTo(String target) {
    final ResolvedRange rr;
    try {
      rr = model.parseA1(target, contextSheetId: _activeSheetId);
    } on InvalidRangeException {
      return false;
    }
    if (rr.sheetId != _activeSheetId) activateSheet(rr.sheetId);
    final kind = rr.wholeSheet
        ? SelectionKind.all
        : rr.wholeRows
        ? SelectionKind.rows
        : rr.wholeColumns
        ? SelectionKind.columns
        : SelectionKind.cells;
    final rect = kind == SelectionKind.cells
        ? GridSelectionController.expandMerges(activeSheet!, rr.rect)
        : rr.rect;
    selection.setRanges([(kind, rect)]);
    revealCell(rect.top, rect.left);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Cell queries.

  /// Why typing into ([row], [col]) of the active sheet is refused by a
  /// [writeGates] gate (pivot output, protection), or null.
  String? editRefusalAt(int row, int col) {
    final op = SetCellInputs(
      sheetId: _activeSheetId,
      row: row,
      col: col,
      inputs: const [
        [CellInput.user('')],
      ],
    );
    for (final gate in List.of(writeGates)) {
      try {
        gate(null, op);
      } on WriteRefused catch (e) {
        return e.message;
      } on WriteNeedsConfirmation {
        // Asked when the edit is committed.
      }
    }
    return null;
  }

  /// The text the editor shows for a cell (03 §8.2).
  String editableText(int row, int col, {String? sheetId}) {
    final sid = sheetId ?? _activeSheetId;
    final rec = model.cellAt(sid, row, col);
    final content = rec?.decoded;
    switch (content) {
      case null:
        return '';
      case FormulaContent(:final text):
        return hooks.toA1(
          text,
          sheetId: sid,
          row: row,
          col: col,
          locale: locale,
        );
      case TextContent(:final text):
        final v = InputParser.instance.parseValue(
          InputParser.trimAscii(text),
          locale: locale,
        );
        return v != null || text.startsWith("'") || text.startsWith('=')
            ? "'$text"
            : text;
      case NumberContent(:final number):
        final f = cells.displayAt(sid, row, col);
        final pattern = f?.numberFormat;
        if (pattern != null &&
            (NumberFormatInfo.isDatePattern(pattern, locale: locale) ||
                NumberFormatInfo.isTimePattern(pattern, locale: locale) ||
                NumberFormatInfo.isPercentPattern(pattern, locale: locale))) {
          return f!.text;
        }
        return CellContent.formatNumber(number);
      case BoolContent(:final value):
        return value ? 'TRUE' : 'FALSE';
      case ErrorContent(:final kind):
        return kind.literal;
      case RichTextContent():
        return content.plainText ?? '';
    }
  }

  /// The effective format of the active cell (toolbar state).
  ResolvedFormat activeFormat() {
    final r = selection.resolved;
    final d = cells.displayAt(_activeSheetId, r.activeRow, r.activeCol);
    return d?.format ??
        EffectiveFormatResolver(
          model,
        ).resolve(_activeSheetId, r.activeRow, r.activeCol);
  }

  /// The display of the active cell (null when empty).
  CellDisplay? activeDisplay() {
    final r = selection.resolved;
    return cells.displayAt(_activeSheetId, r.activeRow, r.activeCol);
  }

  /// A1 of the active cell.
  String get activeA1 {
    final r = selection.resolved;
    return CellPos(r.activeRow, r.activeCol).a1;
  }

  String columnLabel(int col) => ColumnLetters.fromIndex(col);

  // ---------------------------------------------------------------------------
  // Describe (MCP ui.get_state).

  Map<String, Object?> describeState() {
    final r = selection.resolved;
    return {
      'sheet': activeSheet?.name,
      'sheetId': _activeSheetId,
      'sheets': [for (final s in model.sheets) s.name],
      'selection': [
        for (final x in r.ranges)
          x.rect.isSingleCell ? CellPos(x.rect.top, x.rect.left).a1 : x.rect.a1,
      ],
      'activeCell': activeA1,
      'editing': editor.isEditing,
      'zoom': (scroll.zoom * 100).round(),
      'frozenRows': activeSheet?.record?.frozenRows ?? 0,
      'frozenColumns': activeSheet?.record?.frozenColumns ?? 0,
      'canEdit': canEdit,
    };
  }

  @override
  void dispose() {
    for (final f in _disposers.reversed) {
      f();
    }
    _disposers.clear();
    model.removeListener(_onBatch);
    unawaited(_recalc?.cancel());
    selection.removeListener(_onSelection);
    selection.dispose();
    scroll.dispose();
    editor.dispose();
    textCache.clear();
    layers.dispose();
    contentSignal.dispose();
    overlaySignal.dispose();
    clipMark.dispose();
    antsPhase.dispose();
    drag.dispose();
    paintFormat.dispose();
    gridFocus.dispose();
    nameBoxFocus.dispose();
    renamingSheet.dispose();
    super.dispose();
  }
}
