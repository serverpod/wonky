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
import '../../platform/common/actor_kind.dart' as _ipbpecg8;

abstract class WriteDiffAuthor
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WriteDiffAuthor._({
    this.userUuid,
    required this.name,
    required this.colorIndex,
    required this.actorKind,
    required this.inserted,
    required this.deleted,
    required this.formatted,
  });

  factory WriteDiffAuthor({
    _is.UuidValue? userUuid,
    required String name,
    required int colorIndex,
    required _ipbpecg8.ActorKind actorKind,
    required int inserted,
    required int deleted,
    required int formatted,
  }) = _WriteDiffAuthorImpl;

  factory WriteDiffAuthor.fromJson(Map<String, dynamic> jsonSerialization) {
    return WriteDiffAuthor(
      userUuid: jsonSerialization['userUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['userUuid']),
      name: jsonSerialization['name'] as String,
      colorIndex: jsonSerialization['colorIndex'] as int,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      inserted: jsonSerialization['inserted'] as int,
      deleted: jsonSerialization['deleted'] as int,
      formatted: jsonSerialization['formatted'] as int,
    );
  }

  _is.UuidValue? userUuid;

  String name;

  int colorIndex;

  _ipbpecg8.ActorKind actorKind;

  int inserted;

  int deleted;

  int formatted;

  /// Returns a shallow copy of this [WriteDiffAuthor]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WriteDiffAuthor copyWith({
    _is.UuidValue? userUuid = const _is.$UndefinedUuidValue(),
    String? name,
    int? colorIndex,
    _ipbpecg8.ActorKind? actorKind,
    int? inserted,
    int? deleted,
    int? formatted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WriteDiffAuthor',
      if (userUuid != null) 'userUuid': userUuid?.toJson(),
      'name': name,
      'colorIndex': colorIndex,
      'actorKind': actorKind.toJson(),
      'inserted': inserted,
      'deleted': deleted,
      'formatted': formatted,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WriteDiffAuthor',
      if (userUuid != null) 'userUuid': userUuid?.toJson(),
      'name': name,
      'colorIndex': colorIndex,
      'actorKind': actorKind.toJson(),
      'inserted': inserted,
      'deleted': deleted,
      'formatted': formatted,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _WriteDiffAuthorImpl extends WriteDiffAuthor {
  _WriteDiffAuthorImpl({
    _is.UuidValue? userUuid,
    required String name,
    required int colorIndex,
    required _ipbpecg8.ActorKind actorKind,
    required int inserted,
    required int deleted,
    required int formatted,
  }) : super._(
         userUuid: userUuid,
         name: name,
         colorIndex: colorIndex,
         actorKind: actorKind,
         inserted: inserted,
         deleted: deleted,
         formatted: formatted,
       );

  /// Returns a shallow copy of this [WriteDiffAuthor]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WriteDiffAuthor copyWith({
    _is.UuidValue? userUuid = const _is.$UndefinedUuidValue(),
    String? name,
    int? colorIndex,
    _ipbpecg8.ActorKind? actorKind,
    int? inserted,
    int? deleted,
    int? formatted,
  }) {
    return WriteDiffAuthor(
      userUuid: userUuid is _is.UndefinedSentinel ? this.userUuid : userUuid,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      actorKind: actorKind ?? this.actorKind,
      inserted: inserted ?? this.inserted,
      deleted: deleted ?? this.deleted,
      formatted: formatted ?? this.formatted,
    );
  }
}
