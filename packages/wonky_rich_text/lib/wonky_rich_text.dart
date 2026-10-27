/// Shared rich text of the Wonky Work apps (v2 review Q4, suite 01 §2.1):
/// the pieces of Write's Delta model that Slides reuses without importing
/// `wonky_write_core`.
///
/// - Delta inline schema: attribute keys ([WonkyAttr]) and typed helpers
///   ([Attributes], [BlockFormat], [SuggestionMark]);
/// - Delta helpers ([DeltaUtils]: canonical form, lengths, builders;
///   [softBreak], [embedChar]);
/// - [LinkPolicy] (link/image URL rules) and [TextRules] (characters);
/// - [RichTextNormalizer] over a [RichTextSchema] (embed-free bodies:
///   canonical form, character rules, allowed attributes);
/// - the inline Markdown codec: [InlineRun], [InlineMarkdown] (parse),
///   [InlineMarkdownWriter] (write with context-aware escaping),
///   [InlineReader] and [ImportWarning].
///
/// Pure Dart (VM and web). `wonky_write_core` re-exports these names.
library;

export 'package:dart_quill_delta/dart_quill_delta.dart' show Delta, Operation;

export 'src/attributes.dart';
export 'src/delta_utils.dart';
export 'src/import_warning.dart';
export 'src/inline_run.dart';
export 'src/links.dart';
export 'src/markdown/inline_markdown.dart';
export 'src/markdown/inline_reader.dart';
export 'src/markdown/inline_writer.dart';
export 'src/markdown/md_syntax.dart';
export 'src/markdown/wonky_syntax.dart';
export 'src/rich_text_normalizer.dart';
export 'src/text_rules.dart';
