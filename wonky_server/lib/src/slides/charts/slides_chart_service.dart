import 'dart:collection';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart' hide EmbeddedObjectKind;
import '../../platform/sharing/access_service.dart';
import '../../sheets/headless/headless_workbook.dart';
import '../../sheets/headless/headless_workbook_provider.dart';

/// Linked charts from Sheets in Slides (Slides 08 §5, §6, §13): lists the charts of a
/// spreadsheet, resolves snapshots and checks links. Resolution runs in the cached headless
/// workbook of the spreadsheet (`HeadlessWorkbookProvider`) with the Sheets chart data
/// resolver; snapshots contain only the chart's resolved series (08 §6).
///
/// **Access** (08 §6): the caller needs a role on the spreadsheet (no role → `notFound`, so
/// ids don't leak) and, to copy data, editor+ or `nonEditorsCanExport`. Trashed
/// spreadsheets can't be resolved. Errors carry `detailsJson = {"reason": …}` with the codes
/// of 08 §4.3 (`no_access`, `export_disabled`, `chart_not_found`, `chart_too_large`,
/// `unsupported_spec`, `spreadsheet_trashed`).
///
/// **Version token** (08 §5.1): `<changeLog>:<specHash>:<dataVersion>` where `<changeLog>`
/// is `<newest ChangeLog id>.<ChangeLog row count>` of the spreadsheet (the count also
/// catches offline changes merged with older timestamps); `checkLinks` compares only that
/// marker when it is unchanged and resolves the chart otherwise. Current tokens are cached per
/// `(spreadsheet, chart)` and marker; resolved snapshots per token for [snapshotTtl].
abstract final class SlidesChartService {
  /// Probes per `checkLinks` call.
  static const maxProbes = 50;

  /// Charts per `listCharts` result.
  static const maxCharts = 100;

  /// Per-user call limits per minute (08 §13; tests lower them).
  static int resolvesPerMinute = 60;
  static int checksPerMinute = 30;
  static int listsPerMinute = 30;

  /// Largest compressed data snapshot (08 §3.4).
  static int maxSnapshotBytes = ChartSnapshotColumns.maxCompressedBytes;

  /// How long resolved snapshots stay cached.
  static Duration snapshotTtl = const Duration(minutes: 10);

  static const _maxCached = 200;

  /// `(space|chart)` → (marker, token).
  static final LinkedHashMap<String, (String, String)> _tokens =
      LinkedHashMap();

  /// `space|chart|token` → snapshot.
  static final LinkedHashMap<String, (DateTime, ChartSnapshotView)> _snapshots =
      LinkedHashMap();

  static final Map<String, List<DateTime>> _calls = {};

  /// Number of chart resolutions (tests: cache hits don't resolve).
  static int resolves = 0;

  /// Clears caches and rate-limit windows (tests).
  static void reset() {
    _tokens.clear();
    _snapshots.clear();
    _calls.clear();
    resolves = 0;
  }

  // ---------------------------------------------------------------- calls

  /// The charts of [spreadsheetUuid] with previews (08 §4.2). Viewer+; without the right to
  /// copy data, previews are left out and `exportAllowed` is false.
  static Future<ChartSourceList> listCharts(
    Session session,
    Actor actor,
    UuidValue spreadsheetUuid,
  ) async {
    _rateLimit(actor, 'list', listsPerMinute);
    final (item, role) = await _requireSpreadsheet(
      session,
      actor,
      spreadsheetUuid,
    );
    final exportAllowed = _canExport(item, role);
    final wb = await HeadlessWorkbookProvider.open(session, item.contentRef!);
    final charts = <ChartSourceSummary>[];
    for (final (sheet, rec) in _charts(wb)) {
      if (charts.length >= maxCharts) break;
      final spec = ChartSpec.fromJson(rec.specJson);
      String? preview;
      if (exportAllowed && !spec.isFromNewerVersion) {
        final data = ChartSnapshotLimits.preview.apply(
          spec,
          _resolve(wb, spec),
        );
        preview = jsonEncode(
          ChartSourceSnapshot(
            spec: spec,
            dataSnapshot: _dataSnapshot(item, wb, sheet, rec, spec, data, ''),
          ).toJson(),
        );
      }
      charts.add(
        ChartSourceSummary(
          chartObjectId: rec.id,
          title: _title(rec, spec),
          type: spec.typeId,
          is3D: spec.threeD.appliesTo(spec.type),
          sheetName: sheet.name,
          onChartSheet:
              ObjectAnchor.tryParse(rec.anchorJson)?.ownSheet ?? false,
          unsupported: spec.isFromNewerVersion,
          previewSnapshotJson: preview,
        ),
      );
    }
    return ChartSourceList(
      spreadsheetTitle: item.name,
      charts: charts,
      exportAllowed: exportAllowed,
    );
  }

  /// The full snapshot of chart [chartObjectId] (08 §3.3–§3.4).
  static Future<ChartSnapshotView> resolveSnapshot(
    Session session,
    Actor actor,
    UuidValue spreadsheetUuid,
    String chartObjectId,
  ) async {
    _rateLimit(actor, 'resolve', resolvesPerMinute);
    final (item, role) = await _requireSpreadsheet(
      session,
      actor,
      spreadsheetUuid,
    );
    if (!_canExport(item, role)) {
      throw _error(
        Errors.forbidden(
          "The owner doesn't allow viewers to copy charts from this "
          'spreadsheet.',
        ),
        'export_disabled',
      );
    }
    final space = item.contentRef!;
    final marker = await _changeLogMarker(session, space);
    final tokenKey = '${space.uuid}|$chartObjectId';
    final known = _tokens[tokenKey];
    if (known != null && known.$1 == marker) {
      final hit = _snapshots['$tokenKey|${known.$2}'];
      if (hit != null && clock.now().difference(hit.$1) < snapshotTtl) {
        return hit.$2;
      }
    }
    final wb = await HeadlessWorkbookProvider.open(session, space);
    final found = _chart(wb, chartObjectId);
    if (found == null) {
      throw _error(
        Errors.notFound('Chart'),
        'chart_not_found',
        'This chart was deleted. Pick another one.',
      );
    }
    final (sheet, rec) = found;
    final spec = ChartSpec.fromJson(rec.specJson);
    if (spec.isFromNewerVersion) {
      throw _error(
        Errors.invalid('Unsupported chart.'),
        'unsupported_spec',
        'This chart was made with a newer version of Wonky Sheets. Reload to '
            'insert it.',
      );
    }
    final full = _resolve(wb, spec);
    final data = const ChartSnapshotLimits().apply(spec, full);
    final token = _token(marker, spec, full);
    final dataJson = _dataSnapshot(
      item,
      wb,
      sheet,
      rec,
      spec,
      data,
      token,
    ).encode();
    if (dataJson.length > maxSnapshotBytes &&
        ChartSnapshotColumns.compressedSize(dataJson) > maxSnapshotBytes) {
      throw _error(
        Errors.tooLarge('Chart too large.'),
        'chart_too_large',
        'This chart has too much data to place in a presentation. Reduce its '
            'range in Sheets.',
      );
    }
    final view = ChartSnapshotView(
      spreadsheetUuid: item.uuid,
      chartObjectId: chartObjectId,
      sheetId: sheet.id,
      sourceSpecJson: spec.encode(),
      dataSnapshotJson: dataJson,
      sourceVersion: token,
      updatedAt: clock.now().toUtc(),
      warnings: [for (final w in data.warnings) w.message],
    );
    _remember(_tokens, tokenKey, (marker, token));
    _remember(_snapshots, '$tokenKey|$token', (clock.now(), view));
    return view;
  }

  /// The status of each probe (08 §5.2), in order. Spreadsheets the caller can't read give
  /// status codes only.
  static Future<List<ChartLinkStatus>> checkLinks(
    Session session,
    Actor actor,
    List<ChartLinkProbe> probes,
  ) async {
    if (probes.length > maxProbes) {
      throw Errors.invalid('At most $maxProbes links per call.');
    }
    _rateLimit(actor, 'check', checksPerMinute);
    final bySheet = <String, List<int>>{};
    for (final (i, p) in probes.indexed) {
      (bySheet[p.spreadsheetUuid.uuid] ??= []).add(i);
    }
    final out = List<ChartLinkStatus?>.filled(probes.length, null);
    for (final entry in bySheet.entries) {
      final first = probes[entry.value.first];
      ChartLinkStatus status(ChartLinkProbe p, ChartLinkState s) =>
          ChartLinkStatus(elementId: p.elementId, status: s);
      final item = await _findSpreadsheet(session, first.spreadsheetUuid);
      if (item == null) {
        for (final i in entry.value) {
          out[i] = status(probes[i], ChartLinkState.spreadsheetDeleted);
        }
        continue;
      }
      final role = await AccessService.effectiveRole(
        session,
        actor.userId,
        item,
      );
      final ChartLinkState? denied = role == null
          ? ChartLinkState.noAccess
          : item.trashedAt != null
          ? ChartLinkState.spreadsheetTrashed
          : !_canExport(item, role)
          ? ChartLinkState.exportDisabled
          : null;
      if (denied != null) {
        for (final i in entry.value) {
          out[i] = status(probes[i], denied);
        }
        continue;
      }
      final space = item.contentRef!;
      final marker = await _changeLogMarker(session, space);
      HeadlessWorkbook? wb;
      for (final i in entry.value) {
        final p = probes[i];
        final have = ChartSourceVersion.tryParse(p.sourceVersion);
        if (have != null && have.changeLog == marker) {
          out[i] = status(p, ChartLinkState.upToDate);
          continue;
        }
        final tokenKey = '${space.uuid}|${p.chartObjectId}';
        var token = _tokens[tokenKey]?.$1 == marker
            ? _tokens[tokenKey]!.$2
            : null;
        if (token == null) {
          wb ??= await HeadlessWorkbookProvider.open(session, space);
          final found = _chart(wb, p.chartObjectId);
          if (found == null) {
            out[i] = status(p, ChartLinkState.chartDeleted);
            continue;
          }
          final spec = ChartSpec.fromJson(found.$2.specJson);
          if (spec.isFromNewerVersion) {
            out[i] = status(p, ChartLinkState.unsupportedSpec);
            continue;
          }
          token = _token(marker, spec, _resolve(wb, spec));
          _remember(_tokens, tokenKey, (marker, token));
        }
        final now = ChartSourceVersion.tryParse(token)!;
        if (have != null && have.sameChartAs(now)) {
          out[i] = ChartLinkStatus(
            elementId: p.elementId,
            status: ChartLinkState.upToDate,
            newVersion: token,
          );
        } else {
          final dataChanged =
              have == null || have.dataVersion != now.dataVersion;
          final specChanged = have == null || have.specHash != now.specHash;
          out[i] = ChartLinkStatus(
            elementId: p.elementId,
            status: ChartLinkState.changed,
            newVersion: token,
            summary: dataChanged && specChanged
                ? 'Data and style changed'
                : dataChanged
                ? 'Data changed'
                : 'Chart style changed',
          );
        }
      }
    }
    return [for (final s in out) s!];
  }

  // -------------------------------------------------------------- helpers

  static WonkyException _error(
    WonkyException e,
    String reason, [
    String? message,
  ]) => WonkyException(
    code: e.code,
    message: message ?? e.message,
    detailsJson: jsonEncode({'reason': reason}),
  );

  static Future<DriveItem?> _findSpreadsheet(
    Session session,
    UuidValue uuid,
  ) async {
    final item =
        await AccessService.findItem(session, uuid) ??
        await DriveItem.db.findFirstRow(
          session,
          where: (t) =>
              t.contentRef.equals(uuid) &
              t.kind.equals(DriveItemKind.spreadsheet),
        );
    if (item == null ||
        item.kind != DriveItemKind.spreadsheet ||
        item.contentRef == null) {
      return null;
    }
    return item;
  }

  static Future<(DriveItem, Role)> _requireSpreadsheet(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final item = await _findSpreadsheet(session, uuid);
    final role = item == null
        ? null
        : await AccessService.effectiveRole(session, actor.userId, item);
    if (item == null || role == null) {
      throw _error(
        Errors.notFound('Spreadsheet'),
        'no_access',
        "You don't have access to this spreadsheet anymore.",
      );
    }
    if (item.trashedAt != null) {
      throw _error(
        Errors.notFound('Spreadsheet'),
        'spreadsheet_trashed',
        'This spreadsheet is in the trash.',
      );
    }
    return (item, role);
  }

  static bool _canExport(DriveItem item, Role role) =>
      role >= Role.editor || item.nonEditorsCanExport;

  static void _rateLimit(Actor actor, String kind, int perMinute) {
    final key = '${actor.userId}|$kind';
    final now = clock.now();
    final list = _calls[key] ??= [];
    list.removeWhere((t) => now.difference(t) >= const Duration(minutes: 1));
    if (list.length >= perMinute) {
      throw Errors.limit('Too many chart requests. Try again in a minute.');
    }
    list.add(now);
  }

  static void _remember<V>(LinkedHashMap<String, V> map, String key, V value) {
    map.remove(key);
    map[key] = value;
    while (map.length > _maxCached) {
      map.remove(map.keys.first);
    }
  }

  /// The spreadsheet's head revision (RevLog), empty without a file: it
  /// changes with every committed change of the spreadsheet.
  static Future<String> _changeLogMarker(
    Session session,
    UuidValue space,
  ) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(space),
    );
    return file == null ? '' : 'r${file.headRevision}';
  }

  static String _token(String marker, ChartSpec spec, ChartData data) {
    final hash = sha256
        .convert(utf8.encode(spec.encode()))
        .toString()
        .substring(0, 16);
    return ChartSourceVersion(
      changeLog: marker,
      specHash: hash,
      dataVersion: '${data.dataVersion}',
    ).toString();
  }

  static Iterable<(SheetModel, EmbeddedObjectRecord)> _charts(
    HeadlessWorkbook wb,
  ) sync* {
    for (final s in wb.model.sheets) {
      for (final o in s.objects.values) {
        if (o.kind == EmbeddedObjectKind.chart) yield (s, o);
      }
    }
  }

  static (SheetModel, EmbeddedObjectRecord)? _chart(
    HeadlessWorkbook wb,
    String id,
  ) {
    for (final s in wb.model.sheets) {
      final o = s.objects[id];
      if (o != null && o.kind == EmbeddedObjectKind.chart) return (s, o);
    }
    return null;
  }

  static ChartData _resolve(HeadlessWorkbook wb, ChartSpec spec) =>
      ChartDataResolver.resolve(spec, wb.model, wb.engine, locale: wb.locale);

  static String _title(EmbeddedObjectRecord rec, ChartSpec spec) {
    final t = spec.title.text.trim();
    if (t.isNotEmpty) return t;
    return (rec.title ?? '').trim();
  }

  static ChartDataSnapshot _dataSnapshot(
    DriveItem item,
    HeadlessWorkbook wb,
    SheetModel sheet,
    EmbeddedObjectRecord rec,
    ChartSpec spec,
    ChartData data,
    String token,
  ) {
    final theme = wb.model.theme;
    return ChartDataSnapshot(
      data: data,
      sourceTheme: ChartSourceTheme.of(theme, colors: theme.colors),
      locale: wb.locale,
      source: ChartSourceInfo(
        spreadsheetTitle: item.name,
        sheetName: sheet.name,
        chartTitle: _title(rec, spec),
        rangesA1: [
          for (final g in spec.data.gridRanges)
            if (wb.model.resolve(g) case final ResolvedRange r)
              wb.model.a1Of(r),
        ],
      ),
      version: token,
    );
  }
}
