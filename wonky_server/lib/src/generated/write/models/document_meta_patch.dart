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

/// One LWW metadata change: [field] ∈ themeId, pageSetup, language,
/// frontMatter, markdownFlavor; [valueJson] is the JSON-encoded new value
/// (may be `null`).
abstract class DocumentMetaPatch
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DocumentMetaPatch._({
    required this.field,
    required this.valueJson,
  });

  factory DocumentMetaPatch({
    required String field,
    required String valueJson,
  }) = _DocumentMetaPatchImpl;

  factory DocumentMetaPatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentMetaPatch(
      field: jsonSerialization['field'] as String,
      valueJson: jsonSerialization['valueJson'] as String,
    );
  }

  String field;

  String valueJson;

  /// Returns a shallow copy of this [DocumentMetaPatch]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocumentMetaPatch copyWith({
    String? field,
    String? valueJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentMetaPatch',
      'field': field,
      'valueJson': valueJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentMetaPatch',
      'field': field,
      'valueJson': valueJson,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DocumentMetaPatchImpl extends DocumentMetaPatch {
  _DocumentMetaPatchImpl({
    required String field,
    required String valueJson,
  }) : super._(
         field: field,
         valueJson: valueJson,
       );

  /// Returns a shallow copy of this [DocumentMetaPatch]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocumentMetaPatch copyWith({
    String? field,
    String? valueJson,
  }) {
    return DocumentMetaPatch(
      field: field ?? this.field,
      valueJson: valueJson ?? this.valueJson,
    );
  }
}
