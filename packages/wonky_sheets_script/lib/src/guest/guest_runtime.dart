import 'dart:async';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_internals.dart'
    show $InstanceImpl, RuntimeException, WrappedException;
import 'package:dart_eval/stdlib/core.dart';

import '../protocol/messages.dart';
import '../protocol/values.dart';
import 'boxing.dart';
import 'guest_bridge.dart';
import 'runtime_plugin.dart';

/// Library of the generated dispatcher (`package:script/__exports.dart`).
const String scriptExportsLibrary = 'package:script/__exports.dart';

/// Entry point of the generated dispatcher.
const String scriptInvokeFunction = 'wonkyInvoke';

/// Final status of an execution (`ScriptExecutionStatus`).
enum ExecutionStatus {
  /// Returned normally.
  completed,

  /// Threw an exception.
  failed,

  /// Exceeded its time limit.
  timedOut,

  /// Stopped by the user or the host.
  cancelled,

  /// Exceeded a quota (cells, memory, bridged values).
  quotaExceeded,

  /// Not run (trigger already running, scripts disabled).
  skipped,
}

/// One frame of a script stack trace (09 §13.2).
final class ScriptStackFrame {
  /// Creates a frame.
  const ScriptStackFrame({
    required this.function,
    this.library,
    this.offset,
    this.file,
    this.line,
    this.column,
  });

  /// Function or `Class.method`.
  final String function;

  /// Library URI (`package:script/main.dart`).
  final String? library;

  /// Source offset of the enclosing declaration (patch DE-1).
  final int? offset;

  /// Script file name (`main.dart`), mapped by the host.
  final String? file;

  /// 1-based line, mapped by the host.
  final int? line;

  /// 1-based column, mapped by the host.
  final int? column;

  /// Copy with a source position.
  ScriptStackFrame withPosition(String file, int line, int column) =>
      ScriptStackFrame(
        function: function,
        library: library,
        offset: offset,
        file: file,
        line: line,
        column: column,
      );

  /// JSON form (`ScriptExecution.errorStackJson`).
  Map<String, Object?> toJson() => {
    'function': function,
    'library': ?library,
    'offset': ?offset,
    'file': ?file,
    'line': ?line,
    'column': ?column,
  };

  /// From [toJson].
  static ScriptStackFrame fromJson(Map<String, Object?> j) => ScriptStackFrame(
    function: j['function']! as String,
    library: j['library'] as String?,
    offset: j['offset'] as int?,
    file: j['file'] as String?,
    line: j['line'] as int?,
    column: j['column'] as int?,
  );

  @override
  String toString() =>
      '$function (${file ?? library ?? '?'}${line == null ? '' : ':$line'})';
}

/// Why an execution failed.
final class ScriptFailure {
  /// Creates a failure.
  const ScriptFailure({
    required this.type,
    required this.message,
    this.code,
    this.frames = const [],
  });

  /// Exception type (`RangeException`, `StateError`, `TimeoutError`, …).
  final String type;

  /// Message.
  final String message;

  /// Host error code for API exceptions.
  final String? code;

  /// Stack, innermost first.
  final List<ScriptStackFrame> frames;

  /// Copy with mapped [frames].
  ScriptFailure withFrames(List<ScriptStackFrame> frames) =>
      ScriptFailure(type: type, message: message, code: code, frames: frames);

  /// JSON form.
  Map<String, Object?> toJson() => {
    'type': type,
    'message': message,
    'code': ?code,
    'frames': [for (final f in frames) f.toJson()],
  };

  /// From [toJson].
  static ScriptFailure fromJson(Map<String, Object?> j) => ScriptFailure(
    type: j['type']! as String,
    message: j['message']! as String,
    code: j['code'] as String?,
    frames: [
      for (final f in (j['frames'] as List? ?? const []))
        ScriptStackFrame.fromJson((f as Map).cast()),
    ],
  );

  @override
  String toString() => '$type: $message';
}

/// What the guest runs (09 §8.2.2 `Execute`).
final class GuestRequest {
  /// Creates a request.
  const GuestRequest({
    required this.buildHash,
    this.bytecode,
    required this.function,
    this.args = const [],
    this.event,
    required this.timeoutMs,
    this.maxBridgedValues = 5000000,
    this.maxListLength = 10000000,
    this.maxSleepMs = 5000,
    this.writeBatchCells = 10000,
  });

  /// Build the bytecode belongs to (runtime cache key).
  final String buildHash;

  /// EVC bytecode; may be omitted when the guest already has the build.
  final Uint8List? bytecode;

  /// Exported function to run.
  final String function;

  /// Positional arguments (custom functions, MCP).
  final List<Object?> args;

  /// Event object data (`kind`, `range` handle, `user`, …).
  final Map<String, Object?>? event;

  /// Time limit (used by the checkpoint guard; isolates are also killed by
  /// the host).
  final int timeoutMs;

  /// Bridged value limit.
  final int maxBridgedValues;

  /// List allocation limit.
  final int maxListLength;

  /// `Utilities.sleep` limit.
  final int maxSleepMs;

  /// Write batch size.
  final int writeBatchCells;

  /// Wire form.
  Map<String, Object?> toWire() => {
    'buildHash': buildHash,
    'bytecode': bytecode,
    'function': function,
    'args': args,
    'event': event,
    'timeoutMs': timeoutMs,
    'maxBridgedValues': maxBridgedValues,
    'maxListLength': maxListLength,
    'maxSleepMs': maxSleepMs,
    'writeBatchCells': writeBatchCells,
  };

  /// From [toWire].
  static GuestRequest fromWire(Map<String, Object?> w) => GuestRequest(
    buildHash: w['buildHash']! as String,
    bytecode: w['bytecode'] as Uint8List?,
    function: w['function']! as String,
    args: (w['args'] as List?)?.cast<Object?>() ?? const [],
    event: (w['event'] as Map?)?.cast<String, Object?>(),
    timeoutMs: w['timeoutMs']! as int,
    maxBridgedValues: w['maxBridgedValues']! as int,
    maxListLength: w['maxListLength']! as int,
    maxSleepMs: w['maxSleepMs']! as int,
    writeBatchCells: w['writeBatchCells']! as int,
  );

  /// Copy without bytecode (the guest already has it).
  GuestRequest withoutBytecode() => GuestRequest(
    buildHash: buildHash,
    function: function,
    args: args,
    event: event,
    timeoutMs: timeoutMs,
    maxBridgedValues: maxBridgedValues,
    maxListLength: maxListLength,
    maxSleepMs: maxSleepMs,
    writeBatchCells: writeBatchCells,
  );
}

/// Result of running a [GuestRequest] (09 §8.2.2 `Done`).
final class GuestOutcome {
  /// Creates an outcome.
  const GuestOutcome({
    required this.status,
    this.result,
    this.error,
    this.instructions = 0,
    this.bridgeCalls = 0,
    this.bridgedValues = 0,
  });

  /// Final status.
  final ExecutionStatus status;

  /// Return value (plain values).
  final Object? result;

  /// Failure, if any.
  final ScriptFailure? error;

  /// Approximate number of executed instructions.
  final int instructions;

  /// Host calls made.
  final int bridgeCalls;

  /// Values boxed into the guest.
  final int bridgedValues;

  /// Wire form.
  Map<String, Object?> toWire() => {
    'status': status.name,
    'result': result,
    'error': error?.toJson(),
    'instructions': instructions,
    'bridgeCalls': bridgeCalls,
    'bridgedValues': bridgedValues,
  };

  /// From [toWire].
  static GuestOutcome fromWire(Map<String, Object?> w) => GuestOutcome(
    status: ExecutionStatus.values.byName(w['status']! as String),
    result: w['result'],
    error: w['error'] == null
        ? null
        : ScriptFailure.fromJson((w['error']! as Map).cast()),
    instructions: w['instructions']! as int,
    bridgeCalls: w['bridgeCalls']! as int,
    bridgedValues: w['bridgedValues']! as int,
  );
}

/// Loads bytecode into dart_eval runtimes and runs exported functions
/// (09 §3.1 `guest.dart`). Used inside sandbox isolates and by the inline
/// runner; keeps up to two warm runtimes (by build hash, 09 §8.8).
final class GuestRuntime {
  /// Creates a guest runtime that talks to its host through [transport].
  GuestRuntime(this.transport);

  /// Channel to the host.
  final GuestTransport transport;

  final _runtimes = <String, (Runtime, GuestBridgeSlot)>{};

  /// Whether the runtime of [buildHash] is loaded.
  bool hasBuild(String buildHash) => _runtimes.containsKey(buildHash);

  (Runtime, GuestBridgeSlot) _load(GuestRequest req) {
    final cached = _runtimes.remove(req.buildHash);
    if (cached != null) {
      _runtimes[req.buildHash] = cached;
      return cached;
    }
    final bytes = req.bytecode;
    if (bytes == null) {
      throw StateError('Bytecode of build ${req.buildHash} is not loaded.');
    }
    final runtime = Runtime(ByteData.sublistView(bytes));
    final slot = GuestBridgeSlot();
    runtime.addPlugin(
      WonkyRuntimePlugin(slot, maxListLength: req.maxListLength),
    );
    while (_runtimes.length >= 2) {
      _runtimes.remove(_runtimes.keys.first);
    }
    final entry = (runtime, slot);
    _runtimes[req.buildHash] = entry;
    return entry;
  }

  /// Drops a runtime (after a timeout its state is unreliable).
  void evict(String buildHash) => _runtimes.remove(buildHash);

  /// Runs [req]. Never throws.
  Future<GuestOutcome> execute(GuestRequest req) async {
    final Runtime runtime;
    final GuestBridgeSlot slot;
    try {
      (runtime, slot) = _load(req);
    } on Object catch (e) {
      return GuestOutcome(
        status: ExecutionStatus.failed,
        error: ScriptFailure(type: 'LoadError', message: '$e'),
      );
    }
    final bridge = GuestBridge(
      transport,
      maxBridgedValues: req.maxBridgedValues,
      writeBatchCells: req.writeBatchCells,
      maxSleepMs: req.maxSleepMs,
    );
    slot.current = bridge;
    final watch = Stopwatch()..start();
    final startCheckpoints = runtime.checkpoints;
    runtime.onCheckpoint = () {
      if (watch.elapsedMilliseconds > req.timeoutMs) {
        throw ScriptAbort(
          'timedOut',
          'Exceeded maximum execution time (${_seconds(req.timeoutMs)}).',
        );
      }
    };
    GuestOutcome outcome;
    try {
      final args = [
        $String(req.function),
        $List.wrap(<$Value>[for (final a in req.args) bridge.boxing.box(a)]),
        if (req.event == null) const $null() else bridge.boxing.box(req.event),
      ];
      var result = runZoned(
        () => runtime.executeLib(
          scriptExportsLibrary,
          scriptInvokeFunction,
          args,
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) =>
              transport.log(ScriptLogLevel.info, line),
        ),
      );
      if (result is $Future) {
        result = await (result.$value as Future<Object?>);
      }
      final pending = bridge.finish();
      if (pending != null) {
        outcome = GuestOutcome(
          status: ExecutionStatus.failed,
          error: _apiFailure(pending, const []),
        );
      } else {
        Object? value;
        try {
          value = GuestBoxing.unbox(result);
        } on UnsupportedValueError catch (e) {
          value = CellError('#VALUE!', e.toString());
        }
        outcome = GuestOutcome(
          status: ExecutionStatus.completed,
          result: value,
        );
      }
    } on Object catch (e) {
      outcome = _failure(runtime, e, bridge);
      if (outcome.status == ExecutionStatus.timedOut) evict(req.buildHash);
    } finally {
      slot.current = null;
      runtime.onCheckpoint = null;
      runtime.resetExecutionState();
    }
    final instructions =
        (runtime.checkpoints - startCheckpoints) * runtime.checkpointInterval;
    return GuestOutcome(
      status: outcome.status,
      result: outcome.result,
      error: outcome.error,
      instructions: instructions,
      bridgeCalls: bridge.calls,
      bridgedValues: bridge.bridgedValues,
    );
  }

  static String _seconds(int ms) => ms % 1000 == 0
      ? '${ms ~/ 1000} s'
      : '${(ms / 1000).toStringAsFixed(1)} s';

  GuestOutcome _failure(Runtime runtime, Object e, GuestBridge bridge) {
    Object error = e;
    if (error is RuntimeException) error = error.caughtException;
    if (error is WrappedException) error = error.exception;
    if (error is ScriptAbort) {
      return GuestOutcome(
        status: ExecutionStatus.values.byName(error.status),
        error: ScriptFailure(
          type: error.status == 'timedOut'
              ? 'ExecutionTimeoutException'
              : 'QuotaExceededException',
          message: error.message,
          frames: _frames(runtime, runtime.scopeNameStack),
        ),
      );
    }
    final scopes = e is RuntimeException
        ? runtime.scopeNameStack
        : (runtime.throwScopes ?? runtime.scopeNameStack);
    final frames = _frames(runtime, scopes);
    if (error is $Value) {
      return GuestOutcome(
        status: ExecutionStatus.failed,
        error: _thrownValue(runtime, error, frames),
      );
    }
    final type = error is Error || error is Exception
        ? _publicType(error)
        : 'Error';
    return GuestOutcome(
      status: ExecutionStatus.failed,
      error: ScriptFailure(type: type, message: '$error', frames: frames),
    );
  }

  ScriptFailure _thrownValue(
    Runtime runtime,
    $Value value,
    List<ScriptStackFrame> frames,
  ) {
    if (value is $InstanceImpl) {
      String? field(String name) {
        try {
          final v = value.$getProperty(runtime, name);
          return v is $String ? v.$value : null;
        } on Object {
          return null;
        }
      }

      final text = runtime.valueToString(value);
      final message = field('message') ?? text;
      final code = field('code');
      final type = text.contains(':')
          ? text.substring(0, text.indexOf(':'))
          : 'Exception';
      return ScriptFailure(
        type: type.contains('(') ? type.substring(0, type.indexOf('(')) : type,
        message: message,
        code: code,
        frames: frames,
      );
    }
    final Object? raw = value.$value;
    if (raw is Error || raw is Exception) {
      return ScriptFailure(
        type: _publicType(raw!),
        message: '$raw',
        frames: frames,
      );
    }
    return ScriptFailure(type: 'Exception', message: '$raw', frames: frames);
  }

  /// The public type name of a host exception (`_Exception` → `Exception`).
  static String _publicType(Object e) {
    final name = e.runtimeType.toString();
    if (name == '_Exception') return 'Exception';
    if (name.startsWith('_')) {
      return e is Error ? 'Error' : 'Exception';
    }
    return name;
  }

  ScriptFailure _apiFailure(ScriptError e, List<ScriptStackFrame> frames) =>
      ScriptFailure(
        type: _exceptionType(e.code),
        message: e.message,
        code: e.code,
        frames: frames,
      );

  static String _exceptionType(String code) => switch (code) {
    'range' => 'RangeException',
    'permission_denied' => 'PermissionDeniedException',
    'scope_not_granted' => 'ScopeNotGrantedException',
    'ui_unavailable' => 'UiUnavailableException',
    'quota_exceeded' => 'QuotaExceededException',
    'offline' => 'OfflineException',
    'side_effect' => 'CustomFunctionSideEffectException',
    'url_fetch' => 'UrlFetchException',
    _ => 'ScriptException',
  };

  /// Frames from DE-1 scope labels (`name@library:offset`), innermost first,
  /// without the API and dispatcher internals.
  static List<ScriptStackFrame> _frames(Runtime runtime, List<String> scopes) {
    final out = <ScriptStackFrame>[];
    for (final label in scopes.reversed) {
      final at = label.lastIndexOf('@');
      if (at < 0) continue;
      final name = label.substring(0, at);
      final pos = label.substring(at + 1).split(':');
      final lib = int.tryParse(pos[0]);
      final offset = pos.length > 1 ? int.tryParse(pos[1]) : null;
      final uri = lib == null ? null : runtime.libraryUriOf(lib);
      if (uri == null || !uri.startsWith('package:script/')) continue;
      if (uri == scriptExportsLibrary) continue;
      if (out.isNotEmpty &&
          out.last.function == name &&
          out.last.offset == offset) {
        continue; // try/finally scopes repeat the frame
      }
      out.add(ScriptStackFrame(function: name, library: uri, offset: offset));
    }
    return out;
  }
}
