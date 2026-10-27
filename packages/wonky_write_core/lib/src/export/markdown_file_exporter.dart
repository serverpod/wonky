/// Markdown and Markdown + images (zip) exporters (07 §5.1).
library;

import 'dart:convert';
import 'dart:typed_data';

import '../ir/anchors.dart';
import '../ir/doc_tree.dart';
import '../ir/doc_tree_builder.dart';
import '../markdown/markdown_exporter.dart';
import 'export_api.dart';
import 'zip.dart';

/// Builds the IR for an export (suggestion view, link resolution happens in
/// the format writers).
DocTree exportTree(ExportInput input, ExportOptions options) =>
    const DocTreeBuilder().fromDelta(
      input.document,
      view: options.suggestions,
      meta: input.meta,
    );

/// `.md` exporter.
final class MarkdownFileExporter
    implements DocumentExporter<MarkdownFileExportOptions> {
  /// Creates the exporter. [signedUrl] maps `wonky-file://` sources to
  /// signed URLs for `images: signedUrl` (server); without it the stored
  /// source is kept.
  const MarkdownFileExporter({this.signedUrl});

  /// Signed URL provider.
  final String Function(String src)? signedUrl;

  @override
  ExportFormat get format => ExportFormat.markdown;

  @override
  Future<ExportArtifact> export(
    ExportInput input,
    MarkdownFileExportOptions options,
  ) async {
    input.cancel?.throwIfCancelled();
    final tree = exportTree(input, options);
    final warnings = <ExportWarning>[];
    if (options.images == MarkdownImageMode.signedUrl &&
        tree.images.any((i) => i.src.startsWith('wonky-file://'))) {
      warnings.add(
        const ExportWarning(
          'signed_urls_expire',
          'Image links are signed URLs that expire after 7 days',
        ),
      );
    }
    final md = MarkdownExporter(
      options: MarkdownExportOptions(
        frontMatter: options.frontMatter,
        omitImages: options.images == MarkdownImageMode.omit,
        imageSource: (img) => switch (options.images) {
          MarkdownImageMode.signedUrl
              when img.src.startsWith('wonky-file://') =>
            signedUrl?.call(img.src) ?? img.src,
          _ => img.src,
        },
        linkRewriter: input.links.resolve,
        flavor: input.meta.markdownFlavor,
      ),
    ).export(tree);
    return ExportArtifact(
      fileName: ExportFileNames.fileName(
        options.fileName ?? input.meta.title,
        'md',
      ),
      mimeType: format.mimeType,
      bytes: Uint8List.fromList(utf8.encode(md)),
      warnings: warnings,
    );
  }
}

/// `.zip` exporter: `document.md` + `images/<n>-<slug>.<ext>`.
final class MarkdownZipExporter
    implements DocumentExporter<MarkdownFileExportOptions> {
  /// Creates the exporter.
  const MarkdownZipExporter();

  @override
  ExportFormat get format => ExportFormat.markdownZip;

  @override
  Future<ExportArtifact> export(
    ExportInput input,
    MarkdownFileExportOptions options,
  ) async {
    final tree = exportTree(input, options);
    final warnings = <ExportWarning>[];
    final entries = <ZipEntry>[];
    final paths = <String, String>{}; // src → relative path
    var n = 0;
    for (final img in tree.images) {
      if (paths.containsKey(img.src)) continue;
      input.cancel?.throwIfCancelled();
      final resolved = await input.images.resolve(img.src);
      if (resolved == null) {
        warnings.add(
          ExportWarning(
            'image_unavailable',
            'Image "${img.alt}" could not be loaded',
          ),
        );
        continue;
      }
      n++;
      final slug = AnchorIdGenerator.slugify(
        img.alt.isEmpty ? 'image' : img.alt,
      );
      final path = 'images/$n-$slug.${imageExtension(resolved.mime)}';
      paths[img.src] = path;
      entries.add(ZipEntry(path, resolved.bytes, store: true));
    }
    final md = MarkdownExporter(
      options: MarkdownExportOptions(
        frontMatter: options.frontMatter,
        imageSource: (img) => paths[img.src] ?? img.src,
        linkRewriter: input.links.resolve,
        flavor: input.meta.markdownFlavor,
      ),
    ).export(tree);
    entries.add(ZipEntry.text('document.md', md));
    return ExportArtifact(
      fileName: ExportFileNames.fileName(
        options.fileName ?? input.meta.title,
        'zip',
      ),
      mimeType: format.mimeType,
      bytes: DeterministicZip.encode(
        entries,
        modified: input.meta.modifiedAt,
        first: const ['document.md'],
      ),
      warnings: warnings,
    );
  }
}

/// File extension for an image MIME type.
String imageExtension(String mime) => switch (mime) {
  'image/jpeg' || 'image/jpg' => 'jpg',
  'image/gif' => 'gif',
  'image/webp' => 'webp',
  'image/bmp' => 'bmp',
  'image/svg+xml' => 'svg',
  _ => 'png',
};
