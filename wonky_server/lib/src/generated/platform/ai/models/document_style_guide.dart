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

/// The style guide a Write document uses (Write 09 §5.9): Apply style
/// follows it and the other assistant actions get it as context. A side
/// table keyed by the document's drive item (the document row is not
/// changed).
abstract class DocumentStyleGuide
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DocumentStyleGuide._({
    this.id,
    required this.itemId,
    required this.styleRef,
    this.setById,
    required this.updatedAt,
  });

  factory DocumentStyleGuide({
    int? id,
    required int itemId,
    required String styleRef,
    int? setById,
    required DateTime updatedAt,
  }) = _DocumentStyleGuideImpl;

  factory DocumentStyleGuide.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentStyleGuide(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      styleRef: jsonSerialization['styleRef'] as String,
      setById: jsonSerialization['setById'] as int?,
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = DocumentStyleGuideTable();

  static const db = DocumentStyleGuideRepository._();

  @override
  int? id;

  int itemId;

  /// `builtin:<key>` or `custom:<uuid>`.
  String styleRef;

  int? setById;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DocumentStyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocumentStyleGuide copyWith({
    int? id,
    int? itemId,
    String? styleRef,
    int? setById,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentStyleGuide',
      if (id != null) 'id': id,
      'itemId': itemId,
      'styleRef': styleRef,
      if (setById != null) 'setById': setById,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentStyleGuide',
      if (id != null) 'id': id,
      'itemId': itemId,
      'styleRef': styleRef,
      if (setById != null) 'setById': setById,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static DocumentStyleGuideInclude include() {
    return DocumentStyleGuideInclude._();
  }

  static DocumentStyleGuideIncludeList includeList({
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentStyleGuideTable>? orderBy,
    _is.OrderByListBuilder<DocumentStyleGuideTable>? orderByList,
    DocumentStyleGuideInclude? include,
  }) {
    return DocumentStyleGuideIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentStyleGuide.t),
      orderByList: orderByList?.call(DocumentStyleGuide.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentStyleGuideImpl extends DocumentStyleGuide {
  _DocumentStyleGuideImpl({
    int? id,
    required int itemId,
    required String styleRef,
    int? setById,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         itemId: itemId,
         styleRef: styleRef,
         setById: setById,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [DocumentStyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocumentStyleGuide copyWith({
    Object? id = _Undefined,
    int? itemId,
    String? styleRef,
    Object? setById = _Undefined,
    DateTime? updatedAt,
  }) {
    return DocumentStyleGuide(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      styleRef: styleRef ?? this.styleRef,
      setById: setById is int? ? setById : this.setById,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DocumentStyleGuideUpdateTable
    extends _is.UpdateTable<DocumentStyleGuideTable> {
  DocumentStyleGuideUpdateTable(super.table);

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<String, String> styleRef(String value) => _is.ColumnValue(
    table.styleRef,
    value,
  );

  _is.ColumnValue<int, int> setById(int? value) => _is.ColumnValue(
    table.setById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class DocumentStyleGuideTable extends _is.Table<int?> {
  DocumentStyleGuideTable({super.tableRelation})
    : super(tableName: 'document_style_guide') {
    updateTable = DocumentStyleGuideUpdateTable(this);
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    styleRef = _is.ColumnString(
      'styleRef',
      this,
    );
    setById = _is.ColumnInt(
      'setById',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final DocumentStyleGuideUpdateTable updateTable;

  late final _is.ColumnInt itemId;

  /// `builtin:<key>` or `custom:<uuid>`.
  late final _is.ColumnString styleRef;

  late final _is.ColumnInt setById;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    itemId,
    styleRef,
    setById,
    updatedAt,
  ];
}

class DocumentStyleGuideInclude extends _is.IncludeObject {
  DocumentStyleGuideInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DocumentStyleGuide.t;
}

class DocumentStyleGuideIncludeList extends _is.IncludeList {
  DocumentStyleGuideIncludeList._({
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DocumentStyleGuide.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DocumentStyleGuide.t;
}

class DocumentStyleGuideRepository {
  const DocumentStyleGuideRepository._();

  /// Returns a list of [DocumentStyleGuide]s matching the given query parameters.
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
  Future<List<DocumentStyleGuide>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentStyleGuideTable>? orderBy,
    _is.OrderByListBuilder<DocumentStyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DocumentStyleGuide>(
      where: where?.call(DocumentStyleGuide.t),
      orderBy: orderBy?.call(DocumentStyleGuide.t),
      orderByList: orderByList?.call(DocumentStyleGuide.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DocumentStyleGuide]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DocumentStyleGuide.t`.
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
  _ida.Stream<List<DocumentStyleGuide>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentStyleGuideTable>? orderBy,
    _is.OrderByListBuilder<DocumentStyleGuideTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DocumentStyleGuide>(
      where: where?.call(DocumentStyleGuide.t),
      orderBy: orderBy?.call(DocumentStyleGuide.t),
      orderByList: orderByList?.call(DocumentStyleGuide.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DocumentStyleGuide] matching the given query parameters.
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
  Future<DocumentStyleGuide?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? where,
    int? offset,
    _is.OrderByBuilder<DocumentStyleGuideTable>? orderBy,
    _is.OrderByListBuilder<DocumentStyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DocumentStyleGuide>(
      where: where?.call(DocumentStyleGuide.t),
      orderBy: orderBy?.call(DocumentStyleGuide.t),
      orderByList: orderByList?.call(DocumentStyleGuide.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DocumentStyleGuide] by its [id] or null if no such row exists.
  Future<DocumentStyleGuide?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DocumentStyleGuide>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DocumentStyleGuide]s in the list and returns the inserted rows.
  ///
  /// The returned [DocumentStyleGuide]s will have their `id` fields set.
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
  Future<List<DocumentStyleGuide>> insert(
    _is.DatabaseSession session,
    List<DocumentStyleGuide> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DocumentStyleGuide>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DocumentStyleGuide] and returns the inserted row.
  ///
  /// The returned [DocumentStyleGuide] will have its `id` field set.
  Future<DocumentStyleGuide> insertRow(
    _is.DatabaseSession session,
    DocumentStyleGuide row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DocumentStyleGuide>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DocumentStyleGuide]s in the list and returns the resulting rows.
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
  /// The returned [DocumentStyleGuide]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentStyleGuide>> upsert(
    _is.DatabaseSession session,
    List<DocumentStyleGuide> rows, {
    required _is.ColumnSelections<DocumentStyleGuideTable> conflictColumns,
    _is.ColumnSelections<DocumentStyleGuideTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DocumentStyleGuide>(
      rows,
      conflictColumns: conflictColumns(DocumentStyleGuide.t),
      updateColumns: updateColumns?.call(DocumentStyleGuide.t),
      updateWhere: updateWhere?.call(DocumentStyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DocumentStyleGuide] and returns the resulting row.
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
  /// The returned [DocumentStyleGuide] will have its `id` field set.
  Future<DocumentStyleGuide?> upsertRow(
    _is.DatabaseSession session,
    DocumentStyleGuide row, {
    required _is.ColumnSelections<DocumentStyleGuideTable> conflictColumns,
    _is.ColumnSelections<DocumentStyleGuideTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DocumentStyleGuide>(
      row,
      conflictColumns: conflictColumns(DocumentStyleGuide.t),
      updateColumns: updateColumns?.call(DocumentStyleGuide.t),
      updateWhere: updateWhere?.call(DocumentStyleGuide.t),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentStyleGuide]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentStyleGuide>> update(
    _is.DatabaseSession session,
    List<DocumentStyleGuide> rows, {
    _is.ColumnSelections<DocumentStyleGuideTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DocumentStyleGuide>(
      rows,
      columns: columns?.call(DocumentStyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DocumentStyleGuide]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DocumentStyleGuide> updateRow(
    _is.DatabaseSession session,
    DocumentStyleGuide row, {
    _is.ColumnSelections<DocumentStyleGuideTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DocumentStyleGuide>(
      row,
      columns: columns?.call(DocumentStyleGuide.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DocumentStyleGuide] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DocumentStyleGuide?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DocumentStyleGuideUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DocumentStyleGuide>(
      id,
      columnValues: columnValues(DocumentStyleGuide.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentStyleGuide]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentStyleGuide>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DocumentStyleGuideUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<DocumentStyleGuideTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentStyleGuideTable>? orderBy,
    _is.OrderByListBuilder<DocumentStyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DocumentStyleGuide>(
      columnValues: columnValues(DocumentStyleGuide.t.updateTable),
      where: where(DocumentStyleGuide.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentStyleGuide.t),
      orderByList: orderByList?.call(DocumentStyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DocumentStyleGuide]s in the list and returns the deleted rows.
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
  Future<List<DocumentStyleGuide>> delete(
    _is.DatabaseSession session,
    List<DocumentStyleGuide> rows, {
    _is.OrderByBuilder<DocumentStyleGuideTable>? orderBy,
    _is.OrderByListBuilder<DocumentStyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DocumentStyleGuide>(
      rows,
      orderBy: orderBy?.call(DocumentStyleGuide.t),
      orderByList: orderByList?.call(DocumentStyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DocumentStyleGuide].
  Future<DocumentStyleGuide> deleteRow(
    _is.DatabaseSession session,
    DocumentStyleGuide row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DocumentStyleGuide>(
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
  Future<List<DocumentStyleGuide>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentStyleGuideTable> where,
    _is.OrderByBuilder<DocumentStyleGuideTable>? orderBy,
    _is.OrderByListBuilder<DocumentStyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DocumentStyleGuide>(
      where: where(DocumentStyleGuide.t),
      orderBy: orderBy?.call(DocumentStyleGuide.t),
      orderByList: orderByList?.call(DocumentStyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentStyleGuideTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DocumentStyleGuide>(
      where: where?.call(DocumentStyleGuide.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DocumentStyleGuide] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentStyleGuideTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DocumentStyleGuide>(
      where: where(DocumentStyleGuide.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
