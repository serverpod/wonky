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
import '../../platform/common/access_role.dart' as _iv7g6vuy;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../platform/presence/presence_state.dart' as _ia3e8v5g;

/// A connected session on an item.
abstract class Participant
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Participant._({
    required this.sessionId,
    required this.userId,
    required this.userUuid,
    required this.displayName,
    this.avatarUrl,
    required this.colorIndex,
    required this.role,
    required this.actorKind,
    required this.state,
    this.mode,
    this.cursorJson,
    required this.joinedAt,
  });

  factory Participant({
    required String sessionId,
    required int userId,
    required _isc.UuidValue userUuid,
    required String displayName,
    String? avatarUrl,
    required int colorIndex,
    required _iv7g6vuy.AccessRole role,
    required _ipbpecg8.ActorKind actorKind,
    required _ia3e8v5g.PresenceState state,
    String? mode,
    String? cursorJson,
    required DateTime joinedAt,
  }) = _ParticipantImpl;

  factory Participant.fromJson(Map<String, dynamic> jsonSerialization) {
    return Participant(
      sessionId: jsonSerialization['sessionId'] as String,
      userId: jsonSerialization['userId'] as int,
      userUuid: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['userUuid'],
      ),
      displayName: jsonSerialization['displayName'] as String,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      colorIndex: jsonSerialization['colorIndex'] as int,
      role: _iv7g6vuy.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      state: _ia3e8v5g.PresenceState.fromJson(
        (jsonSerialization['state'] as String),
      ),
      mode: jsonSerialization['mode'] as String?,
      cursorJson: jsonSerialization['cursorJson'] as String?,
      joinedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  String sessionId;

  int userId;

  _isc.UuidValue userUuid;

  String displayName;

  String? avatarUrl;

  int colorIndex;

  _iv7g6vuy.AccessRole role;

  _ipbpecg8.ActorKind actorKind;

  _ia3e8v5g.PresenceState state;

  String? mode;

  String? cursorJson;

  DateTime joinedAt;

  /// Returns a shallow copy of this [Participant]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Participant copyWith({
    String? sessionId,
    int? userId,
    _isc.UuidValue? userUuid,
    String? displayName,
    String? avatarUrl,
    int? colorIndex,
    _iv7g6vuy.AccessRole? role,
    _ipbpecg8.ActorKind? actorKind,
    _ia3e8v5g.PresenceState? state,
    String? mode,
    String? cursorJson,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Participant',
      'sessionId': sessionId,
      'userId': userId,
      'userUuid': userUuid.toJson(),
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'colorIndex': colorIndex,
      'role': role.toJson(),
      'actorKind': actorKind.toJson(),
      'state': state.toJson(),
      if (mode != null) 'mode': mode,
      if (cursorJson != null) 'cursorJson': cursorJson,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Participant',
      'sessionId': sessionId,
      'userId': userId,
      'userUuid': userUuid.toJson(),
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'colorIndex': colorIndex,
      'role': role.toJson(),
      'actorKind': actorKind.toJson(),
      'state': state.toJson(),
      if (mode != null) 'mode': mode,
      if (cursorJson != null) 'cursorJson': cursorJson,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ParticipantImpl extends Participant {
  _ParticipantImpl({
    required String sessionId,
    required int userId,
    required _isc.UuidValue userUuid,
    required String displayName,
    String? avatarUrl,
    required int colorIndex,
    required _iv7g6vuy.AccessRole role,
    required _ipbpecg8.ActorKind actorKind,
    required _ia3e8v5g.PresenceState state,
    String? mode,
    String? cursorJson,
    required DateTime joinedAt,
  }) : super._(
         sessionId: sessionId,
         userId: userId,
         userUuid: userUuid,
         displayName: displayName,
         avatarUrl: avatarUrl,
         colorIndex: colorIndex,
         role: role,
         actorKind: actorKind,
         state: state,
         mode: mode,
         cursorJson: cursorJson,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [Participant]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Participant copyWith({
    String? sessionId,
    int? userId,
    _isc.UuidValue? userUuid,
    String? displayName,
    Object? avatarUrl = _Undefined,
    int? colorIndex,
    _iv7g6vuy.AccessRole? role,
    _ipbpecg8.ActorKind? actorKind,
    _ia3e8v5g.PresenceState? state,
    Object? mode = _Undefined,
    Object? cursorJson = _Undefined,
    DateTime? joinedAt,
  }) {
    return Participant(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userUuid: userUuid ?? this.userUuid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      colorIndex: colorIndex ?? this.colorIndex,
      role: role ?? this.role,
      actorKind: actorKind ?? this.actorKind,
      state: state ?? this.state,
      mode: mode is String? ? mode : this.mode,
      cursorJson: cursorJson is String? ? cursorJson : this.cursorJson,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
