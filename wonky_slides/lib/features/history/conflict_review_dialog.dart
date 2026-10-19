import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_slides_core/model.dart';

import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import 'change_labels.dart';
import 'local_conflicts.dart';

/// "Slide 4, Title" of a conflict (the slide when detected if the body is
/// gone).
String conflictWhere(
  SlidesLocalizations l,
  DeckModel m,
  SlidesLocalConflict c,
) {
  final slide = c.target.slideIn(m) ?? c.slideId;
  final entry = slide == null ? null : m.indexes.order.entry(slide);
  if (entry == null) return l.conflictsGoneTarget;
  final number = entry.index + 1;
  return switch (c.target.kind) {
    'notes' => l.conflictsNotesTarget(number),
    'cell' => l.conflictsCellTarget(number),
    _ => l.conflictsSlideTarget(
      number,
      m.element(c.target.elementId!) == null
          ? ''
          : VersionChangeLabels.placeholder(l, m.element(c.target.elementId!)!),
    ),
  };
}

/// A text body shown in the review ("(empty)" for none; ≤ 60 characters).
String conflictText(SlidesLocalizations l, String? delta) {
  final t = SlidesText.plainText(delta).trim().replaceAll('\n', ' ');
  if (t.isEmpty) return l.conflictsEmptyValue;
  return t.length > 60 ? '${t.substring(0, 59)}…' : t;
}

/// The overwritten-text review (Slides 09 §6.3): one checkbox per replaced
/// text ("Slide 4, Title — yours: … · now: … (Bo)"), deleted targets in the
/// description, *Restore* (mine) for the checked texts, *Copy* (mine) and
/// *Dismiss all*. MCP-operable ([WonkyDialogSpec], `dialog.textConflicts`).
Future<ConflictReviewChoice?> showConflictReviewDialog(
  BuildContext context, {
  required DeckEditorController editor,
  required List<SlidesLocalConflict> conflicts,
}) {
  final l = slidesL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final m = editor.model;
  String who(SlidesLocalConflict c) => c.theirName ?? la.someone;
  return showConflictReview<SlidesLocalConflict>(
    context,
    conflicts: conflicts,
    id: (c) => c.id,
    actionable: (c) => c.canRestore,
    rowLabel: (c) => l.conflictsRow(
      conflictWhere(l, m, c),
      conflictText(l, c.myText),
      conflictText(l, c.theirText),
      who(c),
    ),
    goneLine: (c) => l.conflictsDeletedBy(
      conflictWhere(l, m, c),
      who(c),
      conflictText(l, c.myText),
    ),
    title: l.conflictsTitle,
    description: l.conflictsDescription,
    dialogKey: 'dialog.textConflicts',
    buttons: (anyActionable) => [
      DialogButtonSpec(id: 'dismiss', label: l.conflictsDismissAll),
      DialogButtonSpec(id: 'copy', label: l.conflictsCopyMine),
      if (anyActionable)
        DialogButtonSpec(
          id: 'restore',
          label: l.conflictsRestoreMine,
          primary: true,
        ),
    ],
    // Deleted targets can be copied (not restored).
    includeGoneFor: const {'copy'},
  );
}
