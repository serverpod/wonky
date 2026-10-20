import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../data/api.dart';
import '../drive/drive_format.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/dialogs.dart' show activityDetail, activityText;
import '../shell/shell_services.dart';

/// Stable keys of the activity feed (specs/15 §7).
abstract final class ActivityFeedKeys {
  static const loadMore = ValueKey<String>('activity.feed.loadMore');
  static ValueKey<String> event(int id) =>
      ValueKey<String>('activity.feed.event.$id');
}

/// The activity feed of a drive item (details panel and the dashboard's
/// Activity tab): who did what, newest first, with "Show more" paging. It
/// reloads when the item changes in the drive (rename, share, move, …).
class ActivityFeed extends StatefulWidget {
  const ActivityFeed({
    super.key,
    required this.services,
    required this.itemUuid,
    this.pageSize = 20,
  });

  final ShellServices services;
  final UuidValue itemUuid;
  final int pageSize;

  @override
  State<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  List<ActivityEventView> _events = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;
  int _generation = 0;
  StreamSubscription<DriveChange>? _changes;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _changes = widget.services.driveChanges.listen((c) {
      if (c.itemUuid == widget.itemUuid) unawaited(_load());
    });
  }

  @override
  void didUpdateWidget(ActivityFeed old) {
    super.didUpdateWidget(old);
    if (old.itemUuid != widget.itemUuid) unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  Future<void> _load() async {
    final gen = ++_generation;
    setState(() {
      _loading = _events.isEmpty;
      _error = null;
    });
    try {
      final events = await widget.services.drive.activity(
        widget.itemUuid,
        limit: widget.pageSize,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _events = events;
        _hasMore = events.length >= widget.pageSize;
      });
    } catch (e) {
      if (mounted && gen == _generation) setState(() => _error = e);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _events.isEmpty) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final more = await widget.services.drive.activity(
        widget.itemUuid,
        beforeId: _events.last.id,
        limit: widget.pageSize,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _events = [..._events, ...more];
        _hasMore = more.length >= widget.pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: ShadSpinner()),
      );
    }
    if (_error != null && _events.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(errorMessage(_error!), style: theme.textTheme.muted),
          ),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: _load,
            child: Text(l.actionRetry),
          ),
        ],
      );
    }
    if (_events.isEmpty) {
      return Text(l.activityEmpty, style: theme.textTheme.muted);
    }
    final full = intl.DateFormat.yMMMd().add_jm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in _events)
          Padding(
            key: ActivityFeedKeys.event(e.id),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EventAvatar(event: e),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityText(l, e),
                          style: theme.textTheme.small.copyWith(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        if (activityDetail(l, e) case final detail?)
                          Text(
                            detail,
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                          ),
                        ShadTooltip(
                          builder: (_) => Text(full.format(e.at.toLocal())),
                          child: Text(
                            timeAgo(l, e.at),
                            style: theme.textTheme.muted.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_hasMore)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: ShadSpinner(size: 16),
                  )
                : ShadButton.ghost(
                    key: ActivityFeedKeys.loadMore,
                    size: ShadButtonSize.sm,
                    onPressed: _loadMore,
                    child: Text(l.activityShowMore),
                  ),
          ),
      ],
    );
  }
}

IconData activityIcon(ActivityType t) => switch (t) {
  ActivityType.created => LucideIcons.filePlus,
  ActivityType.renamed => LucideIcons.textCursorInput,
  ActivityType.moved => LucideIcons.folderInput,
  ActivityType.edited => LucideIcons.pencil,
  ActivityType.commented => LucideIcons.messageSquare,
  ActivityType.shared => LucideIcons.userPlus,
  ActivityType.unshared => LucideIcons.userMinus,
  ActivityType.restoredVersion => LucideIcons.history,
  ActivityType.trashed => LucideIcons.trash2,
  ActivityType.restored => LucideIcons.archiveRestore,
  ActivityType.exported => LucideIcons.download,
  ActivityType.uploaded => LucideIcons.upload,
  ActivityType.submission => LucideIcons.send,
};

class _EventAvatar extends StatelessWidget {
  const _EventAvatar({required this.event});

  final ActivityEventView event;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final actor = event.actor;
    return ExcludeSemantics(
      child: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (actor != null)
              WonkyAvatar(
                name: actor.displayName,
                color: parseHexColor(actor.avatarColor),
                imageUrl: actor.avatarUrl,
                size: 24,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.bot,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
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
                  activityIcon(event.type),
                  size: 10,
                  color: theme.colorScheme.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
