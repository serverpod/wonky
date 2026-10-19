/// The renderer-independent display list of a slide (02 §11 "Scene", 03
/// §1.1, 12 §5.4): built from a resolved slide by the `SlideSceneBuilder`
/// (SL-10) and drawn by the Flutter `SlideStage`, thumbnails, the PDF
/// renderer (10) and server PNG export; animated per element id by the
/// timeline (06).
///
/// Contract (SL-3). Naming deviation from the 12 §5.4 sketch: the nodes are
/// `GroupNode`, `PathNode`, … instead of `SGroup`, `SPath`, … because
/// `wonky_charts` exports `SGroup`/`SPath`/`SText`/`SClip`/`SStroke` and the
/// scene builder and PDF renderer import both. Paths reuse the chart
/// engine's `PathCmd`s, so path code (bounds, PDF/Flutter emitters) is
/// shared.
library;

import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:wonky_charts/wonky_charts.dart'
    show ChartScene, PathCmd, SStrokeCap, SStrokeJoin;

import '../../model/api/deck_reader.dart';
import '../../model/api/resolved.dart';
import '../../theme/model/common.dart';
import '../../theme/resolve/resolved_theme.dart';
import 'code_scene.dart';
import 'text_layout.dart';

/// A path in a node's local coordinates (su): the chart engine's commands
/// plus a fill rule.
final class ScenePath {
  /// Creates a path.
  const ScenePath(this.commands, {this.evenOdd = false});

  /// Move/line/cubic/close commands.
  final List<PathCmd> commands;

  /// Even-odd fill rule (else non-zero).
  final bool evenOdd;
}

/// Arrowhead styles of open paths (lines, connectors; 03 §6.4).
enum ArrowHead { none, triangle, open, stealth, diamond, oval }

/// A stroke with concrete values.
final class NodeStroke {
  /// Creates a stroke.
  const NodeStroke({
    required this.width,
    required this.color,
    this.dash = const [],
    this.cap = SStrokeCap.butt,
    this.join = SStrokeJoin.miter,
    this.startArrow = ArrowHead.none,
    this.endArrow = ArrowHead.none,
    this.arrowScale = 1,
  });

  /// Width (su).
  final double width;

  /// ARGB.
  final int color;

  /// Dash pattern (su, on/off pairs); empty = solid.
  final List<double> dash;
  final SStrokeCap cap;
  final SStrokeJoin join;
  final ArrowHead startArrow;
  final ArrowHead endArrow;

  /// Arrowhead size relative to the default (3 × width).
  final double arrowScale;
}

/// A drop shadow / glow with concrete values.
final class NodeShadow {
  /// Creates a shadow.
  const NodeShadow({
    required this.color,
    this.dx = 0,
    this.dy = 0,
    this.blur = 0,
    this.spread = 0,
  });

  /// ARGB.
  final int color;

  /// Offset (su).
  final double dx;

  /// Offset (su).
  final double dy;

  /// Blur radius (su).
  final double blur;

  /// Spread (su; glow).
  final double spread;
}

/// Effects of a node (02 §5.4) with concrete values.
final class NodeEffects {
  /// Creates effects.
  const NodeEffects({this.shadows = const [], this.blurSigma = 0});

  /// Shadows and glows, back to front.
  final List<NodeShadow> shadows;

  /// Layer blur (su).
  final double blurSigma;

  /// No effects.
  static const none = NodeEffects();
}

/// A clip in the node's local coordinates.
final class NodeClip {
  /// Clips to [rect].
  const NodeClip.rect(SuRect this.rect) : path = null;

  /// Clips to [path].
  const NodeClip.path(ScenePath this.path) : rect = null;

  /// The rectangle, or null.
  final SuRect? rect;

  /// The path, or null.
  final ScenePath? path;
}

/// A reference to image pixels: an uploaded file (`wonky-file://<uuid>`) or
/// a proxied URL. Bytes are fetched through `SlideImageSource`.
final class SlideImageRef {
  /// Creates a reference.
  const SlideImageRef(this.src, {this.naturalWidth, this.naturalHeight});

  /// `wonky-file://<uuid>` or `https://…` (image proxy).
  final String src;

  /// Natural size in pixels, when known.
  final int? naturalWidth;

  /// Natural size in pixels, when known.
  final int? naturalHeight;

  /// The uploaded file UUID, or null for URLs.
  String? get fileUuid =>
      src.startsWith(fileScheme) ? src.substring(fileScheme.length) : null;

  /// The scheme of uploaded files.
  static const fileScheme = 'wonky-file://';

  @override
  bool operator ==(Object other) => other is SlideImageRef && other.src == src;

  @override
  int get hashCode => src.hashCode;
}

/// A node of a [SlideScene]. Nodes of elements carry the element id so the
/// timeline can animate them and the stage can cache them per element.
sealed class SceneNode {
  const SceneNode({this.elementId});

  /// The element this node draws, or null for decorations (backgrounds,
  /// selection-free chrome).
  final String? elementId;
}

/// A group with a transform (su), opacity and optional clip.
final class GroupNode extends SceneNode {
  /// Creates a group.
  GroupNode({
    super.elementId,
    Matrix4? transform,
    this.opacity = 1,
    this.clip,
    this.effects = NodeEffects.none,
    required this.children,
  }) : transform = transform ?? Matrix4.identity();

  /// Local → parent transform (rotation about the frame center, flips,
  /// group child space).
  final Matrix4 transform;

  /// Opacity 0..1 multiplied into the children.
  final double opacity;
  final NodeClip? clip;
  final NodeEffects effects;
  final List<SceneNode> children;
}

/// A filled and/or stroked path (shapes, lines, connectors, table borders,
/// icons).
final class PathNode extends SceneNode {
  /// Creates a path node.
  const PathNode({
    super.elementId,
    required this.path,
    this.fill,
    this.stroke,
    this.effects = NodeEffects.none,
  });

  final ScenePath path;
  final ResolvedFill? fill;
  final NodeStroke? stroke;
  final NodeEffects effects;
}

/// An image drawn from [src] (pixels) into [dst] (su), with optional color
/// matrix (adjustments, 02 §6.4) and mask path.
final class ImageNode extends SceneNode {
  /// Creates an image node.
  const ImageNode({
    super.elementId,
    required this.image,
    required this.src,
    required this.dst,
    this.colorMatrix,
    this.mask,
    this.blurSigma = 0,
  });

  final SlideImageRef image;

  /// Source rectangle in image pixels (crop).
  final SuRect src;

  /// Destination rectangle (su).
  final SuRect dst;

  /// 4×5 row-major color matrix (20 values), or null.
  final List<double>? colorMatrix;
  final ScenePath? mask;
  final double blurSigma;
}

/// Laid-out text: positioned lines and runs (`TextLayoutEngine`).
final class TextNode extends SceneNode {
  /// Creates a text node at [origin] (top-left of the text box, su).
  const TextNode({
    super.elementId,
    required this.layout,
    this.originX = 0,
    this.originY = 0,
    this.partId,
  });

  final TextLayoutResult layout;
  final double originX;
  final double originY;

  /// Which body of the element this is when it has several (table cells:
  /// `"<rowId>|<columnId>"`, SL-15), else null.
  final String? partId;
}

/// A chart sub-scene (`wonky_charts`, 08) drawn into [dst].
final class ChartNode extends SceneNode {
  /// Creates a chart node.
  const ChartNode({super.elementId, required this.scene, required this.dst});

  final ChartScene scene;
  final SuRect dst;
}

/// A code sub-scene (07) drawn into [dst].
final class CodeNode extends SceneNode {
  /// Creates a code node.
  const CodeNode({super.elementId, required this.scene, required this.dst});

  final CodeScene scene;
  final SuRect dst;
}

/// An empty placeholder's prompt ("Click to add title"): editor only, never
/// presented or exported.
final class PromptNode extends SceneNode {
  /// Creates a prompt node.
  const PromptNode({
    super.elementId,
    required this.text,
    required this.box,
    this.layout,
    this.originX = 0,
    this.originY = 0,
  });

  final String text;

  /// The text area the prompt stands for (dashed outline, element-local).
  final SuRect box;

  /// The prompt laid out with the placeholder's text styles (SL-10), drawn
  /// muted; null = renderers pick a default style.
  final TextLayoutResult? layout;

  /// Origin of [layout] (element-local su).
  final double originX;

  /// Origin of [layout] (element-local su).
  final double originY;
}

/// The display list of one slide (or layout/master preview) in su.
final class SlideScene {
  /// Creates a scene.
  const SlideScene({
    required this.slideId,
    required this.width,
    required this.height,
    required this.background,
    required this.nodes,
    this.frames = const {},
    this.routes = const {},
  });

  /// The slide (or layout/master) id.
  final String slideId;

  /// Slide size (su).
  final double width;

  /// Slide size (su).
  final double height;

  /// The resolved background.
  final ResolvedBackground background;

  /// Nodes back to front: master/layout decorations, then slide elements.
  final List<SceneNode> nodes;

  /// Derived frames (SL-10) of elements drawn larger or smaller than their
  /// stored frame: `autofit: resize` text, auto-width text boxes
  /// (`wrap: false`), tables whose rows grew to fit their text. Selection
  /// chrome and hit testing use these (03 §6.1 "the selection box
  /// follows").
  final Map<String, SuRect> frames;

  /// Derived routes of lines and connectors by element id (slide space;
  /// polyline points, or start/control/control/end for curves), for
  /// endpoint handles and hit testing (03 §6.4).
  final Map<String, List<({double x, double y})>> routes;

  /// The effective frame of [element] (derived or stored).
  SuRect frameOf(ResolvedElement element) =>
      frames[element.id] ?? element.frame;

  /// Every node of [elementId] (top-level and nested), in paint order.
  Iterable<SceneNode> nodesOf(String elementId) sync* {
    Iterable<SceneNode> walk(List<SceneNode> list) sync* {
      for (final n in list) {
        if (n.elementId == elementId) yield n;
        if (n is GroupNode) yield* walk(n.children);
      }
    }

    yield* walk(nodes);
  }
}

/// What a scene is built for (06 §9.6): the edit frame differs from
/// thumbnails and the print frame in code states and prompts.
enum ScenePurpose {
  /// The editor canvas (prompts of empty placeholders when [SceneContext.
  /// editing]; code shows the state selected in the inspector).
  edit,

  /// Navigator, grid, Drive thumbnails (code: last state).
  thumbnail,

  /// Presenting (the timeline animates on top).
  present,

  /// PDF without builds: the print frame (code: last state, no dimming).
  print,
}

/// A glyph of an icon font (Lucide) or an emoji, drawn as text.
final class IconGlyph {
  /// Creates a glyph.
  const IconGlyph(this.fontFamily, this.text);

  /// The font family (Flutter asset family, e.g. `packages/…/Lucide400`).
  final String fontFamily;

  /// The glyph's characters.
  final String text;
}

/// Maps `icon` elements (02 §6.6) to glyphs. The app supplies the Lucide
/// map (SL-14); without one, icons draw a neutral frame.
abstract interface class SlideIconSource {
  /// The glyph of Lucide icon [name] at [strokeWidth] (1–3), or null.
  IconGlyph? lucide(String name, double strokeWidth);

  /// The emoji font family, or null for the platform default.
  String? get emojiFamily;
}

/// Lays out chart elements (08): the chart engine's scene for a chart
/// element at [width] × [height] su, or null to draw a placeholder.
/// Supplied by the chart link core (SL-27: `SlideChartLayout`) and the
/// app's text measurer.
abstract interface class ChartSceneSource {
  /// The chart scene of [element]. [background] is the effective slide
  /// background behind the element (ARGB; automatic chart text and line
  /// colors resolve against it, 08 §3.5), null when unknown. The scene may
  /// be in its own units (chart px): `ChartNode` scales it into its `dst`.
  ChartScene? chartScene(
    ResolvedElement element,
    DeckReader? deck,
    ResolvedTheme theme, {
    required double width,
    required double height,
    int? background,
  });
}

/// Lays out code elements (07). The core's implementation is SL-26's
/// `CodeElementLayout` (`CodeElementModel` + `CodeSceneComposer`).
abstract interface class CodeSceneSource {
  /// The code scene of [element] in [stateIndex] (null = per purpose:
  /// thumbnails and the print frame show the last state, otherwise the
  /// first) with highlight [step] (0-based, null = none). [background] is
  /// the effective slide background behind the element (ARGB; `auto`
  /// palettes pick light or dark by it, 07 §2.5), null when unknown.
  CodeScene? codeScene(
    ResolvedElement element,
    DeckReader? deck,
    ResolvedTheme theme, {
    required double width,
    required double height,
    required ScenePurpose purpose,
    int? stateIndex,
    int? step,
    int? background,
  });
}

/// What a scene builder needs besides the resolved element (03 §1.3):
/// the resolved theme, the text layout
/// engine and whether editor-only nodes (prompts) are wanted.
///
/// SL-10 added (additive): [deck] (tables, code states, chart links),
/// [purpose], [icons], [charts], [code], [codeStates].
final class SceneContext {
  /// Creates a context.
  const SceneContext({
    required this.theme,
    required this.textLayout,
    this.editing = false,
    this.deck,
    this.purpose = ScenePurpose.edit,
    this.icons,
    this.charts,
    this.code,
    this.codeStates = const {},
    this.codeSteps = const {},
    this.generation = 0,
  });

  /// The deck theme resolved for the deck appearance.
  final ResolvedTheme theme;

  /// The text layout engine (Flutter in the app, core on the server).
  final TextLayoutEngine textLayout;

  /// Editor rendering: prompts of empty placeholders are drawn.
  final bool editing;

  /// The deck (table axes and cells, code states, chart links).
  final DeckReader? deck;

  /// What the scene is for.
  final ScenePurpose purpose;

  /// Icon glyphs.
  final SlideIconSource? icons;

  /// Chart scenes.
  final ChartSceneSource? charts;

  /// Code scenes (null = the core's basic layout).
  final CodeSceneSource? code;

  /// Code state shown per element in the edit frame (inspector choice).
  final Map<String, int> codeStates;

  /// Highlight step (0-based) previewed per code element in the edit frame
  /// (the inspector's selected line step, SL-31).
  final Map<String, int> codeSteps;

  /// An opaque counter that invalidates cached element nodes when
  /// something outside the deck changes their layout (bundled fonts
  /// finished loading, 05 §3.3).
  final int generation;

  /// A copy with [theme] replaced (slides of another theme in one deck).
  SceneContext withTheme(ResolvedTheme theme) => identical(theme, this.theme)
      ? this
      : SceneContext(
          theme: theme,
          textLayout: textLayout,
          editing: editing,
          deck: deck,
          purpose: purpose,
          icons: icons,
          charts: charts,
          code: code,
          codeStates: codeStates,
          codeSteps: codeSteps,
          generation: generation,
        );
}
