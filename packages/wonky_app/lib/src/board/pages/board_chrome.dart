import 'dart:ui' show SemanticsRole;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/wonky_app_localizations.dart';
import '../../shell/shell_services.dart';
import 'board_trail.dart';
import 'board_widgets.dart';

/// The name of board list [tab].
String boardTabName(WonkyAppLocalizations l, BoardTab tab) => switch (tab) {
  BoardTab.improvements => l.boardTabImprovements,
  BoardTab.bugs => l.boardTabBugs,
  BoardTab.tasks => l.boardTabTasks,
  BoardTab.claimed => l.boardTabClaimed,
  BoardTab.done => l.boardTabDone,
  BoardTab.review => l.boardTabReview,
  BoardTab.search => l.boardSearchResults,
};

/// One step of the board's breadcrumb: its [label] and where it leads
/// ([target]; null for the current page, the last crumb).
class BoardCrumb {
  const BoardCrumb({required this.id, required this.label, this.target});

  /// `root`, `list`, `task`, `post` or `contribute` (key `board.crumb.<id>`).
  final String id;
  final String label;
  final BoardTrail? target;
}

/// The crumbs of [trail] after the app icon (specs/16 §4.3): *Bugs &
/// improvements* (the root, the Improvements list), the list, the task
/// (`T-1 Title`), the post (`#5 Title`) or *How to contribute*. The last
/// one is the current page.
List<BoardCrumb> boardCrumbs(
  WonkyAppLocalizations l,
  BoardTrail trail, {
  String? taskTitle,
  String? postTitle,
}) {
  String titled(String id, String? title) =>
      title == null || title.isEmpty ? id : '$id $title';
  final list = trail.list;
  final task = trail.task;
  final post = trail.post;
  final out = <BoardCrumb>[
    BoardCrumb(id: 'root', label: l.boardTitle, target: BoardTrail.root),
    if (trail.contribute)
      BoardCrumb(id: 'contribute', label: l.boardContributeTitle),
    if (list != null)
      BoardCrumb(
        id: 'list',
        label: switch (trail.search) {
          final q? when list == BoardTab.search => l.boardSearchResultsFor(
            q.text,
          ),
          _ => boardTabName(l, list),
        },
        target: BoardTrail(list: list, search: trail.search),
      ),
    if (task != null)
      BoardCrumb(
        id: 'task',
        label: titled('T-$task', taskTitle),
        target: BoardTrail(list: list, task: task),
      ),
    if (post != null)
      BoardCrumb(id: 'post', label: titled('#$post', postTitle)),
  ];
  final last = out.removeLast();
  return [...out, BoardCrumb(id: last.id, label: last.label)];
}

/// The board's breadcrumb (specs/16 §4.3) in the page frame's bar, in place
/// of back, logo and title: the app icon (closes the board,
/// [boardBackTarget]), then [crumbs] separated by chevrons; the last is the
/// current page (`aria-current`), the others are links (`small`,
/// `mutedForeground`, the foreground and an underline on hover, the focus
/// ring, Enter or Space). Long crumbs are ellipsized. When the trail does
/// not fit, the crumbs between the app icon and the current page collapse
/// into a *…* menu. The whole is a navigation landmark named *Breadcrumb*.
class BoardBreadcrumb extends StatelessWidget {
  const BoardBreadcrumb({
    super.key,
    required this.services,
    required this.crumbs,
  });

  final ShellServices services;
  final List<BoardCrumb> crumbs;

  /// The widest a link crumb gets before it is ellipsized.
  static const double maxCrumbWidth = 220;

  /// The least room the current crumb keeps before the trail collapses.
  static const double minLastWidth = 120;

  static const double _iconWidth = 32;
  static const double _separatorWidth = 22;
  static const double _crumbPadding = 10;

  /// The width every crumb needs uncollapsed: link crumbs up to
  /// [maxCrumbWidth], the current one up to [minLastWidth] (or, when
  /// [comfortable], up to [maxCrumbWidth] too).
  static double fullWidth(
    BuildContext context,
    List<BoardCrumb> crumbs, {
    bool comfortable = false,
  }) {
    final style = _linkStyle(ShadTheme.of(context));
    var need = _iconWidth;
    for (var i = 0; i < crumbs.length; i++) {
      final w = boardTextWidth(context, crumbs[i].label, style) + _crumbPadding;
      final cap = i == crumbs.length - 1 && !comfortable
          ? minLastWidth
          : maxCrumbWidth;
      need += _separatorWidth + (w < cap ? w : cap);
    }
    return need;
  }

  static TextStyle _linkStyle(ShadThemeData theme) =>
      theme.textTheme.small.copyWith(fontWeight: FontWeight.w500);

  void _go(BuildContext context, BoardTrail target) =>
      boardGo(services, target, context: context);

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    Widget separator() => SizedBox(
      width: _separatorWidth,
      child: ExcludeSemantics(
        child: Icon(
          LucideIcons.chevronRight,
          size: 14,
          color: cs.mutedForeground,
        ),
      ),
    );
    Widget link(BoardCrumb c) => _BoardCrumbLink(
      key: ValueKey<String>('board.crumb.${c.id}'),
      label: c.label,
      onTap: () => _go(context, c.target!),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: maxCrumbWidth - _crumbPadding,
        ),
        child: Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    Widget current(BoardCrumb c) => Semantics(
      container: true,
      selected: true,
      label: c.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _crumbPadding / 2),
        child: Text(
          c.label,
          key: ValueKey<String>('board.crumb.${c.id}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _linkStyle(theme).copyWith(color: cs.foreground),
        ),
      ),
    );
    final app = ShadTooltip(
      builder: (_) => Text(l.boardClose),
      child: _BoardCrumbLink(
        key: const ValueKey<String>('board.crumb.app'),
        label: l.boardClose,
        onTap: () => closeBoard(services),
        padding: const EdgeInsets.all(2),
        child: services.config.logo(size: 24),
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: l.boardBreadcrumb,
      child: FocusTraversalGroup(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final full = fullWidth(context, crumbs) <= constraints.maxWidth;
            final last = crumbs.last;
            final hidden = full
                ? const <BoardCrumb>[]
                : crumbs.sublist(0, crumbs.length - 1);
            return Row(
              key: ValueKey<String>(
                full ? 'board.breadcrumb' : 'board.breadcrumb.collapsed',
              ),
              children: [
                app,
                if (full)
                  for (final c in crumbs.take(crumbs.length - 1)) ...[
                    separator(),
                    link(c),
                  ]
                else if (hidden.isNotEmpty) ...[
                  separator(),
                  WonkyDropdownMenu(
                    entries: () => [
                      for (final c in hidden)
                        WonkyMenuItem(
                          key: ValueKey<String>('board.crumb.menu.${c.id}'),
                          label: c.label,
                          onSelected: () => _go(context, c.target!),
                        ),
                    ],
                    builder: (context, ctl) => ShadTooltip(
                      builder: (_) => Text(l.boardShowPath),
                      child: ShadIconButton.ghost(
                        key: const ValueKey<String>('board.crumb.more'),
                        width: 28,
                        height: 28,
                        iconSize: 16,
                        semanticLabel: l.boardShowPath,
                        icon: const Icon(LucideIcons.ellipsis),
                        onPressed: ctl.toggle,
                      ),
                    ),
                  ),
                ],
                separator(),
                Flexible(child: current(last)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A link crumb: [child] with the hover underline and foreground, the
/// focus ring, and Enter / Space.
class _BoardCrumbLink extends StatefulWidget {
  const _BoardCrumbLink({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<_BoardCrumbLink> createState() => _BoardCrumbLinkState();
}

class _BoardCrumbLinkState extends State<_BoardCrumbLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final active = _hover || _focus;
    return Semantics(
      container: true,
      link: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _focus ? cs.ring : const Color(0x00000000),
                width: 1.5,
              ),
            ),
            child: DefaultTextStyle.merge(
              style: BoardBreadcrumb._linkStyle(theme).copyWith(
                color: active ? cs.foreground : cs.mutedForeground,
                decoration: _hover
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: cs.foreground,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The width of [text] in [style] on one line (layout decisions).
double boardTextWidth(BuildContext context, String text, TextStyle style) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final w = p.width;
  p.dispose();
  return w;
}

/// The board's part of the page frame's bar (specs/16 §4.3): the
/// breadcrumb, then the actions. The breadcrumb has priority: the actions
/// are labelled buttons only while the whole trail fits beside them, else
/// icon buttons (and the trail collapses if it still does not fit); below
/// [BoardTopActions.menuWidth] of window they are one menu.
class BoardBar extends StatelessWidget {
  const BoardBar({
    super.key,
    required this.services,
    required this.crumbs,
    this.showContribute = true,
  });

  final ShellServices services;
  final List<BoardCrumb> crumbs;
  final bool showContribute;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final window = MediaQuery.sizeOf(context).width;
    return LayoutBuilder(
      builder: (context, constraints) {
        final BoardActionsMode mode;
        if (window < BoardTopActions.menuWidth) {
          mode = BoardActionsMode.menu;
        } else {
          final labels = BoardTopActions.labelledWidth(context, [
            l.boardReportBug,
            l.boardSuggestImprovement,
            if (showContribute) l.boardContributeLink,
          ]);
          final trail = BoardBreadcrumb.fullWidth(
            context,
            crumbs,
            comfortable: true,
          );
          mode = trail + _gap + labels <= constraints.maxWidth
              ? BoardActionsMode.labels
              : BoardActionsMode.icons;
        }
        return Row(
          children: [
            Expanded(
              child: BoardBreadcrumb(services: services, crumbs: crumbs),
            ),
            const SizedBox(width: _gap),
            BoardTopActions(
              services: services,
              mode: mode,
              showContribute: showContribute,
            ),
          ],
        );
      },
    );
  }
}

/// How [BoardTopActions] shows: labelled buttons, icon buttons with
/// tooltips, or one *More actions* menu.
enum BoardActionsMode { labels, icons, menu }

/// The board's actions in the page frame's bar (specs/16 §4.3): *Report a
/// bug*, *Suggest an improvement* (both `shell.board.report`, which sends
/// signed-out visitors to sign in) and *How to contribute* (hidden on that
/// page), all outline `sm` buttons with their icons; as [mode] says, icon
/// buttons with tooltips or one *More actions* menu instead, so the bar
/// never overflows (360 px).
class BoardTopActions extends StatelessWidget {
  const BoardTopActions({
    super.key,
    required this.services,
    this.mode = BoardActionsMode.labels,
    this.showContribute = true,
  });

  final ShellServices services;
  final BoardActionsMode mode;
  final bool showContribute;

  /// Below this window width the actions are one menu.
  static const double menuWidth = 520;

  /// The width of the labelled buttons with [labels].
  static double labelledWidth(BuildContext context, List<String> labels) {
    final style = ShadTheme.of(
      context,
    ).textTheme.small.copyWith(fontWeight: FontWeight.w500);
    var w = 0.0;
    for (final label in labels) {
      // Text, the 16 px icon and its gap, the sm padding and the border.
      w += boardTextWidth(context, label, style) + 50 + 8;
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final s = services;
    final actions = <(String, IconData, String, VoidCallback)>[
      (
        'board.reportBug',
        LucideIcons.bug,
        l.boardReportBug,
        () => boardInvoke(s, 'shell.board.report', {
          'kind': 'bug',
        }, context: context),
      ),
      (
        'board.suggest',
        LucideIcons.leaf,
        l.boardSuggestImprovement,
        () => boardInvoke(s, 'shell.board.report', {
          'kind': 'idea',
        }, context: context),
      ),
      if (showContribute)
        (
          'board.howToContribute',
          LucideIcons.gitPullRequest,
          l.boardContributeLink,
          () => boardOpenContribute(s),
        ),
    ];
    if (mode == BoardActionsMode.menu) {
      return WonkyDropdownMenu(
        anchor: const ShadAnchor(
          childAlignment: AlignmentDirectional.bottomEnd,
          overlayAlignment: AlignmentDirectional.topEnd,
          offset: Offset(0, 4),
        ),
        entries: () => [
          for (final (key, icon, label, onTap) in actions)
            WonkyMenuItem(
              key: ValueKey<String>(key),
              icon: icon,
              label: label,
              onSelected: onTap,
            ),
        ],
        builder: (context, ctl) => ShadTooltip(
          builder: (_) => Text(l.moreActions),
          child: ShadIconButton.outline(
            key: const ValueKey<String>('board.actions.more'),
            width: 32,
            height: 32,
            iconSize: 16,
            semanticLabel: l.moreActions,
            icon: const Icon(LucideIcons.ellipsis),
            onPressed: ctl.toggle,
          ),
        ),
      );
    }
    final labelled = mode == BoardActionsMode.labels;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (final (key, icon, label, onTap) in actions)
          if (labelled)
            ShadButton.outline(
              key: ValueKey<String>(key),
              size: ShadButtonSize.sm,
              leading: Icon(icon, size: 16),
              onPressed: onTap,
              child: Text(label),
            )
          else
            ShadTooltip(
              builder: (_) => Text(label),
              child: ShadIconButton.outline(
                key: ValueKey<String>(key),
                width: 32,
                height: 32,
                iconSize: 16,
                semanticLabel: label,
                icon: Icon(icon),
                onPressed: onTap,
              ),
            ),
      ],
    );
  }
}

/// A tab of the board's tabs bar: its label and, when known, the count.
class BoardTabItem {
  const BoardTabItem({required this.tab, required this.label, this.count});

  final BoardTab tab;
  final String label;
  final int? count;
}

/// The board's tabs bar (specs/16 §4.4), styled like the editors' toolbar
/// strip (`muted` at 60 %, 20 px radius, the toolbar's height): the tabs on
/// the left as toolbar toggles (the active one highlighted; none while a
/// search of all posts shows, [value] null) with GitHub-like count badges,
/// and [trailing] (the search button) at the end. The tabs scroll
/// horizontally when they do not fit.
class BoardTabsBar extends StatelessWidget {
  const BoardTabsBar({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  final List<BoardTabItem> tabs;
  final BoardTab? value;
  final ValueChanged<BoardTab> onChanged;
  final Widget? trailing;

  /// Inner padding of the strip, and how far it reaches past the content
  /// column on each side so the first tab's edge lines up with the content
  /// below (the strip's rounded ends sit outside the column).
  static const double padding = 8;
  static const double bleed = 8;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final ext = WonkyThemeScope.of(context);
    final size = ext.toolbarButtonSize;
    final tt = theme.tabsTheme;
    Widget tab(BoardTabItem t) {
      final active = t.tab == value;
      final count = t.count;
      return Semantics(
        key: ValueKey<String>('board.tab.${t.tab.name}'),
        container: true,
        role: SemanticsRole.tab,
        selected: active,
        label: count == null ? t.label : l.boardTabWithCount(t.label, count),
        excludeSemantics: true,
        onTap: () => onChanged(t.tab),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): () =>
                onChanged(t.tab),
            const SingleActivator(LogicalKeyboardKey.space): () =>
                onChanged(t.tab),
          },
          child: ShadButton.ghost(
            height: size,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: active
                ? tt.tabSelectedBackgroundColor ?? cs.background
                : tt.tabBackgroundColor ?? const Color(0x00000000),
            hoverBackgroundColor: active
                ? tt.tabSelectedHoverBackgroundColor ?? cs.background
                : cs.background.withValues(alpha: 0.5),
            // Like ShadTabs: unselected tabs keep the foreground color (the
            // muted text would fail contrast on the muted strip).
            foregroundColor: active
                ? tt.tabSelectedForegroundColor ?? cs.foreground
                : tt.tabForegroundColor ?? cs.foreground,
            hoverForegroundColor: cs.foreground,
            shadows: active ? tt.tabSelectedShadows : null,
            decoration: tt.tabDecoration,
            onPressed: () => onChanged(t.tab),
            // Extends the theme's text style (the app font, Geist): a bare
            // TextStyle here would replace it and fall back to the browser's
            // default font.
            textStyle: theme.textTheme.small.copyWith(
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Text(t.label),
                if (count != null)
                  BoardCountBadge(
                    key: ValueKey<String>('board.tab.${t.tab.name}.count'),
                    count: count,
                    active: active,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final tabsRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Semantics(
        container: true,
        role: SemanticsRole.tabBar,
        explicitChildNodes: true,
        child: Row(spacing: 2, children: [for (final t in tabs) tab(t)]),
      ),
    );
    final trailing = this.trailing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final strip = Container(
          key: const ValueKey<String>('board.tabsBar'),
          height: ext.effectiveToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            color: cs.muted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: tabsRow,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 4), trailing],
            ],
          ),
        );
        // The strip is wider than the column by [bleed] on each side.
        return SizedBox(
          height: ext.effectiveToolbarHeight,
          child: OverflowBox(
            maxWidth: constraints.maxWidth + 2 * bleed,
            minWidth: constraints.maxWidth + 2 * bleed,
            child: strip,
          ),
        );
      },
    );
  }
}

/// A tab's count: a small rounded pill (`border` fill; stronger on the
/// active tab), tabular figures — like GitHub's tab counters. The figures
/// are one step smaller than the tab label (11 px) but semibold, in the
/// foreground color (muted text on `border` is too faint at that size).
class BoardCountBadge extends StatelessWidget {
  const BoardCountBadge({super.key, required this.count, this.active = false});

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // `border` as it is: in dark it is a translucent white, and setting
        // its alpha made an opaque white pill.
        color: active ? cs.mutedForeground.withValues(alpha: 0.22) : cs.border,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        style: ShadTheme.of(context).textTheme.small.copyWith(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: active ? cs.foreground : cs.foreground.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
