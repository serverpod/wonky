/// Import warnings (Write 02 §2.1, 07 §2.2): stable codes shown in the
/// import banner, also produced by the inline Markdown reader.
library;

/// Kinds of import warnings (stable codes shown in the import banner).
enum ImportWarningKind {
  /// Nested blockquotes flattened to one level.
  nestedQuoteFlattened,

  /// A Wonky Markdown directive was not closed, held lines it cannot keep
  /// (a grid's non-item lines) or nested too deep (Write 11 §4).
  directiveFlattened,

  /// A list inside a blockquote was flattened to quote lines.
  listInQuoteFlattened,

  /// A block (heading, code, table, …) inside a list item or quote was moved
  /// out or flattened.
  blockFlattened,

  /// Ordered list starting at a number other than 1 (numbering restarts).
  orderedListStart,

  /// List nesting deeper than 8 levels was flattened.
  indentTooDeep,

  /// A list item with several paragraphs was joined with soft breaks.
  multiParagraphItem,

  /// Inline HTML was stripped to text.
  htmlStripped,

  /// An HTML block was converted to text.
  htmlBlock,

  /// A link with a relative or unsupported target was dropped (text kept).
  unsupportedLink,

  /// An image could not be resolved (relative path, unsupported source).
  unresolvedImage,

  /// An image inside a link or table cell was converted to text.
  imageFlattened,

  /// Formatting not expressible in Markdown (underline, color, fonts, …) was
  /// removed.
  formattingRemoved,

  /// Table cells were merged/spanned or nested; content flattened.
  tableFlattened,

  /// Content that could not be represented was dropped (scripts, forms, …).
  contentDropped,

  /// Footnotes/endnotes were appended as a "Notes" section.
  footnotesAppended,

  /// Comments in the source were dropped.
  commentsDropped,

  /// Tracked changes were accepted.
  trackedChangesAccepted,

  /// Page/section breaks or columns were dropped.
  breaksDropped,

  /// Headers/footers were dropped.
  headersFootersDropped,

  /// The source text encoding was guessed (invalid UTF-8).
  encodingGuessed,

  /// Equations/charts/shapes were replaced with placeholders.
  placeholderInserted,
}

/// One import warning.
final class ImportWarning {
  /// Creates a warning.
  const ImportWarning(this.kind, this.message, {this.line, this.blockIndex});

  /// Kind.
  final ImportWarningKind kind;

  /// Human-readable description.
  final String message;

  /// 1-based source line, when known.
  final int? line;

  /// 0-based line index in the resulting document, when known.
  final int? blockIndex;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'message': message,
    'line': ?line,
    'block_index': ?blockIndex,
  };

  @override
  String toString() => 'ImportWarning(${kind.name}: $message)';
}
