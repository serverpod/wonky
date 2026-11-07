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

/// Who can open an item besides the people it is shared with (specs/06
/// §2.2–2.3): no one else, everyone in an organization, or anyone with
/// the link.
enum GeneralAccess implements _isc.SerializableModel {
  restricted,
  organization,
  link;

  static GeneralAccess fromJson(String name) {
    switch (name) {
      case 'restricted':
        return GeneralAccess.restricted;
      case 'organization':
        return GeneralAccess.organization;
      case 'link':
        return GeneralAccess.link;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "GeneralAccess"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
