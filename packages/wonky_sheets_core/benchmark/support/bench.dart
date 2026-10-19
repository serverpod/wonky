/// Shared helpers of the core benchmarks (specs/wonky_sheets/05-formula-engine.md §21).
///
/// The benchmarks run on the real [WorkbookModel] bound to the formula engine
/// ([ModelEngineBinding]) with UUID ids, the way the client `RecalcHost` and the
/// server `HeadlessWorkbook` use them, not on the test `MemoryWorkbook`.
library;

import 'dart:io';
import 'dart:math';

import 'package:wonky_sheets_core/model_testing.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart';
import 'package:wonky_sync_models/ids.dart';

/// One measured scenario: median and minimum of the timed runs.
final class BenchResult {
  BenchResult(this.name, this.median, this.min, this.runs, this.budget);

  final String name;
  final Duration median;
  final Duration min;
  final int runs;

  /// The spec budget (05 §21, native), for the printout; null when the spec has none.
  final String? budget;

  @override
  String toString() {
    final b = budget == null ? '' : '   (budget $budget)';
    return '${name.padRight(58)} ${_ms(median).padLeft(10)} median, '
        '${_ms(min).padLeft(10)} min, $runs runs$b';
  }

  static String _ms(Duration d) =>
      '${(d.inMicroseconds / 1000).toStringAsFixed(d.inMicroseconds < 10000 ? 3 : 1)} ms';
}

/// Runs [run] [warmup] + [runs] times (with [setUp] before each, untimed) and prints the
/// median and minimum time.
BenchResult bench(
  String name,
  void Function() run, {
  void Function()? setUp,
  int runs = 5,
  int warmup = 1,
  String? budget,
}) {
  final times = <Duration>[];
  for (var i = 0; i < warmup + runs; i++) {
    setUp?.call();
    final sw = Stopwatch()..start();
    run();
    sw.stop();
    if (i >= warmup) times.add(sw.elapsed);
  }
  times.sort();
  final r = BenchResult(
    name,
    times[times.length ~/ 2],
    times.first,
    runs,
    budget,
  );
  stdout.writeln(r);
  return r;
}

/// Prints a section header.
void section(String title) => stdout.writeln('\n== $title');

/// A workbook with one grid sheet bound to the formula engine.
final class BenchWorkbook {
  /// Creates a sheet of [rows] × [cols] with deterministic UUID ids.
  BenchWorkbook({required int rows, required int cols, int seed = 7}) {
    final b = WorkbookBuilder(ids: SeededIdGenerator(seed))
      ..sheet('Sheet1', rows: rows, cols: cols);
    model = b.build();
    sheet = model.sheets.first;
  }

  late final WorkbookModel model;
  late final SheetModel sheet;
  ModelEngineBinding? _binding;
  EngineFormulaHooks? _hooks;
  final IdGenerator _ids = SeededIdGenerator(99);

  String get sheetId => sheet.id;

  /// The engine binding (created on first use).
  ModelEngineBinding get binding =>
      _binding ??= ModelEngineBinding.create(model);

  /// The formula engine.
  FormulaEngine get engine => binding.engine;

  /// Formula hooks over the engine (as the app's planner context uses them).
  EngineFormulaHooks get hooks =>
      _hooks ??= EngineFormulaHooks(model, engine: engine, view: binding.view);

  String rowId(int r) => sheet.rows.idAt(r);
  String colId(int c) => sheet.columns.idAt(c);

  /// Stored reference token of the cell ([r], [c]).
  String ref(int r, int c, {bool absolute = false}) => RefToken(
    rowId: rowId(r),
    colId: colId(c),
    absRow: absolute,
    absCol: absolute,
  ).encode();

  /// Stored range `⟦…⟧:⟦…⟧` of ([r1], [c1])–([r2], [c2]) (endpoints carry sort keys).
  String range(int r1, int c1, int r2, int c2) {
    String end(int r, int c) => RefToken(
      rowId: rowId(r),
      colId: colId(c),
      rowKey: sheet.rows.sortKeyAt(r),
      colKey: sheet.columns.sortKeyAt(c),
    ).encode();
    return '${end(r1, c1)}:${end(r2, c2)}';
  }

  /// Stored form of an A1 formula hosted at ([row], [col]).
  String stored(String a1, {int row = 0, int col = 0}) => EngineFormulaHooks(
    model,
  ).toStored(a1, sheetId: sheetId, row: row, col: col);

  /// Encoded content of a literal [value].
  static String literal(Object value) =>
      CellContent.fromValue(CellValue.from(value))!.encode();

  /// A cell row with encoded [content] at ([r], [c]).
  RowChange cell(int r, int c, String content) {
    final rid = rowId(r), cid = colId(c);
    return RowChange.insert(
      SheetsTables.cell,
      SheetsIds.cellId(sheetId, rid, cid),
      {
        Cols.sheetId: sheetId,
        CellCols.rowId: rid,
        CellCols.columnId: cid,
        CellCols.content: content,
      },
    );
  }

  /// Loads cells without events (before the engine is bound).
  void load(Iterable<RowChange> cells) =>
      model.applyChanges(cells, silent: true);

  /// Plans [op] and applies it to the model (the engine follows through the binding).
  MutationPlan apply(SheetsOperation op) {
    final plan = const SheetsMutationPlanner().plan(op, model, context);
    model.applyPlan(plan);
    return plan;
  }

  /// The planner context the app would use.
  PlanContext get context => PlanContext(
    userId: '00000000-0000-4000-8000-0000000000ff',
    now: DateTime.utc(2026, 10, 18),
    ids: _ids,
    formulas: hooks,
    values: engine,
    random: Random(1),
    maxCells: 100000000,
  );

  /// Sets one cell through the planner (as typing does).
  void type(int r, int c, String text) => apply(
    SetCellInputs(
      sheetId: sheetId,
      row: r,
      col: c,
      inputs: [
        [CellInput.user(text)],
      ],
    ),
  );

  /// Value of ([r], [c]), evaluating on demand.
  FValue value(int r, int c) => engine.valueAt(sheetId, r, c);
}
