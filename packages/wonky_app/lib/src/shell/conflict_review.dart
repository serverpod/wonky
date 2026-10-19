import 'package:flutter/widgets.dart';

import 'form_dialog.dart';

/// What the user chose in a conflict review: the button id (`dismiss`, an
/// app's apply/restore/copy action) and the conflicts it applies to.
typedef ConflictReviewChoice = ({String action, List<String> ids});

/// The review of offline edits that someone else's changes overwrote
/// (Sheets 10 §9, Slides 09 §6.3; CQ-53: one dialog, the apps pass their
/// texts). One checked checkbox per conflict that can still be applied
/// ([actionable], labelled by [rowLabel]); the others (their target was
/// deleted) are listed in the description after [description]
/// ([goneLine]). [buttons] are the dialog's buttons, the primary last; the
/// returned ids are the checked actionable conflicts, plus every gone one
/// for the buttons in [includeGoneFor] (a copy can take them, a restore
/// can't). MCP-operable ([WonkyDialogSpec], [dialogKey]).
Future<ConflictReviewChoice?> showConflictReview<T>(
  BuildContext context, {
  required List<T> conflicts,
  required String Function(T) id,
  required bool Function(T) actionable,
  required String Function(T) rowLabel,
  required String Function(T) goneLine,
  required String title,
  required String description,
  required String dialogKey,
  required List<DialogButtonSpec> Function(bool anyActionable) buttons,
  Set<String> includeGoneFor = const {},
  double width = 480,
}) async {
  final apply = [
    for (final c in conflicts)
      if (actionable(c)) c,
  ];
  final gone = [
    for (final c in conflicts)
      if (!actionable(c)) c,
  ];
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: title,
      dialogKey: dialogKey,
      description: [description, for (final c in gone) goneLine(c)].join('\n'),
      width: width,
      fields: [
        for (final c in apply)
          CheckboxFieldSpec(id: id(c), label: rowLabel(c), initial: true),
      ],
      buttons: buttons(apply.isNotEmpty),
    ),
  );
  if (r == null || r.buttonId == 'cancel') return null;
  return (
    action: r.buttonId,
    ids: [
      for (final c in apply)
        if (r.values[id(c)] == true) id(c),
      if (includeGoneFor.contains(r.buttonId))
        for (final c in gone) id(c),
    ],
  );
}
