import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';
import '../number_format/mcp_dialog_state.dart';

/// Picks another spreadsheet the user can open (recent ones, or a search):
/// *Import theme* (06 §13, P2) and other cross-spreadsheet imports.
/// Returns the drive item.
Future<DriveItemView?> showSpreadsheetPickerDialog(
  BuildContext context, {
  required ShellServices services,
  required String title,
  UuidValue? exclude,
}) => showShadDialog<DriveItemView>(
  context: context,
  builder: (_) => SpreadsheetPickerDialog(
    services: services,
    title: title,
    exclude: exclude,
  ),
);

class SpreadsheetPickerDialog extends StatefulWidget {
  const SpreadsheetPickerDialog({
    super.key,
    required this.services,
    required this.title,
    this.exclude,
  });

  final ShellServices services;
  final String title;
  final UuidValue? exclude;

  @override
  State<SpreadsheetPickerDialog> createState() =>
      _SpreadsheetPickerDialogState();
}

class _SpreadsheetPickerDialogState
    extends McpDialogState<SpreadsheetPickerDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<DriveItemView> _items = const [];
  bool _loading = true;
  bool _failed = false;

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
      _loading = true;
      _failed = false;
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
            if (i.kind == DriveItemKind.spreadsheet && i.uuid != widget.exclude)
              i,
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Map<String, Object?> describe() => {
    'title': widget.title,
    'fields': [
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
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
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
        close(i);
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    if (buttonId != 'cancel') return false;
    close();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => close(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.pickSpreadsheet'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(widget.title),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.pickSpreadsheet.cancel'),
            onPressed: () => close(),
            child: Text(la.actionCancel),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SizedBox(
            width: double.infinity,
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadInput(
                  key: const ValueKey<String>('dialog.pickSpreadsheet.search'),
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
                  child: _loading
                      ? const Center(child: ShadSpinner())
                      : _failed || _items.isEmpty
                      ? Center(
                          child: Text(
                            _failed
                                ? l.pickSpreadsheetOffline
                                : l.importFunctionsNoSpreadsheets,
                            style: theme.textTheme.muted,
                          ),
                        )
                      : ListView(
                          children: [
                            for (final i in _items)
                              ShadButton.ghost(
                                key: ValueKey<String>(
                                  'dialog.pickSpreadsheet.item.${i.uuid}',
                                ),
                                width: double.infinity,
                                mainAxisAlignment: MainAxisAlignment.start,
                                leading: const Icon(
                                  LucideIcons.sheet,
                                  size: 16,
                                ),
                                onPressed: () => close(i),
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
            ),
          ),
        ),
      ),
    );
  }
}
