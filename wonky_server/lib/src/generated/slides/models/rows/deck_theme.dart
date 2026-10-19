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
import '../../../slides/models/rows/deck.dart' as _ilwyx5cu;

/// A theme copied into the deck (Slides 02 §3.2, 05). A deck has at least one
/// theme; slides pasted with "keep source formatting" bring their own. Copies
/// of built-in or library themes use SlidesIds.themeCopyId.
abstract class DeckTheme
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  DeckTheme._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.deckId,
    this.deck,
    required this.name,
    this.sourceKey,
    required this.colorsJson,
    required this.fontsJson,
    required this.textStylesJson,
    required this.backgroundJson,
    this.shapeStyleJson,
    this.tableStyleJson,
    this.codeStyleJson,
    this.chartStyleJson,
    required this.sortKey,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory DeckTheme({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue deckId,
    _ilwyx5cu.Deck? deck,
    required String name,
    String? sourceKey,
    required String colorsJson,
    required String fontsJson,
    required String textStylesJson,
    required String backgroundJson,
    String? shapeStyleJson,
    String? tableStyleJson,
    String? codeStyleJson,
    String? chartStyleJson,
    required String sortKey,
    DateTime? createdAt,
  }) = _DeckThemeImpl;

  factory DeckTheme.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeckTheme(
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
      deckId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['deckId']),
      deck: jsonSerialization['deck'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ilwyx5cu.Deck>(
              jsonSerialization['deck'],
            ),
      name: jsonSerialization['name'] as String,
      sourceKey: jsonSerialization['sourceKey'] as String?,
      colorsJson: jsonSerialization['colorsJson'] as String,
      fontsJson: jsonSerialization['fontsJson'] as String,
      textStylesJson: jsonSerialization['textStylesJson'] as String,
      backgroundJson: jsonSerialization['backgroundJson'] as String,
      shapeStyleJson: jsonSerialization['shapeStyleJson'] as String?,
      tableStyleJson: jsonSerialization['tableStyleJson'] as String?,
      codeStyleJson: jsonSerialization['codeStyleJson'] as String?,
      chartStyleJson: jsonSerialization['chartStyleJson'] as String?,
      sortKey: jsonSerialization['sortKey'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = DeckThemeTable();

  static const db = DeckThemeRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue deckId;

  _ilwyx5cu.Deck? deck;

  String name;

  /// Provenance: builtin:<key>@<v> | deck:<itemUuid>:<themeId> | null (created here).
  String? sourceKey;

  /// {light:{bg1,text1,...,accent1-6,link}, dark:{...}} (05 §2.2).
  String colorsJson;

  /// {heading, body, mono, sizes?} (05 §2.3).
  String fontsJson;

  /// Named text styles (05 §2.5).
  String textStylesJson;

  /// Default background (05 §2.6).
  String backgroundJson;

  /// Default fill/stroke/text of new shapes, lines, text boxes (05 §2.7).
  String? shapeStyleJson;

  /// Default table style (05 §2.8).
  String? tableStyleJson;

  /// Code palettes light/dark + chrome (05 §2.9, 07).
  String? codeStyleJson;

  /// Series palette order, fonts, gridlines (05 §2.10, 08).
  String? chartStyleJson;

  /// Order in the Themes panel (fractional index; ties by id).
  String sortKey;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [DeckTheme]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeckTheme copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDeckTheme$file(),
    int? revision,
    _is.UuidValue? deckId,
    _ilwyx5cu.Deck? deck = const _UndefinedDeckTheme$deck(),
    String? name,
    String? sourceKey,
    String? colorsJson,
    String? fontsJson,
    String? textStylesJson,
    String? backgroundJson,
    String? shapeStyleJson,
    String? tableStyleJson,
    String? codeStyleJson,
    String? chartStyleJson,
    String? sortKey,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeckTheme',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'deckId': deckId.toJson(),
      if (deck != null) 'deck': deck?.toJson(),
      'name': name,
      if (sourceKey != null) 'sourceKey': sourceKey,
      'colorsJson': colorsJson,
      'fontsJson': fontsJson,
      'textStylesJson': textStylesJson,
      'backgroundJson': backgroundJson,
      if (shapeStyleJson != null) 'shapeStyleJson': shapeStyleJson,
      if (tableStyleJson != null) 'tableStyleJson': tableStyleJson,
      if (codeStyleJson != null) 'codeStyleJson': codeStyleJson,
      if (chartStyleJson != null) 'chartStyleJson': chartStyleJson,
      'sortKey': sortKey,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DeckThemeInclude include({
    _imcki4bb.RevFileInclude? file,
    _ilwyx5cu.DeckInclude? deck,
  }) {
    return DeckThemeInclude._(
      file: file,
      deck: deck,
    );
  }

  static DeckThemeIncludeList includeList({
    _is.WhereExpressionBuilder<DeckThemeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckThemeTable>? orderBy,
    _is.OrderByListBuilder<DeckThemeTable>? orderByList,
    DeckThemeInclude? include,
  }) {
    return DeckThemeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeckTheme.t),
      orderByList: orderByList?.call(DeckTheme.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedDeckTheme$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedDeckTheme$file();
}

class _UndefinedDeckTheme$deck extends _is.UndefinedSentinel
    implements _ilwyx5cu.Deck {
  const _UndefinedDeckTheme$deck();
}

class _DeckThemeImpl extends DeckTheme {
  _DeckThemeImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue deckId,
    _ilwyx5cu.Deck? deck,
    required String name,
    String? sourceKey,
    required String colorsJson,
    required String fontsJson,
    required String textStylesJson,
    required String backgroundJson,
    String? shapeStyleJson,
    String? tableStyleJson,
    String? codeStyleJson,
    String? chartStyleJson,
    required String sortKey,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         deckId: deckId,
         deck: deck,
         name: name,
         sourceKey: sourceKey,
         colorsJson: colorsJson,
         fontsJson: fontsJson,
         textStylesJson: textStylesJson,
         backgroundJson: backgroundJson,
         shapeStyleJson: shapeStyleJson,
         tableStyleJson: tableStyleJson,
         codeStyleJson: codeStyleJson,
         chartStyleJson: chartStyleJson,
         sortKey: sortKey,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DeckTheme]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeckTheme copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDeckTheme$file(),
    int? revision,
    _is.UuidValue? deckId,
    _ilwyx5cu.Deck? deck = const _UndefinedDeckTheme$deck(),
    String? name,
    Object? sourceKey = _Undefined,
    String? colorsJson,
    String? fontsJson,
    String? textStylesJson,
    String? backgroundJson,
    Object? shapeStyleJson = _Undefined,
    Object? tableStyleJson = _Undefined,
    Object? codeStyleJson = _Undefined,
    Object? chartStyleJson = _Undefined,
    String? sortKey,
    DateTime? createdAt,
  }) {
    return DeckTheme(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      deckId: deckId ?? this.deckId,
      deck: deck is _is.UndefinedSentinel ? this.deck?.copyWith() : deck,
      name: name ?? this.name,
      sourceKey: sourceKey is String? ? sourceKey : this.sourceKey,
      colorsJson: colorsJson ?? this.colorsJson,
      fontsJson: fontsJson ?? this.fontsJson,
      textStylesJson: textStylesJson ?? this.textStylesJson,
      backgroundJson: backgroundJson ?? this.backgroundJson,
      shapeStyleJson: shapeStyleJson is String?
          ? shapeStyleJson
          : this.shapeStyleJson,
      tableStyleJson: tableStyleJson is String?
          ? tableStyleJson
          : this.tableStyleJson,
      codeStyleJson: codeStyleJson is String?
          ? codeStyleJson
          : this.codeStyleJson,
      chartStyleJson: chartStyleJson is String?
          ? chartStyleJson
          : this.chartStyleJson,
      sortKey: sortKey ?? this.sortKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DeckThemeUpdateTable extends _is.UpdateTable<DeckThemeTable> {
  DeckThemeUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> deckId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.deckId,
        value,
      );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> sourceKey(String? value) => _is.ColumnValue(
    table.sourceKey,
    value,
  );

  _is.ColumnValue<String, String> colorsJson(String value) => _is.ColumnValue(
    table.colorsJson,
    value,
  );

  _is.ColumnValue<String, String> fontsJson(String value) => _is.ColumnValue(
    table.fontsJson,
    value,
  );

  _is.ColumnValue<String, String> textStylesJson(String value) =>
      _is.ColumnValue(
        table.textStylesJson,
        value,
      );

  _is.ColumnValue<String, String> backgroundJson(String value) =>
      _is.ColumnValue(
        table.backgroundJson,
        value,
      );

  _is.ColumnValue<String, String> shapeStyleJson(String? value) =>
      _is.ColumnValue(
        table.shapeStyleJson,
        value,
      );

  _is.ColumnValue<String, String> tableStyleJson(String? value) =>
      _is.ColumnValue(
        table.tableStyleJson,
        value,
      );

  _is.ColumnValue<String, String> codeStyleJson(String? value) =>
      _is.ColumnValue(
        table.codeStyleJson,
        value,
      );

  _is.ColumnValue<String, String> chartStyleJson(String? value) =>
      _is.ColumnValue(
        table.chartStyleJson,
        value,
      );

  _is.ColumnValue<String, String> sortKey(String value) => _is.ColumnValue(
    table.sortKey,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DeckThemeTable extends _is.Table<_is.UuidValue> {
  DeckThemeTable({super.tableRelation}) : super(tableName: 'deck_theme') {
    updateTable = DeckThemeUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    deckId = _is.ColumnUuid(
      'deckId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    sourceKey = _is.ColumnString(
      'sourceKey',
      this,
    );
    colorsJson = _is.ColumnString(
      'colorsJson',
      this,
    );
    fontsJson = _is.ColumnString(
      'fontsJson',
      this,
    );
    textStylesJson = _is.ColumnString(
      'textStylesJson',
      this,
    );
    backgroundJson = _is.ColumnString(
      'backgroundJson',
      this,
    );
    shapeStyleJson = _is.ColumnString(
      'shapeStyleJson',
      this,
    );
    tableStyleJson = _is.ColumnString(
      'tableStyleJson',
      this,
    );
    codeStyleJson = _is.ColumnString(
      'codeStyleJson',
      this,
    );
    chartStyleJson = _is.ColumnString(
      'chartStyleJson',
      this,
    );
    sortKey = _is.ColumnString(
      'sortKey',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DeckThemeUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid deckId;

  _ilwyx5cu.DeckTable? _deck;

  late final _is.ColumnString name;

  /// Provenance: builtin:<key>@<v> | deck:<itemUuid>:<themeId> | null (created here).
  late final _is.ColumnString sourceKey;

  /// {light:{bg1,text1,...,accent1-6,link}, dark:{...}} (05 §2.2).
  late final _is.ColumnString colorsJson;

  /// {heading, body, mono, sizes?} (05 §2.3).
  late final _is.ColumnString fontsJson;

  /// Named text styles (05 §2.5).
  late final _is.ColumnString textStylesJson;

  /// Default background (05 §2.6).
  late final _is.ColumnString backgroundJson;

  /// Default fill/stroke/text of new shapes, lines, text boxes (05 §2.7).
  late final _is.ColumnString shapeStyleJson;

  /// Default table style (05 §2.8).
  late final _is.ColumnString tableStyleJson;

  /// Code palettes light/dark + chrome (05 §2.9, 07).
  late final _is.ColumnString codeStyleJson;

  /// Series palette order, fonts, gridlines (05 §2.10, 08).
  late final _is.ColumnString chartStyleJson;

  /// Order in the Themes panel (fractional index; ties by id).
  late final _is.ColumnString sortKey;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: DeckTheme.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _ilwyx5cu.DeckTable get deck {
    if (_deck != null) return _deck!;
    _deck = _is.createRelationTable(
      relationFieldName: 'deck',
      field: DeckTheme.t.deckId,
      foreignField: _ilwyx5cu.Deck.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ilwyx5cu.DeckTable(tableRelation: foreignTableRelation),
    );
    return _deck!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    deckId,
    name,
    sourceKey,
    colorsJson,
    fontsJson,
    textStylesJson,
    backgroundJson,
    shapeStyleJson,
    tableStyleJson,
    codeStyleJson,
    chartStyleJson,
    sortKey,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'deck') {
      return deck;
    }
    return null;
  }
}

class DeckThemeInclude extends _is.IncludeObject {
  DeckThemeInclude._({
    _imcki4bb.RevFileInclude? file,
    _ilwyx5cu.DeckInclude? deck,
  }) {
    _file = file;
    _deck = deck;
  }

  _imcki4bb.RevFileInclude? _file;

  _ilwyx5cu.DeckInclude? _deck;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'deck': _deck,
  };

  @override
  _is.Table<_is.UuidValue> get table => DeckTheme.t;
}

class DeckThemeIncludeList extends _is.IncludeList {
  DeckThemeIncludeList._({
    _is.WhereExpressionBuilder<DeckThemeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DeckTheme.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => DeckTheme.t;
}

class DeckThemeRepository {
  const DeckThemeRepository._();

  final attachRow = const DeckThemeAttachRowRepository._();

  /// Returns a list of [DeckTheme]s matching the given query parameters.
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
  Future<List<DeckTheme>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckThemeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckThemeTable>? orderBy,
    _is.OrderByListBuilder<DeckThemeTable>? orderByList,
    _is.Transaction? transaction,
    DeckThemeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DeckTheme>(
      where: where?.call(DeckTheme.t),
      orderBy: orderBy?.call(DeckTheme.t),
      orderByList: orderByList?.call(DeckTheme.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DeckTheme]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DeckTheme.t`.
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
  _ida.Stream<List<DeckTheme>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckThemeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckThemeTable>? orderBy,
    _is.OrderByListBuilder<DeckThemeTable>? orderByList,
    DeckThemeInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DeckTheme>(
      where: where?.call(DeckTheme.t),
      orderBy: orderBy?.call(DeckTheme.t),
      orderByList: orderByList?.call(DeckTheme.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DeckTheme] matching the given query parameters.
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
  Future<DeckTheme?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckThemeTable>? where,
    int? offset,
    _is.OrderByBuilder<DeckThemeTable>? orderBy,
    _is.OrderByListBuilder<DeckThemeTable>? orderByList,
    _is.Transaction? transaction,
    DeckThemeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DeckTheme>(
      where: where?.call(DeckTheme.t),
      orderBy: orderBy?.call(DeckTheme.t),
      orderByList: orderByList?.call(DeckTheme.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DeckTheme] by its [id] or null if no such row exists.
  Future<DeckTheme?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    DeckThemeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DeckTheme>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DeckTheme]s in the list and returns the inserted rows.
  ///
  /// The returned [DeckTheme]s will have their `id` fields set.
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
  Future<List<DeckTheme>> insert(
    _is.DatabaseSession session,
    List<DeckTheme> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DeckTheme>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DeckTheme] and returns the inserted row.
  ///
  /// The returned [DeckTheme] will have its `id` field set.
  Future<DeckTheme> insertRow(
    _is.DatabaseSession session,
    DeckTheme row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DeckTheme>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DeckTheme]s in the list and returns the resulting rows.
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
  /// The returned [DeckTheme]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeckTheme>> upsert(
    _is.DatabaseSession session,
    List<DeckTheme> rows, {
    required _is.ColumnSelections<DeckThemeTable> conflictColumns,
    _is.ColumnSelections<DeckThemeTable>? updateColumns,
    _is.WhereExpressionBuilder<DeckThemeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DeckTheme>(
      rows,
      conflictColumns: conflictColumns(DeckTheme.t),
      updateColumns: updateColumns?.call(DeckTheme.t),
      updateWhere: updateWhere?.call(DeckTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DeckTheme] and returns the resulting row.
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
  /// The returned [DeckTheme] will have its `id` field set.
  Future<DeckTheme?> upsertRow(
    _is.DatabaseSession session,
    DeckTheme row, {
    required _is.ColumnSelections<DeckThemeTable> conflictColumns,
    _is.ColumnSelections<DeckThemeTable>? updateColumns,
    _is.WhereExpressionBuilder<DeckThemeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DeckTheme>(
      row,
      conflictColumns: conflictColumns(DeckTheme.t),
      updateColumns: updateColumns?.call(DeckTheme.t),
      updateWhere: updateWhere?.call(DeckTheme.t),
      transaction: transaction,
    );
  }

  /// Updates all [DeckTheme]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeckTheme>> update(
    _is.DatabaseSession session,
    List<DeckTheme> rows, {
    _is.ColumnSelections<DeckThemeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DeckTheme>(
      rows,
      columns: columns?.call(DeckTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DeckTheme]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DeckTheme> updateRow(
    _is.DatabaseSession session,
    DeckTheme row, {
    _is.ColumnSelections<DeckThemeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DeckTheme>(
      row,
      columns: columns?.call(DeckTheme.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DeckTheme] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DeckTheme?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<DeckThemeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DeckTheme>(
      id,
      columnValues: columnValues(DeckTheme.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DeckTheme]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeckTheme>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DeckThemeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DeckThemeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckThemeTable>? orderBy,
    _is.OrderByListBuilder<DeckThemeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DeckTheme>(
      columnValues: columnValues(DeckTheme.t.updateTable),
      where: where(DeckTheme.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeckTheme.t),
      orderByList: orderByList?.call(DeckTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DeckTheme]s in the list and returns the deleted rows.
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
  Future<List<DeckTheme>> delete(
    _is.DatabaseSession session,
    List<DeckTheme> rows, {
    _is.OrderByBuilder<DeckThemeTable>? orderBy,
    _is.OrderByListBuilder<DeckThemeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DeckTheme>(
      rows,
      orderBy: orderBy?.call(DeckTheme.t),
      orderByList: orderByList?.call(DeckTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DeckTheme].
  Future<DeckTheme> deleteRow(
    _is.DatabaseSession session,
    DeckTheme row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DeckTheme>(
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
  Future<List<DeckTheme>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeckThemeTable> where,
    _is.OrderByBuilder<DeckThemeTable>? orderBy,
    _is.OrderByListBuilder<DeckThemeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DeckTheme>(
      where: where(DeckTheme.t),
      orderBy: orderBy?.call(DeckTheme.t),
      orderByList: orderByList?.call(DeckTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckThemeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DeckTheme>(
      where: where?.call(DeckTheme.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DeckTheme] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeckThemeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DeckTheme>(
      where: where(DeckTheme.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class DeckThemeAttachRowRepository {
  const DeckThemeAttachRowRepository._();

  /// Creates a relation between the given [DeckTheme] and [RevFile]
  /// by setting the [DeckTheme]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    DeckTheme deckTheme,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (deckTheme.id == null) {
      throw ArgumentError.notNull('deckTheme.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $deckTheme = deckTheme.copyWith(fileId: file.id);
    await session.db.updateRow<DeckTheme>(
      $deckTheme,
      columns: [DeckTheme.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [DeckTheme] and [Deck]
  /// by setting the [DeckTheme]'s foreign key `deckId` to refer to the [Deck].
  Future<void> deck(
    _is.DatabaseSession session,
    DeckTheme deckTheme,
    _ilwyx5cu.Deck deck, {
    _is.Transaction? transaction,
  }) async {
    if (deckTheme.id == null) {
      throw ArgumentError.notNull('deckTheme.id');
    }
    if (deck.id == null) {
      throw ArgumentError.notNull('deck.id');
    }

    var $deckTheme = deckTheme.copyWith(deckId: deck.id);
    await session.db.updateRow<DeckTheme>(
      $deckTheme,
      columns: [DeckTheme.t.deckId],
      transaction: transaction,
    );
  }
}
