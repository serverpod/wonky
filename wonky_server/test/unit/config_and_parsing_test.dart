import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/config/wonky_config.dart';
import 'package:wonky_server/src/platform/drive/import_service.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/content/write_content.dart';
import 'package:wonky_server/src/write/themes/theme_service.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

void main() {
  group('Given a wonky config section', () {
    test('when values are set then they are read', () {
      final c = WonkyConfig.fromMap({
        'features': {'ai': false},
        'write': {'maxDocumentChars': 10},
        'minClientVersion': '2.0.0',
      });

      expect(c.aiEnabled, isFalse);
      expect(c.maxDocumentChars, 10);
      expect(c.minClientVersion, '2.0.0');
    });

    test('when an environment variable is set then it overrides the file', () {
      final c = WonkyConfig.fromMap(
        {
          'sheets': {'maxSheetsPerSpreadsheet': 5},
        },
        environment: {'WONKY_SHEETS_MAX_SHEETS_PER_SPREADSHEET': '7'},
      );

      expect(c.maxSheetsPerSpreadsheet, 7);
    });

    test('when the section is missing then defaults are used', () {
      final c = WonkyConfig.fromMap(const {});

      expect(c.snapshotEveryNOps, 500);
      expect(c.maxCellsPerSpreadsheet, 1000000);
    });
  });

  group('Given delimited text', () {
    final cases = [
      (
        'a,b\n1,2',
        ',',
        [
          ['a', 'b'],
          ['1', '2'],
        ],
      ),
      (
        '"x, y",z\r\n',
        ',',
        [
          ['x, y', 'z'],
        ],
      ),
      (
        '"say ""hi""";2',
        ';',
        [
          ['say "hi"', '2'],
        ],
      ),
      (
        'a\tb',
        '\t',
        [
          ['a', 'b'],
        ],
      ),
    ];
    for (final (input, delimiter, expected) in cases) {
      test('when parsing ${jsonEncode(input)} then rows are $expected', () {
        expect(ImportService.parseDelimited(input, delimiter), expected);
      });
    }
  });

  group('Given the built-in themes', () {
    for (final theme in BuiltinThemes.all) {
      test('when canonicalizing ${theme.key} then it is valid', () {
        final canonical = ThemeService.canonical(jsonEncode(theme.json));

        expect((jsonDecode(canonical) as Map)['schemaVersion'], 1);
      });
    }

    test('when a theme has no schemaVersion then it is refused', () {
      expect(
        () => ThemeService.canonical('{}'),
        throwsA(isA<WonkyException>()),
      );
    });
  });

  group('Given the built-in document templates', () {
    for (final t in BuiltinTemplates.all.where(
      (t) => t.kind == DriveItemKind.document,
    )) {
      test('when converting ${t.key} then the delta is a valid document', () {
        final delta = WriteContent.fromMarkdown(t.markdown!).delta;

        expect(const WonkyDeltaValidator().validate(delta).isValid, isTrue);
      });
    }

    test('when templates are listed then their uuids are unique', () {
      final uuids = BuiltinTemplates.all.map((t) => t.uuid).toSet();
      expect(uuids, hasLength(BuiltinTemplates.all.length));
    });
  });

  group('Given plain text', () {
    test(
      'when converting with paragraph breaks then each line is a paragraph',
      () {
        final delta = WriteContent.fromPlainText('one\ntwo').delta;

        expect(DeltaUtils.text(delta), 'one\ntwo\n');
      },
    );
  });
}
