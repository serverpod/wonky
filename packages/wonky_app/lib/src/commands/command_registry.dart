import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:wonky_core/wonky_core.dart';

import 'command.dart';

/// All commands of the running app (suite 08 §1.1). Shell commands are
/// registered by `wonky_app`, app commands by the app config; dynamic
/// registration is reserved for Sheets script macros (`sheets.macro.*`).
///
/// Two signals (suite 08 §1.1, CQ-39):
/// - the registry itself notifies when commands **or their state** may have
///   changed: registrations synchronously, [notifyStateChanged] coalesced to
///   at most once per frame (selection moves, typing, role changes). Command
///   widgets (toolbars, menus, buttons) listen to it.
/// - [registrations] notifies only when commands are registered or removed
///   (the keymap, which rebuilds its chord table on it).
class CommandRegistry extends ChangeNotifier {
  final Map<CommandId, Command<CommandArgs>> _commands = {};
  final _Signal _registrations = _Signal();

  bool _statePending = false;
  int? _frameCallbackId;
  bool _disposed = false;

  /// Notifies only when commands are registered or unregistered (never on
  /// [notifyStateChanged]).
  Listenable get registrations => _registrations;

  /// Registers [command]. Re-registering an id throws unless [replace]
  /// (apps must never re-register shell ids).
  void register(Command<CommandArgs> command, {bool replace = false}) {
    if (!command.id.isValid) {
      throw ArgumentError.value(command.id.value, 'id', 'Invalid command id');
    }
    if (!replace && _commands.containsKey(command.id)) {
      throw StateError('Command ${command.id.value} is already registered');
    }
    _commands[command.id] = command;
    _notifyRegistrations();
  }

  void registerAll(Iterable<Command<CommandArgs>> commands) {
    for (final c in commands) {
      if (_commands.containsKey(c.id)) {
        throw StateError('Command ${c.id.value} is already registered');
      }
      _commands[c.id] = c;
    }
    _notifyRegistrations();
  }

  /// Removes a dynamic command (script macros).
  void unregister(CommandId id) {
    if (_commands.remove(id) != null) _notifyRegistrations();
  }

  Command<CommandArgs>? operator [](CommandId id) => _commands[id];

  Command<CommandArgs>? byId(String id) => _commands[CommandId(id)];

  bool contains(String id) => _commands.containsKey(CommandId(id));

  Iterable<Command<CommandArgs>> get all => _commands.values;

  /// Signals that enabled/checked states may have changed (selection moved,
  /// role changed) so command widgets rebuild. Coalesced: the listeners run
  /// once at the start of the next frame however often this is called
  /// before it (outside Flutter, in a microtask).
  void notifyStateChanged() {
    if (_disposed || _statePending) return;
    _statePending = true;
    final binding = _scheduler();
    if (binding == null || !binding.framesEnabled) {
      scheduleMicrotask(_flushState);
    } else {
      _frameCallbackId = binding.scheduleFrameCallback((_) {
        _frameCallbackId = null;
        _flushState();
      });
    }
  }

  void _flushState() {
    if (_disposed || !_statePending) return;
    _statePending = false;
    notifyListeners();
  }

  void _notifyRegistrations() {
    // A synchronous notification covers a pending state change.
    _statePending = false;
    _registrations.fire();
    notifyListeners();
  }

  static SchedulerBinding? _scheduler() {
    try {
      return SchedulerBinding.instance;
    } on Object {
      // Not initialized (pure unit tests).
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final id = _frameCallbackId;
    if (id != null) _scheduler()?.cancelFrameCallbackWithId(id);
    _registrations.dispose();
    super.dispose();
  }
}

class _Signal extends ChangeNotifier {
  void fire() => notifyListeners();
}
