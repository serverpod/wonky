import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/search_indexes.dart';
import '../common/time.dart';
import '../sharing/access_service.dart';
import 'drive_views.dart';
import 'kind_masks.dart';

/// `drive.list` and `drive.search` in SQL (specs/05 §2, CQ-25): the view,
/// visibility, kind/owner/category/folder filters and the sort run in the
/// database, pages are cut with a keyset cursor, and views are built for
/// the page only. Cost grows with the page size, not with the number of
/// items the caller can see.
abstract final class DriveListing {
  /// Largest page of `drive.list`.
  static const maxListPage = 500;

  /// Largest page of `drive.search`.
  static const maxSearchPage = 200;

  /// Items the caller can see: owned, granted (direct or inherited, not
  /// expired) or with a link role (as `AccessService.rolesFor`).
  static const _visible =
      '(d."ownerId" = @me'
      ' OR EXISTS (SELECT 1 FROM drive_item_permission p'
      ' WHERE p."itemId" = d.id AND p."userId" = @me'
      ' AND (p."expiresAt" IS NULL OR p."expiresAt" > @now))'
      ' OR EXISTS (SELECT 1 FROM share_link l'
      ' WHERE l."itemId" = d.id AND l.role IS NOT NULL))';

  /// Search reaches link items only once the caller opened them (a user
  /// state row exists).
  static const _searchVisible =
      '(d."ownerId" = @me'
      ' OR EXISTS (SELECT 1 FROM drive_item_permission p'
      ' WHERE p."itemId" = d.id AND p."userId" = @me'
      ' AND (p."expiresAt" IS NULL OR p."expiresAt" > @now))'
      ' OR (s."itemId" IS NOT NULL AND EXISTS (SELECT 1 FROM share_link l'
      ' WHERE l."itemId" = d.id AND l.role IS NOT NULL)))';

  /// (v2) Files still uploading only for their uploader; failed never.
  static const _listable =
      '(d."uploadState" IS NULL OR d."uploadState" = \'ready\''
      ' OR (d."uploadState" = \'uploading\' AND d."ownerId" = @me))';

  /// Search finds ready files only.
  static const _searchable =
      '(d."uploadState" IS NULL OR d."uploadState" = \'ready\')';

  static const _fromWithState =
      'FROM drive_item d LEFT JOIN drive_item_user_state s'
      ' ON s."itemId" = d.id AND s."userId" = @me';

  // ------------------------------------------------------------------ list

  /// One page of [filter]'s view (see the class comment).
  static Future<DriveListPage> list(
    Session session,
    Actor actor, {
    UuidValue? folderUuid,
    required DriveListFilter filter,
    required DriveSort sort,
    String? cursor,
    int limit = 100,
  }) async {
    final me = actor.userId;
    final params = <String, Object?>{'me': me, 'now': nowUtc()};
    final where = <String>[];
    switch (filter.view) {
      case DriveView.folder:
        if (folderUuid == null) {
          where.add(
            'd."trashedAt" IS NULL AND ((d."ownerId" = @me AND '
            'd."parentId" IS NULL) OR s."shortcutParentId" = 0)',
          );
        } else {
          final (folder, _) = await AccessService.require(
            session,
            actor,
            folderUuid,
            Role.viewer,
          );
          if (folder.kind != DriveItemKind.folder) {
            throw Errors.invalid('The item is not a folder.');
          }
          params['folder'] = folder.id!;
          where.add(
            'd."trashedAt" IS NULL AND (d."parentId" = @folder OR '
            's."shortcutParentId" = @folder)',
          );
        }
      case DriveView.sharedWithMe:
        where.add(
          'd."trashedAt" IS NULL AND d."ownerId" <> @me AND ('
          'EXISTS (SELECT 1 FROM drive_item_permission g'
          ' WHERE g."itemId" = d.id AND g."userId" = @me'
          ' AND g."inheritedFromId" IS NULL)'
          ' OR s."viaLink" = true)',
        );
      case DriveView.starred:
        where.add('d."trashedAt" IS NULL AND s.starred = true');
      case DriveView.recent:
        where.add('d."trashedAt" IS NULL AND s."lastOpenedAt" IS NOT NULL');
      case DriveView.offline:
        where.add('d."trashedAt" IS NULL AND s."pinnedOffline" = true');
      case DriveView.trash:
        // Only the top of each trashed subtree.
        where.add(
          'd."ownerId" = @me AND d."trashedAt" IS NOT NULL AND NOT EXISTS ('
          'SELECT 1 FROM drive_item pp WHERE pp.id = d."parentId"'
          ' AND pp."trashedAt" = d."trashedAt")',
        );
    }
    where
      ..add(_visible)
      ..add(_listable);
    _addFilters(
      where,
      params,
      kinds: filter.kinds,
      owner: filter.owner,
      categories: filter.fileCategories,
      foldersContaining: filter.foldersContaining,
    );
    final effective = filter.view == DriveView.recent
        ? DriveSort(
            field: DriveSortField.lastOpenedByMe,
            descending: true,
            foldersFirst: false,
          )
        : sort;
    final keys = _keysOf(effective);
    final signature = [
      'l',
      filter.view.name,
      folderUuid?.uuid ?? '',
      effective.field.name,
      effective.descending,
      effective.foldersFirst,
    ].join('|');
    final after = _decodeCursor(cursor, signature, keys);
    if (after != null) where.add(_after(keys, after, params));
    final pageSize = limit.clamp(1, maxListPage);
    params['limit'] = pageSize + 1;
    final rows = await session.db.unsafeQuery(
      'SELECT d.id, ${[for (final k in keys) k.select].join(', ')} '
      '$_fromWithState WHERE ${where.join(' AND ')} '
      'ORDER BY ${[for (final k in keys) '${k.order} ${k.desc ? 'DESC' : 'ASC'}'].join(', ')} '
      'LIMIT @limit',
      parameters: QueryParameters.named(params),
    );
    final more = rows.length > pageSize;
    final pageRows = more ? rows.sublist(0, pageSize) : rows;
    final views = await _views(session, me, [
      for (final r in pageRows) r[0]! as int,
    ]);
    return DriveListPage(
      items: views,
      nextCursor: more
          ? _encodeCursor(signature, keys, [
              for (var i = 0; i < keys.length; i++) pageRows.last[i + 1],
            ])
          : null,
    );
  }

  // ---------------------------------------------------------------- search

  /// Full-text search over name, description and extracted content of the
  /// items the caller can access (Postgres `simple` text search with prefix
  /// matching on [SearchIndexes.driveDocument], plus substring matching on
  /// names), best first, then newest.
  static Future<DriveListPage> search(
    Session session,
    Actor actor,
    String query, {
    required DriveSearchFilters filters,
    String? cursor,
    int limit = 50,
  }) async {
    final terms = RegExp(
      r'[\p{L}\p{N}]+',
      unicode: true,
    ).allMatches(query.toLowerCase()).map((m) => m[0]!).take(8).toList();
    if (terms.isEmpty) return DriveListPage(items: const []);
    final me = actor.userId;
    final params = <String, Object?>{
      'me': me,
      'now': nowUtc(),
      'q': terms.map((t) => '$t:*').join(' & '),
      'like':
          '%${query.trim().replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%',
    };
    final where = <String>[
      'd."trashedAt" IS NULL',
      _searchable,
      _searchVisible,
    ];
    _addFilters(
      where,
      params,
      kinds: filters.kinds,
      owner: filters.owner,
      categories: filters.fileCategories,
    );
    if (filters.modifiedAfter != null) {
      params['after'] = filters.modifiedAfter!.toUtc();
      where.add('d."modifiedAt" > @after');
    }
    if (filters.modifiedBefore != null) {
      params['before'] = filters.modifiedBefore!.toUtc();
      where.add('d."modifiedAt" < @before');
    }
    if (filters.sharedOnly) {
      // Shared with or by the caller (`DriveItemView.shared` or not owned).
      where.add(
        '(d."ownerId" <> @me'
        ' OR EXISTS (SELECT 1 FROM drive_item_permission sp'
        ' WHERE sp."itemId" = d.id AND (sp."userId" IS DISTINCT FROM d."ownerId"'
        ' OR sp."invitedEmail" IS NOT NULL))'
        ' OR EXISTS (SELECT 1 FROM share_link sl'
        ' WHERE sl."itemId" = d.id AND sl.role IS NOT NULL))',
      );
    }
    const doc = SearchIndexes.driveDocument;
    where.add('($doc @@ query OR d.name ILIKE @like)');
    final signature = [
      's',
      query.trim(),
      filters.kinds?.map((k) => k.name).join(',') ?? '',
      filters.owner.name,
      filters.sharedOnly,
    ].join('|');
    const keys = [
      _Key('x.rank', 'x.rank', true, _KeyType.real),
      _Key('x."modifiedAt"', 'x."modifiedAt"', true, _KeyType.time),
      _Key('x.id', 'x.id', true, _KeyType.int),
    ];
    final after = _decodeCursor(cursor, signature, keys);
    final pageSize = limit.clamp(1, maxSearchPage);
    params['limit'] = pageSize + 1;
    final rows = await session.db.unsafeQuery(
      'SELECT x.id, x.rank, x."modifiedAt" FROM ('
      'SELECT d.id, ts_rank($doc, query) AS rank, d."modifiedAt" '
      '$_fromWithState, to_tsquery(\'simple\', @q) query '
      'WHERE ${where.join(' AND ')}) x '
      '${after == null ? '' : 'WHERE ${_after(keys, after, params)} '}'
      'ORDER BY x.rank DESC, x."modifiedAt" DESC, x.id DESC '
      'LIMIT @limit',
      parameters: QueryParameters.named(params),
    );
    final more = rows.length > pageSize;
    final pageRows = more ? rows.sublist(0, pageSize) : rows;
    final views = await _views(session, me, [
      for (final r in pageRows) r[0]! as int,
    ]);
    return DriveListPage(
      items: views,
      nextCursor: more
          ? _encodeCursor(signature, keys, [
              pageRows.last[1],
              pageRows.last[2],
              pageRows.last[0],
            ])
          : null,
    );
  }

  // ------------------------------------------------------------- templates

  /// Ids of the published templates the caller can see (newest first, at
  /// most [limit]); visibility is decided in SQL, so the caller's own
  /// templates never fall out of a global limit.
  static Future<List<DriveItem>> visibleTemplates(
    Session session,
    Actor actor, {
    DriveItemKind? kind,
    int limit = 500,
  }) async {
    final rows = await session.db.unsafeQuery(
      'SELECT d.id FROM drive_item d '
      'WHERE d."templateOf" IS NOT NULL AND d."trashedAt" IS NULL '
      '${kind == null ? '' : "AND d.kind = '${kind.name}' "}'
      'AND $_visible '
      'ORDER BY d."modifiedAt" DESC, d.id DESC LIMIT @limit',
      parameters: QueryParameters.named({
        'me': actor.userId,
        'now': nowUtc(),
        'limit': limit,
      }),
    );
    return _items(session, [for (final r in rows) r[0]! as int]);
  }

  // --------------------------------------------------------------- helpers

  static void _addFilters(
    List<String> where,
    Map<String, Object?> params, {
    List<DriveItemKind>? kinds,
    DriveOwnerFilter owner = DriveOwnerFilter.anyone,
    List<FileCategory>? categories,
    DriveItemKind? foldersContaining,
  }) {
    // Enum names are constants: safe to inline.
    if (kinds != null && kinds.isNotEmpty) {
      where.add('d.kind IN (${kinds.map((k) => "'${k.name}'").join(', ')})');
    }
    switch (owner) {
      case DriveOwnerFilter.anyone:
        break;
      case DriveOwnerFilter.me:
        where.add('d."ownerId" = @me');
      case DriveOwnerFilter.notMe:
        where.add('d."ownerId" <> @me');
    }
    if (categories != null && categories.isNotEmpty) {
      where.add(
        "(d.kind <> 'file' OR d.\"fileCategory\" IN "
        '(${categories.map((c) => "'${c.name}'").join(', ')}))',
      );
    }
    if (foldersContaining != null) {
      params['kindBit'] = KindMasks.bit(foldersContaining);
      where.add("(d.kind <> 'folder' OR (d.\"kindMask\" & @kindBit) <> 0)");
    }
  }

  /// The sort keys of [sort]: folders first (optional), the field, the id.
  /// Missing per-user dates sort as the smallest value (as before: first
  /// ascending, last descending).
  static List<_Key> _keysOf(DriveSort sort) {
    final desc = sort.descending;
    return [
      if (sort.foldersFirst)
        const _Key(
          "CASE WHEN d.kind = 'folder' THEN 0 ELSE 1 END",
          "CASE WHEN d.kind = 'folder' THEN 0 ELSE 1 END",
          false,
          _KeyType.int,
        ),
      switch (sort.field) {
        DriveSortField.name => _Key(
          'lower(d.name) COLLATE "C"',
          'lower(d.name)',
          desc,
          _KeyType.text,
        ),
        DriveSortField.modifiedAt => _Key(
          'd."modifiedAt"',
          'd."modifiedAt"',
          desc,
          _KeyType.time,
        ),
        DriveSortField.createdAt => _Key(
          'd."createdAt"',
          'd."createdAt"',
          desc,
          _KeyType.time,
        ),
        DriveSortField.size => _Key(
          'd."sizeBytes"',
          'd."sizeBytes"',
          desc,
          _KeyType.int,
        ),
        DriveSortField.lastOpenedByMe => _Key(
          'COALESCE(s."lastOpenedAt", \'-infinity\'::timestamp)',
          's."lastOpenedAt"',
          desc,
          _KeyType.time,
        ),
        DriveSortField.lastModifiedByMe => _Key(
          'COALESCE(s."lastEditedAt", \'-infinity\'::timestamp)',
          's."lastEditedAt"',
          desc,
          _KeyType.time,
        ),
      },
      const _Key('d.id', 'd.id', false, _KeyType.int),
    ];
  }

  /// Rows after the cursor [values] in the order of [keys]:
  /// `k1 > v1 OR (k1 = v1 AND (k2 > v2 OR …))` (`<` for descending keys).
  static String _after(
    List<_Key> keys,
    List<Object?> values,
    Map<String, Object?> params,
  ) {
    String value(int i) {
      final v = values[i];
      if (v == null) return "'-infinity'::timestamp";
      params['k$i'] = v;
      return '@k$i';
    }

    String cond(int i) {
      final k = keys[i];
      final op = k.desc ? '<' : '>';
      final v = value(i);
      if (i == keys.length - 1) return '${k.order} $op $v';
      return '(${k.order} $op $v OR (${k.order} = $v AND ${cond(i + 1)}))';
    }

    return cond(0);
  }

  static String _encodeCursor(
    String signature,
    List<_Key> keys,
    List<Object?> values,
  ) => base64Url.encode(
    utf8.encode(
      jsonEncode({
        's': signature,
        'k': [
          for (final (i, v) in values.indexed)
            switch (keys[i].type) {
              _KeyType.time =>
                v == null ? null : (v as DateTime).microsecondsSinceEpoch,
              _ => v,
            },
        ],
      }),
    ),
  );

  /// The key values of [cursor], or null for the first page. A cursor of
  /// another list, sort or format is refused.
  static List<Object?>? _decodeCursor(
    String? cursor,
    String signature,
    List<_Key> keys,
  ) {
    if (cursor == null || cursor.isEmpty) return null;
    try {
      final m = jsonDecode(utf8.decode(base64Url.decode(cursor))) as Map;
      final k = m['k'] as List;
      if (m['s'] != signature || k.length != keys.length) {
        throw const FormatException();
      }
      return [
        for (final (i, v) in k.indexed)
          switch (keys[i].type) {
            _KeyType.time =>
              v == null
                  ? null
                  : DateTime.fromMicrosecondsSinceEpoch(
                      (v as num).toInt(),
                      isUtc: true,
                    ),
            _KeyType.int => (v as num).toInt(),
            _KeyType.real => (v as num).toDouble(),
            _KeyType.text => v as String,
          },
      ];
    } on Object {
      throw Errors.invalid(
        'The page cursor is not valid for this list. Load it again.',
      );
    }
  }

  static Future<List<DriveItem>> _items(
    Session session,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final items = await DriveItem.db.find(
      session,
      where: (t) => t.id.inSet(ids.toSet()),
    );
    final byId = {for (final i in items) i.id!: i};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Views of [ids] in this order.
  static Future<List<DriveItemView>> _views(
    Session session,
    int me,
    List<int> ids,
  ) async {
    final items = await _items(session, ids);
    final roles = await AccessService.rolesFor(session, me, items);
    return DriveViews.build(session, me, items, roles: roles);
  }
}

enum _KeyType { int, real, text, time }

/// One sort key: [order] is the expression sorted and compared on,
/// [select] the value read for the cursor.
final class _Key {
  const _Key(this.order, this.select, this.desc, this.type);

  final String order;
  final String select;
  final bool desc;
  final _KeyType type;
}
