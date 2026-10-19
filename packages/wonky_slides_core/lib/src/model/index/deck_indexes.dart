import '../../schema/slides_schema.dart';
import '../api/deck_model.dart';
import '../api/events.dart';
import '../api/records.dart';
import 'element_tree.dart';
import 'placeholder_index.dart';
import 'slide_order.dart';
import 'table_index.dart';
import 'theme_index.dart';

/// The derived indexes of a [DeckModel] (02 §11): [order] (`SlideOrder`),
/// [tree] per owner (`ElementTree`), [themes] (`ThemeIndex`),
/// [placeholders] (`PlaceholderIndex`), [table] per table element
/// (`TableIndex`), builds by element (`BuildIndex`) and per-slide revision
/// counters for memoized resolution.
///
/// Built lazily and invalidated selectively from the model's change
/// batches (a silent ingestion invalidates everything). Get the instance of
/// a model with [DeckIndexes.of] (one per model).
final class DeckIndexes {
  DeckIndexes._(this.model) : _seen = model.version {
    model.addListener(_onBatch);
  }

  static final Expando<DeckIndexes> _cache = Expando('deckIndexes');

  /// The indexes of [model] (created on first use).
  static DeckIndexes of(DeckModel model) =>
      _cache[model] ??= DeckIndexes._(model);

  /// The indexed model.
  final DeckModel model;

  int _seen;
  SlideOrder? _order;
  ThemeIndex? _themes;
  PlaceholderIndex? _placeholders;
  final Map<String, ElementTree> _trees = {};
  final Map<String, TableIndex> _tables = {};
  Map<String, List<SlideBuildRec>>? _buildsByElement;
  final Map<String, int> _slideRev = {};
  final Map<String, int> _ownerRev = {};
  final Map<String, int> _elementRev = {};
  int _globalRev = 0;
  int _epoch = 0;

  void _invalidateAll() {
    _order = null;
    _themes = null;
    _placeholders = null;
    _trees.clear();
    _tables.clear();
    _buildsByElement = null;
    _slideRev.clear();
    _ownerRev.clear();
    _elementRev.clear();
    _epoch++;
    _globalRev++;
  }

  void _sync() {
    if (model.version != _seen) {
      _invalidateAll();
      _seen = model.version;
    }
  }

  /// Slide columns the presentation order depends on (with added and
  /// removed slides).
  static const _orderColumns = {
    SlidesCols.sortKey,
    SlideCols.groupId,
    SlidesCols.skipped,
  };

  /// Slide columns nothing on the slide is drawn from.
  static const _unrenderedSlideColumns = {
    SlideCols.notes,
    SlideCols.timingsJson,
  };

  /// Deck columns no slide is drawn from.
  static const _unrenderedDeckColumns = {
    DeckCols.title,
    DeckCols.guidesJson,
    DeckCols.presentJson,
    DeckCols.defaultsJson,
    DeckCols.createdBy,
  };

  void _onBatch(DeckChangeBatch batch) {
    if (model.version != _seen + 1) {
      _invalidateAll();
      _seen = model.version;
      return;
    }
    _seen = model.version;
    for (final e in batch.events) {
      switch (e) {
        case DeckChanged(:final columns):
          if (columns.contains(DeckCols.firstSlideNumber)) _order = null;
          if (columns.contains(DeckCols.themeId)) {
            _themes = null;
            _placeholders = null;
          }
          if (columns.any((c) => !_unrenderedDeckColumns.contains(c))) {
            _globalRev++;
          }
        case SlidesChanged():
          var reorder = false, relayout = false;
          final replaced = <SlideRec>[];
          for (final s in e.slideIds) {
            final whole = e.added.contains(s) || e.removed.contains(s);
            final columns = whole ? null : e.columns[s];
            if (columns == null || columns.any(_orderColumns.contains)) {
              reorder = true;
            } else if (model.slide(s) case final rec?) {
              replaced.add(rec);
            }
            // layoutId changes affect layout usage.
            if (columns == null || columns.contains(SlideCols.layoutId)) {
              relayout = true;
            }
            if (columns == null ||
                columns.any((c) => !_unrenderedSlideColumns.contains(c))) {
              _bump(s);
            }
          }
          if (reorder) {
            _order = null;
          } else if (replaced.isNotEmpty) {
            _order = _order?.withSlides(replaced);
          }
          if (relayout) {
            _themes = null;
            _placeholders = null;
          }
        case OrderChanged():
          // Numbers and effective skips are part of [revision].
          _order = null;
        case ElementsChanged():
          for (final o in e.ownerIds) {
            _trees.remove(o);
            _bump(o);
          }
          for (final id in e.elementIds) {
            _tables.remove(id);
            _elementRev[id] = (_elementRev[id] ?? 0) + 1;
          }
        case ThemeChanged():
          _themes = null;
          _placeholders = null;
          for (final id in [...e.layoutIds, ...e.masterIds]) {
            _trees.remove(id);
          }
          // Only the slides drawn with them re-render ([revision]).
          for (final id in [...e.themeIds, ...e.masterIds, ...e.layoutIds]) {
            _ownerRev[id] = (_ownerRev[id] ?? 0) + 1;
          }
        case BuildsChanged():
          _buildsByElement = null;
          for (final s in e.slideIds) {
            _bump(s);
          }
        case OtherRowsChanged():
          break;
      }
    }
  }

  void _bump(String slideId) =>
      _slideRev[slideId] = (_slideRev[slideId] ?? 0) + 1;

  /// The presentation order.
  SlideOrder get order {
    _sync();
    return _order ??= SlideOrder.of(model);
  }

  /// Themes, masters and layouts.
  ThemeIndex get themes {
    _sync();
    return _themes ??= ThemeIndex.of(model);
  }

  /// Placeholder chains.
  PlaceholderIndex get placeholders {
    _sync();
    return _placeholders ??= PlaceholderIndex(model, themes);
  }

  /// The element tree of [ownerId] (slide, layout or master).
  ElementTree tree(String ownerId) {
    _sync();
    return _trees[ownerId] ??= ElementTree.of(model, ownerId);
  }

  /// The structure of table element [elementId].
  TableIndex table(String elementId) {
    _sync();
    return _tables[elementId] ??= TableIndex.of(model, elementId);
  }

  /// Builds targeting [elementId] (any slide), in table order.
  List<SlideBuildRec> buildsOfElement(String elementId) {
    _sync();
    final map = _buildsByElement ??= () {
      final out = <String, List<SlideBuildRec>>{};
      for (final r in model.records(SlidesTables.slideBuild)) {
        final b = r as SlideBuildRec;
        final el = b.elementId;
        if (el != null) (out[el] ??= []).add(b);
      }
      return out;
    }();
    return map[elementId] ?? const [];
  }

  /// A revision of what [slideId] renders from (or of a layout or master
  /// drawn as its editing surface): changes of the slide's render-relevant
  /// columns, its elements and builds bump it, and so do changes of its
  /// effective layout, master and theme (rows or elements) and of
  /// render-relevant deck columns. Notes, timings, the deck title, guides
  /// and present settings don't (CQ-43). The slide's number and effective
  /// skip are part of it (another slide's skip renumbers this one). Equal
  /// revisions mean an equal resolution.
  String revision(String slideId) {
    _sync();
    final ix = themes;
    final slide = model.slide(slideId);
    final layout = slide != null
        ? ix.effectiveLayout(slide)
        : model.layout(slideId);
    final master = layout != null
        ? ix.masterOf(layout)
        : slide == null
        ? model.master(slideId)
        : null;
    final theme =
        (master == null ? null : ix.themeOf(master)) ?? model.defaultTheme;
    final e = slide == null ? null : order.entry(slideId);
    return '$_globalRev.${_slideRev[slideId] ?? 0}.'
        '${layout?.id}:${_ownerRev[layout?.id] ?? 0}.'
        '${master?.id}:${_ownerRev[master?.id] ?? 0}.'
        '${theme?.id}:${_ownerRev[theme?.id] ?? 0}.'
        '${e?.number}.${e?.skipped}';
  }

  /// A revision of element [elementId]'s row and its dependent rows (table
  /// axes and cells, code states, chart links): the scene builder keys its
  /// node cache with it, since resolved elements keep their identity while
  /// only dependent rows change.
  String elementRevision(String elementId) {
    _sync();
    return '$_epoch.${_elementRev[elementId] ?? 0}';
  }
}

/// Index accessors on [DeckModel].
extension DeckModelIndexes on DeckModel {
  /// The derived indexes of this model.
  DeckIndexes get indexes => DeckIndexes.of(this);
}
