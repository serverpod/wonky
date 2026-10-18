import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_connection.dart';
import 'package:wonky_server/src/platform/revlog/rev_pages.dart';
import 'package:wonky_server/src/platform/revlog/rev_views.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_rev_binding.dart';
import 'package:wonky_sheets_core/model.dart' hide ActorKind;

import 'test_users.dart';

/// A spreadsheet client for server tests (RevLog spec 09 §3): one
/// `RevLogConnection` of [user] to [fileUuid] and a [WorkbookModel] replica
/// that bootstraps from pages, submits planner ops and applies remote ops.
final class SheetsRevDevice {
  SheetsRevDevice._(this.user, this.fileUuid, this._input, this._out);

  /// The user.
  final TestUser user;

  /// The file.
  final UuidValue fileUuid;

  final StreamController<RevClientMessage> _input;
  final StreamQueue<RevServerMessage> _out;

  /// The replica.
  late WorkbookModel model;

  /// The last revision applied.
  int revision = 0;

  /// The role the server reported.
  AccessRole role = AccessRole.viewer;

  /// Rejections received.
  final List<RevRejected> rejections = [];

  /// Ack outcomes received (JSON).
  final List<String> outcomes = [];

  static final _binding = SheetsRevBinding.instance;

  /// Connects [user] to [fileUuid] and loads the file.
  static Future<SheetsRevDevice> open(
    TestUser user,
    UuidValue fileUuid,
  ) async {
    final input = StreamController<RevClientMessage>();
    final out = StreamQueue(
      RevLogConnection.open(
        user.session,
        _binding,
        user.actor,
        fileUuid,
        0,
        'device-${user.name}',
        input.stream,
      ),
    );
    final d = SheetsRevDevice._(user, fileUuid, input, out);
    final init = await d._next();
    if (init is RevRejected) {
      throw StateError('connect failed: ${init.code} ${init.message}');
    }
    init as RevInit;
    d.role = init.role;
    await d._bootstrap();
    return d;
  }

  Future<RevServerMessage> _next() =>
      _out.next.timeout(const Duration(seconds: 15));

  Future<void> _bootstrap() async {
    final file = (await RevFile.db.findFirstRow(
      user.session,
      where: (t) => t.fileUuid.equals(fileUuid),
    ))!;
    final rows = <(String, Map<String, Object?>)>[];
    var rev = 0;
    String? cursor;
    do {
      final p = await RevPages.page(
        user.session,
        _binding,
        file,
        RevPageRequest(
          kind: RevPageKind.structure,
          cursor: cursor,
          maxRows: 20000,
          format: RevPageCodec.version,
        ),
      );
      rows.addAll(_decode(p));
      rev = p.revision;
      cursor = p.nextCursor;
    } while (cursor != null);
    final sheets = [
      for (final (t, r) in rows)
        if (t == SheetsTables.sheet) r,
    ];
    for (final s in sheets) {
      final rowIds = [
        for (final (t, r) in rows)
          if (t == SheetsTables.sheetRow && r[Cols.sheetId] == s['id'])
            UuidValue.fromString(r['id']! as String),
      ];
      for (var i = 0; i < rowIds.length; i += 1000) {
        final p = await RevPages.page(
          user.session,
          _binding,
          file,
          RevPageRequest(
            kind: RevPageKind.cells,
            sheetId: UuidValue.fromString(s['id']! as String),
            rowIds: rowIds.sublist(i, (i + 1000).clamp(0, rowIds.length)),
            maxRows: 1000,
            format: RevPageCodec.version,
          ),
        );
        rows.addAll(_decode(p));
      }
    }
    model = WorkbookModel.fromRows(fileUuid.uuid, [
      for (final table in SheetsTables.dependencyOrder)
        for (final r in rows)
          if (r.$1 == table) r,
    ]);
    revision = rev;
    // Ops committed while the pages were read.
    await catchUp();
  }

  static List<(String, Map<String, Object?>)> _decode(RevPage p) =>
      RevPageCodec.decode(
        _binding.schema,
        p.body.buffer.asUint8List(p.body.offsetInBytes, p.body.lengthInBytes),
      );

  /// Applies the ops committed after [revision] (gap fill).
  Future<void> catchUp() async {
    final file = (await RevFile.db.findFirstRow(
      user.session,
      where: (t) => t.fileUuid.equals(fileUuid),
    ))!;
    if (file.headRevision <= revision) return;
    final views = await RevViews.read(
      user.session,
      _binding.codec,
      file.id!,
      revision + 1,
      file.headRevision,
    );
    for (final v in views) {
      _applyRemote(v);
    }
  }

  void _applyRemote(RevOpView v) {
    if (v.revision <= revision) return;
    model.applyChanges(RevViews.appliedOf(_binding.codec, v));
    revision = v.revision;
  }

  /// Plans [op] on the replica, submits it and waits for its ack.
  Future<RevAck> apply(SheetsOperation op) async {
    final plan = const SheetsMutationPlanner().plan(
      op,
      model,
      PlanContext(
        userId: user.authUserId.uuid,
        now: clock.now().toUtc(),
        formulas: EngineFormulaHooks(model),
      ),
    );
    return submit(plan.changes, summary: plan.summary.toJson());
  }

  /// Submits [changes] and waits for the ack (remote ops before it are
  /// applied first).
  Future<RevAck> submit(
    List<RowChange> changes, {
    Map<String, Object?>? summary,
    String label = 'Edit',
  }) async {
    final id = UuidValue.fromString(const Uuid().v7());
    final base = revision;
    _input.add(
      RevSubmit(
        clientOpId: id,
        baseRevision: base,
        payload: _binding.codec.encodeText(changes, summary: summary),
        label: label,
        actorKind: ActorKind.user,
        groupIndex: 0,
        groupLast: true,
        offline: false,
        createdAt: clock.now().toUtc(),
      ),
    );
    while (true) {
      final m = await _next();
      switch (m) {
        case RevRemoteOp():
          _applyRemote(m.op);
        case RevAck() when m.clientOpId == id:
          await catchUp();
          return m;
        case RevRejected() when m.clientOpId == id:
          rejections.add(m);
          throw RevDeviceRejected(m);
        default:
          continue;
      }
    }
  }

  /// Receives and applies pending remote ops (a short wait).
  Future<void> sync() async {
    while (await _out.hasNext.timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => false,
    )) {
      final m = await _out.next;
      if (m is RevRemoteOp) _applyRemote(m.op);
      if (m is RevRoleChanged) role = m.role;
    }
    await catchUp();
  }

  /// Types [input] into ([row], [col]) of the first sheet.
  Future<RevAck> setCell(int row, int col, String input) => apply(
    SetCellInputs(
      sheetId: model.sheets.first.id,
      row: row,
      col: col,
      inputs: [
        [CellInput.user(input)],
      ],
    ),
  );

  /// The encoded content of ([row], [col]) of the first sheet.
  String? cell(int row, int col) =>
      model.cellAt(model.sheets.first.id, row, col)?.content;

  /// The spreadsheet title.
  String get title => model.spreadsheet.title;

  /// Rows of the first sheet.
  int get rowCount => model.sheets.first.rows.length;

  /// Renames the spreadsheet (the title column).
  Future<RevAck> rename(String title) => submit([
    RowChange.update(
      SheetsTables.spreadsheet,
      fileUuid.uuid,
      {'title': model.spreadsheet.title},
      {'title': title},
    ),
  ], label: 'Rename');

  /// Disconnects.
  Future<void> close() async {
    await _input.close();
    await _out.cancel(immediate: true);
  }
}

/// A submit the server rejected.
final class RevDeviceRejected implements Exception {
  /// Creates the exception.
  RevDeviceRejected(this.rejected);

  /// The rejection.
  final RevRejected rejected;

  @override
  String toString() =>
      'RevDeviceRejected(${rejected.code}: ${rejected.message})';
}
