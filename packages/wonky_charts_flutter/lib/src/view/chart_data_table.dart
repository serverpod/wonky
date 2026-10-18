import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_charts/wonky_charts.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

/// Header and formatted rows of [data] (domain + series columns; table
/// charts: their own columns).
({List<String> headers, List<List<String>> rows}) chartDataRows(
  ChartData data, {
  String locale = 'en_US',
}) {
  final t = data.table;
  if (t != null) {
    return (
      headers: t.headers,
      rows: [
        for (var r = 0; r < t.rowCount; r++)
          [for (final col in t.texts) r < col.length ? col[r] : ''],
      ],
    );
  }
  final fmt = DefaultChartValueFormatter(locale: locale);
  final d = data.domain;
  final withDomain = !d.isSynthetic;
  return (
    headers: [if (withDomain) d.name, for (final s in data.series) s.name],
    rows: [
      for (var i = 0; i < d.length; i++)
        [
          if (withDomain) d.labels[i],
          for (final s in data.series)
            i < s.values.length && !s.values[i].isNaN
                ? fmt.format(s.values[i], s.numberFormat)
                : '',
        ],
    ],
  );
}

/// `{headers, rows}` of [data] for MCP callers (`*.chart.viewDataTable`).
Map<String, Object?> chartDataJson(ChartData data, {String locale = 'en_US'}) {
  final t = chartDataRows(data, locale: locale);
  return {'headers': t.headers, 'rows': t.rows};
}

/// The localized texts of [showChartDataTableDialog].
class ChartDataTableStrings {
  const ChartDataTableStrings({
    required this.title,
    required this.close,
    required this.noData,
  });

  /// Dialog title ("Data: Revenue by region").
  final String title;
  final String close;

  /// Shown when the chart has no data.
  final String noData;
}

/// "View data as table" (Sheets 08 §14, Slides 08 §17): a read-only table of
/// a chart's resolved data (at most 500 rows).
Future<void> showChartDataTableDialog(
  BuildContext context, {
  required ChartData data,
  required ChartDataTableStrings strings,
  String locale = 'en_US',
  Key dialogKey = const ValueKey<String>('dialog.chartData'),
}) => showShadDialog<void>(
  context: context,
  builder: (context) => ChartDataTableDialog(
    data: data,
    strings: strings,
    locale: locale,
    dialogKey: dialogKey,
  ),
);

/// The dialog of [showChartDataTableDialog].
class ChartDataTableDialog extends StatelessWidget {
  const ChartDataTableDialog({
    super.key,
    required this.data,
    required this.strings,
    this.locale = 'en_US',
    this.dialogKey = const ValueKey<String>('dialog.chartData'),
  });

  final ChartData data;
  final ChartDataTableStrings strings;
  final String locale;
  final Key dialogKey;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = chartDataRows(data, locale: locale);
    final rows = t.rows.take(500).toList();
    final width = MediaQuery.sizeOf(context).width;
    return ShadDialog(
      key: dialogKey,
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(strings.title),
      constraints: BoxConstraints(
        maxWidth: width < 672 ? width - 32 : 640,
        maxHeight: 560,
      ),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
      ],
      child: t.headers.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(strings.noData, style: theme.textTheme.muted),
            )
          : SizedBox(
              height: 360,
              child: ShadTable.list(
                header: [
                  for (final h in t.headers)
                    ShadTableCell.header(
                      child: Text(
                        h,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                children: [
                  for (final r in rows)
                    [
                      for (final c in r)
                        ShadTableCell(
                          child: Text(
                            c,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                ],
              ),
            ),
    );
  }
}
