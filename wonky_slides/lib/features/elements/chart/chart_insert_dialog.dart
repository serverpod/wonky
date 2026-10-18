import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_charts/wonky_charts.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides_core/charts.dart';
import 'package:wonky_slides_core/themes.dart' show ResolvedTheme;
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../../l10n/slides_l10n.dart';
import '../../editor_screen/deck_editor_controller.dart';
import 'chart_api.dart';
import 'chart_text.dart';

/// What the insert dialog returns (08 §4.2).
@immutable
class ChartInsertChoice {
  const ChartInsertChoice({
    required this.spreadsheetUuid,
    required this.chartObjectIds,
    this.link = true,
    this.useDeckTheme = true,
  });

  final String spreadsheetUuid;
  final List<String> chartObjectIds;
  final bool link;
  final bool useDeckTheme;
}

/// Stable widget keys of the insert dialog.
abstract final class ChartInsertKeys {
  static const dialog = ValueKey<String>('dialog.slides.chartInsert');
  static const search = ValueKey<String>('slides.chartInsert.search');
  static const back = ValueKey<String>('slides.chartInsert.back');
  static const link = ValueKey<String>('slides.chartInsert.link');
  static const matchTheme = ValueKey<String>('slides.chartInsert.matchTheme');
  static const insert = ValueKey<String>('slides.chartInsert.insert');
  static const openInSheets = ValueKey<String>('slides.chartInsert.open');

  static ValueKey<String> tab(String id) =>
      ValueKey<String>('slides.chartInsert.tab.$id');

  static ValueKey<String> spreadsheet(String uuid) =>
      ValueKey<String>('slides.chartInsert.sheet.$uuid');

  static ValueKey<String> tile(String chartObjectId) =>
      ValueKey<String>('slides.chartInsert.chart.$chartObjectId');
}

/// The message of a chart call that failed (08 §4.3).
String chartErrorMessage(SlidesLocalizations l, ChartApiError e) => switch (e) {
  ChartApiError.offline => l.chartErrOffline,
  ChartApiError.noAccess => l.chartErrNoAccess,
  ChartApiError.spreadsheetTrashed => l.chartErrTrashed,
  ChartApiError.exportDisabled => l.chartErrExportDisabled,
  ChartApiError.chartNotFound => l.chartErrNotFound,
  ChartApiError.chartTooLarge => l.chartErrTooLarge,
  ChartApiError.unsupportedSpec => l.chartErrUnsupported,
  ChartApiError.quotaExceeded => l.chartErrQuota,
  ChartApiError.rateLimited => l.chartErrRateLimited,
  ChartApiError.failed => l.chartErrFailed,
};

/// *Insert › Chart › From Wonky Sheets…* (08 §4.1–§4.2): pick a
/// spreadsheet (Recent, My files, Shared with me, Starred, search; only
/// spreadsheets whose charts the user may copy are selectable), then one
/// or more charts (previews in the deck theme when *Match presentation
/// theme* is on; Mod-click selects several). [spreadsheetUuid] opens at
/// step 2; [single] allows one chart (*Change linked chart…*).
/// MCP-operable. Returns null when cancelled.
Future<ChartInsertChoice?> showChartInsertDialog(
  BuildContext context, {
  required ShellServices services,
  required DeckEditorController editor,
  String? spreadsheetUuid,
  bool single = false,
  bool useDeckTheme = true,
}) => showShadDialog<ChartInsertChoice>(
  context: context,
  builder: (_) => ChartInsertDialog(
    services: services,
    editor: editor,
    spreadsheetUuid: spreadsheetUuid,
    single: single,
    useDeckTheme: useDeckTheme,
  ),
);

class ChartInsertDialog extends StatefulWidget {
  const ChartInsertDialog({
    super.key,
    required this.services,
    required this.editor,
    this.spreadsheetUuid,
    this.single = false,
    this.useDeckTheme = true,
  });

  final ShellServices services;
  final DeckEditorController editor;
  final String? spreadsheetUuid;
  final bool single;
  final bool useDeckTheme;

  @override
  State<ChartInsertDialog> createState() => _ChartInsertDialogState();
}

class _ChartInsertDialogState extends State<ChartInsertDialog>
    implements McpDescribableDialog {
  static const _tabs = ['recent', 'mine', 'shared', 'starred'];

  final _search = TextEditingController();
  final _chartSearch = TextEditingController();
  Timer? _debounce;
  ShellServices? _registeredIn;

  // Step 1.
  String _tab = 'recent';
  List<DriveItemView> _sheets = const [];
  bool _loadingSheets = true;
  bool _sheetsFailed = false;

  // Step 2.
  String? _sheetUuid;
  String _sheetTitle = '';
  ChartSourceListing? _listing;
  ChartApiError? _error;
  bool _loadingCharts = false;
  final List<String> _selected = [];

  /// Preview looks per chart, with the inputs they were made from.
  final Map<String, (Object, SlideChartLook)> _looks = {};
  late bool _link = true;
  late bool _match = widget.useDeckTheme;

  SlidesChartApi get _api => SlidesChartApi.of(widget.services);

  @override
  void initState() {
    super.initState();
    final start = widget.spreadsheetUuid;
    if (start != null) {
      unawaited(_open(start, ''));
    } else {
      unawaited(_findSheets());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    _debounce?.cancel();
    _search.dispose();
    _chartSearch.dispose();
    super.dispose();
  }

  static bool canCopy(DriveItemView i) =>
      i.role == AccessRole.editor ||
      i.role == AccessRole.owner ||
      i.nonEditorsCanExport;

  Future<void> _findSheets() async {
    final q = _search.text.trim();
    setState(() {
      _loadingSheets = true;
      _sheetsFailed = false;
    });
    try {
      final drive = widget.services.drive;
      final page = q.isEmpty
          ? await drive.list(
              filter: DriveListFilter(
                view: switch (_tab) {
                  'shared' => DriveView.sharedWithMe,
                  'starred' => DriveView.starred,
                  'mine' => DriveView.folder,
                  _ => DriveView.recent,
                },
                owner: _tab == 'mine' ? DriveOwnerFilter.me : null,
                kinds: [DriveItemKind.spreadsheet],
              ),
              sort: DriveSort(
                field: _tab == 'recent'
                    ? DriveSortField.lastOpenedByMe
                    : DriveSortField.modifiedAt,
                descending: true,
              ),
              limit: 50,
            )
          : await drive.search(
              q,
              filters: DriveSearchFilters(kinds: [DriveItemKind.spreadsheet]),
              limit: 50,
            );
      if (!mounted) return;
      setState(() {
        _sheets = [
          for (final i in page.items)
            if (i.kind == DriveItemKind.spreadsheet && i.trashedAt == null) i,
        ];
        _loadingSheets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSheets = false;
        _sheetsFailed = true;
      });
    }
  }

  Future<void> _open(String uuid, String title) async {
    setState(() {
      _sheetUuid = uuid;
      _sheetTitle = title;
      _listing = null;
      _error = null;
      _loadingCharts = true;
      _selected.clear();
    });
    try {
      final r = await _api.listCharts(uuid);
      if (!mounted || _sheetUuid != uuid) return;
      setState(() {
        _listing = r;
        _sheetTitle = r.spreadsheetTitle;
        _loadingCharts = false;
        if (!r.exportAllowed) _error = ChartApiError.exportDisabled;
      });
    } on ChartApiException catch (e) {
      if (!mounted || _sheetUuid != uuid) return;
      setState(() {
        _error = e.error;
        _loadingCharts = false;
      });
    }
  }

  void _back() {
    setState(() {
      _sheetUuid = null;
      _listing = null;
      _error = null;
      _selected.clear();
    });
    if (_sheets.isEmpty) unawaited(_findSheets());
  }

  bool _selectable(ChartSourceTile t) =>
      !t.unsupported && (_listing?.exportAllowed ?? false);

  void _toggle(ChartSourceTile t, {bool multi = false}) {
    if (!_selectable(t)) return;
    setState(() {
      if (multi && !widget.single) {
        if (!_selected.remove(t.chartObjectId)) _selected.add(t.chartObjectId);
      } else if (_selected.length == 1 && _selected.single == t.chartObjectId) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..add(t.chartObjectId);
      }
    });
  }

  void _insert() {
    final uuid = _sheetUuid;
    if (uuid == null || _selected.isEmpty) return;
    Navigator.of(context).pop(
      ChartInsertChoice(
        spreadsheetUuid: uuid,
        chartObjectIds: List.of(_selected),
        link: _link,
        useDeckTheme: _match,
      ),
    );
  }

  void _close() => Navigator.of(context).pop();

  List<ChartSourceTile> get _visibleCharts {
    final q = _chartSearch.text.trim().toLowerCase();
    return [
      for (final c in _listing?.charts ?? const <ChartSourceTile>[])
        if (q.isEmpty ||
            c.title.toLowerCase().contains(q) ||
            c.sheetName.toLowerCase().contains(q))
          c,
    ];
  }

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final l = slidesL10n(context);
    final step2 = _sheetUuid != null;
    return {
      'title': step2
          ? l.chartInsertFromTitle(_sheetTitle)
          : l.chartInsertDialogTitle,
      'fields': step2
          ? [
              {
                'id': 'search',
                'label': l.chartSearchCharts,
                'type': 'text',
                'value': _chartSearch.text,
              },
              {
                'id': 'chart',
                'label': l.chartPickChart,
                'type': 'select',
                'options': [
                  for (final c in _visibleCharts)
                    if (_selectable(c)) c.chartObjectId,
                ],
                'optionLabels': {
                  for (final c in _visibleCharts)
                    if (_selectable(c))
                      c.chartObjectId: '${c.sheetName} › ${c.title}',
                },
                'value': _selected,
              },
              {
                'id': 'link',
                'label': l.chartLinkToSpreadsheet,
                'type': 'checkbox',
                'value': _link,
              },
              {
                'id': 'matchTheme',
                'label': l.chartMatchTheme,
                'type': 'checkbox',
                'value': _match,
              },
            ]
          : [
              {
                'id': 'search',
                'label': l.chartSearchSpreadsheets,
                'type': 'text',
                'value': _search.text,
              },
              {
                'id': 'tab',
                'label': l.chartSpreadsheetsLabel,
                'type': 'select',
                'options': _tabs,
                'value': _tab,
              },
              {
                'id': 'spreadsheet',
                'label': l.chartSpreadsheetsLabel,
                'type': 'select',
                'options': [
                  for (final s in _sheets)
                    if (canCopy(s)) s.uuid.uuid,
                ],
                'optionLabels': {
                  for (final s in _sheets)
                    if (canCopy(s)) s.uuid.uuid: s.name,
                },
              },
            ],
      if (_error != null) 'error': chartErrorMessage(l, _error!),
      'buttons': [
        {
          'id': 'cancel',
          'label': WonkyAppLocalizations.of(context).actionCancel,
        },
        if (step2 && widget.spreadsheetUuid == null)
          {'id': 'back', 'label': l.chartBack},
        if (step2) {'id': 'insert', 'label': l.dialogInsert},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    final step2 = _sheetUuid != null;
    switch (id) {
      case 'search' when value is String:
        if (step2) {
          setState(() => _chartSearch.text = value);
        } else {
          _search.text = value;
          unawaited(_findSheets());
        }
        return true;
      case 'tab' when value is String && _tabs.contains(value) && !step2:
        setState(() => _tab = value);
        unawaited(_findSheets());
        return true;
      case 'spreadsheet' when value is String && !step2:
        final s = _sheets.where((x) => x.uuid.uuid == value).firstOrNull;
        if (s == null || !canCopy(s)) return false;
        unawaited(_open(s.uuid.uuid, s.name));
        return true;
      case 'chart' when step2:
        final ids = value is List
            ? value.whereType<String>()
            : [?value as String?];
        final tiles = _listing?.charts ?? const <ChartSourceTile>[];
        final pick = [
          for (final id in ids)
            if (tiles.where((t) => t.chartObjectId == id && _selectable(t))
                case final m when m.isNotEmpty)
              id,
        ];
        if (pick.isEmpty || (widget.single && pick.length > 1)) return false;
        setState(() {
          _selected
            ..clear()
            ..addAll(pick);
        });
        return true;
      case 'link' when value is bool && step2:
        setState(() => _link = value);
        return true;
      case 'matchTheme' when value is bool && step2:
        setState(() => _match = value);
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        _close();
        return true;
      case 'back' when _sheetUuid != null:
        _back();
        return true;
      case 'insert' when _selected.isNotEmpty:
        _insert();
        return true;
    }
    return false;
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final step2 = _sheetUuid != null;
    return ShadDialog(
      key: ChartInsertKeys.dialog,
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(
        step2
            ? l.chartInsertFromTitle(_sheetTitle)
            : (widget.single ? l.chartRelinkTitle : l.chartInsertDialogTitle),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      constraints: BoxConstraints(maxWidth: width < 752 ? width - 32 : 720),
      actions: [
        ShadButton.outline(onPressed: _close, child: Text(la.actionCancel)),
        if (step2)
          ShadButton(
            key: ChartInsertKeys.insert,
            enabled: _selected.isNotEmpty,
            onPressed: _insert,
            child: Text(l.dialogInsert),
          ),
      ],
      child: SizedBox(
        height: 440,
        child: step2 ? _charts(context, l) : _spreadsheets(context, l),
      ),
    );
  }

  Widget _spreadsheets(BuildContext context, SlidesLocalizations l) {
    final theme = ShadTheme.of(context);
    Widget body;
    if (_loadingSheets) {
      body = const Center(child: ShadSpinner());
    } else if (_sheetsFailed || _sheets.isEmpty) {
      body = Center(
        child: Text(
          _sheetsFailed ? l.chartListFailed : l.chartNoSpreadsheets,
          textAlign: TextAlign.center,
          style: theme.textTheme.muted,
        ),
      );
    } else {
      body = ListView.builder(
        itemCount: _sheets.length,
        itemBuilder: (context, i) {
          final s = _sheets[i];
          final ok = canCopy(s);
          final row = ShadButton.ghost(
            key: ChartInsertKeys.spreadsheet(s.uuid.uuid),
            width: double.infinity,
            height: 44,
            enabled: ok,
            mainAxisAlignment: MainAxisAlignment.start,
            leading: const Icon(LucideIcons.sheet, size: 16),
            onPressed: () => unawaited(_open(s.uuid.uuid, s.name)),
            child: Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    s.owner.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
          return ok
              ? row
              : ShadTooltip(
                  builder: (_) => Text(l.chartErrExportDisabled),
                  child: row,
                );
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadInput(
          key: ChartInsertKeys.search,
          controller: _search,
          placeholder: Text(l.chartSearchSpreadsheets),
          leading: const Icon(LucideIcons.search, size: 16),
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 250),
              () => unawaited(_findSheets()),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final t in _tabs)
              ShadButton.raw(
                key: ChartInsertKeys.tab(t),
                variant: t == _tab
                    ? ShadButtonVariant.secondary
                    : ShadButtonVariant.ghost,
                size: ShadButtonSize.sm,
                onPressed: () {
                  if (t == _tab) return;
                  setState(() => _tab = t);
                  _search.clear();
                  unawaited(_findSheets());
                },
                child: Text(switch (t) {
                  'mine' => l.chartTabMine,
                  'shared' => l.chartTabShared,
                  'starred' => l.chartTabStarred,
                  _ => l.chartTabRecent,
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: body),
      ],
    );
  }

  Widget _charts(BuildContext context, SlidesLocalizations l) {
    final theme = ShadTheme.of(context);
    final err = _error;
    Widget body;
    if (_loadingCharts) {
      body = Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < 6; i++)
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: theme.colorScheme.muted,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      );
    } else if (err != null && (_listing == null || _listing!.charts.isEmpty)) {
      body = Center(
        child: Text(
          chartErrorMessage(l, err),
          textAlign: TextAlign.center,
          style: theme.textTheme.muted,
        ),
      );
    } else if (_listing == null || _listing!.charts.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.chartNoCharts,
              textAlign: TextAlign.center,
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 8),
            ShadButton.outline(
              key: ChartInsertKeys.openInSheets,
              size: ShadButtonSize.sm,
              onPressed: () {
                final uuid = _sheetUuid!;
                _close();
                unawaited(
                  widget.services.crossApp.open(
                    WonkyAppKind.sheets,
                    '/s/$uuid',
                  ),
                );
              },
              child: Text(l.chartOpenInSheets),
            ),
          ],
        ),
      );
    } else {
      final bySheet = <String, List<ChartSourceTile>>{};
      for (final c in _visibleCharts) {
        (bySheet[c.sheetName] ??= []).add(c);
      }
      body = ListView(
        children: [
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                chartErrorMessage(l, err),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
            ),
          for (final e in bySheet.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                e.key,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final c in e.value) _tile(context, l, c)],
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (widget.spreadsheetUuid == null)
              ShadButton.ghost(
                key: ChartInsertKeys.back,
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.arrowLeft, size: 14),
                onPressed: _back,
                child: Text(l.chartBack),
              ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: ShadInput(
                controller: _chartSearch,
                placeholder: Text(l.chartSearchCharts),
                leading: const Icon(LucideIcons.search, size: 14),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: body),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            ShadCheckbox(
              key: ChartInsertKeys.link,
              value: _link,
              onChanged: (v) => setState(() => _link = v),
              label: Text(l.chartLinkToSpreadsheet),
            ),
            ShadCheckbox(
              key: ChartInsertKeys.matchTheme,
              value: _match,
              onChanged: (v) => setState(() => _match = v),
              label: Text(l.chartMatchTheme),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l.chartDataNotice, style: theme.textTheme.muted),
      ],
    );
  }

  /// The deck theme and the color behind charts on the current slide.
  (ResolvedTheme, int)? _deckLook() {
    final ed = widget.editor;
    final id = ed.surfaceId ?? ed.currentSlideId;
    final slide = id == null ? null : ed.resolver.resolve(id);
    if (slide == null) return null;
    return (slide.theme, slide.background.effectiveColor(0xffffffff));
  }

  Widget _tile(BuildContext context, SlidesLocalizations l, ChartSourceTile t) {
    final theme = ShadTheme.of(context);
    final selected = _selected.contains(t.chartObjectId);
    final enabled = _selectable(t);
    final preview = t.preview;
    final deck = _deckLook();
    Widget picture;
    if (preview != null && deck != null && !t.unsupported) {
      // Memoized: a new look (theme) per build would re-lay out every tile
      // on each rebuild (CQ-47, CH-3).
      final lookKey = (preview, _match, deck.$1, deck.$2);
      final cached = _looks[t.chartObjectId];
      final look = cached != null && cached.$1 == lookKey
          ? cached.$2
          : SlideChartSpec.effective(
              snapshot: preview,
              element: ChartElementData(
                style: SlideChartStyle(useDeckTheme: _match),
              ),
              deckTheme: deck.$1,
              slideBackground: deck.$2,
            );
      _looks[t.chartObjectId] = (lookKey, look);
      picture = ChartView(
        spec: look.spec,
        data: preview.data,
        theme: look.theme,
        locale: look.locale,
        text: SlidesChartText.measurer,
      );
      if (_match) {
        picture = ColoredBox(color: Color(deck.$2), child: picture);
      }
    } else {
      picture = Center(
        child: SizedBox(
          width: 48,
          height: 36,
          child: preview != null
              ? ChartTypeIcon.of(preview.spec)
              : ChartTypeIcon(
                  id: t.is3D ? '${t.type}3d' : t.type,
                  type: ChartType.values.firstWhere(
                    (x) => x.id == t.type,
                    orElse: () => ChartType.column,
                  ),
                  threeD: t.is3D,
                ),
        ),
      );
    }
    final badges = [
      if (t.is3D) l.chart3DBadge,
      if (t.onChartSheet) l.chartSheetBadge,
      if (t.unsupported) l.chartNewerVersion,
    ];
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      label: t.title,
      child: GestureDetector(
        onDoubleTap: enabled
            ? () {
                setState(() {
                  _selected
                    ..clear()
                    ..add(t.chartObjectId);
                });
                _insert();
              }
            : null,
        child: ShadButton.raw(
          key: ChartInsertKeys.tile(t.chartObjectId),
          variant: ShadButtonVariant.ghost,
          enabled: enabled,
          width: 200,
          height: 160,
          padding: EdgeInsets.zero,
          decoration: ShadDecoration(
            border: ShadBorder.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.border,
              width: selected ? 2 : 1,
              radius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            final mod =
                HardwareKeyboard.instance.isMetaPressed ||
                HardwareKeyboard.instance.isControlPressed;
            _toggle(t, multi: mod);
          },
          child: SizedBox(
            width: 196,
            height: 156,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                  child: SizedBox(
                    height: 124,
                    child: Stack(
                      children: [
                        Positioned.fill(child: IgnorePointer(child: picture)),
                        if (badges.isNotEmpty)
                          Positioned(
                            top: 4,
                            left: 4,
                            right: 4,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final b in badges)
                                  ShadBadge.secondary(
                                    child: Text(
                                      b,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.title.isEmpty ? l.chartUntitled : t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.small,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
