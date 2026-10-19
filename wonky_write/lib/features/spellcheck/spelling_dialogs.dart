import 'package:flutter/widgets.dart';
import 'package:wonky_app/spellcheck.dart' as shell;

import 'package:wonky_write_core/wonky_write_core.dart' show DeltaSelection;
import '../editor/commands/write_editor_commands.dart';
import '../editor/controller/write_editor_controller.dart';
import 'write_spellcheck.dart';

// The dialogs themselves are the shell's (`package:wonky_app/spellcheck.dart`,
// Drive 05 D-7); Write provides the [shell.SpellingSession] over its editor.
export 'package:wonky_app/spellcheck.dart'
    show SpellingKeys, showPersonalDictionaryDialog;

/// Replaces every occurrence of [word] flagged in the document with
/// [replacement] as one undo step ("Change all"). Returns the count.
int changeAllSpelling(
  WriteSpellcheck spellcheck,
  WriteEditorController controller,
  WriteEditorCommands commands,
  String word,
  String replacement,
) {
  final matches = [
    for (final e in spellcheck.errors)
      if (e.word == word) e,
  ];
  if (matches.isEmpty) return 0;
  controller.group(controller.strings().undoCorrectSpelling, () {
    // Back to front so earlier offsets stay valid.
    for (final e in matches.reversed) {
      commands.replaceRangeWithTextLabelled(
        e.start,
        e.length,
        replacement,
        label: controller.strings().undoCorrectSpelling,
      );
    }
  });
  return matches.length;
}

/// The Check spelling dialog's view of a Write document.
class WriteSpellingSession implements shell.SpellingSession {
  WriteSpellingSession({
    required this.spellcheck,
    required this.controller,
    required this.commands,
    required this.onAddToDictionary,
  });

  final WriteSpellcheck spellcheck;
  final WriteEditorController controller;
  final WriteEditorCommands commands;
  final Future<void> Function(String word) onAddToDictionary;

  @override
  List<shell.SpellingIssue> get issues => [
    for (final e in spellcheck.errors)
      shell.SpellingIssue(e.word, e.start, e.end),
  ];

  @override
  bool get isAvailable => spellcheck.state == SpellcheckState.ready;

  @override
  int get startOffset => controller.selection?.start ?? 0;

  @override
  List<String> suggestionsFor(String word) => spellcheck.suggestionsFor(word);

  @override
  void select(shell.SpellingIssue issue) => controller.select(
    DeltaSelection(issue.start, issue.end),
    userInteraction: true,
  );

  @override
  void change(shell.SpellingIssue issue, String replacement) =>
      commands.replaceRangeWithTextLabelled(
        issue.start,
        issue.length,
        replacement,
        label: controller.strings().undoCorrectSpelling,
      );

  @override
  void changeAll(String word, String replacement) =>
      changeAllSpelling(spellcheck, controller, commands, word, replacement);

  @override
  void ignoreAll(String word) => spellcheck.ignore(word);

  @override
  Future<void> addToDictionary(String word) => onAddToDictionary(word);

  @override
  void recheck() => spellcheck.checkAllNow();
}

/// Tools › Spelling › Check spelling… (Write 05 §12): walks the flagged
/// words from the caret with Change, Change all, Ignore, Ignore all and Add
/// to dictionary.
Future<void> showSpellingDialog(
  BuildContext context, {
  required WriteSpellcheck spellcheck,
  required WriteEditorController controller,
  required WriteEditorCommands commands,
  required Future<void> Function(String word) addToDictionary,
}) => shell.showSpellingDialog(
  context,
  session: WriteSpellingSession(
    spellcheck: spellcheck,
    controller: controller,
    commands: commands,
    onAddToDictionary: addToDictionary,
  ),
);
