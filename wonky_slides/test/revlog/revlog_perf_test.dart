@Tags(['slow'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' show Uuid;
import 'package:wonky_revlog/apply.dart' show parentsFirst;
import 'package:wonky_revlog/client.dart' show RevChunker;
import 'package:wonky_revlog/codec.dart' show ChangeSet, RevCodec;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_slides_core/revlog.dart' show slidesSchema;
import 'package:wonky_slides_core/schema.dart' show ElementCols, SlidesTables;
import 'package:wonky_slides_core/testing.dart';

import 'support/deck_harness.dart';

/// The deck gates of RevLog (spec 17 part 7 P1, P6, P8 for a 500-slide
/// deck; plans/sheets-sync-migration/spec/10 R7) on the client, against
/// the in-process [FakeRevHub] with a real SQLite cache. Prints a results
/// table; the numbers are in `plans/sheets-sync-migration/baseline.md`.
///
/// Run: `flutter test -t slow test/revlog/revlog_perf_test.dart`.
void main() {
  test('Given a 500-slide deck then the client deck gates hold', () async {
    final hub = slidesHub();
    final anna = const Uuid().v7obj();
    final ben = const Uuid().v7obj();
    final file = const Uuid().v7obj();

    // 500 slides × (title, body, 12 shapes, 2 text boxes, a 3 × 3 table).
    final b = DeckBuilder(deckId: file.uuid, title: 'Perf');
    for (var s = 0; s < 500; s++) {
      final id = b.slide(title: 'Slide $s', body: 'Body of slide $s');
      for (var i = 0; i < 12; i++) {
        b.shape(
          id,
          x: 60.0 + (i % 4) * 400,
          y: 260.0 + (i ~/ 4) * 220,
          width: 300,
          height: 150,
          text: 'Shape $i',
          fillJson: jsonEncode({
            'v': 1,
            'type': 'solid',
            'color': i.isEven ? '#3366FF' : '#22C55E',
          }),
        );
      }
      b.textBox(id, 'A text box with a sentence or two of text on it.');
      b.textBox(id, 'Another text box.', y: 900);
      final (t, rows, cols) = b.table(
        id,
        rows: 3,
        cols: 3,
        x: 1300,
        y: 700,
        width: 500,
        height: 240,
      );
      for (final r in rows) {
        for (final c in cols) {
          b.cell(t, r, c, 'Cell');
        }
      }
    }
    final inserts = parentsFirst(slidesSchema, [
      for (final (table, row) in b.rows)
        RowChange.insert(table, row['id']! as String, {
          for (final e in row.entries)
            if (e.key != 'id') e.key: e.value,
        }),
    ]);
    for (final op in RevChunker.split(
      ChangeSet(
        clientOpId: const Uuid().v7(),
        baseRevision: 0,
        changes: inserts,
        label: 'Import',
      ),
      RevCodec(slidesSchema, lenient: true),
      () => const Uuid().v7(),
    )) {
      hub.commit(file.uuid, anna.uuid, op);
    }

    // P6: cold open (not on the device).
    final dev = await DeckDevice.start(hub, ben);
    final watch = Stopwatch()..start();
    final s1 = await dev.openFile(
      file,
      maintenanceDelay: const Duration(hours: 1),
    );
    final opened = watch.elapsedMilliseconds;
    await s1.flush();
    final stored = watch.elapsedMilliseconds;
    final slides = s1.model.slides.length;
    _results.add(
      _Result(
        'P6',
        'Cold open of a $slides-slide deck (${inserts.length} rows) → '
            'DeckReady (pages into SQLite: $stored ms)',
        '< 1.5 s desktop',
        '$opened ms',
        pass: opened < 1500,
      ),
    );

    // P1 (client part): another device's op applied to the model.
    final remote = <int>[];
    final element = s1.model.elementsOf(s1.model.slides[3].id).last;
    for (var i = 0; i < 220; i++) {
      final got = s1.remoteBatches.first;
      final w = Stopwatch()..start();
      commitChanges(hub, file, anna, [
        RowChange.update(
          SlidesTables.slideElement,
          element.id,
          {ElementCols.x: i == 0 ? element.x : 100.0 + i - 1},
          {ElementCols.x: 100.0 + i},
        ),
      ]);
      await got.timeout(const Duration(seconds: 30));
      if (i >= 20) remote.add(w.elapsedMicroseconds);
    }
    _results.add(
      _Result(
        'P1',
        'Remote op (move an element) → applied in a $slides-slide deck '
            '(client part; in-process server)',
        'p95 < 250 ms',
        _dist(remote),
        pass: _p(remote, 95) < 250000,
      ),
    );

    // P8: reopen from the cache.
    await s1.flush();
    await s1.dispose();
    watch
      ..reset()
      ..start();
    final s2 = await dev.openFile(
      file,
      waitReady: false,
      maintenanceDelay: const Duration(hours: 1),
    );
    await whenReady(s2, timeout: const Duration(minutes: 2));
    final reopened = watch.elapsedMilliseconds;
    _results.add(
      _Result(
        'P8',
        'Reopen of the $slides-slide deck from the cache → DeckReady',
        '≤ 0.55 s',
        '$reopened ms',
        pass: reopened <= 550,
      ),
    );
    await dev.close();
    _print();
  }, timeout: const Timeout(Duration(minutes: 30)));
}

int _p(List<int> samples, int p) {
  final s = [...samples]..sort();
  final i = ((p / 100) * (s.length - 1)).round();
  return s[math.min(i, s.length - 1)];
}

String _dist(List<int> us) {
  String f(int v) => (v / 1000).toStringAsFixed(1);
  final mean = us.reduce((a, b) => a + b) / us.length;
  return 'p50 ${f(_p(us, 50))} / p95 ${f(_p(us, 95))} / max '
      '${f(us.reduce(math.max))} ms (mean ${f(mean.round())})';
}

final class _Result {
  _Result(this.gate, this.metric, this.target, this.measured, {this.pass});
  final String gate;
  final String metric;
  final String target;
  final String measured;
  final bool? pass;
}

final _results = <_Result>[];

void _print() {
  final b = StringBuffer()
    ..writeln()
    ..writeln(
      'RevLog Slides client perf (${Platform.operatingSystem}, '
      '${Platform.numberOfProcessors} cpus, flutter test VM, SQLite, '
      'in-process FakeRevHub)',
    )
    ..writeln('| Gate | Metric | Target | Measured | Pass |')
    ..writeln('|------|--------|--------|----------|------|');
  for (final r in _results) {
    final pass = switch (r.pass) {
      true => 'pass',
      false => '**miss**',
      null => '—',
    };
    b.writeln(
      '| ${r.gate} | ${r.metric} | ${r.target} | ${r.measured} | $pass |',
    );
  }
  // ignore: avoid_print
  print(b);
}
