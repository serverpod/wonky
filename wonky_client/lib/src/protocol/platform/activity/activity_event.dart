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
import '../../platform/activity/activity_type.dart' as _ib69qjv6;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;

/// Activity log of an item (specs/05 §5). Edits are aggregated to one event
/// per (user, item) per 10 minutes.
abstract class ActivityEvent
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActivityEvent._({
    this.id,
    required this.itemId,
    this.actorId,
    required this.actorKind,
    required this.type,
    required this.summary,
    required this.at,
  });

  factory ActivityEvent({
    int? id,
    required int itemId,
    int? actorId,
    required _ipbpecg8.ActorKind actorKind,
    required _ib69qjv6.ActivityType type,
    required String summary,
    required DateTime at,
  }) = _ActivityEventImpl;

  factory ActivityEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActivityEvent(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      actorId: jsonSerialization['actorId'] as int?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      type: _ib69qjv6.ActivityType.fromJson(
        (jsonSerialization['type'] as String),
      ),
      summary: jsonSerialization['summary'] as String,
      at: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int itemId;

  int? actorId;

  _ipbpecg8.ActorKind actorKind;

  _ib69qjv6.ActivityType type;

  /// JSON payload for rendering.
  String summary;

  DateTime at;

  /// Returns a shallow copy of this [ActivityEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActivityEvent copyWith({
    int? id,
    int? itemId,
    int? actorId,
    _ipbpecg8.ActorKind? actorKind,
    _ib69qjv6.ActivityType? type,
    String? summary,
    DateTime? at,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActivityEvent',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (actorId != null) 'actorId': actorId,
      'actorKind': actorKind.toJson(),
      'type': type.toJson(),
      'summary': summary,
      'at': at.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActivityEvent',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (actorId != null) 'actorId': actorId,
      'actorKind': actorKind.toJson(),
      'type': type.toJson(),
      'summary': summary,
      'at': at.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActivityEventImpl extends ActivityEvent {
  _ActivityEventImpl({
    int? id,
    required int itemId,
    int? actorId,
    required _ipbpecg8.ActorKind actorKind,
    required _ib69qjv6.ActivityType type,
    required String summary,
    required DateTime at,
  }) : super._(
         id: id,
         itemId: itemId,
         actorId: actorId,
         actorKind: actorKind,
         type: type,
         summary: summary,
         at: at,
       );

  /// Returns a shallow copy of this [ActivityEvent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActivityEvent copyWith({
    Object? id = _Undefined,
    int? itemId,
    Object? actorId = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    _ib69qjv6.ActivityType? type,
    String? summary,
    DateTime? at,
  }) {
    return ActivityEvent(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      actorId: actorId is int? ? actorId : this.actorId,
      actorKind: actorKind ?? this.actorKind,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      at: at ?? this.at,
    );
  }
}
