/// `ThemeResolver`: `WriteThemeData` → `ResolvedWriteTheme` (06 §3).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:wonky_fonts/wonky_fonts.dart';
import '../model/color_ref.dart';
import '../model/json_util.dart';
import '../model/length.dart';
import '../model/properties.dart';
import '../model/style_enums.dart';
import '../model/syntax_token.dart';
import '../model/values.dart';
import '../model/write_theme_data.dart';
import 'base_theme.dart';
import 'dark_palette_deriver.dart';
import 'oklch.dart';
import 'resolved_theme.dart';

/// Resolves themes into concrete, renderer-ready values.
abstract interface class ThemeResolver {
  /// A shared memoizing resolver.
  static final ThemeResolver instance = WriteThemeResolver();

  /// Resolves [theme] for [variant]; memoized by `(contentHash, variant)`.
  ResolvedWriteTheme resolve(WriteThemeData theme, ThemeVariant variant);
}

/// The default [ThemeResolver]: deterministic and pure, with an LRU cache of
/// [capacity] results keyed by `(theme.contentHash, variant)`.
///
/// Cascade (06 §3), per variant:
/// `base (Wonky Default) → theme.elements → dark.elements` (dark only);
/// headings layer `headings` below `h1…h6` at each level; text properties
/// an element does not set inherit from the resolved body bag (code blocks
/// only inherit `color`/`lineHeight`); inline elements are deltas.
final class WriteThemeResolver implements ThemeResolver {
  /// Creates a resolver.
  WriteThemeResolver({this.capacity = 32});

  /// Maximum number of cached results.
  final int capacity;

  final _cache = <(String, ThemeVariant), ResolvedWriteTheme>{};

  @override
  ResolvedWriteTheme resolve(WriteThemeData theme, ThemeVariant variant) {
    final key = (theme.contentHash, variant);
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit;
      return hit;
    }
    final resolved = _Resolution(theme, variant).build();
    _cache[key] = resolved;
    while (_cache.length > capacity) {
      _cache.remove(_cache.keys.first);
    }
    return resolved;
  }

  /// Number of cached results.
  int get cacheSize => _cache.length;

  /// Drops all cached results.
  void clear() => _cache.clear();
}

/// The resolved palette (ARGB) of [theme] for [variant].
Map<PaletteKey, int> resolveThemePalette(
  WriteThemeData theme,
  ThemeVariant variant,
) {
  final light = resolvePaletteColors(theme.palette);
  if (variant == ThemeVariant.light) return light;
  const deriver = DarkPaletteDeriver();
  final derived = deriver.derive(theme.palette);
  if (theme.dark.mode == DarkMode.explicit) {
    return resolvePaletteColors(theme.dark.palette, fallback: derived);
  }
  if (theme.dark.palette.isEmpty) return derived;
  final layered = <PaletteKey, ColorRef>{
    for (final e in derived.entries) e.key: ColorRef.argb(e.value),
    for (final k in PaletteKey.values)
      if (theme.palette[k]?.kind == ColorRefKind.palette) k: theme.palette[k]!,
    ...theme.dark.palette.entries,
  };
  return resolvePaletteColors(ThemePalette(layered), fallback: derived);
}

final class _Resolution {
  _Resolution(this.theme, this.variant)
    : base = BaseTheme.instance,
      colors = resolveThemePalette(theme, variant);

  final WriteThemeData theme;
  final ThemeVariant variant;
  final BaseTheme base;
  final Map<PaletteKey, int> colors;

  bool get _dark => variant == ThemeVariant.dark;

  late final PropertyBag bodyBag = layered(ThemeElement.body);
  late final ResolvedTextStyle bodyStyle = text(
    bodyBag,
    role: FontRole.body,
    emBase: 11,
  );
  double get bodySize => bodyStyle.fontSize;

  // ---------------------------------------------------------------- layers

  PropertyBag _themeLayer(ThemeElement e) {
    final light = theme.element(e);
    return _dark ? light.merge(theme.dark.elements[e]) : light;
  }

  PropertyBag layered(ThemeElement e) {
    final level = e.headingLevel;
    if (level != null) {
      var bag = base
          .element(ThemeElement.headings)
          .merge(base.element(e))
          .merge(theme.element(ThemeElement.headings))
          .merge(theme.element(e));
      if (_dark) {
        bag = bag
            .merge(theme.dark.elements[ThemeElement.headings])
            .merge(theme.dark.elements[e]);
      }
      return bag;
    }
    if (e == ThemeElement.header || e == ThemeElement.footer) {
      final hf = (base.page.bag('headerFooter') ?? PropertyBag.empty).merge(
        theme.page.bag('headerFooter'),
      );
      return hf.merge(base.element(e)).merge(_themeLayer(e));
    }
    return base.element(e).merge(_themeLayer(e));
  }

  // ---------------------------------------------------------------- values

  int? color(ColorRef? ref) {
    if (ref == null) return null;
    return switch (ref.kind) {
      ColorRefKind.rgb || ColorRefKind.transparent => ref.argb,
      ColorRefKind.palette =>
        colors[ref.paletteKey!] ?? colors[PaletteKey.text] ?? 0xff000000,
    };
  }

  /// A fill color; fully transparent → `null`.
  int? fill(ColorRef? ref) {
    final c = color(ref);
    return c == null || (c >>> 24) == 0 ? null : c;
  }

  String family(FontRef? ref, FontRole role) {
    if (ref == null) return theme.fonts.of(role);
    if (ref.role != null) return theme.fonts.of(ref.role!);
    return FontRegistry.canonicalName(ref.family!) ?? theme.fonts.of(role);
  }

  double pt(Length? l, double emBase, [double fallback = 0]) =>
      l == null ? fallback : l.toPt(emBase);

  EdgesPt edges(Edges<Length>? e, double emBase) => e == null
      ? EdgesPt.zero
      : EdgesPt(
          top: pt(e.top, emBase),
          right: pt(e.right, emBase),
          bottom: pt(e.bottom, emBase),
          left: pt(e.left, emBase),
        );

  BorderPt? border(BorderSpec? spec, double emBase) {
    if (spec == null) return null;
    return BorderPt(
      width: pt(spec.width, emBase, 0.75),
      style: spec.style ?? LineStyle.solid,
      color: color(spec.color) ?? colors[PaletteKey.border] ?? 0xffd0d7de,
    );
  }

  BordersPt borders(Edges<BorderSpec>? e, double emBase) => e == null
      ? BordersPt.none
      : BordersPt(
          top: border(e.top, emBase) ?? BorderPt.none,
          right: border(e.right, emBase) ?? BorderPt.none,
          bottom: border(e.bottom, emBase) ?? BorderPt.none,
          left: border(e.left, emBase) ?? BorderPt.none,
        );

  T enumValue<T extends JsonEnum>(List<T> values, String? json, T fallback) =>
      enumFromJson(values, json) ?? fallback;

  /// Resolves TextStyleProps of [bag]; keys missing in [bag] come from
  /// [inherit] (restricted to [inheritKeys] when given), then from the body
  /// style. `em` font sizes are relative to [emBase] (body size).
  ResolvedTextStyle text(
    PropertyBag bag, {
    required FontRole role,
    PropertyBag? inherit,
    Set<String>? inheritKeys,
    double? emBase,
    double? fontSizeOverride,
  }) {
    Object? get(String key) {
      final own = bag[key];
      if (own != null) return own;
      if (inherit == null) return null;
      if (inheritKeys != null && !inheritKeys.contains(key)) return null;
      return inherit[key];
    }

    final fam = family(get('fontFamily') as FontRef?, role);
    final sizeBase = emBase ?? bodySize;
    final size =
        fontSizeOverride ??
        (get('fontSize') as Length?)?.toPt(sizeBase) ??
        (inherit == null ? 11.0 : bodySize);
    final weight = FontRegistry.snapWeight(
      fam,
      (get('fontWeight') as int?) ?? 400,
    );
    return ResolvedTextStyle(
      fontFamily: fam,
      fontSize: size,
      fontWeight: weight,
      italic: get('fontStyle') == 'italic',
      lineHeight: switch (get('lineHeight')) {
        final num n => n.toDouble(),
        _ => 1.5,
      },
      letterSpacing: (get('letterSpacing') as Length?)?.toPt(size) ?? 0,
      color:
          color(get('color') as ColorRef?) ??
          colors[PaletteKey.text] ??
          0xff000000,
      caseTransform: enumValue(
        CaseTransform.values,
        get('caseTransform') as String?,
        CaseTransform.none,
      ),
      fontFeatures: List.unmodifiable(
        (get('fontFeatures') as List<String>?) ?? const <String>[],
      ),
    );
  }

  ResolvedBox box(
    PropertyBag bag,
    double emBase, {
    ThemeAlign defaultAlign = ThemeAlign.left,
  }) => ResolvedBox(
    spaceBefore: pt(bag.length('spaceBefore'), emBase),
    spaceAfter: pt(bag.length('spaceAfter'), emBase),
    padding: edges(bag.lengthEdges('padding'), emBase),
    background: fill(bag.color('background')),
    border: borders(bag.borderEdges('border'), emBase),
    borderRadius: pt(bag.length('borderRadius'), emBase),
    align: enumValue(ThemeAlign.values, bag.string('align'), defaultAlign),
    keepWithNext: bag.boolean('keepWithNext') ?? false,
    pageBreakBefore: bag.boolean('pageBreakBefore') ?? false,
  );

  ResolvedExtent extent(Length? l, ResolvedExtent fallback) {
    if (l == null) return fallback;
    if (l.unit == LengthUnit.percent) {
      return ResolvedExtent.fraction(l.value / 100);
    }
    return ResolvedExtent.points(l.toPt(bodySize));
  }

  // ---------------------------------------------------------------- build

  ResolvedWriteTheme build() {
    final body = ResolvedText(
      style: bodyStyle,
      box: box(bodyBag, bodySize),
      firstLineIndent: pt(bodyBag.length('firstLineIndent'), bodySize),
    );
    return ResolvedWriteTheme(
      variant: variant,
      name: theme.name,
      fonts: ResolvedFonts(
        body: theme.fonts.body,
        heading: theme.fonts.heading,
        mono: theme.fonts.mono,
      ),
      palette: Map.unmodifiable(colors),
      page: _page(),
      body: body,
      headings: List.unmodifiable([for (var l = 1; l <= 6; l++) _heading(l)]),
      headingNumbering: _numbering(),
      paragraphAfterHeading: _paragraphAfterHeading(),
      bold: _bold(),
      italic: _italic(),
      strike: _strike(),
      inlineCode: _inlineCode(),
      link: _link(),
      mention: _mention(),
      blockquote: _blockquote(),
      codeBlock: _codeBlock(),
      list: _list(),
      task: _task(),
      rule: _rule(),
      image: _image(),
      table: _table(),
      wonky: _wonky(),
      header: _headerFooter(ThemeElement.header),
      footer: _headerFooter(ThemeElement.footer),
      syntax: Map.unmodifiable(_syntax()),
      overlays: _overlays(),
      themeHash: theme.contentHash,
      contentHash: sha256
          .convert(utf8.encode('${theme.canonicalJson}\n${variant.name}'))
          .toString(),
    );
  }

  // Wonky Markdown elements (Write 11 §8).

  ResolvedWonkyElements _wonky() => ResolvedWonkyElements(
    callout: _callout(),
    details: _details(),
    card: _card(),
    grid: _grid(),
    button: _button(),
    chip: _chip(),
    stepBadge: _stepBadge(),
  );

  int get _pageColor =>
      colors[PaletteKey.page] ?? (_dark ? 0xff111111 : 0xffffffff);

  /// [a] mixed into [b] by [t] (0 = [b], 1 = [a]) in Oklab.
  static int _mix(int a, int b, double t) {
    final x = Oklab.fromArgb(a);
    final y = Oklab.fromArgb(b);
    return Oklab(
      y.l + (x.l - y.l) * t,
      y.a + (x.a - y.a) * t,
      y.b + (x.b - y.b) * t,
    ).toArgb();
  }

  ResolvedCallout _callout() {
    final bag = layered(ThemeElement.callout);
    final page = _pageColor;
    final variants = <String, ResolvedCalloutColors>{};
    for (final v in const ['info', 'tip', 'note', 'warning', 'danger']) {
      final vb = bag.bag(v) ?? PropertyBag.empty;
      final hue = color(vb.color('color')) ?? colors[PaletteKey.accent] ?? 0;
      final title = Oklch.fromArgb(hue);
      variants[v] = ResolvedCalloutColors(
        color: hue,
        background:
            fill(vb.color('background')) ??
            _mix(hue, page, _dark ? 0.16 : 0.07),
        border:
            color(vb.color('border')) ?? _mix(hue, page, _dark ? 0.45 : 0.32),
        title:
            color(vb.color('titleColor')) ??
            title
                .copyWith(l: _dark ? 0.85 : 0.42, c: title.c.clamp(0, 0.16))
                .toArgb(),
      );
    }
    return ResolvedCallout(
      spaceBefore: pt(bag.length('spaceBefore'), bodySize),
      spaceAfter: pt(bag.length('spaceAfter'), bodySize),
      padding: edges(bag.lengthEdges('padding'), bodySize),
      borderRadius: pt(bag.length('borderRadius'), bodySize),
      borderWidth: pt(bag.length('borderWidth'), bodySize, 0.75),
      titleCase: enumValue(
        CaseTransform.values,
        bag.string('titleCaseTransform'),
        CaseTransform.uppercase,
      ),
      titleSizeRatio: bag.number('titleSizeRatio') ?? 0.75,
      titleWeight: FontRegistry.snapWeight(
        bodyStyle.fontFamily,
        bag.integer('titleWeight') ?? 600,
      ),
      variants: Map.unmodifiable(variants),
    );
  }

  ResolvedDetails _details() {
    final bag = layered(ThemeElement.details);
    return ResolvedDetails(
      spaceBefore: pt(bag.length('spaceBefore'), bodySize),
      spaceAfter: pt(bag.length('spaceAfter'), bodySize),
      padding: edges(bag.lengthEdges('padding'), bodySize),
      background: fill(bag.color('background')),
      border: border(bag.border('border'), bodySize) ?? BorderPt.none,
      borderRadius: pt(bag.length('borderRadius'), bodySize),
      summaryWeight: FontRegistry.snapWeight(
        bodyStyle.fontFamily,
        bag.integer('summaryWeight') ?? 600,
      ),
      chevronColor:
          color(bag.color('chevronColor')) ??
          colors[PaletteKey.muted] ??
          bodyStyle.color,
    );
  }

  ResolvedCard _card() {
    final bag = layered(ThemeElement.card);
    return ResolvedCard(
      spaceBefore: pt(bag.length('spaceBefore'), bodySize),
      spaceAfter: pt(bag.length('spaceAfter'), bodySize),
      padding: edges(bag.lengthEdges('padding'), bodySize),
      background: fill(bag.color('background')),
      borderRadius: pt(bag.length('borderRadius'), bodySize),
      shadow: bag.string('shadow') != 'none',
    );
  }

  ResolvedGrid _grid() {
    final bag = layered(ThemeElement.grid);
    return ResolvedGrid(
      spaceBefore: pt(bag.length('spaceBefore'), bodySize),
      spaceAfter: pt(bag.length('spaceAfter'), bodySize),
      bulletColor:
          color(bag.color('bulletColor')) ??
          colors[PaletteKey.accent] ??
          bodyStyle.color,
      columnGap: pt(bag.length('columnGap'), bodySize, 24),
      rowGap: pt(bag.length('rowGap'), bodySize, 9),
    );
  }

  ResolvedButton _button() {
    final bag = layered(ThemeElement.button);
    final accent = colors[PaletteKey.accent] ?? bodyStyle.color;
    return ResolvedButton(
      background: color(bag.color('background')) ?? accent,
      color: color(bag.color('color')) ?? _pageColor,
      secondaryBackground:
          color(bag.color('secondaryBackground')) ??
          colors[PaletteKey.muted] ??
          bodyStyle.color,
      secondaryColor: color(bag.color('secondaryColor')) ?? _pageColor,
      borderRadius: pt(bag.length('borderRadius'), bodySize),
      fontWeight: FontRegistry.snapWeight(
        bodyStyle.fontFamily,
        bag.integer('fontWeight') ?? 600,
      ),
      arrowColor: color(bag.color('arrowColor')) ?? accent,
      arrowWeight: FontRegistry.snapWeight(
        bodyStyle.fontFamily,
        bag.integer('arrowWeight') ?? 600,
      ),
    );
  }

  ResolvedChip _chip() {
    final bag = layered(ThemeElement.chip);
    return ResolvedChip(
      background:
          color(bag.color('background')) ??
          colors[PaletteKey.codeBg] ??
          _pageColor,
      color: color(bag.color('color')) ?? bodyStyle.color,
      borderRadius: pt(bag.length('borderRadius'), bodySize, 200),
      fontWeight: FontRegistry.snapWeight(
        bodyStyle.fontFamily,
        bag.integer('fontWeight') ?? 500,
      ),
    );
  }

  ResolvedStepBadge _stepBadge() {
    final bag = layered(ThemeElement.stepBadge);
    return ResolvedStepBadge(
      background:
          color(bag.color('background')) ??
          colors[PaletteKey.accent] ??
          bodyStyle.color,
      color: color(bag.color('color')) ?? _pageColor,
      sizeRatio: bag.number('sizeRatio') ?? 1.1,
    );
  }

  ResolvedPage _page() {
    final bag = base.page.merge(theme.page);
    return ResolvedPage(
      paperColor:
          color(bag.color('paperColor')) ??
          colors[PaletteKey.page] ??
          0xffffffff,
      canvasColor:
          color(bag.color('canvasColor')) ??
          colors[PaletteKey.canvas] ??
          0xfff1f3f4,
      pageShadow: enumValue(
        ShadowLevel.values,
        bag.string('pageShadow'),
        ShadowLevel.soft,
      ),
      pagelessMaxWidth: pt(bag.length('pagelessMaxWidth'), bodySize, 570),
      pagelessPadding: edges(bag.lengthEdges('pagelessPadding'), bodySize),
      defaultMargins: edges(bag.lengthEdges('defaultMargins'), bodySize),
    );
  }

  ResolvedHeading _heading(int level) {
    final bag = layered(ThemeElement.heading(level));
    final style = text(bag, role: FontRole.heading, inherit: bodyBag);
    final bb = border(bag.border('borderBottom'), style.fontSize);
    return ResolvedHeading(
      level: level,
      style: style,
      box: box(bag, style.fontSize),
      borderBottom: bb != null && bb.isVisible ? bb : null,
      borderBottomGap: pt(bag.length('borderBottomGap'), style.fontSize),
    );
  }

  ResolvedHeadingNumbering _numbering() {
    final bag =
        layered(ThemeElement.headings).bag('numbering') ?? PropertyBag.empty;
    return ResolvedHeadingNumbering(
      enabled: bag.boolean('enabled') ?? false,
      fromLevel: bag.integer('fromLevel') ?? 1,
      toLevel: bag.integer('toLevel') ?? 6,
      style: enumValue(
        HeadingNumberingStyle.values,
        bag.string('style'),
        HeadingNumberingStyle.decimal,
      ),
      suffix: bag.string('suffix') ?? ' ',
    );
  }

  ResolvedSpacingOverride _paragraphAfterHeading() {
    final bag = layered(ThemeElement.paragraphAfterHeading);
    final before = bag.length('spaceBefore');
    final after = bag.length('spaceAfter');
    return ResolvedSpacingOverride(
      spaceBefore: before?.toPt(bodySize),
      spaceAfter: after?.toPt(bodySize),
    );
  }

  ResolvedInline _bold() {
    final bag = layered(ThemeElement.bold);
    return ResolvedInline(
      fontWeight: bag.integer('fontWeight') ?? 700,
      color: color(bag.color('color')),
    );
  }

  ResolvedInline _italic() {
    final bag = layered(ThemeElement.italic);
    final s = bag.string('fontStyle') ?? 'italic';
    return ResolvedInline(
      italic: true,
      oblique: s == 'oblique',
      color: color(bag.color('color')),
    );
  }

  ResolvedStrike _strike() {
    final bag = layered(ThemeElement.strike);
    return ResolvedStrike(
      color: color(bag.color('color')),
      lineColor: color(bag.color('lineColor')),
      lineThickness: pt(bag.length('lineThickness'), bodySize, 0.75),
    );
  }

  ResolvedInlineCode _inlineCode() {
    final bag = layered(ThemeElement.inlineCode);
    final fam = family(bag.font('fontFamily'), FontRole.mono);
    final ratio = bag.number('sizeRatio') ?? 0.9;
    final codeSize = bodySize * ratio;
    final ls = bag.length('letterSpacing');
    final b = border(bag.border('border'), codeSize);
    return ResolvedInlineCode(
      fontFamily: fam,
      sizeRatio: ratio,
      fontWeight: FontRegistry.snapWeight(
        fam,
        bag.integer('fontWeight') ?? 400,
      ),
      italic: bag.string('fontStyle') == 'italic',
      letterSpacingEm: ls == null
          ? 0
          : ls.unit == LengthUnit.em
          ? ls.value
          : ls.toPt() / codeSize,
      fontFeatures: List.unmodifiable(
        bag.strings('fontFeatures') ?? const <String>[],
      ),
      color:
          color(bag.color('color')) ??
          colors[PaletteKey.codeText] ??
          bodyStyle.color,
      background: fill(bag.color('background')),
      paddingX: pt(bag.length('paddingX'), codeSize),
      borderRadius: pt(bag.length('borderRadius'), codeSize),
      border: b != null && b.isVisible ? b : null,
    );
  }

  ResolvedLink _link() {
    final bag = layered(ThemeElement.link);
    final c =
        color(bag.color('color')) ?? colors[PaletteKey.link] ?? bodyStyle.color;
    return ResolvedLink(
      color: c,
      hoverColor: color(bag.color('hoverColor')) ?? c,
      underline: enumValue(
        LinkUnderline.values,
        bag.string('underline'),
        LinkUnderline.always,
      ),
      underlineStyle: enumValue(
        LineStyle.values,
        bag.string('underlineStyle'),
        LineStyle.solid,
      ),
      underlineThickness: pt(bag.length('underlineThickness'), bodySize, 0.75),
    );
  }

  ResolvedMention _mention() {
    final bag = layered(ThemeElement.mention);
    return ResolvedMention(
      color:
          color(bag.color('color')) ??
          colors[PaletteKey.mentionText] ??
          bodyStyle.color,
      background: fill(bag.color('background')),
      borderRadius: pt(bag.length('borderRadius'), bodySize),
      fontWeight: FontRegistry.snapWeight(
        bodyStyle.fontFamily,
        bag.integer('fontWeight') ?? bodyStyle.fontWeight,
      ),
      prefix: bag.string('prefix') ?? '@',
    );
  }

  ResolvedBlockquote _blockquote() {
    final bag = layered(ThemeElement.blockquote);
    var style = text(bag, role: FontRole.body, inherit: bodyBag);
    if (bag.boolean('italic') ?? false) style = style.copyWith(italic: true);
    final bar = border(bag.border('bar'), style.fontSize);
    return ResolvedBlockquote(
      style: style,
      box: box(bag, style.fontSize),
      bar: bar ?? BorderPt.none,
    );
  }

  ResolvedCodeBlock _codeBlock() {
    final bag = layered(ThemeElement.codeBlock);
    final style = text(
      bag,
      role: FontRole.mono,
      inherit: bodyBag,
      inheritKeys: const {'color', 'lineHeight'},
    );
    return ResolvedCodeBlock(
      style: style,
      box: box(bag, style.fontSize),
      wrap: bag.boolean('wrap') ?? true,
      showLanguageLabel: bag.boolean('showLanguageLabel') ?? true,
      tabSize: bag.integer('tabSize') ?? 4,
      lineNumbers: bag.boolean('lineNumbers') ?? false,
    );
  }

  ResolvedList _list() {
    final bag = layered(ThemeElement.list);
    final numbering = bag.strings('numbering');
    return ResolvedList(
      style: bodyStyle,
      box: box(bag, bodySize),
      bullets: List.unmodifiable(
        bag.strings('bullets') ??
            const ['•', '◦', '▪', '•', '◦', '▪', '•', '◦', '▪'],
      ),
      bulletColor: color(bag.color('bulletColor')) ?? bodyStyle.color,
      bulletScale: bag.number('bulletScale') ?? 1,
      numbering: List.unmodifiable([
        for (var i = 0; i < 9; i++)
          enumValue(
            ListNumberStyle.values,
            numbering?[i],
            const [
              ListNumberStyle.decimal,
              ListNumberStyle.lowerAlpha,
              ListNumberStyle.lowerRoman,
            ][i % 3],
          ),
      ]),
      numberSuffix: bag.string('numberSuffix') ?? '.',
      numberColor: color(bag.color('numberColor')) ?? bodyStyle.color,
      indentPerLevel: pt(bag.length('indentPerLevel'), bodySize, 18),
      markerGap: pt(bag.length('markerGap'), bodySize, 6),
      itemSpacing: pt(bag.length('itemSpacing'), bodySize),
    );
  }

  ResolvedTask _task() {
    final bag = layered(ThemeElement.task);
    final cb = bag.bag('checkbox') ?? PropertyBag.empty;
    final ct = bag.bag('checkedText') ?? PropertyBag.empty;
    return ResolvedTask(
      style: bodyStyle,
      box: box(bag, bodySize),
      checkbox: ResolvedCheckbox(
        shape: enumValue(
          CheckboxShape.values,
          cb.string('shape'),
          CheckboxShape.rounded,
        ),
        size: pt(cb.length('size'), bodySize, bodySize * 0.9),
        borderColor:
            color(cb.color('borderColor')) ??
            colors[PaletteKey.muted] ??
            bodyStyle.color,
        checkedFill:
            color(cb.color('checkedFill')) ??
            colors[PaletteKey.accent] ??
            bodyStyle.color,
        checkColor:
            color(cb.color('checkColor')) ??
            colors[PaletteKey.page] ??
            0xffffffff,
      ),
      checkedStrike: ct.boolean('strike') ?? true,
      checkedOpacity: ct.number('opacity') ?? 0.7,
      checkedColor: color(ct.color('color')) ?? bodyStyle.color,
    );
  }

  ResolvedRule _rule() {
    final bag = layered(ThemeElement.rule);
    final c = color(bag.color('color')) ?? colors[PaletteKey.border] ?? 0;
    return ResolvedRule(
      box: box(bag, bodySize, defaultAlign: ThemeAlign.center),
      style: enumValue(RuleStyle.values, bag.string('style'), RuleStyle.solid),
      thickness: pt(bag.length('thickness'), bodySize, 0.75),
      color: c,
      width: extent(bag.length('width'), const ResolvedExtent.fraction(1)),
      ornament: bag.string('ornament') ?? '⁂',
      ornamentStyle: bodyStyle.copyWith(color: c),
    );
  }

  ResolvedImageStyle _image() {
    final bag = layered(ThemeElement.image);
    final cap = bag.bag('caption') ?? PropertyBag.empty;
    final capStyle = text(cap, role: FontRole.body, inherit: bodyBag);
    final align = enumValue(
      ImageAlign.values,
      bag.string('align'),
      ImageAlign.center,
    );
    final b = border(bag.border('border'), bodySize);
    return ResolvedImageStyle(
      box: box(
        bag.withValue('align', null),
        bodySize,
        defaultAlign: align == ImageAlign.center
            ? ThemeAlign.center
            : ThemeAlign.left,
      ),
      maxWidth: extent(
        bag.length('maxWidth'),
        const ResolvedExtent.fraction(1),
      ),
      align: align,
      borderRadius: pt(bag.length('borderRadius'), bodySize),
      border: b != null && b.isVisible ? b : null,
      shadow: enumValue(
        ShadowLevel.values,
        bag.string('shadow'),
        ShadowLevel.none,
      ),
      caption: ResolvedCaption(
        show: cap.boolean('show') ?? true,
        style: capStyle,
        align: enumValue(
          ThemeAlign.values,
          cap.string('align'),
          ThemeAlign.center,
        ),
        gap: pt(cap.length('gap'), capStyle.fontSize),
      ),
    );
  }

  ResolvedTable _table() {
    final bag = layered(ThemeElement.table);
    final ratio = bag.number('fontSizeRatio') ?? 1;
    final ownSize = bag.length('fontSize');
    final style = text(
      bag,
      role: FontRole.body,
      inherit: bodyBag,
      fontSizeOverride: ownSize == null ? bodySize * ratio : null,
    );
    final headerWeight = FontRegistry.snapWeight(
      style.fontFamily,
      bag.integer('headerFontWeight') ?? 600,
    );
    return ResolvedTable(
      style: style,
      headerStyle: style.copyWith(
        color:
            color(bag.color('headerColor')) ??
            colors[PaletteKey.heading] ??
            style.color,
        fontWeight: headerWeight,
      ),
      box: box(bag, style.fontSize),
      width: enumValue(TableWidth.values, bag.string('width'), TableWidth.auto),
      headerBackground: fill(bag.color('headerBackground')),
      borders: enumValue(
        TableBorders.values,
        bag.string('borders'),
        TableBorders.all,
      ),
      borderColor:
          color(bag.color('borderColor')) ?? colors[PaletteKey.border] ?? 0,
      borderWidth: pt(bag.length('borderWidth'), style.fontSize, 0.75),
      zebra: bag.boolean('zebra') ?? false,
      zebraColor: fill(bag.color('zebraColor')),
      cellPadding: edges(bag.lengthEdges('cellPadding'), style.fontSize),
    );
  }

  ResolvedHeaderFooter _headerFooter(ThemeElement e) {
    final bag = layered(e);
    final style = text(bag, role: FontRole.body, inherit: bodyBag);
    BorderPt? visible(BorderPt? b) => b != null && b.isVisible ? b : null;
    return ResolvedHeaderFooter(
      style: style,
      align: enumValue(ThemeAlign.values, bag.string('align'), ThemeAlign.left),
      borderBottom: visible(border(bag.border('borderBottom'), style.fontSize)),
      borderTop: visible(border(bag.border('borderTop'), style.fontSize)),
    );
  }

  Map<SyntaxToken, ResolvedTokenStyle> _syntax() {
    final codeText = colors[PaletteKey.codeText] ?? bodyStyle.color;
    final codeBg = compositeCodeBg();
    const deriver = DarkPaletteDeriver();
    final out = <SyntaxToken, ResolvedTokenStyle>{};
    for (final t in SyntaxToken.values) {
      final light = (base.syntax(t) ?? PropertyBag.empty).merge(
        theme.syntax[t],
      );
      final darkBag = _dark ? (theme.dark.syntax?[t]) : null;
      final bag = light.merge(darkBag);
      int c;
      final darkColor = darkBag?.color('color');
      final ref = light.color('color');
      if (!_dark || darkColor != null) {
        c = color(bag.color('color')) ?? codeText;
      } else if (ref == null) {
        c = codeText;
      } else if (ref.kind == ColorRefKind.rgb) {
        c = deriver.deriveSyntaxColor(ref.argb!, codeBg);
      } else {
        c = color(ref) ?? codeText;
      }
      final weight = bag.integer('fontWeight');
      out[t] = ResolvedTokenStyle(
        color: c,
        italic: bag.string('fontStyle') == 'italic',
        fontWeight: weight == null
            ? null
            : FontRegistry.snapWeight(theme.fonts.mono, weight),
      );
    }
    return out;
  }

  /// The code block background composited over the paper color.
  int compositeCodeBg() {
    final bag = layered(ThemeElement.codeBlock);
    final paper =
        color(base.page.merge(theme.page).color('paperColor')) ??
        colors[PaletteKey.page] ??
        0xffffffff;
    final bg = fill(bag.color('background'));
    final opaquePaper = paper | 0xff000000;
    return bg == null ? opaquePaper : compositeOver(bg, opaquePaper);
  }

  ResolvedOverlays _overlays() {
    final bag = theme.overlays;
    final caret = bag.bag('caret') ?? PropertyBag.empty;
    final cw = caret.length('width');
    return ResolvedOverlays(
      selection: color(bag.color('selection')),
      caretColor: color(caret.color('color')),
      caretWidth: cw?.toPt(bodySize),
      commentHighlight: color(bag.color('commentHighlight')),
      commentHighlightActive: color(bag.color('commentHighlightActive')),
      suggestionInsert: color(bag.color('suggestionInsert')),
      suggestionDelete: color(bag.color('suggestionDelete')),
      findMatch: color(bag.color('findMatch')),
      findMatchActive: color(bag.color('findMatchActive')),
    );
  }
}
