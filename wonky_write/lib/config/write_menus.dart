import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show BuiltinThemes;

import '../l10n/write_l10n.dart';

/// Menu ids of the Write menus (stable: used by MCP `ui.get_menu_tree`).
abstract final class WriteMenuIds {
  static const insert = 'insert';
  static const format = 'format';
  static const tablePicker = 'insert.table.picker';
}

MenuCommand _c(
  String id, {
  String? label,
  Map<String, Object?> args = const {},
  String? menuId,
  bool radio = false,
}) => MenuSpec.command(id, label: label, args: args, id: menuId, radio: radio);

/// The Write menubar (Write 05 §7): the shell's shared menus extended with
/// Write items, plus the Insert and Format menus. Labels come from [l10n]
/// (default: the Write strings in the locale of the shell's strings).
MenuRoot writeMenus(ShellMenus shell, {WriteLocalizations? l10n}) {
  final l = l10n ?? writeL10nFor(shell.l10n);
  var root = shell.root;

  // ---- File (§7.1) ----
  root = root
      .insertAfter('shell.file.import', [
        _c('write.insert.fromFile', label: l.cmdInsertFromFile),
      ])
      // (M14) A story for a publication (specs/18 §4.4); disabled for
      // documents without a submission.
      .insertAfter(ShellMenuIds.fileShare, [
        _c('write.submission.submit', label: l.cmdSubmissionSubmit),
        _c('write.submission.showStatus', label: l.cmdSubmissionStatus),
        _c('write.submission.withdraw', label: l.cmdSubmissionWithdraw),
      ])
      .replace('shell.file.details', [
        _c('write.doc.properties', label: l.cmdDocProperties),
      ])
      .insertAfter(ShellMenuIds.fileEndOfVersions, [
        _c('write.doc.languageDialog', label: l.cmdDocLanguageDialog),
        _c('write.doc.pageSetup', label: l.cmdDocPageSetup),
        // Write 11 §3.1.
        MenuSpec.submenu('file.markdownFlavor', l.menuMarkdownFlavor, [
          _c(
            'write.doc.setMarkdownFlavor',
            label: l.menuMarkdownGfm,
            args: {'flavor': 'gfm'},
            menuId: 'file.markdownFlavor.gfm',
            radio: true,
          ),
          _c(
            'write.doc.setMarkdownFlavor',
            label: l.menuMarkdownWonky,
            args: {'flavor': 'wonky'},
            menuId: 'file.markdownFlavor.wonky',
            radio: true,
          ),
        ]),
        MenuSpec.separator(),
      ]);

  // ---- Edit (§7.2) ----
  root = root
      .insertAfter('shell.edit.pasteWithoutFormatting', [
        MenuSpec.submenu('edit.copyAs', l.menuCopyAs, [
          _c('write.edit.copyAsMarkdown', label: l.menuCopyAsMarkdown),
          _c('write.edit.copyAsPlainText', label: l.menuCopyAsPlainText),
          _c('write.edit.copyAsHtml', label: l.menuCopyAsHtml),
        ]),
        _c('write.edit.pasteAsMarkdown', label: l.cmdEditPasteAsMarkdown),
      ])
      .insertAfter('shell.edit.selectAll', [_c('write.edit.delete')])
      .appendTo(ShellMenuIds.edit, [
        MenuSpec.separator(),
        _c('write.find.open', label: l.cmdFindOpen),
        _c('write.find.openReplace', label: l.cmdFindOpenReplace),
        _c('write.find.next'),
        _c('write.find.previous'),
        _c('write.nav.goToHeading'),
      ]);

  // ---- View (§7.3) ----
  root = root
      .appendTo(ShellMenuIds.viewMode, [
        _c('write.mode.editing', label: l.screenModeEditing, radio: true),
        _c('write.mode.suggesting', label: l.screenModeSuggesting, radio: true),
        _c('write.mode.viewing', label: l.screenModeViewing, radio: true),
      ])
      .insertAfter(ShellMenuIds.viewMode, [
        MenuSpec.submenu('view.layout', l.menuPageLayout, [
          _c(
            'write.doc.setLayout',
            label: l.menuLayoutPages,
            args: {'layout': 'pages'},
            menuId: 'view.layout.pages',
            radio: true,
          ),
          _c(
            'write.doc.setLayout',
            label: l.menuLayoutPageless,
            args: {'layout': 'pageless'},
            menuId: 'view.layout.pageless',
            radio: true,
          ),
        ]),
        MenuSpec.submenu('view.suggestions', l.menuSuggestions, [
          _c(
            'write.view.suggestionPreview',
            label: l.menuShowSuggestions,
            args: {'mode': 'show'},
            menuId: 'view.suggestions.show',
          ),
          _c(
            'write.view.suggestionPreview',
            label: l.menuPreviewAccepted,
            args: {'mode': 'accepted'},
            menuId: 'view.suggestions.accepted',
          ),
          _c(
            'write.view.suggestionPreview',
            label: l.menuPreviewOriginal,
            args: {'mode': 'original'},
            menuId: 'view.suggestions.original',
          ),
        ]),
      ])
      .replace(ShellMenuIds.viewZoom, [
        MenuSpec.submenu(ShellMenuIds.viewZoom, l.menuZoom, [
          _c('write.view.zoomIn'),
          _c('write.view.zoomOut'),
          MenuSpec.separator(),
          for (final p in const [50, 75, 90, 100, 125, 150, 200])
            _c(
              'shell.view.zoom',
              label: l.screenZoomPercent(p),
              args: {'percent': p},
              menuId: 'view.zoom.$p',
              radio: true,
            ),
          MenuSpec.separator(),
          _c(
            'write.view.zoomFit',
            label: l.menuFitWidth,
            args: {'mode': 'width'},
            menuId: 'view.zoom.fitWidth',
          ),
          _c(
            'write.view.zoomFit',
            label: l.menuFitPage,
            args: {'mode': 'page'},
            menuId: 'view.zoom.fitPage',
          ),
          _c('write.view.zoomReset', label: l.menuZoomReset),
        ]),
      ])
      // The side panel shows Outline, Find, History or the Assistant;
      // comments and suggestions live in the margin (Write 05 §10).
      .replace('shell.comments.togglePanel', [
        _c('write.view.toggleOutline', label: l.cmdViewToggleOutline),
        _c(
          'write.find.open',
          label: l.cmdFindOpenReplace,
          menuId: 'view.panels.find',
        ),
      ])
      .insertAfter(ShellMenuIds.viewPanels, [
        _c(
          'shell.comments.togglePanel',
          label: l.menuShowComments,
          menuId: 'view.comments',
        ),
      ]);

  // ---- Insert (§7.4) and Format (§7.5) ----
  root = root.insertMenusBefore(ShellMenuIds.tools, [
    insertMenu(l),
    formatMenu(l),
  ]);

  // ---- Tools (§7.6) ----
  root = root
      .insertAfter('tools.assistant', [
        _c('write.ai.summarizeDocument', menuId: 'tools.ai.summarize'),
        _c('write.ai.generateOutline', menuId: 'tools.ai.outline'),
        _c('write.ai.proofreadDocument', menuId: 'tools.ai.proofread'),
      ])
      .insertBefore('tools.assistant', [
        _c('write.tools.wordCount', label: l.cmdToolsWordCount),
        _c(
          'write.doc.languageDialog',
          label: l.cmdDocLanguageDialog,
          menuId: 'tools.language',
        ),
        MenuSpec.submenu('tools.spelling', l.menuSpelling, [
          _c('write.spell.check', label: l.cmdSpellCheck),
          _c('write.spell.nextError', label: l.menuNextError),
          MenuSpec.separator(),
          _c('write.spell.toggle', label: l.menuUnderlineErrors),
          _c(
            'write.spell.toggleIgnoreUppercase',
            label: l.cmdSpellToggleIgnoreUppercase,
          ),
          MenuSpec.separator(),
          _c(
            'write.spell.personalDictionary',
            label: l.cmdSpellPersonalDictionary,
          ),
          _c(
            'write.doc.languageDialog',
            label: l.cmdDocLanguageDialog,
            menuId: 'tools.spelling.language',
          ),
        ]),
        MenuSpec.separator(),
      ])
      .insertBefore('tools.preferences', [
        MenuSpec.submenu('tools.writePrefs', l.menuPreferences, [
          _c('write.prefs.setMarkdownShortcuts'),
          _c('write.prefs.setSmartTypography'),
          _c('write.prefs.setAutoPair'),
          _c('write.prefs.setAutolink'),
          _c('write.prefs.setCopyAsMarkdown'),
          _c('write.prefs.setSelectionToolbar'),
          MenuSpec.separator(),
          // (v2, suite 04 §4) Write settings and Wonky Work settings.
          _c('shell.settings.openApp', menuId: 'tools.writePrefs.all'),
          _c(
            'shell.settings.open',
            args: {'section': 'account'},
            menuId: 'tools.writePrefs.work',
          ),
        ]),
      ])
      .remove(ShellMenuIds.toolsAppSettings)
      .remove(ShellMenuIds.toolsWorkSettings);

  // ---- Help (§7.7) ----
  root = root.insertAfter('shell.help.shortcuts', [
    _c('write.help.markdownGuide'),
  ]);
  return root;
}

/// Insert (Write 05 §7.4).
MenuSubmenu insertMenu(
  WriteLocalizations l,
) => MenuSpec.submenu(WriteMenuIds.insert, l.menuInsert, [
  MenuSpec.submenu('insert.image', l.menuImage, [
    _c('write.insert.image', label: l.menuImageUpload),
    _c('write.insert.imageFromUrl', label: l.menuImageByUrl),
  ]),
  MenuSpec.submenu('insert.table', l.menuTable, [
    MenuSpec.custom(WriteMenuIds.tablePicker, label: l.menuTableSize),
    MenuSpec.separator(),
    _c('write.insert.tableDialog', label: l.menuTableCustomSize),
  ]),
  _c('write.insert.divider', label: l.menuDividerLine),
  _c(
    'write.format.blockType.codeBlock',
    label: l.cmdFormatBlockTypeCodeBlock,
    menuId: 'insert.codeBlock',
  ),
  _c(
    'write.format.blockType.quote',
    label: l.cmdFormatBlockTypeQuote,
    menuId: 'insert.quote',
  ),
  _c(
    'write.list.toggleChecklist',
    label: l.cmdListToggleChecklist,
    menuId: 'insert.checklist',
  ),
  // Wonky Markdown (Write 11 §7.5): hidden in GitHub Markdown documents.
  MenuSpec.separator(),
  calloutMenu(l, 'insert.callout', l.cmdInsertCallout),
  _c('write.insert.details', label: l.cmdInsertDetails),
  _c('write.insert.card', label: l.cmdInsertCard),
  _c('write.insert.grid', label: l.cmdInsertGrid),
  _c('write.insert.youtube', label: l.cmdInsertYouTube),
  _c(
    'write.insert.button',
    label: l.menuButtonEllipsis,
    menuId: 'insert.button',
  ),
  _c(
    'write.insert.button',
    label: l.menuSecondaryButtonEllipsis,
    args: {'variant': 'secondary'},
    menuId: 'insert.buttonSecondary',
  ),
  _c('write.insert.arrowLink', label: l.menuArrowLinkEllipsis),
  _c('write.format.chip', label: l.cmdFormatChip, menuId: 'insert.chip'),
  MenuSpec.separator(),
  _c('write.link.insert', label: l.menuLink),
  _c('write.insert.mentionTrigger', label: l.cmdInsertMentionTrigger),
  _c('write.insert.emoji', label: l.cmdInsertEmoji),
  _c('write.insert.specialCharacter', label: l.cmdInsertSpecialCharacter),
  MenuSpec.separator(),
  _c('shell.comments.create', label: l.menuComment, menuId: 'insert.comment'),
  _c('write.insert.fromFile', label: l.menuFromFile, menuId: 'insert.fromFile'),
]);

/// Format (Write 05 §7.5).
MenuSubmenu formatMenu(WriteLocalizations l) =>
    MenuSpec.submenu(WriteMenuIds.format, l.menuFormat, [
      MenuSpec.submenu('format.text', l.menuText, [
        _c('write.format.bold'),
        _c('write.format.italic'),
        _c('write.format.strikethrough'),
        _c('write.format.inlineCode', label: l.cmdFormatInlineCode),
        _c('write.format.chip', label: l.cmdFormatChip),
      ]),
      MenuSpec.submenu('format.styles', l.menuParagraphStyles, [
        _c(
          'write.format.blockType.paragraph',
          label: l.cmdFormatBlockTypeParagraph,
          radio: true,
        ),
        for (var i = 1; i <= 6; i++)
          _c(
            'write.format.blockType.heading$i',
            label: _heading(l, i),
            radio: true,
          ),
        _c(
          'write.format.blockType.quote',
          label: l.cmdFormatBlockTypeQuote,
          radio: true,
        ),
        _c(
          'write.format.blockType.codeBlock',
          label: l.cmdFormatBlockTypeCodeBlock,
          radio: true,
        ),
        MenuSpec.separator(),
        _c('write.heading.toggleStep', label: l.cmdHeadingToggleStep),
        _c('write.heading.renumberSteps', label: l.cmdHeadingRenumberSteps),
      ]),
      MenuSpec.submenu('format.lists', l.menuBulletsNumbering, [
        _c('write.list.toggleBulleted', label: l.cmdListToggleBulleted),
        _c('write.list.toggleNumbered', label: l.cmdListToggleNumbered),
        _c('write.list.toggleChecklist', label: l.cmdListToggleChecklist),
        MenuSpec.separator(),
        _c('write.list.indent', label: l.cmdListIndent),
        _c('write.list.outdent', label: l.cmdListOutdent),
        _c('write.list.toggleChecked', label: l.menuToggleChecked),
      ]),
      MenuSpec.submenu('format.link', l.menuLinkSubmenu, [
        _c(
          'write.link.insert',
          label: l.menuInsertOrEditLink,
          menuId: 'format.link.insert',
        ),
        _c('write.link.remove', label: l.cmdLinkRemove),
        MenuSpec.submenu('format.link.style', l.linkStyle, [
          for (final (style, label) in [
            ('plain', l.linkStylePlain),
            ('arrow', l.linkStyleArrow),
            ('button', l.linkStyleButton),
            ('buttonSecondary', l.linkStyleButtonSecondary),
          ])
            _c(
              'write.link.setStyle',
              label: label,
              args: {'style': style},
              menuId: 'format.link.style.$style',
              radio: true,
            ),
        ]),
      ]),
      _c('write.format.clearFormatting'),
      MenuSpec.separator(),
      MenuSpec.submenu('format.table', l.menuTable, [
        _c('write.table.editCell', label: l.menuEditCells),
        _c('write.table.edit', label: l.cmdTableEdit),
        _c('write.table.copyAsTsv', label: l.cmdTableCopyAsTsv),
        _c('write.table.delete', label: l.cmdTableDelete),
      ]),
      MenuSpec.submenu('format.image', l.menuImage, [
        _c('write.image.preview', label: l.cmdImagePreview),
        _c('write.image.editAlt', label: l.cmdImageEditAlt),
        _c('write.image.replace', label: l.menuImageReplace),
        _c('write.image.download', label: l.menuImageDownload),
      ]),
      MenuSpec.submenu('format.code', l.menuCodeBlock, [
        _c('write.code.copy', label: l.cmdCodeCopy),
        _c('write.code.exit', label: l.cmdCodeExit),
      ]),
      // Wonky Markdown (Write 11 §7.5).
      containerMenu(l),
      gridMenu(l),
      MenuSpec.separator(),
      MenuSpec.submenu('format.theme', l.menuTheme, [
        for (final b in BuiltinThemes.all)
          _c(
            'write.theme.apply',
            label: b.name,
            args: {'themeId': b.uuid},
            menuId: 'format.theme.${b.key}',
            radio: true,
          ),
        _c(
          'write.theme.useDefault',
          label: l.cmdThemeUseDefault,
          menuId: 'format.theme.useDefault',
          radio: true,
        ),
        MenuSpec.separator(),
        _c('write.theme.openPicker', label: l.menuMoreThemes),
        _c('write.theme.openEditor', label: l.cmdThemeOpenEditor),
        _c('write.theme.openManager', label: l.cmdThemeOpenManager),
        MenuSpec.separator(),
        _c('write.theme.setUserDefault', label: l.cmdThemeSetUserDefault),
      ]),
    ]);

/// Callout ▸ the six types (Insert menu, toolbar).
MenuSubmenu calloutMenu(WriteLocalizations l, String id, String label) =>
    MenuSpec.submenu(id, label, [
      for (final (variant, name) in calloutVariantLabels(l))
        _c(
          'write.insert.callout',
          label: name,
          args: {'variant': variant},
          menuId: '$id.$variant',
        ),
    ]);

/// The callout types and their labels.
List<(String, String)> calloutVariantLabels(WriteLocalizations l) => [
  ('info', l.calloutInfo),
  ('tip', l.calloutTip),
  ('note', l.calloutNote),
  ('warning', l.calloutWarning),
  ('caution', l.calloutCaution),
  ('danger', l.calloutDanger),
];

/// Format › Container (Write 11 §7.5); also the container chrome's menu.
MenuSubmenu containerMenu(
  WriteLocalizations l, {
  Map<String, Object?> args = const {},
}) => MenuSpec.submenu('format.container', l.menuContainer, [
  MenuSpec.submenu('format.container.type', l.menuCalloutType, [
    for (final (variant, name) in calloutVariantLabels(l))
      _c(
        'write.box.setVariant',
        label: name,
        args: {...args, 'variant': variant},
        menuId: 'format.container.type.$variant',
        radio: true,
      ),
  ]),
  _c('write.box.editTitle', label: l.menuEditTitleEllipsis, args: args),
  _c('write.details.toggleCollapsed', label: l.cmdDetailsToggleCollapsed),
  MenuSpec.submenu('format.container.convert', l.menuChangeTo, [
    for (final (type, name) in [
      ('callout', l.cmdInsertCallout),
      ('details', l.cmdInsertDetails),
      ('card', l.cmdInsertCard),
    ])
      _c(
        'write.box.convert',
        label: name,
        args: {...args, 'type': type},
        menuId: 'format.container.convert.$type',
        radio: true,
      ),
  ]),
  MenuSpec.separator(),
  _c('write.box.unwrap', label: l.cmdBoxUnwrap, args: args),
  _c('write.box.delete', label: l.cmdBoxDelete, args: args),
]);

/// Format › Grid (Write 11 §7.5).
MenuSubmenu gridMenu(
  WriteLocalizations l, {
  Map<String, Object?> args = const {},
}) => MenuSpec.submenu('format.grid', l.cmdInsertGrid, [
  MenuSpec.submenu('format.grid.columns', l.menuColumns, [
    for (var n = 1; n <= 4; n++)
      _c(
        'write.grid.setColumns',
        label: '$n',
        args: {...args, 'columns': n},
        menuId: 'format.grid.columns.$n',
        radio: true,
      ),
  ]),
  MenuSpec.submenu('format.grid.bullets', l.menuBullets, [
    for (final (bullets, name) in [
      ('check', l.gridBulletsCheck),
      ('circle', l.gridBulletsCircle),
      ('none', l.gridBulletsNone),
    ])
      _c(
        'write.grid.setBullets',
        label: name,
        args: {...args, 'bullets': bullets},
        menuId: 'format.grid.bullets.$bullets',
        radio: true,
      ),
  ]),
  _c('write.grid.addItem', label: l.cmdGridAddItem, args: args),
  MenuSpec.separator(),
  _c('write.grid.delete', label: l.menuDeleteGrid, args: args),
]);

String _heading(WriteLocalizations l, int level) => switch (level) {
  1 => l.cmdFormatBlockTypeHeading1,
  2 => l.cmdFormatBlockTypeHeading2,
  3 => l.cmdFormatBlockTypeHeading3,
  4 => l.cmdFormatBlockTypeHeading4,
  5 => l.cmdFormatBlockTypeHeading5,
  _ => l.cmdFormatBlockTypeHeading6,
};
