import 'theme_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/model.dart';

import '../../l10n/sheets_l10n.dart';
import '../../theme/sheets_tokens.dart';
import '../formatting/cell_fonts.dart';
import '../formatting/formatting_features.dart';
import '../formatting/panel_widgets.dart';
import '../formatting/sheets_colors.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'theme_controller.dart';

/// The *Themes* side panel (06 §13.3): preset cards (font, accents, mini
/// table) and *Customize* (font, text/background/accent/link colors, reset
/// to preset). Picks are previewed on the grid; *Done* commits
/// `sheets.theme.set` (one undo step), *Cancel* discards.
class ThemePanel extends StatefulWidget {
  const ThemePanel({super.key, required this.services, required this.editor});

  final ShellServices services;
  final SheetEditorController editor;

  @override
  State<ThemePanel> createState() => _ThemePanelState();
}

class _ThemePanelState extends State<ThemePanel> {
  late SpreadsheetTheme _draft = c.stored;

  SheetEditorController get ed => widget.editor;
  ThemeController get c => FormattingFeatures.of(ed).theme;

  @override
  void dispose() {
    FormattingFeatures.maybeOf(ed)?.theme.preview(null);
    super.dispose();
  }

  void _set(SpreadsheetTheme t) {
    setState(() => _draft = t);
    c.preview(t == c.stored ? null : t);
  }

  /// The preset the draft derives from (by name), if any.
  SpreadsheetTheme? get _basePreset => SpreadsheetTheme.preset(_draft.name);

  bool get _customized {
    final p = _basePreset;
    return p != null && p != _draft;
  }

  Future<void> _done() async {
    if (_draft == c.stored) {
      _close();
      return;
    }
    final r = await widget.services.invokeWithToasts(
      'sheets.theme.set',
      args: {'themeJson': _draft.toJson()},
      context: context,
    );
    if (r.isOk) _close();
  }

  void _close() {
    c.preview(null);
    widget.services.panels.close(FormattingPanels.theme);
    ed.gridFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final d = _draft;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _done,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _done,
      },
      child: FormatPanelFrame(
        key: const ValueKey<String>('theme.panel'),
        title: l.themePanelTitle,
        footer: PanelDoneFooter(
          keyPrefix: 'theme',
          cancelLabel: la.actionCancel,
          doneLabel: l.panelDone,
          onCancel: _close,
          onDone: ed.canEdit ? _done : null,
        ),
        children: [
          PanelSection(
            label: l.themePresets,
            top: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in SpreadsheetTheme.presets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ThemeCard(
                      key: ValueKey<String>('theme.preset.${p.name}'),
                      theme: p,
                      selected: d.name == p.name,
                      current: c.stored.name == p.name,
                      label: themePresetLabel(l, p.name),
                      onPressed: () => _set(p),
                    ),
                  ),
              ],
            ),
          ),
          PanelSection(
            label: l.themeCustomize,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l.themeFont)),
                    SizedBox(
                      width: 170,
                      child: CellFontSelect(
                        keyName: 'theme.font',
                        value: d.textFont,
                        onChanged: (f) =>
                            _set(d.copyWith(textFont: f, name: d.name)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final key in SpreadsheetTheme.colorKeys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(themeColorLabel(l, key))),
                        SizedBox(
                          width: 170,
                          child: SheetsColorButton(
                            key: ValueKey<String>('theme.color.$key'),
                            label: themeColorLabel(l, key),
                            theme: d,
                            withThemeColors: false,
                            value: d.colors[key],
                            onChanged: (v) {
                              if (v == null) return;
                              _set(
                                d.copyWith(
                                  colors: {...d.colors, key: v.toUpperCase()},
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_customized)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShadButton.link(
                      key: const ValueKey<String>('theme.reset'),
                      size: ShadButtonSize.sm,
                      padding: EdgeInsets.zero,
                      onPressed: () => _set(_basePreset!),
                      child: Text(l.themeResetToPreset),
                    ),
                  ),
                // Import theme (06 §13, P2): previewed until Done.
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.link(
                    key: const ValueKey<String>('theme.import'),
                    size: ShadButtonSize.sm,
                    padding: EdgeInsets.zero,
                    enabled: ed.canEdit,
                    onPressed: () async {
                      final t = await ThemeImport.pick(context, ed);
                      if (t != null && mounted) _set(t);
                    },
                    child: Text(l.themeImport),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Localized name of a theme preset.
String themePresetLabel(SheetsLocalizations l, String name) => switch (name) {
  'Standard' => l.themeStandard,
  'Simple' => l.themeSimple,
  'Streamline' => l.themeStreamline,
  'Paperback' => l.themePaperback,
  'Marina' => l.themeMarina,
  'Coral' => l.themeCoral,
  'Forest' => l.themeForest,
  'Mono' => l.themeMono,
  'Retro' => l.themeRetro,
  'Ocean' => l.themeOcean,
  _ => name,
};

/// A select of cell font families, each rendered in its face (06 §6.1).
/// Unbundled names show "Displayed as …".
class CellFontSelect extends StatelessWidget {
  const CellFontSelect({
    super.key,
    required this.keyName,
    required this.value,
    required this.onChanged,
  });

  final String keyName;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final fonts = [
      if (!CellFonts.isBundled(value)) value,
      ...CellFonts.bundled,
    ];
    return PanelSelect<String>(
      keyName: keyName,
      value: value,
      options: {for (final f in fonts) f: f},
      optionBuilder: (context, f, label) {
        final bundled = CellFonts.isBundled(f);
        return Text(
          bundled ? f : l.fontDisplayedAs(f, CellFonts.displayFamily(f)),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: CellFonts.screenFamily(f),
            fontStyle: bundled ? null : FontStyle.italic,
          ),
        );
      },
      onChanged: onChanged,
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.current,
    required this.label,
    required this.onPressed,
  });

  final SpreadsheetTheme theme;
  final bool selected;
  final bool current;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final shad = ShadTheme.of(context);
    Color c(String key) =>
        hexToColor(theme.resolveColor('theme:$key')) ?? const Color(0xFF000000);
    final font = CellFonts.screenFamily(theme.textFont);
    return Semantics(
      button: true,
      selected: selected,
      label: current ? '$label, ${l.themeCurrent}' : label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed();
              return null;
            },
          ),
        },
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return GestureDetector(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: shad.colorScheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: selected || focused ? 2 : 1,
                    color: selected
                        ? shad.colorScheme.primary
                        : focused
                        ? shad.colorScheme.ring
                        : shad.colorScheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    // Mini table: header in accent 1, text in the theme font.
                    Container(
                      width: 64,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c('background'),
                        border: Border.all(color: shad.colorScheme.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(height: 10, color: c('accent1')),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Aa',
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 15,
                                  color: c('text'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                  style: shad.textTheme.small.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (current) ...[
                                const SizedBox(width: 6),
                                ShadBadge.secondary(
                                  child: Text(l.themeCurrent),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            theme.textFont,
                            overflow: TextOverflow.ellipsis,
                            style: shad.textTheme.muted.copyWith(
                              fontFamily: font,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              for (var i = 1; i <= 6; i++)
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(right: 3),
                                  decoration: BoxDecoration(
                                    color: c('accent$i'),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
