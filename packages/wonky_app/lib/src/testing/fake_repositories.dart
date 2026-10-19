import 'dart:convert';
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../board/board_repository.dart';
import '../auth/auth_repository.dart';
import '../data/collab_repositories.dart';
import '../data/drive_repository.dart';
import '../data/file_repository.dart';
import '../data/sharing_repository.dart';
import '../data/user_repository.dart';

/// Thrown by the fakes for unknown items (the server throws a not-found
/// exception).
class FakeNotFound implements Exception {
  const FakeNotFound(this.what);

  final String what;

  @override
  String toString() => 'Not found: $what';
}

/// Builds [UserSummary]s for tests.
abstract final class TestUsers {
  static UserSummary summary({
    int id = 1,
    String displayName = 'Anna Berg',
    String? email,
  }) => UserSummary(
    id: id,
    uuid: UuidValue.fromString(
      '00000000-0000-4000-8000-${id.toRadixString(16).padLeft(12, '0')}',
    ),
    displayName: displayName,
    email: email ?? 'user$id@example.test',
    avatarColor: '#6366f1',
    colorIndex: presenceColorIndex('$id'),
  );

  static final anna = summary(
    id: 1,
    displayName: 'Anna Berg',
    email: 'anna@example.test',
  );
  static final bob = summary(
    id: 2,
    displayName: 'Bob Stone',
    email: 'bob@example.test',
  );
}

/// In-memory [DriveRepository] with the server's semantics for the
/// operations the shell uses (folders, documents, rename, move, star, pin,
/// trash, restore, delete forever, search, virtual views). Mutations emit
/// [DriveChange]s on [watch] and are recorded in [calls].
class FakeDriveRepository implements DriveRepository {
  FakeDriveRepository({UserSummary? me, UuidV7Generator? ids, this.templates})
    : me = me ?? TestUsers.anna,
      _ids = ids ?? UuidV7Generator.instance;

  final UserSummary me;
  final UuidV7Generator _ids;

  /// Returned by [listTemplates] (filtered by kind).
  List<TemplateView>? templates;

  final Map<UuidValue, DriveItemView> _items = {};
  final _changes = StreamController<DriveChange>.broadcast();

  /// Names of the mutating calls, in order (`rename`, `move` …).
  final List<String> calls = [];

  /// All items, including trashed ones.
  Iterable<DriveItemView> get items => _items.values;

  /// The current view of [uuid] (throws [FakeNotFound]).
  DriveItemView item(UuidValue uuid) =>
      _items[uuid] ?? (throw FakeNotFound('item $uuid'));

  /// Adds an item directly (seeding); returns it.
  DriveItemView seed({
    required String name,
    DriveItemKind kind = DriveItemKind.document,
    UuidValue? parentUuid,
    UserSummary? owner,
    AccessRole role = AccessRole.owner,
    bool starred = false,
    DateTime? trashedAt,
    UuidValue? uuid,
    FileCategory? fileCategory,
    int countedBytes = 0,
    bool nonEditorsCanExport = true,
    UuidValue? contentRef,
  }) {
    final now = clock.now();
    final v = DriveItemView(
      contentRef: contentRef,
      countedBytes: countedBytes,
      fileCategory:
          fileCategory ??
          (kind == DriveItemKind.file ? FileCategory.other : null),
      uuid: uuid ?? _ids.next(),
      kind: kind,
      name: name,
      parentUuid: parentUuid,
      owner: owner ?? me,
      role: role,
      shared: owner != null && owner.id != me.id,
      sizeBytes: 0,
      createdAt: now,
      modifiedAt: now,
      trashedAt: trashedAt,
      starred: starred,
      pinnedOffline: false,
      editorsCanShare: true,
      nonEditorsCanExport: nonEditorsCanExport,
      viewersSeeComments: true,
    );
    _items[v.uuid] = v;
    return v;
  }

  DriveItemView _put(DriveItemView v, DriveChangeKind kind, String call) {
    _items[v.uuid] = v;
    calls.add(call);
    _changes.add(DriveChange(kind: kind, itemUuid: v.uuid, item: v));
    return v;
  }

  Iterable<DriveItemView> _descendants(UuidValue uuid) sync* {
    for (final c in _items.values.where((i) => i.parentUuid == uuid).toList()) {
      yield c;
      yield* _descendants(c.uuid);
    }
  }

  bool _isTrashed(DriveItemView v) {
    if (v.trashedAt != null) return true;
    final p = v.parentUuid == null ? null : _items[v.parentUuid];
    return p != null && _isTrashed(p);
  }

  List<DriveItemView> _sorted(Iterable<DriveItemView> items, DriveSort sort) {
    int cmp(DriveItemView a, DriveItemView b) {
      if (sort.foldersFirst) {
        final fa = a.kind == DriveItemKind.folder ? 0 : 1;
        final fb = b.kind == DriveItemKind.folder ? 0 : 1;
        if (fa != fb) return fa - fb;
      }
      final r = switch (sort.field) {
        DriveSortField.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        DriveSortField.size => a.sizeBytes.compareTo(b.sizeBytes),
        DriveSortField.createdAt => a.createdAt.compareTo(b.createdAt),
        DriveSortField.lastOpenedByMe =>
          (a.lastOpenedAt ?? DateTime(0)).compareTo(
            b.lastOpenedAt ?? DateTime(0),
          ),
        DriveSortField.lastModifiedByMe ||
        DriveSortField.modifiedAt => a.modifiedAt.compareTo(b.modifiedAt),
      };
      return sort.descending ? -r : r;
    }

    return items.toList()..sort(cmp);
  }

  @override
  Future<DriveListPage> list({
    UuidValue? folderUuid,
    required DriveListFilter filter,
    required DriveSort sort,
    String? cursor,
    int limit = 100,
  }) async {
    Iterable<DriveItemView> out = _items.values;
    out = switch (filter.view) {
      DriveView.folder => out.where(
        (i) =>
            i.parentUuid == folderUuid && !_isTrashed(i) && i.owner.id == me.id,
      ),
      DriveView.sharedWithMe => out.where(
        (i) => i.owner.id != me.id && !_isTrashed(i),
      ),
      DriveView.starred => out.where((i) => i.starred && !_isTrashed(i)),
      DriveView.recent => out.where(
        (i) => i.lastOpenedAt != null && !_isTrashed(i),
      ),
      DriveView.trash => out.where((i) => i.trashedAt != null),
      DriveView.offline => out.where((i) => i.pinnedOffline && !_isTrashed(i)),
    };
    final kinds = filter.kinds;
    if (kinds != null) out = out.where((i) => kinds.contains(i.kind));
    final cats = filter.fileCategories;
    if (cats != null) out = out.where((i) => cats.contains(i.fileCategory));
    // The server's `kindMask` rule (suite 05 §3.2), computed here.
    final containing = filter.foldersContaining;
    if (containing != null) {
      out = out.where(
        (i) =>
            i.kind != DriveItemKind.folder || containsKind(i.uuid, containing),
      );
    }
    out = switch (filter.owner) {
      DriveOwnerFilter.anyone => out,
      DriveOwnerFilter.me => out.where((i) => i.owner.id == me.id),
      DriveOwnerFilter.notMe => out.where((i) => i.owner.id != me.id),
    };
    final all = _sorted(out, sort);
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, all.length);
    return DriveListPage(
      items: all.sublist(start, end),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  /// Whether folder [folder] contains — recursively, ignoring trashed
  /// items — an item of [kind] (the server's `DriveItem.kindMask`).
  bool containsKind(UuidValue folder, DriveItemKind kind) {
    for (final i in _items.values) {
      if (i.parentUuid != folder || _isTrashed(i)) continue;
      if (i.kind == kind) return true;
      if (i.kind == DriveItemKind.folder && containsKind(i.uuid, kind)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<DriveItemView> get(UuidValue uuid) async => item(uuid);

  @override
  Future<List<DriveItemView>> path(UuidValue uuid) async {
    final out = <DriveItemView>[];
    var p = item(uuid).parentUuid;
    while (p != null) {
      final v = item(p);
      out.insert(0, v);
      p = v.parentUuid;
    }
    return out;
  }

  @override
  Future<DriveListPage> search(
    String query, {
    required DriveSearchFilters filters,
    String? cursor,
    int limit = 50,
  }) async {
    final q = query.toLowerCase();
    final kinds = filters.kinds;
    final hits = _items.values.where(
      (i) =>
          !_isTrashed(i) &&
          i.name.toLowerCase().contains(q) &&
          (kinds == null || kinds.contains(i.kind)),
    );
    return DriveListPage(
      items: _sorted(hits, DriveSort()).take(limit).toList(),
    );
  }

  DriveItemView _create(String name, DriveItemKind kind, UuidValue? parent) {
    if (parent != null) item(parent);
    return seed(name: name, kind: kind, parentUuid: parent);
  }

  @override
  Future<DriveItemView> createFolder({
    UuidValue? parentUuid,
    required String name,
  }) async => _put(
    _create(name, DriveItemKind.folder, parentUuid),
    DriveChangeKind.created,
    'createFolder',
  );

  @override
  Future<DriveItemView> createDocument({
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
    String? initialMarkdown,
    UuidValue? documentUuid,
    UuidValue? itemUuid,
  }) async {
    final v = _create(
      name,
      DriveItemKind.document,
      parentUuid,
    ).copyWith(uuid: itemUuid, contentRef: documentUuid ?? _ids.next());
    return _put(v, DriveChangeKind.created, 'createDocument');
  }

  @override
  Future<DriveItemView> createSpreadsheet({
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
  }) async => _put(
    _create(
      name,
      DriveItemKind.spreadsheet,
      parentUuid,
    ).copyWith(contentRef: _ids.next()),
    DriveChangeKind.created,
    'createSpreadsheet',
  );

  @override
  Future<DriveItemView> registerSpreadsheet({
    required UuidValue spaceUuid,
    UuidValue? parentUuid,
    required String name,
  }) async => _put(
    _create(
      name,
      DriveItemKind.spreadsheet,
      parentUuid,
    ).copyWith(contentRef: spaceUuid),
    DriveChangeKind.created,
    'registerSpreadsheet',
  );

  @override
  Future<DriveItemView> createPresentation({
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
  }) async {
    final v = _create(name, DriveItemKind.presentation, parentUuid);
    return _put(
      v.copyWith(contentRef: v.uuid),
      DriveChangeKind.created,
      'createPresentation',
    );
  }

  /// The item uuid is the space uuid (Slides 02 §9.3); idempotent.
  @override
  Future<DriveItemView> registerPresentation({
    required UuidValue spaceUuid,
    UuidValue? parentUuid,
    required String name,
  }) async {
    final known = _items[spaceUuid];
    if (known != null) return known;
    return _put(
      _create(
        name,
        DriveItemKind.presentation,
        parentUuid,
      ).copyWith(uuid: spaceUuid, contentRef: spaceUuid),
      DriveChangeKind.created,
      'registerPresentation',
    );
  }

  DriveItemView _touch(DriveItemView v) =>
      v.copyWith(modifiedAt: clock.now(), modifiedBy: me);

  @override
  Future<DriveItemView> rename(UuidValue uuid, String name) async =>
      _put(_touch(item(uuid)).copyWith(name: name), .updated, 'rename');

  @override
  Future<DriveItemView> updateDescription(
    UuidValue uuid,
    String? description,
  ) async {
    final v = _touch(item(uuid));
    return _put(
      DriveItemView.fromJson({...v.toJson(), 'description': description}),
      DriveChangeKind.updated,
      'updateDescription',
    );
  }

  @override
  Future<List<DriveItemView>> move(
    List<UuidValue> uuids,
    UuidValue? newParentUuid,
  ) async {
    if (newParentUuid != null) {
      final target = item(newParentUuid);
      for (final u in uuids) {
        if (u == newParentUuid || _descendants(u).contains(target)) {
          throw ArgumentError('Cannot move a folder into itself');
        }
      }
    }
    return [
      for (final u in uuids)
        _put(
          DriveItemView.fromJson({
            ...item(u).toJson(),
            'parentUuid': newParentUuid?.toJson(),
          }),
          DriveChangeKind.moved,
          'move',
        ),
    ];
  }

  @override
  Future<DriveItemView> copy(
    UuidValue uuid, {
    required String newName,
    UuidValue? parentUuid,
    bool copyComments = false,
    bool copySharing = false,
  }) async {
    final src = item(uuid);
    return _put(
      _create(newName, src.kind, parentUuid ?? src.parentUuid),
      DriveChangeKind.created,
      'copy',
    );
  }

  @override
  Future<DriveItemView> setStarred(UuidValue uuid, bool starred) async =>
      _put(item(uuid).copyWith(starred: starred), .updated, 'setStarred');

  @override
  Future<DriveItemView> setPinnedOffline(UuidValue uuid, bool pinned) async =>
      _put(
        item(uuid).copyWith(pinnedOffline: pinned),
        DriveChangeKind.updated,
        'setPinnedOffline',
      );

  @override
  Future<DriveItemView> markOpened(UuidValue uuid) async {
    final v = item(uuid).copyWith(lastOpenedAt: clock.now());
    _items[uuid] = v;
    return v;
  }

  @override
  Future<DriveItemView> addShortcut(UuidValue uuid, UuidValue? parentUuid) =>
      throw UnsupportedError('FakeDriveRepository does not fake shortcuts');

  @override
  Future<void> removeShortcut(UuidValue uuid) =>
      throw UnsupportedError('FakeDriveRepository does not fake shortcuts');

  @override
  Future<void> trash(List<UuidValue> uuids) async {
    for (final u in uuids) {
      _put(item(u).copyWith(trashedAt: clock.now()), .trashed, 'trash');
    }
  }

  @override
  Future<void> restore(List<UuidValue> uuids) async {
    for (final u in uuids) {
      _put(
        DriveItemView.fromJson({...item(u).toJson(), 'trashedAt': null}),
        DriveChangeKind.restored,
        'restore',
      );
    }
  }

  @override
  Future<void> deletePermanently(List<UuidValue> uuids) async {
    for (final u in uuids) {
      item(u);
      for (final d in _descendants(u).toList()) {
        _items.remove(d.uuid);
      }
      _items.remove(u);
      calls.add('deletePermanently');
      _changes.add(DriveChange(kind: DriveChangeKind.removed, itemUuid: u));
    }
  }

  @override
  Future<int> emptyTrash() async {
    final trashed = [
      for (final i in _items.values)
        if (i.trashedAt != null && i.owner.id == me.id) i.uuid,
    ];
    await deletePermanently(trashed);
    calls.add('emptyTrash');
    return trashed.length;
  }

  @override
  Future<List<TemplateView>> listTemplates(DriveItemKind? kind) async => [
    for (final t in templates ?? const <TemplateView>[])
      if (kind == null || t.kind == kind) t,
  ];

  @override
  Future<StorageUsage> storageUsage() async {
    int count(DriveItemKind k) =>
        _items.values.where((i) => i.kind == k).length;
    return StorageUsage(
      bytesUsed: _items.values.fold(0, (s, i) => s + i.sizeBytes),
      documents: count(DriveItemKind.document),
      spreadsheets: count(DriveItemKind.spreadsheet),
      folders: count(DriveItemKind.folder),
      files: 0,
    );
  }

  @override
  Future<List<ActivityEventView>> activity(
    UuidValue uuid, {
    int? beforeId,
    int limit = 50,
  }) async {
    final events = activityByItem[uuid.uuid] ?? const <ActivityEventView>[];
    return [
      for (final e in events)
        if (beforeId == null || e.id < beforeId) e,
    ].take(limit).toList();
  }

  /// Activity events per item uuid, newest first (for [activity]).
  final activityByItem = <String, List<ActivityEventView>>{};

  @override
  Stream<DriveChange> watch() => _changes.stream;

  Future<void> dispose() => _changes.close();
}

/// In-memory [UserRepository]: profile, preferences (patches merge like the
/// server's) and user search over [directory].
class FakeUserRepository implements UserRepository {
  FakeUserRepository({UserSummary? me, List<UserSummary>? directory})
    : _me = me ?? TestUsers.anna,
      directory = directory ?? [TestUsers.anna, TestUsers.bob];

  UserSummary _me;
  final List<UserSummary> directory;
  String? _locale;
  String? _timeZone;
  late UserPreferences _prefs = UserPreferences(
    userId: _me.id,
    keymapOverrides: '{}',
    writeDefaults: '{}',
    sheetsDefaults: '{}',
    notificationSettings: '{}',
  );

  /// Preference patches received, in order.
  final List<UserPreferencesPatch> patches = [];

  UserProfileView get profile => UserProfileView(
    summary: _me,
    locale: _locale,
    timeZone: _timeZone,
    createdAt: DateTime.utc(2026),
  );

  @override
  Future<UserProfileView> getMe() async {
    getMeCalls++;
    final gate = getMeGate;
    if (gate != null) await gate.future;
    return profile;
  }

  /// Calls of [getMe].
  int getMeCalls = 0;

  /// When set, [getMe] waits for it (a slow network).
  Completer<void>? getMeGate;

  /// The profile [cachedMe] returns (a device that was signed in before).
  UserProfileView? cachedProfile;

  @override
  Future<UserProfileView?> cachedMe() async => cachedProfile;

  @override
  Future<UserProfileView> updateProfile({
    String? displayName,
    String? locale,
    String? timeZone,
  }) async {
    if (displayName != null) _me = _me.copyWith(displayName: displayName);
    _locale = locale ?? _locale;
    _timeZone = timeZone ?? _timeZone;
    return profile;
  }

  @override
  Future<UserProfileView> setAvatar(UuidValue? fileUuid) async => profile;

  @override
  Future<UserPreferences> getPreferences() async => _prefs;

  @override
  Future<UserPreferences> updatePreferences(UserPreferencesPatch patch) async {
    patches.add(patch);
    final p = _prefs;
    _prefs = p.copyWith(
      appTheme: patch.appTheme ?? p.appTheme,
      density: patch.density ?? p.density,
      reduceMotion: patch.reduceMotion ?? p.reduceMotion,
      keymapOverrides: patch.keymapOverrides ?? p.keymapOverrides,
      writeDefaults: patch.writeDefaults ?? p.writeDefaults,
      sheetsDefaults: patch.sheetsDefaults ?? p.sheetsDefaults,
      notificationSettings:
          patch.notificationSettings ?? p.notificationSettings,
      aiEnabled: patch.aiEnabled ?? p.aiEnabled,
      // (v2) Merged key by key like the server (null removes a key).
      driveDefaults: _mergeJson(p.driveDefaults, patch.driveDefaults),
    );
    if (patch.clearAccentColor == true) {
      _prefs = UserPreferences.fromJson({
        ..._prefs.toJson(),
        'accentColor': null,
      });
    } else if (patch.accentColor != null) {
      _prefs = _prefs.copyWith(accentColor: patch.accentColor);
    }
    return _prefs;
  }

  static String _mergeJson(String current, String? patch) {
    if (patch == null) return current;
    Map<String, Object?> decode(String json) {
      try {
        final v = jsonDecode(json);
        return v is Map ? v.cast<String, Object?>() : {};
      } catch (_) {
        return {};
      }
    }

    return jsonEncode(
      {...decode(current), ...decode(patch)}..removeWhere((_, v) => v == null),
    );
  }

  @override
  Future<List<UserSummary>> searchUsers(String query, {int limit = 10}) async {
    final q = query.toLowerCase();
    return [
      for (final u in directory)
        if (u.displayName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
          u,
    ].take(limit).toList();
  }

  @override
  Future<AccountDeletionPreview> deleteAccountPreview() =>
      throw UnsupportedError('FakeUserRepository.deleteAccountPreview');

  @override
  Future<void> deleteAccount(String confirmation) =>
      throw UnsupportedError('FakeUserRepository.deleteAccount');

  @override
  Future<List<AccessTokenView>> listTokens() async => const [];

  @override
  Future<CreatedAccessToken> createToken({
    required String name,
    required List<String> scopes,
    DateTime? expiresAt,
  }) => throw UnsupportedError('FakeUserRepository.createToken');

  @override
  Future<void> revokeToken(int id) async {}
}

/// In-memory [AuthRepository]: accounts in [accounts] (email → password),
/// verification codes readable from [lastCode].
class FakeAuthRepository extends ChangeNotifier implements AuthRepository {
  FakeAuthRepository({this._signedIn = true, Map<String, String>? accounts})
    : accounts = accounts ?? {'anna@example.test': 'Correct-Horse-42!'};

  final Map<String, String> accounts;
  bool _signedIn;
  final _requests = <UuidValue, String>{};
  final _tokens = <String, String>{};

  /// The last verification / reset code "emailed".
  String? lastCode;

  @override
  bool get isSignedIn => _signedIn;

  @override
  UuidValue? get authUserId => _signedIn ? TestUsers.anna.uuid : null;

  void _setSignedIn(bool v) {
    _signedIn = v;
    notifyListeners();
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (accounts[email.toLowerCase()] != password) {
      throw StateError('Invalid email or password');
    }
    _setSignedIn(true);
  }

  /// Whether the fake offers Google sign-in, and what the popup does:
  /// true signs in, false is a closed popup, null means not configured.
  @override
  bool offersGoogleSignIn = false;
  bool? googleOutcome = true;

  @override
  Future<bool> signInWithGoogle() async {
    final outcome = googleOutcome;
    if (outcome == null) throw const GoogleSignInUnavailableException();
    if (outcome) _setSignedIn(true);
    return outcome;
  }

  UuidValue _request(String email) {
    final id = UuidV7Generator.instance.next();
    _requests[id] = email.toLowerCase();
    lastCode = '12345678';
    return id;
  }

  String _verify(UuidValue requestId, String code) {
    final email = _requests[requestId];
    if (email == null || code != lastCode) throw StateError('Invalid code');
    final token = 'token-${_tokens.length}';
    _tokens[token] = email;
    return token;
  }

  @override
  Future<UuidValue> startRegistration(String email) async => _request(email);

  @override
  Future<String> verifyRegistrationCode(
    UuidValue requestId,
    String code,
  ) async => _verify(requestId, code);

  @override
  Future<void> finishRegistration(
    String registrationToken,
    String password,
  ) async {
    final email = _tokens.remove(registrationToken);
    if (email == null) throw StateError('Invalid token');
    accounts[email] = password;
    _setSignedIn(true);
  }

  @override
  Future<UuidValue> startPasswordReset(String email) async => _request(email);

  @override
  Future<String> verifyPasswordResetCode(
    UuidValue requestId,
    String code,
  ) async => _verify(requestId, code);

  @override
  Future<void> finishPasswordReset({
    required String token,
    required String newPassword,
    required String email,
  }) async {
    if (_tokens.remove(token) == null) throw StateError('Invalid token');
    accounts[email.toLowerCase()] = newPassword;
    _setSignedIn(true);
  }

  @override
  Future<void> signOut({bool allDevices = false}) async => _setSignedIn(false);
}

/// In-memory [NotificationRepository]: [items] newest first, cursor paging
/// by id, read state, and [emit] to push a live event.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({List<NotificationView>? items})
    : items = [...?items];

  final List<NotificationView> items;
  final _events = StreamController<NotificationEvent>.broadcast();
  int listCalls = 0;

  int get unreadCount => items.where((n) => n.readAt == null).length;

  @override
  Future<NotificationPage> list({
    String? cursor,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    listCalls++;
    final before = int.tryParse(cursor ?? '');
    final matching = [
      for (final n in items)
        if ((!unreadOnly || n.readAt == null) &&
            (before == null || n.id < before))
          n,
    ];
    final page = matching.take(limit).toList();
    return NotificationPage(
      items: page,
      nextCursor: matching.length > limit ? '${page.last.id}' : null,
      unreadCount: unreadCount,
    );
  }

  @override
  Future<void> markRead(List<int> ids) async {
    for (var i = 0; i < items.length; i++) {
      if (ids.contains(items[i].id) && items[i].readAt == null) {
        items[i] = items[i].copyWith(readAt: clock.now());
      }
    }
  }

  @override
  Future<void> markAllRead() => markRead([for (final n in items) n.id]);

  /// Adds [n] (newest) and pushes it to [watch] listeners.
  void emit(NotificationView n) {
    items.insert(0, n);
    _events.add(NotificationEvent(notification: n, unreadCount: unreadCount));
  }

  @override
  Stream<NotificationEvent> watch() => _events.stream;
}

/// In-memory [ActivityRepository] returning [dashboards] by item uuid.
class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({Map<String, ActivityDashboard>? dashboards})
    : dashboards = {...?dashboards};

  final Map<String, ActivityDashboard> dashboards;
  bool viewHistory = true;
  final requestedDays = <int>[];

  /// When set, [setShowViewHistory] throws it (to test rollback).
  Object? failSetting;

  @override
  Future<ActivityDashboard> dashboard(
    UuidValue itemUuid, {
    int days = 28,
  }) async {
    requestedDays.add(days);
    final d = dashboards[itemUuid.uuid];
    if (d == null) throw FakeNotFound(itemUuid.uuid);
    return d.copyWith(showMyViewHistory: viewHistory);
  }

  @override
  Future<bool> showViewHistory() async => viewHistory;

  @override
  Future<bool> setShowViewHistory(bool show) async {
    final failure = failSetting;
    if (failure != null) throw failure;
    return viewHistory = show;
  }
}

/// Base of the repositories the fakes don't model: every call fails with a
/// clear [UnsupportedError] naming the member, so a test that needs one
/// passes its own implementation to `CommandTestHarness`.
mixin _NotFaked {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '$runtimeType.${invocation.memberName} is not faked; pass a custom '
    'implementation to CommandTestHarness',
  );
}

class UnfakedSharingRepository with _NotFaked implements SharingRepository {}

class UnfakedCommentRepository with _NotFaked implements CommentRepository {}

class UnfakedNotificationRepository
    with _NotFaked
    implements NotificationRepository {}

class UnfakedPresenceRepository with _NotFaked implements PresenceRepository {}

class UnfakedVersionRepository with _NotFaked implements VersionRepository {}

class UnfakedFileRepository with _NotFaked implements FileRepository {}

class UnfakedMetaRepository with _NotFaked implements MetaRepository {}

class UnfakedBoardRepository with _NotFaked implements BoardRepository {}
