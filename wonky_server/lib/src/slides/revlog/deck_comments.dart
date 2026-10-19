import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/model.dart'
    show DeckModelIndexes, DeckReader, SlidesText;
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../../platform/common/models.dart';
import 'slides_revlog.dart';

/// The ids of a Slides comment anchor (Slides 09 §3.1): `slide` anchors
/// `{"v":1,"slideId":…}`, `element` anchors `{"v":1,"slideId":…,
/// "elementId":…}` — the element id is authoritative, the slide id a hint.
final class DeckCommentAnchorIds {
  /// Creates the ids.
  const DeckCommentAnchorIds({this.slideId, this.elementId});

  /// Parses a slide or element anchor (null for other kinds and malformed
  /// JSON).
  static DeckCommentAnchorIds? of(CommentAnchorKind kind, String json) {
    if (kind != CommentAnchorKind.slide && kind != CommentAnchorKind.element) {
      return null;
    }
    try {
      final j = jsonDecode(json);
      if (j is! Map) return null;
      final slide = j['slideId'];
      final element = j['elementId'];
      return DeckCommentAnchorIds(
        slideId: slide is String ? slide : null,
        elementId: kind == CommentAnchorKind.element && element is String
            ? element
            : null,
      );
    } on FormatException {
      return null;
    }
  }

  /// The slide (hint for element anchors).
  final String? slideId;

  /// The element.
  final String? elementId;
}

/// Notification payload extras of deck comments (Slides 09 §3.6):
/// `slideNumber` (1-based, presentation order) and `slideTitle` of the
/// anchor's slide (the element's current slide for element anchors), from
/// the headless deck. Empty for other anchors or unresolvable ones.
abstract final class DeckCommentPayload {
  /// The extras of [thread] on [item].
  static Future<Map<String, Object?>> extras(
    Session session,
    DriveItem item,
    CommentThread thread,
  ) async {
    final a = DeckCommentAnchorIds.of(thread.anchorKind, thread.anchorJson);
    final file = item.contentRef;
    if (a == null || file == null) return const {};
    final deck = await SlidesRevlog.model(session, file);
    final elementSlide = a.elementId == null
        ? null
        : deck.element(a.elementId!)?.slideId;
    final slideId = elementSlide ?? a.slideId;
    if (slideId == null) return const {};
    final index = deck.indexes.order.indexOf(slideId);
    if (index < 0) return const {};
    return {'slideNumber': index + 1, 'slideTitle': titleOf(deck, slideId)};
  }

  /// The plain text of [slideId]'s title placeholder ('' without one).
  static String titleOf(DeckReader deck, String slideId) {
    for (final e in deck.elementsOf(slideId)) {
      if (e.placeholderType == SlidePlaceholderType.title) {
        return SlidesText.plainText(e.text).trim();
      }
    }
    return '';
  }
}
