import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show PresenceHints;
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../../revlog/logged_workbook_session.dart';
import '../../sheet_editor/sheet_editor_controller.dart';

/// A range that is about to change (big pastes, fills, imports).
class PendingHint {
  PendingHint({
    required this.sessionId,
    required this.sheetId,
    required this.range,
    required this.receivedAt,
  });

  final String sessionId;
  final String sheetId;
  final PresenceRangeIds range;
  final DateTime receivedAt;
}

/// Range bounds by ids.
typedef PresenceRangeIds = ({String r1, String c1, String r2, String c2});

/// Ephemeral commit hints over the presence stream (Sheets 10 §2):
///
/// - `typing`: the cell editor's text while someone types (live preview).
/// - `pending`: a commit of more than [maxCells] cells is on its way; the
///   others show a shimmer over its range until the group's last op
///   arrives, the sheet's cells change remotely, or [lifetime] passes.
///
/// Committed values themselves arrive as RevLog ops in about one round trip,
/// so per-cell value hints are not sent (RevLog spec 17 RD-18).
class CommitHints {
  CommitHints(this.editor) {
    editor.model.addListener(_onBatch);
    _remote = editor.session.remoteBatches.listen(_onRemote);
    final session = editor.session;
    if (session is LoggedWorkbookSession) {
      _history = session.history.listen((op) {
        // The last op of another connection's group: its shimmer is done.
        if (op.groupLast && op.groupId != null && pending.isNotEmpty) {
          pending.clear();
          _refresh();
        }
      });
    }
    editor.editor.text.addListener(_onTypingText);
  }

  /// Receives `typing` hints (live typing preview, Sheets 10 §2.1, P2).
  void Function(
    String sessionId, {
    required String sheetId,
    required String rowId,
    required String colId,
    required String? text,
  })?
  onTyping;

  /// Typing previews are sent at most this often (4/s).
  static const typingInterval = Duration(milliseconds: 250);

  /// Max characters of a typing preview.
  static const typingMaxChars = 200;

  Timer? _typingTimer;
  String? _typingSent;

  void _onTypingText() {
    if (_disposed || _presence == null || !editor.roleCanEdit) return;
    if (_typingTimer?.isActive ?? false) return;
    _sendTyping();
    _typingTimer = Timer(typingInterval, _sendTyping);
  }

  /// Sends the cell editor's current text as a `typing` hint (when it
  /// changed since the last one).
  void _sendTyping() {
    final p = _presence;
    final s = editor.editor.session;
    if (_disposed || p == null || s == null) {
      _typingSent = null;
      return;
    }
    var text = editor.editor.text.text;
    if (text.length > typingMaxChars) {
      text = text.substring(0, typingMaxChars);
    }
    final key = '${s.sheetId}|${s.rowId}|${s.colId}|$text';
    if (key == _typingSent) return;
    _typingSent = key;
    p.sendHints([
      jsonEncode({
        't': 'typing',
        'sheetId': s.sheetId,
        'rowId': s.rowId,
        'colId': s.colId,
        'text': text,
      }),
    ]);
  }

  final SheetEditorController editor;

  /// Commits of more cells than this send a `pending` hint.
  static const maxCells = 500;

  /// Hints older than this are dropped.
  static const lifetime = Duration(seconds: 5);

  PresenceSession? _presence;
  StreamSubscription<PresenceHints>? _hintsSub;
  StreamSubscription<WorkbookChangeBatch>? _remote;
  StreamSubscription<Object?>? _history;
  final List<WorkbookChangeBatch> _pending = [];
  final Set<WorkbookChangeBatch> _remoteBatches = Set.identity();
  bool _scheduled = false;
  Timer? _expiry;
  bool _disposed = false;

  /// Pending ranges (shimmer).
  final List<PendingHint> pending = [];

  /// Sent hint messages (tests, diagnostics).
  int sent = 0;

  void attach(PresenceSession? presence) {
    if (identical(presence, _presence)) return;
    unawaited(_hintsSub?.cancel());
    _hintsSub = null;
    _presence?.removeListener(_onRoster);
    _presence = presence;
    if (presence != null) {
      _hintsSub = presence.hints.listen(receive);
      presence.addListener(_onRoster);
    }
  }

  // ------------------------------------------------------------------ send

  void _onBatch(WorkbookChangeBatch batch) {
    if (_disposed || batch.isEmpty) return;
    _pending.add(batch);
    if (_scheduled) return;
    _scheduled = true;
    // Remote batches are announced on `remoteBatches` right after they are
    // applied (delivered in a microtask); decide after those ran.
    Timer.run(_flushLocal);
  }

  void _onRemote(WorkbookChangeBatch batch) {
    _remoteBatches.add(batch);
    _dropSynced(batch);
  }

  void _flushLocal() {
    _scheduled = false;
    final batches = List.of(_pending);
    _pending.clear();
    final local = [
      for (final b in batches)
        if (!_remoteBatches.contains(b)) b,
    ];
    _remoteBatches.clear();
    if (local.isEmpty || _disposed) return;
    final hints = buildHints(local);
    if (hints.isEmpty) return;
    final p = _presence;
    if (p == null || !editor.roleCanEdit) return;
    p.sendHints(hints);
    sent += hints.length;
  }

  /// `pending` hint JSON messages for local [batches]: one per sheet whose
  /// commit changed more than [maxCells] cells.
  List<String> buildHints(List<WorkbookChangeBatch> batches) {
    final bySheet = <String, Set<CellKey>>{};
    for (final b in batches) {
      for (final e in b.whereType<CellsChanged>()) {
        if (e.contentKeys.isEmpty) continue;
        bySheet.putIfAbsent(e.sheetId, () => {}).addAll(e.contentKeys);
      }
    }
    final now = clock.now().millisecondsSinceEpoch;
    final out = <String>[];
    for (final entry in bySheet.entries) {
      final keys = entry.value;
      if (keys.length <= maxCells) continue;
      final sheet = editor.model.sheet(entry.key);
      if (sheet == null) continue;
      final rect = _bounds(sheet, keys);
      if (rect == null) continue;
      out.add(
        jsonEncode({
          't': 'pending',
          'sheetId': entry.key,
          'range': {
            'r1': sheet.rows.idAt(rect.top),
            'c1': sheet.columns.idAt(rect.left),
            'r2': sheet.rows.idAt(rect.bottom),
            'c2': sheet.columns.idAt(rect.right),
          },
          'kind': 'values',
          'hlcMillis': now,
        }),
      );
    }
    return out;
  }

  static GridRect? _bounds(SheetModel sheet, Set<CellKey> keys) {
    int? t, l, b, r;
    for (final k in keys) {
      final row = sheet.rows.indexOf(k.rowId);
      final col = sheet.columns.indexOf(k.colId);
      if (row < 0 || col < 0) continue;
      t = t == null || row < t ? row : t;
      b = b == null || row > b ? row : b;
      l = l == null || col < l ? col : l;
      r = r == null || col > r ? col : r;
    }
    return t == null ? null : GridRect(t, l!, b!, r!);
  }

  // --------------------------------------------------------------- receive

  /// Applies hints relayed from another participant (`cell`/`range` hints
  /// of older clients are ignored).
  void receive(PresenceHints e) {
    if (_disposed) return;
    final now = clock.now();
    var changed = false;
    for (final raw in e.hints) {
      Object? j;
      try {
        j = jsonDecode(raw);
      } on FormatException {
        continue;
      }
      if (j is! Map) continue;
      final sheetId = j['sheetId'];
      if (sheetId is! String || editor.model.sheet(sheetId) == null) continue;
      switch (j['t']) {
        case 'typing':
          final rowId = j['rowId'];
          final colId = j['colId'];
          if (rowId is! String || colId is! String) continue;
          final text = j['text'];
          onTyping?.call(
            e.sessionId,
            sheetId: sheetId,
            rowId: rowId,
            colId: colId,
            text: text is String ? text : null,
          );
        case 'pending':
          final r = j['range'];
          if (r is! Map) continue;
          final ids = [r['r1'], r['c1'], r['r2'], r['c2']];
          if (ids.any((x) => x is! String)) continue;
          pending.add(
            PendingHint(
              sessionId: e.sessionId,
              sheetId: sheetId,
              range: (
                r1: ids[0]! as String,
                c1: ids[1]! as String,
                r2: ids[2]! as String,
                c2: ids[3]! as String,
              ),
              receivedAt: now,
            ),
          );
          changed = true;
      }
    }
    if (changed) {
      _refresh();
      _scheduleExpiry();
    }
  }

  void _dropSynced(WorkbookChangeBatch batch) {
    if (pending.isEmpty) return;
    var changed = false;
    for (final e in batch.whereType<CellsChanged>()) {
      if (e.contentKeys.isEmpty) continue;
      final before = pending.length;
      pending.removeWhere((p) => p.sheetId == e.sheetId);
      changed |= before != pending.length;
    }
    if (pending.isNotEmpty && batch.whereType<StructureChanged>().isNotEmpty) {
      pending.clear();
      changed = true;
    }
    if (changed) _refresh();
  }

  void _onRoster() {
    final p = _presence;
    if (p == null) return;
    final present = {for (final x in p.participants) x.sessionId};
    final before = pending.length;
    pending.removeWhere((h) => !present.contains(h.sessionId));
    if (before != pending.length) _refresh();
  }

  /// Drops hints older than [lifetime].
  void expire() {
    final cutoff = clock.now().subtract(lifetime);
    final before = pending.length;
    pending.removeWhere((h) => !h.receivedAt.isAfter(cutoff));
    if (before != pending.length) _refresh();
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    if (pending.isEmpty) return;
    var oldest = pending.first.receivedAt;
    for (final h in pending) {
      if (h.receivedAt.isBefore(oldest)) oldest = h.receivedAt;
    }
    final wait = oldest.add(lifetime).difference(clock.now());
    _expiry = Timer(
      wait.isNegative ? Duration.zero : wait + const Duration(milliseconds: 10),
      expire,
    );
  }

  void _refresh() {
    if (_disposed) return;
    editor.overlaySignal.fire();
  }

  void dispose() {
    _disposed = true;
    _typingTimer?.cancel();
    editor.editor.text.removeListener(_onTypingText);
    editor.model.removeListener(_onBatch);
    unawaited(_remote?.cancel());
    unawaited(_history?.cancel());
    unawaited(_hintsSub?.cancel());
    _presence?.removeListener(_onRoster);
    _expiry?.cancel();
  }
}
