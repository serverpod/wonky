import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/copy.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/names.dart';
import '../../platform/files/file_service.dart';
import '../../platform/storage/content_sizes.dart';
import '../../platform/storage/storage_hooks.dart';
import '../../platform/storage/storage_service.dart';
import '../revlog/slides_revlog.dart';
import 'slides_decks.dart';

/// A deck copied by [DeckCopies.copy].
class CopiedDeck {
  CopiedDeck(this.item, this.ids, this.files, this.filesFailed);

  /// The new presentation item (uuid = file uuid).
  final DriveItem item;

  /// Old → new row ids (comment anchors).
  final Map<String, String> ids;

  /// Uploaded files copied into the new item.
  final int files;

  /// Files that could not be copied (gone, unreadable); their elements
  /// keep the new reference and render as missing images.
  final int filesFailed;
}

/// Server-side deck copies (Slides 02 §9.3): *Make a copy*
/// (`drive.copy`), presentations created from a template item
/// (`drive.createPresentation(templateUuid)`) and version copies
/// (`slidesVersion.makeCopy`, [sourceModel]).
/// Rows are rewritten by the core `DeckCopier` (new ids, deterministic
/// ids for the new deck, references remapped) and committed as the new
/// file's creation op (`RevLogService.createFile`); uploaded images
/// are re-homed into the new item (`FileService.copyToItem`). The caller
/// pays (Drive 03 §7.2): the quota is checked before anything is created
/// (`StorageService.checkRoom` with the source's content + attachment
/// size) and the copy's size is measured after (`ContentSizes.refresh`
/// → `setItemSize`; images as attachment bytes).
abstract final class DeckCopies {
  /// The label of the copy's creation op.
  static const copyLabel = 'Copy presentation';

  /// Copies the deck of [source] for [actor] into [parentUuid] (null = My
  /// Drive) under [name]. The caller checked read access and the copy
  /// permission; the parent is checked here.
  static Future<CopiedDeck> copy(
    Session session,
    Actor actor,
    DriveItem source, {
    required String name,
    UuidValue? parentUuid,
    String? description,
    String quotaReason = QuotaReason.copy,
    DeckModel? sourceModel,
    UuidValue? fileUuid,
  }) async {
    if (source.kind != DriveItemKind.presentation ||
        source.contentRef == null) {
      throw Errors.invalid('This is not a presentation.');
    }
    final cleanName = normalizeItemName(name);
    await StorageHooks.checkCaller(
      session,
      actor,
      source.sizeBytes + source.attachmentBytes,
      quotaReason,
    );
    // A version copy (Slides 09 §4.5) passes the version's model.
    final sourceDeck =
        sourceModel ?? await SlidesRevlog.model(session, source.contentRef!);
    final file = fileUuid ?? const Uuid().v7obj();
    final copy = DeckCopier.copy(
      sourceDeck,
      deckId: file.uuid,
      userId: actor.authUserId.uuid,
      now: clock.now().toUtc(),
      title: cleanName,
    );
    final item = await SlidesDecks.createFile(
      session,
      actor,
      parentUuid: parentUuid,
      name: cleanName,
      fileUuid: file,
      initialChanges: copy.inserts,
      label: copyLabel,
      description: description,
    );
    var copied = 0, failed = 0;
    for (final f in copy.files) {
      try {
        await FileService.copyToItem(
          session,
          actor,
          sourceFileUuid: UuidValue.withValidation(f.sourceFileUuid),
          newFileUuid: UuidValue.withValidation(f.newFileUuid),
          targetItemUuid: item.uuid,
        );
        copied++;
      } on Object catch (e) {
        // Any failure (also a storage error) only loses this image: the
        // deck exists already (created atomically with its RevLog file),
        // so the copy finishes instead of failing half-done (CQ-34).
        failed++;
        session.log(
          'Deck copy ${item.uuid}: file ${f.sourceFileUuid} not copied '
          '(${e is WonkyException ? e.message : e})',
          level: LogLevel.warning,
        );
      }
    }
    await ContentSizes.refresh(session, item);
    final fresh = await DriveItem.db.findById(session, item.id!) ?? item;
    return CopiedDeck(fresh, copy.ids, copied, failed);
  }
}
