import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';

import '../../l10n/wonky_ui_localizations.dart';
import '../../theme/wonky_colors.dart';
import '../dialog/dialog_close_button.dart';

/// The sync states shown by [SyncStatusIndicator] (suite 02 §4.14).
enum SyncState { saved, saving, offline, error, connecting, reconnecting }

/// One entry of the sync log shown in the details dialog.
@immutable
class SyncLogEntry {
  const SyncLogEntry({
    required this.at,
    required this.message,
    this.isError = false,
  });

  final DateTime at;
  final String message;
  final bool isError;
}

/// Snapshot of a document's (or the shell's) sync status.
@immutable
class SyncStatus {
  const SyncStatus({
    required this.state,
    this.pendingChanges = 0,
    this.reconnectAt,
    this.error,
    this.log = const [],
    this.progress,
  });

  static const saved = SyncStatus(state: SyncState.saved);

  final SyncState state;
  final int pendingChanges;

  /// When the next reconnect attempt happens (for the countdown).
  final DateTime? reconnectAt;
  final String? error;
  final List<SyncLogEntry> log;

  /// Share (0..1) of a big save already stored, shown as *Saving… 42 %*;
  /// null for ordinary saves.
  final double? progress;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.state == state &&
      other.pendingChanges == pendingChanges &&
      other.reconnectAt == reconnectAt &&
      other.error == error &&
      other.log.length == log.length &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(
    state,
    pendingChanges,
    reconnectAt,
    error,
    log.length,
    progress,
  );
}

/// Icon + label: *Saved*, *Saving…*, *Offline — changes saved on this
/// device*, *Sync error*, *Reconnecting in N s…*. Clicking opens a details
/// dialog with retry and the event log. Announced as a live region.
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.onRetry,
    this.compact = false,
    this.now,
  });

  final SyncStatus status;
  final VoidCallback? onRetry;

  /// Icon only (label in tooltip), used in tight title rows.
  final bool compact;

  /// Clock for the countdown (tests).
  final DateTime Function()? now;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  Timer? _tick;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  void _syncTimer() {
    final needs =
        widget.status.state == SyncState.reconnecting &&
        widget.status.reconnectAt != null;
    if (needs && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!needs) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  (IconData, String, Color?) _visual(
    WonkyUiLocalizations l10n,
    ShadColorScheme c,
  ) {
    final s = widget.status;
    return switch (s.state) {
      SyncState.saved => (LucideIcons.cloudCheck, l10n.syncSaved, null),
      SyncState.saving => (
        LucideIcons.refreshCw,
        s.progress == null
            ? l10n.syncSaving
            : '${l10n.syncSaving} ${(s.progress!.clamp(0, 1) * 100).floor()} %',
        null,
      ),
      SyncState.offline => (LucideIcons.cloudOff, l10n.syncOffline, c.warning),
      SyncState.error => (
        LucideIcons.cloudAlert,
        l10n.syncError,
        c.destructive,
      ),
      SyncState.connecting => (LucideIcons.cloud, l10n.syncConnecting, null),
      SyncState.reconnecting => (
        LucideIcons.cloudOff,
        s.reconnectAt == null
            ? l10n.syncConnecting
            : l10n.syncReconnecting(
                s.reconnectAt!.difference(_now()).inSeconds.clamp(0, 3600),
              ),
        c.warning,
      ),
    };
  }

  Future<void> _showDetails(BuildContext context) {
    final l10n = WonkyUiLocalizations.of(context);
    return showShadDialog<void>(
      context: context,
      builder: (context) {
        final theme = ShadTheme.of(context);
        final (icon, label, color) = _visual(l10n, theme.colorScheme);
        final time = intl.DateFormat.Hms();
        return ShadDialog(
          closeIcon: const WonkyDialogCloseButton(),
          title: Text(l10n.syncDetailsTitle),
          actions: [
            if (widget.onRetry != null)
              ShadButton(
                key: const ValueKey<String>('sync.retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRetry!();
                },
                child: Text(l10n.syncRetry),
              ),
            ShadButton.outline(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label)),
                  ],
                ),
                if (widget.status.pendingChanges > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.syncPending(widget.status.pendingChanges),
                    style: theme.textTheme.muted,
                  ),
                ],
                if (widget.status.error != null) ...[
                  const SizedBox(height: 8),
                  ShadAlert.destructive(
                    icon: const Icon(LucideIcons.circleAlert),
                    description: Text(widget.status.error!),
                  ),
                ],
                const SizedBox(height: 12),
                Text(l10n.syncLog, style: theme.textTheme.small),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: widget.status.log.isEmpty
                      ? Text(l10n.syncNoEvents, style: theme.textTheme.muted)
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final e in widget.status.log.reversed)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      time.format(e.at.toLocal()),
                                      style: theme.textTheme.muted.copyWith(
                                        fontFamily: 'packages/shad/GeistMono',
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e.message,
                                        style: theme.textTheme.small.copyWith(
                                          fontWeight: FontWeight.normal,
                                          color: e.isError
                                              ? theme.colorScheme.destructive
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WonkyUiLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final (icon, label, color) = _visual(l10n, theme.colorScheme);
    // The row says just "Offline"; the tooltip and details explain it.
    final shortLabel = widget.status.state == SyncState.offline
        ? l10n.syncOfflineShort
        : label;
    final fg = color ?? theme.colorScheme.mutedForeground;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: fg),
        if (!widget.compact) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              shortLabel,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.muted.copyWith(fontSize: 12, color: fg),
            ),
          ),
        ],
      ],
    );
    // Merged so the button's tap target carries the label
    // (labeledTapTargetGuideline).
    return MergeSemantics(
      child: Semantics(
        liveRegion: true,
        label: label,
        button: true,
        child: ShadTooltip(
          builder: (_) => Text(label),
          child: ShadButton.ghost(
            key: const ValueKey<String>('sync.status'),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () => _showDetails(context),
            child: ExcludeSemantics(child: content),
          ),
        ),
      ),
    );
  }
}
