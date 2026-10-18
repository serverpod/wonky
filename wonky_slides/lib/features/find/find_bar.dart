import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import 'find_controller.dart';

/// "3 of 12" / "12 matches" / "No results" (03 §13).
String findStatusText(SlidesLocalizations l, DeckFindController f) {
  if (f.query.isEmpty || f.error != null) return '';
  final (cur, total) = f.status;
  if (total == 0) return l.findNoResults;
  return cur <= 0 ? l.findMatchesCount(total) : l.findOfCount(cur, total);
}

/// The compact find bar at the top-right of the canvas (03 §13, ⌘F): the
/// shell's [WonkyFindBar] on the deck's [DeckFindController]. Showing a
/// match starts text editing; the bar keeps the keyboard. Esc returns to
/// the canvas.
class SlidesFindBar extends StatelessWidget {
  const SlidesFindBar({super.key, required this.editor});

  final DeckEditorController editor;

  static const barKey = ValueKey<String>('slides.findBar');

  Future<void> _run(String id, [Map<String, Object?> args = const {}]) => editor
      .services
      .invokeWithToasts(id, args: args, source: InvocationSource.ui);

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final f = DeckFindController.of(editor);
    return WonkyFindBar(
      model: f,
      keyPrefix: barKey.value,
      labels: FindBarLabels(
        placeholder: l.findPlaceholder,
        previous: l.cmdFindPrevious,
        next: l.cmdFindNext,
        replace: l.cmdFindOpenReplace,
        close: l.findClose,
      ),
      statusText: () => findStatusText(l, f),
      onNext: (query) => _run('slides.find.next', {'query': query}),
      onPrevious: (query) => _run('slides.find.previous', {'query': query}),
      onReplace: (query) => _run('slides.find.openReplace', {'find': query}),
      onClose: () => _run('slides.find.close'),
    );
  }
}
