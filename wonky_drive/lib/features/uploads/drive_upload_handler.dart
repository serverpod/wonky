import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;

import '../../l10n/drive_l10n.dart';
import 'upload_host.dart';
import 'upload_queue.dart';

/// A picked file whose content is read on demand (DR-1): the batch
/// pre-checks (count, size, quota) run on [size], the picker's metadata,
/// and only the files the queue accepts are read. Its [bytes] are not
/// available (only Drive's [DriveUploadHandler.importFiles] receives it).
class LazyImportFile extends ImportFile {
  const LazyImportFile({
    required super.name,
    required this.size,
    required this.read,
    super.mimeType,
    super.lastModified,
    super.folderPath,
  }) : super(bytes: const []);

  /// The size in bytes, as the picker reports it.
  final int size;

  /// Reads the content.
  final Future<Uint8List> Function() read;

  @override
  List<int> get bytes =>
      throw UnsupportedError('LazyImportFile: read the content with read()');
}

/// Drive's [ImportHandler] (Drive 05 §1): *File upload…* (`shell.drive
/// .upload`) and drops on the home upload every file type as a `file`
/// item through the upload queue instead of importing it. The files are
/// staged and handed to `drive.upload.files` (one undo step per batch).
class DriveUploadHandler implements ImportHandler {
  const DriveUploadHandler();

  /// Every extension: Drive stores any file (the shell's drop handler
  /// checks `HomeScope.uploadsFiles` instead of this set).
  @override
  Set<String> get extensions => const {};

  @override
  Future<List<ImportFile>> pickFiles(BuildContext context) async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: driveL10n(context).uploadPickTitle,
    );
    return [for (final f in picked) await lazyImportFileOf(f)];
  }

  /// [f] as a [LazyImportFile]: its size comes from the picker (no read
  /// where the platform reports it), its content is read when queued.
  @visibleForTesting
  static Future<LazyImportFile> lazyImportFileOf(PlatformFile f) async {
    var size = f.lengthSync();
    if (size == null) {
      try {
        size = await f.length();
      } on Object {
        size = null;
      }
    }
    if (size == null) {
      // Unknown size: read it now so the pre-checks see the real size.
      final bytes = await f.readAsBytes();
      return LazyImportFile(
        name: f.name,
        size: bytes.length,
        read: () async => bytes,
        mimeType: f.xFile.mimeType,
        lastModified: await _lastModified(f),
      );
    }
    return LazyImportFile(
      name: f.name,
      size: size,
      read: f.readAsBytes,
      mimeType: f.xFile.mimeType,
      lastModified: await _lastModified(f),
    );
  }

  static Future<DateTime?> _lastModified(PlatformFile f) async {
    try {
      return await f.xFile.lastModified();
    } on Object {
      return null;
    }
  }

  /// [f] as an [UploadFile]; a [LazyImportFile] stays unread.
  @visibleForTesting
  static UploadFile uploadFileOf(ImportFile f) => switch (f) {
    LazyImportFile() => UploadFile.lazy(
      name: f.name,
      size: f.size,
      read: f.read,
      mimeType: f.mimeType,
      lastModified: f.lastModified,
      folderPath: f.folderPath,
    ),
    _ => UploadFile(
      name: f.name,
      bytes: f.bytes is Uint8List
          ? f.bytes as Uint8List
          : Uint8List.fromList(f.bytes),
      mimeType: f.mimeType,
      lastModified: f.lastModified,
      folderPath: f.folderPath,
    ),
  };

  /// Queues [files] for [parentUuid]; returns no items (they appear in the
  /// list when each upload completes).
  @override
  Future<List<DriveItemView>> importFiles(
    BuildContext context,
    ShellServices services,
    List<ImportFile> files, {
    UuidValue? parentUuid,
  }) async {
    final host = UploadHost.of(services);
    final staged = host.stage([for (final f in files) uploadFileOf(f)]);
    await services.dispatcher.invoke(
      'drive.upload.files',
      args: {'staged': staged, 'parentUuid': ?parentUuid?.uuid},
      source: InvocationSource.ui,
      context: context.mounted ? context : null,
    );
    // Not used by a cancelled dialog.
    host.takeStaged(staged);
    return const [];
  }
}
