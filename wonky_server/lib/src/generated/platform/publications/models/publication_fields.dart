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
import '../../../platform/publications/models/publication_field_mode.dart'
    as _i5yv7v4s;

/// Which submission fields a publication asks for (specs/18 §8.1). The
/// title is always asked for and required.
abstract class PublicationFields
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PublicationFields._({
    required this.summary,
    required this.tags,
    required this.allowedTags,
    required this.coverImage,
    required this.authorBio,
    required this.note,
  });

  factory PublicationFields({
    required _i5yv7v4s.PublicationFieldMode summary,
    required _i5yv7v4s.PublicationFieldMode tags,
    required List<String> allowedTags,
    required _i5yv7v4s.PublicationFieldMode coverImage,
    required _i5yv7v4s.PublicationFieldMode authorBio,
    required _i5yv7v4s.PublicationFieldMode note,
  }) = _PublicationFieldsImpl;

  factory PublicationFields.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationFields(
      summary: _i5yv7v4s.PublicationFieldMode.fromJson(
        (jsonSerialization['summary'] as String),
      ),
      tags: _i5yv7v4s.PublicationFieldMode.fromJson(
        (jsonSerialization['tags'] as String),
      ),
      allowedTags: _il4umwa0.Protocol().deserialize<List<String>>(
        jsonSerialization['allowedTags'],
      ),
      coverImage: _i5yv7v4s.PublicationFieldMode.fromJson(
        (jsonSerialization['coverImage'] as String),
      ),
      authorBio: _i5yv7v4s.PublicationFieldMode.fromJson(
        (jsonSerialization['authorBio'] as String),
      ),
      note: _i5yv7v4s.PublicationFieldMode.fromJson(
        (jsonSerialization['note'] as String),
      ),
    );
  }

  _i5yv7v4s.PublicationFieldMode summary;

  _i5yv7v4s.PublicationFieldMode tags;

  /// When not empty, tags must come from this list.
  List<String> allowedTags;

  _i5yv7v4s.PublicationFieldMode coverImage;

  _i5yv7v4s.PublicationFieldMode authorBio;

  _i5yv7v4s.PublicationFieldMode note;

  /// Returns a shallow copy of this [PublicationFields]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationFields copyWith({
    _i5yv7v4s.PublicationFieldMode? summary,
    _i5yv7v4s.PublicationFieldMode? tags,
    List<String>? allowedTags,
    _i5yv7v4s.PublicationFieldMode? coverImage,
    _i5yv7v4s.PublicationFieldMode? authorBio,
    _i5yv7v4s.PublicationFieldMode? note,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationFields',
      'summary': summary.toJson(),
      'tags': tags.toJson(),
      'allowedTags': allowedTags.toJson(),
      'coverImage': coverImage.toJson(),
      'authorBio': authorBio.toJson(),
      'note': note.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationFields',
      'summary': summary.toJson(),
      'tags': tags.toJson(),
      'allowedTags': allowedTags.toJson(),
      'coverImage': coverImage.toJson(),
      'authorBio': authorBio.toJson(),
      'note': note.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PublicationFieldsImpl extends PublicationFields {
  _PublicationFieldsImpl({
    required _i5yv7v4s.PublicationFieldMode summary,
    required _i5yv7v4s.PublicationFieldMode tags,
    required List<String> allowedTags,
    required _i5yv7v4s.PublicationFieldMode coverImage,
    required _i5yv7v4s.PublicationFieldMode authorBio,
    required _i5yv7v4s.PublicationFieldMode note,
  }) : super._(
         summary: summary,
         tags: tags,
         allowedTags: allowedTags,
         coverImage: coverImage,
         authorBio: authorBio,
         note: note,
       );

  /// Returns a shallow copy of this [PublicationFields]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationFields copyWith({
    _i5yv7v4s.PublicationFieldMode? summary,
    _i5yv7v4s.PublicationFieldMode? tags,
    List<String>? allowedTags,
    _i5yv7v4s.PublicationFieldMode? coverImage,
    _i5yv7v4s.PublicationFieldMode? authorBio,
    _i5yv7v4s.PublicationFieldMode? note,
  }) {
    return PublicationFields(
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      allowedTags: allowedTags ?? this.allowedTags.map((e0) => e0).toList(),
      coverImage: coverImage ?? this.coverImage,
      authorBio: authorBio ?? this.authorBio,
      note: note ?? this.note,
    );
  }
}
