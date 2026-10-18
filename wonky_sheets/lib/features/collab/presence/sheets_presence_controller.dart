import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show Participant, PresenceState;
import 'package:wonky_sheets_core/formula.dart' show CellPos, GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../../formatting/sheets_user_defaults.dart';
import '../../grid/selection/grid_selection.dart';
import '../../objects/objects_controller.dart';
import '../../sheet_editor/sheet_editor_controller.dart';
import 'presence_cursor.dart';

/// A remote participant's cursor on the grid.
@immutable
class RemoteCursorView {
  const RemoteCursorView({
    required this.participant,
    required this.cursor,
    required this.movedAt,
  });

  final Participant participant;
  final SheetsPresenceCursor cursor;

  /// When the active cell last moved (the name flag shows for 3 s).
  final DateTime movedAt;

  String get sessionId => participant.sessionId;
  int get colorIndex => participant.colorIndex;
  bool get isAgent => participant.actorKind.name != 'user';
  String get displayName => participant.displayName;
}

/// A collaborator's in-progress cell editor text (Sheets 10 §2.1 `typing`
/// hint, P2).
typedef TypingPreview = ({
  String sheetId,
  String rowId,
  String colId,
  String text,
  DateTime at,
});

/// Sheets presence (Sheets 10 §1.6): publishes the local selection, editing
/// state and (while followed) viewport as the `PresenceCursor` JSON through
/// the shell's [PresenceSession]; maps the other participants' cursors for
/// the grid layer, sheet tabs and avatars; jump-to and follow mode.
class SheetsPresenceController extends ChangeNotifier {
  SheetsPresenceController(this.editor) {
    editor.addListener(_onLocal);
    editor.editor.addListener(_onLocal);
    editor.scroll.addListener(_onScroll);
  }

  final SheetEditorController editor;

  /// How long a name flag stays after the cursor moved.
  static const flagDuration = Duration(seconds: 3);

  /// Viewport updates while followed (2/s).
  static const viewportInterval = Duration(milliseconds: 500);

  PresenceSession? _presence;
  SheetsPresenceCursor? _sent;
  final Map<String, RemoteCursorView> _cursors = {};
  final ValueNotifier<List<RemoteCursorView>> cursors = ValueNotifier(const []);

  /// The session we follow (Sheets 10 §1.5), or null.
  final ValueNotifier<String?> following = ValueNotifier(null);

  /// Session whose cursor flashes after a jump, and whether it is lit.
  String? flashSession;
  bool flashOn = false;
  Timer? _flash;
  Timer? _flagTimer;
  Timer? _viewportTimer;
  bool _applying = false;
  (double, double)? _followScroll;
  bool _disposed = false;

  /// Fires when cursors, flags or the flash change (grid layer repaint).
  final GridSignal repaint = GridSignal();

  /// Dash offset of the marching border of editing collaborators (px).
  double marchPhase = 0;
  Timer? _march;

  /// Interval of the marching border animation (one dash period per 1 s).
  static const marchTick = Duration(milliseconds: 60);

  /// The hovered cell (`sheetId`, row, col): the name flag of a cursor on
  /// it shows while hovered (Sheets 10 §1.2).
  (String, int, int)? _hover;

  /// Live typing previews by session id.
  final Map<String, TypingPreview> typing = {};

  /// How long a typing preview stays without an update.
  static const typingLifetime = Duration(seconds: 5);

  PresenceSession? get presence => _presence;

  String? _scriptFile;

  /// The file open in this window's script editor (null = the grid): the
  /// cursor then has `route: script` and the file (Sheets 09 §14.3).
  String? get scriptFileId => _scriptFile;
  set scriptFileId(String? fileId) {
    if (fileId == _scriptFile) return;
    _scriptFile = fileId;
    _publish();
  }

  String? get selfSessionId => _presence?.sessionId;

  /// Attaches the shell's presence session (null detaches).
  void attach(PresenceSession? presence) {
    if (identical(presence, _presence)) return;
    _presence?.removeListener(_onRemote);
    if (_presence?.detailOf == _detailOf) _presence?.detailOf = null;
    _presence = presence;
    _sent = null;
    if (presence != null) {
      presence.addListener(_onRemote);
      presence.detailOf = _detailOf;
      _onRemote();
      _publish();
    } else {
      _cursors.clear();
      _emit();
    }
  }

  // ---------------------------------------------------------------- outgoing

  /// The cursor describing the local state.
  SheetsPresenceCursor localCursor({bool withViewport = false}) {
    final sel = editor.selection.selection;
    final session = editor.editor.session;
    final scriptFile = _scriptFile;
    return SheetsPresenceCursor(
      route: scriptFile == null ? 'grid' : 'script',
      file: scriptFile,
      sheetId: editor.activeSheetId,
      activeRowId: sel.active.rowId.isEmpty ? null : sel.active.rowId,
      activeColId: sel.active.colId.isEmpty ? null : sel.active.colId,
      ranges: [
        for (final r in sel.ranges.take(SheetsPresenceCursor.maxRanges))
          PresenceRange(
            r1: r.kind == SelectionKind.columns || r.kind == SelectionKind.all
                ? null
                : r.r1,
            r2: r.kind == SelectionKind.columns || r.kind == SelectionKind.all
                ? null
                : r.r2,
            c1: r.kind == SelectionKind.rows || r.kind == SelectionKind.all
                ? null
                : r.c1,
            c2: r.kind == SelectionKind.rows || r.kind == SelectionKind.all
                ? null
                : r.c2,
          ),
      ],
      editing: session != null && session.sheetId == editor.activeSheetId,
      objectId: ObjectsController.maybeOf(editor)?.selectedId,
      viewport: withViewport ? _viewport() : null,
      following: following.value,
    );
  }

  PresenceViewport? _viewport() {
    final s = editor.activeSheet;
    final g = editor.geometry;
    if (s == null || g == null || s.rows.length == 0 || s.columns.length == 0) {
      return null;
    }
    final (top, _) = g.visibleRows;
    final (left, _) = g.visibleCols;
    final r = s.rows.tryIdAt(top);
    final c = s.columns.tryIdAt(left);
    if (r == null || c == null) return null;
    return PresenceViewport(
      topRowId: r,
      leftColId: c,
      zoom: editor.scroll.zoom,
    );
  }

  bool get _followed => (_presence?.followerCount ?? 0) > 0;

  /// Publishes the cursor after the object selection changed (08 §9.2:
  /// collaborators outline the selected object).
  void publishObjectSelection() => _publish();

  void _publish() {
    final p = _presence;
    if (p == null || _disposed) return;
    final c = localCursor(withViewport: _followed);
    if (c == _sent) return;
    _sent = c;
    p.updateCursor(c.encode());
  }

  void _onLocal() {
    if (_disposed) return;
    if (!_applying && following.value != null) {
      // Any local selection change or sheet switch stops following.
      final sel = editor.selection.selection;
      final last = _lastSelection;
      if (last != null &&
          (last.sheetId != sel.sheetId || last.active != sel.active)) {
        unfollow();
      }
    }
    _lastSelection = editor.selection.selection;
    _publish();
    _updateMarch();
  }

  GridSelection? _lastSelection;

  void _onScroll() {
    if (_disposed) return;
    final f = _followScroll;
    if (!_applying && following.value != null && f != null) {
      final dx = (editor.scroll.x - f.$1).abs();
      final dy = (editor.scroll.y - f.$2).abs();
      if (dx > 2 || dy > 2) unfollow();
    }
    if (_followed && !(_viewportTimer?.isActive ?? false)) {
      _viewportTimer = Timer(viewportInterval, _publish);
    }
  }

  // ---------------------------------------------------------------- incoming

  void _onRemote() {
    final p = _presence;
    if (p == null || _disposed) return;
    final self = p.sessionId;
    final now = DateTime.now();
    final seen = <String>{};
    for (final part in p.participants) {
      if (part.sessionId == self) continue;
      final cursor = SheetsPresenceCursor.tryParse(part.cursorJson);
      if (cursor == null) continue;
      seen.add(part.sessionId);
      final before = _cursors[part.sessionId];
      final moved =
          before == null ||
          before.cursor.activeRowId != cursor.activeRowId ||
          before.cursor.activeColId != cursor.activeColId ||
          before.cursor.sheetId != cursor.sheetId;
      _cursors[part.sessionId] = RemoteCursorView(
        participant: part,
        cursor: cursor,
        movedAt: moved ? now : before.movedAt,
      );
      if (part.sessionId == following.value) _applyFollow(cursor);
    }
    _cursors.removeWhere((k, _) => !seen.contains(k));
    final f = following.value;
    if (f != null && !p.participants.any((x) => x.sessionId == f)) unfollow();
    // The viewport is sent only while followed; the count may have changed.
    _publish();
    _emit();
  }

  void _emit() {
    if (_disposed) return;
    final list = _cursors.values.toList()
      ..sort(
        (a, b) => a.participant.joinedAt.compareTo(b.participant.joinedAt),
      );
    cursors.value = list;
    typing.removeWhere((k, _) => !(_cursors[k]?.cursor.editing ?? false));
    _scheduleFlagExpiry();
    _updateMarch();
    repaint.fire();
    notifyListeners();
  }

  void _scheduleFlagExpiry() {
    _flagTimer?.cancel();
    final now = DateTime.now();
    Duration? next;
    for (final c in _cursors.values) {
      final left = c.movedAt.add(flagDuration).difference(now);
      if (left > Duration.zero && (next == null || left < next)) next = left;
    }
    if (next != null) {
      _flagTimer = Timer(next + const Duration(milliseconds: 20), repaint.fire);
    }
  }

  /// Cursors drawn on [sheetId]: not away, on the grid route.
  List<RemoteCursorView> cursorsOn(String sheetId) => [
    for (final c in cursors.value)
      if (c.cursor.sheetId == sheetId &&
          c.cursor.route == 'grid' &&
          c.participant.state != PresenceState.away &&
          c.participant.state != PresenceState.offline)
        c,
  ];

  /// Participants per sheet (sheet tab dots).
  Map<String, List<RemoteCursorView>> get bySheet {
    final out = <String, List<RemoteCursorView>>{};
    for (final c in cursors.value) {
      if (c.participant.state == PresenceState.offline) continue;
      out.putIfAbsent(c.cursor.sheetId, () => []).add(c);
    }
    return out;
  }

  /// Whether the name flag of [c] shows (3 s after moving, while editing,
  /// while flashing, while its cell is hovered).
  bool flagVisible(RemoteCursorView c, DateTime now) =>
      c.cursor.editing ||
      now.difference(c.movedAt) < flagDuration ||
      c.sessionId == flashSession ||
      _hovered(c);

  bool _hovered(RemoteCursorView c) {
    final h = _hover;
    if (h == null || h.$1 != c.cursor.sheetId) return false;
    final sheet = editor.model.sheet(h.$1);
    if (sheet == null) return false;
    final a = activeOf(sheet, c.cursor);
    if (a == null) return false;
    final m = sheet.mergeAt(a.$1, a.$2);
    return m == null ? (a.$1 == h.$2 && a.$2 == h.$3) : m.contains(h.$2, h.$3);
  }

  /// The hovered cell of the grid (null when the pointer left it).
  void setHover(String? sheetId, int row, int col) {
    final next = sheetId == null ? null : (sheetId, row, col);
    if (next == _hover) return;
    final before = _hovering();
    _hover = next;
    // Repaint only when a cursor's flag appears or disappears.
    if (!setEquals(before, _hovering())) repaint.fire();
  }

  Set<String> _hovering() {
    final h = _hover;
    if (h == null) return const {};
    return {
      for (final c in cursorsOn(h.$1))
        if (_hovered(c)) c.sessionId,
    };
  }

  /// Whether grid animations are reduced (Settings › Reduce motion).
  bool get reduceMotion {
    try {
      if (SheetsUserDefaults.of(editor.services).reduceAnimations) return true;
    } catch (_) {}
    return WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
  }

  /// Runs the marching border while a collaborator edits a cell on the
  /// active sheet (static dashes with *Reduce motion*).
  void _updateMarch() {
    final needed =
        !_disposed &&
        cursorsOn(editor.activeSheetId).any((c) => c.cursor.editing) &&
        !reduceMotion;
    if (needed && _march == null) {
      _march = Timer.periodic(marchTick, (_) {
        // 8 px dash period per second.
        marchPhase = (marchPhase + 8 * marchTick.inMilliseconds / 1000) % 8;
        repaint.fire();
      });
    } else if (!needed && _march != null) {
      _march?.cancel();
      _march = null;
    }
  }

  /// Whether the marching border animation runs (tests).
  bool get marching => _march != null;

  // ---------------------------------------------------------- typing preview

  /// Applies a `typing` hint of [sessionId] (text null or empty clears).
  void setTyping(
    String sessionId, {
    required String sheetId,
    required String rowId,
    required String colId,
    required String? text,
  }) {
    if (text == null || text.isEmpty) {
      if (typing.remove(sessionId) != null) repaint.fire();
      return;
    }
    typing[sessionId] = (
      sheetId: sheetId,
      rowId: rowId,
      colId: colId,
      text: text.length > 200 ? text.substring(0, 200) : text,
      at: DateTime.now(),
    );
    repaint.fire();
  }

  /// The typing preview of [c], when it still edits that cell.
  TypingPreview? typingOf(RemoteCursorView c, DateTime now) {
    final t = typing[c.sessionId];
    if (t == null || !c.cursor.editing) return null;
    if (t.sheetId != c.cursor.sheetId ||
        t.rowId != c.cursor.activeRowId ||
        t.colId != c.cursor.activeColId) {
      return null;
    }
    if (now.difference(t.at) > typingLifetime) return null;
    return t;
  }

  // ------------------------------------------------------------ id mapping

  /// The grid rectangle of [r] on [sheet]; open bounds span the sheet, an
  /// unknown bound falls back to the known one (Sheets 10 §1.1). Null when
  /// nothing of the range is known.
  static GridRect? rectOf(SheetModel sheet, PresenceRange r) {
    final rows = sheet.rows;
    final cols = sheet.columns;
    if (rows.length == 0 || cols.length == 0) return null;
    (int, int)? span(AxisIndex axis, String? a, String? b) {
      if (a == null && b == null) return (0, axis.length - 1);
      final i = a == null ? -1 : axis.indexOf(a);
      final j = b == null ? -1 : axis.indexOf(b);
      if (i < 0 && j < 0) return null;
      final x = i < 0 ? j : i;
      final y = j < 0 ? i : j;
      return x <= y ? (x, y) : (y, x);
    }

    final rs = span(rows, r.r1, r.r2);
    final cs = span(cols, r.c1, r.c2);
    if (rs == null || cs == null) return null;
    return GridRect(rs.$1, cs.$1, rs.$2, cs.$2);
  }

  /// The active cell of [c] on [sheet] (null when unknown).
  static (int, int)? activeOf(SheetModel sheet, SheetsPresenceCursor c) {
    if (!c.hasActiveCell) return null;
    final r = sheet.rows.indexOf(c.activeRowId!);
    final col = sheet.columns.indexOf(c.activeColId!);
    if (r < 0 || col < 0) return null;
    return (r, col);
  }

  /// "Sheet1!B4" of a cursor's active cell (or the sheet name).
  String? locationOf(SheetsPresenceCursor c) {
    final sheet = editor.model.sheet(c.sheetId);
    if (sheet == null) return null;
    final a = activeOf(sheet, c);
    if (a == null) return sheet.name;
    return '${sheet.name}!${CellPos(a.$1, a.$2).a1}';
  }

  String? _detailOf(Participant p) {
    if (p.sessionId == selfSessionId) return null;
    if (p.state == PresenceState.idle ||
        p.state == PresenceState.away ||
        p.state == PresenceState.offline) {
      return null;
    }
    final c = SheetsPresenceCursor.tryParse(p.cursorJson);
    if (c == null) return null;
    final l = editor.l10n;
    final loc = locationOf(c);
    String? detail;
    if (c.route == 'script') {
      detail = l.presenceInScriptEditor;
    } else if (loc == null) {
      detail = null;
    } else if (c.editing) {
      detail = l.presenceTypingIn(loc);
    } else if (p.mode == 'viewing') {
      detail = l.presenceViewingSheet(editor.model.sheet(c.sheetId)!.name);
    } else {
      detail = l.presenceEditingCell(loc);
    }
    if (c.following != null && c.following == selfSessionId) {
      return detail == null
          ? l.presenceFollowingYou
          : '$detail · ${l.presenceFollowingYou}';
    }
    return detail;
  }

  // ------------------------------------------------------------ jump/follow

  RemoteCursorView? cursorOf(String sessionId) => _cursors[sessionId];

  /// Activates the participant's sheet, scrolls their active cell into view
  /// (no selection change) and flashes their cursor twice (Sheets 10 §1.4).
  bool jumpTo(String sessionId) {
    final c = _cursors[sessionId];
    if (c == null) return false;
    _apply(() {
      if (c.cursor.sheetId != editor.activeSheetId) {
        editor.activateSheet(c.cursor.sheetId);
      }
      final sheet = editor.activeSheet;
      final a = sheet == null ? null : activeOf(sheet, c.cursor);
      if (a != null) editor.revealCell(a.$1, a.$2);
    });
    _startFlash(sessionId);
    return true;
  }

  void _startFlash(String sessionId) {
    _flash?.cancel();
    flashSession = sessionId;
    var ticks = 0;
    flashOn = true;
    repaint.fire();
    _flash = Timer.periodic(const Duration(milliseconds: 250), (t) {
      ticks++;
      flashOn = !flashOn;
      if (ticks >= 4) {
        t.cancel();
        flashSession = null;
        flashOn = false;
      }
      repaint.fire();
    });
  }

  /// Follows [sessionId] (Sheets 10 §1.5).
  bool follow(String sessionId) {
    if (sessionId == selfSessionId || !_cursors.containsKey(sessionId)) {
      return false;
    }
    following.value = sessionId;
    _presence?.follow(sessionId);
    HardwareKeyboard.instance.addHandler(_onKey);
    _applyFollow(_cursors[sessionId]!.cursor);
    _publish();
    notifyListeners();
    return true;
  }

  /// Stops following.
  void unfollow() {
    if (following.value == null) return;
    following.value = null;
    _followScroll = null;
    _presence?.follow(null);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _publish();
    if (!_disposed) notifyListeners();
  }

  bool _onKey(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      unfollow();
    }
    return false;
  }

  void _apply(void Function() f) {
    _applying = true;
    try {
      f();
    } finally {
      _applying = false;
    }
  }

  void _applyFollow(SheetsPresenceCursor c) {
    _apply(() {
      if (c.sheetId != editor.activeSheetId &&
          editor.model.sheet(c.sheetId) != null) {
        editor.activateSheet(c.sheetId);
      }
      final sheet = editor.activeSheet;
      if (sheet == null) return;
      final v = c.viewport;
      final top = v == null ? -1 : sheet.rows.indexOf(v.topRowId);
      final left = v == null ? -1 : sheet.columns.indexOf(v.leftColId);
      if (top >= 0 && left >= 0) {
        // Align their top-left; we keep our zoom.
        final z = editor.scroll.zoom;
        final fr = sheet.record?.frozenRows ?? 0;
        final fc = sheet.record?.frozenColumns ?? 0;
        final y = (sheet.rows.offsetOf(top) - sheet.rows.offsetOf(fr)) * z;
        final x =
            (sheet.columns.offsetOf(left) - sheet.columns.offsetOf(fc)) * z;
        editor.scroll.jumpTo(x < 0 ? 0 : x, y < 0 ? 0 : y);
      } else {
        final a = activeOf(sheet, c);
        if (a != null) editor.revealCell(a.$1, a.$2);
      }
    });
    // Scroll may settle after layout; remember where we put it.
    _followScroll = (editor.scroll.x, editor.scroll.y);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (following.value != null) {
        _followScroll = (editor.scroll.x, editor.scroll.y);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    HardwareKeyboard.instance.removeHandler(_onKey);
    editor.removeListener(_onLocal);
    editor.editor.removeListener(_onLocal);
    editor.scroll.removeListener(_onScroll);
    _presence?.removeListener(_onRemote);
    if (_presence?.detailOf == _detailOf) _presence?.detailOf = null;
    _flash?.cancel();
    _flagTimer?.cancel();
    _viewportTimer?.cancel();
    _march?.cancel();
    cursors.dispose();
    following.dispose();
    repaint.dispose();
    super.dispose();
  }
}
