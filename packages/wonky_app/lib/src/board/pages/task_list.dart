import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../core/stream_supervisor.dart';
import '../../data/api.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/page_frame.dart';
import '../../shell/shell_services.dart';
import '../board_hub.dart';
import 'board_labels.dart';
import 'board_trail.dart';
import 'board_widgets.dart';

/// The claim state of a task: *Claimed by Ada · 31 h left*, *In review*,
/// or *Up for grabs*.
String boardClaimState(WonkyAppLocalizations l, BoardTaskView t) {
  final by = t.claimedBy?.displayName;
  final until = t.claimExpiresAt;
  switch (t.status) {
    case BoardTaskStatus.claimed when by != null && until != null:
      final hours = until.difference(clock.now()).inHours.clamp(0, 999);
      return l.boardClaimedBy(by, hours);
    case BoardTaskStatus.inReview:
      return by == null ? l.boardTaskInReview : l.boardInReviewBy(by);
    case BoardTaskStatus.published:
      return l.boardUpForGrabs;
    default:
      return l.boardTaskStatusName(t.status);
  }
}

/// Tasks with [statuses] (*Up for grabs*: published; *Claimed*: claimed
/// and in review; Done: done and shipped). [live] follows
/// `board.watchTasks`, so a claim, a release, an expiry or a linked PR
/// moves a task between the tabs.
class BoardTaskList extends StatefulWidget {
  const BoardTaskList({
    super.key,
    required this.services,
    required this.statuses,
    this.live = false,
    this.compact = false,
    this.title,
    this.horizontalPadding,
    this.emptyTitle,
    this.emptyDescription,
    this.selectable = false,
  });

  final ShellServices services;
  final List<BoardTaskStatus> statuses;
  final bool live;

  /// Admins get the selection mode (*Up for grabs*, specs/16 §9.3): rows
  /// with checkboxes and *Merge N tasks…*.
  final bool selectable;

  /// Shrink-wrapped (a section above the Done posts); nothing when empty.
  final bool compact;
  final String? title;

  /// The list's side padding (default: the page's content column, less
  /// the rows' own 8 px).
  final double? horizontalPadding;

  /// The empty state (default: *No tasks up for grabs*).
  final String? emptyTitle;
  final String? emptyDescription;

  @override
  State<BoardTaskList> createState() => _BoardTaskListState();
}

class _BoardTaskListState extends State<BoardTaskList> {
  ShellServices get s => widget.services;

  final List<BoardTaskView> _items = [];
  String? _cursor;
  bool _loading = true;
  Object? _error;
  SupervisedStream? _watch;
  StreamSubscription<BoardChange>? _changes;
  bool _selecting = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _changes = BoardHub.of(s).changes.listen((c) {
      if (c.task != null || c.lists) unawaited(_load());
    });
    if (widget.live) {
      // A key per list: the next tab's list starts before this one is
      // disposed, and a shared key would cancel it.
      _watch = s.supervisor.supervise<BoardPostEvent>(
        'board.tasks.list.${identityHashCode(this)}',
        () => s.repositories.board.watchTasks(),
        (_) => unawaited(_load()),
      );
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    _changes?.cancel();
    unawaited(_watch?.cancel());
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    try {
      final page = await s.repositories.board.listTasks(
        widget.statuses,
        cursor: more ? _cursor : null,
      );
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        _items.addAll(page.items);
        // A task that left the list (claimed, merged) leaves the selection.
        _selected.retainAll({for (final t in _items) t.number});
        BoardHub.of(s).noteTasks(page.items);
        _cursor = page.nextCursor;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final pad =
        widget.horizontalPadding ??
        math.max(0.0, shellPageInset(MediaQuery.sizeOf(context).width) - 8);
    if (widget.compact) {
      if (_items.isEmpty) return const SizedBox.shrink();
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: pad),
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text(
                widget.title!,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (final t in _items) BoardTaskRow(services: s, task: t),
        ],
      );
    }
    if (_loading) return const BoardListLoading();
    if (_error != null && _items.isEmpty) {
      final offline = isOfflineError(_error!);
      return WonkyEmptyState(
        illustration: offline
            ? EmptyIllustration.offline
            : EmptyIllustration.error,
        title: offline ? l.driveOfflineTitle : l.boardLoadFailed,
        description: offline ? null : errorMessage(_error!),
        actions: [
          ShadButton.outline(onPressed: _load, child: Text(l.actionRetry)),
        ],
      );
    }
    if (_items.isEmpty) {
      return WonkyEmptyState(
        key: const ValueKey<String>('board.tasks.empty'),
        illustration: EmptyIllustration.documents,
        title: widget.emptyTitle ?? l.boardEmptyTasks,
        description: widget.emptyTitle == null
            ? l.boardEmptyTasksHint
            : widget.emptyDescription,
      );
    }
    final selectable = widget.selectable && BoardHub.of(s).isAdmin;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
      children: [
        for (final t in _items)
          BoardTaskRow(
            services: s,
            task: t,
            selected: selectable && _selecting
                ? _selected.contains(t.number)
                : null,
            onSelected: (v) => setState(
              () => v ? _selected.add(t.number) : _selected.remove(t.number),
            ),
          ),
        if (_cursor != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: ShadButton.outline(
                key: const ValueKey<String>('board.tasks.loadMore'),
                onPressed: () => _load(more: true),
                child: Text(l.boardLoadMore),
              ),
            ),
          ),
      ],
    );
    if (!selectable) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: _selecting && _selected.isNotEmpty
              ? _selectionBar(l, theme, pad)
              : _toolbar(l, pad),
        ),
        Expanded(child: list),
      ],
    );
  }

  void _endSelection() => setState(() {
    _selected.clear();
    _selecting = false;
  });

  /// *Select* at the end of the row, like the filter bar of the issue tabs.
  Widget _toolbar(WonkyAppLocalizations l, double pad) => Padding(
    padding: EdgeInsets.symmetric(horizontal: pad + 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ShadButton.ghost(
          key: const ValueKey<String>('board.tasks.select'),
          size: ShadButtonSize.sm,
          leading: Icon(
            _selecting ? LucideIcons.x : LucideIcons.squareCheck,
            size: 14,
          ),
          onPressed: () => setState(() {
            _selecting = !_selecting;
            _selected.clear();
          }),
          child: Text(_selecting ? l.boardSelectDone : l.boardSelect),
        ),
      ],
    ),
  );

  /// The drive's selection bar (as on the issue tabs): *Clear*, the count
  /// and *Merge N tasks…*, which needs two tasks or more.
  Widget _selectionBar(
    WonkyAppLocalizations l,
    ShadThemeData theme,
    double pad,
  ) => Container(
    key: const ValueKey<String>('board.tasks.selectionBar'),
    margin: EdgeInsets.fromLTRB(pad, 4, pad, 4),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: theme.colorScheme.secondary,
      borderRadius: BorderRadius.circular(22),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ShadTooltip(
            builder: (_) => Text(l.actionClear),
            child: ShadIconButton.ghost(
              key: const ValueKey<String>('board.tasks.selection.clear'),
              width: 32,
              height: 32,
              iconSize: 16,
              semanticLabel: l.actionClear,
              icon: const Icon(LucideIcons.x),
              onPressed: _endSelection,
            ),
          ),
          Text(l.boardSelected(_selected.length), style: theme.textTheme.small),
          const SizedBox(width: 12),
          ShadTooltip(
            builder: (_) => Text(l.boardMergeTasksNeedsTwo),
            child: ShadButton.ghost(
              key: const ValueKey<String>('board.tasks.selection.merge'),
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.merge, size: 14),
              onPressed: _selected.length < 2 ? null : _merge,
              child: Text(l.boardMergeTasksTitle(_selected.length)),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _merge() async {
    final r = await boardInvoke(s, 'shell.board.admin.mergeTasks', {
      'taskNumbers': [..._selected],
    }, context: context);
    final n = (r?.data as Map?)?['taskNumber'];
    if (r?.isOk != true || !mounted) return;
    _endSelection();
    if (n is int) boardOpenTask(s, n, context: context);
  }
}

/// One task: `T-12`, title, labels, status and claim state, issue count;
/// a checkbox in the admin selection mode ([selected] non-null).
class BoardTaskRow extends StatelessWidget {
  const BoardTaskRow({
    super.key,
    required this.services,
    required this.task,
    this.selected,
    this.onSelected,
  });

  final ShellServices services;
  final BoardTaskView task;
  final bool? selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.muted.copyWith(fontSize: 12);
    final t = task;
    void open() => boardOpenTask(services, t.number, context: context);
    final selected = this.selected;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        BoardNumberedTitle(number: 'T-${t.number}', title: t.title),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...boardLabelChips(l, area: t.area, size: t.size),
            BoardStatusBadge(
              status: t.status,
              label: l.boardTaskStatusName(t.status),
            ),
            Text(boardClaimState(l, t), style: muted),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [
                Icon(
                  LucideIcons.layers,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                Text(l.boardPostCount(t.posts.length), style: muted),
              ],
            ),
          ],
        ),
      ],
    );
    return BoardListTile(
      key: ValueKey<String>('board.task.${t.number}'),
      semanticLabel: 'T-${t.number} ${t.title}, ${boardClaimState(l, t)}',
      selected: selected == true,
      onTap: open,
      child: selected == null
          ? details
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ShadCheckbox(
                    key: ValueKey<String>('board.task.${t.number}.select'),
                    value: selected,
                    onChanged: onSelected,
                  ),
                ),
                Expanded(child: details),
              ],
            ),
    );
  }
}
