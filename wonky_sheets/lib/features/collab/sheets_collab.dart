import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show Participant, PresenceNotice;
import 'package:wonky_revlog/apply.dart' show RevRejectReason;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart'
    show RevGroupRejection;
import 'package:wonky_sheets_core/model.dart';

import '../comments/comment_indicator_layer.dart';
import '../comments/sheets_comments.dart';
import '../history/cell_history.dart';
import '../history/local_conflicts.dart';
import '../model/sheets_undo.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import '../revlog/logged_workbook_session.dart';
import 'hints/commit_hints.dart';
import 'hints/pending_hint_layer.dart';
import 'presence/remote_presence_layer.dart';
import 'presence/sheets_presence_controller.dart';

/// The collaboration features of one open spreadsheet editor (Sheets 10):
/// presence (cursors, tab dots, jump/follow), commit hints, comments
/// (anchors, indicators, cards), the cell history popover and remote
/// change toasts. Attached to the editor by the editor screen; found with
/// [SheetsCollab.of].
class SheetsCollab {
  SheetsCollab._(this.editor)
    : presence = SheetsPresenceController(editor),
      hints = CommitHints(editor),
      comments = SheetsComments(editor) {
    conflicts = SheetsConflicts(editor, names: _nameOfUser);
    _presenceLayer = RemotePresenceLayer(
      presence,
      colors,
      typingLabel: () => editor.l10n.presenceTyping,
      nameOf: (c) => participantLabel(c.participant),
    );
    hints.onTyping = presence.setTyping;
    _commentLayer = CommentIndicatorLayer(comments);
    _pendingLayer = PendingHintLayer(
      hints,
      colors,
      (id) => presence.presence?.participants
          .where((p) => p.sessionId == id)
          .firstOrNull
          ?.colorIndex,
    );
    editor.layers
      ..add(_presenceLayer)
      ..add(_commentLayer)
      ..add(_pendingLayer);
    editor.selection.addListener(_onSelection);
    editor.onEditedCellDeleted = (s, r, c) =>
        unawaited(editedCellDeleted(s, r, c));
    comments.addListener(_openDeepLinkedComment);
    _deepLinkComment = _commentParam();
    final session = editor.session;
    if (session is LoggedWorkbookSession) {
      _rejections = session.groupRejected.listen(onGroupRejected);
    }
  }

  StreamSubscription<RevGroupRejection>? _rejections;

  String? _deepLinkComment;

  String? _commentParam() {
    try {
      return services
          .router
          .routerDelegate
          .currentConfiguration
          .uri
          .queryParameters['comment'];
    } catch (_) {
      return null;
    }
  }

  /// `?comment=<threadUuid>` (Sheets 10 §3.4): activates the sheet, scrolls
  /// to the cell and opens the thread once the threads are loaded.
  void _openDeepLinkedComment() {
    final id = _deepLinkComment;
    final c = comments.controller;
    if (id == null || c == null || c.loading) return;
    _deepLinkComment = null;
    if (c.thread(id) == null) return;
    services.panels.open(ShellPanels.comments);
    c.activate(id);
  }

  static final Expando<SheetsCollab> _of = Expando('sheetsCollab');

  /// The collaboration features of [editor] (null when not attached, e.g.
  /// the read-only version grid).
  static SheetsCollab? of(SheetEditorController editor) => _of[editor];

  /// Creates the collaboration features of [editor].
  static SheetsCollab attach(
    SheetEditorController editor, {
    PresenceSession? presence,
  }) {
    final c = SheetsCollab._(editor);
    _of[editor] = c;
    c.setPresence(presence);
    return c;
  }

  final SheetEditorController editor;
  final SheetsPresenceController presence;
  final CommitHints hints;
  final SheetsComments comments;

  /// Overwritten offline edits (Sheets 10 §9).
  late final SheetsConflicts conflicts;

  String? _nameOfUser(String userUuid) {
    for (final p in presence.presence?.participants ?? const <Participant>[]) {
      if (p.userUuid.uuid == userUuid && p.actorKind.name == 'user') {
        return p.displayName;
      }
    }
    return null;
  }

  /// Theme colors of the layers (set by the overlay widget on build).
  final CollabPaintColors colors = CollabPaintColors();

  /// The cell whose edit history popover is open.
  final ValueNotifier<CellHistoryController?> cellHistory = ValueNotifier(null);

  /// Whether the docked thread card of the active cell is dismissed (until
  /// the active cell changes).
  final ValueNotifier<bool> dockedDismissed = ValueNotifier(false);

  late final RemotePresenceLayer _presenceLayer;
  late final CommentIndicatorLayer _commentLayer;
  late final PendingHintLayer _pendingLayer;
  StreamSubscription<PresenceNotice>? _notices;
  PresenceSession? _session;
  (String, String)? _lastActive;
  bool _disposed = false;

  ShellServices get services => editor.services;

  /// The display label of a participant: agents (MCP/AI writes) show as
  /// "Claude via MCP (Anna)" / "Assistant (Anna)" (Sheets 10 §1.2).
  String participantLabel(Participant p) {
    final l = editor.l10n;
    return switch (p.actorKind.name) {
      'mcp' => l.actorViaMcp(p.displayName),
      'ai' => l.actorViaAi(p.displayName),
      'script' => l.actorViaScript(p.displayName),
      _ => p.displayName,
    };
  }

  /// Attaches the shell's presence session of the file (null detaches).
  void setPresence(PresenceSession? session) {
    if (identical(session, _session)) return;
    _session = session;
    presence.attach(session);
    hints.attach(session);
    unawaited(_notices?.cancel());
    _notices = session?.notices.listen(_onNotice);
  }

  void _onSelection() {
    final sel = editor.selection.selection;
    final key = (sel.sheetId, '${sel.active.rowId}|${sel.active.colId}');
    if (key != _lastActive) {
      _lastActive = key;
      dockedDismissed.value = false;
      final h = cellHistory.value;
      if (h != null) {
        cellHistory.value = null;
        h.dispose();
      }
    }
  }

  void _onNotice(PresenceNotice n) {
    if (_disposed) return;
    Map<String, Object?> p;
    try {
      p = (jsonDecode(n.payloadJson) as Map).cast<String, Object?>();
    } on Object {
      p = const {};
    }
    switch (n.kind) {
      case 'versionRestored':
        if (p['userId'] == services.me?.id) return;
        services.toasts.show(
          editor.l10n.toastVersionRestoredBy('${p['name'] ?? ''}'),
        );
    }
  }

  // ------------------------------------------------- cell history popover

  /// Opens the edit history of the active cell (top-left of a merge).
  bool showCellHistory({int? row, int? col}) {
    final sheet = editor.activeSheet;
    if (sheet == null) return false;
    final sel = editor.selection.resolved;
    var r = row ?? sel.activeRow;
    var c = col ?? sel.activeCol;
    final m = sheet.mergeAt(r, c);
    if (m != null) {
      r = m.top;
      c = m.left;
    }
    final rowId = sheet.rows.tryIdAt(r);
    final colId = sheet.columns.tryIdAt(c);
    if (rowId == null || colId == null) return false;
    final old = cellHistory.value;
    cellHistory.value = cellHistoryFor(
      editor,
      CellHistoryTarget(sheet.id, rowId, colId),
    );
    old?.dispose();
    return true;
  }

  void closeCellHistory() {
    final h = cellHistory.value;
    cellHistory.value = null;
    h?.dispose();
    editor.gridFocus.requestFocus();
  }

  // ------------------------------------------------- rejected changes

  /// The server rejected a group (RevLog spec 06 §4.6): the model is
  /// already rolled back; the plan's undo step is removed when it is the
  /// top one (a buried step's undo finds nothing to revert and is skipped
  /// by the per-column rule), and one toast says why.
  @visibleForTesting
  void onGroupRejected(RevGroupRejection r) {
    if (_disposed) return;
    final stack = UndoStackKey(editor.session.itemUuid.uuid);
    final steps = services.undo.undoStepsOf(stack);
    if (steps.isNotEmpty) {
      final top = steps.last;
      final hit = top.entries.any(
        (e) => e is SheetsRowsUndoEntry && e.groupId == r.groupId,
      );
      if (hit) services.undo.discardTop(top.id, stack: stack);
    }
    final l = editor.l10n;
    final label = r.ops.first.label;
    debugPrint(
      'Change rejected (${r.rejection.reason.name}, group ${r.groupId}): '
      '${r.rejection.message}',
    );
    services.toasts.show(switch (r.rejection.reason) {
      RevRejectReason.protectedRange => l.toastChangeProtected(label),
      RevRejectReason.forbiddenForRole ||
      RevRejectReason.forbidden => l.toastChangeNoAccess,
      _ => l.toastChangeNotSaved(label, r.rejection.message),
    });
  }

  // ---------------------------------------------- remote change toasts

  /// "The row you were editing was deleted by Bo." (03 §15.3): looks up the
  /// deleting user in the synced change log.
  Future<void> editedCellDeleted(
    String sheetId,
    String rowId,
    String colId,
  ) async {
    final l = editor.l10n;
    String? name;
    try {
      name = await _deleterOf(sheetId, rowId, colId);
    } catch (e) {
      debugPrint('Finding who deleted the row failed: $e');
    }
    if (_disposed) return;
    services.toasts.show(
      name == null ? l.toastEditedRowDeleted : l.toastEditedRowDeletedBy(name),
    );
  }

  Future<String?> _deleterOf(String sheetId, String rowId, String colId) async {
    final session = editor.session;
    if (session is! LoggedWorkbookSession) return null;
    // The ops of the last hour (RevLog spec 06 §7.1), newest first.
    final logs = (await session.recentOps(const Duration(hours: 1))).reversed;
    for (final log in logs) {
      final summary = log.summary;
      if (summary == null) continue;
      final s = ChangeSummary.fromJson(summary);
      final hit =
          (s.deleted['rows'] ?? const []).contains(rowId) ||
          (s.deleted['cols'] ?? const []).contains(colId) ||
          (s.deleted['sheets'] ?? const []).contains(sheetId);
      if (!hit) continue;
      final uuid = log.authorUuid;
      if (uuid == null || uuid == session.userId) return null;
      for (final p
          in presence.presence?.participants ?? const <Participant>[]) {
        if (p.userUuid.uuid == uuid) return p.displayName;
      }
      return editor.l10n.someone;
    }
    return null;
  }

  void dispose() {
    _disposed = true;
    unawaited(_notices?.cancel());
    unawaited(_rejections?.cancel());
    editor.selection.removeListener(_onSelection);
    comments.removeListener(_openDeepLinkedComment);
    editor.onEditedCellDeleted = null;
    editor.layers
      ..remove(_presenceLayer)
      ..remove(_commentLayer)
      ..remove(_pendingLayer);
    presence.dispose();
    hints.dispose();
    comments.dispose();
    conflicts.dispose();
    cellHistory.value?.dispose();
    cellHistory.dispose();
    dockedDismissed.dispose();
    _of[editor] = null;
  }
}
