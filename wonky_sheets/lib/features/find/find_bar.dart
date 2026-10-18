import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';

import '../../l10n/sheets_l10n.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'find_controller.dart';

/// "3 of 12" / "No results" / "100,000+".
String findStatusText(SheetsLocalizations l, FindController f) {
  if (f.query.isEmpty) return '';
  if (f.error != null) return '';
  final (cur, total, capped) = f.status;
  if (total == 0) return l.findNoResults;
  final t = capped ? '$total+' : '$total';
  return cur <= 0 ? l.findMatchesCount(t) : l.findOfCount(cur, t);
}

/// The compact find bar at the top-right of the grid (07 §11.1): the
/// shell's [WonkyFindBar] on the [FindController], with ⋮ for *Find and
/// replace*; Esc returns to the grid.
class FindBar extends StatelessWidget {
  const FindBar({super.key, required this.editor, required this.find});

  final SheetEditorController editor;
  final FindController find;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    return WonkyFindBar(
      model: find,
      keyPrefix: 'sheets.findBar',
      labels: FindBarLabels(
        placeholder: l.findPlaceholder,
        previous: l.cmdFindPrevious,
        next: l.cmdFindNext,
        replace: l.cmdFindOpenReplace,
        close: l.findClose,
      ),
      statusText: () => findStatusText(l, find),
      onNext: (_) => editor.invokeCommand('sheets.find.next'),
      onPrevious: (_) => editor.invokeCommand('sheets.find.previous'),
      onReplace: (query) =>
          editor.invokeCommand('sheets.find.openReplace', {'query': query}),
      onClose: () => editor.invokeCommand('sheets.find.close'),
      replaceIcon: LucideIcons.ellipsisVertical,
      replaceKeyName: 'more',
      queryWidth: 230,
    );
  }
}
