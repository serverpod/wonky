import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../features/data_tools/data_job.dart';
import '../features/data_tools/data_tools.dart';
import '../features/filters/filter_controller.dart';
import '../features/grid/selection/grid_selection.dart';
import '../features/sheet_editor/sheet_editor_controller.dart';
import 'sheets_command.dart';
import 'sort_commands.dart' show applyKeepingSelection;

String _data(SheetsLocalizations l) => l.categoryData;

/// Panel id of the filter views list (04 §10).
const filterViewsPanelId = 'sheets.panel.filterViews';

FilterController _filters(SheetEditorController ed) => DataTools.of(ed).filters;

/// The range a new filter / filter view covers (07 §3.6): a multi-cell
/// selection, else the data region around the active cell.
GridRect? filterRangeFor(SheetEditorController ed) {
  final s = ed.activeSheet;
  if (s == null || s.rows.length == 0 || s.columns.length == 0) return null;
  final sel = ed.selection.resolved;
  final range = sel.activeRange;
  final grid = GridRect(0, 0, s.rows.length - 1, s.columns.length - 1);
  if (range.rect.cellCount > 1) {
    final r = range.rect.intersection(grid) ?? range.rect;
    if (range.kind == SelectionKind.cells) return r;
    final used = s.usedRect();
    if (used == null) return null;
    return GridRect(
      range.wholeColumns ? 0 : r.top,
      range.wholeRows ? used.left : r.left,
      range.wholeColumns ? used.bottom : r.bottom,
      range.wholeRows ? used.right : r.right,
    ).intersection(grid);
  }
  return ed.edgeFinder().region(sel.activeRow, sel.activeCol) ??
      GridRect.cell(sel.activeRow, sel.activeCol);
}

/// Parses `criteria` (a column criteria JSON map, or null to clear).
ColumnCriteria? criteriaArg(JsonArgs a) {
  final v = a.values['criteria'];
  if (v == null) return null;
  final c = ColumnCriteria.fromJson(v is String ? jsonDecode(v) : v);
  return c.isEmpty ? null : c;
}

/// The sheet holding saved or temporary filter view [viewId].
String? viewSheetOf(SheetEditorController ed, String viewId) {
  final temp = _filters(ed).temporaryView(viewId);
  if (temp != null) return temp.sheetId;
  for (final s in ed.model.sheets) {
    if (s.filterViews.containsKey(viewId)) return s.id;
  }
  return null;
}

/// A command whose effect is a synced write for saved filter views (one
/// undo step) but local state for temporary ones (viewers may use it):
/// always opens an undo transaction (empty ones are dropped).
class _ViewCommand extends SheetsCommand {
  _ViewCommand(
    super.id, {
    required super.label,
    required super.run,
    super.icon,
    super.argsSchema,
    super.enabled,
    super.showInPalette,
  }) : super(categoryName: _data);

  @override
  bool get isUndoable => true;
}

String _viewIdArg(SheetEditorController ed, JsonArgs a) {
  final id = a.string('viewId') ?? _filters(ed).activeViewId(ed.activeSheetId);
  if (id == null) throw PlanException('not_found', ed.l10n.filterViewNone);
  return id;
}

bool _isTemp(String viewId) => viewId.startsWith('temp:');

void _requireEdit(SheetEditorController ed) {
  if (!ed.canEdit) {
    throw PlanException(
      'forbidden',
      ed.roleCanEdit ? ed.l10n.reasonViewingMode : ed.l10n.reasonViewAccess,
    );
  }
}

/// Basic filter and filter view commands (07 §3–4, §20).
List<Command<CommandArgs>> filterCommands(ShellServices s) => [
  SheetsCommand(
    'sheets.filter.toggle',
    label: (l) => l.cmdFilterToggle,
    dynamicLabel: (l, ed) => ed.activeSheet?.basicFilter == null
        ? l.cmdFilterToggle
        : l.cmdFilterRemove,
    icon: LucideIcons.funnel,
    categoryName: _data,
    mutates: true,
    defaultBindings: const [KeyBinding('L', mod: true, alt: true, shift: true)],
    argsSchema: const JsonSchema.object(
      properties: {
        'range': JsonSchema.string(description: 'A1 range (create only).'),
      },
    ),
    run: (ctx, ed, a) {
      final sheet = ed.activeSheet!;
      if (sheet.basicFilter != null) {
        _filters(ed).popover.value = null;
        ed.apply(ctx, RemoveBasicFilter(sheet.id));
        return ok({'removed': true});
      }
      final explicit = a.string('range') != null;
      final range = explicit ? rangeArg(ed, a).rect : filterRangeFor(ed);
      if (range == null) return const CommandResult.cancelled();
      // A data region that reaches the last used row stays open-ended so
      // rows typed below join the filter (07 §3.6).
      final used = sheet.usedRect();
      final openEnded =
          !explicit &&
          ed.selection.resolved.activeRange.rect.cellCount == 1 &&
          used != null &&
          range.bottom >= used.bottom;
      ed.apply(ctx, SetBasicFilter(sheet.id, range, openEnded: openEnded));
      return ok({'range': range.a1, 'openEnded': openEnded});
    },
  ),
  SheetsCommand(
    'sheets.filter.setRange',
    label: (l) => l.cmdFilterSetRange,
    categoryName: _data,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'range': JsonSchema.string()},
      required: ['range'],
    ),
    run: (ctx, ed, a) {
      final f = _filters(ed).basicFilter(ed.activeSheetId);
      final r = rangeArg(ed, a).rect;
      final sheet = ed.activeSheet!;
      final keep = {
        for (var c = r.left; c <= r.right; c++) sheet.columns.idAt(c),
      };
      ed.apply(
        ctx,
        SetBasicFilter(
          sheet.id,
          r,
          criteriaJson: f?.criteria.retain(keep).encode(),
          sortJson: sheet.basicFilter?.sortJson,
        ),
      );
      return ok({'range': r.a1});
    },
  ),
  SheetsCommand(
    'sheets.filter.openColumnMenu',
    label: (l) => l.cmdFilterOpenColumnMenu,
    categoryName: _data,
    defaultBindings: const [KeyBinding('R', mod: true, alt: true)],
    argsSchema: const JsonSchema.object(
      properties: {'colId': JsonSchema.string()},
    ),
    enabled: (ed, a) {
      final f = _filters(ed).effective(ed.activeSheetId);
      if (f == null) return false;
      final col = ed.selection.resolved.activeCol;
      return a.string('colId') != null ||
          (col >= f.range.left && col <= f.range.right);
    },
    run: (ctx, ed, a) {
      final filters = _filters(ed);
      final f = filters.effective(ed.activeSheetId)!;
      final sheet = ed.activeSheet!;
      final colId =
          a.string('colId') ??
          sheet.columns.idAt(ed.selection.resolved.activeCol);
      final col = sheet.columns.indexOf(colId);
      if (col < f.range.left || col > f.range.right) {
        return const CommandResult.failed('Column is not in the filter');
      }
      ed.revealCell(f.range.top, col);
      final g = ed.geometry;
      final cell = g?.cellRect(f.range.top, col) ?? Rect.zero;
      filters.popover.value = FilterPopoverRequest(
        sheet.id,
        colId,
        Rect.fromLTWH(cell.right - 18, cell.top, 18, cell.height),
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.filter.setColumnCriteria',
    label: (l) => l.cmdFilterSetColumnCriteria,
    categoryName: _data,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'colId': JsonSchema.string(),
        'criteria': JsonSchema.nullable(
          JsonSchema.object(
            additionalProperties: true,
            description:
                '{hiddenValues: [...], condition: {type, values}, '
                'visibleBackgroundColor, visibleForegroundColor}; null clears.',
          ),
        ),
      },
      required: ['colId'],
    ),
    enabled: (ed, a) => ed.activeSheet?.basicFilter != null,
    run: (ctx, ed, a) {
      final c = criteriaArg(a);
      ed.apply(
        ctx,
        SetFilterColumnCriteria(
          ed.activeSheetId,
          a.requireString('colId'),
          c?.toJson(),
        ),
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.filter.clearColumn',
    label: (l) => l.cmdFilterClearColumn,
    categoryName: _data,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'colId': JsonSchema.string()},
      required: ['colId'],
    ),
    enabled: (ed, a) => ed.activeSheet?.basicFilter != null,
    run: (ctx, ed, a) {
      ed.apply(
        ctx,
        SetFilterColumnCriteria(
          ed.activeSheetId,
          a.requireString('colId'),
          null,
        ),
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.filter.clearAll',
    label: (l) => l.cmdFilterClearAll,
    categoryName: _data,
    mutates: true,
    enabled: (ed, a) =>
        !(_filters(ed).basicFilter(ed.activeSheetId)?.criteria.isEmpty ?? true),
    run: (ctx, ed, a) {
      final f = _filters(ed).basicFilter(ed.activeSheetId)!;
      ed.apply(
        ctx,
        SetBasicFilter(
          ed.activeSheetId,
          f.range,
          criteriaJson: '{}',
          sortJson: ed.activeSheet?.basicFilter?.sortJson,
          openEnded: _filters(ed).basicOpenEnded(ed.activeSheetId),
        ),
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.filter.sortColumn',
    label: (l) => l.cmdFilterSortColumn,
    categoryName: _data,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'colId': JsonSchema.string(),
        'ascending': JsonSchema.boolean(),
        'fillColor': JsonSchema.string(
          description: 'Sort by color (P2): rows with this fill first.',
        ),
        'textColor': JsonSchema.string(
          description: 'Sort by color (P2): rows with this text color first.',
        ),
      },
      required: ['colId'],
    ),
    enabled: (ed, a) => ed.activeSheet?.basicFilter != null,
    undoLabelOf: (l, a) => l.cmdDataSortRange,
    run: (ctx, ed, a) async {
      final filters = _filters(ed);
      final f = filters.basicFilter(ed.activeSheetId)!;
      final colId = a.requireString('colId');
      final asc = a.boolean('ascending') ?? true;
      final fill = a.string('fillColor');
      final text = a.string('textColor');
      final spec = SortKeySpec(
        colId,
        ascending: asc,
        fillColor: fill,
        textColor: fill == null ? text : null,
      );
      if (f.range.rowCount > 2) {
        final op = SortRange(ResolvedRange(ed.activeSheetId, f.range), [
          spec,
        ], hasHeader: true);
        await DataJobs.run(
          ed,
          rows: f.range.rowCount,
          label: ed.l10n.dataJobSorting(f.range.rowCount),
          op: op,
          work: () => applyKeepingSelection(ctx, ed, op),
        );
      }
      ed.apply(
        ctx,
        SetBasicFilter(
          ed.activeSheetId,
          f.range,
          criteriaJson: f.criteria.encode(),
          sortJson: jsonEncode([
            fill != null
                ? {'colId': colId, 'fillColor': fill}
                : text != null
                ? {'colId': colId, 'textColor': text}
                : {'colId': colId, 'ascending': asc},
          ]),
          openEnded: filters.basicOpenEnded(ed.activeSheetId),
        ),
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.filter.byCellValue',
    label: (l) => l.cmdFilterByCellValue,
    icon: LucideIcons.funnel,
    categoryName: _data,
    mutates: true,
    run: (ctx, ed, a) {
      final sheet = ed.activeSheet!;
      final filters = _filters(ed);
      final sel = ed.selection.resolved;
      var f = filters.basicFilter(sheet.id);
      if (f == null || !f.range.contains(sel.activeRow, sel.activeCol)) {
        final range = ed.edgeFinder().region(sel.activeRow, sel.activeCol);
        if (range == null || range.rowCount < 2) {
          return CommandResult.failed(ed.l10n.filterByValueNoData);
        }
        ed.apply(ctx, SetBasicFilter(sheet.id, range));
        filters.refresh(sheet.id);
        f = filters.basicFilter(sheet.id)!;
      }
      if (sel.activeRow == f.range.top) {
        return CommandResult.failed(ed.l10n.filterByValueHeader);
      }
      final col = sel.activeCol;
      final text = filters.source(sheet.id).displayTextAt(sel.activeRow, col);
      final entries = filters.checklist(f, col);
      final hidden = [
        for (final e in entries)
          if (e.text != text) e.text,
      ];
      ed.apply(
        ctx,
        SetFilterColumnCriteria(
          sheet.id,
          sheet.columns.idAt(col),
          ColumnCriteria(hiddenValues: hidden).toJson(),
        ),
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.filter.saveAsFilterView',
    label: (l) => l.cmdFilterSaveAsView,
    categoryName: _data,
    mutates: true,
    enabled: (ed, a) => ed.activeSheet?.basicFilter != null,
    run: (ctx, ed, a) {
      final filters = _filters(ed);
      final f = filters.basicFilter(ed.activeSheetId)!;
      final plan = ed.apply(
        ctx,
        CreateFilterView(
          ed.activeSheetId,
          f.range,
          criteriaJson: f.criteria.encode(),
          sortJson: ed.activeSheet?.basicFilter?.sortJson,
        ),
      );
      final id = plan.result['viewId'] as String?;
      if (id != null) filters.activate(ed.activeSheetId, id);
      return ok({'viewId': id});
    },
  ),

  // ---- Filter views (07 §4) ----
  _ViewCommand(
    'sheets.filterView.create',
    label: (l) => l.cmdFilterViewCreate,
    icon: LucideIcons.listFilter,
    argsSchema: const JsonSchema.object(
      properties: {
        'temporary': JsonSchema.boolean(),
        'fromBasicFilter': JsonSchema.boolean(),
        'name': JsonSchema.string(),
      },
    ),
    run: (ctx, ed, a) {
      final filters = _filters(ed);
      final sid = ed.activeSheetId;
      final basic = filters.basicFilter(sid);
      final range = basic?.range ?? filterRangeFor(ed);
      if (range == null) return const CommandResult.cancelled();
      final from = a.boolean('fromBasicFilter') ?? false;
      final criteria = from ? basic?.criteria : null;
      final temporary = (a.boolean('temporary') ?? false) || !ed.canEdit;
      if (temporary) {
        final v = filters.createTemporary(
          sid,
          ed.activeSheet!.gridRange(range),
          criteria: criteria,
          name: a.string('name'),
        );
        return ok({'viewId': v.id, 'temporary': true});
      }
      final plan = ed.apply(
        ctx,
        CreateFilterView(
          sid,
          range,
          name: a.string('name'),
          criteriaJson: criteria?.encode(),
        ),
      );
      final id = plan.result['viewId'] as String?;
      if (id != null) filters.activate(sid, id);
      return ok({'viewId': id});
    },
  ),
  SheetsCommand(
    'sheets.filterView.activate',
    label: (l) => l.cmdFilterViewActivate,
    categoryName: _data,
    argsSchema: const JsonSchema.object(
      properties: {
        'viewId': JsonSchema.nullable(
          JsonSchema.string(description: 'null closes the view.'),
        ),
      },
    ),
    checked: (ed, a) {
      final id = a.string('viewId');
      final active = _filters(ed).activeViewId(ed.activeSheetId);
      return a.values.containsKey('viewId') ? active == id : null;
    },
    run: (ctx, ed, a) {
      final id = a.string('viewId');
      final filters = _filters(ed);
      if (id == null) {
        filters.activate(ed.activeSheetId, null);
        return ok();
      }
      final sid = viewSheetOf(ed, id);
      if (sid == null) {
        return CommandResult.failed(ed.l10n.filterViewDeletedToast);
      }
      if (sid != ed.activeSheetId) ed.activateSheet(sid);
      filters.activate(sid, id);
      final f = filters.effective(sid);
      if (f != null) ed.revealCell(f.range.top, f.range.left);
      return ok();
    },
  ),
  _ViewCommand(
    'sheets.filterView.rename',
    label: (l) => l.cmdFilterViewRename,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'viewId': JsonSchema.string(), 'name': JsonSchema.string()},
      required: ['name'],
    ),
    run: (ctx, ed, a) {
      final id = _viewIdArg(ed, a);
      final name = a.requireString('name').trim();
      if (name.isEmpty) return const CommandResult.cancelled();
      if (_isTemp(id)) {
        _filters(ed).updateTemporary(id, name: name);
      } else {
        _requireEdit(ed);
        ed.apply(ctx, UpdateFilterView(id, name: name));
      }
      return ok();
    },
  ),
  _ViewCommand(
    'sheets.filterView.setRange',
    label: (l) => l.cmdFilterViewSetRange,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'viewId': JsonSchema.string(), 'range': JsonSchema.string()},
      required: ['range'],
    ),
    run: (ctx, ed, a) {
      final id = _viewIdArg(ed, a);
      final sid = viewSheetOf(ed, id) ?? ed.activeSheetId;
      final r = ed.model.parseA1(a.requireString('range'), contextSheetId: sid);
      if (_isTemp(id)) {
        _filters(
          ed,
        ).updateTemporary(id, range: ed.model.sheet(sid)!.gridRange(r.rect));
      } else {
        _requireEdit(ed);
        ed.apply(ctx, UpdateFilterView(id, range: r.rect));
      }
      return ok();
    },
  ),
  // View-only sort (07 §4.4): reorders this view's rows on screen; the data
  // and other people's screens don't change. No colId clears it.
  _ViewCommand(
    'sheets.filterView.sortColumn',
    label: (l) => l.cmdFilterViewSortColumn,
    icon: LucideIcons.arrowDownAZ,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'viewId': JsonSchema.string(),
        'colId': JsonSchema.string(
          description: 'Column to sort by; omit to clear the view sort.',
        ),
        'ascending': JsonSchema.boolean(),
      },
    ),
    run: (ctx, ed, a) {
      final id = _viewIdArg(ed, a);
      final colId = a.string('colId');
      final sort = colId == null
          ? const <(String, bool)>[]
          : [(colId, a.boolean('ascending') ?? true)];
      if (_isTemp(id)) {
        _filters(ed).updateTemporary(id, sort: sort);
      } else {
        _requireEdit(ed);
        ed.apply(
          ctx,
          UpdateFilterView(
            id,
            sortJson: jsonEncode([
              for (final (c, asc) in sort) {'colId': c, 'ascending': asc},
            ]),
          ),
        );
      }
      return ok({'sorted': colId != null});
    },
  ),
  _ViewCommand(
    'sheets.filterView.setColumnCriteria',
    label: (l) => l.cmdFilterSetColumnCriteria,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'viewId': JsonSchema.string(),
        'colId': JsonSchema.string(),
        'criteria': JsonSchema.nullable(
          JsonSchema.object(additionalProperties: true),
        ),
      },
      required: ['colId'],
    ),
    run: (ctx, ed, a) {
      final id = _viewIdArg(ed, a);
      final colId = a.requireString('colId');
      final c = criteriaArg(a);
      final filters = _filters(ed);
      if (_isTemp(id)) {
        final v = filters.temporaryView(id)!;
        filters.updateTemporary(id, criteria: v.criteria.withColumn(colId, c));
      } else {
        _requireEdit(ed);
        ed.apply(
          ctx,
          SetFilterColumnCriteria(
            viewSheetOf(ed, id)!,
            colId,
            c?.toJson(),
            viewId: id,
          ),
        );
      }
      return ok();
    },
  ),
  _ViewCommand(
    'sheets.filterView.duplicate',
    label: (l) => l.cmdFilterViewDuplicate,
    argsSchema: const JsonSchema.object(
      properties: {'viewId': JsonSchema.string()},
    ),
    enabled: (ed, a) =>
        a.string('viewId') != null ||
        _filters(ed).activeViewId(ed.activeSheetId) != null,
    run: (ctx, ed, a) {
      final id = _viewIdArg(ed, a);
      final filters = _filters(ed);
      final sid = viewSheetOf(ed, id)!;
      final v = filters.view(sid, id)!;
      final name = ed.l10n.filterViewCopyOf(v.name ?? '');
      if (_isTemp(id) || !ed.canEdit) {
        final t = filters.createTemporary(
          sid,
          ed.model.sheet(sid)!.gridRange(v.range),
          criteria: v.criteria,
          name: name,
        );
        return ok({'viewId': t.id});
      }
      final plan = ed.apply(
        ctx,
        CreateFilterView(
          sid,
          v.range,
          name: name,
          criteriaJson: v.criteria.encode(),
          sortJson: ed.model.sheet(sid)!.filterViews[id]?.sortJson,
        ),
      );
      final nid = plan.result['viewId'] as String?;
      if (nid != null) filters.activate(sid, nid);
      return ok({'viewId': nid});
    },
  ),
  SheetsCommand(
    'sheets.filterView.save',
    label: (l) => l.cmdFilterViewSave,
    categoryName: _data,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'tempId': JsonSchema.string()},
    ),
    enabled: (ed, a) {
      final id =
          a.string('tempId') ?? _filters(ed).activeViewId(ed.activeSheetId);
      return id != null && _isTemp(id);
    },
    run: (ctx, ed, a) {
      final filters = _filters(ed);
      final id = a.string('tempId') ?? filters.activeViewId(ed.activeSheetId)!;
      final t = filters.temporaryView(id);
      if (t == null) return const CommandResult.failed('Not found');
      final v = filters.view(t.sheetId, id)!;
      final plan = ed.apply(
        ctx,
        CreateFilterView(
          t.sheetId,
          v.range,
          name: t.name,
          criteriaJson: t.criteria.encode(),
        ),
      );
      final nid = plan.result['viewId'] as String?;
      filters.deleteTemporary(id);
      if (nid != null) filters.activate(t.sheetId, nid);
      return ok({'viewId': nid});
    },
  ),
  _ViewCommand(
    'sheets.filterView.delete',
    label: (l) => l.cmdFilterViewDelete,
    icon: LucideIcons.trash2,
    argsSchema: const JsonSchema.object(
      properties: {'viewId': JsonSchema.string()},
    ),
    enabled: (ed, a) =>
        a.string('viewId') != null ||
        _filters(ed).activeViewId(ed.activeSheetId) != null,
    run: (ctx, ed, a) {
      final id = _viewIdArg(ed, a);
      final filters = _filters(ed);
      if (_isTemp(id)) {
        filters.deleteTemporary(id);
        return ok();
      }
      _requireEdit(ed);
      final sid = viewSheetOf(ed, id);
      if (sid != null && filters.activeViewId(sid) == id) {
        filters.activate(sid, null);
      }
      ed.apply(ctx, DeleteFilterView(id));
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.filterView.copyLink',
    label: (l) => l.cmdFilterViewCopyLink,
    icon: LucideIcons.link,
    categoryName: _data,
    argsSchema: const JsonSchema.object(
      properties: {'viewId': JsonSchema.string()},
    ),
    enabled: (ed, a) {
      final id =
          a.string('viewId') ?? _filters(ed).activeViewId(ed.activeSheetId);
      return id != null && !_isTemp(id);
    },
    run: (ctx, ed, a) async {
      final id = _viewIdArg(ed, a);
      final sid = viewSheetOf(ed, id) ?? ed.activeSheetId;
      final url = s.urls.urlFor(
        s.config.app,
        '/s/${ed.session.itemUuid.uuid}?sheet=$sid&fv=$id',
      );
      await Clipboard.setData(ClipboardData(text: url));
      s.toasts.show(ed.l10n.toastLinkCopied);
      return ok({'url': url});
    },
  ),
  SheetsCommand(
    'sheets.filterView.openPanel',
    label: (l) => l.cmdFilterViewOpenPanel,
    icon: LucideIcons.listFilter,
    categoryName: _data,
    run: (ctx, ed, a) {
      s.panels.open(filterViewsPanelId);
      return ok();
    },
  ),
];
