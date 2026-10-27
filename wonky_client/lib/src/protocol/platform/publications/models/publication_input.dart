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

/// Create or update a publication (specs/18 §8.1).
abstract class PublicationInput
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PublicationInput._({
    required this.name,
    required this.siteUrl,
    required this.webhookUrl,
    this.templateItemUuid,
    this.termsUrl,
    required this.fields,
    this.markdownFlavor,
    required this.enabled,
  });

  factory PublicationInput({
    required String name,
    required String siteUrl,
    required String webhookUrl,
    _isc.UuidValue? templateItemUuid,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    String? markdownFlavor,
    required bool enabled,
  }) = _PublicationInputImpl;

  factory PublicationInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationInput(
      name: jsonSerialization['name'] as String,
      siteUrl: jsonSerialization['siteUrl'] as String,
      webhookUrl: jsonSerialization['webhookUrl'] as String,
      templateItemUuid: jsonSerialization['templateItemUuid'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['templateItemUuid'],
            ),
      termsUrl: jsonSerialization['termsUrl'] as String?,
      fields: _i8pkqg1o.Protocol().deserialize<_i1a71r29.PublicationFields>(
        jsonSerialization['fields'],
      ),
      markdownFlavor: jsonSerialization['markdownFlavor'] as String?,
      enabled: _isc.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
    );
  }

  String name;

  String siteUrl;

  String webhookUrl;

  _isc.UuidValue? templateItemUuid;

  String? termsUrl;

  _i1a71r29.PublicationFields fields;

  /// `gfm` (default) or `wonky` (Write 11 §3.3).
  String? markdownFlavor;

  bool enabled;

  /// Returns a shallow copy of this [PublicationInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PublicationInput copyWith({
    String? name,
    String? siteUrl,
    String? webhookUrl,
    _isc.UuidValue? templateItemUuid = const _isc.$UndefinedUuidValue(),
    String? termsUrl,
    _i1a71r29.PublicationFields? fields,
    String? markdownFlavor,
    bool? enabled,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationInput',
      'name': name,
      'siteUrl': siteUrl,
      'webhookUrl': webhookUrl,
      if (templateItemUuid != null)
        'templateItemUuid': templateItemUuid?.toJson(),
      if (termsUrl != null) 'termsUrl': termsUrl,
      'fields': fields.toJson(),
      if (markdownFlavor != null) 'markdownFlavor': markdownFlavor,
      'enabled': enabled,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationInput',
      'name': name,
      'siteUrl': siteUrl,
      'webhookUrl': webhookUrl,
      if (templateItemUuid != null)
        'templateItemUuid': templateItemUuid?.toJson(),
      if (termsUrl != null) 'termsUrl': termsUrl,
      'fields': fields.toJsonForProtocol(),
      if (markdownFlavor != null) 'markdownFlavor': markdownFlavor,
      'enabled': enabled,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationInputImpl extends PublicationInput {
  _PublicationInputImpl({
    required String name,
    required String siteUrl,
    required String webhookUrl,
    _isc.UuidValue? templateItemUuid,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    String? markdownFlavor,
    required bool enabled,
  }) : super._(
         name: name,
         siteUrl: siteUrl,
         webhookUrl: webhookUrl,
         templateItemUuid: templateItemUuid,
         termsUrl: termsUrl,
         fields: fields,
         markdownFlavor: markdownFlavor,
         enabled: enabled,
       );

  /// Returns a shallow copy of this [PublicationInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PublicationInput copyWith({
    String? name,
    String? siteUrl,
    String? webhookUrl,
    _isc.UuidValue? templateItemUuid = const _isc.$UndefinedUuidValue(),
    Object? termsUrl = _Undefined,
    _i1a71r29.PublicationFields? fields,
    Object? markdownFlavor = _Undefined,
    bool? enabled,
  }) {
    return PublicationInput(
      name: name ?? this.name,
      siteUrl: siteUrl ?? this.siteUrl,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      templateItemUuid: templateItemUuid is _isc.UndefinedSentinel
          ? this.templateItemUuid
          : templateItemUuid,
      termsUrl: termsUrl is String? ? termsUrl : this.termsUrl,
      fields: fields ?? this.fields.copyWith(),
      markdownFlavor: markdownFlavor is String?
          ? markdownFlavor
          : this.markdownFlavor,
      enabled: enabled ?? this.enabled,
    );
  }
}
