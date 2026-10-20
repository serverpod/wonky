import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../slides/revlog/slides_rev_binding.dart';

import '../../sheets/revlog/sheets_rev_binding.dart';
import '../revlog/headless_file_cache.dart';
import '../revlog/rev_log_service.dart';
import '../../write/ot/document_cache.dart';
import '../activity/activity_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/guarded.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../files/file_service.dart';
import '../publications/submission_service.dart';
import '../sharing/access_service.dart';
import '../sharing/acl_events.dart';
import '../storage/storage_service.dart';
import 'drive_events.dart';
import 'drive_file_service.dart';
import 'kind_masks.dart';

import 'drive_service.dart';

/// Trash, restore and permanent deletion of drive items (specs/05 §2.4,
/// Drive 03 §5): the purge of a subtree, its storage and its content.
abstract final class DriveTrash {
  /// Trashed items are deleted after this period (`drive.purgeTrash`).
  static const trashRetention = Duration(days: 30);

  static Future<void> trash(
    Session session,
    Actor actor,
    List<UuidValue> uuids,
  ) async {
    final now = nowUtc();
    for (final uuid in DriveService.bulkUuids(uuids)) {
      final (item, _) = await AccessService.require(
        session,
        actor,
        uuid,
        Role.editor,
      );
      if (item.trashedAt != null) continue;
      // (v2) Trashing an upload in progress cancels it (Drive 02 §2).
      if (item.uploadState == FileUploadState.uploading) {
        await DriveFileService.cancelUpload(session, actor, item.uuid);
        continue;
      }
      final nodes = await AccessService.subtree(session, item);
      final ids = {for (final n in nodes) n.id!};
      await session.db.transaction((tx) async {
        await DriveItem.db.updateWhere(
          session,
          columnValues: (t) => [t.trashedAt(now), t.trashedById(actor.userId)],
          where: (t) => t.id.inSet(ids) & t.trashedAt.equals(null),
          transaction: tx,
        );
        await KindMasks.refreshChain(session, item.parentId, transaction: tx);
        // (v2) Bytes move to the owners' trash (Drive 03 §7.4).
        await StorageService.instance.onTrash(session, nodes, transaction: tx);
      });
      await ActivityService.log(session, item.id!, actor, ActivityType.trashed);
      final updated = (await DriveItem.db.findById(session, item.id!))!;
      await AclEvents.changed(session, updated, kind: DriveChangeKind.trashed);
      // Open submissions are withdrawn (specs/18 §4.5).
      await runGuarded<void>(
        session,
        'publications.onTrashed',
        () => SubmissionService.onTrashed(session, nodes),
      );
    }
  }

  static Future<void> restore(
    Session session,
    Actor actor,
    List<UuidValue> uuids,
  ) async {
    for (final uuid in DriveService.bulkUuids(uuids)) {
      final (item, _) = await AccessService.require(
        session,
        actor,
        uuid,
        Role.editor,
      );
      final trashedAt = item.trashedAt;
      if (trashedAt == null) continue;
      final nodes = await AccessService.subtree(session, item);
      final ids = {
        for (final n in nodes)
          if (n.trashedAt == trashedAt) n.id!,
      };
      // Restoring into a trashed or missing folder moves the item to the
      // owner's root.
      int? parentId = item.parentId;
      if (parentId != null) {
        final parent = await DriveItem.db.findById(session, parentId);
        if (parent == null || parent.trashedAt != null) parentId = null;
      }
      await session.db.transaction((tx) async {
        await DriveItem.db.updateWhere(
          session,
          columnValues: (t) => [t.trashedAt(null), t.trashedById(null)],
          where: (t) => t.id.inSet(ids),
          transaction: tx,
        );
        // (v2) Never refused: trashed bytes already count (Q16).
        await StorageService.instance.onRestore(
          session,
          [
            for (final n in nodes)
              if (ids.contains(n.id)) n,
          ],
          transaction: tx,
        );
      });
      if (parentId != item.parentId) {
        await DriveItem.db.updateWhere(
          session,
          columnValues: (t) => [t.parentId(null)],
          where: (t) => t.id.equals(item.id!),
        );
      }
      final updated = (await DriveItem.db.findById(session, item.id!))!;
      if (parentId != item.parentId) {
        await AccessService.rebuildInherited(session, updated);
      }
      await KindMasks.refreshSubtree(session, updated);
      await ActivityService.log(
        session,
        item.id!,
        actor,
        ActivityType.restored,
      );
      await AclEvents.changed(session, updated, kind: DriveChangeKind.restored);
      await runGuarded<void>(
        session,
        'publications.onRestored',
        () => SubmissionService.onRestored(session, [
          for (final n in nodes)
            if (ids.contains(n.id)) n,
        ]),
      );
    }
  }

  /// Deletes trashed items forever (owners only).
  static Future<void> deletePermanently(
    Session session,
    Actor actor,
    List<UuidValue> uuids,
  ) async {
    for (final uuid in DriveService.bulkUuids(uuids)) {
      final (item, role) = await AccessService.require(
        session,
        actor,
        uuid,
        Role.viewer,
      );
      if (role != Role.owner) {
        throw Errors.forbidden('Only the owner can delete an item forever.');
      }
      if (item.trashedAt == null) {
        throw Errors.invalid('Move the item to the trash first.');
      }
      await purge(session, item);
    }
  }

  static Future<int> emptyTrash(Session session, Actor actor) async {
    final page = await DriveService.list(
      session,
      actor,
      filter: DriveListFilter(view: DriveView.trash),
      sort: DriveSort(),
      limit: 500,
    );
    var count = 0;
    for (final view in page.items) {
      final item = await AccessService.findItem(session, view.uuid);
      if (item == null || item.ownerId != actor.userId) continue;
      await purge(session, item);
      count++;
    }
    return count;
  }

  /// Physically deletes [item] and the part of its subtree owned by its
  /// owner: documents (cascade), spreadsheet and deck spaces, stored files.
  /// Items of other people are never deleted (specs/06 §1: delete forever
  /// is Owner-only): the topmost ones move to their owners' roots with
  /// their subtrees, out of the trash when they were trashed together with
  /// [item], with their inherited grants and the folder kind masks
  /// rebuilt. Returns the number of deleted items.
  static Future<int> purge(Session session, DriveItem item) async {
    final nodes = await AccessService.subtree(session, item);
    final (doomed, kept) = purgePlan(item, nodes);
    final users = {
      for (final s in (await AccessService.interestedUsersOf(
        session,
        doomed,
      )).values)
        ...s,
    };
    final keptUsers = <int, Set<int>>{
      for (final k in kept) k.id!: await DriveService.subtreeUsers(session, k),
    };
    final ids = {for (final n in doomed) n.id!};
    await FileService.deleteFilesOfItems(session, ids);
    // RevLog files go first: rev_file.item is Restrict (RevLog spec 05
    // §10.1), and their rows are deleted in batches outside one huge
    // transaction.
    for (final n in doomed) {
      final binding = switch (n.kind) {
        DriveItemKind.spreadsheet => SheetsRevBinding.instance,
        DriveItemKind.presentation => SlidesRevBinding.instance,
        _ => null,
      };
      if (binding != null && n.contentRef != null) {
        await RevLogService.purgeFile(session, binding, n.contentRef!);
        HeadlessFileCache.evict(n.contentRef!);
      }
    }
    final rerooted = await session.db.transaction((tx) async {
      final rerooted = <DriveItem>[];
      for (final k in kept) {
        rerooted.add(await _reroot(session, k, item.trashedAt, tx));
      }
      await DriveItem.db.deleteWhere(
        session,
        where: (t) => t.id.inSet(ids),
        transaction: tx,
      );
      // (v2) Frees the owners' bytes (Drive 03 §7.4).
      await StorageService.instance.onDelete(session, doomed, transaction: tx);
      if (item.parentId != null && !ids.contains(item.parentId)) {
        await KindMasks.refreshChain(session, item.parentId, transaction: tx);
      }
      return rerooted;
    });
    // A purged document's cached state (head, op cache, overlays) on this
    // instance goes now rather than when its connections time out.
    for (final n in doomed) {
      if (n.kind == DriveItemKind.document && n.contentRef != null) {
        DocumentCache.evict(n.contentRef!, deleted: true);
      }
    }
    for (final r in rerooted) {
      await AclEvents.changed(
        session,
        r,
        affectedUsers: keptUsers[r.id] ?? const {},
        kind: DriveChangeKind.moved,
      );
    }
    // One signal per user for the whole subtree.
    final removed = [for (final n in doomed) n.uuid];
    await DriveEvents.postTo(session, {
      for (final u in users) u: removed,
    }, DriveChangeKind.removed);
    return doomed.length;
  }

  /// Splits [nodes] (the subtree of [root], parents first) for [purge]:
  /// the items to delete (owned by [root]'s owner and not below another
  /// owner's item) and the topmost items of other owners, which are kept
  /// with their whole subtrees.
  static (List<DriveItem> doomed, List<DriveItem> kept) purgePlan(
    DriveItem root,
    List<DriveItem> nodes,
  ) {
    final children = <int, List<DriveItem>>{};
    for (final n in nodes) {
      if (n.id == root.id || n.parentId == null) continue;
      children.putIfAbsent(n.parentId!, () => []).add(n);
    }
    final doomed = <DriveItem>[];
    final kept = <DriveItem>[];
    final seen = <int>{};
    var frontier = [root];
    while (frontier.isNotEmpty) {
      final next = <DriveItem>[];
      for (final n in frontier) {
        if (!seen.add(n.id!)) continue;
        if (n.id != root.id && n.ownerId != root.ownerId) {
          kept.add(n);
          continue;
        }
        doomed.add(n);
        next.addAll(children[n.id] ?? const []);
      }
      frontier = next;
    }
    return (doomed, kept);
  }

  /// Moves [item] (another owner's item inside a purged folder) to its
  /// owner's root, restores the part of its subtree that was trashed at
  /// [trashedAt] (together with the purged folder) and rebuilds its
  /// inherited grants and kind masks.
  static Future<DriveItem> _reroot(
    Session session,
    DriveItem item,
    DateTime? trashedAt,
    Transaction tx,
  ) async {
    await DriveItem.db.updateWhere(
      session,
      columnValues: (t) => [t.parentId(null)],
      where: (t) => t.id.equals(item.id!),
      transaction: tx,
    );
    if (trashedAt != null) {
      final nodes = await AccessService.subtree(session, item, transaction: tx);
      final restored = [
        for (final n in nodes)
          if (n.trashedAt == trashedAt) n,
      ];
      if (restored.isNotEmpty) {
        final ids = <int>{for (final n in restored) n.id!};
        await DriveItem.db.updateWhere(
          session,
          columnValues: (t) => [t.trashedAt(null), t.trashedById(null)],
          where: (t) => t.id.inSet(ids),
          transaction: tx,
        );
        await StorageService.instance.onRestore(
          session,
          restored,
          transaction: tx,
        );
      }
    }
    final updated = (await DriveItem.db.findById(
      session,
      item.id!,
      transaction: tx,
    ))!;
    await AccessService.rebuildInherited(session, updated, transaction: tx);
    await KindMasks.refreshSubtree(session, updated, transaction: tx);
    return updated;
  }

  /// Daily job: deletes items trashed longer than [trashRetention], in
  /// batches until none are left (or [budget] is spent). Each item is
  /// purged from the top of what was trashed with it, so other people's
  /// items inside it are kept ([purge]).
  static Future<int> purgeExpiredTrash(
    Session session, {
    DateTime? now,
    Duration budget = const Duration(minutes: 10),
  }) async {
    final cutoff = (now ?? nowUtc()).subtract(trashRetention);
    final watch = Stopwatch()..start();
    final failed = <int>{};
    var purged = 0;
    while (watch.elapsed < budget) {
      final expired = await DriveItem.db.find(
        session,
        where: (t) => (t.trashedAt < cutoff) & t.id.notInSet(failed),
        orderBy: (t) => t.id,
        limit: 1000,
      );
      if (expired.isEmpty) break;
      var progress = false;
      for (final item in expired) {
        if (watch.elapsed >= budget) break;
        final current = await DriveItem.db.findById(session, item.id!);
        if (current == null || current.trashedAt == null) continue;
        final root = await _trashRoot(session, current);
        try {
          final count = await purge(session, root);
          purged += count;
          progress = true;
        } on Object catch (e, st) {
          failed.addAll({item.id!, root.id!});
          session.log(
            'drive.purgeTrash: item ${root.id} failed: $e',
            level: LogLevel.error,
            stackTrace: st,
          );
        }
      }
      if (!progress) break;
    }
    return purged;
  }

  /// The topmost ancestor of trashed [item] that was trashed together with
  /// it (same `trashedAt`), or [item] itself.
  static Future<DriveItem> _trashRoot(Session session, DriveItem item) async {
    var root = item;
    for (final a in await AccessService.ancestors(session, item)) {
      if (a.trashedAt != item.trashedAt) break;
      root = a;
    }
    return root;
  }
}
