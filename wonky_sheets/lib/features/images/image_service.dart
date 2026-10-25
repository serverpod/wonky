import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show FileUrlView, StoredFileKind, StoredFileStatus, UuidValue;

import 'package:http/http.dart' as http;

import '../import_export/pending_uploads.dart';
import 'image_blob_cache.dart';
import '../sheet_editor/sheet_editor_controller.dart';

/// Picked or pasted image bytes.
@immutable
class PickedImage {
  const PickedImage({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;
}

/// Why an image file was rejected.
enum ImageRejectReason { unsupportedFormat, tooLarge }

class ImageRejected implements Exception {
  const ImageRejected(this.reason);
  final ImageRejectReason reason;

  @override
  String toString() => 'ImageRejected(${reason.name})';
}

/// Image limits and formats of Sheets images (08 §10.1).
abstract final class SheetsImageRules {
  /// 50 MB, as in Google Sheets.
  static const maxBytes = 50 * 1024 * 1024;

  /// 25 megapixels.
  static const maxPixels = 25 * 1000 * 1000;

  static const extensions = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'];

  /// SVG images are rasterized on insert (08 §10.1).
  static const svgMime = 'image/svg+xml';

  /// The MIME type of [bytes] (sniffed, else by [name]'s extension); throws
  /// [ImageRejected].
  static String validate(String name, Uint8List bytes) {
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
        : '';
    final mime = sniff(bytes) ?? _byExtension(ext);
    if (mime == null) {
      throw const ImageRejected(ImageRejectReason.unsupportedFormat);
    }
    if (bytes.length > maxBytes) {
      throw const ImageRejected(ImageRejectReason.tooLarge);
    }
    return mime;
  }

  static String? _byExtension(String ext) => switch (ext) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'svg' => svgMime,
    _ => null,
  };

  static bool _startsWith(Uint8List b, String s) {
    if (b.length < s.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (b[i] != s.codeUnitAt(i)) return false;
    }
    return true;
  }

  /// Sniffs PNG, JPEG, GIF, WebP and SVG (BMP isn't supported).
  static String? sniff(Uint8List b) {
    if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e) {
      return 'image/png';
    }
    if (b.length >= 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) {
      return 'image/jpeg';
    }
    if (_startsWith(b, 'GIF8')) return 'image/gif';
    if (b.length >= 12 &&
        _startsWith(b, 'RIFF') &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    if (_isSvg(b)) return svgMime;
    return null;
  }

  /// An SVG document (optional BOM, XML declaration, comments or doctype
  /// before the `<svg` element).
  static bool _isSvg(Uint8List b) {
    final n = b.length < 2048 ? b.length : 2048;
    final head = String.fromCharCodes(b.sublist(0, n)).trimLeft();
    final start = head.startsWith('\uFEFF') ? head.substring(1) : head;
    if (!start.startsWith('<')) return false;
    return start.startsWith('<svg') || start.contains('<svg');
  }
}

/// The natural size of encoded image [bytes] (null when it can't be read).
Future<ui.Size?> decodeImageSize(Uint8List bytes) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final d = await ui.ImageDescriptor.encoded(buffer);
    final size = ui.Size(d.width.toDouble(), d.height.toDouble());
    d.dispose();
    buffer.dispose();
    return size;
  } catch (_) {
    return null;
  }
}

/// Load state of one image source.
enum ImageLoadPhase { loading, uploading, ready, failed }

/// A decoded image (or why there is none yet).
@immutable
class LoadedImage {
  const LoadedImage(this.phase, {this.image, this.animated});

  final ImageLoadPhase phase;

  /// The decoded first frame (when [phase] is ready).
  final ui.Image? image;

  /// The encoded bytes of an animated image (GIF/WebP with several frames):
  /// the editor animates it (08 §10.1); exports, print and in-cell images
  /// use the first frame.
  final Uint8List? animated;
}

class _Entry {
  _Entry(this.src)
    : state = ValueNotifier(const LoadedImage(ImageLoadPhase.loading));
  final String src;
  final ValueNotifier<LoadedImage> state;
  bool started = false;
  int bytes = 0;
}

/// Images of an open spreadsheet (08 §10): uploads picked/pasted images to
/// the files service (attached to the spreadsheet's drive item) with retries
/// and shows them from the local bytes until uploaded; resolves
/// `wonky-file://` sources to signed URLs (polling while another user's
/// upload is still pending: "Image uploading…") and loads `https://` images
/// through the server's image proxy. Decoded images are cached (LRU,
/// ~100 MB).
///
/// One instance per editor ([of]).
class SheetsImageService {
  SheetsImageService._(this.editor);

  static final Expando<SheetsImageService> _registry = Expando(
    'SheetsImageService',
  );

  static SheetsImageService of(SheetEditorController editor) =>
      _registry[editor] ??= SheetsImageService._(editor);

  final SheetEditorController editor;

  ShellServices get _s => editor.services;

  static const scheme = 'wonky-file://';

  /// Decoded-image budget.
  static const maxCacheBytes = 100 * 1024 * 1024;

  final Map<String, Uint8List> _local = {};
  final Set<String> _uploading = {};
  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();
  int _cacheBytes = 0;

  /// Fired whenever an image finished loading (grid in-cell images repaint).
  final ValueNotifier<int> loaded = ValueNotifier(0);

  /// Test hook: replaces the remote byte loader.
  @visibleForTesting
  Future<Uint8List?> Function(String src)? remoteLoader;

  /// The file uuid of a `wonky-file://` source, a bare uuid, or null.
  static String? fileUuidOf(String src) {
    final s = src.startsWith(scheme) ? src.substring(scheme.length) : src;
    try {
      return UuidValue.withValidation(s).uuid;
    } catch (_) {
      return null;
    }
  }

  /// The local bytes of an image inserted on this device (download of the
  /// original while it uploads).
  Uint8List? localBytes(String fileUuid) => _local[fileUuid];

  /// Starts uploading [image]; returns the client-generated file uuid that
  /// the object spec / `IMAGE()` formula references right away (the upload
  /// itself is not undoable; orphans are collected by the server).
  String startUpload(PickedImage image) {
    final uuid = _s.ids.nextString();
    _local[uuid] = image.bytes;
    // Kept after the upload too: the image renders offline and after a
    // reload (08 §10.1 local blob cache).
    unawaited(
      SheetsImageBlobCache.of(_s)?.put(uuid, image.bytes, image.mimeType),
    );
    // Durable queue (stored on the device first, uploads when online).
    final queue = SheetsPendingUploads.of(_s);
    if (queue != null) {
      unawaited(
        queue.add(
          fileUuid: uuid,
          itemUuid: editor.session.itemUuid.uuid,
          bytes: image.bytes,
          mimeType: image.mimeType,
          fileName: image.name,
        ),
      );
      return uuid;
    }
    _uploading.add(uuid);
    unawaited(_upload(uuid, image));
    return uuid;
  }

  Future<void> _upload(String uuid, PickedImage image) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        await _s.repositories.files.upload(
          fileUuid: UuidValue.withValidation(uuid),
          itemUuid: editor.session.itemUuid,
          fileName: image.name,
          mimeType: image.mimeType,
          bytes: image.bytes,
          kind: StoredFileKind.image,
        );
        _uploading.remove(uuid);
        return;
      } catch (e) {
        debugPrint('Image upload failed (attempt $attempt): $e');
        if (QuotaErrorPresenter.isQuotaExceeded(e)) {
          // Drive 03 §6.3: "Not uploaded — out of storage" until Retry /
          // Remove, and the *Out of storage* dialog.
          _uploading.remove(uuid);
          _refused[uuid] = image;
          _uploadStates.value++;
          _s.quotaErrors.present(e, reason: QuotaReasons.image);
          return;
        }
        if (attempt >= 6) {
          _uploading.remove(uuid);
          return;
        }
        await Future<void>.delayed(
          Duration(seconds: (2 << (attempt - 1)).clamp(2, 120)),
        );
      }
    }
  }

  /// Direct uploads (no queue) the server refused on quota.
  final Map<String, PickedImage> _refused = {};
  final ValueNotifier<int> _uploadStates = ValueNotifier(0);

  /// Notifies when [isOutOfStorage] may have changed (direct uploads and
  /// the device's upload queue).
  Listenable get uploadStates =>
      Listenable.merge([_uploadStates, ?SheetsPendingUploads.of(_s)]);

  /// Whether the server refused the upload of [fileUuid] from this device
  /// because the storage quota is full (Drive 03 §6.3, 08 §10).
  bool isOutOfStorage(String fileUuid) =>
      _refused.containsKey(fileUuid) ||
      (SheetsPendingUploads.of(_s)?.isOutOfStorage(fileUuid) ?? false);

  /// *Retry* on a refused image.
  void retryUpload(String fileUuid) {
    final image = _refused.remove(fileUuid);
    if (image != null) {
      _uploading.add(fileUuid);
      _uploadStates.value++;
      unawaited(_upload(fileUuid, image));
      return;
    }
    SheetsPendingUploads.of(_s)?.retry(fileUuid);
  }

  /// Forgets a refused upload (*Remove* deletes the image object).
  void forgetUpload(String fileUuid) {
    if (_refused.remove(fileUuid) != null) _uploadStates.value++;
    final queue = SheetsPendingUploads.of(_s);
    if (queue != null && queue.contains(fileUuid)) {
      unawaited(queue.cancel(fileUuid));
    }
  }

  /// Whether [fileUuid] is still uploading from this device.
  bool isUploading(String fileUuid) =>
      !isOutOfStorage(fileUuid) &&
      (_uploading.contains(fileUuid) ||
          (SheetsPendingUploads.of(_s)?.contains(fileUuid) ?? false));

  /// The load state of [src] (`wonky-file://…`, a file uuid, or `https://…`);
  /// starts loading on first use.
  ValueListenable<LoadedImage> image(String src) {
    final key = _key(src);
    var e = _entries.remove(key);
    e ??= _Entry(key);
    _entries[key] = e;
    if (!e.started) {
      e.started = true;
      unawaited(_load(e));
    }
    return e.state;
  }

  /// The decoded image of [src] if it is loaded (starts loading otherwise).
  ui.Image? decoded(String src) => image(src).value.image;

  String _key(String src) {
    final f = fileUuidOf(src);
    return f ?? src.trim();
  }

  Future<void> _load(_Entry e) async {
    try {
      final source = await _sourceOf(e);
      final ui.Image img;
      Uint8List? animated;
      switch (source) {
        case ui.Image():
          img = source;
        case Uint8List():
          final codec = await ui.instantiateImageCodec(source);
          if (codec.frameCount > 1) animated = source;
          final frame = await codec.getNextFrame();
          codec.dispose();
          img = frame.image;
        default:
          e.state.value = const LoadedImage(ImageLoadPhase.failed);
          return;
      }
      e.bytes = img.width * img.height * 4 + (animated?.length ?? 0);
      _cacheBytes += e.bytes;
      e.state.value = LoadedImage(
        ImageLoadPhase.ready,
        image: img,
        animated: animated,
      );
      loaded.value++;
      _evict();
    } catch (err) {
      debugPrint('Loading image ${e.src} failed: $err');
      e.state.value = const LoadedImage(ImageLoadPhase.failed);
    }
  }

  void _evict() {
    while (_cacheBytes > maxCacheBytes && _entries.length > 1) {
      final first = _entries.keys.first;
      final e = _entries.remove(first)!;
      _cacheBytes -= e.bytes;
      e.state.value.image?.dispose();
      e.state.dispose();
    }
  }

  /// Bytes (`Uint8List`) or a decoded `ui.Image` of [e], or null.
  Future<Object?> _sourceOf(_Entry e) async {
    final hook = remoteLoader;
    final src = e.src;
    final local = _local[src];
    if (local != null) return local;
    // Inserted or downloaded on this device before (offline, reloads).
    final cache = await SheetsImageBlobCache.ready(_s);
    final cached = await cache?.get(src);
    if (cached != null) return cached.bytes;
    // Not uploaded yet (imported or inserted on this device, maybe before a
    // reload): the bytes kept by the upload queue.
    final pending = await SheetsPendingUploads.of(_s)?.bytesOf(src);
    if (pending != null) return pending;
    if (hook != null) return hook(src);
    if (src.startsWith('https://')) {
      final client = _s.client;
      if (client == null) return null;
      final data = await client.sheets.fetchImage(editor.session.itemUuid, src);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      unawaited(cache?.put(src, bytes, SheetsImageRules.sniff(bytes) ?? ''));
      return bytes;
    }
    final uuid = UuidValue.withValidation(src);
    var delay = const Duration(seconds: 2);
    final deadline = DateTime.now().add(const Duration(hours: 1));
    while (true) {
      final FileUrlView view = await _s.repositories.files.getUrl(uuid);
      if (view.status == StoredFileStatus.ready && view.url != null) {
        final bytes = await _download(view.url!);
        if (bytes != null) {
          unawaited(
            cache?.put(src, bytes, SheetsImageRules.sniff(bytes) ?? ''),
          );
          return bytes;
        }
        return _downloadDecoded(view.url!);
      }
      if (view.status == StoredFileStatus.failed ||
          DateTime.now().isAfter(deadline)) {
        return null;
      }
      // Another user's upload that hasn't finished yet.
      e.state.value = const LoadedImage(ImageLoadPhase.uploading);
      await Future<void>.delayed(delay);
      delay = delay * 2 > const Duration(seconds: 30)
          ? const Duration(seconds: 30)
          : delay * 2;
    }
  }

  /// The encoded bytes at the signed [url] (null when the request fails,
  /// for example without CORS on the web).
  Future<Uint8List?> _download(String url) async {
    try {
      final r = await http.get(Uri.parse(url));
      if (r.statusCode != 200) return null;
      return r.bodyBytes;
    } catch (e) {
      debugPrint('Downloading an image failed: $e');
      return null;
    }
  }

  Future<ui.Image?> _downloadDecoded(String url) async {
    final completer = Completer<ui.Image?>();
    // NetworkImage handles web (fetch) and native (HttpClient).
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late ImageStreamListener l;
    l = ImageStreamListener(
      (info, _) {
        stream.removeListener(l);
        if (!completer.isCompleted) completer.complete(info.image.clone());
        info.dispose();
      },
      onError: (err, _) {
        stream.removeListener(l);
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(l);
    return completer.future;
  }

  /// The bytes of the https image [url], loaded through the server's image
  /// proxy (08 §10.1 *By URL*).
  Future<Uint8List> fetchRemote(String url) async {
    final hook = remoteLoader;
    if (hook != null) {
      final b = await hook(url);
      if (b == null) throw StateError('Image not found');
      return b;
    }
    final client = _s.client;
    if (client == null) throw StateError('Offline');
    final data = await client.sheets.fetchImage(editor.session.itemUuid, url);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Bytes of [src] for download (local or cached original bytes, else the
  /// loaded image as PNG).
  Future<Uint8List?> bytesForDownload(String src) async {
    final key = _key(src);
    final local = _local[key];
    if (local != null) return local;
    final cached = await (await SheetsImageBlobCache.ready(_s))?.get(key);
    if (cached != null) return cached.bytes;
    final img = decoded(key);
    if (img == null) return null;
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}

/// Helpers to get PNG bytes of an image source (clipboard copies).
extension SheetsImagePng on SheetsImageService {
  /// PNG bytes of [src] (the original when it is a PNG), or null while it
  /// isn't loaded.
  Future<Uint8List?> pngOf(String src) async {
    final bytes = await bytesForDownload(src);
    if (bytes != null && SheetsImageRules.sniff(bytes) == 'image/png') {
      return bytes;
    }
    var img = decoded(src);
    if (img == null) {
      final l = image(src);
      if (l.value.phase == ImageLoadPhase.loading) {
        final done = Completer<void>();
        void on() {
          if (l.value.phase != ImageLoadPhase.loading && !done.isCompleted) {
            done.complete();
          }
        }

        l.addListener(on);
        await done.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        );
        l.removeListener(on);
      }
      img = l.value.image;
    }
    if (img == null) return null;
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
