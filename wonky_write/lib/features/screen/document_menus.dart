import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../editor/commands/write_editor_commands.dart';
import '../editor/controller/editor_types.dart';
import '../../commands/extras_commands.dart' show spellingMenuEntries;
import '../editor/model/code_languages.dart';
import 'wonky_menus.dart';
import 'write_document_controller.dart';
import 'write_toolbar.dart';

/// "Turn into" entries (paragraph styles + lists).
List<WonkyMenuEntry> turnIntoEntries(CommandUi ui, BlockKind? current) => [
  ...paragraphStyleEntries(ui, current),
  const WonkyMenuSeparator(),
  for (final kind in const [
    BlockKind.bulleted,
    BlockKind.numbered,
    BlockKind.checklist,
  ])
    WonkyMenuRadioItem(
      key: ValueKey<String>('menu.turnInto.${kind.name}'),
      label: blockKindLabel(ui.l, kind),
      selected: current == kind,
      enabled: ui.state('write.format.blockType', {'type': kind.name}).enabled,
      onSelected: () => ui.run('write.format.blockType', {'type': kind.name}),
    ),
];

/// The canvas context menu for the current selection (Write 05 §6).
List<WonkyMenuEntry> contextMenuEntries(
  CommandUi ui,
  WriteDocumentController doc,
) {
  final viewing = doc.editor.mode == EditorMode.viewing;
  final sel = doc.editor.selection;
  final hasSelection = sel != null && !sel.isCollapsed;
  final link = doc.commands.linkAt();
  final kind = doc.commands.selectedBlockKind;
  final selected = doc.selectedText;
  final l = ui.l;
  final out = <WonkyMenuEntry>[
    // Suggestions for a misspelled word at the caret (Write 04 §28.2).
    ...spellingMenuEntries(doc, (id, args) => ui.run(id, args)),
  ];

  WonkyMenuEntry copyAs() => WonkyMenuSubmenu(
    label: l.menuCopyAs,
    icon: LucideIcons.clipboardCopy,
    children: [
      ui.item('write.edit.copyAsMarkdown', label: l.menuCopyAsMarkdown),
      ui.item('write.edit.copyAsPlainText', label: l.menuCopyAsPlainText),
      ui.item('write.edit.copyAsHtml', label: l.menuCopyAsHtml),
    ],
  );

  WonkyMenuEntry search() => ui.item(
    'write.find.open',
    args: {'query': ?selected},
    label: selected == null
        ? l.docMenuSearchDocument
        : l.docMenuSearchDocumentFor(
            selected.length > 24 ? '${selected.substring(0, 24)}…' : selected,
          ),
    icon: LucideIcons.search,
    keyName: 'context.search',
  );

  if (link != null) {
    out.addAll([
      ui.item('write.link.open', icon: LucideIcons.externalLink),
      ui.item('write.link.copy', icon: LucideIcons.copy),
      if (!viewing) ...[
        ui.item('write.link.edit', icon: LucideIcons.pencil),
        ui.item('write.link.remove'),
      ],
      const WonkyMenuSeparator(),
    ]);
  }

  if (viewing) {
    return [
      ...out,
      ui.item('write.edit.copy'),
      copyAs(),
      ui.item('shell.comments.create', label: l.menuComment),
      const WonkyMenuSeparator(),
      search(),
    ];
  }

  // Wonky Markdown grids and containers (Write 11 §7.5).
  if (doc.isWonky) {
    final grid = doc.commands.gridOf();
    if (grid != null) {
      return [
        ...out,
        ...gridEntries(ui, grid.id),
        const WonkyMenuSeparator(),
        ui.item('shell.comments.create', label: l.menuComment),
        ui.item('write.edit.cut'),
        ui.item('write.edit.copy'),
        const WonkyMenuSeparator(),
        ui.item('write.block.moveUp', label: l.docMenuMoveUp),
        ui.item('write.block.moveDown', label: l.docMenuMoveDown),
      ];
    }
    final video = doc.commands.youtubeOf();
    if (video != null) {
      return [
        ...out,
        ...youtubeEntries(ui, video.id),
        const WonkyMenuSeparator(),
        ui.item('shell.comments.create', label: l.menuComment),
        ui.item('write.edit.cut'),
        ui.item('write.edit.copy'),
        const WonkyMenuSeparator(),
        ui.item('write.block.moveUp', label: l.docMenuMoveUp),
        ui.item('write.block.moveDown', label: l.docMenuMoveDown),
      ];
    }
    if (doc.commands.containerAt() != null) {
      out.addAll([
        WonkyMenuSubmenu(
          label: l.menuContainer,
          icon: LucideIcons.panelTop,
          children: containerEntries(ui, doc),
        ),
        const WonkyMenuSeparator(),
      ]);
    }
  }

  if (doc.onImage) {
    return [
      ...out,
      ui.item('write.image.preview', icon: LucideIcons.maximize),
      ui.item('write.image.editAlt'),
      ui.item('write.image.replace'),
      ui.item('write.image.download', icon: LucideIcons.download),
      const WonkyMenuSeparator(),
      ui.item('shell.comments.create', label: l.menuComment),
      ui.item('write.edit.cut'),
      ui.item('write.edit.copy'),
      ui.item('write.block.delete', label: l.docMenuDeleteImage),
      const WonkyMenuSeparator(),
      ui.item('write.block.moveUp', label: l.docMenuMoveUp),
      ui.item('write.block.moveDown', label: l.docMenuMoveDown),
    ];
  }

  if (doc.inTable) {
    return [
      ...out,
      ui.item('write.table.editCell', label: l.menuEditCells),
      ui.item('write.table.edit'),
      const WonkyMenuSeparator(),
      ui.item('write.edit.copyAsMarkdown', label: l.docMenuCopyMarkdown),
      ui.item('write.table.copyAsTsv'),
      ui.item('shell.comments.create', label: l.menuComment),
      const WonkyMenuSeparator(),
      ui.item('write.block.moveUp', label: l.docMenuMoveUp),
      ui.item('write.block.moveDown', label: l.docMenuMoveDown),
      ui.item('write.table.delete'),
    ];
  }

  if (doc.inCode) {
    out.addAll([
      WonkyMenuSubmenu(
        label: l.docMenuLanguage,
        icon: LucideIcons.code,
        children: codeLanguageEntries(ui, doc),
      ),
      ui.item('write.code.copy'),
      ui.item('write.code.exit', label: l.cmdCodeExit),
      const WonkyMenuSeparator(),
    ]);
  }

  if (hasSelection) {
    return [
      ...out,
      ui.item('write.edit.cut'),
      ui.item('write.edit.copy'),
      copyAs(),
      ui.item('write.edit.paste'),
      ui.item('write.edit.pasteWithoutFormatting'),
      const WonkyMenuSeparator(),
      ui.item('shell.comments.create', label: l.menuComment),
      ui.item(
        'write.link.insert',
        label: link == null ? l.cmdLinkInsert : l.toolbarEditLink,
      ),
      const WonkyMenuSeparator(),
      ui.item('write.format.bold'),
      ui.item('write.format.italic'),
      ui.item('write.format.strikethrough'),
      ui.item('write.format.inlineCode'),
      ui.item('write.format.clearFormatting'),
      WonkyMenuSubmenu(
        label: l.docMenuTurnInto,
        icon: LucideIcons.pilcrow,
        children: turnIntoEntries(ui, kind),
      ),
      const WonkyMenuSeparator(),
      search(),
    ];
  }

  return [
    ...out,
    ui.item('write.edit.paste'),
    ui.item('write.edit.pasteWithoutFormatting'),
    const WonkyMenuSeparator(),
    ui.item('write.link.insert'),
    ui.item('shell.comments.create', label: l.menuComment),
    const WonkyMenuSeparator(),
    WonkyMenuSubmenu(
      label: l.docMenuTurnInto,
      icon: LucideIcons.pilcrow,
      children: turnIntoEntries(ui, kind),
    ),
    WonkyMenuSubmenu(
      label: l.menuInsert,
      icon: LucideIcons.plus,
      children: [
        ui.item('write.insert.image', label: l.menuImage),
        ui.item('write.insert.imageFromUrl', label: l.docMenuImageByUrl),
        ui.item(
          'write.insert.table',
          args: {'rows': 3, 'cols': 3},
          label: l.menuTable,
          keyName: 'context.insertTable',
        ),
        ui.item('write.insert.divider'),
        ui.item(
          'write.format.blockType',
          args: {'type': 'codeBlock'},
          label: l.cmdFormatBlockTypeCodeBlock,
          keyName: 'context.codeBlock',
        ),
      ],
    ),
    const WonkyMenuSeparator(),
    ui.item('write.edit.selectAll'),
  ];
}

/// Code language entries (Write 05 §9.4).
List<WonkyMenuEntry> codeLanguageEntries(
  CommandUi ui,
  WriteDocumentController doc, {
  String? nodeId,
}) {
  final current = doc.block(nodeId)?.blockAttributes?['code-block'];
  final names = [
    for (final id in CodeLanguages.grammars.keys)
      MapEntry(id, CodeLanguages.displayName(id)),
  ]..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
  return [
    WonkyMenuRadioItem(
      key: const ValueKey<String>('menu.code.plain'),
      label: ui.l.docMenuPlainText,
      selected: current == null || current == '' || current == true,
      onSelected: () =>
          ui.run('write.code.setLanguage', {'language': '', 'nodeId': ?nodeId}),
    ),
    const WonkyMenuSeparator(),
    for (final e in names)
      WonkyMenuRadioItem(
        key: ValueKey<String>('menu.code.${e.key}'),
        label: e.value,
        selected: current == e.key,
        onSelected: () => ui.run('write.code.setLanguage', {
          'language': e.key,
          'nodeId': ?nodeId,
        }),
      ),
  ];
}
