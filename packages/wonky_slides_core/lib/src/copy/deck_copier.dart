import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import '../model/api/deck_reader.dart';
import '../planner/theme_copy.dart';
import '../schema/slides_schema.dart';
import '../theme/builtins/builtin_themes.dart';
import 'id_remapper.dart';

/// A deck copied for a new space by [DeckCopier.copy].
final class DeckCopy {
  /// Creates a copy.
  const DeckCopy({
    required this.deckId,
    required this.rows,
    required this.ids,
    required this.files,
    required this.dropped,
  });

  /// The new deck id (= space UUID = drive item UUID).
  final String deckId;

  /// The rows of the copy in dependency order (parents first).
  final List<SlidesRow> rows;

  /// Old → new row ids (every copied row; comment anchors, version copies).
  final Map<String, String> ids;

  /// Uploaded files to copy into the new item (empty without re-homing).
  final List<FileRehome> files;

  /// Rows of the source left out because their owner or parent is missing
  /// (`table:id`; the deck's render rules never showed them).
  final List<String> dropped;

  /// The rows as inserts (a writer's input).
  List<RowChange> get inserts => [
    for (final (t, c) in rows)
      RowChange.insert(t, c[SlidesCols.id]! as String, c),
  ];

  /// Number of rows per table.
  Map<String, int> get counts {
    final out = <String, int>{};
    for (final (t, _) in rows) {
      out[t] = (out[t] ?? 0) + 1;
    }
    return out;
  }
}

/// Copies a whole deck into a new deck id (02 §9.3: *Make a copy*, copies
/// of versions, templates). Row ids are global, so every row gets a new
/// id:
///
/// - fresh UUIDv7 for groups, slides, elements, table axes, builds and
///   code states;
/// - deterministic ids recomputed for the new deck: `themeCopyId(deck,
///   sourceKey)` for themes with provenance (built-ins, imported decks),
///   `themePartId(theme, partKey)` for masters, layouts and their elements
///   (built-in parts keep their built-in part key, so re-applying the same
///   built-in theme in the copy finds the copied rows — no duplicate theme),
///   `placeholderInstanceId` for placeholder instances, `tableCellId`,
///   `chartLinkId`;
/// - references remapped: owners, `parentId`, `groupId`, `layoutId`,
///   `masterId`, `themeId`, `placeholderOf`, table axes, build and chart
///   link elements; inside JSON (connector `connect.elementId`,
///   `linkJson.slideId`, build options, presenter settings) and text
///   `slide:` links; match keys of theme elements derived from their ids;
/// - uploaded files (`wonky-file://`, `fileUuid`) get new uuids and are
///   listed in [DeckCopy.files] for the server to copy (re-homing);
/// - `DeckChangeLog` is not copied (not part of the model); chart links
///   are kept (the copy stays linked).
///
/// Pure and deterministic for a given [IdGenerator].
abstract final class DeckCopier {
  /// Copies [source] to deck [deckId] for [userId] (`Deck.createdBy`).
  /// [title] replaces the deck title. Without [rehomeFiles], file
  /// references stay unchanged (a copy that keeps reading the source's
  /// files, e.g. an in-memory preview).
  static DeckCopy copy(
    DeckReader source, {
    required String deckId,
    required String userId,
    required DateTime now,
    String? title,
    IdGenerator ids = const UuidV7IdGenerator(),
    bool rehomeFiles = true,
  }) {
    final deck = source.deck;
    if (deck == null) {
      throw ArgumentError('Deck ${source.deckId} has no deck row to copy.');
    }
    final map = <String, String>{source.deckId: deckId};
    // Fresh ids never reuse a source id (UUIDv7 can't, but injected
    // generators in tests and imports might).
    final taken = <String>{
      source.deckId,
      for (final t in SlidesTables.dependencyOrder)
        for (final r in source.records(t)) r.id,
    };
    String fresh() {
      while (true) {
        final id = ids.newId();
        if (taken.add(id)) return id;
      }
    }

    final dropped = <String>[];

    // ---- themes and their parts (deterministic ids)
    final themes = source.records(SlidesTables.deckTheme).toList();
    final masters = source.records(SlidesTables.slideMaster).toList();
    final layouts = source.records(SlidesTables.slideLayout).toList();
    for (final t in themes) {
      final sourceKey = t[DeckThemeCols.sourceKey] as String?;
      var id = sourceKey == null
          ? null
          : SlidesIds.themeCopyId(deckId, sourceKey);
      if (id == null || map.containsValue(id)) id = fresh();
      map[t.id] = id;
    }
    // Built-in part keys of the source's built-in copies.
    final partKeys = <String, String>{};
    for (final t in themes) {
      final key = _builtinKey(t[DeckThemeCols.sourceKey] as String?);
      final pkg = key == null ? null : BuiltInThemes.package(key);
      if (pkg == null) continue;
      void add(String pk) => partKeys[SlidesIds.themePartId(t.id, pk)] = pk;
      for (final m in pkg.masters) {
        add(m.partKey);
        for (final e in m.elements) {
          add(e.partKey);
        }
        for (final l in m.layouts) {
          add(l.partKey);
          for (final e in l.elements) {
            add(e.partKey);
          }
        }
      }
    }
    String part(String themeId, String oldId) =>
        SlidesIds.themePartId(map[themeId]!, partKeys[oldId] ?? oldId);
    final themeOfMaster = <String, String>{};
    for (final m in masters) {
      final t = m[SlideMasterCols.themeId] as String?;
      if (t == null || !map.containsKey(t)) continue;
      themeOfMaster[m.id] = t;
      map[m.id] = part(t, m.id);
    }
    final themeOfLayout = <String, String>{};
    for (final l in layouts) {
      final t = themeOfMaster[l[SlideLayoutCols.masterId]];
      if (t == null) continue;
      themeOfLayout[l.id] = t;
      map[l.id] = part(t, l.id);
    }
    final elements = source.records(SlidesTables.slideElement).toList();
    for (final e in elements) {
      final master = e[ElementCols.masterId] as String?;
      final layout = e[ElementCols.layoutId] as String?;
      final t = master != null
          ? themeOfMaster[master]
          : (layout != null ? themeOfLayout[layout] : null);
      if (t != null) map[e.id] = part(t, e.id);
    }

    // ---- groups, slides
    for (final g in source.records(SlidesTables.slideGroup)) {
      map[g.id] = fresh();
    }
    for (final s in source.records(SlidesTables.slide)) {
      map[s.id] = fresh();
    }

    // ---- slide elements: placeholder instances keep deterministic ids
    for (final e in elements) {
      final slide = e[SlidesCols.slideId] as String?;
      if (slide == null) continue;
      final newSlide = map[slide];
      if (newSlide == null) continue;
      final of = e[ElementCols.placeholderOf] as String?;
      final newOf = of == null ? null : map[of];
      if (of != null &&
          newOf != null &&
          e.id == SlidesIds.placeholderInstanceId(slide, of)) {
        map[e.id] = SlidesIds.placeholderInstanceId(newSlide, newOf);
      } else {
        map[e.id] = fresh();
      }
    }

    // ---- dependent rows
    final axes = source.records(SlidesTables.slideTableAxis).toList();
    for (final a in axes) {
      if (map.containsKey(a[SlidesCols.elementId])) map[a.id] = fresh();
    }
    final cells = source.records(SlidesTables.slideTableCell).toList();
    for (final c in cells) {
      final el = map[c[SlidesCols.elementId]];
      final row = map[c[TableCellCols.rowId]];
      final col = map[c[TableCellCols.columnId]];
      if (el == null || row == null || col == null) continue;
      map[c.id] = SlidesIds.tableCellId(el, row, col);
    }
    final builds = source.records(SlidesTables.slideBuild).toList();
    for (final b in builds) {
      if (map.containsKey(b[SlidesCols.elementId]) &&
          map.containsKey(b[SlidesCols.slideId])) {
        map[b.id] = fresh();
      }
    }
    final states = source.records(SlidesTables.codeState).toList();
    for (final s in states) {
      if (map.containsKey(s[SlidesCols.elementId])) map[s.id] = fresh();
    }
    final links = source.records(SlidesTables.chartLink).toList();
    for (final l in links) {
      final el = map[l[SlidesCols.elementId]];
      if (el != null) map[l.id] = SlidesIds.chartLinkId(el);
    }

    // ---- files
    final files = <String, String>{};
    if (rehomeFiles) {
      for (final table in SlidesTables.dependencyOrder) {
        for (final r in source.records(table)) {
          for (final e in r.columns.entries) {
            if (!e.key.endsWith('Json') || e.value is! String) continue;
            for (final f in SlidesIdRemapper.fileRefs(e.value as String?)) {
              files.putIfAbsent(f, fresh);
            }
          }
        }
      }
    }
    final remap = SlidesIdRemapper(map, files: files);

    // ---- rows
    final rows = <SlidesRow>[];
    Map<String, Object?>? row(
      String table,
      Map<String, Object?> src, {
      Set<String> required = const {},
    }) {
      final out = <String, Object?>{};
      for (final c in SlidesTables.columns[table]!) {
        final v = src[c];
        if (c == SlidesCols.id) {
          out[c] = map[v];
        } else if (_refColumns.contains(c)) {
          final m = remap.mapped(v);
          if (m == null && v != null && required.contains(c)) return null;
          out[c] = m;
        } else if (c.endsWith('Json')) {
          out[c] = remap.json(v as String?);
        } else if (c == SlidesCols.text || c == SlideCols.notes) {
          out[c] = remap.text(v as String?);
        } else {
          out[c] = v;
        }
      }
      if (out[SlidesCols.id] == null) return null;
      for (final c in required) {
        if (out[c] == null) return null;
      }
      return out;
    }

    void add(
      String table,
      Iterable<Map<String, Object?>> sources, {
      Set<String> required = const {},
    }) {
      for (final src in sources) {
        final r = row(table, src, required: required);
        if (r == null) {
          dropped.add('$table:${src[SlidesCols.id]}');
          continue;
        }
        rows.add((table, r));
      }
    }

    rows.add((
      SlidesTables.deck,
      row(SlidesTables.deck, deck.columns)!
        ..[DeckCols.title] = title ?? deck[DeckCols.title]
        ..[DeckCols.createdBy] = userId
        ..[SlidesCols.createdAt] = now,
    ));
    add(
      SlidesTables.deckTheme,
      [
        for (final t in themes)
          {...t.columns, DeckThemeCols.deckId: source.deckId},
      ],
      required: {DeckThemeCols.deckId},
    );
    add(
      SlidesTables.slideMaster,
      [for (final m in masters) m.columns],
      required: {SlideMasterCols.themeId},
    );
    add(
      SlidesTables.slideLayout,
      [for (final l in layouts) l.columns],
      required: {SlideLayoutCols.masterId},
    );
    add(
      SlidesTables.slideGroup,
      [
        for (final g in source.records(SlidesTables.slideGroup))
          {...g.columns, SlidesCols.deckId: source.deckId},
      ],
      required: {SlidesCols.deckId},
    );
    add(
      SlidesTables.slide,
      [
        for (final s in source.records(SlidesTables.slide))
          {...s.columns, SlidesCols.deckId: source.deckId},
      ],
      required: {SlidesCols.deckId},
    );
    for (final e in elements) {
      final owner = ElementCols.owners.firstWhere(
        (c) => e[c] != null,
        orElse: () => SlidesCols.slideId,
      );
      final r = row(SlidesTables.slideElement, e.columns, required: {owner});
      if (r == null ||
          (e[SlidesCols.parentId] != null && r[SlidesCols.parentId] == null)) {
        dropped.add('${SlidesTables.slideElement}:${e.id}');
        continue;
      }
      final mk = e[ElementCols.matchKey] as String?;
      if (mk != null) {
        r[ElementCols.matchKey] = mk == ThemeCopy.partMatchKey(e.id)
            ? ThemeCopy.partMatchKey(r[SlidesCols.id]! as String)
            : remap.string(mk);
      }
      rows.add((SlidesTables.slideElement, r));
    }
    // Elements dropped above drop their descendants and dependent rows.
    final kept = {
      for (final (t, r) in rows)
        if (t == SlidesTables.slideElement) r[SlidesCols.id],
    };
    var changed = true;
    while (changed) {
      changed = false;
      rows.removeWhere((x) {
        final (t, r) = x;
        if (t != SlidesTables.slideElement) return false;
        final p = r[SlidesCols.parentId];
        if (p == null || kept.contains(p)) return false;
        kept.remove(r[SlidesCols.id]);
        dropped.add('${SlidesTables.slideElement}:${r[SlidesCols.id]}');
        changed = true;
        return true;
      });
    }
    bool keptElement(Map<String, Object?> src) =>
        kept.contains(map[src[SlidesCols.elementId]]);
    add(
      SlidesTables.slideTableAxis,
      [
        for (final a in axes)
          if (keptElement(a.columns)) a.columns,
      ],
      required: {SlidesCols.elementId},
    );
    add(
      SlidesTables.slideTableCell,
      [
        for (final c in cells)
          if (keptElement(c.columns)) c.columns,
      ],
      required: {
        SlidesCols.elementId,
        TableCellCols.rowId,
        TableCellCols.columnId,
      },
    );
    add(
      SlidesTables.slideBuild,
      [
        for (final b in builds)
          if (keptElement(b.columns)) b.columns,
      ],
      required: {SlidesCols.slideId, SlidesCols.elementId},
    );
    add(
      SlidesTables.codeState,
      [
        for (final s in states)
          if (keptElement(s.columns)) s.columns,
      ],
      required: {SlidesCols.elementId},
    );
    add(
      SlidesTables.chartLink,
      [
        for (final l in links)
          if (keptElement(l.columns)) l.columns,
      ],
      required: {SlidesCols.elementId},
    );

    final copied = {for (final (_, r) in rows) r[SlidesCols.id]};
    return DeckCopy(
      deckId: deckId,
      rows: rows,
      ids: {
        for (final e in map.entries)
          if (copied.contains(e.value)) e.key: e.value,
      },
      files: [for (final e in files.entries) FileRehome(e.key, e.value)],
      dropped: dropped,
    );
  }

  /// UUID columns that reference rows of the deck.
  static const _refColumns = {
    'deckId',
    'slideId',
    'elementId',
    'parentId',
    'themeId',
    'masterId',
    'groupId',
    'layoutId',
    'placeholderOf',
    'rowId',
    'columnId',
  };

  /// The built-in key of a `builtin:<key>@<version>` source key.
  static String? _builtinKey(String? sourceKey) {
    if (sourceKey == null || !sourceKey.startsWith('builtin:')) return null;
    final rest = sourceKey.substring(8);
    final at = rest.lastIndexOf('@');
    return at < 0 ? rest : rest.substring(0, at);
  }
}
