import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/features/canvas/slide_canvas_controller.dart';

import '../features/canvas/canvas_rig.dart' show CanvasFixture;
import '../harness/deck_harness.dart';

/// Suite 08 §4: every registered `slides.*` command, executed headless on
/// the canvas fixture (shapes, a group, a locked shape; one shape
/// selected), then undone and redone; the deck rows must match before and
/// after.
void main() {
  test('Given every Slides command when it runs, is undone and redone then '
      'the rows round-trip and nothing changes without an undo step', () async {
    final probe = DeckHarness.open();
    final commands = [
      for (final c in probe.services.registry.all)
        if (c.id.value.startsWith('slides.')) c,
    ]..sort((a, b) => a.id.value.compareTo(b.id.value));
    await probe.dispose();

    final report = await sweepCommands(
      commands: commands,
      open: _SlidesFixture.open,
      args: _args,
      skip: const {
        'slides.edit.undo': 'undo itself',
        'slides.edit.redo': 'redo itself',
      },
    );

    printOnFailure(report.describe());
    expect(report.violations, isEmpty);
    expect(
      report.idsWith(SweepOutcome.roundTrip).length,
      greaterThanOrEqualTo(_minRoundTrips),
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Commands covered by a full round trip (raise it when adding arguments).
const _minRoundTrips = 51;

/// Arguments for commands whose sampled ones do not fit the fixture.
const _args = <String, Map<String, Object?>>{};

class _SlidesFixture implements SweepFixture {
  _SlidesFixture(this.d);

  final DeckHarness d;

  static Future<SweepFixture> open() async {
    final f = CanvasFixture();
    final d = DeckHarness.open(fixture: f.b);
    d.editor.setCurrentSlide(f.slide);
    selectionOf(d.editor).select([f.a]);
    return _SlidesFixture(d);
  }

  @override
  Future<CommandResult> invoke(String id, Map<String, Object?> args) =>
      d.run(id, args);

  @override
  Future<void> undo() async => d.undo();

  @override
  Future<void> redo() async => d.redo();

  @override
  int get undoSteps => d.undoLabels.length;

  @override
  Object? snapshot() => d.model.dump();

  @override
  Future<void> dispose() => d.dispose();
}
