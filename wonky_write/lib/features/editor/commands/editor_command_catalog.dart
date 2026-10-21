import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_core/wonky_core.dart';

import '../applier/delta_applier.dart';
import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import '../model/table_model.dart';
import '../paste/editor_clipboard.dart';
import 'write_editor_commands.dart';

/// What a command runs against: the editor of the active document.
class EditorCommandTarget {
  const EditorCommandTarget({
    required this.controller,
    required this.commands,
    required this.clipboard,
  });

  final WriteEditorController controller;
  final WriteEditorCommands commands;
  final EditorClipboard clipboard;
}

/// One editor command of the Write 04 §40 catalog, independent of the shell's
/// `Command` class: the screen wraps each spec in a `CallbackCommand`
/// (id, title, bindings, role, undoable, enabled, checked, run).
@immutable
class EditorCommandSpec {
  const EditorCommandSpec({
    required this.id,
    required this.title,
    required this.run,
    this.argsSchema = JsonSchema.empty,
    this.bindings = const [],
    this.requiredRole = Role.editor,
    this.isUndoable = true,
    this.suggestable = true,
    this.enabled,
    this.checked,
    this.category,
  });

  final String id;
  final String title;
  final JsonSchema argsSchema;
  final List<KeyBinding> bindings;

  /// Minimum role (commenters may run content commands only in Suggesting
  /// mode — `C*` in §40; the dispatcher checks [suggestable]).
  final Role requiredRole;
  final bool isUndoable;

  /// Whether commenters may run it in Suggesting mode (`C*`).
  final bool suggestable;
  final String? category;
  final bool Function(EditorCommandTarget target, JsonArgs args)? enabled;
  final bool? Function(EditorCommandTarget target, JsonArgs args)? checked;
  final FutureOr<CommandResult> Function(
    EditorCommandTarget target,
    JsonArgs args,
  )
  run;

  bool isEnabled(EditorCommandTarget target, JsonArgs args) =>
      enabled?.call(target, args) ?? true;
}

CommandResult _result(bool ok, [String? failure]) => ok
    ? const CommandResult.ok()
    : CommandResult.failed(failure ?? 'Not available here');

const _mod = true;

/// The editor command catalog (Write 04 §40).
List<EditorCommandSpec> editorCommandCatalog() {
  EditorCommandSpec format(
    String id,
    InlineFormat f,
    List<KeyBinding> bindings,
  ) => EditorCommandSpec(
    id: id,
    title: f.label,
    category: 'Format',
    bindings: bindings,
    requiredRole: Role.commenter,
    enabled: (t, _) => t.commands.canToggleFormat(f),
    checked: (t, _) => t.commands.isFormatActive(f),
    run: (t, _) => _result(t.commands.toggleFormat(f)),
  );

  EditorCommandSpec blockType(BlockKind kind, List<KeyBinding> bindings) =>
      EditorCommandSpec(
        id: 'write.format.blockType.${kind.name}',
        title: kind.label,
        category: 'Format',
        bindings: bindings,
        requiredRole: Role.commenter,
        enabled: (t, _) => t.commands.canChangeBlockType(),
        // Quote is on for list items inside a quote too.
        checked: (t, _) => kind == BlockKind.quote
            ? t.commands.selectionInQuote
            : t.commands.selectedBlockKind == kind,
        run: (t, _) => _result(t.commands.setBlockType(kind)),
      );

  final kinds = {for (final k in BlockKind.values) k.name};
  return [
    // Edit (§23.5).
    EditorCommandSpec(
      id: 'write.edit.copy',
      title: 'Copy',
      requiredRole: Role.viewer,
      isUndoable: false,
      bindings: const [KeyBinding('C', mod: _mod)],
      enabled: (t, _) => t.clipboard.canCopy,
      run: (t, _) async => _result(await t.clipboard.copy()),
    ),
    EditorCommandSpec(
      id: 'write.edit.cut',
      title: 'Cut',
      requiredRole: Role.commenter,
      bindings: const [KeyBinding('X', mod: _mod)],
      enabled: (t, _) => t.clipboard.canCopy && t.commands.canEdit,
      run: (t, _) async => _result(await t.clipboard.cut()),
    ),
    EditorCommandSpec(
      id: 'write.edit.paste',
      title: 'Paste',
      requiredRole: Role.commenter,
      bindings: const [KeyBinding('V', mod: _mod)],
      enabled: (t, _) => t.clipboard.canPaste,
      run: (t, _) async => _result(await t.clipboard.paste()),
    ),
    EditorCommandSpec(
      id: 'write.edit.pasteWithoutFormatting',
      title: 'Paste without formatting',
      requiredRole: Role.commenter,
      bindings: const [KeyBinding('V', mod: _mod, shift: true)],
      enabled: (t, _) => t.clipboard.canPaste,
      run: (t, _) async => _result(await t.clipboard.paste(plainOnly: true)),
    ),
    EditorCommandSpec(
      id: 'write.edit.pasteAsMarkdown',
      title: 'Paste as Markdown',
      requiredRole: Role.commenter,
      enabled: (t, _) => t.clipboard.canPaste,
      run: (t, _) async =>
          _result(await t.clipboard.paste(forceMarkdown: true)),
    ),
    for (final (format, title) in [
      (CopyFormat.markdown, 'Copy as Markdown'),
      (CopyFormat.plainText, 'Copy as plain text'),
      (CopyFormat.html, 'Copy as HTML'),
    ])
      EditorCommandSpec(
        id:
            'write.edit.copyAs${format == CopyFormat.markdown
                ? 'Markdown'
                : format == CopyFormat.html
                ? 'Html'
                : 'PlainText'}',
        title: title,
        requiredRole: Role.viewer,
        isUndoable: false,
        enabled: (t, _) => t.clipboard.canCopy,
        run: (t, _) async => _result(await t.clipboard.copyAs(format)),
      ),
    EditorCommandSpec(
      id: 'write.edit.selectAll',
      title: 'Select all',
      requiredRole: Role.viewer,
      isUndoable: false,
      bindings: const [KeyBinding('A', mod: _mod)],
      run: (t, _) {
        t.commands.selectAll();
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.edit.delete',
      title: 'Delete',
      requiredRole: Role.commenter,
      enabled: (t, _) =>
          t.controller.selection?.isCollapsed == false && t.commands.canEdit,
      run: (t, _) => _result(t.commands.deleteSelection()),
    ),
    EditorCommandSpec(
      id: 'write.edit.insertText',
      title: 'Insert text',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {
          'text': JsonSchema.string(),
          'position': JsonSchema.integer(minimum: 0),
        },
        required: ['text'],
      ),
      run: (t, a) => _result(
        t.commands.insertText(
          a.requireString('text'),
          position: a.integer('position'),
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.edit.replaceRange',
      title: 'Replace text',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {
          'start': JsonSchema.integer(minimum: 0),
          'length': JsonSchema.integer(minimum: 0),
          'text': JsonSchema.string(),
        },
        required: ['start', 'length', 'text'],
      ),
      run: (t, a) => _result(
        t.commands.replaceRangeWithText(
          a.integer('start')!,
          a.integer('length')!,
          a.requireString('text'),
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.edit.selectRange',
      title: 'Select range',
      requiredRole: Role.viewer,
      isUndoable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'anchor': JsonSchema.integer(minimum: 0),
          'head': JsonSchema.integer(minimum: 0),
        },
        required: ['anchor', 'head'],
      ),
      run: (t, a) {
        t.commands.selectRange(a.integer('anchor')!, a.integer('head')!);
        return const CommandResult.ok();
      },
    ),

    // Format (§10, §12).
    format('write.format.bold', InlineFormat.bold, const [
      KeyBinding('B', mod: _mod),
    ]),
    format('write.format.italic', InlineFormat.italic, const [
      KeyBinding('I', mod: _mod),
    ]),
    format('write.format.strikethrough', InlineFormat.strikethrough, const [
      KeyBinding('X', mod: _mod, shift: true),
    ]),
    format('write.format.inlineCode', InlineFormat.code, const [
      KeyBinding('E', mod: _mod),
    ]),
    EditorCommandSpec(
      id: 'write.format.clearFormatting',
      title: 'Clear formatting',
      category: 'Format',
      requiredRole: Role.commenter,
      bindings: const [KeyBinding('Backslash', mod: _mod)],
      enabled: (t, _) => t.commands.canEdit,
      run: (t, _) => _result(t.commands.clearFormatting()),
    ),
    EditorCommandSpec(
      id: 'write.format.blockType',
      title: 'Paragraph style',
      category: 'Format',
      requiredRole: Role.commenter,
      argsSchema: JsonSchema.object(
        properties: {'type': JsonSchema.string(enumValues: kinds.toList())},
        required: const ['type'],
      ),
      enabled: (t, _) => t.commands.canChangeBlockType(),
      run: (t, a) {
        final kind = BlockKind.tryParse(a.string('type'));
        if (kind == null) {
          return const CommandResult.failed('Unknown block type');
        }
        return _result(t.commands.setBlockType(kind));
      },
    ),
    blockType(BlockKind.paragraph, const [
      KeyBinding('0', mod: _mod, alt: true),
    ]),
    for (var level = 1; level <= 6; level += 1)
      blockType(BlockKind.values[BlockKind.heading1.index + level - 1], [
        KeyBinding('$level', mod: _mod, alt: true),
      ]),
    blockType(BlockKind.quote, const [
      KeyBinding('Period', mod: _mod, shift: true),
    ]),
    blockType(BlockKind.codeBlock, const [
      KeyBinding('C', mod: _mod, alt: true),
    ]),
    EditorCommandSpec(
      id: 'write.format.markdownHint',
      title: 'Markdown formatting hint',
      requiredRole: Role.viewer,
      isUndoable: false,
      argsSchema: const JsonSchema.object(
        properties: {'feature': JsonSchema.string()},
      ),
      bindings: const [KeyBinding('U', mod: _mod)],
      run: (t, a) {
        t.controller.notify(
          EditorNotice(
            EditorNoticeKind.markdownHint,
            t.controller.strings().editorUnderlineHintTheme,
          ),
        );
        return const CommandResult.ok();
      },
    ),

    // Lists (§13).
    EditorCommandSpec(
      id: 'write.list.toggleBulleted',
      title: 'Bulleted list',
      requiredRole: Role.commenter,
      bindings: const [KeyBinding('8', mod: _mod, shift: true)],
      enabled: (t, _) => t.commands.canChangeBlockType(),
      checked: (t, _) => t.commands.selectedBlockKind == BlockKind.bulleted,
      run: (t, _) => _result(t.commands.toggleBulleted()),
    ),
    EditorCommandSpec(
      id: 'write.list.toggleNumbered',
      title: 'Numbered list',
      requiredRole: Role.commenter,
      bindings: const [KeyBinding('7', mod: _mod, shift: true)],
      enabled: (t, _) => t.commands.canChangeBlockType(),
      checked: (t, _) => t.commands.selectedBlockKind == BlockKind.numbered,
      run: (t, _) => _result(t.commands.toggleNumbered()),
    ),
    EditorCommandSpec(
      id: 'write.list.toggleChecklist',
      title: 'Checklist',
      requiredRole: Role.commenter,
      bindings: const [KeyBinding('9', mod: _mod, shift: true)],
      enabled: (t, _) => t.commands.canChangeBlockType(),
      checked: (t, _) => t.commands.selectedBlockKind == BlockKind.checklist,
      run: (t, _) => _result(t.commands.toggleChecklist()),
    ),
    EditorCommandSpec(
      id: 'write.list.indent',
      title: 'Increase indent',
      requiredRole: Role.commenter,
      enabled: (t, _) => t.commands.canIndent(),
      run: (t, _) => _result(t.commands.indent()),
    ),
    EditorCommandSpec(
      id: 'write.list.outdent',
      title: 'Decrease indent',
      requiredRole: Role.commenter,
      enabled: (t, _) => t.commands.canOutdent(),
      run: (t, _) => _result(t.commands.outdent()),
    ),
    EditorCommandSpec(
      id: 'write.list.toggleChecked',
      title: 'Check item',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string()},
      ),
      enabled: (t, a) =>
          t.commands.canToggleChecked(nodeId: a.string('nodeId')),
      run: (t, a) =>
          _result(t.commands.toggleChecked(nodeId: a.string('nodeId'))),
    ),

    // Links (§11).
    EditorCommandSpec(
      id: 'write.link.set',
      title: 'Insert link',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {
          'url': JsonSchema.string(),
          'text': JsonSchema.string(),
          'range': JsonSchema.object(
            properties: {
              'start': JsonSchema.integer(minimum: 0),
              'length': JsonSchema.integer(minimum: 0),
            },
          ),
        },
        required: ['url'],
      ),
      enabled: (t, _) => t.commands.canInsertLink(),
      run: (t, a) {
        final range = a.values['range'];
        try {
          return _result(
            t.commands.setLink(
              a.requireString('url'),
              text: a.string('text'),
              start: range is Map ? (range['start'] as num?)?.toInt() : null,
              length: range is Map ? (range['length'] as num?)?.toInt() : null,
            ),
          );
        } on EditorCommandError catch (e) {
          return CommandResult.failed(e.message);
        }
      },
    ),
    EditorCommandSpec(
      id: 'write.link.remove',
      title: 'Remove link',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {
          'range': JsonSchema.object(
            properties: {
              'start': JsonSchema.integer(minimum: 0),
              'length': JsonSchema.integer(minimum: 0),
            },
          ),
        },
      ),
      enabled: (t, _) => t.commands.canEdit && t.commands.linkAt() != null,
      run: (t, a) {
        final range = a.values['range'];
        return _result(
          t.commands.removeLink(
            start: range is Map ? (range['start'] as num?)?.toInt() : null,
            length: range is Map ? (range['length'] as num?)?.toInt() : null,
          ),
        );
      },
    ),

    // Insert (§16–19).
    EditorCommandSpec(
      id: 'write.insert.divider',
      title: 'Divider',
      requiredRole: Role.commenter,
      enabled: (t, _) => t.commands.canInsertBlock(),
      run: (t, _) => _result(t.commands.insertDivider()),
    ),
    EditorCommandSpec(
      id: 'write.insert.imageFromUrl',
      title: 'Image from URL',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {'url': JsonSchema.string(), 'alt': JsonSchema.string()},
        required: ['url'],
      ),
      enabled: (t, _) => t.commands.canInsertBlock(),
      run: (t, a) {
        final url = a.requireString('url');
        if (!url.startsWith('https://')) {
          return const CommandResult.failed('Images must use https:// URLs');
        }
        final ids = t.commands.insertImages([
          (src: url, alt: a.string('alt') ?? '', title: null),
        ]);
        return ids.isEmpty
            ? const CommandResult.failed('Not available here')
            : CommandResult.ok({'id': ids.single});
      },
    ),
    EditorCommandSpec(
      id: 'write.insert.table',
      title: 'Table',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'rows': JsonSchema.integer(minimum: 1, maximum: 2000),
          'cols': JsonSchema.integer(minimum: 1, maximum: 64),
        },
      ),
      enabled: (t, _) =>
          t.commands.canInsertBlock() && !t.commands.isSuggesting,
      run: (t, a) {
        final id = t.commands.insertTable(
          rows: a.integer('rows', 3)!,
          columns: a.integer('cols', 3)!,
        );
        return id == null
            ? const CommandResult.failed('Not available here')
            : CommandResult.ok({'id': id});
      },
    ),
    EditorCommandSpec(
      id: 'write.insert.mention',
      title: 'Mention',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {
          'userUuid': JsonSchema.string(),
          'displayName': JsonSchema.string(),
          'email': JsonSchema.string(),
        },
        required: ['userUuid', 'displayName', 'email'],
      ),
      run: (t, a) => _result(
        t.commands.insertMention(
          userUuid: a.requireString('userUuid'),
          displayName: a.requireString('displayName'),
          email: a.requireString('email'),
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.insert.specialCharacter',
      title: 'Special characters…',
      requiredRole: Role.commenter,
      // Without `char` the screen opens the dialog (Write 04 §20.2).
      argsSchema: const JsonSchema.object(
        properties: {'char': JsonSchema.string()},
      ),
      run: (t, a) => _result(
        t.commands.insertText(
          a.requireString('char'),
          label: t.controller.strings().undoInsertSpecialCharacter,
        ),
      ),
    ),

    // Blocks (§22).
    EditorCommandSpec(
      id: 'write.block.turnInto',
      title: 'Turn into',
      requiredRole: Role.commenter,
      argsSchema: JsonSchema.object(
        properties: {
          'type': JsonSchema.string(enumValues: kinds.toList()),
          'nodeId': const JsonSchema.string(),
        },
        required: const ['type'],
      ),
      run: (t, a) {
        final kind = BlockKind.tryParse(a.string('type'));
        if (kind == null) {
          return const CommandResult.failed('Unknown block type');
        }
        return _result(
          t.commands.setBlockType(
            kind,
            toggle: false,
            nodeId: a.string('nodeId'),
          ),
        );
      },
    ),
    EditorCommandSpec(
      id: 'write.block.duplicate',
      title: 'Duplicate',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string()},
      ),
      run: (t, a) =>
          _result(t.commands.duplicateBlock(nodeId: a.string('nodeId'))),
    ),
    EditorCommandSpec(
      id: 'write.block.delete',
      title: 'Delete block',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string()},
      ),
      run: (t, a) =>
          _result(t.commands.deleteBlock(nodeId: a.string('nodeId'))),
    ),
    EditorCommandSpec(
      id: 'write.block.moveUp',
      title: 'Move block up',
      suggestable: false,
      bindings: const [
        KeyBinding('ArrowUp', ctrl: true, shift: true, mac: true),
        KeyBinding('ArrowUp', alt: true, shift: true, mac: false),
      ],
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string()},
      ),
      enabled: (t, a) =>
          t.commands.canMoveBlock(up: true, nodeId: a.string('nodeId')),
      run: (t, a) =>
          _result(t.commands.moveBlock(up: true, nodeId: a.string('nodeId'))),
    ),
    EditorCommandSpec(
      id: 'write.block.moveDown',
      title: 'Move block down',
      suggestable: false,
      bindings: const [
        KeyBinding('ArrowDown', ctrl: true, shift: true, mac: true),
        KeyBinding('ArrowDown', alt: true, shift: true, mac: false),
      ],
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string()},
      ),
      enabled: (t, a) =>
          t.commands.canMoveBlock(up: false, nodeId: a.string('nodeId')),
      run: (t, a) =>
          _result(t.commands.moveBlock(up: false, nodeId: a.string('nodeId'))),
    ),
    EditorCommandSpec(
      id: 'write.block.move',
      title: 'Move blocks',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeIds': JsonSchema.array(JsonSchema.string()),
          'toIndex': JsonSchema.integer(minimum: 0),
        },
        required: ['nodeIds', 'toIndex'],
      ),
      run: (t, a) => _result(
        t.commands.moveBlocks(a.strings('nodeIds'), a.integer('toIndex')!),
      ),
    ),
    EditorCommandSpec(
      id: 'write.block.select',
      title: 'Select block',
      requiredRole: Role.viewer,
      isUndoable: false,
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string()},
      ),
      run: (t, a) =>
          _result(t.commands.selectBlock(nodeId: a.string('nodeId'))),
    ),

    // Code (§15).
    EditorCommandSpec(
      id: 'write.code.setLanguage',
      title: 'Set code language',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {
          'language': JsonSchema.string(),
          'nodeId': JsonSchema.string(),
        },
        required: ['language'],
      ),
      enabled: (t, a) => t.commands.canEditCode(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.setCodeLanguage(
          a.requireString('language'),
          nodeId: a.string('nodeId'),
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.code.exit',
      title: 'Exit code block',
      requiredRole: Role.commenter,
      enabled: (t, _) => t.commands.canEditCode(),
      run: (t, _) => _result(t.commands.exitCodeBlock()),
    ),
    EditorCommandSpec(
      id: 'write.code.indentLines',
      title: 'Indent code',
      requiredRole: Role.commenter,
      enabled: (t, _) => t.commands.canEditCode(),
      run: (t, _) => _result(t.commands.indentCodeLines()),
    ),
    EditorCommandSpec(
      id: 'write.code.outdentLines',
      title: 'Outdent code',
      requiredRole: Role.commenter,
      enabled: (t, _) => t.commands.canEditCode(),
      run: (t, _) => _result(t.commands.outdentCodeLines()),
    ),

    // Images (§17.4).
    EditorCommandSpec(
      id: 'write.image.setAlt',
      title: 'Alt text',
      requiredRole: Role.commenter,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'alt': JsonSchema.string(maxLength: 500),
          'title': JsonSchema.string(),
        },
        required: ['alt'],
      ),
      run: (t, a) => _result(
        t.commands.setImageAlt(
          a.requireString('alt'),
          title: a.string('title'),
          nodeId: a.string('nodeId'),
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.image.replaceFromUrl',
      title: 'Replace image',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string(), 'url': JsonSchema.string()},
        required: ['url'],
      ),
      run: (t, a) => _result(
        t.commands.replaceImage(
          a.requireString('url'),
          nodeId: a.string('nodeId'),
        ),
      ),
    ),

    // Tables (§18.4).
    EditorCommandSpec(
      id: 'write.table.insertRow',
      title: 'Insert row',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'index': JsonSchema.integer(minimum: 0),
          'position': JsonSchema.string(enumValues: ['above', 'below']),
        },
        required: ['index'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.insertRow(
            a.integer('index')! + (a.string('position') == 'above' ? 0 : 1),
          ),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoInsertRow,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.insertColumn',
      title: 'Insert column',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'index': JsonSchema.integer(minimum: 0),
          'position': JsonSchema.string(enumValues: ['left', 'right']),
        },
        required: ['index'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.insertColumn(
            a.integer('index')! + (a.string('position') == 'left' ? 0 : 1),
          ),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoInsertColumn,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.deleteRow',
      title: 'Delete row',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'index': JsonSchema.integer(minimum: 1),
        },
        required: ['index'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.deleteRow(a.integer('index')!),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoDeleteRow,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.deleteColumn',
      title: 'Delete column',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'index': JsonSchema.integer(minimum: 0),
        },
        required: ['index'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.deleteColumn(a.integer('index')!),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoDeleteColumn,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.moveRow',
      title: 'Move row',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'from': JsonSchema.integer(minimum: 1),
          'to': JsonSchema.integer(minimum: 1),
        },
        required: ['from', 'to'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.moveRow(a.integer('from')!, a.integer('to')!),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoMoveRow,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.moveColumn',
      title: 'Move column',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'from': JsonSchema.integer(minimum: 0),
          'to': JsonSchema.integer(minimum: 0),
        },
        required: ['from', 'to'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.moveColumn(a.integer('from')!, a.integer('to')!),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoMoveColumn,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.setColumnAlignment',
      title: 'Column alignment',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'index': JsonSchema.integer(minimum: 0),
          'align': JsonSchema.string(
            enumValues: ['none', 'left', 'center', 'right'],
          ),
        },
        required: ['index', 'align'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.setColumnAlignment(
            a.integer('index')!,
            TableAlign.parse(a.string('align')),
          ),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoColumnAlignment,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.setCell',
      title: 'Edit cell',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'nodeId': JsonSchema.string(),
          'row': JsonSchema.integer(minimum: 0),
          'col': JsonSchema.integer(minimum: 0),
          'markdown': JsonSchema.string(),
        },
        required: ['row', 'col', 'markdown'],
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) => _result(
        t.commands.editTable(
          (table) => table.setCell(
            a.integer('row')!,
            a.integer('col')!,
            a.requireString('markdown'),
          ),
          nodeId: a.string('nodeId'),
          label: t.controller.strings().undoEditTable,
        ),
      ),
    ),
    EditorCommandSpec(
      id: 'write.table.delete',
      title: 'Delete table',
      suggestable: false,
      argsSchema: const JsonSchema.object(
        properties: {'nodeId': JsonSchema.string()},
      ),
      enabled: (t, a) => t.commands.canEditTable(nodeId: a.string('nodeId')),
      run: (t, a) =>
          _result(t.commands.deleteBlock(nodeId: a.string('nodeId'))),
    ),

    // View (§29, not undoable).
    EditorCommandSpec(
      id: 'write.view.zoomIn',
      title: 'Zoom in',
      requiredRole: Role.viewer,
      isUndoable: false,
      bindings: const [KeyBinding('Equal', mod: _mod, alt: true)],
      run: (t, _) {
        t.controller.view.zoomIn();
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.view.zoomOut',
      title: 'Zoom out',
      requiredRole: Role.viewer,
      isUndoable: false,
      bindings: const [KeyBinding('Minus', mod: _mod, alt: true)],
      run: (t, _) {
        t.controller.view.zoomOut();
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.view.zoomReset',
      title: 'Zoom to 100 %',
      requiredRole: Role.viewer,
      isUndoable: false,
      run: (t, _) {
        t.controller.view.zoomReset();
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.view.zoomSet',
      title: 'Zoom',
      requiredRole: Role.viewer,
      isUndoable: false,
      argsSchema: const JsonSchema.object(
        properties: {'percent': JsonSchema.integer(minimum: 50, maximum: 200)},
        required: ['percent'],
      ),
      run: (t, a) {
        t.controller.view.zoom = a.integer('percent')! / 100;
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.view.suggestionPreview',
      title: 'Preview suggestions',
      requiredRole: Role.viewer,
      isUndoable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'mode': JsonSchema.string(
            enumValues: ['show', 'accepted', 'original'],
          ),
        },
        required: ['mode'],
      ),
      run: (t, a) {
        t.controller.view.suggestionPreview = SuggestionPreviewMode.values
            .where((m) => m.name == a.string('mode'))
            .firstOrNull;
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.mode.set',
      title: 'Editing mode',
      requiredRole: Role.viewer,
      isUndoable: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'mode': JsonSchema.string(
            enumValues: ['editing', 'suggesting', 'viewing'],
          ),
        },
        required: ['mode'],
      ),
      run: (t, a) {
        final mode = EditorMode.values
            .where((m) => m.name == a.string('mode'))
            .firstOrNull;
        if (mode == null) return const CommandResult.failed('Unknown mode');
        t.controller.mode = mode;
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.nav.documentStart',
      title: 'Go to document start',
      requiredRole: Role.viewer,
      isUndoable: false,
      run: (t, _) {
        t.controller.select(const DeltaSelection.collapsed(0));
        return const CommandResult.ok();
      },
    ),
    EditorCommandSpec(
      id: 'write.nav.documentEnd',
      title: 'Go to document end',
      requiredRole: Role.viewer,
      isUndoable: false,
      run: (t, _) {
        t.controller.select(DeltaSelection.collapsed(t.controller.length - 1));
        return const CommandResult.ok();
      },
    ),
  ];
}
