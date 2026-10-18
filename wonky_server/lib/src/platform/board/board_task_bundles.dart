import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'ai/board_ai.dart';
import 'board_access.dart';
import 'board_common.dart';
import 'board_views.dart';

import 'board_tasks.dart';

/// Bundle suggestions of board tasks (specs/16 §13.5): related posts the
/// AI proposes to handle as one task.
abstract final class BoardTaskBundles {
  static Future<List<BoardBundleSuggestionView>> suggestBundles(
    Session session,
  ) async {
    await BoardAccess.requireAdmin(session);
    final ai = BoardAi.instance;
    if (!ai.geminiConfigured) {
      throw Errors.unavailable('The board AI is not configured.');
    }
    if (!await ai.geminiAvailable(session)) {
      throw Errors.unavailable("Today's AI budget is used up.");
    }
    final cancelled = {
      for (final t in await BoardTask.db.find(
        session,
        where: (t) => t.status.equals(BoardTaskStatus.cancelled),
      ))
        t.id!,
    };
    final posts = [
      for (final p in await BoardPost.db.find(
        session,
        where: (t) =>
            t.moderation.equals(BoardModeration.visible) &
            t.status.equals(BoardPostStatus.open) &
            t.size.equals(BoardSize.small) &
            t.deletedAt.equals(null),
        orderBy: (t) => t.score.desc(),
        limit: BoardTasks.maxBundleInput * 2,
      ))
        if (p.taskId == null || cancelled.contains(p.taskId)) p,
    ].take(BoardTasks.maxBundleInput).toList();
    if (posts.length < 2) return listSuggestions(session);
    final List<BoardBundleProposal> proposals;
    try {
      proposals = await ai.suggestBundles(session, posts);
    } on BoardAiException catch (e) {
      throw Errors.unavailable(
        'The AI could not suggest bundles: ${e.message}',
      );
    }
    final allowed = {for (final p in posts) p.id!};
    final known = {
      for (final s in await BoardBundleSuggestion.db.find(
        session,
        where: (t) => t.state.inSet({'pending', 'dismissed'}),
      ))
        _key(s.postIds),
    };
    final now = nowUtc();
    for (final p in proposals) {
      final ids = {
        for (final id in p.postIds)
          if (allowed.contains(id)) id,
      };
      if (ids.length < 2) continue;
      final key = _key(ids);
      if (!known.add(key)) continue;
      await BoardBundleSuggestion.db.insertRow(
        session,
        BoardBundleSuggestion(
          title: p.title.trim().isEmpty ? 'Bundle' : p.title.trim(),
          rationale: p.rationale.trim(),
          area: p.area,
          postIds: ids.toList()..sort(),
          state: 'pending',
          createdAt: now,
        ),
      );
    }
    return listSuggestions(session);
  }

  static String _key(Iterable<int> ids) =>
      (ids.toSet().toList()..sort()).join(',');

  static Future<List<BoardBundleSuggestionView>> listSuggestions(
    Session session,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final suggestions = await BoardBundleSuggestion.db.find(
      session,
      where: (t) => t.state.equals('pending'),
      orderBy: (t) => t.id.desc(),
    );
    final ids = {for (final s in suggestions) ...s.postIds};
    final posts = ids.isEmpty
        ? const <BoardPost>[]
        : await BoardPost.db.find(session, where: (t) => t.id.inSet(ids));
    final activeTasks = {
      for (final t in await BoardTask.db.find(
        session,
        where: (t) => t.status.notEquals(BoardTaskStatus.cancelled),
      ))
        t.id!,
    };
    final usable = {
      for (final p in posts)
        if (p.deletedAt == null &&
            p.moderation == BoardModeration.visible &&
            p.status == BoardPostStatus.open &&
            !activeTasks.contains(p.taskId))
          p.id!: p,
    };
    final result = <BoardBundleSuggestionView>[];
    for (final s in suggestions) {
      final members = [
        for (final id in s.postIds)
          if (usable[id] != null) usable[id]!,
      ];
      if (members.length < 2) continue;
      result.add(
        BoardBundleSuggestionView(
          id: s.id!,
          title: s.title,
          rationale: s.rationale,
          area: s.area,
          posts: await BoardViews.listItems(session, c, members),
          createdAt: s.createdAt,
        ),
      );
    }
    return result;
  }

  static Future<void> dismissSuggestion(Session session, int id) async {
    final c = await BoardAccess.requireAdmin(session);
    final s = await BoardBundleSuggestion.db.findById(session, id);
    if (s == null) throw Errors.notFound('Suggestion');
    await BoardBundleSuggestion.db.updateRow(
      session,
      s.copyWith(state: 'dismissed'),
      columns: (t) => [t.state],
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'dismissSuggestion',
      targetKind: BoardTargetKind.task,
      targetId: id,
    );
  }
}
