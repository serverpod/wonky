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

abstract class AclFutureCallFanOutModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AclFutureCallFanOutModel._({
    required this.itemId,
    required this.kind,
    required this.affectedUsers,
  });

  factory AclFutureCallFanOutModel({
    required int itemId,
    required String kind,
    required List<int> affectedUsers,
  }) = _AclFutureCallFanOutModelImpl;

  factory AclFutureCallFanOutModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AclFutureCallFanOutModel(
      itemId: jsonSerialization['itemId'] as int,
      kind: jsonSerialization['kind'] as String,
      affectedUsers: _il4umwa0.Protocol().deserialize<List<int>>(
        jsonSerialization['affectedUsers'],
      ),
    );
  }

  int itemId;

  String kind;

  List<int> affectedUsers;

  /// Returns a shallow copy of this [AclFutureCallFanOutModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AclFutureCallFanOutModel copyWith({
    int? itemId,
    String? kind,
    List<int>? affectedUsers,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AclFutureCallFanOutModel',
      'itemId': itemId,
      'kind': kind,
      'affectedUsers': affectedUsers.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AclFutureCallFanOutModelImpl extends AclFutureCallFanOutModel {
  _AclFutureCallFanOutModelImpl({
    required int itemId,
    required String kind,
    required List<int> affectedUsers,
  }) : super._(
         itemId: itemId,
         kind: kind,
         affectedUsers: affectedUsers,
       );

  /// Returns a shallow copy of this [AclFutureCallFanOutModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AclFutureCallFanOutModel copyWith({
    int? itemId,
    String? kind,
    List<int>? affectedUsers,
  }) {
    return AclFutureCallFanOutModel(
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      affectedUsers:
          affectedUsers ?? this.affectedUsers.map((e0) => e0).toList(),
    );
  }
}
