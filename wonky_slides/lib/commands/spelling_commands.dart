import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/special_chars.dart';
import 'package:wonky_app/spellcheck.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/find.dart';
import 'package:wonky_slides_core/ops.dart' show Patch, SetDeckProps;

import '../features/canvas/canvas_interactions.dart';
import '../features/canvas/slide_canvas_controller.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/notes/notes_pane.dart';
import '../features/settings/slides_settings.dart' show slidesLanguages;
import '../features/settings/slides_user_defaults.dart';
import '../features/spellcheck/slides_spelling.dart';
import '../features/spellcheck/spelling_actions.dart';
import '../features/spellcheck/spelling_canvas.dart';
import '../features/spellcheck/spelling_session.dart';
import '../features/spellcheck/text_inserts.dart';
import '../features/text_editing/text_editing_host.dart';
import '../l10n/slides_l10n.dart' show slidesL10nOf;
import 'slides_command.dart';

/// Spelling, the presentation language and special characters (Slides 03
/// §14; SL-44): Tools › Spelling (*Check spelling…*, *Underline errors*,
/// *Personal dictionary…*), the context-menu actions on a misspelled word
/// (replace, ignore, add to dictionary), File › Language ▸ and Insert ›
/// Special characters…. Registers the canvas squiggles and the spelling of
/// the text and notes editors.
List<Command<CommandArgs>> spellingCommands(ShellServices s) {
  CanvasInteractions.register(SpellingCanvasLayer.new);
  if (!SlideTextEditing.addonFactories.contains(canvasSpellingAddon)) {
    SlideTextEditing.addonFactories.add(canvasSpellingAddon);
  }
  if (!NotesPane.addonFactories.contains(notesSpellingAddon)) {
    NotesPane.addonFactories.add(notesSpellingAddon);
  }
  NotesPane.contextMenuEntries = notesSpellingMenu;
  return [
    SlidesCommand(
      'slides.spelling.check',
      label: (l) => l.cmdSpellingCheck,
      icon: LucideIcons.spellCheck,
      categoryOf: SlidesCategory.tools,
      descriptionText: (l) => l.cmdSpellingCheckDescription,
      argsSchema: const JsonSchema.object(
        properties: {
          'limit': JsonSchema.integer(
            minimum: 1,
            description: 'Agents: the most issues listed (default 200).',
          ),
        },
      ),
      run: (ctx, ed, a) async {
        final spelling = SlidesSpelling.of(ed);
        await spelling.whenSettled();
        if (ctx.source.isAgent || ctx.dialogContext == null) {
          final issues = spelling.deckIssues();
          final limit = a.integer('limit') ?? 200;
          return ok({
            'language': spelling.language,
            'dictionary': spelling.dictionaryTag,
            'available': spelling.isReady,
            'count': issues.length,
            'issues': [
              for (final i in issues.take(limit))
                i.toJson(suggestions: spelling.suggestionsFor(i.word)),
            ],
          });
        }
        final dc = ctx.dialogContext!;
        if (!dc.mounted) return const CommandResult.cancelled();
        await showSpellingDialog(
          dc,
          session: SlidesSpellingSession(ed),
          keys: SpellingKeys.slides,
        );
        return ok();
      },
    ),
    SlidesCommand(
      'slides.spelling.toggleUnderline',
      label: (l) => l.cmdSpellingToggleUnderline,
      categoryOf: SlidesCategory.tools,
      argsSchema: const JsonSchema.object(
        properties: {'enabled': JsonSchema.boolean()},
      ),
      checked: (ed, a) => SlidesSpelling.of(ed).underline,
      run: (ctx, ed, a) async {
        final on = a.boolean('enabled') ?? !SlidesSpelling.of(ed).underline;
        final err = await SlidesUserDefaults.of(
          ed.services,
        ).set(SlidesUserDefaults.keyUnderlineSpelling, on);
        if (err != null) return CommandResult.failed(err);
        SlidesSpelling.of(ed).refresh();
        SlideCanvasController.of(ed)?.refresh();
        return ok({'enabled': on});
      },
    ),
    SlidesCommand(
      'slides.spelling.replace',
      label: (l) => l.cmdSpellingReplace,
      categoryOf: SlidesCategory.tools,
      mutates: true,
      showInPalette: false,
      argsSchema: JsonSchema.object(
        properties: {
          ..._targetProps,
          'start': const JsonSchema.integer(
            minimum: 0,
            description: 'Offset of the word in the body\'s plain text.',
          ),
          'length': const JsonSchema.integer(minimum: 1),
          'word': const JsonSchema.string(
            description: 'The misspelled word expected at the range.',
          ),
          'replacement': const JsonSchema.string(),
        },
        required: const ['start', 'length', 'replacement'],
      ),
      undoLabelOf: (l, a) => l.undoCorrectSpelling,
      run: (ctx, ed, a) {
        final l = slidesL10nOf(ed.services);
        final t = spellingTargetOf(a);
        if (t == null) {
          return const CommandResult.failed(
            'elementId (with rowId and columnId for a table cell) or '
            'notesSlideId is required',
          );
        }
        textEditingOf(ed).commit();
        final json = spellingBodyOf(ed, t);
        if (json == null) return CommandResult.failed(l.reasonSpellingTextGone);
        final start = a.integer('start')!, length = a.integer('length')!;
        final plain = DeckFind.plainOf(json);
        if (start + length > plain.length) {
          return const CommandResult.failed('The range is outside the text');
        }
        final word = a.string('word');
        if (word != null && plain.substring(start, start + length) != word) {
          return CommandResult.failed(
            slidesL10nOf(ed.services).errorTextChanged,
          );
        }
        final r = replaceSpelling(ed, {
          t: [(start, length, a.requireString('replacement'))],
        }, (op) => ed.apply(ctx, op));
        if (r.replaced == 0) {
          return CommandResult.failed(
            r.holder == null
                ? l.reasonSpellingTextGone
                : l.toastFindBodyLocked(r.holder!),
          );
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.spelling.replaceAll',
      label: (l) => l.cmdSpellingReplaceAll,
      categoryOf: SlidesCategory.tools,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'word': JsonSchema.string(description: 'The misspelled word.'),
          'replacement': JsonSchema.string(),
        },
        required: ['word', 'replacement'],
      ),
      undoLabelOf: (l, a) => l.undoCorrectSpelling,
      run: (ctx, ed, a) async {
        await SlidesSpelling.of(ed).whenSettled();
        final edits = spellingEditsFor(
          ed,
          a.requireString('word'),
          a.requireString('replacement'),
        );
        final r = replaceSpelling(ed, edits, (op) => ed.apply(ctx, op));
        return ok({'replaced': r.replaced, 'skipped': r.skipped});
      },
    ),
    SlidesCommand(
      'slides.spelling.ignore',
      label: (l) => l.cmdSpellingIgnore,
      categoryOf: SlidesCategory.tools,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {'word': JsonSchema.string()},
        required: ['word'],
      ),
      run: (ctx, ed, a) {
        SlidesSpelling.of(ed).ignore(a.requireString('word'));
        _refocus(ed);
        return ok();
      },
    ),
    SlidesCommand(
      'slides.spelling.addToDictionary',
      label: (l) => l.cmdSpellingAddToDictionary,
      categoryOf: SlidesCategory.tools,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {'word': JsonSchema.string()},
        required: ['word'],
      ),
      run: (ctx, ed, a) async {
        final word = a.requireString('word').trim();
        if (word.isEmpty || word.contains(RegExp(r'\s'))) {
          return CommandResult.failed(slidesL10nOf(ed.services).errorOneWord);
        }
        final added = await SlidesSpelling.of(ed).addToDictionary(word);
        if (!added) {
          final msg = slidesL10nOf(
            ed.services,
          ).toastPersonalDictionaryFull(PersonalDictionary.maxWords);
          if (!ctx.source.isAgent) ed.services.toasts.error(msg);
          return CommandResult.failed(msg);
        }
        _refocus(ed);
        return ok();
      },
    ),
    SlidesCommand(
      'slides.spelling.personalDictionary',
      label: (l) => l.cmdSpellingPersonalDictionary,
      categoryOf: SlidesCategory.tools,
      argsSchema: const JsonSchema.object(
        properties: {
          'add': JsonSchema.string(description: 'Agents: a word to add.'),
          'remove': JsonSchema.string(description: 'Agents: a word to remove.'),
        },
      ),
      run: (ctx, ed, a) async {
        final spelling = SlidesSpelling.of(ed);
        final add = a.string('add'), remove = a.string('remove');
        if (ctx.source.isAgent || add != null || remove != null) {
          if (add != null && !await spelling.addToDictionary(add)) {
            return CommandResult.failed(
              slidesL10nOf(
                ed.services,
              ).toastPersonalDictionaryFull(PersonalDictionary.maxWords),
            );
          }
          if (remove != null) await spelling.removeFromDictionary(remove);
          return ok({'words': spelling.personalWords});
        }
        final dc = ctx.dialogContext;
        if (dc == null) return ok({'words': spelling.personalWords});
        await showPersonalDictionaryDialog(
          dc,
          words: () => spelling.personalWords,
          onAdd: (w) => spelling.addToDictionary(w),
          onRemove: spelling.removeFromDictionary,
          keys: SpellingKeys.slides,
        );
        return ok();
      },
    ),
    SlidesCommand(
      'slides.file.setLanguage',
      label: (l) => l.cmdFileSetLanguage,
      icon: LucideIcons.languages,
      categoryOf: SlidesCategory.file,
      mutates: true,
      argsSchema: JsonSchema.object(
        properties: {
          'language': JsonSchema.string(
            description:
                'BCP 47 tag of the presentation language (spelling), e.g. '
                '${slidesLanguages.map((e) => e.$1).join(', ')}.',
          ),
        },
        required: const ['language'],
      ),
      checked: (ed, a) {
        final want = a.string('language');
        if (want == null) return null;
        return SlidesSpelling.of(ed).language.toLowerCase() ==
            want.toLowerCase();
      },
      undoLabelOf: (l, a) => l.undoSetLanguage,
      run: (ctx, ed, a) {
        final lang = a.requireString('language').trim();
        if (lang.isEmpty ||
            !RegExp(r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$').hasMatch(lang)) {
          return const CommandResult.failed(
            'A BCP 47 language tag is expected',
          );
        }
        ed.apply(ctx, SetDeckProps(language: Patch(lang)));
        SlidesSpelling.of(ed).refresh();
        return ok({'language': lang});
      },
    ),
    SlidesCommand(
      'slides.insert.specialCharacter',
      label: (l) => l.cmdInsertSpecialCharacter,
      icon: LucideIcons.omega,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'char': JsonSchema.string(
            description:
                'The character(s) to type at the caret (omit to '
                'choose in the dialog).',
          ),
        },
      ),
      enabled: (ed, a) => isEditingText(ed),
      reason: (l, ed) => l.reasonNotEditingText,
      run: (ctx, ed, a) async {
        final char = a.string('char');
        if (char != null) {
          return insertIntoEditedText(ed, char)
              ? ok()
              : CommandResult.failed(
                  slidesL10nOf(ed.services).reasonNotEditingText,
                );
        }
        final dc = ctx.dialogContext;
        if (dc == null || ctx.source.isAgent) {
          return const CommandResult.failed('char is required');
        }
        await showSpecialCharactersDialog(
          dc,
          onInsert: (ch) => insertIntoEditedText(ed, ch),
          store: ed.services.userStore,
          keys: SpecialCharsKeys.slides,
        );
        if (isEditingText(ed)) textEditingOf(ed).editorFocus.requestFocus();
        return ok();
      },
    ),
  ];
}

const _targetProps = <String, JsonSchema>{
  'elementId': JsonSchema.string(
    description: 'The text box, shape or table (with rowId/columnId).',
  ),
  'rowId': JsonSchema.string(),
  'columnId': JsonSchema.string(),
  'notesSlideId': JsonSchema.string(
    description: 'The slide whose speaker notes hold the word.',
  ),
};

/// Back to the text being edited after a context-menu action.
void _refocus(DeckEditorController ed) {
  final host = textEditingOf(ed);
  if (host.isEditing) host.editorFocus.requestFocus();
}
