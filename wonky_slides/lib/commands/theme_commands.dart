import 'dart:convert';

import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/clipboard.dart' show SlidesClipboardCodec;
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_sync_models/ids.dart' show SlidesIds;

import '../config/panels/slides_panels.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/page_setup/numbering_dialog.dart';
import '../features/page_setup/page_setup_dialog.dart';
import '../features/themes/theme_import.dart';
import '../l10n/slides_l10n.dart' show slidesL10nOf;
import 'slides_command.dart';

/// Themes, layouts, backgrounds and page setup (Slides 05 §2.4, §4–§5, §7,
/// §9; 04 §7.4, §12, §13.1, §13.3; SL-17).
///
/// - `slides.panel.themes` opens the Themes panel.
/// - `slides.theme.apply {builtin | themeId | source, scope, slideIds}`
///   copies a built-in theme in (deterministic ids, repeated applies merge)
///   and/or applies a deck theme to all or the selected slides, remapping
///   layouts by key (05 §5.4); scope *all* makes it the default theme.
/// - `slides.theme.import {itemUuid?, themeId?, apply?}` copies a theme of
///   another presentation (picker and chooser without arguments).
/// - `slides.theme.rename|duplicate|setDefault|delete|removeUnused`.
/// - `slides.deck.setAppearance {appearance?}` (omitted = toggle).
/// - `slides.slide.applyLayout {layoutId, slideIds?}`,
///   `slides.slide.resetToLayout {slideIds?}`.
/// - `slides.slide.setBackground {color? | fill? | reset?, slideIds?}`,
///   `slides.slide.applyBackgroundToAll`, `slides.slide.setHideMasterElements`.
/// - `slides.file.pageSetup` (dialog) and `slides.deck.setSize {preset,
///   width?, height?, scaleContent?}`.
/// - `slides.deck.openNumbering` (dialog) and `slides.deck.setNumbering`.
///
/// Without `slideIds` the slide commands act on the navigator's selected
/// slides (else the current slide). Every mutating command is one undo
/// step (all its operations in the command's transaction).
List<Command<CommandArgs>> themeCommands(ShellServices s) => [
  SlidesCommand(
    'slides.panel.themes',
    label: (l) => l.cmdPanelThemes,
    icon: LucideIcons.palette,
    categoryOf: SlidesCategory.view,
    checked: (ed, a) => s.panels.isOpen(SlidesPanels.themes),
    run: (ctx, ed, a) {
      s.panels.open(SlidesPanels.themes);
      return ok();
    },
  ),
  // ---- Themes (05 §9)
  SlidesCommand(
    'slides.theme.apply',
    label: (l) => l.cmdThemeApply,
    icon: LucideIcons.palette,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: JsonSchema.object(
      properties: {
        'builtin': JsonSchema.string(
          description: 'A built-in theme key',
          enumValues: [for (final t in BuiltInThemes.all) t.key],
        ),
        'themeId': const JsonSchema.string(
          description: 'A theme of this presentation',
        ),
        'source': const JsonSchema.object(
          description: '{builtin: key} or {deckThemeId: id} (05 §9)',
          additionalProperties: true,
        ),
        'scope': const JsonSchema.string(enumValues: ['all', 'selected']),
        'slideIds': _ids,
      },
    ),
    run: (ctx, ed, a) {
      final source = a.values['source'];
      final src = source is Map ? source : const <Object?, Object?>{};
      final builtin = a.string('builtin') ?? src['builtin'] as String?;
      var themeId = a.string('themeId') ?? src['deckThemeId'] as String?;
      if ((builtin == null) == (themeId == null)) {
        return const CommandResult.failed('Give builtin or themeId');
      }
      final explicit = a.strings('slideIds');
      final all = explicit.isEmpty && a.string('scope', 'all') == 'all';
      if (builtin != null) {
        final imported = ed.apply(ctx, ImportTheme(builtInKey: builtin));
        themeId = imported.result['themeId']! as String;
      }
      final slides = all
          ? const <String>[]
          : (explicit.isNotEmpty ? explicit : _selectedSlides(ed));
      if (!all && slides.isEmpty) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).errorNoSlidesSelected,
        );
      }
      if (ed.order.length > 0 || !all) {
        ed.apply(ctx, ApplyThemeToSlides(themeId!, slides, setDefault: all));
      } else {
        ed.apply(ctx, SetDeckTheme(themeId!));
      }
      return ok({'themeId': themeId});
    },
  ),
  SlidesCommand(
    'slides.theme.import',
    label: (l) => l.cmdThemeImport,
    icon: LucideIcons.fileInput,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'itemUuid': JsonSchema.string(
          description: 'The presentation to import from',
        ),
        'themeId': JsonSchema.string(description: 'One of its themes'),
        'apply': JsonSchema.boolean(description: 'Also apply it to all slides'),
      },
    ),
    run: (ctx, ed, a) async {
      final l = slidesL10nOf(s);
      final dc = ctx.dialogContext;
      final ui = dc != null && dc.mounted && !ctx.source.isAgent;
      var item = a.string('itemUuid');
      if (item == null) {
        if (!ui) return const CommandResult.failed('itemUuid is required');
        final picked = await ThemeImport.pickPresentation(
          dc,
          s,
          exclude: ed.session.itemUuid,
        );
        if (picked == null) return const CommandResult.cancelled();
        item = picked.uuid.uuid;
      }
      final RemoteDeckThemes source;
      try {
        source = await ThemeImport.fetch(s, UuidValue.withValidation(item));
      } on StateError {
        return CommandResult.failed(l.themeImportOffline);
      }
      var themeId = a.string('themeId');
      if (themeId == null) {
        if (source.themes.length == 1) {
          themeId = source.themes.single['id'] as String?;
        } else if (ui && dc.mounted) {
          themeId = await ThemeImport.chooseTheme(dc, source);
          if (themeId == null) return const CommandResult.cancelled();
        } else {
          return const CommandResult.failed('themeId is required');
        }
      }
      final entry = themeId == null ? null : source.theme(themeId);
      if (entry == null) return const CommandResult.failed('Theme not found');
      final sourceKey = source.sourceKeyOf(themeId!);
      final copyId = SlidesIds.themeCopyId(ed.session.deckId, sourceKey);
      final rehomed = await ThemeImport.rehome(
        s,
        entry,
        themeId: copyId,
        target: ed.session.itemUuid,
      );
      ed.apply(ctx, ImportTheme(themeEntry: rehomed, sourceKey: sourceKey));
      final apply = a.boolean('apply') ?? false;
      if (apply && ed.order.length > 0) {
        ed.apply(ctx, ApplyThemeToSlides(copyId, const [], setDefault: true));
      } else if (!apply && ui) {
        s.toasts.show(
          l.themeImported('${entry['name'] ?? ''}'),
          actionLabel: l.themeApplyToAll,
          onAction: () => s.dispatcher.invoke(
            'slides.theme.apply',
            args: {'themeId': copyId, 'scope': 'all'},
            source: InvocationSource.ui,
          ),
        );
      }
      return ok({'themeId': copyId});
    },
  ),
  SlidesCommand(
    'slides.theme.rename',
    label: (l) => l.cmdThemeRename,
    icon: LucideIcons.pencil,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'themeId': JsonSchema.string(), 'name': JsonSchema.string()},
      required: ['themeId'],
    ),
    enabled: (ed, a) => _theme(ed, a) != null,
    run: (ctx, ed, a) async {
      final t = _theme(ed, a)!;
      var name = a.string('name');
      if (name == null) {
        final dc = ctx.dialogContext;
        if (dc == null || !dc.mounted || ctx.source.isAgent) {
          return const CommandResult.failed('name is required');
        }
        final l = slidesL10nOf(s);
        final r = await showWonkyFormDialog(
          dc,
          WonkyDialogSpec(
            title: l.themeRenameTitle,
            dialogKey: 'dialog.slides.renameTheme',
            fields: [
              TextFieldSpec(
                id: 'name',
                label: l.themeNameLabel,
                initial: t.name,
                maxLength: 100,
                validator: (v) => v.trim().isEmpty ? l.themeNameEmpty : null,
              ),
            ],
            buttons: [
              DialogButtonSpec(
                id: 'cancel',
                label: WonkyAppLocalizations.of(dc).actionCancel,
              ),
              DialogButtonSpec(
                id: 'rename',
                label: l.themeRenameButton,
                primary: true,
              ),
            ],
          ),
        );
        if (r?.buttonId != 'rename') return const CommandResult.cancelled();
        name = r!.text('name');
      }
      if (name.trim() == t.name) return ok();
      ed.apply(ctx, UpdateTheme(t.id, themeName: name));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.theme.duplicate',
    label: (l) => l.cmdThemeDuplicate,
    icon: LucideIcons.copy,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'themeId': JsonSchema.string()},
      required: ['themeId'],
    ),
    enabled: (ed, a) => _theme(ed, a) != null,
    run: (ctx, ed, a) {
      final t = _theme(ed, a)!;
      final l = slidesL10nOf(s);
      final name = l.themeCopyName(t.name);
      final plan = ed.apply(
        ctx,
        ImportTheme(
          themeEntry: SlidesClipboardCodec.themeEntry(ed.model, t),
          themeName: name.length > 100 ? name.substring(0, 100) : name,
        ),
      );
      return ok({'themeId': plan.result['themeId']});
    },
  ),
  SlidesCommand(
    'slides.theme.setDefault',
    label: (l) => l.cmdThemeSetDefault,
    icon: LucideIcons.star,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'themeId': JsonSchema.string()},
      required: ['themeId'],
    ),
    enabled: (ed, a) {
      final t = _theme(ed, a);
      return t != null && t.id != ed.model.indexes.themes.defaultTheme?.id;
    },
    reason: (l, ed) => l.reasonThemeIsDefault,
    run: (ctx, ed, a) {
      ed.apply(ctx, SetDeckTheme(_theme(ed, a)!.id));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.theme.delete',
    label: (l) => l.cmdThemeDelete,
    icon: LucideIcons.trash2,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'themeId': JsonSchema.string()},
      required: ['themeId'],
    ),
    enabled: (ed, a) {
      final t = _theme(ed, a);
      return t != null &&
          ed.model.themes.length > 1 &&
          ed.model.indexes.themes.slidesUsingTheme(t.id) == 0;
    },
    reason: (l, ed) => l.reasonThemeInUse,
    run: (ctx, ed, a) {
      ed.apply(ctx, DeleteTheme(_theme(ed, a)!.id));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.theme.removeUnused',
    label: (l) => l.cmdThemeRemoveUnused,
    icon: LucideIcons.trash2,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    enabled: (ed, a) => unusedThemes(ed.model).isNotEmpty,
    reason: (l, ed) => l.reasonNoUnusedThemes,
    run: (ctx, ed, a) {
      final ids = unusedThemes(ed.model);
      for (final id in ids) {
        ed.apply(ctx, DeleteTheme(id));
      }
      return ok({'removed': ids.length});
    },
  ),
  // ---- Appearance (05 §2.4)
  SlidesCommand(
    'slides.deck.setAppearance',
    label: (l) => l.cmdDeckSetAppearance,
    icon: LucideIcons.sunMoon,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'appearance': JsonSchema.string(
          enumValues: ['light', 'dark'],
          description: 'Omitted = switch to the other appearance.',
        ),
      },
    ),
    checked: (ed, a) {
      final want = a.string('appearance');
      if (want == null) return null;
      return (ed.model.deck?.appearance ?? SlideAppearance.light).name == want;
    },
    run: (ctx, ed, a) {
      final cur = ed.model.deck?.appearance ?? SlideAppearance.light;
      final want = switch (a.string('appearance')) {
        'light' => SlideAppearance.light,
        'dark' => SlideAppearance.dark,
        _ =>
          cur == SlideAppearance.light
              ? SlideAppearance.dark
              : SlideAppearance.light,
      };
      if (want == cur) return ok();
      ed.apply(ctx, SetDeckProps(appearance: want));
      return ok();
    },
  ),
  // ---- Layouts (05 §4, §5.4)
  SlidesCommand(
    'slides.slide.applyLayout',
    label: (l) => l.cmdSlideApplyLayout,
    icon: LucideIcons.layoutTemplate,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'layoutId': JsonSchema.string(), 'slideIds': _ids},
    ),
    enabled: (ed, a) {
      if (_targets(ed, a).isEmpty) return false;
      final id = a.string('layoutId');
      return id == null || ed.model.layout(id) != null;
    },
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) {
      final layoutId = a.string('layoutId');
      if (layoutId == null) {
        // From a menu without a layout: the inspector's layout gallery.
        ed.openInspector(InspectorTab.slide, section: 'layout');
        return ok();
      }
      ed.apply(ctx, SetSlideProps(_targets(ed, a), layoutId: layoutId));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.slide.resetToLayout',
    label: (l) => l.cmdSlideResetToLayout,
    icon: LucideIcons.rotateCcw,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(properties: {'slideIds': _ids}),
    enabled: (ed, a) => _targets(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) {
      ed.apply(ctx, ResetSlideToLayout(_targets(ed, a)));
      return ok();
    },
  ),
  // ---- Background and master elements (04 §7.4)
  SlidesCommand(
    'slides.slide.setBackground',
    label: (l) => l.cmdSlideSetBackground,
    icon: LucideIcons.wallpaper,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'color': JsonSchema.string(
          description: 'A solid color: `theme:bg2`, `#RRGGBB`',
        ),
        'fill': JsonSchema.object(
          description: 'A Fill (02 §5.2)',
          additionalProperties: true,
        ),
        'reset': JsonSchema.boolean(
          description: 'Inherit the layout background again',
        ),
        'slideIds': _ids,
      },
    ),
    enabled: (ed, a) => _targets(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) {
      final color = a.string('color');
      final fill = a.values['fill'];
      final String? json;
      if (a.boolean('reset') ?? false) {
        json = null;
      } else if (color != null || fill is Map) {
        final f = fill is Map
            ? fill.cast<String, Object?>()
            : {'v': 1, 'type': 'solid', 'color': color};
        json = jsonEncode({
          'v': 1,
          'fill': {'v': 1, ...f},
        });
        final sink = IssueSink();
        if (SlideBackground.fromJson(jsonDecode(json), sink) == null ||
            sink.errors.isNotEmpty) {
          return const CommandResult.failed('Invalid background');
        }
      } else {
        // No value: the inspector's background section (04 §7.4).
        ed.openInspector(InspectorTab.slide, section: 'background');
        return ok();
      }
      ed.apply(
        ctx,
        SetSlideProps(_targets(ed, a), backgroundJson: Patch(json)),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.slide.applyBackgroundToAll',
    label: (l) => l.cmdSlideApplyBackgroundToAll,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    enabled: (ed, a) => ed.currentSlideId != null && ed.order.length > 1,
    reason: (l, ed) => l.reasonSelectSlides,
    run: (ctx, ed, a) {
      final cur = ed.model.slide(ed.currentSlideId!)!;
      final others = [
        for (final e in ed.order.entries)
          if (e.id != cur.id && e.slide.backgroundJson != cur.backgroundJson)
            e.id,
      ];
      if (others.isEmpty) return ok();
      ed.apply(
        ctx,
        SetSlideProps(others, backgroundJson: Patch(cur.backgroundJson)),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.slide.setHideMasterElements',
    label: (l) => l.cmdSlideSetHideMasterElements,
    icon: LucideIcons.layers,
    categoryOf: SlidesCategory.slides,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.boolean(description: 'Omitted = toggle'),
        'slideIds': _ids,
      },
    ),
    enabled: (ed, a) => _targets(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectSlides,
    checked: (ed, a) {
      final t = _targets(ed, a);
      if (t.isEmpty) return false;
      return t.every((id) => ed.model.slide(id)?.hideMasterElements ?? false);
    },
    run: (ctx, ed, a) {
      final t = _targets(ed, a);
      final v =
          a.boolean('value') ??
          !t.every((id) => ed.model.slide(id)?.hideMasterElements ?? false);
      ed.apply(ctx, SetSlideProps(t, hideMasterElements: Patch(v)));
      return ok();
    },
  ),
  // ---- Page setup (04 §13.1, 05 §7)
  SlidesCommand(
    'slides.file.pageSetup',
    label: (l) => l.cmdFilePageSetup,
    icon: LucideIcons.ratio,
    categoryOf: SlidesCategory.file,
    mutates: true,
    undoLabelOf: (l, a) => l.undoChangeSlideSize,
    run: (ctx, ed, a) async {
      final dc = ctx.dialogContext;
      if (dc == null || !dc.mounted || ctx.source.isAgent) {
        return const CommandResult.failed(
          'Use slides.deck.setSize {preset, width, height, scaleContent}',
        );
      }
      final choice = await showPageSetupDialog(dc, ed);
      if (choice == null) return const CommandResult.cancelled();
      return _setSize(ctx, ed, choice.size, choice.scaleContent);
    },
  ),
  SlidesCommand(
    'slides.deck.setSize',
    label: (l) => l.cmdDeckSetSize,
    icon: LucideIcons.ratio,
    categoryOf: SlidesCategory.file,
    mutates: true,
    argsSchema: JsonSchema.object(
      properties: {
        'preset': JsonSchema.string(
          enumValues: [for (final k in SlideSizeKind.values) k.name],
        ),
        'width': const JsonSchema.number(description: 'su (custom; 320–7,680)'),
        'height': const JsonSchema.number(description: 'su (custom)'),
        'scaleContent': const JsonSchema.boolean(
          description: 'Scale content to fit (default) or keep frames',
        ),
      },
      required: const ['preset'],
    ),
    run: (ctx, ed, a) {
      final kind = SlideSizeKind.fromName(a.string('preset'));
      if (kind == null) return const CommandResult.failed('Unknown preset');
      final SlideSize size;
      if (kind == SlideSizeKind.custom) {
        final w = (a.values['width'] as num?)?.toDouble() ?? double.nan;
        final h = (a.values['height'] as num?)?.toDouble() ?? double.nan;
        final problem = SlideSize.validate(w, h);
        if (problem != null) return CommandResult.failed(problem);
        size = SlideSize.custom(w.roundToDouble(), h.roundToDouble());
      } else {
        size = SlideSize.preset(kind);
      }
      return _setSize(ctx, ed, size, a.boolean('scaleContent') ?? true);
    },
  ),
  // ---- Slide numbers and footer (04 §13.3, 05 §5.5)
  SlidesCommand(
    'slides.deck.openNumbering',
    label: (l) => l.cmdDeckOpenNumbering,
    icon: LucideIcons.hash,
    categoryOf: SlidesCategory.insert,
    mutates: true,
    undoLabelOf: (l, a) => l.undoNumbering,
    run: (ctx, ed, a) async {
      final dc = ctx.dialogContext;
      if (dc == null || !dc.mounted || ctx.source.isAgent) {
        return const CommandResult.failed('Use slides.deck.setNumbering');
      }
      final c = await showNumberingDialog(dc, ed);
      if (c == null) return const CommandResult.cancelled();
      return _setNumbering(
        ctx,
        ed,
        show: c.showSlideNumbers,
        first: c.firstSlideNumber,
        hideOnTitle: c.hideNumberOnTitle,
        footer: c.footerText,
      );
    },
  ),
  SlidesCommand(
    'slides.deck.setNumbering',
    label: (l) => l.cmdDeckSetNumbering,
    icon: LucideIcons.hash,
    categoryOf: SlidesCategory.insert,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'showSlideNumbers': JsonSchema.boolean(),
        'firstSlideNumber': JsonSchema.integer(minimum: 0, maximum: 9999),
        'hideNumberOnTitle': JsonSchema.boolean(),
        'footerText': JsonSchema.string(
          description: 'Empty = no footer',
          maxLength: 200,
        ),
      },
    ),
    run: (ctx, ed, a) => _setNumbering(
      ctx,
      ed,
      show: a.boolean('showSlideNumbers'),
      first: a.integer('firstSlideNumber'),
      hideOnTitle: a.boolean('hideNumberOnTitle'),
      footer: a.string('footerText')?.trim(),
    ),
  ),
];

const JsonSchema _ids = JsonSchema.array(JsonSchema.string());

/// Theme `themeId` of the args (null when missing).
DeckThemeRec? _theme(DeckEditorController ed, JsonArgs a) {
  final id = a.string('themeId');
  return id == null ? null : ed.model.theme(id);
}

/// The deck's themes no slide uses, except the default theme (kept for new
/// slides), in theme order.
List<String> unusedThemes(DeckModel m) {
  final ix = m.indexes.themes;
  return [
    for (final t in m.themes)
      if (t.id != ix.defaultTheme?.id && ix.slidesUsingTheme(t.id) == 0) t.id,
  ];
}

/// The navigator's selected slides in deck order, else the current slide.
List<String> _selectedSlides(DeckEditorController ed) {
  final sel = ed.selectedSlideIds;
  final ordered = [
    for (final e in ed.order.entries)
      if (sel.contains(e.id)) e.id,
  ];
  if (ordered.isNotEmpty) return ordered;
  final cur = ed.currentSlideId;
  return cur == null ? const [] : [cur];
}

/// `slideIds` (existing ones), else the selected slides.
List<String> _targets(DeckEditorController ed, JsonArgs a) {
  final explicit = a.strings('slideIds');
  if (explicit.isEmpty) return _selectedSlides(ed);
  return [
    for (final id in explicit)
      if (ed.model.slide(id) != null) id,
  ];
}

CommandResult _setSize(
  CommandContext ctx,
  DeckEditorController ed,
  SlideSize size,
  bool scale,
) {
  final d = ed.model.deck;
  if (d != null &&
      d.width == size.width &&
      d.height == size.height &&
      d.sizePreset == size.kind) {
    return ok();
  }
  ed.apply(
    ctx,
    SetDeckProps(
      size: DeckSizeChange(
        size,
        mode: scale ? SizeScaleMode.scale : SizeScaleMode.keep,
      ),
    ),
  );
  return ok();
}

CommandResult _setNumbering(
  CommandContext ctx,
  DeckEditorController ed, {
  bool? show,
  int? first,
  bool? hideOnTitle,
  String? footer,
}) {
  final d = ed.model.deck;
  final op = SetDeckProps(
    showSlideNumbers: show == d?.showSlideNumbers ? null : show,
    firstSlideNumber: first == d?.firstSlideNumber ? null : first,
    hideNumberOnTitle: hideOnTitle == d?.hideNumberOnTitle ? null : hideOnTitle,
    footerText: footer == null || footer == (d?.footerText ?? '')
        ? null
        : Patch(footer.isEmpty ? null : footer),
  );
  ed.apply(ctx, op);
  return ok();
}
