import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show CommentThreadView;
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../sheet_editor/sheet_editor_controller.dart';
import 'sheets_comments.dart';

/// One thread moved by a cut & paste.
@immutable
class CommentAnchorMove {
  const CommentAnchorMove(this.threadUuid, this.before, this.after);

  final String threadUuid;
  final SheetsCommentAnchor before;
  final SheetsCommentAnchor after;
}

/// Comments move with cut cells (Sheets 10 §3.2, Google behavior): after a
/// paste of a cut (all of it, `PasteMode.all`), every thread anchored inside
/// the cut range is re-anchored to the same offset in the pasted range with
/// `comment.updateAnchor`. The moves are recorded in the paste's undo step
/// (`comments` domain), so one undo puts contents and comments back. Copy &
/// paste never copies comments.
class CommentAnchorMoves {
  CommentAnchorMoves(this.comments) {
    editor.applyListeners.add(_onApply);
  }

  final SheetsComments comments;

  SheetEditorController get editor => comments.editor;

  void _onApply(CommandContext? ctx, SheetsOperation op, MutationPlan plan) {
    if (op is! PasteClipboard ||
        op.mode != PasteMode.all ||
        !op.source.isCut ||
        plan.isEmpty) {
      return;
    }
    final c = comments.controller;
    final written = plan.result['range'];
    if (c == null || written is! GridRect) return;
    final moves = movesFor(
      op.source,
      targetSheetId: op.target.sheetId,
      written: written,
      model: editor.model,
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

  /// The threads anchored inside the cut [source] and their anchors at the
  /// same offsets of the pasted range [written] on [targetSheetId]. Range
  /// anchors move only when the whole range was cut.
  static List<CommentAnchorMove> movesFor(
    PasteSource source, {
    required String targetSheetId,
    required GridRect written,
    required WorkbookModel model,
    required Iterable<CommentThreadView> threads,
  }) {
    final from = model.sheet(source.sheetId ?? targetSheetId);
    final to = model.sheet(targetSheetId);
    if (from == null || to == null || source.cells.isEmpty) return const [];
    final rows = source.cells.length;
    final cols = source.cells.first.length;
    // Source index → payload offset.
    final rowOffset = <int, int>{
      for (var i = 0; i < rows; i++)
        (source.sourceRowIndices != null && i < source.sourceRowIndices!.length
                ? source.sourceRowIndices![i]
                : source.sourceRow + i):
            i,
    };
    final colOffset = <int, int>{
      for (var i = 0; i < cols; i++)
        (source.sourceColIndices != null && i < source.sourceColIndices!.length
                ? source.sourceColIndices![i]
                : source.sourceCol + i):
            i,
    };
    String? rowAt(int offset) {
      final r = written.top + offset;
      return r <= written.bottom ? to.rows.tryIdAt(r) : null;
    }

    String? colAt(int offset) {
      final c = written.left + offset;
      return c <= written.right ? to.columns.tryIdAt(c) : null;
    }

    final out = <CommentAnchorMove>[];
    for (final t in threads) {
      final a = SheetsCommentAnchor.parse(t.anchorKind, t.anchorJson);
      if (a == null || a.sheetId != from.id) continue;
      final rect = a.resolve(model);
      if (rect == null) continue;
      final top = rowOffset[rect.top];
      final bottom = rowOffset[rect.bottom];
      final left = colOffset[rect.left];
      final right = colOffset[rect.right];
      if (top == null || bottom == null || left == null || right == null) {
        continue;
      }
      final r1 = rowAt(top);
      final r2 = rowAt(bottom);
      final c1 = colAt(left);
      final c2 = colAt(right);
      if (r1 == null || r2 == null || c1 == null || c2 == null) continue;
      final after = SheetsCommentAnchor(
        sheetId: to.id,
        r1: r1,
        c1: c1,
        r2: r2,
        c2: c2,
      );
      if (after.encode() == a.encode()) continue;
      out.add(CommentAnchorMove(t.uuid.uuid, a, after));
    }
    return out;
  }

  void dispose() => editor.applyListeners.remove(_onApply);
}
