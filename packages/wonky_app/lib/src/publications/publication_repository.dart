import 'package:wonky_client/wonky_client.dart';

import '../data/api.dart';

/// Publications and submissions (specs/18 §9): starting a story from a
/// contributor link, a document's submission, and the owner's settings.
abstract class PublicationRepository {
  // Contributor.
  Future<PublicationCard> resolve(String publicId);
  Future<SubmissionStarted> startSubmission(
    String publicId, {
    String? ref,
    required bool agreed,
  });

  // A document's submission.
  Future<SubmissionView?> submission(UuidValue itemUuid);
  Future<SubmissionView> submit(
    UuidValue itemUuid,
    SubmissionValues values, {
    required bool agreed,
  });
  Future<SubmissionView> withdraw(UuidValue itemUuid);
  Future<void> disconnect(UuidValue itemUuid);
  Future<SubmissionView?> reconnect(UuidValue itemUuid);

  // Owner.
  Future<List<PublicationSettings>> list();
  Future<PublicationSecret> create(PublicationInput input);
  Future<PublicationSettings> update(String publicId, PublicationInput input);
  Future<void> delete(String publicId);
  Future<PublicationCheckResult> verify(String publicId);
  Future<PublicationSecret> rotateSecret(String publicId);
  Future<PublicationSecret> createApiKey(String publicId);
  Future<PublicationSettings> setModerators(
    String publicId,
    List<String> emails,
  );
  Future<List<PublicationDeliveryView>> deliveries(String publicId);
  Future<PublicationDeliveryView> resend(String publicId, String webhookId);
  Future<PublicationCheckResult> sendTest(String publicId);
}

/// [PublicationRepository] on the `publication` and `submission` endpoints.
class ServerPublicationRepository implements PublicationRepository {
  ServerPublicationRepository(this.api);

  final Api api;

  @override
  Future<PublicationCard> resolve(String publicId) =>
      api.guard((c) => c.publication.resolve(publicId));

  @override
  Future<SubmissionStarted> startSubmission(
    String publicId, {
    String? ref,
    required bool agreed,
  }) => api.guard((c) => c.publication.startSubmission(publicId, ref, agreed));

  @override
  Future<SubmissionView?> submission(UuidValue itemUuid) =>
      api.guard((c) => c.submission.get(itemUuid));

  @override
  Future<SubmissionView> submit(
    UuidValue itemUuid,
    SubmissionValues values, {
    required bool agreed,
  }) => api.guard((c) => c.submission.submit(itemUuid, values, agreed));

  @override
  Future<SubmissionView> withdraw(UuidValue itemUuid) =>
      api.guard((c) => c.submission.withdraw(itemUuid));

  @override
  Future<void> disconnect(UuidValue itemUuid) =>
      api.guard((c) => c.submission.disconnect(itemUuid));

  @override
  Future<SubmissionView?> reconnect(UuidValue itemUuid) =>
      api.guard((c) => c.submission.reconnect(itemUuid));

  @override
  Future<List<PublicationSettings>> list() =>
      api.guard((c) => c.publication.list());

  @override
  Future<PublicationSecret> create(PublicationInput input) =>
      api.guard((c) => c.publication.create(input));

  @override
  Future<PublicationSettings> update(String publicId, PublicationInput input) =>
      api.guard((c) => c.publication.update(publicId, input));

  @override
  Future<void> delete(String publicId) =>
      api.guard((c) => c.publication.delete(publicId));

  @override
  Future<PublicationCheckResult> verify(String publicId) =>
      api.guard((c) => c.publication.verify(publicId));

  @override
  Future<PublicationSecret> rotateSecret(String publicId) =>
      api.guard((c) => c.publication.rotateSecret(publicId));

  @override
  Future<PublicationSecret> createApiKey(String publicId) =>
      api.guard((c) => c.publication.createApiKey(publicId));

  @override
  Future<PublicationSettings> setModerators(
    String publicId,
    List<String> emails,
  ) => api.guard((c) => c.publication.setModerators(publicId, emails));

  @override
  Future<List<PublicationDeliveryView>> deliveries(String publicId) =>
      api.guard((c) => c.publication.deliveries(publicId));

  @override
  Future<PublicationDeliveryView> resend(String publicId, String webhookId) =>
      api.guard((c) => c.publication.resend(publicId, webhookId));

  @override
  Future<PublicationCheckResult> sendTest(String publicId) =>
      api.guard((c) => c.publication.sendTest(publicId));
}
