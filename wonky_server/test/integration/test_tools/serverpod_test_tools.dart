/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: no_leading_underscores_for_local_identifiers

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'dart:convert' as _idc;
import 'dart:io' as _idi;
import 'dart:typed_data' as _idt;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_test/serverpod_test.dart' as _ist;
import 'package:wonky_server/src/generated/future_calls.dart' as _iwslocjr;
import 'package:wonky_server/src/generated/future_calls_generated_models/acl_future_call_fan_out_model.dart'
    as _ievi2fyc;
import 'package:wonky_server/src/generated/future_calls_generated_models/board_future_call_summarize_model.dart'
    as _ied218dm;
import 'package:wonky_server/src/generated/future_calls_generated_models/board_future_call_triage_model.dart'
    as _ic65ofts;
import 'package:wonky_server/src/generated/future_calls_generated_models/board_future_call_write_prompt_model.dart'
    as _if4770sx;
import 'package:wonky_server/src/generated/future_calls_generated_models/board_github_future_call_handle_model.dart'
    as _it2ybdc3;
import 'package:wonky_server/src/generated/future_calls_generated_models/board_github_future_call_review_model.dart'
    as _iqologas;
import 'package:wonky_server/src/generated/future_calls_generated_models/file_preview_future_call_generate_model.dart'
    as _ikj8bo9l;
import 'package:wonky_server/src/generated/future_calls_generated_models/notification_email_future_call_send_model.dart'
    as _iuw2rc8h;
import 'package:wonky_server/src/generated/future_calls_generated_models/publications_future_call_deliver_model.dart'
    as _in0nsjwu;
import 'package:wonky_server/src/generated/future_calls_generated_models/storage_future_call_refresh_item_size_model.dart'
    as _i5g4dkd6;
import 'package:wonky_server/src/generated/platform/activity/activity_dashboard.dart'
    as _iwuvk2ka;
import 'package:wonky_server/src/generated/platform/activity/activity_event_view.dart'
    as _iiw0494r;
import 'package:wonky_server/src/generated/platform/ai/models/ai_provider.dart'
    as _i02m7u6n;
import 'package:wonky_server/src/generated/platform/ai/models/ai_quality.dart'
    as _idrzmvpg;
import 'package:wonky_server/src/generated/platform/ai/models/assistant_context_hints.dart'
    as _ixc2f7d5;
import 'package:wonky_server/src/generated/platform/ai/models/assistant_event.dart'
    as _ibgujsil;
import 'package:wonky_server/src/generated/platform/ai/models/assistant_status.dart'
    as _ibfulm5p;
import 'package:wonky_server/src/generated/platform/ai/models/assistant_thread_detail.dart'
    as _invizsga;
import 'package:wonky_server/src/generated/platform/ai/models/assistant_thread_view.dart'
    as _i1372x0g;
import 'package:wonky_server/src/generated/platform/ai/models/inline_ai_event.dart'
    as _iplizi6w;
import 'package:wonky_server/src/generated/platform/ai/models/inline_ai_request.dart'
    as _i4c3y8bm;
import 'package:wonky_server/src/generated/platform/ai/models/proofread_event.dart'
    as _ib6yu876;
import 'package:wonky_server/src/generated/platform/board/models/board_area.dart'
    as _i2y7swbd;
import 'package:wonky_server/src/generated/platform/board/models/board_bundle_suggestion_view.dart'
    as _i8qikgvy;
import 'package:wonky_server/src/generated/platform/board/models/board_comment_view.dart'
    as _ilh4w69x;
import 'package:wonky_server/src/generated/platform/board/models/board_counts.dart'
    as _imokftek;
import 'package:wonky_server/src/generated/platform/board/models/board_flag_reason.dart'
    as _i0z7k09i;
import 'package:wonky_server/src/generated/platform/board/models/board_list_query.dart'
    as _i6z8cjbe;
import 'package:wonky_server/src/generated/platform/board/models/board_me.dart'
    as _imb1vxwh;
import 'package:wonky_server/src/generated/platform/board/models/board_moderation_action.dart'
    as _iqqjetoq;
import 'package:wonky_server/src/generated/platform/board/models/board_post_draft.dart'
    as _i6ub5i5f;
import 'package:wonky_server/src/generated/platform/board/models/board_post_event.dart'
    as _igl1sayy;
import 'package:wonky_server/src/generated/platform/board/models/board_post_kind.dart'
    as _i5noao4s;
import 'package:wonky_server/src/generated/platform/board/models/board_post_page.dart'
    as _imlue0yd;
import 'package:wonky_server/src/generated/platform/board/models/board_post_view.dart'
    as _ir7e9zc6;
import 'package:wonky_server/src/generated/platform/board/models/board_review_counts.dart'
    as _iuafg5le;
import 'package:wonky_server/src/generated/platform/board/models/board_review_item.dart'
    as _id1usvpt;
import 'package:wonky_server/src/generated/platform/board/models/board_review_section.dart'
    as _i6ojypp7;
import 'package:wonky_server/src/generated/platform/board/models/board_similar_post.dart'
    as _iv1j9wri;
import 'package:wonky_server/src/generated/platform/board/models/board_size.dart'
    as _ikq67o57;
import 'package:wonky_server/src/generated/platform/board/models/board_task_page.dart'
    as _i84zsqgv;
import 'package:wonky_server/src/generated/platform/board/models/board_task_status.dart'
    as _ihypagkt;
import 'package:wonky_server/src/generated/platform/board/models/board_task_view.dart'
    as _ia65vc34;
import 'package:wonky_server/src/generated/platform/board/models/board_vote_result.dart'
    as _inylym64;
import 'package:wonky_server/src/generated/platform/comments/comment_anchor_kind.dart'
    as _i384cqmz;
import 'package:wonky_server/src/generated/platform/comments/comment_event.dart'
    as _i4nxgne2;
import 'package:wonky_server/src/generated/platform/comments/comment_filter.dart'
    as _i0f5nb76;
import 'package:wonky_server/src/generated/platform/comments/comment_thread_view.dart'
    as _ixzwh8hc;
import 'package:wonky_server/src/generated/platform/comments/comment_view.dart'
    as _ionqrnff;
import 'package:wonky_server/src/generated/platform/common/access_role.dart'
    as _i9nsco4y;
import 'package:wonky_server/src/generated/platform/drive/drive_change.dart'
    as _iypu9rxn;
import 'package:wonky_server/src/generated/platform/drive/drive_import_options.dart'
    as _iyihga8r;
import 'package:wonky_server/src/generated/platform/drive/drive_item_kind.dart'
    as _i0549mj7;
import 'package:wonky_server/src/generated/platform/drive/drive_item_view.dart'
    as _ily3pmy5;
import 'package:wonky_server/src/generated/platform/drive/drive_list_filter.dart'
    as _iaoi0gn5;
import 'package:wonky_server/src/generated/platform/drive/drive_list_page.dart'
    as _i2951hft;
import 'package:wonky_server/src/generated/platform/drive/drive_search_filters.dart'
    as _iub85lgd;
import 'package:wonky_server/src/generated/platform/drive/drive_sort.dart'
    as _il6plm80;
import 'package:wonky_server/src/generated/platform/drive/file_upload_progress.dart'
    as _idjmq8ha;
import 'package:wonky_server/src/generated/platform/drive/file_upload_request.dart'
    as _i6y6tdjl;
import 'package:wonky_server/src/generated/platform/drive/file_upload_start.dart'
    as _ibju74sj;
import 'package:wonky_server/src/generated/platform/drive/import_report_view.dart'
    as _imxcy17c;
import 'package:wonky_server/src/generated/platform/drive/storage_list_filter.dart'
    as _i7yliwmh;
import 'package:wonky_server/src/generated/platform/drive/storage_usage.dart'
    as _iui3jqzz;
import 'package:wonky_server/src/generated/platform/drive/template_category.dart'
    as _inlkiawi;
import 'package:wonky_server/src/generated/platform/drive/template_view.dart'
    as _ibinmr4r;
import 'package:wonky_server/src/generated/platform/feedback/feedback_submission.dart'
    as _ira9srbn;
import 'package:wonky_server/src/generated/platform/files/file_upload_ticket.dart'
    as _i3u7lvch;
import 'package:wonky_server/src/generated/platform/files/file_url_view.dart'
    as _i28n3m1r;
import 'package:wonky_server/src/generated/platform/files/stored_file_kind.dart'
    as _idhe6v6s;
import 'package:wonky_server/src/generated/platform/mcp/ui_bridge/ui_bridge_message.dart'
    as _is78z0de;
import 'package:wonky_server/src/generated/platform/meta/protocol_info.dart'
    as _ih1cymrz;
import 'package:wonky_server/src/generated/platform/notifications/notification_event.dart'
    as _iw7v7gz7;
import 'package:wonky_server/src/generated/platform/notifications/notification_page.dart'
    as _i2em4uch;
import 'package:wonky_server/src/generated/platform/presence/presence_event.dart'
    as _in8u6dfh;
import 'package:wonky_server/src/generated/platform/presence/presence_update.dart'
    as _ipd65of1;
import 'package:wonky_server/src/generated/platform/publications/models/publication_card.dart'
    as _iywwc4sf;
import 'package:wonky_server/src/generated/platform/publications/models/publication_check_result.dart'
    as _i1amkxf0;
import 'package:wonky_server/src/generated/platform/publications/models/publication_delivery_view.dart'
    as _idovycpn;
import 'package:wonky_server/src/generated/platform/publications/models/publication_input.dart'
    as _iy7hmxv3;
import 'package:wonky_server/src/generated/platform/publications/models/publication_secret.dart'
    as _i1thvjiu;
import 'package:wonky_server/src/generated/platform/publications/models/publication_settings.dart'
    as _i9ilkmgj;
import 'package:wonky_server/src/generated/platform/publications/models/submission_started.dart'
    as _ighe7owc;
import 'package:wonky_server/src/generated/platform/publications/models/submission_values.dart'
    as _iwukrrmj;
import 'package:wonky_server/src/generated/platform/publications/models/submission_view.dart'
    as _ij8gnfyr;
import 'package:wonky_server/src/generated/platform/revlog/messages/rev_client_message.dart'
    as _iv4mnr49;
import 'package:wonky_server/src/generated/platform/revlog/messages/rev_server_message.dart'
    as _ifa159qn;
import 'package:wonky_server/src/generated/platform/revlog/models/rev_file_info.dart'
    as _iwjfjan3;
import 'package:wonky_server/src/generated/platform/revlog/models/rev_op_view.dart'
    as _iu7aww0d;
import 'package:wonky_server/src/generated/platform/revlog/models/rev_page.dart'
    as _i4qoa0fo;
import 'package:wonky_server/src/generated/platform/revlog/models/rev_page_request.dart'
    as _iynxab9u;
import 'package:wonky_server/src/generated/platform/sharing/invite_resolution.dart'
    as _ir129i67;
import 'package:wonky_server/src/generated/platform/sharing/item_sharing_settings.dart'
    as _i55sl7s1;
import 'package:wonky_server/src/generated/platform/sharing/sharing_info.dart'
    as _ibhys9d2;
import 'package:wonky_server/src/generated/platform/users/access_token_view.dart'
    as _ioyb7a1p;
import 'package:wonky_server/src/generated/platform/users/account_deletion_preview.dart'
    as _ioq21a5l;
import 'package:wonky_server/src/generated/platform/users/created_access_token.dart'
    as _iutsxjwz;
import 'package:wonky_server/src/generated/platform/users/user_preferences.dart'
    as _istt8k6c;
import 'package:wonky_server/src/generated/platform/users/user_preferences_patch.dart'
    as _ingbfbma;
import 'package:wonky_server/src/generated/platform/users/user_profile_view.dart'
    as _ixfirwt7;
import 'package:wonky_server/src/generated/platform/users/user_summary.dart'
    as _i8uuoam6;
import 'package:wonky_server/src/generated/platform/versions/item_version_view.dart'
    as _ir2w0lzm;
import 'package:wonky_server/src/generated/platform/versions/version_restore_result.dart'
    as _i8hd56jb;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_ai_apply_result.dart'
    as _irr92qm3;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_ai_cell_request.dart'
    as _ifqit8uo;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_ai_cell_result.dart'
    as _iq57nmvp;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_ai_preview.dart'
    as _i5mk43di;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_fill_proposal.dart'
    as _i8mtoy9m;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_fill_row.dart'
    as _isuyxaqz;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_formula_suggestion.dart'
    as _idbu6x15;
import 'package:wonky_server/src/generated/sheets/imports/models/sheets_import_progress.dart'
    as _iatbq4i5;
import 'package:wonky_server/src/generated/sheets/models/cell_history_page.dart'
    as _ia7wiyaj;
import 'package:wonky_server/src/generated/sheets/models/revert_result.dart'
    as _iqq3mn94;
import 'package:wonky_server/src/generated/sheets/models/sheets_activity_summary.dart'
    as _in9s3hn0;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_authorization_view.dart'
    as _ix5njoik;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_compile_response.dart'
    as _ii26bewh;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_execution.dart'
    as _isf59hoo;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_execution_status.dart'
    as _icum4fx3;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_fetch_response.dart'
    as _i540ar91;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_run_response.dart'
    as _ijolphc0;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_alt_text.dart'
    as _iqoob7q4;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_apply_result.dart'
    as _iok1gsl7;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_build_result.dart'
    as _iyy431k4;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_design_rank.dart'
    as _ixtuoo5p;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_note.dart'
    as _iug1yx01;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_outline_request.dart'
    as _isfebja2;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_preview.dart'
    as _ipuzdgjy;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_rewrite_request.dart'
    as _ionqjjsu;
import 'package:wonky_server/src/generated/slides/charts/models/chart_link_probe.dart'
    as _izmhos0v;
import 'package:wonky_server/src/generated/slides/charts/models/chart_link_status.dart'
    as _imx2esrl;
import 'package:wonky_server/src/generated/slides/charts/models/chart_snapshot_view.dart'
    as _iapx01g6;
import 'package:wonky_server/src/generated/slides/charts/models/chart_source_list.dart'
    as _ippij8zo;
import 'package:wonky_server/src/generated/slides/present/models/presentation_event.dart'
    as _ieyo7nqv;
import 'package:wonky_server/src/generated/slides/present/models/presentation_join.dart'
    as _ieucpeca;
import 'package:wonky_server/src/generated/slides/present/models/presentation_pairing_target.dart'
    as _ienppxeb;
import 'package:wonky_server/src/generated/slides/present/models/presentation_session_info.dart'
    as _i3wfcxhm;
import 'package:wonky_server/src/generated/slides/present/models/presentation_update.dart'
    as _i0rcw8q1;
import 'package:wonky_server/src/generated/write/messages/doc_client_message.dart'
    as _i64vpekp;
import 'package:wonky_server/src/generated/write/messages/doc_server_message.dart'
    as _ih1nh1nq;
import 'package:wonky_server/src/generated/write/models/convert_for_insert_result.dart'
    as _i3qt51xn;
import 'package:wonky_server/src/generated/write/models/document_info.dart'
    as _ieznlrqc;
import 'package:wonky_server/src/generated/write/models/document_meta_patch.dart'
    as _issank2j;
import 'package:wonky_server/src/generated/write/models/document_op_view.dart'
    as _icjb0pei;
import 'package:wonky_server/src/generated/write/models/document_snapshot_view.dart'
    as _icrmohm9;
import 'package:wonky_server/src/generated/write/models/export_progress_event.dart'
    as _iqisbum6;
import 'package:wonky_server/src/generated/write/models/export_result_view.dart'
    as _ilqg61i8;
import 'package:wonky_server/src/generated/write/models/write_diff_view.dart'
    as _id5ij7u1;
import 'package:wonky_server/src/generated/write/models/write_theme_revision_view.dart'
    as _iu3gmhy1;
import 'package:wonky_server/src/generated/write/models/write_theme_view.dart'
    as _ipbzt39t;
import 'package:wonky_server/src/generated/write/models/write_version_document.dart'
    as _i2bmzm01;
import 'package:wonky_server/src/generated/protocol.dart';
import 'package:wonky_server/src/generated/endpoints.dart';
export 'package:serverpod_test/serverpod_test_public_exports.dart';

/// Creates a new test group that takes a callback that can be used to write tests.
/// The callback has two parameters: `sessionBuilder` and `endpoints`.
/// `sessionBuilder` is used to build a `Session` object that represents the server state during an endpoint call and is used to set up scenarios.
/// `endpoints` contains all your Serverpod endpoints and lets you call them:
/// ```dart
/// withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
///   test('when calling `hello` then should return greeting', () async {
///     final greeting = await endpoints.example.hello(sessionBuilder, 'Michael');
///     expect(greeting, 'Hello Michael');
///   });
/// });
/// ```
///
/// **Configuration options**
///
/// [applyMigrations] Whether pending migrations should be applied when starting Serverpod. Defaults to `true`
///
/// [enableSessionLogging] Whether session logging should be enabled. Defaults to `false`
///
/// [ephemeralDatabase] Whether this group gets its own empty database, created when the group starts and dropped when it finishes. Defaults to `true`.
/// Set this to `false` to use the database configured for [runMode], including a previously seeded database. [configOverride] can still replace that database. The configured database is not created or dropped, so groups that share it cannot run in parallel. [rollbackDatabase] still controls whether writes inside the group are rolled back.
///
/// [rollbackDatabase] Options for when to rollback the database during the test lifecycle.
/// By default `withServerpod` does all database operations inside a transaction that is rolled back after each `test` case.
/// Just like the following enum describes, the behavior of the automatic rollbacks can be configured:
/// ```dart
/// /// Options for when to rollback the database during the test lifecycle.
/// enum RollbackDatabase {
///   /// After each test. This is the default.
///   afterEach,
///
///   /// After all tests.
///   afterAll,
///
///   /// Disable rolling back the database.
///   disabled,
/// }
/// ```
///
/// [runMode] The run mode that Serverpod should be running in. Defaults to `test`.
///
/// [serverpodLoggingMode] The logging mode used when creating Serverpod. Defaults to `ServerpodLoggingMode.normal`
///
/// [serverpodStartTimeout] The timeout to use when starting Serverpod, which connects to the database among other things. Defaults to `Duration(seconds: 120)`.
///
/// [testServerOutputMode] Options for controlling test server output during test execution. Defaults to `TestServerOutputMode.normal`.
/// ```dart
/// /// Options for controlling test server output during test execution.
/// enum TestServerOutputMode {
///   /// Default mode - only stderr is printed (stdout suppressed).
///   /// This hides normal startup/shutdown logs while preserving error messages.
///   normal,
///
///   /// All logging - both stdout and stderr are printed.
///   /// Useful for debugging when you need to see all server output.
///   verbose,
///
///   /// No logging - both stdout and stderr are suppressed.
///   /// Completely silent mode, useful when you don't want any server output.
///   silent,
/// }
/// ```
///
/// [configOverride] A function to override the server configuration. This function is called with
/// the default server configuration after it is loaded from the config/ directory
/// and before it is used to start the server. Use this to override particular
/// settings in the server configuration.
///
/// [databaseInterceptor] Optional interceptor that replaces the default database for each session.
/// See [Serverpod.databaseInterceptor] for more information.
///
/// [testGroupTagsOverride] By default Serverpod test tools tags the `withServerpod` test group with `"integration"`.
/// This is to provide a simple way to only run unit or integration tests.
/// This property allows this tag to be overridden to something else. Defaults to `['integration']`.
///
/// [experimentalFeatures] Optionally specify experimental features. See [Serverpod] for more information.
///
/// [serverDirectory] The server package directory `config/<runMode>.yaml`, `config/passwords.yaml`,
/// and `migrations/<module>/...` are resolved against. Defaults to
/// [Directory.current] at the time the test boots. Pass this when the test
/// isolate's cwd is not the server package root (e.g. running tests from a
/// workspace parent directory) so config and migrations are still loaded
/// from the right place.
@_ist.isTestGroup
void withServerpod(
  String testGroupName,
  _ist.TestClosure<TestEndpoints> testClosure, {
  bool? applyMigrations,
  _is.ServerpodConfig Function(_is.ServerpodConfig)? configOverride,
  _is.DatabaseInterceptor? databaseInterceptor,
  bool? enableSessionLogging,
  bool? ephemeralDatabase,
  _is.ExperimentalFeatures? experimentalFeatures,
  _ist.RollbackDatabase? rollbackDatabase,
  String? runMode,
  _is.RuntimeParametersListBuilder? runtimeParametersBuilder,
  _idi.Directory? serverDirectory,
  _is.ServerpodLoggingMode? serverpodLoggingMode,
  Duration? serverpodStartTimeout,
  List<String>? testGroupTagsOverride,
  _ist.TestServerOutputMode? testServerOutputMode,
}) {
  _ist.buildWithServerpod<_InternalTestEndpoints>(
    testGroupName,
    _ist.TestServerpod(
      testEndpoints: _InternalTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: runMode,
      applyMigrations: applyMigrations,
      ephemeralDatabase: ephemeralDatabase,
      isDatabaseEnabled: true,
      serverpodLoggingMode: serverpodLoggingMode,
      testServerOutputMode: testServerOutputMode,
      serverDirectory: serverDirectory,
      experimentalFeatures: experimentalFeatures,
      configOverride: configOverride,
      runtimeParametersBuilder: runtimeParametersBuilder,
      databaseInterceptor: databaseInterceptor,
    ),
    maybeRollbackDatabase: rollbackDatabase,
    maybeEnableSessionLogging: enableSessionLogging,
    maybeTestGroupTagsOverride: testGroupTagsOverride,
    maybeServerpodStartTimeout: serverpodStartTimeout,
    maybeTestServerOutputMode: testServerOutputMode,
  )(testClosure);
}

class TestEndpoints {
  late final futureCalls = _FutureCalls();

  late final _EmailIdpEndpoint emailIdp;

  late final _JwtRefreshEndpoint jwtRefresh;

  late final _ActivityEndpoint activity;

  late final _AssistantEndpoint assistant;

  late final _BoardEndpoint board;

  late final _CommentEndpoint comment;

  late final _DriveEndpoint drive;

  late final _E2eSupportEndpoint e2eSupport;

  late final _FeedbackEndpoint feedback;

  late final _FileEndpoint file;

  late final _UiBridgeEndpoint uiBridge;

  late final _MetaEndpoint meta;

  late final _NotificationEndpoint notification;

  late final _PresenceEndpoint presence;

  late final _PublicationEndpoint publication;

  late final _SubmissionEndpoint submission;

  late final _SharingEndpoint sharing;

  late final _AccessTokenEndpoint accessToken;

  late final _GoogleIdpEndpoint googleIdp;

  late final _UserEndpoint user;

  late final _VersionEndpoint version;

  late final _SheetsAiEndpoint sheetsAi;

  late final _SheetsDocEndpoint sheetsDoc;

  late final _SheetsEndpoint sheets;

  late final _SheetsImportEndpoint sheetsImport;

  late final _ScriptEndpoint script;

  late final _SheetsVersionEndpoint sheetsVersion;

  late final _SlidesAiEndpoint slidesAi;

  late final _SlidesChartsEndpoint slidesCharts;

  late final _SlidesDocEndpoint slidesDoc;

  late final _SlidesEndpoint slides;

  late final _SlidesExportEndpoint slidesExport;

  late final _PresentationEndpoint presentation;

  late final _SlidesThemesEndpoint slidesThemes;

  late final _SlidesVersionEndpoint slidesVersion;

  late final _DocumentEndpoint document;

  late final _WriteExportEndpoint writeExport;

  late final _WriteHistoryEndpoint writeHistory;

  late final _WriteThemeEndpoint writeTheme;
}

class _InternalTestEndpoints extends TestEndpoints
    implements _ist.InternalTestEndpoints {
  @override
  void initialize(
    _is.SerializationManager serializationManager,
    _is.EndpointDispatch endpoints,
  ) {
    emailIdp = _EmailIdpEndpoint(
      endpoints,
      serializationManager,
    );
    jwtRefresh = _JwtRefreshEndpoint(
      endpoints,
      serializationManager,
    );
    activity = _ActivityEndpoint(
      endpoints,
      serializationManager,
    );
    assistant = _AssistantEndpoint(
      endpoints,
      serializationManager,
    );
    board = _BoardEndpoint(
      endpoints,
      serializationManager,
    );
    comment = _CommentEndpoint(
      endpoints,
      serializationManager,
    );
    drive = _DriveEndpoint(
      endpoints,
      serializationManager,
    );
    e2eSupport = _E2eSupportEndpoint(
      endpoints,
      serializationManager,
    );
    feedback = _FeedbackEndpoint(
      endpoints,
      serializationManager,
    );
    file = _FileEndpoint(
      endpoints,
      serializationManager,
    );
    uiBridge = _UiBridgeEndpoint(
      endpoints,
      serializationManager,
    );
    meta = _MetaEndpoint(
      endpoints,
      serializationManager,
    );
    notification = _NotificationEndpoint(
      endpoints,
      serializationManager,
    );
    presence = _PresenceEndpoint(
      endpoints,
      serializationManager,
    );
    publication = _PublicationEndpoint(
      endpoints,
      serializationManager,
    );
    submission = _SubmissionEndpoint(
      endpoints,
      serializationManager,
    );
    sharing = _SharingEndpoint(
      endpoints,
      serializationManager,
    );
    accessToken = _AccessTokenEndpoint(
      endpoints,
      serializationManager,
    );
    googleIdp = _GoogleIdpEndpoint(
      endpoints,
      serializationManager,
    );
    user = _UserEndpoint(
      endpoints,
      serializationManager,
    );
    version = _VersionEndpoint(
      endpoints,
      serializationManager,
    );
    sheetsAi = _SheetsAiEndpoint(
      endpoints,
      serializationManager,
    );
    sheetsDoc = _SheetsDocEndpoint(
      endpoints,
      serializationManager,
    );
    sheets = _SheetsEndpoint(
      endpoints,
      serializationManager,
    );
    sheetsImport = _SheetsImportEndpoint(
      endpoints,
      serializationManager,
    );
    script = _ScriptEndpoint(
      endpoints,
      serializationManager,
    );
    sheetsVersion = _SheetsVersionEndpoint(
      endpoints,
      serializationManager,
    );
    slidesAi = _SlidesAiEndpoint(
      endpoints,
      serializationManager,
    );
    slidesCharts = _SlidesChartsEndpoint(
      endpoints,
      serializationManager,
    );
    slidesDoc = _SlidesDocEndpoint(
      endpoints,
      serializationManager,
    );
    slides = _SlidesEndpoint(
      endpoints,
      serializationManager,
    );
    slidesExport = _SlidesExportEndpoint(
      endpoints,
      serializationManager,
    );
    presentation = _PresentationEndpoint(
      endpoints,
      serializationManager,
    );
    slidesThemes = _SlidesThemesEndpoint(
      endpoints,
      serializationManager,
    );
    slidesVersion = _SlidesVersionEndpoint(
      endpoints,
      serializationManager,
    );
    document = _DocumentEndpoint(
      endpoints,
      serializationManager,
    );
    writeExport = _WriteExportEndpoint(
      endpoints,
      serializationManager,
    );
    writeHistory = _WriteHistoryEndpoint(
      endpoints,
      serializationManager,
    );
    writeTheme = _WriteThemeEndpoint(
      endpoints,
      serializationManager,
    );
  }
}

class _FutureCalls {
  late final board = _BoardFutureCall();

  late final boardGithub = _BoardGithubFutureCall();

  late final filePreview = _FilePreviewFutureCall();

  late final maintenance = _MaintenanceFutureCall();

  late final notificationEmail = _NotificationEmailFutureCall();

  late final publications = _PublicationsFutureCall();

  late final acl = _AclFutureCall();

  late final storage = _StorageFutureCall();

  late final scriptScheduler = _ScriptSchedulerFutureCall();
}

class _EmailIdpEndpoint {
  _EmailIdpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> login(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
    required String password,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'login',
          parameters: _ist.testObjectToJson({
            'email': email,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_is.UuidValue> startRegistration(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startRegistration',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_is.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> verifyRegistrationCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue accountRequestId,
    required String verificationCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyRegistrationCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyRegistrationCode',
          parameters: _ist.testObjectToJson({
            'accountRequestId': accountRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iacs.AuthSuccess> finishRegistration(
    _ist.TestSessionBuilder sessionBuilder, {
    required String registrationToken,
    required String password,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishRegistration',
          parameters: _ist.testObjectToJson({
            'registrationToken': registrationToken,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_is.UuidValue> startPasswordReset(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startPasswordReset',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_is.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> verifyPasswordResetCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyPasswordResetCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyPasswordResetCode',
          parameters: _ist.testObjectToJson({
            'passwordResetRequestId': passwordResetRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> finishPasswordReset(
    _ist.TestSessionBuilder sessionBuilder, {
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishPasswordReset',
          parameters: _ist.testObjectToJson({
            'finishPasswordResetToken': finishPasswordResetToken,
            'newPassword': newPassword,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> hasAccount(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'hasAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'hasAccount',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _JwtRefreshEndpoint {
  _JwtRefreshEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> refreshAccessToken(
    _ist.TestSessionBuilder sessionBuilder, {
    String? refreshToken,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'jwtRefresh',
            method: 'refreshAccessToken',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'jwtRefresh',
          methodName: 'refreshAccessToken',
          parameters: _ist.testObjectToJson({'refreshToken': refreshToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ActivityEndpoint {
  _ActivityEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iwuvk2ka.ActivityDashboard> dashboard(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int days,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'activity',
            method: 'dashboard',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'activity',
          methodName: 'dashboard',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'days': days,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iwuvk2ka.ActivityDashboard>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> showViewHistory(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'activity',
            method: 'showViewHistory',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'activity',
          methodName: 'showViewHistory',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> setShowViewHistory(
    _ist.TestSessionBuilder sessionBuilder,
    bool show,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'activity',
            method: 'setShowViewHistory',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'activity',
          methodName: 'setShowViewHistory',
          parameters: _ist.testObjectToJson({'show': show}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AssistantEndpoint {
  _AssistantEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ibfulm5p.AssistantStatus> getStatus(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'getStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'getStatus',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibfulm5p.AssistantStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibfulm5p.AssistantStatus> setQuality(
    _ist.TestSessionBuilder sessionBuilder,
    _idrzmvpg.AiQuality quality,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'setQuality',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'setQuality',
          parameters: _ist.testObjectToJson({'quality': quality}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibfulm5p.AssistantStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibfulm5p.AssistantStatus> setProviderKey(
    _ist.TestSessionBuilder sessionBuilder,
    _i02m7u6n.AiProvider provider,
    String apiKey,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'setProviderKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'setProviderKey',
          parameters: _ist.testObjectToJson({
            'provider': provider,
            'apiKey': apiKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibfulm5p.AssistantStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibfulm5p.AssistantStatus> removeProviderKey(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'removeProviderKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'removeProviderKey',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibfulm5p.AssistantStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_ibgujsil.AssistantEvent> chat(
    _ist.TestSessionBuilder sessionBuilder,
    int? threadId,
    _is.UuidValue itemUuid,
    String message,
    _ixc2f7d5.AssistantContextHints hints,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_ibgujsil.AssistantEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'assistant',
              method: 'chat',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'assistant',
              methodName: 'chat',
              arguments: {
                'threadId': threadId,
                'itemUuid': itemUuid,
                'message': message,
                'hints': _idc.jsonDecode(
                  _is.SerializationManager.encode(hints),
                ),
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<bool> stop(
    _ist.TestSessionBuilder sessionBuilder,
    int? threadId,
    String? runId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'stop',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'stop',
          parameters: _ist.testObjectToJson({
            'threadId': threadId,
            'runId': runId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> confirm(
    _ist.TestSessionBuilder sessionBuilder,
    String runId,
    String confirmationId,
    bool allow,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'confirm',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'confirm',
          parameters: _ist.testObjectToJson({
            'runId': runId,
            'confirmationId': confirmationId,
            'allow': allow,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> uiToolResult(
    _ist.TestSessionBuilder sessionBuilder,
    String runId,
    _is78z0de.UiBridgeResponse response,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'uiToolResult',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'uiToolResult',
          parameters: _ist.testObjectToJson({
            'runId': runId,
            'response': response,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i1372x0g.AssistantThreadView>> listThreads(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'listThreads',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'listThreads',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i1372x0g.AssistantThreadView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_invizsga.AssistantThreadDetail> getThread(
    _ist.TestSessionBuilder sessionBuilder,
    int threadId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'getThread',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'getThread',
          parameters: _ist.testObjectToJson({'threadId': threadId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_invizsga.AssistantThreadDetail>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> deleteThread(
    _ist.TestSessionBuilder sessionBuilder,
    int threadId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'deleteThread',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'deleteThread',
          parameters: _ist.testObjectToJson({'threadId': threadId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> clearHistory(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'clearHistory',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'clearHistory',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> revertChange(
    _ist.TestSessionBuilder sessionBuilder,
    String changeId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'assistant',
            method: 'revertChange',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'assistant',
          methodName: 'revertChange',
          parameters: _ist.testObjectToJson({'changeId': changeId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iplizi6w.InlineAiEvent> inline(
    _ist.TestSessionBuilder sessionBuilder,
    _i4c3y8bm.InlineAiRequest request,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iplizi6w.InlineAiEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'assistant',
              method: 'inline',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'assistant',
              methodName: 'inline',
              arguments: {
                'request': _idc.jsonDecode(
                  _is.SerializationManager.encode(request),
                ),
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Stream<_ib6yu876.ProofreadEvent> proofread(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int? start,
    int? length,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_ib6yu876.ProofreadEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'assistant',
              method: 'proofread',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'assistant',
              methodName: 'proofread',
              arguments: {
                'itemUuid': itemUuid,
                'start': start,
                'length': length,
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }
}

class _BoardEndpoint {
  _BoardEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_imb1vxwh.BoardMe> me(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'me',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'me',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_imb1vxwh.BoardMe>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_imlue0yd.BoardPostPage> list(
    _ist.TestSessionBuilder sessionBuilder,
    _i6z8cjbe.BoardListQuery query,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'list',
          parameters: _ist.testObjectToJson({'query': query}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_imlue0yd.BoardPostPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_imokftek.BoardCounts> counts(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'counts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'counts',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_imokftek.BoardCounts>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> getPost(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'getPost',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'getPost',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ilh4w69x.BoardCommentView>> listComments(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'listComments',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'listComments',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ilh4w69x.BoardCommentView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ilh4w69x.BoardCommentView>> listTaskComments(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'listTaskComments',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'listTaskComments',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ilh4w69x.BoardCommentView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iv1j9wri.BoardSimilarPost>> similar(
    _ist.TestSessionBuilder sessionBuilder,
    String title,
    String body,
    _i5noao4s.BoardPostKind? kind,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'similar',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'similar',
          parameters: _ist.testObjectToJson({
            'title': title,
            'body': body,
            'kind': kind,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iv1j9wri.BoardSimilarPost>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String?> getScreenshotUrl(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'getScreenshotUrl',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'getScreenshotUrl',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i84zsqgv.BoardTaskPage> listTasks(
    _ist.TestSessionBuilder sessionBuilder,
    List<_ihypagkt.BoardTaskStatus> statuses,
    String? cursor,
    int limit,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'listTasks',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'listTasks',
          parameters: _ist.testObjectToJson({
            'statuses': statuses,
            'cursor': cursor,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i84zsqgv.BoardTaskPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> getTask(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'getTask',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'getTask',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_igl1sayy.BoardPostEvent> watchPost(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_igl1sayy.BoardPostEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'board',
              method: 'watchPost',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'board',
              methodName: 'watchPost',
              arguments: {'number': number},
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Stream<_igl1sayy.BoardPostEvent> watchTasks(
    _ist.TestSessionBuilder sessionBuilder,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_igl1sayy.BoardPostEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'board',
              method: 'watchTasks',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'board',
              methodName: 'watchTasks',
              arguments: {},
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_i3u7lvch.FileUploadTicket> createScreenshotUpload(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    String mimeType,
    int size,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'createScreenshotUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'createScreenshotUpload',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'mimeType': mimeType,
            'size': size,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i3u7lvch.FileUploadTicket>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> createPost(
    _ist.TestSessionBuilder sessionBuilder,
    _i6ub5i5f.BoardPostDraft draft,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'createPost',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'createPost',
          parameters: _ist.testObjectToJson({'draft': draft}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> editPost(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    String title,
    String body,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'editPost',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'editPost',
          parameters: _ist.testObjectToJson({
            'number': number,
            'title': title,
            'body': body,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> deletePost(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'deletePost',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'deletePost',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> restorePost(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'restorePost',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'restorePost',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> removeScreenshot(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'removeScreenshot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'removeScreenshot',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_inylym64.BoardVoteResult> vote(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    int value,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'vote',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'vote',
          parameters: _ist.testObjectToJson({
            'number': number,
            'value': value,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_inylym64.BoardVoteResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ilh4w69x.BoardCommentView> addComment(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    int? postNumber,
    int? taskNumber,
    String body,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'addComment',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'addComment',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'postNumber': postNumber,
            'taskNumber': taskNumber,
            'body': body,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ilh4w69x.BoardCommentView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ilh4w69x.BoardCommentView> editComment(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    String body,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'editComment',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'editComment',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'body': body,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ilh4w69x.BoardCommentView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> deleteComment(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'deleteComment',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'deleteComment',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ilh4w69x.BoardCommentView> restoreComment(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'restoreComment',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'restoreComment',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ilh4w69x.BoardCommentView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> flag(
    _ist.TestSessionBuilder sessionBuilder,
    int? number,
    _is.UuidValue? commentUuid,
    _i0z7k09i.BoardFlagReason reason,
    String? note,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'flag',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'flag',
          parameters: _ist.testObjectToJson({
            'number': number,
            'commentUuid': commentUuid,
            'reason': reason,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> unflag(
    _ist.TestSessionBuilder sessionBuilder,
    int? number,
    _is.UuidValue? commentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'unflag',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'unflag',
          parameters: _ist.testObjectToJson({
            'number': number,
            'commentUuid': commentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> claimTask(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'claimTask',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'claimTask',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> releaseTask(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'releaseTask',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'releaseTask',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iuafg5le.BoardReviewCounts> reviewCounts(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'reviewCounts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'reviewCounts',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iuafg5le.BoardReviewCounts>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_id1usvpt.BoardReviewItem>> reviewQueue(
    _ist.TestSessionBuilder sessionBuilder,
    _i6ojypp7.BoardReviewSection section,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'reviewQueue',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'reviewQueue',
          parameters: _ist.testObjectToJson({'section': section}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_id1usvpt.BoardReviewItem>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> moderatePost(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    _iqqjetoq.BoardModerationAction action,
    String? reason,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'moderatePost',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'moderatePost',
          parameters: _ist.testObjectToJson({
            'number': number,
            'action': action,
            'reason': reason,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ilh4w69x.BoardCommentView> moderateComment(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    _iqqjetoq.BoardModerationAction action,
    String? reason,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'moderateComment',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'moderateComment',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'action': action,
            'reason': reason,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ilh4w69x.BoardCommentView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> adminEditPost(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    String title,
    String body,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'adminEditPost',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'adminEditPost',
          parameters: _ist.testObjectToJson({
            'number': number,
            'title': title,
            'body': body,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> setLabels(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    _i5noao4s.BoardPostKind kind,
    _i2y7swbd.BoardArea? area,
    _ikq67o57.BoardSize? size,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'setLabels',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'setLabels',
          parameters: _ist.testObjectToJson({
            'number': number,
            'kind': kind,
            'area': area,
            'size': size,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> applySuggestedTitle(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'applySuggestedTitle',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'applySuggestedTitle',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> dismissDuplicateHint(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'dismissDuplicateHint',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'dismissDuplicateHint',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> merge(
    _ist.TestSessionBuilder sessionBuilder,
    int source,
    int target,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'merge',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'merge',
          parameters: _ist.testObjectToJson({
            'source': source,
            'target': target,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> unmerge(
    _ist.TestSessionBuilder sessionBuilder,
    int source,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'unmerge',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'unmerge',
          parameters: _ist.testObjectToJson({'source': source}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> decline(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    String reason,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'decline',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'decline',
          parameters: _ist.testObjectToJson({
            'number': number,
            'reason': reason,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir7e9zc6.BoardPostView> reopen(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'reopen',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'reopen',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir7e9zc6.BoardPostView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> blockUser(
    _ist.TestSessionBuilder sessionBuilder,
    int userId,
    String reason,
    DateTime? until,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'blockUser',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'blockUser',
          parameters: _ist.testObjectToJson({
            'userId': userId,
            'reason': reason,
            'until': until,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> unblockUser(
    _ist.TestSessionBuilder sessionBuilder,
    int userId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'unblockUser',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'unblockUser',
          parameters: _ist.testObjectToJson({'userId': userId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> createTask(
    _ist.TestSessionBuilder sessionBuilder,
    List<int> postNumbers,
    String title,
    _i2y7swbd.BoardArea area,
    _ikq67o57.BoardSize size, {
    List<_is.UuidValue>? excludedComments,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'createTask',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'createTask',
          parameters: _ist.testObjectToJson({
            'postNumbers': postNumbers,
            'title': title,
            'area': area,
            'size': size,
            'excludedComments': excludedComments,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> updateTask(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    String title,
    _i2y7swbd.BoardArea area,
    _ikq67o57.BoardSize size,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'updateTask',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'updateTask',
          parameters: _ist.testObjectToJson({
            'number': number,
            'title': title,
            'area': area,
            'size': size,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> setTaskPosts(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    List<int> postNumbers,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'setTaskPosts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'setTaskPosts',
          parameters: _ist.testObjectToJson({
            'number': number,
            'postNumbers': postNumbers,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> mergeTasks(
    _ist.TestSessionBuilder sessionBuilder,
    List<int> numbers,
    String title,
    _i2y7swbd.BoardArea area,
    _ikq67o57.BoardSize size,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'mergeTasks',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'mergeTasks',
          parameters: _ist.testObjectToJson({
            'numbers': numbers,
            'title': title,
            'area': area,
            'size': size,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> unmergeTasks(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'unmergeTasks',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'unmergeTasks',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> regeneratePrompt(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'regeneratePrompt',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'regeneratePrompt',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> setPrompt(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    String body,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'setPrompt',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'setPrompt',
          parameters: _ist.testObjectToJson({
            'number': number,
            'body': body,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> publishTask(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'publishTask',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'publishTask',
          parameters: _ist.testObjectToJson({'number': number}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> setTaskStatus(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    _ihypagkt.BoardTaskStatus status,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'setTaskStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'setTaskStatus',
          parameters: _ist.testObjectToJson({
            'number': number,
            'status': status,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia65vc34.BoardTaskView> linkPullRequest(
    _ist.TestSessionBuilder sessionBuilder,
    int number,
    String? url,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'linkPullRequest',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'linkPullRequest',
          parameters: _ist.testObjectToJson({
            'number': number,
            'url': url,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia65vc34.BoardTaskView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i8qikgvy.BoardBundleSuggestionView>> suggestBundles(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'suggestBundles',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'suggestBundles',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i8qikgvy.BoardBundleSuggestionView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i8qikgvy.BoardBundleSuggestionView>> listSuggestions(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'listSuggestions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'listSuggestions',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i8qikgvy.BoardBundleSuggestionView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> dismissSuggestion(
    _ist.TestSessionBuilder sessionBuilder,
    int id,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'board',
            method: 'dismissSuggestion',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'board',
          methodName: 'dismissSuggestion',
          parameters: _ist.testObjectToJson({'id': id}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _CommentEndpoint {
  _CommentEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_ixzwh8hc.CommentThreadView>> listThreads(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    _i0f5nb76.CommentFilter filter,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'listThreads',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'listThreads',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'filter': filter,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ixzwh8hc.CommentThreadView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixzwh8hc.CommentThreadView> getThread(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue threadUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'getThread',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'getThread',
          parameters: _ist.testObjectToJson({'threadUuid': threadUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixzwh8hc.CommentThreadView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixzwh8hc.CommentThreadView> createThread(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue threadUuid,
    _is.UuidValue itemUuid,
    _i384cqmz.CommentAnchorKind anchorKind,
    String anchorJson,
    String? quotedText,
    String body,
    List<int> mentions,
    int? assigneeId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'createThread',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'createThread',
          parameters: _ist.testObjectToJson({
            'threadUuid': threadUuid,
            'itemUuid': itemUuid,
            'anchorKind': anchorKind,
            'anchorJson': anchorJson,
            'quotedText': quotedText,
            'body': body,
            'mentions': mentions,
            'assigneeId': assigneeId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixzwh8hc.CommentThreadView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixzwh8hc.CommentThreadView> reply(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue threadUuid,
    String body,
    List<int> mentions, {
    _is.UuidValue? commentUuid,
    int? assigneeId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'reply',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'reply',
          parameters: _ist.testObjectToJson({
            'threadUuid': threadUuid,
            'body': body,
            'mentions': mentions,
            'commentUuid': commentUuid,
            'assigneeId': assigneeId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixzwh8hc.CommentThreadView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ionqrnff.CommentView> edit(
    _ist.TestSessionBuilder sessionBuilder,
    int commentId,
    String body, {
    List<int>? mentions,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'edit',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'edit',
          parameters: _ist.testObjectToJson({
            'commentId': commentId,
            'body': body,
            'mentions': mentions,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ionqrnff.CommentView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> delete(
    _ist.TestSessionBuilder sessionBuilder,
    int commentId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'delete',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'delete',
          parameters: _ist.testObjectToJson({'commentId': commentId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> deleteThread(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue threadUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'deleteThread',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'deleteThread',
          parameters: _ist.testObjectToJson({'threadUuid': threadUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixzwh8hc.CommentThreadView> resolve(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue threadUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'resolve',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'resolve',
          parameters: _ist.testObjectToJson({'threadUuid': threadUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixzwh8hc.CommentThreadView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixzwh8hc.CommentThreadView> reopen(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue threadUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'reopen',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'reopen',
          parameters: _ist.testObjectToJson({'threadUuid': threadUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixzwh8hc.CommentThreadView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ionqrnff.CommentView> react(
    _ist.TestSessionBuilder sessionBuilder,
    int commentId,
    String emoji,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'react',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'react',
          parameters: _ist.testObjectToJson({
            'commentId': commentId,
            'emoji': emoji,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ionqrnff.CommentView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixzwh8hc.CommentThreadView> updateAnchor(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue threadUuid,
    String anchorJson, {
    _i384cqmz.CommentAnchorKind? anchorKind,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'comment',
            method: 'updateAnchor',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'comment',
          methodName: 'updateAnchor',
          parameters: _ist.testObjectToJson({
            'threadUuid': threadUuid,
            'anchorJson': anchorJson,
            'anchorKind': anchorKind,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixzwh8hc.CommentThreadView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_i4nxgne2.CommentEvent> watch(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_i4nxgne2.CommentEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'comment',
              method: 'watch',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'comment',
              methodName: 'watch',
              arguments: {'itemUuid': itemUuid},
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }
}

class _DriveEndpoint {
  _DriveEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_i2951hft.DriveListPage> list(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? folderUuid,
    _iaoi0gn5.DriveListFilter filter,
    _il6plm80.DriveSort sort,
    String? cursor,
    int limit,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'list',
          parameters: _ist.testObjectToJson({
            'folderUuid': folderUuid,
            'filter': filter,
            'sort': sort,
            'cursor': cursor,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i2951hft.DriveListPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> get(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'get',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'get',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ily3pmy5.DriveItemView>> path(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'path',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'path',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ily3pmy5.DriveItemView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i2951hft.DriveListPage> search(
    _ist.TestSessionBuilder sessionBuilder,
    String query,
    _iub85lgd.DriveSearchFilters filters,
    String? cursor,
    int limit,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'search',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'search',
          parameters: _ist.testObjectToJson({
            'query': query,
            'filters': filters,
            'cursor': cursor,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i2951hft.DriveListPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> createFolder(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? parentUuid,
    String name,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'createFolder',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'createFolder',
          parameters: _ist.testObjectToJson({
            'parentUuid': parentUuid,
            'name': name,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> createDocument(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? parentUuid,
    String name,
    _is.UuidValue? templateUuid,
    String? initialMarkdown, {
    _is.UuidValue? documentUuid,
    _is.UuidValue? itemUuid,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'createDocument',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'createDocument',
          parameters: _ist.testObjectToJson({
            'parentUuid': parentUuid,
            'name': name,
            'templateUuid': templateUuid,
            'initialMarkdown': initialMarkdown,
            'documentUuid': documentUuid,
            'itemUuid': itemUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> registerSpreadsheet(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spaceUuid,
    _is.UuidValue? parentUuid,
    String name,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'registerSpreadsheet',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'registerSpreadsheet',
          parameters: _ist.testObjectToJson({
            'spaceUuid': spaceUuid,
            'parentUuid': parentUuid,
            'name': name,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> createSpreadsheet(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? parentUuid,
    String name,
    _is.UuidValue? templateUuid, {
    String? locale,
    String? timeZone,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'createSpreadsheet',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'createSpreadsheet',
          parameters: _ist.testObjectToJson({
            'parentUuid': parentUuid,
            'name': name,
            'templateUuid': templateUuid,
            'locale': locale,
            'timeZone': timeZone,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> rename(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    String name,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'rename',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'rename',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'name': name,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> updateDescription(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    String? description,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'updateDescription',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'updateDescription',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'description': description,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ily3pmy5.DriveItemView>> move(
    _ist.TestSessionBuilder sessionBuilder,
    List<_is.UuidValue> uuids,
    _is.UuidValue? newParentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'move',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'move',
          parameters: _ist.testObjectToJson({
            'uuids': uuids,
            'newParentUuid': newParentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ily3pmy5.DriveItemView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> copy(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    String newName,
    _is.UuidValue? parentUuid,
    bool copyComments,
    bool copySharing,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'copy',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'copy',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'newName': newName,
            'parentUuid': parentUuid,
            'copyComments': copyComments,
            'copySharing': copySharing,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> setStarred(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    bool starred,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'setStarred',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'setStarred',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'starred': starred,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> setPinnedOffline(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    bool pinned,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'setPinnedOffline',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'setPinnedOffline',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'pinned': pinned,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> markOpened(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'markOpened',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'markOpened',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> addShortcut(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    _is.UuidValue? parentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'addShortcut',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'addShortcut',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'parentUuid': parentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> removeShortcut(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'removeShortcut',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'removeShortcut',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> trash(
    _ist.TestSessionBuilder sessionBuilder,
    List<_is.UuidValue> uuids,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'trash',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'trash',
          parameters: _ist.testObjectToJson({'uuids': uuids}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> restore(
    _ist.TestSessionBuilder sessionBuilder,
    List<_is.UuidValue> uuids,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'restore',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'restore',
          parameters: _ist.testObjectToJson({'uuids': uuids}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> deletePermanently(
    _ist.TestSessionBuilder sessionBuilder,
    List<_is.UuidValue> uuids,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'deletePermanently',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'deletePermanently',
          parameters: _ist.testObjectToJson({'uuids': uuids}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> emptyTrash(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'emptyTrash',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'emptyTrash',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iypu9rxn.DriveChange> watch(
    _ist.TestSessionBuilder sessionBuilder,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iypu9rxn.DriveChange>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'drive',
              method: 'watch',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'drive',
              methodName: 'watch',
              arguments: {},
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<List<_ibinmr4r.TemplateView>> listTemplates(
    _ist.TestSessionBuilder sessionBuilder,
    _i0549mj7.DriveItemKind? kind,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'listTemplates',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'listTemplates',
          parameters: _ist.testObjectToJson({'kind': kind}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ibinmr4r.TemplateView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> setTemplate(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    _inlkiawi.TemplateCategory? category,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'setTemplate',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'setTemplate',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'category': category,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_imxcy17c.ImportReportView> import(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uploadId,
    _i0549mj7.DriveItemKind kind,
    _iyihga8r.DriveImportOptions options,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'import',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'import',
          parameters: _ist.testObjectToJson({
            'uploadId': uploadId,
            'kind': kind,
            'options': options,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_imxcy17c.ImportReportView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> registerPresentation(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spaceUuid,
    _is.UuidValue? parentUuid,
    String name,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'registerPresentation',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'registerPresentation',
          parameters: _ist.testObjectToJson({
            'spaceUuid': spaceUuid,
            'parentUuid': parentUuid,
            'name': name,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> createPresentation(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? parentUuid,
    String name,
    _is.UuidValue? templateUuid, {
    _is.UuidValue? fileUuid,
    bool? initialize,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'createPresentation',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'createPresentation',
          parameters: _ist.testObjectToJson({
            'parentUuid': parentUuid,
            'name': name,
            'templateUuid': templateUuid,
            'fileUuid': fileUuid,
            'initialize': initialize,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibju74sj.FileUploadStart> createFileUpload(
    _ist.TestSessionBuilder sessionBuilder,
    _i6y6tdjl.FileUploadRequest request,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'createFileUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'createFileUpload',
          parameters: _ist.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibju74sj.FileUploadStart>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> completeFileUpload(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'completeFileUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'completeFileUpload',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> cancelFileUpload(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'cancelFileUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'cancelFileUpload',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idjmq8ha.FileUploadProgress> fileUploadStatus(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'fileUploadStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'fileUploadStatus',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idjmq8ha.FileUploadProgress>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_imxcy17c.ImportReportView> convertFile(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileItemUuid,
    _i0549mj7.DriveItemKind target,
    _iyihga8r.DriveImportOptions options,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'convertFile',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'convertFile',
          parameters: _ist.testObjectToJson({
            'fileItemUuid': fileItemUuid,
            'target': target,
            'options': options,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_imxcy17c.ImportReportView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i28n3m1r.FileUrlView> fileContentUrl(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid, {
    required bool download,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'fileContentUrl',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'fileContentUrl',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'download': download,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i28n3m1r.FileUrlView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> updateFileMeta(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String fileMetaJson,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'updateFileMeta',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'updateFileMeta',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'fileMetaJson': fileMetaJson,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> checkRoom(
    _ist.TestSessionBuilder sessionBuilder,
    int bytes,
    _is.UuidValue? itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'checkRoom',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'checkRoom',
          parameters: _ist.testObjectToJson({
            'bytes': bytes,
            'itemUuid': itemUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i2951hft.DriveListPage> listByStorage(
    _ist.TestSessionBuilder sessionBuilder,
    _i7yliwmh.StorageListFilter filter,
    String? cursor,
    int limit,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'listByStorage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'listByStorage',
          parameters: _ist.testObjectToJson({
            'filter': filter,
            'cursor': cursor,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i2951hft.DriveListPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iui3jqzz.StorageUsage> storageUsage(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'storageUsage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'storageUsage',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iui3jqzz.StorageUsage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> setThumbnail(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    _is.UuidValue uploadedFileUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'setThumbnail',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'setThumbnail',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'uploadedFileUuid': uploadedFileUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iiw0494r.ActivityEventView>> activity(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    int? beforeId,
    int limit,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'drive',
            method: 'activity',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'drive',
          methodName: 'activity',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'beforeId': beforeId,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iiw0494r.ActivityEventView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _E2eSupportEndpoint {
  _E2eSupportEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String?> latestVerificationCode(
    _ist.TestSessionBuilder sessionBuilder,
    String email,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'e2eSupport',
            method: 'latestVerificationCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'e2eSupport',
          methodName: 'latestVerificationCode',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String?> latestPasswordResetCode(
    _ist.TestSessionBuilder sessionBuilder,
    String email,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'e2eSupport',
            method: 'latestPasswordResetCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'e2eSupport',
          methodName: 'latestPasswordResetCode',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _FeedbackEndpoint {
  _FeedbackEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<void> submit(
    _ist.TestSessionBuilder sessionBuilder,
    _ira9srbn.FeedbackSubmission feedback,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'feedback',
            method: 'submit',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'feedback',
          methodName: 'submit',
          parameters: _ist.testObjectToJson({'feedback': feedback}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> reportError(
    _ist.TestSessionBuilder sessionBuilder,
    _ira9srbn.FeedbackSubmission report,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'feedback',
            method: 'reportError',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'feedback',
          methodName: 'reportError',
          parameters: _ist.testObjectToJson({'report': report}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _FileEndpoint {
  _FileEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_i3u7lvch.FileUploadTicket> createUpload(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    _is.UuidValue? itemUuid,
    String fileName,
    String mimeType,
    int size, {
    _idhe6v6s.StoredFileKind? kind,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'file',
            method: 'createUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'file',
          methodName: 'createUpload',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'itemUuid': itemUuid,
            'fileName': fileName,
            'mimeType': mimeType,
            'size': size,
            'kind': kind,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i3u7lvch.FileUploadTicket>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i28n3m1r.FileUrlView> completeUpload(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'file',
            method: 'completeUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'file',
          methodName: 'completeUpload',
          parameters: _ist.testObjectToJson({'fileUuid': fileUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i28n3m1r.FileUrlView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i28n3m1r.FileUrlView> getUrl(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'file',
            method: 'getUrl',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'file',
          methodName: 'getUrl',
          parameters: _ist.testObjectToJson({'fileUuid': fileUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i28n3m1r.FileUrlView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i28n3m1r.FileUrlView> copyToItem(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue sourceFileUuid,
    _is.UuidValue newFileUuid,
    _is.UuidValue targetItemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'file',
            method: 'copyToItem',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'file',
          methodName: 'copyToItem',
          parameters: _ist.testObjectToJson({
            'sourceFileUuid': sourceFileUuid,
            'newFileUuid': newFileUuid,
            'targetItemUuid': targetItemUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i28n3m1r.FileUrlView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt.ByteData> fetchImage(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String url,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'file',
            method: 'fetchImage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'file',
          methodName: 'fetchImage',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'url': url,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt.ByteData>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i28n3m1r.FileUrlView>> getUrls(
    _ist.TestSessionBuilder sessionBuilder,
    List<_is.UuidValue> fileUuids,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'file',
            method: 'getUrls',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'file',
          methodName: 'getUrls',
          parameters: _ist.testObjectToJson({'fileUuids': fileUuids}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i28n3m1r.FileUrlView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _UiBridgeEndpoint {
  _UiBridgeEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Stream<_is78z0de.UiBridgeMessage> connect(
    _ist.TestSessionBuilder sessionBuilder,
    _ida.Stream<_is78z0de.UiBridgeMessage> fromApp,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_is78z0de.UiBridgeMessage>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'uiBridge',
              method: 'connect',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'uiBridge',
              methodName: 'connect',
              arguments: {},
              requestedInputStreams: ['fromApp'],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {'fromApp': fromApp},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }
}

class _MetaEndpoint {
  _MetaEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ih1cymrz.ProtocolInfo> getInfo(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'meta',
            method: 'getInfo',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'meta',
          methodName: 'getInfo',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ih1cymrz.ProtocolInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _NotificationEndpoint {
  _NotificationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_i2em4uch.NotificationPage> list(
    _ist.TestSessionBuilder sessionBuilder,
    String? cursor,
    int limit,
    bool unreadOnly,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'notification',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'notification',
          methodName: 'list',
          parameters: _ist.testObjectToJson({
            'cursor': cursor,
            'limit': limit,
            'unreadOnly': unreadOnly,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i2em4uch.NotificationPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> unreadCount(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'notification',
            method: 'unreadCount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'notification',
          methodName: 'unreadCount',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> markRead(
    _ist.TestSessionBuilder sessionBuilder,
    List<int> ids,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'notification',
            method: 'markRead',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'notification',
          methodName: 'markRead',
          parameters: _ist.testObjectToJson({'ids': ids}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> markAllRead(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'notification',
            method: 'markAllRead',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'notification',
          methodName: 'markAllRead',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iw7v7gz7.NotificationEvent> watch(
    _ist.TestSessionBuilder sessionBuilder,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iw7v7gz7.NotificationEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'notification',
              method: 'watch',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'notification',
              methodName: 'watch',
              arguments: {},
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }
}

class _PresenceEndpoint {
  _PresenceEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Stream<_in8u6dfh.PresenceEvent> join(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    _ida.Stream<_ipd65of1.PresenceUpdate> updates,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_in8u6dfh.PresenceEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'presence',
              method: 'join',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'presence',
              methodName: 'join',
              arguments: {'itemUuid': itemUuid},
              requestedInputStreams: ['updates'],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {'updates': updates},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }
}

class _PublicationEndpoint {
  _PublicationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iywwc4sf.PublicationCard> resolve(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'resolve',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'resolve',
          parameters: _ist.testObjectToJson({'publicId': publicId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iywwc4sf.PublicationCard>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ighe7owc.SubmissionStarted> startSubmission(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
    String? ref,
    bool agreed,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'startSubmission',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'startSubmission',
          parameters: _ist.testObjectToJson({
            'publicId': publicId,
            'ref': ref,
            'agreed': agreed,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ighe7owc.SubmissionStarted>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i9ilkmgj.PublicationSettings>> list(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'list',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i9ilkmgj.PublicationSettings>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i1thvjiu.PublicationSecret> create(
    _ist.TestSessionBuilder sessionBuilder,
    _iy7hmxv3.PublicationInput input,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'create',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'create',
          parameters: _ist.testObjectToJson({'input': input}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i1thvjiu.PublicationSecret>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i9ilkmgj.PublicationSettings> update(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
    _iy7hmxv3.PublicationInput input,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'update',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'update',
          parameters: _ist.testObjectToJson({
            'publicId': publicId,
            'input': input,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i9ilkmgj.PublicationSettings>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> delete(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'delete',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'delete',
          parameters: _ist.testObjectToJson({'publicId': publicId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i1amkxf0.PublicationCheckResult> verify(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'verify',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'verify',
          parameters: _ist.testObjectToJson({'publicId': publicId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i1amkxf0.PublicationCheckResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i1thvjiu.PublicationSecret> rotateSecret(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'rotateSecret',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'rotateSecret',
          parameters: _ist.testObjectToJson({'publicId': publicId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i1thvjiu.PublicationSecret>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i1thvjiu.PublicationSecret> createApiKey(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'createApiKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'createApiKey',
          parameters: _ist.testObjectToJson({'publicId': publicId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i1thvjiu.PublicationSecret>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i9ilkmgj.PublicationSettings> setModerators(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
    List<String> emails,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'setModerators',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'setModerators',
          parameters: _ist.testObjectToJson({
            'publicId': publicId,
            'emails': emails,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i9ilkmgj.PublicationSettings>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_idovycpn.PublicationDeliveryView>> deliveries(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'deliveries',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'deliveries',
          parameters: _ist.testObjectToJson({'publicId': publicId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_idovycpn.PublicationDeliveryView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idovycpn.PublicationDeliveryView> resend(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
    String webhookId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'resend',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'resend',
          parameters: _ist.testObjectToJson({
            'publicId': publicId,
            'webhookId': webhookId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idovycpn.PublicationDeliveryView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i1amkxf0.PublicationCheckResult> sendTest(
    _ist.TestSessionBuilder sessionBuilder,
    String publicId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'publication',
            method: 'sendTest',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'publication',
          methodName: 'sendTest',
          parameters: _ist.testObjectToJson({'publicId': publicId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i1amkxf0.PublicationCheckResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SubmissionEndpoint {
  _SubmissionEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ij8gnfyr.SubmissionView?> get(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'submission',
            method: 'get',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'submission',
          methodName: 'get',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ij8gnfyr.SubmissionView?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ij8gnfyr.SubmissionView> submit(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    _iwukrrmj.SubmissionValues values,
    bool agreed,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'submission',
            method: 'submit',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'submission',
          methodName: 'submit',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'values': values,
            'agreed': agreed,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ij8gnfyr.SubmissionView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ij8gnfyr.SubmissionView> withdraw(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'submission',
            method: 'withdraw',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'submission',
          methodName: 'withdraw',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ij8gnfyr.SubmissionView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> disconnect(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'submission',
            method: 'disconnect',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'submission',
          methodName: 'disconnect',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ij8gnfyr.SubmissionView?> reconnect(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'submission',
            method: 'reconnect',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'submission',
          methodName: 'reconnect',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ij8gnfyr.SubmissionView?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SharingEndpoint {
  _SharingEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ibhys9d2.SharingInfo> getSharing(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'getSharing',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'getSharing',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> share(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    List<String> emails,
    _i9nsco4y.AccessRole role,
    bool notify,
    String? message,
    DateTime? expiresAt,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'share',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'share',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'emails': emails,
            'role': role,
            'notify': notify,
            'message': message,
            'expiresAt': expiresAt,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> updateRole(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int userId,
    _i9nsco4y.AccessRole role, {
    DateTime? expiresAt,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'updateRole',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'updateRole',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'userId': userId,
            'role': role,
            'expiresAt': expiresAt,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> remove(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int? userId, {
    String? invitedEmail,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'remove',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'remove',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'userId': userId,
            'invitedEmail': invitedEmail,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> transferOwnership(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int newOwnerUserId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'transferOwnership',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'transferOwnership',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'newOwnerUserId': newOwnerUserId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> respondToOwnershipTransfer(
    _ist.TestSessionBuilder sessionBuilder,
    int transferId,
    bool accept,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'respondToOwnershipTransfer',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'respondToOwnershipTransfer',
          parameters: _ist.testObjectToJson({
            'transferId': transferId,
            'accept': accept,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> setLink(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    _i9nsco4y.AccessRole? role,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'setLink',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'setLink',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'role': role,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> rotateLink(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'rotateLink',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'rotateLink',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> updateSettings(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    _i55sl7s1.ItemSharingSettings settings,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'updateSettings',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'updateSettings',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'settings': settings,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> requestAccess(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    _i9nsco4y.AccessRole role,
    String? message,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'requestAccess',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'requestAccess',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'role': role,
            'message': message,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ibhys9d2.SharingInfo> handleAccessRequest(
    _ist.TestSessionBuilder sessionBuilder,
    int requestId,
    bool approve,
    _i9nsco4y.AccessRole? role,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'handleAccessRequest',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'handleAccessRequest',
          parameters: _ist.testObjectToJson({
            'requestId': requestId,
            'approve': approve,
            'role': role,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ibhys9d2.SharingInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir129i67.InviteResolution> resolveInvite(
    _ist.TestSessionBuilder sessionBuilder,
    String token,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sharing',
            method: 'resolveInvite',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sharing',
          methodName: 'resolveInvite',
          parameters: _ist.testObjectToJson({'token': token}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir129i67.InviteResolution>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AccessTokenEndpoint {
  _AccessTokenEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_ioyb7a1p.AccessTokenView>> list(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'accessToken',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'accessToken',
          methodName: 'list',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ioyb7a1p.AccessTokenView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iutsxjwz.CreatedAccessToken> create(
    _ist.TestSessionBuilder sessionBuilder,
    String name,
    List<String> scopes,
    DateTime? expiresAt,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'accessToken',
            method: 'create',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'accessToken',
          methodName: 'create',
          parameters: _ist.testObjectToJson({
            'name': name,
            'scopes': scopes,
            'expiresAt': expiresAt,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iutsxjwz.CreatedAccessToken>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ioyb7a1p.AccessTokenView> revoke(
    _ist.TestSessionBuilder sessionBuilder,
    int id,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'accessToken',
            method: 'revoke',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'accessToken',
          methodName: 'revoke',
          parameters: _ist.testObjectToJson({'id': id}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ioyb7a1p.AccessTokenView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _GoogleIdpEndpoint {
  _GoogleIdpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> login(
    _ist.TestSessionBuilder sessionBuilder, {
    required String idToken,
    required String? accessToken,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'googleIdp',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'googleIdp',
          methodName: 'login',
          parameters: _ist.testObjectToJson({
            'idToken': idToken,
            'accessToken': accessToken,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iacs.AuthSuccess> loginWithCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'googleIdp',
            method: 'loginWithCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'googleIdp',
          methodName: 'loginWithCode',
          parameters: _ist.testObjectToJson({
            'code': code,
            'codeVerifier': codeVerifier,
            'redirectUri': redirectUri,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> hasAccount(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'googleIdp',
            method: 'hasAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'googleIdp',
          methodName: 'hasAccount',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _UserEndpoint {
  _UserEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ixfirwt7.UserProfileView> getMe(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'getMe',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'getMe',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixfirwt7.UserProfileView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixfirwt7.UserProfileView> updateProfile(
    _ist.TestSessionBuilder sessionBuilder, {
    String? displayName,
    String? locale,
    String? timeZone,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'updateProfile',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'updateProfile',
          parameters: _ist.testObjectToJson({
            'displayName': displayName,
            'locale': locale,
            'timeZone': timeZone,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixfirwt7.UserProfileView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i3u7lvch.FileUploadTicket> uploadAvatar(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    String fileName,
    String mimeType,
    int size,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'uploadAvatar',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'uploadAvatar',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'fileName': fileName,
            'mimeType': mimeType,
            'size': size,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i3u7lvch.FileUploadTicket>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixfirwt7.UserProfileView> setAvatar(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? fileUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'setAvatar',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'setAvatar',
          parameters: _ist.testObjectToJson({'fileUuid': fileUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixfirwt7.UserProfileView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_istt8k6c.UserPreferences> getPreferences(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'getPreferences',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'getPreferences',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_istt8k6c.UserPreferences>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_istt8k6c.UserPreferences> updatePreferences(
    _ist.TestSessionBuilder sessionBuilder,
    _ingbfbma.UserPreferencesPatch patch,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'updatePreferences',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'updatePreferences',
          parameters: _ist.testObjectToJson({'patch': patch}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_istt8k6c.UserPreferences>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i8uuoam6.UserSummary>> searchUsers(
    _ist.TestSessionBuilder sessionBuilder,
    String query,
    int limit,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'searchUsers',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'searchUsers',
          parameters: _ist.testObjectToJson({
            'query': query,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i8uuoam6.UserSummary>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i8uuoam6.UserSummary>> getUsers(
    _ist.TestSessionBuilder sessionBuilder,
    List<int> ids,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'getUsers',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'getUsers',
          parameters: _ist.testObjectToJson({'ids': ids}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i8uuoam6.UserSummary>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ioq21a5l.AccountDeletionPreview> accountDeletionPreview(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'accountDeletionPreview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'accountDeletionPreview',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ioq21a5l.AccountDeletionPreview>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> deleteAccount(
    _ist.TestSessionBuilder sessionBuilder,
    String confirmation,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'user',
            method: 'deleteAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'user',
          methodName: 'deleteAccount',
          parameters: _ist.testObjectToJson({'confirmation': confirmation}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _VersionEndpoint {
  _VersionEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_ir2w0lzm.ItemVersionView>> list(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    bool namedOnly, {
    int? beforeId,
    int? limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'version',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'version',
          methodName: 'list',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'namedOnly': namedOnly,
            'beforeId': beforeId,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ir2w0lzm.ItemVersionView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir2w0lzm.ItemVersionView> nameCurrent(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String name,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'version',
            method: 'nameCurrent',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'version',
          methodName: 'nameCurrent',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'name': name,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir2w0lzm.ItemVersionView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir2w0lzm.ItemVersionView> rename(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int versionId,
    String? name,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'version',
            method: 'rename',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'version',
          methodName: 'rename',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'versionId': versionId,
            'name': name,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir2w0lzm.ItemVersionView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i8hd56jb.VersionRestoreResult> restore(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int versionId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'version',
            method: 'restore',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'version',
          methodName: 'restore',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'versionId': versionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i8hd56jb.VersionRestoreResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i28n3m1r.FileUrlView> getSnapshotUrl(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int versionId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'version',
            method: 'getSnapshotUrl',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'version',
          methodName: 'getSnapshotUrl',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'versionId': versionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i28n3m1r.FileUrlView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SheetsAiEndpoint {
  _SheetsAiEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_idbu6x15.SheetsFormulaSuggestion> suggestFormula(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String cell,
    String prompt,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'suggestFormula',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'suggestFormula',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'cell': cell,
            'prompt': prompt,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idbu6x15.SheetsFormulaSuggestion>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iplizi6w.InlineAiEvent> explainFormula(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String cell,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iplizi6w.InlineAiEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'sheetsAi',
              method: 'explainFormula',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'sheetsAi',
              methodName: 'explainFormula',
              arguments: {
                'itemUuid': itemUuid,
                'cell': cell,
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_i8mtoy9m.SheetsFillProposal> fillRange(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String range,
    String? instructions,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'fillRange',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'fillRange',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'range': range,
            'instructions': instructions,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i8mtoy9m.SheetsFillProposal>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_irr92qm3.SheetsAiApplyResult> applyFill(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String range,
    List<_isuyxaqz.SheetsFillRow> rows,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'applyFill',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'applyFill',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'range': range,
            'rows': rows,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_irr92qm3.SheetsAiApplyResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<String>> analyzeChips(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String? range,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'analyzeChips',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'analyzeChips',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'range': range,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> describeChart(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String chartId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'describeChart',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'describeChart',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'chartId': chartId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i5mk43di.SheetsAiPreview> getPreview(
    _ist.TestSessionBuilder sessionBuilder,
    String previewId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'getPreview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'getPreview',
          parameters: _ist.testObjectToJson({'previewId': previewId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i5mk43di.SheetsAiPreview>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_irr92qm3.SheetsAiApplyResult> applyPreview(
    _ist.TestSessionBuilder sessionBuilder,
    String previewId,
    List<String>? callIds,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'applyPreview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'applyPreview',
          parameters: _ist.testObjectToJson({
            'previewId': previewId,
            'callIds': callIds,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_irr92qm3.SheetsAiApplyResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iq57nmvp.SheetsAiCellResult>> evaluateAiCells(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    List<_ifqit8uo.SheetsAiCellRequest> requests,
    bool refresh,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'evaluateAiCells',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'evaluateAiCells',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'requests': requests,
            'refresh': refresh,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iq57nmvp.SheetsAiCellResult>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> discardPreview(
    _ist.TestSessionBuilder sessionBuilder,
    String previewId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsAi',
            method: 'discardPreview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsAi',
          methodName: 'discardPreview',
          parameters: _ist.testObjectToJson({'previewId': previewId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SheetsDocEndpoint {
  _SheetsDocEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Stream<_ifa159qn.RevServerMessage> connect(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    int knownRevision,
    String tabId,
    _ida.Stream<_iv4mnr49.RevClientMessage> input,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_ifa159qn.RevServerMessage>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'sheetsDoc',
              method: 'connect',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'sheetsDoc',
              methodName: 'connect',
              arguments: {
                'fileUuid': fileUuid,
                'knownRevision': knownRevision,
                'tabId': tabId,
              },
              requestedInputStreams: ['input'],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {'input': input},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_i4qoa0fo.RevPage> page(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    _iynxab9u.RevPageRequest request,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsDoc',
            method: 'page',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsDoc',
          methodName: 'page',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'request': request,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i4qoa0fo.RevPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iu7aww0d.RevOpView>> ops(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    int fromRevision,
    int toRevision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsDoc',
            method: 'ops',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsDoc',
          methodName: 'ops',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'fromRevision': fromRevision,
            'toRevision': toRevision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iu7aww0d.RevOpView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iwjfjan3.RevFileInfo> info(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsDoc',
            method: 'info',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsDoc',
          methodName: 'info',
          parameters: _ist.testObjectToJson({'fileUuid': fileUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iwjfjan3.RevFileInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SheetsEndpoint {
  _SheetsEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<Map<String, String>> getUserProperties(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'getUserProperties',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'getUserProperties',
          parameters: _ist.testObjectToJson({'fileUuid': fileUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<Map<String, String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> setUserProperties(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    Map<String, String?> changes,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'setUserProperties',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'setUserProperties',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'changes': changes,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> namedFunctions(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'namedFunctions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'namedFunctions',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> spreadsheetTheme(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'spreadsheetTheme',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'spreadsheetTheme',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iqq3mn94.RevertResult> revertChange(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue changeId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'revertChange',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'revertChange',
          parameters: _ist.testObjectToJson({'changeId': changeId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iqq3mn94.RevertResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iqq3mn94.RevertResult> reapplyChange(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue changeId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'reapplyChange',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'reapplyChange',
          parameters: _ist.testObjectToJson({'changeId': changeId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iqq3mn94.RevertResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ia7wiyaj.CellHistoryPage> cellHistory(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    _is.UuidValue sheetId,
    _is.UuidValue rowId,
    _is.UuidValue colId,
    String? cursor,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'cellHistory',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'cellHistory',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'sheetId': sheetId,
            'rowId': rowId,
            'colId': colId,
            'cursor': cursor,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ia7wiyaj.CellHistoryPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_in9s3hn0.SheetsActivitySummary> activitySummary(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    int days,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'activitySummary',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'activitySummary',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'days': days,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_in9s3hn0.SheetsActivitySummary>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt.ByteData> fetchImage(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String url,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheets',
            method: 'fetchImage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheets',
          methodName: 'fetchImage',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'url': url,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt.ByteData>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SheetsImportEndpoint {
  _SheetsImportEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_is.UuidValue> importInto(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    _is.UuidValue uploadId,
    String optionsJson,
    String? activeSheetId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsImport',
            method: 'importInto',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsImport',
          methodName: 'importInto',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'uploadId': uploadId,
            'optionsJson': optionsJson,
            'activeSheetId': activeSheetId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_is.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iatbq4i5.SheetsImportProgress> watchImport(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue jobId,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iatbq4i5.SheetsImportProgress>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'sheetsImport',
              method: 'watchImport',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'sheetsImport',
              methodName: 'watchImport',
              arguments: {'jobId': jobId},
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_iatbq4i5.SheetsImportProgress> importProgress(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue jobId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsImport',
            method: 'importProgress',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsImport',
          methodName: 'importProgress',
          parameters: _ist.testObjectToJson({'jobId': jobId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iatbq4i5.SheetsImportProgress>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ilqg61i8.ExportResultView> sourceFromDrive(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsImport',
            method: 'sourceFromDrive',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsImport',
          methodName: 'sourceFromDrive',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ilqg61i8.ExportResultView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iatbq4i5.SheetsImportProgress> cancelImport(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue jobId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsImport',
            method: 'cancelImport',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsImport',
          methodName: 'cancelImport',
          parameters: _ist.testObjectToJson({'jobId': jobId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iatbq4i5.SheetsImportProgress>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ScriptEndpoint {
  _ScriptEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ii26bewh.ScriptCompileResponse> compile(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'compile',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'compile',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ii26bewh.ScriptCompileResponse>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> analyze(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    String fileName,
    String source,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'analyze',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'analyze',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'fileName': fileName,
            'source': source,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt.ByteData> bytecode(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'bytecode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'bytecode',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt.ByteData>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ijolphc0.ScriptRunResponse> run(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    String functionName,
    String? argsJson,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'run',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'run',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'functionName': functionName,
            'argsJson': argsJson,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ijolphc0.ScriptRunResponse>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<String> runLive(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    String functionName,
    String? argsJson,
  ) {
    var _localTestStreamManager = _ist.TestStreamManager<String>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'script',
              method: 'runLive',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'script',
              methodName: 'runLive',
              arguments: {
                'spreadsheetUuid': spreadsheetUuid,
                'functionName': functionName,
                'argsJson': argsJson,
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<List<_isf59hoo.ScriptExecution>> executions(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid, {
    String? functionName,
    _icum4fx3.ScriptExecutionStatus? status,
    DateTime? before,
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'executions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'executions',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'functionName': functionName,
            'status': status,
            'before': before,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_isf59hoo.ScriptExecution>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> reportExecutions(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    List<_isf59hoo.ScriptExecution> executions,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'reportExecutions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'reportExecutions',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'executions': executions,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i540ar91.ScriptFetchResponse> urlFetch(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    String requestJson, {
    required bool customFunction,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'urlFetch',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'urlFetch',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'requestJson': requestJson,
            'customFunction': customFunction,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i540ar91.ScriptFetchResponse>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ix5njoik.ScriptAuthorizationView> authorization(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'authorization',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'authorization',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ix5njoik.ScriptAuthorizationView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ix5njoik.ScriptAuthorizationView> authorize(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    List<String> scopes,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'authorize',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'authorize',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'scopes': scopes,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ix5njoik.ScriptAuthorizationView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> revokeAuthorization(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'revokeAuthorization',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'revokeAuthorization',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> notifyOpen(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'script',
            method: 'notifyOpen',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'script',
          methodName: 'notifyOpen',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SheetsVersionEndpoint {
  _SheetsVersionEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String> changes(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int versionId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsVersion',
            method: 'changes',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsVersion',
          methodName: 'changes',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'versionId': versionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i28n3m1r.FileUrlView> diff(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int versionId,
    int? previousVersionId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsVersion',
            method: 'diff',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsVersion',
          methodName: 'diff',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'versionId': versionId,
            'previousVersionId': previousVersionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i28n3m1r.FileUrlView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> copyExtras(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue sourceItemUuid,
    _is.UuidValue targetItemUuid,
    String anchorIdMapJson,
    bool copyComments,
    bool copySharing,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sheetsVersion',
            method: 'copyExtras',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sheetsVersion',
          methodName: 'copyExtras',
          parameters: _ist.testObjectToJson({
            'sourceItemUuid': sourceItemUuid,
            'targetItemUuid': targetItemUuid,
            'anchorIdMapJson': anchorIdMapJson,
            'copyComments': copyComments,
            'copySharing': copySharing,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SlidesAiEndpoint {
  _SlidesAiEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Stream<_iplizi6w.InlineAiEvent> proposeOutline(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? itemUuid,
    _isfebja2.SlidesAiOutlineRequest request,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iplizi6w.InlineAiEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'slidesAi',
              method: 'proposeOutline',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'slidesAi',
              methodName: 'proposeOutline',
              arguments: {
                'itemUuid': itemUuid,
                'request': _idc.jsonDecode(
                  _is.SerializationManager.encode(request),
                ),
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_iyy431k4.SlidesAiBuildResult> buildDeck(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue? itemUuid,
    String outlineJson,
    String? afterSlideId,
    bool notes,
    bool groups,
    _is.UuidValue? parentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesAi',
            method: 'buildDeck',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesAi',
          methodName: 'buildDeck',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'outlineJson': outlineJson,
            'afterSlideId': afterSlideId,
            'notes': notes,
            'groups': groups,
            'parentUuid': parentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iyy431k4.SlidesAiBuildResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iplizi6w.InlineAiEvent> rewrite(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    _ionqjjsu.SlidesAiRewriteRequest request,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iplizi6w.InlineAiEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'slidesAi',
              method: 'rewrite',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'slidesAi',
              methodName: 'rewrite',
              arguments: {
                'itemUuid': itemUuid,
                'request': _idc.jsonDecode(
                  _is.SerializationManager.encode(request),
                ),
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<List<_iug1yx01.SlidesAiNote>> writeNotes(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    List<String> slideIds,
    String length,
    String style,
    String mode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesAi',
            method: 'writeNotes',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesAi',
          methodName: 'writeNotes',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'slideIds': slideIds,
            'length': length,
            'style': style,
            'mode': mode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iug1yx01.SlidesAiNote>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iqoob7q4.SlidesAiAltText>> describeElements(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    List<String> elementIds,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesAi',
            method: 'describeElements',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesAi',
          methodName: 'describeElements',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'elementIds': elementIds,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iqoob7q4.SlidesAiAltText>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ixtuoo5p.SlidesAiDesignRank>> rankDesigns(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String slideId,
    List<String> candidates,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesAi',
            method: 'rankDesigns',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesAi',
          methodName: 'rankDesigns',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'slideId': slideId,
            'candidates': candidates,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ixtuoo5p.SlidesAiDesignRank>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipuzdgjy.SlidesAiPreview> getPreview(
    _ist.TestSessionBuilder sessionBuilder,
    String previewId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesAi',
            method: 'getPreview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesAi',
          methodName: 'getPreview',
          parameters: _ist.testObjectToJson({'previewId': previewId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipuzdgjy.SlidesAiPreview>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iok1gsl7.SlidesAiApplyResult> applyPreview(
    _ist.TestSessionBuilder sessionBuilder,
    String previewId,
    List<String>? callIds,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesAi',
            method: 'applyPreview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesAi',
          methodName: 'applyPreview',
          parameters: _ist.testObjectToJson({
            'previewId': previewId,
            'callIds': callIds,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iok1gsl7.SlidesAiApplyResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> discardPreview(
    _ist.TestSessionBuilder sessionBuilder,
    String previewId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesAi',
            method: 'discardPreview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesAi',
          methodName: 'discardPreview',
          parameters: _ist.testObjectToJson({'previewId': previewId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SlidesChartsEndpoint {
  _SlidesChartsEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ippij8zo.ChartSourceList> listCharts(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesCharts',
            method: 'listCharts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesCharts',
          methodName: 'listCharts',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ippij8zo.ChartSourceList>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iapx01g6.ChartSnapshotView> resolveSnapshot(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue spreadsheetUuid,
    String chartObjectId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesCharts',
            method: 'resolveSnapshot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesCharts',
          methodName: 'resolveSnapshot',
          parameters: _ist.testObjectToJson({
            'spreadsheetUuid': spreadsheetUuid,
            'chartObjectId': chartObjectId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iapx01g6.ChartSnapshotView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_imx2esrl.ChartLinkStatus>> checkLinks(
    _ist.TestSessionBuilder sessionBuilder,
    List<_izmhos0v.ChartLinkProbe> probes,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesCharts',
            method: 'checkLinks',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesCharts',
          methodName: 'checkLinks',
          parameters: _ist.testObjectToJson({'probes': probes}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_imx2esrl.ChartLinkStatus>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SlidesDocEndpoint {
  _SlidesDocEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Stream<_ifa159qn.RevServerMessage> connect(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    int knownRevision,
    String tabId,
    _ida.Stream<_iv4mnr49.RevClientMessage> input,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_ifa159qn.RevServerMessage>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'slidesDoc',
              method: 'connect',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'slidesDoc',
              methodName: 'connect',
              arguments: {
                'fileUuid': fileUuid,
                'knownRevision': knownRevision,
                'tabId': tabId,
              },
              requestedInputStreams: ['input'],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {'input': input},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_i4qoa0fo.RevPage> page(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    _iynxab9u.RevPageRequest request,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesDoc',
            method: 'page',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesDoc',
          methodName: 'page',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'request': request,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i4qoa0fo.RevPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iu7aww0d.RevOpView>> ops(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
    int fromRevision,
    int toRevision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesDoc',
            method: 'ops',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesDoc',
          methodName: 'ops',
          parameters: _ist.testObjectToJson({
            'fileUuid': fileUuid,
            'fromRevision': fromRevision,
            'toRevision': toRevision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iu7aww0d.RevOpView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iwjfjan3.RevFileInfo> info(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue fileUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesDoc',
            method: 'info',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesDoc',
          methodName: 'info',
          parameters: _ist.testObjectToJson({'fileUuid': fileUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iwjfjan3.RevFileInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SlidesEndpoint {
  _SlidesEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iqq3mn94.RevertResult> revertChange(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue changeId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slides',
            method: 'revertChange',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slides',
          methodName: 'revertChange',
          parameters: _ist.testObjectToJson({'changeId': changeId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iqq3mn94.RevertResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iqq3mn94.RevertResult> reapplyChange(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue changeId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slides',
            method: 'reapplyChange',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slides',
          methodName: 'reapplyChange',
          parameters: _ist.testObjectToJson({'changeId': changeId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iqq3mn94.RevertResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SlidesExportEndpoint {
  _SlidesExportEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ilqg61i8.ExportResultView> export(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String format,
    String optionsJson,
    int? revision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesExport',
            method: 'export',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesExport',
          methodName: 'export',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'format': format,
            'optionsJson': optionsJson,
            'revision': revision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ilqg61i8.ExportResultView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iqisbum6.ExportProgressEvent> exportWithProgress(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    String format,
    String optionsJson,
    int? revision,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iqisbum6.ExportProgressEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'slidesExport',
              method: 'exportWithProgress',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'slidesExport',
              methodName: 'exportWithProgress',
              arguments: {
                'itemUuid': itemUuid,
                'format': format,
                'optionsJson': optionsJson,
                'revision': revision,
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }
}

class _PresentationEndpoint {
  _PresentationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Stream<_ieyo7nqv.PresentationEvent> join(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue deckUuid,
    _ieucpeca.PresentationJoin join,
    _ida.Stream<_i0rcw8q1.PresentationUpdate> updates,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_ieyo7nqv.PresentationEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'presentation',
              method: 'join',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'presentation',
              methodName: 'join',
              arguments: {
                'deckUuid': deckUuid,
                'join': _idc.jsonDecode(_is.SerializationManager.encode(join)),
              },
              requestedInputStreams: ['updates'],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {'updates': updates},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_i3wfcxhm.PresentationSessionInfo?> findSession(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue deckUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'presentation',
            method: 'findSession',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'presentation',
          methodName: 'findSession',
          parameters: _ist.testObjectToJson({'deckUuid': deckUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i3wfcxhm.PresentationSessionInfo?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ienppxeb.PresentationPairingTarget?> resolvePairingCode(
    _ist.TestSessionBuilder sessionBuilder,
    String code,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'presentation',
            method: 'resolvePairingCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'presentation',
          methodName: 'resolvePairingCode',
          parameters: _ist.testObjectToJson({'code': code}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ienppxeb.PresentationPairingTarget?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SlidesThemesEndpoint {
  _SlidesThemesEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String> list(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesThemes',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesThemes',
          methodName: 'list',
          parameters: _ist.testObjectToJson({'itemUuid': itemUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SlidesVersionEndpoint {
  _SlidesVersionEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String> changes(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int versionId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesVersion',
            method: 'changes',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesVersion',
          methodName: 'changes',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'versionId': versionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> makeCopy(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue itemUuid,
    int versionId,
    String name,
    _is.UuidValue? folderUuid,
    bool copyComments,
    bool copySharing,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'slidesVersion',
            method: 'makeCopy',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'slidesVersion',
          methodName: 'makeCopy',
          parameters: _ist.testObjectToJson({
            'itemUuid': itemUuid,
            'versionId': versionId,
            'name': name,
            'folderUuid': folderUuid,
            'copyComments': copyComments,
            'copySharing': copySharing,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _DocumentEndpoint {
  _DocumentEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Stream<_ih1nh1nq.DocServerMessage> connect(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    int knownRevision,
    _ida.Stream<_i64vpekp.DocClientMessage> input,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_ih1nh1nq.DocServerMessage>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'document',
              method: 'connect',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'document',
              methodName: 'connect',
              arguments: {
                'documentUuid': documentUuid,
                'knownRevision': knownRevision,
              },
              requestedInputStreams: ['input'],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {'input': input},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_ieznlrqc.DocumentInfo> getInfo(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'document',
            method: 'getInfo',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'document',
          methodName: 'getInfo',
          parameters: _ist.testObjectToJson({'documentUuid': documentUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ieznlrqc.DocumentInfo>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_icjb0pei.DocumentOpView>> getOps(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    int fromRevision,
    int toRevision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'document',
            method: 'getOps',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'document',
          methodName: 'getOps',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'fromRevision': fromRevision,
            'toRevision': toRevision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_icjb0pei.DocumentOpView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_icrmohm9.DocumentSnapshotView> getSnapshot(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    int? revision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'document',
            method: 'getSnapshot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'document',
          methodName: 'getSnapshot',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'revision': revision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_icrmohm9.DocumentSnapshotView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> updateMeta(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    _issank2j.DocumentMetaPatch patch,
    _is.UuidValue clientOpId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'document',
            method: 'updateMeta',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'document',
          methodName: 'updateMeta',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'patch': patch,
            'clientOpId': clientOpId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WriteExportEndpoint {
  _WriteExportEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ilqg61i8.ExportResultView> export(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    String format,
    String optionsJson,
    int? revision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeExport',
            method: 'export',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeExport',
          methodName: 'export',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'format': format,
            'optionsJson': optionsJson,
            'revision': revision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ilqg61i8.ExportResultView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Stream<_iqisbum6.ExportProgressEvent> exportWithProgress(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    String format,
    String optionsJson,
    int? revision,
  ) {
    var _localTestStreamManager =
        _ist.TestStreamManager<_iqisbum6.ExportProgressEvent>();
    _ist.callStreamFunctionAndHandleExceptions(
      () async {
        var _localUniqueSession =
            (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
              endpoint: 'writeExport',
              method: 'exportWithProgress',
            );
        var _localCallContext = await _endpointDispatch
            .getMethodStreamCallContext(
              createSessionCallback: (_) => _localUniqueSession,
              endpointPath: 'writeExport',
              methodName: 'exportWithProgress',
              arguments: {
                'documentUuid': documentUuid,
                'format': format,
                'optionsJson': optionsJson,
                'revision': revision,
              },
              requestedInputStreams: [],
              serializationManager: _serializationManager,
            );
        await _localTestStreamManager.callStreamMethod(
          _localCallContext,
          _localUniqueSession,
          {},
        );
      },
      _localTestStreamManager.outputStreamController,
    );
    return _localTestStreamManager.outputStreamController.stream;
  }

  _ida.Future<_i3qt51xn.ConvertForInsertResult> convertForInsert(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uploadId,
    String format,
    String optionsJson,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeExport',
            method: 'convertForInsert',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeExport',
          methodName: 'convertForInsert',
          parameters: _ist.testObjectToJson({
            'uploadId': uploadId,
            'format': format,
            'optionsJson': optionsJson,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i3qt51xn.ConvertForInsertResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt.ByteData> fetchImage(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    String src,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeExport',
            method: 'fetchImage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeExport',
          methodName: 'fetchImage',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'src': src,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt.ByteData>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WriteHistoryEndpoint {
  _WriteHistoryEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_i2bmzm01.WriteVersionDocument> getVersionDocument(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    int revision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeHistory',
            method: 'getVersionDocument',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeHistory',
          methodName: 'getVersionDocument',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'revision': revision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i2bmzm01.WriteVersionDocument>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_id5ij7u1.WriteDiffView> diff(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    int fromRevision,
    int toRevision,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeHistory',
            method: 'diff',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeHistory',
          methodName: 'diff',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'fromRevision': fromRevision,
            'toRevision': toRevision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_id5ij7u1.WriteDiffView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ir2w0lzm.ItemVersionView> createRestorePoint(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeHistory',
            method: 'createRestorePoint',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeHistory',
          methodName: 'createRestorePoint',
          parameters: _ist.testObjectToJson({'documentUuid': documentUuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ir2w0lzm.ItemVersionView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i8hd56jb.VersionRestoreResult> restore(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    int versionId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeHistory',
            method: 'restore',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeHistory',
          methodName: 'restore',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'versionId': versionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i8hd56jb.VersionRestoreResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ily3pmy5.DriveItemView> copyVersion(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue documentUuid,
    int versionId,
    String name,
    _is.UuidValue? parentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeHistory',
            method: 'copyVersion',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeHistory',
          methodName: 'copyVersion',
          parameters: _ist.testObjectToJson({
            'documentUuid': documentUuid,
            'versionId': versionId,
            'name': name,
            'parentUuid': parentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ily3pmy5.DriveItemView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WriteThemeEndpoint {
  _WriteThemeEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_ipbzt39t.WriteThemeView>> listBuiltins(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'listBuiltins',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'listBuiltins',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ipbzt39t.WriteThemeView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ipbzt39t.WriteThemeView>> listMine(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'listMine',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'listMine',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ipbzt39t.WriteThemeView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipbzt39t.WriteThemeView> get(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    _is.UuidValue? viaDocumentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'get',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'get',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'viaDocumentUuid': viaDocumentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipbzt39t.WriteThemeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ipbzt39t.WriteThemeView>> getMany(
    _ist.TestSessionBuilder sessionBuilder,
    List<_is.UuidValue> uuids,
    _is.UuidValue? viaDocumentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'getMany',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'getMany',
          parameters: _ist.testObjectToJson({
            'uuids': uuids,
            'viaDocumentUuid': viaDocumentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ipbzt39t.WriteThemeView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipbzt39t.WriteThemeView> create(
    _ist.TestSessionBuilder sessionBuilder,
    String name,
    String json,
    _is.UuidValue? basedOnUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'create',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'create',
          parameters: _ist.testObjectToJson({
            'name': name,
            'json': json,
            'basedOnUuid': basedOnUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipbzt39t.WriteThemeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipbzt39t.WriteThemeView> update(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    String json,
    int expectedVersion,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'update',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'update',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'json': json,
            'expectedVersion': expectedVersion,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipbzt39t.WriteThemeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipbzt39t.WriteThemeView> rename(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    String name,
    int expectedVersion,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'rename',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'rename',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'name': name,
            'expectedVersion': expectedVersion,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipbzt39t.WriteThemeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipbzt39t.WriteThemeView> duplicate(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    String name,
    _is.UuidValue? viaDocumentUuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'duplicate',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'duplicate',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'name': name,
            'viaDocumentUuid': viaDocumentUuid,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipbzt39t.WriteThemeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipbzt39t.WriteThemeView> delete(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'delete',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'delete',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipbzt39t.WriteThemeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ipbzt39t.WriteThemeView> restore(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'restore',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'restore',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ipbzt39t.WriteThemeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iu3gmhy1.WriteThemeRevisionView>> listRevisions(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'listRevisions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'listRevisions',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iu3gmhy1.WriteThemeRevisionView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iu3gmhy1.WriteThemeRevisionView> getRevision(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
    int version,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'getRevision',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'getRevision',
          parameters: _ist.testObjectToJson({
            'uuid': uuid,
            'version': version,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iu3gmhy1.WriteThemeRevisionView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> usage(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue uuid,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'writeTheme',
            method: 'usage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'writeTheme',
          methodName: 'usage',
          parameters: _ist.testObjectToJson({'uuid': uuid}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _BoardFutureCall {
  Future<void> triage(
    _ist.TestSessionBuilder sessionBuilder,
    int postId,
  ) async {
    var object = _ic65ofts.BoardFutureCallTriageModel(postId: postId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.BoardTriageFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> summarize(
    _ist.TestSessionBuilder sessionBuilder,
    int postId,
  ) async {
    var object = _ied218dm.BoardFutureCallSummarizeModel(postId: postId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.BoardSummarizeFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> writePrompt(
    _ist.TestSessionBuilder sessionBuilder,
    int taskId,
  ) async {
    var object = _if4770sx.BoardFutureCallWritePromptModel(taskId: taskId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.BoardWritePromptFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> sweep(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.BoardSweepFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _BoardGithubFutureCall {
  Future<void> handle(
    _ist.TestSessionBuilder sessionBuilder,
    String deliveryId,
  ) async {
    var object = _it2ybdc3.BoardGithubFutureCallHandleModel(
      deliveryId: deliveryId,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.BoardGithubHandleFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> review(
    _ist.TestSessionBuilder sessionBuilder,
    int prNumber,
    String headSha,
  ) async {
    var object = _iqologas.BoardGithubFutureCallReviewModel(
      prNumber: prNumber,
      headSha: headSha,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.BoardGithubReviewFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _FilePreviewFutureCall {
  Future<void> generate(
    _ist.TestSessionBuilder sessionBuilder,
    int itemId,
  ) async {
    var object = _ikj8bo9l.FilePreviewFutureCallGenerateModel(itemId: itemId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.FilePreviewGenerateFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _MaintenanceFutureCall {
  Future<void> captureVersions(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.MaintenanceCaptureVersionsFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> sendDigests(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.MaintenanceSendDigestsFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> cleanupFiles(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.MaintenanceCleanupFilesFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> revlogSweep(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.MaintenanceRevlogSweepFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> expireGrants(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.MaintenanceExpireGrantsFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> daily(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.MaintenanceDailyFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _NotificationEmailFutureCall {
  Future<void> send(
    _ist.TestSessionBuilder sessionBuilder,
    int notificationId,
  ) async {
    var object = _iuw2rc8h.NotificationEmailFutureCallSendModel(
      notificationId: notificationId,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.NotificationEmailSendFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _PublicationsFutureCall {
  Future<void> deliver(
    _ist.TestSessionBuilder sessionBuilder,
    int deliveryId,
  ) async {
    var object = _in0nsjwu.PublicationsFutureCallDeliverModel(
      deliveryId: deliveryId,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.PublicationsDeliverFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> sweep(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.PublicationsSweepFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _AclFutureCall {
  Future<void> fanOut(
    _ist.TestSessionBuilder sessionBuilder,
    int itemId,
    String kind,
    List<int> affectedUsers,
  ) async {
    var object = _ievi2fyc.AclFutureCallFanOutModel(
      itemId: itemId,
      kind: kind,
      affectedUsers: affectedUsers,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.AclFanOutFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _StorageFutureCall {
  Future<void> backfill(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.StorageBackfillFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> reconcile(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.StorageReconcileFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> refreshItemSize(
    _ist.TestSessionBuilder sessionBuilder,
    int itemId,
  ) async {
    var object = _i5g4dkd6.StorageFutureCallRefreshItemSizeModel(
      itemId: itemId,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.StorageRefreshItemSizeFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _ScriptSchedulerFutureCall {
  Future<void> tick(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.ScriptSchedulerTickFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> prune(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _iwslocjr.ScriptSchedulerPruneFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}
