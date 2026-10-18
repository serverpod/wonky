@Tags(['integration'])
library;

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/server.dart' show registerVersionProviders;
import 'package:wonky_server/src/platform/common/actor.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/versions/version_service.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// A document provider that records its captures and can hold them.
class _FakeProvider implements VersionProvider {
  final captures = <int, int>{};
  Completer<void>? gate;
  final started = StreamController<int>.broadcast();
  Future<void> Function(Session session, DriveItem item)? during;

  @override
  DriveItemKind get kind => DriveItemKind.document;

  @override
  Future<void> beforeCapture(Session session, DriveItem item) async {}

  @override
  Future<CapturedVersion> capture(Session session, DriveItem item) async {
    started.add(item.id!);
    await gate?.future;
    await during?.call(session, item);
    captures[item.id!] = (captures[item.id!] ?? 0) + 1;
    return const CapturedVersion(storageKind: VersionStorage.writeRevision);
  }

  @override
  Future<void> afterCapture(
    Session session,
    DriveItem item,
    ItemVersion version,
    CapturedVersion captured,
  ) async {}

  @override
  Future<void> discard(Session session, ItemVersion version) async {}

  @override
  Future<RestoredVersion> restore(
    Session session,
    Actor actor,
    DriveItem item,
    ItemVersion version,
  ) => throw UnimplementedError();
}

/// Version capture and thinning (code-quality CQ-29, specs/07 §5).
void main() {
  withWonkyServerpod('Given dirty documents', (sessionBuilder, endpoints) {
    late _FakeProvider fake;
    late TestUser anna;
    late List<DriveItem> items;
    setUp(() async {
      fake = _FakeProvider();
      VersionService.register(fake);
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final session = sessionBuilder.build();
      items = [];
      for (var i = 0; i < 3; i++) {
        final view = await TestDrive.document(endpoints, anna, name: 'D$i');
        items.add(
          (await DriveItem.db.findFirstRow(
            session,
            where: (t) => t.uuid.equals(view.uuid),
          ))!,
        );
      }
      for (final item in items) {
        await VersionService.recordEdit(session, item, anna.id);
      }
    });
    tearDown(registerVersionProviders);

    test(
      'when two capture runs overlap then every item is captured once',
      () async {
        fake.gate = Completer<void>();
        final twoStarted = fake.started.stream.take(2).toList();
        final later = clock.now().toUtc().add(const Duration(minutes: 6));

        final runs = Future.wait([
          VersionService.captureDue(sessionBuilder.build(), now: later),
          VersionService.captureDue(sessionBuilder.build(), now: later),
        ]);
        await twoStarted;
        fake.gate!.complete();
        await runs;

        expect([for (final i in items) fake.captures[i.id]], [1, 1, 1]);
      },
    );

    test('when an edit is recorded during the capture then the item stays '
        'dirty and the version keeps its authors', () async {
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final item = items.first;
      fake.during = (session, captured) async {
        if (captured.id != item.id) return;
        await withClock(
          Clock.fixed(clock.now().add(const Duration(seconds: 1))),
          () => VersionService.recordEdit(session, captured, bo.id),
        );
      };

      final version = await VersionService.capture(
        sessionBuilder.build(),
        item,
        kind: VersionKind.auto,
      );
      final state = (await ItemVersionState.db.findFirstRow(
        sessionBuilder.build(),
        where: (t) => t.itemId.equals(item.id!),
      ))!;

      expect(version.authors, [anna.id]);
      expect(state.dirtySince, isNotNull);
      expect(state.editorsSinceLastVersion, contains(bo.id));
      expect(state.capturingSince, isNull);
    });

    test(
      'when nothing was edited during the capture then the item is clean',
      () async {
        await VersionService.capture(
          sessionBuilder.build(),
          items.first,
          kind: VersionKind.auto,
        );
        final state = (await ItemVersionState.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.itemId.equals(items.first.id!),
        ))!;

        expect(state.dirtySince, isNull);
        expect(state.editorsSinceLastVersion, isEmpty);
      },
    );

    test('when several users record edits at once then none is lost', () async {
      final users = [
        for (var i = 0; i < 6; i++)
          await TestUsers.create(sessionBuilder, name: 'U$i'),
      ];
      final item = items.last;

      await Future.wait([
        for (final u in users)
          VersionService.recordEdit(sessionBuilder.build(), item, u.id),
      ]);
      final state = (await ItemVersionState.db.findFirstRow(
        sessionBuilder.build(),
        where: (t) => t.itemId.equals(item.id!),
      ))!;

      expect(
        state.editorsSinceLastVersion,
        unorderedEquals([anna.id, for (final u in users) u.id]),
      );
      expect(state.editorsSinceLastVersion.first, anna.id);
    });

    test('when old auto versions are thinned then one per hour is kept and '
        'named versions stay', () async {
      final session = sessionBuilder.build();
      final item = items.first;
      final now = clock.now().toUtc();
      final hour = DateTime.utc(
        now.year,
        now.month,
        now.day,
        now.hour,
      ).subtract(const Duration(days: 10));
      ItemVersion version(VersionKind kind, int minute) => ItemVersion(
        itemId: item.id!,
        kind: kind,
        createdAt: hour.add(Duration(minutes: minute)),
        authors: const [],
        storageKind: VersionStorage.writeRevision,
      );
      await ItemVersion.db.insert(session, [
        version(VersionKind.auto, 1),
        version(VersionKind.auto, 20),
        version(VersionKind.auto, 40),
        version(VersionKind.named, 50),
      ]);

      await VersionService.thin(session, now: now);
      final left = await ItemVersion.db.find(
        session,
        where: (t) => t.itemId.equals(item.id!),
        orderBy: (t) => t.createdAt,
      );

      expect(left.map((v) => (v.kind, v.createdAt.minute)), [
        (VersionKind.auto, 40),
        (VersionKind.named, 50),
      ]);
    });
  });
}
