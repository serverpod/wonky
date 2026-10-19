import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show ScriptExecution, ScriptExecutionKind, ScriptExecutionStatus, UuidValue;
import 'package:wonky_core/diff.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show CellPos, GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

import '../../l10n/sheets_l10n.dart';
import '../model/memory_workbook_session.dart';
import '../history/server_change_undo.dart' show SheetsServerChangeEntry;
import '../model/sheets_undo.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import '../formatting/sheets_user_defaults.dart';
import '../protection/file_editors.dart';
import '../revlog/logged_workbook_session.dart';
import 'authorization_dialog.dart';
import 'conflict_dialog.dart';
import 'local/script_local_store.dart';
import 'runtime/script_panels.dart';
import 'runtime/script_runners.dart';
import 'runtime/script_ui.dart';
import 'runtime/session_workbook_access.dart';
import 'runtime/user_properties.dart';
import 'script_backend.dart';
import 'script_project.dart';

/// Where the script editor's build stands (09 §14.1 title row).
enum ScriptBuildPhase {
  /// No project or no build yet.
  none,

  /// Saved; waiting for the server build.
  building,

  /// The latest sources built.
  ok,

  /// The latest sources have errors (the last good build keeps running).
  failed,

  /// Saved on this device; compiles when online.
  offline,
}

/// One log line of a run in this window (Log panel, 09 §14.1).
class ScriptLogLine {
  const ScriptLogLine(this.function, this.entry);

  final String function;
  final LogEntry entry;
}

/// The script runtime of one open spreadsheet (09 §8.4, §8.8): installs
/// the last good build (`ScriptBuild.lastGood*`, bytecode from
/// `ScriptEndpoint.bytecode`), runs functions, menus, macros and simple
/// triggers, persists each execution's writes as one undo step
/// "Script: fn", feeds custom functions to the formula engine and uploads
/// executions. One per editor (`SheetEditorController.extension`).
class ScriptService extends ChangeNotifier {
  ScriptService._(this.editor) : access = SessionWorkbookAccess(editor);

  static const _key = #wonkySheetsScriptService;

  /// Label prefix of script undo steps ("Script: fn").
  static const undoPrefix = 'Script: ';

  /// The service of [editor] (created and started on first use).
  static ScriptService of(SheetEditorController editor) =>
      editor.extension<ScriptService>(_key, () {
        final s = ScriptService._(editor);
        editor.onDispose(s.dispose);
        s._start();
        return s;
      });

  /// The service of [editor] if it was started.
  static ScriptService? maybeOf(SheetEditorController? editor) =>
      editor?.extensionOrNull<ScriptService>(_key);

  /// The server API (tests supply a fake; null without a client).
  static ScriptBackend? Function(ShellServices services) backendFactory =
      _defaultBackend;

  static ScriptBackend? _defaultBackend(ShellServices s) {
    final c = s.client;
    return c == null ? null : ServerScriptBackend(c);
  }

  /// Bytecode of recent builds by build hash (memory; the persistent copy
  /// is in [ScriptLocalStore]).
  static final Map<String, Uint8List> _bytecodeCache = {};

  final SheetEditorController editor;
  final SessionWorkbookAccess access;
  late final ScriptBackend? backend = backendFactory(services);

  ShellServices get services => editor.services;
  WorkbookModel get model => editor.model;
  UuidValue get itemUuid => editor.session.itemUuid;
  SheetsLocalizations get l => editor.l10n;

  ScriptSession? _session;
  ScriptProgram? _program;
  PropertyStore? _userProps;
  Set<String> _granted = {};
  bool _disposed = false;
  bool _openFired = false;
  StreamSubscription<CommandInvoked>? _commands;
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _uploadTimer;
  Timer? _selectionTimer;
  final List<ScriptExecution> _pendingReports = [];
  final Set<String> _seenSteps = {};
  final Set<String> _running = {};
  ScriptCompileResult? _lastCompile;
  List<ScriptMenu> _menus = const [];
  ScriptLocalStore? _local;
  Timer? _draftTimer;
  bool _enabled = true;
  final Set<LogEntry> _streamed = Set.identity();
  Timer? _logNotify;
  final Completer<void> _ready = Completer();

  /// Completes when drafts are restored and the build is installed (the
  /// editor opens files after it).
  Future<void> get ready => _ready.future;

  /// Whether [ready] has completed.
  bool get isReady => _ready.isCompleted;

  /// Build phase shown by the editor.
  ScriptBuildPhase phase = ScriptBuildPhase.none;

  /// The file shown in the script editor (`sheets.script.saveFile`
  /// default).
  String? activeFileId;

  /// The function of the editor's *Run* button.
  String? selectedFunction;

  /// The installed program (last good build).
  ScriptProgram? get program => _program;

  /// The script session (null until a build is installed).
  ScriptSession? get session => _session;

  /// Exports of the last good build.
  ScriptExports get exports => _program?.exports ?? ScriptExports.empty;

  /// Custom menus added by the last `onOpen` (09 §16.1).
  List<ScriptMenu> get menus => _menus;

  /// Functions running in this window.
  Set<String> get running => Set.unmodifiable(_running);

  /// Recent executions of this window, newest last (Log, executions).
  final List<ExecutionResult> recent = [];

  /// Log lines of runs started in this window.
  final List<ScriptLogLine> log = [];

  /// The scopes the user granted (09 §11.2).
  Set<String> get grantedScopes => Set.unmodifiable(_granted);

  /// Scopes of the build the user has not granted.
  Set<String> get missingScopes => _session?.missingScopes() ?? const {};

  /// The script project row, if any.
  GenericRecord? get project => scriptProjectOf(model);

  /// The project's files in order.
  List<GenericRecord> get files => ScriptProjectRows.files(model);

  /// The build row.
  GenericRecord? get buildRow => ScriptProjectRows.build(model);

  /// Macros of the project.
  List<GenericRecord> get macros => ScriptProjectRows.macros(model);

  /// Diagnostics of the latest build of the saved sources.
  List<ScriptDiagnostic> get buildDiagnostics {
    final c = _lastCompile;
    if (c != null) return c.diagnostics;
    final json = buildRow?.columns['diagnosticsJson'] as String?;
    if (json == null || json.isEmpty) return const [];
    try {
      return ScriptDiagnostic.decodeList(json);
    } on Object {
      return const [];
    }
  }

  /// When the last good build was made.
  DateTime? get builtAt {
    final v = buildRow?.columns['builtAt'];
    return v is DateTime ? v : (v is String ? DateTime.tryParse(v) : null);
  }

  bool get _online => services.connectivity.online;

  /// Settings › Sheets › *Enable scripts* (09 §11.3): when off, no script
  /// code runs in this client and custom functions show an error.
  bool get scriptsEnabled => _enabled;

  /// The device-local store (null until opened or without SQLite).
  ScriptLocalStore? get localStore => _local;

  String get _spreadsheetKey => itemUuid.uuid;

  // ---------------------------------------------------------------- start

  void _start() {
    _enabled = SheetsUserDefaults.of(services).scriptsEnabled;
    // Buttons of script sidebars and dialogs (09 §16.3) run like menu
    // items: one undo step, with a UiEvent.
    ScriptPanels.of(editor).onButton = (fn, e) async {
      await run(fn, kind: ExecutionKind.menu, event: e);
    };
    services.prefs.addListener(_onPrefs);
    model.addListener(_onBatch);
    _commands = services.dispatcher.events.listen(_onCommand);
    editor.selection.addListener(_onSelection);
    _seenSteps.addAll([
      for (final s in services.undo.undoStepsOf(_stack)) s.id,
    ]);
    unawaited(_init());
  }

  UndoStackKey get _stack => UndoStackKey(itemUuid.uuid);

  Future<void> _init() async {
    try {
      _userProps = await RemoteUserProperties.forSession(
        services,
        editor.session,
      );
    } on Object catch (e) {
      debugPrint('Loading script user properties failed: $e');
    }
    if (_disposed) return;
    _local = await ScriptLocalStore.of(services);
    if (_disposed) return;
    await _restoreDrafts();
    await _loadGrant();
    await reloadBuild();
    if (!_ready.isCompleted) _ready.complete();
    if (_disposed) return;
    unawaited(uploadExecutions());
    if (project == null) return;
    final b = backend;
    if (b != null && _online) {
      try {
        await b.notifyOpen(itemUuid);
      } on Object {
        // Installable onOpen triggers are best effort.
      }
    }
  }

  /// Reloads the user's granted scopes from the server.
  Future<void> refreshGrant() => _loadGrant();

  Future<void> _loadGrant() async {
    final b = backend;
    if (b == null || !_online || project == null) return;
    try {
      _granted = await b.authorization(itemUuid);
      _session?.grantedScopes = _granted;
    } on Object {
      // Offline or scripts disabled: simple triggers run limited.
    }
  }

  // ---------------------------------------------------------------- build

  /// Installs the last good build of the build row when it changed
  /// (downloads its bytecode).
  Future<void> reloadBuild() async {
    final row = buildRow;
    final hash = row?.columns['lastGoodSourceHash'] as String?;
    final exportsJson = row?.columns['lastGoodExportsJson'] as String?;
    if (row != null) {
      final failed = row.columns['status'] == 'errors';
      phase = failed ? ScriptBuildPhase.failed : ScriptBuildPhase.ok;
    }
    if (hash == null || exportsJson == null) {
      if (row == null && project == null && _program != null) _uninstall();
      notifyListeners();
      return;
    }
    if (_program?.buildHash == hash) {
      notifyListeners();
      return;
    }
    var bytes = _bytecodeCache[hash];
    final local = _local;
    if (bytes == null && local != null) {
      try {
        bytes = await local.bytecode(hash);
      } on Object catch (e) {
        debugPrint('Reading the cached script build failed: $e');
      }
    }
    final b = backend;
    if (bytes == null && b != null && _online) {
      try {
        bytes = await b.bytecode(itemUuid);
        if (bytes != null) _cacheBytecode(hash, bytes);
      } on Object catch (e) {
        debugPrint('Downloading the script build failed: $e');
      }
    }
    if (_disposed) return;
    if (bytes == null) {
      notifyListeners();
      return;
    }
    _bytecodeCache[hash] = bytes;
    installProgram(
      ScriptProgram(
        buildHash: hash,
        bytecode: bytes,
        exports: ScriptExports.decode(exportsJson),
      ),
    );
  }

  void _cacheBytecode(String hash, Uint8List bytes) {
    final local = _local;
    if (local == null) return;
    unawaited(
      local.putBytecode(hash, bytes).catchError((Object e) {
        debugPrint('Caching the script build failed: $e');
      }),
    );
  }

  /// Installs [program] (last good build): custom functions, menus
  /// (`onOpen`), macros.
  void installProgram(ScriptProgram program) {
    if (_disposed) return;
    final s = _ensureSession();
    s.customFunctions.disabledReason = _enabled ? null : l.scriptsDisabled;
    final before = {...?_program?.exports.customFunctions.keys};
    if (!s.setProgram(program)) {
      services.toasts.show(l.scriptNeedsNewerApp);
      return;
    }
    _program = program;
    final wb = editor.session;
    if (wb is WorkbookSessionBase) {
      wb.customFunctions
        ..target = s.customFunctions
        ..names = List.of(s.customFunctions.names);
    }
    // Formulas that called a then-unknown name hold #NAME? without a
    // custom dependency: new names re-evaluate every formula once.
    if (!program.exports.customFunctions.keys.every(before.contains)) {
      unawaited(editor.engine.recalcAll());
    }
    notifyListeners();
    services.registry.notifyStateChanged();
    unawaited(fireOpen());
  }

  /// Forgets the installed build and the in-memory bytecode (tests of the
  /// persistent cache).
  @visibleForTesting
  void forgetBuild() {
    _bytecodeCache.clear();
    _uninstall();
  }

  /// The project was deleted: no custom functions, menus or macros.
  void _uninstall() {
    _program = null;
    _session?.setProgram(null);
    final wb = editor.session;
    if (wb is WorkbookSessionBase) wb.customFunctions.target = null;
    _session?.menus.clear();
    _menusChanged();
    phase = ScriptBuildPhase.none;
  }

  ScriptSession _ensureSession() {
    final existing = _session;
    if (existing != null) return existing;
    final me = services.me;
    final s = ScriptSession(
      workbook: access,
      uiRunner: createScriptRunner(),
      pureRunner: createScriptRunner(),
      user: ScriptUser(
        id: editor.session.userId,
        email: me?.email ?? '',
        name: me?.displayName ?? '',
      ),
      role: _role(),
      onLiveLog: _onLiveLog,
      ui: AppScriptUi(editor, onMenu: (_) => _menusChanged()),
      fetcher: _AppFetcher(this),
      userProperties: _userProps ?? MemoryPropertyStore(),
      grantedScopes: _granted,
      spreadsheetUrl: services.urls.urlFor(
        WonkyAppKind.sheets,
        '/s/${itemUuid.uuid}',
      ),
    );
    _subs
      ..add(s.executions.listen(_onExecution))
      ..add(s.customFunctionBatches.listen(_onCustomBatch))
      ..add(s.customFunctions.updates.listen((_) => _settleSoon()));
    s.customFunctions.disabledReason = _enabled ? null : l.scriptsDisabled;
    return _session = s;
  }

  /// Live log lines while a function runs (09 §14.1 Log panel).
  void _onLiveLog(String function, LogEntry e) {
    if (_disposed) return;
    _streamed.add(e);
    log.add(ScriptLogLine(function, e));
    if (log.length > 2000) log.removeRange(0, log.length - 2000);
    // Coalesce repaints of chatty scripts.
    _logNotify ??= Timer(const Duration(milliseconds: 50), () {
      _logNotify = null;
      if (!_disposed) notifyListeners();
    });
  }

  void _onPrefs() {
    final enabled = SheetsUserDefaults.of(services).scriptsEnabled;
    if (enabled == _enabled || _disposed) return;
    _enabled = enabled;
    final s = _session;
    if (s != null) {
      s.customFunctions.disabledReason = enabled ? null : l.scriptsDisabled;
      s.customFunctions.invalidateAll();
    }
    if (enabled) {
      if (_program != null) unawaited(fireOpen());
    } else {
      _session?.menus.clear();
      _menusChanged();
    }
    notifyListeners();
  }

  bool _settling = false;

  /// Custom function results arrived: the engine dirtied the calling cells
  /// (and their dependents); evaluate them so the grid repaints (the
  /// engine's change batch invalidates the render cache).
  void _settleSoon() {
    if (_settling) return;
    _settling = true;
    Timer.run(() {
      _settling = false;
      if (_disposed) return;
      final r = editor.engine.drain(const Duration(milliseconds: 16));
      if (r.remaining > 0) _settleSoon();
    });
  }

  void _menusChanged() {
    _menus = List.unmodifiable(_session?.menus ?? const <ScriptMenu>[]);
    notifyListeners();
    services.registry.notifyStateChanged();
  }

  Role _role() {
    if (!editor.canEdit) return Role.viewer;
    return editor.itemRole >= Role.owner ? Role.owner : Role.editor;
  }

  ScriptSelection _selection() {
    final r = editor.selection.resolved;
    final active = r.activeRange.rect;
    return ScriptSelection(
      sheetId: r.sheetId,
      ranges: [
        active,
        for (final x in r.ranges)
          if (!identical(x, r.activeRange)) x.rect,
      ],
      currentCell: CellPos(r.activeRow, r.activeCol),
    );
  }

  // ---------------------------------------------------------------- runs

  /// Runs `onOpen` (menus) once per window and after each new build.
  Future<void> fireOpen() async {
    _openFired = true;
    await _fireTrigger(ExecutionKind.onOpen, const OpenEventData());
    _menusChanged();
  }

  /// Runs [functionName] (editor, menu, macro). Asks for authorization when
  /// the build needs scopes the user has not granted. Returns null when it
  /// did not run.
  Future<ExecutionResult?> run(
    String functionName, {
    ExecutionKind kind = ExecutionKind.editor,
    BuildContext? context,
    ScriptEvent? event,
  }) async {
    final s = _session;
    if (!_enabled) {
      services.toasts.show(l.scriptsDisabled);
      return null;
    }
    if (s == null || _program == null) {
      services.toasts.show(l.scriptNoBuild);
      return null;
    }
    if (exports.function(functionName) == null) {
      services.toasts.error(l.scriptUnknownFunction(functionName));
      return null;
    }
    final missing = s.missingScopes();
    if (missing.isNotEmpty && !await authorize(missing, context: context)) {
      return null;
    }
    _prepare(s);
    _running.add(functionName);
    notifyListeners();
    // Running `onOpen(OpenEvent e)` by hand (editor, palette) gets the same
    // event as opening the spreadsheet instead of failing its cast on null.
    final ev =
        event ?? (functionName == 'onOpen' ? const OpenEventData() : null);
    final ExecutionResult r;
    try {
      r = await s.run(functionName, kind: kind, event: ev);
    } finally {
      _running.remove(functionName);
      notifyListeners();
    }
    _commit(r);
    _reportFailure(r);
    return r;
  }

  void _prepare(ScriptSession s) {
    s
      ..role = _role()
      ..selection = _selection()
      ..grantedScopes = _granted;
  }

  Future<ExecutionResult?> _fireTrigger(
    ExecutionKind kind,
    ScriptEvent event, {
    UndoStep? appendTo,
  }) async {
    final s = _session;
    if (s == null || _program == null || !_enabled) return null;
    _prepare(s);
    final started = clock.now();
    final r = await s.fireSimpleTrigger(kind, event);
    if (r == null) return null;
    final merge =
        appendTo != null &&
        clock.now().difference(started) <= const Duration(seconds: 2) &&
        services.undo.undoStepsOf(_stack).lastOrNull?.id == appendTo.id;
    _commit(r, appendTo: merge ? appendTo : null);
    if (!r.ok && r.status != ExecutionStatus.skipped) _reportFailure(r);
    return r;
  }

  /// Persists the writes of [r] as one undo step "Script: fn" (or appends
  /// them to [appendTo], 09 §8.7.2).
  void _commit(ExecutionResult r, {UndoStep? appendTo}) {
    final changes = <RowChange>[
      for (final a in r.applied)
        if (a.undoable) ...a.plan.changes,
    ];
    access.applied.clear();
    if (changes.isEmpty) return;
    final label = '$undoPrefix${r.functionName}';
    final entry = SheetsRowsUndoEntry(changes, label: label);
    if (appendTo != null) {
      services.undo.replaceLast(
        appendTo.copyWith(entries: [...appendTo.entries, entry]),
        stack: _stack,
      );
      return;
    }
    final step = UndoStep(
      id: services.ids.next().uuid,
      label: label,
      entries: [entry],
      source: InvocationSource.ui,
    );
    _seenSteps.add(step.id);
    services.undo.push(step, stack: _stack);
  }

  void _reportFailure(ExecutionResult r) {
    if (r.ok) return;
    final e = r.error;
    if (r.status == ExecutionStatus.skipped && e != null) {
      services.toasts.show(e.message);
      return;
    }
    services.toasts.show(
      l.scriptErrorToast(r.functionName),
      description: e?.message ?? r.status.name,
      destructive: true,
      actionLabel: l.scriptViewDetails,
      onAction: () =>
          unawaited(services.dispatcher.invoke('sheets.script.openExecutions')),
    );
  }

  /// *Run on server* (09 §14.5).
  Future<ServerRunResult?> runOnServer(String functionName) async {
    if (!_enabled) {
      services.toasts.show(l.scriptsDisabled);
      return null;
    }
    final b = backend;
    if (b == null || !_online) {
      services.toasts.show(l.scriptOffline);
      return null;
    }
    _running.add(functionName);
    notifyListeners();
    try {
      var streamed = 0;
      final r = await b.runOnServer(
        itemUuid,
        functionName,
        onLog: (e) {
          streamed++;
          _onLiveLog(functionName, e);
        },
      );
      for (final e in r.logs.skip(streamed)) {
        log.add(ScriptLogLine(functionName, e));
      }
      final change = r.changeId;
      if (change != null) {
        _pushServerChange(change, '$undoPrefix$functionName');
      }
      if (r.status != ExecutionStatus.completed) {
        services.toasts.show(
          l.scriptErrorToast(functionName),
          description: r.error?.message ?? r.status.name,
          destructive: true,
        );
      }
      return r;
    } on Object catch (e) {
      services.toasts.error(
        l.scriptErrorToast(functionName),
        description: '$e',
      );
      return null;
    } finally {
      _running.remove(functionName);
      notifyListeners();
    }
  }

  void _pushServerChange(String changeId, String label) {
    final step = UndoStep(
      id: services.ids.next().uuid,
      label: label,
      entries: [SheetsServerChangeEntry(changeId: changeId, label: label)],
    );
    _seenSteps.add(step.id);
    services.undo.push(step, stack: _stack);
  }

  /// *Revert changes* of a server execution (09 §13.3); one undo step
  /// re-applies them.
  Future<bool> revertServerChange(String changeId, String functionName) async {
    final b = backend;
    if (b == null || !_online) {
      services.toasts.show(l.scriptOffline);
      return false;
    }
    final revert = await b.revertChange(changeId);
    _pushServerChange(revert, l.scriptRevertLabel(functionName));
    return true;
  }

  /// Stops the running executions: the guests are killed and a fresh
  /// session takes over (09 §14.5 *Stop*).
  Future<void> stop() async {
    final old = _session;
    final program = _program;
    if (old == null) return;
    _session = null;
    _program = null;
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    final wb = editor.session;
    if (wb is WorkbookSessionBase) wb.customFunctions.target = null;
    await old.close();
    _running.clear();
    if (program != null && !_disposed) {
      final s = _ensureSession();
      if (s.setProgram(program)) {
        _program = program;
        if (wb is WorkbookSessionBase) {
          wb.customFunctions
            ..target = s.customFunctions
            ..names = List.of(s.customFunctions.names);
        }
      }
    }
    notifyListeners();
  }

  // -------------------------------------------------------------- drafts

  /// Unsaved editor content per file id (09 §14.3).
  final Map<String, String> drafts = {};

  /// Content hash per file id at load or last save (conflict check).
  final Map<String, String> baseHashes = {};

  /// Source per file id at load or last save (the base of *Merge*).
  final Map<String, String> baseSources = {};

  /// Whether the file [id] has unsaved changes.
  bool isDirty(String id) => drafts.containsKey(id);

  /// Files whose save is being written: the model notifies while the row
  /// changes but [baseHashes] still holds the old hash, which must not read
  /// as "saved elsewhere" (09 §14.3).
  final Set<String> saving = {};

  /// Records the editor content of [id] (removes the draft when it equals
  /// the saved source). Drafts are persisted 2 s later (09 §14.3).
  void setDraft(String id, String text) {
    final row = ScriptProjectRows.file(model, id);
    final saved = row == null ? null : ScriptProjectRows.sourceOf(row);
    final was = drafts.containsKey(id);
    if (saved == text) {
      drafts.remove(id);
    } else {
      drafts[id] = text;
    }
    _scheduleDraftSave();
    if (was != drafts.containsKey(id)) notifyListeners();
  }

  /// Drops the draft of [id] (reload, discard).
  void clearDraft(String id) {
    if (drafts.remove(id) != null) {
      _scheduleDraftSave();
      notifyListeners();
    }
  }

  /// Notes that the editor shows the saved version of [id].
  void markLoaded(String id) {
    final row = ScriptProjectRows.file(model, id);
    if (row != null) {
      baseHashes[id] = ScriptProjectRows.hashOf(row);
      baseSources[id] = ScriptProjectRows.sourceOf(row);
    }
  }

  void _scheduleDraftSave() {
    if (_local == null || _disposed) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(seconds: 2),
      () => unawaited(_saveDrafts()),
    );
  }

  Future<void> _saveDrafts() async {
    _draftTimer?.cancel();
    _draftTimer = null;
    final local = _local;
    if (local == null) return;
    try {
      await local.saveDrafts(_spreadsheetKey, [
        for (final e in drafts.entries)
          ScriptDraft(
            fileId: e.key,
            text: e.value,
            baseHash: baseHashes[e.key] ?? '',
            baseText: baseSources[e.key] ?? '',
          ),
      ]);
    } on Object catch (e) {
      debugPrint('Saving script drafts failed: $e');
    }
  }

  /// Persists the drafts now (tests; normally 2 s after the last edit).
  @visibleForTesting
  Future<void> flushDrafts() => _saveDrafts();

  /// Restores the unsaved drafts of the last session (reload, crash).
  @visibleForTesting
  Future<void> restoreDrafts() => _restoreDrafts();

  Future<void> _restoreDrafts() async {
    final local = _local;
    if (local == null) return;
    List<ScriptDraft> saved;
    try {
      saved = await local.drafts(_spreadsheetKey);
    } on Object catch (e) {
      debugPrint('Reading script drafts failed: $e');
      return;
    }
    var any = false;
    for (final d in saved) {
      final row = ScriptProjectRows.file(model, d.fileId);
      if (row == null || drafts.containsKey(d.fileId)) continue;
      if (ScriptProjectRows.sourceOf(row) == d.text) continue;
      drafts[d.fileId] = d.text;
      baseHashes[d.fileId] = d.baseHash.isEmpty
          ? ScriptProjectRows.hashOf(row)
          : d.baseHash;
      baseSources[d.fileId] = d.baseText;
      any = true;
    }
    if (any) notifyListeners();
  }

  // -------------------------------------------------------- local history

  /// Saved versions of [fileId] on this device, newest first (09 §14.3
  /// `LocalScriptHistory`).
  Future<List<ScriptHistoryEntry>> historyOf(String fileId) async {
    final local = _local;
    if (local == null) return const [];
    try {
      return await local.history(fileId);
    } on Object {
      return const [];
    }
  }

  void _keepHistory(String fileId, String source, String note) {
    final local = _local;
    if (local == null || source.isEmpty) return;
    unawaited(
      local
          .addHistory(
            ScriptHistoryEntry(
              fileId: fileId,
              savedAt: clock.now(),
              source: source,
              note: note,
            ),
          )
          .catchError((Object e) => debugPrint('Script history: $e')),
    );
  }

  /// Puts [source] into the editor of [fileId] as an unsaved draft
  /// (*Restore* of a local history version, *Merge*).
  void restoreDraft(String fileId, String source) {
    setDraft(fileId, source);
    notifyListeners();
  }

  /// Saves the draft of [id] (or [source]); returns false when nothing was
  /// saved (no change, conflict cancelled). Compiles afterwards.
  Future<bool> save(
    String id, {
    String? source,
    BuildContext? context,
    bool compileAfter = true,
  }) async {
    final row = ScriptProjectRows.file(model, id);
    final text = source ?? drafts[id];
    if (row == null || text == null) return false;
    final current = ScriptProjectRows.hashOf(row);
    final base = baseHashes[id] ?? current;
    final by = '${row.columns['updatedBy'] ?? ''}';
    if (current != base && by != editor.session.userId) {
      final ctx = context ?? services.navigatorContext;
      if (ctx == null || !ctx.mounted) return false;
      final theirs = ScriptProjectRows.sourceOf(row);
      final who = await _nameOf(by);
      if (!ctx.mounted) return false;
      final choice = await showScriptConflictDialog(
        ctx,
        fileName: ScriptProjectRows.nameOf(row),
        updatedBy: who,
        updatedAt: row.columns['updatedAt'],
        mine: text,
        theirs: theirs,
        canMerge: baseSources.containsKey(id),
      );
      switch (choice) {
        case ScriptConflictChoice.cancel:
          return false;
        case ScriptConflictChoice.discardMine:
          _keepHistory(id, text, 'discarded');
          drafts.remove(id);
          baseHashes[id] = current;
          baseSources[id] = theirs;
          _scheduleDraftSave();
          notifyListeners();
          return false;
        case ScriptConflictChoice.merge:
          final merged = LineDiff.merge3(baseSources[id] ?? '', text, theirs);
          _keepHistory(id, text, 'before merge');
          baseHashes[id] = current;
          baseSources[id] = theirs;
          restoreDraft(id, merged.text);
          if (merged.hasConflicts) {
            services.toasts.show(
              l.scriptMergeConflicts(merged.conflictLines.length),
            );
          }
          return false;
        case ScriptConflictChoice.overwrite:
          _keepHistory(id, theirs, 'overwritten');
      }
    }
    saving.add(id);
    final String hash;
    try {
      hash = ScriptProjectWriter(editor).saveSource(id, text);
    } finally {
      saving.remove(id);
    }
    baseHashes[id] = hash;
    baseSources[id] = text;
    drafts.remove(id);
    _keepHistory(id, text, 'saved');
    _scheduleDraftSave();
    notifyListeners();
    if (compileAfter) unawaited(compile());
    return true;
  }

  /// Display name of the user [authUserId] (the file's editors; empty
  /// when unknown).
  Future<String> _nameOf(String authUserId) async {
    if (authUserId.isEmpty) return '';
    try {
      final list = await FileEditors.load(services, itemUuid);
      for (final e in list.editors) {
        if (e.userId == authUserId) return e.label;
      }
    } on Object {
      // Offline: the dialog names nobody.
    }
    return '';
  }

  /// Saves every draft (*Save all*).
  Future<int> saveAll({BuildContext? context}) async {
    var n = 0;
    for (final id in List.of(drafts.keys)) {
      if (await save(id, context: context, compileAfter: false)) n++;
    }
    if (n > 0) unawaited(compile());
    return n;
  }

  // ------------------------------------------------------------ settings

  /// The project settings (`ScriptProject.settingsJson`, 09 §14.7).
  Map<String, Object?> get settings {
    final raw = project?.columns[ScriptCols.settingsJson] as String?;
    if (raw == null || raw.isEmpty) return const {};
    try {
      return (jsonDecode(raw) as Map).cast<String, Object?>();
    } on Object {
      return const {};
    }
  }

  /// "Show script menus in menubar" (default on).
  bool get showMenusInMenubar => settings['showMenusInMenubar'] != false;

  // ------------------------------------------------------- authorization

  /// Shows the authorization dialog for [scopes] and grants them (09
  /// §11.2). Returns whether the scopes are granted.
  Future<bool> authorize(Set<String> scopes, {BuildContext? context}) async {
    final ctx = context ?? services.navigatorContext;
    final b = backend;
    if (ctx == null || !ctx.mounted) return false;
    final name = '${project?.columns[ScriptCols.name] ?? ''}';
    final ok = await showScriptAuthorizationDialog(
      ctx,
      projectName: name,
      scopes: scopes,
    );
    if (!ok) return false;
    if (b == null || !_online) {
      services.toasts.show(l.scriptOffline);
      return false;
    }
    try {
      _granted = await b.authorize(itemUuid, [..._granted, ...scopes]);
    } on Object catch (e) {
      services.toasts.error(l.scriptAuthorizeFailed, description: '$e');
      return false;
    }
    _session
      ?..grantedScopes = _granted
      ..authorized = true;
    notifyListeners();
    return true;
  }

  /// *Revoke my authorization* (09 §11.2).
  Future<bool> revokeAuthorization() async {
    final b = backend;
    if (b == null || !_online) {
      services.toasts.show(l.scriptOffline);
      return false;
    }
    await b.revokeAuthorization(itemUuid);
    _granted = {};
    _session?.grantedScopes = _granted;
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------- build

  /// After a save: syncs, asks the server to build and installs the result
  /// (09 §14.3).
  Future<ScriptCompileResult?> compile() async {
    final b = backend;
    if (b == null || !_online) {
      phase = ScriptBuildPhase.offline;
      notifyListeners();
      return null;
    }
    phase = ScriptBuildPhase.building;
    notifyListeners();
    try {
      await editor.session.flush();
      final session = editor.session;
      if (session is LoggedWorkbookSession) {
        try {
          // Compile what the server has: every change acknowledged (06
          // §7.1).
          await session.whenSynced(timeout: const Duration(seconds: 10));
        } on Object {
          // The server also builds after the change (scripts hook).
        }
      }
      final r = await b.compile(itemUuid);
      if (_disposed) return r;
      _lastCompile = r;
      phase = r.ok ? ScriptBuildPhase.ok : ScriptBuildPhase.failed;
      notifyListeners();
      final json = r.exportsJson;
      if (r.ok && json != null && _program?.buildHash != r.sourceHash) {
        final bytes = await b.bytecode(itemUuid);
        if (bytes != null && !_disposed) {
          _bytecodeCache[r.sourceHash] = bytes;
          _cacheBytecode(r.sourceHash, bytes);
          installProgram(
            ScriptProgram(
              buildHash: r.sourceHash,
              bytecode: bytes,
              exports: ScriptExports.decode(json),
            ),
          );
        }
      }
      return r;
    } on Object catch (e) {
      debugPrint('Script build failed: $e');
      phase = ScriptBuildPhase.offline;
      notifyListeners();
      return null;
    }
  }

  // ------------------------------------------------------------- events

  void _onBatch(WorkbookChangeBatch batch) {
    var build = false;
    var other = false;
    for (final e in batch.events) {
      if (e is! OtherRowsChanged) continue;
      if (e.table == SheetsTables.scriptBuild) build = true;
      if (_scriptTables.contains(e.table)) other = true;
    }
    if (build) {
      _lastCompile = null;
      unawaited(reloadBuild());
    }
    if (other && project == null && _program != null) _uninstall();
    if (other) {
      notifyListeners();
      services.registry.notifyStateChanged();
    }
    if (build && !_openFired && _program != null) unawaited(fireOpen());
  }

  static const _scriptTables = {
    SheetsTables.scriptProject,
    SheetsTables.scriptFile,
    SheetsTables.scriptBuild,
    SheetsTables.scriptTrigger,
    SheetsTables.macro,
  };

  /// `onEdit` / `onChange` after a user command committed an undo step
  /// (09 §8.7.1): not for scripts, agents, undo/redo or remote changes.
  void _onCommand(CommandInvoked e) {
    if (_program == null || e.result?.isOk != true || e.source.isAgent) {
      return;
    }
    if (services.undo.currentTransaction != null) return;
    final top = services.undo.undoStepsOf(_stack).lastOrNull;
    if (top == null || !_seenSteps.add(top.id)) return;
    if (top.label.startsWith(undoPrefix)) return;
    final changes = [
      for (final entry in top.entries)
        if (entry is SheetsRowsUndoEntry) ...entry.changes,
    ];
    if (changes.isEmpty) return;
    final edit = _editEvent(changes);
    if (edit != null && exports.hasTrigger('onEdit')) {
      unawaited(_fireTrigger(ExecutionKind.onEdit, edit, appendTo: top));
    }
    if (exports.hasTrigger('onChange')) {
      final type = _changeType(changes, edit != null);
      if (type != null) {
        unawaited(_fireTrigger(ExecutionKind.onChange, ChangeEventData(type)));
      }
    }
  }

  EditEventData? _editEvent(List<RowChange> changes) {
    String? sheetId;
    int? top, left, bottom, right;
    for (final c in changes) {
      if (c.table != SheetsTables.cell) continue;
      final cols = {...c.columnsBefore.keys, ...c.columnsAfter.keys};
      if (!cols.contains(CellCols.content) && c.op == RowOp.update) continue;
      final rec = model.record(SheetsTables.cell, c.rowId);
      final cell = rec is CellRecord ? rec : null;
      final sid =
          cell?.sheetId ??
          (c.columnsAfter[Cols.sheetId] ?? c.columnsBefore[Cols.sheetId])
              as String?;
      if (sid == null) continue;
      sheetId ??= sid;
      if (sid != sheetId) continue;
      final s = model.sheet(sid);
      final rowId =
          (c.columnsAfter[CellCols.rowId] ?? c.columnsBefore[CellCols.rowId])
              as String? ??
          cell?.rowId;
      final colId =
          (c.columnsAfter[CellCols.columnId] ??
                  c.columnsBefore[CellCols.columnId])
              as String? ??
          cell?.columnId;
      if (s == null || rowId == null || colId == null) continue;
      final r = s.rows.indexOf(rowId);
      final col = s.columns.indexOf(colId);
      if (r < 0 || col < 0) continue;
      top = top == null || r < top ? r : top;
      bottom = bottom == null || r > bottom ? r : bottom;
      left = left == null || col < left ? col : left;
      right = right == null || col > right ? col : right;
    }
    if (sheetId == null || top == null) return null;
    final rect = GridRect(top, left!, bottom!, right!);
    Object? value;
    if (rect.cellCount == 1) {
      value = editor.editableText(top, left, sheetId: sheetId);
    }
    return EditEventData(sheetId: sheetId, range: rect, value: value);
  }

  String? _changeType(List<RowChange> changes, bool edited) {
    for (final c in changes) {
      switch (c.table) {
        case SheetsTables.sheetRow:
          if (c.op == RowOp.insert) return 'INSERT_ROW';
          if (c.op == RowOp.delete) return 'REMOVE_ROW';
        case SheetsTables.sheetColumn:
          if (c.op == RowOp.insert) return 'INSERT_COLUMN';
          if (c.op == RowOp.delete) return 'REMOVE_COLUMN';
        case SheetsTables.sheet:
          if (c.op == RowOp.insert) return 'INSERT_GRID';
          if (c.op == RowOp.delete) return 'REMOVE_GRID';
      }
    }
    if (edited) return 'EDIT';
    for (final c in changes) {
      if (c.table == SheetsTables.cell) return 'FORMAT';
    }
    return 'OTHER';
  }

  void _onSelection() {
    if (_program == null || !exports.hasTrigger('onSelectionChange')) return;
    _selectionTimer?.cancel();
    _selectionTimer = Timer(const Duration(milliseconds: 300), () {
      if (_disposed || editor.drag.value != null) return;
      final r = editor.selection.resolved;
      unawaited(
        _fireTrigger(
          ExecutionKind.onSelectionChange,
          SelectionChangeEventData(
            sheetId: r.sheetId,
            range: r.activeRange.rect,
          ),
        ),
      );
    });
  }

  // --------------------------------------------------------- executions

  void _onExecution(ExecutionResult r) {
    recent.add(r);
    if (recent.length > 200) recent.removeRange(0, recent.length - 200);
    for (final e in r.logs) {
      // Lines streamed while the function ran are already in the log.
      if (_streamed.remove(e)) continue;
      log.add(ScriptLogLine(r.functionName, e));
    }
    if (log.length > 2000) log.removeRange(0, log.length - 2000);
    _queueReport(_toRow(r));
    notifyListeners();
  }

  /// Queues an execution for upload: in the device's
  /// `LocalScriptExecutionLog` (survives reloads offline), in memory
  /// without a local store.
  void _queueReport(ScriptExecution row) {
    final local = _local;
    if (local != null) {
      unawaited(
        local
            .queueExecutions(_spreadsheetKey, [row.toJson()])
            .then((_) => _scheduleUpload())
            .catchError((Object e) {
              debugPrint('Queueing a script execution failed: $e');
              _pendingReports.add(row);
              _scheduleUpload();
            }),
      );
      return;
    }
    _pendingReports.add(row);
    if (_pendingReports.length > 1000) {
      _pendingReports.removeRange(0, _pendingReports.length - 1000);
    }
    _scheduleUpload();
  }

  void _onCustomBatch(CustomFunctionBatchReport b) {
    if (b.calls == 0) return;
    final first = b.results.isEmpty ? null : b.results.first;
    final failed = b.results.where((r) => !r.ok).firstOrNull;
    _queueReport(
      ScriptExecution(
        uuid: UuidValue.fromString(
          first?.executionId.isNotEmpty == true
              ? first!.executionId
              : services.ids.next().uuid,
        ),
        spreadsheetUuid: itemUuid,
        projectId: _projectUuid(),
        functionName: first?.functionName ?? '',
        kind: ScriptExecutionKind.customFunction,
        userId: 0,
        runAsUserId: 0,
        runtime: clientRuntimeKind,
        status: b.failures > 0
            ? ScriptExecutionStatus.failed
            : ScriptExecutionStatus.completed,
        buildSourceHash: b.buildHash,
        startedAt: (first?.startedAt ?? clock.now()).toUtc(),
        durationMs: b.duration.inMilliseconds,
        logs: '',
        errorMessage: failed?.error?.message,
        cellsRead: 0,
        cellsWritten: 0,
        fetchCalls: 0,
        callCount: b.calls,
      ),
    );
  }

  /// Uploads are batched: at most every 10 s while there are reports.
  void _scheduleUpload() {
    if (_uploadTimer?.isActive ?? false) return;
    _uploadTimer = Timer(const Duration(seconds: 10), () {
      if (!_disposed) unawaited(uploadExecutions());
    });
  }

  UuidValue? _projectUuid() {
    final id = project?.id;
    return id == null ? null : UuidValue.fromString(id);
  }

  ScriptExecution _toRow(ExecutionResult r) => ScriptExecution(
    uuid: UuidValue.fromString(
      r.executionId.isEmpty ? services.ids.next().uuid : r.executionId,
    ),
    spreadsheetUuid: itemUuid,
    projectId: _projectUuid(),
    functionName: r.functionName,
    kind: ScriptExecutionKind.values.byName(r.kind.name),
    userId: 0,
    runAsUserId: 0,
    runtime: clientRuntimeKind,
    status: ScriptExecutionStatus.values.byName(r.status.name),
    buildSourceHash: _program?.buildHash ?? '',
    startedAt: r.startedAt.toUtc(),
    durationMs: r.duration.inMilliseconds,
    logs: r.logsJsonLines,
    errorMessage: r.error?.message,
    errorStackJson: r.error == null
        ? null
        : jsonEncode([for (final f in r.error!.frames) f.toJson()]),
    cellsRead: r.counters.cellsRead,
    cellsWritten: r.counters.cellsWritten,
    fetchCalls: r.counters.fetchCalls,
    callCount: 1,
  );

  /// Uploads finished client executions (best effort; queued offline).
  Future<void> uploadExecutions() async {
    final b = backend;
    if (b == null || !_online) return;
    final local = _local;
    var stored = const <(int, Map<String, Object?>)>[];
    if (local != null) {
      try {
        stored = await local.pendingExecutions(_spreadsheetKey);
      } on Object catch (e) {
        debugPrint('Reading queued script executions failed: $e');
      }
    }
    if (_pendingReports.isEmpty && stored.isEmpty) return;
    final memory = List.of(_pendingReports);
    _pendingReports.clear();
    final batch = [...memory, for (final (_, row) in stored) ?_decodeRow(row)];
    try {
      if (batch.isNotEmpty) await b.reportExecutions(itemUuid, batch);
      if (stored.isNotEmpty) {
        await local!.removeExecutions([for (final (id, _) in stored) id]);
      }
      // More than one batch was waiting.
      if (stored.length >= 200 && !_disposed) _scheduleUpload();
    } on Object {
      _pendingReports.insertAll(0, memory);
      if (!_disposed) _scheduleUpload();
    }
  }

  static ScriptExecution? _decodeRow(Map<String, Object?> row) {
    try {
      return ScriptExecution.fromJson(row);
    } on Object {
      return null;
    }
  }

  /// Executions of this spreadsheet from the server log (Executions panel);
  /// this window's runs when offline.
  Future<List<ScriptExecution>> loadExecutions({
    String? functionName,
    ScriptExecutionStatus? status,
  }) async {
    await uploadExecutions();
    final b = backend;
    if (b != null && _online) {
      try {
        return await b.executions(
          itemUuid,
          functionName: functionName,
          status: status,
          limit: 100,
        );
      } on Object catch (e) {
        debugPrint('Loading executions failed: $e');
      }
    }
    return [
      for (final r in recent.reversed)
        if ((functionName == null || r.functionName == functionName) &&
            (status == null || r.status.name == status.name))
          _toRow(r),
    ];
  }

  // ------------------------------------------------------------- dispose

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    model.removeListener(_onBatch);
    editor.selection.removeListener(_onSelection);
    unawaited(_commands?.cancel());
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _uploadTimer?.cancel();
    _selectionTimer?.cancel();
    _logNotify?.cancel();
    services.prefs.removeListener(_onPrefs);
    if (_draftTimer != null) unawaited(_saveDrafts());
    unawaited(uploadExecutions());
    if (!_ready.isCompleted) _ready.complete();
    final wb = editor.session;
    if (wb is WorkbookSessionBase) wb.customFunctions.target = null;
    final s = _session;
    _session = null;
    if (s != null) unawaited(s.close());
    super.dispose();
  }
}

/// `UrlFetchApp` of client executions: the server proxy (09 §8.3).
class _AppFetcher implements UrlFetcher {
  _AppFetcher(this.service);

  final ScriptService service;

  @override
  Future<FetchResponseData> fetch(
    FetchRequestData request, {
    required bool customFunction,
  }) async {
    final b = service.backend;
    if (b == null || !service._online) {
      throw const FetchFailure(
        'You are offline; UrlFetchApp needs a connection.',
        code: 'offline',
      );
    }
    try {
      return await b.urlFetch(
        service.itemUuid,
        request,
        customFunction: customFunction,
      );
    } on FetchFailure {
      rethrow;
    } on Object catch (e) {
      throw FetchFailure('$e');
    }
  }
}
