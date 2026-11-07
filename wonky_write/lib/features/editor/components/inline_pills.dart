import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:super_editor/super_editor.dart';

import '../attributions/wonky_attributions.dart';
import '../styles/editor_theme.dart';

/// A pill's padding left of its first character, in em (the right padding
/// is its last character's letter spacing, [PillGapAttribution.pill]).
const pillPaddingLeft = 0.55;

/// The inset of a left-to-right, start-aligned paragraph whose text starts
/// with a chip or button (Write 11 §7.2): the pill's left padding, so the
/// pill starts at the text margin instead of hanging over it (and over the
/// page or a container's edge). Zero for any other paragraph.
EdgeInsets leadingPillInset(ParagraphComponentViewModel viewModel) {
  final text = viewModel.text;
  if (text.isEmpty ||
      viewModel.textDirection != TextDirection.ltr ||
      !const {
        TextAlign.left,
        TextAlign.start,
        TextAlign.justify,
      }.contains(viewModel.textAlignment)) {
    return EdgeInsets.zero;
  }
  final attributions = text.getAllAttributionsAt(0);
  if (!attributions.any(
    (a) => a is ChipAttribution || (a is LinkStyleAttribution && a.isButton),
  )) {
    return EdgeInsets.zero;
  }
  final em = viewModel.textStyleBuilder(attributions).fontSize ?? 14.67;
  return EdgeInsets.only(left: em * pillPaddingLeft);
}

/// Paints the Wonky Markdown inline elements of a text component (Write 11
/// §7.2): the pills behind chips and buttons and the arrow after arrow
/// links, behind the text and above a container's background. The text
/// gets the room for them from `PillSpacingStylePhase`; a caret inside a
/// pill at its end is drawn next to its last glyph ([PillBoundary.caretRect]).
class InlinePillComponentBuilder implements ComponentBuilder {
  const InlinePillComponentBuilder(this.inner, {required this.theme});

  final ComponentBuilder inner;
  final EditorTheme theme;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    final component = inner.createComponent(componentContext, viewModel);
    if (component == null || viewModel is! TextComponentViewModel) {
      return component;
    }
    final text = viewModel.text;
    final pills = <_PillSpan>[];
    final style = theme.wonky;
    for (final span in text.getAttributionSpansInRange(
      attributionFilter: (a) =>
          a is ChipAttribution || a is LinkStyleAttribution,
      range: SpanRange(0, text.length),
    )) {
      final a = span.attribution;
      // The font size at the pill's first character, as [leadingPillInset]
      // reads it (the editor's text isn't scaled).
      double em() =>
          viewModel
              .textStyleBuilder(text.getAllAttributionsAt(span.start))
              .fontSize ??
          14.67;
      pills.add(switch (a) {
        ChipAttribution() => _PillSpan(
          span.start,
          span.end,
          fill: style.chipBackground,
          radius: style.chipRadius,
          padY: 0.28,
          em: em(),
        ),
        LinkStyleAttribution(isButton: true) => _PillSpan(
          span.start,
          span.end,
          fill: a.style == 'buttonSecondary'
              ? style.secondaryButtonBackground
              : style.buttonBackground,
          radius: style.buttonRadius,
          padY: 0.5,
          em: em(),
        ),
        _ => _PillSpan(span.start, span.end, arrow: style.arrowColor),
      });
    }
    if (pills.isEmpty) return component;
    return _PillPaint(
      componentKey: componentContext.componentKey,
      pills: pills,
      selection: viewModel.selection,
      child: component,
    );
  }
}

class _PillSpan {
  const _PillSpan(
    this.start,
    this.end, {
    this.fill,
    this.radius = 0,
    this.padY = 0,
    this.em = 0,
    this.arrow,
  });

  /// First and last character.
  final int start;
  final int end;

  /// The pill color, or `null` for an arrow link.
  final Color? fill;
  final double radius;

  /// Vertical padding of the pill in em.
  final double padY;

  /// The font size of the pill's text in px, the unit of its padding.
  final double em;

  /// The arrow color of an arrow link.
  final Color? arrow;
}

class _PillPaint extends StatefulWidget {
  const _PillPaint({
    required this.componentKey,
    required this.pills,
    required this.selection,
    required this.child,
  });

  final GlobalKey componentKey;
  final List<_PillSpan> pills;

  /// The selection in this text, shown over dark pills ([_PillPainter]).
  final TextSelection? selection;
  final Widget child;

  @override
  State<_PillPaint> createState() => _PillPaintState();
}

class _PillPaintState extends State<_PillPaint> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: _key,
    painter: _PillPainter(
      paintKey: _key,
      componentKey: widget.componentKey,
      pills: widget.pills,
      selection: widget.selection,
    ),
    child: widget.child,
  );
}

class _PillPainter extends CustomPainter {
  _PillPainter({
    required this.paintKey,
    required this.componentKey,
    required this.pills,
    this.selection,
  });

  final GlobalKey paintKey;
  final GlobalKey componentKey;
  final List<_PillSpan> pills;
  final TextSelection? selection;

  /// Lightens the selected part of a dark pill: the selection highlight,
  /// painted over it in the accent color, barely shows on a button filled
  /// with the same color.
  static const _selectedOnDark = Color(0x59FFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final state = componentKey.currentState;
    final paintBox = paintKey.currentContext?.findRenderObject();
    final componentBox = componentKey.currentContext?.findRenderObject();
    if (state is! DocumentComponent ||
        state is! TextComposable ||
        paintBox is! RenderBox ||
        componentBox is! RenderBox ||
        !componentBox.attached) {
      return;
    }
    final origin = componentBox.localToGlobal(Offset.zero, ancestor: paintBox);
    final DocumentComponent component = state;
    final composable = state as TextComposable;
    for (final pill in pills) {
      final rects = _lineRects(component, composable, pill.start, pill.end + 1);
      if (rects.isEmpty) continue;
      if (pill.fill != null) {
        final em = pill.em;
        for (final r in rects) {
          final rect = r.shift(origin);
          final pillRect = Rect.fromLTRB(
            rect.left - em * pillPaddingLeft,
            rect.top - em * pill.padY,
            // The last character's letter spacing (0.45 em) is in `rect`.
            rect.right - em * 0.05,
            rect.bottom + em * pill.padY,
          );
          final rrect = RRect.fromRectAndRadius(
            pillRect,
            Radius.circular(math.min(pill.radius, pillRect.height / 2)),
          );
          canvas.drawRRect(rrect, Paint()..color = pill.fill!);
          _paintSelection(canvas, component, composable, pill, rrect, origin);
        }
      } else {
        final r = rects.last.shift(origin);
        final em = r.height / 1.2;
        final icon = LucideIcons.arrowUpRight;
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: em * 0.9,
              color: pill.arrow,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        // In the gap (1.05 em) the last character's letter spacing leaves.
        painter.paint(
          canvas,
          Offset(r.right - em * 0.95, r.top + (r.height - painter.height) / 2),
        );
      }
    }
  }

  /// The selected part of a dark pill ([_selectedOnDark]), within the pill.
  void _paintSelection(
    Canvas canvas,
    DocumentComponent component,
    TextComposable composable,
    _PillSpan pill,
    RRect pillRect,
    Offset origin,
  ) {
    final s = selection;
    if (s == null || s.isCollapsed) return;
    if (pill.fill!.computeLuminance() > 0.4) return;
    final from = math.max(s.start, pill.start);
    final to = math.min(s.end, pill.end + 1);
    if (to <= from) return;
    canvas
      ..save()
      ..clipRRect(pillRect);
    final rects = _lineRects(component, composable, from, to);
    for (var i = 0; i < rects.length; i++) {
      final rect = rects[i].shift(origin);
      // The pill's padding is selected with its first or last character.
      final left = i == 0 && from == pill.start ? pillRect.left : rect.left;
      final right = i == rects.length - 1 && to == pill.end + 1
          ? pillRect.right
          : rect.right;
      canvas.drawRect(
        Rect.fromLTRB(left, pillRect.top, right, pillRect.bottom),
        Paint()..color = _selectedOnDark,
      );
    }
    canvas.restore();
  }

  /// Per-line rectangles of `[from, to)` in the component's coordinates.
  static List<Rect> _lineRects(
    DocumentComponent component,
    TextComposable composable,
    int from,
    int to,
  ) {
    final rects = <Rect>[];
    var cursor = from;
    for (var guard = 0; cursor < to && guard < 50; guard++) {
      final lineEnd = composable
          .getPositionAtEndOfLine(TextNodePosition(offset: cursor))
          .offset;
      final segmentEnd = lineEnd <= cursor ? to : math.min(lineEnd, to);
      final rect = component.getRectForSelection(
        TextNodePosition(offset: cursor),
        TextNodePosition(offset: segmentEnd),
      );
      if (rect.width > 0) rects.add(rect);
      if (segmentEnd >= to) break;
      final next = composable.getPositionOneLineDown(
        TextNodePosition(offset: cursor),
      );
      if (next == null) break;
      final nextStart = composable.getPositionAtStartOfLine(next).offset;
      cursor = nextStart > segmentEnd ? nextStart : segmentEnd;
    }
    return rects;
  }

  /// Positions depend on the layout at paint time.
  @override
  bool shouldRepaint(_PillPainter old) => true;

  /// Not a hit target: one in the document content layer hides the pointer
  /// from the editor's interactor below it, so taps in the line never
  /// placed the caret.
  @override
  bool? hitTest(Offset position) => false;
}
