import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import '../editor_screen/slide_labels.dart';
import '../stage/slide_renderer.dart';
import 'deck_renderer.dart';
import 'nav_thumbnail.dart';

/// The compact slide selector of the mobile layout (Slides 04 §16.1): one
/// row of small thumbnails with their numbers below the slide; tapping one
/// shows it (`slides.nav.goToSlide`). The current slide is kept in view.
class MobileSlideStrip extends StatefulWidget {
  const MobileSlideStrip({
    super.key,
    required this.services,
    required this.editor,
  });

  /// Width of a thumbnail.
  static const double thumbWidth = 72;
  static const double _gap = 8;

  final ShellServices services;
  final DeckEditorController editor;

  @override
  State<MobileSlideStrip> createState() => _MobileSlideStripState();
}

class _MobileSlideStripState extends State<MobileSlideStrip> {
  late SlideRenderer _renderer;
  final _scroll = ScrollController();
  String? _shown;

  DeckEditorController get ed => widget.editor;

  @override
  void initState() {
    super.initState();
    _renderer = DeckThumbnails.acquire(ed);
  }

  @override
  void didUpdateWidget(MobileSlideStrip old) {
    super.didUpdateWidget(old);
    if (!identical(old.editor, widget.editor)) {
      DeckThumbnails.release(old.editor, _renderer);
      _renderer = DeckThumbnails.acquire(ed);
    }
  }

  @override
  void dispose() {
    DeckThumbnails.release(ed, _renderer);
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls the current slide to the middle of the strip once it changes.
  void _keepCurrentInView(int index, double viewport) {
    final id = ed.currentSlideId;
    if (id == _shown) return;
    _shown = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      const step = MobileSlideStrip.thumbWidth + MobileSlideStrip._gap;
      final target = (index * step - (viewport - step) / 2).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      if (WonkyThemeScope.of(context).reduceMotion) {
        _scroll.jumpTo(target);
      } else {
        unawaited(
          _scroll.animateTo(
            target,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = slidesL10n(context);
    final size = _renderer.slideSize;
    const w = MobileSlideStrip.thumbWidth;
    final thumbHeight = w * size.height / size.width;
    return ListenableBuilder(
      listenable: ed,
      builder: (context, _) {
        final entries = ed.order.entries;
        return LayoutBuilder(
          builder: (context, box) {
            final current = entries.indexWhere(
              (e) => e.id == ed.currentSlideId,
            );
            if (current >= 0) _keepCurrentInView(current, box.maxWidth);
            return Container(
              key: const ValueKey<String>('slides.mobile.strip'),
              height: thumbHeight + 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.border),
                ),
              ),
              child: ListView.separated(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: MobileSlideStrip._gap),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final title = SlideLabels.title(ed.model, e.id);
                  final isCurrent = i == current;
                  return Semantics(
                    button: true,
                    selected: isCurrent,
                    label: l.navigatorSlideSemantics(
                      i + 1,
                      entries.length,
                      title.isEmpty ? l.slideUntitled : title,
                    ),
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey<String>('slides.mobile.slide.${e.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => unawaited(
                        ed.invokeCommand(
                          'slides.nav.goToSlide',
                          {'slideId': e.id},
                          InvocationSource.ui,
                          context,
                        ),
                      ),
                      child: SizedBox(
                        width: w,
                        child: Column(
                          children: [
                            NavThumbnail(
                              renderer: _renderer,
                              slideId: e.id,
                              width: w,
                              current: isCurrent,
                              skipped: e.skipped,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${i + 1}',
                              style: theme.textTheme.muted.copyWith(
                                fontSize: 12,
                                color: isCurrent
                                    ? theme.colorScheme.foreground
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
