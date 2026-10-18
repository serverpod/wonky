import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart';

import '../../l10n/write_l10n.dart';
import '../document/write_document_session.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show DeltaSelection;
import '../editor/view/editor_view_state.dart' show RemoteCursor;
import '../sync/document_sync_controller.dart';

/// Write presence on the document stream (Write 08 §5, Write 04 §34):
///
/// - the participants of the document stream (names, presence colors,
///   roles) — the avatar stack itself uses the shell's presence roster;
/// - remote carets and selections: `RemoteCursor` messages are mapped to
///   local offsets by the sync controller and drawn by the editor
///   (`EditorViewState.setRemoteCursor`, transformed through every change);
/// - the local selection, broadcast as `CursorUpdate` throttled to 10/s and
///   on focus changes (also in Viewing mode);
/// - jump to / follow a collaborator (`write.presence.jumpTo`, `follow`).
class RemotePresenceController extends ChangeNotifier {
  RemotePresenceController(this.session, {this.throttle = _defaultThrottle});

  static const _defaultThrottle = Duration(milliseconds: 100);

  final WriteDocumentSession session;

  /// Minimum interval between two cursor updates (10/s).
  final Duration throttle;

  DocumentSyncController? _sync;
  StreamSubscription<SyncEvent>? _sub;
  Map<String, Participant> _participants = const {};
  final Map<String, int> _activity = {};
  String? _following;
  Timer? _timer;
  bool _dirty = false;
  DeltaSelection? _lastSelection;
  bool? _lastFocused;
  bool _disposed = false;

  /// Other sessions on the document (this window excluded), oldest first.
  List<Participant> get participants {
    final list = [..._participants.values]
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return list;
  }

  /// The session being followed, if any.
  String? get following => _following;

  /// Starts presence for [sync] (called by the session).
  void attach(DocumentSyncController sync) {
    _sync = sync;
    _sub = sync.events.listen(_onEvent);
    session.editor.addListener(_onEditor);
    session.editor.focusNode.addListener(_onEditor);
  }

  void _onEvent(SyncEvent e) {
    if (_disposed) return;
    final view = session.editor.view;
    switch (e) {
      case SyncParticipantsChanged(:final participants):
        _participants = participants;
        for (final c in [...view.remoteCursors]) {
          if (!participants.containsKey(c.sessionId)) {
            view.removeRemoteCursor(c.sessionId);
          }
        }
        if (_following != null && !participants.containsKey(_following)) {
          _following = null;
        }
        notifyListeners();
      case SyncRemoteCursor():
        _showCursor(e);
      case SyncDisconnected():
        view.clearRemoteCursors();
      case SyncConnected():
        _lastSelection = null;
        _lastFocused = null;
        _onEditor();
      default:
        break;
    }
  }

  void _showCursor(SyncRemoteCursor e) {
    final p = _participants[e.sessionId];
    final me = session.services.me;
    final isSelf = p != null && me != null && p.userId == me.id;
    final activity = (_activity[e.sessionId] ?? 0) + 1;
    _activity[e.sessionId] = activity;
    session.editor.view.setRemoteCursor(
      RemoteCursor(
        sessionId: e.sessionId,
        userKey: '${p?.userUuid.uuid ?? e.userId}',
        name: isSelf
            ? writeL10nOf(session.services).presenceYouOtherTab
            : (p?.displayName ?? writeL10nOf(session.services).presenceSomeone),
        selection: DeltaSelection(e.anchor, e.head),
        focused: e.focused,
        isAgent: p != null && p.actorKind != ActorKind.user,
        lastActivity: activity,
        colorIndex: p?.colorIndex,
      ),
    );
    if (_following == e.sessionId) _revealCursor(e.sessionId);
  }

  // ---------------------------------------------------------------------------
  // Local cursor broadcast.

  void _onEditor() {
    if (_disposed) return;
    final sel = session.editor.selection;
    final focused = session.editor.focusNode.hasFocus;
    if (sel == _lastSelection && focused == _lastFocused) return;
    if (_following != null && sel != _lastSelection && _lastSelection != null) {
      // Local caret movement stops following (Write 04 §34.4).
      unfollow();
    }
    _dirty = true;
    if (_timer?.isActive ?? false) return;
    _send();
    _timer = Timer(throttle, () {
      if (_dirty) _send();
    });
  }

  /// Sends a pending cursor update now (skips the throttle).
  void flush() {
    if (_dirty) _send();
  }

  void _send() {
    _dirty = false;
    final sync = _sync;
    final sel = session.editor.selection;
    final focused = session.editor.focusNode.hasFocus;
    if (sync == null || !sync.isConnected || sel == null) return;
    _lastSelection = sel;
    _lastFocused = focused;
    sync.sendCursor(sel.anchor, sel.head, focused: focused);
  }

  // ---------------------------------------------------------------------------
  // Jump to / follow.

  /// Scrolls to [sessionId]'s caret (`write.presence.jumpTo`). Returns
  /// false when the collaborator has no known cursor.
  bool reveal(String sessionId) => _revealCursor(sessionId);

  bool _revealCursor(String sessionId) {
    for (final c in session.editor.view.remoteCursors) {
      if (c.sessionId == sessionId) {
        session.revealRange(c.selection.head, c.selection.head);
        return true;
      }
    }
    return false;
  }

  /// Scrolls to the caret of [userId]'s most recent session.
  bool revealUser(int userId) {
    final candidates = [
      for (final p in participants)
        if (p.userId == userId) p.sessionId,
    ];
    for (final id in candidates.reversed) {
      if (_revealCursor(id)) return true;
    }
    return false;
  }

  /// Keeps [sessionId]'s caret in view until local input
  /// (`write.presence.follow`).
  void follow(String sessionId) {
    _following = sessionId;
    _revealCursor(sessionId);
    notifyListeners();
  }

  /// Stops following (`write.presence.unfollow`).
  void unfollow() {
    if (_following == null) return;
    _following = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_sub?.cancel());
    session.editor.removeListener(_onEditor);
    session.editor.focusNode.removeListener(_onEditor);
    super.dispose();
  }
}
