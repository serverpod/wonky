import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';

import '../l10n/wonky_app_localizations.dart';
import '../shell/form_dialog.dart';
import '../shell/shell_services.dart';

/// The `/new?publication=pub_…` route of Write (specs/18 §3): asks for
/// consent (once per publication, again when what was agreed changed),
/// offers the contributor's open stories, and creates the document of a
/// new one. Returns the document to open, or null when cancelled.
Future<UuidValue?> startPublicationStory(
  BuildContext context,
  ShellServices services,
  String publicId, {
  String? ref,
}) async {
  final repo = services.repositories.publications;
  final l = WonkyAppLocalizations.of(context);
  final card = await repo.resolve(publicId);
  if (!context.mounted) return null;
  if (card.blocked || !card.enabled) {
    await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: card.name,
        description: card.blocked
            ? l.pubStartBlocked(card.name)
            : l.pubStartClosed(card.name),
        dialogKey: 'dialog.publicationStart',
        alert: true,
        buttons: [DialogButtonSpec(id: 'cancel', label: l.actionOk)],
      ),
    );
    return null;
  }
  if (!card.consentNeeded && card.openSubmissions.isEmpty) {
    final started = await repo.startSubmission(
      publicId,
      ref: ref,
      agreed: false,
    );
    return started.itemUuid;
  }
  final host = card.verified
      ? l.pubStartHostVerified(card.shownHost)
      : l.pubStartHostUnverified(card.siteHost, card.webhookHost);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.pubStartTitle(card.name),
      description: [
        host,
        if (card.consentNeeded) l.pubStartConsent(card.name),
      ].join('\n\n'),
      dialogKey: 'dialog.publicationStart',
      width: 480,
      fields: [
        if (card.openSubmissions.isNotEmpty)
          SelectFieldSpec(
            id: 'story',
            label: l.pubStartWhich,
            options: {
              for (final o in card.openSubmissions)
                o.itemUuid.uuid: l.pubStartContinue(o.name),
              'new': l.pubStartNew,
            },
            initial: card.openSubmissions.first.itemUuid.uuid,
          ),
        if (card.consentNeeded && card.termsUrl != null)
          CheckboxFieldSpec(
            id: 'terms',
            label: l.pubStartTerms(card.name, card.termsUrl!),
          ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel, validates: false),
        DialogButtonSpec(id: 'start', label: l.pubStartButton, primary: true),
      ],
    ),
  );
  if (r == null || r.buttonId != 'start') return null;
  final story = r.values['story'] as String?;
  if (story != null && story != 'new') return UuidValue.fromString(story);
  if (card.consentNeeded && card.termsUrl != null && !r.flag('terms')) {
    services.toasts.error(l.pubStartTermsRequired(card.name));
    return null;
  }
  final started = await repo.startSubmission(
    publicId,
    ref: ref,
    agreed: card.consentNeeded,
  );
  return started.itemUuid;
}
