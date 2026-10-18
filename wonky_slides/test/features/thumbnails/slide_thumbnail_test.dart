import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/thumbnails/slide_thumbnail.dart';
import 'package:wonky_slides/features/thumbnails/slide_thumbnail_cache.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart' show deltaOf;

import '../stage/stage_fixture.dart';

void main() {
  group('Given a renderer with thumbnails', () {
    testWidgets('when asking twice for an unchanged slide then the picture is '
        'recorded once', (tester) async {
      final f = StageFixture();
      f.shape(text: 'Thumb');
      final r = f.renderer();
      addTearDown(r.dispose);

      final a = r.thumbnail(f.slideId, width: 240);
      final b = r.thumbnail(f.slideId, width: 240);

      expect(identical(a, b), isTrue);
      expect(r.thumbnails.debugRecords, 1);
      expect(a!.size, const Size(240, 135));
    });

    testWidgets('when the slide changes then a new picture is recorded '
        '(cached by revision)', (tester) async {
      final f = StageFixture();
      final id = f.shape();
      final r = f.renderer();
      addTearDown(r.dispose);

      final a = r.thumbnail(f.slideId, width: 240);
      f.moveElement(id, 900);
      final b = r.thumbnail(f.slideId, width: 240);

      expect(identical(a, b), isFalse);
      expect(r.thumbnails.debugRecords, 2);
    });

    testWidgets('when a slide changes repeatedly then its entry is replaced '
        'in place and the old picture is disposed after the frame', (
      tester,
    ) async {
      final f = StageFixture();
      final id = f.shape();
      final r = f.renderer();
      addTearDown(r.dispose);

      final a = r.thumbnail(f.slideId, width: 240)!;
      for (var i = 0; i < 5; i++) {
        f.moveElement(id, 100.0 + i);
        r.thumbnail(f.slideId, width: 240);
      }

      expect(r.thumbnails.length, 1);
      expect(a.disposed, isFalse, reason: 'painters may still draw it');
      await tester.pump();
      expect(a.disposed, isTrue);
    });

    testWidgets('when speaker notes are typed or the deck is renamed then no '
        'thumbnail is recorded again', (tester) async {
      final f = StageFixture();
      f.shape(text: 'Thumb');
      final r = f.renderer();
      addTearDown(r.dispose);
      final a = r.thumbnail(f.slideId, width: 240);

      f.model.applyChanges([
        RowChange.update(
          SlidesTables.slide,
          f.slideId,
          {SlideCols.notes: null},
          {SlideCols.notes: deltaOf('Notes')},
        ),
        RowChange.update(
          SlidesTables.deck,
          f.model.deck!.id,
          {DeckCols.title: f.model.deck!.title},
          {DeckCols.title: 'Renamed'},
        ),
      ]);

      expect(identical(r.thumbnail(f.slideId, width: 240), a), isTrue);
      expect(r.thumbnails.debugRecords, 1);
    });

    testWidgets('when a slide has an undecoded image then the thumbnail is '
        'incomplete and recorded again once the image decoded', (tester) async {
      final f = StageFixture();
      f.image();
      final r = f.renderer();
      addTearDown(r.dispose);

      final a = r.thumbnail(f.slideId, width: 240)!;
      await tester.runAsync(() => r.images.preload(r.scene(f.slideId)!));
      final b = r.thumbnail(f.slideId, width: 240)!;
      final c = r.thumbnail(f.slideId, width: 240)!;

      expect(a.complete, isFalse);
      expect(b.complete, isTrue);
      expect(identical(b, c), isTrue);
      expect(r.thumbnails.debugRecords, 2);
    });

    testWidgets('when the slide does not exist then there is no thumbnail', (
      tester,
    ) async {
      final f = StageFixture();
      final r = f.renderer();
      addTearDown(r.dispose);

      expect(
        r.thumbnail('00000000-0000-7000-8000-000000000000', width: 240),
        isNull,
      );
    });

    testWidgets('when the widget is shown then it has the slide aspect and '
        'paints the picture', (tester) async {
      final f = StageFixture();
      f.shape();
      final r = f.renderer();
      addTearDown(r.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SlideThumbnail(
              renderer: r,
              slideId: f.slideId,
              width: 200,
              semanticLabel: 'Slide 1',
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(SlideThumbnail)),
        const Size(200, 112.5),
      );
      expect(find.bySemanticsLabel('Slide 1'), findsOneWidget);
      expect(r.thumbnails.length, 1);
    });
  });

  group('Given a thumbnail cache', () {
    testWidgets('when more entries than the capacity are recorded then the '
        'least recently used ones are dropped', (tester) async {
      final f = StageFixture();
      final r = f.renderer();
      addTearDown(r.dispose);
      final cache = SlideThumbnailCache(capacity: 2);
      final scene = r.scene(f.slideId)!;

      cache.picture('a', () => scene, width: 100);
      cache.picture('b', () => scene, width: 100);
      cache.picture('a', () => scene, width: 100); // touch a
      cache.picture('c', () => scene, width: 100);

      expect(cache.lookup('a'), isNotNull);
      expect(cache.lookup('b'), isNull);
      expect(cache.lookup('c'), isNotNull);
      expect(cache.debugRecords, 3);
    });

    testWidgets('when invalidating a slide then its entries are dropped', (
      tester,
    ) async {
      final f = StageFixture();
      final r = f.renderer();
      addTearDown(r.dispose);
      final cache = SlideThumbnailCache();
      final scene = r.scene(f.slideId)!;
      cache.picture('s1|1', () => scene, width: 100);
      cache.picture('s2|1', () => scene, width: 100);

      cache.invalidate('s1');

      expect(cache.lookup('s1|1'), isNull);
      expect(cache.lookup('s2|1'), isNotNull);
    });
  });
}
