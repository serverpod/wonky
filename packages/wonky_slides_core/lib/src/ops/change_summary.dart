import 'package:wonky_revlog/rows.dart';

import '../schema/slides_schema.dart';

/// A Slides mutation plan (the shared kit's plan with the Slides summary).
typedef SlidesPlan = MutationPlan<SlidesChangeSummary>;

/// Kinds of change in a `DeckChangeLog.summaryJson` (02 §3.10.1).
abstract final class SlidesChangeKinds {
  static const text = 'text';
  static const frame = 'frame';
  static const style = 'style';
  static const structure = 'structure';
  static const order = 'order';
  static const theme = 'theme';
  static const build = 'build';
  static const code = 'code';
  static const chart = 'chart';
  static const notes = 'notes';
  static const deck = 'deck';

  /// Every kind in the order of 02 §3.10.1.
  static const all = [
    text,
    frame,
    style,
    structure,
    order,
    theme,
    build,
    code,
    chart,
    notes,
    deck,
  ];
}

/// The change-log summary of a Slides plan (`DeckChangeLog.summaryJson`,
/// 02 §3.10.1): what kinds of change, which slides and elements were
/// touched, which rows were deleted or revived (comment orphaning, 09
/// §3.2) and which chart links changed (08).
final class SlidesChangeSummary implements ChangeSummary {
  /// Creates an empty summary.
  SlidesChangeSummary();

  /// Max slides listed before `slidesOverflow`.
  static const maxSlides = 500;

  /// Max elements listed before `elementsOverflow`.
  static const maxElements = 1000;

  /// Kinds of change.
  final Set<String> kinds = {};

  /// Touched slides.
  final Set<String> slides = {};

  /// Touched elements.
  final Set<String> elements = {};

  /// Deleted rows by category (`slides`, `elements`, `groups`, `themes`).
  final Map<String, Set<String>> deleted = {
    'slides': {},
    'elements': {},
    'groups': {},
    'themes': {},
  };

  /// Revived rows (inserts of previously deleted ids: undo of a delete).
  final Map<String, Set<String>> revived = {
    'slides': {},
    'elements': {},
    'groups': {},
    'themes': {},
  };

  /// Chart elements whose link was created, updated or removed.
  final Set<String> chartLinks = {};

  /// Whether nothing was recorded.
  bool get isEmpty =>
      kinds.isEmpty && slides.isEmpty && elements.isEmpty && chartLinks.isEmpty;

  /// Derives a summary from bare row changes (writers of undo/redo and
  /// remote patches, `SyncWriter.summarize`). [current] resolves the slide
  /// of updated elements and dependent rows (the model before or after the
  /// change; missing rows are skipped). An insert counts as *revived* when
  /// [wasDeleted] says the id existed before (undo of a delete).
  static SlidesChangeSummary of(
    Iterable<RowChange> changes, {
    CurrentRowReader? current,
    bool Function(String table, String rowId)? wasDeleted,
  }) {
    final s = SlidesChangeSummary();
    for (final c in changes) {
      s.addChange(c, current: current, wasDeleted: wasDeleted);
    }
    return s;
  }

  static const _category = {
    SlidesTables.slide: 'slides',
    SlidesTables.slideElement: 'elements',
    SlidesTables.slideGroup: 'groups',
    SlidesTables.deckTheme: 'themes',
  };

  static const _frameColumns = {
    ElementCols.x,
    ElementCols.y,
    ElementCols.width,
    ElementCols.height,
    ElementCols.rotation,
    ElementCols.flipH,
    ElementCols.flipV,
  };

  static const _styleColumns = {
    ElementCols.textStyleJson,
    ElementCols.fillJson,
    ElementCols.strokeJson,
    ElementCols.effectsJson,
    ElementCols.opacity,
    ElementCols.locked,
    SlidesCols.hidden,
    SlidesCols.name,
    ElementCols.altText,
    ElementCols.decorative,
    ElementCols.linkJson,
    ElementCols.dataJson,
  };

  /// Records one change.
  void addChange(
    RowChange c, {
    CurrentRowReader? current,
    bool Function(String table, String rowId)? wasDeleted,
  }) {
    final cols = {...c.columnsBefore, ...c.columnsAfter};
    String? col(String k) {
      final v = cols[k];
      if (v != null) return v.toString();
      return current?.currentColumns(c.table, c.rowId)?[k]?.toString();
    }

    final category = _category[c.table];
    if (category != null) {
      if (c.op == RowOp.delete) deleted[category]!.add(c.rowId);
      if (c.op == RowOp.insert &&
          (wasDeleted?.call(c.table, c.rowId) ?? false)) {
        revived[category]!.add(c.rowId);
      }
    }
    final touched = c.touchedColumns;
    final structural = c.op != RowOp.update;
    switch (c.table) {
      case SlidesTables.deck:
        kinds.add(SlidesChangeKinds.deck);
      case SlidesTables.deckTheme ||
          SlidesTables.slideMaster ||
          SlidesTables.slideLayout:
        kinds.add(SlidesChangeKinds.theme);
      case SlidesTables.slideGroup:
        kinds.add(
          structural ? SlidesChangeKinds.structure : SlidesChangeKinds.order,
        );
      case SlidesTables.slide:
        slides.add(c.rowId);
        if (structural) kinds.add(SlidesChangeKinds.structure);
        if (!structural &&
            (touched.contains(SlidesCols.sortKey) ||
                touched.contains(SlideCols.groupId))) {
          kinds.add(SlidesChangeKinds.order);
        }
        if (touched.contains(SlideCols.notes)) {
          kinds.add(SlidesChangeKinds.notes);
        }
        if (!structural &&
            touched.any(
              (k) =>
                  k != SlidesCols.sortKey &&
                  k != SlideCols.groupId &&
                  k != SlideCols.notes,
            )) {
          kinds.add(SlidesChangeKinds.style);
        }
      case SlidesTables.slideElement:
        elements.add(c.rowId);
        final slide = col(SlidesCols.slideId);
        if (slide != null) slides.add(slide);
        if (structural) {
          kinds.add(SlidesChangeKinds.structure);
        } else {
          if (touched.contains(SlidesCols.text)) {
            kinds.add(SlidesChangeKinds.text);
          }
          if (touched.any(_frameColumns.contains)) {
            kinds.add(SlidesChangeKinds.frame);
          }
          if (touched.contains(ElementCols.zKey) ||
              touched.contains(SlidesCols.parentId) ||
              touched.contains(ElementCols.readingKey)) {
            kinds.add(SlidesChangeKinds.order);
          }
          if (touched.any(_styleColumns.contains)) {
            kinds.add(SlidesChangeKinds.style);
          }
        }
        if (col(ElementCols.layoutId) != null ||
            col(ElementCols.masterId) != null) {
          kinds.add(SlidesChangeKinds.theme);
        }
      case SlidesTables.slideTableAxis || SlidesTables.slideTableCell:
        _dependent(col(SlidesCols.elementId), current);
        kinds.add(
          c.table == SlidesTables.slideTableCell &&
                  touched.contains(SlidesCols.text)
              ? SlidesChangeKinds.text
              : (structural
                    ? SlidesChangeKinds.structure
                    : SlidesChangeKinds.style),
        );
      case SlidesTables.slideBuild:
        final slide = col(SlidesCols.slideId);
        if (slide != null) slides.add(slide);
        final el = col(SlidesCols.elementId);
        if (el != null) elements.add(el);
        kinds.add(SlidesChangeKinds.build);
      case SlidesTables.codeState:
        _dependent(col(SlidesCols.elementId), current);
        kinds.add(SlidesChangeKinds.code);
      case SlidesTables.chartLink:
        final el = col(SlidesCols.elementId);
        _dependent(el, current);
        if (el != null) chartLinks.add(el);
        kinds.add(SlidesChangeKinds.chart);
    }
  }

  void _dependent(String? elementId, CurrentRowReader? current) {
    if (elementId == null) return;
    elements.add(elementId);
    final slide = current?.currentColumns(
      SlidesTables.slideElement,
      elementId,
    )?[SlidesCols.slideId];
    if (slide != null) slides.add(slide.toString());
  }

  static List<String> _sorted(Iterable<String> s) => s.toList()..sort();

  @override
  Map<String, Object?> toJson() {
    final slideList = _sorted(slides);
    final elementList = _sorted(elements);
    Map<String, Object?> cats(Map<String, Set<String>> m) => {
      for (final e in m.entries) e.key: _sorted(e.value),
    };
    return {
      'v': 1,
      'kinds': [
        for (final k in SlidesChangeKinds.all)
          if (kinds.contains(k)) k,
      ],
      'slides': slideList.length > maxSlides
          ? slideList.sublist(0, maxSlides)
          : slideList,
      if (slideList.length > maxSlides) 'slidesOverflow': true,
      'elements': elementList.length > maxElements
          ? elementList.sublist(0, maxElements)
          : elementList,
      if (elementList.length > maxElements) 'elementsOverflow': true,
      'deleted': cats(deleted),
      'revived': cats(revived),
      'chartLinks': _sorted(chartLinks),
    };
  }

  @override
  String toString() => 'SlidesChangeSummary(${toJson()})';
}
