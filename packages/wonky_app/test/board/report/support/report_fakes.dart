import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/src/board/report/board_report_services.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/testing.dart';

/// A [BoardRepository] for the report dialog: `me`, `similar`,
/// `createScreenshotUpload`, `createPost` and `vote`, each logged in
/// [log] (shared with [FakeScreenshotTransport]).
class FakeReportBoard extends UnfakedBoardRepository {
  FakeReportBoard({List<String>? log}) : log = log ?? [];

  final List<String> log;

  BoardMe meValue = BoardMe(
    signedIn: true,
    userId: 1,
    isAdmin: false,
    blocked: false,
    activeClaims: const [],
    aiChecks: true,
    repository: 'serverpod/wonky',
    securityContact: 'security@serverpod.dev',
    claimHours: 48,
  );

  /// The bodies `getPost` answers, by number.
  final Map<int, String> postBodies = {};

  /// What `similar` answers.
  List<BoardSimilarPost> similarPosts = const [];

  /// The `similar` queries, in order.
  final List<String> similarQueries = [];

  /// The posted drafts.
  final List<BoardPostDraft> posted = [];

  /// Thrown by `createPost` when set.
  Object? postError;

  /// The moderation state of created posts.
  BoardModeration moderation = BoardModeration.checking;

  /// `(number, value)` of the votes.
  final List<(int, int)> votes = [];

  @override
  Future<BoardMe> me() async => meValue;

  @override
  Future<List<BoardSimilarPost>> similar(
    String title,
    String body,
    BoardPostKind? kind,
  ) async {
    similarQueries.add('$title|$body|${kind?.name}');
    log.add('similar');
    return similarPosts;
  }

  @override
  Future<FileUploadTicket> createScreenshotUpload(
    UuidValue fileUuid,
    String mimeType,
    int size,
  ) async {
    log.add('createScreenshotUpload $mimeType $size');
    return FileUploadTicket(
      fileUuid: fileUuid,
      uploadDescription: 'upload-description',
      status: StoredFileStatus.pending,
    );
  }

  @override
  Future<BoardPostView> createPost(BoardPostDraft draft) async {
    log.add('createPost');
    final e = postError;
    if (e != null) throw e;
    posted.add(draft);
    return postView(
      number: 412,
      kind: draft.kind,
      title: draft.title,
      body: draft.body,
      moderation: moderation,
    );
  }

  @override
  Future<void> deletePost(int number) async => log.add('deletePost $number');

  @override
  Future<BoardPostView> restorePost(int number) async {
    log.add('restorePost $number');
    return postView(number: number);
  }

  @override
  Future<BoardPostView> getPost(int number) async {
    return postView(
      number: number,
      body: postBodies[number] ?? '',
    ).copyWith(myVote: 0);
  }

  @override
  Future<BoardVoteResult> vote(int number, int value) async {
    log.add('vote $number $value');
    votes.add((number, value));
    return BoardVoteResult(number: number, score: 15, voteCount: 15, myVote: 1);
  }
}

/// A [BoardScreenshotTransport] that records into [log].
class FakeScreenshotTransport implements BoardScreenshotTransport {
  FakeScreenshotTransport(this.log);

  final List<String> log;
  final List<Uint8List> uploaded = [];

  @override
  Future<void> upload(FileUploadTicket ticket, Uint8List bytes) async {
    log.add('upload ${ticket.uploadDescription} ${bytes.length}');
    uploaded.add(bytes);
  }

  @override
  Future<void> complete(UuidValue fileUuid) async => log.add('complete');
}

BoardPostView postView({
  required int number,
  BoardPostKind kind = BoardPostKind.bug,
  String title = 'A post title',
  String body = '',
  BoardModeration moderation = BoardModeration.visible,
}) => BoardPostView(
  number: number,
  kind: kind,
  reportedKind: kind,
  aiLabels: false,
  title: title,
  body: body,
  appHint: 'write',
  hasScreenshot: false,
  status: BoardPostStatus.open,
  moderation: moderation,
  editedByModerator: false,
  triageState: BoardTriageState.pending,
  mergedFrom: const [],
  score: 1,
  voteCount: 1,
  commentCount: 0,
  myVote: 1,
  isMine: true,
  canEdit: true,
  createdAt: DateTime.utc(2026, 10, 15),
  deleted: false,
  needsCheck: false,
);

BoardSimilarPost similarPost(
  int number,
  String title, {
  BoardPostKind kind = BoardPostKind.bug,
  int score = 14,
  int myVote = 0,
  BoardPostStatus status = BoardPostStatus.open,
}) => BoardSimilarPost(
  number: number,
  kind: kind,
  title: title,
  status: status,
  score: score,
  myVote: myVote,
);

/// The routes the report flow navigates to.
GoRouter reportRouter() => GoRouter(
  routes: [
    for (final p in const [
      '/',
      '/d/:uuid',
      '/improvements',
      '/improvements/:tab',
      '/improvements/p/:number',
      '/settings/:section',
    ])
      GoRoute(path: p, builder: (_, _) => const SizedBox()),
  ],
);

/// A harness with [board], a fake transport (logging into the board's log)
/// and the report routes; the capture returns [capture] (none: a failed
/// capture).
CommandTestHarness reportHarness({
  FakeReportBoard? board,
  WonkyAppKind app = WonkyAppKind.write,
  FakeAuthRepository? auth,
  HomeScope? scope,
  AppUrls? urls,
}) {
  final b = board ?? FakeReportBoard();
  final h = CommandTestHarness(
    config: TestAppConfig(app: app, scope: scope),
    board: b,
    auth: auth,
    urls: urls,
  );
  h.services.router = reportRouter();
  final rs = BoardReportServices.of(h.services);
  rs.transport = FakeScreenshotTransport(b.log);
  rs.capture = () async => null;
  return h;
}

String routerPath(CommandTestHarness h) =>
    h.services.router.routeInformationProvider.value.uri.toString();

/// Pumps [child] like the shell: services above the app's navigator, and
/// `services.navigatorKey` attached (dialogs and toasts work), inside a
/// `RepaintBoundary` with the shell's screenshot key.
Future<void> pumpReportShell(
  WidgetTester tester,
  CommandTestHarness h,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: h.services,
      child: RepaintBoundary(
        key: h.services.screenshotBoundary,
        child: WonkyTestApp(
          brightness: brightness,
          extraDelegates: const [WonkyAppLocalizations.delegate],
          child: Navigator(
            key: h.services.navigatorKey,
            onGenerateRoute: (_) =>
                PageRouteBuilder<void>(pageBuilder: (context, _, _) => child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A widget that invokes [id] with [args] through the dispatcher when its
/// button (key `test.invoke`) is tapped, from a context under the
/// navigator (like a menu item).
class InvokeButton extends StatelessWidget {
  const InvokeButton(this.id, {super.key, this.args = const {}});

  final String id;
  final Map<String, Object?> args;

  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      key: const ValueKey<String>('test.invoke'),
      onTap: () => ShellScope.of(
        context,
      ).dispatcher.invoke(id, args: args, context: context),
      child: const SizedBox(width: 100, height: 40, child: Text('Invoke')),
    ),
  );
}

/// A solid [width]×[height] image in [color] (created outside the fake
/// async zone).
Future<ui.Image> solidImage(
  WidgetTester tester,
  int width,
  int height, {
  Color color = const Color(0xff3366cc),
}) async => (await tester.runAsync(() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}))!;

/// The key finder for `ValueKey<String>(id)`.
Finder key(String id) => find.byKey(ValueKey<String>(id));

/// Enters [text] into the field keyed [id]: a text input, or a Markdown
/// composer (WYSIWYG, specs/16 §7.3) whose Markdown becomes [text].
Future<void> enterField(WidgetTester tester, String id, String text) async {
  final editable = find.descendant(
    of: key(id),
    matching: find.byType(EditableText),
  );
  if (editable.evaluate().isEmpty) {
    await enterMarkdown(tester, key(id), text);
    return;
  }
  await tester.enterText(editable, text);
  await tester.pump();
}
