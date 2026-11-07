import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../../features/elements/style/style_toolbar.dart'
    show arrowItems, quickStyleItems, routingItems;
import '../../features/settings/slides_settings.dart' show slidesLanguages;
import '../../l10n/slides_l10n.dart';
import '../slides_features.dart';

/// Ids of the Slides menus and of the dynamic menu slots the editor screen
/// fills (`MenuCustomItems`); stable for MCP `ui.get_menu_tree`.
abstract final class SlidesMenuIds {
  static const insert = 'insert';
  static const format = 'format';
  static const slide = 'slide';
  static const arrange = 'arrange';
  static const extensions = 'extensions';

  /// Insert › New slide with layout ▸ — the deck theme's layouts.
  static const newSlideLayouts = 'insert.newSlideLayout.list';

  /// Insert › Shape ▸ — the shape gallery (SL-14 supplies the grid).
  static const shapeGallery = 'insert.shape.gallery';

  /// Format › Shape › Change shape ▸ — the shape gallery (SL-14).
  static const changeShapeGallery = 'format.shape.change.gallery';

  /// Insert › Table ▸ — the table size picker.
  static const tablePicker = 'insert.table.picker';

  /// Slide › Apply layout ▸ — the deck theme's layouts.
  static const applyLayouts = 'slide.applyLayout.list';

  /// Slide › Group ▸ Add to group ▸ — the deck's groups.
  static const addToGroup = 'slide.group.addTo.list';

  /// The text context menu's spelling section (suggestions, *Ignore*,
  /// *Add to dictionary* for the misspelled word at the caret, SL-44).
  static const spellingSuggestions = 'context.text.spelling';
}

/// The group colors of 04 §5.4 (token names, `groupColor.<name>`).
const slideGroupColors = [
  'gray',
  'red',
  'orange',
  'amber',
  'green',
  'teal',
  'blue',
  'violet',
  'pink',
];

MenuCommand _c(
  String id, {
  String? label,
  Map<String, Object?> args = const {},
  String? menuId,
  bool radio = false,
}) => MenuSpec.command(id, label: label, args: args, id: menuId, radio: radio);

/// The Slides menubar (Slides 04 §4 — the canonical registry of menu-bound
/// command ids): the shell's shared menus (File, Edit, View, Tools, Help)
/// extended with the Slides items, plus Insert, Format, Slide, Arrange and
/// Extensions. Items of features that are off ([SlidesFeatures]) are
/// pruned from the tree (SL-23), so menus, the palette's menu paths and MCP
/// `ui.get_menu_tree` only list what works; empty menus disappear (the
/// Extensions menu keeps MCP).
MenuRoot slidesMenus(ShellMenus shell, {required SlidesLocalizations l}) =>
    SlidesFeatures.pruneRoot(_slidesMenus(shell, l: l));

MenuRoot _slidesMenus(ShellMenus shell, {required SlidesLocalizations l}) {
  var root = shell.root;

  // ---- File (§4.1)
  root = root
      .replace('shell.file.import', [_c('slides.file.importSlides')])
      .replace(ShellMenuIds.fileDownload, [
        MenuSpec.submenu(ShellMenuIds.fileDownload, l.menuDownload, [
          for (final (f, label) in [
            ('pdf', l.downloadPdf),
            ('png', l.downloadPng),
            ('pngZip', l.downloadPngZip),
            ('markdown', l.downloadMarkdown),
          ])
            _c(
              'slides.file.download',
              label: label,
              args: {'format': f},
              menuId: 'file.download.$f',
            ),
        ]),
      ])
      .replace(ShellMenuIds.fileVersions, [
        MenuSpec.submenu(ShellMenuIds.fileVersions, l.menuVersionHistory, [
          _c('slides.history.nameCurrentVersion'),
          _c('slides.history.open'),
        ]),
      ])
      .insertAfter('shell.file.details', [
        MenuSpec.submenu('file.language', l.menuLanguage, [
          for (final (code, name) in slidesLanguages)
            _c(
              'slides.file.setLanguage',
              label: name,
              args: {'language': code},
              menuId: 'file.language.$code',
              radio: true,
            ),
        ]),
        _c('slides.file.pageSetup'),
      ])
      .replace('shell.file.print', [_c('slides.print.open')]);

  // ---- Edit (§4.2)
  root = root
      .insertAfter('shell.edit.pasteWithoutFormatting', [
        MenuSpec.submenu('edit.pasteSpecial', l.menuPasteSpecial, [
          for (final (mode, label) in [
            ('keepSource', l.pasteKeepSource),
            ('useDestination', l.pasteUseDestination),
            ('unlinked', l.pasteChartUnlinked),
          ])
            _c(
              'slides.edit.pasteSpecial',
              label: label,
              args: {'mode': mode},
              menuId: 'edit.pasteSpecial.$mode',
            ),
        ]),
        _c('slides.edit.duplicate'),
        _c('slides.edit.delete'),
      ])
      .insertAfter('shell.edit.selectAll', [_c('slides.select.escape')])
      .insertAfter(ShellMenuIds.editEndOfSelect, [
        _c('slides.find.open'),
        _c('slides.find.openReplace'),
        MenuSpec.separator(),
        _c('slides.format.copyStyle'),
        _c('slides.format.pasteStyle'),
        MenuSpec.separator(),
      ]);

  // ---- View (§4.3): rebuilt in the spec's order around the shell's App
  // theme submenu.
  final appTheme = root.find(ShellMenuIds.viewTheme)!;
  root = root.replace(ShellMenuIds.view, [
    MenuSpec.submenu(ShellMenuIds.view, shell.l10n.menuView, [
      presentMenu(l, id: 'view.present'),
      MenuSpec.separator(),
      for (final (mode, label) in [
        ('normal', l.viewNormal),
        ('grid', l.viewGrid),
        ('outline', l.viewOutline),
      ])
        _c(
          'slides.view.setMode',
          label: label,
          args: {'mode': mode},
          menuId: 'view.mode.$mode',
          radio: true,
        ),
      _c(
        'slides.view.setMode',
        label: l.menuEditMasters,
        args: const {'mode': 'masters'},
        menuId: 'view.mode.masters',
      ),
      MenuSpec.separator(),
      MenuSpec.submenu('view.show', l.menuShow, [
        _c('slides.view.toggleNavigator'),
        _c('slides.view.toggleInspector'),
        _c('slides.view.toggleNotes'),
        _c('slides.view.toggleRulers'),
        _c('slides.view.toggleGuides'),
        _c('slides.animate.toggleOrderOverlay'),
        _c('slides.magicMove.toggleMatches'),
        _c('slides.view.toggleCommentPins'),
        _c('slides.view.toggleRemoteCursors'),
      ]),
      MenuSpec.submenu('view.snap', l.menuSnap, [
        _c('slides.view.toggleSmartGuides'),
        _c('slides.view.toggleSnapObjects'),
        _c('slides.view.toggleSnapGuides'),
        _c('slides.view.toggleSnapGrid'),
      ]),
      MenuSpec.submenu('view.guides', l.menuGuides, [
        _c(
          'slides.guides.add',
          label: l.guidesAddVertical,
          args: const {'axis': 'vertical'},
          menuId: 'view.guides.addVertical',
        ),
        _c(
          'slides.guides.add',
          label: l.guidesAddHorizontal,
          args: const {'axis': 'horizontal'},
          menuId: 'view.guides.addHorizontal',
        ),
        _c('slides.guides.clear'),
      ]),
      MenuSpec.separator(),
      MenuSpec.submenu(ShellMenuIds.viewZoom, l.menuZoom, [
        _c('slides.view.zoomFit', label: l.zoomFit, menuId: 'view.zoom.fit'),
        for (final p in const [50, 100, 150, 200])
          _c(
            'slides.view.zoom',
            label: l.zoomPercent(p),
            args: {'percent': p},
            menuId: 'view.zoom.$p',
            radio: true,
          ),
        MenuSpec.separator(),
        _c('slides.view.zoomIn'),
        _c('slides.view.zoomOut'),
        _c('slides.view.zoomToSelection'),
      ]),
      MenuSpec.submenu(ShellMenuIds.viewPanels, l.menuPanels, [
        _c('shell.comments.togglePanel', menuId: 'view.panels.comments'),
        _c('slides.panel.layers'),
        _c('slides.panel.themes'),
        _c('slides.panel.accessibility'),
        _c('slides.panel.linkedObjects'),
        _c('shell.ai.togglePanel', menuId: 'view.panels.assistant'),
        _c('slides.panel.animate', menuId: 'view.panels.animate'),
      ]),
      appTheme,
      MenuSpec.submenu(ShellMenuIds.viewMode, shell.l10n.menuMode, [
        _c('slides.mode.editing', radio: true),
        _c('slides.mode.viewing', radio: true),
      ]),
    ]),
  ]);

  // ---- Insert, Format, Slide, Arrange (§4.4–§4.7)
  root = root.insertMenusBefore(ShellMenuIds.tools, [
    insertMenu(l),
    formatMenu(l),
    slideMenu(l),
    arrangeMenu(l),
  ]);

  // ---- Tools (§4.8)
  root = root.insertAfter('tools.assistant', [
    MenuSpec.submenu('tools.spelling', l.menuSpelling, [
      _c('slides.spelling.check'),
      _c('slides.spelling.toggleUnderline'),
      _c(
        'slides.spelling.personalDictionary',
        label: l.menuPersonalDictionary,
        menuId: 'tools.spelling.dictionary',
      ),
    ]),
    _c('slides.tools.accessibilityCheck'),
    _c(
      'slides.panel.linkedObjects',
      label: l.cmdPanelLinkedObjects,
      menuId: 'tools.linkedObjects',
    ),
    _c(
      'slides.present.rehearse',
      label: l.menuRehearsePresentation,
      menuId: 'tools.rehearse',
    ),
    _c('slides.notifications.openSettings'),
    MenuSpec.separator(),
  ]);

  // ---- Extensions (§4.9); Help (§4.10) is the shell's.
  return root.insertMenusBefore(ShellMenuIds.help, [extensionsMenu(l)]);
}

/// Present ▸ (View menu) — also the Present split button's menu (04 §3).
MenuSubmenu presentMenu(SlidesLocalizations l, {required String id}) =>
    MenuSpec.submenu(id, l.menuPresent, [
      _c('slides.present.fromCurrent', menuId: '$id.fromCurrent'),
      _c('slides.present.fromStart', menuId: '$id.fromStart'),
      _c('slides.present.presenterView', menuId: '$id.presenterView'),
      _c('slides.present.rehearse', menuId: '$id.rehearse'),
    ]);

/// Insert (§4.4).
MenuSubmenu insertMenu(SlidesLocalizations l) =>
    MenuSpec.submenu(SlidesMenuIds.insert, l.menuInsert, [
      _c('slides.slide.new', menuId: 'insert.newSlide'),
      MenuSpec.submenu('insert.newSlideLayout', l.menuNewSlideWithLayout, [
        MenuSpec.custom(SlidesMenuIds.newSlideLayouts),
      ]),
      _c('slides.slide.duplicateForMagicMove'),
      MenuSpec.separator(),
      _c('slides.insert.textBox'),
      MenuSpec.submenu('insert.image', l.menuImage, [
        for (final (source, label) in [
          ('upload', l.imageUpload),
          ('drive', l.imageFromDrive),
          ('url', l.imageByUrl),
          ('clipboard', l.imageFromClipboard),
        ])
          _c(
            'slides.insert.image',
            label: label,
            args: {'source': source},
            menuId: 'insert.image.$source',
          ),
      ]),
      MenuSpec.submenu('insert.shape', l.menuShape, [
        MenuSpec.custom(SlidesMenuIds.shapeGallery),
        _c(
          'slides.insert.shape',
          label: l.menuShapeGallery,
          args: const {'pick': true},
          menuId: 'insert.shape.all',
        ),
      ]),
      MenuSpec.submenu('insert.line', l.menuLine, lineInsertItems(l)),
      MenuSpec.submenu('insert.table', l.menuTable, [
        MenuSpec.custom(SlidesMenuIds.tablePicker),
      ]),
      MenuSpec.submenu('insert.code', l.menuCodeBlock, [
        for (final (lang, label) in [
          ('dart', 'Dart'),
          ('javascript', 'JavaScript'),
          ('python', 'Python'),
          ('plaintext', l.codePlainText),
        ])
          _c(
            'slides.insert.code',
            label: label,
            args: {'language': lang},
            menuId: 'insert.code.$lang',
          ),
        MenuSpec.separator(),
        _c(
          'slides.insert.code',
          label: l.codeAllLanguages,
          args: const {'pick': true},
          menuId: 'insert.code.all',
        ),
      ]),
      MenuSpec.submenu('insert.chart', l.menuChart, [
        _c('slides.insert.chartFromSheets', label: l.chartFromSheets),
        MenuSpec.separator(),
        for (final (type, label) in [
          ('column', l.chartColumn),
          ('bar', l.chartBar),
          ('line', l.chartLine),
          ('pie', l.chartPie),
          ('area', l.chartArea),
          ('scatter', l.chartScatter),
        ])
          _c(
            'slides.insert.chart',
            label: label,
            args: {'type': type},
            menuId: 'insert.chart.$type',
          ),
      ]),
      _c('slides.insert.icon'),
      _c('slides.insert.emoji'),
      _c('slides.insert.specialCharacter'),
      MenuSpec.separator(),
      _c('slides.insert.link'),
      _c('shell.comments.create', menuId: 'insert.comment'),
      _c(
        'slides.panel.animate',
        label: l.menuAnimation,
        args: const {'tab': 'build'},
        menuId: 'insert.animation',
      ),
      MenuSpec.separator(),
      _c('slides.deck.openNumbering'),
      MenuSpec.submenu('insert.placeholder', l.menuPlaceholder, [
        // Date placeholders are P2 (not drawn on slides yet, 05 §4).
        for (final t in SlidePlaceholderType.values)
          if (t != SlidePlaceholderType.date)
            _c(
              'slides.layout.insertPlaceholder',
              label: placeholderTypeLabel(l, t),
              args: {'type': t.name},
              menuId: 'insert.placeholder.${t.name}',
            ),
      ]),
    ]);

/// Insert › Line ▸ items (also the toolbar's line dropdown).
List<MenuSpec> lineInsertItems(SlidesLocalizations l) => [
  for (final (key, label, routing, arrows) in [
    ('line', l.lineLine, 'straight', 'none'),
    ('arrow', l.lineArrow, 'straight', 'end'),
    ('doubleArrow', l.lineDoubleArrow, 'straight', 'both'),
    ('elbow', l.lineElbowConnector, 'elbow', 'end'),
    ('curved', l.lineCurvedConnector, 'curved', 'end'),
  ])
    _c(
      'slides.insert.line',
      label: label,
      args: {'routing': routing, 'arrows': arrows},
      menuId: 'insert.line.$key',
    ),
];

/// Format (§4.5).
MenuSubmenu formatMenu(SlidesLocalizations l) =>
    MenuSpec.submenu(SlidesMenuIds.format, l.menuFormat, [
      MenuSpec.submenu('format.text', l.menuText, [
        _c('slides.format.bold'),
        _c('slides.format.italic'),
        _c('slides.format.underline'),
        _c('slides.format.strikethrough'),
        MenuSpec.separator(),
        _c(
          'slides.format.script',
          label: l.textSuperscript,
          args: const {'value': 'super'},
          menuId: 'format.text.superscript',
        ),
        _c(
          'slides.format.script',
          label: l.textSubscript,
          args: const {'value': 'sub'},
          menuId: 'format.text.subscript',
        ),
        MenuSpec.separator(),
        MenuSpec.submenu('format.text.size', l.menuSize, [
          _c('slides.format.increaseFontSize'),
          _c('slides.format.decreaseFontSize'),
        ]),
        MenuSpec.submenu('format.text.caps', l.menuCapitalization, [
          for (final (v, label) in [
            ('upper', l.capsUpper),
            ('smallCaps', l.capsSmallCaps),
            ('title', l.capsTitle),
            ('none', l.capsNone),
          ])
            _c(
              'slides.format.caps',
              label: label,
              args: {'value': v},
              menuId: 'format.text.caps.$v',
              radio: true,
            ),
        ]),
      ]),
      MenuSpec.submenu('format.textStyle', l.menuTextStyle, [
        for (final key in textStyleKeys)
          _c(
            'slides.format.textStyle',
            label: textStyleLabel(l, key),
            args: {'key': key},
            menuId: 'format.textStyle.$key',
            radio: true,
          ),
      ]),
      MenuSpec.submenu('format.align', l.menuAlignIndent, [
        for (final (v, label) in [
          ('left', l.alignLeft),
          ('center', l.alignCenter),
          ('right', l.alignRight),
          ('justify', l.alignJustify),
        ])
          _c(
            'slides.format.align',
            label: label,
            args: {'value': v},
            menuId: 'format.align.$v',
            radio: true,
          ),
        MenuSpec.separator(),
        for (final (v, label) in [
          ('top', l.anchorTop),
          ('middle', l.anchorMiddle),
          ('bottom', l.anchorBottom),
        ])
          _c(
            'slides.format.anchor',
            label: label,
            args: {'value': v},
            menuId: 'format.anchor.$v',
            radio: true,
          ),
        MenuSpec.separator(),
        _c('slides.format.indent'),
        _c('slides.format.outdent'),
      ]),
      MenuSpec.submenu('format.spacing', l.menuSpacing, [
        for (final (v, label) in [
          (1.0, l.spacingSingle),
          (1.15, '1.15'),
          (1.5, '1.5'),
          (2.0, l.spacingDouble),
        ])
          _c(
            'slides.format.lineHeight',
            label: label,
            args: {'value': v},
            menuId: 'format.spacing.$v',
            radio: true,
          ),
        _c(
          'slides.format.lineHeight',
          label: l.spacingCustom,
          menuId: 'format.spacing.custom',
        ),
        MenuSpec.separator(),
        _c(
          'slides.format.paragraphSpacing',
          label: l.spacingAddBefore,
          args: const {'before': true},
          menuId: 'format.spacing.before',
        ),
        _c(
          'slides.format.paragraphSpacing',
          label: l.spacingAddAfter,
          args: const {'after': true},
          menuId: 'format.spacing.after',
        ),
      ]),
      MenuSpec.submenu('format.lists', l.menuLists, [
        for (final (v, label) in [
          ('bullet', l.listBulleted),
          ('number', l.listNumbered),
          ('check', l.listChecklist),
        ])
          _c(
            'slides.format.list',
            label: label,
            args: {'type': v},
            menuId: 'format.lists.$v',
            radio: true,
          ),
        MenuSpec.separator(),
        _c('slides.format.listStyle', label: l.listOptions),
        _c('slides.format.listStart'),
      ]),
      MenuSpec.submenu('format.autofit', l.menuTextFitting, [
        for (final (v, label) in [
          ('none', l.autofitNone),
          ('shrink', l.autofitShrink),
          ('resize', l.autofitResize),
        ])
          _c(
            'slides.format.autofit',
            label: label,
            args: {'mode': v},
            menuId: 'format.autofit.$v',
            radio: true,
          ),
      ]),
      MenuSpec.separator(),
      _c('slides.format.fill', label: l.menuFillEllipsis),
      _c('slides.format.stroke', label: l.menuBorderEllipsis),
      _c('slides.format.effects', label: l.menuEffectsEllipsis),
      _c('slides.format.opacity'),
      MenuSpec.submenu('format.image', l.menuImage, [
        _c('slides.image.crop'),
        _c('slides.image.mask'),
        _c('slides.image.replace'),
        _c('slides.image.adjust'),
        _c('slides.image.reset'),
        _c('slides.image.downloadOriginal'),
      ]),
      MenuSpec.submenu(
        'format.table',
        l.menuTable,
        tableItems(l, 'format.table'),
      ),
      MenuSpec.submenu('format.shape', l.menuShape, [
        MenuSpec.submenu('format.shape.change', l.menuChangeShape, [
          MenuSpec.custom(SlidesMenuIds.changeShapeGallery),
          _c(
            'slides.shape.change',
            label: l.menuShapeGallery,
            menuId: 'format.shape.change.all',
          ),
        ]),
        MenuSpec.submenu(
          'format.shape.quickStyles',
          l.menuQuickStyles,
          quickStyleItems(l, null, 'format.shape'),
        ),
      ]),
      MenuSpec.submenu('format.line', l.menuLine, [
        MenuSpec.submenu(
          'format.line.startArrow',
          l.lineStartArrow,
          arrowItems(l, 'start', 'format.line'),
        ),
        MenuSpec.submenu(
          'format.line.endArrow',
          l.lineEndArrow,
          arrowItems(l, 'end', 'format.line'),
        ),
        MenuSpec.submenu(
          'format.line.routing',
          l.menuRouting,
          routingItems(l, 'format.line'),
        ),
      ]),
      MenuSpec.submenu('format.code', l.menuCode, [
        _c('slides.code.edit'),
        _c('slides.code.setLanguage'),
        MenuSpec.submenu('format.code.palette', l.cmdCodeSetPalette, [
          for (final (id, label) in [
            ('auto', l.codePaletteAuto),
            ('light', l.codePaletteLight),
            ('dark', l.codePaletteDark),
          ])
            _c(
              'slides.code.setPalette',
              label: label,
              args: {'palette': id},
              menuId: 'format.code.palette.$id',
            ),
        ]),
        _c(
          'slides.code.updateOptions',
          label: l.codeLineNumbers,
          args: const {'toggle': 'lineNumbers'},
          menuId: 'format.code.lineNumbers',
        ),
        _c(
          'slides.code.updateOptions',
          label: l.codeWrap,
          args: const {'toggle': 'wrap'},
          menuId: 'format.code.wrap',
        ),
        MenuSpec.separator(),
        _c('slides.code.setHighlightSteps'),
        _c('slides.code.addState'),
        _c('slides.code.toggleDiffGutter'),
        _c(
          'slides.inspector.open',
          label: l.codeStates,
          args: const {'tab': 'format', 'section': 'code'},
          menuId: 'format.code.states',
        ),
        MenuSpec.separator(),
        _c('slides.code.copy'),
      ]),
      MenuSpec.submenu('format.chart', l.menuChart, [
        _c('slides.chart.update'),
        _c('slides.chart.setAutoUpdate'),
        _c('slides.chart.openSource'),
        _c('slides.chart.unlink'),
        _c('slides.chart.relink'),
        MenuSpec.separator(),
        _c(
          'slides.chart.setUseDeckTheme',
          label: l.chartMatchThemeShort,
          args: const {'useDeckTheme': true},
          menuId: 'format.chart.matchTheme',
          radio: true,
        ),
        _c(
          'slides.chart.setUseDeckTheme',
          label: l.chartKeepSource,
          args: const {'useDeckTheme': false},
          menuId: 'format.chart.keepSource',
          radio: true,
        ),
        _c('slides.chart.resetOverrides'),
        MenuSpec.separator(),
        _c('slides.chart.viewDataTable'),
        _c('slides.chart.copyAsImage'),
        _c(
          'slides.inspector.open',
          label: l.chartCustomize,
          args: const {'tab': 'format', 'section': 'chart'},
          menuId: 'format.chart.options',
        ),
      ]),
      MenuSpec.separator(),
      _c('slides.element.editAltText'),
      _c('slides.format.paintFormat'),
      _c('slides.format.clear'),
      _c(
        'slides.inspector.open',
        label: l.menuFormatOptions,
        args: const {'tab': 'format'},
        menuId: 'format.options',
      ),
    ]);

/// Table items (Format › Table ▸ and the table context menu, 04 §11.4).
List<MenuSpec> tableItems(SlidesLocalizations l, String prefix) => [
  _c(
    'slides.table.insertRow',
    label: l.tableInsertRowAbove,
    args: const {'below': false},
    menuId: '$prefix.rowAbove',
  ),
  _c(
    'slides.table.insertRow',
    label: l.tableInsertRowBelow,
    args: const {'below': true},
    menuId: '$prefix.rowBelow',
  ),
  _c(
    'slides.table.insertColumn',
    label: l.tableInsertColumnLeft,
    args: const {'right': false},
    menuId: '$prefix.columnLeft',
  ),
  _c(
    'slides.table.insertColumn',
    label: l.tableInsertColumnRight,
    args: const {'right': true},
    menuId: '$prefix.columnRight',
  ),
  MenuSpec.separator(),
  _c('slides.table.deleteRows', menuId: '$prefix.deleteRow'),
  _c('slides.table.deleteColumns', menuId: '$prefix.deleteColumn'),
  MenuSpec.separator(),
  _c('slides.table.mergeCells', menuId: '$prefix.merge'),
  _c('slides.table.unmergeCells', menuId: '$prefix.unmerge'),
  _c('slides.table.distributeRows', menuId: '$prefix.distributeRows'),
  _c('slides.table.distributeColumns', menuId: '$prefix.distributeColumns'),
  MenuSpec.separator(),
  _c('slides.table.setOptions', menuId: '$prefix.options'),
];

/// Slide (§4.6).
MenuSubmenu slideMenu(SlidesLocalizations l) =>
    MenuSpec.submenu(SlidesMenuIds.slide, l.menuSlide, [
      _c('slides.slide.new', menuId: 'slide.new'),
      _c('slides.slide.duplicate'),
      _c('slides.slide.delete'),
      _c('slides.slide.toggleSkip'),
      MenuSpec.submenu('slide.move', l.menuMoveSlide, [
        for (final (to, label) in [
          ('start', l.moveToBeginning),
          ('up', l.moveUp),
          ('down', l.moveDown),
          ('end', l.moveToEnd),
        ])
          _c(
            'slides.slide.move',
            label: label,
            args: {'to': to},
            menuId: 'slide.move.$to',
          ),
      ]),
      MenuSpec.separator(),
      MenuSpec.submenu('slide.group', l.menuGroup, [
        _c('slides.group.create'),
        _c('slides.group.ungroup'),
        MenuSpec.submenu('slide.group.addTo', l.menuAddToGroup, [
          MenuSpec.custom(SlidesMenuIds.addToGroup),
          _c('slides.group.addSlides', label: l.menuChooseGroup),
        ]),
        _c('slides.group.removeSlides'),
        _c('slides.group.startRename'),
        MenuSpec.submenu('slide.group.color', l.menuGroupColor, [
          for (final color in slideGroupColors)
            _c(
              'slides.group.setColor',
              label: groupColorLabel(l, color),
              args: {'color': color},
              menuId: 'slide.group.color.$color',
              radio: true,
            ),
          _c(
            'slides.group.setColor',
            label: l.colorNone,
            args: const {'color': null},
            menuId: 'slide.group.color.none',
            radio: true,
          ),
        ]),
        _c('slides.group.toggleSkip'),
        MenuSpec.separator(),
        _c('slides.group.collapse'),
        _c('slides.group.expand'),
        _c('slides.group.collapseAll'),
        _c('slides.group.expandAll'),
      ]),
      MenuSpec.separator(),
      MenuSpec.submenu('slide.applyLayout', l.menuApplyLayout, [
        MenuSpec.custom(SlidesMenuIds.applyLayouts),
      ]),
      _c('slides.slide.resetToLayout'),
      _c(
        'slides.inspector.open',
        label: l.menuChangeBackground,
        args: const {'tab': 'slide', 'section': 'background'},
        menuId: 'slide.background',
      ),
      _c(
        'slides.panel.animate',
        label: l.menuTransition,
        args: const {'tab': 'transition'},
        menuId: 'slide.transition',
      ),
      _c('slides.animate.preview'),
      _c('slides.animate.removeAll'),
      MenuSpec.separator(),
      _c(
        'slides.panel.themes',
        label: l.menuChangeTheme,
        menuId: 'slide.changeTheme',
      ),
      _c('slides.theme.edit'),
      _c(
        'slides.view.setMode',
        label: l.menuEditMasters,
        args: const {'mode': 'masters'},
        menuId: 'slide.editMasters',
      ),
      MenuSpec.separator(),
      _c('slides.nav.goToSlide'),
      _c('slides.nav.previousSlide'),
      _c('slides.nav.nextSlide'),
    ]);

/// Arrange (§4.7).
MenuSubmenu arrangeMenu(SlidesLocalizations l) =>
    MenuSpec.submenu(SlidesMenuIds.arrange, l.menuArrange, [
      MenuSpec.submenu(
        'arrange.order',
        l.menuOrder,
        orderItems(l, 'arrange.order'),
      ),
      MenuSpec.submenu('arrange.align', l.menuAlign, [
        for (final (edge, label) in [
          ('left', l.alignLeft),
          ('center', l.alignCenter),
          ('right', l.alignRight),
          ('top', l.anchorTop),
          ('middle', l.anchorMiddle),
          ('bottom', l.anchorBottom),
        ])
          _c(
            'slides.arrange.align',
            label: label,
            args: {'edge': edge},
            menuId: 'arrange.align.$edge',
          ),
      ]),
      MenuSpec.submenu('arrange.distribute', l.menuDistribute, [
        for (final (axis, label) in [
          ('horizontal', l.axisHorizontally),
          ('vertical', l.axisVertically),
        ])
          _c(
            'slides.arrange.distribute',
            label: label,
            args: {'axis': axis},
            menuId: 'arrange.distribute.$axis',
          ),
      ]),
      MenuSpec.submenu('arrange.center', l.menuCenterOnSlide, [
        for (final (axis, label) in [
          ('horizontal', l.axisHorizontally),
          ('vertical', l.axisVertically),
          ('both', l.axisBoth),
        ])
          _c(
            'slides.arrange.centerOnSlide',
            label: label,
            args: {'axis': axis},
            menuId: 'arrange.center.$axis',
          ),
      ]),
      MenuSpec.submenu('arrange.matchSize', l.menuMatchSize, [
        for (final (d, label) in [
          ('width', l.sizeWidth),
          ('height', l.sizeHeight),
          ('both', l.axisBoth),
        ])
          _c(
            'slides.arrange.matchSize',
            label: label,
            args: {'dimension': d},
            menuId: 'arrange.matchSize.$d',
          ),
      ]),
      MenuSpec.submenu(
        'arrange.rotate',
        l.menuRotate,
        rotateItems(l, 'arrange.rotate'),
      ),
      MenuSpec.separator(),
      _c('slides.arrange.group'),
      _c('slides.arrange.ungroup'),
      MenuSpec.separator(),
      _c('slides.element.toggleLock'),
      _c('slides.element.unlockAll'),
      _c('slides.element.hide'),
      _c('slides.element.show'),
      MenuSpec.separator(),
      _c(
        'slides.panel.animate',
        label: l.menuAnimateEllipsis,
        args: const {'tab': 'build'},
        menuId: 'arrange.animate',
      ),
      _c(
        'slides.inspector.open',
        label: l.menuSizePosition,
        args: const {'tab': 'format', 'section': 'arrange'},
        menuId: 'arrange.sizePosition',
      ),
      _c('slides.panel.layers', menuId: 'arrange.layers'),
    ]);

/// Order ▸ items (Arrange menu, element context menu).
List<MenuSpec> orderItems(SlidesLocalizations l, String prefix) => [
  for (final (op, label) in [
    ('front', l.orderBringToFront),
    ('forward', l.orderBringForward),
    ('backward', l.orderSendBackward),
    ('back', l.orderSendToBack),
  ])
    _c(
      'slides.arrange.order',
      label: label,
      args: {'op': op},
      menuId: '$prefix.$op',
    ),
];

/// Rotate ▸ items (Arrange menu, element context menu).
List<MenuSpec> rotateItems(SlidesLocalizations l, String prefix) => [
  _c(
    'slides.arrange.rotate',
    label: l.rotateClockwise,
    args: const {'degrees': 90},
    menuId: '$prefix.cw',
  ),
  _c(
    'slides.arrange.rotate',
    label: l.rotateCounterClockwise,
    args: const {'degrees': -90},
    menuId: '$prefix.ccw',
  ),
  MenuSpec.separator(),
  _c(
    'slides.arrange.flip',
    label: l.flipHorizontally,
    args: const {'axis': 'horizontal'},
    menuId: '$prefix.flipH',
  ),
  _c(
    'slides.arrange.flip',
    label: l.flipVertically,
    args: const {'axis': 'vertical'},
    menuId: '$prefix.flipV',
  ),
];

/// Extensions (§4.9).
MenuSubmenu extensionsMenu(SlidesLocalizations l) =>
    MenuSpec.submenu(SlidesMenuIds.extensions, l.menuExtensions, [
      MenuSpec.submenu('extensions.ai', l.menuAi, [
        _c('slides.ai.generateDeck'),
        MenuSpec.submenu('extensions.ai.rewrite', l.menuRewriteText, [
          for (final (mode, label) in [
            ('shorter', l.rewriteShorter),
            ('longer', l.rewriteLonger),
            ('clearer', l.rewriteClearer),
            ('formal', l.rewriteFormal),
            ('grammar', l.rewriteGrammar),
            ('custom', l.rewriteCustom),
          ])
            _c(
              'slides.ai.rewrite',
              label: label,
              args: {'mode': mode},
              menuId: 'extensions.ai.rewrite.$mode',
            ),
        ]),
        _c('slides.ai.suggestLayouts'),
        _c('slides.ai.speakerNotes'),
        _c('slides.ai.altText'),
        _c('slides.ai.codeWalkthrough'),
      ]),
      MenuSpec.submenu('extensions.mcp', l.menuMcp, [
        _c('shell.mcp.copyConnectionInfo'),
      ]),
    ]);

/// The theme text style keys in menu order (05 §2.5).
const textStyleKeys = [
  'title',
  'subtitle',
  'heading',
  'body',
  'body2',
  'caption',
  'quote',
  'attribution',
  'bigNumber',
  'label',
];

String textStyleLabel(SlidesLocalizations l, String key) => switch (key) {
  'title' => l.styleTitle,
  'subtitle' => l.styleSubtitle,
  'heading' => l.styleHeading,
  'body' => l.styleBody,
  'body2' => l.styleBody2,
  'caption' => l.styleCaption,
  'quote' => l.styleQuote,
  'attribution' => l.styleAttribution,
  'bigNumber' => l.styleBigNumber,
  'label' => l.styleLabel,
  _ => key,
};

String groupColorLabel(SlidesLocalizations l, String color) => switch (color) {
  'gray' => l.colorGray,
  'red' => l.colorRed,
  'orange' => l.colorOrange,
  'amber' => l.colorAmber,
  'green' => l.colorGreen,
  'teal' => l.colorTeal,
  'blue' => l.colorBlue,
  'violet' => l.colorViolet,
  'pink' => l.colorPink,
  _ => color,
};

String placeholderTypeLabel(SlidesLocalizations l, SlidePlaceholderType t) =>
    switch (t.name) {
      'title' => l.styleTitle,
      'subtitle' => l.styleSubtitle,
      'body' => l.styleBody,
      'picture' => l.placeholderPicture,
      'chart' => l.menuChart,
      'table' => l.menuTable,
      'code' => l.menuCode,
      'caption' => l.styleCaption,
      'bigNumber' => l.styleBigNumber,
      'quote' => l.styleQuote,
      'attribution' => l.styleAttribution,
      'object' => l.placeholderObject,
      'footer' => l.placeholderFooter,
      'slideNumber' => l.placeholderSlideNumber,
      'date' => l.placeholderDate,
      _ => t.name,
    };
