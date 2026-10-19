/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

part of 'rev_server_message.dart';

/// The op was not committed (RevLog spec 04 §4). [clientOpId] null: a
/// session-level error, after which the stream closes.
abstract class RevRejected extends _i26f4ubs.RevServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RevRejected._({
    this.clientOpId,
    required this.code,
    required this.message,
    this.detailsJson,
  });

  factory RevRejected({
    _isc.UuidValue? clientOpId,
    required _ibphbk3y.RevRejectCode code,
    required String message,
    String? detailsJson,
  }) = _RevRejectedImpl;

  factory RevRejected.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevRejected(
      clientOpId: jsonSerialization['clientOpId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['clientOpId'],
            ),
      code: _ibphbk3y.RevRejectCode.fromJson(
        (jsonSerialization['code'] as String),
      ),
      message: jsonSerialization['message'] as String,
      detailsJson: jsonSerialization['detailsJson'] as String?,
    );
  }

  _isc.UuidValue? clientOpId;

  _ibphbk3y.RevRejectCode code;

  String message;

  String? detailsJson;

  /// Returns a shallow copy of this [RevRejected]
  /// with some or all fields replaced by the given arguments.
  @override
  @_isc.useResult
  RevRejected copyWith({
    _isc.UuidValue? clientOpId = const _isc.$UndefinedUuidValue(),
    _ibphbk3y.RevRejectCode? code,
    String? message,
    String? detailsJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevRejected',
      if (clientOpId != null) 'clientOpId': clientOpId?.toJson(),
      'code': code.toJson(),
      'message': message,
      if (detailsJson != null) 'detailsJson': detailsJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevRejected',
      if (clientOpId != null) 'clientOpId': clientOpId?.toJson(),
      'code': code.toJson(),
      'message': message,
      if (detailsJson != null) 'detailsJson': detailsJson,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RevRejectedImpl extends RevRejected {
  _RevRejectedImpl({
    _isc.UuidValue? clientOpId,
    required _ibphbk3y.RevRejectCode code,
    required String message,
    String? detailsJson,
  }) : super._(
         clientOpId: clientOpId,
         code: code,
         message: message,
         detailsJson: detailsJson,
       );

  /// Returns a shallow copy of this [RevRejected]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RevRejected copyWith({
    _isc.UuidValue? clientOpId = const _isc.$UndefinedUuidValue(),
    _ibphbk3y.RevRejectCode? code,
    String? message,
    Object? detailsJson = _Undefined,
  }) {
    return RevRejected(
      clientOpId: clientOpId is _isc.UndefinedSentinel
          ? this.clientOpId
          : clientOpId,
      code: code ?? this.code,
      message: message ?? this.message,
      detailsJson: detailsJson is String? ? detailsJson : this.detailsJson,
    );
  }
}
