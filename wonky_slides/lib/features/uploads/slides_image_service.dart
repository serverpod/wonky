import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show
        FileUrlView,
        StoredFileKind,
        StoredFileStatus,
        UuidValue,
        WonkyException;
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/scene.dart' show SlideImageRef;

import '../editor_screen/deck_editor_controller.dart';
import '../clipboard/rehome_queue.dart';
import 'slides_pending_uploads.dart';

/// The images of one open deck (03 §6.5, 02 §6.4) and its upload state —
/// the [SlideImageResolver] the canvas, thumbnails, presenting and PDF
/// export read bytes from:
///
/// 1. images inserted on this device in this session (local bytes),
/// 2. the device's upload queue ([SlidesPendingUploads]: images that are
///    not on the server yet render from their local bytes, also offline
///    and after a reload),
/// 3. the session's own resolver (in-memory decks, previews),
/// 4. the server: `wonky-file://` sources resolve to signed URLs (polling
///    while another user's upload is still pending), `https://` sources go
///    through the image proxy (`file.fetchImage`).
///
/// Downloaded bytes are kept in a bounded LRU (64 MB); bytes inserted on
/// this device move there once their upload is done. Loads that fail
/// for now (offline, server errors) throw [SlideImageTransientException]
/// and [retries] fires when the connection comes back (CQ-43). One
/// instance per open deck ([of]); [dispose] cancels the polls.
class SlidesImageService extends ChangeNotifier
    implements RetryingSlideImageResolver {
  SlidesImageService._(this.editor) {
    _s.connectivity.addListener(_onConnectivity);
  }

  static final Expando<SlidesImageService> _registry = Expando(
    'SlidesImageService',
  );

  /// The image service of [editor] (created on first use).
  static SlidesImageService of(DeckEditorController editor) =>
      _registry[editor] ??= SlidesImageService._(editor);

  /// The image service of [editor] if one was created.
  static SlidesImageService? maybeOf(DeckEditorController editor) =>
      _registry[editor];

  final DeckEditorController editor;

  ShellServices get _s => editor.services;

  static const scheme = SlideImageRef.fileScheme;

  /// Budget of the downloaded-bytes LRU.
  static const maxCacheBytes = 64 * 1024 * 1024;

  final Map<String, Uint8List> _local = {};
  final Set<String> _uploading = {};
  final Map<String, (Uint8List, String, String)> _refused = {};
  final LinkedHashMap<String, Uint8List> _downloaded = LinkedHashMap();
  int _downloadedBytes = 0;
  final StreamController<void> _retries = StreamController.broadcast();
  final Set<Completer<void>> _sleeping = {};
  late bool _online = _s.connectivity.online;
  bool _disposed = false;

  @override
  Stream<void> get retries => _retries.stream;

  void _onConnectivity() {
    final online = _s.connectivity.online;
    if (online && !_online && !_disposed) _retries.add(null);
    _online = online;
  }

  /// Stops polling for pending uploads of other users and stops listening
  /// to the connection (the deck closed).
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _s.connectivity.removeListener(_onConnectivity);
    for (final c in _sleeping) {
      c.complete();
    }
    _sleeping.clear();
    unawaited(_retries.close());
    if (identical(_registry[editor], this)) _registry[editor] = null;
    super.dispose();
  }

  /// Waits [d], or less when disposed.
  Future<void> _sleep(Duration d) {
    final c = Completer<void>();
    _sleeping.add(c);
    final t = Timer(d, () {
      if (!c.isCompleted) c.complete();
    });
    return c.future.whenComplete(() {
      t.cancel();
      _sleeping.remove(c);
    });
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Test hook: replaces the server for remote bytes (`https://` sources
  /// and signed downloads of `wonky-file://` sources by file uuid).
  @visibleForTesting
  Future<Uint8List?> Function(String src)? remoteLoader;

  /// Test hook: replaces `file.copyToItem` (*From Wonky Drive*).
  @visibleForTesting
  Future<void> Function(UuidValue source, UuidValue copy)? driveCopier;

  /// The file uuid of a `wonky-file://` source, a bare uuid, or null.
  static String? fileUuidOf(String src) {
    final s = src.startsWith(scheme) ? src.substring(scheme.length) : src;
    try {
      return UuidValue.withValidation(s).uuid;
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------- uploads

  SlidesPendingUploads? get _queue => SlidesPendingUploads.of(_s);

  /// Copies of pasted files that are still pending (SL-18): their images
  /// render from the source file meanwhile.
  SlidesRehomeQueue? get _rehome => SlidesRehomeQueue.of(_s);

  /// Starts uploading [bytes] (stored on the device first); returns the
  /// client-generated file uuid the element references at once. The upload
  /// itself is not an undo step (03 §15); orphans are collected by the
  /// server.
  String startUpload(Uint8List bytes, String mimeType, String fileName) {
    final uuid = _s.ids.nextString();
    _local[uuid] = bytes;
    final queue = _queue;
    if (queue != null) {
      unawaited(
        queue.add(
          fileUuid: uuid,
          itemUuid: editor.session.itemUuid.uuid,
          bytes: bytes,
          mimeType: mimeType,
          fileName: fileName,
        ),
      );
    } else {
      _uploading.add(uuid);
      unawaited(_upload(uuid, bytes, mimeType, fileName));
    }
    notifyListeners();
    return uuid;
  }

  /// Direct upload when no queue is installed (tests, signed-out previews).
  Future<void> _upload(
    String uuid,
    Uint8List bytes,
    String mimeType,
    String fileName,
  ) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await _s.repositories.files.upload(
          fileUuid: UuidValue.withValidation(uuid),
          itemUuid: editor.session.itemUuid,
          fileName: fileName,
          mimeType: mimeType,
          bytes: bytes,
          kind: StoredFileKind.image,
        );
        _uploading.remove(uuid);
        notifyListeners();
        return;
      } catch (e) {
        if (QuotaErrorPresenter.isQuotaExceeded(e)) {
          _uploading.remove(uuid);
          _refused[uuid] = (bytes, mimeType, fileName);
          notifyListeners();
          _s.quotaErrors.present(e, reason: QuotaReasons.image);
          return;
        }
        if (attempt >= 6) {
          _uploading.remove(uuid);
          notifyListeners();
          return;
        }
        await Future<void>.delayed(
          Duration(seconds: (2 << (attempt - 1)).clamp(2, 120)),
        );
      }
    }
  }

  /// Notifies when [isOutOfStorage] / [isUploading] may have changed.
  Listenable get uploadStates => Listenable.merge([this, ?_queue, ?_rehome]);

  /// Whether the server refused the upload of [fileUuid] from this device
  /// because the storage quota is full (Drive 03 §6.3): the image shows
  /// "Not uploaded — out of storage" with *Retry* and *Remove*.
  bool isOutOfStorage(String fileUuid) =>
      _refused.containsKey(fileUuid) ||
      (_queue?.isOutOfStorage(fileUuid) ?? false) ||
      (_rehome?.isOutOfStorage(fileUuid) ?? false);

  /// Whether [fileUuid] still uploads from this device.
  bool isUploading(String fileUuid) =>
      !isOutOfStorage(fileUuid) &&
      (_uploading.contains(fileUuid) ||
          (_queue?.contains(fileUuid) ?? false) ||
          (_rehome?.contains(fileUuid) ?? false));

  /// *Retry* on a refused image.
  void retryUpload(String fileUuid) {
    final r = _refused.remove(fileUuid);
    if (r != null) {
      _uploading.add(fileUuid);
      notifyListeners();
      unawaited(_upload(fileUuid, r.$1, r.$2, r.$3));
      return;
    }
    _queue?.retry(fileUuid);
    _rehome?.retry(fileUuid);
  }

  /// Forgets a refused upload (*Remove* deletes the image element).
  void forgetUpload(String fileUuid) {
    if (_refused.remove(fileUuid) != null) notifyListeners();
    final q = _queue;
    if (q != null && q.contains(fileUuid)) unawaited(q.cancel(fileUuid));
    final r = _rehome;
    if (r != null && r.contains(fileUuid)) unawaited(r.cancel(fileUuid));
  }

  // ------------------------------------------------------------- sources

  /// The bytes of the https image [url] through the server's image proxy
  /// (*Insert image ▸ By URL*, 03 §6.5.1). Throws when it can't be loaded.
  Future<Uint8List> fetchRemote(String url) async {
    final hook = remoteLoader;
    if (hook != null) {
      final b = await hook(url);
      if (b == null) throw StateError('Image not found');
      return b;
    }
    final client = _s.client;
    if (client == null) throw StateError('Offline');
    final data = await client.file.fetchImage(editor.session.itemUuid, url);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Copies the image file [sourceFileUuid] (a Wonky Drive image file) into
  /// the deck on the server (`file.copyToItem`, quota of the deck's owner;
  /// 03 §6.5.1 *From Wonky Drive*) and returns the copy's uuid and bytes.
  Future<(String, Uint8List)> copyFromDrive(UuidValue sourceFileUuid) async {
    final copy = UuidValue.withValidation(_s.ids.nextString());
    final hook = driveCopier;
    if (hook != null) {
      await hook(sourceFileUuid, copy);
    } else {
      final client = _s.client;
      if (client == null) throw StateError('Offline');
      await client.file.copyToItem(
        sourceFileUuid,
        copy,
        editor.session.itemUuid,
      );
    }
    final bytes = await this.bytes(SlideImageRef('$scheme${copy.uuid}'));
    if (bytes == null) throw StateError('Image not found');
    _remember(copy.uuid, bytes);
    return (copy.uuid, bytes);
  }

  // ------------------------------------------------------------ resolver

  String _key(String src) {
    final k = fileUuidOf(src) ?? src.trim();
    // A pasted file whose copy is pending renders from its source.
    return _rehome?.sourceOf(k) ?? k;
  }

  @override
  Uint8List? cachedBytes(SlideImageRef ref) {
    final key = _key(ref.src);
    final local = _local[key];
    if (local != null) {
      // Uploaded: the bounded LRU keeps the bytes from now on.
      if (!isUploading(key) && !isOutOfStorage(key)) {
        _local.remove(key);
        _remember(key, local);
      }
      return local;
    }
    final hit =
        _queue?.cachedBytesOf(key) ?? editor.session.images.cachedBytes(ref);
    if (hit != null) return hit;
    final d = _downloaded.remove(key);
    if (d != null) _downloaded[key] = d;
    return d;
  }

  @override
  Future<Uint8List?> bytes(SlideImageRef ref) async {
    final cached = cachedBytes(ref);
    if (cached != null) return cached;
    final key = _key(ref.src);
    final pending = await _queue?.bytesOf(key);
    if (pending != null) return pending;
    final own = await editor.session.images.bytes(ref);
    if (own != null) return own;
    final Uint8List? b;
    try {
      b = await _remote(key);
    } catch (e) {
      // Gone or no access: unavailable for good. Offline, a transport or
      // server error: the image cache tries again later.
      if (e is SlideImageTransientException) rethrow;
      if (e is WonkyException) {
        debugPrint('Loading slide image $key failed: $e');
        return null;
      }
      throw SlideImageTransientException(e);
    }
    if (b != null) _remember(key, b);
    return b;
  }

  @override
  Future<Uri?> url(SlideImageRef ref) async {
    final f = fileUuidOf(ref.src);
    if (f == null) {
      return ref.src.startsWith('https://') ? Uri.parse(ref.src) : null;
    }
    try {
      final v = await _s.repositories.files.getUrl(UuidValue.withValidation(f));
      return v.url == null ? null : Uri.parse(v.url!);
    } catch (_) {
      return null;
    }
  }

  void _remember(String key, Uint8List b) {
    final old = _downloaded.remove(key);
    if (old != null) _downloadedBytes -= old.length;
    _downloaded[key] = b;
    _downloadedBytes += b.length;
    while (_downloadedBytes > maxCacheBytes && _downloaded.length > 1) {
      final first = _downloaded.keys.first;
      _downloadedBytes -= _downloaded.remove(first)!.length;
    }
  }

  Future<Uint8List?> _remote(String key) async {
    final hook = remoteLoader;
    if (hook != null) return hook(key);
    if (_disposed) return null;
    if (!_s.connectivity.online) {
      throw const SlideImageTransientException('offline');
    }
    if (key.startsWith('https://')) return fetchRemote(key);
    final uuid = UuidValue.withValidation(key);
    var delay = const Duration(seconds: 2);
    final deadline = DateTime.now().add(const Duration(hours: 1));
    while (true) {
      final FileUrlView view = await _s.repositories.files.getUrl(uuid);
      if (_disposed) return null;
      if (view.status == StoredFileStatus.ready && view.url != null) {
        final r = await http.get(Uri.parse(view.url!));
        return switch (r.statusCode) {
          200 => r.bodyBytes,
          403 || 404 || 410 => null,
          _ => throw SlideImageTransientException('HTTP ${r.statusCode}'),
        };
      }
      if (view.status == StoredFileStatus.failed ||
          DateTime.now().isAfter(deadline)) {
        return null;
      }
      // Another user's upload that hasn't finished yet (stops when the
      // deck closes).
      await _sleep(delay);
      if (_disposed) return null;
      delay = delay * 2 > const Duration(seconds: 30)
          ? const Duration(seconds: 30)
          : delay * 2;
    }
  }

  /// The original bytes of [src] for *Download original* (null while not
  /// available).
  Future<Uint8List?> originalBytes(String src) => bytes(SlideImageRef(src));
}
