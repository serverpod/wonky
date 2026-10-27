/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

part of 'doc_server_message.dart';

/// Theme / page setup / language / front matter / title / theme version changed.
abstract class DocMetaChanged extends _iototaiw.DocServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DocMetaChanged._({
    required this.field,
    required this.valueJson,
    this.authorId,
  });

  factory DocMetaChanged({
    required String field,
    required String valueJson,
    int? authorId,
  }) = _DocMetaChangedImpl;

  factory DocMetaChanged.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocMetaChanged(
      field: jsonSerialization['field'] as String,
      valueJson: jsonSerialization['valueJson'] as String,
      authorId: jsonSerialization['authorId'] as int?,
    );
  }

  /// themeId, pageSetup, language, frontMatter, markdownFlavor, title or
  /// themeVersion.
  String field;

  String valueJson;

  int? authorId;

  /// Returns a shallow copy of this [DocMetaChanged]
  /// with some or all fields replaced by the given arguments.
  @override
  @_isc.useResult
  DocMetaChanged copyWith({
    String? field,
    String? valueJson,
    int? authorId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocMetaChanged',
      'field': field,
      'valueJson': valueJson,
      if (authorId != null) 'authorId': authorId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocMetaChanged',
      'field': field,
      'valueJson': valueJson,
      if (authorId != null) 'authorId': authorId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _DocMetaChangedImpl extends DocMetaChanged {
  _DocMetaChangedImpl({
    required String field,
    required String valueJson,
    int? authorId,
  }) : super._(
         field: field,
         valueJson: valueJson,
         authorId: authorId,
       );

  /// Returns a shallow copy of this [DocMetaChanged]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DocMetaChanged copyWith({
    String? field,
    String? valueJson,
    Object? authorId = _Undefined,
  }) {
    return DocMetaChanged(
      field: field ?? this.field,
      valueJson: valueJson ?? this.valueJson,
      authorId: authorId is int? ? authorId : this.authorId,
    );
  }
}
