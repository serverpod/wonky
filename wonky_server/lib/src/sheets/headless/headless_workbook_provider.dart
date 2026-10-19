import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../../platform/common/errors.dart';
import '../../platform/common/keyed_lock.dart';
import '../../platform/common/models.dart';
import '../../platform/revlog/headless_file_cache.dart';
import '../revlog/sheets_rev_binding.dart';
import 'headless_workbook.dart';

/// Server-side workbooks of spreadsheets (Sheets 12 §2.3) over the RevLog
/// headless cache (RevLog spec 05 §9): a model is loaded once and follows
/// the file's ops, so there is no staleness check, write-through or patch.
/// A facade that keeps the call sites of MCP, AI, scripts and versions.
abstract final class HeadlessWorkbookProvider {
  /// Memory budget of all headless models (both apps).
  static int get budgetBytes => HeadlessFileCache.budgetBytes;
  static set budgetBytes(int v) => HeadlessFileCache.budgetBytes = v;

  /// Fails a waiting [withWriteLock] after this long.
  static Duration get lockTimeout => _lock.timeout;
  static set lockTimeout(Duration v) => _lock.timeout = v;

  static final _lock = KeyedLock();

  /// Number of cold loads (tests).
  static int get loads => HeadlessFileCache.coldLoads;

  /// Files with a cached workbook.
  static Iterable<UuidValue> get cachedSpaces => HeadlessFileCache.cachedFiles;

  /// The cached workbook of [space] without loading (tests).
  static HeadlessWorkbook? peek(UuidValue space) =>
      HeadlessFileCache.peek(space) as HeadlessWorkbook?;

  /// The workbook of [space] at the current head (loaded on first use).
  /// The model stays leased (never evicted) until [session] closes, so a
  /// caller holding it across awaits keeps a live model.
  static Future<HeadlessWorkbook> open(Session session, UuidValue space) async {
    final binding = SheetsRevBinding.instance;
    final lease = await HeadlessFileCache.open(session, binding, space);
    if (lease == null) throw Errors.notFound('Spreadsheet');
    try {
      final file = await RevFile.db.findFirstRow(
        session,
        where: (t) => t.fileUuid.equals(space),
      );
      if (file != null) await lease.ensureAtLeast(session, file.headRevision);
      final model = lease.model as HeadlessWorkbook;
      session.addWillCloseListener((_) => lease.release());
      return model;
    } catch (_) {
      lease.release();
      rethrow;
    }
  }

  /// Drops every model (tests).
  static void clear() => HeadlessFileCache.clear();

  /// Runs [body] holding the write lock of [space] (Sheets 12 §2.3:
  /// planning server changes of one spreadsheet is serialized per
  /// instance). Fails with `busy` after [lockTimeout].
  static Future<T> withWriteLock<T>(
    UuidValue space,
    Future<T> Function() body,
  ) => _lock.run(
    space.uuid,
    body,
    busy: () => Errors.busy(
      'Another change to this spreadsheet is still running. Try again.',
    ),
  );
}
