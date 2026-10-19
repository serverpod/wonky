import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/revlog/headless_file_cache.dart';
import '../headless/headless_workbook.dart';

/// One mutating tool call recorded in a [SheetsShadow] (AI Suggest mode,
/// Sheets 12 §6.3).
class ShadowCall {
  ShadowCall({
    required this.callId,
    required this.toolName,
    required this.label,
    required this.changes,
    required this.ranges,
    required this.cellsAffected,
    required this.kinds,
    this.structural,
  });

  final String callId;
  final String toolName;
  final String label;

  /// The planned row changes (against the shadow state before the call).
  final List<RowChange> changes;

  /// A1 ranges the call wrote.
  final List<String> ranges;
  final int cellsAffected;
  final Set<String> kinds;

  /// A text description of structure changes ("Inserted 3 rows").
  final String? structural;
}

/// A private overlay of a spreadsheet for the assistant's Suggest mode
/// (Sheets 12 §6.3): mutating tool calls are planned against [wb] (a copy
/// of the headless workbook) and recorded instead of committed, so
/// multi-step plans see their own results. The client shows the recorded
/// calls in the AI changes preview and applies the selected ones.
///
/// Memory (CQ-35): one copy while the run records; the "before" state
/// ([base]) is rebuilt only when a preview needs it, from [wb] and the
/// inverse of the recorded changes, and both copies are counted in the
/// headless cache budget (`HeadlessFileCache.reserveExternal`).
class SheetsShadow {
  SheetsShadow._(this.previewId, this.space, this.userId, this.wb) {
    HeadlessFileCache.reserveExternal(this, wb.estimatedBytes);
  }

  /// Creates a shadow of [source] for [userId].
  factory SheetsShadow.of(
    HeadlessWorkbook source, {
    required String previewId,
    required int userId,
  }) {
    final copy = WorkbookModel.fromRows(
      source.model.spreadsheetId,
      source.model.allRows().toList(),
    );
    final wb = HeadlessWorkbook(
      space: source.space,
      model: copy,
      watermark: source.watermark,
      estimatedBytes: source.estimatedBytes,
    );
    return SheetsShadow._(previewId, source.space, userId, wb);
  }

  final String previewId;
  final UuidValue space;
  final int userId;

  /// The shadow state (all recorded calls applied).
  final HeadlessWorkbook wb;

  HeadlessWorkbook? _base;

  /// The state when the shadow was created (before → after previews):
  /// built on first use from [wb] with the recorded calls undone.
  HeadlessWorkbook get base => _base ??= _buildBase();

  HeadlessWorkbook _buildBase() {
    final model = WorkbookModel.fromRows(
      wb.model.spreadsheetId,
      wb.model.allRows().toList(),
    );
    model.applyChanges([
      for (final call in calls.reversed)
        for (final c in call.changes.reversed) c.inverse(),
    ]);
    final base = HeadlessWorkbook(
      space: space,
      model: model,
      watermark: wb.watermark,
      estimatedBytes: wb.estimatedBytes,
    );
    HeadlessFileCache.reserveExternal(this, wb.estimatedBytes * 2);
    return base;
  }

  final DateTime createdAt = clock.now();
  final List<ShadowCall> calls = [];

  /// The id of the next recorded call.
  String nextCallId() => 'c${calls.length + 1}';

  void dispose() {
    wb.dispose();
    _base?.dispose();
    HeadlessFileCache.releaseExternal(this);
  }
}

/// The open shadows by assistant run (`ToolContext.groupId`) and by
/// preview id (Sheets 12 §6.3: plans expire after 30 min).
abstract final class SheetsShadows {
  static Duration lifetime = const Duration(minutes: 30);

  static final Map<String, SheetsShadow> _byGroup = {};
  static final Map<String, SheetsShadow> _byPreview = {};

  /// Starts recording the Suggest-mode run [groupId] on [source].
  static SheetsShadow begin(
    String groupId,
    HeadlessWorkbook source, {
    required int userId,
  }) {
    _expire();
    final shadow = SheetsShadow.of(source, previewId: groupId, userId: userId);
    _byGroup[groupId] = shadow;
    _byPreview[shadow.previewId] = shadow;
    return shadow;
  }

  /// The shadow mutating tool calls of run [groupId] write into, or null
  /// (Edit mode, MCP).
  static SheetsShadow? forGroup(String? groupId) =>
      groupId == null ? null : _byGroup[groupId];

  /// Ends recording for [groupId]; the shadow stays available as a preview
  /// until it is applied, discarded or expires. Returns it when it has
  /// recorded calls (else it is discarded).
  static SheetsShadow? end(String groupId) {
    final s = _byGroup.remove(groupId);
    if (s == null) return null;
    if (s.calls.isEmpty) {
      _byPreview.remove(s.previewId);
      s.dispose();
      return null;
    }
    return s;
  }

  /// The preview [previewId] (null when unknown or expired).
  static SheetsShadow? preview(String previewId) {
    _expire();
    return _byPreview[previewId];
  }

  /// Discards a preview.
  static void discard(String previewId) {
    final s = _byPreview.remove(previewId);
    if (s == null) return;
    _byGroup.removeWhere((_, v) => identical(v, s));
    s.dispose();
  }

  static void _expire() {
    final now = clock.now();
    for (final s in _byPreview.values.toList()) {
      if (now.difference(s.createdAt) > lifetime) discard(s.previewId);
    }
  }

  /// Drops everything (tests).
  static void clear() {
    for (final id in _byPreview.keys.toList()) {
      discard(id);
    }
    _byGroup.clear();
  }
}
