import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart' hide formatBytes;
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_sheets_core/formula.dart' show ColumnLetters;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../data_tools/spreadsheet_picker_dialog.dart';
import '../import_export/pending_uploads.dart';
import 'import_pipeline.dart';
import 'server_import.dart';

/// What the import dialog returns.
class ImportDialogResult {
  const ImportDialogResult(this.file, this.options, this.parsed);

  final ImportFileData file;
  final ImportOptions options;

  /// The file parsed with [options] (reused by the import when present).
  final ParsedImportFile? parsed;
}

/// The size check of the open spreadsheet (null: no spreadsheet / create
/// new only).
typedef ImportEstimator =
    ImportSizeEstimate Function(ParsedImportFile parsed, ImportOptions o);

/// Locales offered for CSV numbers and dates (the spreadsheet's first).
const importLocales = [
  'en_US',
  'en_GB',
  'de_DE',
  'fr_FR',
  'es_ES',
  'it_IT',
  'nl_NL',
  'pt_BR',
  'sv_SE',
  'da_DK',
  'fi_FI',
  'pl_PL',
  'ja_JP',
];

/// *File › Import* (04 §11.15, 11 §2.2): source step (drop zone + *Browse*)
/// and options (location, separator, encoding, locale, conversion, sheets,
/// unsupported formulas) with a 20-row preview and the cell-limit check.
Future<ImportDialogResult?> showImportDialog(
  BuildContext context, {
  ImportFileData? file,
  ImportLocation? location,
  required bool canEdit,
  required String spreadsheetLocale,
  String? activeCell,
  ImportEstimator? estimate,
  UuidValue? exclude,
  bool fileLocked = false,
}) => showShadDialog<ImportDialogResult>(
  context: context,
  builder: (_) => ImportDialog(
    initialFile: file,
    initialLocation: location,
    canEdit: canEdit,
    spreadsheetLocale: spreadsheetLocale,
    activeCell: activeCell,
    estimate: estimate,
    exclude: exclude,
    fileLocked: fileLocked,
  ),
);

class ImportDialog extends StatefulWidget {
  const ImportDialog({
    super.key,
    this.initialFile,
    this.initialLocation,
    required this.canEdit,
    required this.spreadsheetLocale,
    this.activeCell,
    this.estimate,
    this.exclude,
    this.fileLocked = false,
  });

  final ImportFileData? initialFile;
  final ImportLocation? initialLocation;
  final bool canEdit;
  final String spreadsheetLocale;
  final String? activeCell;
  final ImportEstimator? estimate;

  /// The open spreadsheet (not offered in the *Drive* tab).
  final UuidValue? exclude;

  /// *Open with Wonky Sheets* (`/import?file=`, D-16): the Drive file is the
  /// source, so the file can't be changed (no *Change file*, no drop) and
  /// the only location is a new spreadsheet. D-18: the dialog offered
  /// *Change file* — whose bytes the server conversion of the Drive file
  /// ignored — and five locations that need an open spreadsheet.
  final bool fileLocked;

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

/// Separator choices of the dialog (value → JSON separator).
const _separators = ['auto', '\t', ',', ';', '|', 'custom'];

class _ImportDialogState extends State<ImportDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  ImportFileData? _file;
  String? _fileError;
  bool _dropping = false;

  late ImportLocation _location;
  String _separator = 'auto';
  final _custom = TextEditingController();
  final _scroll = ScrollController();
  String _encoding = 'auto';
  String? _locale;
  bool _convert = true;
  UnsupportedFormulaMode _unsupported = UnsupportedFormulaMode.value;
  List<ImportFileSheet> _sheets = const [];
  Set<String> _selected = {};

  ParsedImportFile? _parsed;
  String? _parsedKey;
  bool _parsing = false;
  Object? _parseError;
  Timer? _debounce;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _location =
        widget.initialLocation ??
        (widget.canEdit
            ? ImportLocation.insertSheets
            : ImportLocation.createNew);
    final f = widget.initialFile;
    if (f != null) _setFile(f, notify: false);
  }

  /// Whether the import runs as a server job (big file, online; 11 §3.1).
  bool get _onServer {
    final s = _registeredIn;
    final f = _file;
    if (s == null || f == null) return false;
    if (_location == ImportLocation.createNew) return false;
    final cells = _parsed?.document.sheets.fold<int>(
      0,
      (n, sh) => n + sh.cells.length,
    );
    return runsOnServer(s, f, cells: cells);
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
    _custom.dispose();
    _scroll.dispose();
    super.dispose();
  }

  SheetsFileFormat? get _format => _file?.format;
  bool get _isText => _format?.isText ?? false;

  bool _allowed(ImportLocation l) {
    if (l == ImportLocation.createNew) return true;
    if (!widget.canEdit || widget.fileLocked) return false;
    if (l.createsSheets) return true;
    return _isText;
  }

  ImportOptions get _options {
    final sep = switch (_separator) {
      'auto' => null,
      'custom' => _custom.text.isEmpty ? null : _custom.text,
      final s => s,
    };
    return ImportOptions(
      location: _location,
      cell: _location == ImportLocation.replaceAtCell
          ? widget.activeCell
          : null,
      separator: sep,
      encoding: TextEncoding.byId(_encoding == 'auto' ? null : _encoding),
      locale: _locale,
      convert: _convert,
      sheets: _format?.isWorkbook ?? false
          ? [
              for (final s in _sheets)
                if (_selected.contains(s.name)) s.name,
            ]
          : null,
      unsupportedFormulas: _unsupported,
    );
  }

  /// Options that change the parse result.
  String get _parseKey {
    final o = _options;
    return _isText
        ? '${o.separator}|${o.encoding?.id}|${o.locale}|${o.convert}'
        : _unsupported.name;
  }

  void _setFile(ImportFileData f, {bool notify = true}) {
    void apply() {
      _file = f;
      _fileError = null;
      _parsed = null;
      _parsedKey = null;
      _parseError = null;
      final fmt = f.format;
      if (fmt == null) {
        _fileError = 'unsupported';
      } else if (fmt == SheetsFileFormat.xls) {
        _fileError = 'xls';
      }
      _sheets = const [];
      _selected = {};
      if (fmt != null && fmt.isWorkbook) {
        try {
          _sheets = SheetsFileImporter.listSheets(f.bytes, fmt);
          _selected = {
            for (final s in _sheets)
              if (!s.hidden) s.name,
          };
        } on ImportFileException catch (e) {
          _fileError = e.message;
        }
      }
      if (!_allowed(_location)) {
        _location = widget.canEdit
            ? ImportLocation.insertSheets
            : ImportLocation.createNew;
      }
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
    if (_fileError == null) _scheduleParse(immediate: true);
  }

  void _scheduleParse({bool immediate = false}) {
    _debounce?.cancel();
    if (_file == null || _fileError != null) return;
    if (_parsedKey == _parseKey && _parsed != null) return;
    _debounce = Timer(
      Duration(milliseconds: immediate ? 0 : 150),
      () => unawaited(_parse()),
    );
  }

  Future<void> _parse() async {
    final file = _file;
    if (file == null) return;
    final key = _parseKey;
    final gen = ++_generation;
    setState(() {
      _parsing = true;
      _parseError = null;
    });
    try {
      final p = await parseImportFile(
        file,
        _options,
        spreadsheetLocale: widget.spreadsheetLocale,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _parsed = p;
        _parsedKey = key;
        _parsing = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _parseError = e;
        _parsing = false;
      });
    }
  }

  void _changed(VoidCallback fn) {
    setState(fn);
    _scheduleParse();
  }

  Future<void> _browse() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: SheetsFileImporter.extensions.toList(),
      dialogTitle: mounted ? sheetsL10n(context).importDialogTitle : null,
    );
    if (picked.isEmpty || !mounted) return;
    final f = picked.first;
    _setFile(ImportFileData(name: f.name, bytes: await f.readAsBytes()));
  }

  Future<void> _onDrop(DropDoneDetails d) async {
    setState(() => _dropping = false);
    if (d.files.isEmpty || widget.fileLocked) return;
    final f = d.files.first;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    _setFile(ImportFileData(name: f.name, bytes: bytes));
  }

  ImportSizeEstimate? get _estimate {
    final p = _parsed;
    final e = widget.estimate;
    if (p == null || _parsedKey != _parseKey) return null;
    try {
      if (e == null || _location == ImportLocation.createNew) {
        return IrToRowsPlanner.estimate(
          p.document,
          WorkbookModel(spreadsheetId: 'new'),
          options: _options,
        );
      }
      return e(p, _options);
    } catch (_) {
      return null;
    }
  }

  /// Cells with values in the parsed file (selected sheets).
  int get _valueCells {
    final p = _parsed;
    if (p == null) return 0;
    final wb = _format?.isWorkbook ?? false;
    return p.document.sheets
        .where((s) => !wb || _selected.contains(s.name))
        .fold(0, (n, s) => n + s.cells.length);
  }

  bool get _canImport {
    if (_file == null || _fileError != null || _parsing) return false;
    if (_parsed == null || _parsedKey != _parseKey) return false;
    if (!_allowed(_location)) return false;
    if ((_format?.isWorkbook ?? false) && _selected.isEmpty) return false;
    if (_separator == 'custom' && _custom.text.isEmpty) return false;
    return !(_estimate?.exceedsLimit ?? false);
  }

  void _submit() {
    if (!_canImport) return;
    Navigator.of(context).pop(ImportDialogResult(_file!, _options, _parsed));
  }

  // ---------------------------------------------------------------- MCP

  @override
  Map<String, Object?> describe() => {
    'title': 'Import file',
    'file': _file == null
        ? null
        : {
            'name': _file!.name,
            'size': _file!.bytes.length,
            'format': _format?.name,
            'error': _fileError,
          },
    'fields': [
      if (_file == null) ...[
        {
          'id': 'tab',
          'label': 'Source',
          'type': 'select',
          'value': _tab,
          'options': ['upload', 'recent', 'drive'],
        },
        if (_tab == 'recent')
          {
            'id': 'recentFile',
            'label': 'Recent uploads',
            'type': 'select',
            'value': null,
            'options': [for (final r in _recent ?? const []) r.id],
            'labels': [for (final r in _recent ?? const []) r.name],
          },
      ],
      {
        'id': 'location',
        'label': 'Import location',
        'type': 'select',
        'value': _location.name,
        'options': [
          for (final l in ImportLocation.values)
            if (_allowed(l)) l.name,
        ],
      },
      if (_isText) ...[
        {
          'id': 'separator',
          'label': 'Separator type',
          'type': 'select',
          'value': _separator,
          'options': _separators,
          'detected': _parsed?.delimiter,
        },
        {
          'id': 'customSeparator',
          'label': 'Custom separator',
          'type': 'text',
          'value': _custom.text,
        },
        {
          'id': 'encoding',
          'label': 'Encoding',
          'type': 'select',
          'value': _encoding,
          'options': ['auto', for (final e in TextEncoding.values) e.id],
          'detected': _parsed?.encoding?.id,
        },
        {
          'id': 'locale',
          'label': 'Locale for numbers & dates',
          'type': 'select',
          'value': _locale ?? 'spreadsheet',
          'options': ['spreadsheet', ...importLocales],
        },
        {
          'id': 'convert',
          'label': 'Convert text to numbers, dates, and formulas',
          'type': 'checkbox',
          'value': _convert,
        },
      ],
      if (_format?.isWorkbook ?? false) ...[
        {
          'id': 'sheets',
          'label': 'Sheets to import',
          'type': 'multiselect',
          'value': _selected.toList(),
          'options': [for (final s in _sheets) s.name],
        },
        {
          'id': 'unsupportedFormulas',
          'label': 'Unsupported formulas',
          'type': 'select',
          'value': _unsupported.name,
          'options': ['value', 'text'],
        },
      ],
    ],
    'estimate': _estimate == null
        ? null
        : {
            'cells': _estimate!.cells,
            'limit': _estimate!.limit,
            'exceedsLimit': _estimate!.exceedsLimit,
          },
    'buttons': [
      if (_file == null && _tab == 'drive')
        {'id': 'chooseFromDrive', 'label': 'Choose a spreadsheet'},
      {'id': 'cancel', 'label': 'Cancel'},
      {'id': 'import', 'label': 'Import data', 'enabled': _canImport},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'tab':
        if (value is! String ||
            !{'upload', 'recent', 'drive'}.contains(value)) {
          return false;
        }
        _openTab(value);
        return true;
      case 'recentFile':
        final r = (_recent ?? const <RecentImport>[])
            .where((e) => e.id == value)
            .firstOrNull;
        if (r == null) return false;
        unawaited(_pickRecent(r));
        return true;
      case 'location':
        final l = ImportLocation.byName(value);
        if (l == null || !_allowed(l)) return false;
        _changed(() => _location = l);
        return true;
      case 'separator':
        if (!_separators.contains(value)) return false;
        _changed(() => _separator = value! as String);
        return true;
      case 'customSeparator':
        _changed(() {
          _custom.text = '${value ?? ''}';
          _separator = 'custom';
        });
        return true;
      case 'encoding':
        if (value != 'auto' && TextEncoding.byId('$value') == null) {
          return false;
        }
        _changed(() => _encoding = '$value');
        return true;
      case 'locale':
        _changed(
          () => _locale = value == null || value == 'spreadsheet'
              ? null
              : '$value',
        );
        return true;
      case 'convert':
        if (value is! bool) return false;
        _changed(() => _convert = value);
        return true;
      case 'sheets':
        if (value is! List) return false;
        final names = {for (final v in value) '$v'};
        setState(
          () => _selected = {
            for (final s in _sheets)
              if (names.contains(s.name)) s.name,
          },
        );
        return true;
      case 'unsupportedFormulas':
        _changed(
          () => _unsupported = value == 'text'
              ? UnsupportedFormulaMode.text
              : UnsupportedFormulaMode.value,
        );
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'chooseFromDrive':
        if (_file != null) return false;
        unawaited(_pickFromDrive());
        return true;
      case 'cancel':
        Navigator.of(context).pop();
        return true;
      case 'import':
        if (!_canImport) return false;
        _submit();
        return true;
    }
    return false;
  }

  // ---------------------------------------------------------------- UI

  String _locationLabel(SheetsLocalizations l, ImportLocation loc) =>
      switch (loc) {
        ImportLocation.createNew => l.importLocationCreateNew,
        ImportLocation.insertSheets => l.importLocationInsertSheets,
        ImportLocation.replaceSpreadsheet => l.importLocationReplaceSpreadsheet,
        ImportLocation.replaceSheet => l.importLocationReplaceSheet,
        ImportLocation.append => l.importLocationAppend,
        ImportLocation.replaceAtCell => l.importLocationReplaceAtCell(
          widget.activeCell ?? 'A1',
        ),
      };

  String _separatorLabel(SheetsLocalizations l, String v) => switch (v) {
    'auto' =>
      _parsed?.delimiter == null
          ? l.importSeparatorAuto
          : l.importSeparatorAutoDetected(
              _delimiterName(l, _parsed!.delimiter!),
            ),
    'custom' => l.importSeparatorCustom,
    _ => _delimiterName(l, v),
  };

  String _delimiterName(SheetsLocalizations l, String d) => switch (d) {
    '\t' => l.importSeparatorTab,
    ',' => l.importSeparatorComma,
    ';' => l.importSeparatorSemicolon,
    '|' => l.importSeparatorPipe,
    _ => '"$d"',
  };

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter): _submit},
      child: ShadDialog(
        key: const ValueKey<String>('dialog.import'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.importDialogTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.import.cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.import.confirm'),
            enabled: _canImport,
            onPressed: _submit,
            child: Text(l.importDialogImport),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
          child: SizedBox(
            width: 640,
            child: _file == null ? _sourceStep(context) : _optionsStep(context),
          ),
        ),
      ),
    );
  }

  Widget _dropZone(BuildContext context, {required bool compact}) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dropping = !widget.fileLocked),
      onDragExited: (_) => setState(() => _dropping = false),
      onDragDone: (d) => unawaited(_onDrop(d)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.all(compact ? 10 : 28),
        decoration: BoxDecoration(
          color: _dropping ? cs.primary.withValues(alpha: 0.06) : cs.muted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _dropping ? cs.ring : cs.border,
            width: _dropping ? 2 : 1,
          ),
        ),
        child: compact
            ? Row(
                children: [
                  Icon(
                    LucideIcons.fileSpreadsheet,
                    size: 18,
                    color: cs.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.importFileLabel(_file!.name, _file!.sizeLabel),
                      key: const ValueKey<String>('dialog.import.file'),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small,
                    ),
                  ),
                  if (!widget.fileLocked)
                    ShadButton.ghost(
                      key: const ValueKey<String>('dialog.import.change'),
                      size: ShadButtonSize.sm,
                      onPressed: _browse,
                      child: Text(l.importChangeFile),
                    ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.upload, size: 32, color: cs.mutedForeground),
                  const SizedBox(height: 10),
                  Text(
                    l.importDropHere,
                    style: theme.textTheme.large,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.importSupportedTypes,
                    style: theme.textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  ShadButton(
                    key: const ValueKey<String>('dialog.import.browse'),
                    leading: const Icon(LucideIcons.folderOpen, size: 16),
                    onPressed: _browse,
                    child: Text(l.importBrowse),
                  ),
                ],
              ),
      ),
    );
  }

  /// Source tabs (11 §2.1): *Upload* (drop zone + *Browse*), *Recent
  /// uploads* (files imported on this device) and *Drive* (another
  /// spreadsheet, fetched as XLSX).
  Widget _sourceStep(BuildContext context) {
    final l = sheetsL10n(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ShadTabs<String>(
        key: const ValueKey<String>('dialog.import.tabs'),
        value: _tab,
        onChanged: (v) => _openTab(v),
        tabs: [
          ShadTab(
            key: const ValueKey<String>('dialog.import.tab.upload'),
            value: 'upload',
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _dropZone(context, compact: false),
            ),
            child: Text(l.importTabUpload),
          ),
          ShadTab(
            key: const ValueKey<String>('dialog.import.tab.recent'),
            value: 'recent',
            content: _recentTab(context),
            child: Text(
              MediaQuery.sizeOf(context).width < 520
                  ? l.importTabRecentShort
                  : l.importTabRecent,
            ),
          ),
          ShadTab(
            key: const ValueKey<String>('dialog.import.tab.drive'),
            value: 'drive',
            content: _driveTab(context),
            child: Text(l.importTabDrive),
          ),
        ],
      ),
    );
  }

  String _tab = 'upload';
  List<RecentImport>? _recent;
  bool _fetching = false;
  String? _sourceError;

  void _openTab(String v) {
    setState(() {
      _tab = v;
      _sourceError = null;
    });
    if (v == 'recent' && _recent == null) unawaited(_loadRecent());
  }

  Future<void> _loadRecent() async {
    final s = _registeredIn;
    final q = s == null ? null : await SheetsPendingUploads.ready(s);
    final list = await q?.recentImports() ?? const <RecentImport>[];
    if (mounted) setState(() => _recent = list);
  }

  Future<void> _pickRecent(RecentImport r) async {
    final s = _registeredIn;
    final q = s == null ? null : SheetsPendingUploads.of(s);
    final bytes = await q?.recentImportBytes(r.id);
    if (!mounted) return;
    if (bytes == null) {
      setState(() => _sourceError = sheetsL10n(context).importRecentGone);
      return;
    }
    _setFile(ImportFileData(name: r.name, bytes: bytes));
  }

  Future<void> _pickFromDrive() async {
    final s = _registeredIn;
    if (s == null || !s.connectivity.online) return;
    final api = ServerImportApi.of(s);
    if (api == null) return;
    final l = sheetsL10n(context);
    final item = await showSpreadsheetPickerDialog(
      context,
      services: s,
      title: l.importDrivePickTitle,
      exclude: widget.exclude,
    );
    if (item == null || !mounted) return;
    setState(() {
      _fetching = true;
      _sourceError = null;
    });
    try {
      final f = await api.driveFile(item.uuid, item.name);
      if (!mounted) return;
      setState(() => _fetching = false);
      _setFile(f);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetching = false;
        _sourceError = errorMessage(e);
      });
    }
  }

  Widget _sourceErrorText(BuildContext context) {
    final theme = ShadTheme.of(context);
    final e = _sourceError;
    if (e == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        e,
        key: const ValueKey<String>('dialog.import.sourceError'),
        style: theme.textTheme.small.copyWith(
          color: theme.colorScheme.destructive,
        ),
      ),
    );
  }

  Widget _recentTab(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final list = _recent;
    if (list == null) {
      return const SizedBox(height: 160, child: Center(child: ShadSpinner()));
    }
    if (list.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            l.importRecentEmpty,
            key: const ValueKey<String>('dialog.import.recentEmpty'),
            style: theme.textTheme.muted,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_jm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        for (final r in list)
          ShadButton.ghost(
            key: ValueKey<String>('dialog.import.recent.${r.id}'),
            mainAxisAlignment: MainAxisAlignment.start,
            leading: const Icon(LucideIcons.fileSpreadsheet, size: 16),
            onPressed: () => unawaited(_pickRecent(r)),
            child: Expanded(
              child: Text(
                l.importRecentItem(
                  r.name,
                  formatBytes(r.size),
                  date.format(r.importedAt),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        _sourceErrorText(context),
      ],
    );
  }

  Widget _driveTab(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final s = _registeredIn;
    final online =
        s != null && s.connectivity.online && ServerImportApi.of(s) != null;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.hardDrive,
            size: 28,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 10),
          Text(
            online ? l.importDriveHint : l.importDriveOffline,
            style: theme.textTheme.muted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ShadButton(
            key: const ValueKey<String>('dialog.import.drivePick'),
            enabled: online && !_fetching,
            leading: _fetching
                ? const SizedBox.square(dimension: 16, child: ShadSpinner())
                : const Icon(LucideIcons.fileSpreadsheet, size: 16),
            onPressed: () => unawaited(_pickFromDrive()),
            child: Text(l.importDrivePick),
          ),
          _sourceErrorText(context),
        ],
      ),
    );
  }

  Widget _optionsStep(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        t,
        style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    final est = _estimate;
    final fileError = switch (_fileError) {
      null => null,
      'unsupported' => l.importUnsupportedType,
      'xls' => l.importLegacyXls,
      final e => e,
    };
    return WonkyScrollArea(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dropZone(context, compact: true),
            if (fileError != null) ...[
              const SizedBox(height: 10),
              ShadAlert.destructive(
                key: const ValueKey<String>('dialog.import.fileError'),
                icon: const Icon(LucideIcons.circleAlert),
                title: Text(fileError),
              ),
            ] else ...[
              if (est != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.importEstimate(_valueCells),
                    style: theme.textTheme.muted,
                  ),
                ),
              label(l.importLocation),
              ShadRadioGroup<ImportLocation>(
                key: ValueKey<String>(
                  'dialog.import.location.${_location.name}',
                ),
                initialValue: _location,
                onChanged: (v) {
                  if (v != null) _changed(() => _location = v);
                },
                items: [
                  for (final loc in ImportLocation.values)
                    if (widget.fileLocked
                        ? _allowed(loc)
                        : _allowed(loc) ||
                              loc == ImportLocation.createNew ||
                              loc.createsSheets ||
                              _isText)
                      ShadRadio<ImportLocation>(
                        key: ValueKey<String>('dialog.import.loc.${loc.name}'),
                        value: loc,
                        enabled: _allowed(loc),
                        label: Text(_locationLabel(l, loc)),
                      ),
                ],
              ),
              if (_location == ImportLocation.replaceSpreadsheet)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.importReplaceSpreadsheetWarning,
                    style: theme.textTheme.small.copyWith(
                      color: cs.destructive,
                    ),
                  ),
                ),
              if (_isText) ..._textOptions(context, label),
              if (_format?.isWorkbook ?? false)
                ..._workbookOptions(context, label),
              if (est != null && est.exceedsLimit) ...[
                const SizedBox(height: 12),
                ShadAlert.destructive(
                  key: const ValueKey<String>('dialog.import.limit'),
                  icon: const Icon(LucideIcons.circleAlert),
                  title: Text(l.importLimitTitle),
                  description: Text(l.importLimitBody(est.cells, est.limit)),
                ),
              ],
              if (_file != null && _onServer) ...[
                const SizedBox(height: 8),
                Text(
                  l.importServerNote,
                  key: const ValueKey<String>('dialog.import.serverNote'),
                  style: theme.textTheme.muted,
                ),
              ] else if (_file != null && ImportThresholds.isLarge(_file!)) ...[
                const SizedBox(height: 8),
                Text(l.importLargeNote, style: theme.textTheme.muted),
              ],
              label(l.importPreview),
              _preview(context),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _textOptions(
    BuildContext context,
    Widget Function(String) label,
  ) {
    final l = sheetsL10n(context);
    final detectedEnc = _parsed?.encoding?.label;
    return [
      Wrap(
        spacing: 16,
        runSpacing: 0,
        children: [
          SizedBox(
            width: 290,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label(l.importSeparator),
                Row(
                  children: [
                    Expanded(
                      child: ShadSelect<String>(
                        key: ValueKey<String>(
                          'dialog.import.separator.$_separator.${_parsed?.delimiter}',
                        ),
                        initialValue: _separator,
                        options: [
                          for (final s in _separators)
                            ShadOption(
                              value: s,
                              child: Text(_separatorLabel(l, s)),
                            ),
                        ],
                        selectedOptionBuilder: (context, v) => Text(
                          _separatorLabel(l, v),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (v) {
                          if (v != null) _changed(() => _separator = v);
                        },
                      ),
                    ),
                    if (_separator == 'custom') ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: ShadInput(
                          key: const ValueKey<String>(
                            'dialog.import.customSeparator',
                          ),
                          controller: _custom,
                          maxLength: 8,
                          onChanged: (_) => _changed(() {}),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 290,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label(l.importEncoding),
                ShadSelect<String>(
                  key: ValueKey<String>(
                    'dialog.import.encoding.$_encoding.$detectedEnc',
                  ),
                  initialValue: _encoding,
                  options: [
                    ShadOption(
                      value: 'auto',
                      child: Text(
                        detectedEnc == null
                            ? l.importEncodingAuto
                            : l.importEncodingAutoDetected(detectedEnc),
                      ),
                    ),
                    for (final e in TextEncoding.values)
                      ShadOption(value: e.id, child: Text(e.label)),
                  ],
                  selectedOptionBuilder: (context, v) => Text(
                    v == 'auto'
                        ? (detectedEnc == null
                              ? l.importEncodingAuto
                              : l.importEncodingAutoDetected(detectedEnc))
                        : TextEncoding.byId(v)?.label ?? v,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (v) {
                    if (v != null) _changed(() => _encoding = v);
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            width: 290,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label(l.importLocale),
                ShadSelect<String>(
                  key: ValueKey<String>(
                    'dialog.import.locale.${_locale ?? ''}',
                  ),
                  initialValue: _locale ?? 'spreadsheet',
                  options: [
                    ShadOption(
                      value: 'spreadsheet',
                      child: Text(
                        l.importLocaleSpreadsheet(widget.spreadsheetLocale),
                      ),
                    ),
                    for (final loc in importLocales)
                      ShadOption(value: loc, child: Text(loc)),
                  ],
                  selectedOptionBuilder: (context, v) => Text(
                    v == 'spreadsheet'
                        ? l.importLocaleSpreadsheet(widget.spreadsheetLocale)
                        : v,
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      _changed(() => _locale = v == 'spreadsheet' ? null : v);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      ShadCheckbox(
        key: const ValueKey<String>('dialog.import.convert'),
        value: _convert,
        onChanged: (v) => _changed(() => _convert = v),
        label: Text(l.importConvert),
      ),
    ];
  }

  List<Widget> _workbookOptions(
    BuildContext context,
    Widget Function(String) label,
  ) {
    final l = sheetsL10n(context);
    return [
      label(l.importSheets),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final s in _sheets)
            ShadCheckbox(
              key: ValueKey<String>('dialog.import.sheet.${s.name}'),
              value: _selected.contains(s.name),
              onChanged: (v) => setState(() {
                if (v) {
                  _selected.add(s.name);
                } else {
                  _selected.remove(s.name);
                }
              }),
              label: Text(s.hidden ? l.importSheetHidden(s.name) : s.name),
            ),
        ],
      ),
      label(l.importUnsupportedFormulas),
      SizedBox(
        width: 290,
        child: ShadSelect<UnsupportedFormulaMode>(
          key: ValueKey<String>(
            'dialog.import.unsupported.${_unsupported.name}',
          ),
          initialValue: _unsupported,
          options: [
            ShadOption(
              value: UnsupportedFormulaMode.value,
              child: Text(l.importUnsupportedValue),
            ),
            ShadOption(
              value: UnsupportedFormulaMode.text,
              child: Text(l.importUnsupportedText),
            ),
          ],
          selectedOptionBuilder: (context, v) => Text(
            v == UnsupportedFormulaMode.text
                ? l.importUnsupportedText
                : l.importUnsupportedValue,
          ),
          onChanged: (v) {
            if (v != null) _changed(() => _unsupported = v);
          },
        ),
      ),
    ];
  }

  Widget _preview(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    if (_parseError != null) {
      return Text(
        l.importParseFailed(errorMessage(_parseError!)),
        style: theme.textTheme.small.copyWith(color: cs.destructive),
      );
    }
    final p = _parsed;
    if (p == null || _parsing) {
      return const SizedBox(height: 120, child: Center(child: ShadSpinner()));
    }
    final sheet = (_format?.isWorkbook ?? false)
        ? _sheets.where((s) => _selected.contains(s.name)).firstOrNull?.name
        : null;
    final rows = previewRows(
      p,
      sheetName: sheet,
      locale: _locale ?? widget.spreadsheetLocale,
    );
    if (rows.isEmpty) {
      return Text(l.importPreviewEmpty, style: theme.textTheme.muted);
    }
    final cols = rows.fold(0, (m, r) => r.length > m ? r.length : m);
    final small = theme.textTheme.small.copyWith(fontSize: 12);
    Widget cell(String t, {bool head = false}) => Container(
      width: head ? null : 120,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: head ? cs.muted : null,
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: head ? small.copyWith(color: cs.mutedForeground) : small,
      ),
    );
    return Container(
      key: const ValueKey<String>('dialog.import.preview'),
      height: 220,
      decoration: BoxDecoration(
        border: Border.all(color: cs.border),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.symmetric(
              inside: BorderSide(color: cs.border, width: 0.5),
            ),
            children: [
              TableRow(
                children: [
                  cell('', head: true),
                  for (var c = 0; c < cols; c++)
                    cell(ColumnLetters.fromIndex(c), head: true),
                ],
              ),
              for (var r = 0; r < rows.length; r++)
                TableRow(
                  children: [
                    cell('${r + 1}', head: true),
                    for (var c = 0; c < cols; c++)
                      cell(c < rows[r].length ? rows[r][c] : ''),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
