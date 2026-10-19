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
import 'package:wonky_client/src/protocol/protocol.dart' as _i8pkqg1o;
import '../../platform/activity/activity_type.dart' as _ib69qjv6;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../platform/users/user_summary.dart' as _itg9e9ms;

abstract class ActivityEventView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActivityEventView._({
    required this.id,
    required this.type,
    this.actor,
    required this.actorKind,
    required this.summary,
    required this.at,
  });

  factory ActivityEventView({
    required int id,
    required _ib69qjv6.ActivityType type,
    _itg9e9ms.UserSummary? actor,
    required _ipbpecg8.ActorKind actorKind,
    required String summary,
    required DateTime at,
  }) = _ActivityEventViewImpl;

  factory ActivityEventView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActivityEventView(
      id: jsonSerialization['id'] as int,
      type: _ib69qjv6.ActivityType.fromJson(
        (jsonSerialization['type'] as String),
      ),
      actor: jsonSerialization['actor'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<_itg9e9ms.UserSummary>(
              jsonSerialization['actor'],
            ),
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      summary: jsonSerialization['summary'] as String,
      at: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
    );
  }

  int id;

  _ib69qjv6.ActivityType type;

  _itg9e9ms.UserSummary? actor;

  _ipbpecg8.ActorKind actorKind;

  String summary;

  DateTime at;

  /// Returns a shallow copy of this [ActivityEventView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActivityEventView copyWith({
    int? id,
    _ib69qjv6.ActivityType? type,
    _itg9e9ms.UserSummary? actor = const _UndefinedActivityEventView$actor(),
    _ipbpecg8.ActorKind? actorKind,
    String? summary,
    DateTime? at,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActivityEventView',
      'id': id,
      'type': type.toJson(),
      if (actor != null) 'actor': actor?.toJson(),
      'actorKind': actorKind.toJson(),
      'summary': summary,
      'at': at.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActivityEventView',
      'id': id,
      'type': type.toJson(),
      if (actor != null) 'actor': actor?.toJsonForProtocol(),
      'actorKind': actorKind.toJson(),
      'summary': summary,
      'at': at.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _UndefinedActivityEventView$actor extends _isc.UndefinedSentinel
    implements _itg9e9ms.UserSummary {
  const _UndefinedActivityEventView$actor();
}

class _ActivityEventViewImpl extends ActivityEventView {
  _ActivityEventViewImpl({
    required int id,
    required _ib69qjv6.ActivityType type,
    _itg9e9ms.UserSummary? actor,
    required _ipbpecg8.ActorKind actorKind,
    required String summary,
    required DateTime at,
  }) : super._(
         id: id,
         type: type,
         actor: actor,
         actorKind: actorKind,
         summary: summary,
         at: at,
       );

  /// Returns a shallow copy of this [ActivityEventView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActivityEventView copyWith({
    int? id,
    _ib69qjv6.ActivityType? type,
    _itg9e9ms.UserSummary? actor = const _UndefinedActivityEventView$actor(),
    _ipbpecg8.ActorKind? actorKind,
    String? summary,
    DateTime? at,
  }) {
    return ActivityEventView(
      id: id ?? this.id,
      type: type ?? this.type,
      actor: actor is _isc.UndefinedSentinel ? this.actor?.copyWith() : actor,
      actorKind: actorKind ?? this.actorKind,
      summary: summary ?? this.summary,
      at: at ?? this.at,
    );
  }
}
