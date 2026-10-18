import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import '../support/fake_collab.dart';

void main() {
  final item = UuidValue.fromString('0199f000-0000-7000-8000-0000000000cc');
  const anchor = NewCommentAnchor(
    kind: CommentAnchorKind.textRange,
    anchorJson: '{"from":1,"to":4}',
    quotedText: 'Plan',
  );
  late FakeCommentRepository repo;
  late CommandTestHarness h;
  late CommentsController c;

  setUp(() {
    repo = FakeCommentRepository();
    h = CommandTestHarness(comments: repo);
    c = CommentsController(services: h.services, itemUuid: item);
  });
  tearDown(() async {
    c.dispose();
    await h.dispose();
    await repo.events.close();
  });

  List<String> bodies(Iterable<CommentThreadView> threads) => [
    for (final t in threads) t.comments.first.body,
  ];

  group('Given a file with comment threads', () {
    setUp(() {
      repo
        ..seed(body: 'First')
        ..seed(body: 'Done', status: CommentStatus.resolved);
    });

    test('when started then the threads load and the live stream is '
        'watched', () async {
      expect(c.loading, isTrue);

      await c.start();

      expect(c.loading, isFalse);
      expect(c.error, isNull);
      expect(bodies(c.threads), ['First', 'Done']);
      expect(c.openCount, 1);
      expect(repo.watches, 1);
      expect(h.services.supervisor.isActive('comments:${item.uuid}'), isTrue);
    });

    test(
      'when loading fails then the error is kept and loading ends',
      () async {
        repo.failWith = WonkyException(
          code: WonkyErrorCode.forbidden,
          message: 'No access',
        );

        await c.start();

        expect(c.loading, isFalse);
        expect(c.error, isA<WonkyException>());
        expect(c.messageOf(c.error!), 'No access');
      },
    );

    test('when disposed then the live stream stops', () async {
      await c.start();

      c.dispose();
      c = CommentsController(services: h.services, itemUuid: item);
      await pumpEventQueue();

      expect(h.services.supervisor.isActive('comments:${item.uuid}'), isFalse);
    });
  });

  group('Given started comments', () {
    setUp(() => c.start());

    test('when a thread is created then it is stored, listed and active, '
        'and the draft is closed', () async {
      c.startDraft(anchor);
      expect(c.draftAnchor, same(anchor));

      final t = await c.createThread(anchor: anchor, body: 'Check this');

      expect(repo.threads.keys, [t.uuid.uuid]);
      expect(t.quotedText, 'Plan');
      expect(c.thread(t.uuid.uuid), isNotNull);
      expect(c.activeThreadUuid, t.uuid.uuid);
      expect(c.draftAnchor, isNull);
    });

    test('when replying then the reply is added to the thread', () async {
      final t = await c.createThread(anchor: anchor, body: 'Check this');

      await c.reply(t.uuid.uuid, 'Done');

      expect(bodies([c.thread(t.uuid.uuid)!]), ['Check this']);
      expect(
        [for (final x in c.thread(t.uuid.uuid)!.comments) x.body],
        ['Check this', 'Done'],
      );
    });

    test('when a thread is resolved then it leaves the open list, and '
        'reopening brings it back', () async {
      final t = await c.createThread(anchor: anchor, body: 'Check this');

      await c.resolve(t.uuid.uuid);
      expect(c.thread(t.uuid.uuid)!.status, CommentStatus.resolved);
      expect(c.visible, isEmpty);
      expect(c.openCount, 0);

      await c.reopen(t.uuid.uuid);

      expect(bodies(c.visible), ['Check this']);
    });

    test('when a thread is deleted then it is gone; when a comment is '
        'deleted then the thread reloads without it', () async {
      final a = await c.createThread(anchor: anchor, body: 'A');
      final b = await c.createThread(anchor: anchor, body: 'B');
      final reply = (await c.reply(b.uuid.uuid, 'B2')).comments.last;

      await c.deleteThread(a.uuid.uuid);
      await c.deleteComment(reply.id);

      expect(c.thread(a.uuid.uuid), isNull);
      expect([for (final x in c.thread(b.uuid.uuid)!.comments) x.body], ['B']);
    });

    test('when a comment is edited then the thread reloads with the new '
        'text', () async {
      final t = await c.createThread(anchor: anchor, body: 'Teh plan');

      await c.edit(t.comments.single.id, 'The plan');

      expect(bodies([c.thread(t.uuid.uuid)!]), ['The plan']);
    });
  });

  group('Given live comment events', () {
    late int notified;

    setUp(() async {
      await c.start();
      // The reload of the stream's onConnected.
      await pumpEventQueue();
      notified = 0;
      c.addListener(() => notified++);
    });

    test('when threads are created, change status and are deleted '
        'elsewhere then the list follows', () async {
      final t = repo.seed(body: 'Remote');

      repo.events.add(
        CommentEvent(
          kind: CommentEventKind.threadCreated,
          threadUuid: t.uuid,
          thread: t,
        ),
      );
      await pumpEventQueue();
      expect(bodies(c.threads), ['Remote']);

      repo.events.add(
        CommentEvent(
          kind: CommentEventKind.statusChanged,
          threadUuid: t.uuid,
          thread: t.copyWith(status: CommentStatus.resolved),
        ),
      );
      await pumpEventQueue();
      expect(c.threads.single.status, CommentStatus.resolved);

      repo.events.add(
        CommentEvent(kind: CommentEventKind.threadDeleted, threadUuid: t.uuid),
      );
      await pumpEventQueue();

      expect(c.threads, isEmpty);
      expect(notified, 3);
    });
  });

  group('Given threads for and not for the signed-in user', () {
    setUp(() async {
      repo
        ..seed(body: 'Assigned', assignee: TestUsers.anna)
        ..seed(
          body: 'Mentioned',
          author: TestUsers.bob,
          mentions: [TestUsers.anna],
          createdAt: DateTime.utc(2026, 10, 3),
        )
        ..seed(
          body: 'Other',
          author: TestUsers.bob,
          createdAt: DateTime.utc(2026, 10, 2),
        )
        ..seed(
          body: 'Resolved',
          assignee: TestUsers.anna,
          status: CommentStatus.resolved,
        );
      await c.start();
    });

    test('when filtering open threads then every unresolved thread shows, '
        'oldest first', () {
      expect(bodies(c.visible), ['Assigned', 'Other', 'Mentioned']);
    });

    test('when filtering for me then only threads assigned to or '
        'mentioning me show', () {
      c.setFilter(CommentsFilter.forYou);

      expect(bodies(c.visible), ['Assigned', 'Mentioned']);
    });

    test('when sorting by date then the newest thread comes first', () {
      c.setSort(CommentsSort.date);

      expect(bodies(c.visible), ['Mentioned', 'Other', 'Assigned']);
    });
  });

  group('Given comments of the open file run as commands', () {
    setUp(() async {
      await c.start();
      h.services.comments.value = c;
    });

    Future<String> create() async {
      final r = await h.invoke('shell.comments.create', {
        'body': 'Check this',
        'anchorKind': 'textRange',
        'anchorJson': '{"from":1,"to":4}',
      });
      return (r.data! as Map<String, Object?>)['threadUuid']! as String;
    }

    test('when undoing a new comment then the thread is deleted, and redo '
        'brings it back with the same id', () async {
      final uuid = await create();

      await h.undo();
      expect(repo.threads, isEmpty);
      expect(c.threads, isEmpty);
      await h.redo();

      expect(repo.threads.keys, [uuid]);
      expect(bodies(c.threads), ['Check this']);
    });

    test('when undoing a resolve then the thread is open again', () async {
      final uuid = await create();
      await h.invoke('shell.comments.resolve', {'threadUuid': uuid});

      await h.undo();

      expect(repo.threads[uuid]!.status, CommentStatus.open);
      expect(c.thread(uuid)!.status, CommentStatus.open);
    });

    test('when undoing a deleted thread then it is re-created with the same '
        'id, anchor and text', () async {
      final uuid = await create();
      await h.invoke('shell.comments.delete', {'threadUuid': uuid});
      expect(repo.threads, isEmpty);

      await h.undo();

      final t = repo.threads[uuid]!;
      expect(t.anchorJson, '{"from":1,"to":4}');
      expect(t.comments.single.body, 'Check this');
    });

    test('when undoing a reply then the reply is deleted', () async {
      final uuid = await create();
      await h.invoke('shell.comments.reply', {
        'threadUuid': uuid,
        'body': 'Done',
      });

      await h.undo();

      expect(
        [for (final x in repo.threads[uuid]!.comments) x.body],
        ['Check this'],
      );
    });
  });

  group('Given comments queued offline', () {
    setUp(() async {
      await c.start();
      c.queueOffline = true;
      h.services.connectivity.reportFailure();
    });

    test('when a thread is created offline then it shows as pending and is '
        'posted when the connection is back', () async {
      final t = await c.createThread(anchor: anchor, body: 'Offline');
      expect(c.isPending(t.uuid.uuid), isTrue);
      expect(c.isPendingComment(t.comments.single), isTrue);
      expect(repo.threads, isEmpty);

      h.services.connectivity.reportSuccess();
      await pumpEventQueue();

      expect(c.pendingOps, isEmpty);
      expect(repo.calls, ['createThread']);
      expect(
        c.isPendingComment(c.thread(t.uuid.uuid)!.comments.single),
        isFalse,
      );
    });

    test('when a queued thread is deleted then it is dropped without '
        'calling the server', () async {
      final t = await c.createThread(anchor: anchor, body: 'Offline');

      await c.deleteThread(t.uuid.uuid);
      h.services.connectivity.reportSuccess();
      await pumpEventQueue();

      expect(c.threads, isEmpty);
      expect(repo.calls, isEmpty);
    });
  });
}
