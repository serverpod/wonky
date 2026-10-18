import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput, TriggerKind;
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/notifications/notification_service.dart';
import '../../platform/sharing/access_service.dart';
import '../headless/headless_workbook_provider.dart';
import 'script_jobs.dart';
import 'script_service.dart';

/// Next run times of time-driven triggers (09 §6.11, §8.7.3).
///
/// Schedules come from `TimeTriggerBuilder`: `{type: minutes|hours|days|
/// weeks|monthly|once, interval, atHour, weekday, monthDay, at}`. Times of
/// day are in the spreadsheet time zone; `atHour` gets a deterministic
/// ±15 minute jitter per trigger.
abstract final class ScriptSchedule {
  /// Allowed `everyMinutes` intervals.
  static const minuteIntervals = {1, 5, 10, 15, 30};

  /// Allowed `everyHours` intervals.
  static const hourIntervals = {1, 2, 4, 6, 8, 12};

  /// The next run after [after] (null = never again).
  static DateTime? next(
    Map<String, Object?> schedule,
    DateTime after, {
    required String timeZone,
    required String triggerId,
    TimeZoneResolver timeZones = const TzDatabaseResolver(),
    DateTime? lastRun,
  }) {
    final type = schedule['type'];
    final interval = (schedule['interval'] as num?)?.toInt() ?? 1;
    final utc = after.toUtc();
    switch (type) {
      case 'minutes':
        final n = minuteIntervals.contains(interval) ? interval : 1;
        final base = DateTime.utc(
          utc.year,
          utc.month,
          utc.day,
          utc.hour,
          utc.minute,
        );
        return base.add(Duration(minutes: n - base.minute % n));
      case 'hours':
        final n = hourIntervals.contains(interval) ? interval : 1;
        final base = DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
        return base.add(Duration(hours: n - base.hour % n));
      case 'once':
        final at = DateTime.tryParse('${schedule['at']}')?.toUtc();
        if (at == null || lastRun != null) return null;
        return at.isAfter(utc) ? at : utc;
      case 'days' || 'weeks' || 'monthly':
        final hour = (schedule['atHour'] as num?)?.toInt() ?? 0;
        final jitter = _jitter(triggerId);
        final offset = timeZones.offsetAt(timeZone, utc);
        final local = utc.add(offset);
        var day = DateTime.utc(local.year, local.month, local.day);
        DateTime candidateFor(DateTime d) {
          final wall = d.add(Duration(hours: hour)).add(jitter);
          final o = timeZones.offsetAt(timeZone, wall.subtract(offset));
          return wall.subtract(o);
        }

        bool matches(DateTime d) {
          if (type == 'weeks') {
            return d.weekday == ((schedule['weekday'] as num?)?.toInt() ?? 1);
          }
          if (type == 'monthly') {
            final md = (schedule['monthDay'] as num?)?.toInt() ?? 1;
            final last = DateTime.utc(d.year, d.month + 1, 0).day;
            return d.day == (md > last ? last : md);
          }
          return true;
        }

        final minGap = switch (type) {
          'days' => Duration(days: interval - 1),
          'weeks' => Duration(days: 7 * (interval - 1)),
          _ => Duration.zero,
        };
        final earliest = lastRun == null ? utc : lastRun.toUtc().add(minGap);
        for (var i = 0; i < 400 * interval; i++) {
          final c = candidateFor(day);
          if (matches(day) && c.isAfter(utc) && !c.isBefore(earliest)) {
            return c;
          }
          day = day.add(const Duration(days: 1));
        }
        return null;
      default:
        return null;
    }
  }

  static Duration _jitter(String id) {
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return Duration(minutes: h % 31 - 15);
  }
}

/// Installable triggers on the server (09 §8.7.3): the time-driven
/// scheduler (FutureCall `wonky.scriptsTick`, every minute) and installable
/// `onEdit`/`onChange`/`onOpen` fired from change-log processing.
abstract final class ScriptTriggerService {
  /// Consecutive failures before a trigger is disabled.
  static const maxFailures = 5;

  /// A run still marked running after this is considered dead.
  static const staleRun = Duration(minutes: 10);

  /// Runs change-triggered executions inline (tests) instead of in the
  /// background.
  static bool runInline = false;

  /// Scheduler tick: syncs trigger states with the synced `ScriptTrigger`
  /// rows and runs the due time-driven triggers. Returns the runs.
  static Future<int> tick(Session session) async {
    if (!_enabled) return 0;
    final now = clock.now().toUtc();
    final db = session;
    final triggers = await ScriptTrigger.db.find(
      db,
      where: (t) => t.kind.equals(TriggerKind.timeDriven),
    );
    final projectIds = {for (final t in triggers) t.projectId};
    final projects = projectIds.isEmpty
        ? <ScriptProject>[]
        : await ScriptProject.db.find(
            db,
            where: (t) => t.id.inSet(projectIds),
          );
    final spaceOf = {
      for (final p in projects) p.id: p.spreadsheetId,
    };
    final states = {
      for (final s in await ScriptTriggerState.db.find(session))
        s.triggerId.uuid: s,
    };
    final live = <String>{};
    final due = <(ScriptTrigger, ScriptTriggerState)>[];
    for (final t in triggers) {
      final space = spaceOf[t.projectId];
      if (space == null) continue;
      live.add(t.id.uuid);
      var state = states[t.id.uuid];
      if (!t.enabled) {
        if (state != null && state.nextRunAt != null) {
          await ScriptTriggerState.db.updateRow(
            session,
            state.copyWith(nextRunAt: null),
          );
        }
        continue;
      }
      if (state == null || state.scheduleJson != t.scheduleJson) {
        final next = await _next(session, t, space, now, state?.lastRunAt);
        if (state == null) {
          state = await ScriptTriggerState.db.insertRow(
            session,
            ScriptTriggerState(
              triggerId: t.id,
              spreadsheetUuid: space,
              scheduleJson: t.scheduleJson,
              nextRunAt: next,
            ),
          );
        } else {
          state = await ScriptTriggerState.db.updateRow(
            session,
            state.copyWith(scheduleJson: t.scheduleJson, nextRunAt: next),
          );
        }
      }
      final next = state.nextRunAt;
      final running = state.runningSince;
      if (state.disabledReason == null &&
          next != null &&
          !next.isAfter(now) &&
          (running == null || now.difference(running) > staleRun)) {
        due.add((t, state));
      }
    }
    for (final s in states.values) {
      if (!live.contains(s.triggerId.uuid) && s.nextRunAt != null) {
        await ScriptTriggerState.db.updateRow(
          session,
          s.copyWith(nextRunAt: null),
        );
      }
    }
    var enqueued = 0;
    for (final (t, state) in due) {
      final item = await DriveItem.db.findFirstRow(
        session,
        where: (i) => i.contentRef.equals(state.spreadsheetUuid),
      );
      if (item == null) continue;
      await ScriptTriggerState.db.updateRow(
        session,
        state.copyWith(runningSince: now),
      );
      await ScriptJobQueue.enqueue(
        session,
        item: item,
        trigger: t,
        kind: ScriptExecutionKind.timeDriven,
        event: TimeEventData(
          triggerUid: t.id.uuid,
          scheduledAt: state.nextRunAt!,
          firedAt: now,
        ),
      );
      enqueued++;
    }
    // Leftovers of other instances (no worker role) run here too.
    final ran = await ScriptJobQueue.kick(session);
    return runInline ? ran : enqueued;
  }

  /// Whether scripts are enabled on this server.
  static bool get enabled => _enabled;

  static bool get _enabled {
    try {
      ScriptService.requireEnabled();
      return true;
    } on Exception {
      return false;
    }
  }

  static Future<DateTime?> _next(
    Session session,
    ScriptTrigger t,
    UuidValue space,
    DateTime after,
    DateTime? lastRun,
  ) async {
    final schedule = t.scheduleJson == null
        ? const <String, Object?>{}
        : (jsonDecode(t.scheduleJson!) as Map).cast<String, Object?>();
    final spreadsheet = await Spreadsheet.db.findById(
      session,
      space,
    );
    return ScriptSchedule.next(
      schedule,
      after,
      timeZone: spreadsheet?.timeZone ?? 'UTC',
      triggerId: t.id.uuid,
      lastRun: lastRun,
    );
  }

  /// Runs trigger [t] as its installer after the run-as checks (09
  /// §8.7.3); records the state. Returns null when the trigger was skipped
  /// or disabled.
  static Future<ScriptRunResponse?> runTrigger(
    Session session,
    DriveItem item,
    ScriptTrigger t,
    ScriptExecutionKind kind,
    ScriptEvent event,
  ) async {
    final space = item.contentRef!;
    var state = await ScriptTriggerState.db.findFirstRow(
      session,
      where: (s) => s.triggerId.equals(t.id),
    );
    state ??= await ScriptTriggerState.db.insertRow(
      session,
      ScriptTriggerState(
        triggerId: t.id,
        spreadsheetUuid: space,
        scheduleJson: t.scheduleJson,
      ),
    );
    if (state.disabledReason != null || !t.enabled) return null;
    final profile = await UserProfile.db.findFirstRow(
      session,
      where: (p) => p.authUserId.equals(t.runAsUserId),
    );
    final role = profile == null
        ? null
        : await AccessService.effectiveRole(session, profile.id!, item);
    if (profile == null || role == null || role < Role.editor) {
      final reason =
          'Trigger ${t.functionName} was disabled because its installer '
          'no longer has edit access to ${item.name}.';
      await ScriptTriggerState.db.updateRow(
        session,
        state.copyWith(
          disabledReason: reason,
          nextRunAt: null,
          runningSince: null,
        ),
      );
      session.log(
        'Script trigger ${t.id} disabled: installer lost edit access.',
        level: LogLevel.warning,
      );
      if (profile != null) {
        await _notifyFailure(session, profile.id!, item, t, reason);
      }
      return null;
    }
    // Settings › Sheets › Enable scripts off: the installer's triggers
    // pause (09 §11.3) without counting as failures.
    if (!await _scriptsEnabled(session, profile.id!)) {
      await ScriptTriggerState.db.updateRow(
        session,
        state.copyWith(
          runningSince: null,
          nextRunAt: kind == ScriptExecutionKind.timeDriven
              ? await _next(
                  session,
                  t,
                  space,
                  clock.now().toUtc(),
                  state.lastRunAt,
                )
              : state.nextRunAt,
        ),
      );
      return null;
    }
    final actor = Actor(
      userId: profile.id!,
      authUserId: profile.authUserId,
      kind: ActorKind.script,
    );
    ScriptRunResponse? response;
    var failed = false;
    try {
      response = await ScriptService.run(
        session,
        actor,
        item.uuid,
        t.functionName,
        kind: kind,
        event: event,
        triggerId: t.id,
      );
      failed = response.status != ScriptExecutionStatus.completed;
    } on Object catch (e) {
      session.log('Script trigger ${t.id} failed: $e', level: LogLevel.warning);
      failed = true;
    }
    final now = clock.now().toUtc();
    final failures = failed ? state.consecutiveFailures + 1 : 0;
    final next = kind == ScriptExecutionKind.timeDriven
        ? await _next(session, t, space, now, now)
        : state.nextRunAt;
    final disabled = failures >= maxFailures
        ? 'Trigger ${t.functionName} was disabled after $maxFailures '
              'failures in a row.'
        : null;
    // Failure notifications (09 §8.7.3): per the trigger's `notify`
    // option (immediately, daily = at most one a day, never); disabling
    // always notifies.
    var notifiedAt = state.lastNotifiedAt;
    if (failed) {
      final mode = _notifyMode(t);
      final last = state.lastNotifiedAt;
      final due =
          disabled != null ||
          mode == 'immediately' ||
          (mode == 'daily' &&
              (last == null ||
                  now.difference(last) >= const Duration(hours: 24)));
      if (due) {
        final message =
            disabled ??
            'Trigger ${t.functionName} failed: '
                '${_errorMessage(response) ?? response?.status.name ?? 'error'}';
        await _notifyFailure(
          session,
          profile.id!,
          item,
          t,
          message,
          executionId: response?.executionId,
        );
        notifiedAt = now;
      }
    }
    await ScriptTriggerState.db.updateRow(
      session,
      state.copyWith(
        lastRunAt: now,
        lastStatus: response?.status ?? ScriptExecutionStatus.failed,
        consecutiveFailures: failures,
        runningSince: null,
        nextRunAt: disabled != null ? null : next,
        disabledReason: disabled,
        lastNotifiedAt: notifiedAt,
      ),
    );
    return response;
  }

  static String _notifyMode(ScriptTrigger t) {
    if (t.optionsJson == null) return 'daily';
    try {
      final v = (jsonDecode(t.optionsJson!) as Map)['notify'];
      return v is String ? v : 'daily';
    } on FormatException {
      return 'daily';
    }
  }

  static String? _errorMessage(ScriptRunResponse? r) {
    final e = r?.errorJson;
    if (e == null) return null;
    try {
      return (jsonDecode(e) as Map)['message'] as String?;
    } on FormatException {
      return null;
    }
  }

  static Future<void> _notifyFailure(
    Session session,
    int userId,
    DriveItem item,
    ScriptTrigger t,
    String message, {
    UuidValue? executionId,
  }) async {
    try {
      await NotificationService.notify(
        session,
        userId: userId,
        kind: NotificationKind.scriptFailure,
        item: item,
        payload: {
          'message': message,
          'function': t.functionName,
          'triggerId': t.id.uuid,
          'executionId': ?executionId?.uuid,
        },
      );
    } on Object catch (e) {
      session.log(
        'Script failure notification failed: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Settings › Sheets › *Enable scripts* of the user [userId].
  static Future<bool> _scriptsEnabled(Session session, int userId) async {
    final prefs = await UserPreferences.db.findFirstRow(
      session,
      where: (p) => p.userId.equals(userId),
    );
    final raw = prefs?.sheetsDefaults;
    if (raw == null || raw.isEmpty) return true;
    try {
      final m = jsonDecode(raw);
      return m is! Map || m['scriptsEnabled'] != false;
    } on FormatException {
      return true;
    }
  }

  /// Installable triggers of [kind] (`onEdit`, `onChange`,
  /// `installableOnOpen`) of the spreadsheet [item].
  static Future<List<ScriptTrigger>> triggersOf(
    Session session,
    DriveItem item,
    TriggerKind kind,
  ) async {
    final p = await ScriptService.project(session, item.contentRef!);
    if (p == null) return const [];
    return ScriptTrigger.db.find(
      session,
      where: (t) =>
          t.projectId.equals(p.id) &
          t.kind.equals(kind) &
          t.enabled.equals(true),
    );
  }

  /// `ScriptEndpoint.notifyOpen`: runs installable onOpen triggers.
  static Future<int> fireOpen(Session session, DriveItem item) async {
    var n = 0;
    for (final t in await triggersOf(
      session,
      item,
      TriggerKind.installableOnOpen,
    )) {
      await ScriptJobQueue.enqueue(
        session,
        item: item,
        trigger: t,
        kind: ScriptExecutionKind.installableOnOpen,
        event: const OpenEventData(),
      );
      n++;
    }
    if (n == 0) return 0;
    final ran = await ScriptJobQueue.kick(session);
    return runInline ? ran : n;
  }

  static bool _fireFor(ScriptTrigger t, ActorKind actor) {
    if (actor == ActorKind.user || actor == ActorKind.ai) return true;
    if (actor != ActorKind.mcp || t.optionsJson == null) return false;
    try {
      return (jsonDecode(t.optionsJson!) as Map)['fireForMcp'] == true;
    } on FormatException {
      return false;
    }
  }

  /// Fires installable `onEdit`/`onChange` triggers for a committed op
  /// (RevLog `scripts` hook): its summary, actor kind and whether it was
  /// made offline.
  static Future<int> fireForChange(
    Session session,
    DriveItem item, {
    required String summaryJson,
    required ActorKind actorKind,
    required bool offline,
  }) async {
    final summary = ChangeSummary.parse(summaryJson);
    var n = 0;
    final edits = summary.kinds.contains(ChangeKinds.values)
        ? await triggersOf(session, item, TriggerKind.onEdit)
        : const <ScriptTrigger>[];
    final changes = summary.kinds.isEmpty
        ? const <ScriptTrigger>[]
        : await triggersOf(session, item, TriggerKind.onChange);
    if (edits.isEmpty && changes.isEmpty) return 0;
    ScriptEvent? editEvent;
    if (edits.isNotEmpty) {
      final model = (await HeadlessWorkbookProvider.open(
        session,
        item.contentRef!,
      )).model;
      for (final json in summary.ranges) {
        final r = model.resolve(
          GridRange.tryParse(json) ?? const GridRange.sheet(''),
        );
        if (r == null) continue;
        editEvent = EditEventData(
          sheetId: r.sheetId,
          range: r.rect,
          offline: offline,
        );
        break;
      }
    }
    for (final t in edits) {
      if (editEvent == null || !_fireFor(t, actorKind)) continue;
      await ScriptJobQueue.enqueue(
        session,
        item: item,
        trigger: t,
        kind: ScriptExecutionKind.installableOnEdit,
        event: EditEventData(
          sheetId: (editEvent as EditEventData).sheetId,
          range: editEvent.range,
          triggerUid: t.id.uuid,
          offline: editEvent.offline,
        ),
      );
      n++;
    }
    final changeType = summary.kinds.contains(ChangeKinds.structure)
        ? 'OTHER'
        : summary.kinds.contains(ChangeKinds.sheets)
        ? 'INSERT_GRID'
        : summary.kinds.contains(ChangeKinds.format)
        ? 'FORMAT'
        : summary.kinds.contains(ChangeKinds.values)
        ? 'EDIT'
        : 'OTHER';
    for (final t in changes) {
      if (!_fireFor(t, actorKind)) continue;
      await ScriptJobQueue.enqueue(
        session,
        item: item,
        trigger: t,
        kind: ScriptExecutionKind.installableOnChange,
        event: ChangeEventData(changeType),
      );
      n++;
    }
    if (n == 0) return 0;
    final ran = await ScriptJobQueue.kick(session);
    return runInline ? ran : n;
  }
}
