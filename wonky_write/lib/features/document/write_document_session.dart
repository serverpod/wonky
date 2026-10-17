/// # WriteDocumentSession — one open Write document (sync & collaboration)
///
/// The per-document sync session the editor screen builds on (Write 03,
/// Write 08, suite 08). The screen's `WriteDocumentController` (the shell's
/// `DocumentController`) owns screen state (find, outline, export, theme)
/// and delegates content sync, undo, presence, comments and suggestions to
/// this object.
///
/// ```dart
/// final session = WriteDocumentSession(services: services, itemUuid: uuid)
///   ..open();
/// final controller = WriteDocumentController(session: session, …);
/// // dispose the controller first, then the session.
/// ```
///
/// Public API:
///
/// | Member | What |
/// |--------|------|
/// | [open] / [dispose] | Loads the drive item, connects `document.connect` (reconnects with backoff) |
/// | [phase], [error] | `loading` → `ready`, or `noAccess` / `failed` |
/// | [editor] | The `WriteEditorController` (content, selection, view state) |
/// | [item], [title], [documentUuid], [itemUuid] | Drive item, name, ids |
/// | [role] / [currentRole] | Effective role (live `RoleChanged`; Editing → Suggesting → Viewing clamp) |
/// | [setMode], [canUseMode] | Editing / Suggesting / Viewing, clamped to the role, remembered per document |
/// | [meta] (`WriteDocumentMeta`), [setMeta], [setTheme], [setPageSetup], [setLanguage] | Document metadata (live `MetaChanged`); changes are undoable (`write.meta`) |
/// | [syncStatus], [retry], [revision], [sync] | Saved / Saving… / Offline / Error for `SyncStatusIndicator`; the OT controller |
/// | [undoHandlers], [undoStackKey], [shouldRestoreSelection] | `write.content` + `write.meta` undo handlers; the shell restores selections only when [shouldRestoreSelection] says so (content undo restores the rebased selection itself) |
/// | [commentAnchors] / [comments] | `CommentAnchorProvider` (anchors, highlights, click-to-activate, next/previous, re-attach) |
/// | [suggestions] | Pending suggestions, accept / reject / withdraw (all) |
/// | [presence], [revealParticipant] | Collaborators on the document stream, remote cursors, jump/follow |
/// | [contentVersion] | Bumps on every content change |
/// | [applyContentChange] | Applies a Delta as an undoable local change (agents, overlay changes) |
/// | [revealRange] | Scrolls a Delta range into view |
/// | [saveCopy] | "Save my changes as a copy" after a lost resync |
/// | [offline], [openedFromCache] | The user's offline store (suite 12 §1); whether the document was rendered from it |
///
/// Offline (suite 12 §1.2): with the user's `WriteOffline` store the
/// document opens from the local copy immediately (stale-while-revalidate)
/// and then connects; local changes go to the durable outbox before they
/// are sent; documents created offline open at once and connect after
/// their queued creation; metadata changes made offline are queued.
///
/// Undo is not persisted by the shell for Write (the controller returns
/// `persistUndo => false`); the session stores its stacks with the offline
/// copy instead (best effort, restored only onto the identical document).
library;

import 'dart:async';
import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart' show SyncState, SyncStatus;
import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaUtils, MarkdownCodec, PageSetup, documentHash;

import '../../l10n/write_l10n.dart';
import '../ai/ai_undo_grouping.dart';
import '../collab/remote_presence.dart';
import '../comments/write_comments.dart';
import '../editor/applier/delta_applier.dart' show DeltaSelection;
import '../editor/controller/editor_types.dart';
import '../editor/controller/write_editor_controller.dart';
import '../offline/sqlite_sync_persistence.dart';
import '../offline/write_local_store.dart' show StoredDocument;
import '../offline/write_offline.dart';
import '../suggestions/suggestions_controller.dart';
import '../sync/connection_keeper.dart';
import '../sync/document_sync_controller.dart';
import 'reveal.dart';
import 'write_document_api.dart';
import 'write_undo.dart';

/// Lifecycle of a [WriteDocumentSession].
enum WriteSessionPhase {
  /// Loading the item and connecting (first `Init` not yet received).
  loading,

  /// The document is loaded (it may be offline or reconnecting later).
  ready,

  /// No access (or the document does not exist).
  noAccess,

  /// Loading failed (see [WriteDocumentSession.error]).
  failed,
}

/// Document metadata (Write 03 §6) in the shape the screen uses.
@immutable
class WriteDocumentMeta {
  const WriteDocumentMeta({
    required this.pageSetup,
    this.themeUuid,
    this.language,
    this.frontMatter,
  });

  static final empty = WriteDocumentMeta(
    pageSetup: PageSetup.defaultsFor('en'),
  );

  /// The page setup (defaults when unset).
  final PageSetup pageSetup;

  /// The assigned theme (null = the user's default theme).
  final String? themeUuid;

  /// BCP-47 language tag (null = the user's locale).
  final String? language;

  /// YAML front matter (round-tripped through Markdown).
  final String? frontMatter;

  static WriteDocumentMeta fromView(DocumentMetaView? v) {
    if (v == null) return empty;
    var setup = PageSetup.defaultsFor(v.language ?? 'en');
    final json = v.pageSetupJson;
    if (json.isNotEmpty && json != '{}') {
      try {
        setup = PageSetup.fromJson(
          (jsonDecode(json) as Map).cast<String, dynamic>(),
        );
      } on Object {
        // Keep the defaults.
      }
    }
    return WriteDocumentMeta(
      pageSetup: setup,
      themeUuid: v.themeId?.uuid,
      language: v.language,
      frontMatter: v.frontMatter,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WriteDocumentMeta &&
      other.pageSetup == pageSetup &&
      other.themeUuid == themeUuid &&
      other.language == language &&
      other.frontMatter == frontMatter;

  @override
  int get hashCode => Object.hash(pageSetup, themeUuid, language, frontMatter);
}

/// One open Write document: content sync, undo, presence, comments,
/// suggestions and metadata. See the library documentation for the API.
class WriteDocumentSession extends ChangeNotifier {
  WriteDocumentSession({
    required this.services,
    required String itemUuid,
    WriteDocumentApi? api,
    ConnectionKeeper? keeper,
    UuidV7Generator? ids,
    Future<WriteOffline?> Function()? offline,
  }) : itemUuid = UuidValue.fromString(itemUuid),
       _offlineLookup = offline,
       _ids = ids ?? UuidV7Generator.instance,
       api =
           api ??
           ServerWriteDocumentApi(
             services.client ??
                 (throw StateError('WriteDocumentSession needs a client')),
           ),
       keeper =
           keeper ??
           ShellConnectionKeeper(services.supervisor, services.connectivity) {
    editor = WriteEditorController(
      documentUuid: itemUuid,
      userUuid: services.me?.uuid.uuid ?? '',
      mode: EditorMode.viewing,
    );
    _host = _SessionHost(this);
    presence = RemotePresenceController(this);
    comments = WriteComments(this);
    suggestions = WriteSuggestionsController(this);
    _localSub = editor.localChanges.listen(_onLocalChange);
    _noticeSub = editor.notices.listen(_onNotice);
    editor.addListener(_onEditorChanged);
    _lastMode = editor.mode;
    services.currentItem.addListener(_onCurrentItem);
    _outcomeSub = services.undo.outcomes.listen((_) {
      _selectionRestoredByUndo = false;
    });
    _contentUndo = _WriteContentUndoHandler(this);
    _metaUndo = WriteMetaUndoHandler(_writeMeta);
    _open[this.itemUuid.uuid] = this;
  }

  static final Map<String, WriteDocumentSession> _open = {};

  /// The open session of drive item [itemUuid], if any.
  static WriteDocumentSession? forItem(UuidValue? itemUuid) =>
      itemUuid == null ? null : _open[itemUuid.uuid];

  /// The session of the active document of a command context.
  static WriteDocumentSession? of(CommandContext ctx) {
    final d = ctx.document;
    if (d == null || d.kind != DriveItemKind.document) return null;
    return forItem(d.itemUuid);
  }

  final ShellServices services;

  /// The drive item uuid (route `/d/:uuid`).
  final UuidValue itemUuid;

  /// Server calls (drive item, updateMeta, history).
  final WriteDocumentApi api;

  /// Keeps the document stream connected.
  final ConnectionKeeper keeper;
  final UuidV7Generator _ids;
  final Future<WriteOffline?> Function()? _offlineLookup;

  WriteOffline? _offline;

  /// The signed-in user's offline store (null when unavailable: the
  /// session then keeps its outbox in memory only).
  WriteOffline? get offline => _offline;

  bool _fromCache = false;

  /// Whether the document was rendered from the local copy before the
  /// server answered.
  bool get openedFromCache => _fromCache;

  /// The editor controller: content, selection, view state (zoom, layout,
  /// find matches, remote cursors, comment highlights).
  late final WriteEditorController editor;

  /// Collaborators and remote cursors.
  late final RemotePresenceController presence;

  /// Comment anchors, highlights and navigation.
  late final WriteComments comments;

  /// Pending suggestions, accept / reject.
  late final WriteSuggestionsController suggestions;

  late final _SessionHost _host;
  late final _WriteContentUndoHandler _contentUndo;

  /// Undo grouping of AI assistant runs made on behalf of this session.
  late final AiUndoGrouping aiUndo = AiUndoGrouping(
    undo: services.undo,
    stack: undoStackKey,
    nextId: _ids.nextString,
    l10n: () => writeL10nOf(services),
  );
  late final WriteMetaUndoHandler _metaUndo;
  StreamSubscription<LocalDeltaChange>? _localSub;
  StreamSubscription<EditorNotice>? _noticeSub;
  StreamSubscription<SyncEvent>? _syncSub;
  StreamSubscription<UndoOutcome>? _outcomeSub;

  final ValueNotifier<WriteSessionPhase> _phase = ValueNotifier(
    WriteSessionPhase.loading,
  );

  /// `loading` → `ready` (or `noAccess` / `failed`).
  ValueListenable<WriteSessionPhase> get phase => _phase;

  /// Why loading failed (or access was lost).
  Object? error;

  final ValueNotifier<int> _contentVersion = ValueNotifier(0);

  /// Incremented on every content change (local or remote).
  ValueListenable<int> get contentVersion => _contentVersion;

  final ValueNotifier<SyncStatus> _status = ValueNotifier(
    const SyncStatus(state: SyncState.connecting),
  );

  /// Saved / Saving… / Offline / Error (`SyncStatusIndicator`).
  ValueListenable<SyncStatus> get syncStatus => _status;

  final ValueNotifier<Role> _role = ValueNotifier(Role.viewer);

  /// The effective role (drive item, then the document stream's, live).
  ValueListenable<Role> get role => _role;

  /// [role]'s current value.
  Role get currentRole => _role.value;

  final ValueNotifier<WriteDocumentMeta> _meta = ValueNotifier(
    WriteDocumentMeta.empty,
  );

  /// Theme, page setup, language and front matter.
  ValueListenable<WriteDocumentMeta> get meta => _meta;

  DocumentSyncController? _sync;

  /// The OT sync controller (null until [open] resolved the document).
  DocumentSyncController? get sync => _sync;

  /// The last server revision applied locally.
  int get revision => _sync?.revision ?? 0;

  DriveItemView? _item;

  /// The drive item (null while loading).
  DriveItemView? get item => _item;

  /// The item's name.
  String get title => _item?.name ?? '';

  UuidValue? _documentUuid;

  /// The document's uuid (`DriveItemView.contentRef`), once known.
  UuidValue? get documentUuid => _documentUuid;

  /// Called with `{"themeId", "version", "hash"}` JSON when the document's
  /// theme was saved (live theme link, Write 06 §5.3).
  void Function(String valueJson)? onThemeVersion;

  /// The undo stack of this document (same key as the screen controller's).
  UndoStackKey get undoStackKey => UndoStackKey(itemUuid.uuid);

  /// Whether the first `Init` arrived.
  bool get isLoaded => _sync?.isLoaded ?? false;

  /// The local user's auth UUID (suggestion authorship).
  String get userUuid => services.me?.uuid.uuid ?? editor.userUuid;

  bool _opened = false;
  bool _disposed = false;
  EditorMode _lastMode = EditorMode.viewing;
  EditorMode? _preferredMode;
  bool _settingMode = false;
  bool _selectionRestoredByUndo = false;

  // Typing coalescing (suite 08 §3.1 principle 4).
  LocalDeltaChange? _lastTyping;
  String? _typingKey;
  int _typingLength = 0;

  // ---------------------------------------------------------------------------
  // Opening.

  /// Loads the document — from the local copy when there is one, then
  /// from the server — and connects the document stream.
  Future<void> open() async {
    if (_opened || _disposed) return;
    _opened = true;
    try {
      final offline =
          await (_offlineLookup?.call() ?? WriteOffline.ready(services));
      if (_disposed) return;
      _offline = offline;
      var stored = await _loadStored(offline);
      if (_disposed) return;
      final item = stored?.item ?? await _loadItem();
      if (_disposed) return;
      _setItem(item);
      final doc = item.contentRef ?? stored?.documentUuid;
      if (item.kind != DriveItemKind.document || doc == null) {
        throw WonkyException(
          code: WonkyErrorCode.notFound,
          message: writeL10nOf(services).sessionNotADocument,
        );
      }
      _documentUuid = doc;
      if (offline != null) {
        await offline.claim(doc);
        _claimed = true;
        if (stored == null && offline.isPendingCreate(itemUuid)) {
          stored = await _prepareCreatedOffline(offline, doc, item);
        }
      }
      if (stored == null && !services.connectivity.online) {
        throw const OfflineException('not available offline');
      }
      _preferredMode = await _loadModePref();
      if (_disposed) return;
      final sync = DocumentSyncController(
        transport: api.transport(doc),
        host: _host,
        keeper: keeper,
        key: 'write.document:${doc.uuid}',
        ids: _ids,
        persistence: offline?.persistenceFor(
          documentUuid: doc,
          itemUuid: itemUuid,
          stored: stored,
          item: item,
        ),
      );
      _sync = sync;
      _syncSub = sync.events.listen(_onSyncEvent);
      sync.status.addListener(_onStatus);
      presence.attach(sync);
      if (stored != null) {
        _fromCache = true;
        sync.restore(stored.state);
        await _restoreUndo();
        if (_disposed) return;
      }
      if (offline != null) {
        unawaited(offline.opened(doc, item));
        services.undo.addListener(_onUndoChanged);
      }
      if (offline != null && offline.isPendingCreate(itemUuid)) {
        // Created offline: connect once the queued creation went through.
        unawaited(
          offline.whenCreated(itemUuid).then((_) {
            if (!_disposed) sync.start();
          }),
        );
      } else {
        sync.start();
      }
      if (stored?.item != null) unawaited(_refreshItem());
      notifyListeners();
    } catch (e) {
      if (_disposed) return;
      error = e;
      _phase.value = _isAccessError(e)
          ? WriteSessionPhase.noAccess
          : WriteSessionPhase.failed;
      if (isOfflineError(e)) _reopenWhenOnline();
      notifyListeners();
    }
  }

  bool _claimed = false;

  Future<StoredDocument?> _loadStored(WriteOffline? offline) async {
    if (offline == null) return null;
    try {
      return await offline.load(itemUuid);
    } on Object catch (e) {
      debugPrint('Reading the local copy failed: $e');
      return null;
    }
  }

  /// The drive item from the server, or — offline — from the drive cache.
  Future<DriveItemView> _loadItem() async {
    if (services.connectivity.online) {
      try {
        return await api.getItem(itemUuid);
      } catch (e) {
        if (!isOfflineError(e)) rethrow;
      }
    }
    final known = services.knownItem(itemUuid);
    if (known != null) return known;
    throw const OfflineException('not available offline');
  }

  /// A document created offline: its local copy starts empty at revision 0
  /// (the server creates it empty, suite 12 §1.2).
  Future<StoredDocument?> _prepareCreatedOffline(
    WriteOffline offline,
    UuidValue doc,
    DriveItemView item,
  ) async {
    final d = services.drive;
    final pending = d is CachedDriveRepository
        ? d.pendingCreate(itemUuid)
        : null;
    if (pending != null &&
        (pending.args['templateUuid'] != null ||
            ((pending.args['initialMarkdown'] as String?) ?? '').isNotEmpty)) {
      // Its content comes from the server (template, import).
      return null;
    }
    await offline.prepareLocalDocument(documentUuid: doc, item: item);
    return offline.load(itemUuid);
  }

  /// Revalidates the cached drive item (title, role, pin).
  Future<void> _refreshItem() async {
    if (!services.connectivity.online) return;
    try {
      final item = await api.getItem(itemUuid);
      if (_disposed) return;
      _setItem(item);
      final doc = _documentUuid;
      if (doc != null) unawaited(_offline?.updateItem(doc, item));
    } catch (_) {
      // The stream reports lost access; offline keeps the cached item.
    }
  }

  VoidCallback? _onlineListener;

  /// Retries a failed open when the connection comes back.
  void _reopenWhenOnline() {
    if (_onlineListener != null) return;
    void l() {
      if (!services.connectivity.online || _disposed) return;
      _stopReopen();
      unawaited(_reopen());
    }

    _onlineListener = l;
    services.connectivity.addListener(l);
  }

  void _stopReopen() {
    final l = _onlineListener;
    if (l != null) services.connectivity.removeListener(l);
    _onlineListener = null;
  }

  Future<void> _reopen() async {
    if (_disposed || _sync != null) return;
    _opened = false;
    error = null;
    _phase.value = WriteSessionPhase.loading;
    notifyListeners();
    await open();
  }

  static bool _isAccessError(Object e) =>
      e is WonkyException &&
      (e.code == WonkyErrorCode.forbidden || e.code == WonkyErrorCode.notFound);

  Role? _docRole;

  void _setItem(DriveItemView item) {
    _item = item;
    final p = _sync?.persistence;
    if (p is SqliteSyncPersistence) p.item = item;
    if (_docRole == null) _setRole(roleOf(item.role));
    notifyListeners();
  }

  void _onCurrentItem() {
    final v = services.currentItem.value;
    if (v == null || v.uuid != itemUuid || v == _item) return;
    _setItem(v);
  }

  void _setRole(Role r) {
    if (_role.value == r) return;
    _role.value = r;
    _applyRoleToMode();
  }

  // ---------------------------------------------------------------------------
  // Mode.

  bool _readOnlyView = false;

  /// Whether the mobile read-only view is on (suite 02 §6.1): only Viewing.
  bool get readOnlyView => _readOnlyView;

  /// Turns the mobile read-only view on (Viewing, whatever the role) or off
  /// (back to the remembered or the role's mode). Not remembered.
  void setReadOnlyView(bool readOnly) {
    if (_readOnlyView == readOnly) return;
    _readOnlyView = readOnly;
    if (isLoaded) {
      if (readOnly) {
        _applyRoleToMode();
      } else if (editor.mode == EditorMode.viewing) {
        _setModeInternally(defaultMode());
      }
    }
    notifyListeners();
  }

  /// Whether the role allows [m] (Editing needs Editor+, Suggesting
  /// Commenter+); only Viewing in the mobile read-only view.
  bool canUseMode(EditorMode m) => switch (m) {
    EditorMode.editing => !_readOnlyView && currentRole.canEdit,
    EditorMode.suggesting => !_readOnlyView && currentRole.canComment,
    EditorMode.viewing => true,
  };

  /// Switches the mode; ignored when the role does not allow it. Remembered
  /// per user and document.
  void setMode(EditorMode m) {
    if (!isLoaded || !canUseMode(m)) return;
    editor.mode = m;
  }

  /// The mode to use for the current role: the remembered one if allowed,
  /// else Editing (Editors), Suggesting (Commenters) or Viewing.
  EditorMode defaultMode() {
    final pref = _preferredMode;
    if (pref != null && canUseMode(pref)) return pref;
    if (canUseMode(EditorMode.editing)) return EditorMode.editing;
    if (canUseMode(EditorMode.suggesting)) return EditorMode.suggesting;
    return EditorMode.viewing;
  }

  /// Switches to an allowed mode when the role no longer permits the
  /// current one (Editor → Commenter: Suggesting; → Viewer: Viewing).
  void _applyRoleToMode() {
    if (!isLoaded || canUseMode(editor.mode)) return;
    _setModeInternally(defaultMode());
  }

  void _setModeInternally(EditorMode m) {
    _settingMode = true;
    try {
      editor.mode = m;
    } finally {
      _settingMode = false;
    }
  }

  String get _modeKey => 'write.mode.${itemUuid.uuid}';

  Future<EditorMode?> _loadModePref() async {
    try {
      final v = await services.userStore.read(_modeKey);
      return EditorMode.values.where((m) => m.name == v).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveModePref(EditorMode m) async {
    try {
      await services.userStore.write(_modeKey, m.name);
    } catch (_) {
      // Best effort.
    }
  }

  void _onEditorChanged() {
    final m = editor.mode;
    if (m == _lastMode) return;
    _lastMode = m;
    if (isLoaded && !canUseMode(m)) {
      // `write.mode.set` sets the controller directly; enforce the role.
      scheduleMicrotask(() {
        if (!_disposed && !canUseMode(editor.mode)) {
          _setModeInternally(defaultMode());
        }
      });
    } else if (isLoaded && !_settingMode) {
      _preferredMode = m;
      unawaited(_saveModePref(m));
    }
    notifyListeners();
  }

  /// Called by the screen when the shell reports a role change.
  void onRoleChanged(Role role) {
    _docRole = role;
    _setRole(role);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Metadata.

  /// The raw metadata as the server sent it.
  DocumentMetaView? get metaView => _sync?.meta;

  String _currentMetaJson(String field) {
    final m = metaView;
    return switch (field) {
      'themeId' => jsonEncode(m?.themeId?.uuid),
      'pageSetup' =>
        (m?.pageSetupJson.isNotEmpty ?? false) ? m!.pageSetupJson : '{}',
      'language' => jsonEncode(m?.language),
      'frontMatter' => jsonEncode(m?.frontMatter),
      _ => 'null',
    };
  }

  /// Changes a document property (`themeId`, `pageSetup`, `language`,
  /// `frontMatter`) and records a `write.meta` undo entry — in the open
  /// command transaction, or as its own step labelled [label].
  Future<void> setMeta(String field, String valueJson, {String? label}) async {
    final doc = _documentUuid;
    if (doc == null || !currentRole.canEdit) return;
    final before = _currentMetaJson(field);
    if (WriteMetaUndoEntry.sameJson(before, valueJson)) return;
    await _writeMeta(field, valueJson);
    final entry = WriteMetaUndoEntry(
      documentUuid: doc.uuid,
      field: field,
      beforeJson: before,
      afterJson: valueJson,
    );
    final undo = services.undo;
    final t = undo.currentTransaction;
    if (t != null && t.stack == undoStackKey) {
      t.record(entry);
    } else if (!undo.isApplying) {
      undo.push(
        UndoStep(
          id: _ids.nextString(),
          label: label ?? writeL10nOf(services).sessionUndoChangeSettings,
          entries: [entry],
        ),
        stack: undoStackKey,
      );
    }
  }

  /// Assigns a theme (null = the default).
  Future<void> setTheme(String? themeUuid, {String? label}) => setMeta(
    'themeId',
    jsonEncode(themeUuid),
    label: label ?? writeL10nOf(services).sessionUndoChangeTheme,
  );

  /// Replaces the page setup.
  Future<void> setPageSetup(PageSetup setup, {String? label}) => setMeta(
    'pageSetup',
    jsonEncode(setup.toJson()),
    label: label ?? writeL10nOf(services).sessionUndoChangePageSetup,
  );

  /// Sets the document language (null = the user's locale).
  Future<void> setLanguage(String? language, {String? label}) => setMeta(
    'language',
    jsonEncode(language),
    label: label ?? writeL10nOf(services).sessionUndoChangeLanguage,
  );

  Future<void> _writeMeta(String field, String valueJson) async {
    final doc = _documentUuid;
    if (doc == null) return;
    final clientOpId = _ids.next();
    final offline = _offline;
    try {
      if (!services.connectivity.online) {
        throw const OfflineException('offline');
      }
      if (offline != null && offline.isPendingCreate(itemUuid)) {
        throw const OfflineException('not created yet');
      }
      await api.updateMeta(doc, field, valueJson, clientOpId);
    } catch (e) {
      if (!isOfflineError(e) || offline == null) rethrow;
      // Saved on this device; sent with the same id on reconnect.
      await offline.queueMeta(doc, field, valueJson, clientOpId);
    }
    // Optimistic: the `MetaChanged` echo confirms it.
    _sync?.applyLocalMeta(field, valueJson);
    _meta.value = WriteDocumentMeta.fromView(metaView);
  }

  // ---------------------------------------------------------------------------
  // Content.

  /// Applies [change] (against the current document) as a local, undoable
  /// change labelled [label] — for agents, overlay changes (comment
  /// anchors) and suggestion decisions ([bypassSuggesting]: applied as is
  /// in Suggesting mode). Overlay-only changes also work in Viewing mode
  /// (commenters comment while reading). Returns false when the change was
  /// not applied.
  bool applyContentChange(
    Delta change, {
    required String label,
    LocalChangeSource source = LocalChangeSource.command,
    DeltaSelection? selectionAfter,
    bool bypassSuggesting = false,
  }) {
    if (!isLoaded || DeltaUtils.isNoop(change)) return false;
    final overlay = _isOverlayOnly(change);
    final m = editor.mode;
    final r = currentRole;
    final allowed = overlay || bypassSuggesting
        ? r.canComment
        : r.canEdit || (r.canComment && m == EditorMode.suggesting);
    if (!allowed) return false;
    if (m == EditorMode.viewing && !overlay && !bypassSuggesting) return false;
    final direct =
        m == EditorMode.viewing ||
        (m == EditorMode.suggesting && (overlay || bypassSuggesting));
    if (direct) {
      // The editor refuses edits in Viewing mode and rewrites them in
      // Suggesting mode; apply as an undo-source change and record it here.
      final applied = editor.applyLocal(
        change,
        label: label,
        source: LocalChangeSource.undo,
        selectionAfter: selectionAfter,
      );
      if (applied == null) return false;
      _recordUndo(applied.copyWith(source: source));
      return true;
    }
    return editor.applyLocal(
          change,
          label: label,
          source: source,
          selectionAfter: selectionAfter,
        ) !=
        null;
  }

  /// Scrolls Delta range `[start, end]` into view (comment anchors,
  /// collaborator carets, suggestions).
  void revealRange(int start, int end) =>
      revealDocumentRange(editor.documentLayout, editor.mirror, start, end);

  static bool _isOverlayOnly(Delta change) {
    for (final op in change.operations) {
      if (op.isInsert || op.isDelete) return false;
      final attrs = op.attributes;
      if (attrs == null) continue;
      if (!attrs.keys.every((k) => k.startsWith('cmt_'))) return false;
    }
    return true;
  }

  void _onLocalChange(LocalDeltaChange c) {
    final sync = _sync;
    if (sync == null || !sync.isLoaded) return;
    sync.submitLocal(
      c.delta,
      kind: c.source == LocalChangeSource.agent
          ? DocumentOpKind.aiEdit
          : DocumentOpKind.content,
    );
    _contentVersion.value++;
    if (c.source == LocalChangeSource.undo) {
      _lastTyping = null;
      return;
    }
    _recordUndo(c);
  }

  void _recordUndo(LocalDeltaChange c) {
    final undo = services.undo;
    if (undo.isApplying) return;
    final entry = WriteContentUndoEntry(
      change: c.inverse,
      select: c.selectionBefore,
      counterSelect: c.selectionAfter,
    );
    final t = undo.currentTransaction;
    if (t != null && t.stack == undoStackKey) {
      t.record(entry);
      _lastTyping = null;
      return;
    }
    undo.push(
      UndoStep(
        id: _ids.nextString(),
        label: c.label,
        entries: [entry],
        source: c.source == LocalChangeSource.agent
            ? InvocationSource.ai
            : InvocationSource.ui,
        coalesceKey: _coalesceKey(c),
      ),
      stack: undoStackKey,
    );
  }

  /// Consecutive typing (or deleting) in the same block within 1 s and
  /// without caret jumps joins the previous step (Write 03 §4).
  String? _coalesceKey(LocalDeltaChange c) {
    final prev = _lastTyping;
    final steps = services.undo.undoStepsOf(undoStackKey);
    final top = steps.isEmpty ? null : steps.last;
    if (prev != null &&
        _typingKey != null &&
        top?.coalesceKey == _typingKey &&
        prev.canCoalesce(c, groupLength: _typingLength)) {
      _lastTyping = c;
      _typingLength += c.size;
      return _typingKey;
    }
    if (c.source == LocalChangeSource.input &&
        c.kind != LocalChangeKind.other) {
      _lastTyping = c;
      _typingLength = c.size;
      return _typingKey = _ids.nextString();
    }
    _lastTyping = null;
    _typingKey = null;
    return null;
  }

  /// A remote (or fix-up / resync) change was applied to the editor:
  /// rebase the undo and redo stacks over it (Write 03 §4).
  void _afterRemoteChange(Delta change) {
    final stack = undoStackKey;
    final undo = services.undo;
    final rebased = rebaseWriteStacks(
      undo.undoStepsOf(stack),
      undo.redoStepsOf(stack),
      change,
    );
    if (rebased != null) undo.applyRemote(stack, rebased);
    _contentVersion.value++;
  }

  void _onNotice(EditorNotice n) {
    if (n.kind == EditorNoticeKind.documentFull) {
      services.toasts.error(writeL10nOf(services).sessionDocumentFull);
    }
  }

  // ---------------------------------------------------------------------------
  // Sync events.

  void _onStatus() {
    final s = _sync?.status.value;
    if (s != null && !_disposed) _status.value = s;
  }

  void _onSyncEvent(SyncEvent e) {
    if (_disposed) return;
    switch (e) {
      case SyncLoaded():
        _docRole = roleOf(_sync!.role ?? _item?.role ?? AccessRole.viewer);
        _role.value = _docRole!;
        _meta.value = WriteDocumentMeta.fromView(metaView);
        editor.userUuid = userUuid;
        _setModeInternally(defaultMode());
        _lastMode = editor.mode;
        _contentVersion.value++;
        _phase.value = WriteSessionPhase.ready;
        notifyListeners();
      case SyncRoleChanged(:final role, :final initial):
        final previous = currentRole;
        _docRole = roleOf(role);
        _setRole(_docRole!);
        if (!initial && previous != currentRole) {
          final l = writeL10nOf(services);
          services.toasts.show(
            l.sessionAccessChanged(_roleName(l, currentRole)),
          );
        }
        notifyListeners();
      case SyncMetaChanged(:final field, :final valueJson)
          when field == 'themeVersion':
        // The document's theme was saved (Write 06 §5.3): no metadata change.
        onThemeVersion?.call(valueJson);
      case SyncMetaChanged(:final field, :final valueJson):
        _meta.value = WriteDocumentMeta.fromView(metaView);
        final doc = _documentUuid;
        if (doc != null) {
          services.undo.applyRemote(
            undoStackKey,
            FieldRemoteChange(
              domain: WriteMetaUndoEntry.domainName,
              target: doc.uuid,
              key: field,
              value: valueJson,
            ),
          );
        }
        notifyListeners();
      case SyncResynced():
        _onResynced(e);
      case SyncAccessLost(:final error):
        this.error = error;
        final lostDoc = _documentUuid;
        final p = _sync?.persistence;
        if (lostDoc != null &&
            p is SqliteSyncPersistence &&
            !(_sync?.hasPendingChanges ?? true)) {
          // No access, nothing unsent: the local copy goes.
          p.discard();
          unawaited(_offline?.forget(lostDoc));
        }
        _setModeInternally(EditorMode.viewing);
        _phase.value = WriteSessionPhase.noAccess;
        notifyListeners();
      case SyncConnected():
        final doc = _documentUuid;
        final offline = _offline;
        if (doc != null && offline != null) {
          unawaited(offline.replayMeta(doc, api));
        }
      case SyncDisconnected() ||
          SyncParticipantsChanged() ||
          SyncRemoteCursor():
        break;
    }
  }

  static String _roleName(WriteLocalizations l, Role r) => switch (r) {
    Role.viewer => l.sessionRoleViewer,
    Role.commenter => l.sessionRoleCommenter,
    Role.editor => l.sessionRoleEditor,
    Role.owner => l.sessionRoleOwner,
  };

  void _onResynced(SyncResynced e) {
    final recovery = e.recoveryDocument;
    if (!e.lostLocalChanges) return;
    final l = writeL10nOf(services);
    final tooOld = e.reason == ResyncReason.rebaseTooOld;
    final reason = switch (e.code) {
      DocRejectCode.tooLarge => l.sessionRejectTooLarge,
      DocRejectCode.forbiddenForRole => l.sessionRejectForbidden,
      DocRejectCode.rebaseTooOld => l.sessionRejectTooOld,
      _ => e.message,
    };
    services.toasts.show(
      tooOld ? l.sessionOfflineChangesNotMerged : l.sessionChangesNotSaved,
      description: reason,
      destructive: true,
      duration: const Duration(seconds: 20),
      actionLabel: recovery == null
          ? null
          : (tooOld
                ? l.sessionSaveOfflineChangesAsCopy
                : l.sessionSaveChangesAsCopy),
      onAction: recovery == null
          ? null
          : () => saveCopy(recovery, offlineChanges: tooOld),
    );
  }

  /// Saves [document] (e.g. unsaved local changes) as a new document next
  /// to this one ("Save my changes as a copy", suite 12 §1.2), named
  /// "<title> (my changes)" — or "(offline changes)" with
  /// [offlineChanges]. With the offline store the copy is created with
  /// client ids and its content goes through the outbox (works offline,
  /// keeps every attribute); otherwise it is created from Markdown.
  Future<DriveItemView?> saveCopy(
    Delta document, {
    bool offlineChanges = false,
  }) async {
    final l = writeL10nOf(services);
    final name = offlineChanges
        ? l.sessionCopyNameOfflineChanges(title)
        : l.sessionCopyNameMyChanges(title);
    try {
      final offline = _offline;
      final copy = offline != null
          ? await offline.createDocument(
              parentUuid: _item?.parentUuid,
              name: name,
              content: document,
            )
          : await services.drive.createDocument(
              parentUuid: _item?.parentUuid,
              name: name,
              initialMarkdown: const MarkdownCodec().exportMarkdown(document),
            );
      services.toasts.show(
        l.sessionCopySaved,
        description: copy.name,
        actionLabel: l.sessionOpen,
        onAction: () => services.openItem(copy),
      );
      return copy;
    } catch (e) {
      services.toasts.error(l.sessionCopyFailed, description: '$e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Hooks for the screen's DocumentController.

  /// `write.content` and `write.meta` undo handlers.
  List<UndoHandler<UndoEntry>> get undoHandlers => [_contentUndo, _metaUndo];

  /// Whether the shell should restore a step's (unrebased) selection
  /// snapshot now. False right after a content entry restored its own,
  /// rebased selection (call from `DocumentController.restoreSelection`).
  bool shouldRestoreSelection() {
    if (!_selectionRestoredByUndo) return true;
    _selectionRestoredByUndo = false;
    return false;
  }

  /// Reconnects now (sync status "Retry"); re-opens after a failed open.
  Future<void> retry() async {
    if (_sync == null && _phase.value == WriteSessionPhase.failed) {
      _stopReopen();
      unawaited(services.connectivity.reconnect());
      await _reopen();
      return;
    }
    _sync?.retry();
  }

  // ---------------------------------------------------------------------------
  // Undo persistence (best effort, suite 12 §1.1 `LocalUndoStack`).

  Timer? _undoSave;

  final Completer<void> _closed = Completer<void>();

  /// Completes after [dispose] once the local copy is written (tests, the
  /// screen's teardown).
  Future<void> get whenClosed => _closed.future;

  void _onUndoChanged() {
    if (!isLoaded || _disposed) return;
    _undoSave?.cancel();
    _undoSave = Timer(const Duration(milliseconds: 800), () {
      unawaited(_saveUndo());
    });
  }

  /// The newest steps that can be stored: everything after the last step
  /// that has an entry without JSON (older steps only make sense together
  /// with the newer ones).
  static List<Map<String, Object?>> _storable(List<UndoStep> steps) {
    final out = <Map<String, Object?>>[];
    for (final st in steps.reversed) {
      final j = st.toJson();
      if (j == null) break;
      out.insert(0, j);
    }
    return out;
  }

  Future<void> _saveUndo() async {
    final offline = _offline;
    final doc = _documentUuid;
    if (offline == null || doc == null || !isLoaded) return;
    final undo = services.undo;
    final stacks = {
      'undo': _storable(undo.undoStepsOf(undoStackKey)),
      'redo': _storable(undo.redoStepsOf(undoStackKey)),
    };
    await offline.saveUndo(doc, stacks, documentHash(editor.delta));
  }

  Future<void> _restoreUndo() async {
    final offline = _offline;
    final doc = _documentUuid;
    if (offline == null || doc == null) return;
    final json = await offline.loadUndo(doc, documentHash(editor.delta));
    if (json == null || _disposed) return;
    final decoders = <String, UndoEntryDecoder>{
      WriteContentUndoEntry.domainName: WriteContentUndoEntry.fromJson,
      WriteMetaUndoEntry.domainName: WriteMetaUndoEntry.fromJson,
    };
    List<UndoStep> decode(Object? list) {
      final out = <UndoStep>[];
      if (list is! List) return out;
      for (final j in list) {
        if (j is! Map) return const [];
        final st = UndoStep.fromJson(j.cast<String, Object?>(), decoders);
        if (st == null) return const [];
        out.add(st);
      }
      return out;
    }

    services.undo.restoreSteps(
      undoStackKey,
      undo: decode(json['undo']),
      redo: decode(json['redo']),
    );
  }

  /// Comment anchors for the shell's comments controller.
  CommentAnchorProvider get commentAnchors => comments;

  /// Scrolls to a collaborator's caret (presence avatar click).
  void revealParticipant(String sessionId) => presence.reveal(sessionId);

  @override
  void dispose() {
    if (_disposed) return;
    final undoSaved = isLoaded ? _saveUndo() : Future<void>.value();
    _disposed = true;
    _undoSave?.cancel();
    _stopReopen();
    services.undo.removeListener(_onUndoChanged);
    if (_open[itemUuid.uuid] == this) _open.remove(itemUuid.uuid);
    services.currentItem.removeListener(_onCurrentItem);
    editor.removeListener(_onEditorChanged);
    unawaited(_localSub?.cancel());
    unawaited(_noticeSub?.cancel());
    unawaited(_syncSub?.cancel());
    unawaited(_outcomeSub?.cancel());
    _sync?.status.removeListener(_onStatus);
    final sync = _sync;
    final offline = _offline;
    final doc = _documentUuid;
    Future<void> closing = undoSaved;
    if (sync != null) {
      closing = Future.wait([undoSaved, sync.dispose()]);
    }
    if (offline != null && doc != null && _claimed) {
      closing = closing.whenComplete(() => offline.release(doc));
    }
    _closed.complete(closing.catchError((Object _) {}));
    presence.dispose();
    comments.dispose();
    suggestions.dispose();
    editor.dispose();
    _phase.dispose();
    _contentVersion.dispose();
    _status.dispose();
    _role.dispose();
    _meta.dispose();
    super.dispose();
  }
}

/// Connects the sync controller to the editor.
class _SessionHost implements SyncDocumentHost {
  _SessionHost(this.session);

  final WriteDocumentSession session;

  @override
  Delta get localDocument => session.editor.delta;

  @override
  void applyRemoteChange(Delta change, RemoteChangeInfo info) {
    // AI runs on behalf of this session land on its undo stack as one
    // step per run (Write 09 §5.2).
    final ownRun =
        info.origin == RemoteChangeOrigin.remote &&
        AiUndoGrouping.isOwnRun(
          onBehalfOf: info.onBehalfOfSessionId,
          groupId: info.groupId,
          sessionId: session._sync?.sessionId,
        );
    final before = ownRun ? session.editor.delta : null;
    session.editor.applyRemote(change);
    if (before != null) {
      session.aiUndo.record(change, before, info.groupId!);
      session._contentVersion.value++;
    } else {
      session._afterRemoteChange(change);
    }
  }

  @override
  void resetDocument(Delta document) {
    session.editor.resetDocument(document);
    session._contentVersion.value++;
  }
}

/// Undo/redo of `write.content` entries: submits the entry's delta as a new
/// local op and restores the entry's (rebased) selection.
class _WriteContentUndoHandler extends UndoHandler<WriteContentUndoEntry> {
  _WriteContentUndoHandler(this.session);

  final WriteDocumentSession session;

  @override
  String get domain => WriteContentUndoEntry.domainName;

  @override
  Future<WriteContentUndoEntry> undo(WriteContentUndoEntry entry) async =>
      _run(entry);

  @override
  Future<WriteContentUndoEntry> redo(WriteContentUndoEntry entry) async =>
      _run(entry);

  WriteContentUndoEntry _run(WriteContentUndoEntry entry) {
    if (!session.isLoaded || !session.currentRole.canComment) {
      throw const UndoConflict('The document is read-only');
    }
    final applied = session.editor.applyLocal(
      entry.change,
      label: writeL10nOf(session.services).commonUndo,
      source: LocalChangeSource.undo,
      selectionAfter: entry.select,
    );
    if (applied == null) throw const UndoConflict('Nothing to undo');
    session._selectionRestoredByUndo = true;
    return WriteContentUndoEntry(
      change: applied.inverse,
      select: entry.counterSelect,
      counterSelect: entry.select,
    );
  }
}
