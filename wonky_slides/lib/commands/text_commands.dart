import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show IconData;

import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/model.dart' as core show SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/scene.dart' show defaultTextInsets;
import 'package:wonky_slides_core/themes.dart' show ColorRef, SlidesFonts;
import 'package:wonky_rich_text/wonky_rich_text.dart' show Delta;
import 'package:wonky_sync_models/ids.dart' show Base62Uuid;

import '../config/menus/slides_menu_spec.dart' show textStyleKeys;
import '../features/canvas/canvas_tools.dart' show CanvasTools;
import '../features/canvas/slide_canvas_controller.dart';
import '../features/elements/text/text_box_tool.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/elements/text/text_dialogs.dart';
import '../features/text_editing/text_editing_host.dart';
import '../features/text_editing/text_format.dart';
import '../l10n/slides_l10n.dart';
import 'slides_command.dart';

/// Font size steps of *Increase/Decrease font size* (su, 03 §6.1).
const fontSizeSteps = <double>[
  8, 10, 12, 14, 18, 24, 28, 32, 36, 40, 48, 56, 64, 72, 96, 120, 144, 200, //
  240, 288, 360, 480, 600, 800,
];

/// The next size step above (or below, [direction] < 0) [size].
double stepFontSize(double size, int direction) {
  if (direction > 0) {
    for (final s in fontSizeSteps) {
      if (s > size + 0.01) return s;
    }
    return fontSizeSteps.last;
  }
  for (final s in fontSizeSteps.reversed) {
    if (s < size - 0.01) return s;
  }
  return fontSizeSteps.first;
}

/// Bullet and numbering styles of `slides.format.listStyle` (02 §4.1).
const listStyleKeys = [
  'disc',
  'circle',
  'square',
  'dash',
  'arrow',
  'check',
  'star',
  'none',
  'decimal',
  'lowerAlpha',
  'upperAlpha',
  'lowerRoman',
  'upperRoman',
];

/// Inline attributes *Clear formatting* removes (links stay, 03 §6.1).
const _clearedInline = [
  'bold',
  'italic',
  'underline',
  'strike',
  'code',
  'font',
  'weight',
  'size',
  'color',
  'highlight',
  'script',
  'caps',
  'letterSpacing',
];

/// The text commands of SL-13 (Slides 03 §6.1–§6.2, §6.9; 04 §4.5, §6.2):
/// every `slides.format.*` text command (inline, paragraph and box level),
/// text box insertion, links, *Exit editing* and *Reset to layout*.
///
/// While a body is edited they apply to its selection (pending typing is
/// written first; a collapsed caret sets the typing attributes); otherwise
/// to all text of every selected text-capable element (soft-locked bodies
/// are skipped with a toast). Each command is one undo step.
List<Command<CommandArgs>> textCommands(ShellServices s) {
  CanvasTools.register(TextBoxTool.factory);
  return _textCommands(s);
}

List<Command<CommandArgs>> _textCommands(ShellServices s) => [
  _toggle(
    'slides.format.bold',
    (l) => l.cmdFormatBold,
    LucideIcons.bold,
    const [KeyBinding('B', mod: true)],
    (st) => st.bold,
    (f, on) => on
        ? const {'bold': true, 'weight': null}
        : {
            'bold': null,
            'weight': TextFormatState.themeBold(f.scope) ? 400 : null,
          },
  ),
  _toggle(
    'slides.format.italic',
    (l) => l.cmdFormatItalic,
    LucideIcons.italic,
    const [KeyBinding('I', mod: true)],
    (st) => st.italic,
    (f, on) => {'italic': on ? true : null},
  ),
  _toggle(
    'slides.format.underline',
    (l) => l.cmdFormatUnderline,
    LucideIcons.underline,
    const [KeyBinding('U', mod: true)],
    (st) => st.underline,
    (f, on) => {'underline': on ? true : null},
  ),
  _toggle(
    'slides.format.strikethrough',
    (l) => l.cmdFormatStrikethrough,
    LucideIcons.strikethrough,
    const [
      KeyBinding('X', mod: true, shift: true, mac: true),
      KeyBinding('5', alt: true, shift: true, mac: false),
    ],
    (st) => st.strike,
    (f, on) => {'strike': on ? true : null},
  ),
  _text(
    'slides.format.script',
    label: (l) => l.cmdFormatScript,
    icon: LucideIcons.superscript,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.string(enumValues: ['super', 'sub', 'none']),
      },
      required: ['value'],
    ),
    argBindings: const [
      ArgsKeyBinding(KeyBinding('.', mod: true), {'value': 'super'}),
      ArgsKeyBinding(KeyBinding(',', mod: true), {'value': 'sub'}),
    ],
    checked: (st, a) => st.script == a.string('value'),
    run: (ctx, ed, a, f) {
      final v = a.string('value');
      final on = v == 'super' || v == 'sub';
      final st = TextFormatState.of(f.scope);
      f.inline({'script': on && st.script != v ? v : null});
      return ok();
    },
  ),
  for (final (id, label, icon, key, dir) in [
    (
      'slides.format.increaseFontSize',
      (SlidesLocalizations l) => l.cmdFormatIncreaseFontSize,
      LucideIcons.aArrowUp,
      '.',
      1,
    ),
    (
      'slides.format.decreaseFontSize',
      (SlidesLocalizations l) => l.cmdFormatDecreaseFontSize,
      LucideIcons.aArrowDown,
      ',',
      -1,
    ),
  ])
    _text(
      id,
      label: label,
      icon: icon,
      defaultBindings: [KeyBinding(key, mod: true, shift: true)],
      run: (ctx, ed, a, f) {
        f.perRun((style, inline) => {'size': stepFontSize(style.size, dir)});
        return ok();
      },
    ),
  _text(
    'slides.format.caps',
    label: (l) => l.cmdFormatCaps,
    icon: LucideIcons.caseUpper,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.string(
          enumValues: ['upper', 'smallCaps', 'title', 'none'],
        ),
      },
      required: ['value'],
    ),
    checked: (st, a) => st.caps == _caps(a.string('value')),
    run: (ctx, ed, a, f) {
      f.inline({'caps': _caps(a.string('value'))});
      return ok();
    },
  ),
  _text(
    'slides.format.textStyle',
    label: (l) => l.cmdFormatTextStyle,
    icon: LucideIcons.heading,
    argsSchema: JsonSchema.object(
      properties: {'key': JsonSchema.string(enumValues: textStyleKeys)},
      required: const ['key'],
    ),
    argBindings: [
      for (final (i, key) in textStyleKeys.take(9).indexed)
        ArgsKeyBinding(KeyBinding('${i + 1}', mod: true, alt: true), {
          'key': key,
        }),
    ],
    checked: (st, a) => st.styleKey == a.string('key'),
    run: (ctx, ed, a, f) {
      f.block({'style': a.requireString('key')});
      return ok();
    },
  ),
  _text(
    'slides.format.font',
    label: (l) => l.cmdFormatFont,
    icon: LucideIcons.type,
    argsSchema: const JsonSchema.object(
      properties: {
        'family': JsonSchema.string(
          description:
              'A bundled family ("Lato") or a theme font (`@heading`, '
              '`@body`, `@mono`).',
        ),
      },
    ),
    run: (ctx, ed, a, f) async {
      var family = a.string('family');
      if (family == null) {
        final dc = ctx.dialogContext;
        if (dc == null || !dc.mounted || ctx.source.isAgent) {
          return const CommandResult.failed('family is required');
        }
        final l = slidesL10n(dc);
        final st = TextFormatState.of(f.scope);
        family = await showTextChoiceDialog(
          dc,
          dialogKey: 'dialog.slides.font',
          title: l.cmdFormatFont,
          label: l.fontLabel,
          options: fontOptions(l),
          initial: st.fontRef ?? st.font ?? '@body',
        );
        if (family == null) return const CommandResult.cancelled();
      }
      f.inline({'font': family});
      return ok();
    },
  ),
  _text(
    'slides.format.fontSize',
    label: (l) => l.cmdFormatFontSize,
    argsSchema: const JsonSchema.object(
      properties: {'size': JsonSchema.number(minimum: 6, maximum: 800)},
    ),
    run: (ctx, ed, a, f) async {
      var size = (a.values['size'] as num?)?.toDouble();
      if (size == null) {
        final st = TextFormatState.of(f.scope);
        final v = await _askNumber(
          ctx,
          key: 'dialog.slides.fontSize',
          title: (l) => l.cmdFormatFontSize,
          label: (l) => l.fontSizeLabel,
          initial: st.size,
          min: 6,
          max: 800,
        );
        if (v == null) return const CommandResult.cancelled();
        size = v;
      }
      f.inline({'size': size.clamp(6, 800)});
      return ok();
    },
  ),
  for (final (id, key, label, icon) in [
    (
      'slides.format.textColor',
      'color',
      (SlidesLocalizations l) => l.cmdFormatTextColor,
      LucideIcons.baseline,
    ),
    (
      'slides.format.highlight',
      'highlight',
      (SlidesLocalizations l) => l.cmdFormatHighlight,
      LucideIcons.highlighter,
    ),
  ])
    _text(
      id,
      label: label,
      icon: icon,
      argsSchema: const JsonSchema.object(
        properties: {
          'color': JsonSchema.nullable(
            JsonSchema.string(
              description:
                  '`#RRGGBB`, a theme color (`theme:accent1`) or null '
                  '(automatic / none).',
            ),
          ),
        },
      ),
      run: (ctx, ed, a, f) async {
        Object? color = a.values['color'];
        if (!a.values.containsKey('color')) {
          final st = TextFormatState.of(f.scope);
          final v = await _ask(
            ctx,
            key: 'dialog.slides.$key',
            title: label,
            label: (l) => l.colorLabel,
            initial: key == 'color' ? st.colorRef : st.highlight,
          );
          if (v == null) return const CommandResult.cancelled();
          color = v.isEmpty ? null : v;
        }
        if (color != null && (color is! String || !_validColor(color))) {
          return const CommandResult.failed('Invalid color');
        }
        f.inline({key: color});
        return ok();
      },
    ),
  _text(
    'slides.format.letterSpacing',
    label: (l) => l.cmdFormatLetterSpacing,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.nullable(
          JsonSchema.number(
            minimum: -0.2,
            maximum: 1,
            description: 'Em; null = the style\'s.',
          ),
        ),
      },
      required: ['value'],
    ),
    run: (ctx, ed, a, f) {
      f.inline({'letterSpacing': (a.values['value'] as num?)?.toDouble()});
      return ok();
    },
  ),
  _text(
    'slides.format.align',
    label: (l) => l.cmdFormatAlign,
    icon: LucideIcons.alignLeft,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.string(
          enumValues: ['left', 'center', 'right', 'justify'],
        ),
      },
      required: ['value'],
    ),
    argBindings: [
      for (final (k, v) in [
        ('L', 'left'),
        ('E', 'center'),
        ('R', 'right'),
        ('J', 'justify'),
      ])
        ArgsKeyBinding(KeyBinding(k, mod: true, shift: true), {'value': v}),
    ],
    checked: (st, a) => st.align == a.string('value'),
    run: (ctx, ed, a, f) {
      f.block({'align': a.requireString('value')});
      return ok();
    },
  ),
  _text(
    'slides.format.anchor',
    label: (l) => l.cmdFormatAnchor,
    icon: LucideIcons.alignVerticalJustifyCenter,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.string(enumValues: ['top', 'middle', 'bottom']),
      },
      required: ['value'],
    ),
    checked: (st, a) => st.anchor == a.string('value'),
    run: (ctx, ed, a, f) {
      f.box({'anchor': a.requireString('value')});
      return ok();
    },
  ),
  for (final (id, label, icon, key, delta) in [
    (
      'slides.format.indent',
      (SlidesLocalizations l) => l.cmdFormatIndent,
      LucideIcons.indentIncrease,
      ']',
      1,
    ),
    (
      'slides.format.outdent',
      (SlidesLocalizations l) => l.cmdFormatOutdent,
      LucideIcons.indentDecrease,
      '[',
      -1,
    ),
  ])
    _text(
      id,
      label: label,
      icon: icon,
      defaultBindings: [KeyBinding(key, mod: true)],
      run: (ctx, ed, a, f) {
        f.perParagraph((block, _) {
          final cur = (block['indent'] as num?)?.toInt() ?? 0;
          final next = (cur + delta).clamp(0, 8);
          if (next == cur) return null;
          return {'indent': next == 0 ? null : next};
        });
        return ok();
      },
    ),
  _text(
    'slides.format.lineHeight',
    label: (l) => l.cmdFormatLineHeight,
    icon: LucideIcons.listCollapse,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.number(
          minimum: 0.7,
          maximum: 3,
          description: 'Line height multiplier (omit to enter one).',
        ),
      },
    ),
    checked: (st, a) {
      final v = (a.values['value'] as num?)?.toDouble();
      return v != null &&
          st.lineHeight != null &&
          (st.lineHeight! - v).abs() < 0.001;
    },
    run: (ctx, ed, a, f) async {
      var v = (a.values['value'] as num?)?.toDouble();
      if (v == null) {
        v = await _askNumber(
          ctx,
          key: 'dialog.slides.lineHeight',
          title: (l) => l.cmdFormatLineHeight,
          label: (l) => l.lineHeightLabel,
          initial: TextFormatState.of(f.scope).lineHeight,
          min: 0.7,
          max: 3,
          fractionDigits: 2,
        );
        if (v == null) return const CommandResult.cancelled();
      }
      f.block({'lineHeight': v.clamp(0.7, 3)});
      return ok();
    },
  ),
  _text(
    'slides.format.paragraphSpacing',
    label: (l) => l.cmdFormatParagraphSpacing,
    argsSchema: const JsonSchema.object(
      properties: {
        'before': JsonSchema.any(
          description:
              'Space before (su), or true to add/remove the default space.',
        ),
        'after': JsonSchema.any(
          description:
              'Space after (su), or true to add/remove the default space.',
        ),
      },
    ),
    run: (ctx, ed, a, f) {
      final attrs = <String, Object?>{};
      final paras = f.paragraphs;
      for (final (arg, key) in [
        ('before', 'spaceBefore'),
        ('after', 'spaceAfter'),
      ]) {
        final v = a.values[arg];
        if (v == true) {
          final has =
              paras.isNotEmpty &&
              paras.every((p) => ((p.$1[key] as num?) ?? 0) > 0);
          attrs[key] = has ? null : 12;
        } else if (v is num) {
          attrs[key] = v.clamp(0, 400);
        } else if (a.values.containsKey(arg) && v == null) {
          attrs[key] = null;
        }
      }
      if (attrs.isEmpty) return const CommandResult.failed('before or after');
      f.block(attrs);
      return ok();
    },
  ),
  _text(
    'slides.format.list',
    label: (l) => l.cmdFormatList,
    icon: LucideIcons.list,
    argsSchema: const JsonSchema.object(
      properties: {
        'type': JsonSchema.string(
          enumValues: ['bullet', 'number', 'ordered', 'check', 'none'],
        ),
      },
      required: ['type'],
    ),
    argBindings: [
      for (final (k, v) in [('8', 'bullet'), ('7', 'number'), ('9', 'check')])
        ArgsKeyBinding(KeyBinding(k, mod: true, shift: true), {'type': v}),
    ],
    checked: (st, a) => st.list != null && st.list == _listOf(a.string('type')),
    run: (ctx, ed, a, f) {
      final want = _listOf(a.string('type'));
      final paras = f.paragraphs;
      bool isIt(Map<String, Object?> b, Map<String, Object?> d) {
        final cur = effectiveList(b, d);
        return want == 'check'
            ? cur == 'check' || cur == 'unchecked'
            : cur == want;
      }

      final all =
          want != null &&
          paras.isNotEmpty &&
          paras.every((p) => isIt(p.$1, p.$2));
      f.perParagraph((block, defaults) {
        if (want == null || all) {
          // Off: drop the explicit list; a list from the box defaults (a
          // body placeholder's bullets) is turned off with `listStyle:
          // none` (02 §4.1).
          final fromDefault = effectiveList({...block, 'list': null}, defaults);
          if (fromDefault != null) return {'list': null, 'listStyle': 'none'};
          return block['list'] == null ? null : {'list': null};
        }
        if (isIt(block, defaults)) return null;
        return {
          'list': want == 'check' ? 'unchecked' : want,
          if (block['listStyle'] == 'none') 'listStyle': null,
        };
      });
      return ok();
    },
  ),
  _text(
    'slides.format.listStyle',
    label: (l) => l.cmdFormatListStyle,
    icon: LucideIcons.listOrdered,
    argsSchema: JsonSchema.object(
      properties: {
        'style': JsonSchema.string(
          description:
              'Bullet (${listStyleKeys.take(8).join(', ')}), numbering '
              '(${listStyleKeys.skip(8).join(', ')}) or `emoji:<emoji>`.',
        ),
      },
    ),
    run: (ctx, ed, a, f) async {
      var style = a.string('style');
      if (style == null) {
        final dc = ctx.dialogContext;
        if (dc == null || !dc.mounted || ctx.source.isAgent) {
          return const CommandResult.failed('style is required');
        }
        final l = slidesL10n(dc);
        style = await showTextChoiceDialog(
          dc,
          dialogKey: 'dialog.slides.listStyle',
          title: l.cmdFormatListStyle,
          label: l.listStyleLabel,
          options: {for (final k in listStyleKeys) k: listStyleLabel(l, k)},
          initial: 'disc',
        );
        if (style == null) return const CommandResult.cancelled();
      }
      final numbering = listStyleKeys.skip(8).contains(style);
      f.perParagraph((block, _) {
        final list = block['list'];
        return {
          'listStyle': style,
          if (list == null || (numbering != (list == 'ordered')))
            'list': numbering ? 'ordered' : 'bullet',
        };
      });
      return ok();
    },
  ),
  _text(
    'slides.format.listStart',
    label: (l) => l.cmdFormatListStart,
    argsSchema: const JsonSchema.object(
      properties: {'n': JsonSchema.integer(minimum: 0, maximum: 100000)},
    ),
    run: (ctx, ed, a, f) async {
      var n = a.integer('n');
      if (n == null) {
        final v = await _askNumber(
          ctx,
          key: 'dialog.slides.listStart',
          title: (l) => l.cmdFormatListStart,
          label: (l) => l.listStartLabel,
          initial: 1,
          min: 0,
          max: 100000,
        );
        if (v == null) return const CommandResult.cancelled();
        n = v.round();
      }
      f.block({'listStart': n, 'list': 'ordered'});
      return ok();
    },
  ),
  _text(
    'slides.format.autofit',
    label: (l) => l.cmdFormatAutofit,
    argsSchema: const JsonSchema.object(
      properties: {
        'mode': JsonSchema.string(enumValues: ['none', 'shrink', 'resize']),
      },
      required: ['mode'],
    ),
    checked: (st, a) => st.autofit == a.string('mode'),
    run: (ctx, ed, a, f) {
      f.box({'autofit': a.requireString('mode')});
      return ok();
    },
  ),
  _text(
    'slides.format.insets',
    label: (l) => l.cmdFormatInsets,
    argsSchema: const JsonSchema.object(
      properties: {
        't': JsonSchema.number(minimum: 0, maximum: 2000),
        'r': JsonSchema.number(minimum: 0, maximum: 2000),
        'b': JsonSchema.number(minimum: 0, maximum: 2000),
        'l': JsonSchema.number(minimum: 0, maximum: 2000),
      },
    ),
    run: (ctx, ed, a, f) {
      final cur = TextFormatState.of(f.scope).insets ?? defaultTextInsets;
      double v(String k, int i) =>
          ((a.values[k] as num?)?.toDouble() ?? cur[i]).clamp(0, 2000);
      f.box({
        'insets': [v('t', 0), v('r', 1), v('b', 2), v('l', 3)],
      });
      return ok();
    },
  ),
  _text(
    'slides.format.clear',
    label: (l) => l.cmdFormatClear,
    icon: LucideIcons.removeFormatting,
    defaultBindings: const [KeyBinding('\\', mod: true)],
    run: (ctx, ed, a, f) {
      f.inline({for (final k in _clearedInline) k: null});
      return ok();
    },
  ),

  // ---- Editing (03 §6.1)
  SlidesCommand(
    'slides.text.exitEditing',
    label: (l) => l.cmdTextExitEditing,
    icon: LucideIcons.squareMousePointer,
    categoryOf: SlidesCategory.text,
    keyScope: SlidesKeyScopes.text,
    enabled: (ed, a) => textEditingOf(ed).isEditing,
    reason: (l, ed) => l.reasonNotEditingText,
    run: (ctx, ed, a) {
      textEditingOf(ed).end();
      return ok();
    },
  ),
  SlidesCommand(
    'slides.insert.textBox',
    label: (l) => l.cmdInsertTextBox,
    icon: LucideIcons.type,
    categoryOf: SlidesCategory.insert,
    mutates: true,
    defaultBindings: const [KeyBinding('T')],
    keyScope: SlidesKeyScopes.canvas,
    argsSchema: const JsonSchema.object(
      properties: {
        'x': JsonSchema.number(description: 'Left (su).'),
        'y': JsonSchema.number(description: 'Top (su).'),
        'width': JsonSchema.number(
          minimum: 1,
          description: 'A fixed width (wraps); omit for an auto-width box.',
        ),
        'height': JsonSchema.number(minimum: 1),
        'text': JsonSchema.string(description: 'Plain text to put in it.'),
      },
    ),
    enabled: (ed, a) => ed.surfaceId != null && !ed.textEditing,
    reason: (l, ed) =>
        ed.surfaceId == null ? l.reasonNoSlides : l.reasonNotOnCanvas,
    checked: (ed, a) => ed.armedTool == 'text',
    run: _insertTextBox,
  ),

  // ---- Links (03 §6.1, §6.9)
  SlidesCommand(
    'slides.insert.link',
    label: (l) => l.cmdInsertLink,
    icon: LucideIcons.link,
    categoryOf: SlidesCategory.insert,
    mutates: true,
    defaultBindings: const [KeyBinding('K', mod: true)],
    argsSchema: _linkSchema,
    enabled: (ed, a) =>
        textEditingOf(ed).isEditing || ed.selectedElementIds.isNotEmpty,
    reason: (l, ed) => l.reasonSelectTextOrObject,
    run: (ctx, ed, a) async {
      if (!textEditingOf(ed).isEditing) return _setElementLink(ctx, ed, a);
      final f = TextFormatter(ctx, ed);
      final st = TextFormatState.of(f.scope);
      final choice = await _linkChoice(ctx, ed, a, current: st.link);
      if (choice == null) return const CommandResult.cancelled();
      final value = switch (choice) {
        UrlLink(:final url) => core.SlidesText.link(_withScheme(url)),
        SlideLink(:final slideId) => core.SlidesText.link(
          'slide:${_b62(slideId)}',
        ),
        ActionLink() => null,
        RemoveLink() => null,
      };
      if (choice is RemoveLink) {
        _removeTextLink(f);
        return ok();
      }
      if (value == null) return const CommandResult.failed('Invalid link');
      final r = f.scope.targets.single;
      if (r.collapsed) {
        _insertLinkedText(ctx, ed, f, value as String, choice);
      } else {
        f.inline({'link': value});
      }
      return ok();
    },
  ),
  _text(
    'slides.text.removeLink',
    label: (l) => l.cmdTextRemoveLink,
    icon: LucideIcons.unlink,
    run: (ctx, ed, a, f) {
      _removeTextLink(f);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.element.setLink',
    label: (l) => l.cmdElementSetLink,
    icon: LucideIcons.link,
    categoryOf: SlidesCategory.format,
    mutates: true,
    argsSchema: _linkSchema,
    enabled: (ed, a) => _linkable(ed).isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    run: _setElementLink,
  ),
  SlidesCommand(
    'slides.element.removeLink',
    label: (l) => l.cmdElementRemoveLink,
    icon: LucideIcons.unlink,
    categoryOf: SlidesCategory.format,
    mutates: true,
    enabled: (ed, a) =>
        _linkable(ed).any((id) => ed.model.element(id)?.linkJson != null),
    reason: (l, ed) => l.reasonNoLink,
    run: (ctx, ed, a) {
      ed.apply(
        ctx,
        SetElementProps(_linkable(ed), linkJson: const Patch(null)),
      );
      return ok();
    },
  ),

  // ---- Placeholders (03 §6.2)
  SlidesCommand(
    'slides.element.resetPlaceholder',
    label: (l) => l.cmdElementResetPlaceholder,
    icon: LucideIcons.layoutTemplate,
    categoryOf: SlidesCategory.format,
    mutates: true,
    enabled: (ed, a) => _placeholders(ed).isNotEmpty,
    reason: (l, ed) => l.reasonSelectPlaceholder,
    run: (ctx, ed, a) {
      ed.apply(ctx, ResetPlaceholders(_placeholders(ed)));
      return ok();
    },
  ),
];

// ---------------------------------------------------------------- helpers

typedef _TextRun =
    FutureOr<CommandResult> Function(
      CommandContext ctx,
      DeckEditorController ed,
      JsonArgs args,
      TextFormatter f,
    );

/// A text format command: enabled with a text selection or text-capable
/// elements; runs [run] with a [TextFormatter] and toasts skipped
/// soft-locked bodies.
SlidesCommand _text(
  String id, {
  required SlidesText label,
  required _TextRun run,
  IconData? icon,
  JsonSchema argsSchema = JsonSchema.empty,
  List<KeyBinding> defaultBindings = const [],
  List<ArgsKeyBinding> argBindings = const [],
  bool Function(TextFormatState st, JsonArgs a)? checked,
}) => SlidesCommand(
  id,
  label: label,
  icon: icon,
  categoryOf: SlidesCategory.text,
  mutates: true,
  argsSchema: argsSchema,
  defaultBindings: defaultBindings,
  argBindings: argBindings,
  enabled: (ed, a) => !TextFormatScope.of(ed).isEmpty,
  reason: (l, ed) => l.reasonSelectText,
  checked: checked == null
      ? null
      : (ed, a) {
          final scope = TextFormatScope.of(ed);
          return scope.isEmpty ? false : checked(TextFormatState.of(scope), a);
        },
  run: (ctx, ed, a) async {
    final f = TextFormatter(ctx, ed);
    if (f.scope.isEmpty) {
      return CommandResult.failed(slidesL10nOf(ed.services).reasonSelectText);
    }
    final r = await run(ctx, ed, a, f);
    final skipped = f.scope.skipped;
    if (skipped.isNotEmpty && !ctx.source.isAgent) {
      ed.services.toasts.show(
        slidesL10nOf(
          ed.services,
        ).toastSkippedLocked(skipped.length, skipped.first),
      );
    }
    return r;
  },
);

/// A toggled inline format (checked when every selected character has it).
SlidesCommand _toggle(
  String id,
  SlidesText label,
  IconData icon,
  List<KeyBinding> bindings,
  bool Function(TextFormatState st) isOn,
  Map<String, Object?> Function(TextFormatter f, bool on) attrs,
) => _text(
  id,
  label: label,
  icon: icon,
  defaultBindings: bindings,
  checked: (st, a) => isOn(st),
  run: (ctx, ed, a, f) {
    final on = !isOn(TextFormatState.of(f.scope));
    f.inline(attrs(f, on));
    return ok();
  },
);

String? _caps(String? v) => switch (v) {
  'upper' || 'all' => 'all',
  'smallCaps' || 'small' => 'small',
  'title' => 'title',
  _ => null,
};

String? _listOf(String? type) => switch (type) {
  'bullet' => 'bullet',
  'number' || 'ordered' => 'ordered',
  'check' || 'unchecked' => 'check',
  _ => null,
};

bool _validColor(String v) => ColorRef.tryParse(v) != null;

/// The font choices: theme fonts, then the bundled families.
Map<String, String> fontOptions(SlidesLocalizations l) => {
  '@heading': l.fontThemeHeading,
  '@body': l.fontThemeBody,
  '@mono': l.fontThemeMono,
  for (final f in SlidesFonts.families) f: f,
};

/// The label of list style [key].
String listStyleLabel(SlidesLocalizations l, String key) => switch (key) {
  'disc' => '•  ${l.listStyleDisc}',
  'circle' => '◦  ${l.listStyleCircle}',
  'square' => '▪  ${l.listStyleSquare}',
  'dash' => '–  ${l.listStyleDash}',
  'arrow' => '→  ${l.listStyleArrow}',
  'check' => '✓  ${l.listStyleCheck}',
  'star' => '★  ${l.listStyleStar}',
  'none' => l.listStyleNone,
  'decimal' => '1. 2. 3.',
  'lowerAlpha' => 'a. b. c.',
  'upperAlpha' => 'A. B. C.',
  'lowerRoman' => 'i. ii. iii.',
  'upperRoman' => 'I. II. III.',
  _ => key,
};

Future<String?> _ask(
  CommandContext ctx, {
  required String key,
  required SlidesText title,
  required SlidesText label,
  String? initial,
  String? Function(String value)? validator,
}) async {
  final dc = ctx.dialogContext;
  if (dc == null || !dc.mounted || ctx.source.isAgent) return null;
  final l = slidesL10n(dc);
  return showTextValueDialog(
    dc,
    dialogKey: key,
    title: title(l),
    label: label(l),
    initial: initial ?? '',
    validator: validator,
  );
}

Future<double?> _askNumber(
  CommandContext ctx, {
  required String key,
  required SlidesText title,
  required SlidesText label,
  required num? initial,
  required num min,
  required num max,
  int fractionDigits = 0,
}) async {
  final dc = ctx.dialogContext;
  if (dc == null || !dc.mounted) return null;
  final l = slidesL10n(dc);
  final v = await _ask(
    ctx,
    key: key,
    title: title,
    label: label,
    initial: initial == null
        ? ''
        : (fractionDigits == 0
              ? '${initial.round()}'
              : initial.toStringAsFixed(fractionDigits)),
    validator: (s) {
      final n = num.tryParse(s.trim());
      return n == null || n < min || n > max
          ? l.validationNumberRange('$min', '$max')
          : null;
    },
  );
  return v == null ? null : num.tryParse(v)?.toDouble();
}

/// Text box insertion (03 §6.1): with a point (the armed tool's click or
/// drag, MCP) the box is created there; from a menu, the toolbar or the
/// T key the text box tool is armed (toggled); from the palette or an
/// agent a 960 × 120 su box goes to the slide center.
Future<CommandResult> _insertTextBox(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a,
) async {
  final slideId = ed.surfaceId;
  if (slideId == null) return const CommandResult.failed('No slide');
  final x = (a.values['x'] as num?)?.toDouble();
  final y = (a.values['y'] as num?)?.toDouble();
  final text = a.string('text');
  final pointer = switch (ctx.source) {
    InvocationSource.menu ||
    InvocationSource.toolbar ||
    InvocationSource.shortcut ||
    InvocationSource.contextMenu ||
    InvocationSource.ui => true,
    _ => false,
  };
  if (x == null && y == null && pointer && text == null) {
    ed.armTool(ed.armedTool == 'text' ? null : 'text');
    return ok({'armed': ed.armedTool == 'text'});
  }
  final slide = ed.resolver.resolve(slideId);
  if (slide == null) return const CommandResult.failed('No slide');
  final b = slide.bounds;
  final insets =
      slide.theme.shapeStyles.text.textStyle?.insets ?? defaultTextInsets;
  final minH = insets[0] + insets[2] + 1;
  var width = (a.values['width'] as num?)?.toDouble();
  var height = (a.values['height'] as num?)?.toDouble();
  final atPoint = x != null || y != null;
  final auto = atPoint && width == null;
  if (!atPoint) {
    width ??= 960;
    height ??= 120;
  }
  final w = width ?? insets[1] + insets[3] + 1;
  final h = (height ?? minH) < minH ? minH : (height ?? minH);
  final left = x ?? b.x + (b.width - w) / 2;
  final top = y ?? b.y + (b.height - h) / 2;
  ed.armTool(null);
  final plan = ed.apply(
    ctx,
    InsertElements(ownerKind: ed.surfaceKind, slideId, [
      ElementSpec(
        kind: ElementKind.text,
        x: left,
        y: top,
        width: w,
        height: h,
        columns: {
          'textStyleJson': jsonEncode({
            'v': 1,
            'autofit': 'resize',
            if (auto) 'wrap': false,
          }),
          if (text != null && text.isNotEmpty)
            'text': jsonEncode([
              {'insert': '$text\n'},
            ]),
        },
      ),
    ]),
  );
  final id = _insertedId(plan);
  if (id == null) return const CommandResult.failed('Not inserted');
  final host = textEditingOf(ed);
  final canvas = SlideCanvasController.of(ed);
  if (!ctx.source.isAgent && canvas != null && host.canEdit(id)) {
    await host.begin(id);
  } else {
    canvas?.selection.select([id]);
    if (canvas == null) ed.selectElements([id]);
  }
  return ok({'elementId': id});
}

String? _insertedId(SlidesPlan plan) {
  final ids = plan.result['elementIds'];
  return ids is List && ids.isNotEmpty ? '${ids.first}' : null;
}

const _linkSchema = JsonSchema.object(
  properties: {
    'url': JsonSchema.string(description: 'https://…, mailto:…'),
    'slideId': JsonSchema.string(description: 'A slide of this deck.'),
    'action': JsonSchema.string(
      enumValues: ['next', 'previous', 'first', 'last', 'end'],
      description: 'Elements only: what a click does when presenting.',
    ),
  },
);

/// The selected elements an element link applies to (03 §6.9).
List<String> _linkable(DeckEditorController ed) => [
  for (final id in ed.selectedElementIds)
    if (ed.model.element(id) case final e?)
      if (!e.locked && e.kind != ElementKind.group) id,
];

/// The selected placeholder instances (03 §6.2 *Reset to layout*).
List<String> _placeholders(DeckEditorController ed) => [
  for (final id in ed.selectedElementIds)
    if (ed.model.element(id) case final e?)
      if (e.placeholderOf != null && e.slideId != null) id,
];

String _withScheme(String url) {
  final t = url.trim();
  if (t.contains(':')) return t;
  if (t.contains('@') && !t.contains('/')) return 'mailto:$t';
  return 'https://$t';
}

String _b62(String uuid) => Base62Uuid.encode(uuid);

Future<LinkChoice?> _linkChoice(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a, {
  String? current,
  bool actions = false,
  bool canRemove = false,
}) async {
  final url = a.string('url');
  if (url != null) return UrlLink(url);
  final slide = a.string('slideId');
  if (slide != null) {
    return ed.order.entry(slide) == null ? null : SlideLink(slide);
  }
  final action = a.string('action');
  if (action != null) return actions ? ActionLink(action) : null;
  final dc = ctx.dialogContext;
  if (dc == null || !dc.mounted || ctx.source.isAgent) return null;
  String? slideId;
  var initialUrl = current ?? '';
  if (current != null && current.startsWith('slide:')) {
    initialUrl = '';
    final b62 = current.substring(6);
    for (final e in ed.order.entries) {
      if (_b62(e.id) == b62) slideId = e.id;
    }
  }
  return showLinkDialog(
    dc,
    ed,
    initialUrl: initialUrl,
    initialSlideId: slideId,
    actions: actions,
    canRemove: canRemove || current != null,
  );
}

Future<CommandResult> _setElementLink(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a,
) async {
  final ids = _linkable(ed);
  if (ids.isEmpty) {
    return CommandResult.failed(slidesL10nOf(ed.services).reasonSelectObject);
  }
  final cur = ed.model.element(ids.first)?.linkJson;
  Map<String, Object?>? curMap;
  try {
    final d = cur == null ? null : jsonDecode(cur);
    if (d is Map) curMap = d.cast<String, Object?>();
  } on FormatException {
    curMap = null;
  }
  final choice = await _linkChoice(
    ctx,
    ed,
    a,
    current: curMap?['url'] as String?,
    actions: true,
    canRemove: cur != null,
  );
  if (choice == null) {
    return a.values.isEmpty
        ? const CommandResult.cancelled()
        : const CommandResult.failed('Invalid link');
  }
  final Map<String, Object?>? link = switch (choice) {
    UrlLink(:final url) => () {
      final v = core.SlidesText.link(_withScheme(url));
      return v == null ? null : {'v': 1, 'url': v};
    }(),
    SlideLink(:final slideId) => {'v': 1, 'slideId': slideId},
    ActionLink(:final action) => {'v': 1, 'action': action},
    RemoveLink() => null,
  };
  if (link == null && choice is! RemoveLink) {
    return const CommandResult.failed('Invalid link');
  }
  ed.apply(
    ctx,
    SetElementProps(
      ids,
      linkJson: Patch(link == null ? null : jsonEncode(link)),
    ),
  );
  return ok();
}

/// Removes inline links in the scope; a collapsed caret removes the link
/// run around it.
void _removeTextLink(TextFormatter f) {
  final r = f.scope.targets.isEmpty ? null : f.scope.targets.first;
  final editing = f.editing;
  if (editing != null && r != null && r.collapsed) {
    editing.commit();
    final body = r.currentBody(f.ed.model);
    for (final p in paragraphsOf(body)) {
      for (final run in p.runs) {
        if (run.inline['link'] != null &&
            r.start! >= run.start &&
            r.start! <= run.end) {
          f.ed.apply(
            f.ctx,
            FormatText(
              [r.target],
              const {'link': null},
              start: run.start,
              length: run.end - run.start,
            ),
          );
          return;
        }
      }
    }
    return;
  }
  f.inline(const {'link': null});
}

/// Mod+K with a caret: the link's text (the URL or the slide's title) is
/// inserted with the link (one step).
void _insertLinkedText(
  CommandContext ctx,
  DeckEditorController ed,
  TextFormatter f,
  String link,
  LinkChoice choice,
) {
  final editing = f.editing!;
  editing.commit();
  final at = f.scope.targets.single.start!;
  final label = switch (choice) {
    UrlLink(:final url) => url,
    SlideLink(:final slideId) =>
      ed.order.entry(slideId) == null
          ? link
          : slidesL10nOf(
              ed.services,
            ).slideNumberLabel(ed.order.indexOf(slideId) + 1),
    _ => link,
  };
  final doc = core.SlidesText.parse(
    f.scope.targets.single.currentBody(ed.model),
  );
  final change = Delta()
    ..retain(at)
    ..insert(label, {'link': link});
  ed.apply(
    ctx,
    SetText(editing.target, core.SlidesText.encode(doc.compose(change))),
  );
  editing.selectRange(at + label.length);
}
