/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/revlog/models/rev_page_kind.dart' as _icfciep6;

/// A bootstrap page request (RevLog spec 04 §3).
abstract class RevPageRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevPageRequest._({
    required this.kind,
    this.cursor,
    this.table,
    this.sheetId,
    this.rowIds,
    required this.maxRows,
    this.format,
  });

  factory RevPageRequest({
    required _icfciep6.RevPageKind kind,
    String? cursor,
    String? table,
    _is.UuidValue? sheetId,
    List<_is.UuidValue>? rowIds,
    required int maxRows,
    int? format,
  }) = _RevPageRequestImpl;

  factory RevPageRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevPageRequest(
      kind: _icfciep6.RevPageKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      cursor: jsonSerialization['cursor'] as String?,
      table: jsonSerialization['table'] as String?,
      sheetId: jsonSerialization['sheetId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['sheetId']),
      rowIds: jsonSerialization['rowIds'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<List<_is.UuidValue>>(
              jsonSerialization['rowIds'],
            ),
      maxRows: jsonSerialization['maxRows'] as int,
      format: jsonSerialization['format'] as int?,
    );
  }

  _icfciep6.RevPageKind kind;

  /// structure/rows: cursor of the previous page; null = start.
  String? cursor;

  /// kind == rows: the table.
  String? table;

  /// kind == cells (Sheets).
  _is.UuidValue? sheetId;

  List<_is.UuidValue>? rowIds;

  int maxRows;

  /// The newest page body version the client reads (04 §3.1); null = a
  /// client from before format negotiation (served version 1).
  int? format;

  /// Returns a shallow copy of this [RevPageRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevPageRequest copyWith({
    _icfciep6.RevPageKind? kind,
    String? cursor,
    String? table,
    _is.UuidValue? sheetId = const _is.$UndefinedUuidValue(),
    List<_is.UuidValue>? rowIds = const _is.$UndefinedList<_is.UuidValue>(),
    int? maxRows,
    int? format,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevPageRequest',
      'kind': kind.toJson(),
      if (cursor != null) 'cursor': cursor,
      if (table != null) 'table': table,
      if (sheetId != null) 'sheetId': sheetId?.toJson(),
      if (rowIds != null)
        'rowIds': rowIds?.toJson(valueToJson: (v) => v.toJson()),
      'maxRows': maxRows,
      if (format != null) 'format': format,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevPageRequest',
      'kind': kind.toJson(),
      if (cursor != null) 'cursor': cursor,
      if (table != null) 'table': table,
      if (sheetId != null) 'sheetId': sheetId?.toJson(),
      if (rowIds != null)
        'rowIds': rowIds?.toJson(valueToJson: (v) => v.toJson()),
      'maxRows': maxRows,
      if (format != null) 'format': format,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RevPageRequestImpl extends RevPageRequest {
  _RevPageRequestImpl({
    required _icfciep6.RevPageKind kind,
    String? cursor,
    String? table,
    _is.UuidValue? sheetId,
    List<_is.UuidValue>? rowIds,
    required int maxRows,
    int? format,
  }) : super._(
         kind: kind,
         cursor: cursor,
         table: table,
         sheetId: sheetId,
         rowIds: rowIds,
         maxRows: maxRows,
         format: format,
       );

  /// Returns a shallow copy of this [RevPageRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevPageRequest copyWith({
    _icfciep6.RevPageKind? kind,
    Object? cursor = _Undefined,
    Object? table = _Undefined,
    _is.UuidValue? sheetId = const _is.$UndefinedUuidValue(),
    List<_is.UuidValue>? rowIds = const _is.$UndefinedList<_is.UuidValue>(),
    int? maxRows,
    Object? format = _Undefined,
  }) {
    return RevPageRequest(
      kind: kind ?? this.kind,
      cursor: cursor is String? ? cursor : this.cursor,
      table: table is String? ? table : this.table,
      sheetId: sheetId is _is.UndefinedSentinel ? this.sheetId : sheetId,
      rowIds: rowIds is _is.UndefinedSentinel
          ? this.rowIds?.map((e0) => e0).toList()
          : rowIds,
      maxRows: maxRows ?? this.maxRows,
      format: format is int? ? format : this.format,
    );
  }
}
