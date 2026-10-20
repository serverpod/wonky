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
import '../../../platform/analytics/models/analytics_cohort.dart' as _i3uny1ae;
import '../../../platform/analytics/models/analytics_count.dart' as _iucqk5df;
import '../../../platform/analytics/models/analytics_day.dart' as _ii75e3xb;

/// The usage analytics dashboard of Wonky Drive (specs/19 §3), for admins.
abstract class AnalyticsOverview
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AnalyticsOverview._({
    required this.days,
    required this.includeAdmins,
    required this.generatedAt,
    this.trackingSince,
    required this.accounts,
    required this.newAccounts,
    required this.activeToday,
    required this.weekly,
    required this.monthly,
    required this.stickiness,
    required this.series,
    required this.itemTotals,
    required this.storageBytes,
    required this.signInMethods,
    required this.aiFeatures,
    required this.aiModels,
    required this.aiRetentionDays,
    required this.sharedItems,
    required this.coEditedItems,
    required this.commenters,
    required this.cohorts,
  });

  factory AnalyticsOverview({
    required int days,
    required bool includeAdmins,
    required DateTime generatedAt,
    DateTime? trackingSince,
    required int accounts,
    required int newAccounts,
    required int activeToday,
    required int weekly,
    required int monthly,
    required double stickiness,
    required List<_ii75e3xb.AnalyticsDay> series,
    required List<_iucqk5df.AnalyticsCount> itemTotals,
    required int storageBytes,
    required List<_iucqk5df.AnalyticsCount> signInMethods,
    required List<_iucqk5df.AnalyticsCount> aiFeatures,
    required List<_iucqk5df.AnalyticsCount> aiModels,
    required int aiRetentionDays,
    required int sharedItems,
    required int coEditedItems,
    required int commenters,
    required List<_i3uny1ae.AnalyticsCohort> cohorts,
  }) = _AnalyticsOverviewImpl;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsOverview(
      days: jsonSerialization['days'] as int,
      includeAdmins: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['includeAdmins'],
      ),
      generatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['generatedAt'],
      ),
      trackingSince: jsonSerialization['trackingSince'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['trackingSince'],
            ),
      accounts: jsonSerialization['accounts'] as int,
      newAccounts: jsonSerialization['newAccounts'] as int,
      activeToday: jsonSerialization['activeToday'] as int,
      weekly: jsonSerialization['weekly'] as int,
      monthly: jsonSerialization['monthly'] as int,
      stickiness: (jsonSerialization['stickiness'] as num).toDouble(),
      series: _i8pkqg1o.Protocol().deserialize<List<_ii75e3xb.AnalyticsDay>>(
        jsonSerialization['series'],
      ),
      itemTotals: _i8pkqg1o.Protocol()
          .deserialize<List<_iucqk5df.AnalyticsCount>>(
            jsonSerialization['itemTotals'],
          ),
      storageBytes: jsonSerialization['storageBytes'] as int,
      signInMethods: _i8pkqg1o.Protocol()
          .deserialize<List<_iucqk5df.AnalyticsCount>>(
            jsonSerialization['signInMethods'],
          ),
      aiFeatures: _i8pkqg1o.Protocol()
          .deserialize<List<_iucqk5df.AnalyticsCount>>(
            jsonSerialization['aiFeatures'],
          ),
      aiModels: _i8pkqg1o.Protocol()
          .deserialize<List<_iucqk5df.AnalyticsCount>>(
            jsonSerialization['aiModels'],
          ),
      aiRetentionDays: jsonSerialization['aiRetentionDays'] as int,
      sharedItems: jsonSerialization['sharedItems'] as int,
      coEditedItems: jsonSerialization['coEditedItems'] as int,
      commenters: jsonSerialization['commenters'] as int,
      cohorts: _i8pkqg1o.Protocol()
          .deserialize<List<_i3uny1ae.AnalyticsCohort>>(
            jsonSerialization['cohorts'],
          ),
    );
  }

  /// Period length in days; [series] has one entry per day, oldest first,
  /// ending today (UTC).
  int days;

  bool includeAdmins;

  DateTime generatedAt;

  /// The first day with recorded activity (null: none yet).
  DateTime? trackingSince;

  /// All accounts now, and those created in the period.
  int accounts;

  int newAccounts;

  /// Distinct active users today, in the last 7 and the last 30 days.
  int activeToday;

  int weekly;

  int monthly;

  /// The average daily active users of the last 30 days over [monthly]
  /// (0–1).
  double stickiness;

  List<_ii75e3xb.AnalyticsDay> series;

  /// Items now (not trashed) by kind: count and bytes.
  List<_iucqk5df.AnalyticsCount> itemTotals;

  int storageBytes;

  /// Accounts by sign-in method (`email`, `google`, …); an account with
  /// two methods counts for both.
  List<_iucqk5df.AnalyticsCount> signInMethods;

  /// AI requests and tokens in the period by feature and by model.
  List<_iucqk5df.AnalyticsCount> aiFeatures;

  List<_iucqk5df.AnalyticsCount> aiModels;

  /// How many days of AI usage the server keeps.
  int aiRetentionDays;

  /// Items now shared with at least one other person.
  int sharedItems;

  /// Items edited by two or more people in the period.
  int coEditedItems;

  /// People who commented in the period.
  int commenters;

  List<_i3uny1ae.AnalyticsCohort> cohorts;

  /// Returns a shallow copy of this [AnalyticsOverview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AnalyticsOverview copyWith({
    int? days,
    bool? includeAdmins,
    DateTime? generatedAt,
    DateTime? trackingSince = const _isc.$UndefinedDateTime(),
    int? accounts,
    int? newAccounts,
    int? activeToday,
    int? weekly,
    int? monthly,
    double? stickiness,
    List<_ii75e3xb.AnalyticsDay>? series,
    List<_iucqk5df.AnalyticsCount>? itemTotals,
    int? storageBytes,
    List<_iucqk5df.AnalyticsCount>? signInMethods,
    List<_iucqk5df.AnalyticsCount>? aiFeatures,
    List<_iucqk5df.AnalyticsCount>? aiModels,
    int? aiRetentionDays,
    int? sharedItems,
    int? coEditedItems,
    int? commenters,
    List<_i3uny1ae.AnalyticsCohort>? cohorts,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsOverview',
      'days': days,
      'includeAdmins': includeAdmins,
      'generatedAt': generatedAt.toJson(),
      if (trackingSince != null) 'trackingSince': trackingSince?.toJson(),
      'accounts': accounts,
      'newAccounts': newAccounts,
      'activeToday': activeToday,
      'weekly': weekly,
      'monthly': monthly,
      'stickiness': stickiness,
      'series': series.toJson(valueToJson: (v) => v.toJson()),
      'itemTotals': itemTotals.toJson(valueToJson: (v) => v.toJson()),
      'storageBytes': storageBytes,
      'signInMethods': signInMethods.toJson(valueToJson: (v) => v.toJson()),
      'aiFeatures': aiFeatures.toJson(valueToJson: (v) => v.toJson()),
      'aiModels': aiModels.toJson(valueToJson: (v) => v.toJson()),
      'aiRetentionDays': aiRetentionDays,
      'sharedItems': sharedItems,
      'coEditedItems': coEditedItems,
      'commenters': commenters,
      'cohorts': cohorts.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AnalyticsOverview',
      'days': days,
      'includeAdmins': includeAdmins,
      'generatedAt': generatedAt.toJson(),
      if (trackingSince != null) 'trackingSince': trackingSince?.toJson(),
      'accounts': accounts,
      'newAccounts': newAccounts,
      'activeToday': activeToday,
      'weekly': weekly,
      'monthly': monthly,
      'stickiness': stickiness,
      'series': series.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'itemTotals': itemTotals.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'storageBytes': storageBytes,
      'signInMethods': signInMethods.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'aiFeatures': aiFeatures.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'aiModels': aiModels.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'aiRetentionDays': aiRetentionDays,
      'sharedItems': sharedItems,
      'coEditedItems': coEditedItems,
      'commenters': commenters,
      'cohorts': cohorts.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AnalyticsOverviewImpl extends AnalyticsOverview {
  _AnalyticsOverviewImpl({
    required int days,
    required bool includeAdmins,
    required DateTime generatedAt,
    DateTime? trackingSince,
    required int accounts,
    required int newAccounts,
    required int activeToday,
    required int weekly,
    required int monthly,
    required double stickiness,
    required List<_ii75e3xb.AnalyticsDay> series,
    required List<_iucqk5df.AnalyticsCount> itemTotals,
    required int storageBytes,
    required List<_iucqk5df.AnalyticsCount> signInMethods,
    required List<_iucqk5df.AnalyticsCount> aiFeatures,
    required List<_iucqk5df.AnalyticsCount> aiModels,
    required int aiRetentionDays,
    required int sharedItems,
    required int coEditedItems,
    required int commenters,
    required List<_i3uny1ae.AnalyticsCohort> cohorts,
  }) : super._(
         days: days,
         includeAdmins: includeAdmins,
         generatedAt: generatedAt,
         trackingSince: trackingSince,
         accounts: accounts,
         newAccounts: newAccounts,
         activeToday: activeToday,
         weekly: weekly,
         monthly: monthly,
         stickiness: stickiness,
         series: series,
         itemTotals: itemTotals,
         storageBytes: storageBytes,
         signInMethods: signInMethods,
         aiFeatures: aiFeatures,
         aiModels: aiModels,
         aiRetentionDays: aiRetentionDays,
         sharedItems: sharedItems,
         coEditedItems: coEditedItems,
         commenters: commenters,
         cohorts: cohorts,
       );

  /// Returns a shallow copy of this [AnalyticsOverview]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AnalyticsOverview copyWith({
    int? days,
    bool? includeAdmins,
    DateTime? generatedAt,
    DateTime? trackingSince = const _isc.$UndefinedDateTime(),
    int? accounts,
    int? newAccounts,
    int? activeToday,
    int? weekly,
    int? monthly,
    double? stickiness,
    List<_ii75e3xb.AnalyticsDay>? series,
    List<_iucqk5df.AnalyticsCount>? itemTotals,
    int? storageBytes,
    List<_iucqk5df.AnalyticsCount>? signInMethods,
    List<_iucqk5df.AnalyticsCount>? aiFeatures,
    List<_iucqk5df.AnalyticsCount>? aiModels,
    int? aiRetentionDays,
    int? sharedItems,
    int? coEditedItems,
    int? commenters,
    List<_i3uny1ae.AnalyticsCohort>? cohorts,
  }) {
    return AnalyticsOverview(
      days: days ?? this.days,
      includeAdmins: includeAdmins ?? this.includeAdmins,
      generatedAt: generatedAt ?? this.generatedAt,
      trackingSince: trackingSince is _isc.UndefinedSentinel
          ? this.trackingSince
          : trackingSince,
      accounts: accounts ?? this.accounts,
      newAccounts: newAccounts ?? this.newAccounts,
      activeToday: activeToday ?? this.activeToday,
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      stickiness: stickiness ?? this.stickiness,
      series: series ?? this.series.map((e0) => e0.copyWith()).toList(),
      itemTotals:
          itemTotals ?? this.itemTotals.map((e0) => e0.copyWith()).toList(),
      storageBytes: storageBytes ?? this.storageBytes,
      signInMethods:
          signInMethods ??
          this.signInMethods.map((e0) => e0.copyWith()).toList(),
      aiFeatures:
          aiFeatures ?? this.aiFeatures.map((e0) => e0.copyWith()).toList(),
      aiModels: aiModels ?? this.aiModels.map((e0) => e0.copyWith()).toList(),
      aiRetentionDays: aiRetentionDays ?? this.aiRetentionDays,
      sharedItems: sharedItems ?? this.sharedItems,
      coEditedItems: coEditedItems ?? this.coEditedItems,
      commenters: commenters ?? this.commenters,
      cohorts: cohorts ?? this.cohorts.map((e0) => e0.copyWith()).toList(),
    );
  }
}
