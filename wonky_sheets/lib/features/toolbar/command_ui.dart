import 'package:wonky_app/wonky_app.dart';

import '../../l10n/sheets_l10n.dart';

/// Binds Sheets controls to commands (every toolbar/menu/tab control
/// invokes a command id — no control calls business logic): the shell's
/// [ShellCommandUi] with the Sheets toolbar keys and localizations.
class CommandUi extends ShellCommandUi {
  CommandUi(super.context, super.s) : super(toolbarKeyPrefix: 'sheets.toolbar');

  SheetsLocalizations get l => sheetsL10n(context);
}
