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
import '../../../platform/publications/models/submission_status.dart'
    as _igclxad1;

/// A story the caller can continue (specs/18 §3).
abstract class PublicationOpenSubmission
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PublicationOpenSubmission._({
    required this.itemUuid,
    required this.name,
    required this.status,
    required this.updatedAt,
  });

  factory PublicationOpenSubmission({
    required _is.UuidValue itemUuid,
    required String name,
    required _igclxad1.SubmissionStatus status,
    required DateTime updatedAt,
  }) = _PublicationOpenSubmissionImpl;

  factory PublicationOpenSubmission.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PublicationOpenSubmission(
      itemUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['itemUuid'],
      ),
      name: jsonSerialization['name'] as String,
      status: _igclxad1.SubmissionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  _is.UuidValue itemUuid;

  String name;

  _igclxad1.SubmissionStatus status;

  DateTime updatedAt;

  /// Returns a shallow copy of this [PublicationOpenSubmission]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationOpenSubmission copyWith({
    _is.UuidValue? itemUuid,
    String? name,
    _igclxad1.SubmissionStatus? status,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationOpenSubmission',
      'itemUuid': itemUuid.toJson(),
      'name': name,
      'status': status.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationOpenSubmission',
      'itemUuid': itemUuid.toJson(),
      'name': name,
      'status': status.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PublicationOpenSubmissionImpl extends PublicationOpenSubmission {
  _PublicationOpenSubmissionImpl({
    required _is.UuidValue itemUuid,
    required String name,
    required _igclxad1.SubmissionStatus status,
    required DateTime updatedAt,
  }) : super._(
         itemUuid: itemUuid,
         name: name,
         status: status,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PublicationOpenSubmission]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationOpenSubmission copyWith({
    _is.UuidValue? itemUuid,
    String? name,
    _igclxad1.SubmissionStatus? status,
    DateTime? updatedAt,
  }) {
    return PublicationOpenSubmission(
      itemUuid: itemUuid ?? this.itemUuid,
      name: name ?? this.name,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
