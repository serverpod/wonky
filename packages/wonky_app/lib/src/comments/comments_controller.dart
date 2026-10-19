import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart';

import '../data/api.dart';
import '../shell/shell_services.dart';
import 'comment_anchor.dart';
import 'pending_comment_ops.dart';

/// Filters of the comments (suite 07 §2.3): unresolved threads, or the
/// unresolved threads that mention or are assigned to the signed-in user.
enum CommentsFilter { open, forYou }

/// Sort of the comments panel.
enum CommentsSort { position, date }

/// Live comment threads of one file: loads, watches (`comment.watch`) and
/// runs comment operations. Commands (`shell.comments.*`) call it; widgets
/// listen to it.
class CommentsController extends ChangeNotifier {
  CommentsController({
    required this.services,
    required this.itemUuid,
    this.anchors,
  });

  final ShellServices services;
  final UuidValue itemUuid;

  /// The app's anchor provider (null on the home screen).
  CommentAnchorProvider? anchors;

  List<CommentThreadView> _threads = const [];
  bool _loading = true;
  Object? _error;
  CommentsFilter _filter = CommentsFilter.open;
  CommentsSort _sort = CommentsSort.position;
  NewCommentAnchor? _draft;
  String? _active;
  bool _disposed = false;
  bool _started = false;
  String? _scope;

  /// Whether creating, replying, resolving/reopening and anchor moves are
  /// queued while offline and posted when the connection is back (Sheets
  /// 10 §3.7, set by the app). Off: those operations fail offline.
  bool queueOffline = false;

  List<PendingCommentOp> _ops = const [];
  int _localIds = 0;
  bool _flushing = false;
  bool _listening = false;

  /// Operations waiting to be posted.
  List<PendingCommentOp> get pendingOps => _ops;

  /// Whether [threadUuid] has operations waiting to be posted.
  bool isPending(String threadUuid) =>
      _ops.any((o) => o.threadUuid == threadUuid);

  /// Whether [comment] exists only locally (waiting to be posted).
  bool isPendingComment(CommentView comment) => comment.id < 0;

  List<CommentThreadView> get threads => _threads;
  bool get loading => _loading;
  Object? get error => _error;
  CommentsFilter get filter => _filter;
  CommentsSort get sort => _sort;

  /// The app's scope filter (Sheets: `sheet` / `all`), see
  /// [CommentPanelOptions.scopes]; null without scopes.
  String? get scope {
    final opts = commentPanelOptionsOf(anchors);
    final scopes = opts?.scopes ?? const {};
    if (scopes.isEmpty) return null;
    final s = _scope;
    return s != null && scopes.containsKey(s)
        ? s
        : (opts?.defaultScope ?? scopes.keys.first);
  }

  void setScope(String scope) {
    _scope = scope;
    _notify();
  }

  /// The anchor of the composer being written, if any.
  NewCommentAnchor? get draftAnchor => _draft;

  String? get activeThreadUuid => _active;

  int get openCount =>
      _threads.where((t) => t.status == CommentStatus.open).length;

  CommentThreadView? thread(String uuid) {
    for (final t in _threads) {
      if (t.uuid.uuid == uuid) return t;
    }
    return null;
  }

  String get _streamKey => 'comments:${itemUuid.uuid}';

  /// Loads threads and starts the live stream. A no-op once disposed (also
  /// when the disposal happens while loading): a late start must not leave
  /// a zombie stream behind or replace a reopened editor's stream, which is
  /// supervised under the same key.
  Future<void> start() async {
    if (_disposed) return;
    await _loadOps();
    if (_disposed) return;
    await reload();
    if (_disposed) return;
    _started = true;
    services.supervisor.supervise<CommentEvent>(
      _streamKey,
      () => services.repositories.comments.watch(itemUuid),
      _onEvent,
      onConnected: () => unawaited(reload()),
    );
  }

  Future<void> reload() async {
    try {
      _threads = _overlay(
        await services.repositories.comments.listThreads(itemUuid),
      );
      _error = null;
    } catch (e) {
      if (_ops.isNotEmpty && isOfflineError(e)) {
        _threads = _overlay(_threads);
      } else {
        _error = e;
      }
    } finally {
      _loading = false;
      _notify();
    }
  }

  // ---- Offline queue (Sheets 10 §3.7) ----

  String get _opsKey => 'comments.pending.${itemUuid.uuid}';

  Future<void> _loadOps() async {
    if (!_listening) {
      _listening = true;
      services.connectivity.addListener(_onConnectivity);
    }
    try {
      final raw = await services.userStore.read(_opsKey);
      final list = raw is List ? raw : const <Object?>[];
      _ops = [for (final j in list) ?PendingCommentOp.fromJson(j)];
    } catch (e) {
      debugPrint('Reading pending comments failed: $e');
    }
  }

  Future<void> _saveOps() async {
    try {
      if (_ops.isEmpty) {
        await services.userStore.remove(_opsKey);
      } else {
        await services.userStore.write(_opsKey, [
          for (final o in _ops) o.toJson(),
        ]);
      }
    } catch (e) {
      debugPrint('Saving pending comments failed: $e');
    }
  }

  List<CommentThreadView> _overlay(List<CommentThreadView> threads) {
    var out = threads;
    for (final o in _ops) {
      out = o.overlay(
        out,
        itemUuid: itemUuid,
        me: services.me,
        localId: () => -(++_localIds),
      );
    }
    return out;
  }

  bool get _offline => !services.connectivity.online || Api.simulatedOffline;

  void _onConnectivity() {
    if (!_offline && _ops.isNotEmpty) unawaited(flushPending());
  }

  Future<CommentThreadView> _enqueue(
    String threadUuid,
    PendingCommentKind kind,
    Map<String, Object?> payload,
  ) async {
    final op = PendingCommentOp(
      opId: services.ids.next().uuid,
      threadUuid: threadUuid,
      kind: kind,
      payload: payload,
      createdAt: clock.now().toUtc(),
    );
    _ops = [..._ops, op];
    _threads = op.overlay(
      _threads,
      itemUuid: itemUuid,
      me: services.me,
      localId: () => -(++_localIds),
    );
    await _saveOps();
    _notify();
    return thread(threadUuid)!;
  }

  /// Runs [online], or queues the operation when offline (or when the call
  /// fails for lack of a connection) and [queueOffline] is on.
  Future<CommentThreadView> _orQueue(
    String threadUuid,
    PendingCommentKind kind,
    Map<String, Object?> payload,
    Future<CommentThreadView> Function() online,
  ) async {
    final canQueue =
        queueOffline &&
        (kind == PendingCommentKind.create || thread(threadUuid) != null);
    // Later operations on a queued thread wait behind it.
    if (canQueue && (_offline || isPending(threadUuid))) {
      return _enqueue(threadUuid, kind, payload);
    }
    try {
      return await online();
    } catch (e) {
      if (canQueue && isOfflineError(e)) {
        return _enqueue(threadUuid, kind, payload);
      }
      rethrow;
    }
  }

  /// Posts the queued operations in order (when the connection is back).
  /// Operations the server rejects are dropped.
  Future<void> flushPending() async {
    if (_flushing || _ops.isEmpty) return;
    _flushing = true;
    try {
      while (_ops.isNotEmpty && !_disposed) {
        final o = _ops.first;
        try {
          await _post(o);
        } catch (e) {
          if (isOfflineError(e)) return;
          debugPrint('Posting a pending comment failed: $e');
          if (!_disposed) {
            services.toasts.error(
              services.l10n?.commentFailed ?? 'Error',
              description: errorMessage(e),
            );
          }
        }
        _ops = _ops.where((x) => x.opId != o.opId).toList();
        await _saveOps();
      }
    } finally {
      _flushing = false;
    }
    if (!_disposed) await reload();
  }

  Future<void> _post(PendingCommentOp o) async {
    final repo = services.repositories.comments;
    final uuid = UuidValue.fromString(o.threadUuid);
    switch (o.kind) {
      case PendingCommentKind.create:
        // Idempotent on the client-generated thread uuid.
        await repo.createThread(
          threadUuid: uuid,
          itemUuid: itemUuid,
          anchorKind: CommentAnchorKind.values.byName(
            '${o.payload['anchorKind'] ?? 'document'}',
          ),
          anchorJson: '${o.payload['anchorJson'] ?? '{}'}',
          quotedText: o.payload['quotedText'] as String?,
          body: '${o.payload['body'] ?? ''}',
          mentions: o.mentions,
          assigneeId: (o.payload['assigneeId'] as num?)?.toInt(),
        );
      case PendingCommentKind.reply:
        await repo.reply(
          uuid,
          body: '${o.payload['body'] ?? ''}',
          mentions: o.mentions,
          commentUuid: o.payload['commentUuid'] is String
              ? UuidValue.fromString(o.payload['commentUuid'] as String)
              : null,
        );
      case PendingCommentKind.resolve:
        await repo.resolve(uuid);
      case PendingCommentKind.reopen:
        await repo.reopen(uuid);
      case PendingCommentKind.anchor:
        await repo.updateAnchor(uuid, '${o.payload['anchorJson']}');
    }
  }

  /// Drops the queued operations of [threadUuid] (undo of an offline
  /// create); true when the thread existed only locally.
  Future<bool> _dropQueued(String threadUuid) async {
    final created = _ops.any(
      (o) => o.threadUuid == threadUuid && o.kind == PendingCommentKind.create,
    );
    if (!created) return false;
    _ops = _ops.where((o) => o.threadUuid != threadUuid).toList();
    await _saveOps();
    return true;
  }

  void _onEvent(CommentEvent e) {
    switch (e.kind) {
      case CommentEventKind.threadDeleted:
        _threads = [
          for (final t in _threads)
            if (t.uuid != e.threadUuid) t,
        ];
      case CommentEventKind.threadCreated:
      case CommentEventKind.threadUpdated:
      case CommentEventKind.statusChanged:
        final t = e.thread;
        if (t != null) _upsert(t);
    }
    _notify();
  }

  void _upsert(CommentThreadView t) {
    final i = _threads.indexWhere((x) => x.uuid == t.uuid);
    _threads = i < 0 ? [..._threads, t] : ([..._threads]..[i] = t);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Whether [t] passes the current [filter].
  bool passesFilter(CommentThreadView t) {
    // Open includes orphaned threads (unresolved, their text deleted).
    if (t.status == CommentStatus.resolved) return false;
    if (_filter == CommentsFilter.open) return true;
    final me = services.me?.id;
    return t.assignee?.id == me ||
        t.comments.any((c) => c.mentions.any((m) => m.id == me));
  }

  /// Threads after filter and sort.
  List<CommentThreadView> get visible {
    final a = anchors;
    final opts = commentPanelOptionsOf(a);
    final sc = scope;
    final out = [
      for (final t in _threads)
        if (passesFilter(t) &&
            (sc == null || opts == null || opts.inScope(t, sc)))
          t,
    ];
    if (_sort == CommentsSort.date) {
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      if (a != null) {
        // Positions are anchor lookups (O(document) in Write): once each.
        final pos = {for (final t in out) t: a.positionOf(t)};
        out.sort((x, y) => pos[x]!.compareTo(pos[y]!));
      } else {
        out.sort((x, y) => x.createdAt.compareTo(y.createdAt));
      }
    }
    return out;
  }

  void setFilter(CommentsFilter f) {
    _filter = f;
    _notify();
  }

  void setSort(CommentsSort s) {
    _sort = s;
    _notify();
  }

  void startDraft(NewCommentAnchor anchor) {
    _draft = anchor;
    _notify();
  }

  void cancelDraft() {
    _draft = null;
    _notify();
  }

  void activate(String? threadUuid) {
    _active = threadUuid;
    final t = threadUuid == null ? null : thread(threadUuid);
    if (t != null) anchors?.reveal(t);
    _notify();
  }

  // ---- Operations (called by shell.comments.* and the undo handler) ----

  Future<CommentThreadView> createThread({
    required NewCommentAnchor anchor,
    required String body,
    List<int> mentions = const [],
    int? assigneeId,
    UuidValue? threadUuid,
  }) async {
    final id = threadUuid ?? services.ids.next();
    final t = await _orQueue(
      id.uuid,
      PendingCommentKind.create,
      {
        'anchorKind': anchor.kind.name,
        'anchorJson': anchor.anchorJson,
        'quotedText': anchor.quotedText,
        'body': body,
        'mentions': mentions,
        'assigneeId': assigneeId,
      },
      () => services.repositories.comments.createThread(
        threadUuid: id,
        itemUuid: itemUuid,
        anchorKind: anchor.kind,
        anchorJson: anchor.anchorJson,
        quotedText: anchor.quotedText,
        body: body,
        mentions: mentions,
        assigneeId: assigneeId,
      ),
    );
    _draft = null;
    _upsert(t);
    _active = t.uuid.uuid;
    anchors?.onThreadCreated(t);
    _notify();
    return t;
  }

  Future<CommentThreadView> reply(
    String threadUuid,
    String body, {
    List<int> mentions = const [],
  }) async {
    final commentUuid = services.ids.next();
    final t = await _orQueue(
      threadUuid,
      PendingCommentKind.reply,
      {'body': body, 'mentions': mentions, 'commentUuid': commentUuid.uuid},
      () => services.repositories.comments.reply(
        UuidValue.fromString(threadUuid),
        body: body,
        mentions: mentions,
        commentUuid: commentUuid,
      ),
    );
    _upsert(t);
    _notify();
    return t;
  }

  Future<CommentThreadView> resolve(String threadUuid) async {
    final t = await _orQueue(
      threadUuid,
      PendingCommentKind.resolve,
      const {},
      () => services.repositories.comments.resolve(
        UuidValue.fromString(threadUuid),
      ),
    );
    _upsert(t);
    _notify();
    return t;
  }

  Future<CommentThreadView> reopen(String threadUuid) async {
    final t = await _orQueue(
      threadUuid,
      PendingCommentKind.reopen,
      const {},
      () => services.repositories.comments.reopen(
        UuidValue.fromString(threadUuid),
      ),
    );
    _upsert(t);
    _notify();
    return t;
  }

  /// Moves a thread to a new anchor (Sheets: comments move with cut cells,
  /// Sheets 10 §3.2). Queued offline like other thread operations.
  Future<CommentThreadView> updateAnchor(
    String threadUuid,
    String anchorJson,
  ) async {
    final t = await _orQueue(
      threadUuid,
      PendingCommentKind.anchor,
      {'anchorJson': anchorJson},
      () => services.repositories.comments.updateAnchor(
        UuidValue.fromString(threadUuid),
        anchorJson,
      ),
    );
    _upsert(t);
    _notify();
    return t;
  }

  Future<void> deleteThread(String threadUuid) async {
    final existing = thread(threadUuid);
    // A thread created offline and not posted yet is just dropped.
    if (!await _dropQueued(threadUuid)) {
      await services.repositories.comments.deleteThread(
        UuidValue.fromString(threadUuid),
      );
    }
    _threads = [
      for (final t in _threads)
        if (t.uuid.uuid != threadUuid) t,
    ];
    if (existing != null) anchors?.onThreadDeleted(existing);
    _notify();
  }

  Future<void> deleteComment(int commentId) async {
    await services.repositories.comments.delete(commentId);
    await reload();
  }

  Future<CommentView> edit(int commentId, String body) async {
    final c = await services.repositories.comments.edit(commentId, body);
    await reload();
    return c;
  }

  Future<void> react(int commentId, String emoji) async {
    await services.repositories.comments.react(commentId, emoji);
    await reload();
  }

  /// Seconds since [t] for relative times (tests use a fixed clock).
  Duration ageOf(DateTime t) => clock.now().difference(t);

  /// User-facing message for [e].
  String messageOf(Object e) => errorMessage(e);

  @override
  void dispose() {
    _disposed = true;
    if (_listening) services.connectivity.removeListener(_onConnectivity);
    // A controller that never started leaves the key alone: it may belong
    // to a reopened editor's controller.
    if (_started) unawaited(services.supervisor.cancel(_streamKey));
    super.dispose();
  }
}
