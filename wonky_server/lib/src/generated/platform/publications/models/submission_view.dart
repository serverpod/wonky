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
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/publications/models/publication_fields.dart'
    as _i1a71r29;
import '../../../platform/publications/models/submission_delivery_state.dart'
    as _ifp7j30v;
import '../../../platform/publications/models/submission_revision_view.dart'
    as _idtrp1yl;
import '../../../platform/publications/models/submission_status.dart'
    as _igclxad1;
import '../../../platform/publications/models/submission_values.dart'
    as _igthguer;

/// A document's submission as editors and moderators see it (specs/18 §4).
abstract class SubmissionView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SubmissionView._({
    required this.id,
    required this.itemUuid,
    required this.status,
    this.delivery,
    required this.publicationId,
    required this.publicationName,
    required this.shownHost,
    required this.verified,
    required this.accepting,
    required this.fields,
    this.termsUrl,
    required this.consentNeeded,
    required this.values,
    this.publicUrl,
    this.feedbackThreadUuid,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSubmittedRevision,
    required this.revisions,
    required this.updatedAt,
  });

  factory SubmissionView({
    required String id,
    required _is.UuidValue itemUuid,
    required _igclxad1.SubmissionStatus status,
    _ifp7j30v.SubmissionDeliveryState? delivery,
    required String publicationId,
    required String publicationName,
    required String shownHost,
    required bool verified,
    required bool accepting,
    required _i1a71r29.PublicationFields fields,
    String? termsUrl,
    required bool consentNeeded,
    required _igthguer.SubmissionValues values,
    String? publicUrl,
    _is.UuidValue? feedbackThreadUuid,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? lastSubmittedRevision,
    required List<_idtrp1yl.SubmissionRevisionView> revisions,
    required DateTime updatedAt,
  }) = _SubmissionViewImpl;

  factory SubmissionView.fromJson(Map<String, dynamic> jsonSerialization) {
    return SubmissionView(
      id: jsonSerialization['id'] as String,
      itemUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['itemUuid'],
      ),
      status: _igclxad1.SubmissionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      delivery: jsonSerialization['delivery'] == null
          ? null
          : _ifp7j30v.SubmissionDeliveryState.fromJson(
              (jsonSerialization['delivery'] as String),
            ),
      publicationId: jsonSerialization['publicationId'] as String,
      publicationName: jsonSerialization['publicationName'] as String,
      shownHost: jsonSerialization['shownHost'] as String,
      verified: _is.BoolJsonExtension.fromJson(jsonSerialization['verified']),
      accepting: _is.BoolJsonExtension.fromJson(jsonSerialization['accepting']),
      fields: _il4umwa0.Protocol().deserialize<_i1a71r29.PublicationFields>(
        jsonSerialization['fields'],
      ),
      termsUrl: jsonSerialization['termsUrl'] as String?,
      consentNeeded: _is.BoolJsonExtension.fromJson(
        jsonSerialization['consentNeeded'],
      ),
      values: _il4umwa0.Protocol().deserialize<_igthguer.SubmissionValues>(
        jsonSerialization['values'],
      ),
      publicUrl: jsonSerialization['publicUrl'] as String?,
      feedbackThreadUuid: jsonSerialization['feedbackThreadUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['feedbackThreadUuid'],
            ),
      lastMessage: jsonSerialization['lastMessage'] as String?,
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      lastSubmittedRevision: jsonSerialization['lastSubmittedRevision'] as int?,
      revisions: _il4umwa0.Protocol()
          .deserialize<List<_idtrp1yl.SubmissionRevisionView>>(
            jsonSerialization['revisions'],
          ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// "sub_<uuid>".
  String id;

  _is.UuidValue itemUuid;

  _igclxad1.SubmissionStatus status;

  _ifp7j30v.SubmissionDeliveryState? delivery;

  String publicationId;

  String publicationName;

  String shownHost;

  bool verified;

  /// The publication still takes submissions (enabled, caller not blocked).
  bool accepting;

  _i1a71r29.PublicationFields fields;

  String? termsUrl;

  /// The caller still has to agree to the terms before submitting.
  bool consentNeeded;

  _igthguer.SubmissionValues values;

  String? publicUrl;

  _is.UuidValue? feedbackThreadUuid;

  /// The publication's last message (Markdown) and when it came.
  String? lastMessage;

  DateTime? lastMessageAt;

  /// The document revision of the last submit (null before the first).
  int? lastSubmittedRevision;

  List<_idtrp1yl.SubmissionRevisionView> revisions;

  DateTime updatedAt;

  /// Returns a shallow copy of this [SubmissionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SubmissionView copyWith({
    String? id,
    _is.UuidValue? itemUuid,
    _igclxad1.SubmissionStatus? status,
    _ifp7j30v.SubmissionDeliveryState? delivery,
    String? publicationId,
    String? publicationName,
    String? shownHost,
    bool? verified,
    bool? accepting,
    _i1a71r29.PublicationFields? fields,
    String? termsUrl,
    bool? consentNeeded,
    _igthguer.SubmissionValues? values,
    String? publicUrl,
    _is.UuidValue? feedbackThreadUuid = const _is.$UndefinedUuidValue(),
    String? lastMessage,
    DateTime? lastMessageAt = const _is.$UndefinedDateTime(),
    int? lastSubmittedRevision,
    List<_idtrp1yl.SubmissionRevisionView>? revisions,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SubmissionView',
      'id': id,
      'itemUuid': itemUuid.toJson(),
      'status': status.toJson(),
      if (delivery != null) 'delivery': delivery?.toJson(),
      'publicationId': publicationId,
      'publicationName': publicationName,
      'shownHost': shownHost,
      'verified': verified,
      'accepting': accepting,
      'fields': fields.toJson(),
      if (termsUrl != null) 'termsUrl': termsUrl,
      'consentNeeded': consentNeeded,
      'values': values.toJson(),
      if (publicUrl != null) 'publicUrl': publicUrl,
      if (feedbackThreadUuid != null)
        'feedbackThreadUuid': feedbackThreadUuid?.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastSubmittedRevision != null)
        'lastSubmittedRevision': lastSubmittedRevision,
      'revisions': revisions.toJson(valueToJson: (v) => v.toJson()),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SubmissionView',
      'id': id,
      'itemUuid': itemUuid.toJson(),
      'status': status.toJson(),
      if (delivery != null) 'delivery': delivery?.toJson(),
      'publicationId': publicationId,
      'publicationName': publicationName,
      'shownHost': shownHost,
      'verified': verified,
      'accepting': accepting,
      'fields': fields.toJsonForProtocol(),
      if (termsUrl != null) 'termsUrl': termsUrl,
      'consentNeeded': consentNeeded,
      'values': values.toJsonForProtocol(),
      if (publicUrl != null) 'publicUrl': publicUrl,
      if (feedbackThreadUuid != null)
        'feedbackThreadUuid': feedbackThreadUuid?.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      if (lastSubmittedRevision != null)
        'lastSubmittedRevision': lastSubmittedRevision,
      'revisions': revisions.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SubmissionViewImpl extends SubmissionView {
  _SubmissionViewImpl({
    required String id,
    required _is.UuidValue itemUuid,
    required _igclxad1.SubmissionStatus status,
    _ifp7j30v.SubmissionDeliveryState? delivery,
    required String publicationId,
    required String publicationName,
    required String shownHost,
    required bool verified,
    required bool accepting,
    required _i1a71r29.PublicationFields fields,
    String? termsUrl,
    required bool consentNeeded,
    required _igthguer.SubmissionValues values,
    String? publicUrl,
    _is.UuidValue? feedbackThreadUuid,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? lastSubmittedRevision,
    required List<_idtrp1yl.SubmissionRevisionView> revisions,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         itemUuid: itemUuid,
         status: status,
         delivery: delivery,
         publicationId: publicationId,
         publicationName: publicationName,
         shownHost: shownHost,
         verified: verified,
         accepting: accepting,
         fields: fields,
         termsUrl: termsUrl,
         consentNeeded: consentNeeded,
         values: values,
         publicUrl: publicUrl,
         feedbackThreadUuid: feedbackThreadUuid,
         lastMessage: lastMessage,
         lastMessageAt: lastMessageAt,
         lastSubmittedRevision: lastSubmittedRevision,
         revisions: revisions,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SubmissionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SubmissionView copyWith({
    String? id,
    _is.UuidValue? itemUuid,
    _igclxad1.SubmissionStatus? status,
    Object? delivery = _Undefined,
    String? publicationId,
    String? publicationName,
    String? shownHost,
    bool? verified,
    bool? accepting,
    _i1a71r29.PublicationFields? fields,
    Object? termsUrl = _Undefined,
    bool? consentNeeded,
    _igthguer.SubmissionValues? values,
    Object? publicUrl = _Undefined,
    _is.UuidValue? feedbackThreadUuid = const _is.$UndefinedUuidValue(),
    Object? lastMessage = _Undefined,
    DateTime? lastMessageAt = const _is.$UndefinedDateTime(),
    Object? lastSubmittedRevision = _Undefined,
    List<_idtrp1yl.SubmissionRevisionView>? revisions,
    DateTime? updatedAt,
  }) {
    return SubmissionView(
      id: id ?? this.id,
      itemUuid: itemUuid ?? this.itemUuid,
      status: status ?? this.status,
      delivery: delivery is _ifp7j30v.SubmissionDeliveryState?
          ? delivery
          : this.delivery,
      publicationId: publicationId ?? this.publicationId,
      publicationName: publicationName ?? this.publicationName,
      shownHost: shownHost ?? this.shownHost,
      verified: verified ?? this.verified,
      accepting: accepting ?? this.accepting,
      fields: fields ?? this.fields.copyWith(),
      termsUrl: termsUrl is String? ? termsUrl : this.termsUrl,
      consentNeeded: consentNeeded ?? this.consentNeeded,
      values: values ?? this.values.copyWith(),
      publicUrl: publicUrl is String? ? publicUrl : this.publicUrl,
      feedbackThreadUuid: feedbackThreadUuid is _is.UndefinedSentinel
          ? this.feedbackThreadUuid
          : feedbackThreadUuid,
      lastMessage: lastMessage is String? ? lastMessage : this.lastMessage,
      lastMessageAt: lastMessageAt is _is.UndefinedSentinel
          ? this.lastMessageAt
          : lastMessageAt,
      lastSubmittedRevision: lastSubmittedRevision is int?
          ? lastSubmittedRevision
          : this.lastSubmittedRevision,
      revisions:
          revisions ?? this.revisions.map((e0) => e0.copyWith()).toList(),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
