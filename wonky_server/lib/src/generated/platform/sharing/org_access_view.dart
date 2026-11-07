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
import '../../platform/common/access_role.dart' as _iv7g6vuy;

/// An "Anyone at <domain>" grant in the share dialog (specs/06 §2.3).
abstract class OrgAccessView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  OrgAccessView._({
    required this.domain,
    required this.role,
    this.inheritedFromUuid,
    this.inheritedFromName,
  });

  factory OrgAccessView({
    required String domain,
    required _iv7g6vuy.AccessRole role,
    _is.UuidValue? inheritedFromUuid,
    String? inheritedFromName,
  }) = _OrgAccessViewImpl;

  factory OrgAccessView.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrgAccessView(
      domain: jsonSerialization['domain'] as String,
      role: _iv7g6vuy.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      inheritedFromUuid: jsonSerialization['inheritedFromUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['inheritedFromUuid'],
            ),
      inheritedFromName: jsonSerialization['inheritedFromName'] as String?,
    );
  }

  /// The organization's name: its first domain (`serverpod.dev`).
  String domain;

  _iv7g6vuy.AccessRole role;

  /// The folder the grant is inherited from (null = set on this item).
  _is.UuidValue? inheritedFromUuid;

  String? inheritedFromName;

  /// Returns a shallow copy of this [OrgAccessView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OrgAccessView copyWith({
    String? domain,
    _iv7g6vuy.AccessRole? role,
    _is.UuidValue? inheritedFromUuid = const _is.$UndefinedUuidValue(),
    String? inheritedFromName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrgAccessView',
      'domain': domain,
      'role': role.toJson(),
      if (inheritedFromUuid != null)
        'inheritedFromUuid': inheritedFromUuid?.toJson(),
      if (inheritedFromName != null) 'inheritedFromName': inheritedFromName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OrgAccessView',
      'domain': domain,
      'role': role.toJson(),
      if (inheritedFromUuid != null)
        'inheritedFromUuid': inheritedFromUuid?.toJson(),
      if (inheritedFromName != null) 'inheritedFromName': inheritedFromName,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrgAccessViewImpl extends OrgAccessView {
  _OrgAccessViewImpl({
    required String domain,
    required _iv7g6vuy.AccessRole role,
    _is.UuidValue? inheritedFromUuid,
    String? inheritedFromName,
  }) : super._(
         domain: domain,
         role: role,
         inheritedFromUuid: inheritedFromUuid,
         inheritedFromName: inheritedFromName,
       );

  /// Returns a shallow copy of this [OrgAccessView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OrgAccessView copyWith({
    String? domain,
    _iv7g6vuy.AccessRole? role,
    _is.UuidValue? inheritedFromUuid = const _is.$UndefinedUuidValue(),
    Object? inheritedFromName = _Undefined,
  }) {
    return OrgAccessView(
      domain: domain ?? this.domain,
      role: role ?? this.role,
      inheritedFromUuid: inheritedFromUuid is _is.UndefinedSentinel
          ? this.inheritedFromUuid
          : inheritedFromUuid,
      inheritedFromName: inheritedFromName is String?
          ? inheritedFromName
          : this.inheritedFromName,
    );
  }
}
