/// Public test helpers for the formula engine (specs/15 §2): an in-memory
/// workbook ([MemoryWorkbook]) and the [FormulaTestBench] that evaluates
/// formulas against it. Never import from `lib/` code (CQ-56: they were
/// exported from `formula.dart`).
library;

export 'src/formula/model/memory_workbook.dart';
export 'src/formula/testing/formula_test_bench.dart';
