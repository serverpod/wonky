import 'storage_mode_io.dart'
    if (dart.library.js_interop) 'storage_mode_web.dart'
    as platform;

/// Whether the replica can't use OPFS and falls back to IndexedDB, which
/// keeps the whole database in memory (suite 12 intro): offline
/// availability is then capped. Always false on desktop.
Future<bool> offlineStorageLimited() => platform.offlineStorageLimited();
