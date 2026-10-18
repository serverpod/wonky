/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/drive/drive_item.dart' as _ic5t7igt;
import '../../../platform/revlog/models/rev_file_kind.dart' as _i4o13d09;

/// One RevLog file (RevLog spec 02 §1): a spreadsheet or deck whose rows
/// are written only through the op log.
abstract class RevFile
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  RevFile._({
    this.id,
    required this.fileUuid,
    required this.kind,
    required this.itemId,
    this.item,
    int? headRevision,
    int? prunedBelow,
    bool? initPending,
    bool? purging,
    required this.schemaHash,
    String? stats,
    int? contentCount,
    required this.createdAt,
    required this.updatedAt,
  }) : headRevision = headRevision ?? 0,
       prunedBelow = prunedBelow ?? 0,
       initPending = initPending ?? false,
       purging = purging ?? false,
       stats = stats ?? '{}',
       contentCount = contentCount ?? 0;

  factory RevFile({
    int? id,
    required _is.UuidValue fileUuid,
    required _i4o13d09.RevFileKind kind,
    required int itemId,
    _ic5t7igt.DriveItem? item,
    int? headRevision,
    int? prunedBelow,
    bool? initPending,
    bool? purging,
    required String schemaHash,
    String? stats,
    int? contentCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RevFileImpl;

  factory RevFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevFile(
      id: jsonSerialization['id'] as int?,
      fileUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      kind: _i4o13d09.RevFileKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      itemId: jsonSerialization['itemId'] as int,
      item: jsonSerialization['item'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ic5t7igt.DriveItem>(
              jsonSerialization['item'],
            ),
      headRevision: jsonSerialization['headRevision'] as int?,
      prunedBelow: jsonSerialization['prunedBelow'] as int?,
      initPending: jsonSerialization['initPending'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['initPending']),
      purging: jsonSerialization['purging'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['purging']),
      schemaHash: jsonSerialization['schemaHash'] as String,
      stats: jsonSerialization['stats'] as String?,
      contentCount: jsonSerialization['contentCount'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = RevFileTable();

  static const db = RevFileRepository._();

  @override
  int? id;

  /// Drive item uuid = root row id.
  _is.UuidValue fileUuid;

  _i4o13d09.RevFileKind kind;

  int itemId;

  /// The drive item; purge deletes this row first (05 §10.1).
  _ic5t7igt.DriveItem? item;

  int headRevision;

  /// Ops below this revision have no payload any more (05 §10).
  int prunedBelow;

  /// createFile wrote the row but not all initial ops yet (05 §8.3).
  bool initPending;

  /// Purge in progress: connects and submits are refused (05 §10.1).
  bool purging;

  /// RevSchema hash of the last write.
  String schemaHash;

  /// Binding-defined JSON (02 §1.1).
  String stats;

  /// Sheets: grid cells (Σ rows × cols); Slides: elements.
  int contentCount;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [RevFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevFile copyWith({
    int? id,
    _is.UuidValue? fileUuid,
    _i4o13d09.RevFileKind? kind,
    int? itemId,
    _ic5t7igt.DriveItem? item = const _UndefinedRevFile$item(),
    int? headRevision,
    int? prunedBelow,
    bool? initPending,
    bool? purging,
    String? schemaHash,
    String? stats,
    int? contentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevFile',
      if (id != null) 'id': id,
      'fileUuid': fileUuid.toJson(),
      'kind': kind.toJson(),
      'itemId': itemId,
      if (item != null) 'item': item?.toJson(),
      'headRevision': headRevision,
      'prunedBelow': prunedBelow,
      'initPending': initPending,
      'purging': purging,
      'schemaHash': schemaHash,
      'stats': stats,
      'contentCount': contentCount,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static RevFileInclude include({_ic5t7igt.DriveItemInclude? item}) {
    return RevFileInclude._(item: item);
  }

  static RevFileIncludeList includeList({
    _is.WhereExpressionBuilder<RevFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevFileTable>? orderBy,
    _is.OrderByListBuilder<RevFileTable>? orderByList,
    RevFileInclude? include,
  }) {
    return RevFileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RevFile.t),
      orderByList: orderByList?.call(RevFile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedRevFile$item extends _is.UndefinedSentinel
    implements _ic5t7igt.DriveItem {
  const _UndefinedRevFile$item();
}

class _RevFileImpl extends RevFile {
  _RevFileImpl({
    int? id,
    required _is.UuidValue fileUuid,
    required _i4o13d09.RevFileKind kind,
    required int itemId,
    _ic5t7igt.DriveItem? item,
    int? headRevision,
    int? prunedBelow,
    bool? initPending,
    bool? purging,
    required String schemaHash,
    String? stats,
    int? contentCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         fileUuid: fileUuid,
         kind: kind,
         itemId: itemId,
         item: item,
         headRevision: headRevision,
         prunedBelow: prunedBelow,
         initPending: initPending,
         purging: purging,
         schemaHash: schemaHash,
         stats: stats,
         contentCount: contentCount,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RevFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevFile copyWith({
    Object? id = _Undefined,
    _is.UuidValue? fileUuid,
    _i4o13d09.RevFileKind? kind,
    int? itemId,
    _ic5t7igt.DriveItem? item = const _UndefinedRevFile$item(),
    int? headRevision,
    int? prunedBelow,
    bool? initPending,
    bool? purging,
    String? schemaHash,
    String? stats,
    int? contentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RevFile(
      id: id is int? ? id : this.id,
      fileUuid: fileUuid ?? this.fileUuid,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      item: item is _is.UndefinedSentinel ? this.item?.copyWith() : item,
      headRevision: headRevision ?? this.headRevision,
      prunedBelow: prunedBelow ?? this.prunedBelow,
      initPending: initPending ?? this.initPending,
      purging: purging ?? this.purging,
      schemaHash: schemaHash ?? this.schemaHash,
      stats: stats ?? this.stats,
      contentCount: contentCount ?? this.contentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RevFileUpdateTable extends _is.UpdateTable<RevFileTable> {
  RevFileUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> fileUuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.fileUuid,
        value,
      );

  _is.ColumnValue<_i4o13d09.RevFileKind, _i4o13d09.RevFileKind> kind(
    _i4o13d09.RevFileKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<int, int> headRevision(int value) => _is.ColumnValue(
    table.headRevision,
    value,
  );

  _is.ColumnValue<int, int> prunedBelow(int value) => _is.ColumnValue(
    table.prunedBelow,
    value,
  );

  _is.ColumnValue<bool, bool> initPending(bool value) => _is.ColumnValue(
    table.initPending,
    value,
  );

  _is.ColumnValue<bool, bool> purging(bool value) => _is.ColumnValue(
    table.purging,
    value,
  );

  _is.ColumnValue<String, String> schemaHash(String value) => _is.ColumnValue(
    table.schemaHash,
    value,
  );

  _is.ColumnValue<String, String> stats(String value) => _is.ColumnValue(
    table.stats,
    value,
  );

  _is.ColumnValue<int, int> contentCount(int value) => _is.ColumnValue(
    table.contentCount,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class RevFileTable extends _is.Table<int?> {
  RevFileTable({super.tableRelation}) : super(tableName: 'rev_file') {
    updateTable = RevFileUpdateTable(this);
    fileUuid = _is.ColumnUuid(
      'fileUuid',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    headRevision = _is.ColumnInt(
      'headRevision',
      this,
      hasDefault: true,
    );
    prunedBelow = _is.ColumnInt(
      'prunedBelow',
      this,
      hasDefault: true,
    );
    initPending = _is.ColumnBool(
      'initPending',
      this,
      hasDefault: true,
    );
    purging = _is.ColumnBool(
      'purging',
      this,
      hasDefault: true,
    );
    schemaHash = _is.ColumnString(
      'schemaHash',
      this,
    );
    stats = _is.ColumnString(
      'stats',
      this,
      hasDefault: true,
    );
    contentCount = _is.ColumnInt(
      'contentCount',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final RevFileUpdateTable updateTable;

  /// Drive item uuid = root row id.
  late final _is.ColumnUuid fileUuid;

  late final _is.ColumnEnum<_i4o13d09.RevFileKind> kind;

  late final _is.ColumnInt itemId;

  /// The drive item; purge deletes this row first (05 §10.1).
  _ic5t7igt.DriveItemTable? _item;

  late final _is.ColumnInt headRevision;

  /// Ops below this revision have no payload any more (05 §10).
  late final _is.ColumnInt prunedBelow;

  /// createFile wrote the row but not all initial ops yet (05 §8.3).
  late final _is.ColumnBool initPending;

  /// Purge in progress: connects and submits are refused (05 §10.1).
  late final _is.ColumnBool purging;

  /// RevSchema hash of the last write.
  late final _is.ColumnString schemaHash;

  /// Binding-defined JSON (02 §1.1).
  late final _is.ColumnString stats;

  /// Sheets: grid cells (Σ rows × cols); Slides: elements.
  late final _is.ColumnInt contentCount;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  _ic5t7igt.DriveItemTable get item {
    if (_item != null) return _item!;
    _item = _is.createRelationTable(
      relationFieldName: 'item',
      field: RevFile.t.itemId,
      foreignField: _ic5t7igt.DriveItem.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ic5t7igt.DriveItemTable(tableRelation: foreignTableRelation),
    );
    return _item!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileUuid,
    kind,
    itemId,
    headRevision,
    prunedBelow,
    initPending,
    purging,
    schemaHash,
    stats,
    contentCount,
    createdAt,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'item') {
      return item;
    }
    return null;
  }
}

class RevFileInclude extends _is.IncludeObject {
  RevFileInclude._({_ic5t7igt.DriveItemInclude? item}) {
    _item = item;
  }

  _ic5t7igt.DriveItemInclude? _item;

  @override
  Map<String, _is.Include?> get includes => {'item': _item};

  @override
  _is.Table<int?> get table => RevFile.t;
}

class RevFileIncludeList extends _is.IncludeList {
  RevFileIncludeList._({
    _is.WhereExpressionBuilder<RevFileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RevFile.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => RevFile.t;
}

class RevFileRepository {
  const RevFileRepository._();

  final attachRow = const RevFileAttachRowRepository._();

  /// Returns a list of [RevFile]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<RevFile>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevFileTable>? orderBy,
    _is.OrderByListBuilder<RevFileTable>? orderByList,
    _is.Transaction? transaction,
    RevFileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RevFile>(
      where: where?.call(RevFile.t),
      orderBy: orderBy?.call(RevFile.t),
      orderByList: orderByList?.call(RevFile.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [RevFile]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `RevFile.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<RevFile>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevFileTable>? orderBy,
    _is.OrderByListBuilder<RevFileTable>? orderByList,
    RevFileInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<RevFile>(
      where: where?.call(RevFile.t),
      orderBy: orderBy?.call(RevFile.t),
      orderByList: orderByList?.call(RevFile.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [RevFile] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<RevFile?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevFileTable>? where,
    int? offset,
    _is.OrderByBuilder<RevFileTable>? orderBy,
    _is.OrderByListBuilder<RevFileTable>? orderByList,
    _is.Transaction? transaction,
    RevFileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RevFile>(
      where: where?.call(RevFile.t),
      orderBy: orderBy?.call(RevFile.t),
      orderByList: orderByList?.call(RevFile.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RevFile] by its [id] or null if no such row exists.
  Future<RevFile?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    RevFileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RevFile>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RevFile]s in the list and returns the inserted rows.
  ///
  /// The returned [RevFile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevFile>> insert(
    _is.DatabaseSession session,
    List<RevFile> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RevFile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RevFile] and returns the inserted row.
  ///
  /// The returned [RevFile] will have its `id` field set.
  Future<RevFile> insertRow(
    _is.DatabaseSession session,
    RevFile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<RevFile>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RevFile]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [RevFile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevFile>> upsert(
    _is.DatabaseSession session,
    List<RevFile> rows, {
    required _is.ColumnSelections<RevFileTable> conflictColumns,
    _is.ColumnSelections<RevFileTable>? updateColumns,
    _is.WhereExpressionBuilder<RevFileTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RevFile>(
      rows,
      conflictColumns: conflictColumns(RevFile.t),
      updateColumns: updateColumns?.call(RevFile.t),
      updateWhere: updateWhere?.call(RevFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RevFile] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [RevFile] will have its `id` field set.
  Future<RevFile?> upsertRow(
    _is.DatabaseSession session,
    RevFile row, {
    required _is.ColumnSelections<RevFileTable> conflictColumns,
    _is.ColumnSelections<RevFileTable>? updateColumns,
    _is.WhereExpressionBuilder<RevFileTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RevFile>(
      row,
      conflictColumns: conflictColumns(RevFile.t),
      updateColumns: updateColumns?.call(RevFile.t),
      updateWhere: updateWhere?.call(RevFile.t),
      transaction: transaction,
    );
  }

  /// Updates all [RevFile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevFile>> update(
    _is.DatabaseSession session,
    List<RevFile> rows, {
    _is.ColumnSelections<RevFileTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RevFile>(
      rows,
      columns: columns?.call(RevFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RevFile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RevFile> updateRow(
    _is.DatabaseSession session,
    RevFile row, {
    _is.ColumnSelections<RevFileTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<RevFile>(
      row,
      columns: columns?.call(RevFile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RevFile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RevFile?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<RevFileUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<RevFile>(
      id,
      columnValues: columnValues(RevFile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RevFile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevFile>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RevFileUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RevFileTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevFileTable>? orderBy,
    _is.OrderByListBuilder<RevFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RevFile>(
      columnValues: columnValues(RevFile.t.updateTable),
      where: where(RevFile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RevFile.t),
      orderByList: orderByList?.call(RevFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RevFile]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevFile>> delete(
    _is.DatabaseSession session,
    List<RevFile> rows, {
    _is.OrderByBuilder<RevFileTable>? orderBy,
    _is.OrderByListBuilder<RevFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RevFile>(
      rows,
      orderBy: orderBy?.call(RevFile.t),
      orderByList: orderByList?.call(RevFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RevFile].
  Future<RevFile> deleteRow(
    _is.DatabaseSession session,
    RevFile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RevFile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevFile>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RevFileTable> where,
    _is.OrderByBuilder<RevFileTable>? orderBy,
    _is.OrderByListBuilder<RevFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RevFile>(
      where: where(RevFile.t),
      orderBy: orderBy?.call(RevFile.t),
      orderByList: orderByList?.call(RevFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevFileTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<RevFile>(
      where: where?.call(RevFile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RevFile] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RevFileTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RevFile>(
      where: where(RevFile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class RevFileAttachRowRepository {
  const RevFileAttachRowRepository._();

  /// Creates a relation between the given [RevFile] and [DriveItem]
  /// by setting the [RevFile]'s foreign key `itemId` to refer to the [DriveItem].
  Future<void> item(
    _is.DatabaseSession session,
    RevFile revFile,
    _ic5t7igt.DriveItem item, {
    _is.Transaction? transaction,
  }) async {
    if (revFile.id == null) {
      throw ArgumentError.notNull('revFile.id');
    }
    if (item.id == null) {
      throw ArgumentError.notNull('item.id');
    }

    var $revFile = revFile.copyWith(itemId: item.id);
    await session.db.updateRow<RevFile>(
      $revFile,
      columns: [RevFile.t.itemId],
      transaction: transaction,
    );
  }
}
