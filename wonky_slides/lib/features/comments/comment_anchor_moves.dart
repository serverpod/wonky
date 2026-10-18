import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show CommentThreadView;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';

import 'slides_comment_anchor.dart';
import 'slides_comments.dart';

/// One thread moved by a cut & paste.
@immutable
class DeckCommentMove {
  const DeckCommentMove(this.threadUuid, this.before, this.after);

  final String threadUuid;
  final SlidesCommentAnchor before;
  final SlidesCommentAnchor after;
}

/// Comments move with cut elements and slides (Slides 09 §3.2): when a
/// paste (`PasteElements`, `PasteSlides`) brings back elements or slides
/// whose originals are gone from this deck — they were cut — every thread
/// anchored to an original is re-anchored to its pasted copy with
/// `comment.updateAnchor` (which also revives a thread the server already
/// orphaned). The moves are recorded in the paste's undo step (`comments`
/// domain), so one undo puts the objects and their comments back. Copy &
/// paste (the originals still exist), duplicates and pastes into other
/// decks never copy comments.
class CommentAnchorMoves {
  CommentAnchorMoves(this.comments) {
    comments.editor.applyListeners.add(_onApply);
  }

  final SlidesComments comments;

  void _onApply(CommandContext ctx, SlidesOperation op, SlidesPlan plan) {
    if (op is! PasteElements && op is! PasteSlides) return;
    final c = comments.controller;
    if (c == null) return;
    final moves = movesFor(
      plan.result,
      model: comments.model,
      threads: c.threads,
    );
    applyCommentAnchorChanges(ctx, c, [
      for (final m in moves)
        CommentAnchorChange(
          threadUuid: m.threadUuid,
          anchorKind: m.after.kind,
          beforeJson: m.before.encode(),
          afterJson: m.after.encode(),
        ),
    ]);
  }

  /// The threads anchored to cut originals of a paste's [result]
  /// (`elementIdMap`, `slideIdMap`: old → new ids) and their anchors on
  /// the pasted copies. An original counts as cut when [model] (after the
  /// paste) no longer has it.
  static List<DeckCommentMove> movesFor(
    Map<String, Object?> result, {
    required DeckModel model,
    required Iterable<CommentThreadView> threads,
  }) {
    Map<String, String> map(Object? v) => {
      if (v is Map)
        for (final e in v.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
    };
    final elements = map(result['elementIdMap']);
    final slides = map(result['slideIdMap']);
    if (elements.isEmpty && slides.isEmpty) return const [];
    final out = <DeckCommentMove>[];
    for (final t in threads) {
      final a = SlidesComments.anchorOf(t);
      if (a == null) continue;
      final el = a.elementId;
      SlidesCommentAnchor? after;
      if (el != null) {
        final next = elements[el];
        if (next == null || model.element(el) != null) continue;
        final slide = model.element(next)?.slideId;
        if (slide == null) continue;
        after = a.moved(slideId: slide, elementId: next);
      } else if (a.slideId != null) {
        final next = slides[a.slideId];
        if (next == null || model.slide(a.slideId!) != null) continue;
        after = a.moved(slideId: next);
      }
      if (after == null || after == a) continue;
      out.add(DeckCommentMove(t.uuid.uuid, a, after));
    }
    return out;
  }

  void dispose() => comments.editor.applyListeners.remove(_onApply);
}
