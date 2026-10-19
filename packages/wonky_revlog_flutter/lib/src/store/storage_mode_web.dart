import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// The SQLite worker picks OPFS when the browser offers the origin private
/// file system with synchronous access handles in workers, else IndexedDB
/// (`WebSqlite.connectToRecommended`). The app can't ask the worker which
/// one it chose, so this checks the same prerequisites: a secure context,
/// `FileSystemFileHandle` and a usable `navigator.storage.getDirectory()`
/// (it rejects in private windows of some browsers).
Future<bool> offlineStorageLimited() async {
  try {
    if (!web.window.isSecureContext) return true;
    if (!globalContext.has('FileSystemFileHandle')) return true;
    final storage = web.window.navigator.storage;
    if (!(storage as JSObject).has('getDirectory')) return true;
    await storage.getDirectory().toDart;
    return false;
  } catch (_) {
    return true;
  }
}
