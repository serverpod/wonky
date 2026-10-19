import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_slides_core/schema.dart' show SlidesCols, SlidesTables;
import 'package:wonky_slides_core/themes.dart' show BuiltInThemes;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/names.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/drive/drive_views.dart';
import '../../platform/drive/templates/builtin_templates.dart';
import '../../platform/revlog/rev_hooks.dart';
import '../../platform/revlog/rev_log_service.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/storage/content_sizes.dart';
import '../../platform/storage/storage_hooks.dart';
import '../../platform/storage/storage_service.dart';
import '../revlog/slides_rev_binding.dart';
import '../revlog/slides_server_writes.dart';
import '../templates/slides_template_decks.dart';
import 'deck_copies.dart';
import 'deck_factory.dart';

/// Server-side deck lifecycle (Slides 02 §9.3, RevLog spec 04 §5, 05 §8.3):
/// creating a deck (`drive.createPresentation`, MCP, AI; offline and
/// client-written creations with `initialize: false`) and mirroring drive
/// renames into `Deck.title`.
abstract final class SlidesDecks {
  /// Creates a deck: its drive item (uuid = file uuid) with the `rev_file`
  /// and, with [initialize], the content as revision 1… in one
  /// transaction — a blank deck with built-in theme [themeKey] and a title
  /// slide, a built-in presentation template (`SlidesTemplates`, SL-22) or,
  /// with a [templateUuid] the caller can read, a copy of that deck
  /// ([DeckCopies], SL-8; the quota is checked first, reason `template`).
  /// Blank decks are tiny and always allowed (Drive 03 §7.2).
  ///
  /// With [fileUuid] the call is idempotent (a retry returns the item).
  /// [initialize] false: the file stays at revision 0 and the client's first
  /// op creates the rows (offline creation, built-in templates and blank
  /// decks the app builds itself, version copies).
  static Future<DriveItemView> create(
    Session session,
    Actor actor, {
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
    String? themeKey,
    UuidValue? fileUuid,
    bool initialize = true,
  }) async {
    if (fileUuid != null) {
      final existing = await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.contentRef.equals(fileUuid) | t.uuid.equals(fileUuid),
      );
      if (existing != null) {
        if (existing.kind != DriveItemKind.presentation) {
          throw Errors.conflict('This id belongs to another item.');
        }
        if (existing.ownerId != actor.userId) {
          throw Errors.forbidden('This file belongs to someone else.');
        }
        return DriveService.get(session, actor, existing.uuid);
      }
    }
    if (!initialize) {
      return _createDeck(
        session,
        actor,
        parentUuid: parentUuid,
        name: name,
        fileUuid: fileUuid,
        summary: const {},
        changes: (_, _) => const [],
      );
    }
    if (templateUuid != null) {
      return _fromTemplate(
        session,
        actor,
        templateUuid,
        parentUuid: parentUuid,
        name: name,
        fileUuid: fileUuid,
      );
    }
    final theme = themeKey ?? BuiltInThemes.defaultKey;
    if (BuiltInThemes.byKey(theme) == null) {
      throw Errors.invalid('Unknown theme "$theme".');
    }
    return _createDeck(
      session,
      actor,
      parentUuid: parentUuid,
      name: name,
      fileUuid: fileUuid,
      summary: {'theme': theme},
      changes: (file, title) => DeckFactory.rows(
        deckSpace: file,
        authorUuid: actor.authUserId,
        title: title,
        themeKey: theme,
      ),
    );
  }

  /// Inserts the drive item of a new deck with its `rev_file` and commits
  /// [changes] as revision 1… in one transaction (RevLog spec 05 §8.3);
  /// then its size and the creation's activity.
  static Future<DriveItemView> _createDeck(
    Session session,
    Actor actor, {
    UuidValue? parentUuid,
    required String name,
    UuidValue? fileUuid,
    required Map<String, Object?> summary,
    required List<RowChange> Function(UuidValue file, String title) changes,
  }) async {
    final cleanName = normalizeItemName(name);
    final file = fileUuid ?? const Uuid().v7obj();
    final item = await createFile(
      session,
      actor,
      parentUuid: parentUuid,
      name: cleanName,
      fileUuid: file,
      initialChanges: changes(file, cleanName),
      label: DeckFactory.createLabel,
    );
    await ContentSizes.refresh(session, item);
    await DriveService.afterCreate(session, actor, item, summary: summary);
    return DriveViews.one(session, actor.userId, item, role: Role.owner);
  }

  /// The drive item and `rev_file` of a new deck with [initialChanges] as
  /// its first revisions, in one transaction (also for copies).
  static Future<DriveItem> createFile(
    Session session,
    Actor actor, {
    required UuidValue? parentUuid,
    required String name,
    required UuidValue fileUuid,
    required List<RowChange> initialChanges,
    required String label,
    String? description,
  }) async {
    final binding = SlidesRevBinding.instance;
    // Checks the folder before anything is created.
    await DriveService.parentFor(session, actor, parentUuid);
    final (item, rev) = await session.db.transaction<(DriveItem, RevFile)>((
      tx,
    ) async {
      final parent = await DriveService.parentFor(
        session,
        actor,
        parentUuid,
        transaction: tx,
      );
      final item = await DriveService.insertItem(
        session,
        actor,
        kind: DriveItemKind.presentation,
        name: name,
        parent: parent,
        contentRef: fileUuid,
        description: description,
        transaction: tx,
      );
      final rev = await RevLogService.createFile(
        session,
        binding: binding,
        item: item,
        submitter: RevSubmitter.of(actor),
        initialChanges: initialChanges,
        label: label,
        actorKind: actor.kind.name,
        transaction: tx,
      );
      return (item, rev);
    });
    if (initialChanges.isNotEmpty) {
      RevHooks.kick(session.serverpod, binding, rev.id!);
    }
    return item;
  }

  static Future<DriveItemView> _fromTemplate(
    Session session,
    Actor actor,
    UuidValue templateUuid, {
    UuidValue? parentUuid,
    required String name,
    UuidValue? fileUuid,
  }) async {
    final builtin = BuiltinTemplates.byUuid(templateUuid);
    if (builtin != null) {
      if (builtin.kind != DriveItemKind.presentation) {
        throw Errors.invalid('This is not a presentation template.');
      }
      // (SL-22) A built-in template: its deck is built by the core's
      // planner into the new file; the quota is checked first.
      final template = builtin.slides!;
      await StorageHooks.checkCaller(
        session,
        actor,
        SlidesTemplateDecks.estimate(template),
        QuotaReason.template,
      );
      return _createDeck(
        session,
        actor,
        parentUuid: parentUuid,
        name: name,
        fileUuid: fileUuid,
        summary: {'template': builtin.key},
        changes: (file, title) => SlidesTemplateDecks.changes(
          template,
          deckId: file,
          authorUuid: actor.authUserId,
          title: title,
        ),
      );
    }
    final (template, role) = await AccessService.require(
      session,
      actor,
      templateUuid,
      Role.viewer,
    );
    if (template.kind != DriveItemKind.presentation) {
      throw Errors.invalid('This is not a presentation template.');
    }
    if (role < Role.editor && !template.nonEditorsCanExport) {
      throw Errors.forbidden('The owner has disabled copying for viewers.');
    }
    final copied = await DeckCopies.copy(
      session,
      actor,
      template,
      name: name,
      parentUuid: parentUuid,
      quotaReason: QuotaReason.template,
      fileUuid: fileUuid,
    );
    await DriveService.afterCreate(
      session,
      actor,
      copied.item,
      summary: {'template': template.uuid.uuid},
    );
    return DriveViews.one(session, actor.userId, copied.item, role: Role.owner);
  }

  /// Writes a drive rename into `Deck.title` as a system op (RevLog spec
  /// 05 §8.3; not an undoable deck edit), when the deck row exists;
  /// otherwise the creation op picks up the name (04 §5).
  static Future<void> mirrorTitleToDeck(
    Session session,
    Actor actor,
    DriveItem item,
  ) async {
    if (item.kind != DriveItemKind.presentation || item.contentRef == null) {
      return;
    }
    try {
      final file = item.contentRef!;
      final rows = await session.db.unsafeQuery(
        'SELECT title FROM deck WHERE id = @id::uuid',
        parameters: QueryParameters.named({'id': file.uuid}),
      );
      if (rows.isEmpty) return;
      final title = rows.first[0] as String?;
      if (title == item.name) return;
      await SlidesServerWrites.apply(
        session,
        actor: actor.copyWith(kind: ActorKind.system),
        fileUuid: file,
        changes: [
          RowChange.update(
            SlidesTables.deck,
            file.uuid,
            {SlidesCols.title: title},
            {SlidesCols.title: item.name},
          ),
        ],
        label: 'Rename',
      );
    } on Exception catch (e) {
      session.log(
        'Could not mirror the title of ${item.uuid} to its deck: $e',
        level: LogLevel.warning,
      );
    }
  }
}
