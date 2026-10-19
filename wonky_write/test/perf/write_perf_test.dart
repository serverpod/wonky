/// Write perf suite (Write 04 §36, CQ-38): keystroke latency on the
/// `bench_100_pages` fixture through the real document screen (toolbar,
/// comment margin, Pages mode, Suggesting mode, find highlights, the
/// server's acknowledgements), caret moves, select-all and remote ops.
///
/// Each sample is one action plus one 16 ms frame (build, layout, paint).
/// Widget tests run JIT in debug mode, so the numbers are only comparable
/// with each other (before/after a change on the same machine), not with
/// the profile-mode budget of 16 ms p95. The debug-only full-document
/// invariant checks and the semantics tree are off (as in a release app
/// without a screen reader). The budgets below are about 2× the medians
/// measured on 2026-10-18 after CQ-42/CQ-49; a regression past them fails
/// the test. Tagged `perf` (skipped by default):
///
/// ```sh
/// flutter test -t perf --run-skipped test/perf
/// # hot spots of each scenario (VM CPU profile):
/// WONKY_PROFILE=1 flutter test --enable-vmservice -t perf --run-skipped test/perf
/// ```
@Tags(['perf'])
library;

import 'dart:math' as math;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write/config/write_app_config.dart';
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/editor/controller/editor_pipeline.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart'
    show LayoutMode;
import 'package:wonky_write/features/editor/view/editor_view_state.dart'
    show HighlightRange;
import 'package:wonky_write/features/screen/write_document_screen.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaSelection, DeltaUtils;

import '../features/document/support/session_harness.dart';
import '../features/sync/support/fake_document_server.dart';
import 'support/bench_document.dart';
import 'support/cpu_profile.dart';

/// Median and p95 of a list of samples (µs), printed in ms.
class PerfStats {
  PerfStats(this.name, List<int> micros) : samples = [...micros]..sort();

  final String name;
  final List<int> samples;

  double _at(double q) =>
      samples[math.min(samples.length - 1, (samples.length * q).floor())] /
      1000;

  double get median => _at(0.5);
  double get p95 => _at(0.95);

  @override
  String toString() =>
      '[perf] $name: median ${median.toStringAsFixed(1)} ms, '
      'p95 ${p95.toStringAsFixed(1)} ms (n=${samples.length})';
}

void main() {
  late BenchDocument bench;
  late FakeDocumentServer server;
  late CommandTestHarness h;
  late WriteDocumentSession session;
  late SimpleConnectionKeeper keeper;
  late FakeComments comments;

  setUpAll(() {
    bench = BenchDocument.hundredPages();
    // Measure the editor, not the debug-only full-document checks.
    EditorPipeline.debugVerifyInvariants = false;
  });
  tearDownAll(() => EditorPipeline.debugVerifyInvariants = null);

  setUp(() {
    server = FakeDocumentServer(initial: bench.delta);
    comments = FakeComments();
    for (final uuid in bench.commentThreads) {
      comments.threads[uuid] = CommentThreadView(
        uuid: UuidValue.fromString(uuid),
        itemUuid: UuidValue.fromString(itemUuid),
        anchorKind: CommentAnchorKind.textRange,
        anchorJson: '{"v":1}',
        quotedText: 'Bench',
        status: CommentStatus.open,
        createdBy: comments.me,
        createdAt: DateTime.utc(2026),
        comments: [
          CommentView(
            id: comments.threads.length + 1,
            threadUuid: UuidValue.fromString(uuid),
            author: comments.me,
            authorKind: ActorKind.user,
            body: 'Please check this.',
            mentions: const [],
            reactions: const {},
            createdAt: DateTime.utc(2026),
            deleted: false,
          ),
        ],
      );
    }
    h = CommandTestHarness(config: const WriteAppConfig(), comments: comments);
    h.drive.seed(name: 'Bench', uuid: UuidValue.fromString(itemUuid));
    keeper = SimpleConnectionKeeper(minDelay: Duration.zero);
    session = WriteDocumentSession(
      services: h.services,
      itemUuid: itemUuid,
      api: FakeWriteApi(server),
      keeper: keeper,
    );
  });

  tearDown(() async {
    await pumpEventQueue();
    keeper.dispose();
    await pumpEventQueue();
    await h.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    LayoutMode layout = LayoutMode.pageless,
  }) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      Provider<ShellServices>.value(
        value: h.services,
        child: ShadApp(
          theme: WonkyTheme.light(),
          localizationsDelegates: const [
            WonkyAppLocalizations.delegate,
            WonkyUiLocalizations.delegate,
          ],
          home: Material(
            type: MaterialType.transparency,
            child: WonkyThemeScope(
              data: const WonkyThemeExtension(),
              child: WriteDocumentScreen(
                services: h.services,
                itemUuid: itemUuid,
                themes: WriteThemeCatalog(),
                sessionFactory: (s, uuid) => session,
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
      if (session.phase.value == WriteSessionPhase.ready && i > 10) break;
    }
    // Comment threads load, derived data settles.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 400));
    }
    if (session.editor.view.layout != layout) {
      await h.invoke('write.doc.setLayout', {'layout': layout.name});
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(pumpEventQueue);
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(session.phase.value, WriteSessionPhase.ready);
    expect(session.editor.view.layout, layout);
  }

  /// Puts the caret in the middle of a paragraph about halfway through the
  /// document (between comment anchors).
  Future<void> placeCaret(WidgetTester tester) async {
    final mirror = session.editor.mirror;
    for (var i = mirror.nodeCount ~/ 2; i < mirror.nodeCount; i++) {
      final node = mirror.entryAt(i).node;
      if (node is ParagraphNode &&
          node.text.length > 40 &&
          node.metadata['blockType'] == paragraphAttribution) {
        final start = mirror.startOfIndex(i);
        session.editor.select(DeltaSelection.collapsed(start + 20));
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// Runs [action] [count] times, pumping one 16 ms frame after each, and
  /// returns the wall time per action + frame.
  Future<PerfStats> measure(
    WidgetTester tester,
    String name,
    int count,
    void Function(int i) action, {
    int warmUp = 5,
    bool roundTrip = false,
  }) async {
    // With [roundTrip], the server's answer (ack, echo) is processed inside
    // the measured time too (the transport runs on real async).
    Future<void> deliver() async {
      if (roundTrip) await tester.runAsync(() => pumpEventQueue(times: 4));
    }

    for (var i = 0; i < warmUp; i++) {
      action(i);
      await deliver();
      await tester.pump(const Duration(milliseconds: 16));
    }
    final samples = <int>[];
    final actions = <int>[];
    await CpuProfile.run(tester, name, () async {
      for (var i = 0; i < count; i++) {
        final sw = Stopwatch()..start();
        action(warmUp + i);
        actions.add(sw.elapsedMicroseconds);
        await deliver();
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        samples.add(sw.elapsedMicroseconds);
      }
    });
    final stats = PerfStats(name, samples);
    // ignore: avoid_print
    print('$stats; action alone: ${PerfStats(name, actions).median} ms');
    return stats;
  }

  /// [count] separate undo steps at the caret (commands do not coalesce),
  /// acknowledged by the server.
  Future<void> addUndoSteps(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      final at = session.editor.selection!.anchor;
      session.applyContentChange(
        Delta()
          ..retain(at)
          ..insert('u'),
        label: 'Step $i',
      );
      await tester.runAsync(() => pumpEventQueue(times: 4));
    }
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      h.services.undo.undoStepsOf(session.undoStackKey).length,
      greaterThanOrEqualTo(count),
    );
  }

  void typeChar(int i) => session.editor.editor.execute([
    InsertCharacterAtCaretRequest(character: i % 6 == 5 ? ' ' : 'x'),
  ]);

  Future<void> settleAndClose(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  perfTest('Given the 100-page document with the comment margin when '
      'typing then a keystroke stays within its budget', (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const ValueKey('write.commentMargin')), findsWidgets);
    await placeCaret(tester);

    final stats = await measure(tester, 'keystroke, pageless', 40, typeChar);

    expect(stats.median, lessThan(_budget.keystroke));
    await settleAndClose(tester);
  });

  perfTest('Given the 100-page document in Pages mode when typing then a '
      'keystroke stays within its budget', (tester) async {
    await pumpScreen(tester, layout: LayoutMode.pages);
    await placeCaret(tester);

    final stats = await measure(tester, 'keystroke, Pages', 40, typeChar);

    expect(stats.median, lessThan(_budget.pagesKeystroke));
    await settleAndClose(tester);
  });

  perfTest('Given the 100-page document in Pages mode when moving the '
      'caret then a caret move stays within its budget', (tester) async {
    await pumpScreen(tester, layout: LayoutMode.pages);
    await placeCaret(tester);
    final base = session.editor.selection!.anchor;

    final stats = await measure(
      tester,
      'caret move, Pages',
      40,
      (i) => session.editor.select(DeltaSelection.collapsed(base + i % 10)),
    );

    expect(stats.median, lessThan(_budget.caretMove));
    await settleAndClose(tester);
  });

  perfTest(
    'Given about 2,000 find matches in the 100-page document when typing '
    'then a keystroke stays within its budget',
    (tester) async {
      await pumpScreen(tester);
      await placeCaret(tester);
      final text = DeltaUtils.text(session.editor.delta);
      // 2,000 matches spread evenly over the document.
      final all = [
        for (
          var i = text.indexOf('target');
          i >= 0;
          i = text.indexOf('target', i + 1)
        )
          HighlightRange(i, i + 6),
      ];
      final matches = [
        for (var k = 0; k < 2000; k++) all[k * all.length ~/ 2000],
      ];
      session.editor.view.setFindMatches(matches);
      await tester.pump(const Duration(milliseconds: 16));
      expect(all.length, greaterThan(2000));

      final stats = await measure(
        tester,
        'keystroke, 2,000 find matches',
        40,
        typeChar,
      );

      expect(stats.median, lessThan(_budget.findKeystroke));
      await settleAndClose(tester);
    },
  );

  perfTest('Given the 100-page document in Suggesting mode when typing '
      'then a keystroke stays within its budget', (tester) async {
    await pumpScreen(tester);
    await h.invoke('write.mode.set', {'mode': 'suggesting'});
    await tester.pump(const Duration(milliseconds: 16));
    await placeCaret(tester);

    final stats = await measure(tester, 'keystroke, Suggesting', 40, typeChar);

    expect(stats.median, lessThan(_budget.suggestingKeystroke));
    await settleAndClose(tester);
  });

  perfTest('Given the 100-page document when selecting all then the '
      'frame stays within its budget', (tester) async {
    await pumpScreen(tester);
    await placeCaret(tester);
    final length = session.editor.length;
    final caret = session.editor.selection!.anchor;

    final stats = await measure(
      tester,
      'select all / collapse',
      20,
      (i) => session.editor.select(
        i.isEven
            ? DeltaSelection(0, length - 1)
            : DeltaSelection.collapsed(caret),
      ),
      warmUp: 2,
    );

    expect(stats.median, lessThan(_budget.selectAll));
    await settleAndClose(tester);
  });

  perfTest('Given the 100-page document with 200 undo steps when typing '
      'with the server acknowledging each change then a keystroke stays '
      'within its budget', (tester) async {
    await pumpScreen(tester);
    await placeCaret(tester);
    await addUndoSteps(tester, 200);
    final revision = session.revision;

    final stats = await measure(tester, 'keystroke + ack round trip', 40, (i) {
      typeChar(i);
      // The presence controller sends the caret (throttled to 10/s).
      final caret = session.editor.selection!.anchor;
      session.sync!.sendCursor(caret, caret);
    }, roundTrip: true);

    expect(session.revision, greaterThan(revision + 40));
    expect(stats.median, lessThan(_budget.ackKeystroke));
    await settleAndClose(tester);
  });

  perfTest('Given the 100-page document with 200 undo steps when '
      'collaborators edit then a remote op stays within its budget', (
    tester,
  ) async {
    await pumpScreen(tester);
    await placeCaret(tester);
    await addUndoSteps(tester, 200);

    final stats = await measure(
      tester,
      'remote op',
      40,
      (i) => server.commitExternal(
        Delta()
          ..retain(10 + i)
          ..insert('r'),
      ),
      warmUp: 3,
      roundTrip: true,
    );

    expect(stats.median, lessThan(_budget.remoteOp));
    await settleAndClose(tester);
  });
}

/// Median budgets (ms, debug-mode widget test on a Windows dev machine; see
/// the library comment): about twice the medians measured after CQ-42/49.
/// Before → after on 2026-10-18 in the comments.
const _budget = (
  keystroke: 300.0, // 487 → 124–134
  pagesKeystroke: 300.0, // 486 → 146
  caretMove: 150.0, // 414 → 69
  suggestingKeystroke: 300.0, // 483 → 130
  ackKeystroke: 300.0, // 142 → 121 (CQ-49 only; the fake server normalizes too)
  findKeystroke: 250.0, // 199 → 107 (W-13 only)
  selectAll: 900.0, // 824 → 440
  remoteOp: 250.0, // 427 → 105
);

/// A widget test without the semantics tree (as in the app while no screen
/// reader is on; flutter_test turns semantics on by default).
void perfTest(String description, WidgetTesterCallback body) =>
    testWidgets(description, body, semanticsEnabled: false);
