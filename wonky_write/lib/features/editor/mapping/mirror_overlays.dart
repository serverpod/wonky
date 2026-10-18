import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        CommentAnchor,
        CommentAnchors,
        CommentPiece,
        SuggestionIndex,
        SuggestionInfo,
        SuggestionPiece,
        WonkyAttr;

import 'document_mirror.dart';

/// Comment anchors and pending suggestions of a [DocumentMirror], computed
/// from per-block pieces (Write 04 §36, CQ-42).
///
/// The overlay pieces (`cmt_*` runs, `sug_*` marks) of each block are
/// scanned once per [MirrorEntry] — entries are immutable and replaced when
/// their node changes — so after a keystroke only the edited block is
/// scanned again; [anchors] and [suggestions] then only add up the cached
/// pieces with the blocks' offsets. Same results as
/// `CommentAnchors.anchors(mirror.toDelta())` and
/// `SuggestionIndex.list(mirror.toDelta())`, without serializing and
/// re-parsing the whole document.
class MirrorOverlays {
  MirrorOverlays(this.mirror);

  final DocumentMirror mirror;

  final _blocks = Expando<_BlockOverlays>('overlays');

  _BlockOverlays _of(MirrorEntry entry) =>
      _blocks[entry] ??= _BlockOverlays.scan(entry.delta);

  /// Anchors of every comment thread in the document (by thread uuid).
  Map<String, CommentAnchor> anchors() {
    final pieces = <CommentPiece>[];
    var offset = 0;
    for (var i = 0; i < mirror.nodeCount; i++) {
      final entry = mirror.entryAt(i);
      for (final p in _of(entry).comments) {
        pieces.add((
          threadUuid: p.threadUuid,
          start: p.start + offset,
          length: p.length,
          text: p.text,
        ));
      }
      offset += entry.length;
    }
    return CommentAnchors.fromPieces(pieces);
  }

  /// Pending suggestions in document order.
  List<SuggestionInfo> suggestions() {
    final pieces = <SuggestionPiece>[];
    var offset = 0;
    for (var i = 0; i < mirror.nodeCount; i++) {
      final entry = mirror.entryAt(i);
      for (final p in _of(entry).suggestions) {
        pieces.add((id: p.id, mark: p.mark, part: p.part.shifted(offset)));
      }
      offset += entry.length;
    }
    return SuggestionIndex.fromPieces(pieces);
  }
}

class _BlockOverlays {
  const _BlockOverlays(this.comments, this.suggestions);

  static const none = _BlockOverlays([], []);

  factory _BlockOverlays.scan(Delta delta) {
    var comments = false;
    var suggestions = false;
    for (final op in delta.operations) {
      for (final key in op.attributes?.keys ?? const <String>[]) {
        comments = comments || WonkyAttr.isComment(key);
        suggestions = suggestions || WonkyAttr.isSuggestion(key);
      }
    }
    if (!comments && !suggestions) return none;
    return _BlockOverlays(
      comments ? CommentAnchors.pieces(delta) : const [],
      suggestions ? SuggestionIndex.pieces(delta) : const [],
    );
  }

  /// Comment runs, offsets relative to the block.
  final List<CommentPiece> comments;

  /// Suggestion marks, offsets relative to the block.
  final List<SuggestionPiece> suggestions;
}
