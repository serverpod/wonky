import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/model.dart' show RowChange;

import '../../platform/common/models.dart';
import '../../platform/files/file_service.dart';
import '../revlog/sheets_server_writes.dart';

/// Legacy [ServerChangeRecord]s (before RevLog; Sheets composites): the
/// inverse and forward changes stored inline or as files. Records of RevLog
/// files carry a `recordId` instead, and [inverse]/[forward] read their ops.
/// Legacy records hold the inverse row changes as gzip+base64 JSON (inline
/// or in a stored file) and the forward changes in a file (redo). New
/// records are never written in this format.
abstract final class SheetsChangeRecords {
  static List<RowChange> decode(String data) => [
    for (final m
        in jsonDecode(utf8.decode(gzip.decode(base64Decode(data))))
            as List<dynamic>)
      RowChange.fromJson((m as Map).cast<String, Object?>()),
  ];

  /// The inverse changes of a record.
  static Future<List<RowChange>> inverse(
    Session session,
    ServerChangeRecord r,
  ) async {
    if (r.recordId != null) return SheetsServerWrites.inverse(session, r);
    final inline = r.inverseJson;
    if (inline != null) return decode(inline);
    if (r.inverseFileId == null) return const [];
    final file = await FileService.byUuid(session, r.inverseFileId!);
    if (file == null) return const [];
    final bytes = await FileService.readBytes(session, file);
    return decode(
      utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  }

  /// The forward changes of a record (empty when its file is gone).
  static Future<List<RowChange>> forward(
    Session session,
    ServerChangeRecord r,
  ) async {
    if (r.recordId != null) return SheetsServerWrites.forward(session, r);
    if (r.forwardFileId == null) return const [];
    final file = await FileService.byUuid(session, r.forwardFileId!);
    if (file == null) return const [];
    final bytes = await FileService.readBytes(session, file);
    return decode(
      utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  }
}
