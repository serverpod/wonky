import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/themes.dart' show BuiltInThemes;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_sync_models/ids.dart';

import '../../platform/common/errors.dart';
import '../../platform/common/time.dart';

/// Creates deck content server-side (Slides 02 §9.3): the
/// rows of the planner's `CreateDeck` — the `deck` row (id = file
/// uuid), a copy of a built-in theme with the deterministic ids of 02 §2.1
/// and one slide with layout `title` and its placeholder instances —
/// committed by `RevLogService.createFile` as the creation op ("Create
/// presentation"). The same rows a client writes offline (SL-9).
abstract final class DeckFactory {
  /// The label of the creation op.
  static const createLabel = 'Create presentation';

  /// The rows of a new deck as inserts (dependency order).
  static List<RowChange> rows({
    required UuidValue deckSpace,
    required UuidValue authorUuid,
    required String title,
    String themeKey = BuiltInThemes.defaultKey,
    String? firstLayoutKey = 'title',
    IdGenerator ids = const UuidV7IdGenerator(),
    DateTime? now,
  }) {
    if (BuiltInThemes.byKey(themeKey) == null) {
      throw Errors.invalid('Unknown theme "$themeKey".');
    }
    try {
      final plan = const SlidesPlanner().plan(
        CreateDeck(
          deckId: deckSpace.uuid,
          title: title,
          themeKey: themeKey,
          firstLayoutKey: firstLayoutKey,
        ),
        DeckModel(deckId: deckSpace.uuid),
        SlidesPlanContext(
          userId: authorUuid.uuid,
          now: now ?? nowUtc(),
          ids: ids,
          isOwner: true,
        ),
      );
      return plan.changes;
    } on PlanException catch (e) {
      throw Errors.invalid(e.message);
    }
  }
}
