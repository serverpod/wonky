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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// A Wonky Write document (Write 02 §3). Content lives in the op log.
abstract class Document
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    required _isc.UuidValue uuid,
    required int itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _isc.UuidValue? themeId,
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
      uuid: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      itemId: jsonSerialization['itemId'] as int,
      headRevision: jsonSerialization['headRevision'] as int?,
      latestSnapshotRevision:
          jsonSerialization['latestSnapshotRevision'] as int?,
      themeId: jsonSerialization['themeId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['themeId']),
      pageSetupJson: jsonSerialization['pageSetupJson'] as String?,
      language: jsonSerialization['language'] as String?,
      frontMatter: jsonSerialization['frontMatter'] as String?,
      markdownFlavor: jsonSerialization['markdownFlavor'] as String?,
      charCount: jsonSerialization['charCount'] as int?,
      wordCount: jsonSerialization['wordCount'] as int?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Client may generate (UUIDv7) for offline creation.
  _isc.UuidValue uuid;

  int itemId;

  int headRevision;

  int latestSnapshotRevision;

  /// WriteTheme.uuid; null = each viewer's default theme.
  _isc.UuidValue? themeId;

  String pageSetupJson;

  String? language;

  String? frontMatter;

  /// `gfm` or `wonky` (Write 11 §3.1).
  String markdownFlavor;

  int charCount;

  int wordCount;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Document]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Document copyWith({
    int? id,
    _isc.UuidValue? uuid,
    int? itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _isc.UuidValue? themeId = const _isc.$UndefinedUuidValue(),
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentImpl extends Document {
  _DocumentImpl({
    int? id,
    required _isc.UuidValue uuid,
    required int itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _isc.UuidValue? themeId,
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
  @_isc.useResult
  @override
  Document copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? uuid,
    int? itemId,
    int? headRevision,
    int? latestSnapshotRevision,
    _isc.UuidValue? themeId = const _isc.$UndefinedUuidValue(),
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
      themeId: themeId is _isc.UndefinedSentinel ? this.themeId : themeId,
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
