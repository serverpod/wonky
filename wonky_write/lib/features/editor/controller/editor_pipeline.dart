import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:super_editor/super_editor.dart';

import '../applier/delta_applier.dart';
import '../extractor/change_delta_extractor.dart';
import '../mapping/delta_document_mapper.dart';
import '../mapping/document_mirror.dart';

/// The super_editor objects of one open document plus the Delta plumbing that
/// keeps them in sync with the Wonky Delta (Write 04 §2.1):
/// [MutableDocument], [MutableDocumentComposer], [Editor] (history disabled),
/// [DocumentMirror] (+ `DeltaIndex`), [ChangeDeltaExtractor] and
/// [DeltaApplier].
class EditorPipeline {
  EditorPipeline({
    required Delta initialDelta,
    List<EditRequestHandler> requestHandlers = const [],
    List<EditReaction> Function(EditorPipeline pipeline)? reactions,
    this.mapper = const DeltaDocumentMapper(),
    String Function()? newNodeId,
    bool? verifyInvariants,
    required void Function(
      List<ExtractedChange> changes,
      List<EditEvent> events,
    )
    onTransaction,
  }) : _newNodeId = newNodeId ?? Editor.createNodeId {
    verifyInvariants ??= debugVerifyInvariants;
    document = mapper.documentFromDelta(initialDelta, newNodeId: _newNodeId);
    composer = MutableDocumentComposer();
    mirror = DocumentMirror(serializer: mapper.serializer)..rebuild(document);
    extractor = ChangeDeltaExtractor(
      mirror: mirror,
      document: document,
      composer: composer,
      verifyInvariants: verifyInvariants,
    );
    editor = Editor(
      editables: {Editor.documentKey: document, Editor.composerKey: composer},
      requestHandlers: [
        ...requestHandlers,
        // super_editor builds the list with an untyped List.unmodifiable.
        ...defaultRequestHandlers.cast<EditRequestHandler>(),
      ],
      reactionPipeline: [],
      // REQUIRED (Write 03 §4): undo is ours, never super_editor's.
      isHistoryEnabled: false,
    );
    editor.reactionPipeline.addAll(reactions?.call(this) ?? const []);
    applier = DeltaApplier(
      editor: editor,
      mirror: mirror,
      parser: mapper.parser,
      newNodeId: _newNodeId,
      verifyInvariants: verifyInvariants,
    );
    editor.addListener(
      FunctionalEditListener((events) {
        onTransaction(extractor.finishTransaction(events), events);
      }),
    );
  }

  /// Overrides the default of `verifyInvariants` (debug builds: on) for
  /// pipelines created without it — the perf suite turns the full-document
  /// checks off so it measures the editor, not the checks.
  @visibleForTesting
  static bool? debugVerifyInvariants;

  final DeltaDocumentMapper mapper;
  final String Function() _newNodeId;

  late final MutableDocument document;
  late final MutableDocumentComposer composer;
  late final Editor editor;
  late final DocumentMirror mirror;
  late final ChangeDeltaExtractor extractor;
  late final DeltaApplier applier;

  /// Creates a node id (shared by the parser and commands).
  String newNodeId() => _newNodeId();

  /// The full document Delta (O(n)).
  Delta get delta => mirror.toDelta();

  /// Replaces the whole document (resync / re-init from a snapshot) without
  /// producing a local change.
  void resetDocument(Delta delta, {DeltaSelection? selection}) {
    final current = mirror.toDelta();
    final change = current.diff(delta, cleanupSemantic: false);
    applier.apply(change, selectionAfter: selection);
  }

  void dispose() {
    editor.dispose();
    composer.dispose();
    document.dispose();
  }
}
