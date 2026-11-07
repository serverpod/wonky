import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/common/actor.dart';
import '../../platform/sharing/anonymous_access.dart';
import '../../platform/users/user_service.dart';
import '../themes/theme_service.dart';

/// Write themes (Write 06 §5.5).
///
/// `listBuiltins`, `get` and `getMany` also serve signed-out viewers of
/// link-shared documents (the document's theme, without the owner's email,
/// specs/06 §2.4); every other call needs an account.
class WriteThemeEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<List<WriteThemeView>> listBuiltins(Session session) async {
    await AnonymousAccess.actorOf(session);
    return ThemeService.listBuiltins(session);
  }

  static WriteThemeView _scrub(Actor actor, WriteThemeView view) =>
      actor.isAnonymous && view.owner != null
      ? view.copyWith(owner: view.owner!.copyWith(email: ''))
      : view;

  Future<List<WriteThemeView>> listMine(Session session) async =>
      ThemeService.listMine(session, await UserService.actorOf(session));

  Future<WriteThemeView> get(
    Session session,
    UuidValue uuid,
    UuidValue? viaDocumentUuid,
  ) async {
    final actor = await AnonymousAccess.actorOf(session);
    return _scrub(
      actor,
      await ThemeService.get(
        session,
        actor,
        uuid,
        viaDocumentUuid: viaDocumentUuid,
      ),
    );
  }

  Future<List<WriteThemeView>> getMany(
    Session session,
    List<UuidValue> uuids,
    UuidValue? viaDocumentUuid,
  ) async {
    final actor = await AnonymousAccess.actorOf(session);
    return [
      for (final v in await ThemeService.getMany(
        session,
        actor,
        uuids,
        viaDocumentUuid: viaDocumentUuid,
      ))
        _scrub(actor, v),
    ];
  }

  Future<WriteThemeView> create(
    Session session,
    String name,
    String json,
    UuidValue? basedOnUuid,
  ) async => ThemeService.create(
    session,
    await UserService.actorOf(session),
    name: name,
    json: json,
    basedOnUuid: basedOnUuid,
  );

  /// Saves a theme; throws [ThemeConflictException] when [expectedVersion]
  /// is stale.
  Future<WriteThemeView> update(
    Session session,
    UuidValue uuid,
    String json,
    int expectedVersion,
  ) async => ThemeService.update(
    session,
    await UserService.actorOf(session),
    uuid,
    json,
    expectedVersion,
  );

  Future<WriteThemeView> rename(
    Session session,
    UuidValue uuid,
    String name,
    int expectedVersion,
  ) async => ThemeService.rename(
    session,
    await UserService.actorOf(session),
    uuid,
    name,
    expectedVersion,
  );

  /// Copies a built-in or readable theme into the caller's library.
  Future<WriteThemeView> duplicate(
    Session session,
    UuidValue uuid,
    String name,
    UuidValue? viaDocumentUuid,
  ) async => ThemeService.duplicate(
    session,
    await UserService.actorOf(session),
    uuid,
    name,
    viaDocumentUuid: viaDocumentUuid,
  );

  Future<WriteThemeView> delete(Session session, UuidValue uuid) async =>
      ThemeService.delete(session, await UserService.actorOf(session), uuid);

  Future<WriteThemeView> restore(Session session, UuidValue uuid) async =>
      ThemeService.restore(session, await UserService.actorOf(session), uuid);

  Future<List<WriteThemeRevisionView>> listRevisions(
    Session session,
    UuidValue uuid,
  ) async => ThemeService.listRevisions(
    session,
    await UserService.actorOf(session),
    uuid,
  );

  Future<WriteThemeRevisionView> getRevision(
    Session session,
    UuidValue uuid,
    int version,
  ) async => ThemeService.getRevision(
    session,
    await UserService.actorOf(session),
    uuid,
    version,
  );

  /// Number of the caller's documents using the theme.
  Future<int> usage(Session session, UuidValue uuid) async =>
      ThemeService.usage(session, await UserService.actorOf(session), uuid);
}
