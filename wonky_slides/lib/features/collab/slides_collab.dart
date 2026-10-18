import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_revlog/apply.dart' show RevRejectReason;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart'
    show RevGroupRejection;
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoEntry;

import '../editor_screen/deck_editor_controller.dart';
import '../../l10n/slides_l10n.dart';
import '../present/active_presentation.dart';
import '../revlog/logged_deck_session.dart';
import '../text_editing/text_editing_host.dart';
import 'slides_hints.dart';
import 'slides_presence_controller.dart';
import 'slides_presence_cursor.dart';
import 'soft_locks.dart';

/// The collaboration features of one open deck editor (Slides 09 §1–§2):
/// presence ([presence]: cursor, remote selections, dots, jump/follow,
/// presenting), soft locks ([locks], installed as the text editing's
/// `TextEditLocks`) and ephemeral hints ([hints]: live typing and drags).
/// Attached by the editor screen once the deck is ready; found with
/// [SlidesCollab.of]. Absent offline is fine: without a presence session
/// nothing is sent or shown (09 §6.1).
class SlidesCollab {
  SlidesCollab._(this.editor) {
    presence = SlidesPresenceController(editor, claimOf: () => locks.published);
    locks = SlidesSoftLocks(editor, presence);
    hints = SlidesHints(editor, presence);
    _host = textEditingOf(editor)..locks = locks;
    activePresentation.addListener(_onPresentation);
    _onPresentation();
    final session = editor.session;
    if (session is LoggedDeckSession) {
      _rejections = session.groupRejected.listen(onGroupRejected);
    }
  }

  StreamSubscription<RevGroupRejection>? _rejections;

  /// The server rejected a group (RevLog spec 06 §4.6): the model is
  /// already rolled back; the plan's undo step is removed when it is the
  /// top one (a buried step's undo finds nothing to revert and is skipped
  /// by the per-column rule), and one toast says why.
  @visibleForTesting
  void onGroupRejected(RevGroupRejection r) {
    if (_disposed) return;
    final services = editor.services;
    final stack = UndoStackKey(editor.session.itemUuid.uuid);
    final steps = services.undo.undoStepsOf(stack);
    if (steps.isNotEmpty) {
      final top = steps.last;
      final hit = top.entries.any(
        (e) => e is SlidesRowsUndoEntry && e.groupId == r.groupId,
      );
      if (hit) services.undo.discardTop(top.id, stack: stack);
    }
    debugPrint(
      'Change rejected (${r.rejection.reason.name}, group ${r.groupId}): '
      '${r.rejection.message}',
    );
    final l = slidesL10nOf(services);
    services.toasts.show(switch (r.rejection.reason) {
      RevRejectReason.forbiddenForRole ||
      RevRejectReason.forbidden => l.toastChangeNoAccess,
      _ => l.toastChangeNotSaved(r.ops.first.label, r.rejection.message),
    });
  }

  static final Expando<SlidesCollab> _of = Expando('slidesCollab');

  /// The collaboration features of [editor] (null when not attached).
  static SlidesCollab? of(DeckEditorController editor) => _of[editor];

  /// Creates (or returns) the collaboration features of [editor].
  static SlidesCollab attach(
    DeckEditorController editor, {
    PresenceSession? presence,
  }) {
    final c = _of[editor] ??= SlidesCollab._(editor);
    c.setPresence(presence);
    return c;
  }

  final DeckEditorController editor;

  /// The text editing host whose soft locks these are.
  late final SlideTextEditing _host;
  late final SlidesPresenceController presence;
  late final SlidesSoftLocks locks;
  late final SlidesHints hints;

  PresenceSession? _session;
  bool _disposed = false;

  /// Everything the canvas chrome draws from.
  late final Listenable changes = Listenable.merge([
    presence,
    locks,
    hints,
    locks.prompt,
  ]);

  PresenceSession? get session => _session;

  /// Attaches the shell's presence session of the file (null detaches).
  void setPresence(PresenceSession? session) {
    if (identical(session, _session)) return;
    _session = session;
    presence.attach(session);
    hints.attach(session);
    presence.publish();
  }

  // ------------------------------------------------------------ presenting

  PresentHandle? _handle;
  Timer? _poll;

  /// Publishes `presenting` while this user presents the deck in this
  /// window (SL-19's present screen, 09 §1.6). The present screen creates
  /// its controller after the route opened, so an active presentation
  /// without one is polled until it has one.
  void _onPresentation() {
    if (_disposed) return;
    final h = activePresentation.value;
    if (!identical(h, _handle)) {
      _handle?.controller?.removeListener(_onPosition);
      _handle = h;
      _bound = null;
    }
    _bindController();
  }

  Object? _bound;

  void _bindController() {
    final h = _handle;
    final c = h?.controller;
    if (h == null) {
      _poll?.cancel();
      _poll = null;
      presence.presenting = null;
      return;
    }
    if (c == null) {
      _poll ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_handle?.controller != null) {
          _poll?.cancel();
          _poll = null;
          _bindController();
        }
      });
      return;
    }
    if (!identical(c, _bound)) {
      (_bound as Listenable?)?.removeListener(_onPosition);
      _bound = c;
      c.addListener(_onPosition);
    }
    _onPosition();
  }

  void _onPosition() {
    if (_disposed) return;
    final h = _handle;
    final c = h?.controller;
    final p = c?.position;
    final presenting =
        h != null &&
        c != null &&
        !c.ended &&
        !h.view.isMember &&
        identical(c.model, editor.model);
    presence.presenting = presenting && p != null
        ? PresentingState(
            presentationId: h.link?.sessionId,
            slideId: p.slideId,
            step: p.step,
          )
        : null;
  }

  /// Collaborators and soft locks for MCP `ui.get_state` (09 §8).
  Map<String, Object?> describeState() => {
    'collaborators': [
      for (final c in presence.cursors)
        {
          'sessionId': c.sessionId,
          'name': presence.labelOf(c.participant),
          'state': c.participant.state.name,
          'slideId': c.slideId,
          'selection': c.cursor.selection,
          'viewMode': c.cursor.viewMode,
          'surfaceId': ?c.cursor.surfaceId,
          if (c.cursor.pointer case final p?) 'pointer': {'x': p.dx, 'y': p.dy},
          if (c.cursor.presenting != null) 'presenting': true,
          if (c.cursor.editing case final e?) 'editing': e.toJson(),
        },
    ],
    'softLocks': [for (final e in locks.localClaims) e.toJson()],
    'following': presence.following.value,
    'presenters': [for (final p in presence.presenters) p.sessionId],
  };

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_rejections?.cancel());
    activePresentation.removeListener(_onPresentation);
    (_bound as Listenable?)?.removeListener(_onPosition);
    _poll?.cancel();
    if (identical(_host.locks, locks)) _host.locks = const TextEditLocks();
    hints.dispose();
    locks.dispose();
    presence.dispose();
    if (identical(_of[editor], this)) _of[editor] = null;
  }
}
