import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/model.dart'
    show NumberFormatPresets, FontSizeSteps;

import '../commands/format_commands.dart' show numberFormatLabel;
import '../features/dialogs/sheets_dialogs.dart' show PasteSpecialMode;
import '../l10n/sheets_l10n.dart';

/// Ids of the Sheets menus and dynamic menu slots (stable for MCP
/// `ui.get_menu_tree`).
abstract final class SheetsMenuIds {
  static const insert = 'insert';
  static const format = 'format';
  static const data = 'data';
  static const extensions = 'extensions';

  /// Dynamic entries supplied by the editor screen (`MenuCustomItems`).
  static const freezeRowsDynamic = 'view.freeze.upToRow';
  static const freezeColumnsDynamic = 'view.freeze.upToColumn';
  static const hiddenSheets = 'view.hiddenSheets.list';
  static const recentNumberFormats = 'format.number.recent';
  static const dynamicLabels = 'dynamic';
}

MenuCommand _c(
  String id, {
  String? label,
  Map<String, Object?> args = const {},
  String? menuId,
  bool radio = false,
}) => MenuSpec.command(id, label: label, args: args, id: menuId, radio: radio);

/// The Sheets menubar (04 §3): the shell's shared menus extended with the
/// Sheets items, plus Insert, Format, Data and Extensions. Items of features
/// that are not built yet are listed (their commands are disabled).
MenuRoot sheetsMenus(ShellMenus shell, {required SheetsLocalizations l}) {
  var root = shell.root;

  // ---- File (§3.1) ----
  root = root
      .replace('shell.file.import', [_c('sheets.file.import')])
      .replace(ShellMenuIds.fileDownload, [
        MenuSpec.submenu(ShellMenuIds.fileDownload, l.menuDownload, [
          for (final (f, label) in [
            ('xlsx', l.downloadXlsx),
            ('ods', l.downloadOds),
            ('pdf', l.downloadPdf),
            ('html', l.downloadHtml),
            ('csv', l.downloadCsv),
            ('tsv', l.downloadTsv),
            ('json', l.downloadJson),
          ])
            _c(
              'sheets.file.download',
              label: label,
              args: {'format': f},
              menuId: 'file.download.$f',
            ),
        ]),
      ])
      .insertAfter(ShellMenuIds.fileEndOfVersions, [
        _c('sheets.file.settings'),
        MenuSpec.separator(),
      ])
      .replace('shell.file.print', [_c('sheets.print.open')]);

  // ---- Edit (§3.2) ----
  root = root
      .replace('shell.edit.pasteWithoutFormatting', [pasteSpecialMenu(l)])
      .insertAfter(ShellMenuIds.editEndOfSelect, [
        MenuSpec.submenu('edit.move', l.menuMove, [
          _c('sheets.rows.moveUp'),
          _c('sheets.rows.moveDown'),
          _c('sheets.cols.moveLeft'),
          _c('sheets.cols.moveRight'),
        ]),
        MenuSpec.submenu('edit.delete', l.menuDelete, [
          _c('sheets.edit.clearValues'),
          _c('sheets.rows.delete'),
          _c('sheets.cols.delete'),
          _c('sheets.cells.deleteShiftLeft'),
          _c('sheets.cells.deleteShiftUp'),
          _c('sheets.notes.clear'),
        ]),
        MenuSpec.separator(),
        _c('sheets.find.openReplace'),
        MenuSpec.separator(),
      ]);

  // ---- View (§3.3) ----
  root = root
      .appendTo(ShellMenuIds.viewMode, [
        _c('sheets.mode.editing', radio: true),
        _c('sheets.mode.viewing', radio: true),
      ])
      .insertAfter(ShellMenuIds.viewMode, [
        MenuSpec.submenu('view.show', l.menuShow, [
          _c('sheets.view.toggleFormulaBar'),
          _c('sheets.view.toggleGridlines'),
          _c('sheets.view.toggleFormulas'),
          _c('sheets.view.toggleProtectedRanges'),
        ]),
        MenuSpec.submenu('view.freeze', l.menuFreeze, [
          _c(
            'sheets.view.freezeRows',
            label: l.freezeNoRows,
            args: {'count': 0},
            menuId: 'view.freeze.rows0',
            radio: true,
          ),
          _c(
            'sheets.view.freezeRows',
            label: l.freezeRows(1),
            args: {'count': 1},
            menuId: 'view.freeze.rows1',
            radio: true,
          ),
          _c(
            'sheets.view.freezeRows',
            label: l.freezeRows(2),
            args: {'count': 2},
            menuId: 'view.freeze.rows2',
            radio: true,
          ),
          MenuSpec.custom(SheetsMenuIds.freezeRowsDynamic),
          MenuSpec.separator(),
          _c(
            'sheets.view.freezeColumns',
            label: l.freezeNoColumns,
            args: {'count': 0},
            menuId: 'view.freeze.cols0',
            radio: true,
          ),
          _c(
            'sheets.view.freezeColumns',
            label: l.freezeColumns(1),
            args: {'count': 1},
            menuId: 'view.freeze.cols1',
            radio: true,
          ),
          _c(
            'sheets.view.freezeColumns',
            label: l.freezeColumns(2),
            args: {'count': 2},
            menuId: 'view.freeze.cols2',
            radio: true,
          ),
          MenuSpec.custom(SheetsMenuIds.freezeColumnsDynamic),
        ]),
        MenuSpec.submenu('view.group', l.menuGroup, [
          _c('sheets.group.groupRows'),
          _c('sheets.group.groupColumns'),
          _c('sheets.group.ungroupRows'),
          _c('sheets.group.ungroupColumns'),
          MenuSpec.separator(),
          _c(
            'sheets.group.expandAll',
            label: l.menuExpandAllRowGroups,
            args: {'dimension': 'rows'},
            menuId: 'view.group.expandRows',
          ),
          _c(
            'sheets.group.collapseAll',
            label: l.menuCollapseAllRowGroups,
            args: {'dimension': 'rows'},
            menuId: 'view.group.collapseRows',
          ),
          _c(
            'sheets.group.expandAll',
            label: l.menuExpandAllColumnGroups,
            args: {'dimension': 'columns'},
            menuId: 'view.group.expandColumns',
          ),
          _c(
            'sheets.group.collapseAll',
            label: l.menuCollapseAllColumnGroups,
            args: {'dimension': 'columns'},
            menuId: 'view.group.collapseColumns',
          ),
        ]),
        MenuSpec.submenu('view.comments', l.menuComments, [
          _c('sheets.comments.openPanel'),
          _c('sheets.comments.next'),
          _c('sheets.comments.previous'),
          _c('sheets.view.toggleCommentIndicators'),
        ]),
        MenuSpec.submenu('view.hiddenSheets', l.menuHiddenSheets, [
          MenuSpec.custom(SheetsMenuIds.hiddenSheets),
        ]),
      ])
      .replace(ShellMenuIds.viewZoom, [
        MenuSpec.submenu(ShellMenuIds.viewZoom, l.menuZoom, [
          for (final p in const [50, 75, 90, 100, 125, 150, 200])
            _c(
              'sheets.view.zoom',
              label: l.zoomPercent(p),
              args: {'percent': p},
              menuId: 'view.zoom.$p',
              radio: true,
            ),
        ]),
      ]);

  // ---- Insert, Format, Data (§3.4–3.6) ----
  root = root.insertMenusBefore(ShellMenuIds.tools, [
    insertMenu(l),
    formatMenu(l),
    dataMenu(l),
  ]);

  // ---- Tools (§3.7) ----
  root = root
      // Sheets' Explore panel (the shell's Tools › Explore is gone).
      .insertAfter('tools.assistant', [_c('sheets.explore.toggle')])
      .insertBefore('tools.preferences', [
        MenuSpec.submenu('tools.spelling', l.menuSpelling, [
          _c('sheets.tools.spellCheck'),
          _c('sheets.tools.personalDictionary'),
        ]),
        _c('sheets.tools.toggleAutocomplete'),
        _c('sheets.tools.toggleFormulaSuggestions'),
        MenuSpec.submenu('tools.notifications', l.menuNotificationSettings, [
          _c('sheets.notifications.openSettings'),
          _c('sheets.notifications.openRules'),
        ]),
        MenuSpec.separator(),
      ]);

  // ---- Extensions (§3.8) ----
  root = root.insertMenusBefore(ShellMenuIds.help, [extensionsMenu(l)]);

  // ---- Help (§3.9) ----
  root = root.insertAfter('shell.help.shortcuts', [
    _c('sheets.help.functionList'),
    _c('sheets.help.scriptApiReference'),
  ]);
  return root;
}

/// Edit › Paste special ▸ (also in context menus).
MenuSubmenu pasteSpecialMenu(SheetsLocalizations l) =>
    MenuSpec.submenu('edit.pasteSpecial', l.menuPasteSpecial, [
      for (final m in PasteSpecialMode.values)
        _c(
          'sheets.edit.pasteSpecial',
          label: m.label(l),
          args: {'mode': m.id},
          menuId: 'edit.pasteSpecial.${m.id}',
        ),
      MenuSpec.separator(),
      _c('sheets.edit.pasteSpecialDialog'),
    ]);

/// Insert (§3.4).
MenuSubmenu insertMenu(SheetsLocalizations l) =>
    MenuSpec.submenu(SheetsMenuIds.insert, l.menuInsert, [
      MenuSpec.submenu('insert.cells', l.menuCells, [
        _c('sheets.cells.insertShiftRight'),
        _c('sheets.cells.insertShiftDown'),
      ]),
      MenuSpec.submenu('insert.rows', l.menuRows, [
        _c('sheets.rows.insertAbove'),
        _c('sheets.rows.insertBelow'),
      ]),
      MenuSpec.submenu('insert.columns', l.menuColumns, [
        _c('sheets.cols.insertLeft'),
        _c('sheets.cols.insertRight'),
      ]),
      _c('sheets.sheet.add'),
      MenuSpec.separator(),
      _c('sheets.chart.insert'),
      _c('sheets.insert.pivotTable'),
      MenuSpec.submenu('insert.image', l.menuImage, [
        _c('sheets.image.insertInCell'),
        _c('sheets.image.insertOverCells'),
      ]),
      _c('sheets.drawing.insert'),
      MenuSpec.separator(),
      MenuSpec.submenu('insert.function', l.menuFunction, [
        for (final f in const ['SUM', 'AVERAGE', 'COUNT', 'MAX', 'MIN'])
          _c(
            'sheets.insert.function',
            label: f,
            args: {'name': f},
            menuId: 'insert.function.$f',
          ),
        MenuSpec.separator(),
        _c('sheets.help.functionList'),
      ]),
      MenuSpec.separator(),
      _c('sheets.insert.link'),
      _c('sheets.insert.checkbox'),
      _c('sheets.insert.dropdown'),
      _c('sheets.insert.emoji'),
      _c('sheets.insert.smartChip'),
      MenuSpec.separator(),
      _c('shell.comments.create', menuId: 'insert.comment'),
      _c('sheets.notes.insert'),
    ]);

/// Format (§3.5).
MenuSubmenu formatMenu(SheetsLocalizations l) =>
    MenuSpec.submenu(SheetsMenuIds.format, l.menuFormat, [
      _c('sheets.theme.openPanel'),
      MenuSpec.submenu('format.number', l.menuNumber, [
        for (final m in NumberFormatPresets.menu)
          _c(
            'sheets.format.numberFormat',
            label: numberFormatLabel(l, m.id),
            args: {'preset': m.id},
            menuId: 'format.number.${m.id}',
            radio: true,
          ),
        MenuSpec.separator(),
        MenuSpec.custom(SheetsMenuIds.recentNumberFormats),
        MenuSpec.separator(),
        _c('sheets.format.openCustomCurrency'),
        _c('sheets.format.openCustomDateTime'),
        _c('sheets.format.openCustomNumberFormat'),
      ]),
      MenuSpec.submenu('format.text', l.menuText, [
        _c('sheets.format.bold'),
        _c('sheets.format.italic'),
        _c('sheets.format.underline'),
        _c('sheets.format.strikethrough'),
      ]),
      MenuSpec.submenu('format.alignment', l.menuAlignment, [
        for (final (v, label) in [
          ('left', l.alignLeft),
          ('center', l.alignCenter),
          ('right', l.alignRight),
        ])
          _c(
            'sheets.format.hAlign',
            label: label,
            args: {'align': v},
            menuId: 'format.align.$v',
            radio: true,
          ),
        MenuSpec.separator(),
        for (final (v, label) in [
          ('top', l.alignTop),
          ('middle', l.alignMiddle),
          ('bottom', l.alignBottom),
        ])
          _c(
            'sheets.format.vAlign',
            label: label,
            args: {'align': v},
            menuId: 'format.valign.$v',
            radio: true,
          ),
      ]),
      MenuSpec.submenu('format.wrapping', l.menuWrapping, [
        for (final (v, label) in [
          ('overflow', l.wrapOverflow),
          ('wrap', l.wrapWrap),
          ('clip', l.wrapClip),
        ])
          _c(
            'sheets.format.wrap',
            label: label,
            args: {'strategy': v},
            menuId: 'format.wrap.$v',
            radio: true,
          ),
      ]),
      MenuSpec.submenu('format.rotation', l.menuRotation, [
        for (final (angle, label) in [
          (0, l.rotationNone),
          (45, l.rotationTiltUp),
          (-45, l.rotationTiltDown),
          (255, l.rotationStack),
          (90, l.rotationUp),
          (-90, l.rotationDown),
        ])
          _c(
            'sheets.format.rotation',
            label: label,
            args: {'angle': angle},
            menuId: 'format.rotation.$angle',
            radio: true,
          ),
        _c(
          'sheets.format.rotation',
          label: l.rotationCustom,
          menuId: 'format.rotation.custom',
        ),
      ]),
      MenuSpec.submenu('format.fontSize', l.menuFontSize, [
        for (final size in FontSizeSteps.menu)
          _c(
            'sheets.format.fontSize',
            label: size.toStringAsFixed(0),
            args: {'size': size},
            menuId: 'format.fontSize.${size.toInt()}',
            radio: true,
          ),
      ]),
      MenuSpec.submenu('format.merge', l.menuMergeCells, [
        _c(
          'sheets.format.merge',
          label: l.mergeAll,
          args: {'mode': 'all'},
          menuId: 'format.merge.all',
        ),
        _c(
          'sheets.format.merge',
          label: l.mergeHorizontally,
          args: {'mode': 'horizontal'},
          menuId: 'format.merge.horizontal',
        ),
        _c(
          'sheets.format.merge',
          label: l.mergeVertically,
          args: {'mode': 'vertical'},
          menuId: 'format.merge.vertical',
        ),
        _c('sheets.format.unmerge'),
      ]),
      _c('sheets.format.convertToTable'),
      MenuSpec.separator(),
      _c('sheets.cf.openPanel'),
      _c('sheets.banding.openPanel'),
      MenuSpec.separator(),
      _c('sheets.format.clear'),
    ]);

/// Data (§3.6).
MenuSubmenu dataMenu(SheetsLocalizations l) =>
    MenuSpec.submenu(SheetsMenuIds.data, l.menuData, [
      MenuSpec.submenu('data.sortSheet', l.menuSortSheet, [
        _c(
          'sheets.data.sortSheet',
          label: l.sortAtoZ,
          args: {'ascending': true},
          menuId: 'data.sortSheet.asc',
        ),
        _c(
          'sheets.data.sortSheet',
          label: l.sortZtoA,
          args: {'ascending': false},
          menuId: 'data.sortSheet.desc',
        ),
      ]),
      MenuSpec.submenu('data.sortRange', l.menuSortRange, [
        _c(
          'sheets.data.sortRange',
          label: l.sortAtoZ,
          args: {'ascending': true},
          menuId: 'data.sortRange.asc',
        ),
        _c(
          'sheets.data.sortRange',
          label: l.sortZtoA,
          args: {'ascending': false},
          menuId: 'data.sortRange.desc',
        ),
        _c('sheets.data.openSortDialog'),
      ]),
      MenuSpec.separator(),
      _c('sheets.filter.toggle'),
      _c('sheets.filterView.create'),
      MenuSpec.submenu('data.changeView', l.cmdFilterViewActivate, [
        // Filled by the editor screen (07 §4.2).
        MenuSpec.custom('data.changeView.list'),
      ]),
      _c('sheets.filter.saveAsFilterView'),
      _c('sheets.slicer.add'),
      MenuSpec.separator(),
      _c('sheets.protect.openPanel'),
      _c('sheets.namedRanges.openPanel'),
      _c('sheets.namedFunctions.openPanel'),
      _c('sheets.data.randomizeRange'),
      MenuSpec.separator(),
      _c('sheets.data.columnStats'),
      _c('sheets.dv.openPanel'),
      MenuSpec.submenu('data.cleanup', l.menuDataCleanup, [
        _c('sheets.cleanup.openSuggestions'),
        _c('sheets.cleanup.openRemoveDuplicates'),
        _c('sheets.cleanup.trimWhitespace'),
        _c('sheets.ai.cleanupSuggestions'),
      ]),
      _c('sheets.data.splitTextToColumns'),
      _c('sheets.data.extraction'),
      MenuSpec.separator(),
      _c('sheets.ai.analyze'),
    ]);

/// Extensions (§3.8).
MenuSubmenu extensionsMenu(SheetsLocalizations l) =>
    MenuSpec.submenu(SheetsMenuIds.extensions, l.menuExtensions, [
      MenuSpec.submenu('extensions.scripts', l.menuScripts, [
        _c('sheets.script.openEditor'),
        MenuSpec.submenu('extensions.macros', l.menuMacros, [
          _c('sheets.macro.record'),
          _c('sheets.macro.import'),
          _c('sheets.macro.manage'),
        ]),
        _c('sheets.script.openTriggers'),
        _c('sheets.script.openExecutions'),
      ]),
      MenuSpec.submenu('extensions.ai', l.menuAi, [
        _c('sheets.ai.suggestFormula'),
        _c('sheets.ai.explainFormula'),
        _c('sheets.ai.fillRange'),
        _c('sheets.ai.analyze', menuId: 'extensions.ai.analyze'),
        _c('sheets.ai.refreshAiCells'),
      ]),
      MenuSpec.submenu('extensions.mcp', 'MCP', [
        _c('shell.mcp.copyConnectionInfo'),
      ]),
    ]);
