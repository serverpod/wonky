import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';

import '../../shell/shell_services.dart';
import '../board_hub.dart';

/// The lists (tabs) of the board page (specs/16 §4.3–4.4), and [search],
/// the results of a search across all posts (not a tab: the tabs show no
/// selection while it is open).
enum BoardTab {
  improvements('/improvements'),
  bugs('/improvements/bugs'),
  tasks('/improvements/tasks'),
  claimed('/improvements/claimed'),
  done('/improvements/done'),
  review('/improvements/review'),
  search('/improvements/search');

  const BoardTab(this.path);

  final String path;

  /// Whether the list shows posts (a post opened from it stays under it).
  bool get hasPosts => this != BoardTab.tasks && this != BoardTab.claimed;

  /// Whether the list shows tasks (a task opened from it stays under it).
  /// *Done* lists finished issues only (specs/16 §4.4).
  bool get hasTasks =>
      this == BoardTab.tasks ||
      this == BoardTab.claimed ||
      this == BoardTab.review;

  static BoardTab? byName(String? name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// The list a task belongs to by its [status]: *Claimed* while claimed or
  /// in review, *Done* when done or shipped, else *Up for grabs*.
  static BoardTab ofTask(BoardTaskStatus status) => switch (status) {
    BoardTaskStatus.claimed || BoardTaskStatus.inReview => BoardTab.claimed,
    BoardTaskStatus.done || BoardTaskStatus.shipped => BoardTab.done,
    _ => BoardTab.tasks,
  };
}

/// A search of the board's posts (specs/16 §4.4, §6.4): the [text] (the
/// server matches word prefixes, title substrings and post numbers), and
/// the options of the search popover: [closed] adds done, shipped,
/// declined and duplicate posts; [kind] narrows it to bugs or
/// improvements. A search always covers all posts and is shown in the
/// results view ([BoardTab.search]); in the URL as
/// `/improvements/search?q=sort&closed=1&kind=bug`.
@immutable
class BoardSearchQuery {
  const BoardSearchQuery(this.text, {this.closed = false, this.kind});

  final String text;
  final bool closed;
  final BoardPostKind? kind;

  /// The search in [query] for list [tab]; null without a `q`, or when
  /// [tab] is not the results view (the tabs are never searched).
  static BoardSearchQuery? parse(Map<String, String> query, BoardTab tab) {
    final text = (query['q'] ?? '').trim();
    if (text.isEmpty || tab != BoardTab.search) return null;
    return BoardSearchQuery(
      text,
      closed: query['closed'] == '1',
      kind: switch (query['kind']) {
        'bug' => BoardPostKind.bug,
        'idea' => BoardPostKind.idea,
        _ => null,
      },
    );
  }

  /// The URL query parameters of this search.
  List<String> get queryParameters => [
    'q=${Uri.encodeQueryComponent(text)}',
    if (closed) 'closed=1',
    if (kind case final k?) 'kind=${k.name}',
  ];

  /// The statuses the list [tab] shows (with [search] on the results
  /// view): open and planned (Done: done and shipped), plus the closed ones
  /// when the search includes them.
  static Set<BoardPostStatus> statusesFor(
    BoardTab tab,
    BoardSearchQuery? search,
  ) {
    final closed = search?.closed ?? false;
    if (tab == BoardTab.done) {
      return {BoardPostStatus.done, BoardPostStatus.shipped};
    }
    return {
      BoardPostStatus.open,
      BoardPostStatus.planned,
      if (closed) ...[
        BoardPostStatus.done,
        BoardPostStatus.shipped,
        BoardPostStatus.declined,
        BoardPostStatus.duplicate,
      ],
    };
  }

  @override
  bool operator ==(Object other) =>
      other is BoardSearchQuery &&
      other.text == text &&
      other.closed == closed &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(text, closed, kind);

  @override
  String toString() => 'BoardSearchQuery(${queryParameters.join('&')})';
}

/// Whether [location] is a board route (`/improvements…`).
bool isBoardLocation(String location) =>
    location == '/improvements' ||
    location.startsWith('/improvements/') ||
    location.startsWith('/improvements?') ||
    location.startsWith('/improvements#');

/// Where closing the board goes (specs/16 §4.3): the last visited route that
/// is not a board page, else home.
String boardBackTarget(ShellServices s) {
  final h = s.navHistory;
  for (var i = s.navIndex; i >= 0 && i < h.length; i--) {
    if (!isBoardLocation(h[i])) return h[i];
  }
  return '/';
}

/// Closes the board: back to [boardBackTarget] (the app icon crumb).
void closeBoard(ShellServices s) => s.router.go(boardBackTarget(s));

/// A place on the board as a breadcrumb trail (specs/16 §4.3): the board
/// root › [list] › [task] › [post], or the contribute page. The trail is
/// derived from the board's hierarchy, never from the browser history, and
/// travels in the URL query (`/improvements/p/5?list=tasks&task=1`), so a
/// reload or a shared link keeps it.
///
/// A null [list] on a post or task means "the item's own list": the post's
/// kind (*Bugs* or *Improvements*; the task's list under a task), the
/// task's status ([BoardTab.ofTask]); see [resolve]. A [search] belongs to
/// the results view ([BoardTab.search]) and travels with the posts opened
/// from it, so the list crumb returns to the results.
@immutable
class BoardTrail {
  const BoardTrail({
    this.list,
    this.task,
    this.post,
    this.contribute = false,
    this.search,
  }) : assert(!contribute || (list == null && task == null && post == null));

  /// The board root (the *Improvements* list).
  static const root = BoardTrail(list: BoardTab.improvements);

  final BoardTab? list;
  final int? task;
  final int? post;
  final bool contribute;
  final BoardSearchQuery? search;

  /// A list page (no item below the list).
  bool get isList => !contribute && task == null && post == null;

  /// A task page (the task is the last step).
  bool get isTask => task != null && post == null;

  bool get isPost => post != null;

  /// The trail of a board [uri]; null when it is not a board route.
  /// Unknown or contradictory query values fall back to the defaults.
  static BoardTrail? parse(Uri uri) {
    final seg = uri.pathSegments.where((x) => x.isNotEmpty).toList();
    if (seg.isEmpty || seg.first != 'improvements') return null;
    final q = uri.queryParameters;
    if (seg.length == 1) return root;
    if (seg.length == 2) {
      if (seg[1] == 'contribute') return const BoardTrail(contribute: true);
      final tab = BoardTab.byName(seg[1]);
      // `/improvements` itself is the Improvements list.
      return tab == null || tab == BoardTab.improvements
          ? null
          : BoardTrail(list: tab, search: BoardSearchQuery.parse(q, tab));
    }
    if (seg.length != 3) return null;
    final n = int.tryParse(seg[2]);
    if (n == null) return null;
    var list = BoardTab.byName(q['list']);
    switch (seg[1]) {
      case 'p':
        final task = int.tryParse(q['task'] ?? '');
        if (task != null && list != null && !list.hasTasks) list = null;
        if (list != null && task == null && !list.hasPosts) list = null;
        return BoardTrail(
          list: list,
          task: task,
          post: n,
          search: list == null || task != null
              ? null
              : BoardSearchQuery.parse(q, list),
        );
      case 't':
        if (list != null && !list.hasTasks) list = null;
        return BoardTrail(list: list, task: n);
    }
    return null;
  }

  /// The trail of the current route of [s] with its defaults resolved from
  /// what the board last showed ([resolve]).
  static BoardTrail? here(ShellServices s) {
    final t = parse(s.router.routerDelegate.currentConfiguration.uri);
    return t?.resolve(BoardHub.of(s));
  }

  /// Fills in a missing [list] from the item: a post under a task is in
  /// the task's list (*Up for grabs* while the task is unknown); a post in
  /// its kind's list; a task in its status's list ([BoardTab.ofTask]).
  /// Stays null while the item is unknown.
  BoardTrail resolve(
    BoardHub hub, {
    BoardPostKind? postKind,
    BoardTaskStatus? taskStatus,
  }) {
    if (list != null || contribute) return this;
    final BoardTab? l;
    if (post case final p?) {
      if (task case final t?) {
        final status = hub.taskStatuses[t];
        l = status == null ? BoardTab.tasks : BoardTab.ofTask(status);
      } else {
        l = switch (postKind ?? hub.postKinds[p]) {
          BoardPostKind.bug => BoardTab.bugs,
          BoardPostKind.idea => BoardTab.improvements,
          _ => null,
        };
      }
    } else if (task case final t?) {
      final status = taskStatus ?? hub.taskStatuses[t];
      l = status == null ? null : BoardTab.ofTask(status);
    } else {
      l = null;
    }
    return l == null ? this : BoardTrail(list: l, task: task, post: post);
  }

  /// The route of this trail: the page's path with the trail's query.
  String get location {
    if (contribute) return '/improvements/contribute';
    final query = <String>[
      if (list != null && !isList) 'list=${list!.name}',
      if (post != null && task != null) 'task=$task',
      ...?search?.queryParameters,
    ];
    final path = switch ((post, task)) {
      (final int p, _) => '/improvements/p/$p',
      (null, final int t) => '/improvements/t/$t',
      _ => (list ?? BoardTab.improvements).path,
    };
    return query.isEmpty ? path : '$path?${query.join('&')}';
  }

  /// Opening post [number] from here (specs/16 §4.3):
  /// - from a list: root › list › post (the list's own when it has no
  ///   posts: *Up for grabs* → the post's kind);
  /// - from a task: root › list › task › post;
  /// - from a post: the new post replaces this one (siblings: similar posts,
  ///   merged duplicates, *duplicate of*);
  /// - the post already here: unchanged.
  BoardTrail openPost(int number) {
    if (post == number) return this;
    if (post != null || task != null) {
      return BoardTrail(list: list, task: task, post: number, search: search);
    }
    if (contribute) return BoardTrail(post: number);
    final l = list;
    final keep = l != null && l.hasPosts;
    return BoardTrail(
      list: keep ? l : null,
      post: number,
      search: keep ? search : null,
    );
  }

  /// Opening task [number] from here: the task in the trail truncates the
  /// trail to it (a post's own task: root › list › T-n, never post › task ›
  /// post); any other task replaces the trail below the list, keeping the
  /// list when it shows tasks (else the task's own list).
  BoardTrail openTask(int number) {
    if (task == number) return BoardTrail(list: list, task: number);
    final l = list;
    return BoardTrail(list: l != null && l.hasTasks ? l : null, task: number);
  }

  /// Opening list [tab] (a tab, the root crumb).
  BoardTrail openList(BoardTab tab) => BoardTrail(list: tab);

  /// Whether going from here to [next] stays at the same depth (switching
  /// tabs, a post to a sibling post, a task to another task): such moves
  /// replace the history entry, so Back never walks through loops. A new or
  /// cleared search is not a sibling: Back returns to the list before it.
  bool isSiblingOf(BoardTrail next) {
    if (isList && next.isList) return search == next.search;
    if (isPost && next.isPost) return task == next.task && post != next.post;
    if (isTask && next.isTask) return task != next.task;
    return false;
  }

  @override
  bool operator ==(Object other) =>
      other is BoardTrail &&
      other.list == list &&
      other.task == task &&
      other.post == post &&
      other.contribute == contribute &&
      other.search == search;

  @override
  int get hashCode => Object.hash(list, task, post, contribute, search);

  @override
  String toString() => 'BoardTrail($location)';
}

/// Navigates the board to [next] (specs/16 §4.3): `router.go` to its
/// location, replacing the history entry when the move stays at the same
/// depth ([BoardTrail.isSiblingOf]), so the shell's Back (`Mod+[`, the
/// browser's back) still steps through real history without loops. With
/// [merged], the post page says it came from that merged duplicate.
void boardGo(
  ShellServices s,
  BoardTrail next, {
  BuildContext? context,
  bool replace = false,
  int? merged,
}) {
  var location = next.location;
  if (merged != null) {
    location += '${location.contains('?') ? '&' : '?'}merged=$merged';
  }
  final here = BoardTrail.here(s);
  if (replace || (here != null && here.isSiblingOf(next))) {
    s.goReplacing(location, context: context);
  } else {
    s.router.go(location);
  }
}

/// Opens post [number] from the current board page ([BoardTrail.openPost]).
void boardOpenPost(ShellServices s, int number, {BuildContext? context}) =>
    boardGo(
      s,
      (BoardTrail.here(s) ?? BoardTrail.root).openPost(number),
      context: context,
    );

/// Opens task [number] from the current board page ([BoardTrail.openTask]).
void boardOpenTask(ShellServices s, int number, {BuildContext? context}) =>
    boardGo(
      s,
      (BoardTrail.here(s) ?? BoardTrail.root).openTask(number),
      context: context,
    );

/// Opens list [tab] (a tab switch replaces the history entry).
void boardOpenList(ShellServices s, BoardTab tab, {BuildContext? context}) =>
    boardGo(s, BoardTrail(list: tab), context: context);

/// Opens the results of [search] across all posts ([BoardTab.search]); a
/// null [search] clears it (back to the Improvements list).
void boardOpenSearch(
  ShellServices s,
  BoardSearchQuery? search, {
  BuildContext? context,
}) => boardGo(
  s,
  search == null
      ? const BoardTrail(list: BoardTab.improvements)
      : BoardTrail(list: BoardTab.search, search: search),
  context: context,
);

/// Opens *How to contribute*.
void boardOpenContribute(ShellServices s) =>
    boardGo(s, const BoardTrail(contribute: true));
