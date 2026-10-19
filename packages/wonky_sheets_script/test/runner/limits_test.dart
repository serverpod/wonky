import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_sheets_script/native.dart';
import 'package:wonky_sheets_script/testing.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

const _source = '''
import 'package:wonky/wonky.dart';

void spin() {
  var i = 0;
  while (true) {
    i++;
  }
}

void spinReading() {
  while (true) {
    SpreadsheetApp.active.getRange('A1').value;
  }
}

Object? spinInCatch() {
  try {
    while (true) {}
  } catch (e) {
    return 'caught';
  }
}

Object? hugeList() => List.filled(1000000000, 0).length;

void grow() {
  final keep = <Object?>[];
  while (true) {
    keep.add(List.filled(1000000, 0));
  }
}

Object? hello() => 'hello';
''';

const _short = ExecutionLimits(timeout: Duration(milliseconds: 400));

/// Time limits, kills and memory guards (09 §21.2).
void main() {
  late ScriptProgram program;
  setUpAll(() => program = compileScript({'main.dart': _source}));

  for (final (name, create) in <(String, ScriptRunner Function())>[
    ('inline runner', InlineScriptRunner.new),
    ('isolate runner', IsolateScriptRunner.new),
  ]) {
    group('Given the $name', () {
      late ScriptRunner runner;
      late ScriptTestBench bench;
      setUp(() {
        runner = create();
        bench = ScriptTestBench(conformanceWorkbook(), runner: runner);
      });
      tearDown(() async {
        bench.dispose();
        await runner.close();
      });

      test(
        'when a function loops forever then it times out and the next run succeeds',
        () async {
          final watch = Stopwatch()..start();
          final r = await bench.run(program, 'spin', limits: _short);
          expect(r.status, ExecutionStatus.timedOut);
          expect(r.error!.message, contains('Exceeded maximum execution time'));
          expect(watch.elapsed, lessThan(const Duration(milliseconds: 1400)));
          expect((await bench.run(program, 'hello')).result, 'hello');
        },
      );

      test('when a loop calls the host forever then it times out', () async {
        final r = await bench.run(program, 'spinReading', limits: _short);
        expect(r.status, ExecutionStatus.timedOut);
      });

      test(
        'when the loop is inside try/catch then the timeout cannot be caught',
        () async {
          final r = await bench.run(program, 'spinInCatch', limits: _short);
          expect(r.status, ExecutionStatus.timedOut);
        },
      );

      test(
        'when a script allocates a huge list then the quota stops it',
        () async {
          final r = await bench.run(program, 'hugeList');
          expect(r.status, ExecutionStatus.quotaExceeded);
          expect((await bench.run(program, 'hello')).result, 'hello');
        },
      );
    });
  }

  group('Given the isolate runner', () {
    test(
      'when a script runs forever then the host event loop stays responsive',
      () async {
        final runner = IsolateScriptRunner();
        final bench = ScriptTestBench(conformanceWorkbook(), runner: runner);
        var ticks = 0;
        final timer = Timer.periodic(
          const Duration(milliseconds: 10),
          (_) => ticks++,
        );
        final r = await bench.run(
          program,
          'spin',
          limits: const ExecutionLimits(timeout: Duration(seconds: 1)),
        );
        timer.cancel();
        expect(r.status, ExecutionStatus.timedOut);
        expect(ticks, greaterThan(40));
        await runner.close();
      },
    );

    test(
      'when memory grows past the RSS limit then the watchdog kills the guest',
      () async {
        final limit = ProcessInfo.currentRss + 300 * 1024 * 1024;
        final runner = IsolateScriptRunner(maxRssBytes: limit);
        final bench = ScriptTestBench(conformanceWorkbook(), runner: runner);
        final r = await bench.run(
          program,
          'grow',
          limits: const ExecutionLimits(timeout: Duration(seconds: 20)),
        );
        expect(r.status, ExecutionStatus.quotaExceeded);
        expect(runner.kills, 1);
        // The watchdog reads the process RSS, and the killed guest's memory
        // goes back to the OS some time after the kill: until then, any run
        // would be stopped too. Wait for it, then the runner recovers.
        final watch = Stopwatch()..start();
        while (ProcessInfo.currentRss > limit &&
            watch.elapsed < const Duration(seconds: 30)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        final hello = await bench.run(program, 'hello');
        expect(hello.status, ExecutionStatus.completed);
        expect(hello.result, 'hello');
        await runner.close();
      },
      // The wait for the OS to take the guest's memory back can take up to
      // 30 s (Windows keeps the working set longer than Linux).
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test('when cancelled then the execution stops', () async {
      final runner = IsolateScriptRunner();
      final bench = ScriptTestBench(conformanceWorkbook(), runner: runner);
      final pending = bench.run(
        program,
        'spinReading',
        limits: const ExecutionLimits(timeout: Duration(seconds: 20)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      runner.cancel();
      expect((await pending).status, ExecutionStatus.cancelled);
      await runner.close();
    });
  });
}
