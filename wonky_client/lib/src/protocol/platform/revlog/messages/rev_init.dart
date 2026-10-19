/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

part of 'rev_server_message.dart';

/// First message of a connection (RevLog spec 04 §2.2).
abstract class RevInit extends _i26f4ubs.RevServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RevInit._({
    required this.revision,
    required this.role,
    required this.sessionId,
    required this.schemaHash,
    required this.acceptedHashes,
    required this.stats,
    required this.prunedBelow,
    this.ops,
    required this.more,
    required this.bootstrap,
  });

  factory RevInit({
    required int revision,
    required _iyf5alod.AccessRole role,
    required String sessionId,
    required String schemaHash,
    required List<String> acceptedHashes,
    required String stats,
    required int prunedBelow,
    List<_irs0bkik.RevOpView>? ops,
    required bool more,
    required bool bootstrap,
  }) = _RevInitImpl;

  factory RevInit.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevInit(
      revision: jsonSerialization['revision'] as int,
      role: _iyf5alod.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      sessionId: jsonSerialization['sessionId'] as String,
      schemaHash: jsonSerialization['schemaHash'] as String,
      acceptedHashes: _i8pkqg1o.Protocol().deserialize<List<String>>(
        jsonSerialization['acceptedHashes'],
      ),
      stats: jsonSerialization['stats'] as String,
      prunedBelow: jsonSerialization['prunedBelow'] as int,
      ops: jsonSerialization['ops'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<List<_irs0bkik.RevOpView>>(
              jsonSerialization['ops'],
            ),
      more: _isc.BoolJsonExtension.fromJson(jsonSerialization['more']),
      bootstrap: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['bootstrap'],
      ),
    );
  }

  int revision;

  _iyf5alod.AccessRole role;

  String sessionId;

  String schemaHash;

  List<String> acceptedHashes;

  String stats;

  int prunedBelow;

  /// Ops in (knownRevision, revision], or null with [bootstrap].
  List<_irs0bkik.RevOpView>? ops;

  /// More ops follow by gap fill (ops() / RevRequestOps).
  bool more;

  /// The client must (re)load pages.
  bool bootstrap;

  /// Returns a shallow copy of this [RevInit]
  /// with some or all fields replaced by the given arguments.
  @override
  @_isc.useResult
  RevInit copyWith({
    int? revision,
    _iyf5alod.AccessRole? role,
    String? sessionId,
    String? schemaHash,
    List<String>? acceptedHashes,
    String? stats,
    int? prunedBelow,
    List<_irs0bkik.RevOpView>? ops =
        const _isc.$UndefinedList<_irs0bkik.RevOpView>(),
    bool? more,
    bool? bootstrap,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevInit',
      'revision': revision,
      'role': role.toJson(),
      'sessionId': sessionId,
      'schemaHash': schemaHash,
      'acceptedHashes': acceptedHashes.toJson(),
      'stats': stats,
      'prunedBelow': prunedBelow,
      if (ops != null) 'ops': ops?.toJson(valueToJson: (v) => v.toJson()),
      'more': more,
      'bootstrap': bootstrap,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevInit',
      'revision': revision,
      'role': role.toJson(),
      'sessionId': sessionId,
      'schemaHash': schemaHash,
      'acceptedHashes': acceptedHashes.toJson(),
      'stats': stats,
      'prunedBelow': prunedBelow,
      if (ops != null)
        'ops': ops?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'more': more,
      'bootstrap': bootstrap,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RevInitImpl extends RevInit {
  _RevInitImpl({
    required int revision,
    required _iyf5alod.AccessRole role,
    required String sessionId,
    required String schemaHash,
    required List<String> acceptedHashes,
    required String stats,
    required int prunedBelow,
    List<_irs0bkik.RevOpView>? ops,
    required bool more,
    required bool bootstrap,
  }) : super._(
         revision: revision,
         role: role,
         sessionId: sessionId,
         schemaHash: schemaHash,
         acceptedHashes: acceptedHashes,
         stats: stats,
         prunedBelow: prunedBelow,
         ops: ops,
         more: more,
         bootstrap: bootstrap,
       );

  /// Returns a shallow copy of this [RevInit]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RevInit copyWith({
    int? revision,
    _iyf5alod.AccessRole? role,
    String? sessionId,
    String? schemaHash,
    List<String>? acceptedHashes,
    String? stats,
    int? prunedBelow,
    List<_irs0bkik.RevOpView>? ops =
        const _isc.$UndefinedList<_irs0bkik.RevOpView>(),
    bool? more,
    bool? bootstrap,
  }) {
    return RevInit(
      revision: revision ?? this.revision,
      role: role ?? this.role,
      sessionId: sessionId ?? this.sessionId,
      schemaHash: schemaHash ?? this.schemaHash,
      acceptedHashes:
          acceptedHashes ?? this.acceptedHashes.map((e0) => e0).toList(),
      stats: stats ?? this.stats,
      prunedBelow: prunedBelow ?? this.prunedBelow,
      ops: ops is _isc.UndefinedSentinel
          ? this.ops?.map((e0) => e0.copyWith()).toList()
          : ops,
      more: more ?? this.more,
      bootstrap: bootstrap ?? this.bootstrap,
    );
  }
}
