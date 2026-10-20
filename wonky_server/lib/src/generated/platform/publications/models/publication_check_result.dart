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

/// Result of *Verify* or *Send test* (specs/18 §8.1, §8.2).
abstract class PublicationCheckResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PublicationCheckResult._({
    required this.ok,
    this.message,
    required this.settings,
  });

  factory PublicationCheckResult({
    required bool ok,
    String? message,
    required _iyzf06w5.PublicationSettings settings,
  }) = _PublicationCheckResultImpl;

  factory PublicationCheckResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PublicationCheckResult(
      ok: _is.BoolJsonExtension.fromJson(jsonSerialization['ok']),
      message: jsonSerialization['message'] as String?,
      settings: _il4umwa0.Protocol().deserialize<_iyzf06w5.PublicationSettings>(
        jsonSerialization['settings'],
      ),
    );
  }

  bool ok;

  /// What went wrong, for the owner.
  String? message;

  _iyzf06w5.PublicationSettings settings;

  /// Returns a shallow copy of this [PublicationCheckResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationCheckResult copyWith({
    bool? ok,
    String? message,
    _iyzf06w5.PublicationSettings? settings,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationCheckResult',
      'ok': ok,
      if (message != null) 'message': message,
      'settings': settings.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationCheckResult',
      'ok': ok,
      if (message != null) 'message': message,
      'settings': settings.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationCheckResultImpl extends PublicationCheckResult {
  _PublicationCheckResultImpl({
    required bool ok,
    String? message,
    required _iyzf06w5.PublicationSettings settings,
  }) : super._(
         ok: ok,
         message: message,
         settings: settings,
       );

  /// Returns a shallow copy of this [PublicationCheckResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationCheckResult copyWith({
    bool? ok,
    Object? message = _Undefined,
    _iyzf06w5.PublicationSettings? settings,
  }) {
    return PublicationCheckResult(
      ok: ok ?? this.ok,
      message: message is String? ? message : this.message,
      settings: settings ?? this.settings.copyWith(),
    );
  }
}
