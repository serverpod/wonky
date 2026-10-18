import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        CommentAnchor,
        CommentAnchors,
        DeltaUtils,
        WonkyAttr,
        embedChar,
        softBreak;

import '../../l10n/write_l10n.dart';
import '../document/write_document_session.dart';
import '../editor/styles/write_stylesheet.dart' show CommentHighlightState;
import '../editor/view/editor_view_state.dart' show HighlightRange;

/// Anchor JSON of Write text-range threads (Write 08 §1.1): positions live
/// in the Delta (`cmt_<threadUuid>` attributes), not in the thread.
const writeAnchorJson = '{"v":1}';

/// Write's side of comments (Write 08 §1, §3): anchors in the Delta, the
/// shell's `CommentsController` for the threads.
///
/// - `CommentAnchorProvider` for the shell: the anchor of a new comment
///   (selection, or the word at the caret), adding the `cmt_*` attribute
///   when the thread is created (one undo step with the thread) and removing
///   it when the thread is deleted, positions for "sort by position",
///   revealing anchors;
/// - the pending range of the composer (dashed highlight, transformed
///   through remote edits until the comment is saved);
/// - highlights: resolved/orphaned threads hidden, the active thread;
/// - click-to-activate (caret inside an anchor), next/previous, re-attach
///   orphaned threads, document comments.
class WriteComments extends ChangeNotifier implements CommentAnchorProvider {
  WriteComments(this.session) {
    session.services.comments.addListener(_onControllerChanged);
    session.contentVersion.addListener(_onContent);
    session.editor.addListener(_onEditor);
    _onControllerChanged();
  }

  final WriteDocumentSession session;

  CommentsController? _controller;
  Map<String, CommentAnchor>? _anchors;
  (int, int)? _lastRange;
  bool _drafting = false;
  int _contentAtSelection = -1;
  Object? _lastCaret;
  bool _disposed = false;

  /// The shell's comments controller of this document (null on other
  /// screens).
  CommentsController? get controller => _controller;

  /// Anchors of every thread present in the document (by thread uuid).
  Map<String, CommentAnchor> get anchors =>
      _anchors ??= session.editor.overlays.anchors();

  /// Threads that should be listed with an anchor in the margin: open text
  /// threads (not suggestion threads), in document order.
  List<CommentThreadView> get anchoredOpenThreads {
    final c = _controller;
    if (c == null) return const [];
    final a = anchors;
    final list = [
      for (final t in c.threads)
        if (t.status == CommentStatus.open &&
            t.suggestionId == null &&
            t.anchorKind == CommentAnchorKind.textRange &&
            a.containsKey(t.uuid.uuid))
          t,
    ]..sort((x, y) => a[x.uuid.uuid]!.start.compareTo(a[y.uuid.uuid]!.start));
    return list;
  }

  /// Unresolved threads without a place in the text — comments on the whole
  /// document and threads whose text was deleted (orphaned). The margin
  /// lists them at the top of the document.
  List<CommentThreadView> get unanchoredThreads {
    final c = _controller;
    if (c == null) return const [];
    final a = anchors;
    return [
      for (final t in c.threads)
        if (t.suggestionId == null &&
            (t.status == CommentStatus.open ||
                t.status == CommentStatus.orphaned) &&
            !(t.anchorKind == CommentAnchorKind.textRange &&
                a.containsKey(t.uuid.uuid)))
          t,
    ];
  }

  /// Where the comment being written is anchored (a Delta offset; 0 for a
  /// comment on the whole document), or null when none is being written.
  int? get draftOffset {
    final draft = _controller?.draftAnchor;
    if (draft == null) return null;
    if (draft.kind != CommentAnchorKind.textRange) return 0;
    return _lastRange?.$1 ?? 0;
  }

  /// Whether the user may see comments (Viewers only when the owner allows
  /// it, suite 06).
  bool get visible =>
      session.currentRole.canComment ||
      (session.item?.viewersSeeComments ?? false);

  void _onContent() {
    _anchors = null;
    if (_controller != null) notifyListeners();
  }

  void _onControllerChanged() {
    final c = session.services.comments.value;
    final itemMatches = c != null && c.itemUuid == session.itemUuid;
    final next = itemMatches ? c : null;
    if (next != _controller) {
      _controller?.removeListener(_onThreadsChanged);
      _controller = next;
      next?.addListener(_onThreadsChanged);
      if (next != null) next.anchors = this;
    }
    _onThreadsChanged();
  }

  void _onThreadsChanged() {
    if (_disposed) return;
    final c = _controller;
    final view = session.editor.view;
    final hidden = <String>{
      for (final t in c?.threads ?? const <CommentThreadView>[])
        if (t.status != CommentStatus.open) t.uuid.uuid,
    };
    view.comments = CommentHighlightState(
      hiddenThreads: hidden,
      activeThread: c?.activeThreadUuid,
      visible: visible,
    );
    // Composer: show the pending range while a text draft is open.
    final draft = c?.draftAnchor;
    if (draft != null && !_drafting) {
      _drafting = true;
      final r = _lastRange;
      if (draft.kind == CommentAnchorKind.textRange && r != null) {
        view.pendingComment = HighlightRange(r.$1, r.$2);
      }
    } else if (draft == null && _drafting) {
      _drafting = false;
      view.pendingComment = null;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CommentAnchorProvider.

  @override
  NewCommentAnchor? anchorForSelection() {
    if (!session.isLoaded || !session.currentRole.canComment) return null;
    final range = selectionRange();
    if (range == null) return null;
    _lastRange = range;
    return NewCommentAnchor(
      kind: CommentAnchorKind.textRange,
      anchorJson: writeAnchorJson,
      quotedText: quoteOf(range.$1, range.$2),
    );
  }

  /// The range a new comment anchors to: the selection, or the word at a
  /// collapsed caret (an embed when the caret is on one); null when there is
  /// nothing to anchor to.
  (int, int)? selectionRange() {
    final sel = session.editor.selection;
    if (sel == null) return null;
    if (!sel.isCollapsed) {
      final max = session.editor.length - 1;
      final start = sel.start.clamp(0, max);
      final end = sel.end.clamp(0, max);
      return end > start ? (start, end) : null;
    }
    return _wordAt(sel.anchor);
  }

  (int, int)? _wordAt(int offset) {
    final mirror = session.editor.mirror;
    if (mirror.nodeCount == 0) return null;
    final index = mirror.indexAtOffset(offset.clamp(0, mirror.length - 1));
    final entry = mirror.entryAt(index);
    final start = mirror.startOfIndex(index);
    final ops = entry.delta.operations;
    if (ops.isNotEmpty && ops.first.data is Map) return (start, start + 1);
    final text = DeltaUtils.text(entry.delta);
    final local = (offset - start).clamp(0, text.length);
    bool isWord(int i) =>
        i >= 0 &&
        i < text.length &&
        RegExp(r'[\p{L}\p{N}_]', unicode: true).hasMatch(text[i]);
    var s = local;
    var e = local;
    while (isWord(s - 1)) {
      s--;
    }
    while (isWord(e)) {
      e++;
    }
    if (e <= s) return null;
    return (start + s, start + e);
  }

  /// The quoted text of `[start, end)` (≤ 500 characters, line ends as
  /// spaces).
  String quoteOf(int start, int end) {
    var q = DeltaUtils.text(session.editor.mirror.slice(start, end))
        .replaceAll(embedChar, '')
        .replaceAll(RegExp('[\n$softBreak]+'), ' ')
        .trim();
    if (q.length > CommentAnchors.maxQuote) {
      q = q.substring(0, CommentAnchors.maxQuote);
    }
    return q;
  }

  @override
  String? labelFor(CommentThreadView thread) {
    if (thread.anchorKind == CommentAnchorKind.document) {
      return writeL10nOf(session.services).commentWholeDocument;
    }
    return thread.quotedText;
  }

  @override
  num positionOf(CommentThreadView thread) {
    if (thread.anchorKind == CommentAnchorKind.document) return -1;
    return anchors[thread.uuid.uuid]?.start ?? _far;
  }

  @override
  void reveal(CommentThreadView thread) {
    final a = anchors[thread.uuid.uuid];
    if (a != null) session.revealRange(a.start, a.start + a.length);
  }

  @override
  void onThreadCreated(CommentThreadView thread) {
    final view = session.editor.view;
    final pending = view.pendingComment;
    view.pendingComment = null;
    _drafting = false;
    // Undo/redo re-adds the anchor through its own content entry.
    if (session.services.undo.isApplying) return;
    if (thread.anchorKind != CommentAnchorKind.textRange) return;
    if (anchors.containsKey(thread.uuid.uuid)) return;
    final range = pending != null
        ? (pending.isEmpty ? null : (pending.start, pending.end))
        : (_lastRange ?? selectionRange());
    _lastRange = null;
    final l = writeL10nOf(session.services);
    if (range == null) {
      session.services.toasts.show(
        l.commentSelectionDeleted,
        description: l.commentSavedWithoutPosition,
      );
      return;
    }
    session.applyContentChange(
      CommentAnchors.addAnchor(thread.uuid.uuid, range.$1, range.$2 - range.$1),
      label: l.commentUndoAdd,
    );
  }

  @override
  void onThreadDeleted(CommentThreadView thread) {
    if (session.services.undo.isApplying) return;
    removeAnchor(
      thread.uuid.uuid,
      label: writeL10nOf(session.services).commentUndoDelete,
    );
  }

  /// Removes every anchor of [threadUuid] (one undoable change).
  bool removeAnchor(String threadUuid, {required String label}) {
    if (!anchors.containsKey(threadUuid)) return false;
    final change = CommentAnchors.removeAnchor(
      session.editor.delta,
      threadUuid,
    );
    return session.applyContentChange(change, label: label);
  }

  @override
  String? get activeThreadUuid => _controller?.activeThreadUuid;

  // ---------------------------------------------------------------------------
  // Activation and navigation.

  /// The innermost (shortest) visible open thread covering [offset].
  String? threadAt(int offset) {
    final c = _controller;
    if (c == null || !visible) return null;
    String? best;
    var bestLength = _far;
    anchors.forEach((uuid, a) {
      final t = c.thread(uuid);
      if (t == null || t.status != CommentStatus.open) return;
      for (final r in a.ranges) {
        if (offset >= r.start && offset < r.end && a.length < bestLength) {
          best = uuid;
          bestLength = a.length;
        }
      }
    });
    return best;
  }

  /// Activates [threadUuid] (margin card expanded and aligned, highlight).
  void activate(String? threadUuid, {bool reveal = true}) {
    final c = _controller;
    if (c == null) return;
    if (reveal) {
      c.activate(threadUuid);
    } else {
      // CommentsController.activate also scrolls; avoid jumps on clicks.
      final saved = c.anchors;
      c.anchors = null;
      c.activate(threadUuid);
      c.anchors = saved;
    }
  }

  void _onEditor() {
    if (_disposed || !session.isLoaded) return;
    final sel = session.editor.selection;
    final caret = sel == null ? null : (sel.anchor, sel.head);
    // A content change notified together with the caret move means typing.
    final version = session.contentVersion.value;
    final typed = version != _contentAtSelection;
    _contentAtSelection = version;
    if (caret == _lastCaret) return;
    _lastCaret = caret;
    // Caret moves caused by typing never change the active card.
    if (typed || sel == null || !sel.isCollapsed) return;
    final thread = threadAt(sel.anchor);
    if (thread != null && thread != activeThreadUuid) {
      activate(thread, reveal: false);
    } else if (thread == null && activeThreadUuid != null) {
      final a = anchors[activeThreadUuid];
      final inside =
          a != null &&
          a.ranges.any((r) => sel.anchor >= r.start && sel.anchor <= r.end);
      if (!inside) activate(null, reveal: false);
    }
    session.suggestions.activateAt(sel.anchor);
  }

  /// Threads with anchors in document order (navigation).
  List<String> get _ordered {
    final c = _controller;
    final a = anchors;
    final ids = [
      for (final e in a.entries)
        if (c?.thread(e.key)?.status == CommentStatus.open) e.key,
    ]..sort((x, y) => a[x]!.start.compareTo(a[y]!.start));
    return ids;
  }

  /// Activates the next (or previous) open thread after the caret
  /// (`write.comments.next` / `previous`). Returns false when there is none.
  bool next({bool previous = false}) {
    final ids = _ordered;
    if (ids.isEmpty) return false;
    final a = anchors;
    final active = activeThreadUuid;
    final from = active != null && a.containsKey(active)
        ? a[active]!.start
        : (session.editor.selection?.anchor ?? 0);
    String? target;
    if (previous) {
      for (final id in ids.reversed) {
        if (a[id]!.start < from) {
          target = id;
          break;
        }
      }
      target ??= ids.last;
    } else {
      for (final id in ids) {
        if (a[id]!.start > from || (active == null && a[id]!.start == from)) {
          target = id;
          break;
        }
      }
      target ??= ids.first;
    }
    activate(target);
    return true;
  }

  /// Re-attaches [threadUuid] to the current selection
  /// (`write.comments.reattach`, Editors; an orphaned thread reopens).
  bool reattach(String threadUuid) {
    final range = selectionRange();
    if (range == null || !session.currentRole.canEdit) return false;
    var change = CommentAnchors.addAnchor(
      threadUuid,
      range.$1,
      range.$2 - range.$1,
    );
    if (anchors.containsKey(threadUuid)) {
      change = CommentAnchors.removeAnchor(
        session.editor.delta,
        threadUuid,
      ).compose(change);
    }
    return session.applyContentChange(
      change,
      label: writeL10nOf(session.services).commentUndoReattach,
    );
  }

  /// Opens the composer for a comment on the whole document
  /// (`write.comments.addDocumentComment`).
  void startDocumentComment() {
    final c = _controller;
    if (c == null || !session.currentRole.canComment) return;
    final host = session.services.commentsHost;
    if (host != null) host.isShown = true;
    c.startDraft(
      NewCommentAnchor(
        kind: CommentAnchorKind.document,
        anchorJson: writeAnchorJson,
        label: writeL10nOf(session.services).commentWholeDocument,
      ),
    );
  }

  /// Whether [threadUuid] has a `cmt_*` anchor in [document].
  static bool isAnchored(Delta document, String threadUuid) {
    final key = WonkyAttr.commentKey(threadUuid);
    return document.operations.any(
      (op) => op.attributes?.containsKey(key) ?? false,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    session.services.comments.removeListener(_onControllerChanged);
    session.contentVersion.removeListener(_onContent);
    session.editor.removeListener(_onEditor);
    _controller?.removeListener(_onThreadsChanged);
    if (_controller?.anchors == this) _controller!.anchors = null;
    super.dispose();
  }
}

/// A large int that is exact on the VM and the web (`1 << n` with n ≥ 32
/// is 0 on the web).
const _far = 0x1FFFFFFFFFFFFF;
