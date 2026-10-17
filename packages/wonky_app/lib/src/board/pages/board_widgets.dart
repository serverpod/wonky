import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart';

import '../../data/api.dart';
import '../../drive/drive_format.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/page_frame.dart';
import '../../shell/shell_scope.dart';
import '../../shell/shell_services.dart';
import 'board_chrome.dart';
import 'board_labels.dart';
import 'board_trail.dart';

/// Sends a signed-out visitor to sign-in, coming back to the current page.
void boardSignIn(ShellServices s) {
  final here = s.router.state.uri.toString();
  s.router.go('/signin?next=${Uri.encodeQueryComponent(here)}');
}

/// Invokes a board command from the UI; failures become an error toast.
Future<CommandResult?> boardInvoke(
  ShellServices s,
  String id,
  Map<String, Object?> args, {
  BuildContext? context,
}) async {
  try {
    return await s.dispatcher.invoke(
      id,
      args: args,
      source: InvocationSource.ui,
      context: context,
    );
  } catch (e) {
    final l = s.l10n;
    s.toasts.error(l?.errorGeneric ?? 'Error', description: errorMessage(e));
    return null;
  }
}

/// The board's page chrome (specs/16 §4.3): the settings-like
/// [ShellPageFrame] with the breadcrumb of [trail] ([BoardBreadcrumb]: the
/// app icon closes the board, the crumbs lead up the board's hierarchy) in
/// place of back, logo and title; the board's actions ([BoardBar]);
/// and the account menu or, signed out, *Sign in*. [taskTitle] and
/// [postTitle] complete the task and post crumbs once known.
class BoardFrame extends StatelessWidget {
  const BoardFrame({
    super.key,
    required this.services,
    required this.trail,
    required this.child,
    this.taskTitle,
    this.postTitle,
  });

  final ShellServices services;
  final BoardTrail trail;
  final Widget child;
  final String? taskTitle;
  final String? postTitle;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final s = services;
    return ShellPageFrame(
      services: s,
      title: l.boardTitle,
      navigation: BoardBar(
        services: s,
        crumbs: boardCrumbs(
          l,
          trail,
          taskTitle: taskTitle,
          postTitle: postTitle,
        ),
        showContribute: !trail.contribute,
      ),
      signedOutAction: ShadButton.outline(
        key: const ValueKey<String>('board.signIn'),
        size: ShadButtonSize.sm,
        onPressed: () => boardSignIn(s),
        child: Text(l.boardSignIn),
      ),
      child: child,
    );
  }
}

/// An inline text link (`small`, `primary`, underlined) that wraps like
/// text, keyboard operable with the focus ring; [external] adds the
/// external-link icon.
class BoardTextLink extends StatefulWidget {
  const BoardTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.external = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool external;

  @override
  State<BoardTextLink> createState() => _BoardTextLinkState();
}

class _BoardTextLinkState extends State<BoardTextLink> {
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      link: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _focus ? cs.ring : const Color(0x00000000),
              ),
            ),
            child: Text.rich(
              TextSpan(
                text: widget.label,
                children: [
                  if (widget.external)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 4),
                        child: Icon(
                          LucideIcons.externalLink,
                          size: 13,
                          color: cs.primary,
                        ),
                      ),
                    ),
                ],
              ),
              style: theme.textTheme.small.copyWith(
                color: cs.primary,
                decoration: TextDecoration.underline,
                decorationColor: cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of a board list (posts, tasks, review items), styled like the
/// drive list's rows and the notification rows: a rounded tile with the
/// accent on hover, `sidebarAccent` when [selected] and the focus ring.
/// Enter and Space activate [onTap].
class BoardListTile extends StatefulWidget {
  const BoardListTile({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  /// Names the row for screen readers; its controls stay reachable.
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  State<BoardListTile> createState() => _BoardListTileState();
}

class _BoardListTileState extends State<BoardListTile> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final onTap = widget.onTap;
    final tile = Container(
      padding: widget.padding,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: widget.selected
            ? cs.sidebarAccent
            : _hover && onTap != null
            ? cs.accent.withValues(alpha: 0.6)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _focus ? cs.ring : const Color(0x00000000),
          width: 1.5,
        ),
      ),
      child: widget.child,
    );
    return Semantics(
      container: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: onTap != null,
        mouseCursor: onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: tile,
        ),
      ),
    );
  }
}

/// The loading state of a board list: the drive list's skeleton rows
/// (`LoadingShimmer.driveList`), clipped, in the page's content column.
class BoardListLoading extends StatelessWidget {
  const BoardListLoading({super.key, this.rows = 8});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final inset = shellPageInset(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        math.max(0, inset - 16),
        8,
        math.max(0, inset - 16),
        0,
      ),
      // Clipped: the placeholder rows may be taller than a short window.
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: LoadingShimmer.driveList(rows: rows),
        ),
      ),
    );
  }
}

/// The vote control (specs/16 §4.4, §4.7): ▲ score ▼, the same for ideas
/// and bugs, with "Upvote, 14 votes" / "Remove upvote" labels and a pressed
/// state. Bugs can only be upvoted: their ▼ is greyed out and disabled,
/// with the tooltip *Bugs can only be upvoted* (screen readers hear that it
/// is unavailable). [onVote] gets the new value (−1, 0, 1); null disables
/// the buttons (voting closed).
class BoardVoteControl extends StatelessWidget {
  const BoardVoteControl({
    super.key,
    required this.number,
    required this.kind,
    required this.score,
    required this.voteCount,
    required this.myVote,
    required this.onVote,
    this.large = false,
  });

  final int number;
  final BoardPostKind kind;
  final int score;
  final int voteCount;
  final int myVote;
  final ValueChanged<int>? onVote;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final upOnly = kind == BoardPostKind.bug;
    Widget arrow(int value) {
      final up = value == 1;
      final unavailable = !up && upOnly;
      final enabled = onVote != null && !unavailable;
      final pressed = myVote == value;
      final label = unavailable
          ? l.boardDownvoteUnavailable
          : up
          ? (pressed ? l.boardRemoveUpvote : l.boardUpvoteLabel(score))
          : (pressed ? l.boardRemoveDownvote : l.boardDownvoteLabel(score));
      return Semantics(
        button: true,
        toggled: unavailable ? null : pressed,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        onTap: enabled ? () => onVote?.call(pressed ? 0 : value) : null,
        child: ShadTooltip(
          builder: (_) => Text(unavailable ? l.boardBugsUpvoteOnly : label),
          child: _HoverReport(
            active: unavailable,
            child: ShadIconButton.raw(
              key: ValueKey<String>('board.vote.$number.${up ? 'up' : 'down'}'),
              variant: pressed
                  ? ShadButtonVariant.secondary
                  : ShadButtonVariant.ghost,
              width: large ? 36 : 28,
              height: large ? 30 : 24,
              iconSize: large ? 20 : 16,
              enabled: enabled,
              icon: Icon(
                up ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                color: pressed
                    ? cs.primary
                    : unavailable
                    ? cs.mutedForeground.withValues(alpha: 0.5)
                    : null,
              ),
              onPressed: () => onVote?.call(pressed ? 0 : value),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(1),
        Text(
          '$score',
          key: ValueKey<String>('board.vote.$number.score'),
          style: (large ? theme.textTheme.large : theme.textTheme.small)
              .copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: myVote != 0 ? cs.primary : null,
              ),
        ),
        arrow(-1),
      ],
    );
  }
}

/// Reports the pointer's hover to the [ShadTooltip] around it when [active]:
/// a disabled shad button reports none, and its tooltip would never show.
class _HoverReport extends StatelessWidget {
  const _HoverReport({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final hover = ShadTheme.of(context).hoverStrategies.onHoverChange;
    return MouseRegion(
      onEnter: (_) => hover?.call(true),
      onExit: (_) => hover?.call(false),
      child: child,
    );
  }
}

/// A small label chip (area, size, kind): a secondary `ShadBadge` like the
/// comment cards' author badges; [ai] adds the *AI* marker while the label
/// is not confirmed by an admin.
class BoardChip extends StatelessWidget {
  const BoardChip({super.key, required this.label, this.ai = false, this.icon});

  final String label;
  final bool ai;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final fg = theme.colorScheme.secondaryForeground;
    return Semantics(
      label: ai ? l.boardAiLabel(label) : label,
      excludeSemantics: true,
      child: ShadBadge.secondary(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (icon != null) Icon(icon, size: 12, color: fg),
            Text(label, style: const TextStyle(fontSize: 11)),
            if (ai)
              Text(
                l.boardAiMarker,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A status badge: an outline `ShadBadge` with a dot in the design system's
/// status color and the status name (color is never the only signal,
/// specs/16 §4.7). With [onTap] it is a link (*Planned in T-12*).
class BoardStatusBadge extends StatelessWidget {
  const BoardStatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.onTap,
    this.color,
  });

  final Enum status;
  final String label;
  final VoidCallback? onTap;

  /// Overrides the status color (review verdicts).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = this.color ?? boardStatusColor(theme.colorScheme, status);
    return Semantics(
      link: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: ShadBadge.outline(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// An author line: avatar, name, an *Admin* badge (from the server's flag)
/// and the age — the comment cards' metadata style.
class BoardAuthorLine extends StatelessWidget {
  const BoardAuthorLine({
    super.key,
    required this.author,
    required this.createdAt,
    this.editedAt,
    this.avatar = true,
  });

  final BoardAuthor? author;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final a = author;
    final muted = theme.textTheme.muted.copyWith(fontSize: 12);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        if (avatar)
          WonkyAvatar(
            name: a?.displayName ?? '?',
            color: a == null
                ? theme.colorScheme.muted
                : parseHexColor(a.avatarColor),
            imageUrl: a?.avatarUrl,
            size: 20,
          ),
        Text(a?.displayName ?? l.boardDeletedUser, style: muted),
        if (a?.isAdmin == true)
          ShadBadge.secondary(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(l.boardAdmin, style: const TextStyle(fontSize: 11)),
          ),
        Text('· ${timeAgo(l, createdAt)}', style: muted),
        if (editedAt != null)
          Text('· ${l.boardEdited(timeAgo(l, editedAt!))}', style: muted),
      ],
    );
  }
}

/// A notice above a post or task (state, moderation, kind correction): a
/// `ShadAlert` like the app's other callouts (trashed file, offline
/// warnings), the icon in the status color [tone];
/// [ShadAlert.destructive] when [tone] is the destructive color.
class BoardNotice extends StatelessWidget {
  const BoardNotice({
    super.key,
    required this.icon,
    required this.text,
    this.tone,
    this.action,
  });

  final IconData icon;
  final String text;

  /// The icon's color (null: the foreground).
  final Color? tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final destructive = tone != null && tone == theme.colorScheme.destructive;
    return (destructive ? ShadAlert.destructive : ShadAlert.new)(
      icon: Icon(icon, size: 16),
      iconColor: destructive ? null : tone,
      titleStyle: theme.textTheme.small,
      crossAxisAlignment: action == null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      title: Text(text),
      trailing: action == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: action,
            ),
    );
  }
}

/// *Writing the prompt with AI… this takes about a minute* with a spinner:
/// the AI writes a task prompt in the background (specs/16 §10.1); the
/// page refreshes live when it is done.
class BoardPromptPendingNotice extends StatelessWidget {
  const BoardPromptPendingNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: ShadAlert(
        icon: const ExcludeSemantics(child: ShadSpinner(size: 16)),
        titleStyle: theme.textTheme.small,
        title: Text(l.boardPromptWriting),
      ),
    );
  }
}

/// The monospaced text of the board's code (setup commands, PR lines, the
/// prompt, the claim code): the design system's mono font at 12 px, like
/// the code snippets in Settings › Developer.
TextStyle boardCodeStyle(ShadThemeData theme) => TextStyle(
  fontFamily: WonkyTheme.monoFamily,
  fontSize: 12,
  height: 1.5,
  color: theme.colorScheme.foreground,
);

/// Copies [text] and confirms with the shell's toast.
Future<void> boardCopy(BuildContext context, String text) async {
  final l = WonkyAppLocalizations.of(context);
  final s = ShellScope.maybeOf(context);
  await Clipboard.setData(ClipboardData(text: text));
  s?.toasts.show(l.boardCopied);
}

/// A command line with a copy button (setup steps, PR lines): a code block
/// like the Markdown code blocks — `muted` fill, 6 px radius, the copy icon
/// at the top end.
class BoardCopyLine extends StatelessWidget {
  const BoardCopyLine({
    super.key,
    required this.text,
    required this.copyKey,
    this.label,
  });

  final String text;
  final String copyKey;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final copy = label ?? l.boardCopy;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 34, 8),
            child: Text(text, style: boardCodeStyle(theme)),
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: ShadTooltip(
              builder: (_) => Text(copy),
              child: ShadIconButton.ghost(
                key: ValueKey<String>(copyKey),
                width: 26,
                height: 26,
                iconSize: 13,
                semanticLabel: copy,
                icon: const Icon(LucideIcons.copy),
                onPressed: () => boardCopy(context, text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section heading on board pages (`h4`, like the drive's page titles).
class BoardSectionTitle extends StatelessWidget {
  const BoardSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: theme.textTheme.h4),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A disclosure header (*Details*, *How to build it*): a chevron and
/// [label] that toggle [open]; keyboard operable (Enter, Space) with the
/// focus ring, like the report dialog's *Details*.
class BoardDisclosure extends StatefulWidget {
  const BoardDisclosure({
    super.key,
    required this.tapKey,
    required this.open,
    required this.onToggle,
    required this.label,
    this.iconSize = 16,
  });

  /// The key of the tappable header.
  final String tapKey;
  final bool open;
  final VoidCallback onToggle;
  final Widget label;
  final double iconSize;

  @override
  State<BoardDisclosure> createState() => _BoardDisclosureState();
}

class _BoardDisclosureState extends State<BoardDisclosure> {
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      button: true,
      expanded: widget.open,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onToggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          key: ValueKey<String>(widget.tapKey),
          behavior: HitTestBehavior.opaque,
          onTap: widget.onToggle,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: _focus
                    ? theme.colorScheme.ring
                    : const Color(0x00000000),
              ),
              borderRadius: theme.radius,
            ),
            child: Row(
              spacing: 4,
              children: [
                Icon(
                  widget.open
                      ? LucideIcons.chevronDown
                      : LucideIcons.chevronRight,
                  size: widget.iconSize,
                ),
                Flexible(child: widget.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The post's labels: kind (optional), area and size with the AI marker.
List<Widget> boardLabelChips(
  WonkyAppLocalizations l, {
  BoardPostKind? kind,
  BoardArea? area,
  BoardSize? size,
  bool ai = false,
}) => [
  if (kind != null)
    BoardChip(
      label: l.boardKindName(kind),
      icon: kind == BoardPostKind.bug ? LucideIcons.bug : LucideIcons.leaf,
    ),
  if (area != null) BoardChip(label: l.boardAreaName(area), ai: ai),
  if (size != null) BoardChip(label: l.boardSizeName(size), ai: ai),
];

/// A post or task number (`#5`, `T-1`) and its title as one text: the
/// number grayed out, the title semibold (like the selected tab), on one
/// baseline, wrapping together
/// (board rows, the task header; specs/16 §4.4).
class BoardNumberedTitle extends StatelessWidget {
  const BoardNumberedTitle({
    super.key,
    required this.number,
    required this.title,
    this.style,
    this.maxLines = 2,
  });

  final String number;
  final String title;

  /// The base style (default: `small`); the title is bold, the number keeps
  /// the regular weight in the muted color.
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final base = style ?? theme.textTheme.small;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$number ',
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
              fontWeight: FontWeight.w400,
            ),
          ),
          // Semibold like the selected tab: Geist is a variable font, and a
          // heavier weight than the theme uses rendered wider.
          TextSpan(
            text: title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      style: base,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
