import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';

/// Suite 08 §4: every registered `shell.*` command, executed headless on a
/// small drive (a folder and a selected document in it), then undone and
/// redone; the drive must match before and after.
void main() {
  test(
    'Given every shell command when it runs, is undone and redone then '
    'the drive round-trips and nothing changes without an undo step',
    () async {
      final probe = CommandTestHarness();
      final commands = [
        for (final c in probe.services.registry.all)
          if (c.id.value.startsWith('shell.')) c,
      ]..sort((a, b) => a.id.value.compareTo(b.id.value));
      await probe.dispose();

      final report = await sweepCommands(
        commands: commands,
        open: _ShellFixture.open,
        args: _args,
        skip: const {
          'shell.edit.undo': 'undo itself',
          'shell.edit.redo': 'redo itself',
          'shell.edit.undoTo': 'undo itself',
        },
        noUndoStep: const {
          'shell.drive.togglePinnedOffline':
              'available offline is a per-user setting, not undoable (08 §2)',
          'shell.drive.newDocument': 'creating a file is not undoable (08 §2)',
          'shell.file.new': 'creating a file is not undoable (08 §2)',
        },
      );

      printOnFailure(report.describe());
      expect(report.violations, isEmpty);
      expect(
        report.idsWith(SweepOutcome.roundTrip).length,
        greaterThanOrEqualTo(_minRoundTrips),
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// Commands covered by a full round trip (raise it when adding arguments).
const _minRoundTrips = 6;

/// Arguments for commands whose sampled ones do not fit the fixture.
const _args = <String, Map<String, Object?>>{
  'shell.drive.rename': {'name': 'Renamed'},
  'shell.drive.newFolder': {'name': 'New'},
  'shell.drive.setDescription': {'description': 'About'},
  'shell.drive.setStarred': {'starred': true},
  'shell.drive.move': {'folderUuid': null},
};

class _ShellFixture implements SweepFixture {
  _ShellFixture(this.h);

  final CommandTestHarness h;

  static Future<SweepFixture> open() async {
    final h = CommandTestHarness();
    final folder = h.drive.seed(name: 'Projects', kind: DriveItemKind.folder);
    final doc = h.drive.seed(name: 'Plan', parentUuid: folder.uuid);
    h.services.currentFolder.value = folder;
    h.services.driveSelection.value = [doc];
    return _ShellFixture(h);
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

  /// What the user sees of the drive: the items not in the trash, without
  /// server timestamps (undoing a folder creation trashes the folder, 08
  /// §3.3; every write bumps `modifiedAt`).
  @override
  Object? snapshot() => {
    for (final i in h.drive.items)
      if (i.trashedAt == null)
        i.uuid.uuid: (
          i.name,
          i.parentUuid?.uuid,
          i.starred,
          i.pinnedOffline,
          i.description,
        ),
  };

  @override
  Future<void> dispose() => h.dispose();
}
