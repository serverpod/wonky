import 'package:serverpod/serverpod.dart';

/// Trigram indexes that Serverpod models cannot express (`gin_trgm_ops`),
/// created at server start (specs/13 §3 "Search indexes", CQ-25).
///
/// They are a documented exception to "the schema equals `definition.sql`":
/// a migration's SQL is never run on databases created from
/// `definition.sql`, so the indexes are ensured here instead, idempotently
/// (`IF NOT EXISTS`) and without blocking writes (`CONCURRENTLY`). Every
/// start recreates any that are missing or invalid.
///
/// `pg_trgm` (trusted, so the database owner may create it) speeds up the
/// name substring match (`ILIKE '%x%'`); when the extension is not
/// available the trigram indexes are skipped and the substring match scans.
///
/// The full-text documents ([driveDocument], [boardDocument]) have no index
/// for now: Serverpod's schema check reports expression indexes as a
/// mismatch at every start, and a clean check is worth more than the speed
/// while the tables are small. Search scans them (TODO.md). Indexes of an
/// earlier version ([retired]) are dropped.
abstract final class SearchIndexes {
  /// The search document of a drive item (`simple` configuration: no
  /// stemming, every language).
  static const driveDocument =
      "to_tsvector('simple', coalesce(d.name, '') || ' ' || "
      "coalesce(d.description, '') || ' ' || coalesce(d.\"searchText\", ''))";

  /// The search document of a board post (title words rank first).
  static const boardDocument =
      "(setweight(to_tsvector('english', p.title), 'A') || "
      "setweight(to_tsvector('english', p.body), 'B'))";

  /// The indexes by name: (table, `USING …` definition, needs pg_trgm).
  static const indexes = <String, (String, String, bool)>{
    'drive_item_name_trgm_idx': ('drive_item', 'gin (name gin_trgm_ops)', true),
    'board_post_title_trgm_idx': (
      'board_post',
      'gin (title gin_trgm_ops)',
      true,
    ),
  };

  /// Indexes created by an earlier version, dropped by [ensure].
  static const retired = [
    'drive_item_search_fts_idx',
    'board_post_search_fts_idx',
  ];

  /// Whether `pg_trgm` was available at the last [ensure].
  static bool trigramAvailable = false;

  /// Creates the missing [indexes] (and `pg_trgm`). Returns the names of
  /// the indexes that exist and are valid afterwards. Never throws: a
  /// failed index is logged and retried at the next start.
  static Future<Set<String>> ensure(Session session) async {
    trigramAvailable = await _ensureTrigram(session);
    for (final name in retired) {
      try {
        await session.db.unsafeExecute(
          'DROP INDEX CONCURRENTLY IF EXISTS "$name"',
        );
      } on Object catch (e) {
        session.log(
          'Retired search index $name could not be dropped: $e',
          level: LogLevel.warning,
        );
      }
    }
    final ready = <String>{};
    for (final MapEntry(key: name, value: (table, using, trigram))
        in indexes.entries) {
      if (trigram && !trigramAvailable) continue;
      try {
        if (await _valid(session, name)) {
          ready.add(name);
          continue;
        }
        // A failed concurrent build leaves an invalid index behind.
        await session.db.unsafeExecute(
          'DROP INDEX CONCURRENTLY IF EXISTS "$name"',
        );
        await session.db.unsafeExecute(
          'CREATE INDEX CONCURRENTLY IF NOT EXISTS "$name" ON "$table" '
          'USING $using',
        );
        if (await _valid(session, name)) ready.add(name);
      } on Object catch (e, st) {
        session.log(
          'Search index $name could not be created: $e',
          level: LogLevel.warning,
          exception: e,
          stackTrace: st,
        );
      }
    }
    return ready;
  }

  static Future<bool> _ensureTrigram(Session session) async {
    try {
      final available = await session.db.unsafeQuery(
        "SELECT 1 FROM pg_available_extensions WHERE name = 'pg_trgm'",
      );
      if (available.isEmpty) return false;
      await session.db.unsafeExecute('CREATE EXTENSION IF NOT EXISTS pg_trgm');
      return true;
    } on Object catch (e) {
      session.log(
        'pg_trgm is not available ($e); name substring search scans.',
        level: LogLevel.info,
      );
      return false;
    }
  }

  static Future<bool> _valid(Session session, String name) async {
    final rows = await session.db.unsafeQuery(
      'SELECT i.indisvalid FROM pg_class c '
      'JOIN pg_index i ON i.indexrelid = c.oid '
      'WHERE c.relname = @name',
      parameters: QueryParameters.named({'name': name}),
    );
    return rows.isNotEmpty && rows.first[0] == true;
  }
}
