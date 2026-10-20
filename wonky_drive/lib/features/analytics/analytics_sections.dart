import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/drive_l10n.dart';
import 'analytics_charts.dart';
import 'analytics_controller.dart';

/// Number and date formats of the Analytics page in the app's locale.
/// Days are UTC days (the server's), so dates are formatted as given.
class AnalyticsFormat {
  AnalyticsFormat(BuildContext context) : locale = _locale(context);

  final String locale;

  static String _locale(BuildContext context) {
    final l = Localizations.localeOf(context).toString();
    return DateFormat.localeExists(l) && NumberFormat.localeExists(l)
        ? l
        : 'en';
  }

  late final NumberFormat _int = NumberFormat.decimalPattern(locale);
  late final NumberFormat _compact = NumberFormat.compact(locale: locale);
  late final NumberFormat _percent = NumberFormat.percentPattern(locale);

  String count(num v) => _int.format(v.round());

  /// Below 10,000 in full, above compact ("12K").
  String compact(num v) =>
      v.abs() < 10000 ? _int.format(v.round()) : _compact.format(v);

  String percent(double v) => _percent.format(v);

  /// "Oct 3".
  String day(DateTime d) => DateFormat.MMMd(locale).format(d);

  /// "Mon, Oct 3".
  String dayTitle(DateTime d) => DateFormat.MMMEd(locale).format(d);

  /// "Oct 3, 2026".
  String date(DateTime d) => DateFormat.yMMMd(locale).format(d);

  /// "Oct 3 – Oct 9".
  String range(DateTime from, DateTime to) => '${day(from)} – ${day(to)}';

  /// "14:05" in the device's time zone.
  String time(DateTime t) => DateFormat.Hm(locale).format(t.toLocal());
}

/// A section card of the Analytics page: title, optional subtitle and
/// [actions], and the [chart] — or, after *Show as table*, [table].
class AnalyticsCard extends StatefulWidget {
  const AnalyticsCard({
    super.key,
    required this.id,
    required this.title,
    required this.chart,
    this.subtitle,
    this.actions = const [],
    this.table,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget chart;

  /// The same data as a table (null: no table view).
  final AnalyticsTableData Function()? table;

  @override
  State<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<AnalyticsCard> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final table = widget.table;
    return Container(
      key: ValueKey<String>('analytics.card.${widget.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          // Narrow cards put the actions (tabs) under the title.
          final stacked = box.maxWidth < 520 && widget.actions.isNotEmpty;
          final tableButton = table == null
              ? null
              : ShadIconButton.ghost(
                  key: ValueKey<String>('analytics.card.${widget.id}.table'),
                  width: 32,
                  height: 32,
                  iconSize: 16,
                  semanticLabel: _table
                      ? l.analyticsShowChart
                      : l.analyticsShowTable,
                  icon: Icon(
                    _table ? LucideIcons.chartLine : LucideIcons.table2,
                  ),
                  onPressed: () => setState(() => _table = !_table),
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            widget.title,
                            style: theme.textTheme.large,
                          ),
                        ),
                        if (widget.subtitle case final s?) ...[
                          const SizedBox(height: 2),
                          Text(s, style: theme.textTheme.muted),
                        ],
                      ],
                    ),
                  ),
                  if (!stacked) ...widget.actions,
                  ?tableButton,
                ],
              ),
              if (stacked) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, children: widget.actions),
                ),
              ],
              const SizedBox(height: 14),
              if (_table && table != null)
                AnalyticsTable(data: table())
              else
                widget.chart,
            ],
          );
        },
      ),
    );
  }
}

/// Rows of a chart's table view, newest first.
class AnalyticsTableData {
  const AnalyticsTableData({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;
}

/// The table view of a chart: a header and the rows, scrolling inside a
/// fixed height.
class AnalyticsTable extends StatelessWidget {
  const AnalyticsTable({super.key, required this.data});

  final AnalyticsTableData data;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final number = theme.textTheme.small.copyWith(
      fontWeight: FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget cell(String text, {bool header = false, bool first = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            text,
            textAlign: first ? TextAlign.left : TextAlign.right,
            style: header ? theme.textTheme.muted : number,
          ),
        );
    return SizedBox(
      height: 240,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder(
                horizontalInside: BorderSide(color: c.border),
              ),
              children: [
                TableRow(
                  children: [
                    for (var i = 0; i < data.columns.length; i++)
                      cell(data.columns[i], header: true, first: i == 0),
                  ],
                ),
                for (final r in data.rows)
                  TableRow(
                    children: [
                      for (var i = 0; i < r.length; i++)
                        cell(r[i], first: i == 0),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [series] over [days] as table rows, newest first.
AnalyticsTableData seriesTable(
  String dayColumn,
  List<String> dayLabels,
  List<AnalyticsSeries> series,
  String Function(num) format,
) => AnalyticsTableData(
  columns: [dayColumn, for (final s in series) s.label],
  rows: [
    for (var i = dayLabels.length - 1; i >= 0; i--)
      [dayLabels[i], for (final s in series) format(s.values[i])],
  ],
);

/// A headline number (specs/19 §3.1): label, value, a note, and an
/// optional sparkline of the period.
class AnalyticsKpi extends StatelessWidget {
  const AnalyticsKpi({
    super.key,
    required this.id,
    required this.label,
    required this.value,
    this.note,
    this.trend,
  });

  final String id;
  final String label;
  final String value;
  final String? note;
  final List<double>? trend;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    return Container(
      key: ValueKey<String>('analytics.kpi.$id'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Semantics(
        container: true,
        label: [label, value, ?note].join(', '),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.muted),
            const SizedBox(height: 4),
            Text(
              value,
              key: ValueKey<String>('analytics.kpi.$id.value'),
              style: theme.textTheme.h3.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note ?? '',
              style: theme.textTheme.muted.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (trend case final t?) ...[
              const SizedBox(height: 6),
              AnalyticsSparkline(values: t, color: AnalyticsColors.ink(c)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lays [children] out in equal columns: [wide] columns from 720 px,
/// [medium] from 460 px, otherwise [narrow].
class AnalyticsGrid extends StatelessWidget {
  const AnalyticsGrid({
    super.key,
    required this.children,
    this.wide = 3,
    this.medium = 2,
    this.narrow = 1,
    this.gap = 12,
  });

  final List<Widget> children;
  final int wide;
  final int medium;
  final int narrow;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 720
          ? wide
          : box.maxWidth >= 460
          ? medium
          : narrow;
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    },
  );
}

/// The weekly sign-up cohorts (specs/19 §3.5): one row per cohort, a cell
/// per week since sign-up with the share still active, shaded with the
/// ink by that share; weeks before tracking started are blank.
class AnalyticsCohortGrid extends StatelessWidget {
  const AnalyticsCohortGrid({super.key, required this.cohorts});

  final List<AnalyticsCohort> cohorts;

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final f = AnalyticsFormat(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final weeks = cohorts.fold<int>(0, (m, k) => math.max(m, k.active.length));
    final small = theme.textTheme.muted.copyWith(fontSize: 12);
    final number = theme.textTheme.small.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget head(String text, {TextAlign align = TextAlign.center}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(text, style: small, textAlign: align),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(48),
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              head(l.analyticsCohortWeek, align: TextAlign.left),
              head(l.analyticsCohortSize, align: TextAlign.right),
              for (var k = 0; k < weeks; k++) head(l.analyticsCohortWeekN(k)),
            ],
          ),
          for (final cohort in cohorts.reversed)
            TableRow(
              key: ValueKey<String>(
                'analytics.cohort.${cohort.week.toIso8601String()}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(f.day(cohort.week), style: theme.textTheme.small),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    f.count(cohort.size),
                    style: number,
                    textAlign: TextAlign.right,
                  ),
                ),
                for (var k = 0; k < weeks; k++)
                  _cell(context, cohort, k, f, number, c),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    AnalyticsCohort cohort,
    int k,
    AnalyticsFormat f,
    TextStyle number,
    ShadColorScheme c,
  ) {
    final l = driveL10n(context);
    final active = k < cohort.active.length ? cohort.active[k] : null;
    if (active == null || cohort.size == 0) {
      return const SizedBox(height: 30);
    }
    final share = active / cohort.size;
    final alpha = 0.06 + 0.8 * share;
    final label = l.analyticsCohortCell(
      f.day(cohort.week),
      k,
      active,
      f.percent(share),
    );
    return Padding(
      padding: const EdgeInsets.all(2),
      child: ShadTooltip(
        builder: (_) => Text(label),
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Container(
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.foreground.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              f.percent(share),
              style: number.copyWith(
                fontSize: 11,
                color: alpha > 0.5 ? c.background : c.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of three small numbers (collaboration).
class AnalyticsStatRow extends StatelessWidget {
  const AnalyticsStatRow({super.key, required this.stats});

  /// Id, label and value.
  final List<(String, String, String)> stats;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Wrap(
      spacing: 28,
      runSpacing: 8,
      children: [
        for (final (id, label, value) in stats)
          Column(
            key: ValueKey<String>('analytics.stat.$id'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.h4.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(label, style: theme.textTheme.muted),
            ],
          ),
      ],
    );
  }
}

/// The kinds of items in the content charts, with their colors (the kind
/// colors of the drive icons; files are Drive's).
List<(String, String, Color)> analyticsKinds(
  BuildContext context,
  ShadColorScheme c,
) {
  final la = WonkyAppLocalizations.of(context);
  final b = ShadTheme.of(context).brightness;
  return [
    ('document', la.settingsStorageDocuments, AnalyticsColors.write),
    ('spreadsheet', la.settingsStorageSpreadsheets, AnalyticsColors.sheets),
    ('presentation', la.settingsStoragePresentations, AnalyticsColors.slides),
    ('file', la.settingsStorageFiles, AnalyticsColors.drive(b)),
  ];
}

/// Items now by kind (count and bytes) and total storage, as a stacked bar
/// with legend.
class AnalyticsContentNow extends StatelessWidget {
  const AnalyticsContentNow({super.key, required this.overview});

  final AnalyticsOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final f = AnalyticsFormat(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final totals = {for (final t in overview.itemTotals) t.key: t};
    final kinds = analyticsKinds(context, c);
    final all = kinds.fold<int>(0, (s, k) => s + (totals[k.$1]?.count ?? 0));
    final segments = [
      for (final (id, label, color) in kinds)
        WonkyStackedBarSegment(
          id: id,
          label: label,
          value: (totals[id]?.count ?? 0).toDouble(),
          valueLabel: f.count(totals[id]?.count ?? 0),
          color: color,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.analyticsItemsTotal(
            f.count(all),
            storageBytes(overview.storageBytes),
          ),
          style: theme.textTheme.muted,
        ),
        const SizedBox(height: 10),
        WonkyStackedBar(
          key: const ValueKey<String>('analytics.content.bar'),
          keyPrefix: 'analytics.content.legend',
          total: math.max(1, all).toDouble(),
          segments: segments,
          semanticLabel: [
            l.analyticsContentNowTitle,
            for (final s in segments) s.legendText,
          ].join(', '),
        ),
      ],
    );
  }
}

/// Accounts by sign-in method as a stacked bar with legend.
class AnalyticsSignInMethods extends StatelessWidget {
  const AnalyticsSignInMethods({super.key, required this.overview});

  final AnalyticsOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = driveL10n(context);
    final f = AnalyticsFormat(context);
    final theme = ShadTheme.of(context);
    final c = theme.colorScheme;
    final methods = {for (final m in overview.signInMethods) m.key: m.count};
    final segments = [
      WonkyStackedBarSegment(
        id: 'email',
        label: l.analyticsSignInEmail,
        value: (methods['email'] ?? 0).toDouble(),
        valueLabel: f.count(methods['email'] ?? 0),
        color: AnalyticsColors.ink(c),
      ),
      WonkyStackedBarSegment(
        id: 'google',
        label: l.analyticsSignInGoogle,
        value: (methods['google'] ?? 0).toDouble(),
        valueLabel: f.count(methods['google'] ?? 0),
        color: AnalyticsColors.accent(theme.brightness),
      ),
    ];
    final total = segments.fold<double>(0, (s, x) => s + x.value);
    return WonkyStackedBar(
      key: const ValueKey<String>('analytics.signIn.bar'),
      keyPrefix: 'analytics.signIn.legend',
      total: math.max(1, total),
      segments: segments,
      semanticLabel: [
        l.analyticsSignInTitle,
        for (final s in segments) s.legendText,
      ].join(', '),
    );
  }
}

/// The bar chart of one daily measure, bucketed by [AnalyticsController]'s
/// rule (daily up to 90 days, weekly beyond), with its table view data.
({
  List<DateTime> starts,
  int size,
  List<AnalyticsSeries> series,
  String Function(int) title,
  List<String> labels,
})
bucketed(
  AnalyticsOverview o,
  AnalyticsFormat f,
  List<(String, String, Color, num Function(AnalyticsDay))> measures,
) {
  final days = [for (final d in o.series) d.day];
  final size = bucketSizeOf(o.days);
  final starts = bucketStarts(days, size);
  String title(int i) {
    if (size == 1) return f.dayTitle(starts[i]);
    final end = i + 1 < starts.length
        ? starts[i + 1].subtract(const Duration(days: 1))
        : days.last;
    return f.range(starts[i], end);
  }

  return (
    starts: starts,
    size: size,
    series: [
      for (final (id, label, color, pick) in measures)
        AnalyticsSeries(
          id: id,
          label: label,
          color: color,
          values: bucketSums([for (final d in o.series) pick(d)], size),
        ),
    ],
    title: title,
    labels: [for (var i = 0; i < starts.length; i++) title(i)],
  );
}
