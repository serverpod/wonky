import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// Colors of the analytics charts (specs/19 §3.2). The apps keep the kind
/// colors of the drive icons (Write blue, Sheets green, Slides amber);
/// Drive is pink and MCP cyan, because Drive's violet cannot be told from
/// blue with deuteranopia. The set was checked for color vision deficiency
/// in light and dark (worst pair ΔE 6.1, so legends and tooltips always
/// name the series). Measures that are no app use the ink and [accent].
abstract final class AnalyticsColors {
  static const write = Color(0xff2563eb);
  static const sheets = Color(0xff16a34a);
  static const slides = Color(0xffd97706);
  static const mcp = Color(0xff0891b2);

  static Color drive(Brightness b) =>
      b == Brightness.dark ? const Color(0xffec4899) : const Color(0xffdb2777);

  /// The second measure of a chart (editors, shares).
  static Color accent(Brightness b) =>
      b == Brightness.dark ? const Color(0xffa78bfa) : const Color(0xff7c3aed);

  /// The main measure of a chart (active users, accounts).
  static Color ink(ShadColorScheme c) => c.foreground;
}

/// One series of an analytics chart.
@immutable
class AnalyticsSeries {
  const AnalyticsSeries({
    required this.id,
    required this.label,
    required this.color,
    required this.values,
    this.dashed = false,
    this.area = false,
  });

  final String id;
  final String label;
  final Color color;

  /// One value per point (day or bar), oldest first.
  final List<double> values;

  /// Drawn dashed (line charts): a second cue beside the color.
  final bool dashed;

  /// Filled below the line (line charts; the main measure).
  final bool area;
}

TextStyle _axisStyle(ShadThemeData theme) => theme.textTheme.muted.copyWith(
  fontSize: 11,
  height: 1.2,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// The value ticks of a chart whose largest value is [max]: 0 and four
/// round steps (integers: at least 1 apart).
List<double> _ticks(double max) {
  if (max <= 0) return const [0, 1, 2, 3, 4];
  final raw = max / 4;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  var step = mag;
  for (final f in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    step = f * mag;
    if (step >= raw) break;
  }
  if (step < 1) step = 1;
  return [for (var i = 0; i <= 4; i++) step * i];
}

/// The plot area of a chart of [size] whose value labels are [labelWidth]
/// wide.
Rect _plot(Size size, double labelWidth) =>
    Rect.fromLTRB(labelWidth + 10, 8, size.width - 6, size.height - 22);

double _labelWidth(
  List<double> ticks,
  String Function(num) format,
  TextStyle s,
) {
  var w = 0.0;
  for (final t in ticks) {
    final tp = TextPainter(
      text: TextSpan(text: format(t), style: s),
      textDirection: TextDirection.ltr,
    )..layout();
    w = math.max(w, tp.width);
  }
  return w;
}

/// The indices of the date labels under a plot [width] wide with [n]
/// points: evenly spaced, anchored at the last point (today).
List<int> _dateTicks(int n, double width, {double every = 76}) {
  if (n <= 0) return const [];
  final most = (width / every).floor().clamp(2, 8);
  final step = math.max(1, ((n - 1) / (most - 1)).ceil());
  return [for (var i = n - 1; i >= 0; i -= step) i].reversed.toList();
}

void _paintText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset at, {
  Alignment align = Alignment.topLeft,
  double? minX,
  double? maxX,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  var x = at.dx - tp.width * (align.x + 1) / 2;
  final y = at.dy - tp.height * (align.y + 1) / 2;
  if (minX != null) x = math.max(minX, x);
  if (maxX != null) x = math.min(maxX - tp.width, x);
  tp.paint(canvas, Offset(x, y));
}

void _paintGrid(
  Canvas canvas,
  Rect plot,
  List<double> ticks,
  String Function(num) format,
  ShadThemeData theme,
) {
  final c = theme.colorScheme;
  final grid = Paint()
    ..color = c.border.withValues(alpha: 0.7)
    ..strokeWidth = 1;
  final top = ticks.last;
  final style = _axisStyle(theme);
  for (final t in ticks) {
    final y = (plot.bottom - (t / top) * plot.height).roundToDouble() + 0.5;
    if (t > 0) {
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    _paintText(
      canvas,
      format(t),
      style,
      Offset(plot.left - 8, y),
      align: Alignment.centerRight,
    );
  }
  canvas.drawLine(
    Offset(plot.left, plot.bottom + 0.5),
    Offset(plot.right, plot.bottom + 0.5),
    Paint()
      ..color = c.border
      ..strokeWidth = 1,
  );
}

// ------------------------------------------------------------- legend

/// The legend of a chart with two or more series: a swatch (a line for
/// line charts) and the name; a click hides or shows the series.
class AnalyticsLegend extends StatelessWidget {
  const AnalyticsLegend({
    super.key,
    required this.series,
    required this.hidden,
    required this.onToggle,
    this.lines = false,
  });

  final List<AnalyticsSeries> series;
  final Set<String> hidden;
  final ValueChanged<String> onToggle;
  final bool lines;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final s in series)
          Semantics(
            button: true,
            toggled: !hidden.contains(s.id),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                key: ValueKey<String>('analytics.legend.${s.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onToggle(s.id),
                child: Opacity(
                  opacity: hidden.contains(s.id) ? 0.4 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Swatch(color: s.color, line: lines, dashed: s.dashed),
                        const SizedBox(width: 6),
                        Text(s.label, style: theme.textTheme.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.line = false, this.dashed = false});

  final Color color;
  final bool line;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    if (!line) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return SizedBox(
      width: 14,
      height: 10,
      child: CustomPaint(
        painter: _LineSwatchPainter(color: color, dashed: dashed),
      ),
    );
  }
}

class _LineSwatchPainter extends CustomPainter {
  _LineSwatchPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (dashed) {
      canvas.drawLine(Offset(1, y), Offset(5, y), p);
      canvas.drawLine(Offset(9, y), Offset(13, y), p);
    } else {
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), p);
    }
  }

  @override
  bool shouldRepaint(_LineSwatchPainter old) =>
      old.color != color || old.dashed != dashed;
}

// ------------------------------------------------------------ tooltip

/// The hover card of a chart: a title (the day or the bar's days) and the
/// series' values with their swatches.
class AnalyticsTooltip extends StatelessWidget {
  const AnalyticsTooltip({
    super.key,
    required this.title,
    required this.rows,
    this.lines = false,
  });

  final String title;
  final List<(AnalyticsSeries, String)> rows;
  final bool lines;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final value = theme.textTheme.small.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return IgnorePointer(
      child: Container(
        key: const ValueKey<String>('analytics.tooltip'),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: c.popover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff000000).withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.small),
            const SizedBox(height: 6),
            Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                for (final (s, v) in rows)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Swatch(
                          color: s.color,
                          line: lines,
                          dashed: s.dashed,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 2),
                        child: Text(s.label, style: theme.textTheme.muted),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          v,
                          style: value,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The hover handling shared by the charts: mouse hover, and taps and
/// drags on touch screens, report the x position; leaving clears it.
class _HoverArea extends StatelessWidget {
  const _HoverArea({required this.onX, required this.child});

  final ValueChanged<double?> onX;
  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onHover: (e) => onX(e.localPosition.dx),
    onExit: (_) => onX(null),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => onX(d.localPosition.dx),
      onHorizontalDragUpdate: (d) => onX(d.localPosition.dx),
      onHorizontalDragEnd: (_) => onX(null),
      dragStartBehavior: DragStartBehavior.down,
      child: child,
    ),
  );
}

/// Places the tooltip beside the hovered x: right of it in the left half,
/// left of it in the right half.
Widget _placeTooltip(double x, double width, Widget tooltip) => Positioned(
  top: 0,
  left: x <= width / 2 ? x + 14 : null,
  right: x > width / 2 ? width - x + 14 : null,
  child: tooltip,
);

// --------------------------------------------------------- line chart

/// A line chart over days (specs/19 §3.2): 2 px lines, the first [area]
/// series filled, recessive gridlines, a crosshair with dots and a tooltip
/// on hover, and a legend for two or more series (click hides a series).
class AnalyticsLineChart extends StatefulWidget {
  const AnalyticsLineChart({
    super.key,
    required this.days,
    required this.series,
    required this.format,
    required this.dayLabel,
    required this.dayTitle,
    this.height = 200,
    this.semanticLabel,
  });

  final List<DateTime> days;
  final List<AnalyticsSeries> series;
  final String Function(num v) format;

  /// Short date of the axis ("Oct 3").
  final String Function(DateTime d) dayLabel;

  /// Date of the tooltip ("Mon, Oct 3").
  final String Function(DateTime d) dayTitle;
  final double height;
  final String? semanticLabel;

  @override
  State<AnalyticsLineChart> createState() => _AnalyticsLineChartState();
}

class _AnalyticsLineChartState extends State<AnalyticsLineChart> {
  int? _hover;
  final Set<String> _hidden = {};

  List<AnalyticsSeries> get _shown => [
    for (final s in widget.series)
      if (!_hidden.contains(s.id)) s,
  ];

  void _toggle(String id) => setState(() {
    if (!_hidden.remove(id)) _hidden.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final shown = _shown;
    final n = widget.days.length;
    var max = 0.0;
    for (final s in shown) {
      for (final v in s.values) {
        max = math.max(max, v);
      }
    }
    final ticks = _ticks(max);
    final labelWidth = _labelWidth(ticks, widget.format, _axisStyle(theme));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.series.length > 1) ...[
          AnalyticsLegend(
            series: widget.series,
            hidden: _hidden,
            onToggle: _toggle,
            lines: true,
          ),
          const SizedBox(height: 10),
        ],
        Semantics(
          label: widget.semanticLabel,
          image: true,
          child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, widget.height);
                final plot = _plot(size, labelWidth);
                double xOf(int i) => n <= 1
                    ? plot.center.dx
                    : plot.left + plot.width * i / (n - 1);
                final hover = _hover;
                return _HoverArea(
                  onX: (x) {
                    int? i;
                    if (x != null && n > 0) {
                      i = n <= 1
                          ? 0
                          : ((x - plot.left) / plot.width * (n - 1))
                                .round()
                                .clamp(0, n - 1);
                    }
                    if (i != _hover) setState(() => _hover = i);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LinePainter(
                            theme: theme,
                            days: widget.days,
                            series: shown,
                            ticks: ticks,
                            labelWidth: labelWidth,
                            format: widget.format,
                            dayLabel: widget.dayLabel,
                            hover: hover,
                          ),
                        ),
                      ),
                      if (hover != null && shown.isNotEmpty)
                        _placeTooltip(
                          xOf(hover),
                          size.width,
                          AnalyticsTooltip(
                            title: widget.dayTitle(widget.days[hover]),
                            lines: true,
                            rows: [
                              for (final s in shown)
                                (s, widget.format(s.values[hover])),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.theme,
    required this.days,
    required this.series,
    required this.ticks,
    required this.labelWidth,
    required this.format,
    required this.dayLabel,
    required this.hover,
  });

  final ShadThemeData theme;
  final List<DateTime> days;
  final List<AnalyticsSeries> series;
  final List<double> ticks;
  final double labelWidth;
  final String Function(num) format;
  final String Function(DateTime) dayLabel;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _plot(size, labelWidth);
    if (plot.width <= 0 || plot.height <= 0) return;
    final c = theme.colorScheme;
    final n = days.length;
    final top = ticks.last;
    double x(int i) =>
        n <= 1 ? plot.center.dx : plot.left + plot.width * i / (n - 1);
    double y(double v) => plot.bottom - (v / top) * plot.height;

    _paintGrid(canvas, plot, ticks, format, theme);
    final style = _axisStyle(theme);
    for (final i in _dateTicks(n, plot.width)) {
      _paintText(
        canvas,
        dayLabel(days[i]),
        style,
        Offset(x(i), plot.bottom + 6),
        align: Alignment.topCenter,
        minX: 0,
        maxX: size.width,
      );
    }
    if (hover != null) {
      final hx = x(hover!).roundToDouble() + 0.5;
      canvas.drawLine(
        Offset(hx, plot.top),
        Offset(hx, plot.bottom),
        Paint()
          ..color = c.mutedForeground.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }
    for (final s in series.reversed) {
      if (n == 0) continue;
      final path = Path()..moveTo(x(0), y(s.values[0]));
      for (var i = 1; i < n; i++) {
        path.lineTo(x(i), y(s.values[i]));
      }
      if (s.area) {
        final fill = Path.from(path)
          ..lineTo(x(n - 1), plot.bottom)
          ..lineTo(x(0), plot.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: 0.16),
                s.color.withValues(alpha: 0.01),
              ],
            ).createShader(plot),
        );
      }
      final stroke = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(s.dashed ? _dash(path) : path, stroke);
      if (n == 1) canvas.drawCircle(Offset(x(0), y(s.values[0])), 3, stroke);
    }
    if (hover != null) {
      for (final s in series) {
        final p = Offset(x(hover!), y(s.values[hover!]));
        canvas
          ..drawCircle(p, 6, Paint()..color = c.card)
          ..drawCircle(p, 4, Paint()..color = s.color);
      }
    }
  }

  /// [path] cut into 6 px dashes with 4 px gaps.
  static Path _dash(Path path) {
    final out = Path();
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, math.min(d + 6, m.length)), Offset.zero);
        d += 10;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.theme != theme ||
      old.days != days ||
      old.series != series ||
      old.hover != hover ||
      old.labelWidth != labelWidth;
}

// ---------------------------------------------------------- bar chart

/// Stacked columns over days or weeks (specs/19 §3.2): one bar per
/// [starts] entry covering [bucketDays] days, a 2 px gap between stacked
/// segments, rounded tops, a highlight band and a tooltip with the total
/// on hover, and a legend for two or more series.
class AnalyticsBarChart extends StatefulWidget {
  const AnalyticsBarChart({
    super.key,
    required this.starts,
    required this.bucketDays,
    required this.series,
    required this.format,
    required this.dayLabel,
    required this.bucketTitle,
    required this.totalLabel,
    this.height = 200,
    this.semanticLabel,
  });

  /// The first day of each bar, oldest first.
  final List<DateTime> starts;
  final int bucketDays;
  final List<AnalyticsSeries> series;
  final String Function(num v) format;
  final String Function(DateTime d) dayLabel;

  /// The tooltip title of the bar [i] ("Mon, Oct 3" or "Oct 3 – 9").
  final String Function(int i) bucketTitle;

  /// "Total" (shown in the tooltip of stacked bars).
  final String totalLabel;
  final double height;
  final String? semanticLabel;

  @override
  State<AnalyticsBarChart> createState() => _AnalyticsBarChartState();
}

class _AnalyticsBarChartState extends State<AnalyticsBarChart> {
  int? _hover;
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final shown = [
      for (final s in widget.series)
        if (!_hidden.contains(s.id)) s,
    ];
    final n = widget.starts.length;
    final totals = [
      for (var i = 0; i < n; i++)
        shown.fold<double>(0, (sum, s) => sum + s.values[i]),
    ];
    final ticks = _ticks(totals.fold(0, math.max));
    final labelWidth = _labelWidth(ticks, widget.format, _axisStyle(theme));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.series.length > 1) ...[
          AnalyticsLegend(
            series: widget.series,
            hidden: _hidden,
            onToggle: (id) => setState(() {
              if (!_hidden.remove(id)) _hidden.add(id);
            }),
          ),
          const SizedBox(height: 10),
        ],
        Semantics(
          label: widget.semanticLabel,
          image: true,
          child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, widget.height);
                final plot = _plot(size, labelWidth);
                final slot = n == 0 ? 0.0 : plot.width / n;
                final hover = _hover;
                return _HoverArea(
                  onX: (x) {
                    int? i;
                    if (x != null && n > 0 && slot > 0) {
                      i = ((x - plot.left) / slot).floor().clamp(0, n - 1);
                    }
                    if (i != _hover) setState(() => _hover = i);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BarPainter(
                            theme: theme,
                            starts: widget.starts,
                            series: shown,
                            ticks: ticks,
                            labelWidth: labelWidth,
                            format: widget.format,
                            dayLabel: widget.dayLabel,
                            hover: hover,
                          ),
                        ),
                      ),
                      if (hover != null && shown.isNotEmpty)
                        _placeTooltip(
                          plot.left + slot * (hover + 0.5),
                          size.width,
                          AnalyticsTooltip(
                            title: widget.bucketTitle(hover),
                            rows: [
                              for (final s in shown.reversed)
                                (s, widget.format(s.values[hover])),
                              if (shown.length > 1)
                                (
                                  AnalyticsSeries(
                                    id: 'total',
                                    label: widget.totalLabel,
                                    color: const Color(0x00000000),
                                    values: const [],
                                  ),
                                  widget.format(totals[hover]),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.theme,
    required this.starts,
    required this.series,
    required this.ticks,
    required this.labelWidth,
    required this.format,
    required this.dayLabel,
    required this.hover,
  });

  final ShadThemeData theme;
  final List<DateTime> starts;
  final List<AnalyticsSeries> series;
  final List<double> ticks;
  final double labelWidth;
  final String Function(num) format;
  final String Function(DateTime) dayLabel;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _plot(size, labelWidth);
    if (plot.width <= 0 || plot.height <= 0) return;
    final c = theme.colorScheme;
    final n = starts.length;
    if (n == 0) return;
    final slot = plot.width / n;
    final barWidth = math.min(28.0, math.max(1.0, slot * 0.72));
    final top = ticks.last;

    if (hover != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(plot.left + slot * hover!, plot.top, slot, plot.height),
          const Radius.circular(4),
        ),
        Paint()..color = c.muted.withValues(alpha: 0.8),
      );
    }
    _paintGrid(canvas, plot, ticks, format, theme);
    final style = _axisStyle(theme);
    for (final i in _dateTicks(n, plot.width)) {
      _paintText(
        canvas,
        dayLabel(starts[i]),
        style,
        Offset(plot.left + slot * (i + 0.5), plot.bottom + 6),
        align: Alignment.topCenter,
        minX: 0,
        maxX: size.width,
      );
    }
    // A 2 px gap between stacked segments (only when bars are wide enough
    // to show it).
    final gap = barWidth >= 6 ? 2.0 : 0.0;
    final radius = math.min(4.0, barWidth / 2);
    for (var i = 0; i < n; i++) {
      final left = plot.left + slot * i + (slot - barWidth) / 2;
      var base = plot.bottom;
      final segments = [
        for (final s in series)
          if (s.values[i] > 0) s,
      ];
      for (var k = 0; k < segments.length; k++) {
        final s = segments[k];
        final h = s.values[i] / top * plot.height;
        final isTop = k == segments.length - 1;
        var rectTop = base - h;
        final rectBottom = k == 0 ? base : base - gap;
        if (rectBottom - rectTop < 1) rectTop = rectBottom - 1;
        final rect = Rect.fromLTRB(left, rectTop, left + barWidth, rectBottom);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: isTop ? Radius.circular(radius) : Radius.zero,
            topRight: isTop ? Radius.circular(radius) : Radius.zero,
          ),
          Paint()..color = s.color,
        );
        base -= h;
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.theme != theme ||
      old.starts != starts ||
      old.series != series ||
      old.hover != hover ||
      old.labelWidth != labelWidth;
}

// ------------------------------------------------------------ others

/// A ranked list of horizontal bars (AI by feature or model): label, bar
/// relative to the largest value, and the value as text.
class AnalyticsRankBars extends StatelessWidget {
  const AnalyticsRankBars({
    super.key,
    required this.rows,
    required this.color,
    this.keyPrefix = 'analytics.rank',
  });

  /// Label, value and its text, largest first.
  final List<(String, double, String)> rows;
  final Color color;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final max = rows.fold<double>(0, (m, r) => math.max(m, r.$2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, value, text) in rows)
          Padding(
            key: ValueKey<String>('$keyPrefix.$label'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: theme.textTheme.muted.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: c.muted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        height: 6,
                        width: max <= 0
                            ? 0
                            : math.max(3, box.maxWidth * value / max),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A small trend line under a KPI (no axes): 2 px, the last point marked.
class AnalyticsSparkline extends StatelessWidget {
  const AnalyticsSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 28,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparkPainter(
          values,
          color,
          ShadTheme.of(context).colorScheme,
        ),
      ),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.c);

  final List<double> values;
  final Color color;
  final ShadColorScheme c;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final max = values.fold<double>(0, math.max);
    final top = max <= 0 ? 1.0 : max;
    final n = values.length;
    Offset at(int i) => Offset(
      2 + (size.width - 4) * i / (n - 1),
      size.height - 3 - (values[i] / top) * (size.height - 6),
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas
      ..drawCircle(at(n - 1), 4, Paint()..color = c.card)
      ..drawCircle(at(n - 1), 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color || old.c != c;
}
