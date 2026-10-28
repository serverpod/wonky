/// `WonkyDeltaNormalizer` (specs/wonky_write/02-document-model.md §1.4, §4.3).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'attributes.dart';
import 'boxes.dart';
import 'cells.dart';
import 'delta_utils.dart';
import 'document.dart';
import 'embeds.dart';
import 'links.dart';
import 'validator.dart';

/// A single fix applied by the normalizer (diagnostics / import warnings).
enum NormalizationFix {
  /// Non-canonical op structure merged (no content change).
  mergedOps,

  /// Missing final `"\n"` appended.
  appendedTrailingNewline,

  /// Disallowed characters removed or replaced.
  replacedCharacters,

  /// Unknown or invalid attributes removed.
  removedAttributes,

  /// Conflicting block attributes resolved.
  resolvedBlockConflict,

  /// List indent clamped.
  clampedIndent,

  /// Inline `code` exclusions applied.
  codeExclusion,

  /// Embed moved onto its own line.
  movedEmbed,

  /// Invalid embed removed.
  removedEmbed,

  /// Duplicate embed id resolved (embed identity rule).
  removedDuplicateEmbed,

  /// Embed payload canonicalized.
  canonicalizedEmbed,

  /// Links canonicalized or removed.
  normalizedLink,

  /// Comment anchors of unknown threads removed.
  removedOrphanComment,

  /// Suggestion timestamps stamped with server time.
  stampedSuggestion,

  /// Chip or link style exclusions applied (Write 11 §2.4 rule 10).
  styledTextExclusion,

  /// Invalid container frames removed or canonicalized (Write 11 §2.4
  /// rule 11).
  normalizedBox,
}

/// Result of [WonkyDeltaNormalizer.normalize].
final class NormalizeResult {
  /// Creates a result.
  const NormalizeResult({
    required this.document,
    required this.fixup,
    required this.fixes,
  });

  /// The normalized, canonical document.
  final Delta document;

  /// The change that turns the input document into [document]
  /// (`input.compose(fixup) == document`); empty when only the op structure
  /// was canonicalized.
  final Delta fixup;

  /// Fixes that were applied.
  final Set<NormalizationFix> fixes;

  /// Whether the content changed (i.e. [fixup] is not empty).
  bool get changed => fixup.isNotEmpty;
}

/// Result of [WonkyDeltaNormalizer.normalizeChange].
final class NormalizeChangeResult {
  /// Creates a result.
  const NormalizeChangeResult({
    required this.document,
    required this.fixup,
    required this.change,
    required this.fixes,
  });

  /// The normalized document after the change.
  final Delta document;

  /// Fix-up applied after the incoming change.
  final Delta fixup;

  /// The incoming change composed with [fixup] (`A''` in the sync spec):
  /// `docBefore.compose(change) == document`.
  final Delta change;

  /// Fixes that were applied.
  final Set<NormalizationFix> fixes;
}

/// Normalizes document deltas into valid, canonical Wonky Delta Schema v1.
///
/// Every output validates with [WonkyDeltaValidator] (except for the length
/// limit, which cannot be normalized) and `normalize` is idempotent.
final class WonkyDeltaNormalizer {
  /// Creates a normalizer.
  ///
  /// [isKnownCommentThread], when given, removes `cmt_*` anchors of threads
  /// that no longer exist (weekly server job). [tableCellNormalizer]
  /// canonicalizes table cell Markdown (default: whitespace/character
  /// cleanup only).
  const WonkyDeltaNormalizer({
    this.isKnownCommentThread,
    this.tableCellNormalizer,
  });

  /// Comment thread filter (`null` keeps all anchors).
  final bool Function(String threadUuid)? isKnownCommentThread;

  /// Table cell canonicalizer applied after the basic cleanup.
  final String Function(String cell)? tableCellNormalizer;

  /// Spaces replacing a tab outside code blocks.
  static const tabReplacement = '    ';

  /// Normalizes [document] (inserts only; other ops throw [ArgumentError]).
  ///
  /// Duplicate embed ids keep the first occurrence.
  NormalizeResult normalize(Delta document) =>
      _normalize(document, preferredEmbedOffsets: const {}, stampAt: null);

  /// Applies [change] to [docBefore] and normalizes the result.
  ///
  /// Implements the embed identity rule (02 §4.3): when the change inserts an
  /// embed whose id already exists in the document, the pre-existing embed is
  /// deleted (last writer wins). When [suggestionTimestamp] is given, `at` of
  /// every `sug_*` value introduced by the change is set to it (server time,
  /// 08 §2.10).
  NormalizeChangeResult normalizeChange(
    Delta docBefore,
    Delta change, {
    int? suggestionTimestamp,
  }) {
    final after = docBefore.compose(change);
    final preferred = <int>{};
    final introduced = <int>{};
    var newOffset = 0;
    for (final op in change.operations) {
      if (op.isInsert) {
        if (op.data is! String) preferred.add(newOffset);
        if (suggestionTimestamp != null &&
            (op.attributes?.keys.any(WonkyAttr.isSuggestion) ?? false)) {
          for (var i = 0; i < op.length!; i++) {
            introduced.add(newOffset + i);
          }
        }
        newOffset += op.length!;
      } else if (op.isRetain) {
        if (suggestionTimestamp != null &&
            (op.attributes?.entries.any(
                  (e) => WonkyAttr.isSuggestion(e.key) && e.value != null,
                ) ??
                false)) {
          for (var i = 0; i < op.length!; i++) {
            introduced.add(newOffset + i);
          }
        }
        newOffset += op.length!;
      }
    }
    final r = _normalize(
      after,
      preferredEmbedOffsets: preferred,
      stampAt: suggestionTimestamp == null
          ? null
          : (offsets: introduced, at: suggestionTimestamp),
    );
    return NormalizeChangeResult(
      document: r.document,
      fixup: r.fixup,
      change: DeltaUtils.canonical(change.compose(r.fixup)),
      fixes: r.fixes,
    );
  }

  /// `normalizeChange(docBefore, change).change` for a normalized
  /// [docBefore] (a server document), computed from the lines the change
  /// touches instead of the whole document (the Write client predicts the
  /// committed form of each acknowledged op, Write 03 §3; CQ-49).
  ///
  /// Normalization is per line, given the list indent of the line before
  /// and whether the lines are the document's last; the only rule across
  /// lines is embed identity, so a change that inserts an embed is
  /// normalized against the whole document.
  Delta normalizedChange(Delta docBefore, Delta change) {
    Delta whole() => normalizeChange(docBefore, change).change;
    // The base range the change touches.
    var offset = 0;
    int? lo;
    var hi = 0;
    for (final op in change.operations) {
      final length = op.length!;
      if (op.isInsert) {
        if (op.data is! String) return whole();
        lo ??= offset;
        if (offset > hi) hi = offset;
        continue;
      }
      final attributes = op.attributes;
      if (op.isRetain && (attributes == null || attributes.isEmpty)) {
        offset += length;
        continue;
      }
      lo ??= offset;
      offset += length;
      if (offset > hi) hi = offset;
    }
    if (lo == null) return whole();

    // The lines from the one containing `lo` to the one containing `hi`
    // (a deleted or reformatted line end touches the next line too), and
    // the list indent of the line before them.
    var position = 0;
    var start = 0;
    int? end;
    Map<String, dynamic>? before;
    Map<String, dynamic>? last;
    for (final op in docBefore.operations) {
      if (!op.isInsert) return whole();
      final data = op.data;
      final length = op.length!;
      if (data is String) {
        var i = data.indexOf('\n');
        while (i >= 0) {
          final at = position + i;
          if (at < lo) {
            start = at + 1;
            before = op.attributes;
          } else if (at >= hi) {
            end = at + 1;
            last = op.attributes;
            break;
          }
          i = data.indexOf('\n', i + 1);
        }
      }
      if (end != null) break;
      position += length;
    }
    final docLength = DeltaUtils.documentLength(docBefore);
    end ??= docLength;
    if (end <= start) return whole();
    int? listIndent(Map<String, dynamic>? attributes) {
      final format = BlockFormat.fromAttributes(attributes);
      return format.isList ? format.indent : null;
    }

    final window = _Window(
      startsDocument: start == 0,
      endsDocument: end == docLength,
      prevListIndent: listIndent(before),
      prevListQuoted: BlockFormat.fromAttributes(before).quoted,
      prevListBox: Boxes.of(before),
    );

    // The change within the window.
    final local = Delta();
    var skip = start;
    var taken = 0;
    for (final op in change.operations) {
      if (skip > 0) {
        // Plain retains before `lo`.
        final length = op.length!;
        if (length <= skip) {
          skip -= length;
          continue;
        }
        local.retain(length - skip, op.attributes);
        taken += length - skip;
        skip = 0;
        continue;
      }
      if (!op.isInsert && taken >= end - start) break;
      local.push(op);
      if (!op.isInsert) taken += op.length!;
    }
    local.trim();
    final after = docBefore.slice(start, end).compose(local);
    if (after.isEmpty) return whole();
    final r = _normalize(
      after,
      preferredEmbedOffsets: const {},
      stampAt: null,
      window: window,
    );
    // A list indent clamped differently from here on (the change removed or
    // re-indented a list item) cascades to the next lines.
    // So does a change of the last line's list kind or containers.
    final lastOut = r.document.operations.last.attributes;
    if (!window.endsDocument &&
        (listIndent(lastOut) != listIndent(last) ||
            BlockFormat.fromAttributes(lastOut).quoted !=
                BlockFormat.fromAttributes(last).quoted ||
            !Boxes.samePath(Boxes.of(lastOut), Boxes.of(last)))) {
      return whole();
    }
    final fixup = Delta()..retain(start);
    for (final op in r.fixup.operations) {
      fixup.push(op);
    }
    return DeltaUtils.canonical(change.compose(fixup));
  }

  NormalizeResult _normalize(
    Delta input, {
    required Set<int> preferredEmbedOffsets,
    required ({Set<int> offsets, int at})? stampAt,
    _Window window = const _Window.whole(),
  }) {
    final doc = WonkyDocument(input);
    final b = _Builder()..newlines = window.startsDocument ? 0 : 1;
    final fixes = <NormalizationFix>{};

    // Pre-pass: embed identity (which duplicate occurrences to remove).
    final occurrences = <String, List<int>>{};
    for (final line in doc.lines) {
      for (final s in line.segments) {
        if (!s.isEmbed) continue;
        final id = WonkyEmbed.idOf(s.data);
        if (id != null && WonkyEmbed.tryParse(s.data) != null) {
          (occurrences[id] ??= []).add(s.start);
        }
      }
    }
    final removeEmbedsAt = <int>{};
    for (final list in occurrences.values) {
      if (list.length < 2) continue;
      final preferred = list.where(preferredEmbedOffsets.contains);
      final keep = preferred.isNotEmpty ? preferred.last : list.first;
      removeEmbedsAt.addAll(list.where((o) => o != keep));
    }
    if (removeEmbedsAt.isNotEmpty) {
      fixes.add(NormalizationFix.removedDuplicateEmbed);
    }

    int? prevListIndent = window.prevListIndent;
    var prevListQuoted = window.prevListQuoted;
    var prevListBox = window.prevListBox;
    for (final line in doc.lines) {
      final isLast = window.endsDocument && line.index == doc.lines.length - 1;
      final blockIn = line.attributes;
      final blockOut = _normalizeBlockAttributes(
        blockIn,
        fixes,
        line.newlineOffset,
        stampAt,
      );
      final isCode = blockOut.containsKey(WonkyAttr.codeBlock);
      // A table cell or grid item is one line (Write 12 §1.4).
      final isCell =
          blockOut.containsKey(WonkyAttr.cell) ||
          blockOut.containsKey(WonkyAttr.grid);

      // Group segments into text runs and embeds (after embed validation).
      final groups = <_Group>[];
      for (final s in line.segments) {
        if (s.isEmbed) {
          final embed = WonkyEmbed.tryParse(s.data);
          if (embed == null) {
            fixes.add(NormalizationFix.removedEmbed);
            groups.add(_Group.removed(s));
            continue;
          }
          if (removeEmbedsAt.contains(s.start)) {
            groups.add(_Group.removed(s));
            continue;
          }
          final canonical = _canonicalEmbed(embed);
          if (canonical == null) {
            fixes.add(NormalizationFix.removedEmbed);
            groups.add(_Group.removed(s));
            continue;
          }
          groups.add(_Group.embed(s, canonical));
        } else {
          if (groups.isNotEmpty && groups.last.isText) {
            groups.last.segments.add(s);
          } else {
            groups.add(_Group.text(s));
          }
        }
      }
      final live = groups.where((g) => !g.isRemoved).toList();
      final hasEmbed = live.any((g) => g.isEmbed);
      if (hasEmbed && live.length > 1) fixes.add(NormalizationFix.movedEmbed);

      // Indent clamping uses the output state at each emitted line end.
      Map<String, dynamic> clamped() => _clampIndent(
        blockOut,
        prevListIndent,
        prevListQuoted,
        prevListBox,
        fixes,
      );
      void track(Map<String, dynamic> attrs) {
        final f = BlockFormat.fromAttributes(attrs);
        prevListIndent = f.isList ? f.indent : null;
        prevListQuoted = f.quoted;
        prevListBox = Boxes.of(attrs);
      }

      // The attributes an embed's line end keeps: overlays and the box.
      Map<String, dynamic> embedLineAttrs(Map<String, dynamic> overlaysOf) => {
        ...Attributes.overlays(overlaysOf),
        if (blockOut.containsKey(WonkyAttr.box))
          WonkyAttr.box: blockOut[WonkyAttr.box],
      };

      for (var gi = 0; gi < groups.length; gi++) {
        final g = groups[gi];
        if (g.isRemoved) {
          b.delete(1);
          continue;
        }
        final liveIndex = live.indexOf(g);
        final isFinal = liveIndex == live.length - 1;
        if (g.isEmbed) {
          final s = g.segments.single;
          final attrsOut = _normalizeOverlays(
            s.attributes,
            fixes,
            block: false,
            at: s.start,
            stampAt: stampAt,
          );
          if (!_deepEquals(g.canonical!.toInsert(), s.data)) {
            fixes.add(NormalizationFix.canonicalizedEmbed);
            b.delete(1);
            b.insert(g.canonical!.toInsert(), attrsOut);
          } else {
            b.keep(s.data, s.attributes, attrsOut);
          }
          if (!isFinal) {
            b.insert('\n', Attributes.orNull(embedLineAttrs(const {})));
          }
          prevListIndent = null;
        } else {
          for (final s in g.segments) {
            _normalizeText(
              s,
              b,
              fixes,
              isCode: isCode,
              isCell: isCell,
              codeLineAttrs: blockOut,
              stampAt: stampAt,
            );
          }
          if (!isFinal) {
            // Split before a following embed: this text keeps the block type.
            final attrs = Attributes.block(clamped());
            b.insert('\n', Attributes.orNull(attrs));
            track(attrs);
          }
        }
      }

      // The line end.
      if (live.isEmpty &&
          line.segments.isNotEmpty &&
          (!isLast || b.newlines > 0)) {
        // Only removed embeds: drop the now-empty line entirely.
        if (line.hasNewline) b.delete(1);
        continue;
      }
      final endsWithEmbed = live.isNotEmpty && live.last.isEmbed;
      var finalAttrs = endsWithEmbed ? embedLineAttrs(blockOut) : clamped();
      if (endsWithEmbed &&
          Attributes.block(blockIn).keys.any((k) => k != WonkyAttr.box)) {
        fixes.add(NormalizationFix.movedEmbed);
      }
      if (live.isEmpty && line.segments.isNotEmpty) {
        finalAttrs = Attributes.overlays(blockOut);
      }
      if (line.hasNewline) {
        b.keep('\n', line.attributes, finalAttrs);
      } else {
        fixes.add(NormalizationFix.appendedTrailingNewline);
        b.insert('\n', Attributes.orNull(finalAttrs));
      }
      track(finalAttrs);
    }
    if (doc.lines.isEmpty) {
      fixes.add(NormalizationFix.appendedTrailingNewline);
      b.insert('\n', null);
    }

    final output = DeltaUtils.canonical(Delta.fromOperations(b.out));
    if (output.operations.length != input.operations.length ||
        output != input) {
      if (b.change.isEmpty) fixes.add(NormalizationFix.mergedOps);
    }
    return NormalizeResult(
      document: output,
      fixup: DeltaUtils.canonical(b.change),
      fixes: fixes,
    );
  }

  // ---------------------------------------------------------------------
  // Text

  void _normalizeText(
    LineSegment s,
    _Builder b,
    Set<NormalizationFix> fixes, {
    required bool isCode,
    bool isCell = false,
    required Map<String, dynamic> codeLineAttrs,
    required ({Set<int> offsets, int at})? stampAt,
  }) {
    final text = s.data as String;
    var attrsOut = _normalizeInline(
      s.attributes,
      fixes,
      s.start,
      s.length,
      stampAt,
    );
    if (isCode && attrsOut != null && attrsOut.keys.any(WonkyAttr.isInline)) {
      // Code block text carries no inline formatting (not expressible in
      // Markdown); overlays stay.
      fixes.add(NormalizationFix.removedAttributes);
      attrsOut = Attributes.orNull(Attributes.overlays(attrsOut));
    }
    // Soft breaks never carry `code` (it would split the code span).
    final softBreakAttrs =
        attrsOut == null || !attrsOut.containsKey(WonkyAttr.code)
        ? attrsOut
        : (Map<String, dynamic>.from(attrsOut)..remove(WonkyAttr.code));
    var runStart = 0;
    void flush(int end) {
      if (end > runStart) {
        b.keep(text.substring(runStart, end), s.attributes, attrsOut);
      }
      runStart = end;
    }

    for (var i = 0; i < text.length; i++) {
      final u = text.codeUnitAt(i);
      // Surrogates.
      if (u >= 0xD800 && u <= 0xDBFF) {
        if (i + 1 < text.length) {
          final n = text.codeUnitAt(i + 1);
          if (n >= 0xDC00 && n <= 0xDFFF) {
            i++;
            continue;
          }
        }
        flush(i);
        b.delete(1);
        runStart = i + 1;
        fixes.add(NormalizationFix.replacedCharacters);
        continue;
      }
      if (u >= 0xDC00 && u <= 0xDFFF) {
        flush(i);
        b.delete(1);
        runStart = i + 1;
        fixes.add(NormalizationFix.replacedCharacters);
        continue;
      }
      final isSoft = u == 0x2028 || u == 0x2029;
      if (u == 0x09 && !isCode) {
        flush(i);
        b.delete(1);
        b.insert(tabReplacement, attrsOut);
        runStart = i + 1;
        fixes.add(NormalizationFix.replacedCharacters);
      } else if (isSoft && isCode) {
        flush(i);
        b.delete(1);
        final nlAttrs = <String, dynamic>{
          ...Attributes.block(codeLineAttrs),
          ...Attributes.overlays(attrsOut),
        };
        b.insert('\n', Attributes.orNull(nlAttrs));
        runStart = i + 1;
        fixes.add(NormalizationFix.replacedCharacters);
      } else if (isSoft && isCell) {
        flush(i);
        b.delete(1);
        b.insert(' ', attrsOut);
        runStart = i + 1;
        fixes.add(NormalizationFix.replacedCharacters);
      } else if (u == 0x2029) {
        flush(i);
        b.delete(1);
        b.insert(softBreak, softBreakAttrs);
        runStart = i + 1;
        fixes.add(NormalizationFix.replacedCharacters);
      } else if (u == 0x2028 && softBreakAttrs != attrsOut) {
        flush(i);
        b.keep(softBreak, s.attributes, softBreakAttrs);
        runStart = i + 1;
        fixes.add(NormalizationFix.codeExclusion);
      } else if (u != 0x09 && TextRules.isForbiddenUnit(u)) {
        flush(i);
        b.delete(1);
        runStart = i + 1;
        fixes.add(NormalizationFix.replacedCharacters);
      }
    }
    flush(text.length);
  }

  // ---------------------------------------------------------------------
  // Attributes

  Map<String, dynamic>? _normalizeInline(
    Map<String, dynamic>? attrs,
    Set<NormalizationFix> fixes,
    int offset,
    int length,
    ({Set<int> offsets, int at})? stampAt,
  ) {
    if (attrs == null || attrs.isEmpty) return null;
    final out = <String, dynamic>{};
    for (final e in attrs.entries) {
      final key = e.key;
      final v = e.value;
      if (WonkyAttr.isOverlay(key)) continue;
      switch (key) {
        case WonkyAttr.bold ||
            WonkyAttr.italic ||
            WonkyAttr.strike ||
            WonkyAttr.code:
          if (v == true) {
            out[key] = true;
          } else {
            fixes.add(NormalizationFix.removedAttributes);
          }
        case WonkyAttr.link:
          final normalized = v is String ? LinkPolicy.normalizeLink(v) : null;
          if (normalized == null) {
            fixes.add(NormalizationFix.normalizedLink);
          } else {
            if (normalized != v) fixes.add(NormalizationFix.normalizedLink);
            out[key] = normalized;
          }
        case WonkyAttr.mention:
          if (v is String && v.isNotEmpty) {
            out[key] = v;
          } else {
            fixes.add(NormalizationFix.removedAttributes);
          }
        case WonkyAttr.linkStyle:
          if (WonkyAttr.linkStyles.contains(v)) {
            out[key] = v;
          } else {
            fixes.add(NormalizationFix.removedAttributes);
          }
        case WonkyAttr.chip:
          if (v == true ||
              (v is String && WonkyDeltaValidator.chipIcon.hasMatch(v))) {
            out[key] = v;
          } else {
            fixes.add(NormalizationFix.removedAttributes);
          }
        default:
          fixes.add(NormalizationFix.removedAttributes);
      }
    }
    // A chip and a styled link are plain-text labels (Write 11 §2.1).
    if (out.containsKey(WonkyAttr.chip)) {
      for (final k in WonkyAttr.chipExcludedKeys) {
        if (out.remove(k) != null) {
          fixes.add(NormalizationFix.styledTextExclusion);
        }
      }
    } else if (out.containsKey(WonkyAttr.linkStyle)) {
      if (!out.containsKey(WonkyAttr.link)) {
        out.remove(WonkyAttr.linkStyle);
        fixes.add(NormalizationFix.styledTextExclusion);
      } else {
        for (final k in WonkyAttr.linkStyleExcludedKeys) {
          if (out.remove(k) != null) {
            fixes.add(NormalizationFix.styledTextExclusion);
          }
        }
      }
    }
    if (out.containsKey(WonkyAttr.code)) {
      for (final k in WonkyAttr.codeExcludedKeys) {
        if (out.remove(k) != null) fixes.add(NormalizationFix.codeExclusion);
      }
    }
    if (out.containsKey(WonkyAttr.mention)) {
      final link = out[WonkyAttr.link];
      if (link is! String || !LinkPolicy.isMailto(link)) {
        out.remove(WonkyAttr.mention);
        fixes.add(NormalizationFix.removedAttributes);
      }
    }
    final overlays = _normalizeOverlays(
      attrs,
      fixes,
      block: false,
      at: offset,
      length: length,
      stampAt: stampAt,
    );
    if (overlays != null) out.addAll(overlays);
    return out.isEmpty ? null : out;
  }

  Map<String, dynamic> _normalizeBlockAttributes(
    Map<String, dynamic> attrs,
    Set<NormalizationFix> fixes,
    int offset,
    ({Set<int> offsets, int at})? stampAt,
  ) {
    final out = <String, dynamic>{};
    String? type;
    for (final key in WonkyAttr.blockTypeKeys) {
      if (!attrs.containsKey(key)) continue;
      final v = attrs[key];
      Object? value;
      switch (key) {
        case WonkyAttr.codeBlock:
          if (v is String) {
            value = _sanitizeLanguage(v);
            if (value != v) fixes.add(NormalizationFix.removedAttributes);
          } else if (v == true) {
            value = '';
          }
        case WonkyAttr.header:
          final level = v is int
              ? v
              : (v is num && v == v.roundToDouble() ? v.toInt() : null);
          if (level != null && level >= 1 && level <= 6) value = level;
        case WonkyAttr.list:
          if (ListKind.tryParse(v) != null) value = v;
        case WonkyAttr.blockquote:
          if (v == true) value = true;
      }
      if (value == null) {
        fixes.add(NormalizationFix.removedAttributes);
        continue;
      }
      if (type == WonkyAttr.list && key == WonkyAttr.blockquote) {
        // A list item inside a quote (Write 02 §1.2).
        out[key] = value;
        continue;
      }
      if (type != null) {
        fixes.add(NormalizationFix.resolvedBlockConflict);
        continue;
      }
      type = key;
      out[key] = value;
    }
    if (attrs.containsKey(WonkyAttr.step)) {
      final v = attrs[WonkyAttr.step];
      final level = out[WonkyAttr.header];
      if (v is int &&
          v >= 0 &&
          v <= WonkyAttr.maxStep &&
          (level == 2 || level == 3)) {
        out[WonkyAttr.step] = v;
      } else {
        fixes.add(NormalizationFix.removedAttributes);
      }
    }
    if (attrs.containsKey(WonkyAttr.box)) {
      final box = _normalizeBox(attrs[WonkyAttr.box]);
      if (box == null) {
        fixes.add(NormalizationFix.normalizedBox);
      } else {
        if (!_deepEquals(box, attrs[WonkyAttr.box])) {
          fixes.add(NormalizationFix.normalizedBox);
        }
        out[WonkyAttr.box] = box;
      }
    }
    if (attrs.containsKey(WonkyAttr.indent)) {
      final v = attrs[WonkyAttr.indent];
      final n = v is int ? v : (v is num ? v.round() : null);
      if (type == WonkyAttr.list && n != null && n >= 1) {
        final clamped = n > WonkyAttr.maxIndent ? WonkyAttr.maxIndent : n;
        if (clamped != v) fixes.add(NormalizationFix.clampedIndent);
        out[WonkyAttr.indent] = clamped;
      } else {
        fixes.add(NormalizationFix.removedAttributes);
      }
    }
    _normalizeCell(attrs, out, fixes);
    for (final key in attrs.keys) {
      if (!WonkyAttr.isBlock(key) && !WonkyAttr.isOverlay(key)) {
        fixes.add(NormalizationFix.removedAttributes);
      }
    }
    final overlays = _normalizeOverlays(
      attrs,
      fixes,
      block: true,
      at: offset,
      stampAt: stampAt,
    );
    if (overlays != null) out.addAll(overlays);
    return out;
  }

  /// A table cell or grid item line (Write 12 §1.4): its canonical `cell`
  /// or `grid` value, and no other block attribute than `box`.
  static void _normalizeCell(
    Map<String, dynamic> attrs,
    Map<String, dynamic> out,
    Set<NormalizationFix> fixes,
  ) {
    final hasCell = attrs.containsKey(WonkyAttr.cell);
    final hasGrid = attrs.containsKey(WonkyAttr.grid);
    if (!hasCell && !hasGrid) return;
    final cell = hasCell ? CellAttr.tryParse(attrs[WonkyAttr.cell]) : null;
    final grid = cell == null && hasGrid
        ? GridItemAttr.tryParse(attrs[WonkyAttr.grid])
        : null;
    final value = cell?.toJson() ?? grid?.toJson();
    if (value == null) {
      fixes.add(NormalizationFix.removedAttributes);
      return;
    }
    for (final key in [...out.keys]) {
      if (key != WonkyAttr.box && WonkyAttr.isBlock(key)) {
        out.remove(key);
        fixes.add(NormalizationFix.removedAttributes);
      }
    }
    final key = cell != null ? WonkyAttr.cell : WonkyAttr.grid;
    out[key] = value;
    if (!_deepEquals(value, attrs[key]) || (hasCell && hasGrid)) {
      fixes.add(NormalizationFix.removedAttributes);
    }
  }

  /// The canonical `box` value of [value]: valid frames only (Write 11
  /// §2.4 rule 11), distinct ids, at most [BoxFrame.maxDepth] (the
  /// outermost), canonical titles; `null` when none is left.
  static List<Map<String, dynamic>>? _normalizeBox(Object? value) {
    if (value is! List) return null;
    final frames = <BoxFrame>[];
    final ids = <String>{};
    for (final v in value) {
      final f = BoxFrame.tryParse(v);
      if (f == null || !ids.add(f.id)) continue;
      frames.add(
        f.title == null
            ? f
            : (BoxFrame.canonicalTitle(f.title) == null
                  ? f.copyWith(clearTitle: true)
                  : f.copyWith(title: BoxFrame.canonicalTitle(f.title))),
      );
      if (frames.length == BoxFrame.maxDepth) break;
    }
    return Boxes.toValue(frames);
  }

  /// Clamps a list line's indent to one deeper than the previous list line
  /// of the same run; a quoted and an unquoted list, and lists in different
  /// containers, are two runs.
  Map<String, dynamic> _clampIndent(
    Map<String, dynamic> block,
    int? prevListIndent,
    bool prevListQuoted,
    List<BoxFrame> prevListBox,
    Set<NormalizationFix> fixes,
  ) {
    if (!block.containsKey(WonkyAttr.list)) return block;
    final indent = (block[WonkyAttr.indent] as int?) ?? 0;
    final quoted = block[WonkyAttr.blockquote] == true;
    final maxAllowed =
        prevListIndent == null ||
            prevListQuoted != quoted ||
            !Boxes.samePath(prevListBox, Boxes.of(block))
        ? 0
        : prevListIndent + 1;
    if (indent <= maxAllowed) return block;
    fixes.add(NormalizationFix.clampedIndent);
    final out = Map<String, dynamic>.from(block);
    if (maxAllowed == 0) {
      out.remove(WonkyAttr.indent);
    } else {
      out[WonkyAttr.indent] = maxAllowed;
    }
    return out;
  }

  Map<String, dynamic>? _normalizeOverlays(
    Map<String, dynamic>? attrs,
    Set<NormalizationFix> fixes, {
    required bool block,
    required int at,
    int length = 1,
    required ({Set<int> offsets, int at})? stampAt,
  }) {
    bool introduced() {
      if (stampAt == null) return false;
      for (var i = at; i < at + length; i++) {
        if (stampAt.offsets.contains(i)) return true;
      }
      return false;
    }

    if (attrs == null || attrs.isEmpty) return null;
    final out = <String, dynamic>{};
    for (final e in attrs.entries) {
      final key = e.key;
      if (WonkyAttr.isComment(key)) {
        if (e.value != true) {
          fixes.add(NormalizationFix.removedAttributes);
          continue;
        }
        final known = isKnownCommentThread;
        if (known != null && !known(WonkyAttr.commentThreadId(key)!)) {
          fixes.add(NormalizationFix.removedOrphanComment);
          continue;
        }
        out[key] = true;
      } else if (WonkyAttr.isSuggestion(key)) {
        var mark = SuggestionMark.tryParse(e.value);
        if (mark == null) {
          fixes.add(NormalizationFix.removedAttributes);
          continue;
        }
        if (mark.before != null) {
          final allowed = block ? WonkyAttr.blockKeys : WonkyAttr.inlineKeys;
          final before = {
            for (final b in mark.before!.entries)
              if (allowed.contains(b.key) && b.value != null) b.key: b.value,
          };
          if (before.length != mark.before!.length) {
            fixes.add(NormalizationFix.removedAttributes);
            mark = SuggestionMark(
              kind: mark.kind,
              by: mark.by,
              at: mark.at,
              before: before,
              via: mark.via,
            );
          }
        }
        if (stampAt != null && mark.at != stampAt.at && introduced()) {
          fixes.add(NormalizationFix.stampedSuggestion);
          mark = mark.copyWith(at: stampAt.at);
        }
        out[key] = mark.toJson();
      }
    }
    return out.isEmpty ? null : out;
  }

  static String _sanitizeLanguage(String v) {
    final cleaned = v.replaceAll(RegExp(r'[^A-Za-z0-9_+#.\-]'), '');
    return cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
  }

  // ---------------------------------------------------------------------
  // Embeds

  WonkyEmbed? _canonicalEmbed(WonkyEmbed embed) {
    switch (embed) {
      case ImageEmbed():
        final src = LinkPolicy.normalizeImageSource(embed.src);
        if (src == null) return null;
        final title = embed.title == null ? null : _singleLine(embed.title!);
        return ImageEmbed(
          id: embed.id,
          src: src,
          alt: _singleLine(embed.alt),
          title: (title == null || title.isEmpty) ? null : title,
        );
      case DividerEmbed():
        return embed;
      case YouTubeEmbed(:final title):
        final canonical = YouTubeEmbed.canonicalTitle(title);
        return canonical == title
            ? embed
            : embed.copyWith(title: canonical, clearTitle: canonical == null);
      case GridEmbed():
        final normalizeCell = tableCellNormalizer;
        final items = [
          for (final c in embed.items.take(GridEmbed.maxItems))
            normalizeCell == null
                ? _singleLine(c)
                : normalizeCell(_singleLine(c)),
        ];
        return GridEmbed(
          id: embed.id,
          columns: GridEmbed.canonicalColumns(embed.columns),
          bullets: embed.bullets,
          items: items.isEmpty ? const [''] : items,
        );
      case TableEmbed():
        final padded = embed.padded();
        final normalizeCell = tableCellNormalizer;
        return TableEmbed(
          id: padded.id,
          align: padded.align,
          rows: [
            for (final r in padded.rows)
              [
                for (final c in r)
                  normalizeCell == null
                      ? _singleLine(c)
                      : normalizeCell(_singleLine(c)),
              ],
          ],
        );
    }
  }

  static String _singleLine(String s) {
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final u = s.codeUnitAt(i);
      if (u == 0x0A || u == 0x0D || u == 0x09 || u == 0x2028 || u == 0x2029) {
        b.write(' ');
      } else if (u >= 0xD800 && u <= 0xDBFF) {
        if (i + 1 < s.length) {
          final n = s.codeUnitAt(i + 1);
          if (n >= 0xDC00 && n <= 0xDFFF) {
            b.writeCharCode(u);
            b.writeCharCode(n);
            i++;
          }
        }
      } else if (u >= 0xDC00 && u <= 0xDFFF) {
        continue;
      } else if (!TextRules.isForbiddenUnit(u)) {
        b.writeCharCode(u);
      }
    }
    return b.toString().trim();
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_deepEquals(a[k], b[k])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}

/// A group of segments on one line: a text run, an embed, or a removed embed.
final class _Group {
  _Group.text(LineSegment s)
    : segments = [s],
      isEmbed = false,
      isRemoved = false,
      canonical = null;
  _Group.embed(LineSegment s, this.canonical)
    : segments = [s],
      isEmbed = true,
      isRemoved = false;
  _Group.removed(LineSegment s)
    : segments = [s],
      isEmbed = false,
      isRemoved = true,
      canonical = null;

  final List<LineSegment> segments;
  final bool isEmbed;
  final bool isRemoved;
  final WonkyEmbed? canonical;

  bool get isText => !isEmbed && !isRemoved;
}

/// Accumulates the output document and the fix-up change simultaneously.
final class _Builder {
  final out = <Operation>[];
  final change = Delta();

  /// Number of line ends written to the output so far.
  int newlines = 0;

  /// Keeps [data] from the input with attributes changed from [attrsIn] to
  /// [attrsOut].
  void keep(
    Object data,
    Map<String, dynamic>? attrsIn,
    Map<String, dynamic>? attrsOut,
  ) {
    final len = data is String ? data.length : 1;
    if (len == 0) return;
    change.retain(len, Attributes.diff(attrsIn, attrsOut));
    out.add(Operation.insert(data, Attributes.orNull(attrsOut)));
    if (data == '\n') newlines++;
  }

  void delete(int n) {
    if (n > 0) change.delete(n);
  }

  void insert(Object data, Map<String, dynamic>? attrs) {
    final a = Attributes.orNull(attrs);
    change.insert(data, a);
    out.add(Operation.insert(data, a));
    if (data == '\n') newlines++;
  }
}

/// The lines [WonkyDeltaNormalizer._normalize] works on: the whole
/// document, or a run of its lines (`normalizedChange`).
final class _Window {
  const _Window({
    required this.startsDocument,
    required this.endsDocument,
    required this.prevListIndent,
    required this.prevListQuoted,
    required this.prevListBox,
  });

  const _Window.whole()
    : startsDocument = true,
      endsDocument = true,
      prevListIndent = null,
      prevListQuoted = false,
      prevListBox = const [];

  /// Whether the first line is the document's first.
  final bool startsDocument;

  /// Whether the last line is the document's last.
  final bool endsDocument;

  /// List indent of the line before the first (null: not a list line).
  final int? prevListIndent;

  /// Whether the line before the first is a quoted list item.
  final bool prevListQuoted;

  /// The containers of the line before the first.
  final List<BoxFrame> prevListBox;
}
