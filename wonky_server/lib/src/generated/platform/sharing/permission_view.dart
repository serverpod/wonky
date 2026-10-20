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
import '../../platform/common/access_role.dart' as _iv7g6vuy;
import '../../platform/users/user_summary.dart' as _itg9e9ms;

abstract class PermissionView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PermissionView._({
    this.user,
    this.invitedEmail,
    required this.role,
    this.inheritedFromUuid,
    this.inheritedFromName,
    required this.grantedAt,
    this.expiresAt,
    this.viaPublication,
  });

  factory PermissionView({
    _itg9e9ms.UserSummary? user,
    String? invitedEmail,
    required _iv7g6vuy.AccessRole role,
    _is.UuidValue? inheritedFromUuid,
    String? inheritedFromName,
    required DateTime grantedAt,
    DateTime? expiresAt,
    String? viaPublication,
  }) = _PermissionViewImpl;

  factory PermissionView.fromJson(Map<String, dynamic> jsonSerialization) {
    return PermissionView(
      user: jsonSerialization['user'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_itg9e9ms.UserSummary>(
              jsonSerialization['user'],
            ),
      invitedEmail: jsonSerialization['invitedEmail'] as String?,
      role: _iv7g6vuy.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      inheritedFromUuid: jsonSerialization['inheritedFromUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['inheritedFromUuid'],
            ),
      inheritedFromName: jsonSerialization['inheritedFromName'] as String?,
      grantedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['grantedAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      viaPublication: jsonSerialization['viaPublication'] as String?,
    );
  }

  /// Null for pending invites.
  _itg9e9ms.UserSummary? user;

  String? invitedEmail;

  _iv7g6vuy.AccessRole role;

  /// The folder the grant comes from (null = direct grant).
  _is.UuidValue? inheritedFromUuid;

  String? inheritedFromName;

  DateTime grantedAt;

  DateTime? expiresAt;

  /// (M14) The publication a moderator grant comes from (specs/18 §5.1).
  String? viaPublication;

  /// Returns a shallow copy of this [PermissionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PermissionView copyWith({
    _itg9e9ms.UserSummary? user = const _UndefinedPermissionView$user(),
    String? invitedEmail,
    _iv7g6vuy.AccessRole? role,
    _is.UuidValue? inheritedFromUuid = const _is.$UndefinedUuidValue(),
    String? inheritedFromName,
    DateTime? grantedAt,
    DateTime? expiresAt = const _is.$UndefinedDateTime(),
    String? viaPublication,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PermissionView',
      if (user != null) 'user': user?.toJson(),
      if (invitedEmail != null) 'invitedEmail': invitedEmail,
      'role': role.toJson(),
      if (inheritedFromUuid != null)
        'inheritedFromUuid': inheritedFromUuid?.toJson(),
      if (inheritedFromName != null) 'inheritedFromName': inheritedFromName,
      'grantedAt': grantedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (viaPublication != null) 'viaPublication': viaPublication,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PermissionView',
      if (user != null) 'user': user?.toJsonForProtocol(),
      if (invitedEmail != null) 'invitedEmail': invitedEmail,
      'role': role.toJson(),
      if (inheritedFromUuid != null)
        'inheritedFromUuid': inheritedFromUuid?.toJson(),
      if (inheritedFromName != null) 'inheritedFromName': inheritedFromName,
      'grantedAt': grantedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (viaPublication != null) 'viaPublication': viaPublication,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedPermissionView$user extends _is.UndefinedSentinel
    implements _itg9e9ms.UserSummary {
  const _UndefinedPermissionView$user();
}

class _PermissionViewImpl extends PermissionView {
  _PermissionViewImpl({
    _itg9e9ms.UserSummary? user,
    String? invitedEmail,
    required _iv7g6vuy.AccessRole role,
    _is.UuidValue? inheritedFromUuid,
    String? inheritedFromName,
    required DateTime grantedAt,
    DateTime? expiresAt,
    String? viaPublication,
  }) : super._(
         user: user,
         invitedEmail: invitedEmail,
         role: role,
         inheritedFromUuid: inheritedFromUuid,
         inheritedFromName: inheritedFromName,
         grantedAt: grantedAt,
         expiresAt: expiresAt,
         viaPublication: viaPublication,
       );

  /// Returns a shallow copy of this [PermissionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PermissionView copyWith({
    _itg9e9ms.UserSummary? user = const _UndefinedPermissionView$user(),
    Object? invitedEmail = _Undefined,
    _iv7g6vuy.AccessRole? role,
    _is.UuidValue? inheritedFromUuid = const _is.$UndefinedUuidValue(),
    Object? inheritedFromName = _Undefined,
    DateTime? grantedAt,
    DateTime? expiresAt = const _is.$UndefinedDateTime(),
    Object? viaPublication = _Undefined,
  }) {
    return PermissionView(
      user: user is _is.UndefinedSentinel ? this.user?.copyWith() : user,
      invitedEmail: invitedEmail is String? ? invitedEmail : this.invitedEmail,
      role: role ?? this.role,
      inheritedFromUuid: inheritedFromUuid is _is.UndefinedSentinel
          ? this.inheritedFromUuid
          : inheritedFromUuid,
      inheritedFromName: inheritedFromName is String?
          ? inheritedFromName
          : this.inheritedFromName,
      grantedAt: grantedAt ?? this.grantedAt,
      expiresAt: expiresAt is _is.UndefinedSentinel
          ? this.expiresAt
          : expiresAt,
      viaPublication: viaPublication is String?
          ? viaPublication
          : this.viaPublication,
    );
  }
}
