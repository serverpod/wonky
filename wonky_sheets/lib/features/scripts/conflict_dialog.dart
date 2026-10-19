import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';
import 'editor/script_diff_view.dart';

/// Answers of the save conflict dialog (09 §14.3).
enum ScriptConflictChoice { overwrite, discardMine, merge, cancel }

/// "Bo saved a newer version of utils.dart 3 minutes ago" (09 §14.3, LWW
/// per file): *Compare* (side-by-side diff, toggled inside the dialog),
/// *Merge* (3-way with the local base), *Discard mine*, *Overwrite with
/// mine*, *Cancel*. MCP-operable.
Future<ScriptConflictChoice> showScriptConflictDialog(
  BuildContext context, {
  required String fileName,
  required String mine,
  required String theirs,
  String updatedBy = '',
  Object? updatedAt,
  bool canMerge = true,
}) async {
  final r = await showShadDialog<ScriptConflictChoice>(
    context: context,
    builder: (_) => _ConflictDialog(
      fileName: fileName,
      mine: mine,
      theirs: theirs,
      updatedBy: updatedBy,
      updatedAt: updatedAt is DateTime
          ? updatedAt
          : (updatedAt is String ? DateTime.tryParse(updatedAt) : null),
      canMerge: canMerge,
    ),
  );
  return r ?? ScriptConflictChoice.cancel;
}

class _ConflictDialog extends StatefulWidget {
  const _ConflictDialog({
    required this.fileName,
    required this.mine,
    required this.theirs,
    required this.updatedBy,
    required this.updatedAt,
    required this.canMerge,
  });

  final String fileName;
  final String mine;
  final String theirs;
  final String updatedBy;
  final DateTime? updatedAt;
  final bool canMerge;

  @override
  State<_ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<_ConflictDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  bool _compare = false;

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

  String _body(SheetsLocalizations l) {
    final at = widget.updatedAt;
    final who = widget.updatedBy;
    if (who.isEmpty) return l.scriptConflictBody(widget.fileName);
    final when = at == null
        ? ''
        : DateFormat.yMMMd().add_Hm().format(at.toLocal());
    return l.scriptConflictBodyBy(who, widget.fileName, when);
  }

  List<(String, String, bool, bool)> _buttons(SheetsLocalizations l) => [
    ('cancel', WonkyAppLocalizations.of(context).actionCancel, false, false),
    (
      'compare',
      _compare ? l.scriptHideComparison : l.scriptCompare,
      false,
      false,
    ),
    if (widget.canMerge) ('merge', l.scriptMerge, false, false),
    ('discard', l.scriptConflictDiscard, false, true),
    ('overwrite', l.scriptConflictOverwrite, true, false),
  ];

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.scriptConflictTitle,
      'description': _body(l),
      'fields': const [],
      'buttons': [
        for (final b in _buttons(l)) {'id': b.$1, 'label': b.$2},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) => false;

  @override
  bool press(String buttonId) {
    final choice = switch (buttonId) {
      'overwrite' => ScriptConflictChoice.overwrite,
      'discard' => ScriptConflictChoice.discardMine,
      'merge' when widget.canMerge => ScriptConflictChoice.merge,
      'cancel' => ScriptConflictChoice.cancel,
      _ => null,
    };
    if (buttonId == 'compare') {
      setState(() => _compare = !_compare);
      return true;
    }
    if (choice == null) return false;
    Navigator.of(context).pop(choice);
    return true;
  }

  Widget _button((String, String, bool, bool) b) {
    final key = ValueKey<String>('dialog.scriptConflict.${b.$1}');
    void onPressed() => press(b.$1);
    // Long labels shrink with an ellipsis in narrow windows.
    final label = Flexible(
      child: Text(b.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    if (b.$3) {
      return ShadButton(key: key, onPressed: onPressed, child: label);
    }
    if (b.$4) {
      return ShadButton.destructive(
        key: key,
        onPressed: onPressed,
        child: label,
      );
    }
    return ShadButton.outline(key: key, onPressed: onPressed, child: label);
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final size = MediaQuery.sizeOf(context);
    final width = _compare
        ? (size.width - 96).clamp(240.0, 960.0)
        : (size.width - 96).clamp(240.0, 520.0);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => press('cancel'),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.scriptConflict'),
        closeIcon: const WonkyDialogCloseButton(),
        constraints: BoxConstraints(maxWidth: width + 48),
        title: Text(l.scriptConflictTitle),
        description: Text(_body(l)),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_compare)
                SizedBox(
                  height: (size.height * 0.5).clamp(160.0, 600.0),
                  child: ScriptDiffView(
                    before: widget.theirs,
                    after: widget.mine,
                    beforeLabel: l.scriptVersionTheirs,
                    afterLabel: l.scriptVersionMine,
                  ),
                ),
              const SizedBox(height: 12),
              // Five actions: wrap instead of one row (narrow windows).
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [for (final b in _buttons(l)) _button(b)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
