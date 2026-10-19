import 'package:flutter/widgets.dart';
import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../shell/shell_services.dart';

/// This window's presence in one file (suite 07 §1): joins the roster,
/// sends state changes (active → idle after 60 s without input, away when
/// hidden), throttles cursor updates to 10/s, and exposes the participants.
class PresenceSession extends ChangeNotifier with WidgetsBindingObserver {
  PresenceSession({required this.services, required this.itemUuid, this.mode});

  final ShellServices services;
  final UuidValue itemUuid;
  String? mode;

  final _updates = StreamController<PresenceUpdate>.broadcast();
  final _hints = StreamController<PresenceHints>.broadcast();
  final _notices = StreamController<PresenceNotice>.broadcast();
  List<Participant> _participants = const [];
  int _followers = 0;
  String? _following;
  String? _sessionId;
  PresenceState _state = PresenceState.active;
  Timer? _idle;
  Timer? _throttle;
  String? _pendingCursor;
  bool _disposed = false;
  bool _started = false;

  /// Whether [start] joined the roster (and [dispose] did not yet run).
  bool get isStarted => _started && !_disposed;

  /// Everyone in the file (including this window).
  List<Participant> get participants => _participants;

  String? get sessionId => _sessionId;

  /// Commit hints relayed from other participants (Sheets 10 §2).
  Stream<PresenceHints> get hints => _hints.stream;

  /// System notices for everyone on the file ("Anna restored a version").
  Stream<PresenceNotice> get notices => _notices.stream;

  /// How many sessions follow this one (Sheets 10 §1.5).
  int get followerCount => _followers;

  /// The session this window follows, or null.
  String? get following => _following;

  /// App-specific activity text of a participant for the avatar tooltip
  /// ("Editing Sheet1!B4"); set by the app.
  String? Function(Participant participant)? detailOf;

  String get _key => 'presence:${itemUuid.uuid}';

  /// Joins the roster. A no-op once started or disposed: a late start must
  /// not leave a zombie stream behind (or replace a reopened editor's
  /// stream, which is supervised under the same key).
  void start() {
    if (_disposed || _started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    services.supervisor.supervise<PresenceEvent>(
      _key,
      () => services.repositories.presence.join(itemUuid, _updates.stream),
      _onEvent,
      onConnected: () => Future<void>.delayed(Duration.zero, _send),
    );
    _resetIdle();
  }

  void _onEvent(PresenceEvent e) {
    switch (e) {
      case PresenceRoster():
        _sessionId = e.sessionId;
        _participants = e.participants;
      case PresenceJoined():
        // A repeated hello (agent cursor updates) replaces the participant.
        final known = _participants.any(
          (p) => p.sessionId == e.participant.sessionId,
        );
        _participants = [
          for (final p in _participants)
            if (p.sessionId != e.participant.sessionId) p,
          e.participant,
        ];
        if (!known) _announce(e.participant.displayName, joined: true);
      case PresenceLeft():
        final gone = _participants
            .where((p) => p.sessionId == e.sessionId)
            .firstOrNull;
        _participants = [
          for (final p in _participants)
            if (p.sessionId != e.sessionId) p,
        ];
        if (gone != null) _announce(gone.displayName, joined: false);
      case PresenceUpdated():
        _participants = [
          for (final p in _participants)
            p.sessionId == e.sessionId
                ? p.copyWith(
                    state: e.state,
                    cursorJson: e.cursorJson,
                    mode: e.mode,
                  )
                : p,
        ];
      case PresenceHints():
        if (!_hints.isClosed) _hints.add(e);
        return;
      case PresenceNotice():
        if (!_notices.isClosed) _notices.add(e);
        return;
      case PresenceFollowerCount():
        _followers = e.count;
    }
    if (!_disposed) notifyListeners();
  }

  void _announce(String name, {required bool joined}) {
    final c = services.navigatorContext;
    final l = services.l10n;
    if (c == null || l == null || !c.mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(c),
      joined ? l.presenceJoined(name) : l.presenceLeft(name),
      Directionality.of(c),
    );
  }

  void _send() {
    if (_updates.isClosed) return;
    _updates.add(
      PresenceUpdate(
        state: _state,
        cursorJson: _pendingCursor,
        mode: mode,
        followingSessionId: _following,
      ),
    );
  }

  /// Broadcasts ephemeral commit hints (JSON objects, Sheets 10 §2.1) to
  /// the other participants; not throttled (the server limits them).
  void sendHints(List<String> hints) {
    if (_updates.isClosed || hints.isEmpty) return;
    _updates.add(
      PresenceUpdate(
        state: _state,
        cursorJson: _pendingCursor,
        mode: mode,
        hints: hints,
        followingSessionId: _following,
      ),
    );
  }

  /// Follows [sessionId] (null stops); the server counts followers so the
  /// followed window knows to send its viewport.
  void follow(String? sessionId) {
    if (_following == sessionId) return;
    _following = sessionId;
    _send();
    if (!_disposed) notifyListeners();
  }

  void _setState(PresenceState s) {
    if (_state == s) return;
    _state = s;
    _send();
  }

  void _resetIdle() {
    _idle?.cancel();
    _idle = Timer(
      const Duration(seconds: 60),
      () => _setState(PresenceState.idle),
    );
  }

  /// Call on user input (the editor scaffold forwards pointer/key events).
  void activity() {
    if (_state != PresenceState.active) _setState(PresenceState.active);
    _resetIdle();
  }

  /// App-specific cursor JSON (Sheets); throttled to 10/s.
  void updateCursor(String? cursorJson) {
    _pendingCursor = cursorJson;
    if (_throttle?.isActive ?? false) return;
    _send();
    _throttle = Timer(const Duration(milliseconds: 100), _send);
  }

  void setMode(String? m) {
    mode = m;
    _send();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setState(PresenceState.active);
        _resetIdle();
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.inactive:
        _setState(PresenceState.away);
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Participants for `PresenceAvatarStack`.
  List<PresenceParticipant> avatars() => [
    for (final p in _participants)
      PresenceParticipant(
        sessionId: p.sessionId,
        userKey: '${p.userId}',
        displayName: p.displayName,
        colorIndex: p.colorIndex,
        avatarUrl: p.avatarUrl,
        isSelf:
            p.sessionId == _sessionId ||
            p.userId == services.me?.id && p.sessionId == _sessionId,
        isAgent: p.actorKind.name != 'user',
        detail: detailOf?.call(p),
        activity: switch (p.state) {
          PresenceState.active =>
            p.mode == 'viewing'
                ? PresenceActivity.viewing
                : PresenceActivity.editing,
          PresenceState.idle => PresenceActivity.idle,
          PresenceState.away => PresenceActivity.away,
          PresenceState.offline => PresenceActivity.offline,
        },
      ),
  ];

  @override
  void dispose() {
    _disposed = true;
    _idle?.cancel();
    _throttle?.cancel();
    // A session that never started leaves the key alone: it may belong to
    // a reopened editor's session.
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(services.supervisor.cancel(_key));
    }
    _updates.close();
    _hints.close();
    _notices.close();
    super.dispose();
  }
}
