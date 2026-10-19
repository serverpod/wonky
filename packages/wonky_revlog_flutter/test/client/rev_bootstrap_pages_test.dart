import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' as api;
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_revlog_flutter/testing.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';

import '../support/harness.dart';

void main() {
  late FakeRevHub hub;
  final rows = [for (var i = 0; i < 23; i++) newId()];

  setUp(() => hub = FakeRevHub(testSchema));

  /// Anna's file: 23 rows with two cells each.
  Future<MapPort> created() async {
    final a = await Device.open(hub, anna);
    final (sync, port, _) = await a.openFile(docId);
    a.edit(sync, port, creation(rows));
    for (final r in rows) {
      a.edit(sync, port, [
        ...setCell(port.model, r, 0, 'a$r'),
        ...setCell(port.model, r, 1, 'b$r'),
      ]);
    }
    await sync.whenSynced(timeout: const Duration(seconds: 5));
    return port;
  }

  /// Bo opens the file over [transport] with [plan].
  Future<(RevFileSync, MapPort)> openAs(
    RevTransport transport,
    RevBootstrapPlan plan,
  ) async {
    final b = await Device.open(hub, bo);
    final port = MapPort();
    final sync = RevFileSync(
      store: b.store,
      transport: transport,
      keeper: b.keeper,
      schema: testSchema,
      fileUuid: docId,
      tabId: newId(),
      port: port,
      plan: plan,
    );
    addTearDown(() async {
      await sync.whenStored();
      await sync.dispose();
    });
    await sync.open();
    return (sync, port);
  }

  group('Given a plan that hands out unloaded rows until they are loaded', () {
    test('when the cells load with several pages in flight, then every row '
        'is requested once, ready follows the first block and the model '
        'equals the author\'s', () async {
      RevFileSync.minPageRows = 2;
      addTearDown(() => RevFileSync.minPageRows = 100);
      final author = await created();
      final transport = _Recording(hub.transport(bo));
      final plan = _RepeatingPlan(blockRows: 5);

      final (_, port) = await openAs(transport, plan);
      await plan.isComplete.future.timeout(const Duration(seconds: 10));

      final requested = [
        for (final r in transport.requests)
          if (r.kind == api.RevPageKind.cells) ...r.rowIds!.map((u) => u.uuid),
      ];
      expect(requested, unorderedEquals(rows));
      expect(plan.loadedAtReady, containsAll(plan.firstBlock));
      expect(transport.maxInFlight, greaterThan(1));
      expect(port.snapshot, author.snapshot);
    });
  });

  group('Given a server from before page formats', () {
    test('when it serves version-1 bodies, then the client decodes them and '
        'loads the file', () async {
      final author = await created();
      final transport = _Recording(hub.transport(bo), stripFormat: true);
      final plan = AllCellsPlan();

      final (_, port) = await openAs(transport, plan);
      await plan.isComplete.future.timeout(const Duration(seconds: 10));

      expect(transport.versions.toSet(), {RevPageCodec.legacyVersion});
      expect(port.snapshot, author.snapshot);
    });

    test(
      'when a version-2 client asks, then the bodies are version 2',
      () async {
        await created();
        final transport = _Recording(hub.transport(bo));
        final plan = AllCellsPlan();

        await openAs(transport, plan);
        await plan.isComplete.future.timeout(const Duration(seconds: 10));

        expect(transport.versions.toSet(), {RevPageCodec.version});
      },
    );
  });

  group('Given a large page body', () {
    test('when decoded off the UI isolate, then the rows equal an inline '
        'decode', () async {
      final body = RevPageCodec.encode(testSchema, [
        for (var i = 0; i < 3000; i++)
          (
            'cell',
            <String, Object?>{
              RowChange.idColumn: cellId(rows[i % rows.length], i),
              'sheetId': sheetId,
              'rowId': rows[i % rows.length],
              'col': i,
              'content': 'value $i',
            },
          ),
      ]);
      expect(body.length, greaterThan(RevPageDecoder.inlineBelow));

      final back = await RevPageDecoder.decode(testSchema, body);

      List<Object> flat(List<RevPageRow> l) => [
        for (final (t, r) in l) [t, r],
      ];
      expect(flat(back), flat(RevPageCodec.decode(testSchema, body)));
    });
  });
}

/// Records page requests and the body versions served; with
/// [stripFormat], requests lose their format (an old client's request,
/// so the hub serves version 1 as an old server would).
final class _Recording implements RevTransport {
  _Recording(this.inner, {this.stripFormat = false});

  final RevTransport inner;
  final bool stripFormat;
  final List<api.RevPageRequest> requests = [];
  final List<int> versions = [];
  int inFlight = 0;
  int maxInFlight = 0;

  @override
  Stream<api.RevServerMessage> connect(
    api.UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<api.RevClientMessage> input,
  ) => inner.connect(fileUuid, knownRevision, tabId, input);

  @override
  Future<api.RevPage> page(
    api.UuidValue fileUuid,
    api.RevPageRequest request,
  ) async {
    requests.add(request);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    final api.RevPage page;
    try {
      page = await inner.page(
        fileUuid,
        stripFormat ? request.copyWith(format: null) : request,
      );
    } finally {
      inFlight--;
    }
    versions.add(RevPageCodec.versionOf(Uint8List.sublistView(page.body)));
    return page;
  }

  @override
  Future<List<api.RevOpView>> ops(api.UuidValue fileUuid, int from, int to) =>
      inner.ops(fileUuid, from, to);

  @override
  Future<api.RevFileInfo> info(api.UuidValue fileUuid) => inner.info(fileUuid);
}

/// Like the Sheets plan: hands out the first [blockRows] rows not loaded
/// yet, again and again until `cellsLoaded` marks them.
final class _RepeatingPlan implements RevBootstrapPlan {
  _RepeatingPlan({required this.blockRows});

  final int blockRows;
  final List<String> _missing = [];
  final Completer<void> isComplete = Completer();
  final Set<String> _loaded = {};
  Set<String> loadedAtReady = const {};
  List<String> firstBlock = const [];

  @override
  void structureLoaded(List<(String, Map<String, Object?>)> structure) {
    _missing
      ..clear()
      ..addAll([
        for (final (t, r) in structure)
          if (t == 'row') r[RowChange.idColumn]! as String,
      ]);
  }

  @override
  (String, List<String>)? nextCells() {
    if (_missing.isEmpty) return null;
    final block = _missing.take(blockRows).toList();
    if (firstBlock.isEmpty) firstBlock = block;
    return (sheetId, block);
  }

  @override
  void cellsLoaded(String scope, List<String> rowKeys) {
    _missing.removeWhere(rowKeys.contains);
    _loaded.addAll(rowKeys);
  }

  @override
  void ready() => loadedAtReady = {..._loaded};

  @override
  void complete() {
    if (!isComplete.isCompleted) isComplete.complete();
  }
}
