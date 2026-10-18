import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show Client, UuidValue;
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

import '../../model/workbook_session.dart';
import '../../revlog/logged_workbook_session.dart';

/// `PropertiesService.userProperties` on the client (09 §6.9, A-09-4).
///
/// User properties live on the server (`script_user_property`, read and
/// written with `sheets.getUserProperties` / `setUserProperties`), so they
/// follow the user to other devices and to server runs
/// (`ServerUserProperties`). Scripts read synchronously: the values are
/// loaded once ([load]) and kept in memory. A copy and the unsent changes
/// are kept in the user's local store (`sheets.userProps.<fileUuid>`), so
/// they work offline; unsent changes are sent with the next write or load
/// (RevLog spec 06 §7.1).
class RemoteUserProperties implements PropertyStore {
  RemoteUserProperties._(this._client, this._store, this.fileUuid);

  /// The store of [session]'s user for its spreadsheet; a memory store for
  /// sessions without a server (tests, previews).
  static Future<PropertyStore> forSession(
    ShellServices services,
    WorkbookSession session,
  ) async {
    final client = services.client;
    if (session is! LoggedWorkbookSession || client == null) {
      return MemoryPropertyStore();
    }
    final store = RemoteUserProperties._(
      client,
      services.userStore,
      UuidValue.fromString(session.spreadsheetId),
    );
    await store.load();
    return store;
  }

  final Client _client;
  final LocalStore _store;

  /// The spreadsheet's file.
  final UuidValue fileUuid;

  final Map<String, String> _values = {};

  /// Changes not yet confirmed by the server (null = delete).
  final Map<String, String?> _pending = {};
  Future<void> _writes = Future.value();

  String get _key => 'sheets.userProps.${fileUuid.uuid}';

  /// Reads the cached values, then the server's (when reachable) with the
  /// unsent changes on top.
  Future<void> load() async {
    try {
      final raw = await _store.read(_key);
      if (raw is Map) {
        _read(raw['values'], (k, v) => _values[k] = v!);
        _read(raw['pending'], (k, v) => _pending[k] = v);
      }
    } catch (e) {
      debugPrint('Reading cached user properties failed: $e');
    }
    try {
      final server = await _client.sheets.getUserProperties(fileUuid);
      _values
        ..clear()
        ..addAll(server);
      for (final e in _pending.entries) {
        if (e.value == null) {
          _values.remove(e.key);
        } else {
          _values[e.key] = e.value!;
        }
      }
      await _save();
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
    }
    if (_pending.isNotEmpty) _enqueue();
  }

  static void _read(Object? m, void Function(String, String?) put) {
    if (m is! Map) return;
    for (final e in m.entries) {
      final v = e.value;
      if (v == null || v is String) put('${e.key}', v as String?);
    }
  }

  /// Completes when the queued writes are sent (or failed offline).
  Future<void> flush() => _writes;

  @override
  Map<String, String> all() => Map.of(_values);

  @override
  void set(String key, String value) {
    if (_values[key] == value) return;
    _values[key] = value;
    _pending[key] = value;
    _enqueue();
  }

  @override
  void delete(String key) {
    if (_values.remove(key) == null) return;
    _pending[key] = null;
    _enqueue();
  }

  void _enqueue() {
    _writes = _writes.then((_) => _send()).catchError((Object e) {
      debugPrint('Storing user properties failed: $e');
    });
  }

  Future<void> _send() async {
    if (_pending.isEmpty) return;
    final sent = Map.of(_pending);
    await _save();
    try {
      await _client.sheets.setUserProperties(fileUuid, sent);
    } catch (e) {
      // Offline: kept in the local store and sent with the next write or
      // load.
      if (isOfflineError(e)) return;
      rethrow;
    }
    for (final e in sent.entries) {
      if (_pending.containsKey(e.key) && _pending[e.key] == e.value) {
        _pending.remove(e.key);
      }
    }
    await _save();
  }

  Future<void> _save() =>
      _store.write(_key, {'values': _values, 'pending': _pending});
}
