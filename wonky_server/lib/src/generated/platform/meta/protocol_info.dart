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
import '../../platform/meta/feature_flags.dart' as _iebgpwu8;
import '../../platform/meta/server_limits.dart' as _ii93uvig;

/// Returned by `meta.getInfo()`; clients check it on connect (specs/01 §7).
abstract class ProtocolInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ProtocolInfo._({
    required this.serverVersion,
    required this.minClientVersion,
    required this.revSchemaHash,
    required this.runMode,
    required this.features,
    required this.limits,
    required this.serverTime,
    bool? redisEnabled,
    bool? redisConnected,
  }) : redisEnabled = redisEnabled ?? false,
       redisConnected = redisConnected ?? false;

  factory ProtocolInfo({
    required String serverVersion,
    required String minClientVersion,
    required String revSchemaHash,
    required String runMode,
    required _iebgpwu8.FeatureFlags features,
    required _ii93uvig.ServerLimits limits,
    required DateTime serverTime,
    bool? redisEnabled,
    bool? redisConnected,
  }) = _ProtocolInfoImpl;

  factory ProtocolInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProtocolInfo(
      serverVersion: jsonSerialization['serverVersion'] as String,
      minClientVersion: jsonSerialization['minClientVersion'] as String,
      revSchemaHash: jsonSerialization['revSchemaHash'] as String,
      runMode: jsonSerialization['runMode'] as String,
      features: _il4umwa0.Protocol().deserialize<_iebgpwu8.FeatureFlags>(
        jsonSerialization['features'],
      ),
      limits: _il4umwa0.Protocol().deserialize<_ii93uvig.ServerLimits>(
        jsonSerialization['limits'],
      ),
      serverTime: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverTime'],
      ),
      redisEnabled: jsonSerialization['redisEnabled'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['redisEnabled']),
      redisConnected: jsonSerialization['redisConnected'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['redisConnected']),
    );
  }

  String serverVersion;

  String minClientVersion;

  /// RevSchema hashes of the synced apps (`sheets:<hash>,slides:<hash>`,
  /// RevLog spec 02 §4.3). A file stream also announces the hashes it
  /// accepts (`RevInit.acceptedHashes`).
  String revSchemaHash;

  String runMode;

  _iebgpwu8.FeatureFlags features;

  _ii93uvig.ServerLimits limits;

  DateTime serverTime;

  /// Redis is configured (multi-instance messaging, specs/13 §4).
  bool redisEnabled;

  /// The server reached Redis (a ping) when this was returned.
  bool redisConnected;

  /// Returns a shallow copy of this [ProtocolInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ProtocolInfo copyWith({
    String? serverVersion,
    String? minClientVersion,
    String? revSchemaHash,
    String? runMode,
    _iebgpwu8.FeatureFlags? features,
    _ii93uvig.ServerLimits? limits,
    DateTime? serverTime,
    bool? redisEnabled,
    bool? redisConnected,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProtocolInfo',
      'serverVersion': serverVersion,
      'minClientVersion': minClientVersion,
      'revSchemaHash': revSchemaHash,
      'runMode': runMode,
      'features': features.toJson(),
      'limits': limits.toJson(),
      'serverTime': serverTime.toJson(),
      'redisEnabled': redisEnabled,
      'redisConnected': redisConnected,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProtocolInfo',
      'serverVersion': serverVersion,
      'minClientVersion': minClientVersion,
      'revSchemaHash': revSchemaHash,
      'runMode': runMode,
      'features': features.toJsonForProtocol(),
      'limits': limits.toJsonForProtocol(),
      'serverTime': serverTime.toJson(),
      'redisEnabled': redisEnabled,
      'redisConnected': redisConnected,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ProtocolInfoImpl extends ProtocolInfo {
  _ProtocolInfoImpl({
    required String serverVersion,
    required String minClientVersion,
    required String revSchemaHash,
    required String runMode,
    required _iebgpwu8.FeatureFlags features,
    required _ii93uvig.ServerLimits limits,
    required DateTime serverTime,
    bool? redisEnabled,
    bool? redisConnected,
  }) : super._(
         serverVersion: serverVersion,
         minClientVersion: minClientVersion,
         revSchemaHash: revSchemaHash,
         runMode: runMode,
         features: features,
         limits: limits,
         serverTime: serverTime,
         redisEnabled: redisEnabled,
         redisConnected: redisConnected,
       );

  /// Returns a shallow copy of this [ProtocolInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ProtocolInfo copyWith({
    String? serverVersion,
    String? minClientVersion,
    String? revSchemaHash,
    String? runMode,
    _iebgpwu8.FeatureFlags? features,
    _ii93uvig.ServerLimits? limits,
    DateTime? serverTime,
    bool? redisEnabled,
    bool? redisConnected,
  }) {
    return ProtocolInfo(
      serverVersion: serverVersion ?? this.serverVersion,
      minClientVersion: minClientVersion ?? this.minClientVersion,
      revSchemaHash: revSchemaHash ?? this.revSchemaHash,
      runMode: runMode ?? this.runMode,
      features: features ?? this.features.copyWith(),
      limits: limits ?? this.limits.copyWith(),
      serverTime: serverTime ?? this.serverTime,
      redisEnabled: redisEnabled ?? this.redisEnabled,
      redisConnected: redisConnected ?? this.redisConnected,
    );
  }
}
