import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/roles.dart';
import '../common/time.dart';

/// The single source of truth for permissions (specs/06 §3).
///
/// Effective role = max(owner, direct grants, grants inherited from folders,
/// the link role when link sharing is on). Folder grants are materialized on
/// every descendant as [DriveItemPermission] rows with `inheritedFromId`;
/// [rebuildInherited] maintains them on share, unshare and move. The owner of
/// a folder also gets an inherited Editor grant on items other people put
/// into it.
abstract final class AccessService {
  // ---------------------------------------------------------------- lookup

  static Future<DriveItem?> findItem(
    Session session,
    UuidValue uuid, {
    Transaction? transaction,
  }) => DriveItem.db.findFirstRow(
    session,
    where: (t) => t.uuid.equals(uuid),
    transaction: transaction,
  );

  /// Loads [uuid] and checks that [actor] holds at least [min]. Callers
  /// without any access get `notFound` so ids do not leak.
  static Future<(DriveItem, Role)> require(
    Session session,
    Actor actor,
    UuidValue uuid,
    Role min, {
    Transaction? transaction,
  }) async {
    final item = await findItem(session, uuid, transaction: transaction);
    if (item == null) throw Errors.notFound();
    final role = await effectiveRole(
      session,
      actor.userId,
      item,
      transaction: transaction,
    );
    if (role == null) throw Errors.notFound();
    if (!(role >= min)) throw Errors.forbidden();
    return (item, role);
  }

  /// Like [require] for an already loaded item.
  static Future<Role> requireRole(
    Session session,
    Actor actor,
    DriveItem item,
    Role min, {
    Transaction? transaction,
  }) async {
    final role = await effectiveRole(
      session,
      actor.userId,
      item,
      transaction: transaction,
    );
    if (role == null) throw Errors.notFound();
    if (!(role >= min)) throw Errors.forbidden();
    return role;
  }

  /// The effective role of [userId] on [item], or null without access.
  static Future<Role?> effectiveRole(
    Session session,
    int userId,
    DriveItem item, {
    Transaction? transaction,
  }) async {
    final roles = await rolesFor(
      session,
      userId,
      [item],
      transaction: transaction,
    );
    return roles[item.id!];
  }

  /// Effective roles of [userId] on [items] (items without access are left
  /// out of the result).
  static Future<Map<int, Role>> rolesFor(
    Session session,
    int userId,
    List<DriveItem> items, {
    Transaction? transaction,
  }) async {
    final result = <int, Role>{};
    if (items.isEmpty) return result;
    final others = <int>{};
    for (final item in items) {
      if (item.ownerId == userId) {
        result[item.id!] = Role.owner;
      } else {
        others.add(item.id!);
      }
    }
    if (others.isEmpty) return result;
    final now = nowUtc();
    final grants = await DriveItemPermission.db.find(
      session,
      where: (t) =>
          t.itemId.inSet(others) &
          t.userId.equals(userId) &
          (t.expiresAt.equals(null) | (t.expiresAt > now)),
      transaction: transaction,
    );
    for (final g in grants) {
      result[g.itemId] = maxRole(result[g.itemId], g.role.role)!;
    }
    final links = await ShareLink.db.find(
      session,
      where: (t) => t.itemId.inSet(others) & t.role.notEquals(null),
      transaction: transaction,
    );
    for (final link in links) {
      result[link.itemId] = maxRole(result[link.itemId], link.role!.role)!;
    }
    return result;
  }

  /// Users with a grant or ownership on [item] (not link visitors).
  static Future<Set<int>> grantedUsers(
    Session session,
    DriveItem item, {
    Transaction? transaction,
  }) async {
    final grants = await DriveItemPermission.db.find(
      session,
      where: (t) => t.itemId.equals(item.id!) & t.userId.notEquals(null),
      transaction: transaction,
    );
    return {item.ownerId, for (final g in grants) g.userId!};
  }

  /// Everyone who may see [item] in a list: grantees plus link visitors.
  static Future<Set<int>> interestedUsers(
    Session session,
    DriveItem item, {
    Transaction? transaction,
  }) async =>
      (await interestedUsersOf(
        session,
        [item],
        transaction: transaction,
      ))[item.id!] ??
      {item.ownerId};

  /// [interestedUsers] of every item in [items] by item id, in two queries
  /// per 1,000 items (folder fan-out, CQ-26).
  static Future<Map<int, Set<int>>> interestedUsersOf(
    Session session,
    List<DriveItem> items, {
    Transaction? transaction,
  }) async {
    final result = <int, Set<int>>{
      for (final i in items) i.id!: {i.ownerId},
    };
    final ids = result.keys.toList();
    for (var start = 0; start < ids.length; start += 1000) {
      final chunk = ids
          .sublist(start, start + 1000 > ids.length ? ids.length : start + 1000)
          .toSet();
      final grants = await DriveItemPermission.db.find(
        session,
        where: (t) => t.itemId.inSet(chunk) & t.userId.notEquals(null),
        transaction: transaction,
      );
      for (final g in grants) {
        result[g.itemId]!.add(g.userId!);
      }
      final states = await DriveItemUserState.db.find(
        session,
        where: (t) => t.itemId.inSet(chunk),
        transaction: transaction,
      );
      for (final s in states) {
        result[s.itemId]!.add(s.userId);
      }
    }
    return result;
  }

  /// Whether [role] may share [item] (add people, change roles, links).
  static bool canShare(DriveItem item, Role role) =>
      role == Role.owner || (role == Role.editor && item.editorsCanShare);

  // ----------------------------------------------------------- inheritance

  /// The chain of ancestors of [item], nearest first: one recursive query
  /// (cycle-safe, at most 1,000 levels) and one load.
  static Future<List<DriveItem>> ancestors(
    Session session,
    DriveItem item, {
    Transaction? transaction,
  }) async {
    if (item.parentId == null) return const [];
    final rows = await session.db.unsafeQuery(
      'WITH RECURSIVE chain(id, "parentId", depth, path) AS ('
      ' SELECT d.id, d."parentId", 1, ARRAY[CAST(@self AS bigint), d.id]'
      ' FROM drive_item d WHERE d.id = @parent'
      ' UNION ALL'
      ' SELECT d.id, d."parentId", c.depth + 1, c.path || d.id'
      ' FROM drive_item d JOIN chain c ON d.id = c."parentId"'
      ' WHERE NOT d.id = ANY(c.path) AND c.depth < 1000)'
      ' SELECT id FROM chain ORDER BY depth',
      parameters: QueryParameters.named({
        'self': item.id!,
        'parent': item.parentId!,
      }),
      transaction: transaction,
    );
    final ids = [for (final r in rows) r[0]! as int];
    if (ids.isEmpty) return const [];
    final byId = {
      for (final d in await DriveItem.db.find(
        session,
        where: (t) => t.id.inSet(ids.toSet()),
        transaction: transaction,
      ))
        d.id!: d,
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// [root] and all its descendants, parents before children.
  static Future<List<DriveItem>> subtree(
    Session session,
    DriveItem root, {
    Transaction? transaction,
  }) async {
    final result = <DriveItem>[root];
    var frontier = <int>{root.id!};
    final seen = <int>{root.id!};
    while (frontier.isNotEmpty) {
      final children = await DriveItem.db.find(
        session,
        where: (t) => t.parentId.inSet(frontier),
        transaction: transaction,
      );
      // A Set: linear in the subtree (a list made this quadratic).
      final next = <int>{};
      for (final c in children) {
        if (seen.add(c.id!)) {
          next.add(c.id!);
          result.add(c);
        }
      }
      frontier = next;
    }
    return result;
  }

  /// Recomputes the inherited grants of [root] and its descendants from the
  /// direct grants of their folder ancestors. Returns the ids of users whose
  /// grants changed.
  static Future<Set<int>> rebuildInherited(
    Session session,
    DriveItem root, {
    Transaction? transaction,
  }) async {
    final changedUsers = <int>{};
    final nodes = await subtree(session, root, transaction: transaction);
    final byId = {for (final n in nodes) n.id!: n};
    final outside = await ancestors(session, root, transaction: transaction);
    final allFolders = [
      ...outside.where((a) => a.kind == DriveItemKind.folder),
      ...nodes.where((n) => n.kind == DriveItemKind.folder),
    ];
    final folderIds = {for (final f in allFolders) f.id!};
    final directOnFolders = folderIds.isEmpty
        ? <DriveItemPermission>[]
        : await DriveItemPermission.db.find(
            session,
            where: (t) =>
                t.itemId.inSet(folderIds) & t.inheritedFromId.equals(null),
            transaction: transaction,
          );
    final directByFolder = <int, List<DriveItemPermission>>{};
    for (final p in directOnFolders) {
      directByFolder.putIfAbsent(p.itemId, () => []).add(p);
    }
    final foldersById = {for (final f in allFolders) f.id!: f};

    List<int> folderAncestorsOf(DriveItem node) {
      final result = <int>[];
      var parentId = node.parentId;
      final seen = <int>{node.id!};
      while (parentId != null && seen.add(parentId)) {
        final parent = byId[parentId] ?? foldersById[parentId];
        if (parent == null) {
          // Above the subtree: use the precomputed outside chain.
          final index = outside.indexWhere((a) => a.id == parentId);
          if (index < 0) break;
          for (final a in outside.skip(index)) {
            if (a.kind == DriveItemKind.folder) result.add(a.id!);
          }
          break;
        }
        if (parent.kind == DriveItemKind.folder) result.add(parent.id!);
        parentId = parent.parentId;
      }
      return result;
    }

    final nodeIds = {for (final n in nodes) n.id!};
    final existing = await DriveItemPermission.db.find(
      session,
      where: (t) => t.itemId.inSet(nodeIds) & t.inheritedFromId.notEquals(null),
      transaction: transaction,
    );
    String key(int itemId, int? userId, String? email, int from) =>
        '$itemId|${userId ?? ''}|${email ?? ''}|$from';
    final existingByKey = {
      for (final p in existing)
        key(p.itemId, p.userId, p.invitedEmail, p.inheritedFromId!): p,
    };
    final desired = <String, DriveItemPermission>{};
    final now = nowUtc();
    for (final node in nodes) {
      for (final folderId in folderAncestorsOf(node)) {
        final folder = foldersById[folderId]!;
        for (final g
            in directByFolder[folderId] ?? const <DriveItemPermission>[]) {
          if (g.userId == node.ownerId) continue;
          final k = key(node.id!, g.userId, g.invitedEmail, folderId);
          final prev = desired[k];
          if (prev == null || g.role.index > prev.role.index) {
            desired[k] = DriveItemPermission(
              itemId: node.id!,
              userId: g.userId,
              invitedEmail: g.invitedEmail,
              role: g.role,
              inheritedFromId: folderId,
              grantedById: g.grantedById,
              grantedAt: g.grantedAt,
              expiresAt: g.expiresAt,
            );
          }
        }
        if (folder.ownerId != node.ownerId) {
          final k = key(node.id!, folder.ownerId, null, folderId);
          desired.putIfAbsent(
            k,
            () => DriveItemPermission(
              itemId: node.id!,
              userId: folder.ownerId,
              role: AccessRole.editor,
              inheritedFromId: folderId,
              grantedById: folder.ownerId,
              grantedAt: now,
            ),
          );
        }
      }
    }
    final toDelete = <int>[];
    for (final entry in existingByKey.entries) {
      final want = desired[entry.key];
      final have = entry.value;
      if (want == null ||
          want.role != have.role ||
          want.expiresAt != have.expiresAt) {
        toDelete.add(have.id!);
        if (have.userId != null) changedUsers.add(have.userId!);
      }
    }
    if (toDelete.isNotEmpty) {
      await DriveItemPermission.db.deleteWhere(
        session,
        where: (t) => t.id.inSet(toDelete.toSet()),
        transaction: transaction,
      );
    }
    final toInsert = [
      for (final entry in desired.entries)
        if (existingByKey[entry.key] == null ||
            toDelete.contains(existingByKey[entry.key]!.id))
          entry.value,
    ];
    if (toInsert.isNotEmpty) {
      await DriveItemPermission.db.insert(
        session,
        toInsert,
        transaction: transaction,
      );
      for (final p in toInsert) {
        if (p.userId != null) changedUsers.add(p.userId!);
      }
    }
    return changedUsers;
  }
}
