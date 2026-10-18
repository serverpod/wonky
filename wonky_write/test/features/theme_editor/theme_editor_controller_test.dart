import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show UndoService, UndoStackKey;
import 'package:wonky_write/features/theme_editor/theme_editor_controller.dart';
import 'package:wonky_write/features/theme_editor/theme_editor_model.dart';
import 'package:wonky_write/features/theme_editor/theme_undo.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import 'support/fake_theme_repository.dart';

void main() {
  late FakeThemeRepository repo;
  late WriteThemeCatalog catalog;
  late UndoService undo;
  late ThemeEditorController? current;

  setUp(() {
    repo = FakeThemeRepository();
    catalog = WriteThemeCatalog();
    undo = UndoService();
    current = null;
    undo.registerHandler(
      ThemeUndoHandler(
        repository: () => repo,
        catalog: catalog,
        host: () => current,
      ),
    );
  });

  Future<ThemeEditorController> open(String uuid) async {
    final c = ThemeEditorController(
      themeUuid: uuid,
      catalog: catalog,
      undo: undo,
      repository: repo,
      myUserUuid: repo.me,
    );
    current = c;
    undo.setActiveDocument(c.draftStack);
    await c.load();
    return c;
  }

  Object? at(ThemeEditorController c, String path) =>
      ThemePropertyPath.get(c.draftJson, path);

  group('Given my theme in the editor', () {
    late ThemeEditorController c;
    setUp(() async => c = await open(repo.seed(name: 'Report').uuid));
    tearDown(() => c.dispose());

    test('when setting a property then the draft changes and is dirty', () {
      final r = c.setProperty('elements.h2.fontSize', '20pt');

      expect(r.isOk, isTrue);
      expect(at(c, 'elements.h2.fontSize'), '20pt');
      expect(c.dirty, isTrue);
      expect(c.resolved().headings[1].style.fontSize, 20);
    });

    test('when undoing a property change then the draft is back', () async {
      c.setProperty('palette.accent', '#ff0000');

      await undo.undo();

      expect(at(c, 'palette.accent'), isNot('#ff0000'));
      expect(c.dirty, isFalse);
      await undo.redo();
      expect(at(c, 'palette.accent'), '#ff0000');
    });

    test('when a gesture sets a value repeatedly then it is one undo step', () {
      for (final v in [1.2, 1.3, 1.4]) {
        c.setProperty('elements.body.lineHeight', v, coalesceKey: 'lh');
      }

      expect(undo.undoStepsOf(c.draftStack), hasLength(1));
    });

    test('when a value is out of bounds then the draft is unchanged', () {
      final r = c.setProperty('elements.body.fontSize', '400pt');

      expect(r.isOk, isFalse);
      expect(c.dirty, isFalse);
    });

    test('when setting a dark override then it lands in the dark layer', () {
      c.setProperty('palette.text', '#eeeeee', variant: ThemeVariant.dark);

      expect(at(c, 'dark.palette.text'), '#eeeeee');
      expect(c.resolved(ThemeVariant.dark).body.style.color, 0xffeeeeee);
    });

    test('when resetting an element then its overrides are gone', () {
      c.setProperty('elements.h3.color', '#123456');
      c.setProperty('elements.h3.fontSize', '15pt');

      c.resetElement(const ThemeNode.element(ThemeElement.h3));

      expect(at(c, 'elements.h3'), isNull);
      expect(undo.undoStepsOf(c.draftStack), hasLength(3));
    });

    test('when fixing a contrast warning then the pair passes', () {
      c.setProperty('palette.text', '#cccccc');
      expect(c.contrastWarnings.map((w) => w.pairId), contains('body'));

      final r = c.fixContrast('body', ThemeVariant.light);

      expect(r.isOk, isTrue);
      expect(
        c.contrastWarnings.where(
          (w) => w.pairId == 'body' && w.variant == ThemeVariant.light,
        ),
        isEmpty,
      );
    });

    test('when saving then the server has the draft and the draft stack is '
        'cleared', () async {
      c.setProperty('elements.h1.fontSize', '30pt');

      final r = await c.save();

      expect(r.isOk, isTrue);
      expect(c.dirty, isFalse);
      expect(c.version, 2);
      final server = jsonDecode(repo.themes[c.themeUuid]!.json) as Map;
      expect((server['elements'] as Map)['h1'], {'fontSize': '30pt'});
      expect(undo.undoStepsOf(c.draftStack), isEmpty);
      expect(
        undo.undoStepsOf(UndoStackKey.shell).single.label,
        'Edit theme “Report”',
      );
      expect(catalog.lookup(c.themeUuid)?.version, 2);
    });

    test('when undoing a save then the previous JSON is saved again', () async {
      c.setProperty('elements.h1.fontSize', '30pt');
      await c.save();

      await undo.undo();

      final server = jsonDecode(repo.themes[c.themeUuid]!.json) as Map;
      expect((server['elements'] as Map)['h1'], isNull);
      expect(at(c, 'elements.h1.fontSize'), isNull);
    });

    test(
      'when the theme was saved elsewhere then saving reports a conflict',
      () async {
        repo.saveElsewhere(
          c.themeUuid,
          canonicalJsonEncode({
            ...BuiltinThemes.wonkyDefault.json,
            'name': 'Report',
            'elements': {
              'h1': {'color': '#00ff00'},
            },
          }),
        );
        c.setProperty('elements.h1.fontSize', '30pt');

        final r = await c.save();

        expect(r.isOk, isFalse);
        expect(c.conflict?.serverVersion, 2);
        expect(c.dirty, isTrue);
      },
    );

    test('when reloading theirs after a conflict then the draft is the '
        "server's", () async {
      repo.saveElsewhere(
        c.themeUuid,
        canonicalJsonEncode({
          ...BuiltinThemes.wonkyDefault.json,
          'name': 'Report',
          'elements': {
            'h1': {'color': '#00ff00'},
          },
        }),
      );
      c.setProperty('elements.h1.fontSize', '30pt');
      await c.save();

      await c.reloadTheirs();

      expect(c.conflict, isNull);
      expect(c.dirty, isFalse);
      expect(at(c, 'elements.h1.color'), '#00ff00');
      expect(c.version, 2);
    });

    test('when overwriting after a conflict then my draft wins', () async {
      repo.saveElsewhere(
        c.themeUuid,
        canonicalJsonEncode({...BuiltinThemes.wonkyDefault.json, 'name': 'X'}),
      );
      c.setProperty('elements.h1.fontSize', '30pt');
      await c.save();

      final r = await c.overwrite();

      expect(r.isOk, isTrue);
      expect(repo.themes[c.themeUuid]!.version, 3);
      expect(c.conflict, isNull);
    });

    test('when reverting then the draft is the saved theme', () async {
      c.setProperty('elements.h1.fontSize', '30pt');

      await c.revert();

      expect(c.dirty, isFalse);
      expect(undo.undoStepsOf(c.draftStack), isEmpty);
    });

    test('when renaming and undoing then the old name is back', () async {
      await c.rename('Letters');
      expect(repo.themes[c.themeUuid]!.name, 'Letters');

      await undo.undo();

      expect(repo.themes[c.themeUuid]!.name, 'Report');
      expect(c.name, 'Report');
    });

    test('when deleting and undoing then the theme is restored', () async {
      await c.delete();
      expect(repo.themes[c.themeUuid]!.isDeleted, isTrue);
      expect(c.readOnly, isTrue);

      await undo.undo();

      expect(repo.themes[c.themeUuid]!.isDeleted, isFalse);
    });

    test('when loading a revision then it becomes the draft', () async {
      c.setProperty('elements.h1.fontSize', '30pt');
      await c.save();
      final revisions = await c.revisions();

      c.loadRevision(revisions.last);

      expect(at(c, 'elements.h1.fontSize'), isNull);
      expect(c.dirty, isTrue);
    });
  });

  group('Given a built-in theme in the editor', () {
    late ThemeEditorController c;
    setUp(() async => c = await open(BuiltinThemes.wonkyDefault.uuid));
    tearDown(() => c.dispose());

    test('when setting a property then it is refused (read-only)', () {
      final r = c.setProperty('elements.h1.fontSize', '30pt');

      expect(r.isOk, isFalse);
      expect(c.readOnly, isTrue);
      expect(c.isBuiltin, isTrue);
    });

    test('when duplicating then a copy is created in my library and undo '
        'deletes it', () async {
      final copy = await c.duplicate();

      expect(copy, isNotNull);
      expect(copy!.name, 'Wonky Default (copy)');
      expect(catalog.mine.map((t) => t.name), ['Wonky Default (copy)']);
      expect(jsonDecode(copy.json)['basedOn'], 'builtin:wonky-default');

      await undo.undo();

      expect(repo.themes[copy.uuid]!.isDeleted, isTrue);
      expect(catalog.mine, isEmpty);
    });
  });

  group("Given a collaborator's theme", () {
    test('when opened then it is read-only', () async {
      final c = await open(repo.seed(name: 'Theirs', owner: 'other').uuid);
      addTearDown(c.dispose);

      expect(c.readOnly, isTrue);
      expect(c.setProperty('palette.text', '#000000').isOk, isFalse);
    });
  });

  group('Given the editor opened from a document', () {
    test('when applying to the document then it is assigned and undo puts '
        'the previous theme back', () async {
      final mine = repo.seed(name: 'Report');
      final c = ThemeEditorController(
        themeUuid: mine.uuid,
        catalog: catalog,
        undo: undo,
        repository: repo,
        myUserUuid: repo.me,
        documentItemUuid: 'item-1',
        loadDocument: (_) async => ThemeEditorDocument(
          itemUuid: 'item-1',
          documentUuid: 'doc-1',
          title: 'Plan',
          delta: Delta()..insert('Hi\n'),
          themeUuid: null,
          canEdit: true,
        ),
      );
      addTearDown(c.dispose);
      current = c;
      await c.load();

      final r = await c.applyToDocument();

      expect(r.isOk, isTrue);
      expect(repo.documentThemes['doc-1'], mine.uuid);
      await undo.undo();
      expect(repo.documentThemes['doc-1'], isNull);
    });
  });
}
