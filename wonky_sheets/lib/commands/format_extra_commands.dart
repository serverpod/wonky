import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show CellPos, FormulaLanguage;
import 'package:wonky_sheets_core/model.dart';

import '../features/history/change_labels.dart';
import '../features/formatting/spreadsheet_settings_dialog.dart';
import '../features/number_format/custom_currency_dialog.dart';
import '../features/number_format/custom_date_time_dialog.dart';
import '../features/number_format/recent_formats.dart';
import '../features/sheet_editor/sheet_editor_controller.dart';
import 'sheets_command.dart';

String _fmt(SheetsLocalizations l) => l.categoryFormatting;

/// Applies a custom number format [pattern] to the selection (1 step).
CommandResult applyCustomNumberFormat(
  CommandContext ctx,
  SheetEditorController ed,
  String pattern,
) {
  final err = NumberFormatParser.validate(pattern);
  if (err != null) {
    return CommandResult.failed('invalid_number_format: ${err.message}');
  }
  ed.apply(
    ctx,
    SetFormat(ed.selectedRanges, {
      FormatAttr.numberFormat: pattern.isEmpty ? null : pattern,
    }),
  );
  RecentNumberFormats.note(ed.model, pattern);
  return ok();
}

/// The current custom pattern of the active cell ('' for presets).
String _currentPattern(SheetEditorController ed) {
  final p = ed.activeFormat().numberFormat;
  return NumberFormatPresets.isPreset(p) || NumberFormatPresets.isAutomatic(p)
      ? ''
      : p;
}

(String, int, int) _cell(SheetEditorController ed, JsonArgs a) {
  final sid = a.string('sheetId');
  final rid = a.string('rowId');
  final cid = a.string('colId');
  if (sid != null && rid != null && cid != null) {
    final s = ed.model.sheet(sid);
    final r = s?.rows.indexOf(rid) ?? -1;
    final c = s?.columns.indexOf(cid) ?? -1;
    if (r >= 0 && c >= 0) return (sid, r, c);
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

/// The cell input for text with rich runs (06 §11): text that parses as a
/// number, date, boolean or formula can't have runs and is typed as usual;
/// runs equal to the cell format are dropped (normalization).
CellInput richTextInput(
  SheetEditorController ed,
  String sheetId,
  int row,
  int col,
  String text,
  List<Object?> runs,
) {
  final typed = UserCellInput(text);
  if (text.startsWith('=') || text.startsWith("'")) return typed;
  final value = InputParser.instance.parseValue(
    InputParser.trimAscii(text),
    locale: ed.locale,
  );
  if (value != null) return typed;
  final rich = RichText.fromJson({'t': text, 'runs': runs});
  if (rich == null) return typed;
  final cell = ed.model.explicitFormatChain(sheetId, row, col).toMap();
  final n = rich.normalize(
    cellFormat: {
      for (final k in RichRunKeys.all)
        if (cell[k] != null) k: cell[k],
    },
  );
  final r = n.rich;
  return r == null ? typed : ContentCellInput(RichTextContent(r));
}

/// Number-format dialogs and spreadsheet settings (04 §3.5, §11.1–11.4).
List<Command<CommandArgs>> formatExtraCommands(ShellServices s) => [
  SheetsCommand(
    'sheets.cell.setRichText',
    label: (l) => l.cmdCellSetRichText,
    categoryName: _fmt,
    mutates: true,
    showInPalette: false,
    undoLabelOf: (l, a) => l.undoTyping,
    argsSchema: const JsonSchema.object(
      properties: {
        'a1': JsonSchema.string(description: 'Target cell (default: active).'),
        'text': JsonSchema.string(),
        'runs': JsonSchema.array(
          JsonSchema.object(additionalProperties: true),
          description: 'Runs {s, e, f} (06 §11).',
        ),
        'sheetId': JsonSchema.string(),
        'rowId': JsonSchema.string(),
        'colId': JsonSchema.string(),
      },
      required: ['text'],
    ),
    run: (ctx, ed, a) {
      final (sid, r, c) = _cell(ed, a);
      final text = a.requireString('text');
      final runs = a.values['runs'];
      ed.apply(
        ctx,
        SetCellInputs(
          sheetId: sid,
          row: r,
          col: c,
          inputs: [
            [
              richTextInput(
                ed,
                sid,
                r,
                c,
                text,
                runs is List ? runs : const [],
              ),
            ],
          ],
          parseLocale: ed.locale,
          label: SheetsChangeLabels.typing,
        ),
      );
      return ok({'cell': CellPos(r, c).a1});
    },
  ),
  SheetsCommand(
    'sheets.format.openCustomCurrency',
    label: (l) => l.cmdFormatOpenCustomCurrency,
    icon: LucideIcons.dollarSign,
    categoryName: _fmt,
    mutates: true,
    undoLabelOf: (l, a) => l.cmdFormatNumberFormat,
    run: (ctx, ed, a) async {
      final c = ctx.dialogContext;
      if (c == null) return const CommandResult.cancelled();
      final p = await showCustomCurrencyDialog(c, locale: ed.locale);
      if (p == null) return const CommandResult.cancelled();
      return applyCustomNumberFormat(ctx, ed, p);
    },
  ),
  SheetsCommand(
    'sheets.format.openCustomDateTime',
    label: (l) => l.cmdFormatOpenCustomDateTime,
    icon: LucideIcons.calendar,
    categoryName: _fmt,
    mutates: true,
    undoLabelOf: (l, a) => l.cmdFormatNumberFormat,
    run: (ctx, ed, a) async {
      final c = ctx.dialogContext;
      if (c == null) return const CommandResult.cancelled();
      final current = _currentPattern(ed);
      final p = await showCustomDateTimeDialog(
        c,
        initial:
            NumberFormatInfo.isDatePattern(current, locale: ed.locale) ||
                NumberFormatInfo.isTimePattern(current, locale: ed.locale)
            ? current
            : '',
        locale: ed.locale,
        activeValue: ed.activeDisplay()?.value,
      );
      if (p == null) return const CommandResult.cancelled();
      return applyCustomNumberFormat(ctx, ed, p);
    },
  ),
  SheetsCommand(
    'sheets.file.settings',
    label: (l) => l.cmdFileSettings,
    icon: LucideIcons.settings,
    categoryName: (l) => l.categoryFile,
    enabled: (ed, a) => ed.canEdit,
    run: (ctx, ed, a) async {
      final c = ctx.dialogContext;
      if (c == null) return const CommandResult.cancelled();
      final before = SpreadsheetSettings.of(ed.model.spreadsheet);
      final after = await showSpreadsheetSettingsDialog(c, before);
      if (after == null) return const CommandResult.cancelled();
      final changes = after.changesFrom(before);
      if (changes.isEmpty) return ok();
      final done = await ed.invokeCommand(
        'sheets.settings.update',
        changes,
        ctx.source,
      );
      return done ? ok() : const CommandResult.cancelled();
    },
  ),
  SheetsCommand(
    'sheets.settings.update',
    label: (l) => l.cmdSettingsUpdate,
    icon: LucideIcons.settings,
    categoryName: (l) => l.categoryFile,
    mutates: true,
    showInPalette: false,
    argsSchema: JsonSchema.object(
      properties: {
        'locale': const JsonSchema.string(description: 'e.g. en_US, de_DE'),
        'timeZone': const JsonSchema.string(description: 'IANA zone'),
        'recalcMode': JsonSchema.string(
          enumValues: [for (final m in RecalcMode.values) m.name],
        ),
        'iterativeCalc': const JsonSchema.boolean(),
        'maxIterations': const JsonSchema.integer(minimum: 1, maximum: 1000),
        'convergenceThreshold': const JsonSchema.number(minimum: 0),
        // 04 §11.1 (P2): function names and booleans; '' = English.
        'displayLanguage': JsonSchema.string(
          description: 'Function language; empty = English',
          enumValues: ['', for (final l in FormulaLanguage.supported) l.code],
        ),
      },
    ),
    run: (ctx, ed, a) {
      final op = SetSpreadsheetProperties(
        displayLanguage: a.string('displayLanguage'),
        locale: a.string('locale'),
        timeZone: a.string('timeZone'),
        recalcMode: a.string('recalcMode'),
        iterativeCalc: a.boolean('iterativeCalc'),
        maxIterations: a.integer('maxIterations'),
        convergenceThreshold: (a.values['convergenceThreshold'] as num?)
            ?.toDouble(),
      );
      ed.apply(ctx, op);
      return ok();
    },
  ),
];
