import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
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
import 'board_chrome.dart';
import 'board_labels.dart';
import 'board_search.dart';
import 'board_trail.dart';
import 'board_widgets.dart';
import 'review_tab.dart';
import 'task_list.dart';

/// Page size of the board list (specs/16 §4.4).
const boardPageSize = 30;

/// The board page (`/improvements…`, specs/16 §4.4): the tabs bar (tabs
/// with count badges, the search button at the end) and the tab's content;
/// *Report a bug* / *Suggest an improvement* are in the frame's bar. On
/// [BoardTab.search], [search] (from the URL) lists the results across all
/// posts.
class BoardPage extends StatefulWidget {
  const BoardPage({
    super.key,
    required this.services,
    required this.tab,
    this.search,
  });

  final ShellServices services;
  final BoardTab tab;
  final BoardSearchQuery? search;

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  ShellServices get s => widget.services;
  BoardHub get hub => BoardHub.of(s);

  BoardCounts? _counts;
  int? _held;
  StreamSubscription<BoardChange>? _changes;
  SupervisedStream? _watch;
  final _searchPopover = ShadPopoverController();

  @override
  void initState() {
    super.initState();
    hub.me.addListener(_onMe);
    unawaited(hub.loadMe());
    _changes = hub.changes.listen((c) {
      if (c.lists || c.task != null) unawaited(_loadCounts());
    });
    // Claims, releases, expiries and linked PRs move tasks between Up for
    // grabs and Claimed: their counts follow live. A key per page: the next
    // page starts before this one is disposed.
    _watch = s.supervisor.supervise<BoardPostEvent>(
      'board.tasks.counts.${identityHashCode(this)}',
      () => s.repositories.board.watchTasks(),
      (_) => unawaited(_loadCounts()),
    );
    HardwareKeyboard.instance.addHandler(_onKey);
    unawaited(_loadCounts());
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    hub.me.removeListener(_onMe);
    _changes?.cancel();
    unawaited(_watch?.cancel());
    _searchPopover.dispose();
    super.dispose();
  }

  void _onMe() {
    if (!mounted) return;
    setState(() {});
    unawaited(_loadCounts());
  }

  /// `/` opens the search popover, unless a text field has the focus or
  /// another page or dialog is in front.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || e.character != '/') return false;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) {
      return false;
    }
    if (!mounted || _searchPopover.isOpen) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus != null &&
        (focus.widget is EditableText ||
            focus.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    // Only when the board page is the shown route (not a dialog over it).
    final location = s.router.routerDelegate.currentConfiguration.uri.path;
    if (location != widget.tab.path &&
        !(widget.tab == BoardTab.improvements && location == '/improvements')) {
      return false;
    }
    _searchPopover.show();
    return true;
  }

  Future<void> _loadCounts() async {
    final repo = s.repositories.board;
    BoardCounts? counts;
    int? held;
    try {
      counts = await repo.counts();
    } catch (_) {}
    if (hub.isAdmin) {
      try {
        held = (await repo.reviewCounts()).held;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _counts = counts ?? _counts;
      _held = held;
    });
  }

  int? _count(BoardTab t) => switch (t) {
    BoardTab.improvements => _counts?.ideas,
    BoardTab.bugs => _counts?.bugs,
    BoardTab.tasks => _counts?.upForGrabs,
    BoardTab.claimed => _counts?.claimed,
    BoardTab.done || BoardTab.search => null,
    BoardTab.review => _held,
  };

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final inset = shellPageInset(width);
    final tab = widget.tab == BoardTab.review && !hub.isAdmin
        ? (hub.me.value == null ? BoardTab.review : BoardTab.improvements)
        : widget.tab;
    final search = widget.search;
    final tabs = [
      BoardTab.improvements,
      BoardTab.bugs,
      BoardTab.tasks,
      BoardTab.claimed,
      BoardTab.done,
      if (hub.isAdmin) BoardTab.review,
    ];
    final header = Padding(
      padding: EdgeInsets.fromLTRB(inset, 24, inset, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (!s.auth.isSignedIn)
            BoardNotice(
              key: const ValueKey<String>('board.signedOutBanner'),
              icon: LucideIcons.logIn,
              text: l.boardSignInToVote,
              tone: theme.colorScheme.info,
              action: ShadButton.outline(
                key: const ValueKey<String>('board.signedOutBanner.signIn'),
                size: ShadButtonSize.sm,
                onPressed: () => boardSignIn(s),
                child: Text(l.boardSignIn),
              ),
            ),
          if (hub.me.value?.blocked == true)
            BoardNotice(
              icon: LucideIcons.ban,
              text: l.boardBlocked,
              tone: theme.colorScheme.destructive,
            ),
          BoardTabsBar(
            key: const ValueKey<String>('board.tabs'),
            // The results of a search of all posts: no tab is selected.
            value: tab == BoardTab.search
                ? null
                : (tabs.contains(tab) ? tab : BoardTab.improvements),
            onChanged: (t) => boardOpenList(s, t, context: context),
            tabs: [
              for (final t in tabs)
                BoardTabItem(
                  tab: t,
                  label: boardTabName(l, t),
                  count: _count(t),
                ),
            ],
            trailing: BoardSearchButton(
              services: s,
              controller: _searchPopover,
              search: search,
            ),
          ),
        ],
      ),
    );
    final Widget body = switch (tab) {
      BoardTab.search when search == null => WonkyEmptyState(
        key: const ValueKey<String>('board.search.start'),
        illustration: EmptyIllustration.search,
        title: l.boardSearchStartTitle,
        description: l.boardSearchStartHint,
        actions: [
          ShadButton.outline(
            leading: const Icon(LucideIcons.search, size: 16),
            onPressed: _searchPopover.show,
            child: Text(l.boardSearchButton),
          ),
        ],
      ),
      BoardTab.improvements ||
      BoardTab.bugs ||
      BoardTab.done ||
      BoardTab.search => BoardPostList(
        key: ValueKey<String>('board.list.${tab.name}'),
        services: s,
        tab: tab,
        search: search,
      ),
      BoardTab.tasks => BoardTaskList(
        key: const ValueKey<String>('board.tasks'),
        services: s,
        statuses: const [BoardTaskStatus.published],
        live: true,
        selectable: true,
      ),
      BoardTab.claimed => BoardTaskList(
        key: const ValueKey<String>('board.claimed'),
        services: s,
        statuses: const [BoardTaskStatus.claimed, BoardTaskStatus.inReview],
        live: true,
        emptyTitle: l.boardEmptyClaimed,
        emptyDescription: l.boardEmptyClaimedHint,
      ),
      BoardTab.review =>
        hub.me.value == null
            ? const BoardListLoading()
            : BoardReviewTab(services: s),
    };
    return BoardFrame(
      services: s,
      trail: BoardTrail(list: tab, search: search),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- posts

/// The posts of a board tab (Improvements, Bugs, Done) or the results of a
/// search ([BoardTab.search], all posts): filter chips (with the active
/// search as a removable chip), sort, rows, *Load more*, empty states, and
/// the admin selection mode (not on the results).
class BoardPostList extends StatefulWidget {
  const BoardPostList({
    super.key,
    required this.services,
    required this.tab,
    this.search,
  });

  final ShellServices services;
  final BoardTab tab;
  final BoardSearchQuery? search;

  String get query => search?.text ?? '';

  @override
  State<BoardPostList> createState() => _BoardPostListState();
}

class _BoardPostListState extends State<BoardPostList> {
  ShellServices get s => widget.services;
  BoardHub get hub => BoardHub.of(s);

  final List<BoardPostListItem> _items = [];
  String? _cursor;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _generation = 0;

  Set<BoardArea> _areas = {};
  BoardSize? _size;
  late Set<BoardPostStatus> _statuses = _defaultStatuses;
  bool _mine = false;
  BoardSort _sort = BoardSort.trending;

  bool _selecting = false;
  final Set<int> _selected = {};

  StreamSubscription<BoardChange>? _changes;

  bool get _done => widget.tab == BoardTab.done;

  bool get _results => widget.tab == BoardTab.search;

  Set<BoardPostStatus> get _defaultStatuses =>
      BoardSearchQuery.statusesFor(widget.tab, widget.search);

  @override
  void initState() {
    super.initState();
    _changes = hub.changes.listen((c) {
      if (c.lists) unawaited(_load(keep: true));
    });
    unawaited(_load());
  }

  @override
  void didUpdateWidget(BoardPostList old) {
    super.didUpdateWidget(old);
    if (old.search != widget.search) {
      _statuses = _defaultStatuses;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  BoardListQuery _q(String? cursor, int limit) => BoardListQuery(
    kind: switch (widget.tab) {
      BoardTab.improvements => BoardPostKind.idea,
      BoardTab.bugs => BoardPostKind.bug,
      BoardTab.search => widget.search?.kind,
      _ => null,
    },
    statuses: [..._statuses],
    areas: [..._areas],
    sizes: [?_size],
    sort: _sort,
    query: widget.query.isEmpty ? null : widget.query,
    mine: _mine,
    cursor: cursor,
    limit: limit,
  );

  /// Loads the first page; [keep] reloads as many rows as are shown.
  Future<void> _load({bool keep = false}) async {
    final gen = ++_generation;
    final limit = keep && _items.length > boardPageSize
        ? _items.length
        : boardPageSize;
    if (!keep) setState(() => _loading = true);
    try {
      final page = await s.repositories.board.list(_q(null, limit));
      if (!mounted || gen != _generation) return;
      hub.notePosts(page.items);
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _cursor = page.nextCursor;
        _total = page.total;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await s.repositories.board.list(_q(cursor, boardPageSize));
      if (!mounted || gen != _generation) return;
      hub.notePosts(page.items);
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _total = page.total;
      });
    } catch (e) {
      final l = s.l10n;
      if (l != null) {
        s.toasts.error(l.errorGeneric, description: errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _set(VoidCallback change) {
    setState(change);
    unawaited(_load());
  }

  Future<void> _vote(BoardPostListItem item, int value) async {
    if (!s.auth.isSignedIn) return boardSignIn(s);
    final r = await boardInvoke(s, 'shell.board.vote', {
      'postNumber': item.number,
      'value': value,
    }, context: context);
    final data = r?.data;
    if (!mounted || r?.isOk != true || data is! Map) return;
    final i = _items.indexWhere((x) => x.number == item.number);
    if (i < 0) return;
    setState(() {
      _items[i] = _items[i].copyWith(
        score: data['score'] as int?,
        myVote: data['myVote'] as int?,
      );
    });
  }

  Future<void> _createTask() async {
    final r = await boardInvoke(s, 'shell.board.admin.createTask', {
      'postNumbers': [..._selected],
    }, context: context);
    final n = (r?.data as Map?)?['taskNumber'];
    if (r?.isOk == true && mounted) {
      setState(() {
        _selected.clear();
        _selecting = false;
      });
      if (n is int) boardOpenTask(s, n, context: context);
    }
  }

  Future<void> _addToTask() async {
    final r = await boardInvoke(s, 'shell.board.admin.setTaskPosts', {
      'add': [..._selected],
    }, context: context);
    if (r?.isOk == true && mounted) {
      setState(() {
        _selected.clear();
        _selecting = false;
      });
    }
  }

  /// The filter bar: the drive's filter chips (outline buttons with a
  /// chevron that open a menu; the label names the current value) in one
  /// horizontally scrolling row.
  Widget _filters(WonkyAppLocalizations l, double inset) {
    Widget chip(
      String key,
      String label,
      List<WonkyMenuEntry> Function() entries,
    ) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: WonkyDropdownMenu(
        entries: entries,
        builder: (context, ctl) => ShadButton.outline(
          key: ValueKey<String>('board.filter.$key'),
          size: ShadButtonSize.sm,
          trailing: const Icon(LucideIcons.chevronDown, size: 14),
          onPressed: ctl.toggle,
          child: Text(label),
        ),
      ),
    );

    String named(String name, Iterable<String> values) =>
        values.isEmpty ? name : '$name: ${values.join(', ')}';
    final statuses = _done
        ? const [BoardPostStatus.done, BoardPostStatus.shipped]
        : BoardPostStatus.values;
    final hub = this.hub;
    final search = widget.search;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(inset, 8, inset, 8),
      child: SingleChildScrollView(
        key: const ValueKey<String>('board.filterBar'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (search != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _SearchChip(
                  label: l.boardSearchActive(search.text),
                  removeLabel: l.boardSearchRemove,
                  onRemove: () => boardOpenSearch(s, null, context: context),
                ),
              ),
            chip(
              'area',
              named(l.boardFilterArea, [
                for (final a in BoardArea.values)
                  if (_areas.contains(a)) l.boardAreaName(a),
              ]),
              () => [
                for (final a in BoardArea.values)
                  WonkyMenuCheckItem(
                    key: ValueKey<String>('board.filter.area.${a.name}'),
                    label: l.boardAreaName(a),
                    checked: _areas.contains(a),
                    onSelected: () => _set(
                      () => _areas = _areas.contains(a)
                          ? ({..._areas}..remove(a))
                          : {..._areas, a},
                    ),
                  ),
              ],
            ),
            chip(
              'size',
              named(l.boardFilterSize, [?_size].map(l.boardSizeName)),
              () => [
                WonkyMenuRadioItem(
                  key: const ValueKey<String>('board.filter.size.any'),
                  label: l.boardFilterAny,
                  selected: _size == null,
                  onSelected: () => _set(() => _size = null),
                ),
                for (final x in BoardSize.values)
                  WonkyMenuRadioItem(
                    key: ValueKey<String>('board.filter.size.${x.name}'),
                    label: l.boardSizeName(x),
                    selected: _size == x,
                    onSelected: () => _set(() => _size = x),
                  ),
              ],
            ),
            chip(
              'status',
              named(l.boardFilterStatus, [
                if (!_sameSet(_statuses, _defaultStatuses))
                  for (final x in statuses)
                    if (_statuses.contains(x)) l.boardStatusName(x),
              ]),
              () => [
                for (final x in statuses)
                  WonkyMenuCheckItem(
                    key: ValueKey<String>('board.filter.status.${x.name}'),
                    label: l.boardStatusName(x),
                    checked: _statuses.contains(x),
                    onSelected: () => _set(() {
                      final next = _statuses.contains(x)
                          ? ({..._statuses}..remove(x))
                          : {..._statuses, x};
                      _statuses = next.isEmpty ? _defaultStatuses : next;
                    }),
                  ),
              ],
            ),
            if (s.auth.isSignedIn)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Semantics(
                  toggled: _mine,
                  button: true,
                  child: ShadButton.outline(
                    key: const ValueKey<String>('board.filter.mine'),
                    size: ShadButtonSize.sm,
                    leading: _mine
                        ? const Icon(LucideIcons.check, size: 14)
                        : null,
                    onPressed: () => _set(() => _mine = !_mine),
                    child: Text(l.boardFilterMine),
                  ),
                ),
              ),
            chip(
              'sort',
              l.sortBy(l.boardSortName(_sort)),
              () => [
                for (final x in BoardSort.values)
                  WonkyMenuRadioItem(
                    key: ValueKey<String>('board.sort.${x.name}'),
                    label: l.boardSortName(x),
                    selected: _sort == x,
                    onSelected: () => _set(() => _sort = x),
                  ),
              ],
            ),
            if (hub.isAdmin && !_done && !_results)
              ShadButton.ghost(
                key: const ValueKey<String>('board.select'),
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
      ),
    );
  }

  /// The drive's selection bar: a `secondary` pill that replaces the filter
  /// bar in place (same height, so the rows do not move) with *Clear*, the
  /// count and the actions.
  Widget _selectionBar(
    WonkyAppLocalizations l,
    ShadThemeData theme,
    double inset,
  ) => Container(
    key: const ValueKey<String>('board.selectionBar'),
    margin: EdgeInsetsDirectional.fromSTEB(
      math.max(0, inset - 8),
      4,
      math.max(0, inset - 8),
      4,
    ),
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
              key: const ValueKey<String>('board.selection.clear'),
              width: 32,
              height: 32,
              iconSize: 16,
              semanticLabel: l.actionClear,
              icon: const Icon(LucideIcons.x),
              onPressed: () => setState(() {
                _selected.clear();
                _selecting = false;
              }),
            ),
          ),
          Text(l.boardSelected(_selected.length), style: theme.textTheme.small),
          const SizedBox(width: 12),
          ShadButton.ghost(
            key: const ValueKey<String>('board.selection.createTask'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.hammer, size: 14),
            onPressed: _createTask,
            child: Text(l.boardCreateTaskFrom(_selected.length)),
          ),
          ShadButton.ghost(
            key: const ValueKey<String>('board.selection.addToTask'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.listPlus, size: 14),
            onPressed: _addToTask,
            child: Text(l.boardAddToTaskEllipsis),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 600;
    final inset = shellPageInset(width);
    final Widget list;
    if (_loading) {
      list = const BoardListLoading(key: ValueKey('board.loading'));
    } else if (_error != null && _items.isEmpty) {
      final offline = isOfflineError(_error!);
      list = WonkyEmptyState(
        key: const ValueKey<String>('board.error'),
        illustration: offline
            ? EmptyIllustration.offline
            : EmptyIllustration.error,
        title: offline ? l.driveOfflineTitle : l.boardLoadFailed,
        description: offline ? null : errorMessage(_error!),
        actions: [
          ShadButton.outline(onPressed: _load, child: Text(l.actionRetry)),
        ],
      );
    } else if (_items.isEmpty) {
      list = WonkyEmptyState(
        key: const ValueKey<String>('board.empty'),
        illustration: widget.query.isNotEmpty
            ? EmptyIllustration.search
            : EmptyIllustration.comments,
        title: widget.query.isNotEmpty
            ? l.boardEmptySearch
            : switch (widget.tab) {
                BoardTab.bugs => l.boardEmptyBugs,
                BoardTab.done => l.boardEmptyDone,
                _ => l.boardEmptyIdeas,
              },
        description: widget.query.isNotEmpty
            ? l.boardEmptySearchHint
            : (_done ? null : l.boardEmptyHint),
      );
    } else {
      // Rows are inset by their own 8 px padding: their text lines up with
      // the header's.
      final rowInset = math.max(0.0, inset - 8);
      list = ListView.builder(
        key: const ValueKey<String>('board.rows'),
        padding: EdgeInsets.fromLTRB(rowInset, 0, rowInset, 24),
        itemCount: _items.length + 1,
        itemBuilder: (context, i) {
          if (i == _items.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Text(
                    l.boardShowing(_items.length, _total),
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                  if (_cursor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ShadButton.outline(
                        key: const ValueKey<String>('board.loadMore'),
                        enabled: !_loadingMore,
                        leading: _loadingMore
                            ? const ShadSpinner(size: 14)
                            : null,
                        onPressed: _loadMore,
                        child: Text(l.boardLoadMore),
                      ),
                    ),
                ],
              ),
            );
          }
          final item = _items[i];
          return BoardPostRow(
            key: ValueKey<String>('board.row.${item.number}'),
            services: s,
            item: item,
            narrow: narrow,
            onVote: (v) => _vote(item, v),
            selected: _selecting ? _selected.contains(item.number) : null,
            onSelected: (v) => setState(
              () => v
                  ? _selected.add(item.number)
                  : _selected.remove(item.number),
            ),
          );
        },
      );
    }
    final search = widget.search;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The results of a search of all posts: a header names the search.
        if (_results && search != null)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(inset, 16, inset, 0),
            child: Semantics(
              header: true,
              child: Text(
                l.boardSearchResultsFor(search.text),
                key: const ValueKey<String>('board.search.header'),
                style: theme.textTheme.large,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        SizedBox(
          height: 48,
          child: _selecting && _selected.isNotEmpty
              ? _selectionBar(l, theme, inset)
              : _filters(l, inset),
        ),
        Expanded(
          child: _done ? _DoneLayout(services: s, posts: list) : list,
        ),
      ],
    );
  }
}

/// The active search in the filter row (specs/16 §4.4): *Search: “sort”*
/// with ✕; pressing it clears the search.
class _SearchChip extends StatelessWidget {
  const _SearchChip({
    required this.label,
    required this.removeLabel,
    required this.onRemove,
  });

  final String label;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label, $removeLabel',
    excludeSemantics: true,
    onTap: onRemove,
    child: ShadTooltip(
      builder: (_) => Text(removeLabel),
      child: ShadButton.secondary(
        key: const ValueKey<String>('board.filter.search'),
        size: ShadButtonSize.sm,
        leading: const Icon(LucideIcons.search, size: 14),
        trailing: const Icon(LucideIcons.x, size: 14),
        onPressed: onRemove,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ),
    ),
  );
}

bool _sameSet<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

/// The Done tab: finished tasks above the done and shipped posts.
class _DoneLayout extends StatelessWidget {
  const _DoneLayout({required this.services, required this.posts});

  final ShellServices services;
  final Widget posts;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final inset = shellPageInset(MediaQuery.sizeOf(context).width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: BoardTaskList(
            key: const ValueKey<String>('board.doneTasks'),
            services: services,
            statuses: const [BoardTaskStatus.done, BoardTaskStatus.shipped],
            compact: true,
            title: l.boardDoneTasks,
            horizontalPadding: math.max(0, inset - 8),
          ),
        ),
        Expanded(child: posts),
      ],
    );
  }
}

/// One post in the board list (specs/16 §4.4): the vote control, title,
/// labels, status, comment count, author and age, screenshot icon. `+` /
/// `-` on the focused row vote (specs/16 §4.7); Enter opens the post.
class BoardPostRow extends StatefulWidget {
  const BoardPostRow({
    super.key,
    required this.services,
    required this.item,
    required this.onVote,
    this.narrow = false,
    this.selected,
    this.onSelected,
  });

  final ShellServices services;
  final BoardPostListItem item;
  final ValueChanged<int> onVote;
  final bool narrow;

  /// Non-null in the admin selection mode.
  final bool? selected;
  final ValueChanged<bool>? onSelected;

  @override
  State<BoardPostRow> createState() => _BoardPostRowState();
}

class _BoardPostRowState extends State<BoardPostRow> {
  BoardPostListItem get item => widget.item;

  bool get _votingOpen =>
      item.status == BoardPostStatus.open ||
      item.status == BoardPostStatus.planned;

  void _open() => boardOpenPost(widget.services, item.number, context: context);

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final plus =
        k == LogicalKeyboardKey.add ||
        k == LogicalKeyboardKey.numpadAdd ||
        k == LogicalKeyboardKey.equal ||
        e.character == '+';
    final minus =
        k == LogicalKeyboardKey.minus ||
        k == LogicalKeyboardKey.numpadSubtract ||
        e.character == '-';
    if (plus || minus) {
      if (!_votingOpen) return KeyEventResult.handled;
      final bug = item.kind == BoardPostKind.bug;
      final int value;
      if (plus) {
        value = item.myVote == 1 ? 0 : 1;
      } else {
        value = bug || item.myVote == -1 ? 0 : -1;
      }
      if (value != item.myVote) widget.onVote(value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final muted = theme.textTheme.muted.copyWith(fontSize: 12);
    final vote = BoardVoteControl(
      number: item.number,
      kind: item.kind,
      score: item.score,
      voteCount: item.voteCount,
      myVote: item.myVote,
      onVote: _votingOpen ? widget.onVote : null,
    );
    final task = item.task;
    final meta = <Widget>[
      ...boardLabelChips(
        l,
        area: item.area,
        size: item.size,
        ai: item.aiLabels,
      ),
      BoardStatusBadge(
        status: item.status,
        label: task != null && item.status == BoardPostStatus.planned
            ? l.boardPlannedIn(task.number)
            : l.boardStatusName(item.status),
        onTap: task == null
            ? null
            : () =>
                  boardOpenTask(widget.services, task.number, context: context),
      ),
      if (item.moderation != BoardModeration.visible)
        BoardChip(label: l.boardModerationName(item.moderation)),
      Semantics(
        label: l.boardCommentCount(item.commentCount),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 14,
              color: cs.mutedForeground,
            ),
            Text('${item.commentCount}', style: muted),
          ],
        ),
      ),
      if (item.hasScreenshot)
        Semantics(
          label: l.boardHasScreenshot,
          excludeSemantics: true,
          child: Icon(LucideIcons.camera, size: 14, color: cs.mutedForeground),
        ),
      BoardAuthorLine(
        author: item.author,
        createdAt: item.createdAt,
        avatar: false,
      ),
    ];
    final selected = widget.selected;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: BoardListTile(
        semanticLabel: '#${item.number} ${item.title}',
        selected: selected == true,
        onTap: _open,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ShadCheckbox(
                  key: ValueKey<String>('board.row.${item.number}.select'),
                  value: selected,
                  onChanged: widget.onSelected,
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48),
              child: Center(widthFactor: 1, child: vote),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  BoardNumberedTitle(
                    number: '#${item.number}',
                    title: item.title,
                    maxLines: widget.narrow ? 3 : 2,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: meta,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
