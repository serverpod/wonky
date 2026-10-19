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
import 'dart:typed_data' as _idt;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/common/actor_kind.dart' as _iqucl2d4;
import '../../../platform/revlog/models/rev_file.dart' as _imcki4bb;

/// One committed op of a RevLog file (RevLog spec 02 §1).
abstract class RevOp implements _is.TableRow<int?>, _is.ProtocolSerialization {
  RevOp._({
    this.id,
    required this.fileId,
    this.file,
    required this.revision,
    required this.clientOpId,
    required this.baseRevision,
    this.authorId,
    this.authorUuid,
    this.sessionId,
    this.onBehalfOfSessionId,
    required this.actorKind,
    required this.label,
    this.groupId,
    int? groupIndex,
    bool? groupLast,
    this.recordId,
    bool? offline,
    this.payload,
    required this.changeCount,
    this.summaryJson,
    this.detailJson,
    this.outcomeJson,
    required this.appliedEqualsSubmitted,
    this.clientCreatedAt,
    required this.committedAt,
  }) : groupIndex = groupIndex ?? 0,
       groupLast = groupLast ?? true,
       offline = offline ?? false;

  factory RevOp({
    int? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    required int revision,
    required _is.UuidValue clientOpId,
    required int baseRevision,
    int? authorId,
    _is.UuidValue? authorUuid,
    String? sessionId,
    String? onBehalfOfSessionId,
    required _iqucl2d4.ActorKind actorKind,
    required String label,
    String? groupId,
    int? groupIndex,
    bool? groupLast,
    _is.UuidValue? recordId,
    bool? offline,
    _idt.ByteData? payload,
    required int changeCount,
    String? summaryJson,
    String? detailJson,
    String? outcomeJson,
    required bool appliedEqualsSubmitted,
    DateTime? clientCreatedAt,
    required DateTime committedAt,
  }) = _RevOpImpl;

  factory RevOp.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevOp(
      id: jsonSerialization['id'] as int?,
      fileId: jsonSerialization['fileId'] as int,
      file: jsonSerialization['file'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_imcki4bb.RevFile>(
              jsonSerialization['file'],
            ),
      revision: jsonSerialization['revision'] as int,
      clientOpId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientOpId'],
      ),
      baseRevision: jsonSerialization['baseRevision'] as int,
      authorId: jsonSerialization['authorId'] as int?,
      authorUuid: jsonSerialization['authorUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['authorUuid'],
            ),
      sessionId: jsonSerialization['sessionId'] as String?,
      onBehalfOfSessionId: jsonSerialization['onBehalfOfSessionId'] as String?,
      actorKind: _iqucl2d4.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      label: jsonSerialization['label'] as String,
      groupId: jsonSerialization['groupId'] as String?,
      groupIndex: jsonSerialization['groupIndex'] as int?,
      groupLast: jsonSerialization['groupLast'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['groupLast']),
      recordId: jsonSerialization['recordId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['recordId']),
      offline: jsonSerialization['offline'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['offline']),
      payload: jsonSerialization['payload'] == null
          ? null
          : _is.ByteDataJsonExtension.fromJson(jsonSerialization['payload']),
      changeCount: jsonSerialization['changeCount'] as int,
      summaryJson: jsonSerialization['summaryJson'] as String?,
      detailJson: jsonSerialization['detailJson'] as String?,
      outcomeJson: jsonSerialization['outcomeJson'] as String?,
      appliedEqualsSubmitted: _is.BoolJsonExtension.fromJson(
        jsonSerialization['appliedEqualsSubmitted'],
      ),
      clientCreatedAt: jsonSerialization['clientCreatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['clientCreatedAt'],
            ),
      committedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['committedAt'],
      ),
    );
  }

  static final t = RevOpTable();

  static const db = RevOpRepository._();

  @override
  int? id;

  int fileId;

  _imcki4bb.RevFile? file;

  int revision;

  _is.UuidValue clientOpId;

  int baseRevision;

  /// user_profile id (null for system changes).
  int? authorId;

  /// Auth user uuid (sent to clients).
  _is.UuidValue? authorUuid;

  /// The committing connection's session id, or "server:<runId>".
  String? sessionId;

  String? onBehalfOfSessionId;

  _iqucl2d4.ActorKind actorKind;

  String label;

  /// Chunk group of one plan (RD-21).
  String? groupId;

  int groupIndex;

  bool groupLast;

  /// ServerChangeRecord / assistant run (RD-21).
  _is.UuidValue? recordId;

  bool offline;

  /// gzip of the codec JSON of the applied changes, with before (RD-20);
  /// null once pruned.
  _idt.ByteData? payload;

  int changeCount;

  String? summaryJson;

  String? detailJson;

  /// Full outcome (04 §2.2) for idempotent re-acks; null once pruned.
  String? outcomeJson;

  /// The applied form is exactly the submitted changes.
  bool appliedEqualsSubmitted;

  DateTime? clientCreatedAt;

  DateTime committedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [RevOp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevOp copyWith({
    int? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedRevOp$file(),
    int? revision,
    _is.UuidValue? clientOpId,
    int? baseRevision,
    int? authorId,
    _is.UuidValue? authorUuid = const _is.$UndefinedUuidValue(),
    String? sessionId,
    String? onBehalfOfSessionId,
    _iqucl2d4.ActorKind? actorKind,
    String? label,
    String? groupId,
    int? groupIndex,
    bool? groupLast,
    _is.UuidValue? recordId = const _is.$UndefinedUuidValue(),
    bool? offline,
    _idt.ByteData? payload,
    int? changeCount,
    String? summaryJson,
    String? detailJson,
    String? outcomeJson,
    bool? appliedEqualsSubmitted,
    DateTime? clientCreatedAt = const _is.$UndefinedDateTime(),
    DateTime? committedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevOp',
      if (id != null) 'id': id,
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'clientOpId': clientOpId.toJson(),
      'baseRevision': baseRevision,
      if (authorId != null) 'authorId': authorId,
      if (authorUuid != null) 'authorUuid': authorUuid?.toJson(),
      if (sessionId != null) 'sessionId': sessionId,
      if (onBehalfOfSessionId != null)
        'onBehalfOfSessionId': onBehalfOfSessionId,
      'actorKind': actorKind.toJson(),
      'label': label,
      if (groupId != null) 'groupId': groupId,
      'groupIndex': groupIndex,
      'groupLast': groupLast,
      if (recordId != null) 'recordId': recordId?.toJson(),
      'offline': offline,
      if (payload != null) 'payload': payload?.toJson(),
      'changeCount': changeCount,
      if (summaryJson != null) 'summaryJson': summaryJson,
      if (detailJson != null) 'detailJson': detailJson,
      if (outcomeJson != null) 'outcomeJson': outcomeJson,
      'appliedEqualsSubmitted': appliedEqualsSubmitted,
      if (clientCreatedAt != null) 'clientCreatedAt': clientCreatedAt?.toJson(),
      'committedAt': committedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static RevOpInclude include({_imcki4bb.RevFileInclude? file}) {
    return RevOpInclude._(file: file);
  }

  static RevOpIncludeList includeList({
    _is.WhereExpressionBuilder<RevOpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevOpTable>? orderBy,
    _is.OrderByListBuilder<RevOpTable>? orderByList,
    RevOpInclude? include,
  }) {
    return RevOpIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RevOp.t),
      orderByList: orderByList?.call(RevOp.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedRevOp$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedRevOp$file();
}

class _RevOpImpl extends RevOp {
  _RevOpImpl({
    int? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    required int revision,
    required _is.UuidValue clientOpId,
    required int baseRevision,
    int? authorId,
    _is.UuidValue? authorUuid,
    String? sessionId,
    String? onBehalfOfSessionId,
    required _iqucl2d4.ActorKind actorKind,
    required String label,
    String? groupId,
    int? groupIndex,
    bool? groupLast,
    _is.UuidValue? recordId,
    bool? offline,
    _idt.ByteData? payload,
    required int changeCount,
    String? summaryJson,
    String? detailJson,
    String? outcomeJson,
    required bool appliedEqualsSubmitted,
    DateTime? clientCreatedAt,
    required DateTime committedAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         clientOpId: clientOpId,
         baseRevision: baseRevision,
         authorId: authorId,
         authorUuid: authorUuid,
         sessionId: sessionId,
         onBehalfOfSessionId: onBehalfOfSessionId,
         actorKind: actorKind,
         label: label,
         groupId: groupId,
         groupIndex: groupIndex,
         groupLast: groupLast,
         recordId: recordId,
         offline: offline,
         payload: payload,
         changeCount: changeCount,
         summaryJson: summaryJson,
         detailJson: detailJson,
         outcomeJson: outcomeJson,
         appliedEqualsSubmitted: appliedEqualsSubmitted,
         clientCreatedAt: clientCreatedAt,
         committedAt: committedAt,
       );

  /// Returns a shallow copy of this [RevOp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevOp copyWith({
    Object? id = _Undefined,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedRevOp$file(),
    int? revision,
    _is.UuidValue? clientOpId,
    int? baseRevision,
    Object? authorId = _Undefined,
    _is.UuidValue? authorUuid = const _is.$UndefinedUuidValue(),
    Object? sessionId = _Undefined,
    Object? onBehalfOfSessionId = _Undefined,
    _iqucl2d4.ActorKind? actorKind,
    String? label,
    Object? groupId = _Undefined,
    int? groupIndex,
    bool? groupLast,
    _is.UuidValue? recordId = const _is.$UndefinedUuidValue(),
    bool? offline,
    Object? payload = _Undefined,
    int? changeCount,
    Object? summaryJson = _Undefined,
    Object? detailJson = _Undefined,
    Object? outcomeJson = _Undefined,
    bool? appliedEqualsSubmitted,
    DateTime? clientCreatedAt = const _is.$UndefinedDateTime(),
    DateTime? committedAt,
  }) {
    return RevOp(
      id: id is int? ? id : this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      clientOpId: clientOpId ?? this.clientOpId,
      baseRevision: baseRevision ?? this.baseRevision,
      authorId: authorId is int? ? authorId : this.authorId,
      authorUuid: authorUuid is _is.UndefinedSentinel
          ? this.authorUuid
          : authorUuid,
      sessionId: sessionId is String? ? sessionId : this.sessionId,
      onBehalfOfSessionId: onBehalfOfSessionId is String?
          ? onBehalfOfSessionId
          : this.onBehalfOfSessionId,
      actorKind: actorKind ?? this.actorKind,
      label: label ?? this.label,
      groupId: groupId is String? ? groupId : this.groupId,
      groupIndex: groupIndex ?? this.groupIndex,
      groupLast: groupLast ?? this.groupLast,
      recordId: recordId is _is.UndefinedSentinel ? this.recordId : recordId,
      offline: offline ?? this.offline,
      payload: payload is _idt.ByteData? ? payload : this.payload?.clone(),
      changeCount: changeCount ?? this.changeCount,
      summaryJson: summaryJson is String? ? summaryJson : this.summaryJson,
      detailJson: detailJson is String? ? detailJson : this.detailJson,
      outcomeJson: outcomeJson is String? ? outcomeJson : this.outcomeJson,
      appliedEqualsSubmitted:
          appliedEqualsSubmitted ?? this.appliedEqualsSubmitted,
      clientCreatedAt: clientCreatedAt is _is.UndefinedSentinel
          ? this.clientCreatedAt
          : clientCreatedAt,
      committedAt: committedAt ?? this.committedAt,
    );
  }
}

class RevOpUpdateTable extends _is.UpdateTable<RevOpTable> {
  RevOpUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> clientOpId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.clientOpId,
    value,
  );

  _is.ColumnValue<int, int> baseRevision(int value) => _is.ColumnValue(
    table.baseRevision,
    value,
  );

  _is.ColumnValue<int, int> authorId(int? value) => _is.ColumnValue(
    table.authorId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authorUuid(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.authorUuid,
    value,
  );

  _is.ColumnValue<String, String> sessionId(String? value) => _is.ColumnValue(
    table.sessionId,
    value,
  );

  _is.ColumnValue<String, String> onBehalfOfSessionId(String? value) =>
      _is.ColumnValue(
        table.onBehalfOfSessionId,
        value,
      );

  _is.ColumnValue<_iqucl2d4.ActorKind, _iqucl2d4.ActorKind> actorKind(
    _iqucl2d4.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<String, String> groupId(String? value) => _is.ColumnValue(
    table.groupId,
    value,
  );

  _is.ColumnValue<int, int> groupIndex(int value) => _is.ColumnValue(
    table.groupIndex,
    value,
  );

  _is.ColumnValue<bool, bool> groupLast(bool value) => _is.ColumnValue(
    table.groupLast,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> recordId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.recordId,
    value,
  );

  _is.ColumnValue<bool, bool> offline(bool value) => _is.ColumnValue(
    table.offline,
    value,
  );

  _is.ColumnValue<_idt.ByteData, _idt.ByteData> payload(_idt.ByteData? value) =>
      _is.ColumnValue(
        table.payload,
        value,
      );

  _is.ColumnValue<int, int> changeCount(int value) => _is.ColumnValue(
    table.changeCount,
    value,
  );

  _is.ColumnValue<String, String> summaryJson(String? value) => _is.ColumnValue(
    table.summaryJson,
    value,
  );

  _is.ColumnValue<String, String> detailJson(String? value) => _is.ColumnValue(
    table.detailJson,
    value,
  );

  _is.ColumnValue<String, String> outcomeJson(String? value) => _is.ColumnValue(
    table.outcomeJson,
    value,
  );

  _is.ColumnValue<bool, bool> appliedEqualsSubmitted(bool value) =>
      _is.ColumnValue(
        table.appliedEqualsSubmitted,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> clientCreatedAt(DateTime? value) =>
      _is.ColumnValue(
        table.clientCreatedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> committedAt(DateTime value) =>
      _is.ColumnValue(
        table.committedAt,
        value,
      );
}

class RevOpTable extends _is.Table<int?> {
  RevOpTable({super.tableRelation}) : super(tableName: 'rev_op') {
    updateTable = RevOpUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    clientOpId = _is.ColumnUuid(
      'clientOpId',
      this,
    );
    baseRevision = _is.ColumnInt(
      'baseRevision',
      this,
    );
    authorId = _is.ColumnInt(
      'authorId',
      this,
    );
    authorUuid = _is.ColumnUuid(
      'authorUuid',
      this,
    );
    sessionId = _is.ColumnString(
      'sessionId',
      this,
    );
    onBehalfOfSessionId = _is.ColumnString(
      'onBehalfOfSessionId',
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
    groupId = _is.ColumnString(
      'groupId',
      this,
    );
    groupIndex = _is.ColumnInt(
      'groupIndex',
      this,
      hasDefault: true,
    );
    groupLast = _is.ColumnBool(
      'groupLast',
      this,
      hasDefault: true,
    );
    recordId = _is.ColumnUuid(
      'recordId',
      this,
    );
    offline = _is.ColumnBool(
      'offline',
      this,
      hasDefault: true,
    );
    payload = _is.ColumnByteData(
      'payload',
      this,
    );
    changeCount = _is.ColumnInt(
      'changeCount',
      this,
    );
    summaryJson = _is.ColumnString(
      'summaryJson',
      this,
    );
    detailJson = _is.ColumnString(
      'detailJson',
      this,
    );
    outcomeJson = _is.ColumnString(
      'outcomeJson',
      this,
    );
    appliedEqualsSubmitted = _is.ColumnBool(
      'appliedEqualsSubmitted',
      this,
    );
    clientCreatedAt = _is.ColumnDateTime(
      'clientCreatedAt',
      this,
    );
    committedAt = _is.ColumnDateTime(
      'committedAt',
      this,
    );
  }

  late final RevOpUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  _imcki4bb.RevFileTable? _file;

  late final _is.ColumnInt revision;

  late final _is.ColumnUuid clientOpId;

  late final _is.ColumnInt baseRevision;

  /// user_profile id (null for system changes).
  late final _is.ColumnInt authorId;

  /// Auth user uuid (sent to clients).
  late final _is.ColumnUuid authorUuid;

  /// The committing connection's session id, or "server:<runId>".
  late final _is.ColumnString sessionId;

  late final _is.ColumnString onBehalfOfSessionId;

  late final _is.ColumnEnum<_iqucl2d4.ActorKind> actorKind;

  late final _is.ColumnString label;

  /// Chunk group of one plan (RD-21).
  late final _is.ColumnString groupId;

  late final _is.ColumnInt groupIndex;

  late final _is.ColumnBool groupLast;

  /// ServerChangeRecord / assistant run (RD-21).
  late final _is.ColumnUuid recordId;

  late final _is.ColumnBool offline;

  /// gzip of the codec JSON of the applied changes, with before (RD-20);
  /// null once pruned.
  late final _is.ColumnByteData payload;

  late final _is.ColumnInt changeCount;

  late final _is.ColumnString summaryJson;

  late final _is.ColumnString detailJson;

  /// Full outcome (04 §2.2) for idempotent re-acks; null once pruned.
  late final _is.ColumnString outcomeJson;

  /// The applied form is exactly the submitted changes.
  late final _is.ColumnBool appliedEqualsSubmitted;

  late final _is.ColumnDateTime clientCreatedAt;

  late final _is.ColumnDateTime committedAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: RevOp.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    clientOpId,
    baseRevision,
    authorId,
    authorUuid,
    sessionId,
    onBehalfOfSessionId,
    actorKind,
    label,
    groupId,
    groupIndex,
    groupLast,
    recordId,
    offline,
    payload,
    changeCount,
    summaryJson,
    detailJson,
    outcomeJson,
    appliedEqualsSubmitted,
    clientCreatedAt,
    committedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    return null;
  }
}

class RevOpInclude extends _is.IncludeObject {
  RevOpInclude._({_imcki4bb.RevFileInclude? file}) {
    _file = file;
  }

  _imcki4bb.RevFileInclude? _file;

  @override
  Map<String, _is.Include?> get includes => {'file': _file};

  @override
  _is.Table<int?> get table => RevOp.t;
}

class RevOpIncludeList extends _is.IncludeList {
  RevOpIncludeList._({
    _is.WhereExpressionBuilder<RevOpTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RevOp.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => RevOp.t;
}

class RevOpRepository {
  const RevOpRepository._();

  final attachRow = const RevOpAttachRowRepository._();

  /// Returns a list of [RevOp]s matching the given query parameters.
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
  Future<List<RevOp>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevOpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevOpTable>? orderBy,
    _is.OrderByListBuilder<RevOpTable>? orderByList,
    _is.Transaction? transaction,
    RevOpInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RevOp>(
      where: where?.call(RevOp.t),
      orderBy: orderBy?.call(RevOp.t),
      orderByList: orderByList?.call(RevOp.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [RevOp]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `RevOp.t`.
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
  _ida.Stream<List<RevOp>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevOpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevOpTable>? orderBy,
    _is.OrderByListBuilder<RevOpTable>? orderByList,
    RevOpInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<RevOp>(
      where: where?.call(RevOp.t),
      orderBy: orderBy?.call(RevOp.t),
      orderByList: orderByList?.call(RevOp.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [RevOp] matching the given query parameters.
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
  Future<RevOp?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevOpTable>? where,
    int? offset,
    _is.OrderByBuilder<RevOpTable>? orderBy,
    _is.OrderByListBuilder<RevOpTable>? orderByList,
    _is.Transaction? transaction,
    RevOpInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RevOp>(
      where: where?.call(RevOp.t),
      orderBy: orderBy?.call(RevOp.t),
      orderByList: orderByList?.call(RevOp.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RevOp] by its [id] or null if no such row exists.
  Future<RevOp?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    RevOpInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RevOp>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RevOp]s in the list and returns the inserted rows.
  ///
  /// The returned [RevOp]s will have their `id` fields set.
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
  Future<List<RevOp>> insert(
    _is.DatabaseSession session,
    List<RevOp> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RevOp>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RevOp] and returns the inserted row.
  ///
  /// The returned [RevOp] will have its `id` field set.
  Future<RevOp> insertRow(
    _is.DatabaseSession session,
    RevOp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<RevOp>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RevOp]s in the list and returns the resulting rows.
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
  /// The returned [RevOp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevOp>> upsert(
    _is.DatabaseSession session,
    List<RevOp> rows, {
    required _is.ColumnSelections<RevOpTable> conflictColumns,
    _is.ColumnSelections<RevOpTable>? updateColumns,
    _is.WhereExpressionBuilder<RevOpTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RevOp>(
      rows,
      conflictColumns: conflictColumns(RevOp.t),
      updateColumns: updateColumns?.call(RevOp.t),
      updateWhere: updateWhere?.call(RevOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RevOp] and returns the resulting row.
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
  /// The returned [RevOp] will have its `id` field set.
  Future<RevOp?> upsertRow(
    _is.DatabaseSession session,
    RevOp row, {
    required _is.ColumnSelections<RevOpTable> conflictColumns,
    _is.ColumnSelections<RevOpTable>? updateColumns,
    _is.WhereExpressionBuilder<RevOpTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RevOp>(
      row,
      conflictColumns: conflictColumns(RevOp.t),
      updateColumns: updateColumns?.call(RevOp.t),
      updateWhere: updateWhere?.call(RevOp.t),
      transaction: transaction,
    );
  }

  /// Updates all [RevOp]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevOp>> update(
    _is.DatabaseSession session,
    List<RevOp> rows, {
    _is.ColumnSelections<RevOpTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RevOp>(
      rows,
      columns: columns?.call(RevOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RevOp]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RevOp> updateRow(
    _is.DatabaseSession session,
    RevOp row, {
    _is.ColumnSelections<RevOpTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<RevOp>(
      row,
      columns: columns?.call(RevOp.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RevOp] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RevOp?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<RevOpUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<RevOp>(
      id,
      columnValues: columnValues(RevOp.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RevOp]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevOp>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RevOpUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RevOpTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevOpTable>? orderBy,
    _is.OrderByListBuilder<RevOpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RevOp>(
      columnValues: columnValues(RevOp.t.updateTable),
      where: where(RevOp.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RevOp.t),
      orderByList: orderByList?.call(RevOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RevOp]s in the list and returns the deleted rows.
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
  Future<List<RevOp>> delete(
    _is.DatabaseSession session,
    List<RevOp> rows, {
    _is.OrderByBuilder<RevOpTable>? orderBy,
    _is.OrderByListBuilder<RevOpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RevOp>(
      rows,
      orderBy: orderBy?.call(RevOp.t),
      orderByList: orderByList?.call(RevOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RevOp].
  Future<RevOp> deleteRow(
    _is.DatabaseSession session,
    RevOp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RevOp>(
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
  Future<List<RevOp>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RevOpTable> where,
    _is.OrderByBuilder<RevOpTable>? orderBy,
    _is.OrderByListBuilder<RevOpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RevOp>(
      where: where(RevOp.t),
      orderBy: orderBy?.call(RevOp.t),
      orderByList: orderByList?.call(RevOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevOpTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<RevOp>(
      where: where?.call(RevOp.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RevOp] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RevOpTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RevOp>(
      where: where(RevOp.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class RevOpAttachRowRepository {
  const RevOpAttachRowRepository._();

  /// Creates a relation between the given [RevOp] and [RevFile]
  /// by setting the [RevOp]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    RevOp revOp,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (revOp.id == null) {
      throw ArgumentError.notNull('revOp.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $revOp = revOp.copyWith(fileId: file.id);
    await session.db.updateRow<RevOp>(
      $revOp,
      columns: [RevOp.t.fileId],
      transaction: transaction,
    );
  }
}
