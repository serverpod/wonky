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

/// A labeled count of the usage analytics (specs/19 §3): items by kind,
/// sign-in methods, AI requests by feature or model.
abstract class AnalyticsCount
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AnalyticsCount._({
    required this.key,
    required this.count,
    int? amount,
  }) : amount = amount ?? 0;

  factory AnalyticsCount({
    required String key,
    required int count,
    int? amount,
  }) = _AnalyticsCountImpl;

  factory AnalyticsCount.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsCount(
      key: jsonSerialization['key'] as String,
      count: jsonSerialization['count'] as int,
      amount: jsonSerialization['amount'] as int?,
    );
  }

  String key;

  int count;

  /// A second measure where one applies (bytes of items, AI tokens); 0
  /// otherwise.
  int amount;

  /// Returns a shallow copy of this [AnalyticsCount]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AnalyticsCount copyWith({
    String? key,
    int? count,
    int? amount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsCount',
      'key': key,
      'count': count,
      'amount': amount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AnalyticsCount',
      'key': key,
      'count': count,
      'amount': amount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AnalyticsCountImpl extends AnalyticsCount {
  _AnalyticsCountImpl({
    required String key,
    required int count,
    int? amount,
  }) : super._(
         key: key,
         count: count,
         amount: amount,
       );

  /// Returns a shallow copy of this [AnalyticsCount]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AnalyticsCount copyWith({
    String? key,
    int? count,
    int? amount,
  }) {
    return AnalyticsCount(
      key: key ?? this.key,
      count: count ?? this.count,
      amount: amount ?? this.amount,
    );
  }
}
