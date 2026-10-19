import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../../l10n/slides_l10n.dart';
import '../../stage/scene_painter.dart';

/// The shape library categories shown in galleries (03 §6.3; `custom`
/// shapes come from pasted SVG paths).
const galleryCategories = [
  ShapeCategory.basic,
  ShapeCategory.arrows,
  ShapeCategory.stars,
  ShapeCategory.callouts,
  ShapeCategory.flowchart,
  ShapeCategory.brackets,
];

/// The localized name of shape [geometry] ("Rounded rectangle").
String shapeName(SlidesLocalizations l, String geometry) =>
    l.shapeName(geometry);

/// The localized name of a gallery category.
String shapeCategoryName(SlidesLocalizations l, ShapeCategory c) =>
    l.shapeCategory(c.name);

/// Stable widget keys of the shape gallery.
abstract final class ShapeGalleryKeys {
  static const gallery = ValueKey<String>('slides.shapeGallery');

  /// The cell of [geometry].
  static ValueKey<String> cell(String geometry) =>
      ValueKey<String>('slides.shapeGallery.$geometry');
}

/// The shape gallery (Insert › Shape ▸, the toolbar's shape menu, Format ›
/// Shape › Change shape ▸ and the *All shapes…* dialog): the library by
/// category as a grid of drawn outlines with the shape name as tooltip
/// and semantics label. Keyboard: Tab / arrows move over the cells,
/// Enter / Space choose.
class ShapeGallery extends StatelessWidget {
  const ShapeGallery({
    super.key,
    required this.onSelected,
    this.selected,
    this.cell = 32,
    this.columns = 8,
  });

  final ValueChanged<String> onSelected;

  /// The current geometry (highlighted).
  final String? selected;
  final double cell;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = slidesL10n(context);
    return FocusTraversalGroup(
      child: SizedBox(
        key: ShapeGalleryKeys.gallery,
        width: columns * (cell + 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in galleryCategories) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
                child: Text(
                  shapeCategoryName(l, c),
                  style: theme.textTheme.small.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  for (final g in ShapeLibrary.inCategory(c))
                    _cell(context, g.key, shapeName(l, g.key)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String key, String name) {
    final theme = ShadTheme.of(context);
    final on = key == selected;
    return Semantics(
      label: name,
      selected: on,
      child: ShadTooltip(
        builder: (_) => Text(name),
        child: ShadButton.ghost(
          key: ShapeGalleryKeys.cell(key),
          width: cell,
          height: cell,
          padding: EdgeInsets.zero,
          backgroundColor: on ? theme.colorScheme.accent : null,
          onPressed: () => onSelected(key),
          child: ShapeGlyph(
            geometry: key,
            size: cell - 10,
            color: theme.colorScheme.foreground,
            fill: theme.colorScheme.muted,
          ),
        ),
      ),
    );
  }
}

/// A drawn shape outline (gallery cells, menu icons).
class ShapeGlyph extends StatelessWidget {
  const ShapeGlyph({
    super.key,
    required this.geometry,
    required this.size,
    required this.color,
    this.fill,
  });

  final String geometry;
  final double size;
  final Color color;
  final Color? fill;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ShapeGlyphPainter(geometry, color, fill),
  );
}

class _ShapeGlyphPainter extends CustomPainter {
  _ShapeGlyphPainter(this.geometry, this.color, this.fill);

  final String geometry;
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final g = ShapeLibrary.resolve(geometry);
    final aspect = g.aspect ?? 1;
    // Fit the natural aspect into the square, inset for the stroke.
    final side = size.shortestSide - 2;
    final w = aspect >= 1 ? side : side * aspect;
    final h = aspect >= 1 ? side / aspect : side;
    final outline = g.outline(w, h);
    canvas.save();
    canvas.translate((size.width - w) / 2, (size.height - h) / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, side / 18)
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final p in outline.parts) {
      final path = SlideScenePainter.pathOf(p.path);
      if (p.fill && fill != null) canvas.drawPath(path, Paint()..color = fill!);
      if (p.stroke) canvas.drawPath(path, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShapeGlyphPainter old) =>
      old.geometry != geometry || old.color != color || old.fill != fill;
}

/// The *All shapes…* dialog (Insert › Shape ▸, Change shape): the gallery
/// in a dialog, MCP-operable (`shape` select of every geometry key with its
/// name, buttons *Cancel* / *Choose*). Returns the chosen geometry.
Future<String?> showShapeGalleryDialog(
  BuildContext context, {
  String? selected,
}) => showShadDialog<String>(
  context: context,
  builder: (ctx) => ShadDialog(
    key: const ValueKey<String>('slides.dialog.shapeGallery'),
    closeIcon: const WonkyDialogCloseButton(),
    title: Text(slidesL10n(ctx).shapeGalleryTitle),
    child: _ShapeGalleryDialogBody(selected: selected),
  ),
);

class _ShapeGalleryDialogBody extends StatefulWidget {
  const _ShapeGalleryDialogBody({this.selected});

  final String? selected;

  @override
  State<_ShapeGalleryDialogBody> createState() =>
      _ShapeGalleryDialogBodyState();
}

class _ShapeGalleryDialogBodyState extends State<_ShapeGalleryDialogBody>
    implements McpDescribableDialog {
  late String? _selected = widget.selected;
  ShellServices? _registeredIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    super.dispose();
  }

  List<String> get _keys => [
    for (final c in galleryCategories)
      for (final g in ShapeLibrary.inCategory(c)) g.key,
  ];

  @override
  Map<String, Object?> describe() {
    final l = slidesL10n(context);
    return {
      'title': l.shapeGalleryTitle,
      'fields': [
        {
          'id': 'shape',
          'label': l.styleLabelGeometry,
          'type': 'select',
          'value': _selected,
          'options': _keys,
          'optionLabels': {for (final k in _keys) k: shapeName(l, k)},
        },
      ],
      'buttons': [
        {
          'id': 'cancel',
          'label': WonkyAppLocalizations.of(context).actionCancel,
        },
        {'id': 'choose', 'label': l.shapeGalleryChoose},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id != 'shape' || !_keys.contains(value)) return false;
    setState(() => _selected = value as String);
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        Navigator.of(context).pop();
      case 'choose':
        Navigator.of(context).pop(_selected);
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 420 ? 7 : 10;
    return SizedBox(
      height: math.min(480, MediaQuery.sizeOf(context).height - 160),
      child: SingleChildScrollView(
        child: ShapeGallery(
          selected: _selected,
          columns: columns,
          cell: 34,
          onSelected: (g) => Navigator.of(context).pop(g),
        ),
      ),
    );
  }
}
