import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show DriveItemKind, UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoHandler;
import 'package:wonky_ui/wonky_ui.dart' show SyncStatus;

import '../elements/code/code_blocks.dart';
import '../../l10n/slides_l10n.dart';
import '../canvas/slide_canvas_controller.dart' show selectionOf;
import '../collab/slides_collab.dart';
import '../comments/slides_comments.dart';
import '../navigator/navigator_controller.dart' show navigatorOf;
import '../outline_view/outline_controller.dart' show outlineOf;
import '../text_editing/text_editing_host.dart' show textEditingOf;
import '../undo/server_change_undo.dart';
import 'deck_editor_controller.dart';

/// The shell's view of an open presentation (suite 03 §5, Slides 04 §2):
/// title, role, the undo stack with the `slides.rows` handler, selection
/// snapshots, zoom, sync status and MCP state. The [editor] is attached
/// once the deck session is ready.
class DeckDocumentController extends DocumentController {
  DeckDocumentController({
    required this.services,
    required this.itemUuid,
    this.title = '',
    this._role = Role.viewer,
    this.persistUndo = true,
  }) {
    undo = SlidesRowsUndoHandler(
      () => editor!.session,
      onPartial: () {
        partialUndos++;
        services.toasts.show(slidesL10nOf(services).toastUndoPartial);
      },
    );
  }

  final ShellServices services;

  @override
  final UuidValue itemUuid;

  @override
  String title;

  @override
  final bool persistUndo;

  Role _role;

  /// The `slides.rows` undo handler (02 §12.2).
  late final SlidesRowsUndoHandler undo;

  /// How often an undo skipped columns a collaborator changed (tests).
  int partialUndos = 0;

  DeckEditorController? _editor;

  /// The editor (null while the deck opens).
  DeckEditorController? get editor => _editor;

  @override
  DriveItemKind get kind => DriveItemKind.presentation;

  @override
  Role get role => _editor?.role ?? _role;

  @override
  bool get isLoaded => _editor != null;

  /// The `slides.serverChange` handler (AI runs, restores; SL-43).
  late final SlidesServerChangeHandler serverChanges =
      SlidesServerChangeHandler(services);

  @override
  List<UndoHandler<UndoEntry>> get undoHandlers => [undo, serverChanges];

  /// Attaches the editor of the opened deck.
  void attach(DeckEditorController editor) {
    _editor?.removeListener(notifyListeners);
    _editor = editor;
    editor.itemRole = _role;
    editor.readOnlyView = _readOnlyView;
    editor.addListener(notifyListeners);
    notifyListeners();
  }

  // ---- Collaboration (09 §1–§2; SL-21) ----

  /// The Slides comment anchors (09 §3; SL-38).
  @override
  CommentAnchorProvider? get commentAnchors {
    final ed = _editor;
    return ed == null ? null : SlidesComments.of(ed);
  }

  PresenceSession? _presence;

  /// The shell's presence session of the file (cursor, hints, follow).
  PresenceSession? get presence => _presence;

  @override
  void attachPresence(PresenceSession? presence) {
    _presence = presence;
    final ed = _editor;
    if (ed != null) SlidesCollab.of(ed)?.setPresence(presence);
  }

  @override
  void revealParticipant(String sessionId, {int? userId}) => unawaited(
    _editor?.invokeCommand('slides.presence.jumpTo', {'sessionId': sessionId}),
  );

  @override
  void followParticipant(String sessionId) => unawaited(
    _editor?.invokeCommand('slides.presence.follow', {'sessionId': sessionId}),
  );

  void update({String? title, Role? role}) {
    if (title != null) this.title = title;
    if (role != null) {
      _role = role;
      _editor?.itemRole = role;
    }
    notifyListeners();
  }

  // ---- Selection ----

  @override
  SelectionSnapshot? captureSelection() => _editor?.captureSelection();

  @override
  void restoreSelection(SelectionSnapshot selection) =>
      _editor?.restoreSelection(selection);

  @override
  String? get selectionSummary => _editor?.describeSelection();

  // ---- Edit menu ----
  //
  // The shell's Cut/Copy/Paste/Paste without formatting run the Slides
  // clipboard commands (SL-18, 03 §12): they act on the body being edited,
  // the selected table cells, the canvas selection, or — when the
  // navigator owns the clipboard — slides and groups (SL-16, 04 §5.8).

  bool _enabled(String id) =>
      _editor != null && services.dispatcher.stateOf(id).enabled;

  Future<void> _run(String id, [Map<String, Object?> args = const {}]) async {
    await _editor?.invokeCommand(id, args, InvocationSource.menu);
  }

  @override
  bool get canCut => _enabled('slides.edit.cut');

  @override
  bool get canCopy => _enabled('slides.edit.copy');

  @override
  bool get canPaste => _enabled('slides.edit.paste');

  @override
  Future<void> cut() => _run('slides.edit.cut');

  @override
  Future<void> copy() => _run('slides.edit.copy');

  @override
  Future<void> paste({bool plainText = false}) =>
      _run('slides.edit.paste', {if (plainText) 'plainText': true});

  /// Mod+A on the canvas selects every unlocked, visible element of the
  /// selection scope (03 §3.3; SL-12); while editing text, all text of the
  /// body (SL-13). The navigator scope extends this (SL-16).
  @override
  bool get canSelectAll => _editor != null;

  @override
  void selectAll() {
    final ed = _editor;
    if (ed == null) return;
    final text = textEditingOf(ed).active;
    if (text != null) {
      text.selectAll();
      return;
    }
    // The navigator or grid view selects every slide (04 §5.9; SL-16).
    if (ed.mode == DeckViewMode.grid || ed.navigatorFocus.hasFocus) {
      navigatorOf(ed).selectAll();
      return;
    }
    selectionOf(ed).selectAll();
  }

  // ---- Undo ----

  /// Pending typing is written first, so menu, toolbar, palette and MCP
  /// undo/redo see the burst as its own step (03 §6.1, SL-13).
  @override
  Future<void> beforeUndo() async {
    final ed = _editor;
    if (ed != null) {
      textEditingOf(ed).commit();
      CodeBlockView.maybeOf(ed)?.commitEdit();
      await outlineOf(ed).commitTyping();
    }
  }

  @override
  Future<void> beforeRedo() async {
    final ed = _editor;
    if (ed != null) {
      textEditingOf(ed).commit();
      CodeBlockView.maybeOf(ed)?.commitEdit();
      await outlineOf(ed).commitTyping();
    }
  }

  // ---- View ----

  @override
  String get mode =>
      (_editor?.viewMode ?? !role.canEdit) ? 'viewing' : 'editing';

  @override
  double get zoom => _editor?.zoom ?? 1;

  @override
  void setZoom(double zoom) => _editor?.setZoom(zoom);

  @override
  void focusEditor() => _editor?.canvasFocus.requestFocus();

  bool _readOnlyView = false;

  /// The mobile layout shows the deck read-only (suite 02 §6.1, 04 §16).
  @override
  void setReadOnlyView(bool readOnly) {
    if (readOnly == _readOnlyView) return;
    _readOnlyView = readOnly;
    _editor?.readOnlyView = readOnly;
    notifyListeners();
  }

  // ---- Sync ----

  @override
  ValueListenable<SyncStatus> get syncStatus =>
      _editor?.session.syncStatus ?? super.syncStatus;

  @override
  Map<String, Object?> describeState() {
    final ed = _editor;
    if (ed == null) return const {'loading': true};
    return {
      ...ed.describeState(),
      ...?SlidesCollab.of(ed)?.describeState(),
      ...?SlidesComments.of(ed)?.describeState(),
    };
  }

  @override
  void onRoleChanged(Role role) {
    _role = role;
    _editor?.itemRole = role;
    notifyListeners();
  }

  @override
  void dispose() {
    _editor?.removeListener(notifyListeners);
    super.dispose();
  }
}
