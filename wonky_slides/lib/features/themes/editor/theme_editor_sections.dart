import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_code_flutter/wonky_code_flutter.dart'
    show BuiltInPalettes, SyntaxToken;
import 'package:wonky_slides_core/model.dart' show DeckModelIndexes;
import 'package:wonky_slides_core/themes.dart';

import '../../../commands/text_commands.dart' show listStyleLabel;
import '../../../config/menus/slides_menu_spec.dart' show textStyleLabel;
import '../../../l10n/slides_l10n.dart';
import '../../editor_screen/deck_editor_controller.dart';
import '../../inspector/inspector_sections.dart';
import '../../masters/masters_targets.dart';
import 'theme_edit_scope.dart';
import 'theme_editor_controls.dart';

/// Inspector › **Theme** in masters mode (Slides 05 §8.4; SL-28): the
/// theme editor of the edited master's theme, one collapsible section per
/// JSON column (Colors, Fonts, Text styles, Background, Objects, Tables,
/// Code, Charts) after the theme's name and actions. Each committed
/// control writes one column (`slides.theme.update`, one undo step).
final List<InspectorSectionSpec> themeEditorSections = [
  InspectorSectionSpec(
    id: 'themeInfo',
    title: (l) => l.sectionTheme,
    tab: InspectorTab.theme,
    builder: _guard(_info),
  ),
  InspectorSectionSpec(
    id: 'colors',
    title: (l) => l.themeSectionColors,
    tab: InspectorTab.theme,
    builder: _guard(_colors),
  ),
  InspectorSectionSpec(
    id: 'fonts',
    title: (l) => l.themeSectionFonts,
    tab: InspectorTab.theme,
    builder: _guard(_fonts),
  ),
  InspectorSectionSpec(
    id: 'textStyles',
    title: (l) => l.themeSectionTextStyles,
    tab: InspectorTab.theme,
    builder: _guard(_textStyles),
  ),
  InspectorSectionSpec(
    id: 'themeBackground',
    title: (l) => l.sectionBackground,
    tab: InspectorTab.theme,
    builder: _guard(_background),
  ),
  InspectorSectionSpec(
    id: 'objects',
    title: (l) => l.themeSectionObjects,
    tab: InspectorTab.theme,
    builder: _guard(_objects),
  ),
  InspectorSectionSpec(
    id: 'tables',
    title: (l) => l.themeSectionTables,
    tab: InspectorTab.theme,
    builder: _guard(_tables),
  ),
  InspectorSectionSpec(
    id: 'code',
    title: (l) => l.sectionCode,
    tab: InspectorTab.theme,
    builder: _guard(_code),
  ),
  InspectorSectionSpec(
    id: 'charts',
    title: (l) => l.themeSectionCharts,
    tab: InspectorTab.theme,
    builder: _guard(_charts),
  ),
];

typedef _ScopeBuilder = Widget Function(ThemeEditScope s);

/// Builds [body] with a scope; a deck without themes shows a note.
InspectorSectionBuilder _guard(_ScopeBuilder body) =>
    (context, services, ed) => ListenableBuilder(
      listenable: ThemeEditorState.of(ed),
      builder: (context, _) {
        final s = ThemeEditScope(context, services, ed);
        if (s.rec == null) {
          return Text(
            s.l.themeEditorNoTheme,
            style: ShadTheme.of(context).textTheme.muted,
          );
        }
        return body(s);
      },
    );

// ------------------------------------------------------------------ Theme

Widget _info(ThemeEditScope s) {
  final rec = s.rec!;
  final l = s.l;
  final theme = ShadTheme.of(s.context);
  final builtin = MastersTargets.builtInKeyOf(rec);
  final isDefault = s.ed.model.deck?.themeId == rec.id;
  Widget cmd(String id, String label, IconData icon) {
    final args = {'themeId': rec.id};
    final st = s.ui.state(id, args);
    final b = ShadButton.outline(
      key: ValueKey<String>('slides.theme.cmd.$id'),
      size: ShadButtonSize.sm,
      enabled: st.enabled,
      leading: Icon(icon, size: 14),
      onPressed: () => s.run(id, args),
      child: Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    final reason = st.disabledReason;
    return st.enabled || reason == null
        ? b
        : ShadTooltip(builder: (_) => Text(reason), child: b);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ThemeEditorRow(
        label: l.themeNameLabel,
        child: ThemeCommitField(
          keyName: 'name',
          value: rec.name,
          enabled: s.enabled,
          semanticLabel: l.themeNameLabel,
          onCommit: (v) =>
              s.run('slides.theme.update', {'themeId': rec.id, 'name': v}),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          [
            if (builtin != null)
              l.themeEditorBasedOn(BuiltInThemes.byKey(builtin)!.name),
            l.themesUsedBy(s.ed.model.indexes.themes.slidesUsingTheme(rec.id)),
            if (isDefault) l.themesDefault,
          ].join(' · '),
          style: theme.textTheme.muted.copyWith(fontSize: 12),
        ),
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          cmd('slides.theme.duplicate', l.cmdThemeDuplicate, LucideIcons.copy),
          if (builtin != null)
            cmd(
              'slides.theme.resetToBuiltIn',
              l.cmdThemeResetToBuiltIn,
              LucideIcons.rotateCcw,
            ),
          if (!isDefault)
            cmd(
              'slides.theme.setDefault',
              l.cmdThemeSetDefault,
              LucideIcons.star,
            ),
        ],
      ),
    ],
  );
}

// ----------------------------------------------------------------- Colors

const _contrastPairs = {
  'text1': ThemeContrastPair('text1', 'bg1', 7),
  'text2': ThemeContrastPair('text2', 'bg1', 4.5),
  'accent1': ThemeContrastPair('accent1', 'bg1', 3),
  'link': ThemeContrastPair('link', 'bg1', 4.5),
};

Widget _appearanceToggle(ThemeEditScope s) {
  final theme = ShadTheme.of(s.context);
  Widget button(SlideAppearance a, String label) {
    final selected = s.appearance == a;
    return Semantics(
      selected: selected,
      button: true,
      child: ShadButton.ghost(
        key: ValueKey<String>('slides.theme.appearance.${a.name}'),
        size: ShadButtonSize.sm,
        backgroundColor: selected ? theme.colorScheme.muted : null,
        onPressed: () => s.state.appearance = a,
        child: Text(label),
      ),
    );
  }

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: theme.colorScheme.border),
      borderRadius: BorderRadius.circular(6),
    ),
    padding: const EdgeInsets.all(2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(SlideAppearance.light, s.l.appearanceLight),
        button(SlideAppearance.dark, s.l.appearanceDark),
      ],
    ),
  );
}

Widget _colors(ThemeEditScope s) {
  final l = s.l;
  final colors = s.data.colors;
  final app = s.appearance;
  final scheme = colors.scheme(app);
  final checks = {
    for (final r in ThemeContrast.check(colors, app)) r.pair.foreground: r,
  };
  void setScheme(String key, int argb) =>
      s.edit(DeckThemeColumn.colorsJson, (j) {
        ThemeEditScope.setPath(j, [app.name, key], ColorRef.formatHex(argb));
      });
  final custom = colors.custom;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _appearanceToggle(s),
          ShadButton.outline(
            key: const ValueKey<String>('slides.theme.deriveDark'),
            size: ShadButtonSize.sm,
            enabled: s.enabled,
            leading: const Icon(LucideIcons.moon, size: 14),
            onPressed: () =>
                s.run('slides.theme.deriveDarkColors', {'themeId': s.rec!.id}),
            child: Flexible(
              child: Text(
                l.cmdThemeDeriveDarkColors,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final key in themeColorKeys)
        ThemeEditorRow(
          label: schemeKeyLabel(l, key),
          trailing: switch (checks[key]) {
            final r? => ContrastBadge(
              key: ValueKey<String>('slides.theme.contrast.$key.${app.name}'),
              ratio: r.ratio,
              required: _contrastPairs[key]!.required,
              pair: l.themeContrastPair(
                schemeKeyLabel(l, key),
                schemeKeyLabel(l, 'bg1'),
              ),
            ),
            null => null,
          },
          child: ThemeHexColorButton(
            keyName: '${app.name}.$key',
            label: schemeKeyLabel(l, key),
            argb: scheme[key]!,
            enabled: s.enabled,
            onChanged: (v) => setScheme(key, v),
          ),
        ),
      ThemeEditorSubTitle(l.themeEditorCustomColors),
      for (final (i, c) in custom.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              ThemeHexColorButton(
                keyName: 'custom${i + 1}.${app.name}',
                label: c.name,
                argb: c.forAppearance(app),
                compact: true,
                enabled: s.enabled,
                onChanged: (v) => s.edit(DeckThemeColumn.colorsJson, (j) {
                  final list = (j['custom'] as List)
                      .cast<Map<Object?, Object?>>();
                  list[i][app.name] = ColorRef.formatHex(v);
                }),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ThemeCommitField(
                  keyName: 'custom${i + 1}.name',
                  value: c.name,
                  enabled: s.enabled,
                  semanticLabel: l.themeEditorCustomColorName,
                  maxLength: 60,
                  onCommit: (v) => s.edit(DeckThemeColumn.colorsJson, (j) {
                    final list = (j['custom'] as List)
                        .cast<Map<Object?, Object?>>();
                    list[i]['name'] = v;
                  }),
                ),
              ),
              ShadIconButton.ghost(
                key: ValueKey<String>('slides.theme.custom${i + 1}.remove'),
                width: 28,
                height: 28,
                iconSize: 14,
                enabled: s.enabled,
                semanticLabel: l.themeEditorRemoveCustomColor(c.name),
                icon: const Icon(LucideIcons.x),
                onPressed: () => s.edit(DeckThemeColumn.colorsJson, (j) {
                  final list = (j['custom'] as List)..removeAt(i);
                  if (list.isEmpty) j.remove('custom');
                }),
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: ShadButton.ghost(
          key: const ValueKey<String>('slides.theme.custom.add'),
          size: ShadButtonSize.sm,
          enabled: s.enabled && custom.length < maxCustomThemeColors,
          leading: const Icon(LucideIcons.plus, size: 14),
          onPressed: () => s.edit(DeckThemeColumn.colorsJson, (j) {
            final list = ((j['custom'] as List?) ?? []).toList();
            list.add({
              'name': l.themeEditorCustomColorDefault(list.length + 1),
              'light': ColorRef.formatHex(colors.light.accent(1)),
              'dark': ColorRef.formatHex(colors.dark.accent(1)),
            });
            j['custom'] = list;
          }),
          child: Flexible(
            child: Text(
              l.themeEditorAddCustomColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    ],
  );
}

// ------------------------------------------------------------------ Fonts

const _weights = [300, 400, 500, 600, 700, 800];

String _weightLabel(SlidesLocalizations l, int w) => l.themeEditorWeight('$w');

Widget _fonts(ThemeEditScope s) {
  final l = s.l;
  final fonts = s.data.fonts;
  final theme = ShadTheme.of(s.context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (role, label) in [
        (ThemeFontRole.heading, l.fontThemeHeading),
        (ThemeFontRole.body, l.fontThemeBody),
        (ThemeFontRole.mono, l.fontThemeMono),
      ])
        () {
          final f = fonts.of(role);
          final families = [
            ...SlidesFonts.families,
            if (!SlidesFonts.families.contains(f.family)) f.family,
          ];
          final bundled = SlidesFonts.isAvailable(f.family);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role on its own line: family and weight need the width.
              ThemeEditorSubTitle(label),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: ThemeSelect(
                        keyName: 'font.${role.name}',
                        value: f.family,
                        options: families,
                        enabled: s.enabled,
                        minWidth: 100,
                        styleOf: fontPreviewStyle,
                        onChanged: (v) => s.edit(DeckThemeColumn.fontsJson, (
                          j,
                        ) {
                          ThemeEditScope.setPath(j, [role.name, 'family'], v);
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ThemeSelect(
                      keyName: 'weight.${role.name}',
                      value: '${f.weight}',
                      options: [for (final w in _weights) '$w'],
                      minWidth: 72,
                      enabled: s.enabled,
                      labelOf: (v) => _weightLabel(l, int.parse(v)),
                      onChanged: (v) => s.edit(DeckThemeColumn.fontsJson, (j) {
                        ThemeEditScope.setPath(j, [
                          role.name,
                          'weight',
                        ], int.parse(v));
                      }),
                    ),
                  ],
                ),
              ),
              if (!bundled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    l.themeEditorFontFallback(
                      f.family,
                      s.light.fonts[role]?.face.family ?? '',
                    ),
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ),
            ],
          );
        }(),
    ],
  );
}

// ------------------------------------------------------------ Text styles

Widget _textStyles(ThemeEditScope s) {
  final l = s.l;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final key in themeTextStyleKeys) _styleRow(s, key),
      ThemeEditorSubTitle(l.themeEditorLists),
      ..._lists(s),
    ],
  );
}

FontWeight _fontWeight(int w) =>
    FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

Widget _styleRow(ThemeEditScope s, String key) {
  final l = s.l;
  final theme = ShadTheme.of(s.context);
  final r = s.resolved;
  final rs = r.textStyles[key];
  final open = s.state.expanded(key);
  final bg = r.colorOf('bg1') ?? 0xffffffff;
  final sampleSize = ((rs?.size ?? 40) * 0.2).clamp(11.0, 24.0);
  final family = rs?.font.face.family;
  final sample = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Color(bg),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: theme.colorScheme.border),
    ),
    child: Text(
      _capsOf(textStyleLabel(l, key), rs?.caps),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: family == null
            ? null
            : fontPreviewStyle(family)?.fontFamily,
        fontSize: sampleSize,
        fontWeight: _fontWeight(rs?.font.face.weight ?? 400),
        fontStyle: (rs?.font.face.italic ?? false)
            ? FontStyle.italic
            : FontStyle.normal,
        color: Color(rs?.color ?? 0xff000000),
        letterSpacing: (rs?.letterSpacing ?? 0) * sampleSize,
      ),
    ),
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Semantics(
          button: true,
          expanded: open,
          label: textStyleLabel(l, key),
          child: GestureDetector(
            key: ValueKey<String>('slides.theme.style.$key'),
            behavior: HitTestBehavior.opaque,
            onTap: () => s.state.toggle(key),
            child: Row(
              children: [
                Icon(
                  open ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 4),
                Expanded(child: sample),
                const SizedBox(width: 6),
                Text(
                  '${(rs?.size ?? 0).round()}',
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
      if (open)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 0, 10),
          child: _styleProps(s, key),
        ),
    ],
  );
}

String _capsOf(String text, String? caps) =>
    caps == 'all' || caps == 'small' ? text.toUpperCase() : text;

Widget _styleProps(ThemeEditScope s, String key) {
  final l = s.l;
  final st = s.data.textStyles[key];
  final rs = s.resolved.textStyles[key];
  void set(String prop, Object? value) =>
      s.edit(DeckThemeColumn.textStylesJson, (j) {
        ThemeEditScope.setPath(j, ['styles', key, prop], value);
      });
  final fontValues = [
    '@heading',
    '@body',
    '@mono',
    ...SlidesFonts.families,
    if (st.font != null &&
        !st.font!.value.startsWith('@') &&
        !SlidesFonts.families.contains(st.font!.value))
      st.font!.value,
  ];
  String fontLabel(String v) => switch (v) {
    '@heading' => l.fontThemeHeading,
    '@body' => l.fontThemeBody,
    '@mono' => l.fontThemeMono,
    _ => v,
  };
  final k = 'style.$key';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ThemeEditorRow(
        label: l.fontLabel,
        child: ThemeSelect(
          keyName: '$k.font',
          value: st.font?.value ?? '@body',
          options: fontValues,
          labelOf: fontLabel,
          styleOf: (v) => v.startsWith('@') ? null : fontPreviewStyle(v),
          enabled: s.enabled,
          onChanged: (v) => set('font', v),
        ),
      ),
      ThemeEditorRow(
        label: l.fontSizeLabel,
        child: ThemeNumber(
          keyName: '$k.size',
          value: st.size ?? rs?.size,
          min: minFontSize,
          max: maxFontSize,
          step: 2,
          enabled: s.enabled,
          semanticLabel: l.fontSizeLabel,
          onChanged: (v) => set('size', v),
        ),
      ),
      ThemeEditorRow(
        label: l.styleLabelWeight,
        child: ThemeSelect(
          keyName: '$k.weight',
          value: '${st.weight ?? rs?.font.requestedWeight ?? 400}',
          options: [for (final w in _weights) '$w'],
          labelOf: (v) => _weightLabel(l, int.parse(v)),
          minWidth: 96,
          enabled: s.enabled,
          onChanged: (v) => set('weight', int.parse(v)),
        ),
      ),
      ThemeEditorRow(
        label: l.themeEditorItalic,
        child: ShadSwitch(
          key: ValueKey<String>('slides.theme.$k.italic'),
          value: st.italic ?? false,
          enabled: s.enabled,
          onChanged: (v) => set('italic', v ? true : null),
        ),
      ),
      ThemeEditorRow(
        label: l.lineHeightLabel,
        child: ThemeNumber(
          keyName: '$k.lineHeight',
          value: st.lineHeight ?? rs?.lineHeight,
          min: 0.5,
          max: 3,
          step: 0.05,
          digits: 2,
          enabled: s.enabled,
          semanticLabel: l.lineHeightLabel,
          onChanged: (v) => set('lineHeight', v),
        ),
      ),
      ThemeEditorRow(
        label: l.themeEditorLetterSpacing,
        child: ThemeNumber(
          keyName: '$k.letterSpacing',
          value: st.letterSpacing ?? rs?.letterSpacing ?? 0,
          min: -0.2,
          max: 1,
          step: 0.01,
          digits: 2,
          enabled: s.enabled,
          semanticLabel: l.themeEditorLetterSpacing,
          onChanged: (v) => set('letterSpacing', v == 0 ? null : v),
        ),
      ),
      ThemeEditorRow(
        label: l.styleLabelColor,
        child: ThemeRefColorButton(
          keyName: '$k.color',
          label: l.styleLabelColor,
          value: st.color?.json,
          theme: s.resolved,
          enabled: s.enabled,
          onChanged: (c) => set('color', c),
        ),
      ),
      ThemeEditorRow(
        label: l.themeEditorCaps,
        child: ThemeSelect(
          keyName: '$k.caps',
          value: st.caps ?? 'none',
          options: const ['none', 'all', 'small', 'title'],
          labelOf: (v) => switch (v) {
            'all' => l.capsUpper,
            'small' => l.capsSmallCaps,
            'title' => l.capsTitle,
            _ => l.capsNone,
          },
          enabled: s.enabled,
          onChanged: (v) => set('caps', v == 'none' ? null : v),
        ),
      ),
      ThemeEditorRow(
        label: l.spacingAddBefore,
        child: ThemeNumber(
          keyName: '$k.spaceBefore',
          value: st.spaceBefore ?? 0,
          max: 400,
          step: 4,
          enabled: s.enabled,
          semanticLabel: l.spacingAddBefore,
          onChanged: (v) => set('spaceBefore', v == 0 ? null : v),
        ),
      ),
      ThemeEditorRow(
        label: l.spacingAddAfter,
        child: ThemeNumber(
          keyName: '$k.spaceAfter',
          value: st.spaceAfter ?? 0,
          max: 400,
          step: 4,
          enabled: s.enabled,
          semanticLabel: l.spacingAddAfter,
          onChanged: (v) => set('spaceAfter', v == 0 ? null : v),
        ),
      ),
    ],
  );
}

List<Widget> _lists(ThemeEditScope s) {
  final l = s.l;
  final lists = s.data.textStyles.lists;
  void edit(void Function(JsonMap lists) f) => s.edit(
    DeckThemeColumn.textStylesJson,
    (j) {
      final m = (j['lists'] as Map?)?.cast<String, Object?>() ?? lists.toJson();
      f(m);
      j['lists'] = m;
    },
  );
  return [
    for (var level = 0; level < 3; level++)
      ThemeEditorRow(
        label: l.themeEditorListLevel(level + 1),
        child: Row(
          children: [
            Flexible(
              child: ThemeSelect(
                keyName: 'bullets.$level',
                value: lists.bullets[level],
                options: bulletGlyphKeys.toList(),
                labelOf: (v) => listStyleLabel(l, v),
                minWidth: 96,
                enabled: s.enabled,
                onChanged: (v) => edit((m) {
                  final b = (m['bullets'] as List).toList();
                  b[level] = v;
                  m['bullets'] = b;
                }),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: ThemeSelect(
                keyName: 'numbering.$level',
                value: lists.numbering[level],
                options: numberingKeys.toList(),
                labelOf: (v) => listStyleLabel(l, v),
                minWidth: 96,
                enabled: s.enabled,
                onChanged: (v) => edit((m) {
                  final n = (m['numbering'] as List).toList();
                  n[level] = v;
                  m['numbering'] = n;
                }),
              ),
            ),
          ],
        ),
      ),
    ThemeEditorRow(
      label: l.themeEditorBulletColor,
      child: ThemeRefColorButton(
        keyName: 'bulletColor',
        label: l.themeEditorBulletColor,
        value: lists.bulletColor.json,
        theme: s.resolved,
        enabled: s.enabled,
        onChanged: (c) => edit((m) => m['bulletColor'] = c),
      ),
    ),
    ThemeEditorRow(
      label: l.themeEditorIndent,
      child: ThemeNumber(
        keyName: 'indentPerLevel',
        value: lists.indentPerLevel,
        min: 0,
        max: 400,
        step: 8,
        enabled: s.enabled,
        semanticLabel: l.themeEditorIndent,
        onChanged: (v) => edit((m) => m['indentPerLevel'] = v),
      ),
    ),
  ];
}

// ------------------------------------------------------------- Background

/// The solid color of a `Fill` JSON, or null.
String? _solidColor(Object? fill) =>
    fill is Map && fill['type'] == 'solid' && fill['color'] is String
    ? fill['color'] as String
    : null;

JsonMap _solid(String color) => {'v': 1, 'type': 'solid', 'color': color};

Widget _background(ThemeEditScope s) {
  final l = s.l;
  final theme = ShadTheme.of(s.context);
  final json = s.column(DeckThemeColumn.backgroundJson);
  final fill = json['fill'];
  final dark = json['fillDark'];
  final solid = _solidColor(fill);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ThemeEditorRow(
        label: l.styleLabelColor,
        child: ThemeRefColorButton(
          keyName: 'background',
          label: l.sectionBackground,
          value: solid,
          theme: s.light,
          enabled: s.enabled,
          onChanged: (c) => s.edit(
            DeckThemeColumn.backgroundJson,
            (j) => j['fill'] = _solid(c!),
          ),
        ),
      ),
      if (solid == null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            l.themeEditorBackgroundNotSolid,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        ),
      ThemeEditorRow(
        label: l.themeEditorDarkBackground,
        child: ShadSwitch(
          key: const ValueKey<String>('slides.theme.background.darkOverride'),
          value: dark != null,
          enabled: s.enabled,
          onChanged: (v) => s.edit(DeckThemeColumn.backgroundJson, (j) {
            if (v) {
              j['fillDark'] = _solid(solid ?? 'theme:bg1');
            } else {
              j.remove('fillDark');
            }
          }),
        ),
      ),
      if (dark != null)
        ThemeEditorRow(
          label: l.appearanceDark,
          child: ThemeRefColorButton(
            keyName: 'backgroundDark',
            label: l.themeEditorDarkBackground,
            value: _solidColor(dark),
            theme: s.dark,
            enabled: s.enabled,
            onChanged: (c) => s.edit(
              DeckThemeColumn.backgroundJson,
              (j) => j['fillDark'] = _solid(c!),
            ),
          ),
        ),
    ],
  );
}

// ---------------------------------------------------------------- Objects

/// Sets the color of the fill at [path] of [j] (a solid fill).
void _setFill(JsonMap j, List<String> path, String? color) =>
    ThemeEditScope.setPath(
      j,
      path,
      color == null ? {'v': 1, 'type': 'none'} : _solid(color),
    );

/// Sets the color of the stroke at [path] (a `none` stroke becomes a
/// [width] su line).
void _setStroke(JsonMap j, List<String> path, String? color, {num width = 4}) {
  final cur = ThemeEditScope.getPath(j, path);
  if (color == null) {
    ThemeEditScope.setPath(j, path, {'v': 1, 'type': 'none'});
    return;
  }
  final m = cur is Map && cur['type'] != 'none'
      ? cur.cast<String, Object?>()
      : <String, Object?>{'v': 1, 'width': width};
  m['color'] = color;
  ThemeEditScope.setPath(j, path, m);
}

Widget _objects(ThemeEditScope s) {
  final l = s.l;
  final json = s.column(DeckThemeColumn.shapeStyleJson);
  String? at(List<String> p) {
    final v = ThemeEditScope.getPath(json, p);
    return v is String ? v : null;
  }

  Widget color(
    String keyName,
    String label,
    String? value,
    void Function(JsonMap j, String? c) set, {
    String? resetLabel,
  }) => ThemeEditorRow(
    label: label,
    child: ThemeRefColorButton(
      keyName: 'objects.$keyName',
      label: label,
      value: value,
      theme: s.deckResolved,
      enabled: s.enabled,
      resetLabel: resetLabel,
      onChanged: (c) =>
          s.edit(DeckThemeColumn.shapeStyleJson, (j) => set(j, c)),
    ),
  );

  final quick = (json['quickStyles'] as List?) ?? const [];
  final shadow = json['shadow'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ThemeEditorSubTitle(l.themeEditorTextBoxes),
      color(
        'text.fill',
        l.sectionFill,
        _solidColor(ThemeEditScope.getPath(json, ['text', 'fill'])),
        (j, c) => _setFill(j, ['text', 'fill'], c),
        resetLabel: l.styleLabelNoFill,
      ),
      ThemeEditorSubTitle(l.themeEditorShapes),
      color(
        'shape.fill',
        l.sectionFill,
        _solidColor(ThemeEditScope.getPath(json, ['shape', 'fill'])),
        (j, c) => _setFill(j, ['shape', 'fill'], c),
        resetLabel: l.styleLabelNoFill,
      ),
      color(
        'shape.stroke',
        l.sectionBorder,
        at(['shape', 'stroke', 'color']),
        (j, c) => _setStroke(j, ['shape', 'stroke'], c),
        resetLabel: l.styleLabelNoBorder,
      ),
      color(
        'shape.text',
        l.themeEditorTextColor,
        at(['shape', 'textStyle', 'defaults', 'color']),
        (j, c) => ThemeEditScope.setPath(j, [
          'shape',
          'textStyle',
          'defaults',
          'color',
        ], c),
        resetLabel: l.colorThemeDefault,
      ),
      ThemeEditorSubTitle(l.themeEditorLines),
      color(
        'line.stroke',
        l.styleLabelColor,
        at(['line', 'stroke', 'color']),
        (j, c) => _setStroke(j, ['line', 'stroke'], c),
      ),
      ThemeEditorRow(
        label: l.styleLabelWeight,
        child: ThemeNumber(
          keyName: 'line.width',
          value:
              (ThemeEditScope.getPath(json, ['line', 'stroke', 'width'])
                  as num?) ??
              4,
          min: 1,
          max: 64,
          enabled: s.enabled,
          semanticLabel: l.styleLabelWeight,
          onChanged: (v) => s.edit(
            DeckThemeColumn.shapeStyleJson,
            (j) => ThemeEditScope.setPath(j, ['line', 'stroke', 'width'], v),
          ),
        ),
      ),
      ThemeEditorSubTitle(l.themeEditorIcons),
      color(
        'icon.stroke',
        l.styleLabelColor,
        at(['icon', 'stroke', 'color']),
        (j, c) => _setStroke(j, ['icon', 'stroke'], c, width: 2),
      ),
      ThemeEditorSubTitle(l.styleLabelShadow),
      color(
        'shadow.color',
        l.styleLabelColor,
        shadow is Map ? shadow['color'] as String? : null,
        (j, c) => ThemeEditScope.setPath(j, ['shadow', 'color'], c),
      ),
      ThemeEditorRow(
        label: l.themeEditorShadowBlur,
        child: ThemeNumber(
          keyName: 'shadow.blur',
          value: shadow is Map ? shadow['blur'] as num? : 32,
          max: 200,
          step: 4,
          enabled: s.enabled,
          semanticLabel: l.themeEditorShadowBlur,
          onChanged: (v) => s.edit(
            DeckThemeColumn.shapeStyleJson,
            (j) => ThemeEditScope.setPath(j, ['shadow', 'blur'], v),
          ),
        ),
      ),
      ThemeEditorRow(
        label: l.themeEditorShadowOffset,
        child: ThemeNumber(
          keyName: 'shadow.dy',
          value: shadow is Map ? shadow['dy'] as num? : 16,
          min: -200,
          max: 200,
          step: 4,
          enabled: s.enabled,
          semanticLabel: l.themeEditorShadowOffset,
          onChanged: (v) => s.edit(
            DeckThemeColumn.shapeStyleJson,
            (j) => ThemeEditScope.setPath(j, ['shadow', 'dy'], v),
          ),
        ),
      ),
      ThemeEditorSubTitle(l.themeEditorQuickStyles),
      for (final (i, q) in quick.indexed)
        if (q is Map)
          ThemeEditorRow(
            label: l.themeEditorQuickStyle(i + 1),
            child: Row(
              children: [
                Flexible(
                  child: ThemeRefColorButton(
                    keyName: 'quick$i.fill',
                    label: l.sectionFill,
                    value: _solidColor(q['fill']),
                    theme: s.deckResolved,
                    enabled: s.enabled,
                    resetLabel: l.styleLabelNoFill,
                    onChanged: (c) =>
                        s.edit(DeckThemeColumn.shapeStyleJson, (j) {
                          final list = (j['quickStyles'] as List).toList();
                          final m = (list[i] as Map).cast<String, Object?>();
                          _setFill(m, ['fill'], c);
                          list[i] = m;
                          j['quickStyles'] = list;
                        }),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: ThemeRefColorButton(
                    keyName: 'quick$i.text',
                    label: l.themeEditorTextColor,
                    value: q['textColor'] as String?,
                    theme: s.deckResolved,
                    enabled: s.enabled,
                    resetLabel: l.colorThemeDefault,
                    onChanged: (c) =>
                        s.edit(DeckThemeColumn.shapeStyleJson, (j) {
                          final list = (j['quickStyles'] as List).toList();
                          final m = (list[i] as Map).cast<String, Object?>();
                          ThemeEditScope.setPath(m, ['textColor'], c);
                          list[i] = m;
                          j['quickStyles'] = list;
                        }),
                  ),
                ),
              ],
            ),
          ),
    ],
  );
}

// ----------------------------------------------------------------- Tables

Widget _tables(ThemeEditScope s) {
  final l = s.l;
  final json = s.column(DeckThemeColumn.tableStyleJson);
  Widget color(String keyName, String label, List<String> path) {
    final v = ThemeEditScope.getPath(json, path);
    return ThemeEditorRow(
      label: label,
      child: ThemeRefColorButton(
        keyName: 'table.$keyName',
        label: label,
        value: v is String ? v : null,
        theme: s.deckResolved,
        enabled: s.enabled,
        resetLabel: l.colorNone,
        onChanged: (c) => s.edit(
          DeckThemeColumn.tableStyleJson,
          (j) => ThemeEditScope.setPath(j, path, c),
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: _TablePreview(theme: s.light, label: l.appearanceLight),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TablePreview(theme: s.dark, label: l.appearanceDark),
          ),
        ],
      ),
      const SizedBox(height: 8),
      color('header.fill', l.themeEditorHeaderFill, ['header', 'fill']),
      color('header.text', l.themeEditorHeaderText, [
        'header',
        'text',
        'color',
      ]),
      color('body.fill', l.themeEditorBodyFill, ['body', 'fill']),
      color('band', l.themeEditorBandFill, ['bandFill']),
      ThemeEditorRow(
        label: l.themeEditorCornerRadius,
        child: ThemeNumber(
          keyName: 'table.radius',
          value: ThemeEditScope.getPath(json, ['radius']) as num? ?? 0,
          max: 96,
          step: 4,
          enabled: s.enabled,
          semanticLabel: l.themeEditorCornerRadius,
          onChanged: (v) =>
              s.edit(DeckThemeColumn.tableStyleJson, (j) => j['radius'] = v),
        ),
      ),
    ],
  );
}

/// A three-row table drawn with a theme's table style.
class _TablePreview extends StatelessWidget {
  const _TablePreview({required this.theme, required this.label});

  final ResolvedTheme theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = theme.tableStyle;
    final ui = ShadTheme.of(context);
    Color c(ColorRef? ref, String fallback) =>
        Color(ref == null ? theme.colorOf(fallback)! : theme.color(ref));
    final rows = [
      c(t.header.fill, 'accent1'),
      c(t.body.fill, 'bg1'),
      t.bandFill == null ? c(t.body.fill, 'bg1') : c(t.bandFill, 'bg2'),
      c(t.body.fill, 'bg1'),
    ];
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Color(theme.colorOf('bg1') ?? 0xffffffff),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ui.colorScheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (t.radius / 6).clamp(0, 8).toDouble(),
          ),
          child: Column(
            children: [
              for (final fill in rows)
                Container(
                  height: 9,
                  margin: const EdgeInsets.only(bottom: 1),
                  color: fill,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- Code

Widget _code(ThemeEditScope s) {
  final l = s.l;
  final json = s.column(DeckThemeColumn.codeStyleJson);
  final ids = BuiltInPalettes.json.keys.toList();
  String name(String id) => BuiltInPalettes.byId(id)?.name ?? id;
  Widget palette(String which, String label) {
    final v = ThemeEditScope.getPath(json, ['palettes', which]) as String?;
    return ThemeEditorRow(
      label: label,
      trailing: v == null ? null : _PaletteSwatch(id: v),
      child: ThemeSelect(
        keyName: 'code.$which',
        value: v,
        options: ids,
        labelOf: name,
        enabled: s.enabled,
        onChanged: (p) => s.edit(
          DeckThemeColumn.codeStyleJson,
          (j) => ThemeEditScope.setPath(j, ['palettes', which], p),
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      palette('light', l.themeEditorLightPalette),
      palette('dark', l.themeEditorDarkPalette),
      ThemeEditorRow(
        label: l.themeEditorWindowChrome,
        child: ThemeSelect(
          keyName: 'code.chrome',
          value: json['chrome'] as String? ?? 'window',
          options: const ['none', 'tab', 'window', 'caption'],
          labelOf: (v) => switch (v) {
            'tab' => l.themeEditorChromeTab,
            'window' => l.themeEditorChromeWindow,
            'caption' => l.themeEditorChromeCaption,
            _ => l.colorNone,
          },
          enabled: s.enabled,
          onChanged: (v) =>
              s.edit(DeckThemeColumn.codeStyleJson, (j) => j['chrome'] = v),
        ),
      ),
      ThemeEditorRow(
        label: l.themeEditorCornerRadius,
        child: ThemeNumber(
          keyName: 'code.radius',
          value:
              ThemeEditScope.getPath(json, ['box', 'cornerRadius']) as num? ??
              16,
          max: 96,
          step: 4,
          enabled: s.enabled,
          semanticLabel: l.themeEditorCornerRadius,
          onChanged: (v) => s.edit(
            DeckThemeColumn.codeStyleJson,
            (j) => ThemeEditScope.setPath(j, ['box', 'cornerRadius'], v),
          ),
        ),
      ),
      ThemeEditorRow(
        label: l.styleLabelShadow,
        child: ThemeSelect(
          keyName: 'code.shadow',
          value:
              ThemeEditScope.getPath(json, ['box', 'shadow']) as String? ??
              'soft',
          options: const ['none', 'soft', 'strong'],
          labelOf: (v) => switch (v) {
            'soft' => l.themeEditorShadowSoft,
            'strong' => l.themeEditorShadowStrong,
            _ => l.colorNone,
          },
          enabled: s.enabled,
          onChanged: (v) => s.edit(
            DeckThemeColumn.codeStyleJson,
            (j) => ThemeEditScope.setPath(j, ['box', 'shadow'], v),
          ),
        ),
      ),
    ],
  );
}

/// The background with keyword / string / comment colors of palette [id].
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final p = BuiltInPalettes.byId(id);
    if (p == null) return const SizedBox.shrink();
    final ui = ShadTheme.of(context);
    Widget dot(SyntaxToken t) => Container(
      width: 5,
      height: 10,
      margin: const EdgeInsets.only(left: 2),
      color: Color(p.tokens[t]?.color ?? p.text),
    );
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Color(p.background),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: ui.colorScheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot(SyntaxToken.keyword),
          dot(SyntaxToken.string),
          dot(SyntaxToken.comment),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- Charts

Widget _charts(ThemeEditScope s) {
  final l = s.l;
  final json = s.column(DeckThemeColumn.chartStyleJson);
  final palette = ((json['palette'] as List?) ?? const []).cast<Object?>();
  Widget color(String keyName, String label, String key) {
    final v = json[key];
    return ThemeEditorRow(
      label: label,
      child: ThemeRefColorButton(
        keyName: 'chart.$keyName',
        label: label,
        value: v is String ? v : null,
        theme: s.deckResolved,
        enabled: s.enabled,
        onChanged: (c) =>
            s.edit(DeckThemeColumn.chartStyleJson, (j) => j[key] = c),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: _ChartPreview(theme: s.light, label: l.appearanceLight),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ChartPreview(theme: s.dark, label: l.appearanceDark),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final (i, c) in palette.indexed)
        ThemeEditorRow(
          label: l.themeEditorSeries(i + 1),
          child: ThemeRefColorButton(
            keyName: 'chart.series$i',
            label: l.themeEditorSeries(i + 1),
            value: c is String ? c : null,
            theme: s.deckResolved,
            enabled: s.enabled,
            onChanged: (v) => s.edit(DeckThemeColumn.chartStyleJson, (j) {
              final list = (j['palette'] as List).toList();
              list[i] = v;
              j['palette'] = list;
            }),
          ),
        ),
      color('text', l.themeEditorTextColor, 'textColor'),
      color('gridlines', l.themeEditorGridlines, 'gridlines'),
      color('axis', l.themeEditorAxis, 'axis'),
      ThemeEditorRow(
        label: l.themeEditorLighting,
        child: ThemeSelect(
          keyName: 'chart.lighting',
          value:
              ThemeEditScope.getPath(json, ['threeD', 'lighting']) as String? ??
              'soft',
          options: const ['soft', 'studio', 'flat'],
          labelOf: (v) => switch (v) {
            'studio' => l.themeEditorLightingStudio,
            'flat' => l.themeEditorLightingFlat,
            _ => l.themeEditorLightingSoft,
          },
          enabled: s.enabled,
          onChanged: (v) => s.edit(
            DeckThemeColumn.chartStyleJson,
            (j) => ThemeEditScope.setPath(j, ['threeD', 'lighting'], v),
          ),
        ),
      ),
    ],
  );
}

/// Bars in the series colors on the theme background.
class _ChartPreview extends StatelessWidget {
  const _ChartPreview({required this.theme, required this.label});

  final ResolvedTheme theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = ShadTheme.of(context);
    final colors = theme.chartPalette;
    return Semantics(
      label: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        decoration: BoxDecoration(
          color: Color(theme.colorOf('bg1') ?? 0xffffffff),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ui.colorScheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, c) in colors.indexed)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 8.0 + (i * 7 % 22),
                  color: Color(c),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
