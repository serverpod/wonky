import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

/// `shell.board.*` (specs/16 §14): every state-changing command records the
/// server inverse on the shell stack; undo and redo round-trip.
void main() {
  late FakeBoardRepository board;
  late CommandTestHarness h;

  Future<void> asAdmin() async {
    board.isAdmin = true;
    await BoardHub.of(h.services).loadMe(force: true);
  }

  setUp(() {
    board = FakeBoardRepository(userId: 1);
    h = CommandTestHarness(board: board);
  });
  tearDown(() async {
    await h.dispose();
    await board.dispose();
  });

  test('when posting a report then the post exists, open board pages are '
      'told, undo deletes it and redo restores it', () async {
    final changes = <BoardChange>[];
    final sub = BoardHub.of(h.services).changes.listen(changes.add);
    addTearDown(sub.cancel);

    final r = await h.invoke('shell.board.createPost', {
      'kind': 'bug',
      'title': 'Paste drops bold in merged cells',
      'body': 'Steps: paste.',
      'contextJson': '{"app":"sheets"}',
    });
    final n = (r.data! as Map)['postNumber'] as int;
    final post = board.posts[n]!;

    expect((r.data! as Map)['moderation'], 'visible');
    expect(post.title, 'Paste drops bold in merged cells');
    expect(post.kind, BoardPostKind.bug);
    expect(post.contextJson, '{"app":"sheets"}');
    expect(changes.single.post, n);
    expect(changes.single.lists, isTrue);
    expect(h.undoLabels, hasLength(1));

    await h.undo();
    expect(post.deletedAt, isNotNull);

    await h.redo();
    expect(post.deletedAt, isNull);
  });

  group('Given an idea and a bug', () {
    late FakeBoardPost idea;
    late FakeBoardPost bug;
    setUp(() {
      idea = board.seedPost(title: 'Dark mode for slides', score: 3);
      bug = board.seedPost(
        title: 'Paste loses styles',
        kind: BoardPostKind.bug,
      );
    });

    test('when voting up then the vote counts, undo removes it and redo '
        'casts it again', () async {
      final r = await h.invoke('shell.board.vote', {
        'postNumber': idea.number,
        'value': 1,
      });
      expect(r.isOk, isTrue);
      expect(idea.votes[1], 1);

      await h.undo();
      expect(idea.votes.containsKey(1), isFalse);

      await h.redo();
      expect(idea.votes[1], 1);
    });

    test(
      'when switching an up vote to down then undo restores the up vote',
      () async {
        await h.invoke('shell.board.vote', {
          'postNumber': idea.number,
          'value': 1,
        });
        await h.invoke('shell.board.vote', {
          'postNumber': idea.number,
          'value': -1,
        });
        expect(idea.votes[1], -1);

        await h.undo();

        expect(idea.votes[1], 1);
      },
    );

    test('when voting down on a bug then the server refuses it and nothing '
        'is recorded', () async {
      await expectLater(
        h.invoke('shell.board.vote', {'postNumber': bug.number, 'value': -1}),
        throwsA(isA<WonkyException>()),
      );
      expect(h.undoLabels, isEmpty);
    });

    test('when commenting then undo deletes the comment and redo restores '
        'it', () async {
      final r = await h.invoke('shell.board.comment.add', {
        'postNumber': idea.number,
        'body': 'Yes **please**',
      });
      final uuid = (r.data! as Map)['uuid'] as String;
      expect(board.comments[uuid]!.deleted, isFalse);

      await h.undo();
      expect(board.comments[uuid]!.deleted, isTrue);

      await h.redo();
      expect(board.comments[uuid]!.deleted, isFalse);
    });

    test(
      'when editing a comment then undo writes the previous text back',
      () async {
        final c = board.seedComment(
          postNumber: idea.number,
          authorId: 1,
          body: 'v1',
        );
        await h.invoke('shell.board.comment.edit', {
          'uuid': c.uuid.uuid,
          'body': 'v2',
          'previousBody': 'v1',
          'postNumber': idea.number,
        });
        expect(c.body, 'v2');

        await h.undo();
        expect(c.body, 'v1');

        await h.redo();
        expect(c.body, 'v2');
      },
    );

    test('when deleting a comment then undo restores it', () async {
      final c = board.seedComment(postNumber: idea.number, authorId: 1);
      await h.invoke('shell.board.comment.delete', {'uuid': c.uuid.uuid});
      expect(c.deleted, isTrue);

      await h.undo();
      expect(c.deleted, isFalse);

      await h.redo();
      expect(c.deleted, isTrue);
    });

    test('when flagging then undo unflags and redo flags with the same '
        'reason', () async {
      await h.invoke('shell.board.flag', {
        'postNumber': bug.number,
        'reason': 'spam',
        'note': 'ads',
      });
      expect(board.flags['post:${bug.number}']![1], (
        BoardFlagReason.spam,
        'ads',
      ));

      await h.undo();
      expect(board.flags['post:${bug.number}']!.containsKey(1), isFalse);

      await h.redo();
      expect(board.flags['post:${bug.number}']![1]!.$1, BoardFlagReason.spam);
    });

    test(
      'when flagging without a reason headless then it is cancelled',
      () async {
        final r = await h.invoke('shell.board.flag', {
          'postNumber': bug.number,
        });

        expect(r.status, CommandStatus.cancelled);
        expect(board.flags, isEmpty);
      },
    );
  });

  group('Given my own open post', () {
    late FakeBoardPost mine;
    setUp(() => mine = board.seedPost(authorId: 1, title: 'Old title here'));

    test('when editing it then undo restores the title and body', () async {
      await h.invoke('shell.board.editPost', {
        'postNumber': mine.number,
        'title': 'A better title',
        'body': 'New body',
      });
      expect(mine.title, 'A better title');

      await h.undo();
      expect(
        (mine.title, mine.body),
        ('Old title here', 'It loses the **formatting**.'),
      );

      await h.redo();
      expect(mine.body, 'New body');
    });

    test('when deleting it then undo restores it', () async {
      await h.invoke('shell.board.deletePost', {'postNumber': mine.number});
      expect(mine.deletedAt, isNotNull);

      await h.undo();
      expect(mine.deletedAt, isNull);

      await h.redo();
      expect(mine.deletedAt, isNotNull);
    });
  });

  group('Given a published task', () {
    late FakeBoardTask task;
    setUp(() {
      final p = board.seedPost();
      task = board.seedTask(posts: [p.number]);
    });

    test('when claiming it then the claim code is returned, undo releases '
        'and redo claims again', () async {
      final r = await h.invoke('shell.board.claim', {
        'taskNumber': task.number,
      });
      expect((r.data! as Map)['claimCode'], isNotNull);
      expect(task.claimedById, 1);

      await h.undo();
      expect(task.claimedById, isNull);
      expect(task.status, BoardTaskStatus.published);

      await h.redo();
      expect(task.claimedById, 1);
    });

    test('when releasing my claim then undo claims it again', () async {
      await h.invoke('shell.board.claim', {'taskNumber': task.number});
      await h.invoke('shell.board.release', {'taskNumber': task.number});
      expect(task.claimedById, isNull);

      await h.undo();
      expect(task.claimedById, 1);
    });

    test('when someone else claimed it meanwhile then undoing my release is '
        'a conflict and the claim stays theirs', () async {
      await h.invoke('shell.board.claim', {'taskNumber': task.number});
      await h.invoke('shell.board.release', {'taskNumber': task.number});
      task
        ..status = BoardTaskStatus.claimed
        ..claimedById = 2
        ..claimExpiresAt = clock.now().add(const Duration(hours: 40));

      final outcome = await h.undo();

      expect(outcome!.partial, isTrue);
      expect(task.claimedById, 2);
    });

    test('when copying the prompt as the claimant then the full wrapped '
        'prompt with the claim code is returned', () async {
      await h.invoke('shell.board.claim', {'taskNumber': task.number});
      final r = await h.invoke('shell.board.copyPrompt', {
        'taskNumber': task.number,
      });

      final prompt = (r.data! as Map)['prompt'] as String;
      expect(prompt, startsWith('# Wonky task T-1:'));
      expect(prompt, contains('Wonky-Claim: ${task.claimCode}'));
      expect(h.undoLabels, hasLength(1), reason: 'only the claim');
    });

    test('when copying the prompt without a claim then it fails: the prompt '
        'comes with the claim', () async {
      final r = await h.invoke('shell.board.copyPrompt', {
        'taskNumber': task.number,
      });

      expect(r.status, CommandStatus.failed);
      expect(r.message, 'Claim this task to get the prompt.');
    });

    test('when commenting on the task then it is refused: tasks have no '
        'discussion', () async {
      await expectLater(
        h.invoke('shell.board.comment.add', {
          'taskNumber': task.number,
          'body': 'Can I take it?',
        }),
        throwsA(predicate((e) => '$e'.contains('taskNumber'))),
        reason: 'the command takes a post only',
      );
      await expectLater(
        board.addComment(
          const Uuid().v4obj(),
          taskNumber: task.number,
          body: 'Directly',
        ),
        throwsA(isA<WonkyException>()),
        reason: 'the server refuses it too',
      );
      expect(board.comments.values.where((c) => c.taskNumber != null), isEmpty);
      expect(h.undoLabels, isEmpty);
    });

    test('when looking at Unclaim this task then its icon is ban', () {
      final release = h.services.registry.byId('shell.board.release')!;

      expect(release.icon, LucideIcons.ban);
    });

    test('when copying the PR lines as the claimant then both lines are '
        'filled in', () async {
      await h.invoke('shell.board.claim', {'taskNumber': task.number});
      final r = await h.invoke('shell.board.copyClaimCode', {
        'taskNumber': task.number,
        'lines': true,
      });

      expect(
        (r.data! as Map)['text'],
        'Wonky-Task: T-1\nWonky-Claim: ${task.claimCode}',
      );
    });

    test('when copying the claim code without a claim then it fails', () async {
      final r = await h.invoke('shell.board.copyClaimCode', {
        'taskNumber': task.number,
      });

      expect(r.status, CommandStatus.failed);
    });
  });

  group('Given a signed-in non-admin', () {
    test('when an admin command is invoked then it is disabled', () async {
      final p = board.seedPost();
      await BoardHub.of(h.services).loadMe(force: true);

      expect(
        h.services.dispatcher.stateOf('shell.board.admin.decline', {
          'postNumber': p.number,
        }).enabled,
        isFalse,
      );
      await expectLater(
        h.invoke('shell.board.admin.decline', {
          'postNumber': p.number,
          'reason': 'No',
        }),
        throwsA(isA<CommandDisabled>()),
      );
    });
  });

  group('Given an admin', () {
    late FakeBoardPost post;
    setUp(() async {
      await asAdmin();
      post = board.seedPost(title: 'Merged cells', aiLabels: true);
    });

    test('when approving a held post then undo holds it again', () async {
      post.moderation = BoardModeration.held;
      await h.invoke('shell.board.admin.moderate', {
        'postNumber': post.number,
        'action': 'approve',
      });
      expect(post.moderation, BoardModeration.visible);

      await h.undo();
      expect(post.moderation, BoardModeration.held);

      await h.redo();
      expect(post.moderation, BoardModeration.visible);
    });

    test('when removing a post then undo restores it to visible', () async {
      await h.invoke('shell.board.admin.moderate', {
        'postNumber': post.number,
        'action': 'remove',
        'reason': 'Spam',
      });
      expect(post.moderation, BoardModeration.removed);

      await h.undo();
      expect(post.moderation, BoardModeration.visible);
    });

    test('when restoring a removed post then undo removes it with the old '
        'reason', () async {
      post
        ..moderation = BoardModeration.removed
        ..moderationReason = 'Spam';
      await h.invoke('shell.board.admin.moderate', {
        'postNumber': post.number,
        'action': 'restore',
      });

      await h.undo();

      expect(post.moderation, BoardModeration.removed);
      expect(post.moderationReason, 'Spam');
    });

    test('when approving a held comment then undo holds it again', () async {
      final c = board.seedComment(
        postNumber: post.number,
        moderation: BoardModeration.held,
      );
      await h.invoke('shell.board.admin.moderate', {
        'commentUuid': c.uuid.uuid,
        'action': 'approve',
      });
      expect(c.moderation, BoardModeration.visible);

      await h.undo();
      expect(c.moderation, BoardModeration.held);
    });

    test(
      'when setting labels then undo restores the previous labels',
      () async {
        await h.invoke('shell.board.admin.setLabels', {
          'postNumber': post.number,
          'area': 'write',
          'size': null,
        });
        expect(
          (post.area, post.size, post.aiLabels),
          (BoardArea.write, null, false),
        );

        await h.undo();
        expect((post.area, post.size), (BoardArea.sheets, BoardSize.small));

        await h.redo();
        expect(post.area, BoardArea.write);
      },
    );

    test('when applying the suggested title then undo writes the old title '
        'back', () async {
      post.suggestedTitle = 'Paste into merged cells drops styles';
      await h.invoke('shell.board.admin.applySuggestedTitle', {
        'postNumber': post.number,
      });
      expect(post.title, 'Paste into merged cells drops styles');

      await h.undo();
      expect(post.title, 'Merged cells');
    });

    test(
      'when editing and approving a held post then one undo reverts both',
      () async {
        post.moderation = BoardModeration.held;
        await h.invoke('shell.board.admin.editPost', {
          'postNumber': post.number,
          'title': 'Merged cells (edited)',
          'approve': true,
        });
        expect(post.moderation, BoardModeration.visible);

        await h.undo();

        expect(post.title, 'Merged cells');
        expect(post.moderation, BoardModeration.held);
      },
    );

    test(
      'when merging then votes move, undo unmerges and redo merges again',
      () async {
        final target = board.seedPost(title: 'Target', score: 1);
        post.votes[50] = 1;
        await h.invoke('shell.board.admin.merge', {
          'source': post.number,
          'target': target.number,
        });
        expect(post.status, BoardPostStatus.duplicate);
        expect(target.votes.containsKey(50), isTrue);

        await h.undo();
        expect(post.status, BoardPostStatus.open);
        expect(target.votes.containsKey(50), isFalse);

        await h.redo();
        expect(post.duplicateOf, target.number);
      },
    );

    test('when unmerging then undo merges again', () async {
      final target = board.seedPost(title: 'Target');
      await board.merge(post.number, target.number);
      await h.invoke('shell.board.admin.unmerge', {'postNumber': post.number});
      expect(post.status, BoardPostStatus.open);

      await h.undo();
      expect(post.duplicateOf, target.number);
    });

    test('when declining then undo reopens and redo declines again', () async {
      await h.invoke('shell.board.admin.decline', {
        'postNumber': post.number,
        'reason': 'Out of scope',
      });
      expect(post.status, BoardPostStatus.declined);

      await h.undo();
      expect(post.status, BoardPostStatus.open);

      await h.redo();
      expect(post.declineReason, 'Out of scope');
    });

    test('when reopening a declined post then undo declines it with the old '
        'reason', () async {
      await board.decline(post.number, "Won't fix");
      await h.invoke('shell.board.admin.reopen', {'postNumber': post.number});

      await h.undo();

      expect(post.status, BoardPostStatus.declined);
      expect(post.declineReason, "Won't fix");
    });

    test('when blocking the author then undo unblocks', () async {
      await h.invoke('shell.board.admin.block', {
        'postNumber': post.number,
        'reason': 'Spam',
      });
      expect(board.blockedUsers.keys, [2]);

      await h.undo();
      expect(board.blockedUsers, isEmpty);

      await h.redo();
      expect(board.blockedUsers.keys, [2]);
    });

    test('when creating a task then undo cancels it and redo creates a new '
        'draft', () async {
      final r = await h.invoke('shell.board.admin.createTask', {
        'postNumbers': [post.number],
        'title': 'Merged cells',
        'area': 'sheets',
        'size': 'small',
      });
      final n = (r.data! as Map)['taskNumber'] as int;
      expect(board.tasks[n]!.status, BoardTaskStatus.draft);

      await h.undo();
      expect(board.tasks[n]!.status, BoardTaskStatus.cancelled);

      await h.redo();
      final redone = board.tasks.values.last;
      expect(redone.number, isNot(n));
      expect(redone.status, BoardTaskStatus.draft);
      expect(redone.posts, [post.number]);
    });

    test('when creating a task headless without labels then the first '
        "post's title and labels are used", () async {
      final r = await h.invoke('shell.board.admin.createTask', {
        'postNumbers': [post.number],
      });

      final t = board.tasks[(r.data! as Map)['taskNumber']]!;
      expect(
        (t.title, t.area, t.size),
        ('Merged cells', BoardArea.sheets, BoardSize.small),
      );
    });

    group('and a draft task', () {
      late FakeBoardTask task;
      setUp(() {
        task = board.seedTask(
          status: BoardTaskStatus.draft,
          posts: [post.number],
          promptBody: 'v1',
        );
      });

      test(
        'when setting the prompt then undo writes the previous body back',
        () async {
          await h.invoke('shell.board.admin.setPrompt', {
            'taskNumber': task.number,
            'body': 'v2',
          });
          expect(task.promptBody, 'v2');

          await h.undo();
          expect(task.promptBody, 'v1');

          await h.redo();
          expect(task.promptBody, 'v2');
        },
      );

      test(
        'when regenerating the prompt then undo restores the edited body',
        () async {
          await h.invoke('shell.board.admin.regeneratePrompt', {
            'taskNumber': task.number,
          });
          expect(task.promptBody, contains('Regenerated'));

          await h.undo();
          expect(task.promptBody, 'v1');
        },
      );

      test('when regenerating while the AI writes in the background then the '
          'prompt is pending, undo keeps the previous body and drops the '
          'pending pass, and redo asks again', () async {
        board.writesPromptLater = true;

        final r = await h.invoke('shell.board.admin.regeneratePrompt', {
          'taskNumber': task.number,
        });
        expect((r.data! as Map)['promptPending'], isTrue);
        expect(task.promptPending, isTrue);
        expect(task.promptBody, 'v1');

        await h.undo();
        expect(task.promptPending, isFalse);
        expect(task.promptBody, 'v1');

        await h.redo();
        expect(task.promptPending, isTrue);
        expect(board.calls.where((c) => c.startsWith('regeneratePrompt')), [
          'regeneratePrompt ${task.number}',
          'regeneratePrompt ${task.number}',
        ]);
      });

      test('when publishing then posts are planned, undo returns it to draft '
          'and redo publishes again', () async {
        await h.invoke('shell.board.admin.publishTask', {
          'taskNumber': task.number,
        });
        expect(task.status, BoardTaskStatus.published);
        expect(post.status, BoardPostStatus.planned);

        await h.undo();
        expect(task.status, BoardTaskStatus.draft);

        await h.redo();
        expect(task.status, BoardTaskStatus.published);
      });

      test(
        'when editing the task then undo restores title, area and size',
        () async {
          await h.invoke('shell.board.admin.updateTask', {
            'taskNumber': task.number,
            'title': 'Renamed',
            'size': 'large',
          });
          expect((task.title, task.size), ('Renamed', BoardSize.large));

          await h.undo();
          expect(
            (task.title, task.size),
            ('Merged cells keep formatting', BoardSize.small),
          );
        },
      );

      test('when adding posts then undo restores the previous posts', () async {
        final other = board.seedPost(title: 'Other');
        await h.invoke('shell.board.admin.setTaskPosts', {
          'taskNumber': task.number,
          'add': [other.number],
        });
        expect(task.posts, [post.number, other.number]);

        await h.undo();
        expect(task.posts, [post.number]);
        expect(other.taskNumber, isNull);
      });

      test('when adding an issue while the AI writes in the background then '
          'the task waits as a draft for its new prompt', () async {
        board.writesPromptLater = true;
        final other = board.seedPost(title: 'Other');

        await h.invoke('shell.board.admin.setTaskPosts', {
          'taskNumber': task.number,
          'add': [other.number],
        });
        expect(task.status, BoardTaskStatus.draft);
        expect(task.promptPending, isTrue);

        board.finishPrompt(task.number, body: '## Goal\nBoth.');
        expect(task.status, BoardTaskStatus.published);
      });

      test('when merging another task into it then it keeps both issues, '
          'the other is cancelled, undo restores both and redo merges '
          'again', () async {
        final otherPost = board.seedPost(title: 'Other');
        final other = board.seedTask(title: 'Other', posts: [otherPost.number]);

        final r = await h.invoke('shell.board.admin.mergeTasks', {
          'taskNumbers': [other.number, task.number],
          'title': 'Both',
          'area': 'write',
          'size': 'medium',
        });
        expect((r.data! as Map)['taskNumber'], task.number);
        expect(task.posts, [post.number, otherPost.number]);
        expect((task.title, task.area), ('Both', BoardArea.write));
        expect(other.status, BoardTaskStatus.cancelled);
        expect(other.mergedInto, task.number);

        await h.undo();
        expect(task.posts, [post.number]);
        expect(task.title, 'Merged cells keep formatting');
        expect(other.status, BoardTaskStatus.published);
        expect(other.posts, [otherPost.number]);
        expect(otherPost.taskNumber, other.number);

        await h.redo();
        expect(other.status, BoardTaskStatus.cancelled);
        expect(task.posts, [post.number, otherPost.number]);
      });
    });

    group('and a claimed task', () {
      late FakeBoardTask task;
      setUp(() {
        task = board.seedTask(posts: [post.number], claimedById: 2);
      });

      test('when linking a pull request then it is in review and undo '
          'unlinks', () async {
        await h.invoke('shell.board.admin.linkPullRequest', {
          'taskNumber': task.number,
          'url': 'https://github.com/serverpod/wonky/pull/345',
        });
        expect(task.status, BoardTaskStatus.inReview);

        await h.undo();
        expect(task.pullRequestUrl, isNull);
        expect(task.status, BoardTaskStatus.claimed);
      });

      test(
        'when marking it done then undo returns to the previous status',
        () async {
          await h.invoke('shell.board.admin.markDone', {
            'taskNumber': task.number,
          });
          expect(task.status, BoardTaskStatus.done);
          expect(post.status, BoardPostStatus.done);

          await h.undo();
          expect(task.status, BoardTaskStatus.claimed);

          await h.redo();
          expect(task.status, BoardTaskStatus.done);
        },
      );

      test('when marking it shipped then undo returns it to done', () async {
        await h.invoke('shell.board.admin.markDone', {
          'taskNumber': task.number,
        });
        await h.invoke('shell.board.admin.markShipped', {
          'taskNumber': task.number,
        });
        expect(post.status, BoardPostStatus.shipped);

        await h.undo();
        expect(task.status, BoardTaskStatus.done);
      });

      test('when cancelling it then undo publishes it again (the claim is '
          'gone)', () async {
        await h.invoke('shell.board.admin.cancelTask', {
          'taskNumber': task.number,
        });
        expect(task.status, BoardTaskStatus.cancelled);

        await h.undo();
        expect(task.status, BoardTaskStatus.published);
      });

      test(
        'when an admin releases the claim then it is not undoable',
        () async {
          await h.invoke('shell.board.release', {'taskNumber': task.number});

          expect(task.claimedById, isNull);
          expect(h.undoLabels, isEmpty);
        },
      );
    });

    test(
      'when suggesting bundles then nothing goes on the undo stack',
      () async {
        board.seedSuggestion(postNumbers: [post.number]);
        final r = await h.invoke('shell.board.admin.suggestBundles');

        expect((r.data! as Map)['suggestions'], 1);
        expect(h.undoLabels, isEmpty);
      },
    );
  });
}
