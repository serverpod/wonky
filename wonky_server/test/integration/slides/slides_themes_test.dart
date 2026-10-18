@Tags(['integration'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/slides/headless/headless_deck.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_sync_models/ids.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// `slidesThemes.list` (Slides 05 §9 *Import theme from a presentation*,
/// SL-17): the themes of a deck the caller can view, as theme entries the
/// client copies with `ImportTheme.themeEntry`.
void main() {
  withWonkyServerpod('Given a presentation with two themes', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser ben;
    late DriveItemView item;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
      item = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Garden',
        null,
      );
      final deck = await const SlidesHeadlessProvider().open(
        HeadlessDeckContext(anna.session, anna.actor),
        item.uuid.uuid,
      );
      final first = deck.model.slides.single.id;
      await deck.write(AddSlides(afterSlideId: first));
      final w = await deck.write(const ImportTheme(builtInKey: 'botanical'));
      final botanical = w.plan.result['themeId']! as String;
      await deck.write(ApplyThemeToSlides(botanical, [first]));
    });

    tearDown(HeadlessFileCache.clear);

    test('when a viewer lists its themes then every theme comes with its '
        'masters, layouts, elements and usage, and the entries import into '
        'another deck', () async {
      await TestDrive.share(endpoints, item, anna, ben, AccessRole.viewer);
      final json = await endpoints.slidesThemes.list(
        ben.endpointSession,
        item.uuid,
      );
      final r = jsonDecode(json) as Map<String, Object?>;

      expect(r['sourceItemUuid'], item.uuid.uuid);
      final themes = (r['themes']! as List).cast<Map<String, Object?>>();
      expect([for (final t in themes) t['name']], ['Wonky', 'Botanical']);
      expect([for (final t in themes) t['usedBy']], [1, 1]);
      expect(r['defaultThemeId'], themes.first['id']);
      for (final t in themes) {
        expect(t['masters'], hasLength(1));
        expect(t['layouts'], hasLength(16));
        expect(t['elements'], isNotEmpty);
      }

      // The client side: copy the Botanical entry into another deck.
      final other = MemoryDeck(
        model: (DeckBuilder()..slide(title: 'x')).build(),
        userId: testUserId,
        planner: const SlidesPlanner(),
      );
      final source = SlidesIds.deckThemeSourceKey(
        item.uuid.uuid,
        themes[1]['id']! as String,
      );
      final plan = other.execute(
        ImportTheme(themeEntry: themes[1], sourceKey: source),
      );
      final copy = other.model.theme(plan.result['themeId']! as String)!;
      expect(copy.name, 'Botanical');
      expect(other.model.indexes.themes.layoutsOfTheme(copy.id), hasLength(16));
    });

    test(
      'when someone without access lists its themes then it is refused',
      () async {
        await expectLater(
          endpoints.slidesThemes.list(ben.endpointSession, item.uuid),
          throwsA(isA<WonkyException>()),
        );
      },
    );
  });
}
