@Tags(['integration', 'slow'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/drive_service.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_connection.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_service.dart';
import 'package:wonky_server/src/platform/revlog/rev_pages.dart';
import 'package:wonky_server/src/platform/revlog/rev_sql.dart';
import 'package:wonky_server/src/platform/revlog/rev_views.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_rev_binding.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_revlog.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_server_writes.dart';
import 'package:wonky_server/src/sheets/spaces/spreadsheet_factory.dart';
import 'package:wonky_server/src/sheets/spaces/template_formulas.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart' hide ActorKind;
import 'package:wonky_sync_models/ids.dart' show SheetsIds;

import '../../../support/sheets_rev_device.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// The server side of the RevLog performance gates (RevLog spec 17 part 7,
/// P1–P12; plans/sheets-sync-migration/spec/09 §6) against the embedded
/// test Postgres. Prints a results table at the end; the numbers are
/// recorded in `plans/sheets-sync-migration/baseline.md`.
///
/// Run (one server test process at a time; the database is shared):
/// `dart test -t slow test/integration/sheets/revlog/revlog_perf_test.dart`
///
/// `REVLOG_PERF_SCALE` (default 1.0) scales the file sizes (0.1 for a quick
/// smoke run; the gates are judged at 1.0 only).
void main() {
  final scale =
      double.tryParse(Platform.environment['REVLOG_PERF_SCALE'] ?? '') ?? 1.0;
  // 26 columns (the default grid width) × rows: 200k and 1M cells, within
  // `maxCellsPerSpreadsheet` (grid size counts).
  final rows200k = (7700 * scale).round();
  final rows1m = (38461 * scale).round();
  const columns = SpreadsheetFactory.defaultColumns;
  // Rows 1…free of the 200k file are edited; the 20 protections (P12) sit
  // below, every `step` rows from `guarded`.
  final free = (rows200k * 0.6).round();
  final guarded = free + 10;
  final step = math.max(2, (rows200k * 0.3 / 20).floor());

  withWonkyServerpod('Given RevLog spreadsheets of 200k and 1M cells', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser ben;
    late UuidValue file200k;
    UuidValue? file1m;
    UuidValue? imported1m;

    setUpAll(() async {
      SheetsRevlog.register();
      RevHooks.debounce = const Duration(hours: 1);
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
      final watch = Stopwatch()..start();
      final item = await DriveService.createSpreadsheetFromSheets(
        anna.session,
        anna.actor,
        name: 'Perf 200k',
        sheets: [_dataSheet(rows200k)],
      );
      _results.add(
        _Result(
          '—',
          'Import of a new ${_n(rows200k * columns)}-cell file '
              '(one transaction)',
          'info',
          _ms(watch.elapsedMilliseconds),
        ),
      );
      file200k = item.contentRef!;
      await TestDrive.share(endpoints, item, anna, ben, AccessRole.editor);
    });
    tearDownAll(() async {
      await RevHooks.idle();
      HeadlessFileCache.clear();
      _printResults(scale);
      // The big files leave the shared test database (its size slows the
      // embedded Postgres down for every later run).
      for (final f in [file200k, ?file1m, ?imported1m]) {
        await RevLogService.purgeFile(
          anna.session,
          SheetsRevBinding.instance,
          f,
        );
      }
    });

    test(
      'P10/P11: a server import of 1M cells and its storage',
      () async {
        // A new file from imported sheets: one transaction (05 §8.3).
        var watch = Stopwatch()..start();
        final imported = await DriveService.createSpreadsheetFromSheets(
          anna.session,
          anna.actor,
          name: 'Perf 1M import',
          sheets: [_dataSheet(rows1m)],
        );
        final newFileMs = watch.elapsedMilliseconds;
        file1m = imported.contentRef!;
        _results.add(
          _Result(
            'P10',
            'Import of a new ${_n(rows1m * columns)}-cell file '
                '(createSpreadsheetFromSheets, one transaction)',
            '< 60 s',
            _ms(newFileMs),
            pass: newFileMs < 60000,
          ),
        );

        // A server change of 1M cells into an existing empty sheet:
        // SheetsServerWrites (submitServerChange, ops of ≤ 5,000 changes).
        final empty = await DriveService.createSpreadsheetFromSheets(
          anna.session,
          anna.actor,
          name: 'Perf 1M server change',
          sheets: [
            TemplateSheet(
              name: 'Data',
              rows: List.filled(rows1m, const <String?>[]),
              boldRows: const {},
              frozenRows: 0,
            ),
          ],
        );
        final target = empty.contentRef!;
        imported1m = target;
        final lease = (await HeadlessFileCache.open(
          anna.session,
          SheetsRevBinding.instance,
          target,
        ))!;
        final model = (lease.model as HeadlessWorkbook).model;
        final sheet = model.sheets.first;
        final rowIds = [...sheet.rows.ids];
        final colIds = [...sheet.columns.ids];
        final formulas = TemplateFormulas(
          sheetId: sheet.id,
          sheetName: sheet.name,
          rowIds: rowIds,
          rowKeys: [
            for (var i = 0; i < rowIds.length; i++) sheet.rows.sortKeyAt(i),
          ],
          columnIds: colIds,
          columnKeys: [
            for (var i = 0; i < colIds.length; i++) sheet.columns.sortKeyAt(i),
          ],
        );
        lease.release();
        HeadlessFileCache.evict(target);
        final changes = <RowChange>[
          for (var r = 0; r < rowIds.length; r++)
            for (var c = 0; c < columns; c++)
              if (_input(r, c) case final input?)
                RowChange.insert(
                  SheetsTables.cell,
                  SheetsIds.cellId(sheet.id, rowIds[r], colIds[c]),
                  {
                    'sheetId': sheet.id,
                    'rowId': rowIds[r],
                    'columnId': colIds[c],
                    'content': SpreadsheetFactory.encodeInput(
                      input,
                      r,
                      c,
                      formulas,
                    ),
                    'bold': ?(r == 0 ? true : null),
                    'numberFormat': ?(r > 0 ? _formats[c] : null),
                  },
                ),
        ];
        final storage0 = await _storage(anna.session);
        watch = Stopwatch()..start();
        final applied = await SheetsServerWrites.apply(
          anna.session,
          actor: anna.actor,
          fileUuid: target,
          changes: changes,
          label: 'Import',
        );
        final changeMs = watch.elapsedMilliseconds;
        final storage1 = await _storage(anna.session);
        final cells = applied.cellsAffected;
        final targetId = (await _revFile(anna.session, target)).id!;
        final ops = await RevOp.db.count(
          anna.session,
          where: (t) => t.fileId.equals(targetId),
        );
        _results.add(
          _Result(
            'P10',
            'Server change of ${_n(cells)} cells into an existing sheet '
                '(SheetsServerWrites.apply, ${ops - 1} ops)',
            '< 60 s',
            _ms(changeMs),
            pass: changeMs < 60000,
          ),
        );
        final perCell = (storage1.cell - storage0.cell) / cells;
        final opPerCell = (storage1.op - storage0.op) / cells;
        _results.add(
          _Result(
            'P11',
            'Storage per non-empty cell: `cell` table incl. indexes and '
                'TOAST (size delta / cells)',
            '≤ 250 B',
            '${perCell.toStringAsFixed(0)} B',
            pass: perCell <= 250,
          ),
        );
        _results.add(
          _Result(
            'P11',
            'Op log per imported cell (`rev_op`, compressed applied form; '
                'payload pruned after 30 days)',
            'info',
            '${opPerCell.toStringAsFixed(0)} B',
          ),
        );

        // The hooks of the import (after the acks; info).
        watch = Stopwatch()..start();
        final f = await _revFile(anna.session, target);
        await RevHooks.drainNow(
          anna.session.serverpod,
          SheetsRevBinding.instance,
          f.id!,
          session: anna.session,
        );
        _results.add(
          _Result(
            '—',
            'Post-commit hooks of the 1M-cell server change (drain)',
            'info',
            _ms(watch.elapsedMilliseconds),
          ),
        );
      },
      timeout: const Timeout(Duration(minutes: 30)),
    );

    test(
      'P6/P7: bootstrap pages of the 1M-cell file and its headless load',
      () async {
        final fileUuid = file1m!;
        final session = anna.session;
        final binding = SheetsRevBinding.instance;
        final file = await _revFile(session, fileUuid);

        // P6 (server part): connect → RevInit, structure pages, the first
        // cell page (500 rows, as RevFileSync asks), decoded into a model.
        final watch = Stopwatch()..start();
        final client = await _PerfClient.open(anna, fileUuid);
        final initMs = watch.elapsedMilliseconds;
        final structure = <(String, Map<String, Object?>)>[];
        String? cursor;
        var bytes = 0;
        do {
          final p = await RevPages.page(
            session,
            binding,
            file,
            RevPageRequest(
              kind: RevPageKind.structure,
              cursor: cursor,
              maxRows: 20000,
            ),
          );
          bytes += p.body.lengthInBytes;
          structure.addAll(_decode(p));
          cursor = p.nextCursor;
        } while (cursor != null);
        final structureMs = watch.elapsedMilliseconds;
        final sheetId = [
          for (final (t, r) in structure)
            if (t == SheetsTables.sheet) r['id']! as String,
        ].single;
        final rowIds =
            [
              for (final (t, r) in structure)
                if (t == SheetsTables.sheetRow) r,
            ]..sort(
              (a, b) => (a['sortKey']! as String).compareTo(
                b['sortKey']! as String,
              ),
            );
        var serverUs = 0, decodeUs = 0, modelUs = 0;
        Future<List<(String, Map<String, Object?>)>> cellsPage(int from) async {
          final ids = [
            for (final r in rowIds.skip(from).take(500))
              UuidValue.fromString(r['id']! as String),
          ];
          final w = Stopwatch()..start();
          final p = await RevPages.page(
            session,
            binding,
            file,
            RevPageRequest(
              kind: RevPageKind.cells,
              sheetId: UuidValue.fromString(sheetId),
              rowIds: ids,
              maxRows: ids.length,
            ),
          );
          serverUs += w.elapsedMicroseconds;
          w.reset();
          bytes += p.body.lengthInBytes;
          final rows = _decode(p);
          decodeUs += w.elapsedMicroseconds;
          return rows;
        }

        final first = await cellsPage(0);
        final m = Stopwatch()..start();
        final model = WorkbookModel.fromRows(fileUuid.uuid, [
          for (final table in SheetsTables.dependencyOrder)
            for (final r in [...structure, ...first])
              if (r.$1 == table) r,
        ]);
        final modelMs = m.elapsedMilliseconds;
        final readyMs = watch.elapsedMilliseconds;
        _results.add(
          _Result(
            'P6',
            'Cold open of ${_n(rows1m * columns)} cells, server + decode + '
                'model (RevInit $initMs ms, structure pages '
                '${structureMs - initMs} ms, first 500-row cell page '
                '${serverUs ~/ 1000} ms + decode ${decodeUs ~/ 1000} ms, '
                'model $modelMs ms; no SQLite, no UI)',
            '< 1.5 s desktop',
            _ms(readyMs),
            pass: readyMs < 1500,
          ),
        );

        // P7 (server part): every other cell page, applied to the model.
        for (var i = 500; i < rowIds.length; i += 500) {
          final rows = await cellsPage(i);
          m
            ..reset()
            ..start();
          model.applyChanges([
            for (final (t, r) in rows)
              RowChange.insert(t, r['id']! as String, {
                for (final e in r.entries)
                  if (e.key != 'id') e.key: e.value,
              }),
          ]);
          modelUs += m.elapsedMicroseconds;
        }
        final downloadMs = watch.elapsedMilliseconds;
        final cells = model.sheets.first.cells.count;
        _results.add(
          _Result(
            'P7',
            'Complete download of ${_n(cells)} cells, server + decode + '
                'model (${(rowIds.length / 500).ceil()} cell pages, '
                '${(bytes / 1048576).toStringAsFixed(1)} MiB gzip: server '
                '${serverUs ~/ 1000} ms, decode ${decodeUs ~/ 1000} ms, model '
                '${modelMs + modelUs ~/ 1000} ms; no SQLite)',
            '< 15 s desktop',
            _ms(downloadMs),
            pass: downloadMs < 15000,
          ),
        );
        await client.close();

        // Headless cold load (05 §9): what a protected file's first submit
        // or an MCP call pays when the model is not cached.
        HeadlessFileCache.evict(fileUuid);
        final h = Stopwatch()..start();
        final all =
            await RevSql(
                  binding.schema,
                  perSheetTables: binding.perSheetTables,
                )
                .allRows(
                  session,
                  file.id!,
                  scopes: () => binding.perSheetScopes(session, file.id!),
                )
                .toList();
        final readMs = h.elapsedMilliseconds;
        h.reset();
        binding.buildModel(fileUuid, all);
        final buildMs = h.elapsedMilliseconds;
        all.clear();
        h.reset();
        final lease = (await HeadlessFileCache.open(
          session,
          binding,
          fileUuid,
        ))!;
        _results.add(
          _Result(
            '—',
            'Headless cold load of the ${_n(cells)}-cell file (rows read '
                '$readMs ms, model built $buildMs ms)',
            'info',
            _ms(h.elapsedMilliseconds),
          ),
        );
        lease.release();
        HeadlessFileCache.evict(fileUuid);
        h
          ..reset()
          ..start();
        final lease2 = (await HeadlessFileCache.open(
          session,
          binding,
          file200k,
        ))!;
        _results.add(
          _Result(
            '—',
            'Headless cold load of the ${_n(rows200k * columns)}-cell file',
            'info',
            _ms(h.elapsedMilliseconds),
          ),
        );
        lease2.release();
        HeadlessFileCache.evict(file200k);
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );

    test(
      'P1/P3/P4: commit and propagation latency on the 200k-cell file',
      () async {
        final a = await _PerfClient.open(anna, file200k, withModel: true);
        final b = await _PerfClient.open(ben, file200k, withModel: true);
        try {
          final sheet = a.model!.sheets.first.id;
          // P3: single-cell and 100-cell ops.
          final one = <int>[];
          for (var i = 0; i < 300; i++) {
            final t = await a.timedEdit(
              sheet,
              1 + i % (free - 20),
              3 + i % 18,
              1,
              1,
            );
            if (i >= 20) one.add(t);
          }
          _results.add(
            _Result(
              'P3',
              'Server commit, 1 change (submit → ack, ${one.length} ops)',
              'p95 < 15 ms',
              _dist(one),
              pass: _p(one, 95) < 15000,
            ),
          );
          final hundred = <int>[];
          for (var i = 0; i < 120; i++) {
            final t = await a.timedEdit(
              sheet,
              1 + (i * 10) % (free - 20),
              3,
              10,
              10,
            );
            if (i >= 20) hundred.add(t);
          }
          _results.add(
            _Result(
              'P3',
              'Server commit, 100 changes (submit → ack, ${hundred.length} '
                  'ops)',
              'p95 < 15 ms',
              _dist(hundred),
              pass: _p(hundred, 95) < 15000,
            ),
          );
          // P4: ~5,000 changes (192 rows × 26 columns).
          final big = <int>[];
          for (var i = 0; i < 12; i++) {
            final t = await a.timedEdit(
              sheet,
              1 + (i * 192) % (rows200k - 200),
              0,
              192,
              26,
            );
            if (i >= 2) big.add(t);
          }
          _results.add(
            _Result(
              'P4',
              'Server commit, 4,992 changes (submit → ack, ${big.length} ops)',
              'p95 < 300 ms',
              _dist(big),
              pass: _p(big, 95) < 300000,
            ),
          );
          // P1: one connection's op visible in the other's model.
          await b.caughtUp(a.revision);
          final prop = <int>[];
          for (var i = 0; i < 520; i++) {
            final t = await a.timedEdit(
              sheet,
              1 + i % (free - 20),
              4 + i % 16,
              1,
              1,
              observer: b,
            );
            if (i >= 20) prop.add(t);
          }
          _results.add(
            _Result(
              'P1',
              'Local op → applied in another connection\'s model, one '
                  'instance (${prop.length} single-cell ops)',
              'p95 < 250 ms',
              _dist(prop),
              pass: _p(prop, 95) < 250000,
            ),
          );

          // Throughput: two editors typing at once, disjoint cells.
          final watch = Stopwatch()..start();
          await b.caughtUp(a.revision);
          await Future.wait([
            for (final (c, col) in [(a, 5), (b, 6)])
              () async {
                for (var i = 0; i < 250; i++) {
                  await c.timedEdit(sheet, 1 + i, col, 1, 1);
                }
              }(),
          ]);
          final ms = watch.elapsedMilliseconds;
          _results.add(
            _Result(
              '—',
              'Op throughput, 2 editors × 250 single-cell ops at once',
              'info',
              '${(500 / ms * 1000).toStringAsFixed(0)} ops/s',
            ),
          );
        } finally {
          await a.close();
          await b.close();
        }
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );

    test(
      'P12: commits on the warm 200k-cell file with 20 protections',
      () async {
        // 20 protections by the owner (ranges outside where Ben types).
        final owner = await SheetsRevDevice.open(anna, file200k);
        final sheet = owner.model.sheets.first.id;
        for (var i = 0; i < 20; i++) {
          await owner.apply(
            AddProtection(
              sheet,
              range: GridRect(
                guarded + i * step,
                0,
                guarded + i * step + step ~/ 2,
                25,
              ),
              description: 'Protected $i',
            ),
          );
        }
        await owner.close();
        HeadlessFileCache.evict(file200k);
        // Ben's connection warms the headless model (05 §3.5).
        final b = await _PerfClient.open(ben, file200k, withModel: true);
        try {
          final loads = HeadlessFileCache.coldLoads;
          final one = <int>[];
          for (var i = 0; i < 220; i++) {
            final t = await b.timedEdit(
              sheet,
              1 + i % (free - 20),
              3 + i % 18,
              1,
              1,
            );
            if (i >= 20) one.add(t);
          }
          final hundred = <int>[];
          for (var i = 0; i < 120; i++) {
            final t = await b.timedEdit(
              sheet,
              1 + (i * 10) % (free - 20),
              3,
              10,
              10,
            );
            if (i >= 20) hundred.add(t);
          }
          final cold = HeadlessFileCache.coldLoads - loads;
          _results.add(
            _Result(
              'P12',
              'Commit with 20 protections, editor, 1 change '
                  '(${one.length} ops)',
              'p95 < 30 ms',
              _dist(one),
              pass: _p(one, 95) < 30000,
            ),
          );
          _results.add(
            _Result(
              'P12',
              'Commit with 20 protections, editor, 100 changes '
                  '(${hundred.length} ops)',
              'p95 < 30 ms',
              _dist(hundred),
              pass: _p(hundred, 95) < 30000,
            ),
          );
          _results.add(
            _Result(
              'P12',
              'Cold headless loads inside the lock during those commits',
              '0',
              '$cold',
              pass: cold == 0,
            ),
          );
          // A write into a protected range is still refused.
          await expectLater(
            b.edit(sheet, guarded, 0, 1, 1),
            throwsA(isA<_Rejected>()),
          );
        } finally {
          await b.close();
        }
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );

    test(
      'P5: idle connections cost no database queries',
      () async {
        final session = anna.session;
        // Stats of earlier statements are flushed within ~10 s (Postgres
        // idle flush); this is a wall-clock measurement on purpose. The
        // measuring query counts itself once per window.
        Future<int> idleWindow() async {
          await Future<void>.delayed(const Duration(seconds: 11));
          final before = await _transactions(session);
          await Future<void>.delayed(const Duration(seconds: 31));
          return await _transactions(session) - before - 1;
        }

        final baseline = await idleWindow();
        final a = await _PerfClient.open(anna, file200k);
        final b = await _PerfClient.open(ben, file200k);
        try {
          final idle = await idleWindow();
          _results.add(
            _Result(
              'P5',
              'Database transactions during 31 s idle with 2 connections '
                  'open, minus the same window without connections '
                  '($idle − $baseline; pg_stat_database; role re-check every '
                  '5 min)',
              '0',
              '${idle - baseline}',
              pass: idle - baseline <= 0,
            ),
          );
        } finally {
          await a.close();
          await b.close();
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

// ------------------------------------------------------------- data

/// Number formats of the data columns.
const _formats = <int, String>{3: '#,##0.00', 4: '#,##0.00', 25: '0.0%'};

const _regions = ['North', 'South', 'East', 'West', 'Central'];

/// The typed input of ([r], [c]) of a realistic sheet: a header row, item
/// labels, regions, dates, numbers, three formula columns and notes.
String? _input(int r, int c) {
  if (r == 0) return 'Column ${String.fromCharCode(65 + c)}';
  final row = r + 1;
  return switch (c) {
    0 => 'Item $r',
    1 => _regions[r % _regions.length],
    2 =>
      '2026-${(r % 12 + 1).toString().padLeft(2, '0')}-'
          '${(r % 28 + 1).toString().padLeft(2, '0')}',
    21 => '=D$row*E$row',
    22 => '=SUM(D$row:H$row)',
    23 => '=IF(F$row>500,"high","low")',
    24 => r % 3 == 0 ? 'Checked by the regional team on site' : 'ok',
    25 => '${(r * 7 % 100) / 100}',
    _ => '${((r * 31 + c * 17) % 100000) / 100}',
  };
}

TemplateSheet _dataSheet(int rows) => TemplateSheet(
  name: 'Data',
  rows: [
    for (var r = 0; r < rows; r++)
      [
        for (var c = 0; c < SpreadsheetFactory.defaultColumns; c++)
          _input(r, c),
      ],
  ],
  numberFormats: _formats,
);

// ------------------------------------------------------------ client

final class _Rejected implements Exception {
  _Rejected(this.m);
  final RevRejected m;
  @override
  String toString() => 'rejected ${m.code}: ${m.message}';
}

/// A measuring client over one `RevLogConnection`: submits planner ops,
/// applies remote ops to its model (when it has one) and records when each
/// op arrived.
final class _PerfClient {
  _PerfClient._(this.user, this.fileUuid);

  static final _binding = SheetsRevBinding.instance;
  static var _tabs = 0;

  final TestUser user;
  final UuidValue fileUuid;
  final _toServer = StreamController<RevClientMessage>();
  late final StreamSubscription<RevServerMessage> _sub;
  WorkbookModel? model;
  int revision = 0;
  final _acks = <UuidValue, Completer<RevAck>>{};
  final _seen = <String, Completer<void>>{};
  final _init = Completer<void>();

  /// Connects; with [withModel] the model is bootstrapped from pages first.
  static Future<_PerfClient> open(
    TestUser user,
    UuidValue fileUuid, {
    bool withModel = false,
  }) async {
    final c = _PerfClient._(user, fileUuid);
    if (withModel) {
      final d = await SheetsRevDevice.open(user, fileUuid);
      c.model = d.model;
      c.revision = d.revision;
      await d.close();
    }
    final stream = RevLogConnection.open(
      user.session,
      _binding,
      user.actor,
      fileUuid,
      c.revision,
      'perf-${++_tabs}',
      c._toServer.stream,
    );
    c._sub = stream.listen(c._on);
    await c._init.future.timeout(const Duration(minutes: 2));
    return c;
  }

  void _on(RevServerMessage m) {
    switch (m) {
      case RevInit():
        for (final v in m.ops ?? const <RevOpView>[]) {
          _apply(v);
        }
        if (!_init.isCompleted) _init.complete();
      case RevRemoteOp():
        _apply(m.op);
      case RevAck():
        if (m.revision > revision) revision = m.revision;
        _acks.remove(m.clientOpId)?.complete(m);
      case RevRejected():
        final id = m.clientOpId;
        if (id == null) {
          if (!_init.isCompleted) _init.completeError(_Rejected(m));
        } else {
          _acks.remove(id)?.completeError(_Rejected(m));
        }
      default:
        break;
    }
  }

  void _apply(RevOpView v) {
    if (v.revision <= revision) return;
    model?.applyChanges(RevViews.appliedOf(_binding.codec, v));
    revision = v.revision;
    _seen.remove(v.clientOpId.uuid)?.complete();
  }

  /// Completes when an op of [rev] or later was applied.
  Future<void> caughtUp(int rev) async {
    while (revision < rev) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// Types numbers into [rows] × [cols] at ([row], [col]); returns the ack.
  Future<RevAck> edit(
    String sheetId,
    int row,
    int col,
    int rows,
    int cols, {
    _PerfClient? observer,
    Stopwatch? watch,
  }) async {
    final m = model!;
    final plan = const SheetsMutationPlanner().plan(
      SetCellInputs(
        sheetId: sheetId,
        row: row,
        col: col,
        inputs: [
          for (var r = 0; r < rows; r++)
            [
              for (var c = 0; c < cols; c++)
                CellInput.user('${_counter++ % 100000}'),
            ],
        ],
      ),
      m,
      PlanContext(
        userId: user.authUserId.uuid,
        now: clock.now().toUtc(),
        formulas: EngineFormulaHooks(m),
      ),
    );
    m.applyChanges(plan.changes);
    final id = UuidValue.fromString(const Uuid().v7());
    watch?.start();
    final seen = observer == null
        ? null
        : (observer._seen[id.uuid] = Completer());
    final packed = RevCodec.pack(
      _binding.codec.encodeText(plan.changes, summary: plan.summary.toJson()),
    );
    final ack = Completer<RevAck>();
    _acks[id] = ack;
    _toServer.add(
      RevSubmit(
        clientOpId: id,
        baseRevision: revision,
        payload: packed.text,
        payloadGz: packed.gz == null ? null : ByteData.sublistView(packed.gz!),
        label: 'Edit',
        actorKind: ActorKind.user,
        groupIndex: 0,
        groupLast: true,
        offline: false,
        createdAt: clock.now().toUtc(),
      ),
    );
    final result = await ack.future.timeout(const Duration(minutes: 2));
    if (seen != null) await seen.future.timeout(const Duration(minutes: 1));
    watch?.stop();
    return result;
  }

  static var _counter = 0;

  /// [edit] timed in microseconds (submit → ack, or → applied by
  /// [observer]).
  Future<int> timedEdit(
    String sheetId,
    int row,
    int col,
    int rows,
    int cols, {
    _PerfClient? observer,
  }) async {
    final w = Stopwatch();
    await edit(sheetId, row, col, rows, cols, observer: observer, watch: w);
    return w.elapsedMicroseconds;
  }

  Future<void> close() async {
    await _toServer.close();
    await _sub.cancel();
  }
}

// --------------------------------------------------------------- utils

List<(String, Map<String, Object?>)> _decode(RevPage p) => RevPageCodec.decode(
  SheetsRevBinding.instance.schema,
  RevCodec.gunzip(
    p.body.buffer.asUint8List(p.body.offsetInBytes, p.body.lengthInBytes),
  ),
);

Future<RevFile> _revFile(Session session, UuidValue fileUuid) async =>
    (await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    ))!;

Future<({int cell, int op})> _storage(Session session) async {
  final r = await session.db.unsafeQuery(
    "SELECT pg_total_relation_size('cell'), pg_total_relation_size('rev_op')",
  );
  return (cell: r.first[0]! as int, op: r.first[1]! as int);
}

Future<int> _transactions(Session session) async {
  final r = await session.db.unsafeQuery(
    'SELECT (xact_commit + xact_rollback)::bigint FROM pg_stat_database '
    'WHERE datname = current_database()',
  );
  return r.first[0]! as int;
}

/// Percentile [p] of microsecond [samples].
int _p(List<int> samples, int p) {
  final s = [...samples]..sort();
  final i = ((p / 100) * (s.length - 1)).round();
  return s[math.min(i, s.length - 1)];
}

String _dist(List<int> us) {
  String f(int v) => (v / 1000).toStringAsFixed(1);
  final mean = us.reduce((a, b) => a + b) / us.length;
  return 'p50 ${f(_p(us, 50))} / p95 ${f(_p(us, 95))} / max '
      '${f(us.reduce(math.max))} ms (mean ${f(mean.round())})';
}

String _ms(int ms) =>
    ms >= 10000 ? '${(ms / 1000).toStringAsFixed(1)} s' : '$ms ms';

String _n(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]},',
);

final class _Result {
  _Result(this.gate, this.metric, this.target, this.measured, {this.pass});
  final String gate;
  final String metric;
  final String target;
  final String measured;
  final bool? pass;
}

final _results = <_Result>[];

void _printResults(double scale) {
  final b = StringBuffer()
    ..writeln()
    ..writeln(
      'RevLog server perf (scale $scale, ${Platform.operatingSystem} '
      '${Platform.operatingSystemVersion}, ${Platform.numberOfProcessors} '
      'cpus, Dart ${Platform.version.split(' ').first}, JIT, embedded '
      'Postgres)',
    )
    ..writeln('| Gate | Metric | Target | Measured | Pass |')
    ..writeln('|------|--------|--------|----------|------|');
  for (final r in _results) {
    final pass = switch (r.pass) {
      true => 'pass',
      false => '**miss**',
      null => '—',
    };
    b.writeln(
      '| ${r.gate} | ${r.metric} | ${r.target} | ${r.measured} | $pass |',
    );
  }
  // ignore: avoid_print
  print(b);
}
