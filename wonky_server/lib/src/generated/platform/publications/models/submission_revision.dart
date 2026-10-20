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
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/publications/models/submission_values.dart'
    as _igthguer;

/// One submit of a submission (specs/18 §2, §6).
abstract class SubmissionRevision
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SubmissionRevision._({
    this.id,
    required this.submissionId,
    required this.sequence,
    required this.revision,
    this.versionId,
    required this.values,
    required this.payload,
    required this.submittedById,
    required this.submittedAt,
  });

  factory SubmissionRevision({
    int? id,
    required int submissionId,
    required int sequence,
    required int revision,
    int? versionId,
    required _igthguer.SubmissionValues values,
    required String payload,
    required int submittedById,
    required DateTime submittedAt,
  }) = _SubmissionRevisionImpl;

  factory SubmissionRevision.fromJson(Map<String, dynamic> jsonSerialization) {
    return SubmissionRevision(
      id: jsonSerialization['id'] as int?,
      submissionId: jsonSerialization['submissionId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      revision: jsonSerialization['revision'] as int,
      versionId: jsonSerialization['versionId'] as int?,
      values: _il4umwa0.Protocol().deserialize<_igthguer.SubmissionValues>(
        jsonSerialization['values'],
      ),
      payload: jsonSerialization['payload'] as String,
      submittedById: jsonSerialization['submittedById'] as int,
      submittedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['submittedAt'],
      ),
    );
  }

  static final t = SubmissionRevisionTable();

  static const db = SubmissionRevisionRepository._();

  @override
  int? id;

  int submissionId;

  /// 1, 2, … per submission.
  int sequence;

  /// The Write document revision that was sent.
  int revision;

  /// The named version of this submit (specs/18 P8).
  int? versionId;

  _igthguer.SubmissionValues values;

  /// The `submission.submitted` body sent for this submit (JSON), served
  /// again by `GET submissions/{id}/content` (specs/18 §7.3).
  String payload;

  int submittedById;

  DateTime submittedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SubmissionRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SubmissionRevision copyWith({
    int? id,
    int? submissionId,
    int? sequence,
    int? revision,
    int? versionId,
    _igthguer.SubmissionValues? values,
    String? payload,
    int? submittedById,
    DateTime? submittedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmissionRevision',
      if (id != null) 'id': id,
      'submissionId': submissionId,
      'sequence': sequence,
      'revision': revision,
      if (versionId != null) 'versionId': versionId,
      'values': values.toJson(),
      'payload': payload,
      'submittedById': submittedById,
      'submittedAt': submittedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SubmissionRevisionInclude include() {
    return SubmissionRevisionInclude._();
  }

  static SubmissionRevisionIncludeList includeList({
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionRevisionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionRevisionTable>? orderByList,
    SubmissionRevisionInclude? include,
  }) {
    return SubmissionRevisionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SubmissionRevision.t),
      orderByList: orderByList?.call(SubmissionRevision.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SubmissionRevisionImpl extends SubmissionRevision {
  _SubmissionRevisionImpl({
    int? id,
    required int submissionId,
    required int sequence,
    required int revision,
    int? versionId,
    required _igthguer.SubmissionValues values,
    required String payload,
    required int submittedById,
    required DateTime submittedAt,
  }) : super._(
         id: id,
         submissionId: submissionId,
         sequence: sequence,
         revision: revision,
         versionId: versionId,
         values: values,
         payload: payload,
         submittedById: submittedById,
         submittedAt: submittedAt,
       );

  /// Returns a shallow copy of this [SubmissionRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SubmissionRevision copyWith({
    Object? id = _Undefined,
    int? submissionId,
    int? sequence,
    int? revision,
    Object? versionId = _Undefined,
    _igthguer.SubmissionValues? values,
    String? payload,
    int? submittedById,
    DateTime? submittedAt,
  }) {
    return SubmissionRevision(
      id: id is int? ? id : this.id,
      submissionId: submissionId ?? this.submissionId,
      sequence: sequence ?? this.sequence,
      revision: revision ?? this.revision,
      versionId: versionId is int? ? versionId : this.versionId,
      values: values ?? this.values.copyWith(),
      payload: payload ?? this.payload,
      submittedById: submittedById ?? this.submittedById,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

class SubmissionRevisionUpdateTable
    extends _is.UpdateTable<SubmissionRevisionTable> {
  SubmissionRevisionUpdateTable(super.table);

  _is.ColumnValue<int, int> submissionId(int value) => _is.ColumnValue(
    table.submissionId,
    value,
  );

  _is.ColumnValue<int, int> sequence(int value) => _is.ColumnValue(
    table.sequence,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<int, int> versionId(int? value) => _is.ColumnValue(
    table.versionId,
    value,
  );

  _is.ColumnValue<_igthguer.SubmissionValues, _igthguer.SubmissionValues>
  values(_igthguer.SubmissionValues value) => _is.ColumnValue(
    table.values,
    value,
  );

  _is.ColumnValue<String, String> payload(String value) => _is.ColumnValue(
    table.payload,
    value,
  );

  _is.ColumnValue<int, int> submittedById(int value) => _is.ColumnValue(
    table.submittedById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> submittedAt(DateTime value) =>
      _is.ColumnValue(
        table.submittedAt,
        value,
      );
}

class SubmissionRevisionTable extends _is.Table<int?> {
  SubmissionRevisionTable({super.tableRelation})
    : super(tableName: 'submission_revision') {
    updateTable = SubmissionRevisionUpdateTable(this);
    submissionId = _is.ColumnInt(
      'submissionId',
      this,
    );
    sequence = _is.ColumnInt(
      'sequence',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    versionId = _is.ColumnInt(
      'versionId',
      this,
    );
    values = _is.ColumnSerializable<_igthguer.SubmissionValues>(
      'values',
      this,
    );
    payload = _is.ColumnString(
      'payload',
      this,
    );
    submittedById = _is.ColumnInt(
      'submittedById',
      this,
    );
    submittedAt = _is.ColumnDateTime(
      'submittedAt',
      this,
    );
  }

  late final SubmissionRevisionUpdateTable updateTable;

  late final _is.ColumnInt submissionId;

  /// 1, 2, … per submission.
  late final _is.ColumnInt sequence;

  /// The Write document revision that was sent.
  late final _is.ColumnInt revision;

  /// The named version of this submit (specs/18 P8).
  late final _is.ColumnInt versionId;

  late final _is.ColumnSerializable<_igthguer.SubmissionValues> values;

  /// The `submission.submitted` body sent for this submit (JSON), served
  /// again by `GET submissions/{id}/content` (specs/18 §7.3).
  late final _is.ColumnString payload;

  late final _is.ColumnInt submittedById;

  late final _is.ColumnDateTime submittedAt;

  @override
  List<_is.Column> get columns => [
    id,
    submissionId,
    sequence,
    revision,
    versionId,
    values,
    payload,
    submittedById,
    submittedAt,
  ];
}

class SubmissionRevisionInclude extends _is.IncludeObject {
  SubmissionRevisionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SubmissionRevision.t;
}

class SubmissionRevisionIncludeList extends _is.IncludeList {
  SubmissionRevisionIncludeList._({
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SubmissionRevision.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SubmissionRevision.t;
}

class SubmissionRevisionRepository {
  const SubmissionRevisionRepository._();

  /// Returns a list of [SubmissionRevision]s matching the given query parameters.
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
  Future<List<SubmissionRevision>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionRevisionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SubmissionRevision>(
      where: where?.call(SubmissionRevision.t),
      orderBy: orderBy?.call(SubmissionRevision.t),
      orderByList: orderByList?.call(SubmissionRevision.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [SubmissionRevision]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `SubmissionRevision.t`.
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
  _ida.Stream<List<SubmissionRevision>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionRevisionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionRevisionTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<SubmissionRevision>(
      where: where?.call(SubmissionRevision.t),
      orderBy: orderBy?.call(SubmissionRevision.t),
      orderByList: orderByList?.call(SubmissionRevision.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [SubmissionRevision] matching the given query parameters.
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
  Future<SubmissionRevision?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? where,
    int? offset,
    _is.OrderByBuilder<SubmissionRevisionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SubmissionRevision>(
      where: where?.call(SubmissionRevision.t),
      orderBy: orderBy?.call(SubmissionRevision.t),
      orderByList: orderByList?.call(SubmissionRevision.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SubmissionRevision] by its [id] or null if no such row exists.
  Future<SubmissionRevision?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SubmissionRevision>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SubmissionRevision]s in the list and returns the inserted rows.
  ///
  /// The returned [SubmissionRevision]s will have their `id` fields set.
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
  Future<List<SubmissionRevision>> insert(
    _is.DatabaseSession session,
    List<SubmissionRevision> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SubmissionRevision>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SubmissionRevision] and returns the inserted row.
  ///
  /// The returned [SubmissionRevision] will have its `id` field set.
  Future<SubmissionRevision> insertRow(
    _is.DatabaseSession session,
    SubmissionRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SubmissionRevision>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SubmissionRevision]s in the list and returns the resulting rows.
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
  /// The returned [SubmissionRevision]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SubmissionRevision>> upsert(
    _is.DatabaseSession session,
    List<SubmissionRevision> rows, {
    required _is.ColumnSelections<SubmissionRevisionTable> conflictColumns,
    _is.ColumnSelections<SubmissionRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SubmissionRevision>(
      rows,
      conflictColumns: conflictColumns(SubmissionRevision.t),
      updateColumns: updateColumns?.call(SubmissionRevision.t),
      updateWhere: updateWhere?.call(SubmissionRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SubmissionRevision] and returns the resulting row.
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
  /// The returned [SubmissionRevision] will have its `id` field set.
  Future<SubmissionRevision?> upsertRow(
    _is.DatabaseSession session,
    SubmissionRevision row, {
    required _is.ColumnSelections<SubmissionRevisionTable> conflictColumns,
    _is.ColumnSelections<SubmissionRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SubmissionRevision>(
      row,
      conflictColumns: conflictColumns(SubmissionRevision.t),
      updateColumns: updateColumns?.call(SubmissionRevision.t),
      updateWhere: updateWhere?.call(SubmissionRevision.t),
      transaction: transaction,
    );
  }

  /// Updates all [SubmissionRevision]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SubmissionRevision>> update(
    _is.DatabaseSession session,
    List<SubmissionRevision> rows, {
    _is.ColumnSelections<SubmissionRevisionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SubmissionRevision>(
      rows,
      columns: columns?.call(SubmissionRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SubmissionRevision]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SubmissionRevision> updateRow(
    _is.DatabaseSession session,
    SubmissionRevision row, {
    _is.ColumnSelections<SubmissionRevisionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SubmissionRevision>(
      row,
      columns: columns?.call(SubmissionRevision.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SubmissionRevision] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SubmissionRevision?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SubmissionRevisionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SubmissionRevision>(
      id,
      columnValues: columnValues(SubmissionRevision.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SubmissionRevision]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SubmissionRevision>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SubmissionRevisionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<SubmissionRevisionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionRevisionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SubmissionRevision>(
      columnValues: columnValues(SubmissionRevision.t.updateTable),
      where: where(SubmissionRevision.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SubmissionRevision.t),
      orderByList: orderByList?.call(SubmissionRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SubmissionRevision]s in the list and returns the deleted rows.
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
  Future<List<SubmissionRevision>> delete(
    _is.DatabaseSession session,
    List<SubmissionRevision> rows, {
    _is.OrderByBuilder<SubmissionRevisionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SubmissionRevision>(
      rows,
      orderBy: orderBy?.call(SubmissionRevision.t),
      orderByList: orderByList?.call(SubmissionRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SubmissionRevision].
  Future<SubmissionRevision> deleteRow(
    _is.DatabaseSession session,
    SubmissionRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SubmissionRevision>(
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
  Future<List<SubmissionRevision>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SubmissionRevisionTable> where,
    _is.OrderByBuilder<SubmissionRevisionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SubmissionRevision>(
      where: where(SubmissionRevision.t),
      orderBy: orderBy?.call(SubmissionRevision.t),
      orderByList: orderByList?.call(SubmissionRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionRevisionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SubmissionRevision>(
      where: where?.call(SubmissionRevision.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SubmissionRevision] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SubmissionRevisionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SubmissionRevision>(
      where: where(SubmissionRevision.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
