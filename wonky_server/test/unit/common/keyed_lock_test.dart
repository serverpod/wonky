import 'dart:async';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/keyed_lock.dart';

/// The planning lock of headless spreadsheet and deck writes (CQ-52,
/// CQ-8): one holder per key, first come first served, and a waiter that
/// times out never lets the next one in early.
void main() {
  final busy = StateError('busy');

  group('Given a lock held for one key', () {
    late KeyedLock lock;
    late Completer<void> holder;
    late Future<String> first;

    setUp(() async {
      lock = KeyedLock();
      holder = Completer<void>();
      first = lock.run('a', () async {
        await holder.future;
        return 'first';
      }, busy: () => busy);
      await pumpEventQueue();
    });

    test('when another key is locked then it runs at once', () async {
      final other = await lock.run('b', () async => 'b', busy: () => busy);

      expect(other, 'b');
      expect(lock.isLocked('a'), isTrue);
      holder.complete();
      await first;
    });

    test('when a second caller waits then it runs after the holder, in '
        'order', () async {
      final order = <String>[];
      final second = lock.run('a', () async {
        order.add('second');
      }, busy: () => busy);
      final third = lock.run('a', () async {
        order.add('third');
      }, busy: () => busy);
      await pumpEventQueue();
      expect(order, isEmpty);

      holder.complete();
      await Future.wait([first, second, third]);

      expect(order, ['second', 'third']);
      expect(lock.length, 0);
    });

    test('when a waiter times out then it fails busy and the next waiter '
        'still waits for the holder', () async {
      lock.timeout = Duration.zero;
      final timedOut = lock.run('a', () async => 'never', busy: () => busy);
      await expectLater(timedOut, throwsA(same(busy)));

      lock.timeout = const Duration(minutes: 1);
      var nextRan = false;
      final next = lock.run('a', () async {
        nextRan = true;
      }, busy: () => busy);
      await pumpEventQueue();
      expect(nextRan, isFalse);

      holder.complete();
      await next;

      expect(nextRan, isTrue);
      expect(await first, 'first');
      expect(lock.length, 0);
    });

    test('when the body throws then the lock is released', () async {
      holder.complete();
      await first;

      await expectLater(
        lock.run('a', () async => throw ArgumentError('x'), busy: () => busy),
        throwsArgumentError,
      );

      expect(lock.isLocked('a'), isFalse);
    });
  });
}
