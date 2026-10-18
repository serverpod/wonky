import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/clipboard.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../config/menus/slides_menu_spec.dart' show slideGroupColors;
import '../features/clipboard/deck_clipboard.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/navigator/navigator_clipboard.dart';
import '../features/navigator/navigator_controller.dart';
import '../features/navigator/navigator_dialogs.dart';
import '../features/navigator/navigator_model.dart';
import '../l10n/slides_l10n.dart' show slidesL10nOf;
import 'slides_command.dart';

/// The slide navigator's commands (Slides 04 §5, SL-16): slides (new,
/// duplicate, delete, skip, move), slide groups (create, rename, color,
/// skip, move, duplicate, delete, ungroup, add/remove slides), collapse
/// state (view state, not undoable), the navigator clipboard and Select
/// all, and the speaker notes zoom.
///
/// Without explicit ids they act on the **navigator selection** (04 §5.5):
/// selected groups as groups (with their slides) and the loose slides.
/// Every mutating command is one undo step (`DeckEditorController.apply`
/// per operation inside the command's transaction); moves write `groupId`
/// + `sortKey` together (02 P4).
List<Command<CommandArgs>> navigatorCommands(ShellServices s) => [
  // ---- Slides (04 §5.7)
  SlidesCommand(
    'slides.slide.new',
    label: (l) => l.cmdSlideNew,
    icon: LucideIcons.plus,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    defaultBindings: const [KeyBinding('M', ctrl: true)],
    argsSchema: const JsonSchema.object(
      properties: {
        'layoutId': JsonSchema.string(description: 'Layout of the slide.'),
        'after': JsonSchema.string(
          description: 'Insert after this slide (in its group).',
        ),
        'inGroup': JsonSchema.boolean(
          description: 'At the end of the selected (or current) group.',
        ),
        'groupId': JsonSchema.string(description: 'At the end of this group.'),
      },
    ),
    run: (ctx, ed, a) {
      final nav = navigatorOf(ed);
      final layoutId = a.string('layoutId');
      final after = a.string('after');
      AddSlides op;
      final inGroup = a.string('groupId');
      if (after != null) {
        op = AddSlides(layoutId: layoutId, afterSlideId: after);
      } else if (inGroup != null) {
        op = AddSlides(layoutId: layoutId, target: InGroup(inGroup));
      } else if (a.boolean('inGroup') ?? false) {
        final g = _targetGroups(ed, const JsonArgs()).firstOrNull;
        if (g == null) return const CommandResult.failed('No group');
        op = AddSlides(layoutId: layoutId, target: InGroup(g));
      } else if (nav.insertion != null) {
        op = AddSlides(layoutId: layoutId, target: nav.insertion);
      } else if (ed.currentSlideId != null) {
        op = AddSlides(layoutId: layoutId, afterSlideId: ed.currentSlideId);
      } else {
        op = AddSlides(layoutId: layoutId, target: const TopLevel());
      }
      final plan = ed.apply(ctx, op);
      nav.clearInsertion();
      final ids = (plan.result['slideIds'] as List?)?.cast<String>() ?? [];
      if (ids.isNotEmpty) {
        ed.setCurrentSlide(ids.first);
        // The title placeholder is selected (04 §5.7).
        for (final e in ed.model.elementsOf(ids.first)) {
          if (e.placeholderType == SlidePlaceholderType.title) {
            ed.selectElements([e.id]);
            break;
          }
        }
      }
      return ok({'slideIds': ids});
    },
  ),
  SlidesCommand(
    'slides.slide.duplicate',
    label: (l) => l.cmdSlideDuplicate,
    dynamicLabel: (l, ed) =>
        l.cmdSlideDuplicateCount(_selection(ed).allSlideIds(ed.order).length),
    icon: LucideIcons.copyPlus,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argBindings: const [
      ArgsKeyBinding(
        KeyBinding('D', mod: true),
        {},
        scope: SlidesKeyScopes.navigator,
      ),
    ],
    argsSchema: _slideIdsSchema,
    enabled: (ed, a) => !_selectionOf(ed, a).isEmpty && !_inTextField(),
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) {
      final sel = _selectionOf(ed, a);
      final newGroups = <String>[];
      final newSlides = <String>[];
      if (sel.groupIds.isNotEmpty) {
        final plan = ed.apply(ctx, DuplicateGroups(sel.groupIds));
        newGroups.addAll(
          (plan.result['groupIds'] as List?)?.cast<String>() ?? [],
        );
      }
      if (sel.slideIds.isNotEmpty) {
        final plan = ed.apply(ctx, DuplicateSlides(sel.slideIds));
        newSlides.addAll(
          (plan.result['slideIds'] as List?)?.cast<String>() ?? [],
        );
      }
      _selectNew(ed, groups: newGroups, slides: newSlides);
      return ok({'groupIds': newGroups, 'slideIds': newSlides});
    },
  ),
  SlidesCommand(
    'slides.slide.delete',
    label: (l) => l.cmdSlideDelete,
    dynamicLabel: (l, ed) =>
        l.cmdSlideDeleteCount(_selection(ed).allSlideIds(ed.order).length),
    icon: LucideIcons.trash2,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argBindings: const [
      ArgsKeyBinding(
        KeyBinding('Backspace'),
        {},
        scope: SlidesKeyScopes.navigator,
      ),
      ArgsKeyBinding(
        KeyBinding('Delete'),
        {},
        scope: SlidesKeyScopes.navigator,
      ),
    ],
    argsSchema: _slideIdsSchema,
    enabled: (ed, a) => !_selectionOf(ed, a).isEmpty && !_inTextField(),
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) async {
      final sel = _selectionOf(ed, a);
      final nonEmpty = [
        for (final g in sel.groupIds)
          if ((ed.order.range(g)?.length ?? 0) > 0) g,
      ];
      var withSlides = true;
      if (nonEmpty.isNotEmpty && !ctx.source.isAgent) {
        final dc = ctx.dialogContext;
        if (dc == null || !dc.mounted) {
          return const CommandResult.cancelled();
        }
        final choice = await showDeleteGroupDialog(dc, ed, sel.groupIds);
        if (choice == DeleteGroupChoice.cancel) {
          return const CommandResult.cancelled();
        }
        withSlides = choice == DeleteGroupChoice.withSlides;
      }
      if (sel.groupIds.isNotEmpty) {
        ed.apply(ctx, DeleteGroups(sel.groupIds, withSlides: withSlides));
      }
      if (sel.slideIds.isNotEmpty) {
        ed.apply(ctx, DeleteSlides(sel.slideIds));
      }
      if (sel.groupIds.isNotEmpty) _toastGroupDeleted(ctx);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.slide.toggleSkip',
    label: (l) => l.cmdSlideToggleSkip,
    icon: LucideIcons.eyeOff,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'slideIds': _ids,
        'skipped': JsonSchema.boolean(
          description: 'Skip (true) or show (false); omitted = toggle.',
        ),
      },
    ),
    enabled: (ed, a) => _skipTargets(ed, a).$3,
    reason: (l, ed) => _selection(ed).isEmpty
        ? l.reasonSelectSlides
        : l.reasonSkippedWithGroup,
    checked: (ed, a) => _skipTargets(ed, a).$4,
    run: (ctx, ed, a) {
      final (groups, slides, enabled, allSkipped) = _skipTargets(ed, a);
      if (!enabled) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).reasonSkippedWithGroup,
        );
      }
      final v = a.boolean('skipped') ?? !allSkipped;
      if (groups.isNotEmpty) {
        ed.apply(ctx, SetGroupProps(groups, skipped: v));
      }
      if (slides.isNotEmpty) {
        ed.apply(ctx, SetSlideProps(slides, skipped: v));
      }
      return ok({'skipped': v});
    },
  ),
  SlidesCommand(
    'slides.slide.move',
    label: (l) => l.cmdSlideMove,
    icon: LucideIcons.arrowUpDown,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argBindings: const [
      ArgsKeyBinding(KeyBinding('ArrowUp', mod: true), {
        'to': 'up',
      }, scope: SlidesKeyScopes.navigator),
      ArgsKeyBinding(KeyBinding('ArrowDown', mod: true), {
        'to': 'down',
      }, scope: SlidesKeyScopes.navigator),
      ArgsKeyBinding(KeyBinding('ArrowLeft', mod: true), {
        'to': 'up',
      }, scope: SlidesKeyScopes.navigator),
      ArgsKeyBinding(KeyBinding('ArrowRight', mod: true), {
        'to': 'down',
      }, scope: SlidesKeyScopes.navigator),
      ArgsKeyBinding(KeyBinding('ArrowUp', mod: true, shift: true), {
        'to': 'start',
      }, scope: SlidesKeyScopes.navigator),
      ArgsKeyBinding(KeyBinding('ArrowDown', mod: true, shift: true), {
        'to': 'end',
      }, scope: SlidesKeyScopes.navigator),
    ],
    argsSchema: const JsonSchema.object(
      properties: {
        'slideIds': _ids,
        'groupIds': _ids,
        'to': _to,
        'copy': JsonSchema.boolean(
          description: 'Copy instead of moving (Alt-drag, 04 §5.10).',
        ),
      },
      required: ['to'],
    ),
    undoLabelOf: (l, a) =>
        a.boolean('copy') ?? false ? l.cmdNavigatorCopy : l.cmdSlideMove,
    enabled: (ed, a) => _moveOps(ed, a, groupsOnly: false) != null,
    reason: (l, ed) =>
        _selection(ed).isEmpty ? l.reasonSelectSlides : l.reasonCantMoveFurther,
    run: (ctx, ed, a) => _runMove(ctx, ed, a, groupsOnly: false),
  ),

  // ---- Groups (04 §5.4–§5.7, §5.13)
  SlidesCommand(
    'slides.group.create',
    label: (l) => l.cmdGroupCreate,
    icon: LucideIcons.group,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    defaultBindings: const [KeyBinding('G', mod: true)],
    keyScope: SlidesKeyScopes.navigator,
    argsSchema: const JsonSchema.object(
      properties: {
        'slideIds': JsonSchema.array(
          JsonSchema.string(),
          description:
              'Slides to group (default: the selection; [] = an '
              'empty group at the end).',
        ),
        'title': JsonSchema.string(minLength: 1),
        'color': JsonSchema.string(enumValues: slideGroupColors),
      },
    ),
    enabled: (ed, a) => _createState(ed, a) == null,
    reason: (l, ed) => _createState(ed, const JsonArgs()) == 'already'
        ? l.reasonAlreadyGroup
        : l.reasonSelectSlides,
    run: (ctx, ed, a) {
      final explicit = a.values.containsKey('slideIds');
      final ids = explicit ? a.strings('slideIds') : _selectedSlides(ed);
      if (ids.isEmpty && !explicit) {
        return CommandResult.failed(slidesL10nOf(ed.services).errorSelectSlide);
      }
      final order = ed.order;
      SlideTarget? target;
      String? prevGroup;
      if (ids.isEmpty) {
        target = const TopLevel();
        prevGroup = order.groups.lastOrNull?.group.id;
      } else {
        final first = order.entry(
          order.entries.firstWhere((e) => ids.contains(e.id)).id,
        )!;
        final g = first.groupId;
        if (g != null) {
          // Inside group G: the new group goes right after G (one level).
          target = TopLevel(afterId: g);
          prevGroup = g;
        } else {
          prevGroup = _groupBefore(order, first.id);
        }
      }
      final plan = ed.apply(
        ctx,
        CreateGroup(
          ids,
          title: a.string('title'),
          color: a.string('color') ?? _nextColor(ed.model, prevGroup),
          target: target,
        ),
      );
      final groupId = plan.result['groupId']! as String;
      final nav = navigatorOf(ed);
      nav.setCollapsed([groupId], false);
      nav.selectGroups([groupId]);
      // The inline rename field opens (typing renames; Esc keeps the
      // default title).
      if (!ctx.source.isAgent && a.string('title') == null) {
        nav.startRename(groupId);
      }
      return ok({'groupId': groupId});
    },
  ),
  SlidesCommand(
    'slides.group.rename',
    label: (l) => l.cmdGroupRename,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'groupId': JsonSchema.string(),
        'title': JsonSchema.string(minLength: 1, maxLength: 100),
      },
      required: ['groupId', 'title'],
    ),
    run: (ctx, ed, a) {
      final id = a.requireString('groupId');
      final title = a.requireString('title');
      if (ed.model.group(id)?.title == title.trim()) return ok();
      ed.apply(ctx, SetGroupProps([id], title: title));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.group.startRename',
    label: (l) => l.cmdGroupStartRename,
    icon: LucideIcons.pencil,
    categoryOf: SlidesCategory.slides,
    defaultBindings: const [KeyBinding('F2')],
    keyScope: SlidesKeyScopes.navigator,
    argsSchema: _groupIdSchema,
    enabled: (ed, a) => ed.canEdit && _targetGroups(ed, a).isNotEmpty,
    reason: (l, ed) => ed.canEdit ? l.reasonSelectGroup : _editReason(l, ed),
    run: (ctx, ed, a) {
      final g = _targetGroups(ed, a).firstOrNull;
      if (g == null) return const CommandResult.failed('No group');
      if (ed.mode == DeckViewMode.normal) ed.setNavigatorVisible(true);
      navigatorOf(ed).startRename(g);
      return ok({'groupId': g});
    },
  ),
  SlidesCommand(
    'slides.group.setColor',
    label: (l) => l.cmdGroupSetColor,
    icon: LucideIcons.palette,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: JsonSchema.object(
      properties: {
        'groupIds': _ids,
        'color': JsonSchema.nullable(
          JsonSchema.string(enumValues: slideGroupColors),
        ),
      },
    ),
    enabled: (ed, a) => _targetGroups(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectGroup,
    checked: (ed, a) {
      final groups = _targetGroups(ed, a);
      if (groups.isEmpty) return null;
      final c = a.string('color');
      return groups.every((g) => ed.model.group(g)?.color == c);
    },
    run: (ctx, ed, a) {
      final groups = _targetGroups(ed, a);
      final color = a.string('color');
      if (color != null && !slideGroupColors.contains(color)) {
        return const CommandResult.failed('Unknown group color');
      }
      ed.apply(ctx, SetGroupProps(groups, color: Patch(color)));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.group.toggleSkip',
    label: (l) => l.cmdGroupToggleSkip,
    icon: LucideIcons.eyeOff,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'groupIds': _ids, 'skipped': JsonSchema.boolean()},
    ),
    enabled: (ed, a) => _targetGroups(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectGroup,
    checked: (ed, a) {
      final groups = _targetGroups(ed, a);
      if (groups.isEmpty) return null;
      return groups.every((g) => ed.model.group(g)?.skipped ?? false);
    },
    run: (ctx, ed, a) {
      final groups = _targetGroups(ed, a);
      final all = groups.every((g) => ed.model.group(g)?.skipped ?? false);
      final v = a.boolean('skipped') ?? !all;
      ed.apply(ctx, SetGroupProps(groups, skipped: v));
      return ok({'skipped': v});
    },
  ),
  SlidesCommand(
    'slides.group.move',
    label: (l) => l.cmdGroupMove,
    icon: LucideIcons.arrowUpDown,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'groupIds': _ids, 'to': _to},
      required: ['to'],
    ),
    enabled: (ed, a) => _moveOps(ed, a, groupsOnly: true) != null,
    reason: (l, ed) => l.reasonSelectGroup,
    run: (ctx, ed, a) => _runMove(ctx, ed, a, groupsOnly: true),
  ),
  SlidesCommand(
    'slides.group.duplicate',
    label: (l) => l.cmdGroupDuplicate,
    icon: LucideIcons.copyPlus,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: _groupIdsSchema,
    enabled: (ed, a) => _targetGroups(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectGroup,
    run: (ctx, ed, a) {
      final plan = ed.apply(ctx, DuplicateGroups(_targetGroups(ed, a)));
      final ids = (plan.result['groupIds'] as List?)?.cast<String>() ?? [];
      _selectNew(ed, groups: ids);
      return ok({'groupIds': ids});
    },
  ),
  SlidesCommand(
    'slides.group.delete',
    label: (l) => l.cmdGroupDelete,
    icon: LucideIcons.trash2,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'groupIds': _ids,
        'withSlides': JsonSchema.boolean(
          description:
              'Delete the slides too (default false: ungroup '
              'them in place).',
        ),
      },
    ),
    enabled: (ed, a) => _targetGroups(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectGroup,
    run: (ctx, ed, a) async {
      final groups = _targetGroups(ed, a);
      var withSlides = a.boolean('withSlides');
      final nonEmpty = groups.any((g) => (ed.order.range(g)?.length ?? 0) > 0);
      if (withSlides == null && nonEmpty && !ctx.source.isAgent) {
        final dc = ctx.dialogContext;
        if (dc == null || !dc.mounted) return const CommandResult.cancelled();
        final choice = await showDeleteGroupDialog(dc, ed, groups);
        if (choice == DeleteGroupChoice.cancel) {
          return const CommandResult.cancelled();
        }
        withSlides = choice == DeleteGroupChoice.withSlides;
      }
      ed.apply(ctx, DeleteGroups(groups, withSlides: withSlides ?? false));
      _toastGroupDeleted(ctx);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.group.ungroup',
    label: (l) => l.cmdGroupUngroup,
    icon: LucideIcons.ungroup,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    defaultBindings: const [KeyBinding('G', mod: true, shift: true)],
    keyScope: SlidesKeyScopes.navigator,
    argsSchema: _groupIdsSchema,
    enabled: (ed, a) => _targetGroups(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonNotInGroup,
    run: (ctx, ed, a) {
      final groups = _targetGroups(ed, a);
      final slides = [
        for (final g in groups)
          for (final id in _members(ed.order, g)) id,
      ];
      for (final g in groups) {
        ed.apply(ctx, Ungroup(g));
      }
      if (slides.isNotEmpty) {
        final cur = ed.currentSlideId;
        ed.selectSlides(slides);
        if (cur != null && slides.contains(cur)) {
          ed.setCurrentSlide(cur, select: false);
        }
      }
      return ok();
    },
  ),
  SlidesCommand(
    'slides.group.addSlides',
    label: (l) => l.cmdGroupAddSlides,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'groupId': JsonSchema.string(
          description: 'The group (omit to choose in a dialog).',
        ),
        'slideIds': _ids,
      },
    ),
    enabled: (ed, a) =>
        ed.order.groups.isNotEmpty &&
        (a.values.containsKey('slideIds') || _selectedSlides(ed).isNotEmpty),
    reason: (l, ed) =>
        ed.order.groups.isEmpty ? l.reasonNoGroups : l.reasonSelectSlides,
    run: (ctx, ed, a) async {
      var g = a.string('groupId');
      if (g == null) {
        final dc = ctx.dialogContext;
        if (dc == null || !dc.mounted || ctx.source.isAgent) {
          return const CommandResult.failed('groupId is required');
        }
        g = await showChooseGroupDialog(dc, ed);
        if (g == null) return const CommandResult.cancelled();
      }
      if (ed.order.range(g) == null) {
        return const CommandResult.failed('No such group');
      }
      final ids = a.values.containsKey('slideIds')
          ? a.strings('slideIds')
          : _selectedSlides(ed);
      final ordered = [
        for (final e in ed.order.entries)
          if (ids.contains(e.id)) e.id,
      ];
      if (ordered.isEmpty) return ok();
      ed.apply(ctx, MoveSlides(ordered, InGroup(g)));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.group.removeSlides',
    label: (l) => l.cmdGroupRemoveSlides,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: _slideIdsSchema,
    enabled: (ed, a) => _removable(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonNotInGroup,
    run: (ctx, ed, a) {
      final byGroup = _removable(ed, a);
      // Out to the top level right after their group, keeping order.
      for (final MapEntry(key: g, value: ids) in byGroup.entries) {
        ed.apply(ctx, MoveSlides(ids, TopLevel(afterId: g)));
      }
      return ok();
    },
  ),
  SlidesCommand(
    'slides.group.selectSlides',
    label: (l) => l.cmdGroupSelectSlides,
    categoryOf: SlidesCategory.slides,
    argsSchema: _groupIdSchema,
    enabled: (ed, a) =>
        _targetGroups(ed, a).any((g) => (ed.order.range(g)?.length ?? 0) > 0),
    reason: (l, ed) => l.reasonSelectGroup,
    run: (ctx, ed, a) {
      final slides = [
        for (final g in _targetGroups(ed, a)) ..._members(ed.order, g),
      ];
      final cur = ed.currentSlideId;
      ed.selectSlides(slides);
      if (cur != null && !slides.contains(cur) && slides.isNotEmpty) {
        ed.setCurrentSlide(slides.first, select: false);
      }
      return ok({'slideIds': slides});
    },
  ),

  // ---- Collapse state (view state per user and device, 04 §5.4)
  _collapse(
    'slides.group.collapse',
    (l) => l.cmdGroupCollapse,
    LucideIcons.chevronRight,
    collapse: true,
  ),
  _collapse(
    'slides.group.expand',
    (l) => l.cmdGroupExpand,
    LucideIcons.chevronDown,
    collapse: false,
  ),
  SlidesCommand(
    'slides.group.toggleCollapsed',
    label: (l) => l.cmdGroupToggleCollapsed,
    categoryOf: SlidesCategory.slides,
    showInPalette: false,
    argsSchema: _groupIdsSchema,
    enabled: (ed, a) => _targetGroups(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectGroup,
    run: (ctx, ed, a) {
      final nav = navigatorOf(ed);
      final groups = _targetGroups(ed, a);
      final collapse = !groups.every(nav.isCollapsed);
      nav.setCollapsed(groups, collapse);
      return ok({'collapsed': collapse});
    },
  ),
  _collapseAll(
    'slides.group.collapseAll',
    (l) => l.cmdGroupCollapseAll,
    collapse: true,
    binding: const KeyBinding('[', mod: true, alt: true),
  ),
  _collapseAll(
    'slides.group.expandAll',
    (l) => l.cmdGroupExpandAll,
    collapse: false,
    binding: const KeyBinding(']', mod: true, alt: true),
  ),

  // ---- Navigator selection and clipboard (04 §5.8, §5.9)
  SlidesCommand(
    'slides.nav.selectAllSlides',
    label: (l) => l.cmdNavSelectAllSlides,
    categoryOf: SlidesCategory.slides,
    argBindings: const [
      ArgsKeyBinding(
        KeyBinding('A', mod: true),
        {},
        scope: SlidesKeyScopes.navigator,
      ),
    ],
    enabled: (ed, a) => ed.order.length > 0 && !_inTextField(),
    reason: (l, ed) => l.reasonNoSlides,
    run: (ctx, ed, a) {
      navigatorOf(ed).selectAll();
      return ok();
    },
  ),
  SlidesCommand(
    'slides.navigator.copy',
    label: (l) => l.cmdNavigatorCopy,
    icon: LucideIcons.copy,
    categoryOf: SlidesCategory.edit,
    showInPalette: false,
    argBindings: const [
      ArgsKeyBinding(
        KeyBinding('C', mod: true),
        {},
        scope: SlidesKeyScopes.navigator,
      ),
    ],
    argsSchema: _selectionSchema,
    enabled: (ed, a) => !_selectionOf(ed, a).isEmpty && !_inTextField(),
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) async {
      final sel = _selectionOf(ed, a);
      await _copy(ed, sel);
      return ok({
        'groupIds': sel.groupIds,
        'slideIds': sel.allSlideIds(ed.order),
      });
    },
  ),
  SlidesCommand(
    'slides.navigator.cut',
    label: (l) => l.cmdNavigatorCut,
    icon: LucideIcons.scissors,
    categoryOf: SlidesCategory.edit,
    showInPalette: false,
    mutates: true,
    argBindings: const [
      ArgsKeyBinding(
        KeyBinding('X', mod: true),
        {},
        scope: SlidesKeyScopes.navigator,
      ),
    ],
    argsSchema: _selectionSchema,
    enabled: (ed, a) => !_selectionOf(ed, a).isEmpty && !_inTextField(),
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) async {
      final sel = _selectionOf(ed, a);
      await _copy(ed, sel);
      if (sel.groupIds.isNotEmpty) {
        ed.apply(ctx, DeleteGroups(sel.groupIds, withSlides: true));
      }
      if (sel.slideIds.isNotEmpty) ed.apply(ctx, DeleteSlides(sel.slideIds));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.navigator.paste',
    label: (l) => l.cmdNavigatorPaste,
    icon: LucideIcons.clipboardPaste,
    categoryOf: SlidesCategory.edit,
    showInPalette: false,
    mutates: true,
    argBindings: const [
      ArgsKeyBinding(
        KeyBinding('V', mod: true),
        {},
        scope: SlidesKeyScopes.navigator,
      ),
    ],
    argsSchema: const JsonSchema.object(
      properties: {
        'afterSlideId': JsonSchema.string(
          description:
              'Paste after this slide (default: the insertion '
              'point, else after the selection).',
        ),
        'themeMode': JsonSchema.string(
          enumValues: ['useDestination', 'keepSource'],
        ),
      },
    ),
    enabled: (ed, a) => SlidesSlideClipboard.hasSlides && !_inTextField(),
    reason: (l, ed) => l.reasonClipboardNoSlides,
    run: (ctx, ed, a) async {
      final payload = await SlidesSlideClipboard.read(ed.services.userStore);
      final kind = payload?['kind'];
      if (payload == null ||
          (kind != SlidesClipboardCodec.kindSlides &&
              kind != SlidesClipboardCodec.kindGroups)) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).errorClipboardNoSlides,
        );
      }
      final nav = navigatorOf(ed);
      final after = a.string('afterSlideId');
      final target = after != null ? null : (nav.insertion ?? _pasteTarget(ed));
      final keep = a.string('themeMode') == 'keepSource';
      // Files of another deck are re-homed into this one (SL-18, 03 §12.3).
      final prepared = DeckClipboard.isCrossDeck(ed, payload)
          ? await DeckClipboard.prepareFiles(
              ctx,
              ed,
              SlidesSlideClipboard.copyOf(payload),
            )
          : SlidesSlideClipboard.copyOf(payload);
      if (prepared == null) return const CommandResult.cancelled();
      final plan = ed.apply(
        ctx,
        PasteSlides(
          prepared,
          target: target,
          afterSlideId: after,
          themeMode: keep
              ? PasteThemeMode.keepSource
              : PasteThemeMode.useDestination,
        ),
      );
      DeckClipboard.afterSlidesPaste(
        ctx,
        ed,
        payload,
        keep ? 'keepSource' : 'useDestination',
      );
      nav.clearInsertion();
      final slides = (plan.result['slideIds'] as List?)?.cast<String>() ?? [];
      final groups = (plan.result['groupIds'] as List?)?.cast<String>() ?? [];
      // Pasted groups arrive expanded (04 §5.8).
      nav.setCollapsed(groups, false);
      _selectNew(ed, groups: groups, slides: slides);
      return ok({'slideIds': slides, 'groupIds': groups});
    },
  ),

  // ---- Speaker notes (04 §8)
  SlidesCommand(
    'slides.notes.zoom',
    label: (l) => l.cmdNotesZoom,
    icon: LucideIcons.zoomIn,
    categoryOf: SlidesCategory.view,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'percent': JsonSchema.integer(minimum: 75, maximum: 200)},
      required: ['percent'],
    ),
    checked: (ed, a) => notesZoomOf(ed).value == a.integer('percent'),
    run: (ctx, ed, a) {
      final p = a.integer('percent');
      if (p == null) return const CommandResult.failed('percent is required');
      setNotesZoom(ed, p);
      return ok();
    },
  ),
];

// ---------------------------------------------------------------- notes zoom

final Expando<ValueNotifier<int>> _notesZoom = Expando('slidesNotesZoom');

/// The speaker notes font zoom in percent (75–200, 04 §8, P1; device pref
/// `slides.notes.zoom`).
ValueNotifier<int> notesZoomOf(DeckEditorController ed) =>
    _notesZoom[ed] ??= _loadNotesZoom(ed);

ValueNotifier<int> _loadNotesZoom(DeckEditorController ed) {
  final v = ValueNotifier<int>(100);
  ed.services.userStore
      .read(_notesZoomKey)
      .then((raw) {
        if (raw is int) v.value = raw.clamp(75, 200);
      })
      .catchError((Object _) {});
  return v;
}

const _notesZoomKey = 'slides.notes.zoom';

void setNotesZoom(DeckEditorController ed, int percent) {
  final p = percent.clamp(75, 200);
  notesZoomOf(ed).value = p;
  ed.services.userStore.write(_notesZoomKey, p).catchError((Object _) {});
}

// ------------------------------------------------------------------ helpers

const JsonSchema _ids = JsonSchema.array(JsonSchema.string());

/// `to` of the move commands (04 §5.7).
const JsonSchema _to = JsonSchema.anyOf(
  [
    JsonSchema.string(enumValues: ['start', 'up', 'down', 'end']),
    JsonSchema.object(
      properties: {
        'beforeId': JsonSchema.string(),
        'afterId': JsonSchema.string(),
        'groupId': JsonSchema.string(),
        'index': JsonSchema.integer(minimum: 0),
      },
    ),
  ],
  description:
      'start | up | down | end | {beforeId} | {afterId} | '
      '{groupId, index}',
);

const JsonSchema _slideIdsSchema = JsonSchema.object(
  properties: {'slideIds': _ids},
);

const JsonSchema _groupIdsSchema = JsonSchema.object(
  properties: {'groupIds': _ids},
);

const JsonSchema _groupIdSchema = JsonSchema.object(
  properties: {'groupId': JsonSchema.string()},
);

const JsonSchema _selectionSchema = JsonSchema.object(
  properties: {'slideIds': _ids, 'groupIds': _ids},
);

/// The editor's navigator selection.
NavSelection _selection(DeckEditorController ed) => navigatorOf(ed).selection;

/// Explicit `slideIds` / `groupIds`, else the navigator selection.
NavSelection _selectionOf(DeckEditorController ed, JsonArgs a) {
  final hasSlides = a.values.containsKey('slideIds');
  final hasGroups = a.values.containsKey('groupIds');
  if (!hasSlides && !hasGroups) return _selection(ed);
  return NavSelection.of(
    ed.order,
    slides: a.strings('slideIds'),
    groups: a.strings('groupIds'),
  );
}

/// Every selected slide (the slides of selected groups included).
List<String> _selectedSlides(DeckEditorController ed) =>
    _selection(ed).allSlideIds(ed.order);

List<String> _members(SlideOrder order, String groupId) {
  final r = order.range(groupId);
  if (r == null) return const [];
  return [for (var i = r.start; i < r.end; i++) order.entries[i].id];
}

/// `groupIds` / `groupId`, else the selected groups, else the current
/// slide's group.
List<String> _targetGroups(DeckEditorController ed, JsonArgs a) {
  final order = ed.order;
  final explicit = a.values.containsKey('groupIds')
      ? a.strings('groupIds')
      : [?a.string('groupId')];
  if (explicit.isNotEmpty) {
    return [
      for (final id in explicit)
        if (order.range(id) != null) id,
    ];
  }
  final sel = _selection(ed).groupIds;
  if (sel.isNotEmpty) return sel;
  final g = ed.currentEntry?.groupId;
  return g == null ? const [] : [g];
}

/// Whether a plain text field has focus (scoped bindings then belong to the
/// field: rename, dialogs).
bool _inTextField() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  return ctx.widget is EditableText ||
      ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

String? _editReason(SlidesLocalizations l, DeckEditorController ed) {
  if (!ed.isReady) return l.reasonDeckLoading;
  return ed.roleCanEdit ? l.reasonViewingMode : l.reasonViewAccess;
}

/// The skip targets: (groups, slides, enabled, all skipped). Slides only
/// skipped through their group can't be toggled ("Skipped with group").
(List<String>, List<String>, bool, bool) _skipTargets(
  DeckEditorController ed,
  JsonArgs a,
) {
  final explicit = a.values.containsKey('slideIds');
  final sel = explicit
      ? NavSelection(slideIds: a.strings('slideIds'))
      : _selection(ed);
  final groups = sel.groupIds;
  final slides = <String>[];
  var anyToggleable = groups.isNotEmpty;
  var allSkipped = true;
  for (final g in groups) {
    if (!(ed.model.group(g)?.skipped ?? false)) allSkipped = false;
  }
  for (final id in sel.slideIds) {
    final e = ed.order.entry(id);
    if (e == null) continue;
    final group = e.groupId == null ? null : ed.model.group(e.groupId!);
    final viaGroup = group?.skipped ?? false;
    if (viaGroup) continue;
    slides.add(id);
    anyToggleable = true;
    if (!e.slide.skipped) allSkipped = false;
  }
  return (groups, slides, anyToggleable, anyToggleable && allSkipped);
}

/// `null` when *Group slides* is enabled, else `already` / `empty`.
String? _createState(DeckEditorController ed, JsonArgs a) {
  if (a.values.containsKey('slideIds')) return null;
  final ids = _selectedSlides(ed);
  if (ids.isEmpty) return 'empty';
  final first = ed.order.entry(ids.first)?.groupId;
  if (first != null) {
    final members = _members(ed.order, first);
    if (members.length == ids.length && members.every((m) => ids.contains(m))) {
      return 'already';
    }
  }
  return null;
}

/// The group before top-level item [id] (the "previous group" of a new
/// group's color, 04 §5.4).
String? _groupBefore(SlideOrder order, String id) {
  String? last;
  for (final t in order.topLevel) {
    if (t.id == id) break;
    if (t.isGroup) last = t.id;
  }
  return last;
}

/// The next color of the 04 §5.4 cycle after [prevGroupId]'s color (blue
/// for the first group), never the previous group's color.
String _nextColor(DeckModel model, String? prevGroupId) {
  final prev = prevGroupId == null ? null : model.group(prevGroupId)?.color;
  final i = prev == null ? -1 : slideGroupColors.indexOf(prev);
  if (i < 0) return prev == 'blue' ? 'violet' : 'blue';
  return slideGroupColors[(i + 1) % slideGroupColors.length];
}

/// Slides of [a] (or the selection) that are inside a group, by group.
Map<String, List<String>> _removable(DeckEditorController ed, JsonArgs a) {
  final ids = a.values.containsKey('slideIds')
      ? a.strings('slideIds')
      : _selectedSlides(ed);
  final out = <String, List<String>>{};
  for (final e in ed.order.entries) {
    final g = e.groupId;
    if (g != null && ids.contains(e.id)) out.putIfAbsent(g, () => []).add(e.id);
  }
  return out;
}

/// The selection and target of `slides.slide.move` / `slides.group.move`,
/// or null (no selection, unknown `to`, edge).
(NavSelection, SlideTarget)? _moveTarget(
  DeckEditorController ed,
  JsonArgs a, {
  required bool groupsOnly,
}) {
  final NavSelection sel;
  if (groupsOnly) {
    final groups = a.values.containsKey('groupIds')
        ? a.strings('groupIds')
        : _selection(ed).groupIds;
    sel = NavSelection.of(ed.order, groups: groups);
  } else {
    sel = _selectionOf(ed, a);
  }
  if (sel.isEmpty) return null;
  final target = NavigatorOps.targetOf(
    ed.order,
    sel,
    navigatorOf(ed).collapsed,
    a.values['to'],
  );
  return target == null ? null : (sel, target);
}

/// The move operations of `slides.slide.move` / `slides.group.move`, or
/// null when the move is not possible (no selection, edge, nesting, no
/// change). A copy (`copy: true`) is possible wherever a move would be.
List<SlidesOperation>? _moveOps(
  DeckEditorController ed,
  JsonArgs a, {
  required bool groupsOnly,
}) {
  final m = _moveTarget(ed, a, groupsOnly: groupsOnly);
  if (m == null) return null;
  final (sel, target) = m;
  if (a.boolean('copy') ?? false) {
    return target is InGroup && sel.hasGroups ? null : const [];
  }
  try {
    final ops = NavigatorOps.moveOps(ed.order, sel, target);
    return ops.isEmpty ? null : ops;
  } on NavMoveRefused {
    return null;
  }
}

Future<CommandResult> _runMove(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a, {
  required bool groupsOnly,
}) async {
  final m = _moveTarget(ed, a, groupsOnly: groupsOnly);
  if (m == null) {
    return CommandResult.failed(slidesL10nOf(ed.services).errorNothingToMove);
  }
  final (sel, target) = m;
  if (target is InGroup && sel.hasGroups) {
    return CommandResult.failed(slidesL10nOf(ed.services).reasonGroupsCantNest);
  }
  if (a.boolean('copy') ?? false) {
    // Alt-drop: a same-deck paste of the selection at the target.
    final plan = ed.apply(
      ctx,
      PasteSlides(
        SlidesClipboardCodec.copySlides(
          ed.model,
          slideIds: sel.slideIds,
          groupIds: sel.groupIds,
          sourceItemUuid: ed.session.itemUuid.uuid,
        ),
        target: target,
      ),
    );
    final slides = (plan.result['slideIds'] as List?)?.cast<String>() ?? [];
    final groups = (plan.result['groupIds'] as List?)?.cast<String>() ?? [];
    _selectNew(ed, groups: groups, slides: slides);
    return ok({'slideIds': slides, 'groupIds': groups});
  }
  final ops = _moveOps(ed, a, groupsOnly: groupsOnly);
  if (ops == null) {
    return CommandResult.failed(slidesL10nOf(ed.services).errorNothingToMove);
  }
  for (final op in ops) {
    ed.apply(ctx, op);
  }
  return ok();
}

/// The `to` argument of a move command for [t] (04 §5.7).
Object navMoveTo(SlideTarget t) => switch (t) {
  TopLevel(beforeId: null, afterId: null) => 'end',
  TopLevel(:final beforeId?) => {'beforeId': beforeId},
  TopLevel(:final afterId?) => {'afterId': afterId},
  InGroup(:final beforeId?) => {'beforeId': beforeId},
  InGroup(:final afterId?) => {'afterId': afterId},
  InGroup(:final groupId) => {'groupId': groupId},
};

/// Selects newly created groups and slides; the first becomes current.
void _selectNew(
  DeckEditorController ed, {
  List<String> groups = const [],
  List<String> slides = const [],
}) {
  final all = [for (final g in groups) ..._members(ed.order, g), ...slides];
  if (all.isEmpty && groups.isEmpty) return;
  ed.selectSlides(all, groups: groups);
  final first = ed.order.entries
      .where((e) => all.contains(e.id))
      .firstOrNull
      ?.id;
  if (first != null) ed.setCurrentSlide(first, select: false);
}

/// Where a paste goes without an insertion point (04 §5.8): after the last
/// selected row (after its group when groups are pasted into a group — the
/// planner moves group payloads out of groups).
SlideTarget _pasteTarget(DeckEditorController ed) {
  final units = NavigatorOps.units(ed.order, _selection(ed));
  if (units.isEmpty) return const TopLevel();
  final last = units.last;
  if (last.isGroup) return TopLevel(afterId: last.id);
  final e = ed.order.entry(last.id);
  final g = e?.groupId;
  if (g != null) return InGroup(g, afterId: last.id);
  if (e != null && e.orphan) return const TopLevel();
  return TopLevel(afterId: last.id);
}

Future<void> _copy(DeckEditorController ed, NavSelection sel) =>
    SlidesSlideClipboard.put(
      ed.services.userStore,
      SlidesClipboardCodec.copySlides(
        ed.model,
        slideIds: sel.slideIds,
        groupIds: sel.groupIds,
        sourceItemUuid: ed.session.itemUuid.uuid,
      ),
    );

void _toastGroupDeleted(CommandContext ctx) {
  if (ctx.source.isAgent) return;
  final s = ctx.services;
  final l = slidesL10nOf(s);
  s.toasts.show(
    l.toastGroupDeleted,
    actionLabel: s.l10n?.actionUndo,
    onAction: () =>
        s.dispatcher.invoke('shell.edit.undo', source: InvocationSource.ui),
  );
}

SlidesCommand _collapse(
  String id,
  SlidesText label,
  IconData icon, {
  required bool collapse,
}) => SlidesCommand(
  id,
  label: label,
  icon: icon,
  categoryOf: SlidesCategory.slides,
  argsSchema: _groupIdsSchema,
  enabled: (ed, a) {
    final nav = navigatorOf(ed);
    return _targetGroups(ed, a).any((g) => nav.isCollapsed(g) != collapse);
  },
  reason: (l, ed) {
    if (_targetGroups(ed, const JsonArgs()).isEmpty) {
      return l.reasonSelectGroup;
    }
    return collapse ? l.reasonAllCollapsed : l.reasonAllExpanded;
  },
  run: (ctx, ed, a) {
    navigatorOf(ed).setCollapsed(_targetGroups(ed, a), collapse);
    return ok();
  },
);

SlidesCommand _collapseAll(
  String id,
  SlidesText label, {
  required bool collapse,
  required KeyBinding binding,
}) => SlidesCommand(
  id,
  label: label,
  icon: collapse ? LucideIcons.chevronsDownUp : LucideIcons.chevronsUpDown,
  categoryOf: SlidesCategory.slides,
  defaultBindings: [binding],
  enabled: (ed, a) => ed.order.groups.isNotEmpty,
  reason: (l, ed) => l.reasonNoGroups,
  run: (ctx, ed, a) {
    navigatorOf(
      ed,
    ).setCollapsed([for (final g in ed.order.groups) g.group.id], collapse);
    return ok();
  },
);
