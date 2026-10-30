import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import 'wonky_colors.dart';
import 'wonky_fonts.dart';

/// UI density (user preference, suite 04 §4 Appearance).
enum WonkyDensity { comfortable, compact }

/// The user-tunable inputs of the theme. Compared by value, so it can be used
/// as a cache key.
@immutable
class WonkyThemeConfig {
  const WonkyThemeConfig({
    this.accent,
    this.density = WonkyDensity.comfortable,
  });

  /// One of [WonkyTheme.accents] (null = neutral zinc).
  final String? accent;
  final WonkyDensity density;

  WonkyThemeConfig copyWith({
    String? accent,
    bool clearAccent = false,
    WonkyDensity? density,
  }) => WonkyThemeConfig(
    accent: clearAccent ? null : accent ?? this.accent,
    density: density ?? this.density,
  );

  @override
  bool operator ==(Object other) =>
      other is WonkyThemeConfig &&
      other.accent == accent &&
      other.density == density;

  @override
  int get hashCode => Object.hash(accent, density);
}

/// Builds the app's `ShadThemeData` (suite 02 §1).
///
/// Themes are **memoized** per (brightness, accent, density): `ShadThemeData`
/// inequality makes `ShadApp` lerp for 200 ms on every rebuild, so callers
/// must always obtain themes through this class instead of building or
/// `copyWith`-ing them.
abstract final class WonkyTheme {
  static final Map<(Brightness, WonkyThemeConfig), ShadThemeData> _cache = {};

  /// Accent names users can pick (shadcn accents).
  static List<String> get accents => ShadAccentScheme.all.keys.toList();

  /// The light theme for [config].
  static ShadThemeData light([
    WonkyThemeConfig config = const WonkyThemeConfig(),
  ]) => of(Brightness.light, config);

  /// The dark theme for [config].
  static ShadThemeData dark([
    WonkyThemeConfig config = const WonkyThemeConfig(),
  ]) => of(Brightness.dark, config);

  /// The (cached) theme for [brightness] and [config].
  static ShadThemeData of(Brightness brightness, WonkyThemeConfig config) =>
      _cache.putIfAbsent((
        brightness,
        config,
      ), () => _build(brightness, config));

  /// The monospace font family (formulas, code, shortcuts).
  static const monoFamily = WonkyFonts.geistMono;

  static ShadThemeData _build(Brightness brightness, WonkyThemeConfig config) {
    final tokens = WonkyPalette.tokens(brightness);
    ShadColorScheme scheme = brightness == Brightness.light
        ? ShadZincColorScheme.light(
            // shad's red-600 (#e7000b) under #fafafa is 4.01:1; red-700
            // reaches WCAG AA for text on destructive buttons (specs/11 §3).
            destructive: const Color(0xffc10007),
            custom: tokens,
          )
        : ShadZincColorScheme.dark(custom: tokens);
    final accent = config.accent;
    if (accent != null && ShadAccentScheme.all.containsKey(accent)) {
      scheme = scheme.applyAccentScheme(
        ShadAccentScheme.fromName(accent, brightness: brightness),
      );
    }
    final compact = config.density == WonkyDensity.compact;
    return ShadThemeData(
      brightness: brightness,
      colorScheme: scheme,
      style: ShadStyleTokens.vega,
      spacing: ShadSpacing(step: compact ? 3.5 : 4),
      textTheme: ShadTextTheme(family: WonkyFonts.geist),
    );
  }

  /// Clears the cache (tests only).
  @visibleForTesting
  static void debugClearCache() => _cache.clear();
}

/// Per-widget sizes and overrides for the `wonky_ui` widgets (the "theme
/// slot" of suite 02 §4). Provide with [WonkyThemeScope].
@immutable
class WonkyThemeExtension {
  const WonkyThemeExtension({
    this.density = WonkyDensity.comfortable,
    this.reduceMotion = false,
    this.toolbarHeight,
    this.toolbarButtonSize = 28,
    this.statusBarHeight = 24,
    this.titleRowHeight = 48,
    this.menubarHeight = 32,
    this.maxTitleWidth = 400,
    this.presenceMaxAvatars = 4,
    this.cursorFlagFadeDelay = const Duration(seconds: 3),
    this.scrollbarThickness = 8,
  });

  final WonkyDensity density;

  /// Disables non-essential motion (popover/panel animations, shimmer).
  final bool reduceMotion;

  /// Toolbar height; defaults to 40 (36 when compact).
  final double? toolbarHeight;
  final double toolbarButtonSize;
  final double statusBarHeight;
  final double titleRowHeight;
  final double menubarHeight;
  final double maxTitleWidth;
  final int presenceMaxAvatars;
  final Duration cursorFlagFadeDelay;
  final double scrollbarThickness;

  bool get isCompact => density == WonkyDensity.compact;

  double get effectiveToolbarHeight => toolbarHeight ?? (isCompact ? 36 : 40);

  /// Standard short UI animation (popovers, panels): 0 when motion is reduced.
  Duration motion(BuildContext context, [int millis = 180]) =>
      reduceMotion || MediaQuery.maybeDisableAnimationsOf(context) == true
      ? Duration.zero
      : Duration(milliseconds: millis);

  WonkyThemeExtension copyWith({WonkyDensity? density, bool? reduceMotion}) =>
      WonkyThemeExtension(
        density: density ?? this.density,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        toolbarHeight: toolbarHeight,
        toolbarButtonSize: toolbarButtonSize,
        statusBarHeight: statusBarHeight,
        titleRowHeight: titleRowHeight,
        menubarHeight: menubarHeight,
        maxTitleWidth: maxTitleWidth,
        presenceMaxAvatars: presenceMaxAvatars,
        cursorFlagFadeDelay: cursorFlagFadeDelay,
        scrollbarThickness: scrollbarThickness,
      );

  @override
  bool operator ==(Object other) =>
      other is WonkyThemeExtension &&
      other.density == density &&
      other.reduceMotion == reduceMotion &&
      other.toolbarHeight == toolbarHeight &&
      other.toolbarButtonSize == toolbarButtonSize &&
      other.statusBarHeight == statusBarHeight &&
      other.titleRowHeight == titleRowHeight &&
      other.menubarHeight == menubarHeight &&
      other.maxTitleWidth == maxTitleWidth &&
      other.presenceMaxAvatars == presenceMaxAvatars &&
      other.cursorFlagFadeDelay == cursorFlagFadeDelay &&
      other.scrollbarThickness == scrollbarThickness;

  @override
  int get hashCode => Object.hash(
    density,
    reduceMotion,
    toolbarHeight,
    toolbarButtonSize,
    statusBarHeight,
    titleRowHeight,
    menubarHeight,
    maxTitleWidth,
    presenceMaxAvatars,
    cursorFlagFadeDelay,
    scrollbarThickness,
  );
}

/// Provides [WonkyThemeExtension] to the `wonky_ui` widgets.
class WonkyThemeScope extends InheritedWidget {
  const WonkyThemeScope({super.key, required this.data, required super.child});

  final WonkyThemeExtension data;

  /// The nearest extension, or the defaults.
  static WonkyThemeExtension of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WonkyThemeScope>()?.data ??
      const WonkyThemeExtension();

  @override
  bool updateShouldNotify(WonkyThemeScope oldWidget) => oldWidget.data != data;
}
