import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../write/mcp/headless_editor.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../organizations/organization_service.dart';
import 'style_guides/builtin_style_guides.dart';

/// A resolved style guide: what the assistant follows.
class ResolvedStyleGuide {
  const ResolvedStyleGuide(this.ref, this.name, this.markdown);

  final String ref;
  final String name;
  final String markdown;
}

/// The style guide library (suite 10 §7): built-in guides, users' own
/// guides (personal or shared with their organization), an organization
/// default, and the guide each Write document uses.
///
/// Refs are `builtin:<key>` or `custom:<uuid>`. A document's guide is
/// readable by everyone who can open the document (its collaborators may
/// not see the owner's personal guides otherwise); the organization default
/// follows the requesting user's organization.
abstract final class StyleGuideService {
  static const maxName = 100;
  static const maxDescription = 300;
  static const maxMarkdown = 50000;

  static const sourceBuiltIn = 'builtIn';
  static const sourceMine = 'mine';
  static const sourceOrganization = 'organization';
  static const sourceDocument = 'document';

  static String customRef(UuidValue uuid) => 'custom:${uuid.uuid}';

  /// The uuid of a `custom:` ref (null for built-ins and invalid refs).
  static UuidValue? uuidOf(String ref) {
    if (!ref.startsWith('custom:')) return null;
    try {
      return UuidValue.withValidation(ref.substring(7));
    } on FormatException {
      return null;
    }
  }

  static StyleGuideView _builtinView(BuiltinStyleGuide g) => StyleGuideView(
    ref: g.ref,
    name: g.name,
    description: g.description,
    markdown: g.markdown,
    source: sourceBuiltIn,
    sharedWithOrg: false,
    editable: false,
  );

  static Future<StyleGuideView> _view(
    Session session,
    StyleGuide g,
    int userId, {
    String? source,
  }) async {
    final mine = g.ownerId == userId;
    String? ownerName;
    if (!mine) {
      ownerName = (await UserProfile.db.findById(
        session,
        g.ownerId,
      ))?.displayName;
    }
    return StyleGuideView(
      ref: customRef(g.uuid),
      name: g.name,
      description: g.description,
      markdown: g.markdown,
      source: source ?? (mine ? sourceMine : sourceOrganization),
      sharedWithOrg: g.orgKey != null,
      ownerName: ownerName,
      editable: mine,
      updatedAt: g.updatedAt,
    );
  }

  static Future<StyleGuide?> _custom(Session session, String ref) async {
    final uuid = uuidOf(ref);
    if (uuid == null) return null;
    return StyleGuide.db.findFirstRow(
      session,
      where: (g) => g.uuid.equals(uuid),
    );
  }

  /// Whether [userId] (in [orgKey]) may use [g] outside a document.
  static bool _visible(StyleGuide g, int userId, String? orgKey) =>
      g.ownerId == userId || (g.orgKey != null && g.orgKey == orgKey);

  /// Whether [ref] names a guide [userId] may pick.
  static Future<bool> _usable(
    Session session,
    String ref,
    int userId,
    String? orgKey,
  ) async {
    if (ref.startsWith('builtin:')) {
      return BuiltinStyleGuides.byKey(ref.substring(8)) != null;
    }
    final g = await _custom(session, ref);
    return g != null && _visible(g, userId, orgKey);
  }

  /// The guide of [ref] (any visibility; callers check access), or null.
  static Future<ResolvedStyleGuide?> resolveRef(
    Session session,
    String? ref,
  ) async {
    if (ref == null) return null;
    if (ref.startsWith('builtin:')) {
      final b = BuiltinStyleGuides.byKey(ref.substring(8));
      return b == null ? null : ResolvedStyleGuide(b.ref, b.name, b.markdown);
    }
    final g = await _custom(session, ref);
    return g == null ? null : ResolvedStyleGuide(ref, g.name, g.markdown);
  }

  static Future<String?> _orgDefaultRef(
    Session session,
    String? orgKey,
  ) async {
    if (orgKey == null) return null;
    final row = await StyleGuideOrgDefault.db.findFirstRow(
      session,
      where: (d) => d.orgKey.equals(orgKey),
    );
    return row?.styleRef;
  }

  static Future<String?> _documentRef(Session session, int itemId) async {
    final row = await DocumentStyleGuide.db.findFirstRow(
      session,
      where: (d) => d.itemId.equals(itemId),
    );
    return row?.styleRef;
  }

  /// The guide the document [itemId] uses for [userId]: its own choice,
  /// else the organization default; null when neither resolves.
  static Future<ResolvedStyleGuide?> forDocument(
    Session session,
    int userId,
    int itemId,
  ) async {
    final own = await resolveRef(session, await _documentRef(session, itemId));
    if (own != null) return own;
    final orgKey = await OrganizationService.orgKeyOf(session, userId);
    final def = await resolveRef(
      session,
      await _orgDefaultRef(session, orgKey),
    );
    if (def == null) return null;
    // A custom org default must still be shared with the organization.
    final g = await _custom(session, def.ref);
    if (g != null && !_visible(g, userId, orgKey)) return null;
    return def;
  }

  /// The user's library; with [itemUuid] also the document's choice.
  static Future<StyleGuideLibrary> library(
    Session session,
    Actor actor, {
    UuidValue? itemUuid,
  }) async {
    final userId = actor.userId;
    final orgKey = await OrganizationService.orgKeyOf(session, userId);
    final rows = await StyleGuide.db.find(
      session,
      where: (g) =>
          g.ownerId.equals(userId) |
          (orgKey == null ? g.id.equals(-1) : g.orgKey.equals(orgKey)),
      orderBy: (g) => g.name,
      limit: 500,
    );
    final guides = <StyleGuideView>[
      for (final b in BuiltinStyleGuides.all) _builtinView(b),
      for (final r in rows) await _view(session, r, userId),
    ];
    String? documentRef;
    var canSetDocument = false;
    if (itemUuid != null) {
      final target = await HeadlessDocumentEditor.resolve(
        session,
        actor,
        itemUuid,
      );
      canSetDocument = target.role >= Role.editor;
      final ref = await _documentRef(session, target.item.id!);
      if (ref != null && await resolveRef(session, ref) != null) {
        documentRef = ref;
        if (!guides.any((g) => g.ref == ref)) {
          final g = await _custom(session, ref);
          if (g != null) {
            guides.add(
              await _view(session, g, userId, source: sourceDocument),
            );
          }
        }
      }
    }
    var orgDefault = await _orgDefaultRef(session, orgKey);
    if (orgDefault != null && !guides.any((g) => g.ref == orgDefault)) {
      orgDefault = null;
    }
    return StyleGuideLibrary(
      guides: guides,
      orgKey: orgKey,
      orgDefaultRef: orgDefault,
      documentRef: documentRef,
      effectiveRef: documentRef ?? orgDefault,
      canSetDocument: canSetDocument,
      canSetOrgDefault: orgKey != null,
    );
  }

  static void _validate(StyleGuideInput input) {
    final name = input.name.trim();
    if (name.isEmpty) throw Errors.invalid('The style guide needs a name.');
    if (name.length > maxName) throw Errors.tooLarge('The name is too long.');
    if (input.description.length > maxDescription) {
      throw Errors.tooLarge('The description is too long.');
    }
    if (input.markdown.trim().isEmpty) {
      throw Errors.invalid('The style guide is empty.');
    }
    if (input.markdown.length > maxMarkdown) {
      throw Errors.tooLarge(
        'The style guide is too long (at most $maxMarkdown characters).',
      );
    }
  }

  /// Creates or updates one of the user's guides. With the uuid of a guide
  /// that no longer exists (undo of a delete) it is created again.
  static Future<StyleGuideView> save(
    Session session,
    Actor actor,
    StyleGuideInput input,
  ) async {
    _validate(input);
    final userId = actor.userId;
    final orgKey = input.shareWithOrg
        ? await OrganizationService.orgKeyOf(session, userId)
        : null;
    if (input.shareWithOrg && orgKey == null) {
      throw Errors.invalid(
        'You are not in an organization, so the guide cannot be shared.',
      );
    }
    final now = nowUtc();
    final uuid = input.uuid;
    final existing = uuid == null
        ? null
        : await StyleGuide.db.findFirstRow(
            session,
            where: (g) => g.uuid.equals(uuid),
          );
    if (existing != null && existing.ownerId != userId) {
      throw Errors.forbidden('Only the owner can change this style guide.');
    }
    final StyleGuide row;
    if (existing == null) {
      row = await StyleGuide.db.insertRow(
        session,
        StyleGuide(
          uuid: uuid,
          ownerId: userId,
          name: input.name.trim(),
          description: input.description.trim(),
          markdown: input.markdown,
          orgKey: orgKey,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      row = await StyleGuide.db.updateRow(
        session,
        existing.copyWith(
          name: input.name.trim(),
          description: input.description.trim(),
          markdown: input.markdown,
          orgKey: orgKey,
          updatedAt: now,
        ),
        columns: (t) => [
          t.name,
          t.description,
          t.markdown,
          t.orgKey,
          t.updatedAt,
        ],
      );
    }
    return _view(session, row, userId);
  }

  /// Deletes one of the user's guides (documents using it fall back to the
  /// organization default).
  static Future<void> delete(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final g = await StyleGuide.db.findFirstRow(
      session,
      where: (r) => r.uuid.equals(uuid),
    );
    if (g == null) throw Errors.notFound('Style guide');
    if (g.ownerId != actor.userId) {
      throw Errors.forbidden('Only the owner can delete this style guide.');
    }
    await StyleGuide.db.deleteRow(session, g);
  }

  /// Sets (or with null clears) the default of the user's organization.
  static Future<StyleGuideLibrary> setOrgDefault(
    Session session,
    Actor actor,
    String? ref,
  ) async {
    final orgKey = await OrganizationService.orgKeyOf(session, actor.userId);
    if (orgKey == null) {
      throw Errors.forbidden('You are not in an organization.');
    }
    final existing = await StyleGuideOrgDefault.db.findFirstRow(
      session,
      where: (d) => d.orgKey.equals(orgKey),
    );
    if (ref == null) {
      if (existing != null) {
        await StyleGuideOrgDefault.db.deleteRow(session, existing);
      }
    } else {
      // The default must be usable by the whole organization: a built-in
      // or a guide shared with it.
      final g = await _custom(session, ref);
      final ok = ref.startsWith('builtin:')
          ? BuiltinStyleGuides.byKey(ref.substring(8)) != null
          : g != null && g.orgKey == orgKey;
      if (!ok) {
        throw Errors.invalid(
          'Only a built-in style guide or one shared with your organization '
          'can be its default.',
        );
      }
      final row = StyleGuideOrgDefault(
        orgKey: orgKey,
        styleRef: ref,
        setById: actor.userId,
        updatedAt: nowUtc(),
      );
      if (existing == null) {
        await StyleGuideOrgDefault.db.insertRow(session, row);
      } else {
        await StyleGuideOrgDefault.db.updateRow(
          session,
          row.copyWith(id: existing.id),
          columns: (t) => [t.styleRef, t.setById, t.updatedAt],
        );
      }
    }
    return library(session, actor);
  }

  /// Sets (or with null clears) the style guide of a Write document
  /// (Editor+).
  static Future<StyleGuideLibrary> setDocumentStyle(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String? ref,
  ) async {
    final target = await HeadlessDocumentEditor.resolve(
      session,
      actor,
      itemUuid,
    );
    if (target.role < Role.editor) {
      throw Errors.forbidden('Only editors can change the style guide.');
    }
    final itemId = target.item.id!;
    final existing = await DocumentStyleGuide.db.findFirstRow(
      session,
      where: (d) => d.itemId.equals(itemId),
    );
    if (ref == null) {
      if (existing != null) {
        await DocumentStyleGuide.db.deleteRow(session, existing);
      }
    } else {
      final orgKey = await OrganizationService.orgKeyOf(session, actor.userId);
      // The current choice stays valid (undo), other guides must be ones
      // the user can pick.
      if (existing?.styleRef != ref &&
          !await _usable(session, ref, actor.userId, orgKey)) {
        throw Errors.notFound('Style guide');
      }
      final row = DocumentStyleGuide(
        itemId: itemId,
        styleRef: ref,
        setById: actor.userId,
        updatedAt: nowUtc(),
      );
      if (existing == null) {
        await DocumentStyleGuide.db.insertRow(session, row);
      } else {
        await DocumentStyleGuide.db.updateRow(
          session,
          row.copyWith(id: existing.id),
          columns: (t) => [t.styleRef, t.setById, t.updatedAt],
        );
      }
    }
    return library(session, actor, itemUuid: itemUuid);
  }
}
