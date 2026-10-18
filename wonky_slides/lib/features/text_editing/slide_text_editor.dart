import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_app/wonky_app.dart' show UndoService;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/scene.dart' show TextBody;
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoEntry;

import '../model/deck_session.dart';
import '../stage/slide_renderer.dart';
import 'slides_delta_mapper.dart';
import 'slides_text_components.dart';
import 'slides_text_reactions.dart';
import 'text_edit_geometry.dart';

/// A per-session addition to a text editor (SL-44: the spelling
/// squiggles of `features/spellcheck/`): an extra style phase of the
/// editor, disposed with the session's controller.
abstract class SlideTextEditAddon {
  /// An extra style phase of the editor's layout, or null.
  SingleColumnLayoutStylePhase? get stylePhase => null;

  /// Releases the addon (the session ended).
  void dispose() {}
}

/// One text editing session over one text-capable element (03 §6.1): the
/// super_editor document of the body, its editor and composer, the
/// overlay's style phase, the live geometry (from the scene builder) and
/// the write path.
///
/// Edits are kept in the document and written with `SetText` after
/// [commitDelay] of idle typing and on [close] (02 §4.4); each write is
/// reported to [onCommitted] (the host records it as a `slides.rows` undo
/// step with [coalesceKey], so a typing burst is one step, suite 08 §3.1
/// rule 4 — see [recordTypingStep]). Changes of the body from elsewhere
/// (undo, redo, a collaborator) are patched into the document without
/// moving the caret more than needed.
///
/// Spike SL-4 (Slides 12 §4.3); SL-13 builds the text editing feature on it.
class SlideTextEditController extends ChangeNotifier {
  SlideTextEditController({
    required this.session,
    required this.renderer,
    required this.slideId,
    required this.elementId,
    this.onCommitted,
    this.commitDelay = const Duration(milliseconds: 300),
    int? caretOffset,
    this.mapper = const SlidesDeltaMapper(),
    this.cellRowId,
    this.cellColumnId,
  }) : assert((cellRowId == null) == (cellColumnId == null)) {
    final slide = _slide()!;
    _stored = _storedText();
    document = mapper.documentFromBody(TextBody.fromJson(_stored));
    composer = MutableDocumentComposer(
      initialSelection: DocumentSelection.collapsed(
        position: positionAt(caretOffset),
      ),
    );
    editor = createSlidesTextEditor(document: document, composer: composer);
    _geometry = _geometryOf(slide, null)!;
    stylePhase = SlidesTextStylePhase(
      spec: _geometry.spec,
      engine: renderer.textLayout,
      mapper: mapper,
    );
    editor.addListener(FunctionalEditListener(_onEdits));
    session.model.addListener(_onBatch);
  }

  final DeckSession session;
  final SlideRenderer renderer;
  final String slideId;
  final String elementId;
  final SlidesDeltaMapper mapper;

  /// The table cell being edited (SL-15): its row and column axis ids;
  /// null for an element's own body.
  final String? cellRowId;
  final String? cellColumnId;

  /// Whether a table cell is being edited.
  bool get isCell => cellRowId != null;

  /// The cell's `TextNode.partId` (`"<rowId>|<columnId>"`), or null.
  String? get cellPartId => isCell ? '$cellRowId|$cellColumnId' : null;

  /// The body the session writes.
  TextTarget get target => isCell
      ? CellText(elementId, cellRowId!, cellColumnId!)
      : ElementText(elementId);

  /// The stored body (the element's text or the cell's).
  String? _storedText() => isCell
      ? session.model.indexes
            .table(elementId)
            .cell(cellRowId!, cellColumnId!)
            ?.text
      : session.model.element(elementId)?.text;

  TextEditGeometry? _geometryOf(ResolvedSlide slide, String? json) {
    final element = slide.element(elementId);
    if (element == null) return null;
    return isCell
        ? TextEditGeometry.ofCell(
            slide: slide,
            element: element,
            engine: renderer.textLayout,
            deck: renderer.model,
            rowId: cellRowId!,
            columnId: cellColumnId!,
            textJson: json,
          )
        : TextEditGeometry.of(
            slide: slide,
            element: element,
            engine: renderer.textLayout,
            deck: renderer.model,
            textJson: json,
          );
  }

  /// Called after every write with the plan (undo recording).
  final void Function(SlidesPlan plan)? onCommitted;

  /// Idle time before typing is written (02 §4.4).
  final Duration commitDelay;

  late final MutableDocument document;
  late final MutableDocumentComposer composer;
  late final Editor editor;
  late final SlidesTextStylePhase stylePhase;

  /// Additions of other features (SL-44: spelling), added by the host when
  /// the session starts and disposed with it.
  final List<SlideTextEditAddon> addons = [];

  /// The undo coalescing key of this body's typing.
  String get coalesceKey => isCell
      ? 'slides.text:$elementId:$cellRowId:$cellColumnId'
      : 'slides.text:$elementId';

  late TextEditGeometry _geometry;

  /// Where the text sits and how it is laid out (follows every edit).
  TextEditGeometry get geometry => _geometry;

  String? _stored;
  String? _pending;
  Timer? _timer;
  bool _patching = false;
  bool _closed = false;

  /// Whether edits wait to be written.
  bool get hasPendingEdits => _pending != null;

  /// The body being edited (normalized Delta JSON).
  String get json => _pending ?? mapper.jsonOf(document);

  /// The document position of [offset] in the body's plain text (null =
  /// the end).
  DocumentPosition positionAt(int? offset) {
    var rest = offset;
    TextNode? last;
    for (final node in document) {
      if (node is! TextNode) continue;
      last = node;
      final len = node.text.length;
      if (rest != null && rest <= len) {
        return DocumentPosition(
          nodeId: node.id,
          nodePosition: TextNodePosition(offset: rest),
        );
      }
      if (rest != null) rest -= len + 1;
    }
    return DocumentPosition(
      nodeId: last!.id,
      nodePosition: TextNodePosition(offset: last.text.length),
    );
  }

  /// The body offset (plain text of the Delta, paragraphs joined by
  /// `"\n"`) of document position [p].
  int offsetOf(DocumentPosition p) {
    var at = 0;
    for (final node in document) {
      if (node is! TextNode) continue;
      if (node.id == p.nodeId) {
        final np = p.nodePosition;
        final o = np is TextNodePosition ? np.offset : node.text.length;
        return at + o.clamp(0, node.text.length);
      }
      at += node.text.length + 1;
    }
    return at;
  }

  /// The selected range as body offsets `(start, end)` (start ≤ end), or
  /// null without a selection.
  (int, int)? get selectionRange {
    final s = composer.selection;
    if (s == null) return null;
    final a = offsetOf(s.base), b = offsetOf(s.extent);
    return a <= b ? (a, b) : (b, a);
  }

  /// Selects the body offsets [start]…[end] (a caret when equal).
  void selectRange(int start, [int? end]) {
    final sel = DocumentSelection(
      base: positionAt(start),
      extent: positionAt(end ?? start),
    );
    editor.execute([
      ChangeSelectionRequest(
        sel,
        SelectionChangeType.placeCaret,
        SelectionReason.contentChange,
      ),
    ]);
  }

  /// Selects the whole body (Mod+A while editing, 03 §3.3).
  void selectAll() {
    final len = mapper
        .bodyOf(document)
        .ops
        .fold<int>(0, (n, op) => n + ((op['insert'] as String?)?.length ?? 0));
    selectRange(0, len > 0 ? len - 1 : 0);
  }

  /// Types [text] at the caret (replacing a selection) with the typing
  /// attributes (type-to-edit, 03 §3.4).
  void insertText(String text) {
    final sel = composer.selection;
    if (sel == null) return;
    if (!sel.isCollapsed) {
      editor.execute([
        DeleteContentRequest(documentRange: sel.normalize(document)),
      ]);
    }
    final caret = composer.selection?.extent ?? sel.extent;
    final np = caret.nodePosition;
    if (np is! TextNodePosition) return;
    editor.execute([
      InsertTextRequest(
        documentPosition: caret,
        textToInsert: text,
        attributions: {...composer.preferences.currentAttributions},
      ),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: caret.nodeId,
            nodePosition: TextNodePosition(offset: np.offset + text.length),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
  }

  ResolvedSlide? _slide() => renderer.resolver.resolve(slideId);

  void _onEdits(List<EditEvent> changes) {
    if (_patching || _closed) return;
    if (!changes.any((e) => e is DocumentEdit)) return;
    final next = mapper.jsonOf(document);
    if (next == (_pending ?? _stored)) return;
    _pending = next;
    _relayout(next);
    _timer?.cancel();
    _timer = Timer(commitDelay, commit);
  }

  void _relayout(String? json) {
    final slide = _slide();
    if (slide == null) return;
    final g = _geometryOf(slide, json);
    if (g == null) return;
    _geometry = g;
    stylePhase.spec = g.spec;
    notifyListeners();
  }

  /// Writes pending edits now (idle timer, exit, before undo).
  SlidesPlan? commit() {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    if (pending == null) return null;
    _pending = null;
    if (_same(pending, _storedText())) return null;
    final SlidesPlan plan;
    try {
      _patching = true;
      plan = session.execute(SetText(target, pending));
    } finally {
      _patching = false;
    }
    _stored = _storedText();
    if (!plan.isEmpty) onCommitted?.call(plan);
    return plan;
  }

  void _onBatch(DeckChangeBatch batch) {
    if (_patching || _closed) return;
    final element = session.model.element(elementId);
    if (element == null) return;
    final text = _storedText();
    if (_same(text, _stored)) return;
    _stored = text;
    // Local edits that weren't written yet win (last writer wins on the
    // whole body; the soft lock makes concurrent edits rare, 02 §4.4).
    if (_pending != null) return;
    _replaceBody(TextBody.fromJson(text));
    _relayout(text);
  }

  /// Replaces the document's content with [body] (undo, redo, remote).
  void _replaceBody(TextBody body) {
    final old = document.toList();
    final fresh = mapper.nodesFromBody(body);
    final ops = <DocumentPatchOperation>[];
    for (var i = 0; i < fresh.length; i++) {
      if (i < old.length) {
        ops.add(ReplaceNodePatch(old[i].id, _withId(fresh[i], old[i].id)));
      } else {
        ops.add(InsertNodePatch(i, fresh[i]));
      }
    }
    for (var i = fresh.length; i < old.length; i++) {
      ops.add(DeleteNodePatch(old[i].id));
    }
    final ids = [
      for (var i = 0; i < fresh.length; i++)
        i < old.length ? old[i].id : fresh[i].id,
    ];
    final selection = composer.selection;
    DocumentSelection? after;
    if (selection != null) {
      DocumentPosition clamp(DocumentPosition p) {
        var index = ids.indexOf(p.nodeId);
        if (index < 0) index = ids.length - 1;
        final node = fresh[index] as TextNode;
        final o = p.nodePosition is TextNodePosition
            ? (p.nodePosition as TextNodePosition).offset
            : node.text.length;
        return DocumentPosition(
          nodeId: ids[index],
          nodePosition: TextNodePosition(offset: o.clamp(0, node.text.length)),
        );
      }

      after = DocumentSelection(
        base: clamp(selection.base),
        extent: clamp(selection.extent),
      );
    }
    _patching = true;
    try {
      editor.execute([
        ApplyDocumentPatchRequest(
          operations: ops,
          updateSelection: after != null,
          selectionAfter: after,
          resyncIme: true,
          tag: 'slides.text.external',
        ),
      ]);
    } finally {
      _patching = false;
    }
  }

  static DocumentNode _withId(DocumentNode n, String id) => switch (n) {
    ParagraphNode() => n.copyParagraphWith(id: id),
    ListItemNode() => n.copyListItemWith(id: id),
    TaskNode() => n.copyTaskWith(id: id),
    _ => n,
  };

  static bool _same(String? a, String? b) {
    if (a == b) return true;
    try {
      return sameDelta(
        SlidesText.normalize(SlidesText.parse(a)),
        SlidesText.normalize(SlidesText.parse(b)),
      );
    } on FormatException {
      return false;
    }
  }

  /// Ends the session: writes pending edits and detaches.
  SlidesPlan? close() {
    if (_closed) return null;
    final plan = commit();
    _closed = true;
    session.model.removeListener(_onBatch);
    return plan;
  }

  @override
  void dispose() {
    close();
    _timer?.cancel();
    for (final a in addons) {
      a.dispose();
    }
    addons.clear();
    editor.dispose();
    super.dispose();
  }
}

/// Records [plan] (a typing write) as one `slides.rows` undo step that
/// coalesces with the previous typing of the same element (one step per
/// burst, 03 §15).
void recordTypingStep(
  UndoService undo,
  SlidesPlan plan, {
  required String coalesceKey,
  String label = 'Typing',
}) {
  final t = undo.beginTransaction(label, coalesceKey: coalesceKey);
  t.record(SlidesTypingUndoEntry(plan.changes, label: label));
  t.commit();
}

/// A `slides.rows` entry of typing writes. Coalescing is the kit's
/// (`RowsUndoEntry.coalesce` composes the changes per row with
/// `composeRowChanges`: first `before`, last `after` per column), so one
/// burst of several writes of the same `text` column undoes to the state
/// before the first.
class SlidesTypingUndoEntry extends SlidesRowsUndoEntry {
  SlidesTypingUndoEntry(super.changes, {super.label});

  @override
  SlidesTypingUndoEntry withChanges(List<RowChange> changes) =>
      SlidesTypingUndoEntry(changes, label: label);
}

/// The text editing overlay (03 §6.1): super_editor, shrink-wrapped and
/// non-scrolling, laid out in slide units at the text's layout width and
/// transformed exactly like the static text (zoom × element transform ×
/// text origin), so line breaks, glyphs and baselines coincide with the
/// canvas rendering.
///
/// A full-size layer of the canvas stack, in the stage's coordinate space
/// (logical px = su × [zoom], slide origin top-left).
class SlideTextEditorOverlay extends StatelessWidget {
  const SlideTextEditorOverlay({
    super.key,
    required this.controller,
    required this.zoom,
    this.focusNode,
    this.autofocus = true,
    this.caretColor = const Color(0xFF2563EB),
    this.selectionColor = const Color(0x552563EB),
    this.onExit,
    this.onUndo,
    this.onRedo,
    this.onHostKey,
    this.documentLayoutKey,
  });

  final SlideTextEditController controller;

  /// Logical px per su.
  final double zoom;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color caretColor;
  final Color selectionColor;

  /// Esc (select the box, 03 §6.1).
  final VoidCallback? onExit;

  /// Mod+Z / Mod+Shift+Z: the shell's undo stack (pending typing is written
  /// first so the burst is its own step).
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  /// Keys the host handles before the editor (Tab → indent, Mod+Enter →
  /// exit, …); returns whether the key was handled.
  final bool Function(KeyEvent event)? onHostKey;

  /// The key of the editor's document layout (click-to-caret mapping).
  final GlobalKey? documentLayoutKey;

  /// Key of the editor (tests, driver).
  static const editorKey = ValueKey<String>('slides.textEditor');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final g = controller.geometry;
        final transform = Matrix4.diagonal3Values(zoom, zoom, 1)
          ..multiply(g.textToSlide);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: g.spec.width,
              child: Transform(transform: transform, child: _editor()),
            ),
          ],
        );
      },
    );
  }

  Widget _editor() {
    // Its own (non-scrolling) scrollable: super_editor attaches to the
    // nearest vertical Scrollable, which must not be the canvas's.
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SuperEditor(
          // Keep the selection while the focus is elsewhere (a menu, the
          // special characters or emoji dialog), like Write: Insert ›
          // Special characters and the spelling context menu act on it.
          selectionPolicies: const SuperEditorSelectionPolicies(
            clearSelectionWhenEditorLosesFocus: false,
            clearSelectionWhenImeConnectionCloses: false,
          ),
          key: editorKey,
          editor: controller.editor,
          documentLayoutKey: documentLayoutKey,
          focusNode: focusNode,
          autofocus: autofocus,
          inputSource: TextInputSource.ime,
          gestureMode: DocumentGestureMode.mouse,
          stylesheet: _stylesheet,
          customStylePhases: [
            controller.stylePhase,
            for (final a in controller.addons) ?a.stylePhase,
          ],
          componentBuilders: const [SlidesTextComponentBuilder()],
          selectionStyle: SelectionStyles(selectionColor: selectionColor),
          documentOverlayBuilders: [
            DefaultCaretOverlayBuilder(
              caretStyle: CaretStyle(
                // 2 logical px whatever the zoom.
                width: 2 / zoom,
                color: caretColor,
              ),
            ),
          ],
          keyboardActions: [_hostKeys, ..._imeActions],
          // Links don't open while editing (03 §6.9).
          contentTapDelegateFactories: const [],
        ),
      ],
    );
  }

  ExecutionInstruction _hostKeys({
    required SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      return ExecutionInstruction.continueExecution;
    }
    final host = onHostKey;
    if (host != null && host(keyEvent)) {
      return ExecutionInstruction.haltExecution;
    }
    final keyboard = HardwareKeyboard.instance;
    final mod = defaultTargetPlatform == TargetPlatform.macOS
        ? keyboard.isMetaPressed
        : keyboard.isControlPressed;
    final key = keyEvent.logicalKey;
    VoidCallback? action;
    if (key == LogicalKeyboardKey.escape && !mod) {
      action = onExit;
    } else if (mod && key == LogicalKeyboardKey.keyZ) {
      action = keyboard.isShiftPressed ? onRedo : onUndo;
    } else if (mod &&
        key == LogicalKeyboardKey.keyY &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      action = onRedo;
    }
    if (action == null) return ExecutionInstruction.continueExecution;
    controller.commit();
    action();
    return ExecutionInstruction.haltExecution;
  }

  static final _removed = <SuperEditorKeyboardAction>{
    undoWhenCmdZOrCtrlZIsPressed,
    redoWhenCmdShiftZOrCtrlShiftZIsPressed,
    collapseSelectionWhenEscIsPressed,
    // Bold and italic are the Slides format commands (one undo step each,
    // 03 §15): the keys bubble to the shell's keymap.
    cmdBToToggleBold,
    cmdIToToggleItalics,
  };

  static final List<SuperEditorKeyboardAction> _imeActions = [
    for (final a in defaultImeKeyboardActions)
      if (!_removed.contains(a)) a,
  ];

  static final _stylesheet = Stylesheet(
    rules: const [],
    documentPadding: EdgeInsets.zero,
    inlineTextStyler: (attributions, style) => style,
  );
}
