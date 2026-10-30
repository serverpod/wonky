import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wonky_ui/wonky_ui.dart';

/// The asset folder of the bundled static faces: `wonky_fonts`' package
/// assets, shared with the other apps (the server keeps a copy in
/// `wonky_server/web/fonts/`; `bundled_fonts_test` checks they match).
const fontAssetDir = 'packages/wonky_fonts/fonts';

/// Cell fonts (06 §6.1, `CellFontRegistry`): the families the font picker
/// offers, how any stored family name is rendered on screen and on-demand
/// loading of the bundled faces.
///
/// Bundled: Inter, Geist and Geist Mono (shipped with `shad`) and the static
/// faces of Roboto, Roboto Mono (Apache 2.0), Open Sans, Lato, Source Sans 3,
/// Nunito, Montserrat, EB Garamond, Merriweather and JetBrains Mono (OFL)
/// from `wonky_fonts` ([fontAssetDir]: plain package assets, so web doesn't
/// download them at start-up; [ensureLoaded] registers a family the first
/// time a cell uses it). Source Sans 3 is shipped as `WonkySansThree-*.ttf`: static
/// instances of the variable font, renamed because "Source" is a Reserved
/// Font Name. Every other name (imports, pastes) is stored unchanged and
/// rendered by category: serif → EB Garamond, mono (Courier Prime, Courier
/// New …) → JetBrains Mono, geometric/rounded sans (Poppins, Raleway …) →
/// Lato, other sans → Inter.
abstract final class CellFonts {
  static const inter = 'Inter';
  static const geist = 'Geist';
  static const geistMono = 'Geist Mono';
  static const openSans = 'Open Sans';
  static const ebGaramond = 'EB Garamond';
  static const jetBrainsMono = 'JetBrains Mono';
  static const roboto = 'Roboto';
  static const robotoMono = 'Roboto Mono';
  static const lato = 'Lato';
  static const sourceSans3 = 'Source Sans 3';
  static const nunito = 'Nunito';
  static const montserrat = 'Montserrat';
  static const merriweather = 'Merriweather';

  /// The bundled families in picker order.
  static const bundled = [
    inter,
    roboto,
    openSans,
    lato,
    sourceSans3,
    nunito,
    montserrat,
    geist,
    ebGaramond,
    merriweather,
    geistMono,
    jetBrainsMono,
    robotoMono,
  ];

  static const _assetFamilies = {
    openSans,
    ebGaramond,
    jetBrainsMono,
    roboto,
    robotoMono,
    lato,
    sourceSans3,
    nunito,
    montserrat,
    merriweather,
  };

  static const _faces = {
    openSans: [
      'OpenSans-Regular.ttf',
      'OpenSans-Italic.ttf',
      'OpenSans-SemiBold.ttf',
      'OpenSans-Bold.ttf',
      'OpenSans-BoldItalic.ttf',
    ],
    ebGaramond: [
      'EBGaramond-Regular.ttf',
      'EBGaramond-Italic.ttf',
      'EBGaramond-SemiBold.ttf',
      'EBGaramond-Bold.ttf',
      'EBGaramond-BoldItalic.ttf',
    ],
    jetBrainsMono: [
      'JetBrainsMono-Regular.ttf',
      'JetBrainsMono-Italic.ttf',
      'JetBrainsMono-Bold.ttf',
      'JetBrainsMono-BoldItalic.ttf',
    ],
    roboto: [
      'Roboto-Regular.ttf',
      'Roboto-Italic.ttf',
      'Roboto-Bold.ttf',
      'Roboto-BoldItalic.ttf',
    ],
    // No italic faces: the engine slants the upright ones.
    robotoMono: ['RobotoMono-Regular.ttf', 'RobotoMono-Bold.ttf'],
    lato: [
      'Lato-Regular.ttf',
      'Lato-Italic.ttf',
      'Lato-Bold.ttf',
      'Lato-BoldItalic.ttf',
    ],
    sourceSans3: [
      'WonkySansThree-Regular.ttf',
      'WonkySansThree-Italic.ttf',
      'WonkySansThree-Bold.ttf',
      'WonkySansThree-BoldItalic.ttf',
    ],
    nunito: [
      'Nunito-Regular.ttf',
      'Nunito-Italic.ttf',
      'Nunito-Bold.ttf',
      'Nunito-BoldItalic.ttf',
    ],
    montserrat: [
      'Montserrat-Regular.ttf',
      'Montserrat-Italic.ttf',
      'Montserrat-Bold.ttf',
      'Montserrat-BoldItalic.ttf',
    ],
    merriweather: [
      'Merriweather-Regular.ttf',
      'Merriweather-Italic.ttf',
      'Merriweather-Bold.ttf',
      'Merriweather-BoldItalic.ttf',
    ],
  };

  /// The regular face of each asset family (font menu previews, PDF).
  static String? regularFace(String family) => _faces[family]?.first;

  /// Geometric and rounded sans families shown with [lato].
  static const _geometric = {
    'nunito sans',
    'poppins',
    'raleway',
    'quicksand',
    'work sans',
    'century gothic',
    'futura',
    'avenir',
    'gill sans',
    'trebuchet ms',
  };

  static const _serif = {
    'lora',
    'playfair display',
    'noto serif',
    'tinos',
    'caladea',
    'gelasio',
    'times new roman',
    'times',
    'georgia',
    'cambria',
    'garamond',
    'eb garamond',
    'book antiqua',
    'palatino',
    'palatino linotype',
  };

  static const _mono = {
    'roboto mono',
    'source code pro',
    'courier prime',
    'cousine',
    'courier new',
    'courier',
    'consolas',
    'menlo',
    'monaco',
    'jetbrains mono',
    'geist mono',
    'lucida console',
  };

  static final _byLowerName = {for (final f in bundled) f.toLowerCase(): f};

  /// Whether [family] renders with its own face.
  static bool isBundled(String family) => bundled.contains(family);

  /// The bundled family [family] is displayed with (itself when bundled).
  static String displayFamily(String family) {
    if (isBundled(family)) return family;
    final l = family.toLowerCase().trim();
    final named = _byLowerName[l];
    if (named != null) return named;
    if (l == 'source sans pro') return sourceSans3;
    if (_mono.contains(l) || l.contains('mono') || l.contains('courier')) {
      return jetBrainsMono;
    }
    if (_serif.contains(l) || (l.contains('serif') && !l.contains('sans'))) {
      return ebGaramond;
    }
    if (_geometric.contains(l)) return lato;
    if (l.startsWith('roboto')) return roboto;
    return inter;
  }

  /// The Flutter font family used to paint [family] (loads it on demand).
  static String screenFamily(String family) {
    final shown = displayFamily(family);
    switch (shown) {
      case inter:
        return WonkyFonts.inter;
      case geist:
        return WonkyFonts.geist;
      case geistMono:
        return WonkyFonts.geistMono;
    }
    if (!_loaded.contains(shown)) unawaited(ensureLoaded(shown));
    return shown;
  }

  static final List<String> _recent = [];

  /// Fonts picked recently in this session (most recent first, ≤ 5).
  static List<String> get recent => List.unmodifiable(_recent);

  /// Notes that [family] was picked.
  static void noteRecent(String family) {
    _recent
      ..remove(family)
      ..insert(0, family);
    if (_recent.length > 5) _recent.removeLast();
  }

  /// Fallback families for glyphs missing in the cell font.
  static const fallback = [WonkyFonts.inter, WonkyFonts.geist];

  static final Set<String> _loaded = {};
  static final Map<String, Future<void>> _loading = {};

  /// Bumped whenever a family finished loading (re-layout cell text).
  static final ValueNotifier<int> generation = ValueNotifier(0);

  /// Registers the faces of a bundled asset family with the engine.
  static Future<void> ensureLoaded(String family) {
    if (!_assetFamilies.contains(family)) return Future.value();
    return _loading.putIfAbsent(family, () async {
      try {
        final loader = FontLoader(family);
        for (final f in _faces[family]!) {
          loader.addFont(rootBundle.load('$fontAssetDir/$f'));
        }
        await loader.load();
        _loaded.add(family);
        generation.value++;
      } catch (e) {
        debugPrint('Loading cell font $family failed: $e');
      }
    });
  }
}
