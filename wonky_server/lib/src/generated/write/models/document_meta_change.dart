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

/// LWW metadata change (Write 03 §6). The title lives on DriveItem.
abstract class DocumentMetaChange
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DocumentMetaChange._({
    this.id,
    required this.documentId,
    required this.field,
    this.clientOpId,
    required this.beforeJson,
    required this.afterJson,
    this.authorId,
    required this.actorKind,
    required this.createdAt,
  });

  factory DocumentMetaChange({
    int? id,
    required int documentId,
    required String field,
    _is.UuidValue? clientOpId,
    required String beforeJson,
    required String afterJson,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) = _DocumentMetaChangeImpl;

  factory DocumentMetaChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentMetaChange(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      field: jsonSerialization['field'] as String,
      clientOpId: jsonSerialization['clientOpId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['clientOpId'],
            ),
      beforeJson: jsonSerialization['beforeJson'] as String,
      afterJson: jsonSerialization['afterJson'] as String,
      authorId: jsonSerialization['authorId'] as int?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = DocumentMetaChangeTable();

  static const db = DocumentMetaChangeRepository._();

  @override
  int? id;

  int documentId;

  /// themeId, pageSetup, language, frontMatter.
  String field;

  _is.UuidValue? clientOpId;

  String beforeJson;

  String afterJson;

  int? authorId;

  _ipbpecg8.ActorKind actorKind;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DocumentMetaChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocumentMetaChange copyWith({
    int? id,
    int? documentId,
    String? field,
    _is.UuidValue? clientOpId = const _is.$UndefinedUuidValue(),
    String? beforeJson,
    String? afterJson,
    int? authorId,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentMetaChange',
      if (id != null) 'id': id,
      'documentId': documentId,
      'field': field,
      if (clientOpId != null) 'clientOpId': clientOpId?.toJson(),
      'beforeJson': beforeJson,
      'afterJson': afterJson,
      if (authorId != null) 'authorId': authorId,
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentMetaChange',
      if (id != null) 'id': id,
      'documentId': documentId,
      'field': field,
      if (clientOpId != null) 'clientOpId': clientOpId?.toJson(),
      'beforeJson': beforeJson,
      'afterJson': afterJson,
      if (authorId != null) 'authorId': authorId,
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static DocumentMetaChangeInclude include() {
    return DocumentMetaChangeInclude._();
  }

  static DocumentMetaChangeIncludeList includeList({
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentMetaChangeTable>? orderBy,
    _is.OrderByListBuilder<DocumentMetaChangeTable>? orderByList,
    DocumentMetaChangeInclude? include,
  }) {
    return DocumentMetaChangeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentMetaChange.t),
      orderByList: orderByList?.call(DocumentMetaChange.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentMetaChangeImpl extends DocumentMetaChange {
  _DocumentMetaChangeImpl({
    int? id,
    required int documentId,
    required String field,
    _is.UuidValue? clientOpId,
    required String beforeJson,
    required String afterJson,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) : super._(
         id: id,
         documentId: documentId,
         field: field,
         clientOpId: clientOpId,
         beforeJson: beforeJson,
         afterJson: afterJson,
         authorId: authorId,
         actorKind: actorKind,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DocumentMetaChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocumentMetaChange copyWith({
    Object? id = _Undefined,
    int? documentId,
    String? field,
    _is.UuidValue? clientOpId = const _is.$UndefinedUuidValue(),
    String? beforeJson,
    String? afterJson,
    Object? authorId = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  }) {
    return DocumentMetaChange(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      field: field ?? this.field,
      clientOpId: clientOpId is _is.UndefinedSentinel
          ? this.clientOpId
          : clientOpId,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      authorId: authorId is int? ? authorId : this.authorId,
      actorKind: actorKind ?? this.actorKind,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DocumentMetaChangeUpdateTable
    extends _is.UpdateTable<DocumentMetaChangeTable> {
  DocumentMetaChangeUpdateTable(super.table);

  _is.ColumnValue<int, int> documentId(int value) => _is.ColumnValue(
    table.documentId,
    value,
  );

  _is.ColumnValue<String, String> field(String value) => _is.ColumnValue(
    table.field,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> clientOpId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.clientOpId,
    value,
  );

  _is.ColumnValue<String, String> beforeJson(String value) => _is.ColumnValue(
    table.beforeJson,
    value,
  );

  _is.ColumnValue<String, String> afterJson(String value) => _is.ColumnValue(
    table.afterJson,
    value,
  );

  _is.ColumnValue<int, int> authorId(int? value) => _is.ColumnValue(
    table.authorId,
    value,
  );

  _is.ColumnValue<_ipbpecg8.ActorKind, _ipbpecg8.ActorKind> actorKind(
    _ipbpecg8.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DocumentMetaChangeTable extends _is.Table<int?> {
  DocumentMetaChangeTable({super.tableRelation})
    : super(tableName: 'document_meta_change') {
    updateTable = DocumentMetaChangeUpdateTable(this);
    documentId = _is.ColumnInt(
      'documentId',
      this,
    );
    field = _is.ColumnString(
      'field',
      this,
    );
    clientOpId = _is.ColumnUuid(
      'clientOpId',
      this,
    );
    beforeJson = _is.ColumnString(
      'beforeJson',
      this,
    );
    afterJson = _is.ColumnString(
      'afterJson',
      this,
    );
    authorId = _is.ColumnInt(
      'authorId',
      this,
    );
    actorKind = _is.ColumnEnum(
      'actorKind',
      this,
      _is.EnumSerialization.byName,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DocumentMetaChangeUpdateTable updateTable;

  late final _is.ColumnInt documentId;

  /// themeId, pageSetup, language, frontMatter.
  late final _is.ColumnString field;

  late final _is.ColumnUuid clientOpId;

  late final _is.ColumnString beforeJson;

  late final _is.ColumnString afterJson;

  late final _is.ColumnInt authorId;

  late final _is.ColumnEnum<_ipbpecg8.ActorKind> actorKind;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    documentId,
    field,
    clientOpId,
    beforeJson,
    afterJson,
    authorId,
    actorKind,
    createdAt,
  ];
}

class DocumentMetaChangeInclude extends _is.IncludeObject {
  DocumentMetaChangeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DocumentMetaChange.t;
}

class DocumentMetaChangeIncludeList extends _is.IncludeList {
  DocumentMetaChangeIncludeList._({
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DocumentMetaChange.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DocumentMetaChange.t;
}

class DocumentMetaChangeRepository {
  const DocumentMetaChangeRepository._();

  /// Returns a list of [DocumentMetaChange]s matching the given query parameters.
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
  Future<List<DocumentMetaChange>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentMetaChangeTable>? orderBy,
    _is.OrderByListBuilder<DocumentMetaChangeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DocumentMetaChange>(
      where: where?.call(DocumentMetaChange.t),
      orderBy: orderBy?.call(DocumentMetaChange.t),
      orderByList: orderByList?.call(DocumentMetaChange.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DocumentMetaChange]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DocumentMetaChange.t`.
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
  _ida.Stream<List<DocumentMetaChange>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentMetaChangeTable>? orderBy,
    _is.OrderByListBuilder<DocumentMetaChangeTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DocumentMetaChange>(
      where: where?.call(DocumentMetaChange.t),
      orderBy: orderBy?.call(DocumentMetaChange.t),
      orderByList: orderByList?.call(DocumentMetaChange.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DocumentMetaChange] matching the given query parameters.
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
  Future<DocumentMetaChange?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? where,
    int? offset,
    _is.OrderByBuilder<DocumentMetaChangeTable>? orderBy,
    _is.OrderByListBuilder<DocumentMetaChangeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DocumentMetaChange>(
      where: where?.call(DocumentMetaChange.t),
      orderBy: orderBy?.call(DocumentMetaChange.t),
      orderByList: orderByList?.call(DocumentMetaChange.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DocumentMetaChange] by its [id] or null if no such row exists.
  Future<DocumentMetaChange?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DocumentMetaChange>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DocumentMetaChange]s in the list and returns the inserted rows.
  ///
  /// The returned [DocumentMetaChange]s will have their `id` fields set.
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
  Future<List<DocumentMetaChange>> insert(
    _is.DatabaseSession session,
    List<DocumentMetaChange> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DocumentMetaChange>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DocumentMetaChange] and returns the inserted row.
  ///
  /// The returned [DocumentMetaChange] will have its `id` field set.
  Future<DocumentMetaChange> insertRow(
    _is.DatabaseSession session,
    DocumentMetaChange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DocumentMetaChange>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DocumentMetaChange]s in the list and returns the resulting rows.
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
  /// The returned [DocumentMetaChange]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentMetaChange>> upsert(
    _is.DatabaseSession session,
    List<DocumentMetaChange> rows, {
    required _is.ColumnSelections<DocumentMetaChangeTable> conflictColumns,
    _is.ColumnSelections<DocumentMetaChangeTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DocumentMetaChange>(
      rows,
      conflictColumns: conflictColumns(DocumentMetaChange.t),
      updateColumns: updateColumns?.call(DocumentMetaChange.t),
      updateWhere: updateWhere?.call(DocumentMetaChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DocumentMetaChange] and returns the resulting row.
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
  /// The returned [DocumentMetaChange] will have its `id` field set.
  Future<DocumentMetaChange?> upsertRow(
    _is.DatabaseSession session,
    DocumentMetaChange row, {
    required _is.ColumnSelections<DocumentMetaChangeTable> conflictColumns,
    _is.ColumnSelections<DocumentMetaChangeTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DocumentMetaChange>(
      row,
      conflictColumns: conflictColumns(DocumentMetaChange.t),
      updateColumns: updateColumns?.call(DocumentMetaChange.t),
      updateWhere: updateWhere?.call(DocumentMetaChange.t),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentMetaChange]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentMetaChange>> update(
    _is.DatabaseSession session,
    List<DocumentMetaChange> rows, {
    _is.ColumnSelections<DocumentMetaChangeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DocumentMetaChange>(
      rows,
      columns: columns?.call(DocumentMetaChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DocumentMetaChange]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DocumentMetaChange> updateRow(
    _is.DatabaseSession session,
    DocumentMetaChange row, {
    _is.ColumnSelections<DocumentMetaChangeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DocumentMetaChange>(
      row,
      columns: columns?.call(DocumentMetaChange.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DocumentMetaChange] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DocumentMetaChange?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DocumentMetaChangeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DocumentMetaChange>(
      id,
      columnValues: columnValues(DocumentMetaChange.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentMetaChange]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentMetaChange>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DocumentMetaChangeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<DocumentMetaChangeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentMetaChangeTable>? orderBy,
    _is.OrderByListBuilder<DocumentMetaChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DocumentMetaChange>(
      columnValues: columnValues(DocumentMetaChange.t.updateTable),
      where: where(DocumentMetaChange.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentMetaChange.t),
      orderByList: orderByList?.call(DocumentMetaChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DocumentMetaChange]s in the list and returns the deleted rows.
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
  Future<List<DocumentMetaChange>> delete(
    _is.DatabaseSession session,
    List<DocumentMetaChange> rows, {
    _is.OrderByBuilder<DocumentMetaChangeTable>? orderBy,
    _is.OrderByListBuilder<DocumentMetaChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DocumentMetaChange>(
      rows,
      orderBy: orderBy?.call(DocumentMetaChange.t),
      orderByList: orderByList?.call(DocumentMetaChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DocumentMetaChange].
  Future<DocumentMetaChange> deleteRow(
    _is.DatabaseSession session,
    DocumentMetaChange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DocumentMetaChange>(
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
  Future<List<DocumentMetaChange>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentMetaChangeTable> where,
    _is.OrderByBuilder<DocumentMetaChangeTable>? orderBy,
    _is.OrderByListBuilder<DocumentMetaChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DocumentMetaChange>(
      where: where(DocumentMetaChange.t),
      orderBy: orderBy?.call(DocumentMetaChange.t),
      orderByList: orderByList?.call(DocumentMetaChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentMetaChangeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DocumentMetaChange>(
      where: where?.call(DocumentMetaChange.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DocumentMetaChange] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentMetaChangeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DocumentMetaChange>(
      where: where(DocumentMetaChange.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
