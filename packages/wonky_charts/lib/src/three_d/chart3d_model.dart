import 'dart:math' as math;
import 'dart:typed_data';

import '../scene/scene.dart';
import '../spec/three_d_options.dart';
import 'vec3.dart';

/// What a 3D item belongs to; the software renderer paints the parts in this order.
enum Chart3DPart { floor, wall, gridline, data }

/// A logical element of a 3D chart (08 §23.3) in world units, before it is meshed. Items with
/// the same [key] in two models are interpolated by [Chart3DModel.lerp] (animated data
/// changes).
sealed class Chart3DItem {
  const Chart3DItem(
    this.key,
    this.color,
    this.tag, {
    this.part = Chart3DPart.data,
  });

  /// Stable identity across data changes (`<series>:<point>` …).
  final String key;

  /// ARGB base color.
  final int color;
  final Chart3DPart part;

  /// Semantic tag for hit-testing and tooltips.
  final SceneTag? tag;

  /// This item at [t] on its way to [other] (same type and key).
  Chart3DItem lerpTo(Chart3DItem other, double t);

  /// The state an appearing item grows from.
  Chart3DItem get collapsed;

  /// A copy in [color] (chart builds fade items toward the background, Slides 08 §9.1).
  Chart3DItem withColor(int color);

  /// Stable JSON for tests.
  Map<String, Object?> toJson();
}

int _lerpColor(int a, int b, double t) => Argb.lerp(a, b, t);
double _l(double a, double b, double t) => a + (b - a) * t;

/// A column/bar segment or a floor/wall plate: an axis-aligned box drawn as a box, cylinder,
/// cone or pyramid along [axis] (0 = x for bars, 1 = y for columns).
final class Chart3DBox extends Chart3DItem {
  /// Creates a box.
  const Chart3DBox(
    super.key,
    super.color,
    super.tag, {
    super.part,
    required this.min,
    required this.max,
    this.shape = Chart3DShape.box,
    this.axis = 1,
    this.tipAtMax = true,
    this.edges = true,
  });

  final Vec3 min;
  final Vec3 max;
  final Chart3DShape shape;

  /// Axis of the shape (0 = x, 1 = y).
  final int axis;

  /// Cones and pyramids point toward the max end of [axis] (false: toward the min end, for
  /// negative values).
  final bool tipAtMax;

  /// Whether the faces get a darker outline.
  final bool edges;

  /// Center of the box.
  Vec3 get center => (min + max) * 0.5;

  @override
  Chart3DItem lerpTo(Chart3DItem other, double t) {
    if (other is! Chart3DBox) return t < 0.5 ? this : other;
    return Chart3DBox(
      key,
      _lerpColor(color, other.color, t),
      other.tag,
      part: other.part,
      min: min.lerp(other.min, t),
      max: max.lerp(other.max, t),
      shape: other.shape,
      axis: other.axis,
      tipAtMax: other.tipAtMax,
      edges: other.edges,
    );
  }

  @override
  Chart3DItem get collapsed {
    // Grows from its base along the axis.
    final base = tipAtMax
        ? (axis == 0 ? min.x : min.y)
        : (axis == 0 ? max.x : max.y);
    final lo = axis == 0 ? Vec3(base, min.y, min.z) : Vec3(min.x, base, min.z);
    final hi = axis == 0 ? Vec3(base, max.y, max.z) : Vec3(max.x, base, max.z);
    return Chart3DBox(
      key,
      color,
      tag,
      part: part,
      min: lo,
      max: hi,
      shape: shape,
      axis: axis,
      tipAtMax: tipAtMax,
      edges: edges,
    );
  }

  @override
  Chart3DItem withColor(int color) => Chart3DBox(
    key,
    color,
    tag,
    part: part,
    min: min,
    max: max,
    shape: shape,
    axis: axis,
    tipAtMax: tipAtMax,
    edges: edges,
  );

  @override
  Map<String, Object?> toJson() => {
    'box': key,
    'min': [sceneNum(min.x), sceneNum(min.y), sceneNum(min.z)],
    'max': [sceneNum(max.x), sceneNum(max.y), sceneNum(max.z)],
    'color': argbHex(color),
    if (shape != Chart3DShape.box) 'shape': shape.name,
  };
}

/// A pie or doughnut slice: an extruded annular sector on the floor plane. Angles are radians
/// clockwise from −z (12 o'clock seen from above with the viewer at +z).
final class Chart3DWedge extends Chart3DItem {
  /// Creates a wedge.
  const Chart3DWedge(
    super.key,
    super.color,
    super.tag, {
    required this.center,
    required this.start,
    required this.sweep,
    required this.radius,
    this.innerRadius = 0,
    required this.height,
    this.offset = 0,
  });

  /// Center of the pie's bottom.
  final Vec3 center;
  final double start;
  final double sweep;
  final double radius;
  final double innerRadius;
  final double height;

  /// Explode distance (world units) along the middle angle.
  final double offset;

  /// Middle angle.
  double get mid => start + sweep / 2;

  /// The point at angle [a] and radius [r] (before the explode offset), at height [y].
  static Vec3 polar(Vec3 c, double a, double r, double y) =>
      Vec3(c.x + math.sin(a) * r, y, c.z - math.cos(a) * r);

  /// Center of the bottom after the explode offset.
  Vec3 get shiftedCenter => Vec3(
    center.x + math.sin(mid) * offset,
    center.y,
    center.z - math.cos(mid) * offset,
  );

  @override
  Chart3DItem lerpTo(Chart3DItem other, double t) {
    if (other is! Chart3DWedge) return t < 0.5 ? this : other;
    return Chart3DWedge(
      key,
      _lerpColor(color, other.color, t),
      other.tag,
      center: center.lerp(other.center, t),
      start: _l(start, other.start, t),
      sweep: _l(sweep, other.sweep, t),
      radius: _l(radius, other.radius, t),
      innerRadius: _l(innerRadius, other.innerRadius, t),
      height: _l(height, other.height, t),
      offset: _l(offset, other.offset, t),
    );
  }

  @override
  Chart3DItem get collapsed => Chart3DWedge(
    key,
    color,
    tag,
    center: center,
    start: start + sweep,
    sweep: 0,
    radius: radius,
    innerRadius: innerRadius,
    height: height,
    offset: offset,
  );

  @override
  Chart3DItem withColor(int color) => Chart3DWedge(
    key,
    color,
    tag,
    center: center,
    start: start,
    sweep: sweep,
    radius: radius,
    innerRadius: innerRadius,
    height: height,
    offset: offset,
  );

  @override
  Map<String, Object?> toJson() => {
    'wedge': key,
    'start': sceneNum(start),
    'sweep': sceneNum(sweep),
    'r': sceneNum(radius),
    if (innerRadius > 0) 'inner': sceneNum(innerRadius),
    'h': sceneNum(height),
    if (offset > 0) 'offset': sceneNum(offset),
    'color': argbHex(color),
  };
}

/// A 3D area or line ribbon: the profile between [bottoms] and [tops] at [xs], extruded from
/// [z0] to [z1]. NaN tops break the profile into runs.
final class Chart3DSlab extends Chart3DItem {
  /// Creates a slab.
  const Chart3DSlab(
    super.key,
    super.color,
    super.tag, {
    required this.xs,
    required this.tops,
    required this.bottoms,
    required this.z0,
    required this.z1,
    this.pointIndexes,
  });

  final Float64List xs;
  final Float64List tops;
  final Float64List bottoms;
  final double z0;
  final double z1;

  /// Domain index of each x (null = the position).
  final Int32List? pointIndexes;

  /// Domain index of vertex [k].
  int pointIndexOf(int k) => pointIndexes?[k] ?? k;

  @override
  Chart3DItem lerpTo(Chart3DItem other, double t) {
    if (other is! Chart3DSlab || other.xs.length != xs.length) {
      return t < 0.5 ? this : other;
    }
    Float64List mix(Float64List a, Float64List b) => Float64List.fromList([
      for (var i = 0; i < a.length; i++)
        a[i].isNaN || b[i].isNaN ? b[i] : _l(a[i], b[i], t),
    ]);
    return Chart3DSlab(
      key,
      _lerpColor(color, other.color, t),
      other.tag,
      xs: mix(xs, other.xs),
      tops: mix(tops, other.tops),
      bottoms: mix(bottoms, other.bottoms),
      z0: _l(z0, other.z0, t),
      z1: _l(z1, other.z1, t),
      pointIndexes: other.pointIndexes,
    );
  }

  @override
  Chart3DItem get collapsed => Chart3DSlab(
    key,
    color,
    tag,
    xs: xs,
    tops: Float64List.fromList([
      for (var i = 0; i < tops.length; i++)
        tops[i].isNaN ? double.nan : bottoms[i],
    ]),
    bottoms: bottoms,
    z0: z0,
    z1: z1,
    pointIndexes: pointIndexes,
  );

  @override
  Chart3DItem withColor(int color) => Chart3DSlab(
    key,
    color,
    tag,
    xs: xs,
    tops: tops,
    bottoms: bottoms,
    z0: z0,
    z1: z1,
    pointIndexes: pointIndexes,
  );

  @override
  Map<String, Object?> toJson() => {
    'slab': key,
    'xs': [for (final x in xs) sceneNum(x)],
    'tops': [for (final y in tops) sceneNum(y)],
    'bottoms': [for (final y in bottoms) sceneNum(y)],
    'z': [sceneNum(z0), sceneNum(z1)],
    'color': argbHex(color),
  };
}

/// A quadrilateral of a surface chart (08 §23): corners in order around the patch (they
/// need not be coplanar; the mesher splits it into two triangles), visible from both sides.
final class Chart3DPatch extends Chart3DItem {
  /// Creates a patch.
  const Chart3DPatch(
    super.key,
    super.color,
    super.tag, {
    required this.corners,
    this.floorY = 0,
  });

  /// Four corners.
  final List<Vec3> corners;

  /// Height an appearing patch grows from.
  final double floorY;

  @override
  Chart3DItem lerpTo(Chart3DItem other, double t) {
    if (other is! Chart3DPatch) return t < 0.5 ? this : other;
    return Chart3DPatch(
      key,
      _lerpColor(color, other.color, t),
      other.tag,
      corners: [
        for (var i = 0; i < corners.length; i++)
          corners[i].lerp(other.corners[i], t),
      ],
      floorY: other.floorY,
    );
  }

  @override
  Chart3DItem get collapsed => Chart3DPatch(
    key,
    color,
    tag,
    corners: [for (final c in corners) Vec3(c.x, floorY, c.z)],
    floorY: floorY,
  );

  @override
  Chart3DItem withColor(int color) =>
      Chart3DPatch(key, color, tag, corners: corners, floorY: floorY);

  @override
  Map<String, Object?> toJson() => {
    'patch': key,
    'corners': [
      for (final c in corners) [sceneNum(c.x), sceneNum(c.y), sceneNum(c.z)],
    ],
    'color': argbHex(color),
  };
}

/// A gridline on a wall or the floor, [width] px wide.
final class Chart3DLine extends Chart3DItem {
  /// Creates a line.
  const Chart3DLine(
    String key,
    int color, {
    required this.a,
    required this.b,
    required this.normal,
    this.width = 1,
  }) : super(key, color, null, part: Chart3DPart.gridline);

  final Vec3 a;
  final Vec3 b;

  /// Normal of the surface the line lies on (the GPU backend lifts it off the surface).
  final Vec3 normal;
  final double width;

  @override
  Chart3DItem lerpTo(Chart3DItem other, double t) {
    if (other is! Chart3DLine) return t < 0.5 ? this : other;
    return Chart3DLine(
      key,
      _lerpColor(color, other.color, t),
      a: a.lerp(other.a, t),
      b: b.lerp(other.b, t),
      normal: other.normal,
      width: other.width,
    );
  }

  @override
  Chart3DItem get collapsed => this;

  @override
  Chart3DItem withColor(int color) =>
      Chart3DLine(key, color, a: a, b: b, normal: normal, width: width);

  @override
  Map<String, Object?> toJson() => {
    'line': key,
    'a': [sceneNum(a.x), sceneNum(a.y), sceneNum(a.z)],
    'b': [sceneNum(b.x), sceneNum(b.y), sceneNum(b.z)],
  };
}

/// A text placed at a projected world point (axis and data labels; both backends draw text
/// with Flutter on top of the 3D image).
final class Chart3DLabel {
  /// Creates a label. [outward] is the world direction the text moves away from [anchor];
  /// null centers it on the anchor.
  const Chart3DLabel(
    this.text,
    this.anchor,
    this.style, {
    this.outward,
    this.gap = 6,
    this.tag,
  });

  final String text;
  final Vec3 anchor;
  final TextStyleSpec style;
  final Vec3? outward;

  /// Distance in px between the anchor and the text box.
  final double gap;
  final SceneTag? tag;
}

/// Kind of 3D chart.
enum Chart3DKind { cartesian, pie }

/// A laid-out 3D chart in world units (08 §23.3): its items, labels and view settings. The
/// layout engine builds it from the spec and data; [Chart3DScene] meshes, projects and picks
/// it.
final class Chart3DModel {
  /// Creates a model.
  const Chart3DModel({
    required this.kind,
    required this.items,
    required this.labels,
    required this.bounds,
    required this.azimuth,
    required this.elevation,
    required this.fov,
    required this.lighting,
    required this.background,
    required this.floorY,
    this.dark = false,
  });

  final Chart3DKind kind;
  final List<Chart3DItem> items;
  final List<Chart3DLabel> labels;

  /// Bounds the camera is fitted to.
  final Aabb3 bounds;

  /// View angles and field of view in degrees.
  final double azimuth;
  final double elevation;
  final double fov;
  final Chart3DLighting lighting;

  /// ARGB chart background (shadows and highlights blend toward it).
  final int background;

  /// Height of the floor (shadows are cast on it).
  final double floorY;

  /// Whether the chart uses the dark theme.
  final bool dark;

  /// Data items only.
  Iterable<Chart3DItem> get dataItems =>
      items.where((i) => i.part == Chart3DPart.data);

  /// A copy viewed from other angles (orbit drags).
  Chart3DModel withView({double? azimuth, double? elevation, double? fov}) =>
      Chart3DModel(
        kind: kind,
        items: items,
        labels: labels,
        bounds: bounds,
        azimuth: azimuth ?? this.azimuth,
        elevation: elevation ?? this.elevation,
        fov: fov ?? this.fov,
        lighting: lighting,
        background: background,
        floorY: floorY,
        dark: dark,
      );

  /// The model between [from] and [to] at [t] (0..1): items with the same key are
  /// interpolated, new ones grow from their collapsed state; labels, view and bounds are
  /// those of [to].
  static Chart3DModel lerp(Chart3DModel from, Chart3DModel to, double t) {
    if (t >= 1) return to;
    final old = {for (final i in from.items) i.key: i};
    final items = <Chart3DItem>[
      for (final i in to.items)
        (old[i.key] ?? i.collapsed).lerpTo(i, t.clamp(0.0, 1.0)),
    ];
    return Chart3DModel(
      kind: to.kind,
      items: items,
      labels: to.labels,
      bounds: to.bounds,
      azimuth: to.azimuth,
      elevation: to.elevation,
      fov: to.fov,
      lighting: to.lighting,
      background: to.background,
      floorY: to.floorY,
      dark: to.dark,
    );
  }

  /// A hash of everything the meshes depend on (not the view), so GPU backends rebuild their
  /// buffers only when it changes.
  ///
  /// The model is immutable: computed once per instance (it is read on every
  /// GPU frame, CQ-47).
  int get contentHash => _contentHashes[this] ??= Object.hashAll([
    kind,
    lighting,
    for (final i in items) Object.hashAll(i.toJson().values.map(_hashable)),
  ]);

  static final Expando<int> _contentHashes = Expando(
    'Chart3DModel.contentHash',
  );

  static Object? _hashable(Object? v) =>
      v is List ? Object.hashAll(v.map(_hashable)) : v;

  /// Stable JSON for tests.
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'view': [sceneNum(azimuth), sceneNum(elevation), sceneNum(fov)],
    'items': [for (final i in items) i.toJson()],
    'labels': [for (final l in labels) l.text],
  };
}
