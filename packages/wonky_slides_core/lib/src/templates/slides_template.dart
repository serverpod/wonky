import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import '../model/api/deck_model.dart';
import '../motion/builds/transition_spec.dart';
import '../ops/plan_context.dart';
import '../theme/model/common.dart';
import 'decks/lesson.dart';
import 'decks/pitch_deck.dart';
import 'decks/portfolio.dart';
import 'decks/product_launch.dart';
import 'decks/project_kickoff.dart';
import 'decks/quarterly_review.dart';
import 'decks/tech_talk.dart';
import 'decks/weekly_update.dart';
import 'decks/workshop.dart';
import 'template_builder.dart';

/// The deck of a built-in template, built for one new deck.
final class SlidesTemplateDeck {
  /// Creates the result.
  const SlidesTemplateDeck({
    required this.template,
    required this.model,
    required this.inserts,
    required this.warnings,
  });

  /// The template.
  final SlidesTemplate template;

  /// The built deck.
  final DeckModel model;

  /// Its rows as inserts in dependency order (a writer's input).
  final List<RowChange> inserts;

  /// Planner warnings (none for a valid template).
  final List<String> warnings;
}

/// A built-in presentation template (Slides 04 §15): a deck made of
/// planner operations on a built-in theme (05 §6) and the built-in
/// layouts, with real sample content. Shipped by the server in the
/// template gallery (`drive.listTemplates`, UUIDv5 `wonky-template:<key>`)
/// and built locally by the app (offline creation in a reserved space,
/// card previews).
final class SlidesTemplate {
  /// Creates a template.
  const SlidesTemplate({
    required this.key,
    required this.name,
    required this.description,
    required this.category,
    required this.themeKey,
    required this.script,
    this.subtitle = '',
    this.defaultTransition,
  });

  /// Stable key (`slides.pitch-deck`); the gallery uuid derives from it.
  final String key;

  /// Display name (gallery card, default deck title).
  final String name;

  /// One-line description.
  final String description;

  /// Gallery category: a `TemplateCategory` value name (`work`,
  /// `projectManagement`, `education`, `personal`, `finance`).
  final String category;

  /// The built-in theme the deck is made with.
  final String themeKey;

  /// The text under the title on the card's fallback miniature.
  final String subtitle;

  /// Adds the slides (the deck, theme and appearance exist already).
  final void Function(TemplateDeckBuilder b) script;

  /// The deck's default transition (`Deck.defaultsJson.transition`, 06
  /// A-06-7), part of the template's design: decks made from a template
  /// play it between slides without an own transition. (The user's
  /// Settings › *Default transition* applies to blank decks only, 06 §5.7.)
  /// Null = cuts.
  final TransitionSpec? defaultTransition;

  /// The gallery uuid: `UUIDv5(URL namespace, "wonky-template:<key>")`
  /// (same as the server's `BuiltinTemplate.uuid`).
  String get uuid => SlidesTemplates.uuidOf(key);

  /// Builds the deck [deckId] titled [title] (default: [name]) for
  /// [userId]. Deterministic for a given [ids] and [now].
  SlidesTemplateDeck build({
    required String deckId,
    required String userId,
    required DateTime now,
    String? title,
    IdGenerator ids = const UuidV7IdGenerator(),
    SlideAppearance? appearance,
  }) {
    final b = TemplateDeckBuilder(
      deckId: deckId,
      title: title ?? name,
      themeKey: themeKey,
      appearance: appearance,
      defaultTransition: defaultTransition,
      ctx: SlidesPlanContext(userId: userId, now: now, ids: ids, isOwner: true),
    );
    script(b);
    return SlidesTemplateDeck(
      template: this,
      model: b.model,
      inserts: b.inserts,
      warnings: List.unmodifiable(b.warnings),
    );
  }
}

/// The built-in presentation templates (Slides 04 §15): nine decks; with
/// *Blank* the gallery's ten (5 in M9 by SL-22, 4 in M10 by SL-36).
abstract final class SlidesTemplates {
  /// Every template, in gallery order.
  static final List<SlidesTemplate> all = List.unmodifiable([
    pitchDeckTemplate,
    projectKickoffTemplate,
    quarterlyReviewTemplate,
    techTalkTemplate,
    lessonTemplate,
    productLaunchTemplate,
    weeklyUpdateTemplate,
    portfolioTemplate,
    workshopTemplate,
  ]);

  /// The template [key], or null.
  static SlidesTemplate? byKey(String key) {
    for (final t in all) {
      if (t.key == key) return t;
    }
    return null;
  }

  static final Map<String, SlidesTemplate> _byUuid = {
    for (final t in all) t.uuid: t,
  };

  /// The template whose gallery uuid is [uuid] (any case), or null.
  static SlidesTemplate? byUuid(String uuid) => _byUuid[uuid.toLowerCase()];

  static final List<int> _urlNamespace = _uuidBytes(
    '6ba7b811-9dad-11d1-80b4-00c04fd430c8',
  );

  /// `UUIDv5(URL namespace, "wonky-template:<key>")` (RFC 4122 §4.3), the
  /// id of built-in templates in the gallery (suite 05 §3.1).
  static String uuidOf(String key) {
    final h = sha1
        .convert([..._urlNamespace, ...utf8.encode('wonky-template:$key')])
        .bytes
        .sublist(0, 16);
    h[6] = (h[6] & 0x0f) | 0x50;
    h[8] = (h[8] & 0x3f) | 0x80;
    final hex = [for (final b in h) b.toRadixString(16).padLeft(2, '0')].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static List<int> _uuidBytes(String uuid) {
    final s = uuid.replaceAll('-', '');
    return [
      for (var i = 0; i < 32; i += 2)
        int.parse(s.substring(i, i + 2), radix: 16),
    ];
  }
}
