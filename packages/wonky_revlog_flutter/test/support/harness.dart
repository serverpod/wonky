import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:wonky_app/wonky_app.dart' show SimpleConnectionKeeper;
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_revlog/testing.dart' show MapModel;
import 'package:wonky_revlog_flutter/testing.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';

/// A small spreadsheet-like schema: doc (root) → sheet → row → cell.
final testSchema = RevSchema('test', const [
  RevTable('doc', [RevColumn('title', RevColumnType.string)], isRoot: true),
  RevTable(
    'sheet',
    [
      RevColumn('docId', RevColumnType.uuid, immutable: true),
      RevColumn('name', RevColumnType.string),
    ],
    parents: [RevParent('docId', 'doc')],
    rank: 1,
  ),
  RevTable(
    'row',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('sortKey', RevColumnType.string),
    ],
    parents: [RevParent('sheetId', 'sheet')],
    rank: 2,
  ),
  RevTable(
    'cell',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('rowId', RevColumnType.uuid, immutable: true),
      RevColumn('col', RevColumnType.int, immutable: true),
      RevColumn('content', RevColumnType.string, nullable: true),
    ],
    parents: [RevParent('sheetId', 'sheet'), RevParent('rowId', 'row')],
    rank: 3,
    deterministicIds: true,
    coverage: RevCoverage.cellsByRow,
  ),
]);

const docId = '0190f0b0-0000-7000-8000-000000000001';
const sheetId = '0190f0b0-0000-7000-8000-000000000002';
const anna = '0190a000-0000-7000-8000-0000000000a1';
const bo = '0190a000-0000-7000-8000-0000000000b2';

String newId() => const Uuid().v7();

/// Deterministic cell id.
String cellId(String row, int col) => const Uuid().v5(
  '94020249-01b0-4143-b745-68f9aa91516f',
  'cell:$sheetId:$row:$col',
);

/// The creation changes: the doc, one sheet and [rows] rows.
List<RowChange> creation(List<String> rows) => [
  RowChange.insert('doc', docId, {'title': 'Doc'}),
  RowChange.insert('sheet', sheetId, {'docId': docId, 'name': 'Sheet1'}),
  for (var i = 0; i < rows.length; i++)
    RowChange.insert('row', rows[i], {'sheetId': sheetId, 'sortKey': 'a$i'}),
];

/// Writes [content] into a cell (insert or update against [model]).
List<RowChange> setCell(
  CurrentRowReader model,
  String row,
  int col,
  String? content,
) {
  final id = cellId(row, col);
  final cur = model.currentColumns('cell', id);
  if (cur == null) {
    return [
      RowChange.insert('cell', id, {
        'sheetId': sheetId,
        'rowId': row,
        'col': col,
        'content': content,
      }),
    ];
  }
  return [
    RowChange.update(
      'cell',
      id,
      {'content': cur['content']},
      {'content': content},
    ),
  ];
}

/// A [RevModelPort] over a [MapModel].
final class MapPort implements RevModelPort {
  final MapModel model = MapModel();
  int resets = 0;

  @override
  CurrentRowReader get reader => model;

  @override
  void apply(List<RowChange> changes, {required bool remote}) =>
      model.apply(changes);

  @override
  void reset() {
    resets++;
    model.store.rows.clear();
  }

  /// The content of a cell.
  String? cell(String row, int col) =>
      model.currentColumns('cell', cellId(row, col))?['content'] as String?;

  /// table → id → row (without `id`), for comparisons.
  Map<String, Map<String, Map<String, Object?>>> get snapshot => {
    for (final t in model.store.rows.entries)
      if (t.value.isNotEmpty)
        t.key: {
          for (final r in t.value.entries)
            r.key: {
              for (final c in r.value.entries)
                if (c.key != RowChange.idColumn) c.key: c.value,
            },
        },
  };
}

/// Loads every cell row (rows of the structure) in one block.
final class AllCellsPlan implements RevBootstrapPlan {
  final List<String> _rows = [];
  bool _asked = false;
  final Completer<void> isReady = Completer();
  final Completer<void> isComplete = Completer();

  @override
  void structureLoaded(List<(String, Map<String, Object?>)> structure) {
    _asked = false;
    _rows
      ..clear()
      ..addAll([
        for (final (t, r) in structure)
          if (t == 'row') r[RowChange.idColumn]! as String,
      ]);
  }

  @override
  (String, List<String>)? nextCells() {
    if (_asked || _rows.isEmpty) return null;
    _asked = true;
    return (sheetId, List.of(_rows));
  }

  @override
  void cellsLoaded(String scope, List<String> rowKeys) {}

  @override
  void ready() {
    if (!isReady.isCompleted) isReady.complete();
  }

  @override
  void complete() {
    if (!isComplete.isCompleted) isComplete.complete();
  }
}

/// One user's device: a store on a temporary directory, a keeper and a
/// transport.
final class Device {
  Device._(this.user, this.store, this.transport, this.keeper, this.directory);

  /// Opens a device of [user] on [hub] ([dir]: reopen a device's files).
  static Future<Device> open(
    FakeRevHub hub,
    String user, {
    Directory? dir,
  }) async {
    final d = dir ?? await Directory.systemTemp.createTemp('wonky_revlog_');
    if (dir == null) {
      addTearDown(() async {
        try {
          await d.delete(recursive: true);
        } catch (_) {}
      });
    }
    final store = await RevLocalStore.open(
      schema: testSchema,
      userUuid: user,
      app: 'test',
      directory: d.path,
    );
    final keeper = SimpleConnectionKeeper(
      minDelay: const Duration(milliseconds: 10),
      maxDelay: const Duration(milliseconds: 50),
    );
    final device = Device._(user, store, hub.transport(user), keeper, d);
    addTearDown(device.close);
    return device;
  }

  final String user;
  final RevLocalStore store;
  final FakeRevTransport transport;
  final SimpleConnectionKeeper keeper;
  final Directory directory;
  final List<RevFileSync> _open = [];
  bool _closed = false;

  /// Opens [file] in a new tab ([tabId]: reopen a tab's outbox).
  Future<(RevFileSync, MapPort, AllCellsPlan)> openFile(
    String file, {
    String? tabId,
  }) async {
    final port = MapPort();
    final plan = AllCellsPlan();
    final sync = RevFileSync(
      store: store,
      transport: transport,
      keeper: keeper,
      schema: testSchema,
      fileUuid: file,
      tabId: tabId ?? newId(),
      port: port,
      plan: plan,
    );
    _open.add(sync);
    await sync.open();
    return (sync, port, plan);
  }

  /// A local edit as a session makes it.
  void edit(RevFileSync sync, MapPort port, List<RowChange> changes) {
    sync.beforeLocal(changes);
    port.apply(changes, remote: false);
    sync.submit(changes, label: 'Edit');
  }

  /// Simulates losing / regaining the network.
  set online(bool v) {
    transport.reachable = v;
    keeper.online = v;
  }

  Future<void> closeFile(RevFileSync sync) async {
    _open.remove(sync);
    await sync.whenStored();
    await sync.dispose();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final s in [..._open]) {
      await closeFile(s);
    }
    keeper.dispose();
    await store.close();
  }
}

/// Polls [check] until it holds (fails after [timeout]).
Future<void> eventually(
  bool Function() check, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final watch = Stopwatch()..start();
  while (!check()) {
    if (watch.elapsed > timeout) {
      fail('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
