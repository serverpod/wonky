import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../users/user_service.dart';
import 'publication_service.dart';

/// Publications (specs/18 §9.1): starting a story from a contributor link,
/// and the owner's settings.
class PublicationEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The publication of a contributor link.
  Future<PublicationCard> resolve(Session session, String publicId) async =>
      PublicationService.resolve(
        session,
        await UserService.actorOf(session),
        publicId,
      );

  /// Creates the document of a new story; [agreed] confirms the consent
  /// dialog.
  Future<SubmissionStarted> startSubmission(
    Session session,
    String publicId,
    String? ref,
    bool agreed,
  ) async => PublicationService.startSubmission(
    session,
    await UserService.actorOf(session),
    publicId,
    ref: ref,
    agreed: agreed,
  );

  Future<List<PublicationSettings>> list(Session session) async =>
      PublicationService.list(session, await UserService.actorOf(session));

  /// Creates a publication; the result holds the signing secret once.
  Future<PublicationSecret> create(
    Session session,
    PublicationInput input,
  ) async => PublicationService.create(
    session,
    await UserService.actorOf(session),
    input,
  );

  Future<PublicationSettings> update(
    Session session,
    String publicId,
    PublicationInput input,
  ) async => PublicationService.update(
    session,
    await UserService.actorOf(session),
    publicId,
    input,
  );

  Future<void> delete(Session session, String publicId) async =>
      PublicationService.delete(
        session,
        await UserService.actorOf(session),
        publicId,
      );

  Future<PublicationCheckResult> verify(
    Session session,
    String publicId,
  ) async => PublicationService.verify(
    session,
    await UserService.actorOf(session),
    publicId,
  );

  Future<PublicationSecret> rotateSecret(
    Session session,
    String publicId,
  ) async => PublicationService.rotateSecret(
    session,
    await UserService.actorOf(session),
    publicId,
  );

  Future<PublicationSecret> createApiKey(
    Session session,
    String publicId,
  ) async => PublicationService.createApiKey(
    session,
    await UserService.actorOf(session),
    publicId,
  );

  Future<PublicationSettings> setModerators(
    Session session,
    String publicId,
    List<String> emails,
  ) async => PublicationService.setModerators(
    session,
    await UserService.actorOf(session),
    publicId,
    emails,
  );

  Future<List<PublicationDeliveryView>> deliveries(
    Session session,
    String publicId,
  ) async => PublicationService.deliveries(
    session,
    await UserService.actorOf(session),
    publicId,
  );

  Future<PublicationDeliveryView> resend(
    Session session,
    String publicId,
    String webhookId,
  ) async => PublicationService.resend(
    session,
    await UserService.actorOf(session),
    publicId,
    webhookId,
  );

  Future<PublicationCheckResult> sendTest(
    Session session,
    String publicId,
  ) async => PublicationService.sendTest(
    session,
    await UserService.actorOf(session),
    publicId,
  );
}
