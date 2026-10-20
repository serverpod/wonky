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

/// Lifecycle of a submission (specs/18 §2.1).
enum SubmissionStatus implements _isc.SerializableModel {
  /// Started from the link, never submitted.
  draft,
  inReview,
  changesRequested,

  /// Final for this submission.
  declined,
  published,
  withdrawn;

  static SubmissionStatus fromJson(String name) {
    switch (name) {
      case 'draft':
        return SubmissionStatus.draft;
      case 'inReview':
        return SubmissionStatus.inReview;
      case 'changesRequested':
        return SubmissionStatus.changesRequested;
      case 'declined':
        return SubmissionStatus.declined;
      case 'published':
        return SubmissionStatus.published;
      case 'withdrawn':
        return SubmissionStatus.withdrawn;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SubmissionStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
