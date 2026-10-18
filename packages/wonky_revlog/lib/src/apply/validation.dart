import 'dart:convert';

import '../codec/change_set.dart';
import '../rows/row_change.dart';
import '../schema/rev_schema.dart';

/// Rejection codes (RevLog spec 04 §4); mirrored by the server enum
/// `RevRejectCode`.
enum RevRejectReason {
  invalidChange,
  tooLarge,
  limitExceeded,
  forbiddenForRole,
  forbidden,
  unknownBase,
  schemaMismatch,
  notFound,
  fileReadOnly,
  protectedRange,
  internal,
}

/// An op that must not be committed.
final class RevRejection implements Exception {
  /// Creates the rejection.
  RevRejection(this.reason, this.message, {this.details});

  /// Code.
  final RevRejectReason reason;

  /// Human-readable message (first offending change).
  final String message;

  /// Code-specific JSON details (e.g. protections hit).
  final Map<String, Object?>? details;

  @override
  String toString() => 'RevRejection(${reason.name}): $message';
}

/// Limits of RevLog spec 01 §4.
final class RevLimits {
  /// Creates limits.
  const RevLimits({
    this.maxChangesPerOp = 5000,
    this.maxOpBytes = 16 * 1024 * 1024,
    this.maxMessageBytes = 4 * 1024 * 1024,
    this.targetOpBytes = 1024 * 1024,
  });

  /// Changes per op.
  final int maxChangesPerOp;

  /// Uncompressed payload bytes.
  final int maxOpBytes;

  /// Compressed message bytes.
  final int maxMessageBytes;

  /// Chunkers aim below this (encoded, compressed estimate).
  final int targetOpBytes;

  /// Defaults.
  static const defaults = RevLimits();
}

/// Static validation of an op (03 §5 rules 1–5). Ids-belong-to-file (3a),
/// binding limits (6) and protection (7) are checked by the sequencer.
void validateChangeSet(
  RevSchema schema,
  ChangeSet cs, {
  required bool fromClient,
  required bool isCreation,
  required String fileUuid,
  RevLimits limits = RevLimits.defaults,
}) {
  Never reject(String m) =>
      throw RevRejection(RevRejectReason.invalidChange, m);
  if (cs.changes.length > limits.maxChangesPerOp) {
    throw RevRejection(
      RevRejectReason.tooLarge,
      '${cs.changes.length} changes (max ${limits.maxChangesPerOp})',
    );
  }
  if (fromClient && !const {'user', 'script'}.contains(cs.actorKind)) {
    reject('actor kind ${cs.actorKind} is not allowed from clients');
  }
  for (final ch in cs.changes) {
    final table = schema.tryTable(ch.table);
    if (table == null) reject('unknown table ${ch.table}');
    if (fromClient && !table.clientWritable) {
      reject('${ch.table} is written by the server only');
    }
    if (!_isUuid(ch.rowId)) reject('bad id ${ch.rowId}');
    if (table.isRoot) {
      if (ch.op == RowOp.delete) reject('the root row cannot be deleted');
      if (ch.op == RowOp.insert && (!isCreation || ch.rowId != fileUuid)) {
        reject('the root row can only be created by the creation op');
      }
    }
    if (ch.op == RowOp.update) {
      if (ch.columnsAfter.isEmpty) {
        reject('empty update of ${ch.table} ${ch.rowId}');
      }
      if (!ch.columnsBefore.keys.every(ch.columnsAfter.containsKey)) {
        reject(
          'update of ${ch.table} ${ch.rowId}: before names untouched columns',
        );
      }
    }
    final values = ch.op == RowOp.delete
        ? const <String, Object?>{}
        : ch.columnsAfter;
    for (final e in values.entries) {
      if (e.key == RowChange.idColumn) continue;
      final col = table.column(e.key);
      if (col == null) reject('unknown column ${ch.table}.${e.key}');
      if (fromClient && !col.clientWritable) {
        reject('${ch.table}.${e.key} is written by the server only');
      }
      if (ch.op == RowOp.update && col.immutable) {
        reject('${ch.table}.${e.key} cannot be updated');
      }
      _checkValue(table, col, e.value, reject);
    }
  }
}

void _checkValue(
  RevTable table,
  RevColumn col,
  Object? v,
  Never Function(String) reject,
) {
  // Built only for a rejection (this runs for every value of an op).
  String where() => '${table.name}.${col.name}';
  if (v == null) {
    if (!col.nullable) reject('${where()} must not be null');
    return;
  }
  switch (col.type) {
    case RevColumnType.uuid:
      if (!_isUuid(v.toString())) reject('${where()}: not a uuid');
    case RevColumnType.string:
      if (v is! String) reject('${where()}: not a string');
      if (col.maxLength != null && v.length > col.maxLength!) {
        reject('${where()}: longer than ${col.maxLength}');
      }
    case RevColumnType.json:
      if (v is! String) reject('${where()}: not a JSON string');
      if (col.maxLength != null && v.length > col.maxLength!) {
        reject('${where()}: longer than ${col.maxLength}');
      }
      if (v.isNotEmpty) {
        try {
          jsonDecode(v);
        } on FormatException {
          reject('${where()}: invalid JSON');
        }
      }
    case RevColumnType.int:
      if (v is! num || v != v.roundToDouble()) reject('${where()}: not an int');
    case RevColumnType.double:
      if (v is! num || !v.toDouble().isFinite) {
        reject('${where()}: not a finite number');
      }
    case RevColumnType.bool:
      if (v is! bool) reject('${where()}: not a bool');
    case RevColumnType.dateTime:
      if (v is! DateTime && v is! String && v is! num) {
        reject('${where()}: not a date');
      }
    case RevColumnType.enumName:
      final name = v is Enum ? v.name : v.toString();
      if (col.enumValues != null && !col.enumValues!.contains(name)) {
        reject('${where()}: unknown value $name');
      }
  }
}

/// Whether [s] is a lower-case dashed UUID
/// (`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`),
/// checked by hand: it runs for every id of an op.
bool _isUuid(String s) {
  if (s.length != 36) return false;
  for (var i = 0; i < 36; i++) {
    final c = s.codeUnitAt(i);
    if (i == 8 || i == 13 || i == 18 || i == 23) {
      if (c != 0x2d) return false;
    } else if (!(c >= 0x30 && c <= 0x39 || c >= 0x61 && c <= 0x66)) {
      return false;
    }
  }
  return true;
}
