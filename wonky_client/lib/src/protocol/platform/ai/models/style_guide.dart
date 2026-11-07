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

/// A user's own style guide for the assistant (suite 10 §7), kept personal
/// or shared with the owner's organization. Built-in guides are code
/// constants (`BuiltinStyleGuides`), not rows.
abstract class StyleGuide
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StyleGuide._({
    this.id,
    _isc.UuidValue? uuid,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.markdown,
    this.orgKey,
    required this.createdAt,
    required this.updatedAt,
  }) : uuid = uuid ?? const _isc.Uuid().v7obj();

  factory StyleGuide({
    int? id,
    _isc.UuidValue? uuid,
    required int ownerId,
    required String name,
    required String description,
    required String markdown,
    String? orgKey,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StyleGuideImpl;

  factory StyleGuide.fromJson(Map<String, dynamic> jsonSerialization) {
    return StyleGuide(
      id: jsonSerialization['id'] as int?,
      uuid: jsonSerialization['uuid'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      ownerId: jsonSerialization['ownerId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      markdown: jsonSerialization['markdown'] as String,
      orgKey: jsonSerialization['orgKey'] as String?,
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

  _isc.UuidValue uuid;

  int ownerId;

  String name;

  String description;

  /// The guide itself (Markdown).
  String markdown;

  /// The organization it is shared with (its key, e.g. `serverpod.dev`);
  /// null = personal.
  String? orgKey;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [StyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StyleGuide copyWith({
    int? id,
    _isc.UuidValue? uuid,
    int? ownerId,
    String? name,
    String? description,
    String? markdown,
    String? orgKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StyleGuide',
      if (id != null) 'id': id,
      'uuid': uuid.toJson(),
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'markdown': markdown,
      if (orgKey != null) 'orgKey': orgKey,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StyleGuide',
      if (id != null) 'id': id,
      'uuid': uuid.toJson(),
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'markdown': markdown,
      if (orgKey != null) 'orgKey': orgKey,
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

class _StyleGuideImpl extends StyleGuide {
  _StyleGuideImpl({
    int? id,
    _isc.UuidValue? uuid,
    required int ownerId,
    required String name,
    required String description,
    required String markdown,
    String? orgKey,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         uuid: uuid,
         ownerId: ownerId,
         name: name,
         description: description,
         markdown: markdown,
         orgKey: orgKey,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [StyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StyleGuide copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? uuid,
    int? ownerId,
    String? name,
    String? description,
    String? markdown,
    Object? orgKey = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StyleGuide(
      id: id is int? ? id : this.id,
      uuid: uuid ?? this.uuid,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      markdown: markdown ?? this.markdown,
      orgKey: orgKey is String? ? orgKey : this.orgKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
