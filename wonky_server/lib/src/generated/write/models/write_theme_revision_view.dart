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
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../platform/users/user_summary.dart' as _itg9e9ms;

abstract class WriteThemeRevisionView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WriteThemeRevisionView._({
    required this.version,
    required this.json,
    this.savedBy,
    required this.actorKind,
    required this.createdAt,
  });

  factory WriteThemeRevisionView({
    required int version,
    required String json,
    _itg9e9ms.UserSummary? savedBy,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) = _WriteThemeRevisionViewImpl;

  factory WriteThemeRevisionView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WriteThemeRevisionView(
      version: jsonSerialization['version'] as int,
      json: jsonSerialization['json'] as String,
      savedBy: jsonSerialization['savedBy'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_itg9e9ms.UserSummary>(
              jsonSerialization['savedBy'],
            ),
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int version;

  String json;

  _itg9e9ms.UserSummary? savedBy;

  _ipbpecg8.ActorKind actorKind;

  DateTime createdAt;

  /// Returns a shallow copy of this [WriteThemeRevisionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WriteThemeRevisionView copyWith({
    int? version,
    String? json,
    _itg9e9ms.UserSummary? savedBy =
        const _UndefinedWriteThemeRevisionView$savedBy(),
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WriteThemeRevisionView',
      'version': version,
      'json': json,
      if (savedBy != null) 'savedBy': savedBy?.toJson(),
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WriteThemeRevisionView',
      'version': version,
      'json': json,
      if (savedBy != null) 'savedBy': savedBy?.toJsonForProtocol(),
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedWriteThemeRevisionView$savedBy extends _is.UndefinedSentinel
    implements _itg9e9ms.UserSummary {
  const _UndefinedWriteThemeRevisionView$savedBy();
}

class _WriteThemeRevisionViewImpl extends WriteThemeRevisionView {
  _WriteThemeRevisionViewImpl({
    required int version,
    required String json,
    _itg9e9ms.UserSummary? savedBy,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) : super._(
         version: version,
         json: json,
         savedBy: savedBy,
         actorKind: actorKind,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WriteThemeRevisionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WriteThemeRevisionView copyWith({
    int? version,
    String? json,
    _itg9e9ms.UserSummary? savedBy =
        const _UndefinedWriteThemeRevisionView$savedBy(),
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  }) {
    return WriteThemeRevisionView(
      version: version ?? this.version,
      json: json ?? this.json,
      savedBy: savedBy is _is.UndefinedSentinel
          ? this.savedBy?.copyWith()
          : savedBy,
      actorKind: actorKind ?? this.actorKind,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
