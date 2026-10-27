import 'dart:async';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/emoji.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaSelection, DeltaUtils;
import '../features/editor/commands/editor_command_catalog.dart';
import 'package:wonky_app/platform.dart';
import '../features/editor/popovers/editor_popovers.dart';
import '../features/images/image_services.dart';
import '../features/import/import_service.dart';
import '../features/screen/write_document_controller.dart';
import '../features/special_chars/special_chars_dialog.dart';
import '../features/spellcheck/spelling_dialogs.dart';
import '../features/spellcheck/write_spellcheck.dart';
import '../l10n/write_l10n.dart';
import 'editor_commands.dart';
import 'write_command.dart';

/// Commands of the editor extras (Write 04 §17.4 lightbox, §18.4 in-place
/// table editing, §20 emoji and special characters, §30 focus mode and
/// typewriter scrolling).
List<Command<CommandArgs>> extrasCommands(ShellServices s) => [
  WriteCommand(
    'write.insert.emoji',
    label: (l) => l.cmdInsertEmoji,
    icon: LucideIcons.smile,
    categoryName: (l) => l.categoryInsert,
    requiredRole: Role.commenter,
    isUndoable: true,
    needsEditable: true,
    descriptionText: (l) => l.cmdInsertEmojiDescription,
    argsSchema: const JsonSchema.object(
      properties: {'emoji': JsonSchema.string()},
    ),
    enabled: (d, a) => d.commands.canEdit,
    undoLabelOf: (l, _) => l.undoInsertEmoji,
    run: (ctx, d, a) async {
      final direct = a.string('emoji');
      if (direct != null && direct.isNotEmpty) {
        final l = writeL10nOf(s);
        return okIf(
          d.commands.insertText(direct, label: l.undoInsertEmoji),
          l.reasonNotAvailable,
        );
      }
      final c = ctx.dialogContext;
      if (c == null) return const CommandResult.failed('emoji is required');
      var chosen = false;
      await showEmojiPickerDialog(
        c,
        prefs: emojiPrefsOf(s),
        anchor: _caretAnchor(d),
        onSelected: (emoji) {
          chosen = d.commands.insertText(
            emoji,
            label: writeL10nOf(s).undoInsertEmoji,
          );
        },
      );
      d.focusEditor();
      return chosen
          ? const CommandResult.ok()
          : const CommandResult.cancelled();
    },
  ),
  WriteCommand(
    'write.image.preview',
    label: (l) => l.cmdImagePreview,
    icon: LucideIcons.maximize,
    categoryName: (l) => l.categoryImages,
    descriptionText: (l) => l.cmdImagePreviewDescription,
    argsSchema: const JsonSchema.object(
      properties: {'nodeId': JsonSchema.string()},
    ),
    enabled: (d, a) => d.embedData('image', a.string('nodeId')) != null,
    run: (ctx, d, a) async {
      final data = d.embedData('image', a.string('nodeId'));
      final c = ctx.dialogContext;
      final l = writeL10nOf(s);
      if (data == null) {
        return CommandResult.failed(l.commandToastNoImageSelected);
      }
      if (c == null) return const CommandResult.failed('No window');
      final ok = await openLightbox(
        c,
        resolve: () => d.images.resolve('${data['src'] ?? ''}'),
        alt: '${data['alt'] ?? ''}',
        title: data['title'] as String?,
      );
      d.focusEditor();
      return okIf(ok, l.commandToastImageUnavailable);
    },
  ),
  WriteCommand(
    'write.table.editCell',
    label: (l) => l.cmdTableEditCell,
    categoryName: (l) => l.categoryTables,
    requiredRole: Role.editor,
    descriptionText: (l) => l.cmdTableEditCellDescription,
    argsSchema: const JsonSchema.object(
      properties: {
        'nodeId': JsonSchema.string(),
        'row': JsonSchema.integer(minimum: 0),
        'col': JsonSchema.integer(minimum: 0),
      },
    ),
    needsEditable: true,
    enabled: (d, a) =>
        d.editor.tableEditing != null &&
        d.commands.canEditTable(nodeId: a.string('nodeId')),
    run: (ctx, d, a) {
      final table = d.commands.tableOf(nodeId: a.string('nodeId'));
      final editing = d.editor.tableEditing;
      final l = writeL10nOf(s);
      if (table == null || editing == null) {
        return CommandResult.failed(l.commandToastNoTableSelected);
      }
      return okIf(
        editing.activate(
          table.id,
          a.integer('row') ?? 0,
          a.integer('col') ?? 0,
          selectAll: true,
        ),
        l.reasonNotAvailable,
      );
    },
  ),
];

/// Spellcheck commands (Write 04 §28.2).
List<Command<CommandArgs>> spellCommands(ShellServices s) {
  bool pref(String key, bool fallback) =>
      s.prefs.writeDefaults[key] as bool? ?? fallback;
  return [
    WriteGlobalCommand(
      'write.spell.toggle',
      label: (l) => l.cmdSpellToggle,
      categoryName: (l) => l.categoryTools,
      argsSchema: const JsonSchema.object(
        properties: {'enabled': JsonSchema.boolean()},
      ),
      checked: (ctx, a) => pref('spellcheck', true),
      run: (ctx, a) async {
        await s.prefs.setWriteDefault(
          'spellcheck',
          a.boolean('enabled') ?? !pref('spellcheck', true),
        );
        return const CommandResult.ok();
      },
    ),
    WriteGlobalCommand(
      'write.spell.toggleIgnoreUppercase',
      label: (l) => l.cmdSpellToggleIgnoreUppercase,
      categoryName: (l) => l.categoryTools,
      checked: (ctx, a) => pref('spellcheckIgnoreUppercase', true),
      run: (ctx, a) async {
        await s.prefs.setWriteDefault(
          'spellcheckIgnoreUppercase',
          !pref('spellcheckIgnoreUppercase', true),
        );
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.spell.replace',
      label: (l) => l.cmdSpellReplace,
      categoryName: (l) => l.categoryTools,
      requiredRole: Role.commenter,
      isUndoable: true,
      needsEditable: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'start': JsonSchema.integer(minimum: 0),
          'length': JsonSchema.integer(minimum: 1),
          'word': JsonSchema.string(),
        },
        required: ['start', 'length', 'word'],
      ),
      undoLabelOf: (l, _) => l.undoCorrectSpelling,
      run: (ctx, d, a) {
        final ok = d.commands.replaceRangeWithTextLabelled(
          a.integer('start')!,
          a.integer('length')!,
          a.requireString('word'),
          label: writeL10nOf(s).undoCorrectSpelling,
        );
        d.focusEditor();
        return okIf(ok, writeL10nOf(s).reasonNotAvailable);
      },
    ),
    WriteCommand(
      'write.spell.ignore',
      label: (l) => l.cmdSpellIgnore,
      categoryName: (l) => l.categoryTools,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {'word': JsonSchema.string()},
        required: ['word'],
      ),
      run: (ctx, d, a) {
        d.spellcheck.ignore(a.requireString('word'));
        d.focusEditor();
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.spell.addToDictionary',
      label: (l) => l.cmdSpellAddToDictionary,
      categoryName: (l) => l.categoryTools,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {'word': JsonSchema.string()},
        required: ['word'],
      ),
      run: (ctx, d, a) async {
        await addToPersonalDictionary(s, d, a.requireString('word'));
        d.focusEditor();
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.spell.nextError',
      label: (l) => l.cmdSpellNextError,
      categoryName: (l) => l.categoryTools,
      defaultBindings: const [KeyBinding("'", mod: true)],
      keyScope: KeyScope.editor,
      enabled: (d, a) => d.spellcheck.errors.isNotEmpty,
      run: (ctx, d, a) {
        final errors = d.spellcheck.errors;
        if (errors.isEmpty) {
          return CommandResult.failed(
            writeL10nOf(s).commandToastNoSpellingErrors,
          );
        }
        final from = d.editor.selection?.end ?? 0;
        final next = errors.firstWhere(
          (e) => e.start >= from,
          orElse: () => errors.first,
        );
        d.editor.select(DeltaSelection(next.start, next.end));
        d.revealOffset?.call(next.start);
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.spell.check',
      label: (l) => l.cmdSpellCheck,
      icon: LucideIcons.spellCheck,
      categoryName: (l) => l.categoryTools,
      run: (ctx, d, a) async {
        final c = ctx.dialogContext;
        if (c == null) return const CommandResult.failed('No window');
        if (d.spellcheck.state == SpellcheckState.off) {
          await s.prefs.setWriteDefault('spellcheck', true);
        }
        await d.spellcheck.whenSettled();
        d.spellcheck.checkAllNow();
        if (!c.mounted) return const CommandResult.cancelled();
        await showSpellingDialog(
          c,
          spellcheck: d.spellcheck,
          controller: d.editor,
          commands: d.commands,
          addToDictionary: (w) => addToPersonalDictionary(s, d, w),
        );
        d.focusEditor();
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.spell.personalDictionary',
      label: (l) => l.cmdSpellPersonalDictionary,
      categoryName: (l) => l.categoryTools,
      run: (ctx, d, a) async {
        final c = ctx.dialogContext;
        if (c == null) return const CommandResult.failed('No window');
        await showPersonalDictionaryDialog(
          c,
          words: () => d.personalDictionary,
          onAdd: (w) => addToPersonalDictionary(s, d, w),
          onRemove: (w) => s.prefs.setWriteDefault('personalDictionary', [
            for (final x in d.personalDictionary)
              if (x != w) x,
          ]),
        );
        return const CommandResult.ok();
      },
    ),
  ];
}

/// Adds [word] to the synced personal dictionary (max 10,000 words).
Future<void> addToPersonalDictionary(
  ShellServices s,
  WriteDocumentController d,
  String word,
) async {
  final words = d.personalDictionary;
  if (words.contains(word)) return;
  if (words.length >= 10000) {
    s.toasts.error(writeL10nOf(s).commandToastPersonalDictionaryFull(10000));
    return;
  }
  d.spellcheck.wordAdded(word);
  await s.prefs.setWriteDefault('personalDictionary', [...words, word]);
}

/// The spelling section at the top of the canvas context menu (Write 04
/// §28.2): suggestions for the misspelled word at the caret, Ignore, Add to
/// dictionary.
List<WonkyMenuEntry> spellingMenuEntries(
  WriteDocumentController d,
  void Function(String id, Map<String, Object?> args) run,
) {
  final sel = d.editor.selection;
  if (sel == null || !d.editable) return const [];
  final error = d.spellcheck.errorAt(sel.start);
  if (error == null) return const [];
  final suggestions = d.spellcheck.suggestionsFor(error.word);
  final l = writeL10nOf(d.services);
  return [
    if (suggestions.isEmpty)
      WonkyMenuLabel(l.commandMenuNoSpellingSuggestions)
    else
      for (var i = 0; i < suggestions.length; i += 1)
        WonkyMenuItem(
          key: ValueKey<String>('menu.spell.suggestion.$i'),
          label: suggestions[i],
          icon: i == 0 ? LucideIcons.spellCheck : null,
          onSelected: () => run('write.spell.replace', {
            'start': error.start,
            'length': error.length,
            'word': suggestions[i],
          }),
        ),
    WonkyMenuItem(
      key: const ValueKey<String>('menu.spell.ignore'),
      label: l.cmdSpellIgnore,
      onSelected: () => run('write.spell.ignore', {'word': error.word}),
    ),
    WonkyMenuItem(
      key: const ValueKey<String>('menu.spell.add'),
      label: l.commandMenuAddWordToDictionary(error.word),
      onSelected: () =>
          run('write.spell.addToDictionary', {'word': error.word}),
    ),
    const WonkyMenuSeparator(),
  ];
}

/// Overrides of catalog commands (merged into `editorCommands`).
Map<String, WriteRun Function(EditorCommandSpec spec)> extrasOverrides(
  ShellServices s,
) => {
  // Without a character (menus, palette) the dialog opens (Write 04 §20.2).
  'write.insert.specialCharacter': (spec) => (ctx, d, a) async {
    if (a.string('char') != null) return runSpec(spec, d, a);
    final c = ctx.dialogContext;
    if (c == null) return const CommandResult.failed('char is required');
    var inserted = 0;
    await showSpecialCharactersDialog(
      c,
      store: s.userStore,
      onInsert: (char) {
        if (d.commands.insertText(
          char,
          label: writeL10nOf(s).undoInsertSpecialCharacter,
        )) {
          inserted += 1;
        }
      },
    );
    d.focusEditor();
    return inserted > 0
        ? const CommandResult.ok()
        : const CommandResult.cancelled();
  },
};

EmojiPrefs? _emojiPrefs;
LocalStore? _emojiPrefsStore;

/// The per-user emoji preferences (recents, skin tone).
EmojiPrefs emojiPrefsOf(ShellServices s) {
  if (_emojiPrefs == null || !identical(_emojiPrefsStore, s.userStore)) {
    _emojiPrefsStore = s.userStore;
    _emojiPrefs = EmojiPrefs(s.userStore);
    unawaited(_emojiPrefs!.load());
  }
  return _emojiPrefs!;
}

Rect? _caretAnchor(WriteDocumentController d) {
  final s = d.editor.selection;
  return s == null ? null : d.globalRectForOffset(s.end);
}

/// The `:` emoji trigger's suggestions (Write 04 §20.1); empty until the
/// catalog is loaded (it loads on the first query).
EmojiSuggester emojiSuggester(ShellServices s) {
  EmojiCatalog? catalog;
  var loading = false;
  void load() {
    if (loading) return;
    loading = true;
    unawaited(
      EmojiCatalog.load().then<void>((value) => catalog = value).catchError((
        Object _,
      ) {
        loading = false;
      }),
    );
  }

  // Loaded with the screen so the first `:query` already has results.
  load();
  return (query) {
    final c = catalog;
    if (c == null) {
      load();
      return const [];
    }
    final tone = emojiPrefsOf(s).skinTone;
    final q = query.toLowerCase();
    return [
      for (final e in c.search(q, limit: 8))
        EmojiSuggestion(
          emoji: e.withSkinTone(tone),
          name: e.name,
          shortcode:
              e.shortcodes.where((x) => x.startsWith(q)).firstOrNull ??
              e.shortcodes.firstOrNull,
        ),
    ];
  };
}

/// Files dropped onto the canvas before block [index] (Write 04 §24):
/// images upload, documents import after a confirmation, anything else is
/// refused with a toast.
Future<void> handleDroppedFiles(
  ShellServices s,
  WriteDocumentController d,
  List<DroppedFile> files,
  int index, {
  BuildContext? context,
}) async {
  if (!d.editable || files.isEmpty) return;
  final images = <PickedImage>[];
  final documents = <DroppedFile>[];
  for (final f in files) {
    if (writeImportExtensions.contains(f.extension) &&
        !ImageRules.extensions.contains(f.extension)) {
      documents.add(f);
      continue;
    }
    try {
      final mime = ImageRules.validate(f.name, f.bytes);
      images.add(PickedImage(name: f.name, bytes: f.bytes, mimeType: mime));
    } on ImageRejected catch (e) {
      s.toasts.error(
        ImageRules.extensions.contains(f.extension) || f.extension == 'svg'
            ? e.messageIn(writeL10nOf(s))
            : writeL10nOf(s).commandToastUnsupportedFileType,
        description: f.name,
      );
    }
  }
  if (images.isNotEmpty && !await imagesFitStorage(s, images)) {
    images.clear();
  }
  if (images.isNotEmpty) {
    final values = [
      for (final p in images.take(20))
        {
          'image': {
            'id': d.editor.newEmbedId(),
            'src': d.images.startUpload(p),
            'alt': '',
          },
        },
    ];
    final lines = Delta();
    for (final v in values) {
      lines
        ..insert(v)
        ..insert('\n');
    }
    final change = d.commands.insertBlocksAt(
      index,
      lines,
      label: writeL10nOf(s).undoInsertImages(values.length),
    );
    if (change == null) {
      for (final v in values) {
        d.images.cancel('${(v['image'] as Map)['src']}');
      }
    }
  }
  for (final f in documents.take(1)) {
    final c = context;
    if (c == null || !c.mounted) return;
    final ok = await confirmDialog(
      c,
      title: writeL10n(c).commandDialogInsertFileContentsTitle(f.name),
      confirmLabel: writeL10n(c).commonInsert,
    );
    if (!ok) continue;
    try {
      final converted = await convertImport(
        f.name,
        f.bytes,
        uploadImage: importImageUploader(s, itemUuid: d.itemUuid),
        l: writeL10nOf(s),
        flavor: d.markdownFlavor,
      );
      var delta = converted.result.delta;
      final last = delta.isEmpty ? null : delta.last.data;
      if (last is! String || !last.endsWith('\n')) {
        delta = delta.compose(
          Delta()
            ..retain(DeltaUtils.documentLength(delta))
            ..insert('\n'),
        );
      }
      d.commands.insertBlocksAt(
        index,
        delta,
        label: writeL10nOf(s).undoInsertFile,
      );
      if (converted.warnings.isNotEmpty) {
        s.toasts.show(
          writeL10nOf(s).commandToastInsertedFile(f.name),
          description: converted.warnings.take(5).join('\n'),
        );
      }
    } catch (e) {
      s.toasts.error(
        writeL10nOf(s).commandToastCouldNotInsertFile(f.name),
        description: '$e',
      );
    }
  }
  d.focusEditor();
}
