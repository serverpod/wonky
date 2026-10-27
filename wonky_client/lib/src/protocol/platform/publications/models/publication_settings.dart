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
import '../../../platform/publications/models/publication_moderator_view.dart'
    as _in8lpp1q;

/// The owner's view of a publication (specs/18 §8.1). Never holds secrets.
abstract class PublicationSettings
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PublicationSettings._({
    required this.publicId,
    required this.name,
    required this.siteUrl,
    required this.webhookUrl,
    this.verifiedHost,
    this.verifiedAt,
    this.templateItemUuid,
    this.templateName,
    this.termsUrl,
    required this.fields,
    this.markdownFlavor,
    required this.moderators,
    required this.hasApiKey,
    this.apiKeyLast4,
    this.previousSecretUntil,
    required this.enabled,
    required this.contributorLink,
    required this.openSubmissionCount,
    required this.createdAt,
  });

  factory PublicationSettings({
    required String publicId,
    required String name,
    required String siteUrl,
    required String webhookUrl,
    String? verifiedHost,
    DateTime? verifiedAt,
    _isc.UuidValue? templateItemUuid,
    String? templateName,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    String? markdownFlavor,
    required List<_in8lpp1q.PublicationModeratorView> moderators,
    required bool hasApiKey,
    String? apiKeyLast4,
    DateTime? previousSecretUntil,
    required bool enabled,
    required String contributorLink,
    required int openSubmissionCount,
    required DateTime createdAt,
  }) = _PublicationSettingsImpl;

  factory PublicationSettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationSettings(
      publicId: jsonSerialization['publicId'] as String,
      name: jsonSerialization['name'] as String,
      siteUrl: jsonSerialization['siteUrl'] as String,
      webhookUrl: jsonSerialization['webhookUrl'] as String,
      verifiedHost: jsonSerialization['verifiedHost'] as String?,
      verifiedAt: jsonSerialization['verifiedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['verifiedAt'],
            ),
      templateItemUuid: jsonSerialization['templateItemUuid'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['templateItemUuid'],
            ),
      templateName: jsonSerialization['templateName'] as String?,
      termsUrl: jsonSerialization['termsUrl'] as String?,
      fields: _i8pkqg1o.Protocol().deserialize<_i1a71r29.PublicationFields>(
        jsonSerialization['fields'],
      ),
      markdownFlavor: jsonSerialization['markdownFlavor'] as String?,
      moderators: _i8pkqg1o.Protocol()
          .deserialize<List<_in8lpp1q.PublicationModeratorView>>(
            jsonSerialization['moderators'],
          ),
      hasApiKey: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['hasApiKey'],
      ),
      apiKeyLast4: jsonSerialization['apiKeyLast4'] as String?,
      previousSecretUntil: jsonSerialization['previousSecretUntil'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['previousSecretUntil'],
            ),
      enabled: _isc.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      contributorLink: jsonSerialization['contributorLink'] as String,
      openSubmissionCount: jsonSerialization['openSubmissionCount'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  String publicId;

  String name;

  String siteUrl;

  String webhookUrl;

  String? verifiedHost;

  DateTime? verifiedAt;

  _isc.UuidValue? templateItemUuid;

  String? templateName;

  String? termsUrl;

  _i1a71r29.PublicationFields fields;

  /// `gfm` or `wonky` (Write 11 §3.3).
  String? markdownFlavor;

  List<_in8lpp1q.PublicationModeratorView> moderators;

  bool hasApiKey;

  String? apiKeyLast4;

  /// Set while the previous signing secret still signs.
  DateTime? previousSecretUntil;

  bool enabled;

  /// `https://<host>/write/new?publication=<publicId>`.
  String contributorLink;

  /// Submissions in review or with changes requested.
  int openSubmissionCount;

  DateTime createdAt;

  /// Returns a shallow copy of this [PublicationSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PublicationSettings copyWith({
    String? publicId,
    String? name,
    String? siteUrl,
    String? webhookUrl,
    String? verifiedHost,
    DateTime? verifiedAt = const _isc.$UndefinedDateTime(),
    _isc.UuidValue? templateItemUuid = const _isc.$UndefinedUuidValue(),
    String? templateName,
    String? termsUrl,
    _i1a71r29.PublicationFields? fields,
    String? markdownFlavor,
    List<_in8lpp1q.PublicationModeratorView>? moderators,
    bool? hasApiKey,
    String? apiKeyLast4,
    DateTime? previousSecretUntil = const _isc.$UndefinedDateTime(),
    bool? enabled,
    String? contributorLink,
    int? openSubmissionCount,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationSettings',
      'publicId': publicId,
      'name': name,
      'siteUrl': siteUrl,
      'webhookUrl': webhookUrl,
      if (verifiedHost != null) 'verifiedHost': verifiedHost,
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
      if (templateItemUuid != null)
        'templateItemUuid': templateItemUuid?.toJson(),
      if (templateName != null) 'templateName': templateName,
      if (termsUrl != null) 'termsUrl': termsUrl,
      'fields': fields.toJson(),
      if (markdownFlavor != null) 'markdownFlavor': markdownFlavor,
      'moderators': moderators.toJson(valueToJson: (v) => v.toJson()),
      'hasApiKey': hasApiKey,
      if (apiKeyLast4 != null) 'apiKeyLast4': apiKeyLast4,
      if (previousSecretUntil != null)
        'previousSecretUntil': previousSecretUntil?.toJson(),
      'enabled': enabled,
      'contributorLink': contributorLink,
      'openSubmissionCount': openSubmissionCount,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationSettings',
      'publicId': publicId,
      'name': name,
      'siteUrl': siteUrl,
      'webhookUrl': webhookUrl,
      if (verifiedHost != null) 'verifiedHost': verifiedHost,
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
      if (templateItemUuid != null)
        'templateItemUuid': templateItemUuid?.toJson(),
      if (templateName != null) 'templateName': templateName,
      if (termsUrl != null) 'termsUrl': termsUrl,
      'fields': fields.toJsonForProtocol(),
      if (markdownFlavor != null) 'markdownFlavor': markdownFlavor,
      'moderators': moderators.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'hasApiKey': hasApiKey,
      if (apiKeyLast4 != null) 'apiKeyLast4': apiKeyLast4,
      if (previousSecretUntil != null)
        'previousSecretUntil': previousSecretUntil?.toJson(),
      'enabled': enabled,
      'contributorLink': contributorLink,
      'openSubmissionCount': openSubmissionCount,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationSettingsImpl extends PublicationSettings {
  _PublicationSettingsImpl({
    required String publicId,
    required String name,
    required String siteUrl,
    required String webhookUrl,
    String? verifiedHost,
    DateTime? verifiedAt,
    _isc.UuidValue? templateItemUuid,
    String? templateName,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    String? markdownFlavor,
    required List<_in8lpp1q.PublicationModeratorView> moderators,
    required bool hasApiKey,
    String? apiKeyLast4,
    DateTime? previousSecretUntil,
    required bool enabled,
    required String contributorLink,
    required int openSubmissionCount,
    required DateTime createdAt,
  }) : super._(
         publicId: publicId,
         name: name,
         siteUrl: siteUrl,
         webhookUrl: webhookUrl,
         verifiedHost: verifiedHost,
         verifiedAt: verifiedAt,
         templateItemUuid: templateItemUuid,
         templateName: templateName,
         termsUrl: termsUrl,
         fields: fields,
         markdownFlavor: markdownFlavor,
         moderators: moderators,
         hasApiKey: hasApiKey,
         apiKeyLast4: apiKeyLast4,
         previousSecretUntil: previousSecretUntil,
         enabled: enabled,
         contributorLink: contributorLink,
         openSubmissionCount: openSubmissionCount,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PublicationSettings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PublicationSettings copyWith({
    String? publicId,
    String? name,
    String? siteUrl,
    String? webhookUrl,
    Object? verifiedHost = _Undefined,
    DateTime? verifiedAt = const _isc.$UndefinedDateTime(),
    _isc.UuidValue? templateItemUuid = const _isc.$UndefinedUuidValue(),
    Object? templateName = _Undefined,
    Object? termsUrl = _Undefined,
    _i1a71r29.PublicationFields? fields,
    Object? markdownFlavor = _Undefined,
    List<_in8lpp1q.PublicationModeratorView>? moderators,
    bool? hasApiKey,
    Object? apiKeyLast4 = _Undefined,
    DateTime? previousSecretUntil = const _isc.$UndefinedDateTime(),
    bool? enabled,
    String? contributorLink,
    int? openSubmissionCount,
    DateTime? createdAt,
  }) {
    return PublicationSettings(
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      siteUrl: siteUrl ?? this.siteUrl,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      verifiedHost: verifiedHost is String? ? verifiedHost : this.verifiedHost,
      verifiedAt: verifiedAt is _isc.UndefinedSentinel
          ? this.verifiedAt
          : verifiedAt,
      templateItemUuid: templateItemUuid is _isc.UndefinedSentinel
          ? this.templateItemUuid
          : templateItemUuid,
      templateName: templateName is String? ? templateName : this.templateName,
      termsUrl: termsUrl is String? ? termsUrl : this.termsUrl,
      fields: fields ?? this.fields.copyWith(),
      markdownFlavor: markdownFlavor is String?
          ? markdownFlavor
          : this.markdownFlavor,
      moderators:
          moderators ?? this.moderators.map((e0) => e0.copyWith()).toList(),
      hasApiKey: hasApiKey ?? this.hasApiKey,
      apiKeyLast4: apiKeyLast4 is String? ? apiKeyLast4 : this.apiKeyLast4,
      previousSecretUntil: previousSecretUntil is _isc.UndefinedSentinel
          ? this.previousSecretUntil
          : previousSecretUntil,
      enabled: enabled ?? this.enabled,
      contributorLink: contributorLink ?? this.contributorLink,
      openSubmissionCount: openSubmissionCount ?? this.openSubmissionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
