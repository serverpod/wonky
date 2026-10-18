import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';

import '../common/models.dart';

/// Reading and building [RevOpView]s (RevLog spec 04 §2.3).
abstract final class RevViews {
  /// Payloads up to this size travel as text, bigger ones gzipped.
  static const compressAboveBytes = 16384;

  /// Max ops per read (04 §1).
  static const maxOps = 1000;

  /// Max compressed bytes per read (04 §1).
  static const maxBytes = 1 << 20;

  /// The view of a committed op whose applied form is [applied].
  static RevOpView of(
    RevOp op,
    RevCodec codec,
    List<RowChange> applied,
  ) {
    final (text, gz) = wire(codec, applied, withBefore: false);
    return RevOpView(
      revision: op.revision,
      clientOpId: op.clientOpId,
      payload: text,
      payloadGz: gz,
      authorUuid: op.authorUuid,
      authorSessionId: op.sessionId,
      actorKind: op.actorKind,
      label: op.label,
      summaryJson: op.summaryJson,
      detailJson: op.detailJson,
      offline: op.offline,
      groupId: op.groupId,
      groupIndex: op.groupIndex,
      groupLast: op.groupLast,
      recordId: op.recordId,
      onBehalfOfSessionId: op.onBehalfOfSessionId,
      outcomeJson: op.outcomeJson,
      committedAt: op.committedAt,
    );
  }

  /// The codec text of [changes], gzipped when large.
  static (String?, ByteData?) wire(
    RevCodec codec,
    List<RowChange> changes, {
    required bool withBefore,
    Map<String, Object?>? summary,
    Map<String, Object?>? detail,
  }) {
    final text = codec.encodeText(
      changes,
      withBefore: withBefore,
      summary: summary,
      detail: detail,
    );
    final packed = RevCodec.pack(text, threshold: compressAboveBytes);
    return (
      packed.text,
      packed.gz == null ? null : ByteData.sublistView(packed.gz!),
    );
  }

  /// The stored payload (gzip of the applied form with `before`).
  static ByteData storePayload(RevCodec codec, List<RowChange> applied) =>
      ByteData.sublistView(RevCodec.gzip(codec.encodeText(applied)));

  static Uint8List _bytes(ByteData b) =>
      b.buffer.asUint8List(b.offsetInBytes, b.lengthInBytes);

  /// Decodes a stored payload.
  static List<RowChange> decodeStored(RevCodec codec, ByteData payload) =>
      codec.decodeText(RevCodec.gunzip(_bytes(payload))).changes;

  /// Decodes a client payload (text or gzip).
  static RevPayload decodeWire(RevCodec codec, String? text, ByteData? gz) =>
      codec.decodeText(
        RevCodec.unpack(text: text, gz: gz == null ? null : _bytes(gz)),
      );

  /// Ops in [from, to] of [fileId] from `rev_op` (≤ [maxOps], ≤ [maxBytes]
  /// compressed; fewer when a limit is hit). Pruned ops are skipped.
  static Future<List<RevOpView>> read(
    Session session,
    RevCodec codec,
    int fileId,
    int from,
    int to, {
    Transaction? transaction,
  }) async {
    final ops = await RevOp.db.find(
      session,
      where: (t) =>
          t.fileId.equals(fileId) & (t.revision >= from) & (t.revision <= to),
      orderBy: (t) => t.revision,
      limit: maxOps,
      transaction: transaction,
    );
    final out = <RevOpView>[];
    var bytes = 0;
    for (final op in ops) {
      final payload = op.payload;
      if (payload == null) continue;
      bytes += payload.lengthInBytes;
      if (out.isNotEmpty && bytes > maxBytes) break;
      out.add(of(op, codec, decodeStored(codec, payload)));
    }
    return out;
  }

  /// The applied form of a view (decoded payload, without `before`).
  static List<RowChange> appliedOf(RevCodec codec, RevOpView v) =>
      decodeWire(codec, v.payload, v.payloadGz).changes;
}
