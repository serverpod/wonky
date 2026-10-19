import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../common/search_indexes.dart';
import '../common/time.dart';
import 'board_access.dart';

/// Full-text search and the board list query (specs/16 §4.4, §6.4). The
/// search document is an expression with a GIN index (and a trigram index
/// on the title when `pg_trgm` exists) that [SearchIndexes] creates at
/// start, outside the models (a documented exception, specs/13 §3).
abstract final class BoardSearch {
  /// The indexed search document (must stay identical to the index).
  static const document = SearchIndexes.boardDocument;

  /// Votes of users who are not blocked right now (specs/16 §11).
  static const activeVoter =
      'NOT EXISTS (SELECT 1 FROM board_user_profile b '
      'WHERE b."userId" = v."userId" AND b."blockedAt" IS NOT NULL '
      'AND (b."blockedUntil" IS NULL OR b."blockedUntil" > @now))';

  /// The words of [text] for a tsquery: runs of letters and digits,
  /// lowercased, without one-letter words, at most [max]. Everything else
  /// (tsquery operators `& | ! : * ( ) <->`, quotes, LIKE wildcards) is a
  /// separator, so the result is always a valid `to_tsquery` operand list.
  static List<String> words(String text, {int max = 40}) {
    final out = <String>{};
    for (final m in RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(text)) {
      final w = m[0]!.toLowerCase();
      if (w.length < 2) continue;
      out.add(w);
      if (out.length >= max) break;
    }
    return [...out];
  }

  /// A `to_tsquery('english', …)` text over the [words] of [text], joined
  /// by [op] (`&` or `|`). Words of three or more characters are prefixes
  /// (`sort:*` finds *sorting*; the English config stems the prefix too).
  /// Empty when [text] has no words. Passed as a query parameter, never
  /// spliced into the SQL.
  static String tsQuery(String text, {String op = '&', int max = 40}) => [
    for (final w in words(text, max: max)) w.length >= 3 ? '$w:*' : w,
  ].join(' $op ');

  /// An OR query over the words of [text] (similar posts: any shared term
  /// counts, ranking does the rest).
  static String orQuery(String text) => tsQuery(text, op: '|');

  /// [text] as an `ILIKE` pattern matching it anywhere (`%text%`), with
  /// whitespace collapsed and the LIKE metacharacters `\`, `%` and `_`
  /// escaped (the default escape character is the backslash).
  static String likePattern(String text) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final escaped = t.replaceAllMapped(
      RegExp(r'[\\%_]'),
      (m) => '\\${m[0]}',
    );
    return '%$escaped%';
  }

  /// The post number in [text] (`12` or `#12`), or null.
  static int? postNumber(String text) {
    final m = RegExp(r'^#?\s*(\d{1,9})$').firstMatch(text.trim());
    return m == null ? null : int.parse(m[1]!);
  }

  /// Ids of visible posts in [statuses] that match [text] best (OR over its
  /// words), best first.
  static Future<List<int>> similarIds(
    Session session,
    String text, {
    BoardPostKind? kind,
    int limit = 10,
    int? excludeId,
    List<BoardPostStatus> statuses = const [
      BoardPostStatus.open,
      BoardPostStatus.planned,
      BoardPostStatus.done,
    ],
  }) async {
    final q = orQuery(text);
    if (q.isEmpty) return const [];
    final rows = await session.db.unsafeQuery(
      '''
      SELECT p.id FROM board_post p,
        to_tsquery('english', @q) query
      WHERE p.moderation = 'visible' AND p."deletedAt" IS NULL
        AND p.status IN (${_names(statuses)})
        ${kind == null ? '' : 'AND p.kind = @kind'}
        ${excludeId == null ? '' : 'AND p.id <> @exclude'}
        AND $document @@ query
      ORDER BY ts_rank_cd($document, query) DESC, p.score DESC, p.id DESC
      LIMIT @limit
      ''',
      parameters: QueryParameters.named({
        'q': q,
        'kind': ?kind?.name,
        'exclude': ?excludeId,
        'limit': limit,
      }),
    );
    return [for (final r in rows) r[0] as int];
  }

  static Future<List<BoardPost>> similarPosts(
    Session session,
    String text, {
    BoardPostKind? kind,
    int limit = 10,
    int? excludeId,
  }) async {
    final ids = await similarIds(
      session,
      text,
      kind: kind,
      limit: limit,
      excludeId: excludeId,
    );
    return byIds(session, ids);
  }

  /// Posts by [ids], in that order.
  static Future<List<BoardPost>> byIds(Session session, List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await BoardPost.db.find(
      session,
      where: (t) => t.id.inSet(ids.toSet()),
    );
    final byId = {for (final p in rows) p.id!: p};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  static String _names(Iterable<Enum> values) =>
      values.map((v) => "'${v.name}'").join(', ');

  /// Visible open and planned (ideas, bugs): the tab counts.
  static Future<(int, int)> openCounts(Session session) async {
    final rows = await session.db.unsafeQuery(
      "SELECT p.kind, count(*) FROM board_post p "
      "WHERE p.\"deletedAt\" IS NULL AND p.moderation = 'visible' "
      "AND p.status IN ('open', 'planned') GROUP BY p.kind",
    );
    final byKind = {for (final r in rows) '${r[0]}': r[1] as int};
    return (
      byKind[BoardPostKind.idea.name] ?? 0,
      byKind[BoardPostKind.bug.name] ?? 0,
    );
  }

  /// One page of the board list (specs/16 §4.4): ids in order and the
  /// total.
  static Future<(List<int>, int)> list(
    Session session,
    BoardCaller c,
    BoardListQuery query, {
    required int offset,
    required int limit,
  }) async {
    final statuses = query.statuses.isEmpty
        ? const [BoardPostStatus.open, BoardPostStatus.planned]
        : query.statuses;
    final search = _Search.of(query.query ?? '');
    final where = <String>[
      'p."deletedAt" IS NULL',
      'p.status IN (${_names(statuses)})',
      // The caller's own checking/held posts show in Mine.
      if (query.mine && c.signedIn)
        '(p.moderation = \'visible\' OR (p."authorId" = @me '
            'AND p.moderation IN (\'checking\', \'held\')))'
      else
        "p.moderation = 'visible'",
      if (query.kind != null) 'p.kind = @kind',
      if (query.areas.isNotEmpty) 'p.area IN (${_names(query.areas)})',
      if (query.sizes.isNotEmpty) 'p.size IN (${_names(query.sizes)})',
      if (query.mine)
        c.signedIn
            ? '(p."authorId" = @me OR EXISTS (SELECT 1 FROM board_vote mv '
                  'WHERE mv."postId" = p.id AND mv."userId" = @me))'
            : 'FALSE',
      if (search != null) search.where,
    ];
    final now = nowUtc();
    final params = <String, Object?>{
      if (query.mine && c.signedIn) 'me': c.userId,
      'kind': ?query.kind?.name,
      ...?search?.parameters,
    };
    final whereSql = where.join(' AND ');
    final countRows = await session.db.unsafeQuery(
      'SELECT count(*) FROM board_post p WHERE $whereSql',
      parameters: QueryParameters.named(params),
    );
    final total = countRows.first[0] as int;
    const trending =
        '(SELECT COALESCE(SUM(v.value), 0) FROM board_vote v '
        'WHERE v."postId" = p.id AND v."createdAt" > @since '
        'AND $activeVoter)';
    // A search ranks first (the post number, full-text rank, a title
    // substring hit), then the list's sort.
    final order = [
      ...?search?.order,
      ...switch (query.sort) {
        BoardSort.trending => ['$trending DESC', 'p.score DESC', 'p.id DESC'],
        BoardSort.top => ['p.score DESC', 'p.id DESC'],
        BoardSort.newest => ['p."createdAt" DESC', 'p.id DESC'],
        BoardSort.discussed => [
          'p."commentCount" DESC',
          'p.score DESC',
          'p.id DESC',
        ],
      },
    ].join(', ');
    final rows = await session.db.unsafeQuery(
      'SELECT p.id FROM board_post p WHERE $whereSql '
      'ORDER BY $order LIMIT @limit OFFSET @offset',
      parameters: QueryParameters.named({
        ...params,
        if (query.sort == BoardSort.trending) ...{
          'since': now.subtract(const Duration(days: 14)),
          'now': now,
        },
        'limit': limit,
        'offset': offset,
      }),
    );
    return ([for (final r in rows) r[0] as int], total);
  }
}

/// The search of a board list (specs/16 §6.4): a post matches when its
/// document matches every word as a prefix (full-text), its title contains
/// the text (`ILIKE`, metacharacters escaped), or the text is its number.
/// All user text travels as query parameters.
class _Search {
  _Search._(this.tsQuery, this.like, this.number);

  /// Null when [text] is blank.
  static _Search? of(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return _Search._(
      BoardSearch.tsQuery(t, max: 16),
      BoardSearch.likePattern(t),
      BoardSearch.postNumber(t),
    );
  }

  final String tsQuery;
  final String like;
  final int? number;

  static const _fts = "${BoardSearch.document} @@ to_tsquery('english', @sq)";
  static const _title = 'p.title ILIKE @slike';

  String get where {
    final any = [
      if (tsQuery.isNotEmpty) _fts,
      _title,
      if (number != null) 'p.id = @snum',
    ];
    return '(${any.join(' OR ')})';
  }

  List<String> get order => [
    if (number != null) '(p.id = @snum) DESC',
    if (tsQuery.isNotEmpty)
      "ts_rank_cd(${BoardSearch.document}, to_tsquery('english', @sq)) DESC",
    '($_title) DESC',
  ];

  Map<String, Object?> get parameters => {
    if (tsQuery.isNotEmpty) 'sq': tsQuery,
    'slike': like,
    'snum': ?number,
  };
}
