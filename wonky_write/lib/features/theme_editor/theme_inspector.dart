import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart' as core;
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        BoolProp,
        BorderProp,
        ColorProp,
        ContrastResult,
        EdgesProp,
        EnumProp,
        FeatureListProp,
        FontProp,
        FontRegistry,
        IntProp,
        LengthKind,
        LengthProp,
        ListProp,
        NumberProp,
        ObjectProp,
        PaletteKey,
        PropType,
        StringProp,
        SyntaxToken,
        ThemeElement,
        ThemePropertyPath,
        ThemeVariant,
        WeightProp,
        argbToHex,
        listNumberStyleValues;

import '../../l10n/write_l10n.dart';
import 'theme_controls.dart';
import 'theme_editor_controller.dart';
import 'theme_editor_model.dart';

/// What the inspector can do (the screen routes these through the
/// `write.theme.*` commands so every change is a command, suite 08).
abstract interface class ThemeEditActions {
  void setProperty(
    String path,
    Object? value, {
    ThemeVariant? variant,
    String? gesture,
  });
  void resetElement(ThemeNode node);
  void fixContrast(String pairId, ThemeVariant variant);
  void rename();
  void duplicate();
}

/// The property inspector of the theme editor (Write 06 §10.2, right
/// column): groups of typed controls for the selected node, contrast
/// warnings with *Fix*, and the dark-variant overrides.
class ThemeInspector extends StatelessWidget {
  const ThemeInspector({
    super.key,
    required this.controller,
    required this.actions,
  });

  final ThemeEditorController controller;
  final ThemeEditActions actions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _InspectorBody(c: controller, a: actions),
    );
  }
}

class _InspectorBody extends StatelessWidget {
  const _InspectorBody({required this.c, required this.a});

  final ThemeEditorController c;
  final ThemeEditActions a;

  ThemeNode get node => c.selected;
  bool get enabled => !c.readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    final warnings = c.warningsOf(node);
    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(
              node.label(l),
              key: const ValueKey<String>('write.themeEditor.inspector.title'),
              style: theme.textTheme.large.copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (enabled && c.hasOverrides(node))
            ShadButton.ghost(
              key: const ValueKey<String>('write.themeEditor.resetElement'),
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.rotateCcw, size: 14),
              onPressed: () => a.resetElement(node),
              child: Text(l.commonReset),
            ),
        ],
      ),
      if (c.readOnly) ...[
        const SizedBox(height: 8),
        _ReadOnlyBanner(c: c, a: a),
      ],
      if (c.lastError case final e?) ...[
        const SizedBox(height: 8),
        ShadAlert.destructive(
          icon: const Icon(LucideIcons.circleAlert),
          title: Text(e),
        ),
      ],
      for (final w in warnings) ...[
        const SizedBox(height: 8),
        _ContrastWarning(result: w, onFix: enabled ? a.fixContrast : null),
      ],
      const SizedBox(height: 8),
      ..._content(context),
    ];
    return ListView(
      key: const ValueKey<String>('write.themeEditor.inspector'),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 32),
      children: children,
    );
  }

  List<Widget> _content(BuildContext context) => switch (node.kind) {
    ThemeNodeKind.general => _general(context),
    ThemeNodeKind.palette => _palette(context),
    ThemeNodeKind.fonts => _fonts(context),
    ThemeNodeKind.syntax => _syntax(context),
    ThemeNodeKind.element ||
    ThemeNodeKind.page ||
    ThemeNodeKind.headerFooter ||
    ThemeNodeKind.advanced => _sections(context),
  };

  // ---------------------------------------------------------- sections

  List<Widget> _sections(BuildContext context) {
    final l = writeL10n(context);
    final out = <Widget>[];
    if (node.kind == ThemeNodeKind.advanced) {
      out.add(_Note(l.themeInspectorOverlaysNote));
    }
    for (final (title, prefix, object) in sectionsOf(l, node)) {
      if (title.isNotEmpty) out.add(_SectionTitle(title));
      final groups = <PropGroup, List<Widget>>{};
      for (final f in object.fields.entries) {
        final key = f.key;
        if (node.element != null && !_shownFor(node.element!, key)) continue;
        final g = groupOf(key);
        groups
            .putIfAbsent(g, () => [])
            .addAll(_prop(context, '$prefix.$key', key, f.value));
      }
      for (final g in PropGroup.values) {
        final rows = groups[g];
        if (rows == null || rows.isEmpty) continue;
        out
          ..add(_GroupTitle(propGroupLabel(l, g, node)))
          ..addAll(rows);
      }
    }
    final e = node.element;
    if (e != null) out.addAll(_darkOverrides(context, e));
    return out;
  }

  /// Hides properties that have no visible effect for the element.
  static bool _shownFor(ThemeElement e, String key) => switch (key) {
    'firstLineIndent' => false, // P2: behind a feature flag (06 §6.5)
    'lineNumbers' => false, // P2
    _ => true,
  };

  List<Widget> _prop(
    BuildContext context,
    String path,
    String key,
    PropType type, {
    ThemeVariant? variant,
    String? label,
  }) {
    final l = writeL10n(context);
    final qualified = ThemePropertyPath.qualify(path, variant);
    Object? raw;
    try {
      raw = ThemePropertyPath.get(c.draftJson, qualified);
    } on core.ThemePathException {
      raw = null;
    }
    final inherited = raw == null
        ? ThemeInheritance.of(c.draftJson, qualified)
        : null;
    final effective = raw ?? inherited?.value;
    final name =
        label ??
        (key == 'numbering' && node.element == ThemeElement.list
            ? l.themeInspectorNumberingPerLevel
            : propLabel(l, key));
    void set(Object? v, {String? gesture}) =>
        a.setProperty(path, v, variant: variant, gesture: gesture);
    void reset() => set(null);
    final palette = c
        .resolved(
          variant ?? (path.startsWith('dark.') ? ThemeVariant.dark : null),
        )
        .palette;
    Widget row(Widget control, {bool wide = false}) => ThemePropRow(
      key: ValueKey<String>('write.themeEditor.prop.$qualified'),
      label: name,
      isSet: raw != null,
      inherited: inherited,
      onReset: reset,
      enabled: enabled,
      wide: wide,
      child: control,
    );
    switch (type) {
      case ObjectProp():
        return [
          _SubTitle(name),
          for (final f in type.fields.entries)
            ..._prop(
              context,
              '$path.${f.key}',
              f.key,
              f.value,
              variant: variant,
            ),
        ];
      case LengthProp():
        return [
          row(
            ThemeLengthField(
              value: effective is String ? effective : null,
              kind: type.kind,
              enabled: enabled,
              onChanged: (v) => set(v, gesture: qualified),
            ),
          ),
        ];
      case ColorProp():
        return [
          row(
            ThemeColorField(
              value: effective is String ? effective : null,
              palette: palette,
              enabled: enabled,
              semanticLabel: name,
              allowTransparent:
                  key.toLowerCase().contains('background') ||
                  key == 'paperColor' ||
                  key.endsWith('Bg'),
              onChanged: set,
            ),
          ),
        ];
      case FontProp():
        return [
          row(
            ThemeFontField(
              value: effective is String ? effective : null,
              roles: roleFonts(c.draft),
              enabled: enabled,
              onChanged: set,
            ),
          ),
        ];
      case WeightProp():
        final family = node.element == null
            ? c.draft.fonts.body
            : ThemeInheritance.familyOf(c.draft, c.draftJson, node.element!);
        final weights =
            FontRegistry.lookup(family)?.weights ??
            const [100, 200, 300, 400, 500, 600, 700, 800, 900];
        final current = effective is num ? '${effective.toInt()}' : null;
        return [
          row(
            ThemeEnumField(
              values: [for (final w in weights) '$w'],
              value: current,
              enabled: enabled,
              labelOf: (w) => _weightLabel(l, w),
              onChanged: (v) => set(int.parse(v)),
            ),
          ),
        ];
      case EnumProp():
        return [
          row(
            ThemeEnumField(
              values: type.values,
              value: effective is String ? effective : null,
              enabled: enabled,
              onChanged: set,
            ),
          ),
        ];
      case BoolProp():
        return [
          row(
            ShadSwitch(
              value: effective == true,
              enabled: enabled,
              onChanged: set,
            ),
          ),
        ];
      case NumberProp():
        final range = type.max - type.min;
        return [
          row(
            ThemeNumberField(
              value: effective is num ? effective : null,
              min: type.min,
              max: type.max,
              step: range <= 2 ? 0.05 : 0.1,
              enabled: enabled,
              slider: range <= 4,
              onChanged: (v) => set(v, gesture: qualified),
            ),
            wide: range <= 4,
          ),
        ];
      case IntProp():
        return [
          row(
            ThemeNumberField(
              value: effective is num ? effective : null,
              min: type.min,
              max: type.max,
              step: 1,
              digits: 0,
              slider: false,
              enabled: enabled,
              onChanged: (v) => set(v.toInt(), gesture: qualified),
            ),
          ),
        ];
      case StringProp():
        return [
          row(
            ThemeTextField(
              value: effective is String ? effective : null,
              maxLength: type.maxLength,
              width: 140,
              enabled: enabled,
              onChanged: set,
            ),
          ),
        ];
      case FeatureListProp():
        return [
          row(
            ThemeTextField(
              value: effective is List ? effective.join(', ') : null,
              placeholder: l.themeInspectorFeaturesHint,
              width: 160,
              enabled: enabled,
              onChanged: (v) {
                final tags = [
                  for (final t in v.split(RegExp(r'[\s,]+')))
                    if (t.isNotEmpty) t,
                ];
                set(tags.isEmpty ? null : tags);
              },
            ),
          ),
        ];
      case ListProp():
        return [
          row(
            _LevelList(
              values: effective is List
                  ? [for (final v in effective) '$v']
                  : const [],
              options: type.item is EnumProp
                  ? (type.item as EnumProp).values
                  : null,
              enabled: enabled,
              onChanged: set,
            ),
            wide: true,
          ),
        ];
      case BorderProp():
        return [
          row(
            _BorderEditor(
              value: effective is Map ? effective : null,
              palette: palette,
              enabled: enabled,
              onChanged: (v) => set(v, gesture: '$qualified.border'),
            ),
            wide: true,
          ),
        ];
      case EdgesProp(kind: final kind?):
        return [
          row(
            _EdgesEditor(
              value: effective,
              kind: kind,
              enabled: enabled,
              onChanged: (v) => set(v, gesture: qualified),
            ),
            wide: true,
          ),
        ];
      case EdgesProp():
        // Borders on all sides (uniform) or per side.
        final uniform = effective is Map && !_isPerSide(effective);
        return [
          row(
            _BorderEditor(
              value: uniform
                  ? effective
                  : (effective is Map ? effective['left'] as Map? : null),
              palette: palette,
              enabled: enabled,
              onChanged: (v) => set(v, gesture: '$qualified.border'),
            ),
            wide: true,
          ),
        ];
    }
  }

  static bool _isPerSide(Map<Object?, Object?> m) =>
      m.keys.any((k) => const {'top', 'right', 'bottom', 'left'}.contains(k));

  static String _weightLabel(WriteLocalizations l, String w) => switch (w) {
    '100' => l.fontWeightThin,
    '200' => l.fontWeightExtraLight,
    '300' => l.fontWeightLight,
    '400' => l.fontWeightRegular,
    '500' => l.fontWeightMedium,
    '600' => l.fontWeightSemibold,
    '700' => l.fontWeightBold,
    '800' => l.fontWeightExtraBold,
    '900' => l.fontWeightBlack,
    _ => w,
  };

  /// Dark-variant overrides of the element's colors (Write 06 §10.2).
  List<Widget> _darkOverrides(BuildContext context, ThemeElement e) {
    final object = core.ThemeCatalog.elements[e]!;
    final colors = [
      for (final f in object.fields.entries)
        if (f.value is ColorProp) f.key,
    ];
    if (colors.isEmpty) return const [];
    final l = writeL10n(context);
    return [
      _GroupTitle(l.themeInspectorDarkVariant),
      _Note(l.themeInspectorDarkOverridesNote),
      for (final k in colors)
        ..._prop(
          context,
          'elements.${e.name}.$k',
          k,
          const ColorProp(),
          variant: ThemeVariant.dark,
          label: l.themeInspectorDarkLabel(propLabel(l, k)),
        ),
    ];
  }

  // ------------------------------------------------------------ general

  List<Widget> _general(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    String? str(String path) {
      final v = ThemePropertyPath.get(c.draftJson, path);
      return v is String ? v : null;
    }

    return [
      ThemePropRow(
        label: l.themeInspectorName,
        child: Row(
          children: [
            Flexible(
              child: Text(
                c.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small,
              ),
            ),
            if (enabled)
              ShadButton.link(
                key: const ValueKey<String>('write.themeEditor.renameInline'),
                size: ShadButtonSize.sm,
                onPressed: a.rename,
                child: Text(l.commonRename),
              ),
          ],
        ),
      ),
      ThemePropRow(
        label: l.themeInspectorDescription,
        isSet: str('description') != null,
        onReset: () => a.setProperty('description', null),
        enabled: enabled,
        child: ThemeTextField(
          value: str('description'),
          maxLength: 200,
          width: 170,
          enabled: enabled,
          onChanged: (v) =>
              a.setProperty('description', v.trim().isEmpty ? null : v.trim()),
        ),
      ),
      _GroupTitle(l.themeInspectorDarkVariant),
      ThemePropRow(
        label: l.themeInspectorDarkColors,
        child: ThemeEnumField(
          values: const ['derived', 'explicit'],
          value: str('dark.mode') ?? 'derived',
          enabled: enabled,
          labelOf: (v) => v == 'derived'
              ? l.themeInspectorDarkDerived
              : l.themeInspectorDarkCustom,
          onChanged: (v) => a.setProperty('dark.mode', v),
        ),
      ),
      _Note(
        str('dark.mode') == 'explicit'
            ? l.themeInspectorDarkExplicitNote
            : l.themeInspectorDarkDerivedNote,
      ),
      if (c.record?.updatedAt case final at?) ...[
        _GroupTitle(l.themeInspectorAbout),
        ThemePropRow(
          label: l.themeInspectorVersion,
          child: Text(
            l.themeInspectorVersionSaved(c.version, at.toLocal()),
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        ),
      ],
    ];
  }

  // ------------------------------------------------------------ palette

  List<Widget> _palette(BuildContext context) {
    final l = writeL10n(context);
    final light = c.resolved(ThemeVariant.light).palette;
    final dark = c.resolved(ThemeVariant.dark).palette;
    final explicit =
        ThemePropertyPath.get(c.draftJson, 'dark.mode') == 'explicit';
    Widget pair(PaletteKey k) {
      final lightRaw = ThemePropertyPath.get(c.draftJson, 'palette.${k.name}');
      final darkRaw = ThemePropertyPath.get(
        c.draftJson,
        'dark.palette.${k.name}',
      );
      final derived = dark[k];
      return Padding(
        key: ValueKey<String>('write.themeEditor.palette.${k.name}'),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                paletteLabel(l, k),
                style: ShadTheme.of(
                  context,
                ).textTheme.small.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ThemeColorField(
              value: lightRaw is String ? lightRaw : null,
              palette: light,
              enabled: enabled,
              allowReset: k.isCustom,
              allowTransparent: k.role == core.PaletteRole.surface,
              width: 96,
              semanticLabel: l.themeInspectorLightLabel(paletteLabel(l, k)),
              onChanged: (v) => a.setProperty('palette.${k.name}', v),
            ),
            const SizedBox(width: 6),
            ThemeColorField(
              value: darkRaw is String
                  ? darkRaw
                  : (derived == null ? null : argbToHex(derived)),
              palette: dark,
              enabled: enabled,
              allowReset: !explicit,
              allowTransparent: k.role == core.PaletteRole.surface,
              width: 96,
              semanticLabel: l.themeInspectorDarkLabel(paletteLabel(l, k)),
              onChanged: (v) => a.setProperty(
                'palette.${k.name}',
                v,
                variant: ThemeVariant.dark,
              ),
            ),
          ],
        ),
      );
    }

    final theme = ShadTheme.of(context);
    return [
      _Note(
        explicit
            ? l.themeInspectorPaletteExplicitNote
            : l.themeInspectorPaletteDerivedNote,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Row(
          children: [
            const Spacer(),
            SizedBox(
              width: 102,
              child: Text(
                l.themeInspectorLight,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ),
            SizedBox(
              width: 96,
              child: Text(
                l.themeInspectorDark,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      for (final k in PaletteKey.values)
        if (!k.isCustom) pair(k),
      _GroupTitle(l.themeInspectorCustomColors),
      for (final k in PaletteKey.values)
        if (k.isCustom) pair(k),
    ];
  }

  // -------------------------------------------------------------- fonts

  List<Widget> _fonts(BuildContext context) {
    final l = writeL10n(context);
    return [
      _Note(l.themeInspectorFontsNote),
      for (final (role, label) in [
        ('body', l.themeInspectorFontBody),
        ('heading', l.themeInspectorFontHeadings),
        ('mono', l.themeInspectorFontCode),
      ])
        ThemePropRow(
          key: ValueKey<String>('write.themeEditor.prop.fonts.$role'),
          label: label,
          child: ThemeFontField(
            value: ThemePropertyPath.get(c.draftJson, 'fonts.$role') as String?,
            roles: const [],
            allowRoles: false,
            enabled: enabled,
            onChanged: (v) => a.setProperty('fonts.$role', v),
          ),
        ),
    ];
  }

  // ------------------------------------------------------------- syntax

  List<Widget> _syntax(BuildContext context) {
    final light = c.resolved(ThemeVariant.light);
    final dark = c.resolved(ThemeVariant.dark);
    final l = writeL10n(context);
    return [
      _Note(l.themeInspectorSyntaxNote),
      for (final t in SyntaxToken.values) ...[
        _SubTitle(syntaxLabel(l, t)),
        ..._prop(
          context,
          'syntax.${t.name}.color',
          'color',
          const ColorProp(),
          label: l.themePropColor,
        ),
        ..._prop(
          context,
          'syntax.${t.name}.fontStyle',
          'fontStyle',
          const EnumProp(['normal', 'italic']),
          label: l.themePropStyle,
        ),
        ThemePropRow(
          label: l.themeInspectorDarkLabel(l.themePropColor),
          isSet:
              ThemePropertyPath.get(
                c.draftJson,
                'dark.syntax.${t.name}.color',
              ) !=
              null,
          onReset: () => a.setProperty(
            'syntax.${t.name}.color',
            null,
            variant: ThemeVariant.dark,
          ),
          enabled: enabled,
          child: ThemeColorField(
            value:
                ThemePropertyPath.get(
                      c.draftJson,
                      'dark.syntax.${t.name}.color',
                    )
                    as String? ??
                (dark.syntax[t] == null
                    ? null
                    : argbToHex(dark.syntax[t]!.color)),
            palette: dark.palette,
            enabled: enabled,
            semanticLabel: l.themeInspectorDarkLabel(syntaxLabel(l, t)),
            onChanged: (v) => a.setProperty(
              'syntax.${t.name}.color',
              v,
              variant: ThemeVariant.dark,
            ),
          ),
        ),
        if (light.syntax[t] == null) _Note(l.themeInspectorUsesCodeTextColor),
      ],
    ];
  }
}

// ------------------------------------------------------------------ parts

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({required this.c, required this.a});

  final ThemeEditorController c;
  final ThemeEditActions a;

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final owner = c.record?.ownerName;
    final text = c.isBuiltin
        ? l.themeInspectorBuiltinReadOnly
        : c.isDeleted
        ? l.themeInspectorDeleted
        : owner == null
        ? l.themeInspectorBelongsToSomeoneElse
        : l.themeInspectorBelongsTo(owner);
    return ShadAlert(
      key: const ValueKey<String>('write.themeEditor.readOnly'),
      icon: const Icon(LucideIcons.lock),
      title: Text(text),
      description: Align(
        alignment: Alignment.centerLeft,
        child: ShadButton.link(
          key: const ValueKey<String>('write.themeEditor.duplicateToCustomize'),
          padding: EdgeInsets.zero,
          size: ShadButtonSize.sm,
          onPressed: a.duplicate,
          child: Flexible(
            child: Text(
              c.isBuiltin
                  ? l.themeEditorDuplicateToCustomize
                  : l.themeEditorCopyToMyThemes,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContrastWarning extends StatelessWidget {
  const _ContrastWarning({required this.result, this.onFix});

  final ContrastResult result;
  final void Function(String pairId, ThemeVariant variant)? onFix;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    final ratio = result.ratio.toStringAsFixed(1);
    final required = result.required.toStringAsFixed(1);
    final pair = pairLabel(l, result.pairId);
    return Container(
      key: ValueKey<String>(
        'write.themeEditor.contrast.${result.pairId}.${result.variant.name}',
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 16,
            color: theme.colorScheme.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.variant == ThemeVariant.dark
                  ? l.themeInspectorContrastWarningDark(ratio, pair, required)
                  : l.themeInspectorContrastWarning(ratio, pair, required),
              style: theme.textTheme.small.copyWith(fontSize: 12),
            ),
          ),
          if (onFix != null)
            ShadButton.outline(
              size: ShadButtonSize.sm,
              height: 28,
              onPressed: () => onFix!(result.pairId, result.variant),
              child: Text(l.themeInspectorFix),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 2),
    child: Text(
      text,
      style: ShadTheme.of(
        context,
      ).textTheme.small.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: theme.textTheme.muted.copyWith(
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: theme.colorScheme.border),
          ),
        ],
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 2),
    child: Text(
      text,
      style: ShadTheme.of(
        context,
      ).textTheme.small.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 12),
    ),
  );
}

/// Bullets (text) or numbering styles (select) for the 9 indent levels.
class _LevelList extends StatelessWidget {
  const _LevelList({
    required this.values,
    required this.onChanged,
    this.options,
    this.enabled = true,
  });

  final List<String> values;
  final List<String>? options;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    final list = values.length == 9
        ? values
        : List<String>.generate(
            9,
            (i) => values.isEmpty
                ? (options?.first ?? '•')
                : values[i % values.length],
          );
    void change(int i, String v) {
      final next = [...list]..[i] = v;
      onChanged(next);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < 9; i++)
          Semantics(
            container: true,
            label: l.themeInspectorLevel(i + 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.muted.copyWith(fontSize: 10),
                  ),
                ),
                if (options == null)
                  ThemeTextField(
                    value: list[i],
                    maxLength: 8,
                    width: 44,
                    enabled: enabled,
                    onChanged: (v) {
                      if (v.isNotEmpty) change(i, v);
                    },
                  )
                else
                  SizedBox(
                    width: 64,
                    child: ShadSelect<String>(
                      key: ValueKey<String>('level.$i.${list[i]}'),
                      initialValue: list[i],
                      enabled: enabled,
                      minWidth: 64,
                      selectedOptionBuilder: (context, v) =>
                          Text(enumLabel(l, v)),
                      onChanged: (v) {
                        if (v != null && v != list[i]) change(i, v);
                      },
                      options: [
                        for (final o in options ?? listNumberStyleValues)
                          ShadOption(value: o, child: Text(enumLabel(l, o))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A border `{width, style, color}`.
class _BorderEditor extends StatelessWidget {
  const _BorderEditor({
    required this.value,
    required this.palette,
    required this.onChanged,
    this.enabled = true,
  });

  final Map<Object?, Object?>? value;
  final Map<PaletteKey, int> palette;
  final bool enabled;
  final ValueChanged<Map<String, Object?>?> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value ?? const {};
    final l = writeL10n(context);
    void change(String key, Object? x) {
      final next = <String, Object?>{
        for (final e in v.entries) '${e.key}': e.value,
      };
      if (x == null) {
        next.remove(key);
      } else {
        next[key] = x;
      }
      onChanged(next.isEmpty ? null : next);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ThemeLengthField(
          value: v['width'] as String?,
          kind: LengthKind.stroke,
          enabled: enabled,
          onChanged: (x) => change('width', x),
        ),
        SizedBox(
          width: 104,
          child: ShadSelect<String>(
            key: ValueKey<String>('border.style.${v['style']}'),
            initialValue: v['style'] as String?,
            enabled: enabled,
            minWidth: 104,
            placeholder: Text(l.themePropStyle),
            selectedOptionBuilder: (context, s) => Text(enumLabel(l, s)),
            onChanged: (s) {
              if (s != null) change('style', s);
            },
            options: [
              for (final s in const [
                'none',
                'solid',
                'dashed',
                'dotted',
                'double',
              ])
                ShadOption(value: s, child: Text(enumLabel(l, s))),
            ],
          ),
        ),
        ThemeColorField(
          value: v['color'] as String?,
          palette: palette,
          enabled: enabled,
          semanticLabel: l.themePropBorderColor,
          onChanged: (x) => change('color', x),
        ),
      ],
    );
  }
}

/// Four lengths, linked (one value) or per side (Write 06 §10.3).
class _EdgesEditor extends StatefulWidget {
  const _EdgesEditor({
    required this.value,
    required this.kind,
    required this.onChanged,
    this.enabled = true,
  });

  final Object? value;
  final LengthKind kind;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  @override
  State<_EdgesEditor> createState() => _EdgesEditorState();
}

class _EdgesEditorState extends State<_EdgesEditor> {
  bool? _linked;

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    final sides = <String, String?>{
      for (final s in const ['top', 'right', 'bottom', 'left'])
        s: v is String ? v : (v is Map ? v[s] as String? : null),
    };
    final uniform = sides.values.toSet().length == 1;
    final linked = _linked ?? uniform;
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    Widget link = ShadTooltip(
      builder: (_) => Text(
        linked
            ? l.themeInspectorSetSidesSeparately
            : l.themeInspectorSameOnAllSides,
      ),
      child: ShadIconButton.ghost(
        width: 28,
        height: 28,
        iconSize: 14,
        semanticLabel: linked
            ? l.themeInspectorUnlinkSides
            : l.themeInspectorLinkSides,
        icon: Icon(linked ? LucideIcons.link : LucideIcons.unlink),
        onPressed: widget.enabled
            ? () => setState(() => _linked = !linked)
            : null,
      ),
    );
    if (linked) {
      return Row(
        children: [
          ThemeLengthField(
            value: sides['top'],
            kind: widget.kind,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
          ),
          link,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in const ['top', 'right', 'bottom', 'left'])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    enumLabel(l, s),
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ),
                ThemeLengthField(
                  value: sides[s],
                  kind: widget.kind,
                  enabled: widget.enabled,
                  onChanged: (x) => widget.onChanged(
                    {...sides, s: x}..removeWhere((_, v) => v == null),
                  ),
                ),
                if (s == 'top') link,
              ],
            ),
          ),
      ],
    );
  }
}
