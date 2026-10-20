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

/// One UTC day of the usage analytics (specs/19 §3). Users are counted
/// once per day; the rolling counts are distinct users in the 7 and 30
/// days ending with [day].
abstract class AnalyticsDay
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AnalyticsDay._({
    required this.day,
    required this.active,
    required this.editors,
    required this.weekly,
    required this.monthly,
    required this.drive,
    required this.write,
    required this.sheets,
    required this.slides,
    required this.mcp,
    required this.signups,
    required this.accounts,
    required this.documents,
    required this.spreadsheets,
    required this.presentations,
    required this.files,
    required this.folders,
    required this.comments,
    required this.shares,
    required this.aiRequests,
    required this.aiTokens,
    required this.mcpCalls,
  });

  factory AnalyticsDay({
    required DateTime day,
    required int active,
    required int editors,
    required int weekly,
    required int monthly,
    required int drive,
    required int write,
    required int sheets,
    required int slides,
    required int mcp,
    required int signups,
    required int accounts,
    required int documents,
    required int spreadsheets,
    required int presentations,
    required int files,
    required int folders,
    required int comments,
    required int shares,
    required int aiRequests,
    required int aiTokens,
    required int mcpCalls,
  }) = _AnalyticsDayImpl;

  factory AnalyticsDay.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsDay(
      day: _is.DateTimeJsonExtension.fromJson(jsonSerialization['day']),
      active: jsonSerialization['active'] as int,
      editors: jsonSerialization['editors'] as int,
      weekly: jsonSerialization['weekly'] as int,
      monthly: jsonSerialization['monthly'] as int,
      drive: jsonSerialization['drive'] as int,
      write: jsonSerialization['write'] as int,
      sheets: jsonSerialization['sheets'] as int,
      slides: jsonSerialization['slides'] as int,
      mcp: jsonSerialization['mcp'] as int,
      signups: jsonSerialization['signups'] as int,
      accounts: jsonSerialization['accounts'] as int,
      documents: jsonSerialization['documents'] as int,
      spreadsheets: jsonSerialization['spreadsheets'] as int,
      presentations: jsonSerialization['presentations'] as int,
      files: jsonSerialization['files'] as int,
      folders: jsonSerialization['folders'] as int,
      comments: jsonSerialization['comments'] as int,
      shares: jsonSerialization['shares'] as int,
      aiRequests: jsonSerialization['aiRequests'] as int,
      aiTokens: jsonSerialization['aiTokens'] as int,
      mcpCalls: jsonSerialization['mcpCalls'] as int,
    );
  }

  DateTime day;

  /// Users active in any app or through MCP.
  int active;

  /// Users who created or edited something.
  int editors;

  int weekly;

  int monthly;

  int drive;

  int write;

  int sheets;

  int slides;

  int mcp;

  /// Accounts created that day, and all accounts at its end.
  int signups;

  int accounts;

  /// Items created that day by kind (templates of the gallery left out).
  int documents;

  int spreadsheets;

  int presentations;

  int files;

  int folders;

  /// Comments and replies by people (not system events).
  int comments;

  /// Direct grants to people (not inherited from a folder).
  int shares;

  int aiRequests;

  int aiTokens;

  int mcpCalls;

  /// Returns a shallow copy of this [AnalyticsDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AnalyticsDay copyWith({
    DateTime? day,
    int? active,
    int? editors,
    int? weekly,
    int? monthly,
    int? drive,
    int? write,
    int? sheets,
    int? slides,
    int? mcp,
    int? signups,
    int? accounts,
    int? documents,
    int? spreadsheets,
    int? presentations,
    int? files,
    int? folders,
    int? comments,
    int? shares,
    int? aiRequests,
    int? aiTokens,
    int? mcpCalls,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsDay',
      'day': day.toJson(),
      'active': active,
      'editors': editors,
      'weekly': weekly,
      'monthly': monthly,
      'drive': drive,
      'write': write,
      'sheets': sheets,
      'slides': slides,
      'mcp': mcp,
      'signups': signups,
      'accounts': accounts,
      'documents': documents,
      'spreadsheets': spreadsheets,
      'presentations': presentations,
      'files': files,
      'folders': folders,
      'comments': comments,
      'shares': shares,
      'aiRequests': aiRequests,
      'aiTokens': aiTokens,
      'mcpCalls': mcpCalls,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AnalyticsDay',
      'day': day.toJson(),
      'active': active,
      'editors': editors,
      'weekly': weekly,
      'monthly': monthly,
      'drive': drive,
      'write': write,
      'sheets': sheets,
      'slides': slides,
      'mcp': mcp,
      'signups': signups,
      'accounts': accounts,
      'documents': documents,
      'spreadsheets': spreadsheets,
      'presentations': presentations,
      'files': files,
      'folders': folders,
      'comments': comments,
      'shares': shares,
      'aiRequests': aiRequests,
      'aiTokens': aiTokens,
      'mcpCalls': mcpCalls,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AnalyticsDayImpl extends AnalyticsDay {
  _AnalyticsDayImpl({
    required DateTime day,
    required int active,
    required int editors,
    required int weekly,
    required int monthly,
    required int drive,
    required int write,
    required int sheets,
    required int slides,
    required int mcp,
    required int signups,
    required int accounts,
    required int documents,
    required int spreadsheets,
    required int presentations,
    required int files,
    required int folders,
    required int comments,
    required int shares,
    required int aiRequests,
    required int aiTokens,
    required int mcpCalls,
  }) : super._(
         day: day,
         active: active,
         editors: editors,
         weekly: weekly,
         monthly: monthly,
         drive: drive,
         write: write,
         sheets: sheets,
         slides: slides,
         mcp: mcp,
         signups: signups,
         accounts: accounts,
         documents: documents,
         spreadsheets: spreadsheets,
         presentations: presentations,
         files: files,
         folders: folders,
         comments: comments,
         shares: shares,
         aiRequests: aiRequests,
         aiTokens: aiTokens,
         mcpCalls: mcpCalls,
       );

  /// Returns a shallow copy of this [AnalyticsDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AnalyticsDay copyWith({
    DateTime? day,
    int? active,
    int? editors,
    int? weekly,
    int? monthly,
    int? drive,
    int? write,
    int? sheets,
    int? slides,
    int? mcp,
    int? signups,
    int? accounts,
    int? documents,
    int? spreadsheets,
    int? presentations,
    int? files,
    int? folders,
    int? comments,
    int? shares,
    int? aiRequests,
    int? aiTokens,
    int? mcpCalls,
  }) {
    return AnalyticsDay(
      day: day ?? this.day,
      active: active ?? this.active,
      editors: editors ?? this.editors,
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      drive: drive ?? this.drive,
      write: write ?? this.write,
      sheets: sheets ?? this.sheets,
      slides: slides ?? this.slides,
      mcp: mcp ?? this.mcp,
      signups: signups ?? this.signups,
      accounts: accounts ?? this.accounts,
      documents: documents ?? this.documents,
      spreadsheets: spreadsheets ?? this.spreadsheets,
      presentations: presentations ?? this.presentations,
      files: files ?? this.files,
      folders: folders ?? this.folders,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      aiRequests: aiRequests ?? this.aiRequests,
      aiTokens: aiTokens ?? this.aiTokens,
      mcpCalls: mcpCalls ?? this.mcpCalls,
    );
  }
}
