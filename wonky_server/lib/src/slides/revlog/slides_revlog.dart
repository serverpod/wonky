import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;

import '../../platform/comments/comment_service.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/revlog/headless_file_cache.dart';
import '../../platform/revlog/rev_hooks.dart';
import '../../platform/storage/content_sizes.dart';
import 'deck_comments.dart';
import 'slides_rev_binding.dart';

/// Startup registration of the deck RevLog binding (RevLog spec 05 §1, 08)
/// and the headless decks of the server (05 §9).
abstract final class SlidesRevlog {
  static bool _registered = false;

  /// Registers the binding with the hook runner, the deck size estimator
  /// (Drive 03 §2) and the comment notification extras (09 §3.6).
  /// Idempotent; called at server start and by tests.
  static void register() {
    final binding = SlidesRevBinding.instance;
    RevHooks.bindings[RevFileKind.deck] = binding;
    if (_registered) return;
    _registered = true;
    ContentSizes.register(
      DriveItemKind.presentation,
      RevFileSizeEstimator([for (final t in binding.schema.tables) t.name]),
    );
    CommentService.payloadExtras[DriveItemKind.presentation] =
        DeckCommentPayload.extras;
  }

  /// The headless deck of [fileUuid] at the current head (05 §9; loaded on
  /// first use, then it follows the file's ops). Throws `notFound` for a
  /// missing deck. The model is live: plan against it under the file lock
  /// (`RevLogService.submitServerChange` does).
  static Future<DeckModel> model(Session session, UuidValue fileUuid) async {
    final lease = await HeadlessFileCache.open(
      session,
      SlidesRevBinding.instance,
      fileUuid,
    );
    if (lease == null) throw Errors.notFound('Presentation');
    try {
      final file = await RevFile.db.findFirstRow(
        session,
        where: (t) => t.fileUuid.equals(fileUuid),
      );
      if (file != null) await lease.ensureAtLeast(session, file.headRevision);
      final deck = lease.model as DeckModel;
      if (deck.deck == null) throw Errors.notFound('Presentation');
      return deck;
    } finally {
      lease.release();
    }
  }

  /// The head revision of the deck [fileUuid] (MCP `sync_version`; 0 when
  /// the file is missing).
  static Future<int> headRevision(Session session, UuidValue fileUuid) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    return file?.headRevision ?? 0;
  }
}
