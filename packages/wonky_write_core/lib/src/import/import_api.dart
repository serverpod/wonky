/// Import interfaces and results (02 §2.1, 07 §2.2).
library;

import 'dart:typed_data';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:uuid/uuid.dart';
import 'package:wonky_rich_text/wonky_rich_text.dart'
    show ImportWarning, MarkdownFlavor;

export 'package:wonky_rich_text/wonky_rich_text.dart'
    show
        ImportWarning,
        ImportWarningKind,
        MarkdownFlavor,
        looksLikeWonkyMarkdown;

/// Import source formats.
enum ImportFormat {
  /// Markdown (`.md`, `.markdown`, …).
  markdown,

  /// Plain text.
  txt,

  /// HTML (files and clipboard).
  html,

  /// Word (`.docx`).
  docx,

  /// OpenDocument text (`.odt`).
  odt,

  /// Rich Text Format (`.rtf`).
  rtf,
}

/// An image extracted during import, referenced by `import-image://<tempId>`.
final class ImportedImage {
  /// Creates an imported image.
  const ImportedImage({
    required this.tempId,
    required this.bytes,
    required this.mime,
    this.alt = '',
  });

  /// Temporary id used in the `src`.
  final String tempId;

  /// Image bytes.
  final Uint8List bytes;

  /// MIME type.
  final String mime;

  /// Alt text.
  final String alt;

  /// The temporary `src` value.
  String get src => 'import-image://$tempId';
}

/// Page geometry detected in a source document (DOCX/ODT/RTF → page setup).
final class ImportedPageSetup {
  /// Creates detected page geometry (all lengths in points).
  const ImportedPageSetup({
    required this.widthPt,
    required this.heightPt,
    this.marginTopPt,
    this.marginRightPt,
    this.marginBottomPt,
    this.marginLeftPt,
  });

  /// Page width.
  final double widthPt;

  /// Page height.
  final double heightPt;

  /// Top margin.
  final double? marginTopPt;

  /// Right margin.
  final double? marginRightPt;

  /// Bottom margin.
  final double? marginBottomPt;

  /// Left margin.
  final double? marginLeftPt;
}

/// Result of an import.
final class ImportResult {
  /// Creates a result.
  const ImportResult({
    required this.delta,
    this.warnings = const [],
    this.title,
    this.frontMatter,
    this.language,
    this.images = const [],
    this.pageSetup,
    this.markdownFlavor = MarkdownFlavor.gfm,
  });

  /// The imported, normalized and valid document delta.
  final Delta delta;

  /// What could not be imported exactly.
  final List<ImportWarning> warnings;

  /// Suggested title (front matter, document properties, `<title>`, first H1).
  final String? title;

  /// Front matter (without `---` fences).
  final String? frontMatter;

  /// Source language (BCP-47) when known.
  final String? language;

  /// Images referenced as `import-image://<tempId>`.
  final List<ImportedImage> images;

  /// Page geometry from the source, when present.
  final ImportedPageSetup? pageSetup;

  /// The flavor Markdown was read in (Write 11 §5.1); `wonky` when the
  /// source had Wonky directives and [ImportOptions.detectFlavor] was set.
  final MarkdownFlavor markdownFlavor;
}

/// Options shared by importers.
final class ImportOptions {
  /// Creates options.
  ImportOptions({
    String Function()? idGenerator,
    this.txtLineBreaks = TxtLineBreaks.paragraph,
    this.baseUrl,
    this.fileName,
    this.flavor = MarkdownFlavor.gfm,
    this.detectFlavor = false,
  }) : idGenerator = idGenerator ?? _uuidV7;

  static String _uuidV7() => const Uuid().v7();

  /// Generates embed and container ids (UUIDv7 by default; inject for
  /// determinism).
  final String Function() idGenerator;

  /// The Markdown flavor Markdown sources are read in (Write 11 §5.1).
  final MarkdownFlavor flavor;

  /// Read Markdown that contains Wonky directives as Wonky Markdown (new
  /// documents from a file, Write 11 §5.1).
  final bool detectFlavor;

  /// Copy with [flavor] changed.
  ImportOptions withFlavor(MarkdownFlavor flavor) => ImportOptions(
    idGenerator: idGenerator,
    txtLineBreaks: txtLineBreaks,
    baseUrl: baseUrl,
    fileName: fileName,
    flavor: flavor,
  );

  /// Plain-text line break handling.
  final TxtLineBreaks txtLineBreaks;

  /// Base URL for resolving relative links (HTML `<base>`/source URL).
  final Uri? baseUrl;

  /// Original file name (title fallback).
  final String? fileName;
}

/// Plain-text import line handling (07 §3.4).
enum TxtLineBreaks {
  /// Each line becomes a paragraph.
  paragraph,

  /// Blank-line separated blocks become paragraphs; single line breaks become
  /// soft breaks (U+2028).
  soft,
}

/// An importer for one [ImportFormat].
abstract interface class DocumentImporter {
  /// The format.
  ImportFormat get format;

  /// Imports [bytes].
  Future<ImportResult> import(Uint8List bytes, ImportOptions options);
}
