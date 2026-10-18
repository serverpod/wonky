import 'dart:convert';
import 'dart:math' as math;

import '../../theme/builtins/builtin_themes.dart';
import '../../theme/json/json_util.dart';
import '../../theme/layout/placeholder_resolver.dart' show EffectivePlaceholder;
import '../../theme/layout/placeholder_type.dart';
import '../../theme/model/background.dart';
import '../../theme/model/common.dart';
import '../../theme/model/deck_theme_data.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../../theme/resolve/theme_resolver.dart';
import '../../theme/schema/validator.dart';
import '../api/deck_model.dart';
import '../api/kinds.dart';
import '../api/records.dart';
import '../api/resolved.dart';
import '../geometry/frame_math.dart';
import '../index/deck_indexes.dart';
import '../index/element_tree.dart';
import '../../schema/slides_schema.dart';
import '../text/slides_text.dart';
import 'text_style_resolver.dart';

/// A slide with everything it renders from resolved (02 §11): theme for
/// the deck appearance, background, master/layout decorations, field
/// placeholders and the slide's elements with effective geometry and style.
final class ResolvedSlide {
  /// Creates a resolved slide.
  const ResolvedSlide({
    required this.slide,
    required this.bounds,
    required this.theme,
    required this.background,
    required this.masterElements,
    required this.layoutElements,
    required this.elements,
    required this.hideMasterElements,
    required this.skipped,
    this.layout,
    this.master,
    this.themeRecord,
    this.number,
    this.surface = ElementOwnerKind.slide,
  });

  /// What this resolves (SL-28): a slide, or a layout or master drawn as
  /// its editing surface in master mode (05 §8.1). For a surface, [slide]
  /// is a synthetic row with the layout's/master's id (`layoutId` set for
  /// layouts), [elements] are the owner's own elements including its
  /// placeholder definitions, [masterElements] the master's decorations
  /// (and the master's field placeholders the layout doesn't redefine) for
  /// a layout, and [layoutElements] is empty.
  final ElementOwnerKind surface;

  /// Whether this is a layout or master surface (not a slide).
  bool get isSurface => surface != ElementOwnerKind.slide;

  /// The slide row.
  final SlideRec slide;

  /// The slide rectangle (`0, 0, Deck.width, Deck.height`).
  final SuRect bounds;

  /// The effective layout (02 §10 fallback), or null.
  final SlideLayoutRec? layout;

  /// The layout's master, or null.
  final SlideMasterRec? master;

  /// The theme row, or null when the deck has no theme (the built-in
  /// default is used in memory, 02 §10).
  final DeckThemeRec? themeRecord;

  /// The theme resolved for the deck appearance.
  final ResolvedTheme theme;

  /// The effective background (slide ▸ layout ▸ master ▸ theme).
  final ResolvedBackground background;

  /// Master decorations and visible field placeholders, back to front
  /// (empty when master elements are hidden).
  final List<ResolvedElement> masterElements;

  /// Layout decorations (non-placeholder elements), back to front.
  final List<ResolvedElement> layoutElements;

  /// The slide's own elements (tree), back to front.
  final List<ResolvedElement> elements;

  /// Whether master elements are hidden (slide ▸ layout setting).
  final bool hideMasterElements;

  /// Effective skip.
  final bool skipped;

  /// Slide number (null for skipped slides).
  final int? number;

  /// Every drawn element in painting order (master, layout, slide; group
  /// children after their group).
  Iterable<ResolvedElement> get painted sync* {
    Iterable<ResolvedElement> walk(List<ResolvedElement> l) sync* {
      for (final e in l) {
        yield e;
        yield* walk(e.children);
      }
    }

    yield* walk(masterElements);
    yield* walk(layoutElements);
    yield* walk(elements);
  }

  /// The slide element [id] (any depth), or null.
  ResolvedElement? element(String id) {
    ResolvedElement? find(List<ResolvedElement> l) {
      for (final e in l) {
        if (e.id == id) return e;
        final c = find(e.children);
        if (c != null) return c;
      }
      return null;
    }

    return find(elements);
  }
}

/// Resolves slides (02 §11 `SlideResolver`), memoized per slide revision
/// (`DeckIndexes.revision`: a change to the slide's layout, master or
/// theme or to a render-relevant deck column invalidates it) and
/// appearance.
///
/// Resolved elements keep their identity across resolutions (CQ-43): an
/// element whose inputs are unchanged — its row, the rows of its
/// placeholder chain, the theme, the slide bounds and its group context —
/// resolves to the identical [ResolvedElement], so the scene builder's node
/// cache and the stage's per-element repaint boundaries survive edits of
/// other elements. Master and layout decorations are shared by every slide
/// that draws them.
final class SlideResolver {
  /// Creates a resolver over [model].
  SlideResolver(
    this.model, {
    DeckThemeResolver? themes,
    TextStyleResolver? textStyles,
  }) : themeResolver = themes ?? DeckThemeResolver(),
       textStyles = textStyles ?? TextStyleResolver();

  /// The deck.
  final DeckModel model;

  /// Theme resolution (shared LRU cache).
  final DeckThemeResolver themeResolver;

  /// Text style resolution.
  final TextStyleResolver textStyles;

  final Map<String, (String, ResolvedSlide)> _memo = {};

  /// Resolved elements by `<id>|<inherited>|<appearance>` (and field
  /// placeholders by their own keys), reused while their inputs match.
  final Map<String, _ElementMemo> _elements = {};
  int _pruneAt = 4096;

  /// Resolved elements created (memo misses) so far (tests).
  int debugElementResolves = 0;

  static final Expando<DeckThemeData> _themeData = Expando('deckThemeData');

  DeckIndexes get _ix => model.indexes;

  /// The theme data of [rec] (cached per record; an invalid row falls back
  /// to the built-in default theme).
  static DeckThemeData themeDataOf(DeckThemeRec? rec) {
    if (rec == null) return _fallbackTheme;
    return _themeData[rec] ??= () {
      try {
        return deckThemeFromColumns({
          'name': rec.name,
          'sourceKey': rec.sourceKey,
          ...rec.themeColumns,
        });
      } on FormatException {
        return _fallbackTheme;
      }
    }();
  }

  static final DeckThemeData _fallbackTheme = BuiltInThemes.package(
    BuiltInThemes.defaultKey,
  )!.theme;

  /// The theme [rec] resolved for [appearance] (null rec = the built-in
  /// default, 02 §10).
  ResolvedTheme resolveTheme(DeckThemeRec? rec, SlideAppearance appearance) =>
      themeResolver.resolve(themeDataOf(rec), appearance);

  /// The slide rectangle.
  SuRect get bounds {
    final d = model.deck;
    return SuRect(0, 0, d?.width ?? 1920, d?.height ?? 1080);
  }

  /// Resolves [slideId] for [appearance] (null = the deck's), or null when
  /// the slide doesn't exist. A layout or master id resolves as its
  /// editing surface (SL-28, [ResolvedSlide.surface]; 05 §8.1), so the
  /// canvas, thumbnails and text editing work on layouts and masters too.
  ResolvedSlide? resolve(String slideId, {SlideAppearance? appearance}) {
    final slide = model.slide(slideId);
    final layout = slide == null ? model.layout(slideId) : null;
    final master = slide == null && layout == null
        ? model.master(slideId)
        : null;
    if (slide == null && layout == null && master == null) return null;
    final app = appearance ?? model.deck?.appearance ?? SlideAppearance.light;
    final rev = '${_ix.revision(slideId)}/${app.name}';
    final hit = _memo[slideId];
    if (hit != null && hit.$1 == rev) return hit.$2;
    final r = slide != null
        ? _resolve(slide, app)
        : _resolveSurface(layout, master ?? _ix.themes.masterOf(layout!), app);
    if (r == null) return null;
    _memo[slideId] = (rev, r);
    if (_elements.length > _pruneAt) _prune();
    return r;
  }

  /// Drops memoized elements whose row changed or is gone.
  void _prune() {
    _elements.removeWhere((_, m) => !identical(model.element(m.id), m.record));
    _pruneAt = math.max(4096, _elements.length * 2);
  }

  /// [build]'s element, or the memoized one of [key] when [inputs] are
  /// the same (identical objects, equal values).
  ResolvedElement _memoized(
    String key,
    SlideElementRec record,
    List<Object?> inputs,
    ResolvedElement Function() build,
  ) {
    final hit = _elements[key];
    if (hit != null &&
        identical(hit.record, record) &&
        _sameInputs(hit.inputs, inputs)) {
      return hit.value;
    }
    debugElementResolves++;
    final value = build();
    _elements[key] = _ElementMemo(record, inputs, value);
    return value;
  }

  static bool _sameInputs(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (identical(x, y)) continue;
      // Values (frames, numbers, strings, records of them) compare by
      // value; rows, themes and resolved elements by identity.
      if (x is SlidesRecord ||
          x is ResolvedTheme ||
          x is ResolvedElement ||
          x is List) {
        return false;
      }
      if (x != y) return false;
    }
    return true;
  }

  /// A layout ([layout] non-null) or master surface (05 §8.1).
  ResolvedSlide? _resolveSurface(
    SlideLayoutRec? layout,
    SlideMasterRec? master,
    SlideAppearance app,
  ) {
    final ownerId = layout?.id ?? master?.id;
    if (ownerId == null) return null;
    final ix = _ix;
    final themeRec =
        (master == null ? null : ix.themes.themeOf(master)) ??
        model.defaultTheme;
    final theme = resolveTheme(themeRec, app);
    SlideBackground? bg(String? json) {
      final m = _decode(json);
      return m == null ? null : SlideBackground.fromJson(m, IssueSink());
    }

    final background =
        bg(layout?.backgroundJson) ??
        bg(master?.backgroundJson) ??
        themeDataOf(themeRec).background;
    final hideMaster = layout?.hideMasterElements ?? false;
    final deck = model.deck;
    String? fieldOf(SlidePlaceholderType? t) => switch (t) {
      SlidePlaceholderType.slideNumber => '‹#›',
      SlidePlaceholderType.footer => deck?.footerText ?? '',
      _ => null,
    };
    ResolvedElement withField(ResolvedElement e) {
      final field = e.parentId == null ? fieldOf(e.placeholderType) : null;
      if (field == null) return e;
      return _memoized(
        'field|surface|${e.id}|${e.inherited}|${app.name}',
        e.record,
        [e, field],
        () => ResolvedElement(
          record: e.record,
          frame: e.frame,
          rotation: e.rotation,
          flipH: e.flipH,
          flipV: e.flipV,
          opacity: e.opacity,
          inherited: e.inherited,
          children: e.children,
          placeholderType: e.placeholderType,
          dangling: e.dangling,
          fill: e.fill,
          stroke: e.stroke,
          effects: e.effects,
          data: e.data,
          textStyle: e.textStyle,
          styleKey: e.styleKey,
          textStyles: e.textStyles,
          prompt: e.prompt,
          fieldText: field,
          parentId: e.parentId,
        ),
      );
    }

    final masterElements = <ResolvedElement>[];
    if (layout != null && master != null && !hideMaster) {
      final own = {
        for (final p in ix.placeholders.placeholdersOf(layout.id))
          p.placeholderType,
      };
      masterElements.addAll(
        _resolveTree(
          ix.tree(master.id),
          theme,
          null,
          inherited: true,
          include: (e) {
            final t = e.placeholderType;
            return t == null || (fieldOf(t) != null && !own.contains(t));
          },
        ).map(withField),
      );
    }
    final elements = _resolveTree(
      ix.tree(ownerId),
      theme,
      null,
      inherited: false,
      include: (_) => true,
    ).map(withField).toList();
    return ResolvedSlide(
      slide: SlideRec({
        SlidesCols.id: ownerId,
        if (layout != null) SlideCols.layoutId: layout.id,
      }),
      bounds: bounds,
      layout: layout,
      master: master,
      themeRecord: themeRec,
      theme: theme,
      background: theme.background(background),
      masterElements: masterElements,
      layoutElements: const [],
      elements: elements,
      hideMasterElements: hideMaster,
      skipped: false,
      surface: layout != null
          ? ElementOwnerKind.layout
          : ElementOwnerKind.master,
    );
  }

  /// Resolves a layout or master [ownerId] as drawn in master mode (05 §8):
  /// its elements including placeholder definitions.
  List<ResolvedElement> resolveOwner(
    String ownerId, {
    SlideAppearance? appearance,
  }) {
    final app = appearance ?? model.deck?.appearance ?? SlideAppearance.light;
    final layout = model.layout(ownerId);
    final master = layout == null
        ? model.master(ownerId)
        : _ix.themes.masterOf(layout);
    final themeRec = master == null ? null : _ix.themes.themeOf(master);
    final theme = resolveTheme(themeRec ?? model.defaultTheme, app);
    return _resolveTree(
      _ix.tree(ownerId),
      theme,
      null,
      inherited: false,
      include: (_) => true,
    );
  }

  ResolvedSlide _resolve(SlideRec slide, SlideAppearance app) {
    final ix = _ix;
    final layout = ix.themes.effectiveLayout(slide);
    final master = layout == null ? null : ix.themes.masterOf(layout);
    final themeRec =
        (master == null ? null : ix.themes.themeOf(master)) ??
        model.defaultTheme;
    final theme = resolveTheme(themeRec, app);
    final entry = ix.order.entry(slide.id);

    SlideBackground? bg(String? json) {
      final m = _decode(json);
      return m == null ? null : SlideBackground.fromJson(m, IssueSink());
    }

    final background =
        bg(slide.backgroundJson) ??
        bg(layout?.backgroundJson) ??
        bg(master?.backgroundJson) ??
        themeDataOf(themeRec).background;
    final hideMaster =
        slide.hideMasterElements ?? layout?.hideMasterElements ?? false;

    bool decoration(SlideElementRec e) => e.placeholderType == null;

    final masterElements = <ResolvedElement>[
      if (!hideMaster && master != null)
        ..._resolveTree(
          ix.tree(master.id),
          theme,
          null,
          inherited: true,
          include: decoration,
        ),
      if (!hideMaster && layout != null)
        ..._fields(slide, layout, theme, entry?.number),
    ];
    final layoutElements = layout == null
        ? const <ResolvedElement>[]
        : _resolveTree(
            ix.tree(layout.id),
            theme,
            null,
            inherited: true,
            include: decoration,
          );
    final elements = _resolveTree(
      ix.tree(slide.id),
      theme,
      slide.id,
      inherited: false,
      include: (_) => true,
    );
    return ResolvedSlide(
      slide: slide,
      bounds: bounds,
      layout: layout,
      master: master,
      themeRecord: themeRec,
      theme: theme,
      background: theme.background(background),
      masterElements: masterElements,
      layoutElements: layoutElements,
      elements: elements,
      hideMasterElements: hideMaster,
      skipped: entry?.skipped ?? slide.skipped,
      number: entry?.number,
    );
  }

  /// Slide number and footer placeholders (05 §5.5) from the layout, else
  /// the master.
  List<ResolvedElement> _fields(
    SlideRec slide,
    SlideLayoutRec layout,
    ResolvedTheme theme,
    int? number,
  ) {
    final deck = model.deck;
    if (deck == null) return const [];
    final out = <ResolvedElement>[];
    final box = bounds;
    void add(SlidePlaceholderType type, String text) {
      final def = _ix.placeholders.layoutPlaceholder(layout.id, type);
      if (def == null) return;
      final r = _element(def, theme, box, inherited: true);
      out.add(
        _memoized(
          'field|${slide.id}|${type.name}|${theme.appearance.name}',
          def,
          [r, text],
          () => ResolvedElement(
            record: r.record,
            frame: r.frame,
            rotation: r.rotation,
            opacity: r.opacity,
            inherited: true,
            placeholderType: type,
            fill: r.fill,
            stroke: r.stroke,
            effects: r.effects,
            data: r.data,
            textStyle: r.textStyle,
            styleKey: r.styleKey,
            textStyles: r.textStyles,
            fieldText: text,
          ),
        ),
      );
    }

    final hideNumber =
        number == null ||
        !deck.showSlideNumbers ||
        (deck.hideNumberOnTitle && layout.key == 'title');
    if (!hideNumber) add(SlidePlaceholderType.slideNumber, '$number');
    final footer = deck.footerText;
    if (footer != null && footer.isNotEmpty) {
      add(SlidePlaceholderType.footer, footer);
    }
    return out;
  }

  List<ResolvedElement> _resolveTree(
    ElementTree tree,
    ResolvedTheme theme,
    String? slideId, {
    required bool inherited,
    required bool Function(SlideElementRec) include,
  }) {
    final box = bounds;
    List<ResolvedElement> level(
      String? parent,
      ElementFrame Function(ElementFrame)? toSlide,
      double parentOpacity,
      Object? context,
    ) => [
      for (final e in tree.childrenOf(parent))
        if (parent != null || include(e))
          _element(
            e,
            theme,
            box,
            inherited: inherited,
            parent: parent,
            toSlide: toSlide,
            parentOpacity: parentOpacity,
            context: context,
            children: level,
          ),
    ];

    return level(null, null, 1, null);
  }

  /// Resolves [e] in its group context (memoized, see [SlideResolver]):
  /// [toSlide] maps its local frame to slide space, [parentOpacity] is the
  /// product of its ancestors' opacities and [context] describes both for
  /// the memo (null at the top level). [children] resolves a group's
  /// children.
  ResolvedElement _element(
    SlideElementRec e,
    ResolvedTheme theme,
    SuRect bounds, {
    required bool inherited,
    String? parent,
    ElementFrame Function(ElementFrame)? toSlide,
    double parentOpacity = 1,
    Object? context,
    List<ResolvedElement> Function(
      String parent,
      ElementFrame Function(ElementFrame) toSlide,
      double parentOpacity,
      Object? context,
    )?
    children,
  }) {
    final eff = _ix.placeholders.effective(e, bounds: bounds);
    final opacity = eff.opacity.clamp(0, 1).toDouble();
    final localFrame = ElementFrame.of(
      eff.frame,
      rotation: normalizeRotation(eff.rotation),
      flipH: e.flipH,
      flipV: e.flipV,
    );
    var kids = const <ResolvedElement>[];
    if (e.kind == ElementKind.group && children != null) {
      final cb = childBoundsOf(eff.data) ?? eff.frame;
      ElementFrame map(ElementFrame c) {
        final inParent = GroupSpace.toParent(c, localFrame, cb);
        return toSlide == null ? inParent : toSlide(inParent);
      }

      kids = children(e.id, map, parentOpacity * opacity, (
        context,
        localFrame,
        cb,
        parentOpacity * opacity,
      ));
    }
    return _memoized(
      '${e.id}|$inherited|${theme.appearance.name}',
      e,
      [
        theme,
        bounds,
        parent,
        context,
        parentOpacity,
        eff.chain.length,
        for (final id in eff.chain.skip(1)) model.element(id),
        kids.length,
        ...kids,
      ],
      () {
        final f = toSlide == null ? localFrame : toSlide(localFrame);
        final local = _resolveOne(e, theme, eff);
        return ResolvedElement(
          record: e,
          frame: f.rect,
          rotation: f.rotation,
          flipH: f.flipH,
          flipV: f.flipV,
          opacity: parentOpacity * opacity,
          inherited: inherited,
          children: kids,
          placeholderType: local.placeholderType,
          dangling: local.dangling,
          fill: local.fill,
          stroke: local.stroke,
          effects: local.effects,
          data: local.data,
          textStyle: local.textStyle,
          styleKey: local.styleKey,
          textStyles: local.textStyles,
          prompt: local.prompt,
          parentId: parent,
        );
      },
    );
  }

  /// The element-local values of [e] from its placeholder chain [eff].
  ResolvedElement _resolveOne(
    SlideElementRec e,
    ResolvedTheme theme,
    EffectivePlaceholder eff,
  ) {
    final holdsText = e.kind.hasText || (e.placeholderType?.holdsText ?? false);
    String? prompt;
    if (e.placeholderType != null &&
        e.slideId != null &&
        SlidesText.isBlank(e.text)) {
      for (final id in eff.chain.skip(1)) {
        final def = model.element(id);
        if (def != null && !SlidesText.isBlank(def.text)) {
          prompt = SlidesText.plainText(def.text).trimRight();
          break;
        }
      }
    }
    return ResolvedElement(
      record: e,
      frame: eff.frame,
      rotation: normalizeRotation(eff.rotation),
      flipH: e.flipH,
      flipV: e.flipV,
      opacity: eff.opacity.clamp(0, 1).toDouble(),
      inherited: false,
      placeholderType: eff.type,
      dangling: eff.dangling,
      fill: eff.fill,
      stroke: eff.stroke,
      effects: eff.effects,
      data: eff.data,
      textStyle: eff.textStyle,
      styleKey: eff.styleKey,
      textStyles: holdsText
          ? textStyles.resolve(
              theme,
              box: eff.textStyle,
              defaultStyle: eff.styleKey,
            )
          : null,
      prompt: prompt,
    );
  }

  /// The `childBounds` of a group payload (02 §6.9), or null.
  static SuRect? childBoundsOf(JsonMap? data) {
    final cb = data?['childBounds'];
    if (cb is! Map) return null;
    final x = cb['x'], y = cb['y'], w = cb['w'], h = cb['h'];
    if (x is! num || y is! num || w is! num || h is! num) return null;
    if (w <= 0 || h <= 0) return null;
    return SuRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  }

  static JsonMap? _decode(String? json) {
    if (json == null) return null;
    try {
      final v = jsonDecode(json);
      return v is Map<String, Object?> ? v : null;
    } on FormatException {
      return null;
    }
  }
}

/// A memoized resolved element and the inputs it was resolved from.
final class _ElementMemo {
  _ElementMemo(this.record, this.inputs, this.value);

  final SlideElementRec record;
  final List<Object?> inputs;
  final ResolvedElement value;

  String get id => record.id;
}
