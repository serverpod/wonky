/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;

/// A change made by a headless MCP/AI tool call, kept 24 h for
/// `changes.revert` (Write 09 §1.4 step 5).
abstract class HeadlessChange
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  HeadlessChange._({
    this.id,
    required this.changeId,
    required this.kind,
    required this.itemId,
    this.documentId,
    this.revision,
    this.inverseJson,
    this.metaField,
    this.metaBeforeJson,
    this.metaAfterJson,
    required this.userId,
    required this.actorKind,
    this.label,
    required this.toolName,
    required this.createdAt,
    this.revertedAt,
  });

  factory HeadlessChange({
    int? id,
    required _is.UuidValue changeId,
    required String kind,
    required int itemId,
    int? documentId,
    int? revision,
    String? inverseJson,
    String? metaField,
    String? metaBeforeJson,
    String? metaAfterJson,
    required int userId,
    required _ipbpecg8.ActorKind actorKind,
    String? label,
    required String toolName,
    required DateTime createdAt,
    DateTime? revertedAt,
  }) = _HeadlessChangeImpl;

  factory HeadlessChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return HeadlessChange(
      id: jsonSerialization['id'] as int?,
      changeId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['changeId'],
      ),
      kind: jsonSerialization['kind'] as String,
      itemId: jsonSerialization['itemId'] as int,
      documentId: jsonSerialization['documentId'] as int?,
      revision: jsonSerialization['revision'] as int?,
      inverseJson: jsonSerialization['inverseJson'] as String?,
      metaField: jsonSerialization['metaField'] as String?,
      metaBeforeJson: jsonSerialization['metaBeforeJson'] as String?,
      metaAfterJson: jsonSerialization['metaAfterJson'] as String?,
      userId: jsonSerialization['userId'] as int,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      label: jsonSerialization['label'] as String?,
      toolName: jsonSerialization['toolName'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      revertedAt: jsonSerialization['revertedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['revertedAt']),
    );
  }

  static final t = HeadlessChangeTable();

  static const db = HeadlessChangeRepository._();

  @override
  int? id;

  /// The `change_id` returned by the tool (also the op's clientOpId).
  _is.UuidValue changeId;

  /// `content` (a document op) or `meta` (a document metadata field).
  String kind;

  int itemId;

  int? documentId;

  /// Revision of the content op.
  int? revision;

  /// Inverse of the content op against the document before it.
  String? inverseJson;

  /// Metadata field (`pageSetup`, `themeId`, …) and its JSON values.
  String? metaField;

  String? metaBeforeJson;

  String? metaAfterJson;

  int userId;

  _ipbpecg8.ActorKind actorKind;

  String? label;

  String toolName;

  DateTime createdAt;

  DateTime? revertedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [HeadlessChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  HeadlessChange copyWith({
    int? id,
    _is.UuidValue? changeId,
    String? kind,
    int? itemId,
    int? documentId,
    int? revision,
    String? inverseJson,
    String? metaField,
    String? metaBeforeJson,
    String? metaAfterJson,
    int? userId,
    _ipbpecg8.ActorKind? actorKind,
    String? label,
    String? toolName,
    DateTime? createdAt,
    DateTime? revertedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HeadlessChange',
      if (id != null) 'id': id,
      'changeId': changeId.toJson(),
      'kind': kind,
      'itemId': itemId,
      if (documentId != null) 'documentId': documentId,
      if (revision != null) 'revision': revision,
      if (inverseJson != null) 'inverseJson': inverseJson,
      if (metaField != null) 'metaField': metaField,
      if (metaBeforeJson != null) 'metaBeforeJson': metaBeforeJson,
      if (metaAfterJson != null) 'metaAfterJson': metaAfterJson,
      'userId': userId,
      'actorKind': actorKind.toJson(),
      if (label != null) 'label': label,
      'toolName': toolName,
      'createdAt': createdAt.toJson(),
      if (revertedAt != null) 'revertedAt': revertedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static HeadlessChangeInclude include() {
    return HeadlessChangeInclude._();
  }

  static HeadlessChangeIncludeList includeList({
    _is.WhereExpressionBuilder<HeadlessChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HeadlessChangeTable>? orderBy,
    _is.OrderByListBuilder<HeadlessChangeTable>? orderByList,
    HeadlessChangeInclude? include,
  }) {
    return HeadlessChangeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(HeadlessChange.t),
      orderByList: orderByList?.call(HeadlessChange.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HeadlessChangeImpl extends HeadlessChange {
  _HeadlessChangeImpl({
    int? id,
    required _is.UuidValue changeId,
    required String kind,
    required int itemId,
    int? documentId,
    int? revision,
    String? inverseJson,
    String? metaField,
    String? metaBeforeJson,
    String? metaAfterJson,
    required int userId,
    required _ipbpecg8.ActorKind actorKind,
    String? label,
    required String toolName,
    required DateTime createdAt,
    DateTime? revertedAt,
  }) : super._(
         id: id,
         changeId: changeId,
         kind: kind,
         itemId: itemId,
         documentId: documentId,
         revision: revision,
         inverseJson: inverseJson,
         metaField: metaField,
         metaBeforeJson: metaBeforeJson,
         metaAfterJson: metaAfterJson,
         userId: userId,
         actorKind: actorKind,
         label: label,
         toolName: toolName,
         createdAt: createdAt,
         revertedAt: revertedAt,
       );

  /// Returns a shallow copy of this [HeadlessChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  HeadlessChange copyWith({
    Object? id = _Undefined,
    _is.UuidValue? changeId,
    String? kind,
    int? itemId,
    Object? documentId = _Undefined,
    Object? revision = _Undefined,
    Object? inverseJson = _Undefined,
    Object? metaField = _Undefined,
    Object? metaBeforeJson = _Undefined,
    Object? metaAfterJson = _Undefined,
    int? userId,
    _ipbpecg8.ActorKind? actorKind,
    Object? label = _Undefined,
    String? toolName,
    DateTime? createdAt,
    DateTime? revertedAt = const _is.$UndefinedDateTime(),
  }) {
    return HeadlessChange(
      id: id is int? ? id : this.id,
      changeId: changeId ?? this.changeId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      documentId: documentId is int? ? documentId : this.documentId,
      revision: revision is int? ? revision : this.revision,
      inverseJson: inverseJson is String? ? inverseJson : this.inverseJson,
      metaField: metaField is String? ? metaField : this.metaField,
      metaBeforeJson: metaBeforeJson is String?
          ? metaBeforeJson
          : this.metaBeforeJson,
      metaAfterJson: metaAfterJson is String?
          ? metaAfterJson
          : this.metaAfterJson,
      userId: userId ?? this.userId,
      actorKind: actorKind ?? this.actorKind,
      label: label is String? ? label : this.label,
      toolName: toolName ?? this.toolName,
      createdAt: createdAt ?? this.createdAt,
      revertedAt: revertedAt is _is.UndefinedSentinel
          ? this.revertedAt
          : revertedAt,
    );
  }
}

class HeadlessChangeUpdateTable extends _is.UpdateTable<HeadlessChangeTable> {
  HeadlessChangeUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> changeId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.changeId,
        value,
      );

  _is.ColumnValue<String, String> kind(String value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<int, int> documentId(int? value) => _is.ColumnValue(
    table.documentId,
    value,
  );

  _is.ColumnValue<int, int> revision(int? value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<String, String> inverseJson(String? value) => _is.ColumnValue(
    table.inverseJson,
    value,
  );

  _is.ColumnValue<String, String> metaField(String? value) => _is.ColumnValue(
    table.metaField,
    value,
  );

  _is.ColumnValue<String, String> metaBeforeJson(String? value) =>
      _is.ColumnValue(
        table.metaBeforeJson,
        value,
      );

  _is.ColumnValue<String, String> metaAfterJson(String? value) =>
      _is.ColumnValue(
        table.metaAfterJson,
        value,
      );

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<_ipbpecg8.ActorKind, _ipbpecg8.ActorKind> actorKind(
    _ipbpecg8.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<String, String> label(String? value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<String, String> toolName(String value) => _is.ColumnValue(
    table.toolName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> revertedAt(DateTime? value) =>
      _is.ColumnValue(
        table.revertedAt,
        value,
      );
}

class HeadlessChangeTable extends _is.Table<int?> {
  HeadlessChangeTable({super.tableRelation})
    : super(tableName: 'headless_change') {
    updateTable = HeadlessChangeUpdateTable(this);
    changeId = _is.ColumnUuid(
      'changeId',
      this,
    );
    kind = _is.ColumnString(
      'kind',
      this,
    );
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    documentId = _is.ColumnInt(
      'documentId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    inverseJson = _is.ColumnString(
      'inverseJson',
      this,
    );
    metaField = _is.ColumnString(
      'metaField',
      this,
    );
    metaBeforeJson = _is.ColumnString(
      'metaBeforeJson',
      this,
    );
    metaAfterJson = _is.ColumnString(
      'metaAfterJson',
      this,
    );
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    actorKind = _is.ColumnEnum(
      'actorKind',
      this,
      _is.EnumSerialization.byName,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    toolName = _is.ColumnString(
      'toolName',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    revertedAt = _is.ColumnDateTime(
      'revertedAt',
      this,
    );
  }

  late final HeadlessChangeUpdateTable updateTable;

  /// The `change_id` returned by the tool (also the op's clientOpId).
  late final _is.ColumnUuid changeId;

  /// `content` (a document op) or `meta` (a document metadata field).
  late final _is.ColumnString kind;

  late final _is.ColumnInt itemId;

  late final _is.ColumnInt documentId;

  /// Revision of the content op.
  late final _is.ColumnInt revision;

  /// Inverse of the content op against the document before it.
  late final _is.ColumnString inverseJson;

  /// Metadata field (`pageSetup`, `themeId`, …) and its JSON values.
  late final _is.ColumnString metaField;

  late final _is.ColumnString metaBeforeJson;

  late final _is.ColumnString metaAfterJson;

  late final _is.ColumnInt userId;

  late final _is.ColumnEnum<_ipbpecg8.ActorKind> actorKind;

  late final _is.ColumnString label;

  late final _is.ColumnString toolName;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime revertedAt;

  @override
  List<_is.Column> get columns => [
    id,
    changeId,
    kind,
    itemId,
    documentId,
    revision,
    inverseJson,
    metaField,
    metaBeforeJson,
    metaAfterJson,
    userId,
    actorKind,
    label,
    toolName,
    createdAt,
    revertedAt,
  ];
}

class HeadlessChangeInclude extends _is.IncludeObject {
  HeadlessChangeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => HeadlessChange.t;
}

class HeadlessChangeIncludeList extends _is.IncludeList {
  HeadlessChangeIncludeList._({
    _is.WhereExpressionBuilder<HeadlessChangeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(HeadlessChange.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => HeadlessChange.t;
}

class HeadlessChangeRepository {
  const HeadlessChangeRepository._();

  /// Returns a list of [HeadlessChange]s matching the given query parameters.
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
  Future<List<HeadlessChange>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HeadlessChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HeadlessChangeTable>? orderBy,
    _is.OrderByListBuilder<HeadlessChangeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<HeadlessChange>(
      where: where?.call(HeadlessChange.t),
      orderBy: orderBy?.call(HeadlessChange.t),
      orderByList: orderByList?.call(HeadlessChange.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [HeadlessChange]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `HeadlessChange.t`.
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
  _ida.Stream<List<HeadlessChange>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HeadlessChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HeadlessChangeTable>? orderBy,
    _is.OrderByListBuilder<HeadlessChangeTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<HeadlessChange>(
      where: where?.call(HeadlessChange.t),
      orderBy: orderBy?.call(HeadlessChange.t),
      orderByList: orderByList?.call(HeadlessChange.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [HeadlessChange] matching the given query parameters.
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
  Future<HeadlessChange?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HeadlessChangeTable>? where,
    int? offset,
    _is.OrderByBuilder<HeadlessChangeTable>? orderBy,
    _is.OrderByListBuilder<HeadlessChangeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<HeadlessChange>(
      where: where?.call(HeadlessChange.t),
      orderBy: orderBy?.call(HeadlessChange.t),
      orderByList: orderByList?.call(HeadlessChange.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [HeadlessChange] by its [id] or null if no such row exists.
  Future<HeadlessChange?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<HeadlessChange>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [HeadlessChange]s in the list and returns the inserted rows.
  ///
  /// The returned [HeadlessChange]s will have their `id` fields set.
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
  Future<List<HeadlessChange>> insert(
    _is.DatabaseSession session,
    List<HeadlessChange> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<HeadlessChange>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [HeadlessChange] and returns the inserted row.
  ///
  /// The returned [HeadlessChange] will have its `id` field set.
  Future<HeadlessChange> insertRow(
    _is.DatabaseSession session,
    HeadlessChange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<HeadlessChange>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [HeadlessChange]s in the list and returns the resulting rows.
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
  /// The returned [HeadlessChange]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HeadlessChange>> upsert(
    _is.DatabaseSession session,
    List<HeadlessChange> rows, {
    required _is.ColumnSelections<HeadlessChangeTable> conflictColumns,
    _is.ColumnSelections<HeadlessChangeTable>? updateColumns,
    _is.WhereExpressionBuilder<HeadlessChangeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<HeadlessChange>(
      rows,
      conflictColumns: conflictColumns(HeadlessChange.t),
      updateColumns: updateColumns?.call(HeadlessChange.t),
      updateWhere: updateWhere?.call(HeadlessChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [HeadlessChange] and returns the resulting row.
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
  /// The returned [HeadlessChange] will have its `id` field set.
  Future<HeadlessChange?> upsertRow(
    _is.DatabaseSession session,
    HeadlessChange row, {
    required _is.ColumnSelections<HeadlessChangeTable> conflictColumns,
    _is.ColumnSelections<HeadlessChangeTable>? updateColumns,
    _is.WhereExpressionBuilder<HeadlessChangeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<HeadlessChange>(
      row,
      conflictColumns: conflictColumns(HeadlessChange.t),
      updateColumns: updateColumns?.call(HeadlessChange.t),
      updateWhere: updateWhere?.call(HeadlessChange.t),
      transaction: transaction,
    );
  }

  /// Updates all [HeadlessChange]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HeadlessChange>> update(
    _is.DatabaseSession session,
    List<HeadlessChange> rows, {
    _is.ColumnSelections<HeadlessChangeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<HeadlessChange>(
      rows,
      columns: columns?.call(HeadlessChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [HeadlessChange]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<HeadlessChange> updateRow(
    _is.DatabaseSession session,
    HeadlessChange row, {
    _is.ColumnSelections<HeadlessChangeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<HeadlessChange>(
      row,
      columns: columns?.call(HeadlessChange.t),
      transaction: transaction,
    );
  }

  /// Updates a single [HeadlessChange] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<HeadlessChange?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<HeadlessChangeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<HeadlessChange>(
      id,
      columnValues: columnValues(HeadlessChange.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [HeadlessChange]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<HeadlessChange>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<HeadlessChangeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<HeadlessChangeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<HeadlessChangeTable>? orderBy,
    _is.OrderByListBuilder<HeadlessChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<HeadlessChange>(
      columnValues: columnValues(HeadlessChange.t.updateTable),
      where: where(HeadlessChange.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(HeadlessChange.t),
      orderByList: orderByList?.call(HeadlessChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [HeadlessChange]s in the list and returns the deleted rows.
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
  Future<List<HeadlessChange>> delete(
    _is.DatabaseSession session,
    List<HeadlessChange> rows, {
    _is.OrderByBuilder<HeadlessChangeTable>? orderBy,
    _is.OrderByListBuilder<HeadlessChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<HeadlessChange>(
      rows,
      orderBy: orderBy?.call(HeadlessChange.t),
      orderByList: orderByList?.call(HeadlessChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [HeadlessChange].
  Future<HeadlessChange> deleteRow(
    _is.DatabaseSession session,
    HeadlessChange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<HeadlessChange>(
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
  Future<List<HeadlessChange>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<HeadlessChangeTable> where,
    _is.OrderByBuilder<HeadlessChangeTable>? orderBy,
    _is.OrderByListBuilder<HeadlessChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<HeadlessChange>(
      where: where(HeadlessChange.t),
      orderBy: orderBy?.call(HeadlessChange.t),
      orderByList: orderByList?.call(HeadlessChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<HeadlessChangeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<HeadlessChange>(
      where: where?.call(HeadlessChange.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [HeadlessChange] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<HeadlessChangeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<HeadlessChange>(
      where: where(HeadlessChange.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
