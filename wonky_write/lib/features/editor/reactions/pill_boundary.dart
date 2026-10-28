import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Rect, TextDirection;
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:super_editor/super_editor.dart';

import '../attributions/wonky_attributions.dart';

/// The caret at the end of a chip, button or arrow link (Write 11 §7.4):
/// inside by default (typed text extends the element), outside after → (typed
/// text follows it) or a click past the element. ← at the same place goes
/// back inside (in right-to-left blocks the keys swap). The state belongs
/// to one caret position and ends when the caret moves.
class PillBoundary extends ChangeNotifier {
  DocumentPosition? _outside;

  /// Whether a caret at [position] types after the element ending there.
  bool isOutsideAt(DocumentPosition position) => _outside == position;

  /// Like [isOutsideAt], whatever the caret's affinity.
  bool _outsideAtOffset(String nodeId, int offset) {
    final outside = _outside;
    final p = outside?.nodePosition;
    return outside != null &&
        outside.nodeId == nodeId &&
        p is TextNodePosition &&
        p.offset == offset;
  }

  /// Puts a caret at [position] outside the element ending there.
  void leaveAt(DocumentPosition position) {
    if (_outside == position) return;
    _outside = position;
    notifyListeners();
  }

  /// Puts the caret back inside (or forgets a position the caret left).
  void clear() {
    if (_outside == null) return;
    _outside = null;
    notifyListeners();
  }

  /// Keeps the state only while the caret stays at its position.
  void onSelectionChanged(DocumentSelection? selection) {
    final outside = _outside;
    if (outside == null) return;
    if (selection == null ||
        !selection.isCollapsed ||
        selection.extent != outside) {
      clear();
    }
  }

  /// Where the caret is drawn at the edges of an inline element (for
  /// `DefaultCaretOverlayBuilder`). The room for a pill's padding and an
  /// arrow is letter spacing (`PillSpacingStylePhase`), so the caret's own
  /// place is after it:
  /// - at the end of a chip, button or arrow link, inside it: right after the
  ///   last glyph, clearly in the element; outside it: just past the pill's
  ///   edge (or after the arrow);
  /// - at the start of a chip or button after a space (typed text goes before
  ///   the element): before the pill, not on its first glyph.
  Rect caretRect(Document document, DocumentPosition position, Rect rect) {
    final p = position.nodePosition;
    final node = document.getNodeById(position.nodeId);
    // The caret is 1.2 em high (SE-11; not on Android and iOS).
    if (p is! TextNodePosition || node is! TextNode || _mobile) return rect;
    final text = node.text;
    final em = rect.height / 1.2;
    final ending = endingAt(text, p.offset);
    if (ending.isNotEmpty) {
      final pill = ending.any(_isPillShaped);
      if (isOutsideAt(position)) {
        // The pill's edge is 0.05 em short of the caret: a little room,
        // when a space or nothing follows.
        final next = p.offset < text.length
            ? text.toPlainText()[p.offset]
            : ' ';
        return pill && next.trim().isEmpty ? rect.translate(em * 0.1, 0) : rect;
      }
      final gap = pill ? PillGapAttribution.pill : PillGapAttribution.arrow;
      return rect.translate(-em * gap.em, 0);
    }
    if (p.offset > 0 &&
        p.offset < text.length &&
        text.toPlainText()[p.offset - 1] == ' ' &&
        text.getAllAttributionsAt(p.offset).any(_isPillShaped) &&
        !text.getAllAttributionsAt(p.offset - 1).any(_isPillShaped)) {
      // Before the space's gap (0.6 em), which holds the pill's left
      // padding (0.55 em).
      return rect.translate(-em * (PillGapAttribution.space.em + 0.1), 0);
    }
    return rect;
  }

  static bool _isPillShaped(Attribution a) =>
      a is ChipAttribution || a is LinkStyleAttribution && a.isButton;

  static bool get _mobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether [a] belongs to an element the caret can be inside of at its end.
  static bool isPill(Attribution a) =>
      a is ChipAttribution || a is LinkStyleAttribution;

  /// The attributions of the element ending right before [offset] in
  /// [text] (a chip, or a styled link with its link), or an empty set when
  /// no such element ends there.
  static Set<Attribution> endingAt(AttributedText text, int offset) {
    if (offset <= 0 || offset > text.length) return const {};
    final before = text.getAllAttributionsAt(offset - 1);
    final after = offset < text.length
        ? text.getAllAttributionsAt(offset)
        : const <Attribution>{};
    final pill = before.where(isPill).where((a) => !after.contains(a));
    if (pill.isEmpty) return const {};
    return {
      ...pill,
      // A styled link carries its link along.
      if (pill.any((a) => a is LinkStyleAttribution))
        ...before.whereType<LinkAttribution>(),
    };
  }
}

/// A click past the end of a chip, button or arrow link, beyond its last
/// character's box (right of it; left in a right-to-left block), puts the
/// caret outside the element, like → does; a click on the element's end
/// puts it inside (Write 11 §7.4). The caret itself is placed by
/// super_editor after this delegate.
class PillBoundaryTapHandler extends ContentTapDelegate {
  PillBoundaryTapHandler({
    required this.document,
    required this.composer,
    required this.boundary,
    this.directionOf,
  });

  final Document document;
  final DocumentComposer composer;
  final PillBoundary boundary;
  final TextDirection Function(String nodeId)? directionOf;

  @override
  TapHandlingInstruction onTap(DocumentTapDetails details) {
    // Shift+click extends the selection.
    if (HardwareKeyboard.instance.isShiftPressed) {
      return TapHandlingInstruction.continueHandling;
    }
    final layout = details.documentLayout;
    final position = layout.getDocumentPositionNearestToOffset(
      details.layoutOffset,
    );
    final p = position?.nodePosition;
    final node = position == null
        ? null
        : document.getNodeById(position.nodeId);
    if (position == null || p is! TextNodePosition || node is! TextNode) {
      return TapHandlingInstruction.continueHandling;
    }
    final pill = PillBoundary.endingAt(node.text, p.offset);
    if (pill.isEmpty) return TapHandlingInstruction.continueHandling;
    final last = layout.getRectForSelection(
      DocumentPosition(
        nodeId: position.nodeId,
        nodePosition: TextNodePosition(offset: p.offset - 1),
      ),
      position,
    );
    if (last == null) return TapHandlingInstruction.continueHandling;
    // A click on the edge itself (where the caret is drawn) is on the
    // element.
    const edge = 2.0;
    final x = details.layoutOffset.dx;
    final past = directionOf?.call(position.nodeId) == TextDirection.rtl
        ? x < last.left - edge
        : x > last.right + edge;
    // The typing attributes follow when the caret moves; set here too, for a
    // click at the caret's own position.
    final preferences = composer.preferences;
    if (past) {
      boundary.leaveAt(position);
      preferences.removeStyles(pill);
    } else if (boundary._outsideAtOffset(position.nodeId, p.offset)) {
      boundary.clear();
      preferences.addStyles(pill);
    }
    return TapHandlingInstruction.continueHandling;
  }
}
