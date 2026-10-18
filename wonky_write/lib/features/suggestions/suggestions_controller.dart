import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show SuggestionInfo, SuggestionOps;

import '../../l10n/write_l10n.dart';
import '../document/write_document_session.dart';
import '../editor/controller/editor_types.dart';

/// Suggesting mode on the document level (Write 08 §2): the pending
/// suggestions of the document (`SuggestionIndex`), the active one, and
/// accept / reject / withdraw (single and all) through `SuggestionOps` — one
/// undoable op per action, never itself rewritten into a suggestion.
///
/// Rights (Write 08 §2.8): accepting and rejecting need Editor+; the author
/// of a suggestion (any role ≥ Commenter) may withdraw (reject) it.
class WriteSuggestionsController extends ChangeNotifier {
  WriteSuggestionsController(this.session) {
    session.contentVersion.addListener(_onContent);
  }

  final WriteDocumentSession session;

  List<SuggestionInfo>? _pending;
  String? _active;
  bool _disposed = false;

  /// Pending suggestions in document order.
  List<SuggestionInfo> get pending => _pending ??= session.isLoaded
      ? session.editor.overlays.suggestions()
      : const [];

  /// The active (highlighted, expanded) suggestion.
  String? get activeId => _active;

  SuggestionInfo? byId(String id) {
    for (final s in pending) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The suggestion thread of [id] (author, replies), when loaded.
  CommentThreadView? threadOf(String id) {
    final threads = session.comments.controller?.threads;
    if (threads == null) return null;
    for (final t in threads) {
      if (t.suggestionId == id) return t;
    }
    return null;
  }

  /// Whether the user may accept or reject others' suggestions.
  bool get canDecide => session.currentRole.canEdit && session.isLoaded;

  /// Whether the user may reject [s] (Editors, or its author: withdraw).
  bool canReject(SuggestionInfo s) =>
      session.isLoaded &&
      (session.currentRole.canEdit ||
          (session.currentRole.canComment && s.by == session.userUuid));

  /// Whether the current user wrote [s] (the card shows *Withdraw*).
  bool isOwn(SuggestionInfo s) => s.by == session.userUuid;

  void _onContent() {
    _pending = null;
    if (_active != null && byId(_active!) == null) _active = null;
    if (!_disposed) notifyListeners();
  }

  /// Activates [id] (card highlighted; anchor scrolled into view).
  void activate(String? id, {bool reveal = true}) {
    if (id == _active) return;
    _active = id;
    if (reveal && id != null) {
      final s = byId(id);
      if (s != null) {
        final last = s.parts.last;
        session.revealRange(s.start, last.start + last.length);
      }
    }
    notifyListeners();
  }

  /// Activates the suggestion under a clicked caret (no scrolling).
  void activateAt(int offset) {
    final id = idAt(offset);
    if (id != null || _active != null) activate(id, reveal: false);
  }

  /// The suggestion covering [offset], if any (shortest wins).
  String? idAt(int offset) {
    String? best;
    var bestLength = _far;
    for (final s in pending) {
      for (final p in s.parts) {
        if (offset >= p.start && offset < p.start + p.length) {
          final length = s.parts.fold(0, (n, p) => n + p.length);
          if (length < bestLength) {
            best = s.id;
            bestLength = length;
          }
        }
      }
    }
    return best;
  }

  /// Accepts [ids] (`write.suggestions.accept`). Returns false when nothing
  /// was applied.
  bool accept(Set<String> ids) {
    if (!canDecide || ids.isEmpty) return false;
    return _apply(
      SuggestionOps.accept(session.editor.delta, ids),
      writeL10nOf(session.services).suggestionUndoAccept(ids.length),
    );
  }

  /// Rejects [ids] (`write.suggestions.reject`); the author's own
  /// suggestions are withdrawn.
  bool reject(Set<String> ids) {
    if (ids.isEmpty) return false;
    final infos = [for (final id in ids) ?byId(id)];
    if (infos.isEmpty || !infos.every(canReject)) return false;
    final own = infos.every(isOwn);
    final n = infos.length;
    final l = writeL10nOf(session.services);
    return _apply(
      SuggestionOps.reject(session.editor.delta, ids),
      own ? l.suggestionUndoWithdraw(n) : l.suggestionUndoReject(n),
    );
  }

  /// Accepts every pending suggestion (optionally by [authorUuid]).
  bool acceptAll({String? authorUuid}) {
    if (!canDecide) return false;
    final ids = SuggestionOps.pendingIds(
      session.editor.delta,
      authorUuid: authorUuid,
    );
    return accept(ids);
  }

  /// Rejects every pending suggestion (optionally by [authorUuid]).
  bool rejectAll({String? authorUuid}) {
    if (!canDecide) return false;
    final ids = SuggestionOps.pendingIds(
      session.editor.delta,
      authorUuid: authorUuid,
    );
    return reject(ids);
  }

  /// Number of pending suggestions (optionally by [authorUuid]).
  int count({String? authorUuid}) => authorUuid == null
      ? pending.length
      : pending.where((s) => s.by == authorUuid).length;

  bool _apply(Delta op, String label) {
    final ok = session.applyContentChange(
      op,
      label: label,
      bypassSuggesting: true,
    );
    if (ok) {
      _active = null;
      notifyListeners();
    }
    return ok;
  }

  /// Activates the next (or previous) suggestion after the caret
  /// (`write.suggestions.next` / `previous`).
  bool next({bool previous = false}) {
    final list = pending;
    if (list.isEmpty) return false;
    final active = _active == null ? null : byId(_active!);
    final from = active?.start ?? session.editor.selection?.anchor ?? 0;
    SuggestionInfo? target;
    if (previous) {
      for (final s in list.reversed) {
        if (s.start < from) {
          target = s;
          break;
        }
      }
      target ??= list.last;
    } else {
      for (final s in list) {
        if (s.start > from || (active == null && s.start == from)) {
          target = s;
          break;
        }
      }
      target ??= list.first;
    }
    _active = null;
    activate(target.id);
    return true;
  }

  /// Whether Suggesting mode is on.
  bool get suggesting => session.editor.mode == EditorMode.suggesting;

  @override
  void dispose() {
    _disposed = true;
    session.contentVersion.removeListener(_onContent);
    super.dispose();
  }
}

/// A large int that is exact on the VM and the web (`1 << n` with n ≥ 32
/// is 0 on the web).
const _far = 0x1FFFFFFFFFFFFF;
