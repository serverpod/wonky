import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../slides/templates/slides_template_decks.dart';

import '../../write/content/write_content.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../sharing/access_service.dart';
import '../storage/content_sizes.dart';
import '../storage/storage_hooks.dart';
import 'drive_events.dart';
import 'drive_listing.dart';
import 'drive_views.dart';
import 'templates/builtin_templates.dart';

/// Templates of the template gallery (specs/05 §2, Drive 02 §8): built-in
/// and published ones, and publishing an item as a template.
abstract final class DriveTemplates {
  static Future<List<TemplateView>> listTemplates(
    Session session,
    Actor actor,
    DriveItemKind? kind,
  ) async {
    final result = <TemplateView>[
      for (final t in BuiltinTemplates.all)
        if (t.inGallery && (kind == null || t.kind == kind))
          TemplateView(
            uuid: t.uuid,
            key: t.key,
            kind: t.kind,
            name: t.name,
            description: t.description,
            category: t.category,
            builtin: true,
            previewText: t.previewText,
            themeKey: t.themeKey,
            previewStyle: t.previewStyle,
            sizeBytes: _builtinSize(t),
          ),
    ];
    // Visibility in SQL: the caller's own templates never fall out of a
    // global limit.
    final published = await DriveListing.visibleTemplates(
      session,
      actor,
      kind: kind,
    );
    for (final item in published) {
      result.add(
        TemplateView(
          uuid: item.uuid,
          kind: item.kind,
          name: item.name,
          description: item.description ?? '',
          category: item.templateOf!,
          builtin: false,
          previewText: (item.searchText ?? '').length > 140
              ? '${item.searchText!.substring(0, 140)}…'
              : item.searchText ?? '',
          thumbnailFileId: item.thumbnailFileId,
          sizeBytes: item.sizeBytes + item.attachmentBytes,
        ),
      );
    }
    return result;
  }

  static final Map<String, int> _builtinSizes = {};

  /// (v2) The pre-check size of an item made from a built-in template
  /// (`TemplateView.sizeBytes`, Drive 03 §6.5).
  static int _builtinSize(BuiltinTemplate t) =>
      _builtinSizes[t.key] ??= t.slides != null
      ? SlidesTemplateDecks.estimate(t.slides!)
      : t.markdown != null
      ? DocumentSize.of(WriteContent.fromMarkdown(t.markdown!).delta)
      : StorageHooks.sheetsEstimate(t.sheets);

  /// Publishes (or unpublishes with null) an owned item as a template.
  static Future<DriveItemView> setTemplate(
    Session session,
    Actor actor,
    UuidValue uuid,
    TemplateCategory? category,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.owner,
    );
    if (item.kind == DriveItemKind.folder) {
      throw Errors.invalid('Folders cannot be templates.');
    }
    await DriveItem.db.updateWhere(
      session,
      columnValues: (t) => [t.templateOf(category)],
      where: (t) => t.id.equals(item.id!),
    );
    final updated = (await DriveItem.db.findById(session, item.id!))!;
    await DriveEvents.notify(session, updated, DriveChangeKind.updated);
    return DriveViews.one(session, actor.userId, updated, role: role);
  }
}
