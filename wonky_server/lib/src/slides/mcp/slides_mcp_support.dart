import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;
import 'package:wonky_sync_models/ids.dart' show Base62Uuid;

import '../../platform/common/models.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/sharing/access_service.dart';
import '../headless/headless_deck.dart';

/// Slides-specific tool error codes (Slides 11 §2.3); the suite codes
/// (`not_found`, `forbidden`, `invalid_args`, `busy`, …) come from
/// [McpErrorCode].
abstract final class SlidesErrorCode {
  static const invalidTarget = 'invalid_target';
  static const beingEdited = McpErrorCode.beingEdited;
  static const limitExceeded = McpErrorCode.limitExceeded;
  static const chartNoAccess = 'chart_no_access';
  static const chartExportDisabled = 'chart_export_disabled';
  static const chartNotFound = 'chart_not_found';
  static const chartTooLarge = 'chart_too_large';
  static const chartUnsupportedSpec = 'chart_unsupported_spec';
}

/// The presentation a tool call operates on: the drive item, the caller's
/// role and the headless deck.
class SlidesTarget {
  SlidesTarget(this.item, this.role, this.deck);

  final DriveItem item;
  final Role role;
  final ServerHeadlessDeck deck;

  /// The deck (space) uuid.
  UuidValue get space => item.contentRef!;

  /// The current (cached) model.
  DeckModel get model => deck.model;

  bool get canEdit => role >= Role.editor;
}

/// Shared helpers of the `slides.*` handlers: target resolution, slide and
/// element addressing (11 §1.5) and error mapping.
abstract final class SlidesMcp {
  static final _uuid = RegExp(
    '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    '[0-9a-fA-F]{12}',
  );
  static final _b62 = RegExp(r'^[0-9A-Za-z]{22}$');

  /// The uuid of a `deck` argument: a uuid or an app URL
  /// (`…/slides/p/<uuid>…`).
  static UuidValue parseRef(String ref, {String what = 'presentation'}) {
    final m = _uuid.firstMatch(ref.trim());
    if (m == null) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Unknown $what "$ref": pass its uuid or URL.',
      );
    }
    return UuidValue.withValidation(m.group(0)!.toLowerCase());
  }

  /// Resolves the presentation [ref] for [ctx] with at least [min].
  static Future<SlidesTarget> openRef(
    ToolContext ctx,
    String ref, {
    Role min = Role.viewer,
  }) async {
    final session = ctx.session;
    final uuid = parseRef(ref);
    var item = await AccessService.findItem(session, uuid);
    item ??= await DriveItem.db.findFirstRow(
      session,
      where: (t) =>
          t.contentRef.equals(uuid) & t.kind.equals(DriveItemKind.presentation),
    );
    final role = item == null
        ? null
        : await AccessService.effectiveRole(session, ctx.actor.userId, item);
    if (item == null ||
        role == null ||
        item.trashedAt != null && min > Role.viewer) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Presentation not found or not visible to you.',
      );
    }
    if (item.kind != DriveItemKind.presentation || item.contentRef == null) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        '"${item.name}" is not a presentation.',
      );
    }
    if (!(role >= min)) {
      throw McpToolException(
        McpErrorCode.forbidden,
        min >= Role.editor
            ? 'You need edit access to change this presentation (your role: '
                  '${role.name}).'
            : 'You do not have access to this presentation.',
      );
    }
    final deck = await const SlidesHeadlessProvider().open(
      HeadlessDeckContext(session, ctx.actor),
      item.contentRef!.uuid,
    );
    // AI Suggest mode: the run's shadow deck (11 §6.3).
    deck.overlay = DeckOverlays.of(ctx.groupId, item.contentRef!);
    return SlidesTarget(item, role, deck);
  }

  /// Resolves the `deck` argument of a tool call.
  static Future<SlidesTarget> open(
    ToolContext ctx,
    ToolArgs a, {
    Role min = Role.viewer,
  }) => openRef(ctx, a.requireString('deck'), min: min);

  /// [open] for a tool that edits the deck (Editor+).
  static Future<SlidesTarget> edit(ToolContext ctx, ToolArgs a) =>
      open(ctx, a, min: Role.editor);

  // ------------------------------------------------------------- slides

  /// The canonical id of a slide id given as uuid or base-62 id, or null.
  static String? canonicalId(String raw) {
    final t = raw.trim();
    if (_b62.hasMatch(t)) {
      try {
        return Base62Uuid.decode(t);
      } on Object {
        return null;
      }
    }
    final m = _uuid.firstMatch(t);
    return m?.group(0)?.toLowerCase();
  }

  /// The slide id of a `SlideRef` (id or 1-based position).
  static String slideId(DeckModel m, Object? ref, {String pointer = '/slide'}) {
    final slides = m.slides;
    if (ref is num) {
      final i = ref.toInt();
      if (i < 1 || i > slides.length) {
        throw McpToolException(
          McpErrorCode.notFound,
          'There is no slide $i (the presentation has ${slides.length}).',
          details: {'pointer': pointer},
        );
      }
      return slides[i - 1].id;
    }
    if (ref is String) {
      final id = canonicalId(ref);
      if (id != null && m.slide(id) != null) return id;
      final n = int.tryParse(ref.trim());
      if (n != null) return slideId(m, n, pointer: pointer);
    }
    throw McpToolException(
      McpErrorCode.notFound,
      'Slide "$ref" not found. Use a slide id from slides.get_deck or a '
      '1-based position.',
      details: {'pointer': pointer},
    );
  }

  /// The slide ids of [refs], de-duplicated in order.
  static List<String> slideIds(
    DeckModel m,
    List<Object?>? refs, {
    String pointer = '/slides',
  }) => {
    for (final (i, r) in (refs ?? const []).indexed)
      slideId(m, r, pointer: '$pointer/$i'),
  }.toList();

  /// The 1-based position of [slideId] (0 when not found).
  static int positionOf(DeckModel m, String slideId) {
    final i = m.slides.indexWhere((s) => s.id == slideId);
    return i + 1;
  }

  /// A group id (uuid or base-62).
  static String groupId(
    DeckModel m,
    String? raw, {
    String pointer = '/group_id',
  }) {
    final id = raw == null ? null : canonicalId(raw);
    if (id == null || m.group(id) == null) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Group "$raw" not found (slides.get_deck lists the groups).',
        details: {'pointer': pointer},
      );
    }
    return id;
  }

  // ----------------------------------------------------------- elements

  /// The placeholders of [type] on [slideId] in order (z order).
  static List<SlideElementRec> placeholders(
    DeckModel m,
    String slideId,
    SlidePlaceholderType type,
  ) {
    final list =
        [
          for (final e in m.elementsOf(slideId))
            if (e.placeholderType == type) e,
        ]..sort((a, b) {
          final c = a.zKey.compareTo(b.zKey);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    return list;
  }

  /// The element id of an `ElementRef` (id, `{slide, placeholder, index}`
  /// or `{slide, name}`).
  static String elementId(
    DeckModel m,
    Object? ref, {
    String pointer = '/element',
  }) {
    if (ref is String) {
      final id = canonicalId(ref);
      if (id != null && m.element(id) != null) return id;
    } else if (ref is Map) {
      final slide = slideId(m, ref['slide'], pointer: '$pointer/slide');
      final type = ref['placeholder'];
      if (type is String) {
        final t = SlidePlaceholderType.fromName(type);
        if (t == null) {
          throw McpToolException(
            McpErrorCode.invalidArgs,
            'Unknown placeholder type "$type".',
            details: [
              {'pointer': '$pointer/placeholder', 'message': 'unknown type'},
            ],
          );
        }
        final list = placeholders(m, slide, t);
        final index = (ref['index'] as num?)?.toInt() ?? 1;
        if (index >= 1 && index <= list.length) return list[index - 1].id;
        throw McpToolException(
          McpErrorCode.notFound,
          'Slide ${positionOf(m, slide)} has '
          '${list.isEmpty ? 'no' : 'only ${list.length}'} $type '
          'placeholder${list.length == 1 ? '' : 's'}.',
          details: {'pointer': pointer},
        );
      }
      final name = ref['name'];
      if (name is String) {
        final wanted = name.trim().toLowerCase();
        for (final e in m.allElementsOf(slide)) {
          final own = e.name;
          final layoutName = e.placeholderOf == null
              ? null
              : m.element(e.placeholderOf!)?.name;
          if ((own ?? layoutName)?.trim().toLowerCase() == wanted) return e.id;
        }
      }
    }
    throw McpToolException(
      McpErrorCode.notFound,
      'Element ${ref is String ? '"$ref" ' : ''}not found (slides.get_slide '
      'lists the elements).',
      details: {'pointer': pointer},
    );
  }

  /// The element ids of [refs], de-duplicated in order.
  static List<String> elementIds(
    DeckModel m,
    List<Object?>? refs, {
    String pointer = '/elements',
  }) => {
    for (final (i, r) in (refs ?? const []).indexed)
      elementId(m, r, pointer: '$pointer/$i'),
  }.toList();

  /// The element [id], which must be of one of [kinds].
  static SlideElementRec elementOfKind(
    DeckModel m,
    String id,
    Set<ElementKind> kinds,
    String what,
  ) {
    final e = m.element(id)!;
    if (!kinds.contains(e.kind)) {
      throw McpToolException(
        SlidesErrorCode.invalidTarget,
        'Element $id is a ${e.kind.name}, not $what.',
        details: {'element_id': id, 'kind': e.kind.name},
      );
    }
    return e;
  }

  /// The layout of key or id [ref] in the theme of [themeId] (null = the
  /// deck theme); null when unknown.
  static SlideLayoutRec? layout(DeckModel m, String ref, {String? themeId}) {
    final id = canonicalId(ref);
    if (id != null && m.layout(id) != null) return m.layout(id);
    final key = switch (ref) {
      'twoColumn' => 'twoColumns',
      'titleCode' => 'code',
      'titleAndBody' || 'titleContent' => 'titleBody',
      _ => ref,
    };
    final theme = themeId ?? m.deck?.themeId ?? m.themes.firstOrNull?.id;
    if (theme == null) return null;
    for (final master in m.mastersOf(theme)) {
      for (final l in m.layoutsOf(master.id)) {
        if (l.key == key) return l;
      }
    }
    for (final master in m.mastersOf(theme)) {
      for (final l in m.layoutsOf(master.id)) {
        if (l.key?.toLowerCase() == key.toLowerCase() ||
            l.name.toLowerCase() == key.toLowerCase()) {
          return l;
        }
      }
    }
    return null;
  }

  /// The layout keys of the deck theme (error messages).
  static List<String> layoutKeys(DeckModel m) {
    final theme = m.deck?.themeId ?? m.themes.firstOrNull?.id;
    if (theme == null) return const [];
    return [
      for (final master in m.mastersOf(theme))
        for (final l in m.layoutsOf(master.id))
          if (l.key != null) l.key!,
    ];
  }

  /// The theme a slide uses (its layout's), else the deck theme.
  static String? themeOfSlide(DeckModel m, String slideId) {
    final layoutId = m.slide(slideId)?.layoutId;
    final layout = layoutId == null ? null : m.layout(layoutId);
    final master = layout?.masterId == null
        ? null
        : m.master(layout!.masterId!);
    return master?.themeId ?? m.deck?.themeId;
  }

  // -------------------------------------------------------------- errors

  /// Maps a planner refusal to a tool error (11 §2.3).
  static McpToolException fromPlan(PlanException e) {
    final code = switch (e.code) {
      PlanException.limit => SlidesErrorCode.limitExceeded,
      PlanException.notFound => McpErrorCode.notFound,
      PlanException.locked => McpErrorCode.conflict,
      PlanException.unsupported => McpErrorCode.unsupported,
      PlanException.permission => McpErrorCode.forbidden,
      _ => McpErrorCode.invalidArgs,
    };
    return McpToolException(
      code,
      e.message,
      details: e.details.isEmpty ? null : e.details,
    );
  }

  /// Maps the headless deck's `being_edited` conflict (SL-8) to the tool
  /// error `being_edited {targets}`; other errors stay as they are.
  static McpToolException? beingEdited(WonkyException e) {
    final raw = e.detailsJson;
    if (e.code != WonkyErrorCode.conflict || raw == null) return null;
    try {
      final d = jsonDecode(raw);
      if (d is Map && d['code'] == ServerHeadlessDeck.beingEditedCode) {
        return McpToolException(
          SlidesErrorCode.beingEdited,
          e.message,
          details: {'targets': d['targets'] ?? const <Object?>[]},
        );
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  /// `invalid_args` with a pointer.
  static McpToolException invalid(String message, {String? pointer}) =>
      McpToolException(
        McpErrorCode.invalidArgs,
        message,
        details: pointer == null
            ? null
            : [
                {'pointer': pointer, 'message': message},
              ],
      );
}
