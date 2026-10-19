/// The mutation planner of Wonky Slides (02 §12.1): turns every
/// `SlidesOperation` into a `SlidesPlan` against a `DeckModel`, on the
/// client (`DeckSession.execute`) and the server (`ServerSlidesWriter`).
///
/// Rules: plans name exactly the touched columns (P7) and write coupled
/// columns together (P4, `SlidesUndoHooks.coupled`); a row appears at most
/// once per plan (`PlanBuilder`); deletes list every dependent row so undo
/// revives them; limits (02 §13) throw `PlanException(limit)` before
/// anything is applied; text bodies are normalized to the Slides text
/// schema (`SlidesText`); deterministic ids (02 §2.1) wherever two devices
/// may create the same row; planning never mutates the model.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:wonky_charts/wonky_charts.dart' show ChartSnapshotColumns;
import 'package:wonky_rich_text/wonky_rich_text.dart' show Delta;
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import '../charts/chart_overrides.dart';
import '../maintenance/deck_maintenance.dart';
import '../model/api/deck_model.dart';
import '../model/api/kinds.dart';
import '../model/api/records.dart';
import '../model/geometry/frame_math.dart';
import '../model/index/deck_indexes.dart';
import '../model/index/placeholder_index.dart';
import '../model/resolve/slide_resolver.dart';
import '../model/text/slides_text.dart';
import '../motion/builds/build_options.dart' show BuildOptions;
import '../motion/builds/transition_spec.dart'
    show DeckMotionDefaults, TransitionSpec;
import '../motion/easing/motion_easing.dart' show MotionEasing;
import '../motion/effects/effect_catalog.dart' show EffectCatalog;
import '../ops/change_summary.dart';
import '../ops/operations.dart';
import '../ops/plan_context.dart';
import '../ops/planner.dart';
import '../schema/slides_schema.dart';
import '../theme/builtins/builtin_themes.dart';
import '../theme/builtins/theme_package.dart';
import '../theme/json/json_util.dart';
import '../theme/layout/layout_remap.dart';
import '../theme/layout/placeholder_type.dart';
import '../theme/layout/slide_size.dart';
import '../theme/model/background.dart';
import '../theme/model/box_text_style.dart';
import '../theme/model/common.dart';
import '../theme/model/deck_theme_data.dart';
import '../theme/schema/validator.dart';
import 'order_keys.dart';
import 'plan_builder.dart';
import 'theme_copy.dart';

part 'parts/common.dart';
part 'parts/deck_part.dart';
part 'parts/slide_part.dart';
part 'parts/group_part.dart';
part 'parts/clone_part.dart';
part 'parts/element_part.dart';
part 'parts/text_part.dart';
part 'parts/table_part.dart';
part 'parts/motion_part.dart';
part 'parts/theme_part.dart';
part 'parts/repair_part.dart';
part 'parts/layer_part.dart';

/// The planner of every `SlidesOperation` (02 §12.1).
final class SlidesPlanner implements SlidesMutationPlanner {
  /// Creates the planner.
  const SlidesPlanner();

  /// Max text bodies recorded in `DeckChangeLog.detailJson` (02 §13).
  static const maxDetailBodies = 20;

  /// Max characters per body recorded in `detailJson`.
  static const maxDetailChars = 2000;

  @override
  SlidesPlan plan(SlidesOperation op, DeckModel deck, SlidesPlanContext ctx) {
    final p = _Planner(deck, ctx);
    final label = p.dispatch(op);
    final changes = p.b.build();
    return SlidesPlan(
      label: label,
      summary: SlidesChangeSummary.of(changes, current: deck),
      changes: changes,
      detail: _detail(changes),
      warnings: List.unmodifiable(p.warnings),
      result: Map.unmodifiable(p.result),
    );
  }

  /// Text before/after for ≤ 20 bodies of ≤ 2,000 characters (02 §3.10);
  /// null otherwise.
  static Map<String, Object?>? _detail(List<RowChange> changes) {
    const textColumns = {SlidesCols.text, SlideCols.notes, CodeStateCols.code};
    final bodies = <Map<String, Object?>>[];
    for (final c in changes) {
      for (final col in textColumns) {
        if (!c.columnsAfter.containsKey(col) &&
            !c.columnsBefore.containsKey(col)) {
          continue;
        }
        final before = c.columnsBefore[col] as String?;
        final after = c.columnsAfter[col] as String?;
        if (before == after) continue;
        if ((before?.length ?? 0) > maxDetailChars ||
            (after?.length ?? 0) > maxDetailChars) {
          return null;
        }
        bodies.add({
          'table': c.table,
          'id': c.rowId,
          'column': col,
          'before': before,
          'after': after,
        });
        if (bodies.length > maxDetailBodies) return null;
      }
    }
    return bodies.isEmpty ? null : {'v': 1, 'texts': bodies};
  }
}
