import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show
        DriveImportOptions,
        DriveItemKind,
        DriveItemView,
        StoredFileKind,
        UuidValue;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../l10n/write_l10n.dart';

/// File types Write imports (Write 07 §3): Markdown (and Markdown zips from
/// our *Markdown with images* export), text, HTML, Word, OpenDocument and
/// RTF.
const writeImportExtensions = {
  'md',
  'markdown',
  'mdown',
  'mkd',
  'txt',
  'text',
  'html',
  'htm',
  'xhtml',
  'docx',
  'odt',
  'rtf',
  'zip',
};

/// MIME type of an import source by extension (upload metadata).
String importMimeType(String fileName) {
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  return switch (ext) {
    'md' || 'markdown' || 'mdown' || 'mkd' => 'text/markdown',
    'txt' || 'text' => 'text/plain',
    'html' || 'htm' => 'text/html',
    'xhtml' => 'application/xhtml+xml',
    'docx' => ExportFormat.docx.mimeType,
    'odt' => ExportFormat.odt.mimeType,
    'rtf' => 'application/rtf',
    'zip' => 'application/zip',
    _ => 'application/octet-stream',
  };
}

/// Uploads an imported image; returns the stored file UUID or `null`.
typedef ImportImageUploader = Future<String?> Function(ImportedImage image);

/// A converted file, ready to become (or be inserted into) a document.
class ConvertedImport {
  const ConvertedImport({required this.name, required this.result});

  /// Document name (front matter `title`, document title, first heading or
  /// file name).
  final String name;

  /// The import result; image sources are `wonky-file://` when an uploader
  /// was given, else `import-image://` (see [ImportResult.images]).
  final ImportResult result;

  /// The Markdown of the converted document (for `initialMarkdown`).
  String get markdown => const MarkdownCodec().exportMarkdown(
    result.delta,
    frontMatter: result.frontMatter,
    options: MarkdownExportOptions(flavor: result.markdownFlavor),
  );

  List<String> get warnings => [for (final w in result.warnings) w.message];
}

/// Converts [bytes] of [fileName] with the core importers (client limits).
/// With [uploadImage], embedded images are uploaded and referenced as
/// `wonky-file://`; images that cannot be uploaded become placeholders.
/// Without it, images are dropped to placeholders too (an `import-image://`
/// source never enters a document). A file without a usable name becomes
/// "Imported document" in [l] (English by default).
Future<ConvertedImport> convertImport(
  String fileName,
  Uint8List bytes, {
  ImportImageUploader? uploadImage,
  WriteLocalizations? l,
  MarkdownFlavor? flavor,
}) async {
  // Into a document: its flavor; a new document: Markdown with directives
  // makes a Wonky document (Write 11 §5.1).
  final raw = await const WonkyImporters(limits: ImportLimits.client).import(
    bytes,
    ImportOptions(
      fileName: fileName,
      flavor: flavor ?? MarkdownFlavor.gfm,
      detectFlavor: flavor == null,
    ),
  );
  final result = await ImportPostProcessor.process(
    raw,
    uploadImage ?? (_) async => null,
  );
  final base = fileName.contains('.')
      ? fileName.substring(0, fileName.lastIndexOf('.'))
      : fileName;
  final name =
      FrontMatter.title(result.frontMatter) ??
      (result.title?.trim().isNotEmpty ?? false
          ? result.title!.trim()
          : null) ??
      (base.trim().isEmpty
          ? (l ?? writeL10nEnglish).importDefaultName
          : base.trim());
  return ConvertedImport(name: name, result: result);
}

/// An uploader storing imported images as files of [itemUuid] (the
/// document they are inserted into), or of the user.
ImportImageUploader importImageUploader(
  ShellServices s, {
  UuidValue? itemUuid,
}) => (image) async {
  if (!s.connectivity.online) return null;
  final ext = switch (image.mime) {
    'image/jpeg' => 'jpg',
    'image/gif' => 'gif',
    'image/webp' => 'webp',
    _ => 'png',
  };
  final view = await s.repositories.files.upload(
    fileUuid: s.ids.next(),
    itemUuid: itemUuid,
    fileName: '${image.alt.isEmpty ? 'image' : image.alt}.$ext',
    mimeType: image.mime,
    bytes: image.bytes,
  );
  return view.fileUuid.uuid;
};

/// Picks importable files (dialog titled in [l], English by default).
Future<List<ImportFile>> pickImportFiles({
  bool multiple = true,
  WriteLocalizations? l,
}) async {
  final t = l ?? writeL10nEnglish;
  final files = multiple
      ? await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: writeImportExtensions.toList(),
          dialogTitle: t.importDialogTitleMany,
        )
      : [
          ?await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: writeImportExtensions.toList(),
            dialogTitle: t.importDialogTitleOne,
          ),
        ];
  return [
    for (final f in files)
      ImportFile(name: f.name, bytes: await f.readAsBytes()),
  ];
}

/// Result of importing one file as a new document.
typedef ImportedDocument = ({DriveItemView item, List<String> warnings});

/// Imports [bytes] as a new document: online through the server pipeline
/// (`drive.import`: images stored with the document, page setup from the
/// source, warnings kept for the banner shown when the document opens);
/// offline (or without a server) converted on the client.
Future<ImportedDocument> importAsDocument(
  ShellServices s,
  String fileName,
  Uint8List bytes, {
  UuidValue? parentUuid,
}) async {
  final client = s.client;
  if (client != null && s.connectivity.online) {
    final upload = await s.repositories.files.upload(
      fileUuid: s.ids.next(),
      fileName: fileName,
      mimeType: importMimeType(fileName),
      bytes: bytes,
      kind: StoredFileKind.importSource,
    );
    final report = await client.drive.import(
      upload.fileUuid,
      DriveItemKind.document,
      DriveImportOptions(parentUuid: parentUuid),
    );
    return (
      item: report.item,
      warnings: [for (final w in report.warnings) w.message],
    );
  }
  final converted = await convertImport(
    fileName,
    bytes,
    uploadImage: importImageUploader(s),
    l: writeL10nOf(s),
  );
  final item = await s.drive.createDocument(
    parentUuid: parentUuid,
    name: converted.name,
    initialMarkdown: converted.markdown,
  );
  return (item: item, warnings: converted.warnings);
}

/// Imports Write files as new documents on the home screen
/// (`shell.file.import`, drag and drop, Write 07 §3.1).
class WriteImportHandler implements ImportHandler {
  const WriteImportHandler();

  @override
  Set<String> get extensions => writeImportExtensions;

  @override
  Future<List<ImportFile>> pickFiles(BuildContext context) =>
      pickImportFiles(l: writeL10n(context));

  @override
  Future<List<DriveItemView>> importFiles(
    BuildContext context,
    ShellServices services,
    List<ImportFile> files, {
    UuidValue? parentUuid,
  }) async {
    final l = writeL10nOf(services);
    final created = <DriveItemView>[];
    final problems = <String>[];
    // Drive 03 §7.2: client-side pre-check of the imported bytes (the
    // server checks again; offline imports aren't blocked).
    final bytes = files
        .where((f) => writeImportExtensions.contains(f.extension))
        .fold<int>(0, (n, f) => n + f.bytes.length);
    if (!await services.storageChecks.ensureRoom(
      bytes,
      reason: QuotaReasons.import,
    )) {
      return created;
    }
    for (final f in files) {
      if (!writeImportExtensions.contains(f.extension)) {
        problems.add(l.importProblemUnsupported(f.name));
        continue;
      }
      try {
        final r = await importAsDocument(
          services,
          f.name,
          Uint8List.fromList(f.bytes),
          parentUuid: parentUuid,
        );
        created.add(r.item);
        if (r.warnings.isNotEmpty) {
          problems.add(l.importProblemInexact(f.name, r.warnings.length));
        }
      } catch (e) {
        // Out of storage: the dialog explains it; the rest won't fit either.
        if (services.quotaErrors.present(e)) break;
        problems.add(l.importProblemFailed(f.name, errorMessage(e)));
      }
    }
    if (created.isNotEmpty) {
      services.toasts.show(
        created.length == 1
            ? l.importToastImportedOne(created.single.name)
            : l.importToastImportedMany(created.length),
        description: problems.isEmpty ? null : problems.join('\n'),
        actionLabel: created.length == 1 ? l.sessionOpen : null,
        onAction: created.length == 1
            ? () => services.openItem(created.single)
            : null,
      );
    } else if (problems.isNotEmpty) {
      services.toasts.error(
        l.importToastFailed,
        description: problems.join('\n'),
      );
    }
    services.refreshDrive();
    return created;
  }
}
