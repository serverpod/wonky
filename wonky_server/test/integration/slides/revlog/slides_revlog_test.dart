@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/slides/revlog/slides_hooks.dart';
import 'package:wonky_server/src/slides/revlog/slides_revlog.dart';
import 'package:wonky_slides_core/model.dart' show SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesCols, SlidesTables;

import '../../../support/slides_rev_device.dart';
import '../../../support/slides_rev_hooks.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

String _text(String s) => '[{"insert":"$s\\n"}]';

/// Decks on RevLog end to end (RevLog spec 08, 09 §3): creation through
/// the drive (server-written and `initialize: false`), collaborating
/// devices, the element owner check, the headless deck, hooks (title,
/// search text, activity), access and purge.
void main() {
  withWonkyServerpod('Given a deck', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestUser ben;
    final devices = <SlidesRevDevice>[];

    SlidesRevHooks.install();
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
    });
    tearDown(() async {
      for (final d in devices) {
        await d.close();
      }
      devices.clear();
    });

    Future<SlidesRevDevice> device(TestUser u, UuidValue file) async {
      final d = await SlidesRevDevice.open(u, file);
      devices.add(d);
      return d;
    }

    Future<DriveItemView> created([String name = 'Pitch']) =>
        endpoints.drive.createPresentation(
          anna.endpointSession,
          null,
          name,
          null,
        );

    test('when created on the server then a device loads it at revision 1 '
        'with the default theme and a title slide', () async {
      final item = await created();
      expect(item.uuid, item.contentRef, reason: 'item uuid = file uuid');
      final a = await device(anna, item.contentRef!);
      expect(a.revision, 1);
      expect(a.title, 'Pitch');
      expect(a.model.slides, hasLength(1));
      expect(a.model.count(SlidesTables.deckTheme), 1);
      expect(
        a.model.count(SlidesTables.slideLayout),
        greaterThanOrEqualTo(16),
      );
    });

    test('when a device registers a deck it created offline then the file '
        'waits at revision 0 and its creation op is revision 1', () async {
      final file = UuidValue.fromString(const Uuid().v7());
      final item = await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Offline deck',
      );
      expect(item.uuid, file);
      // Idempotent (a queued retry).
      final again = await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Offline deck',
      );
      expect(again.uuid, file);
      final a = await device(anna, file);
      expect(a.revision, 0);
      expect(a.model.deck, isNull);

      final ack = await a.createDeck('Offline deck');
      expect(ack.revision, 1);
      expect(a.title, 'Offline deck');

      await TestDrive.share(endpoints, item, anna, ben, AccessRole.editor);
      final b = await device(ben, file);
      expect(b.model.slides, hasLength(1));
      expect(b.title, 'Offline deck');
    });

    test('when the drive item was renamed before the creation op arrived '
        'then the op takes the drive name (04 §5)', () async {
      final file = UuidValue.fromString(const Uuid().v7());
      await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Draft',
        null,
        fileUuid: file,
        initialize: false,
      );
      await endpoints.drive.rename(anna.endpointSession, file, 'Final');
      final a = await device(anna, file);
      final ack = await a.createDeck('Draft');
      expect(
        ack.applied ?? ack.appliedGz,
        isNotNull,
        reason: 'the applied form differs',
      );
      expect(a.title, 'Final');
    });

    test('when one device adds a slide and types then the other sees it and '
        'the headless deck follows', () async {
      final item = await created();
      await TestDrive.share(endpoints, item, anna, ben, AccessRole.editor);
      final a = await device(anna, item.contentRef!);
      final b = await device(ben, item.contentRef!);
      await a.execute(AddSlides(afterSlideId: a.model.slides.single.id));
      final slide = a.model.slides.last.id;
      final title = a.model
          .elementsOf(slide)
          .firstWhere((e) => e.placeholderType != null)
          .id;
      await a.execute(SetText(ElementText(title), _text('Roadmap')));

      await b.sync();
      expect(b.model.slides, hasLength(2));
      expect(
        SlidesText.plainText(b.model.element(title)?.text).trim(),
        'Roadmap',
      );
      final headless = await SlidesRevlog.model(
        sessionBuilder.build(),
        item.contentRef!,
      );
      expect(headless.slides, hasLength(2));
      expect(
        SlidesText.plainText(headless.element(title)?.text).trim(),
        'Roadmap',
      );
    });

    test('when an element names two owners or none then the op is '
        'rejected (08 §1)', () async {
      final item = await created();
      final a = await device(anna, item.contentRef!);
      final slide = a.model.slides.single;
      final layout = a.model.records(SlidesTables.slideLayout).first.id;
      final e = a.model.elementsOf(slide.id).first;
      Future<void> rejected(List<RowChange> changes) => expectLater(
        a.submit(changes),
        throwsA(
          isA<RevDeviceRejected>().having(
            (r) => r.rejected.code,
            'code',
            RevRejectCode.invalidChange,
          ),
        ),
      );
      await rejected([
        RowChange.update(
          SlidesTables.slideElement,
          e.id,
          {'layoutId': null},
          {'layoutId': layout},
        ),
      ]);
      final columns = {...e.toColumns()}
        ..remove(SlidesCols.id)
        ..[SlidesCols.slideId] = null;
      await rejected([
        RowChange.insert(
          SlidesTables.slideElement,
          const Uuid().v7(),
          {...columns, 'matchKey': 'abcdefghijklmnopqrstuv'},
        ),
      ]);
    });

    test('when a viewer submits then the op is refused', () async {
      final item = await created();
      await TestDrive.share(endpoints, item, anna, ben, AccessRole.viewer);
      final b = await device(ben, item.contentRef!);
      await expectLater(
        b.execute(AddSlides(afterSlideId: b.model.slides.single.id)),
        throwsA(
          isA<RevDeviceRejected>().having(
            (r) => r.rejected.code,
            'code',
            RevRejectCode.forbiddenForRole,
          ),
        ),
      );
    });

    test('when the drive item is renamed then the deck title follows, and a '
        'deck rename reaches the drive through the title hook', () async {
      final item = await created();
      await endpoints.drive.rename(anna.endpointSession, item.uuid, 'Plan');
      final a = await device(anna, item.contentRef!);
      expect(a.title, 'Plan');
      await a.rename('Forecast');
      await SlidesRevHooks.drain(sessionBuilder.build(), item.contentRef!);
      final fresh = await endpoints.drive.get(anna.endpointSession, item.uuid);
      expect(fresh.name, 'Forecast');
    });

    test('when hooks run then the search text and the activity reflect the '
        'edits', () async {
      final item = await created();
      final a = await device(anna, item.contentRef!);
      final slide = a.model.slides.single.id;
      final title = a.model
          .elementsOf(slide)
          .firstWhere((e) => e.placeholderType != null)
          .id;
      await a.execute(SetText(ElementText(title), _text('Quarterly numbers')));
      final session = sessionBuilder.build();
      await SlidesRevHooks.drain(session, item.contentRef!);

      expect(
        await DeckSearchText.ofFile(session, item.contentRef!),
        allOf(contains('Pitch'), contains('Quarterly numbers')),
      );
      final itemId = await _itemId(session, item.uuid);
      final events = await ActivityEvent.db.find(
        session,
        where: (t) =>
            t.itemId.equals(itemId) & t.type.equals(ActivityType.edited),
      );
      expect(events, isNotEmpty);
    });

    test('when it is deleted forever then its rows and log are gone', () async {
      final item = await created();
      final a = await device(anna, item.contentRef!);
      await a.execute(AddSlides(afterSlideId: a.model.slides.single.id));
      await a.close();
      devices.clear();
      final session = sessionBuilder.build();
      final fileRow = (await RevFile.db.findFirstRow(
        session,
        where: (t) => t.fileUuid.equals(item.contentRef!),
      ))!;
      await endpoints.drive.trash(anna.endpointSession, [item.uuid]);
      await endpoints.drive.deletePermanently(anna.endpointSession, [
        item.uuid,
      ]);
      expect(await RevFile.db.findById(session, fileRow.id!), isNull);
      expect(await Deck.db.findById(session, item.contentRef!), isNull);
      expect(
        await SlideElement.db.count(
          session,
          where: (t) => t.fileId.equals(fileRow.id!),
        ),
        0,
      );
    });
  });
}

Future<int> _itemId(Session session, UuidValue uuid) async =>
    (await DriveItem.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid),
    ))!.id!;
