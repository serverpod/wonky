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
import '../../platform/files/image_profile.dart' as _ilodsldt;
import '../../platform/files/stored_file_kind.dart' as _iytry1n5;
import '../../platform/files/stored_file_status.dart' as _is8j7as8;

/// A file in cloud storage (specs/12 §1.1). The client chooses [fileUuid]
/// so content can reference `wonky-file://<fileUuid>` before upload.
abstract class StoredFile
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StoredFile._({
    this.id,
    required this.fileUuid,
    this.ownerId,
    this.itemId,
    required this.kind,
    required this.storageId,
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    this.imageProfile,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
  });

  factory StoredFile({
    int? id,
    required _isc.UuidValue fileUuid,
    int? ownerId,
    int? itemId,
    required _iytry1n5.StoredFileKind kind,
    required String storageId,
    required String path,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required _is8j7as8.StoredFileStatus status,
    _ilodsldt.ImageProfile? imageProfile,
    required DateTime createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) = _StoredFileImpl;

  factory StoredFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return StoredFile(
      id: jsonSerialization['id'] as int?,
      fileUuid: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      ownerId: jsonSerialization['ownerId'] as int?,
      itemId: jsonSerialization['itemId'] as int?,
      kind: _iytry1n5.StoredFileKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      storageId: jsonSerialization['storageId'] as String,
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      status: _is8j7as8.StoredFileStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      imageProfile: jsonSerialization['imageProfile'] == null
          ? null
          : _ilodsldt.ImageProfile.fromJson(
              (jsonSerialization['imageProfile'] as String),
            ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _isc.UuidValue fileUuid;

  int? ownerId;

  /// Access follows this item (null = owner only, e.g. avatars, imports).
  int? itemId;

  _iytry1n5.StoredFileKind kind;

  String storageId;

  String path;

  String fileName;

  String mimeType;

  int sizeBytes;

  _is8j7as8.StoredFileStatus status;

  /// (Images of documents, avatars, board screenshots) how the upload is
  /// re-encoded on completion (specs/12 §1.1); null for other kinds and
  /// older files.
  _ilodsldt.ImageProfile? imageProfile;

  DateTime createdAt;

  DateTime? completedAt;

  DateTime? expiresAt;

  /// Returns a shallow copy of this [StoredFile]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StoredFile copyWith({
    int? id,
    _isc.UuidValue? fileUuid,
    int? ownerId,
    int? itemId,
    _iytry1n5.StoredFileKind? kind,
    String? storageId,
    String? path,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    _is8j7as8.StoredFileStatus? status,
    _ilodsldt.ImageProfile? imageProfile,
    DateTime? createdAt,
    DateTime? completedAt = const _isc.$UndefinedDateTime(),
    DateTime? expiresAt = const _isc.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StoredFile',
      if (id != null) 'id': id,
      'fileUuid': fileUuid.toJson(),
      if (ownerId != null) 'ownerId': ownerId,
      if (itemId != null) 'itemId': itemId,
      'kind': kind.toJson(),
      'storageId': storageId,
      'path': path,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'status': status.toJson(),
      if (imageProfile != null) 'imageProfile': imageProfile?.toJson(),
      'createdAt': createdAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StoredFile',
      if (id != null) 'id': id,
      'fileUuid': fileUuid.toJson(),
      if (ownerId != null) 'ownerId': ownerId,
      if (itemId != null) 'itemId': itemId,
      'kind': kind.toJson(),
      'storageId': storageId,
      'path': path,
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'status': status.toJson(),
      if (imageProfile != null) 'imageProfile': imageProfile?.toJson(),
      'createdAt': createdAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StoredFileImpl extends StoredFile {
  _StoredFileImpl({
    int? id,
    required _isc.UuidValue fileUuid,
    int? ownerId,
    int? itemId,
    required _iytry1n5.StoredFileKind kind,
    required String storageId,
    required String path,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required _is8j7as8.StoredFileStatus status,
    _ilodsldt.ImageProfile? imageProfile,
    required DateTime createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) : super._(
         id: id,
         fileUuid: fileUuid,
         ownerId: ownerId,
         itemId: itemId,
         kind: kind,
         storageId: storageId,
         path: path,
         fileName: fileName,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         status: status,
         imageProfile: imageProfile,
         createdAt: createdAt,
         completedAt: completedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [StoredFile]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StoredFile copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? fileUuid,
    Object? ownerId = _Undefined,
    Object? itemId = _Undefined,
    _iytry1n5.StoredFileKind? kind,
    String? storageId,
    String? path,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    _is8j7as8.StoredFileStatus? status,
    Object? imageProfile = _Undefined,
    DateTime? createdAt,
    DateTime? completedAt = const _isc.$UndefinedDateTime(),
    DateTime? expiresAt = const _isc.$UndefinedDateTime(),
  }) {
    return StoredFile(
      id: id is int? ? id : this.id,
      fileUuid: fileUuid ?? this.fileUuid,
      ownerId: ownerId is int? ? ownerId : this.ownerId,
      itemId: itemId is int? ? itemId : this.itemId,
      kind: kind ?? this.kind,
      storageId: storageId ?? this.storageId,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      imageProfile: imageProfile is _ilodsldt.ImageProfile?
          ? imageProfile
          : this.imageProfile,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt is _isc.UndefinedSentinel
          ? this.completedAt
          : completedAt,
      expiresAt: expiresAt is _isc.UndefinedSentinel
          ? this.expiresAt
          : expiresAt,
    );
  }
}
