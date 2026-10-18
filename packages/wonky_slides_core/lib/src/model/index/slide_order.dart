import 'package:wonky_sync_models/ids.dart' show FractionalIndex;

import '../api/deck_reader.dart';
import '../api/records.dart';

/// One slide in the flattened presentation order (02 §3.4).
final class SlideOrderEntry {
  /// Creates an entry.
  const SlideOrderEntry({
    required this.slide,
    required this.index,
    required this.groupId,
    required this.skipped,
    required this.number,
    required this.orphan,
  });

  /// The slide row.
  final SlideRec slide;

  /// 0-based position in the flattened order.
  final int index;

  /// The effective group (null for top-level and orphan slides).
  final String? groupId;

  /// Effective skip: `slide.skipped || group.skipped` (02 §3.4).
  final bool skipped;

  /// Slide number: position among non-skipped slides starting at
  /// `Deck.firstSlideNumber`; null for skipped slides (05 §5.5).
  final int? number;

  /// Whether the slide's `groupId` names a missing group (02 §10).
  final bool orphan;

  /// The slide id.
  String get id => slide.id;
}

/// A group's range in the flattened order (`[start, end)`; empty groups have
/// `start == end`).
final class SlideGroupRange {
  /// Creates a range.
  const SlideGroupRange(this.group, this.start, this.end);

  /// The group row.
  final SlideGroupRec group;

  /// First index.
  final int start;

  /// Index after the last slide.
  final int end;

  /// Number of slides.
  int get length => end - start;
}

/// A top-level item: a group or an ungrouped slide (orphans excluded).
final class TopLevelItem {
  /// Creates an item.
  const TopLevelItem(this.key, this.id, {required this.isGroup});

  /// `sortKey`.
  final String key;

  /// Row id.
  final String id;

  /// Whether the item is a group.
  final bool isGroup;
}

/// The deck's presentation order index (02 §11 `SlideOrder`): the flattened
/// two-level order with group ranges, id → index, effective skip and slide
/// numbers.
final class SlideOrder {
  SlideOrder._(this.entries, this.groups, this.topLevel, this._byId);

  /// Builds the index of [deck].
  factory SlideOrder.of(DeckReader deck) {
    final top = <TopLevelItem>[];
    for (final g in deck.groups) {
      top.add(TopLevelItem(g.sortKey, g.id, isGroup: true));
    }
    final groupIds = {for (final g in deck.groups) g.id};
    final orphans = <SlideRec>[];
    for (final s in deck.records(_slideTable)) {
      final slide = s as SlideRec;
      final g = slide.groupId;
      if (g == null) {
        top.add(TopLevelItem(slide.sortKey, slide.id, isGroup: false));
      } else if (!groupIds.contains(g)) {
        orphans.add(slide);
      }
    }
    top.sort((a, b) => FractionalIndex.compare(a.key, a.id, b.key, b.id));
    orphans.sort(
      (a, b) => FractionalIndex.compare(a.sortKey, a.id, b.sortKey, b.id),
    );
    final first = deck.deck?.firstSlideNumber ?? 1;
    final entries = <SlideOrderEntry>[];
    final ranges = <SlideGroupRange>[];
    var number = first;
    void add(SlideRec s, {String? group, bool groupSkipped = false}) {
      final skipped = s.skipped || groupSkipped;
      entries.add(
        SlideOrderEntry(
          slide: s,
          index: entries.length,
          groupId: group,
          skipped: skipped,
          number: skipped ? null : number++,
          orphan: s.groupId != null && group == null,
        ),
      );
    }

    for (final item in top) {
      if (!item.isGroup) {
        add(deck.slide(item.id)!);
        continue;
      }
      final g = deck.group(item.id)!;
      final start = entries.length;
      for (final s in deck.slidesInGroup(g.id)) {
        add(s, group: g.id, groupSkipped: g.skipped);
      }
      ranges.add(SlideGroupRange(g, start, entries.length));
    }
    for (final s in orphans) {
      add(s);
    }
    return SlideOrder._(
      List.unmodifiable(entries),
      List.unmodifiable(ranges),
      List.unmodifiable(top),
      {for (final e in entries) e.id: e},
    );
  }

  static const _slideTable = 'slide';

  /// This order with the rows of [slides] replaced, for changes of columns
  /// the order doesn't depend on (not `sortKey`, `groupId` or `skipped`).
  /// Slides that aren't in the order are ignored.
  SlideOrder withSlides(Iterable<SlideRec> slides) {
    final list = [...entries];
    final byId = {..._byId};
    for (final s in slides) {
      final e = byId[s.id];
      if (e == null) continue;
      list[e.index] = byId[s.id] = SlideOrderEntry(
        slide: s,
        index: e.index,
        groupId: e.groupId,
        skipped: e.skipped,
        number: e.number,
        orphan: e.orphan,
      );
    }
    return SlideOrder._(List.unmodifiable(list), groups, topLevel, byId);
  }

  /// Every slide in presentation order.
  final List<SlideOrderEntry> entries;

  /// Top-level groups in order (with their ranges).
  final List<SlideGroupRange> groups;

  /// Top-level items (groups and ungrouped slides) in key order; orphan
  /// slides are not top-level items until repaired.
  final List<TopLevelItem> topLevel;

  final Map<String, SlideOrderEntry> _byId;

  /// Number of slides.
  int get length => entries.length;

  /// The slides in order.
  List<SlideRec> get slides => [for (final e in entries) e.slide];

  /// The entry of [slideId], or null.
  SlideOrderEntry? entry(String slideId) => _byId[slideId];

  /// The index of [slideId], or -1.
  int indexOf(String slideId) => _byId[slideId]?.index ?? -1;

  /// The range of group [groupId], or null.
  SlideGroupRange? range(String groupId) {
    for (final r in groups) {
      if (r.group.id == groupId) return r;
    }
    return null;
  }

  /// The ids of slides that are not skipped, in order.
  List<String> get presentedIds => [
    for (final e in entries)
      if (!e.skipped) e.id,
  ];
}
