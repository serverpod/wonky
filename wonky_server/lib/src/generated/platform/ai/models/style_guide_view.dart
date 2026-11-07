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

/// A style guide as the client sees it (built-in, the user's own, or one
/// shared with the user's organization).
abstract class StyleGuideView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  StyleGuideView._({
    required this.ref,
    required this.name,
    required this.description,
    required this.markdown,
    required this.source,
    required this.sharedWithOrg,
    this.ownerName,
    required this.editable,
    this.updatedAt,
  });

  factory StyleGuideView({
    required String ref,
    required String name,
    required String description,
    required String markdown,
    required String source,
    required bool sharedWithOrg,
    String? ownerName,
    required bool editable,
    DateTime? updatedAt,
  }) = _StyleGuideViewImpl;

  factory StyleGuideView.fromJson(Map<String, dynamic> jsonSerialization) {
    return StyleGuideView(
      ref: jsonSerialization['ref'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      markdown: jsonSerialization['markdown'] as String,
      source: jsonSerialization['source'] as String,
      sharedWithOrg: _is.BoolJsonExtension.fromJson(
        jsonSerialization['sharedWithOrg'],
      ),
      ownerName: jsonSerialization['ownerName'] as String?,
      editable: _is.BoolJsonExtension.fromJson(jsonSerialization['editable']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// `builtin:<key>` or `custom:<uuid>`.
  String ref;

  String name;

  String description;

  String markdown;

  /// builtIn | mine | organization
  String source;

  /// A custom guide shared with the organization.
  bool sharedWithOrg;

  String? ownerName;

  /// Whether the user may edit or delete it (their own).
  bool editable;

  DateTime? updatedAt;

  /// Returns a shallow copy of this [StyleGuideView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StyleGuideView copyWith({
    String? ref,
    String? name,
    String? description,
    String? markdown,
    String? source,
    bool? sharedWithOrg,
    String? ownerName,
    bool? editable,
    DateTime? updatedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StyleGuideView',
      'ref': ref,
      'name': name,
      'description': description,
      'markdown': markdown,
      'source': source,
      'sharedWithOrg': sharedWithOrg,
      if (ownerName != null) 'ownerName': ownerName,
      'editable': editable,
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StyleGuideView',
      'ref': ref,
      'name': name,
      'description': description,
      'markdown': markdown,
      'source': source,
      'sharedWithOrg': sharedWithOrg,
      if (ownerName != null) 'ownerName': ownerName,
      'editable': editable,
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StyleGuideViewImpl extends StyleGuideView {
  _StyleGuideViewImpl({
    required String ref,
    required String name,
    required String description,
    required String markdown,
    required String source,
    required bool sharedWithOrg,
    String? ownerName,
    required bool editable,
    DateTime? updatedAt,
  }) : super._(
         ref: ref,
         name: name,
         description: description,
         markdown: markdown,
         source: source,
         sharedWithOrg: sharedWithOrg,
         ownerName: ownerName,
         editable: editable,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [StyleGuideView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StyleGuideView copyWith({
    String? ref,
    String? name,
    String? description,
    String? markdown,
    String? source,
    bool? sharedWithOrg,
    Object? ownerName = _Undefined,
    bool? editable,
    DateTime? updatedAt = const _is.$UndefinedDateTime(),
  }) {
    return StyleGuideView(
      ref: ref ?? this.ref,
      name: name ?? this.name,
      description: description ?? this.description,
      markdown: markdown ?? this.markdown,
      source: source ?? this.source,
      sharedWithOrg: sharedWithOrg ?? this.sharedWithOrg,
      ownerName: ownerName is String? ? ownerName : this.ownerName,
      editable: editable ?? this.editable,
      updatedAt: updatedAt is _is.UndefinedSentinel
          ? this.updatedAt
          : updatedAt,
    );
  }
}
