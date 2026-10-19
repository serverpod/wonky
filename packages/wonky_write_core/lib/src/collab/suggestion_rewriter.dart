/// Suggesting mode: rewriting edits into suggestions (08 §2.3–§2.4).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/delta_utils.dart';

/// Context of one rewrite.
final class SuggestionContext {
  /// Creates a context.
  const SuggestionContext({
    required this.userUuid,
    required this.nowMs,
    required this.suggestionId,
    this.via,
  });

  /// The suggesting user.
  final String userUuid;

  /// Timestamp (epoch ms; the server re-stamps it).
  final int nowMs;

  /// Suggestion id for the parts created by this change (see
  /// [SuggestionSession]).
  final String suggestionId;

  /// `ai` / `mcp` when produced on the user's behalf.
  final String? via;
}

/// Rewrites a change into suggestion form (Write 08 §2.3, Write 04 §32.1).
///
/// The one implementation used by the editor, the AI assistant and the
/// server's MCP headless editor (CQ-50). Rules (per op component, against the
/// attributes of `docBefore`):
///
/// - `insert, delete` runs are reordered to `delete, insert`, so the
///   suggested insertion of a replacement follows the struck text (08 §2.4);
/// - inserts get `sug_<id>{t:ins}` (foreign `sug_*` stripped); the user's own
///   typing (no `via`) inside, right after or right before their own typed
///   suggested insertion extends it (same key and mark; agent edits always get
///   a mark of their own, so `via` and the returned id stay right), and the
///   inserts of one change share one mark;
/// - deletes of own insertions are real deletes, already-deleted text is
///   untouched, other text gets `sug_<id>{t:del}`;
/// - attribute changes on own insertions apply directly, on text with an own
///   `fmt` suggestion they apply keeping its `before` (and drop the mark when
///   the result equals `before`), elsewhere they add
///   `sug_<id>{t:fmt, before}` with the original attributes; a change with
///   no effect on a piece adds nothing;
/// - `cmt_*` changes pass through.
final class SuggestionRewriter {
  /// Creates a rewriter.
  const SuggestionRewriter();

  /// Rewrites [change] (applicable to [docBefore]).
  Delta rewrite(Delta docBefore, Delta change, SuggestionContext ctx) {
    final key = WonkyAttr.suggestionKey(ctx.suggestionId);
    SuggestionMark mark(SuggestionKind kind, {Map<String, dynamic>? before}) =>
        SuggestionMark(
          kind: kind,
          by: ctx.userUuid,
          at: ctx.nowMs,
          before: before,
          via: ctx.via,
        );

    final out = Delta();
    final it = _Cursor(docBefore);
    // The attributes of the base piece just before the cursor (own insertion
    // extension) and the mark this change's inserts use.
    Map<String, dynamic>? previous;
    (String, Map<String, dynamic>)? insertMark;
    for (final op in _deletesFirst(change.operations)) {
      if (op.isInsert) {
        final own =
            _ownInsertion(previous, ctx) ??
            (it.hasNext ? _ownInsertion(it.peekAttributes, ctx) : null);
        final (insertKey, data) =
            own ?? insertMark ?? (key, mark(SuggestionKind.ins).toJson());
        insertMark = (insertKey, data);
        final attrs = {
          for (final e in (op.attributes ?? const <String, dynamic>{}).entries)
            if (!WonkyAttr.isSuggestion(e.key) && e.value != null)
              e.key: e.value,
          insertKey: data,
        };
        out.push(Operation.insert(op.data, attrs));
        continue;
      }
      var remaining = op.length!;
      if (op.isRetain && op.isPlain) {
        out.retain(remaining);
        while (remaining > 0 && it.hasNext) {
          final piece = it.next(remaining);
          previous = piece.attributes;
          remaining -= piece.length!;
        }
        continue;
      }
      while (remaining > 0) {
        if (!it.hasNext) {
          throw ArgumentError('Change is longer than the document');
        }
        final piece = it.next(remaining);
        final len = piece.length!;
        remaining -= len;
        previous = piece.attributes;
        final current = piece.attributes ?? const <String, dynamic>{};
        final marks = Attributes.suggestions(current);
        final ownIns = marks.values.any(
          (m) => m.kind == SuggestionKind.ins && m.by == ctx.userUuid,
        );
        if (op.isDelete) {
          if (ownIns) {
            out.delete(len);
          } else if (marks.values.any((m) => m.kind == SuggestionKind.del)) {
            out.retain(len);
          } else {
            out.retain(len, {key: mark(SuggestionKind.del).toJson()});
          }
          continue;
        }
        // Attribute retain.
        final patch = op.attributes ?? const <String, dynamic>{};
        final overlayPatch = {
          for (final e in patch.entries)
            if (WonkyAttr.isOverlay(e.key)) e.key: e.value,
        };
        // Only attributes valid for this piece (inline on text, block on
        // line ends); others would be dropped by the normalizer anyway.
        final pieceGroup = piece.data == '\n'
            ? WonkyAttr.blockKeys
            : piece.data is String
            ? WonkyAttr.inlineKeys
            : const <String>{};
        final contentPatch = {
          for (final e in patch.entries)
            if (!WonkyAttr.isOverlay(e.key) && pieceGroup.contains(e.key))
              e.key: e.value,
        };
        final effective = Attributes.diff(
          Attributes.withoutOverlays(current),
          Attributes.apply(Attributes.withoutOverlays(current), contentPatch) ??
              const {},
        );
        if (effective == null || ownIns) {
          out.retain(len, Attributes.orNull({...overlayPatch, ...?effective}));
          continue;
        }
        final isNewline = piece.data == '\n';
        final group = isNewline ? WonkyAttr.blockKeys : WonkyAttr.inlineKeys;
        final after =
            Attributes.apply(
              Attributes.withoutOverlays(current),
              contentPatch,
            ) ??
            const {};
        final ownFmt = marks.entries
            .where(
              (e) =>
                  e.value.kind == SuggestionKind.fmt &&
                  e.value.by == ctx.userUuid,
            )
            .firstOrNull;
        if (ownFmt != null) {
          final before = ownFmt.value.before ?? const <String, dynamic>{};
          final afterGroup = {
            for (final e in after.entries)
              if (group.contains(e.key)) e.key: e.value,
          };
          final result = {...overlayPatch, ...effective};
          if (Attributes.equals(afterGroup, before)) {
            result[WonkyAttr.suggestionKey(ownFmt.key)] = null;
          }
          out.retain(len, result);
          continue;
        }
        final before = {
          for (final e in current.entries)
            if (group.contains(e.key)) e.key: e.value,
        };
        out.retain(len, {
          ...overlayPatch,
          ...effective,
          key: mark(SuggestionKind.fmt, before: before).toJson(),
        });
      }
    }
    return DeltaUtils.canonical(out);
  }

  /// Reorders `insert, delete` runs into `delete, insert` so that the
  /// suggested insertion of a replacement comes after the struck text
  /// (Write 08 §2.4). Both orders describe the same change.
  static List<Operation> _deletesFirst(List<Operation> ops) {
    final result = <Operation>[];
    var i = 0;
    while (i < ops.length) {
      if (ops[i].isInsert) {
        var j = i;
        while (j < ops.length && ops[j].isInsert) {
          j += 1;
        }
        var k = j;
        while (k < ops.length && ops[k].isDelete) {
          k += 1;
        }
        result
          ..addAll(ops.sublist(j, k))
          ..addAll(ops.sublist(i, j));
        i = k;
        continue;
      }
      result.add(ops[i]);
      i += 1;
    }
    return result;
  }

  /// The key and mark of the user's own typed suggested insertion in
  /// [attributes] that an insert of [ctx] extends, if any: only the user's
  /// own typing (no `via`) extends, and only an insertion they typed.
  static (String, Map<String, dynamic>)? _ownInsertion(
    Map<String, dynamic>? attributes,
    SuggestionContext ctx,
  ) {
    if (attributes == null || ctx.via != null) return null;
    for (final entry in attributes.entries) {
      final value = entry.value;
      if (WonkyAttr.isSuggestion(entry.key) &&
          value is Map &&
          value['t'] == SuggestionKind.ins.value &&
          value['by'] == ctx.userUuid &&
          value['via'] == null) {
        return (entry.key, value.cast<String, dynamic>());
      }
    }
    return null;
  }
}

/// A cursor over a document Delta that can peek at the next piece's
/// attributes.
final class _Cursor {
  _Cursor(this.delta);

  final Delta delta;
  int _index = 0;
  int _offset = 0;

  bool get hasNext => _index < delta.length;

  Map<String, dynamic>? get peekAttributes =>
      hasNext ? delta[_index].attributes : null;

  /// The next piece of at most [length] characters.
  Operation next(int length) {
    final op = delta[_index];
    final opLength = op.length!;
    final take = length < opLength - _offset ? length : opLength - _offset;
    final data = op.data;
    final piece = Operation.insert(
      data is String ? data.substring(_offset, _offset + take) : data,
      op.attributes,
    );
    _offset += take;
    if (_offset >= opLength) {
      _index += 1;
      _offset = 0;
    }
    return piece;
  }
}

/// Tracks suggestion identity across consecutive edits (08 §2.4): the same
/// id is reused for consecutive insertions/deletions by the user in the same
/// block within 30 s without a caret jump; formatting mints a new id unless
/// re-formatting the same range within 5 s.
final class SuggestionSession {
  /// Creates a session; [newId] mints UUIDv7 ids.
  SuggestionSession(this.newId);

  /// Id generator.
  final String Function() newId;

  /// Reuse window for typing/deleting.
  static const typingWindowMs = 30000;

  /// Reuse window for re-formatting the same range.
  static const formatWindowMs = 5000;

  String? _id;
  int _lastMs = 0;
  int _blockStart = -1;
  int _expectedCaret = -1;
  String? _formatId;
  int _formatMs = 0;
  (int, int)? _formatRange;

  /// The id for a text edit (insert/delete) in the block starting at
  /// [blockStart], with the caret at [caretBefore] before the edit and
  /// [caretAfter] after it, at [nowMs].
  String forTextEdit({
    required int blockStart,
    required int caretBefore,
    required int caretAfter,
    required int nowMs,
  }) {
    final reuse =
        _id != null &&
        nowMs - _lastMs <= typingWindowMs &&
        blockStart == _blockStart &&
        caretBefore == _expectedCaret;
    if (!reuse) _id = newId();
    _lastMs = nowMs;
    _blockStart = blockStart;
    _expectedCaret = caretAfter;
    return _id!;
  }

  /// The id for a formatting edit of `[start, start + length)` at [nowMs].
  String forFormat({
    required int start,
    required int length,
    required int nowMs,
  }) {
    final reuse =
        _formatId != null &&
        nowMs - _formatMs <= formatWindowMs &&
        _formatRange == (start, length);
    if (!reuse) _formatId = newId();
    _formatMs = nowMs;
    _formatRange = (start, length);
    _id = null;
    return _formatId!;
  }

  /// Forgets the current ids (caret jump, mode switch, remote edit nearby).
  void reset() {
    _id = null;
    _formatId = null;
    _formatRange = null;
  }

  /// Transforms the remembered caret through a remote change.
  void transformThrough(Delta remote) {
    if (_expectedCaret >= 0) {
      _expectedCaret = remote.transformPosition(_expectedCaret);
    }
    if (_blockStart >= 0) {
      _blockStart = remote.transformPosition(_blockStart, force: false);
    }
  }
}
