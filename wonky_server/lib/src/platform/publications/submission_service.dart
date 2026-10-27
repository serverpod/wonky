import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../write/ot/document_store.dart';
import '../activity/activity_service.dart';
import '../comments/comment_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/guarded.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../drive/drive_events.dart';
import '../files/file_service.dart';
import '../notifications/notification_service.dart';
import '../sharing/access_service.dart';
import '../sharing/acl_events.dart';
import '../users/user_service.dart';
import '../versions/version_service.dart';
import 'publication_common.dart';
import 'publication_rules.dart';
import 'publication_webhooks.dart';

/// Submissions of Write documents to publications (specs/18 §4, §5, §7):
/// submit, withdraw, disconnect, moderator access, the blog's status calls
/// and messages, and the hooks of trash and comment replies.
abstract final class SubmissionService {
  static final _wonkyFile = RegExp(
    r'wonky-file://([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
  );

  // ------------------------------------------------------------- lookups

  static Future<Submission?> ofItem(Session session, DriveItem item) =>
      Submission.db.findFirstRow(
        session,
        where: (t) => t.itemId.equals(item.id!),
      );

  /// The connected submission of [itemUuid] for a caller with [min].
  static Future<(Submission, Publication, DriveItem, Role)> _require(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    Role min,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      min,
    );
    final s = await ofItem(session, item);
    if (s == null || s.disconnectedAt != null) {
      throw Errors.notFound('Submission');
    }
    final p = await Publication.db.findById(session, s.publicationId);
    if (p == null) throw Errors.notFound('Publication');
    return (s, p, item, role);
  }

  // --------------------------------------------------------------- views

  /// The submission of a document, or null when it has none (viewer+).
  static Future<SubmissionView?> get(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    final s = await ofItem(session, item);
    if (s == null || s.disconnectedAt != null) return null;
    final p = await Publication.db.findById(session, s.publicationId);
    if (p == null) return null;
    return view(session, actor, s, p, item);
  }

  static Future<SubmissionView> view(
    Session session,
    Actor actor,
    Submission s,
    Publication p,
    DriveItem item,
  ) async {
    final revisions = await SubmissionRevision.db.find(
      session,
      where: (t) => t.submissionId.equals(s.id!),
      orderBy: (t) => t.sequence,
    );
    final users = await UserService.summaries(session, [
      for (final r in revisions) r.submittedById,
    ]);
    final versions = {
      for (final v in await ItemVersion.db.find(
        session,
        where: (t) => t.id.inSet(<int>{
          for (final r in revisions)
            if (r.versionId != null) r.versionId!,
        }),
      ))
        v.id!: v,
    };
    CommentThread? thread;
    Comment? last;
    if (s.feedbackThreadId != null) {
      thread = await CommentThread.db.findById(session, s.feedbackThreadId!);
      last = await Comment.db.findFirstRow(
        session,
        where: (t) =>
            t.threadId.equals(s.feedbackThreadId!) &
            t.publicationId.equals(p.id!) &
            t.deletedAt.equals(null),
        orderBy: (t) => t.createdAt.desc(),
      );
    }
    final blocked = await Publications.isBlocked(session, p.id!, actor.userId);
    return SubmissionView(
      id: Publications.submissionId(s),
      itemUuid: item.uuid,
      status: s.status,
      delivery: s.delivery,
      publicationId: p.publicId,
      publicationName: p.name,
      shownHost: Publications.shownHost(p),
      verified: p.verifiedHost != null,
      accepting: p.enabled && !blocked,
      fields: p.fields,
      termsUrl: p.termsUrl,
      markdownFlavor: p.markdownFlavor,
      consentNeeded: await Publications.consentNeeded(
        session,
        p,
        actor.userId,
      ),
      values: s.values,
      publicUrl: s.publicUrl,
      feedbackThreadUuid: thread?.uuid,
      lastMessage: last?.body,
      lastMessageAt: last?.createdAt,
      lastSubmittedRevision: revisions.isEmpty ? null : revisions.last.revision,
      revisions: [
        for (final r in revisions)
          SubmissionRevisionView(
            sequence: r.sequence,
            revision: r.revision,
            submittedByName:
                users[r.submittedById]?.displayName ?? 'Deleted user',
            submittedAt: r.submittedAt,
            versionId: versions.containsKey(r.versionId) ? r.versionId : null,
          ),
      ],
      updatedAt: s.updatedAt,
    );
  }

  // -------------------------------------------------------------- submit

  /// Submits the document's current revision (specs/18 §4.2, §7.2): names
  /// a version, stores the payload, grants the moderators Commenter and
  /// tries the webhook once (≤ 10 s); a failure is retried by the outbox.
  static Future<SubmissionView> submit(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    SubmissionValues values, {
    bool agreed = false,
  }) async {
    final (s, p, item, _) = await _require(
      session,
      actor,
      itemUuid,
      Role.editor,
    );
    if (!p.enabled) {
      throw Errors.forbidden('${p.name} isn\'t accepting stories right now.');
    }
    if (await Publications.isBlocked(session, p.id!, actor.userId)) {
      throw Errors.forbidden('${p.name} isn\'t accepting stories from you.');
    }
    if (!PublicationRules.maySubmit(s.status)) {
      throw Errors.forbidden('${p.name} declined this story.');
    }
    if (await Publications.consentNeeded(session, p, actor.userId)) {
      if (!agreed) {
        throw Errors.invalid('Agree to send your story to ${p.name} first.');
      }
      await Publications.recordConsent(session, p, actor.userId);
    }
    final clean = PublicationRules.values(values, p.fields);
    await Publications.checkLimit(
      Publications.submitLimiter,
      '${p.id}:${actor.userId}',
      "You've sent a lot to ${p.name} today. Try again tomorrow.",
    );
    final doc = await DocumentStore.requireByItem(session, item.id!);
    final version = await VersionService.capture(
      session,
      item,
      kind: VersionKind.named,
      name: 'Submitted to ${p.name}',
      createdById: actor.userId,
    );
    final revision = version.revision ?? doc.headRevision;
    final content = await DocumentStore.contentAt(
      session,
      (await DocumentStore.requireByItem(session, item.id!)),
      revision,
    );
    // In the document's flavor (Write 11 §3.3).
    final flavor = core.MarkdownFlavor.parse(doc.markdownFlavor);
    var markdown = const core.MarkdownCodec().exportMarkdown(
      content,
      view: core.SuggestionViewMode.original,
      options: core.MarkdownExportOptions(flavor: flavor),
    );
    final assets = await _assets(session, actor, markdown);
    markdown = markdown.replaceAllMapped(_wonkyFile, (m) {
      final uuid = UuidValue.withValidation(m[1]!.toLowerCase());
      return assets.containsKey(uuid)
          ? Publications.assetUrl(session, uuid)
          : m[0]!;
    });
    if (utf8.encode(markdown).length > PublicationRules.maxMarkdownBytes) {
      throw Errors.tooLarge('This story is too long to submit (over 5 MB).');
    }
    // The cover is uploaded in the submit dialog as an image of the document
    // without being in its text (specs/18 §4.2), or (older submits) one of
    // the document's images. Either way it is an asset of the submission, so
    // the API key may download it.
    final coverFile = clean.coverImage == null
        ? null
        : assets[clean.coverImage] ??
              await _coverOfItem(session, item, clean.coverImage!);
    if (coverFile != null) assets[coverFile.fileUuid] = coverFile;
    final cover = coverFile?.fileUuid;
    if (cover == null && p.fields.coverImage == PublicationFieldMode.required) {
      throw Errors.invalid('Upload a cover image.');
    }
    final stored = clean.copyWith(coverImage: cover);
    final submitter = (await UserService.summaries(session, [
      actor.userId,
    ]))[actor.userId];
    final profile = await UserProfile.db.findById(session, actor.userId);
    final now = nowUtc();
    final last = await SubmissionRevision.db.findFirstRow(
      session,
      where: (t) => t.submissionId.equals(s.id!),
      orderBy: (t) => t.sequence.desc(),
    );
    final sequence = (last?.sequence ?? 0) + 1;
    final submitted = s.copyWith(
      status: SubmissionStatus.inReview,
      statusBeforeSubmit: s.status,
      delivery: SubmissionDeliveryState.pending,
      values: stored,
      updatedAt: now,
    );
    final body = {
      ...PublicationWebhooks.envelope('submission.submitted', p),
      'submission': PublicationWebhooks.submissionJson(
        session,
        submitted,
        item,
      ),
      'sequence': sequence,
      'revision': revision,
      'fields': {
        'title': stored.title,
        'summary': stored.summary,
        'tags': stored.tags,
        'coverImage': cover == null ? null : Publications.assetId(cover),
        'authorBio': stored.authorBio,
        'note': stored.note,
      },
      'markdown': markdown,
      'markdownFlavor': flavor.value,
      'assets': [
        for (final f in assets.values)
          {
            'id': Publications.assetId(f.fileUuid),
            'name': f.fileName,
            'type': f.mimeType,
            'bytes': f.sizeBytes,
            'url': Publications.assetUrl(session, f.fileUuid),
          },
      ],
      'submittedBy': {
        'name': submitter?.displayName ?? 'Someone',
        'wonkyUserId': profile?.authUserId.uuid,
      },
    };
    final delivery = await session.db.transaction((tx) async {
      await SubmissionRevision.db.insertRow(
        session,
        SubmissionRevision(
          submissionId: s.id!,
          sequence: sequence,
          revision: revision,
          versionId: version.id,
          values: stored,
          payload: jsonEncode(body),
          submittedById: actor.userId,
          submittedAt: now,
        ),
        transaction: tx,
      );
      final known = {
        for (final a in await SubmissionAsset.db.find(
          session,
          where: (t) => t.submissionId.equals(s.id!),
          transaction: tx,
        ))
          a.fileUuid,
      };
      final fresh = [
        for (final u in assets.keys)
          if (!known.contains(u))
            SubmissionAsset(submissionId: s.id!, fileUuid: u),
      ];
      if (fresh.isNotEmpty) {
        await SubmissionAsset.db.insert(session, fresh, transaction: tx);
      }
      await Submission.db.updateRow(
        session,
        submitted,
        columns: (t) => [
          t.status,
          t.statusBeforeSubmit,
          t.delivery,
          t.values,
          t.updatedAt,
        ],
        transaction: tx,
      );
      return PublicationWebhooks.enqueue(
        session,
        p,
        body,
        submission: s,
        sequence: sequence,
        transaction: tx,
      );
    });
    await syncModerators(session, submitted, p, item);
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.submission,
      summary: {'publication': p.name, 'action': 'submitted'},
    );
    // One try while the contributor waits; the outbox retries the rest.
    await runGuarded<bool>(
      session,
      'publications.submit ${delivery.webhookId}',
      () => PublicationWebhooks.attempt(session, delivery.id!),
    );
    await _changed(session, item);
    final fresh = await Submission.db.findById(session, s.id!);
    return view(session, actor, fresh!, p, item);
  }

  /// The images of [markdown] the submitter may read, by file uuid.
  /// The cover image [fileUuid] when it is a ready image file of [item]
  /// (uploaded in the submit dialog); null otherwise, so a submit can't
  /// hand the publication someone else's file.
  static Future<StoredFile?> _coverOfItem(
    Session session,
    DriveItem item,
    UuidValue fileUuid,
  ) async {
    final file = await FileService.byUuid(session, fileUuid);
    if (file == null ||
        file.itemId != item.id ||
        file.kind != StoredFileKind.image ||
        file.status != StoredFileStatus.ready) {
      return null;
    }
    return file;
  }

  static Future<Map<UuidValue, StoredFile>> _assets(
    Session session,
    Actor actor,
    String markdown,
  ) async {
    final result = <UuidValue, StoredFile>{};
    for (final m in _wonkyFile.allMatches(markdown)) {
      final uuid = UuidValue.withValidation(m[1]!.toLowerCase());
      if (result.containsKey(uuid)) continue;
      final file = await FileService.byUuid(session, uuid);
      if (file == null ||
          file.status != StoredFileStatus.ready ||
          !await FileService.canRead(session, actor, file)) {
        continue;
      }
      result[uuid] = file;
    }
    return result;
  }

  /// After a submit's delivery settled (from the outbox): drive signal, and
  /// on failure the moderators' access follows the restored status and the
  /// submitter is told (specs/18 §7.2).
  static Future<void> afterDelivery(
    Session session,
    int submissionId, {
    required bool delivered,
    required int submitterId,
  }) async {
    final s = await Submission.db.findById(session, submissionId);
    if (s == null) return;
    final item = await DriveItem.db.findById(session, s.itemId);
    final p = await Publication.db.findById(session, s.publicationId);
    if (item == null || p == null) return;
    if (!delivered) {
      await syncModerators(session, s, p, item);
      await NotificationService.notify(
        session,
        userId: submitterId,
        kind: NotificationKind.submission,
        item: item,
        payload: {
          'publication': p.name,
          'event': 'deliveryFailed',
          'excerpt': "${p.name} couldn't receive your submission.",
        },
      );
    }
    await _changed(session, item);
  }

  // --------------------------------------------- withdraw and disconnect

  static Future<SubmissionView> withdraw(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (s, p, item, _) = await _require(
      session,
      actor,
      itemUuid,
      Role.editor,
    );
    if (!PublicationRules.isOpen(s.status)) {
      throw Errors.conflict('This story isn\'t in review.');
    }
    final updated = await _withdraw(session, actor, s, p, item, 'author');
    return view(session, actor, updated, p, item);
  }

  static Future<Submission> _withdraw(
    Session session,
    Actor? actor,
    Submission s,
    Publication p,
    DriveItem item,
    String reason,
  ) async {
    final updated = s.copyWith(
      status: SubmissionStatus.withdrawn,
      delivery: null,
      updatedAt: nowUtc(),
    );
    await Submission.db.updateRow(
      session,
      updated,
      columns: (t) => [t.status, t.delivery, t.updatedAt],
    );
    await syncModerators(session, updated, p, item);
    await PublicationWebhooks.send(session, p, {
      ...PublicationWebhooks.envelope('submission.withdrawn', p),
      'submission': PublicationWebhooks.submissionJson(session, updated, item),
      'reason': reason,
    }, submission: updated);
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.submission,
      summary: {'publication': p.name, 'action': 'withdrawn'},
    );
    await _changed(session, item);
    return updated;
  }

  /// Disconnects the document (specs/18 §4.5); undone by [reconnect].
  static Future<void> disconnect(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (s, p, item, _) = await _require(
      session,
      actor,
      itemUuid,
      Role.editor,
    );
    if (PublicationRules.isOpen(s.status)) {
      throw Errors.conflict('Withdraw the story before you disconnect it.');
    }
    final updated = s.copyWith(disconnectedAt: nowUtc(), updatedAt: nowUtc());
    await Submission.db.updateRow(
      session,
      updated,
      columns: (t) => [t.disconnectedAt, t.updatedAt],
    );
    await syncModerators(session, updated, p, item);
    if (s.status != SubmissionStatus.draft) {
      await PublicationWebhooks.send(session, p, {
        ...PublicationWebhooks.envelope('submission.disconnected', p),
        'submission': PublicationWebhooks.submissionJson(
          session,
          updated,
          item,
        ),
      }, submission: updated);
    }
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.submission,
      summary: {'publication': p.name, 'action': 'disconnected'},
    );
    await _changed(session, item);
  }

  /// Undoes [disconnect].
  static Future<SubmissionView?> reconnect(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.editor,
    );
    final s = await ofItem(session, item);
    if (s == null) throw Errors.notFound('Submission');
    final p = await Publication.db.findById(session, s.publicationId);
    if (p == null) throw Errors.notFound('Publication');
    if (s.disconnectedAt == null) return view(session, actor, s, p, item);
    final updated = s.copyWith(disconnectedAt: null, updatedAt: nowUtc());
    await Submission.db.updateRow(
      session,
      updated,
      columns: (t) => [t.disconnectedAt, t.updatedAt],
    );
    await syncModerators(session, updated, p, item);
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.submission,
      summary: {'publication': p.name, 'action': 'reconnected'},
    );
    await _changed(session, item);
    return view(session, actor, updated, p, item);
  }

  // --------------------------------------------------- moderator access

  /// Brings the moderators' Commenter grants of [item] in line with the
  /// submission (specs/18 §5.1).
  static Future<void> syncModerators(
    Session session,
    Submission s,
    Publication p,
    DriveItem item,
  ) async {
    final wanted = <int>{};
    if (s.disconnectedAt == null &&
        item.trashedAt == null &&
        PublicationRules.moderatorsHaveAccess(s.status)) {
      final mods = await PublicationModerator.db.find(
        session,
        where: (t) => t.publicationId.equals(p.id!) & t.userId.notEquals(null),
      );
      wanted.addAll([
        for (final m in mods)
          if (m.userId != item.ownerId) m.userId!,
      ]);
    }
    final existing = await DriveItemPermission.db.find(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) & t.viaPublicationId.equals(p.id!),
    );
    final have = {for (final g in existing) g.userId};
    final changed = <int>{};
    final remove = [
      for (final g in existing)
        if (!wanted.contains(g.userId)) g,
    ];
    if (remove.isNotEmpty) {
      await DriveItemPermission.db.delete(session, remove);
      changed.addAll([for (final g in remove) g.userId!]);
    }
    final missing = wanted.difference(have);
    if (missing.isNotEmpty) {
      final direct = {
        for (final g in await DriveItemPermission.db.find(
          session,
          where: (t) =>
              t.itemId.equals(item.id!) &
              t.inheritedFromId.equals(null) &
              t.invitedEmail.equals(null) &
              t.userId.inSet(missing),
        ))
          g.userId,
      };
      final now = nowUtc();
      final rows = [
        for (final u in missing)
          if (!direct.contains(u))
            DriveItemPermission(
              itemId: item.id!,
              userId: u,
              role: AccessRole.commenter,
              grantedById: s.createdById,
              grantedAt: now,
              viaPublicationId: p.id,
            ),
      ];
      if (rows.isNotEmpty) {
        await DriveItemPermission.db.insert(session, rows);
        changed.addAll([for (final r in rows) r.userId!]);
      }
    }
    if (changed.isNotEmpty) {
      await AclEvents.changed(
        session,
        item,
        affectedUsers: changed,
        kind: DriveChangeKind.shared,
      );
    }
  }

  /// Grants a newly linked moderator access to the publication's open
  /// submissions (after the owner adds them or they sign up).
  static Future<void> syncPublication(Session session, Publication p) async {
    final subs = await Submission.db.find(
      session,
      where: (t) =>
          t.publicationId.equals(p.id!) & t.disconnectedAt.equals(null),
    );
    for (final s in subs) {
      final item = await DriveItem.db.findById(session, s.itemId);
      if (item == null) continue;
      await runGuarded<void>(
        session,
        'publications.syncModerators ${s.id}',
        () => syncModerators(session, s, p, item),
      );
    }
  }

  // ------------------------------------------------------ blog → Wonky

  /// The blog's status call (specs/18 §7.3).
  static Future<Submission> setStatus(
    Session session,
    Publication p,
    Submission s, {
    required SubmissionStatus status,
    String? message,
    String? publicUrl,
  }) async {
    if (s.disconnectedAt != null || s.status == SubmissionStatus.withdrawn) {
      throw const PublicationGone();
    }
    if (!PublicationRules.blogMayMove(s.status, status)) {
      throw PublicationTransitionError(s.status, status);
    }
    String? url = s.publicUrl;
    if (status == SubmissionStatus.published) {
      if (publicUrl == null || publicUrl.isEmpty) {
        throw Errors.invalid('Set publicUrl when the status is published.');
      }
      url = PublicationRules.httpsUrl(publicUrl, 'publicUrl').toString();
    }
    final item = await DriveItem.db.findById(session, s.itemId);
    if (item == null) throw Errors.notFound('Submission');
    final updated = s.copyWith(
      status: status,
      publicUrl: url,
      updatedAt: nowUtc(),
    );
    await Submission.db.updateRow(
      session,
      updated,
      columns: (t) => [t.status, t.publicUrl, t.updatedAt],
    );
    final heading = switch (status) {
      SubmissionStatus.inReview => '**In review**',
      SubmissionStatus.changesRequested => '**Changes requested**',
      SubmissionStatus.declined => '**Declined**',
      SubmissionStatus.published => '**Published**: $url',
      _ => '',
    };
    final text = [
      if (status != s.status || status == SubmissionStatus.published) heading,
      if (message != null && message.trim().isNotEmpty) message.trim(),
    ].join('\n\n');
    if (text.isNotEmpty) await _post(session, p, updated, item, text);
    await syncModerators(session, updated, p, item);
    if (status != s.status) {
      await ActivityService.log(
        session,
        item.id!,
        null,
        ActivityType.submission,
        summary: {
          'publication': p.name,
          'action': 'status',
          'status': status.name,
        },
      );
    }
    await _notifyEditors(session, p, item, {
      'event': 'status',
      'status': status.name,
      'excerpt': _excerpt(message) ?? _statusText(p, status),
    });
    await _changed(session, item);
    return updated;
  }

  /// The blog's message without a status change (specs/18 §7.3).
  static Future<void> postMessage(
    Session session,
    Publication p,
    Submission s,
    String body,
  ) async {
    if (s.disconnectedAt != null || s.status == SubmissionStatus.withdrawn) {
      throw const PublicationGone();
    }
    final item = await DriveItem.db.findById(session, s.itemId);
    if (item == null) throw Errors.notFound('Submission');
    await _post(session, p, s, item, body.trim());
    await _notifyEditors(session, p, item, {
      'event': 'message',
      'excerpt': _excerpt(body),
    });
    await _changed(session, item);
  }

  static String _statusText(Publication p, SubmissionStatus status) =>
      switch (status) {
        SubmissionStatus.inReview => '${p.name} is reviewing your story.',
        SubmissionStatus.changesRequested =>
          '${p.name} asked for changes to your story.',
        SubmissionStatus.declined => '${p.name} declined your story.',
        SubmissionStatus.published => '${p.name} published your story.',
        _ => '${p.name} updated your story.',
      };

  static String? _excerpt(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t.length <= 200 ? t : '${t.substring(0, 199)}…';
  }

  /// Adds a message of the publication to the feedback thread, creating or
  /// reopening it (specs/18 §5.2).
  static Future<void> _post(
    Session session,
    Publication p,
    Submission s,
    DriveItem item,
    String body,
  ) async {
    final now = nowUtc();
    CommentThread? thread = s.feedbackThreadId == null
        ? null
        : await CommentThread.db.findById(session, s.feedbackThreadId!);
    var kind = CommentEventKind.threadUpdated;
    await session.db.transaction((tx) async {
      if (thread == null) {
        thread = await CommentThread.db.insertRow(
          session,
          CommentThread(
            uuid: const Uuid().v7obj(),
            itemId: item.id!,
            anchorKind: CommentAnchorKind.document,
            anchorJson: '{"v":1}',
            status: CommentStatus.open,
            createdById: s.createdById,
            createdAt: now,
          ),
          transaction: tx,
        );
        kind = CommentEventKind.threadCreated;
        await Submission.db.updateRow(
          session,
          s.copyWith(feedbackThreadId: thread!.id),
          columns: (t) => [t.feedbackThreadId],
          transaction: tx,
        );
      } else if (thread!.status != CommentStatus.open) {
        thread = await CommentThread.db.updateRow(
          session,
          thread!.copyWith(
            status: CommentStatus.open,
            resolvedAt: null,
            resolvedById: null,
            updatedAt: now,
          ),
          columns: (t) => [t.status, t.resolvedAt, t.resolvedById, t.updatedAt],
          transaction: tx,
        );
      }
      await Comment.db.insertRow(
        session,
        Comment(
          threadId: thread!.id!,
          uuid: const Uuid().v7obj(),
          authorKind: ActorKind.system,
          body: body.length > PublicationRules.maxMessageLength
              ? body.substring(0, PublicationRules.maxMessageLength)
              : body,
          mentions: const [],
          createdAt: now,
          publicationId: p.id,
        ),
        transaction: tx,
      );
    });
    await CommentService.signal(session, item, kind, thread!.uuid);
  }

  static Future<void> _notifyEditors(
    Session session,
    Publication p,
    DriveItem item,
    Map<String, Object?> payload,
  ) async {
    for (final userId in await Publications.editorsOf(session, item)) {
      await NotificationService.notify(
        session,
        userId: userId,
        kind: NotificationKind.submission,
        item: item,
        payload: {'publication': p.name, ...payload},
      );
    }
  }

  // ---------------------------------------------------------------- hooks

  /// Withdraws open submissions of trashed documents (specs/18 §4.5).
  static Future<void> onTrashed(Session session, List<DriveItem> nodes) async {
    final docs = [
      for (final n in nodes)
        if (n.kind == DriveItemKind.document) n,
    ];
    if (docs.isEmpty) return;
    final subs = await Submission.db.find(
      session,
      where: (t) =>
          t.itemId.inSet({for (final d in docs) d.id!}) &
          t.disconnectedAt.equals(null),
    );
    for (final s in subs) {
      final item = await DriveItem.db.findById(session, s.itemId);
      final p = await Publication.db.findById(session, s.publicationId);
      if (item == null || p == null) continue;
      if (PublicationRules.isOpen(s.status)) {
        await _withdraw(session, null, s, p, item, 'trashed');
      } else {
        await syncModerators(session, s, p, item);
      }
    }
  }

  /// Moderator access returns with a restored document.
  static Future<void> onRestored(Session session, List<DriveItem> nodes) async {
    final subs = await Submission.db.find(
      session,
      where: (t) =>
          t.itemId.inSet({for (final n in nodes) n.id!}) &
          t.disconnectedAt.equals(null),
    );
    for (final s in subs) {
      final item = await DriveItem.db.findById(session, s.itemId);
      final p = await Publication.db.findById(session, s.publicationId);
      if (item == null || p == null) continue;
      await syncModerators(session, s, p, item);
    }
  }

  /// Sends `comment.created` for replies in a feedback thread (specs/18
  /// §5.2).
  static Future<void> onReply(
    Session session,
    CommentThread thread,
    Actor actor, {
    required String body,
    UuidValue? commentUuid,
  }) async {
    final s = await Submission.db.findFirstRow(
      session,
      where: (t) =>
          t.feedbackThreadId.equals(thread.id!) & t.disconnectedAt.equals(null),
    );
    if (s == null) return;
    final p = await Publication.db.findById(session, s.publicationId);
    final item = await DriveItem.db.findById(session, s.itemId);
    if (p == null || item == null) return;
    final author = (await UserService.summaries(session, [
      actor.userId,
    ]))[actor.userId];
    final profile = await UserProfile.db.findById(session, actor.userId);
    final isModerator =
        await PublicationModerator.db.findFirstRow(
          session,
          where: (t) =>
              t.publicationId.equals(p.id!) & t.userId.equals(actor.userId),
        ) !=
        null;
    await PublicationWebhooks.send(session, p, {
      ...PublicationWebhooks.envelope('comment.created', p),
      'submission': PublicationWebhooks.submissionJson(session, s, item),
      'comment': {
        'id': (commentUuid ?? const Uuid().v7obj()).uuid,
        'body': body,
        'author': {
          'name': author?.displayName ?? 'Someone',
          'wonkyUserId': profile?.authUserId.uuid,
          'isModerator': isModerator,
        },
      },
    }, submission: s);
  }

  /// After a publication was deleted: the moderators' grants went with it.
  static Future<void> changedAfterDelete(
    Session session,
    DriveItem item,
  ) async {
    await AclEvents.changed(session, item, kind: DriveChangeKind.shared);
    await _changed(session, item);
  }

  /// Tells open editors (and Drive) that the submission changed.
  static Future<void> _changed(Session session, DriveItem item) =>
      DriveEvents.notify(session, item, DriveChangeKind.updated);
}

/// The submission was withdrawn or disconnected (`410 gone`).
class PublicationGone implements Exception {
  const PublicationGone();
}

/// A status change the blog may not make (`409 invalidTransition`).
class PublicationTransitionError implements Exception {
  const PublicationTransitionError(this.from, this.to);
  final SubmissionStatus from;
  final SubmissionStatus to;

  String get message =>
      'A submission that is ${from.name} can\'t be set to ${to.name}.';
}
