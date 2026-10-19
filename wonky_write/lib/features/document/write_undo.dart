import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaSelection, DeltaUtils, WonkyOt, canonicalJsonEncode;

/// One `write.content` undo entry (Write 03 §4, suite 08 §3.3): the delta
/// that performs this entry (for an undo entry: the inverse of the local
/// change) and the selections to restore.
class WriteContentUndoEntry extends UndoEntry {
  const WriteContentUndoEntry({
    required this.change,
    this.select,
    this.counterSelect,
  });

  static const domainName = 'write.content';

  /// Applied (as a new local op) when this entry runs.
  final Delta change;

  /// Selection after running this entry (undo: the selection before the
  /// original change). Offsets in the document after [change].
  final DeltaSelection? select;

  /// Selection after running the counter entry (undo: the selection after
  /// the original change). Offsets in the document before [change].
  final DeltaSelection? counterSelect;

  @override
  String get domain => domainName;

  @override
  UndoEntry? rebase(RemoteChange change) {
    if (change is! WriteContentRemoteChange) return this;
    return change.results.containsKey(this) ? change.results[this] : this;
  }

  /// Typing coalescing: [next] happened after this entry's change, so its
  /// inverse runs first.
  @override
  UndoEntry? coalesce(UndoEntry next) {
    if (next is! WriteContentUndoEntry) return null;
    return WriteContentUndoEntry(
      change: WonkyOt.compose(next.change, change),
      select: select,
      counterSelect: next.counterSelect,
    );
  }

  /// Rebases this entry over [remote], a change applied to the document
  /// this entry runs on. Returns the rebased entry (null when it became a
  /// no-op) and [remote] expressed past this entry (for the next older
  /// entry).
  (WriteContentUndoEntry?, Delta) rebaseOver(Delta remote) {
    final u = change;
    final Delta uPrime;
    final Delta rPrime;
    // Disjoint changes (the common case: a collaborator edits elsewhere)
    // only move each other: no transforms, and an entry that doesn't move
    // stays the same object, so the stack isn't rebuilt (CQ-49, W-11).
    final ur = _Touched.of(u);
    final rr = _Touched.of(remote);
    if (ur != null && rr != null && rr.lo > ur.hi) {
      uPrime = u;
      rPrime = rr.shifted(remote, ur.net);
    } else if (ur != null && rr != null && rr.hi < ur.lo) {
      uPrime = ur.shifted(u, rr.net);
      rPrime = remote;
    } else {
      uPrime = WonkyOt.transform(remote, u, aWinsTies: true);
      rPrime = WonkyOt.transform(u, remote, aWinsTies: false);
      if (DeltaUtils.isNoop(uPrime)) return (null, rPrime);
    }
    final s = select?.transform(rPrime);
    final c = counterSelect?.transform(remote);
    if (identical(uPrime, u) && s == select && c == counterSelect) {
      return (this, rPrime);
    }
    return (
      WriteContentUndoEntry(change: uPrime, select: s, counterSelect: c),
      rPrime,
    );
  }

  /// JSON for the offline undo stack (suite 12 §1.1 `LocalUndoStack`).
  @override
  Map<String, Object?> toJson() => {
    'change': change.toJson(),
    if (select != null) 'select': select!.toJson(),
    if (counterSelect != null) 'counterSelect': counterSelect!.toJson(),
  };

  static WriteContentUndoEntry? fromJson(Map<String, Object?> json) {
    final c = json['change'];
    if (c is! List) return null;
    try {
      return WriteContentUndoEntry(
        change: Delta.fromJson(c),
        select: DeltaSelection.fromJson(json['select']),
        counterSelect: DeltaSelection.fromJson(json['counterSelect']),
      );
    } on Object {
      return null;
    }
  }

  @override
  String toString() => 'WriteContentUndoEntry($change)';
}

/// A remote content change for `UndoService.applyRemote`: the rebased
/// entries, precomputed by [rebaseWriteStacks] (selective-undo rebasing needs
/// the remote change expressed past every newer entry, which the generic
/// per-step rebase cannot do).
class WriteContentRemoteChange extends RemoteChange {
  WriteContentRemoteChange(this.results);

  /// Rebased entry (null = drop) per original entry (identity).
  final Map<WriteContentUndoEntry, WriteContentUndoEntry?> results;

  @override
  String get domain => WriteContentUndoEntry.domainName;
}

/// Rebases the `write.content` entries of an undo stack and a redo stack
/// (each oldest first, as `UndoService.undoStepsOf` returns them) over a
/// remote change [remote] that was just applied to the document (Write 03
/// §4): newest to oldest, `U' = R.transform(U, true)` and `R =
/// U.transform(R, false)`. Undo steps run their entries last to first, redo
/// steps first to last.
WriteContentRemoteChange? rebaseWriteStacks(
  List<UndoStep> undo,
  List<UndoStep> redo,
  Delta remote,
) {
  final results = Map<WriteContentUndoEntry, WriteContentUndoEntry?>.identity();
  void walk(List<UndoStep> steps, {required bool reversedEntries}) {
    var r = remote;
    for (final step in steps.reversed) {
      final entries = reversedEntries ? step.entries.reversed : step.entries;
      for (final e in entries) {
        if (e is! WriteContentUndoEntry) continue;
        final (rebased, next) = e.rebaseOver(r);
        results[e] = rebased;
        r = next;
      }
    }
  }

  walk(undo, reversedEntries: true);
  walk(redo, reversedEntries: false);
  return results.isEmpty ? null : WriteContentRemoteChange(results);
}

/// One `write.meta` undo entry (Write 03 §6): a document property and its
/// JSON values before and after. Dropped when someone else changes the
/// property afterwards.
class WriteMetaUndoEntry extends UndoEntry {
  const WriteMetaUndoEntry({
    required this.documentUuid,
    required this.field,
    required this.beforeJson,
    required this.afterJson,
  });

  static const domainName = 'write.meta';

  final String documentUuid;

  /// `themeId`, `pageSetup`, `language` or `frontMatter`.
  final String field;
  final String beforeJson;
  final String afterJson;

  @override
  String get domain => domainName;

  WriteMetaUndoEntry get swapped => WriteMetaUndoEntry(
    documentUuid: documentUuid,
    field: field,
    beforeJson: afterJson,
    afterJson: beforeJson,
  );

  @override
  UndoEntry? rebase(RemoteChange change) {
    if (change is! FieldRemoteChange ||
        change.target != documentUuid ||
        change.key != field) {
      return this;
    }
    if (change.deleted) return null;
    return sameJson('${change.value}', afterJson) ? this : null;
  }

  @override
  Map<String, Object?> toJson() => {
    'documentUuid': documentUuid,
    'field': field,
    'before': beforeJson,
    'after': afterJson,
  };

  static WriteMetaUndoEntry? fromJson(Map<String, Object?> json) {
    final d = json['documentUuid'];
    final f = json['field'];
    final b = json['before'];
    final a = json['after'];
    if (d is! String || f is! String || b is! String || a is! String) {
      return null;
    }
    return WriteMetaUndoEntry(
      documentUuid: d,
      field: f,
      beforeJson: b,
      afterJson: a,
    );
  }

  /// Whether two JSON strings encode the same value.
  static bool sameJson(String a, String b) {
    if (a == b) return true;
    try {
      return canonicalJsonEncode(jsonDecode(a)) ==
          canonicalJsonEncode(jsonDecode(b));
    } on FormatException {
      return false;
    }
  }
}

/// Runs `write.meta` entries by writing [WriteMetaUndoEntry.beforeJson]
/// through [write].
class WriteMetaUndoHandler extends UndoHandler<WriteMetaUndoEntry> {
  WriteMetaUndoHandler(this.write);

  /// Writes a property value (`document.updateMeta`).
  final Future<void> Function(String field, String valueJson) write;

  @override
  String get domain => WriteMetaUndoEntry.domainName;

  @override
  UndoEntryDecoder? get decoder => WriteMetaUndoEntry.fromJson;

  @override
  Future<WriteMetaUndoEntry> undo(WriteMetaUndoEntry entry) async {
    await write(entry.field, entry.beforeJson);
    return entry.swapped;
  }

  @override
  Future<WriteMetaUndoEntry> redo(WriteMetaUndoEntry entry) async {
    await write(entry.field, entry.beforeJson);
    return entry.swapped;
  }
}

/// The base range `[lo, hi]` a change touches (from its first insert,
/// delete or attributed retain to the end of its last one) and its length
/// change, for rebasing disjoint changes without transforms.
class _Touched {
  const _Touched(this.lo, this.hi, this.net, this.lead);

  final int lo;
  final int hi;
  final int net;

  /// Number of (plain retain) ops before [lo].
  final int lead;

  static _Touched? of(Delta change) {
    var offset = 0;
    var net = 0;
    var lead = 0;
    int? lo;
    var hi = 0;
    for (final op in change.operations) {
      final length = op.length!;
      final attributes = op.attributes;
      if (op.isRetain && (attributes == null || attributes.isEmpty)) {
        if (lo == null) lead++;
        offset += length;
        continue;
      }
      lo ??= offset;
      if (op.isInsert) {
        net += length;
      } else {
        if (op.isDelete) net -= length;
        offset += length;
      }
      if (offset > hi) hi = offset;
    }
    return lo == null ? null : _Touched(lo, hi, net, lead);
  }

  /// [change] (the change this was computed from) moved by [by] characters.
  Delta shifted(Delta change, int by) {
    final out = Delta()..retain(lo + by);
    for (final op in change.operations.skip(lead)) {
      out.push(op);
    }
    return out;
  }
}
