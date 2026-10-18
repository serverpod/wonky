import '../rows/row_change.dart';

/// One op: the unit of submission, sequencing and acknowledgement (RevLog
/// spec 03 §2). [changes] are ordered: parents first for inserts/updates,
/// children first for deletes.
final class ChangeSet {
  /// Creates a change set.
  ChangeSet({
    required this.clientOpId,
    required this.baseRevision,
    required List<RowChange> changes,
    this.label = '',
    this.actorKind = 'user',
    this.summary,
    this.detail,
    this.groupId,
    this.groupIndex = 0,
    this.groupLast = true,
    this.offline = false,
    DateTime? createdAt,
  }) : changes = List.unmodifiable(changes),
       createdAt = (createdAt ?? DateTime.now()).toUtc();

  /// Idempotency key (UUIDv7), reused on every resend.
  final String clientOpId;

  /// The client's server revision when the op was cut.
  final int baseRevision;

  /// Row changes.
  final List<RowChange> changes;

  /// Undo label ("Paste"); empty for maintenance.
  final String label;

  /// `user`, `mcp`, `ai`, `script` or `system`.
  final String actorKind;

  /// Change summary JSON object (kinds, sheets, ranges, deleted, …).
  final Map<String, Object?>? summary;

  /// Cell details (≤ 200) for history, or null.
  final Map<String, Object?>? detail;

  /// Chunk group of one plan (RD-21).
  final String? groupId;

  /// Position in the group.
  final int groupIndex;

  /// Whether this is the group's last op.
  final bool groupLast;

  /// Whether any change was made while disconnected.
  final bool offline;

  /// Client clock of the first change (display only).
  final DateTime createdAt;

  /// Whether the summary marks a client repair (03 §6).
  bool get isRepair => summary?['repair'] == true;

  /// A copy with other fields.
  ChangeSet copyWith({
    String? clientOpId,
    int? baseRevision,
    List<RowChange>? changes,
    String? label,
    Map<String, Object?>? summary,
    Map<String, Object?>? detail,
    bool clearDetail = false,
    String? groupId,
    int? groupIndex,
    bool? groupLast,
    bool? offline,
  }) => ChangeSet(
    clientOpId: clientOpId ?? this.clientOpId,
    baseRevision: baseRevision ?? this.baseRevision,
    changes: changes ?? this.changes,
    label: label ?? this.label,
    actorKind: actorKind,
    summary: summary ?? this.summary,
    detail: clearDetail ? null : (detail ?? this.detail),
    groupId: groupId ?? this.groupId,
    groupIndex: groupIndex ?? this.groupIndex,
    groupLast: groupLast ?? this.groupLast,
    offline: offline ?? this.offline,
    createdAt: createdAt,
  );

  @override
  String toString() =>
      'ChangeSet($clientOpId base=$baseRevision ${changes.length} changes'
      '${groupId == null ? '' : ' group=$groupId#$groupIndex${groupLast ? '!' : ''}'})';
}
