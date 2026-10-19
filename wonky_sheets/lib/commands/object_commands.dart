import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show CellPos;
import 'package:wonky_sheets_core/model.dart';

import '../features/clipboard/system_clipboard.dart';
import 'package:wonky_app/platform.dart' show ImageClipboard;
import '../features/objects/object_png.dart';
import '../features/objects/alt_text_dialog.dart';
import '../features/objects/object_ops.dart';
import '../features/objects/objects_controller.dart';
import '../features/objects/objects_layer.dart' show objectKeyScope;
import '../features/sheet_editor/sheet_editor_controller.dart';
import 'sheets_command.dart';

SheetsText _cat = (l) => l.categoryObjects;

ObjectsController _objs(SheetEditorController ed) => ObjectsController.of(ed);

const _objectIdsSchema = JsonSchema.object(
  properties: {
    'objectIds': JsonSchema.array(
      JsonSchema.string(),
      description: 'Object ids (default: the selected object).',
    ),
  },
);

bool _hasTarget(SheetEditorController ed, JsonArgs a) =>
    ObjectOps.target(ed, a.values) != null;

bool _onChartSheet(SheetEditorController ed, EmbeddedObjectRecord o) =>
    ed.model.sheet(o.sheetId)?.record?.kind == SheetKind.chart;

/// Scrolls so that the object [o] is visible (top-left first).
void revealObject(SheetEditorController ed, EmbeddedObjectRecord o) {
  final cell = _objs(ed).anchorCell(o);
  if (cell != null) ed.revealCell(cell.$1, cell.$2);
}

String? _missing(SheetEditorController ed) => ed.l10n.objectNotFound;

/// The object commands (08 §9, §16): select, move, resize, nudge, order,
/// delete, duplicate, clipboard, alt text, list.
List<Command<CommandArgs>> objectCommands(ShellServices s) => [
  SheetsCommand(
    'sheets.object.select',
    label: (l) => l.cmdObjectSelect,
    categoryName: _cat,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': JsonSchema.string(),
        'objectIds': JsonSchema.array(
          JsonSchema.string(),
          description: 'Selects several objects of one sheet.',
        ),
        'add': JsonSchema.boolean(
          description: 'Toggle objectId in the current selection.',
        ),
      },
    ),
    run: (ctx, ed, a) {
      final objs = _objs(ed);
      final ids = a.strings('objectIds');
      if (ids.isNotEmpty) {
        final list = [for (final id in ids) ?objs.record(id)];
        if (list.isEmpty) return CommandResult.failed(_missing(ed)!);
        final sheet = list.last.sheetId;
        if (sheet != ed.activeSheetId) ed.activateSheet(sheet);
        objs.selectAll([
          for (final o in list)
            if (o.sheetId == sheet) o.id,
        ]);
        revealObject(ed, list.last);
        return ok({'objectIds': objs.selectedIds});
      }
      final o = objs.record(a.string('objectId'));
      if (o == null) return CommandResult.failed(_missing(ed)!);
      if (o.sheetId != ed.activeSheetId) ed.activateSheet(o.sheetId);
      if (a.boolean('add') ?? false) {
        objs.toggleSelect(o.id);
      } else {
        objs.select(o.id);
      }
      revealObject(ed, o);
      return ok({'objectId': o.id, 'objectIds': objs.selectedIds});
    },
  ),
  for (final (id, label, fwd) in <(String, SheetsText, bool)>[
    ('sheets.object.selectNext', (l) => l.cmdObjectSelectNext, true),
    ('sheets.object.selectPrevious', (l) => l.cmdObjectSelectPrevious, false),
  ])
    SheetsCommand(
      id,
      label: label,
      categoryName: _cat,
      defaultBindings: fwd
          ? const [KeyBinding('O', mod: true, alt: true, shift: true)]
          : const [],
      argBindings: fwd
          ? const [
              ArgsKeyBinding(
                KeyBinding('O', mod: true, alt: true, shift: true),
                {},
                scope: objectKeyScope,
              ),
            ]
          : const [],
      enabled: (ed, a) => _objs(ed).activeObjects.isNotEmpty,
      run: (ctx, ed, a) {
        final objs = _objs(ed);
        final items = objs.zItems(ed.activeSheetId);
        final next = fwd
            ? ZOrder.selectNext(items, objs.selectedId)
            : ZOrder.selectPrevious(items, objs.selectedId);
        if (next == null) return const CommandResult.cancelled();
        objs.select(next);
        final o = objs.record(next);
        if (o != null) revealObject(ed, o);
        return ok({'objectId': next});
      },
    ),
  SheetsCommand(
    'sheets.object.deselect',
    label: (l) => l.cmdObjectDeselect,
    categoryName: _cat,
    showInPalette: false,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('Escape')],
    run: (ctx, ed, a) {
      _objs(ed).select(null);
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.object.move',
    label: (l) => l.cmdObjectMove,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': JsonSchema.string(),
        'objectIds': JsonSchema.array(
          JsonSchema.string(),
          description: 'Objects moved together with "by" (group move).',
        ),
        'anchor': JsonSchema.object(
          description: 'New anchor: {cell: A1, dx, dy} (px at 100 % zoom).',
          additionalProperties: true,
        ),
        'by': JsonSchema.object(
          description: 'Move by {x, y} px.',
          additionalProperties: true,
        ),
        'to': JsonSchema.object(
          description: 'Top-left at sheet px {x, y} (100 % zoom).',
          additionalProperties: true,
        ),
      },
    ),
    enabled: (ed, a) {
      final o = ObjectOps.target(ed, a.values);
      return o != null && !_onChartSheet(ed, o);
    },
    run: (ctx, ed, a) {
      final v = a.values;
      // Group move (multi-selection drag): every object by the same offset.
      final group = a.strings('objectIds');
      if (group.isNotEmpty && v['by'] is Map) {
        final by = v['by']! as Map;
        final ids = <String>[];
        for (final o in ObjectOps.targets(ed, {'objectIds': group})) {
          if (_onChartSheet(ed, o)) continue;
          final anchor = _anchorBy(ed, o, _num(by['x']), _num(by['y']));
          if (anchor == null) continue;
          ed.apply(ctx, UpdateObject(o.id, anchorJson: anchor.encode()));
          ids.add(o.id);
        }
        if (ids.isEmpty) return CommandResult.failed(_missing(ed)!);
        return ok({'objectIds': ids});
      }
      final o = ObjectOps.target(ed, a.values);
      final sheet = o == null ? null : ed.model.sheet(o.sheetId);
      final base = o == null ? null : _objs(ed).anchorOf(o);
      final rect = o == null ? null : _objs(ed).rectOf(o, ghost: false);
      if (o == null || sheet == null || base == null || rect == null) {
        return CommandResult.failed(_missing(ed)!);
      }
      ObjectAnchor anchor;
      if (v['anchor'] case final Map<dynamic, dynamic> m) {
        final cell = ed.model.parseA1(
          '${m['cell'] ?? 'A1'}',
          contextSheetId: sheet.id,
        );
        anchor = ObjectAnchor.atCell(
          cell.rect.top,
          cell.rect.left,
          width: base.width,
          height: base.height,
          rows: sheet.rows,
          columns: sheet.columns,
          dx: _num(m['dx']),
          dy: _num(m['dy']),
          lockAspect: base.lockAspect,
          extras: base.extras,
        );
      } else if (v['to'] case final Map<dynamic, dynamic> m) {
        anchor = ObjectOps.anchorAt(
          sheet,
          _num(m['x']),
          _num(m['y']),
          width: base.width,
          height: base.height,
          base: base,
        );
      } else if (v['by'] case final Map<dynamic, dynamic> m) {
        anchor = ObjectOps.anchorAt(
          sheet,
          rect.left + _num(m['x']),
          rect.top + _num(m['y']),
          width: base.width,
          height: base.height,
          base: base,
        );
      } else {
        return const CommandResult.failed('anchor, to or by is required');
      }
      ed.apply(ctx, UpdateObject(o.id, anchorJson: anchor.encode()));
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.object.resize',
    label: (l) => l.cmdObjectResize,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': JsonSchema.string(),
        'width': JsonSchema.number(description: 'px at 100 % zoom'),
        'height': JsonSchema.number(description: 'px at 100 % zoom'),
        'x': JsonSchema.number(description: 'New left (sheet px), optional'),
        'y': JsonSchema.number(description: 'New top (sheet px), optional'),
      },
      required: ['width', 'height'],
    ),
    enabled: (ed, a) {
      final o = ObjectOps.target(ed, a.values);
      return o != null && !_onChartSheet(ed, o);
    },
    run: (ctx, ed, a) {
      final o = ObjectOps.target(ed, a.values);
      final sheet = o == null ? null : ed.model.sheet(o.sheetId);
      final base = o == null ? null : _objs(ed).anchorOf(o);
      final rect = o == null ? null : _objs(ed).rectOf(o, ghost: false);
      if (o == null || sheet == null || base == null || rect == null) {
        return CommandResult.failed(_missing(ed)!);
      }
      final v = a.values;
      final anchor = ObjectOps.anchorAt(
        sheet,
        v['x'] is num ? _num(v['x']) : rect.left,
        v['y'] is num ? _num(v['y']) : rect.top,
        width: _num(v['width']),
        height: _num(v['height']),
        base: base,
      );
      ed.apply(ctx, UpdateObject(o.id, anchorJson: anchor.encode()));
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.object.nudge',
    label: (l) => l.cmdObjectNudge,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    keyScope: objectKeyScope,
    argsSchema: const JsonSchema.object(
      properties: {
        'dx': JsonSchema.number(description: 'px (or cells with cells)'),
        'dy': JsonSchema.number(description: 'px (or cells with cells)'),
        'cells': JsonSchema.boolean(description: 'Move by whole cells.'),
      },
    ),
    argBindings: [
      for (final (key, dx, dy) in const [
        ('ArrowLeft', -1, 0),
        ('ArrowRight', 1, 0),
        ('ArrowUp', 0, -1),
        ('ArrowDown', 0, 1),
      ]) ...[
        ArgsKeyBinding(KeyBinding(key), {'dx': dx, 'dy': dy}),
        ArgsKeyBinding(KeyBinding(key, shift: true), {
          'dx': dx * 10,
          'dy': dy * 10,
        }),
        ArgsKeyBinding(KeyBinding(key, alt: true), {
          'dx': dx,
          'dy': dy,
          'cells': true,
        }),
      ],
    ],
    enabled: (ed, a) {
      final o = _objs(ed).selected;
      return o != null && !_onChartSheet(ed, o);
    },
    run: (ctx, ed, a) {
      final objs = _objs(ed);
      final list = [
        for (final o in objs.selectedRecords)
          if (!_onChartSheet(ed, o)) o,
      ];
      if (list.isEmpty) return const CommandResult.cancelled();
      final dx = _num(a.values['dx']);
      final dy = _num(a.values['dy']);
      final cells = a.boolean('cells') ?? false;
      final changes = <RowChange>[];
      String? label;
      for (final o in list) {
        final anchor = cells
            ? _anchorByCells(ed, o, dx, dy)
            : _anchorBy(ed, o, dx, dy);
        if (anchor == null) continue;
        final plan = ed.session.execute(
          UpdateObject(o.id, anchorJson: anchor.encode()),
        );
        changes.addAll(plan.changes);
        label ??= plan.label;
      }
      ObjectOps.recordCoalescedChanges(
        ctx,
        ed,
        changes,
        key: 'nudge:${[for (final o in list) o.id].join(',')}',
        label: ed.l10n.cmdObjectMove,
        planLabel: label,
      );
      revealObject(ed, list.last);
      return ok();
    },
  ),
  SheetsCommand(
    'sheets.object.order',
    label: (l) => l.cmdObjectOrder,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': JsonSchema.string(),
        'op': JsonSchema.string(
          enumValues: ['front', 'forward', 'backward', 'back'],
        ),
      },
      required: ['op'],
    ),
    undoLabelOf: (l, a) => switch (a.string('op')) {
      'front' => l.objectOrderFront,
      'forward' => l.objectOrderForward,
      'backward' => l.objectOrderBackward,
      _ => l.objectOrderBack,
    },
    enabled: (ed, a) {
      final list = ObjectOps.targets(ed, a.values);
      if (list.isEmpty || list.any((o) => _onChartSheet(ed, o))) return false;
      return list.any(
        (o) => _zChanges(_objs(ed).zItems(o.sheetId), o.id, a).isNotEmpty,
      );
    },
    run: (ctx, ed, a) {
      final list = ObjectOps.targets(ed, a.values);
      if (list.isEmpty) return CommandResult.failed(_missing(ed)!);
      if (!const [
        'front',
        'forward',
        'backward',
        'back',
      ].contains(a.string('op'))) {
        throw const PlanException('invalid', 'Unknown op');
      }
      // Groups keep their relative order: the topmost goes first when
      // sending backward, the bottommost when bringing forward.
      final objs = _objs(ed);
      int zOf(EmbeddedObjectRecord o) => objs.record(o.id)?.zIndex ?? o.zIndex;
      final up = a.string('op') == 'front' || a.string('op') == 'forward';
      final ordered = [...list]
        ..sort((x, y) {
          final c = zOf(x).compareTo(zOf(y));
          final r = c != 0 ? c : x.id.compareTo(y.id);
          return up ? r : -r;
        });
      var changed = 0;
      for (final o in ordered) {
        final z = _zChanges(objs.zItems(o.sheetId), o.id, a);
        for (final e in z.entries) {
          ed.apply(ctx, UpdateObject(e.key, zIndex: e.value));
        }
        changed += z.length;
      }
      return ok({'changed': changed});
    },
  ),
  SheetsCommand(
    'sheets.object.align',
    label: (l) => l.cmdObjectAlign,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectIds': JsonSchema.array(
          JsonSchema.string(),
          description: 'Objects to align (default: the selection).',
        ),
        'op': JsonSchema.string(
          enumValues: [
            'left',
            'center',
            'right',
            'top',
            'middle',
            'bottom',
            'distributeHorizontally',
            'distributeVertically',
          ],
        ),
      },
      required: ['op'],
    ),
    undoLabelOf: (l, a) => l.undoAlignObjects,
    enabled: (ed, a) {
      final list = ObjectOps.targets(ed, a.values);
      final need = (a.string('op') ?? '').startsWith('distribute') ? 3 : 2;
      return list.length >= need && !list.any((o) => _onChartSheet(ed, o));
    },
    run: (ctx, ed, a) {
      final objs = _objs(ed);
      final list = ObjectOps.targets(ed, a.values);
      final rects = <String, ChartRect>{
        for (final o in list) o.id: ?objs.rectOf(o, ghost: false),
      };
      if (rects.length < 2) return CommandResult.failed(_missing(ed)!);
      final next = ObjectAlign.apply(rects, a.string('op') ?? 'left');
      var moved = 0;
      for (final o in list) {
        final to = next[o.id];
        final from = rects[o.id];
        if (to == null || from == null) continue;
        if (to.left == from.left && to.top == from.top) continue;
        final anchor = _anchorBy(ed, o, to.left - from.left, to.top - from.top);
        if (anchor == null) continue;
        ed.apply(ctx, UpdateObject(o.id, anchorJson: anchor.encode()));
        moved++;
      }
      return ok({'moved': moved});
    },
  ),
  SheetsCommand(
    'sheets.object.delete',
    label: (l) => l.cmdObjectDelete,
    icon: LucideIcons.trash2,
    categoryName: _cat,
    mutates: true,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('Delete'), KeyBinding('Backspace')],
    argsSchema: _objectIdsSchema,
    enabled: (ed, a) => ObjectOps.targets(ed, a.values).isNotEmpty,
    run: (ctx, ed, a) async {
      final list = ObjectOps.targets(ed, a.values);
      if (list.isEmpty) return CommandResult.failed(_missing(ed)!);
      final chartSheets = <String>{
        for (final o in list)
          if (_onChartSheet(ed, o)) o.sheetId,
      };
      if (chartSheets.isNotEmpty && ctx.source != InvocationSource.mcp) {
        final c = ctx.dialogContext;
        if (c != null) {
          final l = ed.l10n;
          final yes = await confirmDialog(
            c,
            title: l.dialogDeleteChartSheetTitle,
            description: l.dialogDeleteChartSheetBody,
            confirmLabel: l.dialogDelete,
            destructive: true,
          );
          if (!yes) return const CommandResult.cancelled();
        }
      }
      for (final o in list) {
        if (_onChartSheet(ed, o)) continue;
        await ed.applyConfirmed(ctx, DeleteObject(o.id));
      }
      for (final sid in chartSheets) {
        await ed.applyConfirmed(ctx, DeleteSheet(sid));
      }
      _objs(ed).select(null);
      return ok({'deleted': list.length});
    },
  ),
  SheetsCommand(
    'sheets.object.duplicate',
    label: (l) => l.cmdObjectDuplicate,
    icon: LucideIcons.copyPlus,
    categoryName: _cat,
    mutates: true,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('D', mod: true)],
    argsSchema: _objectIdsSchema,
    enabled: (ed, a) {
      final list = ObjectOps.targets(ed, a.values);
      return list.isNotEmpty && !list.any((o) => _onChartSheet(ed, o));
    },
    run: (ctx, ed, a) {
      final list = ObjectOps.targets(ed, a.values);
      final ids = <String>[];
      for (final o in list) {
        final sheet = ed.model.sheet(o.sheetId);
        final base = _objs(ed).anchorOf(o);
        final rect = _objs(ed).rectOf(o, ghost: false);
        if (sheet == null || base == null || rect == null) continue;
        final anchor = ObjectOps.anchorAt(
          sheet,
          rect.left + ObjectAnchor.duplicateOffset,
          rect.top + ObjectAnchor.duplicateOffset,
          width: base.width,
          height: base.height,
          base: base,
        );
        final plan = ed.apply(
          ctx,
          AddObject(
            o.sheetId,
            o.kind,
            anchorJson: anchor.encode(),
            specJson: o.specJson,
            altText: o.altText,
          ),
        );
        ids.add(plan.result['objectId']! as String);
      }
      if (ids.isNotEmpty) _objs(ed).select(ids.last);
      return ok({'objectIds': ids});
    },
  ),
  SheetsCommand(
    'sheets.object.copy',
    label: (l) => l.cmdObjectCopy,
    icon: LucideIcons.copy,
    categoryName: _cat,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('C', mod: true)],
    argsSchema: _objectIdsSchema,
    enabled: (ed, a) => ObjectOps.targets(ed, a.values).isNotEmpty,
    run: (ctx, ed, a) async {
      final list = ObjectOps.targets(ed, a.values);
      if (list.isEmpty) return CommandResult.failed(_missing(ed)!);
      final clip = ObjectOps.copy(ed, list);
      ed.clipMark.value = null;
      await ed.clipboard.system.write(
        SystemClipboardData(plainText: clip.marker),
      );
      await _writePng(ed, list, clip.marker);
      return ok({'count': list.length});
    },
  ),
  SheetsCommand(
    'sheets.object.cut',
    label: (l) => l.cmdObjectCut,
    icon: LucideIcons.scissors,
    categoryName: _cat,
    mutates: true,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('X', mod: true)],
    argsSchema: _objectIdsSchema,
    enabled: (ed, a) {
      final list = ObjectOps.targets(ed, a.values);
      return list.isNotEmpty && !list.any((o) => _onChartSheet(ed, o));
    },
    run: (ctx, ed, a) async {
      final list = ObjectOps.targets(ed, a.values);
      if (list.isEmpty) return CommandResult.failed(_missing(ed)!);
      final clip = ObjectOps.copy(ed, list);
      await ed.clipboard.system.write(
        SystemClipboardData(plainText: clip.marker),
      );
      await _writePng(ed, list, clip.marker);
      for (final o in list) {
        ed.apply(ctx, DeleteObject(o.id));
      }
      _objs(ed).select(null);
      return ok({'count': list.length});
    },
  ),
  SheetsCommand(
    'sheets.object.paste',
    label: (l) => l.cmdObjectPaste,
    icon: LucideIcons.clipboardPaste,
    categoryName: _cat,
    mutates: true,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('V', mod: true)],
    // In the grid, Mod+V pastes objects only while the object copy is the
    // newest copy (a later cell copy wins).
    argBindings: const [
      ArgsKeyBinding(KeyBinding('V', mod: true), {}, scope: KeyScope.grid),
    ],
    enabled: (ed, a) {
      final clip = ObjectOps.clip;
      if (clip == null || ed.activeSheet?.record?.kind == SheetKind.chart) {
        return false;
      }
      return identical(clip.cellClipAtCopy, ed.clipboard.last);
    },
    run: (ctx, ed, a) async {
      final clip = ObjectOps.clip;
      if (clip == null) return const CommandResult.cancelled();
      // Another app may have put something newer on the system clipboard.
      final sys = await ed.clipboard.system.read();
      final text = sys?.plainText;
      if (text != null && text.isNotEmpty && text != clip.marker) {
        return ed.services.dispatcher.invoke(
          'sheets.edit.paste',
          source: ctx.source,
          context: ctx.buildContext,
        );
      }
      final sheet = ed.activeSheet!;
      final sel = ed.selection.resolved;
      final ids = <String>[];
      var i = 0;
      for (final item in clip.items) {
        final kind =
            EmbeddedObjectKind.values.asNameMap()[item['kind']] ??
            EmbeddedObjectKind.chart;
        final copied =
            ObjectAnchor.tryParse(item['anchor']) ?? const ObjectAnchor();
        var anchor = ObjectPlacement.pasteAnchor(
          row: sel.activeRow,
          col: sel.activeCol,
          copied: copied,
          rows: sheet.rows,
          columns: sheet.columns,
        );
        if (i > 0) {
          final r = anchor.rectIn(sheet.rows, sheet.columns)!;
          anchor = ObjectOps.anchorAt(
            sheet,
            r.left + i * ObjectAnchor.duplicateOffset,
            r.top + i * ObjectAnchor.duplicateOffset,
            width: anchor.width,
            height: anchor.height,
            base: anchor,
          );
        }
        final spec = ObjectOps.resolveSpec(ed, item);
        final plan = ed.apply(
          ctx,
          AddObject(
            sheet.id,
            kind,
            anchorJson: anchor.encode(),
            specJson: jsonEncode(spec),
            altText: item['altText'] as String?,
          ),
        );
        ids.add(plan.result['objectId']! as String);
        i++;
      }
      if (ids.isNotEmpty) _objs(ed).select(ids.last);
      return ok({'objectIds': ids});
    },
  ),
  SheetsCommand(
    'sheets.object.editAltText',
    label: (l) => l.cmdObjectEditAltText,
    categoryName: _cat,
    mutates: true,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('Enter')],
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': JsonSchema.string(),
        'title': JsonSchema.string(),
        'description': JsonSchema.string(),
      },
    ),
    undoLabelOf: (l, a) => l.undoEditAltText,
    enabled: (ed, a) => _hasTarget(ed, a),
    run: (ctx, ed, a) async {
      final o = ObjectOps.target(ed, a.values);
      if (o == null) return CommandResult.failed(_missing(ed)!);
      var title = a.string('title');
      var description = a.string('description');
      if (title == null && description == null) {
        final c = ctx.dialogContext;
        if (c == null) return const CommandResult.cancelled();
        final auto = o.kind == EmbeddedObjectKind.chart
            ? _objs(ed).chartOf(o).autoDescription
            : null;
        final r = await showAltTextDialog(
          c,
          title: o.title ?? '',
          description: o.altText ?? '',
          placeholder: auto,
        );
        if (r == null) return const CommandResult.cancelled();
        (title, description) = r;
      }
      await ed.applyConfirmed(
        ctx,
        UpdateObject(
          o.id,
          title: title?.trim().isEmpty ?? true ? null : title!.trim(),
          altText: description ?? o.altText ?? '',
        ),
      );
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.object.list',
    label: (l) => l.cmdObjectList,
    categoryName: _cat,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'sheetId': JsonSchema.string()},
    ),
    run: (ctx, ed, a) {
      final objs = _objs(ed);
      final sid = a.string('sheetId');
      return ok({
        'objects': [
          for (final s in ed.model.sheets)
            if (sid == null || s.id == sid)
              for (final o in objs.objectsOn(s.id)) _describe(ed, objs, s, o),
        ],
      });
    },
  ),
];

Map<String, Object?> _describe(
  SheetEditorController ed,
  ObjectsController objs,
  SheetModel s,
  EmbeddedObjectRecord o,
) {
  final cell = objs.anchorCell(o);
  final a = objs.anchorOf(o);
  final m = <String, Object?>{
    'id': o.id,
    'kind': o.kind.name,
    'title': o.title,
    'sheet': s.name,
    'anchorCell': cell == null ? null : CellPos(cell.$1, cell.$2).a1,
    'width': a?.width,
    'height': a?.height,
    'zIndex': o.zIndex,
    'altText': o.altText,
  };
  if (o.kind == EmbeddedObjectKind.chart) {
    final spec = ChartSpec.fromJson(o.specJson);
    m['type'] = spec.typeId;
    m['ranges'] = [
      for (final g in spec.data.gridRanges)
        if (ed.model.sheet(g.sheetId)?.resolve(g) case final rr?)
          ed.model.a1Of(rr),
    ];
  }
  return m;
}

double _num(Object? v) => v is num ? v.toDouble() : 0;

/// Adds a PNG of the primary copied object to the system clipboard next to
/// the paste marker, so other apps paste a picture (08 §9.5).
Future<void> _writePng(
  SheetEditorController ed,
  List<EmbeddedObjectRecord> list,
  String marker,
) async {
  final clipboard = ImageClipboard.instance;
  if (!clipboard.supported || list.isEmpty) return;
  try {
    final png = await ObjectPng.of(ed, list.last);
    if (png != null) await clipboard.writePng(png, text: marker);
  } catch (e) {
    debugPrint('Copying the object as PNG failed: $e');
  }
}

/// The z-order writes of `op` in [a] for [id].
Map<String, int> _zChanges(List<ZOrderItem> items, String id, JsonArgs a) =>
    switch (a.string('op')) {
      'front' => ZOrder.bringToFront(items, id),
      'forward' => ZOrder.bringForward(items, id),
      'backward' => ZOrder.sendBackward(items, id),
      'back' => ZOrder.sendToBack(items, id),
      _ => const {},
    };

/// [o]'s anchor moved by ([dx], [dy]) sheet px (normalized), or null.
ObjectAnchor? _anchorBy(
  SheetEditorController ed,
  EmbeddedObjectRecord o,
  double dx,
  double dy,
) {
  final objs = ObjectsController.of(ed);
  final sheet = ed.model.sheet(o.sheetId);
  final base = objs.anchorOf(o);
  final rect = objs.rectOf(o, ghost: false);
  if (sheet == null || base == null || rect == null) return null;
  return ObjectOps.anchorAt(
    sheet,
    rect.left + dx,
    rect.top + dy,
    width: base.width,
    height: base.height,
    base: base,
  );
}

/// [o]'s anchor moved by whole visible cells (Alt+arrows, 08 §9.3).
ObjectAnchor? _anchorByCells(
  SheetEditorController ed,
  EmbeddedObjectRecord o,
  double dx,
  double dy,
) {
  final objs = ObjectsController.of(ed);
  final sheet = ed.model.sheet(o.sheetId);
  final base = objs.anchorOf(o);
  final rect = objs.rectOf(o, ghost: false);
  final cell = objs.anchorCell(o);
  if (sheet == null || base == null || rect == null || cell == null) {
    return null;
  }
  final cols = sheet.columns;
  final rows = sheet.rows;
  var x = rect.left;
  var y = rect.top;
  if (dx != 0) {
    final c = dx > 0
        ? (cols.nextVisible(cell.$2 + 1, 1) ?? cell.$2)
        : (cell.$2 > 0 ? (cols.nextVisible(cell.$2 - 1, -1) ?? 0) : 0);
    x = cols.offsetOf(c);
  }
  if (dy != 0) {
    final r = dy > 0
        ? (rows.nextVisible(cell.$1 + 1, 1) ?? cell.$1)
        : (cell.$1 > 0 ? (rows.nextVisible(cell.$1 - 1, -1) ?? 0) : 0);
    y = rows.offsetOf(r);
  }
  return ObjectOps.anchorAt(
    sheet,
    x,
    y,
    width: base.width,
    height: base.height,
    base: base,
  );
}
