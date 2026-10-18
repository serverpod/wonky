import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:wonky_server/src/platform/common/models.dart';

/// Unsaved board rows for board AI tests.
abstract final class BoardAiBuilders {
  static final _at = DateTime.utc(2026, 10, 15, 12);

  static BoardPost post({
    int? id = 1,
    BoardPostKind kind = BoardPostKind.bug,
    String title = 'Paste into merged cells drops styles',
    String body = 'When I paste a range into merged cells, bold is lost.',
    String appHint = 'sheets',
    BoardArea? area,
    BoardSize? size,
    String? summary,
    String? contextJson,
    int? screenshotFileId,
  }) => BoardPost(
    id: id,
    kind: kind,
    reportedKind: kind,
    area: area,
    size: size,
    title: title,
    body: body,
    appHint: appHint,
    summary: summary,
    contextJson: contextJson,
    screenshotFileId: screenshotFileId,
    status: BoardPostStatus.open,
    moderation: BoardModeration.visible,
    triageState: BoardTriageState.pending,
    createdAt: _at,
  );

  static BoardTask task({
    int? id = 12,
    String title = 'Keep styles when pasting into merged cells',
    BoardArea area = BoardArea.sheets,
    BoardSize size = BoardSize.small,
  }) => BoardTask(
    id: id,
    title: title,
    area: area,
    size: size,
    status: BoardTaskStatus.draft,
    promptBody: '',
    createdById: 1,
    createdAt: _at,
  );

  static BoardComment comment(
    int postId,
    String body, {
    BoardModeration moderation = BoardModeration.visible,
    String? systemEvent,
  }) => BoardComment(
    uuid: UuidValue.fromString('0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b'),
    postId: postId,
    body: body,
    systemEvent: systemEvent,
    moderation: moderation,
    createdAt: _at,
  );
}
