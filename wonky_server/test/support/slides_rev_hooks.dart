import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/slides/revlog/slides_rev_binding.dart';
import 'package:wonky_server/src/slides/revlog/slides_revlog.dart';

/// Post-commit hooks of decks in tests (RevLog spec 09 §3): the binding is
/// registered, debounced drains are off and tests drain explicitly, so
/// activity, versions, drive edits, titles, search text and comment
/// orphans are deterministic.
abstract final class SlidesRevHooks {
  /// Registers the binding and turns off debounced drains (call in a group
  /// body); waits for running drains after each test.
  static void install() {
    setUpAll(() {
      SlidesRevlog.register();
      RevHooks.debounce = const Duration(hours: 1);
    });
    tearDown(RevHooks.idle);
  }

  /// Runs the pending hooks of the deck [fileUuid] (its root id,
  /// `DriveItem.contentRef`) now.
  static Future<void> drain(Session session, UuidValue fileUuid) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    if (file == null) return;
    await RevHooks.drainNow(
      session.serverpod,
      SlidesRevBinding.instance,
      file.id!,
      session: session,
    );
  }

  /// [drain] for a drive item uuid (as MCP tools return it).
  static Future<void> drainItem(Session session, UuidValue itemUuid) async {
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(itemUuid),
    );
    final ref = item?.contentRef;
    if (ref != null) await drain(session, ref);
  }
}
