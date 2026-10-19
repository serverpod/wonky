import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart'
    show DocumentChangeLog, MutableDocument;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../editor/controller/write_editor_controller.dart';

/// Derived, read-only data of the open document (Write 04 §26–27): the
/// outline, document statistics and the statistics of the selection.
///
/// Recomputed from the editor's Delta at most every [debounce] while the
/// document changes; cheap selection-only updates refresh [currentHeading]
/// and [selectionStats] immediately.
class DocumentInsights extends ChangeNotifier {
  DocumentInsights(
    this.editor, {
    this.debounce = const Duration(milliseconds: 250),
  }) {
    editor.addListener(_onEditorChanged);
    _attachDocument();
    _recompute();
  }

  MutableDocument? _document;

  void _attachDocument() {
    final doc = editor.document;
    if (identical(doc, _document)) return;
    _document?.removeListener(_onContentChanged);
    _document = doc..addListener(_onContentChanged);
    _schedule();
  }

  void _onContentChanged(DocumentChangeLog _) => _schedule();

  final WriteEditorController editor;
  final Duration debounce;

  Timer? _timer;
  int _lastLength = -1;
  Delta? _delta;
  DeltaSelection? _lastSelection;

  List<OutlineEntry> _outline = const [];
  DocumentStats _stats = const DocumentStatsCalculator().stats(
    Delta()..insert('\n'),
  );
  DocumentStats? _selectionStats;
  int? _currentHeading;

  /// Headings in document order.
  List<OutlineEntry> get outline => _outline;

  /// Statistics of the whole document.
  DocumentStats get stats => _stats;

  /// Statistics of the selection (null when the selection is collapsed).
  DocumentStats? get selectionStats => _selectionStats;

  /// Index into [outline] of the heading whose section holds the caret.
  int? get currentHeading => _currentHeading;

  /// The document Delta as of the last recompute.
  Delta get delta => _delta ?? editor.delta;

  void _onEditorChanged() {
    _attachDocument();
    final selection = editor.selection;
    if (editor.length != _lastLength) _schedule();
    if (selection != _lastSelection) {
      _lastSelection = selection;
      _updateSelection();
      notifyListeners();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () {
      _recompute();
      notifyListeners();
    });
  }

  /// Recomputes everything now (tests, dialogs that need fresh numbers).
  void refresh() {
    _timer?.cancel();
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    final delta = editor.delta;
    _delta = delta;
    _lastLength = editor.length;
    final doc = WonkyDocument(delta);
    _outline = const OutlineExtractor().outlineOf(doc);
    _stats = const DocumentStatsCalculator().statsOf(doc);
    _updateSelection();
  }

  void _updateSelection() {
    final s = editor.selection;
    final delta = _delta;
    if (s == null || delta == null) {
      _selectionStats = null;
      _currentHeading = null;
      return;
    }
    if (s.isCollapsed) {
      _selectionStats = null;
    } else {
      // `Delta.length` is the number of operations; clamp to the document.
      final docLength = DeltaUtils.documentLength(delta);
      final start = s.start.clamp(0, docLength);
      final length = (s.end.clamp(0, docLength) - start).clamp(0, docLength);
      try {
        _selectionStats = const DocumentStatsCalculator().stats(
          delta,
          start: start,
          length: length,
        );
      } catch (_) {
        _selectionStats = null;
      }
    }
    int? current;
    for (var i = 0; i < _outline.length; i++) {
      if (_outline[i].deltaOffset <= s.start) {
        current = i;
      } else {
        break;
      }
    }
    _currentHeading = current;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _document?.removeListener(_onContentChanged);
    editor.removeListener(_onEditorChanged);
    super.dispose();
  }
}
