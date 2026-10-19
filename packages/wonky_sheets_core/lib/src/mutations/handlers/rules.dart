import 'dart:convert';

import 'package:wonky_sync_models/ids.dart';

import '../../addressing/grid_geometry.dart';
import '../../addressing/sheet_names.dart';
import '../../content/cell_content.dart';
import '../../model/events.dart';
import '../../model/grid_range.dart';
import '../../model/schema.dart';
import '../../model/sheet_model.dart';
import '../operations.dart';
import '../plan_builder.dart';
import '../row_change.dart';
import 'helpers.dart';

List<String> _sortedCfKeys(PlanBuilder b, SheetModel s, {String? exceptId}) {
  final keys = <String>[];
  for (final r in s.cfRules.values) {
    if (r.id == exceptId) continue;
    final cur = b.current(SheetsTables.conditionalFormatRule, r.id);
    if (cur == null) continue;
    keys.add(cur[Cols.sortKey] as String);
  }
  for (final e in b.touchedRows(SheetsTables.conditionalFormatRule).entries) {
    if (e.key == exceptId || e.value == null || s.cfRules.containsKey(e.key)) {
      continue;
    }
    if (e.value![Cols.sheetId] == s.id) {
      keys.add(e.value![Cols.sortKey] as String);
    }
  }
  keys.sort();
  return keys;
}

String _cfKeyBefore(
  PlanBuilder b,
  SheetModel s,
  String? beforeRuleId, {
  String? exceptId,
}) {
  final keys = _sortedCfKeys(b, s, exceptId: exceptId);
  final beforeKey = beforeRuleId == null
      ? null
      : b.current(
              SheetsTables.conditionalFormatRule,
              beforeRuleId,
            )?[Cols.sortKey]
            as String?;
  return PlanBuilderHelpers.keyBefore(keys, beforeKey);
}

SheetModel _ruleSheet(PlanBuilder b, String table, String id) {
  final cur = b.current(table, id);
  if (cur == null) {
    throw PlanException('not_found', 'Rule not found', details: {'id': id});
  }
  return b.sheetOf(cur[Cols.sheetId] as String);
}

void _checkJson(String json, String what) {
  try {
    final v = jsonDecode(json);
    if (v is! Map) throw const FormatException();
  } on FormatException {
    throw PlanException('invalid_argument', 'Invalid $what JSON');
  }
}

/// [AddCfRule].
MutationPlan planAddCfRule(PlanBuilder b, AddCfRule op) {
  final s = b.sheetOf(op.sheetId);
  _checkJson(op.ruleJson, 'rule');
  if (op.ranges.isEmpty) {
    throw const PlanException(
      'invalid_range',
      'A rule needs at least one range',
    );
  }
  if (s.cfRules.length >= 500) {
    throw const PlanException(
      'limit_exceeded',
      'A sheet can have at most 500 rules',
    );
  }
  for (final r in op.ranges) {
    b.checkRect(s, r);
  }
  final id = op.ruleId ?? b.ctx.ids.newId();
  b.insert(SheetsTables.conditionalFormatRule, id, {
    Cols.sheetId: s.id,
    Cols.sortKey: _cfKeyBefore(b, s, op.beforeRuleId),
    Cols.rangesJson: b.rangesJson(s, op.ranges),
    'ruleJson': op.ruleJson,
    'enabled': true,
  });
  for (final r in op.ranges) {
    b.addResolvedRange(ResolvedRange(s.id, r));
  }
  b.result['ruleId'] = id;
  return b.build('Add conditional formatting', kinds: [ChangeKinds.rules]);
}

/// [UpdateCfRule].
MutationPlan planUpdateCfRule(PlanBuilder b, UpdateCfRule op) {
  final s = _ruleSheet(b, SheetsTables.conditionalFormatRule, op.ruleId);
  if (op.ruleJson != null) _checkJson(op.ruleJson!, 'rule');
  b.update(SheetsTables.conditionalFormatRule, op.ruleId, {
    if (op.ranges != null) Cols.rangesJson: b.rangesJson(s, op.ranges!),
    if (op.ruleJson != null) 'ruleJson': op.ruleJson,
  });
  b.summary.sheets.add(s.id);
  return b.build('Edit conditional formatting', kinds: [ChangeKinds.rules]);
}

/// [DeleteCfRule].
MutationPlan planDeleteCfRule(PlanBuilder b, DeleteCfRule op) {
  final s = _ruleSheet(b, SheetsTables.conditionalFormatRule, op.ruleId);
  b.delete(SheetsTables.conditionalFormatRule, op.ruleId);
  b.summary.sheets.add(s.id);
  return b.build('Delete conditional formatting', kinds: [ChangeKinds.rules]);
}

/// [ReorderCfRule].
MutationPlan planReorderCfRule(PlanBuilder b, ReorderCfRule op) {
  final s = _ruleSheet(b, SheetsTables.conditionalFormatRule, op.ruleId);
  if (op.beforeRuleId == op.ruleId) return b.build('Reorder rules');
  b.update(SheetsTables.conditionalFormatRule, op.ruleId, {
    Cols.sortKey: _cfKeyBefore(b, s, op.beforeRuleId, exceptId: op.ruleId),
  });
  b.summary.sheets.add(s.id);
  return b.build('Reorder rules', kinds: [ChangeKinds.rules]);
}

/// [SetCfEnabled].
MutationPlan planSetCfEnabled(PlanBuilder b, SetCfEnabled op) {
  final s = _ruleSheet(b, SheetsTables.conditionalFormatRule, op.ruleId);
  b.update(SheetsTables.conditionalFormatRule, op.ruleId, {
    'enabled': op.enabled,
  });
  b.summary.sheets.add(s.id);
  return b.build(
    op.enabled ? 'Enable rule' : 'Disable rule',
    kinds: [ChangeKinds.rules],
  );
}

/// Subtracts [rects] from every DV rule of [s] except [exceptId]; rules left
/// empty are deleted (07 §6.4).
void clearValidationIn(
  PlanBuilder b,
  SheetModel s,
  List<GridRect> rects, {
  String? exceptId,
}) {
  for (final rule in s.dvRules.values.toList()) {
    if (rule.id == exceptId) continue;
    final cur = b.current(SheetsTables.dataValidationRule, rule.id);
    if (cur == null) continue;
    final ranges = GridRange.parseList(cur[Cols.rangesJson] as String?);
    final current = [
      for (final g in ranges)
        if (s.resolve(g) case final ResolvedRange r) r.rect,
    ];
    var remaining = current;
    for (final q in rects) {
      remaining = RectSet.subtractAll(remaining, q);
    }
    if (RectSet.sameCells(remaining, current)) continue;
    if (remaining.isEmpty) {
      b.delete(SheetsTables.dataValidationRule, rule.id);
    } else {
      if (remaining.length > 1000) {
        b.warnings.add('Validation ranges were simplified');
        remaining = [RectSet.bounds(remaining)!];
      }
      b.update(SheetsTables.dataValidationRule, rule.id, {
        Cols.rangesJson: b.rangesJson(s, remaining),
      });
    }
  }
}

/// [SetDataValidation].
MutationPlan planSetDataValidation(PlanBuilder b, SetDataValidation op) {
  final s = b.sheetOf(op.sheetId);
  for (final r in op.ranges) {
    b.checkRect(s, r);
    b.addResolvedRange(ResolvedRange(s.id, r));
  }
  if (op.criteriaJson == null) {
    clearValidationIn(b, s, op.ranges);
    if (op.ruleId != null) {
      b.delete(SheetsTables.dataValidationRule, op.ruleId!);
    }
    return b.build('Remove data validation', kinds: [ChangeKinds.rules]);
  }
  _checkJson(op.criteriaJson!, 'criteria');
  clearValidationIn(b, s, op.ranges, exceptId: op.ruleId);
  final style = op.displayStyle ?? 'chip';
  final cols = {
    Cols.sheetId: s.id,
    Cols.rangesJson: b.rangesJson(s, op.ranges),
    'criteriaJson': op.criteriaJson,
    'strict': op.strict,
    'showDropdown': style != 'plainText',
    'displayStyle': style,
    'helpText': op.helpText,
  };
  final id = op.ruleId ?? b.ctx.ids.newId();
  if (op.ruleId != null &&
      b.current(SheetsTables.dataValidationRule, id) != null) {
    b.update(SheetsTables.dataValidationRule, id, cols);
  } else {
    b.insert(SheetsTables.dataValidationRule, id, cols);
  }
  b.result['ruleId'] = id;
  return b.build('Data validation', kinds: [ChangeKinds.rules]);
}

/// [DeleteDvRule].
MutationPlan planDeleteDvRule(PlanBuilder b, DeleteDvRule op) {
  final s = _ruleSheet(b, SheetsTables.dataValidationRule, op.ruleId);
  b.delete(SheetsTables.dataValidationRule, op.ruleId);
  b.summary.sheets.add(s.id);
  return b.build('Remove data validation', kinds: [ChangeKinds.rules]);
}

/// [InsertCheckboxes] (07 §6.7).
MutationPlan planInsertCheckboxes(PlanBuilder b, InsertCheckboxes op) {
  final s = b.sheetOf(op.sheetId);
  final criteria = {
    'type': 'checkbox',
    if (op.checked != null) 'checked': op.checked,
    if (op.unchecked != null) 'unchecked': op.unchecked,
  };
  planSetDataValidation(
    b,
    SetDataValidation(
      s.id,
      op.ranges,
      jsonEncode(criteria),
      displayStyle: 'chip',
    ),
  );
  final unchecked = op.unchecked == null
      ? const BoolContent(false)
      : TextContent(op.unchecked!);
  for (final rect in op.ranges) {
    for (var r = rect.top; r <= rect.bottom; r++) {
      for (var c = rect.left; c <= rect.right; c++) {
        final rowId = s.rows.idAt(r);
        final colId = s.columns.idAt(c);
        if (b.currentContent(s.id, rowId, colId) != null) continue;
        b.writeCell(s.id, rowId, colId, {CellCols.content: unchecked.encode()});
      }
    }
  }
  return b.build(
    'Insert checkbox',
    kinds: [ChangeKinds.rules, ChangeKinds.values],
  );
}

/// [SetBasicFilter].
MutationPlan planSetBasicFilter(PlanBuilder b, SetBasicFilter op) {
  final s = b.sheetOf(op.sheetId);
  b.checkRect(s, op.range);
  if (op.criteriaJson != null) _checkJson(op.criteriaJson!, 'criteria');
  final id = SheetsIds.basicFilterId(s.id);
  final g = s.gridRange(op.range);
  final range = op.openEnded
      ? GridRange(
          sheetId: g.sheetId,
          r1: g.r1,
          r1k: g.r1k,
          c1: g.c1,
          c2: g.c2,
          c1k: g.c1k,
          c2k: g.c2k,
        )
      : g;
  final cols = {
    Cols.sheetId: s.id,
    Cols.rangeJson: range.encode(),
    'criteriaJson': op.criteriaJson ?? '{}',
    'sortJson': op.sortJson,
  };
  if (b.current(SheetsTables.basicFilter, id) != null) {
    b.update(SheetsTables.basicFilter, id, cols);
  } else {
    b.insert(SheetsTables.basicFilter, id, cols);
  }
  b.addResolvedRange(ResolvedRange(s.id, op.range));
  return b.build('Create a filter', kinds: [ChangeKinds.filters]);
}

/// [SetFilterColumnCriteria].
MutationPlan planSetFilterColumnCriteria(
  PlanBuilder b,
  SetFilterColumnCriteria op,
) {
  final s = b.sheetOf(op.sheetId);
  final table = op.viewId == null
      ? SheetsTables.basicFilter
      : SheetsTables.filterView;
  final id = op.viewId ?? SheetsIds.basicFilterId(s.id);
  final cur = b.current(table, id);
  if (cur == null) throw const PlanException('not_found', 'Filter not found');
  final criteria = PlanBuilderHelpers.decodeMap(cur['criteriaJson'] as String?);
  // Drop columns that no longer exist.
  criteria.removeWhere((k, _) => !s.columns.contains(k));
  if (op.criteria == null) {
    criteria.remove(op.colId);
  } else {
    criteria[op.colId] = op.criteria;
  }
  b.update(table, id, {'criteriaJson': jsonEncode(criteria)});
  b.summary.sheets.add(s.id);
  return b.build('Filter', kinds: [ChangeKinds.filters]);
}

/// [RemoveBasicFilter].
MutationPlan planRemoveBasicFilter(PlanBuilder b, RemoveBasicFilter op) {
  final s = b.sheetOf(op.sheetId);
  b.delete(SheetsTables.basicFilter, SheetsIds.basicFilterId(s.id));
  if (s.basicFilter != null) {
    b.delete(SheetsTables.basicFilter, s.basicFilter!.id);
  }
  b.summary.sheets.add(s.id);
  return b.build('Remove filter', kinds: [ChangeKinds.filters]);
}

/// [CreateFilterView].
MutationPlan planCreateFilterView(PlanBuilder b, CreateFilterView op) {
  final s = b.sheetOf(op.sheetId);
  b.checkRect(s, op.range);
  final id = op.viewId ?? b.ctx.ids.newId();
  var name = op.name;
  if (name == null) {
    final taken = {for (final v in s.filterViews.values) v.name?.toLowerCase()};
    for (var i = 1; ; i++) {
      if (!taken.contains('filter $i')) {
        name = 'Filter $i';
        break;
      }
    }
  }
  b.insert(SheetsTables.filterView, id, {
    Cols.sheetId: s.id,
    Cols.name: name,
    Cols.rangeJson: b.rangeJson(s, op.range),
    'criteriaJson': op.criteriaJson ?? '{}',
    'sortJson': op.sortJson,
    Cols.createdBy: b.ctx.userId,
  });
  b.result['viewId'] = id;
  b.summary.sheets.add(s.id);
  return b.build('Create filter view', kinds: [ChangeKinds.filters]);
}

/// [UpdateFilterView].
MutationPlan planUpdateFilterView(PlanBuilder b, UpdateFilterView op) {
  final s = _ruleSheet(b, SheetsTables.filterView, op.viewId);
  if (op.range != null) b.checkRect(s, op.range!);
  b.update(SheetsTables.filterView, op.viewId, {
    if (op.name != null) Cols.name: op.name,
    if (op.range != null) Cols.rangeJson: b.rangeJson(s, op.range!),
    if (op.criteriaJson != null) 'criteriaJson': op.criteriaJson,
    if (op.sortJson != null) 'sortJson': op.sortJson,
  });
  b.summary.sheets.add(s.id);
  return b.build('Edit filter view', kinds: [ChangeKinds.filters]);
}

/// [DeleteFilterView].
MutationPlan planDeleteFilterView(PlanBuilder b, DeleteFilterView op) {
  final s = _ruleSheet(b, SheetsTables.filterView, op.viewId);
  b.delete(SheetsTables.filterView, op.viewId);
  b.summary.sheets.add(s.id);
  return b.build('Delete filter view', kinds: [ChangeKinds.filters]);
}

// ---------------------------------------------------------------------------
// Named ranges (07 §8).

final RegExp _nameRe = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

/// Validates a range/function name (07 §8.2); returns null or the message.
String? namedRangeNameError(String name) {
  if (name.isEmpty || name.length > 250 || !_nameRe.hasMatch(name)) {
    return 'Range names must contain only letters, numbers, and underscores.';
  }
  final lower = name.toLowerCase();
  if (lower.startsWith('true') || lower.startsWith('false')) {
    return 'Range names cannot start with a number, or the words "true" or "false".';
  }
  if (SheetNames.looksLikeCell(name) || SheetNames.looksLikeR1C1(name)) {
    return 'Range names can\'t look like a cell reference (e.g. "A1" or "R1C1").';
  }
  return null;
}

void _validateName(PlanBuilder b, String name, {String? exceptId}) {
  final err = namedRangeNameError(name);
  if (err != null) throw PlanException('invalid_argument', err);
  final lower = name.toLowerCase();
  for (final n in b.model.namedRanges) {
    if (n.id == exceptId) continue;
    final cur = b.current(SheetsTables.namedRange, n.id);
    if (cur != null && (cur[Cols.name] as String).toLowerCase() == lower) {
      throw const PlanException(
        'duplicate_name',
        'A range with this name already exists.',
      );
    }
  }
}

/// [AddNamedRange].
MutationPlan planAddNamedRange(PlanBuilder b, AddNamedRange op) {
  _validateName(b, op.name);
  if (op.range == null && op.formula == null) {
    throw const PlanException(
      'invalid_argument',
      'A named range needs a range or a formula',
    );
  }
  String? rangeJson;
  if (op.range != null) {
    final s = b.sheetOf(op.range!.sheetId);
    rangeJson = b.rangeJson(
      s,
      op.range!.rect,
      wholeRows: op.range!.wholeRows,
      wholeColumns: op.range!.wholeColumns,
    );
  }
  final id = op.id ?? b.ctx.ids.newId();
  b.insert(SheetsTables.namedRange, id, {
    Cols.spreadsheetId: b.model.spreadsheetId,
    Cols.name: op.name,
    Cols.rangeJson: rangeJson,
    'formula': op.formula,
    'comment': op.comment,
    'metaJson': op.metaJson,
  });
  b.result['namedRangeId'] = id;
  return b.build(
    op.formula != null && op.range == null
        ? 'Add named function'
        : 'Add named range',
    kinds: [ChangeKinds.names],
  );
}

/// [UpdateNamedRange]: renames rewrite formulas using the old name.
MutationPlan planUpdateNamedRange(PlanBuilder b, UpdateNamedRange op) {
  final cur = b.current(SheetsTables.namedRange, op.id);
  if (cur == null) {
    throw const PlanException('not_found', 'Named range not found');
  }
  final oldName = cur[Cols.name] as String;
  final writes = <String, Object?>{};
  if (op.name != null && op.name != oldName) {
    _validateName(b, op.name!, exceptId: op.id);
    writes[Cols.name] = op.name;
  }
  if (op.range != null) {
    final s = b.sheetOf(op.range!.sheetId);
    writes[Cols.rangeJson] = b.rangeJson(
      s,
      op.range!.rect,
      wholeRows: op.range!.wholeRows,
      wholeColumns: op.range!.wholeColumns,
    );
  }
  if (op.formula != null) writes['formula'] = op.formula;
  if (op.comment != null) writes['comment'] = op.comment;
  if (op.metaJson != null) writes['metaJson'] = op.metaJson;
  b.update(SheetsTables.namedRange, op.id, writes);
  if (writes.containsKey(Cols.name)) {
    renameNameInFormulas(b, oldName, op.name!);
  }
  return b.build('Edit named range', kinds: [ChangeKinds.names]);
}

/// Rewrites every formula (cells, rules, named functions) using [oldName].
void renameNameInFormulas(PlanBuilder b, String oldName, String newName) {
  final hooks = b.ctx.formulas;
  if (hooks == null) return;
  final lower = oldName.toLowerCase();
  String? rewrite(String f) {
    if (!f.toLowerCase().contains(lower)) return null;
    final r = hooks.renameName(f, oldName, newName);
    return r == f ? null : r;
  }

  for (final s in b.model.sheets) {
    for (final cell in s.cells.formulaCells) {
      final content = cell.content;
      if (content == null || !content.startsWith('=')) continue;
      final r = rewrite(content);
      if (r != null) {
        b.update(SheetsTables.cell, cell.id, {CellCols.content: r});
      }
    }
    void json(String table, Iterable<(String, String?)> rows, String column) {
      for (final (id, j) in rows) {
        if (j == null || !j.toLowerCase().contains(lower)) continue;
        final (out, changed) = StoredFormulaJson.map(j, rewrite);
        if (changed) b.update(table, id, {column: out});
      }
    }

    json(SheetsTables.conditionalFormatRule, [
      for (final r in s.cfRules.values) (r.id, r.ruleJson),
    ], 'ruleJson');
    json(SheetsTables.dataValidationRule, [
      for (final r in s.dvRules.values) (r.id, r.criteriaJson),
    ], 'criteriaJson');
  }
  for (final n in b.model.namedRanges) {
    final f = n.formula;
    if (f == null) continue;
    final r = rewrite(f);
    if (r != null) b.update(SheetsTables.namedRange, n.id, {'formula': r});
  }
}

/// JSON string helpers for formulas embedded in rule JSON.
abstract final class StoredFormulaJson {
  /// Applies [f] to `=` strings in [json]; returns `(newJson, changed)`.
  static (String, bool) map(String json, String? Function(String) f) {
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return (json, false);
    }
    var changed = false;
    Object? walk(Object? v) {
      if (v is String && v.startsWith('=')) {
        final r = f(v);
        if (r != null && r != v) {
          changed = true;
          return r;
        }
        return v;
      }
      if (v is List) return [for (final e in v) walk(e)];
      if (v is Map) return {for (final e in v.entries) e.key: walk(e.value)};
      return v;
    }

    final out = walk(decoded);
    return (changed ? jsonEncode(out) : json, changed);
  }
}

/// [DeleteNamedRange].
MutationPlan planDeleteNamedRange(PlanBuilder b, DeleteNamedRange op) {
  if (b.current(SheetsTables.namedRange, op.id) == null) {
    throw const PlanException('not_found', 'Named range not found');
  }
  b.delete(SheetsTables.namedRange, op.id);
  return b.build('Delete named range', kinds: [ChangeKinds.names]);
}

// ---------------------------------------------------------------------------
// Protections (07 §10).

/// [AddProtection].
MutationPlan planAddProtection(PlanBuilder b, AddProtection op) {
  final s = b.sheetOf(op.sheetId);
  if (op.range != null) b.checkRect(s, op.range!);
  final id = op.id ?? b.ctx.ids.newId();
  b.insert(SheetsTables.protectedRange, id, {
    Cols.sheetId: s.id,
    Cols.rangeJson: op.range == null ? null : b.rangeJson(s, op.range!),
    'exceptRangesJson': op.exceptRanges.isEmpty
        ? null
        : b.rangesJson(s, op.exceptRanges),
    'description': op.description,
    'warningOnly': op.warningOnly,
    'editorsJson': jsonEncode(op.editors),
    Cols.createdBy: b.ctx.userId,
  });
  b.result['protectionId'] = id;
  b.summary.sheets.add(s.id);
  return b.build(
    op.range == null ? 'Protect sheet' : 'Protect range',
    kinds: [ChangeKinds.protection],
  );
}

/// [UpdateProtection].
MutationPlan planUpdateProtection(PlanBuilder b, UpdateProtection op) {
  final s = _ruleSheet(b, SheetsTables.protectedRange, op.id);
  if (op.range != null) b.checkRect(s, op.range!);
  b.update(SheetsTables.protectedRange, op.id, {
    if (op.range != null) Cols.rangeJson: b.rangeJson(s, op.range!),
    if (op.wholeSheet) Cols.rangeJson: null,
    if (op.exceptRanges != null)
      'exceptRangesJson': op.exceptRanges!.isEmpty
          ? null
          : b.rangesJson(s, op.exceptRanges!),
    if (op.description != null) 'description': op.description,
    if (op.warningOnly != null) 'warningOnly': op.warningOnly,
    if (op.editors != null) 'editorsJson': jsonEncode(op.editors),
  });
  return b.build('Edit protection', kinds: [ChangeKinds.protection]);
}

/// [DeleteProtection].
MutationPlan planDeleteProtection(PlanBuilder b, DeleteProtection op) {
  _ruleSheet(b, SheetsTables.protectedRange, op.id);
  b.delete(SheetsTables.protectedRange, op.id);
  return b.build('Remove protection', kinds: [ChangeKinds.protection]);
}

// ---------------------------------------------------------------------------
// Banding (06 §14).

/// [AddBanding]: replaces overlapping bandings.
MutationPlan planAddBanding(PlanBuilder b, AddBanding op) {
  final s = b.sheetOf(op.sheetId);
  b.checkRect(s, op.range);
  for (final id in s.rulesIntersecting(RuleKind.banding, op.range)) {
    b.delete(SheetsTables.banding, id);
  }
  final id = op.id ?? b.ctx.ids.newId();
  b.insert(SheetsTables.banding, id, {
    Cols.sheetId: s.id,
    Cols.rangeJson: b.rangeJson(s, op.range),
    'styleJson': op.styleJson,
  });
  b.result['bandingId'] = id;
  b.addResolvedRange(ResolvedRange(s.id, op.range));
  return b.build('Alternating colors', kinds: [ChangeKinds.format]);
}

/// [UpdateBanding].
MutationPlan planUpdateBanding(PlanBuilder b, UpdateBanding op) {
  final s = _ruleSheet(b, SheetsTables.banding, op.id);
  if (op.range != null) {
    b.checkRect(s, op.range!);
    for (final other in s.rulesIntersecting(RuleKind.banding, op.range!)) {
      if (other != op.id) b.delete(SheetsTables.banding, other);
    }
  }
  b.update(SheetsTables.banding, op.id, {
    if (op.range != null) Cols.rangeJson: b.rangeJson(s, op.range!),
    if (op.styleJson != null) 'styleJson': op.styleJson,
  });
  return b.build('Alternating colors', kinds: [ChangeKinds.format]);
}

/// [RemoveBanding].
MutationPlan planRemoveBanding(PlanBuilder b, RemoveBanding op) {
  _ruleSheet(b, SheetsTables.banding, op.id);
  b.delete(SheetsTables.banding, op.id);
  return b.build('Remove alternating colors', kinds: [ChangeKinds.format]);
}
