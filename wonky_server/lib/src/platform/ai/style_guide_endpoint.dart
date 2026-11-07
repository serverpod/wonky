import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../users/user_service.dart';
import 'style_guide_service.dart';

/// The assistant's style guide library (suite 10 §7): built-in guides,
/// the user's own (personal or shared with their organization), the
/// organization's default and each Write document's guide.
class StyleGuideEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The guides the user can use; with [itemUuid] also that document's
  /// choice and whether the user may change it.
  Future<StyleGuideLibrary> library(
    Session session,
    UuidValue? itemUuid,
  ) async => StyleGuideService.library(
    session,
    await UserService.actorOf(session),
    itemUuid: itemUuid,
  );

  /// Creates or updates one of the user's guides.
  Future<StyleGuideView> save(Session session, StyleGuideInput input) async =>
      StyleGuideService.save(
        session,
        await UserService.actorOf(session),
        input,
      );

  /// Deletes one of the user's guides.
  Future<void> delete(Session session, UuidValue uuid) async =>
      StyleGuideService.delete(
        session,
        await UserService.actorOf(session),
        uuid,
      );

  /// Sets (null clears) the default guide of the user's organization.
  Future<StyleGuideLibrary> setOrgDefault(
    Session session,
    String? ref,
  ) async => StyleGuideService.setOrgDefault(
    session,
    await UserService.actorOf(session),
    ref,
  );

  /// Sets (null clears) the style guide of a Write document (Editor+).
  Future<StyleGuideLibrary> setDocumentStyle(
    Session session,
    UuidValue itemUuid,
    String? ref,
  ) async => StyleGuideService.setDocumentStyle(
    session,
    await UserService.actorOf(session),
    itemUuid,
    ref,
  );
}
