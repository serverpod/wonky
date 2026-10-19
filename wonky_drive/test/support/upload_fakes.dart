import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart' show pumpEventQueue;
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/features/uploads/upload_api.dart';
import 'package:wonky_drive/features/uploads/upload_queue.dart';

/// In-memory [UploadApi] (Drive 05 D-13 tests): records the calls, keeps
/// the created items, and fails or holds calls on request.
class FakeUploadApi implements UploadApi {
  FakeUploadApi({this.owner});

  final UserSummary? owner;

  /// Every call in order: `create:a.txt`, `send:a.txt`, `complete:a.txt`,
  /// `cancel:a.txt`.
  final List<String> calls = [];

  /// Errors thrown by the next calls of a phase for a file name
  /// (`create`/`send`/`complete`), consumed in order.
  final Map<String, List<Object>> errors = {};

  /// Holds `send` of a file name until completed.
  final Map<String, Completer<void>> sendGates = {};

  /// Holds `create` of a file name (after the server made the reservation)
  /// until completed.
  final Map<String, Completer<void>> createGates = {};

  /// Holds `complete` of a file name (before it succeeds or fails) until
  /// completed.
  final Map<String, Completer<void>> completeGates = {};

  /// Every `send` waits for this when set (parallelism tests).
  Completer<void>? allSendsGate;

  /// Names in folders (`null` key = My Drive), lower case.
  final Map<String?, Set<String>> names = {};

  /// Items by item uuid (created on `create`, ready on `complete`).
  final Map<UuidValue, DriveItemView> items = {};

  /// File name of an item uuid.
  final Map<UuidValue, String> _names = {};

  /// Requests of `create`.
  final List<FileUploadRequest> requests = [];

  /// Called with each item that became ready (tests mirror it into the
  /// fake drive).
  void Function(DriveItemView item)? onReady;

  /// Sends running right now (parallelism).
  int running = 0;
  int maxRunning = 0;

  void failNext(String phase, String fileName, Object error) =>
      (errors['$phase:$fileName'] ??= []).add(error);

  void _maybeThrow(String phase, String name) {
    calls.add('$phase:$name');
    final list = errors['$phase:$name'];
    if (list != null && list.isNotEmpty) throw list.removeAt(0);
  }

  @override
  Future<FileUploadStart> create(FileUploadRequest request) async {
    requests.add(request);
    _maybeThrow('create', request.name);
    _names[request.itemUuid] = request.name;
    final item = fileView(
      request.itemUuid,
      request.name,
      parentUuid: request.parentUuid,
      size: request.sizeBytes,
      state: FileUploadState.uploading,
      owner: owner,
    );
    items[request.itemUuid] = item;
    await createGates[request.name]?.future;
    return FileUploadStart(
      item: item,
      ticket: FileUploadTicket(
        fileUuid: request.fileUuid,
        uploadDescription: request.sizeBytes == 0
            ? null
            : jsonEncode({
                'type': 'binary',
                'url': 'https://store.test/up/${request.itemUuid.uuid}',
              }),
        status: StoredFileStatus.pending,
      ),
      storage: FakeStorage.usageOf(0),
    );
  }

  @override
  Future<void> send(
    String uploadDescription,
    Uint8List bytes, {
    required void Function(int sent) onProgress,
    required UploadAbort abort,
  }) async {
    final url = Uri.parse(
      (jsonDecode(uploadDescription) as Map)['url'] as String,
    );
    final name = _names[UuidValue.fromString(url.pathSegments.last)]!;
    running++;
    if (running > maxRunning) maxRunning = running;
    try {
      calls.add('send:$name');
      final list = errors['send:$name'];
      if (list != null && list.isNotEmpty) throw list.removeAt(0);
      onProgress(bytes.length ~/ 2);
      final done = Completer<void>();
      abort.onAbort = () {
        if (!done.isCompleted) done.completeError(const UploadAborted());
      };
      final gate = sendGates[name] ?? allSendsGate;
      unawaited(
        (gate?.future ?? Future<void>.value()).then((_) {
          if (!done.isCompleted) done.complete();
        }),
      );
      await done.future;
      onProgress(bytes.length);
    } finally {
      running--;
    }
  }

  @override
  Future<DriveItemView> complete(UuidValue itemUuid) async {
    final name = _names[itemUuid] ?? '?';
    await completeGates[name]?.future;
    _maybeThrow('complete', name);
    final v = items[itemUuid]!.copyWith(uploadState: FileUploadState.ready);
    items[itemUuid] = v;
    onReady?.call(v);
    return v;
  }

  @override
  Future<void> cancel(UuidValue itemUuid) async {
    calls.add('cancel:${_names[itemUuid] ?? '?'}');
    items.remove(itemUuid);
  }

  @override
  Future<Set<String>> namesIn(UuidValue? parentUuid) async {
    calls.add('namesIn');
    return names[parentUuid?.uuid] ?? const {};
  }

  /// Items made by [convert] (by the uploaded file's uuid).
  final Map<UuidValue, DriveItemView> converted = {};

  @override
  Future<DriveItemView> convert(
    UuidValue fileItemUuid,
    DriveItemKind target,
  ) async {
    final file = items[fileItemUuid]!;
    _maybeThrow('convert', file.name);
    final dot = file.name.lastIndexOf('.');
    final v = file.copyWith(
      uuid: UuidValue.fromString(
        '00000000-0000-7000-b000-${(converted.length + 1).toString().padLeft(12, '0')}',
      ),
      kind: target,
      name: dot > 0 ? file.name.substring(0, dot) : file.name,
      mimeType: null,
      fileCategory: null,
    );
    items.remove(fileItemUuid);
    converted[fileItemUuid] = v;
    onReady?.call(v);
    return v;
  }

  /// The ready items, by name.
  Map<String, DriveItemView> get ready => {
    for (final i in items.values)
      if (i.uploadState == FileUploadState.ready) i.name: i,
  };
}

/// A `file` drive item view.
DriveItemView fileView(
  UuidValue uuid,
  String name, {
  UuidValue? parentUuid,
  int size = 0,
  FileUploadState state = FileUploadState.ready,
  UserSummary? owner,
}) {
  final now = DateTime.utc(2026, 10, 1, 12);
  return DriveItemView(
    uuid: uuid,
    kind: DriveItemKind.file,
    name: name,
    parentUuid: parentUuid,
    owner: owner ?? TestUsers.anna,
    role: AccessRole.owner,
    shared: false,
    sizeBytes: size,
    createdAt: now,
    modifiedAt: now,
    starred: false,
    pinnedOffline: false,
    editorsCanShare: true,
    nonEditorsCanExport: true,
    viewersSeeComments: true,
    mimeType: 'text/plain',
    fileCategory: FileCategory.text,
    uploadState: state,
  );
}

/// [n] bytes of `x`.
Uint8List bytesOf(int n) => Uint8List.fromList(List.filled(n, 0x78));

/// A text file to upload.
UploadFile textFile(String name, [int size = 10]) =>
    UploadFile(name: name, bytes: bytesOf(size), mimeType: 'text/plain');

/// Deterministic ids `00000000-0000-7000-8000-<n>`.
UuidValue Function() sequentialIds([int start = 1]) {
  var n = start;
  return () => UuidValue.fromString(
    '00000000-0000-7000-8000-${(n++).toString().padLeft(12, '0')}',
  );
}

/// Lets the queue's futures run (memory store, fake API).
Future<void> settle() => pumpEventQueue(times: 40);

/// A connectivity service whose state the test sets with
/// `forceOffline` (reset `Api.simulatedOffline` in tearDown).
ConnectivityService testConnectivity() =>
    ConnectivityService(ping: () async {});
