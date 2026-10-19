import 'dart:convert';

import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import 'package:wonky_charts/wonky_charts.dart' show ChartSourceSnapshot;

import '../model/api/deck_model.dart';
import '../model/api/kinds.dart';
import '../motion/builds/transition_spec.dart';
import '../ops/change_summary.dart';
import '../ops/operations.dart';
import '../ops/plan_context.dart';
import '../ops/planner.dart';
import '../planner/slides_planner.dart';
import '../schema/slides_schema.dart';
import '../theme/color/color_ref.dart';
import '../theme/model/box_text_style.dart';
import '../theme/model/common.dart';
import '../theme/model/paint.dart';
import 'template_text.dart';

/// Builds the deck of a built-in template (Slides 04 §15) with the real
/// planner: every slide, group, placeholder text, shape and table is a
/// `SlidesOperation` planned against the growing [model], exactly as if a
/// user had made the deck — so template decks pass maintenance, copy and
/// render like any other deck.
///
/// Placeholder bodies are addressed by the layout's part names (`title`,
/// `subtitle`, `body`, `bodyRight`, `headingLeft`, `bigNumber`, `caption`,
/// `quote`, `attribution`, `label`, `code`, …; `BuiltInLayouts`).
final class TemplateDeckBuilder {
  /// Starts a deck with [CreateDeck] (no first slide).
  TemplateDeckBuilder({
    required String deckId,
    required String title,
    required String themeKey,
    required this.ctx,
    SlideAppearance? appearance,
    TransitionSpec? defaultTransition,
    this.planner = const SlidesPlanner(),
  }) : model = DeckModel(deckId: deckId) {
    final r = run(
      CreateDeck(
        deckId: deckId,
        title: title,
        themeKey: themeKey,
        appearance: appearance,
        firstLayoutKey: null,
        defaultsJson: defaultTransition == null
            ? null
            : DeckMotionDefaults.withTransition(null, defaultTransition),
      ),
    );
    themeId = r['themeId']! as String;
  }

  /// The deck being built.
  final DeckModel model;

  /// Ids, author and time of every row.
  final SlidesPlanContext ctx;

  /// The planner.
  final SlidesMutationPlanner planner;

  /// The deck's theme copy.
  late final String themeId;

  /// Planner warnings, prefixed with the operation name.
  final List<String> warnings = [];

  /// Every plan, in order.
  final List<SlidesPlan> plans = [];

  /// Plans [op], applies it to [model] and returns the plan's result.
  Map<String, Object?> run(SlidesOperation op) {
    final plan = planner.plan(op, model, ctx);
    plans.add(plan);
    for (final w in plan.warnings) {
      warnings.add('${op.name}: $w');
    }
    model.applyChanges(plan.changes);
    return plan.result;
  }

  /// The id of layout [key] in the deck's theme copy.
  String layoutId(String key) {
    final id = SlidesIds.themePartId(themeId, 'layout:$key');
    if (model.layout(id) == null) {
      throw ArgumentError.value(key, 'key', 'Unknown layout');
    }
    return id;
  }

  /// The instance of placeholder [name] (a layout part name) on [slideId].
  String placeholder(String slideId, String name) {
    final slide = model.slide(slideId)!;
    final layout = model.layout(slide.layoutId!)!;
    final def = SlidesIds.themePartId(themeId, 'el:${layout.key}/$name');
    final id = SlidesIds.placeholderInstanceId(slideId, def);
    if (model.element(id) == null) {
      throw ArgumentError.value(
        name,
        'name',
        'No placeholder on layout ${layout.key}',
      );
    }
    return id;
  }

  /// Creates a slide group at the end of the deck; the next [slide]s go
  /// into it until [endGroup] or the next [group].
  String group(String title, {String? color}) {
    final r = run(
      CreateGroup(const [], title: title, color: color, target: TopLevel()),
    );
    return _group = r['groupId']! as String;
  }

  /// Slides added after this go to the top level again.
  void endGroup() => _group = null;

  String? _group;

  /// Adds a slide with layout [layoutKey] at the end (of the open group):
  /// placeholder bodies by part name ([text]; a `String`, `TemplatePara` or
  /// `List<TemplatePara>`), speaker [notes], extra [elements] (on top of the
  /// placeholders), [skipped].
  String slide(
    String layoutKey, {
    Map<String, Object> text = const {},
    Object? notes,
    List<ElementSpec> elements = const [],
    bool skipped = false,
  }) {
    final g = _group;
    final r = run(
      AddSlides(
        layoutId: layoutId(layoutKey),
        target: g == null ? const TopLevel() : InGroup(g),
      ),
    );
    final id = (r['slideIds']! as List).single as String;
    for (final MapEntry(:key, :value) in text.entries) {
      run(SetText(ElementText(placeholder(id, key)), TemplateText.of(value)));
    }
    if (notes != null || skipped) {
      run(
        SetSlideProps(
          [id],
          notes: notes == null ? null : Patch(TemplateText.of(notes)),
          skipped: skipped ? true : null,
        ),
      );
    }
    lastElements = elements.isEmpty ? const [] : insert(id, elements);
    return id;
  }

  /// The ids of the `elements` of the last [slide] (in spec order).
  List<String> lastElements = const [];

  /// Inserts [elements] on [slideId] (on top); their ids in spec order.
  List<String> insert(String slideId, List<ElementSpec> elements) {
    final r = run(InsertElements(slideId, elements));
    return [for (final id in r['elementIds']! as List) id as String];
  }

  /// Appends [builds] to the build sequence of [slideId] (06 §2; specs from
  /// `BuildEdits.spec`, catalog defaults).
  void builds(String slideId, List<BuildSpec> builds) =>
      run(AddBuilds(slideId, builds));

  /// Sets the own transition of [slideIds] (06 §7.1).
  void transition(List<String> slideIds, TransitionSpec transition) =>
      run(SetSlideProps(slideIds, transitionJson: Patch(transition.encode())));

  /// Sets the Magic Move key of [elementId] (06 §8.2): elements with equal
  /// keys on consecutive slides morph into each other.
  void matchKey(String elementId, String key) =>
      run(SetElementProps([elementId], matchKey: key));

  /// Fills the code placeholder of [slideId] with one state; [highlight]
  /// is its line-highlight step syntax (07 §4.1, `1-3 | 5`). Returns the
  /// code element.
  String code(
    String slideId,
    String source, {
    required String language,
    String? highlight,
  }) => codeStates(slideId, [
    TemplateCodeState(source, highlight: highlight),
  ], language: language);

  /// Fills the code placeholder of [slideId] with [states] (07 §3.2: the
  /// first is shown first; later ones arrive by type-in or morph per
  /// their `mode`), with [options] merged into the element's `dataJson`
  /// (07 §3.1: title, chrome, …). Returns the code element.
  String codeStates(
    String slideId,
    List<TemplateCodeState> states, {
    required String language,
    Map<String, Object?> options = const {},
  }) {
    final el = placeholder(slideId, 'code');
    if (options.isNotEmpty) {
      final current = model.element(el)?.dataJson;
      final data = current == null
          ? <String, Object?>{'v': 1}
          : {...jsonDecode(current) as Map<String, Object?>};
      run(SetElementData(el, jsonEncode({...data, ...options})));
    }
    run(
      AddCodeStates(el, [
        for (final s in states)
          {
            CodeStateCols.code: s.code,
            CodeStateCols.language: language,
            CodeStateCols.highlight: ?s.highlight,
            SlidesCols.label: ?s.label,
            SlidesCols.title: ?s.title,
            if (s.mode != null || s.typing.isNotEmpty)
              SlidesCols.transitionJson: jsonEncode({
                'v': 1,
                'mode': ?s.mode,
                ...s.typing,
              }),
            if (s.callouts.isNotEmpty)
              CodeStateCols.annotationsJson: jsonEncode({
                'v': 1,
                'steps': {
                  for (final MapEntry(:key, :value) in s.callouts.entries)
                    '$key': {'text': value},
                },
              }),
          },
      ]),
    );
    return el;
  }

  /// Fills the chart placeholder of [slideId] with a static chart of
  /// [snapshot] in the deck theme's colors (08 §3.1 `static`: sample data a
  /// user replaces with *Relink…* to a spreadsheet chart, keeping the
  /// frame, builds and camera), with an optional 3D [camera]
  /// (`{azimuth, elevation, perspective}`) and [altText] (03 §17). Returns
  /// the chart element.
  String staticChart(
    String slideId,
    ChartSourceSnapshot snapshot, {
    required String altText,
    Map<String, Object?>? camera,
  }) {
    final el = placeholder(slideId, 'chart');
    run(
      SetElementData(
        el,
        jsonEncode({
          'v': 1,
          'source': 'static',
          'style': {'useDeckTheme': true},
          'camera': ?camera,
          'snapshot': snapshot.toJson(),
        }),
      ),
    );
    run(SetElementProps([el], altText: Patch(altText)));
    return el;
  }

  /// Adds a [rows] × columns table on [slideId] at [rect]: the first row is
  /// the header (the table style's default), its text bold at 36 su. Cells
  /// are plain text.
  String table(String slideId, SuRect rect, List<List<String>> rows) {
    final cols = rows.first.length;
    final r = run(
      InsertElements(slideId, [
        ElementSpec(
          kind: ElementKind.table,
          x: rect.x,
          y: rect.y,
          width: rect.width,
          height: rect.height,
          tableRows: rows.length,
          tableColumns: cols,
        ),
      ]),
    );
    final el = (r['elementIds']! as List).single as String;
    final rowIds = [
      for (final a in model.axesOf(el, TableAxisDimension.row)) a.id,
    ];
    final colIds = [
      for (final a in model.axesOf(el, TableAxisDimension.column)) a.id,
    ];
    run(
      SetCells(el, [
        for (final (ri, row) in rows.indexed)
          for (final (ci, cell) in row.indexed)
            if (cell.isNotEmpty)
              CellWrite(rowIds[ri], colIds[ci], {
                SlidesCols.text: TemplateText.of(
                  // Header cells a little larger: large bold text keeps
                  // ≥ 3:1 on accent header fills (05 §11).
                  ri == 0
                      ? TemplatePara.runs([
                          TemplateRun(cell, const {'bold': true, 'size': 36}),
                        ])
                      : cell,
                ),
              }),
      ]),
    );
    return el;
  }

  /// The deck's rows as inserts in dependency order (a writer's input).
  List<RowChange> get inserts => [
    for (final t in SlidesTables.dependencyOrder)
      for (final r in model.records(t))
        RowChange.insert(t, r.id, r.toColumns()),
  ];
}

/// A state of a template code block (07 §3.2).
final class TemplateCodeState {
  /// Creates a state.
  const TemplateCodeState(
    this.code, {
    this.highlight,
    this.label,
    this.title,
    this.mode,
    this.typing = const {},
    this.callouts = const {},
  });

  /// The source.
  final String code;

  /// Line-highlight steps (07 §4.1), or null.
  final String? highlight;

  /// Name in the state strip.
  final String? label;

  /// Title override (file name), or null.
  final String? title;

  /// How this state arrives (`type`, `morph`, `instant`; null = the
  /// element default, `type`).
  final String? mode;

  /// Typing settings of this state's arrival (07 §5.3: `cps`,
  /// `maxDurationMs`, …).
  final Map<String, Object?> typing;

  /// Callout text (inline Markdown) per 1-based highlight step (07 §4.4).
  final Map<int, String> callouts;
}

/// Element specs for template slides (frames in su on the 1920 × 1080
/// grid). Colors are `ColorRef` strings (`theme:accent1`,
/// `theme:bg2/alpha:0.5`).
abstract final class TemplateShapes {
  /// A shape with [geometry] (`ShapeLibrary` key) at [rect]: fill and
  /// stroke explicit (none when null), optional [text] (`String`, `TemplatePara`,
  /// `List<TemplatePara>`) with box [box] (default: centered, middle anchored,
  /// 24 su insets) and [textColor].
  static ElementSpec shape(
    String geometry,
    SuRect rect, {
    String? fill,
    String? stroke,
    double strokeWidth = 4,
    Object? text,
    String? textColor,
    String textStyle = 'body',
    double? textSize,
    String align = 'center',
    String anchor = 'middle',
    List<double> insets = const [24, 32, 24, 32],
    Map<String, Object?> adjust = const {},
    double? rotation,
    double? opacity,
    String? name,
    bool decorative = false,
    String? matchKey,
  }) => ElementSpec(
    kind: ElementKind.shape,
    x: rect.x,
    y: rect.y,
    width: rect.width,
    height: rect.height,
    rotation: rotation,
    columns: {
      ElementCols.dataJson: jsonEncode({
        'v': 1,
        'geometry': geometry,
        if (adjust.isNotEmpty) 'adjust': adjust,
      }),
      ElementCols.fillJson: jsonEncode(
        fill == null
            ? const NoFill().toJson()
            : SolidFill(ColorRef.parse(fill)).toJson(),
      ),
      ElementCols.strokeJson: jsonEncode(
        stroke == null
            ? const SlideStroke.none().toJson()
            : SlideStroke(
                color: ColorRef.parse(stroke),
                width: strokeWidth,
              ).toJson(),
      ),
      if (text != null) SlidesCols.text: TemplateText.of(text),
      if (text != null)
        ElementCols.textStyleJson: jsonEncode(
          BoxTextStyle(
            anchor: anchor,
            insets: insets,
            autofit: 'shrink',
            wrap: true,
            defaults: {
              'style': textStyle,
              'align': align,
              'color': ?textColor,
              'size': ?textSize,
            },
          ).toJson(),
        ),
      ElementCols.opacity: ?opacity,
      SlidesCols.name: ?name,
      if (decorative) ElementCols.decorative: true,
      ElementCols.matchKey: ?matchKey,
    },
  );

  /// A text box at [rect] (no fill), [text] in style [textStyle].
  static ElementSpec text(
    SuRect rect,
    Object text, {
    String textStyle = 'body',
    String? color,
    double? size,
    String align = 'left',
    String anchor = 'top',
    String? name,
    String? matchKey,
  }) => ElementSpec(
    kind: ElementKind.text,
    x: rect.x,
    y: rect.y,
    width: rect.width,
    height: rect.height,
    columns: {
      SlidesCols.text: TemplateText.of(text),
      ElementCols.textStyleJson: jsonEncode(
        BoxTextStyle(
          anchor: anchor,
          insets: const [0, 0, 0, 0],
          autofit: 'shrink',
          wrap: true,
          defaults: {
            'style': textStyle,
            'align': align,
            'color': ?color,
            'size': ?size,
          },
        ).toJson(),
      ),
      SlidesCols.name: ?name,
      ElementCols.matchKey: ?matchKey,
    },
  );

  /// A straight line from ([x1], [y1]) to ([x2], [y2]).
  static ElementSpec line(
    double x1,
    double y1,
    double x2,
    double y2, {
    required String color,
    double width = 4,
    String? endArrow,
    String? dash,
    bool decorative = true,
  }) {
    final x = x1 < x2 ? x1 : x2, y = y1 < y2 ? y1 : y2;
    final w = (x2 - x1).abs(), h = (y2 - y1).abs();
    double nx(double v) => w == 0 ? 0 : (v - x) / w;
    double ny(double v) => h == 0 ? 0 : (v - y) / h;
    return ElementSpec(
      kind: ElementKind.line,
      x: x,
      y: y,
      // Frames have a minimum side; a horizontal line keeps height 1.
      width: w == 0 ? 1 : w,
      height: h == 0 ? 1 : h,
      columns: {
        ElementCols.dataJson: jsonEncode({
          'v': 1,
          'routing': 'straight',
          'start': {'x': nx(x1), 'y': ny(y1)},
          'end': {'x': nx(x2), 'y': ny(y2)},
        }),
        ElementCols.strokeJson: jsonEncode(
          SlideStroke(
            color: ColorRef.parse(color),
            width: width,
            dash: dash,
            endArrow: endArrow,
          ).toJson(),
        ),
        if (decorative) ElementCols.decorative: true,
      },
    );
  }
}
