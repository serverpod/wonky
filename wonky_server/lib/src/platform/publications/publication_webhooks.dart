import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';

import '../common/guarded.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'publication_common.dart';
import 'publication_http.dart';
import 'publication_keys.dart';
import 'submission_service.dart';

/// The webhook outbox of publications (specs/18 §7.1, §7.2): every event
/// is stored first, then sent signed; failures are retried with the same
/// `webhook-id`.
abstract final class PublicationWebhooks {
  /// Delays after the 1st … 6th failed attempt; after the 7th attempt the
  /// delivery fails.
  static const retryDelays = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 30),
    Duration(hours: 2),
    Duration(hours: 6),
    Duration(hours: 12),
  ];

  /// How long one instance holds a delivery while sending it.
  static Duration leaseDuration = const Duration(seconds: 60);

  /// At most this many deliveries are sent per sweep.
  static const sweepBatch = 50;

  /// Schedules sending a delivery soon (tests replace it to send inline or
  /// record).
  static Future<void> Function(Session session, int deliveryId) scheduler =
      _viaFutureCall;

  static Future<void> _viaFutureCall(Session session, int deliveryId) => session
      .serverpod
      .futureCalls
      .callWithDelay(Duration.zero)
      .publications
      .deliver(deliveryId);

  /// The common fields of every body.
  static Map<String, Object?> envelope(String type, Publication p) => {
    'type': type,
    'createdAt': nowUtc().toIso8601String(),
    'publicationId': p.publicId,
  };

  /// The `submission` object of a body.
  static Map<String, Object?> submissionJson(
    Session session,
    Submission s,
    DriveItem item,
  ) => {
    'id': Publications.submissionId(s),
    'ref': s.ref,
    'status': s.status.name,
    'documentUrl': Publications.documentUrl(session, item.uuid),
  };

  /// Stores a delivery of [body]; returns the row.
  static Future<PublicationDelivery> enqueue(
    Session session,
    Publication p,
    Map<String, Object?> body, {
    Submission? submission,
    int? sequence,
    Transaction? transaction,
  }) => PublicationDelivery.db.insertRow(
    session,
    PublicationDelivery(
      publicationId: p.id!,
      submissionId: submission?.id,
      webhookId: 'msg_${const Uuid().v4().replaceAll('-', '')}',
      type: body['type'] as String,
      payload: jsonEncode(body),
      sequence: sequence,
      nextAttemptAt: nowUtc(),
      createdAt: nowUtc(),
    ),
    transaction: transaction,
  );

  /// Stores a delivery and schedules sending it right away.
  static Future<PublicationDelivery> send(
    Session session,
    Publication p,
    Map<String, Object?> body, {
    Submission? submission,
  }) async {
    final d = await enqueue(session, p, body, submission: submission);
    await scheduler(session, d.id!);
    return d;
  }

  /// Sends the delivery [id] once if it is due and not held by another
  /// instance; returns whether the blog accepted it.
  static Future<bool> attempt(Session session, int id) async {
    final now = nowUtc();
    final claimed = await PublicationDelivery.db.updateWhere(
      session,
      columnValues: (t) => [t.leaseUntil(now.add(leaseDuration))],
      where: (t) =>
          t.id.equals(id) &
          t.deliveredAt.equals(null) &
          t.failedAt.equals(null) &
          (t.leaseUntil.equals(null) | (t.leaseUntil < now)),
    );
    if (claimed.isEmpty) return false;
    final d = claimed.single;
    final p = await Publication.db.findById(session, d.publicationId);
    if (p == null) return false;
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;
    final secrets = [
      p.signingSecret,
      if (p.previousSigningSecret != null &&
          (p.previousSecretUntil?.isAfter(now) ?? false))
        p.previousSigningSecret!,
    ];
    final result = await PublicationHttp.instance.post(
      p.webhookUrl,
      headers: {
        'webhook-id': d.webhookId,
        'webhook-timestamp': '$timestamp',
        'webhook-signature': PublicationKeys.signatureHeader(
          secrets: secrets,
          webhookId: d.webhookId,
          timestamp: timestamp,
          body: d.payload,
        ),
      },
      body: d.payload,
    );
    final attempts = d.attempts + 1;
    final done = nowUtc();
    if (result.ok) {
      await PublicationDelivery.db.updateRow(
        session,
        d.copyWith(
          attempts: attempts,
          lastStatus: result.status,
          lastError: null,
          deliveredAt: done,
          nextAttemptAt: null,
          leaseUntil: null,
        ),
        columns: _resultColumns,
      );
      await _settled(session, d, delivered: true);
      return true;
    }
    final error = result.error ?? 'HTTP ${result.status}';
    final giveUp = attempts > retryDelays.length;
    await PublicationDelivery.db.updateRow(
      session,
      d.copyWith(
        attempts: attempts,
        lastStatus: result.status,
        lastError: error.length > 500 ? error.substring(0, 500) : error,
        failedAt: giveUp ? done : null,
        nextAttemptAt: giveUp ? null : done.add(retryDelays[attempts - 1]),
        leaseUntil: null,
      ),
      columns: _resultColumns,
    );
    if (giveUp) await _settled(session, d, delivered: false);
    return false;
  }

  static List<Column<Object?>> _resultColumns(PublicationDeliveryTable t) => [
    t.attempts,
    t.lastStatus,
    t.lastError,
    t.deliveredAt,
    t.failedAt,
    t.nextAttemptAt,
    t.leaseUntil,
  ];

  /// After the last attempt of a `submission.submitted`: clears or marks the
  /// submission's delivery state, when it is still the latest submit.
  static Future<void> _settled(
    Session session,
    PublicationDelivery d, {
    required bool delivered,
  }) async {
    if (d.type != 'submission.submitted' ||
        d.submissionId == null ||
        d.sequence == null) {
      return;
    }
    final latest = await SubmissionRevision.db.findFirstRow(
      session,
      where: (t) => t.submissionId.equals(d.submissionId!),
      orderBy: (t) => t.sequence.desc(),
    );
    if (latest?.sequence != d.sequence) return;
    final s = await Submission.db.findById(session, d.submissionId!);
    if (s == null) return;
    if (delivered) {
      await Submission.db.updateRow(
        session,
        s.copyWith(delivery: null, updatedAt: nowUtc()),
        columns: (t) => [t.delivery, t.updatedAt],
      );
    } else {
      final back = s.status == SubmissionStatus.inReview
          ? (s.statusBeforeSubmit ?? SubmissionStatus.draft)
          : s.status;
      await Submission.db.updateRow(
        session,
        s.copyWith(
          delivery: SubmissionDeliveryState.failed,
          status: back,
          updatedAt: nowUtc(),
        ),
        columns: (t) => [t.delivery, t.status, t.updatedAt],
      );
    }
    await SubmissionService.afterDelivery(
      session,
      s.id!,
      delivered: delivered,
      submitterId: latest!.submittedById,
    );
  }

  /// Sends the due deliveries (`wonky.publicationSweep`, every minute).
  static Future<int> sweep(Session session) async {
    final now = nowUtc();
    final due = await PublicationDelivery.db.find(
      session,
      where: (t) =>
          (t.nextAttemptAt <= now) &
          t.deliveredAt.equals(null) &
          t.failedAt.equals(null) &
          (t.leaseUntil.equals(null) | (t.leaseUntil < now)),
      orderBy: (t) => t.nextAttemptAt,
      limit: sweepBatch,
    );
    var sent = 0;
    for (final d in due) {
      final ok = await runGuarded<bool>(
        session,
        'publications.deliver ${d.webhookId}',
        () => attempt(session, d.id!),
      );
      if (ok ?? false) sent++;
    }
    return sent;
  }

  /// Deliveries older than 30 days are deleted (daily).
  static Future<int> purgeOld(Session session) async {
    final removed = await PublicationDelivery.db.deleteWhere(
      session,
      where: (t) =>
          (t.createdAt < nowUtc().subtract(const Duration(days: 30))) &
          t.nextAttemptAt.equals(null),
    );
    return removed.length;
  }
}
