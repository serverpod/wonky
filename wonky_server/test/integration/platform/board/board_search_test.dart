@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/board_search.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import '../../../support/board/board_harness.dart';

/// The board's search (specs/16 §6.4): prefix full-text matches, title
/// substrings, post numbers, special characters and ranking; and the tab
/// counts (§4.4).
void main() {
  group('Given search text helpers', () {
    test('when building a full-text query then words are AND-joined '
        'prefixes and operators are dropped', () {
      expect(
        BoardSearch.tsQuery("Sort & it's: !rows | (a) <-> x:*"),
        'sort:* & it & rows:*',
      );
    });

    test('when the text has no words then the full-text query is empty', () {
      expect(BoardSearch.tsQuery(r"%_' & : ! \ "), '');
    });

    test('when building a LIKE pattern then %, _ and the backslash are '
        'escaped and whitespace collapses', () {
      expect(
        BoardSearch.likePattern(r'  100%  a_b \x '),
        r'%100\% a\_b \\x%',
      );
    });

    final numbers = [
      ('12', 12),
      ('#12', 12),
      (' # 7 ', 7),
      ('12a', null),
      ('T-12', null),
      ('', null),
    ];
    for (final (text, n) in numbers) {
      test('when the text is "$text" then the post number is $n', () {
        expect(BoardSearch.postNumber(text), n);
      });
    }
  });

  withWonkyServerpod('Given board posts', (sessionBuilder, endpoints) {
    late BoardHarness h;
    late TestUser anna;
    late String w;
    setUp(() async {
      h = BoardHarness.install();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      w = BoardHarness.word();
    });
    tearDown(() => h.uninstall());

    BoardListQuery q(
      String query, {
      BoardSort sort = BoardSort.newest,
      BoardPostKind? kind,
    }) => BoardListQuery(
      kind: kind,
      statuses: const [],
      areas: const [],
      sizes: const [],
      sort: sort,
      query: query,
      mine: false,
      limit: 50,
    );

    Future<List<int>> search(
      String query, {
      BoardSort sort = BoardSort.newest,
    }) async => [
      for (final i in (await endpoints.board.list(
        TestUsers.unauthenticated(sessionBuilder),
        q(query, sort: sort),
      )).items)
        i.number,
    ];

    Future<BoardPostView> post(String title, {String? body}) =>
        BoardHarness.post(endpoints, anna, title: title, body: body);

    test('when searching for the start of words then prefixes match '
        '(sort finds Sorting)', () async {
      final p = await post('Sorting $w columns loses the header');

      expect(await search('sort $w'), [p.number]);
      expect(await search('sort ${w.substring(0, w.length - 3)} col'), [
        p.number,
      ]);
    });

    test('when every word must match then a missing word excludes the '
        'post', () async {
      await post('Sorting $w columns');

      expect(await search('sort $w zzqqnothing'), isEmpty);
    });

    test('when searching for part of a word in the title then the title '
        'substring matches (ort finds Sorting)', () async {
      final p = await post('Sorting x${w}y columns');
      final middle = w.substring(2, w.length - 1);

      expect(await search(middle), [p.number]);
      expect(await search('orting x${w.substring(0, w.length - 2)}'), [
        p.number,
      ]);
    });

    test('when searching for a post number with or without # then that '
        'post comes first', () async {
      final p = await post('Numbered post $w');

      expect((await search('${p.number}')).first, p.number);
      expect((await search('#${p.number}')).first, p.number);
    });

    test('when the text has % or _ then they match literally, not as '
        'wildcards', () async {
      final percent = await post('Rounds 100% to $w wrongly');
      final plain = await post('Rounds 1000 to $w wrongly');
      final underscore = await post('The cell_ref $w field');
      final noUnderscore = await post('The cellxref $w field');

      // "to" is a stop word: only the title substring can match, and an
      // unescaped % would also match "1000 to".
      final byPercent = await search('0% to');
      expect(byPercent, contains(percent.number));
      expect(byPercent, isNot(contains(plain.number)));
      // No full-text words; an unescaped _ would also match "lxr".
      final byUnderscore = await search('l_r');
      expect(byUnderscore, contains(underscore.number));
      expect(byUnderscore, isNot(contains(noUnderscore.number)));
    });

    // `$w` stands for the test's unique word.
    final special = [
      r"it's $w",
      r'$w & sorting',
      r'$w: sorting',
      r'!$w',
      r'$w | !(sorting) <-> x:*',
      r"\'%_ $w",
    ];
    for (final text in special) {
      test('when searching for "$text" then the query is safe and finds '
          'the post', () async {
        final p = await post("It's sorting $w");

        expect(await search(text.replaceAll(r'$w', w)), contains(p.number));
      });
    }

    test('when the text is an SQL injection attempt then it is only '
        'text', () async {
      final p = await post('Injection target $w');

      expect(
        await search("$w'; DROP TABLE board_post; --"),
        isEmpty,
        reason: 'the quote and the rest are search words',
      );
      expect(await search("x' OR '1'='1"), isNot(contains(p.number)));
      expect(await search(w), [p.number], reason: 'the table is intact');
    });

    test('when ranking then full-text rank comes first (title before '
        'body), then title substrings, then the sort', () async {
      final title = await post('Alpha $w in the title');
      final body = await post(
        'Beta has it in the body',
        body: 'The body mentions $w once.',
      );
      final substring = await post('Gamma x${w}y only as a substring');

      // Newest first would be the reverse order.
      expect(await search(w), [title.number, body.number, substring.number]);
      expect(await search(w, sort: BoardSort.top), [
        title.number,
        body.number,
        substring.number,
      ]);
    });

    test('when asking for similar posts then a word prefix matches', () async {
      final p = await post('Sorting $w columns');

      final similar = await endpoints.board.similar(
        anna.endpointSession,
        'Sort ${w.substring(0, w.length - 2)}',
        '',
        BoardPostKind.bug,
      );

      expect(similar.first.number, p.number);
    });

    group('and tasks', () {
      late TestUser admin;
      late TestUser bo;
      setUp(() async {
        admin = await BoardHarness.admin(sessionBuilder);
        bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      });

      Future<BoardCounts> counts() =>
          endpoints.board.counts(TestUsers.unauthenticated(sessionBuilder));

      test('when posting, publishing and claiming then the tab counts '
          'follow', () async {
        final before = await counts();
        final idea = await BoardHarness.post(
          endpoints,
          anna,
          kind: BoardPostKind.idea,
          title: 'An idea $w',
        );
        final bug = await post('A bug $w');
        final afterPosts = await counts();
        expect(afterPosts.ideas - before.ideas, 1);
        expect(afterPosts.bugs - before.bugs, 1);

        final task = await BoardHarness.publishedTask(endpoints, admin, [
          idea.number,
          bug.number,
        ]);
        final published = await counts();
        expect(published.upForGrabs - afterPosts.upForGrabs, 1);
        expect(published.claimed - afterPosts.claimed, 0);

        await endpoints.board.claimTask(bo.endpointSession, task.number);
        final claimed = await counts();
        expect(claimed.upForGrabs - published.upForGrabs, -1);
        expect(claimed.claimed - published.claimed, 1);

        final upForGrabs = await endpoints.board.listTasks(
          TestUsers.unauthenticated(sessionBuilder),
          [BoardTaskStatus.published],
          null,
          50,
        );
        final claimedList = await endpoints.board.listTasks(
          TestUsers.unauthenticated(sessionBuilder),
          [BoardTaskStatus.claimed, BoardTaskStatus.inReview],
          null,
          50,
        );
        expect(
          upForGrabs.items.map((t) => t.number),
          isNot(contains(task.number)),
        );
        expect(claimedList.items.map((t) => t.number), contains(task.number));
      });
    });
  });
}
