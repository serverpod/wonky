import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write/features/ai/ai_undo_grouping.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

/// Commits [change] on the server as an AI op made on behalf of [onBehalf]
/// in run [groupId] (what `HeadlessDocumentEditor` broadcasts).
void _aiOp(
  FakeDocumentServer server,
  Delta change, {
  required String onBehalf,
  required String groupId,
}) {
  final c = DeltaUtils.canonical(change);
  server.document = WonkyOt.apply(server.document, c);
  server.history.add(server.document);
  final rev = server.revision + 1;
  server.ops.add(
    FakeOp(
      rev,
      c,
      UuidValue.fromString(
        '00000000-0000-7000-9000-${rev.toRadixString(16).padLeft(12, '0')}',
      ),
      'ai-agent',
      1,
    ),
  );
  for (final conn in server.connections) {
    conn.push(
      DocRemoteOp(
        revision: rev,
        deltaJson: jsonEncode(c.toJson()),
        authorId: 1,
        authorSessionId: 'ai-agent',
        actorKind: ActorKind.ai,
        kind: DocumentOpKind.aiEdit,
        onBehalfOfSessionId: onBehalf,
        groupId: groupId,
      ),
      bus: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Given an open document and an assistant run on its behalf', () {
    late FakeDocumentServer server;
    late SessionHarness h;

    setUp(() async {
      server = FakeDocumentServer(
        initial: Delta()..insert('The old plan.\nTen euros.\n'),
      );
      h = SessionHarness(server);
      await h.open();
    });
    tearDown(() => h.dispose());

    test('when the run makes two edits then they undo as one step labelled '
        '"AI: …"', () async {
      final session = h.session.sync!.sessionId!;
      _aiOp(
        server,
        Delta()
          ..retain(4)
          ..delete(3)
          ..insert('new'),
        onBehalf: session,
        groupId: 'run-1',
      );
      await pumpEventQueue();
      _aiOp(
        server,
        Delta()
          ..retain(14)
          ..delete(3)
          ..insert('Twelve'),
        onBehalf: session,
        groupId: 'run-1',
      );
      await pumpEventQueue();
      expect(h.text, 'The new plan.\nTwelve euros.\n');
      expect(h.undo.undoStepsOf(h.session.undoStackKey), hasLength(1));

      h.session.aiUndo.relabel('run-1', 'Updated the plan');
      expect(h.undo.undoLabel.value, 'AI: Updated the plan');

      await h.undo.undo();
      await pumpEventQueue();
      expect(h.text, 'The old plan.\nTen euros.\n');
      expect(DeltaUtils.text(server.document), 'The old plan.\nTen euros.\n');
    });

    test(
      'when another session made the run then nothing lands on this stack',
      () async {
        _aiOp(
          server,
          Delta()..insert('Hi '),
          onBehalf: 'someone-else',
          groupId: 'run-2',
        );
        await pumpEventQueue();
        expect(h.text, 'Hi The old plan.\nTen euros.\n');
        expect(h.undo.undoStepsOf(h.session.undoStackKey), isEmpty);
      },
    );

    test('when the user typed during the run then undoing the run keeps the '
        'typing', () async {
      final session = h.session.sync!.sessionId!;
      _aiOp(
        server,
        Delta()
          ..retain(4)
          ..delete(3)
          ..insert('new'),
        onBehalf: session,
        groupId: 'run-3',
      );
      await pumpEventQueue();
      h.session.editor.applyLocal(
        Delta()
          ..retain(13)
          ..insert('!'),
        label: 'Typing',
        source: LocalChangeSource.input,
      );
      await pumpEventQueue();
      expect(await h.session.aiUndo.undoRun('run-3'), isFalse);
      await h.undo.undo(); // Typing
      await pumpEventQueue();
      expect(await h.session.aiUndo.undoRun('run-3'), isTrue);
      await pumpEventQueue();
      expect(h.text, 'The old plan.\nTen euros.\n');
    });

    test('ownership needs the same session and a group', () {
      expect(
        AiUndoGrouping.isOwnRun(
          onBehalfOf: 's1',
          groupId: 'g',
          sessionId: 's1',
        ),
        isTrue,
      );
      expect(
        AiUndoGrouping.isOwnRun(
          onBehalfOf: 's1',
          groupId: null,
          sessionId: 's1',
        ),
        isFalse,
      );
      expect(
        AiUndoGrouping.isOwnRun(
          onBehalfOf: 's2',
          groupId: 'g',
          sessionId: 's1',
        ),
        isFalse,
      );
    });
  });
}
