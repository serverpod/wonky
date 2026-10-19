import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show DeltaSelection;

import '../mapping/delta_node_codec.dart';
import '../mapping/document_mirror.dart';

export 'package:wonky_write_core/wonky_write_core.dart' show DeltaSelection;

/// The origin of a change applied by the [DeltaApplier].
enum AppliedChangeOrigin {
  /// A collaborator's change (or a server-side change) — never a local edit.
  remote,

  /// A change made by this client through a Delta (undo/redo, commands, AI):
  /// the caller reports it as a local change itself.
  local,
}

/// Thrown when a change Delta doesn't fit the current document.
class DeltaApplyError extends Error {
  DeltaApplyError(this.message);

  final String message;

  @override
  String toString() => 'DeltaApplyError: $message';
}

/// Applies change Deltas (from collaborators, undo, AI, MCP) to the live
/// document **without** going through the composer (Write 03 §3, patch SE-2).
///
/// Only the lines the change touches are re-parsed; unchanged nodes keep
/// their instances (no relayout), touched nodes keep their ids where the
/// change maps them, the local selection is transformed through the change,
/// and an IME composing region that the change intersects is cleared.
class DeltaApplier {
  DeltaApplier({
    required this.editor,
    required this.mirror,
    this.parser = const WonkyDeltaParser(),
    String Function()? newNodeId,
    bool? verifyInvariants,
  }) : _newNodeId = newNodeId ?? Editor.createNodeId,
       verifyInvariants = verifyInvariants ?? kDebugMode;

  /// Tag of patches made by this applier (see [ApplyDocumentPatchRequest.tag]).
  static const patchTag = 'wonky.deltaApplier';

  final Editor editor;
  final DocumentMirror mirror;
  final WonkyDeltaParser parser;
  final String Function() _newNodeId;

  /// Whether the mirror is checked against the document after each apply.
  final bool verifyInvariants;

  MutableDocument get _document => editor.document;
  MutableDocumentComposer get _composer => editor.composer;

  /// Applies [change]. Returns the local selection before and after (as Delta
  /// offsets), or `null` values when there is no selection.
  ///
  /// When [selectionAfter] is given (e.g. undo restoring `selectionBefore`), it
  /// replaces the transformed selection.
  ({DeltaSelection? before, DeltaSelection? after}) apply(
    Delta change, {
    AppliedChangeOrigin origin = AppliedChangeOrigin.remote,
    DeltaSelection? selectionAfter,
  }) {
    final docLength = mirror.length;
    var baseLength = 0;
    for (final op in change.operations) {
      if (!op.isInsert) baseLength += op.length!;
    }
    if (baseLength > docLength) {
      throw DeltaApplyError(
        'Change base length $baseLength exceeds the document length $docLength',
      );
    }

    final selection = _composer.selection;
    final selectionBefore = selection == null
        ? null
        : _toDeltaSelection(selection);
    final composing = _composer.composingRegion.value;
    final composingBefore = composing == null ? null : _toDeltaRange(composing);

    final ranges = _affectedRanges(change, docLength);
    if (ranges.isEmpty) {
      final after = selectionAfter ?? selectionBefore;
      if (selectionAfter != null && selectionAfter != selectionBefore) {
        _setSelectionOnly(selectionAfter);
      }
      return (before: selectionBefore, after: after);
    }

    final operations = <DocumentPatchOperation>[];
    final mirrorUpdates = <(int, int, List<MirrorEntry>)>[];
    var touchesCaretNode = false;
    final caretNodeIds = {
      if (selection != null) selection.base.nodeId,
      if (selection != null) selection.extent.nodeId,
    };

    for (final (first, last) in ranges.reversed) {
      final sliceStart = mirror.startOfIndex(first);
      final sliceEnd = mirror.startOfIndex(last + 1);
      final isDocumentEnd = last == mirror.nodeCount - 1;
      final subChange = _restrict(
        change,
        sliceStart,
        sliceEnd,
        includeInsertsAtEnd: isDocumentEnd,
      );
      final oldSlice = mirror.entriesDelta(first, last + 1);
      final newSlice = oldSlice.compose(subChange);

      final oldEntries = [
        for (var i = first; i <= last; i += 1) mirror.entryAt(i),
      ];
      final regionIds = {for (final e in oldEntries) e.nodeId};
      if (regionIds.any(caretNodeIds.contains)) {
        touchesCaretNode = true;
      }

      final claimed = <String>{};
      bool claim(String id) {
        if (!claimed.add(id)) return false;
        final index = mirror.indexOfNode(id);
        return index < 0 || regionIds.contains(id);
      }

      var newNodes = parser.parse(
        newSlice,
        newNodeId: _newNodeId,
        claimId: claim,
      );
      newNodes = _assignIds(oldEntries, newNodes, subChange, claimed);

      final newEntries = <MirrorEntry>[];
      final oldById = {for (final e in oldEntries) e.nodeId: e};
      for (var k = 0; k < newNodes.length; k += 1) {
        final node = newNodes[k];
        final entry = mirror.serializeEntry(node);
        final old = oldById[node.id];
        if (old != null &&
            old.node.runtimeType == node.runtimeType &&
            nodeDeltasEqual(old.delta, entry.delta)) {
          newEntries.add(old);
        } else {
          newEntries.add(entry);
        }
      }

      // Patch operations for this region. Regions are processed from the end
      // of the document, so earlier indices stay valid. Nodes kept in both
      // lists are replaced in place, which requires them to keep their
      // relative order; if they don't (an embed moved within the region),
      // every node of the region is deleted and re-inserted.
      final newIds = {for (final e in newEntries) e.nodeId};
      final keptOld = [
        for (final e in oldEntries)
          if (newIds.contains(e.nodeId)) e.nodeId,
      ];
      final keptNew = [
        for (final e in newEntries)
          if (oldById.containsKey(e.nodeId)) e.nodeId,
      ];
      final keepInPlace = listEquals(keptOld, keptNew);
      for (final old in oldEntries) {
        if (!keepInPlace || !newIds.contains(old.nodeId)) {
          operations.add(DeleteNodePatch(old.nodeId));
        }
      }
      for (var k = 0; k < newEntries.length; k += 1) {
        final entry = newEntries[k];
        final old = oldById[entry.nodeId];
        if (old == null || !keepInPlace) {
          operations.add(InsertNodePatch(first + k, entry.node));
        } else if (!identical(old.node, entry.node)) {
          operations.add(ReplaceNodePatch(entry.nodeId, entry.node));
        }
      }
      mirrorUpdates.add((first, last + 1, newEntries));
    }

    // Selection and composing region after the change. They need the updated
    // mirror for offset → position conversion, so update the mirror first.
    for (final (from, to, entries) in mirrorUpdates) {
      mirror.replaceRange(from, to, entries);
    }

    final transformedSelection =
        selectionAfter ?? selectionBefore?.transform(change);
    DocumentSelection? newSelection;
    if (transformedSelection != null) {
      newSelection = mirror.selectionAt(
        transformedSelection.anchor.clamp(0, mirror.length - 1),
        transformedSelection.head.clamp(0, mirror.length - 1),
      );
    }

    var clearComposing = false;
    DocumentRange? newComposing;
    if (composingBefore != null) {
      if (_intersects(change, composingBefore.$1, composingBefore.$2)) {
        clearComposing = true;
      } else {
        final start = change.transformPosition(
          composingBefore.$1,
          force: false,
        );
        final end = change.transformPosition(composingBefore.$2, force: false);
        final startPosition = mirror.positionAt(start);
        final endPosition = mirror.positionAt(end);
        if (startPosition != null && endPosition != null) {
          newComposing = DocumentRange(start: startPosition, end: endPosition);
        }
      }
    }

    // The patch must be applied in the same order as computed: per region
    // (last region first). Operations within a region: deletes, then
    // replacements and inserts in ascending order.
    if (operations.isNotEmpty ||
        newSelection != selection ||
        composingBefore != null) {
      editor.execute([
        ApplyDocumentPatchRequest(
          operations: operations,
          updateSelection: selection != null || selectionAfter != null,
          selectionAfter: newSelection,
          updateComposingRegion: composingBefore != null,
          composingRegionAfter: clearComposing ? null : newComposing,
          resyncIme: touchesCaretNode || clearComposing,
          tag: origin == AppliedChangeOrigin.remote
              ? patchTag
              : '$patchTag.local',
        ),
      ]);
    }

    if (verifyInvariants) {
      _verify();
    }

    return (before: selectionBefore, after: transformedSelection);
  }

  void _setSelectionOnly(DeltaSelection selection) {
    final documentSelection = mirror.selectionAt(
      selection.anchor.clamp(0, mirror.length - 1),
      selection.head.clamp(0, mirror.length - 1),
    );
    editor.execute([
      ChangeSelectionRequest(
        documentSelection,
        SelectionChangeType.alteredContent,
        SelectionReason.contentChange,
      ),
    ]);
  }

  void _verify() {
    final nodes = _document.toList();
    if (nodes.length != mirror.nodeCount) {
      throw DeltaApplyError(
        'Mirror has ${mirror.nodeCount} nodes, document has ${nodes.length}',
      );
    }
    for (var i = 0; i < nodes.length; i += 1) {
      if (!identical(nodes[i], mirror.entryAt(i).node)) {
        throw DeltaApplyError(
          'Mirror entry $i (${mirror.entryAt(i).nodeId}) differs from node ${nodes[i].id}',
        );
      }
    }
  }

  DeltaSelection? _toDeltaSelection(DocumentSelection selection) {
    final offsets = mirror.offsetsOf(selection);
    return offsets == null ? null : DeltaSelection(offsets.$1, offsets.$2);
  }

  (int, int)? _toDeltaRange(DocumentRange range) {
    final start = mirror.offsetOf(range.start);
    final end = mirror.offsetOf(range.end);
    if (start == null || end == null) return null;
    return start <= end ? (start, end) : (end, start);
  }

  /// Whether [change] modifies anything within `[start, end]`.
  static bool _intersects(Delta change, int start, int end) {
    var offset = 0;
    for (final op in change.operations) {
      final length = op.length!;
      if (op.isInsert) {
        if (offset >= start && offset <= end) return true;
        continue;
      }
      if (op.isRetain && op.isPlain) {
        offset += length;
        if (offset > end) return false;
        continue;
      }
      if (offset <= end && offset + length >= start) return true;
      offset += length;
    }
    return false;
  }

  /// Node index ranges `(first, last)` (inclusive, merged, ascending) affected
  /// by [change], extended by one node on each side so that lines can merge
  /// with their neighbors (e.g. adjacent code blocks).
  List<(int, int)> _affectedRanges(Delta change, int docLength) {
    final count = mirror.nodeCount;
    final raw = <(int, int)>[];
    var offset = 0;
    for (final op in change.operations) {
      final length = op.length!;
      if (op.isRetain && op.isPlain) {
        offset += length;
        continue;
      }
      int first;
      int last;
      if (op.isInsert) {
        first = mirror.indexAtOffset(offset);
        last = first;
      } else {
        first = mirror.indexAtOffset(offset);
        final endOffset = op.isDelete ? offset + length : offset + length - 1;
        last = mirror.indexAtOffset(
          endOffset >= docLength ? docLength - 1 : endOffset,
        );
        offset += length;
      }
      raw.add((
        first > 0 ? first - 1 : 0,
        last + 1 < count ? last + 1 : count - 1,
      ));
    }
    if (raw.isEmpty) {
      return const [];
    }
    raw.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[raw.first];
    for (final range in raw.skip(1)) {
      final previous = merged.last;
      if (range.$1 <= previous.$2 + 1) {
        merged[merged.length - 1] = (
          previous.$1,
          range.$2 > previous.$2 ? range.$2 : previous.$2,
        );
      } else {
        merged.add(range);
      }
    }
    return merged;
  }

  /// The part of [change] that applies to the old document range
  /// `[from, to)`, expressed relative to `from`.
  static Delta _restrict(
    Delta change,
    int from,
    int to, {
    required bool includeInsertsAtEnd,
  }) {
    final result = Delta();
    var offset = 0;
    for (final op in change.operations) {
      if (op.isInsert) {
        if (offset >= from &&
            (offset < to || (offset == to && includeInsertsAtEnd))) {
          result.push(op);
        }
        continue;
      }
      final length = op.length!;
      final opStart = offset;
      final opEnd = offset + length;
      offset = opEnd;
      final start = opStart > from ? opStart : from;
      final end = opEnd < to ? opEnd : to;
      if (start >= end) {
        continue;
      }
      if (op.isDelete) {
        result.delete(end - start);
      } else {
        result.retain(end - start, op.attributes);
      }
    }
    result.trim();
    return result;
  }

  /// Gives new nodes the ids of the old nodes they continue: an old node's id
  /// goes to the new node that contains the old node's (transformed) start.
  List<DocumentNode> _assignIds(
    List<MirrorEntry> oldEntries,
    List<DocumentNode> newNodes,
    Delta subChange,
    Set<String> claimed,
  ) {
    if (newNodes.isEmpty) {
      return newNodes;
    }
    final starts = <int>[];
    var offset = 0;
    for (final node in newNodes) {
      starts.add(offset);
      offset += mirror.serializer
          .serializeNode(node)
          .operations
          .fold<int>(0, (sum, op) => sum + op.length!);
    }

    final assigned = List<String?>.filled(newNodes.length, null);
    var oldStart = 0;
    for (final old in oldEntries) {
      final position = subChange.transformPosition(oldStart);
      oldStart += old.length;
      if (old.node is! TextNode) {
        continue;
      }
      // The new node that contains `position`.
      var index = 0;
      while (index + 1 < starts.length && starts[index + 1] <= position) {
        index += 1;
      }
      if (assigned[index] == null && newNodes[index] is TextNode) {
        assigned[index] = old.nodeId;
      }
    }

    return [
      for (var k = 0; k < newNodes.length; k += 1)
        if (assigned[k] != null && assigned[k] != newNodes[k].id)
          (newNodes[k] as TextNode).copyTextNodeWith(id: assigned[k])
        else
          newNodes[k],
    ];
  }
}
