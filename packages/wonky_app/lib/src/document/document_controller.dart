import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue, DriveItemKind;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../comments/comment_anchor.dart';
import '../presence/presence_session.dart';
import '../undo/undo_service.dart';

/// The contract between the shell and an open document (Write's
/// `WriteDocumentController`, Sheets' `SheetEditorController`).
///
/// The editor screen makes its controller active with `DocumentScope`; shell
/// commands (`shell.edit.*`, comments, versions, view) then delegate to it
/// through `CommandContext.document`. Defaults make every capability
/// optional, so apps override only what they support.
abstract class DocumentController extends ChangeNotifier {
  /// The drive item of the document.
  UuidValue get itemUuid;

  DriveItemKind get kind;

  /// The current title (drive item name).
  String get title;

  /// The user's effective role on the document.
  Role get role;

  /// Whether content is loaded and editable/viewable.
  bool get isLoaded => true;

  /// The undo stack of this document (one per document).
  UndoStackKey get undoStackKey => UndoStackKey(itemUuid.uuid);

  /// Undo handlers of the document's domains; registered with the
  /// `UndoService` while the document is active.
  List<UndoHandler<UndoEntry>> get undoHandlers => const [];

  /// Persist the undo stack locally (best effort, suite 08 §3.1).
  bool get persistUndo => true;

  // ---- Selection (restored by undo/redo) ----

  SelectionSnapshot? captureSelection() => null;

  void restoreSelection(SelectionSnapshot selection) {}

  /// Short text for MCP `ui.get_state` ("B4:C9", "12 words selected").
  String? get selectionSummary => null;

  // ---- Edit menu contributions (shell.edit.*) ----

  bool get canCut => false;
  bool get canCopy => false;
  bool get canPaste => role.canEdit;
  bool get canSelectAll => true;

  Future<void> cut() async {}
  Future<void> copy() async {}

  /// [plainText]: Paste without formatting.
  Future<void> paste({bool plainText = false}) async {}
  void selectAll() {}

  /// Called by `shell.edit.undo` before undoing (e.g. Write commits an IME
  /// composition first).
  Future<void> beforeUndo() async {}

  /// Called by `shell.edit.redo` before redoing (e.g. Slides writes pending
  /// typing first).
  Future<void> beforeRedo() async {}

  // ---- File menu contributions ----

  /// Formats offered under File › Download (`docx`, `pdf`, `xlsx` …) with
  /// their labels.
  List<DownloadFormat> get downloadFormats => const [];

  /// Downloads/exports the document as [format].
  Future<void> download(String format) async {}

  bool get canPrint => false;

  /// Opens the print preview (`/d/:uuid/print`).
  Future<void> print() async {}

  // ---- View ----

  /// Editing / Suggesting / Viewing (apps define the ids).
  String get mode => role.canEdit ? 'editing' : 'viewing';

  double get zoom => 1;
  void setZoom(double zoom) {}

  /// Focuses the document surface (Esc from toolbar/panels).
  void focusEditor() {}

  /// Called by `EditorScaffold` when its mobile layout (suite 02 §6.1)
  /// starts or ends: while [readOnly] the document must not be editable,
  /// whatever the role and the View › Mode (apps fold it into their view
  /// mode); ending it restores the mode the user had. Layout, not a change
  /// of the document: nothing to undo.
  void setReadOnlyView(bool readOnly) {}

  // ---- Sync ----

  /// The document's sync status (title row and status bar).
  ValueListenable<SyncStatus> get syncStatus => _savedStatus;
  static final _savedStatus = ValueNotifier(SyncStatus.saved);

  Future<void> retrySync() async {}

  // ---- Collaboration hooks ----

  /// Creates anchors for new comments and maps anchors to positions.
  CommentAnchorProvider? get commentAnchors => null;

  /// Scrolls to another participant's cursor (presence avatar click).
  /// [sessionId] is the presence-stream session, which differs from the
  /// document stream's session id; [userId] identifies the participant's
  /// user so the editor can find their caret.
  void revealParticipant(String sessionId, {int? userId}) {}

  /// Follows another participant (avatar long-press / right-click, or its
  /// tooltip menu); Sheets tracks their sheet and viewport.
  void followParticipant(String sessionId) {}

  /// The editor scaffold's presence session of this file (null when it
  /// closes). Sheets sends its cursor and commit hints through it.
  void attachPresence(PresenceSession? presence) {}

  /// Cursor JSON sent with presence updates (Sheets; Write uses its own
  /// document stream).
  String? get presenceCursorJson => null;

  /// Extra state for MCP `ui.get_state`.
  Map<String, Object?> describeState() => const {};

  /// Called when the user's role changes while editing (suite 03 §4).
  void onRoleChanged(Role role) {}
}

/// A download format of File › Download.
class DownloadFormat {
  const DownloadFormat(this.id, this.label);

  /// Format id passed to `shell.file.download {format}`.
  final String id;

  /// Menu label ("Microsoft Word (.docx)").
  final String label;
}

/// Makes [controller] the active document while this widget is mounted.
class DocumentScope extends StatefulWidget {
  const DocumentScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final DocumentController controller;
  final Widget child;

  @override
  State<DocumentScope> createState() => _DocumentScopeState();
}

/// Registered by the shell; DocumentScope talks to it.
abstract class ActiveDocumentHost {
  void activate(DocumentController controller);
  void deactivate(DocumentController controller);
}

/// Provides the [ActiveDocumentHost] to [DocumentScope]s.
class ActiveDocumentHostScope extends InheritedWidget {
  const ActiveDocumentHostScope({
    super.key,
    required this.host,
    required super.child,
  });

  final ActiveDocumentHost host;

  static ActiveDocumentHost? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ActiveDocumentHostScope>()?.host;

  @override
  bool updateShouldNotify(ActiveDocumentHostScope oldWidget) =>
      oldWidget.host != host;
}

class _DocumentScopeState extends State<DocumentScope> {
  ActiveDocumentHost? _host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = ActiveDocumentHostScope.maybeOf(context);
    if (host != _host) {
      _host?.deactivate(widget.controller);
      _host = host;
      host?.activate(widget.controller);
    }
  }

  @override
  void didUpdateWidget(DocumentScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _host?.deactivate(oldWidget.controller);
      _host?.activate(widget.controller);
    }
  }

  @override
  void dispose() {
    _host?.deactivate(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A minimal [DocumentController] for screens without a real editor yet
/// (placeholders, read-only previews): item identity and role only.
class BasicDocumentController extends DocumentController {
  BasicDocumentController({
    required this.itemUuid,
    required this.kind,
    this.title = '',
    this.role = Role.viewer,
  });

  @override
  final UuidValue itemUuid;
  @override
  final DriveItemKind kind;
  @override
  String title;
  @override
  Role role;

  @override
  bool get persistUndo => false;

  /// Updates title/role from the loaded drive item.
  void update({String? title, Role? role}) {
    if (title != null) this.title = title;
    if (role != null) this.role = role;
    notifyListeners();
  }
}
