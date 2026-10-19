import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_sheets_core/model.dart'
    show Cols, CellCols, RowChange, SheetsTables;
import 'package:wonky_sync_models/ids.dart';

import '../../platform/common/models.dart';
import '../../platform/revlog/rev_sql.dart';
import '../revlog/sheets_rev_binding.dart';

/// Copies a spreadsheet into a new file (Sheets 10 §5.4 "Make a copy",
/// templates). Row ids are global, so every entity gets a new UUIDv7; cell
/// and basic-filter ids are recomputed ([SheetsIds]); ids inside strings
/// (stored formula tokens in base-62 form, GridRange JSON, anchors) are
/// remapped. Script triggers and builds are not copied.
abstract final class SpaceCopier {
  static final _uuidPattern = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );
  static final _base62Pattern = RegExp(r'[0-9A-Za-z]{22}');

  /// Tables not copied.
  static const excluded = {
    SheetsTables.scriptTrigger,
    SheetsTables.scriptBuild,
  };

  /// The creation changes of a copy of [fromFile] as the new file
  /// [toFile] by [authorUuid], and the id map (old → new, dashed lower
  /// case) for remapping comment anchors.
  static Future<(List<RowChange>, Map<String, String>)> changes(
    Session session, {
    required UuidValue fromFile,
    required UuidValue toFile,
    required UuidValue authorUuid,
    String? title,
    IdGenerator ids = const UuidV7IdGenerator(),
  }) async {
    final binding = SheetsRevBinding.instance;
    final schema = binding.schema;
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fromFile),
    );
    if (file == null) {
      throw StateError('Spreadsheet $fromFile has no rows to copy.');
    }
    final sql = RevSql(schema, perSheetTables: binding.perSheetTables);
    final rows = [
      for (final r
          in await sql
              .allRows(
                session,
                file.id!,
                scopes: () => binding.perSheetScopes(session, file.id!),
              )
              .toList())
        if (!excluded.contains(r.$1)) r,
    ];

    // ---- id map
    final idMap = <String, String>{fromFile.uuid: toFile.uuid};
    String id(Map<String, Object?> row) => row[RowChange.idColumn]! as String;
    for (final (table, row) in rows) {
      if (table == SheetsTables.spreadsheet ||
          table == SheetsTables.cell ||
          table == SheetsTables.basicFilter) {
        continue;
      }
      idMap[id(row)] = ids.newId();
    }
    for (final (table, row) in rows) {
      if (table == SheetsTables.basicFilter) {
        idMap[id(row)] = SheetsIds.basicFilterId(
          idMap[row[Cols.sheetId]! as String]!,
        );
      } else if (table == SheetsTables.cell) {
        idMap[id(row)] = SheetsIds.cellId(
          idMap[row[Cols.sheetId]! as String]!,
          idMap[row[CellCols.rowId]! as String]!,
          idMap[row[CellCols.columnId]! as String]!,
        );
      }
    }
    final base62Map = {
      for (final e in idMap.entries)
        Base62Uuid.encode(e.key): Base62Uuid.encode(e.value),
    };
    String remap(String s) {
      var out = s.replaceAllMapped(
        _uuidPattern,
        (m) => idMap[m[0]!.toLowerCase()] ?? m[0]!,
      );
      if (out.contains('⟦')) {
        out = out.replaceAllMapped(
          _base62Pattern,
          (m) => base62Map[m[0]!] ?? m[0]!,
        );
      }
      return out;
    }

    final now = DateTime.now().toUtc();
    final out = <RowChange>[];
    for (final (table, row) in rows) {
      final t = schema.table(table);
      final cols = <String, Object?>{};
      for (final c in t.columns) {
        final v = row[c.name];
        cols[c.name] = switch ((c.type, v)) {
          (RevColumnType.uuid, final String s) => idMap[s] ?? s,
          (RevColumnType.string || RevColumnType.json, final String s) => remap(
            s,
          ),
          _ => v,
        };
      }
      if (table == SheetsTables.spreadsheet) {
        cols['title'] = title ?? cols['title'];
        cols['createdBy'] = authorUuid.uuid;
        cols['createdAt'] = now;
      }
      out.add(RowChange.insert(table, idMap[id(row)]!, cols));
    }
    out.sort((a, b) => schema.rank(a.table).compareTo(schema.rank(b.table)));
    return (out, idMap);
  }
}
