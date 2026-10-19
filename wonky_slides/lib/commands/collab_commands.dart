import 'dart:async';

import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../features/canvas/canvas_interactions.dart';
import '../features/collab/collab_canvas_layer.dart';
import '../features/collab/slides_collab.dart';
import '../features/present/active_presentation.dart';
import '../features/present/platform/present_platform.dart';
import '../features/text_editing/text_editing_host.dart';
import '../l10n/slides_l10n.dart';
import 'slides_command.dart';

const _session = JsonSchema.object(
  properties: {
    'sessionId': JsonSchema.string(
      minLength: 1,
      description: 'Presence session id of the participant.',
    ),
  },
  required: ['sessionId'],
);

/// Presence and soft-lock commands (Slides 09 §1.3–§1.6, §2.2, §7):
/// jump to and follow collaborators, follow a presenter, *Edit anyway*.
/// Registers the collaboration layer of the canvas.
List<Command<CommandArgs>> collabCommands(ShellServices s) {
  CanvasInteractions.register(CollabCanvasLayer.new);
  return [
    SlidesCommand(
      'slides.presence.jumpTo',
      label: (l) => l.cmdPresenceJumpTo,
      icon: LucideIcons.locateFixed,
      categoryOf: SlidesCategory.view,
      argsSchema: _session,
      showInPalette: false,
      run: (ctx, ed, a) {
        final c = SlidesCollab.of(ed);
        if (c == null || !c.presence.jumpTo(a.requireString('sessionId'))) {
          return const CommandResult.failed('Participant not found');
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.presence.follow',
      label: (l) => l.cmdPresenceFollow,
      icon: LucideIcons.eye,
      categoryOf: SlidesCategory.view,
      argsSchema: _session,
      showInPalette: false,
      run: (ctx, ed, a) {
        final c = SlidesCollab.of(ed);
        if (c == null || !c.presence.follow(a.requireString('sessionId'))) {
          return const CommandResult.failed('Participant not found');
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.presence.unfollow',
      label: (l) => l.cmdPresenceUnfollow,
      icon: LucideIcons.eyeOff,
      categoryOf: SlidesCategory.view,
      enabled: (ed, _) => SlidesCollab.of(ed)?.presence.following.value != null,
      run: (ctx, ed, a) {
        SlidesCollab.of(ed)?.presence.unfollow();
        return ok();
      },
    ),
    SlidesCommand(
      'slides.presence.followPresenter',
      label: (l) => l.cmdPresenceFollowPresenter,
      icon: LucideIcons.presentation,
      categoryOf: SlidesCategory.present,
      argsSchema: _session,
      showInPalette: false,
      run: (ctx, ed, a) async {
        final c = SlidesCollab.of(ed);
        final id = a.requireString('sessionId');
        final presenting = c?.presence.cursorOf(id)?.cursor.presenting;
        if (c == null || presenting == null) {
          ed.services.toasts.show(slidesL10nOf(s).toastPresenterNotFound);
          return const CommandResult.failed('Not presenting');
        }
        final session = presenting.presentationId;
        if (session != null) {
          if (activePresentation.value != null) {
            return const CommandResult.failed('Already presenting');
          }
          // Follower mode (SL-37, 09 §1.6, 10 §6.3): joins their
          // presentation session as a follower; slides and build steps
          // track the presenter, navigation browses away locally.
          c.presence.unfollow();
          unawaited(PresentPlatform.instance.requestFullscreen());
          s.router.go(
            '${s.config.itemPath(ed.session.itemUuid.uuid)}/present'
            '?view=follow&session=$session',
          );
          return ok();
        }
        // Presenting without a session: follow their slide in the editor.
        return c.presence.follow(id)
            ? ok()
            : const CommandResult.failed('Participant not found');
      },
    ),
    SlidesCommand(
      'slides.presence.returnToPresenter',
      label: (l) => l.cmdPresenceReturnToPresenter,
      icon: LucideIcons.undo2,
      categoryOf: SlidesCategory.present,
      keyScope: SlidesKeyScopes.present,
      defaultBindings: const [KeyBinding('R', shift: true)],
      enabled: (ed, a) =>
          activePresentation.value?.controller?.browsing ?? false,
      run: (ctx, ed, a) {
        final c = activePresentation.value?.controller;
        if (c == null || !c.browsing) {
          return const CommandResult.failed('Not browsing away');
        }
        c.returnToPresenter();
        return ok();
      },
    ),
    SlidesCommand(
      'slides.text.editAnyway',
      label: (l) => l.cmdTextEditAnyway,
      icon: LucideIcons.pencilLine,
      categoryOf: SlidesCategory.text,
      showInPalette: false,
      requiredRole: Role.editor,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementId': JsonSchema.string(
            minLength: 1,
            description:
                'The text box, shape or table being edited by someone '
                'else (default: the single selected element).',
          ),
          'rowId': JsonSchema.string(description: 'Table cell row axis id.'),
          'columnId': JsonSchema.string(
            description: 'Table cell column axis id.',
          ),
        },
      ),
      enabled: (ed, a) => ed.canEdit,
      run: (ctx, ed, a) async {
        final c = SlidesCollab.of(ed);
        if (c == null) return const CommandResult.failed('Not available');
        final prompt = c.locks.prompt.value;
        final id =
            a.string('elementId') ??
            prompt?.target.elementId ??
            (ed.selectedElementIds.length == 1
                ? ed.selectedElementIds.single
                : null);
        if (id == null) {
          return CommandResult.failed(
            slidesL10nOf(ed.services).errorSelectTextBox,
          );
        }
        final row = a.string('rowId');
        final col = a.string('columnId');
        final target = row != null && col != null
            ? TextLockTarget.cell(id, row, col)
            : prompt?.target.elementId == id
            ? prompt!.target
            : TextLockTarget.element(id);
        final started = await editAnyway(c, target);
        return started ? ok() : const CommandResult.failed('Cannot edit');
      },
    ),
  ];
}
