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
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/revlog/models/rev_file.dart' as _imcki4bb;
import '../../../slides/models/rows/slide_element.dart' as _ip9zwo22;

/// One version of a code element's source (Slides 02 §3.8, 07 §3.2). Every
/// state, including the first, is a row; a code element has at least one.
abstract class CodeState
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  CodeState._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.elementId,
    this.element,
    required this.sortKey,
    this.label,
    required this.code,
    this.language,
    this.title,
    this.highlight,
    this.annotationsJson,
    this.transitionJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory CodeState({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required String sortKey,
    String? label,
    required String code,
    String? language,
    String? title,
    String? highlight,
    String? annotationsJson,
    String? transitionJson,
    DateTime? createdAt,
  }) = _CodeStateImpl;

  factory CodeState.fromJson(Map<String, dynamic> jsonSerialization) {
    return CodeState(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      fileId: jsonSerialization['fileId'] as int,
      file: jsonSerialization['file'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_imcki4bb.RevFile>(
              jsonSerialization['file'],
            ),
      revision: jsonSerialization['revision'] as int?,
      elementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['elementId'],
      ),
      element: jsonSerialization['element'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ip9zwo22.SlideElement>(
              jsonSerialization['element'],
            ),
      sortKey: jsonSerialization['sortKey'] as String,
      label: jsonSerialization['label'] as String?,
      code: jsonSerialization['code'] as String,
      language: jsonSerialization['language'] as String?,
      title: jsonSerialization['title'] as String?,
      highlight: jsonSerialization['highlight'] as String?,
      annotationsJson: jsonSerialization['annotationsJson'] as String?,
      transitionJson: jsonSerialization['transitionJson'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = CodeStateTable();

  static const db = CodeStateRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue elementId;

  /// The code element (kind code).
  _ip9zwo22.SlideElement? element;

  String sortKey;

  /// "Add caching".
  String? label;

  /// Full source of this state (whole-value LWW).
  String code;

  /// null = the element's language (07 A-07-2).
  String? language;

  /// null = the element's title.
  String? title;

  /// Line-highlight steps, e.g. "1-3 | 5" (07 §4.1).
  String? highlight;

  /// Per-step callouts (07 §4.4).
  String? annotationsJson;

  /// How this state is reached from the previous one (07 §5.3).
  String? transitionJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [CodeState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CodeState copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedCodeState$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedCodeState$element(),
    String? sortKey,
    String? label,
    String? code,
    String? language,
    String? title,
    String? highlight,
    String? annotationsJson,
    String? transitionJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CodeState',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'elementId': elementId.toJson(),
      if (element != null) 'element': element?.toJson(),
      'sortKey': sortKey,
      if (label != null) 'label': label,
      'code': code,
      if (language != null) 'language': language,
      if (title != null) 'title': title,
      if (highlight != null) 'highlight': highlight,
      if (annotationsJson != null) 'annotationsJson': annotationsJson,
      if (transitionJson != null) 'transitionJson': transitionJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static CodeStateInclude include({
    _imcki4bb.RevFileInclude? file,
    _ip9zwo22.SlideElementInclude? element,
  }) {
    return CodeStateInclude._(
      file: file,
      element: element,
    );
  }

  static CodeStateIncludeList includeList({
    _is.WhereExpressionBuilder<CodeStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodeStateTable>? orderBy,
    _is.OrderByListBuilder<CodeStateTable>? orderByList,
    CodeStateInclude? include,
  }) {
    return CodeStateIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodeState.t),
      orderByList: orderByList?.call(CodeState.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedCodeState$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedCodeState$file();
}

class _UndefinedCodeState$element extends _is.UndefinedSentinel
    implements _ip9zwo22.SlideElement {
  const _UndefinedCodeState$element();
}

class _CodeStateImpl extends CodeState {
  _CodeStateImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required String sortKey,
    String? label,
    required String code,
    String? language,
    String? title,
    String? highlight,
    String? annotationsJson,
    String? transitionJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         elementId: elementId,
         element: element,
         sortKey: sortKey,
         label: label,
         code: code,
         language: language,
         title: title,
         highlight: highlight,
         annotationsJson: annotationsJson,
         transitionJson: transitionJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [CodeState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CodeState copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedCodeState$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedCodeState$element(),
    String? sortKey,
    Object? label = _Undefined,
    String? code,
    Object? language = _Undefined,
    Object? title = _Undefined,
    Object? highlight = _Undefined,
    Object? annotationsJson = _Undefined,
    Object? transitionJson = _Undefined,
    DateTime? createdAt,
  }) {
    return CodeState(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      elementId: elementId ?? this.elementId,
      element: element is _is.UndefinedSentinel
          ? this.element?.copyWith()
          : element,
      sortKey: sortKey ?? this.sortKey,
      label: label is String? ? label : this.label,
      code: code ?? this.code,
      language: language is String? ? language : this.language,
      title: title is String? ? title : this.title,
      highlight: highlight is String? ? highlight : this.highlight,
      annotationsJson: annotationsJson is String?
          ? annotationsJson
          : this.annotationsJson,
      transitionJson: transitionJson is String?
          ? transitionJson
          : this.transitionJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CodeStateUpdateTable extends _is.UpdateTable<CodeStateTable> {
  CodeStateUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> elementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.elementId,
    value,
  );

  _is.ColumnValue<String, String> sortKey(String value) => _is.ColumnValue(
    table.sortKey,
    value,
  );

  _is.ColumnValue<String, String> label(String? value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<String, String> code(String value) => _is.ColumnValue(
    table.code,
    value,
  );

  _is.ColumnValue<String, String> language(String? value) => _is.ColumnValue(
    table.language,
    value,
  );

  _is.ColumnValue<String, String> title(String? value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> highlight(String? value) => _is.ColumnValue(
    table.highlight,
    value,
  );

  _is.ColumnValue<String, String> annotationsJson(String? value) =>
      _is.ColumnValue(
        table.annotationsJson,
        value,
      );

  _is.ColumnValue<String, String> transitionJson(String? value) =>
      _is.ColumnValue(
        table.transitionJson,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class CodeStateTable extends _is.Table<_is.UuidValue> {
  CodeStateTable({super.tableRelation}) : super(tableName: 'code_state') {
    updateTable = CodeStateUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    elementId = _is.ColumnUuid(
      'elementId',
      this,
    );
    sortKey = _is.ColumnString(
      'sortKey',
      this,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    code = _is.ColumnString(
      'code',
      this,
    );
    language = _is.ColumnString(
      'language',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    highlight = _is.ColumnString(
      'highlight',
      this,
    );
    annotationsJson = _is.ColumnString(
      'annotationsJson',
      this,
    );
    transitionJson = _is.ColumnString(
      'transitionJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final CodeStateUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid elementId;

  /// The code element (kind code).
  _ip9zwo22.SlideElementTable? _element;

  late final _is.ColumnString sortKey;

  /// "Add caching".
  late final _is.ColumnString label;

  /// Full source of this state (whole-value LWW).
  late final _is.ColumnString code;

  /// null = the element's language (07 A-07-2).
  late final _is.ColumnString language;

  /// null = the element's title.
  late final _is.ColumnString title;

  /// Line-highlight steps, e.g. "1-3 | 5" (07 §4.1).
  late final _is.ColumnString highlight;

  /// Per-step callouts (07 §4.4).
  late final _is.ColumnString annotationsJson;

  /// How this state is reached from the previous one (07 §5.3).
  late final _is.ColumnString transitionJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: CodeState.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _ip9zwo22.SlideElementTable get element {
    if (_element != null) return _element!;
    _element = _is.createRelationTable(
      relationFieldName: 'element',
      field: CodeState.t.elementId,
      foreignField: _ip9zwo22.SlideElement.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ip9zwo22.SlideElementTable(tableRelation: foreignTableRelation),
    );
    return _element!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    elementId,
    sortKey,
    label,
    code,
    language,
    title,
    highlight,
    annotationsJson,
    transitionJson,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'element') {
      return element;
    }
    return null;
  }
}

class CodeStateInclude extends _is.IncludeObject {
  CodeStateInclude._({
    _imcki4bb.RevFileInclude? file,
    _ip9zwo22.SlideElementInclude? element,
  }) {
    _file = file;
    _element = element;
  }

  _imcki4bb.RevFileInclude? _file;

  _ip9zwo22.SlideElementInclude? _element;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'element': _element,
  };

  @override
  _is.Table<_is.UuidValue> get table => CodeState.t;
}

class CodeStateIncludeList extends _is.IncludeList {
  CodeStateIncludeList._({
    _is.WhereExpressionBuilder<CodeStateTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CodeState.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => CodeState.t;
}

class CodeStateRepository {
  const CodeStateRepository._();

  final attachRow = const CodeStateAttachRowRepository._();

  /// Returns a list of [CodeState]s matching the given query parameters.
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
  Future<List<CodeState>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodeStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodeStateTable>? orderBy,
    _is.OrderByListBuilder<CodeStateTable>? orderByList,
    _is.Transaction? transaction,
    CodeStateInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CodeState>(
      where: where?.call(CodeState.t),
      orderBy: orderBy?.call(CodeState.t),
      orderByList: orderByList?.call(CodeState.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [CodeState]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `CodeState.t`.
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
  _ida.Stream<List<CodeState>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodeStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodeStateTable>? orderBy,
    _is.OrderByListBuilder<CodeStateTable>? orderByList,
    CodeStateInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<CodeState>(
      where: where?.call(CodeState.t),
      orderBy: orderBy?.call(CodeState.t),
      orderByList: orderByList?.call(CodeState.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [CodeState] matching the given query parameters.
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
  Future<CodeState?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodeStateTable>? where,
    int? offset,
    _is.OrderByBuilder<CodeStateTable>? orderBy,
    _is.OrderByListBuilder<CodeStateTable>? orderByList,
    _is.Transaction? transaction,
    CodeStateInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CodeState>(
      where: where?.call(CodeState.t),
      orderBy: orderBy?.call(CodeState.t),
      orderByList: orderByList?.call(CodeState.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CodeState] by its [id] or null if no such row exists.
  Future<CodeState?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    CodeStateInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CodeState>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CodeState]s in the list and returns the inserted rows.
  ///
  /// The returned [CodeState]s will have their `id` fields set.
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
  Future<List<CodeState>> insert(
    _is.DatabaseSession session,
    List<CodeState> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CodeState>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CodeState] and returns the inserted row.
  ///
  /// The returned [CodeState] will have its `id` field set.
  Future<CodeState> insertRow(
    _is.DatabaseSession session,
    CodeState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<CodeState>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CodeState]s in the list and returns the resulting rows.
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
  /// The returned [CodeState]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodeState>> upsert(
    _is.DatabaseSession session,
    List<CodeState> rows, {
    required _is.ColumnSelections<CodeStateTable> conflictColumns,
    _is.ColumnSelections<CodeStateTable>? updateColumns,
    _is.WhereExpressionBuilder<CodeStateTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CodeState>(
      rows,
      conflictColumns: conflictColumns(CodeState.t),
      updateColumns: updateColumns?.call(CodeState.t),
      updateWhere: updateWhere?.call(CodeState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CodeState] and returns the resulting row.
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
  /// The returned [CodeState] will have its `id` field set.
  Future<CodeState?> upsertRow(
    _is.DatabaseSession session,
    CodeState row, {
    required _is.ColumnSelections<CodeStateTable> conflictColumns,
    _is.ColumnSelections<CodeStateTable>? updateColumns,
    _is.WhereExpressionBuilder<CodeStateTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CodeState>(
      row,
      conflictColumns: conflictColumns(CodeState.t),
      updateColumns: updateColumns?.call(CodeState.t),
      updateWhere: updateWhere?.call(CodeState.t),
      transaction: transaction,
    );
  }

  /// Updates all [CodeState]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodeState>> update(
    _is.DatabaseSession session,
    List<CodeState> rows, {
    _is.ColumnSelections<CodeStateTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CodeState>(
      rows,
      columns: columns?.call(CodeState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CodeState]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CodeState> updateRow(
    _is.DatabaseSession session,
    CodeState row, {
    _is.ColumnSelections<CodeStateTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<CodeState>(
      row,
      columns: columns?.call(CodeState.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CodeState] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CodeState?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<CodeStateUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<CodeState>(
      id,
      columnValues: columnValues(CodeState.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CodeState]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CodeState>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CodeStateUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CodeStateTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CodeStateTable>? orderBy,
    _is.OrderByListBuilder<CodeStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CodeState>(
      columnValues: columnValues(CodeState.t.updateTable),
      where: where(CodeState.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CodeState.t),
      orderByList: orderByList?.call(CodeState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CodeState]s in the list and returns the deleted rows.
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
  Future<List<CodeState>> delete(
    _is.DatabaseSession session,
    List<CodeState> rows, {
    _is.OrderByBuilder<CodeStateTable>? orderBy,
    _is.OrderByListBuilder<CodeStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CodeState>(
      rows,
      orderBy: orderBy?.call(CodeState.t),
      orderByList: orderByList?.call(CodeState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CodeState].
  Future<CodeState> deleteRow(
    _is.DatabaseSession session,
    CodeState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CodeState>(
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
  Future<List<CodeState>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CodeStateTable> where,
    _is.OrderByBuilder<CodeStateTable>? orderBy,
    _is.OrderByListBuilder<CodeStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CodeState>(
      where: where(CodeState.t),
      orderBy: orderBy?.call(CodeState.t),
      orderByList: orderByList?.call(CodeState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CodeStateTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CodeState>(
      where: where?.call(CodeState.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CodeState] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CodeStateTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CodeState>(
      where: where(CodeState.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class CodeStateAttachRowRepository {
  const CodeStateAttachRowRepository._();

  /// Creates a relation between the given [CodeState] and [RevFile]
  /// by setting the [CodeState]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    CodeState codeState,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (codeState.id == null) {
      throw ArgumentError.notNull('codeState.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $codeState = codeState.copyWith(fileId: file.id);
    await session.db.updateRow<CodeState>(
      $codeState,
      columns: [CodeState.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [CodeState] and [SlideElement]
  /// by setting the [CodeState]'s foreign key `elementId` to refer to the [SlideElement].
  Future<void> element(
    _is.DatabaseSession session,
    CodeState codeState,
    _ip9zwo22.SlideElement element, {
    _is.Transaction? transaction,
  }) async {
    if (codeState.id == null) {
      throw ArgumentError.notNull('codeState.id');
    }
    if (element.id == null) {
      throw ArgumentError.notNull('element.id');
    }

    var $codeState = codeState.copyWith(elementId: element.id);
    await session.db.updateRow<CodeState>(
      $codeState,
      columns: [CodeState.t.elementId],
      transaction: transaction,
    );
  }
}
