import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

import 'function_vectors.dart';

void main() {
  final t = FormulaTestBench(now: DateTime.utc(2026, 10, 12, 14, 30, 15));
  t.setRows('A1', [
    ['Name', 'Region', 'Sales', 'Date', 'Paid'],
    ['Ann', 'East', 100, '=DATE(2024, 1, 15)', true],
    ['Bob', 'West', 200, '=DATE(2024, 2, 10)', false],
    ['Cid', 'East', 50, '=DATE(2024, 3, 5)', true],
    ['Dee', 'West', 'n/a', '=DATE(2024, 4, 1)', true],
    ['Eve', 'North', 75, '=DATE(2025, 5, 20)', false],
  ]);

  group('Given a QUERY with select, where, order by, limit and offset', () {
    formulaVectors(t, const [
      (
        '=QUERY(A1:E6, "select A, C where C > 60 order by C desc")',
        [
          ['Name', 'Sales'],
          ['Bob', 200],
          ['Ann', 100],
          ['Eve', 75],
        ],
      ),
      (
        '=QUERY(A1:E6, "select A order by B, A desc limit 2 offset 1")',
        [
          ['Name'],
          ['Ann'],
          ['Eve'],
        ],
      ),
      (
        '=QUERY(A1:E6, "select A where E")',
        [
          ['Name'],
          ['Ann'],
          ['Cid'],
          ['Dee'],
        ],
      ),
      (
        '=QUERY(A1:E6, "select A, C where C is null")',
        [
          ['Name', 'Sales'],
          ['Dee', null],
        ],
      ),
      (
        '=QUERY(A1:E6, "select A where not (B = \'East\' or C >= 200)")',
        [
          ['Name'],
          ['Dee'],
          ['Eve'],
        ],
      ),
      (
        '=QUERY(A1:E6, "select A where D >= date \'2024-03-01\' and D < date \'2025-01-01\'")',
        [
          ['Name'],
          ['Cid'],
          ['Dee'],
        ],
      ),
      ('=QUERY(A1:E6, "select A where C > 1000")', 'Name'),
      ('=QUERY(A2:E6, "select A where C > 1000", 0)', '#N/A'),
    ]);
  });

  group('Given QUERY string operators', () {
    formulaVectors(t, const [
      (
        '=QUERY(A1:E6, "select A where B like \'%st\' and A matches \'[A-C].*\'")',
        [
          ['Name'],
          ['Ann'],
          ['Bob'],
          ['Cid'],
        ],
      ),
      (
        '=QUERY(A1:E6, "select A where B contains \'or\' or A starts with \'B\' or A ends with \'id\'")',
        [
          ['Name'],
          ['Bob'],
          ['Cid'],
          ['Eve'],
        ],
      ),
      ('=QUERY(A1:E6, "select A where B = \'east\'")', 'Name'),
      (
        '=QUERY(A1:E6, "select A where lower(B) = \'east\'")',
        [
          ['Name'],
          ['Ann'],
          ['Cid'],
        ],
      ),
    ]);
  });

  group('Given QUERY aggregation', () {
    formulaVectors(t, const [
      (
        '=QUERY(A1:E6, "select B, sum(C), count(A) group by B")',
        [
          ['Region', 'sum Sales', 'count Name'],
          ['East', 150, 2],
          ['North', 75, 1],
          ['West', 200, 2],
        ],
      ),
      (
        '=QUERY(A1:E6, "select B, sum(C) group by B order by sum(C) desc label sum(C) \'Total\'")',
        [
          ['Region', 'Total'],
          ['West', 200],
          ['East', 150],
          ['North', 75],
        ],
      ),
      (
        '=QUERY(A1:E6, "select avg(C), max(D), min(A)")',
        [
          ['avg Sales', 'max Date', 'min Name'],
          [106.25, 45797, 'Ann'],
        ],
      ),
      (
        '=QUERY(A1:E6, "select year(D), count(A) group by year(D)")',
        [
          ['year(Date)', 'count Name'],
          [2024, 4],
          [2025, 1],
        ],
      ),
      (
        '=QUERY({1, "a"; 2, "b"; 3, "a"}, "select Col2, sum(Col1) group by Col2", 0)',
        [
          ['', 'sum'],
          ['a', 4],
          ['b', 2],
        ],
      ),
    ]);
  });

  group('Given QUERY pivot', () {
    formulaVectors(t, const [
      (
        '=QUERY(A1:E6, "select sum(C) pivot B")',
        [
          ['East', 'North', 'West'],
          [150, 75, 200],
        ],
      ),
      (
        '=QUERY(A1:E6, "select B, count(A) group by B pivot E")',
        [
          ['Region', 'FALSE', 'TRUE'],
          ['East', null, 2],
          ['North', 1, null],
          ['West', 1, 1],
        ],
      ),
      (
        '=QUERY(A1:E6, "select count(A), sum(C) pivot E")',
        [
          [
            'FALSE count Name',
            'FALSE sum Sales',
            'TRUE count Name',
            'TRUE sum Sales',
          ],
          [2, 275, 3, 150],
        ],
      ),
    ]);
  });

  group('Given QUERY scalar functions and arithmetic', () {
    formulaVectors(t, const [
      (
        '=QUERY(A1:E6, "select A, month(D), dayOfWeek(D), quarter(D) where A = \'Bob\'")',
        [
          ['Name', 'month(Date)', 'dayOfWeek(Date)', 'quarter(Date)'],
          ['Bob', 1, 7, 1],
        ],
      ),
      (
        '=QUERY(A1:E6, "select C * 2, C % 30, upper(A) where A starts with \'A\'")',
        [
          ['product(Sales, 2)', 'modulo(Sales, 30)', 'upper(Name)'],
          [200, 10, 'ANN'],
        ],
      ),
      (
        '=QUERY(A1:E6, "select dateDiff(date \'2024-01-20\', D) where A = \'Ann\'")',
        [
          ['dateDiff(date \'2024-01-20\', Date)'],
          [5],
        ],
      ),
      (
        '=QUERY(A1:E6, "select year(now()) limit 1")',
        [
          ['year(now())'],
          [2026],
        ],
      ),
      (
        '=QUERY(A1:E6, "select toDate(1700000000000) limit 1")',
        [
          ['toDate(1700000000000)'],
          [45244],
        ],
      ),
    ]);
  });

  group('Given QUERY column identifiers and headers', () {
    formulaVectors(t, const [
      (
        '=QUERY(B2:C3, "select C, B")',
        [
          [100, 'East'],
          [200, 'West'],
        ],
      ),
      ('=QUERY({"x", 1; "y", 2}, "select Col2 where Col1 = \'y\'")', 2),
      (
        '=QUERY(A1:C3, "select A", 2)',
        [
          ['Name Ann'],
          ['Bob'],
        ],
      ),
      (
        '=QUERY(A1:C3, "select *")',
        [
          ['Name', 'Region', 'Sales'],
          ['Ann', 'East', 100],
          ['Bob', 'West', 200],
        ],
      ),
    ]);
  });

  group('Given an invalid QUERY', () {
    formulaVectors(t, const [
      ('=QUERY(A1:E6, "select Z")', '#VALUE!'),
      ('=QUERY(A1:E6, "select A, sum(C)")', '#VALUE!'),
      ('=QUERY(A1:E6, "selec A")', '#VALUE!'),
      ('=QUERY(A1:E6, "select sum(A)")', '#VALUE!'),
      ('=QUERY(A1:E6, "select A where sum(C) > 1")', '#VALUE!'),
      ('=QUERY(A1:E6, "select * group by B")', '#VALUE!'),
      ('=QUERY(A1:E6, "select B pivot E")', '#VALUE!'),
      ('=QUERY(A1:E6, "select A where D > date \'2024-13-01\'")', '#VALUE!'),
    ]);

    test('when the query does not parse then the message names the token', () {
      final v = t.eval('=QUERY(A1:E6, "selec A")');

      expect(
        v,
        isA<FError>().having(
          (e) => e.message,
          'message',
          'Unable to parse query string for Function QUERY parameter 2: '
              'PARSE_ERROR: Encountered "selec" at line 1, column 1.',
        ),
      );
    });

    test('when a column is unknown then the message is NO_COLUMN', () {
      final v = t.eval('=QUERY(A1:E6, "select Z")');

      expect(
        v,
        isA<FError>().having(
          (e) => e.message,
          'message',
          'Unable to parse query string for Function QUERY parameter 2: NO_COLUMN: Z',
        ),
      );
    });
  });

  group('Given QUERY output formats', () {
    test('when selecting a date column then the values carry a date hint', () {
      final v = t.eval('=QUERY(A1:E6, "select D limit 1")') as FArray;

      expect((v.at(1, 0) as FNumber).hint, FormatHint.date);
    });

    test('when a format clause is given then the values carry its pattern', () {
      final v =
          t.eval('=QUERY(A1:E6, "select C limit 1 format C \'0.0\'")')
              as FArray;

      expect((v.at(1, 0) as FNumber).hint, FormatHint.fromCell('0.0'));
    });

    test('when options no_format is given then the values carry no hint', () {
      final v =
          t.eval('=QUERY(A1:E6, "select D limit 1 options no_format")')
              as FArray;

      expect((v.at(1, 0) as FNumber).hint, FormatHint.none);
    });

    test(
      'when options no_values is given then formatted columns become text',
      () {
        final v =
            t.eval(
                  '=QUERY(A1:E6, "select C limit 1 format C \'0.00\' options no_values")',
                )
                as FArray;

        expect(v.at(1, 0), const FText('100.00'));
      },
    );
  });
}
