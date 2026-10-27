import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:wonky_write_core/wonky_write_core.dart';

/// The colors of one callout type on screen.
@immutable
class CalloutColors {
  const CalloutColors({
    required this.background,
    required this.border,
    required this.title,
  });

  final Color background;
  final Color border;

  /// Label and icon.
  final Color title;
}

/// How a container frame is drawn (callout, details or card), in logical
/// pixels at 100 % zoom.
@immutable
class FrameStyle {
  const FrameStyle({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.radius,
    required this.padding,
    required this.spaceBefore,
    required this.spaceAfter,
    this.shadow = false,
  });

  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final EdgeInsets padding;
  final double spaceBefore;
  final double spaceAfter;
  final bool shadow;
}

/// The look of the Wonky Markdown elements in the editor (Write 11 §7.2,
/// §8), from the document theme's `ResolvedWonkyElements`.
@immutable
class WonkyEditorStyle {
  const WonkyEditorStyle({
    required this.callouts,
    required this.calloutFrame,
    required this.calloutTitleSizeRatio,
    required this.calloutTitleWeight,
    required this.calloutTitleCase,
    required this.detailsFrame,
    required this.detailsSummaryWeight,
    required this.chevronColor,
    required this.cardFrame,
    required this.gridBulletColor,
    required this.gridColumnGap,
    required this.gridRowGap,
    required this.gridSpaceBefore,
    required this.gridSpaceAfter,
    required this.buttonBackground,
    required this.buttonColor,
    required this.secondaryButtonBackground,
    required this.secondaryButtonColor,
    required this.buttonRadius,
    required this.buttonWeight,
    required this.arrowColor,
    required this.arrowWeight,
    required this.chipBackground,
    required this.chipColor,
    required this.chipRadius,
    required this.chipWeight,
    required this.stepBackground,
    required this.stepColor,
    required this.stepSizeRatio,
  });

  /// Converts resolved theme values (pt, ARGB) with [px] (pt → px).
  factory WonkyEditorStyle.fromResolved(
    ResolvedWonkyElements w,
    double Function(double pt) px,
  ) {
    EdgeInsets edges(EdgesPt e) =>
        EdgeInsets.fromLTRB(px(e.left), px(e.top), px(e.right), px(e.bottom));
    final co = w.callout;
    final de = w.details;
    return WonkyEditorStyle(
      callouts: {
        for (final v in CalloutVariant.values)
          v.value: () {
            final c = co.colorsFor(v.value);
            return CalloutColors(
              background: Color(c.background),
              border: Color(c.border),
              title: Color(c.title),
            );
          }(),
      },
      calloutFrame: FrameStyle(
        background: null,
        borderColor: null,
        borderWidth: px(co.borderWidth),
        radius: px(co.borderRadius),
        padding: edges(co.padding),
        spaceBefore: px(co.spaceBefore),
        spaceAfter: px(co.spaceAfter),
      ),
      calloutTitleSizeRatio: co.titleSizeRatio,
      calloutTitleWeight: _weight(co.titleWeight),
      calloutTitleCase: co.titleCase,
      detailsFrame: FrameStyle(
        background: de.background == null ? null : Color(de.background!),
        borderColor: de.border.isVisible ? Color(de.border.color) : null,
        borderWidth: de.border.isVisible ? px(de.border.width) : 0,
        radius: px(de.borderRadius),
        padding: edges(de.padding),
        spaceBefore: px(de.spaceBefore),
        spaceAfter: px(de.spaceAfter),
      ),
      detailsSummaryWeight: _weight(de.summaryWeight),
      chevronColor: Color(de.chevronColor),
      cardFrame: FrameStyle(
        background: w.card.background == null
            ? null
            : Color(w.card.background!),
        borderColor: null,
        borderWidth: 0,
        radius: px(w.card.borderRadius),
        padding: edges(w.card.padding),
        spaceBefore: px(w.card.spaceBefore),
        spaceAfter: px(w.card.spaceAfter),
        shadow: w.card.shadow,
      ),
      gridBulletColor: Color(w.grid.bulletColor),
      gridColumnGap: px(w.grid.columnGap),
      gridRowGap: px(w.grid.rowGap),
      gridSpaceBefore: px(w.grid.spaceBefore),
      gridSpaceAfter: px(w.grid.spaceAfter),
      buttonBackground: Color(w.button.background),
      buttonColor: Color(w.button.color),
      secondaryButtonBackground: Color(w.button.secondaryBackground),
      secondaryButtonColor: Color(w.button.secondaryColor),
      buttonRadius: px(w.button.borderRadius),
      buttonWeight: _weight(w.button.fontWeight),
      arrowColor: Color(w.button.arrowColor),
      arrowWeight: _weight(w.button.arrowWeight),
      chipBackground: Color(w.chip.background),
      chipColor: Color(w.chip.color),
      chipRadius: px(w.chip.borderRadius),
      chipWeight: _weight(w.chip.fontWeight),
      stepBackground: Color(w.stepBadge.background),
      stepColor: Color(w.stepBadge.color),
      stepSizeRatio: w.stepBadge.sizeRatio,
    );
  }

  /// Wonky Default's elements, until the document's theme is resolved.
  factory WonkyEditorStyle.fallback(Brightness brightness) =>
      _fallbacks[brightness] ??= WonkyEditorStyle.fromResolved(
        ThemeResolver.instance
            .resolve(
              BuiltinThemes.wonkyDefault.theme,
              brightness == Brightness.dark
                  ? ThemeVariant.dark
                  : ThemeVariant.light,
            )
            .wonky,
        (pt) => pt * 96 / 72,
      );

  static final _fallbacks = <Brightness, WonkyEditorStyle>{};

  static FontWeight _weight(int w) =>
      FontWeight.values[((w ~/ 100) - 1).clamp(0, 8)];

  /// Colors per callout type (`caution` included).
  final Map<String, CalloutColors> callouts;

  /// Callout geometry (colors per type in [callouts]).
  final FrameStyle calloutFrame;
  final double calloutTitleSizeRatio;
  final FontWeight calloutTitleWeight;
  final CaseTransform calloutTitleCase;

  final FrameStyle detailsFrame;
  final FontWeight detailsSummaryWeight;
  final Color chevronColor;

  final FrameStyle cardFrame;

  final Color gridBulletColor;
  final double gridColumnGap;
  final double gridRowGap;
  final double gridSpaceBefore;
  final double gridSpaceAfter;

  final Color buttonBackground;
  final Color buttonColor;
  final Color secondaryButtonBackground;
  final Color secondaryButtonColor;
  final double buttonRadius;
  final FontWeight buttonWeight;
  final Color arrowColor;
  final FontWeight arrowWeight;

  final Color chipBackground;
  final Color chipColor;
  final double chipRadius;
  final FontWeight chipWeight;

  final Color stepBackground;
  final Color stepColor;

  /// Badge diameter relative to the heading's font size.
  final double stepSizeRatio;

  /// The colors of callout type [variant].
  CalloutColors calloutColors(CalloutVariant? variant) =>
      callouts[(variant ?? CalloutVariant.info).value]!;

  /// The frame of [frame]'s container type, with a callout's colors.
  FrameStyle frameOf(BoxFrame frame) => switch (frame.type) {
    BoxType.callout => FrameStyle(
      background: calloutColors(frame.variant).background,
      borderColor: calloutColors(frame.variant).border,
      borderWidth: calloutFrame.borderWidth,
      radius: calloutFrame.radius,
      padding: calloutFrame.padding,
      spaceBefore: calloutFrame.spaceBefore,
      spaceAfter: calloutFrame.spaceAfter,
    ),
    BoxType.details => detailsFrame,
    BoxType.card => cardFrame,
  };
}
