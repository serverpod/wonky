import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' show pumpEventQueue;
import 'package:go_router/go_router.dart';
import 'package:wonky_app/spellcheck.dart' show ShellSpelling;
import 'package:wonky_app/testing.dart'
    show FakePublicationRepository, noSpellDictionaries;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write/features/document/write_document_api.dart';
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/sync/sync_transport.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../sync/support/fake_document_server.dart';

const itemUuid = '00000000-0000-7000-8000-0000000000a1';
const documentUuid = '00000000-0000-7000-8000-0000000000d1';

UserSummary userSummary(int id) => UserSummary(
  id: id,
  uuid: UuidValue.fromString('00000000-0000-7000-8000-00000000000$id'),
  displayName: 'User $id',
  email: 'user$id@example.test',
  avatarColor: '#336699',
  colorIndex: id % 12,
);

DriveItemView driveItem({AccessRole role = AccessRole.editor}) => DriveItemView(
  uuid: UuidValue.fromString(itemUuid),
  kind: DriveItemKind.document,
  name: 'Plan',
  contentRef: UuidValue.fromString(documentUuid),
  owner: userSummary(1),
  role: role,
  shared: true,
  sizeBytes: 0,
  createdAt: DateTime.utc(2026),
  modifiedAt: DateTime.utc(2026),
  starred: false,
  pinnedOffline: false,
  editorsCanShare: true,
  nonEditorsCanExport: true,
  viewersSeeComments: true,
);

class _Unimplemented {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeAuth extends ChangeNotifier with _NoSuch implements AuthRepository {
  @override
  bool get isSignedIn => true;

  @override
  UuidValue? get authUserId => null;
}

mixin _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeDrive extends _Unimplemented implements DriveRepository {}

class _FakeUsers extends _Unimplemented implements UserRepository {}

class _FakeSharing extends _Unimplemented implements SharingRepository {}

class _FakeNotifications extends _Unimplemented
    implements NotificationRepository {}

class _FakePresence extends _Unimplemented implements PresenceRepository {}

class _FakeVersions extends _Unimplemented implements VersionRepository {}

/// In-memory uploads (`FileRepository`): every upload is ready at once.
class FakeFiles implements FileRepository {
  /// The uploads, in order.
  final uploads = <({UuidValue fileUuid, UuidValue? itemUuid, String name})>[];

  FileUrlView _view(UuidValue fileUuid, String name, String mime, int size) =>
      FileUrlView(
        fileUuid: fileUuid,
        status: StoredFileStatus.ready,
        fileName: name,
        mimeType: mime,
        sizeBytes: size,
      );

  @override
  Future<FileUrlView> upload({
    required UuidValue fileUuid,
    UuidValue? itemUuid,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    StoredFileKind kind = StoredFileKind.image,
  }) async {
    uploads.add((fileUuid: fileUuid, itemUuid: itemUuid, name: fileName));
    return _view(fileUuid, fileName, mimeType, bytes.length);
  }

  /// Ready without a URL: images show their placeholder.
  @override
  Future<FileUrlView> getUrl(UuidValue fileUuid) async =>
      _view(fileUuid, 'image.png', 'image/png', 1);
}

class _FakeMeta extends _Unimplemented implements MetaRepository {}

/// In-memory comment threads (`CommentRepository`).
class FakeComments implements CommentRepository {
  final Map<String, CommentThreadView> threads = {};
  final _events = StreamController<CommentEvent>.broadcast();
  final UserSummary me = userSummary(1);

  @override
  Future<List<CommentThreadView>> listThreads(
    UuidValue itemUuid, {
    CommentFilter filter = CommentFilter.all,
  }) async => [...threads.values];

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
  }) async {
    final t = CommentThreadView(
      uuid: threadUuid,
      itemUuid: itemUuid,
      anchorKind: anchorKind,
      anchorJson: anchorJson,
      quotedText: quotedText,
      status: CommentStatus.open,
      createdBy: me,
      createdAt: DateTime.utc(2026),
      comments: [
        CommentView(
          id: threads.length + 1,
          threadUuid: threadUuid,
          author: me,
          authorKind: ActorKind.user,
          body: body,
          mentions: const [],
          reactions: const {},
          createdAt: DateTime.utc(2026),
          deleted: false,
        ),
      ],
    );
    return threads[threadUuid.uuid] = t;
  }

  CommentThreadView _status(UuidValue uuid, CommentStatus s) =>
      threads[uuid.uuid] = threads[uuid.uuid]!.copyWith(status: s);

  @override
  Future<CommentThreadView> resolve(UuidValue threadUuid) async =>
      _status(threadUuid, CommentStatus.resolved);

  @override
  Future<CommentThreadView> reopen(UuidValue threadUuid) async =>
      _status(threadUuid, CommentStatus.open);

  @override
  Future<void> deleteThread(UuidValue threadUuid) async =>
      threads.remove(threadUuid.uuid);

  @override
  Stream<CommentEvent> watch(UuidValue itemUuid) => _events.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Config extends WonkyAppConfig {
  const _Config();

  @override
  WonkyAppKind get app => WonkyAppKind.write;

  @override
  String get appName => 'Wonky Write';

  @override
  DriveItemKind get primaryKind => DriveItemKind.document;

  @override
  Color get brandColor => const Color(0xff2563eb);

  @override
  Widget logo({double size = 28}) => SizedBox(width: size, height: size);

  @override
  String itemPath(String uuid) => '/d/$uuid';

  @override
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid) =>
      const SizedBox();

  @override
  String untitledName(BuildContext context) => 'Untitled document';
}

/// The session's server calls against a [FakeDocumentServer].
class FakeWriteApi implements WriteDocumentApi {
  FakeWriteApi(
    this.server, {
    this.userId = 1,
    AccessRole role = AccessRole.editor,
  }) : item = driveItem(role: role);

  final FakeDocumentServer server;
  final int userId;
  DriveItemView item;
  final List<(String, String)> metaWrites = [];

  @override
  Future<DriveItemView> getItem(UuidValue itemUuid) async => item;

  @override
  DocumentSyncTransport transport(UuidValue documentUuid) =>
      server.transport(userId: userId, userUuid: userSummary(userId).uuid.uuid);

  @override
  Future<void> updateMeta(
    UuidValue documentUuid,
    String field,
    String valueJson,
    UuidValue clientOpId,
  ) async {
    metaWrites.add((field, valueJson));
    server.changeMeta(field, valueJson, authorId: userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A shell (real undo service, commands registry, fake repositories) and a
/// [WriteDocumentSession] against an in-process OT server.
class SessionHarness {
  SessionHarness(
    this.server, {
    int userId = 1,
    AccessRole role = AccessRole.editor,
  }) : comments = FakeComments() {
    ShellSpelling.debugDictionaries ??= noSpellDictionaries();
    services = ShellServices(
      config: const _Config(),
      auth: AuthController(_FakeAuth()),
      repositories: ShellRepositories(
        drive: _FakeDrive(),
        users: _FakeUsers(),
        sharing: _FakeSharing(),
        comments: comments,
        notifications: _FakeNotifications(),
        presence: _FakePresence(),
        versions: _FakeVersions(),
        files: files,
        meta: _FakeMeta(),
        publications: publications,
      ),
      urls: const AppUrls(apiUrl: 'http://localhost:8080/', apps: {}),
      connectivity: ConnectivityService(ping: () async {}),
      deviceStore: MemoryStore(),
    );
    services.currentUser.value = UserProfileView(
      summary: userSummary(userId),
      createdAt: DateTime.utc(2026),
    );
    api = FakeWriteApi(server, userId: userId, role: role);
    keeper = SimpleConnectionKeeper(minDelay: Duration.zero);
    session = WriteDocumentSession(
      services: services,
      itemUuid: itemUuid,
      api: api,
      keeper: keeper,
    );
  }

  final FakeDocumentServer server;

  /// Publications and submissions (specs/18).
  final FakePublicationRepository publications = FakePublicationRepository();

  /// Uploads (images, the cover image of a submission).
  final FakeFiles files = FakeFiles();
  final FakeComments comments;
  late final ShellServices services;
  late final FakeWriteApi api;
  late final SimpleConnectionKeeper keeper;
  late final WriteDocumentSession session;
  CommentsController? commentsController;

  UndoService get undo => services.undo;

  /// Opens the session, activates its undo stack (as the screen's
  /// controller does) and optionally the comments controller.
  Future<void> open({bool withComments = false}) async {
    for (final h in session.undoHandlers) {
      undo.registerHandler(h);
    }
    await undo.openStack(session.undoStackKey, persist: false);
    undo.setActiveDocument(session.undoStackKey);
    if (withComments) {
      final c = CommentsController(
        services: services,
        itemUuid: session.itemUuid,
      );
      commentsController = c;
      services.comments.value = c;
      await c.reload();
    }
    await session.open();
    await pumpEventQueue();
  }

  String get text => DeltaUtils.text(session.editor.delta);

  Delta get doc => session.editor.delta;

  Future<void> dispose() async {
    session.dispose();
    commentsController?.dispose();
    keeper.dispose();
    await pumpEventQueue();
  }
}
