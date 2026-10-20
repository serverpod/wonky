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

/// Result of starting a story (specs/18 §3 step 3).
abstract class SubmissionStarted
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SubmissionStarted._({required this.itemUuid});

  factory SubmissionStarted({required _is.UuidValue itemUuid}) =
      _SubmissionStartedImpl;

  factory SubmissionStarted.fromJson(Map<String, dynamic> jsonSerialization) {
    return SubmissionStarted(
      itemUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['itemUuid'],
      ),
    );
  }

  _is.UuidValue itemUuid;

  /// Returns a shallow copy of this [SubmissionStarted]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SubmissionStarted copyWith({_is.UuidValue? itemUuid});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmissionStarted',
      'itemUuid': itemUuid.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmissionStarted',
      'itemUuid': itemUuid.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SubmissionStartedImpl extends SubmissionStarted {
  _SubmissionStartedImpl({required _is.UuidValue itemUuid})
    : super._(itemUuid: itemUuid);

  /// Returns a shallow copy of this [SubmissionStarted]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SubmissionStarted copyWith({_is.UuidValue? itemUuid}) {
    return SubmissionStarted(itemUuid: itemUuid ?? this.itemUuid);
  }
}
