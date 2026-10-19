import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:wonky_server/src/generated/protocol.dart';
import 'package:wonky_server/src/platform/common/isolate_runner.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

/// `IsolateRunner` (code-quality T4, CQ-24): work runs in its own isolate,
/// is killed on timeout or cancel, waits for a global slot, and can ask the
/// calling isolate through a channel.
void main() {
  const long = Duration(seconds: 20);
  late int savedMax;
  late Duration savedWait;
  setUp(() {
    savedMax = IsolateRunner.maxConcurrent;
    savedWait = IsolateRunner.maxQueueWait;
  });
  tearDown(() {
    IsolateRunner.maxConcurrent = savedMax;
    IsolateRunner.maxQueueWait = savedWait;
  });

  /// Work that blocks until the calling isolate answers its request.
  Future<String> gated(
    Completer<void> gate, {
    IsolateCancelToken? cancel,
    void Function()? onAsked,
  }) => IsolateRunner.runWithChannel<String>(
    _askOnce,
    name: 'gated',
    timeout: long,
    cancel: cancel,
    onRequest: (_) async {
      onAsked?.call();
      await gate.future;
      return 'done';
    },
  );

  group('Given work in its own isolate', () {
    test('when it finishes then its result is returned', () async {
      final r = await IsolateRunner.run(
        () async => 'converted',
        name: 'test',
        timeout: long,
      );

      expect(r, 'converted');
      expect(IsolateRunner.running, 0);
    });

    test('when it throws then the error keeps its type', () async {
      await expectLater(
        IsolateRunner.run<int>(
          () => throw const ImportTooLargeException(
            ImportLimitKind.unpackedBytes,
            actual: 2,
            limit: 1,
          ),
          name: 'test',
          timeout: long,
        ),
        throwsA(
          isA<ImportTooLargeException>().having(
            (e) => e.kind,
            'kind',
            ImportLimitKind.unpackedBytes,
          ),
        ),
      );
      expect(IsolateRunner.running, 0);
    });

    test('when it runs past the timeout then it is killed and a '
        'TimeoutException is thrown', () async {
      final beats = ReceivePort();
      var count = 0;
      beats.listen((_) => count++);
      final sendPort = beats.sendPort;

      await expectLater(
        IsolateRunner.run<void>(
          () {
            // Runaway work: never yields, reports that it still runs.
            for (var i = 0; ; i++) {
              if (i % 1000000 == 0) sendPort.send(i);
            }
          },
          name: 'runaway',
          timeout: const Duration(milliseconds: 300),
        ),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final afterKill = count;
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(afterKill, greaterThan(0));
      expect(count, afterKill, reason: 'the isolate still runs');
      expect(IsolateRunner.running, 0);
      beats.close();
    });

    test('when it posts and asks then the calling isolate receives and '
        'answers', () async {
      final posted = <Object?>[];

      final r = await IsolateRunner.runWithChannel<String>(
        _postAndAsk,
        name: 'channel',
        timeout: long,
        onRequest: (m) async => (m! as int) * 2,
        onMessage: posted.add,
      );

      expect(r, 'answer 42');
      expect(posted, [0.5]);
    });

    test('when the answer fails then the request throws in the worker', () {
      expect(
        IsolateRunner.runWithChannel<Object?>(
          _askOnce,
          name: 'channel',
          timeout: long,
          onRequest: (_) async => throw StateError('no session'),
        ),
        throwsA(isA<RemoteError>()),
      );
    });
  });

  group('Given one slot', () {
    setUp(() => IsolateRunner.maxConcurrent = 1);

    test('when a second run starts then it waits for the first', () async {
      final gate = Completer<void>();
      final asked = Completer<void>();
      final first = gated(gate, onAsked: asked.complete);
      await asked.future;

      var secondDone = false;
      final second =
          IsolateRunner.run(
            () => 'second',
            name: 'second',
            timeout: long,
          ).then((r) {
            secondDone = true;
            return r;
          });
      await pumpEventQueue();

      expect(IsolateRunner.running, 1);
      expect(IsolateRunner.queued, 1);
      expect(secondDone, isFalse);

      gate.complete();
      expect(await first, 'done');
      expect(await second, 'second');
      expect(IsolateRunner.running, 0);
      expect(IsolateRunner.queued, 0);
    });

    test('when the wait is too long then the run fails as busy', () async {
      IsolateRunner.maxQueueWait = const Duration(milliseconds: 50);
      final gate = Completer<void>();
      final asked = Completer<void>();
      final first = gated(gate, onAsked: asked.complete);
      await asked.future;

      await expectLater(
        IsolateRunner.run(() => 1, name: 'late', timeout: long),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.busy,
          ),
        ),
      );
      expect(IsolateRunner.queued, 0);

      gate.complete();
      await first;
      expect(IsolateRunner.running, 0);
    });

    test('when a waiting run is cancelled then it leaves the queue', () async {
      final gate = Completer<void>();
      final asked = Completer<void>();
      final first = gated(gate, onAsked: asked.complete);
      await asked.future;
      final cancel = IsolateCancelToken();

      final waiting = IsolateRunner.run(
        () => 1,
        name: 'cancelled',
        timeout: long,
        cancel: cancel,
      );
      await pumpEventQueue();
      cancel.cancel();

      await expectLater(waiting, throwsA(isA<IsolateCancelledException>()));
      expect(IsolateRunner.queued, 0);
      gate.complete();
      await first;
      expect(IsolateRunner.running, 0);
    });
  });

  group('Given running work', () {
    test(
      'when it is cancelled then it is killed and the slot is free',
      () async {
        final cancel = IsolateCancelToken();
        final asked = Completer<void>();
        final run = gated(
          Completer<void>(),
          cancel: cancel,
          onAsked: asked.complete,
        );
        await asked.future;

        cancel.cancel();

        await expectLater(run, throwsA(isA<IsolateCancelledException>()));
        expect(IsolateRunner.running, 0);
      },
    );
  });
}

// Work functions are top-level so that their closures capture nothing of
// the test (everything a closure's context holds is copied into the
// isolate).

Future<String> _askOnce(IsolateChannel channel) async =>
    '${await channel.request('may I?')}';

Future<String> _postAndAsk(IsolateChannel channel) async {
  channel.post(0.5);
  final answer = await channel.request(21);
  return 'answer $answer';
}
