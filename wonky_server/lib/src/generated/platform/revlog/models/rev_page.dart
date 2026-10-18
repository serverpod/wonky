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
import 'dart:typed_data' as _idt;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;

/// A bootstrap page (RevLog spec 04 §3).
abstract class RevPage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevPage._({
    required this.revision,
    required this.body,
    required this.coverage,
    required this.excludedTables,
    this.nextCursor,
  });

  factory RevPage({
    required int revision,
    required _idt.ByteData body,
    required List<String> coverage,
    required List<String> excludedTables,
    String? nextCursor,
  }) = _RevPageImpl;

  factory RevPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevPage(
      revision: jsonSerialization['revision'] as int,
      body: _is.ByteDataJsonExtension.fromJson(jsonSerialization['body']),
      coverage: _il4umwa0.Protocol().deserialize<List<String>>(
        jsonSerialization['coverage'],
      ),
      excludedTables: _il4umwa0.Protocol().deserialize<List<String>>(
        jsonSerialization['excludedTables'],
      ),
      nextCursor: jsonSerialization['nextCursor'] as String?,
    );
  }

  /// Exact revision of every row in this page.
  int revision;

  /// gzip NDJSON (04 §3.1).
  _idt.ByteData body;

  List<String> coverage;

  /// structure: tables the client must load with kind == rows.
  List<String> excludedTables;

  String? nextCursor;

  /// Returns a shallow copy of this [RevPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevPage copyWith({
    int? revision,
    _idt.ByteData? body,
    List<String>? coverage,
    List<String>? excludedTables,
    String? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevPage',
      'revision': revision,
      'body': body.toJson(),
      'coverage': coverage.toJson(),
      'excludedTables': excludedTables.toJson(),
      if (nextCursor != null) 'nextCursor': nextCursor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevPage',
      'revision': revision,
      'body': body.toJson(),
      'coverage': coverage.toJson(),
      'excludedTables': excludedTables.toJson(),
      if (nextCursor != null) 'nextCursor': nextCursor,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RevPageImpl extends RevPage {
  _RevPageImpl({
    required int revision,
    required _idt.ByteData body,
    required List<String> coverage,
    required List<String> excludedTables,
    String? nextCursor,
  }) : super._(
         revision: revision,
         body: body,
         coverage: coverage,
         excludedTables: excludedTables,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [RevPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevPage copyWith({
    int? revision,
    _idt.ByteData? body,
    List<String>? coverage,
    List<String>? excludedTables,
    Object? nextCursor = _Undefined,
  }) {
    return RevPage(
      revision: revision ?? this.revision,
      body: body ?? this.body.clone(),
      coverage: coverage ?? this.coverage.map((e0) => e0).toList(),
      excludedTables:
          excludedTables ?? this.excludedTables.map((e0) => e0).toList(),
      nextCursor: nextCursor is String? ? nextCursor : this.nextCursor,
    );
  }
}
