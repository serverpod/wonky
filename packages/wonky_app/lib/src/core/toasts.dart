import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// Shows toasts through `ShadSonner` (stacked, bottom-right).
class Toasts {
  Toasts(this._context);

  final BuildContext? Function() _context;
  int _next = 1;

  int show(
    String title, {
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    bool destructive = false,
    Duration? duration,
  }) {
    final ctx = _context();
    final id = _next++;
    if (ctx == null || !ctx.mounted) return id;
    final sonner = ShadSonner.maybeOf(ctx);
    if (sonner == null) return id;
    final action = actionLabel == null
        ? null
        : ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () {
              sonner.hide(id);
              onAction?.call();
            },
            child: Text(actionLabel),
          );
    sonner.show(
      destructive
          ? ShadToast.destructive(
              id: id,
              title: Text(title),
              description: description == null ? null : Text(description),
              action: action,
              displayDuration: duration,
            )
          : ShadToast(
              id: id,
              title: Text(title),
              description: description == null ? null : Text(description),
              action: action,
              displayDuration: duration,
            ),
    );
    return id;
  }

  /// A progress toast for a long job (Sheets 07 §1.4): [title], a bar with
  /// the percentage of [progress] (null = indeterminate) and, while
  /// [onCancel] is set, a [cancelLabel] button. Stays until [hide].
  int showProgress(
    String title, {
    required ValueListenable<double?> progress,
    String? cancelLabel,
    VoidCallback? onCancel,
    ValueListenable<bool>? cancellable,
    Duration duration = const Duration(minutes: 30),
  }) {
    final ctx = _context();
    final id = _next++;
    if (ctx == null || !ctx.mounted) return id;
    final sonner = ShadSonner.maybeOf(ctx);
    if (sonner == null) return id;
    final can = cancellable ?? ValueNotifier(true);
    sonner.show(
      ShadToast(
        id: id,
        title: Text(title),
        description: ValueListenableBuilder<double?>(
          valueListenable: progress,
          // The toast sizes its content to its intrinsic width: a fixed
          // bar width.
          builder: (context, p, _) => Row(
            key: ValueKey<String>('toast.progress.$id'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                // Room for the title column, the percentage and *Cancel* on
                // narrow windows.
                width: (MediaQuery.sizeOf(context).width - 280).clamp(
                  48.0,
                  180.0,
                ),
                child: ShadProgress(value: p?.clamp(0.0, 1.0)),
              ),
              const SizedBox(width: 8),
              Text(
                p == null ? '' : '${(p.clamp(0.0, 1.0) * 100).floor()} %',
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        action: cancelLabel == null || onCancel == null
            ? null
            : ValueListenableBuilder<bool>(
                valueListenable: can,
                builder: (context, enabled, _) => ShadButton.outline(
                  key: const ValueKey<String>('toast.progress.cancel'),
                  size: ShadButtonSize.sm,
                  enabled: enabled,
                  onPressed: onCancel,
                  child: Text(cancelLabel),
                ),
              ),
        displayDuration: duration,
      ),
    );
    return id;
  }

  void error(String title, {String? description}) =>
      show(title, description: description, destructive: true);

  void hide(int id) {
    final ctx = _context();
    if (ctx == null || !ctx.mounted) return;
    ShadSonner.maybeOf(ctx)?.hide(id);
  }
}
