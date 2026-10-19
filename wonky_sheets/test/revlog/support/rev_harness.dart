import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show SimpleConnectionKeeper;
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, Uuid, UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/client.dart' show RevChunker;
import 'package:wonky_revlog/codec.dart' show ChangeSet, RevCodec;
import 'package:wonky_revlog_flutter/testing.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';
import 'package:wonky_sheets/features/model/workbook_session.dart';
import 'package:wonky_sheets/features/revlog/logged_workbook_session.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/revlog.dart' show sheetsSchema;

export 'package:wonky_revlog_flutter/testing.dart' show FakeRevHub;

/// A hub of Sheets files (RevLog spec 09 §1).
FakeRevHub sheetsHub() => FakeRevHub(sheetsSchema);

/// The creation plan of a spreadsheet [file] (like *New spreadsheet*).
MutationPlan creationPlan(
  UuidValue file,
  UuidValue user, {
  String title = 'Test',
  int rows = 50,
  int columns = 10,
}) => const SheetsMutationPlanner().plan(
  CreateSpreadsheet(
    spreadsheetId: file.uuid,
    title: title,
    rows: rows,
    columns: columns,
  ),
  WorkbookModel(spreadsheetId: file.uuid),
  PlanContext(userId: user.uuid, now: DateTime.utc(2026, 10, 1)),
);

/// Commits [plan] to [file] on the hub (a fixture written by [user]),
/// split into ops within the limits like a server change; returns the
/// last revision.
int commitPlan(
  FakeRevHub hub,
  UuidValue file,
  UuidValue user,
  MutationPlan plan,
) {
  final ops = RevChunker.split(
    ChangeSet(
      clientOpId: const Uuid().v7(),
      baseRevision: hub.file(file.uuid).head,
      changes: plan.changes,
      label: plan.label,
      summary: plan.summary.toJson(),
    ),
    RevCodec(sheetsSchema, lenient: true),
    () => const Uuid().v7(),
  );
  var revision = 0;
  for (final op in ops) {
    revision = hub.commit(file.uuid, user.uuid, op);
  }
  return revision;
}

/// One user's device with the Sheets RevLog client: a cache in a
/// temporary directory, a connection keeper and a fake transport.
final class SheetsDevice {
  SheetsDevice._(this.user, this.client, this.transport, this.keeper);

  /// Opens a device of [user] on [hub].
  static Future<SheetsDevice> start(FakeRevHub hub, UuidValue user) async {
    final dir = await Directory.systemTemp.createTemp('wonky_sheets_rev_');
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
    final transport = hub.transport(user.uuid);
    final client = RevLogClient(
      app: 'sheets',
      schema: sheetsSchema,
      store: store,
      transport: transport,
      keeper: keeper,
      kind: DriveItemKind.spreadsheet,
    );
    final d = SheetsDevice._(user, client, transport, keeper);
    addTearDown(() async {
      await d.close();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    return d;
  }

  final UuidValue user;
  final RevLogClient client;
  final FakeRevTransport transport;
  final SimpleConnectionKeeper keeper;
  final List<LoggedWorkbookSession> _sessions = [];
  bool _closed = false;

  /// Creates [file] on this device (offline first) and opens it.
  Future<LoggedWorkbookSession> create(
    UuidValue file, {
    String title = 'Test',
    int rows = 50,
    int columns = 10,
  }) async {
    final plan = creationPlan(
      file,
      user,
      title: title,
      rows: rows,
      columns: columns,
    );
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
    return openFile(file, role: Role.owner);
  }

  /// Opens [file] and waits until it is ready.
  Future<LoggedWorkbookSession> openFile(
    UuidValue file, {
    Role role = Role.editor,
    bool waitReady = true,
    Duration maintenanceDelay = const Duration(milliseconds: 20),
  }) async {
    final s = LoggedWorkbookSession.open(
      client,
      maintenanceDelay: maintenanceDelay,
      itemUuid: file,
      fileUuid: file,
      userId: user.uuid,
      role: role,
    );
    _sessions.add(s);
    await s.opened;
    if (waitReady) await whenReady(s);
    return s;
  }

  /// Simulates losing / regaining the network.
  set online(bool v) {
    transport.reachable = v;
    keeper.online = v;
  }

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

/// Completes when [s] is ready (fails after [timeout]).
Future<void> whenReady(
  WorkbookSession s, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  if (s.loadState.value is WorkbookReady) return;
  final c = Completer<void>();
  void check() {
    final v = s.loadState.value;
    if (c.isCompleted) return;
    if (v is WorkbookReady) c.complete();
    if (v is WorkbookUnavailable && !v.offline) {
      c.completeError(StateError(v.reason));
    }
  }

  s.loadState.addListener(check);
  try {
    check();
    await c.future.timeout(timeout);
  } finally {
    s.loadState.removeListener(check);
  }
}

/// Canonical, comparable dump of a model (rows sorted, values normalized).
List<String> canonical(WorkbookModel model) {
  Object? norm(Object? v) => switch (v) {
    num() => v.toDouble(),
    DateTime() => v.toUtc().millisecondsSinceEpoch,
    _ => v,
  };
  return [
    for (final (table, columns) in model.allRows())
      '$table ${(columns.keys.toList()..sort()).map((k) => '$k=${norm(columns[k])}').join(' ')}',
  ]..sort();
}

/// Polls [check] until it holds (fails after [timeout]).
Future<void> eventually(
  bool Function() check, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final watch = Stopwatch()..start();
  while (!check()) {
    if (watch.elapsed > timeout) fail('Condition not met within $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
