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
import '../../../slides/models/rows/enums/deck_appearance.dart' as _i7xo28ze;
import '../../../slides/models/rows/enums/slide_size_preset.dart' as _ivxzn7up;

/// A presentation (Slides 02 §3.1). Its id is always the RevLog file uuid
/// and the UUID of its drive item (one deck per file, P1).
abstract class Deck
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  Deck._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.title,
    double? width,
    double? height,
    _ivxzn7up.SlideSizePreset? sizePreset,
    this.themeId,
    _i7xo28ze.DeckAppearance? appearance,
    this.language,
    bool? showSlideNumbers,
    bool? hideNumberOnTitle,
    int? firstSlideNumber,
    this.footerText,
    this.defaultsJson,
    this.guidesJson,
    this.presentJson,
    required this.createdBy,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       width = width ?? 1920.0,
       height = height ?? 1080.0,
       sizePreset = sizePreset ?? _ivxzn7up.SlideSizePreset.widescreen16x9,
       appearance = appearance ?? _i7xo28ze.DeckAppearance.light,
       showSlideNumbers = showSlideNumbers ?? false,
       hideNumberOnTitle = hideNumberOnTitle ?? true,
       firstSlideNumber = firstSlideNumber ?? 1,
       createdAt = createdAt ?? DateTime.now();

  factory Deck({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required String title,
    double? width,
    double? height,
    _ivxzn7up.SlideSizePreset? sizePreset,
    _is.UuidValue? themeId,
    _i7xo28ze.DeckAppearance? appearance,
    String? language,
    bool? showSlideNumbers,
    bool? hideNumberOnTitle,
    int? firstSlideNumber,
    String? footerText,
    String? defaultsJson,
    String? guidesJson,
    String? presentJson,
    required _is.UuidValue createdBy,
    DateTime? createdAt,
  }) = _DeckImpl;

  factory Deck.fromJson(Map<String, dynamic> jsonSerialization) {
    return Deck(
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
      title: jsonSerialization['title'] as String,
      width: (jsonSerialization['width'] as num?)?.toDouble(),
      height: (jsonSerialization['height'] as num?)?.toDouble(),
      sizePreset: jsonSerialization['sizePreset'] == null
          ? null
          : _ivxzn7up.SlideSizePreset.fromJson(
              (jsonSerialization['sizePreset'] as String),
            ),
      themeId: jsonSerialization['themeId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['themeId']),
      appearance: jsonSerialization['appearance'] == null
          ? null
          : _i7xo28ze.DeckAppearance.fromJson(
              (jsonSerialization['appearance'] as String),
            ),
      language: jsonSerialization['language'] as String?,
      showSlideNumbers: jsonSerialization['showSlideNumbers'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['showSlideNumbers'],
            ),
      hideNumberOnTitle: jsonSerialization['hideNumberOnTitle'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['hideNumberOnTitle'],
            ),
      firstSlideNumber: jsonSerialization['firstSlideNumber'] as int?,
      footerText: jsonSerialization['footerText'] as String?,
      defaultsJson: jsonSerialization['defaultsJson'] as String?,
      guidesJson: jsonSerialization['guidesJson'] as String?,
      presentJson: jsonSerialization['presentJson'] as String?,
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = DeckTable();

  static const db = DeckRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  /// Mirrored to DriveItem.name by the server (both ways).
  String title;

  /// Design size in slide units (su); 1920 x 1080 for 16:9 (02 §2.2).
  double width;

  double height;

  _ivxzn7up.SlideSizePreset sizePreset;

  /// Default DeckTheme for new slides (same space; plain UUID, not an FK).
  /// Missing = the theme with the smallest id (02 §10).
  _is.UuidValue? themeId;

  /// Which color scheme of the themes is used (05 §2.4).
  _i7xo28ze.DeckAppearance appearance;

  /// BCP-47 for spelling / hyphenation; null = the user's locale.
  String? language;

  /// Master slide-number placeholders visible.
  bool showSlideNumbers;

  /// No number on slides whose layout key is `title`.
  bool hideNumberOnTitle;

  int firstSlideNumber;

  /// Master footer placeholders' text; null = hidden.
  String? footerText;

  /// {transition, build, codeFontSize, ...}; keys owned by 06/07 (A-06-7).
  String? defaultsJson;

  /// User guides [{"axis":"v"|"h","at":<su>}], whole-value LWW (03 A-03-1).
  String? guidesJson;

  /// Presenting options (10 A-10-1, schema 10 §3); null = defaults.
  String? presentJson;

  /// Auth user UUID of the creator.
  _is.UuidValue createdBy;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [Deck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Deck copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDeck$file(),
    int? revision,
    String? title,
    double? width,
    double? height,
    _ivxzn7up.SlideSizePreset? sizePreset,
    _is.UuidValue? themeId = const _is.$UndefinedUuidValue(),
    _i7xo28ze.DeckAppearance? appearance,
    String? language,
    bool? showSlideNumbers,
    bool? hideNumberOnTitle,
    int? firstSlideNumber,
    String? footerText,
    String? defaultsJson,
    String? guidesJson,
    String? presentJson,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Deck',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'title': title,
      'width': width,
      'height': height,
      'sizePreset': sizePreset.toJson(),
      if (themeId != null) 'themeId': themeId?.toJson(),
      'appearance': appearance.toJson(),
      if (language != null) 'language': language,
      'showSlideNumbers': showSlideNumbers,
      'hideNumberOnTitle': hideNumberOnTitle,
      'firstSlideNumber': firstSlideNumber,
      if (footerText != null) 'footerText': footerText,
      if (defaultsJson != null) 'defaultsJson': defaultsJson,
      if (guidesJson != null) 'guidesJson': guidesJson,
      if (presentJson != null) 'presentJson': presentJson,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DeckInclude include({_imcki4bb.RevFileInclude? file}) {
    return DeckInclude._(file: file);
  }

  static DeckIncludeList includeList({
    _is.WhereExpressionBuilder<DeckTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckTable>? orderBy,
    _is.OrderByListBuilder<DeckTable>? orderByList,
    DeckInclude? include,
  }) {
    return DeckIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Deck.t),
      orderByList: orderByList?.call(Deck.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedDeck$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedDeck$file();
}

class _DeckImpl extends Deck {
  _DeckImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required String title,
    double? width,
    double? height,
    _ivxzn7up.SlideSizePreset? sizePreset,
    _is.UuidValue? themeId,
    _i7xo28ze.DeckAppearance? appearance,
    String? language,
    bool? showSlideNumbers,
    bool? hideNumberOnTitle,
    int? firstSlideNumber,
    String? footerText,
    String? defaultsJson,
    String? guidesJson,
    String? presentJson,
    required _is.UuidValue createdBy,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         title: title,
         width: width,
         height: height,
         sizePreset: sizePreset,
         themeId: themeId,
         appearance: appearance,
         language: language,
         showSlideNumbers: showSlideNumbers,
         hideNumberOnTitle: hideNumberOnTitle,
         firstSlideNumber: firstSlideNumber,
         footerText: footerText,
         defaultsJson: defaultsJson,
         guidesJson: guidesJson,
         presentJson: presentJson,
         createdBy: createdBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Deck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Deck copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDeck$file(),
    int? revision,
    String? title,
    double? width,
    double? height,
    _ivxzn7up.SlideSizePreset? sizePreset,
    _is.UuidValue? themeId = const _is.$UndefinedUuidValue(),
    _i7xo28ze.DeckAppearance? appearance,
    Object? language = _Undefined,
    bool? showSlideNumbers,
    bool? hideNumberOnTitle,
    int? firstSlideNumber,
    Object? footerText = _Undefined,
    Object? defaultsJson = _Undefined,
    Object? guidesJson = _Undefined,
    Object? presentJson = _Undefined,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  }) {
    return Deck(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      title: title ?? this.title,
      width: width ?? this.width,
      height: height ?? this.height,
      sizePreset: sizePreset ?? this.sizePreset,
      themeId: themeId is _is.UndefinedSentinel ? this.themeId : themeId,
      appearance: appearance ?? this.appearance,
      language: language is String? ? language : this.language,
      showSlideNumbers: showSlideNumbers ?? this.showSlideNumbers,
      hideNumberOnTitle: hideNumberOnTitle ?? this.hideNumberOnTitle,
      firstSlideNumber: firstSlideNumber ?? this.firstSlideNumber,
      footerText: footerText is String? ? footerText : this.footerText,
      defaultsJson: defaultsJson is String? ? defaultsJson : this.defaultsJson,
      guidesJson: guidesJson is String? ? guidesJson : this.guidesJson,
      presentJson: presentJson is String? ? presentJson : this.presentJson,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DeckUpdateTable extends _is.UpdateTable<DeckTable> {
  DeckUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<double, double> width(double value) => _is.ColumnValue(
    table.width,
    value,
  );

  _is.ColumnValue<double, double> height(double value) => _is.ColumnValue(
    table.height,
    value,
  );

  _is.ColumnValue<_ivxzn7up.SlideSizePreset, _ivxzn7up.SlideSizePreset>
  sizePreset(_ivxzn7up.SlideSizePreset value) => _is.ColumnValue(
    table.sizePreset,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> themeId(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.themeId,
        value,
      );

  _is.ColumnValue<_i7xo28ze.DeckAppearance, _i7xo28ze.DeckAppearance>
  appearance(_i7xo28ze.DeckAppearance value) => _is.ColumnValue(
    table.appearance,
    value,
  );

  _is.ColumnValue<String, String> language(String? value) => _is.ColumnValue(
    table.language,
    value,
  );

  _is.ColumnValue<bool, bool> showSlideNumbers(bool value) => _is.ColumnValue(
    table.showSlideNumbers,
    value,
  );

  _is.ColumnValue<bool, bool> hideNumberOnTitle(bool value) => _is.ColumnValue(
    table.hideNumberOnTitle,
    value,
  );

  _is.ColumnValue<int, int> firstSlideNumber(int value) => _is.ColumnValue(
    table.firstSlideNumber,
    value,
  );

  _is.ColumnValue<String, String> footerText(String? value) => _is.ColumnValue(
    table.footerText,
    value,
  );

  _is.ColumnValue<String, String> defaultsJson(String? value) =>
      _is.ColumnValue(
        table.defaultsJson,
        value,
      );

  _is.ColumnValue<String, String> guidesJson(String? value) => _is.ColumnValue(
    table.guidesJson,
    value,
  );

  _is.ColumnValue<String, String> presentJson(String? value) => _is.ColumnValue(
    table.presentJson,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> createdBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.createdBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DeckTable extends _is.Table<_is.UuidValue> {
  DeckTable({super.tableRelation}) : super(tableName: 'deck') {
    updateTable = DeckUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    width = _is.ColumnDouble(
      'width',
      this,
      hasDefault: true,
    );
    height = _is.ColumnDouble(
      'height',
      this,
      hasDefault: true,
    );
    sizePreset = _is.ColumnEnum(
      'sizePreset',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    themeId = _is.ColumnUuid(
      'themeId',
      this,
    );
    appearance = _is.ColumnEnum(
      'appearance',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    language = _is.ColumnString(
      'language',
      this,
    );
    showSlideNumbers = _is.ColumnBool(
      'showSlideNumbers',
      this,
      hasDefault: true,
    );
    hideNumberOnTitle = _is.ColumnBool(
      'hideNumberOnTitle',
      this,
      hasDefault: true,
    );
    firstSlideNumber = _is.ColumnInt(
      'firstSlideNumber',
      this,
      hasDefault: true,
    );
    footerText = _is.ColumnString(
      'footerText',
      this,
    );
    defaultsJson = _is.ColumnString(
      'defaultsJson',
      this,
    );
    guidesJson = _is.ColumnString(
      'guidesJson',
      this,
    );
    presentJson = _is.ColumnString(
      'presentJson',
      this,
    );
    createdBy = _is.ColumnUuid(
      'createdBy',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DeckUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  /// Mirrored to DriveItem.name by the server (both ways).
  late final _is.ColumnString title;

  /// Design size in slide units (su); 1920 x 1080 for 16:9 (02 §2.2).
  late final _is.ColumnDouble width;

  late final _is.ColumnDouble height;

  late final _is.ColumnEnum<_ivxzn7up.SlideSizePreset> sizePreset;

  /// Default DeckTheme for new slides (same space; plain UUID, not an FK).
  /// Missing = the theme with the smallest id (02 §10).
  late final _is.ColumnUuid themeId;

  /// Which color scheme of the themes is used (05 §2.4).
  late final _is.ColumnEnum<_i7xo28ze.DeckAppearance> appearance;

  /// BCP-47 for spelling / hyphenation; null = the user's locale.
  late final _is.ColumnString language;

  /// Master slide-number placeholders visible.
  late final _is.ColumnBool showSlideNumbers;

  /// No number on slides whose layout key is `title`.
  late final _is.ColumnBool hideNumberOnTitle;

  late final _is.ColumnInt firstSlideNumber;

  /// Master footer placeholders' text; null = hidden.
  late final _is.ColumnString footerText;

  /// {transition, build, codeFontSize, ...}; keys owned by 06/07 (A-06-7).
  late final _is.ColumnString defaultsJson;

  /// User guides [{"axis":"v"|"h","at":<su>}], whole-value LWW (03 A-03-1).
  late final _is.ColumnString guidesJson;

  /// Presenting options (10 A-10-1, schema 10 §3); null = defaults.
  late final _is.ColumnString presentJson;

  /// Auth user UUID of the creator.
  late final _is.ColumnUuid createdBy;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: Deck.t.fileId,
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
    title,
    width,
    height,
    sizePreset,
    themeId,
    appearance,
    language,
    showSlideNumbers,
    hideNumberOnTitle,
    firstSlideNumber,
    footerText,
    defaultsJson,
    guidesJson,
    presentJson,
    createdBy,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    return null;
  }
}

class DeckInclude extends _is.IncludeObject {
  DeckInclude._({_imcki4bb.RevFileInclude? file}) {
    _file = file;
  }

  _imcki4bb.RevFileInclude? _file;

  @override
  Map<String, _is.Include?> get includes => {'file': _file};

  @override
  _is.Table<_is.UuidValue> get table => Deck.t;
}

class DeckIncludeList extends _is.IncludeList {
  DeckIncludeList._({
    _is.WhereExpressionBuilder<DeckTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Deck.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => Deck.t;
}

class DeckRepository {
  const DeckRepository._();

  final attachRow = const DeckAttachRowRepository._();

  /// Returns a list of [Deck]s matching the given query parameters.
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
  Future<List<Deck>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckTable>? orderBy,
    _is.OrderByListBuilder<DeckTable>? orderByList,
    _is.Transaction? transaction,
    DeckInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Deck>(
      where: where?.call(Deck.t),
      orderBy: orderBy?.call(Deck.t),
      orderByList: orderByList?.call(Deck.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Deck]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Deck.t`.
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
  _ida.Stream<List<Deck>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckTable>? orderBy,
    _is.OrderByListBuilder<DeckTable>? orderByList,
    DeckInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Deck>(
      where: where?.call(Deck.t),
      orderBy: orderBy?.call(Deck.t),
      orderByList: orderByList?.call(Deck.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Deck] matching the given query parameters.
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
  Future<Deck?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckTable>? where,
    int? offset,
    _is.OrderByBuilder<DeckTable>? orderBy,
    _is.OrderByListBuilder<DeckTable>? orderByList,
    _is.Transaction? transaction,
    DeckInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Deck>(
      where: where?.call(Deck.t),
      orderBy: orderBy?.call(Deck.t),
      orderByList: orderByList?.call(Deck.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Deck] by its [id] or null if no such row exists.
  Future<Deck?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    DeckInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Deck>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Deck]s in the list and returns the inserted rows.
  ///
  /// The returned [Deck]s will have their `id` fields set.
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
  Future<List<Deck>> insert(
    _is.DatabaseSession session,
    List<Deck> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Deck>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Deck] and returns the inserted row.
  ///
  /// The returned [Deck] will have its `id` field set.
  Future<Deck> insertRow(
    _is.DatabaseSession session,
    Deck row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Deck>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Deck]s in the list and returns the resulting rows.
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
  /// The returned [Deck]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Deck>> upsert(
    _is.DatabaseSession session,
    List<Deck> rows, {
    required _is.ColumnSelections<DeckTable> conflictColumns,
    _is.ColumnSelections<DeckTable>? updateColumns,
    _is.WhereExpressionBuilder<DeckTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Deck>(
      rows,
      conflictColumns: conflictColumns(Deck.t),
      updateColumns: updateColumns?.call(Deck.t),
      updateWhere: updateWhere?.call(Deck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Deck] and returns the resulting row.
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
  /// The returned [Deck] will have its `id` field set.
  Future<Deck?> upsertRow(
    _is.DatabaseSession session,
    Deck row, {
    required _is.ColumnSelections<DeckTable> conflictColumns,
    _is.ColumnSelections<DeckTable>? updateColumns,
    _is.WhereExpressionBuilder<DeckTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Deck>(
      row,
      conflictColumns: conflictColumns(Deck.t),
      updateColumns: updateColumns?.call(Deck.t),
      updateWhere: updateWhere?.call(Deck.t),
      transaction: transaction,
    );
  }

  /// Updates all [Deck]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Deck>> update(
    _is.DatabaseSession session,
    List<Deck> rows, {
    _is.ColumnSelections<DeckTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Deck>(
      rows,
      columns: columns?.call(Deck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Deck]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Deck> updateRow(
    _is.DatabaseSession session,
    Deck row, {
    _is.ColumnSelections<DeckTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Deck>(
      row,
      columns: columns?.call(Deck.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Deck] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Deck?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<DeckUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Deck>(
      id,
      columnValues: columnValues(Deck.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Deck]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Deck>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DeckUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DeckTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeckTable>? orderBy,
    _is.OrderByListBuilder<DeckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Deck>(
      columnValues: columnValues(Deck.t.updateTable),
      where: where(Deck.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Deck.t),
      orderByList: orderByList?.call(Deck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Deck]s in the list and returns the deleted rows.
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
  Future<List<Deck>> delete(
    _is.DatabaseSession session,
    List<Deck> rows, {
    _is.OrderByBuilder<DeckTable>? orderBy,
    _is.OrderByListBuilder<DeckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Deck>(
      rows,
      orderBy: orderBy?.call(Deck.t),
      orderByList: orderByList?.call(Deck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Deck].
  Future<Deck> deleteRow(
    _is.DatabaseSession session,
    Deck row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Deck>(
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
  Future<List<Deck>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeckTable> where,
    _is.OrderByBuilder<DeckTable>? orderBy,
    _is.OrderByListBuilder<DeckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Deck>(
      where: where(Deck.t),
      orderBy: orderBy?.call(Deck.t),
      orderByList: orderByList?.call(Deck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeckTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Deck>(
      where: where?.call(Deck.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Deck] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeckTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Deck>(
      where: where(Deck.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class DeckAttachRowRepository {
  const DeckAttachRowRepository._();

  /// Creates a relation between the given [Deck] and [RevFile]
  /// by setting the [Deck]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    Deck deck,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (deck.id == null) {
      throw ArgumentError.notNull('deck.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $deck = deck.copyWith(fileId: file.id);
    await session.db.updateRow<Deck>(
      $deck,
      columns: [Deck.t.fileId],
      transaction: transaction,
    );
  }
}
