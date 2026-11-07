import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_charts/wonky_charts.dart';
import 'package:wonky_slides_core/charts.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;

import '../../../l10n/slides_l10n.dart';
import '../../editor_screen/deck_editor_controller.dart';
import '../../present/active_presentation.dart';
import 'chart_api.dart';

/// The last known state of one linked chart (08 §5.4): a `checkLinks`
/// status, or a local one (no snapshot yet, offline).
@immutable
class ChartLinkInfo {
  const ChartLinkInfo({
    required this.elementId,
    this.status,
    this.summary,
    this.newVersion,
    this.checkedAt,
  });

  final String elementId;

  /// null: not checked yet.
  final ChartLinkStatusCode? status;

  /// "Data changed" … (server English; shown in the tooltip).
  final String? summary;
  final String? newVersion;
  final DateTime? checkedAt;

  bool get changed => status == ChartLinkStatusCode.changed;
}

/// The linked charts of an open deck (Slides 08 §5): checks their sources
/// with `slidesCharts.checkLinks` when the deck opens, when the window comes
/// back after ≥ 60 s, every 5 minutes while online, once when presenting
/// starts (updates are never applied on stage; a toast offers them after),
/// and on *Check for updates*.
///
/// Editors also write the maintenance updates of 08 §5.2/§5.5 (no undo
/// step): newer tokens of unchanged charts, the snapshots of charts with
/// *Update automatically* (toast "Charts updated from …"), and the first
/// snapshot of links pasted without data. Viewers only cache statuses.
class ChartLinks extends ChangeNotifier {
  ChartLinks._(this.editor);

  static final Expando<ChartLinks> _registry = Expando('slidesChartLinks');

  /// The linked charts of [ed].
  static ChartLinks of(DeckEditorController ed) =>
      _registry[ed] ??= ChartLinks._(ed);

  /// The instance of [ed] if it exists.
  static ChartLinks? maybeOf(DeckEditorController ed) => _registry[ed];

  /// How often an open deck re-checks while online (08 §5.3).
  static Duration period = const Duration(minutes: 5);

  /// How long the window must have been away before a resume re-checks.
  static const resumeAfter = Duration(seconds: 60);

  final DeckEditorController editor;

  SlidesChartApi get api => SlidesChartApi.of(editor.services);

  final Map<String, ChartLinkInfo> _info = {};
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  DateTime? _hiddenAt;
  DateTime? _lastCheck;
  bool _checking = false;
  bool _started = false;
  bool _wasPresenting = false;
  Future<void>? _running;

  /// Whether a check is running.
  bool get checking => _checking;

  /// When the last check finished.
  DateTime? get lastCheck => _lastCheck;

  /// Whether the server can be reached now.
  bool get online => api.online;

  /// The last known state of the linked chart [elementId].
  ChartLinkInfo? infoOf(String elementId) => _info[elementId];

  /// The status of the linked chart [elementId] now (null: not checked):
  /// the last check compared with the snapshot the deck holds, so an undone
  /// *Update* shows *Update* again and a collaborator's update clears it.
  ChartLinkStatusCode? statusOf(String elementId) {
    final i = _info[elementId];
    if (i == null) return null;
    final link = editor.model.chartLinkOf(elementId);
    final current = i.newVersion;
    if (link == null ||
        current == null ||
        (i.status != ChartLinkStatusCode.upToDate &&
            i.status != ChartLinkStatusCode.changed)) {
      return i.status;
    }
    if (link.sourceVersion == current) return ChartLinkStatusCode.upToDate;
    final a = ChartSourceVersion.tryParse(link.sourceVersion);
    final b = ChartSourceVersion.tryParse(current);
    return a != null && b != null && a.sameChartAs(b)
        ? ChartLinkStatusCode.upToDate
        : ChartLinkStatusCode.changed;
  }

  /// The linked charts whose source changed.
  List<String> get changedIds => [
    for (final e in _info.values)
      if (_linked(e.elementId) &&
          statusOf(e.elementId) == ChartLinkStatusCode.changed)
        e.elementId,
  ];

  bool _linked(String id) {
    final e = editor.model.element(id);
    return e != null &&
        e.kind == ElementKind.chart &&
        ChartElementData.fromJson(e.dataJson).source ==
            SlideChartSource.linked &&
        editor.model.chartLinkOf(id) != null;
  }

  /// Starts the periodic checks (the canvas calls it; idempotent).
  void start() {
    // A guest (signed out) can't check links: the charts show their
    // stored snapshots (specs/06 §2.4).
    if (_started || editor.services.isGuest) return;
    _started = true;
    _ensureTimer();
    editor.services.connectivity.addListener(_onConnectivity);
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt = clock.now(),
      onShow: _resumed,
      onResume: _resumed,
    );
    activePresentation.addListener(_onPresent);
    editor.session.loadState.addListener(_onLoad);
    _onLoad();
  }

  /// Stops the periodic checks.
  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    editor.services.connectivity.removeListener(_onConnectivity);
    _lifecycle?.dispose();
    _lifecycle = null;
    activePresentation.removeListener(_onPresent);
    editor.session.loadState.removeListener(_onLoad);
  }

  bool _loadedOnce = false;
  bool _wasOnline = true;

  /// The 5-minute timer runs while the deck has links and the server is
  /// reachable.
  void _ensureTimer() {
    if (!_started || _timer != null || !online || !_hasLinks) return;
    _timer = Timer.periodic(period, (_) {
      if (!online) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      unawaited(check());
    });
  }

  void _onConnectivity() {
    final now = online;
    if (now && !_wasOnline && _hasLinks) unawaited(check());
    _wasOnline = now;
    if (now) _ensureTimer();
  }

  void _onLoad() {
    if (_loadedOnce || !editor.isReady) return;
    _loadedOnce = true;
    if (_hasLinks) unawaited(check());
  }

  bool get _hasLinks => editor.model.records(SlidesTables.chartLink).isNotEmpty;

  void _resumed() {
    final at = _hiddenAt;
    _hiddenAt = null;
    if (at == null || clock.now().difference(at) < resumeAfter) return;
    if (online && _hasLinks) unawaited(check());
  }

  bool get _presenting => activePresentation.value != null;

  void _onPresent() {
    final now = _presenting;
    if (now == _wasPresenting) return;
    _wasPresenting = now;
    if (now) {
      // Checked once at the start; nothing is applied on stage.
      if (online && _hasLinks) unawaited(check());
      return;
    }
    final n = changedIds.length;
    if (n == 0 || !editor.canEdit) return;
    final l = slidesL10nOf(editor.services);
    editor.services.toasts.show(
      l.chartNewerDataToast(n),
      actionLabel: l.chartUpdateAction,
      onAction: () => unawaited(
        editor.invokeCommand('slides.chart.update', const {'all': true}),
      ),
    );
  }

  /// Checks every linked chart of the deck now (08 §5.2) and applies the
  /// editor's maintenance writes. Concurrent calls share one run.
  Future<void> check() => _running ??= _check().whenComplete(() {
    _running = null;
  });

  Future<void> _check() async {
    if (!online) return;
    _checking = true;
    notifyListeners();
    try {
      await _fillPlaceholders();
      final probes = ChartLinkOps.probesOf(editor.model);
      if (probes.isEmpty) return;
      final statuses = await api.check(probes);
      final now = clock.now();
      for (final s in statuses) {
        _info[s.elementId] = ChartLinkInfo(
          elementId: s.elementId,
          status: s.status,
          summary: s.summary,
          newVersion: s.newVersion,
          checkedAt: now,
        );
      }
      _lastCheck = now;
      await _maintain(statuses);
      _ensureTimer();
    } on ChartApiException {
      // Offline or failed: the last known statuses stay.
    } finally {
      _checking = false;
      if (_started || hasListeners) notifyListeners();
    }
  }

  bool get _maintains => editor.roleCanEdit && editor.isReady;

  /// Token refreshes and auto-updates (maintenance writes, 08 §5.2, §5.5).
  Future<void> _maintain(List<ChartLinkStatusData> statuses) async {
    if (!_maintains) return;
    final updated = <String>{};
    for (final s in statuses) {
      final link = editor.model.chartLinkOf(s.elementId);
      if (link == null) continue;
      final v = s.newVersion;
      if (s.status == ChartLinkStatusCode.upToDate &&
          v != null &&
          v != link.sourceVersion) {
        _write(ChartLinkOps.refreshToken(link, v));
      } else if (s.status == ChartLinkStatusCode.changed &&
          link.autoUpdate &&
          !_presenting) {
        try {
          final r = await api.resolve(
            link.spreadsheetItemUuid,
            link.chartObjectId,
          );
          if (editor.model.chartLinkOf(s.elementId) == null) continue;
          willUpdate?.call(s.elementId);
          _write(ChartLinkOps.update(s.elementId, r));
          markUpToDate(s.elementId, r.sourceVersion);
          final title = ChartSourceSnapshot.fromColumns(
            r.sourceSpecJson,
            r.dataSnapshotJson,
          ).dataSnapshot.source.spreadsheetTitle;
          updated.add(title);
        } on ChartApiException {
          continue;
        }
      }
    }
    if (updated.isNotEmpty) {
      final l = slidesL10nOf(editor.services);
      editor.services.toasts.show(
        l.chartAutoUpdatedToast(updated.where((t) => t.isNotEmpty).join(', ')),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Links pasted before their first snapshot get one (maintenance write:
  /// the paste was the undo step).
  Future<void> _fillPlaceholders() async {
    if (!_maintains) return;
    for (final r in editor.model.records(SlidesTables.chartLink).toList()) {
      if (r is! ChartLinkRec) continue;
      final id = r.elementId;
      if (id == null || !_linked(id)) continue;
      final snap = ChartDataSnapshot.fromJson(
        ChartSnapshotColumns.decode(r.dataSnapshotJson),
      );
      if (!snap.isPlaceholder) continue;
      try {
        final s = await api.resolve(r.spreadsheetItemUuid, r.chartObjectId);
        if (editor.model.chartLinkOf(id) == null) continue;
        _write(ChartLinkOps.update(id, s));
        markUpToDate(id, s.sourceVersion);
      } on ChartApiException catch (e) {
        _info[id] = ChartLinkInfo(
          elementId: id,
          status: _statusOf(e.error),
          checkedAt: clock.now(),
        );
      }
    }
  }

  static ChartLinkStatusCode? _statusOf(ChartApiError e) => switch (e) {
    ChartApiError.noAccess => ChartLinkStatusCode.noAccess,
    ChartApiError.spreadsheetTrashed => ChartLinkStatusCode.spreadsheetTrashed,
    ChartApiError.exportDisabled => ChartLinkStatusCode.exportDisabled,
    ChartApiError.chartNotFound => ChartLinkStatusCode.chartDeleted,
    ChartApiError.unsupportedSpec => ChartLinkStatusCode.unsupportedSpec,
    _ => null,
  };

  /// The status of a failed resolve (an *Update* that found the source
  /// gone), recorded for the badge.
  void markFailed(String elementId, ChartApiError error) {
    final s = _statusOf(error);
    if (s == null) return;
    _info[elementId] = ChartLinkInfo(
      elementId: elementId,
      status: s,
      checkedAt: clock.now(),
    );
    notifyListeners();
  }

  /// Records that [elementId] now shows [version] (after an update).
  void markUpToDate(String elementId, String version) {
    _info[elementId] = ChartLinkInfo(
      elementId: elementId,
      status: ChartLinkStatusCode.upToDate,
      newVersion: version,
      checkedAt: clock.now(),
    );
    notifyListeners();
  }

  /// Called before an update replaces a chart's snapshot (the canvas
  /// morphs from the old scene, 08 §9.4).
  void Function(String elementId)? willUpdate;

  void _write(SlidesOperation op) {
    try {
      editor.session.execute(op);
    } on PlanException {
      // The link changed meanwhile (unlinked, deleted): nothing to keep.
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
