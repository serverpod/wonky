import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show TextEditingController;

/// Clicks on items edited in place (grid items, table cells; Write 04
/// §18.4), counted from raw pointer events: the first click turns the
/// rendered item into a text field, which never sees that click, and on the
/// web the field's own double click doesn't fire there, so double and triple
/// clicks are recognized here, on the rendered item and on the field alike.
///
/// - The caret goes where the click was: [renderedOffsetAt] finds the
///   position in the rendered text, [sourceOffset] the matching position in
///   the item's inline Markdown source.
/// - [down] and [up] count consecutive clicks at one place ([count]): the
///   second selects the word at the caret ([wordAt]), the third the text.
class FieldClicks {
  Duration? _upAt;
  Offset? _upPosition;
  int _count = 0;

  /// The clicks of the current series (1 for a single click), as of the
  /// last [up].
  int get count => _count;

  /// A press: the next click of a series when it follows the last click
  /// closely, at the same place.
  void down(PointerDownEvent event) {
    release();
    final upAt = _upAt;
    final upPosition = _upPosition;
    final next =
        upAt != null &&
        upPosition != null &&
        event.timeStamp - upAt <= kDoubleTapTimeout &&
        (event.position - upPosition).distance <= kDoubleTapSlop;
    _count = next ? _count + 1 : 1;
  }

  /// The press was released: the clicks of the series so far.
  int up(PointerUpEvent event) {
    _upAt = event.timeStamp;
    _upPosition = event.position;
    return _count;
  }

  TextEditingController? _heldIn;
  TextSelection? _held;
  String? _heldText;

  /// Selects [selection] in [text] for a double or triple click and keeps it
  /// until the next press, key or edit ([release]): the field's own handling
  /// of the second click (a single click, [kDoubleTapTimeout] later)
  /// collapsed it again.
  void select(TextEditingController text, TextSelection selection) {
    release();
    text.selection = selection;
    _heldIn = text;
    _held = selection;
    _heldText = text.text;
    text.addListener(_keep);
  }

  void _keep() {
    final text = _heldIn;
    final held = _held;
    if (text == null || held == null) return;
    if (text.text != _heldText) {
      release();
      return;
    }
    if (text.selection != held && text.selection.isCollapsed) {
      text.selection = held;
    }
  }

  /// Stops keeping a selection made by [select].
  void release() {
    _heldIn?.removeListener(_keep);
    _heldIn = null;
    _held = null;
    _heldText = null;
  }

  /// The word around [offset] in [text] (letters, digits, `_` and
  /// apostrophes), or a collapsed selection at [offset] outside words.
  static TextSelection wordAt(String text, int offset) {
    final at = offset.clamp(0, text.length);
    bool isWord(int i) => i >= 0 && i < text.length && _word.hasMatch(text[i]);
    var start = at;
    var end = at;
    if (!isWord(at) && isWord(at - 1)) start = end = at - 1;
    if (!isWord(start)) return TextSelection.collapsed(offset: at);
    while (isWord(start - 1)) {
      start--;
    }
    while (isWord(end)) {
      end++;
    }
    return TextSelection(baseOffset: start, extentOffset: end);
  }

  static final _word = RegExp(r"[\p{L}\p{N}_'’]", unicode: true);

  /// The character offset of [global] in the first text under [box] (the
  /// rendered item), or `null` when it holds no text.
  static int? renderedOffsetAt(RenderObject? box, Offset global) {
    RenderParagraph? paragraph;
    void find(RenderObject node) {
      if (paragraph != null) return;
      if (node is RenderParagraph) {
        paragraph = node;
        return;
      }
      node.visitChildren(find);
    }

    if (box == null) return null;
    find(box);
    final p = paragraph;
    if (p == null || !p.attached) return null;
    return p.getPositionForOffset(p.globalToLocal(global)).offset;
  }

  /// The offset in [source] (inline Markdown) of the character at
  /// [plainOffset] in its rendered text [plain]: both are walked together,
  /// skipping what the rendering drops (markup, escapes, a link's
  /// `](url)`).
  static int sourceOffset(String source, String plain, int plainOffset) {
    var s = 0;
    for (var p = 0; p < plainOffset && p < plain.length; p++) {
      while (s < source.length) {
        final link = _linkTail.matchAsPrefix(source, s);
        if (link != null) {
          s = link.end;
          continue;
        }
        if (source[s] == plain[p]) break;
        s++;
      }
      if (s >= source.length) return source.length;
      s++;
    }
    // Past the markup that opens the next character (`**b`: before `b`
    // would split the marker; after it keeps the formatting).
    if (plainOffset < plain.length) {
      while (s < source.length && source[s] != plain[plainOffset]) {
        final link = _linkTail.matchAsPrefix(source, s);
        if (link != null && plainOffset > 0) break;
        s++;
      }
    }
    return s.clamp(0, source.length);
  }

  static final _linkTail = RegExp(r'\]\([^)]*\)');
}
