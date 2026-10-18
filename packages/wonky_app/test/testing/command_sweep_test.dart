import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';

/// The execute → undo → redo sweep helper (08 §4) used by every app.
void main() {
  group('Given commands that keep and break the undo contract', () {
    late List<Command<CommandArgs>> commands;
    setUp(() {
      commands = [
        CallbackCommand(
          id: 'test.renameWithoutUndo',
          title: (_) => 'Rename',
          isUndoable: false,
          run: (ctx, args) async {
            final h = _Fixture.current!;
            await h.h.drive.rename(h.doc.uuid, 'Changed');
            return const CommandResult.ok();
          },
        ),
        CallbackCommand(
          id: 'test.needsArgs',
          title: (_) => 'Needs args',
          argsSchema: const JsonSchema.object(
            properties: {'n': JsonSchema.integer(minimum: 3)},
            required: ['n'],
          ),
          run: (ctx, args) async => CommandResult.ok(args.toJson()),
        ),
      ];
      _Fixture.extra = commands;
    });

    test('when sweeping then the rename without an undo step is a violation '
        'and the others are reported', () async {
      final report = await sweepCommands(
        commands: [...commands, _registered('shell.drive.setStarred')],
        open: _Fixture.open,
        args: const {
          'shell.drive.setStarred': {'starred': true},
        },
      );

      expect(report.violations, {
        'test.renameWithoutUndo': 'changed the document without an undo step',
      });
      expect(report.idsWith(SweepOutcome.roundTrip), [
        'shell.drive.setStarred',
      ]);
      expect(report.idsWith(SweepOutcome.noChange), ['test.needsArgs']);
    });

    test('when the rename is allowed without an undo step then it is not a '
        'violation', () async {
      final report = await sweepCommands(
        commands: commands,
        open: _Fixture.open,
        noUndoStep: const {'test.renameWithoutUndo': 'by design'},
      );

      expect(report.violations, isEmpty);
    });
  });

  test('Given a schema when sampling arguments then required properties get '
      'values of their type', () {
    final args = sampleArgs(
      const JsonSchema.object(
        properties: {
          'kind': JsonSchema.string(enumValues: ['a', 'b']),
          'count': JsonSchema.integer(minimum: 2),
          'on': JsonSchema.boolean(),
          'ids': JsonSchema.array(JsonSchema.string(format: 'uuid')),
          'maybe': JsonSchema.nullable(JsonSchema.string()),
          'optional': JsonSchema.string(),
        },
        required: ['kind', 'count', 'on', 'ids', 'maybe'],
      ),
    );

    expect(args, {
      'kind': 'a',
      'count': 2,
      'on': true,
      'ids': ['00000000-0000-7000-8000-000000000000'],
      'maybe': null,
    });
  });
}

class _Fixture implements SweepFixture {
  _Fixture(this.h, this.doc);

  /// The fixture being swept (the test commands write through it).
  static _Fixture? current;

  /// Test commands registered in every fixture.
  static List<Command<CommandArgs>> extra = const [];

  final CommandTestHarness h;
  final DriveItemView doc;

  static Future<SweepFixture> open() async {
    final h = CommandTestHarness();
    h.services.registry.registerAll(extra);
    final doc = h.drive.seed(name: 'Plan');
    h.services.driveSelection.value = [doc];
    return current = _Fixture(h, doc);
  }

  @override
  Future<CommandResult> invoke(String id, Map<String, Object?> args) =>
      h.invoke(id, args, InvocationSource.ui);

  @override
  Future<void> undo() async => h.undo();

  @override
  Future<void> redo() async => h.redo();

  @override
  int get undoSteps => h.undoLabels.length;

  @override
  Object? snapshot() => {
    for (final i in h.drive.items) i.uuid.uuid: (i.name, i.starred),
  };

  @override
  Future<void> dispose() => h.dispose();
}

/// The shell command [id] (the sweep only reads its id and schema).
Command<CommandArgs> _registered(String id) {
  final h = CommandTestHarness();
  final command = h.services.registry.all.firstWhere((c) => c.id.value == id);
  h.dispose();
  return command;
}
