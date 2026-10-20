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

abstract class SubmissionRevisionView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SubmissionRevisionView._({
    required this.sequence,
    required this.revision,
    required this.submittedByName,
    required this.submittedAt,
    this.versionId,
  });

  factory SubmissionRevisionView({
    required int sequence,
    required int revision,
    required String submittedByName,
    required DateTime submittedAt,
    int? versionId,
  }) = _SubmissionRevisionViewImpl;

  factory SubmissionRevisionView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SubmissionRevisionView(
      sequence: jsonSerialization['sequence'] as int,
      revision: jsonSerialization['revision'] as int,
      submittedByName: jsonSerialization['submittedByName'] as String,
      submittedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['submittedAt'],
      ),
      versionId: jsonSerialization['versionId'] as int?,
    );
  }

  int sequence;

  int revision;

  String submittedByName;

  DateTime submittedAt;

  /// The named version of this submit, when it still exists.
  int? versionId;

  /// Returns a shallow copy of this [SubmissionRevisionView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SubmissionRevisionView copyWith({
    int? sequence,
    int? revision,
    String? submittedByName,
    DateTime? submittedAt,
    int? versionId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmissionRevisionView',
      'sequence': sequence,
      'revision': revision,
      'submittedByName': submittedByName,
      'submittedAt': submittedAt.toJson(),
      if (versionId != null) 'versionId': versionId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmissionRevisionView',
      'sequence': sequence,
      'revision': revision,
      'submittedByName': submittedByName,
      'submittedAt': submittedAt.toJson(),
      if (versionId != null) 'versionId': versionId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SubmissionRevisionViewImpl extends SubmissionRevisionView {
  _SubmissionRevisionViewImpl({
    required int sequence,
    required int revision,
    required String submittedByName,
    required DateTime submittedAt,
    int? versionId,
  }) : super._(
         sequence: sequence,
         revision: revision,
         submittedByName: submittedByName,
         submittedAt: submittedAt,
         versionId: versionId,
       );

  /// Returns a shallow copy of this [SubmissionRevisionView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SubmissionRevisionView copyWith({
    int? sequence,
    int? revision,
    String? submittedByName,
    DateTime? submittedAt,
    Object? versionId = _Undefined,
  }) {
    return SubmissionRevisionView(
      sequence: sequence ?? this.sequence,
      revision: revision ?? this.revision,
      submittedByName: submittedByName ?? this.submittedByName,
      submittedAt: submittedAt ?? this.submittedAt,
      versionId: versionId is int? ? versionId : this.versionId,
    );
  }
}
