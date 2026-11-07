import 'package:serverpod/serverpod.dart';

import 'models.dart';

/// Who performs a service call: the user plus the kind of actor (a person in
/// an app, an MCP client, the AI assistant, a script or the system).
class Actor {
  const Actor({
    required this.userId,
    required this.authUserId,
    this.kind = ActorKind.user,
    this.sessionId,
  });

  /// The profile id of the signed-out viewer of a link-shared item
  /// ([anonymous], specs/06 §2.4). Profile ids start at 1.
  static const anonymousUserId = 0;

  /// The signed-out viewer of a link-shared document, spreadsheet or
  /// presentation (specs/06 §2.4): no profile, Viewer at most
  /// (`AccessService.rolesFor`), never recorded (no drive state, activity,
  /// presence or usage).
  static final anonymous = Actor(
    userId: anonymousUserId,
    authUserId: UuidValue.fromString('00000000-0000-0000-0000-000000000000'),
  );

  /// UserProfile id ([anonymousUserId] when signed out).
  final int userId;

  /// Whether this is the signed-out viewer ([anonymous]).
  bool get isAnonymous => userId == anonymousUserId;

  /// Serverpod auth user UUID (sync spaces, Write `by` attributes).
  final UuidValue authUserId;

  final ActorKind kind;

  /// Editing session (document stream, presence) the call belongs to.
  final String? sessionId;

  Actor copyWith({ActorKind? kind, String? sessionId}) => Actor(
    userId: userId,
    authUserId: authUserId,
    kind: kind ?? this.kind,
    sessionId: sessionId ?? this.sessionId,
  );

  @override
  String toString() => 'Actor($userId, ${kind.name})';
}
