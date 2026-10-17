import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The mobile layout of suite 02 §6: phones (and windows narrower than
/// shad's `sm` breakpoint) get the read-only view of documents — no
/// menubar, toolbars, side panels or status bar.
abstract final class WonkyLayout {
  /// Below this width every window is mobile (shad `sm`).
  static const double mobileMaxWidth = 640;

  /// Phones in landscape stay mobile while their shortest side is below
  /// this (the usual phone/tablet split).
  static const double phoneMaxShortestSide = 600;

  /// Whether [context] gets the mobile (read-only) layout: windows narrower
  /// than [mobileMaxWidth], and phone browsers (Android or iOS on the web)
  /// whose shortest side is below [phoneMaxShortestSide], so turning a
  /// phone to landscape does not switch to the editor.
  static bool isMobile(BuildContext context) {
    final override = _WonkyLayoutOverride.maybeOf(context);
    if (override != null) return override;
    final size = MediaQuery.sizeOf(context);
    if (size.width < mobileMaxWidth) return true;
    final phone =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return kIsWeb && phone && size.shortestSide < phoneMaxShortestSide;
  }

  /// Forces the mobile layout on or off below [child] (previews, tests).
  static Widget override({required bool mobile, required Widget child}) =>
      _WonkyLayoutOverride(mobile: mobile, child: child);
}

class _WonkyLayoutOverride extends InheritedWidget {
  const _WonkyLayoutOverride({required this.mobile, required super.child});

  final bool mobile;

  static bool? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_WonkyLayoutOverride>()
      ?.mobile;

  @override
  bool updateShouldNotify(_WonkyLayoutOverride oldWidget) =>
      oldWidget.mobile != mobile;
}
