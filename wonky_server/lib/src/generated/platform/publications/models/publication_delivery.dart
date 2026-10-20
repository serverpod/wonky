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

/// A webhook in the outbox (specs/18 §7.2): retried with the same id until
/// the blog answers 2xx or the retries run out.
abstract class PublicationDelivery
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PublicationDelivery._({
    this.id,
    required this.publicationId,
    this.submissionId,
    required this.webhookId,
    required this.type,
    this.sequence,
    required this.payload,
    int? attempts,
    this.nextAttemptAt,
    this.leaseUntil,
    this.lastStatus,
    this.lastError,
    this.deliveredAt,
    this.failedAt,
    required this.createdAt,
  }) : attempts = attempts ?? 0;

  factory PublicationDelivery({
    int? id,
    required int publicationId,
    int? submissionId,
    required String webhookId,
    required String type,
    int? sequence,
    required String payload,
    int? attempts,
    DateTime? nextAttemptAt,
    DateTime? leaseUntil,
    int? lastStatus,
    String? lastError,
    DateTime? deliveredAt,
    DateTime? failedAt,
    required DateTime createdAt,
  }) = _PublicationDeliveryImpl;

  factory PublicationDelivery.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationDelivery(
      id: jsonSerialization['id'] as int?,
      publicationId: jsonSerialization['publicationId'] as int,
      submissionId: jsonSerialization['submissionId'] as int?,
      webhookId: jsonSerialization['webhookId'] as String,
      type: jsonSerialization['type'] as String,
      sequence: jsonSerialization['sequence'] as int?,
      payload: jsonSerialization['payload'] as String,
      attempts: jsonSerialization['attempts'] as int?,
      nextAttemptAt: jsonSerialization['nextAttemptAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['nextAttemptAt'],
            ),
      leaseUntil: jsonSerialization['leaseUntil'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['leaseUntil']),
      lastStatus: jsonSerialization['lastStatus'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      deliveredAt: jsonSerialization['deliveredAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['deliveredAt'],
            ),
      failedAt: jsonSerialization['failedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['failedAt']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = PublicationDeliveryTable();

  static const db = PublicationDeliveryRepository._();

  @override
  int? id;

  int publicationId;

  int? submissionId;

  /// "msg_<uuid>", the `webhook-id` header; stable across retries.
  String webhookId;

  String type;

  /// The submit's sequence of a `submission.submitted`.
  int? sequence;

  /// The JSON body.
  String payload;

  int attempts;

  /// Null once delivered or given up.
  DateTime? nextAttemptAt;

  /// Lease of the instance sending it (specs/13 §4).
  DateTime? leaseUntil;

  /// HTTP status of the last attempt; 0 = network error or timeout.
  int? lastStatus;

  String? lastError;

  DateTime? deliveredAt;

  DateTime? failedAt;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PublicationDelivery]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationDelivery copyWith({
    int? id,
    int? publicationId,
    int? submissionId,
    String? webhookId,
    String? type,
    int? sequence,
    String? payload,
    int? attempts,
    DateTime? nextAttemptAt = const _is.$UndefinedDateTime(),
    DateTime? leaseUntil = const _is.$UndefinedDateTime(),
    int? lastStatus,
    String? lastError,
    DateTime? deliveredAt = const _is.$UndefinedDateTime(),
    DateTime? failedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationDelivery',
      if (id != null) 'id': id,
      'publicationId': publicationId,
      if (submissionId != null) 'submissionId': submissionId,
      'webhookId': webhookId,
      'type': type,
      if (sequence != null) 'sequence': sequence,
      'payload': payload,
      'attempts': attempts,
      if (nextAttemptAt != null) 'nextAttemptAt': nextAttemptAt?.toJson(),
      if (leaseUntil != null) 'leaseUntil': leaseUntil?.toJson(),
      if (lastStatus != null) 'lastStatus': lastStatus,
      if (lastError != null) 'lastError': lastError,
      if (deliveredAt != null) 'deliveredAt': deliveredAt?.toJson(),
      if (failedAt != null) 'failedAt': failedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PublicationDeliveryInclude include() {
    return PublicationDeliveryInclude._();
  }

  static PublicationDeliveryIncludeList includeList({
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationDeliveryTable>? orderBy,
    _is.OrderByListBuilder<PublicationDeliveryTable>? orderByList,
    PublicationDeliveryInclude? include,
  }) {
    return PublicationDeliveryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationDelivery.t),
      orderByList: orderByList?.call(PublicationDelivery.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationDeliveryImpl extends PublicationDelivery {
  _PublicationDeliveryImpl({
    int? id,
    required int publicationId,
    int? submissionId,
    required String webhookId,
    required String type,
    int? sequence,
    required String payload,
    int? attempts,
    DateTime? nextAttemptAt,
    DateTime? leaseUntil,
    int? lastStatus,
    String? lastError,
    DateTime? deliveredAt,
    DateTime? failedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         publicationId: publicationId,
         submissionId: submissionId,
         webhookId: webhookId,
         type: type,
         sequence: sequence,
         payload: payload,
         attempts: attempts,
         nextAttemptAt: nextAttemptAt,
         leaseUntil: leaseUntil,
         lastStatus: lastStatus,
         lastError: lastError,
         deliveredAt: deliveredAt,
         failedAt: failedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PublicationDelivery]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationDelivery copyWith({
    Object? id = _Undefined,
    int? publicationId,
    Object? submissionId = _Undefined,
    String? webhookId,
    String? type,
    Object? sequence = _Undefined,
    String? payload,
    int? attempts,
    DateTime? nextAttemptAt = const _is.$UndefinedDateTime(),
    DateTime? leaseUntil = const _is.$UndefinedDateTime(),
    Object? lastStatus = _Undefined,
    Object? lastError = _Undefined,
    DateTime? deliveredAt = const _is.$UndefinedDateTime(),
    DateTime? failedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
  }) {
    return PublicationDelivery(
      id: id is int? ? id : this.id,
      publicationId: publicationId ?? this.publicationId,
      submissionId: submissionId is int? ? submissionId : this.submissionId,
      webhookId: webhookId ?? this.webhookId,
      type: type ?? this.type,
      sequence: sequence is int? ? sequence : this.sequence,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt is _is.UndefinedSentinel
          ? this.nextAttemptAt
          : nextAttemptAt,
      leaseUntil: leaseUntil is _is.UndefinedSentinel
          ? this.leaseUntil
          : leaseUntil,
      lastStatus: lastStatus is int? ? lastStatus : this.lastStatus,
      lastError: lastError is String? ? lastError : this.lastError,
      deliveredAt: deliveredAt is _is.UndefinedSentinel
          ? this.deliveredAt
          : deliveredAt,
      failedAt: failedAt is _is.UndefinedSentinel ? this.failedAt : failedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PublicationDeliveryUpdateTable
    extends _is.UpdateTable<PublicationDeliveryTable> {
  PublicationDeliveryUpdateTable(super.table);

  _is.ColumnValue<int, int> publicationId(int value) => _is.ColumnValue(
    table.publicationId,
    value,
  );

  _is.ColumnValue<int, int> submissionId(int? value) => _is.ColumnValue(
    table.submissionId,
    value,
  );

  _is.ColumnValue<String, String> webhookId(String value) => _is.ColumnValue(
    table.webhookId,
    value,
  );

  _is.ColumnValue<String, String> type(String value) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<int, int> sequence(int? value) => _is.ColumnValue(
    table.sequence,
    value,
  );

  _is.ColumnValue<String, String> payload(String value) => _is.ColumnValue(
    table.payload,
    value,
  );

  _is.ColumnValue<int, int> attempts(int value) => _is.ColumnValue(
    table.attempts,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> nextAttemptAt(DateTime? value) =>
      _is.ColumnValue(
        table.nextAttemptAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> leaseUntil(DateTime? value) =>
      _is.ColumnValue(
        table.leaseUntil,
        value,
      );

  _is.ColumnValue<int, int> lastStatus(int? value) => _is.ColumnValue(
    table.lastStatus,
    value,
  );

  _is.ColumnValue<String, String> lastError(String? value) => _is.ColumnValue(
    table.lastError,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> deliveredAt(DateTime? value) =>
      _is.ColumnValue(
        table.deliveredAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> failedAt(DateTime? value) =>
      _is.ColumnValue(
        table.failedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class PublicationDeliveryTable extends _is.Table<int?> {
  PublicationDeliveryTable({super.tableRelation})
    : super(tableName: 'publication_delivery') {
    updateTable = PublicationDeliveryUpdateTable(this);
    publicationId = _is.ColumnInt(
      'publicationId',
      this,
    );
    submissionId = _is.ColumnInt(
      'submissionId',
      this,
    );
    webhookId = _is.ColumnString(
      'webhookId',
      this,
    );
    type = _is.ColumnString(
      'type',
      this,
    );
    sequence = _is.ColumnInt(
      'sequence',
      this,
    );
    payload = _is.ColumnString(
      'payload',
      this,
    );
    attempts = _is.ColumnInt(
      'attempts',
      this,
      hasDefault: true,
    );
    nextAttemptAt = _is.ColumnDateTime(
      'nextAttemptAt',
      this,
    );
    leaseUntil = _is.ColumnDateTime(
      'leaseUntil',
      this,
    );
    lastStatus = _is.ColumnInt(
      'lastStatus',
      this,
    );
    lastError = _is.ColumnString(
      'lastError',
      this,
    );
    deliveredAt = _is.ColumnDateTime(
      'deliveredAt',
      this,
    );
    failedAt = _is.ColumnDateTime(
      'failedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final PublicationDeliveryUpdateTable updateTable;

  late final _is.ColumnInt publicationId;

  late final _is.ColumnInt submissionId;

  /// "msg_<uuid>", the `webhook-id` header; stable across retries.
  late final _is.ColumnString webhookId;

  late final _is.ColumnString type;

  /// The submit's sequence of a `submission.submitted`.
  late final _is.ColumnInt sequence;

  /// The JSON body.
  late final _is.ColumnString payload;

  late final _is.ColumnInt attempts;

  /// Null once delivered or given up.
  late final _is.ColumnDateTime nextAttemptAt;

  /// Lease of the instance sending it (specs/13 §4).
  late final _is.ColumnDateTime leaseUntil;

  /// HTTP status of the last attempt; 0 = network error or timeout.
  late final _is.ColumnInt lastStatus;

  late final _is.ColumnString lastError;

  late final _is.ColumnDateTime deliveredAt;

  late final _is.ColumnDateTime failedAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    publicationId,
    submissionId,
    webhookId,
    type,
    sequence,
    payload,
    attempts,
    nextAttemptAt,
    leaseUntil,
    lastStatus,
    lastError,
    deliveredAt,
    failedAt,
    createdAt,
  ];
}

class PublicationDeliveryInclude extends _is.IncludeObject {
  PublicationDeliveryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PublicationDelivery.t;
}

class PublicationDeliveryIncludeList extends _is.IncludeList {
  PublicationDeliveryIncludeList._({
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PublicationDelivery.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PublicationDelivery.t;
}

class PublicationDeliveryRepository {
  const PublicationDeliveryRepository._();

  /// Returns a list of [PublicationDelivery]s matching the given query parameters.
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
  Future<List<PublicationDelivery>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationDeliveryTable>? orderBy,
    _is.OrderByListBuilder<PublicationDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PublicationDelivery>(
      where: where?.call(PublicationDelivery.t),
      orderBy: orderBy?.call(PublicationDelivery.t),
      orderByList: orderByList?.call(PublicationDelivery.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PublicationDelivery]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PublicationDelivery.t`.
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
  _ida.Stream<List<PublicationDelivery>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationDeliveryTable>? orderBy,
    _is.OrderByListBuilder<PublicationDeliveryTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PublicationDelivery>(
      where: where?.call(PublicationDelivery.t),
      orderBy: orderBy?.call(PublicationDelivery.t),
      orderByList: orderByList?.call(PublicationDelivery.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PublicationDelivery] matching the given query parameters.
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
  Future<PublicationDelivery?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? where,
    int? offset,
    _is.OrderByBuilder<PublicationDeliveryTable>? orderBy,
    _is.OrderByListBuilder<PublicationDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PublicationDelivery>(
      where: where?.call(PublicationDelivery.t),
      orderBy: orderBy?.call(PublicationDelivery.t),
      orderByList: orderByList?.call(PublicationDelivery.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PublicationDelivery] by its [id] or null if no such row exists.
  Future<PublicationDelivery?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PublicationDelivery>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PublicationDelivery]s in the list and returns the inserted rows.
  ///
  /// The returned [PublicationDelivery]s will have their `id` fields set.
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
  Future<List<PublicationDelivery>> insert(
    _is.DatabaseSession session,
    List<PublicationDelivery> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PublicationDelivery>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PublicationDelivery] and returns the inserted row.
  ///
  /// The returned [PublicationDelivery] will have its `id` field set.
  Future<PublicationDelivery> insertRow(
    _is.DatabaseSession session,
    PublicationDelivery row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PublicationDelivery>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PublicationDelivery]s in the list and returns the resulting rows.
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
  /// The returned [PublicationDelivery]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationDelivery>> upsert(
    _is.DatabaseSession session,
    List<PublicationDelivery> rows, {
    required _is.ColumnSelections<PublicationDeliveryTable> conflictColumns,
    _is.ColumnSelections<PublicationDeliveryTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PublicationDelivery>(
      rows,
      conflictColumns: conflictColumns(PublicationDelivery.t),
      updateColumns: updateColumns?.call(PublicationDelivery.t),
      updateWhere: updateWhere?.call(PublicationDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PublicationDelivery] and returns the resulting row.
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
  /// The returned [PublicationDelivery] will have its `id` field set.
  Future<PublicationDelivery?> upsertRow(
    _is.DatabaseSession session,
    PublicationDelivery row, {
    required _is.ColumnSelections<PublicationDeliveryTable> conflictColumns,
    _is.ColumnSelections<PublicationDeliveryTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PublicationDelivery>(
      row,
      conflictColumns: conflictColumns(PublicationDelivery.t),
      updateColumns: updateColumns?.call(PublicationDelivery.t),
      updateWhere: updateWhere?.call(PublicationDelivery.t),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationDelivery]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationDelivery>> update(
    _is.DatabaseSession session,
    List<PublicationDelivery> rows, {
    _is.ColumnSelections<PublicationDeliveryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PublicationDelivery>(
      rows,
      columns: columns?.call(PublicationDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PublicationDelivery]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PublicationDelivery> updateRow(
    _is.DatabaseSession session,
    PublicationDelivery row, {
    _is.ColumnSelections<PublicationDeliveryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PublicationDelivery>(
      row,
      columns: columns?.call(PublicationDelivery.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PublicationDelivery] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PublicationDelivery?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PublicationDeliveryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PublicationDelivery>(
      id,
      columnValues: columnValues(PublicationDelivery.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationDelivery]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationDelivery>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PublicationDeliveryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PublicationDeliveryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationDeliveryTable>? orderBy,
    _is.OrderByListBuilder<PublicationDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PublicationDelivery>(
      columnValues: columnValues(PublicationDelivery.t.updateTable),
      where: where(PublicationDelivery.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationDelivery.t),
      orderByList: orderByList?.call(PublicationDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PublicationDelivery]s in the list and returns the deleted rows.
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
  Future<List<PublicationDelivery>> delete(
    _is.DatabaseSession session,
    List<PublicationDelivery> rows, {
    _is.OrderByBuilder<PublicationDeliveryTable>? orderBy,
    _is.OrderByListBuilder<PublicationDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PublicationDelivery>(
      rows,
      orderBy: orderBy?.call(PublicationDelivery.t),
      orderByList: orderByList?.call(PublicationDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PublicationDelivery].
  Future<PublicationDelivery> deleteRow(
    _is.DatabaseSession session,
    PublicationDelivery row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PublicationDelivery>(
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
  Future<List<PublicationDelivery>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationDeliveryTable> where,
    _is.OrderByBuilder<PublicationDeliveryTable>? orderBy,
    _is.OrderByListBuilder<PublicationDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PublicationDelivery>(
      where: where(PublicationDelivery.t),
      orderBy: orderBy?.call(PublicationDelivery.t),
      orderByList: orderByList?.call(PublicationDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationDeliveryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PublicationDelivery>(
      where: where?.call(PublicationDelivery.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PublicationDelivery] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationDeliveryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PublicationDelivery>(
      where: where(PublicationDelivery.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
