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

/// The Write assistant's quick actions (Write 09 §5.5): run without a
/// prompt in the chat, one model round trip on the fast model.
enum AssistantQuickAction implements _isc.SerializableModel {
  /// A summary in the panel.
  summarize,

  /// Small corrections as suggestions.
  proofread,

  /// Fixes asked for in open comments, as suggestions.
  addressComments,

  /// Rewrites to match the document's style guide, as suggestions.
  applyStyle;

  static AssistantQuickAction fromJson(String name) {
    switch (name) {
      case 'summarize':
        return AssistantQuickAction.summarize;
      case 'proofread':
        return AssistantQuickAction.proofread;
      case 'addressComments':
        return AssistantQuickAction.addressComments;
      case 'applyStyle':
        return AssistantQuickAction.applyStyle;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "AssistantQuickAction"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
