import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:wonky_app/fonts.dart';
import 'package:wonky_slides/features/stage/slide_renderer.dart';
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart' show Base62Uuid;

/// A 2 × 2 red PNG.
final Uint8List redPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGP4z8AARAwQCgAf'
  '7gP9i18U1AAAAABJRU5ErkJggg==',
);

/// An asset bundle that serves empty font files.
class EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData(0);
}

/// A font registry that records the families it was asked for and never
/// touches the engine.
class RecordingFontRegistry extends AssetFontRegistry {
  RecordingFontRegistry()
    : super(bundle: EmptyBundle(), register: (family, faces) async {});
}

/// One slide with helpers for every element kind, and a renderer over it.
class StageFixture {
  StageFixture({SlideAppearance appearance = SlideAppearance.light}) {
    slideId = b.slide(layoutKey: 'blank');
    _appearance = appearance;
  }

  final DeckBuilder b = DeckBuilder();
  late final String slideId;
  late final SlideAppearance _appearance;
  final MemorySlideImageResolver images = MemorySlideImageResolver({
    'wonky-file://red': redPng,
  });

  String shape({
    double x = 100,
    double y = 100,
    double w = 400,
    double h = 200,
    String geometry = 'rect',
    String? text,
    String? fillJson,
  }) => b.element(
    slideId,
    ElementKind.shape,
    x: x,
    y: y,
    width: w,
    height: h,
    columns: {
      ElementCols.dataJson: jsonEncode({'v': 1, 'geometry': geometry}),
      if (text != null) SlidesCols.text: deltaOf(text),
      ElementCols.fillJson: ?fillJson,
    },
  );

  String text(String t, {double x = 100, double y = 600, double w = 800}) =>
      b.textBox(slideId, t, x: x, y: y, width: w);

  String line({String endArrow = 'triangle', String color = '#112233'}) =>
      b.element(
        slideId,
        ElementKind.line,
        x: 100,
        y: 900,
        width: 600,
        height: 0,
        columns: {
          ElementCols.dataJson: jsonEncode({
            'v': 1,
            'routing': 'straight',
            'start': {'x': 0, 'y': 0},
            'end': {'x': 1, 'y': 0},
          }),
          ElementCols.strokeJson: jsonEncode({
            'v': 1,
            'color': color,
            'width': 6,
            'endArrow': endArrow,
          }),
        },
      );

  String connector(String from, String to) => b.element(
    slideId,
    ElementKind.line,
    x: 0,
    y: 0,
    width: 10,
    height: 10,
    columns: {
      ElementCols.dataJson: jsonEncode({
        'v': 1,
        'routing': 'elbow',
        'start': {
          'x': 0,
          'y': 0,
          'connect': {'elementId': Base62Uuid.encode(from), 'site': 'right'},
        },
        'end': {
          'x': 1,
          'y': 1,
          'connect': {'elementId': Base62Uuid.encode(to), 'site': 'left'},
        },
      }),
    },
  );

  String image({String src = 'wonky-file://red'}) => b.element(
    slideId,
    ElementKind.image,
    x: 1000,
    y: 100,
    width: 400,
    height: 400,
    columns: {
      ElementCols.dataJson: jsonEncode({
        'v': 1,
        'src': src,
        'naturalWidth': 2,
        'naturalHeight': 2,
      }),
    },
  );

  String table() {
    final (t, rows, cols) = b.table(
      slideId,
      rows: 2,
      cols: 2,
      x: 100,
      y: 100,
      width: 600,
      height: 200,
    );
    b.cell(t, rows[0], cols[0], 'Head');
    b.cell(t, rows[1], cols[1], 'Body');
    return t;
  }

  String icon() => b.element(
    slideId,
    ElementKind.icon,
    width: 160,
    height: 160,
    columns: {
      ElementCols.dataJson: jsonEncode({'v': 1, 'set': 'emoji', 'char': '🚀'}),
    },
  );

  String code() {
    final id = b.element(
      slideId,
      ElementKind.code,
      width: 800,
      height: 300,
      columns: {
        ElementCols.dataJson: jsonEncode({'v': 1, 'language': 'dart'}),
      },
    );
    _codeStates.add((
      SlidesTables.codeState,
      {
        for (final c in SlidesTables.columns[SlidesTables.codeState]!) c: null,
        SlidesCols.id: '00000000-0000-7000-8000-00000000c0de',
        SlidesCols.elementId: id,
        SlidesCols.sortKey: 'a0',
        CodeStateCols.code: 'void main() {\n  print(1);\n}',
        SlidesCols.createdAt: testNow,
      },
    ));
    return id;
  }

  String chart() => b.element(slideId, ElementKind.chart);

  final List<(String, Map<String, Object?>)> _codeStates = [];

  DeckModel? _model;

  /// The deck (built once).
  DeckModel get model => _model ??= DeckModel.fromRows(b.deckId, [
    for (final (t, c) in b.rows)
      (
        t,
        t == SlidesTables.deck
            ? {...c, DeckCols.appearance: _appearance.name}
            : c,
      ),
    ..._codeStates,
  ]);

  RecordingFontRegistry fonts = RecordingFontRegistry();

  SlideRenderer renderer() =>
      SlideRenderer(model: model, images: images, fonts: fonts);

  /// Moves element [id] to [x] (a local edit).
  void moveElement(String id, double x) {
    final before = model.element(id)!;
    model.applyChanges([
      RowChange.update(
        SlidesTables.slideElement,
        id,
        {ElementCols.x: before.x},
        {ElementCols.x: x},
      ),
    ]);
  }
}
