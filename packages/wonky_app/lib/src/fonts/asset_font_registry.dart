/// The shared Flutter loader of the bundled fonts (Slides 05 §3.1, §3.3;
/// Write 06 §8.3): faces are package assets of `wonky_fonts`
/// (`packages/wonky_fonts/fonts/…`), registered with the engine the first
/// time a family is needed, never at start-up.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter/services.dart';
import 'package:wonky_fonts/wonky_fonts.dart';

/// Registers bundled font families with the Flutter engine on demand.
///
/// Every face of a family is added to one `FontLoader` under the family's
/// name, so the engine picks weight and style from the faces themselves.
/// Canvas code renders with fallback metrics until [ensure] completes and
/// re-lays out when [generation] changes (05 §3.3).
class AssetFontRegistry {
  /// Creates a registry loading from [bundle] (default `rootBundle`).
  /// [register] loads the faces into the engine (tests inject a fake).
  AssetFontRegistry({
    AssetBundle? bundle,
    Future<void> Function(String family, List<Future<ByteData>> faces)?
    register,
  }) : _bundle = bundle ?? rootBundle,
       _register = register ?? _engineRegister;

  /// The app-wide registry.
  static final AssetFontRegistry instance = AssetFontRegistry();

  final AssetBundle _bundle;
  final Future<void> Function(String, List<Future<ByteData>>) _register;
  final Map<String, Future<bool>> _loading = {};
  final Set<String> _loaded = {};

  /// Bumped every time a family finished loading — and, once
  /// [watchEngineFonts] ran, whenever the engine's fonts change.
  final ValueNotifier<int> generation = ValueNotifier(0);

  bool _watchingEngine = false;

  /// Also bumps [generation] when the engine's fonts change: on the web
  /// the engine downloads fallback fonts (emoji, arrows and other symbols
  /// the deck's family lacks) after the first layout that needs them, and
  /// layouts cached before that kept drawing empty boxes (SL-45). Safe to
  /// call repeatedly; needs the Flutter bindings.
  void watchEngineFonts() {
    if (_watchingEngine) return;
    _watchingEngine = true;
    PaintingBinding.instance.systemFonts.addListener(() => generation.value++);
  }

  static Future<void> _engineRegister(
    String family,
    List<Future<ByteData>> faces,
  ) async {
    final loader = FontLoader(family);
    for (final f in faces) {
      loader.addFont(f);
    }
    await loader.load();
  }

  /// Whether [family] is registered with the engine.
  bool isLoaded(String family) => _loaded.contains(family);

  /// Registers every bundled face of [family]. Completes with `false` when
  /// the family is not bundled or loading failed. [weight] and [italic]
  /// are accepted for the 05 §3.3 call shape; all faces of the family load
  /// together. Safe to call repeatedly.
  Future<bool> ensure(String family, {int weight = 400, bool italic = false}) {
    final faces = BundledFonts.facesOf(family);
    if (faces.isEmpty) return Future.value(false);
    return _loading.putIfAbsent(family, () async {
      try {
        await _register(family, [
          for (final f in faces) _bundle.load(f.assetKey),
        ]);
        _loaded.add(family);
        generation.value++;
        return true;
      } catch (e) {
        debugPrint('Loading font $family failed: $e');
        unawaited(_loading.remove(family));
        return false;
      }
    });
  }

  /// [ensure] for several families (deck preloading before presenting).
  Future<void> ensureAll(Iterable<String> families) =>
      Future.wait([for (final f in families.toSet()) ensure(f)]);

  /// Adds the licenses of the bundled families to the app's license page.
  static void registerLicenses({AssetBundle? bundle}) {
    if (_licensesRegistered) return;
    _licensesRegistered = true;
    final b = bundle ?? rootBundle;
    LicenseRegistry.addLicense(() async* {
      final byFile = <String, List<String>>{};
      for (final MapEntry(:key, :value) in BundledFonts.licenseFiles.entries) {
        (byFile[value] ??= []).add(key);
      }
      for (final MapEntry(:key, :value) in byFile.entries) {
        final text = await b.loadString(BundledFonts.assetKey(key));
        yield LicenseEntryWithLineBreaks(value, text);
      }
    });
  }

  static bool _licensesRegistered = false;
}

/// A [FontProvider] over the bundled TTF assets (client-side PDF export).
/// Unbundled families are substituted by category ([fallbackFamilies]);
/// [fallbacksFor] returns Open Sans (broad European coverage).
class BundledAssetFontProvider implements FontProvider {
  /// Creates a provider loading from [bundle] (default `rootBundle`).
  BundledAssetFontProvider({
    AssetBundle? bundle,
    this.fallbackFamilies = defaultFallbackFamilies,
  }) : _bundle = bundle ?? rootBundle;

  /// The default substitutes per category.
  static const Map<FontCategory, String> defaultFallbackFamilies = {
    FontCategory.sans: BundledFonts.openSans,
    FontCategory.serif: BundledFonts.ebGaramond,
    FontCategory.mono: BundledFonts.jetBrainsMono,
  };

  /// Substitutes per category for families that are not bundled.
  final Map<FontCategory, String> fallbackFamilies;

  final AssetBundle _bundle;
  final Map<String, Future<Uint8List>> _bytes = {};

  Future<Uint8List> _read(String asset) => _bytes.putIfAbsent(asset, () async {
    final data = await _bundle.load(asset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  });

  /// The bundled family used for [family].
  String bundledFamilyFor(String family) {
    if (BundledFonts.isBundled(family)) return family;
    final category = FontRegistry.lookup(family)?.category ?? FontCategory.sans;
    return fallbackFamilies[category] ?? BundledFonts.openSans;
  }

  @override
  Future<FontFace> load(
    String family, {
    int weight = 400,
    bool italic = false,
  }) async {
    final face = BundledFonts.closestFace(
      bundledFamilyFor(family),
      weight: weight,
      italic: italic,
    )!;
    return FontFace(
      family: family,
      weight: face.weight,
      italic: face.italic,
      bytes: await _read(face.assetKey),
    );
  }

  @override
  Future<List<FontFace>> fallbacksFor(String text) async {
    final face = BundledFonts.closestFace(BundledFonts.openSans)!;
    return [
      FontFace(
        family: face.family,
        weight: face.weight,
        italic: false,
        bytes: await _read(face.assetKey),
      ),
    ];
  }
}
