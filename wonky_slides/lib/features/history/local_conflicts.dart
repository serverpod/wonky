import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show Participant, PresenceNotice;
import 'package:wonky_revlog/rows.dart' show RowOp;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';

import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import '../revlog/logged_deck_session.dart';

/// A text body (Slides 09 §6.3): an element's text, a table cell's text or
/// a slide's speaker notes.
@immutable
class TextBodyRef {
  const TextBodyRef.element(this.elementId)
    : kind = 'element',
      slideId = null,
      rowId = null,
      columnId = null;
  const TextBodyRef.cell(this.elementId, this.rowId, this.columnId)
    : kind = 'cell',
      slideId = null;
  const TextBodyRef.notes(this.slideId)
    : kind = 'notes',
      elementId = null,
      rowId = null,
      columnId = null;

  /// `element`, `cell` or `notes`.
  final String kind;
  final String? elementId;
  final String? rowId;
  final String? columnId;
  final String? slideId;

  /// The stable key (`element:<id>`, `cell:<el>:<row>:<col>`,
  /// `notes:<slide>`).
  String get key => switch (kind) {
    'cell' => 'cell:$elementId:$rowId:$columnId',
    'notes' => 'notes:$slideId',
    _ => 'element:$elementId',
  };

  /// The text target of a `SetText` that writes this body.
  TextTarget get target => switch (kind) {
    'cell' => CellText(elementId!, rowId!, columnId!),
    'notes' => NotesText(slideId!),
    _ => ElementText(elementId!),
  };

  /// The current text of this body in [m] (null when the target is gone;
  /// '' when it is empty).
  String? currentIn(DeckModel m) => switch (kind) {
    'cell' =>
      m.element(elementId!) == null
          ? null
          : m
                    .cellsOf(elementId!)
                    .where((c) => c.rowId == rowId && c.columnId == columnId)
                    .firstOrNull
                    ?.text ??
                '',
    'notes' =>
      m.slide(slideId!) == null ? null : m.slide(slideId!)!.notes ?? '',
    _ =>
      m.element(elementId!) == null ? null : m.element(elementId!)!.text ?? '',
  };

  /// The slide the body is on in [m] (null when gone).
  String? slideIn(DeckModel m) => switch (kind) {
    'notes' => m.slide(slideId!) == null ? null : slideId,
    _ => m.element(elementId!)?.slideId,
  };

  Map<String, Object?> toJson() => {
    'k': kind,
    'e': ?elementId,
    'r': ?rowId,
    'c': ?columnId,
    's': ?slideId,
  };

  static TextBodyRef? fromJson(Object? j) {
    if (j is! Map) return null;
    String? str(String k) => j[k] is String ? j[k] as String : null;
    return switch (j['k']) {
      'element' when str('e') != null => TextBodyRef.element(str('e')!),
      'cell' when str('e') != null && str('r') != null && str('c') != null =>
        TextBodyRef.cell(str('e')!, str('r')!, str('c')!),
      'notes' when str('s') != null => TextBodyRef.notes(str('s')!),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) => other is TextBodyRef && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// An offline (or forced) text edit replaced by a newer edit from someone
/// else (Slides 09 §6.3, A-09-5 `LocalConflict`): kept in the user's local
/// store (`slides.conflicts.<deckId>`) for [SlidesConflicts.lifetime].
@immutable
class SlidesLocalConflict {
  const SlidesLocalConflict({
    required this.id,
    required this.target,
    required this.myText,
    required this.theirText,
    required this.detectedAt,
    this.slideId,
    this.theirUserId,
    this.theirName,
    this.changeLogId,
    this.dismissed = false,
  });

  final String id;
  final TextBodyRef target;

  /// Delta JSON of the user's text (null = empty).
  final String? myText;

  /// Delta JSON of the winning text; null when the target was deleted.
  final String? theirText;

  /// The slide the body was on when detected.
  final String? slideId;
  final String? theirUserId;
  final String? theirName;
  final String? changeLogId;
  final DateTime detectedAt;
  final bool dismissed;

  /// Whether the target was deleted ("deleted by Anna").
  bool get deleted => theirText == null;

  /// Whether *Restore mine* can write the text back.
  bool get canRestore => !deleted;

  SlidesLocalConflict dismiss() => SlidesLocalConflict(
    id: id,
    target: target,
    myText: myText,
    theirText: theirText,
    slideId: slideId,
    theirUserId: theirUserId,
    theirName: theirName,
    changeLogId: changeLogId,
    detectedAt: detectedAt,
    dismissed: true,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    't': target.toJson(),
    'mine': myText,
    'theirs': theirText,
    's': slideId,
    'u': theirUserId,
    'n': theirName,
    'cl': changeLogId,
    'at': detectedAt.toUtc().toIso8601String(),
    if (dismissed) 'd': true,
  };

  static SlidesLocalConflict? fromJson(Object? j) {
    if (j is! Map) return null;
    final target = TextBodyRef.fromJson(j['t']);
    final at = DateTime.tryParse('${j['at']}');
    if (target == null || at == null || j['id'] is! String) return null;
    return SlidesLocalConflict(
      id: j['id'] as String,
      target: target,
      myText: j['mine'] as String?,
      theirText: j['theirs'] as String?,
      slideId: j['s'] as String?,
      theirUserId: j['u'] as String?,
      theirName: j['n'] as String?,
      changeLogId: j['cl'] as String?,
      detectedAt: at,
      dismissed: j['d'] == true,
    );
  }
}

/// Overwritten text review of one open deck (Slides 09 §6.3, P1): records
/// the text bodies the user writes while offline (or under a forced soft
/// lock, [forced]) in `slides.offlineEdits.<deckId>`, and after the next
/// sync compares them with the merged deck. A body whose text now differs
/// because someone else wrote later — or whose element/slide was deleted —
/// becomes a [SlidesLocalConflict]; a toast offers the review dialog
/// (`slides.conflicts.review`), where *Restore mine*
/// (`slides.conflicts.restoreMine`, one undo step) writes the texts back.
///
/// Also shows "Anna restored a previous version" when a collaborator
/// restores a version (presence notice `versionRestored`, 09 §4.4).
class SlidesConflicts extends ChangeNotifier {
  SlidesConflicts._(
    this.editor, {
    LocalStore? store,
    this.changeLogs,
    this.isOffline,
    this.names,
  }) : store = store ?? editor.services.userStore {
    editor.applyListeners.add(_onApply);
    editor.services.connectivity.addListener(_onConnectivity);
    _wasOnline = !_offline;
    unawaited(_load());
  }

  static final Expando<SlidesConflicts> _of = Expando('slidesConflicts');

  /// The conflicts of [editor] (null when not attached).
  static SlidesConflicts? of(DeckEditorController editor) => _of[editor];

  /// Creates (or returns) the conflicts of [editor]; [presence] delivers
  /// restore notices and collaborator names.
  static SlidesConflicts attach(
    DeckEditorController editor, {
    PresenceSession? presence,
    LocalStore? store,
    Future<List<RevOpMeta>> Function()? changeLogs,
    bool Function()? isOffline,
    String? Function(String authUserId)? names,
  }) {
    final c = _of[editor] ??= SlidesConflicts._(
      editor,
      store: store,
      changeLogs: changeLogs,
      isOffline: isOffline,
      names: names,
    );
    c._setPresence(presence);
    return c;
  }

  final DeckEditorController editor;
  final LocalStore store;

  /// The local change log (overrides the replica's; tests).
  final Future<List<RevOpMeta>> Function()? changeLogs;

  /// Whether writes count as offline (overrides connectivity; tests).
  final bool Function()? isOffline;

  /// Names of auth user ids (overrides the presence roster; tests).
  final String? Function(String authUserId)? names;

  /// Bodies edited under a forced soft lock (*Edit anyway*, 09 §2.2) are
  /// tracked like offline edits; the soft locks set this.
  bool Function(TextBodyRef body)? forced;

  /// Conflicts expire after this long (09 §6.3).
  static const lifetime = Duration(days: 7);

  /// Max tracked bodies per deck.
  static const maxTracked = 2000;

  final Map<String, ({TextBodyRef ref, String? text, DateTime at})> _tracked =
      {};
  List<SlidesLocalConflict> _all = const [];
  bool _wasOnline = true;
  bool _disposed = false;
  Timer? _save;
  Timer? _settle;
  PresenceSession? _presence;
  StreamSubscription<PresenceNotice>? _notices;

  ShellServices get services => editor.services;
  String get _deck => editor.session.deckId;
  String get _trackKey => 'slides.offlineEdits.$_deck';
  String get _conflictKey => 'slides.conflicts.$_deck';

  bool get _offline =>
      isOffline?.call() ??
      (!services.connectivity.online || Api.simulatedOffline);

  /// Open conflicts (not dismissed, not expired), newest first.
  List<SlidesLocalConflict> get open {
    final cutoff = clock.now().subtract(lifetime);
    return [
      for (final c in _all)
        if (!c.dismissed && c.detectedAt.isAfter(cutoff)) c,
    ]..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  /// Bodies written offline and not yet checked (tests, diagnostics).
  int get trackedBodies => _tracked.length;

  void _setPresence(PresenceSession? p) {
    if (identical(p, _presence)) return;
    _presence = p;
    unawaited(_notices?.cancel());
    _notices = p?.notices.listen(_onNotice);
  }

  void _onNotice(PresenceNotice n) {
    if (_disposed || n.kind != 'versionRestored') return;
    Map<String, Object?> p;
    try {
      p = (jsonDecode(n.payloadJson) as Map).cast<String, Object?>();
    } on Object {
      p = const {};
    }
    if (p['userId'] == services.me?.id) return;
    services.toasts.show(
      slidesL10nOf(services).toastVersionRestoredBy('${p['name'] ?? ''}'),
    );
  }

  // ------------------------------------------------------------- tracking

  /// The text bodies a plan wrote.
  static List<TextBodyRef> bodiesOf(SlidesPlan plan, DeckModel model) {
    final out = <TextBodyRef>[];
    for (final c in plan.changes) {
      if (c.op == RowOp.delete) continue;
      if (!c.columnsAfter.containsKey(
        c.table == SlidesTables.slide ? SlideCols.notes : SlidesCols.text,
      )) {
        continue;
      }
      switch (c.table) {
        case SlidesTables.slideElement:
          out.add(TextBodyRef.element(c.rowId));
        case SlidesTables.slide:
          out.add(TextBodyRef.notes(c.rowId));
        case SlidesTables.slideTableCell:
          final cols = {...c.columnsBefore, ...c.columnsAfter};
          final cur = model.currentColumns(
            SlidesTables.slideTableCell,
            c.rowId,
          );
          final el = cols[SlidesCols.elementId] ?? cur?[SlidesCols.elementId];
          final row = cols[TableCellCols.rowId] ?? cur?[TableCellCols.rowId];
          final col =
              cols[TableCellCols.columnId] ?? cur?[TableCellCols.columnId];
          if (el != null && row != null && col != null) {
            out.add(TextBodyRef.cell('$el', '$row', '$col'));
          }
      }
    }
    return out;
  }

  void _onApply(CommandContext ctx, SlidesOperation op, SlidesPlan plan) {
    if (_disposed) return;
    final offline = _offline;
    final now = clock.now().toUtc();
    var changed = false;
    for (final ref in bodiesOf(plan, editor.model)) {
      final track = offline || (forced?.call(ref) ?? false);
      if (!track) {
        // A later online edit of ours supersedes the tracked one.
        changed |= _tracked.remove(ref.key) != null;
        continue;
      }
      if (_tracked.length >= maxTracked && !_tracked.containsKey(ref.key)) {
        continue;
      }
      _tracked[ref.key] = (
        ref: ref,
        text: ref.currentIn(editor.model),
        at: now,
      );
      changed = true;
    }
    if (changed) _scheduleSave();
  }

  void _scheduleSave() {
    _save?.cancel();
    _save = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_persist()),
    );
  }

  Future<void> _persist() async {
    try {
      if (_tracked.isEmpty) {
        await store.remove(_trackKey);
      } else {
        await store.write(_trackKey, [
          for (final t in _tracked.values)
            {'t': t.ref.toJson(), 'v': t.text, 'at': t.at.toIso8601String()},
        ]);
      }
    } catch (e) {
      debugPrint('Saving offline text edits failed: $e');
    }
  }

  Future<void> _saveConflicts() async {
    try {
      final cutoff = clock.now().subtract(lifetime);
      _all = [
        for (final c in _all)
          if (c.detectedAt.isAfter(cutoff)) c,
      ];
      if (_all.isEmpty) {
        await store.remove(_conflictKey);
      } else {
        await store.write(_conflictKey, [for (final c in _all) c.toJson()]);
      }
    } catch (e) {
      debugPrint('Saving text conflicts failed: $e');
    }
  }

  Future<void> _load() async {
    try {
      final raw = await store.read(_trackKey);
      if (raw is List) {
        for (final j in raw) {
          if (j is! Map) continue;
          final ref = TextBodyRef.fromJson(j['t']);
          if (ref == null) continue;
          _tracked.putIfAbsent(
            ref.key,
            () => (
              ref: ref,
              text: j['v'] as String?,
              at: DateTime.tryParse('${j['at']}') ?? clock.now().toUtc(),
            ),
          );
        }
      }
      final list = await store.read(_conflictKey);
      if (list is List) {
        _all = [for (final j in list) ?SlidesLocalConflict.fromJson(j)];
      }
    } catch (e) {
      debugPrint('Reading offline text edits failed: $e');
    }
    if (_disposed) return;
    notifyListeners();
    // Edits tracked in an earlier session: check once the deck synced.
    if (!_offline && _tracked.isNotEmpty) _afterSync();
  }

  // ------------------------------------------------------------ checking

  void _onConnectivity() {
    final online = !_offline;
    if (online && !_wasOnline && _tracked.isNotEmpty) _afterSync();
    _wasOnline = online;
  }

  /// Waits until the outbox drained after reconnecting (our pending writes
  /// are committed and the remote ops before them applied), then [check]s.
  void _afterSync() {
    _settle?.cancel();
    final session = editor.session;
    if (session is! LoggedDeckSession) return;
    // A timer only marks that a check is pending (dispose cancels it).
    _settle = Timer(const Duration(days: 1), () {});
    unawaited(() async {
      try {
        await session.whenSynced(timeout: const Duration(seconds: 90));
      } catch (_) {
        // Check what arrived anyway.
      }
      if (_disposed || _offline || !(_settle?.isActive ?? false)) return;
      _settle?.cancel();
      if (!_disposed) await check();
    }());
  }

  Future<List<RevOpMeta>> _logs() async {
    final f = changeLogs;
    if (f != null) return f();
    final session = editor.session;
    if (session is! LoggedDeckSession) return const [];
    return session.recentOps(const Duration(days: 30));
  }

  /// Compares the tracked bodies with the merged deck and records the
  /// conflicts; shows the toast. Returns the new conflicts.
  Future<List<SlidesLocalConflict>> check() async {
    if (_tracked.isEmpty) return const [];
    final me = editor.session.userId;
    List<RevOpMeta> logs;
    try {
      logs = await _logs();
    } catch (e) {
      debugPrint('Reading the deck change log failed: $e');
      logs = const [];
    }
    logs = [...logs]..sort((a, b) => b.revision.compareTo(a.revision));
    final model = editor.model;
    final found = <SlidesLocalConflict>[];
    final now = clock.now().toUtc();
    var n = 0;
    for (final e in _tracked.entries) {
      final t = e.value;
      final current = t.ref.currentIn(model);
      if (current != null && _same(current, t.text)) continue;
      final by = _firstWhere(
        logs,
        (l) => _touched(l, t.ref, deleted: current == null),
      );
      if (by != null && by.authorUuid == me) continue;
      if (by == null && current != null) continue; // not someone else's
      found.add(
        SlidesLocalConflict(
          id: '${e.key}-${now.microsecondsSinceEpoch}-${n++}',
          target: t.ref,
          myText: t.text,
          theirText: current,
          slideId: t.ref.slideIn(model),
          theirUserId: by?.authorUuid,
          theirName: by == null ? null : nameOf(by.authorUuid ?? ''),
          changeLogId: by == null ? null : '${by.revision}',
          detectedAt: now,
        ),
      );
    }
    _tracked.clear();
    await _persist();
    if (found.isNotEmpty) {
      _all = [..._all, ...found];
      await _saveConflicts();
    }
    if (_disposed) return found;
    notifyListeners();
    _toast(found);
    return found;
  }

  static bool _same(String? a, String? b) {
    String plain(String? x) => SlidesText.plainText(x).trimRight();
    return (a ?? '') == (b ?? '') || plain(a) == plain(b);
  }

  static RevOpMeta? _firstWhere(List<RevOpMeta> l, bool Function(RevOpMeta) f) {
    for (final x in l) {
      if (f(x)) return x;
    }
    return null;
  }

  /// Whether change-log row [l] touched [ref] (its summary's elements or
  /// slides; with [deleted], its deleted lists).
  static bool _touched(RevOpMeta l, TextBodyRef ref, {required bool deleted}) {
    final s = l.summary;
    if (s == null) return false;
    List<Object?> list(Object? v) => v is List ? v : const [];
    final del = s['deleted'];
    if (deleted) {
      final d = del is Map ? del : const <Object?, Object?>{};
      return switch (ref.kind) {
        'notes' => list(d['slides']).contains(ref.slideId),
        _ =>
          list(d['elements']).contains(ref.elementId) ||
              list(d['slides']).isNotEmpty,
      };
    }
    return switch (ref.kind) {
      'notes' => list(s['slides']).contains(ref.slideId),
      _ => list(s['elements']).contains(ref.elementId),
    };
  }

  /// The display name of an auth user id (me, the presence roster).
  String nameOf(String authUserId) {
    final me = services.me;
    if (me != null && me.uuid.uuid == authUserId) return me.displayName;
    final named = names?.call(authUserId);
    if (named != null) return named;
    for (final p in _presence?.participants ?? const <Participant>[]) {
      if (p.userUuid.uuid == authUserId) return p.displayName;
    }
    return services.l10n?.someone ?? 'Someone';
  }

  void _toast(List<SlidesLocalConflict> found) {
    if (found.isEmpty) return;
    final l = slidesL10nOf(services);
    final who = {for (final c in found) c.theirName ?? ''}..remove('');
    services.toasts.show(
      l.toastConflicts(
        found.length,
        who.length == 1 ? who.single : l.conflictsSeveralPeople,
      ),
      actionLabel: l.conflictsReview,
      onAction: () =>
          unawaited(editor.invokeCommand('slides.conflicts.review')),
    );
  }

  // ------------------------------------------------------------- actions

  /// Marks [ids] (all open conflicts when null) as dismissed.
  Future<void> dismiss([Iterable<String>? ids]) async {
    final set = ids?.toSet();
    _all = [
      for (final c in _all)
        if (set == null || set.contains(c.id)) c.dismiss() else c,
    ];
    await _saveConflicts();
    if (!_disposed) notifyListeners();
  }

  /// The open conflicts with [ids].
  List<SlidesLocalConflict> byIds(Iterable<String> ids) {
    final set = ids.toSet();
    return [
      for (final c in open)
        if (set.contains(c.id)) c,
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    _save?.cancel();
    _settle?.cancel();
    unawaited(_notices?.cancel());
    editor.applyListeners.remove(_onApply);
    services.connectivity.removeListener(_onConnectivity);
    if (_tracked.isNotEmpty) unawaited(_persist());
    _of[editor] = null;
    super.dispose();
  }
}
