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
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../platform/users/user_summary.dart' as _itg9e9ms;

abstract class SheetsContributorStat
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SheetsContributorStat._({
    this.user,
    required this.actorKind,
    required this.edits,
    required this.lastEditAt,
  });

  factory SheetsContributorStat({
    _itg9e9ms.UserSummary? user,
    required _ipbpecg8.ActorKind actorKind,
    required int edits,
    required DateTime lastEditAt,
  }) = _SheetsContributorStatImpl;

  factory SheetsContributorStat.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SheetsContributorStat(
      user: jsonSerialization['user'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<_itg9e9ms.UserSummary>(
              jsonSerialization['user'],
            ),
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      edits: jsonSerialization['edits'] as int,
      lastEditAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastEditAt'],
      ),
    );
  }

  _itg9e9ms.UserSummary? user;

  _ipbpecg8.ActorKind actorKind;

  int edits;

  DateTime lastEditAt;

  /// Returns a shallow copy of this [SheetsContributorStat]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SheetsContributorStat copyWith({
    _itg9e9ms.UserSummary? user = const _UndefinedSheetsContributorStat$user(),
    _ipbpecg8.ActorKind? actorKind,
    int? edits,
    DateTime? lastEditAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SheetsContributorStat',
      if (user != null) 'user': user?.toJson(),
      'actorKind': actorKind.toJson(),
      'edits': edits,
      'lastEditAt': lastEditAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SheetsContributorStat',
      if (user != null) 'user': user?.toJsonForProtocol(),
      'actorKind': actorKind.toJson(),
      'edits': edits,
      'lastEditAt': lastEditAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _UndefinedSheetsContributorStat$user extends _isc.UndefinedSentinel
    implements _itg9e9ms.UserSummary {
  const _UndefinedSheetsContributorStat$user();
}

class _SheetsContributorStatImpl extends SheetsContributorStat {
  _SheetsContributorStatImpl({
    _itg9e9ms.UserSummary? user,
    required _ipbpecg8.ActorKind actorKind,
    required int edits,
    required DateTime lastEditAt,
  }) : super._(
         user: user,
         actorKind: actorKind,
         edits: edits,
         lastEditAt: lastEditAt,
       );

  /// Returns a shallow copy of this [SheetsContributorStat]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SheetsContributorStat copyWith({
    _itg9e9ms.UserSummary? user = const _UndefinedSheetsContributorStat$user(),
    _ipbpecg8.ActorKind? actorKind,
    int? edits,
    DateTime? lastEditAt,
  }) {
    return SheetsContributorStat(
      user: user is _isc.UndefinedSentinel ? this.user?.copyWith() : user,
      actorKind: actorKind ?? this.actorKind,
      edits: edits ?? this.edits,
      lastEditAt: lastEditAt ?? this.lastEditAt,
    );
  }
}
