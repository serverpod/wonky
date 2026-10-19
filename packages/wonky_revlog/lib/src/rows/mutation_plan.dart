import 'dart:convert';

import 'row_change.dart';

/// The change-log summary of a plan (`ChangeLog.summaryJson` of Sheets,
/// `DeckChangeLog.summaryJson` of Slides). Each app defines its own fields.
abstract interface class ChangeSummary {
  /// JSON map (stored as the `summaryJson` string).
  Map<String, Object?> toJson();
}

/// A [ChangeSummary] over a plain JSON map (tests, writers that derive a
/// summary from bare changes).
final class JsonChangeSummary implements ChangeSummary {
  /// Creates a summary holding [json].
  JsonChangeSummary([Map<String, Object?>? json]) : json = json ?? {};

  /// The summary fields.
  final Map<String, Object?> json;

  @override
  Map<String, Object?> toJson() => json;
}

/// A planned transaction: ordered row changes + undo label + change log data.
///
/// Planners (Sheets' `SheetsMutationPlanner`, Slides'
/// `SlidesMutationPlanner`) produce plans, writers store them (one
/// transaction per ≤ [chunkSize] changes plus the change-log row) and the
/// editor records them as one undo step.
final class MutationPlan<S extends ChangeSummary> {
  /// Creates a plan.
  MutationPlan({
    required this.label,
    required this.summary,
    required List<RowChange> changes,
    this.detail,
    this.warnings = const [],
    this.result = const {},
  }) : changes = List.unmodifiable(changes);

  /// Max entries listed in [detail] (Sheets lists cells).
  static const maxDetailCells = 200;

  /// Max row changes per writer transaction (Sheets 02 §7, Slides 02 §12.2).
  static const chunkSize = 5000;

  /// Undo label ("Paste", "Insert 3 rows").
  final String label;

  /// The change-log summary.
  final S summary;

  /// Ordered row changes.
  final List<RowChange> changes;

  /// The change-log `detailJson` map, or null when not recorded.
  final Map<String, Object?>? detail;

  /// Non-fatal warnings for the caller (MCP `warnings`, toasts).
  final List<String> warnings;

  /// Operation results (e.g. `{"sheetId": …}`, `{"replaced": 12}`).
  final Map<String, Object?> result;

  /// Whether the plan changes nothing.
  bool get isEmpty => changes.isEmpty;

  /// The changes split into writer chunks of ≤ [chunkSize] (one undo step).
  List<List<RowChange>> get chunks => [
    for (var i = 0; i < changes.length; i += chunkSize)
      changes.sublist(
        i,
        i + chunkSize > changes.length ? changes.length : i + chunkSize,
      ),
  ];

  /// The change-log `detailJson` string or null.
  String? get detailJson => detail == null ? null : jsonEncode(detail);

  /// The change-log `summaryJson` string.
  String get summaryJson => jsonEncode(summary.toJson());

  /// The inverse plan (undo), with changes in reverse order. Writers apply
  /// undo through `UndoInverter` (per-column skip rule) instead.
  MutationPlan<S> inverse({String? label}) => MutationPlan<S>(
    label: label ?? this.label,
    summary: summary,
    changes: [for (final c in changes.reversed) c.inverse()],
  );

  @override
  String toString() => 'MutationPlan($label, ${changes.length} changes)';
}
