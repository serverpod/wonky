import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../comments/comments_panel.dart';
import '../../core/stream_supervisor.dart';
import '../../data/api.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../markdown/wonky_markdown.dart';
import '../../shell/page_frame.dart';
import '../../shell/shell_services.dart';
import '../../widgets/image_lightbox.dart';
import '../board_commands.dart';
import '../board_hub.dart';
import 'board_comment_actions.dart';
import 'board_labels.dart';
import 'board_trail.dart';
import 'board_widgets.dart';

/// The post page (`/improvements/p/:number`, specs/16 §4.5).
class BoardPostPage extends StatefulWidget {
  const BoardPostPage({
    super.key,
    required this.services,
    required this.number,
    this.trail,
    this.mergedFrom,
  });

  final ShellServices services;
  final int number;

  /// The breadcrumb trail from the route (`?list=…&task=…`); null: the
  /// post's own list (specs/16 §4.3).
  final BoardTrail? trail;

  /// Arrived here from a merged duplicate (`?merged=388`).
  final int? mergedFrom;

  @override
  State<BoardPostPage> createState() => _BoardPostPageState();
}

class _BoardPostPageState extends State<BoardPostPage> {
  ShellServices get s => widget.services;
  BoardHub get hub => BoardHub.of(s);
  int get n => widget.number;

  BoardPostView? _post;

  /// This page's breadcrumb trail, its list resolved from the post's kind.
  BoardTrail get _trail =>
      (widget.trail ?? BoardTrail(post: n)).resolve(hub, postKind: _post?.kind);
  List<BoardCommentView> _comments = const [];
  List<BoardSimilarPost> _similar = const [];
  String? _screenshotUrl;
  Object? _error;
  bool _loading = true;
  bool _detailsOpen = false;
  SupervisedStream? _watch;
  StreamSubscription<BoardChange>? _changes;

  @override
  void initState() {
    super.initState();
    hub.me.addListener(_onMe);
    unawaited(hub.loadMe());
    _changes = hub.changes.listen((c) {
      if (c.touchesPost(n)) unawaited(_load());
    });
    _watch = s.supervisor.supervise<BoardPostEvent>(
      'board.post.$n',
      () => s.repositories.board.watchPost(n),
      (_) => unawaited(_load()),
    );
    unawaited(_load(first: true));
  }

  @override
  void didUpdateWidget(BoardPostPage old) {
    super.didUpdateWidget(old);
    if (old.number != widget.number) {
      setState(() {
        _post = null;
        _loading = true;
      });
      unawaited(_watch?.cancel());
      _watch = s.supervisor.supervise<BoardPostEvent>(
        'board.post.$n',
        () => s.repositories.board.watchPost(n),
        (_) => unawaited(_load()),
      );
      unawaited(_load(first: true));
    }
  }

  @override
  void dispose() {
    hub.me.removeListener(_onMe);
    _changes?.cancel();
    unawaited(_watch?.cancel());
    super.dispose();
  }

  void _onMe() {
    if (mounted) setState(() {});
  }

  Future<void> _load({bool first = false}) async {
    final repo = s.repositories.board;
    try {
      final p = await repo.getPost(n);
      // A merged duplicate opens its target (admins stay to unmerge).
      if (first &&
          p.status == BoardPostStatus.duplicate &&
          p.duplicateOfNumber != null &&
          !hub.isAdmin &&
          mounted) {
        boardGo(
          s,
          _trail.openPost(p.duplicateOfNumber!),
          replace: true,
          merged: n,
        );
        return;
      }
      final comments = await repo.listComments(n);
      String? shot;
      if (p.hasScreenshot) {
        try {
          shot = await repo.getScreenshotUrl(n);
        } catch (_) {}
      }
      hub
        ..notePost(p)
        ..noteComments(comments);
      if (!mounted) return;
      setState(() {
        _post = p;
        _comments = comments;
        _screenshotUrl = shot;
        _error = null;
        _loading = false;
      });
      if (first) unawaited(_loadSimilar(p));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadSimilar(BoardPostView p) async {
    try {
      final r = await s.repositories.board.similar(p.title, '', p.kind);
      if (!mounted) return;
      setState(
        () => _similar = [
          for (final x in r)
            if (x.number != n) x,
        ].take(3).toList(),
      );
    } catch (_) {}
  }

  Future<void> _invoke(String id, [Map<String, Object?>? args]) =>
      boardInvoke(s, id, args ?? {'postNumber': n}, context: context);

  Future<void> _vote(int value) async {
    if (!s.auth.isSignedIn) return boardSignIn(s);
    await _invoke('shell.board.vote', {'postNumber': n, 'value': value});
  }

  List<WonkyMenuEntry> _menu(WonkyAppLocalizations l, BoardPostView p) {
    final admin = hub.isAdmin;
    final signedIn = s.auth.isSignedIn;
    WonkyMenuItem item(
      String key,
      String label,
      IconData icon,
      VoidCallback onSelected, {
      bool destructive = false,
    }) => WonkyMenuItem(
      key: ValueKey<String>('board.post.menu.$key'),
      label: label,
      icon: icon,
      destructive: destructive,
      onSelected: onSelected,
    );
    final votingOpen =
        p.status == BoardPostStatus.open || p.status == BoardPostStatus.planned;
    return [
      if (p.isMine && p.canEdit && !p.deleted)
        item(
          'edit',
          l.cmdBoardEditPost,
          LucideIcons.pencil,
          () => _invoke('shell.board.editPost'),
        ),
      if (p.isMine && !p.deleted)
        item(
          'delete',
          l.cmdBoardDeletePost,
          LucideIcons.trash2,
          () => _invoke('shell.board.deletePost'),
          destructive: true,
        ),
      if (p.hasScreenshot && (p.isMine || admin))
        item(
          'removeScreenshot',
          l.cmdBoardRemoveScreenshot,
          LucideIcons.imageOff,
          () => _invoke('shell.board.removeScreenshot'),
        ),
      item('copyLink', l.cmdCopyLink, LucideIcons.link, () async {
        await Clipboard.setData(ClipboardData(text: boardPostUrl(s, n)));
        s.toasts.show(l.toastLinkCopied);
      }),
      if (signedIn && !p.isMine)
        item(
          'flag',
          l.cmdBoardFlag,
          LucideIcons.flag,
          () => _invoke('shell.board.flag'),
        ),
      if (admin) ...[
        const WonkyMenuSeparator(),
        WonkyMenuLabel(l.boardAdminActions),
        item(
          'labels',
          l.cmdBoardSetLabels,
          LucideIcons.tags,
          () => _invoke('shell.board.admin.setLabels'),
        ),
        if (p.suggestedTitle != null)
          item(
            'applyTitle',
            l.cmdBoardApplyTitle,
            LucideIcons.sparkles,
            () => _invoke('shell.board.admin.applySuggestedTitle'),
          ),
        item(
          'adminEdit',
          p.moderation == BoardModeration.visible
              ? l.cmdBoardAdminEdit
              : l.boardEditAndApprove,
          LucideIcons.pencilLine,
          () => _invoke('shell.board.admin.editPost', {
            'postNumber': n,
            'approve': p.moderation != BoardModeration.visible,
          }),
        ),
        if (p.moderation != BoardModeration.visible &&
            p.moderation != BoardModeration.removed)
          item(
            'approve',
            l.boardActionApprove,
            LucideIcons.check,
            () => _moderate('approve'),
          ),
        if (p.moderation == BoardModeration.visible)
          item(
            'hold',
            l.boardActionHold,
            LucideIcons.pause,
            () => _moderate('hold'),
          ),
        if (p.needsCheck || p.triageState == BoardTriageState.unchecked)
          item(
            'markChecked',
            l.boardActionLooksFine,
            LucideIcons.checkCheck,
            () => _moderate('markChecked'),
          ),
        if (p.moderation == BoardModeration.removed)
          item(
            'restore',
            l.boardActionRestore,
            LucideIcons.rotateCcw,
            () => _moderate('restore'),
          )
        else
          item(
            'remove',
            l.boardActionRemoveEllipsis,
            LucideIcons.trash,
            () => _moderate('remove'),
            destructive: true,
          ),
        if (votingOpen && p.task == null)
          item(
            'select',
            l.boardSelectForBuilding,
            LucideIcons.hammer,
            _selectForBuilding,
          ),
        if (votingOpen && p.task == null)
          item(
            'addToTask',
            l.boardAddToTaskEllipsis,
            LucideIcons.listPlus,
            () => boardInvoke(s, 'shell.board.admin.setTaskPosts', {
              'add': [n],
            }, context: context),
          ),
        if (p.status == BoardPostStatus.declined)
          item(
            'reopen',
            l.cmdBoardReopen,
            LucideIcons.rotateCcw,
            () => _invoke('shell.board.admin.reopen'),
          )
        else if (votingOpen)
          item(
            'decline',
            l.boardDeclineEllipsis,
            LucideIcons.ban,
            () => _invoke('shell.board.admin.decline'),
          ),
        if (p.status == BoardPostStatus.duplicate)
          item(
            'unmerge',
            l.cmdBoardUnmerge,
            LucideIcons.split,
            () => _invoke('shell.board.admin.unmerge'),
          )
        else
          item(
            'merge',
            l.boardMergeEllipsis,
            LucideIcons.merge,
            () => _invoke('shell.board.admin.merge', {'source': n}),
          ),
        if (p.author != null && !p.author!.isAdmin)
          item(
            'block',
            l.boardBlockEllipsis,
            LucideIcons.userX,
            () => _invoke('shell.board.admin.block', {'postNumber': n}),
            destructive: true,
          ),
      ],
    ];
  }

  Future<void> _moderate(String action) => _invoke(
    'shell.board.admin.moderate',
    {'postNumber': n, 'action': action},
  );

  Future<void> _selectForBuilding() async {
    final r = await boardInvoke(s, 'shell.board.admin.createTask', {
      'postNumbers': [n],
    }, context: context);
    final t = (r?.data as Map?)?['taskNumber'];
    if (t is int && mounted) boardOpenTask(s, t, context: context);
  }

  List<Widget> _notices(WonkyAppLocalizations l, BoardPostView p) {
    final cs = ShadTheme.of(context).colorScheme;
    final out = <Widget>[];
    void add(String key, IconData icon, String text, Color? tone) => out.add(
      BoardNotice(
        key: ValueKey<String>('board.post.notice.$key'),
        icon: icon,
        text: text,
        tone: tone,
      ),
    );
    if (widget.mergedFrom != null) {
      add(
        'merged',
        LucideIcons.merge,
        l.boardMergedFromNote(widget.mergedFrom!),
        cs.info,
      );
    }
    if (p.deleted) {
      add('deleted', LucideIcons.trash2, l.boardPostDeleted, cs.destructive);
    }
    switch (p.moderation) {
      case BoardModeration.checking:
        add('checking', LucideIcons.loaderCircle, l.boardChecking, cs.info);
      case BoardModeration.held:
        add(
          'held',
          LucideIcons.pause,
          p.isMine && !hub.isAdmin
              ? l.boardWaitingForReview
              : l.boardHeldAdmin(p.moderationReason ?? ''),
          cs.warning,
        );
      case BoardModeration.removed:
        add(
          'removed',
          LucideIcons.ban,
          l.boardRemovedByModerator(p.moderationReason ?? ''),
          cs.destructive,
        );
      case BoardModeration.visible:
        break;
    }
    if (p.status == BoardPostStatus.declined) {
      add(
        'declined',
        LucideIcons.ban,
        l.boardDeclinedNote(p.declineReason ?? ''),
        cs.mutedForeground,
      );
    }
    if (p.status == BoardPostStatus.duplicate && p.duplicateOfNumber != null) {
      out.add(
        BoardNotice(
          key: const ValueKey<String>('board.post.notice.duplicate'),
          icon: LucideIcons.merge,
          text: l.boardMergedInto(p.duplicateOfNumber!),
          tone: cs.info,
          action: ShadButton.link(
            size: ShadButtonSize.sm,
            onPressed: () =>
                boardOpenPost(s, p.duplicateOfNumber!, context: context),
            child: Text(l.boardOpenPost(p.duplicateOfNumber!)),
          ),
        ),
      );
    }
    if (p.reportedKind != p.kind) {
      add(
        'moved',
        LucideIcons.arrowRightLeft,
        p.kind == BoardPostKind.idea ? l.boardMovedToIdeas : l.boardMovedToBugs,
        null,
      );
    }
    if (p.editedByModerator) {
      add('modEdit', LucideIcons.pencilLine, l.boardEditedByModerator, null);
    }
    return out;
  }

  Widget _details(WonkyAppLocalizations l, ShadThemeData theme, String json) {
    Map<String, Object?> data;
    try {
      final v = jsonDecode(json);
      data = v is Map ? v.cast<String, Object?>() : {'details': json};
    } catch (_) {
      data = {'details': json};
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoardDisclosure(
          tapKey: 'board.post.details',
          open: _detailsOpen,
          onToggle: () => setState(() => _detailsOpen = !_detailsOpen),
          label: Text(l.boardDetails, style: theme.textTheme.small),
        ),
        if (_detailsOpen)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 20),
            child: Table(
              key: const ValueKey<String>('board.post.detailsTable'),
              columnWidths: const {0: IntrinsicColumnWidth()},
              children: [
                for (final e in data.entries)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 4),
                        child: Text(e.key, style: theme.textTheme.muted),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          e.value is String
                              ? e.value! as String
                              : const JsonEncoder.withIndent(
                                  '  ',
                                ).convert(e.value),
                          style: theme.textTheme.small.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _adminPanel(
    WonkyAppLocalizations l,
    ShadThemeData theme,
    BoardPostView p,
  ) {
    Map<String, Object?>? triage;
    final tj = p.triageJson;
    if (tj != null) {
      try {
        final v = jsonDecode(tj);
        if (v is Map) triage = v.cast<String, Object?>();
      } catch (_) {}
    }
    final flags = p.flags ?? const [];
    final dup = p.possibleDuplicateOfNumber;
    // An admin callout like the app's other `ShadAlert`s (offline warnings,
    // the trashed-file banner).
    return ShadAlert(
      key: const ValueKey<String>('board.post.admin'),
      icon: const Icon(LucideIcons.shieldCheck, size: 16),
      titleStyle: theme.textTheme.small,
      title: Text(l.boardAdminPanel),
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              BoardChip(label: l.boardModerationName(p.moderation)),
              BoardChip(label: l.boardTriage(p.triageState.name)),
              if (p.needsCheck) BoardChip(label: l.boardNeedsCheck),
              if (p.aiLabels) BoardChip(label: l.boardNeedsLabels),
            ],
          ),
          if (p.suggestedTitle != null)
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    l.boardSuggestedTitle(p.suggestedTitle!),
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                ShadButton.outline(
                  key: const ValueKey<String>('board.post.applyTitle'),
                  size: ShadButtonSize.sm,
                  onPressed: () =>
                      _invoke('shell.board.admin.applySuggestedTitle'),
                  child: Text(l.boardApply),
                ),
              ],
            ),
          if (dup != null)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l.boardPossibleDuplicate(dup),
                  style: theme.textTheme.small,
                ),
                ShadButton.outline(
                  key: const ValueKey<String>('board.post.mergeHint'),
                  size: ShadButtonSize.sm,
                  onPressed: () => _invoke('shell.board.admin.merge', {
                    'source': n,
                    'target': dup,
                  }),
                  child: Text(l.boardActionMerge),
                ),
                ShadButton.ghost(
                  key: const ValueKey<String>('board.post.notDuplicate'),
                  size: ShadButtonSize.sm,
                  onPressed: () =>
                      _invoke('shell.board.admin.dismissDuplicate'),
                  child: Text(l.cmdBoardNotDuplicate),
                ),
              ],
            ),
          if (triage != null && triage.isNotEmpty)
            Text(
              '${l.boardAiScores}: ${[for (final e in triage.entries) '${e.key} ${e.value is num ? (e.value! as num).toStringAsFixed(2) : e.value}'].join(' · ')}',
              key: const ValueKey<String>('board.post.triage'),
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          if (flags.isNotEmpty)
            Text(
              l.boardFlags(
                flags.length,
                [
                  for (final f in flags)
                    '${l.boardFlagReasonName(f.reason)}${f.note == null ? '' : ' (${f.note})'}',
                ].join(', '),
              ),
              key: const ValueKey<String>('board.post.flags'),
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final p = _post;
    Widget body;
    if (_loading && p == null) {
      body = const Center(child: ShadSpinner());
    } else if (p == null) {
      final notFound =
          _error is WonkyException &&
          (_error! as WonkyException).code == WonkyErrorCode.notFound;
      body = WonkyEmptyState(
        key: const ValueKey<String>('board.post.notFound'),
        illustration: notFound
            ? EmptyIllustration.noAccess
            : EmptyIllustration.error,
        title: notFound ? l.boardPostNotFound(n) : l.boardLoadFailed,
        description: notFound ? null : errorMessage(_error ?? ''),
        actions: [
          ShadButton.outline(
            onPressed: () => s.router.go('/improvements'),
            child: Text(l.boardBackToBoard),
          ),
        ],
      );
    } else {
      final votingOpen =
          p.status == BoardPostStatus.open ||
          p.status == BoardPostStatus.planned;
      final task = p.task;
      final shot = _screenshotUrl;
      final commentsOpen =
          !p.deleted && p.moderation != BoardModeration.removed;
      body = ShellPageBody(
        key: const ValueKey<String>('board.post'),
        spacing: 12,
        children: [
          ..._notices(l, p),
          // The vote control at the start (ideas and bugs alike), then the
          // header: `#412`, the title (wrapping) and ⋮ on one top-aligned
          // line, the chips and the author below.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              BoardVoteControl(
                number: p.number,
                kind: p.kind,
                score: p.score,
                voteCount: p.voteCount,
                myVote: p.myVote,
                large: true,
                onVote: votingOpen && !p.deleted ? _vote : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Row(
                      key: const ValueKey<String>('board.post.header'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '#${p.number}',
                            key: const ValueKey<String>('board.post.number'),
                            style: theme.textTheme.h3.copyWith(
                              color: theme.colorScheme.mutedForeground,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Semantics(
                              header: true,
                              child: Text(
                                p.title,
                                key: const ValueKey<String>('board.post.title'),
                                style: theme.textTheme.h3,
                              ),
                            ),
                          ),
                        ),
                        WonkyDropdownMenu(
                          anchor: const ShadAnchor(
                            childAlignment: AlignmentDirectional.bottomEnd,
                            overlayAlignment: AlignmentDirectional.topEnd,
                          ),
                          entries: () => _menu(l, p),
                          builder: (context, ctl) => ShadIconButton.ghost(
                            key: const ValueKey<String>('board.post.menu'),
                            semanticLabel: l.moreActions,
                            icon: const Icon(LucideIcons.ellipsisVertical),
                            onPressed: ctl.toggle,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...boardLabelChips(
                          l,
                          kind: p.kind,
                          area: p.area,
                          size: p.size,
                          ai: p.aiLabels,
                        ),
                        BoardStatusBadge(
                          status: p.status,
                          label: l.boardStatusName(p.status),
                          onTap: task == null
                              ? null
                              : () => boardOpenTask(
                                  s,
                                  task.number,
                                  context: context,
                                ),
                        ),
                      ],
                    ),
                    BoardAuthorLine(
                      author: p.author,
                      createdAt: p.createdAt,
                      editedAt: p.editedAt,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hub.isAdmin) _adminPanel(l, theme, p),
          WonkyMarkdown(
            p.body,
            key: const ValueKey<String>('board.post.body'),
            profile: MarkdownProfile.post,
          ),
          if (p.hasScreenshot && shot != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                label: l.boardOpenScreenshot,
                child: GestureDetector(
                  key: const ValueKey<String>('board.post.screenshot'),
                  onTap: () => showImageLightbox(
                    context,
                    image: NetworkImage(shot),
                    alt: l.boardScreenshotAlt(p.number),
                    title: p.title,
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.zoomIn,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 480,
                        maxHeight: 320,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          shot,
                          fit: BoxFit.contain,
                          semanticLabel: l.boardScreenshotAlt(p.number),
                          errorBuilder: (context, _, _) => Text(
                            l.lightboxLoadFailed,
                            style: theme.textTheme.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (p.contextJson case final json? when json.isNotEmpty)
            _details(l, theme, json),
          if (task != null ||
              p.mergedFrom.isNotEmpty ||
              _similar.isNotEmpty) ...[
            BoardSectionTitle(l.boardRelations),
            if (task != null)
              _link(
                'task',
                l.boardPartOfTask(task.number, task.title),
                () => boardOpenTask(s, task.number, context: context),
              ),
            if (p.mergedFrom.isNotEmpty)
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.boardMergedFrom, style: theme.textTheme.small),
                  for (final m in p.mergedFrom)
                    _link(
                      'merged.$m',
                      '#$m',
                      () => boardOpenPost(s, m, context: context),
                    ),
                ],
              ),
            if (_similar.isNotEmpty) ...[
              Text(l.boardSimilarPosts, style: theme.textTheme.small),
              for (final x in _similar)
                _link(
                  'similar.${x.number}',
                  '#${x.number} ${x.title} (${l.boardScore(x.score)})',
                  () => boardOpenPost(s, x.number, context: context),
                ),
            ],
          ],
          BoardSectionTitle(l.boardCommentsTitle(p.commentCount)),
          CommentThreadBody.custom(
            key: ValueKey<String>('board.post.comments.$n'),
            services: s,
            actions: BoardCommentActions(
              services: s,
              postNumber: n,
              open: commentsOpen,
            ),
            comments: boardThreadComments(l, _comments),
          ),
          if (!s.auth.isSignedIn)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ShadButton.outline(
                key: const ValueKey<String>('board.post.signInToComment'),
                onPressed: () => boardSignIn(s),
                child: Text(l.boardSignInToComment),
              ),
            ),
        ],
      );
    }
    final trail = _trail;
    final taskNumber = trail.task;
    return BoardFrame(
      services: s,
      trail: trail,
      postTitle: p?.title,
      taskTitle: taskNumber == null
          ? null
          : p?.task?.number == taskNumber
          ? p!.task!.title
          : hub.taskTitles[taskNumber],
      child: body,
    );
  }

  Widget _link(String key, String text, VoidCallback onTap) => Semantics(
    link: true,
    child: GestureDetector(
      key: ValueKey<String>('board.post.link.$key'),
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          text,
          style: ShadTheme.of(context).textTheme.small.copyWith(
            color: ShadTheme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),
  );
}
