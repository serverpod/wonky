import 'dart:async';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../l10n/write_l10n.dart';
import '../themes/write_fonts.dart';

/// Formats offered under File › Download (Write 07 §9.1). All of them are
/// generated on the client with the shared core exporters (offline too);
/// [WriteExporter] hands very large documents to the server.
enum WriteDownloadFormat {
  md('md', ExportFormat.markdown),
  mdZip('mdZip', ExportFormat.markdownZip),
  pdf('pdf', ExportFormat.pdf),
  html('html', ExportFormat.html),
  htmlZip('htmlZip', ExportFormat.htmlZip),
  docx('docx', ExportFormat.docx),
  odt('odt', ExportFormat.odt),
  rtf('rtf', ExportFormat.rtf),
  epub('epub', ExportFormat.epub),
  txt('txt', ExportFormat.txt);

  const WriteDownloadFormat(this.id, this.format);

  /// Command argument (`write.file.download {format}`).
  final String id;
  final ExportFormat format;

  /// The format's display name in [l] ("PDF document (.pdf)").
  String labelOf(WriteLocalizations l) => switch (this) {
    md => l.exportFormatMd,
    mdZip => l.exportFormatMdZip,
    pdf => l.exportFormatPdf,
    html => l.exportFormatHtml,
    htmlZip => l.exportFormatHtmlZip,
    docx => l.exportFormatDocx,
    odt => l.exportFormatOdt,
    rtf => l.exportFormatRtf,
    epub => l.exportFormatEpub,
    txt => l.exportFormatTxt,
  };

  /// The English display name; UI code uses [labelOf].
  String get label => labelOf(writeL10nEnglish);

  static WriteDownloadFormat? tryParse(String? id) {
    for (final f in values) {
      if (f.id == id || f.format.mcpName == id || f.name == id) return f;
    }
    return null;
  }
}

/// Options of a client-side export (07 §4.1–4.2).
@immutable
class WriteExportOptions {
  const WriteExportOptions({
    this.suggestions = SuggestionViewMode.accepted,
    this.variant = ThemeVariant.light,
    this.headerFooter = true,
    this.includeToc = false,
    this.frontMatter = true,
    this.fileName,
  });

  final SuggestionViewMode suggestions;
  final ThemeVariant variant;
  final bool headerFooter;
  final bool includeToc;
  final bool frontMatter;
  final String? fileName;

  WriteExportOptions copyWith({
    SuggestionViewMode? suggestions,
    ThemeVariant? variant,
    bool? headerFooter,
    bool? includeToc,
    bool? frontMatter,
    String? fileName,
  }) => WriteExportOptions(
    suggestions: suggestions ?? this.suggestions,
    variant: variant ?? this.variant,
    headerFooter: headerFooter ?? this.headerFooter,
    includeToc: includeToc ?? this.includeToc,
    frontMatter: frontMatter ?? this.frontMatter,
    fileName: fileName ?? this.fileName,
  );

  Map<String, Object?> toJson() => {
    'suggestions': suggestions.name,
    'variant': variant.name,
    'headerFooter': headerFooter,
    'includeToc': includeToc,
    'frontMatter': frontMatter,
  };

  factory WriteExportOptions.fromJson(Map<String, Object?> json) =>
      WriteExportOptions(
        suggestions: json['suggestions'] == 'original'
            ? SuggestionViewMode.original
            : SuggestionViewMode.accepted,
        variant: json['variant'] == 'dark'
            ? ThemeVariant.dark
            : ThemeVariant.light,
        headerFooter: json['headerFooter'] != false,
        includeToc: json['includeToc'] == true,
        frontMatter: json['frontMatter'] != false,
      );
}

/// What the exporter needs about the document (snapshot at export time).
@immutable
class ExportSource {
  const ExportSource({
    required this.documentUuid,
    required this.delta,
    required this.title,
    required this.theme,
    required this.pageSetup,
    this.revision = 0,
    this.authorName,
    this.language,
    this.frontMatter,
    this.description,
    this.createdAt,
    this.modifiedAt,
    this.markdownFlavor = MarkdownFlavor.gfm,
  });

  final String documentUuid;
  final Delta delta;
  final String title;
  final WriteThemeData theme;
  final PageSetup pageSetup;
  final int revision;
  final String? authorName;
  final String? language;
  final String? frontMatter;
  final String? description;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  /// The document's Markdown flavor (Write 11 §3): Markdown exports write
  /// it.
  final MarkdownFlavor markdownFlavor;
}

/// Resolves images for client exports (07 §4.4): `wonky-file://` through a
/// signed URL, `https://` through the server's SSRF-safe proxy (CORS).
class ClientImageResolver implements ImageResolver {
  ClientImageResolver({
    required this.documentUuid,
    this.signedUrl,
    this.proxy,
    http.Client? client,
  }) : _http = client ?? http.Client();

  final String documentUuid;

  /// Signed URL of a stored file (`file.getUrl`).
  final Future<String?> Function(UuidValue fileUuid)? signedUrl;

  /// `writeExport.fetchImage` (https images).
  final Future<Uint8List> Function(String src)? proxy;
  final http.Client _http;
  final Map<String, Future<ResolvedImage?>> _cache = {};

  @override
  Future<ResolvedImage?> resolve(String src) =>
      _cache.putIfAbsent(src, () => _resolve(src));

  Future<ResolvedImage?> _resolve(String src) async {
    try {
      Uint8List? bytes;
      if (src.startsWith('wonky-file://')) {
        final uuid = UuidValue.withValidation(
          src.substring('wonky-file://'.length),
        );
        final url = await signedUrl?.call(uuid);
        if (url == null) return null;
        final r = await _http.get(Uri.parse(url));
        if (r.statusCode != 200) return null;
        bytes = r.bodyBytes;
      } else if (src.startsWith('https://')) {
        if (proxy != null) {
          bytes = await proxy!(src);
        } else {
          final r = await _http.get(Uri.parse(src));
          if (r.statusCode == 200) bytes = r.bodyBytes;
        }
      }
      if (bytes == null || bytes.isEmpty) return null;
      return await decodeForExport(bytes);
    } catch (e) {
      debugPrint('Export image $src failed: $e');
      return null;
    }
  }

  void dispose() => _http.close();
}

/// Describes [bytes] for the exporters (07 §4.4): PNG, JPEG, GIF and WebP
/// pass through as they are, read from their header like on the server
/// (`describeExportImage`); each exporter converts what its format can't
/// hold, in pure Dart. Only other formats (e.g. SVG or AVIF from `https`
/// images) are decoded by Flutter and re-encoded as PNG: Flutter web's
/// `toByteData(format: png)` can return the image on a larger, transparent
/// canvas when other images are rasterized at the same time.
Future<ResolvedImage?> decodeForExport(Uint8List bytes) async {
  final described = describeExportImage(bytes);
  if (described != null) return described;
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return null;
    return ResolvedImage(
      bytes: png.buffer.asUint8List(),
      mime: 'image/png',
      widthPx: image.width,
      heightPx: image.height,
    );
  } finally {
    image.dispose();
    codec.dispose();
  }
}

/// Client-side exports with `wonky_write_core` exporters (07 §4.3: offline
/// and ≤ 50 pages run on the client — the server path exists for MCP).
class WriteExporter {
  WriteExporter({required this.images, FontProvider? fonts, this.origin = ''})
    : fonts = fonts ?? AssetFontProvider();

  final ImageResolver images;
  final FontProvider fonts;

  /// Origin for internal links (`https://host`).
  final String origin;

  ExportInput _input(
    ExportSource src,
    WriteExportOptions options, {
    CancellationToken? cancel,
    ExportProgressSink? progress,
  }) => ExportInput(
    document: src.delta,
    revision: src.revision,
    meta: DocMeta(
      documentUuid: src.documentUuid,
      title: src.title,
      authorName: src.authorName,
      language: src.language,
      frontMatter: src.frontMatter,
      description: src.description,
      createdAt: src.createdAt,
      modifiedAt: src.modifiedAt,
      markdownFlavor: src.markdownFlavor,
    ),
    theme: src.theme,
    variant: options.variant,
    pageSetup: src.pageSetup,
    images: images,
    fonts: fonts,
    links: origin.isEmpty
        ? const IdentityLinkResolver()
        : DefaultLinkResolver(origin: origin, documentUuid: src.documentUuid),
    now: clock.now(),
    cancel: cancel,
    progress: progress,
    // Exports run on the UI isolate (Write 07 §4.3): turns for the event
    // loop between blocks and pages keep the progress dialog painting and
    // make *Cancel* work (W-07).
    yielder: ExportYielder(),
  );

  /// Exports [src] as [format].
  Future<ExportArtifact> export(
    ExportSource src,
    WriteDownloadFormat format, {
    WriteExportOptions options = const WriteExportOptions(),
    CancellationToken? cancel,
    ExportProgressSink? progress,
  }) {
    final input = _input(src, options, cancel: cancel, progress: progress);
    final name = sanitizeFileName(options.fileName ?? src.title);
    switch (format) {
      case WriteDownloadFormat.md:
        return const MarkdownFileExporter().export(
          input,
          MarkdownFileExportOptions(
            suggestions: options.suggestions,
            fileName: name,
            images: MarkdownImageMode.wonkyLink,
            frontMatter: options.frontMatter,
          ),
        );
      case WriteDownloadFormat.mdZip:
        return const MarkdownZipExporter().export(
          input,
          MarkdownFileExportOptions(
            suggestions: options.suggestions,
            fileName: name,
            frontMatter: options.frontMatter,
          ),
        );
      case WriteDownloadFormat.pdf:
        return const PdfExporter().export(
          input,
          PdfExportOptions(
            suggestions: options.suggestions,
            fileName: name,
            headerFooter: options.headerFooter,
            includeToc: options.includeToc,
          ),
        );
      case WriteDownloadFormat.html:
        return const HtmlExporter().export(
          input,
          HtmlExportOptions(suggestions: options.suggestions, fileName: name),
        );
      case WriteDownloadFormat.htmlZip:
        return const HtmlZipExporter().export(
          input,
          HtmlExportOptions(suggestions: options.suggestions, fileName: name),
        );
      case WriteDownloadFormat.docx:
        return const DocxExporter().export(
          input,
          OfficeExportOptions(
            suggestions: options.suggestions,
            fileName: name,
            includeToc: options.includeToc,
          ),
        );
      case WriteDownloadFormat.odt:
        return const OdtExporter().export(
          input,
          OfficeExportOptions(
            suggestions: options.suggestions,
            fileName: name,
            includeToc: options.includeToc,
          ),
        );
      case WriteDownloadFormat.rtf:
        return const RtfExporter().export(
          input,
          RtfExportOptions(suggestions: options.suggestions, fileName: name),
        );
      case WriteDownloadFormat.epub:
        return const EpubExporter().export(
          input,
          EpubExportOptions(
            suggestions: options.suggestions,
            fileName: name,
            author: src.authorName,
          ),
        );
      case WriteDownloadFormat.txt:
        return const TxtExporter().export(
          input,
          TxtExportOptions(suggestions: options.suggestions, fileName: name),
        );
    }
  }
}

/// File names without `/\:*?"<>|`, at most 120 characters (07 §4.1). An
/// empty [title] becomes "Untitled document" in [l] (English by default).
String sanitizeFileName(String title, {WriteLocalizations? l}) {
  var s = title.replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), ' ').trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) s = (l ?? writeL10nEnglish).untitledDocument;
  return s.length > 120 ? s.substring(0, 120).trim() : s;
}

/// Saves [artifact]: browser download in the same tab on web, a save dialog
/// (titled in [l], English by default) on desktop.
Future<bool> saveArtifact(
  ExportArtifact artifact, {
  WriteLocalizations? l,
}) async {
  final mime = artifact.mimeType.split(';').first.trim();
  final uri = await FilePicker.saveFile(
    fileName: artifact.fileName,
    bytes: artifact.bytes,
    mimeType: mime,
    dialogTitle: (l ?? writeL10nEnglish).exportSaveDialogTitle(
      artifact.fileName,
    ),
  );
  return kIsWeb || uri != null;
}

/// Builds the client image resolver from the shell services.
ClientImageResolver imageResolverFor(ShellServices s, String documentUuid) =>
    ClientImageResolver(
      documentUuid: documentUuid,
      signedUrl: (uuid) async {
        final v = await s.repositories.files.getUrl(uuid);
        return v.url;
      },
      proxy: s.client == null
          ? null
          : (src) async {
              final data = await s.client!.writeExport.fetchImage(
                UuidValue.withValidation(documentUuid),
                src,
              );
              return data.buffer.asUint8List(
                data.offsetInBytes,
                data.lengthInBytes,
              );
            },
    );
