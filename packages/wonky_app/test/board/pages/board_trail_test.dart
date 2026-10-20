import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/src/board/pages/board_trail.dart';
import 'package:wonky_client/wonky_client.dart';

/// The board's breadcrumb trail (specs/16 §4.3): derived from the board's
/// hierarchy (root › list › task › post), carried in the URL query, and
/// never a loop.
void main() {
  BoardTrail parse(String location) => BoardTrail.parse(Uri.parse(location))!;

  group('Given a board location', () {
    test('when parsed then the lists, posts, tasks and contribute map to '
        'their trails', () {
      expect(parse('/improvements'), BoardTrail.root);
      expect(
        parse('/improvements/bugs'),
        const BoardTrail(list: BoardTab.bugs),
      );
      expect(parse('/improvements/review').list, BoardTab.review);
      expect(parse('/improvements/contribute').contribute, isTrue);
      expect(parse('/improvements/p/5'), const BoardTrail(post: 5));
      expect(
        parse('/improvements/p/5?list=tasks&task=1'),
        const BoardTrail(list: BoardTab.tasks, task: 1, post: 5),
      );
      expect(
        parse('/improvements/t/2?list=claimed'),
        const BoardTrail(list: BoardTab.claimed, task: 2),
      );
      // Done lists finished issues only (specs/16 §4.4): a task under it
      // falls back to its own list.
      expect(parse('/improvements/t/2?list=done'), const BoardTrail(task: 2));
      expect(BoardTrail.parse(Uri.parse('/recent')), isNull);
      expect(BoardTrail.parse(Uri.parse('/improvements/p/x')), isNull);
    });

    test('when the query is unknown or contradicts the hierarchy then the '
        'defaults apply', () {
      expect(parse('/improvements/p/5?list=nope').list, isNull);
      expect(
        parse('/improvements/p/5?list=tasks').list,
        isNull,
        reason: 'Up for grabs lists no posts',
      );
      expect(
        parse('/improvements/p/5?list=bugs&task=1'),
        const BoardTrail(task: 1, post: 5),
        reason: 'a task is not under Bugs',
      );
      expect(parse('/improvements/t/2?list=improvements').list, isNull);
    });

    test('when a trail is written then its location round-trips', () {
      for (final l in [
        '/improvements',
        '/improvements/bugs',
        '/improvements/tasks',
        '/improvements/contribute',
        '/improvements/p/5',
        '/improvements/p/5?list=bugs',
        '/improvements/p/5?list=tasks&task=1',
        '/improvements/t/2',
        '/improvements/t/2?list=review',
        '/improvements/claimed',
        '/improvements/t/3?list=claimed',
        '/improvements/search?q=sort',
        '/improvements/search?q=dark+mode&closed=1&kind=bug',
        '/improvements/p/5?list=search&q=sort&kind=idea',
      ]) {
        expect(parse(l).location, l);
      }
    });
  });

  group('Given a search in the URL', () {
    test('when parsed then the search belongs to the list', () {
      expect(
        parse('/improvements/search?q=%20sort%20&closed=1&kind=idea'),
        const BoardTrail(
          list: BoardTab.search,
          search: BoardSearchQuery(
            'sort',
            closed: true,
            kind: BoardPostKind.idea,
          ),
        ),
      );
      for (final tab in ['bugs', 'done', 'tasks']) {
        expect(
          parse('/improvements/$tab?q=x&kind=idea').search,
          isNull,
          reason: 'a search is always the results view, never a tab',
        );
      }
      expect(parse('/improvements?q=x'), BoardTrail.root);
      expect(parse('/improvements/search?q=').search, isNull);
      expect(
        parse('/improvements/p/5?list=tasks&task=1&q=x').search,
        isNull,
        reason: 'a search never sits under a task',
      );
    });

    test('when a post opens from the results then the search travels with '
        'it and the list crumb returns to the results', () {
      const results = BoardTrail(
        list: BoardTab.search,
        search: BoardSearchQuery('sort'),
      );
      final post = results.openPost(5);
      expect(post.location, '/improvements/p/5?list=search&q=sort');
      expect(post.openPost(6).search, results.search, reason: 'siblings');
      expect(
        post.openTask(1).location,
        '/improvements/t/1',
        reason: 'the results hold no tasks: the task\'s own list',
      );
    });

    test('when a search starts, changes or ends then it is not a sibling '
        'move (Back returns to the list before it)', () {
      const bugs = BoardTrail(list: BoardTab.bugs);
      const searched = BoardTrail(
        list: BoardTab.search,
        search: BoardSearchQuery('x'),
      );
      expect(bugs.isSiblingOf(searched), isFalse);
      expect(searched.isSiblingOf(bugs), isFalse);
      expect(
        bugs.isSiblingOf(const BoardTrail(list: BoardTab.claimed)),
        isTrue,
      );
    });

    test('when computing the statuses then Include closed adds the closed '
        'ones', () {
      expect(BoardSearchQuery.statusesFor(BoardTab.bugs, null), {
        BoardPostStatus.open,
        BoardPostStatus.planned,
      });
      expect(
        BoardSearchQuery.statusesFor(
          BoardTab.search,
          const BoardSearchQuery('x', closed: true),
        ),
        BoardPostStatus.values.toSet(),
      );
      expect(BoardSearchQuery.statusesFor(BoardTab.done, null), {
        BoardPostStatus.done,
        BoardPostStatus.shipped,
      });
    });
  });

  group('Given a task status', () {
    final cases = {
      BoardTaskStatus.published: BoardTab.tasks,
      BoardTaskStatus.claimed: BoardTab.claimed,
      BoardTaskStatus.inReview: BoardTab.claimed,
      BoardTaskStatus.done: BoardTab.done,
      BoardTaskStatus.shipped: BoardTab.done,
    };
    for (final MapEntry(key: status, value: tab) in cases.entries) {
      test('when it is ${status.name} then its own list is ${tab.name}', () {
        expect(BoardTab.ofTask(status), tab);
      });
    }
  });

  group('Given the trail rules', () {
    const bugs = BoardTrail(list: BoardTab.bugs);
    const tasks = BoardTrail(list: BoardTab.tasks);

    test('when a post or task opens from a list then it goes under it', () {
      expect(bugs.openPost(4).location, '/improvements/p/4?list=bugs');
      expect(tasks.openTask(1).location, '/improvements/t/1?list=tasks');
      expect(
        tasks.openPost(4).location,
        '/improvements/p/4',
        reason: 'Up for grabs has no posts: the post\'s own list',
      );
      expect(
        bugs.openTask(1).location,
        '/improvements/t/1',
        reason: 'Bugs has no tasks: the task\'s own list',
      );
    });

    test(
      'when a linked post opens from a task then it goes under the task',
      () {
        final post = tasks.openTask(1).openPost(5);
        expect(post.location, '/improvements/p/5?list=tasks&task=1');
      },
    );

    test('when a post opens its task then the trail truncates to it, never '
        'post › task › post › task', () {
      final post = tasks.openTask(1).openPost(5);
      final task = post.openTask(1);
      expect(task.location, '/improvements/t/1?list=tasks');
      expect(task.openPost(5), post, reason: 'and back down, same trail');
      expect(
        bugs.openPost(4).openTask(1).location,
        '/improvements/t/1',
        reason: 'a post outside the task: the task under its own list',
      );
    });

    test('when another post opens from a post then it replaces it', () {
      final post = tasks.openTask(1).openPost(5);
      final sibling = post.openPost(7);
      expect(sibling.location, '/improvements/p/7?list=tasks&task=1');
      expect(post.isSiblingOf(sibling), isTrue);
      expect(
        bugs.openPost(4).openPost(8).location,
        '/improvements/p/8?list=bugs',
      );
    });

    test('when the trail is at its deepest then nothing goes deeper than '
        'root › list › task › post', () {
      var t = tasks.openTask(1).openPost(5);
      for (var i = 0; i < 5; i++) {
        t = t.openTask(i + 2).openPost(i + 10);
        expect(t.list, BoardTab.tasks);
        expect(t.post, i + 10);
        expect(t.task, i + 2);
      }
    });

    test('when moving at the same depth then it is a sibling move (replaces '
        'history), else not', () {
      expect(bugs.isSiblingOf(tasks), isTrue, reason: 'tab switch');
      expect(tasks.isSiblingOf(tasks.openTask(1)), isFalse);
      expect(tasks.openTask(1).isSiblingOf(tasks.openTask(2)), isTrue);
      expect(
        bugs.openPost(4).isSiblingOf(bugs.openPost(4).openTask(1)),
        isFalse,
      );
      expect(
        tasks.openTask(1).openPost(5).isSiblingOf(tasks.openTask(1)),
        isFalse,
        reason: 'up the trail',
      );
    });
  });
}
