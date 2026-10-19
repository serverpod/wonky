import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';
import 'package:wonky_server/src/platform/storage/content_sizes.dart';
import 'package:wonky_server/src/platform/storage/storage_counters.dart';
import 'package:wonky_server/src/platform/storage/storage_hooks.dart';
import 'package:wonky_server/src/platform/storage/storage_maintenance.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show Delta;

/// Accounting rules of Drive 03 §2–§4 that need no database.
void main() {
  group('Given the counter of an item (Drive 03 §2)', () {
    const cases = <(DriveItemKind, bool, String?)>[
      (DriveItemKind.document, false, 'documentsBytes'),
      (DriveItemKind.spreadsheet, false, 'spreadsheetsBytes'),
      (DriveItemKind.presentation, false, 'presentationsBytes'),
      (DriveItemKind.file, false, 'filesBytes'),
      (DriveItemKind.document, true, 'trashBytes'),
      (DriveItemKind.file, true, 'trashBytes'),
      (DriveItemKind.folder, false, null),
      (DriveItemKind.folder, true, null),
    ];
    for (final (kind, trashed, column) in cases) {
      test('when a ${trashed ? 'trashed ' : ''}${kind.name} changes size '
          'then $column is charged', () {
        expect(StorageCounters.columnOf(kind, trashed: trashed), column);
      });
    }
  });

  group('Given storage totals', () {
    test(
      'when summing then used is every kind plus trash, not reservations',
      () {
        const t = StorageTotals(
          documentsBytes: 1,
          spreadsheetsBytes: 2,
          presentationsBytes: 4,
          filesBytes: 8,
          trashBytes: 16,
          reservedBytes: 32,
        );

        expect(t.usedBytes, 31);
        expect(t.toMap()['reservedBytes'], 32);
      },
    );
  });

  group('Given a document size (Drive 03 §2)', () {
    test('when measuring then it is the UTF-8 length of the Delta JSON', () {
      final delta = Delta()
        ..insert('Hé')
        ..insert('\n');

      // [{"insert":"Hé\n"}]: 19 characters (the newline escaped), é is
      // 2 bytes.
      expect(DocumentSize.of(delta), 20);
    });

    test('when measuring the same content twice then the size is the same', () {
      Delta make() => Delta()
        ..insert('Bold', {'bold': true})
        ..insert(' text\n');

      expect(DocumentSize.of(make()), DocumentSize.of(make()));
    });
  });

  group('Given the Sheets estimator (Drive 03 §11)', () {
    test('when a row counts then only its properties do, not its id, sheet, '
        'order or creation time', () {
      final sql = SheetsSizeEstimator.valueBytes('sheet_row');

      expect(sql, contains('t."height"'));
      expect(sql, contains('t."hidden"'));
      expect(sql, contains('t."formatJson"'));
      for (final c in [
        'id',
        'fileId',
        'revision',
        'sheetId',
        'sortKey',
        'createdAt',
      ]) {
        expect(sql, isNot(contains('t."$c"')));
      }
    });

    test('when script builds or the spreadsheet row are priced then they '
        'cost nothing beyond the base', () {
      expect(SheetsSizeEstimator.excluded, contains('script_build'));
      expect(SheetsSizeEstimator.rowBytes('spreadsheet'), '0');
    });
  });

  group('Given a spreadsheet pre-check estimate', () {
    test('when the sheets have more cells then the estimate is larger', () {
      const small = [
        TemplateSheet(
          name: 'A',
          rows: [
            ['x'],
          ],
        ),
      ];
      final big = [
        TemplateSheet(
          name: 'A',
          rows: [
            for (var i = 0; i < 100; i++) ['row $i', null, ''],
          ],
        ),
      ];

      expect(
        StorageHooks.sheetsEstimate(big),
        greaterThan(StorageHooks.sheetsEstimate(small)),
      );
      expect(StorageHooks.sheetsEstimate(const []), greaterThan(0));
    });

    test('when a sheet is empty then it costs the base and the sheet, like '
        'the estimator', () {
      expect(
        StorageHooks.sheetsEstimate(const [TemplateSheet(name: 'A', rows: [])]),
        SheetsSizeEstimator.base + SheetsSizeEstimator.sheetBytes,
      );
    });

    test('when cells are filled then each costs its text, the content prefix '
        'and the row overhead; empty cells and bold rows without text cost '
        'nothing', () {
      const sheet = TemplateSheet(
        name: 'A',
        boldRows: {},
        rows: [
          ['abc', null, ''],
          ['é'],
        ],
      );

      expect(
        StorageHooks.sheetsEstimate(const [sheet]),
        SheetsSizeEstimator.base +
            SheetsSizeEstimator.sheetBytes +
            (SheetsSizeEstimator.propertyRowBytes + 3 + 2) +
            (SheetsSizeEstimator.propertyRowBytes + 2 + 2),
      );
    });
  });

  group('Given reconcile drift (Drive 03 §4.3)', () {
    const cases = <(int, int, bool)>[
      (1000, 1000, false),
      (1000, 1005, false),
      (1000, 1011, true),
      (10 * 1024 * 1024, 10 * 1024 * 1024 + 65 * 1024, true),
      (100 * 1024 * 1024, 100 * 1024 * 1024 + 60 * 1024, false),
      (0, 1, true),
    ];
    for (final (before, after, logged) in cases) {
      test('when a counter goes from $before to $after then it is '
          '${logged ? '' : 'not '}logged', () {
        expect(StorageMaintenance.significant(before, after), logged);
      });
    }
  });

  group('Given the over-quota notice (Drive 03 §9.3)', () {
    test('when the user uses 73.2 MB of 50 MB then the text says so', () {
      final text = StorageMaintenance.overQuotaMessage(
        usedBytes: (73.2 * 1024 * 1024).round(),
        quota: 50 * 1024 * 1024,
      );

      expect(
        text,
        'Wonky Work now includes 50 MB of storage per person. '
        "You're using 73.2 MB — you can keep editing, but free up space to "
        'upload or copy files again.',
      );
    });
  });
}
