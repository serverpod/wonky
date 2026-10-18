import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write/features/comments/comment_margin_layout.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Given a document with comments open', () {
    late FakeDocumentServer server;
    late SessionHarness h;
    late CommentsController c;

    setUp(() async {
      server = FakeDocumentServer(
        initial: Delta()..insert('Hello brave world\n'),
      );
      h = SessionHarness(server);
      await h.open(withComments: true);
      c = h.commentsController!;
    });

    tearDown(() => h.dispose());

    /// What `shell.comments.create` does: draft, then create in one
    /// undoable step.
    Future<CommentThreadView> comment(String body) async {
      final anchor = h.session.comments.anchorForSelection()!;
      c.startDraft(anchor);
      final t = h.undo.beginTransaction(
        'Comment',
        stack: h.session.undoStackKey,
      );
      final thread = await c.createThread(anchor: anchor, body: body);
      t.record(
        CommentUndoEntry(
          op: CommentUndoOp.createThread,
          threadUuid: thread.uuid.uuid,
          body: body,
          anchorKind: anchor.kind,
          anchorJson: anchor.anchorJson,
          quotedText: anchor.quotedText,
        ),
      );
      t.commit();
      await pumpEventQueue();
      return thread;
    }

    test(
      'when commenting on a selection then the range carries the anchor on every replica',
      () async {
        h.session.editor.select(const DeltaSelection(6, 11));

        final t = await comment('Why brave?');

        final anchor = CommentAnchors.anchorOf(h.doc, t.uuid.uuid)!;
        expect((anchor.start, anchor.length), (6, 5));
        expect(t.quotedText, 'brave');
        expect(
          CommentAnchors.anchorOf(server.document, t.uuid.uuid),
          isNotNull,
        );
        expect(h.session.comments.anchoredOpenThreads.single.uuid, t.uuid);
        expect(h.session.editor.view.pendingComment, isNull);
      },
    );

    test(
      'when the caret is collapsed then the word at the caret is the anchor',
      () {
        h.session.editor.select(const DeltaSelection.collapsed(8));

        final anchor = h.session.comments.anchorForSelection();

        expect(anchor!.quotedText, 'brave');
        expect(anchor.anchorJson, '{"v":1}');
      },
    );

    test(
      'when the comment step is undone then the anchor is removed',
      () async {
        h.session.editor.select(const DeltaSelection(0, 5));
        final t = await comment('Greeting');

        await h.undo.undo();
        await pumpEventQueue();

        expect(CommentAnchors.anchorOf(h.doc, t.uuid.uuid), isNull);
        expect(c.thread(t.uuid.uuid), isNull);
        expect(server.document, h.doc);
      },
    );

    test(
      'when the comment step is undone and redone then thread and anchor come back together',
      () async {
        h.session.editor.select(const DeltaSelection(0, 5));
        final t = await comment('Greeting');
        await h.undo.undo();
        await pumpEventQueue();

        await h.undo.redo();
        await pumpEventQueue();

        expect(c.thread(t.uuid.uuid), isNotNull);
        expect(CommentAnchors.anchorOf(h.doc, t.uuid.uuid), isNotNull);
        expect(server.document, h.doc);
      },
    );

    test(
      'when a collaborator edits before the composer is saved then the pending range follows',
      () async {
        h.session.editor.select(const DeltaSelection(6, 11));
        final anchor = h.session.comments.anchorForSelection()!;
        c.startDraft(anchor);
        await pumpEventQueue();
        expect(h.session.editor.view.pendingComment!.start, 6);

        server.commitExternal(Delta()..insert('Oh! '));
        await pumpEventQueue();
        final thread = await c.createThread(anchor: anchor, body: 'x');
        await pumpEventQueue();

        final a = CommentAnchors.anchorOf(h.doc, thread.uuid.uuid)!;
        expect((a.start, a.length), (10, 5));
      },
    );

    test(
      'when clicking into highlighted text then its thread becomes active',
      () async {
        h.session.editor.select(const DeltaSelection(6, 11));
        final t = await comment('Why brave?');
        c.activate(null);

        h.session.editor.select(const DeltaSelection.collapsed(8));
        await pumpEventQueue();

        expect(c.activeThreadUuid, t.uuid.uuid);
        expect(h.session.editor.view.comments.activeThread, t.uuid.uuid);
      },
    );

    test('when a thread is resolved then its highlight is hidden', () async {
      h.session.editor.select(const DeltaSelection(0, 5));
      final t = await comment('Greeting');

      await c.resolve(t.uuid.uuid);

      expect(
        h.session.editor.view.comments.hiddenThreads,
        contains(t.uuid.uuid),
      );
      expect(h.session.comments.anchoredOpenThreads, isEmpty);
    });

    test(
      'when a thread is deleted then its anchors are removed as one step',
      () async {
        h.session.editor.select(const DeltaSelection(0, 5));
        final t = await comment('Greeting');

        await c.deleteThread(t.uuid.uuid);
        await pumpEventQueue();

        expect(CommentAnchors.anchorOf(h.doc, t.uuid.uuid), isNull);
        expect(h.undo.undoLabel.value, 'Delete comment');
      },
    );

    test(
      'when navigating then the next anchored thread after the caret is activated',
      () async {
        h.session.editor.select(const DeltaSelection(0, 5));
        final first = await comment('one');
        h.session.editor.select(const DeltaSelection(12, 17));
        final second = await comment('two');
        c.activate(null);
        h.session.editor.select(const DeltaSelection.collapsed(6));

        expect(h.session.comments.next(), isTrue);
        expect(c.activeThreadUuid, second.uuid.uuid);
        expect(h.session.comments.next(), isTrue);
        expect(c.activeThreadUuid, first.uuid.uuid);
      },
    );
  });

  group('Given margin cards', () {
    MarginItem item(String id, double top, {double height = 50}) => MarginItem(
      id: id,
      anchorTop: top,
      anchorOffset: top.toInt(),
      height: height,
    );

    test('when anchors are close then cards are stacked without overlap', () {
      final tops = CommentMarginLayout.layout([
        item('a', 10),
        item('b', 20),
        item('c', 200),
      ]);

      expect(tops, {'a': 10.0, 'b': 68.0, 'c': 200.0});
    });

    test(
      'when a card is active then it aligns with its anchor and pushes earlier cards up',
      () {
        final tops = CommentMarginLayout.layout([
          item('a', 100),
          item('b', 110),
          item('c', 120),
        ], activeId: 'b');

        expect(tops['b'], 110);
        expect(tops['a'], 110 - 8 - 50);
        expect(tops['c'], 110 + 50 + 8);
      },
    );

    test(
      'when pushing up would leave the margin then the cards start at the top',
      () {
        final tops = CommentMarginLayout.layout([
          item('a', 0),
          item('b', 10),
        ], activeId: 'b');

        expect(tops['a'], 0);
        expect(tops['b'], 58);
      },
    );
  });
}
