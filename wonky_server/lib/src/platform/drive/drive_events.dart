import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../common/actor.dart';
import '../common/models.dart';
import '../sharing/access_service.dart';
import '../storage/storage_service.dart';
import 'drive_file_filters.dart';
import 'drive_views.dart';
import '../cluster/cluster_bus.dart';

/// Live drive updates (`drive.watch`, specs/05 §2). Changes are posted per
/// user on `drive:user:<userId>`; each watcher resolves the items with its
/// own role, so lists show the right permissions. A change of many items
/// (a folder's subtree) is **one** signal per user with up to
/// [maxItemsPerSignal] item ids, resolved by the watcher in batches
/// (CQ-26).
abstract final class DriveEvents {
  static String channel(int userId) => 'drive:user:$userId';

  /// Item ids per signal.
  static const maxItemsPerSignal = 500;

  /// Notifies everyone who may see [item] (plus [alsoNotify], e.g. users who
  /// just lost access) about a change.
  static Future<void> notify(
    Session session,
    DriveItem item,
    DriveChangeKind kind, {
    Set<int> alsoNotify = const {},
  }) => notifyAll(session, [item], kind, alsoNotify: alsoNotify);

  /// Notifies about several items at once: the interested users of all of
  /// them in one batch, then one signal per user.
  static Future<void> notifyAll(
    Session session,
    Iterable<DriveItem> items,
    DriveChangeKind kind, {
    Set<int> alsoNotify = const {},
  }) async {
    final list = items.toList();
    if (list.isEmpty) return;
    final interested = await AccessService.interestedUsersOf(session, list);
    final byUser = <int, List<UuidValue>>{};
    for (final item in list) {
      for (final u in {...?interested[item.id!], ...alsoNotify}) {
        byUser.putIfAbsent(u, () => []).add(item.uuid);
      }
    }
    await postTo(session, byUser, kind);
  }

  /// Posts [kind] for each user's item ids (chunked by
  /// [maxItemsPerSignal]).
  static Future<void> postTo(
    Session session,
    Map<int, List<UuidValue>> itemsByUser,
    DriveChangeKind kind,
  ) async {
    for (final MapEntry(key: userId, value: uuids) in itemsByUser.entries) {
      for (var i = 0; i < uuids.length; i += maxItemsPerSignal) {
        final chunk = uuids.sublist(
          i,
          i + maxItemsPerSignal > uuids.length
              ? uuids.length
              : i + maxItemsPerSignal,
        );
        await ClusterBus.post(
          session,
          channel(userId),
          DriveChangeSignal(
            kind: kind,
            itemUuid: chunk.first,
            itemUuids: chunk.length > 1 ? chunk : null,
          ),
        );
      }
    }
  }

  /// The live stream of changes visible to [actor].
  static Stream<DriveChange> watch(Session session, Actor actor) async* {
    final signals = session.messages.createStream<DriveChangeSignal>(
      channel(actor.userId),
    );
    await for (final signal in signals) {
      // (v2) The watcher's storage changed (Drive 03 §3).
      if (signal.kind == DriveChangeKind.storageChanged) {
        yield DriveChange(
          kind: DriveChangeKind.storageChanged,
          itemUuid: signal.itemUuid,
          storage: await StorageService.instance.usage(session, actor.userId),
        );
        continue;
      }
      final uuids = signal.itemUuids ?? [signal.itemUuid];
      final items = await DriveItem.db.find(
        session,
        where: (t) => t.uuid.inSet(uuids.toSet()),
      );
      final byUuid = {for (final i in items) i.uuid: i};
      final roles = await AccessService.rolesFor(session, actor.userId, items);
      final visible = [
        for (final i in items)
          // (v2) Uploads in progress are only visible to their uploader.
          if (roles[i.id!] != null &&
              DriveFileFilters.listable(i, actor.userId))
            i,
      ];
      final views = {
        for (final v in await DriveViews.build(
          session,
          actor.userId,
          visible,
          roles: roles,
        ))
          v.uuid: v,
      };
      for (final uuid in uuids) {
        final item = byUuid[uuid];
        if (item == null || roles[item.id!] == null) {
          yield DriveChange(kind: DriveChangeKind.removed, itemUuid: uuid);
          continue;
        }
        final view = views[uuid];
        if (view == null) continue;
        yield DriveChange(kind: signal.kind, itemUuid: uuid, item: view);
      }
    }
  }
}
