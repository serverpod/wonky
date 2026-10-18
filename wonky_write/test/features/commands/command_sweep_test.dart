import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write/commands/screen_commands.dart';
import 'package:wonky_write/features/screen/write_document_controller.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

/// Suite 08 §4 (Write 04 §43): every registered `write.*` command, executed
/// headless on a small document (a heading, a paragraph with "Hello"
/// selected, a bullet item), then undone and redone; the document and its
/// metadata must match before and after.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Given every Write command when it runs, is undone and redone then '
    'the document round-trips and nothing changes without an undo step',
    () async {
      final probe = await _WriteFixture.open();
      final commands = [
        for (final c in writeCommands(
          (probe as _WriteFixture).h.services,
          WriteThemeCatalog(),
        ))
          if (c.id.value.startsWith('write.')) c,
      ]..sort((a, b) => a.id.value.compareTo(b.id.value));
      await probe.dispose();

      final report = await sweepCommands(
        commands: commands,
        open: _WriteFixture.open,
        args: _args,
        skip: const {
          'write.edit.undo': 'undo itself',
          'write.edit.redo': 'redo itself',
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
const _minRoundTrips = 31;

/// Arguments for commands whose sampled ones do not fit the fixture.
const _args = <String, Map<String, Object?>>{};

class _WriteFixture implements SweepFixture {
  _WriteFixture(this.h, this.doc);

  final SessionHarness h;
  final WriteDocumentController doc;

  static Future<SweepFixture> open() async {
    final server = FakeDocumentServer(
      initial: Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('Hello colour world, colour\n')
        ..insert('item')
        ..insert('\n', {'list': 'bullet'}),
    );
    final h = SessionHarness(server);
    await h.open();
    final catalog = WriteThemeCatalog();
    h.services.registry.registerAll(writeCommands(h.services, catalog));
    final doc = WriteDocumentController(
      services: h.services,
      session: h.session,
      themes: catalog,
    );
    h.services.activate(doc);
    await pumpEventQueue();
    doc.editor.select(const DeltaSelection(6, 11));
    return _WriteFixture(h, doc);
  }

  @override
  Future<CommandResult> invoke(String id, Map<String, Object?> args) async {
    final r = await h.services.dispatcher.invoke(
      id,
      args: args,
      source: InvocationSource.ui,
    );
    await pumpEventQueue();
    return r;
  }

  @override
  Future<void> undo() async {
    await h.undo.undo();
    await pumpEventQueue();
  }

  @override
  Future<void> redo() async {
    await h.undo.redo();
    await pumpEventQueue();
  }

  @override
  int get undoSteps => h.undo.history().length;

  @override
  Object? snapshot() =>
      (jsonEncode(h.session.editor.delta.toJson()), h.session.meta.value);

  @override
  Future<void> dispose() async {
    h.services.deactivate(doc);
    doc.dispose();
    await h.dispose();
  }
}
