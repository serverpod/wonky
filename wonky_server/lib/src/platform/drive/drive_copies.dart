import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart' show DeltaUtils;

import '../../sheets/spaces/space_copier.dart';
import '../../slides/decks/deck_copies.dart';

import '../../write/ot/document_store.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/names.dart';
import '../common/time.dart';
import '../comments/comment_copier.dart';
import '../sharing/access_service.dart';
import '../sharing/acl_events.dart';
import '../storage/content_sizes.dart';
import '../storage/storage_hooks.dart';
import '../storage/storage_service.dart';
import 'drive_file_service.dart';
import 'drive_views.dart';

import 'drive_service.dart';

/// *Make a copy* of drive items (specs/05 §2, Drive 02): the copy per kind,
/// where it goes, its sharing and its activity.
abstract final class DriveCopies {
  /// Copies a document or spreadsheet ("Make a copy").
  static Future<DriveItemView> copy(
    Session session,
    Actor actor,
    UuidValue uuid, {
    required String newName,
    UuidValue? parentUuid,
    bool copyComments = false,
    bool copySharing = false,
  }) async {
    final (source, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    if (role < Role.editor && !source.nonEditorsCanExport) {
      throw Errors.forbidden('The owner has disabled copying for viewers.');
    }
    // Comments hidden from the caller are never copied.
    copyComments = copyComments && CommentCopier.mayCopy(source, role);
    final DriveItemView copyView;
    switch (source.kind) {
      case DriveItemKind.folder:
        throw Errors.invalid('Folders cannot be copied.');
      case DriveItemKind.presentation:
        // (v2, SL-8) Deck copies (Slides 02 §9.3): `DeckCopier` rows in a
        // new deck space, images re-homed; the copier pays.
        final copied = await DeckCopies.copy(
          session,
          actor,
          source,
          name: newName,
          parentUuid:
              parentUuid ?? await defaultCopyParent(session, actor, source),
          description: source.description,
        );
        if (copyComments) {
          await CommentCopier.copyThreads(
            session,
            from: source,
            to: copied.item,
            anchorIdMap: copied.ids,
          );
        }
        copyView = await finishCopy(
          session,
          actor,
          source,
          copied.item,
          copySharing,
        );
      case DriveItemKind.file:
        // (v2) Server-side copy of the stored bytes (Drive 02 §10).
        final item = await DriveFileService.copyFile(
          session,
          actor,
          source,
          newName: newName,
          parentUuid:
              parentUuid ?? await defaultCopyParent(session, actor, source),
        );
        copyView = await finishCopy(session, actor, source, item, copySharing);
      case DriveItemKind.document:
        // (v2) The copier pays for the copy (Drive 03 §7.2).
        await StorageHooks.checkCaller(
          session,
          actor,
          source.sizeBytes + source.attachmentBytes,
          QuotaReason.copy,
        );
        final sourceDoc = await DocumentStore.requireByItem(
          session,
          source.id!,
        );
        var content = await DocumentStore.head(session, sourceDoc);
        final threadMap = copyComments
            ? await CommentCopier.newThreadUuids(session, source)
            : <String, String>{};
        content = copyComments
            ? CommentCopier.rewriteAnchors(content, threadMap)
            : DeltaUtils.stripComments(content);
        final docUuid = const Uuid().v7obj();
        final item = await session.db.transaction((tx) async {
          final parent = await DriveService.parentFor(
            session,
            actor,
            parentUuid ?? await defaultCopyParent(session, actor, source),
            transaction: tx,
          );
          final item = await DriveService.insertItem(
            session,
            actor,
            kind: DriveItemKind.document,
            name: newName,
            parent: parent,
            contentRef: docUuid,
            description: source.description,
            transaction: tx,
          );
          await DocumentStore.create(
            session,
            item: item,
            documentUuid: docUuid,
            actor: actor,
            initial: content,
            kind: DocumentOpKind.content,
            themeId: sourceDoc.themeId,
            pageSetupJson: sourceDoc.pageSetupJson,
            language: sourceDoc.language,
            frontMatter: sourceDoc.frontMatter,
            transaction: tx,
          );
          await DriveItem.db.updateRow(
            session,
            item.copyWith(searchText: source.searchText),
            columns: (t) => [t.searchText],
            transaction: tx,
          );
          await StorageService.instance.setItemSize(
            session,
            item,
            DocumentSize.of(content),
            transaction: tx,
          );
          if (copyComments) {
            await CommentCopier.copyThreads(
              session,
              from: source,
              to: item,
              threadMap: threadMap,
              transaction: tx,
            );
          }
          return item;
        });
        copyView = await finishCopy(session, actor, source, item, copySharing);
      case DriveItemKind.spreadsheet:
        await StorageHooks.checkCaller(
          session,
          actor,
          source.sizeBytes + source.attachmentBytes,
          QuotaReason.copy,
        );
        final space = const Uuid().v7obj();
        final (changes, idMap) = await SpaceCopier.changes(
          session,
          fromFile: source.contentRef!,
          toFile: space,
          authorUuid: actor.authUserId,
          title: normalizeItemName(newName),
        );
        final item = await DriveService.createSheetsFile(
          session,
          actor,
          parentUuid:
              parentUuid ?? await defaultCopyParent(session, actor, source),
          name: newName,
          fileUuid: space,
          initialChanges: changes,
          description: source.description,
        );
        if (copyComments) {
          await session.db.transaction(
            (tx) => CommentCopier.copyThreads(
              session,
              from: source,
              to: item,
              anchorIdMap: idMap,
              transaction: tx,
            ),
          );
        }
        await ContentSizes.refresh(session, item);
        copyView = await finishCopy(session, actor, source, item, copySharing);
    }
    return copyView;
  }

  /// Where a copy of [source] goes by default (its folder when [actor] can
  /// edit it, else My Drive) and the end of a copy (sharing, activity,
  /// view): used by copies made outside [copy] (Slides version copies,
  /// SL-39).
  static Future<UuidValue?> defaultCopyParent(
    Session session,
    Actor actor,
    DriveItem source,
  ) async {
    if (source.parentId == null) return null;
    final parent = await DriveItem.db.findById(session, source.parentId!);
    if (parent == null) return null;
    final role = await AccessService.effectiveRole(
      session,
      actor.userId,
      parent,
    );
    return role != null && role >= Role.editor ? parent.uuid : null;
  }

  /// *Share with the same people* of a copy: the direct grants of
  /// [source] (and its owner as editor) on [copy].
  static Future<void> copyGrants(
    Session session,
    Actor actor,
    DriveItem source,
    DriveItem copy,
  ) async {
    final grants = await DriveItemPermission.db.find(
      session,
      where: (t) =>
          t.itemId.equals(source.id!) & t.inheritedFromId.equals(null),
    );
    final now = nowUtc();
    final rows = [
      for (final g in grants)
        if (g.userId != actor.userId)
          DriveItemPermission(
            itemId: copy.id!,
            userId: g.userId,
            invitedEmail: g.invitedEmail,
            role: g.role,
            grantedById: actor.userId,
            grantedAt: now,
            expiresAt: g.expiresAt,
          ),
      if (source.ownerId != actor.userId &&
          !grants.any((g) => g.userId == source.ownerId))
        DriveItemPermission(
          itemId: copy.id!,
          userId: source.ownerId,
          role: AccessRole.editor,
          grantedById: actor.userId,
          grantedAt: now,
        ),
    ];
    if (rows.isNotEmpty) {
      await DriveItemPermission.db.insert(session, rows);
    }
    await AclEvents.changed(session, copy);
  }

  /// The end of a copy: sharing, activity, view (see [defaultCopyParent]).
  static Future<DriveItemView> finishCopy(
    Session session,
    Actor actor,
    DriveItem source,
    DriveItem copy,
    bool copySharing,
  ) async {
    if (copySharing) await copyGrants(session, actor, source, copy);
    await DriveService.afterCreate(
      session,
      actor,
      copy,
      summary: {'copiedFrom': source.uuid.uuid, 'copiedFromName': source.name},
    );
    return DriveViews.one(session, actor.userId, copy, role: Role.owner);
  }
}
