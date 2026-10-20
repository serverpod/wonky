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
import '../../../platform/publications/models/publication_fields.dart'
    as _i1a71r29;

/// Create or update a publication (specs/18 §8.1).
abstract class PublicationInput
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PublicationInput._({
    required this.name,
    required this.siteUrl,
    required this.webhookUrl,
    this.templateItemUuid,
    this.termsUrl,
    required this.fields,
    required this.enabled,
  });

  factory PublicationInput({
    required String name,
    required String siteUrl,
    required String webhookUrl,
    _is.UuidValue? templateItemUuid,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    required bool enabled,
  }) = _PublicationInputImpl;

  factory PublicationInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationInput(
      name: jsonSerialization['name'] as String,
      siteUrl: jsonSerialization['siteUrl'] as String,
      webhookUrl: jsonSerialization['webhookUrl'] as String,
      templateItemUuid: jsonSerialization['templateItemUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['templateItemUuid'],
            ),
      termsUrl: jsonSerialization['termsUrl'] as String?,
      fields: _il4umwa0.Protocol().deserialize<_i1a71r29.PublicationFields>(
        jsonSerialization['fields'],
      ),
      enabled: _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
    );
  }

  String name;

  String siteUrl;

  String webhookUrl;

  _is.UuidValue? templateItemUuid;

  String? termsUrl;

  _i1a71r29.PublicationFields fields;

  bool enabled;

  /// Returns a shallow copy of this [PublicationInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationInput copyWith({
    String? name,
    String? siteUrl,
    String? webhookUrl,
    _is.UuidValue? templateItemUuid = const _is.$UndefinedUuidValue(),
    String? termsUrl,
    _i1a71r29.PublicationFields? fields,
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
      'enabled': enabled,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationInputImpl extends PublicationInput {
  _PublicationInputImpl({
    required String name,
    required String siteUrl,
    required String webhookUrl,
    _is.UuidValue? templateItemUuid,
    String? termsUrl,
    required _i1a71r29.PublicationFields fields,
    required bool enabled,
  }) : super._(
         name: name,
         siteUrl: siteUrl,
         webhookUrl: webhookUrl,
         templateItemUuid: templateItemUuid,
         termsUrl: termsUrl,
         fields: fields,
         enabled: enabled,
       );

  /// Returns a shallow copy of this [PublicationInput]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationInput copyWith({
    String? name,
    String? siteUrl,
    String? webhookUrl,
    _is.UuidValue? templateItemUuid = const _is.$UndefinedUuidValue(),
    Object? termsUrl = _Undefined,
    _i1a71r29.PublicationFields? fields,
    bool? enabled,
  }) {
    return PublicationInput(
      name: name ?? this.name,
      siteUrl: siteUrl ?? this.siteUrl,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      templateItemUuid: templateItemUuid is _is.UndefinedSentinel
          ? this.templateItemUuid
          : templateItemUuid,
      termsUrl: termsUrl is String? ? termsUrl : this.termsUrl,
      fields: fields ?? this.fields.copyWith(),
      enabled: enabled ?? this.enabled,
    );
  }
}
