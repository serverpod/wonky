/// Export interfaces and options (07 §2.2, §4).
library;

import 'dart:typed_data';

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../collab/suggestion_view.dart';
import 'package:wonky_fonts/wonky_fonts.dart';
import '../ir/doc_tree.dart';
import '../layout/page_setup.dart';
import '../theme/model/values.dart';
import '../theme/model/write_theme_data.dart';

/// Export formats.
enum ExportFormat {
  /// `.md`.
  markdown('md', 'text/markdown; charset=utf-8'),

  /// `.zip` with `document.md` + `images/`.
  markdownZip('zip', 'application/zip'),

  /// `.pdf`.
  pdf('pdf', 'application/pdf'),

  /// `.html` (self-contained).
  html('html', 'text/html; charset=utf-8'),

  /// `.zip` web page (`index.html`, `style.css`, `images/`, `fonts/`).
  htmlZip('zip', 'application/zip'),

  /// `.docx`.
  docx(
    'docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ),

  /// `.odt`.
  odt('odt', 'application/vnd.oasis.opendocument.text'),

  /// `.rtf`.
  rtf('rtf', 'application/rtf'),

  /// `.epub`.
  epub('epub', 'application/epub+zip'),

  /// `.txt`.
  txt('txt', 'text/plain; charset=utf-8');

  const ExportFormat(this.extension, this.mimeType);

  /// File extension (without dot).
  final String extension;

  /// MIME type.
  final String mimeType;

  /// MCP names (`md`, `md_zip`, `pdf`, `html`, `html_zip`, `docx`, `odt`,
  /// `rtf`, `epub`, `txt`).
  String get mcpName => switch (this) {
    markdown => 'md',
    markdownZip => 'md_zip',
    htmlZip => 'html_zip',
    _ => name,
  };

  /// Parses an MCP name.
  static ExportFormat? fromMcpName(String name) =>
      ExportFormat.values.where((f) => f.mcpName == name).firstOrNull;
}

/// An image resolved for export.
final class ResolvedImage {
  /// Creates an image.
  const ResolvedImage({
    required this.bytes,
    required this.mime,
    required this.widthPx,
    required this.heightPx,
  });

  /// Encoded bytes (PNG/JPEG after conversion).
  final Uint8List bytes;

  /// MIME type.
  final String mime;

  /// Intrinsic width.
  final int widthPx;

  /// Intrinsic height.
  final int heightPx;
}

/// Resolves `wonky-file://<uuid>` or `https://` image sources.
abstract interface class ImageResolver {
  /// Bytes + intrinsic size, or `null` if unavailable (exporters render an
  /// `[Image: alt]` placeholder and add a warning).
  Future<ResolvedImage?> resolve(String src);
}

/// An [ImageResolver] over a map (tests; images pre-resolved for isolates).
final class MapImageResolver implements ImageResolver {
  /// Creates a resolver.
  const MapImageResolver(this.images);

  /// Images by `src`.
  final Map<String, ResolvedImage> images;

  @override
  Future<ResolvedImage?> resolve(String src) async => images[src];
}

/// Rewrites links for exports.
abstract interface class LinkResolver {
  /// The exported URL for [link] (`wonky://doc/<uuid>#slug` → https or
  /// `#slug` for the same document).
  String resolve(String link);
}

/// Default link resolution (07 §2.2): `wonky://doc/<uuid>[#slug]` →
/// `https://<host>/write/d/<uuid>[#slug]` (same document → `#slug`),
/// `wonky://sheet/<uuid>` → `https://<host>/sheets/s/<uuid>`.
final class DefaultLinkResolver implements LinkResolver {
  /// Creates a resolver.
  const DefaultLinkResolver({required this.origin, this.documentUuid});

  /// Origin such as `https://wonky.work`.
  final String origin;

  /// The exported document (internal links to it become `#slug`).
  final String? documentUuid;

  @override
  String resolve(String link) {
    final doc = RegExp(r'^wonky://doc/([0-9A-Za-z-]+)(#.*)?$').firstMatch(link);
    if (doc != null) {
      final uuid = doc.group(1)!;
      final frag = doc.group(2) ?? '';
      if (uuid == documentUuid && frag.isNotEmpty) return frag;
      return '$origin/write/d/$uuid$frag';
    }
    final sheet = RegExp(
      r'^wonky://sheet/([0-9A-Za-z-]+)(.*)$',
    ).firstMatch(link);
    if (sheet != null) {
      return '$origin/sheets/s/${sheet.group(1)}${sheet.group(2)}';
    }
    return link;
  }
}

/// Leaves links unchanged.
final class IdentityLinkResolver implements LinkResolver {
  /// Creates the resolver.
  const IdentityLinkResolver();

  @override
  String resolve(String link) => link;
}

/// Export phases for progress reporting.
enum ExportPhase {
  /// Loading content.
  loading,

  /// Layout/pagination.
  layout,

  /// Loading fonts.
  fonts,

  /// Resolving images.
  images,

  /// Packaging the file.
  packaging,

  /// Uploading (server).
  uploading,
}

/// Progress callback.
typedef ExportProgressSink = void Function(ExportPhase phase, double progress);

/// Thrown when an export is cancelled.
final class ExportCancelledException implements Exception {
  /// Creates the exception.
  const ExportCancelledException();

  @override
  String toString() => 'ExportCancelledException';
}

/// Cooperative cancellation.
final class CancellationToken {
  var _cancelled = false;

  /// Whether cancellation was requested.
  bool get isCancelled => _cancelled;

  /// Requests cancellation.
  void cancel() => _cancelled = true;

  /// Throws [ExportCancelledException] when cancelled.
  void throwIfCancelled() {
    if (_cancelled) throw const ExportCancelledException();
  }
}

/// Gives the event loop a turn during a long export on the UI isolate (web,
/// 07 §4.3): exporters call [maybeYield] between blocks and pages; once
/// [slice] has passed since the last turn it awaits a zero-delay timer, so
/// the progress dialog paints and *Cancel* is handled. Server and isolate
/// runs pass none and stay synchronous.
final class ExportYielder {
  /// Creates a yielder.
  ExportYielder({this.slice = const Duration(milliseconds: 12)});

  /// Longest stretch of work between two turns.
  final Duration slice;

  final _since = Stopwatch()..start();

  /// Number of turns given so far (tests).
  int turns = 0;

  /// Awaits a zero-delay timer when [slice] has passed since the last turn.
  Future<void> maybeYield() async {
    if (_since.elapsed < slice) return;
    await Future<void>.delayed(Duration.zero);
    turns++;
    _since.reset();
  }
}

/// Everything an exporter needs (07 §2.2).
final class ExportInput {
  /// Creates an input.
  ExportInput({
    required this.document,
    this.revision = 0,
    this.meta = const DocMeta(),
    required this.theme,
    this.variant = ThemeVariant.light,
    this.pageSetup = const PageSetup(),
    this.images = const MapImageResolver({}),
    required this.fonts,
    this.links = const IdentityLinkResolver(),
    this.locale = 'en-US',
    required this.now,
    this.progress,
    this.cancel,
    this.yielder,
  });

  /// Canonical document delta at [revision].
  final Delta document;

  /// Revision.
  final int revision;

  /// Metadata (title, author, language, front matter, dates).
  final DocMeta meta;

  /// Theme.
  final WriteThemeData theme;

  /// Variant (light unless "Use dark theme").
  final ThemeVariant variant;

  /// Page setup.
  final PageSetup pageSetup;

  /// Image resolver.
  final ImageResolver images;

  /// Font provider.
  final FontProvider fonts;

  /// Link resolver.
  final LinkResolver links;

  /// Locale for dates in headers/footers.
  final String locale;

  /// Injected "now" for `{date}`.
  final DateTime now;

  /// Progress sink.
  final ExportProgressSink? progress;

  /// Cancellation.
  final CancellationToken? cancel;

  /// Turns for the event loop between blocks and pages (web; null: none).
  final ExportYielder? yielder;
}

/// A non-fatal export problem (missing image, dropped content).
final class ExportWarning {
  /// Creates a warning.
  const ExportWarning(this.code, this.message);

  /// Stable code (`image_unavailable`, `font_fallback`, `content_dropped`…).
  final String code;

  /// Description.
  final String message;

  /// JSON form.
  Map<String, dynamic> toJson() => {'code': code, 'message': message};

  @override
  String toString() => 'ExportWarning($code: $message)';
}

/// An exported file.
final class ExportArtifact {
  /// Creates an artifact.
  const ExportArtifact({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    this.pageCount,
    this.warnings = const [],
  });

  /// Sanitized file name with extension.
  final String fileName;

  /// MIME type.
  final String mimeType;

  /// Bytes.
  final Uint8List bytes;

  /// Page count (paginated formats).
  final int? pageCount;

  /// Warnings.
  final List<ExportWarning> warnings;
}

/// Options common to all formats (07 §4.1).
abstract base class ExportOptions {
  /// Creates options.
  const ExportOptions({
    this.suggestions = SuggestionViewMode.accepted,
    this.fileName,
  });

  /// Suggestion view (accepted | original).
  final SuggestionViewMode suggestions;

  /// File name (without extension; default: title).
  final String? fileName;

  /// Common options from MCP/preferences JSON (snake_case).
  static ({SuggestionViewMode suggestions, String? fileName}) commonFromJson(
    Map<String, dynamic> json,
  ) => (
    suggestions: json['suggestions'] == 'original'
        ? SuggestionViewMode.original
        : SuggestionViewMode.accepted,
    fileName: json['file_name'] as String?,
  );

  /// Common JSON.
  Map<String, dynamic> commonToJson() => {
    'suggestions': suggestions == SuggestionViewMode.original
        ? 'original'
        : 'accepted',
    'file_name': ?fileName,
  };

  /// JSON form (snake_case).
  Map<String, dynamic> toJson();
}

/// Markdown image handling.
enum MarkdownImageMode {
  /// Signed URLs (7 days).
  signedUrl,

  /// `wonky-file://` links.
  wonkyLink,

  /// Omit images.
  omit,
}

/// Markdown options.
final class MarkdownFileExportOptions extends ExportOptions {
  /// Creates options.
  const MarkdownFileExportOptions({
    super.suggestions,
    super.fileName,
    this.images = MarkdownImageMode.signedUrl,
    this.frontMatter = true,
  });

  /// Image handling.
  final MarkdownImageMode images;

  /// Emit front matter.
  final bool frontMatter;

  /// Parses JSON.
  factory MarkdownFileExportOptions.fromJson(Map<String, dynamic> json) {
    final c = ExportOptions.commonFromJson(json);
    return MarkdownFileExportOptions(
      suggestions: c.suggestions,
      fileName: c.fileName,
      images: switch (json['images']) {
        'wonky_link' || 'wonkyLink' => MarkdownImageMode.wonkyLink,
        'omit' => MarkdownImageMode.omit,
        _ => MarkdownImageMode.signedUrl,
      },
      frontMatter: json['front_matter'] != false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...commonToJson(),
    'images': switch (images) {
      MarkdownImageMode.signedUrl => 'signed_url',
      MarkdownImageMode.wonkyLink => 'wonky_link',
      MarkdownImageMode.omit => 'omit',
    },
    'front_matter': frontMatter,
  };
}

/// PDF options.
final class PdfExportOptions extends ExportOptions {
  /// Creates options.
  const PdfExportOptions({
    super.suggestions,
    super.fileName,
    this.includeToc = false,
    this.tocDepth = 3,
    this.bookmarks = true,
    this.pageRange = 'all',
    this.headerFooter = true,
    this.pageBackground,
  });

  /// Insert a table of contents.
  final bool includeToc;

  /// TOC depth 1–6.
  final int tocDepth;

  /// PDF outline/bookmarks.
  final bool bookmarks;

  /// `all` or `1-3,5`.
  final String pageRange;

  /// Render headers/footers.
  final bool headerFooter;

  /// Paint the page background (default: when paper ≠ white or dark).
  final bool? pageBackground;

  /// Parses JSON.
  factory PdfExportOptions.fromJson(Map<String, dynamic> json) {
    final c = ExportOptions.commonFromJson(json);
    return PdfExportOptions(
      suggestions: c.suggestions,
      fileName: c.fileName,
      includeToc: json['include_toc'] == true,
      tocDepth: (json['toc_depth'] as int? ?? 3).clamp(1, 6),
      bookmarks: json['bookmarks'] != false,
      pageRange: json['page_range'] as String? ?? 'all',
      headerFooter: json['header_footer'] != false,
      pageBackground: json['page_background'] as bool?,
    );
  }

  /// Selected 0-based page indexes of [pageCount] pages (`null` = all).
  Set<int>? selectedPages(int pageCount) {
    if (pageRange.trim().isEmpty || pageRange.trim() == 'all') return null;
    final pages = <int>{};
    for (final part in pageRange.split(',')) {
      final m = RegExp(r'^\s*(\d+)\s*(?:-\s*(\d+)\s*)?$').firstMatch(part);
      if (m == null) throw FormatException('Invalid page range "$pageRange"');
      final a = int.parse(m.group(1)!);
      final b = m.group(2) == null ? a : int.parse(m.group(2)!);
      for (var p = a; p <= b && p <= pageCount; p++) {
        if (p >= 1) pages.add(p - 1);
      }
    }
    return pages;
  }

  @override
  Map<String, dynamic> toJson() => {
    ...commonToJson(),
    'include_toc': includeToc,
    'toc_depth': tocDepth,
    'bookmarks': bookmarks,
    'page_range': pageRange,
    'header_footer': headerFooter,
    'page_background': ?pageBackground,
  };
}

/// HTML / web page zip options.
final class HtmlExportOptions extends ExportOptions {
  /// Creates options.
  const HtmlExportOptions({
    super.suggestions,
    super.fileName,
    this.embedImages = true,
    this.embedFonts,
    this.includeDarkMode = true,
    this.includeToc = false,
  });

  /// Images as data URIs (single file).
  final bool embedImages;

  /// Embed fonts (default: false for `.html`, true for the zip).
  final bool? embedFonts;

  /// Include a `prefers-color-scheme: dark` block.
  final bool includeDarkMode;

  /// Include a `<nav class="wonky-toc">`.
  final bool includeToc;

  /// Parses JSON.
  factory HtmlExportOptions.fromJson(Map<String, dynamic> json) {
    final c = ExportOptions.commonFromJson(json);
    return HtmlExportOptions(
      suggestions: c.suggestions,
      fileName: c.fileName,
      embedImages: json['embed_images'] != false,
      embedFonts: json['embed_fonts'] as bool?,
      includeDarkMode: json['include_dark_mode'] != false,
      includeToc: json['include_toc'] == true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...commonToJson(),
    'embed_images': embedImages,
    'embed_fonts': ?embedFonts,
    'include_dark_mode': includeDarkMode,
    'include_toc': includeToc,
  };
}

/// DOCX / ODT options.
final class OfficeExportOptions extends ExportOptions {
  /// Creates options.
  const OfficeExportOptions({
    super.suggestions,
    super.fileName,
    this.includeToc = false,
    this.embedFonts = false,
  });

  /// Insert a TOC (DOCX: field updated on open).
  final bool includeToc;

  /// Embed fonts (DOCX, P2).
  final bool embedFonts;

  /// Parses JSON.
  factory OfficeExportOptions.fromJson(Map<String, dynamic> json) {
    final c = ExportOptions.commonFromJson(json);
    return OfficeExportOptions(
      suggestions: c.suggestions,
      fileName: c.fileName,
      includeToc: json['include_toc'] == true,
      embedFonts: json['embed_fonts'] == true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...commonToJson(),
    'include_toc': includeToc,
    'embed_fonts': embedFonts,
  };
}

/// RTF options (common only).
final class RtfExportOptions extends ExportOptions {
  /// Creates options.
  const RtfExportOptions({super.suggestions, super.fileName});

  /// Parses JSON.
  factory RtfExportOptions.fromJson(Map<String, dynamic> json) {
    final c = ExportOptions.commonFromJson(json);
    return RtfExportOptions(suggestions: c.suggestions, fileName: c.fileName);
  }

  @override
  Map<String, dynamic> toJson() => commonToJson();
}

/// EPUB chapter splitting.
enum EpubChapterSplit {
  /// At level-1 headings.
  h1,

  /// At level-1 and level-2 headings.
  h2,

  /// One chapter.
  none,
}

/// EPUB options.
final class EpubExportOptions extends ExportOptions {
  /// Creates options.
  const EpubExportOptions({
    super.suggestions,
    super.fileName,
    this.chapterSplit = EpubChapterSplit.h1,
    this.cover = 'auto',
    this.embedFonts = true,
    this.useThemeColors = false,
    this.author,
  });

  /// Chapter splitting.
  final EpubChapterSplit chapterSplit;

  /// `auto`, `none`, or an image file UUID.
  final String cover;

  /// Embed fonts.
  final bool embedFonts;

  /// Use theme colors (else readers control colors).
  final bool useThemeColors;

  /// Author (default: owner name / front matter `author`).
  final String? author;

  /// Parses JSON.
  factory EpubExportOptions.fromJson(Map<String, dynamic> json) {
    final c = ExportOptions.commonFromJson(json);
    final cover = json['cover'];
    return EpubExportOptions(
      suggestions: c.suggestions,
      fileName: c.fileName,
      chapterSplit:
          EpubChapterSplit.values
              .where((v) => v.name == json['chapter_split'])
              .firstOrNull ??
          EpubChapterSplit.h1,
      cover: cover is String
          ? cover
          : (cover is Map && cover['image_file_uuid'] is String
                ? cover['image_file_uuid'] as String
                : 'auto'),
      embedFonts: json['embed_fonts'] != false,
      useThemeColors: json['use_theme_colors'] == true,
      author: json['author'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...commonToJson(),
    'chapter_split': chapterSplit.name,
    'cover': cover,
    'embed_fonts': embedFonts,
    'use_theme_colors': useThemeColors,
    'author': ?author,
  };
}

/// Plain-text table rendering.
enum TxtTables {
  /// Tab-separated.
  tsv,

  /// Space-aligned columns.
  aligned,
}

/// Plain-text options.
final class TxtExportOptions extends ExportOptions {
  /// Creates options.
  const TxtExportOptions({
    super.suggestions,
    super.fileName,
    this.crlf = false,
    this.wrapColumn = 0,
    this.tables = TxtTables.aligned,
  });

  /// CRLF line endings.
  final bool crlf;

  /// Hard wrap column (0 = none; 72 or 80).
  final int wrapColumn;

  /// Table rendering.
  final TxtTables tables;

  /// Parses JSON.
  factory TxtExportOptions.fromJson(Map<String, dynamic> json) {
    final c = ExportOptions.commonFromJson(json);
    return TxtExportOptions(
      suggestions: c.suggestions,
      fileName: c.fileName,
      crlf: json['line_endings'] == 'crlf',
      wrapColumn: json['wrap_column'] as int? ?? 0,
      tables: json['tables'] == 'tsv' ? TxtTables.tsv : TxtTables.aligned,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...commonToJson(),
    'line_endings': crlf ? 'crlf' : 'lf',
    'wrap_column': wrapColumn,
    'tables': tables.name,
  };
}

/// An exporter for one format.
abstract interface class DocumentExporter<O extends ExportOptions> {
  /// The format.
  ExportFormat get format;

  /// Exports [input].
  Future<ExportArtifact> export(ExportInput input, O options);
}

/// File name helpers.
abstract final class ExportFileNames {
  /// Sanitizes [name] (no `/\:*?"<>|`, ≤ 120 chars, default `Untitled`) and
  /// appends `.ext`.
  static String fileName(String? name, String extension) {
    var n = (name ?? '')
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (n.isEmpty) n = 'Untitled';
    if (n.length > 120) n = n.substring(0, 120).trim();
    return '$n.$extension';
  }
}
