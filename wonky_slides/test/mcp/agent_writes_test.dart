import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' show ActorKind;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;
import 'package:wonky_slides/mcp/agent_flash.dart';
import 'package:wonky_slides/mcp/agent_writes.dart';

import '../harness/deck_harness.dart';
import '../support/deck_screen.dart' show sampleDeck;

const _bo = '00000000-0000-4000-8000-0000000000b0';

/// Headless agent writes flash in open editors (Slides 11 §1.3, AC 5;
/// SL-42): MCP rows of the change log flash their elements (or slides)
/// with the agent tag; user edits, the user's own AI runs and stale rows
/// don't.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DeckHarness d;
  late List<RevOpMeta> rows;
  late SlidesAgentWrites writes;

  SlidesAgentFlash flash() => SlidesAgentFlash.of(d.editor);

  var revision = 0;
  RevOpMeta row({
    required ActorKind kind,
    String user = _bo,
    String session = 'server:mcp',
    List<String> slides = const [],
    List<String> elements = const [],
    DateTime? at,
  }) => RevOpMeta(
    revision: ++revision,
    authorUuid: user,
    actorKind: kind.name,
    sessionId: session,
    label: 'MCP: set_text',
    summary: {
      'v': 1,
      'kinds': ['text'],
      'slides': slides,
      'elements': elements,
    },
    committedAt: at ?? clock.now().toUtc(),
  );

  String titleOf(int index) {
    final slide = d.editor.order.entries[index].id;
    return d.model
        .elementsOf(slide)
        .firstWhere((e) => e.placeholderType?.name == 'title')
        .id;
  }

  setUp(() {
    d = DeckHarness.open(fixture: sampleDeck());
    rows = [];
    writes = SlidesAgentWrites(d.editor, source: (since) async => rows);
  });

  tearDown(() async {
    writes.dispose();
    flash().dispose();
    await d.dispose();
  });

  group('Given an open deck', () {
    test('when an MCP write to a title syncs in then the title flashes '
        'with an MCP tag', () async {
      final title = titleOf(1);
      rows.add(
        row(
          kind: ActorKind.mcp,
          slides: [d.editor.order.entries[1].id],
          elements: [title],
        ),
      );

      await writes.poll();

      final f = flash().active.single;
      expect(f.elementIds, [title]);
      expect(f.slideId, d.editor.order.entries[1].id);
      expect(f.label, contains('MCP'));
    });

    test(
      'when the same row is read again then it does not flash twice',
      () async {
        rows.add(row(kind: ActorKind.mcp, elements: [titleOf(0)]));

        await writes.poll();
        await writes.poll();

        expect(flash().active, hasLength(1));
      },
    );

    test(
      'when an MCP write only added a slide then the slide flashes',
      () async {
        final slide = d.editor.order.entries[3].id;
        rows.add(row(kind: ActorKind.mcp, slides: [slide]));

        await writes.poll();

        final f = flash().active.single;
        expect(f.slideId, slide);
        expect(f.elementIds, isEmpty);
      },
    );

    test('when a person edits or the user runs their own AI then nothing '
        'flashes', () async {
      rows
        ..add(row(kind: ActorKind.user, session: 'bo', elements: [titleOf(0)]))
        ..add(
          row(
            kind: ActorKind.ai,
            user: d.session.userId,
            elements: [titleOf(1)],
          ),
        );

      await writes.poll();

      expect(flash().active, isEmpty);
    });

    test('when another user\'s AI run syncs in then it flashes', () async {
      rows.add(row(kind: ActorKind.ai, elements: [titleOf(2)]));

      await writes.poll();

      expect(flash().active.single.elementIds, [titleOf(2)]);
    });

    test(
      'when an MCP write is older than two minutes then it is skipped',
      () async {
        rows.add(
          row(
            kind: ActorKind.mcp,
            elements: [titleOf(0)],
            at: clock.now().toUtc().subtract(const Duration(minutes: 5)),
          ),
        );

        await writes.poll();

        expect(flash().active, isEmpty);
      },
    );
  });
}
