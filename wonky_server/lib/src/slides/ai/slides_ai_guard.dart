import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/ops.dart' show SlidesPlan;
import 'package:wonky_slides_core/schema.dart' show SlidesTables;
import 'package:wonky_revlog/rows.dart' show RowOp;

import '../../platform/mcp/tool_support.dart';

/// The assistant's confirmations (Slides 11 §8.1): with
/// `ToolContext.guardDestructive` on (assistant runs; MCP tokens are never
/// prompted), these writes fail with `needs_confirmation` before anything
/// is written; the loop asks the user and retries with the guard off.
abstract final class SlidesAiGuard {
  /// `slides.delete_slides` asks from this many slides …
  static const deleteSlides = 3;

  /// … or this share of the deck.
  static const deleteFraction = 0.25;

  /// `slides.replace_text` asks above this many replacements.
  static const replacements = 50;

  /// The reason [tool]'s [plan] needs the user's confirmation, or null.
  /// [before] is the deck before the call; [warnings] the call's warning
  /// codes (`broader_audience`).
  static String? reason(
    String tool,
    SlidesPlan plan, {
    required DeckModel before,
    Iterable<String> warnings = const [],
  }) {
    int count(String table, RowOp op) =>
        plan.changes.where((c) => c.table == table && c.op == op).length;
    final total = before.slides.length;
    final deleted = count(SlidesTables.slide, RowOp.delete);
    switch (tool) {
      case 'slides.delete_slides':
        if (deleted >= deleteSlides ||
            (deleted > 0 && deleted > total * deleteFraction)) {
          return 'The assistant wants to delete $deleted of $total slides';
        }
      case 'slides.delete_group':
        if (deleted > 0) {
          return 'The assistant wants to delete a group with its $deleted '
              'slide${deleted == 1 ? '' : 's'}';
        }
      case 'slides.set_code_states':
        final builds = count(SlidesTables.slideBuild, RowOp.delete);
        if (builds > 0) {
          return 'The assistant wants to replace code states that have '
              '$builds build${builds == 1 ? '' : 's'}';
        }
      case 'slides.insert_linked_chart':
        if (warnings.contains('broader_audience')) {
          return 'The presentation is shared more widely than the '
              'spreadsheet: people who can open it will see the chart data';
        }
    }
    return null;
  }

  /// The reason of a `slides.apply_theme` call on all slides ([allSlides]:
  /// no `slides` argument) of a deck with [total] slides.
  static String? themeReason({required bool allSlides, required int total}) =>
      allSlides && total > 0
      ? 'The assistant wants to apply a theme to all $total slides'
      : null;

  /// The reason of a `slides.replace_text` call with [n] replacements.
  static String? replaceReason(int n) => n > replacements
      ? 'The assistant wants to replace text in $n places'
      : null;

  /// The tool error that pauses the run for the user (suite 10 §1).
  static McpToolException needsConfirmation(String summary) => McpToolException(
    'needs_confirmation',
    '$summary. The user must confirm it.',
    details: {'summary': summary},
  );
}
