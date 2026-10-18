import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/ai/ai_preview_records.dart';
import '../../platform/common/models.dart';
import '../mcp/sheets_shadow.dart';

/// One call of an AI changes preview as needed to apply it.
class PreviewCallChanges {
  PreviewCallChanges(this.changes, this.kinds);

  final List<RowChange> changes;
  final Set<String> kinds;
}

/// A Suggest-mode preview read from the database: what the dialog shows
/// plus the recorded row changes per call.
class StoredAiPreview {
  StoredAiPreview({
    required this.previewId,
    required this.userId,
    required this.space,
    required this.preview,
    required this.calls,
  });

  final String previewId;
  final int userId;
  final UuidValue space;
  final SheetsAiPreview preview;
  final Map<String, PreviewCallChanges> calls;
}

/// Persists Suggest-mode previews (Sheets 12 §6.3) so that the instance
/// serving `sheetsAi.getPreview` / `applyPreview` / `discardPreview` need
/// not be the one that ran the assistant (the in-memory [SheetsShadows]
/// are only a fast path). Rows expire with the preview (30 min) and are
/// purged on the next save.
abstract final class SheetsAiPreviewStore {
  /// Previews whose encoded changes are larger stay in memory only.
  static const maxBytes = AiPreviewRecords.maxBytes;

  /// Stores [preview] of [shadow].
  static Future<void> save(
    Session session,
    SheetsShadow shadow,
    SheetsAiPreview preview,
  ) async {
    await AiPreviewRecords.save(
      session,
      previewId: shadow.previewId,
      userId: shadow.userId,
      fileUuid: shadow.space,
      previewJson: jsonEncode(preview.toJson()),
      changesJson: AiPreviewRecords.encode({
        for (final c in shadow.calls)
          c.callId: {
            'kinds': c.kinds.toList(),
            'changes': [for (final r in c.changes) r.toJson()],
          },
      }),
      createdAt: shadow.createdAt,
      expiresAt: preview.expiresAt,
    );
  }

  /// The stored preview [previewId] (null when unknown or expired).
  static Future<StoredAiPreview?> load(
    Session session,
    String previewId,
  ) async {
    final row = await AiPreviewRecords.load(session, previewId);
    if (row == null) return null;
    final decoded = AiPreviewRecords.decode(row.changesJson)! as Map;
    return StoredAiPreview(
      previewId: row.previewId,
      userId: row.userId,
      space: row.fileUuid,
      preview: SheetsAiPreview.fromJson(
        (jsonDecode(row.previewJson) as Map).cast<String, dynamic>(),
      ),
      calls: {
        for (final e in decoded.entries)
          '${e.key}': PreviewCallChanges(
            [
              for (final c in (e.value as Map)['changes'] as List)
                RowChange.fromJson((c as Map).cast<String, Object?>()),
            ],
            {...((e.value as Map)['kinds'] as List).cast<String>()},
          ),
      },
    );
  }

  /// Deletes the stored preview [previewId].
  static Future<void> delete(Session session, String previewId) =>
      AiPreviewRecords.delete(session, previewId);
}
