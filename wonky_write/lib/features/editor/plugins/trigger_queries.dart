import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';

import '../applier/delta_applier.dart';
import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import '../mapping/wonky_schema.dart';

/// A trigger being typed: `/query` (slash menu), `@query` (mention picker)
/// or `:query` (emoji suggestions).
@immutable
class TriggerQuery {
  const TriggerQuery({
    required this.trigger,
    required this.query,
    required this.start,
    required this.end,
  });

  /// `/`, `@` or `:`.
  final String trigger;

  /// Text after the trigger.
  final String query;

  /// Delta range `[start, end)` of trigger + query.
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is TriggerQuery &&
      other.trigger == trigger &&
      other.query == query &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(trigger, query, start, end);

  @override
  String toString() => 'TriggerQuery($trigger$query @$start)';
}

/// Detects slash commands and mentions being typed (Write 04 §19.1, §21.1):
/// the trigger must follow the block start, whitespace or an opening bracket,
/// never in code or inline code, and is dismissed with Esc until the caret
/// leaves it.
class TriggerQueryTracker {
  TriggerQueryTracker(this.controller) {
    controller.addListener(_update);
  }

  final WriteEditorController controller;

  /// The slash query at the caret, or `null`.
  final ValueNotifier<TriggerQuery?> slash = ValueNotifier(null);

  /// The mention query at the caret, or `null`.
  final ValueNotifier<TriggerQuery?> mention = ValueNotifier(null);

  /// The emoji query (`:smi`, at least 2 characters) at the caret, or `null`
  /// (Write 04 §20.1).
  final ValueNotifier<TriggerQuery?> emoji = ValueNotifier(null);

  /// Whether the `:` emoji trigger is active.
  bool emojiEnabled = true;

  int? _dismissedStart;

  static final _slash = RegExp(r'(?:^|[\s(\[{])(/[\w\-.#]{0,32})$');
  static final _mention = RegExp(
    r'(?:^|[\s(\[{])(@[^\s@()\[\]{}<>,;:!?"]{0,40})$',
  );
  static final _emoji = RegExp(
    r'(?:^|[\s(\[{])(:[\p{L}\p{N}_+\-]{2,30})$',
    unicode: true,
  );

  /// Hides the open picker until the caret leaves the query (Esc).
  void dismiss() {
    _dismissedStart =
        slash.value?.start ?? mention.value?.start ?? emoji.value?.start;
    slash.value = null;
    mention.value = null;
    emoji.value = null;
  }

  void _update() {
    final next = _compute();
    final slashQuery = next?.trigger == '/' ? next : null;
    final mentionQuery = next?.trigger == '@' ? next : null;
    final emojiQuery = next?.trigger == ':' ? next : null;
    if (next == null || next.start != _dismissedStart) {
      if (next?.start != _dismissedStart) _dismissedStart = null;
      slash.value = _dismissedStart == null ? slashQuery : null;
      mention.value = _dismissedStart == null ? mentionQuery : null;
      emoji.value = _dismissedStart == null ? emojiQuery : null;
    } else {
      slash.value = null;
      mention.value = null;
      emoji.value = null;
    }
  }

  TriggerQuery? _compute() {
    if (controller.mode == EditorMode.viewing) return null;
    final selection = controller.composer.selection;
    if (selection == null || !selection.isCollapsed) return null;
    final node = controller.document.getNodeById(selection.extent.nodeId);
    final position = selection.extent.nodePosition;
    if (node is! TextNode ||
        position is! TextNodePosition ||
        isCodeBlockNode(node)) {
      return null;
    }
    final offset = position.offset;
    final text = node.text.toPlainText();
    final before = text.substring(0, offset);
    // The selection can name a node the mirror has not seen yet (a node
    // inserted in the same transaction); the next update catches up.
    final index = controller.mirror.indexOfNode(node.id);
    if (index < 0) return null;
    final nodeStart = controller.mirror.startOfIndex(index);
    for (final (trigger, pattern) in [
      ('/', _slash),
      ('@', _mention),
      if (emojiEnabled) (':', _emoji),
    ]) {
      final match = pattern.firstMatch(before);
      if (match == null) continue;
      final raw = match.group(1)!;
      final start = offset - raw.length;
      if (start < text.length &&
          node.text.getAllAttributionsAt(start).contains(codeAttribution)) {
        continue;
      }
      if (start > 0 &&
          node.text
              .getAllAttributionsAt(start - 1)
              .any((a) => a is LinkAttribution)) {
        continue;
      }
      return TriggerQuery(
        trigger: trigger,
        query: raw.substring(1),
        start: nodeStart + start,
        end: nodeStart + offset,
      );
    }
    return null;
  }

  /// Removes the trigger text (`/query`) as part of the running change.
  void removeTriggerText(TriggerQuery query) {
    controller.applyLocal(
      Delta()
        ..retain(query.start)
        ..delete(query.end - query.start),
      label: controller.strings().undoSlashCommand,
      selectionAfter: DeltaSelection.collapsed(query.start),
    );
  }

  void dispose() {
    controller.removeListener(_update);
    slash.dispose();
    mention.dispose();
    emoji.dispose();
  }
}
