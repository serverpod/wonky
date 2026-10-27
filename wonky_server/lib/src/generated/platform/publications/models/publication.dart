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
import '../../../platform/publications/models/publication_fields.dart'
    as _i1a71r29;

/// A destination that takes stories from Wonky Write (specs/18 §2, §6),
/// owned by one user (the blog owner). Holds the signing secret, so it
/// never leaves the server; clients see [PublicationSettings] and
/// [PublicationCard].
abstract class Publication
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Publication._({
    this.id,
    required this.publicId,
    required this.ownerId,
    required this.name,
    required this.siteUrl,
    required this.webhookUrl,
    this.verifiedHost,
    this.verifiedAt,
    this.templateItemId,
    this.termsUrl,
    required this.fields,
    String? markdownFlavor,
    required this.signingSecret,
    this.previousSigningSecret,
    this.previousSecretUntil,
    this.apiKeyHash,
    this.apiKeyLast4,
    bool? enabled,
    required this.createdAt,
    required this.updatedAt,
  }) : markdownFlavor = markdownFlavor ?? 'gfm',
       enabled = enabled ?? true;

  factory Publication({
    int? id,
    required String publicId,
    required int ownerId,
    required String name,
    required String siteUrl,
    required String webhookUrl,
    String? verifiedHost,
    DateTime? verifiedAt,
    int? templateItemId,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    String? markdownFlavor,
    required String signingSecret,
    String? previousSigningSecret,
    DateTime? previousSecretUntil,
    String? apiKeyHash,
    String? apiKeyLast4,
    bool? enabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PublicationImpl;

  factory Publication.fromJson(Map<String, dynamic> jsonSerialization) {
    return Publication(
      id: jsonSerialization['id'] as int?,
      publicId: jsonSerialization['publicId'] as String,
      ownerId: jsonSerialization['ownerId'] as int,
      name: jsonSerialization['name'] as String,
      siteUrl: jsonSerialization['siteUrl'] as String,
      webhookUrl: jsonSerialization['webhookUrl'] as String,
      verifiedHost: jsonSerialization['verifiedHost'] as String?,
      verifiedAt: jsonSerialization['verifiedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['verifiedAt']),
      templateItemId: jsonSerialization['templateItemId'] as int?,
      termsUrl: jsonSerialization['termsUrl'] as String?,
      fields: _il4umwa0.Protocol().deserialize<_i1a71r29.PublicationFields>(
        jsonSerialization['fields'],
      ),
      markdownFlavor: jsonSerialization['markdownFlavor'] as String?,
      signingSecret: jsonSerialization['signingSecret'] as String,
      previousSigningSecret:
          jsonSerialization['previousSigningSecret'] as String?,
      previousSecretUntil: jsonSerialization['previousSecretUntil'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['previousSecretUntil'],
            ),
      apiKeyHash: jsonSerialization['apiKeyHash'] as String?,
      apiKeyLast4: jsonSerialization['apiKeyLast4'] as String?,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = PublicationTable();

  static const db = PublicationRepository._();

  @override
  int? id;

  /// "pub_" + 22 url-safe characters; in contributor links, not a secret.
  String publicId;

  int ownerId;

  String name;

  /// https origin of the blog (`https://blog.example.com`).
  String siteUrl;

  /// https URL the webhooks go to.
  String webhookUrl;

  /// The site host proven by `/.well-known/wonky-publications.json`
  /// (specs/18 §8.2); null = unverified.
  String? verifiedHost;

  DateTime? verifiedAt;

  /// The owner's Write document new stories start from.
  int? templateItemId;

  String? termsUrl;

  _i1a71r29.PublicationFields fields;

  /// Markdown flavor of new stories and submissions: `gfm` or `wonky`
  /// (Write 11 §3.3).
  String markdownFlavor;

  /// "whsec_" + base64 key; must be kept in plain to sign (specs/13 §2).
  String signingSecret;

  /// The previous secret signs too until [previousSecretUntil] (rotation).
  String? previousSigningSecret;

  DateTime? previousSecretUntil;

  /// SHA-256 (hex) of the API key "wpk_…", shown once.
  String? apiKeyHash;

  String? apiKeyLast4;

  bool enabled;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Publication]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Publication copyWith({
    int? id,
    String? publicId,
    int? ownerId,
    String? name,
    String? siteUrl,
    String? webhookUrl,
    String? verifiedHost,
    DateTime? verifiedAt = const _is.$UndefinedDateTime(),
    int? templateItemId,
    String? termsUrl,
    _i1a71r29.PublicationFields? fields,
    String? markdownFlavor,
    String? signingSecret,
    String? previousSigningSecret,
    DateTime? previousSecretUntil = const _is.$UndefinedDateTime(),
    String? apiKeyHash,
    String? apiKeyLast4,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Publication',
      if (id != null) 'id': id,
      'publicId': publicId,
      'ownerId': ownerId,
      'name': name,
      'siteUrl': siteUrl,
      'webhookUrl': webhookUrl,
      if (verifiedHost != null) 'verifiedHost': verifiedHost,
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
      if (templateItemId != null) 'templateItemId': templateItemId,
      if (termsUrl != null) 'termsUrl': termsUrl,
      'fields': fields.toJson(),
      'markdownFlavor': markdownFlavor,
      'signingSecret': signingSecret,
      if (previousSigningSecret != null)
        'previousSigningSecret': previousSigningSecret,
      if (previousSecretUntil != null)
        'previousSecretUntil': previousSecretUntil?.toJson(),
      if (apiKeyHash != null) 'apiKeyHash': apiKeyHash,
      if (apiKeyLast4 != null) 'apiKeyLast4': apiKeyLast4,
      'enabled': enabled,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PublicationInclude include() {
    return PublicationInclude._();
  }

  static PublicationIncludeList includeList({
    _is.WhereExpressionBuilder<PublicationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationTable>? orderBy,
    _is.OrderByListBuilder<PublicationTable>? orderByList,
    PublicationInclude? include,
  }) {
    return PublicationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Publication.t),
      orderByList: orderByList?.call(Publication.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationImpl extends Publication {
  _PublicationImpl({
    int? id,
    required String publicId,
    required int ownerId,
    required String name,
    required String siteUrl,
    required String webhookUrl,
    String? verifiedHost,
    DateTime? verifiedAt,
    int? templateItemId,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    String? markdownFlavor,
    required String signingSecret,
    String? previousSigningSecret,
    DateTime? previousSecretUntil,
    String? apiKeyHash,
    String? apiKeyLast4,
    bool? enabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         publicId: publicId,
         ownerId: ownerId,
         name: name,
         siteUrl: siteUrl,
         webhookUrl: webhookUrl,
         verifiedHost: verifiedHost,
         verifiedAt: verifiedAt,
         templateItemId: templateItemId,
         termsUrl: termsUrl,
         fields: fields,
         markdownFlavor: markdownFlavor,
         signingSecret: signingSecret,
         previousSigningSecret: previousSigningSecret,
         previousSecretUntil: previousSecretUntil,
         apiKeyHash: apiKeyHash,
         apiKeyLast4: apiKeyLast4,
         enabled: enabled,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Publication]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Publication copyWith({
    Object? id = _Undefined,
    String? publicId,
    int? ownerId,
    String? name,
    String? siteUrl,
    String? webhookUrl,
    Object? verifiedHost = _Undefined,
    DateTime? verifiedAt = const _is.$UndefinedDateTime(),
    Object? templateItemId = _Undefined,
    Object? termsUrl = _Undefined,
    _i1a71r29.PublicationFields? fields,
    String? markdownFlavor,
    String? signingSecret,
    Object? previousSigningSecret = _Undefined,
    DateTime? previousSecretUntil = const _is.$UndefinedDateTime(),
    Object? apiKeyHash = _Undefined,
    Object? apiKeyLast4 = _Undefined,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Publication(
      id: id is int? ? id : this.id,
      publicId: publicId ?? this.publicId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      siteUrl: siteUrl ?? this.siteUrl,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      verifiedHost: verifiedHost is String? ? verifiedHost : this.verifiedHost,
      verifiedAt: verifiedAt is _is.UndefinedSentinel
          ? this.verifiedAt
          : verifiedAt,
      templateItemId: templateItemId is int?
          ? templateItemId
          : this.templateItemId,
      termsUrl: termsUrl is String? ? termsUrl : this.termsUrl,
      fields: fields ?? this.fields.copyWith(),
      markdownFlavor: markdownFlavor ?? this.markdownFlavor,
      signingSecret: signingSecret ?? this.signingSecret,
      previousSigningSecret: previousSigningSecret is String?
          ? previousSigningSecret
          : this.previousSigningSecret,
      previousSecretUntil: previousSecretUntil is _is.UndefinedSentinel
          ? this.previousSecretUntil
          : previousSecretUntil,
      apiKeyHash: apiKeyHash is String? ? apiKeyHash : this.apiKeyHash,
      apiKeyLast4: apiKeyLast4 is String? ? apiKeyLast4 : this.apiKeyLast4,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PublicationUpdateTable extends _is.UpdateTable<PublicationTable> {
  PublicationUpdateTable(super.table);

  _is.ColumnValue<String, String> publicId(String value) => _is.ColumnValue(
    table.publicId,
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

  _is.ColumnValue<String, String> siteUrl(String value) => _is.ColumnValue(
    table.siteUrl,
    value,
  );

  _is.ColumnValue<String, String> webhookUrl(String value) => _is.ColumnValue(
    table.webhookUrl,
    value,
  );

  _is.ColumnValue<String, String> verifiedHost(String? value) =>
      _is.ColumnValue(
        table.verifiedHost,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> verifiedAt(DateTime? value) =>
      _is.ColumnValue(
        table.verifiedAt,
        value,
      );

  _is.ColumnValue<int, int> templateItemId(int? value) => _is.ColumnValue(
    table.templateItemId,
    value,
  );

  _is.ColumnValue<String, String> termsUrl(String? value) => _is.ColumnValue(
    table.termsUrl,
    value,
  );

  _is.ColumnValue<_i1a71r29.PublicationFields, _i1a71r29.PublicationFields>
  fields(_i1a71r29.PublicationFields value) => _is.ColumnValue(
    table.fields,
    value,
  );

  _is.ColumnValue<String, String> markdownFlavor(String value) =>
      _is.ColumnValue(
        table.markdownFlavor,
        value,
      );

  _is.ColumnValue<String, String> signingSecret(String value) =>
      _is.ColumnValue(
        table.signingSecret,
        value,
      );

  _is.ColumnValue<String, String> previousSigningSecret(String? value) =>
      _is.ColumnValue(
        table.previousSigningSecret,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> previousSecretUntil(DateTime? value) =>
      _is.ColumnValue(
        table.previousSecretUntil,
        value,
      );

  _is.ColumnValue<String, String> apiKeyHash(String? value) => _is.ColumnValue(
    table.apiKeyHash,
    value,
  );

  _is.ColumnValue<String, String> apiKeyLast4(String? value) => _is.ColumnValue(
    table.apiKeyLast4,
    value,
  );

  _is.ColumnValue<bool, bool> enabled(bool value) => _is.ColumnValue(
    table.enabled,
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

class PublicationTable extends _is.Table<int?> {
  PublicationTable({super.tableRelation}) : super(tableName: 'publication') {
    updateTable = PublicationUpdateTable(this);
    publicId = _is.ColumnString(
      'publicId',
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
    siteUrl = _is.ColumnString(
      'siteUrl',
      this,
    );
    webhookUrl = _is.ColumnString(
      'webhookUrl',
      this,
    );
    verifiedHost = _is.ColumnString(
      'verifiedHost',
      this,
    );
    verifiedAt = _is.ColumnDateTime(
      'verifiedAt',
      this,
    );
    templateItemId = _is.ColumnInt(
      'templateItemId',
      this,
    );
    termsUrl = _is.ColumnString(
      'termsUrl',
      this,
    );
    fields = _is.ColumnSerializable<_i1a71r29.PublicationFields>(
      'fields',
      this,
    );
    markdownFlavor = _is.ColumnString(
      'markdownFlavor',
      this,
      hasDefault: true,
    );
    signingSecret = _is.ColumnString(
      'signingSecret',
      this,
    );
    previousSigningSecret = _is.ColumnString(
      'previousSigningSecret',
      this,
    );
    previousSecretUntil = _is.ColumnDateTime(
      'previousSecretUntil',
      this,
    );
    apiKeyHash = _is.ColumnString(
      'apiKeyHash',
      this,
    );
    apiKeyLast4 = _is.ColumnString(
      'apiKeyLast4',
      this,
    );
    enabled = _is.ColumnBool(
      'enabled',
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

  late final PublicationUpdateTable updateTable;

  /// "pub_" + 22 url-safe characters; in contributor links, not a secret.
  late final _is.ColumnString publicId;

  late final _is.ColumnInt ownerId;

  late final _is.ColumnString name;

  /// https origin of the blog (`https://blog.example.com`).
  late final _is.ColumnString siteUrl;

  /// https URL the webhooks go to.
  late final _is.ColumnString webhookUrl;

  /// The site host proven by `/.well-known/wonky-publications.json`
  /// (specs/18 §8.2); null = unverified.
  late final _is.ColumnString verifiedHost;

  late final _is.ColumnDateTime verifiedAt;

  /// The owner's Write document new stories start from.
  late final _is.ColumnInt templateItemId;

  late final _is.ColumnString termsUrl;

  late final _is.ColumnSerializable<_i1a71r29.PublicationFields> fields;

  /// Markdown flavor of new stories and submissions: `gfm` or `wonky`
  /// (Write 11 §3.3).
  late final _is.ColumnString markdownFlavor;

  /// "whsec_" + base64 key; must be kept in plain to sign (specs/13 §2).
  late final _is.ColumnString signingSecret;

  /// The previous secret signs too until [previousSecretUntil] (rotation).
  late final _is.ColumnString previousSigningSecret;

  late final _is.ColumnDateTime previousSecretUntil;

  /// SHA-256 (hex) of the API key "wpk_…", shown once.
  late final _is.ColumnString apiKeyHash;

  late final _is.ColumnString apiKeyLast4;

  late final _is.ColumnBool enabled;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    publicId,
    ownerId,
    name,
    siteUrl,
    webhookUrl,
    verifiedHost,
    verifiedAt,
    templateItemId,
    termsUrl,
    fields,
    markdownFlavor,
    signingSecret,
    previousSigningSecret,
    previousSecretUntil,
    apiKeyHash,
    apiKeyLast4,
    enabled,
    createdAt,
    updatedAt,
  ];
}

class PublicationInclude extends _is.IncludeObject {
  PublicationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Publication.t;
}

class PublicationIncludeList extends _is.IncludeList {
  PublicationIncludeList._({
    _is.WhereExpressionBuilder<PublicationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Publication.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Publication.t;
}

class PublicationRepository {
  const PublicationRepository._();

  /// Returns a list of [Publication]s matching the given query parameters.
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
  Future<List<Publication>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationTable>? orderBy,
    _is.OrderByListBuilder<PublicationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Publication>(
      where: where?.call(Publication.t),
      orderBy: orderBy?.call(Publication.t),
      orderByList: orderByList?.call(Publication.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Publication]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Publication.t`.
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
  _ida.Stream<List<Publication>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationTable>? orderBy,
    _is.OrderByListBuilder<PublicationTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Publication>(
      where: where?.call(Publication.t),
      orderBy: orderBy?.call(Publication.t),
      orderByList: orderByList?.call(Publication.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Publication] matching the given query parameters.
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
  Future<Publication?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationTable>? where,
    int? offset,
    _is.OrderByBuilder<PublicationTable>? orderBy,
    _is.OrderByListBuilder<PublicationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Publication>(
      where: where?.call(Publication.t),
      orderBy: orderBy?.call(Publication.t),
      orderByList: orderByList?.call(Publication.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Publication] by its [id] or null if no such row exists.
  Future<Publication?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Publication>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Publication]s in the list and returns the inserted rows.
  ///
  /// The returned [Publication]s will have their `id` fields set.
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
  Future<List<Publication>> insert(
    _is.DatabaseSession session,
    List<Publication> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Publication>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Publication] and returns the inserted row.
  ///
  /// The returned [Publication] will have its `id` field set.
  Future<Publication> insertRow(
    _is.DatabaseSession session,
    Publication row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Publication>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Publication]s in the list and returns the resulting rows.
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
  /// The returned [Publication]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Publication>> upsert(
    _is.DatabaseSession session,
    List<Publication> rows, {
    required _is.ColumnSelections<PublicationTable> conflictColumns,
    _is.ColumnSelections<PublicationTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Publication>(
      rows,
      conflictColumns: conflictColumns(Publication.t),
      updateColumns: updateColumns?.call(Publication.t),
      updateWhere: updateWhere?.call(Publication.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Publication] and returns the resulting row.
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
  /// The returned [Publication] will have its `id` field set.
  Future<Publication?> upsertRow(
    _is.DatabaseSession session,
    Publication row, {
    required _is.ColumnSelections<PublicationTable> conflictColumns,
    _is.ColumnSelections<PublicationTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Publication>(
      row,
      conflictColumns: conflictColumns(Publication.t),
      updateColumns: updateColumns?.call(Publication.t),
      updateWhere: updateWhere?.call(Publication.t),
      transaction: transaction,
    );
  }

  /// Updates all [Publication]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Publication>> update(
    _is.DatabaseSession session,
    List<Publication> rows, {
    _is.ColumnSelections<PublicationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Publication>(
      rows,
      columns: columns?.call(Publication.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Publication]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Publication> updateRow(
    _is.DatabaseSession session,
    Publication row, {
    _is.ColumnSelections<PublicationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Publication>(
      row,
      columns: columns?.call(Publication.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Publication] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Publication?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PublicationUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Publication>(
      id,
      columnValues: columnValues(Publication.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Publication]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Publication>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PublicationUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PublicationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationTable>? orderBy,
    _is.OrderByListBuilder<PublicationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Publication>(
      columnValues: columnValues(Publication.t.updateTable),
      where: where(Publication.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Publication.t),
      orderByList: orderByList?.call(Publication.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Publication]s in the list and returns the deleted rows.
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
  Future<List<Publication>> delete(
    _is.DatabaseSession session,
    List<Publication> rows, {
    _is.OrderByBuilder<PublicationTable>? orderBy,
    _is.OrderByListBuilder<PublicationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Publication>(
      rows,
      orderBy: orderBy?.call(Publication.t),
      orderByList: orderByList?.call(Publication.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Publication].
  Future<Publication> deleteRow(
    _is.DatabaseSession session,
    Publication row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Publication>(
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
  Future<List<Publication>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationTable> where,
    _is.OrderByBuilder<PublicationTable>? orderBy,
    _is.OrderByListBuilder<PublicationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Publication>(
      where: where(Publication.t),
      orderBy: orderBy?.call(Publication.t),
      orderByList: orderByList?.call(Publication.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Publication>(
      where: where?.call(Publication.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Publication] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Publication>(
      where: where(Publication.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
