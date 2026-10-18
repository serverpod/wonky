import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../l10n/wonky_app_localizations.dart';
import '../shell/shell_services.dart';

/// The undo history (suite 08 §3.5): the last 50 steps; clicking a step
/// undoes it and everything above it; hovering highlights those steps.
Future<void> showUndoHistoryDialog(BuildContext context, ShellServices s) =>
    showShadDialog<void>(
      context: context,
      builder: (context) => ShadDialog(
        key: const ValueKey<String>('undoHistory'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(WonkyAppLocalizations.of(context).undoHistoryTitle),
        child: SizedBox(
          width: 380,
          height: 360,
          child: UndoHistoryList(services: s),
        ),
      ),
    );

/// The list body (also used inside the toolbar's press-and-hold popover).
class UndoHistoryList extends StatefulWidget {
  const UndoHistoryList({super.key, required this.services, this.onDone});

  final ShellServices services;
  final VoidCallback? onDone;

  @override
  State<UndoHistoryList> createState() => _UndoHistoryListState();
}

class _UndoHistoryListState extends State<UndoHistoryList> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final history = widget.services.undo.history();
    if (history.isEmpty) {
      return Center(
        child: Text(l.undoHistoryEmpty, style: theme.textTheme.muted),
      );
    }
    final time = intl.DateFormat.jms();
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, i) {
        final h = history[i];
        final highlighted = _hover != null && i <= _hover!;
        final agent = h.step.source.isAgent;
        return MouseRegion(
          onEnter: (_) => setState(() => _hover = i),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            onTap: () async {
              Navigator.of(context).maybePop();
              widget.onDone?.call();
              await widget.services.dispatcher.invoke(
                'shell.edit.undoTo',
                args: {'stepId': h.step.id},
                source: InvocationSource.menu,
              );
            },
            child: Container(
              key: ValueKey<String>('undoHistory.step.$i'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: highlighted ? theme.colorScheme.accent : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    agent ? LucideIcons.bot : LucideIcons.undo2,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(h.step.label, overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    time.format(h.step.updatedAt.toLocal()),
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
