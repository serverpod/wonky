import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_app/wonky_app.dart' show UndoStackKey;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/themes.dart' show BoxTextStyle, SuRect;
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoEntry;
import 'package:wonky_revlog/rows.dart' show RowOp;

import '../../l10n/slides_l10n.dart';
import '../canvas/slide_canvas_controller.dart';
import '../editor_screen/deck_editor_controller.dart';
import '../selection/slide_elements.dart';
import 'slide_text_editor.dart';

/// One text body a soft lock covers (Slides 02 §4.4, 09 §2.1): the text of
/// an element, one table cell, or one slide's speaker notes.
@immutable
class TextLockTarget {
  /// The text body of element [elementId].
  const TextLockTarget.element(String this.elementId)
    : kind = 'text',
      rowId = null,
      columnId = null,
      slideId = null;

  /// Table [elementId]'s cell ([rowId], [columnId]).
  const TextLockTarget.cell(
    String this.elementId,
    String this.rowId,
    String this.columnId,
  ) : kind = 'tableCell',
      slideId = null;

  /// The speaker notes of [slideId].
  const TextLockTarget.notes(String this.slideId)
    : kind = 'notes',
      elementId = null,
      rowId = null,
      columnId = null;

  /// `text`, `tableCell` or `notes` (the claim kinds of 09 §2.1).
  final String kind;
  final String? elementId;
  final String? rowId;
  final String? columnId;
  final String? slideId;

  /// A key unique per body.
  String get key => switch (kind) {
    'tableCell' => 'tableCell:$elementId|$rowId|$columnId',
    'notes' => 'notes:$slideId',
    _ => 'text:$elementId',
  };

  @override
  bool operator ==(Object other) => other is TextLockTarget && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'TextLockTarget($key)';
}

/// The soft-lock hook of text editing (02 §4.4, 09; built by SL-21).
///
/// [request] is asked before a body is edited (double-click, Enter, typing
/// into a selected box, a click into an empty placeholder): SL-21 checks
/// the other participants' claims, shows the soft-lock popover ("Anna is
/// editing this text." *Cancel* / *Edit anyway*, 04 §13.11) and completes
/// with the answer. [claim]/[release] announce this user's editing;
/// [heldBy] names another participant editing a body, so format commands
/// on whole elements skip it (03 §6.1). The default allows everything.
///
/// The editors call the `…Target` variants, which name the exact body (a
/// table cell, a slide's notes) and default to the element methods; the
/// soft locks of SL-21 (`features/collab/soft_locks.dart`) override them.
class TextEditLocks {
  const TextEditLocks();

  /// Whether this user may edit [elementId] now.
  FutureOr<bool> request(String elementId) => true;

  /// This user started editing [elementId].
  void claim(String elementId) {}

  /// This user stopped editing [elementId].
  void release(String elementId) {}

  /// The display name of someone else editing [elementId], or null.
  String? heldBy(String elementId) => null;

  /// Whether this user may edit [target] now (may ask with the soft-lock
  /// popover and complete later).
  FutureOr<bool> requestTarget(TextLockTarget target) {
    final id = target.elementId;
    return id == null ? true : request(id);
  }

  /// This user started editing [target]. [activity] notifies on input
  /// (keeps the claim from going idle, 09 §2.1); [stop] ends the editing
  /// (the user chose *Stop editing* after losing a claim race).
  void claimTarget(
    TextLockTarget target, {
    Listenable? activity,
    VoidCallback? stop,
  }) {
    final id = target.elementId;
    if (id != null) claim(id);
  }

  /// This user stopped editing [target].
  void releaseTarget(TextLockTarget target) {
    final id = target.elementId;
    if (id != null) release(id);
  }

  /// The display name of someone else editing [target], or null.
  String? heldByTarget(TextLockTarget target) {
    final id = target.elementId;
    return id == null ? null : heldBy(id);
  }

  /// Notifies when claims change (null: never).
  Listenable? get changes => null;
}

/// The text editing state of an open deck (created on first use; shared
/// by the canvas, the commands and the chrome).
SlideTextEditing textEditingOf(DeckEditorController editor) =>
    _hosts[editor] ??= SlideTextEditing._(editor);

final Expando<SlideTextEditing> _hosts = Expando('slidesTextEditing');

/// Text editing of one open deck (03 §6.1, §3.4): at most one
/// [SlideTextEditController] at a time over the current slide's selected
/// text box, shape or text placeholder. Starting and ending sessions keeps
/// the editor's selection and `textEditing` flag in step (the canvas,
/// toolbar and inspector follow them), routes typing writes to the undo
/// stack as coalesced "Typing" steps, asks [locks] before editing, and
/// deletes a text box that is still empty when editing ends (together with
/// its creation step when nothing else happened since).
///
/// Editing ends when the selection changes, the slide changes, the element
/// disappears, the user loses edit access or [end] is called (Esc, a click
/// outside, `slides.text.exitEditing`).
class SlideTextEditing extends ChangeNotifier {
  SlideTextEditing._(this.editor) {
    editor.addListener(_onEditor);
  }

  final DeckEditorController editor;

  /// The soft-lock hook (SL-21 replaces the default).
  TextEditLocks locks = const TextEditLocks();

  SlideTextEditController? _active;
  final ValueNotifier<String?> _editing = ValueNotifier(null);
  SuRect? _lastFrame;
  GlobalKey _layoutKey = GlobalKey(debugLabel: 'slides.textLayout');
  Offset? _caretPoint;
  bool _starting = false;
  bool _disposed = false;

  /// The editing session, or null.
  SlideTextEditController? get active => _active;

  /// Whether a body is being edited.
  bool get isEditing => _active != null;

  /// The element being edited, or null.
  String? get elementId => _active?.elementId;

  /// The element being edited, as a listenable (the canvas rebuilds only
  /// when editing starts or ends; caret moves notify this host).
  ValueListenable<String?> get editing => _editing;

  /// The key of the overlay's document layout (click-to-caret).
  GlobalKey get documentLayoutKey => _layoutKey;

  /// The keyboard focus of the overlay's editor (the canvas holds the
  /// focus when editing starts, so autofocus wouldn't take it).
  final FocusNode editorFocus = FocusNode(debugLabel: 'slides.textEditor');

  /// Keys of a table cell being edited (SL-15: Tab / Shift+Tab and arrows
  /// at the text edges move between cells); returns whether [event] was
  /// handled. Set by the table feature.
  static bool Function(SlideTextEditing host, KeyEvent event)? cellKeys;

  /// Esc while editing a table cell (SL-15: the cell becomes the cell
  /// selection). Set by the table feature.
  static void Function(
    SlideTextEditing host,
    String elementId,
    String rowId,
    String columnId,
  )?
  onCellExit;

  /// Additions to every editing session (SL-44: spelling squiggles),
  /// registered by other features; each may return null.
  static final List<
    SlideTextEditAddon? Function(
      SlideTextEditing host,
      SlideTextEditController c,
    )
  >
  addonFactories = [];

  /// The active cell of a selected table that typing edits (SL-15), or
  /// null. Set by the table feature.
  static ({String rowId, String columnId})? Function(
    DeckEditorController editor,
    String tableId,
  )?
  activeCellOf;

  /// Whether [e] holds a text body that the overlay edits (text boxes,
  /// shapes, text placeholders; table cells are edited with `begin(cell)`).
  static bool isTextCapable(ResolvedElement e) =>
      e.textStyles != null &&
      (e.record.kind == ElementKind.text || e.record.kind == ElementKind.shape);

  /// The resolved element [id] of the current slide (or edited layout or
  /// master, SL-28).
  ResolvedElement? element(String id) {
    final s = editor.surfaceId;
    if (s == null) return null;
    final slide = editor.resolver.resolve(s);
    return slide == null ? null : SlideElements.of(slide)[id];
  }

  /// Whether [id] can be edited now (edit access, a canvas, a visible,
  /// unlocked, text-capable element of the current slide; with [cell] a
  /// table's cell).
  bool canEdit(String id, {bool cell = false}) {
    if (!editor.canEdit || SlideCanvasController.of(editor) == null) {
      return false;
    }
    final e = element(id);
    return e != null &&
        !e.hidden &&
        !e.locked &&
        (cell ? e.record.kind == ElementKind.table : isTextCapable(e));
  }

  /// The table cell being edited (`rowId`, `columnId`), or null.
  ({String rowId, String columnId})? get cell {
    final c = _active;
    return c == null || !c.isCell
        ? null
        : (rowId: c.cellRowId!, columnId: c.cellColumnId!);
  }

  /// The single selected element that typing or Enter would edit, or null.
  String? get editableSelection {
    final ids = editor.selectedElementIds;
    if (ids.length != 1 || isEditing) return null;
    return canEdit(ids.single) ? ids.single : null;
  }

  /// Starts editing [id]: the caret goes to slide point [at] (once the
  /// overlay is laid out), to body offset [caretOffset], or to the end;
  /// [insert] is typed first (type-to-edit, 03 §3.4); [selectAll] selects
  /// the whole body. Returns whether editing started.
  Future<bool> begin(
    String id, {
    Offset? at,
    int? caretOffset,
    String? insert,
    bool selectAll = false,
    ({String rowId, String columnId})? cell,
  }) async {
    if (!canEdit(id, cell: cell != null)) return false;
    final current = _active;
    if (current != null &&
        current.elementId == id &&
        current.cellRowId == cell?.rowId &&
        current.cellColumnId == cell?.columnId) {
      if (at != null) placeCaretAt(at);
      if (caretOffset != null) current.selectRange(caretOffset);
      if (insert != null) current.insertText(insert);
      if (selectAll) current.selectAll();
      return true;
    }
    end(select: false);
    final target = cell == null
        ? TextLockTarget.element(id)
        : TextLockTarget.cell(id, cell.rowId, cell.columnId);
    final allowed = locks.requestTarget(target);
    if (!(allowed is bool ? allowed : await allowed)) return false;
    if (!canEdit(id, cell: cell != null) || isEditing) return false;
    final canvas = SlideCanvasController.of(editor)!;
    final slideId = editor.surfaceId!;
    final l = slidesL10nOf(editor.services);
    late final SlideTextEditController c;
    c = SlideTextEditController(
      session: editor.session,
      renderer: canvas.renderer,
      slideId: slideId,
      elementId: id,
      caretOffset: caretOffset,
      cellRowId: cell?.rowId,
      cellColumnId: cell?.columnId,
      onCommitted: (plan) => recordTypingStep(
        editor.services.undo,
        plan,
        coalesceKey: c.coalesceKey,
        label: l.undoTyping,
      ),
    );
    for (final f in addonFactories) {
      final a = f(this, c);
      if (a != null) c.addons.add(a);
    }
    c.addListener(_onGeometry);
    c.composer.selectionNotifier.addListener(_notify);
    c.composer.preferences.addListener(_notify);
    _layoutKey = GlobalKey(debugLabel: 'slides.textLayout');
    _caretPoint = at;
    _active = c;
    _starting = true;
    try {
      final parent = canvas.elements?.parentOf(id)?.id;
      canvas.selection.select([id], enteredGroup: parent);
      editor.textEditing = true;
      editor.selectElements([id]);
    } finally {
      _starting = false;
    }
    canvas.liveFrameOf = _liveFrame;
    _lastFrame = c.geometry.frame;
    _editing.value = id;
    locks.claimTarget(
      target,
      activity: c,
      stop: () {
        if (identical(_active, c)) end();
      },
    );
    if (insert != null) c.insertText(insert);
    if (selectAll) c.selectAll();
    _notify();
    return true;
  }

  ElementFrame? _liveFrame(String id) {
    final c = _active;
    if (c == null || c.elementId != id) return null;
    final e = element(id);
    if (e == null) return null;
    return ElementFrame.of(
      c.geometry.frame,
      rotation: e.rotation,
      flipH: e.flipH,
      flipV: e.flipV,
    );
  }

  /// Puts the caret at slide point [p] (the overlay's nearest position).
  /// Returns whether the overlay was laid out to do so.
  bool placeCaretAt(Offset p) {
    final c = _active;
    final layout = _layoutKey.currentState;
    if (c == null || layout is! DocumentLayout) {
      _caretPoint = p;
      return false;
    }
    _caretPoint = null;
    final inv = Matrix4.tryInvert(c.geometry.textToSlide);
    if (inv == null) return false;
    final local = MatrixUtils.transformPoint(inv, p);
    final pos = (layout as DocumentLayout).getDocumentPositionNearestToOffset(
      local,
    );
    if (pos == null) return false;
    c.editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(position: pos),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
    return true;
  }

  /// Before the context menu of a right-click at slide point [p]: a click
  /// outside the selected text puts the caret there (so the menu's
  /// spelling suggestions are those of the word under the pointer, SL-44);
  /// a click inside a selection keeps it.
  void prepareContextMenu(Offset p) {
    final c = _active;
    final layout = _layoutKey.currentState;
    if (c == null || layout is! DocumentLayout) return;
    final inv = Matrix4.tryInvert(c.geometry.textToSlide);
    if (inv == null) return;
    final local = MatrixUtils.transformPoint(inv, p);
    final pos = (layout as DocumentLayout).getDocumentPositionNearestToOffset(
      local,
    );
    final range = c.selectionRange;
    if (pos == null || range == null) return;
    final at = c.offsetOf(pos);
    if (range.$1 != range.$2 && at >= range.$1 && at <= range.$2) return;
    placeCaretAt(p);
  }

  /// Called after the overlay was laid out: focuses the editor and applies
  /// a caret point requested before layout.
  void afterLayout() {
    if (_active != null && !editorFocus.hasFocus) editorFocus.requestFocus();
    applyPendingCaret();
  }

  /// Applies a caret point requested before the overlay was laid out.
  void applyPendingCaret() {
    final p = _caretPoint;
    if (p != null) placeCaretAt(p);
  }

  /// Whether slide point [p] is inside the box being edited (a table
  /// cell's box while editing a cell).
  bool hits(Offset p) {
    final f = elementId == null ? null : _liveFrame(elementId!);
    if (f == null || !SlideCanvasController.containsPoint(f, p.dx, p.dy)) {
      return false;
    }
    final box = _active?.geometry.cellBox;
    if (box == null) return true;
    final l = SlideCanvasController.slideToLocal(f, p);
    return l.dx >= box.x &&
        l.dx <= box.x + box.width &&
        l.dy >= box.y &&
        l.dy <= box.y + box.height;
  }

  /// Whether slide point [p] is over the laid-out text of the overlay
  /// (super_editor handles the pointer there).
  bool hitsText(Offset p) {
    final c = _active;
    if (c == null) return false;
    final inv = Matrix4.tryInvert(c.geometry.textToSlide);
    if (inv == null) return false;
    final l = MatrixUtils.transformPoint(inv, p);
    return l.dx >= 0 &&
        l.dy >= 0 &&
        l.dx <= c.geometry.spec.width &&
        l.dy <= c.geometry.contentHeight;
  }

  /// The soft-lock target of editing session [c].
  static TextLockTarget lockTargetOf(SlideTextEditController c) => c.isCell
      ? TextLockTarget.cell(c.elementId, c.cellRowId!, c.cellColumnId!)
      : TextLockTarget.element(c.elementId);

  /// Writes pending typing now (before undo/redo, formatting, exit).
  SlidesPlan? commit() => _active?.commit();

  /// Ends editing: pending typing is written; with [select] the box stays
  /// selected and the canvas gets the keyboard back (Esc, 03 §3.3). A text
  /// box left empty is deleted (03 §6.1).
  void end({bool select = true}) {
    final c = _active;
    if (c == null) return;
    _active = null;
    _caretPoint = null;
    c.close();
    c.removeListener(_onGeometry);
    c.composer.selectionNotifier.removeListener(_notify);
    c.composer.preferences.removeListener(_notify);
    final canvas = SlideCanvasController.of(editor);
    if (canvas != null && canvas.liveFrameOf == _liveFrame) {
      canvas.liveFrameOf = null;
    }
    locks.releaseTarget(lockTargetOf(c));
    _editing.value = null;
    _starting = true;
    try {
      if (editor.textEditing) {
        editor.textEditing = false;
        editor.selectElements(
          select ? [c.elementId] : editor.selectedElementIds,
        );
      }
      _deleteIfEmpty(c.elementId);
    } finally {
      _starting = false;
    }
    if (select) editor.canvasFocus.requestFocus();
    // The overlay still shows the controller until the next frame.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => c.dispose())
      ..scheduleFrame();
    _notify();
  }

  /// Deletes text box [id] when its body is blank; its creation step goes
  /// with it when it is still the top undo step (03 §6.1).
  void _deleteIfEmpty(String id) {
    final e = editor.model.element(id);
    if (e == null ||
        e.kind != ElementKind.text ||
        e.placeholderType != null ||
        e.placeholderOf != null ||
        !SlidesText.isBlank(e.text) ||
        !editor.canEdit) {
      return;
    }
    final undo = editor.services.undo;
    final key = UndoStackKey(editor.session.itemUuid.uuid);
    final steps = undo.undoStepsOf(key);
    final top = steps.isEmpty ? null : steps.last;
    final created =
        top != null &&
        top.entries.any(
          (entry) =>
              entry is SlidesRowsUndoEntry &&
              entry.changes.any(
                (ch) => ch.op == RowOp.insert && ch.rowId == id,
              ),
        );
    try {
      final plan = editor.session.execute(DeleteElements([id]));
      if (created) {
        undo.discardTop(top.id, stack: key);
      } else if (!plan.isEmpty) {
        final t = undo.beginTransaction(
          slidesL10nOf(editor.services).cmdEditDelete,
          stack: key,
        );
        t.record(SlidesTypingUndoEntry(plan.changes, label: plan.label));
        t.commit();
      }
    } on PlanException {
      // Already gone (a collaborator deleted it).
    }
    editor.selectElements(const []);
  }

  void _onEditor() {
    if (_starting || _disposed) return;
    final c = _active;
    if (c == null) return;
    if (!editor.textEditing ||
        !editor.canEdit ||
        editor.surfaceId != c.slideId ||
        !editor.selectedElementIds.contains(c.elementId) ||
        editor.model.element(c.elementId) == null) {
      end(select: false);
    }
  }

  void _onGeometry() {
    final f = _active?.geometry.frame;
    final l = _lastFrame;
    if (f == null ||
        l == null ||
        (f.x - l.x).abs() > 1e-6 ||
        (f.y - l.y).abs() > 1e-6 ||
        (f.width - l.width).abs() > 1e-6 ||
        (f.height - l.height).abs() > 1e-6) {
      _lastFrame = f;
      SlideCanvasController.of(editor)?.refresh();
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// The box text properties of [e] with the theme defaults of its kind.
  static BoxTextStyle boxStyleOf(ResolvedElement e, ResolvedSlide slide) {
    final d = e.record.kind == ElementKind.shape
        ? slide.theme.shapeStyles.shape
        : slide.theme.shapeStyles.text;
    return (d.textStyle ?? BoxTextStyle.empty).merge(e.textStyle);
  }

  @override
  void dispose() {
    _disposed = true;
    editor.removeListener(_onEditor);
    // The editor closes: write pending typing, notify nobody.
    final c = _active;
    _active = null;
    if (c != null) {
      c.close();
      locks.releaseTarget(lockTargetOf(c));
      WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
    }
    if (_hosts[editor] == this) _hosts[editor] = null;
    _editing.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) => editorFocus.dispose());
    super.dispose();
  }
}

/// Type-to-edit (03 §3.4): a printable character (no Mod/Ctrl/Alt) with
/// exactly one text-capable element selected starts editing it with the
/// caret at the end and types the character — an empty placeholder's prompt
/// is replaced. Returns whether [event] was taken.
bool typeToEdit(DeckEditorController editor, KeyEvent event) {
  if (event is! KeyDownEvent) return false;
  final ch = event.character;
  if (ch == null || ch.isEmpty || ch.trim().isEmpty) return false;
  if (ch.runes.any((r) => r < 0x20 || r == 0x7F)) return false;
  final k = HardwareKeyboard.instance;
  if (k.isControlPressed || k.isMetaPressed || k.isAltPressed) return false;
  final host = textEditingOf(editor);
  final id = host.editableSelection;
  if (id == null) {
    // A selected table types into its active cell (SL-15, 03 §6.6).
    final ids = editor.selectedElementIds;
    if (ids.length != 1 || host.isEditing) return false;
    final cell = SlideTextEditing.activeCellOf?.call(editor, ids.single);
    if (cell == null || !host.canEdit(ids.single, cell: true)) return false;
    unawaited(host.begin(ids.single, insert: ch, cell: cell));
    return true;
  }
  unawaited(host.begin(id, insert: ch));
  return true;
}
