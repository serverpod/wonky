/// `SlideSceneBuilder` (02 §11, 03 §1.3, 12 §5.4): a resolved slide → a
/// renderer-independent [SlideScene]. Every element becomes a [GroupNode]
/// carrying its id (the timeline animates it, the stage caches it) whose
/// children draw the kind's content in element-local su (lines and element
/// groups in slide space). Derived geometry — auto-fit, auto-width text,
/// grown table rows, connector routes — is computed here and exposed on
/// the scene (P8: never stored).
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:wonky_charts/wonky_charts.dart' show SStrokeCap, SStrokeJoin;

import '../../code/code_element_data.dart' show CodeBoxStyle;
import '../../connectors/connector_router.dart';
import '../../geometry/path_ops.dart';
import '../../geometry/shape_library.dart';
import '../../layout/auto_fit.dart';
import '../../model/api/deck_model.dart';
import '../../model/index/deck_indexes.dart';
import '../../model/api/kinds.dart';
import '../../model/api/resolved.dart';
import '../../model/index/table_index.dart';
import '../../model/resolve/slide_resolver.dart' show ResolvedSlide;
import '../../model/resolve/text_style_resolver.dart';
import '../../schema/slides_schema.dart';
import '../../theme/model/box_text_style.dart';
import '../../theme/model/common.dart';
import '../../theme/model/object_styles.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../nodes/scene_nodes.dart';
import '../nodes/table_grid.dart';
import '../nodes/text_layout.dart';
import 'code_layout.dart';
import 'image_adjust.dart';
import 'paint_resolve.dart';

/// Default text insets `[t, r, b, l]` (su) when the box chain sets none.
const List<double> defaultTextInsets = [8, 16, 8, 16];

/// Builds scenes. One builder per open deck (it caches element nodes per
/// resolved element, so unchanged slides keep their node identities).
final class SlideSceneBuilder {
  /// Creates a builder.
  SlideSceneBuilder({TextStyleResolver? textStyles})
    : textStyles = textStyles ?? TextStyleResolver();

  /// Resolves cell text styles.
  final TextStyleResolver textStyles;

  final Expando<_Slots> _cache = Expando('sceneNode');

  /// Element nodes built (cache misses) by every builder so far (perf
  /// tests, CQ-38).
  static int debugNodeBuilds = 0;

  /// The scene of [slide].
  SlideScene build(ResolvedSlide slide, SceneContext context) {
    final ctx = context.withTheme(slide.theme);
    final all = <String, ResolvedElement>{
      for (final e in slide.painted) e.id: e,
    };
    final b = _Build(
      this,
      ctx,
      (id) => all[id],
      background: slide.background.effectiveColor(
        ctx.theme.colorOf('bg1') ?? 0xffffffff,
      ),
    );
    final nodes = <SceneNode>[
      for (final e in slide.masterElements) ?b.element(e),
      for (final e in slide.layoutElements) ?b.element(e),
      for (final e in slide.elements) ?b.element(e),
    ];
    return SlideScene(
      slideId: slide.slide.id,
      width: slide.bounds.width,
      height: slide.bounds.height,
      background: slide.background,
      nodes: nodes,
      frames: b.frames,
      routes: b.routes,
    );
  }

  /// The scene of free [elements] (layout/master previews, 05 §8; pasted
  /// content previews).
  SlideScene buildElements(
    String id,
    List<ResolvedElement> elements, {
    required double width,
    required double height,
    required ResolvedBackground background,
    required SceneContext context,
  }) {
    final all = <String, ResolvedElement>{};
    void index(List<ResolvedElement> l) {
      for (final e in l) {
        all[e.id] = e;
        index(e.children);
      }
    }

    index(elements);
    final b = _Build(
      this,
      context,
      (id) => all[id],
      background: background.effectiveColor(
        context.theme.colorOf('bg1') ?? 0xffffffff,
      ),
    );
    return SlideScene(
      slideId: id,
      width: width,
      height: height,
      background: background,
      nodes: [for (final e in elements) ?b.element(e)],
      frames: b.frames,
      routes: b.routes,
    );
  }

  /// The node of one element (03 §1.3, built per kind here);
  /// [lookup] finds glued connector targets. Null for hidden elements.
  SceneNode? buildElement(
    ResolvedElement element,
    SceneContext context, {
    ResolvedElement? Function(String id)? lookup,
  }) => _Build(this, context, lookup ?? (_) => null).element(element);

  /// The laid-out grid of table [element] (SL-15): the same layout the
  /// scene draws, with [cellText] (`"<rowId>|<columnId>"` → Delta JSON)
  /// overriding stored cell bodies (the cell being edited). [context] must
  /// carry the slide's theme and the deck. Null when it isn't a table or
  /// has no rows/columns.
  TableGrid? tableGrid(
    ResolvedElement element,
    SceneContext context, {
    Map<String, String?> cellText = const {},
  }) {
    final deck = context.deck;
    if (element.record.kind != ElementKind.table || deck == null) return null;
    final ix = deck is DeckModel
        ? deck.indexes.table(element.id)
        : TableIndex.of(deck, element.id);
    final layout = _TableLayout(
      _Build(this, context, (_) => null),
      element,
      ix,
      cellText: cellText,
    );
    layout.build();
    return layout.grid;
  }
}

final class _CacheEntry {
  _CacheEntry(this.key, this.node, this.frame, this.route);

  final String key;
  final SceneNode? node;
  final SuRect? frame;
  final List<({double x, double y})>? route;
}

final class _Build {
  _Build(this.owner, this.ctx, this.lookup, {this.background});

  final SlideSceneBuilder owner;
  final SceneContext ctx;
  final ResolvedElement? Function(String id) lookup;

  /// The effective slide background (ARGB) behind the elements, when known
  /// (code palettes `auto`, 07 §2.5).
  final int? background;
  final Map<String, SuRect> frames = {};
  final Map<String, List<({double x, double y})>> routes = {};

  ResolvedTheme get theme => ctx.theme;

  /// The cache key of [e]'s node besides its identity. Resolved elements
  /// keep their identity while only their dependent rows change (table
  /// cells, code states, chart links), so the element's revision is part
  /// of the key, with the context and the glued targets.
  String _key(ResolvedElement e) => [
    theme.contentHash,
    theme.appearance.name,
    ctx.editing,
    ctx.purpose.name,
    identityHashCode(ctx.textLayout),
    identityHashCode(ctx.icons),
    identityHashCode(ctx.charts),
    identityHashCode(ctx.code),
    identityHashCode(ctx.deck),
    _revisionOf(e.id),
    ctx.codeStates[e.id] ?? '',
    ctx.codeSteps[e.id] ?? '',
    ctx.generation,
    if (e.record.kind == ElementKind.line) _glueKey(e),
    if (e.record.kind == ElementKind.code || e.record.kind == ElementKind.chart)
      background ?? '',
  ].join('|');

  String _revisionOf(String elementId) {
    final deck = ctx.deck;
    return deck is DeckModel ? deck.indexes.elementRevision(elementId) : '';
  }

  String _glueKey(ResolvedElement line) {
    final d = LineData.fromJson(line.data);
    String part(LineEndpoint p) {
      final id = p.elementId;
      if (id == null) return '';
      final t = lookup(id);
      // Derived frames (grown tables, auto-fit text) follow the target's
      // dependent rows.
      return t == null ? 'x' : '${identityHashCode(t)}.${_revisionOf(id)}';
    }

    return '${part(d.start)}/${part(d.end)}';
  }

  SceneNode? element(ResolvedElement e) {
    if (e.hidden) return null;
    // One element is built for several contexts (the canvas's edit scene
    // and the thumbnails share a renderer): a few entries per element.
    final slots = owner._cache[e] ??= _Slots();
    if (e.record.kind == ElementKind.group) {
      final children = [for (final c in e.children) ?element(c)];
      // The group node is reused while its children nodes are.
      final gk = 'group|${ctx.purpose.name}|${ctx.editing}';
      final hit = slots.get(gk);
      final g = hit?.node;
      if (g is GroupNode && _sameNodes(g.children, children)) return g;
      final node = GroupNode(elementId: e.id, children: children);
      slots.put(gk, _CacheEntry(gk, node, null, null));
      return node;
    }
    final key = _key(e);
    final hit = slots.get(key);
    if (hit != null) {
      if (hit.frame != null) frames[e.id] = hit.frame!;
      if (hit.route != null) routes[e.id] = hit.route!;
      return hit.node;
    }
    final before = (frames[e.id], routes[e.id]);
    SlideSceneBuilder.debugNodeBuilds++;
    final node = _build(e);
    final frame = frames[e.id];
    final route = routes[e.id];
    slots.put(
      key,
      _CacheEntry(
        key,
        node,
        identical(frame, before.$1) ? null : frame,
        identical(route, before.$2) ? null : route,
      ),
    );
    return node;
  }

  SceneNode? _build(ResolvedElement e) {
    switch (e.record.kind) {
      case ElementKind.line:
        return _line(e);
      case ElementKind.group:
        return null; // handled by [element]
      case ElementKind.text:
      case ElementKind.shape:
        return _textOrShape(e);
      case ElementKind.image:
        return _wrap(e, _image(e), e.frame);
      case ElementKind.table:
        final (children, h) = _table(e);
        final f = h == null
            ? e.frame
            : SuRect(e.frame.x, e.frame.y, e.frame.width, h);
        if (h != null && (h - e.frame.height).abs() > 0.01) frames[e.id] = f;
        return _wrap(e, children, f);
      case ElementKind.icon:
        return _wrap(e, _icon(e), e.frame);
      case ElementKind.code:
        return _wrap(e, _code(e), e.frame, defaultShadow: _codeShadow(e));
      case ElementKind.chart:
        return _wrap(e, _chart(e), e.frame);
    }
  }

  // ---------------------------------------------------------------------
  // Element group wrapper

  GroupNode _wrap(
    ResolvedElement e,
    List<SceneNode> children,
    SuRect frame, {
    NodeEffects? defaultShadow,
  }) {
    final effects = e.effects == null
        ? (defaultShadow ?? NodeEffects.none)
        : ScenePaint.effects(theme, e.effects);
    return GroupNode(
      elementId: e.id,
      transform: frameTransform(
        frame,
        rotation: e.rotation,
        flipH: e.flipH,
        flipV: e.flipV,
      ),
      opacity: e.opacity,
      effects: effects,
      children: children,
    );
  }

  /// Element-local (0..w, 0..h) → slide space.
  static Matrix4 frameTransform(
    SuRect f, {
    double rotation = 0,
    bool flipH = false,
    bool flipV = false,
  }) {
    final a0 = rotation * math.pi / 180;
    final cos = math.cos(a0), sin = math.sin(a0);
    final fx = flipH ? -1.0 : 1.0, fy = flipV ? -1.0 : 1.0;
    final a = cos * fx, b = sin * fx, c = -sin * fy, d = cos * fy;
    final cx = f.x + f.width / 2, cy = f.y + f.height / 2;
    final ex = cx - a * f.width / 2 - c * f.height / 2;
    final ey = cy - b * f.width / 2 - d * f.height / 2;
    return affine(a, b, c, d, ex, ey);
  }

  /// A 2D affine transform `[a c e; b d f]` as a [Matrix4].
  static Matrix4 affine(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) => Matrix4(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1);

  // ---------------------------------------------------------------------
  // Text boxes and shapes

  ObjectStyleDefaults _defaultsOf(ResolvedElement e) =>
      e.record.kind == ElementKind.shape
      ? theme.shapeStyles.shape
      : theme.shapeStyles.text;

  SceneNode? _textOrShape(ResolvedElement e) {
    final isShape = e.record.kind == ElementKind.shape;
    final defaults = _defaultsOf(e);
    final fill = ScenePaint.fill(theme, e.fill, fallback: defaults.fill);
    final stroke = ScenePaint.stroke(
      theme,
      e.stroke,
      fallback: defaults.stroke,
    );
    var frame = e.frame;
    final text = _textBlock(e, frame, defaults, isShape);
    if (text != null) {
      final (_, w, h, _, _) = text;
      if ((w - frame.width).abs() > 0.01 || (h - frame.height).abs() > 0.01) {
        frame = SuRect(frame.x, frame.y, w, h);
        frames[e.id] = frame;
      }
    }
    final children = <SceneNode>[];
    if (isShape) {
      final outline = ShapeLibrary.outlineOf(e.data, frame.width, frame.height);
      for (final part in outline.parts) {
        final f = part.fill && ScenePaint.visible(fill)
            ? ScenePaint.shaded(fill, part.shade)
            : null;
        final s = part.stroke ? stroke : null;
        if (f == null && s == null) continue;
        children.add(PathNode(path: part.path, fill: f, stroke: s));
      }
    } else if (ScenePaint.visible(fill) || stroke != null) {
      children.add(
        PathNode(
          path: (ShapePathBuilder()..rect(0, 0, frame.width, frame.height))
              .build(),
          fill: ScenePaint.visible(fill) ? fill : null,
          stroke: stroke,
        ),
      );
    }
    if (text != null) {
      final (node, w, h, _, _) = text;
      if (node != null) {
        children.add(
          e.flipH || e.flipV
              ? GroupNode(
                  transform: affine(
                    e.flipH ? -1 : 1,
                    0,
                    0,
                    e.flipV ? -1 : 1,
                    e.flipH ? w : 0,
                    e.flipV ? h : 0,
                  ),
                  children: [node],
                )
              : node,
        );
      }
    }
    return _wrap(e, children, frame);
  }

  /// Lays out the element's text: the text (or prompt) node and the
  /// effective box size (auto-fit `resize`, auto width).
  (SceneNode?, double w, double h, FittedText?, SuRect)? _textBlock(
    ResolvedElement e,
    SuRect frame,
    ObjectStyleDefaults defaults,
    bool isShape,
  ) {
    final base = e.textStyles;
    if (base == null) return null;
    final box = (defaults.textStyle ?? BoxTextStyle.empty).merge(e.textStyle);
    final styles = base.withBox(box);
    final field = e.fieldText;
    var body = field != null
        ? _fieldBody(e.text, field)
        : TextBody.fromJson(e.text);
    var prompt = false;
    if (body.isBlank) {
      final p = e.prompt;
      if (ctx.editing && p != null && p.isNotEmpty) {
        body = TextBody.plain(p);
        prompt = true;
      } else {
        return (null, frame.width, frame.height, null, SuRect(0, 0, 0, 0));
      }
    }
    final insets = box.insets ?? defaultTextInsets;
    final (t, r, b, l) = (insets[0], insets[1], insets[2], insets[3]);
    final textRect = _textRect(e, frame.width, frame.height, isShape);
    final wrap = box.wrap ?? true;
    final mode = AutoFitMode.fromName(
      box.autofit,
      fallback: isShape ? AutoFitMode.shrink : AutoFitMode.resize,
    );
    var cw = math.max(1.0, textRect.width - l - r);
    var w = frame.width;
    if (!wrap && !isShape) {
      final probe = ctx.textLayout.layout(body, styles, width: 100000);
      var natural = 0.0;
      for (final line in probe.lines) {
        natural = math.max(natural, line.width + math.max(0, line.left));
      }
      cw = math.max(1.0, natural + 0.5);
      w = cw + l + r;
    }
    final available = math.max(0.0, textRect.height - t - b);
    final fitted = AutoFit.fit(
      layoutAt: (s) => ctx.textLayout.layout(body, styles, width: cw, scale: s),
      mode: prompt ? AutoFitMode.none : mode,
      available: available,
      insetsY: t + b,
    );
    var h = frame.height;
    if (mode == AutoFitMode.resize && !prompt) {
      h = frame.height + math.max(0.0, fitted.contentHeight - available);
    }
    final effAvailable = available + (h - frame.height);
    final anchor = box.anchor ?? (isShape ? 'middle' : 'top');
    final free = effAvailable - fitted.contentHeight;
    final dy = switch (anchor) {
      'middle' => free / 2,
      'bottom' => free,
      _ => 0.0,
    };
    final ox = textRect.x + l, oy = textRect.y + t + dy;
    final SceneNode node = prompt
        ? PromptNode(
            elementId: e.id,
            text: body.plainText.trimRight(),
            box: SuRect(textRect.x + l, textRect.y + t, cw, effAvailable),
            layout: fitted.layout,
            originX: ox,
            originY: oy,
          )
        : TextNode(
            elementId: e.id,
            layout: fitted.layout,
            originX: ox,
            originY: oy,
          );
    return (node, w, h, fitted, textRect);
  }

  /// A field placeholder's text with the definition's paragraph attributes.
  static TextBody _fieldBody(String? defText, String value) {
    final def = TextBody.fromJson(defText);
    Map<String, Object?>? block;
    for (final op in def.ops) {
      final ins = op['insert'];
      if (ins is String && ins.contains('\n') && op['attributes'] is Map) {
        block = (op['attributes'] as Map).cast<String, Object?>();
        break;
      }
    }
    return TextBody([
      {'insert': value},
      {'insert': '\n', 'attributes': ?block},
    ]);
  }

  SuRect _textRect(ResolvedElement e, double w, double h, bool isShape) {
    final tb = e.data?['textBounds'];
    if (tb is Map) {
      final x = tb['x'], y = tb['y'], tw = tb['w'], th = tb['h'];
      if (x is num && y is num && tw is num && th is num && tw > 0 && th > 0) {
        return SuRect(x * w, y * h, tw * w, th * h);
      }
    }
    if (!isShape) return SuRect(0, 0, w, h);
    return ShapeLibrary.outlineOf(e.data, w, h).textRect;
  }

  // ---------------------------------------------------------------------
  // Lines and connectors

  SceneNode? _line(ResolvedElement e) {
    final route = ConnectorRouter.route(e, lookup);
    routes[e.id] = route.points;
    final stroke = ScenePaint.stroke(
      theme,
      e.stroke,
      fallback: theme.shapeStyles.line.stroke,
      arrows: true,
    );
    final children = <SceneNode>[];
    if (stroke != null) {
      final len = ArrowHeads.lengthFor(stroke.width, null) * stroke.arrowScale;
      final trimStart = ArrowHeads.trimFor(stroke.startArrow, len);
      final trimEnd = ArrowHeads.trimFor(stroke.endArrow, len);
      final shaft = NodeStroke(
        width: stroke.width,
        color: stroke.color,
        dash: stroke.dash,
        cap: stroke.cap,
        join: stroke.join,
      );
      children.add(
        PathNode(path: _trimmed(route, trimStart, trimEnd), stroke: shaft),
      );
      void head(ArrowHead style, SuPoint tip, SuPoint dir) {
        if (style == ArrowHead.none) return;
        final (path, :filled) = ArrowHeads.head(
          style,
          tip,
          dir,
          len,
          stroke.width,
        );
        children.add(
          filled
              ? PathNode(path: path, fill: ResolvedSolidFill(stroke.color))
              : PathNode(
                  path: path,
                  stroke: NodeStroke(
                    width: stroke.width,
                    color: stroke.color,
                    cap: SStrokeCap.round,
                    join: SStrokeJoin.round,
                  ),
                ),
        );
      }

      head(stroke.endArrow, route.end, route.endDirection);
      head(stroke.startArrow, route.start, (
        x: -route.startDirection.x,
        y: -route.startDirection.y,
      ));
    }
    final effects = e.effects == null
        ? NodeEffects.none
        : ScenePaint.effects(theme, e.effects);
    return GroupNode(
      elementId: e.id,
      opacity: e.opacity,
      effects: effects,
      children: children,
    );
  }

  static ScenePath _trimmed(ConnectorRoute r, double start, double end) {
    final pts = [...r.points];
    if (r.routing == LineRouting.curved && pts.length == 4) {
      final s = r.startDirection, d = r.endDirection;
      pts[0] = (x: pts[0].x + s.x * start, y: pts[0].y + s.y * start);
      pts[1] = (x: pts[1].x + s.x * start, y: pts[1].y + s.y * start);
      pts[3] = (x: pts[3].x - d.x * end, y: pts[3].y - d.y * end);
      pts[2] = (x: pts[2].x - d.x * end, y: pts[2].y - d.y * end);
      return (ShapePathBuilder()
            ..moveTo(pts[0].x, pts[0].y)
            ..cubicTo(
              pts[1].x,
              pts[1].y,
              pts[2].x,
              pts[2].y,
              pts[3].x,
              pts[3].y,
            ))
          .build();
    }
    SuPoint move(SuPoint from, SuPoint toward, double by) {
      final dx = toward.x - from.x, dy = toward.y - from.y;
      final l = math.sqrt(dx * dx + dy * dy);
      if (l == 0 || by == 0) return from;
      final k = math.min(by, l * 0.9) / l;
      return (x: from.x + dx * k, y: from.y + dy * k);
    }

    if (pts.length >= 2) {
      pts[0] = move(pts[0], pts[1], start);
      final n = pts.length;
      pts[n - 1] = move(pts[n - 1], pts[n - 2], end);
    }
    final b = ShapePathBuilder()..moveTo(pts.first.x, pts.first.y);
    for (final p in pts.skip(1)) {
      b.lineTo(p.x, p.y);
    }
    return b.build();
  }

  // ---------------------------------------------------------------------
  // Images

  List<SceneNode> _image(ResolvedElement e) {
    final data = e.data ?? const <String, Object?>{};
    final w = e.frame.width, h = e.frame.height;
    final src = data['src'];
    final out = <SceneNode>[];
    final mask = data['mask'] is String
        ? ShapeLibrary.resolve(data['mask'] as String)
              .outline(
                w,
                h,
                adjust: data['maskAdjust'] is Map
                    ? (data['maskAdjust'] as Map).cast<String, Object?>()
                    : null,
              )
              .fillPath
        : null;
    final outline = mask ?? (ShapePathBuilder()..rect(0, 0, w, h)).build();
    final fill = ScenePaint.fill(theme, e.fill);
    if (ScenePaint.visible(fill)) out.add(PathNode(path: outline, fill: fill));
    if (src is String && src.isNotEmpty) {
      final nw = (data['naturalWidth'] as num?)?.toInt();
      final nh = (data['naturalHeight'] as num?)?.toInt();
      final crop = data['crop'] is Map
          ? (data['crop'] as Map).cast<String, Object?>()
          : const <String, Object?>{};
      double c(String k) {
        final v = crop[k];
        return v is num && v.isFinite ? v.toDouble().clamp(-1.0, 0.99) : 0;
      }

      final iw = (nw ?? 1).toDouble(), ih = (nh ?? 1).toDouble();
      final l = c('l'), t = c('t'), r = c('r'), b = c('b');
      final adjust = data['adjust'] is Map
          ? (data['adjust'] as Map).cast<String, Object?>()
          : null;
      final blur = adjust?['blur'];
      out.add(
        ImageNode(
          elementId: e.id,
          image: SlideImageRef(src, naturalWidth: nw, naturalHeight: nh),
          src: SuRect(
            l * iw,
            t * ih,
            math.max(1e-6, (1 - l - r) * iw),
            math.max(1e-6, (1 - t - b) * ih),
          ),
          dst: SuRect(0, 0, w, h),
          colorMatrix: ImageAdjust.matrix(adjust),
          mask: mask,
          blurSigma: blur is num && blur > 0 ? blur.toDouble() : 0,
        ),
      );
    }
    final stroke = ScenePaint.stroke(theme, e.stroke);
    if (stroke != null) out.add(PathNode(path: outline, stroke: stroke));
    return out;
  }

  // ---------------------------------------------------------------------
  // Icons

  List<SceneNode> _icon(ResolvedElement e) {
    final data = e.data ?? const <String, Object?>{};
    final w = e.frame.width, h = e.frame.height;
    final size = math.min(w, h);
    final stroke = ScenePaint.stroke(
      theme,
      e.stroke,
      fallback: theme.shapeStyles.icon.stroke,
    );
    final color = stroke?.color ?? theme.colorOf('text1')!;
    final IconGlyph? glyph;
    if (data['set'] == 'emoji') {
      final ch = data['char'];
      glyph = ch is String && ch.isNotEmpty
          ? IconGlyph(ctx.icons?.emojiFamily ?? '', ch)
          : null;
    } else {
      final name = data['name'];
      final sw = (data['strokeWidth'] as num?)?.toDouble() ?? 2;
      glyph = name is String ? ctx.icons?.lucide(name, sw) : null;
    }
    final out = <SceneNode>[];
    final fill = ScenePaint.fill(theme, e.fill);
    if (ScenePaint.visible(fill)) {
      out.add(
        PathNode(
          path: (ShapePathBuilder()..rect(0, 0, w, h)).build(),
          fill: fill,
        ),
      );
    }
    if (glyph == null) {
      // Neutral frame until the icon source knows the glyph.
      final inset = size * 0.12;
      out.add(
        PathNode(
          path:
              (ShapePathBuilder()..roundRect(
                    (w - size) / 2 + inset,
                    (h - size) / 2 + inset,
                    size - 2 * inset,
                    size - 2 * inset,
                    size * 0.15,
                  ))
                  .build(),
          stroke: NodeStroke(width: math.max(1, size / 24 * 2), color: color),
        ),
      );
      return out;
    }
    final run = TextRunBox(
      text: glyph.text,
      start: 0,
      x: 0,
      width: size,
      fontFamily: glyph.fontFamily,
      fontSize: size,
      color: color,
    );
    out.add(
      TextNode(
        elementId: e.id,
        layout: TextLayoutResult(
          width: size,
          height: size,
          lines: [
            TextLineBox(
              top: 0,
              baseline: size * 0.85,
              height: size,
              left: 0,
              width: size,
              start: 0,
              end: glyph.text.length,
              runs: [run],
            ),
          ],
        ),
        originX: (w - size) / 2,
        originY: (h - size) / 2,
      ),
    );
    return out;
  }

  // ---------------------------------------------------------------------
  // Code and charts

  /// The box shadow: the element's `box.shadow` (07 §3.1) or the theme's.
  NodeEffects? _codeShadow(ResolvedElement e) =>
      switch (CodeBoxStyle.fromJson(e.data?['box']).shadow ??
      theme.codeStyle.shadow) {
        'none' => null,
        'strong' => const NodeEffects(
          shadows: [NodeShadow(color: 0x59000000, dy: 16, blur: 40)],
        ),
        _ => const NodeEffects(
          shadows: [NodeShadow(color: 0x2e000000, dy: 8, blur: 24)],
        ),
      };

  List<SceneNode> _code(ResolvedElement e) {
    final w = e.frame.width, h = e.frame.height;
    final scene = (ctx.code ?? const BasicCodeLayout()).codeScene(
      e,
      ctx.deck,
      theme,
      width: w,
      height: h,
      purpose: ctx.purpose,
      stateIndex: ctx.purpose == ScenePurpose.edit
          ? ctx.codeStates[e.id]
          : null,
      step: ctx.purpose == ScenePurpose.edit ? ctx.codeSteps[e.id] : null,
      background: background,
    );
    if (scene == null) return const [];
    return [CodeNode(elementId: e.id, scene: scene, dst: SuRect(0, 0, w, h))];
  }

  List<SceneNode> _chart(ResolvedElement e) {
    final w = e.frame.width, h = e.frame.height;
    final scene = ctx.charts?.chartScene(
      e,
      ctx.deck,
      theme,
      width: w,
      height: h,
      background: background,
    );
    if (scene != null) {
      return [
        ChartNode(elementId: e.id, scene: scene, dst: SuRect(0, 0, w, h)),
      ];
    }
    // Placeholder: a soft card with three bars in the chart palette.
    final palette = theme.chartPalette;
    final out = <SceneNode>[
      PathNode(
        path: (ShapePathBuilder()..roundRect(0, 0, w, h, math.min(w, h) * 0.04))
            .build(),
        fill: ResolvedSolidFill(theme.colorOf('bg2') ?? 0xfff3f4f6),
      ),
    ];
    final bw = w * 0.14, gap = w * 0.08;
    final left = (w - 3 * bw - 2 * gap) / 2;
    for (final (i, frac) in [0.45, 0.75, 0.6].indexed) {
      final bh = h * 0.7 * frac;
      out.add(
        PathNode(
          path:
              (ShapePathBuilder()
                    ..rect(left + i * (bw + gap), h * 0.85 - bh, bw, bh))
                  .build(),
          fill: ResolvedSolidFill(
            palette.isEmpty ? 0xff6366f1 : palette[i % palette.length],
          ),
        ),
      );
    }
    return out;
  }

  // ---------------------------------------------------------------------
  // Tables

  (List<SceneNode>, double?) _table(ResolvedElement e) {
    final deck = ctx.deck;
    if (deck == null) return (const [], null);
    final ix = deck is DeckModel
        ? deck.indexes.table(e.id)
        : TableIndex.of(deck, e.id);
    return _TableLayout(this, e, ix).build();
  }
}

/// Lays out one table (02 §3.6, §6.5; 03 §6.6; 05 §2.8): column widths
/// from axis sizes (null = even split of the rest, scaled to the frame),
/// rows growing to fit their text, merges, theme areas, bands and borders.
final class _TableLayout {
  _TableLayout(this.b, this.e, this.ix, {this.cellText = const {}});

  final _Build b;
  final ResolvedElement e;
  final TableIndex ix;

  /// Bodies overriding stored cell text (`"<rowId>|<columnId>"`).
  final Map<String, String?> cellText;

  /// The grid of the last [build].
  TableGrid? grid;

  ResolvedTheme get theme => b.theme;

  (List<SceneNode>, double?) build() {
    final rows = ix.rows, cols = ix.columns;
    if (rows.isEmpty || cols.isEmpty) return (const [], null);
    final data = e.data ?? const <String, Object?>{};
    final styled = data['style'] != 'none';
    final options = data['options'] is Map
        ? (data['options'] as Map).cast<String, Object?>()
        : const <String, Object?>{};
    bool opt(String k, bool d) => options[k] is bool ? options[k] as bool : d;
    final headerRow = opt('headerRow', true);
    final firstColumn = opt('firstColumn', false);
    final bandedRows = opt('bandedRows', true);
    final bandedColumns = opt('bandedColumns', false);
    final totalRow = opt('totalRow', false);
    final ts = theme.tableStyle;
    final defaultPadding =
        _padding(data['defaultCellPadding']) ?? ts.cellPadding;
    final w = e.frame.width, h = e.frame.height;

    // Column widths.
    final colW = _distribute([for (final c in cols) c.size], w);
    // Minimum row heights.
    final rowMin = [for (final r in rows) r.size ?? h / rows.length];

    bool isHeader(int r) => (headerRow && r == 0) || rows[r].header;
    bool isTotal(int r) => totalRow && r == rows.length - 1 && r > 0;
    bool isFirstCol(int c) => (firstColumn && c == 0) || cols[c].header;

    TableAreaStyle? areaOf(int r, int c) {
      if (!styled) return null;
      if (isHeader(r)) return ts.header;
      if (isTotal(r)) return ts.totalRow;
      if (isFirstCol(c)) return ts.firstColumn;
      return ts.body;
    }

    int? fillOf(int r, int c, String? cellFill) {
      if (cellFill != null) return theme.colorString(cellFill);
      if (!styled) return null;
      if (isHeader(r) && ts.header.fill != null) {
        return theme.color(ts.header.fill!);
      }
      if (isTotal(r) && ts.totalRow.fill != null) {
        return theme.color(ts.totalRow.fill!);
      }
      final bodyRow = r - (headerRow ? 1 : 0);
      final bodyCol = c - (firstColumn ? 1 : 0);
      if (ts.bandFill != null &&
          ((bandedRows && bodyRow.isOdd) || (bandedColumns && bodyCol.isOdd))) {
        return theme.color(ts.bandFill!);
      }
      if (isFirstCol(c) && ts.firstColumn.fill != null) {
        return theme.color(ts.firstColumn.fill!);
      }
      return ts.body.fill == null ? null : theme.color(ts.body.fill!);
    }

    ResolvedTextStyles stylesOf(int r, int c) {
      final area = areaOf(r, c);
      final body = styled ? ts.body.text : null;
      final t = area?.text;
      final style = t?.style ?? body?.style ?? 'body2';
      final color = t?.color ?? body?.color;
      final weight = t?.weight ?? body?.weight;
      final defaults = <String, Object?>{
        'color': ?color?.json,
        'weight': ?weight,
      };
      return b.owner.textStyles.resolve(
        theme,
        box: BoxTextStyle(defaults: defaults),
        defaultStyle: style,
      );
    }

    // Cell content.
    final cells = <(int, int, int, int, _CellText?)>[]; // r, c, rs, cs
    final cellPads = <List<double>>[];
    final cellStyles = <ResolvedTextStyles>[];
    final rowNeed = [...rowMin];
    final spanNeeds = <(int, int, double)>[]; // first row, last row, need
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < cols.length; c++) {
        final m = ix.mergeAt(r, c);
        if (m != null && (m.row != r || m.column != c)) continue;
        final rs = m?.rowSpan ?? 1, cs = m?.colSpan ?? 1;
        final rec = ix.cellAt(r, c);
        final pad = _padding(rec?.padding) ?? defaultPadding;
        final cellW = _sum(colW, c, cs);
        _CellText? text;
        final key = '${rows[r].id}|${cols[c].id}';
        final body = TextBody.fromJson(
          cellText.containsKey(key) ? cellText[key] : rec?.text,
        );
        final styles = stylesOf(r, c);
        cellPads.add(pad);
        cellStyles.add(styles);
        if (!body.isBlank) {
          final layout = b.ctx.textLayout.layout(
            body,
            styles,
            width: math.max(1.0, cellW - pad[1] - pad[3]),
          );
          text = _CellText(layout, pad, rec?.vAlign ?? 'top');
          text.partId = key;
          final need = layout.height + pad[0] + pad[2];
          if (rs == 1) {
            rowNeed[r] = math.max(rowNeed[r], need);
          } else {
            spanNeeds.add((r, r + rs - 1, need));
          }
        }
        cells.add((r, c, rs, cs, text));
      }
    }
    for (final (first, last, need) in spanNeeds) {
      final have = _sum(rowNeed, first, last - first + 1);
      if (need > have) rowNeed[last] += need - have;
    }
    final colX = _prefix(colW);
    final rowY = _prefix(rowNeed);
    final totalH = rowY.last;
    grid = TableGrid(
      elementId: e.id,
      columnX: colX,
      rowY: rowY,
      rowIds: [for (final a in rows) a.id],
      columnIds: [for (final a in cols) a.id],
      cells: [
        for (final (i, (r, c, rs, cs, t)) in cells.indexed)
          TableGridCell(
            row: r,
            column: c,
            rowSpan: rs,
            colSpan: cs,
            rowId: rows[r].id,
            columnId: cols[c].id,
            x: colX[c],
            y: rowY[r],
            width: colX[c + cs] - colX[c],
            height: rowY[r + rs] - rowY[r],
            padding: cellPads[i],
            vAlign: ix.cellAt(r, c)?.vAlign ?? 'top',
            styles: cellStyles[i],
            layout: t?.layout,
          ),
      ],
    );

    final inner = <SceneNode>[];
    final text = <SceneNode>[];
    final lines = <SceneNode>[];
    for (final (r, c, rs, cs, t) in cells) {
      final x = colX[c], y = rowY[r];
      final cw = colX[c + cs] - x, ch = rowY[r + rs] - y;
      final rec = ix.cellAt(r, c);
      final fill = fillOf(r, c, rec?.fill);
      if (fill != null && (fill >>> 24) != 0) {
        inner.add(
          PathNode(
            path: (ShapePathBuilder()..rect(x, y, cw, ch)).build(),
            fill: ResolvedSolidFill(fill),
          ),
        );
      }
      if (t != null) {
        final avail = ch - t.pad[0] - t.pad[2];
        final free = avail - t.layout.height;
        final dy = switch (t.vAlign) {
          'middle' => free / 2,
          'bottom' => free,
          _ => 0.0,
        };
        text.add(
          TextNode(
            elementId: e.id,
            layout: t.layout,
            originX: x + t.pad[3],
            originY: y + t.pad[0] + dy,
            partId: t.partId,
          ),
        );
      }
      // Cell borders (override the theme's on their edges).
      if (rec != null) {
        void edge(String col, double x0, double y0, double x1, double y1) {
          final s = ScenePaint.border(
            theme,
            ScenePaint.parseBorder(rec.str(col)),
          );
          if (s == null) return;
          lines.add(
            PathNode(
              path:
                  (ShapePathBuilder()
                        ..moveTo(x0, y0)
                        ..lineTo(x1, y1))
                      .build(),
              stroke: s,
            ),
          );
        }

        edge(TableCellCols.borderTop, x, y, x + cw, y);
        edge(TableCellCols.borderRight, x + cw, y, x + cw, y + ch);
        edge(TableCellCols.borderBottom, x, y + ch, x + cw, y + ch);
        edge(TableCellCols.borderLeft, x, y, x, y + ch);
      }
    }

    // Theme borders.
    final themeLines = <SceneNode>[];
    if (styled) {
      final hs = ScenePaint.border(theme, ts.horizontalBorder);
      final vs = ScenePaint.border(theme, ts.verticalBorder);
      for (var r = 1; r < rows.length; r++) {
        final s = isTotal(r) && ts.totalRow.borderTop != null
            ? ScenePaint.border(theme, ts.totalRow.borderTop)
            : hs;
        if (s == null) continue;
        themeLines.add(_segments(r, true, s, colX, rowY, cols.length));
      }
      if (vs != null) {
        for (var c = 1; c < cols.length; c++) {
          themeLines.add(_segments(c, false, vs, colX, rowY, rows.length));
        }
      }
    }
    final radius = styled ? math.min(ts.radius, math.min(w, totalH) / 2) : 0.0;
    final clipPath = (ShapePathBuilder()..roundRect(0, 0, w, totalH, radius))
        .build();
    final out = <SceneNode>[
      GroupNode(
        clip: radius > 0 ? NodeClip.path(clipPath) : null,
        children: [...inner, ...themeLines, ...lines, ...text],
      ),
    ];
    final outer = styled ? ScenePaint.border(theme, ts.outerBorder) : null;
    if (outer != null) out.add(PathNode(path: clipPath, stroke: outer));
    final stroke = ScenePaint.stroke(theme, e.stroke);
    if (stroke != null) out.add(PathNode(path: clipPath, stroke: stroke));
    return (out, totalH);
  }

  /// The border between rows (or columns) [i] − 1 and [i], skipping the
  /// parts inside merged cells.
  SceneNode _segments(
    int i,
    bool horizontal,
    NodeStroke s,
    List<double> colX,
    List<double> rowY,
    int count,
  ) {
    final p = ShapePathBuilder();
    final at = horizontal ? rowY[i] : colX[i];
    for (var k = 0; k < count; k++) {
      final m = horizontal ? ix.mergeAt(i, k) : ix.mergeAt(k, i);
      final inside = m != null && (horizontal ? m.row < i : m.column < i);
      if (inside) continue;
      if (horizontal) {
        p
          ..moveTo(colX[k], at)
          ..lineTo(colX[k + 1], at);
      } else {
        p
          ..moveTo(at, rowY[k])
          ..lineTo(at, rowY[k + 1]);
      }
    }
    return PathNode(path: p.build(), stroke: s);
  }

  static List<double>? _padding(Object? raw) {
    List<double>? parse(List<Object?> l) =>
        l.length == 4 && l.every((v) => v is num)
        ? [for (final v in l) (v! as num).toDouble()]
        : null;
    if (raw is List) return parse(raw);
    if (raw is String) {
      final parts = raw.split(',').map((s) => double.tryParse(s.trim()));
      final list = parts.toList();
      if (list.length == 4 && list.every((v) => v != null)) {
        return [for (final v in list) v!];
      }
      if (raw.trim().startsWith('[')) {
        try {
          final v = jsonDecode(raw);
          if (v is List) return parse(v);
        } on FormatException {
          return null;
        }
      }
    }
    return null;
  }

  /// Sizes (null = even share of the rest) scaled to sum to [total].
  static List<double> _distribute(List<double?> sizes, double total) {
    final fixed = sizes.whereType<double>().fold(0.0, (a, b) => a + b);
    final free = sizes.where((s) => s == null).length;
    final rest = total - fixed;
    final share = free == 0 ? 0.0 : math.max(rest / free, total * 0.02);
    final raw = [for (final s in sizes) s ?? share];
    final sum = raw.fold(0.0, (a, b) => a + b);
    if (sum <= 0) return [for (final _ in sizes) total / sizes.length];
    return [for (final v in raw) v * total / sum];
  }

  static double _sum(List<double> v, int from, int count) {
    var s = 0.0;
    for (var i = from; i < from + count && i < v.length; i++) {
      s += v[i];
    }
    return s;
  }

  static List<double> _prefix(List<double> v) {
    final out = <double>[0];
    for (final x in v) {
      out.add(out.last + x);
    }
    return out;
  }
}

final class _CellText {
  _CellText(this.layout, this.pad, this.vAlign);

  final TextLayoutResult layout;
  final List<double> pad;
  final String vAlign;
  String? partId;
}

bool _sameNodes(List<SceneNode> a, List<SceneNode> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

/// The cached nodes of one element, most recently used last.
final class _Slots {
  static const capacity = 4;
  final Map<String, _CacheEntry> _entries = {};

  _CacheEntry? get(String key) {
    final hit = _entries.remove(key);
    if (hit != null) _entries[key] = hit;
    return hit;
  }

  void put(String key, _CacheEntry entry) {
    _entries.remove(key);
    _entries[key] = entry;
    if (_entries.length > capacity) _entries.remove(_entries.keys.first);
  }
}
