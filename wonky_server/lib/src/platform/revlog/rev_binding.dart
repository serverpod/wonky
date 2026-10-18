import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

import '../common/models.dart';
import 'rev_hooks.dart';

/// What an app plugs into the RevLog platform (RevLog spec 05 §1).
abstract class RevBinding {
  /// The file kind.
  RevFileKind get kind;

  /// The table schema.
  RevSchema get schema;

  /// The drive item kind of the files.
  DriveItemKind get itemKind;

  /// The root row's title column (04 §5 creation title).
  String get rootTitleColumn;

  /// Tables read sheet by sheet instead of by `fileId` (02 §2.2).
  Set<String> get perSheetTables => const {};

  /// The values of the scope columns of [perSheetTables] for a file (Sheets:
  /// `sheetId` → the file's sheet ids), read within [transaction].
  Future<Map<String, List<String>>> perSheetScopes(
    Session session,
    int fileId, {
    Transaction? transaction,
  }) async => const {};

  /// Limits, special-table roles and protections beyond the schema (03 §5
  /// rule 6). Throws [RevRejection].
  Future<void> authorize(
    Session session,
    Transaction transaction,
    ChangeSet cs,
    ApplyResult applied,
    RevAuthor author,
    RevStats statsAfter,
    RevModelAccess models,
  ) async {}

  /// The file's stats after [applied] (02 §1.1).
  RevStats updateStats(RevStats before, List<RowChange> applied) {
    final tables = {...before.tables};
    for (final c in applied) {
      switch (c.op) {
        case RowOp.insert:
          tables[c.table] = (tables[c.table] ?? 0) + 1;
        case RowOp.delete:
          tables[c.table] = ((tables[c.table] ?? 0) - 1).clamp(0, 1 << 62);
        case RowOp.update:
          break;
      }
    }
    return RevStats(tables: tables, extra: before.extra);
  }

  /// `contentCount` of [stats].
  int contentCount(RevStats stats) => 0;

  /// Summary JSON for plan-less server changes (02 §4).
  String summarize(List<RowChange> changes);

  /// Durable post-commit hooks in run order (05 §6).
  List<RevHook> get hooks => const [];

  /// Builds the headless model of a file from its rows (05 §9).
  Object buildModel(
    UuidValue fileUuid,
    Iterable<(String, Map<String, Object?>)> rows,
  );

  /// Applies an applied form to a headless model.
  void applyToModel(Object model, List<RowChange> applied);

  /// Rough memory size of a headless model.
  int estimateBytes(Object model);

  /// The codec of [schema] (lenient for payloads of compatible schemas).
  late final RevCodec codec = RevCodec(schema, lenient: true);
}

/// The author of an op (05 §1).
final class RevAuthor {
  /// Creates the record.
  const RevAuthor({
    required this.userId,
    required this.authUuid,
    required this.role,
    required this.actorKind,
  });

  /// user_profile id (null for system).
  final int? userId;

  /// Auth user uuid (null for system).
  final UuidValue? authUuid;

  /// Effective role.
  final Role role;

  /// Actor kind name.
  final String actorKind;
}

/// Lazily loads the headless model at the head before the op (05 §3.5).
abstract interface class RevModelAccess {
  /// The model at the previous revision.
  Future<Object> atPrevious();
}

/// `rev_file.stats` (02 §1.1): per-table row counts plus binding data.
final class RevStats {
  /// Creates stats.
  RevStats({Map<String, int>? tables, Map<String, Object?>? extra})
    : tables = tables ?? {},
      extra = extra ?? {};

  /// Parses `rev_file.stats`.
  factory RevStats.parse(String json) {
    final m = (jsonDecode(json) as Map).cast<String, Object?>();
    final t = (m['tables'] as Map?)?.cast<String, Object?>() ?? const {};
    return RevStats(
      tables: {for (final e in t.entries) e.key: (e.value! as num).toInt()},
      extra: {
        for (final e in m.entries)
          if (e.key != 'tables') e.key: e.value,
      },
    );
  }

  /// Rows per table.
  final Map<String, int> tables;

  /// Binding data (Sheets: per-sheet grid sizes).
  final Map<String, Object?> extra;

  /// JSON.
  String encode() => jsonEncode({'tables': tables, ...extra});
}
