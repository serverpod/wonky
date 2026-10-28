import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import 'document_cache.dart';
import 'ot_service.dart';

/// Upgrades the legacy `table` and `grid` embeds of a Write document to
/// cell and grid item lines (Write 12 §1.5).
///
/// The upgrade is committed as a system op (`actorKind: system`,
/// `kind: system`, no author) through [OtService.submit], so it bumps the
/// revision, is broadcast to connected clients as an ordinary remote op and
/// shows in the history as the system's. It runs when a document's state
/// is loaded ([DocumentCache.of]) and after every committed op whose result
/// still holds a legacy embed (an old client, a restored version).
///
/// The change is computed from the head under the document lock and must
/// commit at exactly that head (`atHead`): a concurrent op (or an upgrade on
/// another instance) makes it retry from the new head, so two upgrades of
/// the same embed never both commit. Once the head holds no legacy embed,
/// nothing is committed: loading again or committing again is a no-op.
abstract final class CellUpgrader {
  /// What the upgrade is called in logs (Write 12 §1.5).
  static const label = 'Upgrade tables';

  /// Attempts before giving up when other ops keep landing in between.
  static const maxAttempts = 5;

  /// Queues an upgrade of [document] after the earlier ones of [state];
  /// completes when it ran (committed or found nothing to do). Never
  /// throws: failures are logged.
  static Future<void> schedule(
    Session session,
    Document document,
    DocumentState state, {
    DriveItem? item,
  }) => state.runUpgrade(() => _run(session, document, state, item));

  static Future<void> _run(
    Session session,
    Document document,
    DocumentState state,
    DriveItem? item,
  ) async {
    if (state.upgradeBlocked) return;
    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final fresh = await Document.db.findById(session, document.id!);
        if (fresh == null) return;
        final (change, base, legacy) = await state.lock(() async {
          await state.catchUp(session, fresh.headRevision);
          final content = state.content;
          return (
            CellUpgrade.upgradeChange(content),
            state.revision,
            CellUpgrade.hasLegacy(content),
          );
        });
        if (change == null) {
          // Embeds that cannot be parsed stay; don't look again.
          if (legacy) state.upgradeBlocked = true;
          return;
        }
        item ??= await DriveItem.db.findById(session, document.itemId);
        if (item == null) return;
        final owner = await UserProfile.db.findById(session, item.ownerId);
        if (owner == null) return;
        try {
          final committed = await OtService.submit(
            session,
            // The owner stands in for the system where a user is needed
            // (overlay lifecycle); the op itself has no author.
            actor: Actor(
              userId: owner.id!,
              authUserId: owner.authUserId,
              kind: ActorKind.system,
            ),
            document: document,
            item: item,
            role: Role.owner,
            clientOpId: const Uuid().v7obj(),
            baseRevision: base,
            deltaJson: jsonEncode(change.toJson()),
            kind: DocumentOpKind.system,
            atHead: true,
            enforceOpLimits: false,
            // Not settle(): it waits for this upgrade.
            awaitSideEffects: false,
          );
          await committed.sideEffects;
          session.log(
            '$label: ${document.uuid} r${committed.revision}',
            level: LogLevel.info,
          );
          return;
        } on OpRejection catch (r) {
          if (r.code == DocRejectCode.rebaseTooOld) continue;
          state.upgradeBlocked = true;
          session.log(
            '$label of ${document.uuid} was rejected: ${r.message}',
            level: LogLevel.warning,
          );
          return;
        }
      }
      session.log(
        '$label of ${document.uuid}: the document kept changing, '
        'gave up after $maxAttempts attempts.',
        level: LogLevel.warning,
      );
    } on Object catch (e, st) {
      session.log(
        '$label of ${document.uuid} failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    }
  }
}
