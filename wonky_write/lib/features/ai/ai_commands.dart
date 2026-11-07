import 'dart:async';

import 'package:flutter/widgets.dart' show IconData;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../../commands/write_command.dart';
import '../../l10n/write_l10n.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show DeltaSelection;
import 'write_ai_controller.dart';
import 'write_ai_icons.dart';

const _rewriteModes = [
  'improve',
  'fixGrammar',
  'shorter',
  'longer',
  'tone',
  'translate',
  'custom',
  'explain',
  'summarize',
];

/// The Write AI commands (Write 09 §6). Previews are not undoable; applying
/// a result is one undo step labelled "AI: …".
List<Command<CommandArgs>> writeAiCommands(ShellServices services) {
  WriteAiController? ai(CommandContext ctx) => WriteAiController.of(ctx);
  WriteLocalizations l10n() => writeL10nOf(services);
  bool on(CommandContext ctx) {
    final a = ai(ctx);
    return a != null && a.shown;
  }

  WriteCommand cmd(
    String id, {
    required WriteText label,
    required FutureOr<CommandResult> Function(
      CommandContext ctx,
      WriteAiController ai,
      JsonArgs args,
    )
    run,
    bool Function(WriteAiController ai, JsonArgs args)? enabled,
    Role role = Role.viewer,
    JsonSchema args = JsonSchema.empty,
    List<KeyBinding> bindings = const [],
    KeyScope scope = KeyScope.global,
    bool palette = true,
    WriteText? description,
    bool needsEditable = false,
    bool undoable = false,
    IconData icon = LucideIcons.sparkles,
  }) => WriteCommand(
    id,
    label: label,
    icon: icon,
    categoryName: (l) => l.categoryAI,
    descriptionText: description,
    requiredRole: role,
    argsSchema: args,
    defaultBindings: bindings,
    keyScope: scope,
    showInPalette: palette,
    needsEditable: needsEditable,
    isUndoable: undoable,
    enabled: (doc, a) {
      final c = WriteAiController.forItem(doc.itemUuid);
      if (c == null || !c.shown) return false;
      return enabled?.call(c, a) ?? c.available;
    },
    reason: (l, doc, a) {
      final c = WriteAiController.forItem(doc.itemUuid);
      if (c == null) return null;
      final s = c.assistant?.status.value;
      if (s != null && !s.available) return s.message;
      return null;
    },
    run: (ctx, doc, a) async {
      final c = ai(ctx);
      if (c == null || !on(ctx)) {
        return CommandResult.failed(l10n().commandToastAiUnavailable);
      }
      return run(ctx, c, a);
    },
  );

  CommandResult ok([Object? data]) =>
      data == null ? const CommandResult.ok() : CommandResult.ok(data);

  return [
    cmd(
      'write.ai.rewriteSelection',
      label: (l) => l.cmdAiRewriteSelection,
      description: (l) => l.cmdAiRewriteSelectionDescription,
      role: Role.commenter,
      args: const JsonSchema.object(
        properties: {
          'mode': JsonSchema.string(enumValues: _rewriteModes),
          'tone': JsonSchema.string(),
          'language': JsonSchema.string(),
          'instruction': JsonSchema.string(),
          'range': JsonSchema.object(
            properties: {
              'start': JsonSchema.integer(minimum: 0),
              'length': JsonSchema.integer(minimum: 1),
            },
            required: ['start', 'length'],
          ),
        },
        required: ['mode'],
      ),
      enabled: (c, a) =>
          c.available && (c.hasSelection || a.values['range'] != null),
      run: (ctx, c, a) async {
        final mode = a.string('mode') ?? 'improve';
        final range = a.values['range'];
        DeltaSelection? sel;
        if (range is Map) {
          final s = (range['start'] as num).toInt();
          final l = (range['length'] as num).toInt();
          sel = DeltaSelection(s, s + l);
          c.doc.editor.select(sel);
        }
        if (mode == 'explain' || mode == 'summarize') {
          unawaited(c.explainSelection(summarize: mode == 'summarize'));
          return ok();
        }
        if (!c.canWrite) {
          return CommandResult.failed(l10n().commandToastReadOnly);
        }
        unawaited(
          c.rewriteSelection(
            mode,
            tone: a.string('tone'),
            language: a.string('language'),
            instruction: a.string('instruction'),
            range: sel,
          ),
        );
        return ok();
      },
    ),
    cmd(
      'write.ai.inline',
      label: (l) => l.cmdAiInline,
      description: (l) => l.cmdAiInlineDescription,
      role: Role.commenter,
      bindings: const [KeyBinding('J', mod: true)],
      scope: KeyScope.editor,
      args: const JsonSchema.object(
        properties: {'prompt': JsonSchema.string()},
      ),
      enabled: (c, a) =>
          c.available &&
          c.canWrite &&
          (c.caretInEmptyParagraph ||
              c.hasSelection ||
              a.string('prompt') != null),
      run: (ctx, c, a) async {
        c.openPrompt();
        final prompt = a.string('prompt');
        if (prompt != null) unawaited(c.submitPrompt(prompt));
        return ok();
      },
    ),
    cmd(
      'write.ai.continue',
      label: (l) => l.cmdAiContinue,
      description: (l) => l.cmdAiContinueDescription,
      role: Role.commenter,
      args: const JsonSchema.object(
        properties: {'maxWords': JsonSchema.integer(minimum: 10, maximum: 300)},
      ),
      enabled: (c, a) => c.available && c.canWrite,
      run: (ctx, c, a) async {
        unawaited(c.continueWriting(maxWords: a.integer('maxWords')));
        return ok();
      },
    ),
    // Quick actions (Write 09 §5.5): no prompt in the chat, one round trip
    // on the fast model; edits arrive as suggestions.
    cmd(
      'write.ai.summarizeDocument',
      icon: WriteAiIcons.summarize,
      label: (l) => l.cmdAiSummarizeDocument,
      description: (l) => l.cmdAiSummarizeDocumentDescription,
      run: (ctx, c, a) async {
        unawaited(c.runQuickAction(AssistantQuickAction.summarize));
        return ok();
      },
    ),
    cmd(
      'write.ai.generateOutline',
      label: (l) => l.cmdAiGenerateOutline,
      args: const JsonSchema.object(
        properties: {'prompt': JsonSchema.string()},
      ),
      run: (ctx, c, a) async {
        unawaited(c.generateOutline(prompt: a.string('prompt')));
        return ok();
      },
    ),
    cmd(
      'write.ai.proofreadDocument',
      icon: WriteAiIcons.proofread,
      label: (l) => l.cmdAiProofreadDocument,
      description: (l) => l.cmdAiProofreadDocumentDescription,
      role: Role.commenter,
      run: (ctx, c, a) async {
        unawaited(c.runQuickAction(AssistantQuickAction.proofread));
        return ok();
      },
    ),
    cmd(
      'write.ai.addressComments',
      icon: WriteAiIcons.addressComments,
      label: (l) => l.cmdAiAddressComments,
      description: (l) => l.cmdAiAddressCommentsDescription,
      role: Role.commenter,
      run: (ctx, c, a) async {
        unawaited(c.runQuickAction(AssistantQuickAction.addressComments));
        return ok();
      },
    ),
    cmd(
      'write.ai.applyStyle',
      icon: WriteAiIcons.applyStyle,
      label: (l) => l.cmdAiApplyStyle,
      description: (l) => l.cmdAiApplyStyleDescription,
      role: Role.commenter,
      run: (ctx, c, a) async {
        unawaited(c.runQuickAction(AssistantQuickAction.applyStyle));
        return ok();
      },
    ),
    cmd(
      'write.ai.openAssistant',
      label: (l) => l.cmdAiOpenAssistant,
      run: (ctx, c, a) {
        c.openPanel();
        return ok();
      },
    ),
    // Style guides (suite 10 §7, Write 09 §5.9).
    cmd(
      'write.ai.manageStyleGuides',
      icon: WriteAiIcons.styleGuides,
      label: (l) => l.cmdAiManageStyleGuides,
      description: (l) => l.cmdAiManageStyleGuidesDescription,
      run: (ctx, c, a) async {
        final context = ctx.dialogContext;
        if (context == null) return const CommandResult.failed('No window');
        await c.openStyleGuides(context);
        return ok();
      },
    ),
    cmd(
      'write.doc.styleGuide',
      label: (l) => l.cmdDocStyleGuide,
      description: (l) => l.cmdDocStyleGuideDescription,
      run: (ctx, c, a) async {
        final context = ctx.dialogContext;
        if (context == null) return const CommandResult.failed('No window');
        await c.openStyleGuides(context);
        return ok();
      },
    ),
    cmd(
      'write.doc.setStyleGuide',
      label: (l) => l.cmdDocSetStyleGuide,
      palette: false,
      role: Role.editor,
      undoable: true,
      args: const JsonSchema.object(
        properties: {
          'ref': JsonSchema.nullable(
            JsonSchema.string(
              description:
                  '`builtin:<key>` or `custom:<uuid>`; null = no style '
                  'guide.',
            ),
          ),
        },
        required: ['ref'],
      ),
      run: (ctx, c, a) async {
        final ref = a.string('ref');
        try {
          await c.setStyleGuide(ref == null || ref.isEmpty ? null : ref);
        } on Object catch (e) {
          return CommandResult.failed(errorMessage(e));
        }
        return ok({'ref': ref});
      },
    ),
    cmd(
      'write.ai.previewReplace',
      label: (l) => l.cmdAiPreviewReplace,
      palette: false,
      role: Role.commenter,
      enabled: (c, a) => c.preview?.canApply ?? false,
      run: (ctx, c, a) => c.replace()
          ? ok()
          : CommandResult.failed(l10n().commandToastNothingToReplace),
    ),
    cmd(
      'write.ai.previewInsertBelow',
      label: (l) => l.cmdAiPreviewInsertBelow,
      palette: false,
      role: Role.commenter,
      enabled: (c, a) => c.preview?.canApply ?? false,
      run: (ctx, c, a) => c.insert(below: true)
          ? ok()
          : CommandResult.failed(l10n().commandToastNothingToInsert),
    ),
    cmd(
      'write.ai.previewRetry',
      label: (l) => l.cmdAiPreviewRetry,
      palette: false,
      enabled: (c, a) => c.preview != null,
      run: (ctx, c, a) async {
        unawaited(c.retry());
        return ok();
      },
    ),
    cmd(
      'write.ai.previewRefine',
      label: (l) => l.cmdAiPreviewRefine,
      palette: false,
      args: const JsonSchema.object(
        properties: {'instruction': JsonSchema.string(minLength: 1)},
        required: ['instruction'],
      ),
      enabled: (c, a) => c.preview?.canApply ?? false,
      run: (ctx, c, a) async {
        unawaited(c.refine(a.requireString('instruction')));
        return ok();
      },
    ),
    cmd(
      'write.ai.previewDiscard',
      label: (l) => l.cmdAiPreviewDiscard,
      palette: false,
      enabled: (c, a) => c.preview != null,
      run: (ctx, c, a) {
        c.discard();
        return ok();
      },
    ),
  ];
}
