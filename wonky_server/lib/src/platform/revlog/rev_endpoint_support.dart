import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/roles.dart';
import '../sharing/access_service.dart';
import 'rev_binding.dart';
import 'rev_legacy_files.dart';
import 'rev_log_connection.dart';
import 'rev_pages.dart';
import 'rev_views.dart';

/// The shared bodies of the app endpoints `<app>Doc.page/ops/info`
/// (RevLog spec 04 §1, 05 §11).
abstract final class RevEndpointSupport {
  static Future<(RevFile, DriveItem, Role)> _file(
    Session session,
    RevBinding binding,
    Actor actor,
    UuidValue fileUuid,
  ) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    if (file == null) {
      await RevLegacyFiles.removeIfLegacy(session, binding, actor, fileUuid);
    }
    if (file == null || file.purging || file.kind != binding.kind) {
      throw Errors.notFound('File');
    }
    final item = await DriveItem.db.findById(session, file.itemId);
    if (item == null) throw Errors.notFound('File');
    final role = await AccessService.requireRole(
      session,
      actor,
      item,
      Role.viewer,
    );
    return (file, item, role);
  }

  /// A bootstrap page (Viewer+).
  static Future<RevPage> page(
    Session session,
    RevBinding binding,
    Actor actor,
    UuidValue fileUuid,
    RevPageRequest request,
  ) async {
    final (file, _, _) = await _file(session, binding, actor, fileUuid);
    try {
      return await RevPages.page(session, binding, file, request);
    } on ArgumentError catch (e) {
      throw Errors.invalid('${e.message}');
    }
  }

  /// Ops in (from, to] (Viewer+ within the last 1,000 revisions).
  static Future<List<RevOpView>> ops(
    Session session,
    RevBinding binding,
    Actor actor,
    UuidValue fileUuid,
    int fromRevision,
    int toRevision,
  ) async {
    final (file, _, role) = await _file(session, binding, actor, fileUuid);
    final from = fromRevision + 1;
    final to = toRevision > file.headRevision ? file.headRevision : toRevision;
    if (to < from) return const [];
    if (from < RevLogConnection.oldestOpFor(role, file.headRevision)) {
      throw Errors.forbidden('Older history needs edit access.');
    }
    return RevViews.read(session, binding.codec, file.id!, from, to);
  }

  /// Head revision, role and stats (Viewer+).
  static Future<RevFileInfo> info(
    Session session,
    RevBinding binding,
    Actor actor,
    UuidValue fileUuid,
  ) async {
    final (file, _, role) = await _file(session, binding, actor, fileUuid);
    return RevFileInfo(
      fileUuid: fileUuid,
      revision: file.headRevision,
      role: role.access,
      schemaHash: binding.schema.hash,
      stats: file.stats,
    );
  }
}
