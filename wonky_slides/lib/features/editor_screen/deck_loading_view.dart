import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../l10n/slides_l10n.dart';
import '../../theme/slides_tokens.dart';

/// "Downloading presentation…" over a skeleton navigator and slide
/// (Slides 04 §1, 02 §9.1). [progress] is 0..1 when known; [message] is
/// the session's own text.
class DeckLoadingView extends StatelessWidget {
  const DeckLoadingView({super.key, this.progress, this.message});

  final double? progress;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l = slidesL10n(context);
    final theme = ShadTheme.of(context);
    final tokens = SlidesTokens.of(context);
    final p = progress;
    final narrow = MediaQuery.sizeOf(context).width < 768;
    Widget bone(double h) => Container(
      height: h,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Stack(
      key: const ValueKey<String>('slides.loading'),
      children: [
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!narrow)
                Container(
                  width: 220,
                  color: tokens.navigatorBackground,
                  padding: const EdgeInsets.fromLTRB(28, 12, 12, 12),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: double.infinity,
                      child: Column(
                        children: [for (var i = 0; i < 5; i++) bone(86)],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ColoredBox(
                  color: tokens.canvasSurround,
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.card,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: theme.colorScheme.border),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.popover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p == null
                      ? message ?? l.deckLoading
                      : l.deckLoadingProgress(
                          message ?? l.deckDownloading,
                          (p * 100).round(),
                        ),
                  key: const ValueKey<String>('slides.loading.message'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.small,
                ),
                const SizedBox(height: 12),
                ShadProgress(value: p),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
