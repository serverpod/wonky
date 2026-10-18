import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';

/// A [Random] whose doubles are always [value] (0.5 = no jitter).
class _FixedRandom implements Random {
  _FixedRandom([this.value = 0.5]);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

/// The streams a supervised key opened, in order, each a controller the test
/// drives; [failOpen] makes `open` throw instead.
class _Source {
  final List<StreamController<int>> opened = [];
  final List<bool> cancelled = [];
  bool failOpen = false;

  int get opens => opened.length + _thrown;
  int _thrown = 0;

  StreamController<int> get last => opened.last;

  Stream<int> open() {
    if (failOpen) {
      _thrown++;
      throw StateError('connect failed');
    }
    final index = opened.length;
    cancelled.add(false);
    final c = StreamController<int>(onCancel: () => cancelled[index] = true);
    opened.add(c);
    return c.stream;
  }
}

void main() {
  late ConnectivityService connectivity;
  late StreamSupervisor supervisor;
  late _Source source;
  late List<int> data;
  late List<Object> errors;
  late int connects;

  setUp(() {
    connectivity = ConnectivityService(ping: () async {});
    supervisor = StreamSupervisor(connectivity, random: _FixedRandom());
    source = _Source();
    data = [];
    errors = [];
    connects = 0;
  });

  tearDown(() {
    supervisor.dispose();
    connectivity.dispose();
  });

  SupervisedStream superviseKey([String key = 'k']) =>
      supervisor.supervise<int>(
        key,
        source.open,
        data.add,
        onError: errors.add,
        onConnected: () => connects++,
      );

  /// Pumps in 100 ms steps until the stream is opened again; returns the
  /// time it took.
  Future<Duration> nextRetry(WidgetTester tester) async {
    final before = source.opens;
    var waited = Duration.zero;
    while (source.opens == before) {
      if (waited > const Duration(minutes: 1)) fail('Not reopened in 1 min');
      await tester.pump(const Duration(milliseconds: 100));
      waited += const Duration(milliseconds: 100);
    }
    return waited;
  }

  group('Given a supervised stream', () {
    testWidgets('when it emits then the events are delivered and it counts '
        'as connected once', (tester) async {
      superviseKey();

      source.last
        ..add(1)
        ..add(2);
      await tester.pump();

      expect(data, [1, 2]);
      expect(connects, 1);
      expect(supervisor.isActive('k'), isTrue);
    });

    testWidgets('when it errors then the error is reported and the stream is '
        'reopened after 1 s', (tester) async {
      superviseKey();

      source.last.addError(StateError('lost'));
      await tester.pump(const Duration(milliseconds: 999));

      expect(errors, [isA<StateError>()]);
      expect(source.opens, 1);
      await tester.pump(const Duration(milliseconds: 1));
      expect(source.opens, 2);
      expect(connects, 2);
    });

    testWidgets('when it keeps failing then the backoff doubles up to 30 s', (
      tester,
    ) async {
      source.failOpen = true;
      superviseKey();

      final delays = [for (var i = 0; i < 7; i++) await nextRetry(tester)];

      expect(delays, [
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 4),
        const Duration(seconds: 8),
        const Duration(seconds: 16),
        const Duration(seconds: 30),
        const Duration(seconds: 30),
      ]);
      expect(errors, hasLength(8));
      supervisor.dispose();
    });

    testWidgets('when a reconnected stream delivers data then the backoff '
        'starts again at 1 s', (tester) async {
      superviseKey();
      source.last.addError(StateError('lost'));
      expect(await nextRetry(tester), const Duration(seconds: 1));
      source.last.addError(StateError('lost'));
      expect(await nextRetry(tester), const Duration(seconds: 2));

      source.last.add(7);
      await source.last.close();
      await tester.pump();

      expect(await nextRetry(tester), const Duration(seconds: 1));
      expect(data, [7]);
    });

    testWidgets('when the stream ends then it is reopened', (tester) async {
      superviseKey();

      await source.last.close();

      expect(await nextRetry(tester), const Duration(seconds: 1));
      expect(errors, isEmpty);
    });
  });

  testWidgets('Given jitter at its minimum when a stream fails then the retry '
      'comes after 80 % of the backoff', (tester) async {
    supervisor.dispose();
    supervisor = StreamSupervisor(connectivity, random: _FixedRandom(0));
    superviseKey();

    source.last.addError(StateError('lost'));

    expect(await nextRetry(tester), const Duration(milliseconds: 800));
  });

  group('Given a supervised key that is supervised again', () {
    testWidgets('when the new stream emits then only the new handler gets '
        'events and the old subscription is cancelled', (tester) async {
      superviseKey();
      final first = source.last;
      final replaced = <int>[];

      supervisor.supervise<int>('k', source.open, replaced.add);
      await tester.pump();
      first.add(1);
      source.last.add(2);
      await tester.pump();

      expect(source.cancelled, [true, false]);
      expect(data, isEmpty);
      expect(replaced, [2]);
    });

    testWidgets('when the old stream had a retry pending then the retry does '
        'not reopen anything', (tester) async {
      superviseKey();
      source.last.addError(StateError('lost'));
      await tester.pump();

      supervisor.supervise<int>('k', source.open, data.add);
      await tester.pump(const Duration(seconds: 5));

      expect(source.opens, 2);
    });
  });

  group('Given a supervised stream that is cancelled', () {
    testWidgets('when cancelled through its handle then the subscription is '
        'cancelled and the key is inactive', (tester) async {
      final handle = superviseKey();

      unawaited(handle.cancel());
      await tester.pump();

      expect(source.cancelled, [true]);
      expect(supervisor.isActive('k'), isFalse);
    });

    testWidgets('when it had a retry pending then it is not reopened', (
      tester,
    ) async {
      superviseKey();
      source.last.addError(StateError('lost'));
      await tester.pump();

      unawaited(supervisor.cancel('k'));
      await tester.pump(const Duration(seconds: 60));

      expect(source.opens, 1);
    });

    testWidgets('when everything is cancelled then every subscription ends', (
      tester,
    ) async {
      superviseKey('a');
      superviseKey('b');

      await tester.runAsync(supervisor.cancelAll);

      expect(source.cancelled, [true, true]);
      expect(supervisor.isActive('a'), isFalse);
      expect(supervisor.isActive('b'), isFalse);
    });
  });

  group('Given the connection is lost', () {
    testWidgets('when a stream ends while offline then it is not reopened '
        'until the connection is back, and then at once', (tester) async {
      superviseKey();
      connectivity.reportFailure();

      await source.last.close();
      await tester.pump(const Duration(seconds: 60));
      expect(source.opens, 1);

      connectivity.reportSuccess();

      expect(source.opens, 2);
      expect(connects, 2);
    });

    testWidgets('when a stream is supervised offline then it opens once the '
        'connection is back', (tester) async {
      connectivity.reportFailure();
      superviseKey();
      expect(source.opens, 0);

      connectivity.reportSuccess();

      expect(source.opens, 1);
    });

    testWidgets('when the connection returns then a live stream is '
        'resubscribed and the backoff is reset', (tester) async {
      superviseKey();
      source.last.addError(StateError('lost'));
      await nextRetry(tester);
      connectivity.reportFailure();

      connectivity.reportSuccess();
      expect(source.cancelled[1], isTrue);
      expect(source.opens, 3);
      source.last.addError(StateError('lost'));

      expect(await nextRetry(tester), const Duration(seconds: 1));
    });

    testWidgets('when offline is simulated then every stream is dropped and '
        'reopened when the simulation ends', (tester) async {
      addTearDown(() => connectivity.forceOffline(false));
      superviseKey('a');
      superviseKey('b');

      connectivity.forceOffline(true);
      expect(source.cancelled, [true, true]);
      await tester.pump(const Duration(seconds: 60));
      expect(source.opens, 2);

      connectivity.forceOffline(false);
      await tester.pump();

      expect(source.opens, 4);
      expect(source.cancelled, [true, true, false, false]);
    });
  });

  testWidgets('Given a disposed supervisor when the connection returns then '
      'nothing is reopened', (tester) async {
    superviseKey();
    connectivity.reportFailure();

    supervisor.dispose();
    await tester.pump();
    connectivity.reportSuccess();

    expect(source.cancelled, [true]);
    expect(source.opens, 1);
    expect(supervisor.isActive('k'), isFalse);
  });
}
