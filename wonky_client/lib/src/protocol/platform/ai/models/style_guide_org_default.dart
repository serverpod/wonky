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

/// The default style guide of an organization (suite 10 §7): documents
/// without their own style use it.
abstract class StyleGuideOrgDefault
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StyleGuideOrgDefault._({
    this.id,
    required this.orgKey,
    required this.styleRef,
    this.setById,
    required this.updatedAt,
  });

  factory StyleGuideOrgDefault({
    int? id,
    required String orgKey,
    required String styleRef,
    int? setById,
    required DateTime updatedAt,
  }) = _StyleGuideOrgDefaultImpl;

  factory StyleGuideOrgDefault.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StyleGuideOrgDefault(
      id: jsonSerialization['id'] as int?,
      orgKey: jsonSerialization['orgKey'] as String,
      styleRef: jsonSerialization['styleRef'] as String,
      setById: jsonSerialization['setById'] as int?,
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String orgKey;

  /// `builtin:<key>` or `custom:<uuid>`.
  String styleRef;

  int? setById;

  DateTime updatedAt;

  /// Returns a shallow copy of this [StyleGuideOrgDefault]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StyleGuideOrgDefault copyWith({
    int? id,
    String? orgKey,
    String? styleRef,
    int? setById,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StyleGuideOrgDefault',
      if (id != null) 'id': id,
      'orgKey': orgKey,
      'styleRef': styleRef,
      if (setById != null) 'setById': setById,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StyleGuideOrgDefault',
      if (id != null) 'id': id,
      'orgKey': orgKey,
      'styleRef': styleRef,
      if (setById != null) 'setById': setById,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StyleGuideOrgDefaultImpl extends StyleGuideOrgDefault {
  _StyleGuideOrgDefaultImpl({
    int? id,
    required String orgKey,
    required String styleRef,
    int? setById,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         orgKey: orgKey,
         styleRef: styleRef,
         setById: setById,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [StyleGuideOrgDefault]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StyleGuideOrgDefault copyWith({
    Object? id = _Undefined,
    String? orgKey,
    String? styleRef,
    Object? setById = _Undefined,
    DateTime? updatedAt,
  }) {
    return StyleGuideOrgDefault(
      id: id is int? ? id : this.id,
      orgKey: orgKey ?? this.orgKey,
      styleRef: styleRef ?? this.styleRef,
      setById: setById is int? ? setById : this.setById,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
