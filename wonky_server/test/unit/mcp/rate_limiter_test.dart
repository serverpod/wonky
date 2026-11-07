import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/rate_limiter.dart';
import 'package:wonky_server/src/platform/mcp/tool_executor.dart';

/// A [RateCounter] shared by several limiters, like Redis is shared by
/// several server instances.
class _SharedCounter implements RateCounter {
  final Map<String, int> counts = {};
  bool reachable = true;

  @override
  Future<int> increment(String key, Duration ttl, {int by = 1}) async {
    if (!reachable) throw StateError('unreachable');
    return counts[key] = (counts[key] ?? 0) + by;
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 13, 12, 0, 30);

  group('Given two instances sharing a rate counter', () {
    late _SharedCounter counter;
    late McpRateLimiter first;
    late McpRateLimiter second;
    setUp(() {
      counter = _SharedCounter();
      first = McpRateLimiter(limit: 2, counter: counter);
      second = McpRateLimiter(limit: 2, counter: counter);
    });

    test('when the token spends its limit across both then the next call is '
        'limited until the window ends', () async {
      await withClock(Clock.fixed(now), () async {
        final a = await first.check(7);
        final b = await second.check(7);
        final c = await first.check(7);

        expect(a, isNull);
        expect(b, isNull);
        expect(c, const Duration(seconds: 30));
      });
    });

    test('when another token calls then it has its own limit', () async {
      await withClock(Clock.fixed(now), () async {
        await first.check(7);
        await second.check(7);

        expect(await first.check(8), isNull);
      });
    });

    test(
      'when the counter is unreachable then the local window applies',
      () async {
        counter.reachable = false;
        await withClock(Clock.fixed(now), () async {
          final a = await first.check(7);
          final b = await first.check(7);
          final c = await first.check(7);

          expect([a, b], [isNull, isNull]);
          expect(c, isNotNull);
        });
      },
    );
  });

  group('Given a limiter of 5 calls an hour', () {
    late RateLimiter limiter;
    setUp(() {
      limiter = RateLimiter(
        name: 'test.cost',
        limit: 5,
        window: const Duration(hours: 1),
        counter: null,
      );
    });

    test('when a call costs 3 twice then the second is refused and not '
        'counted', () async {
      await withClock(Clock.fixed(now), () async {
        expect(limiter.hit('a', cost: 3), isNull);
        expect(limiter.hit('a', cost: 3), const Duration(hours: 1));
        expect(limiter.hit('a', cost: 2), isNull);
        expect(limiter.hit('a'), isNotNull);
      });
    });

    test('when a call costs more than the limit then it is refused', () {
      withClock(Clock.fixed(now), () {
        expect(limiter.hit('b', cost: 6), const Duration(hours: 1));
        expect(limiter.hit('b', cost: 5), isNull);
      });
    });

    test('when the counter is shared then the cost is added at once', () async {
      final counter = _SharedCounter();
      final shared = RateLimiter(
        name: 'test.cost',
        limit: 5,
        window: const Duration(hours: 1),
        counter: counter,
      );
      await withClock(Clock.fixed(now), () async {
        expect(await shared.check('c', cost: 4), isNull);
        expect(await shared.check('c', cost: 2), isNotNull);
        expect(counter.counts.values.single, 6);
      });
    });
  });
}
