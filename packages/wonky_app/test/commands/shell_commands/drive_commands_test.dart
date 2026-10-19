import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';

void main() {
  late CommandTestHarness h;

  setUp(() => h = CommandTestHarness());
  tearDown(() => h.dispose());

  group('Given a document in My Drive', () {
    late DriveItemView doc;
    setUp(() => doc = h.drive.seed(name: 'Plan'));

    test('when renaming it then the drive has the new name', () async {
      final r = await h.invoke('shell.drive.rename', {
        'uuid': doc.uuid.uuid,
        'name': 'Q3 plan',
      });

      expect(r.isOk, isTrue);
      expect(h.drive.item(doc.uuid).name, 'Q3 plan');
    });

    test('when setting its description then undo and redo restore each '
        'value', () async {
      final r = await h.invoke('shell.drive.setDescription', {
        'uuid': doc.uuid.uuid,
        'description': '  Budget for Q3 ',
      });
      expect(r.isOk, isTrue);
      expect(h.drive.item(doc.uuid).description, 'Budget for Q3');

      await h.undo();
      expect(h.drive.item(doc.uuid).description, isNull);

      await h.redo();
      expect(h.drive.item(doc.uuid).description, 'Budget for Q3');
    });

    test('when clearing its description then it is removed', () async {
      await h.invoke('shell.drive.setDescription', {
        'uuid': doc.uuid.uuid,
        'description': 'x',
      });

      await h.invoke('shell.drive.setDescription', {
        'uuid': doc.uuid.uuid,
        'description': '',
      });

      expect(h.drive.item(doc.uuid).description, isNull);
    });

    test('when undoing a rename then the old name is back', () async {
      await h.invoke('shell.drive.rename', {
        'uuid': doc.uuid.uuid,
        'name': 'Q3 plan',
      });

      await h.undo();

      expect(h.drive.item(doc.uuid).name, 'Plan');
    });

    test('when redoing an undone rename then the new name is back', () async {
      await h.invoke('shell.drive.rename', {
        'uuid': doc.uuid.uuid,
        'name': 'Q3 plan',
      });
      await h.undo();

      await h.redo();

      expect(h.drive.item(doc.uuid).name, 'Q3 plan');
    });

    test('when starring it then it is starred and undo unstars it', () async {
      await h.invoke('shell.drive.setStarred', {
        'uuid': doc.uuid.uuid,
        'starred': true,
      });
      expect(h.drive.item(doc.uuid).starred, isTrue);

      await h.undo();

      expect(h.drive.item(doc.uuid).starred, isFalse);
    });

    test(
      'when trashing it then it is in the trash and undo restores it',
      () async {
        await h.invoke('shell.drive.trash', {'uuid': doc.uuid.uuid});
        expect(h.drive.item(doc.uuid).trashedAt, isNotNull);

        await h.undo();

        expect(h.drive.item(doc.uuid).trashedAt, isNull);
      },
    );

    test('when moving it into a folder then undo moves it back', () async {
      final folder = h.drive.seed(name: 'Projects', kind: DriveItemKind.folder);
      await h.invoke('shell.drive.move', {
        'uuid': doc.uuid.uuid,
        'folderUuid': folder.uuid.uuid,
      });
      expect(h.drive.item(doc.uuid).parentUuid, folder.uuid);

      await h.undo();

      expect(h.drive.item(doc.uuid).parentUuid, isNull);
    });

    test('when deleting it forever with confirmation then it is gone and '
        'nothing is undoable', () async {
      await h.invoke('shell.drive.trash', {'uuid': doc.uuid.uuid});
      await h.invoke('shell.drive.deleteForever', {
        'uuid': doc.uuid.uuid,
        'confirmed': true,
      });

      expect(() => h.drive.item(doc.uuid), throwsA(isA<FakeNotFound>()));
      expect(h.undoLabels, hasLength(1)); // only the trash step
    });
  });

  test('Given an empty drive when creating a folder by name then it exists '
      'and undo trashes it', () async {
    final r = await h.invoke('shell.drive.newFolder', {'name': 'Projects'});
    final uuid = UuidValue.fromString((r.data! as Map)['uuid'] as String);
    expect(h.drive.item(uuid).kind, DriveItemKind.folder);

    await h.undo();

    expect(h.drive.item(uuid).trashedAt, isNotNull);
  });

  test('Given an open folder when creating a folder with an explicit null '
      'parent then it is created in My Drive', () async {
    final open = h.drive.seed(name: 'Open', kind: DriveItemKind.folder);
    h.services.currentFolder.value = open;

    final r = await h.invoke('shell.drive.newFolder', {
      'name': 'Root level',
      'parentUuid': null,
    });

    final uuid = UuidValue.fromString((r.data! as Map)['uuid'] as String);
    expect(h.drive.item(uuid).parentUuid, isNull);
  });
}
