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
import '../../platform/common/access_role.dart' as _iv7g6vuy;

/// A role grant on a drive item (specs/06 §2). Grants on folders are
/// materialized on every descendant with [inheritedFromId].
abstract class DriveItemPermission
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DriveItemPermission._({
    this.id,
    required this.itemId,
    this.userId,
    this.invitedEmail,
    required this.role,
    this.inheritedFromId,
    required this.grantedById,
    required this.grantedAt,
    this.expiresAt,
    this.viaPublicationId,
  });

  factory DriveItemPermission({
    int? id,
    required int itemId,
    int? userId,
    String? invitedEmail,
    required _iv7g6vuy.AccessRole role,
    int? inheritedFromId,
    required int grantedById,
    required DateTime grantedAt,
    DateTime? expiresAt,
    int? viaPublicationId,
  }) = _DriveItemPermissionImpl;

  factory DriveItemPermission.fromJson(Map<String, dynamic> jsonSerialization) {
    return DriveItemPermission(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      userId: jsonSerialization['userId'] as int?,
      invitedEmail: jsonSerialization['invitedEmail'] as String?,
      role: _iv7g6vuy.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      inheritedFromId: jsonSerialization['inheritedFromId'] as int?,
      grantedById: jsonSerialization['grantedById'] as int,
      grantedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['grantedAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      viaPublicationId: jsonSerialization['viaPublicationId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int itemId;

  /// Null while the invite is pending (no account yet).
  int? userId;

  String? invitedEmail;

  _iv7g6vuy.AccessRole role;

  /// The folder item the grant was inherited from (null = direct).
  int? inheritedFromId;

  int grantedById;

  DateTime grantedAt;

  DateTime? expiresAt;

  /// (M14) Moderator grant of a submission (specs/18 §5.1); removed with it.
  int? viaPublicationId;

  /// Returns a shallow copy of this [DriveItemPermission]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DriveItemPermission copyWith({
    int? id,
    int? itemId,
    int? userId,
    String? invitedEmail,
    _iv7g6vuy.AccessRole? role,
    int? inheritedFromId,
    int? grantedById,
    DateTime? grantedAt,
    DateTime? expiresAt = const _isc.$UndefinedDateTime(),
    int? viaPublicationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DriveItemPermission',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (userId != null) 'userId': userId,
      if (invitedEmail != null) 'invitedEmail': invitedEmail,
      'role': role.toJson(),
      if (inheritedFromId != null) 'inheritedFromId': inheritedFromId,
      'grantedById': grantedById,
      'grantedAt': grantedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (viaPublicationId != null) 'viaPublicationId': viaPublicationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DriveItemPermission',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (userId != null) 'userId': userId,
      if (invitedEmail != null) 'invitedEmail': invitedEmail,
      'role': role.toJson(),
      if (inheritedFromId != null) 'inheritedFromId': inheritedFromId,
      'grantedById': grantedById,
      'grantedAt': grantedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (viaPublicationId != null) 'viaPublicationId': viaPublicationId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DriveItemPermissionImpl extends DriveItemPermission {
  _DriveItemPermissionImpl({
    int? id,
    required int itemId,
    int? userId,
    String? invitedEmail,
    required _iv7g6vuy.AccessRole role,
    int? inheritedFromId,
    required int grantedById,
    required DateTime grantedAt,
    DateTime? expiresAt,
    int? viaPublicationId,
  }) : super._(
         id: id,
         itemId: itemId,
         userId: userId,
         invitedEmail: invitedEmail,
         role: role,
         inheritedFromId: inheritedFromId,
         grantedById: grantedById,
         grantedAt: grantedAt,
         expiresAt: expiresAt,
         viaPublicationId: viaPublicationId,
       );

  /// Returns a shallow copy of this [DriveItemPermission]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DriveItemPermission copyWith({
    Object? id = _Undefined,
    int? itemId,
    Object? userId = _Undefined,
    Object? invitedEmail = _Undefined,
    _iv7g6vuy.AccessRole? role,
    Object? inheritedFromId = _Undefined,
    int? grantedById,
    DateTime? grantedAt,
    DateTime? expiresAt = const _isc.$UndefinedDateTime(),
    Object? viaPublicationId = _Undefined,
  }) {
    return DriveItemPermission(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      userId: userId is int? ? userId : this.userId,
      invitedEmail: invitedEmail is String? ? invitedEmail : this.invitedEmail,
      role: role ?? this.role,
      inheritedFromId: inheritedFromId is int?
          ? inheritedFromId
          : this.inheritedFromId,
      grantedById: grantedById ?? this.grantedById,
      grantedAt: grantedAt ?? this.grantedAt,
      expiresAt: expiresAt is _isc.UndefinedSentinel
          ? this.expiresAt
          : expiresAt,
      viaPublicationId: viaPublicationId is int?
          ? viaPublicationId
          : this.viaPublicationId,
    );
  }
}
