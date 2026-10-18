import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/wonky_app_localizations.dart';
import '../../shell/shell_services.dart';
import '../auth_controller.dart';
import 'sign_in_screen.dart';

/// Blocking "Session expired" dialog over the current screen (suite 04
/// §1.5): state is preserved; after re-auth the user continues.
Future<void> showSessionExpiredDialog(BuildContext context, ShellServices s) =>
    showShadDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l = WonkyAppLocalizations.of(context);
        return ListenableBuilder(
          listenable: s.auth,
          builder: (context, _) {
            if (s.auth.status != AuthStatus.sessionExpired) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.of(context).maybePop();
              });
            }
            return ShadDialog(
              key: const ValueKey<String>('dialog.sessionExpired'),
              closeIcon: const WonkyDialogCloseButton(),
              title: Text(l.sessionExpiredTitle),
              description: Text(l.sessionExpiredBody),
              actions: [
                ShadButton.ghost(
                  onPressed: () {
                    s.auth.acknowledgeExpiry();
                    Navigator.of(context).pop();
                  },
                  child: Text(l.switchAccount),
                ),
              ],
              child: SizedBox(
                width: 380,
                child: SignInScreen(
                  services: s,
                  embedded: true,
                  initialEmail: s.me?.email,
                  onSignedIn: () => Navigator.of(context).maybePop(),
                ),
              ),
            );
          },
        );
      },
    );
