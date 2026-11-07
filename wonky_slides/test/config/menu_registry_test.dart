import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/commands/slides_command.dart';
import 'package:wonky_slides/config/menus/context_menu_specs.dart';
import 'package:wonky_slides/config/slides_features.dart';
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_ui/testing.dart';

import '../harness/deck_harness.dart';

/// The menubar is the canonical registry of menu-bound command ids
/// (Slides 04 §4, AC-1/AC-2): every item dispatches a registered command,
/// the tree carries the spec's ids, and `ui.get_menu_tree` resolves titles,
/// enabled states and reasons.
void main() {
  late DeckHarness d;

  setUp(() => d = DeckHarness.open());
  tearDown(() => d.dispose());

  /// A context with the Slides and shell localizations.
  Future<BuildContext> contextOf(WidgetTester tester) async {
    late BuildContext ctx;
    await pumpWonky(
      tester,
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
      extraDelegates: [
        WonkyAppLocalizations.delegate,
        ...d.services.config.localizationsDelegates,
      ],
      wrap: (context, child) =>
          Provider<ShellServices>.value(value: d.services, child: child!),
    );
    return ctx;
  }

  List<MenuCommand> commandsOf(List<MenuSpec> nodes) => [
    for (final n in nodes)
      ...switch (n) {
        MenuCommand() => [n],
        MenuSubmenu(:final children) => commandsOf(children),
        _ => const <MenuCommand>[],
      },
  ];

  /// The command ids of Slides 04 §4 (golden list; the spec's shell ids
  /// that the shell names differently are mapped: Open… = `shell.file.open`,
  /// Accessibility settings = `shell.settings.open`, Mode = `slides.mode.*`,
  /// Panels › Comments/Assistant = the shell toggles).
  const golden = {
    // File
    'shell.file.new', 'shell.file.newFromTemplate', 'shell.file.open',
    'slides.file.importSlides', 'shell.drive.copy', 'shell.sharing.open',
    'shell.sharing.copyLink', 'slides.file.download', 'shell.drive.rename',
    'shell.drive.move', 'shell.drive.addShortcut', 'shell.drive.trash',
    'slides.history.nameCurrentVersion', 'slides.history.open',
    'shell.drive.togglePinnedOffline', 'shell.file.details',
    'slides.file.setLanguage', 'slides.file.pageSetup', 'slides.print.open',
    // Edit
    'shell.edit.undo', 'shell.edit.redo', 'shell.edit.undoHistory',
    'shell.edit.cut', 'shell.edit.copy', 'shell.edit.paste',
    'shell.edit.pasteWithoutFormatting', 'slides.edit.pasteSpecial',
    'slides.edit.duplicate', 'slides.edit.delete', 'shell.edit.selectAll',
    'slides.select.escape', 'slides.find.openReplace',
    'slides.format.copyStyle', 'slides.format.pasteStyle',
    // View
    'slides.present.fromCurrent', 'slides.present.fromStart',
    'slides.present.presenterView', 'slides.present.rehearse',
    'slides.view.setMode', 'slides.view.toggleNavigator',
    'slides.view.toggleInspector', 'slides.view.toggleNotes',
    'slides.view.toggleRulers', 'slides.view.toggleGuides',
    'slides.animate.toggleOrderOverlay', 'slides.magicMove.toggleMatches',
    'slides.view.toggleCommentPins', 'slides.view.toggleRemoteCursors',
    'slides.view.toggleSmartGuides', 'slides.view.toggleSnapObjects',
    'slides.view.toggleSnapGuides', 'slides.view.toggleSnapGrid',
    'slides.guides.add', 'slides.guides.clear', 'slides.view.zoomFit',
    'slides.view.zoom', 'slides.view.zoomIn', 'slides.view.zoomOut',
    'slides.view.zoomToSelection', 'shell.comments.togglePanel',
    'slides.panel.layers', 'slides.panel.themes',
    'slides.panel.accessibility', 'slides.panel.linkedObjects',
    'shell.ai.togglePanel',
    'slides.panel.animate', 'shell.appearance.setTheme',
    'slides.mode.editing', 'slides.mode.viewing',
    // Insert
    'slides.slide.new', 'slides.slide.duplicateForMagicMove',
    'slides.insert.textBox', 'slides.insert.image', 'slides.insert.shape',
    'slides.insert.line', 'slides.insert.code',
    'slides.insert.chartFromSheets', 'slides.insert.chart',
    'slides.insert.icon', 'slides.insert.emoji',
    'slides.insert.specialCharacter', 'slides.insert.link',
    'shell.comments.create', 'slides.deck.openNumbering',
    'slides.layout.insertPlaceholder',
    // Format
    'slides.format.bold', 'slides.format.italic', 'slides.format.underline',
    'slides.format.strikethrough', 'slides.format.script',
    'slides.format.increaseFontSize', 'slides.format.decreaseFontSize',
    'slides.format.caps', 'slides.format.textStyle', 'slides.format.align',
    'slides.format.anchor', 'slides.format.indent', 'slides.format.outdent',
    'slides.format.lineHeight', 'slides.format.paragraphSpacing',
    'slides.format.list', 'slides.format.listStyle', 'slides.format.listStart',
    'slides.format.autofit', 'slides.format.fill', 'slides.format.stroke',
    'slides.format.effects', 'slides.format.opacity', 'slides.image.crop',
    'slides.image.mask', 'slides.image.replace', 'slides.image.adjust',
    'slides.image.reset', 'slides.image.downloadOriginal',
    'slides.table.insertRow', 'slides.table.insertColumn',
    'slides.table.deleteRows', 'slides.table.deleteColumns',
    'slides.table.mergeCells', 'slides.table.unmergeCells',
    'slides.table.distributeRows', 'slides.table.distributeColumns',
    'slides.table.setOptions', 'slides.shape.change',
    'slides.shape.applyQuickStyle', 'slides.line.setArrow',
    'slides.line.setRouting', 'slides.code.setLanguage',
    'slides.code.updateOptions', 'slides.code.setHighlightSteps',
    'slides.chart.update', 'slides.chart.setAutoUpdate',
    'slides.chart.openSource', 'slides.chart.unlink',
    'slides.element.editAltText', 'slides.format.paintFormat',
    'slides.format.clear', 'slides.inspector.open',
    // Slide
    'slides.slide.duplicate', 'slides.slide.delete', 'slides.slide.toggleSkip',
    'slides.slide.move', 'slides.group.create', 'slides.group.ungroup',
    'slides.group.addSlides', 'slides.group.removeSlides',
    'slides.group.startRename', 'slides.group.setColor',
    'slides.group.toggleSkip', 'slides.group.collapse', 'slides.group.expand',
    'slides.group.collapseAll', 'slides.group.expandAll',
    'slides.slide.resetToLayout', 'slides.animate.preview',
    'slides.animate.removeAll', 'slides.theme.edit', 'slides.nav.goToSlide',
    'slides.nav.previousSlide', 'slides.nav.nextSlide',
    // Arrange
    'slides.arrange.order', 'slides.arrange.align',
    'slides.arrange.distribute', 'slides.arrange.centerOnSlide',
    'slides.arrange.matchSize', 'slides.arrange.rotate', 'slides.arrange.flip',
    'slides.arrange.group', 'slides.arrange.ungroup',
    'slides.element.toggleLock', 'slides.element.unlockAll',
    'slides.element.hide', 'slides.element.show',
    // Tools
    'slides.spelling.check', 'slides.spelling.toggleUnderline',
    'slides.tools.accessibilityCheck',
    'slides.notifications.openSettings', 'shell.help.shortcuts',
    'shell.settings.openApp',
    // Extensions
    'slides.ai.generateDeck', 'slides.ai.rewrite', 'slides.ai.suggestLayouts',
    'slides.ai.speakerNotes', 'slides.ai.altText', 'slides.ai.codeWalkthrough',
    'shell.mcp.copyConnectionInfo',
    // Help
    'shell.board.report', 'shell.board.open', 'shell.help.about',
  };

  testWidgets('Given the Slides menubar when it is built then every item '
      'dispatches a registered command and every spec id is present (AC-1)', (
    tester,
  ) async {
    final context = await contextOf(tester);
    final root = d.services.menuRoot(context);

    expect(
      [for (final m in root.children) (m as MenuSubmenu).label],
      [
        'File',
        'Edit',
        'View',
        'Insert',
        'Format',
        'Slide',
        'Arrange',
        'Tools',
        'Extensions',
        'Help',
      ],
    );
    final items = commandsOf(root.children);
    final unregistered = {
      for (final c in items)
        if (d.services.registry.byId(c.commandId) == null) c.commandId,
    };
    expect(unregistered, isEmpty);
    final ids = {for (final c in items) c.commandId};
    // Ids of features that are off are hidden (SL-23); the rest is there.
    final offered = {
      for (final id in golden)
        if (SlidesFeatures.registers(id) &&
            !SlidesFeatures.hidesShellCommand(id))
          id,
    };
    expect(offered.difference(ids), isEmpty);
    // SL-28 shipped masters mode, layout editing and the theme editor.
    expect(SlidesFeatures.isOn(SlidesFeature.masters), isTrue);
    expect(
      ids,
      containsAll(['slides.theme.edit', 'slides.layout.insertPlaceholder']),
    );
    expect([
      for (final c in items)
        if (c.commandId == 'slides.view.setMode') c.args['mode'],
    ], contains('masters'));
    // SL-43 shipped the assistant and the AI commands; the code
    // walkthrough stays hidden.
    expect(SlidesFeatures.isOn(SlidesFeature.assistant), isTrue);
    expect(
      ids,
      containsAll([
        'slides.ai.generateDeck',
        'slides.ai.rewrite',
        'slides.ai.speakerNotes',
        'slides.ai.altText',
        'slides.ai.suggestLayouts',
        'shell.ai.togglePanel',
      ]),
    );
    expect(ids, isNot(contains('slides.ai.codeWalkthrough')));
    expect({
      for (final c in items)
        if (!SlidesFeatures.offers(c.commandId, c.args) ||
            SlidesFeatures.hidesShellCommand(c.commandId))
          c.effectiveId,
    }, isEmpty);
    // Item ids are unique (stable keys for MCP and the menubar).
    final itemIds = [for (final c in items) c.effectiveId];
    final dupes = <String>{};
    final seen = <String>{};
    for (final id in itemIds) {
      if (!seen.add(id)) dupes.add(id);
    }
    expect(dupes, isEmpty);
  });

  testWidgets('Given the menu tree as MCP sees it when resolved then every '
      'item has a title and an enabled state, and placeholders say why '
      '(AC-2)', (tester) async {
    final context = await contextOf(tester);
    final json = MenuResolver(
      d.services,
    ).toJson(context, d.services.menuRoot(context));
    final flat = <Map<String, Object?>>[];
    void walk(List<Object?> nodes) {
      for (final n in nodes.cast<Map<String, Object?>>()) {
        if (n['type'] == 'command') flat.add(n);
        final children = n['items'];
        if (children is List) walk(children);
      }
    }

    walk(json);
    expect(flat, isNotEmpty);
    for (final n in flat) {
      expect(n['title'], isA<String>(), reason: '${n['id']}');
      expect(
        (n['title']! as String).startsWith('slides.'),
        isFalse,
        reason: 'untranslated title of ${n['id']}',
      );
      expect(n['enabled'], isA<bool>(), reason: '${n['id']}');
    }
    // View toggles report their checked state; Fit is on.
    final fit = flat.firstWhere((n) => n['id'] == 'view.zoom.fit');
    expect(fit['checked'], isTrue);
    final navigator = flat.firstWhere(
      (n) => n['commandId'] == 'slides.view.toggleNavigator',
    );
    expect(navigator['checked'], isTrue);
    // No placeholder is offered: unbuilt features are hidden (SL-23).
    expect(d.services.registry.byId('slides.insert.chart'), isNull);
    expect([
      for (final c in d.services.registry.all)
        if (c is SlidesCommand && c.placeholder) c.id.value,
    ], isEmpty);
  });

  testWidgets('Given the context menus when they are built then every item '
      'is a registered command (04 §11)', (tester) async {
    final context = await contextOf(tester);
    final l = slidesL10n(context);
    final menus = slidesContextMenus(l);

    expect([
      for (final m in menus.children) m.effectiveId,
    ], SlidesContextMenuIds.all);
    for (final m in menus.children.cast<MenuSubmenu>()) {
      final items = commandsOf(m.children);
      expect(items, isNotEmpty, reason: m.id);
      for (final c in items) {
        expect(
          d.services.registry.byId(c.commandId),
          isNotNull,
          reason: '${m.id}: ${c.commandId}',
        );
      }
    }
  });

  testWidgets('Given the menubar and context menus when their items are '
      'dispatched then their fixed arguments match the commands\' schemas '
      '(Comment on slide / object passed an unknown "anchor")', (tester) async {
    final context = await contextOf(tester);
    final l = slidesL10n(context);
    final violations = <String>[];
    final menus = [
      ...slidesContextMenus(l).children.cast<MenuSubmenu>(),
      ...d.services.menuRoot(context).children.cast<MenuSubmenu>(),
    ];
    for (final m in menus) {
      for (final c in commandsOf(m.children)) {
        final command = d.services.registry.byId(c.commandId);
        if (command == null) continue;
        for (final v in command.argsSchema.validate(c.args)) {
          violations.add('${m.id} ${c.commandId}: $v');
        }
      }
    }
    expect(violations, isEmpty);
  });

  testWidgets('Given every registered Slides command when its title is read '
      'then it is localized and placeholders name their work package', (
    tester,
  ) async {
    final context = await contextOf(tester);
    final slides = [
      for (final c in d.services.registry.all)
        if (c.id.value.startsWith('slides.')) c,
    ];
    expect(slides.length, greaterThan(150));
    for (final c in slides) {
      final title = c.title(context);
      expect(title, isNotEmpty, reason: c.id.value);
      expect(title, isNot(c.id.value), reason: c.id.value);
      if (c is SlidesCommand && c.placeholder) {
        expect(c.owner, isNotEmpty, reason: c.id.value);
      }
    }
    // Browser-reserved chords are never bound (suite 08 §1.2).
    for (final p in const [KeyPlatform.macWeb, KeyPlatform.otherWeb]) {
      for (final c in slides) {
        for (final b in c.defaultBindings) {
          expect(b.isBrowserReserved(p), isFalse, reason: c.id.value);
        }
      }
    }
  });

  group('Given a feature switched on (a later work package)', () {
    late DeckHarness on;

    setUp(() {
      SlidesFeatures.enabled = {SlidesFeature.nativeCharts};
      on = DeckHarness.open();
    });
    tearDown(() {
      on.dispose();
      SlidesFeatures.reset();
    });

    testWidgets('when its placeholders are read then they are registered, '
        'disabled with the reason, and still name their work package', (
      tester,
    ) async {
      final st = on.services.dispatcher.stateOf('slides.insert.chart');
      expect(st.enabled, isFalse);
      expect(st.disabledReason, slidesL10nEnglish.reasonNotAvailableYet);
      final c = on.services.registry.byId('slides.insert.chart');
      expect((c! as SlidesCommand).owner, contains('SL-32'));
      // Other hidden features stay out.
      expect(on.services.registry.byId('slides.code.edit'), isNull);
    });
  });
}
