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
import '../../platform/drive/drive_item_kind.dart' as _i26ubj99;

/// What a signed-out viewer learns about a link-shared document,
/// spreadsheet or presentation (`sharing.publicItem`, specs/06 §2.4).
/// No emails and no ids of people.
abstract class PublicItemView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PublicItemView._({
    required this.uuid,
    required this.kind,
    required this.name,
    required this.contentRef,
    required this.ownerName,
    required this.modifiedAt,
  });

  factory PublicItemView({
    required _is.UuidValue uuid,
    required _i26ubj99.DriveItemKind kind,
    required String name,
    required _is.UuidValue contentRef,
    required String ownerName,
    required DateTime modifiedAt,
  }) = _PublicItemViewImpl;

  factory PublicItemView.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicItemView(
      uuid: _is.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      kind: _i26ubj99.DriveItemKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      name: jsonSerialization['name'] as String,
      contentRef: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['contentRef'],
      ),
      ownerName: jsonSerialization['ownerName'] as String,
      modifiedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['modifiedAt'],
      ),
    );
  }

  _is.UuidValue uuid;

  _i26ubj99.DriveItemKind kind;

  String name;

  /// The content id the editors open (document, spreadsheet or deck).
  _is.UuidValue contentRef;

  /// The owner's display name.
  String ownerName;

  DateTime modifiedAt;

  /// Returns a shallow copy of this [PublicItemView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicItemView copyWith({
    _is.UuidValue? uuid,
    _i26ubj99.DriveItemKind? kind,
    String? name,
    _is.UuidValue? contentRef,
    String? ownerName,
    DateTime? modifiedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicItemView',
      'uuid': uuid.toJson(),
      'kind': kind.toJson(),
      'name': name,
      'contentRef': contentRef.toJson(),
      'ownerName': ownerName,
      'modifiedAt': modifiedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicItemView',
      'uuid': uuid.toJson(),
      'kind': kind.toJson(),
      'name': name,
      'contentRef': contentRef.toJson(),
      'ownerName': ownerName,
      'modifiedAt': modifiedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PublicItemViewImpl extends PublicItemView {
  _PublicItemViewImpl({
    required _is.UuidValue uuid,
    required _i26ubj99.DriveItemKind kind,
    required String name,
    required _is.UuidValue contentRef,
    required String ownerName,
    required DateTime modifiedAt,
  }) : super._(
         uuid: uuid,
         kind: kind,
         name: name,
         contentRef: contentRef,
         ownerName: ownerName,
         modifiedAt: modifiedAt,
       );

  /// Returns a shallow copy of this [PublicItemView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicItemView copyWith({
    _is.UuidValue? uuid,
    _i26ubj99.DriveItemKind? kind,
    String? name,
    _is.UuidValue? contentRef,
    String? ownerName,
    DateTime? modifiedAt,
  }) {
    return PublicItemView(
      uuid: uuid ?? this.uuid,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      contentRef: contentRef ?? this.contentRef,
      ownerName: ownerName ?? this.ownerName,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}
