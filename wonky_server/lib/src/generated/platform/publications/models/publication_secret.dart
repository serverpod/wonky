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
import '../../../platform/publications/models/publication_settings.dart'
    as _iyzf06w5;

/// A secret shown once (specs/18 §8.1): the signing secret at creation or
/// rotation, or an API key.
abstract class PublicationSecret
    implements _is.SerializableModel, _is.ProtocolSerialization {
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
      settings: _il4umwa0.Protocol().deserialize<_iyzf06w5.PublicationSettings>(
        jsonSerialization['settings'],
      ),
      secret: jsonSerialization['secret'] as String,
    );
  }

  _iyzf06w5.PublicationSettings settings;

  String secret;

  /// Returns a shallow copy of this [PublicationSecret]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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
