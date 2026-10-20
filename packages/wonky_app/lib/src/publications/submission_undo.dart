import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../shell/shell_services.dart';

/// Undo of disconnecting a document from its publication (specs/18 §4.4):
/// undo reconnects, redo disconnects again. Submitting and withdrawing
/// reach the blog and are not undoable.
class SubmissionUndoEntry extends UndoEntry {
  const SubmissionUndoEntry({required this.itemUuid});

  final String itemUuid;

  static const domainName = 'publications';

  @override
  String get domain => domainName;

  @override
  UndoEntry? rebase(RemoteChange change) => this;
}

/// Applies [SubmissionUndoEntry]s through the publication repository.
class SubmissionUndoHandler extends UndoHandler<SubmissionUndoEntry> {
  SubmissionUndoHandler(this.services);

  final ShellServices services;

  @override
  String get domain => SubmissionUndoEntry.domainName;

  @override
  Future<SubmissionUndoEntry> undo(SubmissionUndoEntry e) async {
    await services.repositories.publications.reconnect(
      UuidValue.fromString(e.itemUuid),
    );
    return e;
  }

  @override
  Future<SubmissionUndoEntry> redo(SubmissionUndoEntry e) async {
    await services.repositories.publications.disconnect(
      UuidValue.fromString(e.itemUuid),
    );
    return e;
  }
}
