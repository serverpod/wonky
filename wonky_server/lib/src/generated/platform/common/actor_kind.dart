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

/// Who performed a change: a person, an agent or the system. Used by the
/// RevLog ops, activity, comments, presence and the Write op log.
enum ActorKind implements _is.SerializableModel {
  /// A person through an app.
  user,

  /// An MCP client acting with a personal access token.
  mcp,

  /// The built-in AI assistant.
  ai,

  /// A Sheets script (trigger, macro, custom function).
  script,

  /// The server itself (jobs, migrations, normalizers).
  system;

  static ActorKind fromJson(String name) {
    switch (name) {
      case 'user':
        return ActorKind.user;
      case 'mcp':
        return ActorKind.mcp;
      case 'ai':
        return ActorKind.ai;
      case 'script':
        return ActorKind.script;
      case 'system':
        return ActorKind.system;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "ActorKind"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
