@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/search_indexes.dart';

import '../../support/wonky_serverpod.dart';

/// `SearchIndexes` (CQ-25): the trigram indexes Serverpod models cannot
/// declare are ensured at start, idempotently; the full-text expression
/// indexes of an earlier version are dropped (they made Serverpod's schema
/// check report a mismatch at every start).
void main() {
  withWonkyServerpod('Given the database', (sessionBuilder, endpoints) {
    Future<bool> exists(String name) async {
      final rows = await sessionBuilder.build().db.unsafeQuery(
        "SELECT 1 FROM pg_class WHERE relname = '$name'",
      );
      return rows.isNotEmpty;
    }

    test('when the indexes are ensured twice then the trigram indexes exist '
        'where pg_trgm is available, and nothing else', () async {
      final session = sessionBuilder.build();
      final available = await session.db.unsafeQuery(
        "SELECT 1 FROM pg_available_extensions WHERE name = 'pg_trgm'",
      );

      await SearchIndexes.ensure(session);
      final ready = await SearchIndexes.ensure(session);

      expect(SearchIndexes.trigramAvailable, available.isNotEmpty);
      expect(
        ready,
        available.isEmpty
            ? isEmpty
            : {'drive_item_name_trgm_idx', 'board_post_title_trgm_idx'},
      );
    });

    test(
      'when a retired full-text index exists then ensuring drops it',
      () async {
        final session = sessionBuilder.build();
        await session.db.unsafeExecute(
          'CREATE INDEX IF NOT EXISTS "drive_item_search_fts_idx" '
          "ON drive_item USING gin (to_tsvector('simple', coalesce(name, '')))",
        );
        expect(await exists('drive_item_search_fts_idx'), isTrue);

        await SearchIndexes.ensure(session);

        for (final name in SearchIndexes.retired) {
          expect(await exists(name), isFalse, reason: name);
        }
      },
    );

    for (final (table, alias, document) in [
      ('drive_item', 'd', SearchIndexes.driveDocument),
      ('board_post', 'p', SearchIndexes.boardDocument),
    ]) {
      test('when $table is searched with its document then the query '
          'runs without an index', () async {
        final session = sessionBuilder.build();
        await SearchIndexes.ensure(session);

        final rows = await session.db.unsafeQuery(
          'SELECT $alias.id FROM $table $alias '
          "WHERE $document @@ to_tsquery('simple', 'word:*')",
        );

        expect(rows, isEmpty);
      });
    }
  });
}
