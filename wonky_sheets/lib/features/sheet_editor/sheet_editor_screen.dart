import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_ui/wonky_ui.dart';

import '../../config/context_menus.dart';
import '../../config/sheets_menus.dart';
import '../../l10n/sheets_l10n.dart';
import '../data_tools/data_tools_screen.dart';
import '../assistant/sheets_assistant_panel.dart';
import '../charts/editor/chart_editor_panel.dart';
import '../collab/collab_overlay.dart';
import '../collab/sheets_collab.dart';
import '../explore/explore_panel.dart';
import '../formatting/format_menus.dart';
import '../formatting/formatting_panels.dart';
import '../import/grid_drop_target.dart';
import '../macros/macro_recording_bar.dart';
import '../macros/macro_service.dart';
import '../formula_bar/formula_bar.dart';
import '../grid/grid_area.dart';
import '../in_cell/cell_features.dart';
import '../model/local_view_state.dart';
import '../model/workbook_session.dart';
import '../objects/objects_layer.dart';
import '../pivot/pivot_controller.dart';
import '../pivot/ui/pivot_editor_panel.dart';
import '../scripts/runtime/script_panels.dart';
import '../scripts/executions_panel.dart';
import '../status/selection_stats_button.dart';
import '../sync/sheets_sessions.dart';
import '../sync/synced_workbook_session.dart'
    show SyncedWorkbookSession, ViewportHint;
import '../tab_bar/sheet_tab_bar.dart';
import '../toolbar/command_ui.dart';
import '../toolbar/sheets_toolbar.dart';
import 'sheet_editor_controller.dart';
import 'sheets_document_controller.dart';
import 'view_state_binding.dart';

/// Opens the workbook session of a spreadsheet (tests inject fakes).
typedef WorkbookSessionFactory =
    Future<WorkbookSession> Function(ShellServices services, UuidValue item);

/// The spreadsheet editor `/s/:uuid` (04 §2): the shell's `EditorScaffold`
/// (title row, menubar, panels) around the Sheets toolbar, formula bar,
/// grid, sheet tab bar and status bar.
class SheetEditorScreen extends StatefulWidget {
  const SheetEditorScreen({
    super.key,
    required this.services,
    required this.itemUuid,
    this.sessionFactory,
    this.initialSheetId,
    this.initialRange,
    this.initialFilterView,
  });

  final ShellServices services;
  final String itemUuid;
  final WorkbookSessionFactory? sessionFactory;

  /// `?sheet=<sheetId>&range=A1:B9` deep link.
  final String? initialSheetId;
  final String? initialRange;

  /// `?fv=<filterViewId>` deep link (07 §4.1).
  final String? initialFilterView;

  @override
  State<SheetEditorScreen> createState() => _SheetEditorScreenState();
}

class _SheetEditorScreenState extends State<SheetEditorScreen> {
  late final SheetsDocumentController doc = SheetsDocumentController(
    services: s,
    itemUuid: UuidValue.fromString(widget.itemUuid),
  );
  WorkbookSession? _session;
  SheetEditorController? _editor;
  Object? _error;
  final _toolbar = WonkyToolbarController();
  final _gridKey = GlobalKey();
  bool _disposed = false;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    if (kIsWeb) unawaited(BrowserContextMenu.disableContextMenu());
  }

  Future<void> _open() async {
    try {
      final factory = widget.sessionFactory ?? openWorkbookSession;
      final session = await factory(s, UuidValue.fromString(widget.itemUuid));
      if (_disposed) {
        unawaited(session.dispose());
        return;
      }
      _session = session;
      // `?gid=`: that sheet's first rows load first (viewport-first).
      final gid = widget.initialSheetId;
      if (gid != null &&
          session is SyncedWorkbookSession &&
          session.viewportHint?.sheetId != gid) {
        session.viewportHint = ViewportHint(sheetId: gid);
      }
      session.loadState.addListener(_onLoadState);
      _onLoadState();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onLoadState() {
    final session = _session;
    if (session == null || !mounted) return;
    if (session.loadState.value is WorkbookReady && _editor == null) {
      final editor = SheetEditorController(
        services: s,
        session: session,
        initialSheetId: widget.initialSheetId,
      );
      editor.openContextMenu = _openMenuAtActive;
      doc.attach(editor);
      _editor = editor;
      SheetsCollab.attach(editor, presence: doc.presence);
      PivotController.of(editor);
      attachDataTools(editor, filterView: widget.initialFilterView);
      attachCellFeatures(editor);
      attachFormatting(editor);
      // Scripts: last good build, custom functions, onOpen menus, macros.
      MacroService.of(editor);
      // Where the user left it (LocalViewState); the route's sheet/range win.
      ViewStateBinding.attach(
        editor,
        LocalViewStateStore(s.userStore),
        restoreSheet: widget.initialSheetId == null,
        restoreSelection: widget.initialRange == null,
      );
      final range = widget.initialRange;
      if (range != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => editor.goTo(range));
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    if (kIsWeb) unawaited(BrowserContextMenu.enableContextMenu());
    _session?.loadState.removeListener(_onLoadState);
    final editor = _editor;
    final session = _session;
    // The shell deactivates the document after this frame; dispose after.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (editor != null) SheetsCollab.of(editor)?.dispose();
      if (editor != null) detachFormatting(editor);
      editor?.dispose();
      doc.dispose();
      if (session != null) unawaited(session.dispose());
    });
    super.dispose();
  }

  void _openMenu(GridMenuKind kind, Offset global) {
    final editor = _editor;
    final ctx = _gridKey.currentContext;
    if (editor == null || ctx == null) return;
    WonkyPopupMenuHost.maybeOf(ctx)?.show(
      global,
      () => gridContextMenu(CommandUi(ctx, s), editor, kind),
      onClosed: () => editor.gridFocus.requestFocus(),
    );
  }

  void _openMenuAtActive() {
    final editor = _editor;
    final ctx = _gridKey.currentContext;
    final g = editor?.lastGeometry;
    if (editor == null || ctx == null || g == null) return;
    final r = editor.selection.resolved;
    final rect = g.cellRect(r.activeRow, r.activeCol);
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    _openMenu(GridMenuKind.cell, box.localToGlobal(rect.bottomLeft));
  }

  MenuCustomItems _menuItems(SheetEditorController? editor) {
    if (editor == null) return const MenuCustomItems();
    return MenuCustomItems(
      entries: {
        ...dataToolsMenuEntries(s, editor),
        SheetsMenuIds.freezeRowsDynamic: (context) {
          final ui = CommandUi(context, s);
          final row = editor.selection.resolved.activeRow + 1;
          return [
            if (row > 2)
              ui.item(
                'sheets.view.freezeRows',
                args: {'count': row},
                label: ui.l.freezeUpToRow(row),
                radio: true,
                keyName: 'view.freeze.upToRow',
              ),
          ];
        },
        SheetsMenuIds.freezeColumnsDynamic: (context) {
          final ui = CommandUi(context, s);
          final col = editor.selection.resolved.activeCol;
          return [
            if (col > 1)
              ui.item(
                'sheets.view.freezeColumns',
                args: {'count': col + 1},
                label: ui.l.freezeUpToColumn(editor.columnLabel(col)),
                radio: true,
                keyName: 'view.freeze.upToColumn',
              ),
          ];
        },
        SheetsMenuIds.recentNumberFormats: (context) =>
            recentNumberFormatEntries(CommandUi(context, s), editor),
        SheetsMenuIds.hiddenSheets: (context) {
          final ui = CommandUi(context, s);
          final hidden = [
            for (final sh in editor.model.sheets)
              if (sh.record!.hidden) sh,
          ];
          if (hidden.isEmpty) {
            return [
              WonkyMenuItem(label: ui.l.menuNoHiddenSheets, enabled: false),
            ];
          }
          return [
            for (final sh in hidden)
              ui.item(
                'sheets.sheet.unhide',
                args: {'sheetId': sh.id},
                label: sh.name,
                keyName: 'view.hiddenSheets.${sh.id}',
              ),
          ];
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editor = _editor;
    return EditorScaffold(
      key: ValueKey<String>('sheets.screen.${widget.itemUuid}'),
      services: s,
      itemUuid: widget.itemUuid,
      controller: doc,
      onItemLoaded: (item) => doc.update(title: item.name, role: item.myRole),
      syncStatus: _session?.syncStatus,
      customMenuItems: _menuItems(editor),
      panels: [
        if (editor != null) ...dataToolsPanelSpecs(context, editor),
        if (editor != null)
          SidePanelSpec(
            id: PivotController.panelId,
            title: sheetsL10n(context).pivotPanelTitle,
            icon: LucideIcons.table2,
            // Opened by its commands and the pivot's Edit button.
            showAsTab: false,
            builder: (_) => PivotEditorPanel(editor: editor),
          ),
        if (editor != null) explorePanelSpec(s, editor),
        if (editor != null) ...cellFeaturePanelSpecs(context, s, editor),
        if (editor != null) chartEditorPanelSpec(context, s, editor),
        if (editor != null) ...formattingPanelSpecs(context, s, editor),
        if (editor != null) scriptExecutionsPanelSpec(context, editor),
        if (editor != null) scriptSidebarPanelSpec(context, editor),
        ?sheetsAssistantPanelSpec(s, editor),
      ],
      toolbar: (context) => editor == null
          ? SizedBox(height: WonkyThemeScope.of(context).toolbarButtonSize + 8)
          : SheetsToolbar(services: s, editor: editor, controller: _toolbar),
      body: (context, item) => _body(context),
      statusLeft: (context) =>
          editor == null ? const [] : [SheetsStatusLeft(controller: editor)],
      statusRight: (context) =>
          editor == null ? const [] : [SheetsStatusRight(controller: editor)],
    );
  }

  Widget _body(BuildContext context) {
    final l = sheetsL10n(context);
    final err = _error;
    if (err != null) {
      return WonkyEmptyState(
        illustration: EmptyIllustration.error,
        title: l.screenOpenFailed,
        description: errorMessage(err),
        actions: [
          ShadButton.outline(
            onPressed: () {
              setState(() => _error = null);
              unawaited(_open());
            },
            child: Text(l.screenTryAgain),
          ),
        ],
      );
    }
    final session = _session;
    if (session == null) return const SpreadsheetLoadingView(progress: null);
    return ValueListenableBuilder<WorkbookLoadState>(
      valueListenable: session.loadState,
      builder: (context, state, _) {
        switch (state) {
          case WorkbookLoading(:final progress):
            return SpreadsheetLoadingView(progress: progress);
          case WorkbookUnavailable(:final reason, :final offline):
            return WonkyEmptyState(
              key: const ValueKey<String>('sheets.unavailable'),
              illustration: offline
                  ? EmptyIllustration.offline
                  : EmptyIllustration.error,
              title: offline ? l.screenOfflineUnavailable : l.screenUnavailable,
              description: reason,
              actions: [
                ShadButton.ghost(
                  onPressed: () => s.router.go('/'),
                  child: Text(l.screenGoHome),
                ),
              ],
            );
          case WorkbookReady():
            final editor = _editor;
            if (editor == null) {
              return const SpreadsheetLoadingView(progress: null);
            }
            return Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The read-only mobile layout shows the grid and the
                  // sheet tabs only (suite 02 §6.1).
                  if (!WonkyLayout.isMobile(context)) ...[
                    FormulaBar(controller: editor),
                    FilterViewBar(editor: editor),
                  ] else
                    // A 1 px `border` line between the title row and the
                    // grid, which otherwise blend (T-12).
                    SizedBox(
                      key: const ValueKey<String>('sheets.mobile.separator'),
                      height: 1,
                      child: ColoredBox(
                        color: ShadTheme.of(context).colorScheme.border,
                      ),
                    ),
                  Expanded(
                    child: WonkyPopupMenuHost(
                      child: Builder(
                        builder: (context) => Stack(
                          children: [
                            Positioned.fill(
                              child: GridFileDropTarget(
                                controller: editor,
                                child: KeyedSubtree(
                                  key: _gridKey,
                                  child: CollabGridOverlay(
                                    controller: editor,
                                    child: SheetObjectsHost(
                                      editor: editor,
                                      services: s,
                                      child: GridArea(
                                        key: const ValueKey<String>(
                                          'sheets.grid',
                                        ),
                                        controller: editor,
                                        services: s,
                                        onContextMenu: _openMenu,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: DataToolsGridOverlay(editor: editor),
                            ),
                            Positioned.fill(
                              child: MacroRecordingOverlay(editor: editor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SheetTabBar(controller: editor),
                ],
              ),
            );
        }
      },
    );
  }
}

/// "Downloading spreadsheet… 42%" with a skeleton grid (04 §1).
class SpreadsheetLoadingView extends StatelessWidget {
  const SpreadsheetLoadingView({super.key, required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final p = progress;
    return Stack(
      key: const ValueKey<String>('sheets.loading'),
      children: [
        Positioned.fill(child: LoadingShimmer.documentPage()),
        Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.popover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p == null
                      ? l.loadingSpreadsheet
                      : l.downloadingSpreadsheet((p * 100).round()),
                  style: theme.textTheme.small,
                ),
                const SizedBox(height: 12),
                ShadProgress(value: p),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
