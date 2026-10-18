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

/// The last 50 saved versions of a theme.
abstract class WriteThemeRevision
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WriteThemeRevision._({
    this.id,
    required this.themeId,
    required this.version,
    required this.json,
    this.savedById,
    required this.actorKind,
    required this.createdAt,
  });

  factory WriteThemeRevision({
    int? id,
    required int themeId,
    required int version,
    required String json,
    int? savedById,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) = _WriteThemeRevisionImpl;

  factory WriteThemeRevision.fromJson(Map<String, dynamic> jsonSerialization) {
    return WriteThemeRevision(
      id: jsonSerialization['id'] as int?,
      themeId: jsonSerialization['themeId'] as int,
      version: jsonSerialization['version'] as int,
      json: jsonSerialization['json'] as String,
      savedById: jsonSerialization['savedById'] as int?,
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

  int themeId;

  int version;

  String json;

  int? savedById;

  _ipbpecg8.ActorKind actorKind;

  DateTime createdAt;

  /// Returns a shallow copy of this [WriteThemeRevision]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WriteThemeRevision copyWith({
    int? id,
    int? themeId,
    int? version,
    String? json,
    int? savedById,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WriteThemeRevision',
      if (id != null) 'id': id,
      'themeId': themeId,
      'version': version,
      'json': json,
      if (savedById != null) 'savedById': savedById,
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WriteThemeRevision',
      if (id != null) 'id': id,
      'themeId': themeId,
      'version': version,
      'json': json,
      if (savedById != null) 'savedById': savedById,
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

class _WriteThemeRevisionImpl extends WriteThemeRevision {
  _WriteThemeRevisionImpl({
    int? id,
    required int themeId,
    required int version,
    required String json,
    int? savedById,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) : super._(
         id: id,
         themeId: themeId,
         version: version,
         json: json,
         savedById: savedById,
         actorKind: actorKind,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WriteThemeRevision]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WriteThemeRevision copyWith({
    Object? id = _Undefined,
    int? themeId,
    int? version,
    String? json,
    Object? savedById = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  }) {
    return WriteThemeRevision(
      id: id is int? ? id : this.id,
      themeId: themeId ?? this.themeId,
      version: version ?? this.version,
      json: json ?? this.json,
      savedById: savedById is int? ? savedById : this.savedById,
      actorKind: actorKind ?? this.actorKind,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
