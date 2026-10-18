import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../../l10n/sheets_l10n.dart';
import '../local/script_local_store.dart';
import 'script_diff_view.dart';

/// *Local history* of a script file (09 §14.3 `LocalScriptHistory`): the
/// last 20 versions saved on this device (also the losing text of a
/// conflict), each compared with the editor's text; *Restore* puts the
/// version into the editor as an unsaved draft. MCP-operable (`version`
/// select, `restore` / `close`). Returns the source to restore, or null.
Future<String?> showScriptHistoryDialog(
  BuildContext context, {
  required String fileName,
  required String current,
  required List<ScriptHistoryEntry> versions,
}) => showShadDialog<String>(
  context: context,
  builder: (_) =>
      _HistoryDialog(fileName: fileName, current: current, versions: versions),
);

class _HistoryDialog extends StatefulWidget {
  const _HistoryDialog({
    required this.fileName,
    required this.current,
    required this.versions,
  });

  final String fileName;
  final String current;
  final List<ScriptHistoryEntry> versions;

  @override
  State<_HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<_HistoryDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  int _selected = 0;

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
    super.dispose();
  }

  String _label(ScriptHistoryEntry e, SheetsLocalizations l) {
    final at = DateFormat.yMMMd().add_Hms().format(e.savedAt.toLocal());
    final note = switch (e.note) {
      'discarded' => l.scriptHistoryDiscarded,
      'overwritten' => l.scriptHistoryOverwritten,
      'before merge' => l.scriptHistoryBeforeMerge,
      _ => l.scriptHistorySaved,
    };
    return '$at · $note';
  }

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.scriptHistoryTitle(widget.fileName),
      'fields': [
        {
          'id': 'version',
          'label': l.scriptHistoryVersion,
          'type': 'select',
          'value': '$_selected',
          'options': {
            for (var i = 0; i < widget.versions.length; i++)
              '$i': _label(widget.versions[i], l),
          },
        },
      ],
      'buttons': [
        {'id': 'restore', 'label': l.scriptHistoryRestore},
        {'id': 'close', 'label': WonkyAppLocalizations.of(context).actionClose},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    final i = int.tryParse('$value');
    if (id != 'version' || i == null || i < 0 || i >= widget.versions.length) {
      return false;
    }
    setState(() => _selected = i);
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'restore':
        if (widget.versions.isEmpty) return false;
        Navigator.of(context).pop(widget.versions[_selected].source);
        return true;
      case 'close' || 'cancel':
        Navigator.of(context).pop();
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 96).clamp(240.0, 1000.0);
    final narrow = width < 640;
    final list = ListView(
      key: const ValueKey<String>('script.history.list'),
      children: [
        for (var i = 0; i < widget.versions.length; i++)
          GestureDetector(
            key: ValueKey<String>('script.history.version.$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _selected = i),
            child: Container(
              color: i == _selected ? cs.accent : null,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                _label(widget.versions[i], l),
                style: theme.textTheme.small,
              ),
            ),
          ),
      ],
    );
    final body = widget.versions.isEmpty
        ? Center(
            child: Text(
              l.scriptHistoryEmpty,
              key: const ValueKey<String>('script.history.empty'),
              style: theme.textTheme.muted,
            ),
          )
        : ScriptDiffView(
            before: widget.versions[_selected].source,
            after: widget.current,
            beforeLabel: l.scriptHistorySelected,
            afterLabel: l.scriptHistoryCurrent,
          );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => press('close'),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.scriptHistory'),
        closeIcon: const WonkyDialogCloseButton(),
        constraints: BoxConstraints(maxWidth: width + 48),
        title: Text(l.scriptHistoryTitle(widget.fileName)),
        description: Text(l.scriptHistoryDescription),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.scriptHistory.close'),
            onPressed: () => press('close'),
            child: Text(WonkyAppLocalizations.of(context).actionClose),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.scriptHistory.restore'),
            enabled: widget.versions.isNotEmpty,
            onPressed: () => press('restore'),
            child: Text(l.scriptHistoryRestore),
          ),
        ],
        child: SizedBox(
          width: width,
          height: (size.height * 0.6).clamp(240.0, 680.0),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 120, child: list),
                    const SizedBox(height: 8),
                    Expanded(child: body),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 240, child: list),
                    const SizedBox(width: 8),
                    Expanded(child: body),
                  ],
                ),
        ),
      ),
    );
  }
}
