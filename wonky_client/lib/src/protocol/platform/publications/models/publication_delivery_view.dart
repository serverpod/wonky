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

/// A webhook delivery in the owner's *Deliveries* list (specs/18 §8.1).
abstract class PublicationDeliveryView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PublicationDeliveryView._({
    required this.webhookId,
    required this.type,
    required this.createdAt,
    required this.attempts,
    this.lastStatus,
    this.lastError,
    this.deliveredAt,
    this.failedAt,
    this.nextAttemptAt,
  });

  factory PublicationDeliveryView({
    required String webhookId,
    required String type,
    required DateTime createdAt,
    required int attempts,
    int? lastStatus,
    String? lastError,
    DateTime? deliveredAt,
    DateTime? failedAt,
    DateTime? nextAttemptAt,
  }) = _PublicationDeliveryViewImpl;

  factory PublicationDeliveryView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PublicationDeliveryView(
      webhookId: jsonSerialization['webhookId'] as String,
      type: jsonSerialization['type'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      attempts: jsonSerialization['attempts'] as int,
      lastStatus: jsonSerialization['lastStatus'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      deliveredAt: jsonSerialization['deliveredAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['deliveredAt'],
            ),
      failedAt: jsonSerialization['failedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['failedAt']),
      nextAttemptAt: jsonSerialization['nextAttemptAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['nextAttemptAt'],
            ),
    );
  }

  String webhookId;

  String type;

  DateTime createdAt;

  int attempts;

  int? lastStatus;

  String? lastError;

  DateTime? deliveredAt;

  DateTime? failedAt;

  DateTime? nextAttemptAt;

  /// Returns a shallow copy of this [PublicationDeliveryView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PublicationDeliveryView copyWith({
    String? webhookId,
    String? type,
    DateTime? createdAt,
    int? attempts,
    int? lastStatus,
    String? lastError,
    DateTime? deliveredAt = const _isc.$UndefinedDateTime(),
    DateTime? failedAt = const _isc.$UndefinedDateTime(),
    DateTime? nextAttemptAt = const _isc.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationDeliveryView',
      'webhookId': webhookId,
      'type': type,
      'createdAt': createdAt.toJson(),
      'attempts': attempts,
      if (lastStatus != null) 'lastStatus': lastStatus,
      if (lastError != null) 'lastError': lastError,
      if (deliveredAt != null) 'deliveredAt': deliveredAt?.toJson(),
      if (failedAt != null) 'failedAt': failedAt?.toJson(),
      if (nextAttemptAt != null) 'nextAttemptAt': nextAttemptAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationDeliveryView',
      'webhookId': webhookId,
      'type': type,
      'createdAt': createdAt.toJson(),
      'attempts': attempts,
      if (lastStatus != null) 'lastStatus': lastStatus,
      if (lastError != null) 'lastError': lastError,
      if (deliveredAt != null) 'deliveredAt': deliveredAt?.toJson(),
      if (failedAt != null) 'failedAt': failedAt?.toJson(),
      if (nextAttemptAt != null) 'nextAttemptAt': nextAttemptAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationDeliveryViewImpl extends PublicationDeliveryView {
  _PublicationDeliveryViewImpl({
    required String webhookId,
    required String type,
    required DateTime createdAt,
    required int attempts,
    int? lastStatus,
    String? lastError,
    DateTime? deliveredAt,
    DateTime? failedAt,
    DateTime? nextAttemptAt,
  }) : super._(
         webhookId: webhookId,
         type: type,
         createdAt: createdAt,
         attempts: attempts,
         lastStatus: lastStatus,
         lastError: lastError,
         deliveredAt: deliveredAt,
         failedAt: failedAt,
         nextAttemptAt: nextAttemptAt,
       );

  /// Returns a shallow copy of this [PublicationDeliveryView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PublicationDeliveryView copyWith({
    String? webhookId,
    String? type,
    DateTime? createdAt,
    int? attempts,
    Object? lastStatus = _Undefined,
    Object? lastError = _Undefined,
    DateTime? deliveredAt = const _isc.$UndefinedDateTime(),
    DateTime? failedAt = const _isc.$UndefinedDateTime(),
    DateTime? nextAttemptAt = const _isc.$UndefinedDateTime(),
  }) {
    return PublicationDeliveryView(
      webhookId: webhookId ?? this.webhookId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastStatus: lastStatus is int? ? lastStatus : this.lastStatus,
      lastError: lastError is String? ? lastError : this.lastError,
      deliveredAt: deliveredAt is _isc.UndefinedSentinel
          ? this.deliveredAt
          : deliveredAt,
      failedAt: failedAt is _isc.UndefinedSentinel ? this.failedAt : failedAt,
      nextAttemptAt: nextAttemptAt is _isc.UndefinedSentinel
          ? this.nextAttemptAt
          : nextAttemptAt,
    );
  }
}
