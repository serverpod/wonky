import 'dart:convert';

import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

/// Two blank slides A → B for Magic Move tests: elements are added to a
/// slide with an optional shared match key (the duplicate-slide workflow).
final class MagicMoveFixture {
  MagicMoveFixture() {
    a = b.slide(layoutKey: 'blank');
    bSlide = b.slide(layoutKey: 'blank');
  }

  final b = DeckBuilder();
  late final String a;
  late final String bSlide;

  /// Adds a shape to [slide].
  String shape(
    String slide, {
    String? key,
    double x = 100,
    double y = 100,
    double w = 400,
    double h = 200,
    double? rotation,
    String geometry = 'rect',
    String? fill,
    String? text,
    String? name,
  }) => b.element(
    slide,
    ElementKind.shape,
    x: x,
    y: y,
    width: w,
    height: h,
    rotation: rotation,
    columns: {
      ElementCols.dataJson: jsonEncode({'v': 1, 'geometry': geometry}),
      if (fill != null)
        ElementCols.fillJson: jsonEncode({
          'v': 1,
          'type': 'solid',
          'color': fill,
        }),
      if (text != null) SlidesCols.text: deltaOf(text),
      ElementCols.matchKey: ?key,
      SlidesCols.name: ?name,
    },
  );

  /// Adds a text box to [slide].
  String text(
    String slide,
    String text, {
    String? key,
    double x = 100,
    double y = 600,
    double w = 1200,
    double h = 200,
  }) => b.element(
    slide,
    ElementKind.text,
    x: x,
    y: y,
    width: w,
    height: h,
    columns: {SlidesCols.text: deltaOf(text), ElementCols.matchKey: ?key},
  );

  /// Adds an element of [kind] with [data] to [slide].
  String element(
    String slide,
    ElementKind kind, {
    String? key,
    Map<String, Object?> data = const {},
    double x = 100,
    double y = 100,
    double w = 400,
    double h = 200,
    String? parentId,
    String? id,
  }) => b.element(
    slide,
    kind,
    x: x,
    y: y,
    width: w,
    height: h,
    parentId: parentId,
    id: id,
    columns: {
      ElementCols.dataJson: jsonEncode({'v': 1, ...data}),
      ElementCols.matchKey: ?key,
    },
  );

  DeckModel? _model;
  DeckModel get model => _model ??= b.build();

  /// Sets [slide]'s `transitionJson` (after the model is built).
  void setTransition(String slide, Map<String, Object?> transition) =>
      model.applyChanges([
        RowChange.update(
          SlidesTables.slide,
          slide,
          {SlidesCols.transitionJson: null},
          {SlidesCols.transitionJson: jsonEncode(transition)},
        ),
      ], silent: true);

  MagicMoveSlide slideA({SlideFrame frame = SlideFrame.edit}) =>
      MagicMoveSlide.fromDeck(model, a, frame: frame);

  MagicMoveSlide slideB({SlideFrame frame = SlideFrame.edit}) =>
      MagicMoveSlide.fromDeck(model, bSlide, frame: frame);

  /// The plan A → B with Magic Move [options] (linear easing by default so
  /// progress = time).
  MagicMovePlan plan({
    Map<String, Object?> options = const {},
    String easing = 'linear',
    int durationMs = 1000,
    bool reverse = false,
  }) => MagicMovePlan.compile(
    slideA(),
    slideB(),
    spec: magicMove(options: options, easing: easing, durationMs: durationMs),
    reverse: reverse,
  );

  static TransitionSpec magicMove({
    Map<String, Object?> options = const {},
    String easing = 'linear',
    int durationMs = 1000,
  }) => TransitionSpec.fromJson({
    'type': 'magicMove',
    'durationMs': durationMs,
    'easing': easing,
    'magicMove': options,
  }).value;
}

/// Where [m] puts slide point ([x], [y]).
(double, double) mapPoint(Matrix4 m, double x, double y) {
  final v = m.perspectiveTransform(Vector3(x, y, 0));
  return (v.x, v.y);
}
