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

/// Kind of a sheet tab.
enum SheetKind implements _is.SerializableModel {
  /// A regular grid of cells.
  grid,

  /// An object sheet holding one chart.
  chart;

  static SheetKind fromJson(String name) {
    switch (name) {
      case 'grid':
        return SheetKind.grid;
      case 'chart':
        return SheetKind.chart;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "SheetKind"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
