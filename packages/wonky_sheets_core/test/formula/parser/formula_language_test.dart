import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/model_testing.dart';

import '../../support/planner_harness.dart';

void main() {
  group('FormulaLanguage tables', () {
    for (final lang in FormulaLanguage.supported) {
      test('Given ${lang.code}, every translated function exists, no local '
          'name is another English function and local names lex as function '
          'names', () {
        final reg = FunctionRegistry.standard;
        final locals = <String>{};
        for (final en in lang.translatedFunctions) {
          expect(reg.has(en), isTrue, reason: '$en is not registered');
          final local = lang.localName(en)!;
          expect(locals.add(local), isTrue, reason: 'duplicate $local');
          if (local != en) {
            expect(
              reg.has(local),
              isFalse,
              reason: '$local (${lang.code} $en) is an English function',
            );
          }
          final locale = FormulaLocale.forId('de_DE').withLanguage(lang.code);
          final tokens = FormulaLexer.significant(
            FormulaLexer(
              locale: locale,
              storedForm: false,
            ).tokenize('=$local(1)'),
          );
          expect(tokens[1].kind, TokenKind.functionName, reason: local);
          expect(lang.englishName(local.toLowerCase()), en);
        }
        expect(reg.has(lang.trueName), isFalse);
        expect(lang.booleanOf(lang.falseName.toLowerCase()), isFalse);
      });
    }

    test('Given codes then forCode maps languages and regions; English and '
        'unknown codes are null', () {
      expect(FormulaLanguage.forCode('de')?.code, 'de');
      expect(FormulaLanguage.forCode('sv_SE')?.code, 'sv');
      expect(FormulaLanguage.forCode('fr-CA')?.code, 'fr');
      expect(FormulaLanguage.forCode('en'), isNull);
      expect(FormulaLanguage.forCode(''), isNull);
      expect(FormulaLanguage.forCode(null), isNull);
      final de = FormulaLocale.forId('de_DE').withLanguage('de');
      expect(de, isNot(FormulaLocale.forId('de_DE')));
      expect(de.withLanguage(null), FormulaLocale.forId('de_DE'));
      expect(
        identical(de, FormulaLocale.forId('de_DE').withLanguage('de')),
        isTrue,
      );
    });
  });

  group('Given a German display language', () {
    late MemoryWorkbook wb;
    setUp(() {
      wb = MemoryWorkbook();
      wb.addSheet('Sheet1', rows: 100, cols: 10);
    });
    CodecContext ctx(String locale, String? lang) => CodecContext(
      workbook: wb,
      hostSheetId: wb.sheetByName('Sheet1')!.id,
      locale: FormulaLocale.forId(locale).withLanguage(lang),
    );

    test('when a localized formula is stored then it is English and reads '
        'back localized; English input is accepted', () {
      final de = ctx('de_DE', 'de');
      final stored = FormulaCodec.toStored(
        '=wenn(summe(A1:A3)>1,5; wahr; Falsch)',
        de,
      );
      expect(stored, contains('IF(SUM('));
      expect(stored, contains(', TRUE, FALSE)'));
      expect(stored, contains('1.5'));
      expect(
        FormulaCodec.toA1(stored, de),
        '=WENN(SUMME(A1:A3)>1,5; WAHR; FALSCH)',
      );
      // English stays English in an English locale view of the same text.
      expect(
        FormulaCodec.toA1(stored, ctx('de_DE', null)),
        '=IF(SUM(A1:A3)>1,5; TRUE; FALSE)',
      );
      final en = FormulaCodec.toStored('=SUM(A1;TRUE)', de);
      expect(en, contains('SUM('));
      expect(en, contains('TRUE'));
    });

    test('when French, Spanish and Swedish names are typed then they store '
        'in English', () {
      expect(
        FormulaCodec.toStored('=SOMME.SI(A1:A3;">1")', ctx('fr_FR', 'fr')),
        startsWith('=SUMIF('),
      );
      expect(
        FormulaCodec.toStored('=BUSCARV(1;A1:B3;2;FALSO)', ctx('es_ES', 'es')),
        allOf(startsWith('=VLOOKUP('), endsWith(',FALSE)')),
      );
      expect(
        FormulaCodec.toStored(
          '=OMFEL(LETARAD(1;A1:B3;2;FALSKT);"")',
          ctx('sv_SE', 'sv'),
        ),
        allOf(startsWith('=IFERROR(VLOOKUP('), contains(',FALSE)')),
      );
    });

    test('when validating, signature help and autocomplete run then the '
        'localized names are known, shown and inserted', () {
      final de = FormulaLocale.forId('de_DE').withLanguage('de');
      final v = validateFormula('=ZÄHLENWENN(A1:A3;">1")+WAHR', locale: de);
      expect(v.ok, isTrue);
      expect(v.functionsUsed, ['COUNTIF']);
      expect(v.unknownFunctions, isEmpty);

      final sig = signatureAt('=SVERWEIS(1;', 12, locale: de)!;
      expect(sig.functionName, 'SVERWEIS');
      expect(sig.spec?.name, 'VLOOKUP');

      final byLocal = completionsAt('=SVERW', 6, CompletionContext(locale: de));
      expect(byLocal.items.first.name, 'SVERWEIS');
      expect(byLocal.items.first.insertText, 'SVERWEIS(');
      final byEnglish = completionsAt(
        '=VLOOK',
        6,
        CompletionContext(locale: de),
      );
      expect(byEnglish.items.first.name, 'SVERWEIS');
    });
  });

  group('Given a spreadsheet with display language de', () {
    late PlannerHarness h;
    late ModelEngineBinding binding;
    setUp(() {
      final b = WorkbookBuilder()..sheet('Sheet1', rows: 10, cols: 3);
      h = PlannerHarness(b);
      binding = ModelEngineBinding.create(h.model);
      h.apply(const SetSpreadsheetProperties(displayLanguage: 'de'));
      binding.engine.settingsChanged(ModelWorkbookView(h.model).settings);
    });
    tearDown(() => binding.dispose());

    test('when the engine evaluates localized A1 text then it computes it', () {
      final v = binding.engine.evaluate(
        '=SUMME(1, 2)+WAHR',
        sheetId: h.sheetId,
      );
      expect(v.toCellValue(), const NumberValue(4));
    });

    test('when hooks opt into the display language then A1 text is '
        'localized; other hooks keep English', () {
      final ui = EngineFormulaHooks(h.model, displayLanguage: true);
      final stored = ui.toStored(
        '=MITTELWERT(A1:A2)',
        sheetId: h.sheetId,
        row: 0,
        col: 2,
      );
      expect(stored, startsWith('=AVERAGE('));
      expect(
        ui.toA1(stored, sheetId: h.sheetId, row: 0, col: 2),
        '=MITTELWERT(A1:A2)',
      );
      expect(
        h.hooks.toA1(stored, sheetId: h.sheetId, row: 0, col: 2),
        '=AVERAGE(A1:A2)',
      );
    });

    test('when a cell holds a boolean then it displays localized', () {
      h.apply(
        SetCellInputs(
          sheetId: h.sheetId,
          row: 0,
          col: 0,
          inputs: [
            [const CellInput.user('TRUE')],
          ],
        ),
      );
      final d = CellDisplayResolver(h.model, ModelCellSource(h.model));
      expect(d.display(h.sheetId, 0, 0).formatted.plainText, 'WAHR');
      h.apply(const SetSpreadsheetProperties(displayLanguage: ''));
      final en = CellDisplayResolver(h.model, ModelCellSource(h.model));
      expect(en.display(h.sheetId, 0, 0).formatted.plainText, 'TRUE');
    });
  });
}
