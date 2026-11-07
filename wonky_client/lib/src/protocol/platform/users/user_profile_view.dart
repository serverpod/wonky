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
import 'package:wonky_client/src/protocol/protocol.dart' as _i8pkqg1o;
import '../../platform/users/user_summary.dart' as _itg9e9ms;

/// The signed-in user's own profile (`user.getMe`).
abstract class UserProfileView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  UserProfileView._({
    required this.summary,
    this.locale,
    this.timeZone,
    required this.createdAt,
    this.organization,
  });

  factory UserProfileView({
    required _itg9e9ms.UserSummary summary,
    String? locale,
    String? timeZone,
    required DateTime createdAt,
    String? organization,
  }) = _UserProfileViewImpl;

  factory UserProfileView.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserProfileView(
      summary: _i8pkqg1o.Protocol().deserialize<_itg9e9ms.UserSummary>(
        jsonSerialization['summary'],
      ),
      locale: jsonSerialization['locale'] as String?,
      timeZone: jsonSerialization['timeZone'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      organization: jsonSerialization['organization'] as String?,
    );
  }

  _itg9e9ms.UserSummary summary;

  String? locale;

  String? timeZone;

  DateTime createdAt;

  /// The user's organization (its first domain, specs/04 §6), null for
  /// public mail domains.
  String? organization;

  /// Returns a shallow copy of this [UserProfileView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  UserProfileView copyWith({
    _itg9e9ms.UserSummary? summary,
    String? locale,
    String? timeZone,
    DateTime? createdAt,
    String? organization,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserProfileView',
      'summary': summary.toJson(),
      if (locale != null) 'locale': locale,
      if (timeZone != null) 'timeZone': timeZone,
      'createdAt': createdAt.toJson(),
      if (organization != null) 'organization': organization,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserProfileView',
      'summary': summary.toJsonForProtocol(),
      if (locale != null) 'locale': locale,
      if (timeZone != null) 'timeZone': timeZone,
      'createdAt': createdAt.toJson(),
      if (organization != null) 'organization': organization,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserProfileViewImpl extends UserProfileView {
  _UserProfileViewImpl({
    required _itg9e9ms.UserSummary summary,
    String? locale,
    String? timeZone,
    required DateTime createdAt,
    String? organization,
  }) : super._(
         summary: summary,
         locale: locale,
         timeZone: timeZone,
         createdAt: createdAt,
         organization: organization,
       );

  /// Returns a shallow copy of this [UserProfileView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  UserProfileView copyWith({
    _itg9e9ms.UserSummary? summary,
    Object? locale = _Undefined,
    Object? timeZone = _Undefined,
    DateTime? createdAt,
    Object? organization = _Undefined,
  }) {
    return UserProfileView(
      summary: summary ?? this.summary.copyWith(),
      locale: locale is String? ? locale : this.locale,
      timeZone: timeZone is String? ? timeZone : this.timeZone,
      createdAt: createdAt ?? this.createdAt,
      organization: organization is String? ? organization : this.organization,
    );
  }
}
