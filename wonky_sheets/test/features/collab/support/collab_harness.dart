import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show
        AccessRole,
        ActorKind,
        CommentAnchorKind,
        CommentEvent,
        CommentFilter,
        CommentStatus,
        CommentThreadView,
        CommentView,
        Participant,
        PresenceEvent,
        PresenceState,
        PresenceUpdate,
        UuidValue;
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_sheets/config/sheets_app_config.dart';
import 'package:wonky_sheets/features/collab/sheets_collab.dart';
import 'package:wonky_sheets/features/model/memory_workbook_session.dart';
import 'package:wonky_sheets/features/sheet_editor/sheet_editor_controller.dart';
import 'package:wonky_sheets/features/sheet_editor/sheets_document_controller.dart';
import 'package:wonky_sheets_core/model.dart' hide ActorKind;

const collabItemUuid = '01923456-789a-7bcd-8ef0-123456789abd';

/// A presence stream the test drives: records this window's updates and
/// emits server events.
class FakePresenceRepository implements PresenceRepository {
  final events = StreamController<PresenceEvent>.broadcast();
  final List<PresenceUpdate> updates = [];

  @override
  Stream<PresenceEvent> join(
    UuidValue itemUuid,
    Stream<PresenceUpdate> updates,
  ) {
    updates.listen(this.updates.add);
    return events.stream;
  }

  void emit(PresenceEvent e) => events.add(e);
}

/// In-memory comments with the server's basic semantics.
class FakeCommentRepository implements CommentRepository {
  final Map<String, CommentThreadView> threads = {};
  final events = StreamController<CommentEvent>.broadcast();
  int _next = 1;

  CommentThreadView _put(CommentThreadView t) => threads[t.uuid.uuid] = t;

  @override
  Future<List<CommentThreadView>> listThreads(
    UuidValue itemUuid, {
    CommentFilter filter = CommentFilter.all,
  }) async => threads.values.toList();

  @override
  Future<CommentThreadView> createThread({
    required UuidValue threadUuid,
    required UuidValue itemUuid,
    required CommentAnchorKind anchorKind,
    required String anchorJson,
    String? quotedText,
    required String body,
    List<int> mentions = const [],
    int? assigneeId,
  }) async => _put(
    CommentThreadView(
      uuid: threadUuid,
      itemUuid: itemUuid,
      anchorKind: anchorKind,
      anchorJson: anchorJson,
      quotedText: quotedText,
      status: CommentStatus.open,
      createdBy: TestUsers.anna,
      createdAt: DateTime.utc(2026, 10, 1),
      comments: [_comment(threadUuid, body)],
    ),
  );

  CommentView _comment(UuidValue thread, String body) => CommentView(
    id: _next++,
    threadUuid: thread,
    author: TestUsers.anna,
    authorKind: ActorKind.user,
    body: body,
    mentions: const [],
    reactions: const {},
    createdAt: DateTime.utc(2026, 10, 1),
    deleted: false,
  );

  @override
  Future<CommentThreadView> reply(
    UuidValue threadUuid, {
    required String body,
    List<int> mentions = const [],
    UuidValue? commentUuid,
  }) async {
    final t = threads[threadUuid.uuid]!;
    return _put(
      t.copyWith(comments: [...t.comments, _comment(threadUuid, body)]),
    );
  }

  @override
  Future<CommentView> edit(int commentId, String body) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int commentId) async {}

  @override
  Future<void> deleteThread(UuidValue threadUuid) async =>
      threads.remove(threadUuid.uuid);

  @override
  Future<CommentThreadView> resolve(UuidValue threadUuid) async =>
      _put(threads[threadUuid.uuid]!.copyWith(status: CommentStatus.resolved));

  @override
  Future<CommentThreadView> reopen(UuidValue threadUuid) async =>
      _put(threads[threadUuid.uuid]!.copyWith(status: CommentStatus.open));

  @override
  Future<CommentView> react(int commentId, String emoji) =>
      throw UnimplementedError();

  @override
  Future<CommentThreadView> updateAnchor(
    UuidValue threadUuid,
    String anchorJson,
  ) async => _put(threads[threadUuid.uuid]!.copyWith(anchorJson: anchorJson));

  @override
  Stream<CommentEvent> watch(UuidValue itemUuid) => events.stream;
}

/// A remote participant.
Participant participant(
  String sessionId, {
  int userId = 2,
  String name = 'Bo Stone',
  String? cursorJson,
  PresenceState state = PresenceState.active,
  String mode = 'editing',
  int colorIndex = 3,
}) => Participant(
  sessionId: sessionId,
  userId: userId,
  userUuid: UuidValue.fromString(
    '00000000-0000-4000-8000-${userId.toRadixString(16).padLeft(12, '0')}',
  ),
  displayName: name,
  colorIndex: colorIndex,
  role: AccessRole.editor,
  actorKind: ActorKind.user,
  state: state,
  mode: mode,
  cursorJson: cursorJson,
  joinedAt: DateTime.utc(2026, 10, 1),
);

/// A blank in-memory spreadsheet with presence (driven by a fake stream),
/// comments (in memory) and the collaboration features attached.
class CollabHarness {
  CollabHarness._(
    this.h,
    this.presenceRepo,
    this.commentRepo,
    this.session,
    this.doc,
    this.editor,
    this.presence,
    this.comments,
    this.collab,
  );

  /// Opens the harness on a blank in-memory spreadsheet, or on [session]
  /// (item [collabItemUuid]).
  static Future<CollabHarness> open({
    Role role = Role.owner,
    WorkbookSessionBase? session,
  }) async {
    final presenceRepo = FakePresenceRepository();
    final commentRepo = FakeCommentRepository();
    final h = CommandTestHarness(
      config: const SheetsAppConfig(),
      presence: presenceRepo,
      comments: commentRepo,
    );
    final uuid = UuidValue.fromString(collabItemUuid);
    final item = h.drive.seed(name: 'Budget', uuid: uuid);
    h.services.currentItem.value = item;
    session ??= MemoryWorkbookSession.blank(itemUuid: uuid, role: role);
    final doc = SheetsDocumentController(
      services: h.services,
      itemUuid: uuid,
      title: 'Budget',
    )..update(role: role);
    final editor = SheetEditorController(
      services: h.services,
      session: session,
    );
    doc.attach(editor);
    h.services.activate(doc);
    final comments = CommentsController(services: h.services, itemUuid: uuid);
    h.services.comments.value = comments;
    final presence = PresenceSession(services: h.services, itemUuid: uuid)
      ..mode = 'editing';
    presence.start();
    final collab = SheetsCollab.attach(editor, presence: presence);
    doc.attachPresence(presence);
    await comments.start();
    await pumpEventQueue();
    return CollabHarness._(
      h,
      presenceRepo,
      commentRepo,
      session,
      doc,
      editor,
      presence,
      comments,
      collab,
    );
  }

  final CommandTestHarness h;
  final FakePresenceRepository presenceRepo;
  final FakeCommentRepository commentRepo;
  final WorkbookSessionBase session;
  final SheetsDocumentController doc;
  final SheetEditorController editor;
  final PresenceSession presence;
  final CommentsController comments;
  final SheetsCollab collab;

  ShellServices get services => h.services;
  WorkbookModel get model => session.model;
  String get sheetId => editor.activeSheetId;
  SheetModel get sheet => editor.activeSheet!;

  Future<CommandResult> run(
    String id, [
    Map<String, Object?> args = const {},
  ]) => h.invoke(id, args, InvocationSource.ui);

  Future<void> type(String a1, String input) =>
      run('sheets.cell.setInput', {'a1': a1, 'input': input});

  Future<void> select(String a1) => run('sheets.select.range', {'a1': a1});

  String text(String a1) {
    final r = model.parseA1(a1, contextSheetId: sheetId);
    return editor.cells.displayAt(sheetId, r.rect.top, r.rect.left)?.text ?? '';
  }

  /// Row/column ids of [a1] on the active sheet.
  (String, String) ids(String a1) {
    final r = model.parseA1(a1, contextSheetId: sheetId);
    return (sheet.rows.idAt(r.rect.top), sheet.columns.idAt(r.rect.left));
  }

  Future<void> dispose() async {
    collab.dispose();
    presence.dispose();
    comments.dispose();
    services.deactivate(doc);
    editor.dispose();
    await session.dispose();
    await h.dispose();
  }
}
