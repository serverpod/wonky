import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart' show Delta, DeltaUtils;

import '../../sheets/spaces/space_copier.dart';
import '../../slides/decks/slides_decks.dart';
import '../../sheets/spaces/spreadsheet_factory.dart';
import '../../sheets/spaces/sheets_create_defaults.dart';
import 'package:wonky_sheets_core/model.dart' show RowChange, SheetsTables;

import '../../sheets/revlog/sheets_rev_binding.dart';
import '../../sheets/revlog/sheets_server_writes.dart';
import '../revlog/rev_hooks.dart';
import '../revlog/rev_log_service.dart';
import '../../write/content/write_content.dart';
import '../../write/ot/document_bus.dart';
import '../../write/ot/document_store.dart';
import '../../write/themes/builtin_theme_ids.dart';
import '../activity/activity_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/names.dart';
import '../common/time.dart';
import '../files/file_service.dart';
import '../sharing/access_service.dart';
import '../sharing/acl_events.dart';
import '../storage/content_sizes.dart';
import '../storage/storage_hooks.dart';
import '../storage/storage_service.dart';
import 'drive_events.dart';
import 'drive_file_filters.dart';
import 'drive_listing.dart';
import 'drive_views.dart';
import 'kind_masks.dart';
import 'templates/builtin_templates.dart';

/// Wonky Drive (specs/05 §2).
abstract final class DriveService {
  // ------------------------------------------------------------------ read

  static Future<DriveItemView> get(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    // (v2) Uploads in progress are only visible to their uploader.
    if (!DriveFileFilters.listable(item, actor.userId)) throw Errors.notFound();
    return DriveViews.one(session, actor.userId, item, role: role);
  }

  /// Ancestors of [uuid] visible to the caller, root first.
  static Future<List<DriveItemView>> path(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final ancestors = await AccessService.ancestors(session, item);
    final roles = await AccessService.rolesFor(
      session,
      actor.userId,
      ancestors,
    );
    final visible = <DriveItem>[];
    for (final a in ancestors) {
      if (roles[a.id!] == null) break;
      visible.add(a);
    }
    final views = await DriveViews.build(
      session,
      actor.userId,
      visible,
      roles: roles,
    );
    return views.reversed.toList();
  }

  /// One page of a `drive.list` view ([DriveListing.list], in SQL with a
  /// keyset cursor).
  static Future<DriveListPage> list(
    Session session,
    Actor actor, {
    UuidValue? folderUuid,
    required DriveListFilter filter,
    required DriveSort sort,
    String? cursor,
    int limit = 100,
  }) => DriveListing.list(
    session,
    actor,
    folderUuid: folderUuid,
    filter: filter,
    sort: sort,
    cursor: cursor,
    limit: limit,
  );

  /// Full-text search ([DriveListing.search]).
  static Future<DriveListPage> search(
    Session session,
    Actor actor,
    String query, {
    required DriveSearchFilters filters,
    String? cursor,
    int limit = 50,
  }) => DriveListing.search(
    session,
    actor,
    query,
    filters: filters,
    cursor: cursor,
    limit: limit,
  );

  // ---------------------------------------------------------------- create

  /// Resolves the parent folder for a new item. Null = the caller's root.
  static Future<DriveItem?> parentFor(
    Session session,
    Actor actor,
    UuidValue? parentUuid, {
    Transaction? transaction,
  }) async {
    if (parentUuid == null) return null;
    final (parent, _) = await AccessService.require(
      session,
      actor,
      parentUuid,
      Role.editor,
      transaction: transaction,
    );
    if (parent.kind != DriveItemKind.folder) {
      throw Errors.invalid('Items can only be created in folders.');
    }
    if (parent.trashedAt != null) {
      throw Errors.invalid('The folder is in the trash.');
    }
    return parent;
  }

  /// Inserts a drive item (also for the other drive services: files,
  /// presentations).
  static Future<DriveItem> insertItem(
    Session session,
    Actor actor, {
    required DriveItemKind kind,
    required String name,
    DriveItem? parent,
    UuidValue? uuid,
    UuidValue? contentRef,
    String? description,
    Transaction? transaction,
    String? mimeType,
    FileCategory? fileCategory,
    FileUploadState? uploadState,
    String? fileMetaJson,
  }) async {
    final now = nowUtc();
    final item = await DriveItem.db.insertRow(
      session,
      DriveItem(
        // Spreadsheet items share the UUID of their space (Sheets 02 §3.1),
        // so a spreadsheet created offline opens at `/s/<space>` before
        // `registerSpreadsheet` reached the server.
        uuid:
            uuid ??
            (kind == DriveItemKind.spreadsheet ||
                    kind == DriveItemKind.presentation
                ? contentRef
                : null) ??
            const Uuid().v7obj(),
        kind: kind,
        name: normalizeItemName(name),
        ownerId: actor.userId,
        parentId: parent?.id,
        description: description,
        contentRef: contentRef,
        createdAt: now,
        createdById: actor.userId,
        modifiedAt: now,
        modifiedById: actor.userId,
        mimeType: mimeType,
        fileCategory: fileCategory,
        uploadState: uploadState,
        fileMetaJson: fileMetaJson,
      ),
      transaction: transaction,
    );
    await DriveItemUserState.db.insertRow(
      session,
      DriveItemUserState(
        itemId: item.id!,
        userId: actor.userId,
        lastOpenedAt: now,
        lastEditedAt: now,
      ),
      transaction: transaction,
    );
    if (parent != null) {
      await AccessService.rebuildInherited(
        session,
        item,
        transaction: transaction,
      );
      // (v2) Folder kind masks (suite 05 §3.2).
      if (KindMasks.counts(item)) {
        await KindMasks.refreshChain(
          session,
          parent.id,
          transaction: transaction,
        );
      }
    }
    return item;
  }

  /// Logs the creation of [item] and notifies its watchers (also for the
  /// other drive services).
  static Future<void> afterCreate(
    Session session,
    Actor actor,
    DriveItem item, {
    Map<String, Object?> summary = const {},
    ActivityType type = ActivityType.created,
  }) async {
    await ActivityService.log(session, item.id!, actor, type, summary: summary);
    await DriveEvents.notify(session, item, DriveChangeKind.created);
  }

  static Future<DriveItemView> createFolder(
    Session session,
    Actor actor, {
    UuidValue? parentUuid,
    required String name,
  }) async {
    final item = await session.db.transaction((tx) async {
      final parent = await parentFor(
        session,
        actor,
        parentUuid,
        transaction: tx,
      );
      return insertItem(
        session,
        actor,
        kind: DriveItemKind.folder,
        name: name,
        parent: parent,
        transaction: tx,
      );
    });
    await afterCreate(session, actor, item);
    return DriveViews.one(session, actor.userId, item, role: Role.owner);
  }

  /// Creates a document. [documentUuid] and [itemUuid] may be generated by
  /// the client for offline creation; the call is idempotent on them.
  static Future<DriveItemView> createDocument(
    Session session,
    Actor actor, {
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
    String? initialMarkdown,
    UuidValue? documentUuid,
    UuidValue? itemUuid,
  }) async {
    if (documentUuid != null) {
      final existing = await DocumentStore.byUuid(session, documentUuid);
      if (existing != null) {
        final item = await DriveItem.db.findById(session, existing.itemId);
        if (item != null) return get(session, actor, item.uuid);
      }
    }
    if (itemUuid != null) {
      final existing = await AccessService.findItem(session, itemUuid);
      if (existing != null) return get(session, actor, itemUuid);
    }
    Delta? content;
    UuidValue? themeId;
    var pageSetup = '{}';
    String? frontMatter;
    String? language;
    var activitySummary = <String, Object?>{};
    if (templateUuid != null) {
      final builtin = BuiltinTemplates.byUuid(templateUuid);
      if (builtin != null) {
        if (builtin.kind != DriveItemKind.document) {
          throw Errors.invalid('This is not a document template.');
        }
        content = WriteContent.fromMarkdown(builtin.markdown!).delta;
        if (builtin.themeKey case final key?) {
          themeId = BuiltinThemeIds.forKey(key);
        }
        activitySummary = {'template': builtin.key};
      } else {
        final (tplItem, _) = await AccessService.require(
          session,
          actor,
          templateUuid,
          Role.viewer,
        );
        if (tplItem.kind != DriveItemKind.document) {
          throw Errors.invalid('This is not a document template.');
        }
        final tplDoc = await DocumentStore.requireByItem(session, tplItem.id!);
        content = DeltaUtils.stripOverlays(
          await DocumentStore.head(session, tplDoc),
        );
        themeId = tplDoc.themeId;
        pageSetup = tplDoc.pageSetupJson;
        frontMatter = tplDoc.frontMatter;
        language = tplDoc.language;
        activitySummary = {'template': tplItem.uuid.uuid};
      }
    } else if (initialMarkdown != null && initialMarkdown.isNotEmpty) {
      content = WriteContent.fromMarkdown(initialMarkdown).delta;
    }
    // (v2) Quota (Drive 03 §7.2): blank documents are always allowed.
    if (content != null) {
      await StorageHooks.checkCaller(
        session,
        actor,
        DocumentSize.of(content),
        templateUuid != null ? QuotaReason.template : QuotaReason.import,
      );
    }
    final docUuid = documentUuid ?? const Uuid().v7obj();
    final item = await session.db.transaction((tx) async {
      final parent = await parentFor(
        session,
        actor,
        parentUuid,
        transaction: tx,
      );
      final item = await insertItem(
        session,
        actor,
        kind: DriveItemKind.document,
        name: name,
        parent: parent,
        uuid: itemUuid,
        contentRef: docUuid,
        transaction: tx,
      );
      await DocumentStore.create(
        session,
        item: item,
        documentUuid: docUuid,
        actor: actor,
        initial: content,
        kind: DocumentOpKind.content,
        themeId: themeId,
        pageSetupJson: pageSetup,
        frontMatter: frontMatter,
        language: language,
        transaction: tx,
      );
      if (content case final content?) {
        await DriveItem.db.updateRow(
          session,
          item.copyWith(searchText: DocumentStore.searchText(content)),
          columns: (t) => [t.searchText],
          transaction: tx,
        );
        await StorageService.instance.setItemSize(
          session,
          item,
          DocumentSize.of(content),
          transaction: tx,
        );
      }
      return item;
    });
    await afterCreate(session, actor, item, summary: activitySummary);
    return DriveViews.one(session, actor.userId, item, role: Role.owner);
  }

  /// Registers a spreadsheet created on a device (idempotent; queued
  /// offline creations): `createSpreadsheet(fileUuid, initialize: false)`,
  /// whose first client op creates the rows (RevLog spec 04 §5).
  static Future<DriveItemView> registerSpreadsheet(
    Session session,
    Actor actor, {
    required UuidValue spaceUuid,
    UuidValue? parentUuid,
    required String name,
  }) async {
    try {
      return await createSpreadsheet(
        session,
        actor,
        parentUuid: parentUuid,
        name: name,
        fileUuid: spaceUuid,
        initialize: false,
      );
    } on WonkyException catch (e) {
      // The folder was deleted or unshared while offline: use the root.
      if (parentUuid == null || e.code == WonkyErrorCode.forbidden) rethrow;
      return createSpreadsheet(
        session,
        actor,
        name: name,
        fileUuid: spaceUuid,
        initialize: false,
      );
    }
  }

  /// Creates a spreadsheet (RevLog spec 04 §5). With [fileUuid] the call is
  /// idempotent (a retry returns the item and finishes its initialization).
  /// [initialize] false: the file stays at revision 0 and the client's
  /// first op creates the rows (offline creation, version copies, imports
  /// the app does itself).
  static Future<DriveItemView> createSpreadsheet(
    Session session,
    Actor actor, {
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
    String? locale,
    String? timeZone,
    UuidValue? fileUuid,
    bool initialize = true,
  }) async {
    if (fileUuid != null) {
      // Any item using the id (CQ-2): a retry of our own creation is fine;
      // another kind or another item is refused before it reaches the
      // unique file index.
      final existing = await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.contentRef.equals(fileUuid) | t.uuid.equals(fileUuid),
      );
      if (existing != null) {
        if (existing.kind != DriveItemKind.spreadsheet) {
          throw Errors.conflict('This id belongs to another item.');
        }
        if (existing.ownerId != actor.userId) {
          throw Errors.forbidden('This file belongs to someone else.');
        }
        return get(session, actor, existing.uuid);
      }
    }
    final cleanName = normalizeItemName(name);
    BuiltinTemplate? builtin;
    DriveItem? templateItem;
    if (templateUuid != null) {
      builtin = BuiltinTemplates.byUuid(templateUuid);
      if (builtin == null) {
        final (tpl, _) = await AccessService.require(
          session,
          actor,
          templateUuid,
          Role.viewer,
        );
        templateItem = tpl;
      }
      if ((builtin?.kind ?? templateItem!.kind) != DriveItemKind.spreadsheet) {
        throw Errors.invalid('This is not a spreadsheet template.');
      }
    }
    // Validate the parent before creating a space.
    await parentFor(session, actor, parentUuid);
    // (v2) Quota of a template copy (Drive 03 §7.2); blank: always allowed.
    if (templateItem != null || (builtin?.sheets.isNotEmpty ?? false)) {
      await StorageHooks.checkCaller(
        session,
        actor,
        templateItem != null
            ? templateItem.sizeBytes + templateItem.attachmentBytes
            : StorageHooks.sheetsEstimate(builtin!.sheets),
        QuotaReason.template,
      );
    }
    final space = fileUuid ?? const Uuid().v7obj();
    final List<RowChange> initial;
    if (!initialize) {
      initial = const [];
    } else if (templateItem != null) {
      (initial, _) = await SpaceCopier.changes(
        session,
        fromFile: templateItem.contentRef!,
        toFile: space,
        authorUuid: actor.authUserId,
        title: cleanName,
      );
    } else {
      // Settings › Sheets defaults of the creator (04 §11.24); explicit
      // arguments win.
      final d = await SheetsCreateDefaults.of(session, actor.userId);
      initial = SpreadsheetFactory.changes(
        fileUuid: space,
        authorUuid: actor.authUserId,
        title: cleanName,
        locale: locale ?? d.locale ?? 'en_US',
        timeZone: timeZone ?? d.timeZone ?? 'UTC',
        fontFamily: d.fontFamily,
        fontSize: d.fontSize,
        sheets: builtin?.sheets ?? const [],
      );
    }
    final item = await createSheetsFile(
      session,
      actor,
      parentUuid: parentUuid,
      name: cleanName,
      fileUuid: space,
      initialChanges: initial,
    );
    await ContentSizes.refresh(session, item);
    await afterCreate(
      session,
      actor,
      item,
      summary: {
        if (builtin != null) 'template': builtin.key,
        if (templateItem != null) 'template': templateItem.uuid.uuid,
      },
    );
    return DriveViews.one(session, actor.userId, item, role: Role.owner);
  }

  /// Inserts the drive item of a new spreadsheet with its `rev_file` and
  /// commits [initialChanges] as revision 1… in one transaction (RevLog
  /// spec 05 §8.3).
  static Future<DriveItem> createSheetsFile(
    Session session,
    Actor actor, {
    required UuidValue? parentUuid,
    required String name,
    required UuidValue fileUuid,
    required List<RowChange> initialChanges,
    String? description,
  }) async {
    final binding = SheetsRevBinding.instance;
    final submitter = RevSubmitter.of(actor);
    final (item, file) = await session.db.transaction<(DriveItem, RevFile)>((
      tx,
    ) async {
      final parent = await parentFor(
        session,
        actor,
        parentUuid,
        transaction: tx,
      );
      final item = await insertItem(
        session,
        actor,
        kind: DriveItemKind.spreadsheet,
        name: name,
        parent: parent,
        contentRef: fileUuid,
        description: description,
        transaction: tx,
      );
      final file = await RevLogService.createFile(
        session,
        binding: binding,
        item: item,
        submitter: submitter,
        initialChanges: initialChanges,
        transaction: tx,
      );
      return (item, file);
    });
    if (initialChanges.isNotEmpty) {
      RevHooks.kick(session.serverpod, binding, file.id!);
    }
    return item;
  }

  /// Creates a spreadsheet from [sheets] (imports).
  static Future<DriveItemView> createSpreadsheetFromSheets(
    Session session,
    Actor actor, {
    required String name,
    UuidValue? parentUuid,
    required List<TemplateSheet> sheets,
    Map<String, Object?> summary = const {},
  }) async {
    final cleanName = normalizeItemName(name);
    await parentFor(session, actor, parentUuid);
    await StorageHooks.checkCaller(
      session,
      actor,
      StorageHooks.sheetsEstimate(sheets),
      QuotaReason.import,
    );
    final space = const Uuid().v7obj();
    final d = await SheetsCreateDefaults.of(session, actor.userId);
    final item = await createSheetsFile(
      session,
      actor,
      parentUuid: parentUuid,
      name: cleanName,
      fileUuid: space,
      initialChanges: SpreadsheetFactory.changes(
        fileUuid: space,
        authorUuid: actor.authUserId,
        title: cleanName,
        locale: d.locale ?? 'en_US',
        timeZone: d.timeZone ?? 'UTC',
        fontFamily: d.fontFamily,
        fontSize: d.fontSize,
        sheets: sheets,
      ),
    );
    await ContentSizes.refresh(session, item);
    await afterCreate(session, actor, item, summary: summary);
    return DriveViews.one(session, actor.userId, item, role: Role.owner);
  }

  // ---------------------------------------------------------------- update

  static Future<DriveItemView> rename(
    Session session,
    Actor actor,
    UuidValue uuid,
    String name,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.editor,
    );
    final clean = normalizeItemName(name);
    if (clean == item.name) {
      return DriveViews.one(session, actor.userId, item, role: role);
    }
    final updated = await DriveItem.db.updateRow(
      session,
      item.copyWith(name: clean),
      columns: (t) => [t.name],
    );
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.renamed,
      summary: {'from': item.name, 'to': clean},
    );
    if (item.kind == DriveItemKind.document && item.contentRef != null) {
      await DocumentBus.metaChanged(
        session,
        item.contentRef!,
        DocMetaChanged(
          field: 'title',
          valueJson: jsonEncode(clean),
          authorId: actor.userId,
        ),
      );
    }
    if (item.kind == DriveItemKind.spreadsheet && item.contentRef != null) {
      await _mirrorTitleToSpreadsheet(session, actor, updated);
    }
    if (item.kind == DriveItemKind.presentation && item.contentRef != null) {
      await SlidesDecks.mirrorTitleToDeck(session, actor, updated);
    }
    await DriveEvents.notify(session, updated, DriveChangeKind.updated);
    return DriveViews.one(session, actor.userId, updated, role: role);
  }

  /// Writes a drive rename into `spreadsheet.title` as a system op (RevLog
  /// spec 05 §8.3), when the root row exists; otherwise the creation op
  /// picks up the name (04 §5).
  static Future<void> _mirrorTitleToSpreadsheet(
    Session session,
    Actor actor,
    DriveItem item,
  ) async {
    try {
      final current = await Spreadsheet.db.findById(session, item.contentRef!);
      if (current == null || current.title == item.name) return;
      await SheetsServerWrites.apply(
        session,
        actor: actor.copyWith(kind: ActorKind.system),
        fileUuid: item.contentRef!,
        changes: [
          RowChange.update(
            SheetsTables.spreadsheet,
            item.contentRef!.uuid,
            {'title': current.title},
            {'title': item.name},
          ),
        ],
        label: 'Rename',
      );
    } on Exception catch (e) {
      session.log(
        'Could not mirror the title of ${item.uuid} to its spreadsheet: $e',
        level: LogLevel.warning,
      );
    }
  }

  static Future<DriveItemView> updateDescription(
    Session session,
    Actor actor,
    UuidValue uuid,
    String? description,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.editor,
    );
    final clean = description?.trim();
    if (clean != null && clean.length > 5000) {
      throw Errors.invalid('The description is too long.');
    }
    final updated = await DriveItem.db.updateRow(
      session,
      DriveItem(
        id: item.id,
        uuid: item.uuid,
        kind: item.kind,
        name: item.name,
        ownerId: item.ownerId,
        parentId: item.parentId,
        description: clean == null || clean.isEmpty ? null : clean,
        contentRef: item.contentRef,
        thumbnailFileId: item.thumbnailFileId,
        sizeBytes: item.sizeBytes,
        createdAt: item.createdAt,
        createdById: item.createdById,
        modifiedAt: item.modifiedAt,
        modifiedById: item.modifiedById,
        trashedAt: item.trashedAt,
        trashedById: item.trashedById,
        templateOf: item.templateOf,
        templateKey: item.templateKey,
        editorsCanShare: item.editorsCanShare,
        nonEditorsCanExport: item.nonEditorsCanExport,
        viewersSeeComments: item.viewersSeeComments,
        searchText: item.searchText,
      ),
      columns: (t) => [t.description],
    );
    await DriveEvents.notify(session, updated, DriveChangeKind.updated);
    return DriveViews.one(session, actor.userId, updated, role: role);
  }

  /// Moves items into [newParentUuid] (null = the caller's root, owners
  /// only). Requires Editor on the items and the target; cycles are refused.
  /// Non-owners move an item only within its folder tree or into a folder
  /// of its owner.
  static Future<List<DriveItemView>> move(
    Session session,
    Actor actor,
    List<UuidValue> uuids,
    UuidValue? newParentUuid,
  ) async {
    final selected = bulkUuids(uuids);
    DriveItem? target;
    if (newParentUuid != null) {
      final (t, _) = await AccessService.require(
        session,
        actor,
        newParentUuid,
        Role.editor,
      );
      if (t.kind != DriveItemKind.folder) {
        throw Errors.invalid('Items can only be moved into folders.');
      }
      if (t.trashedAt != null) {
        throw Errors.invalid('The folder is in the trash.');
      }
      target = t;
    }
    final moved = <DriveItem>[];
    for (final uuid in selected) {
      final (item, _) = await AccessService.require(
        session,
        actor,
        uuid,
        Role.editor,
      );
      if (target == null && item.ownerId != actor.userId) {
        throw Errors.forbidden(
          'Only the owner can move an item to My Drive. Add a shortcut instead.',
        );
      }
      if (target != null) {
        if (target.id == item.id) {
          throw WonkyException(
            code: WonkyErrorCode.cycle,
            message: 'A folder cannot be moved into itself.',
          );
        }
        final chain = await AccessService.ancestors(session, target);
        if (chain.any((a) => a.id == item.id)) {
          throw WonkyException(
            code: WonkyErrorCode.cycle,
            message: 'A folder cannot be moved into one of its subfolders.',
          );
        }
        // Someone else's item may only move within the folder tree it is
        // in, or into a folder of its owner: moving it into a folder of a
        // third person would give that person (and whoever they share the
        // folder with) access the owner never granted.
        if (item.ownerId != actor.userId && target.ownerId != item.ownerId) {
          final itemChain = await AccessService.ancestors(session, item);
          final itemTop = itemChain.isEmpty ? item : itemChain.last;
          final targetTop = chain.isEmpty ? target : chain.last;
          if (itemTop.id != targetTop.id) {
            throw Errors.forbidden(
              'Only the owner can move this item into a folder owned by '
              'someone else.',
            );
          }
        }
      }
      if (item.parentId == target?.id) continue;
      final before = await subtreeUsers(session, item);
      final updated = await session.db.transaction((tx) async {
        final row = DriveItem.db.updateRow(
          session,
          _withParent(item, target?.id),
          columns: (t) => [t.parentId],
          transaction: tx,
        );
        final updated = await row;
        await AccessService.rebuildInherited(session, updated, transaction: tx);
        // (v2) Kind masks of the old and the new folder chain.
        await KindMasks.refreshChain(session, item.parentId, transaction: tx);
        await KindMasks.refreshChain(session, target?.id, transaction: tx);
        return updated;
      });
      await ActivityService.log(
        session,
        item.id!,
        actor,
        ActivityType.moved,
        summary: {'to': target?.uuid.uuid, 'toName': target?.name},
      );
      await AclEvents.changed(
        session,
        updated,
        affectedUsers: before,
        kind: DriveChangeKind.moved,
      );
      moved.add(updated);
    }
    return DriveViews.build(session, actor.userId, moved);
  }

  /// The interested users of [item]'s subtree (batched, CQ-26).
  static Future<Set<int>> subtreeUsers(Session session, DriveItem item) async {
    final nodes = await AccessService.subtree(session, item);
    final byItem = await AccessService.interestedUsersOf(session, nodes);
    return {for (final users in byItem.values) ...users};
  }

  /// Most items one move, trash, restore or delete call takes (CQ-26).
  static const maxBulkItems = 500;

  /// The distinct [uuids] of one bulk call; `limitExceeded` past
  /// [maxBulkItems].
  static Set<UuidValue> bulkUuids(List<UuidValue> uuids) {
    final set = uuids.toSet();
    if (set.length > maxBulkItems) {
      throw Errors.limit(
        'Select at most $maxBulkItems items at a time.',
      );
    }
    return set;
  }

  static DriveItem _withParent(DriveItem item, int? parentId) => DriveItem(
    id: item.id,
    uuid: item.uuid,
    kind: item.kind,
    name: item.name,
    ownerId: item.ownerId,
    parentId: parentId,
    description: item.description,
    contentRef: item.contentRef,
    thumbnailFileId: item.thumbnailFileId,
    sizeBytes: item.sizeBytes,
    createdAt: item.createdAt,
    createdById: item.createdById,
    modifiedAt: item.modifiedAt,
    modifiedById: item.modifiedById,
    trashedAt: item.trashedAt,
    trashedById: item.trashedById,
    templateOf: item.templateOf,
    templateKey: item.templateKey,
    editorsCanShare: item.editorsCanShare,
    nonEditorsCanExport: item.nonEditorsCanExport,
    viewersSeeComments: item.viewersSeeComments,
    searchText: item.searchText,
  );

  /// Creates a document with [content] (version copies, imports), taking
  /// theme and page setup from [source] when given.
  static Future<DriveItemView> createDocumentFromContent(
    Session session,
    Actor actor, {
    required String name,
    UuidValue? parentUuid,
    required Delta content,
    Document? source,
    String? frontMatter,
    Map<String, Object?> activitySummary = const {},
    String? quotaReason = QuotaReason.import,
  }) async {
    // (v2) Quota (Drive 03 §7.2); null skips the check (already checked).
    if (quotaReason != null) {
      await StorageHooks.checkCaller(
        session,
        actor,
        DocumentSize.of(content),
        quotaReason,
      );
    }
    final docUuid = const Uuid().v7obj();
    final item = await session.db.transaction((tx) async {
      final parent = await parentFor(
        session,
        actor,
        parentUuid,
        transaction: tx,
      );
      final item = await insertItem(
        session,
        actor,
        kind: DriveItemKind.document,
        name: name,
        parent: parent,
        contentRef: docUuid,
        transaction: tx,
      );
      await DocumentStore.create(
        session,
        item: item,
        documentUuid: docUuid,
        actor: actor,
        initial: content,
        kind: DocumentOpKind.imported,
        themeId: source?.themeId,
        pageSetupJson: source?.pageSetupJson ?? '{}',
        language: source?.language,
        frontMatter: frontMatter ?? source?.frontMatter,
        transaction: tx,
      );
      await DriveItem.db.updateRow(
        session,
        item.copyWith(searchText: DocumentStore.searchText(content)),
        columns: (t) => [t.searchText],
        transaction: tx,
      );
      await StorageService.instance.setItemSize(
        session,
        item,
        DocumentSize.of(content),
        transaction: tx,
      );
      return item;
    });
    await afterCreate(session, actor, item, summary: activitySummary);
    return DriveViews.one(session, actor.userId, item, role: Role.owner);
  }

  // ---------------------------------------------------------------- misc

  /// The caller's storage (Drive 03 §3), from [StorageService].
  static Future<StorageUsage> storageUsage(Session session, Actor actor) =>
      StorageService.instance.usage(session, actor.userId);

  static Future<DriveItemView> setThumbnail(
    Session session,
    Actor actor,
    UuidValue uuid,
    UuidValue fileUuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.editor,
    );
    final file = await FileService.requireOwnReadyFile(
      session,
      actor,
      fileUuid,
      kind: StoredFileKind.thumbnail,
    );
    await FileService.attachToItem(session, file, item);
    final previous = item.thumbnailFileId;
    await DriveItem.db.updateWhere(
      session,
      columnValues: (t) => [t.thumbnailFileId(fileUuid)],
      where: (t) => t.id.equals(item.id!),
    );
    if (previous != null && previous != fileUuid) {
      await FileService.deleteFile(session, previous);
    }
    final updated = (await DriveItem.db.findById(session, item.id!))!;
    await DriveEvents.notify(session, updated, DriveChangeKind.updated);
    return DriveViews.one(session, actor.userId, updated, role: role);
  }

  static Future<List<ActivityEventView>> activity(
    Session session,
    Actor actor,
    UuidValue uuid, {
    int? beforeId,
    int limit = 50,
  }) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    return ActivityService.list(
      session,
      item.id!,
      beforeId: beforeId,
      limit: limit,
    );
  }

  /// Marks content as modified (throttled per item by the callers).
  static Future<void> touchModified(
    Session session,
    DriveItem item,
    int? userId, {
    String? searchText,
    int? sizeBytes,
  }) async {
    await DriveItem.db.updateWhere(
      session,
      columnValues: (t) => [
        t.modifiedAt(nowUtc()),
        t.modifiedById(userId),
        if (searchText != null) t.searchText(searchText),
      ],
      where: (t) => t.id.equals(item.id!),
    );
    // (v2) Content size through the storage counters (Drive 03 §2).
    if (sizeBytes != null) {
      await StorageService.instance.setItemSize(session, item, sizeBytes);
    }
    final updated = await DriveItem.db.findById(session, item.id!);
    if (updated != null) {
      await DriveEvents.notify(session, updated, DriveChangeKind.modified);
    }
  }
}
