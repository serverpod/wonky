import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import 'file_preview_service.dart';

/// Generates the server preview and thumbnail of an uploaded image right
/// after its upload completed (Drive 02 §6.2).
class FilePreviewFutureCall extends FutureCall {
  Future<void> generate(Session session, int itemId) => runGuarded(
    session,
    'File preview $itemId',
    () => FilePreviewService.generate(session, itemId),
  );
}
