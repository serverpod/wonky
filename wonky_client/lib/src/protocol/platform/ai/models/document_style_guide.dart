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

/// The style guide a Write document uses (Write 09 §5.9): Apply style
/// follows it and the other assistant actions get it as context. A side
/// table keyed by the document's drive item (the document row is not
/// changed).
abstract class DocumentStyleGuide
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DocumentStyleGuide._({
    this.id,
    required this.itemId,
    required this.styleRef,
    this.setById,
    required this.updatedAt,
  });

  factory DocumentStyleGuide({
    int? id,
    required int itemId,
    required String styleRef,
    int? setById,
    required DateTime updatedAt,
  }) = _DocumentStyleGuideImpl;

  factory DocumentStyleGuide.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentStyleGuide(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      styleRef: jsonSerialization['styleRef'] as String,
      setById: jsonSerialization['setById'] as int?,
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int itemId;

  /// `builtin:<key>` or `custom:<uuid>`.
  String styleRef;

  int? setById;

  DateTime updatedAt;

  /// Returns a shallow copy of this [DocumentStyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DocumentStyleGuide copyWith({
    int? id,
    int? itemId,
    String? styleRef,
    int? setById,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentStyleGuide',
      if (id != null) 'id': id,
      'itemId': itemId,
      'styleRef': styleRef,
      if (setById != null) 'setById': setById,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentStyleGuide',
      if (id != null) 'id': id,
      'itemId': itemId,
      'styleRef': styleRef,
      if (setById != null) 'setById': setById,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentStyleGuideImpl extends DocumentStyleGuide {
  _DocumentStyleGuideImpl({
    int? id,
    required int itemId,
    required String styleRef,
    int? setById,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         itemId: itemId,
         styleRef: styleRef,
         setById: setById,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [DocumentStyleGuide]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DocumentStyleGuide copyWith({
    Object? id = _Undefined,
    int? itemId,
    String? styleRef,
    Object? setById = _Undefined,
    DateTime? updatedAt,
  }) {
    return DocumentStyleGuide(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      styleRef: styleRef ?? this.styleRef,
      setById: setById is int? ? setById : this.setById,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
