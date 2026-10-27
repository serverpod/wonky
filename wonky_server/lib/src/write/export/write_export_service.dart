import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../platform/activity/activity_service.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/isolate_runner.dart';
import '../../platform/common/json.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/files/file_service.dart';
import '../ot/document_service.dart';
import '../ot/document_store.dart';
import '../../platform/users/user_service.dart';
import 'server_fonts.dart';
import 'server_images.dart';
import 'write_import_service.dart';

/// Server-side Write exports (Write 07 §10): every format (md, md_zip, pdf,
/// html, html_zip, docx, odt, rtf, epub, txt) is produced by the shared
/// `wonky_write_core` exporters, with the document's theme and page setup,
/// fonts from `web/fonts` ([FileSystemFontProvider]) and images read from
/// storage ([ServerImageResolver]), so results equal client-side exports.
abstract final class WriteExportService {
  static const resultLifetime = Duration(hours: 24);
  static const inlineLimit = 1024 * 1024;
  static const maxConcurrentPerUser = 2;
  static const exportTimeout = Duration(seconds: 120);

  /// Font provider of server exports (tests may replace it).
  static core.FontProvider fonts = FileSystemFontProvider.instance;

  /// Remote image fetcher (tests may replace it).
  static Future<Uint8List> Function(String src) fetchRemoteImage =
      SafeImageFetcher.fetch;

  static final Map<int, int> _running = {};

  /// Formats available on the server by MCP name (all of them). Kept for
  /// callers that probe availability with `containsKey`.
  static final Map<String, core.ExportFormat> exporters = {
    for (final f in core.ExportFormat.values) f.mcpName: f,
  };

  /// Accepted format names: MCP names plus the app's ids and aliases.
  static core.ExportFormat? formatOf(String name) {
    final n = name.toLowerCase().trim();
    return core.ExportFormat.fromMcpName(n) ??
        switch (n) {
          'markdown' => core.ExportFormat.markdown,
          'mdzip' || 'markdown_zip' => core.ExportFormat.markdownZip,
          'htmlzip' || 'web_zip' => core.ExportFormat.htmlZip,
          'text' => core.ExportFormat.txt,
          'word' => core.ExportFormat.docx,
          _ => null,
        };
  }

  /// Options JSON with camelCase keys converted to the exporters'
  /// snake_case (`includeToc` → `include_toc`).
  static Map<String, dynamic> normalizeOptions(Map<String, Object?> raw) => {
    for (final e in raw.entries)
      e.key.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      ): e.value,
  };

  static Future<ExportResultView> export(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    String format,
    String optionsJson, {
    int? revision,
    void Function(String phase, double progress)? onProgress,
    IsolateCancelToken? cancel,
  }) async {
    final (doc, item, role) = await DocumentService.require(
      session,
      actor,
      documentUuid,
    );
    if (role < Role.editor && !item.nonEditorsCanExport) {
      throw Errors.forbidden('The owner has disabled downloads for viewers.');
    }
    if (revision != null &&
        revision != doc.headRevision &&
        role < Role.editor) {
      throw Errors.forbidden('Exporting older versions requires edit access.');
    }
    final fmt = formatOf(format);
    if (fmt == null) {
      throw Errors.invalid('Unknown export format "$format".');
    }
    final running = _running[actor.userId] ?? 0;
    if (running >= maxConcurrentPerUser) {
      throw Errors.busy('Wait for your other exports to finish.');
    }
    _running[actor.userId] = running + 1;
    try {
      onProgress?.call('loading', 0.05);
      final rev = revision ?? doc.headRevision;
      final content = await DocumentStore.contentAt(session, doc, rev);
      final options = normalizeOptions(decodeObject(optionsJson));
      final input = await _input(
        session,
        actor,
        doc,
        item,
        content,
        rev,
        options,
      );
      final core.ExportArtifact artifact;
      try {
        artifact = await _run(
          session,
          actor,
          fmt,
          input,
          options,
          cancel: cancel,
          onProgress: onProgress,
        );
      } on TimeoutException {
        throw Errors.unavailable(
          'The export took too long. Try a smaller document or format.',
        );
      } on IsolateCancelledException {
        throw Errors.unavailable('The export was cancelled.');
      } on core.ExportCancelledException {
        throw Errors.unavailable('The export was cancelled.');
      }
      final bytes = artifact.bytes;
      final text =
          fmt == core.ExportFormat.markdown || fmt == core.ExportFormat.txt
          ? utf8.decode(bytes, allowMalformed: true)
          : null;
      onProgress?.call('uploading', 0.9);
      final expires = nowUtc().add(resultLifetime);
      final file = await FileService.storeServerFile(
        session,
        ownerId: actor.userId,
        itemId: item.id,
        kind: StoredFileKind.exportResult,
        fileName: artifact.fileName,
        mimeType: artifact.mimeType.split(';').first,
        bytes: bytes,
        expiresAt: expires,
      );
      final url = await FileService.getUrl(session, actor, file.fileUuid);
      await ActivityService.log(
        session,
        item.id!,
        actor,
        ActivityType.exported,
        summary: {'format': fmt.mcpName},
      );
      onProgress?.call('done', 1);
      return ExportResultView(
        fileName: artifact.fileName,
        mimeType: artifact.mimeType,
        sizeBytes: bytes.length,
        pageCount: artifact.pageCount,
        downloadUrl: url.url!,
        expiresAt: url.expiresAt ?? expires,
        inlineText: text != null && bytes.length <= inlineLimit ? text : null,
        warnings: [
          for (final w in artifact.warnings)
            ImportWarningView(kind: w.code, message: w.message),
        ],
      );
    } finally {
      final left = (_running[actor.userId] ?? 1) - 1;
      if (left <= 0) {
        _running.remove(actor.userId);
      } else {
        _running[actor.userId] = left;
      }
    }
  }

  /// Exports [content] of [doc] as [format] without storing the result
  /// (MCP, tests).
  static Future<core.ExportArtifact> exportBytes(
    Session session,
    Actor actor,
    Document doc,
    DriveItem item,
    core.Delta content,
    core.ExportFormat format,
    Map<String, dynamic> options, {
    int? revision,
  }) async {
    final input = await _input(
      session,
      actor,
      doc,
      item,
      content,
      revision ?? doc.headRevision,
      options,
    );
    return _run(session, actor, format, input, options);
  }

  /// Runs the exporter of [format] in a worker isolate (the shared
  /// `IsolateRunner`: killed after [exportTimeout] or on [cancel], global
  /// slots). Images are resolved here, on the request isolate, through
  /// the channel; Markdown's signed image URLs are made before.
  static Future<core.ExportArtifact> _run(
    Session session,
    Actor actor,
    core.ExportFormat format,
    core.ExportInput input,
    Map<String, dynamic> options, {
    IsolateCancelToken? cancel,
    void Function(String phase, double progress)? onProgress,
  }) async {
    var signed = const <String, String>{};
    if (format == core.ExportFormat.markdown &&
        core.MarkdownFileExportOptions.fromJson(options).images ==
            core.MarkdownImageMode.signedUrl) {
      signed = await _signedImageUrls(session, actor, input.document);
    }
    final images = input.images;
    final fonts = WriteExportService.fonts;
    return IsolateRunner.runWithChannel(
      _exportWork(
        format,
        _WorkerInput.of(input),
        options,
        signed,
        // The process-wide provider caches futures; the worker reads the
        // same directory itself.
        fonts is FileSystemFontProvider ? fonts.directory.path : fonts,
      ),
      name: 'write-export',
      timeout: exportTimeout,
      cancel: cancel,
      onRequest: (src) => images.resolve(src! as String),
      onMessage: (m) {
        if (m case (final String phase, final double p)) {
          onProgress?.call(phase, 0.1 + p * 0.7);
        }
      },
    );
  }

  /// Signed URLs of the document's `wonky-file` images the actor can read
  /// (Markdown export with `images: signed_url`).
  static Future<Map<String, String>> _signedImageUrls(
    Session session,
    Actor actor,
    core.Delta document,
  ) async {
    final signed = <String, String>{};
    final tree = const core.DocTreeBuilder().fromDelta(document);
    for (final image in tree.images) {
      final src = image.src;
      if (!src.startsWith(core.ImageEmbed.wonkyFileScheme) ||
          signed.containsKey(src)) {
        continue;
      }
      try {
        final view = await FileService.getUrl(
          session,
          actor,
          UuidValue.withValidation(
            src.substring(core.ImageEmbed.wonkyFileScheme.length),
          ),
        );
        if (view.url != null) signed[src] = view.url!;
      } on Object {
        // Not readable: keep the wonky-file link.
      }
    }
    return signed;
  }

  /// The worker of [_run]. A separate function, so the closure captures
  /// only these arguments (never the session). [fonts] is a font directory
  /// path or a provider.
  static FutureOr<core.ExportArtifact> Function(IsolateChannel) _exportWork(
    core.ExportFormat format,
    _WorkerInput input,
    Map<String, dynamic> options,
    Map<String, String> signed,
    Object fonts,
  ) =>
      (channel) => runExporter(
        format,
        input.build(
          images: _ChannelImageResolver(channel),
          fonts: fonts is String
              ? FileSystemFontProvider(directory: Directory(fonts))
              : fonts as core.FontProvider,
          progress: (phase, p) => channel.post((phase.name, p)),
        ),
        options,
        signedUrls: signed,
      );

  /// Runs the core exporter of [format] on [input] (any isolate).
  static Future<core.ExportArtifact> runExporter(
    core.ExportFormat format,
    core.ExportInput input,
    Map<String, dynamic> options, {
    Map<String, String> signedUrls = const {},
  }) async {
    switch (format) {
      case core.ExportFormat.markdown:
        return core.MarkdownFileExporter(
          signedUrl: (src) => signedUrls[src] ?? src,
        ).export(input, core.MarkdownFileExportOptions.fromJson(options));
      case core.ExportFormat.markdownZip:
        return const core.MarkdownZipExporter().export(
          input,
          core.MarkdownFileExportOptions.fromJson(options),
        );
      case core.ExportFormat.pdf:
        return const core.PdfExporter().export(
          input,
          core.PdfExportOptions.fromJson(options),
        );
      case core.ExportFormat.html:
        return const core.HtmlExporter().export(
          input,
          core.HtmlExportOptions.fromJson(options),
        );
      case core.ExportFormat.htmlZip:
        return const core.HtmlZipExporter().export(
          input,
          core.HtmlExportOptions.fromJson(options),
        );
      case core.ExportFormat.docx:
        return const core.DocxExporter().export(
          input,
          core.OfficeExportOptions.fromJson(options),
        );
      case core.ExportFormat.odt:
        return const core.OdtExporter().export(
          input,
          core.OfficeExportOptions.fromJson(options),
        );
      case core.ExportFormat.rtf:
        return const core.RtfExporter().export(
          input,
          core.RtfExportOptions.fromJson(options),
        );
      case core.ExportFormat.epub:
        return const core.EpubExporter().export(
          input,
          core.EpubExportOptions.fromJson(options),
        );
      case core.ExportFormat.txt:
        return const core.TxtExporter().export(
          input,
          core.TxtExportOptions.fromJson(options),
        );
    }
  }

  static Future<core.ExportInput> _input(
    Session session,
    Actor actor,
    Document doc,
    DriveItem item,
    core.Delta content,
    int revision,
    Map<String, dynamic> options,
  ) async {
    final owner = await UserService.summary(session, item.ownerId);
    final theme = await _theme(session, actor, doc);
    core.PageSetup setup;
    try {
      final json = jsonDecode(doc.pageSetupJson);
      setup = json is Map<String, dynamic>
          ? core.PageSetup.fromJson(json)
          : const core.PageSetup();
    } on Object {
      setup = const core.PageSetup();
    }
    final web = session.serverpod.config.webServer;
    final origin = web == null
        ? ''
        : Uri(
            scheme: web.publicScheme,
            host: web.publicHost,
            port: web.publicPort,
          ).origin;
    return core.ExportInput(
      document: content,
      revision: revision,
      meta: core.DocMeta(
        documentUuid: doc.uuid.uuid,
        title: item.name,
        authorName:
            core.FrontMatter.field(doc.frontMatter, 'author') ??
            owner?.displayName,
        language: doc.language,
        frontMatter: doc.frontMatter,
        description: item.description,
        createdAt: doc.createdAt,
        modifiedAt: doc.updatedAt,
        markdownFlavor: core.MarkdownFlavor.parse(doc.markdownFlavor),
      ),
      theme: theme,
      variant: options['variant'] == 'dark'
          ? core.ThemeVariant.dark
          : core.ThemeVariant.light,
      pageSetup: setup,
      images: ServerImageResolver(
        session,
        actor,
        itemId: item.id!,
        fetchRemote: fetchRemoteImage,
      ),
      fonts: fonts,
      links: origin.isEmpty
          ? const core.IdentityLinkResolver()
          : core.DefaultLinkResolver(
              origin: origin,
              documentUuid: doc.uuid.uuid,
            ),
      locale: options['locale'] as String? ?? 'en-US',
      now: nowUtc(),
    );
  }

  /// The document's theme: its assigned theme, else the actor's default
  /// theme, else *Wonky Default*.
  static Future<core.WriteThemeData> _theme(
    Session session,
    Actor actor,
    Document doc,
  ) async {
    Future<core.WriteThemeData?> load(String? uuid) async {
      if (uuid == null) return null;
      final builtin = core.BuiltinThemes.byUuid(uuid);
      if (builtin != null) return builtin.theme;
      final row = await WriteTheme.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(UuidValue.withValidation(uuid)),
      );
      if (row == null) return null;
      try {
        return core.WriteThemeData.fromJsonString(row.json);
      } on Object {
        return null;
      }
    }

    final assigned = await load(doc.themeId?.uuid);
    if (assigned != null) return assigned;
    try {
      final prefs = await UserService.preferences(session, actor);
      final defaults = decodeObject(prefs.writeDefaults);
      final id = (defaults['defaultThemeId'] ?? defaults['themeUuid']);
      final preferred = await load(id is String ? id : null);
      if (preferred != null) return preferred;
    } on Object {
      // Fall through to the built-in default.
    }
    return core.BuiltinThemes.wonkyDefault.theme;
  }

  static Stream<ExportProgressEvent> exportWithProgress(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    String format,
    String optionsJson, {
    int? revision,
  }) {
    // Cancelling the subscription kills the export's isolate.
    final cancel = IsolateCancelToken();
    final controller = StreamController<ExportProgressEvent>(
      onCancel: cancel.cancel,
    );
    void add(ExportProgressEvent e) {
      if (!controller.isClosed) controller.add(e);
    }

    unawaited(() async {
      try {
        final result = await export(
          session,
          actor,
          documentUuid,
          format,
          optionsJson,
          revision: revision,
          cancel: cancel,
          onProgress: (phase, progress) {
            if (controller.isClosed) return;
            controller.add(
              ExportProgressEvent(
                kind: ExportProgressKind.phase,
                phase: phase,
                progress: progress,
              ),
            );
          },
        );
        add(ExportProgressEvent(kind: ExportProgressKind.done, result: result));
      } on WonkyException catch (e) {
        add(
          ExportProgressEvent(
            kind: ExportProgressKind.error,
            errorCode: e.code.name,
            message: e.message,
          ),
        );
      } on Object catch (e, st) {
        session.log(
          'Write export failed: $e',
          level: LogLevel.error,
          exception: e,
          stackTrace: st,
        );
        add(
          ExportProgressEvent(
            kind: ExportProgressKind.error,
            errorCode: WonkyErrorCode.unavailable.name,
            message: 'The export failed.',
          ),
        );
      } finally {
        await controller.close();
      }
    }());
    return controller.stream;
  }

  /// Converts an uploaded file for *Import into this document* (Write 07
  /// §3.1): any importable format; images are stored as files of the
  /// target document (`documentUuid` in [optionsJson], Editor+ required)
  /// or of the caller.
  static Future<ConvertForInsertResult> convertForInsert(
    Session session,
    Actor actor,
    UuidValue uploadId,
    String format,
    String optionsJson,
  ) async {
    final file = await FileService.requireOwnReadyFile(
      session,
      actor,
      uploadId,
      kind: StoredFileKind.importSource,
    );
    final options = decodeObject(optionsJson);
    DriveItem? target;
    core.MarkdownFlavor? flavor;
    final targetUuid = options['documentUuid'] ?? options['document_uuid'];
    if (targetUuid is String) {
      final (doc, item, role) = await DocumentService.require(
        session,
        actor,
        UuidValue.withValidation(targetUuid),
      );
      if (role < Role.editor) {
        throw Errors.forbidden('Inserting files requires edit access.');
      }
      target = item;
      flavor = core.MarkdownFlavor.parse(doc.markdownFlavor);
    }
    final data = await FileService.readBytes(session, file);
    final converted = await WriteImportService.convert(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      fileName: file.fileName,
      format: format.isEmpty ? null : format,
      options: Map<String, dynamic>.from(options),
      flavor: flavor,
    );
    final (result, _) = await WriteImportService.storeImages(
      session,
      actor,
      converted,
      itemId: target?.id,
    );
    await FileService.deleteFile(session, file.fileUuid);
    return ConvertForInsertResult(
      deltaJson: jsonEncode(result.delta.toJson()),
      warnings: WriteImportService.warningsOf(result),
    );
  }

  /// Proxy for remote images blocked by CORS during client exports
  /// (SSRF-protected, see [SafeImageFetcher]).
  static Future<ByteData> fetchImage(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    String src,
  ) async {
    await DocumentService.require(session, actor, documentUuid);
    return ByteData.sublistView(await fetchRemoteImage(src));
  }
}

/// The sendable part of a [core.ExportInput] (everything but the
/// resolvers and sinks that need the request isolate).
final class _WorkerInput {
  _WorkerInput.of(core.ExportInput i)
    : document = i.document,
      revision = i.revision,
      meta = i.meta,
      theme = i.theme,
      variant = i.variant,
      pageSetup = i.pageSetup,
      links = i.links,
      locale = i.locale,
      now = i.now;

  final core.Delta document;
  final int revision;
  final core.DocMeta meta;
  final core.WriteThemeData theme;
  final core.ThemeVariant variant;
  final core.PageSetup pageSetup;
  final core.LinkResolver links;
  final String locale;
  final DateTime now;

  core.ExportInput build({
    required core.ImageResolver images,
    required core.FontProvider fonts,
    required core.ExportProgressSink progress,
  }) => core.ExportInput(
    document: document,
    revision: revision,
    meta: meta,
    theme: theme,
    variant: variant,
    pageSetup: pageSetup,
    images: images,
    fonts: fonts,
    links: links,
    locale: locale,
    now: now,
    progress: progress,
  );
}

/// [core.ImageResolver] of the export isolate: asks the request isolate
/// ([ServerImageResolver] there).
final class _ChannelImageResolver implements core.ImageResolver {
  _ChannelImageResolver(this.channel);

  final IsolateChannel channel;

  @override
  Future<core.ResolvedImage?> resolve(String src) async {
    try {
      return await channel.request(src) as core.ResolvedImage?;
    } on Object {
      return null;
    }
  }
}
