/// Overlay tracking (`cmt_*`/`sug_*` character counts) and comment anchor
/// helpers (08 §1).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/delta_utils.dart';
import '../delta/document.dart';

/// Kind of an overlay key.
enum OverlayKind {
  /// `cmt_<threadUuid>`.
  comment,

  /// `sug_<suggestionId>`.
  suggestion,
}

/// A count transition of one overlay key.
final class OverlayTransition {
  /// Creates a transition.
  const OverlayTransition(this.key, {required this.appeared});

  /// The attribute key.
  final String key;

  /// `true` for 0 → >0 (first appearance / un-orphaning), `false` for
  /// >0 → 0 (orphaned / suggestion resolved).
  final bool appeared;

  /// Overlay kind.
  OverlayKind get kind =>
      WonkyAttr.isComment(key) ? OverlayKind.comment : OverlayKind.suggestion;

  /// Thread UUID or suggestion id.
  String get id =>
      WonkyAttr.commentThreadId(key) ?? WonkyAttr.suggestionId(key)!;

  @override
  bool operator ==(Object other) =>
      other is OverlayTransition &&
      other.key == key &&
      other.appeared == appeared;

  @override
  int get hashCode => Object.hash(key, appeared);

  @override
  String toString() => 'OverlayTransition($key ${appeared ? '0→>0' : '>0→0'})';
}

/// Maps every overlay key to the number of characters carrying it; updated
/// from `(op, inverse)` pairs only (no document rescans).
final class OverlayIndex {
  final _counts = <String, int>{};

  /// Current counts (read-only view).
  Map<String, int> get counts => Map.unmodifiable(_counts);

  /// Count of [key].
  int count(String key) => _counts[key] ?? 0;

  /// Rebuilds the index from [document] (O(n)).
  void reset(Delta document) {
    _counts.clear();
    for (final op in document.operations) {
      if (!op.isInsert) continue;
      for (final key in (op.attributes ?? const <String, dynamic>{}).keys) {
        if (WonkyAttr.isOverlay(key) && op.attributes![key] != null) {
          _counts[key] = (_counts[key] ?? 0) + op.length!;
        }
      }
    }
  }

  /// Applies an op with its [inverse] (against the pre-op document) and
  /// returns the transitions it caused.
  List<OverlayTransition> apply(Delta op, Delta inverse) {
    final before = <String, int>{};
    void bump(String key, int delta) {
      before.putIfAbsent(key, () => _counts[key] ?? 0);
      _counts[key] = (_counts[key] ?? 0) + delta;
    }

    // Inserts of the op add their overlays.
    // Retains of the op that set an overlay: compare with the inverse in
    // post-op coordinates.
    final setRanges = <(int start, int len, Map<String, dynamic> attrs)>[];
    var post = 0;
    for (final o in op.operations) {
      final len = o.length!;
      if (o.isInsert) {
        for (final e in (o.attributes ?? const <String, dynamic>{}).entries) {
          if (WonkyAttr.isOverlay(e.key) && e.value != null) bump(e.key, len);
        }
        post += len;
      } else if (o.isRetain) {
        final overlays = {
          for (final e in (o.attributes ?? const <String, dynamic>{}).entries)
            if (WonkyAttr.isOverlay(e.key)) e.key: e.value,
        };
        if (overlays.isNotEmpty) setRanges.add((post, len, overlays));
        post += len;
      }
    }
    // Walk the inverse: inserts are deleted content; retains carry the
    // previous values of changed attributes.
    var pos = 0;
    var rangeIndex = 0;
    for (final inv in inverse.operations) {
      final len = inv.length!;
      if (inv.isInsert) {
        for (final e in (inv.attributes ?? const <String, dynamic>{}).entries) {
          if (WonkyAttr.isOverlay(e.key) && e.value != null) bump(e.key, -len);
        }
        continue;
      }
      if (inv.isDelete) {
        pos += len;
        continue;
      }
      // Retain [pos, pos + len) in post coordinates.
      final invAttrs = inv.attributes ?? const <String, dynamic>{};
      while (rangeIndex < setRanges.length &&
          setRanges[rangeIndex].$1 + setRanges[rangeIndex].$2 <= pos) {
        rangeIndex++;
      }
      for (var r = rangeIndex; r < setRanges.length; r++) {
        final (rs, rl, attrs) = setRanges[r];
        if (rs >= pos + len) break;
        final overlap =
            (rs + rl < pos + len ? rs + rl : pos + len) - (rs > pos ? rs : pos);
        if (overlap <= 0) continue;
        for (final e in attrs.entries) {
          final wasPresent = invAttrs.containsKey(e.key)
              ? invAttrs[e.key] != null
              : null;
          if (e.value != null) {
            // Op set the key: inverse null ⇒ newly added.
            if (wasPresent == false) bump(e.key, overlap);
          } else {
            // Op removed the key: inverse has the old value ⇒ removed.
            if (wasPresent == true) bump(e.key, -overlap);
          }
        }
      }
      pos += len;
    }
    final transitions = <OverlayTransition>[];
    for (final e in before.entries) {
      final now = _counts[e.key] ?? 0;
      if (now <= 0) _counts.remove(e.key);
      if (e.value <= 0 && now > 0) {
        transitions.add(OverlayTransition(e.key, appeared: true));
      }
      if (e.value > 0 && now <= 0) {
        transitions.add(OverlayTransition(e.key, appeared: false));
      }
    }
    return transitions;
  }
}

/// A comment anchor range.
final class AnchorRange {
  /// Creates a range.
  const AnchorRange(this.start, this.length);

  /// Start offset.
  final int start;

  /// Length.
  final int length;

  /// End offset.
  int get end => start + length;

  /// JSON form.
  Map<String, dynamic> toJson() => {'start': start, 'length': length};

  @override
  bool operator ==(Object other) =>
      other is AnchorRange && other.start == start && other.length == length;

  @override
  int get hashCode => Object.hash(start, length);

  @override
  String toString() => 'AnchorRange($start, $length)';
}

/// One run of a comment anchor: [length] characters from [start] carry
/// `cmt_<threadUuid>`; [text] is their text (embeds as [embedChar]).
typedef CommentPiece = ({
  String threadUuid,
  int start,
  int length,
  String text,
});

/// The anchor of a thread: overall extent and quote.
final class CommentAnchor {
  /// Creates an anchor.
  const CommentAnchor(this.threadUuid, this.ranges, this.quote);

  /// Thread UUID.
  final String threadUuid;

  /// Contiguous ranges in document order.
  final List<AnchorRange> ranges;

  /// Text covered (≤ 500 chars, embeds removed, line ends as spaces).
  final String quote;

  /// First offset.
  int get start => ranges.first.start;

  /// Extent from the first to the last anchored character.
  int get length => ranges.last.end - ranges.first.start;

  /// MCP JSON `{start, length, quote}`.
  Map<String, dynamic> toJson() => {
    'start': start,
    'length': length,
    'quote': quote,
  };
}

/// Comment anchor helpers.
abstract final class CommentAnchors {
  /// Maximum stored quote length.
  static const maxQuote = 500;

  /// Anchors of all threads in [document].
  static Map<String, CommentAnchor> anchors(Delta document) =>
      fromPieces(pieces(document));

  /// The anchored runs of [document] in document order: one per insert and
  /// thread, with the insert's text (embeds as [embedChar]). A document
  /// can be split anywhere: the pieces of its parts, with their offsets
  /// shifted, are the pieces of the whole (the Write editor keeps them per
  /// block and rescans only changed blocks, Write 04 §36).
  static List<CommentPiece> pieces(Delta document) {
    final out = <CommentPiece>[];
    var offset = 0;
    for (final op in document.operations) {
      if (!op.isInsert) {
        throw ArgumentError.value(document, 'document', 'not a document delta');
      }
      final len = op.length!;
      final ids = Attributes.comments(op.attributes);
      if (ids.isNotEmpty) {
        final data = op.data;
        final text = data is String ? data : embedChar;
        for (final id in ids) {
          out.add((threadUuid: id, start: offset, length: len, text: text));
        }
      }
      offset += len;
    }
    return out;
  }

  /// Anchors from [pieces] in document order: contiguous runs of a thread
  /// form one range.
  static Map<String, CommentAnchor> fromPieces(Iterable<CommentPiece> pieces) {
    final ranges = <String, List<AnchorRange>>{};
    final texts = <String, List<StringBuffer>>{};
    for (final p in pieces) {
      final list = ranges.putIfAbsent(p.threadUuid, () => []);
      final text = texts.putIfAbsent(p.threadUuid, () => []);
      if (list.isNotEmpty && list.last.end == p.start) {
        list[list.length - 1] = AnchorRange(
          list.last.start,
          list.last.length + p.length,
        );
        text.last.write(p.text);
      } else {
        list.add(AnchorRange(p.start, p.length));
        text.add(StringBuffer(p.text));
      }
    }
    return {
      for (final e in ranges.entries)
        e.key: CommentAnchor(
          e.key,
          e.value,
          quoteOfTexts([for (final b in texts[e.key]!) b.toString()]),
        ),
    };
  }

  /// The anchor of [threadUuid], or `null` when orphaned.
  static CommentAnchor? anchorOf(Delta document, String threadUuid) =>
      anchors(document)[threadUuid];

  /// Thread ids of [openThreads] without any anchored character.
  static Set<String> orphaned(Delta document, Iterable<String> openThreads) {
    final present = anchors(document).keys.toSet();
    return {
      for (final t in openThreads)
        if (!present.contains(t)) t,
    };
  }

  /// The quoted text of [ranges].
  static String quoteOf(WonkyDocument doc, List<AnchorRange> ranges) =>
      quoteOfTexts([
        for (final r in ranges) doc.text.substring(r.start, r.end),
      ]);

  /// The quoted text of ranges with the texts [rangeTexts].
  static String quoteOfTexts(List<String> rangeTexts) {
    final b = StringBuffer();
    for (final t in rangeTexts) {
      if (b.isNotEmpty) b.write(' ');
      b.write(t);
    }
    var q = b
        .toString()
        .replaceAll(embedChar, '')
        .replaceAll(RegExp('[\n$softBreak]+'), ' ')
        .trim();
    if (q.length > maxQuote) {
      q = q.substring(0, maxQuote);
      if (q.isNotEmpty &&
          q.codeUnitAt(q.length - 1) >= 0xD800 &&
          q.codeUnitAt(q.length - 1) <= 0xDBFF) {
        q = q.substring(0, q.length - 1);
      }
    }
    return q;
  }

  /// The op anchoring [threadUuid] on `[start, start + length)` (line ends
  /// and embeds inside the range carry the attribute too).
  static Delta addAnchor(String threadUuid, int start, int length) =>
      DeltaUtils.format(start, length, {
        WonkyAttr.commentKey(threadUuid): true,
      });

  /// The op removing every anchor of [threadUuid] from [document].
  static Delta removeAnchor(Delta document, String threadUuid) {
    final key = WonkyAttr.commentKey(threadUuid);
    final d = Delta();
    for (final op in document.operations) {
      final len = op.length!;
      if (op.attributes?.containsKey(key) ?? false) {
        d.retain(len, {key: null});
      } else {
        d.retain(len);
      }
    }
    return DeltaUtils.canonical(d);
  }

  /// The op rewriting comment keys per [mapping] (old → new thread UUID,
  /// *Make a copy* with comments); unmapped keys are removed when
  /// [dropUnmapped].
  static Delta remapThreads(
    Delta document,
    Map<String, String> mapping, {
    bool dropUnmapped = true,
  }) {
    final d = Delta();
    for (final op in document.operations) {
      final len = op.length!;
      final patch = <String, dynamic>{};
      for (final id in Attributes.comments(op.attributes)) {
        patch[WonkyAttr.commentKey(id)] = null;
        final to = mapping[id];
        if (to != null) {
          patch[WonkyAttr.commentKey(to)] = true;
        } else if (!dropUnmapped) {
          patch.remove(WonkyAttr.commentKey(id));
        }
      }
      d.retain(len, patch.isEmpty ? null : patch);
    }
    return DeltaUtils.canonical(d);
  }
}
