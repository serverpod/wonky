import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../l10n/wonky_ui_localizations.dart';

/// The X of a `ShadDialog` (suite 02 §4): pass it as `closeIcon`.
///
/// It looks like shad's default close button but has an accessible label
/// ("Close"), and by default it closes with `Navigator.maybePop`, so a
/// dialog's `PopScope` (e.g. a discard confirmation) is honored. Pass
/// [onPressed] to run the dialog's own cancel path instead.
class WonkyDialogCloseButton extends StatelessWidget {
  const WonkyDialogCloseButton({super.key, this.onPressed});

  /// Runs instead of `Navigator.maybePop` when the X is pressed.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final label =
        Localizations.of<WonkyUiLocalizations>(
          context,
          WonkyUiLocalizations,
        )?.close ??
        'Close';
    return ShadIconButton.ghost(
      key: const ValueKey<String>('dialog.close'),
      icon: const Icon(LucideIcons.x, size: 16),
      width: 20,
      height: 20,
      padding: EdgeInsets.zero,
      semanticLabel: label,
      foregroundColor: theme.colorScheme.foreground.withValues(alpha: .5),
      hoverBackgroundColor: const Color(0x00000000),
      hoverForegroundColor: theme.colorScheme.foreground,
      pressedForegroundColor: theme.colorScheme.foreground,
      onPressed: onPressed ?? () => unawaited(Navigator.of(context).maybePop()),
    );
  }
}
