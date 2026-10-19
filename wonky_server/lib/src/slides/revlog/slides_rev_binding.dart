import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart' show RowChange, RowOp;
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/ops.dart' show SlidesChangeSummary;
import 'package:wonky_slides_core/revlog.dart';
import 'package:wonky_slides_core/schema.dart'
    show ElementCols, SlidesCols, SlidesTables;

import '../../platform/common/models.dart';
import '../../platform/revlog/rev_binding.dart';
import '../../platform/revlog/rev_hooks.dart';
import 'slides_hooks.dart';

/// The RevLog binding of decks (RevLog spec 05 §1, 08 §1). The headless
/// model is the core [DeckModel].
final class SlidesRevBinding extends RevBinding {
  SlidesRevBinding._();

  /// The instance registered at startup.
  static final instance = SlidesRevBinding._();

  /// The owner columns of `slide_element`: exactly one is set (02 §3.5).
  static const ownerColumns = [
    SlidesCols.slideId,
    ElementCols.layoutId,
    ElementCols.masterId,
  ];

  @override
  RevFileKind get kind => RevFileKind.deck;

  @override
  RevSchema get schema => slidesSchema;

  @override
  DriveItemKind get itemKind => DriveItemKind.presentation;

  @override
  String get rootTitleColumn => SlidesCols.title;

  /// `contentCount` = elements (`stats.tables` also has the slides).
  @override
  int contentCount(RevStats stats) =>
      stats.tables[SlidesTables.slideElement] ?? 0;

  /// Exactly one owner FK on every `slide_element` the op writes (03 §5
  /// rule 6; the planner's invariant). There is no server element limit:
  /// 50,000 stays a client storage cap.
  @override
  Future<void> authorize(
    Session session,
    Transaction transaction,
    ChangeSet cs,
    ApplyResult applied,
    RevAuthor author,
    RevStats statsAfter,
    RevModelAccess models,
  ) async {
    final inserted = <String, Map<String, Object?>>{};
    final updated = <String, Map<String, Object?>>{};
    for (final c in applied.applied) {
      if (c.table != SlidesTables.slideElement) continue;
      switch (c.op) {
        case RowOp.insert:
          inserted[c.rowId] = {
            for (final k in ownerColumns) k: c.columnsAfter[k],
          };
        case RowOp.update:
          if (!ownerColumns.any(c.columnsAfter.containsKey)) continue;
          final row = inserted[c.rowId] ?? (updated[c.rowId] ??= {});
          for (final k in ownerColumns) {
            if (c.columnsAfter.containsKey(k)) row[k] = c.columnsAfter[k];
          }
        case RowOp.delete:
          inserted.remove(c.rowId);
          updated.remove(c.rowId);
      }
    }
    if (updated.isNotEmpty) {
      // Updates name only their columns: the others come from the stored
      // row (the op is not written yet).
      final rows = await session.db.unsafeQuery(
        'SELECT id::text, "slideId"::text, "layoutId"::text, '
        '"masterId"::text FROM slide_element WHERE id = ANY(@ids::uuid[])',
        parameters: QueryParameters.named({'ids': updated.keys.toList()}),
        transaction: transaction,
      );
      for (final r in rows) {
        final row = updated[r[0]! as String]!;
        for (final (i, k) in ownerColumns.indexed) {
          if (!row.containsKey(k)) row[k] = r[i + 1];
        }
      }
    }
    for (final MapEntry(key: id, value: row) in {
      ...inserted,
      ...updated,
    }.entries) {
      final owners = ownerColumns.where((k) => row[k] != null).length;
      if (owners != 1) {
        throw RevRejection(
          RevRejectReason.invalidChange,
          'Element $id must belong to exactly one slide, layout or master.',
        );
      }
    }
  }

  @override
  String summarize(List<RowChange> changes) =>
      jsonEncode(SlidesChangeSummary.of(changes).toJson());

  @override
  List<RevHook> get hooks => SlidesHooks.all;

  @override
  Object buildModel(
    UuidValue fileUuid,
    Iterable<(String, Map<String, Object?>)> rows,
  ) {
    final byTable = <String, List<(String, Map<String, Object?>)>>{};
    for (final r in rows) {
      (byTable[r.$1] ??= []).add(r);
    }
    return DeckModel.fromRows(fileUuid.uuid, [
      for (final t in SlidesTables.dependencyOrder) ...?byTable[t],
    ]);
  }

  @override
  void applyToModel(Object model, List<RowChange> applied) =>
      (model as DeckModel).applyChanges(applied);

  /// Elements carry JSON and text (~1 KB), other rows ~300 bytes.
  @override
  int estimateBytes(Object model) {
    final deck = model as DeckModel;
    var bytes = 64 * 1024;
    for (final t in SlidesTables.dependencyOrder) {
      final n = deck.count(t);
      bytes += t == SlidesTables.slideElement ? n * 1024 : n * 300;
    }
    return bytes;
  }
}
