import 'package:wonky_client/wonky_client.dart';

import '../publications/publication_repository.dart';

/// An in-memory [PublicationRepository] (suite 15 §5): one contributor
/// card, document submissions by item, and the owner's publications. Calls
/// are recorded in [calls].
class FakePublicationRepository implements PublicationRepository {
  FakePublicationRepository({this.card});

  /// What [resolve] answers.
  PublicationCard? card;

  /// Submissions by document.
  final submissions = <UuidValue, SubmissionView>{};

  /// The owner's publications.
  final publications = <PublicationSettings>[];

  /// What [startSubmission] creates.
  UuidValue startedItem = UuidValue.fromString(
    '01900000-0000-7000-8000-0000000000aa',
  );

  /// The calls made, e.g. `submit`, `startSubmission:agreed`.
  final calls = <String>[];

  /// The values of the last [submit].
  SubmissionValues? lastValues;

  static PublicationFields fields() => PublicationFields(
    summary: PublicationFieldMode.optional,
    tags: PublicationFieldMode.optional,
    allowedTags: [],
    coverImage: PublicationFieldMode.off,
    authorBio: PublicationFieldMode.off,
    note: PublicationFieldMode.optional,
  );

  /// A submission view with defaults.
  static SubmissionView view(
    UuidValue itemUuid, {
    SubmissionStatus status = SubmissionStatus.draft,
    String name = 'Serverpod blog',
    bool accepting = true,
    int? lastSubmittedRevision,
    String? lastMessage,
    String? publicUrl,
    UuidValue? feedbackThreadUuid,
    SubmissionDeliveryState? delivery,
  }) => SubmissionView(
    id: 'sub_${itemUuid.uuid}',
    itemUuid: itemUuid,
    status: status,
    delivery: delivery,
    publicationId: 'pub_AAAAAAAAAAAAAAAAAAAAAA',
    publicationName: name,
    shownHost: 'blog.example.com',
    verified: true,
    accepting: accepting,
    fields: fields(),
    consentNeeded: false,
    values: SubmissionValues(title: 'Untitled story', tags: []),
    publicUrl: publicUrl,
    feedbackThreadUuid: feedbackThreadUuid,
    lastMessage: lastMessage,
    lastSubmittedRevision: lastSubmittedRevision,
    revisions: [],
    updatedAt: DateTime.utc(2026, 10, 20),
  );

  @override
  Future<PublicationCard> resolve(String publicId) async {
    calls.add('resolve');
    return card!;
  }

  @override
  Future<SubmissionStarted> startSubmission(
    String publicId, {
    String? ref,
    required bool agreed,
  }) async {
    calls.add(agreed ? 'startSubmission:agreed' : 'startSubmission');
    submissions[startedItem] = view(startedItem);
    return SubmissionStarted(itemUuid: startedItem);
  }

  @override
  Future<SubmissionView?> submission(UuidValue itemUuid) async =>
      submissions[itemUuid];

  @override
  Future<SubmissionView> submit(
    UuidValue itemUuid,
    SubmissionValues values, {
    required bool agreed,
  }) async {
    calls.add('submit');
    lastValues = values;
    final v = submissions[itemUuid]!.copyWith(
      status: SubmissionStatus.inReview,
      values: values,
      lastSubmittedRevision: 1 << 30,
    );
    return submissions[itemUuid] = v;
  }

  @override
  Future<SubmissionView> withdraw(UuidValue itemUuid) async {
    calls.add('withdraw');
    return submissions[itemUuid] = submissions[itemUuid]!.copyWith(
      status: SubmissionStatus.withdrawn,
    );
  }

  final _disconnected = <UuidValue, SubmissionView>{};

  @override
  Future<void> disconnect(UuidValue itemUuid) async {
    calls.add('disconnect');
    _disconnected[itemUuid] = submissions.remove(itemUuid)!;
  }

  @override
  Future<SubmissionView?> reconnect(UuidValue itemUuid) async {
    calls.add('reconnect');
    final v = _disconnected.remove(itemUuid);
    if (v != null) submissions[itemUuid] = v;
    return v;
  }

  PublicationSettings _settings(PublicationInput input, String id) =>
      PublicationSettings(
        publicId: id,
        name: input.name,
        siteUrl: input.siteUrl,
        webhookUrl: input.webhookUrl,
        termsUrl: input.termsUrl,
        fields: input.fields,
        moderators: [],
        hasApiKey: false,
        enabled: input.enabled,
        contributorLink: 'https://wonky.work/write/new?publication=$id',
        openSubmissionCount: 0,
        createdAt: DateTime.utc(2026, 10, 20),
      );

  @override
  Future<List<PublicationSettings>> list() async => [...publications];

  @override
  Future<PublicationSecret> create(PublicationInput input) async {
    calls.add('create');
    final p = _settings(input, 'pub_${'B' * 22}');
    publications.add(p);
    return PublicationSecret(settings: p, secret: 'whsec_c2VjcmV0');
  }

  @override
  Future<PublicationSettings> update(
    String publicId,
    PublicationInput input,
  ) async {
    calls.add('update');
    final p = _settings(input, publicId);
    publications[publications.indexWhere((x) => x.publicId == publicId)] = p;
    return p;
  }

  @override
  Future<void> delete(String publicId) async {
    calls.add('delete');
    publications.removeWhere((p) => p.publicId == publicId);
  }

  PublicationSettings _one(String id) =>
      publications.firstWhere((p) => p.publicId == id);

  @override
  Future<PublicationCheckResult> verify(String publicId) async =>
      PublicationCheckResult(
        ok: false,
        message: 'HTTP 404',
        settings: _one(publicId),
      );

  @override
  Future<PublicationSecret> rotateSecret(String publicId) async =>
      PublicationSecret(settings: _one(publicId), secret: 'whsec_bmV3');

  @override
  Future<PublicationSecret> createApiKey(String publicId) async {
    calls.add('createApiKey');
    return PublicationSecret(
      settings: _one(publicId).copyWith(hasApiKey: true, apiKeyLast4: 'abcd'),
      secret: 'wpk_${'k' * 40}',
    );
  }

  @override
  Future<PublicationSettings> setModerators(
    String publicId,
    List<String> emails,
  ) async => _one(publicId).copyWith(
    moderators: [for (final e in emails) PublicationModeratorView(email: e)],
  );

  @override
  Future<List<PublicationDeliveryView>> deliveries(String publicId) async => [];

  @override
  Future<PublicationDeliveryView> resend(
    String publicId,
    String webhookId,
  ) async => throw UnimplementedError();

  @override
  Future<PublicationCheckResult> sendTest(String publicId) async =>
      PublicationCheckResult(ok: true, settings: _one(publicId));
}
