import 'package:serverpod/serverpod.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/config/wonky_config.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_rev_binding.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_revlog.dart';
import 'package:wonky_server/src/sheets/scripts/script_limits.dart';
import 'package:wonky_server/src/sheets/scripts/script_service.dart';
import 'package:wonky_server/src/sheets/scripts/script_triggers.dart';
import 'package:wonky_sheets_script/native.dart';

/// Turns scripting on for a test group (config/test.yaml keeps it off) and
/// runs change-triggered work inline. The RevLog hooks (script compiles and
/// edit triggers) run only when a test drains them ([drainHooks]).
void enableScripting() {
  WonkyConfig.current = WonkyConfig(
    scriptingEnabled: true,
    scriptServerTimeoutMs: 20000,
  );
  SheetsRevlog.register();
  RevHooks.debounce = const Duration(hours: 1);
  ScriptTriggerService.runInline = true;
  ScriptRateLimiter.compiles.reset();
  ScriptRateLimiter.analyses.reset();
  ScriptFetchCache.instance.clear();
  ScriptService.runnerOverride ??= IsolateScriptRunner();
}

/// Undoes [enableScripting].
Future<void> disableScripting() async {
  await RevHooks.idle();
  await ScriptService.runnerOverride?.close();
  ScriptService.runnerOverride = null;
  ScriptService.proxyOverride = null;
  ScriptTriggerService.runInline = false;
  WonkyConfig.current = WonkyConfig();
  HeadlessWorkbookProvider.clear();
}

/// Runs the pending RevLog hooks of the spreadsheet [fileUuid] now.
Future<void> drainHooks(Session session, UuidValue fileUuid) async {
  final file = await RevFile.db.findFirstRow(
    session,
    where: (t) => t.fileUuid.equals(fileUuid),
  );
  await RevHooks.drainNow(
    session.serverpod,
    SheetsRevBinding.instance,
    file!.id!,
    session: session,
  );
}

/// The space uuid of a drive item uuid string.
UuidValue uuidOf(String s) => UuidValue.fromString(s);
