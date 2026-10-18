import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show ActorKind, Participant;
import 'package:wonky_sheets_core/model.dart' hide ActorKind;

import '../collab/sheets_collab.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import '../revlog/logged_workbook_session.dart';
import 'agent_highlight_layer.dart';

/// A committed op as the agent highlight sees it (RevLog `RevOpMeta`).
@immutable
class AgentWrite {
  const AgentWrite({
    required this.id,
    required this.at,
    required this.sessionId,
    required this.userUuid,
    required this.actorKind,
    required this.summaryJson,
  });

  /// Unique per op (the revision).
  final String id;
  final DateTime at;
  final String sessionId;
  final String userUuid;
  final ActorKind actorKind;
  final String summaryJson;
}

/// Reads the ops of the open spreadsheet committed at or after [since]
/// (newest last is not required).
typedef AgentChangeLogSource =
    Future<List<AgentWrite>> Function(DateTime since);

/// The agent presence highlight of headless writes (Sheets 12 §1.4): when
/// remote changes arrive, the synced `ChangeLog` rows of server-side tool
/// writes (`actorKind` `mcp`, or `ai` of other users; `sessionId`
/// `server:*`) are read and their ranges flashed with the agent's name
/// ("Claude Code (MCP)" from the agent participant in presence, else
/// "Bo's agent"). The assistant runs of this user are flashed by their tool
/// chips instead.
class ExternalAgentWrites {
  ExternalAgentWrites(
    this.editor,
    this.highlights, {
    AgentChangeLogSource? source,
    required this.labels,
  }) : source = source ?? _syncedSource(editor) {
    if (this.source == null) return;
    _since = clock.now().subtract(const Duration(seconds: 10));
    _sub = editor.session.remoteBatches.listen((_) => _schedule());
  }

  final SheetEditorController editor;
  final AgentHighlightLayer highlights;
  final AgentChangeLogSource? source;

  /// Tag texts: `mcp` (agent name unknown), `of(name)` and `aiOf(name)`.
  final AgentLabels labels;

  /// Rows older than this are not flashed (offline writes synced late).
  static const maxAge = Duration(minutes: 2);

  /// Remote batches arrive in bursts (chunks): read the log once after.
  static const debounce = Duration(milliseconds: 400);

  StreamSubscription<Object?>? _sub;
  Timer? _timer;
  late DateTime _since;
  final Set<String> _seen = {};
  bool _disposed = false;
  Future<void>? _running;

  static AgentChangeLogSource? _syncedSource(SheetEditorController editor) {
    final session = editor.session;
    if (session is! LoggedWorkbookSession) return null;
    return (since) async => [
      for (final m in await session.recentOps(
        clock.now().difference(since) + const Duration(seconds: 1),
      ))
        if (!m.committedAt.isBefore(since))
          AgentWrite(
            id: '${m.revision}',
            at: m.committedAt,
            sessionId: m.sessionId ?? '',
            userUuid: m.authorUuid ?? '',
            actorKind: ActorKind.values.byName(m.actorKind),
            summaryJson: jsonEncode(m.summary ?? const {}),
          ),
    ];
  }

  void _schedule() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(poll()));
  }

  /// Reads new ops and flashes the agent writes among them.
  Future<void> poll() async {
    if (_disposed || source == null) return;
    // One read at a time; a burst during a read is caught by the next one.
    await _running;
    final run = _poll();
    _running = run;
    await run;
  }

  Future<void> _poll() async {
    List<AgentWrite> rows;
    try {
      rows = await source!(_since.subtract(const Duration(seconds: 5)));
    } catch (e) {
      debugPrint('Reading agent writes failed: $e');
      return;
    }
    if (_disposed) return;
    rows.sort((a, b) => a.at.compareTo(b.at));
    final now = clock.now();
    for (final r in rows) {
      if (!_seen.add(r.id)) continue;
      if (r.at.isAfter(_since)) _since = r.at;
      if (now.difference(r.at) > maxAge) continue;
      final label = labelOf(r);
      if (label == null) continue;
      _flash(r, label);
    }
    if (_seen.length > 5000) _seen.clear();
  }

  /// The tag of [r], or null when it is not an agent write to flash.
  String? labelOf(AgentWrite r) {
    if (!r.sessionId.startsWith('server:')) return null;
    final own = r.userUuid == editor.session.userId;
    final participants =
        SheetsCollab.of(editor)?.presence.presence?.participants ??
        const <Participant>[];
    String? name(ActorKind kind) {
      for (final p in participants) {
        if (p.userUuid.uuid == r.userUuid && p.actorKind == kind) {
          return p.displayName;
        }
      }
      return null;
    }

    switch (r.actorKind) {
      case ActorKind.mcp:
        final agent = name(ActorKind.mcp);
        if (agent != null) return agent;
        final user = own ? null : name(ActorKind.user);
        return user == null ? labels.mcp : labels.of(user);
      case ActorKind.ai:
        if (own) return null;
        return labels.aiOf(name(ActorKind.user) ?? labels.someone);
      default:
        return null;
    }
  }

  void _flash(AgentWrite r, String label) {
    final ChangeSummary s;
    try {
      s = ChangeSummary.parse(r.summaryJson);
    } on Object {
      return;
    }
    final model = editor.model;
    var n = 0;
    for (final json in s.ranges) {
      if (n >= 20) break;
      try {
        final g = GridRange.tryParse(json);
        if (g == null) continue;
        final rr = model.sheet(g.sheetId)?.resolve(g);
        if (rr == null) continue;
        var rect = rr.rect;
        if (rr.wholeRows || rr.wholeColumns) {
          final used = model.sheet(g.sheetId)?.usedRect();
          rect = used == null ? rect : (rect.intersection(used) ?? used);
        }
        highlights.flash(
          AgentHighlight(
            sheetId: g.sheetId,
            rect: rect,
            label: label,
            color: AgentHighlightLayer.agentColor,
          ),
        );
        n++;
      } on Object {
        continue;
      }
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_sub?.cancel());
  }
}

/// Tag texts of [ExternalAgentWrites].
class AgentLabels {
  const AgentLabels({
    required this.mcp,
    required this.of,
    required this.aiOf,
    required this.someone,
  });

  final String mcp;
  final String Function(String name) of;
  final String Function(String name) aiOf;
  final String someone;
}
