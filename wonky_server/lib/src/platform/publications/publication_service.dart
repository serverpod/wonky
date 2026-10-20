import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../write/ot/document_store.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/guarded.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../drive/drive_service.dart';
import '../files/file_service.dart';
import '../sharing/access_service.dart';
import '../storage/storage_service.dart';
import '../users/user_service.dart';
import 'publication_common.dart';
import 'publication_http.dart';
import 'publication_keys.dart';
import 'publication_rules.dart';
import 'publication_webhooks.dart';
import 'submission_service.dart';

/// Publications (specs/18 §3, §8, §9.1): the owner's settings, secrets,
/// moderators, verification and deliveries, and starting a story from a
/// contributor link.
abstract final class PublicationService {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // ---------------------------------------------------------- contributor

  /// The card a contributor sees before starting (specs/18 §3 step 3).
  static Future<PublicationCard> resolve(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await Publications.byPublicId(session, publicId);
    final owner = (await UserService.summaries(session, [
      p.ownerId,
    ]))[p.ownerId];
    final open = await Submission.db.find(
      session,
      where: (t) =>
          t.publicationId.equals(p.id!) &
          t.createdById.equals(actor.userId) &
          t.disconnectedAt.equals(null) &
          t.status.inSet({
            SubmissionStatus.draft,
            SubmissionStatus.changesRequested,
          }),
      orderBy: (t) => t.updatedAt.desc(),
      limit: 20,
    );
    final openViews = <PublicationOpenSubmission>[];
    for (final s in open) {
      final item = await DriveItem.db.findById(session, s.itemId);
      if (item == null || item.trashedAt != null) continue;
      final role = await AccessService.effectiveRole(
        session,
        actor.userId,
        item,
      );
      if (role == null || role < Role.editor) continue;
      openViews.add(
        PublicationOpenSubmission(
          itemUuid: item.uuid,
          name: item.name,
          status: s.status,
          updatedAt: s.updatedAt,
        ),
      );
    }
    return PublicationCard(
      publicId: p.publicId,
      name: p.name,
      shownHost: Publications.shownHost(p),
      verified: p.verifiedHost != null,
      siteHost: PublicationRules.hostOf(p.siteUrl),
      webhookHost: PublicationRules.hostOf(p.webhookUrl),
      termsUrl: p.termsUrl,
      fields: p.fields,
      ownerName: owner?.displayName ?? 'Deleted user',
      enabled: p.enabled,
      consentNeeded: await Publications.consentNeeded(session, p, actor.userId),
      blocked: await Publications.isBlocked(session, p.id!, actor.userId),
      openSubmissions: openViews,
    );
  }

  /// Creates a document for a new story (from the publication's template)
  /// and its draft submission (specs/18 §3 step 3).
  static Future<SubmissionStarted> startSubmission(
    Session session,
    Actor actor,
    String publicId, {
    String? ref,
    bool agreed = false,
  }) async {
    final p = await Publications.byPublicId(session, publicId);
    if (!p.enabled) {
      throw Errors.forbidden('${p.name} isn\'t accepting stories right now.');
    }
    if (await Publications.isBlocked(session, p.id!, actor.userId)) {
      throw Errors.forbidden('${p.name} isn\'t accepting stories from you.');
    }
    final cleanRef = ref == null || ref.isEmpty ? null : ref;
    if (cleanRef != null && !PublicationRules.refPattern.hasMatch(cleanRef)) {
      throw Errors.invalid('The link has an invalid ref.');
    }
    if (await Publications.consentNeeded(session, p, actor.userId)) {
      if (!agreed) {
        throw Errors.invalid('Agree to write for ${p.name} first.');
      }
    }
    await Publications.checkLimit(
      Publications.startLimiter,
      '${p.id}:${actor.userId}',
      "You've started a lot of stories for ${p.name} today. "
          'Try again tomorrow.',
    );
    await Publications.recordConsent(session, p, actor.userId);
    const name = 'Untitled story';
    final view = await _createDocument(session, actor, p, name);
    final item = (await AccessService.findItem(session, view.uuid))!;
    final now = nowUtc();
    await Submission.db.insertRow(
      session,
      Submission(
        uuid: const Uuid().v7obj(),
        publicationId: p.id!,
        itemId: item.id!,
        ref: cleanRef,
        status: SubmissionStatus.draft,
        values: SubmissionValues(title: name, tags: []),
        createdById: actor.userId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return SubmissionStarted(itemUuid: item.uuid);
  }

  /// A new document in the actor's root: empty, or a copy of the
  /// publication's template without comments and suggestions, with its
  /// images copied into the new document.
  static Future<DriveItemView> _createDocument(
    Session session,
    Actor actor,
    Publication p,
    String name,
  ) async {
    final template = p.templateItemId == null
        ? null
        : await DriveItem.db.findById(session, p.templateItemId!);
    final tplDoc = template == null || template.trashedAt != null
        ? null
        : await DocumentStore.byItem(session, template.id!);
    if (tplDoc == null) {
      return DriveService.createDocument(session, actor, name: name);
    }
    var content = core.SuggestionView.accepted(
      await DocumentStore.head(session, tplDoc),
      stripComments: true,
    );
    // Template images belong to the template; copies get their own.
    final copies = <UuidValue, UuidValue>{};
    content = core.Delta.fromOperations([
      for (final op in content.toList())
        if (op.data case {
          'image': final Map<String, dynamic> image,
        } when '${image['src']}'.startsWith('wonky-file://'))
          core.Operation.insert({
            'image': {
              ...image,
              'src': () {
                final source = UuidValue.withValidation(
                  '${image['src']}'.substring('wonky-file://'.length),
                );
                final copy = copies[source] ??= const Uuid().v7obj();
                return 'wonky-file://${copy.uuid}';
              }(),
            },
          }, op.attributes)
        else
          op,
    ]);
    final view = await DriveService.createDocumentFromContent(
      session,
      actor,
      name: name,
      content: content,
      source: tplDoc,
      activitySummary: {'publication': p.name},
      quotaReason: QuotaReason.copy,
    );
    final item = (await AccessService.findItem(session, view.uuid))!;
    for (final MapEntry(key: source, value: copy) in copies.entries) {
      await runGuarded<void>(
        session,
        'publications.copyTemplateImage',
        () async {
          final file = await FileService.byUuid(session, source);
          if (file == null ||
              file.status != StoredFileStatus.ready ||
              file.itemId != template!.id) {
            return;
          }
          final bytes = await FileService.readBytes(session, file);
          final stored = await FileService.storeServerFile(
            session,
            ownerId: actor.userId,
            itemId: item.id,
            kind: StoredFileKind.image,
            fileName: file.fileName,
            mimeType: file.mimeType,
            bytes: bytes.buffer.asUint8List(
              bytes.offsetInBytes,
              bytes.lengthInBytes,
            ),
            fileUuid: copy,
          );
          await StorageService.instance.addAttachment(
            session,
            item,
            stored.sizeBytes,
          );
        },
      );
    }
    return view;
  }

  // ---------------------------------------------------------------- owner

  static Future<List<PublicationSettings>> list(
    Session session,
    Actor actor,
  ) async {
    final pubs = await Publication.db.find(
      session,
      where: (t) => t.ownerId.equals(actor.userId),
      orderBy: (t) => t.createdAt,
    );
    return [for (final p in pubs) await settingsOf(session, p)];
  }

  static Future<Publication> _own(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await Publications.byPublicId(session, publicId);
    if (p.ownerId != actor.userId) throw Errors.notFound('Publication');
    return p;
  }

  static Future<PublicationSettings> settingsOf(
    Session session,
    Publication p,
  ) async {
    final mods = await PublicationModerator.db.find(
      session,
      where: (t) => t.publicationId.equals(p.id!),
      orderBy: (t) => t.email,
    );
    final users = await UserService.summaries(session, [
      for (final m in mods) m.userId,
    ]);
    final template = p.templateItemId == null
        ? null
        : await DriveItem.db.findById(session, p.templateItemId!);
    final open = await Submission.db.count(
      session,
      where: (t) =>
          t.publicationId.equals(p.id!) &
          t.disconnectedAt.equals(null) &
          t.status.inSet({
            SubmissionStatus.inReview,
            SubmissionStatus.changesRequested,
          }),
    );
    final now = nowUtc();
    return PublicationSettings(
      publicId: p.publicId,
      name: p.name,
      siteUrl: p.siteUrl,
      webhookUrl: p.webhookUrl,
      verifiedHost: p.verifiedHost,
      verifiedAt: p.verifiedAt,
      templateItemUuid: template?.uuid,
      templateName: template?.name,
      termsUrl: p.termsUrl,
      fields: p.fields,
      moderators: [
        for (final m in mods)
          PublicationModeratorView(
            email: m.email,
            name: m.userId == null ? null : users[m.userId]?.displayName,
          ),
      ],
      hasApiKey: p.apiKeyHash != null,
      apiKeyLast4: p.apiKeyLast4,
      previousSecretUntil: (p.previousSecretUntil?.isAfter(now) ?? false)
          ? p.previousSecretUntil
          : null,
      enabled: p.enabled,
      contributorLink: Publications.contributorLink(session, p.publicId),
      openSubmissionCount: open,
      createdAt: p.createdAt,
    );
  }

  /// Validated input: (name, site origin, webhook URL, terms URL, template).
  static Future<(String, String, String, String?, DriveItem?)> _validate(
    Session session,
    Actor actor,
    PublicationInput input,
  ) async {
    final name = input.name.trim();
    if (name.isEmpty) throw Errors.invalid('Enter a name.');
    if (name.length > PublicationRules.maxNameLength) {
      throw Errors.invalid(
        'Use at most ${PublicationRules.maxNameLength} characters for the name.',
      );
    }
    final site = PublicationRules.origin(
      PublicationRules.httpsUrl(input.siteUrl, 'site URL', originOnly: true),
    );
    final webhook = PublicationRules.httpsUrl(
      input.webhookUrl,
      'webhook URL',
    ).toString();
    final terms = input.termsUrl == null || input.termsUrl!.trim().isEmpty
        ? null
        : PublicationRules.httpsUrl(input.termsUrl!, 'terms URL').toString();
    DriveItem? template;
    if (input.templateItemUuid case final uuid?) {
      final (item, _) = await AccessService.require(
        session,
        actor,
        uuid,
        Role.owner,
      );
      if (item.kind != DriveItemKind.document) {
        throw Errors.invalid('The template must be a Wonky Write document.');
      }
      template = item;
    }
    final allowed = <String>[];
    for (final t in input.fields.allowedTags) {
      final tag = t.trim();
      if (tag.isEmpty || allowed.contains(tag)) continue;
      if (tag.length > PublicationRules.maxTagLength) {
        throw Errors.invalid('The tag "$tag" is too long.');
      }
      allowed.add(tag);
    }
    if (allowed.length > 200) throw Errors.invalid('Use at most 200 tags.');
    return (name, site, webhook, terms, template);
  }

  /// Creates a publication; the result holds the signing secret (shown
  /// once).
  static Future<PublicationSecret> create(
    Session session,
    Actor actor,
    PublicationInput input,
  ) async {
    final count = await Publication.db.count(
      session,
      where: (t) => t.ownerId.equals(actor.userId),
    );
    if (count >= PublicationRules.maxPublicationsPerOwner) {
      throw Errors.limit(
        'You can have at most ${PublicationRules.maxPublicationsPerOwner} '
        'publications.',
      );
    }
    final (name, site, webhook, terms, template) = await _validate(
      session,
      actor,
      input,
    );
    final secret = PublicationKeys.newSigningSecret();
    final now = nowUtc();
    final p = await Publication.db.insertRow(
      session,
      Publication(
        publicId: PublicationKeys.newPublicId(),
        ownerId: actor.userId,
        name: name,
        siteUrl: site,
        webhookUrl: webhook,
        templateItemId: template?.id,
        termsUrl: terms,
        fields: _fields(input.fields),
        signingSecret: secret,
        enabled: input.enabled,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _ping(session, p);
    return PublicationSecret(
      settings: await settingsOf(session, p),
      secret: secret,
    );
  }

  static PublicationFields _fields(PublicationFields f) => f.copyWith(
    allowedTags: {
      for (final t in f.allowedTags)
        if (t.trim().isNotEmpty) t.trim(),
    }.toList(),
  );

  static Future<PublicationSettings> update(
    Session session,
    Actor actor,
    String publicId,
    PublicationInput input,
  ) async {
    final p = await _own(session, actor, publicId);
    final (name, site, webhook, terms, template) = await _validate(
      session,
      actor,
      input,
    );
    final siteChanged = site != p.siteUrl;
    final webhookChanged = webhook != p.webhookUrl;
    final updated = await Publication.db.updateRow(
      session,
      p.copyWith(
        name: name,
        siteUrl: site,
        webhookUrl: webhook,
        termsUrl: terms,
        templateItemId: template?.id,
        fields: _fields(input.fields),
        enabled: input.enabled,
        verifiedHost: siteChanged ? null : p.verifiedHost,
        verifiedAt: siteChanged ? null : p.verifiedAt,
        updatedAt: nowUtc(),
      ),
      columns: (t) => [
        t.name,
        t.siteUrl,
        t.webhookUrl,
        t.termsUrl,
        t.templateItemId,
        t.fields,
        t.enabled,
        t.verifiedHost,
        t.verifiedAt,
        t.updatedAt,
      ],
    );
    if (webhookChanged) await _ping(session, updated);
    return settingsOf(session, updated);
  }

  /// Deletes a publication: its submissions disconnect (cascade), the
  /// moderators' grants go with it; nothing is sent.
  static Future<void> delete(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await _own(session, actor, publicId);
    final items = [
      for (final s in await Submission.db.find(
        session,
        where: (t) => t.publicationId.equals(p.id!),
      ))
        s.itemId,
    ];
    await Publication.db.deleteRow(session, p);
    for (final id in items) {
      final item = await DriveItem.db.findById(session, id);
      if (item != null) {
        await SubmissionService.changedAfterDelete(session, item);
      }
    }
  }

  static Future<PublicationSecret> rotateSecret(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await _own(session, actor, publicId);
    final secret = PublicationKeys.newSigningSecret();
    final updated = await Publication.db.updateRow(
      session,
      p.copyWith(
        signingSecret: secret,
        previousSigningSecret: p.signingSecret,
        previousSecretUntil: nowUtc().add(const Duration(hours: 24)),
        updatedAt: nowUtc(),
      ),
      columns: (t) => [
        t.signingSecret,
        t.previousSigningSecret,
        t.previousSecretUntil,
        t.updatedAt,
      ],
    );
    return PublicationSecret(
      settings: await settingsOf(session, updated),
      secret: secret,
    );
  }

  /// Creates or replaces the API key; the old key stops working at once.
  static Future<PublicationSecret> createApiKey(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await _own(session, actor, publicId);
    final key = PublicationKeys.newApiKey();
    final updated = await Publication.db.updateRow(
      session,
      p.copyWith(
        apiKeyHash: PublicationKeys.hashApiKey(key),
        apiKeyLast4: key.substring(key.length - 4),
        updatedAt: nowUtc(),
      ),
      columns: (t) => [t.apiKeyHash, t.apiKeyLast4, t.updatedAt],
    );
    return PublicationSecret(
      settings: await settingsOf(session, updated),
      secret: key,
    );
  }

  static Future<PublicationSettings> setModerators(
    Session session,
    Actor actor,
    String publicId,
    List<String> emails,
  ) async {
    final p = await _own(session, actor, publicId);
    final wanted = <String>{};
    for (final raw in emails) {
      final e = raw.trim().toLowerCase();
      if (e.isEmpty) continue;
      if (!_emailPattern.hasMatch(e)) {
        throw Errors.invalid('"$raw" isn\'t an email address.');
      }
      wanted.add(e);
    }
    if (wanted.length > PublicationRules.maxModerators) {
      throw Errors.limit(
        'A publication can have at most ${PublicationRules.maxModerators} '
        'moderators.',
      );
    }
    final existing = await PublicationModerator.db.find(
      session,
      where: (t) => t.publicationId.equals(p.id!),
    );
    final gone = [
      for (final m in existing)
        if (!wanted.contains(m.email)) m,
    ];
    if (gone.isNotEmpty) await PublicationModerator.db.delete(session, gone);
    final have = {for (final m in existing) m.email};
    final added = [
      for (final e in wanted)
        if (!have.contains(e)) e,
    ];
    if (added.isNotEmpty) {
      final profiles = await UserProfile.db.find(
        session,
        where: (t) => t.email.inSet(added.toSet()),
      );
      final byEmail = {for (final u in profiles) u.email.toLowerCase(): u.id!};
      await PublicationModerator.db.insert(session, [
        for (final e in added)
          PublicationModerator(
            publicationId: p.id!,
            userId: byEmail[e],
            email: e,
          ),
      ]);
    }
    if (gone.isNotEmpty || added.isNotEmpty) {
      await SubmissionService.syncPublication(session, p);
    }
    return settingsOf(session, p);
  }

  // ------------------------------------------- verification and deliveries

  /// Checks `/.well-known/wonky-publications.json` on the site host
  /// (specs/18 §8.2).
  static Future<PublicationCheckResult> verify(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await _own(session, actor, publicId);
    final host = PublicationRules.hostOf(p.siteUrl);
    final url = 'https://$host/.well-known/wonky-publications.json';
    final res = await PublicationHttp.instance.get(url);
    String? problem;
    if (!res.ok) {
      problem = res.status == 0
          ? 'Could not load $url: ${res.error}'
          : '$url answered with HTTP ${res.status}.';
    } else {
      try {
        final json = jsonDecode(res.body);
        final ids = json is Map ? json['publications'] : null;
        if (ids is! List || !ids.contains(p.publicId)) {
          problem = '$url doesn\'t list ${p.publicId}.';
        }
      } on FormatException {
        problem = '$url isn\'t valid JSON.';
      }
    }
    var updated = p;
    if (problem == null || p.verifiedHost != null) {
      updated = await Publication.db.updateRow(
        session,
        p.copyWith(
          verifiedHost: problem == null ? host : null,
          verifiedAt: problem == null ? nowUtc() : null,
        ),
        columns: (t) => [t.verifiedHost, t.verifiedAt],
      );
    }
    return PublicationCheckResult(
      ok: problem == null,
      message: problem,
      settings: await settingsOf(session, updated),
    );
  }

  /// Sends a `publication.ping` now and reports the answer.
  static Future<PublicationCheckResult> sendTest(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await _own(session, actor, publicId);
    final d = await PublicationWebhooks.enqueue(
      session,
      p,
      PublicationWebhooks.envelope('publication.ping', p),
    );
    final ok = await PublicationWebhooks.attempt(session, d.id!);
    final after = await PublicationDelivery.db.findById(session, d.id!);
    return PublicationCheckResult(
      ok: ok,
      message: ok
          ? null
          : after?.lastError ?? 'The webhook didn\'t answer with 2xx.',
      settings: await settingsOf(session, p),
    );
  }

  /// A ping after the webhook URL is set; failures only show under
  /// *Deliveries*.
  static Future<void> _ping(Session session, Publication p) async {
    final d = await PublicationWebhooks.enqueue(
      session,
      p,
      PublicationWebhooks.envelope('publication.ping', p),
    );
    await PublicationWebhooks.scheduler(session, d.id!);
  }

  static Future<List<PublicationDeliveryView>> deliveries(
    Session session,
    Actor actor,
    String publicId,
  ) async {
    final p = await _own(session, actor, publicId);
    final rows = await PublicationDelivery.db.find(
      session,
      where: (t) => t.publicationId.equals(p.id!),
      orderBy: (t) => t.createdAt.desc(),
      limit: 50,
    );
    return [
      for (final d in rows)
        PublicationDeliveryView(
          webhookId: d.webhookId,
          type: d.type,
          createdAt: d.createdAt,
          attempts: d.attempts,
          lastStatus: d.lastStatus,
          lastError: d.lastError,
          deliveredAt: d.deliveredAt,
          failedAt: d.failedAt,
          nextAttemptAt: d.nextAttemptAt,
        ),
    ];
  }

  /// Sends a delivery again now (same `webhook-id`).
  static Future<PublicationDeliveryView> resend(
    Session session,
    Actor actor,
    String publicId,
    String webhookId,
  ) async {
    final p = await _own(session, actor, publicId);
    final d = await PublicationDelivery.db.findFirstRow(
      session,
      where: (t) =>
          t.publicationId.equals(p.id!) & t.webhookId.equals(webhookId),
    );
    if (d == null) throw Errors.notFound('Delivery');
    await PublicationDelivery.db.updateRow(
      session,
      d.copyWith(
        deliveredAt: null,
        failedAt: null,
        nextAttemptAt: nowUtc(),
        leaseUntil: null,
      ),
      columns: (t) => [
        t.deliveredAt,
        t.failedAt,
        t.nextAttemptAt,
        t.leaseUntil,
      ],
    );
    await PublicationWebhooks.attempt(session, d.id!);
    final after = (await PublicationDelivery.db.findById(session, d.id!))!;
    return PublicationDeliveryView(
      webhookId: after.webhookId,
      type: after.type,
      createdAt: after.createdAt,
      attempts: after.attempts,
      lastStatus: after.lastStatus,
      lastError: after.lastError,
      deliveredAt: after.deliveredAt,
      failedAt: after.failedAt,
      nextAttemptAt: after.nextAttemptAt,
    );
  }
}
