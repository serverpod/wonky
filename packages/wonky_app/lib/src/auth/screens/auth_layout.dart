import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../branding/product_icon.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/account_menu.dart';
import '../../shell/shell_services.dart';
import '../auth_controller.dart';
import '../password_strength.dart';

/// The `next` target of an auth route (where to land after signing in or
/// up) when it is a safe relative path such as `/improvements`; null for
/// anything else (`//host`, `https://…`), so it never leaves the app.
String? safeAuthNext(String? next) =>
    next != null && next.startsWith('/') && !next.startsWith('//')
    ? next
    : null;

/// The sign-in route that comes back to [location] after sign-in (`/` and
/// auth routes: plain `/signin`).
String signInPathBackTo(String location) {
  final next = safeAuthNext(location);
  return next == null || next == '/' || next.startsWith('/signin')
      ? '/signin'
      : '/signin?next=${Uri.encodeQueryComponent(next)}';
}

/// [path] (an auth route) with the current route's safe `next` carried
/// over: sign-in → sign-up → verification keep the target.
String authPathWithNext(ShellServices services, String path) {
  final next = safeAuthNext(services.router.state.uri.queryParameters['next']);
  return next == null ? path : '$path?next=${Uri.encodeQueryComponent(next)}';
}

/// Centered card (max 400 px) on a branded background with the current app's
/// logo and the "Wonky Work" wordmark (suite 04 §2).
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.services,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
  });

  final ShellServices services;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final brand = services.config.brandColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              brand.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
              ),
              theme.colorScheme.background,
            ),
            theme.colorScheme.canvas,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: ThemeToggleButton(services: services),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // One sign-in covers the suite (suite 04 §1): the
                    // suite's icon and name, not the app's — left-aligned
                    // with the card below.
                    Row(
                      key: const ValueKey<String>('auth.brand'),
                      children: [
                        const WonkyProductIcon(WonkyProduct.work, size: 56),
                        const SizedBox(width: 12),
                        Text(
                          l.wonkyWork,
                          style: theme.textTheme.h3.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ShadCard(
                      width: double.infinity,
                      title: Semantics(
                        container: true,
                        header: true,
                        child: Text(title),
                      ),
                      description: subtitle == null ? null : Text(subtitle!),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: child,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 16),
                      footer!,
                    ],
                    // Bugs & improvements (specs/16 §4.1): the board page,
                    // readable signed out (*Report* asks to sign in).
                    const SizedBox(height: 8),
                    Center(
                      child: ShadButton.link(
                        key: const ValueKey<String>('auth.board'),
                        size: ShadButtonSize.sm,
                        foregroundColor: theme.colorScheme.mutedForeground,
                        leading: const Icon(LucideIcons.bug, size: 14),
                        onPressed: () => services.router.go('/improvements'),
                        child: Text(l.boardReportName),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled input with an inline error.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.obscure = false,
    this.autofocus = false,
    this.autofillHints = const [],
    this.keyboardType,
    this.onSubmitted,
    this.fieldKey,
    this.trailing,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final bool obscure;
  final bool autofocus;
  final Iterable<String> autofillHints;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final String? fieldKey;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.small),
        const SizedBox(height: 6),
        ShadInput(
          key: fieldKey == null ? null : ValueKey<String>(fieldKey!),
          controller: controller,
          obscureText: obscure,
          autofocus: autofocus,
          autofillHints: autofillHints,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          trailing: trailing,
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.onSubmitted,
    this.fieldKey,
    this.newPassword = false,
    this.onChanged,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onSubmitted;
  final String? fieldKey;
  final bool newPassword;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return AuthField(
      label: widget.label,
      controller: widget.controller,
      error: widget.error,
      obscure: _obscure,
      autofocus: widget.autofocus,
      fieldKey: widget.fieldKey,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofillHints: [
        widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
      ],
      trailing: ShadIconButton.ghost(
        width: 24,
        height: 24,
        iconSize: 14,
        semanticLabel: _obscure ? l.authShowPassword : l.authHidePassword,
        icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

/// The sign-up strength meter.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final (label, color, level) = switch (strength) {
      PasswordStrength.empty => (l.strengthEmpty, c.muted, 0),
      PasswordStrength.weak => (l.strengthWeak, c.destructive, 1),
      PasswordStrength.fair => (l.strengthFair, c.warning, 2),
      PasswordStrength.good => (l.strengthGood, c.info, 3),
      PasswordStrength.strong => (l.strengthStrong, c.success, 4),
    };
    return Semantics(
      label: l.strengthLabel(label),
      child: Row(
        children: [
          for (var i = 1; i <= 4; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= level ? color : c.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.muted.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Localized message of an [AuthError].
String authErrorText(WonkyAppLocalizations l, AuthError e) => switch (e) {
  AuthError.invalidCredentials => l.authErrorInvalidCredentials,
  AuthError.tooManyAttempts => l.authErrorTooManyAttempts,
  AuthError.invalidCode => l.authErrorInvalidCode,
  AuthError.expiredCode => l.authErrorExpiredCode,
  AuthError.passwordPolicy => l.authErrorPasswordPolicy,
  AuthError.googleUnavailable => l.authErrorGoogleUnavailable,
  AuthError.popupBlocked => l.authErrorPopupBlocked,
  AuthError.network => l.authErrorNetwork,
  AuthError.unknown => l.authErrorUnknown,
};

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Email validation for auth forms.
String? validateEmail(WonkyAppLocalizations l, String v) {
  final t = v.trim();
  if (t.isEmpty) return l.errorRequired;
  if (!_emailPattern.hasMatch(t)) return l.authErrorEmail;
  return null;
}

/// A form-level error banner.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      liveRegion: true,
      child: ShadAlert.destructive(
        key: const ValueKey<String>('auth.error'),
        icon: const Icon(LucideIcons.circleAlert),
        title: Text(message),
      ),
    ),
  );
}

/// "Continue with Google" (suite 04 §1.6): an outline button with Google's
/// unaltered "G", above the email form. Signs in, or creates the account on
/// a first sign-in. Shown only where Google sign-in is offered (web).
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.services,
    required this.onError,
    this.onSignedIn,
  });

  final ShellServices services;

  /// Shows a form error (null clears it).
  final ValueChanged<String?> onError;
  final VoidCallback? onSignedIn;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  /// The pending attempt. The button stays enabled while Google's popup is
  /// open: the app can't see the popup close (cross-origin isolation), so a
  /// click starts over in the same popup.
  int _attempt = 0;
  bool _busy = false;

  Future<void> _signIn() async {
    final l = WonkyAppLocalizations.of(context);
    final attempt = ++_attempt;
    widget.onError(null);
    setState(() => _busy = true);
    try {
      if (await widget.services.auth.signInWithGoogle()) {
        widget.onSignedIn?.call();
      }
    } on AuthFailure catch (e) {
      if (attempt == _attempt) widget.onError(authErrorText(l, e.error));
    } finally {
      if (mounted && attempt == _attempt) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return ShadButton.outline(
      key: const ValueKey<String>('auth.google'),
      onPressed: _signIn,
      leading: _busy
          ? const SizedBox.square(dimension: 18, child: ShadSpinner(size: 16))
          : const GoogleLogo(),
      child: Text(l.authContinueWithGoogle),
    );
  }
}

/// A horizontal rule with a centered label ("or").
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final line = Expanded(
      child: Container(height: 1, color: theme.colorScheme.border),
    );
    return Row(
      spacing: 12,
      children: [
        line,
        Text(label, style: theme.textTheme.muted.copyWith(fontSize: 12)),
        line,
      ],
    );
  }
}
