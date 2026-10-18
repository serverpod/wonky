import 'package:wonky_app/wonky_app.dart';

import '../../l10n/slides_l10n.dart';

/// Binds Slides chrome controls to commands: every toolbar, header, status
/// bar and inspector control invokes a command id (suite 08) — no control
/// calls business logic. The shell's [ShellCommandUi] with the Slides
/// toolbar keys and localizations.
class SlidesCommandUi extends ShellCommandUi {
  SlidesCommandUi(super.context, super.s)
    : super(toolbarKeyPrefix: 'slides.toolbar');

  SlidesLocalizations get l => slidesL10n(context);
}
