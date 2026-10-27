import 'dart:async';

import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../features/editor/commands/editor_command_catalog.dart';
import '../features/editor/controller/editor_types.dart';
import '../features/screen/write_document_controller.dart';
import 'command_icons.dart';
import 'write_command.dart';

/// Wraps every editor command of the Write 04 §40 catalog
/// (`editorCommandCatalog()`) as a shell command, adding role/mode rules,
/// icons, categories and screen behaviour for a few ids ([overrides]).
List<Command<CommandArgs>> editorCommands(
  ShellServices s, {
  Map<String, WriteRun Function(EditorCommandSpec spec)> overrides = const {},
}) => [
  for (final spec in editorCommandCatalog())
    _wrap(spec, overrides[spec.id]?.call(spec)),
];

String _categoryOf(WriteLocalizations l, String id) {
  final area = id.split('.')[1];
  return switch (area) {
    'edit' => l.categoryEdit,
    'format' => l.categoryFormat,
    'list' => l.categoryFormat,
    'link' => l.categoryInsert,
    'insert' => l.categoryInsert,
    'block' => l.categoryBlocks,
    'code' => l.categoryCodeBlocks,
    'image' => l.categoryImages,
    'table' => l.categoryTables,
    'view' => l.categoryView,
    'mode' => l.categoryView,
    'nav' => l.categoryNavigation,
    _ => l.categoryWrite,
  };
}

/// Localized title of a catalog command (the catalog's English titles are
/// the fallback for ids added later).
String? editorCommandTitle(WriteLocalizations l, String id) => switch (id) {
  'write.edit.copy' => l.cmdEditCopy,
  'write.edit.cut' => l.cmdEditCut,
  'write.edit.paste' => l.cmdEditPaste,
  'write.edit.pasteWithoutFormatting' => l.cmdEditPasteWithoutFormatting,
  'write.edit.pasteAsMarkdown' => l.cmdEditPasteAsMarkdown,
  'write.edit.copyAsMarkdown' => l.cmdEditCopyAsMarkdown,
  'write.edit.copyAsPlainText' => l.cmdEditCopyAsPlainText,
  'write.edit.copyAsHtml' => l.cmdEditCopyAsHtml,
  'write.edit.selectAll' => l.cmdEditSelectAll,
  'write.edit.delete' => l.cmdEditDelete,
  'write.edit.insertText' => l.cmdEditInsertText,
  'write.edit.replaceRange' => l.cmdEditReplaceRange,
  'write.edit.selectRange' => l.cmdEditSelectRange,
  'write.format.bold' => l.cmdFormatBold,
  'write.format.italic' => l.cmdFormatItalic,
  'write.format.strikethrough' => l.cmdFormatStrikethrough,
  'write.format.inlineCode' => l.cmdFormatInlineCode,
  'write.format.clearFormatting' => l.cmdFormatClearFormatting,
  'write.format.blockType' => l.cmdFormatBlockType,
  'write.format.blockType.paragraph' => l.cmdFormatBlockTypeParagraph,
  'write.format.blockType.heading1' => l.cmdFormatBlockTypeHeading1,
  'write.format.blockType.heading2' => l.cmdFormatBlockTypeHeading2,
  'write.format.blockType.heading3' => l.cmdFormatBlockTypeHeading3,
  'write.format.blockType.heading4' => l.cmdFormatBlockTypeHeading4,
  'write.format.blockType.heading5' => l.cmdFormatBlockTypeHeading5,
  'write.format.blockType.heading6' => l.cmdFormatBlockTypeHeading6,
  'write.format.blockType.quote' => l.cmdFormatBlockTypeQuote,
  'write.format.blockType.codeBlock' => l.cmdFormatBlockTypeCodeBlock,
  'write.format.markdownHint' => l.cmdFormatMarkdownHint,
  'write.list.toggleBulleted' => l.cmdListToggleBulleted,
  'write.list.toggleNumbered' => l.cmdListToggleNumbered,
  'write.list.toggleChecklist' => l.cmdListToggleChecklist,
  'write.list.indent' => l.cmdListIndent,
  'write.list.outdent' => l.cmdListOutdent,
  'write.list.toggleChecked' => l.cmdListToggleChecked,
  'write.link.set' => l.cmdLinkSet,
  'write.link.remove' => l.cmdLinkRemove,
  'write.insert.divider' => l.cmdInsertDivider,
  'write.insert.imageFromUrl' => l.cmdInsertImageFromUrl,
  'write.insert.table' => l.cmdInsertTable,
  'write.insert.mention' => l.cmdInsertMention,
  'write.insert.specialCharacter' => l.cmdInsertSpecialCharacter,
  'write.block.turnInto' => l.cmdBlockTurnInto,
  'write.block.duplicate' => l.cmdBlockDuplicate,
  'write.block.delete' => l.cmdBlockDelete,
  'write.block.moveUp' => l.cmdBlockMoveUp,
  'write.block.moveDown' => l.cmdBlockMoveDown,
  'write.block.move' => l.cmdBlockMove,
  'write.block.select' => l.cmdBlockSelect,
  'write.code.setLanguage' => l.cmdCodeSetLanguage,
  'write.code.exit' => l.cmdCodeExit,
  'write.code.indentLines' => l.cmdCodeIndentLines,
  'write.code.outdentLines' => l.cmdCodeOutdentLines,
  'write.image.setAlt' => l.cmdImageSetAlt,
  'write.image.replaceFromUrl' => l.cmdImageReplaceFromUrl,
  'write.table.insertRow' => l.cmdTableInsertRow,
  'write.table.insertColumn' => l.cmdTableInsertColumn,
  'write.table.deleteRow' => l.cmdTableDeleteRow,
  'write.table.deleteColumn' => l.cmdTableDeleteColumn,
  'write.table.moveRow' => l.cmdTableMoveRow,
  'write.table.moveColumn' => l.cmdTableMoveColumn,
  'write.table.setColumnAlignment' => l.cmdTableSetColumnAlignment,
  'write.table.setCell' => l.cmdTableSetCell,
  'write.table.delete' => l.cmdTableDelete,
  'write.view.zoomIn' => l.cmdViewZoomIn,
  'write.view.zoomOut' => l.cmdViewZoomOut,
  'write.view.zoomReset' => l.cmdViewZoomReset,
  'write.view.zoomSet' => l.cmdViewZoomSet,
  'write.view.suggestionPreview' => l.cmdViewSuggestionPreview,
  'write.mode.set' => l.cmdModeSet,
  'write.nav.documentStart' => l.cmdNavDocumentStart,
  'write.nav.documentEnd' => l.cmdNavDocumentEnd,
  'write.insert.callout' => l.cmdInsertCallout,
  'write.insert.details' => l.cmdInsertDetails,
  'write.insert.card' => l.cmdInsertCard,
  'write.insert.grid' => l.cmdInsertGrid,
  'write.insert.youtube' => l.cmdInsertYouTube,
  'write.youtube.edit' => l.cmdYouTubeEdit,
  'write.youtube.delete' => l.cmdYouTubeDelete,
  'write.box.setVariant' => l.cmdBoxSetVariant,
  'write.box.editTitle' => l.cmdBoxEditTitle,
  'write.box.convert' => l.cmdBoxConvert,
  'write.box.unwrap' => l.cmdBoxUnwrap,
  'write.details.toggleCollapsed' => l.cmdDetailsToggleCollapsed,
  'write.box.delete' => l.cmdBoxDelete,
  'write.grid.setColumns' => l.cmdGridSetColumns,
  'write.grid.setBullets' => l.cmdGridSetBullets,
  'write.grid.addItem' => l.cmdGridAddItem,
  'write.grid.removeItem' => l.cmdGridRemoveItem,
  'write.grid.delete' => l.menuDeleteGrid,
  'write.link.setStyle' => l.cmdLinkSetStyle,
  'write.format.chip' => l.cmdFormatChip,
  'write.heading.toggleStep' => l.cmdHeadingToggleStep,
  'write.heading.setStepNumber' => l.cmdHeadingSetStepNumber,
  'write.heading.renumberSteps' => l.cmdHeadingRenumberSteps,
  _ => null,
};

KeyScope _scopeOf(String id) =>
    id.startsWith('write.view.') || id.startsWith('write.mode.')
    ? KeyScope.global
    : KeyScope.editor;

WriteCommand _wrap(EditorCommandSpec spec, WriteRun? override) {
  final content = spec.isUndoable && spec.requiredRole >= Role.commenter;
  bool roleAllows(WriteDocumentController d) {
    if (!content) return true;
    if (d.role >= Role.editor) return true;
    // Commenters run content commands only as suggestions (`C*`).
    return d.role >= Role.commenter &&
        spec.suggestable &&
        d.editor.mode == EditorMode.suggesting;
  }

  return WriteCommand(
    spec.id,
    label: (l) => editorCommandTitle(l, spec.id) ?? spec.title,
    icon: commandIcons[spec.id],
    categoryName: (l) => _categoryOf(l, spec.id),
    defaultBindings: spec.bindings,
    keyScope: _scopeOf(spec.id),
    requiredRole: spec.requiredRole,
    isUndoable: spec.isUndoable,
    argsSchema: spec.argsSchema,
    needsEditable: content,
    wonkyOnly: spec.wonkyOnly,
    enabled: (d, a) => roleAllows(d) && spec.isEnabled(d.target, a),
    checked: spec.checked == null ? null : (d, a) => spec.checked!(d.target, a),
    reason: (l, d, a) {
      if (!roleAllows(d)) {
        return spec.suggestable
            ? l.reasonSwitchToSuggesting
            : l.reasonNeedEditAccess;
      }
      if (!spec.suggestable && d.editor.mode == EditorMode.suggesting) {
        return l.reasonCannotSuggest;
      }
      return null;
    },
    run: (ctx, d, a) async {
      if (spec.radio && spec.checked?.call(d.target, a) == true) {
        return const CommandResult.ok();
      }
      if (override != null) return override(ctx, d, a);
      return spec.run(d.target, a);
    },
  );
}

/// Convenience to run the catalog implementation from an override.
FutureOr<CommandResult> runSpec(
  EditorCommandSpec spec,
  WriteDocumentController doc,
  JsonArgs args,
) => spec.run(doc.target, args);
