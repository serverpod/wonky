import 'package:flutter/foundation.dart';
import 'package:wonky_app/uploads.dart';
import 'package:wonky_app/wonky_app.dart';

/// Schema of `slides_uploads_<userId>.db` (suite 12 §1.1
/// `LocalPendingUpload`): images inserted on this device that are not on
/// the server yet. Local only.
final slidesUploadMigrations = SqliteMigrations()
  ..add(SqliteMigration(1, createPendingUploadTable));

/// Durable image uploads of Slides (03 §6.5.1): the shell's
/// [PendingUploadQueue] (also Sheets'), so an image element references
/// `wonky-file://<uuid>` at once, renders from the local bytes and uploads
/// when the server is reachable; a quota refusal opens the *Out of storage*
/// dialog. One queue per signed-in user ([install]).
class SlidesPendingUploads extends PendingUploadQueue<PendingUploadStore> {
  SlidesPendingUploads({
    required super.store,
    required super.files,
    required super.connectivity,
    super.maxAttempts,
    super.onQuotaRefused,
  }) : super(label: 'Slides upload');

  static final Expando<PerUserInstallation<SlidesPendingUploads>> _installs =
      Expando('SlidesPendingUploads');

  /// `slides_uploads_<userId>.db`.
  static String fileNameFor(String userUuid) => 'slides_uploads_$userUuid.db';

  /// Opens the signed-in user's queue now and whenever the user changes
  /// (idempotent). [openStore] overrides the SQLite store (tests).
  static void install(
    ShellServices services, {
    Future<PendingUploadStore> Function(String userUuid)? openStore,
  }) {
    if (_installs[services] != null) return;
    final open =
        openStore ??
        (user) async => SqlitePendingUploadStore(
          await LocalDatabases.open(
            fileNameFor(user),
            migrations: slidesUploadMigrations,
          ),
        );
    _installs[services] = PerUserInstallation<SlidesPendingUploads>(
      services,
      open: (user, isCurrent) async {
        PendingUploadStore store;
        try {
          store = await open(user);
        } on Object catch (e) {
          // No SQLite (unsupported browser): uploads still work for this
          // session from memory.
          debugPrint('Opening the Slides upload queue failed: $e');
          store = MemoryPendingUploadStore();
        }
        if (!isCurrent()) {
          await store.close();
          return null;
        }
        return SlidesPendingUploads(
          store: store,
          files: services.repositories.files,
          connectivity: services.connectivity,
          onQuotaRefused: (e) =>
              services.quotaErrors.present(e, reason: QuotaReasons.image),
        );
      },
      started: (q) => q.start(),
      close: (q) => q.dispose(),
    )..attach();
  }

  /// Installs [queue] for [services] without a user (widget tests).
  @visibleForTesting
  static void installQueue(ShellServices services, SlidesPendingUploads queue) {
    _installs[services] = PerUserInstallation<SlidesPendingUploads>(
      services,
      open: (_, _) async => queue,
      close: (q) => q.dispose(),
    )..use(queue);
  }

  /// The signed-in user's queue (null while opening, signed out or not
  /// installed).
  static SlidesPendingUploads? of(ShellServices services) =>
      _installs[services]?.value;

  /// The queue once open (null when unavailable).
  static Future<SlidesPendingUploads?> ready(ShellServices services) async {
    final inst = _installs[services];
    if (inst == null) return null;
    await inst.opening;
    return inst.value;
  }
}
