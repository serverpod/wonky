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
import '../../../platform/publications/models/publication_fields.dart'
    as _i1a71r29;
import '../../../platform/publications/models/publication_open_submission.dart'
    as _i2kst26h;

/// What a contributor sees of a publication (specs/18 §3, §9.1).
abstract class PublicationCard
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PublicationCard._({
    required this.publicId,
    required this.name,
    required this.shownHost,
    required this.verified,
    required this.siteHost,
    required this.webhookHost,
    this.termsUrl,
    required this.fields,
    required this.ownerName,
    required this.enabled,
    required this.consentNeeded,
    required this.blocked,
    required this.openSubmissions,
  });

  factory PublicationCard({
    required String publicId,
    required String name,
    required String shownHost,
    required bool verified,
    required String siteHost,
    required String webhookHost,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    required String ownerName,
    required bool enabled,
    required bool consentNeeded,
    required bool blocked,
    required List<_i2kst26h.PublicationOpenSubmission> openSubmissions,
  }) = _PublicationCardImpl;

  factory PublicationCard.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationCard(
      publicId: jsonSerialization['publicId'] as String,
      name: jsonSerialization['name'] as String,
      shownHost: jsonSerialization['shownHost'] as String,
      verified: _isc.BoolJsonExtension.fromJson(jsonSerialization['verified']),
      siteHost: jsonSerialization['siteHost'] as String,
      webhookHost: jsonSerialization['webhookHost'] as String,
      termsUrl: jsonSerialization['termsUrl'] as String?,
      fields: _i8pkqg1o.Protocol().deserialize<_i1a71r29.PublicationFields>(
        jsonSerialization['fields'],
      ),
      ownerName: jsonSerialization['ownerName'] as String,
      enabled: _isc.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      consentNeeded: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['consentNeeded'],
      ),
      blocked: _isc.BoolJsonExtension.fromJson(jsonSerialization['blocked']),
      openSubmissions: _i8pkqg1o.Protocol()
          .deserialize<List<_i2kst26h.PublicationOpenSubmission>>(
            jsonSerialization['openSubmissions'],
          ),
    );
  }

  String publicId;

  String name;

  /// The verified site host, or the webhook host when unverified.
  String shownHost;

  bool verified;

  String siteHost;

  String webhookHost;

  String? termsUrl;

  _i1a71r29.PublicationFields fields;

  String ownerName;

  bool enabled;

  /// The caller must agree first (never asked or what was agreed changed).
  bool consentNeeded;

  /// The publication doesn't take stories from the caller.
  bool blocked;

  /// The caller's drafts and stories with changes requested.
  List<_i2kst26h.PublicationOpenSubmission> openSubmissions;

  /// Returns a shallow copy of this [PublicationCard]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PublicationCard copyWith({
    String? publicId,
    String? name,
    String? shownHost,
    bool? verified,
    String? siteHost,
    String? webhookHost,
    String? termsUrl,
    _i1a71r29.PublicationFields? fields,
    String? ownerName,
    bool? enabled,
    bool? consentNeeded,
    bool? blocked,
    List<_i2kst26h.PublicationOpenSubmission>? openSubmissions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationCard',
      'publicId': publicId,
      'name': name,
      'shownHost': shownHost,
      'verified': verified,
      'siteHost': siteHost,
      'webhookHost': webhookHost,
      if (termsUrl != null) 'termsUrl': termsUrl,
      'fields': fields.toJson(),
      'ownerName': ownerName,
      'enabled': enabled,
      'consentNeeded': consentNeeded,
      'blocked': blocked,
      'openSubmissions': openSubmissions.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationCard',
      'publicId': publicId,
      'name': name,
      'shownHost': shownHost,
      'verified': verified,
      'siteHost': siteHost,
      'webhookHost': webhookHost,
      if (termsUrl != null) 'termsUrl': termsUrl,
      'fields': fields.toJsonForProtocol(),
      'ownerName': ownerName,
      'enabled': enabled,
      'consentNeeded': consentNeeded,
      'blocked': blocked,
      'openSubmissions': openSubmissions.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationCardImpl extends PublicationCard {
  _PublicationCardImpl({
    required String publicId,
    required String name,
    required String shownHost,
    required bool verified,
    required String siteHost,
    required String webhookHost,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    required String ownerName,
    required bool enabled,
    required bool consentNeeded,
    required bool blocked,
    required List<_i2kst26h.PublicationOpenSubmission> openSubmissions,
  }) : super._(
         publicId: publicId,
         name: name,
         shownHost: shownHost,
         verified: verified,
         siteHost: siteHost,
         webhookHost: webhookHost,
         termsUrl: termsUrl,
         fields: fields,
         ownerName: ownerName,
         enabled: enabled,
         consentNeeded: consentNeeded,
         blocked: blocked,
         openSubmissions: openSubmissions,
       );

  /// Returns a shallow copy of this [PublicationCard]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PublicationCard copyWith({
    String? publicId,
    String? name,
    String? shownHost,
    bool? verified,
    String? siteHost,
    String? webhookHost,
    Object? termsUrl = _Undefined,
    _i1a71r29.PublicationFields? fields,
    String? ownerName,
    bool? enabled,
    bool? consentNeeded,
    bool? blocked,
    List<_i2kst26h.PublicationOpenSubmission>? openSubmissions,
  }) {
    return PublicationCard(
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      shownHost: shownHost ?? this.shownHost,
      verified: verified ?? this.verified,
      siteHost: siteHost ?? this.siteHost,
      webhookHost: webhookHost ?? this.webhookHost,
      termsUrl: termsUrl is String? ? termsUrl : this.termsUrl,
      fields: fields ?? this.fields.copyWith(),
      ownerName: ownerName ?? this.ownerName,
      enabled: enabled ?? this.enabled,
      consentNeeded: consentNeeded ?? this.consentNeeded,
      blocked: blocked ?? this.blocked,
      openSubmissions:
          openSubmissions ??
          this.openSubmissions.map((e0) => e0.copyWith()).toList(),
    );
  }
}
