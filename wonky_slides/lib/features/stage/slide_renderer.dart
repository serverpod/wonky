import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:wonky_app/fonts.dart';
import 'package:wonky_slides_core/charts.dart' show SlideChartLayout;
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/themes.dart';

import '../elements/chart/chart_text.dart';
import '../elements/icon/lucide_icon_source.dart';
import '../thumbnails/slide_thumbnail_cache.dart';
import 'flutter_text_layout_engine.dart';
import 'scene_painter.dart';
import 'slide_image_cache.dart';

/// Everything that turns an open deck's rows into paintable scenes (02
/// §11): the `SlideResolver`, the `SlideSceneBuilder`, the Flutter text
/// layout engine, decoded images, on-demand fonts and the thumbnail cache.
/// One per open deck; the canvas, navigator, grid view and present mode
/// share it.
///
/// Listeners are notified when the deck changes and when bundled fonts
/// finish loading or the engine's fonts change (scenes laid out with
/// fallback metrics, or before an emoji/symbol fallback font arrived, are
/// rebuilt, 05 §3.3). Image loads notify [images] instead.
class SlideRenderer extends ChangeNotifier {
  SlideRenderer({
    required this.model,
    SlideImageResolver? images,
    AssetFontRegistry? fonts,
    FlutterTextLayoutEngine? textLayout,
    SlideIconSource? icons,
    ChartSceneSource? charts,
    this.code,
    SlideThumbnailCache? thumbnails,
  }) : fonts = fonts ?? AssetFontRegistry.instance,
       images = SlideImageCache.shared(images ?? MemorySlideImageResolver()),
       thumbnails = thumbnails ?? SlideThumbnailCache(),
       icons = icons ?? LucideIconSource.instance,
       charts = charts ?? SlidesChartText.layout() {
    this.textLayout =
        textLayout ??
        FlutterTextLayoutEngine(fontGeneration: this.fonts.generation);
    resolver = SlideResolver(model);
    model.addListener(_onBatch);
    this.fonts
      ..watchEngineFonts()
      ..generation.addListener(_onFonts);
  }

  /// The deck.
  final DeckModel model;

  /// Font registry (bundled families load on demand).
  final AssetFontRegistry fonts;

  /// Decoded images (shared by every renderer over the same resolver).
  final SlideImageCache images;

  /// Recorded thumbnails.
  final SlideThumbnailCache thumbnails;

  /// Icon glyphs (default: the Lucide icon fonts, SL-14).
  final SlideIconSource icons;

  /// Chart scenes (SL-27/SL-32; default: a `SlideChartLayout` over the
  /// shared chart text measurer, `SlidesChartText`).
  final ChartSceneSource charts;

  /// Code scenes (SL-26; null = the core's basic layout).
  final CodeSceneSource? code;

  /// The text layout engine.
  late final FlutterTextLayoutEngine textLayout;

  /// The slide resolver.
  late final SlideResolver resolver;

  /// The scene builder (caches element nodes).
  final SlideSceneBuilder builder = SlideSceneBuilder();

  final Map<String, (String, SlideScene)> _memo = {};
  bool _disposed = false;

  /// The render revision of [slideId] (changes when anything it draws from
  /// changes, incl. fonts).
  String revision(String slideId) =>
      '${model.indexes.revision(slideId)}/${fonts.generation.value}';

  /// The scene of [slideId], or null when the slide doesn't exist.
  SlideScene? scene(
    String slideId, {
    ScenePurpose purpose = ScenePurpose.edit,
    bool editing = false,
    SlideAppearance? appearance,
    Map<String, int> codeStates = const {},
    Map<String, int> codeSteps = const {},
  }) {
    final key =
        '$slideId|${purpose.name}|$editing|${appearance?.name}|'
        '${codeStates.entries.map((e) => '${e.key}=${e.value}').join(',')}|'
        '${codeSteps.entries.map((e) => '${e.key}=${e.value}').join(',')}';
    final rev = revision(slideId);
    // LRU: a hit moves to the end.
    final hit = _memo.remove(key);
    if (hit != null && hit.$1 == rev) return (_memo[key] = hit).$2;
    final slide = resolver.resolve(slideId, appearance: appearance);
    if (slide == null) return null;
    final scene = builder.build(
      slide,
      SceneContext(
        theme: slide.theme,
        textLayout: textLayout,
        editing: editing,
        deck: model,
        purpose: purpose,
        icons: icons,
        charts: charts,
        code: code,
        codeStates: codeStates,
        codeSteps: codeSteps,
        generation: fonts.generation.value,
      ),
    );
    _memo[key] = (rev, scene);
    if (_memo.length > 256) _memo.remove(_memo.keys.first);
    ensureFonts(scene);
    return scene;
  }

  /// Starts loading the bundled families [scene] draws with.
  void ensureFonts(SlideScene scene) {
    for (final f in SlideScenePainter.fontFamiliesOf(scene)) {
      if (!fonts.isLoaded(f)) fonts.ensure(f);
    }
  }

  /// The thumbnail picture of [slideId] at [width] logical px (edit frame
  /// with the last code state, no prompts; 06 §9.6), or null when the
  /// slide doesn't exist. One cache entry per slide, width and appearance,
  /// re-recorded when the render revision changes.
  SlideThumbnailPicture? thumbnail(
    String slideId, {
    required double width,
    SlideAppearance? appearance,
  }) {
    final key = '$slideId|${appearance?.name}|$width';
    return thumbnails.picture(
      key,
      () => scene(
        slideId,
        purpose: ScenePurpose.thumbnail,
        appearance: appearance,
      ),
      width: width,
      revision: revision(slideId),
      images: images,
    );
  }

  /// The slide size (su).
  Size get slideSize {
    final d = model.deck;
    return Size(d?.width ?? 1920, d?.height ?? 1080);
  }

  void _onBatch(DeckChangeBatch batch) {
    if (!_disposed) notifyListeners();
  }

  void _onFonts() {
    if (_disposed) return;
    textLayout.clear();
    // Charts measured with a fallback font are laid out again.
    SlidesChartText.measurer.clear();
    final c = charts;
    if (c is SlideChartLayout) c.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    model.removeListener(_onBatch);
    fonts.generation.removeListener(_onFonts);
    images.release();
    thumbnails.clear();
    super.dispose();
  }
}
