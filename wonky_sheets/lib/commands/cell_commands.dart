import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart'
    show GridRect, CellPos, ColumnLetters;
import 'package:wonky_sheets_core/model.dart';

import '../features/history/change_labels.dart';
import '../features/cell_editor/cell_editor_controller.dart';
import '../features/clipboard/clipboard_service.dart';
import '../features/dialogs/sheets_dialogs.dart';
import '../features/grid/selection/data_edge_finder.dart';
import '../features/grid/selection/grid_selection.dart';
import '../features/filters/view_sort_editing.dart';
import '../features/sheet_editor/sheet_editor_controller.dart';
import 'image_commands.dart' show pasteClipboardImage;
import 'sheets_command.dart';

String _edit(SheetsLocalizations l) => l.categoryEditing;
String _formulas(SheetsLocalizations l) => l.categoryFormulas;

/// The target cell of `setInput`: ids, A1, or the active cell.
(String, int, int) _targetCell(SheetEditorController ed, JsonArgs a) {
  final sid = a.string('sheetId');
  final rid = a.string('rowId');
  final cid = a.string('colId');
  if (sid != null && rid != null && cid != null) {
    final s = ed.model.sheet(sid);
    if (s != null) {
      final r = s.rows.indexOf(rid);
      final c = s.columns.indexOf(cid);
      if (r >= 0 && c >= 0) return (sid, r, c);
    }
    throw const PlanException('not_found', 'The cell no longer exists');
  }
  final a1 = a.string('a1');
  if (a1 != null) {
    final rr = ed.model.parseA1(a1, contextSheetId: ed.activeSheetId);
    return (rr.sheetId, rr.rect.top, rr.rect.left);
  }
  final r = ed.selection.resolved;
  return (ed.activeSheetId, r.activeRow, r.activeCol);
}

const _cellIds = {
  'sheetId': JsonSchema.string(),
  'rowId': JsonSchema.string(),
  'colId': JsonSchema.string(),
};

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _time(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

/// Cell editing, formula editing, clearing, fill, clipboard, notes and
/// links (03 §7.2, §8–§12, §14).
List<Command<CommandArgs>> cellCommands(ShellServices s) => [
  // ---- Cell editor ----
  SheetsCommand(
    'sheets.cell.edit',
    label: (l) => l.cmdCellEdit,
    icon: LucideIcons.pencil,
    categoryName: _edit,
    mutates: false,
    defaultBindings: const [KeyBinding('F2')],
    argsSchema: const JsonSchema.object(
      properties: {'caretAtEnd': JsonSchema.boolean()},
    ),
    enabled: (ed, a) => ed.canEdit && !ed.editor.isEditing,
    run: (ctx, ed, a) {
      ed.editor.begin(mode: EditMode.edit);
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.cell.setInput',
    label: (l) => l.cmdCellSetInput,
    categoryName: _edit,
    mutates: true,
    showInPalette: false,
    undoLabelOf: (l, a) => l.undoTyping,
    argsSchema: const JsonSchema.object(
      properties: {
        'a1': JsonSchema.string(description: 'Target cell (default: active).'),
        'input': JsonSchema.string(
          description: 'Text as typed: values, dates, =formulas.',
        ),
        ..._cellIds,
      },
      required: ['input'],
    ),
    run: (ctx, ed, a) {
      final (sid, r, c) = _targetCell(ed, a);
      final input = a.requireString('input');
      ed.apply(
        ctx,
        SetCellInputs(
          sheetId: sid,
          row: r,
          col: c,
          inputs: [
            [UserCellInput(input)],
          ],
          parseLocale: ed.locale,
          label: SheetsChangeLabels.typing,
        ),
      );
      return ok({'cell': CellPos(r, c).a1});
    },
  ),
  SheetsCommand(
    'sheets.cell.setInputForSelection',
    label: (l) => l.cmdCellSetInputForSelection,
    categoryName: _edit,
    mutates: true,
    undoLabelOf: (l, a) => l.undoTyping,
    argsSchema: const JsonSchema.object(
      properties: {'input': JsonSchema.string(), ..._cellIds},
    ),
    run: (ctx, ed, a) {
      final input = a.string('input') ?? ed.editor.text.text;
      final sel = ed.selection.resolved;
      final sid = ed.activeSheetId;
      final isFormula = input.startsWith('=') && input.length > 1;
      final stored = isFormula
          ? ed.hooks.toStored(
              input,
              sheetId: sid,
              row: sel.activeRow,
              col: sel.activeCol,
              locale: ed.locale,
            )
          : null;
      for (final range in ed.selectedRanges) {
        final rect =
            range.rect.intersection(
              GridRect(
                0,
                0,
                ed.activeSheet!.rows.length - 1,
                ed.activeSheet!.columns.length - 1,
              ),
            ) ??
            range.rect;
        ed.apply(
          ctx,
          SetCellInputs(
            sheetId: sid,
            row: rect.top,
            col: rect.left,
            inputs: [
              for (var r = rect.top; r <= rect.bottom; r++)
                [
                  for (var c = rect.left; c <= rect.right; c++)
                    stored == null
                        ? UserCellInput(input)
                        : ContentCellInput(
                            FormulaContent(
                              ed.hooks.translate(
                                stored,
                                fromSheetId: sid,
                                fromRow: sel.activeRow,
                                fromCol: sel.activeCol,
                                toSheetId: sid,
                                toRow: r,
                                toCol: c,
                              ),
                            ),
                          ),
                ],
            ],
            parseLocale: ed.locale,
            label: SheetsChangeLabels.typing,
          ),
        );
      }
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.formula.acceptCompletion',
    label: (l) => l.cmdFormulaAcceptCompletion,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    defaultBindings: const [KeyBinding(Keys.tab), KeyBinding(Keys.enter)],
    enabled: (ed, a) => ed.editor.showCompletions,
    run: (ctx, ed, a) {
      ed.editor.acceptCompletion();
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.formula.nextCompletion',
    label: (l) => l.cmdFormulaNextCompletion,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'delta': JsonSchema.integer()},
    ),
    argBindings: const [
      ArgsKeyBinding(KeyBinding(Keys.arrowDown), {'delta': 1}),
      ArgsKeyBinding(KeyBinding(Keys.arrowUp), {'delta': -1}),
    ],
    enabled: (ed, a) => ed.editor.showCompletions,
    run: (ctx, ed, a) {
      ed.editor.moveCompletion(a.integer('delta') ?? 1);
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.formula.dismissCompletion',
    label: (l) => l.cmdFormulaDismissCompletion,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    defaultBindings: const [KeyBinding(Keys.escape)],
    enabled: (ed, a) => ed.editor.showCompletions,
    run: (ctx, ed, a) {
      ed.editor.dismissCompletions();
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.formula.movePoint',
    label: (l) => l.cmdFormulaMovePoint,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'dir': JsonSchema.string(enumValues: ['up', 'down', 'left', 'right']),
        'extend': JsonSchema.boolean(),
        'toEdge': JsonSchema.boolean(),
      },
      required: ['dir'],
    ),
    argBindings: [
      for (final (d, k) in const [
        ('up', Keys.arrowUp),
        ('down', Keys.arrowDown),
        ('left', Keys.arrowLeft),
        ('right', Keys.arrowRight),
      ]) ...[
        ArgsKeyBinding(KeyBinding(k), {'dir': d}),
        ArgsKeyBinding(KeyBinding(k, shift: true), {'dir': d, 'extend': true}),
        ArgsKeyBinding(KeyBinding(k, mod: true), {'dir': d, 'toEdge': true}),
        ArgsKeyBinding(KeyBinding(k, mod: true, shift: true), {
          'dir': d,
          'toEdge': true,
          'extend': true,
        }),
      ],
    ],
    enabled: (ed, a) =>
        ed.editor.isEditing &&
        (ed.editor.isPointing ||
            (ed.editor.mode == EditMode.enter && ed.editor.pointEligible)),
    run: (ctx, ed, a) {
      final d = NavDirection.tryParse(a.string('dir'));
      if (d == null) return const CommandResult.failed('Unknown direction');
      ed.editor.movePoint(
        d,
        extend: a.boolean('extend') ?? false,
        toEdge: a.boolean('toEdge') ?? false,
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.cell.commit',
    label: (l) => l.cmdCellCommit,
    categoryName: _edit,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'move': JsonSchema.string(
          enumValues: [
            'none',
            'enter',
            'enterReverse',
            'tab',
            'tabReverse',
            'up',
            'down',
            'left',
            'right',
          ],
        ),
        'toSelection': JsonSchema.boolean(),
      },
    ),
    argBindings: const [
      ArgsKeyBinding(KeyBinding(Keys.enter), {'move': 'enter'}),
      ArgsKeyBinding(KeyBinding(Keys.enter, shift: true), {
        'move': 'enterReverse',
      }),
      ArgsKeyBinding(KeyBinding(Keys.tab), {'move': 'tab'}),
      ArgsKeyBinding(KeyBinding(Keys.tab, shift: true), {'move': 'tabReverse'}),
      ArgsKeyBinding(KeyBinding(Keys.arrowUp), {'move': 'up'}),
      ArgsKeyBinding(KeyBinding(Keys.arrowDown), {'move': 'down'}),
      ArgsKeyBinding(KeyBinding(Keys.arrowLeft), {'move': 'left'}),
      ArgsKeyBinding(KeyBinding(Keys.arrowRight), {'move': 'right'}),
      ArgsKeyBinding(KeyBinding(Keys.enter, mod: true), {
        'move': 'none',
        'toSelection': true,
      }),
    ],
    enabled: (ed, a) {
      if (!ed.editor.isEditing) return false;
      final m = a.string('move');
      const arrows = {'up', 'down', 'left', 'right'};
      // Arrows commit only in Enter mode (03 §8.1).
      if (arrows.contains(m)) return ed.editor.mode == EditMode.enter;
      return true;
    },
    run: (ctx, ed, a) {
      unawaited(
        ed.editor.commit(
          move: CommitMove.parse(a.string('move')),
          toSelection: a.boolean('toSelection') ?? false,
        ),
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.cell.cancel',
    label: (l) => l.cmdCellCancel,
    categoryName: _edit,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    defaultBindings: const [KeyBinding(Keys.escape)],
    enabled: (ed, a) => ed.editor.isEditing,
    run: (ctx, ed, a) {
      ed.editor.cancel();
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.cell.toggleEditMode',
    label: (l) => l.cmdCellToggleEditMode,
    categoryName: _edit,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    defaultBindings: const [KeyBinding('F2')],
    enabled: (ed, a) => ed.editor.isEditing,
    run: (ctx, ed, a) {
      ed.editor.toggleMode();
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.cell.insertNewline',
    label: (l) => l.cmdCellInsertNewline,
    categoryName: _edit,
    keyScope: KeyScope.cellEditor,
    showInPalette: false,
    defaultBindings: const [
      KeyBinding(Keys.enter, alt: true),
      KeyBinding(Keys.enter, ctrl: true, mac: true),
    ],
    enabled: (ed, a) => ed.editor.isEditing,
    run: (ctx, ed, a) {
      ed.editor.insertNewline();
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.formula.cycleReferenceType',
    label: (l) => l.cmdFormulaCycleReferenceType,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    defaultBindings: const [KeyBinding('F4')],
    enabled: (ed, a) => ed.editor.isEditing && ed.editor.isFormula,
    run: (ctx, ed, a) =>
        ed.editor.cycleAbsoluteRef() ? ok() : const CommandResult.cancelled(),
  ),
  SheetsCommand(
    'sheets.formula.toggleArrayFormula',
    label: (l) => l.cmdFormulaToggleArrayFormula,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    defaultBindings: const [KeyBinding(Keys.enter, mod: true, shift: true)],
    enabled: (ed, a) => ed.editor.isEditing && ed.editor.isFormula,
    run: (ctx, ed, a) {
      ed.editor.toggleArray();
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.formula.toggleHelpCardVisible',
    label: (l) => l.cmdFormulaToggleHelpCardVisible,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    defaultBindings: const [KeyBinding('F1', shift: true)],
    checked: (ed, a) => ed.editor.helpVisible,
    run: (ctx, ed, a) {
      ed.editor.helpVisible = !ed.editor.helpVisible;
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.formula.toggleHelpCard',
    label: (l) => l.cmdFormulaToggleHelpCard,
    categoryName: _formulas,
    keyScope: KeyScope.cellEditor,
    defaultBindings: const [KeyBinding('F1')],
    checked: (ed, a) => ed.editor.helpExpanded,
    run: (ctx, ed, a) {
      ed.editor.helpExpanded = !ed.editor.helpExpanded;
      return ok();
    },
  ),
  for (final (id, label, binding, kind) in [
    (
      'sheets.cell.insertDate',
      (SheetsLocalizations l) => l.cmdCellInsertDate,
      const KeyBinding(';', mod: true),
      0,
    ),
    (
      'sheets.cell.insertTime',
      (SheetsLocalizations l) => l.cmdCellInsertTime,
      const KeyBinding(';', mod: true, shift: true),
      1,
    ),
    (
      'sheets.cell.insertDateTime',
      (SheetsLocalizations l) => l.cmdCellInsertDateTime,
      const KeyBinding(';', mod: true, alt: true, shift: true),
      2,
    ),
  ])
    SheetsCommand(
      id,
      label: label,
      categoryName: _edit,
      mutates: true,
      keyScope: KeyScope.global,
      defaultBindings: [binding],
      run: (ctx, ed, a) {
        final now = clock.now();
        final text = switch (kind) {
          0 => _isoDate(now),
          1 => _time(now),
          _ => '${_isoDate(now)} ${_time(now)}',
        };
        if (ed.editor.isEditing) {
          ed.editor.appendTyped(text);
          return ok();
        }
        final r = ed.selection.resolved;
        ed.apply(
          ctx,
          SetCellInputs(
            sheetId: ed.activeSheetId,
            row: r.activeRow,
            col: r.activeCol,
            inputs: [
              [UserCellInput(text)],
            ],
            parseLocale: 'en_US',
          ),
        );
        return ok();
      },
    ),
  SheetsCommand(
    'sheets.cell.copyLink',
    label: (l) => l.cmdCellCopyLink,
    icon: LucideIcons.link,
    categoryName: _edit,
    run: (ctx, ed, a) async {
      final url = s.urls.urlFor(
        s.config.app,
        '/s/${ed.session.itemUuid.uuid}?sheet=${ed.activeSheetId}&range=${Uri.encodeComponent(ed.selection.describe())}',
      );
      await Clipboard.setData(ClipboardData(text: url));
      s.toasts.show(ed.l10n.toastLinkCopied);
      return ok({'url': url});
    },
  ),
  // ---- Clear ----
  SheetsCommand(
    'sheets.edit.clearValues',
    label: (l) => l.cmdEditClearValues,
    icon: LucideIcons.eraser,
    categoryName: _edit,
    mutates: true,
    argsSchema: Schemas.ranges,
    defaultBindings: const [
      KeyBinding(Keys.delete),
      KeyBinding(Keys.backspace),
    ],
    run: (ctx, ed, a) {
      ed.apply(ctx, ClearRanges(rangesArg(ed, a)));
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.edit.clearAll',
    label: (l) => l.cmdEditClearAll,
    categoryName: _edit,
    mutates: true,
    dynamicLabel: (l, ed) {
      final k = ed.selection.resolved.activeRange;
      if (k.wholeRows && !k.wholeColumns) {
        return l.cmdClearRows(rowsLabel(l, k.rect.top, k.rect.bottom));
      }
      if (k.wholeColumns && !k.wholeRows) {
        return l.cmdClearColumns(colsLabel(l, k.rect.left, k.rect.right));
      }
      return l.cmdEditClearAll;
    },
    argsSchema: Schemas.ranges,
    run: (ctx, ed, a) {
      ed.apply(ctx, ClearRanges(rangesArg(ed, a), what: ClearWhat.all));
      return ok();
    },
  ),
  // ---- Fill (03 §10) ----
  SheetsCommand(
    'sheets.fill.down',
    label: (l) => l.cmdFillDown,
    categoryName: _edit,
    mutates: true,
    repeatable: true,
    defaultBindings: const [KeyBinding('D', mod: true)],
    run: (ctx, ed, a) {
      // A range on screen in a sorted filter view fills in display order.
      if (ViewSortEditing.fillDown(ctx, ed)) return ok();
      for (final r in ed.selectedRanges) {
        final rect = _clip(ed, r.rect);
        if (rect.rowCount < 2) continue;
        ed.apply(
          ctx,
          FillSeries(
            ed.activeSheetId,
            GridRect(rect.top, rect.left, rect.top, rect.right),
            rect,
            mode: FillMode.copy,
          ),
        );
      }
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.fill.right',
    label: (l) => l.cmdFillRight,
    categoryName: _edit,
    mutates: true,
    repeatable: true,
    defaultBindings: const [KeyBinding('R', mod: true)],
    run: (ctx, ed, a) {
      for (final r in ed.selectedRanges) {
        final rect = _clip(ed, r.rect);
        if (rect.colCount < 2) continue;
        ed.apply(
          ctx,
          FillSeries(
            ed.activeSheetId,
            GridRect(rect.top, rect.left, rect.bottom, rect.left),
            rect,
            mode: FillMode.copy,
          ),
        );
      }
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.fill.selection',
    label: (l) => l.cmdFillSelection,
    categoryName: _edit,
    mutates: true,
    defaultBindings: const [KeyBinding(Keys.enter, mod: true)],
    enabled: (ed, a) => !ed.editor.isEditing,
    run: (ctx, ed, a) {
      final sel = ed.selection.resolved;
      final source = ed.clipboard.sourceOf(
        GridRect.cell(sel.activeRow, sel.activeCol),
      );
      for (final r in ed.selectedRanges) {
        ed.apply(
          ctx,
          PasteClipboard(ResolvedRange(r.sheetId, _clip(ed, r.rect)), source),
        );
      }
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.fill.series',
    label: (l) => l.cmdFillSeries,
    categoryName: _edit,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'source': JsonSchema.string(),
        'target': JsonSchema.string(),
        'mode': JsonSchema.string(enumValues: ['auto', 'copy']),
      },
      required: ['source', 'target'],
    ),
    run: (ctx, ed, a) {
      final src = rectArg(ed, a, 'source');
      final target = rectArg(ed, a, 'target');
      ed.apply(
        ctx,
        FillSeries(
          ed.activeSheetId,
          src,
          target,
          mode: a.string('mode') == 'copy' ? FillMode.copy : FillMode.auto,
        ),
      );
      final union = GridRect(
        target.top < src.top ? target.top : src.top,
        target.left < src.left ? target.left : src.left,
        target.bottom > src.bottom ? target.bottom : src.bottom,
        target.right > src.right ? target.right : src.right,
      );
      ed.selection.setRanges(
        [(SelectionKind.cells, union)],
        activeRow: ed.selection.resolved.activeRow,
        activeCol: ed.selection.resolved.activeCol,
      );
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.fill.autoFillDown',
    label: (l) => l.cmdFillAutoFillDown,
    categoryName: _edit,
    mutates: true,
    run: (ctx, ed, a) {
      final sheet = ed.activeSheet!;
      final range = _clip(ed, ed.selection.resolved.activeRange.rect);
      int? lastRow;
      for (final col in [range.left - 1, range.right + 1]) {
        if (col < 0 || col >= sheet.columns.length) continue;
        var r = range.bottom + 1;
        if (r >= sheet.rows.length || sheet.cellAt(r, col)?.content == null) {
          continue;
        }
        while (r + 1 < sheet.rows.length &&
            sheet.cellAt(r + 1, col)?.content != null) {
          r++;
        }
        lastRow = r;
        break;
      }
      if (lastRow == null) return const CommandResult.cancelled();
      final target = GridRect(range.top, range.left, lastRow, range.right);
      ed.apply(ctx, FillSeries(ed.activeSheetId, range, target));
      ed.selection.setRanges([(SelectionKind.cells, target)]);
      return ok();
    },
  ),
  // ---- Clipboard (03 §12) ----
  SheetsCommand(
    'sheets.edit.copy',
    label: (l) => l.cmdEditCopy,
    icon: LucideIcons.copy,
    categoryName: _edit,
    defaultBindings: const [KeyBinding('C', mod: true)],
    enabled: (ed, a) =>
        ed.selection.resolved.ranges.length == 1 ||
        ViewSortEditing.isDisplayGroup(ed.selection.resolved),
    run: (ctx, ed, a) async {
      try {
        await ed.clipboard.copy();
      } on ClipboardActionException catch (e) {
        return CommandResult.failed(e.message);
      }
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.edit.cut',
    label: (l) => l.cmdEditCut,
    icon: LucideIcons.scissors,
    categoryName: _edit,
    defaultBindings: const [KeyBinding('X', mod: true)],
    enabled: (ed, a) => ed.canEdit && ed.selection.resolved.ranges.length == 1,
    run: (ctx, ed, a) async {
      if (!ed.canEdit) return const CommandResult.failed('View only');
      try {
        await ed.clipboard.copy(cut: true);
      } on ClipboardActionException catch (e) {
        return CommandResult.failed(e.message);
      }
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.edit.paste',
    label: (l) => l.cmdEditPaste,
    icon: LucideIcons.clipboardPaste,
    categoryName: _edit,
    defaultBindings: const [KeyBinding('V', mod: true)],
    mutates: true,
    run: (ctx, ed, a) => _paste(ctx, ed, PasteMode.all),
  ),
  SheetsCommand(
    'sheets.edit.pasteSpecial',
    label: (l) => l.cmdEditPasteSpecial,
    categoryName: _edit,
    mutates: true,
    undoLabelOf: (l, a) => l.cmdEditPaste,
    argsSchema: JsonSchema.object(
      properties: {
        'mode': JsonSchema.string(
          enumValues: [for (final m in PasteSpecialMode.values) m.id],
        ),
      },
      required: const ['mode'],
    ),
    argBindings: const [
      ArgsKeyBinding(KeyBinding('V', mod: true, shift: true), {
        'mode': 'values',
      }),
      ArgsKeyBinding(KeyBinding('V', mod: true, alt: true), {'mode': 'format'}),
    ],
    run: (ctx, ed, a) {
      final m = PasteSpecialMode.tryParse(a.string('mode'));
      if (m == null) return const CommandResult.failed('Unknown mode');
      return _paste(ctx, ed, m.mode);
    },
  ),
  SheetsCommand(
    'sheets.edit.pasteSpecialDialog',
    label: (l) => l.cmdEditPasteSpecialDialog,
    categoryName: _edit,
    mutates: true,
    undoLabelOf: (l, a) => l.cmdEditPaste,
    run: (ctx, ed, a) async {
      final c = ctx.dialogContext;
      if (c == null) return const CommandResult.cancelled();
      final m = await showPasteSpecialDialog(c);
      if (m == null) return const CommandResult.cancelled();
      return _paste(ctx, ed, m.mode);
    },
  ),
  // Notes and links: note_commands.dart, link_commands.dart.
];

GridRect _clip(SheetEditorController ed, GridRect r) {
  final s = ed.activeSheet!;
  return r.intersection(
        GridRect(0, 0, s.rows.length - 1, s.columns.length - 1),
      ) ??
      r;
}

Future<CommandResult> _paste(
  CommandContext ctx,
  SheetEditorController ed,
  PasteMode mode,
) async {
  // An image (screenshot, copied picture) without text on the system
  // clipboard goes over cells at the active cell (08 §9.5).
  if (mode == PasteMode.all) {
    final image = await pasteClipboardImage(ctx, ed);
    if (image != null) return image;
  }
  final sel = ed.selection.resolved;
  final target = ed.activeRange;
  final source = await ed.clipboard.readSource(
    targetRow: target.rect.top,
    targetCol: target.rect.left,
  );
  if (source == null) {
    return CommandResult.failed(
      ed.clipboard.system.readBlocked
          ? ed.l10n.toastClipboardBlocked
          : ed.l10n.toastClipboardEmpty,
    );
  }
  // Rows of a sorted filter view take the paste in display order (07 §4.4).
  if (ViewSortEditing.paste(ctx, ed, source, mode) != null) return ok();
  final plan = ed.apply(
    ctx,
    PasteClipboard(
      ResolvedRange(target.sheetId, _clip(ed, target.rect)),
      source,
      mode: mode,
    ),
  );
  if (source.isCut && mode == PasteMode.all) ed.clipboard.consumeCut();
  final written = plan.result['range'];
  if (written is GridRect) {
    ed.selection.setRanges(
      [(SelectionKind.cells, written)],
      activeRow: sel.activeRow,
      activeCol: sel.activeCol,
    );
  }
  return ok();
}

/// Labels of rows / columns ranges ("row 5", "rows 5 – 7").
String rowsLabel(SheetsLocalizations l, int top, int bottom) =>
    top == bottom ? l.labelRow(top + 1) : l.labelRows(top + 1, bottom + 1);

String colsLabel(SheetsLocalizations l, int left, int right) => left == right
    ? l.labelColumn(ColumnLetters.fromIndex(left))
    : l.labelColumns(
        ColumnLetters.fromIndex(left),
        ColumnLetters.fromIndex(right),
      );
