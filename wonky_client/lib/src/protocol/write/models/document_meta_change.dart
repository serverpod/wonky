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
import '../../platform/common/actor_kind.dart' as _ipbpecg8;

/// LWW metadata change (Write 03 §6). The title lives on DriveItem.
abstract class DocumentMetaChange
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DocumentMetaChange._({
    this.id,
    required this.documentId,
    required this.field,
    this.clientOpId,
    required this.beforeJson,
    required this.afterJson,
    this.authorId,
    required this.actorKind,
    required this.createdAt,
  });

  factory DocumentMetaChange({
    int? id,
    required int documentId,
    required String field,
    _isc.UuidValue? clientOpId,
    required String beforeJson,
    required String afterJson,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) = _DocumentMetaChangeImpl;

  factory DocumentMetaChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentMetaChange(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      field: jsonSerialization['field'] as String,
      clientOpId: jsonSerialization['clientOpId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['clientOpId'],
            ),
      beforeJson: jsonSerialization['beforeJson'] as String,
      afterJson: jsonSerialization['afterJson'] as String,
      authorId: jsonSerialization['authorId'] as int?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int documentId;

  /// themeId, pageSetup, language, frontMatter.
  String field;

  _isc.UuidValue? clientOpId;

  String beforeJson;

  String afterJson;

  int? authorId;

  _ipbpecg8.ActorKind actorKind;

  DateTime createdAt;

  /// Returns a shallow copy of this [DocumentMetaChange]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DocumentMetaChange copyWith({
    int? id,
    int? documentId,
    String? field,
    _isc.UuidValue? clientOpId = const _isc.$UndefinedUuidValue(),
    String? beforeJson,
    String? afterJson,
    int? authorId,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentMetaChange',
      if (id != null) 'id': id,
      'documentId': documentId,
      'field': field,
      if (clientOpId != null) 'clientOpId': clientOpId?.toJson(),
      'beforeJson': beforeJson,
      'afterJson': afterJson,
      if (authorId != null) 'authorId': authorId,
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentMetaChange',
      if (id != null) 'id': id,
      'documentId': documentId,
      'field': field,
      if (clientOpId != null) 'clientOpId': clientOpId?.toJson(),
      'beforeJson': beforeJson,
      'afterJson': afterJson,
      if (authorId != null) 'authorId': authorId,
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentMetaChangeImpl extends DocumentMetaChange {
  _DocumentMetaChangeImpl({
    int? id,
    required int documentId,
    required String field,
    _isc.UuidValue? clientOpId,
    required String beforeJson,
    required String afterJson,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) : super._(
         id: id,
         documentId: documentId,
         field: field,
         clientOpId: clientOpId,
         beforeJson: beforeJson,
         afterJson: afterJson,
         authorId: authorId,
         actorKind: actorKind,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DocumentMetaChange]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DocumentMetaChange copyWith({
    Object? id = _Undefined,
    int? documentId,
    String? field,
    _isc.UuidValue? clientOpId = const _isc.$UndefinedUuidValue(),
    String? beforeJson,
    String? afterJson,
    Object? authorId = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  }) {
    return DocumentMetaChange(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      field: field ?? this.field,
      clientOpId: clientOpId is _isc.UndefinedSentinel
          ? this.clientOpId
          : clientOpId,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      authorId: authorId is int? ? authorId : this.authorId,
      actorKind: actorKind ?? this.actorKind,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
