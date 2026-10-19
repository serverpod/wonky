import 'dart:math';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';

/// A [Random] whose doubles are always 0.5 (no jitter).
class _NoJitter implements Random {
  @override
  double nextDouble() => 0.5;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  group('Given a started connectivity service', () {
    late int pings;
    late bool fail;
    late ConnectivityService connectivity;

    setUp(() {
      pings = 0;
      fail = false;
      connectivity = ConnectivityService(
        ping: () async {
          pings++;
          if (fail) throw Exception('unreachable');
        },
        random: _NoJitter(),
      );
    });

    testWidgets('when the app is shown then it pings every 15 s', (
      tester,
    ) async {
      connectivity.start();
      await tester.pump();
      expect(pings, 1);

      await tester.pump(const Duration(seconds: 15));
      await tester.pump(const Duration(seconds: 15));
      expect(pings, 3);
      connectivity.dispose();
    });

    testWidgets('when the app is hidden then it stops pinging', (tester) async {
      connectivity.start();
      await tester.pump();
      connectivity.setVisible(false);

      await tester.pump(const Duration(minutes: 10));
      expect(pings, 1);
      expect(connectivity.online, isTrue);
      connectivity.dispose();
    });

    testWidgets(
      'when it is shown again then it checks at once and resumes the heartbeat',
      (tester) async {
        connectivity.start();
        await tester.pump();
        connectivity.setVisible(false);
        await tester.pump(const Duration(minutes: 10));

        connectivity.setVisible(true);
        await tester.pump();
        expect(pings, 2);

        await tester.pump(const Duration(seconds: 15));
        expect(pings, 3);
        connectivity.dispose();
      },
    );

    testWidgets('when it is offline and hidden then it stops retrying', (
      tester,
    ) async {
      fail = true;
      connectivity.start();
      await tester.pump();
      expect(connectivity.online, isFalse);
      expect(connectivity.nextAttemptAt, isNotNull);

      connectivity.setVisible(false);
      expect(connectivity.nextAttemptAt, isNull);
      await tester.pump(const Duration(minutes: 10));
      expect(pings, 1);

      fail = false;
      connectivity.setVisible(true);
      await tester.pump();
      expect(pings, 2);
      expect(connectivity.online, isTrue);
      connectivity.dispose();
    });

    testWidgets('when it is hidden before it starts then it checks once', (
      tester,
    ) async {
      connectivity.setVisible(false);
      connectivity.start();
      await tester.pump();
      await tester.pump(const Duration(minutes: 10));
      expect(pings, 1);
      connectivity.dispose();
    });
  });

  test(
    'Given the lifecycle states then only resumed and inactive are shown',
    () {
      expect(ConnectivityService.isShown(AppLifecycleState.resumed), isTrue);
      expect(ConnectivityService.isShown(AppLifecycleState.inactive), isTrue);
      expect(ConnectivityService.isShown(AppLifecycleState.hidden), isFalse);
      expect(ConnectivityService.isShown(AppLifecycleState.paused), isFalse);
      expect(ConnectivityService.isShown(AppLifecycleState.detached), isFalse);
    },
  );
}
