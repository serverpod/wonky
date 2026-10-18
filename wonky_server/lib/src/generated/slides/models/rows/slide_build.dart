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
import '../../../slides/models/rows/enums/build_kind.dart' as _inl7t7tg;
import '../../../slides/models/rows/enums/build_trigger.dart' as _ixzpbuvo;
import '../../../slides/models/rows/slide.dart' as _iet418te;
import '../../../slides/models/rows/slide_element.dart' as _ip9zwo22;

/// One animation step on a slide (Slides 02 §3.7; behavior and effect
/// catalog: 06).
abstract class SlideBuild
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  SlideBuild._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.slideId,
    this.slide,
    required this.elementId,
    this.element,
    required this.kind,
    required this.effect,
    required this.sortKey,
    required this.trigger,
    int? delayMs,
    required this.durationMs,
    required this.easing,
    this.optionsJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       delayMs = delayMs ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory SlideBuild({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue slideId,
    _iet418te.Slide? slide,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _inl7t7tg.BuildKind kind,
    required String effect,
    required String sortKey,
    required _ixzpbuvo.BuildTrigger trigger,
    int? delayMs,
    required int durationMs,
    required String easing,
    String? optionsJson,
    DateTime? createdAt,
  }) = _SlideBuildImpl;

  factory SlideBuild.fromJson(Map<String, dynamic> jsonSerialization) {
    return SlideBuild(
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
      slideId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['slideId'],
      ),
      slide: jsonSerialization['slide'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_iet418te.Slide>(
              jsonSerialization['slide'],
            ),
      elementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['elementId'],
      ),
      element: jsonSerialization['element'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ip9zwo22.SlideElement>(
              jsonSerialization['element'],
            ),
      kind: _inl7t7tg.BuildKind.fromJson((jsonSerialization['kind'] as String)),
      effect: jsonSerialization['effect'] as String,
      sortKey: jsonSerialization['sortKey'] as String,
      trigger: _ixzpbuvo.BuildTrigger.fromJson(
        (jsonSerialization['trigger'] as String),
      ),
      delayMs: jsonSerialization['delayMs'] as int?,
      durationMs: jsonSerialization['durationMs'] as int,
      easing: jsonSerialization['easing'] as String,
      optionsJson: jsonSerialization['optionsJson'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SlideBuildTable();

  static const db = SlideBuildRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue slideId;

  _iet418te.Slide? slide;

  _is.UuidValue elementId;

  /// Always set (nullable only by the FK convention).
  _ip9zwo22.SlideElement? element;

  _inl7t7tg.BuildKind kind;

  /// Effect key, e.g. "fade", "moveIn", "typewriter", "codeHighlight" (06).
  String effect;

  /// Order on the slide.
  String sortKey;

  _ixzpbuvo.BuildTrigger trigger;

  int delayMs;

  int durationMs;

  /// Easing expression (06 §4.3): "easeOut", "cubic(0.2,0,0,1)", "spring(0.5,0.25)".
  String easing;

  /// Direction, delivery, motion path, step refs ... (06 §2.2, 07, 08).
  String? optionsJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [SlideBuild]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SlideBuild copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideBuild$file(),
    int? revision,
    _is.UuidValue? slideId,
    _iet418te.Slide? slide = const _UndefinedSlideBuild$slide(),
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedSlideBuild$element(),
    _inl7t7tg.BuildKind? kind,
    String? effect,
    String? sortKey,
    _ixzpbuvo.BuildTrigger? trigger,
    int? delayMs,
    int? durationMs,
    String? easing,
    String? optionsJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SlideBuild',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'slideId': slideId.toJson(),
      if (slide != null) 'slide': slide?.toJson(),
      'elementId': elementId.toJson(),
      if (element != null) 'element': element?.toJson(),
      'kind': kind.toJson(),
      'effect': effect,
      'sortKey': sortKey,
      'trigger': trigger.toJson(),
      'delayMs': delayMs,
      'durationMs': durationMs,
      'easing': easing,
      if (optionsJson != null) 'optionsJson': optionsJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SlideBuildInclude include({
    _imcki4bb.RevFileInclude? file,
    _iet418te.SlideInclude? slide,
    _ip9zwo22.SlideElementInclude? element,
  }) {
    return SlideBuildInclude._(
      file: file,
      slide: slide,
      element: element,
    );
  }

  static SlideBuildIncludeList includeList({
    _is.WhereExpressionBuilder<SlideBuildTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideBuildTable>? orderBy,
    _is.OrderByListBuilder<SlideBuildTable>? orderByList,
    SlideBuildInclude? include,
  }) {
    return SlideBuildIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideBuild.t),
      orderByList: orderByList?.call(SlideBuild.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSlideBuild$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedSlideBuild$file();
}

class _UndefinedSlideBuild$slide extends _is.UndefinedSentinel
    implements _iet418te.Slide {
  const _UndefinedSlideBuild$slide();
}

class _UndefinedSlideBuild$element extends _is.UndefinedSentinel
    implements _ip9zwo22.SlideElement {
  const _UndefinedSlideBuild$element();
}

class _SlideBuildImpl extends SlideBuild {
  _SlideBuildImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue slideId,
    _iet418te.Slide? slide,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _inl7t7tg.BuildKind kind,
    required String effect,
    required String sortKey,
    required _ixzpbuvo.BuildTrigger trigger,
    int? delayMs,
    required int durationMs,
    required String easing,
    String? optionsJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         slideId: slideId,
         slide: slide,
         elementId: elementId,
         element: element,
         kind: kind,
         effect: effect,
         sortKey: sortKey,
         trigger: trigger,
         delayMs: delayMs,
         durationMs: durationMs,
         easing: easing,
         optionsJson: optionsJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SlideBuild]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SlideBuild copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideBuild$file(),
    int? revision,
    _is.UuidValue? slideId,
    _iet418te.Slide? slide = const _UndefinedSlideBuild$slide(),
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedSlideBuild$element(),
    _inl7t7tg.BuildKind? kind,
    String? effect,
    String? sortKey,
    _ixzpbuvo.BuildTrigger? trigger,
    int? delayMs,
    int? durationMs,
    String? easing,
    Object? optionsJson = _Undefined,
    DateTime? createdAt,
  }) {
    return SlideBuild(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      slideId: slideId ?? this.slideId,
      slide: slide is _is.UndefinedSentinel ? this.slide?.copyWith() : slide,
      elementId: elementId ?? this.elementId,
      element: element is _is.UndefinedSentinel
          ? this.element?.copyWith()
          : element,
      kind: kind ?? this.kind,
      effect: effect ?? this.effect,
      sortKey: sortKey ?? this.sortKey,
      trigger: trigger ?? this.trigger,
      delayMs: delayMs ?? this.delayMs,
      durationMs: durationMs ?? this.durationMs,
      easing: easing ?? this.easing,
      optionsJson: optionsJson is String? ? optionsJson : this.optionsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SlideBuildUpdateTable extends _is.UpdateTable<SlideBuildTable> {
  SlideBuildUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> slideId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.slideId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> elementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.elementId,
    value,
  );

  _is.ColumnValue<_inl7t7tg.BuildKind, _inl7t7tg.BuildKind> kind(
    _inl7t7tg.BuildKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> effect(String value) => _is.ColumnValue(
    table.effect,
    value,
  );

  _is.ColumnValue<String, String> sortKey(String value) => _is.ColumnValue(
    table.sortKey,
    value,
  );

  _is.ColumnValue<_ixzpbuvo.BuildTrigger, _ixzpbuvo.BuildTrigger> trigger(
    _ixzpbuvo.BuildTrigger value,
  ) => _is.ColumnValue(
    table.trigger,
    value,
  );

  _is.ColumnValue<int, int> delayMs(int value) => _is.ColumnValue(
    table.delayMs,
    value,
  );

  _is.ColumnValue<int, int> durationMs(int value) => _is.ColumnValue(
    table.durationMs,
    value,
  );

  _is.ColumnValue<String, String> easing(String value) => _is.ColumnValue(
    table.easing,
    value,
  );

  _is.ColumnValue<String, String> optionsJson(String? value) => _is.ColumnValue(
    table.optionsJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SlideBuildTable extends _is.Table<_is.UuidValue> {
  SlideBuildTable({super.tableRelation}) : super(tableName: 'slide_build') {
    updateTable = SlideBuildUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    slideId = _is.ColumnUuid(
      'slideId',
      this,
    );
    elementId = _is.ColumnUuid(
      'elementId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    effect = _is.ColumnString(
      'effect',
      this,
    );
    sortKey = _is.ColumnString(
      'sortKey',
      this,
    );
    trigger = _is.ColumnEnum(
      'trigger',
      this,
      _is.EnumSerialization.byName,
    );
    delayMs = _is.ColumnInt(
      'delayMs',
      this,
      hasDefault: true,
    );
    durationMs = _is.ColumnInt(
      'durationMs',
      this,
    );
    easing = _is.ColumnString(
      'easing',
      this,
    );
    optionsJson = _is.ColumnString(
      'optionsJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SlideBuildUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid slideId;

  _iet418te.SlideTable? _slide;

  late final _is.ColumnUuid elementId;

  /// Always set (nullable only by the FK convention).
  _ip9zwo22.SlideElementTable? _element;

  late final _is.ColumnEnum<_inl7t7tg.BuildKind> kind;

  /// Effect key, e.g. "fade", "moveIn", "typewriter", "codeHighlight" (06).
  late final _is.ColumnString effect;

  /// Order on the slide.
  late final _is.ColumnString sortKey;

  late final _is.ColumnEnum<_ixzpbuvo.BuildTrigger> trigger;

  late final _is.ColumnInt delayMs;

  late final _is.ColumnInt durationMs;

  /// Easing expression (06 §4.3): "easeOut", "cubic(0.2,0,0,1)", "spring(0.5,0.25)".
  late final _is.ColumnString easing;

  /// Direction, delivery, motion path, step refs ... (06 §2.2, 07, 08).
  late final _is.ColumnString optionsJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: SlideBuild.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _iet418te.SlideTable get slide {
    if (_slide != null) return _slide!;
    _slide = _is.createRelationTable(
      relationFieldName: 'slide',
      field: SlideBuild.t.slideId,
      foreignField: _iet418te.Slide.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iet418te.SlideTable(tableRelation: foreignTableRelation),
    );
    return _slide!;
  }

  _ip9zwo22.SlideElementTable get element {
    if (_element != null) return _element!;
    _element = _is.createRelationTable(
      relationFieldName: 'element',
      field: SlideBuild.t.elementId,
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
    slideId,
    elementId,
    kind,
    effect,
    sortKey,
    trigger,
    delayMs,
    durationMs,
    easing,
    optionsJson,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'slide') {
      return slide;
    }
    if (relationField == 'element') {
      return element;
    }
    return null;
  }
}

class SlideBuildInclude extends _is.IncludeObject {
  SlideBuildInclude._({
    _imcki4bb.RevFileInclude? file,
    _iet418te.SlideInclude? slide,
    _ip9zwo22.SlideElementInclude? element,
  }) {
    _file = file;
    _slide = slide;
    _element = element;
  }

  _imcki4bb.RevFileInclude? _file;

  _iet418te.SlideInclude? _slide;

  _ip9zwo22.SlideElementInclude? _element;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'slide': _slide,
    'element': _element,
  };

  @override
  _is.Table<_is.UuidValue> get table => SlideBuild.t;
}

class SlideBuildIncludeList extends _is.IncludeList {
  SlideBuildIncludeList._({
    _is.WhereExpressionBuilder<SlideBuildTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SlideBuild.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => SlideBuild.t;
}

class SlideBuildRepository {
  const SlideBuildRepository._();

  final attachRow = const SlideBuildAttachRowRepository._();

  /// Returns a list of [SlideBuild]s matching the given query parameters.
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
  Future<List<SlideBuild>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideBuildTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideBuildTable>? orderBy,
    _is.OrderByListBuilder<SlideBuildTable>? orderByList,
    _is.Transaction? transaction,
    SlideBuildInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SlideBuild>(
      where: where?.call(SlideBuild.t),
      orderBy: orderBy?.call(SlideBuild.t),
      orderByList: orderByList?.call(SlideBuild.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [SlideBuild]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `SlideBuild.t`.
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
  _ida.Stream<List<SlideBuild>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideBuildTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideBuildTable>? orderBy,
    _is.OrderByListBuilder<SlideBuildTable>? orderByList,
    SlideBuildInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<SlideBuild>(
      where: where?.call(SlideBuild.t),
      orderBy: orderBy?.call(SlideBuild.t),
      orderByList: orderByList?.call(SlideBuild.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [SlideBuild] matching the given query parameters.
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
  Future<SlideBuild?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideBuildTable>? where,
    int? offset,
    _is.OrderByBuilder<SlideBuildTable>? orderBy,
    _is.OrderByListBuilder<SlideBuildTable>? orderByList,
    _is.Transaction? transaction,
    SlideBuildInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SlideBuild>(
      where: where?.call(SlideBuild.t),
      orderBy: orderBy?.call(SlideBuild.t),
      orderByList: orderByList?.call(SlideBuild.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SlideBuild] by its [id] or null if no such row exists.
  Future<SlideBuild?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    SlideBuildInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SlideBuild>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SlideBuild]s in the list and returns the inserted rows.
  ///
  /// The returned [SlideBuild]s will have their `id` fields set.
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
  Future<List<SlideBuild>> insert(
    _is.DatabaseSession session,
    List<SlideBuild> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SlideBuild>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SlideBuild] and returns the inserted row.
  ///
  /// The returned [SlideBuild] will have its `id` field set.
  Future<SlideBuild> insertRow(
    _is.DatabaseSession session,
    SlideBuild row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SlideBuild>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SlideBuild]s in the list and returns the resulting rows.
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
  /// The returned [SlideBuild]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideBuild>> upsert(
    _is.DatabaseSession session,
    List<SlideBuild> rows, {
    required _is.ColumnSelections<SlideBuildTable> conflictColumns,
    _is.ColumnSelections<SlideBuildTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideBuildTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SlideBuild>(
      rows,
      conflictColumns: conflictColumns(SlideBuild.t),
      updateColumns: updateColumns?.call(SlideBuild.t),
      updateWhere: updateWhere?.call(SlideBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SlideBuild] and returns the resulting row.
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
  /// The returned [SlideBuild] will have its `id` field set.
  Future<SlideBuild?> upsertRow(
    _is.DatabaseSession session,
    SlideBuild row, {
    required _is.ColumnSelections<SlideBuildTable> conflictColumns,
    _is.ColumnSelections<SlideBuildTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideBuildTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SlideBuild>(
      row,
      conflictColumns: conflictColumns(SlideBuild.t),
      updateColumns: updateColumns?.call(SlideBuild.t),
      updateWhere: updateWhere?.call(SlideBuild.t),
      transaction: transaction,
    );
  }

  /// Updates all [SlideBuild]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideBuild>> update(
    _is.DatabaseSession session,
    List<SlideBuild> rows, {
    _is.ColumnSelections<SlideBuildTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SlideBuild>(
      rows,
      columns: columns?.call(SlideBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SlideBuild]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SlideBuild> updateRow(
    _is.DatabaseSession session,
    SlideBuild row, {
    _is.ColumnSelections<SlideBuildTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SlideBuild>(
      row,
      columns: columns?.call(SlideBuild.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SlideBuild] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SlideBuild?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<SlideBuildUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SlideBuild>(
      id,
      columnValues: columnValues(SlideBuild.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SlideBuild]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideBuild>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SlideBuildUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SlideBuildTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideBuildTable>? orderBy,
    _is.OrderByListBuilder<SlideBuildTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SlideBuild>(
      columnValues: columnValues(SlideBuild.t.updateTable),
      where: where(SlideBuild.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideBuild.t),
      orderByList: orderByList?.call(SlideBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SlideBuild]s in the list and returns the deleted rows.
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
  Future<List<SlideBuild>> delete(
    _is.DatabaseSession session,
    List<SlideBuild> rows, {
    _is.OrderByBuilder<SlideBuildTable>? orderBy,
    _is.OrderByListBuilder<SlideBuildTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SlideBuild>(
      rows,
      orderBy: orderBy?.call(SlideBuild.t),
      orderByList: orderByList?.call(SlideBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SlideBuild].
  Future<SlideBuild> deleteRow(
    _is.DatabaseSession session,
    SlideBuild row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SlideBuild>(
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
  Future<List<SlideBuild>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideBuildTable> where,
    _is.OrderByBuilder<SlideBuildTable>? orderBy,
    _is.OrderByListBuilder<SlideBuildTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SlideBuild>(
      where: where(SlideBuild.t),
      orderBy: orderBy?.call(SlideBuild.t),
      orderByList: orderByList?.call(SlideBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideBuildTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SlideBuild>(
      where: where?.call(SlideBuild.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SlideBuild] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideBuildTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SlideBuild>(
      where: where(SlideBuild.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SlideBuildAttachRowRepository {
  const SlideBuildAttachRowRepository._();

  /// Creates a relation between the given [SlideBuild] and [RevFile]
  /// by setting the [SlideBuild]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    SlideBuild slideBuild,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (slideBuild.id == null) {
      throw ArgumentError.notNull('slideBuild.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $slideBuild = slideBuild.copyWith(fileId: file.id);
    await session.db.updateRow<SlideBuild>(
      $slideBuild,
      columns: [SlideBuild.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideBuild] and [Slide]
  /// by setting the [SlideBuild]'s foreign key `slideId` to refer to the [Slide].
  Future<void> slide(
    _is.DatabaseSession session,
    SlideBuild slideBuild,
    _iet418te.Slide slide, {
    _is.Transaction? transaction,
  }) async {
    if (slideBuild.id == null) {
      throw ArgumentError.notNull('slideBuild.id');
    }
    if (slide.id == null) {
      throw ArgumentError.notNull('slide.id');
    }

    var $slideBuild = slideBuild.copyWith(slideId: slide.id);
    await session.db.updateRow<SlideBuild>(
      $slideBuild,
      columns: [SlideBuild.t.slideId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideBuild] and [SlideElement]
  /// by setting the [SlideBuild]'s foreign key `elementId` to refer to the [SlideElement].
  Future<void> element(
    _is.DatabaseSession session,
    SlideBuild slideBuild,
    _ip9zwo22.SlideElement element, {
    _is.Transaction? transaction,
  }) async {
    if (slideBuild.id == null) {
      throw ArgumentError.notNull('slideBuild.id');
    }
    if (element.id == null) {
      throw ArgumentError.notNull('element.id');
    }

    var $slideBuild = slideBuild.copyWith(elementId: element.id);
    await session.db.updateRow<SlideBuild>(
      $slideBuild,
      columns: [SlideBuild.t.elementId],
      transaction: transaction,
    );
  }
}
