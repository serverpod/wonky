import 'dart:async';

import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart' show FractionalIndex;

import '../../schema/slides_schema.dart';
import 'deck_reader.dart';
import 'events.dart';
import 'kinds.dart';
import 'records.dart';

/// The in-memory deck (02 §11): built from synced rows, patched by local
/// plans, undo/redo and remote merges, and read by the editor, presenter,
/// PDF exporter, server headless tools and version views.
///
/// [applyChanges] is the single ingestion path. This class holds the
/// records per table with parent indexes and the flattened slide order;
/// the richer indexes and resolvers of 02 §11 (`SlideOrder` with slide
/// numbers and effective skip, `ElementTree`, `PlaceholderIndex`,
/// `SlideResolver`, …) are added by SL-7 behind this API.
final class DeckModel implements DeckReader {
  /// Creates an empty model for deck [deckId].
  DeckModel({required this.deckId});

  /// Builds a model from full rows `(table, columns)` (replica load,
  /// snapshot, fixture). No event is emitted.
  factory DeckModel.fromRows(
    String deckId,
    Iterable<(String table, Map<String, Object?> columns)> rows,
  ) {
    final m = DeckModel(deckId: deckId);
    m.applyChanges([
      for (final (t, c) in rows)
        RowChange.insert(t, c[SlidesCols.id]! as String, c),
    ], silent: true);
    return m;
  }

  @override
  final String deckId;

  final Map<String, Map<String, SlidesRecord>> _tables = {};

  /// Parent buckets per table: parent key → ids.
  final Map<String, Map<String, Set<String>>> _buckets = {};

  /// Sorted lists per `table|parentKey` (invalidated with their bucket).
  final Map<String, List<SlidesRecord>> _sorted = {};

  List<SlideRec>? _slideOrder;
  List<SlideGroupRec>? _groupOrder;
  List<DeckThemeRec>? _themeOrder;

  final StreamController<DeckChangeBatch> _controller =
      StreamController.broadcast(sync: true);
  final List<void Function(DeckChangeBatch)> _listeners = [];

  /// Batches of change events, emitted synchronously after each ingestion.
  Stream<DeckChangeBatch> get changes => _controller.stream;

  /// Adds a synchronous listener (called before [changes] subscribers).
  void addListener(void Function(DeckChangeBatch batch) listener) =>
      _listeners.add(listener);

  /// Removes a listener.
  void removeListener(void Function(DeckChangeBatch batch) listener) =>
      _listeners.remove(listener);

  /// Releases the stream.
  Future<void> dispose() => _controller.close();

  int _version = 0;

  @override
  int get version => _version;

  // ---------------------------------------------------------------------------
  // Reading.

  @override
  DeckRec? get deck => _tables[SlidesTables.deck]?[deckId] as DeckRec?;

  @override
  SlidesRecord? record(String table, String id) => _tables[table]?[id];

  @override
  Iterable<SlidesRecord> records(String table) =>
      _tables[table]?.values ?? const [];

  @override
  Map<String, Object?>? currentColumns(String table, String rowId) =>
      record(table, rowId)?.toColumns();

  /// Number of rows of [table].
  int count(String table) => _tables[table]?.length ?? 0;

  @override
  SlideRec? slide(String id) => record(SlidesTables.slide, id) as SlideRec?;

  @override
  SlideGroupRec? group(String id) =>
      record(SlidesTables.slideGroup, id) as SlideGroupRec?;

  @override
  SlideElementRec? element(String id) =>
      record(SlidesTables.slideElement, id) as SlideElementRec?;

  @override
  DeckThemeRec? theme(String id) =>
      record(SlidesTables.deckTheme, id) as DeckThemeRec?;

  @override
  SlideMasterRec? master(String id) =>
      record(SlidesTables.slideMaster, id) as SlideMasterRec?;

  @override
  SlideLayoutRec? layout(String id) =>
      record(SlidesTables.slideLayout, id) as SlideLayoutRec?;

  @override
  SlideBuildRec? build(String id) =>
      record(SlidesTables.slideBuild, id) as SlideBuildRec?;

  @override
  List<DeckThemeRec> get themes => _themeOrder ??= List.unmodifiable(
    _sortedBy(records(SlidesTables.deckTheme).cast<DeckThemeRec>()),
  );

  @override
  DeckThemeRec? get defaultTheme {
    final id = deck?.themeId;
    final t = id == null ? null : theme(id);
    if (t != null) return t;
    DeckThemeRec? best;
    for (final r in records(SlidesTables.deckTheme)) {
      if (best == null || r.id.compareTo(best.id) < 0) {
        best = r as DeckThemeRec;
      }
    }
    return best;
  }

  @override
  List<SlideMasterRec> mastersOf(String themeId) =>
      _children(SlidesTables.slideMaster, themeId).cast();

  @override
  List<SlideLayoutRec> layoutsOf(String masterId) =>
      _children(SlidesTables.slideLayout, masterId).cast();

  @override
  List<SlideGroupRec> get groups => _groupOrder ??= List.unmodifiable(
    _sortedBy(records(SlidesTables.slideGroup).cast<SlideGroupRec>()),
  );

  @override
  List<SlideRec> get slides =>
      _slideOrder ??= List.unmodifiable(_flattenSlides());

  @override
  List<SlideRec> slidesInGroup(String groupId) =>
      _children(SlidesTables.slide, groupId).cast();

  @override
  List<SlideElementRec> elementsOf(String ownerId, {String? parentId}) {
    final all = _children(SlidesTables.slideElement, ownerId);
    return [
      for (final r in all)
        if ((r as SlideElementRec).parentId == parentId) r,
    ];
  }

  @override
  Iterable<SlideElementRec> allElementsOf(String ownerId) =>
      _bucketRecords(SlidesTables.slideElement, ownerId).cast();

  @override
  List<SlideTableAxisRec> axesOf(
    String elementId,
    TableAxisDimension dimension,
  ) => [
    for (final r in _children(SlidesTables.slideTableAxis, elementId))
      if ((r as SlideTableAxisRec).dimension == dimension) r,
  ];

  @override
  Iterable<SlideTableCellRec> cellsOf(String elementId) =>
      _bucketRecords(SlidesTables.slideTableCell, elementId).cast();

  @override
  List<SlideBuildRec> buildsOf(String slideId) =>
      _children(SlidesTables.slideBuild, slideId).cast();

  @override
  List<CodeStateRec> codeStatesOf(String elementId) =>
      _children(SlidesTables.codeState, elementId).cast();

  @override
  ChartLinkRec? chartLinkOf(String elementId) {
    final r = _bucketRecords(SlidesTables.chartLink, elementId);
    return r.isEmpty ? null : r.first as ChartLinkRec;
  }

  /// Canonical dump of every row: table → id → columns, keys sorted (tests:
  /// replicas identical, undo returns to the start).
  Map<String, Map<String, Map<String, Object?>>> dump() {
    final tables = _tables.keys.toList()..sort();
    return {
      for (final t in tables)
        if (_tables[t]!.isNotEmpty)
          t: {
            for (final id in (_tables[t]!.keys.toList()..sort()))
              id: _sortedColumns(_tables[t]![id]!.columns),
          },
    };
  }

  static Map<String, Object?> _sortedColumns(Map<String, Object?> c) => {
    for (final k in (c.keys.toList()..sort())) k: c[k],
  };

  List<SlideRec> _flattenSlides() {
    // Top-level key space: groups and ungrouped slides (02 §3.4).
    final top = <(String key, String id, Object item)>[];
    for (final g in records(SlidesTables.slideGroup)) {
      final group = g as SlideGroupRec;
      top.add((group.sortKey, group.id, group));
    }
    final orphans = <SlideRec>[];
    for (final s in _bucketRecords(SlidesTables.slide, '')) {
      final slide = s as SlideRec;
      top.add((slide.sortKey, slide.id, slide));
    }
    for (final MapEntry(:key, :value)
        in _buckets[SlidesTables.slide]?.entries ??
            const <MapEntry<String, Set<String>>>[]) {
      if (key.isEmpty || group(key) != null) continue;
      for (final id in value) {
        orphans.add(slide(id)!);
      }
    }
    top.sort((a, b) => FractionalIndex.compare(a.$1, a.$2, b.$1, b.$2));
    final out = <SlideRec>[];
    for (final (_, _, item) in top) {
      if (item is SlideRec) {
        out.add(item);
      } else {
        out.addAll(slidesInGroup((item as SlideGroupRec).id));
      }
    }
    // Orphans: at the end of the top level in (sortKey, id) order (02 §10).
    out.addAll(_sortedBy(orphans));
    return out;
  }

  static List<T> _sortedBy<T extends SlidesRecord>(Iterable<T> records) {
    final list = records.toList();
    list.sort(
      (a, b) => FractionalIndex.compare(_orderKey(a), a.id, _orderKey(b), b.id),
    );
    return list;
  }

  static String _orderKey(SlidesRecord r) =>
      r is SlideElementRec ? r.zKey : r.sortKeyOrEmpty;

  Iterable<SlidesRecord> _bucketRecords(String table, String key) {
    final ids = _buckets[table]?[key];
    if (ids == null) return const [];
    final t = _tables[table]!;
    return [for (final id in ids) t[id]!];
  }

  List<SlidesRecord> _children(String table, String key) =>
      _sorted['$table|$key'] ??= List.unmodifiable(
        _sortedBy(_bucketRecords(table, key)),
      );

  /// The parent bucket key of [r] (null = not indexed by parent).
  static String? _parentKey(SlidesRecord r) => switch (r) {
    SlideMasterRec() => r.themeId ?? '',
    SlideLayoutRec() => r.masterId ?? '',
    SlideRec() => r.groupId ?? '',
    SlideElementRec() => r.ownerId ?? '',
    SlideTableAxisRec() => r.elementId ?? '',
    SlideTableCellRec() => r.elementId ?? '',
    SlideBuildRec() => r.slideId ?? '',
    CodeStateRec() => r.elementId ?? '',
    ChartLinkRec() => r.elementId ?? '',
    _ => null,
  };

  void _index(SlidesRecord r) {
    final key = _parentKey(r);
    if (key == null) return;
    (_buckets[r.table] ??= {}).putIfAbsent(key, () => {}).add(r.id);
    _sorted.remove('${r.table}|$key');
  }

  void _unindex(SlidesRecord r) {
    final key = _parentKey(r);
    if (key == null) return;
    final b = _buckets[r.table];
    final ids = b?[key];
    if (ids != null) {
      ids.remove(r.id);
      if (ids.isEmpty) b!.remove(key);
    }
    _sorted.remove('${r.table}|$key');
  }

  // ---------------------------------------------------------------------------
  // Ingestion.

  /// Applies row changes (local plan, undo/redo, remote merge, load) and
  /// emits one batch. Updates of missing rows are upserts of the given
  /// columns; deletes of missing rows are ignored. With [silent], no event
  /// is emitted.
  DeckChangeBatch applyChanges(
    Iterable<RowChange> changes, {
    DeckChangeOrigin origin = DeckChangeOrigin.local,
    bool silent = false,
  }) {
    final b = _BatchBuilder(this);
    for (final c in changes) {
      final t = _tables.putIfAbsent(c.table, () => {});
      final old = t[c.rowId];
      switch (c.op) {
        case RowOp.insert:
        case RowOp.update:
          final next = old == null || c.op == RowOp.insert
              ? slidesRecordFromColumns(c.table, {
                  ...c.columnsAfter,
                  SlidesCols.id: c.rowId,
                })
              : old.withColumns(c.columnsAfter);
          if (old != null) _unindex(old);
          t[c.rowId] = next;
          _index(next);
          b.changed(old, next);
        case RowOp.delete:
          if (old == null) continue;
          _unindex(old);
          t.remove(c.rowId);
          b.changed(old, null);
      }
    }
    final batch = b.build(origin);
    _version++;
    if (!silent && !batch.isEmpty) {
      for (final l in List.of(_listeners)) {
        l(batch);
      }
      _controller.add(batch);
    }
    return batch;
  }

  /// Applies a plan's changes.
  DeckChangeBatch applyPlan(MutationPlan<ChangeSummary> plan) =>
      applyChanges(plan.changes);

  void _invalidateOrder(String table) {
    switch (table) {
      case SlidesTables.slide:
      case SlidesTables.slideGroup:
        _slideOrder = null;
        _groupOrder = null;
      case SlidesTables.deckTheme:
        _themeOrder = null;
    }
  }

  /// Puts the updated row [slide] into the cached slide order in place (a
  /// change of columns the order doesn't depend on: notes, title, …).
  void _replaceInOrder(SlideRec slide) {
    final order = _slideOrder;
    if (order == null) return;
    final i = order.indexWhere((s) => s.id == slide.id);
    _slideOrder = i < 0 ? null : List.unmodifiable([...order]..[i] = slide);
  }
}

/// Collects the events of one ingestion.
final class _BatchBuilder {
  _BatchBuilder(this.model);

  final DeckModel model;

  Set<String>? _deckColumns;
  SlidesChanged? _slides;
  OrderChanged? _order;
  ElementsChanged? _elements;
  ThemeChanged? _theme;
  BuildsChanged? _builds;
  final Map<String, OtherRowsChanged> _other = {};

  SlidesChanged get slides => _slides ??= SlidesChanged();
  OrderChanged get order => _order ??= OrderChanged();
  ElementsChanged get elements => _elements ??= ElementsChanged();
  ThemeChanged get theme => _theme ??= ThemeChanged();
  BuildsChanged get builds => _builds ??= BuildsChanged();

  static Set<String> _diff(SlidesRecord? a, SlidesRecord? b) {
    if (a == null) return b!.columns.keys.toSet();
    if (b == null) return a.columns.keys.toSet();
    return {
      for (final k in {...a.columns.keys, ...b.columns.keys})
        if (a.columns[k] != b.columns[k]) k,
    };
  }

  void changed(SlidesRecord? old, SlidesRecord? next) {
    final r = (next ?? old)!;
    final diff = _diff(old, next);
    if (diff.isEmpty) return;
    if (next is SlideRec &&
        old != null &&
        !diff.contains(SlidesCols.sortKey) &&
        !diff.contains(SlideCols.groupId)) {
      // Notes, title, … : the order stays, only the row is replaced.
      model._replaceInOrder(next);
    } else {
      model._invalidateOrder(r.table);
    }
    switch (r) {
      case DeckRec():
        (_deckColumns ??= {}).addAll(diff);
      case DeckThemeRec():
        theme.themeIds.add(r.id);
      case SlideMasterRec():
        theme.masterIds.add(r.id);
      case SlideLayoutRec():
        theme.layoutIds.add(r.id);
      case SlideGroupRec():
        order.groupIds.add(r.id);
      case SlideRec():
        slides.slideIds.add(r.id);
        if (old == null) slides.added.add(r.id);
        if (next == null) slides.removed.add(r.id);
        if (old != null && next != null) {
          (slides.columns[r.id] ??= {}).addAll(diff);
        }
        if (old == null ||
            next == null ||
            diff.contains(SlidesCols.sortKey) ||
            diff.contains(SlideCols.groupId)) {
          order.slideIds.add(r.id);
        }
      case SlideElementRec():
        elements.elementIds.add(r.id);
        for (final e in [old, next]) {
          if (e is SlideElementRec) _owner(e);
        }
      case SlideTableAxisRec(:final elementId) ||
          SlideTableCellRec(:final elementId) ||
          CodeStateRec(:final elementId) ||
          ChartLinkRec(:final elementId):
        if (elementId == null) return;
        elements.elementIds.add(elementId);
        final el = model.element(elementId);
        if (el != null) _owner(el);
      case SlideBuildRec():
        builds.buildIds.add(r.id);
        for (final b in [old, next]) {
          final s = (b as SlideBuildRec?)?.slideId;
          if (s != null) builds.slideIds.add(s);
        }
      default:
        (_other[r.table] ??= OtherRowsChanged(r.table, {})).ids.add(r.id);
    }
  }

  void _owner(SlideElementRec e) {
    final owner = e.ownerId;
    if (owner == null) return;
    elements.ownerIds.add(owner);
    switch (e.ownerKind) {
      case ElementOwnerKind.slide:
        elements.slideIds.add(owner);
      case ElementOwnerKind.layout:
        theme.layoutIds.add(owner);
      case ElementOwnerKind.master:
        theme.masterIds.add(owner);
      case null:
        break;
    }
  }

  DeckChangeBatch build(DeckChangeOrigin origin) => DeckChangeBatch([
    if (_deckColumns != null) DeckChanged(_deckColumns!),
    ?_slides,
    ?_order,
    ?_elements,
    ?_theme,
    ?_builds,
    ..._other.values,
  ], origin: origin);
}
