/// Change notifications of the deck model (02 §11 "Change events"): they
/// drive repaint, thumbnail invalidation, the navigator and the inspector.
library;

/// One change notification of a `DeckModel` ingestion batch.
sealed class DeckChangeEvent {
  const DeckChangeEvent();
}

/// The `deck` row changed (title, size, appearance, numbering, …).
final class DeckChanged extends DeckChangeEvent {
  /// Creates the event.
  DeckChanged(this.columns);

  /// Changed column names (all columns on insert).
  final Set<String> columns;

  @override
  String toString() => 'DeckChanged($columns)';
}

/// Slide rows were added, removed or changed (any column).
final class SlidesChanged extends DeckChangeEvent {
  /// Creates the event.
  SlidesChanged({
    Set<String>? slideIds,
    Set<String>? added,
    Set<String>? removed,
    Map<String, Set<String>>? columns,
  }) : slideIds = slideIds ?? {},
       added = added ?? {},
       removed = removed ?? {},
       columns = columns ?? {};

  /// Every affected slide (incl. [added] and [removed]).
  final Set<String> slideIds;

  /// Changed column names per slide (all columns for added and removed
  /// slides; a slide missing here counts as entirely changed).
  final Map<String, Set<String>> columns;

  /// Whether [column] may have changed on slide [slideId].
  bool changed(String slideId, String column) =>
      columns[slideId]?.contains(column) ?? true;

  /// Slides that appeared.
  final Set<String> added;

  /// Slides that disappeared.
  final Set<String> removed;

  @override
  String toString() =>
      'SlidesChanged($slideIds, added: $added, removed: $removed)';
}

/// The flattened presentation order or the group structure changed: a
/// slide or group was added/removed, or its `sortKey`/`groupId` changed, or
/// a group's title/color/skip changed (navigator rows).
final class OrderChanged extends DeckChangeEvent {
  /// Creates the event.
  OrderChanged({Set<String>? slideIds, Set<String>? groupIds})
    : slideIds = slideIds ?? {},
      groupIds = groupIds ?? {};

  /// Slides whose position changed.
  final Set<String> slideIds;

  /// Groups that changed.
  final Set<String> groupIds;

  @override
  String toString() => 'OrderChanged(slides: $slideIds, groups: $groupIds)';
}

/// Elements changed — the element rows themselves or their dependent rows
/// (table axes/cells, code states, chart links, which report their
/// element). [ownerIds] are the slides, layouts and masters holding them.
final class ElementsChanged extends DeckChangeEvent {
  /// Creates the event.
  ElementsChanged({
    Set<String>? slideIds,
    Set<String>? elementIds,
    Set<String>? ownerIds,
  }) : slideIds = slideIds ?? {},
       elementIds = elementIds ?? {},
       ownerIds = ownerIds ?? {};

  /// Slides whose elements changed.
  final Set<String> slideIds;

  /// Changed elements (incl. added/removed ones).
  final Set<String> elementIds;

  /// Owners (slides, layouts, masters) of the changed elements.
  final Set<String> ownerIds;

  @override
  String toString() =>
      'ElementsChanged(slides: $slideIds, elements: $elementIds)';
}

/// Themes, masters or layouts changed (their rows or their elements): every
/// slide using them re-resolves.
final class ThemeChanged extends DeckChangeEvent {
  /// Creates the event.
  ThemeChanged({
    Set<String>? themeIds,
    Set<String>? masterIds,
    Set<String>? layoutIds,
  }) : themeIds = themeIds ?? {},
       masterIds = masterIds ?? {},
       layoutIds = layoutIds ?? {};

  /// Changed themes.
  final Set<String> themeIds;

  /// Changed masters (rows or elements).
  final Set<String> masterIds;

  /// Changed layouts (rows or elements).
  final Set<String> layoutIds;

  @override
  String toString() =>
      'ThemeChanged(themes: $themeIds, masters: $masterIds, layouts: $layoutIds)';
}

/// Builds (animations) of slides changed.
final class BuildsChanged extends DeckChangeEvent {
  /// Creates the event.
  BuildsChanged({Set<String>? slideIds, Set<String>? buildIds})
    : slideIds = slideIds ?? {},
      buildIds = buildIds ?? {};

  /// Slides whose builds changed.
  final Set<String> slideIds;

  /// Changed builds.
  final Set<String> buildIds;

  @override
  String toString() => 'BuildsChanged($slideIds, $buildIds)';
}

/// Rows of a table the model stores without interpretation changed.
final class OtherRowsChanged extends DeckChangeEvent {
  /// Creates the event.
  OtherRowsChanged(this.table, this.ids);

  /// Table name.
  final String table;

  /// Row ids.
  final Set<String> ids;

  @override
  String toString() => 'OtherRowsChanged($table, $ids)';
}

/// Where the changes of a batch came from.
enum DeckChangeOrigin {
  /// A local plan, undo/redo or `applyChanges` of this client.
  local,

  /// A sync merge (other devices, the server).
  remote,

  /// A (re)load from the replica, a snapshot or a version.
  load,
}

/// The events of one ingestion (one plan, one remote merge, one load).
final class DeckChangeBatch {
  /// Creates a batch.
  const DeckChangeBatch(this.events, {this.origin = DeckChangeOrigin.local});

  /// The events (at most one per event type).
  final List<DeckChangeEvent> events;

  /// Where the changes came from.
  final DeckChangeOrigin origin;

  /// Whether nothing changed.
  bool get isEmpty => events.isEmpty;

  /// Whether the batch came from a sync merge.
  bool get isRemote => origin == DeckChangeOrigin.remote;

  /// Events of type [T].
  Iterable<T> whereType<T extends DeckChangeEvent>() => events.whereType<T>();

  /// The first event of type [T], or null.
  T? event<T extends DeckChangeEvent>() {
    for (final e in events) {
      if (e is T) return e;
    }
    return null;
  }

  /// Every slide whose rendering may have changed directly (slide rows,
  /// their elements, their builds). Theme/layout changes are reported by
  /// [ThemeChanged]; consumers map them to the slides using them.
  Set<String> get touchedSlideIds => {
    ...?event<SlidesChanged>()?.slideIds,
    ...?event<ElementsChanged>()?.slideIds,
    ...?event<BuildsChanged>()?.slideIds,
  };

  @override
  String toString() => 'DeckChangeBatch(${origin.name}, $events)';
}
