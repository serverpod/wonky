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

enum NotificationKind implements _is.SerializableModel {
  mention,
  reply,
  assigned,
  shared,
  accessRequest,
  suggestion,
  suggestionDecided,
  ownershipTransfer,
  scriptFailure,

  /// (v2) Storage notice, e.g. over quota after the backfill (Drive 03 §9).
  storage,

  /// Bugs & improvements (specs/16 §12): a comment on my post or one I
  /// commented on.
  boardReply,

  /// A post I wrote or voted on changed status (planned, done, shipped,
  /// declined, duplicate), or my post was held or removed.
  boardStatus,

  /// My claim: warning, expiry, released, PR closed.
  boardClaim,

  /// (M14) A publication changed the status of a story I can edit or sent
  /// a message; a submission could not be delivered (specs/18 §5.3).
  submission;

  static NotificationKind fromJson(String name) {
    switch (name) {
      case 'mention':
        return NotificationKind.mention;
      case 'reply':
        return NotificationKind.reply;
      case 'assigned':
        return NotificationKind.assigned;
      case 'shared':
        return NotificationKind.shared;
      case 'accessRequest':
        return NotificationKind.accessRequest;
      case 'suggestion':
        return NotificationKind.suggestion;
      case 'suggestionDecided':
        return NotificationKind.suggestionDecided;
      case 'ownershipTransfer':
        return NotificationKind.ownershipTransfer;
      case 'scriptFailure':
        return NotificationKind.scriptFailure;
      case 'storage':
        return NotificationKind.storage;
      case 'boardReply':
        return NotificationKind.boardReply;
      case 'boardStatus':
        return NotificationKind.boardStatus;
      case 'boardClaim':
        return NotificationKind.boardClaim;
      case 'submission':
        return NotificationKind.submission;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "NotificationKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
