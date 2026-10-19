import 'dart:async';

import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

/// In-memory [PresenceRepository]: each [join] opens a stream the test
/// drives through [server] and records the session's updates in [updates].
class FakePresenceRepository implements PresenceRepository {
  /// One controller per join, newest last.
  final List<StreamController<PresenceEvent>> joins = [];

  /// Every update this window sent, in order (across reconnects).
  final List<PresenceUpdate> updates = [];

  /// The items joined, in order.
  final List<UuidValue> joinedItems = [];

  /// Whether the latest join's stream was cancelled (the window left).
  bool get left => _left.isNotEmpty && _left.last;
  final List<bool> _left = [];

  /// The latest join's event stream (the server side).
  StreamController<PresenceEvent> get server => joins.last;

  @override
  Stream<PresenceEvent> join(
    UuidValue itemUuid,
    Stream<PresenceUpdate> updates,
  ) {
    joinedItems.add(itemUuid);
    final index = _left.length;
    _left.add(false);
    late final StreamSubscription<PresenceUpdate> sub;
    final c = StreamController<PresenceEvent>(
      onCancel: () {
        _left[index] = true;
        unawaited(sub.cancel());
      },
    );
    sub = updates.listen(this.updates.add);
    joins.add(c);
    return c.stream;
  }
}

/// Builds presence [Participant]s for tests.
Participant participant(
  String sessionId, {
  UserSummary? user,
  PresenceState state = PresenceState.active,
  String? mode,
  ActorKind actorKind = ActorKind.user,
}) {
  final u = user ?? TestUsers.anna;
  return Participant(
    sessionId: sessionId,
    userId: u.id,
    userUuid: u.uuid,
    displayName: u.displayName,
    colorIndex: u.colorIndex,
    role: AccessRole.editor,
    actorKind: actorKind,
    state: state,
    mode: mode,
    joinedAt: DateTime.utc(2026, 10, 1),
  );
}

/// In-memory [CommentRepository] with the server's basic semantics: threads
/// by uuid, comment ids counting up, [events] for live updates and [calls]
/// recording the operations.
class FakeCommentRepository implements CommentRepository {
  final Map<String, CommentThreadView> threads = {};
  final StreamController<CommentEvent> events =
      StreamController<CommentEvent>.broadcast();

  /// Names of the calls, in order (`createThread`, `reply` …).
  final List<String> calls = [];

  /// When set, every mutating call throws it.
  Object? failWith;

  /// How often [watch] was called.
  int watches = 0;
  int _next = 1;
  int _seeded = 0;

  CommentThreadView _put(CommentThreadView t) => threads[t.uuid.uuid] = t;

  CommentThreadView _thread(UuidValue uuid) =>
      threads[uuid.uuid] ??
      (throw WonkyException(
        code: WonkyErrorCode.notFound,
        message: 'Thread not found',
      ));

  void _call(String name) {
    final f = failWith;
    if (f != null) throw f;
    calls.add(name);
  }

  CommentView comment(
    UuidValue thread,
    String body, {
    UserSummary? author,
    List<UserSummary> mentions = const [],
  }) => CommentView(
    id: _next++,
    threadUuid: thread,
    author: author ?? TestUsers.anna,
    authorKind: ActorKind.user,
    body: body,
    mentions: mentions,
    reactions: const {},
    createdAt: DateTime.utc(2026, 10, 1),
    deleted: false,
  );

  /// Seeds a thread created at [createdAt] (default 2026-10-01).
  CommentThreadView seed({
    String body = 'Seeded',
    CommentStatus status = CommentStatus.open,
    DateTime? createdAt,
    UserSummary? author,
    UserSummary? assignee,
    List<UserSummary> mentions = const [],
  }) {
    final id = UuidValue.fromString(
      '0190a000-0000-7000-8000-${(++_seeded).toRadixString(16).padLeft(12, '0')}',
    );
    return _put(
      CommentThreadView(
        uuid: id,
        itemUuid: UuidValue.fromString('00000000-0000-7000-8000-000000000000'),
        anchorKind: CommentAnchorKind.document,
        anchorJson: '{}',
        status: status,
        createdBy: author ?? TestUsers.anna,
        createdAt: createdAt ?? DateTime.utc(2026, 10, 1),
        assignee: assignee,
        comments: [comment(id, body, author: author, mentions: mentions)],
      ),
    );
  }

  @override
  Future<List<CommentThreadView>> listThreads(
    UuidValue itemUuid, {
    CommentFilter filter = CommentFilter.all,
  }) async {
    final f = failWith;
    if (f != null) throw f;
    return threads.values.toList();
  }

  @override
  Future<CommentThreadView> createThread({
    required UuidValue threadUuid,
    required UuidValue itemUuid,
    required CommentAnchorKind anchorKind,
    required String anchorJson,
    String? quotedText,
    required String body,
    List<int> mentions = const [],
    int? assigneeId,
  }) async {
    _call('createThread');
    return _put(
      CommentThreadView(
        uuid: threadUuid,
        itemUuid: itemUuid,
        anchorKind: anchorKind,
        anchorJson: anchorJson,
        quotedText: quotedText,
        status: CommentStatus.open,
        createdBy: TestUsers.anna,
        createdAt: DateTime.utc(2026, 10, 2),
        comments: [comment(threadUuid, body)],
      ),
    );
  }

  @override
  Future<CommentThreadView> reply(
    UuidValue threadUuid, {
    required String body,
    List<int> mentions = const [],
    UuidValue? commentUuid,
  }) async {
    _call('reply');
    final t = _thread(threadUuid);
    return _put(
      t.copyWith(comments: [...t.comments, comment(threadUuid, body)]),
    );
  }

  @override
  Future<CommentView> edit(int commentId, String body) async {
    _call('edit');
    for (final t in threads.values) {
      final i = t.comments.indexWhere((c) => c.id == commentId);
      if (i < 0) continue;
      final edited = t.comments[i].copyWith(body: body);
      _put(t.copyWith(comments: [...t.comments]..[i] = edited));
      return edited;
    }
    throw WonkyException(
      code: WonkyErrorCode.notFound,
      message: 'Comment not found',
    );
  }

  @override
  Future<void> delete(int commentId) async {
    _call('delete');
    for (final t in threads.values.toList()) {
      if (t.comments.any((c) => c.id == commentId)) {
        _put(
          t.copyWith(
            comments: [
              for (final c in t.comments)
                if (c.id != commentId) c,
            ],
          ),
        );
      }
    }
  }

  @override
  Future<void> deleteThread(UuidValue threadUuid) async {
    _call('deleteThread');
    _thread(threadUuid);
    threads.remove(threadUuid.uuid);
  }

  @override
  Future<CommentThreadView> resolve(UuidValue threadUuid) async {
    _call('resolve');
    return _put(_thread(threadUuid).copyWith(status: CommentStatus.resolved));
  }

  @override
  Future<CommentThreadView> reopen(UuidValue threadUuid) async {
    _call('reopen');
    return _put(_thread(threadUuid).copyWith(status: CommentStatus.open));
  }

  @override
  Future<CommentView> react(int commentId, String emoji) =>
      throw UnsupportedError('FakeCommentRepository.react');

  @override
  Future<CommentThreadView> updateAnchor(
    UuidValue threadUuid,
    String anchorJson,
  ) async {
    _call('updateAnchor');
    return _put(_thread(threadUuid).copyWith(anchorJson: anchorJson));
  }

  @override
  Stream<CommentEvent> watch(UuidValue itemUuid) {
    watches++;
    return events.stream;
  }
}

/// In-memory [SharingRepository] for one item: [info] is the server's state,
/// mutations update it and are recorded in [calls] (`share:editor:a@b.c` …).
class FakeSharingRepository implements SharingRepository {
  FakeSharingRepository(this.info, {List<UserSummary>? directory})
    : directory = directory ?? [TestUsers.anna, TestUsers.bob];

  SharingInfo info;

  /// Users that share resolves by email (others become pending invites).
  final List<UserSummary> directory;
  final List<String> calls = [];

  /// When set, every mutating call throws it.
  Object? failWith;

  /// When set, [getSharing] waits for it.
  Completer<void>? loadGate;

  Future<SharingInfo> _update(String call, SharingInfo next) async {
    final f = failWith;
    if (f != null) throw f;
    calls.add(call);
    return info = next;
  }

  /// When set, [getSharing] throws it.
  Object? loadError;

  @override
  Future<SharingInfo> getSharing(UuidValue itemUuid) async {
    final gate = loadGate;
    if (gate != null) await gate.future;
    final e = loadError;
    if (e != null) throw e;
    return info;
  }

  @override
  Future<SharingInfo> share(
    UuidValue itemUuid, {
    required List<String> emails,
    required AccessRole role,
    bool notify = true,
    String? message,
    DateTime? expiresAt,
  }) => _update(
    'share:${role.name}:${emails.join(',')}:notify=$notify',
    info.copyWith(
      permissions: [
        ...info.permissions,
        for (final e in emails)
          PermissionView(
            user: directory.where((u) => u.email == e).firstOrNull,
            invitedEmail: directory.any((u) => u.email == e) ? null : e,
            role: role,
            grantedAt: DateTime.utc(2026, 10, 1),
          ),
      ],
    ),
  );

  @override
  Future<SharingInfo> updateRole(
    UuidValue itemUuid, {
    required int userId,
    required AccessRole role,
    DateTime? expiresAt,
  }) => _update(
    'updateRole:$userId:${role.name}',
    info.copyWith(
      permissions: [
        for (final p in info.permissions)
          p.user?.id == userId ? p.copyWith(role: role) : p,
      ],
    ),
  );

  @override
  Future<SharingInfo> remove(
    UuidValue itemUuid, {
    int? userId,
    String? invitedEmail,
  }) => _update(
    'remove:${userId ?? invitedEmail}',
    info.copyWith(
      permissions: [
        for (final p in info.permissions)
          if (!(userId != null && p.user?.id == userId) &&
              !(invitedEmail != null && p.invitedEmail == invitedEmail))
            p,
      ],
    ),
  );

  @override
  Future<SharingInfo> transferOwnership(
    UuidValue itemUuid,
    int newOwnerUserId,
  ) => _update('transfer:$newOwnerUserId', info);

  @override
  Future<DriveItemView> respondToOwnershipTransfer(
    int transferId,
    bool accept,
  ) => throw UnsupportedError('FakeSharingRepository.respond');

  @override
  Future<SharingInfo> setLink(UuidValue itemUuid, AccessRole? role) => _update(
    'setLink:${role?.name}',
    SharingInfo.fromJson({
      ...info.toJson(),
      'link': role == null
          ? null
          : ShareLinkView(token: 'tok', role: role).toJson(),
    }),
  );

  @override
  Future<SharingInfo> rotateLink(UuidValue itemUuid) =>
      _update('rotateLink', info);

  @override
  Future<SharingInfo> updateSettings(
    UuidValue itemUuid,
    ItemSharingSettings settings,
  ) => _update(
    'settings:${settings.editorsCanShare},${settings.nonEditorsCanExport},'
    '${settings.viewersSeeComments}',
    info.copyWith(settings: settings),
  );

  @override
  Future<void> requestAccess(
    UuidValue itemUuid,
    AccessRole role,
    String? message,
  ) async => calls.add('requestAccess:${role.name}');

  @override
  Future<SharingInfo> handleAccessRequest(
    int requestId,
    bool approve,
    AccessRole? role,
  ) => _update(
    'handleRequest:$requestId:$approve',
    info.copyWith(
      pendingRequests: [
        for (final r in info.pendingRequests)
          if (r.id != requestId) r,
      ],
    ),
  );

  @override
  Future<InviteResolution> resolveInvite(String token) =>
      throw UnsupportedError('FakeSharingRepository.resolveInvite');
}
