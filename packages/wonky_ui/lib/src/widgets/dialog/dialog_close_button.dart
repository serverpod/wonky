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
///
/// A dialog shows the X only when it has no other way out: inside a
/// `ShadDialog` with `actions` (Cancel, Close, Done, Got it, …) the button
/// renders nothing, so the rule holds for every dialog of every app
/// (suite 02 §4.20). Escape and the barrier still dismiss. Pass [always]
/// for a dialog whose actions don't dismiss it.
///
/// A `const` button is not rebuilt when its dialog's `actions` change: a
/// dialog whose actions appear later (after loading) keys it on whether it
/// has any, `WonkyDialogCloseButton(key: ValueKey<bool>(actions.isEmpty))`.
class WonkyDialogCloseButton extends StatelessWidget {
  const WonkyDialogCloseButton({
    super.key,
    this.onPressed,
    this.always = false,
  });

  /// Runs instead of `Navigator.maybePop` when the X is pressed.
  final VoidCallback? onPressed;

  /// Show the X even when the dialog has actions.
  final bool always;

  /// Whether the X shows in [context] (no dialog actions, or [always]).
  static bool showsIn(BuildContext context, {bool always = false}) {
    if (always) return true;
    final dialog = context.findAncestorWidgetOfExactType<ShadDialog>();
    return dialog == null || dialog.actions.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!showsIn(context, always: always)) return const SizedBox.shrink();
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
