import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../applier/delta_applier.dart';
import '../commands/write_editor_commands.dart';
import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import '../layers/document_geometry.dart';
import 'drop_indicator.dart';

/// Drag and drop of the selection inside the editor (Write 04 §24): press on
/// the selected content and drag; a drop caret follows the pointer; the drop
/// **moves** the content (delete + insert, one undo step "Move text"), or
/// **copies** it when Alt/⌥ is held at the drop. Esc cancels.
///
/// Plugged into `SuperEditor.contentDragDelegate` (patch SE-6), so the
/// editor doesn't start a new drag selection meanwhile.
class TextDragController implements ContentDragDelegate {
  TextDragController({
    required this.controller,
    required this.commands,
    required this.indicator,
    this.newEmbedId,
  });

  final WriteEditorController controller;
  final WriteEditorCommands commands;
  final DropIndicator indicator;

  /// Ids for embeds of a copied fragment (defaults to the controller's).
  final String Function()? newEmbedId;

  DeltaSelection? _source;
  int? _target;

  /// Whether a text drag is in progress.
  bool get isDragging => _source != null;

  @override
  bool onDragStart(ContentDragDetails details) {
    if (controller.mode == EditorMode.viewing || !commands.canEdit) {
      return false;
    }
    final selection = controller.selection;
    if (selection == null || selection.isCollapsed) return false;
    if (!_insideSelection(details, selection)) return false;
    _source = selection;
    _target = null;
    HardwareKeyboard.instance.addHandler(_onKey);
    return true;
  }

  bool _insideSelection(ContentDragDetails details, DeltaSelection selection) {
    final rects = DocumentGeometry.rectsForRange(
      details.documentLayout,
      controller.mirror,
      selection.start,
      selection.end,
    );
    return rects.any((r) => r.inflate(1).contains(details.layoutOffset));
  }

  @override
  void onDragUpdate(ContentDragDetails details) {
    final source = _source;
    if (source == null) return;
    final position = details.position;
    final offset = position == null
        ? null
        : controller.mirror.offsetOf(position);
    _target = offset;
    indicator.value = offset == null || _isInside(offset, source)
        ? null
        : CaretDropSpot(offset);
  }

  bool _isInside(int offset, DeltaSelection source) =>
      offset >= source.start && offset <= source.end;

  @override
  void onDragEnd(ContentDragDetails details) {
    onDragUpdate(details);
    final source = _source;
    final target = _target;
    _finish();
    if (source == null || target == null || _isInside(target, source)) {
      return;
    }
    drop(source, target, copy: HardwareKeyboard.instance.isAltPressed);
  }

  @override
  void onDragCancel() => _finish();

  /// Cancels the drag (Esc).
  void cancel() => _finish();

  void _finish() {
    if (_source != null) HardwareKeyboard.instance.removeHandler(_onKey);
    _source = null;
    _target = null;
    indicator.clear();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _source != null) {
      _finish();
      return true;
    }
    return false;
  }

  /// Moves (or copies) Delta `[source.start, source.end)` to [target]
  /// (an offset in the current document) as one undo step, and selects the
  /// dropped content. Returns whether the document changed.
  bool drop(DeltaSelection source, int target, {bool copy = false}) {
    if (!commands.canEdit || _isInside(target, source)) return false;
    final mirror = controller.mirror;
    var fragment = mirror.slice(source.start, source.end);
    if (fragment.isEmpty) return false;
    if (copy) fragment = _withNewEmbedIds(fragment);
    final length = source.end - source.start;
    final l = controller.strings();
    final label = copy ? l.undoCopyText : l.undoMoveText;
    LocalDeltaChange? inserted;
    var at = target;
    controller.group(label, () {
      if (!copy) {
        controller.applyLocal(
          Delta()
            ..retain(source.start)
            ..delete(length),
          label: label,
        );
        if (target > source.end) at = target - length;
      }
      inserted = commands.insertFragment(
        fragment,
        label: label,
        start: at,
        end: at,
      );
    });
    final change = inserted;
    if (change == null) return false;
    var insertedLength = 0;
    for (final op in change.delta.operations) {
      if (op.isInsert) insertedLength += op.length!;
    }
    if (insertedLength > 0) {
      final end = (at + insertedLength).clamp(0, controller.length - 1);
      controller.select(DeltaSelection(at, end));
    }
    return true;
  }

  Delta _withNewEmbedIds(Delta fragment) {
    final ids = newEmbedId ?? controller.newEmbedId;
    return Delta.fromOperations([
      for (final op in fragment.operations)
        if (op.data is Map)
          Operation.insert(_renew(op.data as Map, ids), op.attributes)
        else
          op,
    ]);
  }

  static Map<String, dynamic> _renew(
    Map<Object?, Object?> value,
    String Function() ids,
  ) {
    final type = value.keys.first as String;
    final inner = value[type];
    if (inner is! Map) return value.cast<String, dynamic>();
    return {
      type: {...inner.cast<String, dynamic>(), 'id': ids()},
    };
  }

  @visibleForTesting
  int? get target => _target;
}
