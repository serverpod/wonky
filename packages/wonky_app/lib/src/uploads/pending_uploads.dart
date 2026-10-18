import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show StoredFileKind, UuidValue;

import '../core/connectivity_service.dart';
import '../core/local_database.dart';
import '../data/api.dart' show isOfflineError;
import '../data/file_repository.dart';
import '../shell/shell_services.dart';
import '../storage/quota_error_presenter.dart';

/// Creates `local_pending_upload` (suite 12 §1.1 `LocalPendingUpload`):
/// files of this device that are not on the server yet. The first migration
/// of an app's upload database (`sheets_uploads_<user>.db`,
/// `slides_uploads_<user>.db`).
Future<void> createPendingUploadTable(SqliteWriteContext tx) => tx.execute('''
  CREATE TABLE local_pending_upload (
    file_uuid TEXT PRIMARY KEY NOT NULL,
    item_uuid TEXT,
    bytes BLOB NOT NULL,
    mime_type TEXT NOT NULL,
    file_name TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT
  )''');

/// One queued upload.
@immutable
class PendingUpload {
  const PendingUpload({
    required this.fileUuid,
    required this.bytes,
    required this.mimeType,
    required this.fileName,
    this.itemUuid,
  });

  final String fileUuid;

  /// The document's drive item (the upload is attached to it and counted
  /// against its owner's quota, Drive 03 §6.3).
  final String? itemUuid;
  final Uint8List bytes;
  final String mimeType;
  final String fileName;
}

/// Where queued uploads are kept (SQLite; a map in tests and when SQLite
/// can't be opened).
abstract class PendingUploadStore {
  Future<void> put(PendingUpload u);
  Future<PendingUpload?> get(String fileUuid);

  /// The queued file uuids, oldest first.
  Future<List<String>> ids();
  Future<void> remove(String fileUuid);
  Future<void> recordFailure(String fileUuid, String error);
  Future<void> close();
}

/// [PendingUploadStore] on a per-user SQLite database with
/// `local_pending_upload` ([createPendingUploadTable]).
class SqlitePendingUploadStore implements PendingUploadStore {
  SqlitePendingUploadStore(this.db);

  final SqliteDatabase db;

  @override
  Future<void> put(PendingUpload u) => db.execute(
    'INSERT OR REPLACE INTO local_pending_upload (file_uuid, item_uuid, '
    'bytes, mime_type, file_name, created_at) VALUES (?, ?, ?, ?, ?, ?)',
    [
      u.fileUuid,
      u.itemUuid,
      u.bytes,
      u.mimeType,
      u.fileName,
      clock.now().millisecondsSinceEpoch,
    ],
  );

  @override
  Future<PendingUpload?> get(String fileUuid) async {
    final r = await db.getOptional(
      'SELECT * FROM local_pending_upload WHERE file_uuid = ?',
      [fileUuid],
    );
    if (r == null) return null;
    return PendingUpload(
      fileUuid: r['file_uuid']! as String,
      itemUuid: r['item_uuid'] as String?,
      bytes: switch (r['bytes']) {
        final Uint8List b => b,
        final List<int> b => Uint8List.fromList(b),
        _ => Uint8List(0),
      },
      mimeType: r['mime_type']! as String,
      fileName: r['file_name']! as String,
    );
  }

  @override
  Future<List<String>> ids() async => [
    for (final r in await db.getAll(
      'SELECT file_uuid FROM local_pending_upload ORDER BY created_at',
    ))
      r['file_uuid']! as String,
  ];

  @override
  Future<void> remove(String fileUuid) => db.execute(
    'DELETE FROM local_pending_upload WHERE file_uuid = ?',
    [fileUuid],
  );

  @override
  Future<void> recordFailure(String fileUuid, String error) => db.execute(
    'UPDATE local_pending_upload SET attempts = attempts + 1, '
    'last_error = ? WHERE file_uuid = ?',
    [error, fileUuid],
  );

  @override
  Future<void> close() => db.close();
}

/// [PendingUploadStore] in memory (tests, and when SQLite can't be opened).
class MemoryPendingUploadStore implements PendingUploadStore {
  final Map<String, PendingUpload> rows = {};

  @override
  Future<void> put(PendingUpload u) async => rows[u.fileUuid] = u;

  @override
  Future<PendingUpload?> get(String fileUuid) async => rows[fileUuid];

  @override
  Future<List<String>> ids() async => rows.keys.toList();

  @override
  Future<void> remove(String fileUuid) async => rows.remove(fileUuid);

  @override
  Future<void> recordFailure(String fileUuid, String error) async {}

  @override
  Future<void> close() async {}
}

/// Durable image uploads (suite 12 §1.1 `LocalPendingUpload`; Sheets and
/// Slides, CQ-53): the bytes are stored on the device before the upload
/// starts, so a document can reference `wonky-file://<uuid>` at once, show
/// the image from the local bytes (also offline and after a reload) and
/// upload it whenever the server is reachable. Uploads are idempotent on
/// the client-generated file uuid; failures retry with exponential backoff
/// (2 s → 10 min), at most [maxAttempts] times per app start. A quota
/// refusal keeps the bytes on the device ("Not uploaded — out of storage",
/// Drive 03 §6.3) until [retry] or [cancel]. One queue per signed-in user
/// ([PerUserInstallation]).
class PendingUploadQueue<S extends PendingUploadStore> extends ChangeNotifier {
  PendingUploadQueue({
    required this.store,
    required this.files,
    required this.connectivity,
    this.maxAttempts = 12,
    this.onQuotaRefused,
    this.label = 'upload',
  });

  final S store;
  final FileRepository files;
  final ConnectivityService connectivity;
  final int maxAttempts;

  /// Called once per refused upload with the server's error (the *Out of
  /// storage* dialog).
  final void Function(Object error)? onQuotaRefused;

  /// Names the queue in debug messages ("Slides upload").
  final String label;

  final _completed = StreamController<String>.broadcast();

  /// File uuids whose upload finished.
  Stream<String> get completed => _completed.stream;

  final Map<String, Uint8List> _bytes = {};
  final Set<String> _known = {};
  final Map<String, int> _attempts = {};
  final Map<String, DateTime> _notBefore = {};
  final Set<String> _outOfStorage = {};
  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  late final Future<void> _loaded = _load();

  /// Files waiting for upload.
  int get length => _known.length;

  /// Whether [fileUuid] waits for upload on this device.
  bool contains(String fileUuid) => _known.contains(fileUuid);

  /// Whether the server refused [fileUuid] because the storage quota is
  /// full: it stays on this device and isn't retried on its own.
  bool isOutOfStorage(String fileUuid) => _outOfStorage.contains(fileUuid);

  /// Tries a refused upload again (*Retry*).
  void retry(String fileUuid) {
    if (!_outOfStorage.remove(fileUuid)) return;
    _attempts[fileUuid] = 0;
    _notBefore.remove(fileUuid);
    notifyListeners();
    _kick();
  }

  /// Forgets a pending upload (*Remove* on a refused image).
  Future<void> cancel(String fileUuid) => _complete(fileUuid);

  /// Loads the queue and starts uploading.
  Future<void> start() {
    connectivity.addListener(_onConnectivity);
    return _loaded;
  }

  Future<void> _load() async {
    try {
      _known.addAll(await store.ids());
    } on Object catch (e) {
      debugPrint('Reading pending ${label}s failed: $e');
    }
    if (_known.isNotEmpty) notifyListeners();
    _kick();
  }

  void _onConnectivity() {
    if (connectivity.online) {
      _notBefore.clear();
      _kick();
    }
  }

  /// Stores [bytes] durably; the upload follows when possible.
  Future<void> add({
    required String fileUuid,
    String? itemUuid,
    required Uint8List bytes,
    required String mimeType,
    required String fileName,
  }) async {
    _bytes[fileUuid] = bytes;
    _known.add(fileUuid);
    try {
      await store.put(
        PendingUpload(
          fileUuid: fileUuid,
          itemUuid: itemUuid,
          bytes: bytes,
          mimeType: mimeType,
          fileName: fileName,
        ),
      );
    } on Object catch (e) {
      // Still uploads from memory in this session.
      debugPrint('Storing a pending $label failed: $e');
    }
    notifyListeners();
    _kick();
  }

  /// The local bytes of a pending upload (renders and exports the image
  /// offline).
  Future<Uint8List?> bytesOf(String fileUuid) async {
    final cached = _bytes[fileUuid];
    if (cached != null) return cached;
    await _loaded;
    if (!_known.contains(fileUuid)) return null;
    final u = await store.get(fileUuid);
    if (u == null) return null;
    return _bytes[fileUuid] = u.bytes;
  }

  /// The bytes of [fileUuid] if they are in memory.
  Uint8List? cachedBytesOf(String fileUuid) => _bytes[fileUuid];

  Future<void> _complete(String fileUuid) async {
    _known.remove(fileUuid);
    _outOfStorage.remove(fileUuid);
    _bytes.remove(fileUuid);
    _attempts.remove(fileUuid);
    _notBefore.remove(fileUuid);
    try {
      await store.remove(fileUuid);
    } on Object catch (e) {
      debugPrint('Removing a finished $label failed: $e');
    }
    if (!_completed.isClosed) _completed.add(fileUuid);
    if (!_disposed) notifyListeners();
  }

  /// Uploads now if online (tests, reconnect).
  Future<void> flush() async {
    await _loaded;
    _timer?.cancel();
    final running = _runFuture;
    if (running != null) await running;
    if (_disposed || !connectivity.online) return;
    await (_runFuture = _run());
  }

  Future<void>? _runFuture;

  void _kick() {
    if (_disposed || _running || !connectivity.online) return;
    _timer?.cancel();
    _timer = null;
    _runFuture = _run();
  }

  Future<void> _run() async {
    _running = true;
    try {
      while (!_disposed && connectivity.online) {
        final now = clock.now();
        final next = _known.where((id) {
          if (_outOfStorage.contains(id)) return false;
          if ((_attempts[id] ?? 0) >= maxAttempts) return false;
          final nb = _notBefore[id];
          return nb == null || !nb.isAfter(now);
        }).firstOrNull;
        if (next == null) break;
        await _upload(next);
      }
    } finally {
      _running = false;
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    if (_disposed || _notBefore.isEmpty || !connectivity.online) return;
    final waiting = [
      for (final e in _notBefore.entries)
        if (_known.contains(e.key) &&
            !_outOfStorage.contains(e.key) &&
            (_attempts[e.key] ?? 0) < maxAttempts)
          e.value,
    ];
    if (waiting.isEmpty) return;
    final at = waiting.reduce((a, b) => a.isBefore(b) ? a : b);
    var delay = at.difference(clock.now());
    if (delay.isNegative) delay = Duration.zero;
    _timer?.cancel();
    _timer = Timer(delay, _kick);
  }

  Future<void> _upload(String id) async {
    final PendingUpload? u;
    try {
      u = await store.get(id);
    } on Object catch (e) {
      debugPrint('Reading a pending $label failed: $e');
      _attempts[id] = maxAttempts;
      return;
    }
    final bytes = u?.bytes ?? _bytes[id];
    if (bytes == null) {
      _known.remove(id);
      return;
    }
    try {
      final item = u?.itemUuid;
      await files.upload(
        fileUuid: UuidValue.withValidation(id),
        itemUuid: item == null ? null : UuidValue.withValidation(item),
        fileName: u?.fileName ?? 'image',
        mimeType: u?.mimeType ?? 'application/octet-stream',
        bytes: bytes,
        kind: StoredFileKind.image,
      );
      await _complete(id);
    } catch (e) {
      if (QuotaErrorPresenter.isQuotaExceeded(e)) {
        // Out of storage: kept on this device until Retry / Remove.
        _outOfStorage.add(id);
        try {
          await store.recordFailure(id, '$e');
        } catch (_) {}
        if (!_disposed) {
          notifyListeners();
          onQuotaRefused?.call(e);
        }
        return;
      }
      final n = (_attempts[id] ?? 0) + 1;
      _attempts[id] = n;
      final seconds = min(600, 2 * pow(2, n - 1).toInt());
      _notBefore[id] = clock.now().add(Duration(seconds: seconds));
      try {
        await store.recordFailure(id, '$e');
      } catch (_) {}
      if (isOfflineError(e)) connectivity.reportFailure();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_completed.close());
    _timer?.cancel();
    connectivity.removeListener(_onConnectivity);
    unawaited(store.close());
    super.dispose();
  }
}

/// A per-user object of the shell (CQ-53): opened for the signed-in user
/// when [attach]ed and whenever the user changes, closed on sign-out or a
/// switch. [open] builds it for a user (null to give up, e.g. when
/// [isCurrent] turned false meanwhile); [started] runs once it is
/// [value] (an upload queue loads and starts uploading); [close] releases
/// it.
class PerUserInstallation<T extends Object> {
  PerUserInstallation(
    this.services, {
    required this.open,
    required this.close,
    this.started,
  });

  final ShellServices services;
  final Future<T?> Function(String userUuid, bool Function() isCurrent) open;
  final Future<void> Function(T value)? started;
  final void Function(T value) close;

  String? _user;

  /// The signed-in user's object (null while opening, signed out or when
  /// opening failed).
  T? value;

  /// Completes when the current user's object is open (and started).
  Future<void>? opening;

  /// Follows the signed-in user.
  void attach() {
    services.currentUser.addListener(_onUser);
    _onUser();
  }

  /// Uses [v] without a user (widget tests).
  void use(T v) {
    value = v;
    opening = Future<void>.value();
  }

  void _onUser() {
    final next = services.me?.uuid.uuid;
    if (next == _user) return;
    _user = next;
    final old = value;
    value = null;
    if (old != null) close(old);
    if (next == null) return;
    opening = () async {
      final v = await open(next, () => _user == next);
      if (v == null) return;
      if (_user != next) {
        close(v);
        return;
      }
      value = v;
      await started?.call(v);
    }();
  }
}
