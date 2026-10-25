import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show UuidV7Generator;

import '../../l10n/write_l10n.dart';
import '../images/image_dialogs.dart';
import '../images/image_services.dart';
import '../screen/write_document_controller.dart';

/// The default name of a story's document (server: `PublicationService`).
const untitledStoryName = 'Untitled story';

/// Picks the cover image instead of the platform picker (tests).
@visibleForTesting
Future<PickedImage?> Function()? debugPickCoverImage;

/// Picks an image and uploads it as the story's cover (specs/18 §4.2): an
/// image file of the document (counted like its images, readable by the
/// moderators) that is not inserted into the text, so blogs that show the
/// cover above the post don't show it twice. The server stores it as a
/// 1200 × 630 WebP. Null when cancelled.
Future<ImageFieldPick?> uploadCoverImage(
  ShellServices s,
  WriteDocumentController doc,
) async {
  final l = writeL10nOf(s);
  final picked = debugPickCoverImage != null
      ? await debugPickCoverImage!()
      : (await pickImageFiles(
          multiple: false,
          onRejected: (name, reason) =>
              s.toasts.error(reason, description: name),
          l: l,
        )).firstOrNull;
  if (picked == null) return null;
  if (!await imagesFitStorage(s, [picked])) return null;
  final fileUuid = UuidValue.withValidation(
    UuidV7Generator.instance.nextString(),
  );
  await s.repositories.files.upload(
    fileUuid: fileUuid,
    itemUuid: doc.itemUuid,
    fileName: picked.name,
    mimeType: picked.mimeType,
    bytes: picked.bytes,
    // Re-encoded as a 1200 × 630 WebP, cropped to fill (specs/18 §4.2).
    imageProfile: ImageProfile.cover,
  );
  return (value: fileUuid.uuid, preview: MemoryImage(picked.bytes));
}

/// The number of open suggestions in the document (they are sent as the
/// original text, specs/18 §4.2).
int openSuggestionCount(WriteDocumentController doc) {
  final ids = <String>{};
  for (final op in doc.editor.delta.toList()) {
    for (final key in op.attributes?.keys ?? const <String>[]) {
      if (key.startsWith('sug_')) ids.add(key);
    }
  }
  return ids.length;
}

/// The title a first submit starts with: the stored one, else the
/// document's name, else its first heading.
String initialStoryTitle(WriteDocumentController doc, SubmissionView v) {
  if (v.values.title.trim().isNotEmpty && v.values.title != untitledStoryName) {
    return v.values.title;
  }
  if (doc.title.trim().isNotEmpty && doc.title != untitledStoryName) {
    return doc.title;
  }
  doc.insights.refresh();
  final outline = doc.insights.outline;
  return outline.isEmpty ? '' : outline.first.text;
}

/// *Submit to (publication)* (specs/18 §4.2): asks for the publication's
/// fields and submits the current revision. Returns the new view, or null
/// when cancelled.
Future<SubmissionView?> showSubmitDialog(
  BuildContext context,
  ShellServices s,
  WriteDocumentController doc,
) async {
  final v = doc.submission.view;
  if (v == null) return null;
  final l = writeL10n(context);
  final f = v.fields;
  final suggestions = openSuggestionCount(doc);
  String? need(PublicationFieldMode mode, String value) =>
      mode == PublicationFieldMode.required && value.trim().isEmpty
      ? l.submitRequired
      : null;
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.submitTitle(v.publicationName),
      description: [
        v.verified
            ? l.submitHostVerified(v.shownHost)
            : l.submitHostUnverified(v.shownHost),
        if (suggestions > 0) l.submitOpenSuggestions(suggestions),
        l.submitCommentsStay,
      ].join('\n\n'),
      dialogKey: 'dialog.submit',
      width: 520,
      fields: [
        TextFieldSpec(
          id: 'title',
          label: l.submitFieldTitle,
          initial: initialStoryTitle(doc, v),
          maxLength: 300,
          validator: (x) => x.trim().isEmpty ? l.submitRequired : null,
        ),
        if (f.summary != PublicationFieldMode.off)
          TextFieldSpec(
            id: 'summary',
            label: _label(l, l.submitFieldSummary, f.summary),
            initial: v.values.summary ?? '',
            multiline: true,
            maxLength: 2000,
            validator: (x) => need(f.summary, x),
          ),
        if (f.tags != PublicationFieldMode.off)
          TextFieldSpec(
            id: 'tags',
            label: _label(l, l.submitFieldTags, f.tags),
            placeholder: f.allowedTags.isEmpty
                ? l.submitTagsHint
                : l.submitTagsFrom(f.allowedTags.join(', ')),
            initial: v.values.tags.join(', '),
            validator: (x) => need(f.tags, x),
          ),
        if (f.coverImage != PublicationFieldMode.off)
          ImageFieldSpec(
            id: 'cover',
            label: _label(l, l.submitFieldCover, f.coverImage),
            // The stored cover (also one picked from the document's images
            // before covers were uploaded); none on a first submit.
            initial: v.values.coverImage?.uuid ?? '',
            preview: (id) =>
                doc.images.resolve('${WriteImageServices.scheme}$id'),
            pick: () => uploadCoverImage(s, doc),
            description: l.submitCoverHint,
            uploadLabel: l.submitCoverUpload,
            replaceLabel: l.submitCoverReplace,
            removeLabel: l.submitCoverRemove,
            emptyLabel: l.submitNoCover,
            uploadingLabel: l.submitCoverUploading,
            errorLabel: l.submitCoverFailed,
          ),
        if (f.authorBio != PublicationFieldMode.off)
          TextFieldSpec(
            id: 'authorBio',
            label: _label(l, l.submitFieldBio, f.authorBio),
            initial: v.values.authorBio ?? '',
            multiline: true,
            maxLength: 2000,
            validator: (x) => need(f.authorBio, x),
          ),
        if (f.note != PublicationFieldMode.off)
          TextFieldSpec(
            id: 'note',
            label: _label(l, l.submitFieldNote, f.note),
            multiline: true,
            maxLength: 2000,
            validator: (x) => need(f.note, x),
          ),
        if (v.consentNeeded && v.termsUrl != null)
          CheckboxFieldSpec(
            id: 'terms',
            label: l.submitTerms(v.publicationName, v.termsUrl!),
          ),
      ],
      buttons: [
        DialogButtonSpec(
          id: 'cancel',
          label: WonkyAppLocalizations.of(context).actionCancel,
          validates: false,
        ),
        DialogButtonSpec(id: 'submit', label: l.submitButton, primary: true),
      ],
    ),
  );
  if (r == null || r.buttonId != 'submit') return null;
  if (v.consentNeeded && v.termsUrl != null && !r.flag('terms')) {
    s.toasts.error(l.submitTermsRequired(v.publicationName));
    return null;
  }
  if (f.coverImage == PublicationFieldMode.required &&
      r.text('cover').isEmpty) {
    s.toasts.error(l.submitCoverRequired);
    return null;
  }
  String? opt(String id) =>
      r.text(id).trim().isEmpty ? null : r.text(id).trim();
  final values = SubmissionValues(
    title: r.text('title').trim(),
    summary: opt('summary'),
    tags: [
      for (final t in r.text('tags').split(','))
        if (t.trim().isNotEmpty) t.trim(),
    ],
    coverImage: r.text('cover').isEmpty
        ? null
        : UuidValue.fromString(r.text('cover')),
    authorBio: opt('authorBio'),
    note: opt('note'),
  );
  return doc.submission.submit(values, agreed: v.consentNeeded);
}

String _label(WriteLocalizations l, String label, PublicationFieldMode mode) =>
    mode == PublicationFieldMode.required ? label : l.submitOptional(label);
