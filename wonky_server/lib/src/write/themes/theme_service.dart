import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/users/user_service.dart';
import 'builtin_theme_ids.dart';
import '../../platform/cluster/cluster_bus.dart';

/// Write themes (Write 06 §5): built-in themes are global rows upserted at
/// start; user themes live in the owner's library with optimistic
/// concurrency, revisions and soft delete. Saves are broadcast on
/// `theme:<uuid>` as `DocMetaChanged(field: themeVersion)`.
abstract final class ThemeService {
  static const maxRevisions = 50;
  static const maxJsonLength = 256 * 1024;
  static const deletedRetention = Duration(days: 30);

  static String channel(UuidValue themeUuid) => 'theme:${themeUuid.uuid}';

  // -------------------------------------------------------------- builtins

  /// Upserts the built-in themes (server start). A changed built-in gets a
  /// new version, so documents using it update on next open.
  static Future<void> upsertBuiltins(Session session) async {
    final now = nowUtc();
    for (final builtin in core.BuiltinThemes.all) {
      final json = core.canonicalJsonEncode(builtin.json);
      final description = builtin.theme.description;
      final schemaVersion = builtin.theme.schemaVersion;
      final hash = contentHash(json);
      final uuid = BuiltinThemeIds.forKey(builtin.key);
      final existing = await WriteTheme.db.findFirstRow(
        session,
        where: (t) => t.builtinKey.equals(builtin.key),
      );
      if (existing == null) {
        await WriteTheme.db.insertRow(
          session,
          WriteTheme(
            uuid: uuid,
            isBuiltin: true,
            builtinKey: builtin.key,
            name: builtin.name,
            description: description,
            schemaVersion: schemaVersion,
            version: 1,
            json: json,
            contentHash: hash,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else if (existing.contentHash != hash ||
          existing.name != builtin.name ||
          existing.description != description) {
        await WriteTheme.db.updateRow(
          session,
          existing.copyWith(
            name: builtin.name,
            description: description,
            schemaVersion: schemaVersion,
            version: existing.version + 1,
            json: json,
            contentHash: hash,
            updatedAt: now,
          ),
        );
        await _broadcast(session, existing.uuid, existing.version + 1, hash);
      }
    }
  }

  // -------------------------------------------------------------- helpers

  /// Validates theme JSON with `WriteThemeValidator` (migrating older
  /// schema versions; unknown properties are dropped) and returns its
  /// canonical form (sorted keys, no whitespace).
  static String canonical(String json) {
    if (json.length > maxJsonLength) {
      throw Errors.tooLarge('The theme is too large.');
    }
    final result = const core.WriteThemeValidator().validateString(json);
    if (result.errors.isNotEmpty || result.theme == null) {
      final first = result.errors.isEmpty ? null : result.errors.first;
      throw Errors.invalid(
        first == null
            ? 'The theme is not valid.'
            : 'Invalid theme (${first.path}): ${first.message}',
      );
    }
    return core.canonicalJsonEncode(result.theme!.toJson());
  }

  static String contentHash(String json) =>
      sha256.convert(utf8.encode(json)).toString();

  static int _schemaOf(String json) =>
      (jsonDecode(json) as Map)['schemaVersion'] as int;

  static String _cleanName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      throw Errors.invalid('Theme names have 1–80 characters.');
    }
    return trimmed;
  }

  static Future<WriteThemeView> view(Session session, WriteTheme t) async =>
      WriteThemeView(
        uuid: t.uuid,
        name: t.name,
        description: t.description,
        isBuiltin: t.isBuiltin,
        builtinKey: t.builtinKey,
        owner: await UserService.summary(session, t.ownerId),
        schemaVersion: t.schemaVersion,
        version: t.version,
        contentHash: t.contentHash,
        json: t.json,
        updatedAt: t.updatedAt,
        deletedAt: t.deletedAt,
      );

  static Future<WriteTheme> _byUuid(Session session, UuidValue uuid) async {
    final theme = await WriteTheme.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid),
    );
    if (theme == null) throw Errors.notFound('Theme');
    return theme;
  }

  /// Read access (Write 06 §5.4): owner, anyone for built-ins, or Viewer+ of
  /// a document using the theme ([viaDocumentUuid]).
  static Future<WriteTheme> _readable(
    Session session,
    Actor actor,
    UuidValue uuid,
    UuidValue? viaDocumentUuid,
  ) async {
    final theme = await _byUuid(session, uuid);
    if (theme.isBuiltin || theme.ownerId == actor.userId) return theme;
    if (viaDocumentUuid != null) {
      final doc = await Document.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(viaDocumentUuid),
      );
      if (doc != null && doc.themeId == uuid) {
        final item = await DriveItem.db.findById(session, doc.itemId);
        if (item != null &&
            await AccessService.effectiveRole(session, actor.userId, item) !=
                null) {
          return theme;
        }
      }
    }
    throw Errors.notFound('Theme');
  }

  /// Whether [actor] may assign [uuid] to a document they edit: own or
  /// built-in themes, or the theme the document already uses.
  static Future<WriteTheme> requireAssignable(
    Session session,
    Actor actor,
    UuidValue uuid,
    Document document,
  ) async {
    final theme = await _byUuid(session, uuid);
    if (theme.deletedAt != null && theme.ownerId != actor.userId) {
      throw Errors.notFound('Theme');
    }
    if (theme.isBuiltin ||
        theme.ownerId == actor.userId ||
        document.themeId == uuid) {
      return theme;
    }
    throw Errors.forbidden('Copy the theme to your themes first.');
  }

  static Future<WriteTheme> _owned(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final theme = await _byUuid(session, uuid);
    if (theme.isBuiltin) {
      throw Errors.forbidden('Built-in themes are read-only.');
    }
    if (theme.ownerId != actor.userId) throw Errors.notFound('Theme');
    return theme;
  }

  // ------------------------------------------------------------------ read

  static Future<List<WriteThemeView>> listBuiltins(Session session) async {
    final themes = await WriteTheme.db.find(
      session,
      where: (t) => t.isBuiltin.equals(true),
    );
    final order = [for (final b in core.BuiltinThemes.all) b.key];
    themes.sort(
      (a, b) =>
          order.indexOf(a.builtinKey!).compareTo(order.indexOf(b.builtinKey!)),
    );
    return [for (final t in themes) await view(session, t)];
  }

  static Future<List<WriteThemeView>> listMine(
    Session session,
    Actor actor,
  ) async {
    final themes = await WriteTheme.db.find(
      session,
      where: (t) => t.ownerId.equals(actor.userId) & t.deletedAt.equals(null),
    );
    themes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [for (final t in themes) await view(session, t)];
  }

  static Future<WriteThemeView> get(
    Session session,
    Actor actor,
    UuidValue uuid, {
    UuidValue? viaDocumentUuid,
  }) async => view(
    session,
    await _readable(session, actor, uuid, viaDocumentUuid),
  );

  static Future<List<WriteThemeView>> getMany(
    Session session,
    Actor actor,
    List<UuidValue> uuids, {
    UuidValue? viaDocumentUuid,
  }) async {
    final result = <WriteThemeView>[];
    for (final uuid in uuids.toSet().take(100)) {
      try {
        result.add(
          await get(session, actor, uuid, viaDocumentUuid: viaDocumentUuid),
        );
      } on WonkyException {
        // Unreadable themes are left out.
      }
    }
    return result;
  }

  // ----------------------------------------------------------------- write

  static Future<WriteThemeView> create(
    Session session,
    Actor actor, {
    required String name,
    required String json,
    UuidValue? basedOnUuid,
  }) async {
    final canonicalJson = canonical(json);
    String? description;
    if (basedOnUuid != null) {
      final base = await _readable(session, actor, basedOnUuid, null);
      description = base.description;
    }
    final now = nowUtc();
    final theme = await session.db.transaction((tx) async {
      final theme = await WriteTheme.db.insertRow(
        session,
        WriteTheme(
          ownerId: actor.userId,
          isBuiltin: false,
          name: _cleanName(name),
          description: description,
          schemaVersion: _schemaOf(canonicalJson),
          version: 1,
          json: canonicalJson,
          contentHash: contentHash(canonicalJson),
          createdAt: now,
          updatedAt: now,
        ),
        transaction: tx,
      );
      await _revision(session, theme, actor, tx);
      return theme;
    });
    return view(session, theme);
  }

  static Future<void> _revision(
    Session session,
    WriteTheme theme,
    Actor actor,
    Transaction tx,
  ) async {
    await WriteThemeRevision.db.insertRow(
      session,
      WriteThemeRevision(
        themeId: theme.id!,
        version: theme.version,
        json: theme.json,
        savedById: actor.userId,
        actorKind: actor.kind,
        createdAt: nowUtc(),
      ),
      transaction: tx,
    );
    final old = await WriteThemeRevision.db.find(
      session,
      where: (t) =>
          t.themeId.equals(theme.id!) &
          (t.version <= theme.version - maxRevisions),
      transaction: tx,
    );
    if (old.isNotEmpty) {
      await WriteThemeRevision.db.delete(session, old, transaction: tx);
    }
  }

  static ThemeConflictException _conflict(WriteTheme t) =>
      ThemeConflictException(
        message: 'The theme was changed elsewhere.',
        serverJson: t.json,
        serverVersion: t.version,
        serverName: t.name,
      );

  static Future<WriteThemeView> update(
    Session session,
    Actor actor,
    UuidValue uuid,
    String json,
    int expectedVersion,
  ) async {
    final canonicalJson = canonical(json);
    final saved = await session.db.transaction((tx) async {
      final theme = await WriteTheme.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(uuid),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (theme == null) throw Errors.notFound('Theme');
      if (theme.isBuiltin) {
        throw Errors.forbidden('Built-in themes are read-only.');
      }
      if (theme.ownerId != actor.userId) throw Errors.notFound('Theme');
      if (theme.version != expectedVersion) throw _conflict(theme);
      final updated = await WriteTheme.db.updateRow(
        session,
        theme.copyWith(
          json: canonicalJson,
          contentHash: contentHash(canonicalJson),
          schemaVersion: _schemaOf(canonicalJson),
          version: theme.version + 1,
          updatedAt: nowUtc(),
        ),
        transaction: tx,
      );
      await _revision(session, updated, actor, tx);
      return updated;
    });
    await _broadcast(session, saved.uuid, saved.version, saved.contentHash);
    return view(session, saved);
  }

  static Future<void> _broadcast(
    Session session,
    UuidValue uuid,
    int version,
    String hash,
  ) => ClusterBus.post(
    session,
    channel(uuid),
    DocMetaChanged(
      field: 'themeVersion',
      valueJson: jsonEncode({
        'themeId': uuid.uuid,
        'version': version,
        'hash': hash,
      }),
    ),
  );

  static Future<WriteThemeView> rename(
    Session session,
    Actor actor,
    UuidValue uuid,
    String name,
    int expectedVersion,
  ) async {
    final theme = await _owned(session, actor, uuid);
    if (theme.version != expectedVersion) throw _conflict(theme);
    final updated = await WriteTheme.db.updateRow(
      session,
      theme.copyWith(
        name: _cleanName(name),
        version: theme.version + 1,
        updatedAt: nowUtc(),
      ),
    );
    await _broadcast(
      session,
      updated.uuid,
      updated.version,
      updated.contentHash,
    );
    return view(session, updated);
  }

  static Future<WriteThemeView> duplicate(
    Session session,
    Actor actor,
    UuidValue uuid,
    String name, {
    UuidValue? viaDocumentUuid,
  }) async {
    final source = await _readable(session, actor, uuid, viaDocumentUuid);
    return create(
      session,
      actor,
      name: name,
      json: source.json,
      basedOnUuid: null,
    );
  }

  static Future<WriteThemeView> delete(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final theme = await _owned(session, actor, uuid);
    final updated = await WriteTheme.db.updateRow(
      session,
      theme.copyWith(deletedAt: nowUtc()),
    );
    return view(session, updated);
  }

  static Future<WriteThemeView> restore(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final theme = await _owned(session, actor, uuid);
    final updated = await WriteTheme.db.updateRow(
      session,
      WriteTheme(
        id: theme.id,
        uuid: theme.uuid,
        ownerId: theme.ownerId,
        isBuiltin: theme.isBuiltin,
        builtinKey: theme.builtinKey,
        name: theme.name,
        description: theme.description,
        schemaVersion: theme.schemaVersion,
        version: theme.version,
        json: theme.json,
        contentHash: theme.contentHash,
        createdAt: theme.createdAt,
        updatedAt: nowUtc(),
        deletedAt: null,
      ),
    );
    return view(session, updated);
  }

  static Future<List<WriteThemeRevisionView>> listRevisions(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final theme = await _owned(session, actor, uuid);
    final revisions = await WriteThemeRevision.db.find(
      session,
      where: (t) => t.themeId.equals(theme.id!),
      orderBy: (t) => t.version.desc(),
    );
    final users = await UserService.summaries(session, [
      for (final r in revisions) r.savedById,
    ]);
    return [
      for (final r in revisions)
        WriteThemeRevisionView(
          version: r.version,
          json: r.json,
          savedBy: r.savedById == null ? null : users[r.savedById],
          actorKind: r.actorKind,
          createdAt: r.createdAt,
        ),
    ];
  }

  static Future<WriteThemeRevisionView> getRevision(
    Session session,
    Actor actor,
    UuidValue uuid,
    int version,
  ) async {
    final all = await listRevisions(session, actor, uuid);
    return all.firstWhere(
      (r) => r.version == version,
      orElse: () => throw Errors.notFound('Revision'),
    );
  }

  /// Documents owned by the caller that use the theme.
  static Future<int> usage(Session session, Actor actor, UuidValue uuid) async {
    await _readable(session, actor, uuid, null);
    final result = await session.db.unsafeQuery(
      r'''
      SELECT count(*) FROM document d JOIN drive_item i ON i.id = d."itemId"
      WHERE d."themeId" = @theme AND i."ownerId" = @me AND i."trashedAt" IS NULL
      ''',
      parameters: QueryParameters.named({'theme': uuid, 'me': actor.userId}),
    );
    return result.first[0] as int;
  }

  /// Daily job: hard-deletes themes deleted more than 30 days ago that no
  /// document references.
  static Future<int> purgeDeleted(Session session, {DateTime? now}) async {
    final cutoff = (now ?? nowUtc()).subtract(deletedRetention);
    final old = await WriteTheme.db.find(
      session,
      where: (t) => (t.deletedAt < cutoff) & t.isBuiltin.equals(false),
    );
    var count = 0;
    for (final theme in old) {
      final used = await Document.db.count(
        session,
        where: (t) => t.themeId.equals(theme.uuid),
      );
      if (used > 0) continue;
      await WriteTheme.db.deleteRow(session, theme);
      count++;
    }
    return count;
  }
}
