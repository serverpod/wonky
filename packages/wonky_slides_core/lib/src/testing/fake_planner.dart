import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import '../model/api/deck_model.dart';
import '../model/api/kinds.dart';
import '../model/api/records.dart';
import '../ops/change_summary.dart';
import '../ops/operations.dart';
import '../ops/plan_context.dart';
import '../ops/planner.dart';
import '../schema/slides_schema.dart';
import '../theme/builtins/builtin_themes.dart';
import '../theme/layout/placeholder_type.dart';
import '../planner/theme_copy.dart';
import 'deck_builder.dart';

/// A small planner for contract and harness tests until SL-7's
/// `SlidesMutationPlanner` exists: it follows the planner rules (exact
/// columns, coupled frame/position columns, dependent rows listed on
/// delete) for a subset of operations — `CreateDeck`, `SetDeckProps`
/// (title, appearance, numbering, footer), `AddSlides` (end of the top
/// level / after a slide), `DeleteSlides`, `MoveSlides`, `SetSlideProps`
/// (skip, notes, background), `CreateGroup`, `InsertElements`,
/// `UpdateFrames`, `SetElementProps`, `DeleteElements`, `SetText`,
/// `SetCells` — and throws `PlanException(unsupported)` for the others.
final class FakeSlidesPlanner implements SlidesMutationPlanner {
  /// Creates the planner.
  const FakeSlidesPlanner();

  @override
  SlidesPlan plan(SlidesOperation op, DeckModel deck, SlidesPlanContext ctx) {
    final p = _Plan(deck, ctx);
    final label = switch (op) {
      CreateDeck() => p.createDeck(op),
      SetDeckProps() => p.setDeckProps(op),
      AddSlides() => p.addSlides(op),
      DeleteSlides(:final slideIds) => p.deleteSlides(slideIds),
      MoveSlides() => p.moveSlides(op),
      SetSlideProps() => p.setSlideProps(op),
      CreateGroup() => p.createGroup(op),
      InsertElements() => p.insertElements(op),
      UpdateFrames() => p.updateFrames(op),
      SetElementProps() => p.setElementProps(op),
      DeleteElements(:final elementIds) => p.deleteElements(elementIds),
      SetText() => p.setText(op),
      SetCells() => p.setCells(op),
      _ => throw PlanException(
        PlanException.unsupported,
        '${op.name} is not supported by FakeSlidesPlanner',
      ),
    };
    return SlidesPlan(
      label: label,
      summary: SlidesChangeSummary.of(p.changes, current: deck),
      changes: p.changes,
      result: p.result,
    );
  }
}

final class _Plan {
  _Plan(this.deck, this.ctx);

  final DeckModel deck;
  final SlidesPlanContext ctx;
  final List<RowChange> changes = [];
  final Map<String, Object?> result = {};

  void insert(String table, Map<String, Object?> columns) => changes.add(
    RowChange.insert(table, columns[SlidesCols.id]! as String, columns),
  );

  /// An update naming exactly the columns of [after] that change.
  void update(SlidesRecord r, Map<String, Object?> after) {
    final changed = {
      for (final e in after.entries)
        if (r[e.key] != e.value) e.key: e.value,
    };
    if (changed.isEmpty) return;
    changes.add(
      RowChange.update(r.table, r.id, {
        for (final k in changed.keys) k: r[k],
      }, changed),
    );
  }

  void delete(SlidesRecord r) =>
      changes.add(RowChange.delete(r.table, r.id, r.toColumns()));

  Never notFound(String what, String id) =>
      throw PlanException(PlanException.notFound, '$what $id not found');

  // ---------------------------------------------------------------------------

  String createDeck(CreateDeck op) {
    if (deck.deck != null) {
      throw const PlanException(
        PlanException.invalidArgument,
        'The deck already exists',
      );
    }
    final def =
        BuiltInThemes.byKey(op.themeKey) ??
        (throw PlanException(
          PlanException.invalidArgument,
          'Unknown theme ${op.themeKey}',
        ));
    final pkg = BuiltInThemes.package(op.themeKey)!;
    final (rows, ids) = themePackageRows(
      pkg,
      deckId: op.deckId,
      sourceKey: SlidesIds.builtinThemeSourceKey(def.key, def.version),
      ids: ctx.ids,
      now: ctx.now,
    );
    final size = op.size ?? pkg.size;
    insert(SlidesTables.deck, {
      SlidesCols.id: op.deckId,
      DeckCols.title: op.title,
      DeckCols.width: size.width,
      DeckCols.height: size.height,
      DeckCols.sizePreset: size.kind.name,
      DeckCols.themeId: ids.themeId,
      DeckCols.appearance: (op.appearance ?? pkg.defaultAppearance).name,
      DeckCols.language: null,
      DeckCols.showSlideNumbers: false,
      DeckCols.hideNumberOnTitle: true,
      DeckCols.firstSlideNumber: 1,
      DeckCols.footerText: null,
      DeckCols.defaultsJson: null,
      DeckCols.guidesJson: null,
      DeckCols.presentJson: null,
      DeckCols.createdBy: ctx.userId,
      SlidesCols.createdAt: ctx.now,
    });
    for (final (t, c) in rows) {
      insert(t, c);
    }
    final first = op.firstLayoutKey;
    if (first != null) {
      final layoutId = ids.layoutIds[first] ?? ids.layoutIds.values.first;
      final layoutElements = [
        for (final (t, c) in rows)
          if (t == SlidesTables.slideElement &&
              c[ElementCols.layoutId] == layoutId)
            c,
      ];
      _slide(
        layoutId,
        groupId: null,
        sortKey: FractionalIndex.first(),
        layoutElements: layoutElements,
      );
    }
    return 'Create presentation';
  }

  String setDeckProps(SetDeckProps op) {
    final d = deck.deck ?? notFound('Deck', deck.deckId);
    update(d, {
      DeckCols.title: ?op.title,
      if (op.appearance != null) DeckCols.appearance: op.appearance!.name,
      DeckCols.showSlideNumbers: ?op.showSlideNumbers,
      DeckCols.hideNumberOnTitle: ?op.hideNumberOnTitle,
      DeckCols.firstSlideNumber: ?op.firstSlideNumber,
      if (op.footerText != null) DeckCols.footerText: op.footerText!.value,
      if (op.size != null) ...{
        DeckCols.width: op.size!.size.width,
        DeckCols.height: op.size!.size.height,
        DeckCols.sizePreset: op.size!.size.kind.name,
      },
    });
    return op.title != null ? 'Rename presentation' : 'Presentation settings';
  }

  /// Inserts a slide with the placeholder instances of [layoutId].
  String _slide(
    String layoutId, {
    required String? groupId,
    required String sortKey,
    Iterable<Map<String, Object?>>? layoutElements,
  }) {
    final id = ctx.ids.newId();
    insert(SlidesTables.slide, {
      SlidesCols.id: id,
      SlidesCols.deckId: deck.deckId,
      SlidesCols.sortKey: sortKey,
      SlideCols.groupId: groupId,
      SlideCols.layoutId: layoutId,
      SlidesCols.backgroundJson: null,
      SlidesCols.skipped: false,
      SlideCols.notes: null,
      SlidesCols.transitionJson: null,
      SlidesCols.hideMasterElements: null,
      SlideCols.timingsJson: null,
      SlidesCols.createdAt: ctx.now,
    });
    final elements =
        layoutElements ??
        [for (final e in deck.elementsOf(layoutId)) e.columns];
    String? z;
    for (final c in elements) {
      final type = SlidePlaceholderType.fromName(
        c[ElementCols.placeholderType],
      );
      if (type == null || !type.isInstantiated) continue;
      z = FractionalIndex.after(z);
      insert(SlidesTables.slideElement, {
        ...elementDefaults(),
        SlidesCols.id: SlidesIds.placeholderInstanceId(
          id,
          c[SlidesCols.id]! as String,
        ),
        SlidesCols.slideId: id,
        SlidesCols.kind: c[SlidesCols.kind],
        ElementCols.placeholderType: type.name,
        ElementCols.placeholderOf: c[SlidesCols.id],
        ElementCols.zKey: z,
        ElementCols.matchKey: SlidesIds.newMatchKey(ctx.ids),
        SlidesCols.createdAt: ctx.now,
      });
    }
    return id;
  }

  /// Top-level items `(sortKey, id)` in order.
  List<(String, String)> _topLevel() {
    final items = <(String, String)>[
      for (final g in deck.groups) (g.sortKey, g.id),
      for (final s in deck.slides)
        if (s.groupId == null) (s.sortKey, s.id),
    ];
    items.sort((a, b) => FractionalIndex.compare(a.$1, a.$2, b.$1, b.$2));
    return items;
  }

  /// `count` keys at [target] and the key space's group id.
  (String?, List<String>) _keysAt(SlideTarget target, int count) {
    final (groupId, siblings, before, after) = switch (target) {
      TopLevel(:final beforeId, :final afterId) => (
        null,
        _topLevel(),
        beforeId,
        afterId,
      ),
      InGroup(:final groupId, :final beforeId, :final afterId) => (
        groupId,
        [for (final s in deck.slidesInGroup(groupId)) (s.sortKey, s.id)],
        beforeId,
        afterId,
      ),
    };
    String? lo, hi;
    if (after != null) {
      final i = siblings.indexWhere((s) => s.$2 == after);
      if (i < 0) notFound('Item', after);
      lo = siblings[i].$1;
      hi = i + 1 < siblings.length ? siblings[i + 1].$1 : null;
    } else if (before != null) {
      final i = siblings.indexWhere((s) => s.$2 == before);
      if (i < 0) notFound('Item', before);
      hi = siblings[i].$1;
      lo = i > 0 ? siblings[i - 1].$1 : null;
    } else {
      lo = siblings.isEmpty ? null : siblings.last.$1;
    }
    if (lo != null && hi != null && lo == hi) hi = null;
    return (groupId, FractionalIndex.nBetween(lo, hi, count));
  }

  SlideTarget _afterSlide(String slideId) {
    final s = deck.slide(slideId) ?? notFound('Slide', slideId);
    final g = s.groupId;
    return g != null && deck.group(g) != null
        ? InGroup(g, afterId: s.id)
        : TopLevel(afterId: s.id);
  }

  String addSlides(AddSlides op) {
    final limit = ctx.limits.maxSlidesPerDeck;
    if (deck.count(SlidesTables.slide) + op.count > limit) {
      throw PlanException(
        PlanException.limit,
        'A presentation can have at most $limit slides.',
      );
    }
    final target =
        op.target ??
        (op.afterSlideId != null
            ? _afterSlide(op.afterSlideId!)
            : const TopLevel());
    final before = op.afterSlideId == null
        ? null
        : deck.slide(op.afterSlideId!)?.layoutId;
    final layoutId =
        op.layoutId ??
        (before != null && deck.layout(before) != null ? before : null) ??
        _defaultLayout();
    final (groupId, keys) = _keysAt(target, op.count);
    final ids = [
      for (final k in keys) _slide(layoutId, groupId: groupId, sortKey: k),
    ];
    result['slideIds'] = ids;
    return op.count == 1 ? 'New slide' : 'New ${op.count} slides';
  }

  String _defaultLayout() {
    final theme =
        deck.defaultTheme ??
        (throw const PlanException(PlanException.notFound, 'No theme'));
    for (final m in deck.mastersOf(theme.id)) {
      final layouts = deck.layoutsOf(m.id);
      for (final l in layouts) {
        if (l.key == 'titleBody') return l.id;
      }
      if (layouts.isNotEmpty) return layouts.first.id;
    }
    throw const PlanException(PlanException.notFound, 'No layout');
  }

  void _deleteElementTree(SlideElementRec e, Set<String> done) {
    if (!done.add(e.id)) return;
    final owner = e.ownerId;
    if (owner != null) {
      for (final c in deck.elementsOf(owner, parentId: e.id)) {
        _deleteElementTree(c, done);
      }
    }
    for (final r in [
      ...deck.cellsOf(e.id),
      for (final d in TableAxisDimension.values) ...deck.axesOf(e.id, d),
      ...deck.codeStatesOf(e.id),
      ?deck.chartLinkOf(e.id),
    ]) {
      delete(r);
    }
    for (final s in deck.records(SlidesTables.slideBuild)) {
      if ((s as SlideBuildRec).elementId == e.id) delete(s);
    }
    delete(e);
  }

  String deleteSlides(List<String> slideIds) {
    final done = <String>{};
    for (final id in slideIds) {
      final s = deck.slide(id) ?? notFound('Slide', id);
      for (final e in deck.elementsOf(id)) {
        _deleteElementTree(e, done);
      }
      for (final b in deck.buildsOf(id)) {
        if (!changes.any((c) => c.rowId == b.id)) delete(b);
      }
      delete(s);
    }
    return slideIds.length == 1
        ? 'Delete slide'
        : 'Delete ${slideIds.length} slides';
  }

  String moveSlides(MoveSlides op) {
    final ordered = [
      for (final s in deck.slides)
        if (op.slideIds.contains(s.id)) s,
    ];
    final (groupId, keys) = _keysAt(op.target, ordered.length);
    for (final (i, s) in ordered.indexed) {
      // groupId and sortKey together (02 P4).
      final after = {SlideCols.groupId: groupId, SlidesCols.sortKey: keys[i]};
      changes.add(
        RowChange.update(SlidesTables.slide, s.id, {
          SlideCols.groupId: s.groupId,
          SlidesCols.sortKey: s.sortKey,
        }, after),
      );
    }
    return ordered.length == 1 ? 'Move slide' : 'Move ${ordered.length} slides';
  }

  String setSlideProps(SetSlideProps op) {
    for (final id in op.slideIds) {
      final s = deck.slide(id) ?? notFound('Slide', id);
      update(s, {
        SlidesCols.skipped: ?op.skipped,
        if (op.notes != null) SlideCols.notes: op.notes!.value,
        if (op.backgroundJson != null)
          SlidesCols.backgroundJson: op.backgroundJson!.value,
        if (op.transitionJson != null)
          SlidesCols.transitionJson: op.transitionJson!.value,
        SlideCols.layoutId: ?op.layoutId,
      });
    }
    return op.skipped != null
        ? (op.skipped! ? 'Skip slide' : "Don't skip slide")
        : op.notes != null
        ? 'Edit notes'
        : 'Slide settings';
  }

  String createGroup(CreateGroup op) {
    final ordered = [
      for (final s in deck.slides)
        if (op.slideIds.contains(s.id)) s,
    ];
    if (ordered.isEmpty) {
      throw const PlanException(PlanException.invalidArgument, 'No slides');
    }
    final first = ordered.first;
    final (_, keys) = _keysAt(
      first.groupId == null ? TopLevel(beforeId: first.id) : const TopLevel(),
      1,
    );
    final groupId = op.groupId ?? ctx.ids.newId();
    insert(SlidesTables.slideGroup, {
      SlidesCols.id: groupId,
      SlidesCols.deckId: deck.deckId,
      SlidesCols.title: op.title ?? 'Group ${deck.groups.length + 1}',
      SlidesCols.sortKey: keys.single,
      SlidesCols.parentId: null,
      SlideGroupCols.color: op.color,
      SlidesCols.skipped: false,
      SlidesCols.createdAt: ctx.now,
    });
    final slideKeys = FractionalIndex.nBetween(null, null, ordered.length);
    for (final (i, s) in ordered.indexed) {
      changes.add(
        RowChange.update(
          SlidesTables.slide,
          s.id,
          {SlideCols.groupId: s.groupId, SlidesCols.sortKey: s.sortKey},
          {SlideCols.groupId: groupId, SlidesCols.sortKey: slideKeys[i]},
        ),
      );
    }
    result['groupId'] = groupId;
    return 'Group slides';
  }

  String insertElements(InsertElements op) {
    final siblings = deck.elementsOf(op.ownerId, parentId: op.parentId);
    final limit = ctx.limits.maxElementsPerOwner;
    if (deck.allElementsOf(op.ownerId).length + op.elements.length > limit) {
      throw PlanException(
        PlanException.limit,
        "This slide can't hold more than $limit objects.",
      );
    }
    var z = siblings.isEmpty ? null : siblings.last.zKey;
    final ownerColumn = switch (op.ownerKind) {
      ElementOwnerKind.slide => SlidesCols.slideId,
      ElementOwnerKind.layout => ElementCols.layoutId,
      ElementOwnerKind.master => ElementCols.masterId,
    };
    final ids = <String>[];
    void add(ElementSpec e, String? parentId, String? zKey) {
      final id = e.id ?? ctx.ids.newId();
      ids.add(id);
      insert(SlidesTables.slideElement, {
        ...elementDefaults(),
        SlidesCols.id: id,
        ownerColumn: op.ownerId,
        SlidesCols.parentId: parentId,
        SlidesCols.kind: e.kind.name,
        ElementCols.x: e.x,
        ElementCols.y: e.y,
        ElementCols.width: e.width,
        ElementCols.height: e.height,
        ElementCols.rotation: e.rotation,
        ElementCols.zKey: zKey,
        ElementCols.matchKey: SlidesIds.newMatchKey(ctx.ids),
        SlidesCols.createdAt: ctx.now,
        ...e.columns,
      });
      String? cz;
      for (final c in e.children) {
        cz = FractionalIndex.after(cz);
        add(c, id, cz);
      }
    }

    for (final e in op.elements) {
      z = FractionalIndex.after(z);
      add(e, op.parentId, z);
    }
    result['elementIds'] = ids;
    return 'Insert';
  }

  String updateFrames(UpdateFrames op) {
    for (final u in op.updates) {
      final e = deck.element(u.elementId) ?? notFound('Element', u.elementId);
      update(e, {
        ElementCols.x: ?u.x,
        ElementCols.y: ?u.y,
        ElementCols.width: ?u.width,
        ElementCols.height: ?u.height,
        ElementCols.rotation: ?u.rotation,
        ElementCols.flipH: ?u.flipH,
        ElementCols.flipV: ?u.flipV,
      });
    }
    return op.label ?? 'Move';
  }

  String setElementProps(SetElementProps op) {
    for (final id in op.elementIds) {
      final e = deck.element(id) ?? notFound('Element', id);
      update(e, {
        if (op.fillJson != null) ElementCols.fillJson: op.fillJson!.value,
        if (op.strokeJson != null) ElementCols.strokeJson: op.strokeJson!.value,
        if (op.effectsJson != null)
          ElementCols.effectsJson: op.effectsJson!.value,
        if (op.opacity != null) ElementCols.opacity: op.opacity!.value,
        ElementCols.locked: ?op.locked,
        SlidesCols.hidden: ?op.hidden,
        if (op.elementName != null) SlidesCols.name: op.elementName!.value,
        if (op.altText != null) ElementCols.altText: op.altText!.value,
        ElementCols.decorative: ?op.decorative,
        if (op.linkJson != null) ElementCols.linkJson: op.linkJson!.value,
        ElementCols.matchKey: ?op.matchKey,
        if (op.readingKey != null) ElementCols.readingKey: op.readingKey!.value,
      });
    }
    return 'Format';
  }

  String deleteElements(List<String> elementIds) {
    final done = <String>{};
    for (final id in elementIds) {
      _deleteElementTree(deck.element(id) ?? notFound('Element', id), done);
    }
    return 'Delete';
  }

  String setText(SetText op) {
    switch (op.target) {
      case ElementText(:final elementId):
        final e = deck.element(elementId) ?? notFound('Element', elementId);
        update(e, {SlidesCols.text: op.delta});
      case NotesText(:final slideId):
        final s = deck.slide(slideId) ?? notFound('Slide', slideId);
        update(s, {SlideCols.notes: op.delta});
        return 'Edit notes';
      case CellText(:final elementId, :final rowId, :final columnId):
        _cell(elementId, rowId, columnId, {SlidesCols.text: op.delta});
    }
    return 'Typing';
  }

  void _cell(
    String elementId,
    String rowId,
    String columnId,
    Map<String, Object?> columns,
  ) {
    final id = SlidesIds.tableCellId(elementId, rowId, columnId);
    final existing = deck.record(SlidesTables.slideTableCell, id);
    if (existing != null) {
      update(existing, columns);
      return;
    }
    insert(SlidesTables.slideTableCell, {
      for (final c in SlidesTables.columns[SlidesTables.slideTableCell]!)
        c: null,
      SlidesCols.id: id,
      SlidesCols.elementId: elementId,
      TableCellCols.rowId: rowId,
      TableCellCols.columnId: columnId,
      SlidesCols.createdAt: ctx.now,
      ...columns,
    });
  }

  String setCells(SetCells op) {
    for (final w in op.writes) {
      _cell(op.elementId, w.rowId, w.columnId, w.columns);
    }
    return 'Edit table';
  }
}
