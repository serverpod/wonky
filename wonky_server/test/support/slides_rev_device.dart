import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/apply.dart' show parentsFirst;
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_connection.dart';
import 'package:wonky_server/src/platform/revlog/rev_pages.dart';
import 'package:wonky_server/src/platform/revlog/rev_views.dart';
import 'package:wonky_server/src/slides/revlog/slides_rev_binding.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/schema.dart' show SlidesCols, SlidesTables;
import 'package:wonky_slides_core/themes.dart' show BuiltInThemes;

import 'sheets_rev_device.dart' show RevDeviceRejected;
import 'test_users.dart';

export 'sheets_rev_device.dart' show RevDeviceRejected;

/// A deck client for server tests (RevLog spec 09 §3, 08 §2): one
/// `RevLogConnection` of [user] to [fileUuid] and a [DeckModel] replica
/// that bootstraps from a structure page (decks are small), submits planner
/// ops and applies remote ops.
final class SlidesRevDevice {
  SlidesRevDevice._(this.user, this.fileUuid, this._input, this._out);

  /// The user.
  final TestUser user;

  /// The deck's file.
  final UuidValue fileUuid;

  final StreamController<RevClientMessage> _input;
  final StreamQueue<RevServerMessage> _out;

  /// The replica.
  late DeckModel model;

  /// The last revision applied.
  int revision = 0;

  /// The role the server reported.
  AccessRole role = AccessRole.viewer;

  /// Rejections received.
  final List<RevRejected> rejections = [];

  /// Acks received.
  final List<RevAck> acks = [];

  static final _binding = SlidesRevBinding.instance;

  /// Connects [user] to [fileUuid] and loads the deck.
  static Future<SlidesRevDevice> open(TestUser user, UuidValue fileUuid) async {
    final input = StreamController<RevClientMessage>();
    final out = StreamQueue(
      RevLogConnection.open(
        user.session,
        _binding,
        user.actor,
        fileUuid,
        0,
        'device-${user.name}-${const Uuid().v4()}',
        input.stream,
      ),
    );
    final d = SlidesRevDevice._(user, fileUuid, input, out);
    final init = await d._next();
    if (init is RevRejected) {
      throw StateError('connect failed: ${init.code} ${init.message}');
    }
    init as RevInit;
    d.role = init.role;
    await d._bootstrap();
    return d;
  }

  Future<RevServerMessage> _next() =>
      _out.next.timeout(const Duration(seconds: 15));

  Future<void> _bootstrap() async {
    final file = (await RevFile.db.findFirstRow(
      user.session,
      where: (t) => t.fileUuid.equals(fileUuid),
    ))!;
    final rows = <(String, Map<String, Object?>)>[];
    var rev = 0;
    String? cursor;
    do {
      final p = await RevPages.page(
        user.session,
        _binding,
        file,
        RevPageRequest(
          kind: RevPageKind.structure,
          cursor: cursor,
          maxRows: 20000,
        ),
      );
      rows.addAll(
        RevPageCodec.decode(
          _binding.schema,
          RevCodec.gunzip(
            p.body.buffer.asUint8List(
              p.body.offsetInBytes,
              p.body.lengthInBytes,
            ),
          ),
        ),
      );
      rev = p.revision;
      cursor = p.nextCursor;
    } while (cursor != null);
    model = DeckModel.fromRows(fileUuid.uuid, [
      for (final table in SlidesTables.dependencyOrder)
        for (final r in rows)
          if (r.$1 == table) r,
    ]);
    revision = rev;
    // Ops committed while the pages were read.
    await catchUp();
  }

  /// Applies the ops committed after [revision] (gap fill).
  Future<void> catchUp() async {
    final file = (await RevFile.db.findFirstRow(
      user.session,
      where: (t) => t.fileUuid.equals(fileUuid),
    ))!;
    if (file.headRevision <= revision) return;
    final views = await RevViews.read(
      user.session,
      _binding.codec,
      file.id!,
      revision + 1,
      file.headRevision,
    );
    for (final v in views) {
      _applyRemote(v);
    }
  }

  void _applyRemote(RevOpView v) {
    if (v.revision <= revision) return;
    model.applyChanges(RevViews.appliedOf(_binding.codec, v));
    revision = v.revision;
  }

  /// The planning context of this device's user.
  SlidesPlanContext get context => SlidesPlanContext(
    userId: user.authUserId.uuid,
    now: clock.now().toUtc(),
    isOwner: true,
  );

  /// Plans [op] on the replica, submits it and waits for its ack.
  Future<RevAck> execute(SlidesOperation op) async {
    final plan = const SlidesPlanner().plan(op, model, context);
    return submit(
      plan.changes,
      summary: plan.summary.toJson(),
      label: plan.label,
    );
  }

  /// The creation op of a deck created with `initialize: false` (the
  /// planner's `CreateDeck`, as the app writes it).
  Future<RevAck> createDeck(
    String title, {
    String themeKey = BuiltInThemes.defaultKey,
  }) => execute(
    CreateDeck(
      deckId: fileUuid.uuid,
      title: title,
      themeKey: themeKey,
      firstLayoutKey: 'title',
    ),
  );

  /// Submits [changes] (ordered parents first, as the client does) and
  /// waits for the ack (remote ops before it are applied first).
  Future<RevAck> submit(
    List<RowChange> changes, {
    Map<String, Object?>? summary,
    String label = 'Edit',
    bool offline = false,
  }) async {
    final id = UuidValue.fromString(const Uuid().v7());
    final ordered = parentsFirst(_binding.schema, changes);
    _input.add(
      RevSubmit(
        clientOpId: id,
        baseRevision: revision,
        payload: _binding.codec.encodeText(
          ordered,
          summary: summary ?? SlidesChangeSummary.of(ordered).toJson(),
        ),
        label: label,
        actorKind: ActorKind.user,
        groupIndex: 0,
        groupLast: true,
        offline: offline,
        createdAt: clock.now().toUtc(),
      ),
    );
    while (true) {
      final m = await _next();
      switch (m) {
        case RevRemoteOp():
          _applyRemote(m.op);
        case RevAck() when m.clientOpId == id:
          acks.add(m);
          await catchUp();
          return m;
        case RevRejected() when m.clientOpId == id:
          rejections.add(m);
          throw RevDeviceRejected(m);
        case RevRoleChanged():
          role = m.role;
        default:
          continue;
      }
    }
  }

  /// Receives and applies pending remote ops (a short wait).
  Future<void> sync() async {
    while (await _out.hasNext.timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => false,
    )) {
      final m = await _out.next;
      if (m is RevRemoteOp) _applyRemote(m.op);
      if (m is RevRoleChanged) role = m.role;
    }
    await catchUp();
  }

  /// The deck title (null before the creation op).
  String? get title => model.deck?.title;

  /// Renames the deck (the title column).
  Future<RevAck> rename(String title) => submit([
    RowChange.update(
      SlidesTables.deck,
      fileUuid.uuid,
      {SlidesCols.title: model.deck?.title},
      {SlidesCols.title: title},
    ),
  ], label: 'Rename presentation');

  /// Disconnects.
  Future<void> close() async {
    await _input.close();
    await _out.cancel(immediate: true);
  }
}
