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

/// A weekly sign-up cohort (specs/19 §3.5): accounts created in the week
/// starting [week] (Monday, UTC) and how many of them were active N weeks
/// later.
abstract class AnalyticsCohort
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AnalyticsCohort._({
    required this.week,
    required this.size,
    required this.active,
  });

  factory AnalyticsCohort({
    required DateTime week,
    required int size,
    required List<int?> active,
  }) = _AnalyticsCohortImpl;

  factory AnalyticsCohort.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsCohort(
      week: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['week']),
      size: jsonSerialization['size'] as int,
      active: _i8pkqg1o.Protocol().deserialize<List<int?>>(
        jsonSerialization['active'],
      ),
    );
  }

  DateTime week;

  int size;

  /// Index N: active users of the cohort in week N after sign-up (0 = the
  /// sign-up week). Null where the week is in the future or ended before
  /// activity was recorded.
  List<int?> active;

  /// Returns a shallow copy of this [AnalyticsCohort]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AnalyticsCohort copyWith({
    DateTime? week,
    int? size,
    List<int?>? active,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsCohort',
      'week': week.toJson(),
      'size': size,
      'active': active.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AnalyticsCohort',
      'week': week.toJson(),
      'size': size,
      'active': active.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AnalyticsCohortImpl extends AnalyticsCohort {
  _AnalyticsCohortImpl({
    required DateTime week,
    required int size,
    required List<int?> active,
  }) : super._(
         week: week,
         size: size,
         active: active,
       );

  /// Returns a shallow copy of this [AnalyticsCohort]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AnalyticsCohort copyWith({
    DateTime? week,
    int? size,
    List<int?>? active,
  }) {
    return AnalyticsCohort(
      week: week ?? this.week,
      size: size ?? this.size,
      active: active ?? this.active.map((e0) => e0).toList(),
    );
  }
}
