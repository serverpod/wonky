import 'dart:convert';

/// `Deck.presentJson` (Slides 10 §3, A-10-1): the deck's presentation
/// options with defaults. Unknown or invalid values read as the defaults;
/// [toJson] writes only the known keys (`v: 1`).
class PresentSettings {
  const PresentSettings({
    this.mode = 'normal',
    this.useRehearsedTimings = false,
    this.advanceDuringBuild = 'finish',
    this.endBehavior = 'endScreen',
    this.wheelAdvance = true,
    this.letterboxColor = 0xff000000,
    this.reduceMotion = false,
    this.keepPresentingOutsideFullscreen = false,
    this.kioskRestartAfterIdleSec = 120,
    this.kioskExitGesture = 'holdEsc',
    this.laserColor = 'red',
    this.showCaptionsByDefault = false,
  });

  static const defaults = PresentSettings();

  static const modes = ['normal', 'loop', 'kiosk'];
  static const advanceModes = ['finish', 'skip'];
  static const endBehaviors = ['endScreen', 'exit', 'loop'];
  static const laserColors = ['red', 'green', 'blue', 'amber'];
  static const exitGestures = ['holdEsc', 'esc'];

  /// `normal`, `loop` or `kiosk` (§9; kiosk timers come with SL-29).
  final String mode;
  final bool useRehearsedTimings;

  /// `finish` (a *Next* during a running build finishes it) or `skip`.
  final String advanceDuringBuild;

  /// `endScreen`, `exit` or `loop` (§1.5).
  final String endBehavior;
  final bool wheelAdvance;

  /// ARGB of the area around the slide (§1.4).
  final int letterboxColor;
  final bool reduceMotion;
  final bool keepPresentingOutsideFullscreen;
  final int kioskRestartAfterIdleSec;
  final String kioskExitGesture;

  /// `red`, `green`, `blue` or `amber` (§4.2).
  final String laserColor;
  final bool showCaptionsByDefault;

  /// Whether the deck loops after its last slide.
  bool get loops => mode != 'normal' || endBehavior == 'loop';

  /// The settings of `Deck.presentJson` (null or invalid = defaults).
  factory PresentSettings.parse(String? json) {
    if (json == null || json.isEmpty) return defaults;
    try {
      final v = jsonDecode(json);
      return v is Map
          ? PresentSettings.fromJson(v.cast<String, Object?>())
          : defaults;
    } on FormatException {
      return defaults;
    }
  }

  factory PresentSettings.fromJson(Map<String, Object?> j) {
    String pick(String key, List<String> allowed, String fallback) {
      final v = j[key];
      return v is String && allowed.contains(v) ? v : fallback;
    }

    bool flag(String key, bool fallback) {
      final v = j[key];
      return v is bool ? v : fallback;
    }

    final kiosk = j['kiosk'];
    final k = kiosk is Map
        ? kiosk.cast<String, Object?>()
        : const <String, Object?>{};
    final idle = k['restartAfterIdleSec'];
    return PresentSettings(
      mode: pick('mode', modes, defaults.mode),
      useRehearsedTimings: flag('useRehearsedTimings', false),
      advanceDuringBuild: pick(
        'advanceDuringBuild',
        advanceModes,
        defaults.advanceDuringBuild,
      ),
      endBehavior: pick('endBehavior', endBehaviors, defaults.endBehavior),
      wheelAdvance: flag('wheelAdvance', true),
      letterboxColor:
          parseColor(j['letterboxColor']) ?? defaults.letterboxColor,
      reduceMotion: flag('reduceMotion', false),
      keepPresentingOutsideFullscreen: flag(
        'keepPresentingOutsideFullscreen',
        false,
      ),
      kioskRestartAfterIdleSec: idle is num && idle >= 5 && idle <= 3600
          ? idle.toInt()
          : defaults.kioskRestartAfterIdleSec,
      kioskExitGesture:
          k['exitGesture'] is String && exitGestures.contains(k['exitGesture'])
          ? k['exitGesture']! as String
          : defaults.kioskExitGesture,
      laserColor: pick('laserColor', laserColors, defaults.laserColor),
      showCaptionsByDefault: flag('showCaptionsByDefault', false),
    );
  }

  /// `#rrggbb` → ARGB, or null.
  static int? parseColor(Object? v) {
    if (v is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) return null;
    return 0xff000000 | int.parse(v.substring(1), radix: 16);
  }

  static String colorHex(int argb) =>
      '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}';

  Map<String, Object?> toJson() => {
    'v': 1,
    'mode': mode,
    'useRehearsedTimings': useRehearsedTimings,
    'advanceDuringBuild': advanceDuringBuild,
    'endBehavior': endBehavior,
    'wheelAdvance': wheelAdvance,
    'letterboxColor': colorHex(letterboxColor),
    'reduceMotion': reduceMotion,
    'keepPresentingOutsideFullscreen': keepPresentingOutsideFullscreen,
    'kiosk': {
      'restartAfterIdleSec': kioskRestartAfterIdleSec,
      'exitGesture': kioskExitGesture,
    },
    'laserColor': laserColor,
    'showCaptionsByDefault': showCaptionsByDefault,
  };

  /// Applies a `slides.deck.setPresentSettings {patch}` patch (top-level
  /// keys of [toJson]; `kiosk` merges). Throws [FormatException] for
  /// unknown keys or invalid values.
  PresentSettings patched(Map<String, Object?> patch) {
    final base = toJson();
    for (final e in patch.entries) {
      if (e.key == 'v' || !base.containsKey(e.key)) {
        throw FormatException('Unknown presentation setting "${e.key}"');
      }
      if (e.key == 'kiosk') {
        final v = e.value;
        if (v is! Map) throw const FormatException('kiosk must be an object');
        base['kiosk'] = {...(base['kiosk']! as Map), ...v};
      } else {
        base[e.key] = e.value;
      }
    }
    final next = PresentSettings.fromJson(base);
    final check = next.toJson();
    for (final e in patch.entries) {
      if (e.key == 'kiosk') continue;
      if (jsonEncode(check[e.key]).toLowerCase() !=
          jsonEncode(e.value).toLowerCase()) {
        throw FormatException('Invalid value for "${e.key}"');
      }
    }
    return next;
  }

  /// ARGB of [laserColor] (§4.2).
  int get laserArgb => switch (laserColor) {
    'green' => 0xff22c55e,
    'blue' => 0xff3b82f6,
    'amber' => 0xfff59e0b,
    _ => 0xffef4444,
  };
}
