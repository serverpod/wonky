@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/slides/revlog/slides_revlog.dart';
import 'package:wonky_server/src/slides/templates/slides_template_decks.dart';
import 'package:wonky_slides_core/maintenance.dart';
import 'package:wonky_slides_core/templates.dart';

import '../../support/slides_rev_device.dart';
import '../../support/slides_rev_hooks.dart';
import '../../support/test_storage.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Built-in presentation templates (Slides 04 §15, 12 §4 SL-22): the
/// gallery lists them, `drive.createPresentation(templateUuid)` builds
/// their decks on the server (the creation op of a RevLog file) and devices
/// load them like any deck.
void main() {
  withWonkyServerpod('Given the built-in presentation templates', (
    sessionBuilder,
    endpoints,
  ) {
    late Session server;

    SlidesRevHooks.install();
    setUpAll(() {
      server = sessionBuilder.build();
    });

    tearDown(HeadlessFileCache.clear);

    test('when listing presentation templates, then the five built-ins come '
        'with the core uuids, card styles, preview text and sizes', () async {
      final user = await TestUsers.create(sessionBuilder);

      final list = await endpoints.drive.listTemplates(
        user.endpointSession,
        DriveItemKind.presentation,
      );

      final builtins = [
        for (final t in list)
          if (t.builtin) t,
      ];
      expect(
        [for (final t in builtins) t.key],
        [for (final t in SlidesTemplates.all) t.key],
      );
      for (final (i, view) in builtins.indexed) {
        final t = SlidesTemplates.all[i];
        expect(view.uuid.uuid, t.uuid, reason: 'server uuid ≡ core uuid');
        expect(BuiltinTemplates.byUuid(view.uuid)!.slides, same(t));
        expect(view.kind, DriveItemKind.presentation);
        expect(view.name, t.name);
        expect(view.category.name, t.category);
        expect(view.themeKey, t.themeKey);
        expect(view.previewText, startsWith('# '));
        expect(view.previewStyle, isNotNull);
        expect(view.previewStyle!.paper, matches(RegExp(r'^#[0-9a-f]{6}$')));
        expect(view.sizeBytes, greaterThan(10000));
      }
      final documents = await endpoints.drive.listTemplates(
        user.endpointSession,
        DriveItemKind.document,
      );
      expect(
        documents.where((t) => t.kind == DriveItemKind.presentation),
        isEmpty,
      );
    });

    for (final t in SlidesTemplates.all) {
      test('when creating a presentation from ${t.key}, then the deck has '
          'the template\'s slides, groups and theme, is searchable and '
          'passes maintenance', () async {
        final user = await TestUsers.create(sessionBuilder);

        final item = await endpoints.drive.createPresentation(
          user.endpointSession,
          null,
          'From ${t.name}',
          UuidValue.fromString(t.uuid),
        );

        expect(item.kind, DriveItemKind.presentation);
        expect(item.name, 'From ${t.name}');
        final db = server;
        final deck = await Deck.db.findById(db, item.uuid);
        expect(deck!.title, 'From ${t.name}');
        expect(deck.createdBy, user.authUserId);
        final preview = SlidesTemplateDecks.preview(t).model;
        final slides = await Slide.db.count(
          db,
          where: (s) => s.deckId.equals(item.uuid),
        );
        expect(slides, preview.slides.length);
        final groups = await SlideGroup.db.count(
          db,
          where: (g) => g.deckId.equals(item.uuid),
        );
        expect(groups, preview.groups.length);
        final themes = await DeckTheme.db.find(
          db,
          where: (x) => x.deckId.equals(item.uuid),
        );
        expect(themes.single.sourceKey, startsWith('builtin:${t.themeKey}@'));
        final file = await RevFile.db.findFirstRow(
          db,
          where: (f) => f.fileUuid.equals(item.uuid),
        );
        final ops = await RevOp.db.find(
          db,
          where: (o) => o.fileId.equals(file!.id!),
          orderBy: (o) => o.revision,
        );
        expect(ops.first.label, 'Create presentation');
        expect(file!.initPending, isFalse);
        await SlidesRevHooks.drain(server, item.uuid);
        final fresh = await DriveItem.db.findFirstRow(
          server,
          where: (d) => d.uuid.equals(item.uuid),
        );
        expect(fresh!.sizeBytes, greaterThan(0));
        // Search text: the title slide's title.
        final title = SlidesTemplateDecks.previewText(
          t,
        ).split('\n').first.substring(2);
        expect(fresh.searchText, contains(title));
        final headless = await SlidesRevlog.model(server, item.uuid);
        expect(DeckMaintenance.detect(headless), isEmpty);
        expect(
          headless.slides.length,
          preview.slides.length,
          reason: 'every row was written',
        );
      });
    }

    test('when the owner opens a template deck on a device, then the whole '
        'deck is in the replica (available offline)', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final t = SlidesTemplates.byKey('slides.workshop')!;
      final item = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Workshop',
        UuidValue.fromString(t.uuid),
      );

      final a = await SlidesRevDevice.open(anna, item.uuid);
      addTearDown(a.close);
      expect(a.role, AccessRole.owner);

      final preview = SlidesTemplateDecks.preview(t).model;
      expect(a.model.count('slide'), preview.slides.length);
      expect(a.model.count('slide_group'), preview.groups.length);
      expect(a.model.count('code_state'), 2, reason: 'two code slides');
      expect(a.model.count('slide_table_cell'), greaterThan(10));
      expect(a.title, 'Workshop');
    });

    test('when the quota is too small, then nothing is created; templates of '
        'other kinds are refused', () async {
      final user = await TestUsers.create(sessionBuilder);
      final pitch = UuidValue.fromString(
        SlidesTemplates.byKey('slides.pitch-deck')!.uuid,
      );
      await TestStorage.setQuota(user, 1000);

      await expectLater(
        endpoints.drive.createPresentation(
          user.endpointSession,
          null,
          'Too big',
          pitch,
        ),
        throwsA(isA<WonkyException>()),
      );
      expect(
        await DriveItem.db.count(
          server,
          where: (d) => d.ownerId.equals(user.id),
        ),
        0,
      );

      await TestStorage.setQuota(user, 50 * 1024 * 1024);
      final notes = BuiltinTemplates.byKey('write.meeting-notes');
      await expectLater(
        endpoints.drive.createPresentation(
          user.endpointSession,
          null,
          'Nope',
          notes.uuid,
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.invalidArgument,
          ),
        ),
      );
      await expectLater(
        endpoints.drive.createDocument(
          user.endpointSession,
          null,
          'Nope',
          pitch,
          null,
        ),
        throwsA(isA<WonkyException>()),
      );
    });
  });
}
