import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../data/api.dart';
import '../drive/drive_format.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/shell_services.dart';
import 'notifications_controller.dart';

/// Stable keys of the notifications popover (specs/15 §7).
abstract final class NotificationKeys {
  static const button = ValueKey<String>('shell.notifications');
  static const markAllRead = ValueKey<String>(
    'shell.notifications.markAllRead',
  );
  static const filterAll = ValueKey<String>('shell.notifications.filter.all');
  static const filterUnread = ValueKey<String>(
    'shell.notifications.filter.unread',
  );
  static const loadMore = ValueKey<String>('shell.notifications.loadMore');
  static const settings = ValueKey<String>('shell.notifications.settings');
  static ValueKey<String> item(int id) =>
      ValueKey<String>('shell.notifications.item.$id');
}

/// The in-app notifications popover (suite 07 §4): unread badge, All/Unread
/// filter, grouped list (Today / Yesterday / Earlier) with comment excerpts,
/// paging, mark-all-read and a link to the notification settings; live via
/// `notification.watch`.
class NotificationsButton extends StatefulWidget {
  const NotificationsButton({super.key, required this.services});

  final ShellServices services;

  @override
  State<NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<NotificationsButton> {
  final _popover = ShadPopoverController();
  late final NotificationsController _ctl = NotificationsController(
    s.repositories.notifications,
  );

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    unawaited(_ctl.load());
    s.supervisor.supervise<NotificationEvent>(
      'notifications',
      s.repositories.notifications.watch,
      (e) {
        if (mounted) _ctl.onEvent(e);
      },
    );
  }

  @override
  void dispose() {
    unawaited(s.supervisor.cancel('notifications'));
    _popover.dispose();
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _open(NotificationView n) async {
    _popover.hide();
    unawaited(_ctl.markRead(n));
    // Bugs & improvements (specs/16 §12): posts and tasks on the board.
    final board = _boardPathOf(n);
    if (board != null) {
      await s.openPath(board);
      return;
    }
    final uuid = n.itemUuid;
    if (uuid == null) return;
    final thread = _threadOf(n);
    final path = switch (n.itemKind) {
      // Spreadsheets open the comment's cell (Sheets 10 §3.4).
      DriveItemKind.spreadsheet =>
        '/s/${uuid.uuid}${thread == null ? '' : '?comment=$thread'}',
      // (v2) Decks open the comment's slide and element (Slides 09 §3.4).
      DriveItemKind.presentation =>
        '/p/${uuid.uuid}${thread == null ? '' : '?comment=$thread'}',
      DriveItemKind.folder => '/f/${uuid.uuid}',
      _ => '/d/${uuid.uuid}',
    };
    await s.openPath(path);
  }

  static String? _boardPathOf(NotificationView n) {
    final p = _payload(n);
    if (p['taskNumber'] is int) return '/improvements/t/${p['taskNumber']}';
    if (p['postNumber'] is int) return '/improvements/p/${p['postNumber']}';
    return null;
  }

  static String? _threadOf(NotificationView n) {
    try {
      final p = jsonDecode(n.payload);
      return p is Map && p['threadUuid'] is String
          ? p['threadUuid'] as String
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _openSettings() async {
    _popover.hide();
    await s.openPath('/settings/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return ShadPopover(
      controller: _popover,
      anchor: const ShadAnchor(
        childAlignment: AlignmentDirectional.bottomEnd,
        overlayAlignment: AlignmentDirectional.topEnd,
        offset: Offset(0, 6),
      ),
      popover: (context) => NotificationsPanel(
        controller: _ctl,
        onOpen: _open,
        onOpenSettings: _openSettings,
      ),
      child: ListenableBuilder(
        listenable: _ctl,
        builder: (context, _) => _BellButton(
          unread: _ctl.unreadCount,
          tooltip: l.notificationsTitle,
          semanticLabel: _ctl.unreadCount > 0
              ? l.notificationsUnread(_ctl.unreadCount)
              : l.notificationsTitle,
          onPressed: () {
            _popover.toggle();
            if (_popover.isOpen) unawaited(_ctl.load());
          },
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({
    required this.unread,
    required this.tooltip,
    required this.semanticLabel,
    required this.onPressed,
  });

  final int unread;
  final String tooltip;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadTooltip(
      builder: (_) => Text(tooltip),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ShadIconButton.ghost(
            key: NotificationKeys.button,
            semanticLabel: semanticLabel,
            icon: const Icon(LucideIcons.bell, size: 18),
            onPressed: onPressed,
          ),
          if (unread > 0)
            Positioned(
              right: 4,
              top: 4,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.destructive,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: theme.colorScheme.destructiveForeground,
                          fontSize: 10,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The popover content (public for widget tests).
class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({
    super.key,
    required this.controller,
    required this.onOpen,
    required this.onOpenSettings,
    this.now,
  });

  final NotificationsController controller;
  final ValueChanged<NotificationView> onOpen;
  final VoidCallback onOpenSettings;

  /// The time used for grouping (tests); defaults to the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return SizedBox(
      width: 380,
      height: 460,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = controller;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l.notificationsTitle,
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  ShadButton.link(
                    key: NotificationKeys.markAllRead,
                    size: ShadButtonSize.sm,
                    enabled: c.unreadCount > 0,
                    onPressed: c.markAllRead,
                    child: Text(l.notificationsMarkAllRead),
                  ),
                ],
              ),
              Row(
                children: [
                  _FilterButton(
                    key: NotificationKeys.filterAll,
                    label: l.notificationsFilterAll,
                    selected: !c.unreadOnly,
                    onPressed: () => c.setUnreadOnly(false),
                  ),
                  const SizedBox(width: 4),
                  _FilterButton(
                    key: NotificationKeys.filterUnread,
                    label: c.unreadCount > 0
                        ? l.notificationsFilterUnreadCount(c.unreadCount)
                        : l.notificationsFilterUnread,
                    selected: c.unreadOnly,
                    onPressed: () => c.setUnreadOnly(true),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const ShadSeparator.horizontal(margin: EdgeInsets.zero),
              Expanded(child: _body(context, l, theme)),
              const ShadSeparator.horizontal(margin: EdgeInsets.zero),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ShadButton.ghost(
                  key: NotificationKeys.settings,
                  size: ShadButtonSize.sm,
                  leading: const Icon(LucideIcons.settings, size: 14),
                  onPressed: onOpenSettings,
                  child: Text(l.notificationsSettings),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WonkyAppLocalizations l,
    ShadThemeData theme,
  ) {
    final c = controller;
    if (c.loading && c.items.isEmpty) {
      return const Center(child: ShadSpinner());
    }
    if (c.error != null && c.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.notificationsLoadFailed, style: theme.textTheme.muted),
            const SizedBox(height: 4),
            Text(
              errorMessage(c.error!),
              style: theme.textTheme.muted.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: c.load,
              child: Text(l.actionRetry),
            ),
          ],
        ),
      );
    }
    if (c.items.isEmpty) {
      return WonkyEmptyState(
        illustration: EmptyIllustration.notifications,
        title: c.unreadOnly ? l.notificationsEmptyUnread : l.notificationsEmpty,
        size: 72,
      );
    }
    final at = now ?? clock.now();
    final rows = <Widget>[];
    RecentGroup? group;
    for (final n in c.items) {
      final g = recentGroupOf(n.createdAt, now: at);
      final label = g == RecentGroup.thisWeek ? RecentGroup.earlier : g;
      if (label != group) {
        group = label;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Semantics(
              header: true,
              child: Text(
                recentGroupLabel(l, label),
                style: theme.textTheme.muted.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }
      rows.add(
        NotificationTile(
          key: NotificationKeys.item(n.id),
          notification: n,
          now: at,
          onPressed: () => onOpen(n),
        ),
      );
    }
    if (c.hasMore) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: c.loadingMore
                ? const ShadSpinner(size: 16)
                : ShadButton.ghost(
                    key: NotificationKeys.loadMore,
                    size: ShadButtonSize.sm,
                    onPressed: c.loadMore,
                    child: Text(l.notificationsLoadMore),
                  ),
          ),
        ),
      );
    }
    return ListView(children: rows);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: selected
        ? ShadButton.secondary(
            size: ShadButtonSize.sm,
            onPressed: onPressed,
            child: Text(label),
          )
        : ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: onPressed,
            child: Text(label),
          ),
  );
}

/// The text of a notification ("Anna mentioned you in “Plan”").
String notificationText(WonkyAppLocalizations l, NotificationView n) {
  final who = n.actor?.displayName ?? l.someone;
  final what = n.itemName ?? '';
  return switch (n.kind) {
    NotificationKind.mention => l.notifMention(who, what),
    NotificationKind.reply => l.notifReply(who, what),
    NotificationKind.assigned => l.notifAssigned(who, what),
    NotificationKind.shared => l.notifShared(who, what),
    NotificationKind.accessRequest => l.notifAccessRequest(who, what),
    NotificationKind.suggestion => l.notifSuggestion(who, what),
    NotificationKind.suggestionDecided => switch (_payload(n)['decision']) {
      'accepted' => l.notifSuggestionAccepted(who, what),
      'rejected' => l.notifSuggestionRejected(who, what),
      _ => l.notifSuggestionDecided(who, what),
    },
    NotificationKind.ownershipTransfer => l.notifOwnership(who, what),
    NotificationKind.scriptFailure => l.notifScriptFailure(what),
    NotificationKind.storage => switch (_payload(n)['message']) {
      final String m when m.isNotEmpty => m,
      _ => l.notifStorage,
    },
    NotificationKind.boardReply => l.notifBoardReply(
      who,
      '${_payload(n)['title'] ?? ''}',
    ),
    NotificationKind.boardStatus ||
    NotificationKind.boardClaim => switch (_payload(n)['line']) {
      final String m when m.isNotEmpty => m,
      _ => l.notifBoardUpdate('${_payload(n)['title'] ?? ''}'),
    },
    NotificationKind.submission => _submissionText(l, n, what),
  };
}

/// (M14) A publication's update on a story (specs/18 §5.3).
String _submissionText(
  WonkyAppLocalizations l,
  NotificationView n,
  String what,
) {
  final p = _payload(n);
  final pub = '${p['publication'] ?? l.someone}';
  return switch ((p['event'], p['status'])) {
    ('deliveryFailed', _) => l.notifSubmissionFailed(pub, what),
    ('status', 'changesRequested') => l.notifSubmissionChanges(pub, what),
    ('status', 'declined') => l.notifSubmissionDeclined(pub, what),
    ('status', 'published') => l.notifSubmissionPublished(pub, what),
    ('status', 'inReview') => l.notifSubmissionInReview(pub, what),
    _ => l.notifSubmissionMessage(pub, what),
  };
}

/// The quoted context of a notification: comment excerpt or share message.
String? notificationExcerpt(NotificationView n) {
  final p = _payload(n);
  final e = p['excerpt'] ?? p['message'];
  if (e is! String) return null;
  final flat = e.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.isEmpty ? null : flat;
}

Map<String, Object?> _payload(NotificationView n) {
  try {
    final v = jsonDecode(n.payload);
    return v is Map ? v.cast<String, Object?>() : const {};
  } on FormatException {
    return const {};
  }
}

IconData _kindIcon(NotificationKind k) => switch (k) {
  NotificationKind.mention => LucideIcons.atSign,
  NotificationKind.reply => LucideIcons.messageSquareReply,
  NotificationKind.assigned => LucideIcons.userCheck,
  NotificationKind.shared => LucideIcons.share2,
  NotificationKind.accessRequest => LucideIcons.keyRound,
  NotificationKind.suggestion => LucideIcons.pencilLine,
  NotificationKind.suggestionDecided => LucideIcons.checkCheck,
  NotificationKind.ownershipTransfer => LucideIcons.crown,
  NotificationKind.scriptFailure => LucideIcons.triangleAlert,
  NotificationKind.storage => LucideIcons.hardDrive,
  NotificationKind.boardReply => LucideIcons.messageSquareReply,
  NotificationKind.boardStatus => LucideIcons.bug,
  NotificationKind.boardClaim => LucideIcons.hand,
  NotificationKind.submission => LucideIcons.newspaper,
};

/// One notification row: avatar with the kind icon, text, excerpt, time and
/// an unread dot. Focusable and activated with Enter/Space.
class NotificationTile extends StatefulWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onPressed,
    this.now,
  });

  final NotificationView notification;
  final VoidCallback onPressed;
  final DateTime? now;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final n = widget.notification;
    final unread = n.readAt == null;
    final text = notificationText(l, n);
    final excerpt = notificationExcerpt(n);
    final time = timeAgo(l, n.createdAt, now: widget.now);
    final highlight = _hover || _focus;
    return Semantics(
      button: true,
      label: [
        text,
        ?excerpt,
        time,
        if (unread) l.notificationsUnreadMarker,
      ].join(', '),
      excludeSemantics: true,
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
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: highlight
                  ? theme.colorScheme.accent
                  : unread
                  ? theme.colorScheme.muted.withValues(alpha: 0.5)
                  : null,
              border: _focus
                  ? Border.all(color: theme.colorScheme.ring, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      WonkyAvatar(
                        name: n.actor?.displayName ?? '?',
                        color: n.actor == null
                            ? theme.colorScheme.muted
                            : parseHexColor(n.actor!.avatarColor),
                        imageUrl: n.actor?.avatarUrl,
                        size: 28,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _kindIcon(n.kind),
                            size: 11,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: theme.textTheme.small.copyWith(
                          fontWeight: unread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (excerpt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '“$excerpt”',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          time,
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
