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
import '../../../platform/ai/models/style_guide_view.dart' as _iex8dq5x;

/// The style guides a user can use, the organization's default and (when
/// listed for a document) the document's choice (suite 10 §7).
abstract class StyleGuideLibrary
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StyleGuideLibrary._({
    required this.guides,
    this.orgKey,
    this.orgDefaultRef,
    this.documentRef,
    this.effectiveRef,
    required this.canSetDocument,
    required this.canSetOrgDefault,
  });

  factory StyleGuideLibrary({
    required List<_iex8dq5x.StyleGuideView> guides,
    String? orgKey,
    String? orgDefaultRef,
    String? documentRef,
    String? effectiveRef,
    required bool canSetDocument,
    required bool canSetOrgDefault,
  }) = _StyleGuideLibraryImpl;

  factory StyleGuideLibrary.fromJson(Map<String, dynamic> jsonSerialization) {
    return StyleGuideLibrary(
      guides: _i8pkqg1o.Protocol().deserialize<List<_iex8dq5x.StyleGuideView>>(
        jsonSerialization['guides'],
      ),
      orgKey: jsonSerialization['orgKey'] as String?,
      orgDefaultRef: jsonSerialization['orgDefaultRef'] as String?,
      documentRef: jsonSerialization['documentRef'] as String?,
      effectiveRef: jsonSerialization['effectiveRef'] as String?,
      canSetDocument: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canSetDocument'],
      ),
      canSetOrgDefault: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['canSetOrgDefault'],
      ),
    );
  }

  List<_iex8dq5x.StyleGuideView> guides;

  /// The user's organization (null = none, e.g. a public mail domain).
  String? orgKey;

  String? orgDefaultRef;

  /// The document's own choice (null = none).
  String? documentRef;

  /// What the document uses: its own choice, else the org default.
  String? effectiveRef;

  /// Whether the user may change the document's style guide (Editor+).
  bool canSetDocument;

  /// Whether the user may set the organization's default.
  bool canSetOrgDefault;

  /// Returns a shallow copy of this [StyleGuideLibrary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StyleGuideLibrary copyWith({
    List<_iex8dq5x.StyleGuideView>? guides,
    String? orgKey,
    String? orgDefaultRef,
    String? documentRef,
    String? effectiveRef,
    bool? canSetDocument,
    bool? canSetOrgDefault,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StyleGuideLibrary',
      'guides': guides.toJson(valueToJson: (v) => v.toJson()),
      if (orgKey != null) 'orgKey': orgKey,
      if (orgDefaultRef != null) 'orgDefaultRef': orgDefaultRef,
      if (documentRef != null) 'documentRef': documentRef,
      if (effectiveRef != null) 'effectiveRef': effectiveRef,
      'canSetDocument': canSetDocument,
      'canSetOrgDefault': canSetOrgDefault,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StyleGuideLibrary',
      'guides': guides.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (orgKey != null) 'orgKey': orgKey,
      if (orgDefaultRef != null) 'orgDefaultRef': orgDefaultRef,
      if (documentRef != null) 'documentRef': documentRef,
      if (effectiveRef != null) 'effectiveRef': effectiveRef,
      'canSetDocument': canSetDocument,
      'canSetOrgDefault': canSetOrgDefault,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StyleGuideLibraryImpl extends StyleGuideLibrary {
  _StyleGuideLibraryImpl({
    required List<_iex8dq5x.StyleGuideView> guides,
    String? orgKey,
    String? orgDefaultRef,
    String? documentRef,
    String? effectiveRef,
    required bool canSetDocument,
    required bool canSetOrgDefault,
  }) : super._(
         guides: guides,
         orgKey: orgKey,
         orgDefaultRef: orgDefaultRef,
         documentRef: documentRef,
         effectiveRef: effectiveRef,
         canSetDocument: canSetDocument,
         canSetOrgDefault: canSetOrgDefault,
       );

  /// Returns a shallow copy of this [StyleGuideLibrary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StyleGuideLibrary copyWith({
    List<_iex8dq5x.StyleGuideView>? guides,
    Object? orgKey = _Undefined,
    Object? orgDefaultRef = _Undefined,
    Object? documentRef = _Undefined,
    Object? effectiveRef = _Undefined,
    bool? canSetDocument,
    bool? canSetOrgDefault,
  }) {
    return StyleGuideLibrary(
      guides: guides ?? this.guides.map((e0) => e0.copyWith()).toList(),
      orgKey: orgKey is String? ? orgKey : this.orgKey,
      orgDefaultRef: orgDefaultRef is String?
          ? orgDefaultRef
          : this.orgDefaultRef,
      documentRef: documentRef is String? ? documentRef : this.documentRef,
      effectiveRef: effectiveRef is String? ? effectiveRef : this.effectiveRef,
      canSetDocument: canSetDocument ?? this.canSetDocument,
      canSetOrgDefault: canSetOrgDefault ?? this.canSetOrgDefault,
    );
  }
}
