@Tags(['integration'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/isolate_runner.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/slides/exports/slides_export_service.dart';
import 'package:wonky_server/src/slides/headless/headless_deck.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_slides_core/ops.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Future<Uint8List> _bytesOf(Session session, ExportResultView r) async {
  final files = await StoredFile.db.find(
    session,
    where: (t) => t.kind.equals(StoredFileKind.exportResult),
  );
  files.sort((a, b) => a.id!.compareTo(b.id!));
  final data = await FileService.readBytes(session, files.last);
  expect(data.lengthInBytes, r.sizeBytes);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

int _pages(Uint8List pdf) => RegExp(
  r'/Type\s*/Page(?![a-zA-Z])',
).allMatches(latin1.decode(pdf)).length;

/// `slidesExport` (Slides 10 §11.4–§11.5, 12 §4 SL-20).
void main() {
  withWonkyServerpod('Given a presentation on the server', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView item;

    setUp(() async {
      SlidesExportService.clearCache();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Q3 Review',
        null,
      );
      final deck = await const SlidesHeadlessProvider().open(
        HeadlessDeckContext(anna.session, anna.actor),
        item.uuid.uuid,
      );
      final first = deck.model.slides.single.id;
      await deck.write(AddSlides(afterSlideId: first, count: 3));
      final slides = deck.model.slides.map((s) => s.id).toList();
      await deck.write(CreateGroup([slides[1], slides[2]], title: 'Intro'));
      await deck.write(SetSlideProps([slides[3]], skipped: true));
    });

    tearDown(HeadlessFileCache.clear);

    test('when exporting a PDF then the stored result has one page per '
        'non-skipped slide, the deck title and an activity entry', () async {
      final r = await endpoints.slidesExport.export(
        anna.endpointSession,
        item.uuid,
        'pdf',
        '{}',
        null,
      );

      expect(r.fileName, 'Q3 Review.pdf');
      expect(r.mimeType, 'application/pdf');
      expect(r.pageCount, 3);
      expect(r.downloadUrl, isNotEmpty);
      final bytes = await _bytesOf(anna.session, r);
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      final files = await StoredFile.db.find(
        anna.session,
        where: (t) => t.kind.equals(StoredFileKind.exportResult),
      );
      expect(files.last.expiresAt, isNotNull);
      final activity = await ActivityEvent.db.find(
        anna.session,
        where: (t) => t.type.equals(ActivityType.exported),
      );
      expect(activity, isNotEmpty);
    });

    test('when exporting with skipped slides and the notes layout then every '
        'slide is a page', () async {
      final r = await endpoints.slidesExport.export(
        anna.endpointSession,
        item.uuid,
        'pdf',
        jsonEncode({
          'layout': 'notes',
          'includeSkipped': true,
          'fileName': 'Speaker notes',
        }),
        null,
      );

      expect(r.pageCount, 4);
      expect(r.fileName, 'Speaker notes.pdf');
      expect(_pages(await _bytesOf(anna.session, r)), greaterThanOrEqualTo(4));
    });

    test('when the same export is requested twice then the stored result is '
        'reused', () async {
      Future<int> stored() async => (await StoredFile.db.find(
        anna.session,
        where: (t) => t.kind.equals(StoredFileKind.exportResult),
      )).length;
      final a = await endpoints.slidesExport.export(
        anna.endpointSession,
        item.uuid,
        'pdf',
        '{"layout":"handouts","handoutsPerPage":6}',
        null,
      );
      final before = await stored();
      final b = await endpoints.slidesExport.export(
        anna.endpointSession,
        item.uuid,
        'pdf',
        '{"layout":"handouts","handoutsPerPage":6}',
        null,
      );

      expect(a.pageCount, 1);
      expect(await stored(), before);
      expect(b.sizeBytes, a.sizeBytes);
    });

    test('when the deck changes between two equal requests then the second '
        'renders the new revision', () async {
      final a = await endpoints.slidesExport.export(
        anna.endpointSession,
        item.uuid,
        'pdf',
        '{}',
        null,
      );
      final deck = await const SlidesHeadlessProvider().open(
        HeadlessDeckContext(anna.session, anna.actor),
        item.uuid.uuid,
      );
      await deck.write(
        AddSlides(afterSlideId: deck.model.slides.first.id, count: 1),
      );

      final b = await endpoints.slidesExport.export(
        anna.endpointSession,
        item.uuid,
        'pdf',
        '{}',
        null,
      );

      expect(a.pageCount, 3);
      expect(b.pageCount, 4);
    });

    test('when an export is cancelled before it starts then it fails as '
        'cancelled and frees its slot', () async {
      final cancel = IsolateCancelToken()..cancel();

      await expectLater(
        SlidesExportService.export(
          anna.session,
          anna.actor,
          item.uuid,
          'pdf',
          '{}',
          cancel: cancel,
        ),
        throwsA(
          isA<WonkyException>()
              .having((e) => e.code, 'code', WonkyErrorCode.unavailable)
              .having((e) => e.message, 'message', contains('cancelled')),
        ),
      );
      final r = await endpoints.slidesExport.export(
        anna.endpointSession,
        item.uuid,
        'pdf',
        '{}',
        null,
      );
      expect(r.pageCount, 3);
      expect(IsolateRunner.running, 0);
    });

    test(
      'when exporting with the progress API then it ends with done',
      () async {
        final events = await endpoints.slidesExport
            .exportWithProgress(
              anna.endpointSession,
              item.uuid,
              'pdf',
              '{}',
              null,
            )
            .toList();

        expect(events.last.kind, ExportProgressKind.done);
        expect(events.last.result!.pageCount, 3);
        expect(
          events.where((e) => e.kind == ExportProgressKind.phase),
          isNotEmpty,
        );
      },
    );

    test('when the format is PNG then it is not available yet', () async {
      await expectLater(
        endpoints.slidesExport.export(
          anna.endpointSession,
          item.uuid,
          'png',
          '{}',
          null,
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.unavailable,
          ),
        ),
      );
    });

    test('when a stranger exports then the deck is not found', () async {
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');

      await expectLater(
        endpoints.slidesExport.export(
          eve.endpointSession,
          item.uuid,
          'pdf',
          '{}',
          null,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when a viewer exports then it works, unless downloads are disabled',
      () async {
        final ben = await TestUsers.create(sessionBuilder, name: 'Ben');
        await TestDrive.share(endpoints, item, anna, ben, AccessRole.viewer);

        final r = await endpoints.slidesExport.export(
          ben.endpointSession,
          item.uuid,
          'pdf',
          '{}',
          null,
        );
        expect(r.pageCount, 3);

        await endpoints.sharing.updateSettings(
          anna.endpointSession,
          item.uuid,
          ItemSharingSettings(
            editorsCanShare: true,
            nonEditorsCanExport: false,
            viewersSeeComments: false,
          ),
        );
        SlidesExportService.clearCache();
        await expectLater(
          endpoints.slidesExport.export(
            ben.endpointSession,
            item.uuid,
            'pdf',
            '{}',
            null,
          ),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.forbidden,
            ),
          ),
        );
      },
    );

    test('when signed out then the export is refused', () async {
      await expectLater(
        endpoints.slidesExport.export(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.unauthenticated(),
          ),
          item.uuid,
          'pdf',
          '{}',
          null,
        ),
        throwsA(anything),
      );
    });
  });
}
