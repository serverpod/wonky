import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../applier/delta_applier.dart';
import '../controller/editor_types.dart';
import '../styles/write_stylesheet.dart';

/// A highlighted Delta range (find match, pending comment, AI preview).
@immutable
class HighlightRange {
  const HighlightRange(this.start, this.end);

  final int start;
  final int end;

  HighlightRange transform(Delta change) {
    final s = change.transformPosition(start, force: false);
    final e = change.transformPosition(end, force: false);
    return HighlightRange(s, e < s ? s : e);
  }

  bool get isEmpty => end <= start;

  @override
  bool operator ==(Object other) =>
      other is HighlightRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'HighlightRange($start, $end)';
}

/// A collaborator's cursor (Write 04 §34), in Delta offsets at the current
/// local document state (the sync layer transforms remote offsets before
/// handing them in; the controller transforms them through later changes).
@immutable
class RemoteCursor {
  const RemoteCursor({
    required this.sessionId,
    required this.userKey,
    required this.name,
    required this.selection,
    this.focused = true,
    this.idle = false,
    this.isAgent = false,
    this.lastActivity,
    this.colorIndex,
  });

  final String sessionId;

  /// Stable user key for the presence color (user id or UUID).
  final String userKey;

  /// Flag label ("Anna", "Claude (via MCP)", "You (other tab)").
  final String name;
  final DeltaSelection selection;
  final bool focused;
  final bool idle;
  final bool isAgent;

  /// Changes whenever the collaborator moves (restarts the flag timer).
  final Object? lastActivity;

  /// Presence color slot; derived from [userKey] when null.
  final int? colorIndex;

  RemoteCursor copyWith({DeltaSelection? selection}) => RemoteCursor(
    sessionId: sessionId,
    userKey: userKey,
    name: name,
    selection: selection ?? this.selection,
    focused: focused,
    idle: idle,
    isAgent: isAgent,
    lastActivity: lastActivity,
    colorIndex: colorIndex,
  );
}

/// Page geometry for the Pages layout (Write 04 §29, Write 07 page setup), in
/// logical pixels at 100 % zoom.
@immutable
class EditorPageSetup {
  const EditorPageSetup({
    this.size = const Size(794, 1123),
    this.margins = const EdgeInsets.all(96),
    this.headerText = '',
    this.footerText = '',
    this.pageGap = 16,
  });

  /// A4 portrait at 96 dpi.
  static const a4 = EditorPageSetup();

  /// US Letter portrait at 96 dpi.
  static const letter = EditorPageSetup(size: Size(816, 1056));

  final Size size;
  final EdgeInsets margins;

  /// Header/footer templates; `{page}` and `{pages}` are replaced.
  final String headerText;
  final String footerText;
  final double pageGap;

  double get contentWidth => size.width - margins.horizontal;
  double get contentHeight => size.height - margins.vertical;

  @override
  bool operator ==(Object other) =>
      other is EditorPageSetup &&
      other.size == size &&
      other.margins == margins &&
      other.headerText == headerText &&
      other.footerText == footerText &&
      other.pageGap == pageGap;

  @override
  int get hashCode =>
      Object.hash(size, margins, headerText, footerText, pageGap);
}

/// View state of the editor: not part of the document, not undoable
/// (Write 04 §25, §29, §31, §33, §34). Ranges are Delta offsets and are
/// transformed through every document change by the controller.
class EditorViewState extends ChangeNotifier {
  static const zoomSteps = [
    0.5,
    0.67,
    0.75,
    0.8,
    0.9,
    1.0,
    1.1,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  double _zoom = 1;
  double get zoom => _zoom;
  set zoom(double value) {
    final clamped = value.clamp(0.5, 2.0);
    if (clamped == _zoom) return;
    _zoom = clamped;
    notifyListeners();
  }

  void zoomIn() => zoom = zoomSteps.firstWhere(
    (z) => z > _zoom + 0.001,
    orElse: () => zoomSteps.last,
  );

  void zoomOut() => zoom = zoomSteps.lastWhere(
    (z) => z < _zoom - 0.001,
    orElse: () => zoomSteps.first,
  );

  void zoomReset() => zoom = 1;

  LayoutMode _layout = LayoutMode.pageless;
  LayoutMode get layout => _layout;
  set layout(LayoutMode value) {
    if (value == _layout) return;
    _layout = value;
    notifyListeners();
  }

  EditorPageSetup _pageSetup = EditorPageSetup.a4;
  EditorPageSetup get pageSetup => _pageSetup;
  set pageSetup(EditorPageSetup value) {
    if (value == _pageSetup) return;
    _pageSetup = value;
    notifyListeners();
  }

  SuggestionPreviewMode? _suggestionPreview;

  /// Explicit preview mode, or `null` for the mode default (Viewing →
  /// original, otherwise show).
  SuggestionPreviewMode? get suggestionPreview => _suggestionPreview;
  set suggestionPreview(SuggestionPreviewMode? value) {
    if (value == _suggestionPreview) return;
    _suggestionPreview = value;
    notifyListeners();
  }

  bool _showRemoteCursors = true;
  bool get showRemoteCursors => _showRemoteCursors;
  set showRemoteCursors(bool value) {
    if (value == _showRemoteCursors) return;
    _showRemoteCursors = value;
    notifyListeners();
  }

  // Find matches (§25.3).
  List<HighlightRange> _findMatches = const [];
  int? _activeFindMatch;
  List<HighlightRange> get findMatches => _findMatches;
  int? get activeFindMatch => _activeFindMatch;

  /// Sets the find matches to paint ([active] = index of the active match).
  void setFindMatches(List<HighlightRange> matches, {int? active}) {
    _findMatches = List.unmodifiable(matches);
    _activeFindMatch = active == null || active < 0 || active >= matches.length
        ? null
        : active;
    notifyListeners();
  }

  void clearFindMatches() => setFindMatches(const []);

  // Comments (§33).
  CommentHighlightState _comments = const CommentHighlightState();
  CommentHighlightState get comments => _comments;
  set comments(CommentHighlightState value) {
    if (value == _comments) return;
    _comments = value;
    notifyListeners();
  }

  HighlightRange? _pendingComment;

  /// The range of a comment being composed (drawn with a dashed underline,
  /// not yet in the document, Write 08 §1.2).
  HighlightRange? get pendingComment => _pendingComment;
  set pendingComment(HighlightRange? value) {
    if (value == _pendingComment) return;
    _pendingComment = value;
    notifyListeners();
  }

  // Remote presence (§34).
  Map<String, RemoteCursor> _remoteCursors = const {};
  Iterable<RemoteCursor> get remoteCursors => _remoteCursors.values;

  void setRemoteCursor(RemoteCursor cursor) {
    _remoteCursors = {..._remoteCursors, cursor.sessionId: cursor};
    notifyListeners();
  }

  void removeRemoteCursor(String sessionId) {
    if (!_remoteCursors.containsKey(sessionId)) return;
    _remoteCursors = {..._remoteCursors}..remove(sessionId);
    notifyListeners();
  }

  void clearRemoteCursors() {
    _remoteCursors = const {};
    notifyListeners();
  }

  /// Whether the current selection is a block selection (§22.3).
  bool _blockSelection = false;
  bool get blockSelection => _blockSelection;
  set blockSelection(bool value) {
    if (value == _blockSelection) return;
    _blockSelection = value;
    notifyListeners();
  }

  /// Transforms all ranges through a document [change].
  void transformThrough(Delta change) {
    var changed = false;
    if (_findMatches.isNotEmpty) {
      _findMatches = [for (final m in _findMatches) m.transform(change)];
      changed = true;
    }
    if (_pendingComment != null) {
      _pendingComment = _pendingComment!.transform(change);
      changed = true;
    }
    if (_remoteCursors.isNotEmpty) {
      _remoteCursors = {
        for (final entry in _remoteCursors.entries)
          entry.key: entry.value.copyWith(
            selection: DeltaSelection(
              change.transformPosition(
                entry.value.selection.anchor,
                force: false,
              ),
              change.transformPosition(
                entry.value.selection.head,
                force: false,
              ),
            ),
          ),
      };
      changed = true;
    }
    if (changed) notifyListeners();
  }
}
