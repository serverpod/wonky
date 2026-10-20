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
import 'package:wonky_client/src/protocol/protocol.dart' as _i8pkqg1o;

/// The fields a contributor filled in (specs/18 §4.2).
abstract class SubmissionValues
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SubmissionValues._({
    required this.title,
    this.summary,
    required this.tags,
    this.coverImage,
    this.authorBio,
    this.note,
  });

  factory SubmissionValues({
    required String title,
    String? summary,
    required List<String> tags,
    _isc.UuidValue? coverImage,
    String? authorBio,
    String? note,
  }) = _SubmissionValuesImpl;

  factory SubmissionValues.fromJson(Map<String, dynamic> jsonSerialization) {
    return SubmissionValues(
      title: jsonSerialization['title'] as String,
      summary: jsonSerialization['summary'] as String?,
      tags: _i8pkqg1o.Protocol().deserialize<List<String>>(
        jsonSerialization['tags'],
      ),
      coverImage: jsonSerialization['coverImage'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['coverImage'],
            ),
      authorBio: jsonSerialization['authorBio'] as String?,
      note: jsonSerialization['note'] as String?,
    );
  }

  String title;

  String? summary;

  List<String> tags;

  /// A `wonky-file` uuid of an image in the document.
  _isc.UuidValue? coverImage;

  String? authorBio;

  String? note;

  /// Returns a shallow copy of this [SubmissionValues]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SubmissionValues copyWith({
    String? title,
    String? summary,
    List<String>? tags,
    _isc.UuidValue? coverImage = const _isc.$UndefinedUuidValue(),
    String? authorBio,
    String? note,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmissionValues',
      'title': title,
      if (summary != null) 'summary': summary,
      'tags': tags.toJson(),
      if (coverImage != null) 'coverImage': coverImage?.toJson(),
      if (authorBio != null) 'authorBio': authorBio,
      if (note != null) 'note': note,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmissionValues',
      'title': title,
      if (summary != null) 'summary': summary,
      'tags': tags.toJson(),
      if (coverImage != null) 'coverImage': coverImage?.toJson(),
      if (authorBio != null) 'authorBio': authorBio,
      if (note != null) 'note': note,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SubmissionValuesImpl extends SubmissionValues {
  _SubmissionValuesImpl({
    required String title,
    String? summary,
    required List<String> tags,
    _isc.UuidValue? coverImage,
    String? authorBio,
    String? note,
  }) : super._(
         title: title,
         summary: summary,
         tags: tags,
         coverImage: coverImage,
         authorBio: authorBio,
         note: note,
       );

  /// Returns a shallow copy of this [SubmissionValues]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SubmissionValues copyWith({
    String? title,
    Object? summary = _Undefined,
    List<String>? tags,
    _isc.UuidValue? coverImage = const _isc.$UndefinedUuidValue(),
    Object? authorBio = _Undefined,
    Object? note = _Undefined,
  }) {
    return SubmissionValues(
      title: title ?? this.title,
      summary: summary is String? ? summary : this.summary,
      tags: tags ?? this.tags.map((e0) => e0).toList(),
      coverImage: coverImage is _isc.UndefinedSentinel
          ? this.coverImage
          : coverImage,
      authorBio: authorBio is String? ? authorBio : this.authorBio,
      note: note is String? ? note : this.note,
    );
  }
}
