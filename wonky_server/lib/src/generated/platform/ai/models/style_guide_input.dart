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
import 'package:serverpod/serverpod.dart' as _is;

/// Creates or updates one of the user's style guides. With [uuid] of a
/// guide that no longer exists (undo of a delete) it is created again.
abstract class StyleGuideInput
    implements _is.SerializableModel, _is.ProtocolSerialization {
  StyleGuideInput._({
    this.uuid,
    required this.name,
    required this.description,
    required this.markdown,
    required this.shareWithOrg,
  });

  factory StyleGuideInput({
    _is.UuidValue? uuid,
    required String name,
    required String description,
    required String markdown,
    required bool shareWithOrg,
  }) = _StyleGuideInputImpl;

  factory StyleGuideInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return StyleGuideInput(
      uuid: jsonSerialization['uuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      markdown: jsonSerialization['markdown'] as String,
      shareWithOrg: _is.BoolJsonExtension.fromJson(
        jsonSerialization['shareWithOrg'],
      ),
    );
  }

  _is.UuidValue? uuid;

  String name;

  String description;

  String markdown;

  bool shareWithOrg;

  /// Returns a shallow copy of this [StyleGuideInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StyleGuideInput copyWith({
    _is.UuidValue? uuid = const _is.$UndefinedUuidValue(),
    String? name,
    String? description,
    String? markdown,
    bool? shareWithOrg,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StyleGuideInput',
      if (uuid != null) 'uuid': uuid?.toJson(),
      'name': name,
      'description': description,
      'markdown': markdown,
      'shareWithOrg': shareWithOrg,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StyleGuideInput',
      if (uuid != null) 'uuid': uuid?.toJson(),
      'name': name,
      'description': description,
      'markdown': markdown,
      'shareWithOrg': shareWithOrg,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _StyleGuideInputImpl extends StyleGuideInput {
  _StyleGuideInputImpl({
    _is.UuidValue? uuid,
    required String name,
    required String description,
    required String markdown,
    required bool shareWithOrg,
  }) : super._(
         uuid: uuid,
         name: name,
         description: description,
         markdown: markdown,
         shareWithOrg: shareWithOrg,
       );

  /// Returns a shallow copy of this [StyleGuideInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StyleGuideInput copyWith({
    _is.UuidValue? uuid = const _is.$UndefinedUuidValue(),
    String? name,
    String? description,
    String? markdown,
    bool? shareWithOrg,
  }) {
    return StyleGuideInput(
      uuid: uuid is _is.UndefinedSentinel ? this.uuid : uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      markdown: markdown ?? this.markdown,
      shareWithOrg: shareWithOrg ?? this.shareWithOrg,
    );
  }
}
