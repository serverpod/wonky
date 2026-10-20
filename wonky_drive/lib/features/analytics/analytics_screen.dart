import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource, KeyScope;
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/drive_l10n.dart';
import 'analytics_charts.dart';
import 'analytics_controller.dart';
import 'analytics_sections.dart';

/// The Analytics page `/analytics` (specs/19 §3) in the home frame (top
/// bar, left menu with *Analytics* highlighted), for admins: headline
/// numbers, active users, apps, accounts, content, collaboration, AI, MCP,
/// and sign-up cohorts. [days] and [includeAdmins] come from
/// `?days=` and `?admins=` (`drive.analytics.show`).
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.services,
    this.days = analyticsDefaultDays,
    this.includeAdmins = false,
  });

  final ShellServices services;
  final int days;
  final bool includeAdmins;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

/// Which rolling count the *Active users* chart shows.
enum _ActiveView { daily, weekly, monthly }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsController c = AnalyticsController(
    services: widget.services,
    days: widget.days,
    includeAdmins: widget.includeAdmins,
  );
  final _scroll = ScrollController();
  final _pageFocus = FocusNode(debugLabel: 'analytics.page');
  final _searchFocus = FocusNode(debugLabel: 'analytics.search');
  final _sidebarFocus = FocusNode(
    debugLabel: 'analytics.sidebar',
    skipTraversal: true,
  );
  final _topFocus = FocusNode(debugLabel: 'analytics.top', skipTraversal: true);
  bool _sidebarOpen = true;
  _ActiveView _activeView = _ActiveView.daily;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    unawaited(c.reload());
    s.focusRegions
      ..clear()
      ..addAll([_topFocus, _sidebarFocus, _pageFocus]);
    s.driveSearchFocus = _searchFocus;
    s.currentItem.value = null;
    s.currentFolder.value = null;
  }

  @override
  void didUpdateWidget(AnalyticsScreen old) {
    super.didUpdateWidget(old);
    c.setPeriod(widget.days, includeAdmins: widget.includeAdmins);
  }

  @override
  void dispose() {
    s.focusRegions.removeWhere(
      (f) => f == _topFocus || f == _sidebarFocus || f == _pageFocus,
    );
    if (s.driveSearchFocus == _searchFocus) s.driveSearchFocus = null;
    c.dispose();
    _scroll.dispose();
    _pageFocus.dispose();
    _searchFocus.dispose();
    _sidebarFocus.dispose();
    _topFocus.dispose();
    super.dispose();
  }

  void _show({int? days, bool? admins}) => unawaited(
    s.dispatcher.invoke(
      'drive.analytics.show',
      args: {
        'days': days ?? c.days,
        'includeAdmins': admins ?? c.includeAdmins,
      },
      source: InvocationSource.ui,
      context: context,
    ),
  );

  /// Below `md` the left menu is a drawer (Drive 04 §2).
  Future<void> _openDrawer() => showShadSheet<void>(
    context: context,
    side: ShadSheetSide.left,
    barrierLabel: WonkyAppLocalizations.of(context).actionClose,
    builder: (sheetContext) => ShadSheet(
      key: const ValueKey<String>('home.drawer'),
      closeIcon: ShadIconButton.ghost(
        key: const ValueKey<String>('home.drawer.close'),
        width: 32,
        height: 32,
        iconSize: 16,
        semanticLabel: WonkyAppLocalizations.of(sheetContext).actionClose,
        icon: const Icon(LucideIcons.x),
        onPressed: () => Navigator.of(sheetContext).maybePop(),
      ),
      scrollable: false,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(maxWidth: HomeSidebar.width + 8),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: HomeSidebar(
            services: s,
            location: const DriveLocation.home(),
            activeDestination: HomeNavDestination.analytics,
            onNavigate: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 768;
    final sidebarVisible = _sidebarOpen && !narrow;
    return ColoredBox(
      color: theme.colorScheme.background,
      child: KeymapScope(
        scope: KeyScope.drive,
        keymap: s.keymap,
        child: Column(
          children: [
            Focus(
              focusNode: _topFocus,
              child: WonkyTopBar(
                services: s,
                searchFocus: _searchFocus,
                onToggleSidebar: narrow
                    ? _openDrawer
                    : () => setState(() => _sidebarOpen = !_sidebarOpen),
                contentStart: sidebarVisible ? HomeSidebar.width + 20 : null,
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sidebarVisible)
                    Focus(
                      focusNode: _sidebarFocus,
                      child: HomeSidebar(
                        services: s,
                        location: const DriveLocation.home(),
                        activeDestination: HomeNavDestination.analytics,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      key: const ValueKey<String>('analytics.page'),
                      margin: EdgeInsets.only(
                        right: narrow ? 0 : 12,
                        bottom: narrow ? 0 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.card,
                        borderRadius: narrow ? null : BorderRadius.circular(16),
                        border: narrow
                            ? null
                            : Border.all(color: theme.colorScheme.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Focus(
                        focusNode: _pageFocus,
                        child: ListenableBuilder(
                          listenable: c,
                          builder: (context, _) => _content(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l = driveL10n(context);
    final la = WonkyAppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth < 480 ? 12.0 : 24.0;
        final o = c.overview;
        final error = c.error;
        final List<Widget> body;
        if (o == null && error != null) {
          final forbidden =
              error is WonkyException && error.code == WonkyErrorCode.forbidden;
          final offline = isOfflineError(error);
          body = [
            WonkyEmptyState(
              key: ValueKey<String>(
                forbidden ? 'analytics.forbidden' : 'analytics.error',
              ),
              illustration: forbidden
                  ? EmptyIllustration.noAccess
                  : offline
                  ? EmptyIllustration.offline
                  : EmptyIllustration.error,
              title: forbidden
                  ? l.analyticsForbiddenTitle
                  : offline
                  ? l.storageOfflineTitle
                  : l.analyticsErrorTitle,
              description: forbidden
                  ? l.analyticsForbiddenBody
                  : offline
                  ? l.storageOfflineBody
                  : errorMessage(error),
              size: 96,
              actions: [
                if (!forbidden)
                  ShadButton.outline(
                    key: const ValueKey<String>('analytics.retry'),
                    onPressed: () => unawaited(c.reload()),
                    child: Text(la.actionRetry),
                  ),
              ],
            ),
          ];
        } else if (o == null) {
          body = [
            SizedBox(
              height: 220,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: LoadingShimmer.driveList(rows: 4),
                ),
              ),
            ),
          ];
        } else {
          body = _sections(context, o);
        }
        return WonkyScrollArea(
          controller: _scroll,
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(pad, 20, pad, 32),
            children: [_header(context), const SizedBox(height: 18), ...body],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final l = driveL10n(context);
    final f = AnalyticsFormat(context);
    final theme = ShadTheme.of(context);
    final o = c.overview;
    final note = o == null
        ? null
        : [
            l.analyticsUpdated(f.time(o.generatedAt)),
            if (o.trackingSince case final t?)
              if (!t.isBefore(o.series.first.day))
                l.analyticsTrackingSince(f.date(t)),
            if (o.trackingSince == null) l.analyticsNoActivityYet,
          ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            Semantics(
              header: true,
              child: Text(l.analyticsTitle, style: theme.textTheme.h3),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                // Phones choose the period from a select (the tabs need
                // about 460 px).
                if (MediaQuery.sizeOf(context).width < 600)
                  SizedBox(
                    width: 140,
                    child: ShadSelect<int>(
                      key: ValueKey<String>(
                        'analytics.period.select.${c.days}',
                      ),
                      initialValue: c.days,
                      minWidth: 140,
                      options: [
                        for (final d in analyticsPeriods)
                          ShadOption(
                            key: ValueKey<String>('analytics.period.option.$d'),
                            value: d,
                            child: Text(l.analyticsPeriodDays(d)),
                          ),
                      ],
                      selectedOptionBuilder: (context, d) =>
                          Text(l.analyticsPeriodDays(d)),
                      onChanged: (d) {
                        if (d != null) _show(days: d);
                      },
                    ),
                  )
                else
                  ShadTabs<int>(
                    key: const ValueKey<String>('analytics.period'),
                    value: c.days,
                    onChanged: (d) => _show(days: d),
                    tabs: [
                      for (final d in analyticsPeriods)
                        ShadTab(
                          key: ValueKey<String>('analytics.period.$d'),
                          value: d,
                          child: Text(l.analyticsPeriodDays(d)),
                        ),
                    ],
                  ),
                ShadSwitch(
                  key: const ValueKey<String>('analytics.includeAdmins'),
                  value: c.includeAdmins,
                  onChanged: (v) => _show(admins: v),
                  label: Text(l.analyticsIncludeAdmins),
                ),
                ShadIconButton.ghost(
                  key: const ValueKey<String>('analytics.refresh'),
                  width: 32,
                  height: 32,
                  iconSize: 16,
                  semanticLabel: l.analyticsRefresh,
                  icon: c.loading
                      ? const SizedBox.square(
                          dimension: 14,
                          child: ShadProgress(),
                        )
                      : const Icon(LucideIcons.refreshCw),
                  onPressed: c.loading ? null : () => unawaited(c.reload()),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          note ?? l.analyticsSubtitle,
          key: const ValueKey<String>('analytics.note'),
          style: theme.textTheme.muted,
        ),
      ],
    );
  }

  List<Widget> _sections(BuildContext context, AnalyticsOverview o) {
    final l = driveL10n(context);
    final f = AnalyticsFormat(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final b = theme.brightness;
    final ink = AnalyticsColors.ink(cs);
    final accent = AnalyticsColors.accent(b);
    final days = [for (final d in o.series) d.day];
    final dayLabels = [for (final d in days) f.dayTitle(d)];
    final last = o.series.last;
    final created = o.series.fold<int>(
      0,
      (s, d) => s + d.documents + d.spreadsheets + d.presentations + d.files,
    );
    final semantic = l.analyticsChartLabel;

    Widget line(String id, List<AnalyticsSeries> series, {double h = 200}) =>
        AnalyticsLineChart(
          key: ValueKey<String>('analytics.chart.$id'),
          days: days,
          series: series,
          format: f.compact,
          dayLabel: f.day,
          dayTitle: f.dayTitle,
          height: h,
          semanticLabel: semantic(
            [for (final s in series) s.label].join(', '),
            f.day(days.first),
            f.day(days.last),
          ),
        );

    AnalyticsTableData Function() table(List<AnalyticsSeries> series) =>
        () => seriesTable(l.analyticsColDay, dayLabels, series, f.count);

    Widget bars(
      String id,
      List<(String, String, Color, num Function(AnalyticsDay))> measures, {
      double h = 180,
    }) {
      final bk = bucketed(o, f, measures);
      return AnalyticsBarChart(
        key: ValueKey<String>('analytics.chart.$id'),
        starts: bk.starts,
        bucketDays: bk.size,
        series: bk.series,
        format: f.compact,
        dayLabel: f.day,
        bucketTitle: bk.title,
        totalLabel: l.analyticsTotal,
        height: h,
        semanticLabel: semantic(
          [for (final s in bk.series) s.label].join(', '),
          f.day(days.first),
          f.day(days.last),
        ),
      );
    }

    AnalyticsTableData Function() barTable(
      List<(String, String, Color, num Function(AnalyticsDay))> measures,
    ) => () {
      final bk = bucketed(o, f, measures);
      return seriesTable(
        bk.size == 1 ? l.analyticsColDay : l.analyticsColWeek,
        bk.labels,
        bk.series,
        f.count,
      );
    };

    // ---- Active users ----
    final activeSeries = switch (_activeView) {
      _ActiveView.daily => [
        AnalyticsSeries(
          id: 'active',
          label: l.analyticsSeriesActive,
          color: ink,
          area: true,
          values: [for (final d in o.series) d.active.toDouble()],
        ),
        AnalyticsSeries(
          id: 'editors',
          label: l.analyticsSeriesEditors,
          color: accent,
          values: [for (final d in o.series) d.editors.toDouble()],
        ),
      ],
      _ActiveView.weekly => [
        AnalyticsSeries(
          id: 'weekly',
          label: l.analyticsSeriesWeekly,
          color: ink,
          area: true,
          values: [for (final d in o.series) d.weekly.toDouble()],
        ),
      ],
      _ActiveView.monthly => [
        AnalyticsSeries(
          id: 'monthly',
          label: l.analyticsSeriesMonthly,
          color: ink,
          area: true,
          values: [for (final d in o.series) d.monthly.toDouble()],
        ),
      ],
    };
    final appSeries = [
      AnalyticsSeries(
        id: 'drive',
        label: 'Drive',
        color: AnalyticsColors.drive(b),
        values: [for (final d in o.series) d.drive.toDouble()],
      ),
      AnalyticsSeries(
        id: 'write',
        label: 'Write',
        color: AnalyticsColors.write,
        values: [for (final d in o.series) d.write.toDouble()],
      ),
      AnalyticsSeries(
        id: 'sheets',
        label: 'Sheets',
        color: AnalyticsColors.sheets,
        values: [for (final d in o.series) d.sheets.toDouble()],
      ),
      AnalyticsSeries(
        id: 'slides',
        label: 'Slides',
        color: AnalyticsColors.slides,
        values: [for (final d in o.series) d.slides.toDouble()],
      ),
      AnalyticsSeries(
        id: 'mcp',
        label: l.analyticsSeriesMcp,
        color: AnalyticsColors.mcp,
        dashed: true,
        values: [for (final d in o.series) d.mcp.toDouble()],
      ),
    ];
    final collabSeries = [
      AnalyticsSeries(
        id: 'comments',
        label: l.analyticsSeriesComments,
        color: ink,
        values: [for (final d in o.series) d.comments.toDouble()],
      ),
      AnalyticsSeries(
        id: 'shares',
        label: l.analyticsSeriesShares,
        color: accent,
        values: [for (final d in o.series) d.shares.toDouble()],
      ),
    ];
    final kinds = analyticsKinds(context, cs);
    final contentMeasures = [
      for (final (id, label, color) in kinds)
        (
          id,
          label,
          color,
          switch (id) {
            'document' => (AnalyticsDay d) => d.documents,
            'spreadsheet' => (AnalyticsDay d) => d.spreadsheets,
            'presentation' => (AnalyticsDay d) => d.presentations,
            _ => (AnalyticsDay d) => d.files,
          },
        ),
    ];
    final signupMeasures = [
      ('signups', l.analyticsSeriesSignups, ink, (AnalyticsDay d) => d.signups),
    ];
    final aiMeasures = [
      (
        'aiRequests',
        l.analyticsSeriesAiRequests,
        ink,
        (AnalyticsDay d) => d.aiRequests,
      ),
    ];
    final mcpMeasures = [
      (
        'mcpCalls',
        l.analyticsSeriesMcpCalls,
        AnalyticsColors.mcp,
        (AnalyticsDay d) => d.mcpCalls,
      ),
    ];
    final aiTokens = o.series.fold<int>(0, (s, d) => s + d.aiTokens);
    final aiRequests = o.series.fold<int>(0, (s, d) => s + d.aiRequests);
    final mcpCalls = o.series.fold<int>(0, (s, d) => s + d.mcpCalls);
    const gap = SizedBox(height: 12);

    return [
      AnalyticsGrid(
        wide: 3,
        medium: 2,
        narrow: 2,
        children: [
          AnalyticsKpi(
            id: 'accounts',
            label: l.analyticsKpiAccounts,
            value: f.count(o.accounts),
            note: l.analyticsKpiNew(f.count(o.newAccounts), o.days),
            trend: [for (final d in o.series) d.accounts.toDouble()],
          ),
          AnalyticsKpi(
            id: 'today',
            label: l.analyticsKpiToday,
            value: f.count(o.activeToday),
            note: l.analyticsKpiEditorsToday(f.count(last.editors)),
            trend: [for (final d in o.series) d.active.toDouble()],
          ),
          AnalyticsKpi(
            id: 'weekly',
            label: l.analyticsKpiWeekly,
            value: f.count(o.weekly),
            note: l.analyticsKpiWeeklyNote,
            trend: [for (final d in o.series) d.weekly.toDouble()],
          ),
          AnalyticsKpi(
            id: 'monthly',
            label: l.analyticsKpiMonthly,
            value: f.count(o.monthly),
            note: l.analyticsKpiMonthlyNote,
            trend: [for (final d in o.series) d.monthly.toDouble()],
          ),
          AnalyticsKpi(
            id: 'stickiness',
            label: l.analyticsKpiStickiness,
            value: f.percent(o.stickiness),
            note: l.analyticsKpiStickinessNote,
          ),
          AnalyticsKpi(
            id: 'created',
            label: l.analyticsKpiCreated,
            value: f.count(created),
            note: l.analyticsKpiInPeriod(o.days),
          ),
        ],
      ),
      const SizedBox(height: 20),
      AnalyticsCard(
        id: 'active',
        title: l.analyticsActiveTitle,
        subtitle: l.analyticsActiveSubtitle,
        actions: [
          ShadTabs<_ActiveView>(
            key: const ValueKey<String>('analytics.active.view'),
            // Scrolls instead of overflowing on phones.
            scrollable: true,
            value: _activeView,
            onChanged: (v) => setState(() => _activeView = v),
            tabs: [
              for (final v in _ActiveView.values)
                ShadTab(
                  key: ValueKey<String>('analytics.active.view.${v.name}'),
                  value: v,
                  child: Text(switch (v) {
                    _ActiveView.daily => l.analyticsViewDaily,
                    _ActiveView.weekly => l.analyticsViewWeekly,
                    _ActiveView.monthly => l.analyticsViewMonthly,
                  }),
                ),
            ],
          ),
        ],
        chart: line('active.${_activeView.name}', activeSeries, h: 240),
        table: table(activeSeries),
      ),
      gap,
      AnalyticsCard(
        id: 'apps',
        title: l.analyticsAppsTitle,
        subtitle: l.analyticsAppsSubtitle,
        chart: line('apps', appSeries),
        table: table(appSeries),
      ),
      gap,
      AnalyticsGrid(
        wide: 2,
        medium: 1,
        children: [
          AnalyticsCard(
            id: 'signups',
            title: l.analyticsSignupsTitle,
            subtitle: l.analyticsSignupsSubtitle(
              f.count(o.newAccounts),
              f.count(o.accounts),
            ),
            chart: bars('signups', signupMeasures),
            table: barTable(signupMeasures),
          ),
          AnalyticsCard(
            id: 'mix',
            title: l.analyticsContentNowTitle,
            chart: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnalyticsContentNow(overview: o),
                const SizedBox(height: 22),
                Text(l.analyticsSignInTitle, style: theme.textTheme.small),
                const SizedBox(height: 10),
                AnalyticsSignInMethods(overview: o),
              ],
            ),
          ),
        ],
      ),
      gap,
      AnalyticsCard(
        id: 'content',
        title: l.analyticsContentTitle,
        subtitle: l.analyticsContentSubtitle,
        chart: bars('content', contentMeasures, h: 200),
        table: barTable(contentMeasures),
      ),
      gap,
      AnalyticsCard(
        id: 'collaboration',
        title: l.analyticsCollabTitle,
        chart: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnalyticsStatRow(
              stats: [
                ('shared', l.analyticsStatShared, f.count(o.sharedItems)),
                (
                  'coEdited',
                  l.analyticsStatCoEdited(o.days),
                  f.count(o.coEditedItems),
                ),
                (
                  'commenters',
                  l.analyticsStatCommenters(o.days),
                  f.count(o.commenters),
                ),
              ],
            ),
            const SizedBox(height: 16),
            line('collaboration', collabSeries, h: 180),
          ],
        ),
        table: table(collabSeries),
      ),
      gap,
      AnalyticsCard(
        id: 'ai',
        title: l.analyticsAiTitle,
        subtitle: l.analyticsAiSubtitle(
          f.count(aiRequests),
          f.compact(aiTokens),
          o.aiRetentionDays,
        ),
        chart: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bars('ai', aiMeasures, h: 160),
            const SizedBox(height: 18),
            AnalyticsGrid(
              wide: 2,
              medium: 2,
              gap: 24,
              children: [
                _rank(
                  context,
                  'feature',
                  l.analyticsAiByFeature,
                  o.aiFeatures,
                  f,
                ),
                _rank(context, 'model', l.analyticsAiByModel, o.aiModels, f),
              ],
            ),
          ],
        ),
        table: barTable(aiMeasures),
      ),
      gap,
      AnalyticsCard(
        id: 'mcp',
        title: l.analyticsMcpTitle,
        subtitle: l.analyticsMcpSubtitle(f.count(mcpCalls)),
        chart: bars('mcp', mcpMeasures, h: 160),
        table: barTable(mcpMeasures),
      ),
      gap,
      AnalyticsCard(
        id: 'retention',
        title: l.analyticsRetentionTitle,
        subtitle: l.analyticsRetentionSubtitle,
        chart: AnalyticsCohortGrid(cohorts: o.cohorts),
      ),
    ];
  }

  Widget _rank(
    BuildContext context,
    String id,
    String title,
    List<AnalyticsCount> counts,
    AnalyticsFormat f,
  ) {
    final l = driveL10n(context);
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.small),
        const SizedBox(height: 10),
        if (counts.isEmpty)
          Text(l.analyticsNoAiUse, style: theme.textTheme.muted)
        else
          AnalyticsRankBars(
            keyPrefix: 'analytics.ai.$id',
            color: AnalyticsColors.ink(theme.colorScheme),
            rows: [
              for (final c in counts)
                (
                  c.key,
                  c.count.toDouble(),
                  l.analyticsAiRow(f.count(c.count), f.compact(c.amount)),
                ),
            ],
          ),
      ],
    );
  }
}

/// `/analytics?days=…&admins=1` → [AnalyticsScreen] (registered by
/// `DriveAppConfig`).
Widget analyticsRoutePage(ShellServices services, Uri uri) => AnalyticsScreen(
  services: services,
  days: parseAnalyticsDays(uri.queryParameters['days']),
  includeAdmins: uri.queryParameters['admins'] == '1',
);
