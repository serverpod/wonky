import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_core/wonky_core.dart' show UuidV7Generator;
import 'package:wonky_write_core/wonky_write_core.dart'
    show SuggestionContext, SuggestionRewriter;

import '../../../l10n/write_l10n.dart';
import '../applier/delta_applier.dart';
import '../extractor/change_delta_extractor.dart';
import '../mapping/delta_document_mapper.dart';
import '../mapping/delta_ops.dart';
import '../mapping/document_mirror.dart';
import '../mapping/mirror_overlays.dart';
import '../requests/block_editing_handlers.dart';
import '../setup/editor_factory.dart';
import '../view/editor_view_state.dart';
import 'editor_pipeline.dart';
import 'editor_types.dart';

/// Controller of one open Write document in the editor (Write 04 §2.1).
///
/// Owns the super_editor objects ([document], [composer], [editor], history
/// disabled) and the Delta plumbing ([mirror], extractor, applier). The sync
/// and undo layers talk to it through Deltas only:
///
/// - [localChanges] emits every local change (typing, commands, reactions,
///   paste…) as a change Delta with its inverse, label and selections;
/// - [applyRemote] applies a collaborator's (already transformed) change
///   without moving the local caret;
/// - [applyLocal] applies a change made through a Delta (undo/redo, AI, MCP,
///   commands) and reports it as a local change;
/// - [selection] / [select] expose the selection as Delta offsets.
class WriteEditorController extends ChangeNotifier {
  WriteEditorController({
    Delta? initialDelta,
    this.documentUuid = '',
    this.userUuid = '',
    this._mode = EditorMode.editing,
    this._preferences = const WriteEditorPreferences(),
    String Function()? newEmbedId,
    String Function()? newNodeId,
    Clock? clock,
    bool? verifyInvariants,
    this.maxDocumentChars = 2000000,
    DeltaDocumentMapper mapper = const DeltaDocumentMapper(),
  }) : _clock = clock ?? const Clock(),
       newEmbedId = newEmbedId ?? UuidV7Generator.instance.nextString {
    _pipeline = EditorPipeline(
      initialDelta: initialDelta ?? (Delta()..insert('\n')),
      mapper: mapper,
      newNodeId: newNodeId,
      verifyInvariants: verifyInvariants,
      requestHandlers: [
        ...wonkyRequestHandlers(
          mode: () => _mode,
          selectable: () => _selectable,
          documentLength: () => mirror.length,
          onMaxLengthReached: () =>
              _events.add(const EditorNotice(EditorNoticeKind.documentFull)),
          maxDocumentChars: maxDocumentChars,
        ),
        ...blockEditingHandlers(
          newEmbedId: this.newEmbedId,
          markdownShortcuts: () => _preferences.markdownShortcuts,
        ),
      ],
      reactions: (pipeline) => wonkyReactions(
        pipeline,
        preferences: () => _preferences,
        mode: () => _mode,
        newEmbedId: this.newEmbedId,
      ),
      onTransaction: _onTransaction,
    );
    composer.selectionNotifier.addListener(_onSelectionChanged);
  }

  /// The document's UUID (used for the IME input role and internal links).
  final String documentUuid;

  /// Maximum document length in characters (Write 02 §1.4).
  final int maxDocumentChars;

  /// Creates ids for new embeds (UUIDv7) and suggestions.
  final String Function() newEmbedId;

  final Clock _clock;

  late final EditorPipeline _pipeline;

  /// The super_editor document.
  MutableDocument get document => _pipeline.document;

  /// The super_editor composer (selection, composing region, typing attributes).
  MutableDocumentComposer get composer => _pipeline.composer;

  /// The super_editor editor (history disabled).
  Editor get editor => _pipeline.editor;

  /// The Delta mirror of [document] (offset ⇄ position conversions).
  DocumentMirror get mirror => _pipeline.mirror;

  /// Comment anchors and pending suggestions, kept per block (Write 04
  /// §36): only changed blocks are scanned again.
  late final MirrorOverlays overlays = MirrorOverlays(mirror);

  /// The change extractor (used by marked reactions).
  ChangeDeltaExtractor get extractor => _pipeline.extractor;

  /// The Delta ⇄ document mapper.
  DeltaDocumentMapper get mapper => _pipeline.mapper;

  /// View state (zoom, layout, find matches, remote cursors, comments).
  final EditorViewState view = EditorViewState();

  /// Focus node of the editor widget.
  final FocusNode focusNode = FocusNode(debugLabel: 'write-editor');

  /// Key of the document layout (used by layers and popovers).
  final GlobalKey documentLayoutKey = GlobalKey(
    debugLabel: 'write-document-layout',
  );

  /// In-place table cell editing of the mounted editor widget (SE-4,
  /// Write 04 §18.4); `null` while no editor is mounted.
  InlineTableEditingHandle? tableEditing;

  /// The document layout, once the editor is laid out.
  DocumentLayout? get documentLayout =>
      documentLayoutKey.currentState as DocumentLayout?;

  // ---------------------------------------------------------------------------
  // Local changes.

  final _localChanges = StreamController<LocalDeltaChange>.broadcast(
    sync: true,
  );

  /// Every local change, in order, synchronously after it was made.
  Stream<LocalDeltaChange> get localChanges => _localChanges.stream;

  final _events = StreamController<EditorNotice>.broadcast(sync: true);

  /// Notices for the UI (toasts, announcements).
  Stream<EditorNotice> get notices => _events.stream;

  /// Emits a notice (used by commands and the widget).
  void notify(EditorNotice notice) => _events.add(notice);

  String? _labelOverride;
  LocalChangeSource? _sourceOverride;
  DeltaSelection? _selection;
  List<LocalDeltaChange>? _group;

  /// The current selection as Delta offsets, or `null`.
  DeltaSelection? get selection => _selection ?? _currentSelection();

  DeltaSelection? _currentSelection() {
    final selection = composer.selection;
    if (selection == null) return null;
    final offsets = mirror.offsetsOf(selection);
    return offsets == null ? null : DeltaSelection(offsets.$1, offsets.$2);
  }

  void _onSelectionChanged() {
    _selection = _currentSelection();
    notifyListeners();
  }

  /// Runs [body] (which executes editor requests) so that the changes it makes
  /// are reported with [label] and [source].
  T runLabelled<T>(
    String label,
    T Function() body, {
    LocalChangeSource source = LocalChangeSource.command,
  }) {
    final previousLabel = _labelOverride;
    final previousSource = _sourceOverride;
    _labelOverride = label;
    _sourceOverride = source;
    try {
      return body();
    } finally {
      _labelOverride = previousLabel;
      _sourceOverride = previousSource;
    }
  }

  /// Runs [body] and reports all local changes it makes as **one** change
  /// (one undo step) labelled [label].
  T group<T>(
    String label,
    T Function() body, {
    LocalChangeSource source = LocalChangeSource.command,
  }) {
    final outer = _group;
    final changes = <LocalDeltaChange>[];
    _group = changes;
    try {
      return runLabelled(label, body, source: source);
    } finally {
      _group = outer;
      final merged = _merge(changes, label, source);
      if (merged != null) {
        _emit(merged);
      }
    }
  }

  LocalDeltaChange? _merge(
    List<LocalDeltaChange> changes,
    String label,
    LocalChangeSource source,
  ) {
    if (changes.isEmpty) return null;
    if (changes.length == 1) {
      return changes.single.copyWith(label: label, source: source);
    }
    var delta = changes.first.delta;
    var inverse = changes.first.inverse;
    for (final change in changes.skip(1)) {
      delta = delta.compose(change.delta);
      inverse = change.inverse.compose(inverse);
    }
    return LocalDeltaChange(
      delta: delta,
      inverse: inverse,
      label: label,
      kind: LocalChangeKind.other,
      source: source,
      at: changes.last.at,
      selectionBefore: changes.first.selectionBefore,
      selectionAfter: changes.last.selectionAfter,
      nodeIds: {for (final c in changes) ...c.nodeIds},
    );
  }

  void _emit(LocalDeltaChange change) {
    if (change.delta.isEmpty) return;
    final group = _group;
    if (group != null) {
      group.add(change);
      return;
    }
    _localChanges.add(change);
  }

  void _onTransaction(List<ExtractedChange> changes, List<EditEvent> events) {
    final selectionBefore = _selection;
    final selectionAfter = _currentSelection();
    if (changes.isEmpty) {
      _selection = selectionAfter;
      return;
    }

    for (final change in changes) {
      view.transformThrough(change.delta);
    }
    final now = _clock.now();
    final local = <LocalDeltaChange>[];
    var before = selectionBefore;
    for (final change in changes) {
      final after = change.selectionAfter == null
          ? null
          : DeltaSelection(
              change.selectionAfter!.$1,
              change.selectionAfter!.$2,
            );
      final isReaction = change.label != null;
      final next = LocalDeltaChange(
        delta: change.delta,
        inverse: change.inverse,
        label: change.label ?? _labelOverride ?? _defaultLabel(change.kind),
        kind: change.kind,
        source: isReaction
            ? LocalChangeSource.reaction
            : (_sourceOverride ?? LocalChangeSource.input),
        at: now,
        selectionBefore: before,
        selectionAfter: after,
        nodeIds: change.nodeIds,
        isComposing: change.isComposing,
      );
      before = after;
      if (local.isNotEmpty && change.label == null) {
        // Fixes made after a reaction (schema guard) belong to the previous step.
        local[local.length - 1] = _merge(
          [local.last, next],
          local.last.label,
          local.last.source,
        )!;
      } else {
        local.add(next);
      }
    }
    _selection = selectionAfter;

    for (final change in local) {
      if (_mode == EditorMode.suggesting &&
          change.source != LocalChangeSource.undo &&
          !_isSuggestionNeutral(change.delta)) {
        _emitAsSuggestion(change);
      } else {
        _emit(change);
      }
    }
    notifyListeners();
  }

  String _defaultLabel(LocalChangeKind kind) {
    final l = strings();
    return switch (kind) {
      LocalChangeKind.typing => l.undoTyping,
      LocalChangeKind.deletion => l.undoDelete,
      LocalChangeKind.other => l.undoEdit,
    };
  }

  /// The Write strings for what the editor labels itself (undo steps,
  /// screen-reader announcements): English unless the host sets the
  /// shell's locale (the document session does).
  WriteLocalizations Function() strings = () => writeL10nEnglish;

  // ---------------------------------------------------------------------------
  // Remote and Delta-based changes.

  /// Applies a collaborator's change (already transformed against local
  /// pending ops, Write 03 §3). The local selection is transformed; no local
  /// change is reported.
  void applyRemote(Delta change) {
    if (change.isEmpty) return;
    _pipeline.applier.apply(change, origin: AppliedChangeOrigin.remote);
    view.transformThrough(change);
    _selection = _currentSelection();
    _afterRemote?.call(change);
    notifyListeners();
  }

  void Function(Delta change)? _afterRemote;

  /// Registers a callback run after every remote change (used by derived
  /// services such as find, presence and pending comment ranges to transform
  /// their offsets).
  set onRemoteChange(void Function(Delta change)? callback) =>
      _afterRemote = callback;

  /// Applies [change] (against the current document) as a local change and
  /// reports it with [label]. Used for undo/redo ([LocalChangeSource.undo]),
  /// AI/MCP edits and Delta-based commands.
  ///
  /// [selectionAfter] sets the selection afterwards (e.g. undo restores
  /// `selectionBefore`); by default the selection is transformed.
  LocalDeltaChange? applyLocal(
    Delta change, {
    required String label,
    LocalChangeSource source = LocalChangeSource.command,
    DeltaSelection? selectionAfter,
  }) {
    if (change.isEmpty) {
      if (selectionAfter != null) select(selectionAfter);
      return null;
    }
    if (_mode == EditorMode.viewing && source != LocalChangeSource.undo) {
      return null;
    }
    final inverse = mirror.invert(change);
    final selectionBefore = _currentSelection();
    final result = _pipeline.applier.apply(
      change,
      origin: AppliedChangeOrigin.local,
      selectionAfter: selectionAfter,
    );
    view.transformThrough(change);
    _selection = _currentSelection();
    final local = LocalDeltaChange(
      delta: change,
      inverse: inverse,
      label: label,
      kind: LocalChangeKind.other,
      source: source,
      at: _clock.now(),
      selectionBefore: selectionBefore,
      selectionAfter: _selection ?? result.after,
    );
    if (_mode == EditorMode.suggesting &&
        source != LocalChangeSource.undo &&
        !_isSuggestionNeutral(change)) {
      _emitAsSuggestion(local, alreadyApplied: true);
    } else {
      _emit(local);
    }
    notifyListeners();
    return local;
  }

  /// Replaces the whole document (re-init after a resync, Write 03 §3.2)
  /// without reporting a local change. The selection is kept as Delta offsets
  /// (clamped) unless [selection] is given.
  void resetDocument(Delta delta, {DeltaSelection? selection}) {
    final keep = selection ?? _selection;
    _pipeline.resetDocument(delta, selection: keep);
    view
      ..clearFindMatches()
      ..pendingComment = null;
    _selection = _currentSelection();
    notifyListeners();
  }

  /// The whole document Delta (O(n)).
  Delta get delta => mirror.toDelta();

  /// The document length (Delta offsets).
  int get length => mirror.length;

  /// Selects Delta offsets `[base, extent]` (not undoable).
  void select(DeltaSelection selection, {bool userInteraction = true}) {
    final max = mirror.length - 1;
    final documentSelection = mirror.selectionAt(
      selection.anchor.clamp(0, max),
      selection.head.clamp(0, max),
    );
    editor.execute([
      ChangeSelectionRequest(
        documentSelection,
        selection.isCollapsed
            ? SelectionChangeType.placeCaret
            : SelectionChangeType.expandSelection,
        userInteraction
            ? SelectionReason.userInteraction
            : SelectionReason.contentChange,
      ),
    ]);
    _selection = _currentSelection();
  }

  /// Transforms a Delta offset through [change] (Write 03 §3).
  static int transformPosition(Delta change, int offset, {bool force = true}) =>
      change.transformPosition(offset, force: force);

  // ---------------------------------------------------------------------------
  // Modes and preferences.

  /// The local user's UUID (suggestion authorship, own mentions).
  String userUuid;

  EditorMode _mode;

  /// Editing, Suggesting or Viewing (Write 04 §31).
  bool _selectable = true;

  /// Whether the user can select text (taps, drags, long presses). Off in
  /// the read-only mobile layout (suite 02 §6.1, T-1); a layout setting, not
  /// a change of the document. Turning it off clears the selection.
  bool get selectable => _selectable;
  set selectable(bool value) {
    if (value == _selectable) return;
    _selectable = value;
    if (!value && composer.selection != null) {
      editor.execute([const ClearSelectionRequest()]);
    }
    notifyListeners();
  }

  EditorMode get mode => _mode;
  set mode(EditorMode value) {
    if (value == _mode) return;
    _mode = value;
    if (value == EditorMode.viewing) {
      editor.execute([const ClearComposingRegionRequest()]);
    }
    _suggestionSession.reset();
    notifyListeners();
  }

  WriteEditorPreferences _preferences;

  /// User preferences (Markdown shortcuts, smart typography, auto-pair, …).
  WriteEditorPreferences get preferences => _preferences;
  set preferences(WriteEditorPreferences value) {
    if (value == _preferences) return;
    _preferences = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Suggesting mode (Write 04 §32, Write 08 §2.3–2.4).

  final _rewriter = const SuggestionRewriter();
  final _suggestionSession = SuggestionSession();

  /// `via` for agent edits in suggesting mode (`ai`, `mcp`).
  String? suggestionVia;

  /// Starts a new suggestion id for the next suggested change (formatting
  /// commands always do).
  void startNewSuggestion() => _suggestionSession.reset();

  bool _isSuggestionNeutral(Delta change) {
    for (final op in change.operations) {
      if (op.isInsert || op.isDelete) return false;
      final attributes = op.attributes;
      if (attributes == null) continue;
      if (!attributes.keys.every(
        (k) => k.startsWith('cmt_') || k.startsWith('sug_'),
      )) {
        return false;
      }
    }
    return true;
  }

  void _emitAsSuggestion(
    LocalDeltaChange change, {
    bool alreadyApplied = true,
  }) {
    final now = _clock.now();
    final id = _suggestionSession.idFor(change, now, newEmbedId);
    final context = SuggestionContext(
      userUuid: userUuid,
      nowMs: now.millisecondsSinceEpoch,
      suggestionId: id,
      via: suggestionVia,
    );
    final (rewritten, rewrittenInverse) = _rewriteLocally(change, context);
    if (rewritten == change.delta) {
      _emit(change);
      return;
    }

    // Caret: Backspace over others' text moves before the struck text,
    // Delete moves after it (Write 08 §2.4).
    // Otherwise the caret goes after the last suggested insertion, or keeps
    // its place.
    DeltaSelection? selectionAfter;
    final selectionBefore = change.selectionBefore;
    final lastInsertEnd = _lastInsertEnd(rewritten);
    if (change.kind == LocalChangeKind.deletion &&
        selectionBefore != null &&
        selectionBefore.isCollapsed) {
      final (start, end) = _deletedRange(change.delta);
      selectionAfter = DeltaSelection.collapsed(
        selectionBefore.anchor == end ? start : end,
      );
    } else if (lastInsertEnd != null) {
      selectionAfter = DeltaSelection.collapsed(lastInsertEnd);
    } else if (selectionBefore != null) {
      selectionAfter = selectionBefore.transform(rewritten);
    }

    final corrective = change.inverse.compose(rewritten);
    _pipeline.applier.apply(
      corrective,
      origin: AppliedChangeOrigin.local,
      selectionAfter: selectionAfter,
    );
    view.transformThrough(corrective);
    _selection = _currentSelection();
    _suggestionSession.remember(change, _selection, now, id);
    _emit(
      LocalDeltaChange(
        delta: rewritten,
        inverse: rewrittenInverse,
        label: change.label,
        kind: change.kind,
        source: change.source,
        at: change.at,
        selectionBefore: change.selectionBefore,
        selectionAfter: _selection,
        nodeIds: change.nodeIds,
        isComposing: change.isComposing,
      ),
    );
  }

  /// [change] (already applied) rewritten into suggestion form, and the
  /// inverse of the rewritten change against the document before [change].
  ///
  /// Works on a window of the document around the touched range (one
  /// character either side: the rewriter looks at the neighbours to extend
  /// your own suggested insertion), not on the whole document (W-04): the
  /// window before the change is the mirror's slice after it composed with
  /// the change's inverse.
  (Delta, Delta) _rewriteLocally(
    LocalDeltaChange change,
    SuggestionContext context,
  ) {
    final touched = _touchedRange(change.delta);
    if (touched == null) return (change.delta, change.inverse);
    final (lo, hi) = touched;
    final net = DeltaOps.lengthChange(change.delta);
    final afterLength = mirror.length;
    final from = lo > 0 ? lo - 1 : 0;
    final to = (hi + 1).clamp(0, afterLength - net);
    final after = mirror.slice(from, to + net);
    final before = after.compose(_withoutPrefix(change.inverse, from));
    final local = _rewriter.rewrite(
      before,
      _withoutPrefix(change.delta, from),
      context,
    );
    Delta prefixed(Delta delta) {
      final out = Delta()..retain(from);
      for (final op in delta.operations) {
        out.push(op);
      }
      out.trim();
      return out;
    }

    final rewritten = prefixed(local);
    final inverse = prefixed(DeltaOps.invert(local, before));
    assert(() {
      if (!_pipeline.extractor.verifyInvariants) return true;
      // The window must give what the whole document gives.
      final whole = mirror.toDelta().compose(change.inverse);
      final full = _rewriter.rewrite(whole, change.delta, context);
      return full == rewritten && DeltaOps.invert(full, whole) == inverse;
    }(), 'windowed suggestion rewrite differs from the full rewrite');
    return (rewritten, inverse);
  }

  /// The base range `[lo, hi]` a change touches: from its first insert,
  /// delete or attributed retain to the end of its last one.
  static (int, int)? _touchedRange(Delta change) {
    var offset = 0;
    int? lo;
    var hi = 0;
    for (final op in change.operations) {
      final length = op.length!;
      final attributes = op.attributes;
      if (op.isRetain && (attributes == null || attributes.isEmpty)) {
        offset += length;
        continue;
      }
      lo ??= offset;
      if (!op.isInsert) offset += length;
      if (offset > hi) hi = offset;
    }
    return lo == null ? null : (lo, hi);
  }

  /// [change] without its first [count] base characters (plain retains).
  static Delta _withoutPrefix(Delta change, int count) {
    final out = Delta();
    var skip = count;
    for (final op in change.operations) {
      if (skip > 0 && op.isRetain) {
        final length = op.length!;
        if (length <= skip) {
          skip -= length;
          continue;
        }
        out.retain(length - skip, op.attributes);
        skip = 0;
        continue;
      }
      out.push(op);
    }
    return out;
  }

  /// Offset (in the new document) right after the last insertion of [delta].
  static int? _lastInsertEnd(Delta delta) {
    var offset = 0;
    int? end;
    for (final op in delta.operations) {
      if (op.isDelete) continue;
      offset += op.length!;
      if (op.isInsert) end = offset;
    }
    return end;
  }

  static (int, int) _deletedRange(Delta delta) {
    var offset = 0;
    for (final op in delta.operations) {
      if (op.isRetain) {
        offset += op.length!;
      } else if (op.isDelete) {
        return (offset, offset + op.length!);
      }
    }
    return (offset, offset);
  }

  @override
  void dispose() {
    composer.selectionNotifier.removeListener(_onSelectionChanged);
    _localChanges.close();
    _events.close();
    focusNode.dispose();
    view.dispose();
    _pipeline.dispose();
    super.dispose();
  }
}

/// Groups consecutive suggestions into one suggestion id (Write 08 §2.4): same
/// block, within 30 s, no caret jump.
class SuggestionSession {
  String? _id;
  DateTime? _at;
  Set<String> _nodeIds = const {};
  DeltaSelection? _selection;

  void reset() {
    _id = null;
    _at = null;
    _nodeIds = const {};
    _selection = null;
  }

  String idFor(LocalDeltaChange change, DateTime now, String Function() newId) {
    final id = _id;
    if (id != null &&
        change.source == LocalChangeSource.input &&
        _at != null &&
        now.difference(_at!) <= const Duration(seconds: 30) &&
        _nodeIds.isNotEmpty &&
        change.nodeIds.every(_nodeIds.contains) &&
        change.selectionBefore == _selection) {
      return id;
    }
    return newId();
  }

  void remember(
    LocalDeltaChange change,
    DeltaSelection? selection,
    DateTime now,
    String id,
  ) {
    _id = change.source == LocalChangeSource.input ? id : null;
    _at = now;
    _nodeIds = change.nodeIds;
    _selection = selection;
  }
}

/// What commands need from the in-place table editor (`write.table.editCell`).
abstract interface class InlineTableEditingHandle {
  /// Starts editing cell ([row], [column]) of the table [tableId].
  bool activate(String tableId, int row, int column, {bool selectAll});

  /// Stops editing (saving the cell).
  void deactivate();

  /// Whether a cell is being edited.
  bool get isEditing;
}

/// A notice for the UI (toast, announcement).
enum EditorNoticeKind {
  /// The document reached its maximum size (Write 04 §3.1).
  documentFull,

  /// A Markdown-hint popover ("Underline isn't available in Markdown…").
  markdownHint,

  /// Some formatting wasn't kept on paste.
  formattingDropped,

  /// A generic message.
  message,

  /// A screen-reader announcement (Write 04 §37.2).
  announcement,
}

@immutable
class EditorNotice {
  const EditorNotice(this.kind, [this.message]);

  final EditorNoticeKind kind;
  final String? message;

  @override
  String toString() => 'EditorNotice($kind, $message)';
}
