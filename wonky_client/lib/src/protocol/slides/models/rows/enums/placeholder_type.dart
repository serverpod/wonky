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

/// Placeholder type of a layout/master placeholder or a slide's placeholder
/// instance (Slides 02 §3.11, 05 §5). Append-only.
enum PlaceholderType implements _isc.SerializableModel {
  title,
  subtitle,
  body,
  picture,
  chart,
  table,
  code,
  caption,
  bigNumber,
  quote,
  attribution,
  slideNumber,
  footer,
  date,
  object;

  static PlaceholderType fromJson(String name) {
    switch (name) {
      case 'title':
        return PlaceholderType.title;
      case 'subtitle':
        return PlaceholderType.subtitle;
      case 'body':
        return PlaceholderType.body;
      case 'picture':
        return PlaceholderType.picture;
      case 'chart':
        return PlaceholderType.chart;
      case 'table':
        return PlaceholderType.table;
      case 'code':
        return PlaceholderType.code;
      case 'caption':
        return PlaceholderType.caption;
      case 'bigNumber':
        return PlaceholderType.bigNumber;
      case 'quote':
        return PlaceholderType.quote;
      case 'attribution':
        return PlaceholderType.attribution;
      case 'slideNumber':
        return PlaceholderType.slideNumber;
      case 'footer':
        return PlaceholderType.footer;
      case 'date':
        return PlaceholderType.date;
      case 'object':
        return PlaceholderType.object;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "PlaceholderType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
