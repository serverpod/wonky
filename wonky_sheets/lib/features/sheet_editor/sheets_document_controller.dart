import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show DriveItemKind, UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart' show SyncStatus;

import '../../l10n/sheets_l10n.dart';
import '../model/sheets_undo.dart';
import '../collab/sheets_collab.dart';
import 'sheet_editor_controller.dart';

/// The shell's view of an open spreadsheet (suite 03 §5): title, role, the
/// undo stack + `sheets.rows` handler, selection snapshots, Edit menu
/// contributions, zoom and MCP state. The [editor] is attached once the
/// workbook session is open.
class SheetsDocumentController extends DocumentController {
  SheetsDocumentController({
    required this.services,
    required this.itemUuid,
    this.title = '',
    this._role = Role.viewer,
  }) {
    _undo = SheetsRowsUndoHandler(
      () => editor!.session,
      onPartial: () =>
          services.toasts.show(sheetsL10nOf(services).toastUndoPartial),
    );
  }

  final ShellServices services;

  @override
  final UuidValue itemUuid;

  @override
  String title;

  Role _role;

  late final SheetsRowsUndoHandler _undo;

  SheetEditorController? _editor;

  /// The editor (null while the spreadsheet opens).
  SheetEditorController? get editor => _editor;

  @override
  DriveItemKind get kind => DriveItemKind.spreadsheet;

  @override
  Role get role {
    final e = _editor;
    if (e == null) return _role;
    final r = e.session.role.value;
    return r < _role ? r : _role;
  }

  @override
  bool get isLoaded => _editor != null;

  @override
  List<UndoHandler<UndoEntry>> get undoHandlers => [_undo];

  @override
  bool get persistUndo => true;

  void attach(SheetEditorController editor) {
    _editor?.removeListener(notifyListeners);
    _editor = editor;
    editor.itemRole = _role;
    editor.readOnlyView = _readOnlyView;
    editor.addListener(notifyListeners);
    editor.session.role.addListener(notifyListeners);
    notifyListeners();
  }

  void update({String? title, Role? role}) {
    if (title != null) this.title = title;
    if (role != null) {
      _role = role;
      _editor?.itemRole = role;
    }
    notifyListeners();
  }

  // ---- Collaboration (Sheets 10) ----

  PresenceSession? _presence;

  /// The shell's presence session of the file (cursor, hints, follow).
  PresenceSession? get presence => _presence;

  SheetsCollab? get _collab =>
      _editor == null ? null : SheetsCollab.of(_editor!);

  @override
  void attachPresence(PresenceSession? presence) {
    _presence = presence;
    _collab?.setPresence(presence);
  }

  @override
  CommentAnchorProvider? get commentAnchors => _collab?.comments;

  @override
  void revealParticipant(String sessionId, {int? userId}) => unawaited(
    _editor?.invokeCommand('sheets.presence.jumpTo', {'sessionId': sessionId}),
  );

  @override
  void followParticipant(String sessionId) => unawaited(
    _editor?.invokeCommand('sheets.presence.follow', {'sessionId': sessionId}),
  );

  // ---- Selection ----

  @override
  SelectionSnapshot? captureSelection() => _editor?.captureSelection();

  @override
  void restoreSelection(SelectionSnapshot selection) =>
      _editor?.restoreSelection(selection);

  @override
  String? get selectionSummary => _editor?.selection.describe();

  // ---- Edit menu ----

  @override
  bool get canCut =>
      (_editor?.canEdit ?? false) &&
      _editor!.selection.resolved.ranges.length == 1;

  @override
  bool get canCopy =>
      _editor != null && _editor!.selection.resolved.ranges.length == 1;

  @override
  bool get canPaste => _editor?.canEdit ?? false;

  @override
  bool get canSelectAll => _editor != null;

  @override
  Future<void> cut() async => _editor?.invokeCommand(
    'sheets.edit.cut',
    const {},
    InvocationSource.menu,
  );

  @override
  Future<void> copy() async => _editor?.invokeCommand(
    'sheets.edit.copy',
    const {},
    InvocationSource.menu,
  );

  @override
  Future<void> paste({bool plainText = false}) async => _editor?.invokeCommand(
    plainText ? 'sheets.edit.pasteSpecial' : 'sheets.edit.paste',
    plainText ? const {'mode': 'values'} : const {},
    InvocationSource.menu,
  );

  @override
  void selectAll() => unawaited(
    _editor?.invokeCommand(
      'sheets.select.all',
      const {},
      InvocationSource.menu,
    ),
  );

  @override
  Future<void> beforeUndo() async {
    final e = _editor;
    if (e != null && e.editor.isEditing) e.editor.cancel();
  }

  // ---- File ----

  /// Print and download go through `sheets.print.open` /
  /// `sheets.file.download` (11 §6–7, `commands/print_commands.dart`).
  @override
  bool get canPrint => _editor != null;

  @override
  Future<void> print() async {
    await _editor?.invokeCommand('sheets.print.open');
  }

  @override
  List<DownloadFormat> get downloadFormats {
    final l = sheetsL10nOf(services);
    return [
      DownloadFormat('xlsx', l.downloadXlsx),
      DownloadFormat('ods', l.downloadOds),
      DownloadFormat('pdf', l.downloadPdf),
      DownloadFormat('html', l.downloadHtml),
      DownloadFormat('csv', l.downloadCsv),
      DownloadFormat('tsv', l.downloadTsv),
    ];
  }

  @override
  Future<void> download(String format) async {
    await _editor?.invokeCommand('sheets.file.download', {'format': format});
  }

  // ---- View ----

  @override
  String get mode =>
      (_editor?.viewMode ?? !role.canEdit) ? 'viewing' : 'editing';

  @override
  double get zoom => _editor?.scroll.zoom ?? 1;

  @override
  void setZoom(double zoom) => _editor?.setZoom(zoom);

  @override
  void focusEditor() => _editor?.gridFocus.requestFocus();

  bool _readOnlyView = false;

  /// The mobile layout shows the spreadsheet read-only (suite 02 §6.1).
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
  Map<String, Object?> describeState() =>
      _editor?.describeState() ?? const {'loading': true};

  @override
  void onRoleChanged(Role role) {
    _role = role;
    _editor?.itemRole = role;
    if (!role.canEdit) _editor?.editor.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _editor?.removeListener(notifyListeners);
    super.dispose();
  }
}
