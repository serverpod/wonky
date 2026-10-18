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
import '../../platform/drive/drive_change_kind.dart' as _ijkkpwz4;

/// Internal session.messages payload on `drive:user:<userId>`.
abstract class DriveChangeSignal
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DriveChangeSignal._({
    required this.kind,
    required this.itemUuid,
    this.itemUuids,
  });

  factory DriveChangeSignal({
    required _ijkkpwz4.DriveChangeKind kind,
    required _is.UuidValue itemUuid,
    List<_is.UuidValue>? itemUuids,
  }) = _DriveChangeSignalImpl;

  factory DriveChangeSignal.fromJson(Map<String, dynamic> jsonSerialization) {
    return DriveChangeSignal(
      kind: _ijkkpwz4.DriveChangeKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      itemUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['itemUuid'],
      ),
      itemUuids: jsonSerialization['itemUuids'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<List<_is.UuidValue>>(
              jsonSerialization['itemUuids'],
            ),
    );
  }

  _ijkkpwz4.DriveChangeKind kind;

  _is.UuidValue itemUuid;

  /// More items with the same change (one signal per user for a folder's
  /// subtree, CQ-26); [itemUuid] is the first of them.
  List<_is.UuidValue>? itemUuids;

  /// Returns a shallow copy of this [DriveChangeSignal]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DriveChangeSignal copyWith({
    _ijkkpwz4.DriveChangeKind? kind,
    _is.UuidValue? itemUuid,
    List<_is.UuidValue>? itemUuids = const _is.$UndefinedList<_is.UuidValue>(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DriveChangeSignal',
      'kind': kind.toJson(),
      'itemUuid': itemUuid.toJson(),
      if (itemUuids != null)
        'itemUuids': itemUuids?.toJson(valueToJson: (v) => v.toJson()),
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

class _DriveChangeSignalImpl extends DriveChangeSignal {
  _DriveChangeSignalImpl({
    required _ijkkpwz4.DriveChangeKind kind,
    required _is.UuidValue itemUuid,
    List<_is.UuidValue>? itemUuids,
  }) : super._(
         kind: kind,
         itemUuid: itemUuid,
         itemUuids: itemUuids,
       );

  /// Returns a shallow copy of this [DriveChangeSignal]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DriveChangeSignal copyWith({
    _ijkkpwz4.DriveChangeKind? kind,
    _is.UuidValue? itemUuid,
    List<_is.UuidValue>? itemUuids = const _is.$UndefinedList<_is.UuidValue>(),
  }) {
    return DriveChangeSignal(
      kind: kind ?? this.kind,
      itemUuid: itemUuid ?? this.itemUuid,
      itemUuids: itemUuids is _is.UndefinedSentinel
          ? this.itemUuids?.map((e0) => e0).toList()
          : itemUuids,
    );
  }
}
