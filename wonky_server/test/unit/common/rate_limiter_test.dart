import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/rate_limiter.dart';

void main() {
  final start = DateTime.utc(2026, 10, 18, 12);

  group('Given an in-memory rate limiter with a one-minute window', () {
    late RateLimiter limiter;
    setUp(
      () => limiter = RateLimiter(
        name: 'test',
        limit: 2,
        window: const Duration(minutes: 1),
      ),
    );

    test('when many keys called once and a window passed then their entries '
        'are dropped on the next call', () {
      withClock(Clock.fixed(start), () {
        for (var i = 0; i < 500; i++) {
          limiter.hit('key $i');
        }
      });
      final before = limiter.trackedKeys;

      withClock(
        Clock.fixed(start.add(const Duration(minutes: 2))),
        () => limiter.hit('fresh'),
      );

      expect(before, 500);
      expect(limiter.trackedKeys, 1);
    });

    test('when a key is still within its window then it is kept and still '
        'limited', () {
      withClock(Clock.fixed(start), () {
        limiter.hit('busy');
        limiter.hit('busy');
      });

      final retry = withClock(
        Clock.fixed(start.add(const Duration(seconds: 30))),
        () => limiter.hit('busy'),
      );

      expect(retry, const Duration(seconds: 30));
    });

    test(
      'when more than maxKeys keys are active then memory stays bounded',
      () {
        withClock(Clock.fixed(start), () {
          for (var i = 0; i < RateLimiter.maxKeys + 10; i++) {
            limiter.hit(i);
          }
        });

        expect(limiter.trackedKeys, lessThanOrEqualTo(RateLimiter.maxKeys));
      },
    );
  });
}
