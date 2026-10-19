import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/pdf.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;
import 'package:wonky_slides_core/scene.dart' show SlideImageRef;

import '../../platform/activity/activity_service.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/isolate_runner.dart';
import '../../platform/common/json.dart';
import '../../platform/common/lru_map.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/files/file_service.dart';
import '../../write/export/server_fonts.dart' show FileSystemFontProvider;
import '../../write/export/server_images.dart' show SafeImageFetcher;
import '../headless/headless_deck.dart';
import '../revlog/slides_revlog.dart';

/// Server-side Slides exports (Slides 10 §11.4–§11.5, `slidesExport`): the
/// deck from the headless cache (Slides 11 §2.1), rendered by the shared
/// pure-Dart `SlidesPdfExporter` with the bundled TTFs of `web/fonts/` (the
/// same files the app embeds, [BundledFileFontProvider]) and images read
/// from storage ([ServerSlideImageResolver]); the PDF is stored as a
/// private `StoredFile(kind: exportResult)` that expires after 24 h (not
/// counted toward quota, Drive D3) and handed out as a signed URL. Equal
/// requests within the lifetime reuse the stored result.
abstract final class SlidesExportService {
  static const resultLifetime = Duration(hours: 24);
  static const maxConcurrentPerUser = 2;
  static const exportTimeout = Duration(seconds: 120);

  /// The fonts version of the result cache key (bump with the font set).
  static const fontsVersion = 'wonky_fonts/1';

  /// Font provider of server exports (tests may replace it).
  static FontProviderFactory fonts = defaultFonts;

  /// Remote image fetcher (tests may replace it).
  static Future<Uint8List> Function(String src) fetchRemoteImage =
      SafeImageFetcher.fetch;

  static final Map<int, int> _running = {};

  /// Recent results by request key (bounded; entries also expire).
  static final LruMap<String, _CachedResult> _results = LruMap(256);

  /// The provider over `web/fonts/` (read once per process).
  static BundledFileFontProvider defaultFonts() =>
      _defaultFonts ??= _filesIn(FileSystemFontProvider.defaultDirectory());
  static BundledFileFontProvider? _defaultFonts;

  static BundledFileFontProvider _filesIn(Directory dir) =>
      BundledFileFontProvider((file) async {
        final f = File('${dir.path}/$file');
        return await f.exists() ? f.readAsBytes() : null;
      });

  /// Accepted formats: `pdf` (PNG and PNG ZIP are P1, 10 §13).
  static const formats = {'pdf'};

  /// Drops cached results (tests).
  static void clearCache() => _results.clear();

  /// Exports deck [itemUuid] as [format] with [optionsJson] (10 §11.1 keys).
  static Future<ExportResultView> export(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String format,
    String optionsJson, {
    int? revision,
    void Function(String phase, double progress)? onProgress,
    IsolateCancelToken? cancel,
  }) async {
    final fmt = format.toLowerCase().trim();
    if (!formats.contains(fmt)) {
      if (fmt == 'png' || fmt == 'pngzip' || fmt == 'png_zip') {
        throw Errors.unavailable('PNG export is not available yet.');
      }
      throw Errors.invalid('Unknown export format "$format".');
    }
    if (revision != null) {
      throw Errors.unavailable(
        'Exporting older versions of a presentation is not available yet.',
      );
    }
    onProgress?.call('loading', 0.02);
    // Read before the model: the model is at least at this revision, so a
    // result is never keyed newer than its content.
    final head = await SlidesRevlog.headRevision(session, itemUuid);
    final deck = await const SlidesHeadlessProvider().open(
      HeadlessDeckContext(session, actor),
      itemUuid.uuid,
    );
    final item = deck.item;
    if (deck.role < Role.editor && !item.nonEditorsCanExport) {
      throw Errors.forbidden('The owner has disabled downloads for viewers.');
    }
    final Map<String, Object?> raw;
    try {
      raw = decodeObject(optionsJson);
    } on Object {
      throw Errors.invalid('The export options are not a JSON object.');
    }
    final options = SlidesPdfOptionsCodec.fromJson(raw);
    final model = deck.model;
    final title = model.deck?.title.isNotEmpty == true
        ? model.deck!.title
        : item.name;
    final fileName =
        '${options.fileName ?? SlidesPdfOptionsCodec.sanitizeFileName(title)}'
        '.pdf';
    // Keyed on the deck's revision (no hash of the whole deck per request).
    final key = sha256
        .convert(
          utf8.encode(
            [
              itemUuid.uuid,
              head,
              item.name,
              item.modifiedAt.toIso8601String(),
              fmt,
              jsonEncode(SlidesPdfOptionsCodec.toJson(options)),
              fontsVersion,
              actor.userId,
            ].join('|'),
          ),
        )
        .toString();

    final cached = await _cached(session, actor, key);
    if (cached != null) {
      await _logExport(session, item, actor, fmt);
      onProgress?.call('done', 1);
      return cached;
    }

    final running = _running[actor.userId] ?? 0;
    if (running >= maxConcurrentPerUser) {
      throw Errors.busy('Wait for your other exports to finish.');
    }
    _running[actor.userId] = running + 1;
    try {
      final owner = await UserProfile.db.findById(session, item.ownerId);
      final images = ServerSlideImageResolver(
        session,
        actor,
        itemId: item.id!,
        fetchRemote: fetchRemoteImage,
        cacheBytes: false,
      );
      // A consistent copy of the live model for the worker isolate.
      final rows = [
        for (final t in SlidesTables.dependencyOrder)
          for (final r in model.records(t)) (t, r.toColumns()),
      ];
      final SlidesPdfResult result;
      try {
        result = await IsolateRunner.runWithChannel(
          _renderWork(
            model.deckId,
            rows,
            options,
            SlidesPdfDocumentInfo(
              title: title,
              author: owner?.displayName,
              subject: item.description,
              modified: item.modifiedAt,
              revision: '$head',
            ),
            fonts,
          ),
          name: 'slides-export',
          timeout: exportTimeout,
          cancel: cancel,
          onRequest: (src) => images.bytes(SlideImageRef(src! as String)),
          onMessage: (m) {
            if (m case (final String phase, final double p)) {
              onProgress?.call(phase, 0.05 + p * 0.85);
            }
          },
        );
      } on TimeoutException {
        throw Errors.unavailable(
          'The export took too long. Try fewer slides or the compact quality.',
        );
      } on IsolateCancelledException {
        throw Errors.unavailable('The export was cancelled.');
      }
      onProgress?.call('uploading', 0.92);
      final bytes = Uint8List.fromList(result.bytes);
      final expires = nowUtc().add(resultLifetime);
      final file = await FileService.storeServerFile(
        session,
        ownerId: actor.userId,
        itemId: item.id,
        kind: StoredFileKind.exportResult,
        fileName: fileName,
        mimeType: 'application/pdf',
        bytes: bytes,
        expiresAt: expires,
      );
      final url = await FileService.getUrl(session, actor, file.fileUuid);
      final view = ExportResultView(
        fileName: fileName,
        mimeType: 'application/pdf',
        sizeBytes: bytes.length,
        pageCount: result.pageCount,
        downloadUrl: url.url!,
        expiresAt: url.expiresAt ?? expires,
        warnings: [
          for (final w in result.warnings)
            ImportWarningView(kind: w, message: warningMessage(w)),
        ],
      );
      _results.put(key, _CachedResult(file.fileUuid, expires, view));
      await _logExport(session, item, actor, fmt);
      onProgress?.call('done', 1);
      return view;
    } finally {
      final left = (_running[actor.userId] ?? 1) - 1;
      if (left <= 0) {
        _running.remove(actor.userId);
      } else {
        _running[actor.userId] = left;
      }
    }
  }

  /// The worker of an export: builds the deck from [rows] and renders it
  /// with images asked from the calling isolate. A separate function, so
  /// the closure captures only these arguments (never the session).
  static FutureOr<SlidesPdfResult> Function(IsolateChannel) _renderWork(
    String deckId,
    List<(String, Map<String, Object?>)> rows,
    SlidesPdfOptions options,
    SlidesPdfDocumentInfo info,
    FontProviderFactory fonts,
  ) =>
      (channel) =>
          SlidesPdfExporter(
            onProgress: (phase, p) => channel.post((phase, p)),
          ).render(
            DeckModel.fromRows(deckId, rows),
            options,
            SlidesExportResources(
              fonts: fonts(),
              images: _ChannelImageResolver(channel),
              info: info,
            ),
          );

  static Future<ExportResultView?> _cached(
    Session session,
    Actor actor,
    String key,
  ) async {
    final hit = _results.get(key);
    if (hit == null) return null;
    if (!hit.expiresAt.isAfter(nowUtc().add(const Duration(minutes: 20)))) {
      _results.remove(key);
      return null;
    }
    final file = await FileService.byUuid(session, hit.fileUuid);
    if (file == null) {
      _results.remove(key);
      return null;
    }
    final url = await FileService.getUrl(session, actor, hit.fileUuid);
    return hit.view.copyWith(
      downloadUrl: url.url!,
      expiresAt: url.expiresAt ?? hit.expiresAt,
    );
  }

  static Future<void> _logExport(
    Session session,
    DriveItem item,
    Actor actor,
    String format,
  ) => ActivityService.log(
    session,
    item.id!,
    actor,
    ActivityType.exported,
    summary: {'format': format},
  );

  /// The user-facing text of an export warning code.
  static String warningMessage(String code) => switch (code) {
    'font_fallback' =>
      'A font could not be embedded; a standard font was used.',
    'glyph_missing' => 'Some characters have no glyph in the embedded fonts.',
    'icon_unavailable' => 'Some icons could not be drawn.',
    'image_missing' => 'Some images could not be loaded.',
    'image_invalid' => 'Some images could not be decoded.',
    'image_limit' => 'The presentation has more images than an export allows.',
    'link_dropped' => 'Links to slides that are not exported were removed.',
    'page_limit' => 'Only the first 500 pages were exported.',
    'range_unresolved' =>
      'The current slide or selection is only known in '
          'the app; every slide was exported.',
    'empty_selection' => 'No slides matched the options.',
    _ => code,
  };

  /// Progress events; the last one is `done` or `error` (10 §11.5).
  /// Cancelling the subscription kills the render.
  static Stream<ExportProgressEvent> exportWithProgress(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String format,
    String optionsJson, {
    int? revision,
  }) {
    final cancel = IsolateCancelToken();
    final controller = StreamController<ExportProgressEvent>(
      onCancel: cancel.cancel,
    );
    unawaited(() async {
      try {
        final result = await export(
          session,
          actor,
          itemUuid,
          format,
          optionsJson,
          revision: revision,
          cancel: cancel,
          onProgress: (phase, progress) {
            if (controller.isClosed || phase == 'done') return;
            controller.add(
              ExportProgressEvent(
                kind: ExportProgressKind.phase,
                phase: phase,
                progress: progress,
              ),
            );
          },
        );
        if (!controller.isClosed) {
          controller.add(
            ExportProgressEvent(kind: ExportProgressKind.done, result: result),
          );
        }
      } on WonkyException catch (e) {
        if (!controller.isClosed) {
          controller.add(
            ExportProgressEvent(
              kind: ExportProgressKind.error,
              errorCode: e.code.name,
              message: e.message,
            ),
          );
        }
      } on Object catch (e) {
        session.log('Slides export failed: $e', level: LogLevel.error);
        if (!controller.isClosed) {
          controller.add(
            ExportProgressEvent(
              kind: ExportProgressKind.error,
              errorCode: WonkyErrorCode.unavailable.name,
              message: 'The export failed.',
            ),
          );
        }
      } finally {
        await controller.close();
      }
    }());
    return controller.stream;
  }
}

/// Creates the font provider of an export.
typedef FontProviderFactory = BundledFileFontProvider Function();

final class _CachedResult {
  _CachedResult(this.fileUuid, this.expiresAt, this.view);

  final UuidValue fileUuid;
  final DateTime expiresAt;
  final ExportResultView view;
}

/// [SlideImageResolver] of server exports: `wonky-file://<uuid>` reads the
/// stored bytes (files of the deck, or files the actor can read), `https://`
/// goes through the SSRF-safe [SafeImageFetcher]; failures resolve to null
/// (the PDF warns `image_missing`). Results are cached per export unless
/// [cacheBytes] is false (the server export: the renderer keeps what it
/// needs, so bytes are not held twice).
class ServerSlideImageResolver implements SlideImageResolver {
  ServerSlideImageResolver(
    this.session,
    this.actor, {
    required this.itemId,
    this.fetchRemote = SafeImageFetcher.fetch,
    this.cacheBytes = true,
  });

  /// Whether loaded bytes are kept for later requests.
  final bool cacheBytes;

  final Session session;
  final Actor actor;

  /// The exported deck's drive item.
  final int itemId;

  final Future<Uint8List> Function(String src) fetchRemote;

  final Map<String, Future<Uint8List?>> _cache = {};

  @override
  Uint8List? cachedBytes(SlideImageRef ref) => null;

  @override
  Future<Uint8List?> bytes(SlideImageRef ref) =>
      cacheBytes ? _cache.putIfAbsent(ref.src, () => _load(ref)) : _load(ref);

  Future<Uint8List?> _load(SlideImageRef ref) async {
    try {
      final uuid = ref.fileUuid;
      if (uuid != null) {
        final file = await FileService.byUuid(
          session,
          UuidValue.withValidation(uuid),
        );
        if (file == null || file.status != StoredFileStatus.ready) return null;
        if (file.itemId != itemId &&
            !await FileService.canRead(session, actor, file)) {
          return null;
        }
        final data = await FileService.readBytes(session, file);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }
      if (ref.src.startsWith('https://')) return await fetchRemote(ref.src);
      return null;
    } on Object catch (e) {
      session.log(
        'Export image ${ref.src} unavailable: $e',
        level: LogLevel.debug,
      );
      return null;
    }
  }

  @override
  Future<Uri?> url(SlideImageRef ref) async => null;
}

/// [SlideImageResolver] of the export isolate: asks the calling isolate
/// ([ServerSlideImageResolver] there) for each image's bytes.
final class _ChannelImageResolver implements SlideImageResolver {
  _ChannelImageResolver(this.channel);

  final IsolateChannel channel;

  @override
  Uint8List? cachedBytes(SlideImageRef ref) => null;

  @override
  Future<Uint8List?> bytes(SlideImageRef ref) async {
    try {
      return await channel.request(ref.src) as Uint8List?;
    } on Object {
      return null;
    }
  }

  @override
  Future<Uri?> url(SlideImageRef ref) async => null;
}
