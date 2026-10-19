import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/model.dart' show SlidesText;
import 'package:wonky_slides_core/templates.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_sync_models/ids.dart' show SequentialIdGenerator;

import '../../platform/common/time.dart';

/// The built-in presentation templates on the server (Slides 04 §15,
/// SL-22): the decks are the core's `SlidesTemplates` (planner operations
/// on built-in themes), created by
/// `drive.createPresentation(templateUuid)`; the gallery's preview text and
/// size estimate come from a preview build.
abstract final class SlidesTemplateDecks {
  static final Map<String, SlidesTemplateDeck> _previews = {};

  /// A build of [t] with fixed ids and time (previews, estimates; never
  /// written).
  static SlidesTemplateDeck preview(SlidesTemplate t) =>
      _previews[t.key] ??= t.build(
        deckId: '00000000-0000-4000-8000-000000000000',
        userId: '00000000-0000-4000-8000-000000000001',
        now: DateTime.utc(2026),
        ids: SequentialIdGenerator(1),
      );

  static final Map<String, int> _sizes = {};

  /// The pre-check size of a deck made from [t] (Drive 03 §6.5): the JSON
  /// size of its rows (the stored size is measured after creation).
  static int estimate(SlidesTemplate t) => _sizes[t.key] ??= () {
    var n = 0;
    for (final c in preview(t).inserts) {
      n += utf8
          .encode(
            jsonEncode(
              c.columnsAfter,
              toEncodable: (v) =>
                  v is DateTime ? v.toIso8601String() : v.toString(),
            ),
          )
          .length;
    }
    return n;
  }();

  /// The card text of [t]: the title slide's title as a `# ` heading line,
  /// then its subtitle (`TemplateView.previewText`, suite 05 §3.1).
  static String previewText(SlidesTemplate t) {
    final m = preview(t).model;
    final first = m.slides.first;
    final lines = <String>[];
    for (final e in m.elementsOf(first.id)) {
      final text = SlidesText.plainText(e.text).trim();
      if (text.isEmpty) continue;
      lines.add(lines.isEmpty ? '# $text' : text);
    }
    return lines.join('\n');
  }

  /// The rows of the deck of [template] titled [title] for the new deck
  /// [deckId] (the creation op of `drive.createPresentation(templateUuid)`).
  static List<RowChange> changes(
    SlidesTemplate template, {
    required UuidValue deckId,
    required UuidValue authorUuid,
    required String title,
  }) => template
      .build(
        deckId: deckId.uuid,
        userId: authorUuid.uuid,
        now: nowUtc(),
        title: title,
      )
      .inserts;
}
