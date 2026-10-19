@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// `drive.list` / `drive.search` in SQL with keyset cursors (CQ-25).
void main() {
  withWonkyServerpod('Given a drive with folders and documents', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      for (final name in ['delta', 'Alpha', 'echo', 'Charlie', 'bravo']) {
        await TestDrive.document(endpoints, anna, name: name);
      }
      await TestDrive.folder(endpoints, anna, name: 'Zulu');
      await TestDrive.folder(endpoints, anna, name: 'Yankee');
    });

    Future<List<String>> pages(
      DriveSort sort, {
      int limit = 2,
      DriveView view = DriveView.folder,
      List<DriveItemKind>? kinds,
    }) async {
      final names = <String>[];
      String? cursor;
      var rounds = 0;
      do {
        final page = await endpoints.drive.list(
          anna.endpointSession,
          null,
          DriveListFilter(view: view, kinds: kinds),
          sort,
          cursor,
          limit,
        );
        expect(page.items.length, lessThanOrEqualTo(limit));
        names.addAll(page.items.map((i) => i.name));
        cursor = page.nextCursor;
        rounds++;
      } while (cursor != null && rounds < 20);
      return names;
    }

    test('when paging by name with folders first then every item comes '
        'once in order', () async {
      final names = await pages(
        DriveSort(
          field: DriveSortField.name,
          descending: false,
          foldersFirst: true,
        ),
      );

      expect(names, [
        'Yankee',
        'Zulu',
        'Alpha',
        'bravo',
        'Charlie',
        'delta',
        'echo',
      ]);
    });

    test('when paging by name descending then the order is reversed '
        'within the folder groups', () async {
      final names = await pages(
        DriveSort(
          field: DriveSortField.name,
          descending: true,
          foldersFirst: true,
        ),
        limit: 3,
      );

      expect(names, [
        'Zulu',
        'Yankee',
        'echo',
        'delta',
        'Charlie',
        'bravo',
        'Alpha',
      ]);
    });

    test('when paging by modification time then the pages match one big '
        'page', () async {
      final sort = DriveSort(
        field: DriveSortField.modifiedAt,
        descending: true,
        foldersFirst: false,
      );
      final all = await endpoints.drive.list(
        anna.endpointSession,
        null,
        DriveListFilter(view: DriveView.folder),
        sort,
        null,
        100,
      );

      final paged = await pages(sort);

      expect(paged, [for (final i in all.items) i.name]);
      expect(all.nextCursor, isNull);
    });

    test('when filtering by kind then only that kind is listed', () async {
      final names = await pages(
        DriveSort(
          field: DriveSortField.name,
          descending: false,
          foldersFirst: true,
        ),
        kinds: [DriveItemKind.folder],
      );

      expect(names, ['Yankee', 'Zulu']);
    });

    test('when some items were opened then the recent view pages by the '
        'last open, newest first', () async {
      final all = await endpoints.drive.list(
        anna.endpointSession,
        null,
        DriveListFilter(view: DriveView.folder),
        DriveSort(
          field: DriveSortField.name,
          descending: false,
          foldersFirst: false,
        ),
        null,
        100,
      );
      final byName = {for (final i in all.items) i.name: i};
      final later = clock.now().toUtc().add(const Duration(hours: 1));
      for (final (i, n) in ['bravo', 'echo', 'Alpha'].indexed) {
        await withClock(
          Clock.fixed(later.add(Duration(minutes: i))),
          () => endpoints.drive.markOpened(
            anna.endpointSession,
            byName[n]!.uuid,
          ),
        );
      }

      final names = await pages(
        DriveSort(
          field: DriveSortField.name,
          descending: false,
          foldersFirst: true,
        ),
        view: DriveView.recent,
      );

      // Created items count as opened too (earlier).
      expect(names.take(3), ['Alpha', 'echo', 'bravo']);
      expect(names.toSet(), hasLength(7));
    });

    test(
      'when a cursor of another sort is passed then it is refused',
      () async {
        final first = await endpoints.drive.list(
          anna.endpointSession,
          null,
          DriveListFilter(view: DriveView.folder),
          DriveSort(
            field: DriveSortField.name,
            descending: false,
            foldersFirst: true,
          ),
          null,
          2,
        );

        await expectLater(
          endpoints.drive.list(
            anna.endpointSession,
            null,
            DriveListFilter(view: DriveView.folder),
            DriveSort(
              field: DriveSortField.size,
              descending: false,
              foldersFirst: true,
            ),
            first.nextCursor,
            2,
          ),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.invalidArgument,
            ),
          ),
        );
      },
    );

    test('when searching with a small page then every match comes once, '
        'and a stranger finds nothing', () async {
      for (var i = 1; i <= 5; i++) {
        await TestDrive.document(endpoints, anna, name: 'Budget $i');
      }
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
      final found = <String>[];
      String? cursor;
      var rounds = 0;
      do {
        final page = await endpoints.drive.search(
          anna.endpointSession,
          'budget',
          DriveSearchFilters(),
          cursor,
          2,
        );
        found.addAll(page.items.map((i) => i.name));
        cursor = page.nextCursor;
        rounds++;
      } while (cursor != null && rounds < 10);

      final strangers = await endpoints.drive.search(
        eve.endpointSession,
        'budget',
        DriveSearchFilters(),
        null,
        10,
      );

      expect(found, hasLength(5));
      expect(found.toSet(), {for (var i = 1; i <= 5; i++) 'Budget $i'});
      expect(strangers.items, isEmpty);
    });

    test(
      'when searching shared items only then only shared ones match',
      () async {
        final shared = await TestDrive.document(
          endpoints,
          anna,
          name: 'Roadmap shared',
        );
        await TestDrive.document(endpoints, anna, name: 'Roadmap private');
        final ben = await TestUsers.create(sessionBuilder, name: 'Ben');
        await TestDrive.share(endpoints, shared, anna, ben, AccessRole.viewer);

        final page = await endpoints.drive.search(
          anna.endpointSession,
          'roadmap',
          DriveSearchFilters(sharedOnly: true),
          null,
          10,
        );
        final bens = await endpoints.drive.search(
          ben.endpointSession,
          'roadmap',
          DriveSearchFilters(),
          null,
          10,
        );

        expect([for (final i in page.items) i.name], ['Roadmap shared']);
        expect([for (final i in bens.items) i.name], ['Roadmap shared']);
      },
    );

    test('when searching for a part of a name then the name matches', () async {
      await TestDrive.document(endpoints, anna, name: 'Quarterly report');

      final page = await endpoints.drive.search(
        anna.endpointSession,
        'terly',
        DriveSearchFilters(),
        null,
        10,
      );

      expect([for (final i in page.items) i.name], ['Quarterly report']);
    });
  });

  withWonkyServerpod('Given published templates', (sessionBuilder, endpoints) {
    test('when listing the gallery then own and shared templates are '
        'shown, a stranger\'s private one is not', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
      final own = await TestDrive.document(endpoints, anna, name: 'Mine');
      final secret = await TestDrive.document(endpoints, eve, name: 'Secret');
      final open = await TestDrive.document(endpoints, eve, name: 'Shared');
      for (final (user, item) in [(anna, own), (eve, secret), (eve, open)]) {
        await endpoints.drive.setTemplate(
          user.endpointSession,
          item.uuid,
          TemplateCategory.values.first,
        );
      }
      await TestDrive.share(endpoints, open, eve, anna, AccessRole.viewer);

      final gallery = await endpoints.drive.listTemplates(
        anna.endpointSession,
        DriveItemKind.document,
      );
      final names = {
        for (final t in gallery)
          if (!t.builtin) t.name,
      };

      expect(names, containsAll(['Mine', 'Shared']));
      expect(names, isNot(contains('Secret')));
    });
  });
}
