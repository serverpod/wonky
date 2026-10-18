import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_core/wonky_core.dart';

import '../core/local_store.dart';

/// Identifies an undo stack: one per open document plus [shell].
extension type const UndoStackKey(String value) {
  /// The shell stack (drive operations).
  static const shell = UndoStackKey('shell');
}

/// Result of an undo/redo.
class UndoOutcome {
  const UndoOutcome({
    required this.step,
    required this.stack,
    required this.isRedo,
    required this.partial,
  });

  final UndoStep step;
  final UndoStackKey stack;
  final bool isRedo;

  /// Some entries were skipped because someone else edited the same data.
  final bool partial;
}

/// A history entry for the undo-history popover.
class UndoHistoryEntry {
  const UndoHistoryEntry(this.step, this.stack);

  final UndoStep step;
  final UndoStackKey stack;
}

/// Collects the entries of one user gesture (suite 08 §3.1 principle 3).
class UndoTransaction {
  UndoTransaction._(
    this._service,
    this.stack,
    this.label,
    this.source,
    this.selectionBefore,
    this.coalesceKey,
  );

  final UndoService _service;
  final UndoStackKey stack;
  final String label;
  final InvocationSource source;
  final SelectionSnapshot? selectionBefore;
  final String? coalesceKey;
  final List<UndoEntry> _entries = [];
  bool _closed = false;
  int _seq = 0;

  /// Whether the transaction was committed or rolled back.
  bool get isClosed => _closed;

  List<UndoEntry> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  /// Adds an entry (in the order the changes were applied).
  void record(UndoEntry entry) {
    if (_closed) throw StateError('Transaction already closed');
    _entries.add(entry);
  }

  /// Commits the step (no-op when nothing was recorded).
  void commit({SelectionSnapshot? selectionAfter}) {
    if (_closed) return;
    _closed = true;
    _service._closeTransaction(this);
    if (_entries.isEmpty) return;
    _service.push(
      UndoStep(
        id: _service._ids.nextString(),
        label: label,
        entries: _entries,
        selectionBefore: selectionBefore,
        selectionAfter: selectionAfter,
        source: source,
        coalesceKey: coalesceKey,
      ),
      stack: stack,
    );
  }

  /// Reverts what was recorded (best effort) and discards the step.
  Future<void> rollback() async {
    if (_closed) return;
    _closed = true;
    _service._closeTransaction(this);
    for (final e in _entries.reversed) {
      try {
        await _service._handlerFor(e).undo(e);
      } catch (err) {
        debugPrint('Undo rollback failed for ${e.domain}: $err');
      }
    }
  }
}

class _Stack {
  final List<UndoStep> undo = [];
  final List<UndoStep> redo = [];
  void Function(SelectionSnapshot)? restoreSelection;
  bool persist = false;
}

/// Local, per-user, per-document undo (suite 08 §3).
///
/// Owns one stack per open document plus the [UndoStackKey.shell] stack.
/// Edit › Undo undoes the most recent step of the active document stack and
/// the shell stack together, so renaming a document from its title field is
/// undone with ⌘Z like any edit. Undo is a forward operation: handlers write
/// the inverse as a new change.
class UndoService extends ChangeNotifier {
  UndoService({
    this.maxSteps = 500,
    this.coalesceWindow = const Duration(milliseconds: 1000),
    LocalStore? persistence,
    UuidV7Generator? ids,
  }) : _store = persistence,
       _ids = ids ?? UuidV7Generator.instance;

  final int maxSteps;
  final Duration coalesceWindow;
  final LocalStore? _store;
  final UuidV7Generator _ids;

  final Map<String, UndoHandler<UndoEntry>> _handlers = {};
  final Map<UndoStackKey, _Stack> _stacks = {UndoStackKey.shell: _Stack()};
  final _outcomes = StreamController<UndoOutcome>.broadcast();
  final Map<UndoStackKey, Timer> _saveTimers = {};
  UndoStackKey? _activeDocument;

  /// Transactions from [beginTransaction] without `scoped`: current for
  /// every caller until they close (hold them only synchronously).
  final List<UndoTransaction> _open = [];
  int _seqs = 0;

  /// The scoped transaction whose zone is executing right now. Code that
  /// zone calls synchronously sees it too, also when it is bound to another
  /// zone (sync stream listeners), see [runInTransaction].
  UndoTransaction? _running;

  /// Zone value key of [runInTransaction].
  final Object _zoneKey = Object();

  /// Nesting depth of handlers applying an undo/redo.
  int _applying = 0;

  /// Tail of the undo/redo queue (they run one at a time, in order); null
  /// while none is running.
  Future<void>? _queue;

  /// Labels and availability for the active context (Edit menu, toolbar).
  final ValueNotifier<bool> canUndo = ValueNotifier(false);
  final ValueNotifier<bool> canRedo = ValueNotifier(false);
  final ValueNotifier<String?> undoLabel = ValueNotifier(null);
  final ValueNotifier<String?> redoLabel = ValueNotifier(null);

  /// Emitted after every undo/redo (partial outcomes → toast).
  Stream<UndoOutcome> get outcomes => _outcomes.stream;

  /// True while an undo/redo applies changes. Apps must not record those
  /// changes as new steps.
  bool get isApplying => _applying > 0;

  /// The open transaction of the running code, if any (nested commands and
  /// app-level recording join it).
  ///
  /// A scoped transaction ([runInTransaction], used by the command
  /// dispatcher) is current only inside its own async call chain: a command
  /// or keystroke that runs while another command awaits does not see it,
  /// so it records its own step and the other command's rollback cannot
  /// revert it. An unscoped [beginTransaction] is current everywhere until
  /// it closes; the newer of the two wins.
  UndoTransaction? get currentTransaction {
    final zoned = Zone.current[_zoneKey];
    var scoped = zoned is UndoTransaction ? zoned : _running;
    if (scoped != null && scoped._closed) scoped = null;
    final global = _open.isEmpty ? null : _open.last;
    if (global == null) return scoped;
    if (scoped == null) return global;
    return global._seq > scoped._seq ? global : scoped;
  }

  UndoStackKey? get activeDocumentStack => _activeDocument;

  // ---- Registration ----

  /// Registers the handler of a domain (`write.content`, `drive` …).
  void registerHandler(UndoHandler<UndoEntry> handler) =>
      _handlers[handler.domain] = handler;

  void unregisterHandler(String domain) => _handlers.remove(domain);

  UndoHandler<UndoEntry> _handlerFor(UndoEntry e) =>
      _handlers[e.domain] ??
      (throw StateError('No undo handler for domain "${e.domain}"'));

  /// Opens (or re-attaches) the stack [key]. With [persist], steps are
  /// stored locally and restored here (best effort; entries need decoders).
  Future<void> openStack(
    UndoStackKey key, {
    void Function(SelectionSnapshot)? restoreSelection,
    bool persist = true,
  }) async {
    final s = _stacks.putIfAbsent(key, _Stack.new);
    s.restoreSelection = restoreSelection;
    s.persist = persist && _store != null;
    if (s.persist && s.undo.isEmpty && s.redo.isEmpty) await _load(key, s);
    _refresh();
  }

  /// Restores steps persisted by the app itself (Write keeps its undo stack
  /// with the offline document cache, suite 12 §1.1 `LocalUndoStack`).
  /// Ignored when the stack already has steps.
  void restoreSteps(
    UndoStackKey key, {
    required List<UndoStep> undo,
    required List<UndoStep> redo,
  }) {
    final s = _stacks.putIfAbsent(key, _Stack.new);
    if (s.undo.isNotEmpty || s.redo.isNotEmpty) return;
    s.undo.addAll(
      undo.length > maxSteps ? undo.sublist(undo.length - maxSteps) : undo,
    );
    s.redo.addAll(redo);
    _changed(key);
  }

  /// Makes [key] the active document stack (null = no editor open).
  void setActiveDocument(UndoStackKey? key) {
    _activeDocument = key;
    if (key != null) _stacks.putIfAbsent(key, _Stack.new);
    _refresh();
  }

  /// Drops the in-memory stack [key] (persisted copy is kept unless
  /// [forget]).
  Future<void> closeStack(UndoStackKey key, {bool forget = false}) async {
    if (key == UndoStackKey.shell) return;
    final s = _stacks[key];
    if (s != null && s.persist && !forget) await _save(key, s);
    _stacks.remove(key);
    if (forget) await _store?.remove('undo.${key.value}');
    if (_activeDocument == key) _activeDocument = null;
    _refresh();
  }

  /// Clears every stack (sign-out).
  void clearAll() {
    for (final s in _stacks.values) {
      s.undo.clear();
      s.redo.clear();
    }
    _refresh();
  }

  // ---- Recording ----

  /// Opens a transaction. Nested commands share the outermost transaction.
  ///
  /// Unless [scoped], it is [currentTransaction] for every caller until it
  /// closes, so close it before the next await. A [scoped] transaction is
  /// current only inside [runInTransaction].
  UndoTransaction beginTransaction(
    String label, {
    UndoStackKey? stack,
    InvocationSource source = InvocationSource.ui,
    SelectionSnapshot? selectionBefore,
    String? coalesceKey,
    bool scoped = false,
  }) {
    final t = UndoTransaction._(
      this,
      stack ?? _activeDocument ?? UndoStackKey.shell,
      label,
      source,
      selectionBefore,
      coalesceKey,
    ).._seq = ++_seqs;
    if (!scoped) _open.add(t);
    return t;
  }

  /// Runs [body] with [t] as the [currentTransaction] of its async call
  /// chain (a forked zone): every callback of that zone, and whatever it
  /// calls synchronously, sees [t]; code that runs while [body] awaits
  /// (input, other commands) does not.
  Future<R> runInTransaction<R>(
    UndoTransaction t,
    FutureOr<R> Function() body,
  ) {
    T enter<T>(Zone zone, T Function() f) {
      final prev = _running;
      final v = zone[_zoneKey];
      _running = v is UndoTransaction ? v : null;
      try {
        return f();
      } finally {
        _running = prev;
      }
    }

    final zone = Zone.current.fork(
      zoneValues: {_zoneKey: t},
      specification: ZoneSpecification(
        run: <T>(self, parent, zone, f) =>
            enter(zone, () => parent.run(zone, f)),
        runUnary: <T, A>(self, parent, zone, f, A a) =>
            enter(zone, () => parent.runUnary(zone, f, a)),
        runBinary: <T, A, B>(self, parent, zone, f, A a, B b) =>
            enter(zone, () => parent.runBinary(zone, f, a, b)),
      ),
    );
    return zone.run(() async => body());
  }

  void _closeTransaction(UndoTransaction t) => _open.remove(t);

  /// Pushes a finished step. Clears redo. Coalesces with the top step when
  /// both share a [UndoStep.coalesceKey] within [coalesceWindow].
  void push(UndoStep step, {UndoStackKey? stack}) {
    final key = stack ?? _activeDocument ?? UndoStackKey.shell;
    final s = _stacks.putIfAbsent(key, _Stack.new);
    s.redo.clear();
    final top = s.undo.isEmpty ? null : s.undo.last;
    final now = clock.now();
    if (top != null &&
        step.coalesceKey != null &&
        top.coalesceKey == step.coalesceKey &&
        top.source == step.source &&
        now.difference(top.updatedAt) <= coalesceWindow) {
      s.undo[s.undo.length - 1] = _merge(top, step, now);
    } else {
      s.undo.add(step);
      if (s.undo.length > maxSteps) {
        s.undo.removeRange(0, s.undo.length - maxSteps);
      }
    }
    _changed(key);
  }

  UndoStep _merge(UndoStep top, UndoStep next, DateTime now) {
    final entries = [...top.entries];
    for (final e in next.entries) {
      final last = entries.isEmpty ? null : entries.last;
      final merged = last != null && last.domain == e.domain
          ? last.coalesce(e)
          : null;
      if (merged != null) {
        entries[entries.length - 1] = merged;
      } else {
        entries.add(e);
      }
    }
    return top.copyWith(
      entries: entries,
      selectionAfter: next.selectionAfter,
      updatedAt: now,
    );
  }

  /// Replaces the top step of [stack] (follow-up refinement of the last
  /// action, e.g. re-running "Split text to columns" with another separator).
  void replaceLast(UndoStep step, {UndoStackKey? stack}) {
    final key = stack ?? _activeDocument ?? UndoStackKey.shell;
    final s = _stacks[key];
    if (s == null || s.undo.isEmpty) {
      push(step, stack: key);
      return;
    }
    s.undo[s.undo.length - 1] = step;
    s.redo.clear();
    _changed(key);
  }

  /// Drops step [stepId] when it is the top undo step of [stack] (an
  /// action that turned out to be a no-op and was reverted by its owner,
  /// e.g. an empty text box that loses editing, Slides 03 §6.1). The redo
  /// stack is untouched. Returns whether the step was removed.
  bool discardTop(String stepId, {UndoStackKey? stack}) {
    final key = stack ?? _activeDocument ?? UndoStackKey.shell;
    final s = _stacks[key];
    if (s == null || s.undo.isEmpty || s.undo.last.id != stepId) return false;
    s.undo.removeLast();
    _changed(key);
    return true;
  }

  /// Rebases every step of [stack] over a remote change; steps that become
  /// no-ops disappear.
  void applyRemote(UndoStackKey stack, RemoteChange change) {
    final s = _stacks[stack];
    if (s == null) return;
    var changed = false;
    for (final list in [s.undo, s.redo]) {
      for (var i = list.length - 1; i >= 0; i--) {
        final r = list[i].rebase(change);
        if (identical(r, list[i])) continue;
        changed = true;
        if (r == null) {
          list.removeAt(i);
        } else {
          list[i] = r;
        }
      }
    }
    if (changed) _changed(stack);
  }

  // ---- Undo / redo ----

  Iterable<UndoStackKey> get _activeKeys => [
    ?_activeDocument,
    UndoStackKey.shell,
  ];

  (UndoStackKey, UndoStep)? _top({required bool redo}) {
    (UndoStackKey, UndoStep)? best;
    for (final k in _activeKeys) {
      final s = _stacks[k];
      if (s == null) continue;
      final list = redo ? s.redo : s.undo;
      if (list.isEmpty) continue;
      final step = list.last;
      if (best == null || step.updatedAt.isAfter(best.$2.updatedAt)) {
        best = (k, step);
      }
    }
    return best;
  }

  /// Steps of [stack], oldest first.
  List<UndoStep> undoStepsOf(UndoStackKey stack) =>
      List.unmodifiable(_stacks[stack]?.undo ?? const []);

  List<UndoStep> redoStepsOf(UndoStackKey stack) =>
      List.unmodifiable(_stacks[stack]?.redo ?? const []);

  /// Undoes the most recent step of the active context.
  ///
  /// Undo, redo and [undoTo] are queued: each starts after the previous one
  /// finished (a held ⌘Z) and picks the top step only then.
  Future<UndoOutcome?> undo() => _serial(() async {
    final top = _top(redo: false);
    if (top == null) return null;
    return _apply(top.$1, top.$2, isRedo: false);
  });

  /// Redoes the most recently undone step (queued like [undo]).
  Future<UndoOutcome?> redo() => _serial(() async {
    final top = _top(redo: true);
    if (top == null) return null;
    return _apply(top.$1, top.$2, isRedo: true);
  });

  /// Undoes every step above and including [stepId] (one undo per step, in
  /// order) — the undo-history popover. Queued like [undo].
  Future<void> undoTo(String stepId) => _serial(() async {
    if (!history().any((h) => h.step.id == stepId)) return;
    for (var guard = 0; guard < maxSteps * 2; guard++) {
      final top = _top(redo: false);
      if (top == null) return;
      await _apply(top.$1, top.$2, isRedo: false);
      if (top.$2.id == stepId) return;
    }
  });

  /// Runs [run] after the queued undo/redo operations; at once (synchronously
  /// up to its first await, as a direct call would) when none is running.
  Future<T> _serial<T>(Future<T> Function() run) {
    final prev = _queue;
    final result = prev == null ? run() : prev.then((_) => run());
    late final Future<void> tail;
    tail = result.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
      if (identical(_queue, tail)) _queue = null;
    });
    _queue = tail;
    return result;
  }

  /// The last [limit] undoable steps of the active context, newest first.
  List<UndoHistoryEntry> history({int limit = 50}) {
    final all = <UndoHistoryEntry>[
      for (final k in _activeKeys)
        for (final s in _stacks[k]?.undo ?? const <UndoStep>[])
          UndoHistoryEntry(s, k),
    ]..sort((a, b) => b.step.updatedAt.compareTo(a.step.updatedAt));
    return all.take(limit).toList();
  }

  /// Applies [step], the top of [key]'s undo (or redo) list. The step stays
  /// on its list until its handlers ran. When a handler throws (other than
  /// [UndoConflict]), the entries not applied yet stay on that list, the
  /// inverse of those applied goes to the opposite list (both marked
  /// partial), and the error is rethrown.
  Future<UndoOutcome> _apply(
    UndoStackKey key,
    UndoStep step, {
    required bool isRedo,
  }) async {
    var partial = step.partiallyRebased;
    final inverse = <UndoEntry>[];
    final ordered = isRedo ? step.entries : step.entries.reversed.toList();
    var applied = 0;
    Object? failure;
    StackTrace? failureTrace;
    _applying++;
    try {
      for (final e in ordered) {
        try {
          final h = _handlerFor(e);
          inverse.add(isRedo ? await h.redo(e) : await h.undo(e));
        } on UndoConflict {
          partial = true;
        }
        applied++;
      }
    } catch (e, st) {
      failure = e;
      failureTrace = st;
    } finally {
      _applying--;
    }
    if (failure != null && applied == 0) {
      Error.throwWithStackTrace(failure, failureTrace!);
    }
    // Look the step up again: a remote change may have rebased it, and the
    // stack may have been closed meanwhile.
    final s = _stacks[key];
    if (s != null) {
      final from = isRedo ? s.redo : s.undo;
      final to = isRedo ? s.undo : s.redo;
      final at = from.lastIndexWhere((x) => x.id == step.id);
      if (failure == null) {
        if (at >= 0) from.removeAt(at);
      } else if (at >= 0) {
        final now = from[at];
        final base = now.entries.length == step.entries.length
            ? now.entries
            : step.entries;
        final rest = isRedo
            ? base.sublist(applied)
            : base.sublist(0, base.length - applied);
        from[at] = now.copyWith(entries: rest, partiallyRebased: true);
      }
      final entries = isRedo ? inverse : inverse.reversed.toList();
      if (entries.isNotEmpty) {
        to.add(
          step.copyWith(entries: entries, partiallyRebased: failure != null),
        );
      }
      if (failure == null) {
        final sel = isRedo ? step.selectionAfter : step.selectionBefore;
        if (sel != null) s.restoreSelection?.call(sel);
      }
      _changed(key);
    }
    if (failure != null) Error.throwWithStackTrace(failure, failureTrace!);
    final outcome = UndoOutcome(
      step: step,
      stack: key,
      isRedo: isRedo,
      partial: partial,
    );
    if (!_outcomes.isClosed) _outcomes.add(outcome);
    return outcome;
  }

  // ---- State / persistence ----

  void _changed(UndoStackKey key) {
    _refresh();
    final s = _stacks[key];
    if (s != null && s.persist) {
      _saveTimers[key]?.cancel();
      _saveTimers[key] = Timer(
        const Duration(milliseconds: 600),
        () => _save(key, s),
      );
    }
  }

  void _refresh() {
    final u = _top(redo: false);
    final r = _top(redo: true);
    canUndo.value = u != null;
    canRedo.value = r != null;
    undoLabel.value = u?.$2.label;
    redoLabel.value = r?.$2.label;
    notifyListeners();
  }

  Future<void> _save(UndoStackKey key, _Stack s) async {
    final store = _store;
    if (store == null) return;
    List<Map<String, Object?>> encode(List<UndoStep> steps) => [
      for (final st in steps) ?st.toJson(),
    ];
    try {
      await store.write('undo.${key.value}', {
        'undo': encode(s.undo),
        'redo': encode(s.redo),
      });
    } catch (e) {
      debugPrint('Persisting undo stack failed: $e');
    }
  }

  Future<void> _load(UndoStackKey key, _Stack s) async {
    final store = _store;
    if (store == null) return;
    final decoders = <String, UndoEntryDecoder>{
      for (final h in _handlers.values)
        if (h.decoder != null) h.domain: h.decoder!,
    };
    try {
      final raw = await store.read('undo.${key.value}');
      if (raw is! Map) return;
      List<UndoStep> decode(Object? list) => [
        if (list is List)
          for (final j in list)
            if (j is Map)
              ?UndoStep.fromJson(j.cast<String, Object?>(), decoders),
      ];
      s.undo.addAll(decode(raw['undo']));
      s.redo.addAll(decode(raw['redo']));
    } catch (e) {
      debugPrint('Restoring undo stack failed: $e');
    }
  }

  @override
  void dispose() {
    for (final t in _saveTimers.values) {
      t.cancel();
    }
    _outcomes.close();
    canUndo.dispose();
    canRedo.dispose();
    undoLabel.dispose();
    redoLabel.dispose();
    super.dispose();
  }
}
