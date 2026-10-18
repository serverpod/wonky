import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_revlog/rows.dart';

import '../../platform/cluster/cluster_bus.dart';
import '../../platform/common/models.dart';
import '../../platform/presence/presence_service.dart';

/// A soft-lock claim on one text body (Slides 02 §4.4, 09 §2.1): the
/// `editing` field of a participant's presence cursor.
class DeckTextClaim {
  DeckTextClaim({
    required this.sessionId,
    required this.userUuid,
    required this.displayName,
    required this.kind,
    required this.table,
    required this.rowId,
    required this.column,
    this.slideId,
    this.elementId,
  });

  final String sessionId;
  final UuidValue userUuid;
  final String displayName;

  /// `text`, `notes`, `tableCell`, `code`, `codeState`, `groupTitle`.
  final String kind;

  /// The claimed body: table, row and text column.
  final String table;
  final String rowId;
  final String column;

  final String? slideId;
  final String? elementId;

  /// MCP `being_edited` target (11 §2.1).
  Map<String, Object?> toJson() => {
    'kind': kind,
    'table': table,
    'row_id': rowId,
    'slide_id': ?slideId,
    'element_id': ?elementId,
    'user': displayName,
    'user_uuid': userUuid.uuid,
  };

  /// The claim in a Slides presence cursor (09 §1.1), or null.
  static DeckTextClaim? fromCursor(Participant p, String? cursorJson) {
    if (cursorJson == null || !cursorJson.contains('editing')) return null;
    final Object? cursor;
    try {
      cursor = jsonDecode(cursorJson);
    } on FormatException {
      return null;
    }
    if (cursor is! Map) return null;
    final e = cursor['editing'];
    if (e is! Map) return null;
    String? s(String k) =>
        e[k] is String ? (e[k] as String).toLowerCase() : null;
    final kind = e['kind'];
    final (String, String?, String)? body = switch (kind) {
      'text' => (SlidesTables.slideElement, s('elementId'), SlidesCols.text),
      'notes' => (SlidesTables.slide, s('slideId'), SlideCols.notes),
      'tableCell' => (
        SlidesTables.slideTableCell,
        s('cellId'),
        SlidesCols.text,
      ),
      'code' || 'codeState' => (
        SlidesTables.codeState,
        s('stateId'),
        CodeStateCols.code,
      ),
      'groupTitle' => (
        SlidesTables.slideGroup,
        s('groupId') ?? s('elementId'),
        SlidesCols.title,
      ),
      _ => null,
    };
    if (body == null || body.$2 == null) return null;
    return DeckTextClaim(
      sessionId: p.sessionId,
      userUuid: p.userUuid,
      displayName: p.displayName,
      kind: kind as String,
      table: body.$1,
      rowId: body.$2!,
      column: body.$3,
      slideId: s('slideId'),
      elementId: s('elementId'),
    );
  }
}

/// Text claims of the people editing a deck, for the headless soft-lock
/// check (Slides 11 §2.1: a write touching a body claimed by another user
/// fails with `being_edited` unless forced). Watches the presence channel
/// of the deck item (`presence:<item>`, global across instances); the
/// first watch asks the present sessions with a `probe` (they answer
/// `here` with their participant and cursor) and waits [probeWait].
/// Watches end after [idleTimeout] without use.
abstract final class DeckTextClaims {
  /// How long the first watch waits for `here` answers.
  static Duration probeWait = const Duration(milliseconds: 250);

  /// Watches unused this long are removed.
  static Duration idleTimeout = const Duration(minutes: 15);

  static final Map<String, _Watch> _watches = {};
  static Session? _session;

  /// Starts (or refreshes) watching [itemUuid]'s presence.
  static Future<void> watch(Session session, UuidValue itemUuid) async {
    _evictIdle();
    final key = itemUuid.uuid;
    final existing = _watches[key];
    if (existing != null) {
      existing.lastUsed = clock.now();
      await existing.ready;
      return;
    }
    final s = _session ??= await session.serverpod.createSession(
      enableLogging: false,
    );
    final w = _Watch(itemUuid);
    _watches[key] = w;
    s.messages.addListener(PresenceService.channel(itemUuid), w.onBus);
    try {
      await ClusterBus.post(
        session,
        PresenceService.channel(itemUuid),
        PresenceBusMessage(type: 'probe', sessionId: w.probeId),
      );
      await Future<void>.delayed(probeWait);
    } on Exception catch (e) {
      session.log('Presence probe failed: $e', level: LogLevel.warning);
    }
    w.done.complete();
  }

  /// The current claims on [itemUuid] (empty when not watched).
  static List<DeckTextClaim> claims(UuidValue itemUuid) =>
      _watches[itemUuid.uuid]?.claims.values.toList() ?? const [];

  /// The claims of users other than [actingUser] on bodies that
  /// [changes] write.
  static List<DeckTextClaim> conflicts(
    UuidValue itemUuid,
    Iterable<RowChange> changes, {
    required UuidValue actingUser,
  }) {
    final claims = [
      for (final c in DeckTextClaims.claims(itemUuid))
        if (c.userUuid != actingUser) c,
    ];
    if (claims.isEmpty) return const [];
    final byBody = <String, List<DeckTextClaim>>{};
    for (final c in claims) {
      byBody.putIfAbsent('${c.table}:${c.rowId}', () => []).add(c);
    }
    final out = <DeckTextClaim>[];
    for (final ch in changes) {
      final hit = byBody.remove('${ch.table}:${ch.rowId}');
      if (hit == null) continue;
      for (final c in hit) {
        final touches =
            ch.op == RowOp.delete ||
            ch.columnsAfter.containsKey(c.column) ||
            ch.columnsBefore.containsKey(c.column);
        if (touches) out.add(c);
      }
    }
    return out;
  }

  /// Stops every watch (tests).
  static void clear() {
    for (final k in _watches.keys.toList()) {
      _stop(k);
    }
  }

  static void _evictIdle() {
    final now = clock.now();
    for (final e in _watches.entries.toList()) {
      if (now.difference(e.value.lastUsed) > idleTimeout) _stop(e.key);
    }
  }

  static void _stop(String key) {
    final w = _watches.remove(key);
    if (w == null) return;
    _session?.messages.removeListener(
      PresenceService.channel(w.itemUuid),
      w.onBus,
    );
  }
}

class _Watch {
  _Watch(this.itemUuid);

  final UuidValue itemUuid;
  final String probeId = 'probe-${const Uuid().v4()}';
  final Completer<void> done = Completer<void>();
  Future<void> get ready => done.future;
  DateTime lastUsed = clock.now();

  /// Participants by session id with their latest cursor.
  final Map<String, (Participant, String?)> roster = {};

  /// Claims by session id.
  final Map<String, DeckTextClaim> claims = {};

  void _set(String sessionId, Participant p, String? cursorJson) {
    roster[sessionId] = (p, cursorJson);
    final claim = DeckTextClaim.fromCursor(p, cursorJson);
    if (claim == null) {
      claims.remove(sessionId);
    } else {
      claims[sessionId] = claim;
    }
  }

  void onBus(SerializableModel model) {
    if (model is! PresenceBusMessage) return;
    final m = model;
    switch (m.type) {
      case 'hello' || 'here' || 'beat':
        final p = m.participant;
        if (p == null) return;
        _set(m.sessionId, p, p.cursorJson);
      case 'update':
        final known = roster[m.sessionId];
        if (known == null) return;
        _set(m.sessionId, known.$1, m.cursorJson);
      case 'bye':
        roster.remove(m.sessionId);
        claims.remove(m.sessionId);
    }
  }
}
