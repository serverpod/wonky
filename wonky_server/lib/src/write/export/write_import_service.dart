import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/isolate_runner.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/config/wonky_config.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/files/file_service.dart';
import '../ot/document_store.dart';
import '../../platform/storage/content_sizes.dart';
import '../../platform/storage/storage_hooks.dart';
import '../../platform/storage/storage_service.dart';

/// Server-side document imports (Write 07 §3.2): Markdown (and Markdown
/// zips), plain text, HTML, DOCX, ODT and RTF are converted with the shared
/// `wonky_write_core` importers in a separate isolate (60 s), embedded
/// images are stored as files of the new document, the source page
/// geometry becomes its page setup, and the warnings are kept for the
/// import banner.
abstract final class WriteImportService {
  /// File extensions (and `format` names) imported as documents.
  static const formats = {
    'md',
    'markdown',
    'mdown',
    'mkd',
    'mkdn',
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

  static const conversionTimeout = Duration(seconds: 60);

  /// The core format for a format name / extension (`null` = detect).
  static core.ImportFormat? formatOf(String? name) =>
      switch (name?.toLowerCase().trim()) {
        'md' ||
        'markdown' ||
        'mdown' ||
        'mkd' ||
        'mkdn' => core.ImportFormat.markdown,
        'txt' || 'text' => core.ImportFormat.txt,
        'html' || 'htm' || 'xhtml' => core.ImportFormat.html,
        'docx' => core.ImportFormat.docx,
        'odt' => core.ImportFormat.odt,
        'rtf' => core.ImportFormat.rtf,
        _ => null,
      };

  /// Converts [bytes] (isolate, [conversionTimeout]); maps core import
  /// errors to `WonkyException`s.
  static Future<core.ImportResult> convert(
    Uint8List bytes, {
    required String fileName,
    String? format,
    Map<String, dynamic> options = const {},
  }) async {
    final explicit = format == null || format == 'auto' || format == 'zip'
        ? null
        : formatOf(format);
    if (format != null &&
        format != 'auto' &&
        explicit == null &&
        format != 'zip') {
      throw Errors.invalid('Files of type "$format" cannot be imported.');
    }
    final soft = (options['lineBreaks'] ?? options['line_breaks']) == 'soft';
    final maxChars = WonkyConfig.current.maxDocumentChars;
    try {
      return await IsolateRunner.run(
        () =>
            core.WonkyImporters(
              limits: core.ImportLimits(
                maxInputBytes: core.ImportLimits.serverMaxInputBytes,
                maxResultChars: maxChars,
              ),
            ).import(
              bytes,
              core.ImportOptions(
                fileName: fileName,
                txtLineBreaks: soft
                    ? core.TxtLineBreaks.soft
                    : core.TxtLineBreaks.paragraph,
              ),
              format: explicit,
            ),
        name: 'write-import',
        timeout: conversionTimeout,
      );
    } on TimeoutException {
      throw Errors.unavailable(
        'Converting the file took too long. Try a smaller file.',
      );
    } on core.ImportTooLargeException {
      throw Errors.tooLarge(
        'The file is too large to import. Split it into smaller files.',
      );
    } on core.ImportFormatException catch (e) {
      throw Errors.invalid(e.message);
    }
  }

  /// Stores the images of [result] (owned by [actor], attached to
  /// [itemId] when given) and rewrites their sources to `wonky-file://`.
  static Future<(core.ImportResult, List<StoredFile>)> storeImages(
    Session session,
    Actor actor,
    core.ImportResult result, {
    int? itemId,
  }) async {
    final stored = <StoredFile>[];
    final maxBytes = WonkyConfig.current.maxImageUploadBytes;
    final processed = await core.ImportPostProcessor.process(result, (
      image,
    ) async {
      if (image.bytes.length > maxBytes) return null;
      final ext = switch (image.mime) {
        'image/jpeg' => 'jpg',
        'image/gif' => 'gif',
        'image/webp' => 'webp',
        'image/bmp' => 'bmp',
        _ => 'png',
      };
      final file = await FileService.storeServerFile(
        session,
        ownerId: actor.userId,
        itemId: itemId,
        kind: StoredFileKind.image,
        fileName: 'imported-${stored.length + 1}.$ext',
        mimeType: image.mime,
        bytes: image.bytes,
      );
      stored.add(file);
      return file.fileUuid.uuid;
    });
    return (processed, stored);
  }

  /// Warnings in the protocol shape.
  static List<ImportWarningView> warningsOf(core.ImportResult r) => [
    for (final w in r.warnings)
      ImportWarningView(kind: w.kind.name, message: w.message, line: w.line),
  ];

  /// Imports [bytes] of [file] as a new document (`drive.import`).
  static Future<ImportReportView> importDocument(
    Session session,
    Actor actor,
    StoredFile file,
    Uint8List bytes,
    String format,
    DriveImportOptions options,
  ) => importBytes(
    session,
    actor,
    bytes,
    fileName: file.fileName,
    format: format,
    name: options.name,
    parentUuid: options.parentUuid,
    options: _options(options.optionsJson),
  );

  /// Converts [bytes] (any of [formats]) and creates a new document from
  /// them, storing embedded images and the import warnings. Shared by
  /// `drive.import` and the MCP `drive.import` tool.
  static Future<ImportReportView> importBytes(
    Session session,
    Actor actor,
    Uint8List bytes, {
    required String fileName,
    required String format,
    String? name,
    UuidValue? parentUuid,
    Map<String, dynamic> options = const {},
    Map<String, Object?> activityExtra = const {},
    String quotaReason = QuotaReason.import,
  }) async {
    // (v2) Quota (Drive 03 §7.2): the source size before the work, the
    // real content size (text + images) before anything is stored.
    await StorageHooks.checkCaller(session, actor, bytes.length, quotaReason);
    final converted = await convert(
      bytes,
      fileName: fileName,
      format: format,
      options: options,
    );
    await StorageHooks.checkCaller(
      session,
      actor,
      DocumentSize.of(converted.delta) +
          converted.images.fold<int>(0, (n, i) => n + i.bytes.length),
      quotaReason,
    );
    final (result, images) = await storeImages(session, actor, converted);
    final warnings = warningsOf(result);
    final docName = _name(name, result, fileName);
    final setup = result.pageSetup == null
        ? null
        : core.ImportedPageSetups.toPageSetup(result.pageSetup!);
    final now = nowUtc();
    final view = await DriveService.createDocumentFromContent(
      session,
      actor,
      name: docName,
      parentUuid: parentUuid,
      content: result.delta,
      frontMatter: result.frontMatter,
      // Carries language and page setup into the new document.
      source: Document(
        uuid: const Uuid().v7obj(),
        itemId: 0,
        pageSetupJson: setup == null ? '{}' : jsonEncode(setup.toJson()),
        language: result.language,
        frontMatter: result.frontMatter,
        createdAt: now,
        updatedAt: now,
      ),
      activitySummary: {
        'importedFrom': _sourceFormat(format, fileName),
        ...activityExtra,
      },
      quotaReason: null, // checked above
    );
    final doc = await DocumentStore.byUuid(session, view.contentRef!);
    if (doc != null) {
      final item = await DriveItem.db.findById(session, doc.itemId);
      if (item != null) {
        // The imported images count for the new document's owner.
        await StorageHooks.attachImages(session, item, images);
      }
      if (warnings.isNotEmpty) {
        await DocumentImportReport.db.insertRow(
          session,
          DocumentImportReport(
            documentId: doc.id!,
            userId: actor.userId,
            warningsJson: jsonEncode([for (final w in warnings) w.toJson()]),
            createdAt: now,
          ),
        );
      }
    }
    return ImportReportView(item: view, warnings: warnings);
  }

  static Map<String, dynamic> _options(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      final v = jsonDecode(json);
      return v is Map<String, dynamic> ? v : const {};
    } on FormatException {
      return const {};
    }
  }

  static String _name(String? explicit, core.ImportResult r, String fileName) {
    String? clean(String? s) {
      final t = s?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    final dot = fileName.lastIndexOf('.');
    final base = clean(dot > 0 ? fileName.substring(0, dot) : fileName);
    final name =
        clean(explicit) ??
        clean(core.FrontMatter.title(r.frontMatter)) ??
        clean(r.title) ??
        base ??
        'Imported document';
    return name.length > 255 ? name.substring(0, 255) : name;
  }

  static String _sourceFormat(String format, String fileName) {
    final f = formatOf(format);
    if (f != null) return f == core.ImportFormat.markdown ? 'md' : f.name;
    final dot = fileName.lastIndexOf('.');
    return dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : 'md';
  }
}
