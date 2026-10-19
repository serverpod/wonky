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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Limits clients pre-check (specs/01 §6, Sheets 01 §3).
abstract class ServerLimits
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ServerLimits._({
    required this.maxCellsPerSpreadsheet,
    required this.maxSheetsPerSpreadsheet,
    required this.maxDocumentChars,
    required this.maxImageUploadBytes,
    required this.maxImportUploadBytes,
    required this.scriptTimeoutMs,
    int? maxFileUploadBytes,
    int? quotaBytesPerUser,
  }) : maxFileUploadBytes = maxFileUploadBytes ?? 52428800,
       quotaBytesPerUser = quotaBytesPerUser ?? 52428800;

  factory ServerLimits({
    required int maxCellsPerSpreadsheet,
    required int maxSheetsPerSpreadsheet,
    required int maxDocumentChars,
    required int maxImageUploadBytes,
    required int maxImportUploadBytes,
    required int scriptTimeoutMs,
    int? maxFileUploadBytes,
    int? quotaBytesPerUser,
  }) = _ServerLimitsImpl;

  factory ServerLimits.fromJson(Map<String, dynamic> jsonSerialization) {
    return ServerLimits(
      maxCellsPerSpreadsheet:
          jsonSerialization['maxCellsPerSpreadsheet'] as int,
      maxSheetsPerSpreadsheet:
          jsonSerialization['maxSheetsPerSpreadsheet'] as int,
      maxDocumentChars: jsonSerialization['maxDocumentChars'] as int,
      maxImageUploadBytes: jsonSerialization['maxImageUploadBytes'] as int,
      maxImportUploadBytes: jsonSerialization['maxImportUploadBytes'] as int,
      scriptTimeoutMs: jsonSerialization['scriptTimeoutMs'] as int,
      maxFileUploadBytes: jsonSerialization['maxFileUploadBytes'] as int?,
      quotaBytesPerUser: jsonSerialization['quotaBytesPerUser'] as int?,
    );
  }

  int maxCellsPerSpreadsheet;

  int maxSheetsPerSpreadsheet;

  int maxDocumentChars;

  int maxImageUploadBytes;

  int maxImportUploadBytes;

  int scriptTimeoutMs;

  /// (v2) Cap for one uploaded Drive file (`wonky.files.maxFileUploadBytes`,
  /// Drive 02 §3.2).
  int maxFileUploadBytes;

  /// (v2) Default storage quota per user (`wonky.drive.quotaBytesPerUser`,
  /// Drive 03 §1).
  int quotaBytesPerUser;

  /// Returns a shallow copy of this [ServerLimits]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ServerLimits copyWith({
    int? maxCellsPerSpreadsheet,
    int? maxSheetsPerSpreadsheet,
    int? maxDocumentChars,
    int? maxImageUploadBytes,
    int? maxImportUploadBytes,
    int? scriptTimeoutMs,
    int? maxFileUploadBytes,
    int? quotaBytesPerUser,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ServerLimits',
      'maxCellsPerSpreadsheet': maxCellsPerSpreadsheet,
      'maxSheetsPerSpreadsheet': maxSheetsPerSpreadsheet,
      'maxDocumentChars': maxDocumentChars,
      'maxImageUploadBytes': maxImageUploadBytes,
      'maxImportUploadBytes': maxImportUploadBytes,
      'scriptTimeoutMs': scriptTimeoutMs,
      'maxFileUploadBytes': maxFileUploadBytes,
      'quotaBytesPerUser': quotaBytesPerUser,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ServerLimits',
      'maxCellsPerSpreadsheet': maxCellsPerSpreadsheet,
      'maxSheetsPerSpreadsheet': maxSheetsPerSpreadsheet,
      'maxDocumentChars': maxDocumentChars,
      'maxImageUploadBytes': maxImageUploadBytes,
      'maxImportUploadBytes': maxImportUploadBytes,
      'scriptTimeoutMs': scriptTimeoutMs,
      'maxFileUploadBytes': maxFileUploadBytes,
      'quotaBytesPerUser': quotaBytesPerUser,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ServerLimitsImpl extends ServerLimits {
  _ServerLimitsImpl({
    required int maxCellsPerSpreadsheet,
    required int maxSheetsPerSpreadsheet,
    required int maxDocumentChars,
    required int maxImageUploadBytes,
    required int maxImportUploadBytes,
    required int scriptTimeoutMs,
    int? maxFileUploadBytes,
    int? quotaBytesPerUser,
  }) : super._(
         maxCellsPerSpreadsheet: maxCellsPerSpreadsheet,
         maxSheetsPerSpreadsheet: maxSheetsPerSpreadsheet,
         maxDocumentChars: maxDocumentChars,
         maxImageUploadBytes: maxImageUploadBytes,
         maxImportUploadBytes: maxImportUploadBytes,
         scriptTimeoutMs: scriptTimeoutMs,
         maxFileUploadBytes: maxFileUploadBytes,
         quotaBytesPerUser: quotaBytesPerUser,
       );

  /// Returns a shallow copy of this [ServerLimits]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ServerLimits copyWith({
    int? maxCellsPerSpreadsheet,
    int? maxSheetsPerSpreadsheet,
    int? maxDocumentChars,
    int? maxImageUploadBytes,
    int? maxImportUploadBytes,
    int? scriptTimeoutMs,
    int? maxFileUploadBytes,
    int? quotaBytesPerUser,
  }) {
    return ServerLimits(
      maxCellsPerSpreadsheet:
          maxCellsPerSpreadsheet ?? this.maxCellsPerSpreadsheet,
      maxSheetsPerSpreadsheet:
          maxSheetsPerSpreadsheet ?? this.maxSheetsPerSpreadsheet,
      maxDocumentChars: maxDocumentChars ?? this.maxDocumentChars,
      maxImageUploadBytes: maxImageUploadBytes ?? this.maxImageUploadBytes,
      maxImportUploadBytes: maxImportUploadBytes ?? this.maxImportUploadBytes,
      scriptTimeoutMs: scriptTimeoutMs ?? this.scriptTimeoutMs,
      maxFileUploadBytes: maxFileUploadBytes ?? this.maxFileUploadBytes,
      quotaBytesPerUser: quotaBytesPerUser ?? this.quotaBytesPerUser,
    );
  }
}
