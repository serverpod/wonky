import 'dart:async';

import 'package:collection/collection.dart';
import 'package:wonky_core/wonky_core.dart';

import '../commands/command.dart';

/// One fresh document for one command of a [sweepCommands] run: what the
/// sweep invokes, undoes, redoes and compares.
abstract class SweepFixture {
  /// Invokes [id] with [args] as a UI gesture.
  Future<CommandResult> invoke(String id, Map<String, Object?> args);

  /// Undoes the newest step.
  Future<void> undo();

  /// Redoes the newest undone step.
  Future<void> redo();

  /// The undo steps of the active stack (the sweep counts them).
  int get undoSteps;

  /// The document state the command may change, compared deeply (maps by
  /// key, lists in order; records and other values with `==`)
  /// (rows, a Delta, drive items … as a string or a deep-comparable value).
  Object? snapshot();

  /// Releases the fixture.
  Future<void> dispose();
}

/// What the sweep saw for one command.
enum SweepOutcome {
  /// Executed, recorded one step; undo restored the snapshot and redo
  /// restored the executed one.
  roundTrip,

  /// Executed without changing the snapshot or recording a step (view
  /// state, panels, navigation, nothing to do in the fixture).
  noChange,

  /// Did not run: cancelled, disabled, failed, needs a dialog or the
  /// platform, invalid sample arguments, or skipped.
  notRun,

  /// Broke the command and undo contract (08 §2–§4).
  violation,
}

/// The result of [sweepCommands].
class CommandSweepReport {
  /// Command id → (outcome, detail).
  final Map<String, (SweepOutcome, String)> results = {};

  /// The ids with [outcome].
  List<String> idsWith(SweepOutcome outcome) => [
    for (final e in results.entries)
      if (e.value.$1 == outcome) e.key,
  ];

  /// Id → what is wrong, for every [SweepOutcome.violation].
  Map<String, String> get violations => {
    for (final e in results.entries)
      if (e.value.$1 == SweepOutcome.violation) e.key: e.value.$2,
  };

  /// A readable summary (for `printOnFailure`).
  String describe() {
    final b = StringBuffer();
    for (final outcome in SweepOutcome.values) {
      final ids = idsWith(outcome);
      b.writeln('${outcome.name}: ${ids.length}');
      for (final id in ids) {
        b.writeln('  $id  ${results[id]!.$2}');
      }
    }
    return b.toString();
  }
}

/// The execute → undo → redo sweep over registered commands (suite 08 §4).
///
/// For each command in [commands] (minus [skip]) a fresh fixture from
/// [open] runs it with [args]`[id]` or arguments sampled from its schema
/// ([sampleArgs]), then:
///
/// - a command that records one undo step must have changed the snapshot,
///   undo must restore the snapshot before it and redo the one after it;
/// - a command that changes the snapshot without recording a step, records
///   more than one step for one invocation, or changes the snapshot and
///   then reports anything but success is a violation;
/// - commands that are cancelled, disabled, need a dialog or the platform,
///   or reject the sampled arguments are reported as not run (headless
///   tests have no navigator: pass arguments in [args] to cover them);
/// - [noUndoStep] names the commands that may change the snapshot without
///   an undo step by design (with the reason, e.g. infrastructure created
///   on first use).
Future<CommandSweepReport> sweepCommands({
  required Iterable<Command<CommandArgs>> commands,
  required Future<SweepFixture> Function() open,
  Map<String, Map<String, Object?>> args = const {},
  Map<String, String> skip = const {},
  Map<String, String> noUndoStep = const {},
  Duration timeout = const Duration(seconds: 5),
}) async {
  final report = CommandSweepReport();
  for (final command in commands) {
    final id = command.id.value;
    final skipped = skip[id];
    if (skipped != null) {
      report.results[id] = (SweepOutcome.notRun, 'skipped: $skipped');
      continue;
    }
    final f = await open();
    try {
      report.results[id] = await _sweepOne(
        f,
        id,
        args[id] ?? sampleArgs(command.argsSchema),
        timeout,
        noUndoStep[id],
      );
    } finally {
      await f.dispose();
    }
  }
  return report;
}

Future<(SweepOutcome, String)> _sweepOne(
  SweepFixture f,
  String id,
  Map<String, Object?> args,
  Duration timeout,
  String? noUndoStep,
) async {
  final before = f.snapshot();
  final steps = f.undoSteps;
  final CommandResult r;
  (SweepOutcome, String) notRun(String why) => _same(f.snapshot(), before)
      ? (SweepOutcome.notRun, why)
      : noUndoStep != null
      ? (SweepOutcome.notRun, '$why (allowed change: $noUndoStep)')
      : (SweepOutcome.violation, 'changed the document, then $why');
  try {
    r = await f.invoke(id, args).timeout(timeout);
  } on TimeoutException {
    return notRun('timed out (waits for input)');
  } on CommandException catch (e) {
    return notRun('${e.runtimeType}');
  } catch (e) {
    return notRun('throws ${e.runtimeType}');
  }
  final after = f.snapshot();
  final changed = !_same(after, before);
  final recorded = f.undoSteps - steps;
  if (r.status != CommandStatus.ok) {
    return changed
        ? (SweepOutcome.violation, 'changed the document but ${r.status.name}')
        : (SweepOutcome.notRun, r.status.name);
  }
  if (recorded > 1) {
    return (SweepOutcome.violation, '$recorded undo steps for one gesture');
  }
  if (recorded == 0) {
    if (!changed) return (SweepOutcome.noChange, '');
    return noUndoStep != null
        ? (SweepOutcome.noChange, 'allowed change: $noUndoStep')
        : (SweepOutcome.violation, 'changed the document without an undo step');
  }
  if (!changed) return (SweepOutcome.noChange, 'step without a visible change');
  await f.undo();
  if (!_same(f.snapshot(), before)) {
    return (SweepOutcome.violation, 'undo did not restore the document');
  }
  await f.redo();
  if (!_same(f.snapshot(), after)) {
    return (SweepOutcome.violation, 'redo did not restore the change');
  }
  return (SweepOutcome.roundTrip, '');
}

/// Sample arguments for a command [schema]: each required property gets a
/// value of its type (the first enum value or the default when there is
/// one); optional properties are left out.
Map<String, Object?> sampleArgs(JsonSchema schema) => switch (schema) {
  ObjectSchema(:final properties, :final required) => {
    for (final name in required)
      if (properties[name] case final p?) name: _sample(p),
  },
  _ => const {},
};

Object? _sample(JsonSchema s) => switch (s) {
  ObjectSchema() => sampleArgs(s),
  StringSchema(:final enumValues, :final defaultValue, :final format) =>
    enumValues?.first ??
        defaultValue ??
        (format == 'uuid' ? '00000000-0000-7000-8000-000000000000' : 'x'),
  IntegerSchema(:final defaultValue, :final minimum) =>
    defaultValue ?? (minimum == null || minimum < 1 ? 1 : minimum),
  NumberSchema(:final defaultValue, :final minimum) =>
    defaultValue ?? (minimum == null || minimum < 1 ? 1 : minimum),
  BooleanSchema(:final defaultValue) => defaultValue ?? true,
  ArraySchema(:final items, :final minItems) => [
    for (var i = 0; i < (minItems == null || minItems < 1 ? 1 : minItems); i++)
      _sample(items),
  ],
  NullableSchema() => null,
  AnyOfSchema(:final options) =>
    options.isEmpty ? null : _sample(options.first),
  AnySchema() => null,
};

/// Deep equality of snapshots (maps compare regardless of key order).
bool _same(Object? a, Object? b) => const DeepCollectionEquality().equals(a, b);
