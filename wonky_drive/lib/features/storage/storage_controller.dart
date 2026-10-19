import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import 'storage_api.dart';

/// What the Storage page's table lists (Drive 03 §6.4): the type filter
/// (*All*, *Documents* … *Trash*) or one of the *Free up space* cards.
enum StorageFilter {
  all,
  documents,
  spreadsheets,
  presentations,
  files,
  trash,

  /// *Large files*: items of at least [StorageFilter.largeBytes].
  large,

  /// *Not opened in 6 months*: items of at least
  /// [StorageFilter.notOpenedMinBytes] not opened for
  /// [StorageFilter.notOpenedDays] days (or never, unless created since).
  notOpened;

  /// 1 MB (Drive 03 §6.4).
  static const largeBytes = 1024 * 1024;

  /// 256 KB.
  static const notOpenedMinBytes = 256 * 1024;
  static const notOpenedDays = 180;

  /// The filters of the *Type* menu.
  static const typeFilters = [
    all,
    documents,
    spreadsheets,
    presentations,
    files,
    trash,
  ];

  /// A filter of a *Free up space* card (shown as a removable chip).
  bool get isSuggestion => this == large || this == notOpened;

  /// The filter named [name] (`/storage?filter=large`); [all] otherwise.
  static StorageFilter parse(String? name) => values.asNameMap()[name] ?? all;

  /// The server filter of `drive.listByStorage`.
  StorageListFilter listFilter(DateTime now) => switch (this) {
    all => StorageListFilter(),
    documents => StorageListFilter(kinds: const [DriveItemKind.document]),
    spreadsheets => StorageListFilter(kinds: const [DriveItemKind.spreadsheet]),
    presentations => StorageListFilter(
      kinds: const [DriveItemKind.presentation],
    ),
    files => StorageListFilter(kinds: const [DriveItemKind.file]),
    trash => StorageListFilter(trashedOnly: true),
    large => StorageListFilter(minCountedBytes: largeBytes),
    notOpened => StorageListFilter(
      minCountedBytes: notOpenedMinBytes,
      notOpenedSince: notOpenedCutoff(now),
    ),
  };

  static DateTime notOpenedCutoff(DateTime now) =>
      now.subtract(const Duration(days: notOpenedDays));

  /// Rows of a server page this filter keeps: *Not opened* skips items
  /// created after the cutoff (a file uploaded yesterday and never opened
  /// is not a clean-up candidate).
  List<DriveItemView> keep(List<DriveItemView> items, DateTime now) {
    if (this != notOpened) return items;
    final cutoff = notOpenedCutoff(now);
    return [
      for (final i in items)
        if (i.createdAt.isBefore(cutoff)) i,
    ];
  }
}

/// The Storage page route, with a filter (`/storage?filter=large`).
String storagePath([StorageFilter filter = StorageFilter.all]) =>
    filter == StorageFilter.all ? '/storage' : '/storage?filter=${filter.name}';

/// The count and size of a *Free up space* card ([more]: the count is a
/// lower bound).
@immutable
class StorageSuggestion {
  const StorageSuggestion(this.count, this.bytes, {this.more = false});

  final int count;
  final int bytes;
  final bool more;
}

/// State of the Storage page (Drive 03 §6.4): the items by counted size
/// (paged, keyset cursor), the filter, the *Free up space* counts, folder
/// names for the *Location* column and the multi-selection, which is
/// published as `ShellServices.driveSelection` so the shell's drive
/// commands (trash, delete forever, rename, star …) and their keys act on
/// it. Reloads (debounced) on drive changes and `storageChanged` events.
class StoragePageController extends ChangeNotifier {
  StoragePageController({
    required this.services,
    this._filter = StorageFilter.all,
    this.pageSize = 50,
    this.debounce = const Duration(milliseconds: 300),
    DateTime Function()? now,
  }) : _now = now ?? StorageHost.of(services).now {
    _sub = services.driveChanges.listen(_onDriveChange);
    services.driveRefresh.addListener(_onRefresh);
    services.storage.addListener(_onStorage);
    _usage = services.storage.value;
    services.driveSelectAll = selectAll;
    StorageHost.of(services).page.value = this;
  }

  final ShellServices services;
  final int pageSize;
  final Duration debounce;
  final DateTime Function() _now;

  /// Rows the live refresh keeps loaded at most (one request).
  static const maxRefreshRows = 200;

  /// Rows counted for a suggestion card.
  static const suggestionLimit = 200;

  StorageApi get api => StorageHost.of(services).api;

  StorageFilter _filter;
  List<DriveItemView> _items = const [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _generation = 0;
  StorageSuggestion? _large;
  StorageSuggestion? _notOpened;
  final Map<String, String?> _folderNames = {};
  final Set<String> _selected = {};
  String? _anchor;
  String? _focused;
  StorageUsage? _usage;
  StreamSubscription<DriveChange>? _sub;
  Timer? _reloadTimer;
  bool _disposed = false;

  StorageFilter get filter => _filter;
  List<DriveItemView> get items => _items;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _cursor != null;
  Object? get error => _error;
  String? get focusedId => _focused;

  /// *Large files* (null until counted or when counting failed).
  StorageSuggestion? get large => _large;

  /// *Not opened in 6 months*.
  StorageSuggestion? get notOpened => _notOpened;

  List<DriveItemView> get selection => [
    for (final i in _items)
      if (_selected.contains(i.uuid.uuid)) i,
  ];

  bool isSelected(DriveItemView i) => _selected.contains(i.uuid.uuid);

  /// Counted bytes of the selection.
  int get selectedBytes => selection.fold(0, (sum, i) => sum + i.countedBytes);

  /// The name of folder [uuid] for the *Location* column: null while it
  /// loads, '' when it can't be read.
  String? folderName(UuidValue uuid) => _folderNames[uuid.uuid];

  // ---- Loading ----

  /// Loads the first page of the filter (and the suggestion counts).
  /// [keepLoaded] reloads as many rows as are shown (live refresh).
  Future<void> reload({bool keepLoaded = false}) async {
    _reloadTimer?.cancel();
    final gen = ++_generation;
    _loading = true;
    _error = null;
    _notify();
    final now = _now();
    final limit = keepLoaded
        ? _items.length.clamp(pageSize, maxRefreshRows)
        : pageSize;
    unawaited(_loadSuggestions(gen, now));
    try {
      final page = await api.listByStorage(
        _filter.listFilter(now),
        limit: limit,
      );
      if (gen != _generation) return;
      _items = _filter.keep(page.items, now);
      _cursor = page.nextCursor;
      _selected.removeWhere((id) => !_items.any((i) => i.uuid.uuid == id));
      _publishSelection();
      _resolveFolders();
    } catch (e) {
      if (gen != _generation) return;
      _error = e;
      _items = const [];
      _cursor = null;
      _selected.clear();
      _publishSelection();
    } finally {
      if (gen == _generation) {
        _loading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore || _loading) return;
    _loadingMore = true;
    _notify();
    final gen = _generation;
    final now = _now();
    try {
      final page = await api.listByStorage(
        _filter.listFilter(now),
        cursor: cursor,
        limit: pageSize,
      );
      if (gen != _generation) return;
      _items = [..._items, ..._filter.keep(page.items, now)];
      _cursor = page.nextCursor;
      _resolveFolders();
    } catch (_) {
      // Keep what we have; the next scroll retries.
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  Future<void> _loadSuggestions(int gen, DateTime now) async {
    Future<StorageSuggestion?> count(StorageFilter f) async {
      try {
        final page = await api.listByStorage(
          f.listFilter(now),
          limit: suggestionLimit,
        );
        final kept = f.keep(page.items, now);
        return StorageSuggestion(
          kept.length,
          kept.fold(0, (sum, i) => sum + i.countedBytes),
          more: page.nextCursor != null,
        );
      } catch (_) {
        return null;
      }
    }

    final r = await Future.wait([
      count(StorageFilter.large),
      count(StorageFilter.notOpened),
    ]);
    if (gen != _generation || _disposed) return;
    _large = r[0];
    _notOpened = r[1];
    _notify();
  }

  /// Names of the parent folders of the listed rows (Location column).
  void _resolveFolders() {
    final missing = <UuidValue>{
      for (final i in _items)
        if (i.parentUuid != null &&
            !i.isTrashed &&
            !_folderNames.containsKey(i.parentUuid!.uuid))
          i.parentUuid!,
    };
    if (missing.isEmpty) return;
    for (final p in missing) {
      _folderNames[p.uuid] = null;
    }
    unawaited(_lookUpFolders(missing.toList()));
  }

  /// Looks up [parents] as one batch (DR-4): at most [folderLookups] at a
  /// time, one rebuild when all are known. A failed lookup is not cached
  /// (the next page load retries it).
  Future<void> _lookUpFolders(List<UuidValue> parents) async {
    for (var i = 0; i < parents.length; i += folderLookups) {
      final chunk = parents.skip(i).take(folderLookups);
      await Future.wait([
        for (final p in chunk)
          services.drive
              .get(p)
              .then<void>(
                (f) => _folderNames[p.uuid] = f.name,
                onError: (Object _) => _folderNames.remove(p.uuid),
              ),
      ]);
      if (_disposed) return;
    }
    _notify();
  }

  /// Parallel folder lookups of the Location column.
  static const folderLookups = 8;

  void setFilter(StorageFilter f) {
    if (f == _filter) return;
    _filter = f;
    _items = const [];
    _cursor = null;
    _selected.clear();
    _anchor = null;
    _focused = null;
    _publishSelection();
    unawaited(reload());
  }

  // ---- Live updates ----

  void _scheduleReload() {
    if (_disposed) return;
    _reloadTimer?.cancel();
    _reloadTimer = Timer(debounce, () => reload(keepLoaded: true));
  }

  void _onRefresh() => _scheduleReload();

  void _onDriveChange(DriveChange c) {
    switch (c.kind) {
      case DriveChangeKind.storageChanged:
        // The StorageController follows it; [_onStorage] reloads.
        break;
      case DriveChangeKind.trashed:
      case DriveChangeKind.restored:
      case DriveChangeKind.removed:
      case DriveChangeKind.created:
      case DriveChangeKind.moved:
      case DriveChangeKind.updated:
      case DriveChangeKind.modified:
      case DriveChangeKind.shared:
      case DriveChangeKind.unshared:
        _scheduleReload();
    }
  }

  void _onStorage() {
    final u = services.storage.value;
    final before = _usage;
    _usage = u;
    if (u == null || before == null) return;
    if (u.bytesUsed != before.bytesUsed ||
        u.trashBytes != before.trashBytes ||
        u.documentsBytes != before.documentsBytes ||
        u.spreadsheetsBytes != before.spreadsheetsBytes ||
        u.presentationsBytes != before.presentationsBytes ||
        u.filesBytes != before.filesBytes) {
      _scheduleReload();
    }
  }

  // ---- Selection ----

  /// Click: select one; [toggle] (Mod-click, checkbox): add/remove;
  /// [range] (Shift-click): from the anchor.
  void select(DriveItemView item, {bool toggle = false, bool range = false}) {
    final id = item.uuid.uuid;
    final anchor = _anchor;
    if (range && anchor != null) {
      final a = _items.indexWhere((x) => x.uuid.uuid == anchor);
      final b = _items.indexWhere((x) => x.uuid.uuid == id);
      if (a >= 0 && b >= 0) {
        if (!toggle) _selected.clear();
        final (lo, hi) = a < b ? (a, b) : (b, a);
        for (var k = lo; k <= hi; k++) {
          _selected.add(_items[k].uuid.uuid);
        }
      }
    } else if (toggle) {
      if (!_selected.remove(id)) _selected.add(id);
      _anchor = id;
    } else {
      _selected
        ..clear()
        ..add(id);
      _anchor = id;
    }
    _focused = id;
    _publishSelection();
    _notify();
  }

  void selectAll() {
    _selected
      ..clear()
      ..addAll(_items.map((i) => i.uuid.uuid));
    _publishSelection();
    _notify();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _publishSelection();
    _notify();
  }

  /// Replaces the selection with the listed items of [uuids] (MCP
  /// `ui.drive.select_items`); returns the ids that are not listed.
  List<String> selectIds(List<String> uuids) {
    final listed = {for (final i in _items) i.uuid.uuid};
    final found = [
      for (final u in uuids)
        if (listed.contains(u)) u,
    ];
    _selected
      ..clear()
      ..addAll(found);
    if (found.isNotEmpty) {
      _focused = found.first;
      _anchor = found.first;
    }
    _publishSelection();
    _notify();
    return [
      for (final u in uuids)
        if (!listed.contains(u)) u,
    ];
  }

  /// Arrow keys: moves the focused row (and selects it; [extend] keeps the
  /// range from the anchor).
  void moveFocus(int delta, {bool extend = false}) {
    if (_items.isEmpty) return;
    var i = _items.indexWhere((x) => x.uuid.uuid == _focused);
    i = (i < 0 ? (delta > 0 ? 0 : _items.length - 1) : i + delta).clamp(
      0,
      _items.length - 1,
    );
    select(_items[i], range: extend);
  }

  void _publishSelection() => services.driveSelection.value = selection;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reloadTimer?.cancel();
    unawaited(_sub?.cancel());
    services.driveRefresh.removeListener(_onRefresh);
    services.storage.removeListener(_onStorage);
    if (services.driveSelectAll == selectAll) services.driveSelectAll = null;
    final host = StorageHost.of(services);
    if (host.page.value == this) host.page.value = null;
    services.driveSelection.value = const [];
    super.dispose();
  }
}

/// Per-shell collaborators of the Storage page: the server API (replaced in
/// tests) and the shown page (`ui.drive.*`).
class StorageHost {
  StorageHost._(this.services);

  static final Expando<StorageHost> _hosts = Expando('StorageHost');

  /// The host of [services] (created on first use).
  static StorageHost of(ShellServices services) =>
      _hosts[services] ??= StorageHost._(services);

  final ShellServices services;

  StorageApi? _api;

  /// Server access ([ServerStorageApi] unless replaced).
  StorageApi get api => _api ??= ServerStorageApi(services);
  set api(StorageApi v) => _api = v;

  /// The controller of the shown Storage page, if any.
  final ValueNotifier<StoragePageController?> page = ValueNotifier(null);

  /// The clock of the *Not opened in 6 months* cutoff (fixed in tests).
  DateTime Function() now = DateTime.now;
}
