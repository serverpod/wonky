@Tags(['slow'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show SimpleConnectionKeeper;
import 'package:wonky_client/wonky_client.dart' as api;
import 'package:wonky_client/wonky_client.dart' show DriveItemKind, Uuid;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/codec.dart' show ChangeSet, RevCodec, RevPageCodec;
import 'package:wonky_revlog_flutter/testing.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';
import 'package:wonky_sheets/features/revlog/logged_workbook_session.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/revlog.dart' show sheetsSchema;

import 'support/rev_harness.dart' show creationPlan, sheetsHub, whenReady;

/// The client side of the RevLog performance gates (RevLog spec 17 part 7:
/// P6–P9 and the per-op costs) for Sheets, against the in-process
/// [FakeRevHub] (real apply rules) with a real SQLite cache. Prints a
/// results table; the numbers are recorded in
/// `plans/sheets-sync-migration/baseline.md`.
///
/// Run: `flutter test -t slow test/revlog/revlog_perf_test.dart`
/// (`REVLOG_PERF_SCALE=0.1` for a quick smoke run).
void main() {
  final scale =
      double.tryParse(Platform.environment['REVLOG_PERF_SCALE'] ?? '') ?? 1.0;
  final rows = (38461 * scale).round();
  const columns = 26;

  test('Given a 1M-cell spreadsheet then the client gates hold', () async {
    final hub = sheetsHub();
    final anna = Uuid().v7obj();
    final ben = Uuid().v7obj();
    final file = Uuid().v7obj();
    final a = await _Device.start(hub, anna);

    // P9: a local import of ~1M cells into the outbox (offline-first:
    // planned, applied to the model and persisted before it is sent).
    final s1 = await a.create(file, rows: rows, columns: columns);
    await s1.whenSynced(timeout: const Duration(minutes: 2));
    final sheet = s1.model.sheets.first.id;
    final watch = Stopwatch()..start();
    a.transport.reachable = false;
    a.keeper.online = false;
    final plan = s1.execute(
      SetCellInputs(
        sheetId: sheet,
        row: 0,
        col: 0,
        inputs: [
          for (var r = 0; r < rows; r++)
            [for (var c = 0; c < columns; c++) CellInput.user(_input(r, c))],
        ],
      ),
    );
    final planned = watch.elapsedMilliseconds;
    await s1.flush();
    final stored = watch.elapsedMilliseconds;
    _results.add(
      _Result(
        'P9',
        'Local import of ${_n(plan.changes.length)} changes '
            '(${_n(rows * columns)} cells) into the outbox: plan + model '
            '$planned ms, outbox durable ${stored - planned} ms',
        '< 30 s',
        _ms(stored),
        pass: stored < 30000,
      ),
    );
    // The outbox drains (one op in flight at a time).
    watch
      ..reset()
      ..start();
    a.transport.reachable = true;
    a.keeper.online = true;
    await s1.whenSynced(timeout: const Duration(minutes: 30));
    await s1.flush();
    final drained = watch.elapsedMilliseconds;
    _results.add(
      _Result(
        '—',
        'Outbox drain of the import (${hub.file(file.uuid).head - 1} ops '
            'to the in-process server, acks stored)',
        'info',
        _ms(drained),
      ),
    );

    // P6/P7: cold open on a second device (not on the device).
    final b = await _Device.start(hub, ben);
    b.transport.warm(file.uuid);
    watch
      ..reset()
      ..start();
    final s2 = await b.open(file);
    await whenReady(s2, timeout: const Duration(minutes: 2));
    final ready = watch.elapsedMilliseconds;
    _results.add(
      _Result(
        'P6',
        'Cold open of ${_n(rows * columns)} cells → WorkbookReady '
            '(structure + viewport pages into SQLite and the model)',
        '< 1.5 s desktop',
        _ms(ready),
        pass: ready < 1500,
      ),
    );
    await _eventually(
      () => s2.rowLoading.complete,
      const Duration(minutes: 10),
    );
    await s2.flush();
    final complete = watch.elapsedMilliseconds;
    final cells = s2.model.sheets.first.cells.count;
    _results.add(
      _Result(
        'P7',
        'Complete download of ${_n(cells)} cells (every page in SQLite and '
            'the model; in-process page serving '
            '${b.transport.pageUs ~/ 1000} ms of it)',
        '< 15 s desktop',
        _ms(complete),
        pass: complete < 15000,
      ),
    );
    // The SQLite part of one cell page (500 rows), alone.
    final sample = await b.client.store.loadScoped(file.uuid, sheet, [
      for (final id in s2.model.sheets.first.rows.ids.skip(1).take(500)) id,
    ]);
    final storeUs = <int>[];
    for (var i = 0; i < 5; i++) {
      final w = Stopwatch()..start();
      await b.client.store.applyPage(
        'perf-scratch-$i',
        revision: 1,
        coverage: const [],
        rows: sample,
        replay: const [],
      );
      storeUs.add(w.elapsedMicroseconds);
    }
    _results.add(
      _Result(
        '—',
        'Store write of one cell page (${_n(sample.length)} cells) '
            '(RevLocalStore.applyPage)',
        'info',
        _dist(storeUs),
      ),
    );

    // Remote op cost on the big model: Anna types, Ben's model shows it.
    final remote = <int>[];
    final durable = <int>[];
    for (var i = 0; i < 220; i++) {
      final got = s2.remoteBatches.first;
      final w = Stopwatch()..start();
      s1.execute(
        SetCellInputs(
          sheetId: sheet,
          row: 1 + i,
          col: 3,
          inputs: [
            [CellInput.user('${i * 3}')],
          ],
        ),
      );
      await s1.flush();
      final d = w.elapsedMicroseconds;
      await got.timeout(const Duration(seconds: 30));
      if (i >= 20) {
        durable.add(d);
        remote.add(w.elapsedMicroseconds);
      }
    }
    _results.add(
      _Result(
        '—',
        'Single-cell edit → outbox durable (SQLite), 1M-cell file',
        'info',
        _dist(durable),
      ),
    );
    _results.add(
      _Result(
        'P1',
        'Single-cell edit → applied in the other client\'s 1M-cell model '
            '(client part; in-process server)',
        'p95 < 250 ms',
        _dist(remote),
        pass: _p(remote, 95) < 250000,
      ),
    );

    // Offline typing: durability with a growing outbox.
    a.transport.reachable = false;
    a.keeper.online = false;
    final offline = <int>[];
    for (var i = 0; i < 200; i++) {
      final w = Stopwatch()..start();
      s1.execute(
        SetCellInputs(
          sheetId: sheet,
          row: 300 + i,
          col: 4,
          inputs: [
            [CellInput.user('${i * 7}')],
          ],
        ),
      );
      await s1.flush();
      offline.add(w.elapsedMicroseconds);
    }
    _results.add(
      _Result(
        '—',
        'Offline single-cell edit → outbox durable (200 edits)',
        'info',
        _dist(offline),
      ),
    );
    a.transport.reachable = true;
    a.keeper.online = true;
    await s1.whenSynced(timeout: const Duration(minutes: 2));
    await _eventually(
      () => s2.model.cellAt(sheet, 499, 4) != null,
      const Duration(minutes: 1),
    );

    // P8: reopen from the cache, and its parts (rows read from SQLite, the
    // model built from them).
    await s2.dispose();
    watch
      ..reset()
      ..start();
    final cached = await b.client.store.loadRows(file.uuid);
    final readMs = watch.elapsedMilliseconds;
    watch
      ..reset()
      ..start();
    WorkbookModel(spreadsheetId: file.uuid).applyChanges([
      for (final (t, r) in cached)
        RowChange.insert(t, r['id']! as String, {
          for (final e in r.entries)
            if (e.key != 'id') e.key: e.value,
        }),
    ]);
    final modelMs = watch.elapsedMilliseconds;
    cached.clear();
    watch
      ..reset()
      ..start();
    final s3 = await b.open(file, waitReady: false);
    await whenReady(s3, timeout: const Duration(minutes: 2));
    final reopened = watch.elapsedMilliseconds;
    _results.add(
      _Result(
        'P8',
        'Reopen from the cache (${_n(s3.model.sheets.first.cells.count)} '
            'cells) → WorkbookReady (alone: rows read $readMs ms, model '
            'built $modelMs ms)',
        '≤ ${(2750 * scale).round()} ms (0.55 s per 200k)',
        _ms(reopened),
        pass: reopened <= 2750 * scale,
      ),
    );
    await s3.dispose();

    // Cache open (the SQLite file with 1M rows).
    final dir = b.dir;
    await b.close();
    watch
      ..reset()
      ..start();
    final store = await RevLocalStore.open(
      schema: sheetsSchema,
      userUuid: ben.uuid,
      app: 'sheets',
      directory: dir.path,
    );
    final opened = watch.elapsedMilliseconds;
    final size = File(
      '${dir.path}/${RevLocalStore.fileNameFor('sheets', ben.uuid)}',
    ).lengthSync();
    _results.add(
      _Result(
        '—',
        'Cache open (RevLocalStore.open, '
            '${(size / 1048576).toStringAsFixed(0)} MiB SQLite file)',
        'info',
        _ms(opened),
      ),
    );
    await store.close();
    await a.close();
    _print(scale);
  }, timeout: const Timeout(Duration(minutes: 60)));
}

// ------------------------------------------------------------------ data

const _regions = ['North', 'South', 'East', 'West', 'Central'];

/// Realistic typed input (the server suite's generator).
String _input(int r, int c) {
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

// ---------------------------------------------------------------- device

/// A device like the harness's `SheetsDevice`, over an [_IndexedTransport]
/// (the hub's cell pages scan every cell; this one indexes them once, as
/// the server's index does).
final class _Device {
  _Device._(this.dir, this.client, this.transport, this.keeper, this.user);

  final Directory dir;
  final RevLogClient client;
  final _IndexedTransport transport;
  final SimpleConnectionKeeper keeper;
  final api.UuidValue user;
  final List<LoggedWorkbookSession> _sessions = [];

  static Future<_Device> start(FakeRevHub hub, api.UuidValue user) async {
    final dir = await Directory.systemTemp.createTemp('wonky_sheets_perf_');
    final store = await RevLocalStore.open(
      schema: sheetsSchema,
      userUuid: user.uuid,
      app: 'sheets',
      directory: dir.path,
    );
    final keeper = SimpleConnectionKeeper(
      minDelay: const Duration(milliseconds: 10),
      maxDelay: const Duration(milliseconds: 50),
    );
    final transport = _IndexedTransport(hub, hub.transport(user.uuid));
    final client = RevLogClient(
      app: 'sheets',
      schema: sheetsSchema,
      store: store,
      transport: transport,
      keeper: keeper,
      kind: DriveItemKind.spreadsheet,
    );
    final d = _Device._(dir, client, transport, keeper, user);
    addTearDown(() async {
      await d.close();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    return d;
  }

  Future<LoggedWorkbookSession> create(
    api.UuidValue file, {
    required int rows,
    required int columns,
  }) async {
    final plan = creationPlan(file, user, rows: rows, columns: columns);
    await client.createLocal(
      file.uuid,
      ChangeSet(
        clientOpId: const Uuid().v7(),
        baseRevision: 0,
        changes: plan.changes,
        label: plan.label,
        summary: plan.summary.toJson(),
      ),
    );
    return open(file, role: Role.owner);
  }

  Future<LoggedWorkbookSession> open(
    api.UuidValue file, {
    Role role = Role.editor,
    bool waitReady = true,
  }) async {
    final s = LoggedWorkbookSession.open(
      client,
      maintenanceDelay: const Duration(hours: 1),
      itemUuid: file,
      fileUuid: file,
      userId: user.uuid,
      role: role,
    );
    _sessions.add(s);
    await s.opened;
    if (waitReady) await whenReady(s, timeout: const Duration(minutes: 2));
    return s;
  }

  bool _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final s in _sessions) {
      if (!s.isDisposed) await s.dispose();
    }
    await client.close();
    keeper.dispose();
  }
}

/// The hub's transport with indexed cell pages.
final class _IndexedTransport implements RevTransport {
  _IndexedTransport(this.hub, this.inner);

  final FakeRevHub hub;
  final FakeRevTransport inner;
  final Map<String, (int, Map<(String, String), List<Map<String, Object?>>>)>
  _index = {};

  bool get reachable => inner.reachable;
  set reachable(bool v) => inner.reachable = v;

  /// Builds the cell index of [fileUuid] at the hub's head.
  void warm(String fileUuid) {
    final server = hub.file(fileUuid);
    final by = <(String, String), List<Map<String, Object?>>>{};
    final cells = server.state.rows[SheetsTables.cell] ?? const {};
    for (final MapEntry(key: id, value: row) in cells.entries) {
      (by[(row[Cols.sheetId]! as String, row['rowId']! as String)] ??= []).add({
        ...row,
        'id': id,
      });
    }
    _index[fileUuid] = (server.head, by);
  }

  @override
  Stream<api.RevServerMessage> connect(
    api.UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<api.RevClientMessage> input,
  ) => inner.connect(fileUuid, knownRevision, tabId, input);

  /// Time spent serving pages (µs): the in-process "server" part.
  int pageUs = 0;

  @override
  Future<api.RevPage> page(
    api.UuidValue fileUuid,
    api.RevPageRequest request,
  ) async {
    final w = Stopwatch()..start();
    try {
      return await _page(fileUuid, request);
    } finally {
      pageUs += w.elapsedMicroseconds;
    }
  }

  Future<api.RevPage> _page(
    api.UuidValue fileUuid,
    api.RevPageRequest request,
  ) async {
    if (request.kind != api.RevPageKind.cells) {
      return inner.page(fileUuid, request);
    }
    if (!inner.reachable) throw StateError('server unreachable');
    final head = hub.file(fileUuid.uuid).head;
    if (_index[fileUuid.uuid]?.$1 != head) warm(fileUuid.uuid);
    final by = _index[fileUuid.uuid]!.$2;
    final sheet = request.sheetId!.uuid;
    final ids = [for (final r in request.rowIds!) r.uuid];
    final rows = [
      for (final r in ids)
        for (final row in by[(sheet, r)] ?? const <Map<String, Object?>>[])
          (SheetsTables.cell, row),
    ];
    return api.RevPage(
      revision: head,
      body: ByteData.sublistView(
        RevCodec.gzip(RevPageCodec.encode(sheetsSchema, rows)),
      ),
      coverage: [for (final id in ids) 'row:$sheet:$id'],
      excludedTables: const [],
    );
  }

  @override
  Future<List<api.RevOpView>> ops(api.UuidValue fileUuid, int from, int to) =>
      inner.ops(fileUuid, from, to);

  @override
  Future<api.RevFileInfo> info(api.UuidValue fileUuid) => inner.info(fileUuid);
}

// ----------------------------------------------------------------- utils

Future<void> _eventually(bool Function() check, Duration timeout) async {
  final watch = Stopwatch()..start();
  while (!check()) {
    if (watch.elapsed > timeout) fail('Condition not met within $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

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

void _print(double scale) {
  final b = StringBuffer()
    ..writeln()
    ..writeln(
      'RevLog Sheets client perf (scale $scale, ${Platform.operatingSystem}, '
      '${Platform.numberOfProcessors} cpus, flutter test VM, SQLite '
      '(sqlite_async), in-process FakeRevHub)',
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
