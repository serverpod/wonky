import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show Participant;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;

import '../features/collab/slides_collab.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/revlog/logged_deck_session.dart';
import '../l10n/slides_l10n.dart';
import 'agent_flash.dart';

/// Reads the deck's op metadata committed at or after a time.
typedef DeckChangeLogSource = Future<List<RevOpMeta>> Function(DateTime since);

/// Flashes the elements that headless agent writes touched (Slides 11 §1.3,
/// AC 5: "live editors see headless writes … with the agent flash on
/// touched elements"): when remote batches arrive, the new `DeckChangeLog`
/// rows of MCP writes (and of AI runs by other users) are read from the
/// replica and their summary's elements — or slides — flash with the
/// agent's tag ([SlidesAgentFlash]). Mirrors Sheets' `ExternalAgentWrites`.
///
/// The server also shows the agent as a participant for 5 s
/// (`DeckAgentPresence`), so its selection outline can show next to the
/// flash.
class SlidesAgentWrites {
  SlidesAgentWrites(
    this.editor, {
    DeckChangeLogSource? source,
    SlidesAgentFlash? flash,
  }) : source = source ?? _syncedSource(editor),
       flash = flash ?? SlidesAgentFlash.of(editor) {
    if (this.source == null) return;
    _since = clock.now().subtract(const Duration(seconds: 10));
    _sub = editor.session.remoteBatches.listen((_) => _schedule());
  }

  final DeckEditorController editor;
  final DeckChangeLogSource? source;
  final SlidesAgentFlash flash;

  /// Rows older than this are not flashed (offline writes synced late).
  static const maxAge = Duration(minutes: 2);

  /// Remote batches arrive in bursts: read the log once after.
  static const debounce = Duration(milliseconds: 400);

  /// Elements flashed per change at most.
  static const maxElements = 30;

  StreamSubscription<Object?>? _sub;
  Timer? _timer;
  late DateTime _since;
  final Set<String> _seen = {};
  bool _disposed = false;
  Future<void>? _running;

  static DeckChangeLogSource? _syncedSource(DeckEditorController editor) {
    final session = editor.session;
    if (session is! LoggedDeckSession) return null;
    return (since) =>
        session.client.store.recentOps(session.fileUuid.uuid, since);
  }

  void _schedule() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(poll()));
  }

  /// Reads new change-log rows and flashes the agent writes among them.
  Future<void> poll() async {
    if (_disposed || source == null) return;
    await _running;
    final run = _poll();
    _running = run;
    await run;
  }

  Future<void> _poll() async {
    List<RevOpMeta> rows;
    try {
      rows = await source!(_since.subtract(const Duration(seconds: 5)));
    } catch (e) {
      debugPrint('Reading agent writes failed: $e');
      return;
    }
    if (_disposed) return;
    rows.sort((a, b) => a.revision.compareTo(b.revision));
    final now = clock.now();
    for (final r in rows) {
      if (!_seen.add('${r.revision}')) continue;
      if (r.committedAt.isAfter(_since)) _since = r.committedAt;
      if (now.difference(r.committedAt) > maxAge) continue;
      final label = labelOf(r);
      if (label == null) continue;
      _flash(r, label);
    }
    if (_seen.length > 5000) _seen.clear();
  }

  /// The tag of [r], or null when it is not an agent write to flash
  /// (user edits; the user's own AI runs, which the app previews itself).
  String? labelOf(RevOpMeta r) {
    if (!(r.sessionId ?? '').startsWith('server:')) return null;
    final own = r.authorUuid == editor.session.userId;
    final collab = SlidesCollab.of(editor);
    final participants = collab?.session?.participants ?? const <Participant>[];
    String? name(String kind) {
      for (final p in participants) {
        if (p.userUuid.uuid == r.authorUuid && p.actorKind.name == kind) {
          return p.displayName;
        }
      }
      return null;
    }

    final l = slidesL10nOf(editor.services);
    final user =
        name('user') ??
        (own ? editor.services.currentUser.value?.summary.displayName : null);
    switch (r.actorKind) {
      case 'mcp':
        return name('mcp') ?? l.actorViaMcp(user ?? 'MCP');
      case 'ai':
        if (own) return null;
        return name('ai') ?? l.actorViaAi(user ?? '…');
      default:
        return null;
    }
  }

  void _flash(RevOpMeta r, String label) {
    final s = r.summary;
    if (s == null) return;
    final model = editor.model;
    final elements = [
      for (final id in (s['elements'] as List? ?? const []).whereType<String>())
        if (model.element(id) != null) id,
    ];
    // Per slide (or layout/master): one highlight with its elements.
    final bySurface = <String, List<String>>{};
    for (final id in elements) {
      final owner = model.element(id)!.ownerId;
      if (owner == null) continue;
      final list = bySurface.putIfAbsent(owner, () => []);
      if (list.length < maxElements) list.add(id);
    }
    for (final MapEntry(key: surface, value: ids) in bySurface.entries) {
      flash.flash(label: label, slideId: surface, elementIds: ids);
    }
    if (bySurface.isEmpty) {
      // Slide-level changes (added slides, backgrounds, notes): outline
      // the slides.
      for (final id in (s['slides'] as List? ?? const []).whereType<String>()) {
        if (model.slide(id) != null) flash.flash(label: label, slideId: id);
      }
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_sub?.cancel());
  }
}
