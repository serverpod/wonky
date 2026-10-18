import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart' show GridRect;
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

import '../../platform/common/models.dart';
import '../../platform/config/wonky_config.dart';
import 'script_triggers.dart';

/// Wire form of the events of queued jobs.
abstract final class ScriptJobEvents {
  static String encode(ScriptEvent e) => jsonEncode(switch (e) {
    OpenEventData() => {'type': 'open'},
    EditEventData() => {
      'type': 'edit',
      'sheetId': e.sheetId,
      'range': [e.range.top, e.range.left, e.range.bottom, e.range.right],
      'triggerUid': ?e.triggerUid,
      if (e.offline) 'offline': true,
      if (e.coalesced) 'coalesced': true,
    },
    SelectionChangeEventData() => {
      'type': 'selection',
      'sheetId': e.sheetId,
      'range': [e.range.top, e.range.left, e.range.bottom, e.range.right],
    },
    ChangeEventData() => {'type': 'change', 'changeType': e.changeType},
    UiEventData() => {
      'type': 'ui',
      'panelId': e.panelId,
      'values': e.values,
      'button': e.button,
    },
    TimeEventData() => {
      'type': 'time',
      'triggerUid': e.triggerUid,
      'scheduledAt': e.scheduledAt.toUtc().toIso8601String(),
    },
  });

  static GridRect _rect(Object? r) {
    final l = (r! as List).cast<int>();
    return GridRect(l[0], l[1], l[2], l[3]);
  }

  /// The event of [json]; time events get [firedAt] (default: now).
  static ScriptEvent decode(String json, {DateTime? firedAt}) {
    final m = (jsonDecode(json) as Map).cast<String, Object?>();
    return switch (m['type']) {
      'edit' => EditEventData(
        sheetId: m['sheetId']! as String,
        range: _rect(m['range']),
        triggerUid: m['triggerUid'] as String?,
        offline: m['offline'] == true,
        coalesced: m['coalesced'] == true,
      ),
      'selection' => SelectionChangeEventData(
        sheetId: m['sheetId']! as String,
        range: _rect(m['range']),
      ),
      'change' => ChangeEventData(m['changeType']! as String),
      'ui' => UiEventData(
        panelId: m['panelId']! as String,
        values: (m['values']! as Map).cast<String, Object?>(),
        button: m['button']! as String,
      ),
      'time' => TimeEventData(
        triggerUid: m['triggerUid']! as String,
        scheduledAt: DateTime.parse(m['scheduledAt']! as String),
        firedAt: (firedAt ?? clock.now()).toUtc(),
      ),
      _ => const OpenEventData(),
    };
  }

  /// [a] and [b] merged for a coalesced job: edits on one sheet become
  /// their bounding box; other events keep the newest.
  static String merge(String a, String b) {
    final x = jsonDecode(a) as Map;
    final y = jsonDecode(b) as Map;
    if (x['type'] != 'edit' || y['type'] != 'edit') return b;
    if (x['sheetId'] != y['sheetId']) {
      return jsonEncode({...x, 'coalesced': true});
    }
    final r1 = _rect(x['range']), r2 = _rect(y['range']);
    return jsonEncode({
      ...x,
      'range': [
        math.min(r1.top, r2.top),
        math.min(r1.left, r2.left),
        math.max(r1.bottom, r2.bottom),
        math.max(r1.right, r2.right),
      ],
      if (x['offline'] == true || y['offline'] == true) 'offline': true,
      'coalesced': true,
    });
  }
}

/// The server script job queue (Sheets 09 §8.5, §8.7.3): installable
/// triggers are enqueued as [ScriptJob] rows and run by instances with the
/// worker role (`sheets.scriptWorker`). Claims use leases (`FOR UPDATE
/// SKIP LOCKED`), so several instances can work the queue; a job whose
/// lease expired (crashed instance) is retried up to [maxAttempts] times.
/// Limits: [perTriggerCap] queued jobs per trigger (the overflow is
/// coalesced into the newest queued job), one running job per trigger and
/// `scriptUserConcurrency` running jobs per run-as user.
abstract final class ScriptJobQueue {
  /// Queued jobs per trigger before new events are coalesced.
  static const perTriggerCap = 100;

  /// Runs of a job before it fails for good (lease expiries).
  static const maxAttempts = 3;

  /// Finished jobs are kept this long (debugging), then pruned.
  static const retention = Duration(days: 1);

  /// This instance (lease owner).
  static final String instanceId =
      '${Platform.localHostname}:$pid:${math.Random().nextInt(1 << 32)}';

  /// Whether this instance runs jobs.
  static bool get isWorker => WonkyConfig.current.scriptWorker;

  /// Runs jobs right after enqueueing on the same session (tests), instead
  /// of in the background ([ScriptTriggerService.runInline]).
  static bool get runInline => ScriptTriggerService.runInline;

  static bool _pumping = false;

  /// Enqueues a run of [trigger] (`runAsUserId` resolved from its
  /// installer) unless the trigger already has [perTriggerCap] queued jobs:
  /// then the event is merged into the newest one (`e.coalesced`).
  static Future<ScriptJob> enqueue(
    Session session, {
    required DriveItem item,
    required ScriptTrigger trigger,
    required ScriptExecutionKind kind,
    required ScriptEvent event,
  }) async {
    final payload = ScriptJobEvents.encode(event);
    final queued = await ScriptJob.db.count(
      session,
      where: (j) =>
          j.triggerId.equals(trigger.id) &
          j.status.equals(ScriptExecutionStatus.queued),
    );
    if (queued >= perTriggerCap) {
      final newest = await ScriptJob.db.findFirstRow(
        session,
        where: (j) =>
            j.triggerId.equals(trigger.id) &
            j.status.equals(ScriptExecutionStatus.queued),
        orderBy: (j) => j.enqueuedAt.desc(),
      );
      if (newest != null) {
        return ScriptJob.db.updateRow(
          session,
          newest.copyWith(
            payloadJson: ScriptJobEvents.merge(newest.payloadJson, payload),
            coalesced: newest.coalesced + 1,
          ),
        );
      }
    }
    final profile = await UserProfile.db.findFirstRow(
      session,
      where: (p) => p.authUserId.equals(trigger.runAsUserId),
    );
    return ScriptJob.db.insertRow(
      session,
      ScriptJob(
        kind: kind,
        spreadsheetUuid: item.contentRef!,
        itemUuid: item.uuid,
        triggerId: trigger.id,
        runAsUserId: profile?.id ?? 0,
        functionName: trigger.functionName,
        payloadJson: payload,
        status: ScriptExecutionStatus.queued,
        enqueuedAt: clock.now().toUtc(),
      ),
    );
  }

  /// After enqueueing: runs the queue now on a worker (inline in tests,
  /// otherwise in the background on a new session). Returns the jobs run
  /// inline.
  static Future<int> kick(Session session) async {
    if (runInline) return pump(session);
    if (!isWorker || _pumping) return 0;
    unawaited(() async {
      final s = await session.serverpod.createSession(enableLogging: false);
      try {
        await pump(s);
      } on Object catch (e, st) {
        s.log('Script jobs failed: $e', level: LogLevel.error, stackTrace: st);
      } finally {
        await s.close();
      }
    }());
    return 0;
  }

  /// Claims and runs queued jobs until none can run or [max] ran; up to
  /// `scriptPoolSize` at once. Returns the jobs run.
  static Future<int> pump(Session session, {int max = 200}) async {
    if (!runInline && !isWorker) return 0;
    if (_pumping && !runInline) return 0;
    _pumping = true;
    try {
      await recoverStale(session);
      var ran = 0;
      final workers = runInline
          ? 1
          : math.max(1, WonkyConfig.current.scriptPoolSize);
      Future<void> loop() async {
        while (ran < max) {
          final job = await _claim(session);
          if (job == null) return;
          ran++;
          await _run(session, job);
        }
      }

      await Future.wait([for (var i = 0; i < workers; i++) loop()]);
      return ran;
    } finally {
      _pumping = false;
    }
  }

  /// The lease outlasts the longest possible run (the script timeout plus
  /// 2 minutes), so a running job needs no heartbeat (CQ-9).
  static Duration get _lease => Duration(
    milliseconds: WonkyConfig.current.scriptServerTimeoutMs + 120000,
  );

  /// Claims the oldest runnable queued job. Claims are serialized across
  /// instances by a transaction-scoped advisory lock, so the per-user and
  /// per-trigger limits (subqueries the claim doesn't lock) hold (CQ-9).
  static Future<ScriptJob?> _claim(Session session) async {
    final id = await session.db.transaction((tx) async {
      await session.db.unsafeExecute(
        "SELECT pg_advisory_xact_lock(hashtext('script_job_claim'))",
        transaction: tx,
      );
      final rows = await _claimIn(session, tx);
      return rows.isEmpty ? null : rows.first[0]! as int;
    });
    if (id == null) return null;
    return ScriptJob.db.findById(session, id);
  }

  static Future<DatabaseResult> _claimIn(
    Session session,
    Transaction tx,
  ) async {
    return session.db.unsafeQuery(
      r'''
      UPDATE script_job SET status = 'running', "leaseOwner" = @owner,
        "leaseUntil" = @until, attempts = attempts + 1
      WHERE id = (
        SELECT j.id FROM script_job j
        WHERE j.status = 'queued'
          AND (SELECT count(*) FROM script_job r
               WHERE r.status = 'running'
                 AND r."runAsUserId" = j."runAsUserId") < @perUser
          AND (j."triggerId" IS NULL OR NOT EXISTS (
               SELECT 1 FROM script_job r
               WHERE r.status = 'running' AND r."triggerId" = j."triggerId"))
        ORDER BY j."enqueuedAt", j.id
        FOR UPDATE SKIP LOCKED
        LIMIT 1)
      RETURNING id
      ''',
      parameters: QueryParameters.named({
        'owner': instanceId,
        'until': clock.now().toUtc().add(_lease),
        'perUser': WonkyConfig.current.scriptUserConcurrency,
      }),
      transaction: tx,
    );
  }

  static Future<void> _run(Session session, ScriptJob job) async {
    var status = ScriptExecutionStatus.skipped;
    String? result;
    try {
      final item = await DriveItem.db.findFirstRow(
        session,
        where: (i) => i.uuid.equals(job.itemUuid),
      );
      final trigger = job.triggerId == null
          ? null
          : await ScriptTrigger.db.findById(
              session,
              job.triggerId!,
            );
      if (item != null && trigger != null && item.trashedAt == null) {
        final r = await ScriptTriggerService.runTrigger(
          session,
          item,
          trigger,
          job.kind,
          ScriptJobEvents.decode(job.payloadJson),
        );
        if (r != null) {
          status = r.status == ScriptExecutionStatus.completed
              ? ScriptExecutionStatus.completed
              : ScriptExecutionStatus.failed;
          result = jsonEncode({
            'executionId': r.executionId.uuid,
            'status': r.status.name,
          });
        }
      }
    } on Object catch (e, st) {
      status = ScriptExecutionStatus.failed;
      result = jsonEncode({'error': '$e'});
      session.log(
        'Script job ${job.id} failed: $e',
        level: LogLevel.warning,
        stackTrace: st,
      );
    }
    // Only while this instance still holds the lease (CQ-9): a job whose
    // lease expired was re-queued by `recoverStale` and belongs to its new
    // runner.
    await ScriptJob.db.updateWhere(
      session,
      columnValues: (t) => [
        t.status(status),
        t.resultJson(result),
        t.finishedAt(clock.now().toUtc()),
        t.leaseOwner(null),
        t.leaseUntil(null),
      ],
      where: (t) =>
          t.id.equals(job.id!) &
          t.status.equals(ScriptExecutionStatus.running) &
          t.leaseOwner.equals(job.leaseOwner),
    );
  }

  /// Jobs whose lease expired (their instance died): queued again, or
  /// failed after [maxAttempts].
  static Future<int> recoverStale(Session session) async {
    final stale = await ScriptJob.db.find(
      session,
      where: (j) =>
          j.status.equals(ScriptExecutionStatus.running) &
          (j.leaseUntil < clock.now().toUtc()),
    );
    var recovered = 0;
    for (final j in stale) {
      final failed = j.attempts >= maxAttempts;
      // Conditional on the lease still being the expired one (CQ-9): two
      // sweeping instances, or a runner finishing late, never overwrite
      // each other.
      final rows = await ScriptJob.db.updateWhere(
        session,
        columnValues: (t) => [
          if (failed) ...[
            t.status(ScriptExecutionStatus.failed),
            t.finishedAt(clock.now().toUtc()),
            t.resultJson(jsonEncode({'error': 'lease expired'})),
          ] else
            t.status(ScriptExecutionStatus.queued),
          t.leaseOwner(null),
          t.leaseUntil(null),
        ],
        where: (t) =>
            t.id.equals(j.id!) &
            t.status.equals(ScriptExecutionStatus.running) &
            t.leaseOwner.equals(j.leaseOwner) &
            t.leaseUntil.equals(j.leaseUntil),
      );
      recovered += rows.length;
    }
    return recovered;
  }

  /// Drops finished jobs older than [retention].
  static Future<int> prune(Session session) async {
    final cutoff = clock.now().toUtc().subtract(retention);
    final done = await ScriptJob.db.deleteWhere(
      session,
      where: (j) =>
          j.status.notInSet({
            ScriptExecutionStatus.queued,
            ScriptExecutionStatus.running,
          }) &
          (j.finishedAt < cutoff),
    );
    return done.length;
  }
}
