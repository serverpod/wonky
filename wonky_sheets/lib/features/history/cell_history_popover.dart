import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import 'change_labels.dart';
import '../../l10n/sheets_l10n.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'cell_history.dart';

/// Display text of a stored cell content in a history entry (Sheets 10 §6):
/// formulas in A1 against the current structure, numbers plain.
String historyValueText(
  SheetEditorController editor,
  CellHistoryTarget target,
  String? content,
) {
  final c = CellContent.decode(content);
  switch (c) {
    case null:
      return '';
    case FormulaContent(:final text):
      final sheet = editor.model.sheet(target.sheetId);
      final row = sheet?.rows.indexOf(target.rowId) ?? -1;
      final col = sheet?.columns.indexOf(target.colId) ?? -1;
      if (row < 0 || col < 0) return text;
      try {
        return editor.hooks.toA1(
          text,
          sheetId: target.sheetId,
          row: row,
          col: col,
          locale: editor.locale,
        );
      } catch (_) {
        return text;
      }
    case TextContent(:final text):
      return text;
    case NumberContent(:final number):
      return CellContent.formatNumber(number);
    case BoolContent(:final value):
      return value ? 'TRUE' : 'FALSE';
    case ErrorContent(:final kind):
      return kind.literal;
    case RichTextContent():
      return c.plainText ?? '';
  }
}

/// The *Show edit history* popover of a cell (Sheets 10 §6): one entry at a
/// time, ‹ n of m ›, *Restore this value*.
class CellHistoryPopover extends StatelessWidget {
  const CellHistoryPopover({
    super.key,
    required this.editor,
    required this.controller,
    required this.onClose,
  });

  final SheetEditorController editor;
  final CellHistoryController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = sheetsL10n(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            controller.previous,
        const SingleActivator(LogicalKeyboardKey.arrowRight): controller.next,
      },
      child: Focus(
        autofocus: true,
        child: Semantics(
          container: true,
          label: l.cellHistoryTitle,
          child: Container(
            decoration: BoxDecoration(
              color: cs.popover,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context, l, theme),
                  ShadSeparator.horizontal(margin: EdgeInsets.zero),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: _body(context, l, theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    SheetsLocalizations l,
    ShadThemeData theme,
  ) {
    final n = controller.items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.cellHistoryTitle,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ShadIconButton.ghost(
            key: const ValueKey<String>('sheets.history.cell.newer'),
            width: 26,
            height: 26,
            iconSize: 14,
            semanticLabel: l.cellHistoryNewer,
            enabled: controller.index > 0,
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: controller.previous,
          ),
          if (n > 0)
            Text(
              l.cellHistoryPosition(controller.index + 1, n),
              key: const ValueKey<String>('sheets.history.cell.position'),
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ShadIconButton.ghost(
            key: const ValueKey<String>('sheets.history.cell.older'),
            width: 26,
            height: 26,
            iconSize: 14,
            semanticLabel: l.cellHistoryOlder,
            enabled: controller.index < n - 1,
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: controller.next,
          ),
          ShadIconButton.ghost(
            key: const ValueKey<String>('sheets.history.cell.close'),
            width: 26,
            height: 26,
            iconSize: 14,
            semanticLabel: l.actionClose,
            icon: const Icon(LucideIcons.x),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    SheetsLocalizations l,
    ShadThemeData theme,
  ) {
    final e = controller.current;
    final cs = theme.colorScheme;
    if (e == null) {
      if (controller.loading) {
        return const Center(
          child: Padding(padding: EdgeInsets.all(8), child: ShadSpinner()),
        );
      }
      return Text(
        controller.offline ? l.cellHistoryEmptyOffline : l.cellHistoryEmpty,
        style: theme.textTheme.muted,
      );
    }
    final who = _author(e, l);
    final time = intl.DateFormat.yMMMd().add_Hm().format(e.at.toLocal());
    final before = historyValueText(editor, controller.target, e.before);
    final after = historyValueText(editor, controller.target, e.after);
    final canRestore =
        editor.canEdit && !e.bulk && e.before != _currentContent();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            WonkyAvatar(
              name: who,
              color: cs.presence(e.user?.colorIndex ?? 0),
              imageUrl: e.user?.avatarUrl,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$who · $time',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (e.bulk)
          Text(
            l.cellHistoryBulk(changeLabelText(l, e.label)),
            style: theme.textTheme.small,
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${l.cellHistoryChanged}  '),
                TextSpan(
                  text: before.isEmpty ? l.cellHistoryBlank : '"$before"',
                  style: TextStyle(color: cs.mutedForeground),
                ),
                const TextSpan(text: '  →  '),
                TextSpan(
                  text: after.isEmpty ? l.cellHistoryBlank : '"$after"',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            key: const ValueKey<String>('sheets.history.cell.change'),
            style: theme.textTheme.small,
          ),
        if (!e.bulk && e.label.isNotEmpty && !_plainEdit(e.label)) ...[
          const SizedBox(height: 4),
          Text(
            l.cellHistoryVia(changeLabelText(l, e.label)),
            style: theme.textTheme.muted,
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton.outline(
            key: const ValueKey<String>('sheets.history.cell.restore'),
            size: ShadButtonSize.sm,
            enabled: canRestore,
            onPressed: () => unawaited(
              editor.invokeCommand('sheets.history.restoreCellValue', {
                'sheetId': controller.target.sheetId,
                'rowId': controller.target.rowId,
                'colId': controller.target.colId,
                'changeLogId': e.changeLogId,
                'content': e.before,
              }),
            ),
            child: Text(l.cellHistoryRestore),
          ),
        ),
      ],
    );
  }

  String? _currentContent() {
    final t = controller.target;
    final sheet = editor.model.sheet(t.sheetId);
    final row = sheet?.rows.indexOf(t.rowId) ?? -1;
    final col = sheet?.columns.indexOf(t.colId) ?? -1;
    if (row < 0 || col < 0) return null;
    return sheet!.cellAt(row, col)?.content;
  }

  static bool _plainEdit(String label) {
    final x = label.toLowerCase();
    return x == 'typing' ||
        x == 'edit' ||
        x == 'edit cell' ||
        x.startsWith('set ');
  }

  String _author(CellHistoryItem e, SheetsLocalizations l) {
    final name =
        e.user?.displayName ??
        (e.userUuid != null && e.userUuid == editor.session.userId
            ? editor.services.me?.displayName
            : null) ??
        l.someone;
    return switch (e.actorKind) {
      'mcp' => l.actorViaMcp(name),
      'ai' => l.actorViaAi(name),
      'script' => l.actorViaScript(name),
      _ => name,
    };
  }
}
