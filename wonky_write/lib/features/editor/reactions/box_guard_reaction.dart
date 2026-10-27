import 'package:super_editor/super_editor.dart';

import '../mapping/document_mirror.dart';
import '../mapping/wonky_schema.dart';

/// Keeps Wonky Markdown containers on nodes that super_editor commands
/// create or replace without copying their metadata (Write 11 §7.4).
///
/// A node of the transaction without [WonkyNodeMetadata.box] gets:
/// - the containers it had before the transaction (a replaced node);
/// - otherwise, for a new node, the containers of the node before it (the
///   node it was split from: Enter keeps the caret's container), or of the
///   node after it when it is first.
///
/// The containers before the transaction come from the [DocumentMirror],
/// which holds the last synced nodes until the change extractor's first
/// checkpoint of the transaction: [snapshot] reads them first in the
/// pipeline and [restore] applies them last, in both reaction phases.
///
/// Wonky commands that place a node in or out of a container on purpose set
/// [WonkyNodeMetadata.box] themselves (an empty list for "none"), so the
/// guard leaves them alone. [restore] runs before the schema guard.
class WonkyBoxGuard {
  WonkyBoxGuard(this.mirror);

  /// The last synced document.
  final DocumentMirror mirror;

  /// The box of each node of the transaction before it ([_newNode] for a
  /// node the transaction created).
  final _before = <String, Object?>{};

  static const _newNode = Object();

  /// Records the containers of the transaction's nodes; first reaction.
  late final EditReaction snapshot = FunctionalEditReaction(
    modifyContent: (context, dispatcher, changeList) {
      _before.clear();
      _record(changeList);
    },
    react: (context, dispatcher, changeList) => _record(changeList),
  );

  /// Puts the containers back on nodes that lost them; last before the
  /// schema guard.
  late final EditReaction restore = FunctionalEditReaction(
    modifyContent: _restore,
    react: _restore,
  );

  void _record(List<EditEvent> changeList) {
    for (final id in _nodeIds(changeList)) {
      if (_before.containsKey(id)) continue;
      final entry = mirror.entryOf(id);
      _before[id] = entry == null ? _newNode : boxValueOf(entry.node);
    }
  }

  void _restore(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final document = editorContext.document;
    final requests = <EditRequest>[];
    for (final id in _nodeIds(changeList)) {
      final node = document.getNodeById(id);
      if (node == null || node.metadata.containsKey(WonkyNodeMetadata.box)) {
        continue;
      }
      final box = _boxFor(document, node);
      if (box == null) continue;
      requests.add(
        ReplaceNodeRequest(
          existingNodeId: node.id,
          newNode: node.copyWithAddedMetadata({WonkyNodeMetadata.box: box}),
        ),
      );
    }
    if (requests.isNotEmpty) requestDispatcher.execute(requests);
  }

  /// The box of a node that has none, or `null` to leave it without.
  List<dynamic>? _boxFor(Document document, DocumentNode node) {
    final before = _before.containsKey(node.id)
        ? _before[node.id]
        : (mirror.entryOf(node.id) == null
              ? _newNode
              : boxValueOf(mirror.entryOf(node.id)!.node));
    if (!identical(before, _newNode)) return before as List<dynamic>?;
    final index = document.getNodeIndexById(node.id);
    final source =
        document.getNodeAt(index - 1) ?? document.getNodeAt(index + 1);
    return source == null ? null : boxValueOf(source);
  }

  static Iterable<String> _nodeIds(List<EditEvent> changeList) sync* {
    final seen = <String>{};
    for (final event in changeList) {
      if (event is! DocumentEdit) continue;
      final change = event.change;
      if (change is! NodeDocumentChange || change is NodeRemovedEvent) {
        continue;
      }
      if (seen.add(change.nodeId)) yield change.nodeId;
    }
  }
}
