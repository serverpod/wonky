import 'dart:async';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import 'rev_binding.dart';
import 'rev_file_state.dart';
import 'rev_sql.dart';
import 'rev_views.dart';

/// A use of a headless model (RevLog spec 05 §9). The model is live: it
/// follows the file's ops. Plan against it under the file lock
/// ([RevFileState.lock]) for a consistent revision.
final class HeadlessLease {
  HeadlessLease._(this._entry);

  final _HeadlessEntry _entry;
  bool _released = false;

  /// The model.
  Object get model => _entry.model!;

  /// The revision the model reflects.
  int get revision => _entry.revision;

  /// The file state.
  RevFileState get state => _entry.state;

  /// Waits until the model reflects [minRevision] (when it exists).
  Future<void> ensureAtLeast(Session session, int minRevision) =>
      _entry.ensureAtLeast(session, minRevision);

  /// Ends the use; the model may be evicted afterwards.
  void release() {
    if (_released) return;
    _released = true;
    _entry.leases--;
    _entry.lastUsed = clock.now();
    HeadlessFileCache._evictOverBudget();
  }
}

final class _HeadlessEntry {
  _HeadlessEntry(this.binding, this.state, this.stateLease);

  final RevBinding binding;
  final RevFileState state;
  final RevFileLease stateLease;
  Object? model;
  int revision = 0;
  int leases = 0;
  int bytes = 0;
  int appliedSinceEstimate = 0;
  DateTime lastUsed = clock.now();
  void Function()? unlisten;
  final List<RevOpView> _buffer = [];
  bool _loaded = false;
  Future<void> _gapFill = Future.value();
  Session? _session;

  void onOp(RevOpView op) {
    if (!_loaded) {
      _buffer.add(op);
      return;
    }
    _apply(op);
  }

  void _apply(RevOpView op) {
    if (op.revision <= revision) return;
    if (op.revision > revision + 1) {
      final s = _session;
      if (s == null) return;
      final from = revision + 1;
      _gapFill = _gapFill.then((_) async {
        final views = await RevViews.read(
          s,
          binding.codec,
          state.fileId,
          from,
          op.revision,
        );
        for (final v in views) {
          _applyNow(v);
        }
      });
      return;
    }
    _applyNow(op);
  }

  void _applyNow(RevOpView op) {
    if (op.revision != revision + 1) return;
    binding.applyToModel(model!, RevViews.appliedOf(binding.codec, op));
    revision = op.revision;
    if (++appliedSinceEstimate >= 1000) {
      appliedSinceEstimate = 0;
      bytes = binding.estimateBytes(model!);
    }
  }

  Future<void> ensureAtLeast(Session session, int minRevision) async {
    await state.ensureAtLeast(session, minRevision);
    await _gapFill;
    if (revision < minRevision && revision < state.revision) {
      final views = await RevViews.read(
        session,
        binding.codec,
        state.fileId,
        revision + 1,
        state.revision,
      );
      for (final v in views) {
        _applyNow(v);
      }
    }
  }

  void dispose() {
    unlisten?.call();
    stateLease.release();
    model = null;
    final s = _session;
    _session = null;
    if (s != null) unawaited(s.close());
  }
}

/// The headless model cache of both apps (RevLog spec 05 §9), replacing
/// `HeadlessWorkbookProvider` and `HeadlessDeckCache`.
abstract final class HeadlessFileCache {
  /// Memory budget (`revlog.headlessBudgetMb`).
  static int budgetBytes = 2048 << 20;

  /// Max cached models (`revlog.headlessMaxEntries`).
  static int maxEntries = 100;

  /// Cold loads (a metric; tests).
  static int coldLoads = 0;

  static final Map<String, _HeadlessEntry> _entries = {};
  static final Map<String, Future<_HeadlessEntry>> _loading = {};

  /// Opens the model of [fileUuid], loading it on first use. Returns null
  /// when the file doesn't exist. Callers must [HeadlessLease.release].
  static Future<HeadlessLease?> open(
    Session session,
    RevBinding binding,
    UuidValue fileUuid,
  ) async {
    final key = fileUuid.uuid;
    var entry = _entries[key];
    if (entry == null || entry.state.purged) {
      final loading = _loading[key];
      if (loading != null) {
        entry = await loading;
      } else {
        final future = _load(session, binding, fileUuid);
        _loading[key] = future;
        try {
          entry = await future;
        } on _Missing {
          return null;
        } finally {
          _loading.removeWhere((k, _) => k == key);
        }
      }
    }
    entry.leases++;
    entry.lastUsed = clock.now();
    entry._session ??= session;
    _evictOverBudget();
    return HeadlessLease._(entry);
  }

  static Future<_HeadlessEntry> _load(
    Session session,
    RevBinding binding,
    UuidValue fileUuid,
  ) async {
    final state = await RevFileStates.of(session, binding, fileUuid);
    if (state == null) throw const _Missing();
    final entry = _HeadlessEntry(binding, state, RevFileStates.retain(state));
    entry.unlisten = state.listen(entry.onOp);
    entry._session = await session.serverpod.createSession(
      enableLogging: false,
    );
    try {
      final sql = RevSql(
        binding.schema,
        perSheetTables: binding.perSheetTables,
      );
      final (rev, rows) = await session.db.transaction(
        (tx) async {
          final head = await session.db.unsafeQuery(
            'SELECT "headRevision" FROM rev_file WHERE id = @f',
            parameters: QueryParameters.named({'f': state.fileId}),
            transaction: tx,
          );
          final list = await sql
              .allRows(
                session,
                state.fileId,
                scopes: () => binding.perSheetScopes(
                  session,
                  state.fileId,
                  transaction: tx,
                ),
                transaction: tx,
              )
              .toList();
          return (head.first[0]! as int, list);
        },
        settings: TransactionSettings(
          isolationLevel: IsolationLevel.repeatableRead,
        ),
      );
      entry.model = binding.buildModel(fileUuid, rows);
      entry.revision = rev;
      entry.bytes = binding.estimateBytes(entry.model!);
      entry._loaded = true;
      for (final op in entry._buffer) {
        entry._apply(op);
      }
      entry._buffer.clear();
      coldLoads++;
      // Evicted (if over budget) by open() once leased, never before.
      _entries[fileUuid.uuid] = entry;
      return entry;
    } on Object {
      entry.dispose();
      rethrow;
    }
  }

  /// Model copies held outside the cache (AI Suggest-mode shadows), by
  /// owner: counted in [budgetBytes] so they evict idle models instead of
  /// adding to the budget (CQ-35).
  static final Map<Object, int> _external = {};

  /// Counts [bytes] held by [owner] in the budget (replaces an earlier
  /// reservation of [owner]).
  static void reserveExternal(Object owner, int bytes) {
    _external[owner] = bytes;
    _evictOverBudget();
  }

  /// Ends [owner]'s reservation.
  static void releaseExternal(Object owner) => _external.remove(owner);

  /// Bytes reserved outside the cache (tests, diagnostics).
  static int get externalBytes => _external.values.fold(0, (s, b) => s + b);

  static void _evictOverBudget() {
    var total = _entries.values.fold(0, (s, e) => s + e.bytes) + externalBytes;
    if (total <= budgetBytes && _entries.length <= maxEntries) return;
    final idle = _entries.entries.where((e) => e.value.leases <= 0).toList()
      ..sort((a, b) => a.value.lastUsed.compareTo(b.value.lastUsed));
    for (final e in idle) {
      if (total <= budgetBytes && _entries.length <= maxEntries) break;
      _entries.remove(e.key);
      total -= e.value.bytes;
      e.value.dispose();
    }
  }

  /// Drops the model of [fileUuid] (purge, tests).
  static void evict(UuidValue fileUuid) {
    final e = _entries.remove(fileUuid.uuid);
    if (e != null && e.leases <= 0) e.dispose();
  }

  /// Drops everything (tests).
  static void clear() {
    for (final e in _entries.values) {
      e.dispose();
    }
    _entries.clear();
  }

  /// Whether a model of [fileUuid] is cached (tests).
  static bool isCached(UuidValue fileUuid) =>
      _entries.containsKey(fileUuid.uuid);

  /// The cached model of [fileUuid] without loading (tests, diagnostics).
  static Object? peek(UuidValue fileUuid) => _entries[fileUuid.uuid]?.model;

  /// The files with a cached model.
  static Iterable<UuidValue> get cachedFiles =>
      _entries.values.map((e) => e.state.fileUuid);
}

final class _Missing implements Exception {
  const _Missing();
}

/// [RevModelAccess] over the headless cache: the model at the head before
/// the op being committed (the caller holds the file lock).
final class HeadlessModelAccess implements RevModelAccess {
  /// Creates the access.
  HeadlessModelAccess(this.session, this.binding, this.fileUuid);

  /// Session.
  final Session session;

  /// Binding.
  final RevBinding binding;

  /// File.
  final UuidValue fileUuid;

  HeadlessLease? _lease;

  @override
  Future<Object> atPrevious() async {
    final lease = _lease ??= await HeadlessFileCache.open(
      session,
      binding,
      fileUuid,
    );
    if (lease == null) throw StateError('file $fileUuid vanished');
    return lease.model;
  }

  /// Releases the lease taken by [atPrevious].
  void release() => _lease?.release();
}
