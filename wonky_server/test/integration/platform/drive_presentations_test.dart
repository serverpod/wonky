@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/kind_masks.dart';

import '../../support/test_drive.dart';
import '../../support/test_files.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _wonky(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// `drive.registerPresentation` (Slides 02 §9.3, RevLog spec 04 §5): a
/// deck a device created registers as `createPresentation(fileUuid,
/// initialize: false)`.
void main() {
  withWonkyServerpod('Given a deck file id from a device', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late UuidValue file;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      file = const Uuid().v7obj();
    });

    test('when registering then a presentation item with the file uuid and '
        'an empty RevLog file are created', () async {
      final item = await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Pitch',
      );

      expect(item.kind, DriveItemKind.presentation);
      expect(item.uuid, file);
      expect(item.contentRef, file);
      expect(item.name, 'Pitch');
      final rev = await RevFile.db.findFirstRow(
        anna.session,
        where: (t) => t.fileUuid.equals(file),
      );
      expect(rev?.kind, RevFileKind.deck);
      expect(rev?.headRevision, 0);
    });

    test('when registering twice then the same item is returned', () async {
      final first = await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Pitch',
      );

      final again = await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Pitch again',
      );

      expect(again.uuid, first.uuid);
      expect(again.name, 'Pitch');
    });

    test(
      'when registering into a folder then its mask has presentations',
      () async {
        final folder = await TestDrive.folder(endpoints, anna);

        await endpoints.drive.registerPresentation(
          anna.endpointSession,
          file,
          folder.uuid,
          'Pitch',
        );

        final row = await TestFiles.row(anna.session, folder.uuid);
        expect(KindMasks.has(row.kindMask, DriveItemKind.presentation), isTrue);
      },
    );

    test('when the folder is gone then the deck lands in My Drive', () async {
      final item = await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        const Uuid().v7obj(),
        'Pitch',
      );

      expect(item.parentUuid, isNull);
    });

    test(
      'when the id belongs to a spreadsheet then it is a conflict',
      () async {
        final sheet = await endpoints.drive.createSpreadsheet(
          anna.endpointSession,
          null,
          'Sheet',
          null,
        );

        await expectLater(
          endpoints.drive.registerPresentation(
            anna.endpointSession,
            sheet.uuid,
            null,
            'Pitch',
          ),
          _wonky(WonkyErrorCode.conflict),
        );
      },
    );

    test('when someone else registers the file then it is refused', () async {
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Pitch',
      );

      await expectLater(
        endpoints.drive.registerPresentation(
          bo.endpointSession,
          file,
          null,
          'Pitch',
        ),
        _wonky(WonkyErrorCode.forbidden),
      );
    });

    test('when the deck is listed then it shows as a presentation', () async {
      await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Pitch',
      );

      final page = await endpoints.drive.list(
        anna.endpointSession,
        null,
        DriveListFilter(kinds: [DriveItemKind.presentation]),
        DriveSort(),
        null,
        10,
      );

      expect(page.items.map((i) => i.uuid), [file]);
    });
  });
}
