import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../../commands/write_command.dart';

/// Keys of `UserPreferences.writeDefaults` set by Write settings (Write 05
/// §13.3) that have no command of their own elsewhere.
abstract final class WriteSettingsKeys {
  /// Default layout of new documents: true = pageless (v1 key). Unset is
  /// Pageless (T-1); the server applies it when it creates a document
  /// (`UserService.defaultPageless`).
  static const pageless = 'pageless';

  /// Default export format id (`md`, `html`, `pdf`, `docx`, `odt`, `txt`).
  static const exportFormat = 'exportFormat';

  /// The page setup saved with *Page setup › Set as default*.
  static const pageSetup = 'pageSetup';

  /// The personal dictionary (list of words).
  static const personalDictionary = 'personalDictionary';
}

/// The export formats offered as the default (Write 05 §13.3).
const writeDefaultExportFormats = ['md', 'html', 'pdf', 'docx', 'odt', 'txt'];

/// Commands of the Write settings that the editor's own commands
/// (`write.prefs.set*`, `write.spell.*`) don't cover, so every setting is
/// MCP-operable (suite 04 §4.2). Settings are not undoable.
List<Command<CommandArgs>> writeSettingsCommands(ShellServices s) => [
  WriteGlobalCommand(
    'write.prefs.setDefaultLayout',
    label: (l) => l.cmdPrefsSetDefaultLayout,
    categoryName: (l) => l.categoryPreferences,
    argsSchema: const JsonSchema.object(
      properties: {
        'layout': JsonSchema.string(enumValues: ['pages', 'pageless']),
      },
      required: ['layout'],
    ),
    checked: (ctx, a) => a.string('layout') == null
        ? null
        : (s.prefs.writeDefaults[WriteSettingsKeys.pageless] == false
                  ? 'pages'
                  : 'pageless') ==
              a.string('layout'),
    run: (ctx, a) async {
      await s.prefs.setWriteDefault(
        WriteSettingsKeys.pageless,
        a.requireString('layout') == 'pageless',
      );
      return const CommandResult.ok();
    },
  ),
  WriteGlobalCommand(
    'write.prefs.setExportFormat',
    label: (l) => l.cmdPrefsSetExportFormat,
    categoryName: (l) => l.categoryPreferences,
    argsSchema: const JsonSchema.object(
      properties: {
        'format': JsonSchema.string(enumValues: writeDefaultExportFormats),
      },
      required: ['format'],
    ),
    checked: (ctx, a) => a.string('format') == null
        ? null
        : (s.prefs.writeDefaults[WriteSettingsKeys.exportFormat] ?? 'md') ==
              a.string('format'),
    run: (ctx, a) async {
      final f = a.requireString('format');
      if (!writeDefaultExportFormats.contains(f)) {
        return CommandResult.failed('Unknown format "$f"');
      }
      await s.prefs.setWriteDefault(WriteSettingsKeys.exportFormat, f);
      return const CommandResult.ok();
    },
  ),
  WriteGlobalCommand(
    'write.prefs.resetPageSetup',
    label: (l) => l.cmdPrefsResetPageSetup,
    categoryName: (l) => l.categoryPreferences,
    enabled: (ctx, a) =>
        s.prefs.writeDefaults[WriteSettingsKeys.pageSetup] != null,
    run: (ctx, a) async {
      await s.prefs.setWriteDefault(WriteSettingsKeys.pageSetup, null);
      return const CommandResult.ok();
    },
  ),
  WriteGlobalCommand(
    'write.prefs.removeDictionaryWord',
    label: (l) => l.cmdPrefsRemoveDictionaryWord,
    categoryName: (l) => l.categoryPreferences,
    argsSchema: const JsonSchema.object(
      properties: {'word': JsonSchema.string()},
      required: ['word'],
    ),
    run: (ctx, a) async {
      final word = a.requireString('word');
      final words = personalDictionaryOf(s);
      if (!words.contains(word)) {
        return CommandResult.failed('"$word" is not in the dictionary');
      }
      await s.prefs.setWriteDefault(WriteSettingsKeys.personalDictionary, [
        for (final w in words)
          if (w != word) w,
      ]);
      return const CommandResult.ok();
    },
  ),
];

/// The words of the personal dictionary (`writeDefaults`).
List<String> personalDictionaryOf(ShellServices s) {
  final raw = s.prefs.writeDefaults[WriteSettingsKeys.personalDictionary];
  return raw is List ? [for (final w in raw) ?(w is String ? w : null)] : [];
}
