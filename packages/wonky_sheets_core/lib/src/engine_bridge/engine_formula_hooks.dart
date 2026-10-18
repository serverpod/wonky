import '../addressing/grid_geometry.dart';
import '../formula/codec/formula_codec.dart';
import '../formula/codec/ref_token.dart';
import '../formula/parser/formula_locale.dart';
import '../formula/parser/lexer.dart';
import '../formula/recalc/formula_engine.dart';
import '../formula/values/errors.dart';
import '../formula/values/fvalue.dart';
import '../model/axis_index.dart';
import '../model/records.dart';
import '../model/schema.dart';
import '../model/sheet_model.dart';
import '../model/workbook_model.dart';
import 'formula_hooks.dart';
import 'model_workbook_view.dart';

/// [FormulaHooks] over the formula engine's codec and a [WorkbookModel].
///
/// Conversions (`toStored`/`toA1`/`translate`) use `FormulaCodec`; rewrites
/// (delete repair, move remap, sort re-pinning, name rename) work on stored
/// reference tokens; rule formulas evaluate through [engine] when given.
final class EngineFormulaHooks implements FormulaHooks {
  /// Creates the hooks. [view] defaults to a [ModelWorkbookView] of [model].
  EngineFormulaHooks(
    this.model, {
    this.engine,
    ModelWorkbookView? view,
    this.displayLanguage = false,
  }) : view = view ?? ModelWorkbookView(model);

  /// Whether [toA1] renders the spreadsheet's display language
  /// (`Spreadsheet.displayLanguage`: localized function names and booleans).
  /// The editor UI turns it on; agents and exports keep English. [toStored]
  /// accepts localized names either way (English is always accepted).
  final bool displayLanguage;

  /// The model.
  final WorkbookModel model;

  /// The engine view of [model].
  final ModelWorkbookView view;

  /// Engine for [evaluateRelative] (optional).
  final FormulaEngine? engine;

  static const FormulaLexer _stored = FormulaLexer();

  /// Input ([toStored]) always accepts the display language's names (and
  /// English); output ([toA1]) is localized only with [displayLanguage].
  CodecContext _ctx(
    String sheetId,
    int row,
    int col,
    String locale, {
    required bool localized,
  }) => CodecContext(
    workbook: view,
    hostSheetId: sheetId,
    hostRow: row,
    hostCol: col,
    locale: localized
        ? FormulaLocale.forId(
            locale,
          ).withLanguage(model.spreadsheet.displayLanguage)
        : FormulaLocale.forId(locale),
  );

  static String _eq(String s) => s.startsWith('=') ? s : '=$s';

  @override
  String toStored(
    String a1Formula, {
    required String sheetId,
    required int row,
    required int col,
    String locale = 'en_US',
  }) => _eq(
    FormulaCodec.toStored(
      a1Formula,
      _ctx(sheetId, row, col, locale, localized: true),
    ),
  );

  @override
  String toA1(
    String stored, {
    required String sheetId,
    required int row,
    required int col,
    String locale = 'en_US',
  }) => _eq(
    FormulaCodec.toA1(
      stored,
      _ctx(sheetId, row, col, locale, localized: displayLanguage),
    ),
  );

  @override
  String translate(
    String stored, {
    required String fromSheetId,
    required int fromRow,
    required int fromCol,
    required String toSheetId,
    required int toRow,
    required int toCol,
  }) => _eq(
    FormulaCodec.translate(
      stored,
      CellPos(fromRow, fromCol),
      CellPos(toRow, toCol),
      view,
      fromSheetId: fromSheetId,
      toSheetId: toSheetId,
    ),
  );

  /// Rewrites every stored reference with [f] (returning null keeps it; a
  /// String replaces the reference text). Returns null when nothing changed.
  String? _rewrite(String stored, String? Function(StoredRef ref) f) {
    if (!stored.contains(RefToken.open)) return null;
    final tokens = _stored.tokenize(stored);
    final b = StringBuffer();
    var changed = false;
    for (final t in tokens) {
      final ref = t.kind == TokenKind.storedRef ? t.ref?.stored : null;
      if (ref == null) {
        b.write(t.text);
        continue;
      }
      final r = f(ref);
      if (r == null || r == t.text) {
        b.write(t.text);
      } else {
        b.write(r);
        changed = true;
      }
    }
    return changed ? b.toString() : null;
  }

  SheetModel? _sheetOfRow(String rowId) {
    final r = model.record(SheetsTables.sheetRow, rowId);
    return r is DimensionRecord ? model.sheet(r.sheetId) : null;
  }

  SheetModel? _sheetOfCol(String colId) {
    final r = model.record(SheetsTables.sheetColumn, colId);
    return r is DimensionRecord ? model.sheet(r.sheetId) : null;
  }

  @override
  String? repairBoundaries(
    String stored, {
    required Set<String> deletedRowIds,
    required Set<String> deletedColIds,
  }) {
    if (deletedRowIds.isEmpty && deletedColIds.isEmpty) return null;
    return _rewrite(stored, (ref) {
      final s = ref.start;
      final e = ref.end;
      bool del(String? id, Set<String> set) => id != null && set.contains(id);
      if (e == null) {
        if (s.isUnbound) return null;
        if (del(s.rowId, deletedRowIds) || del(s.colId, deletedColIds)) {
          return '#REF!';
        }
        return null;
      }
      var start = s;
      var end = e;
      var changed = false;
      // Rows.
      if (del(s.rowId, deletedRowIds) || del(e.rowId, deletedRowIds)) {
        final sheet = _sheetOfRow(s.rowId ?? e.rowId!);
        if (sheet == null) return null;
        final span = _inward(sheet.rows, s.rowId, e.rowId, deletedRowIds);
        if (span == null) return '#REF!';
        start = start.copyWith(
          rowId: span.$1,
          rowKey: span.$1 == null ? null : sheet.rows.sortKeyOf(span.$1!),
        );
        end = end.copyWith(
          rowId: span.$2,
          rowKey: span.$2 == null ? null : sheet.rows.sortKeyOf(span.$2!),
        );
        changed = true;
      }
      if (del(s.colId, deletedColIds) || del(e.colId, deletedColIds)) {
        final sheet = _sheetOfCol(s.colId ?? e.colId!);
        if (sheet == null) return null;
        final span = _inward(sheet.columns, s.colId, e.colId, deletedColIds);
        if (span == null) return '#REF!';
        start = start.copyWith(
          colId: span.$1,
          colKey: span.$1 == null ? null : sheet.columns.sortKeyOf(span.$1!),
        );
        end = end.copyWith(
          colId: span.$2,
          colKey: span.$2 == null ? null : sheet.columns.sortKeyOf(span.$2!),
        );
        changed = true;
      }
      if (!changed) return null;
      return StoredRef(start, end).encode();
    });
  }

  /// Moves deleted endpoints inward to the nearest surviving id; null when no
  /// entry of the span survives. Endpoints that are null stay null.
  (String?, String?)? _inward(
    AxisIndex axis,
    String? a,
    String? z,
    Set<String> deleted,
  ) {
    var i = a == null ? 0 : axis.indexOf(a);
    var j = z == null ? axis.length - 1 : axis.indexOf(z);
    if (i < 0 || j < 0) return (a, z);
    if (i > j) {
      final t = i;
      i = j;
      j = t;
    }
    String? na = a;
    String? nz = z;
    if (a != null && deleted.contains(a)) {
      na = null;
      for (var k = i; k <= j; k++) {
        if (!deleted.contains(axis.idAt(k))) {
          na = axis.idAt(k);
          break;
        }
      }
      if (na == null) return null;
    }
    if (z != null && deleted.contains(z)) {
      nz = null;
      for (var k = j; k >= i; k--) {
        if (!deleted.contains(axis.idAt(k))) {
          nz = axis.idAt(k);
          break;
        }
      }
      if (nz == null) return null;
    }
    return (na, nz);
  }

  /// Resolves a stored reference to a rectangle on its sheet.
  (SheetModel, GridRect)? _rect(StoredRef ref, String hostSheetId) {
    final s = ref.start;
    if (s.isUnbound) return null;
    final sheet = model.sheet(s.sheetId ?? hostSheetId);
    if (sheet == null) return null;
    final e = ref.end ?? s;
    int idx(AxisIndex axis, String? id, String? key, bool isStart, int open) {
      if (id == null) return open;
      final i = axis.indexOf(id);
      if (i >= 0) return i;
      if (key == null) return -1;
      final lb = axis.insertionIndex(key, id);
      return isStart ? lb : lb - 1;
    }

    final r1 = idx(sheet.rows, s.rowId, s.rowKey, true, 0);
    final c1 = idx(sheet.columns, s.colId, s.colKey, true, 0);
    final r2 = idx(sheet.rows, e.rowId, e.rowKey, false, sheet.rows.length - 1);
    final c2 = idx(
      sheet.columns,
      e.colId,
      e.colKey,
      false,
      sheet.columns.length - 1,
    );
    if (r1 < 0 || c1 < 0 || r2 < 0 || c2 < 0) return null;
    return (sheet, GridRect.normalized(r1, c1, r2, c2));
  }

  @override
  String? remap(
    String stored, {
    required String hostSheetId,
    required String sourceSheetId,
    required GridRect source,
    required String destSheetId,
    required GridRect dest,
  }) {
    final dst = model.sheet(destSheetId);
    if (dst == null) return null;
    final dRow = dest.top - source.top;
    final dCol = dest.left - source.left;
    return _rewrite(stored, (ref) {
      final hit = _rect(ref, hostSheetId);
      if (hit == null) return null;
      final (sheet, rect) = hit;
      if (sheet.id != sourceSheetId) return null;
      final s = ref.start;
      final e = ref.end;
      // Whole rows/columns are never retargeted.
      if (s.rowId == null ||
          s.colId == null ||
          (e != null && (e.rowId == null || e.colId == null))) {
        return null;
      }
      if (!source.containsRect(rect)) return null;
      final sheetField = destSheetId == hostSheetId ? null : destSheetId;
      String? rid(int i) => dst.rows.tryIdAt(i);
      String? cid(int i) => dst.columns.tryIdAt(i);
      final nr1 = rid(rect.top + dRow);
      final nc1 = cid(rect.left + dCol);
      if (nr1 == null || nc1 == null) return '#REF!';
      if (e == null) {
        return RefToken(
          sheetId: sheetField,
          rowId: nr1,
          colId: nc1,
          absRow: s.absRow,
          absCol: s.absCol,
        ).encode();
      }
      final nr2 = rid(rect.bottom + dRow);
      final nc2 = cid(rect.right + dCol);
      if (nr2 == null || nc2 == null) return '#REF!';
      // Keep the endpoint orientation of the original reference.
      final a = RefToken(
        sheetId: sheetField,
        rowId: nr1,
        colId: nc1,
        absRow: s.absRow,
        absCol: s.absCol,
        rowKey: dst.rows.sortKeyOf(nr1),
        colKey: dst.columns.sortKeyOf(nc1),
      );
      final z = RefToken(
        rowId: nr2,
        colId: nc2,
        absRow: e.absRow,
        absCol: e.absCol,
        rowKey: dst.rows.sortKeyOf(nr2),
        colKey: dst.columns.sortKeyOf(nc2),
      );
      return StoredRef(a, z).encode();
    });
  }

  @override
  String? repinRows(
    String stored, {
    required String hostSheetId,
    required String sheetId,
    required int blockTop,
    required int blockBottom,
    required String Function(int position) newRowIdAt,
    required int Function(String rowId) oldIndexOf,
  }) => _rewrite(stored, (ref) {
    final s = ref.start;
    if (s.isUnbound) return null;
    if ((s.sheetId ?? hostSheetId) != sheetId) return null;
    RefToken pin(RefToken t) {
      final id = t.rowId;
      if (id == null) return t;
      final p = oldIndexOf(id);
      if (p < blockTop || p > blockBottom) return t;
      return t.copyWith(rowId: newRowIdAt(p));
    }

    final ns = pin(s);
    final ne = ref.end == null ? null : pin(ref.end!);
    if (ns == s && ne == ref.end) return null;
    return StoredRef(ns, ne).encode();
  });

  @override
  String renameName(String stored, String oldName, String newName) {
    final lower = oldName.toLowerCase();
    final tokens = _stored.tokenize(_eq(stored));
    final b = StringBuffer();
    for (final t in tokens) {
      if ((t.kind == TokenKind.name || t.kind == TokenKind.functionName) &&
          t.text.toLowerCase() == lower) {
        b.write(newName);
      } else {
        b.write(t.text);
      }
    }
    return b.toString();
  }

  @override
  bool references(
    String stored, {
    required String hostSheetId,
    required String sheetId,
    required GridRect rect,
  }) {
    if (!stored.contains(RefToken.open)) return false;
    for (final ref in FormulaCodec.references(_eq(stored))) {
      final hit = _rect(ref, hostSheetId);
      if (hit != null && hit.$1.id == sheetId && hit.$2.intersects(rect)) {
        return true;
      }
    }
    return false;
  }

  @override
  FValue evaluateRelative(
    String stored, {
    required String sheetId,
    required int anchorRow,
    required int anchorCol,
    required int row,
    required int col,
  }) {
    final e = engine;
    if (e == null) return const FError(ErrorKind.calc, 'No formula engine');
    // Rule formulas are evaluated for every cell of their ranges: compile each
    // (formula, anchor) once. The key is the stored text, so a changed rule
    // compiles anew; the compiled form resolves its ids on every evaluation.
    final key = (stored, sheetId, anchorRow, anchorCol);
    var compiled = _relative[key];
    if (compiled == null) {
      compiled = e.compileRelative(
        stored,
        sheetId: sheetId,
        anchor: CellPos(anchorRow, anchorCol),
      );
      if (_relative.length >= _relativeCapacity) {
        _relative.remove(_relative.keys.first);
      }
      _relative[key] = compiled;
    }
    return compiled.evaluate(row, col);
  }

  static const int _relativeCapacity = 512;

  /// Compiled rule formulas, oldest first.
  final Map<(String, String, int, int), CompiledRelative> _relative = {};
}
