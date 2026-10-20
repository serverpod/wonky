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

abstract class PublicationModeratorView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PublicationModeratorView._({
    required this.email,
    this.name,
  });

  factory PublicationModeratorView({
    required String email,
    String? name,
  }) = _PublicationModeratorViewImpl;

  factory PublicationModeratorView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PublicationModeratorView(
      email: jsonSerialization['email'] as String,
      name: jsonSerialization['name'] as String?,
    );
  }

  String email;

  /// Null while no account has this email.
  String? name;

  /// Returns a shallow copy of this [PublicationModeratorView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationModeratorView copyWith({
    String? email,
    String? name,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationModeratorView',
      'email': email,
      if (name != null) 'name': name,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PublicationModeratorView',
      'email': email,
      if (name != null) 'name': name,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationModeratorViewImpl extends PublicationModeratorView {
  _PublicationModeratorViewImpl({
    required String email,
    String? name,
  }) : super._(
         email: email,
         name: name,
       );

  /// Returns a shallow copy of this [PublicationModeratorView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationModeratorView copyWith({
    String? email,
    Object? name = _Undefined,
  }) {
    return PublicationModeratorView(
      email: email ?? this.email,
      name: name is String? ? name : this.name,
    );
  }
}
