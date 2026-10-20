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
import '../../../platform/publications/models/publication_settings.dart'
    as _iyzf06w5;

/// A secret shown once (specs/18 §8.1): the signing secret at creation or
/// rotation, or an API key.
abstract class PublicationSecret
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PublicationSecret._({
    required this.settings,
    required this.secret,
  });

  factory PublicationSecret({
    required _iyzf06w5.PublicationSettings settings,
    required String secret,
  }) = _PublicationSecretImpl;

  factory PublicationSecret.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationSecret(
      settings: _i8pkqg1o.Protocol().deserialize<_iyzf06w5.PublicationSettings>(
        jsonSerialization['settings'],
      ),
      secret: jsonSerialization['secret'] as String,
    );
  }

  _iyzf06w5.PublicationSettings settings;

  String secret;

  /// Returns a shallow copy of this [PublicationSecret]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PublicationSecret copyWith({
    _iyzf06w5.PublicationSettings? settings,
    String? secret,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationSecret',
      'settings': settings.toJson(),
      'secret': secret,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationSecret',
      'settings': settings.toJsonForProtocol(),
      'secret': secret,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _PublicationSecretImpl extends PublicationSecret {
  _PublicationSecretImpl({
    required _iyzf06w5.PublicationSettings settings,
    required String secret,
  }) : super._(
         settings: settings,
         secret: secret,
       );

  /// Returns a shallow copy of this [PublicationSecret]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PublicationSecret copyWith({
    _iyzf06w5.PublicationSettings? settings,
    String? secret,
  }) {
    return PublicationSecret(
      settings: settings ?? this.settings.copyWith(),
      secret: secret ?? this.secret,
    );
  }
}
