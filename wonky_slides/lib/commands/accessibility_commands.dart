import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../config/panels/slides_panels.dart';
import '../features/accessibility/accessibility_checker.dart';
import '../features/accessibility/accessibility_controller.dart';
import '../features/accessibility/accessibility_panel.dart';
import '../features/canvas/slide_canvas_controller.dart' show selectionOf;
import '../features/editor_screen/deck_editor_controller.dart';
import '../l10n/slides_l10n.dart' show slidesL10nOf;
import 'slides_command.dart';

/// The accessibility checker's commands (Slides 03 §17.4; SL-34):
///
/// - `slides.panel.accessibility` opens the Accessibility panel.
/// - `slides.tools.accessibilityCheck {slideIds?}` checks the deck and
///   returns the report (`errors`, `warnings`, `info`, `issues` with
///   `rule`, `severity`, `slideId`, `elementId`, `message`, `fixable`);
///   from the UI it also opens the panel.
/// - `slides.a11y.goTo {slideId, elementId?}` shows the slide in Normal
///   view and selects the element.
/// - `slides.a11y.fix {rule, slideId, elementId?, altText?, decorative?}`
///   applies the rule's quick fix as one undo step (alt text: the given
///   text or *Decorative*, else the Alt text dialog).
List<Command<CommandArgs>> accessibilityCommands(ShellServices s) => [
  SlidesCommand(
    'slides.panel.accessibility',
    label: (l) => l.cmdPanelAccessibility,
    icon: LucideIcons.accessibility,
    categoryOf: SlidesCategory.view,
    checked: (ed, a) => s.panels.isOpen(SlidesPanels.accessibility),
    run: (ctx, ed, a) {
      s.panels.open(SlidesPanels.accessibility);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.tools.accessibilityCheck',
    label: (l) => l.cmdToolsAccessibilityCheck,
    icon: LucideIcons.accessibility,
    categoryOf: SlidesCategory.tools,
    descriptionText: (l) => l.a11yCheckDescription,
    argsSchema: const JsonSchema.object(
      properties: {
        'slideIds': JsonSchema.array(
          JsonSchema.string(),
          description: 'Only these slides (default: every slide).',
        ),
      },
    ),
    run: (ctx, ed, a) {
      final raw = a.values['slideIds'];
      final only = raw is List ? raw.whereType<String>().toList() : null;
      final AccessibilityReport report;
      if (only == null) {
        report = accessibilityOf(ed).check();
      } else {
        report = AccessibilityChecker.check(
          ed.model,
          resolver: ed.resolver,
          slideIds: only,
        );
      }
      if (!ctx.source.isAgent) s.panels.open(SlidesPanels.accessibility);
      final l = slidesL10nOf(s);
      return ok({
        ...report.toJson(),
        'issues': [
          for (final i in report.issues)
            {...i.toJson(), 'message': a11yMessage(l, i)},
        ],
      });
    },
  ),
  SlidesCommand(
    'slides.a11y.goTo',
    label: (l) => l.cmdA11yGoTo,
    icon: LucideIcons.crosshair,
    categoryOf: SlidesCategory.tools,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'slideId': JsonSchema.string(),
        'elementId': JsonSchema.string(),
      },
      required: ['slideId'],
    ),
    enabled: (ed, a) => ed.order.entry(a.string('slideId') ?? '') != null,
    reason: (l, ed) => l.reasonNoSlides,
    run: (ctx, ed, a) {
      final slide = a.requireString('slideId');
      if (ed.mode != DeckViewMode.normal) ed.setMode(DeckViewMode.normal);
      ed.setCurrentSlide(slide);
      final el = a.string('elementId');
      if (el != null && ed.model.element(el)?.ownerId == slide) {
        selectionOf(ed).select([el]);
      }
      return ok({'slideId': slide, 'selected': ed.selectedElementIds});
    },
  ),
  SlidesCommand(
    'slides.a11y.fix',
    label: (l) => l.cmdA11yFix,
    icon: LucideIcons.wandSparkles,
    categoryOf: SlidesCategory.tools,
    mutates: true,
    showInPalette: false,
    argsSchema: JsonSchema.object(
      properties: {
        'rule': JsonSchema.string(
          enumValues: [
            for (final r in A11yRule.values)
              if (r.fixable) r.name,
          ],
        ),
        'slideId': const JsonSchema.string(),
        'elementId': const JsonSchema.string(),
        'altText': const JsonSchema.string(
          description: 'missingAltText: the alt text to set.',
        ),
        'decorative': const JsonSchema.boolean(
          description: 'missingAltText: mark the object decorative.',
        ),
      },
      required: const ['rule', 'slideId'],
    ),
    enabled: (ed, a) => _fixable(ed, a),
    reason: (l, ed) => l.reasonA11yNoFix,
    run: (ctx, ed, a) async {
      final rule = A11yRule.fromName(a.string('rule'))!;
      final slide = a.requireString('slideId');
      final el = a.string('elementId');
      if (rule == A11yRule.missingAltText) {
        final alt = a.string('altText');
        final decorative = a.boolean('decorative');
        if (alt == null && decorative == null && ctx.source.isAgent) {
          return const CommandResult.failed(
            'altText or decorative is required',
          );
        }
        return ed.invokeCommand(
          'slides.element.editAltText',
          {
            'ids': [el],
            'altText': ?alt,
            'decorative': ?decorative,
          },
          ctx.source,
          ctx.dialogContext,
        );
      }
      final ops = A11yFixes.opsFor(
        ed.model,
        A11yIssue(rule: rule, slideId: slide, elementId: el),
        resolver: ed.resolver,
      );
      if (ops == null) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).errorNothingToFix,
        );
      }
      for (final op in ops) {
        ed.apply(ctx, op);
      }
      if (rule == A11yRule.emptyPlaceholder) {
        selectionOf(ed).select([
          for (final id in ed.selectedElementIds)
            if (id != el) id,
        ]);
      }
      return ok({'rule': rule.name, 'operations': ops.length});
    },
  ),
];

/// Whether `slides.a11y.fix` has something to do for its arguments.
bool _fixable(DeckEditorController ed, JsonArgs a) {
  final rule = A11yRule.fromName(a.string('rule'));
  final slide = a.string('slideId');
  if (rule == null || !rule.fixable || slide == null) return false;
  if (ed.order.entry(slide) == null) return false;
  if (rule == A11yRule.readingOrder) return true;
  final el = a.string('elementId');
  return el != null && ed.model.element(el)?.ownerId == slide;
}
