import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart'
    show VersionHistoryScreen, VersionRepository;
import 'package:wonky_client/wonky_client.dart'
    show
        DriveItemKind,
        ItemVersionView,
        UuidValue,
        VersionKind,
        VersionRestoreResult,
        VersionStorage;
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_slides/config/slides_app_config.dart';
import 'package:wonky_slides/config/slides_features.dart';
import 'package:wonky_slides/features/history/slides_version_renderer.dart';
import 'package:wonky_slides/features/history/slides_version_view.dart';
import 'package:wonky_slides/features/history/version_copy.dart';
import 'package:wonky_slides/features/history/version_snapshots.dart';
import 'package:wonky_slides/features/undo/server_change_undo.dart';
import 'package:wonky_slides_core/history.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

import '../../support/slides_harness.dart';

class _List implements VersionRepository {
  _List(this.versions);

  final List<ItemVersionView> versions;

  @override
  Future<List<ItemVersionView>> list(
    UuidValue itemUuid, {
    bool namedOnly = false,
  }) async => versions;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

ItemVersionView _version(int id, String deck) => ItemVersionView(
  id: id,
  itemUuid: UuidValue.fromString(deck),
  kind: VersionKind.auto,
  createdAt: DateTime.utc(2026, 10, id),
  authors: [TestUsers.anna, TestUsers.bob],
  storageKind: VersionStorage.snapshotFile,
  sizeBytes: 100,
);

void main() {
  late DeckBuilder b;
  late String s1, s2, s3, gone, box;
  late List<int> v1, v2;

  setUp(() {
    SlidesFeatures.enabled = {
      ...SlidesFeatures.shipped,
      SlidesFeature.versionHistory,
    };
    b = DeckBuilder();
    s1 = b.slide(title: 'Intro');
    s2 = b.slide(title: 'Numbers');
    box = b.textBox(s2, 'Revenue up');
    gone = b.slide(title: 'Old ideas');
    final m = b.build();
    v1 = SlidesSnapshotCodec.encodeModel(
      m,
      capturedAt: DateTime.utc(2026, 10, 1),
    );
    // Version 2: Bo edits the box, Anna adds a slide and deletes one.
    final s3Row = {
      ...m.slide(s1)!.toColumns(),
      SlidesCols.id: '01923456-789a-7bcd-8ef0-0000000000f3',
      SlidesCols.sortKey: 'zz',
    };
    s3 = s3Row[SlidesCols.id]! as String;
    m.applyChanges([
      RowChange.update(
        SlidesTables.slideElement,
        box,
        {SlidesCols.text: m.element(box)!.text},
        {SlidesCols.text: deltaOf('Revenue down')},
      ),
      RowChange.insert(SlidesTables.slide, s3, s3Row),
      for (final e in m.allElementsOf(gone).toList())
        RowChange.delete(SlidesTables.slideElement, e.id, e.toColumns()),
      RowChange.delete(SlidesTables.slide, gone, m.slide(gone)!.toColumns()),
    ]);
    v2 = SlidesSnapshotCodec.encodeModel(
      m,
      capturedAt: DateTime.utc(2026, 10, 2),
    );
    SlidesVersionSnapshots.clear();
    SlidesVersionSnapshots.fetch = (item, id) async => id == 1 ? v1 : v2;
    SlidesVersionView.fetchChanges = (item, id) async => jsonEncode({
      'v': 1,
      'slides': {
        s2: [TestUsers.bob.id],
        s3: [TestUsers.anna.id],
      },
      'elements': {
        box: [TestUsers.bob.id],
      },
      'agents': {
        '${TestUsers.bob.id}': ['mcp'],
      },
    });
    addTearDown(() {
      SlidesVersionSnapshots.fetch = null;
      SlidesVersionSnapshots.clear();
      SlidesVersionView.fetchChanges = null;
      SlidesVersionView.showRemoved.value = true;
      VersionHistoryScreen.showChanges.value = true;
      copySlidesVersionOverride = null;
      SlidesFeatures.reset();
    });
  });

  Future<(CommandTestHarness, SlidesVersionViewState)> show(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1400, 900),
    bool showChanges = true,
  }) async {
    final h = slidesHarness();
    await pumpSlides(
      tester,
      h,
      SlidesVersionView(
        services: h.services,
        itemUuid: UuidValue.fromString(b.deckId),
        version: _version(2, b.deckId),
        previous: _version(1, b.deckId),
        showChanges: showChanges,
      ),
      brightness: brightness,
      size: size,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump();
    return (
      h,
      tester.state<SlidesVersionViewState>(find.byType(SlidesVersionView)),
    );
  }

  Future<void> close(WidgetTester tester, CommandTestHarness h) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await h.dispose();
  }

  for (final brightness in Brightness.values) {
    testWidgets('when a version is shown (${brightness.name}) then the '
        'summary, the navigator badges and the deleted slide show', (
      tester,
    ) async {
      final (h, st) = await show(tester, brightness: brightness);

      expect(st.diff, isNotNull);
      expect(
        find.text('1 slide added · 1 slide changed · 1 slide deleted'),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('slides.version.slide.$s1')), findsOneWidget);
      expect(find.byKey(ValueKey('slides.version.dot.$s2')), findsOneWidget);
      expect(
        find.byKey(ValueKey('slides.version.removed.$gone')),
        findsOneWidget,
      );
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Deleted'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester, h);
    });
  }

  testWidgets('when slide 2 is selected then its change lists the text edit '
      'by the agent author with an inline text diff', (tester) async {
    final (h, st) = await show(tester);

    await tester.tap(find.byKey(ValueKey('slides.version.slide.$s2')));
    await tester.pump();

    expect(st.slideId, s2);
    expect(
      find.text('Text box: text edited — Claude via MCP (Bob Stone)'),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey('slides.version.change.$box')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('updown'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ValueKey('slides.version.change.$box')));
    await tester.pump();
    expect(st.activeElementId, box);
    await close(tester, h);
  });

  testWidgets('when the deleted slide is selected then the previous '
      "version's slide shows", (tester) async {
    final (h, st) = await show(tester);

    await tester.tap(find.byKey(ValueKey('slides.version.removed.$gone')));
    await tester.pump();

    expect(st.slideId, gone);
    expect(st.showingRemoved, isTrue);
    expect(find.byKey(ValueKey('slides.version.stage.$gone')), findsOneWidget);
    expect(find.text('Slide deleted — Someone'), findsOneWidget);
    await close(tester, h);
  });

  testWidgets('when next and previous change are invoked then they step '
      'through the changed slides and objects in presentation order', (
    tester,
  ) async {
    final (h, st) = await show(tester);
    Future<void> run(String id) async {
      await tester.runAsync(
        () => h.services.dispatcher.invoke(id, source: InvocationSource.ui),
      );
      await tester.pump();
    }

    await run('slides.history.nextChange');
    expect((st.slideId, st.activeElementId), (s2, null));
    await run('slides.history.nextChange');
    expect((st.slideId, st.activeElementId), (s2, box));
    await run('slides.history.nextChange');
    expect((st.slideId, st.activeElementId), (s3, null));
    await run('slides.history.previousChange');
    expect((st.slideId, st.activeElementId), (s2, box));
    expect(find.text('2 of 3'), findsOneWidget);
    await close(tester, h);
  });

  testWidgets('when Show changes is off then no badges and no outlines show', (
    tester,
  ) async {
    final (h, _) = await show(tester, showChanges: false);

    expect(find.text('Changes are hidden'), findsWidgets);
    expect(find.byKey(ValueKey('slides.version.dot.$s2')), findsNothing);
    expect(find.byKey(ValueKey('slides.version.removed.$gone')), findsNothing);
    await close(tester, h);
  });

  testWidgets('when Show removed objects is toggled then the command flips '
      'it and reports the state', (tester) async {
    final (h, _) = await show(tester);

    final r = await tester.runAsync(
      () => h.services.dispatcher.invoke(
        'slides.history.toggleShowRemoved',
        source: InvocationSource.ui,
      ),
    );

    expect(r!.data, {'showRemoved': false});
    expect(SlidesVersionView.showRemoved.value, isFalse);
    await close(tester, h);
  });

  for (final width in [360.0, 700.0]) {
    testWidgets('when the view is ${width.toInt()} px wide then the '
        'navigator is a strip above the stage without overflow', (
      tester,
    ) async {
      final (h, _) = await show(tester, size: Size(width, 800));

      final nav = tester.widget<ListView>(
        find.byKey(const ValueKey('slides.version.navigator')),
      );
      expect(nav.scrollDirection, Axis.horizontal);
      expect(tester.takeException(), isNull);
      await close(tester, h);
    });
  }

  testWidgets('when Make a copy runs with a name then the server copies the '
      'version and the result names the new item', (tester) async {
    final calls = <(int, String, bool)>[];
    final (h, _) = await show(tester);
    copySlidesVersionOverride =
        (item, id, name, folder, comments, sharing) async {
          calls.add((id, name, comments));
          return h.drive.seed(
            name: name,
            uuid: UuidValue.fromString('01923456-789a-7bcd-8ef0-0000000000c9'),
            kind: DriveItemKind.presentation,
          );
        };

    final r = await tester.runAsync(
      () => h.services.dispatcher.invoke(
        'slides.history.makeCopy',
        args: {'name': 'Pitch v2', 'copyComments': true},
        source: InvocationSource.mcp,
      ),
    );
    await tester.pump();

    expect(r!.isOk, isTrue);
    expect(calls, [(2, 'Pitch v2', true)]);
    expect(
      (r.data! as Map)['itemUuid'],
      '01923456-789a-7bcd-8ef0-0000000000c9',
    );
    await close(tester, h);
  });

  test('when a restore returns a change id then its undo entry is one '
      'slides.serverChange step', () {
    final r = SlidesVersionRenderer();
    final entry = r.restoreUndoEntry(
      UuidValue.fromString(b.deckId),
      1,
      VersionRestoreResult(
        restorePoint: _version(3, b.deckId),
        changeId: UuidValue.fromString('01923456-789a-7bcd-8ef0-0000000000aa'),
      ),
    );
    expect(entry, isA<SlidesServerChangeEntry>());
    expect(entry!.domain, slidesServerChangeDomain);
    expect(
      (entry as SlidesServerChangeEntry).changeId,
      '01923456-789a-7bcd-8ef0-0000000000aa',
    );
  });

  test('when version history is on then the app config renders versions; '
      'when off then there is no renderer', () {
    expect(
      const SlidesAppConfig().versionRenderer,
      isA<SlidesVersionRenderer>(),
    );
    SlidesFeatures.enabled = {};
    expect(const SlidesAppConfig().versionRenderer, isNull);
  });

  testWidgets('when the shell history route opens a deck then the newest '
      'version renders with Slides changes against the one before', (
    tester,
  ) async {
    final h = slidesHarness(
      versions: _List([_version(2, b.deckId), _version(1, b.deckId)]),
    );
    h.drive.seed(
      name: 'Pitch',
      uuid: UuidValue.fromString(b.deckId),
      kind: DriveItemKind.presentation,
    );
    await pumpSlides(
      tester,
      h,
      VersionHistoryScreen(services: h.services, itemUuid: b.deckId),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(SlidesVersionView), findsOneWidget);
    expect(
      find.text('1 slide added · 1 slide changed · 1 slide deleted'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await close(tester, h);
  });

  for (final brightness in Brightness.values) {
    testWidgets('when the history route opens in a 360 px window '
        '(${brightness.name}) then the versions list sits under the preview '
        'instead of squeezing it to 40 px', (tester) async {
      final h = slidesHarness(
        versions: _List([_version(2, b.deckId), _version(1, b.deckId)]),
      );
      h.drive.seed(
        name: 'Pitch',
        uuid: UuidValue.fromString(b.deckId),
        kind: DriveItemKind.presentation,
      );
      await pumpSlides(
        tester,
        h,
        VersionHistoryScreen(services: h.services, itemUuid: b.deckId),
        brightness: brightness,
        size: const Size(360, 740),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump();

      final preview = tester.getRect(find.byType(SlidesVersionView));
      final list = tester.getRect(
        find.byKey(const ValueKey<String>('shell.history.list')),
      );
      expect(preview.width, greaterThan(300));
      expect(list.top, greaterThanOrEqualTo(preview.bottom - 1));
      expect(tester.takeException(), isNull);
      await close(tester, h);
    });
  }
}
