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
import '../../platform/files/image_profile.dart' as _ilodsldt;
import '../../platform/files/stored_file_kind.dart' as _iytry1n5;
import '../../platform/files/stored_file_status.dart' as _is8j7as8;

/// A file in cloud storage (specs/12 §1.1). The client chooses [fileUuid]
/// so content can reference `wonky-file://<fileUuid>` before upload.
abstract class StoredFile
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  StoredFile._({
    this.id,
    required this.fileUuid,
    this.ownerId,
    this.itemId,
    required this.kind,
    required this.storageId,
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    this.imageProfile,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
  });

  factory StoredFile({
    int? id,
    required _is.UuidValue fileUuid,
    int? ownerId,
    int? itemId,
    required _iytry1n5.StoredFileKind kind,
    required String storageId,
    required String path,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required _is8j7as8.StoredFileStatus status,
    _ilodsldt.ImageProfile? imageProfile,
    required DateTime createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) = _StoredFileImpl;

  factory StoredFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return StoredFile(
      id: jsonSerialization['id'] as int?,
      fileUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      ownerId: jsonSerialization['ownerId'] as int?,
      itemId: jsonSerialization['itemId'] as int?,
      kind: _iytry1n5.StoredFileKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      storageId: jsonSerialization['storageId'] as String,
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      status: _is8j7as8.StoredFileStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      imageProfile: jsonSerialization['imageProfile'] == null
          ? null
          : _ilodsldt.ImageProfile.fromJson(
              (jsonSerialization['imageProfile'] as String),
            ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
    );
  }

  static final t = StoredFileTable();

  static const db = StoredFileRepository._();

  @override
  int? id;

  _is.UuidValue fileUuid;

  int? ownerId;

  /// Access follows this item (null = owner only, e.g. avatars, imports).
  int? itemId;

  _iytry1n5.StoredFileKind kind;

  String storageId;

  String path;

  String fileName;

  String mimeType;

  int sizeBytes;

  _is8j7as8.StoredFileStatus status;

  /// (Images of documents, avatars, board screenshots) how the upload is
  /// re-encoded on completion (specs/12 §1.1); null for other kinds and
  /// older files.
  _ilodsldt.ImageProfile? imageProfile;

  DateTime createdAt;

  DateTime? completedAt;

  DateTime? expiresAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [StoredFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StoredFile copyWith({
    int? id,
    _is.UuidValue? fileUuid,
    int? ownerId,
    int? itemId,
    _iytry1n5.StoredFileKind? kind,
    String? storageId,
    String? path,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    _is8j7as8.StoredFileStatus? status,
    _ilodsldt.ImageProfile? imageProfile,
    DateTime? createdAt,
    DateTime? completedAt = const _is.$UndefinedDateTime(),
    DateTime? expiresAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StoredFile',
      if (id != null) 'id': id,
      'fileUuid': fileUuid.toJson(),
      if (ownerId != null) 'ownerId': ownerId,
      if (itemId != null) 'itemId': itemId,
      'kind': kind.toJson(),
      'storageId': storageId,
      'path': path,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'status': status.toJson(),
      if (imageProfile != null) 'imageProfile': imageProfile?.toJson(),
      'createdAt': createdAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StoredFile',
      if (id != null) 'id': id,
      'fileUuid': fileUuid.toJson(),
      if (ownerId != null) 'ownerId': ownerId,
      if (itemId != null) 'itemId': itemId,
      'kind': kind.toJson(),
      'storageId': storageId,
      'path': path,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'status': status.toJson(),
      if (imageProfile != null) 'imageProfile': imageProfile?.toJson(),
      'createdAt': createdAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  static StoredFileInclude include() {
    return StoredFileInclude._();
  }

  static StoredFileIncludeList includeList({
    _is.WhereExpressionBuilder<StoredFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoredFileTable>? orderBy,
    _is.OrderByListBuilder<StoredFileTable>? orderByList,
    StoredFileInclude? include,
  }) {
    return StoredFileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StoredFile.t),
      orderByList: orderByList?.call(StoredFile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StoredFileImpl extends StoredFile {
  _StoredFileImpl({
    int? id,
    required _is.UuidValue fileUuid,
    int? ownerId,
    int? itemId,
    required _iytry1n5.StoredFileKind kind,
    required String storageId,
    required String path,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required _is8j7as8.StoredFileStatus status,
    _ilodsldt.ImageProfile? imageProfile,
    required DateTime createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) : super._(
         id: id,
         fileUuid: fileUuid,
         ownerId: ownerId,
         itemId: itemId,
         kind: kind,
         storageId: storageId,
         path: path,
         fileName: fileName,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         status: status,
         imageProfile: imageProfile,
         createdAt: createdAt,
         completedAt: completedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [StoredFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StoredFile copyWith({
    Object? id = _Undefined,
    _is.UuidValue? fileUuid,
    Object? ownerId = _Undefined,
    Object? itemId = _Undefined,
    _iytry1n5.StoredFileKind? kind,
    String? storageId,
    String? path,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    _is8j7as8.StoredFileStatus? status,
    Object? imageProfile = _Undefined,
    DateTime? createdAt,
    DateTime? completedAt = const _is.$UndefinedDateTime(),
    DateTime? expiresAt = const _is.$UndefinedDateTime(),
  }) {
    return StoredFile(
      id: id is int? ? id : this.id,
      fileUuid: fileUuid ?? this.fileUuid,
      ownerId: ownerId is int? ? ownerId : this.ownerId,
      itemId: itemId is int? ? itemId : this.itemId,
      kind: kind ?? this.kind,
      storageId: storageId ?? this.storageId,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      imageProfile: imageProfile is _ilodsldt.ImageProfile?
          ? imageProfile
          : this.imageProfile,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt is _is.UndefinedSentinel
          ? this.completedAt
          : completedAt,
      expiresAt: expiresAt is _is.UndefinedSentinel
          ? this.expiresAt
          : expiresAt,
    );
  }
}

class StoredFileUpdateTable extends _is.UpdateTable<StoredFileTable> {
  StoredFileUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> fileUuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.fileUuid,
        value,
      );

  _is.ColumnValue<int, int> ownerId(int? value) => _is.ColumnValue(
    table.ownerId,
    value,
  );

  _is.ColumnValue<int, int> itemId(int? value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<_iytry1n5.StoredFileKind, _iytry1n5.StoredFileKind> kind(
    _iytry1n5.StoredFileKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> storageId(String value) => _is.ColumnValue(
    table.storageId,
    value,
  );

  _is.ColumnValue<String, String> path(String value) => _is.ColumnValue(
    table.path,
    value,
  );

  _is.ColumnValue<String, String> fileName(String value) => _is.ColumnValue(
    table.fileName,
    value,
  );

  _is.ColumnValue<String, String> mimeType(String value) => _is.ColumnValue(
    table.mimeType,
    value,
  );

  _is.ColumnValue<int, int> sizeBytes(int value) => _is.ColumnValue(
    table.sizeBytes,
    value,
  );

  _is.ColumnValue<_is8j7as8.StoredFileStatus, _is8j7as8.StoredFileStatus>
  status(_is8j7as8.StoredFileStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<_ilodsldt.ImageProfile, _ilodsldt.ImageProfile> imageProfile(
    _ilodsldt.ImageProfile? value,
  ) => _is.ColumnValue(
    table.imageProfile,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );
}

class StoredFileTable extends _is.Table<int?> {
  StoredFileTable({super.tableRelation}) : super(tableName: 'stored_file') {
    updateTable = StoredFileUpdateTable(this);
    fileUuid = _is.ColumnUuid(
      'fileUuid',
      this,
    );
    ownerId = _is.ColumnInt(
      'ownerId',
      this,
    );
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    storageId = _is.ColumnString(
      'storageId',
      this,
    );
    path = _is.ColumnString(
      'path',
      this,
    );
    fileName = _is.ColumnString(
      'fileName',
      this,
    );
    mimeType = _is.ColumnString(
      'mimeType',
      this,
    );
    sizeBytes = _is.ColumnInt(
      'sizeBytes',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    imageProfile = _is.ColumnEnum(
      'imageProfile',
      this,
      _is.EnumSerialization.byName,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
  }

  late final StoredFileUpdateTable updateTable;

  late final _is.ColumnUuid fileUuid;

  late final _is.ColumnInt ownerId;

  /// Access follows this item (null = owner only, e.g. avatars, imports).
  late final _is.ColumnInt itemId;

  late final _is.ColumnEnum<_iytry1n5.StoredFileKind> kind;

  late final _is.ColumnString storageId;

  late final _is.ColumnString path;

  late final _is.ColumnString fileName;

  late final _is.ColumnString mimeType;

  late final _is.ColumnInt sizeBytes;

  late final _is.ColumnEnum<_is8j7as8.StoredFileStatus> status;

  /// (Images of documents, avatars, board screenshots) how the upload is
  /// re-encoded on completion (specs/12 §1.1); null for other kinds and
  /// older files.
  late final _is.ColumnEnum<_ilodsldt.ImageProfile> imageProfile;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime completedAt;

  late final _is.ColumnDateTime expiresAt;

  @override
  List<_is.Column> get columns => [
    id,
    fileUuid,
    ownerId,
    itemId,
    kind,
    storageId,
    path,
    fileName,
    mimeType,
    sizeBytes,
    status,
    imageProfile,
    createdAt,
    completedAt,
    expiresAt,
  ];
}

class StoredFileInclude extends _is.IncludeObject {
  StoredFileInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => StoredFile.t;
}

class StoredFileIncludeList extends _is.IncludeList {
  StoredFileIncludeList._({
    _is.WhereExpressionBuilder<StoredFileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(StoredFile.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => StoredFile.t;
}

class StoredFileRepository {
  const StoredFileRepository._();

  /// Returns a list of [StoredFile]s matching the given query parameters.
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
  Future<List<StoredFile>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoredFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoredFileTable>? orderBy,
    _is.OrderByListBuilder<StoredFileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<StoredFile>(
      where: where?.call(StoredFile.t),
      orderBy: orderBy?.call(StoredFile.t),
      orderByList: orderByList?.call(StoredFile.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [StoredFile]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `StoredFile.t`.
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
  _ida.Stream<List<StoredFile>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoredFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoredFileTable>? orderBy,
    _is.OrderByListBuilder<StoredFileTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<StoredFile>(
      where: where?.call(StoredFile.t),
      orderBy: orderBy?.call(StoredFile.t),
      orderByList: orderByList?.call(StoredFile.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [StoredFile] matching the given query parameters.
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
  Future<StoredFile?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoredFileTable>? where,
    int? offset,
    _is.OrderByBuilder<StoredFileTable>? orderBy,
    _is.OrderByListBuilder<StoredFileTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<StoredFile>(
      where: where?.call(StoredFile.t),
      orderBy: orderBy?.call(StoredFile.t),
      orderByList: orderByList?.call(StoredFile.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [StoredFile] by its [id] or null if no such row exists.
  Future<StoredFile?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<StoredFile>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [StoredFile]s in the list and returns the inserted rows.
  ///
  /// The returned [StoredFile]s will have their `id` fields set.
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
  Future<List<StoredFile>> insert(
    _is.DatabaseSession session,
    List<StoredFile> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<StoredFile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [StoredFile] and returns the inserted row.
  ///
  /// The returned [StoredFile] will have its `id` field set.
  Future<StoredFile> insertRow(
    _is.DatabaseSession session,
    StoredFile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<StoredFile>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [StoredFile]s in the list and returns the resulting rows.
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
  /// The returned [StoredFile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredFile>> upsert(
    _is.DatabaseSession session,
    List<StoredFile> rows, {
    required _is.ColumnSelections<StoredFileTable> conflictColumns,
    _is.ColumnSelections<StoredFileTable>? updateColumns,
    _is.WhereExpressionBuilder<StoredFileTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<StoredFile>(
      rows,
      conflictColumns: conflictColumns(StoredFile.t),
      updateColumns: updateColumns?.call(StoredFile.t),
      updateWhere: updateWhere?.call(StoredFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [StoredFile] and returns the resulting row.
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
  /// The returned [StoredFile] will have its `id` field set.
  Future<StoredFile?> upsertRow(
    _is.DatabaseSession session,
    StoredFile row, {
    required _is.ColumnSelections<StoredFileTable> conflictColumns,
    _is.ColumnSelections<StoredFileTable>? updateColumns,
    _is.WhereExpressionBuilder<StoredFileTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<StoredFile>(
      row,
      conflictColumns: conflictColumns(StoredFile.t),
      updateColumns: updateColumns?.call(StoredFile.t),
      updateWhere: updateWhere?.call(StoredFile.t),
      transaction: transaction,
    );
  }

  /// Updates all [StoredFile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredFile>> update(
    _is.DatabaseSession session,
    List<StoredFile> rows, {
    _is.ColumnSelections<StoredFileTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<StoredFile>(
      rows,
      columns: columns?.call(StoredFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [StoredFile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<StoredFile> updateRow(
    _is.DatabaseSession session,
    StoredFile row, {
    _is.ColumnSelections<StoredFileTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<StoredFile>(
      row,
      columns: columns?.call(StoredFile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [StoredFile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<StoredFile?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<StoredFileUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<StoredFile>(
      id,
      columnValues: columnValues(StoredFile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [StoredFile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<StoredFile>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<StoredFileUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<StoredFileTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<StoredFileTable>? orderBy,
    _is.OrderByListBuilder<StoredFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<StoredFile>(
      columnValues: columnValues(StoredFile.t.updateTable),
      where: where(StoredFile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(StoredFile.t),
      orderByList: orderByList?.call(StoredFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [StoredFile]s in the list and returns the deleted rows.
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
  Future<List<StoredFile>> delete(
    _is.DatabaseSession session,
    List<StoredFile> rows, {
    _is.OrderByBuilder<StoredFileTable>? orderBy,
    _is.OrderByListBuilder<StoredFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<StoredFile>(
      rows,
      orderBy: orderBy?.call(StoredFile.t),
      orderByList: orderByList?.call(StoredFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [StoredFile].
  Future<StoredFile> deleteRow(
    _is.DatabaseSession session,
    StoredFile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<StoredFile>(
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
  Future<List<StoredFile>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StoredFileTable> where,
    _is.OrderByBuilder<StoredFileTable>? orderBy,
    _is.OrderByListBuilder<StoredFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<StoredFile>(
      where: where(StoredFile.t),
      orderBy: orderBy?.call(StoredFile.t),
      orderByList: orderByList?.call(StoredFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<StoredFileTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<StoredFile>(
      where: where?.call(StoredFile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [StoredFile] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<StoredFileTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<StoredFile>(
      where: where(StoredFile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
