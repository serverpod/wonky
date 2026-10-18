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
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevRejected._({
    this.clientOpId,
    required this.code,
    required this.message,
    this.detailsJson,
  });

  factory RevRejected({
    _is.UuidValue? clientOpId,
    required _ibphbk3y.RevRejectCode code,
    required String message,
    String? detailsJson,
  }) = _RevRejectedImpl;

  factory RevRejected.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevRejected(
      clientOpId: jsonSerialization['clientOpId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['clientOpId'],
            ),
      code: _ibphbk3y.RevRejectCode.fromJson(
        (jsonSerialization['code'] as String),
      ),
      message: jsonSerialization['message'] as String,
      detailsJson: jsonSerialization['detailsJson'] as String?,
    );
  }

  _is.UuidValue? clientOpId;

  _ibphbk3y.RevRejectCode code;

  String message;

  String? detailsJson;

  /// Returns a shallow copy of this [RevRejected]
  /// with some or all fields replaced by the given arguments.
  @override
  @_is.useResult
  RevRejected copyWith({
    _is.UuidValue? clientOpId = const _is.$UndefinedUuidValue(),
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
    return _is.SerializationManager.encode(this);
  }
}

class _RevRejectedImpl extends RevRejected {
  _RevRejectedImpl({
    _is.UuidValue? clientOpId,
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
  @_is.useResult
  @override
  RevRejected copyWith({
    _is.UuidValue? clientOpId = const _is.$UndefinedUuidValue(),
    _ibphbk3y.RevRejectCode? code,
    String? message,
    Object? detailsJson = _Undefined,
  }) {
    return RevRejected(
      clientOpId: clientOpId is _is.UndefinedSentinel
          ? this.clientOpId
          : clientOpId,
      code: code ?? this.code,
      message: message ?? this.message,
      detailsJson: detailsJson is String? ? detailsJson : this.detailsJson,
    );
  }
}
