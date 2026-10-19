import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_drive/config/drive_app_config.dart';

/// Suite 08 §4: every registered `drive.*` command, executed headless on a
/// small drive (a folder and a selected document in it, the home list
/// open), then undone and redone; the drive must match before and after.
/// Most Drive commands are view, settings and upload-queue commands that
/// are not undoable (08 §2): the sweep checks they change no item.
void main() {
  test(
    'Given every Drive command when it runs, is undone and redone then '
    'the drive round-trips and nothing changes without an undo step',
    () async {
      final probe = _DriveFixture.harness();
      final commands = [
        for (final c in probe.services.registry.all)
          if (c.id.value.startsWith('drive.')) c,
      ]..sort((a, b) => a.id.value.compareTo(b.id.value));
      await probe.dispose();

      final report = await sweepCommands(
        commands: commands,
        open: _DriveFixture.open,
      );

      printOnFailure(report.describe());
      expect(report.violations, isEmpty);
      // Ran headless (preview and upload commands need an open preview or
      // queue: their own tests cover them, e.g. the upload batch undo).
      expect(
        report.idsWith(SweepOutcome.noChange).length +
            report.idsWith(SweepOutcome.roundTrip).length,
        greaterThanOrEqualTo(4),
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

class _DriveFixture implements SweepFixture {
  _DriveFixture(this.h, this.list);

  final CommandTestHarness h;
  final DriveController list;

  static CommandTestHarness harness() {
    final h = CommandTestHarness(config: const DriveAppConfig());
    h.services.router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (c, s) => const SizedBox()),
        GoRoute(path: '/storage', builder: (c, s) => const SizedBox()),
      ],
    );
    return h;
  }

  static Future<SweepFixture> open() async {
    final h = harness();
    final folder = h.drive.seed(name: 'Projects', kind: DriveItemKind.folder);
    final doc = h.drive.seed(name: 'Plan', parentUuid: folder.uuid);
    final list = DriveController(
      services: h.services,
      location: const DriveLocation.myDrive(),
    );
    h.services.driveSelection.value = [doc];
    return _DriveFixture(h, list);
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

  /// The items not in the trash, without server timestamps.
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
  Future<void> dispose() async {
    list.dispose();
    await h.dispose();
  }
}
