/// Format detection, dispatch and image post-processing for imports
/// (07 §2.2, §3.2, §3.3).
library;

import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/embeds.dart';
import '../delta/normalizer.dart';
import '../markdown/markdown_codec.dart';
import 'docx/docx_importer.dart';
import 'encoding.dart';
import 'html/html_importer.dart';
import 'import_api.dart';
import 'import_limits.dart';
import 'odt/odt_importer.dart';
import 'rtf/rtf_importer.dart';
import 'txt_importer.dart';

/// A detected import source.
final class DetectedImport {
  /// Creates a detection result.
  const DetectedImport(this.format, {this.markdownZip = false});

  /// Format.
  final ImportFormat format;

  /// A `.zip` containing one Markdown file plus assets.
  final bool markdownZip;

  /// Whether this version can import the format (all formats are).
  bool get isSupported => ImportFormat.values.contains(format);
}

/// Detects formats by extension, then by sniffing (07 §3.2 step 2).
abstract final class ImportFormatDetector {
  static const _markdownExt = {'md', 'markdown', 'mdown', 'mkd', 'mkdn'};
  static const _txtExt = {'txt', 'text'};
  static const _htmlExt = {'html', 'htm', 'xhtml'};

  /// Detects the format of [bytes] (file name optional).
  static DetectedImport detect(Uint8List bytes, {String? fileName}) {
    final ext = fileName == null || !fileName.contains('.')
        ? ''
        : fileName.split('.').last.toLowerCase();
    final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    if (isZip) {
      try {
        final archive = ZipDecoder().decodeBytes(bytes);
        final names = archive.files.map((f) => f.name).toList();
        if (names.contains('[Content_Types].xml')) {
          return const DetectedImport(ImportFormat.docx);
        }
        final mimetype = archive.findFile('mimetype');
        // The `mimetype` entry is a short string: a large one is not read
        // (zip bombs, W-06).
        if (mimetype != null &&
            mimetype.size <= 1024 &&
            String.fromCharCodes(
              mimetype.content as List<int>,
            ).startsWith('application/vnd.oasis.opendocument.text')) {
          return const DetectedImport(ImportFormat.odt);
        }
        if (names.any(
          (n) => _markdownExt.contains(n.split('.').last.toLowerCase()),
        )) {
          return const DetectedImport(ImportFormat.markdown, markdownZip: true);
        }
      } on Object {
        // Not a readable zip: fall through.
      }
    }
    if (_markdownExt.contains(ext)) {
      return const DetectedImport(ImportFormat.markdown);
    }
    if (_htmlExt.contains(ext)) return const DetectedImport(ImportFormat.html);
    if (ext == 'docx') return const DetectedImport(ImportFormat.docx);
    if (ext == 'odt') return const DetectedImport(ImportFormat.odt);
    if (ext == 'rtf') return const DetectedImport(ImportFormat.rtf);
    final head = String.fromCharCodes(bytes.take(512)).trimLeft().toLowerCase();
    if (head.startsWith(r'{\rtf')) {
      return const DetectedImport(ImportFormat.rtf);
    }
    if (head.startsWith('<!doctype html') || head.startsWith('<html')) {
      return const DetectedImport(ImportFormat.html);
    }
    if (_txtExt.contains(ext)) return const DetectedImport(ImportFormat.txt);
    return const DetectedImport(ImportFormat.markdown);
  }
}

/// Imports files of any supported format (server `DriveEndpoint.import`,
/// client *Import into this document*, drag and drop).
final class WonkyImporters {
  /// Creates the dispatcher with [limits].
  const WonkyImporters({this.limits = ImportLimits.server});

  /// Size limits.
  final ImportLimits limits;

  /// Imports [bytes]; [format] overrides detection. Throws
  /// [ImportFormatException] for unsupported formats and
  /// [ImportTooLargeException] beyond [limits].
  Future<ImportResult> import(
    Uint8List bytes,
    ImportOptions options, {
    ImportFormat? format,
    bool? markdownZip,
  }) async {
    limits.checkInput(bytes.length);
    final detected = format == null
        ? ImportFormatDetector.detect(bytes, fileName: options.fileName)
        : DetectedImport(format, markdownZip: markdownZip ?? false);
    final ImportResult result;
    switch (detected.format) {
      case ImportFormat.markdown:
        result = detected.markdownZip
            ? _markdownZip(bytes, options)
            : _markdown(bytes, options);
      case ImportFormat.txt:
        result = await const TxtImporter().import(bytes, options);
      case ImportFormat.html:
        result = await const HtmlImporter().import(bytes, options);
      case ImportFormat.docx:
        result = const DocxImporter().importSync(bytes, options);
      case ImportFormat.odt:
        result = const OdtImporter().importSync(bytes, options);
      case ImportFormat.rtf:
        result = const RtfImporter().importSync(bytes, options);
    }
    limits.checkResult(result.delta);
    return result;
  }

  ImportResult _markdown(Uint8List bytes, ImportOptions options) {
    final decoded = ImportTextDecoder.decode(bytes);
    final r = const MarkdownCodec().importMarkdown(
      decoded.text,
      options: _flavored(decoded.text, options),
    );
    final w = decoded.warning;
    return w == null ? r : _withWarnings(r, [w]);
  }

  ImportResult _markdownZip(Uint8List bytes, ImportOptions options) {
    final archive = ZipDecoder().decodeBytes(bytes);
    // Before anything is inflated (zip bombs, W-06).
    ArchiveLimits.standard.check(archive);
    final mdFiles =
        archive.files
            .where(
              (f) =>
                  f.isFile &&
                  {
                    'md',
                    'markdown',
                    'mdown',
                    'mkd',
                  }.contains(f.name.split('.').last.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.length.compareTo(b.name.length));
    if (mdFiles.isEmpty) {
      throw const ImportFormatException(
        'The zip file contains no Markdown file',
      );
    }
    final main = mdFiles.first;
    final dir = main.name.contains('/')
        ? main.name.substring(0, main.name.lastIndexOf('/') + 1)
        : '';
    var counter = 0;
    ImportedImage? resolve(String src) {
      final path = Uri.decodeFull(src.split('#').first.split('?').first);
      final normalized = _normalizePath('$dir$path');
      final file = archive.files
          .where((f) => f.isFile && f.name == normalized)
          .firstOrNull;
      if (file == null) return null;
      final ext = normalized.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'svg' => 'image/svg+xml',
        _ => null,
      };
      if (mime == null) return null;
      return ImportedImage(
        tempId: 'zip${counter++}',
        // A view of the inflated part (cached by the archive): referencing
        // an image many times does not copy it.
        bytes: file.content,
        mime: mime,
      );
    }

    final text = ImportTextDecoder.decode(main.content).text;
    return const MarkdownCodec().importMarkdown(
      text,
      options: _flavored(text, options),
      resolveImage: resolve,
    );
  }

  static String _normalizePath(String p) {
    final out = <String>[];
    for (final seg in p.split('/')) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        if (out.isNotEmpty) out.removeLast();
      } else {
        out.add(seg);
      }
    }
    return out.join('/');
  }

  /// [options] reading [markdown] as Wonky Markdown when it has directives
  /// and detection is on.
  static ImportOptions _flavored(String markdown, ImportOptions options) =>
      options.detectFlavor && looksLikeWonkyMarkdown(markdown)
      ? options.withFlavor(MarkdownFlavor.wonky)
      : options;

  static ImportResult _withWarnings(
    ImportResult r,
    List<ImportWarning> extra,
  ) => ImportResult(
    delta: r.delta,
    warnings: [...extra, ...r.warnings],
    title: r.title,
    frontMatter: r.frontMatter,
    language: r.language,
    images: r.images,
    pageSetup: r.pageSetup,
    markdownFlavor: r.markdownFlavor,
  );
}

/// Uploads imported images and rewrites `import-image://<tempId>` sources
/// to `wonky-file://<fileUuid>` (07 §2.2).
abstract final class ImportPostProcessor {
  /// Processes [result] with [upload] (returns the file UUID, or `null` /
  /// throws when the upload failed — the image becomes a placeholder
  /// paragraph and a warning is added).
  static Future<ImportResult> process(
    ImportResult result,
    Future<String?> Function(ImportedImage image) upload,
  ) async {
    final uploaded = <String, String?>{};
    for (final img in result.images) {
      try {
        uploaded[img.src] = await upload(img);
      } on Object {
        uploaded[img.src] = null;
      }
    }
    final warnings = [...result.warnings];
    final out = Delta();
    for (final op in result.delta.operations) {
      final embed = WonkyEmbed.tryParse(op.data);
      if (embed is ImageEmbed &&
          embed.src.startsWith(ImageEmbed.importImageScheme)) {
        final uuid = uploaded[embed.src];
        if (uuid == null) {
          warnings.add(
            ImportWarning(
              ImportWarningKind.unresolvedImage,
              'Image "${embed.alt}" could not be uploaded',
            ),
          );
          out.insert('[image: ${embed.alt}]', null);
        } else {
          out.insert(
            embed
                .copyWith(src: '${ImageEmbed.wonkyFileScheme}$uuid')
                .toInsert(),
            op.attributes,
          );
        }
        continue;
      }
      out.push(op);
    }
    return ImportResult(
      delta: const WonkyDeltaNormalizer().normalize(out).document,
      warnings: warnings,
      title: result.title,
      frontMatter: result.frontMatter,
      language: result.language,
      pageSetup: result.pageSetup,
      markdownFlavor: result.markdownFlavor,
    );
  }
}
