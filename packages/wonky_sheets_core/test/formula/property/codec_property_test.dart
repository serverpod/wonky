@Tags(['property'])
library;

import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Property tests for the codec (05 §22.2): `toA1(toStored(x)) == x` for canonical text, and
/// stored formulas after random row/column inserts/deletes render like a positional oracle
/// applying Excel's reference-adjustment rules.

List<int> seeds() {
  final env = Platform.environment['WONKY_SEED'];
  if (env != null) return [int.parse(env)];
  return const [1, 7, 42, 2026, 31337];
}

int runs() =>
    int.tryParse(Platform.environment['WONKY_PROPERTY_RUNS'] ?? '') ?? 60;

/// A positional reference tracked by the oracle (null rect = #REF!).
final class _Ref {
  int r1, c1, r2, c2;
  final bool range;
  bool dead = false;
  _Ref(this.r1, this.c1, this.r2, this.c2, {required this.range});

  String a1() {
    if (dead) return '#REF!';
    if (!range) return A1Area.cell(r1, c1).format();
    return A1Area.rect(r1, c1, r2, c2).format();
  }
}

void _insert(List<_Ref> refs, bool rows, int k, int n) {
  for (final r in refs) {
    if (r.dead) continue;
    if (rows) {
      if (r.r1 >= k) r.r1 += n;
      if (r.r2 >= k) r.r2 += n;
    } else {
      if (r.c1 >= k) r.c1 += n;
      if (r.c2 >= k) r.c2 += n;
    }
  }
}

void _delete(List<_Ref> refs, bool rows, int k, int n) {
  final e = k + n - 1;
  (int, int)? adj(int a, int b) {
    if (a >= k && b <= e) return null;
    final na = a < k ? a : (a > e ? a - n : k);
    final nb = b < k ? b : (b > e ? b - n : k - 1);
    return (na, nb);
  }

  for (final r in refs) {
    if (r.dead) continue;
    if (!r.range) {
      final v = rows ? r.r1 : r.c1;
      if (v >= k && v <= e) {
        r.dead = true;
        continue;
      }
      if (v > e) {
        if (rows) {
          r.r1 -= n;
          r.r2 -= n;
        } else {
          r.c1 -= n;
          r.c2 -= n;
        }
      }
      continue;
    }
    final res = rows ? adj(r.r1, r.r2) : adj(r.c1, r.c2);
    if (res == null) {
      r.dead = true;
      continue;
    }
    if (rows) {
      r.r1 = res.$1;
      r.r2 = res.$2;
    } else {
      r.c1 = res.$1;
      r.c2 = res.$2;
    }
  }
}

void main() {
  for (final seed in seeds()) {
    test(
      'Given random formulas (seed $seed) when round-tripping A1 → stored → A1 then the text is unchanged',
      () {
        final rnd = Random(seed);
        final wb = MemoryWorkbook();
        final s = wb.addSheet('Sheet1', rows: 200, cols: 30);
        wb.addSheet('Other sheet', rows: 50, cols: 10);
        final ctx = CodecContext(
          workbook: wb,
          hostSheetId: s.id,
          hostRow: 150,
          hostCol: 25,
        );
        const fns = ['SUM', 'MAX', 'IF', 'VLOOKUP', 'COUNTIF'];
        String refText() {
          final abs = rnd.nextBool();
          final r = rnd.nextInt(100), c = rnd.nextInt(20);
          final a = rnd.nextInt(4) == 0
              ? A1Area.rect(
                  r,
                  c,
                  r + rnd.nextInt(30),
                  c + rnd.nextInt(5),
                  absRow1: abs,
                  absCol2: abs,
                )
              : A1Area.cell(r, c, absCol: abs);
          final other = rnd.nextInt(6) == 0;
          return other ? "'Other sheet'!${a.format()}" : a.format();
        }

        String expr(int depth) {
          final k = rnd.nextInt(depth > 2 ? 3 : 6);
          return switch (k) {
            0 => refText(),
            1 => '${rnd.nextInt(1000)}',
            2 => '"t${rnd.nextInt(9)}"',
            3 => '${expr(depth + 1)}+${expr(depth + 1)}',
            4 =>
              '${fns[rnd.nextInt(fns.length)]}(${expr(depth + 1)}, ${expr(depth + 1)})',
            _ => '(${expr(depth + 1)})*-${expr(depth + 1)}',
          };
        }

        for (var i = 0; i < runs(); i++) {
          final text = '=${expr(0)}';
          final stored = FormulaCodec.toStored(text, ctx);
          expect(
            FormulaCodec.toA1(stored, ctx),
            text,
            reason: 'seed $seed: $text',
          );
          expect(
            FormulaCodec.toStored(FormulaCodec.toA1(stored, ctx), ctx),
            stored,
          );
        }
      },
    );

    test(
      'Given stored ranges (seed $seed) when only deleting rows without repair then the sort-key fallback shrinks them like the oracle',
      () {
        final rnd = Random(seed);
        final wb = MemoryWorkbook();
        final s = wb.addSheet('Sheet1', rows: 300, cols: 10);
        final refs = <_Ref>[];
        final stored = <String>[];
        final hostRowId = s.rows.idAt(299);
        CodecContext ctx() => CodecContext(
          workbook: wb,
          hostSheetId: s.id,
          hostRow: s.rows.indexOf(hostRowId),
        );
        for (var i = 0; i < 20; i++) {
          final r = 10 + rnd.nextInt(100);
          final ref = _Ref(r, 1, r + rnd.nextInt(40), 2, range: true);
          refs.add(ref);
          stored.add(FormulaCodec.toStored('=${ref.a1()}', ctx()));
        }
        for (var step = 0; step < 10; step++) {
          final k = rnd.nextInt(150), n = 1 + rnd.nextInt(5);
          s.rows.delete(k, n);
          _delete(refs, true, k, n);
          for (var i = 0; i < refs.length; i++) {
            expect(
              FormulaCodec.toA1(stored[i], ctx()),
              '=${refs[i].a1()}',
              reason: 'seed $seed step $step ref $i',
            );
          }
        }
      },
    );

    test(
      'Given stored references (seed $seed) when applying random inserts and deletes then the A1 form matches the positional oracle',
      () {
        final rnd = Random(seed);
        final wb = MemoryWorkbook();
        final s = wb.addSheet('Sheet1', rows: 300, cols: 40);
        // host far away so it is never deleted
        final refs = <_Ref>[];
        final texts = <String>[];
        for (var i = 0; i < 30; i++) {
          final r = 10 + rnd.nextInt(100), c = 2 + rnd.nextInt(20);
          final range = rnd.nextBool();
          final ref = range
              ? _Ref(r, c, r + rnd.nextInt(40), c + rnd.nextInt(6), range: true)
              : _Ref(r, c, r, c, range: false);
          refs.add(ref);
          texts.add('=${ref.a1()}');
        }
        final hostRowId = s.rows.idAt(299), hostColId = s.columns.idAt(39);
        CodecContext ctx() => CodecContext(
          workbook: wb,
          hostSheetId: s.id,
          hostRow: s.rows.indexOf(hostRowId),
          hostCol: s.columns.indexOf(hostColId),
        );
        final stored = [for (final t in texts) FormulaCodec.toStored(t, ctx())];
        for (var step = 0; step < 25; step++) {
          final rows = rnd.nextBool();
          final axis = rows ? s.rows : s.columns;
          final maxK = rows ? 150 : 30;
          final k = rnd.nextInt(maxK);
          final n = 1 + rnd.nextInt(4);
          if (rnd.nextBool()) {
            axis.insert(k, n);
            _insert(refs, rows, k, n);
          } else {
            // write-time boundary repair in the same transaction as the delete (05 §5.4)
            final ids = {for (var i = k; i < k + n; i++) axis.idAt(i)};
            for (var i = 0; i < stored.length; i++) {
              stored[i] =
                  ReferenceRewriter.repairBoundaries(
                    stored[i],
                    workbook: wb,
                    deletedRowIds: rows ? ids : const {},
                    deletedColIds: rows ? const {} : ids,
                    hostSheetId: s.id,
                  ) ??
                  stored[i];
            }
            axis.delete(k, n);
            _delete(refs, rows, k, n);
          }
          for (var i = 0; i < refs.length; i++) {
            expect(
              FormulaCodec.toA1(stored[i], ctx()),
              '=${refs[i].a1()}',
              reason: 'seed $seed step $step ref $i (${texts[i]})',
            );
          }
        }
      },
    );
  }
}
