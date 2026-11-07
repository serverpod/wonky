import 'dart:ui';

import 'package:flutter/widgets.dart' show IconData;
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write/config/write_app_config.dart';
import 'package:wonky_write/config/write_menus.dart';

void main() {
  group('Given the Write app config', () {
    late CommandTestHarness h;
    late MenuRoot menus;

    setUp(() {
      h = CommandTestHarness(config: const WriteAppConfig());
      menus = writeMenus(
        ShellMenus(lookupWonkyAppLocalizations(const Locale('en'))),
      );
    });

    tearDown(() => h.dispose());

    test('when walking the menubar then every item names a registered '
        'command (AC-05.1)', () {
      final missing = [
        for (final c in menus.commands)
          if (!h.services.registry.contains(c.commandId)) c.commandId,
      ];

      expect(missing, isEmpty);
    });

    test('when listing top-level menus then they follow Write 05 §7', () {
      expect(
        [for (final m in menus.children) (m as MenuSubmenu).label],
        ['File', 'Edit', 'View', 'Insert', 'Format', 'Tools', 'Help'],
      );
    });

    test('when reading the Edit menu then the copy items are together, right '
        'above the paste items (Write 05 §7.2, T-23)', () {
      final edit = menus.find(ShellMenuIds.edit)! as MenuSubmenu;
      final ids = [for (final s in edit.children) s.effectiveId];
      final cut = ids.indexOf('shell.edit.cut');

      expect(ids.sublist(cut, cut + 6), [
        'shell.edit.cut',
        'shell.edit.copy',
        'edit.copyAs',
        'shell.edit.paste',
        'shell.edit.pasteWithoutFormatting',
        'write.edit.pasteAsMarkdown',
      ]);
    });

    test('when walking the menubar then menu ids are unique', () {
      final ids = <String>[];
      void walk(List<MenuSpec> specs) {
        for (final s in specs) {
          if (s is MenuSubmenu) {
            ids.add(s.effectiveId);
            walk(s.children);
          } else if (s is MenuCommand) {
            ids.add(s.effectiveId);
          }
        }
      }

      walk(menus.children);
      final dupes = ids.where((id) => ids.where((x) => x == id).length > 1);

      expect(dupes.toSet(), isEmpty);
    });

    test('when reading View › Panels then it lists the side panels in rail '
        'order with their rail icons (Write 05 §7.3)', () {
      final panels = menus.find(ShellMenuIds.viewPanels)! as MenuSubmenu;
      final items = panels.children.cast<MenuCommand>();

      expect(
        [for (final c in items) c.commandId],
        [
          'shell.ai.togglePanel',
          'write.view.toggleOutline',
          'write.find.open',
          'shell.versions.togglePanel',
        ],
      );
      expect(items.every((c) => c.showIcon), isTrue);
      expect(
        [for (final c in items) h.services.registry.byId(c.commandId)!.icon],
        [
          LucideIcons.sparkles,
          LucideIcons.listTree,
          LucideIcons.search,
          LucideIcons.history,
        ],
      );
    });

    test('when reading the icons then Paste as Markdown, Find, Find next, '
        'Find previous, Code block, Quote, Checklist and Special characters '
        'have theirs', () {
      IconData? icon(String id) => h.services.registry.byId(id)!.icon;

      expect(icon('write.edit.pasteAsMarkdown'), LucideIcons.clipboardList);
      expect(icon('write.find.open'), LucideIcons.search);
      expect(icon('write.find.next'), LucideIcons.arrowBigRightDash);
      expect(icon('write.find.previous'), LucideIcons.arrowBigLeftDash);
      expect(icon('write.format.blockType.codeBlock'), LucideIcons.code);
      expect(icon('write.format.blockType.quote'), LucideIcons.textQuote);
      expect(icon('write.list.toggleChecklist'), LucideIcons.listChecks);
      expect(icon('write.insert.specialCharacter'), LucideIcons.languages);
      // Insert's block items keep their icon although they are toggles.
      for (final id in [
        'insert.codeBlock',
        'insert.quote',
        'insert.checklist',
      ]) {
        expect((menus.find(id)! as MenuCommand).showIcon, isTrue, reason: id);
      }
    });

    test('when reading Tools and Help then Explore, Accessibility settings, '
        'Preferences and What\'s new are gone and Settings is one entry', () {
      final ids = [for (final c in menus.commands) c.effectiveId];
      final commandIds = [for (final c in menus.commands) c.commandId];

      for (final gone in [
        'tools.explore',
        'tools.accessibility',
        'tools.writePrefs',
        'tools.workSettings',
      ]) {
        expect(ids, isNot(contains(gone)), reason: gone);
      }
      expect(commandIds, isNot(contains('shell.help.whatsNew')));
      expect(commandIds.where((c) => c.startsWith('shell.settings.')), [
        'shell.settings.openApp',
      ]);
      expect(
        ids,
        containsAll([ShellMenuIds.helpReportBug, ShellMenuIds.helpSuggest]),
      );
    });

    test('when commands are registered then their ids are well formed', () {
      final bad = [
        for (final c in h.services.registry.all)
          if (c.id.value.startsWith('write.') && !c.id.isValid) c.id.value,
      ];

      expect(bad, isEmpty);
    });
  });
}
