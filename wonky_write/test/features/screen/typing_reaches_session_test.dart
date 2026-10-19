import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write/commands/screen_commands.dart';
import 'package:wonky_write/features/editor/keyboard/editor_keyboard.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write/features/screen/write_document_controller.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

void main() {
  testWidgets(
    'Given the welcome document in the screen editor setup when typing then the change reaches the server and is undoable',
    (tester) async {
      // Tests run in the package folder (wonky_write).
      final md = File(
        '../wonky_server/lib/src/platform/drive/templates/builtin_templates.dart',
      ).readAsStringSync();
      final start = md.indexOf('# Welcome to Wonky Work');
      final welcome = md.substring(start, md.indexOf("'''", start));
      final server = FakeDocumentServer(
        initial: const MarkdownCodec().importMarkdown(welcome).delta,
      );
      final h = SessionHarness(server);
      await tester.runAsync(() => h.open());
      final catalog = WriteThemeCatalog();
      h.services.registry.registerAll(writeCommands(h.services, catalog));
      final doc = WriteDocumentController(
        services: h.services,
        session: h.session,
        themes: catalog,
      );
      h.services.activate(doc);
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => WonkyEditor(
                controller: doc.editor,
                commands: doc.commands,
                clipboard: doc.clipboard,
                theme: doc.documentTheme.editorTheme(Brightness.light),
                imageServices: doc.images,
                keymap: (e) =>
                    h.services.keymap.handle(
                      e,
                      KeyScope.editor,
                      context: context,
                    ) ==
                    KeyEventResult.handled,
                shortcutCallbacks: const EditorShortcutCallbacks(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.placeCaretInParagraph(
        h.session.editor.document.first.id,
        21,
      );
      await tester.typeImeText(' there');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(pumpEventQueue);
      expect(DeltaUtils.text(h.doc), startsWith('Welcome to Wonky Work there'));
      expect(
        DeltaUtils.text(server.document),
        startsWith('Welcome to Wonky Work there'),
      );
      expect(h.undo.canUndo.value, isTrue);

      h.services.deactivate(doc);
      doc.dispose();
      await tester.runAsync(h.dispose);
    },
  );
}
