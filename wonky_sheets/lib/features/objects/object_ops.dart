import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../model/sheets_undo.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'objects_controller.dart';

/// Shared object operations of the object, chart and image commands
/// (08 §9, §15).
abstract final class ObjectOps {
  /// The object named by `objectId` in [args], else the selected one.
  static EmbeddedObjectRecord? target(
    SheetEditorController ed,
    Map<String, Object?> args,
  ) {
    final objs = ObjectsController.of(ed);
    final id = args['objectId'];
    if (id is String && id.isNotEmpty) return objs.record(id);
    return objs.selected;
  }

  /// The objects named by `objectIds` (or `objectId`), else the selection.
  static List<EmbeddedObjectRecord> targets(
    SheetEditorController ed,
    Map<String, Object?> args,
  ) {
    final objs = ObjectsController.of(ed);
    final ids = args['objectIds'];
    if (ids is List && ids.isNotEmpty) {
      return [
        for (final id in ids)
          if (id is String) ?objs.record(id),
      ];
    }
    final id = args['objectId'];
    if (id is String && id.isNotEmpty) {
      final one = objs.record(id);
      return one == null ? const [] : [one];
    }
    return objs.selectedRecords;
  }

  /// A normalized anchor with its top-left at sheet px ([x], [y]) on
  /// [sheet], keeping [base]'s aspect lock and extras.
  static ObjectAnchor anchorAt(
    SheetModel sheet,
    double x,
    double y, {
    required double width,
    required double height,
    ObjectAnchor? base,
  }) => ObjectAnchor.normalizeAt(
    x < 0 ? 0 : x,
    y < 0 ? 0 : y,
    width: width,
    height: height,
    rows: sheet.rows,
    columns: sheet.columns,
    lockAspect: base?.lockAspect ?? false,
    extras: base?.extras ?? const {},
  );

  /// The visible viewport of the main pane in sheet px (100 % zoom).
  static ChartRect? viewport(SheetEditorController ed) {
    final g = ed.geometry;
    if (g == null) return null;
    final m = g.main;
    final x = g.sheet.columns.offsetOf(m.firstCol) + m.scrollX / g.zoom;
    final y = g.sheet.rows.offsetOf(m.firstRow) + m.scrollY / g.zoom;
    return ChartRect(x, y, m.rect.width / g.zoom, m.rect.height / g.zoom);
  }

  /// Records [plan] (already applied with `session.execute`) as an undo step that merges with the previous step of
  /// the same [key] within 1000 ms (nudge bursts, chart editor fields; 08
  /// §8, §9.3). Changes to the same row and column keep the earliest
  /// "before" and the latest "after", so one undo restores the start state.
  static void recordCoalesced(
    CommandContext ctx,
    SheetEditorController ed,
    MutationPlan plan, {
    required String key,
    required String label,
  }) => recordCoalescedChanges(
    ctx,
    ed,
    plan.changes,
    key: key,
    label: label,
    planLabel: plan.label,
  );

  /// [recordCoalesced] for changes of several plans (group nudges).
  static void recordCoalescedChanges(
    CommandContext ctx,
    SheetEditorController ed,
    List<RowChange> changes, {
    required String key,
    required String label,
    String? planLabel,
  }) {
    if (changes.isEmpty) return;
    final doc = ctx.document;
    if (doc == null || ctx.transaction == null) return;
    final undo = ed.services.undo;
    final stack = doc.undoStackKey;
    final steps = undo.undoStepsOf(stack);
    final top = steps.isEmpty ? null : steps.last;
    final now = clock.now();
    if (top != null &&
        top.coalesceKey == key &&
        now.difference(top.updatedAt) <= undo.coalesceWindow &&
        top.entries.length == 1 &&
        top.entries.single is SheetsRowsUndoEntry) {
      final prev = top.entries.single as SheetsRowsUndoEntry;
      undo.replaceLast(
        UndoStep(
          id: top.id,
          label: top.label,
          entries: [
            SheetsRowsUndoEntry(
              mergeChanges(prev.changes, changes),
              label: prev.label,
            ),
          ],
          selectionBefore: top.selectionBefore,
          selectionAfter: top.selectionAfter,
          createdAt: top.createdAt,
          updatedAt: now,
          source: top.source,
          coalesceKey: key,
        ),
        stack: stack,
      );
      return;
    }
    undo.push(
      UndoStep(
        id: ed.services.ids.nextString(),
        label: label,
        entries: [SheetsRowsUndoEntry(changes, label: planLabel ?? label)],
        selectionBefore: ctx.selection,
        source: ctx.source,
        coalesceKey: key,
      ),
      stack: stack,
    );
  }

  /// [a] then [b] as one list: consecutive updates of the same row merge
  /// (earliest before, latest after).
  static List<RowChange> mergeChanges(List<RowChange> a, List<RowChange> b) {
    final out = [...a];
    for (final c in b) {
      final i = out.lastIndexWhere(
        (x) => x.table == c.table && x.rowId == c.rowId,
      );
      // Later changes of other rows don't depend on this row's columns
      // (object anchors), so an earlier update of the same row merges too.
      final mergeable =
          i >= 0 &&
          out[i].op == RowOp.update &&
          c.op == RowOp.update &&
          (i == out.length - 1 ||
              out
                  .skip(i + 1)
                  .every(
                    (x) =>
                        x.op == RowOp.update &&
                        x.table == SheetsTables.embeddedObject &&
                        c.table == SheetsTables.embeddedObject,
                  ));
      if (mergeable) {
        final p = out[i];
        final before = {...p.columnsBefore};
        final after = {...p.columnsAfter};
        c.columnsBefore.forEach((k, v) => before.putIfAbsent(k, () => v));
        after.addAll(c.columnsAfter);
        out[i] = RowChange.update(c.table, c.rowId, before, after);
      } else {
        out.add(c);
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Clipboard (08 §9.5).

  /// In-app object clipboard (shared by every open spreadsheet).
  static ObjectClip? clip;

  /// Text marker written to the system clipboard with an object copy.
  static const clipMarker = 'wonky-sheets-objects:';

  /// The clipboard payload of [objects]: spec ranges re-encoded as A1 with
  /// sheet names so the paste resolves them in any spreadsheet.
  static ObjectClip copy(
    SheetEditorController ed,
    List<EmbeddedObjectRecord> objects,
  ) {
    final items = <Map<String, Object?>>[];
    for (final o in objects) {
      final spec = jsonDecode(o.specJson);
      final map = spec is Map
          ? spec.cast<String, Object?>()
          : <String, Object?>{};
      final ranges = <String>[];
      if (o.kind == EmbeddedObjectKind.chart) {
        final s = ChartSpec.fromJson(map);
        for (final g in s.data.gridRanges) {
          final sh = ed.model.sheet(g.sheetId);
          final rr = sh?.resolve(g);
          if (sh == null || rr == null) {
            ranges.add('');
            continue;
          }
          ranges.add(ed.model.a1Of(rr));
        }
      }
      items.add({
        'kind': o.kind.name,
        'anchor': o.anchorJson,
        'spec': map,
        'rangesA1': ranges,
        'title': o.title,
        'altText': o.altText,
        // Slides 03 A-03-5: a chart pasted into Wonky Slides links back.
        'spreadsheetItemUuid': ed.session.itemUuid.uuid,
        'objectId': o.id,
        'sheetId': o.sheetId,
      });
    }
    final id = ed.services.ids.nextString();
    // Slides 03 §12.4: the other Wonky Work apps (same origin, same user
    // store) paste the objects from the marker on the system clipboard.
    unawaited(_share(ed, id, items));
    return clip = ObjectClip(id, items, ed.clipboard.last);
  }

  /// Key of the shared objects copy in the user's local store (read by
  /// Wonky Slides' paste with the [clipMarker] text).
  static const sharedClipKey = 'clipboard.sheetsObjects';

  static Future<void> _share(
    SheetEditorController ed,
    String id,
    List<Map<String, Object?>> items,
  ) async {
    try {
      await ed.services.userStore.write(sharedClipKey, {
        'id': id,
        'items': items,
      });
    } catch (_) {
      // Best effort: pasting inside Sheets uses the in-memory clip.
    }
  }

  /// Rebuilds a chart spec's ranges from the clip's A1 texts against [ed]'s
  /// workbook (missing sheets keep the stored range: "Data range not
  /// found").
  static Map<String, Object?> resolveSpec(
    SheetEditorController ed,
    Map<String, Object?> item,
  ) {
    final spec = Map<String, Object?>.of(
      (item['spec'] as Map?)?.cast<String, Object?>() ?? const {},
    );
    final a1 = (item['rangesA1'] as List?)?.cast<String>() ?? const [];
    if (item['kind'] != EmbeddedObjectKind.chart.name || a1.isEmpty) {
      return spec;
    }
    final data = Map<String, Object?>.of(
      (spec['data'] as Map?)?.cast<String, Object?>() ?? const {},
    );
    final old = (data['ranges'] as List?) ?? const [];
    final ranges = <Object?>[];
    for (var i = 0; i < a1.length; i++) {
      try {
        final rr = ed.model.parseA1(a1[i], contextSheetId: ed.activeSheetId);
        final sh = ed.model.sheet(rr.sheetId)!;
        ranges.add(
          sh
              .gridRange(
                rr.rect,
                wholeRows: rr.wholeRows,
                wholeColumns: rr.wholeColumns,
              )
              .toJson(),
        );
      } catch (_) {
        if (i < old.length) ranges.add(old[i]);
      }
    }
    data['ranges'] = ranges;
    spec['data'] = data;
    return spec;
  }

  /// A1 of [rect] on the active sheet (helper for results).
  static String a1(GridRect rect) => rect.a1;
}

/// Copied objects (08 §9.5 `application/x-wonky-sheets-objects`).
class ObjectClip {
  ObjectClip(this.id, this.items, this.cellClipAtCopy);

  final String id;
  final List<Map<String, Object?>> items;

  /// The grid clipboard payload when the objects were copied: a later cell
  /// copy makes Mod+V paste cells again.
  final Object? cellClipAtCopy;

  String get marker => '${ObjectOps.clipMarker}$id';
}
