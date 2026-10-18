import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/ai/untrusted_text.dart';
import '../../platform/common/models.dart';
import '../mcp/headless_editor.dart';

/// The document as the model sees it.
class WriteDocContext {
  WriteDocContext({
    required this.title,
    required this.revision,
    required this.content,
    required this.markdown,
    required this.outline,
    required this.frontMatter,
  });

  final String title;
  final int revision;

  /// Head content (raw Delta, suggestions included).
  final Delta content;

  /// Accepted-view Markdown of the whole document.
  final String markdown;
  final List<OutlineEntry> outline;
  final String? frontMatter;

  late final WonkyDocument doc = WonkyDocument(content);

  /// Estimated tokens (4 characters per token).
  int get estimatedTokens => markdown.length ~/ 4;

  /// Whether only an outline and parts go into the prompt (Write 09 §5.6).
  bool get isLarge => estimatedTokens > WriteContextBuilder.largeTokenLimit;
}

/// A selection resolved against the head: a quote the model can use
/// directly with the tools.
class SelectionQuote {
  const SelectionQuote(this.quote, this.occurrence, this.start, this.length);

  final String quote;
  final int occurrence;
  final int start;
  final int length;
}

/// Builds document context for the AI (Write 09 §5.6): a frozen snapshot
/// for the first turn (cached), "document updated" elements appended later,
/// and volatile context (selection, caret, mode, role, date) at the end of
/// the latest user turn.
abstract final class WriteContextBuilder {
  /// Documents larger than this are sent as outline + sections.
  static const largeTokenLimit = 150000;

  /// Selections are quoted up to this many characters.
  static const maxSelectionQuote = 500;

  /// Loads the head of [target].
  static Future<WriteDocContext> load(
    Session session,
    WriteTarget target,
  ) async {
    final state = await HeadlessDocumentEditor.head(session, target.document);
    return fromContent(
      title: target.item.name,
      revision: state.revision,
      content: state.content,
      frontMatter: target.document.frontMatter,
    );
  }

  static WriteDocContext fromContent({
    required String title,
    required int revision,
    required Delta content,
    String? frontMatter,
  }) {
    final md = DocumentReader.renderMarkdown(
      content,
      SuggestionViewMode.accepted,
      frontMatter: frontMatter,
    );
    return WriteDocContext(
      title: title,
      revision: revision,
      content: content,
      markdown: md,
      outline: const OutlineExtractor().outlineOf(WonkyDocument(content)),
      frontMatter: frontMatter,
    );
  }

  static String _attr(String v) => UntrustedText.attribute(v);

  static String outlineJson(WriteDocContext c) => jsonEncode([
    for (final e in c.outline)
      {'index': e.index, 'level': e.level, 'text': e.text},
  ]);

  /// The document snapshot of a thread's first turn: outline JSON plus the
  /// full Markdown, or for large documents the outline plus the first
  /// section and the sections around [focusOffset].
  static String snapshot(WriteDocContext c, {int? focusOffset}) {
    final b = StringBuffer()
      ..writeln('<document_outline>${outlineJson(c)}</document_outline>');
    if (!c.isLarge) {
      b.write(
        '<document title="${_attr(c.title)}" revision="${c.revision}">\n'
        '${UntrustedText.escape(c.markdown, 'document')}\n</document>',
      );
      return b.toString();
    }
    b
      ..writeln(
        '<note>The document is large (about ${c.estimatedTokens} tokens). '
        'Only the first section and the section around the user\'s '
        'selection are included; read other sections with '
        'write_get_document {"range": {"type": "heading_section", '
        '"heading": "…"}}.</note>',
      )
      ..write(
        '<document_excerpt title="${_attr(c.title)}" '
        'revision="${c.revision}">\n',
      );
    final parts = <String>[];
    final sections = _sections(c);
    if (sections.isNotEmpty) parts.add(_sectionMarkdown(c, sections.first));
    if (focusOffset != null) {
      for (final s in sections.skip(1)) {
        if (focusOffset >= s.$1 && focusOffset < s.$1 + s.$2) {
          parts.add(_sectionMarkdown(c, s));
        }
      }
    }
    b
      ..write(
        UntrustedText.escape(parts.join('\n\n…\n\n'), 'document_excerpt'),
      )
      ..write('\n</document_excerpt>');
    return b.toString();
  }

  /// Top-level sections as (start, length) Delta ranges: the text before
  /// the first heading, then each heading of the smallest level used.
  static List<(int, int)> _sections(WriteDocContext c) {
    final len = c.doc.length;
    if (c.outline.isEmpty) return [(0, len)];
    final top = c.outline.map((e) => e.level).reduce((a, b) => a < b ? a : b);
    final starts = <int>[
      0,
      for (final e in c.outline)
        if (e.level == top && e.deltaOffset > 0) e.deltaOffset,
    ];
    return [
      for (var i = 0; i < starts.length; i++)
        (starts[i], (i + 1 < starts.length ? starts[i + 1] : len) - starts[i]),
    ].where((s) => s.$2 > 0).toList();
  }

  static String _sectionMarkdown(WriteDocContext c, (int, int) s) {
    final end = (s.$1 + s.$2).clamp(0, c.doc.length);
    final slice = c.content.slice(s.$1, end);
    return DocumentReader.renderMarkdown(slice, SuggestionViewMode.accepted);
  }

  /// Markdown sections keyed by heading line (for change summaries).
  static List<(String, String)> _mdSections(String md) {
    final out = <(String, String)>[];
    var title = '(start)';
    final buf = StringBuffer();
    var inFence = false;
    for (final line in const LineSplitter().convert(md)) {
      if (line.trimLeft().startsWith('```')) inFence = !inFence;
      if (!inFence && RegExp(r'^#{1,6}\s').hasMatch(line)) {
        out.add((title, buf.toString()));
        buf.clear();
        title = line.trim();
      }
      buf.writeln(line);
    }
    out.add((title, buf.toString()));
    return out;
  }

  /// The element appended when the document changed since the thread's
  /// last turn (never rewrites history): the changed sections' new
  /// Markdown (or just their headings when large), or null when unchanged.
  static String? update({
    required String? previousMarkdown,
    required int? previousRevision,
    required WriteDocContext now,
  }) {
    if (previousMarkdown == null) return null;
    if (previousMarkdown == now.markdown) return null;
    final before = {for (final s in _mdSections(previousMarkdown)) s.$1: s.$2};
    final after = _mdSections(now.markdown);
    final afterTitles = {for (final s in after) s.$1};
    final changed = <(String, String)>[
      for (final s in after)
        if (before[s.$1] != s.$2) s,
    ];
    final removed = [
      for (final t in before.keys)
        if (!afterTitles.contains(t)) t,
    ];
    final b = StringBuffer(
      '<document_update revision="${now.revision}"'
      '${previousRevision == null ? '' : ' previous_revision="$previousRevision"'}>\n'
      'The document changed since you last saw it. ',
    );
    final total = changed.fold<int>(0, (n, s) => n + s.$2.length);
    if (total > 60000 || now.isLarge) {
      b.writeln(
        'Changed sections: ${changed.map((s) => s.$1).join('; ')}. '
        'Read them with write_get_document before relying on their text.',
      );
    } else {
      b.writeln('Current text of the changed sections:');
      for (final s in changed) {
        b
          ..writeln('<section heading="${_attr(s.$1)}">')
          ..write(UntrustedText.escape(s.$2, 'section'))
          ..writeln('</section>');
      }
    }
    if (removed.isNotEmpty) {
      b.writeln('Removed sections: ${removed.join('; ')}.');
    }
    b
      ..writeln('Outline now: ${outlineJson(now)}')
      ..write('</document_update>');
    return b.toString();
  }

  /// Resolves the user's selection against the head: the client's offsets
  /// (of [clientRevision]) are only a hint; the quote is located near them.
  static SelectionQuote? selection(
    WriteDocContext c, {
    int? start,
    int? length,
    String? text,
  }) {
    final plain = c.doc.text;
    String? quote = text;
    if ((quote == null || quote.isEmpty) && start != null && length != null) {
      final s = start.clamp(0, plain.length);
      final e = (start + length).clamp(s, plain.length);
      quote = plain.substring(s, e);
    }
    if (quote == null || quote.trim().isEmpty) return null;
    if (quote.length > maxSelectionQuote) {
      quote = quote.substring(0, maxSelectionQuote);
    }
    final matches = AddressResolver.of(c.doc).findQuote(quote);
    if (matches.isEmpty) return null;
    var best = 0;
    if (start != null) {
      var dist = 1 << 30;
      for (var i = 0; i < matches.length; i++) {
        final d = (matches[i].start - start).abs();
        if (d < dist) {
          dist = d;
          best = i;
        }
      }
    }
    return SelectionQuote(
      quote,
      best + 1,
      matches[best].start,
      (text?.length ?? length ?? quote.length).clamp(0, plain.length),
    );
  }

  /// The heading path of [offset] ("Plan › Budget").
  static String? headingPath(WriteDocContext c, int offset) {
    final path = <OutlineEntry>[];
    for (final e in c.outline) {
      if (e.deltaOffset > offset) break;
      while (path.isNotEmpty && path.last.level >= e.level) {
        path.removeLast();
      }
      path.add(e);
    }
    return path.isEmpty ? null : path.map((e) => e.text).join(' › ');
  }

  /// Volatile context for the end of the latest user turn.
  static String volatile({
    required WriteDocContext c,
    required AiApplyMode applyMode,
    required String role,
    SelectionQuote? selection,
    String? caretHeadingPath,
    String? localTime,
    String? comments,
  }) {
    final b = StringBuffer('<context>\n');
    if (selection != null) {
      b.writeln(
        'Selected text (use it with quote addressing: {"type":"quote",'
        '"quote": <the text>, "occurrence": ${selection.occurrence}}; '
        'offsets start=${selection.start} length=${selection.length} at '
        'revision ${c.revision}):',
      );
      b.writeln('<selection>${selection.quote}</selection>');
    } else {
      b.writeln('No text is selected.');
    }
    if (caretHeadingPath != null) {
      b.writeln('Caret is in section: $caretHeadingPath');
    }
    b
      ..writeln(
        'Apply mode: ${applyMode == AiApplyMode.suggest ? 'Suggest (your edits become tracked suggestions)' : 'Edit directly'}',
      )
      ..writeln('User role: $role')
      ..writeln('Document revision: ${c.revision}');
    if (localTime != null) b.writeln('User\'s local time: $localTime');
    if (comments != null) {
      b.writeln('<open_comments>$comments</open_comments>');
    }
    b.write('</context>');
    return b.toString();
  }
}
