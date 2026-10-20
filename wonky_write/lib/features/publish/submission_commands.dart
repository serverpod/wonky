import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show SubmissionDeliveryState, SubmissionStatus;
import 'package:wonky_core/wonky_core.dart';

import '../../commands/write_command.dart';
import '../../l10n/write_l10n.dart';
import '../screen/write_document_controller.dart';
import 'submit_dialog.dart';

/// The commands of a document's submission to a publication (specs/18
/// §4.4). Submitting and withdrawing reach the blog and are not undoable;
/// disconnecting is.
List<Command<CommandArgs>> writeSubmissionCommands(ShellServices services) {
  String? reason(WriteLocalizations l, WriteDocumentController doc) {
    final c = doc.submission;
    final v = c.view;
    if (v == null) return l.submitReasonNone;
    if (!c.online) return l.submitReasonOffline;
    if (!v.accepting) return l.submitReasonClosed(v.publicationName);
    if (v.status == SubmissionStatus.declined) {
      return l.submitReasonDeclined(v.publicationName);
    }
    if (!c.canSubmit) return l.submitReasonNoChanges;
    return null;
  }

  return [
    WriteCommand(
      'write.submission.submit',
      label: (l) => l.cmdSubmissionSubmit,
      icon: LucideIcons.send,
      categoryName: (l) => l.categoryFile,
      requiredRole: Role.editor,
      enabled: (doc, _) => doc.submission.canSubmit,
      reason: (l, doc, _) => reason(l, doc),
      run: (ctx, doc, _) async {
        final c = ctx.dialogContext;
        if (c == null || !c.mounted) return const CommandResult.cancelled();
        final view = await showSubmitDialog(c, services, doc);
        if (view == null) return const CommandResult.cancelled();
        final l = writeL10nOf(services);
        services.toasts.show(
          view.delivery == SubmissionDeliveryState.pending
              ? l.submitPending(view.publicationName)
              : l.submitDone(view.publicationName),
        );
        return CommandResult.ok({'status': view.status.name});
      },
    ),
    WriteCommand(
      'write.submission.withdraw',
      label: (l) => l.cmdSubmissionWithdraw,
      icon: LucideIcons.undo2,
      categoryName: (l) => l.categoryFile,
      requiredRole: Role.editor,
      enabled: (doc, _) => doc.submission.canWithdraw,
      reason: (l, doc, _) => doc.submission.online
          ? l.submitReasonNotInReview
          : l.submitReasonOffline,
      run: (ctx, doc, _) async {
        final v = doc.submission.view;
        final c = ctx.dialogContext;
        if (v == null) return const CommandResult.cancelled();
        final l = writeL10nOf(services);
        if (c != null && c.mounted && !ctx.source.isAgent) {
          final ok = await confirmDialog(
            c,
            title: l.withdrawTitle(v.publicationName),
            description: l.withdrawBody(v.publicationName),
            confirmLabel: l.withdrawButton,
            destructive: true,
          );
          if (!ok) return const CommandResult.cancelled();
        }
        await doc.submission.withdraw();
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.submission.disconnect',
      label: (l) => l.cmdSubmissionDisconnect,
      icon: LucideIcons.unlink,
      categoryName: (l) => l.categoryFile,
      requiredRole: Role.editor,
      isUndoable: true,
      enabled: (doc, _) => doc.submission.canDisconnect,
      reason: (l, doc, _) => doc.submission.online
          ? l.submitReasonWithdrawFirst
          : l.submitReasonOffline,
      undoLabelOf: (l, _) => l.cmdSubmissionDisconnect,
      run: (ctx, doc, _) async {
        await doc.submission.disconnect();
        ctx.record(SubmissionUndoEntry(itemUuid: doc.itemUuid.uuid));
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.submission.showStatus',
      label: (l) => l.cmdSubmissionStatus,
      icon: LucideIcons.newspaper,
      categoryName: (l) => l.categoryFile,
      enabled: (doc, _) => doc.submission.hasSubmission,
      reason: (l, _, _) => l.submitReasonNone,
      run: (ctx, doc, _) async {
        final v = doc.submission.view;
        if (v == null) return const CommandResult.cancelled();
        // The popover opens from the title row; agents get the status.
        doc.submission.requestPopover();
        return CommandResult.ok({
          'publication': v.publicationName,
          'status': v.status.name,
          'publicUrl': v.publicUrl,
          'lastMessage': v.lastMessage,
        });
      },
    ),
  ];
}
