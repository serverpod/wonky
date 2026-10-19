import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/model.dart'
    show
        ChangeKinds,
        ChangeSummary,
        GuardResult,
        GuardStatus,
        MutationPlan,
        ProtectionCheck,
        RowChange,
        RowOp,
        SheetsTables;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/files/file_service.dart';
import '../../platform/presence/presence_service.dart';
import '../../platform/revlog/rev_sql.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/users/user_service.dart';
import '../../platform/versions/version_service.dart';
import '../headless/headless_workbook_provider.dart';
import '../revlog/sheets_rev_binding.dart';
import '../revlog/sheets_server_writes.dart';
import 'sheets_version_changes.dart';

/// Sheets versions (Sheets 10 §5.1): a gzip NDJSON snapshot of all rows of
/// the spreadsheet in cloud storage, taken at a file revision (recorded in
/// `ItemVersion.revision`); restore applies the row diff as RevLog server
/// changes recorded as a [ServerChangeRecord] (RevLog spec 05 §8).
class SheetsVersionProvider implements VersionProvider {
  const SheetsVersionProvider();

  static const format = 'wonky-sheets-snapshot';
  static const excluded = {
    SheetsTables.changeLog,
    SheetsTables.scriptBuild,
    SheetsTables.scriptTrigger,
  };

  /// The refusal of a restore that would write protected ranges.
  static const protectedMessage =
      "This version changes protected ranges you can't edit";

  @override
  DriveItemKind get kind => DriveItemKind.spreadsheet;

  /// All rows of [space] by table name (admin read), in dependency order,
  /// as JSON maps (date-times as ISO strings).
  static Future<Map<String, Map<String, Map<String, dynamic>>>> readSpace(
    Session session,
    UuidValue space,
  ) async => (await readAt(session, space)).$2;

  /// The rows of [space] as [readSpace] with the file revision they show:
  /// one repeatable-read transaction, so rows and revision agree while ops
  /// commit. Revision 0 when the file is missing.
  static Future<(int, Map<String, Map<String, Map<String, dynamic>>>)> readAt(
    Session session,
    UuidValue space,
  ) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(space),
    );
    if (file == null) return (0, <String, Map<String, Map<String, dynamic>>>{});
    final binding = SheetsRevBinding.instance;
    final sql = RevSql(binding.schema, perSheetTables: binding.perSheetTables);
    final (revision, rows) = await session.db.transaction(
      (tx) async {
        final head = await session.db.unsafeQuery(
          'SELECT "headRevision" FROM rev_file WHERE id = @f',
          parameters: QueryParameters.named({'f': file.id}),
          transaction: tx,
        );
        final list = await sql
            .allRows(
              session,
              file.id!,
              scopes: () => binding.perSheetScopes(
                session,
                file.id!,
                transaction: tx,
              ),
              transaction: tx,
            )
            .toList();
        return (head.first[0]! as int, list);
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.repeatableRead,
      ),
    );
    final result = <String, Map<String, Map<String, dynamic>>>{};
    for (final (table, row) in rows) {
      if (excluded.contains(table)) continue;
      (result[table] ??= {})[row['id']! as String] = {
        for (final e in row.entries)
          e.key: switch (e.value) {
            DateTime() => (e.value! as DateTime).toUtc().toIso8601String(),
            _ => e.value,
          },
      };
    }
    return (
      revision,
      {
        for (final name in SheetsTables.dependencyOrder)
          if (result.containsKey(name)) name: result[name]!,
      },
    );
  }

  /// The gzip NDJSON snapshot of [rows]. Streamed: each line goes through
  /// the UTF-8 and gzip encoders as it is produced, so only the compressed
  /// output is held besides the rows.
  static Uint8List encode(
    UuidValue space,
    Map<String, Map<String, Map<String, dynamic>>> rows, {
    int? revision,
  }) {
    final out = BytesBuilder(copy: false);
    final zipped = gzip.encoder.startChunkedConversion(
      ByteConversionSink.withCallback((bytes) => out.add(bytes)),
    );
    final lines = utf8.encoder.startChunkedConversion(zipped);
    void line(Object? json) => lines.add('${jsonEncode(json)}\n');
    line({
      'format': format,
      'v': 1,
      'spreadsheetId': space.uuid,
      'capturedAt': nowUtc().toIso8601String(),
      'revision': ?revision,
      'schemaHash': SheetsRevBinding.instance.schema.hash,
      'counts': {for (final e in rows.entries) e.key: e.value.length},
    });
    for (final table in rows.entries) {
      for (final row in table.value.values) {
        line({'tb': table.key, 'row': row});
      }
    }
    lines.close();
    return out.takeBytes();
  }

  /// The `sheetsJson` of a snapshot index (Sheets 10 §5.1.2): each sheet
  /// with its row, column and cell counts, in one pass over [rows].
  static String sheetIndex(
    Map<String, Map<String, Map<String, dynamic>>> rows,
  ) {
    Map<String, int> countBySheet(String table) {
      final counts = <String, int>{};
      for (final r in rows[table]?.values ?? const <Map<String, dynamic>>[]) {
        final id = r['sheetId'];
        if (id is String) counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    }

    final rowCounts = countBySheet(SheetsTables.sheetRow);
    final colCounts = countBySheet(SheetsTables.sheetColumn);
    final cellCounts = countBySheet(SheetsTables.cell);
    return jsonEncode([
      for (final s
          in rows[SheetsTables.sheet]?.values ?? const <Map<String, dynamic>>[])
        {
          'id': s['id'],
          'name': s['name'],
          'kind': s['kind'],
          'rows': rowCounts[s['id']] ?? 0,
          'cols': colCounts[s['id']] ?? 0,
          'cells': cellCounts[s['id']] ?? 0,
        },
    ]);
  }

  static Map<String, Map<String, Map<String, dynamic>>> decode(Uint8List data) {
    final lines = const LineSplitter().convert(utf8.decode(gzip.decode(data)));
    if (lines.isEmpty) throw const FormatException('Empty snapshot');
    final header = jsonDecode(lines.first) as Map;
    if (header['format'] != format) {
      throw const FormatException('Not a Wonky Sheets snapshot');
    }
    final result = <String, Map<String, Map<String, dynamic>>>{};
    for (final line in lines.skip(1)) {
      if (line.isEmpty) continue;
      final m = jsonDecode(line) as Map;
      final row = (m['row'] as Map).cast<String, dynamic>();
      result.putIfAbsent(m['tb'] as String, () => {})[row['id'] as String] =
          row;
    }
    return result;
  }

  @override
  Future<CapturedVersion> capture(Session session, DriveItem item) async {
    final space = item.contentRef!;
    final (revision, rows) = await readAt(session, space);
    final bytes = encode(space, rows, revision: revision);
    final file = await FileService.storeServerFile(
      session,
      ownerId: item.ownerId,
      itemId: item.id,
      kind: StoredFileKind.snapshot,
      fileName: 'snapshot.wsv.gz',
      mimeType: 'application/gzip',
      bytes: bytes,
    );
    return CapturedVersion(
      storageKind: VersionStorage.snapshotFile,
      revision: revision,
      snapshotFileId: file.fileUuid,
      sizeBytes: bytes.length,
      // Counted now, from the rows in memory: afterCapture never downloads
      // and decodes the snapshot it just stored.
      index: sheetIndex(rows),
    );
  }

  @override
  Future<void> beforeCapture(Session session, DriveItem item) async {}

  @override
  Future<void> afterCapture(
    Session session,
    DriveItem item,
    ItemVersion version,
    CapturedVersion captured,
  ) async {
    await SheetsSnapshotIndex.db.insertRow(
      session,
      SheetsSnapshotIndex(
        itemVersionId: version.id!,
        sheetsJson: captured.index as String? ?? '[]',
        changedRangesJson: await _changedRanges(session, item, version),
        authorIds: version.authors,
      ),
    );
  }

  /// `changedRangesJson` of [version]: the ranges of the ops committed
  /// since the previous capture, with authors (Sheets 10 §5.1.2).
  static Future<String> _changedRanges(
    Session session,
    DriveItem item,
    ItemVersion version,
  ) async {
    try {
      final window = await SheetsVersionChanges.windowOf(session, version);
      final (ranges, approx) = await SheetsVersionChanges.rangesBetween(
        session,
        item.contentRef!,
        window,
      );
      return SheetsVersionChanges.encode(ranges, approx: approx);
    } on Exception catch (e) {
      session.log('Changed ranges failed: $e', level: LogLevel.warning);
      return SheetsVersionChanges.encode(const [], approx: true);
    }
  }

  @override
  Future<RestoredVersion> restore(
    Session session,
    Actor actor,
    DriveItem item,
    ItemVersion version,
  ) async {
    final fileId = version.snapshotFileId;
    if (fileId == null) throw Errors.invalid('The version has no snapshot.');
    final file = await FileService.byUuid(session, fileId);
    if (file == null) throw Errors.expired('The snapshot is no longer stored.');
    final bytes = await FileService.readBytes(session, file);
    final target = decode(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    final current = await readSpace(session, item.contentRef!);
    final changes = diff(current, toSchema(target));
    await _checkProtections(session, actor, item, changes);
    final label =
        'Restore version "${version.name ?? version.createdAt.toIso8601String()}"';
    final detail = detailOf(changes);
    final (changeId, _) = await SheetsServerWrites.applyRecorded(
      session,
      actor: actor,
      item: item,
      changes: changes,
      label: label,
      summary: summarize(changes),
      detailJson: detail == null ? null : jsonEncode(detail),
      lifetime: const Duration(days: 7),
    );
    try {
      final profile = await UserService.requireProfile(session, actor.userId);
      final who = await UserService.summaryOf(session, profile);
      await PresenceService.notice(session, item.uuid, 'versionRestored', {
        'userId': actor.userId,
        'name': who.displayName,
        'versionId': version.id,
      });
    } on Exception catch (e) {
      session.log('Restore notice failed: $e', level: LogLevel.warning);
    }
    return RestoredVersion(changeId: changeId);
  }

  /// Checks the whole restore diff against the protected ranges before the
  /// first chunk is written (RevLog spec 05 §3.5), so a restore never
  /// commits partially because of protection.
  static Future<void> _checkProtections(
    Session session,
    Actor actor,
    DriveItem item,
    List<RowChange> changes,
  ) async {
    if (changes.isEmpty) return;
    final wb = await HeadlessWorkbookProvider.open(session, item.contentRef!);
    final model = wb.model;
    final touches = changes.any((c) => c.table == SheetsTables.protectedRange);
    if (!touches && !model.sheets.any((s) => s.protections.isNotEmpty)) {
      return;
    }
    final role = await AccessService.effectiveRole(session, actor.userId, item);
    final result = ProtectionCheck.ofApplied(
      model,
      changes,
      actor.authUserId.uuid.toLowerCase(),
      isOwner: role == Role.owner,
    );
    if (result.status != GuardStatus.blocked) return;
    throw Errors.protectedRange(
      protectedMessage,
      detailsJson: jsonEncode({
        'message': GuardResult.blockedMessage,
        'protections': [
          for (final id in {for (final h in result.hits) h.protectionId})
            {'id': id},
        ],
      }),
    );
  }

  /// [snapshot] limited to the tables and columns of the RevLog schema
  /// (snapshots of older schemas may carry columns that no longer exist).
  static Map<String, Map<String, Map<String, dynamic>>> toSchema(
    Map<String, Map<String, Map<String, dynamic>>> snapshot,
  ) {
    final schema = SheetsRevBinding.instance.schema;
    final out = <String, Map<String, Map<String, dynamic>>>{};
    for (final t in snapshot.entries) {
      final table = schema.tryTable(t.key);
      if (table == null) continue;
      final names = {'id', for (final c in table.columns) c.name};
      out[t.key] = {
        for (final r in t.value.entries)
          r.key: {
            for (final e in r.value.entries)
              if (names.contains(e.key)) e.key: e.value,
          },
      };
    }
    return out;
  }

  /// `rev_op.summaryJson` of a restore: touched sheets, deleted and
  /// revived rows/columns/sheets (comment orphaning, Sheets 10 §3.2) and
  /// the restore kind.
  static ChangeSummary summarize(List<RowChange> changes) {
    final s = ChangeSummary(kinds: {ChangeKinds.restore});
    const kinds = {
      SheetsTables.sheetRow: 'rows',
      SheetsTables.sheetColumn: 'cols',
      SheetsTables.sheet: 'sheets',
    };
    for (final c in changes) {
      final sheetId = c.columnsAfter['sheetId'] ?? c.columnsBefore['sheetId'];
      if (sheetId != null) s.sheets.add('$sheetId');
      if (c.table == SheetsTables.sheet) s.sheets.add(c.rowId);
      final kind = kinds[c.table];
      if (kind == null) continue;
      if (c.op == RowOp.delete) s.addDeleted(kind, c.rowId);
      if (c.op == RowOp.insert) s.addRevived(kind, c.rowId);
    }
    return s;
  }

  /// `rev_op.detailJson` map of a restore's cell content changes (≤ 200
  /// cells, else null), so cell edit history lists restored values.
  static Map<String, Object?>? detailOf(List<RowChange> changes) {
    final cells = <Map<String, Object?>>[];
    for (final c in changes) {
      if (c.table != SheetsTables.cell) continue;
      final before = c.columnsBefore['content'];
      final after = c.columnsAfter['content'];
      final touches =
          c.op != RowOp.update || c.columnsAfter.containsKey('content');
      if (!touches || before == after) continue;
      final src = c.op == RowOp.delete ? c.columnsBefore : c.columnsAfter;
      final sheetId = src['sheetId'] ?? c.columnsBefore['sheetId'];
      final rowId = src['rowId'] ?? c.columnsBefore['rowId'];
      final colId = src['columnId'] ?? c.columnsBefore['columnId'];
      if (sheetId == null || rowId == null || colId == null) continue;
      if (cells.length >= MutationPlan.maxDetailCells) return null;
      cells.add({
        's': '$sheetId',
        'r': '$rowId',
        'c': '$colId',
        'b': before,
        'a': after,
      });
    }
    return cells.isEmpty ? null : {'cells': cells};
  }

  /// Row changes turning [current] into [target]: inserts parents first,
  /// deletes children first, updates naming only differing columns.
  static List<RowChange> diff(
    Map<String, Map<String, Map<String, dynamic>>> current,
    Map<String, Map<String, Map<String, dynamic>>> target,
  ) {
    final upserts = <RowChange>[];
    final deletes = <RowChange>[];
    for (final table in SheetsTables.dependencyOrder) {
      if (excluded.contains(table)) continue;
      final cur = current[table] ?? const {};
      final tgt = target[table] ?? const {};
      for (final entry in tgt.entries) {
        final now = cur[entry.key];
        if (now == null) {
          upserts.add(RowChange.insert(table, entry.key, entry.value));
          continue;
        }
        final before = <String, Object?>{};
        final after = <String, Object?>{};
        for (final col in entry.value.entries) {
          if (col.key == 'id') continue;
          if (jsonEncode(now[col.key]) != jsonEncode(col.value)) {
            before[col.key] = now[col.key];
            after[col.key] = col.value;
          }
        }
        if (after.isNotEmpty) {
          upserts.add(RowChange.update(table, entry.key, before, after));
        }
      }
      for (final entry in cur.entries) {
        if (!tgt.containsKey(entry.key)) {
          deletes.add(RowChange.delete(table, entry.key, entry.value));
        }
      }
    }
    return [...deletes.reversed, ...upserts];
  }

  @override
  Future<void> discard(Session session, ItemVersion version) async {
    if (version.snapshotFileId != null) {
      await FileService.deleteFile(session, version.snapshotFileId!);
    }
  }
}
