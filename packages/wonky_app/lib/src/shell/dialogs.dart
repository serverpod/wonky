import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../data/api.dart';
import '../l10n/wonky_app_localizations.dart';
import 'form_dialog.dart';
import 'shell_services.dart';

/// A yes/no confirmation (destructive actions confirm instead of undo).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? description,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: title,
      description: description,
      dialogKey: 'dialog.confirm',
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(
          id: 'confirm',
          label: confirmLabel,
          primary: true,
          destructive: destructive,
        ),
      ],
    ),
  );
  return r?.buttonId == 'confirm';
}

/// The choice in [confirmExternalLink].
enum ExternalLinkChoice { open, copy, cancel }

/// The external-link confirm popover of suite 03 §1: "Open external link?
/// github.com" with an optional [note], *Open* / *Copy link* / *Cancel*.
/// *Open* opens [url] in the system browser (a new browser tab on the web:
/// external content only), *Copy link* copies it. MCP-operable
/// (`dialog.externalLink`).
Future<ExternalLinkChoice> confirmExternalLink(
  BuildContext context,
  ShellServices s, {
  required String url,
  String? note,
}) async {
  final l = WonkyAppLocalizations.of(context);
  final host = Uri.tryParse(url)?.host ?? '';
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.externalLinkTitle,
      description: [if (host.isNotEmpty) host else url, ?note].join(' — '),
      dialogKey: 'dialog.externalLink',
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'copy', label: l.cmdCopyLink),
        DialogButtonSpec(id: 'open', label: l.externalLinkOpen, primary: true),
      ],
    ),
  );
  switch (r?.buttonId) {
    case 'open':
      await s.crossApp.openExternal(url);
      return ExternalLinkChoice.open;
    case 'copy':
      await Clipboard.setData(ClipboardData(text: url));
      s.toasts.show(l.toastLinkCopied);
      return ExternalLinkChoice.copy;
    default:
      return ExternalLinkChoice.cancel;
  }
}

/// A single text field dialog (rename, new folder, name version).
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String initial = '',
  String? placeholder,
  String? Function(String)? validator,
  String dialogKey = 'dialog.text',
  int? maxLength = 255,
}) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: title,
      dialogKey: dialogKey,
      fields: [
        TextFieldSpec(
          id: 'value',
          label: label,
          initial: initial,
          placeholder: placeholder,
          maxLength: maxLength,
          validator:
              validator ?? (v) => v.trim().isEmpty ? l.errorRequired : null,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'ok', label: confirmLabel, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return r!.text('value').trim();
}

/// Validates drive item names (1–255 chars, trimmed, no `/`).
String? Function(String) itemNameValidator(WonkyAppLocalizations l) => (v) {
  final t = v.trim();
  if (t.isEmpty) return l.errorRequired;
  if (t.contains('/')) return l.errorNameSlash;
  if (t.length > 255) return l.errorNameTooLong;
  return null;
};

Future<String?> showNameVersionDialog(
  BuildContext context,
  ShellServices s, {
  String initial = '',
}) {
  final l = WonkyAppLocalizations.of(context);
  return showTextInputDialog(
    context,
    title: l.nameVersionTitle,
    label: l.nameVersionLabel,
    confirmLabel: l.actionSave,
    initial: initial.isEmpty
        ? intl.DateFormat.yMMMd().add_jm().format(DateTime.now())
        : initial,
    dialogKey: 'dialog.nameVersion',
    maxLength: 200,
  );
}

/// Help › What's new.
Future<void> showWhatsNewDialog(BuildContext context, ShellServices s) {
  final l = WonkyAppLocalizations.of(context);
  return showShadDialog<void>(
    context: context,
    builder: (context) => ShadDialog(
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.whatsNewTitle),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionClose),
        ),
      ],
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            for (final item in [
              l.whatsNew1,
              l.whatsNew2,
              l.whatsNew3,
              l.whatsNew4,
            ])
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(LucideIcons.sparkle, size: 14),
                  ),
                  Expanded(child: Text(item)),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

/// Human text of an activity event.
String activityText(WonkyAppLocalizations l, ActivityEventView e) {
  final who =
      e.actor?.displayName ??
      (e.actorKind.name == 'system' ? l.activitySystem : l.someone);
  return switch (e.type) {
    ActivityType.created => l.activityCreated(who),
    ActivityType.renamed => l.activityRenamed(who),
    ActivityType.moved => l.activityMoved(who),
    ActivityType.edited => l.activityEdited(who),
    ActivityType.commented => l.activityCommented(who),
    ActivityType.shared => l.activityShared(who),
    ActivityType.unshared => l.activityUnshared(who),
    ActivityType.restoredVersion => l.activityRestoredVersion(who),
    ActivityType.trashed => l.activityTrashed(who),
    ActivityType.restored => l.activityRestored(who),
    ActivityType.exported => l.activityExported(who),
    ActivityType.uploaded => l.activityUploaded(who),
    ActivityType.submission => _submissionActivity(l, e, who),
  };
}

/// (M14) Submitted to, withdrawn from or disconnected from a publication,
/// or the publication's status change (specs/18 §6).
String _submissionActivity(
  WonkyAppLocalizations l,
  ActivityEventView e,
  String who,
) {
  Map<String, Object?> m;
  try {
    final v = jsonDecode(e.summary);
    m = v is Map ? v.cast<String, Object?>() : const {};
  } on FormatException {
    m = const {};
  }
  final pub = '${m['publication'] ?? ''}';
  return switch (m['action']) {
    'withdrawn' => l.activitySubmissionWithdrawn(who, pub),
    'disconnected' => l.activitySubmissionDisconnected(who, pub),
    'reconnected' => l.activitySubmissionReconnected(who, pub),
    'status' => l.activitySubmissionStatus(
      pub,
      submissionStatusLabel(
        l,
        SubmissionStatus.values.asNameMap()['${m['status']}'] ??
            SubmissionStatus.inReview,
      ),
    ),
    _ => l.activitySubmitted(who, pub),
  };
}

/// The label of a submission status (specs/18 §2.1).
String submissionStatusLabel(
  WonkyAppLocalizations l,
  SubmissionStatus status,
) => switch (status) {
  SubmissionStatus.draft => l.submissionStatusDraft,
  SubmissionStatus.inReview => l.submissionStatusInReview,
  SubmissionStatus.changesRequested => l.submissionStatusChangesRequested,
  SubmissionStatus.declined => l.submissionStatusDeclined,
  SubmissionStatus.published => l.submissionStatusPublished,
  SubmissionStatus.withdrawn => l.submissionStatusWithdrawn,
};

/// The detail line of an edit event (Slides 09 §5): "3 slides · 1 slide
/// deleted · theme changed · with Claude", from the counters and sets of
/// its summary; null when there is nothing to add (documents,
/// spreadsheets).
String? activityDetail(WonkyAppLocalizations l, ActivityEventView e) {
  if (e.type != ActivityType.edited) return null;
  Map<String, Object?> m;
  try {
    final v = jsonDecode(e.summary);
    if (v is! Map) return null;
    m = v.cast<String, Object?>();
  } on FormatException {
    return null;
  }
  int count(String key) {
    final v = m[key];
    return v is num ? v.toInt() : 0;
  }

  final slides = m['slideIds'];
  final kinds = m['actorKinds'];
  final parts = [
    if (slides is List && slides.isNotEmpty)
      l.activityDetailSlides(slides.length),
    if (count('slidesDeleted') > 0)
      l.activityDetailSlidesDeleted(count('slidesDeleted')),
    if (count('themes') > 0) l.activityDetailTheme,
    if (kinds is List && (kinds.contains('mcp') || kinds.contains('ai')))
      l.activityDetailAgent,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// "Request access" for a file the user cannot open (No-access page).
Future<bool> showRequestAccessDialog(
  BuildContext context,
  ShellServices s,
  UuidValue itemUuid,
) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.requestAccessTitle,
      description: l.requestAccessDescription,
      dialogKey: 'dialog.requestAccess',
      fields: [
        SelectFieldSpec(
          id: 'role',
          label: l.requestAccessRole,
          options: {
            'viewer': l.roleViewer,
            'commenter': l.roleCommenter,
            'editor': l.roleEditor,
          },
          initial: 'editor',
        ),
        TextFieldSpec(
          id: 'message',
          label: l.requestAccessMessage,
          multiline: true,
          selectAll: false,
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'send', label: l.requestAccessSend, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'send') return false;
  try {
    final msg = r!.text('message').trim();
    await s.repositories.sharing.requestAccess(
      itemUuid,
      AccessRole.values.byName('${r.values['role']}'),
      msg.isEmpty ? null : msg,
    );
    s.toasts.show(l.toastAccessRequested);
    return true;
  } catch (e) {
    s.toasts.error(l.requestAccessFailed, description: errorMessage(e));
    if (kDebugMode) debugPrint('$e');
    return false;
  }
}
