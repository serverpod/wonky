import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/uploads.dart';
import 'package:wonky_app/wonky_app.dart';

/// Schema of `sheets_uploads_<userId>.db` (suite 12 §1.1
/// `LocalPendingUpload`): image files of this device that are not on the
/// server yet (imported XLSX images, inserted images), and the recently
/// imported files (*Recent uploads*). Local only.
final sheetsUploadMigrations = SqliteMigrations()
  ..add(SqliteMigration(1, createPendingUploadTable))
  ..add(
    SqliteMigration(2, (tx) async {
      await tx.execute('''
        CREATE TABLE local_recent_import (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          size INTEGER NOT NULL,
          bytes BLOB NOT NULL,
          imported_at INTEGER NOT NULL
        )''');
    }),
  );

/// A file imported on this device (*Recent uploads* of the import dialog,
/// 11 §2.1).
@immutable
class RecentImport {
  const RecentImport({
    required this.id,
    required this.name,
    required this.size,
    required this.importedAt,
  });

  final String id;
  final String name;
  final int size;
  final DateTime importedAt;
}

/// The shell's [PendingUploadStore] plus the recent imports of this device.
abstract class SheetsUploadStore implements PendingUploadStore {
  /// Recent imports, newest first (without bytes).
  Future<List<RecentImport>> recent();
  Future<Uint8List?> recentBytes(String id);

  /// Stores [bytes] as a recent import and keeps the newest [keep].
  Future<void> putRecent(RecentImport r, Uint8List bytes, {int keep = 8});
}

/// [SheetsUploadStore] on the per-user SQLite database.
class SqliteSheetsUploadStore extends SqlitePendingUploadStore
    implements SheetsUploadStore {
  SqliteSheetsUploadStore(super.db);

  @override
  Future<List<RecentImport>> recent() async => [
    for (final r in await db.getAll(
      'SELECT id, name, size, imported_at FROM local_recent_import '
      'ORDER BY imported_at DESC',
    ))
      RecentImport(
        id: r['id']! as String,
        name: r['name']! as String,
        size: r['size']! as int,
        importedAt: DateTime.fromMillisecondsSinceEpoch(
          r['imported_at']! as int,
        ),
      ),
  ];

  @override
  Future<Uint8List?> recentBytes(String id) async {
    final r = await db.getOptional(
      'SELECT bytes FROM local_recent_import WHERE id = ?',
      [id],
    );
    return switch (r?['bytes']) {
      final Uint8List b => b,
      final List<int> b => Uint8List.fromList(b),
      _ => null,
    };
  }

  @override
  Future<void> putRecent(RecentImport r, Uint8List bytes, {int keep = 8}) =>
      db.writeTransaction((tx) async {
        await tx.execute(
          'DELETE FROM local_recent_import WHERE name = ? AND size = ?',
          [r.name, r.size],
        );
        await tx.execute(
          'INSERT OR REPLACE INTO local_recent_import (id, name, size, bytes, '
          'imported_at) VALUES (?, ?, ?, ?, ?)',
          [r.id, r.name, r.size, bytes, r.importedAt.millisecondsSinceEpoch],
        );
        await tx.execute(
          'DELETE FROM local_recent_import WHERE id NOT IN (SELECT id FROM '
          'local_recent_import ORDER BY imported_at DESC LIMIT ?)',
          [keep],
        );
      });
}

/// [SheetsUploadStore] in memory (tests).
class MemorySheetsUploadStore extends MemoryPendingUploadStore
    implements SheetsUploadStore {
  final List<(RecentImport, Uint8List)> recents = [];

  @override
  Future<List<RecentImport>> recent() async => [
    for (final (r, _) in recents) r,
  ];

  @override
  Future<Uint8List?> recentBytes(String id) async {
    for (final (r, b) in recents) {
      if (r.id == id) return b;
    }
    return null;
  }

  @override
  Future<void> putRecent(
    RecentImport r,
    Uint8List bytes, {
    int keep = 8,
  }) async {
    recents.removeWhere((e) => e.$1.name == r.name && e.$1.size == r.size);
    recents.insert(0, (r, bytes));
    if (recents.length > keep) recents.removeRange(keep, recents.length);
  }
}

/// Durable image uploads of Sheets (like Write's images): the shell's
/// [PendingUploadQueue] (also Slides'), so a spreadsheet can reference
/// `wonky-file://<uuid>` at once, show the image from the local bytes and
/// upload it when the server is reachable; plus the *Recent uploads* of the
/// import dialog. One queue per signed-in user ([install] at command
/// registration).
class SheetsPendingUploads extends PendingUploadQueue<SheetsUploadStore> {
  SheetsPendingUploads({
    required super.store,
    required super.files,
    required super.connectivity,
    super.maxAttempts,
  }) : super(label: 'upload');

  /// Files above this size are not kept as recent imports.
  static const maxRecentBytes = 10 * 1024 * 1024;

  /// Remembers an imported file for *Recent uploads* (small files only).
  Future<void> recordRecentImport(String name, Uint8List bytes) async {
    if (bytes.length > maxRecentBytes) return;
    try {
      await store.putRecent(
        RecentImport(
          id: '${clock.now().microsecondsSinceEpoch}',
          name: name,
          size: bytes.length,
          importedAt: clock.now(),
        ),
        bytes,
      );
    } on Object catch (e) {
      debugPrint('Storing a recent import failed: $e');
    }
  }

  /// Recent imports of this device, newest first.
  Future<List<RecentImport>> recentImports() async {
    try {
      return await store.recent();
    } on Object catch (e) {
      debugPrint('Reading recent imports failed: $e');
      return const [];
    }
  }

  /// The bytes of a recent import.
  Future<Uint8List?> recentImportBytes(String id) => store.recentBytes(id);

  // ------------------------------------------------------- per user

  static final Expando<PerUserInstallation<SheetsPendingUploads>> _installs =
      Expando('SheetsPendingUploads');

  /// `sheets_uploads_<userId>.db`.
  static String fileNameFor(String userUuid) => 'sheets_uploads_$userUuid.db';

  /// Opens the signed-in user's queue now and whenever the user changes
  /// (idempotent). [openStore] overrides the SQLite store (tests).
  static void install(
    ShellServices services, {
    Future<SheetsUploadStore> Function(String userUuid)? openStore,
  }) {
    if (_installs[services] != null) return;
    final open =
        openStore ??
        (user) async => SqliteSheetsUploadStore(
          await LocalDatabases.open(
            fileNameFor(user),
            migrations: sheetsUploadMigrations,
          ),
        );
    _installs[services] = PerUserInstallation<SheetsPendingUploads>(
      services,
      open: (user, isCurrent) async {
        try {
          final store = await open(user);
          if (!isCurrent()) {
            await store.close();
            return null;
          }
          return SheetsPendingUploads(
            store: store,
            files: services.repositories.files,
            connectivity: services.connectivity,
          );
        } on Object catch (e) {
          debugPrint('Opening the Sheets upload queue failed: $e');
          return null;
        }
      },
      started: (q) => q.start(),
      close: (q) => q.dispose(),
    )..attach();
  }

  /// Installs [queue] for [services] without a user (widget tests).
  @visibleForTesting
  static void installQueue(ShellServices services, SheetsPendingUploads queue) {
    _installs[services] = PerUserInstallation<SheetsPendingUploads>(
      services,
      open: (_, _) async => queue,
      close: (q) => q.dispose(),
    )..use(queue);
  }

  /// The signed-in user's queue (null while opening, signed out or not
  /// installed).
  static SheetsPendingUploads? of(ShellServices services) =>
      _installs[services]?.value;

  /// The queue once open (null when unavailable).
  static Future<SheetsPendingUploads?> ready(ShellServices services) async {
    final inst = _installs[services];
    if (inst == null) return null;
    await inst.opening;
    return inst.value;
  }
}
