import 'package:serverpod/serverpod.dart';

import '../../platform/board/board_service.dart';
import '../../platform/common/models.dart';

/// Signature of the screenshot URL lookup (tests replace it).
typedef BoardScreenshotUrl =
    Future<String?> Function(Session session, int postNumber);

/// Signature of the Markdown lookup of a post (tests replace it).
typedef BoardPostMarkdown =
    Future<String?> Function(Session session, int postNumber);

/// `/improvements` and `/improvements/**` (specs/16 §4.3): links in emails,
/// PRs and task prompts point at the site; they open in Wonky Drive,
/// `/drive/improvements/…`, keeping the rest of the path and the query.
///
/// `/improvements/p/<n>/screenshot` is the stable screenshot link used in
/// task prompts (specs/16 §10.1): it redirects to a fresh signed URL of the
/// post's screenshot, or answers 404 when the post has none or isn't
/// public.
///
/// `/improvements/p/<n>.md` is the post as Markdown (`text/markdown`: the
/// body, details and comments), the link task prompts give coding agents;
/// 404 when the post isn't public.
class ImprovementsRedirectRoute extends Route {
  ImprovementsRedirectRoute({
    BoardScreenshotUrl? screenshotUrl,
    BoardPostMarkdown? markdown,
  }) : _screenshotUrl = screenshotUrl ?? BoardService.getScreenshotUrl,
       _markdown = markdown ?? BoardService.postMarkdown;

  final BoardScreenshotUrl _screenshotUrl;
  final BoardPostMarkdown _markdown;

  static final _screenshot = RegExp(
    r'^/improvements/p/(\d{1,9})/screenshot/?$',
  );
  static final _markdownPath = RegExp(r'^/improvements/p/(\d{1,9})\.md$');

  static final markdownType = MimeType('text', 'markdown');

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final path = request.url.path;
    final shot = _screenshot.firstMatch(path);
    if (shot != null) {
      final url = await _lookup(() => _screenshotUrl(session, _n(shot)));
      if (url == null) return Response.notFound();
      return Response.found(Uri.parse(url));
    }
    final md = _markdownPath.firstMatch(path);
    if (md != null) {
      final text = await _lookup(() => _markdown(session, _n(md)));
      if (text == null) return Response.notFound();
      return Response.ok(
        body: Body.fromString(text, mimeType: markdownType),
        // Votes and comments change: always fetch the current version.
        headers: Headers.build((h) => h['cache-control'] = ['no-cache']),
      );
    }
    return Response.found(Uri.parse(improvementsTarget(request.url)));
  }

  static int _n(RegExpMatch m) => int.parse(m[1]!);

  /// [lookup]'s result, null when it fails with a [WonkyException] (not
  /// found, not public).
  static Future<String?> _lookup(Future<String?> Function() lookup) async {
    try {
      return await lookup();
    } on WonkyException {
      return null;
    }
  }
}

/// `/improvements/p/12?x=1` → `/drive/improvements/p/12?x=1`.
String improvementsTarget(Uri url) {
  var path = url.path;
  if (!path.startsWith('/')) path = '/$path';
  final target = '/drive$path';
  return url.hasQuery ? '$target?${url.query}' : target;
}
