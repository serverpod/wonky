/// Accept/reject operations, suggestion listing and decision inference
/// (08 §2.7–§2.9, 09 §2.4).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/delta_utils.dart';
import '../delta/document.dart';
import '../delta/embeds.dart';

/// Builds accept/reject ops from the current document state.
abstract final class SuggestionOps {
  /// One op accepting every part of [ids] (`ins` → mark removed, `del` →
  /// text deleted, `fmt` → mark removed).
  static Delta accept(Delta document, Set<String> ids) =>
      _build(document, ids, accept: true);

  /// One op rejecting (or withdrawing) every part of [ids] (`ins` → text
  /// deleted, `del` → mark removed, `fmt` → `before` restored).
  static Delta reject(Delta document, Set<String> ids) =>
      _build(document, ids, accept: false);

  /// Accepts all pending suggestions (optionally only those by [authorUuid]).
  static Delta acceptAll(Delta document, {String? authorUuid}) =>
      accept(document, pendingIds(document, authorUuid: authorUuid));

  /// Rejects all pending suggestions (optionally only those by [authorUuid]).
  static Delta rejectAll(Delta document, {String? authorUuid}) =>
      reject(document, pendingIds(document, authorUuid: authorUuid));

  /// Ids of all suggestions in [document].
  static Set<String> pendingIds(Delta document, {String? authorUuid}) {
    final ids = <String>{};
    for (final op in document.operations) {
      for (final e in Attributes.suggestions(op.attributes).entries) {
        if (authorUuid == null || e.value.by == authorUuid) ids.add(e.key);
      }
    }
    return ids;
  }

  static Delta _build(Delta document, Set<String> ids, {required bool accept}) {
    final out = Delta();
    final doc = WonkyDocument(document);
    for (final line in doc.lines) {
      final pieces = <(Object, Map<String, dynamic>?, bool)>[
        for (final seg in line.segments) (seg.data, seg.attributes, false),
        if (line.hasNewline) ('\n', line.attributes, true),
      ];
      for (final (data, attrs, isNewline) in pieces) {
        final len = data is String ? data.length : 1;
        final a = attrs ?? const <String, dynamic>{};
        final selected = {
          for (final e in Attributes.suggestions(a).entries)
            if (ids.contains(e.key)) e.key: e.value,
        };
        if (selected.isEmpty) {
          out.retain(len);
          continue;
        }
        var delete = false;
        final patch = <String, dynamic>{};
        for (final e in selected.entries) {
          final key = WonkyAttr.suggestionKey(e.key);
          final m = e.value;
          switch (m.kind) {
            case SuggestionKind.ins:
              if (accept) {
                patch[key] = null;
              } else {
                delete = true;
              }
            case SuggestionKind.del:
              if (accept) {
                delete = true;
              } else {
                patch[key] = null;
              }
            case SuggestionKind.fmt:
              patch[key] = null;
              if (!accept) {
                final group = isNewline
                    ? WonkyAttr.blockKeys
                    : WonkyAttr.inlineKeys;
                final before = m.before ?? const <String, dynamic>{};
                for (final k in group) {
                  if (a[k] != before[k]) patch[k] = before[k];
                }
              }
          }
        }
        if (delete) {
          out.delete(len);
        } else {
          out.retain(len, patch);
        }
      }
    }
    return DeltaUtils.canonical(out);
  }
}

/// Kind of a listed suggestion part (MCP naming).
enum SuggestionPartKind {
  /// Inserted text.
  insert,

  /// Text proposed for deletion.
  delete,

  /// Inline formatting change.
  format,

  /// Block type change.
  blockFormat,
}

/// One contiguous part of a suggestion.
final class SuggestionPart {
  /// Creates a part.
  const SuggestionPart(
    this.kind,
    this.start,
    this.length,
    this.text, {
    this.before,
    this.after,
    this.embedType,
  });

  /// Embed type (`image`, `divider`, `table`) when the part is one embed.
  final String? embedType;

  /// Kind.
  final SuggestionPartKind kind;

  /// Start offset.
  final int start;

  /// Length.
  final int length;

  /// Text (embeds as [embedChar]).
  final String text;

  /// Original attributes for format parts.
  final Map<String, dynamic>? before;

  /// Current attributes of the group for format parts.
  final Map<String, dynamic>? after;

  /// This part moved by [offset] characters.
  SuggestionPart shifted(int offset) => offset == 0
      ? this
      : SuggestionPart(
          kind,
          start + offset,
          length,
          text,
          before: before,
          after: after,
          embedType: embedType,
        );

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'kind': switch (kind) {
      SuggestionPartKind.insert => 'insert',
      SuggestionPartKind.delete => 'delete',
      SuggestionPartKind.format => 'format',
      SuggestionPartKind.blockFormat => 'block_format',
    },
    'start': start,
    'length': length,
    'text': text,
    'before': ?before,
  };
}

/// A pending suggestion with its parts.
final class SuggestionInfo {
  /// Creates info.
  const SuggestionInfo({
    required this.id,
    required this.by,
    required this.at,
    required this.parts,
    this.via,
  });

  /// Suggestion id.
  final String id;

  /// Author user UUID.
  final String by;

  /// Earliest timestamp.
  final int at;

  /// `ai` / `mcp`.
  final String? via;

  /// Parts in document order.
  final List<SuggestionPart> parts;

  /// First offset.
  int get start => parts.first.start;

  /// Card summary (08 §2.7), truncated to 120 characters.
  String get summary {
    String q(String s) {
      final t = s
          .replaceAll('\n', ' ')
          .replaceAll(softBreak, ' ')
          .replaceAll(embedChar, '')
          .trim();
      return t.length > 120 ? '${t.substring(0, 119)}…' : t;
    }

    final ins = parts
        .where((p) => p.kind == SuggestionPartKind.insert)
        .toList();
    final del = parts
        .where((p) => p.kind == SuggestionPartKind.delete)
        .toList();
    final insText = ins.map((p) => p.text).join();
    final delText = del.map((p) => p.text).join();
    if (ins.isNotEmpty && del.isNotEmpty) {
      return 'Replace: ‘${q(delText)}’ with ‘${q(insText)}’';
    }
    if (ins.isNotEmpty) {
      if (insText.contains(embedChar) && q(insText).isEmpty) {
        return 'Add ${_embedNoun(ins)}';
      }
      if (q(insText).isEmpty) return 'Insert paragraph break';
      return 'Add: ‘${q(insText)}’';
    }
    if (del.isNotEmpty) {
      if (delText.contains(embedChar) && q(delText).isEmpty) {
        return 'Remove ${_embedNoun(del)}';
      }
      if (q(delText).isEmpty) return 'Join paragraphs';
      return 'Delete: ‘${q(delText)}’';
    }
    final block = parts
        .where((p) => p.kind == SuggestionPartKind.blockFormat)
        .firstOrNull;
    if (block != null) {
      return 'Change ${_blockName(block.before)} to ${_blockName(block.after)}';
    }
    final fmt = parts.firstWhere((p) => p.kind == SuggestionPartKind.format);
    final changed = <String>[];
    final before = fmt.before ?? const {};
    final after = fmt.after ?? const {};
    for (final (k, name) in [
      (WonkyAttr.bold, 'Bold'),
      (WonkyAttr.italic, 'Italic'),
      (WonkyAttr.strike, 'Strikethrough'),
      (WonkyAttr.code, 'Code'),
      (WonkyAttr.link, 'Link'),
    ]) {
      if (before[k] != after[k]) {
        changed.add(
          after.containsKey(k) ? name : 'Remove ${name.toLowerCase()}',
        );
      }
    }
    return 'Format: ${changed.isEmpty ? 'Formatting' : changed.join(', ')}';
  }

  String _embedNoun(List<SuggestionPart> parts) =>
      switch (parts.map((p) => p.embedType).nonNulls.firstOrNull) {
        'divider' => 'horizontal line',
        'table' => 'table',
        _ => 'image',
      };

  static String _blockName(Map<String, dynamic>? attrs) {
    final f = BlockFormat.fromAttributes(attrs);
    return switch (f.type) {
      BlockType.paragraph => 'paragraph',
      BlockType.heading => 'Heading ${f.level}',
      BlockType.quote => 'quote',
      BlockType.code => 'code block',
      BlockType.bullet => 'bulleted list',
      BlockType.ordered => 'numbered list',
      BlockType.task => 'checklist',
    };
  }

  /// JSON form (09 §2.4; the server adds author name, thread uuid, replies).
  Map<String, dynamic> toJson() => {
    'suggestion_id': id,
    'author': {'uuid': by},
    'via': ?via,
    'created_at': at,
    'summary': summary,
    'parts': [for (final p in parts) p.toJson()],
  };
}

/// One suggestion mark on one piece of a document (a text run, an embed or
/// a line end): the input of [SuggestionIndex.fromPieces].
typedef SuggestionPiece = ({
  String id,
  SuggestionMark mark,
  SuggestionPart part,
});

/// Lists pending suggestions of a document.
abstract final class SuggestionIndex {
  /// Suggestions in document order (by first part), optionally filtered by
  /// author.
  static List<SuggestionInfo> list(Delta document, {String? authorUuid}) =>
      fromPieces(pieces(document), authorUuid: authorUuid);

  /// The suggestion marks of [document] in document order. A document made
  /// of whole lines can be split anywhere between lines: the pieces of the
  /// parts (offsets shifted, [SuggestionPart.shifted]) are the pieces of the
  /// whole (the Write editor keeps them per block and rescans only changed
  /// blocks, Write 04 §36).
  static List<SuggestionPiece> pieces(Delta document) {
    final doc = WonkyDocument(document);
    final out = <SuggestionPiece>[];
    for (final line in doc.lines) {
      final pieces = <(int, String, Map<String, dynamic>?, bool, String?)>[
        for (final s in line.segments)
          (
            s.start,
            s.text,
            s.attributes,
            false,
            s.isEmbed ? WonkyEmbed.typeOf(s.data) : null,
          ),
        if (line.hasNewline)
          (line.newlineOffset, '\n', line.attributes, true, null),
      ];
      for (final (start, text, attrs, isNewline, embedType) in pieces) {
        for (final e in Attributes.suggestions(attrs).entries) {
          final m = e.value;
          final kind = switch (m.kind) {
            SuggestionKind.ins => SuggestionPartKind.insert,
            SuggestionKind.del => SuggestionPartKind.delete,
            SuggestionKind.fmt =>
              isNewline
                  ? SuggestionPartKind.blockFormat
                  : SuggestionPartKind.format,
          };
          final group = isNewline
              ? Attributes.block(attrs)
              : Attributes.inline(attrs);
          out.add((
            id: e.key,
            mark: m,
            part: SuggestionPart(
              kind,
              start,
              text.length,
              text,
              before: m.kind == SuggestionKind.fmt ? m.before : null,
              after: m.kind == SuggestionKind.fmt ? group : null,
              embedType: embedType,
            ),
          ));
        }
      }
    }
    return out;
  }

  /// Groups [pieces] (in document order) into suggestions: adjacent parts
  /// of the same kind merge; the earliest `at` wins.
  static List<SuggestionInfo> fromPieces(
    Iterable<SuggestionPiece> pieces, {
    String? authorUuid,
  }) {
    final byId =
        <
          String,
          ({String by, int at, String? via, List<SuggestionPart> parts})
        >{};
    for (final (:id, mark: m, :part) in pieces) {
      final e = byId[id];
      if (e == null) {
        byId[id] = (by: m.by, at: m.at, via: m.via, parts: [part]);
        continue;
      }
      final last = e.parts.last;
      if (last.kind == part.kind && last.start + last.length == part.start) {
        e.parts[e.parts.length - 1] = SuggestionPart(
          part.kind,
          last.start,
          last.length + part.length,
          last.text + part.text,
          before: last.before,
          after: last.after,
          embedType: last.embedType ?? part.embedType,
        );
      } else {
        e.parts.add(part);
      }
      if (m.at < e.at) {
        byId[id] = (by: e.by, at: m.at, via: e.via ?? m.via, parts: e.parts);
      }
    }
    final result = [
      for (final e in byId.entries)
        if (authorUuid == null || e.value.by == authorUuid)
          SuggestionInfo(
            id: e.key,
            by: e.value.by,
            at: e.value.at,
            via: e.value.via,
            parts: e.value.parts,
          ),
    ]..sort((a, b) => a.start.compareTo(b.start));
    return result;
  }
}

/// How a suggestion was resolved (08 §2.9).
enum SuggestionDecision {
  /// Accepted by an editor.
  accepted,

  /// Rejected by someone other than the author.
  rejected,

  /// Rejected by its author.
  withdrawn,

  /// Removed together with surrounding text.
  superseded,
}

/// Infers suggestion decisions from an applied op and its inverse.
abstract final class SuggestionDecisions {
  /// Classifies how [op] (by [actorUuid], with [inverse] against the doc
  /// before) removed suggestion [suggestionId] (whose count went to 0).
  static SuggestionDecision infer({
    required Delta op,
    required Delta inverse,
    required String suggestionId,
    required String actorUuid,
  }) {
    final key = WonkyAttr.suggestionKey(suggestionId);
    // Deleted content is in the inverse's inserts; removed attributes are in
    // the inverse's retains (with the old value).
    var insDeleted = false,
        insKept = false,
        delDeleted = false,
        delKept = false;
    var fmtReverted = false, fmtAccepted = false;
    var deletedOutside = false;
    String? author;
    var inRegion = false;
    var regionX = false;
    var regionOther = false;
    void closeRegion() {
      if (inRegion && regionX && regionOther) deletedOutside = true;
      inRegion = false;
      regionX = false;
      regionOther = false;
    }

    // Retain attrs of the op in post-doc coordinates, to compare fmt results.
    for (final inv in inverse.operations) {
      if (inv.isInsert) {
        inRegion = true;
        final m = SuggestionMark.tryParse(inv.attributes?[key]);
        if (m != null) {
          regionX = true;
          author ??= m.by;
          switch (m.kind) {
            case SuggestionKind.ins:
              insDeleted = true;
            case SuggestionKind.del:
              delDeleted = true;
            case SuggestionKind.fmt:
              insDeleted = true;
          }
        } else {
          regionOther = true;
        }
        continue;
      }
      closeRegion();
      if (inv.isRetain) {
        final m = SuggestionMark.tryParse(inv.attributes?[key]);
        if (m == null) continue;
        author ??= m.by;
        switch (m.kind) {
          case SuggestionKind.ins:
            insKept = true;
          case SuggestionKind.del:
            delKept = true;
          case SuggestionKind.fmt:
            // The inverse restores the attributes the op changed: if the op
            // set the group back to `before`, the inverse sets non-before
            // values (the suggested ones).
            final restored = Attributes.withoutOverlays(inv.attributes);
            final before = m.before ?? const <String, dynamic>{};
            final reverted =
                restored.isNotEmpty &&
                restored.entries.every((e) => before[e.key] != e.value);
            if (reverted) {
              fmtReverted = true;
            } else {
              fmtAccepted = true;
            }
        }
      }
    }
    closeRegion();
    final byAuthor = author == actorUuid;
    if (deletedOutside) return SuggestionDecision.superseded;
    if (insKept || delDeleted || fmtAccepted) {
      if (!(insDeleted || delKept || fmtReverted)) {
        return SuggestionDecision.accepted;
      }
    }
    if (insDeleted || delKept || fmtReverted) {
      return byAuthor
          ? SuggestionDecision.withdrawn
          : SuggestionDecision.rejected;
    }
    return SuggestionDecision.accepted;
  }
}
