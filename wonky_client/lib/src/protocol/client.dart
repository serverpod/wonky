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
import 'dart:async' as _ida;
import 'dart:typed_data' as _idt;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:wonky_client/src/protocol/platform/activity/activity_dashboard.dart'
    as _ilqfn3s9;
import 'package:wonky_client/src/protocol/platform/activity/activity_event_view.dart'
    as _itempttd;
import 'package:wonky_client/src/protocol/platform/ai/models/ai_provider.dart'
    as _i9ndea8y;
import 'package:wonky_client/src/protocol/platform/ai/models/ai_quality.dart'
    as _il8jkded;
import 'package:wonky_client/src/protocol/platform/ai/models/assistant_context_hints.dart'
    as _ig0xo5zw;
import 'package:wonky_client/src/protocol/platform/ai/models/assistant_event.dart'
    as _ip81vhc1;
import 'package:wonky_client/src/protocol/platform/ai/models/assistant_status.dart'
    as _idfnr0x0;
import 'package:wonky_client/src/protocol/platform/ai/models/assistant_thread_detail.dart'
    as _irgg4r7f;
import 'package:wonky_client/src/protocol/platform/ai/models/assistant_thread_view.dart'
    as _i2rhb3qx;
import 'package:wonky_client/src/protocol/platform/ai/models/inline_ai_event.dart'
    as _ivbb4qsj;
import 'package:wonky_client/src/protocol/platform/ai/models/inline_ai_request.dart'
    as _i31mo4jy;
import 'package:wonky_client/src/protocol/platform/ai/models/proofread_event.dart'
    as _irtrv5vw;
import 'package:wonky_client/src/protocol/platform/analytics/models/analytics_overview.dart'
    as _iu8mc7mo;
import 'package:wonky_client/src/protocol/platform/analytics/models/usage_app.dart'
    as _izdyac9h;
import 'package:wonky_client/src/protocol/platform/board/models/board_area.dart'
    as _ix53eas0;
import 'package:wonky_client/src/protocol/platform/board/models/board_bundle_suggestion_view.dart'
    as _i94c7q23;
import 'package:wonky_client/src/protocol/platform/board/models/board_comment_view.dart'
    as _iesojpvb;
import 'package:wonky_client/src/protocol/platform/board/models/board_counts.dart'
    as _iwgo3mc7;
import 'package:wonky_client/src/protocol/platform/board/models/board_flag_reason.dart'
    as _iqqu23qj;
import 'package:wonky_client/src/protocol/platform/board/models/board_list_query.dart'
    as _izlc75ds;
import 'package:wonky_client/src/protocol/platform/board/models/board_me.dart'
    as _ighx6l3o;
import 'package:wonky_client/src/protocol/platform/board/models/board_moderation_action.dart'
    as _i4jpdiaw;
import 'package:wonky_client/src/protocol/platform/board/models/board_post_draft.dart'
    as _if6vkyrg;
import 'package:wonky_client/src/protocol/platform/board/models/board_post_event.dart'
    as _i0ceh4xz;
import 'package:wonky_client/src/protocol/platform/board/models/board_post_kind.dart'
    as _im2wvmm2;
import 'package:wonky_client/src/protocol/platform/board/models/board_post_page.dart'
    as _i9sq2gre;
import 'package:wonky_client/src/protocol/platform/board/models/board_post_view.dart'
    as _ichg96zd;
import 'package:wonky_client/src/protocol/platform/board/models/board_review_counts.dart'
    as _iwnb6fq4;
import 'package:wonky_client/src/protocol/platform/board/models/board_review_item.dart'
    as _i3y77bov;
import 'package:wonky_client/src/protocol/platform/board/models/board_review_section.dart'
    as _ijn6o8ui;
import 'package:wonky_client/src/protocol/platform/board/models/board_similar_post.dart'
    as _ikfdrh1p;
import 'package:wonky_client/src/protocol/platform/board/models/board_size.dart'
    as _iky4nxq3;
import 'package:wonky_client/src/protocol/platform/board/models/board_task_page.dart'
    as _i5hp59xb;
import 'package:wonky_client/src/protocol/platform/board/models/board_task_status.dart'
    as _i325i6jq;
import 'package:wonky_client/src/protocol/platform/board/models/board_task_view.dart'
    as _icqm1m07;
import 'package:wonky_client/src/protocol/platform/board/models/board_vote_result.dart'
    as _isrr2fx2;
import 'package:wonky_client/src/protocol/platform/comments/comment_anchor_kind.dart'
    as _i8agtv5a;
import 'package:wonky_client/src/protocol/platform/comments/comment_event.dart'
    as _ikh2q0ca;
import 'package:wonky_client/src/protocol/platform/comments/comment_filter.dart'
    as _ioje6taq;
import 'package:wonky_client/src/protocol/platform/comments/comment_thread_view.dart'
    as _i2c85fb0;
import 'package:wonky_client/src/protocol/platform/comments/comment_view.dart'
    as _ip2r2v4j;
import 'package:wonky_client/src/protocol/platform/common/access_role.dart'
    as _i7gd5xik;
import 'package:wonky_client/src/protocol/platform/drive/drive_change.dart'
    as _i2k3qk48;
import 'package:wonky_client/src/protocol/platform/drive/drive_import_options.dart'
    as _idv1evlb;
import 'package:wonky_client/src/protocol/platform/drive/drive_item_kind.dart'
    as _i37vo1p2;
import 'package:wonky_client/src/protocol/platform/drive/drive_item_view.dart'
    as _iatsgjjq;
import 'package:wonky_client/src/protocol/platform/drive/drive_list_filter.dart'
    as _i8ldc133;
import 'package:wonky_client/src/protocol/platform/drive/drive_list_page.dart'
    as _iawn6g1o;
import 'package:wonky_client/src/protocol/platform/drive/drive_search_filters.dart'
    as _icvnufpf;
import 'package:wonky_client/src/protocol/platform/drive/drive_sort.dart'
    as _ikhtp6t5;
import 'package:wonky_client/src/protocol/platform/drive/file_upload_progress.dart'
    as _izjlog7o;
import 'package:wonky_client/src/protocol/platform/drive/file_upload_request.dart'
    as _igc8ti2y;
import 'package:wonky_client/src/protocol/platform/drive/file_upload_start.dart'
    as _ismkx81d;
import 'package:wonky_client/src/protocol/platform/drive/import_report_view.dart'
    as _irwfmef9;
import 'package:wonky_client/src/protocol/platform/drive/storage_list_filter.dart'
    as _i3az7xi1;
import 'package:wonky_client/src/protocol/platform/drive/storage_usage.dart'
    as _i5ixb3en;
import 'package:wonky_client/src/protocol/platform/drive/template_category.dart'
    as _i6of8k2c;
import 'package:wonky_client/src/protocol/platform/drive/template_view.dart'
    as _i1pzk6fp;
import 'package:wonky_client/src/protocol/platform/feedback/feedback_submission.dart'
    as _i70rrzeg;
import 'package:wonky_client/src/protocol/platform/files/file_upload_ticket.dart'
    as _ilpm2pjc;
import 'package:wonky_client/src/protocol/platform/files/file_url_view.dart'
    as _i4i1hokq;
import 'package:wonky_client/src/protocol/platform/files/image_profile.dart'
    as _i8mxqucd;
import 'package:wonky_client/src/protocol/platform/files/stored_file_kind.dart'
    as _iaaducpz;
import 'package:wonky_client/src/protocol/platform/mcp/ui_bridge/ui_bridge_message.dart'
    as _i1yu9qix;
import 'package:wonky_client/src/protocol/platform/meta/protocol_info.dart'
    as _ix72qie6;
import 'package:wonky_client/src/protocol/platform/notifications/notification_event.dart'
    as _ibtz26fx;
import 'package:wonky_client/src/protocol/platform/notifications/notification_page.dart'
    as _ispzjfjq;
import 'package:wonky_client/src/protocol/platform/presence/presence_event.dart'
    as _i1lme7np;
import 'package:wonky_client/src/protocol/platform/presence/presence_update.dart'
    as _izu9ijhe;
import 'package:wonky_client/src/protocol/platform/publications/models/publication_card.dart'
    as _igbz1wj9;
import 'package:wonky_client/src/protocol/platform/publications/models/publication_check_result.dart'
    as _i9sbxmp8;
import 'package:wonky_client/src/protocol/platform/publications/models/publication_delivery_view.dart'
    as _ipl2ldhs;
import 'package:wonky_client/src/protocol/platform/publications/models/publication_input.dart'
    as _ii8xbzwt;
import 'package:wonky_client/src/protocol/platform/publications/models/publication_secret.dart'
    as _ihfocp8h;
import 'package:wonky_client/src/protocol/platform/publications/models/publication_settings.dart'
    as _i9bruko9;
import 'package:wonky_client/src/protocol/platform/publications/models/submission_started.dart'
    as _i767e3eb;
import 'package:wonky_client/src/protocol/platform/publications/models/submission_values.dart'
    as _i8t9b0m8;
import 'package:wonky_client/src/protocol/platform/publications/models/submission_view.dart'
    as _iy9ei8t0;
import 'package:wonky_client/src/protocol/platform/revlog/messages/rev_client_message.dart'
    as _iedvhh7l;
import 'package:wonky_client/src/protocol/platform/revlog/messages/rev_server_message.dart'
    as _ibic7sfk;
import 'package:wonky_client/src/protocol/platform/revlog/models/rev_file_info.dart'
    as _ipiq4i7g;
import 'package:wonky_client/src/protocol/platform/revlog/models/rev_op_view.dart'
    as _iq15rk0l;
import 'package:wonky_client/src/protocol/platform/revlog/models/rev_page.dart'
    as _ivzrugmo;
import 'package:wonky_client/src/protocol/platform/revlog/models/rev_page_request.dart'
    as _isw8g0pp;
import 'package:wonky_client/src/protocol/platform/sharing/invite_resolution.dart'
    as _idoq825d;
import 'package:wonky_client/src/protocol/platform/sharing/item_sharing_settings.dart'
    as _i0x662rz;
import 'package:wonky_client/src/protocol/platform/sharing/sharing_info.dart'
    as _idqkfu7d;
import 'package:wonky_client/src/protocol/platform/users/access_token_view.dart'
    as _ip6swqsj;
import 'package:wonky_client/src/protocol/platform/users/account_deletion_preview.dart'
    as _ik5w0ki0;
import 'package:wonky_client/src/protocol/platform/users/created_access_token.dart'
    as _irplbwpp;
import 'package:wonky_client/src/protocol/platform/users/user_preferences.dart'
    as _i59f1kw7;
import 'package:wonky_client/src/protocol/platform/users/user_preferences_patch.dart'
    as _i6jtsw1b;
import 'package:wonky_client/src/protocol/platform/users/user_profile_view.dart'
    as _ioc8dkw9;
import 'package:wonky_client/src/protocol/platform/users/user_summary.dart'
    as _iq7femvs;
import 'package:wonky_client/src/protocol/platform/versions/item_version_view.dart'
    as _itqtmykd;
import 'package:wonky_client/src/protocol/platform/versions/version_restore_result.dart'
    as _iyei7m5z;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_ai_apply_result.dart'
    as _isefwvgb;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_ai_cell_request.dart'
    as _ibrzlkni;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_ai_cell_result.dart'
    as _ivc6ykj9;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_ai_preview.dart'
    as _ijqca8sl;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_fill_proposal.dart'
    as _i9koccid;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_fill_row.dart'
    as _i2syfqhi;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_formula_suggestion.dart'
    as _irs9q9tq;
import 'package:wonky_client/src/protocol/sheets/imports/models/sheets_import_progress.dart'
    as _in60swvs;
import 'package:wonky_client/src/protocol/sheets/models/cell_history_page.dart'
    as _i8ap5j9q;
import 'package:wonky_client/src/protocol/sheets/models/revert_result.dart'
    as _i107v8u3;
import 'package:wonky_client/src/protocol/sheets/models/sheets_activity_summary.dart'
    as _im0q5n3x;
import 'package:wonky_client/src/protocol/sheets/scripts/models/script_authorization_view.dart'
    as _i7q8cl7e;
import 'package:wonky_client/src/protocol/sheets/scripts/models/script_compile_response.dart'
    as _igk7mjr7;
import 'package:wonky_client/src/protocol/sheets/scripts/models/script_execution.dart'
    as _ijdpewvc;
import 'package:wonky_client/src/protocol/sheets/scripts/models/script_execution_status.dart'
    as _isizzyyw;
import 'package:wonky_client/src/protocol/sheets/scripts/models/script_fetch_response.dart'
    as _iyfk9f1k;
import 'package:wonky_client/src/protocol/sheets/scripts/models/script_run_response.dart'
    as _iaw9fhnx;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_alt_text.dart'
    as _iqd8jbjp;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_apply_result.dart'
    as _ilgy0ds2;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_build_result.dart'
    as _i6mf4awd;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_design_rank.dart'
    as _ifavqmyp;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_note.dart'
    as _iascr37x;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_outline_request.dart'
    as _itf4l8jm;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_preview.dart'
    as _iqp3429j;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_rewrite_request.dart'
    as _ixhdkbka;
import 'package:wonky_client/src/protocol/slides/charts/models/chart_link_probe.dart'
    as _ipgr9tcd;
import 'package:wonky_client/src/protocol/slides/charts/models/chart_link_status.dart'
    as _idvbn12y;
import 'package:wonky_client/src/protocol/slides/charts/models/chart_snapshot_view.dart'
    as _iwoaz8tz;
import 'package:wonky_client/src/protocol/slides/charts/models/chart_source_list.dart'
    as _izwvek44;
import 'package:wonky_client/src/protocol/slides/present/models/presentation_event.dart'
    as _i693xhmf;
import 'package:wonky_client/src/protocol/slides/present/models/presentation_join.dart'
    as _ia63nl87;
import 'package:wonky_client/src/protocol/slides/present/models/presentation_pairing_target.dart'
    as _i6lgd3j7;
import 'package:wonky_client/src/protocol/slides/present/models/presentation_session_info.dart'
    as _iwz86pi3;
import 'package:wonky_client/src/protocol/slides/present/models/presentation_update.dart'
    as _igyvhitp;
import 'package:wonky_client/src/protocol/write/messages/doc_client_message.dart'
    as _isw33y8i;
import 'package:wonky_client/src/protocol/write/messages/doc_server_message.dart'
    as _ir9iog55;
import 'package:wonky_client/src/protocol/write/models/convert_for_insert_result.dart'
    as _ia522en0;
import 'package:wonky_client/src/protocol/write/models/document_info.dart'
    as _in30vxre;
import 'package:wonky_client/src/protocol/write/models/document_meta_patch.dart'
    as _ih34yxbq;
import 'package:wonky_client/src/protocol/write/models/document_op_view.dart'
    as _i8x9070n;
import 'package:wonky_client/src/protocol/write/models/document_snapshot_view.dart'
    as _i8beogda;
import 'package:wonky_client/src/protocol/write/models/export_progress_event.dart'
    as _i1vrysbd;
import 'package:wonky_client/src/protocol/write/models/export_result_view.dart'
    as _ia6gray1;
import 'package:wonky_client/src/protocol/write/models/write_diff_view.dart'
    as _iohaffow;
import 'package:wonky_client/src/protocol/write/models/write_theme_revision_view.dart'
    as _igytjuh5;
import 'package:wonky_client/src/protocol/write/models/write_theme_view.dart'
    as _i2zuh8f2;
import 'package:wonky_client/src/protocol/write/models/write_version_document.dart'
    as _igd4fcl2;
import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// Tools › Activity dashboard (specs/07 §6): viewers, view and comment
/// trends, and the "Show my view history" privacy setting.
/// {@category Endpoint}
class EndpointActivity extends _isc.EndpointRef {
  EndpointActivity(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'activity';

  /// The dashboard of [itemUuid] for the last [days] days (1–365).
  _ida.Future<_ilqfn3s9.ActivityDashboard> dashboard(
    _isc.UuidValue itemUuid,
    int days,
  ) => caller.callServerEndpoint<_ilqfn3s9.ActivityDashboard>(
    'activity',
    'dashboard',
    {
      'itemUuid': itemUuid,
      'days': days,
    },
  );

  /// The caller's "Show my view history" setting.
  _ida.Future<bool> showViewHistory() => caller.callServerEndpoint<bool>(
    'activity',
    'showViewHistory',
    {},
  );

  /// Turns the caller's "Show my view history" on or off; returns it.
  _ida.Future<bool> setShowViewHistory(bool show) =>
      caller.callServerEndpoint<bool>(
        'activity',
        'setShowViewHistory',
        {'show': show},
      );
}

/// The AI assistant (suite 10 §2, Write 09 §5). Model calls happen here on
/// the server; API keys (the server's and users' own) never reach clients.
/// {@category Endpoint}
class EndpointAssistant extends _isc.EndpointRef {
  EndpointAssistant(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'assistant';

  /// Whether the assistant can be used, the quality setting and today's
  /// usage.
  _ida.Future<_idfnr0x0.AssistantStatus> getStatus() =>
      caller.callServerEndpoint<_idfnr0x0.AssistantStatus>(
        'assistant',
        'getStatus',
        {},
      );

  /// Settings › AI › Quality.
  _ida.Future<_idfnr0x0.AssistantStatus> setQuality(
    _il8jkded.AiQuality quality,
  ) => caller.callServerEndpoint<_idfnr0x0.AssistantStatus>(
    'assistant',
    'setQuality',
    {'quality': quality},
  );

  /// Settings › AI providers: stores the user's own API key for
  /// [provider] (only while the server has no key). The key is never
  /// returned; the status shows the provider and its last four characters.
  _ida.Future<_idfnr0x0.AssistantStatus> setProviderKey(
    _i9ndea8y.AiProvider provider,
    String apiKey,
  ) => caller.callServerEndpoint<_idfnr0x0.AssistantStatus>(
    'assistant',
    'setProviderKey',
    {
      'provider': provider,
      'apiKey': apiKey,
    },
  );

  /// Settings › AI providers › Remove: deletes the user's own key.
  _ida.Future<_idfnr0x0.AssistantStatus> removeProviderKey() =>
      caller.callServerEndpoint<_idfnr0x0.AssistantStatus>(
        'assistant',
        'removeProviderKey',
        {},
      );

  /// Sends a message ([threadId] null = new thread on [itemUuid]) and
  /// streams the run: `started` (thread + run id), text deltas, progress
  /// notes, tool activity, confirmations, usage, then `done`.
  _ida.Stream<_ip81vhc1.AssistantEvent> chat(
    int? threadId,
    _isc.UuidValue itemUuid,
    String message,
    _ig0xo5zw.AssistantContextHints hints,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ip81vhc1.AssistantEvent>,
        _ip81vhc1.AssistantEvent
      >(
        'assistant',
        'chat',
        {
          'threadId': threadId,
          'itemUuid': itemUuid,
          'message': message,
          'hints': hints,
        },
        {},
      );

  /// Stops a run ([runId]) or every run of [threadId].
  _ida.Future<bool> stop(
    int? threadId,
    String? runId,
  ) => caller.callServerEndpoint<bool>(
    'assistant',
    'stop',
    {
      'threadId': threadId,
      'runId': runId,
    },
  );

  /// Answers a destructive-change confirmation (Allow / Deny).
  _ida.Future<bool> confirm(
    String runId,
    String confirmationId,
    bool allow,
  ) => caller.callServerEndpoint<bool>(
    'assistant',
    'confirm',
    {
      'runId': runId,
      'confirmationId': confirmationId,
      'allow': allow,
    },
  );

  /// The requesting window's answer to a `uiToolCall` event (Sheets 12
  /// §6.2): [response].requestId is the event's `toolUseId`.
  _ida.Future<bool> uiToolResult(
    String runId,
    _i1yu9qix.UiBridgeResponse response,
  ) => caller.callServerEndpoint<bool>(
    'assistant',
    'uiToolResult',
    {
      'runId': runId,
      'response': response,
    },
  );

  /// Threads of the user on [itemUuid], newest first.
  _ida.Future<List<_i2rhb3qx.AssistantThreadView>> listThreads(
    _isc.UuidValue itemUuid,
  ) => caller.callServerEndpoint<List<_i2rhb3qx.AssistantThreadView>>(
    'assistant',
    'listThreads',
    {'itemUuid': itemUuid},
  );

  _ida.Future<_irgg4r7f.AssistantThreadDetail> getThread(int threadId) =>
      caller.callServerEndpoint<_irgg4r7f.AssistantThreadDetail>(
        'assistant',
        'getThread',
        {'threadId': threadId},
      );

  _ida.Future<void> deleteThread(int threadId) =>
      caller.callServerEndpoint<void>(
        'assistant',
        'deleteThread',
        {'threadId': threadId},
      );

  /// Deletes every conversation of the user; returns how many.
  _ida.Future<int> clearHistory() => caller.callServerEndpoint<int>(
    'assistant',
    'clearHistory',
    {},
  );

  /// Reverts an assistant change by its `change_id` (panel Undo fallback).
  _ida.Future<void> revertChange(String changeId) =>
      caller.callServerEndpoint<void>(
        'assistant',
        'revertChange',
        {'changeId': changeId},
      );

  /// Inline AI: rewrite a selection, continue writing, explain, summarize,
  /// generate an outline (Write 09 §5.3–5.5).
  _ida.Stream<_ivbb4qsj.InlineAiEvent> inline(
    _i31mo4jy.InlineAiRequest request,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ivbb4qsj.InlineAiEvent>,
        _ivbb4qsj.InlineAiEvent
      >(
        'assistant',
        'inline',
        {'request': request},
        {},
      );

  /// Proofreads the document (or a range): streams validated issues per
  /// section.
  _ida.Stream<_irtrv5vw.ProofreadEvent> proofread(
    _isc.UuidValue itemUuid,
    int? start,
    int? length,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_irtrv5vw.ProofreadEvent>,
        _irtrv5vw.ProofreadEvent
      >(
        'assistant',
        'proofread',
        {
          'itemUuid': itemUuid,
          'start': start,
          'length': length,
        },
        {},
      );
}

/// Usage analytics (specs/19): the apps' activity ping, and the admin
/// dashboard of Wonky Drive (overview, admins only).
/// {@category Endpoint}
class EndpointAnalytics extends _isc.EndpointRef {
  EndpointAnalytics(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'analytics';

  /// The caller is using [app] (sent at app start and on resume).
  _ida.Future<void> ping(_izdyac9h.UsageApp app) =>
      caller.callServerEndpoint<void>(
        'analytics',
        'ping',
        {'app': app},
      );

  /// The dashboard for the last [days] days (7, 30, 90 or 365); admins are
  /// left out of every count unless [includeAdmins].
  _ida.Future<_iu8mc7mo.AnalyticsOverview> overview(
    int days,
    bool includeAdmins,
  ) => caller.callServerEndpoint<_iu8mc7mo.AnalyticsOverview>(
    'analytics',
    'overview',
    {
      'days': days,
      'includeAdmins': includeAdmins,
    },
  );
}

/// Bugs & improvements (specs/16 §12). Read methods work signed out; write
/// methods need a signed-in user who is not blocked; admin methods need an
/// admin (specs/16 §9.1). Posts and tasks are addressed by their public
/// number (the row id), for example #123 and T-12.
/// {@category Endpoint}
class EndpointBoard extends _isc.EndpointRef {
  EndpointBoard(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'board';

  /// The caller's board status (signed out works).
  _ida.Future<_ighx6l3o.BoardMe> me() =>
      caller.callServerEndpoint<_ighx6l3o.BoardMe>(
        'board',
        'me',
        {},
      );

  _ida.Future<_i9sq2gre.BoardPostPage> list(_izlc75ds.BoardListQuery query) =>
      caller.callServerEndpoint<_i9sq2gre.BoardPostPage>(
        'board',
        'list',
        {'query': query},
      );

  /// The tab counts: open ideas and bugs, *Up for grabs* and *Claimed*.
  _ida.Future<_iwgo3mc7.BoardCounts> counts() =>
      caller.callServerEndpoint<_iwgo3mc7.BoardCounts>(
        'board',
        'counts',
        {},
      );

  _ida.Future<_ichg96zd.BoardPostView> getPost(int number) =>
      caller.callServerEndpoint<_ichg96zd.BoardPostView>(
        'board',
        'getPost',
        {'number': number},
      );

  /// Comments of a post, oldest first.
  _ida.Future<List<_iesojpvb.BoardCommentView>> listComments(int number) =>
      caller.callServerEndpoint<List<_iesojpvb.BoardCommentView>>(
        'board',
        'listComments',
        {'number': number},
      );

  /// The activity rows of a task (claimed, released, PR linked …), oldest
  /// first; for admins only (empty for everyone else). Tasks have no
  /// discussion.
  _ida.Future<List<_iesojpvb.BoardCommentView>> listTaskComments(int number) =>
      caller.callServerEndpoint<List<_iesojpvb.BoardCommentView>>(
        'board',
        'listTaskComments',
        {'number': number},
      );

  /// Up to 5 visible posts similar to a draft (specs/16 §6.4).
  _ida.Future<List<_ikfdrh1p.BoardSimilarPost>> similar(
    String title,
    String body,
    _im2wvmm2.BoardPostKind? kind,
  ) => caller.callServerEndpoint<List<_ikfdrh1p.BoardSimilarPost>>(
    'board',
    'similar',
    {
      'title': title,
      'body': body,
      'kind': kind,
    },
  );

  /// A short-lived URL of a post's screenshot, or null.
  _ida.Future<String?> getScreenshotUrl(int number) =>
      caller.callServerEndpoint<String?>(
        'board',
        'getScreenshotUrl',
        {'number': number},
      );

  /// Tasks with [statuses] (empty: published, claimed and inReview). An
  /// expired claim counts as published.
  _ida.Future<_i5hp59xb.BoardTaskPage> listTasks(
    List<_i325i6jq.BoardTaskStatus> statuses,
    String? cursor,
    int limit,
  ) => caller.callServerEndpoint<_i5hp59xb.BoardTaskPage>(
    'board',
    'listTasks',
    {
      'statuses': statuses,
      'cursor': cursor,
      'limit': limit,
    },
  );

  _ida.Future<_icqm1m07.BoardTaskView> getTask(int number) =>
      caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
        'board',
        'getTask',
        {'number': number},
      );

  /// Live changes of a post: votes, comments, moderation, status.
  _ida.Stream<_i0ceh4xz.BoardPostEvent> watchPost(int number) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i0ceh4xz.BoardPostEvent>,
        _i0ceh4xz.BoardPostEvent
      >(
        'board',
        'watchPost',
        {'number': number},
        {},
      );

  /// Live task changes (claims, status) for the Up for grabs and Claimed
  /// tabs.
  _ida.Stream<_i0ceh4xz.BoardPostEvent> watchTasks() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i0ceh4xz.BoardPostEvent>,
        _i0ceh4xz.BoardPostEvent
      >(
        'board',
        'watchTasks',
        {},
        {},
      );

  /// Where to upload a screenshot (PNG or JPEG, ≤ 5 MB; stored as WebP);
  /// finish with `file.completeUpload`, then pass the uuid to [createPost].
  _ida.Future<_ilpm2pjc.FileUploadTicket> createScreenshotUpload(
    _isc.UuidValue fileUuid,
    String mimeType,
    int size,
  ) => caller.callServerEndpoint<_ilpm2pjc.FileUploadTicket>(
    'board',
    'createScreenshotUpload',
    {
      'fileUuid': fileUuid,
      'mimeType': mimeType,
      'size': size,
    },
  );

  _ida.Future<_ichg96zd.BoardPostView> createPost(
    _if6vkyrg.BoardPostDraft draft,
  ) => caller.callServerEndpoint<_ichg96zd.BoardPostView>(
    'board',
    'createPost',
    {'draft': draft},
  );

  /// The author edits their post (open, not in a task).
  _ida.Future<_ichg96zd.BoardPostView> editPost(
    int number,
    String title,
    String body,
  ) => caller.callServerEndpoint<_ichg96zd.BoardPostView>(
    'board',
    'editPost',
    {
      'number': number,
      'title': title,
      'body': body,
    },
  );

  /// Soft delete by the author (or an admin).
  _ida.Future<void> deletePost(int number) => caller.callServerEndpoint<void>(
    'board',
    'deletePost',
    {'number': number},
  );

  /// Undo of [deletePost].
  _ida.Future<_ichg96zd.BoardPostView> restorePost(int number) =>
      caller.callServerEndpoint<_ichg96zd.BoardPostView>(
        'board',
        'restorePost',
        {'number': number},
      );

  /// Deletes the screenshot bytes (author or admin); not undoable.
  _ida.Future<_ichg96zd.BoardPostView> removeScreenshot(int number) =>
      caller.callServerEndpoint<_ichg96zd.BoardPostView>(
        'board',
        'removeScreenshot',
        {'number': number},
      );

  /// Votes -1, 0 (remove) or +1; -1 only on ideas.
  _ida.Future<_isrr2fx2.BoardVoteResult> vote(
    int number,
    int value,
  ) => caller.callServerEndpoint<_isrr2fx2.BoardVoteResult>(
    'board',
    'vote',
    {
      'number': number,
      'value': value,
    },
  );

  /// Adds a comment to post [postNumber]; idempotent on [uuid]. Tasks have
  /// no discussion: a [taskNumber] is refused (`invalidArgument`); the
  /// parameter stays for older clients.
  _ida.Future<_iesojpvb.BoardCommentView> addComment(
    _isc.UuidValue uuid,
    int? postNumber,
    int? taskNumber,
    String body,
  ) => caller.callServerEndpoint<_iesojpvb.BoardCommentView>(
    'board',
    'addComment',
    {
      'uuid': uuid,
      'postNumber': postNumber,
      'taskNumber': taskNumber,
      'body': body,
    },
  );

  _ida.Future<_iesojpvb.BoardCommentView> editComment(
    _isc.UuidValue uuid,
    String body,
  ) => caller.callServerEndpoint<_iesojpvb.BoardCommentView>(
    'board',
    'editComment',
    {
      'uuid': uuid,
      'body': body,
    },
  );

  _ida.Future<void> deleteComment(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<void>(
        'board',
        'deleteComment',
        {'uuid': uuid},
      );

  /// Undo of [deleteComment].
  _ida.Future<_iesojpvb.BoardCommentView> restoreComment(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<_iesojpvb.BoardCommentView>(
        'board',
        'restoreComment',
        {'uuid': uuid},
      );

  /// Flags a post ([number]) or a comment ([commentUuid]).
  _ida.Future<void> flag(
    int? number,
    _isc.UuidValue? commentUuid,
    _iqqu23qj.BoardFlagReason reason,
    String? note,
  ) => caller.callServerEndpoint<void>(
    'board',
    'flag',
    {
      'number': number,
      'commentUuid': commentUuid,
      'reason': reason,
      'note': note,
    },
  );

  /// Undo of [flag].
  _ida.Future<void> unflag(
    int? number,
    _isc.UuidValue? commentUuid,
  ) => caller.callServerEndpoint<void>(
    'board',
    'unflag',
    {
      'number': number,
      'commentUuid': commentUuid,
    },
  );

  /// Claims a published task for `board.claimHours` (specs/16 §8.1).
  _ida.Future<_icqm1m07.BoardTaskView> claimTask(int number) =>
      caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
        'board',
        'claimTask',
        {'number': number},
      );

  /// Releases a claim (the claimant or an admin).
  _ida.Future<_icqm1m07.BoardTaskView> releaseTask(int number) =>
      caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
        'board',
        'releaseTask',
        {'number': number},
      );

  _ida.Future<_iwnb6fq4.BoardReviewCounts> reviewCounts() =>
      caller.callServerEndpoint<_iwnb6fq4.BoardReviewCounts>(
        'board',
        'reviewCounts',
        {},
      );

  _ida.Future<List<_i3y77bov.BoardReviewItem>> reviewQueue(
    _ijn6o8ui.BoardReviewSection section,
  ) => caller.callServerEndpoint<List<_i3y77bov.BoardReviewItem>>(
    'board',
    'reviewQueue',
    {'section': section},
  );

  _ida.Future<_ichg96zd.BoardPostView> moderatePost(
    int number,
    _i4jpdiaw.BoardModerationAction action,
    String? reason,
  ) => caller.callServerEndpoint<_ichg96zd.BoardPostView>(
    'board',
    'moderatePost',
    {
      'number': number,
      'action': action,
      'reason': reason,
    },
  );

  _ida.Future<_iesojpvb.BoardCommentView> moderateComment(
    _isc.UuidValue uuid,
    _i4jpdiaw.BoardModerationAction action,
    String? reason,
  ) => caller.callServerEndpoint<_iesojpvb.BoardCommentView>(
    'board',
    'moderateComment',
    {
      'uuid': uuid,
      'action': action,
      'reason': reason,
    },
  );

  /// Edit and approve (e.g. removing personal data).
  _ida.Future<_ichg96zd.BoardPostView> adminEditPost(
    int number,
    String title,
    String body,
  ) => caller.callServerEndpoint<_ichg96zd.BoardPostView>(
    'board',
    'adminEditPost',
    {
      'number': number,
      'title': title,
      'body': body,
    },
  );

  /// Sets kind, area and size (confirms the AI labels; null clears).
  _ida.Future<_ichg96zd.BoardPostView> setLabels(
    int number,
    _im2wvmm2.BoardPostKind kind,
    _ix53eas0.BoardArea? area,
    _iky4nxq3.BoardSize? size,
  ) => caller.callServerEndpoint<_ichg96zd.BoardPostView>(
    'board',
    'setLabels',
    {
      'number': number,
      'kind': kind,
      'area': area,
      'size': size,
    },
  );

  _ida.Future<_ichg96zd.BoardPostView> applySuggestedTitle(int number) =>
      caller.callServerEndpoint<_ichg96zd.BoardPostView>(
        'board',
        'applySuggestedTitle',
        {'number': number},
      );

  _ida.Future<_ichg96zd.BoardPostView> dismissDuplicateHint(int number) =>
      caller.callServerEndpoint<_ichg96zd.BoardPostView>(
        'board',
        'dismissDuplicateHint',
        {'number': number},
      );

  _ida.Future<_ichg96zd.BoardPostView> merge(
    int source,
    int target,
  ) => caller.callServerEndpoint<_ichg96zd.BoardPostView>(
    'board',
    'merge',
    {
      'source': source,
      'target': target,
    },
  );

  /// Undo of [merge].
  _ida.Future<_ichg96zd.BoardPostView> unmerge(int source) =>
      caller.callServerEndpoint<_ichg96zd.BoardPostView>(
        'board',
        'unmerge',
        {'source': source},
      );

  _ida.Future<_ichg96zd.BoardPostView> decline(
    int number,
    String reason,
  ) => caller.callServerEndpoint<_ichg96zd.BoardPostView>(
    'board',
    'decline',
    {
      'number': number,
      'reason': reason,
    },
  );

  /// Undo of [decline].
  _ida.Future<_ichg96zd.BoardPostView> reopen(int number) =>
      caller.callServerEndpoint<_ichg96zd.BoardPostView>(
        'board',
        'reopen',
        {'number': number},
      );

  _ida.Future<void> blockUser(
    int userId,
    String reason,
    DateTime? until,
  ) => caller.callServerEndpoint<void>(
    'board',
    'blockUser',
    {
      'userId': userId,
      'reason': reason,
      'until': until,
    },
  );

  _ida.Future<void> unblockUser(int userId) => caller.callServerEndpoint<void>(
    'board',
    'unblockUser',
    {'userId': userId},
  );

  /// Creates a draft task from posts and generates its prompt.
  /// [excludedComments] are comments of the posts the admin left out of the
  /// prompt's context (specs/16 §9.3).
  _ida.Future<_icqm1m07.BoardTaskView> createTask(
    List<int> postNumbers,
    String title,
    _ix53eas0.BoardArea area,
    _iky4nxq3.BoardSize size, {
    List<_isc.UuidValue>? excludedComments,
  }) => caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
    'board',
    'createTask',
    {
      'postNumbers': postNumbers,
      'title': title,
      'area': area,
      'size': size,
      'excludedComments': excludedComments,
    },
  );

  _ida.Future<_icqm1m07.BoardTaskView> updateTask(
    int number,
    String title,
    _ix53eas0.BoardArea area,
    _iky4nxq3.BoardSize size,
  ) => caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
    'board',
    'updateTask',
    {
      'number': number,
      'title': title,
      'area': area,
      'size': size,
    },
  );

  _ida.Future<_icqm1m07.BoardTaskView> setTaskPosts(
    int number,
    List<int> postNumbers,
  ) => caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
    'board',
    'setTaskPosts',
    {
      'number': number,
      'postNumbers': postNumbers,
    },
  );

  /// Merges the tasks [numbers] into the oldest one, which takes all their
  /// issues and [title], [area] and [size]; the AI rewrites its prompt
  /// (specs/16 §9.3). Only tasks nobody has claimed.
  _ida.Future<_icqm1m07.BoardTaskView> mergeTasks(
    List<int> numbers,
    String title,
    _ix53eas0.BoardArea area,
    _iky4nxq3.BoardSize size,
  ) => caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
    'board',
    'mergeTasks',
    {
      'numbers': numbers,
      'title': title,
      'area': area,
      'size': size,
    },
  );

  /// Reverts the last merge into task [number] (the undo of [mergeTasks]).
  _ida.Future<_icqm1m07.BoardTaskView> unmergeTasks(int number) =>
      caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
        'board',
        'unmergeTasks',
        {'number': number},
      );

  _ida.Future<_icqm1m07.BoardTaskView> regeneratePrompt(int number) =>
      caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
        'board',
        'regeneratePrompt',
        {'number': number},
      );

  _ida.Future<_icqm1m07.BoardTaskView> setPrompt(
    int number,
    String body,
  ) => caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
    'board',
    'setPrompt',
    {
      'number': number,
      'body': body,
    },
  );

  _ida.Future<_icqm1m07.BoardTaskView> publishTask(int number) =>
      caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
        'board',
        'publishTask',
        {'number': number},
      );

  /// Sets a task's status directly (undo of publish, done, shipped, cancel;
  /// admin fallbacks).
  _ida.Future<_icqm1m07.BoardTaskView> setTaskStatus(
    int number,
    _i325i6jq.BoardTaskStatus status,
  ) => caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
    'board',
    'setTaskStatus',
    {
      'number': number,
      'status': status,
    },
  );

  /// Admin fallback when the GitHub App is not available (specs/16 §8.3).
  _ida.Future<_icqm1m07.BoardTaskView> linkPullRequest(
    int number,
    String? url,
  ) => caller.callServerEndpoint<_icqm1m07.BoardTaskView>(
    'board',
    'linkPullRequest',
    {
      'number': number,
      'url': url,
    },
  );

  _ida.Future<List<_i94c7q23.BoardBundleSuggestionView>> suggestBundles() =>
      caller.callServerEndpoint<List<_i94c7q23.BoardBundleSuggestionView>>(
        'board',
        'suggestBundles',
        {},
      );

  _ida.Future<List<_i94c7q23.BoardBundleSuggestionView>> listSuggestions() =>
      caller.callServerEndpoint<List<_i94c7q23.BoardBundleSuggestionView>>(
        'board',
        'listSuggestions',
        {},
      );

  _ida.Future<void> dismissSuggestion(int id) =>
      caller.callServerEndpoint<void>(
        'board',
        'dismissSuggestion',
        {'id': id},
      );
}

/// Comment threads (specs/07 §2.2).
/// {@category Endpoint}
class EndpointComment extends _isc.EndpointRef {
  EndpointComment(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'comment';

  _ida.Future<List<_i2c85fb0.CommentThreadView>> listThreads(
    _isc.UuidValue itemUuid,
    _ioje6taq.CommentFilter filter,
  ) => caller.callServerEndpoint<List<_i2c85fb0.CommentThreadView>>(
    'comment',
    'listThreads',
    {
      'itemUuid': itemUuid,
      'filter': filter,
    },
  );

  _ida.Future<_i2c85fb0.CommentThreadView> getThread(
    _isc.UuidValue threadUuid,
  ) => caller.callServerEndpoint<_i2c85fb0.CommentThreadView>(
    'comment',
    'getThread',
    {'threadUuid': threadUuid},
  );

  /// Creates a thread; idempotent on the client-generated [threadUuid].
  _ida.Future<_i2c85fb0.CommentThreadView> createThread(
    _isc.UuidValue threadUuid,
    _isc.UuidValue itemUuid,
    _i8agtv5a.CommentAnchorKind anchorKind,
    String anchorJson,
    String? quotedText,
    String body,
    List<int> mentions,
    int? assigneeId,
  ) => caller.callServerEndpoint<_i2c85fb0.CommentThreadView>(
    'comment',
    'createThread',
    {
      'threadUuid': threadUuid,
      'itemUuid': itemUuid,
      'anchorKind': anchorKind,
      'anchorJson': anchorJson,
      'quotedText': quotedText,
      'body': body,
      'mentions': mentions,
      'assigneeId': assigneeId,
    },
  );

  /// Replies; idempotent on the optional client-generated [commentUuid].
  _ida.Future<_i2c85fb0.CommentThreadView> reply(
    _isc.UuidValue threadUuid,
    String body,
    List<int> mentions, {
    _isc.UuidValue? commentUuid,
    int? assigneeId,
  }) => caller.callServerEndpoint<_i2c85fb0.CommentThreadView>(
    'comment',
    'reply',
    {
      'threadUuid': threadUuid,
      'body': body,
      'mentions': mentions,
      'commentUuid': commentUuid,
      'assigneeId': assigneeId,
    },
  );

  _ida.Future<_ip2r2v4j.CommentView> edit(
    int commentId,
    String body, {
    List<int>? mentions,
  }) => caller.callServerEndpoint<_ip2r2v4j.CommentView>(
    'comment',
    'edit',
    {
      'commentId': commentId,
      'body': body,
      'mentions': mentions,
    },
  );

  _ida.Future<void> delete(int commentId) => caller.callServerEndpoint<void>(
    'comment',
    'delete',
    {'commentId': commentId},
  );

  _ida.Future<void> deleteThread(_isc.UuidValue threadUuid) =>
      caller.callServerEndpoint<void>(
        'comment',
        'deleteThread',
        {'threadUuid': threadUuid},
      );

  _ida.Future<_i2c85fb0.CommentThreadView> resolve(_isc.UuidValue threadUuid) =>
      caller.callServerEndpoint<_i2c85fb0.CommentThreadView>(
        'comment',
        'resolve',
        {'threadUuid': threadUuid},
      );

  _ida.Future<_i2c85fb0.CommentThreadView> reopen(_isc.UuidValue threadUuid) =>
      caller.callServerEndpoint<_i2c85fb0.CommentThreadView>(
        'comment',
        'reopen',
        {'threadUuid': threadUuid},
      );

  /// Toggles the caller's reaction.
  _ida.Future<_ip2r2v4j.CommentView> react(
    int commentId,
    String emoji,
  ) => caller.callServerEndpoint<_ip2r2v4j.CommentView>(
    'comment',
    'react',
    {
      'commentId': commentId,
      'emoji': emoji,
    },
  );

  _ida.Future<_i2c85fb0.CommentThreadView> updateAnchor(
    _isc.UuidValue threadUuid,
    String anchorJson, {
    _i8agtv5a.CommentAnchorKind? anchorKind,
  }) => caller.callServerEndpoint<_i2c85fb0.CommentThreadView>(
    'comment',
    'updateAnchor',
    {
      'threadUuid': threadUuid,
      'anchorJson': anchorJson,
      'anchorKind': anchorKind,
    },
  );

  /// Live comment changes on an item.
  _ida.Stream<_ikh2q0ca.CommentEvent> watch(_isc.UuidValue itemUuid) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ikh2q0ca.CommentEvent>,
        _ikh2q0ca.CommentEvent
      >(
        'comment',
        'watch',
        {'itemUuid': itemUuid},
        {},
      );
}

/// Wonky Drive (specs/05 §2).
/// {@category Endpoint}
class EndpointDrive extends _isc.EndpointRef {
  EndpointDrive(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'drive';

  /// Children of a folder (null = My Drive root) or a virtual view.
  _ida.Future<_iawn6g1o.DriveListPage> list(
    _isc.UuidValue? folderUuid,
    _i8ldc133.DriveListFilter filter,
    _ikhtp6t5.DriveSort sort,
    String? cursor,
    int limit,
  ) => caller.callServerEndpoint<_iawn6g1o.DriveListPage>(
    'drive',
    'list',
    {
      'folderUuid': folderUuid,
      'filter': filter,
      'sort': sort,
      'cursor': cursor,
      'limit': limit,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> get(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
        'drive',
        'get',
        {'uuid': uuid},
      );

  /// Breadcrumb ancestors visible to the caller, root first.
  _ida.Future<List<_iatsgjjq.DriveItemView>> path(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<List<_iatsgjjq.DriveItemView>>(
        'drive',
        'path',
        {'uuid': uuid},
      );

  _ida.Future<_iawn6g1o.DriveListPage> search(
    String query,
    _icvnufpf.DriveSearchFilters filters,
    String? cursor,
    int limit,
  ) => caller.callServerEndpoint<_iawn6g1o.DriveListPage>(
    'drive',
    'search',
    {
      'query': query,
      'filters': filters,
      'cursor': cursor,
      'limit': limit,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> createFolder(
    _isc.UuidValue? parentUuid,
    String name,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'createFolder',
    {
      'parentUuid': parentUuid,
      'name': name,
    },
  );

  /// Creates a document; idempotent on the client-generated [documentUuid]
  /// and [itemUuid] (offline creation).
  _ida.Future<_iatsgjjq.DriveItemView> createDocument(
    _isc.UuidValue? parentUuid,
    String name,
    _isc.UuidValue? templateUuid,
    String? initialMarkdown, {
    _isc.UuidValue? documentUuid,
    _isc.UuidValue? itemUuid,
  }) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'createDocument',
    {
      'parentUuid': parentUuid,
      'name': name,
      'templateUuid': templateUuid,
      'initialMarkdown': initialMarkdown,
      'documentUuid': documentUuid,
      'itemUuid': itemUuid,
    },
  );

  /// Registers a spreadsheet created locally in a reserved space
  /// (idempotent).
  _ida.Future<_iatsgjjq.DriveItemView> registerSpreadsheet(
    _isc.UuidValue spaceUuid,
    _isc.UuidValue? parentUuid,
    String name,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'registerSpreadsheet',
    {
      'spaceUuid': spaceUuid,
      'parentUuid': parentUuid,
      'name': name,
    },
  );

  /// Creates a spreadsheet server-side (space + rows).
  _ida.Future<_iatsgjjq.DriveItemView> createSpreadsheet(
    _isc.UuidValue? parentUuid,
    String name,
    _isc.UuidValue? templateUuid, {
    String? locale,
    String? timeZone,
  }) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'createSpreadsheet',
    {
      'parentUuid': parentUuid,
      'name': name,
      'templateUuid': templateUuid,
      'locale': locale,
      'timeZone': timeZone,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> rename(
    _isc.UuidValue uuid,
    String name,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'rename',
    {
      'uuid': uuid,
      'name': name,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> updateDescription(
    _isc.UuidValue uuid,
    String? description,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'updateDescription',
    {
      'uuid': uuid,
      'description': description,
    },
  );

  /// Moves items into [newParentUuid] (null = My Drive root, owners only).
  _ida.Future<List<_iatsgjjq.DriveItemView>> move(
    List<_isc.UuidValue> uuids,
    _isc.UuidValue? newParentUuid,
  ) => caller.callServerEndpoint<List<_iatsgjjq.DriveItemView>>(
    'drive',
    'move',
    {
      'uuids': uuids,
      'newParentUuid': newParentUuid,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> copy(
    _isc.UuidValue uuid,
    String newName,
    _isc.UuidValue? parentUuid,
    bool copyComments,
    bool copySharing,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'copy',
    {
      'uuid': uuid,
      'newName': newName,
      'parentUuid': parentUuid,
      'copyComments': copyComments,
      'copySharing': copySharing,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> setStarred(
    _isc.UuidValue uuid,
    bool starred,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'setStarred',
    {
      'uuid': uuid,
      'starred': starred,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> setPinnedOffline(
    _isc.UuidValue uuid,
    bool pinned,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'setPinnedOffline',
    {
      'uuid': uuid,
      'pinned': pinned,
    },
  );

  /// Records that the caller opened the item (Recent; link visits appear in
  /// Shared with me).
  _ida.Future<_iatsgjjq.DriveItemView> markOpened(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
        'drive',
        'markOpened',
        {'uuid': uuid},
      );

  /// "Add shortcut to My Drive" ([parentUuid] null = root).
  _ida.Future<_iatsgjjq.DriveItemView> addShortcut(
    _isc.UuidValue uuid,
    _isc.UuidValue? parentUuid,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'addShortcut',
    {
      'uuid': uuid,
      'parentUuid': parentUuid,
    },
  );

  _ida.Future<void> removeShortcut(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<void>(
        'drive',
        'removeShortcut',
        {'uuid': uuid},
      );

  _ida.Future<void> trash(List<_isc.UuidValue> uuids) =>
      caller.callServerEndpoint<void>(
        'drive',
        'trash',
        {'uuids': uuids},
      );

  _ida.Future<void> restore(List<_isc.UuidValue> uuids) =>
      caller.callServerEndpoint<void>(
        'drive',
        'restore',
        {'uuids': uuids},
      );

  _ida.Future<void> deletePermanently(List<_isc.UuidValue> uuids) =>
      caller.callServerEndpoint<void>(
        'drive',
        'deletePermanently',
        {'uuids': uuids},
      );

  /// Deletes all owned items in the trash; returns how many.
  _ida.Future<int> emptyTrash() => caller.callServerEndpoint<int>(
    'drive',
    'emptyTrash',
    {},
  );

  /// Live changes of items visible to the caller.
  _ida.Stream<_i2k3qk48.DriveChange> watch() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i2k3qk48.DriveChange>,
        _i2k3qk48.DriveChange
      >(
        'drive',
        'watch',
        {},
        {},
      );

  /// Template gallery ([kind] null = all kinds).
  _ida.Future<List<_i1pzk6fp.TemplateView>> listTemplates(
    _i37vo1p2.DriveItemKind? kind,
  ) => caller.callServerEndpoint<List<_i1pzk6fp.TemplateView>>(
    'drive',
    'listTemplates',
    {'kind': kind},
  );

  /// Publishes an owned item as a template ([category] null = unpublish).
  _ida.Future<_iatsgjjq.DriveItemView> setTemplate(
    _isc.UuidValue uuid,
    _i6of8k2c.TemplateCategory? category,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'setTemplate',
    {
      'uuid': uuid,
      'category': category,
    },
  );

  /// Imports an uploaded file (`file.createUpload` with kind importSource)
  /// as a new item.
  _ida.Future<_irwfmef9.ImportReportView> import(
    _isc.UuidValue uploadId,
    _i37vo1p2.DriveItemKind kind,
    _idv1evlb.DriveImportOptions options,
  ) => caller.callServerEndpoint<_irwfmef9.ImportReportView>(
    'drive',
    'import',
    {
      'uploadId': uploadId,
      'kind': kind,
      'options': options,
    },
  );

  /// Registers a deck created on a device (idempotent; Slides 02 §9.3):
  /// `createPresentation(fileUuid: spaceUuid, initialize: false)`; the
  /// client's first op creates the rows (RevLog spec 04 §5). The item uuid
  /// is the file uuid. Never refused for quota.
  _ida.Future<_iatsgjjq.DriveItemView> registerPresentation(
    _isc.UuidValue spaceUuid,
    _isc.UuidValue? parentUuid,
    String name,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'registerPresentation',
    {
      'spaceUuid': spaceUuid,
      'parentUuid': parentUuid,
      'name': name,
    },
  );

  /// Creates a presentation server-side (online; Slides 02 §9.3): a blank
  /// deck with the default theme and a title slide, or with [templateUuid]
  /// a copy of that presentation (SL-8; built-in presentation templates:
  /// SL-22). With [fileUuid] the call is idempotent; [initialize] false
  /// (default true) leaves the file at revision 0 for the client's creation op (RevLog
  /// spec 04 §5).
  _ida.Future<_iatsgjjq.DriveItemView> createPresentation(
    _isc.UuidValue? parentUuid,
    String name,
    _isc.UuidValue? templateUuid, {
    _isc.UuidValue? fileUuid,
    bool? initialize,
  }) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'createPresentation',
    {
      'parentUuid': parentUuid,
      'name': name,
      'templateUuid': templateUuid,
      'fileUuid': fileUuid,
      'initialize': initialize,
    },
  );

  /// Starts the upload of a `file` item (Drive 02 §3.3): checks the role on
  /// the parent (Editor+), name, size ≤ `maxFileUploadBytes` and reserves
  /// quota; inserts the item (`uploading`) and its `driveFile` StoredFile.
  /// Idempotent on (itemUuid, fileUuid). Errors: forbidden, notFound,
  /// invalidArgument, tooLarge, quotaExceeded, limitExceeded, conflict.
  _ida.Future<_ismkx81d.FileUploadStart> createFileUpload(
    _igc8ti2y.FileUploadRequest request,
  ) => caller.callServerEndpoint<_ismkx81d.FileUploadStart>(
    'drive',
    'createFileUpload',
    {'request': request},
  );

  /// Verifies the stored bytes (size, sniffing), marks the item `ready` and
  /// turns the reservation into usage (Drive 02 §3.3).
  _ida.Future<_iatsgjjq.DriveItemView> completeFileUpload(
    _isc.UuidValue itemUuid,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'completeFileUpload',
    {'itemUuid': itemUuid},
  );

  /// Cancels an upload: deletes the item and partial bytes, releases the
  /// reservation.
  _ida.Future<void> cancelFileUpload(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<void>(
        'drive',
        'cancelFileUpload',
        {'itemUuid': itemUuid},
      );

  /// Upload state for resuming (Drive 02 §4.3).
  _ida.Future<_izjlog7o.FileUploadProgress> fileUploadStatus(
    _isc.UuidValue itemUuid,
  ) => caller.callServerEndpoint<_izjlog7o.FileUploadProgress>(
    'drive',
    'fileUploadStatus',
    {'itemUuid': itemUuid},
  );

  /// *Open with* on the server (Drive 02 §7.2): imports a `file` item's
  /// bytes as a [target] item (document or spreadsheet). Viewer+ on the
  /// file, Editor+ on the target folder (else My Drive); quota checked
  /// before and after (Drive 03 §7.2).
  _ida.Future<_irwfmef9.ImportReportView> convertFile(
    _isc.UuidValue fileItemUuid,
    _i37vo1p2.DriveItemKind target,
    _idv1evlb.DriveImportOptions options,
  ) => caller.callServerEndpoint<_irwfmef9.ImportReportView>(
    'drive',
    'convertFile',
    {
      'fileItemUuid': fileItemUuid,
      'target': target,
      'options': options,
    },
  );

  /// A signed URL (15 min) of a file item's bytes for previews, or with
  /// [download] the `GET /files/d/…` download route (Drive 02 §6.1, §8).
  _ida.Future<_i4i1hokq.FileUrlView> fileContentUrl(
    _isc.UuidValue itemUuid, {
    required bool download,
  }) => caller.callServerEndpoint<_i4i1hokq.FileUrlView>(
    'drive',
    'fileContentUrl',
    {
      'itemUuid': itemUuid,
      'download': download,
    },
  );

  /// Client-measured metadata of a file item (e.g. PDF `{pages}`), Editor+
  /// (Drive 02 §6.3).
  _ida.Future<_iatsgjjq.DriveItemView> updateFileMeta(
    _isc.UuidValue itemUuid,
    String fileMetaJson,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'updateFileMeta',
    {
      'itemUuid': itemUuid,
      'fileMetaJson': fileMetaJson,
    },
  );

  /// Quota pre-check without reserving (Drive 03 §7.2): throws
  /// `quotaExceeded` when [bytes] don't fit. With [itemUuid], the item's
  /// owner is charged (images added to someone else's item); else the
  /// caller.
  _ida.Future<void> checkRoom(
    int bytes,
    _isc.UuidValue? itemUuid,
  ) => caller.callServerEndpoint<void>(
    'drive',
    'checkRoom',
    {
      'bytes': bytes,
      'itemUuid': itemUuid,
    },
  );

  /// The caller's owned items (incl. trashed) by counted size, descending
  /// (Storage page, Drive 03 §6.4). Pass `nextCursor` for the next page.
  _ida.Future<_iawn6g1o.DriveListPage> listByStorage(
    _i3az7xi1.StorageListFilter filter,
    String? cursor,
    int limit,
  ) => caller.callServerEndpoint<_iawn6g1o.DriveListPage>(
    'drive',
    'listByStorage',
    {
      'filter': filter,
      'cursor': cursor,
      'limit': limit,
    },
  );

  _ida.Future<_i5ixb3en.StorageUsage> storageUsage() =>
      caller.callServerEndpoint<_i5ixb3en.StorageUsage>(
        'drive',
        'storageUsage',
        {},
      );

  /// Sets a client-rendered thumbnail (uploaded with kind thumbnail).
  _ida.Future<_iatsgjjq.DriveItemView> setThumbnail(
    _isc.UuidValue uuid,
    _isc.UuidValue uploadedFileUuid,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'drive',
    'setThumbnail',
    {
      'uuid': uuid,
      'uploadedFileUuid': uploadedFileUuid,
    },
  );

  /// The activity feed of an item, newest first.
  _ida.Future<List<_itempttd.ActivityEventView>> activity(
    _isc.UuidValue uuid,
    int? beforeId,
    int limit,
  ) => caller.callServerEndpoint<List<_itempttd.ActivityEventView>>(
    'drive',
    'activity',
    {
      'uuid': uuid,
      'beforeId': beforeId,
      'limit': limit,
    },
  );
}

/// Test support for E2E journeys (specs/15 §9, 13 §1): the latest
/// verification codes of `@example.test` addresses. Refuses every call
/// outside the development and test run modes.
/// {@category Endpoint}
class EndpointE2eSupport extends _isc.EndpointRef {
  EndpointE2eSupport(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'e2eSupport';

  _ida.Future<String?> latestVerificationCode(String email) =>
      caller.callServerEndpoint<String?>(
        'e2eSupport',
        'latestVerificationCode',
        {'email': email},
      );

  _ida.Future<String?> latestPasswordResetCode(String email) =>
      caller.callServerEndpoint<String?>(
        'e2eSupport',
        'latestPasswordResetCode',
        {'email': email},
      );
}

/// "Report a problem" and client error reports (specs/03, 11 §5).
///
/// Public (error reports are sent before sign-in too), so calls are rate
/// limited per signed-in user, or per client address when signed out.
/// {@category Endpoint}
class EndpointFeedback extends _isc.EndpointRef {
  EndpointFeedback(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'feedback';

  _ida.Future<void> submit(_i70rrzeg.FeedbackSubmission feedback) =>
      caller.callServerEndpoint<void>(
        'feedback',
        'submit',
        {'feedback': feedback},
      );

  /// Client error reports (anonymized state, no document content).
  _ida.Future<void> reportError(_i70rrzeg.FeedbackSubmission report) =>
      caller.callServerEndpoint<void>(
        'feedback',
        'reportError',
        {'report': report},
      );
}

/// Uploads and signed downloads (suite 12 §1.1). Idempotent on the
/// client-generated [fileUuid]; content may reference `wonky-file://<uuid>`
/// before the bytes arrive.
/// {@category Endpoint}
class EndpointFile extends _isc.EndpointRef {
  EndpointFile(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'file';

  /// Upload description for `FileUploader`. [kind] defaults to image;
  /// imports use `importSource` without an item. Images are re-encoded as
  /// WebP on completion for [imageProfile] (default `content`; a story's
  /// cover uses `cover`).
  _ida.Future<_ilpm2pjc.FileUploadTicket> createUpload(
    _isc.UuidValue fileUuid,
    _isc.UuidValue? itemUuid,
    String fileName,
    String mimeType,
    int size, {
    _iaaducpz.StoredFileKind? kind,
    _i8mxqucd.ImageProfile? imageProfile,
  }) => caller.callServerEndpoint<_ilpm2pjc.FileUploadTicket>(
    'file',
    'createUpload',
    {
      'fileUuid': fileUuid,
      'itemUuid': itemUuid,
      'fileName': fileName,
      'mimeType': mimeType,
      'size': size,
      'kind': kind,
      'imageProfile': imageProfile,
    },
  );

  _ida.Future<_i4i1hokq.FileUrlView> completeUpload(_isc.UuidValue fileUuid) =>
      caller.callServerEndpoint<_i4i1hokq.FileUrlView>(
        'file',
        'completeUpload',
        {'fileUuid': fileUuid},
      );

  /// Status and signed URL (15 min) of a file.
  _ida.Future<_i4i1hokq.FileUrlView> getUrl(_isc.UuidValue fileUuid) =>
      caller.callServerEndpoint<_i4i1hokq.FileUrlView>(
        'file',
        'getUrl',
        {'fileUuid': fileUuid},
      );

  /// (v2, Slides 03 A-03-3) Copies an image the caller can read into
  /// [targetItemUuid] as [newFileUuid] (idempotent on [newFileUuid];
  /// quota of the target's owner). Errors: notFound, forbidden,
  /// quotaExceeded, conflict.
  _ida.Future<_i4i1hokq.FileUrlView> copyToItem(
    _isc.UuidValue sourceFileUuid,
    _isc.UuidValue newFileUuid,
    _isc.UuidValue targetItemUuid,
  ) => caller.callServerEndpoint<_i4i1hokq.FileUrlView>(
    'file',
    'copyToItem',
    {
      'sourceFileUuid': sourceFileUuid,
      'newFileUuid': newFileUuid,
      'targetItemUuid': targetItemUuid,
    },
  );

  /// (v2, Slides 03 A-03-4) Image proxy for images inserted by URL into
  /// drive item [itemUuid] (any app; caller needs viewer access): the bytes
  /// of the https image [url]. Private addresses, other ports, redirects
  /// and non-images are refused; ≤ 10 MB. The client stores the bytes as
  /// an ordinary (offline-first, quota-checked) upload.
  _ida.Future<_idt.ByteData> fetchImage(
    _isc.UuidValue itemUuid,
    String url,
  ) => caller.callServerEndpoint<_idt.ByteData>(
    'file',
    'fetchImage',
    {
      'itemUuid': itemUuid,
      'url': url,
    },
  );

  _ida.Future<List<_i4i1hokq.FileUrlView>> getUrls(
    List<_isc.UuidValue> fileUuids,
  ) => caller.callServerEndpoint<List<_i4i1hokq.FileUrlView>>(
    'file',
    'getUrls',
    {'fileUuids': fileUuids},
  );
}

/// The UI bridge stream (suite 09 §6.1): a signed-in app window that allows
/// MCP control connects here; `ui.*` tool calls are relayed to it as
/// [UiBridgeRequest]s and answered with [UiBridgeResponse]s.
/// {@category Endpoint}
class EndpointUiBridge extends _isc.EndpointRef {
  EndpointUiBridge(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'uiBridge';

  _ida.Stream<_i1yu9qix.UiBridgeMessage> connect(
    _ida.Stream<_i1yu9qix.UiBridgeMessage> fromApp,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i1yu9qix.UiBridgeMessage>,
        _i1yu9qix.UiBridgeMessage
      >(
        'uiBridge',
        'connect',
        {},
        {'fromApp': fromApp},
      );
}

/// Protocol information checked by clients on connect (specs/01 §7).
/// {@category Endpoint}
class EndpointMeta extends _isc.EndpointRef {
  EndpointMeta(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'meta';

  _ida.Future<_ix72qie6.ProtocolInfo> getInfo() =>
      caller.callServerEndpoint<_ix72qie6.ProtocolInfo>(
        'meta',
        'getInfo',
        {},
      );
}

/// In-app notifications (specs/07 §4).
/// {@category Endpoint}
class EndpointNotification extends _isc.EndpointRef {
  EndpointNotification(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  _ida.Future<_ispzjfjq.NotificationPage> list(
    String? cursor,
    int limit,
    bool unreadOnly,
  ) => caller.callServerEndpoint<_ispzjfjq.NotificationPage>(
    'notification',
    'list',
    {
      'cursor': cursor,
      'limit': limit,
      'unreadOnly': unreadOnly,
    },
  );

  _ida.Future<int> unreadCount() => caller.callServerEndpoint<int>(
    'notification',
    'unreadCount',
    {},
  );

  /// Marks notifications read; returns the unread count.
  _ida.Future<int> markRead(List<int> ids) => caller.callServerEndpoint<int>(
    'notification',
    'markRead',
    {'ids': ids},
  );

  _ida.Future<int> markAllRead() => caller.callServerEndpoint<int>(
    'notification',
    'markAllRead',
    {},
  );

  /// New notifications and unread count changes.
  _ida.Stream<_ibtz26fx.NotificationEvent> watch() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ibtz26fx.NotificationEvent>,
        _ibtz26fx.NotificationEvent
      >(
        'notification',
        'watch',
        {},
        {},
      );
}

/// Ephemeral presence on an item (specs/07 §1).
/// {@category Endpoint}
class EndpointPresence extends _isc.EndpointRef {
  EndpointPresence(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'presence';

  /// Joins [itemUuid]; the first event is a [PresenceRoster].
  _ida.Stream<_i1lme7np.PresenceEvent> join(
    _isc.UuidValue itemUuid,
    _ida.Stream<_izu9ijhe.PresenceUpdate> updates,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i1lme7np.PresenceEvent>,
        _i1lme7np.PresenceEvent
      >(
        'presence',
        'join',
        {'itemUuid': itemUuid},
        {'updates': updates},
      );
}

/// Publications (specs/18 §9.1): starting a story from a contributor link,
/// and the owner's settings.
/// {@category Endpoint}
class EndpointPublication extends _isc.EndpointRef {
  EndpointPublication(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'publication';

  /// The publication of a contributor link.
  _ida.Future<_igbz1wj9.PublicationCard> resolve(String publicId) =>
      caller.callServerEndpoint<_igbz1wj9.PublicationCard>(
        'publication',
        'resolve',
        {'publicId': publicId},
      );

  /// Creates the document of a new story; [agreed] confirms the consent
  /// dialog.
  _ida.Future<_i767e3eb.SubmissionStarted> startSubmission(
    String publicId,
    String? ref,
    bool agreed,
  ) => caller.callServerEndpoint<_i767e3eb.SubmissionStarted>(
    'publication',
    'startSubmission',
    {
      'publicId': publicId,
      'ref': ref,
      'agreed': agreed,
    },
  );

  _ida.Future<List<_i9bruko9.PublicationSettings>> list() =>
      caller.callServerEndpoint<List<_i9bruko9.PublicationSettings>>(
        'publication',
        'list',
        {},
      );

  /// Creates a publication; the result holds the signing secret once.
  _ida.Future<_ihfocp8h.PublicationSecret> create(
    _ii8xbzwt.PublicationInput input,
  ) => caller.callServerEndpoint<_ihfocp8h.PublicationSecret>(
    'publication',
    'create',
    {'input': input},
  );

  _ida.Future<_i9bruko9.PublicationSettings> update(
    String publicId,
    _ii8xbzwt.PublicationInput input,
  ) => caller.callServerEndpoint<_i9bruko9.PublicationSettings>(
    'publication',
    'update',
    {
      'publicId': publicId,
      'input': input,
    },
  );

  _ida.Future<void> delete(String publicId) => caller.callServerEndpoint<void>(
    'publication',
    'delete',
    {'publicId': publicId},
  );

  _ida.Future<_i9sbxmp8.PublicationCheckResult> verify(String publicId) =>
      caller.callServerEndpoint<_i9sbxmp8.PublicationCheckResult>(
        'publication',
        'verify',
        {'publicId': publicId},
      );

  _ida.Future<_ihfocp8h.PublicationSecret> rotateSecret(String publicId) =>
      caller.callServerEndpoint<_ihfocp8h.PublicationSecret>(
        'publication',
        'rotateSecret',
        {'publicId': publicId},
      );

  _ida.Future<_ihfocp8h.PublicationSecret> createApiKey(String publicId) =>
      caller.callServerEndpoint<_ihfocp8h.PublicationSecret>(
        'publication',
        'createApiKey',
        {'publicId': publicId},
      );

  _ida.Future<_i9bruko9.PublicationSettings> setModerators(
    String publicId,
    List<String> emails,
  ) => caller.callServerEndpoint<_i9bruko9.PublicationSettings>(
    'publication',
    'setModerators',
    {
      'publicId': publicId,
      'emails': emails,
    },
  );

  _ida.Future<List<_ipl2ldhs.PublicationDeliveryView>> deliveries(
    String publicId,
  ) => caller.callServerEndpoint<List<_ipl2ldhs.PublicationDeliveryView>>(
    'publication',
    'deliveries',
    {'publicId': publicId},
  );

  _ida.Future<_ipl2ldhs.PublicationDeliveryView> resend(
    String publicId,
    String webhookId,
  ) => caller.callServerEndpoint<_ipl2ldhs.PublicationDeliveryView>(
    'publication',
    'resend',
    {
      'publicId': publicId,
      'webhookId': webhookId,
    },
  );

  _ida.Future<_i9sbxmp8.PublicationCheckResult> sendTest(String publicId) =>
      caller.callServerEndpoint<_i9sbxmp8.PublicationCheckResult>(
        'publication',
        'sendTest',
        {'publicId': publicId},
      );
}

/// A document's submission to a publication (specs/18 §9.2).
/// {@category Endpoint}
class EndpointSubmission extends _isc.EndpointRef {
  EndpointSubmission(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'submission';

  /// The document's submission, or null (viewer+).
  _ida.Future<_iy9ei8t0.SubmissionView?> get(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<_iy9ei8t0.SubmissionView?>(
        'submission',
        'get',
        {'itemUuid': itemUuid},
      );

  /// Submits the current revision (editor+); [agreed] confirms the
  /// publication's terms when they changed.
  _ida.Future<_iy9ei8t0.SubmissionView> submit(
    _isc.UuidValue itemUuid,
    _i8t9b0m8.SubmissionValues values,
    bool agreed,
  ) => caller.callServerEndpoint<_iy9ei8t0.SubmissionView>(
    'submission',
    'submit',
    {
      'itemUuid': itemUuid,
      'values': values,
      'agreed': agreed,
    },
  );

  _ida.Future<_iy9ei8t0.SubmissionView> withdraw(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<_iy9ei8t0.SubmissionView>(
        'submission',
        'withdraw',
        {'itemUuid': itemUuid},
      );

  _ida.Future<void> disconnect(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<void>(
        'submission',
        'disconnect',
        {'itemUuid': itemUuid},
      );

  /// Undoes [disconnect].
  _ida.Future<_iy9ei8t0.SubmissionView?> reconnect(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<_iy9ei8t0.SubmissionView?>(
        'submission',
        'reconnect',
        {'itemUuid': itemUuid},
      );
}

/// Sharing (specs/06 §4).
/// {@category Endpoint}
class EndpointSharing extends _isc.EndpointRef {
  EndpointSharing(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sharing';

  _ida.Future<_idqkfu7d.SharingInfo> getSharing(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
        'sharing',
        'getSharing',
        {'itemUuid': itemUuid},
      );

  _ida.Future<_idqkfu7d.SharingInfo> share(
    _isc.UuidValue itemUuid,
    List<String> emails,
    _i7gd5xik.AccessRole role,
    bool notify,
    String? message,
    DateTime? expiresAt,
  ) => caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
    'sharing',
    'share',
    {
      'itemUuid': itemUuid,
      'emails': emails,
      'role': role,
      'notify': notify,
      'message': message,
      'expiresAt': expiresAt,
    },
  );

  _ida.Future<_idqkfu7d.SharingInfo> updateRole(
    _isc.UuidValue itemUuid,
    int userId,
    _i7gd5xik.AccessRole role, {
    DateTime? expiresAt,
  }) => caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
    'sharing',
    'updateRole',
    {
      'itemUuid': itemUuid,
      'userId': userId,
      'role': role,
      'expiresAt': expiresAt,
    },
  );

  /// Removes a person (or a pending invite with [invitedEmail]).
  _ida.Future<_idqkfu7d.SharingInfo> remove(
    _isc.UuidValue itemUuid,
    int? userId, {
    String? invitedEmail,
  }) => caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
    'sharing',
    'remove',
    {
      'itemUuid': itemUuid,
      'userId': userId,
      'invitedEmail': invitedEmail,
    },
  );

  /// Offers ownership; the new owner accepts with
  /// [respondToOwnershipTransfer].
  _ida.Future<_idqkfu7d.SharingInfo> transferOwnership(
    _isc.UuidValue itemUuid,
    int newOwnerUserId,
  ) => caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
    'sharing',
    'transferOwnership',
    {
      'itemUuid': itemUuid,
      'newOwnerUserId': newOwnerUserId,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> respondToOwnershipTransfer(
    int transferId,
    bool accept,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'sharing',
    'respondToOwnershipTransfer',
    {
      'transferId': transferId,
      'accept': accept,
    },
  );

  /// Link sharing role; null = restricted.
  _ida.Future<_idqkfu7d.SharingInfo> setLink(
    _isc.UuidValue itemUuid,
    _i7gd5xik.AccessRole? role,
  ) => caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
    'sharing',
    'setLink',
    {
      'itemUuid': itemUuid,
      'role': role,
    },
  );

  _ida.Future<_idqkfu7d.SharingInfo> rotateLink(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
        'sharing',
        'rotateLink',
        {'itemUuid': itemUuid},
      );

  _ida.Future<_idqkfu7d.SharingInfo> updateSettings(
    _isc.UuidValue itemUuid,
    _i0x662rz.ItemSharingSettings settings,
  ) => caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
    'sharing',
    'updateSettings',
    {
      'itemUuid': itemUuid,
      'settings': settings,
    },
  );

  _ida.Future<void> requestAccess(
    _isc.UuidValue itemUuid,
    _i7gd5xik.AccessRole role,
    String? message,
  ) => caller.callServerEndpoint<void>(
    'sharing',
    'requestAccess',
    {
      'itemUuid': itemUuid,
      'role': role,
      'message': message,
    },
  );

  _ida.Future<_idqkfu7d.SharingInfo> handleAccessRequest(
    int requestId,
    bool approve,
    _i7gd5xik.AccessRole? role,
  ) => caller.callServerEndpoint<_idqkfu7d.SharingInfo>(
    'sharing',
    'handleAccessRequest',
    {
      'requestId': requestId,
      'approve': approve,
      'role': role,
    },
  );

  /// Resolves a share link token (`/invite/<token>`).
  _ida.Future<_idoq825d.InviteResolution> resolveInvite(String token) =>
      caller.callServerEndpoint<_idoq825d.InviteResolution>(
        'sharing',
        'resolveInvite',
        {'token': token},
      );
}

/// Personal access tokens for MCP (specs/04 §5, 09 §2).
/// {@category Endpoint}
class EndpointAccessToken extends _isc.EndpointRef {
  EndpointAccessToken(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'accessToken';

  _ida.Future<List<_ip6swqsj.AccessTokenView>> list() =>
      caller.callServerEndpoint<List<_ip6swqsj.AccessTokenView>>(
        'accessToken',
        'list',
        {},
      );

  /// Creates a token; the secret is returned only here.
  _ida.Future<_irplbwpp.CreatedAccessToken> create(
    String name,
    List<String> scopes,
    DateTime? expiresAt,
  ) => caller.callServerEndpoint<_irplbwpp.CreatedAccessToken>(
    'accessToken',
    'create',
    {
      'name': name,
      'scopes': scopes,
      'expiresAt': expiresAt,
    },
  );

  _ida.Future<_ip6swqsj.AccessTokenView> revoke(int id) =>
      caller.callServerEndpoint<_ip6swqsj.AccessTokenView>(
        'accessToken',
        'revoke',
        {'id': id},
      );
}

/// Sign in with Google (specs/04 §1.6): `login` (native ID token) and
/// `loginWithCode` (web OAuth2 PKCE code, redirect `/auth/callback`).
/// Answers only when the `googleClientSecret` password is configured.
/// {@category Endpoint}
class EndpointGoogleIdp extends _iaic.EndpointGoogleIdpBase {
  EndpointGoogleIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'googleIdp';

  /// Validates a Google ID token and either logs in the associated user or
  /// creates a new user account if the Google account ID is not yet known.
  ///
  /// If a new user is created an associated [UserProfile] is also created.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String idToken,
    required String? accessToken,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'googleIdp',
    'login',
    {
      'idToken': idToken,
      'accessToken': accessToken,
    },
  );

  /// Validates a Google authorization code from the web OAuth2 PKCE flow and
  /// either logs in the associated user or creates a new account.
  ///
  /// This is the web counterpart of [login], which accepts an ID token directly
  /// (used on native platforms via the `google_sign_in` package).
  ///
  /// If a new user is created an associated [UserProfile] is also created.
  @override
  _ida.Future<_iacc.AuthSuccess> loginWithCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'googleIdp',
    'loginWithCode',
    {
      'code': code,
      'codeVerifier': codeVerifier,
      'redirectUri': redirectUri,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'googleIdp',
    'hasAccount',
    {},
  );
}

/// The signed-in user: profile, preferences, user search and account
/// deletion (specs/04 §5).
/// {@category Endpoint}
class EndpointUser extends _isc.EndpointRef {
  EndpointUser(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'user';

  /// The caller's profile. The first call after sign-up also creates the
  /// welcome document and spreadsheet.
  _ida.Future<_ioc8dkw9.UserProfileView> getMe() =>
      caller.callServerEndpoint<_ioc8dkw9.UserProfileView>(
        'user',
        'getMe',
        {},
      );

  /// Updates the profile; null leaves a field unchanged, an empty string
  /// clears [locale]/[timeZone] (follow the device).
  _ida.Future<_ioc8dkw9.UserProfileView> updateProfile({
    String? displayName,
    String? locale,
    String? timeZone,
  }) => caller.callServerEndpoint<_ioc8dkw9.UserProfileView>(
    'user',
    'updateProfile',
    {
      'displayName': displayName,
      'locale': locale,
      'timeZone': timeZone,
    },
  );

  /// Starts an avatar upload (upload description flow); finish with
  /// `file.completeUpload(fileUuid)` (stores a 256 × 256 WebP) and
  /// [setAvatar].
  _ida.Future<_ilpm2pjc.FileUploadTicket> uploadAvatar(
    _isc.UuidValue fileUuid,
    String fileName,
    String mimeType,
    int size,
  ) => caller.callServerEndpoint<_ilpm2pjc.FileUploadTicket>(
    'user',
    'uploadAvatar',
    {
      'fileUuid': fileUuid,
      'fileName': fileName,
      'mimeType': mimeType,
      'size': size,
    },
  );

  /// Sets (or with null removes) the avatar.
  _ida.Future<_ioc8dkw9.UserProfileView> setAvatar(_isc.UuidValue? fileUuid) =>
      caller.callServerEndpoint<_ioc8dkw9.UserProfileView>(
        'user',
        'setAvatar',
        {'fileUuid': fileUuid},
      );

  _ida.Future<_i59f1kw7.UserPreferences> getPreferences() =>
      caller.callServerEndpoint<_i59f1kw7.UserPreferences>(
        'user',
        'getPreferences',
        {},
      );

  _ida.Future<_i59f1kw7.UserPreferences> updatePreferences(
    _i6jtsw1b.UserPreferencesPatch patch,
  ) => caller.callServerEndpoint<_i59f1kw7.UserPreferences>(
    'user',
    'updatePreferences',
    {'patch': patch},
  );

  /// Users for the share dialog and @mentions (people sharing items with the
  /// caller, or exact email matches).
  _ida.Future<List<_iq7femvs.UserSummary>> searchUsers(
    String query,
    int limit,
  ) => caller.callServerEndpoint<List<_iq7femvs.UserSummary>>(
    'user',
    'searchUsers',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Summaries of users by id (authors, participants): only the caller and
  /// users related to them (who share an item with them, as in
  /// [searchUsers]); other ids are left out.
  _ida.Future<List<_iq7femvs.UserSummary>> getUsers(List<int> ids) =>
      caller.callServerEndpoint<List<_iq7femvs.UserSummary>>(
        'user',
        'getUsers',
        {'ids': ids},
      );

  _ida.Future<_ik5w0ki0.AccountDeletionPreview> accountDeletionPreview() =>
      caller.callServerEndpoint<_ik5w0ki0.AccountDeletionPreview>(
        'user',
        'accountDeletionPreview',
        {},
      );

  /// Deletes the account; [confirmation] must equal the account email.
  _ida.Future<void> deleteAccount(String confirmation) =>
      caller.callServerEndpoint<void>(
        'user',
        'deleteAccount',
        {'confirmation': confirmation},
      );
}

/// Version history shared by both apps (specs/07 §5). Editors+.
/// {@category Endpoint}
class EndpointVersion extends _isc.EndpointRef {
  EndpointVersion(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'version';

  _ida.Future<List<_itqtmykd.ItemVersionView>> list(
    _isc.UuidValue itemUuid,
    bool namedOnly, {
    int? beforeId,
    int? limit,
  }) => caller.callServerEndpoint<List<_itqtmykd.ItemVersionView>>(
    'version',
    'list',
    {
      'itemUuid': itemUuid,
      'namedOnly': namedOnly,
      'beforeId': beforeId,
      'limit': limit,
    },
  );

  /// Captures and names the current state.
  _ida.Future<_itqtmykd.ItemVersionView> nameCurrent(
    _isc.UuidValue itemUuid,
    String name,
  ) => caller.callServerEndpoint<_itqtmykd.ItemVersionView>(
    'version',
    'nameCurrent',
    {
      'itemUuid': itemUuid,
      'name': name,
    },
  );

  /// Names a version; null removes the name.
  _ida.Future<_itqtmykd.ItemVersionView> rename(
    _isc.UuidValue itemUuid,
    int versionId,
    String? name,
  ) => caller.callServerEndpoint<_itqtmykd.ItemVersionView>(
    'version',
    'rename',
    {
      'itemUuid': itemUuid,
      'versionId': versionId,
      'name': name,
    },
  );

  /// Restores a version (a restore point is captured first).
  _ida.Future<_iyei7m5z.VersionRestoreResult> restore(
    _isc.UuidValue itemUuid,
    int versionId,
  ) => caller.callServerEndpoint<_iyei7m5z.VersionRestoreResult>(
    'version',
    'restore',
    {
      'itemUuid': itemUuid,
      'versionId': versionId,
    },
  );

  /// Signed URL (15 min) of a Sheets snapshot (gzip NDJSON).
  _ida.Future<_i4i1hokq.FileUrlView> getSnapshotUrl(
    _isc.UuidValue itemUuid,
    int versionId,
  ) => caller.callServerEndpoint<_i4i1hokq.FileUrlView>(
    'version',
    'getSnapshotUrl',
    {
      'itemUuid': itemUuid,
      'versionId': versionId,
    },
  );
}

/// The inline AI features of Wonky Sheets (Sheets 12 §6.4–6.10) and the AI
/// changes preview of Suggest-mode assistant runs (§6.3). The assistant
/// panel itself uses `assistant.chat` with the spreadsheet's item uuid and
/// the `sheets*` fields of [AssistantContextHints].
/// {@category Endpoint}
class EndpointSheetsAi extends _isc.EndpointRef {
  EndpointSheetsAi(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sheetsAi';

  /// Formula from natural language for [cell] (A1 with sheet). Nothing is
  /// written; the app inserts the formula with `sheets.edit.setCellInput`.
  _ida.Future<_irs9q9tq.SheetsFormulaSuggestion> suggestFormula(
    _isc.UuidValue itemUuid,
    String cell,
    String prompt,
  ) => caller.callServerEndpoint<_irs9q9tq.SheetsFormulaSuggestion>(
    'sheetsAi',
    'suggestFormula',
    {
      'itemUuid': itemUuid,
      'cell': cell,
      'prompt': prompt,
    },
  );

  /// Streams a plain-language explanation of the formula in [cell] (the
  /// assistant panel shows it).
  _ida.Stream<_ivbb4qsj.InlineAiEvent> explainFormula(
    _isc.UuidValue itemUuid,
    String cell,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ivbb4qsj.InlineAiEvent>,
        _ivbb4qsj.InlineAiEvent
      >(
        'sheetsAi',
        'explainFormula',
        {
          'itemUuid': itemUuid,
          'cell': cell,
        },
        {},
      );

  /// Fill with AI: proposals for the empty cells of a column [range]
  /// (examples = its filled cells). Nothing is written.
  _ida.Future<_i9koccid.SheetsFillProposal> fillRange(
    _isc.UuidValue itemUuid,
    String range,
    String? instructions,
  ) => caller.callServerEndpoint<_i9koccid.SheetsFillProposal>(
    'sheetsAi',
    'fillRange',
    {
      'itemUuid': itemUuid,
      'range': range,
      'instructions': instructions,
    },
  );

  /// Writes the accepted proposals as one undo step "AI: Fill …"
  /// (`SheetsEndpoint.revertChange(changeId)` undoes it).
  _ida.Future<_isefwvgb.SheetsAiApplyResult> applyFill(
    _isc.UuidValue itemUuid,
    String range,
    List<_i2syfqhi.SheetsFillRow> rows,
  ) => caller.callServerEndpoint<_isefwvgb.SheetsAiApplyResult>(
    'sheetsAi',
    'applyFill',
    {
      'itemUuid': itemUuid,
      'range': range,
      'rows': rows,
    },
  );

  /// Prompt chips of *Data › Analyze with AI* for [range] (or the first
  /// table).
  _ida.Future<List<String>> analyzeChips(
    _isc.UuidValue itemUuid,
    String? range,
  ) => caller.callServerEndpoint<List<String>>(
    'sheetsAi',
    'analyzeChips',
    {
      'itemUuid': itemUuid,
      'range': range,
    },
  );

  /// An alt-text proposal for a chart.
  _ida.Future<String> describeChart(
    _isc.UuidValue itemUuid,
    String chartId,
  ) => caller.callServerEndpoint<String>(
    'sheetsAi',
    'describeChart',
    {
      'itemUuid': itemUuid,
      'chartId': chartId,
    },
  );

  /// The AI changes preview of a Suggest-mode run (`previewId` of the
  /// `previewReady` / `done` assistant events).
  _ida.Future<_ijqca8sl.SheetsAiPreview> getPreview(String previewId) =>
      caller.callServerEndpoint<_ijqca8sl.SheetsAiPreview>(
        'sheetsAi',
        'getPreview',
        {'previewId': previewId},
      );

  /// Applies the selected calls (null = all) as one undo step.
  _ida.Future<_isefwvgb.SheetsAiApplyResult> applyPreview(
    String previewId,
    List<String>? callIds,
  ) => caller.callServerEndpoint<_isefwvgb.SheetsAiApplyResult>(
    'sheetsAi',
    'applyPreview',
    {
      'previewId': previewId,
      'callIds': callIds,
    },
  );

  /// Evaluates `=AI()` cells (Sheets 12 §6.8): cached values, new ones for
  /// Editors; [refresh] recomputes (*Refresh AI cells*).
  _ida.Future<List<_ivc6ykj9.SheetsAiCellResult>> evaluateAiCells(
    _isc.UuidValue itemUuid,
    List<_ibrzlkni.SheetsAiCellRequest> requests,
    bool refresh,
  ) => caller.callServerEndpoint<List<_ivc6ykj9.SheetsAiCellResult>>(
    'sheetsAi',
    'evaluateAiCells',
    {
      'itemUuid': itemUuid,
      'requests': requests,
      'refresh': refresh,
    },
  );

  /// Discards a preview.
  _ida.Future<void> discardPreview(String previewId) =>
      caller.callServerEndpoint<void>(
        'sheetsAi',
        'discardPreview',
        {'previewId': previewId},
      );
}

/// Spreadsheet sessions over RevLog (RevLog spec 04 §1): `sheetsDoc.*`.
/// {@category Endpoint}
class EndpointSheetsDoc extends _isc.EndpointRef {
  EndpointSheetsDoc(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sheetsDoc';

  /// Opens an editing/viewing session (04 §2).
  _ida.Stream<_ibic7sfk.RevServerMessage> connect(
    _isc.UuidValue fileUuid,
    int knownRevision,
    String tabId,
    _ida.Stream<_iedvhh7l.RevClientMessage> input,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ibic7sfk.RevServerMessage>,
        _ibic7sfk.RevServerMessage
      >(
        'sheetsDoc',
        'connect',
        {
          'fileUuid': fileUuid,
          'knownRevision': knownRevision,
          'tabId': tabId,
        },
        {'input': input},
      );

  /// A bootstrap page (04 §3). Viewer+.
  _ida.Future<_ivzrugmo.RevPage> page(
    _isc.UuidValue fileUuid,
    _isw8g0pp.RevPageRequest request,
  ) => caller.callServerEndpoint<_ivzrugmo.RevPage>(
    'sheetsDoc',
    'page',
    {
      'fileUuid': fileUuid,
      'request': request,
    },
  );

  /// Ops in (fromRevision, toRevision] (04 §1, 05 §11).
  _ida.Future<List<_iq15rk0l.RevOpView>> ops(
    _isc.UuidValue fileUuid,
    int fromRevision,
    int toRevision,
  ) => caller.callServerEndpoint<List<_iq15rk0l.RevOpView>>(
    'sheetsDoc',
    'ops',
    {
      'fileUuid': fileUuid,
      'fromRevision': fromRevision,
      'toRevision': toRevision,
    },
  );

  /// Head revision, role and stats. Viewer+.
  _ida.Future<_ipiq4i7g.RevFileInfo> info(_isc.UuidValue fileUuid) =>
      caller.callServerEndpoint<_ipiq4i7g.RevFileInfo>(
        'sheetsDoc',
        'info',
        {'fileUuid': fileUuid},
      );
}

/// Online-only Sheets operations (suite 12 §2, Sheets 10, 12 §2.5).
/// {@category Endpoint}
class EndpointSheets extends _isc.EndpointRef {
  EndpointSheets(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sheets';

  /// The caller's script user properties of a spreadsheet (RevLog spec
  /// 02 §2.4, Sheets 09 §6.9). Viewer+; private per user.
  _ida.Future<Map<String, String>> getUserProperties(_isc.UuidValue fileUuid) =>
      caller.callServerEndpoint<Map<String, String>>(
        'sheets',
        'getUserProperties',
        {'fileUuid': fileUuid},
      );

  /// Writes the caller's script user properties (null = delete). Viewer+.
  _ida.Future<void> setUserProperties(
    _isc.UuidValue fileUuid,
    Map<String, String?> changes,
  ) => caller.callServerEndpoint<void>(
    'sheets',
    'setUserProperties',
    {
      'fileUuid': fileUuid,
      'changes': changes,
    },
  );

  /// Named functions of another spreadsheet for *Import function*
  /// (Sheets 07 §9.4): JSON list of `{name, formula, comment, metaJson}`.
  _ida.Future<String> namedFunctions(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<String>(
        'sheets',
        'namedFunctions',
        {'itemUuid': itemUuid},
      );

  /// The theme JSON of another spreadsheet for *Import theme* (Sheets 06
  /// §13).
  _ida.Future<String> spreadsheetTheme(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<String>(
        'sheets',
        'spreadsheetTheme',
        {'itemUuid': itemUuid},
      );

  /// Undo of a server-side change (`sheets.serverChange`).
  _ida.Future<_i107v8u3.RevertResult> revertChange(_isc.UuidValue changeId) =>
      caller.callServerEndpoint<_i107v8u3.RevertResult>(
        'sheets',
        'revertChange',
        {'changeId': changeId},
      );

  /// Redo of a reverted server-side change ([changeId] of the original or of
  /// its revert).
  _ida.Future<_i107v8u3.RevertResult> reapplyChange(_isc.UuidValue changeId) =>
      caller.callServerEndpoint<_i107v8u3.RevertResult>(
        'sheets',
        'reapplyChange',
        {'changeId': changeId},
      );

  _ida.Future<_i8ap5j9q.CellHistoryPage> cellHistory(
    _isc.UuidValue spreadsheetUuid,
    _isc.UuidValue sheetId,
    _isc.UuidValue rowId,
    _isc.UuidValue colId,
    String? cursor,
  ) => caller.callServerEndpoint<_i8ap5j9q.CellHistoryPage>(
    'sheets',
    'cellHistory',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'sheetId': sheetId,
      'rowId': rowId,
      'colId': colId,
      'cursor': cursor,
    },
  );

  _ida.Future<_im0q5n3x.SheetsActivitySummary> activitySummary(
    _isc.UuidValue spreadsheetUuid,
    int days,
  ) => caller.callServerEndpoint<_im0q5n3x.SheetsActivitySummary>(
    'sheets',
    'activitySummary',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'days': days,
    },
  );

  /// Image proxy for `IMAGE("https://…")` cells and images inserted by URL
  /// (08 §10): the bytes of the https image [url] (private addresses are
  /// refused).
  _ida.Future<_idt.ByteData> fetchImage(
    _isc.UuidValue itemUuid,
    String url,
  ) => caller.callServerEndpoint<_idt.ByteData>(
    'sheets',
    'fetchImage',
    {
      'itemUuid': itemUuid,
      'url': url,
    },
  );
}

/// Server import jobs into an existing spreadsheet (Sheets 11 §3.3): big
/// files the client should not parse and plan itself. New spreadsheets are
/// imported with `drive.import`.
/// {@category Endpoint}
class EndpointSheetsImport extends _isc.EndpointRef {
  EndpointSheetsImport(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sheetsImport';

  /// Queues the import of the upload [uploadId] (`importSource`) into
  /// [spreadsheetUuid] with [optionsJson] (`ImportOptions`, 11 §9).
  /// [activeSheetId] is the target sheet of the in-sheet locations and the
  /// insert position of new sheets. Returns the job id.
  _ida.Future<_isc.UuidValue> importInto(
    _isc.UuidValue spreadsheetUuid,
    _isc.UuidValue uploadId,
    String optionsJson,
    String? activeSheetId,
  ) => caller.callServerEndpoint<_isc.UuidValue>(
    'sheetsImport',
    'importInto',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'uploadId': uploadId,
      'optionsJson': optionsJson,
      'activeSheetId': activeSheetId,
    },
  );

  /// Progress of [jobId] until it is done, failed or cancelled.
  _ida.Stream<_in60swvs.SheetsImportProgress> watchImport(
    _isc.UuidValue jobId,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_in60swvs.SheetsImportProgress>,
        _in60swvs.SheetsImportProgress
      >(
        'sheetsImport',
        'watchImport',
        {'jobId': jobId},
        {},
      );

  /// The current progress of [jobId].
  _ida.Future<_in60swvs.SheetsImportProgress> importProgress(
    _isc.UuidValue jobId,
  ) => caller.callServerEndpoint<_in60swvs.SheetsImportProgress>(
    'sheetsImport',
    'importProgress',
    {'jobId': jobId},
  );

  /// Another spreadsheet the caller can read as an XLSX file to import
  /// (*Import › Drive*, 11 §2.1): a signed download URL (15 min).
  _ida.Future<_ia6gray1.ExportResultView> sourceFromDrive(
    _isc.UuidValue itemUuid,
  ) => caller.callServerEndpoint<_ia6gray1.ExportResultView>(
    'sheetsImport',
    'sourceFromDrive',
    {'itemUuid': itemUuid},
  );

  /// Cancels [jobId]; written chunks are reverted.
  _ida.Future<_in60swvs.SheetsImportProgress> cancelImport(
    _isc.UuidValue jobId,
  ) => caller.callServerEndpoint<_in60swvs.SheetsImportProgress>(
    'sheetsImport',
    'cancelImport',
    {'jobId': jobId},
  );
}

/// Scripts of a spreadsheet (Sheets 09): build, run on server, executions
/// log, authorization and the URL fetch proxy. `spreadsheetUuid` is the
/// drive item uuid or the space uuid.
/// {@category Endpoint}
class EndpointScript extends _isc.EndpointRef {
  EndpointScript(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'script';

  /// Builds the project's current sources (09 §9.1); returns diagnostics.
  _ida.Future<_igk7mjr7.ScriptCompileResponse> compile(
    _isc.UuidValue spreadsheetUuid,
  ) => caller.callServerEndpoint<_igk7mjr7.ScriptCompileResponse>(
    'script',
    'compile',
    {'spreadsheetUuid': spreadsheetUuid},
  );

  /// Diagnostics for unsaved editor content (09 §9.5); JSON list.
  _ida.Future<String> analyze(
    _isc.UuidValue spreadsheetUuid,
    String fileName,
    String source,
  ) => caller.callServerEndpoint<String>(
    'script',
    'analyze',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'fileName': fileName,
      'source': source,
    },
  );

  /// EVC bytecode of the last good build (clients cache it by build hash).
  _ida.Future<_idt.ByteData> bytecode(_isc.UuidValue spreadsheetUuid) =>
      caller.callServerEndpoint<_idt.ByteData>(
        'script',
        'bytecode',
        {'spreadsheetUuid': spreadsheetUuid},
      );

  /// *Run on server* (09 §14.5): [argsJson] is a JSON list.
  _ida.Future<_iaw9fhnx.ScriptRunResponse> run(
    _isc.UuidValue spreadsheetUuid,
    String functionName,
    String? argsJson,
  ) => caller.callServerEndpoint<_iaw9fhnx.ScriptRunResponse>(
    'script',
    'run',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'functionName': functionName,
      'argsJson': argsJson,
    },
  );

  /// *Run on server* with live logs (09 §14.5): JSON events, first
  /// `{"log": {t, level, msg}}` per log line while the function runs, then
  /// `{"result": ScriptRunResponse}`.
  _ida.Stream<String> runLive(
    _isc.UuidValue spreadsheetUuid,
    String functionName,
    String? argsJson,
  ) => caller.callStreamingServerEndpoint<_ida.Stream<String>, String>(
    'script',
    'runLive',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'functionName': functionName,
      'argsJson': argsJson,
    },
    {},
  );

  /// The executions log, newest first (09 §13.3).
  _ida.Future<List<_ijdpewvc.ScriptExecution>> executions(
    _isc.UuidValue spreadsheetUuid, {
    String? functionName,
    _isizzyyw.ScriptExecutionStatus? status,
    DateTime? before,
    required int limit,
  }) => caller.callServerEndpoint<List<_ijdpewvc.ScriptExecution>>(
    'script',
    'executions',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'functionName': functionName,
      'status': status,
      'before': before,
      'limit': limit,
    },
  );

  /// Uploads client executions (batched, 09 §13.1).
  _ida.Future<int> reportExecutions(
    _isc.UuidValue spreadsheetUuid,
    List<_ijdpewvc.ScriptExecution> executions,
  ) => caller.callServerEndpoint<int>(
    'script',
    'reportExecutions',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'executions': executions,
    },
  );

  /// `UrlFetchApp` of client executions (09 §8.3): [requestJson] is a
  /// `FetchRequestData` JSON object.
  _ida.Future<_iyfk9f1k.ScriptFetchResponse> urlFetch(
    _isc.UuidValue spreadsheetUuid,
    String requestJson, {
    required bool customFunction,
  }) => caller.callServerEndpoint<_iyfk9f1k.ScriptFetchResponse>(
    'script',
    'urlFetch',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'requestJson': requestJson,
      'customFunction': customFunction,
    },
  );

  /// The caller's granted scopes.
  _ida.Future<_i7q8cl7e.ScriptAuthorizationView> authorization(
    _isc.UuidValue spreadsheetUuid,
  ) => caller.callServerEndpoint<_i7q8cl7e.ScriptAuthorizationView>(
    'script',
    'authorization',
    {'spreadsheetUuid': spreadsheetUuid},
  );

  /// The authorization dialog's *Allow* (09 §11.2).
  _ida.Future<_i7q8cl7e.ScriptAuthorizationView> authorize(
    _isc.UuidValue spreadsheetUuid,
    List<String> scopes,
  ) => caller.callServerEndpoint<_i7q8cl7e.ScriptAuthorizationView>(
    'script',
    'authorize',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'scopes': scopes,
    },
  );

  /// *Revoke my authorization* (09 §11.2).
  _ida.Future<void> revokeAuthorization(_isc.UuidValue spreadsheetUuid) =>
      caller.callServerEndpoint<void>(
        'script',
        'revokeAuthorization',
        {'spreadsheetUuid': spreadsheetUuid},
      );

  /// The app opened the spreadsheet online: runs installable onOpen
  /// triggers (09 §8.7.3). Returns the number of runs.
  ///
  /// Opens beyond [openLimiter] (per user and spreadsheet) and
  /// [openLimiterAll] (per spreadsheet, all users) run nothing and return
  /// 0: the triggers run with their installer's authorization and quota.
  _ida.Future<int> notifyOpen(_isc.UuidValue spreadsheetUuid) =>
      caller.callServerEndpoint<int>(
        'script',
        'notifyOpen',
        {'spreadsheetUuid': spreadsheetUuid},
      );
}

/// Sheets extensions of version history (Sheets 10 §5.2, §5.4): changed
/// ranges with authors, the server-side diff of big versions, and the
/// comments/sharing options of *Make a copy* from a version.
/// {@category Endpoint}
class EndpointSheetsVersion extends _isc.EndpointRef {
  EndpointSheetsVersion(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sheetsVersion';

  /// `changedRangesJson` of a version (`{v, approx, ranges: [{s, r1, c1,
  /// r2, c2, u}]}`, oldest first; `u` = user id of the author). Versions
  /// captured before the index existed are computed on the fly.
  _ida.Future<String> changes(
    _isc.UuidValue itemUuid,
    int versionId,
  ) => caller.callServerEndpoint<String>(
    'sheetsVersion',
    'changes',
    {
      'itemUuid': itemUuid,
      'versionId': versionId,
    },
  );

  /// The diff of [versionId] against [previousVersionId] (default: the
  /// version before it) computed on the server for versions too big for the
  /// client (Sheets 10 §5.2 step 4), with the author of every changed cell.
  /// Cached as `<versionId>.diff.gz`; returns its signed URL (gzip JSON
  /// `{diff: SnapshotDiff JSON, a: [author user ids, 0 = unknown]}`).
  _ida.Future<_i4i1hokq.FileUrlView> diff(
    _isc.UuidValue itemUuid,
    int versionId,
    int? previousVersionId,
  ) => caller.callServerEndpoint<_i4i1hokq.FileUrlView>(
    'sheetsVersion',
    'diff',
    {
      'itemUuid': itemUuid,
      'versionId': versionId,
      'previousVersionId': previousVersionId,
    },
  );

  /// The *Copy comments* / *Share with the same people* options of a copy
  /// made on the client from a version (Sheets 10 §5.4): copies the
  /// comment threads of [sourceItemUuid] to [targetItemUuid] with anchors
  /// remapped through [anchorIdMapJson] (`{oldId: newId}`), and the source's
  /// sharing. The caller must own the target and be able to copy the source.
  _ida.Future<void> copyExtras(
    _isc.UuidValue sourceItemUuid,
    _isc.UuidValue targetItemUuid,
    String anchorIdMapJson,
    bool copyComments,
    bool copySharing,
  ) => caller.callServerEndpoint<void>(
    'sheetsVersion',
    'copyExtras',
    {
      'sourceItemUuid': sourceItemUuid,
      'targetItemUuid': targetItemUuid,
      'anchorIdMapJson': anchorIdMapJson,
      'copyComments': copyComments,
      'copySharing': copySharing,
    },
  );
}

/// The AI features of Wonky Slides (Slides 11 §6–§9): *Generate
/// presentation* (outline, then build), *Rewrite text*, speaker notes, alt
/// text, the design-ideas ranking and the AI changes preview of
/// Suggest-mode assistant runs. The assistant panel itself uses
/// `assistant.chat` with the presentation's item uuid and the `slides*`
/// fields of [AssistantContextHints].
/// {@category Endpoint}
class EndpointSlidesAi extends _isc.EndpointRef {
  EndpointSlidesAi(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'slidesAi';

  /// Step 1 of *Generate presentation*: streams progress; `done.markdown`
  /// is the outline JSON. [itemUuid] = the open deck (insert) or null (a
  /// new presentation).
  _ida.Stream<_ivbb4qsj.InlineAiEvent> proposeOutline(
    _isc.UuidValue? itemUuid,
    _itf4l8jm.SlidesAiOutlineRequest request,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ivbb4qsj.InlineAiEvent>,
        _ivbb4qsj.InlineAiEvent
      >(
        'slidesAi',
        'proposeOutline',
        {
          'itemUuid': itemUuid,
          'request': request,
        },
        {},
      );

  /// Step 2: builds [outlineJson] into a new presentation ([itemUuid]
  /// null) or into the deck after [afterSlideId] (one undo step).
  _ida.Future<_i6mf4awd.SlidesAiBuildResult> buildDeck(
    _isc.UuidValue? itemUuid,
    String outlineJson,
    String? afterSlideId,
    bool notes,
    bool groups,
    _isc.UuidValue? parentUuid,
  ) => caller.callServerEndpoint<_i6mf4awd.SlidesAiBuildResult>(
    'slidesAi',
    'buildDeck',
    {
      'itemUuid': itemUuid,
      'outlineJson': outlineJson,
      'afterSlideId': afterSlideId,
      'notes': notes,
      'groups': groups,
      'parentUuid': parentUuid,
    },
  );

  /// *Rewrite text*: streams the rewritten Markdown (nothing is written).
  _ida.Stream<_ivbb4qsj.InlineAiEvent> rewrite(
    _isc.UuidValue itemUuid,
    _ixhdkbka.SlidesAiRewriteRequest request,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ivbb4qsj.InlineAiEvent>,
        _ivbb4qsj.InlineAiEvent
      >(
        'slidesAi',
        'rewrite',
        {
          'itemUuid': itemUuid,
          'request': request,
        },
        {},
      );

  /// Speaker-notes proposals for [slideIds] (empty = all slides).
  _ida.Future<List<_iascr37x.SlidesAiNote>> writeNotes(
    _isc.UuidValue itemUuid,
    List<String> slideIds,
    String length,
    String style,
    String mode,
  ) => caller.callServerEndpoint<List<_iascr37x.SlidesAiNote>>(
    'slidesAi',
    'writeNotes',
    {
      'itemUuid': itemUuid,
      'slideIds': slideIds,
      'length': length,
      'style': style,
      'mode': mode,
    },
  );

  /// Alt-text proposals for [elementIds] (empty = every element missing
  /// alt text).
  _ida.Future<List<_iqd8jbjp.SlidesAiAltText>> describeElements(
    _isc.UuidValue itemUuid,
    List<String> elementIds,
  ) => caller.callServerEndpoint<List<_iqd8jbjp.SlidesAiAltText>>(
    'slidesAi',
    'describeElements',
    {
      'itemUuid': itemUuid,
      'elementIds': elementIds,
    },
  );

  /// Scores of the design-idea [candidates] (`id: description`) of
  /// [slideId].
  _ida.Future<List<_ifavqmyp.SlidesAiDesignRank>> rankDesigns(
    _isc.UuidValue itemUuid,
    String slideId,
    List<String> candidates,
  ) => caller.callServerEndpoint<List<_ifavqmyp.SlidesAiDesignRank>>(
    'slidesAi',
    'rankDesigns',
    {
      'itemUuid': itemUuid,
      'slideId': slideId,
      'candidates': candidates,
    },
  );

  /// The AI changes preview of a Suggest-mode run.
  _ida.Future<_iqp3429j.SlidesAiPreview> getPreview(String previewId) =>
      caller.callServerEndpoint<_iqp3429j.SlidesAiPreview>(
        'slidesAi',
        'getPreview',
        {'previewId': previewId},
      );

  /// Applies the checked calls (null = all) as one undo step.
  _ida.Future<_ilgy0ds2.SlidesAiApplyResult> applyPreview(
    String previewId,
    List<String>? callIds,
  ) => caller.callServerEndpoint<_ilgy0ds2.SlidesAiApplyResult>(
    'slidesAi',
    'applyPreview',
    {
      'previewId': previewId,
      'callIds': callIds,
    },
  );

  /// Discards a preview.
  _ida.Future<void> discardPreview(String previewId) =>
      caller.callServerEndpoint<void>(
        'slidesAi',
        'discardPreview',
        {'previewId': previewId},
      );
}

/// Linked charts from Wonky Sheets in Wonky Slides (Slides 08 §13, `slidesCharts`):
/// the insert dialog's chart list, snapshot resolution for insert/*Update*, and link status
/// checks. Access and errors: [SlidesChartService].
/// {@category Endpoint}
class EndpointSlidesCharts extends _isc.EndpointRef {
  EndpointSlidesCharts(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'slidesCharts';

  /// The charts of spreadsheet [spreadsheetUuid] (drive item uuid) with ≤ 200-point
  /// previews. Viewer+. Errors: notFound (`no_access`, `spreadsheet_trashed`),
  /// limitExceeded.
  _ida.Future<_izwvek44.ChartSourceList> listCharts(
    _isc.UuidValue spreadsheetUuid,
  ) => caller.callServerEndpoint<_izwvek44.ChartSourceList>(
    'slidesCharts',
    'listCharts',
    {'spreadsheetUuid': spreadsheetUuid},
  );

  /// The snapshot of chart [chartObjectId] of [spreadsheetUuid]. Viewer+ with the right to
  /// copy data. Errors: notFound (`no_access`, `spreadsheet_trashed`, `chart_not_found`),
  /// forbidden (`export_disabled`), invalidArgument (`unsupported_spec`), tooLarge
  /// (`chart_too_large`), limitExceeded.
  _ida.Future<_iwoaz8tz.ChartSnapshotView> resolveSnapshot(
    _isc.UuidValue spreadsheetUuid,
    String chartObjectId,
  ) => caller.callServerEndpoint<_iwoaz8tz.ChartSnapshotView>(
    'slidesCharts',
    'resolveSnapshot',
    {
      'spreadsheetUuid': spreadsheetUuid,
      'chartObjectId': chartObjectId,
    },
  );

  /// The status of each of ≤ 50 linked charts, in order (08 §5.2).
  _ida.Future<List<_idvbn12y.ChartLinkStatus>> checkLinks(
    List<_ipgr9tcd.ChartLinkProbe> probes,
  ) => caller.callServerEndpoint<List<_idvbn12y.ChartLinkStatus>>(
    'slidesCharts',
    'checkLinks',
    {'probes': probes},
  );
}

/// Deck sessions over RevLog (RevLog spec 04 §1, 08): `slidesDoc.*`.
/// {@category Endpoint}
class EndpointSlidesDoc extends _isc.EndpointRef {
  EndpointSlidesDoc(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'slidesDoc';

  /// Opens an editing/viewing session (04 §2).
  _ida.Stream<_ibic7sfk.RevServerMessage> connect(
    _isc.UuidValue fileUuid,
    int knownRevision,
    String tabId,
    _ida.Stream<_iedvhh7l.RevClientMessage> input,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ibic7sfk.RevServerMessage>,
        _ibic7sfk.RevServerMessage
      >(
        'slidesDoc',
        'connect',
        {
          'fileUuid': fileUuid,
          'knownRevision': knownRevision,
          'tabId': tabId,
        },
        {'input': input},
      );

  /// A bootstrap page (04 §3). Viewer+.
  _ida.Future<_ivzrugmo.RevPage> page(
    _isc.UuidValue fileUuid,
    _isw8g0pp.RevPageRequest request,
  ) => caller.callServerEndpoint<_ivzrugmo.RevPage>(
    'slidesDoc',
    'page',
    {
      'fileUuid': fileUuid,
      'request': request,
    },
  );

  /// Ops in (fromRevision, toRevision] (04 §1, 05 §11).
  _ida.Future<List<_iq15rk0l.RevOpView>> ops(
    _isc.UuidValue fileUuid,
    int fromRevision,
    int toRevision,
  ) => caller.callServerEndpoint<List<_iq15rk0l.RevOpView>>(
    'slidesDoc',
    'ops',
    {
      'fileUuid': fileUuid,
      'fromRevision': fromRevision,
      'toRevision': toRevision,
    },
  );

  /// Head revision, role and stats. Viewer+.
  _ida.Future<_ipiq4i7g.RevFileInfo> info(_isc.UuidValue fileUuid) =>
      caller.callServerEndpoint<_ipiq4i7g.RevFileInfo>(
        'slidesDoc',
        'info',
        {'fileUuid': fileUuid},
      );
}

/// Online-only Slides operations (Slides 02 §9): undo and redo of server
/// changes. Deck sessions are `slidesDoc.*` (RevLog spec 04 §1).
/// {@category Endpoint}
class EndpointSlides extends _isc.EndpointRef {
  EndpointSlides(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'slides';

  /// Undo of a server-side change (`slides.serverChange`: MCP, AI,
  /// restores): reverts the recorded ops with the per-column skip rule
  /// (columns others changed since stay; coupled columns stay together).
  /// Editor+.
  _ida.Future<_i107v8u3.RevertResult> revertChange(_isc.UuidValue changeId) =>
      caller.callServerEndpoint<_i107v8u3.RevertResult>(
        'slides',
        'revertChange',
        {'changeId': changeId},
      );

  /// Redo of a reverted server-side change ([changeId] of the original or
  /// of its revert).
  _ida.Future<_i107v8u3.RevertResult> reapplyChange(_isc.UuidValue changeId) =>
      caller.callServerEndpoint<_i107v8u3.RevertResult>(
        'slides',
        'reapplyChange',
        {'changeId': changeId},
      );
}

/// Server-side Slides exports (Slides 10 §11.5, `slidesExport`): the same
/// shape as Write's `writeExport`. Formats: `pdf` (`png`/`pngZip` are P1).
/// [optionsJson] holds the `SlidesPdfOptions` of 10 §11.1; [revision]
/// (older versions) is P1.
/// {@category Endpoint}
class EndpointSlidesExport extends _isc.EndpointRef {
  EndpointSlidesExport(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'slidesExport';

  /// Exports deck [itemUuid]; the result is downloaded through its signed
  /// URL (15 min; the stored file expires after 24 h).
  _ida.Future<_ia6gray1.ExportResultView> export(
    _isc.UuidValue itemUuid,
    String format,
    String optionsJson,
    int? revision,
  ) => caller.callServerEndpoint<_ia6gray1.ExportResultView>(
    'slidesExport',
    'export',
    {
      'itemUuid': itemUuid,
      'format': format,
      'optionsJson': optionsJson,
      'revision': revision,
    },
  );

  /// Progress events (`loading`, `layout`, `fonts`, `images`, `packaging`,
  /// `uploading`); the last one is `done` or `error`. Cancel by closing.
  _ida.Stream<_i1vrysbd.ExportProgressEvent> exportWithProgress(
    _isc.UuidValue itemUuid,
    String format,
    String optionsJson,
    int? revision,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i1vrysbd.ExportProgressEvent>,
        _i1vrysbd.ExportProgressEvent
      >(
        'slidesExport',
        'exportWithProgress',
        {
          'itemUuid': itemUuid,
          'format': format,
          'optionsJson': optionsJson,
          'revision': revision,
        },
        {},
      );
}

/// The presentation session of Wonky Slides (Slides 10 §6, A-10-5): the
/// presenter view in this window drives the audience view on another
/// device or browser (v2 is single-window, v2 review Q5/Q29).
/// {@category Endpoint}
class EndpointPresentation extends _isc.EndpointRef {
  EndpointPresentation(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'presentation';

  /// Joins a session on [deckUuid] (a presenter without a session id
  /// creates one). The first event is a [PresentationWelcome], or a
  /// [PresentationEndedEvent] when the session can't be joined.
  _ida.Stream<_i693xhmf.PresentationEvent> join(
    _isc.UuidValue deckUuid,
    _ia63nl87.PresentationJoin join,
    _ida.Stream<_igyvhitp.PresentationUpdate> updates,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i693xhmf.PresentationEvent>,
        _i693xhmf.PresentationEvent
      >(
        'presentation',
        'join',
        {
          'deckUuid': deckUuid,
          'join': join,
        },
        {'updates': updates},
      );

  /// The caller's own live presenter session on [deckUuid], or null.
  _ida.Future<_iwz86pi3.PresentationSessionInfo?> findSession(
    _isc.UuidValue deckUuid,
  ) => caller.callServerEndpoint<_iwz86pi3.PresentationSessionInfo?>(
    'presentation',
    'findSession',
    {'deckUuid': deckUuid},
  );

  /// The remote route of a typed six-digit pairing [code] (Slides 10 §6.4,
  /// SL-41), or null when no presenter issued it (or it expired). Needs ≥
  /// viewer on the deck; rate-limited per user.
  _ida.Future<_i6lgd3j7.PresentationPairingTarget?> resolvePairingCode(
    String code,
  ) => caller.callServerEndpoint<_i6lgd3j7.PresentationPairingTarget?>(
    'presentation',
    'resolvePairingCode',
    {'code': code},
  );
}

/// *Import theme from a presentation…* (Slides 05 §9, SL-17,
/// `slidesThemes`): the themes of another deck the caller can view, so the
/// client can copy one into the open deck (`ImportTheme.themeEntry`).
/// {@category Endpoint}
class EndpointSlidesThemes extends _isc.EndpointRef {
  EndpointSlidesThemes(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'slidesThemes';

  /// The themes of presentation [itemUuid] (viewer+) as JSON:
  /// `{"v": 1, "sourceItemUuid", "defaultThemeId", "themes": [entry…]}`,
  /// each entry the theme's rows (`SlidesClipboardCodec.themeEntry`: the
  /// `deck_theme` columns plus `masters`, `layouts`, `elements`) with
  /// `usedBy` (slides using it). Errors: notFound, forbidden.
  _ida.Future<String> list(_isc.UuidValue itemUuid) =>
      caller.callServerEndpoint<String>(
        'slidesThemes',
        'list',
        {'itemUuid': itemUuid},
      );
}

/// Slides extensions of version history (Slides 09 §4.2, §4.5): who changed
/// what in a version (author attribution of the diff) and *Make a copy*
/// of a version. Editors+ (suite 07 §5).
/// {@category Endpoint}
class EndpointSlidesVersion extends _isc.EndpointRef {
  EndpointSlidesVersion(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'slidesVersion';

  /// The `SlidesVersionChanges` JSON of a version (`{v, slides: {id:
  /// [userIds]}, elements, groups, theme, deck, agents, approx}`; latest
  /// author last). Versions captured before the index existed are computed
  /// from the change log on the fly.
  _ida.Future<String> changes(
    _isc.UuidValue itemUuid,
    int versionId,
  ) => caller.callServerEndpoint<String>(
    'slidesVersion',
    'changes',
    {
      'itemUuid': itemUuid,
      'versionId': versionId,
    },
  );

  /// *Make a copy* of a version (09 §4.5): a new presentation with the
  /// version's content (new ids, uploaded images re-homed, the caller
  /// pays), in [folderUuid] (default: the deck's folder when the caller
  /// can edit it, else My Drive); optionally with the deck's comment
  /// threads (anchors remapped) and its sharing.
  _ida.Future<_iatsgjjq.DriveItemView> makeCopy(
    _isc.UuidValue itemUuid,
    int versionId,
    String name,
    _isc.UuidValue? folderUuid,
    bool copyComments,
    bool copySharing,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'slidesVersion',
    'makeCopy',
    {
      'itemUuid': itemUuid,
      'versionId': versionId,
      'name': name,
      'folderUuid': folderUuid,
      'copyComments': copyComments,
      'copySharing': copySharing,
    },
  );
}

/// Write documents: the OT editing stream and helpers (Write 03 §1).
/// {@category Endpoint}
class EndpointDocument extends _isc.EndpointRef {
  EndpointDocument(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'document';

  /// Opens an editing/viewing session. The first message is [DocInit] with
  /// the ops since [knownRevision] (0 = none) or a snapshot.
  _ida.Stream<_ir9iog55.DocServerMessage> connect(
    _isc.UuidValue documentUuid,
    int knownRevision,
    _ida.Stream<_isw33y8i.DocClientMessage> input,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ir9iog55.DocServerMessage>,
        _ir9iog55.DocServerMessage
      >(
        'document',
        'connect',
        {
          'documentUuid': documentUuid,
          'knownRevision': knownRevision,
        },
        {'input': input},
      );

  _ida.Future<_in30vxre.DocumentInfo> getInfo(_isc.UuidValue documentUuid) =>
      caller.callServerEndpoint<_in30vxre.DocumentInfo>(
        'document',
        'getInfo',
        {'documentUuid': documentUuid},
      );

  /// Ops in [fromRevision]…[toRevision] (at most 1,000).
  _ida.Future<List<_i8x9070n.DocumentOpView>> getOps(
    _isc.UuidValue documentUuid,
    int fromRevision,
    int toRevision,
  ) => caller.callServerEndpoint<List<_i8x9070n.DocumentOpView>>(
    'document',
    'getOps',
    {
      'documentUuid': documentUuid,
      'fromRevision': fromRevision,
      'toRevision': toRevision,
    },
  );

  /// Content at [revision] (head when null; older revisions need Editor+).
  _ida.Future<_i8beogda.DocumentSnapshotView> getSnapshot(
    _isc.UuidValue documentUuid,
    int? revision,
  ) => caller.callServerEndpoint<_i8beogda.DocumentSnapshotView>(
    'document',
    'getSnapshot',
    {
      'documentUuid': documentUuid,
      'revision': revision,
    },
  );

  /// LWW metadata change (themeId, pageSetup, language, frontMatter).
  _ida.Future<void> updateMeta(
    _isc.UuidValue documentUuid,
    _ih34yxbq.DocumentMetaPatch patch,
    _isc.UuidValue clientOpId,
  ) => caller.callServerEndpoint<void>(
    'document',
    'updateMeta',
    {
      'documentUuid': documentUuid,
      'patch': patch,
      'clientOpId': clientOpId,
    },
  );
}

/// Server-side Write exports and conversions (Write 07 §10). Formats use
/// MCP names: md, md_zip, pdf, html, html_zip, docx, odt, rtf, epub, txt.
/// {@category Endpoint}
class EndpointWriteExport extends _isc.EndpointRef {
  EndpointWriteExport(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'writeExport';

  _ida.Future<_ia6gray1.ExportResultView> export(
    _isc.UuidValue documentUuid,
    String format,
    String optionsJson,
    int? revision,
  ) => caller.callServerEndpoint<_ia6gray1.ExportResultView>(
    'writeExport',
    'export',
    {
      'documentUuid': documentUuid,
      'format': format,
      'optionsJson': optionsJson,
      'revision': revision,
    },
  );

  /// Progress events; the last one is `done` or `error`. Cancel by closing.
  _ida.Stream<_i1vrysbd.ExportProgressEvent> exportWithProgress(
    _isc.UuidValue documentUuid,
    String format,
    String optionsJson,
    int? revision,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i1vrysbd.ExportProgressEvent>,
        _i1vrysbd.ExportProgressEvent
      >(
        'writeExport',
        'exportWithProgress',
        {
          'documentUuid': documentUuid,
          'format': format,
          'optionsJson': optionsJson,
          'revision': revision,
        },
        {},
      );

  _ida.Future<_ia522en0.ConvertForInsertResult> convertForInsert(
    _isc.UuidValue uploadId,
    String format,
    String optionsJson,
  ) => caller.callServerEndpoint<_ia522en0.ConvertForInsertResult>(
    'writeExport',
    'convertForInsert',
    {
      'uploadId': uploadId,
      'format': format,
      'optionsJson': optionsJson,
    },
  );

  /// Image proxy for client exports (CORS-blocked remote images).
  _ida.Future<_idt.ByteData> fetchImage(
    _isc.UuidValue documentUuid,
    String src,
  ) => caller.callServerEndpoint<_idt.ByteData>(
    'writeExport',
    'fetchImage',
    {
      'documentUuid': documentUuid,
      'src': src,
    },
  );
}

/// Write version history (Write 08 §4.3). Editors+.
/// {@category Endpoint}
class EndpointWriteHistory extends _isc.EndpointRef {
  EndpointWriteHistory(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'writeHistory';

  _ida.Future<_igd4fcl2.WriteVersionDocument> getVersionDocument(
    _isc.UuidValue documentUuid,
    int revision,
  ) => caller.callServerEndpoint<_igd4fcl2.WriteVersionDocument>(
    'writeHistory',
    'getVersionDocument',
    {
      'documentUuid': documentUuid,
      'revision': revision,
    },
  );

  _ida.Future<_iohaffow.WriteDiffView> diff(
    _isc.UuidValue documentUuid,
    int fromRevision,
    int toRevision,
  ) => caller.callServerEndpoint<_iohaffow.WriteDiffView>(
    'writeHistory',
    'diff',
    {
      'documentUuid': documentUuid,
      'fromRevision': fromRevision,
      'toRevision': toRevision,
    },
  );

  _ida.Future<_itqtmykd.ItemVersionView> createRestorePoint(
    _isc.UuidValue documentUuid,
  ) => caller.callServerEndpoint<_itqtmykd.ItemVersionView>(
    'writeHistory',
    'createRestorePoint',
    {'documentUuid': documentUuid},
  );

  _ida.Future<_iyei7m5z.VersionRestoreResult> restore(
    _isc.UuidValue documentUuid,
    int versionId,
  ) => caller.callServerEndpoint<_iyei7m5z.VersionRestoreResult>(
    'writeHistory',
    'restore',
    {
      'documentUuid': documentUuid,
      'versionId': versionId,
    },
  );

  _ida.Future<_iatsgjjq.DriveItemView> copyVersion(
    _isc.UuidValue documentUuid,
    int versionId,
    String name,
    _isc.UuidValue? parentUuid,
  ) => caller.callServerEndpoint<_iatsgjjq.DriveItemView>(
    'writeHistory',
    'copyVersion',
    {
      'documentUuid': documentUuid,
      'versionId': versionId,
      'name': name,
      'parentUuid': parentUuid,
    },
  );
}

/// Write themes (Write 06 §5.5).
/// {@category Endpoint}
class EndpointWriteTheme extends _isc.EndpointRef {
  EndpointWriteTheme(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'writeTheme';

  _ida.Future<List<_i2zuh8f2.WriteThemeView>> listBuiltins() =>
      caller.callServerEndpoint<List<_i2zuh8f2.WriteThemeView>>(
        'writeTheme',
        'listBuiltins',
        {},
      );

  _ida.Future<List<_i2zuh8f2.WriteThemeView>> listMine() =>
      caller.callServerEndpoint<List<_i2zuh8f2.WriteThemeView>>(
        'writeTheme',
        'listMine',
        {},
      );

  _ida.Future<_i2zuh8f2.WriteThemeView> get(
    _isc.UuidValue uuid,
    _isc.UuidValue? viaDocumentUuid,
  ) => caller.callServerEndpoint<_i2zuh8f2.WriteThemeView>(
    'writeTheme',
    'get',
    {
      'uuid': uuid,
      'viaDocumentUuid': viaDocumentUuid,
    },
  );

  _ida.Future<List<_i2zuh8f2.WriteThemeView>> getMany(
    List<_isc.UuidValue> uuids,
    _isc.UuidValue? viaDocumentUuid,
  ) => caller.callServerEndpoint<List<_i2zuh8f2.WriteThemeView>>(
    'writeTheme',
    'getMany',
    {
      'uuids': uuids,
      'viaDocumentUuid': viaDocumentUuid,
    },
  );

  _ida.Future<_i2zuh8f2.WriteThemeView> create(
    String name,
    String json,
    _isc.UuidValue? basedOnUuid,
  ) => caller.callServerEndpoint<_i2zuh8f2.WriteThemeView>(
    'writeTheme',
    'create',
    {
      'name': name,
      'json': json,
      'basedOnUuid': basedOnUuid,
    },
  );

  /// Saves a theme; throws [ThemeConflictException] when [expectedVersion]
  /// is stale.
  _ida.Future<_i2zuh8f2.WriteThemeView> update(
    _isc.UuidValue uuid,
    String json,
    int expectedVersion,
  ) => caller.callServerEndpoint<_i2zuh8f2.WriteThemeView>(
    'writeTheme',
    'update',
    {
      'uuid': uuid,
      'json': json,
      'expectedVersion': expectedVersion,
    },
  );

  _ida.Future<_i2zuh8f2.WriteThemeView> rename(
    _isc.UuidValue uuid,
    String name,
    int expectedVersion,
  ) => caller.callServerEndpoint<_i2zuh8f2.WriteThemeView>(
    'writeTheme',
    'rename',
    {
      'uuid': uuid,
      'name': name,
      'expectedVersion': expectedVersion,
    },
  );

  /// Copies a built-in or readable theme into the caller's library.
  _ida.Future<_i2zuh8f2.WriteThemeView> duplicate(
    _isc.UuidValue uuid,
    String name,
    _isc.UuidValue? viaDocumentUuid,
  ) => caller.callServerEndpoint<_i2zuh8f2.WriteThemeView>(
    'writeTheme',
    'duplicate',
    {
      'uuid': uuid,
      'name': name,
      'viaDocumentUuid': viaDocumentUuid,
    },
  );

  _ida.Future<_i2zuh8f2.WriteThemeView> delete(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<_i2zuh8f2.WriteThemeView>(
        'writeTheme',
        'delete',
        {'uuid': uuid},
      );

  _ida.Future<_i2zuh8f2.WriteThemeView> restore(_isc.UuidValue uuid) =>
      caller.callServerEndpoint<_i2zuh8f2.WriteThemeView>(
        'writeTheme',
        'restore',
        {'uuid': uuid},
      );

  _ida.Future<List<_igytjuh5.WriteThemeRevisionView>> listRevisions(
    _isc.UuidValue uuid,
  ) => caller.callServerEndpoint<List<_igytjuh5.WriteThemeRevisionView>>(
    'writeTheme',
    'listRevisions',
    {'uuid': uuid},
  );

  _ida.Future<_igytjuh5.WriteThemeRevisionView> getRevision(
    _isc.UuidValue uuid,
    int version,
  ) => caller.callServerEndpoint<_igytjuh5.WriteThemeRevisionView>(
    'writeTheme',
    'getRevision',
    {
      'uuid': uuid,
      'version': version,
    },
  );

  /// Number of the caller's documents using the theme.
  _ida.Future<int> usage(_isc.UuidValue uuid) => caller.callServerEndpoint<int>(
    'writeTheme',
    'usage',
    {'uuid': uuid},
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    activity = EndpointActivity(this);
    assistant = EndpointAssistant(this);
    analytics = EndpointAnalytics(this);
    board = EndpointBoard(this);
    comment = EndpointComment(this);
    drive = EndpointDrive(this);
    e2eSupport = EndpointE2eSupport(this);
    feedback = EndpointFeedback(this);
    file = EndpointFile(this);
    uiBridge = EndpointUiBridge(this);
    meta = EndpointMeta(this);
    notification = EndpointNotification(this);
    presence = EndpointPresence(this);
    publication = EndpointPublication(this);
    submission = EndpointSubmission(this);
    sharing = EndpointSharing(this);
    accessToken = EndpointAccessToken(this);
    googleIdp = EndpointGoogleIdp(this);
    user = EndpointUser(this);
    version = EndpointVersion(this);
    sheetsAi = EndpointSheetsAi(this);
    sheetsDoc = EndpointSheetsDoc(this);
    sheets = EndpointSheets(this);
    sheetsImport = EndpointSheetsImport(this);
    script = EndpointScript(this);
    sheetsVersion = EndpointSheetsVersion(this);
    slidesAi = EndpointSlidesAi(this);
    slidesCharts = EndpointSlidesCharts(this);
    slidesDoc = EndpointSlidesDoc(this);
    slides = EndpointSlides(this);
    slidesExport = EndpointSlidesExport(this);
    presentation = EndpointPresentation(this);
    slidesThemes = EndpointSlidesThemes(this);
    slidesVersion = EndpointSlidesVersion(this);
    document = EndpointDocument(this);
    writeExport = EndpointWriteExport(this);
    writeHistory = EndpointWriteHistory(this);
    writeTheme = EndpointWriteTheme(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointActivity activity;

  late final EndpointAssistant assistant;

  late final EndpointAnalytics analytics;

  late final EndpointBoard board;

  late final EndpointComment comment;

  late final EndpointDrive drive;

  late final EndpointE2eSupport e2eSupport;

  late final EndpointFeedback feedback;

  late final EndpointFile file;

  late final EndpointUiBridge uiBridge;

  late final EndpointMeta meta;

  late final EndpointNotification notification;

  late final EndpointPresence presence;

  late final EndpointPublication publication;

  late final EndpointSubmission submission;

  late final EndpointSharing sharing;

  late final EndpointAccessToken accessToken;

  late final EndpointGoogleIdp googleIdp;

  late final EndpointUser user;

  late final EndpointVersion version;

  late final EndpointSheetsAi sheetsAi;

  late final EndpointSheetsDoc sheetsDoc;

  late final EndpointSheets sheets;

  late final EndpointSheetsImport sheetsImport;

  late final EndpointScript script;

  late final EndpointSheetsVersion sheetsVersion;

  late final EndpointSlidesAi slidesAi;

  late final EndpointSlidesCharts slidesCharts;

  late final EndpointSlidesDoc slidesDoc;

  late final EndpointSlides slides;

  late final EndpointSlidesExport slidesExport;

  late final EndpointPresentation presentation;

  late final EndpointSlidesThemes slidesThemes;

  late final EndpointSlidesVersion slidesVersion;

  late final EndpointDocument document;

  late final EndpointWriteExport writeExport;

  late final EndpointWriteHistory writeHistory;

  late final EndpointWriteTheme writeTheme;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'activity': activity,
    'assistant': assistant,
    'analytics': analytics,
    'board': board,
    'comment': comment,
    'drive': drive,
    'e2eSupport': e2eSupport,
    'feedback': feedback,
    'file': file,
    'uiBridge': uiBridge,
    'meta': meta,
    'notification': notification,
    'presence': presence,
    'publication': publication,
    'submission': submission,
    'sharing': sharing,
    'accessToken': accessToken,
    'googleIdp': googleIdp,
    'user': user,
    'version': version,
    'sheetsAi': sheetsAi,
    'sheetsDoc': sheetsDoc,
    'sheets': sheets,
    'sheetsImport': sheetsImport,
    'script': script,
    'sheetsVersion': sheetsVersion,
    'slidesAi': slidesAi,
    'slidesCharts': slidesCharts,
    'slidesDoc': slidesDoc,
    'slides': slides,
    'slidesExport': slidesExport,
    'presentation': presentation,
    'slidesThemes': slidesThemes,
    'slidesVersion': slidesVersion,
    'document': document,
    'writeExport': writeExport,
    'writeHistory': writeHistory,
    'writeTheme': writeTheme,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
