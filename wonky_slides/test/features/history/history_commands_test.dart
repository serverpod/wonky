import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show
        ItemVersionView,
        RevertResult,
        UuidValue,
        VersionKind,
        VersionRestoreResult,
        VersionStorage;
import 'package:wonky_core/wonky_core.dart' show JsonSchema;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;
import 'package:wonky_slides/config/slides_features.dart';
import 'package:wonky_slides/features/history/conflict_review_dialog.dart';
import 'package:wonky_slides/features/history/local_conflicts.dart';
import 'package:wonky_slides/features/undo/server_change_undo.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

import '../../harness/deck_harness.dart';
import '../../support/slides_harness.dart';

const _bo = '00000000-0000-4000-8000-0000000000b0';
const _change = '01923456-789a-7bcd-8ef0-0000000000aa';

/// Version restores through the Slides commands (one `slides.serverChange`
/// undo step) and the overwritten-text review (Slides 09 §4.4, §6.3).
class _Versions implements VersionRepository {
  final restores = <int>[];

  ItemVersionView view(int id, UuidValue item) => ItemVersionView(
    id: id,
    itemUuid: item,
    kind: VersionKind.restorePoint,
    createdAt: DateTime.utc(2026, 10, 15),
    authors: const [],
    storageKind: VersionStorage.snapshotFile,
    sizeBytes: 0,
  );

  @override
  Future<VersionRestoreResult> restore(
    UuidValue itemUuid,
    int versionId,
  ) async {
    restores.add(versionId);
    return VersionRestoreResult(
      restorePoint: view(99, itemUuid),
      changeId: UuidValue.fromString(_change),
    );
  }

  @override
  Future<List<ItemVersionView>> list(
    UuidValue itemUuid, {
    bool namedOnly = false,
  }) async => const [];

  @override
  Future<ItemVersionView> nameCurrent(UuidValue itemUuid, String name) async =>
      view(5, itemUuid);

  @override
  Future<ItemVersionView> rename(
    UuidValue itemUuid,
    int versionId,
    String? name,
  ) async => view(versionId, itemUuid);
}

RevertResult _result(String id) => RevertResult(
  changeId: UuidValue.fromString(id),
  revertedCells: 1,
  skipped: const [],
);

void main() {
  setUp(() {
    SlidesFeatures.enabled = {
      ...SlidesFeatures.shipped,
      SlidesFeature.versionHistory,
    };
  });
  tearDown(SlidesFeatures.reset);

  group('Given a deck whose version is restored from Slides', () {
    test('when restoreVersion runs then the shell restores it and undo/redo '
        'revert and reapply it on the server as one step', () async {
      final versions = _Versions();
      final d = DeckHarness.open(versions: versions);
      addTearDown(d.dispose);
      d.services.currentItem.value = d.h.drive.item(
        UuidValue.fromString(d.fixture.deckId),
      );
      final calls = <String>[];
      d.services.undo.registerHandler(
        SlidesServerChangeHandler(
          d.services,
          revert: (id) async {
            calls.add('revert $id');
            return _result('01923456-789a-7bcd-8ef0-0000000000ab');
          },
          reapply: (id) async {
            calls.add('reapply $id');
            return _result('01923456-789a-7bcd-8ef0-0000000000ac');
          },
        ),
      );

      final r = await d.run('slides.history.restoreVersion', {
        'versionId': 4,
        'confirmed': true,
      });

      expect(r.isOk, isTrue, reason: '$r');
      expect(versions.restores, [4]);
      expect(d.undoLabels, hasLength(1));
      await d.undo();
      await d.redo();
      expect(calls, [
        'revert $_change',
        'reapply 01923456-789a-7bcd-8ef0-0000000000ab',
      ]);
    });

    test('when version history is off then no history command is '
        'registered', () async {
      SlidesFeatures.enabled = {...SlidesFeatures.shipped}
        ..remove(SlidesFeature.versionHistory);
      final d = DeckHarness.open();
      addTearDown(d.dispose);

      for (final id in [
        'slides.history.open',
        'slides.history.restoreVersion',
        'slides.conflicts.review',
        'shell.versions.restore',
      ]) {
        expect(d.services.registry.contains(id), isFalse, reason: id);
      }
    });
  });

  group('Given a text box edited offline', () {
    late DeckHarness d;
    late String box;
    late String slide;
    late SlidesConflicts c;
    late List<RevOpMeta> logs;
    var offline = true;

    setUp(() async {
      final b = DeckBuilder();
      slide = b.slide(title: 'One');
      box = b.textBox(slide, 'Draft');
      d = DeckHarness.open(fixture: b);
      offline = true;
      logs = [];
      c = SlidesConflicts.attach(
        d.editor,
        isOffline: () => offline,
        changeLogs: () async => logs,
        names: (u) => u == _bo ? 'Bo Stone' : null,
      );
      d.registerOp(
        'test.text',
        (a) => SetText(ElementText(box), deltaOf(a.requireString('t'))),
        argsSchema: const JsonSchema.object(
          properties: {'t': JsonSchema.string()},
        ),
      );
      await d.run('test.text', {'t': 'Mine'});
    });
    tearDown(() async {
      c.dispose();
      await d.dispose();
    });

    String text() => SlidesText.plainText(d.model.element(box)!.text).trim();

    void remote(String t) {
      d.model.applyChanges([
        RowChange.update(
          SlidesTables.slideElement,
          box,
          {SlidesCols.text: d.model.element(box)!.text},
          {SlidesCols.text: deltaOf(t)},
        ),
      ], origin: DeckChangeOrigin.remote);
      logs.add(
        RevOpMeta(
          revision: logs.length + 1,
          authorUuid: _bo,
          actorKind: 'user',
          sessionId: 'bo',
          label: 'Typing',
          summary: {
            'v': 1,
            'kinds': ['text'],
            'slides': [slide],
            'elements': [box],
          },
          committedAt: clock.now().toUtc(),
        ),
      );
    }

    test('when Bo overwrote it then the check records a conflict named '
        'after Bo and Restore mine writes it back as one undo step', () async {
      expect(c.trackedBodies, 1);
      remote('Theirs');
      offline = false;

      final found = await c.check();

      expect(found, hasLength(1));
      expect(found.single.theirName, 'Bo Stone');
      expect(SlidesText.plainText(found.single.myText).trim(), 'Mine');
      expect(c.open, hasLength(1));
      final r = await d.run('slides.conflicts.restoreMine', {
        'conflictIds': [found.single.id],
      });
      expect(r.isOk, isTrue, reason: '$r');
      expect(text(), 'Mine');
      expect(c.open, isEmpty);
      await d.undo();
      expect(text(), 'Theirs');
    });

    test(
      'when the merged text is still mine then there is no conflict',
      () async {
        offline = false;
        expect(await c.check(), isEmpty);
        expect(c.trackedBodies, 0);
      },
    );

    test('when the box was deleted by Bo then the conflict says so and '
        'cannot be restored', () async {
      d.model.applyChanges([
        RowChange.delete(
          SlidesTables.slideElement,
          box,
          d.model.element(box)!.toColumns(),
        ),
      ], origin: DeckChangeOrigin.remote);
      logs.add(
        RevOpMeta(
          revision: logs.length + 1,
          authorUuid: _bo,
          actorKind: 'user',
          sessionId: 'bo',
          label: 'Delete',
          summary: {
            'v': 1,
            'deleted': {
              'elements': [box],
            },
          },
          committedAt: clock.now().toUtc(),
        ),
      );
      offline = false;

      final found = await c.check();

      expect(found.single.deleted, isTrue);
      expect(found.single.canRestore, isFalse);
    });

    test('when an online edit follows then the offline edit is no longer '
        'tracked', () async {
      offline = false;
      await d.run('test.text', {'t': 'Online'});
      expect(c.trackedBodies, 0);
    });

    test('when the conflicts are dismissed then none is open and the review '
        'is disabled', () async {
      remote('Theirs');
      offline = false;
      await c.check();

      await c.dismiss();

      expect(c.open, isEmpty);
      expect(
        d.services.dispatcher.stateOf('slides.conflicts.review').enabled,
        isFalse,
      );
    });

    for (final brightness in Brightness.values) {
      for (final width in [1200.0, 360.0]) {
        testWidgets('when the review dialog shows (${brightness.name}, '
            '${width.toInt()} px) then the replaced text is checkable and '
            'Restore returns it', (tester) async {
          remote('Theirs');
          offline = false;
          final found = (await tester.runAsync(c.check))!;
          ConflictReviewChoice? choice;
          await pumpSlides(
            tester,
            d.h,
            Builder(
              builder: (context) => Center(
                child: GestureDetector(
                  key: const ValueKey('open'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () async => choice = await showConflictReviewDialog(
                    context,
                    editor: d.editor,
                    conflicts: found,
                  ),
                  child: const SizedBox(width: 40, height: 40),
                ),
              ),
            ),
            brightness: brightness,
            size: Size(width, 800),
          );
          await tester.tap(find.byKey(const ValueKey('open')));
          await tester.pumpAndSettle();

          expect(
            find.textContaining('yours: Mine · now: Theirs (Bo Stone)'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Restore'));
          await tester.pumpAndSettle();
          expect(choice?.action, 'restore');
          expect(choice?.ids, [found.single.id]);
        });
      }
    }
  });
}
