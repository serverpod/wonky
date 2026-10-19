import 'package:serverpod/serverpod.dart';

/// Storage parameters of RevLog domain tables that Serverpod models cannot
/// express, set at server start (RevLog spec 05 §3.3).
///
/// Like the search indexes (`SearchIndexes`), they are a documented
/// exception to "the schema equals `definition.sql`": a migration's SQL is
/// never run on databases created from `definition.sql`, so they are
/// ensured here, idempotently. `ALTER TABLE … SET (fillfactor)` rewrites
/// nothing and takes a short lock; it applies to pages written afterwards.
abstract final class RevStorage {
  /// `fillfactor` per table. The cell table keeps 15 % of every page free,
  /// so an op that rewrites cells (typing, pastes, server changes) can
  /// update them in place (HOT: no index writes) instead of moving every
  /// row version to another page and inserting it into the three indexes.
  static const fillfactor = <String, int>{'cell': 85};

  /// Sets the missing parameters. Returns the tables changed. Never
  /// throws: a failure is logged and retried at the next start.
  static Future<List<String>> ensure(Session session) async {
    final changed = <String>[];
    for (final MapEntry(key: table, value: percent) in fillfactor.entries) {
      try {
        final rows = await session.db.unsafeQuery(
          'SELECT reloptions FROM pg_class WHERE relname = @t '
          "AND relkind = 'r'",
          parameters: QueryParameters.named({'t': table}),
        );
        if (rows.isEmpty) continue;
        final options = (rows.first[0] as List?)?.cast<String>() ?? const [];
        if (options.contains('fillfactor=$percent')) continue;
        await session.db.unsafeExecute(
          'ALTER TABLE "$table" SET (fillfactor = $percent)',
        );
        changed.add(table);
      } on Object catch (e, st) {
        session.log(
          'The fillfactor of $table could not be set: $e',
          level: LogLevel.warning,
          exception: e,
          stackTrace: st,
        );
      }
    }
    return changed;
  }
}

/// Fresh planner statistics after large writes (RevLog spec 05 §7.2).
///
/// A cell page reads one sheet's rows by `(sheetId, rowId)`. When the
/// statistics predate a big sheet, Postgres estimates that sheet at about
/// one row and may read it through the `(sheetId, columnId)` index, which
/// scans the whole sheet for every page (seconds instead of milliseconds
/// at 1M cells). Autovacuum analyzes only after 10 % of a table changed,
/// so the sequencer counts the rows it inserts and analyzes the table in
/// the background after every [analyzeAfterRows].
abstract final class RevAnalyze {
  /// Inserted rows of a table between two analyses.
  static int analyzeAfterRows = 100000;

  /// Tables watched (the per-sheet tables of the bindings).
  static const tables = {'cell'};

  static final Map<String, int> _inserted = {};
  static final Set<String> _running = {};

  /// Analyses started (tests).
  static int started = 0;

  /// The last analysis started (tests).
  static Future<void>? last;

  /// Records [rows] committed inserts into [table]; starts an `ANALYZE` in
  /// the background once [analyzeAfterRows] have accumulated.
  static void inserted(Serverpod pod, String table, int rows) {
    if (rows <= 0 || !tables.contains(table)) return;
    final n = (_inserted[table] ?? 0) + rows;
    if (n < analyzeAfterRows || _running.contains(table)) {
      _inserted[table] = n;
      return;
    }
    _inserted[table] = 0;
    _running.add(table);
    started++;
    last = _analyze(pod, table).whenComplete(() => _running.remove(table));
  }

  static Future<void> _analyze(Serverpod pod, String table) async {
    final session = await pod.createSession(enableLogging: false);
    try {
      await session.db.unsafeExecute('ANALYZE "$table"');
    } on Object catch (e) {
      session.log('ANALYZE $table failed: $e', level: LogLevel.warning);
    } finally {
      await session.close();
    }
  }
}
