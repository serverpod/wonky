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

/// Kind of a slide element (Slides 02 §3.11, §6). Append-only.
enum SlideElementKind implements _isc.SerializableModel {
  text,
  shape,
  line,
  image,
  table,
  icon,
  code,
  chart,
  group;

  static SlideElementKind fromJson(String name) {
    switch (name) {
      case 'text':
        return SlideElementKind.text;
      case 'shape':
        return SlideElementKind.shape;
      case 'line':
        return SlideElementKind.line;
      case 'image':
        return SlideElementKind.image;
      case 'table':
        return SlideElementKind.table;
      case 'icon':
        return SlideElementKind.icon;
      case 'code':
        return SlideElementKind.code;
      case 'chart':
        return SlideElementKind.chart;
      case 'group':
        return SlideElementKind.group;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SlideElementKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
