import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/src/activity/activity_feed.dart';
import 'package:wonky_app/src/l10n/wonky_app_localizations.dart';
import 'package:wonky_app/src/shell/dialogs.dart' show activityDetail;
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';

import '../support/screen_pump.dart';

ActivityEventView _e(int id, ActivityType type) => ActivityEventView(
  id: id,
  type: type,
  actor: TestUsers.bob,
  actorKind: ActorKind.user,
  summary: '{}',
  at: clock.now().subtract(Duration(minutes: id)),
);

void main() {
  late CommandTestHarness h;
  late DriveItemView doc;

  setUp(() {
    h = CommandTestHarness();
    doc = h.drive.seed(name: 'Plan');
    h.drive.activityByItem[doc.uuid.uuid] = [
      for (var id = 5; id >= 1; id--)
        _e(id, id.isEven ? ActivityType.commented : ActivityType.edited),
    ];
  });
  tearDown(() => h.dispose());

  Widget feed() => SingleChildScrollView(
    child: ActivityFeed(services: h.services, itemUuid: doc.uuid, pageSize: 3),
  );

  testWidgets('Given an item with 5 events when the feed shows then the '
      'first page is listed newest first', (tester) async {
    await pumpScreen(tester, h, feed());

    expect(find.byKey(ActivityFeedKeys.event(5)), findsOneWidget);
    expect(find.byKey(ActivityFeedKeys.event(2)), findsNothing);
    expect(find.text('Bob Stone commented'), findsOneWidget);
  });

  testWidgets('Given the first page when tapping Show more then older events '
      'are appended', (tester) async {
    await pumpScreen(tester, h, feed());

    await tester.tap(find.byKey(ActivityFeedKeys.loadMore));
    await tester.pumpAndSettle();

    expect(find.byKey(ActivityFeedKeys.event(1)), findsOneWidget);
    expect(find.byKey(ActivityFeedKeys.loadMore), findsNothing);
  });

  testWidgets('Given the feed when the item changes in the drive then the '
      'feed reloads', (tester) async {
    await pumpScreen(tester, h, feed());
    h.drive.activityByItem[doc.uuid.uuid] = [
      _e(9, ActivityType.renamed),
      ...h.drive.activityByItem[doc.uuid.uuid]!,
    ];

    h.services.emitDriveChange(
      DriveChange(kind: DriveChangeKind.updated, itemUuid: doc.uuid, item: doc),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bob Stone renamed this'), findsOneWidget);
  });

  testWidgets('Given a presentation edit event with slides, a deleted slide '
      'and an agent when the feed shows then its detail line lists them', (
    tester,
  ) async {
    h.drive.activityByItem[doc.uuid.uuid] = [
      ActivityEventView(
        id: 7,
        type: ActivityType.edited,
        actor: TestUsers.bob,
        actorKind: ActorKind.mcp,
        summary:
            '{"changes": 4, "slideIds": ["a", "b", "c"], "slidesDeleted": 1, '
            '"themes": 1, "actorKinds": ["mcp", "user"]}',
        at: clock.now(),
      ),
    ];

    await pumpScreen(tester, h, feed());

    expect(
      find.text('3 slides · 1 slide deleted · theme changed · with Claude'),
      findsOneWidget,
    );
  });

  test('Given edit events of documents and spreadsheets then there is no '
      'detail line', () {
    final l = lookupWonkyAppLocalizations(const Locale('en'));
    final e = ActivityEventView(
      id: 1,
      type: ActivityType.edited,
      actorKind: ActorKind.user,
      summary: '{"changes": 2, "cells": 5, "actorKinds": ["user"]}',
      at: clock.now(),
    );
    expect(activityDetail(l, e), isNull);
  });
}
