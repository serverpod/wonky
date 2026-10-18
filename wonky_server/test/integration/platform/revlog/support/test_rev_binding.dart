import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_binding.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_service.dart';
import 'package:wonky_server/src/platform/revlog/rev_sql.dart';

import '../../../../support/test_users.dart';

/// A small spreadsheet-like schema on throwaway tables (`rl_*`): doc (root)
/// → sheet → row → cell (deterministic, per sheet), plus a rule table.
final testRevSchema = RevSchema('rltest', const [
  RevTable('rl_doc', [
    RevColumn('title', RevColumnType.string),
    RevColumn('createdAt', RevColumnType.dateTime, defaultValue: revDefaultNow),
  ], isRoot: true),
  RevTable(
    'rl_sheet',
    [
      RevColumn('docId', RevColumnType.uuid, immutable: true),
      RevColumn('name', RevColumnType.string),
      RevColumn('sortKey', RevColumnType.string),
    ],
    parents: [RevParent('docId', 'rl_doc')],
    rank: 1,
  ),
  RevTable(
    'rl_row',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('sortKey', RevColumnType.string),
      RevColumn('height', RevColumnType.double, nullable: true),
    ],
    parents: [RevParent('sheetId', 'rl_sheet')],
    rank: 2,
  ),
  RevTable(
    'rl_cell',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('rowId', RevColumnType.uuid, immutable: true),
      RevColumn('col', RevColumnType.int, immutable: true),
      RevColumn('content', RevColumnType.string, nullable: true),
      RevColumn('bold', RevColumnType.bool, nullable: true),
    ],
    parents: [RevParent('sheetId', 'rl_sheet'), RevParent('rowId', 'rl_row')],
    indexes: [
      ['sheetId', 'rowId'],
    ],
    rank: 3,
    deterministicIds: true,
    coverage: RevCoverage.cellsByRow,
  ),
  RevTable(
    'rl_rule',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('ruleJson', RevColumnType.json),
    ],
    parents: [RevParent('sheetId', 'rl_sheet')],
    rank: 2,
  ),
]);

/// Records the ops hooks saw (tests).
final class RecordingHook extends RevHook {
  RecordingHook(this.id);

  @override
  final String id;

  /// Revisions seen, in order.
  final List<int> seen = [];

  /// Throw on the next run.
  bool fail = false;

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    if (fail) {
      fail = false;
      throw StateError('hook failed');
    }
    seen.addAll(ops.map((o) => o.revision));
  }
}

/// A binding over [testRevSchema] with an in-memory model.
final class TestRevBinding extends RevBinding {
  TestRevBinding._();

  static final instance = TestRevBinding._();

  final hook = RecordingHook('record');

  @override
  RevFileKind get kind => RevFileKind.spreadsheet;

  @override
  RevSchema get schema => testRevSchema;

  @override
  DriveItemKind get itemKind => DriveItemKind.spreadsheet;

  @override
  String get rootTitleColumn => 'title';

  @override
  Set<String> get perSheetTables => const {'rl_cell'};

  @override
  Future<Map<String, List<String>>> perSheetScopes(
    Session session,
    int fileId, {
    Transaction? transaction,
  }) async {
    final rows = await session.db.unsafeQuery(
      'SELECT id::text FROM rl_sheet WHERE "fileId" = @f',
      parameters: QueryParameters.named({'f': fileId}),
      transaction: transaction,
    );
    return {
      'sheetId': [for (final r in rows) r[0]! as String],
    };
  }

  @override
  String summarize(List<RowChange> changes) => jsonEncode({
    'kinds': ['test'],
  });

  @override
  List<RevHook> get hooks => [hook];

  @override
  Object buildModel(
    UuidValue fileUuid,
    Iterable<(String, Map<String, Object?>)> rows,
  ) {
    final store = MapRowStore();
    for (final (t, r) in rows) {
      store.put(t, r[RowChange.idColumn]! as String, r);
    }
    return store;
  }

  @override
  void applyToModel(Object model, List<RowChange> applied) =>
      replayApplied(model as MapRowStore, applied);

  @override
  int estimateBytes(Object model) => (model as MapRowStore).length * 200;
}

/// Creates (or recreates) the `rl_*` tables.
Future<void> createTestTables(Session session) async {
  final sql = RevSql(testRevSchema, perSheetTables: const {'rl_cell'});
  for (final t in testRevSchema.tables.reversed) {
    await session.db.unsafeExecute('DROP TABLE IF EXISTS "${t.name}" CASCADE');
  }
  for (final t in testRevSchema.tables) {
    for (final stmt in sql.createTableDdl(t).split('\n')) {
      await session.db.unsafeExecute(stmt);
    }
  }
}

/// A drive item for a test file.
Future<DriveItem> testItem(Session session, TestUser owner, String name) =>
    DriveItem.db.insertRow(
      session,
      DriveItem(
        kind: DriveItemKind.spreadsheet,
        name: name,
        ownerId: owner.id,
        createdAt: clock.now().toUtc(),
        createdById: owner.id,
        modifiedAt: clock.now().toUtc(),
      ),
    );

/// Ids of a test file's rows.
final class TestFileIds {
  TestFileIds(this.doc)
    : sheet = const Uuid().v7(),
      rows = [for (var i = 0; i < 4; i++) const Uuid().v7()];

  final String doc;
  final String sheet;
  final List<String> rows;

  String cell(int row, int col) =>
      const Uuid().v5(sheet, 'cell:${rows[row]}:$col');

  /// The creation changes: doc, sheet, rows.
  List<RowChange> creation({String title = 'Doc'}) => [
    RowChange.insert('rl_doc', doc, {'title': title}),
    RowChange.insert('rl_sheet', sheet, {
      'docId': doc,
      'name': 'Sheet1',
      'sortKey': 'a0',
    }),
    for (var i = 0; i < rows.length; i++)
      RowChange.insert('rl_row', rows[i], {
        'sheetId': sheet,
        'sortKey': 'a$i',
        'height': null,
      }),
  ];

  RowChange setCell(int row, int col, String? content) =>
      RowChange.insert('rl_cell', cell(row, col), {
        'sheetId': sheet,
        'rowId': rows[row],
        'col': col,
        'content': content,
        'bold': null,
      });
}

/// The submitter of [user].
RevSubmitter submitterOf(TestUser user, {String? sessionId}) => RevSubmitter(
  userId: user.id,
  authUuid: user.authUserId,
  sessionId: sessionId,
);
