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

/// Where a user was active (usage analytics, specs/19 §2): one of the
/// apps, or an MCP client with a personal access token.
enum UsageApp implements _isc.SerializableModel {
  drive,
  write,
  sheets,
  slides,
  mcp;

  static UsageApp fromJson(String name) {
    switch (name) {
      case 'drive':
        return UsageApp.drive;
      case 'write':
        return UsageApp.write;
      case 'sheets':
        return UsageApp.sheets;
      case 'slides':
        return UsageApp.slides;
      case 'mcp':
        return UsageApp.mcp;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "UsageApp"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
