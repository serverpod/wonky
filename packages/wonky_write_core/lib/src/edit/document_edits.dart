/// Pure change-Delta builders shared by client commands, headless MCP tools
/// and the AI (09 §1.4 step 3, §2.2).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:uuid/uuid.dart';

import '../delta/attributes.dart';
import '../delta/delta_diff.dart';
import '../delta/delta_utils.dart';
import '../delta/document.dart';
import '../delta/embeds.dart';
import '../delta/links.dart';
import '../delta/normalizer.dart';
import '../delta/ot.dart';
import '../delta/validator.dart';
import '../import/import_api.dart';
import '../markdown/inline_markdown.dart';
import '../markdown/markdown_codec.dart';
import 'address.dart';
import 'search.dart';

/// How `insertMarkdown` places content (09 §2.2).
enum InsertAs {
  /// A single paragraph at a mid-line position is merged inline; otherwise
  /// blocks are inserted (a mid-line position splits the line).
  auto,

  /// Inline (only the text of a single paragraph).
  inline,

  /// As blocks.
  blocks,
}

/// Inline formatting to set (`true`) or remove (`false` / `null` link).
final class InlineFormatPatch {
  /// Creates a patch. Omitted fields are left unchanged; for [link] use
  /// [clearLink] to remove links.
  const InlineFormatPatch({
    this.bold,
    this.italic,
    this.strike,
    this.code,
    this.link,
    this.clearLink = false,
  });

  /// Bold on/off.
  final bool? bold;

  /// Italic on/off.
  final bool? italic;

  /// Strikethrough on/off.
  final bool? strike;

  /// Inline code on/off (on removes bold/italic/strike).
  final bool? code;

  /// Link target to set.
  final String? link;

  /// Remove links (and mentions).
  final bool clearLink;

  /// Parses `{bold?, italic?, strike?, code?, link?: str|null}`.
  static InlineFormatPatch fromJson(Map<String, dynamic> json) {
    bool? b(String k) {
      final v = json[k];
      if (v == null) return null;
      if (v is bool) return v;
      throw AddressException(
        AddressErrorCode.invalidArgs,
        '"$k" must be a boolean',
      );
    }

    final hasLink = json.containsKey('link');
    final link = json['link'];
    if (link != null && link is! String) {
      throw const AddressException(
        AddressErrorCode.invalidArgs,
        '"link" must be a string or null',
      );
    }
    return InlineFormatPatch(
      bold: b('bold'),
      italic: b('italic'),
      strike: b('strike'),
      code: b('code'),
      link: link as String?,
      clearLink: hasLink && link == null,
    );
  }
}

/// Target block type for `setBlockType` (09 §2.2 `write.set_block_type`).
final class BlockTypeSpec {
  /// Creates a spec.
  const BlockTypeSpec(
    this.type, {
    this.level,
    this.indent,
    this.checked,
    this.language,
    this.quoted,
  });

  /// Block type.
  final BlockType type;

  /// Whether list and task items are inside a quote (`null` keeps whether
  /// the line is in a quote: a quote line becomes a quoted list item).
  final bool? quoted;

  /// Heading level 1–6.
  final int? level;

  /// List indent 0–8 (`null` keeps the current indent of list lines).
  final int? indent;

  /// Task state.
  final bool? checked;

  /// Code language.
  final String? language;

  /// Parses the MCP args (`type: paragraph|heading|bullet|ordered|task|quote|code`).
  static BlockTypeSpec fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']) {
      'paragraph' => BlockType.paragraph,
      'heading' => BlockType.heading,
      'bullet' => BlockType.bullet,
      'ordered' => BlockType.ordered,
      'task' => BlockType.task,
      'quote' => BlockType.quote,
      'code' => BlockType.code,
      _ => throw AddressException(
        AddressErrorCode.invalidArgs,
        'Unknown block type "${json['type']}"',
      ),
    };
    int? i(String k) {
      final v = json[k];
      if (v == null) return null;
      if (v is int) return v;
      throw AddressException(
        AddressErrorCode.invalidArgs,
        '"$k" must be an integer',
      );
    }

    final level = i('level');
    if (level != null && (level < 1 || level > 6)) {
      throw const AddressException(
        AddressErrorCode.invalidArgs,
        '"level" must be 1–6',
      );
    }
    final indent = i('indent');
    if (indent != null && (indent < 0 || indent > 8)) {
      throw const AddressException(
        AddressErrorCode.invalidArgs,
        '"indent" must be 0–8',
      );
    }
    return BlockTypeSpec(
      type,
      level: level,
      indent: indent,
      checked: json['checked'] as bool?,
      language: json['language'] as String?,
      quoted: json['quoted'] as bool?,
    );
  }
}

/// How replacement text is interpreted by `replaceText`.
enum ReplaceFormat {
  /// Plain text inheriting the inline attributes of the first replaced char.
  text,

  /// Inline Markdown (`**`, `*`, `` ` ``, links).
  markdownInline,
}

/// A table operation (09 §2.2 `write.update_table`).
sealed class TableOperation {
  const TableOperation();

  /// Parses `{op: set_cell|insert_row|delete_row|insert_column|delete_column|set_align, …}`.
  static TableOperation fromJson(Map<String, dynamic> json) {
    int i(String k) {
      final v = json[k];
      if (v is int) return v;
      throw AddressException(
        AddressErrorCode.invalidArgs,
        '"$k" must be an integer',
      );
    }

    List<String>? cells(String k) {
      final v = json[k];
      if (v == null) return null;
      if (v is List && v.every((e) => e is String)) return v.cast<String>();
      throw AddressException(
        AddressErrorCode.invalidArgs,
        '"$k" must be a list of strings',
      );
    }

    return switch (json['op']) {
      'set_cell' => SetCellOp(
        i('row'),
        i('col'),
        json['markdown'] as String? ?? '',
      ),
      'insert_row' => InsertRowOp(i('at'), cells: cells('cells')),
      'delete_row' => DeleteRowOp(i('row')),
      'insert_column' => InsertColumnOp(
        i('at'),
        header: json['header'] as String?,
        cells: cells('cells'),
      ),
      'delete_column' => DeleteColumnOp(i('col')),
      'set_align' => SetAlignOp(i('col'), CellAlign.tryParse(json['align'])),
      _ => throw AddressException(
        AddressErrorCode.invalidArgs,
        'Unknown table op "${json['op']}"',
      ),
    };
  }
}

/// Sets one cell (inline Markdown).
final class SetCellOp extends TableOperation {
  /// Creates the op.
  const SetCellOp(this.row, this.col, this.markdown);

  /// Row (0 = header).
  final int row;

  /// Column.
  final int col;

  /// Cell Markdown.
  final String markdown;
}

/// Inserts a row before [at] (`at == rows` appends).
final class InsertRowOp extends TableOperation {
  /// Creates the op.
  const InsertRowOp(this.at, {this.cells});

  /// Insertion index.
  final int at;

  /// Cells (padded/truncated to the column count).
  final List<String>? cells;
}

/// Deletes a row.
final class DeleteRowOp extends TableOperation {
  /// Creates the op.
  const DeleteRowOp(this.row);

  /// Row index.
  final int row;
}

/// Inserts a column before [at].
final class InsertColumnOp extends TableOperation {
  /// Creates the op.
  const InsertColumnOp(this.at, {this.header, this.cells});

  /// Insertion index.
  final int at;

  /// Header cell.
  final String? header;

  /// Body cells (top to bottom).
  final List<String>? cells;
}

/// Deletes a column.
final class DeleteColumnOp extends TableOperation {
  /// Creates the op.
  const DeleteColumnOp(this.col);

  /// Column index.
  final int col;
}

/// Sets the alignment of a column.
final class SetAlignOp extends TableOperation {
  /// Creates the op.
  const SetAlignOp(this.col, this.align);

  /// Column index.
  final int col;

  /// Alignment (`null` = default).
  final CellAlign? align;
}

/// Result of a document edit.
final class EditResult {
  /// Creates a result.
  const EditResult({
    required this.change,
    required this.document,
    this.appliedRange,
    this.warnings = const [],
    this.summary = '',
    this.extra = const {},
  });

  /// The change to submit as one op (normalized: `docBefore∘change` is
  /// valid).
  final Delta change;

  /// The document after the change.
  final Delta document;

  /// Range of the result in [document], when meaningful.
  final ResolvedRange? appliedRange;

  /// Import warnings from parsed Markdown.
  final List<ImportWarning> warnings;

  /// Short human-readable summary ("Replaced 2 occurrences").
  final String summary;

  /// Tool-specific outputs (e.g. `table_id`, `replacements`, `ranges`).
  final Map<String, dynamic> extra;

  /// Whether the change does nothing.
  bool get isNoop => change.isEmpty;
}

/// Builds change Deltas for document edits. All builders are pure: they take
/// the current document and return a normalized change.
final class DocumentEdits {
  /// Creates the builders. [idGenerator] creates embed ids (UUIDv7).
  DocumentEdits({
    String Function()? idGenerator,
    this.maxDocumentChars = WonkyDeltaValidator.defaultMaxDocumentChars,
  }) : idGenerator = idGenerator ?? (() => const Uuid().v7());

  /// Embed id generator.
  final String Function() idGenerator;

  /// Maximum document length (`write.maxDocumentChars`).
  final int maxDocumentChars;

  /// Maximum Markdown input size (1 MB).
  static const maxMarkdownLength = 1000000;

  static const _normalizer = WonkyDeltaNormalizer();

  // ---------------------------------------------------------------------
  // Parsing

  /// Parses [markdown] into a normalized fragment document.
  ImportResult parseMarkdown(String markdown) {
    if (markdown.length > maxMarkdownLength) {
      throw const AddressException(
        AddressErrorCode.tooLarge,
        'Markdown input larger than 1 MB',
      );
    }
    return const MarkdownCodec().importMarkdown(
      markdown,
      options: ImportOptions(idGenerator: idGenerator),
    );
  }

  static bool _isSingleParagraph(WonkyDocument f) =>
      f.lines.length == 1 &&
      !f.lines.first.isEmbedLine &&
      f.lines.first.format.type == BlockType.paragraph;

  // ---------------------------------------------------------------------
  // Insertion

  /// Inserts [markdown] at offset [at].
  EditResult insertMarkdown(
    Delta document,
    int at,
    String markdown, {
    InsertAs as = InsertAs.auto,
  }) {
    final parsed = parseMarkdown(markdown);
    final r = insertFragment(document, at, parsed.delta, as: as);
    return EditResult(
      change: r.change,
      document: r.document,
      appliedRange: r.appliedRange,
      warnings: parsed.warnings,
      summary: 'Inserted ${r.appliedRange?.length ?? 0} characters',
      extra: {'inserted_range': r.appliedRange?.toJson()},
    );
  }

  /// Inserts the fragment document [fragment] (normalized, ending with
  /// `"\n"`) at [at] following the [InsertAs] rules.
  EditResult insertFragment(
    Delta document,
    int at,
    Delta fragment, {
    InsertAs as = InsertAs.auto,
  }) {
    final change = _insertChange(WonkyDocument(document), at, fragment, as: as);
    final inserted = DeltaUtils.lengthDelta(change.$1);
    return _finish(
      document,
      change.$1,
      appliedRange: ResolvedRange(change.$2, inserted),
    );
  }

  /// Returns (change, start of inserted content).
  (Delta, int) _insertChange(
    WonkyDocument doc,
    int at,
    Delta fragment, {
    required InsertAs as,
  }) {
    AddressResolver.of(doc).checkOffset(at);
    final frag = WonkyDocument(DeltaUtils.canonical(fragment));
    final line = doc.lineAt(at);
    final fragLen = frag.length;
    final withoutLastNewline = frag.delta.slice(0, fragLen - 1);
    final single = _isSingleParagraph(frag);
    final inline =
        !line.isEmbedLine &&
        single &&
        (as == InsertAs.inline || (as == InsertAs.auto && at != line.start));
    if (fragLen <= 1 && single) return (Delta(), at);
    final d = Delta()..retain(at);
    if (inline) {
      for (final op in withoutLastNewline.operations) {
        d.push(op);
      }
      return (DeltaUtils.canonical(d), at);
    }
    final lastNewline = frag.lines.last.attributes;
    final lineBlock = Attributes.block(line.attributes);
    final isEmptyPlain = line.isEmpty && lineBlock.isEmpty;
    if (isEmptyPlain) {
      // Fill the empty paragraph.
      for (final op in withoutLastNewline.operations) {
        d.push(op);
      }
      d.retain(1, Attributes.diff(lineBlock, Attributes.block(lastNewline)));
      return (DeltaUtils.canonical(d), at);
    }
    if (at == line.start) {
      for (final op in frag.delta.operations) {
        d.push(op);
      }
      return (DeltaUtils.canonical(d), at);
    }
    // Split the line.
    d.insert('\n', Attributes.orNull(lineBlock));
    if (at == line.newlineOffset) {
      for (final op in withoutLastNewline.operations) {
        d.push(op);
      }
      d.retain(1, Attributes.diff(lineBlock, Attributes.block(lastNewline)));
    } else {
      for (final op in frag.delta.operations) {
        d.push(op);
      }
    }
    return (DeltaUtils.canonical(d), at + 1);
  }

  // ---------------------------------------------------------------------
  // Replace / delete

  /// Replaces [range] with [markdown]. With [preserveOverlays], the change
  /// is the minimal diff over the affected lines so unchanged words keep
  /// comment anchors and suggestions.
  EditResult replaceRange(
    Delta document,
    ResolvedRange range,
    String markdown, {
    bool preserveOverlays = true,
  }) {
    final parsed = parseMarkdown(markdown);
    final r = replaceRangeWithFragment(
      document,
      range,
      parsed.delta,
      preserveOverlays: preserveOverlays,
    );
    return EditResult(
      change: r.change,
      document: r.document,
      appliedRange: r.appliedRange,
      warnings: parsed.warnings,
      summary: 'Replaced ${range.length} characters',
      extra: {'replaced_range': r.appliedRange?.toJson()},
    );
  }

  /// Replaces [range] with the fragment document [fragment].
  EditResult replaceRangeWithFragment(
    Delta document,
    ResolvedRange range,
    Delta fragment, {
    bool preserveOverlays = true,
  }) {
    final doc = WonkyDocument(document);
    AddressResolver.of(doc).checkRange(range.start, range.length);
    final frag = WonkyDocument(DeltaUtils.canonical(fragment));
    final startLine = doc.lineAt(range.start);
    final inlineCase =
        range.end <= startLine.newlineOffset &&
        !startLine.isEmbedLine &&
        _isSingleParagraph(frag);

    // 1. Delete the range (never the final line end).
    final del = Delta()..retain(range.start);
    var deleteLength = range.length;
    final touchesEnd = range.end == doc.length;
    if (touchesEnd) deleteLength -= 1;
    del.delete(deleteLength);
    if (touchesEnd) {
      final finalAttrs = doc.lines.last.attributes;
      del.retain(1, Attributes.diff(Attributes.block(finalAttrs), null));
    }
    final afterDelete = WonkyOt.apply(document, del);
    // 2. Insert the fragment.
    final (ins, insStart) = _insertChange(
      WonkyDocument(afterDelete),
      range.start.clamp(0, DeltaUtils.documentLength(afterDelete) - 1),
      frag.delta,
      as: inlineCase ? InsertAs.inline : InsertAs.blocks,
    );
    final naive = WonkyOt.compose(del, ins);
    final target = WonkyOt.apply(document, naive);
    final insertedLength = DeltaUtils.lengthDelta(ins);

    var change = naive;
    if (preserveOverlays) {
      // Minimal diff over the affected lines.
      final regionStart = startLine.start;
      final endLine = doc.lineAt(
        range.length == 0 ? range.start : range.end - 1,
      );
      final regionEndOld = endLine.end;
      final regionEndNew = regionEndOld + DeltaUtils.lengthDelta(naive);
      final diff = DeltaDiff.diff(
        document.slice(regionStart, regionEndOld),
        target.slice(regionStart, regionEndNew),
        ignoreOverlays: true,
      );
      change = DeltaUtils.canonical(
        regionStart > 0 ? (Delta()..retain(regionStart)).concat(diff) : diff,
      );
    }
    return _finish(
      document,
      change,
      appliedRange: ResolvedRange(insStart, insertedLength),
    );
  }

  /// Deletes [range]. Whole-line ranges remove their line ends; a range
  /// reaching the document end keeps the final line end (deleting
  /// everything leaves one empty paragraph).
  EditResult deleteRange(Delta document, ResolvedRange range) {
    final doc = WonkyDocument(document);
    AddressResolver.of(doc).checkRange(range.start, range.length);
    if (range.length == 0) {
      return _finish(
        document,
        Delta(),
        appliedRange: ResolvedRange(range.start, 0),
      );
    }
    final d = Delta();
    if (range.end < doc.length) {
      d
        ..retain(range.start)
        ..delete(range.length);
    } else {
      final line = doc.lineAt(range.start);
      var start = range.start;
      Map<String, dynamic>? targetAttrs;
      if (start == 0) {
        targetAttrs = null;
      } else if (start == line.start) {
        start -= 1;
        targetAttrs = doc.lines[line.index - 1].attributes;
      } else {
        targetAttrs = line.attributes;
      }
      d
        ..retain(start)
        ..delete(doc.length - 1 - start)
        ..retain(1, Attributes.diff(doc.lines.last.attributes, targetAttrs));
    }
    return _finish(
      document,
      DeltaUtils.canonical(d),
      appliedRange: ResolvedRange(
        range.start.clamp(0, doc.length - range.length),
        0,
      ),
      summary: 'Deleted ${range.length} characters',
    );
  }

  // ---------------------------------------------------------------------
  // Formatting

  /// Applies inline formatting to the text in [range] (line ends, embeds and
  /// code-block lines are skipped).
  EditResult applyInlineFormat(
    Delta document,
    ResolvedRange range,
    InlineFormatPatch patch,
  ) {
    final doc = WonkyDocument(document);
    AddressResolver.of(doc).checkRange(range.start, range.length);
    String? link;
    if (patch.link != null) {
      link = LinkPolicy.normalizeLink(patch.link!);
      if (link == null) {
        throw AddressException(
          AddressErrorCode.invalidArgs,
          'Link must be http(s), mailto or wonky://: ${patch.link}',
        );
      }
    }
    final d = Delta();
    var pos = 0;
    for (final line in doc.linesInRange(range.start, range.length)) {
      if (line.format.type == BlockType.code) continue;
      for (final s in line.segments) {
        if (s.isEmbed) continue;
        final a = s.start > range.start ? s.start : range.start;
        final b = s.end < range.end ? s.end : range.end;
        if (b <= a) continue;
        final attrs = s.attributes ?? const <String, dynamic>{};
        final p = <String, dynamic>{};
        final hasCode = attrs[WonkyAttr.code] == true;
        for (final (key, value) in [
          (WonkyAttr.bold, patch.bold),
          (WonkyAttr.italic, patch.italic),
          (WonkyAttr.strike, patch.strike),
        ]) {
          if (value == true) {
            p[key] = true;
            if (hasCode) p[WonkyAttr.code] = null;
          } else if (value == false && attrs.containsKey(key)) {
            p[key] = null;
          }
        }
        if (patch.code == true) {
          p[WonkyAttr.code] = true;
          for (final k in WonkyAttr.codeExcludedKeys) {
            p[k] = null;
          }
        } else if (patch.code == false && hasCode) {
          p[WonkyAttr.code] = null;
        }
        if (link != null) {
          p[WonkyAttr.link] = link;
          if (attrs.containsKey(WonkyAttr.mention)) p[WonkyAttr.mention] = null;
        } else if (patch.clearLink) {
          if (attrs.containsKey(WonkyAttr.link)) p[WonkyAttr.link] = null;
          if (attrs.containsKey(WonkyAttr.mention)) p[WonkyAttr.mention] = null;
        }
        final effective = Attributes.diff(attrs, Attributes.apply(attrs, p));
        if (effective == null) continue;
        d.retain(a - pos);
        d.retain(b - a, effective);
        pos = b;
      }
    }
    return _finish(
      document,
      DeltaUtils.canonical(d),
      appliedRange: range,
      summary: 'Formatted ${range.length} characters',
    );
  }

  /// Changes the block type of every line touched by [range] (embed lines
  /// are skipped). Converting lines to code removes their inline formatting
  /// and merges them into one code block.
  EditResult setBlockType(
    Delta document,
    ResolvedRange range,
    BlockTypeSpec spec,
  ) {
    final doc = WonkyDocument(document);
    AddressResolver.of(doc).checkRange(range.start, range.length);
    final lines = doc.linesInRange(range.start, range.length);
    final d = Delta();
    var pos = 0;
    for (final line in lines) {
      if (line.isEmbedLine || !line.hasNewline) continue;
      final current = line.format;
      final indent = spec.indent ?? (current.isList ? current.indent : 0);
      final quoted = spec.quoted ?? current.inQuote;
      final target = switch (spec.type) {
        BlockType.paragraph => BlockFormat.paragraph,
        BlockType.heading => BlockFormat.heading(
          spec.level ?? (current.type == BlockType.heading ? current.level : 1),
        ),
        BlockType.quote => const BlockFormat(BlockType.quote),
        BlockType.code => BlockFormat(
          BlockType.code,
          language:
              spec.language ??
              (current.type == BlockType.code ? current.language : ''),
        ),
        BlockType.bullet => BlockFormat(
          BlockType.bullet,
          indent: indent,
          quoted: quoted,
        ),
        BlockType.ordered => BlockFormat(
          BlockType.ordered,
          indent: indent,
          quoted: quoted,
        ),
        BlockType.task => BlockFormat(
          BlockType.task,
          indent: indent,
          checked:
              spec.checked ??
              (current.type == BlockType.task && current.checked),
          quoted: quoted,
        ),
      };
      if (spec.type == BlockType.code) {
        for (final s in line.segments) {
          final inline = Attributes.inline(s.attributes);
          if (inline.isEmpty) continue;
          d.retain(s.start - pos);
          d.retain(s.length, {for (final k in inline.keys) k: null});
          pos = s.end;
        }
      }
      final patch = target.patchFrom(line.attributes);
      if (patch.isNotEmpty) {
        d.retain(line.newlineOffset - pos);
        d.retain(1, patch);
        pos = line.newlineOffset + 1;
      }
    }
    final first = lines.first.start;
    final last = lines.last.end;
    return _finish(
      document,
      DeltaUtils.canonical(d),
      appliedRange: ResolvedRange(first, last - first),
      summary: 'Changed ${lines.length} line(s)',
    );
  }

  // ---------------------------------------------------------------------
  // Find & replace

  /// Replaces occurrence [occurrence] (1-based) of [find], or all
  /// occurrences when [occurrence] is `null`.
  EditResult replaceText(
    Delta document,
    FindSpec find,
    String replacement, {
    int? occurrence,
    ReplaceFormat format = ReplaceFormat.text,
    ResolvedRange? scope,
  }) {
    final doc = WonkyDocument(document);
    final result = TextSearch(doc).search(find, scope: scope, limit: 1 << 30);
    final List<SearchMatch> selected;
    if (occurrence == null) {
      selected = result.matches;
    } else {
      if (occurrence < 1 || occurrence > result.matches.length) {
        throw AddressException(
          AddressErrorCode.quoteNotFound,
          'Occurrence $occurrence not found (${result.matches.length} matches)',
          details: {'count': result.matches.length},
        );
      }
      selected = [result.matches[occurrence - 1]];
    }
    final d = Delta();
    var pos = 0;
    var shift = 0;
    final ranges = <ResolvedRange>[];
    for (final m in selected) {
      final text = find.regex ? _expand(replacement, m.groups) : replacement;
      final firstAttrs = {
        for (final e
            in (doc.attributesAt(m.start) ?? const <String, dynamic>{}).entries)
          if (!WonkyAttr.isSuggestion(e.key)) e.key: e.value,
      };
      final runs = format == ReplaceFormat.markdownInline
          ? [
              for (final r in InlineMarkdown.parse(text))
                (
                  r.text,
                  {...Attributes.overlays(firstAttrs), ...?r.toAttributes()},
                ),
            ]
          : [(text.replaceAll('\n', ' '), firstAttrs)];
      d.retain(m.start - pos);
      d.delete(m.length);
      var len = 0;
      for (final (t, a) in runs) {
        d.insert(t, Attributes.orNull(a));
        len += t.length;
      }
      ranges.add(ResolvedRange(m.start + shift, len));
      shift += len - m.length;
      pos = m.start + m.length;
    }
    final r = _finish(document, DeltaUtils.canonical(d));
    return EditResult(
      change: r.change,
      document: r.document,
      appliedRange: ranges.isEmpty ? null : ranges.first,
      summary:
          'Replaced ${selected.length} occurrence${selected.length == 1 ? '' : 's'}',
      extra: {
        'replacements': selected.length,
        'ranges': [for (final x in ranges) x.toJson()],
      },
    );
  }

  static String _expand(String template, List<String?> groups) =>
      template.replaceAllMapped(RegExp(r'\$(\$|\d{1,2})'), (m) {
        final g = m.group(1)!;
        if (g == r'$') return r'$';
        final i = int.parse(g);
        return i < groups.length ? (groups[i] ?? '') : m.group(0)!;
      });

  // ---------------------------------------------------------------------
  // Whole document

  /// Replaces the whole document with [markdown] using the minimal diff, so
  /// comment anchors and pending suggestions survive on unchanged text.
  EditResult setMarkdown(Delta document, String markdown) {
    final parsed = parseMarkdown(markdown);
    final change = DeltaDiff.diff(document, parsed.delta, ignoreOverlays: true);
    var changed = 0;
    for (final op in change.operations) {
      if (!op.isRetain) changed += op.length!;
    }
    final r = _finish(
      document,
      change,
      summary: 'Replaced the document ($changed characters changed)',
    );
    return EditResult(
      change: r.change,
      document: r.document,
      warnings: parsed.warnings,
      summary: r.summary,
      extra: {'changed_chars': changed},
    );
  }

  // ---------------------------------------------------------------------
  // Embeds

  /// Inserts an image embed at [at] (as a block).
  EditResult insertImage(
    Delta document,
    int at, {
    required String src,
    String alt = '',
    String? title,
  }) {
    final normalized = LinkPolicy.normalizeImageSource(src);
    if (normalized == null) {
      throw AddressException(
        AddressErrorCode.invalidArgs,
        'Unsupported image source "$src"',
      );
    }
    final embed = ImageEmbed(
      id: idGenerator(),
      src: normalized,
      alt: alt.trim(),
      title: title?.trim(),
    );
    final r = insertFragment(
      document,
      at,
      Delta()
        ..insert(embed.toInsert())
        ..insert('\n'),
      as: InsertAs.blocks,
    );
    return EditResult(
      change: r.change,
      document: r.document,
      appliedRange: r.appliedRange,
      summary: 'Inserted an image',
      extra: {'image_id': embed.id},
    );
  }

  /// Inserts a table at [at]. Rows are padded to the widest row; row 0 is the
  /// header; cells are inline Markdown.
  EditResult insertTable(
    Delta document,
    int at,
    List<List<String>> rows, {
    List<CellAlign?>? align,
  }) {
    if (rows.isEmpty || rows.every((r) => r.isEmpty)) {
      throw const AddressException(
        AddressErrorCode.invalidArgs,
        'A table needs at least one row and column',
      );
    }
    final embed = TableEmbed(
      id: idGenerator(),
      align: align ?? const [],
      rows: rows,
    ).padded();
    final r = insertFragment(
      document,
      at,
      Delta()
        ..insert(embed.toInsert())
        ..insert('\n'),
      as: InsertAs.blocks,
    );
    final doc = WonkyDocument(r.document);
    var tableIndex = 0;
    for (final (_, e) in doc.embeds) {
      if (e is! TableEmbed) continue;
      if (e.id == embed.id) break;
      tableIndex++;
    }
    return EditResult(
      change: r.change,
      document: r.document,
      appliedRange: r.appliedRange,
      summary: 'Inserted a ${embed.rows.length}×${embed.columnCount} table',
      extra: {'table_id': embed.id, 'table_index': tableIndex},
    );
  }

  /// Finds a table by id or by 0-based index among tables; returns its
  /// offset and embed.
  static (int offset, TableEmbed table, Map<String, dynamic>? attributes)
  findTable(Delta document, {String? tableId, int? tableIndex}) {
    final doc = WonkyDocument(document);
    var i = 0;
    for (final line in doc.lines) {
      for (final s in line.segments) {
        final e = s.isEmbed ? WonkyEmbed.tryParse(s.data) : null;
        if (e is! TableEmbed) continue;
        if ((tableId != null && e.id == tableId) ||
            (tableId == null && tableIndex == i)) {
          return (s.start, e, s.attributes);
        }
        i++;
      }
    }
    throw AddressException(
      AddressErrorCode.notFound,
      'Table ${tableId ?? '#$tableIndex'} not found',
    );
  }

  /// Replaces a table's rows, or applies [operations] in order. The embed
  /// keeps its id (embed identity rule).
  EditResult updateTable(
    Delta document, {
    String? tableId,
    int? tableIndex,
    List<List<String>>? rows,
    List<TableOperation> operations = const [],
  }) {
    final (offset, table, attrs) = findTable(
      document,
      tableId: tableId,
      tableIndex: tableIndex,
    );
    var t = table.padded();
    if (rows != null) {
      if (rows.isEmpty) {
        throw const AddressException(
          AddressErrorCode.invalidArgs,
          'rows must not be empty',
        );
      }
      t = TableEmbed(id: t.id, align: t.align, rows: rows).padded();
    }
    for (final op in operations) {
      t = applyTableOperation(t, op);
    }
    final d = Delta()
      ..retain(offset)
      ..delete(1)
      ..insert(t.toInsert(), Attributes.orNull(Attributes.overlays(attrs)));
    final r = _finish(
      document,
      DeltaUtils.canonical(d),
      appliedRange: ResolvedRange(offset, 1),
    );
    return EditResult(
      change: r.change,
      document: r.document,
      appliedRange: r.appliedRange,
      summary: 'Updated table',
      extra: {
        'table_id': t.id,
        'rows': t.rows.length,
        'columns': t.columnCount,
      },
    );
  }

  /// Applies one table operation (pure).
  static TableEmbed applyTableOperation(TableEmbed table, TableOperation op) {
    final t = table.padded();
    final rows = [
      for (final r in t.rows) [...r],
    ];
    final align = [...t.align];
    final cols = t.columnCount;
    void check(bool ok, String message) {
      if (!ok) throw AddressException(AddressErrorCode.invalidArgs, message);
    }

    String cell(String s) =>
        s.replaceAll(RegExp(r'[\n\r\u2028\u2029\t]'), ' ').trim();
    switch (op) {
      case SetCellOp(:final row, :final col, :final markdown):
        check(
          row >= 0 && row < rows.length && col >= 0 && col < cols,
          'Cell ($row, $col) out of range',
        );
        rows[row][col] = cell(markdown);
      case InsertRowOp(:final at, :final cells):
        check(at >= 0 && at <= rows.length, 'Row index $at out of range');
        rows.insert(at, [
          for (var c = 0; c < cols; c++)
            cells != null && c < cells.length ? cell(cells[c]) : '',
        ]);
      case DeleteRowOp(:final row):
        check(row >= 0 && row < rows.length, 'Row $row out of range');
        check(rows.length > 1, 'Cannot delete the only row');
        rows.removeAt(row);
      case InsertColumnOp(:final at, :final header, :final cells):
        check(at >= 0 && at <= cols, 'Column index $at out of range');
        for (var r = 0; r < rows.length; r++) {
          final v = r == 0
              ? (header ?? '')
              : (cells != null && r - 1 < cells.length ? cells[r - 1] : '');
          rows[r].insert(at, cell(v));
        }
        align.insert(at, null);
      case DeleteColumnOp(:final col):
        check(col >= 0 && col < cols, 'Column $col out of range');
        check(cols > 1, 'Cannot delete the only column');
        for (final r in rows) {
          r.removeAt(col);
        }
        align.removeAt(col);
      case SetAlignOp(col: final col, align: final a):
        check(col >= 0 && col < cols, 'Column $col out of range');
        align[col] = a;
    }
    return TableEmbed(id: t.id, align: align, rows: rows);
  }

  // ---------------------------------------------------------------------

  EditResult _finish(
    Delta document,
    Delta change, {
    ResolvedRange? appliedRange,
    String summary = '',
  }) {
    final r = _normalizer.normalizeChange(document, change);
    final validation = WonkyDeltaValidator(
      maxDocumentChars: maxDocumentChars,
    ).validate(r.document);
    if (!validation.isValid) {
      final tooLong = validation.issues.any(
        (i) => i.code == ValidationCode.tooLong,
      );
      throw AddressException(
        tooLong ? AddressErrorCode.tooLarge : AddressErrorCode.validationFailed,
        tooLong
            ? 'Result exceeds $maxDocumentChars characters'
            : 'Result violates the document schema',
        details: validation.toJson(),
      );
    }
    ResolvedRange? applied = appliedRange;
    if (applied != null && r.fixup.isNotEmpty) {
      final (s, l) = WonkyOt.transformRange(
        r.fixup,
        applied.start,
        applied.length,
      );
      applied = ResolvedRange(s, l);
    }
    return EditResult(
      change: r.change,
      document: r.document,
      appliedRange: applied,
      summary: summary,
    );
  }
}
