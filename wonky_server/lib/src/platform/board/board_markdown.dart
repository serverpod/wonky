import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import 'board_access.dart';
import 'board_views.dart';

/// The Markdown version of an issue (specs/16 §4.3, §10.1),
/// `/improvements/p/<n>.md`: what a coding agent reads from a task prompt's
/// *Reports this task comes from* links. Public content only, as a
/// signed-out visitor sees it.
abstract final class BoardMarkdown {
  /// The Markdown of issue #[number], or null when it is not public
  /// (missing, deleted, held, removed or still being checked).
  static Future<String?> post(
    Session session,
    int number, {
    required Uri webOrigin,
  }) async {
    const c = BoardCaller.signedOut();
    final row = await BoardPost.db.findById(session, number);
    if (row == null ||
        row.deletedAt != null ||
        row.moderation != BoardModeration.visible ||
        !BoardAccess.canSeePost(c, row)) {
      return null;
    }
    final view = await BoardViews.post(session, c, row);
    final comments = await BoardComment.db.find(
      session,
      where: (t) =>
          t.postId.equals(number) &
          t.moderation.equals(BoardModeration.visible) &
          t.deletedAt.equals(null) &
          t.systemEvent.equals(null),
      orderBy: (t) => t.id,
      limit: 2000,
    );
    return render(
      view,
      await BoardViews.comments(session, c, comments),
      webOrigin: webOrigin,
    );
  }

  /// [post] and its [comments] as Markdown: a title line, the facts as a
  /// list, the body, the included details and the comments, oldest first.
  static String render(
    BoardPostView post,
    List<BoardCommentView> comments, {
    required Uri webOrigin,
  }) {
    String link(String path) => webOrigin.replace(path: path).toString();
    final n = post.number;
    final kind = post.kind == BoardPostKind.bug ? 'Bug' : 'Improvement';
    final b = StringBuffer()
      ..writeln('# #$n ${_oneLine(post.title)}')
      ..writeln()
      ..writeln('- Kind: $kind')
      ..writeln('- Status: ${post.status.name}');
    final duplicateOf = post.duplicateOfNumber;
    if (duplicateOf != null) {
      b.writeln(
        '- Duplicate of: #$duplicateOf '
        '(${link('/improvements/p/$duplicateOf.md')})',
      );
    }
    if (post.declineReason case final reason? when reason.trim().isNotEmpty) {
      b.writeln('- Declined: ${_oneLine(reason)}');
    }
    final ai = post.aiLabels ? ' (AI)' : '';
    if (post.area case final area?) b.writeln('- Area: ${area.name}$ai');
    if (post.size case final size?) b.writeln('- Size: ${size.name}$ai');
    b.writeln('- Votes: ${post.score}');
    final author = post.author?.displayName ?? 'Deleted user';
    b.writeln('- Reported by: ${_oneLine(author)} on ${_day(post.createdAt)}');
    if (post.task case final task?) {
      b.writeln(
        '- Task: T-${task.number} ${_oneLine(task.title)} '
        '(${task.status.name})',
      );
    }
    if (post.mergedFrom.isNotEmpty) {
      b.writeln(
        '- Duplicates merged into it: '
        '${post.mergedFrom.map((m) => '#$m').join(', ')}',
      );
    }
    b.writeln('- Page: ${link('/improvements/p/$n')}');
    if (post.hasScreenshot) {
      b.writeln('- Screenshot: ${link('/improvements/p/$n/screenshot')}');
    }
    b
      ..writeln()
      ..writeln(post.body.trim());
    final details = _details(post.contextJson);
    if (details != null) {
      b
        ..writeln()
        ..writeln('## Included details')
        ..writeln()
        ..writeln('```json')
        ..writeln(details)
        ..writeln('```');
    }
    final shown = [
      for (final c in comments)
        if (!c.deleted && c.systemEvent == null && c.body.trim().isNotEmpty) c,
    ];
    b
      ..writeln()
      ..writeln('## Comments (${shown.length})');
    if (shown.isEmpty) {
      b
        ..writeln()
        ..writeln('No comments yet.');
    }
    for (final c in shown) {
      final who = c.author?.displayName ?? 'Deleted user';
      final admin = c.author?.isAdmin ?? false ? ' (admin)' : '';
      b
        ..writeln()
        ..writeln('### ${_oneLine(who)}$admin on ${_day(c.createdAt)}')
        ..writeln()
        ..writeln(c.body.trim());
    }
    return b.toString();
  }

  /// The included details, pretty-printed, or null when there are none.
  static String? _details(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    try {
      final value = jsonDecode(json);
      if (value is Map && value.isEmpty) return null;
      return const JsonEncoder.withIndent('  ').convert(value);
    } on FormatException {
      return json.trim();
    }
  }

  static String _oneLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// `2026-10-19` (UTC).
  static String _day(DateTime at) =>
      at.toUtc().toIso8601String().substring(0, 10);
}
