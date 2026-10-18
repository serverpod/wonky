import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../files/file_service.dart';
import 'rev_views.dart';

/// The revertible server changes of RevLog files (RevLog spec 05 §8.2),
/// shared by Sheets and Slides (CQ-52): a [ServerChangeRecord] names the
/// ops of one change by their `recordId`; revert and reapply read the ops'
/// applied forms (with `before`) through the app's [RevCodec].
abstract final class ServerChangeRecords {
  /// Stores the record of the ops of [recordId] on the file [fileUuid] and
  /// returns its change id.
  static Future<UuidValue> store(
    Session session, {
    required Actor actor,
    required UuidValue fileUuid,
    required String label,
    required UuidValue recordId,
    required int cellsAffected,
    Duration lifetime = const Duration(hours: 24),
    Transaction? transaction,
  }) async {
    final changeId = const Uuid().v7obj();
    final now = nowUtc();
    await ServerChangeRecord.db.insertRow(
      session,
      ServerChangeRecord(
        changeId: changeId,
        fileUuid: fileUuid,
        userId: actor.userId,
        actorKind: actor.kind,
        label: label,
        recordId: recordId,
        cellsAffected: cellsAffected,
        createdAt: now,
        expiresAt: now.add(lifetime),
      ),
      transaction: transaction,
    );
    return changeId;
  }

  /// The record [changeId] (with [orRevert], first the record whose revert
  /// is [changeId]), or null.
  static Future<ServerChangeRecord?> find(
    Session session,
    UuidValue changeId, {
    bool orRevert = false,
  }) async =>
      (orRevert
          ? await ServerChangeRecord.db.findFirstRow(
              session,
              where: (t) => t.revertChangeId.equals(changeId),
            )
          : null) ??
      await ServerChangeRecord.db.findFirstRow(
        session,
        where: (t) => t.changeId.equals(changeId),
      );

  /// Throws `expired` when [record] can no longer be undone.
  static void requireLive(ServerChangeRecord record) {
    if (record.expiresAt.isBefore(nowUtc())) {
      throw Errors.expired('The change can no longer be undone.');
    }
  }

  /// The forward changes of [record]: the applied forms (with `before`) of
  /// its ops in revision order (empty once pruned or for legacy records).
  static Future<List<RowChange>> forward(
    Session session,
    RevCodec codec,
    ServerChangeRecord record,
  ) async {
    final recordId = record.recordId;
    if (recordId == null) return const [];
    final ops = await RevOp.db.find(
      session,
      where: (t) => t.recordId.equals(recordId),
      orderBy: (t) => t.revision,
    );
    return [
      for (final o in ops)
        if (o.payload != null) ...RevViews.decodeStored(codec, o.payload!),
    ];
  }

  /// The inverse changes of [record] (reverse order).
  static Future<List<RowChange>> inverse(
    Session session,
    RevCodec codec,
    ServerChangeRecord record,
  ) async => [
    for (final c in (await forward(session, codec, record)).reversed)
      c.inverse(),
  ];

  /// Marks [record] reverted by the change [revertId].
  static Future<void> markReverted(
    Session session,
    ServerChangeRecord record,
    UuidValue revertId,
  ) async {
    await ServerChangeRecord.db.updateRow(
      session,
      record.copyWith(revertedAt: nowUtc(), revertChangeId: revertId),
      columns: (t) => [t.revertedAt, t.revertChangeId],
    );
  }

  /// Joins the records [changeIds] of the file [fileUuid] into one record
  /// labeled [label] (one undo step for an assistant run): their ops move
  /// to a new record id, so reverting it reverts all of them, and the
  /// component records are removed. Returns the composite change id (the
  /// single id when there is one; null when none was recorded).
  static Future<UuidValue?> composite(
    Session session, {
    required Actor actor,
    required UuidValue fileUuid,
    required List<String> changeIds,
    required String label,
    Duration lifetime = const Duration(hours: 24),
  }) async {
    final ids = {
      for (final c in changeIds)
        if (UuidValue.withValidation(c) case final UuidValue u) u,
    };
    if (ids.length < 2) return ids.isEmpty ? null : ids.first;
    final records = await ServerChangeRecord.db.find(
      session,
      where: (t) => t.changeId.inSet(ids) & t.fileUuid.equals(fileUuid),
    );
    final recordIds = [
      for (final r in records)
        if (r.recordId != null) r.recordId!.uuid,
    ];
    if (recordIds.isEmpty) return null;
    final recordId = const Uuid().v7obj();
    return session.db.transaction((tx) async {
      await session.db.unsafeExecute(
        'UPDATE rev_op SET "recordId" = @r::uuid '
        'WHERE "recordId" = ANY(@old::uuid[])',
        parameters: QueryParameters.named({
          'r': recordId.uuid,
          'old': recordIds,
        }),
        transaction: tx,
      );
      await ServerChangeRecord.db.deleteWhere(
        session,
        where: (t) => t.id.inSet(<int>{for (final r in records) r.id!}),
        transaction: tx,
      );
      return store(
        session,
        actor: actor,
        fileUuid: fileUuid,
        label: label,
        recordId: recordId,
        cellsAffected: records.fold(0, (n, r) => n + r.cellsAffected),
        lifetime: lifetime,
        transaction: tx,
      );
    });
  }

  /// Daily job: deletes expired records (and the files of legacy ones), at
  /// most 1,000 per call; returns the count.
  static Future<int> purgeExpired(Session session, {DateTime? now}) async {
    final at = now ?? nowUtc();
    final expired = await ServerChangeRecord.db.find(
      session,
      where: (t) => t.expiresAt < at,
      limit: 1000,
    );
    for (final r in expired) {
      if (r.inverseFileId != null) {
        await FileService.deleteFile(session, r.inverseFileId!);
      }
      if (r.forwardFileId != null) {
        await FileService.deleteFile(session, r.forwardFileId!);
      }
      await ServerChangeRecord.db.deleteRow(session, r);
    }
    return expired.length;
  }
}
