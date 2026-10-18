import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/files.dart' show FileTypes, formatStorageBytes;
import 'package:wonky_core/wonky_core.dart' show InvocationSource;

import '../../l10n/drive_l10n.dart';
import '../preview/file_category_icon.dart';
import 'upload_host.dart';
import 'upload_queue.dart';
import 'upload_task.dart';

/// Stable keys of the upload panel (widget tests, flutter_driver, MCP).
abstract final class UploadPanelKeys {
  static const panel = ValueKey<String>('drive.uploadPanel');
  static const pill = ValueKey<String>('drive.uploadPanel.pill');
  static const collapse = ValueKey<String>('drive.uploadPanel.collapse');
  static const close = ValueKey<String>('drive.uploadPanel.close');
  static const title = ValueKey<String>('drive.uploadPanel.title');
  static const retryAll = ValueKey<String>('drive.uploadPanel.retryAll');
  static const clearFinished = ValueKey<String>(
    'drive.uploadPanel.clearFinished',
  );

  static ValueKey<String> row(String id) =>
      ValueKey<String>('drive.uploadPanel.row.$id');
  static ValueKey<String> action(String id, String action) =>
      ValueKey<String>('drive.uploadPanel.row.$id.$action');
}

/// Places the [UploadPanel] over the app (bottom-right; the width minus
/// 16 px below 768 px) while it is visible (Drive 04 §4).
class UploadPanelLayer extends StatelessWidget {
  const UploadPanelLayer({
    super.key,
    required this.services,
    required this.child,
  });

  final ShellServices services;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final host = UploadHost.of(services);
    return Stack(
      children: [
        Positioned.fill(child: child),
        ValueListenableBuilder<UploadQueue?>(
          valueListenable: host.queue,
          builder: (context, queue, _) => queue == null
              ? const SizedBox.shrink()
              : ValueListenableBuilder<bool>(
                  valueListenable: host.panelVisible,
                  builder: (context, visible, _) {
                    if (!visible) return const SizedBox.shrink();
                    final size = MediaQuery.sizeOf(context);
                    final narrow = size.width < 768;
                    return Positioned(
                      right: narrow ? 8 : 16,
                      left: narrow ? 8 : null,
                      bottom: narrow ? 8 : 16,
                      child: UploadPanel(services: services, queue: queue),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// The upload panel (Drive 04 §4): header with the batch status, collapse
/// and close; one row per file with its status and action; a footer with
/// *Retry all* and *Clear finished*. Collapsed it is a pill.
class UploadPanel extends StatelessWidget {
  const UploadPanel({super.key, required this.services, required this.queue});

  final ShellServices services;
  final UploadQueue queue;

  static const width = 360.0;

  @override
  Widget build(BuildContext context) {
    final host = UploadHost.of(services);
    return ListenableBuilder(
      listenable: Listenable.merge([queue, host.panelCollapsed]),
      builder: (context, _) {
        final collapsed = host.panelCollapsed.value;
        final media = MediaQuery.sizeOf(context);
        final narrow = media.width < 768;
        final panel = collapsed
            ? _Pill(services: services, queue: queue)
            : _Card(
                services: services,
                queue: queue,
                maxHeight: math.max(160, media.height * 0.5),
              );
        return Align(
          alignment: AlignmentDirectional.bottomEnd,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(width: narrow ? null : width, child: panel),
        );
      },
    );
  }
}

/// The header line ("Uploading 3 items · 2 min left").
String uploadPanelTitle(DriveLocalizations l, UploadQueue q) {
  final active = q.activeCount;
  if (active > 0) {
    final waiting = q.tasks
        .where((t) => t.status == UploadStatus.waitingForNetwork)
        .length;
    if (waiting == active) return l.uploadPanelWaiting(active);
    final left = q.timeLeft;
    final base = l.uploadPanelUploading(active);
    if (left == null) return base;
    final time = left.inSeconds < 60
        ? l.uploadSecondsLeft(math.max(1, left.inSeconds))
        : l.uploadMinutesLeft((left.inSeconds / 60).ceil());
    return '$base · $time';
  }
  final failed = q.failedCount;
  if (failed > 0) return l.uploadPanelFailed(failed);
  return l.uploadPanelComplete(q.doneCount);
}

class _Card extends StatelessWidget {
  const _Card({
    required this.services,
    required this.queue,
    required this.maxHeight,
  });

  final ShellServices services;
  final UploadQueue queue;
  final double maxHeight;

  /// Runs a command for a panel button; dialogs open from [context] (the
  /// panel sits above the navigator in the app, so the dispatcher falls
  /// back to the navigator's context).
  Future<void> _run(
    BuildContext context,
    String id, [
    Map<String, Object?> args = const {},
  ]) => services.dispatcher
      .invoke(id, args: args, source: InvocationSource.ui, context: context)
      .then(
        (_) {},
        onError: (Object e) {
          services.toasts.error(errorMessage(e));
        },
      );

  Future<void> _close(
    Future<void> Function(String id, [Map<String, Object?> args]) invoke,
  ) async {
    final host = UploadHost.of(services);
    if (queue.hasActive) {
      await invoke('drive.upload.cancelAll');
      if (queue.hasActive) return;
    }
    host.panelVisible.value = false;
    await queue.clearFinished();
  }

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final host = UploadHost.of(services);
    final tasks = queue.tasks;
    Future<void> invoke(String id, [Map<String, Object?> args = const {}]) =>
        _run(context, id, args);
    final finished = tasks.any((t) => t.status.isFinished);
    final retryable = tasks.any(
      (t) => t.status == UploadStatus.failed && (t.failure?.retryable ?? true),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.uploadPanelLabel,
      child: Container(
        key: UploadPanelKeys.panel,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: c.popover,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: FocusTraversalGroup(
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
              SingleActivator(LogicalKeyboardKey.arrowUp):
                  PreviousFocusIntent(),
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            uploadPanelTitle(l, queue),
                            key: UploadPanelKeys.title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      ShadIconButton.ghost(
                        key: UploadPanelKeys.collapse,
                        width: 32,
                        height: 32,
                        iconSize: 16,
                        semanticLabel: l.uploadPanelCollapse,
                        icon: const Icon(LucideIcons.chevronDown),
                        onPressed: () => host.panelCollapsed.value = true,
                      ),
                      ShadIconButton.ghost(
                        key: UploadPanelKeys.close,
                        width: 32,
                        height: 32,
                        iconSize: 16,
                        semanticLabel: l.uploadPanelClose,
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => _close(invoke),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: c.border),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) => _Row(
                      key: UploadPanelKeys.row(tasks[i].id),
                      task: tasks[i],
                      services: services,
                      invoke: invoke,
                    ),
                  ),
                ),
                if (finished) ...[
                  Container(height: 1, color: c.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        if (retryable)
                          ShadButton.ghost(
                            key: UploadPanelKeys.retryAll,
                            size: ShadButtonSize.sm,
                            onPressed: () => invoke('drive.upload.retryAll'),
                            child: Text(l.uploadRetryAll),
                          ),
                        ShadButton.ghost(
                          key: UploadPanelKeys.clearFinished,
                          size: ShadButtonSize.sm,
                          onPressed: () => invoke('drive.upload.clearFinished'),
                          child: Text(l.uploadClearFinished),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.services, required this.queue});

  final ShellServices services;
  final UploadQueue queue;

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final active = queue.activeCount;
    // All waiting (offline): "2 waiting" with the cloud-off icon, not
    // "Uploading 2 · 0 %" (D-18).
    final waiting =
        active > 0 &&
        queue.tasks.every(
          (t) =>
              !t.status.isActive || t.status == UploadStatus.waitingForNetwork,
        );
    final label = waiting
        ? l.uploadPillWaiting(active)
        : active > 0
        ? l.uploadPill(active, (queue.batchProgress * 100).floor())
        : uploadPanelTitle(l, queue);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      widthFactor: 1,
      child: Semantics(
        liveRegion: true,
        button: true,
        label: label,
        child: ShadButton.outline(
          key: UploadPanelKeys.pill,
          size: ShadButtonSize.sm,
          backgroundColor: c.popover,
          leading: waiting
              ? Icon(LucideIcons.cloudOff, size: 16, color: c.mutedForeground)
              : active > 0
              ? ProgressRing(value: queue.batchProgress, size: 16)
              : Icon(
                  queue.failedCount > 0
                      ? LucideIcons.triangleAlert
                      : LucideIcons.circleCheck,
                  size: 16,
                  color: queue.failedCount > 0 ? c.destructive : c.primary,
                ),
          trailing: const Icon(LucideIcons.chevronUp, size: 16),
          onPressed: () => UploadHost.of(services).panelCollapsed.value = false,
          child: ExcludeSemantics(child: Text(label)),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.task,
    required this.services,
    required this.invoke,
  });

  final UploadTask task;
  final ShellServices services;
  final Future<void> Function(String id, [Map<String, Object?> args]) invoke;

  String _status(DriveLocalizations l) {
    final t = task;
    return switch (t.status) {
      UploadStatus.queued => l.uploadStatusQueued,
      UploadStatus.waitingForNetwork => l.uploadStatusWaiting,
      UploadStatus.starting => l.uploadStatusStarting,
      UploadStatus.uploading => l.uploadStatusPercent(
        (t.progress * 100).floor(),
      ),
      UploadStatus.verifying => l.uploadStatusVerifying,
      UploadStatus.done =>
        t.converted
            ? l.uploadStatusConverted(t.result!.kind.name)
            : l.uploadStatusDone,
      UploadStatus.cancelled => l.uploadStatusCancelled,
      UploadStatus.failed => switch (t.failure) {
        UploadFailure.outOfStorage => l.uploadFailedOutOfStorage,
        UploadFailure.network => l.uploadFailedNetwork,
        UploadFailure.tooLarge => l.uploadFailedTooLarge(
          formatStorageBytes(
            services.serverInfo.value?.limits.maxFileUploadBytes ??
                50 * 1024 * 1024,
          ),
        ),
        UploadFailure.folderGone => l.uploadFailedFolderGone,
        UploadFailure.rateLimited => l.uploadFailedRateLimited,
        UploadFailure.notSaved => l.uploadFailedNotSaved,
        UploadFailure.other || null => l.uploadFailedOther,
      },
    };
  }

  void _showInFolder() {
    final item = task.result;
    if (item == null) return;
    services.driveSelection.value = [item];
    final parent = item.parentUuid;
    services.router.go(parent == null ? '/my-drive' : '/f/${parent.uuid}');
  }

  void _open() {
    final item = task.result;
    if (item == null) return;
    if (task.converted) {
      // A converted upload opens in its app (Drive 02 §7.3).
      unawaited(services.openItem(item));
      return;
    }
    unawaited(invoke('drive.file.preview', {'uuid': item.uuid.uuid}));
  }

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final t = task;
    final failed = t.status == UploadStatus.failed;
    final dim =
        t.status == UploadStatus.waitingForNetwork ||
        t.status == UploadStatus.cancelled;
    final status = _status(l);
    final ext = FileTypes.extensionOf(t.fileName);
    final base = ext.isEmpty
        ? t.fileName
        : t.fileName.substring(0, t.fileName.length - ext.length - 1);
    final actions = _actions(l, c);
    // Text actions go under the status (room at 360 px), icons at the end.
    final links = actions.whereType<_Link>().toList();
    final icons = [
      for (final a in actions)
        if (a is! _Link) a,
    ];
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Opacity(
            opacity: dim ? 0.55 : 1,
            child: FileCategoryIcon(t.category, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: dim ? 0.7 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Middle ellipsis: the extension stays visible (when
                  // there is room for it).
                  LayoutBuilder(
                    builder: (context, box) => ext.isEmpty || box.maxWidth < 96
                        ? Text(
                            t.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.small,
                          )
                        : Row(
                            children: [
                              Flexible(
                                child: Text(
                                  base,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.small,
                                ),
                              ),
                              Text('.$ext', style: theme.textTheme.small),
                            ],
                          ),
                  ),
                  Row(
                    children: [
                      if (t.status == UploadStatus.waitingForNetwork) ...[
                        Icon(
                          LucideIcons.cloudOff,
                          size: 12,
                          color: c.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (failed) ...[
                        Icon(
                          LucideIcons.triangleAlert,
                          size: 12,
                          color: c.destructive,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          t.volatile && t.status.isActive
                              ? '$status · ${l.uploadVolatileHint}'
                              : status,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted.copyWith(
                            fontSize: 12,
                            color: failed ? c.destructive : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (links.isNotEmpty) Wrap(spacing: 12, children: links),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (t.status.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ProgressRing(value: t.progress, size: 20),
            ),
          if (t.status == UploadStatus.done)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(LucideIcons.circleCheck, size: 18, color: c.primary),
            ),
          ...icons,
        ],
      ),
    );
    return Semantics(
      label: '${t.fileName}, $status',
      child: t.status == UploadStatus.done
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _open,
              child: MouseRegion(cursor: SystemMouseCursors.click, child: row),
            )
          : row,
    );
  }

  List<Widget> _actions(DriveLocalizations l, ShadColorScheme c) {
    final t = task;
    Widget icon(String action, IconData glyph, String label, VoidCallback f) =>
        ShadIconButton.ghost(
          key: UploadPanelKeys.action(t.id, action),
          width: 32,
          height: 32,
          iconSize: 16,
          semanticLabel: label,
          icon: Icon(glyph),
          onPressed: f,
        );
    Widget text(String action, String label, VoidCallback f) => _Link(
      key: UploadPanelKeys.action(t.id, action),
      label: label,
      onTap: f,
    );
    final id = {'uploadId': t.id};
    if (t.status.isActive) {
      return [
        icon(
          'cancel',
          LucideIcons.x,
          l.uploadActionCancel(t.fileName),
          () => invoke('drive.upload.cancel', id),
        ),
      ];
    }
    if (t.status == UploadStatus.done) {
      return [
        icon(
          'showInFolder',
          LucideIcons.folderOpen,
          l.uploadActionShowInFolder(t.fileName),
          _showInFolder,
        ),
      ];
    }
    if (t.status == UploadStatus.cancelled) return const [];
    return switch (t.failure) {
      UploadFailure.outOfStorage => [
        text(
          'manageStorage',
          l.uploadManageStorage,
          () => invoke('shell.storage.open'),
        ),
        icon(
          'retry',
          LucideIcons.rotateCw,
          l.uploadActionRetry(t.fileName),
          () => invoke('drive.upload.retry', id),
        ),
      ],
      UploadFailure.folderGone => [
        text(
          'toMyDrive',
          l.uploadActionToMyDrive,
          () => invoke('drive.upload.retry', {...id, 'toMyDrive': true}),
        ),
        icon(
          'remove',
          LucideIcons.x,
          l.uploadActionRemove(t.fileName),
          () => invoke('drive.upload.remove', id),
        ),
      ],
      UploadFailure.notSaved => [
        text('chooseFile', l.uploadActionChooseFile, () async {
          await invoke('drive.upload.remove', id);
          await invoke('shell.drive.upload');
        }),
        icon(
          'remove',
          LucideIcons.x,
          l.uploadActionRemove(t.fileName),
          () => invoke('drive.upload.remove', id),
        ),
      ],
      UploadFailure.tooLarge => [
        icon(
          'remove',
          LucideIcons.x,
          l.uploadActionRemove(t.fileName),
          () => invoke('drive.upload.remove', id),
        ),
      ],
      _ => [
        icon(
          'retry',
          LucideIcons.rotateCw,
          l.uploadActionRetry(t.fileName),
          () => invoke('drive.upload.retry', id),
        ),
      ],
    };
  }
}

/// A text action of a row ("Manage storage", "Upload to My Drive").
class _Link extends StatelessWidget {
  const _Link({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ShadButton.link(
    size: ShadButtonSize.sm,
    height: 24,
    padding: EdgeInsets.zero,
    onPressed: onTap,
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}

/// A determinate progress ring (row status and the collapsed pill).
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 20});

  /// 0…1.
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = ShadTheme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0, 1),
          track: c.muted,
          color: c.primary,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.color});

  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(2.0, size.width / 8);
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        p..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.color != color;
}
