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
import '../../../platform/publications/models/submission_delivery_state.dart'
    as _ifp7j30v;
import '../../../platform/publications/models/submission_status.dart'
    as _igclxad1;
import '../../../platform/publications/models/submission_values.dart'
    as _igthguer;

/// The link between a Write document and a publication (specs/18 §2, §6).
/// A document has at most one.
abstract class Submission
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Submission._({
    this.id,
    _is.UuidValue? uuid,
    required this.publicationId,
    required this.itemId,
    this.ref,
    required this.status,
    this.statusBeforeSubmit,
    this.delivery,
    required this.values,
    this.publicUrl,
    this.feedbackThreadId,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.disconnectedAt,
  }) : uuid = uuid ?? const _is.Uuid().v7obj();

  factory Submission({
    int? id,
    _is.UuidValue? uuid,
    required int publicationId,
    required int itemId,
    String? ref,
    required _igclxad1.SubmissionStatus status,
    _igclxad1.SubmissionStatus? statusBeforeSubmit,
    _ifp7j30v.SubmissionDeliveryState? delivery,
    required _igthguer.SubmissionValues values,
    String? publicUrl,
    int? feedbackThreadId,
    required int createdById,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? disconnectedAt,
  }) = _SubmissionImpl;

  factory Submission.fromJson(Map<String, dynamic> jsonSerialization) {
    return Submission(
      id: jsonSerialization['id'] as int?,
      uuid: jsonSerialization['uuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      publicationId: jsonSerialization['publicationId'] as int,
      itemId: jsonSerialization['itemId'] as int,
      ref: jsonSerialization['ref'] as String?,
      status: _igclxad1.SubmissionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      statusBeforeSubmit: jsonSerialization['statusBeforeSubmit'] == null
          ? null
          : _igclxad1.SubmissionStatus.fromJson(
              (jsonSerialization['statusBeforeSubmit'] as String),
            ),
      delivery: jsonSerialization['delivery'] == null
          ? null
          : _ifp7j30v.SubmissionDeliveryState.fromJson(
              (jsonSerialization['delivery'] as String),
            ),
      values: _il4umwa0.Protocol().deserialize<_igthguer.SubmissionValues>(
        jsonSerialization['values'],
      ),
      publicUrl: jsonSerialization['publicUrl'] as String?,
      feedbackThreadId: jsonSerialization['feedbackThreadId'] as int?,
      createdById: jsonSerialization['createdById'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      disconnectedAt: jsonSerialization['disconnectedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['disconnectedAt'],
            ),
    );
  }

  static final t = SubmissionTable();

  static const db = SubmissionRepository._();

  @override
  int? id;

  /// Public as "sub_<uuid>".
  _is.UuidValue uuid;

  int publicationId;

  int itemId;

  /// The blog's own reference from the contributor link.
  String? ref;

  _igclxad1.SubmissionStatus status;

  /// The status before the last submit, restored when its delivery fails
  /// (specs/18 §7.2).
  _igclxad1.SubmissionStatus? statusBeforeSubmit;

  /// Null = the last delivery was accepted.
  _ifp7j30v.SubmissionDeliveryState? delivery;

  _igthguer.SubmissionValues values;

  String? publicUrl;

  /// The document-level comment thread of the publication's messages.
  int? feedbackThreadId;

  int createdById;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? disconnectedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Submission]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Submission copyWith({
    int? id,
    _is.UuidValue? uuid,
    int? publicationId,
    int? itemId,
    String? ref,
    _igclxad1.SubmissionStatus? status,
    _igclxad1.SubmissionStatus? statusBeforeSubmit,
    _ifp7j30v.SubmissionDeliveryState? delivery,
    _igthguer.SubmissionValues? values,
    String? publicUrl,
    int? feedbackThreadId,
    int? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? disconnectedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Submission',
      if (id != null) 'id': id,
      'uuid': uuid.toJson(),
      'publicationId': publicationId,
      'itemId': itemId,
      if (ref != null) 'ref': ref,
      'status': status.toJson(),
      if (statusBeforeSubmit != null)
        'statusBeforeSubmit': statusBeforeSubmit?.toJson(),
      if (delivery != null) 'delivery': delivery?.toJson(),
      'values': values.toJson(),
      if (publicUrl != null) 'publicUrl': publicUrl,
      if (feedbackThreadId != null) 'feedbackThreadId': feedbackThreadId,
      'createdById': createdById,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (disconnectedAt != null) 'disconnectedAt': disconnectedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SubmissionInclude include() {
    return SubmissionInclude._();
  }

  static SubmissionIncludeList includeList({
    _is.WhereExpressionBuilder<SubmissionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionTable>? orderByList,
    SubmissionInclude? include,
  }) {
    return SubmissionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Submission.t),
      orderByList: orderByList?.call(Submission.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SubmissionImpl extends Submission {
  _SubmissionImpl({
    int? id,
    _is.UuidValue? uuid,
    required int publicationId,
    required int itemId,
    String? ref,
    required _igclxad1.SubmissionStatus status,
    _igclxad1.SubmissionStatus? statusBeforeSubmit,
    _ifp7j30v.SubmissionDeliveryState? delivery,
    required _igthguer.SubmissionValues values,
    String? publicUrl,
    int? feedbackThreadId,
    required int createdById,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? disconnectedAt,
  }) : super._(
         id: id,
         uuid: uuid,
         publicationId: publicationId,
         itemId: itemId,
         ref: ref,
         status: status,
         statusBeforeSubmit: statusBeforeSubmit,
         delivery: delivery,
         values: values,
         publicUrl: publicUrl,
         feedbackThreadId: feedbackThreadId,
         createdById: createdById,
         createdAt: createdAt,
         updatedAt: updatedAt,
         disconnectedAt: disconnectedAt,
       );

  /// Returns a shallow copy of this [Submission]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Submission copyWith({
    Object? id = _Undefined,
    _is.UuidValue? uuid,
    int? publicationId,
    int? itemId,
    Object? ref = _Undefined,
    _igclxad1.SubmissionStatus? status,
    Object? statusBeforeSubmit = _Undefined,
    Object? delivery = _Undefined,
    _igthguer.SubmissionValues? values,
    Object? publicUrl = _Undefined,
    Object? feedbackThreadId = _Undefined,
    int? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? disconnectedAt = const _is.$UndefinedDateTime(),
  }) {
    return Submission(
      id: id is int? ? id : this.id,
      uuid: uuid ?? this.uuid,
      publicationId: publicationId ?? this.publicationId,
      itemId: itemId ?? this.itemId,
      ref: ref is String? ? ref : this.ref,
      status: status ?? this.status,
      statusBeforeSubmit: statusBeforeSubmit is _igclxad1.SubmissionStatus?
          ? statusBeforeSubmit
          : this.statusBeforeSubmit,
      delivery: delivery is _ifp7j30v.SubmissionDeliveryState?
          ? delivery
          : this.delivery,
      values: values ?? this.values.copyWith(),
      publicUrl: publicUrl is String? ? publicUrl : this.publicUrl,
      feedbackThreadId: feedbackThreadId is int?
          ? feedbackThreadId
          : this.feedbackThreadId,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      disconnectedAt: disconnectedAt is _is.UndefinedSentinel
          ? this.disconnectedAt
          : disconnectedAt,
    );
  }
}

class SubmissionUpdateTable extends _is.UpdateTable<SubmissionTable> {
  SubmissionUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> uuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.uuid,
        value,
      );

  _is.ColumnValue<int, int> publicationId(int value) => _is.ColumnValue(
    table.publicationId,
    value,
  );

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<String, String> ref(String? value) => _is.ColumnValue(
    table.ref,
    value,
  );

  _is.ColumnValue<_igclxad1.SubmissionStatus, _igclxad1.SubmissionStatus>
  status(_igclxad1.SubmissionStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<_igclxad1.SubmissionStatus, _igclxad1.SubmissionStatus>
  statusBeforeSubmit(_igclxad1.SubmissionStatus? value) => _is.ColumnValue(
    table.statusBeforeSubmit,
    value,
  );

  _is.ColumnValue<
    _ifp7j30v.SubmissionDeliveryState,
    _ifp7j30v.SubmissionDeliveryState
  >
  delivery(_ifp7j30v.SubmissionDeliveryState? value) => _is.ColumnValue(
    table.delivery,
    value,
  );

  _is.ColumnValue<_igthguer.SubmissionValues, _igthguer.SubmissionValues>
  values(_igthguer.SubmissionValues value) => _is.ColumnValue(
    table.values,
    value,
  );

  _is.ColumnValue<String, String> publicUrl(String? value) => _is.ColumnValue(
    table.publicUrl,
    value,
  );

  _is.ColumnValue<int, int> feedbackThreadId(int? value) => _is.ColumnValue(
    table.feedbackThreadId,
    value,
  );

  _is.ColumnValue<int, int> createdById(int value) => _is.ColumnValue(
    table.createdById,
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

  _is.ColumnValue<DateTime, DateTime> disconnectedAt(DateTime? value) =>
      _is.ColumnValue(
        table.disconnectedAt,
        value,
      );
}

class SubmissionTable extends _is.Table<int?> {
  SubmissionTable({super.tableRelation}) : super(tableName: 'submission') {
    updateTable = SubmissionUpdateTable(this);
    uuid = _is.ColumnUuid(
      'uuid',
      this,
    );
    publicationId = _is.ColumnInt(
      'publicationId',
      this,
    );
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    ref = _is.ColumnString(
      'ref',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    statusBeforeSubmit = _is.ColumnEnum(
      'statusBeforeSubmit',
      this,
      _is.EnumSerialization.byName,
    );
    delivery = _is.ColumnEnum(
      'delivery',
      this,
      _is.EnumSerialization.byName,
    );
    values = _is.ColumnSerializable<_igthguer.SubmissionValues>(
      'values',
      this,
    );
    publicUrl = _is.ColumnString(
      'publicUrl',
      this,
    );
    feedbackThreadId = _is.ColumnInt(
      'feedbackThreadId',
      this,
    );
    createdById = _is.ColumnInt(
      'createdById',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
    disconnectedAt = _is.ColumnDateTime(
      'disconnectedAt',
      this,
    );
  }

  late final SubmissionUpdateTable updateTable;

  /// Public as "sub_<uuid>".
  late final _is.ColumnUuid uuid;

  late final _is.ColumnInt publicationId;

  late final _is.ColumnInt itemId;

  /// The blog's own reference from the contributor link.
  late final _is.ColumnString ref;

  late final _is.ColumnEnum<_igclxad1.SubmissionStatus> status;

  /// The status before the last submit, restored when its delivery fails
  /// (specs/18 §7.2).
  late final _is.ColumnEnum<_igclxad1.SubmissionStatus> statusBeforeSubmit;

  /// Null = the last delivery was accepted.
  late final _is.ColumnEnum<_ifp7j30v.SubmissionDeliveryState> delivery;

  late final _is.ColumnSerializable<_igthguer.SubmissionValues> values;

  late final _is.ColumnString publicUrl;

  /// The document-level comment thread of the publication's messages.
  late final _is.ColumnInt feedbackThreadId;

  late final _is.ColumnInt createdById;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime disconnectedAt;

  @override
  List<_is.Column> get columns => [
    id,
    uuid,
    publicationId,
    itemId,
    ref,
    status,
    statusBeforeSubmit,
    delivery,
    values,
    publicUrl,
    feedbackThreadId,
    createdById,
    createdAt,
    updatedAt,
    disconnectedAt,
  ];
}

class SubmissionInclude extends _is.IncludeObject {
  SubmissionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Submission.t;
}

class SubmissionIncludeList extends _is.IncludeList {
  SubmissionIncludeList._({
    _is.WhereExpressionBuilder<SubmissionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Submission.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Submission.t;
}

class SubmissionRepository {
  const SubmissionRepository._();

  /// Returns a list of [Submission]s matching the given query parameters.
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
  Future<List<Submission>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Submission>(
      where: where?.call(Submission.t),
      orderBy: orderBy?.call(Submission.t),
      orderByList: orderByList?.call(Submission.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Submission]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Submission.t`.
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
  _ida.Stream<List<Submission>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Submission>(
      where: where?.call(Submission.t),
      orderBy: orderBy?.call(Submission.t),
      orderByList: orderByList?.call(Submission.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Submission] matching the given query parameters.
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
  Future<Submission?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionTable>? where,
    int? offset,
    _is.OrderByBuilder<SubmissionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Submission>(
      where: where?.call(Submission.t),
      orderBy: orderBy?.call(Submission.t),
      orderByList: orderByList?.call(Submission.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Submission] by its [id] or null if no such row exists.
  Future<Submission?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Submission>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Submission]s in the list and returns the inserted rows.
  ///
  /// The returned [Submission]s will have their `id` fields set.
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
  Future<List<Submission>> insert(
    _is.DatabaseSession session,
    List<Submission> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Submission>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Submission] and returns the inserted row.
  ///
  /// The returned [Submission] will have its `id` field set.
  Future<Submission> insertRow(
    _is.DatabaseSession session,
    Submission row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Submission>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Submission]s in the list and returns the resulting rows.
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
  /// The returned [Submission]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Submission>> upsert(
    _is.DatabaseSession session,
    List<Submission> rows, {
    required _is.ColumnSelections<SubmissionTable> conflictColumns,
    _is.ColumnSelections<SubmissionTable>? updateColumns,
    _is.WhereExpressionBuilder<SubmissionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Submission>(
      rows,
      conflictColumns: conflictColumns(Submission.t),
      updateColumns: updateColumns?.call(Submission.t),
      updateWhere: updateWhere?.call(Submission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Submission] and returns the resulting row.
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
  /// The returned [Submission] will have its `id` field set.
  Future<Submission?> upsertRow(
    _is.DatabaseSession session,
    Submission row, {
    required _is.ColumnSelections<SubmissionTable> conflictColumns,
    _is.ColumnSelections<SubmissionTable>? updateColumns,
    _is.WhereExpressionBuilder<SubmissionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Submission>(
      row,
      conflictColumns: conflictColumns(Submission.t),
      updateColumns: updateColumns?.call(Submission.t),
      updateWhere: updateWhere?.call(Submission.t),
      transaction: transaction,
    );
  }

  /// Updates all [Submission]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Submission>> update(
    _is.DatabaseSession session,
    List<Submission> rows, {
    _is.ColumnSelections<SubmissionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Submission>(
      rows,
      columns: columns?.call(Submission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Submission]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Submission> updateRow(
    _is.DatabaseSession session,
    Submission row, {
    _is.ColumnSelections<SubmissionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Submission>(
      row,
      columns: columns?.call(Submission.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Submission] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Submission?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SubmissionUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Submission>(
      id,
      columnValues: columnValues(Submission.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Submission]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Submission>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SubmissionUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SubmissionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SubmissionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Submission>(
      columnValues: columnValues(Submission.t.updateTable),
      where: where(Submission.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Submission.t),
      orderByList: orderByList?.call(Submission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Submission]s in the list and returns the deleted rows.
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
  Future<List<Submission>> delete(
    _is.DatabaseSession session,
    List<Submission> rows, {
    _is.OrderByBuilder<SubmissionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Submission>(
      rows,
      orderBy: orderBy?.call(Submission.t),
      orderByList: orderByList?.call(Submission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Submission].
  Future<Submission> deleteRow(
    _is.DatabaseSession session,
    Submission row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Submission>(
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
  Future<List<Submission>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SubmissionTable> where,
    _is.OrderByBuilder<SubmissionTable>? orderBy,
    _is.OrderByListBuilder<SubmissionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Submission>(
      where: where(Submission.t),
      orderBy: orderBy?.call(Submission.t),
      orderByList: orderByList?.call(Submission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SubmissionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Submission>(
      where: where?.call(Submission.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Submission] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SubmissionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Submission>(
      where: where(Submission.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
