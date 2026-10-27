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

/// A Wonky Write document (Write 02 §3). Content lives in the op log.
abstract class Document
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Document._({
    this.id,
    required this.uuid,
    required this.itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    this.themeId,
    String? pageSetupJson,
    this.language,
    this.frontMatter,
    String? markdownFlavor,
    int? charCount,
    int? wordCount,
    required this.createdAt,
    required this.updatedAt,
  }) : headRevision = headRevision ?? 0,
       latestSnapshotRevision = latestSnapshotRevision ?? 0,
       pageSetupJson = pageSetupJson ?? '{}',
       markdownFlavor = markdownFlavor ?? 'gfm',
       charCount = charCount ?? 0,
       wordCount = wordCount ?? 0;

  factory Document({
    int? id,
    required _is.UuidValue uuid,
    required int itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _is.UuidValue? themeId,
    String? pageSetupJson,
    String? language,
    String? frontMatter,
    String? markdownFlavor,
    int? charCount,
    int? wordCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DocumentImpl;

  factory Document.fromJson(Map<String, dynamic> jsonSerialization) {
    return Document(
      id: jsonSerialization['id'] as int?,
      uuid: _is.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      itemId: jsonSerialization['itemId'] as int,
      headRevision: jsonSerialization['headRevision'] as int?,
      latestSnapshotRevision:
          jsonSerialization['latestSnapshotRevision'] as int?,
      themeId: jsonSerialization['themeId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['themeId']),
      pageSetupJson: jsonSerialization['pageSetupJson'] as String?,
      language: jsonSerialization['language'] as String?,
      frontMatter: jsonSerialization['frontMatter'] as String?,
      markdownFlavor: jsonSerialization['markdownFlavor'] as String?,
      charCount: jsonSerialization['charCount'] as int?,
      wordCount: jsonSerialization['wordCount'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = DocumentTable();

  static const db = DocumentRepository._();

  @override
  int? id;

  /// Client may generate (UUIDv7) for offline creation.
  _is.UuidValue uuid;

  int itemId;

  int headRevision;

  int latestSnapshotRevision;

  /// WriteTheme.uuid; null = each viewer's default theme.
  _is.UuidValue? themeId;

  String pageSetupJson;

  String? language;

  String? frontMatter;

  /// `gfm` or `wonky` (Write 11 §3.1).
  String markdownFlavor;

  int charCount;

  int wordCount;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Document]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Document copyWith({
    int? id,
    _is.UuidValue? uuid,
    int? itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _is.UuidValue? themeId = const _is.$UndefinedUuidValue(),
    String? pageSetupJson,
    String? language,
    String? frontMatter,
    String? markdownFlavor,
    int? charCount,
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Document',
      if (id != null) 'id': id,
      'uuid': uuid.toJson(),
      'itemId': itemId,
      'headRevision': headRevision,
      'latestSnapshotRevision': latestSnapshotRevision,
      if (themeId != null) 'themeId': themeId?.toJson(),
      'pageSetupJson': pageSetupJson,
      if (language != null) 'language': language,
      if (frontMatter != null) 'frontMatter': frontMatter,
      'markdownFlavor': markdownFlavor,
      'charCount': charCount,
      'wordCount': wordCount,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Document',
      if (id != null) 'id': id,
      'uuid': uuid.toJson(),
      'itemId': itemId,
      'headRevision': headRevision,
      'latestSnapshotRevision': latestSnapshotRevision,
      if (themeId != null) 'themeId': themeId?.toJson(),
      'pageSetupJson': pageSetupJson,
      if (language != null) 'language': language,
      if (frontMatter != null) 'frontMatter': frontMatter,
      'markdownFlavor': markdownFlavor,
      'charCount': charCount,
      'wordCount': wordCount,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static DocumentInclude include() {
    return DocumentInclude._();
  }

  static DocumentIncludeList includeList({
    _is.WhereExpressionBuilder<DocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentTable>? orderBy,
    _is.OrderByListBuilder<DocumentTable>? orderByList,
    DocumentInclude? include,
  }) {
    return DocumentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Document.t),
      orderByList: orderByList?.call(Document.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentImpl extends Document {
  _DocumentImpl({
    int? id,
    required _is.UuidValue uuid,
    required int itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _is.UuidValue? themeId,
    String? pageSetupJson,
    String? language,
    String? frontMatter,
    String? markdownFlavor,
    int? charCount,
    int? wordCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         uuid: uuid,
         itemId: itemId,
         headRevision: headRevision,
         latestSnapshotRevision: latestSnapshotRevision,
         themeId: themeId,
         pageSetupJson: pageSetupJson,
         language: language,
         frontMatter: frontMatter,
         markdownFlavor: markdownFlavor,
         charCount: charCount,
         wordCount: wordCount,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Document]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Document copyWith({
    Object? id = _Undefined,
    _is.UuidValue? uuid,
    int? itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _is.UuidValue? themeId = const _is.$UndefinedUuidValue(),
    String? pageSetupJson,
    Object? language = _Undefined,
    Object? frontMatter = _Undefined,
    String? markdownFlavor,
    int? charCount,
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id is int? ? id : this.id,
      uuid: uuid ?? this.uuid,
      itemId: itemId ?? this.itemId,
      headRevision: headRevision ?? this.headRevision,
      latestSnapshotRevision:
          latestSnapshotRevision ?? this.latestSnapshotRevision,
      themeId: themeId is _is.UndefinedSentinel ? this.themeId : themeId,
      pageSetupJson: pageSetupJson ?? this.pageSetupJson,
      language: language is String? ? language : this.language,
      frontMatter: frontMatter is String? ? frontMatter : this.frontMatter,
      markdownFlavor: markdownFlavor ?? this.markdownFlavor,
      charCount: charCount ?? this.charCount,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DocumentUpdateTable extends _is.UpdateTable<DocumentTable> {
  DocumentUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> uuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.uuid,
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

  _is.ColumnValue<int, int> latestSnapshotRevision(int value) =>
      _is.ColumnValue(
        table.latestSnapshotRevision,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> themeId(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.themeId,
        value,
      );

  _is.ColumnValue<String, String> pageSetupJson(String value) =>
      _is.ColumnValue(
        table.pageSetupJson,
        value,
      );

  _is.ColumnValue<String, String> language(String? value) => _is.ColumnValue(
    table.language,
    value,
  );

  _is.ColumnValue<String, String> frontMatter(String? value) => _is.ColumnValue(
    table.frontMatter,
    value,
  );

  _is.ColumnValue<String, String> markdownFlavor(String value) =>
      _is.ColumnValue(
        table.markdownFlavor,
        value,
      );

  _is.ColumnValue<int, int> charCount(int value) => _is.ColumnValue(
    table.charCount,
    value,
  );

  _is.ColumnValue<int, int> wordCount(int value) => _is.ColumnValue(
    table.wordCount,
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

class DocumentTable extends _is.Table<int?> {
  DocumentTable({super.tableRelation}) : super(tableName: 'document') {
    updateTable = DocumentUpdateTable(this);
    uuid = _is.ColumnUuid(
      'uuid',
      this,
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
    latestSnapshotRevision = _is.ColumnInt(
      'latestSnapshotRevision',
      this,
      hasDefault: true,
    );
    themeId = _is.ColumnUuid(
      'themeId',
      this,
    );
    pageSetupJson = _is.ColumnString(
      'pageSetupJson',
      this,
      hasDefault: true,
    );
    language = _is.ColumnString(
      'language',
      this,
    );
    frontMatter = _is.ColumnString(
      'frontMatter',
      this,
    );
    markdownFlavor = _is.ColumnString(
      'markdownFlavor',
      this,
      hasDefault: true,
    );
    charCount = _is.ColumnInt(
      'charCount',
      this,
      hasDefault: true,
    );
    wordCount = _is.ColumnInt(
      'wordCount',
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

  late final DocumentUpdateTable updateTable;

  /// Client may generate (UUIDv7) for offline creation.
  late final _is.ColumnUuid uuid;

  late final _is.ColumnInt itemId;

  late final _is.ColumnInt headRevision;

  late final _is.ColumnInt latestSnapshotRevision;

  /// WriteTheme.uuid; null = each viewer's default theme.
  late final _is.ColumnUuid themeId;

  late final _is.ColumnString pageSetupJson;

  late final _is.ColumnString language;

  late final _is.ColumnString frontMatter;

  /// `gfm` or `wonky` (Write 11 §3.1).
  late final _is.ColumnString markdownFlavor;

  late final _is.ColumnInt charCount;

  late final _is.ColumnInt wordCount;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    uuid,
    itemId,
    headRevision,
    latestSnapshotRevision,
    themeId,
    pageSetupJson,
    language,
    frontMatter,
    markdownFlavor,
    charCount,
    wordCount,
    createdAt,
    updatedAt,
  ];
}

class DocumentInclude extends _is.IncludeObject {
  DocumentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Document.t;
}

class DocumentIncludeList extends _is.IncludeList {
  DocumentIncludeList._({
    _is.WhereExpressionBuilder<DocumentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Document.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Document.t;
}

class DocumentRepository {
  const DocumentRepository._();

  /// Returns a list of [Document]s matching the given query parameters.
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
  Future<List<Document>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentTable>? orderBy,
    _is.OrderByListBuilder<DocumentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Document>(
      where: where?.call(Document.t),
      orderBy: orderBy?.call(Document.t),
      orderByList: orderByList?.call(Document.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Document]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Document.t`.
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
  _ida.Stream<List<Document>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentTable>? orderBy,
    _is.OrderByListBuilder<DocumentTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Document>(
      where: where?.call(Document.t),
      orderBy: orderBy?.call(Document.t),
      orderByList: orderByList?.call(Document.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Document] matching the given query parameters.
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
  Future<Document?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentTable>? where,
    int? offset,
    _is.OrderByBuilder<DocumentTable>? orderBy,
    _is.OrderByListBuilder<DocumentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Document>(
      where: where?.call(Document.t),
      orderBy: orderBy?.call(Document.t),
      orderByList: orderByList?.call(Document.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Document] by its [id] or null if no such row exists.
  Future<Document?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Document>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Document]s in the list and returns the inserted rows.
  ///
  /// The returned [Document]s will have their `id` fields set.
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
  Future<List<Document>> insert(
    _is.DatabaseSession session,
    List<Document> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Document>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Document] and returns the inserted row.
  ///
  /// The returned [Document] will have its `id` field set.
  Future<Document> insertRow(
    _is.DatabaseSession session,
    Document row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Document>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Document]s in the list and returns the resulting rows.
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
  /// The returned [Document]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Document>> upsert(
    _is.DatabaseSession session,
    List<Document> rows, {
    required _is.ColumnSelections<DocumentTable> conflictColumns,
    _is.ColumnSelections<DocumentTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Document>(
      rows,
      conflictColumns: conflictColumns(Document.t),
      updateColumns: updateColumns?.call(Document.t),
      updateWhere: updateWhere?.call(Document.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Document] and returns the resulting row.
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
  /// The returned [Document] will have its `id` field set.
  Future<Document?> upsertRow(
    _is.DatabaseSession session,
    Document row, {
    required _is.ColumnSelections<DocumentTable> conflictColumns,
    _is.ColumnSelections<DocumentTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Document>(
      row,
      conflictColumns: conflictColumns(Document.t),
      updateColumns: updateColumns?.call(Document.t),
      updateWhere: updateWhere?.call(Document.t),
      transaction: transaction,
    );
  }

  /// Updates all [Document]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Document>> update(
    _is.DatabaseSession session,
    List<Document> rows, {
    _is.ColumnSelections<DocumentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Document>(
      rows,
      columns: columns?.call(Document.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Document]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Document> updateRow(
    _is.DatabaseSession session,
    Document row, {
    _is.ColumnSelections<DocumentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Document>(
      row,
      columns: columns?.call(Document.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Document] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Document?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DocumentUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Document>(
      id,
      columnValues: columnValues(Document.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Document]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Document>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DocumentUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DocumentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentTable>? orderBy,
    _is.OrderByListBuilder<DocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Document>(
      columnValues: columnValues(Document.t.updateTable),
      where: where(Document.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Document.t),
      orderByList: orderByList?.call(Document.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Document]s in the list and returns the deleted rows.
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
  Future<List<Document>> delete(
    _is.DatabaseSession session,
    List<Document> rows, {
    _is.OrderByBuilder<DocumentTable>? orderBy,
    _is.OrderByListBuilder<DocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Document>(
      rows,
      orderBy: orderBy?.call(Document.t),
      orderByList: orderByList?.call(Document.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Document].
  Future<Document> deleteRow(
    _is.DatabaseSession session,
    Document row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Document>(
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
  Future<List<Document>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentTable> where,
    _is.OrderByBuilder<DocumentTable>? orderBy,
    _is.OrderByListBuilder<DocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Document>(
      where: where(Document.t),
      orderBy: orderBy?.call(Document.t),
      orderByList: orderByList?.call(Document.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Document>(
      where: where?.call(Document.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Document] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Document>(
      where: where(Document.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
