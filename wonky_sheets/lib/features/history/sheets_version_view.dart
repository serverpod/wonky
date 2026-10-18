import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show ItemVersionView, UuidValue, VersionRestoreResult;
import 'package:wonky_core/wonky_core.dart'
    show InvocationSource, Role, UndoEntry;
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import 'change_labels.dart';
import '../../l10n/sheets_l10n.dart';
import '../export/sheets_downloads.dart';
import '../grid/grid_area.dart';
import '../grid/paint/grid_layer.dart';
import '../grid/paint/layers/overlay_layers.dart' show drawDashedRect;
import '../import_export/sheets_io.dart' show saveBytes;
import '../model/memory_workbook_session.dart';
import '../objects/objects_layer.dart' show SheetObjectsHost;
import '../sheet_editor/sheet_editor_controller.dart';
import 'server_change_undo.dart';
import 'version_copy.dart';
import 'version_snapshots.dart';

/// Sheets' [VersionRenderer] (Sheets 10 §5.2): the version's snapshot as a
/// read-only grid with changed cells outlined; restores undo through the
/// `sheets.serverChange` domain (§5.3).
class SheetsVersionRenderer extends VersionRenderer {
  SheetsVersionRenderer();

  @override
  Widget build(
    BuildContext context, {
    required UuidValue itemUuid,
    required ItemVersionView version,
    ItemVersionView? previous,
    required bool showChanges,
  }) => SheetsVersionView(
    key: ValueKey<String>('sheets.version.${version.id}'),
    services: ShellScope.of(context),
    itemUuid: itemUuid,
    version: version,
    previous: previous,
    showChanges: showChanges,
  );

  @override
  UndoEntry? restoreUndoEntry(
    UuidValue itemUuid,
    int versionId,
    VersionRestoreResult result,
  ) => result.changeId == null
      ? null
      : SheetsServerChangeEntry(
          changeId: result.changeId!.uuid,
          label: SheetsChangeLabels.restoreVersion,
        );
}

/// One changed cell of a version, resolved for navigation.
@immutable
class VersionCellChange {
  const VersionCellChange(
    this.sheetId,
    this.rowId,
    this.colId,
    this.kind, {
    this.authorId,
  });

  final String sheetId;
  final String rowId;
  final String colId;
  final CellChangeKind kind;

  /// User id of the author (from the change log, Sheets 10 §5.2 step 5);
  /// null when unknown.
  final int? authorId;
}

/// The changed ranges of a version with their authors
/// (`SheetsVersionEndpoint.changes`, oldest first): the author of a cell is
/// the latest range containing it.
class VersionAttribution {
  const VersionAttribution(this.ranges, {this.approx = false});

  final List<({Map<String, Object?> range, int userId})> ranges;
  final bool approx;

  static VersionAttribution parse(String json) {
    try {
      final m = jsonDecode(json);
      if (m is! Map) return const VersionAttribution([]);
      return VersionAttribution([
        for (final r in (m['ranges'] as List? ?? const []))
          if (r is Map && r['u'] is num)
            (range: r.cast<String, Object?>(), userId: (r['u'] as num).toInt()),
      ], approx: m['approx'] == true);
    } on FormatException {
      return const VersionAttribution([]);
    }
  }

  /// The author of the cell (row, col) of [sheet] (null when no range
  /// covers it).
  int? authorAt(SheetModel sheet, int row, int col) {
    bool within(AxisIndex axis, Object? a, Object? b, int i) {
      final x = a == null ? 0 : axis.indexOf('$a');
      final y = b == null ? axis.length - 1 : axis.indexOf('$b');
      if (x < 0 || y < 0) return false;
      return i >= math.min(x, y) && i <= math.max(x, y);
    }

    for (final r in ranges.reversed) {
      final m = r.range;
      if (m['s'] != sheet.id) continue;
      if (within(sheet.rows, m['r1'], m['r2'], row) &&
          within(sheet.columns, m['c1'], m['c2'], col)) {
        return r.userId;
      }
    }
    return null;
  }
}

/// The read-only grid of a version (Sheets 10 §5.2).
class SheetsVersionView extends StatefulWidget {
  const SheetsVersionView({
    super.key,
    required this.services,
    required this.itemUuid,
    required this.version,
    required this.previous,
    required this.showChanges,
  });

  final ShellServices services;
  final UuidValue itemUuid;
  final ItemVersionView version;
  final ItemVersionView? previous;
  final bool showChanges;

  /// The version shown in the history route (commands
  /// `sheets.history.nextChange` / `previousChange` / `makeCopy`).
  static final ValueNotifier<SheetsVersionViewState?> current = ValueNotifier(
    null,
  );

  @override
  State<SheetsVersionView> createState() => SheetsVersionViewState();
}

bool get _apple => const {
  TargetPlatform.macOS,
  TargetPlatform.iOS,
}.contains(defaultTargetPlatform);

class SheetsVersionViewState extends State<SheetsVersionView> {
  SheetEditorController? editor;
  MemoryWorkbookSession? _session;
  SnapshotRows? rows;
  SnapshotRows? previousRows;
  SnapshotDiff? diff;
  List<VersionCellChange> changes = const [];
  int changeIndex = -1;
  Object? _error;
  bool _copying = false;
  final _changesSignal = GridSignal();
  late _VersionChangesLayer _layer;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    _layer = _VersionChangesLayer(this);
    unawaited(_load());
    SheetsVersionView.current.value = this;
  }

  @override
  void didUpdateWidget(SheetsVersionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showChanges != widget.showChanges) {
      _changesSignal.fire();
      editor?.contentSignal.fire();
      if (widget.showChanges && diff == null) unawaited(_loadDiff());
    }
  }

  Future<void> _load() async {
    try {
      final r = await VersionSnapshots.load(
        s,
        widget.itemUuid,
        widget.version.id,
      );
      if (!mounted) return;
      final model = WorkbookModel.fromRows(_spreadsheetIdOf(r), r);
      final session = MemoryWorkbookSession(
        itemUuid: widget.itemUuid,
        userId: s.me?.uuid.uuid ?? '00000000-0000-7000-8000-000000000000',
        model: model,
        role: Role.viewer,
      );
      final ed = SheetEditorController(services: s, session: session);
      ed.itemRole = Role.viewer;
      ed.layers.add(_layer);
      setState(() {
        rows = r;
        _session = session;
        editor = ed;
      });
      if (widget.showChanges) await _loadDiff();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  static String _spreadsheetIdOf(SnapshotRows rows) {
    for (final (t, c) in rows) {
      if (t == SheetsTables.spreadsheet) return '${c[Cols.id]}';
    }
    return rows.isEmpty ? '' : '${rows.first.$2[Cols.spreadsheetId] ?? ''}';
  }

  /// Versions with more cells than this get their diff from the server
  /// (Sheets 10 §5.2 step 4). Variable for tests.
  static int serverDiffCells = 500000;

  /// Overrides `SheetsVersionEndpoint.changes` (tests).
  @visibleForTesting
  static Future<String> Function(UuidValue item, int versionId)? fetchChanges;

  /// Overrides the server diff download (tests): the gzip JSON bytes.
  @visibleForTesting
  static Future<List<int>> Function(UuidValue item, int versionId, int? prev)?
  fetchServerDiff;

  Future<VersionAttribution> _attribution() async {
    try {
      final override = fetchChanges;
      final client = s.client;
      if (override == null && (client == null || Api.simulatedOffline)) {
        return const VersionAttribution([]);
      }
      final json = override != null
          ? await override(widget.itemUuid, widget.version.id)
          : await client!.sheetsVersion.changes(
              widget.itemUuid,
              widget.version.id,
            );
      return VersionAttribution.parse(json);
    } catch (e) {
      debugPrint('Version authors unavailable: $e');
      return const VersionAttribution([]);
    }
  }

  Future<(SnapshotDiff, List<int>)> _serverDiff() async {
    final prev = widget.previous?.id;
    final override = fetchServerDiff;
    List<int> bytes;
    if (override != null) {
      bytes = await override(widget.itemUuid, widget.version.id, prev);
    } else {
      final client = s.client;
      if (client == null || Api.simulatedOffline) {
        throw const OfflineException('offline');
      }
      final url = await client.sheetsVersion.diff(
        widget.itemUuid,
        widget.version.id,
        prev,
      );
      final r = await http.get(Uri.parse(url.url!));
      if (r.statusCode != 200) {
        throw StateError('Diff download failed (${r.statusCode}).');
      }
      bytes = r.bodyBytes;
    }
    final m = jsonDecode(utf8.decode(const GZipDecoder().decodeBytes(bytes)));
    return (
      SnapshotDiff.fromJson(
        ((m as Map)['diff'] as Map).cast<String, Object?>(),
      ),
      [for (final a in (m['a'] as List? ?? const [])) (a as num).toInt()],
    );
  }

  int get _cellCount {
    var n = 0;
    for (final (t, _) in rows ?? const <(String, Map<String, Object?>)>[]) {
      if (t == SheetsTables.cell) n++;
    }
    return n;
  }

  /// Whether the diff was computed on the server.
  bool serverDiff = false;

  Future<void> _loadDiff() async {
    final prev = widget.previous;
    final cur = rows;
    if (cur == null) return;
    SnapshotRows before = const [];
    SnapshotDiff d;
    List<int>? authors;
    final big = _cellCount > serverDiffCells;
    if (big) {
      try {
        (d, authors) = await _serverDiff();
      } catch (e) {
        debugPrint('Server diff unavailable: $e');
        return;
      }
    } else {
      if (prev != null) {
        try {
          before = await VersionSnapshots.load(s, widget.itemUuid, prev.id);
        } catch (e) {
          debugPrint('Previous version unavailable: $e');
          return;
        }
      }
      d = SnapshotDiffer.diffRows(before, cur);
    }
    final attribution = big
        ? const VersionAttribution([])
        : await _attribution();
    if (!mounted) return;
    final model = editor?.model;
    final order = [
      for (final sh in model?.sheets ?? const <SheetModel>[]) sh.id,
    ];
    int rowOf(VersionCellChange c) =>
        model?.sheet(c.sheetId)?.rows.indexOf(c.rowId) ?? -1;
    int colOf(VersionCellChange c) =>
        model?.sheet(c.sheetId)?.columns.indexOf(c.colId) ?? -1;
    final list = <VersionCellChange>[];
    for (final (i, c) in d.cells.indexed) {
      int? author = authors != null && i < authors.length && authors[i] != 0
          ? authors[i]
          : null;
      final sheet = model?.sheet(c.sheetId);
      if (author == null && sheet != null) {
        final r = sheet.rows.indexOf(c.rowId);
        final col = sheet.columns.indexOf(c.colId);
        if (r >= 0 && col >= 0) author = attribution.authorAt(sheet, r, col);
      }
      list.add(
        VersionCellChange(
          c.sheetId,
          c.rowId,
          c.colId,
          c.kind,
          authorId: author,
        ),
      );
    }
    list.removeWhere((c) => rowOf(c) < 0 || colOf(c) < 0);
    list.sort((a, b) {
      final sa = order.indexOf(a.sheetId).compareTo(order.indexOf(b.sheetId));
      if (sa != 0) return sa;
      final r = rowOf(a).compareTo(rowOf(b));
      return r != 0 ? r : colOf(a).compareTo(colOf(b));
    });
    setState(() {
      previousRows = before;
      diff = d;
      changes = list;
      changeIndex = -1;
      serverDiff = big;
    });
    _layer.rebuild();
    editor?.contentSignal.fire();
  }

  @override
  void dispose() {
    if (SheetsVersionView.current.value == this) {
      SheetsVersionView.current.value = null;
    }
    final ed = editor;
    final session = _session;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ed?.dispose();
      if (session != null) unawaited(session.dispose());
    });
    _changesSignal.dispose();
    super.dispose();
  }

  /// The color of a change: its author's presence color; for unknown
  /// authors the single author's color, else a neutral color for several
  /// authors (Sheets 10 §5.2 step 3).
  Color colorOf(ShadColorScheme cs, VersionCellChange? c) {
    final authors = widget.version.authors;
    final id = c?.authorId;
    if (id != null) {
      for (final a in authors) {
        if (a.id == id) return cs.presence(a.colorIndex);
      }
    }
    return authors.length == 1
        ? cs.presence(authors.single.colorIndex)
        : cs.mutedForeground;
  }

  /// The color of the version's changes as a whole (tab dots, legend).
  Color changeColor(ShadColorScheme cs) => colorOf(cs, null);

  /// Moves to the next/previous changed cell in reading order.
  void step({required bool forward}) {
    final ed = editor;
    if (ed == null || changes.isEmpty) return;
    setState(() {
      changeIndex = forward
          ? (changeIndex + 1) % changes.length
          : (changeIndex <= 0 ? changes.length - 1 : changeIndex - 1);
    });
    final c = changes[changeIndex];
    if (c.sheetId != ed.activeSheetId) ed.activateSheet(c.sheetId);
    final sheet = ed.activeSheet!;
    final row = sheet.rows.indexOf(c.rowId);
    final col = sheet.columns.indexOf(c.colId);
    if (row < 0 || col < 0) return;
    ed.selection.selectCell(row, col);
    ed.revealCell(row, col);
  }

  /// The default name of a copy ("Copy of Budget").
  String get copyName {
    final l = sheetsL10nOf(s);
    return l.versionCopyName(
      editor?.model.spreadsheet.title.isNotEmpty ?? false
          ? editor!.model.spreadsheet.title
          : s.currentItem.value?.name ?? '',
    );
  }

  /// *Make a copy* of this version (Sheets 10 §5.4), optionally with the
  /// spreadsheet's comments and sharing (copied by the server once the copy
  /// is registered).
  Future<UuidValue?> makeCopy({
    String? name,
    bool copyComments = false,
    bool copySharing = false,
  }) async {
    final r = rows;
    if (r == null || _copying) return null;
    final l = sheetsL10nOf(s);
    final title = name ?? copyName;
    setState(() => _copying = true);
    try {
      final result = await copyVersionToNewSpreadsheet(
        s,
        rows: r,
        sourceSpaceId: _spreadsheetIdOf(r),
        name: title,
      );
      if (result == null) return null;
      final (id, idMap) = result;
      if (copyComments || copySharing) {
        try {
          await copyVersionExtras(
            s,
            source: widget.itemUuid,
            target: id,
            idMap: idMap,
            comments: copyComments,
            sharing: copySharing,
          );
        } catch (e) {
          s.toasts.error(
            l.toastVersionCopyExtrasFailed,
            description: errorMessage(e),
          );
        }
      }
      s.toasts.show(
        l.toastVersionCopied(title),
        actionLabel: l.versionOpenCopy,
        onAction: () => s.router.go('/s/${id.uuid}'),
      );
      return id;
    } catch (e) {
      s.toasts.error(l.toastVersionCopyFailed, description: errorMessage(e));
      return null;
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  /// *Make a copy* dialog: name, *Copy comments*, *Share with the same
  /// people* (MCP-operable).
  Future<UuidValue?> makeCopyWithDialog(BuildContext context) async {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final r = await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: l.versionCopyTitle,
        dialogKey: 'dialog.versionCopy',
        fields: [
          TextFieldSpec(
            id: 'name',
            label: l.versionCopyNameLabel,
            initial: copyName,
            selectAll: true,
            maxLength: 255,
            validator: (v) =>
                v.trim().isEmpty ? l.versionCopyNameRequired : null,
          ),
          CheckboxFieldSpec(id: 'comments', label: l.versionCopyComments),
          CheckboxFieldSpec(id: 'sharing', label: l.versionCopySharing),
        ],
        buttons: [
          DialogButtonSpec(id: 'cancel', label: la.actionCancel),
          DialogButtonSpec(
            id: 'ok',
            label: l.cmdHistoryMakeCopy,
            primary: true,
            validates: true,
          ),
        ],
      ),
    );
    if (r?.buttonId != 'ok') return null;
    return makeCopy(
      name: r!.text('name').trim(),
      copyComments: r.values['comments'] == true,
      copySharing: r.values['sharing'] == true,
    );
  }

  /// *Download as…* from this version (Sheets 10 §5.4): the exporters run
  /// on the version's in-memory model. Returns the file name (null when
  /// cancelled).
  Future<String?> download(SheetsExportFormat format) async {
    final ed = editor;
    if (ed == null) return null;
    final l = sheetsL10nOf(s);
    try {
      final artifact = await buildDownload(ed, format);
      final saved = await saveBytes(
        artifact.bytes,
        fileName: artifact.fileName,
        mimeType: artifact.mimeType,
        dialogTitle: l.exportSaveDialogTitle(artifact.fileName),
      );
      return saved ? artifact.fileName : null;
    } catch (e) {
      s.toasts.error(l.exportFailed, description: errorMessage(e));
      rethrow;
    }
  }

  /// Formats offered by *Download* in the history route (PDF goes through
  /// the print route of the live spreadsheet and is not offered).
  static const downloadFormats = [
    SheetsExportFormat.xlsx,
    SheetsExportFormat.ods,
    SheetsExportFormat.csv,
    SheetsExportFormat.tsv,
    SheetsExportFormat.html,
  ];

  String _summary(SheetsLocalizations l) {
    final d = diff;
    if (d == null) return '';
    final parts = <String>[];
    if (changes.isNotEmpty) parts.add(l.versionChangedCells(changes.length));
    var rowsAdded = 0;
    var rowsRemoved = 0;
    var colsAdded = 0;
    var colsRemoved = 0;
    for (final st in d.structure.values) {
      rowsAdded += st.rowsAdded.length;
      rowsRemoved += st.rowsRemoved.length;
      colsAdded += st.columnsAdded.length;
      colsRemoved += st.columnsRemoved.length;
    }
    if (rowsAdded > 0) parts.add(l.versionRowsInserted(rowsAdded));
    if (rowsRemoved > 0) parts.add(l.versionRowsDeleted(rowsRemoved));
    if (colsAdded > 0) parts.add(l.versionColumnsInserted(colsAdded));
    if (colsRemoved > 0) parts.add(l.versionColumnsDeleted(colsRemoved));
    for (final e in d.sheetsRenamed.values) {
      parts.add(l.versionSheetRenamed(e.$1, e.$2));
    }
    if (d.sheetsAdded.isNotEmpty) {
      parts.add(l.versionSheetsAdded(d.sheetsAdded.length));
    }
    if (d.sheetsRemoved.isNotEmpty) {
      parts.add(l.versionSheetsDeleted(d.sheetsRemoved.length));
    }
    return parts.isEmpty ? l.versionNoChanges : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final err = _error;
    if (err != null) {
      return WonkyEmptyState(
        illustration: isOfflineError(err)
            ? EmptyIllustration.offline
            : EmptyIllustration.error,
        title: l.versionLoadFailed,
        description: errorMessage(err),
        actions: [
          ShadButton.outline(
            onPressed: () {
              setState(() => _error = null);
              unawaited(_load());
            },
            child: Text(l.screenTryAgain),
          ),
        ],
      );
    }
    final ed = editor;
    if (ed == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ShadSpinner(),
            const SizedBox(height: 12),
            Text(l.versionLoading, style: theme.textTheme.muted),
          ],
        ),
      );
    }
    _layer.colorOf = (c) => colorOf(theme.colorScheme, c);
    _layer.enabled = widget.showChanges;
    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          LogicalKeyboardKey.arrowDown,
          alt: true,
          control: !_apple,
          meta: _apple,
        ): () =>
            step(forward: true),
        SingleActivator(
          LogicalKeyboardKey.arrowUp,
          alt: true,
          control: !_apple,
          meta: _apple,
        ): () =>
            step(forward: false),
      },
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bar(context, l, theme),
            Expanded(
              // Charts and images render as in the version (read-only).
              child: SheetObjectsHost(
                editor: ed,
                services: s,
                child: GridArea(
                  key: const ValueKey<String>('sheets.version.grid'),
                  controller: ed,
                  services: s,
                ),
              ),
            ),
            _VersionTabs(state: this, controller: ed),
          ],
        ),
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    SheetsLocalizations l,
    ShadThemeData theme,
  ) {
    final showNav = widget.showChanges && changes.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          if (widget.showChanges) ...[
            _AuthorLegend(state: this),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              widget.showChanges
                  ? (diff == null ? l.versionComputingChanges : _summary(l))
                  : l.versionChangesHidden,
              key: const ValueKey<String>('sheets.version.summary'),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.small,
            ),
          ),
          if (showNav) ...[
            Text(
              changeIndex < 0
                  ? '${changes.length}'
                  : '${changeIndex + 1} / ${changes.length}',
              style: theme.textTheme.muted,
            ),
            ShadTooltip(
              builder: (_) => Text(l.cmdHistoryPreviousChange),
              child: ShadIconButton.ghost(
                key: const ValueKey<String>('sheets.version.prev'),
                width: 28,
                height: 28,
                iconSize: 16,
                semanticLabel: l.cmdHistoryPreviousChange,
                icon: const Icon(LucideIcons.chevronUp),
                onPressed: () => step(forward: false),
              ),
            ),
            ShadTooltip(
              builder: (_) => Text(l.cmdHistoryNextChange),
              child: ShadIconButton.ghost(
                key: const ValueKey<String>('sheets.version.next'),
                width: 28,
                height: 28,
                iconSize: 16,
                semanticLabel: l.cmdHistoryNextChange,
                icon: const Icon(LucideIcons.chevronDown),
                onPressed: () => step(forward: true),
              ),
            ),
          ],
          const SizedBox(width: 4),
          WonkyDropdownMenu(
            entries: () => [
              for (final f in downloadFormats)
                WonkyMenuItem(
                  label: downloadFormatLabel(l, f),
                  onSelected: () => unawaited(
                    s.dispatcher.invoke(
                      'sheets.history.download',
                      args: {'format': f.name},
                      source: InvocationSource.ui,
                      context: context,
                    ),
                  ),
                ),
            ],
            builder: (context, ctl) => ShadTooltip(
              builder: (_) => Text(l.cmdHistoryDownload),
              child: ShadIconButton.ghost(
                key: const ValueKey<String>('sheets.version.download'),
                width: 28,
                height: 28,
                iconSize: 16,
                semanticLabel: l.cmdHistoryDownload,
                icon: const Icon(LucideIcons.download),
                onPressed: ctl.toggle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          ShadButton.outline(
            key: const ValueKey<String>('sheets.version.copy'),
            size: ShadButtonSize.sm,
            enabled: !_copying,
            leading: _copying
                ? const SizedBox.square(dimension: 14, child: ShadSpinner())
                : const Icon(LucideIcons.copy, size: 14),
            onPressed: () => unawaited(
              s.dispatcher.invoke(
                'sheets.history.makeCopy',
                source: InvocationSource.ui,
                context: context,
              ),
            ),
            child: Text(l.cmdHistoryMakeCopy),
          ),
        ],
      ),
    );
  }
}

/// The authors of the shown version with their change colors (Sheets 10
/// §5.2: cells are outlined in their author's presence color).
class _AuthorLegend extends StatelessWidget {
  const _AuthorLegend({required this.state});

  final SheetsVersionViewState state;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final authors = state.widget.version.authors;
    final shown = authors.take(3).toList();
    final names = [for (final a in authors) a.displayName].join(', ');
    Widget dot(Color c) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    if (shown.isEmpty) return dot(state.changeColor(cs));
    return ShadTooltip(
      builder: (_) => Text(names),
      child: Row(
        key: const ValueKey<String>('sheets.version.authors'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in shown) ...[
            dot(cs.presence(a.colorIndex)),
            const SizedBox(width: 3),
          ],
          if (authors.length > 3)
            Text('+${authors.length - 3}', style: theme.textTheme.muted),
        ],
      ),
    );
  }
}

/// Sheet tabs of a version: switching sheets, a dot on changed sheets, and
/// struck-through names of sheets deleted since the previous version.
class _VersionTabs extends StatelessWidget {
  const _VersionTabs({required this.state, required this.controller});

  final SheetsVersionViewState state;
  final SheetEditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = sheetsL10n(context);
    final diff = state.widget.showChanges ? state.diff : null;
    final changed = diff?.changedSheets ?? const <String>{};
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Container(
        height: 36,
        decoration: BoxDecoration(
          color: cs.muted,
          border: Border(top: BorderSide(color: cs.border)),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final sh in controller.model.visibleSheets)
              Padding(
                padding: const EdgeInsets.only(right: 2, top: 3),
                child: ShadButton.ghost(
                  key: ValueKey<String>('sheets.version.tab.${sh.id}'),
                  height: 30,
                  backgroundColor: sh.id == controller.activeSheetId
                      ? cs.background
                      : null,
                  onPressed: () => controller.activateSheet(sh.id),
                  trailing: changed.contains(sh.id)
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: state.changeColor(cs),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  child: Text(
                    sh.name,
                    style: theme.textTheme.small.copyWith(
                      fontWeight: sh.id == controller.activeSheetId
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            for (final id in diff?.sheetsRemoved ?? const <String>[])
              Padding(
                padding: const EdgeInsets.only(right: 2, top: 3),
                child: ShadTooltip(
                  builder: (_) => Text(l.versionSheetDeletedTooltip),
                  child: ShadButton.ghost(
                    height: 30,
                    enabled: false,
                    child: Text(
                      _removedName(id),
                      style: theme.textTheme.small.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: cs.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _removedName(String id) {
    for (final (t, c)
        in state.previousRows ?? const <(String, Map<String, Object?>)>[]) {
      if (t == SheetsTables.sheet && c[Cols.id] == id) {
        return '${c[Cols.name] ?? id}';
      }
    }
    return id;
  }
}

/// Changed cells of the shown version (Sheets 10 §5.2): 2 px outline + 15 %
/// fill in the author color; format-only changes dashed.
class _VersionChangesLayer extends GridLayer {
  _VersionChangesLayer(this.state);

  final SheetsVersionViewState state;
  Color Function(VersionCellChange c) colorOf = (_) => const Color(0xFF1A73E8);
  bool enabled = true;
  Map<String, List<VersionCellChange>> _bySheet = const {};

  void rebuild() {
    final m = <String, List<VersionCellChange>>{};
    for (final c in state.changes) {
      m.putIfAbsent(c.sheetId, () => []).add(c);
    }
    _bySheet = m;
  }

  @override
  int get zOrder => GridZ.decorations + 5;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    if (!enabled) return;
    final list = _bySheet[ctx.sheetId];
    if (list == null || list.isEmpty) return;
    final active =
        state.changeIndex >= 0 && state.changeIndex < state.changes.length
        ? state.changes[state.changeIndex]
        : null;
    ctx.forEachPane(canvas, (pane) {
      if (pane.isEmpty) return;
      for (final c in list) {
        final row = ctx.sheet.rows.indexOf(c.rowId);
        final col = ctx.sheet.columns.indexOf(c.colId);
        if (row < pane.rowStart || row > pane.rowEnd) continue;
        if (col < pane.colStart || col > pane.colEnd) continue;
        final rect = pane.rangeRect(GridRect.cell(row, col)).deflate(1);
        final color = colorOf(c);
        final solid = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.15));
        if (c.kind == CellChangeKind.format) {
          drawDashedRect(canvas, rect, solid, dash: 4, gap: 3);
        } else {
          canvas.drawRect(rect, solid);
        }
        if (identical(c, active)) {
          canvas.drawRect(
            rect.inflate(2),
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }
    });
  }
}
