import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write/commands/screen_commands.dart';
import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/screen/write_document_controller.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDocumentServer server;
  late SessionHarness h;
  late WriteDocumentController doc;

  Future<CommandResult> run(
    String id, [
    Map<String, Object?> args = const {},
  ]) => h.services.dispatcher.invoke(
    id,
    args: args,
    source: InvocationSource.mcp,
  );

  String text() => DeltaUtils.text(h.session.editor.delta);

  setUp(() async {
    server = FakeDocumentServer(
      initial: Delta()..insert('Hello colour world, colour\n'),
    );
    h = SessionHarness(server);
    await h.open();
    final catalog = WriteThemeCatalog();
    h.services.registry.registerAll(writeCommands(h.services, catalog));
    doc = WriteDocumentController(
      services: h.services,
      session: h.session,
      themes: catalog,
    );
    h.services.activate(doc);
    await pumpEventQueue();
  });

  tearDown(() async {
    h.services.deactivate(doc);
    doc.dispose();
    await h.dispose();
  });

  group('Given an open document', () {
    test('when every Write command is registered then ids are well formed', () {
      final ids = [
        for (final c in writeCommands(h.services, WriteThemeCatalog())) c.id,
      ];

      expect(ids.where((id) => !id.isValid), isEmpty);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('when bolding a selection then undo and redo toggle it', () async {
      doc.editor.select(const DeltaSelection(0, 5));

      await run('write.format.bold');
      expect(doc.commands.isFormatActive(InlineFormat.bold), isTrue);

      await h.undo.undo();
      expect(h.session.editor.delta.first.attributes, isNull);

      await h.undo.redo();
      expect(h.session.editor.delta.first.attributes, {'bold': true});
    });

    test(
      'when replacing all matches then one undo restores the text',
      () async {
        await run('write.find.replaceAll', {
          'query': 'colour',
          'replacement': 'color',
        });
        expect(text(), 'Hello color world, color\n');
        expect(h.undo.undoStepsOf(h.session.undoStackKey), hasLength(1));

        await h.undo.undo();
        expect(text(), 'Hello colour world, colour\n');

        await h.undo.redo();
        expect(text(), 'Hello color world, color\n');
      },
    );

    test('when switching to Pageless then undo switches back', () async {
      final before = doc.pageSetup.layout;
      final target = before == PageLayoutMode.pages ? 'pageless' : 'pages';

      await run('write.doc.setLayout', {'layout': target});
      await pumpEventQueue();
      expect(doc.pageSetup.layout.name, target);
      expect(doc.view.layout.name, target);

      await h.undo.undo();
      await pumpEventQueue();
      expect(doc.pageSetup.layout, before);

      await h.undo.redo();
      await pumpEventQueue();
      expect(doc.pageSetup.layout.name, target);
    });

    test('when setting a full page setup then it is accepted and undoable '
        '(the args schema allows every PageSetup key)', () async {
      final before = doc.pageSetup.paper;
      final setup = PageSetup(
        paper: before == PaperSize.a4 ? PaperSize.letter : PaperSize.a4,
        margins: const PageMargins.all(54),
      );

      final result = await run('write.doc.setPageSetup', {
        'pageSetup': setup.toJson(),
      });
      await pumpEventQueue();
      expect(result.isOk, isTrue, reason: '$result');
      expect(doc.pageSetup.paper, setup.paper);

      await h.undo.undo();
      await pumpEventQueue();
      expect(doc.pageSetup.paper, before);
    });

    test(
      'when applying a theme then the editor uses it and undo reverts',
      () async {
        final serif = BuiltinThemes.byKey('classic-serif')!;

        await run('write.theme.apply', {'themeId': serif.uuid});
        await pumpEventQueue();
        expect(doc.documentTheme.option.uuid, serif.uuid);

        await h.undo.undo();
        await pumpEventQueue();
        expect(doc.documentTheme.option.builtinKey, BuiltinThemes.defaultKey);

        await h.undo.redo();
        await pumpEventQueue();
        expect(doc.documentTheme.option.uuid, serif.uuid);
      },
    );

    test('when inserting a 2×2 table then undo removes it', () async {
      doc.editor.select(DeltaSelection.collapsed(text().length - 1));

      final r = await run('write.insert.table', {'rows': 2, 'cols': 2});
      expect(r.isOk, isTrue);
      expect(
        h.session.editor.delta.toList().any((op) => op.data is Map),
        isTrue,
      );

      await h.undo.undo();
      expect(
        h.session.editor.delta.toList().any((op) => op.data is Map),
        isFalse,
      );
    });

    test(
      'when the user is in Viewing mode then content commands are disabled',
      () {
        h.session.setMode(EditorMode.viewing);

        final state = h.services.dispatcher.stateOf('write.format.bold');

        expect(state.enabled, isFalse);
        expect(state.disabledReason, contains('Switch to Editing'));
      },
    );

    test(
      'when changing the language then the meta is written and undoable',
      () async {
        await run('write.doc.setLanguage', {'language': 'sv-SE'});
        await pumpEventQueue();
        expect(doc.language, 'sv-SE');

        await h.undo.undo();
        await pumpEventQueue();
        expect(doc.language, isNull);
      },
    );

    test('when navigating to a heading then the caret moves there', () async {
      doc.editor.applyLocal(
        Delta()
          ..retain(text().length - 1)
          ..insert('\nTitle')
          ..retain(1, {'header': 1}),
        label: 'Typing',
      );
      doc.insights.refresh();

      final r = await run('write.nav.goToHeading', {'text': 'Title'});

      expect(r.isOk, isTrue);
      expect(doc.insights.currentHeading, 0);
    });
  });
}
