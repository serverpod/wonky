// Frozen copy of a removed implementation, kept as a test oracle.
import 'package:collection/collection.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Context of one suggestion rewrite (Write 08 §2.3).
class LegacySuggestionContext {
  const LegacySuggestionContext({
    required this.userUuid,
    required this.nowMs,
    required this.suggestionId,
    this.via,
  });

  final String userUuid;
  final int nowMs;

  /// The suggestion id for new parts (from the suggestion session).
  final String suggestionId;

  /// `ai` / `mcp` when the change was made by an agent on the user's behalf.
  final String? via;
}

/// Rewrites a change Delta into suggestion form (Write 08 §2.3, Write 04
/// §32.1): insertions get `sug_<id>{t:ins}`, deletions of other people's text
/// become `sug_<id>{t:del}` retains, formatting changes get
/// `sug_<id>{t:fmt, before}`; deleting or formatting your own suggested
/// insertion applies directly. Comment anchor changes pass through.
///
/// The editor's former copy (`wonky_write/lib/features/editor/suggesting/`),
/// kept unchanged as the oracle of the differential test that pinned its
/// merge into the core `SuggestionRewriter` (CQ-50). Never used by `lib/`.
class LegacyEditorSuggestionRewriter {
  const LegacyEditorSuggestionRewriter();

  static const _prefix = 'sug_';
  static const _inlineKeys = {
    'bold',
    'italic',
    'strike',
    'code',
    'link',
    'mention',
  };
  static const _blockKeys = {
    'header',
    'blockquote',
    'code-block',
    'list',
    'indent',
  };

  /// Rewrites [change] (against [documentBefore]) into suggestion form.
  Delta rewrite(
    Delta documentBefore,
    Delta change,
    LegacySuggestionContext context,
  ) {
    final result = Delta();
    final base = _Cursor(documentBefore);
    String? lastOwnInsertionKey;
    Map<String, dynamic>? lastOwnInsertionData;
    Map<String, dynamic>? previousBaseAttributes;

    for (final op in _deletesFirst(change.operations)) {
      if (op.isInsert) {
        // Typing inside or right after your own suggested insertion extends it.
        final ownBefore = _ownInsertion(
          previousBaseAttributes,
          context.userUuid,
        );
        final ownAfter = base.hasNext
            ? _ownInsertion(base.peekAttributes, context.userUuid)
            : null;
        final own = ownBefore ?? ownAfter;
        final key =
            own?.$1 ?? lastOwnInsertionKey ?? '$_prefix${context.suggestionId}';
        final data = own?.$2 ?? lastOwnInsertionData ?? _data('ins', context);
        lastOwnInsertionKey = key;
        lastOwnInsertionData = data;
        final attributes = <String, dynamic>{
          for (final entry
              in (op.attributes ?? const <String, dynamic>{}).entries)
            if (!entry.key.startsWith(_prefix)) entry.key: entry.value,
          key: data,
        };
        result.insert(op.data, attributes);
        continue;
      }

      var remaining = op.length!;
      while (remaining > 0) {
        if (!base.hasNext) {
          // Past the end of the document (shouldn't happen for valid changes).
          if (op.isDelete) {
            result.delete(remaining);
          } else {
            result.retain(remaining, op.attributes);
          }
          break;
        }
        final piece = base.next(remaining);
        final length = piece.length!;
        remaining -= length;
        final baseAttributes = piece.attributes;
        previousBaseAttributes = baseAttributes;
        final isLineEnd = piece.data == '\n';

        if (op.isRetain) {
          final attributes = op.attributes;
          if (attributes == null || attributes.isEmpty) {
            result.retain(length);
            continue;
          }
          if (attributes.keys.every(
            (k) => k.startsWith('cmt_') || k.startsWith(_prefix),
          )) {
            // Comment anchors (and explicit suggestion edits) pass through.
            result.retain(length, attributes);
            continue;
          }
          if (_ownInsertion(baseAttributes, context.userUuid) != null) {
            result.retain(length, attributes);
            continue;
          }
          result.retain(
            length,
            _formatAttributes(baseAttributes, attributes, isLineEnd, context),
          );
          continue;
        }

        // Delete.
        if (_ownInsertion(baseAttributes, context.userUuid) != null) {
          result.delete(length);
          continue;
        }
        if (_hasDeletion(baseAttributes)) {
          result.retain(length);
          continue;
        }
        result.retain(length, {
          '$_prefix${context.suggestionId}': _data('del', context),
        });
      }
    }
    result.trim();
    return result;
  }

  Map<String, dynamic> _formatAttributes(
    Map<String, dynamic>? baseAttributes,
    Map<String, dynamic> change,
    bool isLineEnd,
    LegacySuggestionContext context,
  ) {
    final trackedKeys = isLineEnd ? _blockKeys : _inlineKeys;
    final base = baseAttributes ?? const <String, dynamic>{};

    // An existing format suggestion of mine on this text keeps its `before`.
    final ownFormat = base.entries.firstWhereOrNull((e) {
      final value = e.value;
      return e.key.startsWith(_prefix) &&
          value is Map &&
          value['t'] == 'fmt' &&
          value['by'] == context.userUuid;
    });
    final result = <String, dynamic>{...change};
    if (ownFormat != null) {
      final before = (ownFormat.value as Map)['before'] as Map? ?? const {};
      final after = <String, dynamic>{
        for (final key in trackedKeys)
          if (base[key] != null) key: base[key],
      };
      for (final entry in change.entries) {
        if (!trackedKeys.contains(entry.key)) continue;
        if (entry.value == null) {
          after.remove(entry.key);
        } else {
          after[entry.key] = entry.value;
        }
      }
      if (const DeepCollectionEquality().equals(after, before)) {
        // Net no change: drop the format suggestion.
        result[ownFormat.key] = null;
      }
      return result;
    }

    final before = <String, dynamic>{
      for (final key in trackedKeys)
        if (base[key] != null) key: base[key],
    };
    result['$_prefix${context.suggestionId}'] = {
      ..._data('fmt', context),
      'before': before,
    };
    return result;
  }

  /// Reorders `insert, delete` pairs into `delete, insert` so that the
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

  static Map<String, dynamic> _data(
    String type,
    LegacySuggestionContext context,
  ) => {
    't': type,
    'by': context.userUuid,
    'at': context.nowMs,
    if (context.via != null) 'via': context.via,
  };

  static (String, Map<String, dynamic>)? _ownInsertion(
    Map<String, dynamic>? attributes,
    String userUuid,
  ) {
    if (attributes == null) return null;
    for (final entry in attributes.entries) {
      final value = entry.value;
      if (entry.key.startsWith(_prefix) &&
          value is Map &&
          value['t'] == 'ins' &&
          value['by'] == userUuid) {
        return (entry.key, value.cast<String, dynamic>());
      }
    }
    return null;
  }

  static bool _hasDeletion(Map<String, dynamic>? attributes) {
    if (attributes == null) return false;
    return attributes.entries.any(
      (e) =>
          e.key.startsWith(_prefix) &&
          e.value is Map &&
          (e.value as Map)['t'] == 'del',
    );
  }
}

/// A cursor over a document Delta that can peek at the next attributes.
class _Cursor {
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
