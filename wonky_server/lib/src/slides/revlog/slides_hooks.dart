import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/rows.dart' show RowOp;
import 'package:wonky_slides_core/schema.dart' show SlidesCols, SlidesTables;

import '../../platform/activity/activity_service.dart';
import '../../platform/comments/comment_service.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/drive/drive_events.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/drive/drive_user_state.dart';
import '../../platform/revlog/rev_hooks.dart';
import '../../platform/storage/content_sizes.dart';
import '../../platform/versions/version_service.dart';
import 'deck_comments.dart';

/// The durable post-commit hooks of decks (RevLog spec 05 §6.2, 08 §1),
/// replacing `DeckChangeLogProcessor` and its plugins (Slides 09 §5).
abstract final class SlidesHooks {
  /// In run order.
  static final List<RevHook> all = [
    _Activity(),
    _Versions(),
    _DriveEdit(),
    _Title(),
    _Modified(),
    _Comments(),
    _ContentSize(),
  ];
}

/// The parsed summary of a deck op (Slides 02 §3.10.1), lenient: unknown or
/// malformed content reads as empty.
final class DeckChangeSummaryView {
  /// Wraps decoded summary JSON.
  DeckChangeSummaryView(this.json);

  /// Parses `summaryJson` (null = empty).
  factory DeckChangeSummaryView.parse(String? summaryJson) {
    if (summaryJson == null) return DeckChangeSummaryView(const {});
    try {
      final v = jsonDecode(summaryJson);
      if (v is Map) return DeckChangeSummaryView(v.cast<String, Object?>());
    } on FormatException {
      // Malformed: empty.
    }
    return DeckChangeSummaryView(const {});
  }

  /// The JSON.
  final Map<String, Object?> json;

  List<String> _list(Object? v) => [
    if (v is List)
      for (final e in v)
        if (e is String) e,
  ];

  /// Change kinds.
  Set<String> get kinds => _list(json['kinds']).toSet();

  /// Slides touched.
  List<String> get slides => _list(json['slides']);

  /// Elements touched.
  List<String> get elements => _list(json['elements']);

  /// Deleted ids of [category] (`slides`, `elements`, `groups`, `themes`).
  List<String> deleted(String category) =>
      _list((json['deleted'] as Map?)?[category]);

  /// Revived ids of [category].
  List<String> revived(String category) =>
      _list((json['revived'] as Map?)?[category]);
}

/// Ops by author (user_profile id), skipping system ops without one.
Map<int, List<RevOpRecord>> _byAuthor(List<RevOpRecord> ops) {
  final out = <int, List<RevOpRecord>>{};
  for (final o in ops) {
    final id = o.op.authorId;
    if (id != null) (out[id] ??= []).add(o);
  }
  return out;
}

/// One edit event per author and 10-minute window (`ActivityService.logEdit`
/// aggregates) with the counters `changes`, `slides` (slides touched),
/// `slidesDeleted` and `themes`, and the set `slideIds` (Slides 09 §5,
/// SL-39). Repairs and system ops don't count.
final class _Activity extends RevHook {
  @override
  String get id => 'activity';

  @override
  bool wants(RevOpRecord op) => op.op.actorKind != ActorKind.system;

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    final byActor = <String, (Actor, Map<String, num>, Set<String>)>{};
    for (final o in ops) {
      final userId = o.op.authorId;
      final authUuid = o.op.authorUuid;
      if (userId == null || authUuid == null) continue;
      if (o.summary['repair'] == true) continue;
      final summary = DeckChangeSummaryView(o.summary);
      final entry = byActor.putIfAbsent(
        '$userId|${o.op.actorKind.name}',
        () => (
          Actor(
            userId: userId,
            authUserId: authUuid,
            kind: o.op.actorKind,
            sessionId: o.op.sessionId,
          ),
          <String, num>{},
          <String>{},
        ),
      );
      final counters = entry.$2;
      void count(String key, num n) {
        if (n == 0) return;
        counters[key] = (counters[key] ?? 0) + n;
      }

      count('changes', 1);
      entry.$3.addAll(summary.slides);
      count('slidesDeleted', summary.deleted('slides').length);
      if (summary.kinds.contains('theme')) count('themes', 1);
    }
    for (final (actor, counters, slides) in byActor.values) {
      if (slides.isNotEmpty) counters['slides'] = slides.length;
      await ActivityService.logEdit(
        ctx.session,
        item.id!,
        actor,
        counters: counters,
        // Distinct slides of the 10-minute event (09 §5; SL-39).
        sets: {if (slides.isNotEmpty) 'slideIds': slides},
      );
    }
  }
}

/// The shared version state per author (`ItemVersionState`, 09 §4.1).
final class _Versions extends RevHook {
  @override
  String get id => 'versions';

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    for (final userId in _byAuthor(ops).keys) {
      await VersionService.recordEdit(ctx.session, item, userId);
    }
  }
}

/// The drive "last edited" state per author.
final class _DriveEdit extends RevHook {
  @override
  String get id => 'driveEdit';

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    for (final userId in _byAuthor(ops).keys) {
      await DriveUserStates.recordEdit(ctx.session, userId, item);
    }
  }
}

/// `Deck.title` → `DriveItem.name` when an op wrote the title. System ops
/// (the drive rename mirrored into the deck) are skipped. Invalid names
/// (empty, too long, with `/`) are not mirrored.
final class _Title extends RevHook {
  @override
  String get id => 'title';

  @override
  bool wants(RevOpRecord op) =>
      op.op.actorKind != ActorKind.system &&
      op.applied.any(
        (c) =>
            c.table == SlidesTables.deck &&
            c.op != RowOp.delete &&
            c.columnsAfter.containsKey(SlidesCols.title),
      );

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    String? title;
    for (final o in ops) {
      for (final c in o.applied) {
        if (c.table == SlidesTables.deck &&
            c.columnsAfter.containsKey(SlidesCols.title)) {
          title = c.columnsAfter[SlidesCols.title] as String?;
        }
      }
    }
    title = title?.trim();
    if (title == null ||
        title.isEmpty ||
        title.length > 255 ||
        title.contains('/')) {
      return;
    }
    final current = await DriveItem.db.findById(ctx.session, item.id!);
    if (current == null || current.name == title) return;
    final updated = await DriveItem.db.updateRow(
      ctx.session,
      current.copyWith(name: title),
      columns: (t) => [t.name],
    );
    await DriveEvents.notify(ctx.session, updated, DriveChangeKind.updated);
  }
}

/// `modifiedAt` and the search text ([DeckSearchText]), at most every 10 s
/// per deck (a trailing run follows).
final class _Modified extends RevHook {
  @override
  String get id => 'modified';

  @override
  Duration get minInterval => const Duration(seconds: 10);

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    final userId = ops.reversed
        .map((o) => o.op.authorId)
        .firstWhere((id) => id != null, orElse: () => null);
    final fresh = await DriveItem.db.findById(ctx.session, item.id!);
    if (fresh == null) return;
    await DriveService.touchModified(
      ctx.session,
      fresh,
      userId ?? fresh.ownerId,
      searchText: await DeckSearchText.of(ctx.session, ctx.file.id!),
    );
  }
}

/// The search text of a deck (Slides 09 §5): title, group titles, slide
/// text (elements and table cells, up to [maxRows] rows each) and speaker
/// notes, at most [maxText] characters. Targeted reads by `fileId`.
abstract final class DeckSearchText {
  /// Max characters.
  static const maxText = 100000;

  /// Max elements and cells read.
  static const maxRows = 10000;

  /// The search text of the deck file [fileId].
  static Future<String> of(Session session, int fileId) async {
    final out = StringBuffer();
    void add(String? s) {
      final t = s?.trim();
      if (t == null || t.isEmpty) return;
      if (out.isNotEmpty) out.write(' ');
      out.write(t);
    }

    Future<List<String?>> read(String sql) async => [
      for (final r in await session.db.unsafeQuery(
        sql,
        parameters: QueryParameters.named({
          'f': fileId,
          if (sql.contains('@n')) 'n': maxRows,
        }),
      ))
        r[0] as String?,
    ];

    for (final t in await read('SELECT title FROM deck WHERE "fileId" = @f')) {
      add(t);
    }
    for (final t in await read(
      'SELECT title FROM slide_group WHERE "fileId" = @f ORDER BY "sortKey"',
    )) {
      add(t);
    }
    for (final t in await read(
      'SELECT text FROM slide_element WHERE "fileId" = @f '
      'AND "slideId" IS NOT NULL AND text IS NOT NULL LIMIT @n',
    )) {
      add(plainText(t));
    }
    for (final t in await read(
      'SELECT text FROM slide_table_cell WHERE "fileId" = @f '
      'AND text IS NOT NULL LIMIT @n',
    )) {
      add(plainText(t));
    }
    for (final t in await read(
      'SELECT notes FROM slide WHERE "fileId" = @f AND notes IS NOT NULL '
      'ORDER BY "sortKey"',
    )) {
      add(plainText(t));
    }
    final text = out.toString();
    return text.length > maxText ? text.substring(0, maxText) : text;
  }

  /// [of] by the deck's file uuid ('' when the file is missing).
  static Future<String> ofFile(Session session, UuidValue fileUuid) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    return file == null ? '' : of(session, file.id!);
  }

  /// The plain text of a Delta JSON string (02 §4.1; string inserts only).
  static String? plainText(String? delta) {
    if (delta == null) return null;
    try {
      final ops = jsonDecode(delta);
      if (ops is! List) return null;
      final out = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) out.write(op['insert']);
      }
      return out.toString().replaceAll('\n', ' ');
    } on FormatException {
      return null;
    }
  }
}

/// Open threads anchored to a deleted slide or element become `orphaned`
/// (`orphanReasonJson {kind: slide|element, id, revision}`); when the
/// deletion is undone (the ids come back in the summary's `revived`) the
/// previous status is restored (Slides 09 §3.2). Element anchors orphan on
/// the element's deletion (the element id is authoritative: an element
/// moved to another slide survives that slide); the reason says `slide`
/// when its slide went with it.
final class _Comments extends RevHook {
  @override
  String get id => 'comments';

  @override
  bool wants(RevOpRecord op) {
    final s = DeckChangeSummaryView(op.summary);
    return s.deleted('slides').isNotEmpty ||
        s.deleted('elements').isNotEmpty ||
        s.revived('slides').isNotEmpty ||
        s.revived('elements').isNotEmpty;
  }

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    final session = ctx.session;
    for (final o in ops) {
      final summary = DeckChangeSummaryView(o.summary);
      final deletedSlides = summary.deleted('slides').toSet();
      final deletedElements = summary.deleted('elements').toSet();
      final revived = {
        ...summary.revived('slides'),
        ...summary.revived('elements'),
      };
      final threads = await CommentThread.db.find(
        session,
        where: (t) =>
            t.itemId.equals(item.id!) &
            t.anchorKind.inSet({
              CommentAnchorKind.slide,
              CommentAnchorKind.element,
            }),
      );
      for (final thread in threads) {
        if (thread.status == CommentStatus.orphaned) {
          final reason = _reasonId(thread.orphanReasonJson);
          if (reason != null && revived.contains(reason)) {
            await CommentService.revive(session, thread, item);
          }
          continue;
        }
        final a = DeckCommentAnchorIds.of(thread.anchorKind, thread.anchorJson);
        if (a == null) continue;
        final element = a.elementId;
        final (String, String)? reason;
        if (element != null) {
          reason = !deletedElements.contains(element)
              ? null
              : a.slideId != null && deletedSlides.contains(a.slideId)
              ? ('slide', a.slideId!)
              : ('element', element);
        } else {
          reason = a.slideId != null && deletedSlides.contains(a.slideId)
              ? ('slide', a.slideId!)
              : null;
        }
        if (reason == null) continue;
        await CommentService.orphan(
          session,
          thread,
          item,
          reason: {'kind': reason.$1, 'id': reason.$2, 'revision': o.revision},
        );
      }
    }
  }

  static String? _reasonId(String? json) {
    if (json == null) return null;
    try {
      final j = jsonDecode(json);
      return j is Map && j['id'] is String ? j['id'] as String : null;
    } on FormatException {
      return null;
    }
  }
}

/// The deck's content size for the owner's storage (throttled per item).
final class _ContentSize extends RevHook {
  @override
  String get id => 'contentSize';

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    await ContentSizes.onSpaceChanged(ctx.session, item);
  }
}
