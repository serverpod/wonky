import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/model.dart' show SheetsTables;

import '../../platform/common/models.dart';
import '../../platform/revlog/headless_file_cache.dart';
import '../../platform/revlog/rev_binding.dart';
import '../../platform/revlog/rev_file_state.dart';
import '../../platform/revlog/rev_hooks.dart';
import '../../platform/revlog/rev_log_connection.dart';
import 'sheets_rev_binding.dart';

/// Startup registration of the spreadsheet RevLog binding (RevLog spec 05
/// §1, §3.5).
abstract final class SheetsRevlog {
  /// Registers the binding with the hook runner and the connection warm-up.
  static void register() {
    final binding = SheetsRevBinding.instance;
    RevHooks.bindings[RevFileKind.spreadsheet] = binding;
    RevLogConnection.warmers[RevFileKind.spreadsheet] = _warm;
  }

  /// An editor's connection to a file with protections keeps its headless
  /// model loaded, so the protection check of the first op doesn't pay the
  /// load under the file lock.
  static Future<void Function()?> _warm(
    Session session,
    RevFileState state,
    Role role,
  ) async {
    if (role < Role.editor) return null;
    final file = await RevFile.db.findById(session, state.fileId);
    if (file == null) return null;
    final stats = RevStats.parse(file.stats);
    if ((stats.tables[SheetsTables.protectedRange] ?? 0) == 0) return null;
    final lease = await HeadlessFileCache.open(
      session,
      SheetsRevBinding.instance,
      state.fileUuid,
    );
    return lease?.release;
  }
}
