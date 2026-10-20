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

/// The caller's board status (specs/16 §9.1).
abstract class BoardMe
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BoardMe._({
    required this.signedIn,
    this.userId,
    required this.isAdmin,
    required this.blocked,
    this.blockedReason,
    required this.activeClaims,
    this.githubLogin,
    required this.aiChecks,
    required this.repository,
    required this.securityContact,
    required this.claimHours,
    int? maxActiveClaims,
    this.claimBlockedUntil,
    this.claimBlockedReason,
  }) : maxActiveClaims = maxActiveClaims ?? 3;

  factory BoardMe({
    required bool signedIn,
    int? userId,
    required bool isAdmin,
    required bool blocked,
    String? blockedReason,
    required List<int> activeClaims,
    String? githubLogin,
    required bool aiChecks,
    required String repository,
    required String securityContact,
    required int claimHours,
    int? maxActiveClaims,
    DateTime? claimBlockedUntil,
    String? claimBlockedReason,
  }) = _BoardMeImpl;

  factory BoardMe.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardMe(
      signedIn: _isc.BoolJsonExtension.fromJson(jsonSerialization['signedIn']),
      userId: jsonSerialization['userId'] as int?,
      isAdmin: _isc.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
      blocked: _isc.BoolJsonExtension.fromJson(jsonSerialization['blocked']),
      blockedReason: jsonSerialization['blockedReason'] as String?,
      activeClaims: _i8pkqg1o.Protocol().deserialize<List<int>>(
        jsonSerialization['activeClaims'],
      ),
      githubLogin: jsonSerialization['githubLogin'] as String?,
      aiChecks: _isc.BoolJsonExtension.fromJson(jsonSerialization['aiChecks']),
      repository: jsonSerialization['repository'] as String,
      securityContact: jsonSerialization['securityContact'] as String,
      claimHours: jsonSerialization['claimHours'] as int,
      maxActiveClaims: jsonSerialization['maxActiveClaims'] as int?,
      claimBlockedUntil: jsonSerialization['claimBlockedUntil'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['claimBlockedUntil'],
            ),
      claimBlockedReason: jsonSerialization['claimBlockedReason'] as String?,
    );
  }

  bool signedIn;

  int? userId;

  bool isAdmin;

  bool blocked;

  String? blockedReason;

  List<int> activeClaims;

  String? githubLogin;

  /// Board AI available (Jev configured): shown in the dialog notice.
  bool aiChecks;

  String repository;

  String securityContact;

  int claimHours;

  /// Claims the caller may hold at a time (`maxActiveClaimsPerUser`).
  int maxActiveClaims;

  /// Set while the caller may not claim tasks (specs/16 §8.4).
  DateTime? claimBlockedUntil;

  String? claimBlockedReason;

  /// Returns a shallow copy of this [BoardMe]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BoardMe copyWith({
    bool? signedIn,
    int? userId,
    bool? isAdmin,
    bool? blocked,
    String? blockedReason,
    List<int>? activeClaims,
    String? githubLogin,
    bool? aiChecks,
    String? repository,
    String? securityContact,
    int? claimHours,
    int? maxActiveClaims,
    DateTime? claimBlockedUntil = const _isc.$UndefinedDateTime(),
    String? claimBlockedReason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardMe',
      'signedIn': signedIn,
      if (userId != null) 'userId': userId,
      'isAdmin': isAdmin,
      'blocked': blocked,
      if (blockedReason != null) 'blockedReason': blockedReason,
      'activeClaims': activeClaims.toJson(),
      if (githubLogin != null) 'githubLogin': githubLogin,
      'aiChecks': aiChecks,
      'repository': repository,
      'securityContact': securityContact,
      'claimHours': claimHours,
      'maxActiveClaims': maxActiveClaims,
      if (claimBlockedUntil != null)
        'claimBlockedUntil': claimBlockedUntil?.toJson(),
      if (claimBlockedReason != null) 'claimBlockedReason': claimBlockedReason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BoardMe',
      'signedIn': signedIn,
      if (userId != null) 'userId': userId,
      'isAdmin': isAdmin,
      'blocked': blocked,
      if (blockedReason != null) 'blockedReason': blockedReason,
      'activeClaims': activeClaims.toJson(),
      if (githubLogin != null) 'githubLogin': githubLogin,
      'aiChecks': aiChecks,
      'repository': repository,
      'securityContact': securityContact,
      'claimHours': claimHours,
      'maxActiveClaims': maxActiveClaims,
      if (claimBlockedUntil != null)
        'claimBlockedUntil': claimBlockedUntil?.toJson(),
      if (claimBlockedReason != null) 'claimBlockedReason': claimBlockedReason,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BoardMeImpl extends BoardMe {
  _BoardMeImpl({
    required bool signedIn,
    int? userId,
    required bool isAdmin,
    required bool blocked,
    String? blockedReason,
    required List<int> activeClaims,
    String? githubLogin,
    required bool aiChecks,
    required String repository,
    required String securityContact,
    required int claimHours,
    int? maxActiveClaims,
    DateTime? claimBlockedUntil,
    String? claimBlockedReason,
  }) : super._(
         signedIn: signedIn,
         userId: userId,
         isAdmin: isAdmin,
         blocked: blocked,
         blockedReason: blockedReason,
         activeClaims: activeClaims,
         githubLogin: githubLogin,
         aiChecks: aiChecks,
         repository: repository,
         securityContact: securityContact,
         claimHours: claimHours,
         maxActiveClaims: maxActiveClaims,
         claimBlockedUntil: claimBlockedUntil,
         claimBlockedReason: claimBlockedReason,
       );

  /// Returns a shallow copy of this [BoardMe]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BoardMe copyWith({
    bool? signedIn,
    Object? userId = _Undefined,
    bool? isAdmin,
    bool? blocked,
    Object? blockedReason = _Undefined,
    List<int>? activeClaims,
    Object? githubLogin = _Undefined,
    bool? aiChecks,
    String? repository,
    String? securityContact,
    int? claimHours,
    int? maxActiveClaims,
    DateTime? claimBlockedUntil = const _isc.$UndefinedDateTime(),
    Object? claimBlockedReason = _Undefined,
  }) {
    return BoardMe(
      signedIn: signedIn ?? this.signedIn,
      userId: userId is int? ? userId : this.userId,
      isAdmin: isAdmin ?? this.isAdmin,
      blocked: blocked ?? this.blocked,
      blockedReason: blockedReason is String?
          ? blockedReason
          : this.blockedReason,
      activeClaims: activeClaims ?? this.activeClaims.map((e0) => e0).toList(),
      githubLogin: githubLogin is String? ? githubLogin : this.githubLogin,
      aiChecks: aiChecks ?? this.aiChecks,
      repository: repository ?? this.repository,
      securityContact: securityContact ?? this.securityContact,
      claimHours: claimHours ?? this.claimHours,
      maxActiveClaims: maxActiveClaims ?? this.maxActiveClaims,
      claimBlockedUntil: claimBlockedUntil is _isc.UndefinedSentinel
          ? this.claimBlockedUntil
          : claimBlockedUntil,
      claimBlockedReason: claimBlockedReason is String?
          ? claimBlockedReason
          : this.claimBlockedReason,
    );
  }
}
