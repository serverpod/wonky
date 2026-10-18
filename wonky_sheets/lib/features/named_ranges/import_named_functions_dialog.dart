import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';
import '../number_format/mcp_dialog_state.dart';

/// A named function of another spreadsheet (07 §9.4 *Import function*).
class ImportableFunction {
  const ImportableFunction({
    required this.name,
    required this.formula,
    this.comment,
    this.metaJson,
  });

  final String name;

  /// Stored-form `=LAMBDA(…)` formula.
  final String formula;
  final String? comment;
  final String? metaJson;

  /// Parses the JSON of `sheets.namedFunctions` (server).
  static List<ImportableFunction> parseList(String json) {
    final d = jsonDecode(json);
    if (d is! List) return const [];
    return [
      for (final e in d)
        if (e is Map && e['name'] is String && e['formula'] is String)
          ImportableFunction(
            name: e['name'] as String,
            formula: e['formula'] as String,
            comment: e['comment'] as String?,
            metaJson: e['metaJson'] as String?,
          ),
    ];
  }

  /// Names of [all] functions [name]'s formula calls, transitively
  /// (imported along with it).
  static Set<String> withDependencies(
    Iterable<String> names,
    List<ImportableFunction> all,
  ) {
    final byName = {for (final f in all) f.name.toUpperCase(): f};
    final out = <String>{};
    final todo = [for (final n in names) n.toUpperCase()];
    while (todo.isNotEmpty) {
      final n = todo.removeLast();
      final f = byName[n];
      if (f == null || !out.add(n)) continue;
      final upper = f.formula.toUpperCase();
      for (final other in byName.keys) {
        if (!out.contains(other) &&
            RegExp(
              '(?<![A-Z0-9_.])${RegExp.escape(other)}\\s*\\(',
            ).hasMatch(upper)) {
          todo.add(other);
        }
      }
    }
    return out;
  }
}

/// The choice of the import dialog.
typedef ImportFunctionsChoice = ({
  UuidValue source,
  List<String> names,
  bool replace,
});

/// *Import function* (07 §9.4): pick a spreadsheet, then the named
/// functions to import (their dependencies come along); functions with an
/// existing name are skipped unless *Replace* is checked.
Future<ImportFunctionsChoice?> showImportNamedFunctionsDialog(
  BuildContext context, {
  required ShellServices services,
  required UuidValue? currentItem,
  required Future<List<ImportableFunction>> Function(UuidValue item) load,
}) => showShadDialog<ImportFunctionsChoice>(
  context: context,
  builder: (_) => ImportNamedFunctionsDialog(
    services: services,
    currentItem: currentItem,
    load: load,
  ),
);

class ImportNamedFunctionsDialog extends StatefulWidget {
  const ImportNamedFunctionsDialog({
    super.key,
    required this.services,
    required this.currentItem,
    required this.load,
  });

  final ShellServices services;
  final UuidValue? currentItem;
  final Future<List<ImportableFunction>> Function(UuidValue item) load;

  @override
  State<ImportNamedFunctionsDialog> createState() =>
      _ImportNamedFunctionsDialogState();
}

class _ImportNamedFunctionsDialogState
    extends McpDialogState<ImportNamedFunctionsDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<DriveItemView> _items = const [];
  bool _loadingItems = true;
  String? _error;

  DriveItemView? _source;
  List<ImportableFunction>? _functions;
  final Set<String> _selected = {};
  bool _replace = false;

  @override
  void initState() {
    super.initState();
    unawaited(_find());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final q = _search.text.trim();
    setState(() {
      _loadingItems = true;
      _error = null;
    });
    try {
      final drive = widget.services.drive;
      final page = q.isEmpty
          ? await drive.list(
              filter: DriveListFilter(
                view: DriveView.recent,
                kinds: [DriveItemKind.spreadsheet],
              ),
              sort: DriveSort(
                field: DriveSortField.lastOpenedByMe,
                descending: true,
              ),
              limit: 30,
            )
          : await drive.search(
              q,
              filters: DriveSearchFilters(kinds: [DriveItemKind.spreadsheet]),
              limit: 30,
            );
      if (!mounted) return;
      setState(() {
        _items = [
          for (final i in page.items)
            if (i.kind == DriveItemKind.spreadsheet &&
                i.uuid != widget.currentItem)
              i,
        ];
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingItems = false;
        _error = sheetsL10n(context).importFunctionsOffline;
      });
    }
  }

  Future<void> _pick(DriveItemView item) async {
    setState(() {
      _source = item;
      _functions = null;
      _selected.clear();
      _error = null;
    });
    try {
      final fns = await widget.load(item.uuid);
      if (!mounted || _source != item) return;
      setState(() => _functions = fns);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _functions = const [];
        _error = sheetsL10n(context).importFunctionsOffline;
      });
    }
  }

  void _back() => setState(() {
    _source = null;
    _functions = null;
    _selected.clear();
    _error = null;
  });

  ImportFunctionsChoice? get _choice {
    final s = _source;
    if (s == null || _selected.isEmpty) return null;
    return (source: s.uuid, names: _selected.toList(), replace: _replace);
  }

  // MCP (suite 09 §6.2).
  @override
  Map<String, Object?> describe() => {
    'title': 'Import named functions',
    'fields': [
      if (_source == null) ...[
        {
          'id': 'search',
          'label': 'Search spreadsheets',
          'type': 'text',
          'value': _search.text,
        },
        {
          'id': 'spreadsheet',
          'label': 'Spreadsheet',
          'type': 'select',
          'options': [for (final i in _items) i.name],
        },
      ] else ...[
        {
          'id': 'functions',
          'label': 'Functions',
          'type': 'multiselect',
          'value': _selected.toList(),
          'options': [for (final f in _functions ?? const []) f.name],
        },
        {
          'id': 'replace',
          'label': 'Replace functions with the same name',
          'type': 'checkbox',
          'value': _replace,
        },
      ],
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
      if (_source != null) {'id': 'back', 'label': 'Back'},
      if (_source != null)
        {'id': 'import', 'label': 'Import', 'enabled': _choice != null},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'search' when value is String:
        _search.text = value;
        unawaited(_find());
        return true;
      case 'spreadsheet' when value is String:
        final i = _items.where((x) => x.name == value).firstOrNull;
        if (i == null) return false;
        unawaited(_pick(i));
        return true;
      case 'functions' when value is List:
        setState(() {
          _selected
            ..clear()
            ..addAll(value.whereType<String>());
        });
        return true;
      case 'replace' when value is bool:
        setState(() => _replace = value);
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        close();
        return true;
      case 'back' when _source != null:
        _back();
        return true;
      case 'import' when _choice != null:
        close(_choice);
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final source = _source;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => close(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.importFunctions'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.importFunctionsTitle),
        description: Text(
          source == null
              ? l.importFunctionsPickSpreadsheet
              : l.importFunctionsPickFunctions(source.name),
        ),
        actions: [
          if (source != null)
            ShadButton.outline(
              key: const ValueKey<String>('dialog.importFunctions.back'),
              onPressed: _back,
              child: Text(l.importFunctionsBack),
            ),
          ShadButton.outline(
            key: const ValueKey<String>('dialog.importFunctions.cancel'),
            onPressed: () => close(),
            child: Text(la.actionCancel),
          ),
          if (source != null)
            ShadButton(
              key: const ValueKey<String>('dialog.importFunctions.import'),
              enabled: _choice != null,
              onPressed: () => close(_choice),
              child: Text(l.importFunctionsImport),
            ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 360),
          child: SizedBox(
            width: double.infinity,
            height: 360,
            child: source == null ? _sources(context) : _list(context),
          ),
        ),
      ),
    );
  }

  Widget _sources(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadInput(
          key: const ValueKey<String>('dialog.importFunctions.search'),
          controller: _search,
          autofocus: true,
          placeholder: Text(l.importFunctionsSearch),
          leading: const Icon(LucideIcons.search, size: 16),
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 250), _find);
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingItems
              ? const Center(child: ShadSpinner())
              : _error != null
              ? Center(child: Text(_error!, style: theme.textTheme.muted))
              : _items.isEmpty
              ? Center(
                  child: Text(
                    l.importFunctionsNoSpreadsheets,
                    style: theme.textTheme.muted,
                  ),
                )
              : ListView(
                  children: [
                    for (final i in _items)
                      ShadButton.ghost(
                        key: ValueKey<String>(
                          'dialog.importFunctions.item.${i.uuid}',
                        ),
                        width: double.infinity,
                        mainAxisAlignment: MainAxisAlignment.start,
                        leading: const Icon(LucideIcons.sheet, size: 16),
                        onPressed: () => _pick(i),
                        child: Expanded(
                          child: Text(
                            i.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _list(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final fns = _functions;
    if (fns == null) return const Center(child: ShadSpinner());
    if (fns.isEmpty) {
      return Center(
        child: Text(
          _error ?? l.importFunctionsNone,
          style: theme.textTheme.muted,
          textAlign: TextAlign.center,
        ),
      );
    }
    final deps = ImportableFunction.withDependencies(_selected, fns)
      ..removeAll(_selected.map((s) => s.toUpperCase()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final f in fns)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ShadCheckbox(
                    key: ValueKey<String>(
                      'dialog.importFunctions.fn.${f.name}',
                    ),
                    value:
                        _selected.contains(f.name) ||
                        deps.contains(f.name.toUpperCase()),
                    onChanged: (v) => setState(() {
                      v ? _selected.add(f.name) : _selected.remove(f.name);
                    }),
                    label: Text(f.name),
                    sublabel: Text(
                      deps.contains(f.name.toUpperCase())
                          ? l.importFunctionsDependency
                          : (f.comment ?? ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const ShadSeparator.horizontal(
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
        ShadCheckbox(
          key: const ValueKey<String>('dialog.importFunctions.replace'),
          value: _replace,
          onChanged: (v) => setState(() => _replace = v),
          label: Text(l.importFunctionsReplace),
        ),
      ],
    );
  }
}
