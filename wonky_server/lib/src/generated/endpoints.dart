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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:wonky_server/src/generated/future_calls.dart' as _iwslocjr;
import 'package:wonky_server/src/generated/platform/ai/models/ai_provider.dart'
    as _i02m7u6n;
import 'package:wonky_server/src/generated/platform/ai/models/ai_quality.dart'
    as _idrzmvpg;
import 'package:wonky_server/src/generated/platform/ai/models/assistant_context_hints.dart'
    as _ixc2f7d5;
import 'package:wonky_server/src/generated/platform/ai/models/inline_ai_request.dart'
    as _i4c3y8bm;
import 'package:wonky_server/src/generated/platform/analytics/models/usage_app.dart'
    as _idlxfxe3;
import 'package:wonky_server/src/generated/platform/board/models/board_area.dart'
    as _i2y7swbd;
import 'package:wonky_server/src/generated/platform/board/models/board_flag_reason.dart'
    as _i0z7k09i;
import 'package:wonky_server/src/generated/platform/board/models/board_list_query.dart'
    as _i6z8cjbe;
import 'package:wonky_server/src/generated/platform/board/models/board_moderation_action.dart'
    as _iqqjetoq;
import 'package:wonky_server/src/generated/platform/board/models/board_post_draft.dart'
    as _i6ub5i5f;
import 'package:wonky_server/src/generated/platform/board/models/board_post_kind.dart'
    as _i5noao4s;
import 'package:wonky_server/src/generated/platform/board/models/board_review_section.dart'
    as _i6ojypp7;
import 'package:wonky_server/src/generated/platform/board/models/board_size.dart'
    as _ikq67o57;
import 'package:wonky_server/src/generated/platform/board/models/board_task_status.dart'
    as _ihypagkt;
import 'package:wonky_server/src/generated/platform/comments/comment_anchor_kind.dart'
    as _i384cqmz;
import 'package:wonky_server/src/generated/platform/comments/comment_filter.dart'
    as _i0f5nb76;
import 'package:wonky_server/src/generated/platform/common/access_role.dart'
    as _i9nsco4y;
import 'package:wonky_server/src/generated/platform/drive/drive_import_options.dart'
    as _iyihga8r;
import 'package:wonky_server/src/generated/platform/drive/drive_item_kind.dart'
    as _i0549mj7;
import 'package:wonky_server/src/generated/platform/drive/drive_list_filter.dart'
    as _iaoi0gn5;
import 'package:wonky_server/src/generated/platform/drive/drive_search_filters.dart'
    as _iub85lgd;
import 'package:wonky_server/src/generated/platform/drive/drive_sort.dart'
    as _il6plm80;
import 'package:wonky_server/src/generated/platform/drive/file_upload_request.dart'
    as _i6y6tdjl;
import 'package:wonky_server/src/generated/platform/drive/storage_list_filter.dart'
    as _i7yliwmh;
import 'package:wonky_server/src/generated/platform/drive/template_category.dart'
    as _inlkiawi;
import 'package:wonky_server/src/generated/platform/feedback/feedback_submission.dart'
    as _ira9srbn;
import 'package:wonky_server/src/generated/platform/files/stored_file_kind.dart'
    as _idhe6v6s;
import 'package:wonky_server/src/generated/platform/mcp/ui_bridge/ui_bridge_message.dart'
    as _is78z0de;
import 'package:wonky_server/src/generated/platform/presence/presence_update.dart'
    as _ipd65of1;
import 'package:wonky_server/src/generated/platform/publications/models/publication_input.dart'
    as _iy7hmxv3;
import 'package:wonky_server/src/generated/platform/publications/models/submission_values.dart'
    as _iwukrrmj;
import 'package:wonky_server/src/generated/platform/revlog/messages/rev_client_message.dart'
    as _iv4mnr49;
import 'package:wonky_server/src/generated/platform/revlog/models/rev_page_request.dart'
    as _iynxab9u;
import 'package:wonky_server/src/generated/platform/sharing/item_sharing_settings.dart'
    as _i55sl7s1;
import 'package:wonky_server/src/generated/platform/users/user_preferences_patch.dart'
    as _ingbfbma;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_ai_cell_request.dart'
    as _ifqit8uo;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_fill_row.dart'
    as _isuyxaqz;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_execution.dart'
    as _isf59hoo;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_execution_status.dart'
    as _icum4fx3;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_outline_request.dart'
    as _isfebja2;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_rewrite_request.dart'
    as _ionqjjsu;
import 'package:wonky_server/src/generated/slides/charts/models/chart_link_probe.dart'
    as _izmhos0v;
import 'package:wonky_server/src/generated/slides/present/models/presentation_join.dart'
    as _ieucpeca;
import 'package:wonky_server/src/generated/slides/present/models/presentation_update.dart'
    as _i0rcw8q1;
import 'package:wonky_server/src/generated/write/messages/doc_client_message.dart'
    as _i64vpekp;
import 'package:wonky_server/src/generated/write/models/document_meta_patch.dart'
    as _issank2j;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../platform/activity/activity_endpoint.dart' as _id6etezj;
import '../platform/ai/assistant_endpoint.dart' as _i8k7ge8b;
import '../platform/analytics/analytics_endpoint.dart' as _ihmj012r;
import '../platform/board/board_endpoint.dart' as _itoz815u;
import '../platform/comments/comment_endpoint.dart' as _iuwjzuw0;
import '../platform/drive/drive_endpoint.dart' as _ijanxtjh;
import '../platform/e2e/e2e_support_endpoint.dart' as _iqj5xom6;
import '../platform/feedback/feedback_endpoint.dart' as _i70eazm1;
import '../platform/files/file_endpoint.dart' as _iokth3bn;
import '../platform/mcp/ui_bridge/ui_bridge_endpoint.dart' as _ipb16bxt;
import '../platform/meta/meta_endpoint.dart' as _isistrmv;
import '../platform/notifications/notification_endpoint.dart' as _ia40tpv4;
import '../platform/presence/presence_endpoint.dart' as _iv7snmpw;
import '../platform/publications/publication_endpoint.dart' as _igj7692v;
import '../platform/publications/submission_endpoint.dart' as _i7uk3p1b;
import '../platform/sharing/sharing_endpoint.dart' as _itz30x9e;
import '../platform/users/access_token_endpoint.dart' as _iusd4uiv;
import '../platform/users/google_idp_endpoint.dart' as _i3henulz;
import '../platform/users/user_endpoint.dart' as _iwtyukq6;
import '../platform/versions/version_endpoint.dart' as _im6cm90k;
import '../sheets/ai/sheets_ai_endpoint.dart' as _i9apq23f;
import '../sheets/endpoints/sheets_doc_endpoint.dart' as _izwcpcmx;
import '../sheets/endpoints/sheets_endpoint.dart' as _izrkvdrt;
import '../sheets/imports/sheets_import_endpoint.dart' as _ixh3mo4r;
import '../sheets/scripts/script_endpoint.dart' as _in9oll5w;
import '../sheets/versions/sheets_version_endpoint.dart' as _izzz2y3b;
import '../slides/ai/slides_ai_endpoint.dart' as _iwzuobfk;
import '../slides/charts/slides_charts_endpoint.dart' as _iusodta9;
import '../slides/endpoints/slides_doc_endpoint.dart' as _ifxounnn;
import '../slides/endpoints/slides_endpoint.dart' as _i90mpuoj;
import '../slides/exports/slides_export_endpoint.dart' as _ipawej08;
import '../slides/present/presentation_endpoint.dart' as _irtlljai;
import '../slides/themes/slides_themes_endpoint.dart' as _ivwqk6th;
import '../slides/versions/slides_version_endpoint.dart' as _iuslkdly;
import '../write/endpoints/document_endpoint.dart' as _iiabxp2u;
import '../write/endpoints/write_export_endpoint.dart' as _ia4kadx2;
import '../write/endpoints/write_history_endpoint.dart' as _izdjh3zj;
import '../write/endpoints/write_theme_endpoint.dart' as _ii3xbyyg;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'activity': _id6etezj.ActivityEndpoint()
        ..initialize(
          server,
          'activity',
          null,
        ),
      'assistant': _i8k7ge8b.AssistantEndpoint()
        ..initialize(
          server,
          'assistant',
          null,
        ),
      'analytics': _ihmj012r.AnalyticsEndpoint()
        ..initialize(
          server,
          'analytics',
          null,
        ),
      'board': _itoz815u.BoardEndpoint()
        ..initialize(
          server,
          'board',
          null,
        ),
      'comment': _iuwjzuw0.CommentEndpoint()
        ..initialize(
          server,
          'comment',
          null,
        ),
      'drive': _ijanxtjh.DriveEndpoint()
        ..initialize(
          server,
          'drive',
          null,
        ),
      'e2eSupport': _iqj5xom6.E2eSupportEndpoint()
        ..initialize(
          server,
          'e2eSupport',
          null,
        ),
      'feedback': _i70eazm1.FeedbackEndpoint()
        ..initialize(
          server,
          'feedback',
          null,
        ),
      'file': _iokth3bn.FileEndpoint()
        ..initialize(
          server,
          'file',
          null,
        ),
      'uiBridge': _ipb16bxt.UiBridgeEndpoint()
        ..initialize(
          server,
          'uiBridge',
          null,
        ),
      'meta': _isistrmv.MetaEndpoint()
        ..initialize(
          server,
          'meta',
          null,
        ),
      'notification': _ia40tpv4.NotificationEndpoint()
        ..initialize(
          server,
          'notification',
          null,
        ),
      'presence': _iv7snmpw.PresenceEndpoint()
        ..initialize(
          server,
          'presence',
          null,
        ),
      'publication': _igj7692v.PublicationEndpoint()
        ..initialize(
          server,
          'publication',
          null,
        ),
      'submission': _i7uk3p1b.SubmissionEndpoint()
        ..initialize(
          server,
          'submission',
          null,
        ),
      'sharing': _itz30x9e.SharingEndpoint()
        ..initialize(
          server,
          'sharing',
          null,
        ),
      'accessToken': _iusd4uiv.AccessTokenEndpoint()
        ..initialize(
          server,
          'accessToken',
          null,
        ),
      'googleIdp': _i3henulz.GoogleIdpEndpoint()
        ..initialize(
          server,
          'googleIdp',
          null,
        ),
      'user': _iwtyukq6.UserEndpoint()
        ..initialize(
          server,
          'user',
          null,
        ),
      'version': _im6cm90k.VersionEndpoint()
        ..initialize(
          server,
          'version',
          null,
        ),
      'sheetsAi': _i9apq23f.SheetsAiEndpoint()
        ..initialize(
          server,
          'sheetsAi',
          null,
        ),
      'sheetsDoc': _izwcpcmx.SheetsDocEndpoint()
        ..initialize(
          server,
          'sheetsDoc',
          null,
        ),
      'sheets': _izrkvdrt.SheetsEndpoint()
        ..initialize(
          server,
          'sheets',
          null,
        ),
      'sheetsImport': _ixh3mo4r.SheetsImportEndpoint()
        ..initialize(
          server,
          'sheetsImport',
          null,
        ),
      'script': _in9oll5w.ScriptEndpoint()
        ..initialize(
          server,
          'script',
          null,
        ),
      'sheetsVersion': _izzz2y3b.SheetsVersionEndpoint()
        ..initialize(
          server,
          'sheetsVersion',
          null,
        ),
      'slidesAi': _iwzuobfk.SlidesAiEndpoint()
        ..initialize(
          server,
          'slidesAi',
          null,
        ),
      'slidesCharts': _iusodta9.SlidesChartsEndpoint()
        ..initialize(
          server,
          'slidesCharts',
          null,
        ),
      'slidesDoc': _ifxounnn.SlidesDocEndpoint()
        ..initialize(
          server,
          'slidesDoc',
          null,
        ),
      'slides': _i90mpuoj.SlidesEndpoint()
        ..initialize(
          server,
          'slides',
          null,
        ),
      'slidesExport': _ipawej08.SlidesExportEndpoint()
        ..initialize(
          server,
          'slidesExport',
          null,
        ),
      'presentation': _irtlljai.PresentationEndpoint()
        ..initialize(
          server,
          'presentation',
          null,
        ),
      'slidesThemes': _ivwqk6th.SlidesThemesEndpoint()
        ..initialize(
          server,
          'slidesThemes',
          null,
        ),
      'slidesVersion': _iuslkdly.SlidesVersionEndpoint()
        ..initialize(
          server,
          'slidesVersion',
          null,
        ),
      'document': _iiabxp2u.DocumentEndpoint()
        ..initialize(
          server,
          'document',
          null,
        ),
      'writeExport': _ia4kadx2.WriteExportEndpoint()
        ..initialize(
          server,
          'writeExport',
          null,
        ),
      'writeHistory': _izdjh3zj.WriteHistoryEndpoint()
        ..initialize(
          server,
          'writeHistory',
          null,
        ),
      'writeTheme': _ii3xbyyg.WriteThemeEndpoint()
        ..initialize(
          server,
          'writeTheme',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['activity'] = _is.EndpointConnector(
      name: 'activity',
      endpoint: endpoints['activity']!,
      methodConnectors: {
        'dashboard': _is.MethodConnector(
          name: 'dashboard',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'days': _is.ParameterDescription(
              name: 'days',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['activity'] as _id6etezj.ActivityEndpoint)
                  .dashboard(
                    session,
                    params['itemUuid'],
                    params['days'],
                  ),
        ),
        'showViewHistory': _is.MethodConnector(
          name: 'showViewHistory',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['activity'] as _id6etezj.ActivityEndpoint)
                  .showViewHistory(session),
        ),
        'setShowViewHistory': _is.MethodConnector(
          name: 'setShowViewHistory',
          params: {
            'show': _is.ParameterDescription(
              name: 'show',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['activity'] as _id6etezj.ActivityEndpoint)
                  .setShowViewHistory(
                    session,
                    params['show'],
                  ),
        ),
      },
    );
    connectors['assistant'] = _is.EndpointConnector(
      name: 'assistant',
      endpoint: endpoints['assistant']!,
      methodConnectors: {
        'getStatus': _is.MethodConnector(
          name: 'getStatus',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .getStatus(session),
        ),
        'setQuality': _is.MethodConnector(
          name: 'setQuality',
          params: {
            'quality': _is.ParameterDescription(
              name: 'quality',
              type: _is.getType<_idrzmvpg.AiQuality>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .setQuality(
                    session,
                    params['quality'],
                  ),
        ),
        'setProviderKey': _is.MethodConnector(
          name: 'setProviderKey',
          params: {
            'provider': _is.ParameterDescription(
              name: 'provider',
              type: _is.getType<_i02m7u6n.AiProvider>(),
              nullable: false,
            ),
            'apiKey': _is.ParameterDescription(
              name: 'apiKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .setProviderKey(
                    session,
                    params['provider'],
                    params['apiKey'],
                  ),
        ),
        'removeProviderKey': _is.MethodConnector(
          name: 'removeProviderKey',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .removeProviderKey(session),
        ),
        'stop': _is.MethodConnector(
          name: 'stop',
          params: {
            'threadId': _is.ParameterDescription(
              name: 'threadId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'runId': _is.ParameterDescription(
              name: 'runId',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint).stop(
                    session,
                    params['threadId'],
                    params['runId'],
                  ),
        ),
        'confirm': _is.MethodConnector(
          name: 'confirm',
          params: {
            'runId': _is.ParameterDescription(
              name: 'runId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'confirmationId': _is.ParameterDescription(
              name: 'confirmationId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'allow': _is.ParameterDescription(
              name: 'allow',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .confirm(
                    session,
                    params['runId'],
                    params['confirmationId'],
                    params['allow'],
                  ),
        ),
        'uiToolResult': _is.MethodConnector(
          name: 'uiToolResult',
          params: {
            'runId': _is.ParameterDescription(
              name: 'runId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'response': _is.ParameterDescription(
              name: 'response',
              type: _is.getType<_is78z0de.UiBridgeResponse>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .uiToolResult(
                    session,
                    params['runId'],
                    params['response'],
                  ),
        ),
        'listThreads': _is.MethodConnector(
          name: 'listThreads',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .listThreads(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'getThread': _is.MethodConnector(
          name: 'getThread',
          params: {
            'threadId': _is.ParameterDescription(
              name: 'threadId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .getThread(
                    session,
                    params['threadId'],
                  ),
        ),
        'deleteThread': _is.MethodConnector(
          name: 'deleteThread',
          params: {
            'threadId': _is.ParameterDescription(
              name: 'threadId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .deleteThread(
                    session,
                    params['threadId'],
                  ),
        ),
        'clearHistory': _is.MethodConnector(
          name: 'clearHistory',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .clearHistory(session),
        ),
        'revertChange': _is.MethodConnector(
          name: 'revertChange',
          params: {
            'changeId': _is.ParameterDescription(
              name: 'changeId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .revertChange(
                    session,
                    params['changeId'],
                  ),
        ),
        'chat': _is.MethodStreamConnector(
          name: 'chat',
          params: {
            'threadId': _is.ParameterDescription(
              name: 'threadId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'message': _is.ParameterDescription(
              name: 'message',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'hints': _is.ParameterDescription(
              name: 'hints',
              type: _is.getType<_ixc2f7d5.AssistantContextHints>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint).chat(
                session,
                params['threadId'],
                params['itemUuid'],
                params['message'],
                params['hints'],
              ),
        ),
        'inline': _is.MethodStreamConnector(
          name: 'inline',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i4c3y8bm.InlineAiRequest>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .inline(
                    session,
                    params['request'],
                  ),
        ),
        'proofread': _is.MethodStreamConnector(
          name: 'proofread',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'start': _is.ParameterDescription(
              name: 'start',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'length': _is.ParameterDescription(
              name: 'length',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['assistant'] as _i8k7ge8b.AssistantEndpoint)
                  .proofread(
                    session,
                    params['itemUuid'],
                    params['start'],
                    params['length'],
                  ),
        ),
      },
    );
    connectors['analytics'] = _is.EndpointConnector(
      name: 'analytics',
      endpoint: endpoints['analytics']!,
      methodConnectors: {
        'ping': _is.MethodConnector(
          name: 'ping',
          params: {
            'app': _is.ParameterDescription(
              name: 'app',
              type: _is.getType<_idlxfxe3.UsageApp>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['analytics'] as _ihmj012r.AnalyticsEndpoint).ping(
                    session,
                    params['app'],
                  ),
        ),
        'overview': _is.MethodConnector(
          name: 'overview',
          params: {
            'days': _is.ParameterDescription(
              name: 'days',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'includeAdmins': _is.ParameterDescription(
              name: 'includeAdmins',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['analytics'] as _ihmj012r.AnalyticsEndpoint)
                  .overview(
                    session,
                    params['days'],
                    params['includeAdmins'],
                  ),
        ),
      },
    );
    connectors['board'] = _is.EndpointConnector(
      name: 'board',
      endpoint: endpoints['board']!,
      methodConnectors: {
        'me': _is.MethodConnector(
          name: 'me',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).me(session),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'query': _is.ParameterDescription(
              name: 'query',
              type: _is.getType<_i6z8cjbe.BoardListQuery>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint).list(
                session,
                params['query'],
              ),
        ),
        'counts': _is.MethodConnector(
          name: 'counts',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint).counts(
                session,
              ),
        ),
        'getPost': _is.MethodConnector(
          name: 'getPost',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).getPost(
                    session,
                    params['number'],
                  ),
        ),
        'listComments': _is.MethodConnector(
          name: 'listComments',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).listComments(
                    session,
                    params['number'],
                  ),
        ),
        'listTaskComments': _is.MethodConnector(
          name: 'listTaskComments',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .listTaskComments(
                    session,
                    params['number'],
                  ),
        ),
        'similar': _is.MethodConnector(
          name: 'similar',
          params: {
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_i5noao4s.BoardPostKind?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).similar(
                    session,
                    params['title'],
                    params['body'],
                    params['kind'],
                  ),
        ),
        'getScreenshotUrl': _is.MethodConnector(
          name: 'getScreenshotUrl',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .getScreenshotUrl(
                    session,
                    params['number'],
                  ),
        ),
        'listTasks': _is.MethodConnector(
          name: 'listTasks',
          params: {
            'statuses': _is.ParameterDescription(
              name: 'statuses',
              type: _is.getType<List<_ihypagkt.BoardTaskStatus>>(),
              nullable: false,
            ),
            'cursor': _is.ParameterDescription(
              name: 'cursor',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).listTasks(
                    session,
                    params['statuses'],
                    params['cursor'],
                    params['limit'],
                  ),
        ),
        'getTask': _is.MethodConnector(
          name: 'getTask',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).getTask(
                    session,
                    params['number'],
                  ),
        ),
        'createScreenshotUpload': _is.MethodConnector(
          name: 'createScreenshotUpload',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'mimeType': _is.ParameterDescription(
              name: 'mimeType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'size': _is.ParameterDescription(
              name: 'size',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .createScreenshotUpload(
                    session,
                    params['fileUuid'],
                    params['mimeType'],
                    params['size'],
                  ),
        ),
        'createPost': _is.MethodConnector(
          name: 'createPost',
          params: {
            'draft': _is.ParameterDescription(
              name: 'draft',
              type: _is.getType<_i6ub5i5f.BoardPostDraft>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).createPost(
                    session,
                    params['draft'],
                  ),
        ),
        'editPost': _is.MethodConnector(
          name: 'editPost',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).editPost(
                    session,
                    params['number'],
                    params['title'],
                    params['body'],
                  ),
        ),
        'deletePost': _is.MethodConnector(
          name: 'deletePost',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).deletePost(
                    session,
                    params['number'],
                  ),
        ),
        'restorePost': _is.MethodConnector(
          name: 'restorePost',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).restorePost(
                    session,
                    params['number'],
                  ),
        ),
        'removeScreenshot': _is.MethodConnector(
          name: 'removeScreenshot',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .removeScreenshot(
                    session,
                    params['number'],
                  ),
        ),
        'vote': _is.MethodConnector(
          name: 'vote',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint).vote(
                session,
                params['number'],
                params['value'],
              ),
        ),
        'addComment': _is.MethodConnector(
          name: 'addComment',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'postNumber': _is.ParameterDescription(
              name: 'postNumber',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'taskNumber': _is.ParameterDescription(
              name: 'taskNumber',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).addComment(
                    session,
                    params['uuid'],
                    params['postNumber'],
                    params['taskNumber'],
                    params['body'],
                  ),
        ),
        'editComment': _is.MethodConnector(
          name: 'editComment',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).editComment(
                    session,
                    params['uuid'],
                    params['body'],
                  ),
        ),
        'deleteComment': _is.MethodConnector(
          name: 'deleteComment',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).deleteComment(
                    session,
                    params['uuid'],
                  ),
        ),
        'restoreComment': _is.MethodConnector(
          name: 'restoreComment',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .restoreComment(
                    session,
                    params['uuid'],
                  ),
        ),
        'flag': _is.MethodConnector(
          name: 'flag',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'commentUuid': _is.ParameterDescription(
              name: 'commentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<_i0z7k09i.BoardFlagReason>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint).flag(
                session,
                params['number'],
                params['commentUuid'],
                params['reason'],
                params['note'],
              ),
        ),
        'unflag': _is.MethodConnector(
          name: 'unflag',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'commentUuid': _is.ParameterDescription(
              name: 'commentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint).unflag(
                session,
                params['number'],
                params['commentUuid'],
              ),
        ),
        'claimTask': _is.MethodConnector(
          name: 'claimTask',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).claimTask(
                    session,
                    params['number'],
                  ),
        ),
        'releaseTask': _is.MethodConnector(
          name: 'releaseTask',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).releaseTask(
                    session,
                    params['number'],
                  ),
        ),
        'reviewCounts': _is.MethodConnector(
          name: 'reviewCounts',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .reviewCounts(session),
        ),
        'reviewQueue': _is.MethodConnector(
          name: 'reviewQueue',
          params: {
            'section': _is.ParameterDescription(
              name: 'section',
              type: _is.getType<_i6ojypp7.BoardReviewSection>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).reviewQueue(
                    session,
                    params['section'],
                  ),
        ),
        'moderatePost': _is.MethodConnector(
          name: 'moderatePost',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'action': _is.ParameterDescription(
              name: 'action',
              type: _is.getType<_iqqjetoq.BoardModerationAction>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).moderatePost(
                    session,
                    params['number'],
                    params['action'],
                    params['reason'],
                  ),
        ),
        'moderateComment': _is.MethodConnector(
          name: 'moderateComment',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'action': _is.ParameterDescription(
              name: 'action',
              type: _is.getType<_iqqjetoq.BoardModerationAction>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .moderateComment(
                    session,
                    params['uuid'],
                    params['action'],
                    params['reason'],
                  ),
        ),
        'adminEditPost': _is.MethodConnector(
          name: 'adminEditPost',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).adminEditPost(
                    session,
                    params['number'],
                    params['title'],
                    params['body'],
                  ),
        ),
        'setLabels': _is.MethodConnector(
          name: 'setLabels',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_i5noao4s.BoardPostKind>(),
              nullable: false,
            ),
            'area': _is.ParameterDescription(
              name: 'area',
              type: _is.getType<_i2y7swbd.BoardArea?>(),
              nullable: true,
            ),
            'size': _is.ParameterDescription(
              name: 'size',
              type: _is.getType<_ikq67o57.BoardSize?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).setLabels(
                    session,
                    params['number'],
                    params['kind'],
                    params['area'],
                    params['size'],
                  ),
        ),
        'applySuggestedTitle': _is.MethodConnector(
          name: 'applySuggestedTitle',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .applySuggestedTitle(
                    session,
                    params['number'],
                  ),
        ),
        'dismissDuplicateHint': _is.MethodConnector(
          name: 'dismissDuplicateHint',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .dismissDuplicateHint(
                    session,
                    params['number'],
                  ),
        ),
        'merge': _is.MethodConnector(
          name: 'merge',
          params: {
            'source': _is.ParameterDescription(
              name: 'source',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'target': _is.ParameterDescription(
              name: 'target',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint).merge(
                session,
                params['source'],
                params['target'],
              ),
        ),
        'unmerge': _is.MethodConnector(
          name: 'unmerge',
          params: {
            'source': _is.ParameterDescription(
              name: 'source',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).unmerge(
                    session,
                    params['source'],
                  ),
        ),
        'decline': _is.MethodConnector(
          name: 'decline',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).decline(
                    session,
                    params['number'],
                    params['reason'],
                  ),
        ),
        'reopen': _is.MethodConnector(
          name: 'reopen',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint).reopen(
                session,
                params['number'],
              ),
        ),
        'blockUser': _is.MethodConnector(
          name: 'blockUser',
          params: {
            'userId': _is.ParameterDescription(
              name: 'userId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'until': _is.ParameterDescription(
              name: 'until',
              type: _is.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).blockUser(
                    session,
                    params['userId'],
                    params['reason'],
                    params['until'],
                  ),
        ),
        'unblockUser': _is.MethodConnector(
          name: 'unblockUser',
          params: {
            'userId': _is.ParameterDescription(
              name: 'userId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).unblockUser(
                    session,
                    params['userId'],
                  ),
        ),
        'createTask': _is.MethodConnector(
          name: 'createTask',
          params: {
            'postNumbers': _is.ParameterDescription(
              name: 'postNumbers',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'area': _is.ParameterDescription(
              name: 'area',
              type: _is.getType<_i2y7swbd.BoardArea>(),
              nullable: false,
            ),
            'size': _is.ParameterDescription(
              name: 'size',
              type: _is.getType<_ikq67o57.BoardSize>(),
              nullable: false,
            ),
            'excludedComments': _is.ParameterDescription(
              name: 'excludedComments',
              type: _is.getType<List<_is.UuidValue>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).createTask(
                    session,
                    params['postNumbers'],
                    params['title'],
                    params['area'],
                    params['size'],
                    excludedComments: params['excludedComments'],
                  ),
        ),
        'updateTask': _is.MethodConnector(
          name: 'updateTask',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'area': _is.ParameterDescription(
              name: 'area',
              type: _is.getType<_i2y7swbd.BoardArea>(),
              nullable: false,
            ),
            'size': _is.ParameterDescription(
              name: 'size',
              type: _is.getType<_ikq67o57.BoardSize>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).updateTask(
                    session,
                    params['number'],
                    params['title'],
                    params['area'],
                    params['size'],
                  ),
        ),
        'setTaskPosts': _is.MethodConnector(
          name: 'setTaskPosts',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'postNumbers': _is.ParameterDescription(
              name: 'postNumbers',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).setTaskPosts(
                    session,
                    params['number'],
                    params['postNumbers'],
                  ),
        ),
        'mergeTasks': _is.MethodConnector(
          name: 'mergeTasks',
          params: {
            'numbers': _is.ParameterDescription(
              name: 'numbers',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'area': _is.ParameterDescription(
              name: 'area',
              type: _is.getType<_i2y7swbd.BoardArea>(),
              nullable: false,
            ),
            'size': _is.ParameterDescription(
              name: 'size',
              type: _is.getType<_ikq67o57.BoardSize>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).mergeTasks(
                    session,
                    params['numbers'],
                    params['title'],
                    params['area'],
                    params['size'],
                  ),
        ),
        'unmergeTasks': _is.MethodConnector(
          name: 'unmergeTasks',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).unmergeTasks(
                    session,
                    params['number'],
                  ),
        ),
        'regeneratePrompt': _is.MethodConnector(
          name: 'regeneratePrompt',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .regeneratePrompt(
                    session,
                    params['number'],
                  ),
        ),
        'setPrompt': _is.MethodConnector(
          name: 'setPrompt',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).setPrompt(
                    session,
                    params['number'],
                    params['body'],
                  ),
        ),
        'publishTask': _is.MethodConnector(
          name: 'publishTask',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).publishTask(
                    session,
                    params['number'],
                  ),
        ),
        'setTaskStatus': _is.MethodConnector(
          name: 'setTaskStatus',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'status': _is.ParameterDescription(
              name: 'status',
              type: _is.getType<_ihypagkt.BoardTaskStatus>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['board'] as _itoz815u.BoardEndpoint).setTaskStatus(
                    session,
                    params['number'],
                    params['status'],
                  ),
        ),
        'linkPullRequest': _is.MethodConnector(
          name: 'linkPullRequest',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'url': _is.ParameterDescription(
              name: 'url',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .linkPullRequest(
                    session,
                    params['number'],
                    params['url'],
                  ),
        ),
        'suggestBundles': _is.MethodConnector(
          name: 'suggestBundles',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .suggestBundles(session),
        ),
        'listSuggestions': _is.MethodConnector(
          name: 'listSuggestions',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .listSuggestions(session),
        ),
        'dismissSuggestion': _is.MethodConnector(
          name: 'dismissSuggestion',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['board'] as _itoz815u.BoardEndpoint)
                  .dismissSuggestion(
                    session,
                    params['id'],
                  ),
        ),
        'watchPost': _is.MethodStreamConnector(
          name: 'watchPost',
          params: {
            'number': _is.ParameterDescription(
              name: 'number',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['board'] as _itoz815u.BoardEndpoint).watchPost(
                session,
                params['number'],
              ),
        ),
        'watchTasks': _is.MethodStreamConnector(
          name: 'watchTasks',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['board'] as _itoz815u.BoardEndpoint).watchTasks(
                session,
              ),
        ),
      },
    );
    connectors['comment'] = _is.EndpointConnector(
      name: 'comment',
      endpoint: endpoints['comment']!,
      methodConnectors: {
        'listThreads': _is.MethodConnector(
          name: 'listThreads',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'filter': _is.ParameterDescription(
              name: 'filter',
              type: _is.getType<_i0f5nb76.CommentFilter>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['comment'] as _iuwjzuw0.CommentEndpoint)
                  .listThreads(
                    session,
                    params['itemUuid'],
                    params['filter'],
                  ),
        ),
        'getThread': _is.MethodConnector(
          name: 'getThread',
          params: {
            'threadUuid': _is.ParameterDescription(
              name: 'threadUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).getThread(
                    session,
                    params['threadUuid'],
                  ),
        ),
        'createThread': _is.MethodConnector(
          name: 'createThread',
          params: {
            'threadUuid': _is.ParameterDescription(
              name: 'threadUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'anchorKind': _is.ParameterDescription(
              name: 'anchorKind',
              type: _is.getType<_i384cqmz.CommentAnchorKind>(),
              nullable: false,
            ),
            'anchorJson': _is.ParameterDescription(
              name: 'anchorJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'quotedText': _is.ParameterDescription(
              name: 'quotedText',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'mentions': _is.ParameterDescription(
              name: 'mentions',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'assigneeId': _is.ParameterDescription(
              name: 'assigneeId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['comment'] as _iuwjzuw0.CommentEndpoint)
                  .createThread(
                    session,
                    params['threadUuid'],
                    params['itemUuid'],
                    params['anchorKind'],
                    params['anchorJson'],
                    params['quotedText'],
                    params['body'],
                    params['mentions'],
                    params['assigneeId'],
                  ),
        ),
        'reply': _is.MethodConnector(
          name: 'reply',
          params: {
            'threadUuid': _is.ParameterDescription(
              name: 'threadUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'mentions': _is.ParameterDescription(
              name: 'mentions',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'commentUuid': _is.ParameterDescription(
              name: 'commentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'assigneeId': _is.ParameterDescription(
              name: 'assigneeId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).reply(
                    session,
                    params['threadUuid'],
                    params['body'],
                    params['mentions'],
                    commentUuid: params['commentUuid'],
                    assigneeId: params['assigneeId'],
                  ),
        ),
        'edit': _is.MethodConnector(
          name: 'edit',
          params: {
            'commentId': _is.ParameterDescription(
              name: 'commentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'mentions': _is.ParameterDescription(
              name: 'mentions',
              type: _is.getType<List<int>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).edit(
                    session,
                    params['commentId'],
                    params['body'],
                    mentions: params['mentions'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'commentId': _is.ParameterDescription(
              name: 'commentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).delete(
                    session,
                    params['commentId'],
                  ),
        ),
        'deleteThread': _is.MethodConnector(
          name: 'deleteThread',
          params: {
            'threadUuid': _is.ParameterDescription(
              name: 'threadUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['comment'] as _iuwjzuw0.CommentEndpoint)
                  .deleteThread(
                    session,
                    params['threadUuid'],
                  ),
        ),
        'resolve': _is.MethodConnector(
          name: 'resolve',
          params: {
            'threadUuid': _is.ParameterDescription(
              name: 'threadUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).resolve(
                    session,
                    params['threadUuid'],
                  ),
        ),
        'reopen': _is.MethodConnector(
          name: 'reopen',
          params: {
            'threadUuid': _is.ParameterDescription(
              name: 'threadUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).reopen(
                    session,
                    params['threadUuid'],
                  ),
        ),
        'react': _is.MethodConnector(
          name: 'react',
          params: {
            'commentId': _is.ParameterDescription(
              name: 'commentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'emoji': _is.ParameterDescription(
              name: 'emoji',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).react(
                    session,
                    params['commentId'],
                    params['emoji'],
                  ),
        ),
        'updateAnchor': _is.MethodConnector(
          name: 'updateAnchor',
          params: {
            'threadUuid': _is.ParameterDescription(
              name: 'threadUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'anchorJson': _is.ParameterDescription(
              name: 'anchorJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'anchorKind': _is.ParameterDescription(
              name: 'anchorKind',
              type: _is.getType<_i384cqmz.CommentAnchorKind?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['comment'] as _iuwjzuw0.CommentEndpoint)
                  .updateAnchor(
                    session,
                    params['threadUuid'],
                    params['anchorJson'],
                    anchorKind: params['anchorKind'],
                  ),
        ),
        'watch': _is.MethodStreamConnector(
          name: 'watch',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['comment'] as _iuwjzuw0.CommentEndpoint).watch(
                session,
                params['itemUuid'],
              ),
        ),
      },
    );
    connectors['drive'] = _is.EndpointConnector(
      name: 'drive',
      endpoint: endpoints['drive']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'folderUuid': _is.ParameterDescription(
              name: 'folderUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'filter': _is.ParameterDescription(
              name: 'filter',
              type: _is.getType<_iaoi0gn5.DriveListFilter>(),
              nullable: false,
            ),
            'sort': _is.ParameterDescription(
              name: 'sort',
              type: _is.getType<_il6plm80.DriveSort>(),
              nullable: false,
            ),
            'cursor': _is.ParameterDescription(
              name: 'cursor',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).list(
                session,
                params['folderUuid'],
                params['filter'],
                params['sort'],
                params['cursor'],
                params['limit'],
              ),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).get(
                session,
                params['uuid'],
              ),
        ),
        'path': _is.MethodConnector(
          name: 'path',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).path(
                session,
                params['uuid'],
              ),
        ),
        'search': _is.MethodConnector(
          name: 'search',
          params: {
            'query': _is.ParameterDescription(
              name: 'query',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'filters': _is.ParameterDescription(
              name: 'filters',
              type: _is.getType<_iub85lgd.DriveSearchFilters>(),
              nullable: false,
            ),
            'cursor': _is.ParameterDescription(
              name: 'cursor',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).search(
                session,
                params['query'],
                params['filters'],
                params['cursor'],
                params['limit'],
              ),
        ),
        'createFolder': _is.MethodConnector(
          name: 'createFolder',
          params: {
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).createFolder(
                    session,
                    params['parentUuid'],
                    params['name'],
                  ),
        ),
        'createDocument': _is.MethodConnector(
          name: 'createDocument',
          params: {
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'templateUuid': _is.ParameterDescription(
              name: 'templateUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'initialMarkdown': _is.ParameterDescription(
              name: 'initialMarkdown',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .createDocument(
                    session,
                    params['parentUuid'],
                    params['name'],
                    params['templateUuid'],
                    params['initialMarkdown'],
                    documentUuid: params['documentUuid'],
                    itemUuid: params['itemUuid'],
                  ),
        ),
        'registerSpreadsheet': _is.MethodConnector(
          name: 'registerSpreadsheet',
          params: {
            'spaceUuid': _is.ParameterDescription(
              name: 'spaceUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .registerSpreadsheet(
                    session,
                    params['spaceUuid'],
                    params['parentUuid'],
                    params['name'],
                  ),
        ),
        'createSpreadsheet': _is.MethodConnector(
          name: 'createSpreadsheet',
          params: {
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'templateUuid': _is.ParameterDescription(
              name: 'templateUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'locale': _is.ParameterDescription(
              name: 'locale',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'timeZone': _is.ParameterDescription(
              name: 'timeZone',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .createSpreadsheet(
                    session,
                    params['parentUuid'],
                    params['name'],
                    params['templateUuid'],
                    locale: params['locale'],
                    timeZone: params['timeZone'],
                  ),
        ),
        'rename': _is.MethodConnector(
          name: 'rename',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).rename(
                session,
                params['uuid'],
                params['name'],
              ),
        ),
        'updateDescription': _is.MethodConnector(
          name: 'updateDescription',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'description': _is.ParameterDescription(
              name: 'description',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .updateDescription(
                    session,
                    params['uuid'],
                    params['description'],
                  ),
        ),
        'move': _is.MethodConnector(
          name: 'move',
          params: {
            'uuids': _is.ParameterDescription(
              name: 'uuids',
              type: _is.getType<List<_is.UuidValue>>(),
              nullable: false,
            ),
            'newParentUuid': _is.ParameterDescription(
              name: 'newParentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).move(
                session,
                params['uuids'],
                params['newParentUuid'],
              ),
        ),
        'copy': _is.MethodConnector(
          name: 'copy',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'newName': _is.ParameterDescription(
              name: 'newName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'copyComments': _is.ParameterDescription(
              name: 'copyComments',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'copySharing': _is.ParameterDescription(
              name: 'copySharing',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).copy(
                session,
                params['uuid'],
                params['newName'],
                params['parentUuid'],
                params['copyComments'],
                params['copySharing'],
              ),
        ),
        'setStarred': _is.MethodConnector(
          name: 'setStarred',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'starred': _is.ParameterDescription(
              name: 'starred',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).setStarred(
                    session,
                    params['uuid'],
                    params['starred'],
                  ),
        ),
        'setPinnedOffline': _is.MethodConnector(
          name: 'setPinnedOffline',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'pinned': _is.ParameterDescription(
              name: 'pinned',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .setPinnedOffline(
                    session,
                    params['uuid'],
                    params['pinned'],
                  ),
        ),
        'markOpened': _is.MethodConnector(
          name: 'markOpened',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).markOpened(
                    session,
                    params['uuid'],
                  ),
        ),
        'addShortcut': _is.MethodConnector(
          name: 'addShortcut',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).addShortcut(
                    session,
                    params['uuid'],
                    params['parentUuid'],
                  ),
        ),
        'removeShortcut': _is.MethodConnector(
          name: 'removeShortcut',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .removeShortcut(
                    session,
                    params['uuid'],
                  ),
        ),
        'trash': _is.MethodConnector(
          name: 'trash',
          params: {
            'uuids': _is.ParameterDescription(
              name: 'uuids',
              type: _is.getType<List<_is.UuidValue>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).trash(
                session,
                params['uuids'],
              ),
        ),
        'restore': _is.MethodConnector(
          name: 'restore',
          params: {
            'uuids': _is.ParameterDescription(
              name: 'uuids',
              type: _is.getType<List<_is.UuidValue>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).restore(
                    session,
                    params['uuids'],
                  ),
        ),
        'deletePermanently': _is.MethodConnector(
          name: 'deletePermanently',
          params: {
            'uuids': _is.ParameterDescription(
              name: 'uuids',
              type: _is.getType<List<_is.UuidValue>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .deletePermanently(
                    session,
                    params['uuids'],
                  ),
        ),
        'emptyTrash': _is.MethodConnector(
          name: 'emptyTrash',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .emptyTrash(session),
        ),
        'listTemplates': _is.MethodConnector(
          name: 'listTemplates',
          params: {
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_i0549mj7.DriveItemKind?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).listTemplates(
                    session,
                    params['kind'],
                  ),
        ),
        'setTemplate': _is.MethodConnector(
          name: 'setTemplate',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'category': _is.ParameterDescription(
              name: 'category',
              type: _is.getType<_inlkiawi.TemplateCategory?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).setTemplate(
                    session,
                    params['uuid'],
                    params['category'],
                  ),
        ),
        'import': _is.MethodConnector(
          name: 'import',
          params: {
            'uploadId': _is.ParameterDescription(
              name: 'uploadId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_i0549mj7.DriveItemKind>(),
              nullable: false,
            ),
            'options': _is.ParameterDescription(
              name: 'options',
              type: _is.getType<_iyihga8r.DriveImportOptions>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).import(
                session,
                params['uploadId'],
                params['kind'],
                params['options'],
              ),
        ),
        'registerPresentation': _is.MethodConnector(
          name: 'registerPresentation',
          params: {
            'spaceUuid': _is.ParameterDescription(
              name: 'spaceUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .registerPresentation(
                    session,
                    params['spaceUuid'],
                    params['parentUuid'],
                    params['name'],
                  ),
        ),
        'createPresentation': _is.MethodConnector(
          name: 'createPresentation',
          params: {
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'templateUuid': _is.ParameterDescription(
              name: 'templateUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'initialize': _is.ParameterDescription(
              name: 'initialize',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .createPresentation(
                    session,
                    params['parentUuid'],
                    params['name'],
                    params['templateUuid'],
                    fileUuid: params['fileUuid'],
                    initialize: params['initialize'],
                  ),
        ),
        'createFileUpload': _is.MethodConnector(
          name: 'createFileUpload',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_i6y6tdjl.FileUploadRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .createFileUpload(
                    session,
                    params['request'],
                  ),
        ),
        'completeFileUpload': _is.MethodConnector(
          name: 'completeFileUpload',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .completeFileUpload(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'cancelFileUpload': _is.MethodConnector(
          name: 'cancelFileUpload',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .cancelFileUpload(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'fileUploadStatus': _is.MethodConnector(
          name: 'fileUploadStatus',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .fileUploadStatus(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'convertFile': _is.MethodConnector(
          name: 'convertFile',
          params: {
            'fileItemUuid': _is.ParameterDescription(
              name: 'fileItemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'target': _is.ParameterDescription(
              name: 'target',
              type: _is.getType<_i0549mj7.DriveItemKind>(),
              nullable: false,
            ),
            'options': _is.ParameterDescription(
              name: 'options',
              type: _is.getType<_iyihga8r.DriveImportOptions>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).convertFile(
                    session,
                    params['fileItemUuid'],
                    params['target'],
                    params['options'],
                  ),
        ),
        'fileContentUrl': _is.MethodConnector(
          name: 'fileContentUrl',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'download': _is.ParameterDescription(
              name: 'download',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .fileContentUrl(
                    session,
                    params['itemUuid'],
                    download: params['download'],
                  ),
        ),
        'updateFileMeta': _is.MethodConnector(
          name: 'updateFileMeta',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'fileMetaJson': _is.ParameterDescription(
              name: 'fileMetaJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .updateFileMeta(
                    session,
                    params['itemUuid'],
                    params['fileMetaJson'],
                  ),
        ),
        'checkRoom': _is.MethodConnector(
          name: 'checkRoom',
          params: {
            'bytes': _is.ParameterDescription(
              name: 'bytes',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).checkRoom(
                    session,
                    params['bytes'],
                    params['itemUuid'],
                  ),
        ),
        'listByStorage': _is.MethodConnector(
          name: 'listByStorage',
          params: {
            'filter': _is.ParameterDescription(
              name: 'filter',
              type: _is.getType<_i7yliwmh.StorageListFilter>(),
              nullable: false,
            ),
            'cursor': _is.ParameterDescription(
              name: 'cursor',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).listByStorage(
                    session,
                    params['filter'],
                    params['cursor'],
                    params['limit'],
                  ),
        ),
        'storageUsage': _is.MethodConnector(
          name: 'storageUsage',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['drive'] as _ijanxtjh.DriveEndpoint)
                  .storageUsage(session),
        ),
        'setThumbnail': _is.MethodConnector(
          name: 'setThumbnail',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'uploadedFileUuid': _is.ParameterDescription(
              name: 'uploadedFileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).setThumbnail(
                    session,
                    params['uuid'],
                    params['uploadedFileUuid'],
                  ),
        ),
        'activity': _is.MethodConnector(
          name: 'activity',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'beforeId': _is.ParameterDescription(
              name: 'beforeId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['drive'] as _ijanxtjh.DriveEndpoint).activity(
                    session,
                    params['uuid'],
                    params['beforeId'],
                    params['limit'],
                  ),
        ),
        'watch': _is.MethodStreamConnector(
          name: 'watch',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['drive'] as _ijanxtjh.DriveEndpoint).watch(
                session,
              ),
        ),
      },
    );
    connectors['e2eSupport'] = _is.EndpointConnector(
      name: 'e2eSupport',
      endpoint: endpoints['e2eSupport']!,
      methodConnectors: {
        'latestVerificationCode': _is.MethodConnector(
          name: 'latestVerificationCode',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['e2eSupport'] as _iqj5xom6.E2eSupportEndpoint)
                      .latestVerificationCode(
                        session,
                        params['email'],
                      ),
        ),
        'latestPasswordResetCode': _is.MethodConnector(
          name: 'latestPasswordResetCode',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['e2eSupport'] as _iqj5xom6.E2eSupportEndpoint)
                      .latestPasswordResetCode(
                        session,
                        params['email'],
                      ),
        ),
      },
    );
    connectors['feedback'] = _is.EndpointConnector(
      name: 'feedback',
      endpoint: endpoints['feedback']!,
      methodConnectors: {
        'submit': _is.MethodConnector(
          name: 'submit',
          params: {
            'feedback': _is.ParameterDescription(
              name: 'feedback',
              type: _is.getType<_ira9srbn.FeedbackSubmission>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['feedback'] as _i70eazm1.FeedbackEndpoint).submit(
                    session,
                    params['feedback'],
                  ),
        ),
        'reportError': _is.MethodConnector(
          name: 'reportError',
          params: {
            'report': _is.ParameterDescription(
              name: 'report',
              type: _is.getType<_ira9srbn.FeedbackSubmission>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['feedback'] as _i70eazm1.FeedbackEndpoint)
                  .reportError(
                    session,
                    params['report'],
                  ),
        ),
      },
    );
    connectors['file'] = _is.EndpointConnector(
      name: 'file',
      endpoint: endpoints['file']!,
      methodConnectors: {
        'createUpload': _is.MethodConnector(
          name: 'createUpload',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'fileName': _is.ParameterDescription(
              name: 'fileName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'mimeType': _is.ParameterDescription(
              name: 'mimeType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'size': _is.ParameterDescription(
              name: 'size',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_idhe6v6s.StoredFileKind?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['file'] as _iokth3bn.FileEndpoint).createUpload(
                    session,
                    params['fileUuid'],
                    params['itemUuid'],
                    params['fileName'],
                    params['mimeType'],
                    params['size'],
                    kind: params['kind'],
                  ),
        ),
        'completeUpload': _is.MethodConnector(
          name: 'completeUpload',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['file'] as _iokth3bn.FileEndpoint).completeUpload(
                    session,
                    params['fileUuid'],
                  ),
        ),
        'getUrl': _is.MethodConnector(
          name: 'getUrl',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _iokth3bn.FileEndpoint).getUrl(
                session,
                params['fileUuid'],
              ),
        ),
        'copyToItem': _is.MethodConnector(
          name: 'copyToItem',
          params: {
            'sourceFileUuid': _is.ParameterDescription(
              name: 'sourceFileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'newFileUuid': _is.ParameterDescription(
              name: 'newFileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'targetItemUuid': _is.ParameterDescription(
              name: 'targetItemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['file'] as _iokth3bn.FileEndpoint).copyToItem(
                    session,
                    params['sourceFileUuid'],
                    params['newFileUuid'],
                    params['targetItemUuid'],
                  ),
        ),
        'fetchImage': _is.MethodConnector(
          name: 'fetchImage',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'url': _is.ParameterDescription(
              name: 'url',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['file'] as _iokth3bn.FileEndpoint).fetchImage(
                    session,
                    params['itemUuid'],
                    params['url'],
                  ),
        ),
        'getUrls': _is.MethodConnector(
          name: 'getUrls',
          params: {
            'fileUuids': _is.ParameterDescription(
              name: 'fileUuids',
              type: _is.getType<List<_is.UuidValue>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _iokth3bn.FileEndpoint).getUrls(
                session,
                params['fileUuids'],
              ),
        ),
      },
    );
    connectors['uiBridge'] = _is.EndpointConnector(
      name: 'uiBridge',
      endpoint: endpoints['uiBridge']!,
      methodConnectors: {
        'connect': _is.MethodStreamConnector(
          name: 'connect',
          params: {},
          streamParams: {
            'fromApp':
                _is.StreamParameterDescription<_is78z0de.UiBridgeMessage>(
                  name: 'fromApp',
                  nullable: false,
                ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['uiBridge'] as _ipb16bxt.UiBridgeEndpoint).connect(
                    session,
                    streamParams['fromApp']!.cast<_is78z0de.UiBridgeMessage>(),
                  ),
        ),
      },
    );
    connectors['meta'] = _is.EndpointConnector(
      name: 'meta',
      endpoint: endpoints['meta']!,
      methodConnectors: {
        'getInfo': _is.MethodConnector(
          name: 'getInfo',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['meta'] as _isistrmv.MetaEndpoint).getInfo(
                session,
              ),
        ),
      },
    );
    connectors['notification'] = _is.EndpointConnector(
      name: 'notification',
      endpoint: endpoints['notification']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'cursor': _is.ParameterDescription(
              name: 'cursor',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'unreadOnly': _is.ParameterDescription(
              name: 'unreadOnly',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _ia40tpv4.NotificationEndpoint)
                      .list(
                        session,
                        params['cursor'],
                        params['limit'],
                        params['unreadOnly'],
                      ),
        ),
        'unreadCount': _is.MethodConnector(
          name: 'unreadCount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _ia40tpv4.NotificationEndpoint)
                      .unreadCount(session),
        ),
        'markRead': _is.MethodConnector(
          name: 'markRead',
          params: {
            'ids': _is.ParameterDescription(
              name: 'ids',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _ia40tpv4.NotificationEndpoint)
                      .markRead(
                        session,
                        params['ids'],
                      ),
        ),
        'markAllRead': _is.MethodConnector(
          name: 'markAllRead',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['notification'] as _ia40tpv4.NotificationEndpoint)
                      .markAllRead(session),
        ),
        'watch': _is.MethodStreamConnector(
          name: 'watch',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['notification'] as _ia40tpv4.NotificationEndpoint)
                  .watch(session),
        ),
      },
    );
    connectors['presence'] = _is.EndpointConnector(
      name: 'presence',
      endpoint: endpoints['presence']!,
      methodConnectors: {
        'join': _is.MethodStreamConnector(
          name: 'join',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          streamParams: {
            'updates': _is.StreamParameterDescription<_ipd65of1.PresenceUpdate>(
              name: 'updates',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['presence'] as _iv7snmpw.PresenceEndpoint).join(
                session,
                params['itemUuid'],
                streamParams['updates']!.cast<_ipd65of1.PresenceUpdate>(),
              ),
        ),
      },
    );
    connectors['publication'] = _is.EndpointConnector(
      name: 'publication',
      endpoint: endpoints['publication']!,
      methodConnectors: {
        'resolve': _is.MethodConnector(
          name: 'resolve',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .resolve(
                        session,
                        params['publicId'],
                      ),
        ),
        'startSubmission': _is.MethodConnector(
          name: 'startSubmission',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'ref': _is.ParameterDescription(
              name: 'ref',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'agreed': _is.ParameterDescription(
              name: 'agreed',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .startSubmission(
                        session,
                        params['publicId'],
                        params['ref'],
                        params['agreed'],
                      ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .list(session),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'input': _is.ParameterDescription(
              name: 'input',
              type: _is.getType<_iy7hmxv3.PublicationInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .create(
                        session,
                        params['input'],
                      ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'input': _is.ParameterDescription(
              name: 'input',
              type: _is.getType<_iy7hmxv3.PublicationInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .update(
                        session,
                        params['publicId'],
                        params['input'],
                      ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .delete(
                        session,
                        params['publicId'],
                      ),
        ),
        'verify': _is.MethodConnector(
          name: 'verify',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .verify(
                        session,
                        params['publicId'],
                      ),
        ),
        'rotateSecret': _is.MethodConnector(
          name: 'rotateSecret',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .rotateSecret(
                        session,
                        params['publicId'],
                      ),
        ),
        'createApiKey': _is.MethodConnector(
          name: 'createApiKey',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .createApiKey(
                        session,
                        params['publicId'],
                      ),
        ),
        'setModerators': _is.MethodConnector(
          name: 'setModerators',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'emails': _is.ParameterDescription(
              name: 'emails',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .setModerators(
                        session,
                        params['publicId'],
                        params['emails'],
                      ),
        ),
        'deliveries': _is.MethodConnector(
          name: 'deliveries',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .deliveries(
                        session,
                        params['publicId'],
                      ),
        ),
        'resend': _is.MethodConnector(
          name: 'resend',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'webhookId': _is.ParameterDescription(
              name: 'webhookId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .resend(
                        session,
                        params['publicId'],
                        params['webhookId'],
                      ),
        ),
        'sendTest': _is.MethodConnector(
          name: 'sendTest',
          params: {
            'publicId': _is.ParameterDescription(
              name: 'publicId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['publication'] as _igj7692v.PublicationEndpoint)
                      .sendTest(
                        session,
                        params['publicId'],
                      ),
        ),
      },
    );
    connectors['submission'] = _is.EndpointConnector(
      name: 'submission',
      endpoint: endpoints['submission']!,
      methodConnectors: {
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['submission'] as _i7uk3p1b.SubmissionEndpoint).get(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'submit': _is.MethodConnector(
          name: 'submit',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'values': _is.ParameterDescription(
              name: 'values',
              type: _is.getType<_iwukrrmj.SubmissionValues>(),
              nullable: false,
            ),
            'agreed': _is.ParameterDescription(
              name: 'agreed',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['submission'] as _i7uk3p1b.SubmissionEndpoint)
                      .submit(
                        session,
                        params['itemUuid'],
                        params['values'],
                        params['agreed'],
                      ),
        ),
        'withdraw': _is.MethodConnector(
          name: 'withdraw',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['submission'] as _i7uk3p1b.SubmissionEndpoint)
                      .withdraw(
                        session,
                        params['itemUuid'],
                      ),
        ),
        'disconnect': _is.MethodConnector(
          name: 'disconnect',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['submission'] as _i7uk3p1b.SubmissionEndpoint)
                      .disconnect(
                        session,
                        params['itemUuid'],
                      ),
        ),
        'reconnect': _is.MethodConnector(
          name: 'reconnect',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['submission'] as _i7uk3p1b.SubmissionEndpoint)
                      .reconnect(
                        session,
                        params['itemUuid'],
                      ),
        ),
      },
    );
    connectors['sharing'] = _is.EndpointConnector(
      name: 'sharing',
      endpoint: endpoints['sharing']!,
      methodConnectors: {
        'getSharing': _is.MethodConnector(
          name: 'getSharing',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .getSharing(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'share': _is.MethodConnector(
          name: 'share',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'emails': _is.ParameterDescription(
              name: 'emails',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_i9nsco4y.AccessRole>(),
              nullable: false,
            ),
            'notify': _is.ParameterDescription(
              name: 'notify',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'message': _is.ParameterDescription(
              name: 'message',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'expiresAt': _is.ParameterDescription(
              name: 'expiresAt',
              type: _is.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sharing'] as _itz30x9e.SharingEndpoint).share(
                    session,
                    params['itemUuid'],
                    params['emails'],
                    params['role'],
                    params['notify'],
                    params['message'],
                    params['expiresAt'],
                  ),
        ),
        'updateRole': _is.MethodConnector(
          name: 'updateRole',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'userId': _is.ParameterDescription(
              name: 'userId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_i9nsco4y.AccessRole>(),
              nullable: false,
            ),
            'expiresAt': _is.ParameterDescription(
              name: 'expiresAt',
              type: _is.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .updateRole(
                    session,
                    params['itemUuid'],
                    params['userId'],
                    params['role'],
                    expiresAt: params['expiresAt'],
                  ),
        ),
        'remove': _is.MethodConnector(
          name: 'remove',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'userId': _is.ParameterDescription(
              name: 'userId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'invitedEmail': _is.ParameterDescription(
              name: 'invitedEmail',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sharing'] as _itz30x9e.SharingEndpoint).remove(
                    session,
                    params['itemUuid'],
                    params['userId'],
                    invitedEmail: params['invitedEmail'],
                  ),
        ),
        'transferOwnership': _is.MethodConnector(
          name: 'transferOwnership',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'newOwnerUserId': _is.ParameterDescription(
              name: 'newOwnerUserId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .transferOwnership(
                    session,
                    params['itemUuid'],
                    params['newOwnerUserId'],
                  ),
        ),
        'respondToOwnershipTransfer': _is.MethodConnector(
          name: 'respondToOwnershipTransfer',
          params: {
            'transferId': _is.ParameterDescription(
              name: 'transferId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'accept': _is.ParameterDescription(
              name: 'accept',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .respondToOwnershipTransfer(
                    session,
                    params['transferId'],
                    params['accept'],
                  ),
        ),
        'setLink': _is.MethodConnector(
          name: 'setLink',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_i9nsco4y.AccessRole?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sharing'] as _itz30x9e.SharingEndpoint).setLink(
                    session,
                    params['itemUuid'],
                    params['role'],
                  ),
        ),
        'rotateLink': _is.MethodConnector(
          name: 'rotateLink',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .rotateLink(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'updateSettings': _is.MethodConnector(
          name: 'updateSettings',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'settings': _is.ParameterDescription(
              name: 'settings',
              type: _is.getType<_i55sl7s1.ItemSharingSettings>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .updateSettings(
                    session,
                    params['itemUuid'],
                    params['settings'],
                  ),
        ),
        'requestAccess': _is.MethodConnector(
          name: 'requestAccess',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_i9nsco4y.AccessRole>(),
              nullable: false,
            ),
            'message': _is.ParameterDescription(
              name: 'message',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .requestAccess(
                    session,
                    params['itemUuid'],
                    params['role'],
                    params['message'],
                  ),
        ),
        'handleAccessRequest': _is.MethodConnector(
          name: 'handleAccessRequest',
          params: {
            'requestId': _is.ParameterDescription(
              name: 'requestId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'approve': _is.ParameterDescription(
              name: 'approve',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_i9nsco4y.AccessRole?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .handleAccessRequest(
                    session,
                    params['requestId'],
                    params['approve'],
                    params['role'],
                  ),
        ),
        'resolveInvite': _is.MethodConnector(
          name: 'resolveInvite',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sharing'] as _itz30x9e.SharingEndpoint)
                  .resolveInvite(
                    session,
                    params['token'],
                  ),
        ),
      },
    );
    connectors['accessToken'] = _is.EndpointConnector(
      name: 'accessToken',
      endpoint: endpoints['accessToken']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['accessToken'] as _iusd4uiv.AccessTokenEndpoint)
                      .list(session),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'scopes': _is.ParameterDescription(
              name: 'scopes',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'expiresAt': _is.ParameterDescription(
              name: 'expiresAt',
              type: _is.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['accessToken'] as _iusd4uiv.AccessTokenEndpoint)
                      .create(
                        session,
                        params['name'],
                        params['scopes'],
                        params['expiresAt'],
                      ),
        ),
        'revoke': _is.MethodConnector(
          name: 'revoke',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['accessToken'] as _iusd4uiv.AccessTokenEndpoint)
                      .revoke(
                        session,
                        params['id'],
                      ),
        ),
      },
    );
    connectors['googleIdp'] = _is.EndpointConnector(
      name: 'googleIdp',
      endpoint: endpoints['googleIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'idToken': _is.ParameterDescription(
              name: 'idToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'accessToken': _is.ParameterDescription(
              name: 'accessToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['googleIdp'] as _i3henulz.GoogleIdpEndpoint).login(
                    session,
                    idToken: params['idToken'],
                    accessToken: params['accessToken'],
                  ),
        ),
        'loginWithCode': _is.MethodConnector(
          name: 'loginWithCode',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'codeVerifier': _is.ParameterDescription(
              name: 'codeVerifier',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'redirectUri': _is.ParameterDescription(
              name: 'redirectUri',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['googleIdp'] as _i3henulz.GoogleIdpEndpoint)
                  .loginWithCode(
                    session,
                    code: params['code'],
                    codeVerifier: params['codeVerifier'],
                    redirectUri: params['redirectUri'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['googleIdp'] as _i3henulz.GoogleIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['user'] = _is.EndpointConnector(
      name: 'user',
      endpoint: endpoints['user']!,
      methodConnectors: {
        'getMe': _is.MethodConnector(
          name: 'getMe',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['user'] as _iwtyukq6.UserEndpoint).getMe(session),
        ),
        'updateProfile': _is.MethodConnector(
          name: 'updateProfile',
          params: {
            'displayName': _is.ParameterDescription(
              name: 'displayName',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'locale': _is.ParameterDescription(
              name: 'locale',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'timeZone': _is.ParameterDescription(
              name: 'timeZone',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['user'] as _iwtyukq6.UserEndpoint).updateProfile(
                    session,
                    displayName: params['displayName'],
                    locale: params['locale'],
                    timeZone: params['timeZone'],
                  ),
        ),
        'uploadAvatar': _is.MethodConnector(
          name: 'uploadAvatar',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'fileName': _is.ParameterDescription(
              name: 'fileName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'mimeType': _is.ParameterDescription(
              name: 'mimeType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'size': _is.ParameterDescription(
              name: 'size',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['user'] as _iwtyukq6.UserEndpoint).uploadAvatar(
                    session,
                    params['fileUuid'],
                    params['fileName'],
                    params['mimeType'],
                    params['size'],
                  ),
        ),
        'setAvatar': _is.MethodConnector(
          name: 'setAvatar',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['user'] as _iwtyukq6.UserEndpoint).setAvatar(
                    session,
                    params['fileUuid'],
                  ),
        ),
        'getPreferences': _is.MethodConnector(
          name: 'getPreferences',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['user'] as _iwtyukq6.UserEndpoint)
                  .getPreferences(session),
        ),
        'updatePreferences': _is.MethodConnector(
          name: 'updatePreferences',
          params: {
            'patch': _is.ParameterDescription(
              name: 'patch',
              type: _is.getType<_ingbfbma.UserPreferencesPatch>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['user'] as _iwtyukq6.UserEndpoint)
                  .updatePreferences(
                    session,
                    params['patch'],
                  ),
        ),
        'searchUsers': _is.MethodConnector(
          name: 'searchUsers',
          params: {
            'query': _is.ParameterDescription(
              name: 'query',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['user'] as _iwtyukq6.UserEndpoint).searchUsers(
                    session,
                    params['query'],
                    params['limit'],
                  ),
        ),
        'getUsers': _is.MethodConnector(
          name: 'getUsers',
          params: {
            'ids': _is.ParameterDescription(
              name: 'ids',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['user'] as _iwtyukq6.UserEndpoint).getUsers(
                session,
                params['ids'],
              ),
        ),
        'accountDeletionPreview': _is.MethodConnector(
          name: 'accountDeletionPreview',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['user'] as _iwtyukq6.UserEndpoint)
                  .accountDeletionPreview(session),
        ),
        'deleteAccount': _is.MethodConnector(
          name: 'deleteAccount',
          params: {
            'confirmation': _is.ParameterDescription(
              name: 'confirmation',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['user'] as _iwtyukq6.UserEndpoint).deleteAccount(
                    session,
                    params['confirmation'],
                  ),
        ),
      },
    );
    connectors['version'] = _is.EndpointConnector(
      name: 'version',
      endpoint: endpoints['version']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'namedOnly': _is.ParameterDescription(
              name: 'namedOnly',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'beforeId': _is.ParameterDescription(
              name: 'beforeId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['version'] as _im6cm90k.VersionEndpoint).list(
                    session,
                    params['itemUuid'],
                    params['namedOnly'],
                    beforeId: params['beforeId'],
                    limit: params['limit'],
                  ),
        ),
        'nameCurrent': _is.MethodConnector(
          name: 'nameCurrent',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['version'] as _im6cm90k.VersionEndpoint)
                  .nameCurrent(
                    session,
                    params['itemUuid'],
                    params['name'],
                  ),
        ),
        'rename': _is.MethodConnector(
          name: 'rename',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['version'] as _im6cm90k.VersionEndpoint).rename(
                    session,
                    params['itemUuid'],
                    params['versionId'],
                    params['name'],
                  ),
        ),
        'restore': _is.MethodConnector(
          name: 'restore',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['version'] as _im6cm90k.VersionEndpoint).restore(
                    session,
                    params['itemUuid'],
                    params['versionId'],
                  ),
        ),
        'getSnapshotUrl': _is.MethodConnector(
          name: 'getSnapshotUrl',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['version'] as _im6cm90k.VersionEndpoint)
                  .getSnapshotUrl(
                    session,
                    params['itemUuid'],
                    params['versionId'],
                  ),
        ),
      },
    );
    connectors['sheetsAi'] = _is.EndpointConnector(
      name: 'sheetsAi',
      endpoint: endpoints['sheetsAi']!,
      methodConnectors: {
        'suggestFormula': _is.MethodConnector(
          name: 'suggestFormula',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'cell': _is.ParameterDescription(
              name: 'cell',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'prompt': _is.ParameterDescription(
              name: 'prompt',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .suggestFormula(
                    session,
                    params['itemUuid'],
                    params['cell'],
                    params['prompt'],
                  ),
        ),
        'fillRange': _is.MethodConnector(
          name: 'fillRange',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'range': _is.ParameterDescription(
              name: 'range',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'instructions': _is.ParameterDescription(
              name: 'instructions',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .fillRange(
                    session,
                    params['itemUuid'],
                    params['range'],
                    params['instructions'],
                  ),
        ),
        'applyFill': _is.MethodConnector(
          name: 'applyFill',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'range': _is.ParameterDescription(
              name: 'range',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'rows': _is.ParameterDescription(
              name: 'rows',
              type: _is.getType<List<_isuyxaqz.SheetsFillRow>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .applyFill(
                    session,
                    params['itemUuid'],
                    params['range'],
                    params['rows'],
                  ),
        ),
        'analyzeChips': _is.MethodConnector(
          name: 'analyzeChips',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'range': _is.ParameterDescription(
              name: 'range',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .analyzeChips(
                    session,
                    params['itemUuid'],
                    params['range'],
                  ),
        ),
        'describeChart': _is.MethodConnector(
          name: 'describeChart',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'chartId': _is.ParameterDescription(
              name: 'chartId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .describeChart(
                    session,
                    params['itemUuid'],
                    params['chartId'],
                  ),
        ),
        'getPreview': _is.MethodConnector(
          name: 'getPreview',
          params: {
            'previewId': _is.ParameterDescription(
              name: 'previewId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .getPreview(
                    session,
                    params['previewId'],
                  ),
        ),
        'applyPreview': _is.MethodConnector(
          name: 'applyPreview',
          params: {
            'previewId': _is.ParameterDescription(
              name: 'previewId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'callIds': _is.ParameterDescription(
              name: 'callIds',
              type: _is.getType<List<String>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .applyPreview(
                    session,
                    params['previewId'],
                    params['callIds'],
                  ),
        ),
        'evaluateAiCells': _is.MethodConnector(
          name: 'evaluateAiCells',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'requests': _is.ParameterDescription(
              name: 'requests',
              type: _is.getType<List<_ifqit8uo.SheetsAiCellRequest>>(),
              nullable: false,
            ),
            'refresh': _is.ParameterDescription(
              name: 'refresh',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .evaluateAiCells(
                    session,
                    params['itemUuid'],
                    params['requests'],
                    params['refresh'],
                  ),
        ),
        'discardPreview': _is.MethodConnector(
          name: 'discardPreview',
          params: {
            'previewId': _is.ParameterDescription(
              name: 'previewId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .discardPreview(
                    session,
                    params['previewId'],
                  ),
        ),
        'explainFormula': _is.MethodStreamConnector(
          name: 'explainFormula',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'cell': _is.ParameterDescription(
              name: 'cell',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['sheetsAi'] as _i9apq23f.SheetsAiEndpoint)
                  .explainFormula(
                    session,
                    params['itemUuid'],
                    params['cell'],
                  ),
        ),
      },
    );
    connectors['sheetsDoc'] = _is.EndpointConnector(
      name: 'sheetsDoc',
      endpoint: endpoints['sheetsDoc']!,
      methodConnectors: {
        'page': _is.MethodConnector(
          name: 'page',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iynxab9u.RevPageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsDoc'] as _izwcpcmx.SheetsDocEndpoint).page(
                    session,
                    params['fileUuid'],
                    params['request'],
                  ),
        ),
        'ops': _is.MethodConnector(
          name: 'ops',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'fromRevision': _is.ParameterDescription(
              name: 'fromRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'toRevision': _is.ParameterDescription(
              name: 'toRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsDoc'] as _izwcpcmx.SheetsDocEndpoint).ops(
                    session,
                    params['fileUuid'],
                    params['fromRevision'],
                    params['toRevision'],
                  ),
        ),
        'info': _is.MethodConnector(
          name: 'info',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsDoc'] as _izwcpcmx.SheetsDocEndpoint).info(
                    session,
                    params['fileUuid'],
                  ),
        ),
        'connect': _is.MethodStreamConnector(
          name: 'connect',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'knownRevision': _is.ParameterDescription(
              name: 'knownRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'tabId': _is.ParameterDescription(
              name: 'tabId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          streamParams: {
            'input': _is.StreamParameterDescription<_iv4mnr49.RevClientMessage>(
              name: 'input',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['sheetsDoc'] as _izwcpcmx.SheetsDocEndpoint)
                  .connect(
                    session,
                    params['fileUuid'],
                    params['knownRevision'],
                    params['tabId'],
                    streamParams['input']!.cast<_iv4mnr49.RevClientMessage>(),
                  ),
        ),
      },
    );
    connectors['sheets'] = _is.EndpointConnector(
      name: 'sheets',
      endpoint: endpoints['sheets']!,
      methodConnectors: {
        'getUserProperties': _is.MethodConnector(
          name: 'getUserProperties',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint)
                  .getUserProperties(
                    session,
                    params['fileUuid'],
                  ),
        ),
        'setUserProperties': _is.MethodConnector(
          name: 'setUserProperties',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'changes': _is.ParameterDescription(
              name: 'changes',
              type: _is.getType<Map<String, String?>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint)
                  .setUserProperties(
                    session,
                    params['fileUuid'],
                    params['changes'],
                  ),
        ),
        'namedFunctions': _is.MethodConnector(
          name: 'namedFunctions',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint)
                  .namedFunctions(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'spreadsheetTheme': _is.MethodConnector(
          name: 'spreadsheetTheme',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint)
                  .spreadsheetTheme(
                    session,
                    params['itemUuid'],
                  ),
        ),
        'revertChange': _is.MethodConnector(
          name: 'revertChange',
          params: {
            'changeId': _is.ParameterDescription(
              name: 'changeId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint)
                  .revertChange(
                    session,
                    params['changeId'],
                  ),
        ),
        'reapplyChange': _is.MethodConnector(
          name: 'reapplyChange',
          params: {
            'changeId': _is.ParameterDescription(
              name: 'changeId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint)
                  .reapplyChange(
                    session,
                    params['changeId'],
                  ),
        ),
        'cellHistory': _is.MethodConnector(
          name: 'cellHistory',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'sheetId': _is.ParameterDescription(
              name: 'sheetId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'rowId': _is.ParameterDescription(
              name: 'rowId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'colId': _is.ParameterDescription(
              name: 'colId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'cursor': _is.ParameterDescription(
              name: 'cursor',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint).cellHistory(
                    session,
                    params['spreadsheetUuid'],
                    params['sheetId'],
                    params['rowId'],
                    params['colId'],
                    params['cursor'],
                  ),
        ),
        'activitySummary': _is.MethodConnector(
          name: 'activitySummary',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'days': _is.ParameterDescription(
              name: 'days',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint)
                  .activitySummary(
                    session,
                    params['spreadsheetUuid'],
                    params['days'],
                  ),
        ),
        'fetchImage': _is.MethodConnector(
          name: 'fetchImage',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'url': _is.ParameterDescription(
              name: 'url',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheets'] as _izrkvdrt.SheetsEndpoint).fetchImage(
                    session,
                    params['itemUuid'],
                    params['url'],
                  ),
        ),
      },
    );
    connectors['sheetsImport'] = _is.EndpointConnector(
      name: 'sheetsImport',
      endpoint: endpoints['sheetsImport']!,
      methodConnectors: {
        'importInto': _is.MethodConnector(
          name: 'importInto',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'uploadId': _is.ParameterDescription(
              name: 'uploadId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'optionsJson': _is.ParameterDescription(
              name: 'optionsJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'activeSheetId': _is.ParameterDescription(
              name: 'activeSheetId',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsImport'] as _ixh3mo4r.SheetsImportEndpoint)
                      .importInto(
                        session,
                        params['spreadsheetUuid'],
                        params['uploadId'],
                        params['optionsJson'],
                        params['activeSheetId'],
                      ),
        ),
        'importProgress': _is.MethodConnector(
          name: 'importProgress',
          params: {
            'jobId': _is.ParameterDescription(
              name: 'jobId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsImport'] as _ixh3mo4r.SheetsImportEndpoint)
                      .importProgress(
                        session,
                        params['jobId'],
                      ),
        ),
        'sourceFromDrive': _is.MethodConnector(
          name: 'sourceFromDrive',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsImport'] as _ixh3mo4r.SheetsImportEndpoint)
                      .sourceFromDrive(
                        session,
                        params['itemUuid'],
                      ),
        ),
        'cancelImport': _is.MethodConnector(
          name: 'cancelImport',
          params: {
            'jobId': _is.ParameterDescription(
              name: 'jobId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsImport'] as _ixh3mo4r.SheetsImportEndpoint)
                      .cancelImport(
                        session,
                        params['jobId'],
                      ),
        ),
        'watchImport': _is.MethodStreamConnector(
          name: 'watchImport',
          params: {
            'jobId': _is.ParameterDescription(
              name: 'jobId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['sheetsImport'] as _ixh3mo4r.SheetsImportEndpoint)
                  .watchImport(
                    session,
                    params['jobId'],
                  ),
        ),
      },
    );
    connectors['script'] = _is.EndpointConnector(
      name: 'script',
      endpoint: endpoints['script']!,
      methodConnectors: {
        'compile': _is.MethodConnector(
          name: 'compile',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['script'] as _in9oll5w.ScriptEndpoint).compile(
                    session,
                    params['spreadsheetUuid'],
                  ),
        ),
        'analyze': _is.MethodConnector(
          name: 'analyze',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'fileName': _is.ParameterDescription(
              name: 'fileName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'source': _is.ParameterDescription(
              name: 'source',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['script'] as _in9oll5w.ScriptEndpoint).analyze(
                    session,
                    params['spreadsheetUuid'],
                    params['fileName'],
                    params['source'],
                  ),
        ),
        'bytecode': _is.MethodConnector(
          name: 'bytecode',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['script'] as _in9oll5w.ScriptEndpoint).bytecode(
                    session,
                    params['spreadsheetUuid'],
                  ),
        ),
        'run': _is.MethodConnector(
          name: 'run',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'functionName': _is.ParameterDescription(
              name: 'functionName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'argsJson': _is.ParameterDescription(
              name: 'argsJson',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['script'] as _in9oll5w.ScriptEndpoint).run(
                session,
                params['spreadsheetUuid'],
                params['functionName'],
                params['argsJson'],
              ),
        ),
        'executions': _is.MethodConnector(
          name: 'executions',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'functionName': _is.ParameterDescription(
              name: 'functionName',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'status': _is.ParameterDescription(
              name: 'status',
              type: _is.getType<_icum4fx3.ScriptExecutionStatus?>(),
              nullable: true,
            ),
            'before': _is.ParameterDescription(
              name: 'before',
              type: _is.getType<DateTime?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['script'] as _in9oll5w.ScriptEndpoint).executions(
                    session,
                    params['spreadsheetUuid'],
                    functionName: params['functionName'],
                    status: params['status'],
                    before: params['before'],
                    limit: params['limit'],
                  ),
        ),
        'reportExecutions': _is.MethodConnector(
          name: 'reportExecutions',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'executions': _is.ParameterDescription(
              name: 'executions',
              type: _is.getType<List<_isf59hoo.ScriptExecution>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['script'] as _in9oll5w.ScriptEndpoint)
                  .reportExecutions(
                    session,
                    params['spreadsheetUuid'],
                    params['executions'],
                  ),
        ),
        'urlFetch': _is.MethodConnector(
          name: 'urlFetch',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'requestJson': _is.ParameterDescription(
              name: 'requestJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'customFunction': _is.ParameterDescription(
              name: 'customFunction',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['script'] as _in9oll5w.ScriptEndpoint).urlFetch(
                    session,
                    params['spreadsheetUuid'],
                    params['requestJson'],
                    customFunction: params['customFunction'],
                  ),
        ),
        'authorization': _is.MethodConnector(
          name: 'authorization',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['script'] as _in9oll5w.ScriptEndpoint)
                  .authorization(
                    session,
                    params['spreadsheetUuid'],
                  ),
        ),
        'authorize': _is.MethodConnector(
          name: 'authorize',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'scopes': _is.ParameterDescription(
              name: 'scopes',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['script'] as _in9oll5w.ScriptEndpoint).authorize(
                    session,
                    params['spreadsheetUuid'],
                    params['scopes'],
                  ),
        ),
        'revokeAuthorization': _is.MethodConnector(
          name: 'revokeAuthorization',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['script'] as _in9oll5w.ScriptEndpoint)
                  .revokeAuthorization(
                    session,
                    params['spreadsheetUuid'],
                  ),
        ),
        'notifyOpen': _is.MethodConnector(
          name: 'notifyOpen',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['script'] as _in9oll5w.ScriptEndpoint).notifyOpen(
                    session,
                    params['spreadsheetUuid'],
                  ),
        ),
        'runLive': _is.MethodStreamConnector(
          name: 'runLive',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'functionName': _is.ParameterDescription(
              name: 'functionName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'argsJson': _is.ParameterDescription(
              name: 'argsJson',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['script'] as _in9oll5w.ScriptEndpoint).runLive(
                session,
                params['spreadsheetUuid'],
                params['functionName'],
                params['argsJson'],
              ),
        ),
      },
    );
    connectors['sheetsVersion'] = _is.EndpointConnector(
      name: 'sheetsVersion',
      endpoint: endpoints['sheetsVersion']!,
      methodConnectors: {
        'changes': _is.MethodConnector(
          name: 'changes',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsVersion']
                          as _izzz2y3b.SheetsVersionEndpoint)
                      .changes(
                        session,
                        params['itemUuid'],
                        params['versionId'],
                      ),
        ),
        'diff': _is.MethodConnector(
          name: 'diff',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'previousVersionId': _is.ParameterDescription(
              name: 'previousVersionId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsVersion']
                          as _izzz2y3b.SheetsVersionEndpoint)
                      .diff(
                        session,
                        params['itemUuid'],
                        params['versionId'],
                        params['previousVersionId'],
                      ),
        ),
        'copyExtras': _is.MethodConnector(
          name: 'copyExtras',
          params: {
            'sourceItemUuid': _is.ParameterDescription(
              name: 'sourceItemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'targetItemUuid': _is.ParameterDescription(
              name: 'targetItemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'anchorIdMapJson': _is.ParameterDescription(
              name: 'anchorIdMapJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'copyComments': _is.ParameterDescription(
              name: 'copyComments',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'copySharing': _is.ParameterDescription(
              name: 'copySharing',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['sheetsVersion']
                          as _izzz2y3b.SheetsVersionEndpoint)
                      .copyExtras(
                        session,
                        params['sourceItemUuid'],
                        params['targetItemUuid'],
                        params['anchorIdMapJson'],
                        params['copyComments'],
                        params['copySharing'],
                      ),
        ),
      },
    );
    connectors['slidesAi'] = _is.EndpointConnector(
      name: 'slidesAi',
      endpoint: endpoints['slidesAi']!,
      methodConnectors: {
        'buildDeck': _is.MethodConnector(
          name: 'buildDeck',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'outlineJson': _is.ParameterDescription(
              name: 'outlineJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'afterSlideId': _is.ParameterDescription(
              name: 'afterSlideId',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'notes': _is.ParameterDescription(
              name: 'notes',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'groups': _is.ParameterDescription(
              name: 'groups',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .buildDeck(
                    session,
                    params['itemUuid'],
                    params['outlineJson'],
                    params['afterSlideId'],
                    params['notes'],
                    params['groups'],
                    params['parentUuid'],
                  ),
        ),
        'writeNotes': _is.MethodConnector(
          name: 'writeNotes',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'slideIds': _is.ParameterDescription(
              name: 'slideIds',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'length': _is.ParameterDescription(
              name: 'length',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'style': _is.ParameterDescription(
              name: 'style',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'mode': _is.ParameterDescription(
              name: 'mode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .writeNotes(
                    session,
                    params['itemUuid'],
                    params['slideIds'],
                    params['length'],
                    params['style'],
                    params['mode'],
                  ),
        ),
        'describeElements': _is.MethodConnector(
          name: 'describeElements',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'elementIds': _is.ParameterDescription(
              name: 'elementIds',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .describeElements(
                    session,
                    params['itemUuid'],
                    params['elementIds'],
                  ),
        ),
        'rankDesigns': _is.MethodConnector(
          name: 'rankDesigns',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'slideId': _is.ParameterDescription(
              name: 'slideId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'candidates': _is.ParameterDescription(
              name: 'candidates',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .rankDesigns(
                    session,
                    params['itemUuid'],
                    params['slideId'],
                    params['candidates'],
                  ),
        ),
        'getPreview': _is.MethodConnector(
          name: 'getPreview',
          params: {
            'previewId': _is.ParameterDescription(
              name: 'previewId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .getPreview(
                    session,
                    params['previewId'],
                  ),
        ),
        'applyPreview': _is.MethodConnector(
          name: 'applyPreview',
          params: {
            'previewId': _is.ParameterDescription(
              name: 'previewId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'callIds': _is.ParameterDescription(
              name: 'callIds',
              type: _is.getType<List<String>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .applyPreview(
                    session,
                    params['previewId'],
                    params['callIds'],
                  ),
        ),
        'discardPreview': _is.MethodConnector(
          name: 'discardPreview',
          params: {
            'previewId': _is.ParameterDescription(
              name: 'previewId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .discardPreview(
                    session,
                    params['previewId'],
                  ),
        ),
        'proposeOutline': _is.MethodStreamConnector(
          name: 'proposeOutline',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_isfebja2.SlidesAiOutlineRequest>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint)
                  .proposeOutline(
                    session,
                    params['itemUuid'],
                    params['request'],
                  ),
        ),
        'rewrite': _is.MethodStreamConnector(
          name: 'rewrite',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_ionqjjsu.SlidesAiRewriteRequest>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['slidesAi'] as _iwzuobfk.SlidesAiEndpoint).rewrite(
                    session,
                    params['itemUuid'],
                    params['request'],
                  ),
        ),
      },
    );
    connectors['slidesCharts'] = _is.EndpointConnector(
      name: 'slidesCharts',
      endpoint: endpoints['slidesCharts']!,
      methodConnectors: {
        'listCharts': _is.MethodConnector(
          name: 'listCharts',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesCharts'] as _iusodta9.SlidesChartsEndpoint)
                      .listCharts(
                        session,
                        params['spreadsheetUuid'],
                      ),
        ),
        'resolveSnapshot': _is.MethodConnector(
          name: 'resolveSnapshot',
          params: {
            'spreadsheetUuid': _is.ParameterDescription(
              name: 'spreadsheetUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'chartObjectId': _is.ParameterDescription(
              name: 'chartObjectId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesCharts'] as _iusodta9.SlidesChartsEndpoint)
                      .resolveSnapshot(
                        session,
                        params['spreadsheetUuid'],
                        params['chartObjectId'],
                      ),
        ),
        'checkLinks': _is.MethodConnector(
          name: 'checkLinks',
          params: {
            'probes': _is.ParameterDescription(
              name: 'probes',
              type: _is.getType<List<_izmhos0v.ChartLinkProbe>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesCharts'] as _iusodta9.SlidesChartsEndpoint)
                      .checkLinks(
                        session,
                        params['probes'],
                      ),
        ),
      },
    );
    connectors['slidesDoc'] = _is.EndpointConnector(
      name: 'slidesDoc',
      endpoint: endpoints['slidesDoc']!,
      methodConnectors: {
        'page': _is.MethodConnector(
          name: 'page',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iynxab9u.RevPageRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesDoc'] as _ifxounnn.SlidesDocEndpoint).page(
                    session,
                    params['fileUuid'],
                    params['request'],
                  ),
        ),
        'ops': _is.MethodConnector(
          name: 'ops',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'fromRevision': _is.ParameterDescription(
              name: 'fromRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'toRevision': _is.ParameterDescription(
              name: 'toRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesDoc'] as _ifxounnn.SlidesDocEndpoint).ops(
                    session,
                    params['fileUuid'],
                    params['fromRevision'],
                    params['toRevision'],
                  ),
        ),
        'info': _is.MethodConnector(
          name: 'info',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesDoc'] as _ifxounnn.SlidesDocEndpoint).info(
                    session,
                    params['fileUuid'],
                  ),
        ),
        'connect': _is.MethodStreamConnector(
          name: 'connect',
          params: {
            'fileUuid': _is.ParameterDescription(
              name: 'fileUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'knownRevision': _is.ParameterDescription(
              name: 'knownRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'tabId': _is.ParameterDescription(
              name: 'tabId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          streamParams: {
            'input': _is.StreamParameterDescription<_iv4mnr49.RevClientMessage>(
              name: 'input',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['slidesDoc'] as _ifxounnn.SlidesDocEndpoint)
                  .connect(
                    session,
                    params['fileUuid'],
                    params['knownRevision'],
                    params['tabId'],
                    streamParams['input']!.cast<_iv4mnr49.RevClientMessage>(),
                  ),
        ),
      },
    );
    connectors['slides'] = _is.EndpointConnector(
      name: 'slides',
      endpoint: endpoints['slides']!,
      methodConnectors: {
        'revertChange': _is.MethodConnector(
          name: 'revertChange',
          params: {
            'changeId': _is.ParameterDescription(
              name: 'changeId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slides'] as _i90mpuoj.SlidesEndpoint)
                  .revertChange(
                    session,
                    params['changeId'],
                  ),
        ),
        'reapplyChange': _is.MethodConnector(
          name: 'reapplyChange',
          params: {
            'changeId': _is.ParameterDescription(
              name: 'changeId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['slides'] as _i90mpuoj.SlidesEndpoint)
                  .reapplyChange(
                    session,
                    params['changeId'],
                  ),
        ),
      },
    );
    connectors['slidesExport'] = _is.EndpointConnector(
      name: 'slidesExport',
      endpoint: endpoints['slidesExport']!,
      methodConnectors: {
        'export': _is.MethodConnector(
          name: 'export',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'format': _is.ParameterDescription(
              name: 'format',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'optionsJson': _is.ParameterDescription(
              name: 'optionsJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'revision': _is.ParameterDescription(
              name: 'revision',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesExport'] as _ipawej08.SlidesExportEndpoint)
                      .export(
                        session,
                        params['itemUuid'],
                        params['format'],
                        params['optionsJson'],
                        params['revision'],
                      ),
        ),
        'exportWithProgress': _is.MethodStreamConnector(
          name: 'exportWithProgress',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'format': _is.ParameterDescription(
              name: 'format',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'optionsJson': _is.ParameterDescription(
              name: 'optionsJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'revision': _is.ParameterDescription(
              name: 'revision',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['slidesExport'] as _ipawej08.SlidesExportEndpoint)
                  .exportWithProgress(
                    session,
                    params['itemUuid'],
                    params['format'],
                    params['optionsJson'],
                    params['revision'],
                  ),
        ),
      },
    );
    connectors['presentation'] = _is.EndpointConnector(
      name: 'presentation',
      endpoint: endpoints['presentation']!,
      methodConnectors: {
        'findSession': _is.MethodConnector(
          name: 'findSession',
          params: {
            'deckUuid': _is.ParameterDescription(
              name: 'deckUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['presentation'] as _irtlljai.PresentationEndpoint)
                      .findSession(
                        session,
                        params['deckUuid'],
                      ),
        ),
        'resolvePairingCode': _is.MethodConnector(
          name: 'resolvePairingCode',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['presentation'] as _irtlljai.PresentationEndpoint)
                      .resolvePairingCode(
                        session,
                        params['code'],
                      ),
        ),
        'join': _is.MethodStreamConnector(
          name: 'join',
          params: {
            'deckUuid': _is.ParameterDescription(
              name: 'deckUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'join': _is.ParameterDescription(
              name: 'join',
              type: _is.getType<_ieucpeca.PresentationJoin>(),
              nullable: false,
            ),
          },
          streamParams: {
            'updates':
                _is.StreamParameterDescription<_i0rcw8q1.PresentationUpdate>(
                  name: 'updates',
                  nullable: false,
                ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['presentation'] as _irtlljai.PresentationEndpoint)
                  .join(
                    session,
                    params['deckUuid'],
                    params['join'],
                    streamParams['updates']!
                        .cast<_i0rcw8q1.PresentationUpdate>(),
                  ),
        ),
      },
    );
    connectors['slidesThemes'] = _is.EndpointConnector(
      name: 'slidesThemes',
      endpoint: endpoints['slidesThemes']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesThemes'] as _ivwqk6th.SlidesThemesEndpoint)
                      .list(
                        session,
                        params['itemUuid'],
                      ),
        ),
      },
    );
    connectors['slidesVersion'] = _is.EndpointConnector(
      name: 'slidesVersion',
      endpoint: endpoints['slidesVersion']!,
      methodConnectors: {
        'changes': _is.MethodConnector(
          name: 'changes',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesVersion']
                          as _iuslkdly.SlidesVersionEndpoint)
                      .changes(
                        session,
                        params['itemUuid'],
                        params['versionId'],
                      ),
        ),
        'makeCopy': _is.MethodConnector(
          name: 'makeCopy',
          params: {
            'itemUuid': _is.ParameterDescription(
              name: 'itemUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'folderUuid': _is.ParameterDescription(
              name: 'folderUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
            'copyComments': _is.ParameterDescription(
              name: 'copyComments',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'copySharing': _is.ParameterDescription(
              name: 'copySharing',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['slidesVersion']
                          as _iuslkdly.SlidesVersionEndpoint)
                      .makeCopy(
                        session,
                        params['itemUuid'],
                        params['versionId'],
                        params['name'],
                        params['folderUuid'],
                        params['copyComments'],
                        params['copySharing'],
                      ),
        ),
      },
    );
    connectors['document'] = _is.EndpointConnector(
      name: 'document',
      endpoint: endpoints['document']!,
      methodConnectors: {
        'getInfo': _is.MethodConnector(
          name: 'getInfo',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['document'] as _iiabxp2u.DocumentEndpoint).getInfo(
                    session,
                    params['documentUuid'],
                  ),
        ),
        'getOps': _is.MethodConnector(
          name: 'getOps',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'fromRevision': _is.ParameterDescription(
              name: 'fromRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'toRevision': _is.ParameterDescription(
              name: 'toRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['document'] as _iiabxp2u.DocumentEndpoint).getOps(
                    session,
                    params['documentUuid'],
                    params['fromRevision'],
                    params['toRevision'],
                  ),
        ),
        'getSnapshot': _is.MethodConnector(
          name: 'getSnapshot',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'revision': _is.ParameterDescription(
              name: 'revision',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['document'] as _iiabxp2u.DocumentEndpoint)
                  .getSnapshot(
                    session,
                    params['documentUuid'],
                    params['revision'],
                  ),
        ),
        'updateMeta': _is.MethodConnector(
          name: 'updateMeta',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'patch': _is.ParameterDescription(
              name: 'patch',
              type: _is.getType<_issank2j.DocumentMetaPatch>(),
              nullable: false,
            ),
            'clientOpId': _is.ParameterDescription(
              name: 'clientOpId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['document'] as _iiabxp2u.DocumentEndpoint)
                  .updateMeta(
                    session,
                    params['documentUuid'],
                    params['patch'],
                    params['clientOpId'],
                  ),
        ),
        'connect': _is.MethodStreamConnector(
          name: 'connect',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'knownRevision': _is.ParameterDescription(
              name: 'knownRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {
            'input': _is.StreamParameterDescription<_i64vpekp.DocClientMessage>(
              name: 'input',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['document'] as _iiabxp2u.DocumentEndpoint).connect(
                    session,
                    params['documentUuid'],
                    params['knownRevision'],
                    streamParams['input']!.cast<_i64vpekp.DocClientMessage>(),
                  ),
        ),
      },
    );
    connectors['writeExport'] = _is.EndpointConnector(
      name: 'writeExport',
      endpoint: endpoints['writeExport']!,
      methodConnectors: {
        'export': _is.MethodConnector(
          name: 'export',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'format': _is.ParameterDescription(
              name: 'format',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'optionsJson': _is.ParameterDescription(
              name: 'optionsJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'revision': _is.ParameterDescription(
              name: 'revision',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeExport'] as _ia4kadx2.WriteExportEndpoint)
                      .export(
                        session,
                        params['documentUuid'],
                        params['format'],
                        params['optionsJson'],
                        params['revision'],
                      ),
        ),
        'convertForInsert': _is.MethodConnector(
          name: 'convertForInsert',
          params: {
            'uploadId': _is.ParameterDescription(
              name: 'uploadId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'format': _is.ParameterDescription(
              name: 'format',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'optionsJson': _is.ParameterDescription(
              name: 'optionsJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeExport'] as _ia4kadx2.WriteExportEndpoint)
                      .convertForInsert(
                        session,
                        params['uploadId'],
                        params['format'],
                        params['optionsJson'],
                      ),
        ),
        'fetchImage': _is.MethodConnector(
          name: 'fetchImage',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'src': _is.ParameterDescription(
              name: 'src',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeExport'] as _ia4kadx2.WriteExportEndpoint)
                      .fetchImage(
                        session,
                        params['documentUuid'],
                        params['src'],
                      ),
        ),
        'exportWithProgress': _is.MethodStreamConnector(
          name: 'exportWithProgress',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'format': _is.ParameterDescription(
              name: 'format',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'optionsJson': _is.ParameterDescription(
              name: 'optionsJson',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'revision': _is.ParameterDescription(
              name: 'revision',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['writeExport'] as _ia4kadx2.WriteExportEndpoint)
                  .exportWithProgress(
                    session,
                    params['documentUuid'],
                    params['format'],
                    params['optionsJson'],
                    params['revision'],
                  ),
        ),
      },
    );
    connectors['writeHistory'] = _is.EndpointConnector(
      name: 'writeHistory',
      endpoint: endpoints['writeHistory']!,
      methodConnectors: {
        'getVersionDocument': _is.MethodConnector(
          name: 'getVersionDocument',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'revision': _is.ParameterDescription(
              name: 'revision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeHistory'] as _izdjh3zj.WriteHistoryEndpoint)
                      .getVersionDocument(
                        session,
                        params['documentUuid'],
                        params['revision'],
                      ),
        ),
        'diff': _is.MethodConnector(
          name: 'diff',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'fromRevision': _is.ParameterDescription(
              name: 'fromRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'toRevision': _is.ParameterDescription(
              name: 'toRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeHistory'] as _izdjh3zj.WriteHistoryEndpoint)
                      .diff(
                        session,
                        params['documentUuid'],
                        params['fromRevision'],
                        params['toRevision'],
                      ),
        ),
        'createRestorePoint': _is.MethodConnector(
          name: 'createRestorePoint',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeHistory'] as _izdjh3zj.WriteHistoryEndpoint)
                      .createRestorePoint(
                        session,
                        params['documentUuid'],
                      ),
        ),
        'restore': _is.MethodConnector(
          name: 'restore',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeHistory'] as _izdjh3zj.WriteHistoryEndpoint)
                      .restore(
                        session,
                        params['documentUuid'],
                        params['versionId'],
                      ),
        ),
        'copyVersion': _is.MethodConnector(
          name: 'copyVersion',
          params: {
            'documentUuid': _is.ParameterDescription(
              name: 'documentUuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'versionId': _is.ParameterDescription(
              name: 'versionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'parentUuid': _is.ParameterDescription(
              name: 'parentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeHistory'] as _izdjh3zj.WriteHistoryEndpoint)
                      .copyVersion(
                        session,
                        params['documentUuid'],
                        params['versionId'],
                        params['name'],
                        params['parentUuid'],
                      ),
        ),
      },
    );
    connectors['writeTheme'] = _is.EndpointConnector(
      name: 'writeTheme',
      endpoint: endpoints['writeTheme']!,
      methodConnectors: {
        'listBuiltins': _is.MethodConnector(
          name: 'listBuiltins',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .listBuiltins(session),
        ),
        'listMine': _is.MethodConnector(
          name: 'listMine',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .listMine(session),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'viaDocumentUuid': _is.ParameterDescription(
              name: 'viaDocumentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint).get(
                    session,
                    params['uuid'],
                    params['viaDocumentUuid'],
                  ),
        ),
        'getMany': _is.MethodConnector(
          name: 'getMany',
          params: {
            'uuids': _is.ParameterDescription(
              name: 'uuids',
              type: _is.getType<List<_is.UuidValue>>(),
              nullable: false,
            ),
            'viaDocumentUuid': _is.ParameterDescription(
              name: 'viaDocumentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .getMany(
                        session,
                        params['uuids'],
                        params['viaDocumentUuid'],
                      ),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'json': _is.ParameterDescription(
              name: 'json',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'basedOnUuid': _is.ParameterDescription(
              name: 'basedOnUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .create(
                        session,
                        params['name'],
                        params['json'],
                        params['basedOnUuid'],
                      ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'json': _is.ParameterDescription(
              name: 'json',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedVersion': _is.ParameterDescription(
              name: 'expectedVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .update(
                        session,
                        params['uuid'],
                        params['json'],
                        params['expectedVersion'],
                      ),
        ),
        'rename': _is.MethodConnector(
          name: 'rename',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedVersion': _is.ParameterDescription(
              name: 'expectedVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .rename(
                        session,
                        params['uuid'],
                        params['name'],
                        params['expectedVersion'],
                      ),
        ),
        'duplicate': _is.MethodConnector(
          name: 'duplicate',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'viaDocumentUuid': _is.ParameterDescription(
              name: 'viaDocumentUuid',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .duplicate(
                        session,
                        params['uuid'],
                        params['name'],
                        params['viaDocumentUuid'],
                      ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .delete(
                        session,
                        params['uuid'],
                      ),
        ),
        'restore': _is.MethodConnector(
          name: 'restore',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .restore(
                        session,
                        params['uuid'],
                      ),
        ),
        'listRevisions': _is.MethodConnector(
          name: 'listRevisions',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .listRevisions(
                        session,
                        params['uuid'],
                      ),
        ),
        'getRevision': _is.MethodConnector(
          name: 'getRevision',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'version': _is.ParameterDescription(
              name: 'version',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .getRevision(
                        session,
                        params['uuid'],
                        params['version'],
                      ),
        ),
        'usage': _is.MethodConnector(
          name: 'usage',
          params: {
            'uuid': _is.ParameterDescription(
              name: 'uuid',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['writeTheme'] as _ii3xbyyg.WriteThemeEndpoint)
                      .usage(
                        session,
                        params['uuid'],
                      ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _iwslocjr.FutureCalls();
  }
}
