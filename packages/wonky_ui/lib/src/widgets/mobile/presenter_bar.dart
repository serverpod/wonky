import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../l10n/wonky_ui_localizations.dart';

/// The top bar of the mobile presenter mode (suite 02 §6, Slides 10 §1.6):
/// close (exits the mode), the title with "3 of 12", and back / forward.
/// Themed with the app's light or dark colors.
class WonkyPresenterBar extends StatelessWidget {
  const WonkyPresenterBar({
    super.key,
    required this.title,
    required this.current,
    required this.total,
    required this.onClose,
    this.onPrevious,
    this.onNext,
  });

  /// Height of the bar.
  static const double height = 52;

  final String title;

  /// 1-based number of the shown slide (0 while there is none).
  final int current;
  final int total;
  final VoidCallback onClose;

  /// Null disables the button (first / last step).
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = WonkyUiLocalizations.of(context);
    Widget button(
      String key,
      IconData icon,
      String label,
      VoidCallback? onPressed,
    ) => ShadTooltip(
      builder: (_) => Text(label),
      child: ShadIconButton.ghost(
        key: ValueKey<String>(key),
        width: 44,
        height: 44,
        iconSize: 22,
        semanticLabel: label,
        enabled: onPressed != null,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
    return Semantics(
      container: true,
      label: l.presenterBarLabel,
      child: Container(
        key: const ValueKey<String>('presenter.bar'),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
        ),
        child: Row(
          children: [
            button('presenter.close', LucideIcons.x, l.presenterExit, onClose),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small,
                  ),
                  if (total > 0)
                    Text(
                      l.presenterPosition(current, total),
                      key: const ValueKey<String>('presenter.position'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                ],
              ),
            ),
            button(
              'presenter.previous',
              LucideIcons.chevronLeft,
              l.presenterPrevious,
              onPrevious,
            ),
            button(
              'presenter.next',
              LucideIcons.chevronRight,
              l.presenterNext,
              onNext,
            ),
          ],
        ),
      ),
    );
  }
}
