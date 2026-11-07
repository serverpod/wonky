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

/// A user's own style guide for the assistant (suite 10 §7), kept personal
/// or shared with the owner's organization. Built-in guides are code
/// constants (`BuiltinStyleGuides`), not rows.
abstract class StyleGuide
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  StyleGuide._({
    this.id,
    _is.UuidValue? uuid,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.markdown,
    this.orgKey,
    required this.createdAt,
    required this.updatedAt,
  }) : uuid = uuid ?? const _is.Uuid().v7obj();

  factory StyleGuide({
    int? id,
    _is.UuidValue? uuid,
    required int ownerId,
    required String name,
    required String description,
    required String markdown,
    String? orgKey,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StyleGuideImpl;

  factory StyleGuide.fromJson(Map<String, dynamic> jsonSerialization) {
    return StyleGuide(
      id: jsonSerialization['id'] as int?,
      uuid: jsonSerialization['uuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      ownerId: jsonSerialization['ownerId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      markdown: jsonSerialization['markdown'] as String,
      orgKey: jsonSerialization['orgKey'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = StyleGuideTable();

  static const db = StyleGuideRepository._();

  @override
  int? id;

  _is.UuidValue uuid;

  int ownerId;

  String name;

  String description;

  /// The guide itself (Markdown).
  String markdown;

  /// The organization it is shared with (its key, e.g. `serverpod.dev`);
  /// null = personal.
  String? orgKey;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [StyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StyleGuide copyWith({
    int? id,
    _is.UuidValue? uuid,
    int? ownerId,
    String? name,
    String? description,
    String? markdown,
    String? orgKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StyleGuide',
      if (id != null) 'id': id,
      'uuid': uuid.toJson(),
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'markdown': markdown,
      if (orgKey != null) 'orgKey': orgKey,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StyleGuide',
      if (id != null) 'id': id,
      'uuid': uuid.toJson(),
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'markdown': markdown,
      if (orgKey != null) 'orgKey': orgKey,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static StyleGuideInclude include() {
    return StyleGuideInclude._();
  }

  static StyleGuideIncludeList includeList({
    _is.WhereExpressionBuilder<StyleGuideTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StyleGuideTable>? orderBy,
    _is.OrderByListBuilder<StyleGuideTable>? orderByList,
    StyleGuideInclude? include,
  }) {
    return StyleGuideIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StyleGuide.t),
      orderByList: orderByList?.call(StyleGuide.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StyleGuideImpl extends StyleGuide {
  _StyleGuideImpl({
    int? id,
    _is.UuidValue? uuid,
    required int ownerId,
    required String name,
    required String description,
    required String markdown,
    String? orgKey,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         uuid: uuid,
         ownerId: ownerId,
         name: name,
         description: description,
         markdown: markdown,
         orgKey: orgKey,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [StyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StyleGuide copyWith({
    Object? id = _Undefined,
    _is.UuidValue? uuid,
    int? ownerId,
    String? name,
    String? description,
    String? markdown,
    Object? orgKey = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StyleGuide(
      id: id is int? ? id : this.id,
      uuid: uuid ?? this.uuid,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      markdown: markdown ?? this.markdown,
      orgKey: orgKey is String? ? orgKey : this.orgKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StyleGuideUpdateTable extends _is.UpdateTable<StyleGuideTable> {
  StyleGuideUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> uuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.uuid,
        value,
      );

  _is.ColumnValue<int, int> ownerId(int value) => _is.ColumnValue(
    table.ownerId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> description(String value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<String, String> markdown(String value) => _is.ColumnValue(
    table.markdown,
    value,
  );

  _is.ColumnValue<String, String> orgKey(String? value) => _is.ColumnValue(
    table.orgKey,
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

class StyleGuideTable extends _is.Table<int?> {
  StyleGuideTable({super.tableRelation}) : super(tableName: 'style_guide') {
    updateTable = StyleGuideUpdateTable(this);
    uuid = _is.ColumnUuid(
      'uuid',
      this,
    );
    ownerId = _is.ColumnInt(
      'ownerId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
    );
    markdown = _is.ColumnString(
      'markdown',
      this,
    );
    orgKey = _is.ColumnString(
      'orgKey',
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
  }

  late final StyleGuideUpdateTable updateTable;

  late final _is.ColumnUuid uuid;

  late final _is.ColumnInt ownerId;

  late final _is.ColumnString name;

  late final _is.ColumnString description;

  /// The guide itself (Markdown).
  late final _is.ColumnString markdown;

  /// The organization it is shared with (its key, e.g. `serverpod.dev`);
  /// null = personal.
  late final _is.ColumnString orgKey;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    uuid,
    ownerId,
    name,
    description,
    markdown,
    orgKey,
    createdAt,
    updatedAt,
  ];
}

class StyleGuideInclude extends _is.IncludeObject {
  StyleGuideInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => StyleGuide.t;
}

class StyleGuideIncludeList extends _is.IncludeList {
  StyleGuideIncludeList._({
    _is.WhereExpressionBuilder<StyleGuideTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(StyleGuide.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => StyleGuide.t;
}

class StyleGuideRepository {
  const StyleGuideRepository._();

  /// Returns a list of [StyleGuide]s matching the given query parameters.
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
  Future<List<StyleGuide>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StyleGuideTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StyleGuideTable>? orderBy,
    _is.OrderByListBuilder<StyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<StyleGuide>(
      where: where?.call(StyleGuide.t),
      orderBy: orderBy?.call(StyleGuide.t),
      orderByList: orderByList?.call(StyleGuide.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [StyleGuide]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `StyleGuide.t`.
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
  _ida.Stream<List<StyleGuide>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StyleGuideTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StyleGuideTable>? orderBy,
    _is.OrderByListBuilder<StyleGuideTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<StyleGuide>(
      where: where?.call(StyleGuide.t),
      orderBy: orderBy?.call(StyleGuide.t),
      orderByList: orderByList?.call(StyleGuide.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [StyleGuide] matching the given query parameters.
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
  Future<StyleGuide?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StyleGuideTable>? where,
    int? offset,
    _is.OrderByBuilder<StyleGuideTable>? orderBy,
    _is.OrderByListBuilder<StyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<StyleGuide>(
      where: where?.call(StyleGuide.t),
      orderBy: orderBy?.call(StyleGuide.t),
      orderByList: orderByList?.call(StyleGuide.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [StyleGuide] by its [id] or null if no such row exists.
  Future<StyleGuide?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<StyleGuide>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [StyleGuide]s in the list and returns the inserted rows.
  ///
  /// The returned [StyleGuide]s will have their `id` fields set.
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
  Future<List<StyleGuide>> insert(
    _is.DatabaseSession session,
    List<StyleGuide> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<StyleGuide>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [StyleGuide] and returns the inserted row.
  ///
  /// The returned [StyleGuide] will have its `id` field set.
  Future<StyleGuide> insertRow(
    _is.DatabaseSession session,
    StyleGuide row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<StyleGuide>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [StyleGuide]s in the list and returns the resulting rows.
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
  /// The returned [StyleGuide]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StyleGuide>> upsert(
    _is.DatabaseSession session,
    List<StyleGuide> rows, {
    required _is.ColumnSelections<StyleGuideTable> conflictColumns,
    _is.ColumnSelections<StyleGuideTable>? updateColumns,
    _is.WhereExpressionBuilder<StyleGuideTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<StyleGuide>(
      rows,
      conflictColumns: conflictColumns(StyleGuide.t),
      updateColumns: updateColumns?.call(StyleGuide.t),
      updateWhere: updateWhere?.call(StyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [StyleGuide] and returns the resulting row.
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
  /// The returned [StyleGuide] will have its `id` field set.
  Future<StyleGuide?> upsertRow(
    _is.DatabaseSession session,
    StyleGuide row, {
    required _is.ColumnSelections<StyleGuideTable> conflictColumns,
    _is.ColumnSelections<StyleGuideTable>? updateColumns,
    _is.WhereExpressionBuilder<StyleGuideTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<StyleGuide>(
      row,
      conflictColumns: conflictColumns(StyleGuide.t),
      updateColumns: updateColumns?.call(StyleGuide.t),
      updateWhere: updateWhere?.call(StyleGuide.t),
      transaction: transaction,
    );
  }

  /// Updates all [StyleGuide]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StyleGuide>> update(
    _is.DatabaseSession session,
    List<StyleGuide> rows, {
    _is.ColumnSelections<StyleGuideTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<StyleGuide>(
      rows,
      columns: columns?.call(StyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [StyleGuide]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<StyleGuide> updateRow(
    _is.DatabaseSession session,
    StyleGuide row, {
    _is.ColumnSelections<StyleGuideTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<StyleGuide>(
      row,
      columns: columns?.call(StyleGuide.t),
      transaction: transaction,
    );
  }

  /// Updates a single [StyleGuide] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<StyleGuide?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<StyleGuideUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<StyleGuide>(
      id,
      columnValues: columnValues(StyleGuide.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [StyleGuide]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StyleGuide>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<StyleGuideUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<StyleGuideTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StyleGuideTable>? orderBy,
    _is.OrderByListBuilder<StyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<StyleGuide>(
      columnValues: columnValues(StyleGuide.t.updateTable),
      where: where(StyleGuide.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StyleGuide.t),
      orderByList: orderByList?.call(StyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [StyleGuide]s in the list and returns the deleted rows.
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
  Future<List<StyleGuide>> delete(
    _is.DatabaseSession session,
    List<StyleGuide> rows, {
    _is.OrderByBuilder<StyleGuideTable>? orderBy,
    _is.OrderByListBuilder<StyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<StyleGuide>(
      rows,
      orderBy: orderBy?.call(StyleGuide.t),
      orderByList: orderByList?.call(StyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [StyleGuide].
  Future<StyleGuide> deleteRow(
    _is.DatabaseSession session,
    StyleGuide row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<StyleGuide>(
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
  Future<List<StyleGuide>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StyleGuideTable> where,
    _is.OrderByBuilder<StyleGuideTable>? orderBy,
    _is.OrderByListBuilder<StyleGuideTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<StyleGuide>(
      where: where(StyleGuide.t),
      orderBy: orderBy?.call(StyleGuide.t),
      orderByList: orderByList?.call(StyleGuide.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StyleGuideTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<StyleGuide>(
      where: where?.call(StyleGuide.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [StyleGuide] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StyleGuideTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<StyleGuide>(
      where: where(StyleGuide.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
