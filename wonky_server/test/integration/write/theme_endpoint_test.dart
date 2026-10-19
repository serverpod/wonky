@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/themes/builtin_theme_ids.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show BuiltinThemes;

import '../../support/test_doc_client.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

final _json = jsonEncode(BuiltinThemes.wonkyDefault.json);

void main() {
  withWonkyServerpod('Given the built-in themes', (sessionBuilder, endpoints) {
    test(
      'when listing them then Wonky Default comes first with its stable uuid',
      () async {
        final anna = await TestUsers.create(sessionBuilder);

        final builtins = await endpoints.writeTheme.listBuiltins(
          anna.endpointSession,
        );

        expect(builtins.first.uuid, BuiltinThemeIds.wonkyDefault);
        expect(builtins.map((t) => t.builtinKey), contains('classic-serif'));
        expect(builtins.every((t) => t.isBuiltin), isTrue);
      },
    );

    test('when updating a built-in then it is refused', () async {
      final anna = await TestUsers.create(sessionBuilder);

      await expectLater(
        endpoints.writeTheme.update(
          anna.endpointSession,
          BuiltinThemeIds.wonkyDefault,
          _json,
          1,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when duplicating a built-in then a user theme at version 1 exists',
      () async {
        final anna = await TestUsers.create(sessionBuilder);

        final copy = await endpoints.writeTheme.duplicate(
          anna.endpointSession,
          BuiltinThemeIds.forKey('classic-serif'),
          'My serif',
          null,
        );
        final mine = await endpoints.writeTheme.listMine(anna.endpointSession);

        expect(copy.version, 1);
        expect(mine.map((t) => t.name), ['My serif']);
      },
    );
  });

  withWonkyServerpod('Given a user theme', (sessionBuilder, endpoints) {
    late TestUser anna;
    late WriteThemeView theme;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      theme = await endpoints.writeTheme.create(
        anna.endpointSession,
        'Mine',
        _json,
        null,
      );
    });

    test(
      'when saving with the current version then the version increments',
      () async {
        final saved = await endpoints.writeTheme.update(
          anna.endpointSession,
          theme.uuid,
          _json.replaceFirst('"name":"Wonky Default"', '"name":"Renamed"'),
          theme.version,
        );

        expect(saved.version, 2);
        expect(jsonDecode(saved.json)['name'], 'Renamed');
      },
    );

    test(
      'when saving with a stale version then a ThemeConflictException is thrown',
      () async {
        await endpoints.writeTheme.update(
          anna.endpointSession,
          theme.uuid,
          _json,
          1,
        );

        await expectLater(
          endpoints.writeTheme.update(
            anna.endpointSession,
            theme.uuid,
            _json,
            1,
          ),
          throwsA(
            isA<ThemeConflictException>().having(
              (e) => e.serverVersion,
              'v',
              2,
            ),
          ),
        );
      },
    );

    test('when invalid JSON is saved then it is refused', () async {
      await expectLater(
        endpoints.writeTheme.update(
          anna.endpointSession,
          theme.uuid,
          '{"x":1}',
          1,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      "when another user reads it without a document then it is not found",
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');

        await expectLater(
          endpoints.writeTheme.get(bo.endpointSession, theme.uuid, null),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test(
      'when assigned to a shared document then collaborators can read it via the document',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
        await endpoints.document.updateMeta(
          anna.endpointSession,
          doc.contentRef!,
          DocumentMetaPatch(
            field: 'themeId',
            valueJson: jsonEncode(theme.uuid.uuid),
          ),
          const Uuid().v7obj(),
        );

        final read = await endpoints.writeTheme.get(
          bo.endpointSession,
          theme.uuid,
          doc.contentRef,
        );

        expect(read.uuid, theme.uuid);
      },
    );

    test(
      'when the theme is saved then connected documents get MetaChanged(themeVersion)',
      () async {
        final doc = await TestDrive.document(endpoints, anna);
        await endpoints.document.updateMeta(
          anna.endpointSession,
          doc.contentRef!,
          DocumentMetaPatch(
            field: 'themeId',
            valueJson: jsonEncode(theme.uuid.uuid),
          ),
          const Uuid().v7obj(),
        );
        final client = await TestDocClient.connect(
          endpoints,
          anna,
          doc.contentRef!,
        );

        await endpoints.writeTheme.update(
          anna.endpointSession,
          theme.uuid,
          _json,
          theme.version,
        );
        final meta = await client.next<DocMetaChanged>();

        expect(meta.field, 'themeVersion');
        expect(jsonDecode(meta.valueJson)['version'], 2);
        await client.close();
      },
    );

    test(
      'when deleting and restoring then it leaves and returns to the library',
      () async {
        await endpoints.writeTheme.delete(anna.endpointSession, theme.uuid);
        final afterDelete = await endpoints.writeTheme.listMine(
          anna.endpointSession,
        );
        await endpoints.writeTheme.restore(anna.endpointSession, theme.uuid);
        final afterRestore = await endpoints.writeTheme.listMine(
          anna.endpointSession,
        );

        expect(afterDelete, isEmpty);
        expect(afterRestore.map((t) => t.uuid), [theme.uuid]);
      },
    );
  });
}
