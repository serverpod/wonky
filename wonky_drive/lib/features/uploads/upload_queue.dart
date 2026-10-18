import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import 'upload_api.dart';
import 'upload_store.dart';
import 'upload_task.dart';

/// A file to upload (picked, dropped or pasted).
///
/// Its bytes may be read lazily ([UploadFile.lazy]): the pre-checks of
/// `startUploadBatch` (count, size, quota) only need [size], and the queue
/// reads the bytes of the files it accepts when they are enqueued, so a
/// picked 2 GB video is refused without being loaded (DR-1).
class UploadFile {
  UploadFile({
    required this.name,
    required Uint8List bytes,
    this.mimeType,
    this.lastModified,
    this.folderPath = const [],
  }) : size = bytes.length,
       _bytes = bytes,
       _read = null;

  /// A file of [size] bytes (as the picker reports it) whose content
  /// [read] loads on demand.
  UploadFile.lazy({
    required this.name,
    required this.size,
    required this._read,
    this.mimeType,
    this.lastModified,
    this.folderPath = const [],
  });

  final String name;
  final String? mimeType;
  final DateTime? lastModified;

  /// Folders to create below the target for a dropped folder
  /// (`['Holiday', 'Day 1']`); empty for single files.
  final List<String> folderPath;

  /// The size in bytes (known before the content is read).
  final int size;

  Uint8List? _bytes;
  final Future<Uint8List> Function()? _read;

  /// The content (read once, on first use).
  Future<Uint8List> readBytes() async => _bytes ??= await _read!();
}

/// Something the panel announces (polite live region) and the shell
/// reacts to (the new item appears in its folder).
@immutable
class UploadEvent {
  const UploadEvent(this.task, {required this.done});

  final UploadTask task;

  /// true: uploaded; false: failed.
  final bool done;
}

/// The Drive app's upload queue (Drive 02 §3.5, §4): runs [parallel]
/// uploads (FIFO), persists every change in the [UploadStore] first,
/// waits for the network while offline and retries network failures with
/// exponential backoff (2 s → 10 min, with jitter). Whole files are
/// retried (v2 review Q12: no chunking).
class UploadQueue extends ChangeNotifier {
  UploadQueue({
    required this.api,
    required this.store,
    required this.connectivity,
    required this._newId,
    this.parallel = 3,
    this.maxAutomaticAttempts = 8,
    this.storeAllBytes = true,
    this.storedBytesLimit = 5 * 1024 * 1024,
    DateTime Function()? now,
    Random? random,
  }) : _now = now ?? DateTime.now,
       _random = random ?? Random();

  final UploadApi api;
  final UploadStore store;
  final ConnectivityService connectivity;
  final UuidValue Function() _newId;
  final DateTime Function() _now;
  final Random _random;

  /// Uploads running at the same time.
  final int parallel;

  /// Network failures retried automatically before the row shows
  /// "Failed — network error".
  final int maxAutomaticAttempts;

  /// The app kind a finished upload is converted to (*Convert uploads to
  /// Wonky formats*, Drive 02 §7.3), or null to keep the file. Asked when
  /// the upload completes.
  DriveItemKind? Function(UploadTask t)? convertTo;

  /// Whether every file's bytes are stored locally (OPFS, desktop). When
  /// false (IndexedDB fallback) only files up to [storedBytesLimit] are;
  /// larger ones are held in memory and marked `volatile` (Drive 02 §4.1).
  bool storeAllBytes;
  final int storedBytesLimit;

  final List<UploadTask> _tasks = [];
  final Map<String, Uint8List> _memory = {};
  final Map<String, UploadAbort> _aborts = {};
  final Map<String, DateTime> _notBefore = {};
  final Set<String> _running = {};

  /// Tasks the server knows (created): a cancel tells the server.
  final Set<String> _created = {};

  /// Tasks cancelled by undo (redo starts them again).
  final Set<String> _cancelledByUndo = {};

  final _events = StreamController<UploadEvent>.broadcast();
  Timer? _timer;
  bool _started = false;
  bool _disposed = false;

  /// Uploaded / failed files (announcements, drive refresh).
  Stream<UploadEvent> get events => _events.stream;

  /// Every task in the panel, in queue order.
  List<UploadTask> get tasks => List.unmodifiable(_tasks);

  UploadTask? task(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Tasks still to finish.
  int get activeCount => _tasks.where((t) => t.status.isActive).length;
  int get doneCount =>
      _tasks.where((t) => t.status == UploadStatus.done).length;
  int get failedCount =>
      _tasks.where((t) => t.status == UploadStatus.failed).length;
  bool get hasActive => _tasks.any((t) => t.status.isActive);

  /// Whether [id] was cancelled by undo (redo starts it again).
  bool cancelledByUndo(String id) => _cancelledByUndo.contains(id);

  /// Progress of the active uploads, by bytes (0…1).
  double get batchProgress {
    var total = 0;
    var sent = 0;
    for (final t in _tasks) {
      if (!t.status.isActive) continue;
      total += t.sizeBytes;
      sent += (t.progress * t.sizeBytes).round();
    }
    return total == 0 ? 0 : sent / total;
  }

  /// Time left of the active uploads, after 2 s of data (null before or
  /// when nothing is being sent).
  Duration? get timeLeft {
    final now = _now();
    var sent = 0;
    var elapsedMs = 0;
    for (final t in _tasks) {
      final since = t.sendingSince;
      if (t.status != UploadStatus.uploading || since == null) continue;
      sent += t.bytesSent;
      elapsedMs = max(elapsedMs, now.difference(since).inMilliseconds);
    }
    if (elapsedMs < 2000 || sent <= 0) return null;
    final remaining = _tasks.fold<int>(0, (a, t) => a + t.remainingBytes);
    final rate = sent / elapsedMs; // bytes per ms
    return Duration(milliseconds: (remaining / rate).round());
  }

  // ---------------------------------------------------------------- start

  /// Restores the stored queue: finished uploads are forgotten, interrupted
  /// ones queued again, held-in-memory ones that lost their bytes fail with
  /// "Add the file again" (Drive 02 §4.1).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    connectivity.addListener(_onConnectivity);
    List<UploadTask> stored;
    try {
      stored = await store.load();
    } on Object catch (e) {
      debugPrint('Reading the upload queue failed: $e');
      stored = const [];
    }
    for (final t in stored) {
      if (_lastCreated == null || t.createdAt.isAfter(_lastCreated!)) {
        _lastCreated = t.createdAt;
      }
      if (t.status == UploadStatus.done || t.status == UploadStatus.cancelled) {
        unawaited(_quietly(() => store.remove(t.id)));
        continue;
      }
      if (t.volatile && t.status != UploadStatus.failed) {
        t
          ..status = UploadStatus.failed
          ..failure = UploadFailure.notSaved;
        unawaited(_save(t));
      } else if (t.status == UploadStatus.failed &&
          t.failure == UploadFailure.network) {
        // A new start retries network failures.
        t
          ..status = UploadStatus.queued
          ..attempts = 0;
      }
      if (t.status.isActive && !connectivity.online) {
        t.status = UploadStatus.waitingForNetwork;
      }
      _tasks.add(t);
    }
    notifyListeners();
    _pump();
  }

  void _onConnectivity() {
    if (_disposed) return;
    if (connectivity.online) {
      _notBefore.clear();
      var changed = false;
      for (final t in _tasks) {
        if (t.status == UploadStatus.waitingForNetwork) {
          t.status = UploadStatus.queued;
          changed = true;
        }
      }
      if (changed) notifyListeners();
      _pump();
    } else {
      var changed = false;
      for (final t in _tasks) {
        if (t.status == UploadStatus.queued) {
          t.status = UploadStatus.waitingForNetwork;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    }
  }

  // -------------------------------------------------------------- enqueue

  /// Queues [files] for [parentUuid] (null = My Drive) as one batch;
  /// returns the tasks (their ids are the client-generated item uuids).
  Future<List<UploadTask>> enqueue(
    List<UploadFile> files, {
    UuidValue? parentUuid,
    String? parentName,
    String? batchId,
  }) async {
    final batch = batchId ?? _newId().uuid;
    final added = <UploadTask>[];
    for (final f in files) {
      // Only accepted files are read (DR-1); a file that can't be read any
      // more (moved, no permission) becomes a failed row.
      final Uint8List bytes;
      try {
        bytes = await f.readBytes();
      } on Object catch (e) {
        debugPrint('Reading ${f.name} failed: $e');
        _addFailed(
          f,
          UploadFailure.notSaved,
          parentUuid: parentUuid,
          parentName: parentName,
          error: '$e',
        );
        continue;
      }
      final itemUuid = _newId();
      final volatile = !storeAllBytes && bytes.length > storedBytesLimit;
      final t = UploadTask(
        id: itemUuid.uuid,
        batchId: batch,
        itemUuid: itemUuid,
        fileUuid: _newId(),
        parentUuid: parentUuid,
        parentName: parentName,
        fileName: f.name,
        sizeBytes: bytes.length,
        mimeType: f.mimeType,
        lastModified: f.lastModified,
        createdAt: _nextCreatedAt(),
        status: connectivity.online
            ? UploadStatus.queued
            : UploadStatus.waitingForNetwork,
        volatile: volatile,
      );
      _memory[t.id] = bytes;
      try {
        await store.add(t, volatile ? null : bytes);
      } on Object catch (e) {
        // Quota of the browser storage, …: keep it in memory.
        debugPrint('Storing an upload failed: $e');
        t.volatile = true;
        await _quietly(() => store.add(t, null));
      }
      _tasks.add(t);
      added.add(t);
    }
    notifyListeners();
    _pump();
    return added;
  }

  DateTime? _lastCreated;

  /// Strictly increasing creation times keep the queue order in the store.
  DateTime _nextCreatedAt() {
    var t = _now();
    final last = _lastCreated;
    if (last != null && !t.isAfter(last)) {
      t = last.add(const Duration(microseconds: 1));
    }
    return _lastCreated = t;
  }

  /// Shows files the pre-check refused (over the size limit) as failed
  /// rows of the panel (Drive 02 §3.2); they are not stored.
  void addRejected(
    List<UploadFile> files,
    UploadFailure failure, {
    UuidValue? parentUuid,
    String? parentName,
  }) {
    if (files.isEmpty) return;
    for (final f in files) {
      _addFailed(f, failure, parentUuid: parentUuid, parentName: parentName);
    }
    notifyListeners();
  }

  void _addFailed(
    UploadFile f,
    UploadFailure failure, {
    UuidValue? parentUuid,
    String? parentName,
    String? error,
  }) {
    final itemUuid = _newId();
    _tasks.add(
      UploadTask(
        id: itemUuid.uuid,
        batchId: itemUuid.uuid,
        itemUuid: itemUuid,
        fileUuid: _newId(),
        parentUuid: parentUuid,
        parentName: parentName,
        fileName: f.name,
        sizeBytes: f.size,
        mimeType: f.mimeType,
        createdAt: _nextCreatedAt(),
        status: UploadStatus.failed,
        failure: failure,
        error: error,
      ),
    );
  }

  /// Bytes of uploads that haven't reached the server yet (not reserved),
  /// for the offline quota pre-check (Drive 02 §4.2).
  int get unreservedBytes => _tasks
      .where(
        (t) =>
            (t.status == UploadStatus.queued ||
                t.status == UploadStatus.waitingForNetwork) &&
            !_created.contains(t.id),
      )
      .fold(0, (a, t) => a + t.sizeBytes);

  // ------------------------------------------------------------- actions

  /// Cancels [id] (queued or running): releases the server reservation.
  Future<void> cancel(String id, {bool byUndo = false}) async {
    final t = task(id);
    if (t == null || !t.status.isActive) return;
    if (byUndo) _cancelledByUndo.add(id);
    // `completeFileUpload` in flight: releasing now would race it; the
    // attempt settles the item when it returns (DR-2).
    final completing = t.status == UploadStatus.verifying;
    t
      ..status = UploadStatus.cancelled
      ..bytesSent = 0;
    _aborts[id]?.abort();
    _notBefore.remove(id);
    notifyListeners();
    await _save(t);
    if (!completing && _created.remove(id)) {
      try {
        await api.cancel(t.itemUuid);
      } on Object catch (e) {
        // Offline: the server expires the upload after 24 h.
        debugPrint('Cancelling upload ${t.fileName} failed: $e');
      }
    }
    if (!byUndo) _forgetBytes(t);
    _pump();
  }

  /// Cancels every running and queued upload.
  Future<int> cancelAll() async {
    final ids = [
      for (final t in _tasks)
        if (t.status.isActive) t.id,
    ];
    for (final id in ids) {
      await cancel(id);
    }
    return ids.length;
  }

  /// Starts [id] again from `createFileUpload`; [toMyDrive] moves it to
  /// My Drive (its folder is gone, Drive 02 §4.2).
  Future<bool> retry(String id, {bool toMyDrive = false}) async {
    final t = task(id);
    if (t == null) return false;
    final again =
        (t.status == UploadStatus.failed && (t.failure?.retryable ?? true)) ||
        (t.status == UploadStatus.cancelled && await _hasBytes(t));
    if (!again) return false;
    // A failed or cancelled item can't be started again on the server
    // ("This upload failed. Start a new one."): new ids. A network failure
    // may have left a pending upload that the same ids continue.
    final keepIds =
        t.status == UploadStatus.failed &&
        (t.failure == UploadFailure.network ||
            t.failure == UploadFailure.rateLimited);
    if (!keepIds) _rotate(t);
    if (toMyDrive) {
      t
        ..parentUuid = null
        ..parentName = null;
    }
    _cancelledByUndo.remove(id);
    t
      ..status = connectivity.online
          ? UploadStatus.queued
          : UploadStatus.waitingForNetwork
      ..attempts = 0
      ..failure = null
      ..error = null
      ..bytesSent = 0;
    _notBefore.remove(id);
    notifyListeners();
    await _save(t);
    _pump();
    return true;
  }

  /// Retries every failed upload that can be retried.
  Future<int> retryAll() async {
    var n = 0;
    for (final t in [..._tasks]) {
      if (t.status == UploadStatus.failed && await retry(t.id)) n++;
    }
    return n;
  }

  /// Removes finished rows (uploaded, failed, cancelled) from the panel.
  Future<int> clearFinished() async {
    final gone = [
      for (final t in _tasks)
        if (t.status.isFinished) t,
    ];
    for (final t in gone) {
      await remove(t.id);
    }
    return gone.length;
  }

  /// Removes [id] from the panel (cancels it first when it runs).
  Future<void> remove(String id) async {
    final t = task(id);
    if (t == null) return;
    if (t.status.isActive) await cancel(id);
    _tasks.remove(t);
    _memory.remove(id);
    _cancelledByUndo.remove(id);
    notifyListeners();
    await _quietly(() => store.remove(id));
  }

  // ----------------------------------------------------------------- run

  void _pump() {
    if (_disposed || !_started) return;
    _timer?.cancel();
    _timer = null;
    if (!connectivity.online) return;
    final now = _now();
    for (final t in _tasks) {
      if (_running.length >= parallel) break;
      if (t.status != UploadStatus.queued || _running.contains(t.id)) continue;
      final nb = _notBefore[t.id];
      if (nb != null && nb.isAfter(now)) continue;
      _running.add(t.id);
      unawaited(_run(t));
    }
    _scheduleNext();
  }

  void _scheduleNext() {
    if (_notBefore.isEmpty || !connectivity.online) return;
    final waiting = [
      for (final e in _notBefore.entries)
        if (task(e.key)?.status == UploadStatus.queued) e.value,
    ];
    if (waiting.isEmpty) return;
    final at = waiting.reduce((a, b) => a.isBefore(b) ? a : b);
    var delay = at.difference(_now());
    if (delay.isNegative) delay = Duration.zero;
    _timer = Timer(delay, _pump);
  }

  Future<void> _run(UploadTask t) async {
    final abort = UploadAbort();
    _aborts[t.id] = abort;
    try {
      await _attempt(t, abort);
    } finally {
      _aborts.remove(t.id);
      _running.remove(t.id);
      if (!_disposed) _pump();
    }
  }

  bool _stillWanted(UploadTask t, UploadAbort abort) =>
      !_disposed && !abort.aborted && _tasks.contains(t);

  Future<void> _attempt(UploadTask t, UploadAbort abort) async {
    final bytes = await _bytesOf(t);
    if (!_stillWanted(t, abort)) return;
    if (bytes == null) {
      await _fail(t, UploadFailure.notSaved, null);
      return;
    }
    var restarted = false;
    while (true) {
      try {
        _set(t, UploadStatus.starting);
        final request = FileUploadRequest(
          itemUuid: t.itemUuid,
          fileUuid: t.fileUuid,
          parentUuid: t.parentUuid,
          name: t.fileName,
          sizeBytes: t.sizeBytes,
          declaredMimeType: t.mimeType,
          lastModified: t.lastModified?.toUtc(),
          conflict: UploadConflictMode.keepBoth,
        );
        final start = await api.create(request);
        if (abort.aborted && !_disposed) {
          // Cancelled while `createFileUpload` was in flight: [cancel]
          // found nothing to release, so release the reservation the
          // server just made (by the requested ids: a retry may have
          // rotated the task's ids meanwhile).
          await _quietly(() => api.cancel(request.itemUuid));
          return;
        }
        _created.add(t.id);
        if (!_stillWanted(t, abort)) return;
        final description = start.ticket.uploadDescription;
        if (description != null) {
          t
            ..bytesSent = 0
            ..sendingSince = _now();
          _set(t, UploadStatus.uploading);
          var lastPercent = -1;
          await api.send(
            description,
            bytes,
            abort: abort,
            onProgress: (sent) {
              t.bytesSent = sent;
              final p = t.sizeBytes == 0 ? 100 : sent * 100 ~/ t.sizeBytes;
              if (p != lastPercent && !_disposed) {
                lastPercent = p;
                notifyListeners();
              }
            },
          );
        }
        if (!_stillWanted(t, abort)) return;
        _set(t, UploadStatus.verifying);
        DriveItemView item;
        // The ids this attempt completes: an undo + redo while the call is in
        // flight rotates the task's ids (and the redo reserves its own).
        final itemUuid = t.itemUuid;
        try {
          item = await api.complete(itemUuid);
        } on Object {
          if (abort.aborted && !_disposed) {
            // Cancelled while completing, and the completion failed: the
            // reservation is still pending; release it (DR-2). [cancel]
            // skips the release while completing, so this attempt owns it.
            if (t.itemUuid == itemUuid) _created.remove(t.id);
            await _quietly(() => api.cancel(itemUuid));
            return;
          }
          rethrow;
        }
        if (abort.aborted && !_disposed && _tasks.contains(t)) {
          // Cancelled while completing, but the file is stored: the row
          // says so instead of "Cancelled" (DR-2; no conversion).
          _created.remove(t.id);
          await _finish(t, item);
          return;
        }
        if (!_stillWanted(t, abort)) return;
        _created.remove(t.id);
        final target = convertTo?.call(t);
        if (target != null) {
          try {
            item = await api.convert(item.uuid, target);
          } on Object catch (e) {
            // Kept as the uploaded file (the host tells the user).
            debugPrint('Converting ${t.fileName} failed: $e');
            t.conversionFailed = true;
          }
          if (!_stillWanted(t, abort)) return;
        }
        await _finish(t, item);
        return;
      } on UploadAborted {
        return;
      } on WonkyException catch (e) {
        if (!_stillWanted(t, abort)) return;
        // The server failed the item (incomplete upload) or refuses the
        // ids of a failed one: start once more with new ids.
        final restart =
            !restarted &&
            ((e.code == WonkyErrorCode.invalidArgument &&
                    t.status == UploadStatus.verifying) ||
                (e.code == WonkyErrorCode.conflict &&
                    t.status == UploadStatus.starting));
        if (restart) {
          restarted = true;
          _created.remove(t.id);
          _rotate(t);
          await _save(t);
          continue;
        }
        await _fail(t, _failureOf(e), e.message);
        return;
      } on Object catch (e) {
        if (!_stillWanted(t, abort)) return;
        if (isOfflineError(e)) connectivity.reportFailure();
        await _networkFailure(t, e);
        return;
      }
    }
  }

  /// The file is stored: the row is done.
  Future<void> _finish(UploadTask t, DriveItemView item) async {
    t
      ..status = UploadStatus.done
      ..result = item
      ..failure = null
      ..error = null
      ..attempts = 0
      ..bytesSent = t.sizeBytes;
    notifyListeners();
    await _save(t);
    _forgetBytes(t);
    if (!_events.isClosed) _events.add(UploadEvent(t, done: true));
  }

  UploadFailure _failureOf(WonkyException e) => switch (e.code) {
    WonkyErrorCode.quotaExceeded => UploadFailure.outOfStorage,
    WonkyErrorCode.tooLarge => UploadFailure.tooLarge,
    WonkyErrorCode.notFound ||
    WonkyErrorCode.forbidden => UploadFailure.folderGone,
    WonkyErrorCode.limitExceeded => UploadFailure.rateLimited,
    _ => UploadFailure.other,
  };

  Future<void> _networkFailure(UploadTask t, Object e) async {
    t
      ..attempts = t.attempts + 1
      ..bytesSent = 0
      ..error = '$e';
    if (!connectivity.online) {
      t.status = UploadStatus.waitingForNetwork;
    } else if (t.attempts >= maxAutomaticAttempts) {
      t
        ..status = UploadStatus.failed
        ..failure = UploadFailure.network;
      if (!_events.isClosed) _events.add(UploadEvent(t, done: false));
    } else {
      t.status = UploadStatus.queued;
      _notBefore[t.id] = _now().add(backoff(t.attempts));
    }
    notifyListeners();
    await _save(t);
  }

  /// 2 s, 4 s, 8 s … at most 10 min, ±20 % jitter (Drive 02 §4.2).
  Duration backoff(int attempt) {
    final seconds = min(600, 2 * pow(2, max(0, attempt - 1)).toInt());
    final jitter = 0.8 + _random.nextDouble() * 0.4;
    return Duration(milliseconds: (seconds * 1000 * jitter).round());
  }

  Future<void> _fail(UploadTask t, UploadFailure f, String? message) async {
    _created.remove(t.id);
    t
      ..status = UploadStatus.failed
      ..failure = f
      ..error = message
      ..bytesSent = 0;
    notifyListeners();
    await _save(t);
    if (!f.retryable) _forgetBytes(t);
    if (!_events.isClosed) _events.add(UploadEvent(t, done: false));
  }

  void _set(UploadTask t, UploadStatus s) {
    t.status = s;
    notifyListeners();
    unawaited(_save(t));
  }

  void _rotate(UploadTask t) {
    t
      ..itemUuid = _newId()
      ..fileUuid = _newId();
  }

  Future<Uint8List?> _bytesOf(UploadTask t) async {
    final m = _memory[t.id];
    if (m != null) return m;
    try {
      final b = await store.bytes(t.id);
      if (b != null) _memory[t.id] = b;
      return b;
    } on Object catch (e) {
      debugPrint('Reading upload bytes failed: $e');
      return null;
    }
  }

  Future<bool> _hasBytes(UploadTask t) async => await _bytesOf(t) != null;

  void _forgetBytes(UploadTask t) {
    _memory.remove(t.id);
    unawaited(_quietly(() => store.dropBytes(t.id)));
  }

  Future<void> _save(UploadTask t) async {
    if (!_tasks.contains(t)) return;
    await _quietly(() => store.update(t));
  }

  static Future<void> _quietly(Future<void> Function() f) async {
    try {
      await f();
    } on Object catch (e) {
      debugPrint('Upload store: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    connectivity.removeListener(_onConnectivity);
    for (final a in _aborts.values) {
      a.abort();
    }
    unawaited(_events.close());
    unawaited(_quietly(store.close));
    super.dispose();
  }
}
