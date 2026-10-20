import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../../l10n/write_l10n.dart';
import '../themes/document_theme.dart';
import '../themes/theme_settings.dart';
import 'write_settings_commands.dart';

/// Write settings (Write 05 §13.3, suite 04 §4): the app settings of
/// Wonky Write at `/settings/app/:section` — Editor, Page & export,
/// Document themes and Spelling. Every change is a command (`write.prefs.*`,
/// `write.spell.*`, `write.theme.*`); values live in
/// `UserPreferences.writeDefaults`.
List<SettingsSectionSpec> writeSettingsSections(ShellServices services) => [
  SettingsSectionSpec(
    id: 'editor',
    title: (c) => writeL10n(c).settingsWriteEditor,
    icon: LucideIcons.squarePen,
    builder: (_) => WriteEditorSettings(services: services),
  ),
  SettingsSectionSpec(
    id: 'page',
    title: (c) => writeL10n(c).settingsWritePage,
    icon: LucideIcons.fileText,
    builder: (_) => WritePageSettings(services: services),
  ),
  SettingsSectionSpec(
    id: 'themes',
    title: (c) => writeL10n(c).settingsDocumentThemes,
    icon: LucideIcons.palette,
    builder: (_) => ThemeSettingsSection(
      services: services,
      themes: themeCatalogFor(services),
    ),
  ),
  SettingsSectionSpec(
    id: 'spelling',
    title: (c) => writeL10n(c).settingsWriteSpelling,
    icon: LucideIcons.spellCheck,
    builder: (_) => WriteSpellingSettings(services: services),
  ),
];

/// Invokes a settings command from the settings UI.
void _invoke(
  ShellServices s,
  BuildContext context,
  String id, [
  Map<String, Object?> args = const {},
]) => unawaited(
  s.dispatcher.invoke(
    id,
    args: args,
    source: InvocationSource.ui,
    context: context,
  ),
);

/// A switch row bound to a boolean `writeDefaults` key and its command
/// (`{enabled: bool}`).
Widget _toggle(
  ShellServices s,
  BuildContext context, {
  required String command,
  required String prefKey,
  required String label,
  String? description,
  bool fallback = true,
}) => SettingsRow(
  label: label,
  description: description,
  control: ShadSwitch(
    key: ValueKey<String>('settings.write.$prefKey'),
    value: s.prefs.writeDefaults[prefKey] as bool? ?? fallback,
    onChanged: (v) => _invoke(s, context, command, {'enabled': v}),
  ),
);

/// Write settings › Editor: typing aids, display and the default mode of
/// documents shared with you.
class WriteEditorSettings extends StatelessWidget {
  const WriteEditorSettings({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final s = services;
    return ListenableBuilder(
      listenable: s.prefs,
      builder: (context, _) {
        final l = writeL10n(context);
        final mode =
            s.prefs.writeDefaults['defaultMode'] as String? ?? 'editing';
        String modeLabel(String m) => switch (m) {
          'suggesting' => l.screenModeSuggesting,
          'viewing' => l.screenModeViewing,
          _ => l.screenModeEditing,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsGroup(
              title: l.settingsWriteTyping,
              children: [
                _toggle(
                  s,
                  context,
                  command: 'write.prefs.setMarkdownShortcuts',
                  prefKey: 'markdownShortcuts',
                  label: l.cmdPrefsSetMarkdownShortcuts,
                ),
                _toggle(
                  s,
                  context,
                  command: 'write.prefs.setSmartTypography',
                  prefKey: 'smartQuotes',
                  label: l.cmdPrefsSetSmartTypography,
                ),
                _toggle(
                  s,
                  context,
                  command: 'write.prefs.setAutoPair',
                  prefKey: 'autoPairBrackets',
                  label: l.cmdPrefsSetAutoPair,
                ),
                _toggle(
                  s,
                  context,
                  command: 'write.prefs.setAutolink',
                  prefKey: 'autolink',
                  label: l.cmdPrefsSetAutolink,
                ),
                _toggle(
                  s,
                  context,
                  command: 'write.prefs.setCopyAsMarkdown',
                  prefKey: 'copyAsMarkdown',
                  label: l.cmdPrefsSetCopyAsMarkdown,
                ),
              ],
            ),
            SettingsGroup(
              title: l.settingsWriteDisplay,
              children: [
                _toggle(
                  s,
                  context,
                  command: 'write.spell.toggle',
                  prefKey: 'spellcheck',
                  label: l.cmdSpellToggle,
                ),
                _toggle(
                  s,
                  context,
                  command: 'write.prefs.setSelectionToolbar',
                  prefKey: 'selectionToolbar',
                  label: l.cmdPrefsSetSelectionToolbar,
                ),
                SettingsRow(
                  label: l.settingsWriteDefaultMode,
                  description: l.settingsWriteDefaultModeHint,
                  control: SizedBox(
                    width: 180,
                    child: ShadSelect<String>(
                      key: ValueKey<String>('settings.write.defaultMode.$mode'),
                      initialValue: mode,
                      minWidth: 180,
                      options: [
                        for (final m in const [
                          'editing',
                          'suggesting',
                          'viewing',
                        ])
                          ShadOption(value: m, child: Text(modeLabel(m))),
                      ],
                      selectedOptionBuilder: (context, v) => Text(modeLabel(v)),
                      onChanged: (v) {
                        if (v != null) {
                          _invoke(s, context, 'write.prefs.setDefaultMode', {
                            'mode': v,
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Write settings › Page & export: default layout, the saved default page
/// setup and the default export format.
class WritePageSettings extends StatelessWidget {
  const WritePageSettings({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final s = services;
    return ListenableBuilder(
      listenable: s.prefs,
      builder: (context, _) {
        final l = writeL10n(context);
        final d = s.prefs.writeDefaults;
        // Pageless unless the user chose Pages (T-1).
        final layout = d[WriteSettingsKeys.pageless] == false
            ? 'pages'
            : 'pageless';
        final format = d[WriteSettingsKeys.exportFormat] as String? ?? 'md';
        final hasPageSetup = d[WriteSettingsKeys.pageSetup] != null;
        String layoutLabel(String v) =>
            v == 'pageless' ? l.pageSetupPageless : l.pageSetupPages;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsGroup(
              title: l.settingsWritePageGroup,
              children: [
                SettingsRow(
                  label: l.settingsWriteDefaultLayout,
                  control: SizedBox(
                    width: 180,
                    child: ShadSelect<String>(
                      key: ValueKey<String>('settings.write.layout.$layout'),
                      initialValue: layout,
                      minWidth: 180,
                      options: [
                        for (final v in const ['pages', 'pageless'])
                          ShadOption(value: v, child: Text(layoutLabel(v))),
                      ],
                      selectedOptionBuilder: (context, v) =>
                          Text(layoutLabel(v)),
                      onChanged: (v) {
                        if (v != null) {
                          _invoke(s, context, 'write.prefs.setDefaultLayout', {
                            'layout': v,
                          });
                        }
                      },
                    ),
                  ),
                ),
                SettingsRow(
                  label: l.settingsWriteDefaultPageSetup,
                  description: hasPageSetup
                      ? l.settingsWritePageSetupSaved
                      : l.settingsWritePageSetupHint,
                  control: ShadButton.outline(
                    key: const ValueKey<String>(
                      'settings.write.resetPageSetup',
                    ),
                    enabled: hasPageSetup,
                    onPressed: () =>
                        _invoke(s, context, 'write.prefs.resetPageSetup'),
                    child: Text(l.settingsWriteResetPageSetup),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: l.settingsWriteExportGroup,
              children: [
                SettingsRow(
                  label: l.cmdPrefsSetExportFormat,
                  control: SizedBox(
                    width: 240,
                    child: ShadSelect<String>(
                      key: ValueKey<String>(
                        'settings.write.exportFormat.$format',
                      ),
                      initialValue: format,
                      minWidth: 240,
                      options: [
                        for (final f in writeDefaultExportFormats)
                          ShadOption(
                            value: f,
                            child: Text(_exportFormatLabel(l, f)),
                          ),
                      ],
                      selectedOptionBuilder: (context, v) => Text(
                        _exportFormatLabel(l, v),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          _invoke(s, context, 'write.prefs.setExportFormat', {
                            'format': v,
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

String _exportFormatLabel(WriteLocalizations l, String id) => switch (id) {
  'html' => l.exportFormatHtml,
  'pdf' => l.exportFormatPdf,
  'docx' => l.exportFormatDocx,
  'odt' => l.exportFormatOdt,
  'txt' => l.exportFormatTxt,
  _ => l.exportFormatMd,
};

/// Write settings › Spelling: uppercase words and the personal dictionary
/// (view, remove words; words are added from the editor's spelling menu).
class WriteSpellingSettings extends StatelessWidget {
  const WriteSpellingSettings({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final s = services;
    return ListenableBuilder(
      listenable: s.prefs,
      builder: (context, _) {
        final l = writeL10n(context);
        final theme = ShadTheme.of(context);
        final words = personalDictionaryOf(s)..sort();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsGroup(
              title: l.settingsWriteSpellingGroup,
              children: [
                SettingsRow(
                  label: l.cmdSpellToggleIgnoreUppercase,
                  control: ShadSwitch(
                    key: const ValueKey<String>(
                      'settings.write.spellcheckIgnoreUppercase',
                    ),
                    value:
                        s.prefs.writeDefaults['spellcheckIgnoreUppercase']
                            as bool? ??
                        true,
                    onChanged: (_) => _invoke(
                      s,
                      context,
                      'write.spell.toggleIgnoreUppercase',
                    ),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: l.settingsWriteDictionary,
              description: l.settingsWriteDictionaryHint,
              children: [
                if (words.isEmpty)
                  Text(
                    l.settingsWriteDictionaryEmpty,
                    key: const ValueKey<String>(
                      'settings.write.dictionary.empty',
                    ),
                    style: theme.textTheme.muted,
                  )
                else
                  for (final w in words)
                    Row(
                      key: ValueKey<String>('settings.write.dictionary.$w'),
                      children: [
                        Expanded(
                          child: Text(
                            w,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.small,
                          ),
                        ),
                        ShadIconButton.ghost(
                          width: 28,
                          height: 28,
                          iconSize: 14,
                          semanticLabel: l.settingsWriteDictionaryRemove(w),
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => _invoke(
                            s,
                            context,
                            'write.prefs.removeDictionaryWord',
                            {'word': w},
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}
