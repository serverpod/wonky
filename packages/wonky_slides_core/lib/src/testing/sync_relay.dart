import 'package:wonky_revlog/rows.dart';

import '../session/memory_deck.dart';

final class _ServerRow {
  _ServerRow(this.table);

  final String table;
  final Map<String, Object?> columns = {};
  final Map<String, int> stamps = {};
  bool deleted = false;
  int deletedAt = 0;
}

/// One client of a [LwwSyncRelay]: a [MemoryDeck] with its queue of
/// persisted but not yet pushed changes.
final class RelayClient {
  RelayClient._(this.name, this.deck);

  /// Name for test output ("A", "B").
  final String name;

  /// The client's session (its own model, writes and undo target).
  final MemoryDeck deck;

  /// Persisted changes not pushed yet.
  final List<RowChange> pending = [];

  /// While false, [LwwSyncRelay.sync] neither pushes nor delivers.
  bool online = true;
}

/// An in-memory stand-in for the offline-sync engine and server (suite 12
/// §2) for multi-client tests of pure-Dart code: field-level
/// last-writer-wins per column in push order, row tombstones and revival
/// by re-insert, full delivery of the server state to online clients.
///
/// A skeleton of the multi-client harness of 12 §7.3 (scripted scenarios,
/// undo against collaborators' edits); the real harness with replicas,
/// writers and the server is SL-9's.
///
/// ```dart
/// final relay = LwwSyncRelay();
/// final a = relay.connect('A', deckA), b = relay.connect('B', deckB);
/// a.deck.execute(op);
/// relay.sync();   // b.deck.model now has a's change
/// ```
final class LwwSyncRelay {
  final Map<String, Map<String, _ServerRow>> _rows = {};
  int _clock = 0;

  /// Connected clients.
  final List<RelayClient> clients = [];

  /// Connects [deck] (its `onPersist` feeds the client's queue). The
  /// client's current rows are pushed as its first write.
  RelayClient connect(String name, MemoryDeck deck) {
    final c = RelayClient._(name, deck);
    final dump = deck.model.dump();
    for (final t in dump.entries) {
      for (final r in t.value.entries) {
        c.pending.add(RowChange.insert(t.key, r.key, r.value));
      }
    }
    deck.onPersist = (w) => c.pending.addAll(w.changes);
    clients.add(c);
    return c;
  }

  /// Applies [client]'s queued changes to the server state.
  void push(RelayClient client) {
    for (final ch in client.pending) {
      final t = _rows.putIfAbsent(ch.table, () => {});
      final ts = ++_clock;
      final row = t[ch.rowId];
      switch (ch.op) {
        case RowOp.insert:
          final r = row ?? (t[ch.rowId] = _ServerRow(ch.table));
          r.deleted = false;
          for (final e in ch.columnsAfter.entries) {
            r.columns[e.key] = e.value;
            r.stamps[e.key] = ts;
          }
        case RowOp.update:
          if (row == null || row.deleted) continue;
          for (final e in ch.columnsAfter.entries) {
            row.columns[e.key] = e.value;
            row.stamps[e.key] = ts;
          }
        case RowOp.delete:
          if (row == null) continue;
          row.deleted = true;
          row.deletedAt = ts;
      }
    }
    client.pending.clear();
  }

  /// Patches [client]'s model to the server state (remote batch).
  void deliver(RelayClient client) {
    final model = client.deck.model;
    final changes = <RowChange>[];
    for (final t in _rows.entries) {
      for (final MapEntry(key: id, value: row) in t.value.entries) {
        final mine = model.currentColumns(t.key, id);
        if (row.deleted) {
          if (mine != null) changes.add(RowChange.delete(t.key, id, mine));
          continue;
        }
        if (mine == null) {
          changes.add(RowChange.insert(t.key, id, row.columns));
          continue;
        }
        final diff = {
          for (final e in row.columns.entries)
            if (mine[e.key] != e.value) e.key: e.value,
        };
        if (diff.isNotEmpty) {
          changes.add(
            RowChange.update(t.key, id, {
              for (final k in diff.keys) k: mine[k],
            }, diff),
          );
        }
      }
    }
    if (changes.isNotEmpty) client.deck.applyRemote(changes);
  }

  /// Pushes every online client's queue, then delivers to every online
  /// client.
  void sync() {
    for (final c in clients) {
      if (c.online) push(c);
    }
    for (final c in clients) {
      if (c.online) deliver(c);
    }
  }

  /// The server's live rows (canonical form, as `DeckModel.dump`).
  Map<String, Map<String, Map<String, Object?>>> dump() {
    final tables = _rows.keys.toList()..sort();
    final out = <String, Map<String, Map<String, Object?>>>{};
    for (final t in tables) {
      final ids = [
        for (final e in _rows[t]!.entries)
          if (!e.value.deleted) e.key,
      ]..sort();
      if (ids.isEmpty) continue;
      out[t] = {
        for (final id in ids)
          id: {
            for (final k in (_rows[t]![id]!.columns.keys.toList()..sort()))
              k: _rows[t]![id]!.columns[k],
          },
      };
    }
    return out;
  }
}
