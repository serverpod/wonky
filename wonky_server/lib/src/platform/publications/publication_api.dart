import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../common/time.dart';
import '../files/storage_reads.dart';
import 'publication_common.dart';
import 'publication_keys.dart';
import 'publication_rules.dart';
import 'submission_service.dart';

/// The answer of a publication API call (JSON, or a byte stream).
class PublicationApiResult {
  const PublicationApiResult(
    this.status,
    this.json, {
    this.headers = const {},
    this.stream,
    this.contentType,
    this.contentLength,
  });

  factory PublicationApiResult.error(int status, String code, String message) =>
      PublicationApiResult(status, {'error': code, 'message': message});

  final int status;
  final Map<String, Object?>? json;
  final Map<String, String> headers;
  final Stream<Uint8List>? stream;
  final String? contentType;
  final int? contentLength;
}

/// Result of checking the API key from the headers.
class PublicationApiAuth {
  const PublicationApiAuth.ok(Publication this.publication) : refused = null;
  const PublicationApiAuth.refused(PublicationApiResult this.refused)
    : publication = null;

  final Publication? publication;
  final PublicationApiResult? refused;
}

/// The publication API (specs/18 §7.3) behind `/api/pub/v1/**`.
abstract final class PublicationApi {
  static const maxBodyBytes = 1024 * 1024;

  static PublicationApiResult notFound([String what = 'Not found.']) =>
      PublicationApiResult.error(404, 'notFound', what);

  static PublicationApiResult invalid(String message) =>
      PublicationApiResult.error(400, 'invalidArgument', message);

  /// Checks the declared size and the bearer key before any body is read.
  static Future<PublicationApiAuth> authenticate(
    Session session, {
    required String? authorization,
    required int? declaredLength,
  }) async {
    if (declaredLength != null && declaredLength > maxBodyBytes) {
      return PublicationApiAuth.refused(
        PublicationApiResult.error(413, 'tooLarge', 'The body is too large.'),
      );
    }
    const prefix = 'Bearer ';
    final key = authorization != null && authorization.startsWith(prefix)
        ? authorization.substring(prefix.length).trim()
        : null;
    if (key == null || !PublicationKeys.apiKeyPattern.hasMatch(key)) {
      return const PublicationApiAuth.refused(_unauthorized);
    }
    final hash = PublicationKeys.hashApiKey(key);
    final retry = await Publications.apiLimiter.check(hash);
    if (retry != null) {
      return PublicationApiAuth.refused(
        PublicationApiResult(
          429,
          {'error': 'rateLimited', 'message': 'Too many requests.'},
          headers: {'retry-after': '${retry.inSeconds + 1}'},
        ),
      );
    }
    final p = await Publication.db.findFirstRow(
      session,
      where: (t) => t.apiKeyHash.equals(hash),
    );
    if (p == null) return const PublicationApiAuth.refused(_unauthorized);
    return PublicationApiAuth.ok(p);
  }

  static const _unauthorized = PublicationApiResult(401, {
    'error': 'unauthorized',
    'message': 'Send the API key as "Authorization: Bearer wpk_…".',
  });

  /// Routes one call.
  static Future<PublicationApiResult> handle(
    Session session,
    Publication p, {
    required String method,
    required List<String> segments,
    required Map<String, String> query,
    required String body,
  }) async {
    try {
      return switch ((method, segments)) {
        ('GET', ['submissions']) => await _list(session, p, query),
        ('GET', ['submissions', final id]) => await _get(session, p, id),
        ('GET', ['submissions', final id, 'content']) => await _content(
          session,
          p,
          id,
          query,
        ),
        ('POST', ['submissions', final id, 'status']) => await _status(
          session,
          p,
          id,
          body,
        ),
        ('POST', ['submissions', final id, 'messages']) => await _message(
          session,
          p,
          id,
          body,
        ),
        ('GET', ['assets', final id]) => await _asset(session, p, id),
        ('POST', ['blocks']) => await _block(session, p, body),
        ('DELETE', ['blocks', final id]) => await _unblock(session, p, id),
        _ => notFound('No such API call.'),
      };
    } on PublicationGone {
      return PublicationApiResult.error(
        410,
        'gone',
        'The submission was withdrawn or disconnected.',
      );
    } on PublicationTransitionError catch (e) {
      return PublicationApiResult.error(409, 'invalidTransition', e.message);
    } on WonkyException catch (e) {
      return switch (e.code) {
        WonkyErrorCode.notFound => notFound(e.message),
        WonkyErrorCode.invalidArgument => invalid(e.message),
        WonkyErrorCode.tooLarge => PublicationApiResult.error(
          413,
          'tooLarge',
          e.message,
        ),
        _ => PublicationApiResult.error(400, e.code.name, e.message),
      };
    } on FormatException {
      return invalid('The body must be a JSON object.');
    }
  }

  static Map<String, Object?> _object(String body) {
    final json = jsonDecode(body.isEmpty ? '{}' : body);
    if (json is! Map<String, Object?>) throw const FormatException();
    return json;
  }

  static Future<Submission?> _find(
    Session session,
    Publication p,
    String id,
  ) async {
    final uuid = Publications.parseSubmissionId(id);
    if (uuid == null) return null;
    return Submission.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid) & t.publicationId.equals(p.id!),
    );
  }

  static Future<Map<String, Object?>> _entry(
    Session session,
    Submission s, {
    bool withFields = false,
  }) async {
    final item = await DriveItem.db.findById(session, s.itemId);
    final last = await SubmissionRevision.db.findFirstRow(
      session,
      where: (t) => t.submissionId.equals(s.id!),
      orderBy: (t) => t.sequence.desc(),
    );
    return {
      'id': Publications.submissionId(s),
      'ref': s.ref,
      'status': s.status.name,
      'documentUrl': item == null
          ? null
          : Publications.documentUrl(session, item.uuid),
      'title': s.values.title,
      'sequence': last?.sequence,
      'revision': last?.revision,
      'submittedAt': last?.submittedAt.toIso8601String(),
      'updatedAt': s.updatedAt.toIso8601String(),
      'publicUrl': s.publicUrl,
      if (withFields)
        'fields': {
          'title': s.values.title,
          'summary': s.values.summary,
          'tags': s.values.tags,
          'coverImage': s.values.coverImage == null
              ? null
              : Publications.assetId(s.values.coverImage!),
          'authorBio': s.values.authorBio,
          'note': s.values.note,
        },
    };
  }

  static Future<PublicationApiResult> _list(
    Session session,
    Publication p,
    Map<String, String> query,
  ) async {
    final status = query['status'];
    final SubmissionStatus? filter;
    if (status == null || status.isEmpty) {
      filter = null;
    } else {
      filter = SubmissionStatus.values.asNameMap()[status];
      if (filter == null) return invalid('Unknown status "$status".');
    }
    final limit = int.tryParse(query['limit'] ?? '') ?? 50;
    if (limit < 1 || limit > 100) return invalid('limit must be 1–100.');
    // Cursor: "<updatedAt micros>_<id>" of the last entry of a page.
    DateTime? afterAt;
    int? afterId;
    if (query['after'] case final after? when after.isNotEmpty) {
      final parts = after.split('_');
      final micros = parts.length == 2 ? int.tryParse(parts[0]) : null;
      afterId = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (micros == null || afterId == null) return invalid('Invalid cursor.');
      afterAt = DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
    }
    final rows = await Submission.db.find(
      session,
      where: (t) {
        var w =
            t.publicationId.equals(p.id!) &
            t.status.notEquals(
              SubmissionStatus.draft,
            );
        if (filter != null) w = w & t.status.equals(filter);
        if (afterAt != null) {
          w =
              w &
              ((t.updatedAt < afterAt) |
                  (t.updatedAt.equals(afterAt) & (t.id < afterId!)));
        }
        return w;
      },
      orderByList: (t) => [t.updatedAt.desc(), t.id.desc()],
      limit: limit + 1,
    );
    final page = rows.take(limit).toList();
    return PublicationApiResult(200, {
      'submissions': [for (final s in page) await _entry(session, s)],
      'next': rows.length > limit
          ? '${page.last.updatedAt.microsecondsSinceEpoch}_${page.last.id}'
          : null,
    });
  }

  static Future<PublicationApiResult> _get(
    Session session,
    Publication p,
    String id,
  ) async {
    final s = await _find(session, p, id);
    if (s == null || s.status == SubmissionStatus.draft) {
      return notFound('No such submission.');
    }
    return PublicationApiResult(
      200,
      await _entry(session, s, withFields: true),
    );
  }

  static Future<PublicationApiResult> _content(
    Session session,
    Publication p,
    String id,
    Map<String, String> query,
  ) async {
    final s = await _find(session, p, id);
    if (s == null) return notFound('No such submission.');
    final sequence = int.tryParse(query['sequence'] ?? '');
    if (query['sequence'] != null && sequence == null) {
      return invalid('sequence must be a number.');
    }
    final rev = await SubmissionRevision.db.findFirstRow(
      session,
      where: (t) => sequence == null
          ? t.submissionId.equals(s.id!)
          : t.submissionId.equals(s.id!) & t.sequence.equals(sequence),
      orderBy: (t) => t.sequence.desc(),
    );
    if (rev == null) return notFound('No such submitted version.');
    return PublicationApiResult(
      200,
      (jsonDecode(rev.payload) as Map).cast<String, Object?>(),
    );
  }

  static Future<PublicationApiResult> _status(
    Session session,
    Publication p,
    String id,
    String body,
  ) async {
    final s = await _find(session, p, id);
    if (s == null || s.status == SubmissionStatus.draft) {
      return notFound('No such submission.');
    }
    final json = _object(body);
    final status = SubmissionStatus.values.asNameMap()['${json['status']}'];
    if (status == null) {
      return invalid(
        'status must be inReview, changesRequested, declined or published.',
      );
    }
    final message = json['message'];
    final url = json['publicUrl'];
    if (message != null && message is! String) {
      return invalid('message must be a string.');
    }
    if (url != null && url is! String) {
      return invalid('publicUrl must be a string.');
    }
    if (message is String &&
        message.length > PublicationRules.maxMessageLength) {
      return invalid('message is longer than 10,000 characters.');
    }
    final updated = await SubmissionService.setStatus(
      session,
      p,
      s,
      status: status,
      message: message as String?,
      publicUrl: url as String?,
    );
    return PublicationApiResult(
      200,
      await _entry(session, updated, withFields: true),
    );
  }

  static Future<PublicationApiResult> _message(
    Session session,
    Publication p,
    String id,
    String body,
  ) async {
    final s = await _find(session, p, id);
    if (s == null || s.status == SubmissionStatus.draft) {
      return notFound('No such submission.');
    }
    final text = _object(body)['body'];
    if (text is! String || text.trim().isEmpty) {
      return invalid('body must be a non-empty string.');
    }
    if (text.length > PublicationRules.maxMessageLength) {
      return invalid('body is longer than 10,000 characters.');
    }
    await SubmissionService.postMessage(session, p, s, text);
    return const PublicationApiResult(200, {'ok': true});
  }

  static Future<PublicationApiResult> _asset(
    Session session,
    Publication p,
    String id,
  ) async {
    final uuid = Publications.parseAssetId(id);
    if (uuid == null) return notFound('No such asset.');
    final uses = await SubmissionAsset.db.find(
      session,
      where: (t) => t.fileUuid.equals(uuid),
    );
    final allowed =
        uses.isNotEmpty &&
        await Submission.db.count(
              session,
              where: (t) =>
                  t.id.inSet(<int>{for (final a in uses) a.submissionId}) &
                  t.publicationId.equals(p.id!),
            ) >
            0;
    if (!allowed) return notFound('No such asset.');
    final file = await StoredFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(uuid),
    );
    if (file == null || file.status != StoredFileStatus.ready) {
      return notFound('The image no longer exists.');
    }
    return PublicationApiResult(
      200,
      null,
      headers: const {
        'x-content-type-options': 'nosniff',
        'content-security-policy': "sandbox; default-src 'none'",
        'cache-control': 'private, no-store',
      },
      stream: StorageReads.stream(session.serverpod, file),
      contentType: file.mimeType,
      contentLength: file.sizeBytes,
    );
  }

  static Future<int?> _profileOf(Session session, Object? wonkyUserId) async {
    if (wonkyUserId is! String) return null;
    try {
      final uuid = UuidValue.withValidation(wonkyUserId);
      final profile = await UserProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(uuid),
      );
      return profile?.id;
    } on FormatException {
      return null;
    }
  }

  static Future<PublicationApiResult> _block(
    Session session,
    Publication p,
    String body,
  ) async {
    final userId = await _profileOf(session, _object(body)['wonkyUserId']);
    if (userId == null) return notFound('No such Wonky user.');
    final existing = await PublicationBlock.db.findFirstRow(
      session,
      where: (t) => t.publicationId.equals(p.id!) & t.userId.equals(userId),
    );
    if (existing == null) {
      await PublicationBlock.db.insertRow(
        session,
        PublicationBlock(publicationId: p.id!, userId: userId, at: nowUtc()),
      );
    }
    return const PublicationApiResult(200, {'ok': true});
  }

  static Future<PublicationApiResult> _unblock(
    Session session,
    Publication p,
    String wonkyUserId,
  ) async {
    final userId = await _profileOf(session, wonkyUserId);
    if (userId != null) {
      await PublicationBlock.db.deleteWhere(
        session,
        where: (t) => t.publicationId.equals(p.id!) & t.userId.equals(userId),
      );
    }
    return const PublicationApiResult(200, {'ok': true});
  }
}
