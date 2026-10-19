import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/schema.dart' show RevColumnType;
import 'package:wonky_sheets_core/revlog.dart' show sheetsSchema;
import 'package:wonky_write_core/wonky_write_core.dart' show Delta;

import '../../generated/future_calls.dart';
import '../../write/ot/document_store.dart';
import '../common/lru_map.dart';
import '../common/models.dart';
import 'storage_service.dart';

/// The counted content size of a Write document (Drive 03 §2): the UTF-8
/// length of the current Delta JSON (the document as it is now; the op log
/// is history and is not counted).
abstract final class DocumentSize {
  static int of(Delta content) =>
      utf8.encode(jsonEncode(content.toJson())).length;
}

/// Estimates the counted content size of an item of one kind (Drive 03
/// §2). Estimates are deterministic: the same content gives the same
/// number. Slides registers its deck estimator with
/// [ContentSizes.register] (a [RevFileSizeEstimator] over its tables).
abstract interface class ContentSizeEstimator {
  /// The content size of [item] in bytes, or null when it can't be
  /// measured (missing content).
  Future<int?> estimate(Session session, DriveItem item);
}

/// Documents: [DocumentSize] of the head.
class DocumentSizeEstimator implements ContentSizeEstimator {
  const DocumentSizeEstimator();

  @override
  Future<int?> estimate(Session session, DriveItem item) async {
    final doc = await DocumentStore.byItem(session, item.id!);
    if (doc == null) return null;
    return DocumentSize.of(await DocumentStore.head(session, doc));
  }
}

/// RevLog files whose rows count as stored (decks; Drive 03 §2): the sum of
/// `pg_column_size(row)` over the file's rows of each of [tables] (by the
/// `fileId` index), plus [baseBytes]. Null when the file is missing.
class RevFileSizeEstimator implements ContentSizeEstimator {
  const RevFileSizeEstimator(this.tables);

  /// The domain table names that hold the content.
  final List<String> tables;

  static final _identifier = RegExp(r'^[a-z_][a-z0-9_]*$');

  /// Bytes every file counts on top of its rows.
  int get baseBytes => 0;

  @override
  Future<int?> estimate(Session session, DriveItem item) async {
    final fileUuid = item.contentRef;
    if (fileUuid == null) return null;
    final files = await session.db.unsafeQuery(
      'SELECT id FROM rev_file WHERE "fileUuid" = @u::uuid',
      parameters: QueryParameters.named({'u': fileUuid.uuid}),
    );
    if (files.isEmpty) return null;
    final parts = <String>[];
    for (final t in tables) {
      if (!_identifier.hasMatch(t)) throw ArgumentError.value(t, 'table');
      parts.add(
        'SELECT coalesce(sum(pg_column_size(t.*)), 0)::bigint AS n '
        'FROM "$t" t WHERE t."fileId" = @f',
      );
    }
    if (parts.isEmpty) return baseBytes;
    final rows = await session.db.unsafeQuery(
      'SELECT coalesce(sum(n), 0)::bigint FROM (${parts.join(' UNION ALL ')}) x',
      parameters: QueryParameters.named({'f': files.first[0]}),
    );
    return baseBytes + (rows.first[0]! as int);
  }
}

/// The Sheets estimator (Drive 03 §2, §11): a compact estimate of the
/// **content**, not of the stored rows (user decision after D-18: "an
/// estimate is ok"). The engine stores 1,000 `sheet_row` and 26
/// `sheet_column` rows for every new sheet; counting them made an empty
/// spreadsheet cost ~80 KB.
///
/// - [base] per spreadsheet (its settings and theme) and [sheetBytes] per
///   sheet;
/// - cells, rows and columns ([propertyTables]): only those that carry
///   something — the bytes of their non-null value/format columns
///   ([valueBytes]: text by its UTF-8 length, numbers 8, small scalars
///   1–4, `true` flags 1) plus [propertyRowBytes]; a cell with no value
///   and no format, and a row or column with the default height/width,
///   not hidden and without a format, count nothing;
/// - script files: [objectBytes] + the UTF-8 length of their source;
/// - everything else (charts, images, pivots, rules, ranges, filters,
///   bandings, script projects/triggers/properties, macros): a fixed
///   [objectBytes] per row (image bytes count as attachments, §2).
///
/// The change log (history, like Write's op log) and script builds
/// (bytecode) don't count. `StorageHooks.sheetsEstimate` pre-estimates
/// templates with the same constants.
class SheetsSizeEstimator implements ContentSizeEstimator {
  SheetsSizeEstimator();

  /// Tables that don't count.
  static const excluded = {'script_build'};

  /// Per spreadsheet (the `spreadsheet` row: settings, theme).
  static const base = 2048;

  /// Per sheet.
  static const sheetBytes = 256;

  /// Per non-empty cell and per row/column with non-default properties,
  /// on top of their value bytes (position, row overhead).
  static const propertyRowBytes = 16;

  /// Per chart, image, pivot table, rule, range, filter, script object.
  static const objectBytes = 256;

  /// Tables whose rows count by their non-null values.
  static const propertyTables = {'cell', 'sheet_row', 'sheet_column'};

  /// Columns every row has (order, timestamps): never content.
  static const _structural = {'sortKey', 'createdAt'};

  static String rowBytes(String table) {
    if (table == 'spreadsheet') return '0';
    if (table == 'sheet') return '$sheetBytes';
    if (table == 'script_file') {
      return '$objectBytes + coalesce(octet_length(t."source"), 0)';
    }
    if (!propertyTables.contains(table)) return '$objectBytes';
    final v = valueBytes(table);
    return 'CASE WHEN $v > 0 THEN $propertyRowBytes + $v ELSE 0 END';
  }

  /// The SQL expression of the bytes of [table]'s non-null value and
  /// format columns of row `t` (structural columns and references
  /// excluded). Derived from the RevLog schema, so new columns count.
  static String valueBytes(String table) {
    final parts = <String>[];
    for (final c in sheetsSchema.table(table).columns) {
      if (_structural.contains(c.name)) continue;
      final q = 't."${c.name}"';
      final part = switch (c.type) {
        // References (`sheetId`, `rowId`, …) are position, not content.
        RevColumnType.uuid => null,
        RevColumnType.string ||
        RevColumnType.json ||
        RevColumnType.enumName => 'coalesce(octet_length($q), 0)',
        RevColumnType.bool => 'CASE WHEN $q THEN 1 ELSE 0 END',
        RevColumnType.double ||
        RevColumnType.dateTime => 'CASE WHEN $q IS NULL THEN 0 ELSE 8 END',
        RevColumnType.int => 'CASE WHEN $q IS NULL THEN 0 ELSE 4 END',
      };
      if (part != null) parts.add(part);
    }
    return parts.isEmpty ? '0' : '(${parts.join(' + ')})';
  }

  @override
  Future<int?> estimate(Session session, DriveItem item) async {
    final fileUuid = item.contentRef;
    if (fileUuid == null) return null;
    final files = await session.db.unsafeQuery(
      'SELECT id FROM rev_file WHERE "fileUuid" = @u::uuid',
      parameters: QueryParameters.named({'u': fileUuid.uuid}),
    );
    if (files.isEmpty) return null;
    final fileId = files.first[0]! as int;
    final parts = <String>[];
    for (final t in sheetsSchema.tables) {
      if (excluded.contains(t.name) || t.name == 'cell') continue;
      parts.add(
        'SELECT coalesce(sum(${rowBytes(t.name)}), 0)::bigint AS n '
        'FROM "${t.name}" t WHERE t."fileId" = @f',
      );
    }
    // Cells are counted sheet by sheet (no fileId index, RevLog spec 02 §2.2).
    parts.add(
      'SELECT coalesce(sum(${rowBytes('cell')}), 0)::bigint AS n '
      'FROM "cell" t WHERE t."sheetId" IN '
      '(SELECT id FROM sheet WHERE "fileId" = @f)',
    );
    final rows = await session.db.unsafeQuery(
      'SELECT coalesce(sum(n), 0)::bigint FROM (${parts.join(' UNION ALL ')}) x',
      parameters: QueryParameters.named({'f': fileId}),
    );
    return base + (rows.first[0]! as int);
  }
}

/// Content size estimation and its cadence (Drive 03 §2): documents with
/// the OT service's throttled search-text update and on create/copy/
/// import; spaces after server writes and, from the change-log consumer,
/// at most every [spaceInterval] per item (trailing).
abstract final class ContentSizes {
  static final Map<DriveItemKind, ContentSizeEstimator> _estimators = {
    DriveItemKind.document: const DocumentSizeEstimator(),
    DriveItemKind.spreadsheet: SheetsSizeEstimator(),
  };

  /// Registers the estimator of [kind] (Slides: `presentation`).
  static void register(DriveItemKind kind, ContentSizeEstimator estimator) =>
      _estimators[kind] = estimator;

  /// The minimum time between two estimates of one space from the
  /// change-log consumer (S-D3, Drive 03 §2).
  static Duration spaceInterval = const Duration(minutes: 5);

  static final LruMap<int, DateTime> _lastRun = LruMap(50000);
  static final Set<int> _pending = {};

  /// Schedules a trailing refresh of item [itemId] after [delay]
  /// (replaceable in tests; default: `StorageFutureCall.refreshItemSize`).
  static Future<void> Function(Session session, int itemId, Duration delay)
  scheduleRefresh = _scheduleViaFutureCall;

  static Future<void> _scheduleViaFutureCall(
    Session session,
    int itemId,
    Duration delay,
  ) => session.serverpod.futureCalls
      .callWithDelay(delay)
      .storage
      .refreshItemSize(itemId);

  /// The estimate of [item]'s content, or null (folders, files: their
  /// size is exact and set on upload).
  static Future<int?> estimate(Session session, DriveItem item) async {
    final estimator = _estimators[item.kind];
    if (estimator == null) return null;
    return estimator.estimate(session, item);
  }

  /// Estimates [item] now and stores the size through [StorageService]
  /// (never throws for quota; may put the owner over quota). Errors are
  /// logged, not thrown: sizes are bookkeeping.
  static Future<void> refresh(Session session, DriveItem item) async {
    if (item.id == null) return;
    _lastRun.put(item.id!, clock.now());
    try {
      final size = await estimate(session, item);
      if (size == null) return;
      await StorageService.instance.setItemSize(session, item, size);
    } on Exception catch (e, st) {
      session.log(
        'Size estimate of item ${item.id} failed: $e',
        level: LogLevel.warning,
        stackTrace: st,
      );
    }
  }

  /// [refresh] by id (the trailing FutureCall).
  static Future<void> refreshById(Session session, int itemId) async {
    _pending.remove(itemId);
    final item = await DriveItem.db.findById(session, itemId);
    if (item != null) await refresh(session, item);
  }

  /// The change-log consumer processed new rows of [item]'s space: refresh
  /// now when the last estimate is older than [spaceInterval], else once
  /// at the end of the interval.
  static Future<void> onSpaceChanged(Session session, DriveItem item) async {
    final id = item.id;
    if (id == null) return;
    final last = _lastRun.get(id);
    final now = clock.now();
    if (last == null || now.difference(last) >= spaceInterval) {
      await refresh(session, item);
      return;
    }
    if (!_pending.add(id)) return;
    try {
      await scheduleRefresh(
        session,
        id,
        last.add(spaceInterval).difference(now),
      );
    } on Object catch (e) {
      _pending.remove(id);
      session.log(
        'Could not schedule the size estimate of item $id: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Forgets the cadence state (tests).
  static void reset() {
    _lastRun.clear();
    _pending.clear();
  }
}
