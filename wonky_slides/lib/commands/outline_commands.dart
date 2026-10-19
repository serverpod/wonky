import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart' show IconData;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;

import '../features/editor_screen/deck_editor_controller.dart';
import '../features/outline_view/outline_body.dart';
import '../features/outline_view/outline_controller.dart';
import '../l10n/slides_l10n.dart' show slidesL10nOf;
import 'canvas_commands.dart' show recordCoalescedStep;
import 'slides_command.dart';

/// The outline view's commands (Slides 04 §10; SL-34). Without `slideId`
/// / `index` / `offset` they act on the focused outline line and caret
/// (`OutlineController`); `index` -1 is the slide title, 0… the body
/// placeholder's paragraphs (bullets). Every edit is one undo step through
/// the planner (`SetText`, `AddSlides`, `DeleteSlides`, …); typing in the
/// outline writes `setTitle`/`setBody` with `typing: true` after a pause,
/// coalesced per slide (one step per typing burst), and unwritten typing
/// is flushed into the next structural command's step.
///
/// - `slides.outline.setTitle {slideId, text}` / `setBody {slideId,
///   delta}` write a title (formatting of untouched text kept; a missing
///   title placeholder instance is added) or the bullets.
/// - Enter: `newSlideAfter` (in a title: a new slide after it, the text
///   after the caret moves to its title) and `newLine` (in a bullet: split
///   it). ⌘Enter: `focusBody` (the first bullet).
/// - Tab / Shift+Tab: `indent` / `outdent` (bullet levels; Shift+Tab on a
///   top-level bullet promotes it to a new slide with the bullets after
///   it; Tab on a title demotes the slide into the previous one's bullets
///   when it holds nothing else).
/// - Alt+Shift+↑/↓: `moveUp` / `moveDown` (bullets in their body; slides
///   in the deck).
/// - Backspace at the start of a line: `joinLine` (joins a bullet onto
///   the one above; deletes an empty slide).
/// - ⌘G: `groupSlides` (the selected slides, `slides.group.create`).
/// - `copyMarkdown`: the outline as Markdown (`#` titles, `-` bullets).
List<Command<CommandArgs>> outlineCommands(ShellServices s) => [
  SlidesCommand(
    'slides.outline.setTitle',
    label: (l) => l.cmdOutlineSetTitle,
    icon: LucideIcons.heading,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'slideId': JsonSchema.string(),
        'text': JsonSchema.string(description: 'The title (plain text).'),
        'typing': JsonSchema.boolean(
          description: 'Coalesce with the previous typing step.',
        ),
      },
      required: ['slideId', 'text'],
    ),
    enabled: (ed, a) =>
        _slide(ed, a.string('slideId')) != null &&
        OutlineSlideParts.of(ed.model, a.string('slideId')!).titleEditable,
    reason: (l, ed) => l.reasonOutlineNoTitle,
    run: (ctx, ed, a) {
      final slide = a.requireString('slideId');
      final text = a.requireString('text').replaceAll('\n', ' ');
      final typing = a.boolean('typing') ?? false;
      if (!typing) _flush(ctx, ed);
      final ops = OutlineSlideParts.of(ed.model, slide).setTitle(text);
      _write(ctx, ed, ops, typing: typing, slideId: slide);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.outline.setBody',
    label: (l) => l.cmdOutlineSetBody,
    icon: LucideIcons.list,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'slideId': JsonSchema.string(),
        'delta': JsonSchema.string(
          description: 'The body as Delta JSON (one paragraph per bullet).',
        ),
        'typing': JsonSchema.boolean(),
      },
      required: ['slideId', 'delta'],
    ),
    enabled: (ed, a) =>
        _slide(ed, a.string('slideId')) != null &&
        OutlineSlideParts.of(ed.model, a.string('slideId')!).body != null,
    reason: (l, ed) => l.reasonOutlineNoBody,
    run: (ctx, ed, a) {
      final slide = a.requireString('slideId');
      final typing = a.boolean('typing') ?? false;
      if (!typing) _flush(ctx, ed);
      final op = OutlineSlideParts.of(
        ed.model,
        slide,
      ).setBody(OutlineBody.parse(a.requireString('delta')));
      _write(ctx, ed, [?op], typing: typing, slideId: slide);
      return ok();
    },
  ),
  _lineCommand(
    'slides.outline.newSlideAfter',
    (l) => l.cmdOutlineNewSlideAfter,
    LucideIcons.squarePlus,
    bindings: const [KeyBinding('Enter')],
    extra: const {'title': JsonSchema.string()},
    enabled: (ed, t, a) => t.index < 0,
    run: (ctx, ed, t, a) {
      _flush(ctx, ed);
      final parts = OutlineSlideParts.of(ed.model, t.slideId);
      final title = parts.titleBody;
      OutlineParagraph moved;
      final explicit = a.string('title');
      if (explicit != null) {
        moved = OutlineParagraph.plain(explicit);
      } else {
        final first = title[0];
        final o = t.offset.clamp(0, first.text.length);
        moved = OutlineParagraph(first.slice(o).runs);
        if (o < first.text.length && parts.title != null) {
          final kept = OutlineBody([
            first.slice(0, o),
            ...title.paragraphs.skip(1),
          ]);
          ed.apply(ctx, SetText(ElementText(parts.title!.id), kept.toJson()));
        }
      }
      final plan = ed.apply(ctx, AddSlides(afterSlideId: t.slideId));
      final id = (plan.result['slideIds'] as List).cast<String>().first;
      if (moved.text.isNotEmpty) {
        final next = OutlineSlideParts.of(ed.model, id);
        final nt = next.title;
        if (nt != null) {
          ed.apply(
            ctx,
            SetText(ElementText(nt.id), OutlineBody([moved]).toJson()),
          );
        } else {
          for (final op in next.setTitle(moved.text)) {
            ed.apply(ctx, op);
          }
        }
      }
      ed.setCurrentSlide(id);
      outlineOf(ed).focusLine(OutlineLine.title(id), offset: 0);
      return ok({'slideId': id});
    },
  ),
  _lineCommand(
    'slides.outline.newLine',
    (l) => l.cmdOutlineNewLine,
    LucideIcons.listPlus,
    bindings: const [KeyBinding('Enter')],
    enabled: (ed, t, a) => t.index >= 0 && t.parts.body != null,
    run: (ctx, ed, t, a) {
      _flush(ctx, ed);
      final parts = OutlineSlideParts.of(ed.model, t.slideId);
      final body = parts.bodyLines;
      final i = t.index.clamp(0, body.length - 1);
      final next = body.split(i, t.offset);
      final op = parts.setBody(next);
      if (op != null) ed.apply(ctx, op);
      outlineOf(ed).focusLine(OutlineLine(t.slideId, i + 1), offset: 0);
      return ok();
    },
  ),
  _lineCommand(
    'slides.outline.focusBody',
    (l) => l.cmdOutlineFocusBody,
    LucideIcons.textCursor,
    bindings: const [KeyBinding('Enter', mod: true)],
    mutates: false,
    enabled: (ed, t, a) => t.index < 0 && t.parts.body != null,
    run: (ctx, ed, t, a) {
      outlineOf(ed).focusLine(OutlineLine(t.slideId, 0), offset: 0);
      return ok();
    },
  ),
  _lineCommand(
    'slides.outline.indent',
    (l) => l.cmdOutlineIndent,
    LucideIcons.indentIncrease,
    bindings: const [KeyBinding('Tab')],
    enabled: (ed, t, a) =>
        t.index >= 0 ? _level(t) < 8 : _demoteTarget(ed, t) != null,
    run: (ctx, ed, t, a) {
      _flush(ctx, ed);
      final parts = OutlineSlideParts.of(ed.model, t.slideId);
      if (t.index >= 0) {
        final body = parts.bodyLines;
        final i = t.index.clamp(0, body.length - 1);
        final op = parts.setBody(body.withLevel(i, body[i].level + 1));
        if (op != null) ed.apply(ctx, op);
        outlineOf(ed).focusLine(OutlineLine(t.slideId, i), offset: t.offset);
        return ok();
      }
      // Demote the slide into the previous slide's bullets.
      final prev = _demoteTarget(ed, t)!;
      final pp = OutlineSlideParts.of(ed.model, prev);
      final pBody = pp.bodyLines;
      final start = pBody.isBlank ? 0 : pBody.length;
      final merged = pBody.concat(
        OutlineBody([
          OutlineParagraph(parts.titleBody[0].runs),
          if (!parts.bodyLines.isBlank)
            for (final p in parts.bodyLines.paragraphs)
              p.withLevel(p.level + 1),
        ]),
      );
      final op = pp.setBody(merged);
      if (op != null) ed.apply(ctx, op);
      ed.apply(ctx, DeleteSlides([t.slideId]));
      ed.setCurrentSlide(prev);
      outlineOf(ed).focusLine(OutlineLine(prev, start), offset: t.offset);
      return ok({'slideId': prev});
    },
  ),
  _lineCommand(
    'slides.outline.outdent',
    (l) => l.cmdOutlineOutdent,
    LucideIcons.indentDecrease,
    bindings: const [KeyBinding('Tab', shift: true)],
    enabled: (ed, t, a) => t.index >= 0,
    run: (ctx, ed, t, a) {
      _flush(ctx, ed);
      final parts = OutlineSlideParts.of(ed.model, t.slideId);
      final body = parts.bodyLines;
      final i = t.index.clamp(0, body.length - 1);
      final level = body[i].level;
      if (level > 0) {
        final op = parts.setBody(body.withLevel(i, level - 1));
        if (op != null) ed.apply(ctx, op);
        outlineOf(ed).focusLine(OutlineLine(t.slideId, i), offset: t.offset);
        return ok();
      }
      // Promote: the bullet becomes a new slide's title, the bullets after
      // it its body (its sub-bullets one level up).
      final rest = <OutlineParagraph>[];
      var children = true;
      for (final p in body.paragraphs.skip(i + 1)) {
        if (p.level == 0) children = false;
        rest.add(children ? p.withLevel(p.level - 1) : p);
      }
      final keep = body.sublist(0, i);
      final op = parts.setBody(i == 0 ? OutlineBody(const []) : keep);
      if (op != null) ed.apply(ctx, op);
      final plan = ed.apply(ctx, AddSlides(afterSlideId: t.slideId));
      final id = (plan.result['slideIds'] as List).cast<String>().first;
      final np = OutlineSlideParts.of(ed.model, id);
      final title = body.titleOf(i);
      if (np.title != null) {
        ed.apply(ctx, SetText(ElementText(np.title!.id), title.toJson()));
      } else {
        for (final o in np.setTitle(title[0].text)) {
          ed.apply(ctx, o);
        }
      }
      if (rest.isNotEmpty) {
        final bop = OutlineSlideParts.of(
          ed.model,
          id,
        ).setBody(OutlineBody(rest));
        if (bop != null) ed.apply(ctx, bop);
      }
      ed.setCurrentSlide(id);
      outlineOf(ed).focusLine(OutlineLine.title(id), offset: t.offset);
      return ok({'slideId': id});
    },
  ),
  for (final up in [true, false])
    _lineCommand(
      up ? 'slides.outline.moveUp' : 'slides.outline.moveDown',
      up ? (l) => l.cmdOutlineMoveUp : (l) => l.cmdOutlineMoveDown,
      up ? LucideIcons.arrowUp : LucideIcons.arrowDown,
      bindings: [
        KeyBinding(up ? 'ArrowUp' : 'ArrowDown', alt: true, shift: true),
      ],
      enabled: (ed, t, a) {
        if (t.index >= 0) {
          final n = t.parts.bodyLines.length;
          return up ? t.index > 0 : t.index < n - 1;
        }
        return ed.services.dispatcher.stateOf('slides.slide.move', {
          'slideIds': [t.slideId],
          'to': up ? 'up' : 'down',
        }).enabled;
      },
      run: (ctx, ed, t, a) async {
        _flush(ctx, ed);
        if (t.index >= 0) {
          final parts = OutlineSlideParts.of(ed.model, t.slideId);
          final to = t.index + (up ? -1 : 1);
          final op = parts.setBody(parts.bodyLines.move(t.index, to));
          if (op != null) ed.apply(ctx, op);
          outlineOf(ed).focusLine(OutlineLine(t.slideId, to), offset: t.offset);
          return ok();
        }
        final r = await ed.invokeCommand(
          'slides.slide.move',
          {
            'slideIds': [t.slideId],
            'to': up ? 'up' : 'down',
          },
          ctx.source,
          ctx.dialogContext,
        );
        outlineOf(ed).focusLine(OutlineLine.title(t.slideId), offset: t.offset);
        return r;
      },
    ),
  _lineCommand(
    'slides.outline.joinLine',
    (l) => l.cmdOutlineJoinLine,
    LucideIcons.cornerUpLeft,
    bindings: const [KeyBinding('Backspace')],
    enabled: (ed, t, a) {
      final o = outlineOf(ed);
      final fromKeys = !a.values.containsKey('slideId');
      if (fromKeys && (o.caret != 0 || o.hasSelection)) return false;
      if (t.index >= 0) return true;
      return _previousSlide(ed, t.slideId) != null;
    },
    run: (ctx, ed, t, a) {
      _flush(ctx, ed);
      final o = outlineOf(ed);
      final parts = OutlineSlideParts.of(ed.model, t.slideId);
      final body = parts.bodyLines;
      if (t.index > 0) {
        final i = t.index.clamp(1, body.length - 1);
        final at = body[i - 1].text.length;
        final op = parts.setBody(body.join(i));
        if (op != null) ed.apply(ctx, op);
        o.focusLine(OutlineLine(t.slideId, i - 1), offset: at);
        return ok();
      }
      if (t.index == 0) {
        if (body[0].text.isEmpty && body.length > 1) {
          final op = parts.setBody(body.removeAt(0));
          if (op != null) ed.apply(ctx, op);
        }
        o.focusLine(OutlineLine.title(t.slideId));
        return ok();
      }
      // At the start of a title: an empty slide is deleted; else the
      // caret moves to the end of the previous slide.
      final prev = _previousSlide(ed, t.slideId)!;
      final empty =
          parts.titleBody.isBlank &&
          body.isBlank &&
          !parts.otherContent &&
          !parts.hasNotes;
      if (empty) ed.apply(ctx, DeleteSlides([t.slideId]));
      final pp = OutlineSlideParts.of(ed.model, prev);
      final pb = pp.bodyLines;
      ed.setCurrentSlide(prev);
      if (pp.body != null && !pb.isBlank) {
        o.focusLine(OutlineLine(prev, pb.length - 1));
      } else {
        o.focusLine(OutlineLine.title(prev));
      }
      return ok({'deleted': empty});
    },
  ),
  SlidesCommand(
    'slides.outline.groupSlides',
    label: (l) => l.cmdGroupCreate,
    icon: LucideIcons.group,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    showInPalette: false,
    keyScope: SlidesKeyScopes.outline,
    defaultBindings: const [KeyBinding('G', mod: true)],
    enabled: (ed, a) =>
        ed.mode == DeckViewMode.outline &&
        ed.services.dispatcher.stateOf('slides.group.create').enabled,
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) {
      _flush(ctx, ed);
      return ed.invokeCommand(
        'slides.group.create',
        const {},
        ctx.source,
        ctx.dialogContext,
      );
    },
  ),
  SlidesCommand(
    'slides.outline.copyMarkdown',
    label: (l) => l.cmdOutlineCopyMarkdown,
    icon: LucideIcons.clipboardCopy,
    categoryOf: SlidesCategory.edit,
    enabled: (ed, a) => ed.order.length > 0,
    reason: (l, ed) => l.reasonNoSlides,
    run: (ctx, ed, a) async {
      final md = outlineMarkdown(
        ed.model,
        untitled: slidesL10nOf(s).outlineNoTitle,
      );
      if (!ctx.source.isAgent) {
        await Clipboard.setData(ClipboardData(text: md));
        s.toasts.show(slidesL10nOf(s).outlineCopied);
      }
      return ok({'markdown': md});
    },
  ),
];

/// The outline of [model] as Markdown (04 §10): groups as HTML comments,
/// `#` slide titles and `-` bullets indented by level.
String outlineMarkdown(DeckModel model, {required String untitled}) {
  final out = StringBuffer();
  String? group;
  for (final e in model.indexes.order.entries) {
    if (e.groupId != group) {
      group = e.groupId;
      final g = group == null ? null : model.group(group);
      if (g != null) out.writeln('<!-- ${g.title} -->\n');
    }
    final parts = OutlineSlideParts.of(model, e.id);
    final title = parts.titleBody[0].toMarkdown().trim();
    out.writeln('# ${title.isEmpty ? untitled : title}');
    final body = parts.bodyLines;
    if (!body.isBlank) {
      out.writeln();
      for (final p in body.paragraphs) {
        if (p.text.trim().isEmpty) continue;
        out.writeln('${'  ' * p.level}- ${p.toMarkdown()}');
      }
    }
    out.writeln();
  }
  return out.toString().trimRight();
}

/// The target line of an outline command.
class _Target {
  _Target(this.slideId, this.index, this.offset, this.parts);

  final String slideId;
  final int index;
  final int offset;
  final OutlineSlideParts parts;
}

typedef _TargetRun =
    FutureOr<CommandResult> Function(
      CommandContext ctx,
      DeckEditorController ed,
      _Target t,
      JsonArgs a,
    );

/// An outline command on a line (explicit `slideId`/`index`/`offset`, else
/// the focused line in the outline view).
SlidesCommand _lineCommand(
  String id,
  SlidesText label,
  IconData icon, {
  required List<KeyBinding> bindings,
  required bool Function(DeckEditorController ed, _Target t, JsonArgs a)
  enabled,
  required _TargetRun run,
  Map<String, JsonSchema> extra = const {},
  bool mutates = true,
}) => SlidesCommand(
  id,
  label: label,
  icon: icon,
  categoryOf: SlidesCategory.slides,
  mutates: mutates,
  showInPalette: false,
  keyScope: SlidesKeyScopes.outline,
  defaultBindings: bindings,
  argsSchema: JsonSchema.object(
    properties: {
      'slideId': const JsonSchema.string(),
      'index': const JsonSchema.integer(
        description: '-1 = the title, else the bullet (paragraph) index.',
      ),
      'offset': const JsonSchema.integer(description: 'The caret offset.'),
      ...extra,
    },
  ),
  enabled: (ed, a) {
    final t = _target(ed, a);
    return t != null && enabled(ed, t, a);
  },
  reason: (l, ed) => l.reasonOutlineLine,
  run: (ctx, ed, a) async {
    final t = _target(ed, a);
    if (t == null) return const CommandResult.failed('No outline line');
    return run(ctx, ed, t, a);
  },
);

/// The line an outline command acts on.
_Target? _target(DeckEditorController ed, JsonArgs a) {
  final o = outlineOf(ed);
  final explicit = a.string('slideId');
  final focus = o.focused;
  final slide = explicit ?? focus?.slideId;
  if (_slide(ed, slide) == null) return null;
  final parts = OutlineSlideParts.of(ed.model, slide!);
  final index = a.integer('index') ?? (explicit == null ? focus!.index : -1);
  final line = index < 0
      ? parts.titleBody[0].text
      : (index < parts.bodyLines.length ? parts.bodyLines[index].text : null);
  if (line == null) return null;
  final offset =
      a.integer('offset') ?? (explicit == null ? o.caret : line.length);
  return _Target(slide, index, offset.clamp(0, line.length), parts);
}

int _level(_Target t) =>
    t.index < t.parts.bodyLines.length ? t.parts.bodyLines[t.index].level : 0;

String? _slide(DeckEditorController ed, String? id) =>
    id != null && ed.order.entry(id) != null ? id : null;

String? _previousSlide(DeckEditorController ed, String slideId) {
  final i = ed.order.indexOf(slideId);
  return i > 0 ? ed.order.entries[i - 1].id : null;
}

/// The slide a title can be demoted into (the previous slide, with a body
/// placeholder), or null when the slide holds more than a title and
/// bullets (it would be lost).
String? _demoteTarget(DeckEditorController ed, _Target t) {
  if (t.parts.otherContent || t.parts.hasNotes) return null;
  final prev = _previousSlide(ed, t.slideId);
  if (prev == null) return null;
  return OutlineSlideParts.of(ed.model, prev).body == null ? null : prev;
}

/// Writes the outline's unwritten typing into [ctx]'s step.
void _flush(CommandContext ctx, DeckEditorController ed) {
  for (final op in outlineOf(ed).takePending()) {
    ed.apply(ctx, op);
  }
}

/// Applies [ops]: as the command's step, or (typing) as a step coalesced
/// with the previous typing of [slideId].
void _write(
  CommandContext ctx,
  DeckEditorController ed,
  List<SlidesOperation> ops, {
  required bool typing,
  required String slideId,
}) {
  if (!typing) {
    for (final op in ops) {
      ed.apply(ctx, op);
    }
    return;
  }
  final changes = <RowChange>[];
  for (final op in ops) {
    changes.addAll(ed.session.execute(op).changes);
  }
  recordCoalescedStep(
    ctx,
    ed,
    changes,
    key: 'slides.outline:$slideId',
    label: slidesL10nOf(ed.services).outlineTypingUndo,
  );
}
