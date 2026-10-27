import 'package:wonky_write_core/wonky_write_core.dart'
    show MarkdownExportOptions, MarkdownFlavor;
import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        CellAttr,
        DocTreeBuilder,
        HtmlBodyWriter,
        HtmlImporter,
        ImportOptions,
        MarkdownCodec,
        SuggestionView,
        SuggestionViewMode,
        WonkyDeltaNormalizer,
        WonkyDeltaValidator,
        WonkyDocument;

import '../mapping/wonky_schema.dart';

/// Clipboard representations of a document fragment (Write 04 §23.2).
@immutable
class ClipboardContent {
  const ClipboardContent({required this.plainText, this.html, this.delta});

  final String plainText;
  final String? html;

  /// The private Wonky Delta (also embedded in [html] as `data-wonky-delta`).
  final Delta? delta;
}

/// Result of decoding pasted content.
@immutable
class PastedFragment {
  const PastedFragment(
    this.delta, {
    this.droppedFormatting = false,
    this.isSingleUrl = false,
  });

  final Delta delta;

  /// Whether unsupported formatting was dropped (shows the paste toast).
  final bool droppedFormatting;

  /// The content was exactly one URL (link the selection, §23.4).
  final bool isSingleUrl;
}

/// Encodes copied fragments and decodes pasted content (Write 04 §23).
class ClipboardCodec {
  const ClipboardCodec({this.newEmbedId, this.flavor});

  /// Ids for embeds in pasted Wonky fragments (avoids identity collisions).
  final String Function()? newEmbedId;

  /// The document's Markdown flavor (copy and paste as Markdown, Write 11
  /// §5).
  final MarkdownFlavor Function()? flavor;

  MarkdownFlavor get _flavor => flavor?.call() ?? MarkdownFlavor.gfm;

  static const _deltaAttribute = 'data-wonky-delta';
  static final _url = RegExp(r'^(https?://|mailto:|wonky://)\S+$');

  /// Encodes [fragment] (a document Delta of the selection). Comments are
  /// never copied; suggestions are copied in the accepted view.
  ClipboardContent encode(Delta fragment, {bool plainAsMarkdown = true}) {
    final accepted = SuggestionView.accepted(
      _ensureTrailingNewline(fragment),
      stripComments: true,
    );
    final markdown = const MarkdownCodec()
        .exportMarkdown(
          accepted,
          options: MarkdownExportOptions(flavor: _flavor),
        )
        .trimRight();
    final tree = const DocTreeBuilder().fromDelta(
      accepted,
      view: SuggestionViewMode.raw,
    );
    final body = const HtmlBodyWriter().blocks(tree.blocks);
    final encoded = base64Url.encode(
      utf8.encode(jsonEncode(accepted.toJson())),
    );
    final html = '<div $_deltaAttribute="$encoded">$body</div>';
    return ClipboardContent(
      plainText: plainAsMarkdown ? markdown : readablePlainText(accepted),
      html: html,
      delta: accepted,
    );
  }

  /// Readable plain text: bullets `• `, numbers, tasks `☐ `/`☑ `, tables as
  /// TSV (cells of a row joined with tabs, Write 12 §3.4), images as
  /// `[image: alt]`.
  static String readablePlainText(Delta document) {
    final out = <String>[];
    var ordinal = 0;
    CellAttr? previousCell;
    for (final line in WonkyDocument(document).lines) {
      final text = StringBuffer();
      for (final segment in line.segments) {
        final data = segment.data;
        if (data is String) {
          text.write(data.replaceAll(DeltaKeys.softBreak, '\n'));
          continue;
        }
        final map = data as Map;
        final type = map.keys.first;
        final value = map[type];
        if (type == DeltaKeys.imageEmbed && value is Map) {
          text.write('[image: ${value['alt'] ?? ''}]');
        } else if (type == DeltaKeys.dividerEmbed) {
          text.write('---');
        } else if (type == DeltaKeys.tableEmbed && value is Map) {
          final rows = (value['rows'] as List? ?? const []).map(
            (r) => (r as List).join('\t'),
          );
          text.write(rows.join('\n'));
        }
      }
      final attrs = line.attributes;
      final cell = CellAttr.of(attrs);
      if (cell != null) {
        final sameRow =
            previousCell != null &&
            previousCell.table == cell.table &&
            previousCell.row == cell.row;
        if (sameRow) {
          out.last = '${out.last}\t$text';
        } else {
          out.add('$text');
        }
        previousCell = cell;
        ordinal = 0;
        continue;
      }
      previousCell = null;
      final list = attrs[DeltaKeys.list];
      final indent = '  ' * ((attrs[DeltaKeys.indent] as int?) ?? 0);
      final prefix = switch (list) {
        'bullet' => '$indent• ',
        'ordered' => '$indent${++ordinal}. ',
        'checked' => '$indent☑ ',
        'unchecked' => '$indent☐ ',
        _ => '',
      };
      if (list != 'ordered') ordinal = 0;
      out.add('$prefix$text');
    }
    return out.join('\n').trimRight();
  }

  /// Decodes pasted content (§23.3): Wonky Delta → HTML → plain text
  /// (Markdown when it looks like Markdown). With [plainOnly], only the plain
  /// text is used, without Markdown detection (`pasteWithoutFormatting`).
  PastedFragment? decode(
    ClipboardContent content, {
    bool plainOnly = false,
    bool forceMarkdown = false,
  }) {
    final options = ImportOptions(idGenerator: newEmbedId, flavor: _flavor);
    if (!plainOnly && content.html != null) {
      final embedded = _embeddedDelta(content.html!);
      if (embedded != null) return PastedFragment(embedded);
    }
    if (!plainOnly && content.delta != null) {
      final cleaned = _cleanWonkyDelta(content.delta!);
      if (cleaned != null) return PastedFragment(cleaned);
    }
    if (!plainOnly && content.html != null && content.html!.trim().isNotEmpty) {
      final result = const HtmlImporter().importFragment(
        content.html!,
        options: options,
      );
      if (result.delta.isNotEmpty) {
        return PastedFragment(
          result.delta,
          droppedFormatting: result.warnings.isNotEmpty,
        );
      }
    }
    final text = content.plainText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    if (text.isEmpty) return null;
    final trimmed = text.trim();
    if (!plainOnly && _url.hasMatch(trimmed)) {
      return PastedFragment(
        Delta()..insert(trimmed, {DeltaKeys.link: trimmed}),
        isSingleUrl: true,
      );
    }
    if (!plainOnly &&
        (forceMarkdown || MarkdownDetector.looksLikeMarkdown(text))) {
      final result = const MarkdownCodec().importMarkdown(
        text,
        options: options,
      );
      if (result.delta.isNotEmpty) {
        return PastedFragment(_withoutTrailingEmptyLine(result.delta, text));
      }
    }
    return PastedFragment(plainTextFragment(text));
  }

  /// Plain text as paragraphs (tabs → 4 spaces, control characters removed).
  static Delta plainTextFragment(String text) {
    final clean = text
        .replaceAll('\t', '    ')
        .replaceAll(
          RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'),
          '',
        );
    return Delta()..insert(clean);
  }

  Delta? _embeddedDelta(String html) {
    final match = RegExp(
      '$_deltaAttribute="([A-Za-z0-9_=-]+)"',
    ).firstMatch(html);
    if (match == null) return null;
    try {
      final json = jsonDecode(utf8.decode(base64Url.decode(match.group(1)!)));
      if (json is! List) return null;
      return _cleanWonkyDelta(Delta.fromJson(json));
    } catch (_) {
      return null;
    }
  }

  /// Validates a Wonky fragment, strips `cmt_*`/`sug_*` and gives embeds new
  /// ids.
  Delta? _cleanWonkyDelta(Delta delta) {
    final ensured = _ensureTrailingNewline(delta);
    final normalized = const WonkyDeltaNormalizer().normalize(ensured).document;
    if (!const WonkyDeltaValidator().validate(normalized).isValid) return null;
    final result = Delta();
    for (final op in normalized.operations) {
      final attributes = op.attributes == null
          ? null
          : <String, dynamic>{
              for (final e in op.attributes!.entries)
                if (!DeltaKeys.isOverlay(e.key)) e.key: e.value,
            };
      var data = op.data;
      if (data is Map && newEmbedId != null) {
        final type = data.keys.first;
        final value = (data[type] as Map).cast<String, dynamic>();
        data = {
          type: {...value, 'id': newEmbedId!()},
        };
      }
      result.push(
        Operation.insert(
          data,
          attributes == null || attributes.isEmpty ? null : attributes,
        ),
      );
    }
    return _endsWithNewline(delta) ? result : _withoutFinalNewline(result);
  }

  static bool _endsWithNewline(Delta delta) {
    if (delta.isEmpty) return false;
    final data = delta.last.data;
    return data is String && data.endsWith('\n');
  }

  static Delta _ensureTrailingNewline(Delta delta) =>
      _endsWithNewline(delta) ? delta : (Delta.from(delta)..insert('\n'));

  static Delta _withoutFinalNewline(Delta delta) {
    final ops = delta.toList();
    final last = ops.removeLast();
    final data = last.data as String;
    final result = Delta.fromOperations(ops);
    if (data.length > 1) {
      result.push(
        Operation.insert(data.substring(0, data.length - 1), last.attributes),
      );
    }
    if (last.attributes != null && data.length == 1) {
      // A final line end with block attributes is kept (complete line).
      return delta;
    }
    return result;
  }

  /// Markdown import always ends with a line end; when the pasted text didn't
  /// end with a newline and its last line is a plain paragraph, drop that line
  /// end so the last line merges with the text after the caret.
  static Delta _withoutTrailingEmptyLine(Delta delta, String text) {
    if (text.endsWith('\n')) return delta;
    final last = delta.last;
    if (last.data is String &&
        (last.data as String).endsWith('\n') &&
        last.attributes == null) {
      return _withoutFinalNewline(delta);
    }
    return delta;
  }
}

/// Heuristic Markdown detection (Write 04 §23.3): at least two distinct
/// signals, or one unambiguous block construct.
abstract final class MarkdownDetector {
  static final _fence = RegExp(r'^```', multiLine: true);
  static final _tableDelimiter = RegExp(
    r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$',
    multiLine: true,
  );
  static final _heading = RegExp(r'^#{1,6} \S', multiLine: true);
  static final _task = RegExp(r'^\s*[-*+] \[( |x|X)\] ', multiLine: true);
  static final _signals = <RegExp>[
    RegExp(r'\*\*[^*\n]+\*\*'),
    RegExp(r'(^|[^*\w])\*[^*\s][^*\n]*\*'),
    RegExp(r'`[^`\n]+`'),
    RegExp(r'\[[^\]\n]+\]\([^)\s]+\)'),
    RegExp(r'^\s*[-*+] \S', multiLine: true),
    RegExp(r'^\s*\d+[.)] \S', multiLine: true),
    RegExp(r'^> ', multiLine: true),
    RegExp(r'~~[^~\n]+~~'),
    RegExp(r'^(---|\*\*\*|___)\s*$', multiLine: true),
  ];

  static bool looksLikeMarkdown(String text) {
    if (_fence.hasMatch(text) ||
        _tableDelimiter.hasMatch(text) ||
        _heading.hasMatch(text) ||
        _task.hasMatch(text)) {
      return true;
    }
    var count = 0;
    for (final signal in _signals) {
      if (signal.hasMatch(text)) count += 1;
      if (count >= 2) return true;
    }
    return false;
  }
}
