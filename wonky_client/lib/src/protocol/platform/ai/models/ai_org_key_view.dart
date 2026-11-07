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
import '../../../platform/ai/models/ai_provider.dart' as _i1k6plh5;

/// What a client sees of the organization's shared API key: the provider,
/// the last four characters and who added it, never the key.
abstract class AiOrgKeyView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AiOrgKeyView._({
    required this.provider,
    required this.last4,
    required this.updatedAt,
    this.addedBy,
  });

  factory AiOrgKeyView({
    required _i1k6plh5.AiProvider provider,
    required String last4,
    required DateTime updatedAt,
    String? addedBy,
  }) = _AiOrgKeyViewImpl;

  factory AiOrgKeyView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiOrgKeyView(
      provider: _i1k6plh5.AiProvider.fromJson(
        (jsonSerialization['provider'] as String),
      ),
      last4: jsonSerialization['last4'] as String,
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      addedBy: jsonSerialization['addedBy'] as String?,
    );
  }

  _i1k6plh5.AiProvider provider;

  String last4;

  DateTime updatedAt;

  /// The display name of the member who added or last replaced it.
  String? addedBy;

  /// Returns a shallow copy of this [AiOrgKeyView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AiOrgKeyView copyWith({
    _i1k6plh5.AiProvider? provider,
    String? last4,
    DateTime? updatedAt,
    String? addedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiOrgKeyView',
      'provider': provider.toJson(),
      'last4': last4,
      'updatedAt': updatedAt.toJson(),
      if (addedBy != null) 'addedBy': addedBy,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiOrgKeyView',
      'provider': provider.toJson(),
      'last4': last4,
      'updatedAt': updatedAt.toJson(),
      if (addedBy != null) 'addedBy': addedBy,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiOrgKeyViewImpl extends AiOrgKeyView {
  _AiOrgKeyViewImpl({
    required _i1k6plh5.AiProvider provider,
    required String last4,
    required DateTime updatedAt,
    String? addedBy,
  }) : super._(
         provider: provider,
         last4: last4,
         updatedAt: updatedAt,
         addedBy: addedBy,
       );

  /// Returns a shallow copy of this [AiOrgKeyView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AiOrgKeyView copyWith({
    _i1k6plh5.AiProvider? provider,
    String? last4,
    DateTime? updatedAt,
    Object? addedBy = _Undefined,
  }) {
    return AiOrgKeyView(
      provider: provider ?? this.provider,
      last4: last4 ?? this.last4,
      updatedAt: updatedAt ?? this.updatedAt,
      addedBy: addedBy is String? ? addedBy : this.addedBy,
    );
  }
}
