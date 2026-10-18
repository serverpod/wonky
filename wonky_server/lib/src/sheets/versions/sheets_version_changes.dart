import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/model.dart'
    show ChangeSummary, SheetsTables, SnapshotDiff, SnapshotDiffer;

import '../../platform/common/models.dart';

/// One changed range of a version with its author (Sheets 10 §5.1.2
/// `SheetsSnapshotIndex.changedRangesJson`, §5.2 author attribution).
typedef AuthoredRange = ({Map<String, Object?> range, int userId, DateTime at});

/// The ops between two captures: revisions (`fromRevision`,
/// `toRevision`] when both versions recorded their file revision, else the
/// commit times (`from`, `to`] (versions captured before RevLog).
typedef VersionWindow = ({
  int? fromRevision,
  int? toRevision,
  DateTime? from,
  DateTime to,
});

/// The changes between two version captures (Sheets 10 §5.1.2, §5.2): the
/// RevLog ops committed between the captures' file revisions, their ranges
/// (op summaries) with authors, and per-cell attribution of snapshot diffs.
/// Offline edits that synced later belong to the version whose window
/// contains their commit.
abstract final class SheetsVersionChanges {
  /// Max ranges kept in `changedRangesJson` (then `approx: true`).
  static const maxRanges = 1000;

  /// Max ops read for one window (then `approx: true`).
  static const maxOps = 20000;

  /// The authored ranges of the ops of [space] in [window], oldest first,
  /// capped at [maxRanges] (the second value tells whether ranges were
  /// dropped).
  static Future<(List<AuthoredRange>, bool)> rangesBetween(
    Session session,
    UuidValue space,
    VersionWindow window,
  ) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(space),
    );
    if (file == null) return (const <AuthoredRange>[], false);
    final toRevision = window.toRevision;
    final fromRevision = window.fromRevision;
    final from = window.from;
    final logs = await RevOp.db.find(
      session,
      where: (t) => toRevision != null
          ? t.fileId.equals(file.id!) &
                (fromRevision == null
                    ? Constant.bool(true)
                    : t.revision > fromRevision) &
                (t.revision <= toRevision)
          : t.fileId.equals(file.id!) &
                (from == null ? Constant.bool(true) : t.committedAt > from) &
                (t.committedAt <= window.to),
      orderBy: (t) => t.revision,
      limit: maxOps,
    );
    if (logs.isEmpty) return (const <AuthoredRange>[], false);
    final profiles = await UserProfile.db.find(
      session,
      where: (t) => t.authUserId.inSet({for (final l in logs) ?l.authorUuid}),
    );
    final byAuth = {for (final p in profiles) p.authUserId.uuid: p.id!};
    final out = <AuthoredRange>[];
    var approx = logs.length >= maxOps;
    for (final l in logs) {
      final user = byAuth[l.authorUuid?.uuid];
      if (user == null || l.summaryJson == null) continue;
      ChangeSummary s;
      try {
        s = ChangeSummary.parse(l.summaryJson!);
      } on Object {
        continue;
      }
      for (final r in s.ranges) {
        if (out.length >= maxRanges) {
          approx = true;
          break;
        }
        out.add((range: r, userId: user, at: l.committedAt));
      }
    }
    return (out, approx);
  }

  /// `changedRangesJson`: `{v, approx, ranges: [{s, r1, c1, r2, c2, u}]}`
  /// (oldest first, later ranges win in attribution).
  static String encode(List<AuthoredRange> ranges, {bool approx = false}) =>
      jsonEncode({
        'v': 1,
        'approx': approx,
        'ranges': [
          for (final r in ranges) {...r.range, 'u': r.userId},
        ],
      });

  /// The capture window of [version]: from the previous version of its
  /// item (exclusive) to its own capture.
  static Future<VersionWindow> windowOf(
    Session session,
    ItemVersion version,
  ) async {
    final prev = await ItemVersion.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(version.itemId) & (t.id < version.id!),
      orderBy: (t) => t.id.desc(),
    );
    return between(prev, version);
  }

  /// The window from [previous] (exclusive; null = the start) to [version].
  /// By revision when both recorded one (a first version needs only its
  /// own), else by capture time.
  static VersionWindow between(ItemVersion? previous, ItemVersion version) {
    final byRevision =
        version.revision != null &&
        (previous == null || previous.revision != null);
    return (
      fromRevision: byRevision ? previous?.revision : null,
      toRevision: byRevision ? version.revision : null,
      from: previous?.createdAt,
      to: version.createdAt,
    );
  }

  /// Rows of a server snapshot (`SheetsVersionProvider.decode`) as the
  /// core differ's row list.
  static List<(String, Map<String, Object?>)> rowsOf(
    Map<String, Map<String, Map<String, dynamic>>> snapshot,
  ) => [
    for (final t in snapshot.entries)
      for (final r in t.value.values) (t.key, r),
  ];

  /// Per-sheet row/column positions of a snapshot (sorted by `sortKey`,
  /// ties by id) for range attribution.
  static Map<String, Map<String, int>> _positions(
    Map<String, Map<String, dynamic>>? rows,
  ) {
    final bySheet = <String, List<Map<String, dynamic>>>{};
    for (final r in rows?.values ?? const <Map<String, dynamic>>[]) {
      bySheet.putIfAbsent('${r['sheetId']}', () => []).add(r);
    }
    return {
      for (final e in bySheet.entries)
        e.key: () {
          final list = e.value
            ..sort((a, b) {
              final k = '${a['sortKey']}'.compareTo('${b['sortKey']}');
              return k != 0 ? k : '${a['id']}'.compareTo('${b['id']}');
            });
          return {
            for (var i = 0; i < list.length; i++) '${list[i]['id']}': i,
          };
        }(),
    };
  }

  /// The diff from [previous] to [current] with the author (user profile
  /// id, 0 = unknown) of every changed cell from [ranges] (latest range
  /// containing the cell wins): `{diff: SnapshotDiff JSON, a: [ids]}`.
  static Map<String, Object?> attributedDiff(
    Map<String, Map<String, Map<String, dynamic>>> previous,
    Map<String, Map<String, Map<String, dynamic>>> current,
    List<AuthoredRange> ranges,
  ) {
    final diff = SnapshotDiffer.diffRows(rowsOf(previous), rowsOf(current));
    final rowPos = _positions(current[SheetsTables.sheetRow]);
    final colPos = _positions(current[SheetsTables.sheetColumn]);
    bool within(
      Map<String, int>? pos,
      Object? a,
      Object? b,
      String id,
    ) {
      if (pos == null) return false;
      final i = pos[id];
      if (i == null) return false;
      final x = a == null ? 0 : pos['$a'];
      final y = b == null ? pos.length - 1 : pos['$b'];
      if (x == null || y == null) return false;
      return i >= (x < y ? x : y) && i <= (x < y ? y : x);
    }

    final authors = <int>[];
    for (final c in diff.cells) {
      var author = 0;
      for (final r in ranges.reversed) {
        final m = r.range;
        if (m['s'] != c.sheetId) continue;
        if (within(rowPos[c.sheetId], m['r1'], m['r2'], c.rowId) &&
            within(colPos[c.sheetId], m['c1'], m['c2'], c.colId)) {
          author = r.userId;
          break;
        }
      }
      authors.add(author);
    }
    return {'diff': diff.toJson(), 'a': authors};
  }

  /// Gzip of [attributedDiff] JSON (the cached `<versionId>.diff.gz`).
  static Uint8List gzipJson(Map<String, Object?> json) =>
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(json))));

  /// Decodes [gzipJson] (tests, clients).
  static (SnapshotDiff, List<int>) decodeDiff(List<int> bytes) {
    final m = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map;
    return (
      SnapshotDiff.fromJson((m['diff'] as Map).cast<String, Object?>()),
      [for (final a in (m['a'] as List? ?? const [])) (a as num).toInt()],
    );
  }
}
