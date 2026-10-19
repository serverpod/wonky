/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:wonky_client/src/protocol/platform/activity/activity_event_view.dart'
    as _itempttd;
import 'package:wonky_client/src/protocol/platform/ai/models/assistant_thread_view.dart'
    as _i2rhb3qx;
import 'package:wonky_client/src/protocol/platform/board/models/board_bundle_suggestion_view.dart'
    as _i94c7q23;
import 'package:wonky_client/src/protocol/platform/board/models/board_comment_view.dart'
    as _iesojpvb;
import 'package:wonky_client/src/protocol/platform/board/models/board_review_item.dart'
    as _i3y77bov;
import 'package:wonky_client/src/protocol/platform/board/models/board_similar_post.dart'
    as _ikfdrh1p;
import 'package:wonky_client/src/protocol/platform/board/models/board_task_status.dart'
    as _i325i6jq;
import 'package:wonky_client/src/protocol/platform/comments/comment_thread_view.dart'
    as _i2c85fb0;
import 'package:wonky_client/src/protocol/platform/drive/drive_item_view.dart'
    as _iatsgjjq;
import 'package:wonky_client/src/protocol/platform/drive/template_view.dart'
    as _i1pzk6fp;
import 'package:wonky_client/src/protocol/platform/files/file_url_view.dart'
    as _i4i1hokq;
import 'package:wonky_client/src/protocol/platform/revlog/models/rev_op_view.dart'
    as _iq15rk0l;
import 'package:wonky_client/src/protocol/platform/users/access_token_view.dart'
    as _ip6swqsj;
import 'package:wonky_client/src/protocol/platform/users/user_summary.dart'
    as _iq7femvs;
import 'package:wonky_client/src/protocol/platform/versions/item_version_view.dart'
    as _itqtmykd;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_ai_cell_request.dart'
    as _ibrzlkni;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_ai_cell_result.dart'
    as _ivc6ykj9;
import 'package:wonky_client/src/protocol/sheets/ai/models/sheets_fill_row.dart'
    as _i2syfqhi;
import 'package:wonky_client/src/protocol/sheets/scripts/models/script_execution.dart'
    as _ijdpewvc;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_alt_text.dart'
    as _iqd8jbjp;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_design_rank.dart'
    as _ifavqmyp;
import 'package:wonky_client/src/protocol/slides/ai/models/slides_ai_note.dart'
    as _iascr37x;
import 'package:wonky_client/src/protocol/slides/charts/models/chart_link_probe.dart'
    as _ipgr9tcd;
import 'package:wonky_client/src/protocol/slides/charts/models/chart_link_status.dart'
    as _idvbn12y;
import 'package:wonky_client/src/protocol/write/models/document_op_view.dart'
    as _i8x9070n;
import 'package:wonky_client/src/protocol/write/models/write_theme_revision_view.dart'
    as _igytjuh5;
import 'package:wonky_client/src/protocol/write/models/write_theme_view.dart'
    as _i2zuh8f2;
import 'platform/activity/activity_dashboard.dart' as _izr1y672;
import 'platform/activity/activity_event.dart' as _iatdjl5p;
import 'platform/activity/activity_event_view.dart' as _isa7sjzq;
import 'platform/activity/activity_trend_point.dart' as _ighcq381;
import 'platform/activity/activity_type.dart' as _i50cy468;
import 'platform/activity/activity_viewer.dart' as _ikcwdr17;
import 'platform/ai/models/ai_apply_mode.dart' as _iyja8k5e;
import 'platform/ai/models/ai_provider.dart' as _ir7z75mb;
import 'platform/ai/models/ai_provider_key_view.dart' as _ic2q2fwi;
import 'platform/ai/models/ai_quality.dart' as _iviyoyk9;
import 'platform/ai/models/ai_usage.dart' as _i7i53on7;
import 'platform/ai/models/ai_user_setting.dart' as _imx2nn1q;
import 'platform/ai/models/assistant_context_hints.dart' as _ic7e83wd;
import 'platform/ai/models/assistant_event.dart' as _imp4tsxo;
import 'platform/ai/models/assistant_event_type.dart' as _id6kvqt9;
import 'platform/ai/models/assistant_message.dart' as _i8cittxq;
import 'platform/ai/models/assistant_message_view.dart' as _i4rkdm2k;
import 'platform/ai/models/assistant_status.dart' as _ia2m3j3v;
import 'platform/ai/models/assistant_thread.dart' as _iaq6rutx;
import 'platform/ai/models/assistant_thread_detail.dart' as _i4iv0swm;
import 'platform/ai/models/assistant_thread_view.dart' as _iohdfqf1;
import 'platform/ai/models/inline_ai_event.dart' as _i8ghcs7p;
import 'platform/ai/models/inline_ai_event_type.dart' as _i6pcz5z6;
import 'platform/ai/models/inline_ai_request.dart' as _i4m43iwr;
import 'platform/ai/models/proofread_event.dart' as _ie0jt2ne;
import 'platform/ai/models/proofread_issue.dart' as _ivmxemza;
import 'platform/board/models/board_area.dart' as _i0ag0upm;
import 'platform/board/models/board_author.dart' as _ika8r7fc;
import 'platform/board/models/board_bundle_suggestion.dart' as _ilo15wk2;
import 'platform/board/models/board_bundle_suggestion_view.dart' as _iin47lv0;
import 'platform/board/models/board_comment.dart' as _ijz5flk6;
import 'platform/board/models/board_comment_view.dart' as _ipkjmsg5;
import 'platform/board/models/board_counts.dart' as _iswbp1jv;
import 'platform/board/models/board_event_kind.dart' as _ita8snxr;
import 'platform/board/models/board_flag.dart' as _i0y7d0xd;
import 'platform/board/models/board_flag_reason.dart' as _iwc3b6vo;
import 'platform/board/models/board_flag_view.dart' as _i5pjfe5s;
import 'platform/board/models/board_list_query.dart' as _igcoqerx;
import 'platform/board/models/board_me.dart' as _iu9hvv8z;
import 'platform/board/models/board_moderation.dart' as _in0hwjmy;
import 'platform/board/models/board_moderation_action.dart' as _i5jfu168;
import 'platform/board/models/board_post.dart' as _i7xps6dm;
import 'platform/board/models/board_post_draft.dart' as _izvgi5ni;
import 'platform/board/models/board_post_event.dart' as _ibl25moa;
import 'platform/board/models/board_post_kind.dart' as _iui4x9zg;
import 'platform/board/models/board_post_list_item.dart' as _iq3f61ec;
import 'platform/board/models/board_post_page.dart' as _i1stsytz;
import 'platform/board/models/board_post_status.dart' as _il200dga;
import 'platform/board/models/board_post_view.dart' as _ijjd81zg;
import 'platform/board/models/board_review_counts.dart' as _im7v2irk;
import 'platform/board/models/board_review_item.dart' as _id33cro1;
import 'platform/board/models/board_review_section.dart' as _izs2n8vy;
import 'platform/board/models/board_signal.dart' as _ieemxbgb;
import 'platform/board/models/board_similar_post.dart' as _in3cjdcj;
import 'platform/board/models/board_size.dart' as _ivbgicm7;
import 'platform/board/models/board_sort.dart' as _itz4727j;
import 'platform/board/models/board_target_kind.dart' as _i2gir90g;
import 'platform/board/models/board_task.dart' as _iv26y3a1;
import 'platform/board/models/board_task_page.dart' as _illpt7x2;
import 'platform/board/models/board_task_ref.dart' as _idsjzf6h;
import 'platform/board/models/board_task_status.dart' as _i4a2ekwp;
import 'platform/board/models/board_task_view.dart' as _ifz7dmuf;
import 'platform/board/models/board_triage_state.dart' as _iso7mdvm;
import 'platform/board/models/board_user_profile.dart' as _i516sz1w;
import 'platform/board/models/board_vote.dart' as _ifuo09i6;
import 'platform/board/models/board_vote_result.dart' as _ie24iiog;
import 'platform/comments/comment.dart' as _iyixppck;
import 'platform/comments/comment_anchor_kind.dart' as _iw81twtc;
import 'platform/comments/comment_event.dart' as _imlsyj2p;
import 'platform/comments/comment_event_kind.dart' as _ih1mb6x5;
import 'platform/comments/comment_filter.dart' as _il5y6tzr;
import 'platform/comments/comment_status.dart' as _iowdswxe;
import 'platform/comments/comment_system_event.dart' as _i94wr3td;
import 'platform/comments/comment_thread.dart' as _ijog60vm;
import 'platform/comments/comment_thread_view.dart' as _i818olql;
import 'platform/comments/comment_view.dart' as _i4xrxro7;
import 'platform/common/access_role.dart' as _ii98prcs;
import 'platform/common/actor_kind.dart' as _i2wc4tyi;
import 'platform/common/wonky_error_code.dart' as _inb0isem;
import 'platform/common/wonky_exception.dart' as _igdswlrw;
import 'platform/drive/drive_change.dart' as _iktwt5zz;
import 'platform/drive/drive_change_kind.dart' as _ijoqbs82;
import 'platform/drive/drive_import_options.dart' as _ig2nixhn;
import 'platform/drive/drive_item.dart' as _inge8yy2;
import 'platform/drive/drive_item_kind.dart' as _i8mh39wa;
import 'platform/drive/drive_item_user_state.dart' as _i0g2m831;
import 'platform/drive/drive_item_view.dart' as _infxyf98;
import 'platform/drive/drive_list_filter.dart' as _ivypvw0m;
import 'platform/drive/drive_list_page.dart' as _iavdhzsq;
import 'platform/drive/drive_owner_filter.dart' as _if1dhg5z;
import 'platform/drive/drive_search_filters.dart' as _i6k3d1nc;
import 'platform/drive/drive_sort.dart' as _iu13r4v2;
import 'platform/drive/drive_sort_field.dart' as _ix0g8yw4;
import 'platform/drive/drive_view.dart' as _ipww3kqy;
import 'platform/drive/file_category.dart' as _iez45i4u;
import 'platform/drive/file_upload_progress.dart' as _ilt75p4e;
import 'platform/drive/file_upload_request.dart' as _iqpb2qv1;
import 'platform/drive/file_upload_start.dart' as _imf3tnfq;
import 'platform/drive/file_upload_state.dart' as _ia04wt6m;
import 'platform/drive/import_report_view.dart' as _i68yhxa0;
import 'platform/drive/import_warning_view.dart' as _i48sm9f2;
import 'platform/drive/storage_list_filter.dart' as _i8hnug6t;
import 'platform/drive/storage_usage.dart' as _i26hsnhw;
import 'platform/drive/template_category.dart' as _iiedu4vz;
import 'platform/drive/template_preview_style.dart' as _i6rg3vdh;
import 'platform/drive/template_view.dart' as _i2ox7ta1;
import 'platform/drive/upload_conflict_mode.dart' as _io3ccr8w;
import 'platform/feedback/feedback_kind.dart' as _iv1sk0e8;
import 'platform/feedback/feedback_submission.dart' as _ilhpki98;
import 'platform/files/file_upload_ticket.dart' as _irrzp8p9;
import 'platform/files/file_url_view.dart' as _itzt3x6d;
import 'platform/files/stored_file.dart' as _im8eh74x;
import 'platform/files/stored_file_kind.dart' as _i45dmz4a;
import 'platform/files/stored_file_status.dart' as _ik7q11oy;
import 'platform/mcp/ui_bridge/ui_bridge_message.dart' as _ichw8k0i;
import 'platform/meta/feature_flags.dart' as _ivk6eyvx;
import 'platform/meta/protocol_info.dart' as _ib575x0y;
import 'platform/meta/server_limits.dart' as _i28el0at;
import 'platform/notifications/notification_event.dart' as _iexg4yzt;
import 'platform/notifications/notification_kind.dart' as _iqlnbbfp;
import 'platform/notifications/notification_page.dart' as _i3r1eo8q;
import 'platform/notifications/notification_view.dart' as _izfzk9h3;
import 'platform/notifications/user_notification.dart' as _ik59hiyp;
import 'platform/presence/participant.dart' as _iylgyc33;
import 'platform/presence/presence_event.dart' as _i8r9afjv;
import 'platform/presence/presence_state.dart' as _ik055xb9;
import 'platform/presence/presence_update.dart' as _isz2sju0;
import 'platform/revlog/messages/rev_client_message.dart' as _i6ck957q;
import 'platform/revlog/messages/rev_server_message.dart' as _ie6clghy;
import 'platform/revlog/models/rev_file_info.dart' as _ihwy023l;
import 'platform/revlog/models/rev_file_kind.dart' as _iwkehf4e;
import 'platform/revlog/models/rev_op_view.dart' as _it4o2pk5;
import 'platform/revlog/models/rev_page.dart' as _ium7xjeg;
import 'platform/revlog/models/rev_page_kind.dart' as _i3q3ua5p;
import 'platform/revlog/models/rev_page_request.dart' as _if03ikx4;
import 'platform/revlog/models/rev_reject_code.dart' as _iilsyt4b;
import 'platform/sharing/access_request.dart' as _i8scn8dm;
import 'platform/sharing/access_request_outcome.dart' as _i7trut12;
import 'platform/sharing/access_request_view.dart' as _iimp60a4;
import 'platform/sharing/drive_item_permission.dart' as _iuzgacy4;
import 'platform/sharing/invite_resolution.dart' as _ikeljole;
import 'platform/sharing/item_sharing_settings.dart' as _ih3711er;
import 'platform/sharing/ownership_transfer.dart' as _ijwxtu30;
import 'platform/sharing/ownership_transfer_view.dart' as _iilpsf9g;
import 'platform/sharing/permission_view.dart' as _iead0ok9;
import 'platform/sharing/share_link.dart' as _it712lg1;
import 'platform/sharing/share_link_view.dart' as _iw2xoohn;
import 'platform/sharing/sharing_info.dart' as _itd24os1;
import 'platform/storage/quota_exceeded_details.dart' as _ifxa4vxf;
import 'platform/users/access_token_view.dart' as _izha9j5m;
import 'platform/users/account_deletion_preview.dart' as _iq4dupwy;
import 'platform/users/app_theme_mode.dart' as _i6azdr3n;
import 'platform/users/created_access_token.dart' as _iru4pv75;
import 'platform/users/ui_density.dart' as _i5lc4gt0;
import 'platform/users/user_preferences.dart' as _i501u5m5;
import 'platform/users/user_preferences_patch.dart' as _id95rrz2;
import 'platform/users/user_profile.dart' as _ihzl7wbq;
import 'platform/users/user_profile_view.dart' as _iufqmqtc;
import 'platform/users/user_summary.dart' as _i6y7tspy;
import 'platform/versions/item_version.dart' as _i7jb115m;
import 'platform/versions/item_version_view.dart' as _ipbapjbz;
import 'platform/versions/version_kind.dart' as _in0fdl1f;
import 'platform/versions/version_restore_result.dart' as _in38zbga;
import 'platform/versions/version_storage.dart' as _i5u6d6t4;
import 'sheets/ai/models/sheets_ai_apply_result.dart' as _iuzj1jin;
import 'sheets/ai/models/sheets_ai_cell_request.dart' as _iljqbz3a;
import 'sheets/ai/models/sheets_ai_cell_result.dart' as _im85lt6z;
import 'sheets/ai/models/sheets_ai_preview.dart' as _i4t3jyqe;
import 'sheets/ai/models/sheets_ai_preview_call.dart' as _idzstekp;
import 'sheets/ai/models/sheets_ai_preview_cell.dart' as _i49726iv;
import 'sheets/ai/models/sheets_fill_proposal.dart' as _izbpavhd;
import 'sheets/ai/models/sheets_fill_row.dart' as _i1gi0ui2;
import 'sheets/ai/models/sheets_formula_suggestion.dart' as _i2bhah0l;
import 'sheets/imports/models/sheets_import_progress.dart' as _iaf43n69;
import 'sheets/imports/models/sheets_import_status.dart' as _i8d83qca;
import 'sheets/models/cell_history_entry.dart' as _ij1xvs09;
import 'sheets/models/cell_history_page.dart' as _i09xo3k8;
import 'sheets/models/revert_result.dart' as _ilv3hlxr;
import 'sheets/models/revert_skip.dart' as _ipqum05l;
import 'sheets/models/rows/enums/dimension.dart' as _ilnsyzhq;
import 'sheets/models/rows/enums/embedded_object_kind.dart' as _ihfpm0ve;
import 'sheets/models/rows/enums/horizontal_align.dart' as _iofwzekn;
import 'sheets/models/rows/enums/recalc_mode.dart' as _i0z9m4nl;
import 'sheets/models/rows/enums/script_build_status.dart' as _io4oc09s;
import 'sheets/models/rows/enums/sheet_kind.dart' as _i8ne06ql;
import 'sheets/models/rows/enums/trigger_kind.dart' as _irmtoho8;
import 'sheets/models/rows/enums/vertical_align.dart' as _ivf2txqv;
import 'sheets/models/rows/enums/wrap_strategy.dart' as _iz9rjt8b;
import 'sheets/models/sheets_activity_summary.dart' as _iaehez21;
import 'sheets/models/sheets_contributor_stat.dart' as _i9yjzgjk;
import 'sheets/scripts/models/script_authorization_view.dart' as _icjzxy6x;
import 'sheets/scripts/models/script_compile_response.dart' as _iq0xpzf7;
import 'sheets/scripts/models/script_execution.dart' as _i4bc0fek;
import 'sheets/scripts/models/script_execution_kind.dart' as _inqz9v2t;
import 'sheets/scripts/models/script_execution_status.dart' as _ira26pfa;
import 'sheets/scripts/models/script_fetch_response.dart' as _is04pxv8;
import 'sheets/scripts/models/script_run_response.dart' as _is0mvar3;
import 'sheets/scripts/models/script_runtime_kind.dart' as _iy0fj18f;
import 'slides/ai/models/slides_ai_alt_text.dart' as _iwj0qehd;
import 'slides/ai/models/slides_ai_apply_result.dart' as _ix6z7bmu;
import 'slides/ai/models/slides_ai_build_result.dart' as _isdksxfl;
import 'slides/ai/models/slides_ai_design_rank.dart' as _i154xjj9;
import 'slides/ai/models/slides_ai_note.dart' as _itoukaix;
import 'slides/ai/models/slides_ai_outline_request.dart' as _i225jf90;
import 'slides/ai/models/slides_ai_preview.dart' as _ioipp9xy;
import 'slides/ai/models/slides_ai_preview_call.dart' as _iuzye628;
import 'slides/ai/models/slides_ai_rewrite_request.dart' as _ixaahmd2;
import 'slides/charts/models/chart_link_probe.dart' as _i7q1o3oi;
import 'slides/charts/models/chart_link_state.dart' as _i3ysrjbx;
import 'slides/charts/models/chart_link_status.dart' as _is6z3tpy;
import 'slides/charts/models/chart_snapshot_view.dart' as _iua8dx49;
import 'slides/charts/models/chart_source_list.dart' as _iq1h9id2;
import 'slides/charts/models/chart_source_summary.dart' as _inygrvyi;
import 'slides/models/rows/enums/build_kind.dart' as _ipok3hcm;
import 'slides/models/rows/enums/build_trigger.dart' as _isb6wks2;
import 'slides/models/rows/enums/deck_appearance.dart' as _isf9v7y6;
import 'slides/models/rows/enums/placeholder_type.dart' as _i4oq3vgh;
import 'slides/models/rows/enums/slide_element_kind.dart' as _isah8148;
import 'slides/models/rows/enums/slide_size_preset.dart' as _isghg0k1;
import 'slides/models/rows/enums/table_dimension.dart' as _i5m4q7yg;
import 'slides/present/models/presentation_event.dart' as _iz9vxb2f;
import 'slides/present/models/presentation_join.dart' as _ih25cwup;
import 'slides/present/models/presentation_pairing_target.dart' as _i6know5x;
import 'slides/present/models/presentation_participant.dart' as _ijgt5qi7;
import 'slides/present/models/presentation_role.dart' as _i4d7um9r;
import 'slides/present/models/presentation_session_info.dart' as _ig7ln54r;
import 'slides/present/models/presentation_state.dart' as _i95fngt4;
import 'slides/present/models/presentation_update.dart' as _ijdad65m;
import 'write/messages/doc_client_message.dart' as _imbts8if;
import 'write/messages/doc_server_message.dart' as _icpkpcrn;
import 'write/models/convert_for_insert_result.dart' as _igqu3xcv;
import 'write/models/doc_reject_code.dart' as _i5srcd7q;
import 'write/models/document.dart' as _i4sx4pml;
import 'write/models/document_info.dart' as _iu022vpf;
import 'write/models/document_meta_change.dart' as _ir38bcqq;
import 'write/models/document_meta_patch.dart' as _inkjv0lb;
import 'write/models/document_meta_view.dart' as _icsyekcn;
import 'write/models/document_op.dart' as _iufsprkx;
import 'write/models/document_op_kind.dart' as _igr6xq1c;
import 'write/models/document_op_view.dart' as _issmv319;
import 'write/models/document_snapshot.dart' as _i2cnn8i8;
import 'write/models/document_snapshot_view.dart' as _i0cy62lm;
import 'write/models/export_progress_event.dart' as _is1ql5wp;
import 'write/models/export_progress_kind.dart' as _isdjhzgs;
import 'write/models/export_result_view.dart' as _if2sngze;
import 'write/models/theme_conflict_exception.dart' as _ittnhawp;
import 'write/models/write_diff_author.dart' as _ii88i7dv;
import 'write/models/write_diff_view.dart' as _idky93gt;
import 'write/models/write_theme.dart' as _iynqrh33;
import 'write/models/write_theme_revision.dart' as _i7pbwt05;
import 'write/models/write_theme_revision_view.dart' as _ick3mhj2;
import 'write/models/write_theme_view.dart' as _ixbjd26z;
import 'write/models/write_version_document.dart' as _is9bkd9t;
export 'platform/activity/activity_dashboard.dart';
export 'platform/activity/activity_event.dart';
export 'platform/activity/activity_event_view.dart';
export 'platform/activity/activity_trend_point.dart';
export 'platform/activity/activity_type.dart';
export 'platform/activity/activity_viewer.dart';
export 'platform/ai/models/ai_apply_mode.dart';
export 'platform/ai/models/ai_provider.dart';
export 'platform/ai/models/ai_provider_key_view.dart';
export 'platform/ai/models/ai_quality.dart';
export 'platform/ai/models/ai_usage.dart';
export 'platform/ai/models/ai_user_setting.dart';
export 'platform/ai/models/assistant_context_hints.dart';
export 'platform/ai/models/assistant_event.dart';
export 'platform/ai/models/assistant_event_type.dart';
export 'platform/ai/models/assistant_message.dart';
export 'platform/ai/models/assistant_message_view.dart';
export 'platform/ai/models/assistant_status.dart';
export 'platform/ai/models/assistant_thread.dart';
export 'platform/ai/models/assistant_thread_detail.dart';
export 'platform/ai/models/assistant_thread_view.dart';
export 'platform/ai/models/inline_ai_event.dart';
export 'platform/ai/models/inline_ai_event_type.dart';
export 'platform/ai/models/inline_ai_request.dart';
export 'platform/ai/models/proofread_event.dart';
export 'platform/ai/models/proofread_issue.dart';
export 'platform/board/models/board_area.dart';
export 'platform/board/models/board_author.dart';
export 'platform/board/models/board_bundle_suggestion.dart';
export 'platform/board/models/board_bundle_suggestion_view.dart';
export 'platform/board/models/board_comment.dart';
export 'platform/board/models/board_comment_view.dart';
export 'platform/board/models/board_counts.dart';
export 'platform/board/models/board_event_kind.dart';
export 'platform/board/models/board_flag.dart';
export 'platform/board/models/board_flag_reason.dart';
export 'platform/board/models/board_flag_view.dart';
export 'platform/board/models/board_list_query.dart';
export 'platform/board/models/board_me.dart';
export 'platform/board/models/board_moderation.dart';
export 'platform/board/models/board_moderation_action.dart';
export 'platform/board/models/board_post.dart';
export 'platform/board/models/board_post_draft.dart';
export 'platform/board/models/board_post_event.dart';
export 'platform/board/models/board_post_kind.dart';
export 'platform/board/models/board_post_list_item.dart';
export 'platform/board/models/board_post_page.dart';
export 'platform/board/models/board_post_status.dart';
export 'platform/board/models/board_post_view.dart';
export 'platform/board/models/board_review_counts.dart';
export 'platform/board/models/board_review_item.dart';
export 'platform/board/models/board_review_section.dart';
export 'platform/board/models/board_signal.dart';
export 'platform/board/models/board_similar_post.dart';
export 'platform/board/models/board_size.dart';
export 'platform/board/models/board_sort.dart';
export 'platform/board/models/board_target_kind.dart';
export 'platform/board/models/board_task.dart';
export 'platform/board/models/board_task_page.dart';
export 'platform/board/models/board_task_ref.dart';
export 'platform/board/models/board_task_status.dart';
export 'platform/board/models/board_task_view.dart';
export 'platform/board/models/board_triage_state.dart';
export 'platform/board/models/board_user_profile.dart';
export 'platform/board/models/board_vote.dart';
export 'platform/board/models/board_vote_result.dart';
export 'platform/comments/comment.dart';
export 'platform/comments/comment_anchor_kind.dart';
export 'platform/comments/comment_event.dart';
export 'platform/comments/comment_event_kind.dart';
export 'platform/comments/comment_filter.dart';
export 'platform/comments/comment_status.dart';
export 'platform/comments/comment_system_event.dart';
export 'platform/comments/comment_thread.dart';
export 'platform/comments/comment_thread_view.dart';
export 'platform/comments/comment_view.dart';
export 'platform/common/access_role.dart';
export 'platform/common/actor_kind.dart';
export 'platform/common/wonky_error_code.dart';
export 'platform/common/wonky_exception.dart';
export 'platform/drive/drive_change.dart';
export 'platform/drive/drive_change_kind.dart';
export 'platform/drive/drive_import_options.dart';
export 'platform/drive/drive_item.dart';
export 'platform/drive/drive_item_kind.dart';
export 'platform/drive/drive_item_user_state.dart';
export 'platform/drive/drive_item_view.dart';
export 'platform/drive/drive_list_filter.dart';
export 'platform/drive/drive_list_page.dart';
export 'platform/drive/drive_owner_filter.dart';
export 'platform/drive/drive_search_filters.dart';
export 'platform/drive/drive_sort.dart';
export 'platform/drive/drive_sort_field.dart';
export 'platform/drive/drive_view.dart';
export 'platform/drive/file_category.dart';
export 'platform/drive/file_upload_progress.dart';
export 'platform/drive/file_upload_request.dart';
export 'platform/drive/file_upload_start.dart';
export 'platform/drive/file_upload_state.dart';
export 'platform/drive/import_report_view.dart';
export 'platform/drive/import_warning_view.dart';
export 'platform/drive/storage_list_filter.dart';
export 'platform/drive/storage_usage.dart';
export 'platform/drive/template_category.dart';
export 'platform/drive/template_preview_style.dart';
export 'platform/drive/template_view.dart';
export 'platform/drive/upload_conflict_mode.dart';
export 'platform/feedback/feedback_kind.dart';
export 'platform/feedback/feedback_submission.dart';
export 'platform/files/file_upload_ticket.dart';
export 'platform/files/file_url_view.dart';
export 'platform/files/stored_file.dart';
export 'platform/files/stored_file_kind.dart';
export 'platform/files/stored_file_status.dart';
export 'platform/mcp/ui_bridge/ui_bridge_message.dart';
export 'platform/meta/feature_flags.dart';
export 'platform/meta/protocol_info.dart';
export 'platform/meta/server_limits.dart';
export 'platform/notifications/notification_event.dart';
export 'platform/notifications/notification_kind.dart';
export 'platform/notifications/notification_page.dart';
export 'platform/notifications/notification_view.dart';
export 'platform/notifications/user_notification.dart';
export 'platform/presence/participant.dart';
export 'platform/presence/presence_event.dart';
export 'platform/presence/presence_state.dart';
export 'platform/presence/presence_update.dart';
export 'platform/revlog/messages/rev_client_message.dart';
export 'platform/revlog/messages/rev_server_message.dart';
export 'platform/revlog/models/rev_file_info.dart';
export 'platform/revlog/models/rev_file_kind.dart';
export 'platform/revlog/models/rev_op_view.dart';
export 'platform/revlog/models/rev_page.dart';
export 'platform/revlog/models/rev_page_kind.dart';
export 'platform/revlog/models/rev_page_request.dart';
export 'platform/revlog/models/rev_reject_code.dart';
export 'platform/sharing/access_request.dart';
export 'platform/sharing/access_request_outcome.dart';
export 'platform/sharing/access_request_view.dart';
export 'platform/sharing/drive_item_permission.dart';
export 'platform/sharing/invite_resolution.dart';
export 'platform/sharing/item_sharing_settings.dart';
export 'platform/sharing/ownership_transfer.dart';
export 'platform/sharing/ownership_transfer_view.dart';
export 'platform/sharing/permission_view.dart';
export 'platform/sharing/share_link.dart';
export 'platform/sharing/share_link_view.dart';
export 'platform/sharing/sharing_info.dart';
export 'platform/storage/quota_exceeded_details.dart';
export 'platform/users/access_token_view.dart';
export 'platform/users/account_deletion_preview.dart';
export 'platform/users/app_theme_mode.dart';
export 'platform/users/created_access_token.dart';
export 'platform/users/ui_density.dart';
export 'platform/users/user_preferences.dart';
export 'platform/users/user_preferences_patch.dart';
export 'platform/users/user_profile.dart';
export 'platform/users/user_profile_view.dart';
export 'platform/users/user_summary.dart';
export 'platform/versions/item_version.dart';
export 'platform/versions/item_version_view.dart';
export 'platform/versions/version_kind.dart';
export 'platform/versions/version_restore_result.dart';
export 'platform/versions/version_storage.dart';
export 'sheets/ai/models/sheets_ai_apply_result.dart';
export 'sheets/ai/models/sheets_ai_cell_request.dart';
export 'sheets/ai/models/sheets_ai_cell_result.dart';
export 'sheets/ai/models/sheets_ai_preview.dart';
export 'sheets/ai/models/sheets_ai_preview_call.dart';
export 'sheets/ai/models/sheets_ai_preview_cell.dart';
export 'sheets/ai/models/sheets_fill_proposal.dart';
export 'sheets/ai/models/sheets_fill_row.dart';
export 'sheets/ai/models/sheets_formula_suggestion.dart';
export 'sheets/imports/models/sheets_import_progress.dart';
export 'sheets/imports/models/sheets_import_status.dart';
export 'sheets/models/cell_history_entry.dart';
export 'sheets/models/cell_history_page.dart';
export 'sheets/models/revert_result.dart';
export 'sheets/models/revert_skip.dart';
export 'sheets/models/rows/enums/dimension.dart';
export 'sheets/models/rows/enums/embedded_object_kind.dart';
export 'sheets/models/rows/enums/horizontal_align.dart';
export 'sheets/models/rows/enums/recalc_mode.dart';
export 'sheets/models/rows/enums/script_build_status.dart';
export 'sheets/models/rows/enums/sheet_kind.dart';
export 'sheets/models/rows/enums/trigger_kind.dart';
export 'sheets/models/rows/enums/vertical_align.dart';
export 'sheets/models/rows/enums/wrap_strategy.dart';
export 'sheets/models/sheets_activity_summary.dart';
export 'sheets/models/sheets_contributor_stat.dart';
export 'sheets/scripts/models/script_authorization_view.dart';
export 'sheets/scripts/models/script_compile_response.dart';
export 'sheets/scripts/models/script_execution.dart';
export 'sheets/scripts/models/script_execution_kind.dart';
export 'sheets/scripts/models/script_execution_status.dart';
export 'sheets/scripts/models/script_fetch_response.dart';
export 'sheets/scripts/models/script_run_response.dart';
export 'sheets/scripts/models/script_runtime_kind.dart';
export 'slides/ai/models/slides_ai_alt_text.dart';
export 'slides/ai/models/slides_ai_apply_result.dart';
export 'slides/ai/models/slides_ai_build_result.dart';
export 'slides/ai/models/slides_ai_design_rank.dart';
export 'slides/ai/models/slides_ai_note.dart';
export 'slides/ai/models/slides_ai_outline_request.dart';
export 'slides/ai/models/slides_ai_preview.dart';
export 'slides/ai/models/slides_ai_preview_call.dart';
export 'slides/ai/models/slides_ai_rewrite_request.dart';
export 'slides/charts/models/chart_link_probe.dart';
export 'slides/charts/models/chart_link_state.dart';
export 'slides/charts/models/chart_link_status.dart';
export 'slides/charts/models/chart_snapshot_view.dart';
export 'slides/charts/models/chart_source_list.dart';
export 'slides/charts/models/chart_source_summary.dart';
export 'slides/models/rows/enums/build_kind.dart';
export 'slides/models/rows/enums/build_trigger.dart';
export 'slides/models/rows/enums/deck_appearance.dart';
export 'slides/models/rows/enums/placeholder_type.dart';
export 'slides/models/rows/enums/slide_element_kind.dart';
export 'slides/models/rows/enums/slide_size_preset.dart';
export 'slides/models/rows/enums/table_dimension.dart';
export 'slides/present/models/presentation_event.dart';
export 'slides/present/models/presentation_join.dart';
export 'slides/present/models/presentation_pairing_target.dart';
export 'slides/present/models/presentation_participant.dart';
export 'slides/present/models/presentation_role.dart';
export 'slides/present/models/presentation_session_info.dart';
export 'slides/present/models/presentation_state.dart';
export 'slides/present/models/presentation_update.dart';
export 'write/messages/doc_client_message.dart';
export 'write/messages/doc_server_message.dart';
export 'write/models/convert_for_insert_result.dart';
export 'write/models/doc_reject_code.dart';
export 'write/models/document.dart';
export 'write/models/document_info.dart';
export 'write/models/document_meta_change.dart';
export 'write/models/document_meta_patch.dart';
export 'write/models/document_meta_view.dart';
export 'write/models/document_op.dart';
export 'write/models/document_op_kind.dart';
export 'write/models/document_op_view.dart';
export 'write/models/document_snapshot.dart';
export 'write/models/document_snapshot_view.dart';
export 'write/models/export_progress_event.dart';
export 'write/models/export_progress_kind.dart';
export 'write/models/export_result_view.dart';
export 'write/models/theme_conflict_exception.dart';
export 'write/models/write_diff_author.dart';
export 'write/models/write_diff_view.dart';
export 'write/models/write_theme.dart';
export 'write/models/write_theme_revision.dart';
export 'write/models/write_theme_revision_view.dart';
export 'write/models/write_theme_view.dart';
export 'write/models/write_version_document.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager
    implements _isc.ProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _isc.ProtocolDeserialization get deserializationMetadata =>
      _isc.ProtocolDeserialization.cached(
        this,
        types: const [
          _isc.getType<_izr1y672.ActivityDashboard>,
          _isc.getType<_iatdjl5p.ActivityEvent>,
          _isc.getType<_isa7sjzq.ActivityEventView>,
          _isc.getType<_ighcq381.ActivityTrendPoint>,
          _isc.getType<_i50cy468.ActivityType>,
          _isc.getType<_ikcwdr17.ActivityViewer>,
          _isc.getType<_iyja8k5e.AiApplyMode>,
          _isc.getType<_ir7z75mb.AiProvider>,
          _isc.getType<_ic2q2fwi.AiProviderKeyView>,
          _isc.getType<_iviyoyk9.AiQuality>,
          _isc.getType<_i7i53on7.AiUsage>,
          _isc.getType<_imx2nn1q.AiUserSetting>,
          _isc.getType<_ic7e83wd.AssistantContextHints>,
          _isc.getType<_imp4tsxo.AssistantEvent>,
          _isc.getType<_id6kvqt9.AssistantEventType>,
          _isc.getType<_i8cittxq.AssistantMessage>,
          _isc.getType<_i4rkdm2k.AssistantMessageView>,
          _isc.getType<_ia2m3j3v.AssistantStatus>,
          _isc.getType<_iaq6rutx.AssistantThread>,
          _isc.getType<_i4iv0swm.AssistantThreadDetail>,
          _isc.getType<_iohdfqf1.AssistantThreadView>,
          _isc.getType<_i8ghcs7p.InlineAiEvent>,
          _isc.getType<_i6pcz5z6.InlineAiEventType>,
          _isc.getType<_i4m43iwr.InlineAiRequest>,
          _isc.getType<_ie0jt2ne.ProofreadEvent>,
          _isc.getType<_ivmxemza.ProofreadIssue>,
          _isc.getType<_i0ag0upm.BoardArea>,
          _isc.getType<_ika8r7fc.BoardAuthor>,
          _isc.getType<_ilo15wk2.BoardBundleSuggestion>,
          _isc.getType<_iin47lv0.BoardBundleSuggestionView>,
          _isc.getType<_ijz5flk6.BoardComment>,
          _isc.getType<_ipkjmsg5.BoardCommentView>,
          _isc.getType<_iswbp1jv.BoardCounts>,
          _isc.getType<_ita8snxr.BoardEventKind>,
          _isc.getType<_i0y7d0xd.BoardFlag>,
          _isc.getType<_iwc3b6vo.BoardFlagReason>,
          _isc.getType<_i5pjfe5s.BoardFlagView>,
          _isc.getType<_igcoqerx.BoardListQuery>,
          _isc.getType<_iu9hvv8z.BoardMe>,
          _isc.getType<_in0hwjmy.BoardModeration>,
          _isc.getType<_i5jfu168.BoardModerationAction>,
          _isc.getType<_i7xps6dm.BoardPost>,
          _isc.getType<_izvgi5ni.BoardPostDraft>,
          _isc.getType<_ibl25moa.BoardPostEvent>,
          _isc.getType<_iui4x9zg.BoardPostKind>,
          _isc.getType<_iq3f61ec.BoardPostListItem>,
          _isc.getType<_i1stsytz.BoardPostPage>,
          _isc.getType<_il200dga.BoardPostStatus>,
          _isc.getType<_ijjd81zg.BoardPostView>,
          _isc.getType<_im7v2irk.BoardReviewCounts>,
          _isc.getType<_id33cro1.BoardReviewItem>,
          _isc.getType<_izs2n8vy.BoardReviewSection>,
          _isc.getType<_ieemxbgb.BoardSignal>,
          _isc.getType<_in3cjdcj.BoardSimilarPost>,
          _isc.getType<_ivbgicm7.BoardSize>,
          _isc.getType<_itz4727j.BoardSort>,
          _isc.getType<_i2gir90g.BoardTargetKind>,
          _isc.getType<_iv26y3a1.BoardTask>,
          _isc.getType<_illpt7x2.BoardTaskPage>,
          _isc.getType<_idsjzf6h.BoardTaskRef>,
          _isc.getType<_i4a2ekwp.BoardTaskStatus>,
          _isc.getType<_ifz7dmuf.BoardTaskView>,
          _isc.getType<_iso7mdvm.BoardTriageState>,
          _isc.getType<_i516sz1w.BoardUserProfile>,
          _isc.getType<_ifuo09i6.BoardVote>,
          _isc.getType<_ie24iiog.BoardVoteResult>,
          _isc.getType<_iyixppck.Comment>,
          _isc.getType<_iw81twtc.CommentAnchorKind>,
          _isc.getType<_imlsyj2p.CommentEvent>,
          _isc.getType<_ih1mb6x5.CommentEventKind>,
          _isc.getType<_il5y6tzr.CommentFilter>,
          _isc.getType<_iowdswxe.CommentStatus>,
          _isc.getType<_i94wr3td.CommentSystemEvent>,
          _isc.getType<_ijog60vm.CommentThread>,
          _isc.getType<_i818olql.CommentThreadView>,
          _isc.getType<_i4xrxro7.CommentView>,
          _isc.getType<_ii98prcs.AccessRole>,
          _isc.getType<_i2wc4tyi.ActorKind>,
          _isc.getType<_inb0isem.WonkyErrorCode>,
          _isc.getType<_igdswlrw.WonkyException>,
          _isc.getType<_iktwt5zz.DriveChange>,
          _isc.getType<_ijoqbs82.DriveChangeKind>,
          _isc.getType<_ig2nixhn.DriveImportOptions>,
          _isc.getType<_inge8yy2.DriveItem>,
          _isc.getType<_i8mh39wa.DriveItemKind>,
          _isc.getType<_i0g2m831.DriveItemUserState>,
          _isc.getType<_infxyf98.DriveItemView>,
          _isc.getType<_ivypvw0m.DriveListFilter>,
          _isc.getType<_iavdhzsq.DriveListPage>,
          _isc.getType<_if1dhg5z.DriveOwnerFilter>,
          _isc.getType<_i6k3d1nc.DriveSearchFilters>,
          _isc.getType<_iu13r4v2.DriveSort>,
          _isc.getType<_ix0g8yw4.DriveSortField>,
          _isc.getType<_ipww3kqy.DriveView>,
          _isc.getType<_iez45i4u.FileCategory>,
          _isc.getType<_ilt75p4e.FileUploadProgress>,
          _isc.getType<_iqpb2qv1.FileUploadRequest>,
          _isc.getType<_imf3tnfq.FileUploadStart>,
          _isc.getType<_ia04wt6m.FileUploadState>,
          _isc.getType<_i68yhxa0.ImportReportView>,
          _isc.getType<_i48sm9f2.ImportWarningView>,
          _isc.getType<_i8hnug6t.StorageListFilter>,
          _isc.getType<_i26hsnhw.StorageUsage>,
          _isc.getType<_iiedu4vz.TemplateCategory>,
          _isc.getType<_i6rg3vdh.TemplatePreviewStyle>,
          _isc.getType<_i2ox7ta1.TemplateView>,
          _isc.getType<_io3ccr8w.UploadConflictMode>,
          _isc.getType<_iv1sk0e8.FeedbackKind>,
          _isc.getType<_ilhpki98.FeedbackSubmission>,
          _isc.getType<_irrzp8p9.FileUploadTicket>,
          _isc.getType<_itzt3x6d.FileUrlView>,
          _isc.getType<_im8eh74x.StoredFile>,
          _isc.getType<_i45dmz4a.StoredFileKind>,
          _isc.getType<_ik7q11oy.StoredFileStatus>,
          _isc.getType<_ichw8k0i.UiBridgeCancel>,
          _isc.getType<_ichw8k0i.UiBridgeHello>,
          _isc.getType<_ichw8k0i.UiBridgeRequest>,
          _isc.getType<_ichw8k0i.UiBridgeResponse>,
          _isc.getType<_ichw8k0i.UiBridgeStatus>,
          _isc.getType<_ichw8k0i.UiBridgeStop>,
          _isc.getType<_ichw8k0i.UiBridgeWelcome>,
          _isc.getType<_ivk6eyvx.FeatureFlags>,
          _isc.getType<_ib575x0y.ProtocolInfo>,
          _isc.getType<_i28el0at.ServerLimits>,
          _isc.getType<_iexg4yzt.NotificationEvent>,
          _isc.getType<_iqlnbbfp.NotificationKind>,
          _isc.getType<_i3r1eo8q.NotificationPage>,
          _isc.getType<_izfzk9h3.NotificationView>,
          _isc.getType<_ik59hiyp.UserNotification>,
          _isc.getType<_iylgyc33.Participant>,
          _isc.getType<_i8r9afjv.PresenceFollowerCount>,
          _isc.getType<_i8r9afjv.PresenceHints>,
          _isc.getType<_i8r9afjv.PresenceJoined>,
          _isc.getType<_i8r9afjv.PresenceLeft>,
          _isc.getType<_i8r9afjv.PresenceNotice>,
          _isc.getType<_i8r9afjv.PresenceRoster>,
          _isc.getType<_i8r9afjv.PresenceUpdated>,
          _isc.getType<_ik055xb9.PresenceState>,
          _isc.getType<_isz2sju0.PresenceUpdate>,
          _isc.getType<_ie6clghy.RevAck>,
          _isc.getType<_i6ck957q.RevPing>,
          _isc.getType<_i6ck957q.RevRequestOps>,
          _isc.getType<_i6ck957q.RevSubmit>,
          _isc.getType<_ie6clghy.RevInit>,
          _isc.getType<_ie6clghy.RevPong>,
          _isc.getType<_ie6clghy.RevRejected>,
          _isc.getType<_ie6clghy.RevRemoteOp>,
          _isc.getType<_ie6clghy.RevResync>,
          _isc.getType<_ie6clghy.RevRoleChanged>,
          _isc.getType<_ihwy023l.RevFileInfo>,
          _isc.getType<_iwkehf4e.RevFileKind>,
          _isc.getType<_it4o2pk5.RevOpView>,
          _isc.getType<_ium7xjeg.RevPage>,
          _isc.getType<_i3q3ua5p.RevPageKind>,
          _isc.getType<_if03ikx4.RevPageRequest>,
          _isc.getType<_iilsyt4b.RevRejectCode>,
          _isc.getType<_i8scn8dm.AccessRequest>,
          _isc.getType<_i7trut12.AccessRequestOutcome>,
          _isc.getType<_iimp60a4.AccessRequestView>,
          _isc.getType<_iuzgacy4.DriveItemPermission>,
          _isc.getType<_ikeljole.InviteResolution>,
          _isc.getType<_ih3711er.ItemSharingSettings>,
          _isc.getType<_ijwxtu30.OwnershipTransfer>,
          _isc.getType<_iilpsf9g.OwnershipTransferView>,
          _isc.getType<_iead0ok9.PermissionView>,
          _isc.getType<_it712lg1.ShareLink>,
          _isc.getType<_iw2xoohn.ShareLinkView>,
          _isc.getType<_itd24os1.SharingInfo>,
          _isc.getType<_ifxa4vxf.QuotaExceededDetails>,
          _isc.getType<_izha9j5m.AccessTokenView>,
          _isc.getType<_iq4dupwy.AccountDeletionPreview>,
          _isc.getType<_i6azdr3n.AppThemeMode>,
          _isc.getType<_iru4pv75.CreatedAccessToken>,
          _isc.getType<_i5lc4gt0.UiDensity>,
          _isc.getType<_i501u5m5.UserPreferences>,
          _isc.getType<_id95rrz2.UserPreferencesPatch>,
          _isc.getType<_ihzl7wbq.UserProfile>,
          _isc.getType<_iufqmqtc.UserProfileView>,
          _isc.getType<_i6y7tspy.UserSummary>,
          _isc.getType<_i7jb115m.ItemVersion>,
          _isc.getType<_ipbapjbz.ItemVersionView>,
          _isc.getType<_in0fdl1f.VersionKind>,
          _isc.getType<_in38zbga.VersionRestoreResult>,
          _isc.getType<_i5u6d6t4.VersionStorage>,
          _isc.getType<_iuzj1jin.SheetsAiApplyResult>,
          _isc.getType<_iljqbz3a.SheetsAiCellRequest>,
          _isc.getType<_im85lt6z.SheetsAiCellResult>,
          _isc.getType<_i4t3jyqe.SheetsAiPreview>,
          _isc.getType<_idzstekp.SheetsAiPreviewCall>,
          _isc.getType<_i49726iv.SheetsAiPreviewCell>,
          _isc.getType<_izbpavhd.SheetsFillProposal>,
          _isc.getType<_i1gi0ui2.SheetsFillRow>,
          _isc.getType<_i2bhah0l.SheetsFormulaSuggestion>,
          _isc.getType<_iaf43n69.SheetsImportProgress>,
          _isc.getType<_i8d83qca.SheetsImportStatus>,
          _isc.getType<_ij1xvs09.CellHistoryEntry>,
          _isc.getType<_i09xo3k8.CellHistoryPage>,
          _isc.getType<_ilv3hlxr.RevertResult>,
          _isc.getType<_ipqum05l.RevertSkip>,
          _isc.getType<_ilnsyzhq.Dimension>,
          _isc.getType<_ihfpm0ve.EmbeddedObjectKind>,
          _isc.getType<_iofwzekn.HorizontalAlign>,
          _isc.getType<_i0z9m4nl.RecalcMode>,
          _isc.getType<_io4oc09s.ScriptBuildStatus>,
          _isc.getType<_i8ne06ql.SheetKind>,
          _isc.getType<_irmtoho8.TriggerKind>,
          _isc.getType<_ivf2txqv.VerticalAlign>,
          _isc.getType<_iz9rjt8b.WrapStrategy>,
          _isc.getType<_iaehez21.SheetsActivitySummary>,
          _isc.getType<_i9yjzgjk.SheetsContributorStat>,
          _isc.getType<_icjzxy6x.ScriptAuthorizationView>,
          _isc.getType<_iq0xpzf7.ScriptCompileResponse>,
          _isc.getType<_i4bc0fek.ScriptExecution>,
          _isc.getType<_inqz9v2t.ScriptExecutionKind>,
          _isc.getType<_ira26pfa.ScriptExecutionStatus>,
          _isc.getType<_is04pxv8.ScriptFetchResponse>,
          _isc.getType<_is0mvar3.ScriptRunResponse>,
          _isc.getType<_iy0fj18f.ScriptRuntimeKind>,
          _isc.getType<_iwj0qehd.SlidesAiAltText>,
          _isc.getType<_ix6z7bmu.SlidesAiApplyResult>,
          _isc.getType<_isdksxfl.SlidesAiBuildResult>,
          _isc.getType<_i154xjj9.SlidesAiDesignRank>,
          _isc.getType<_itoukaix.SlidesAiNote>,
          _isc.getType<_i225jf90.SlidesAiOutlineRequest>,
          _isc.getType<_ioipp9xy.SlidesAiPreview>,
          _isc.getType<_iuzye628.SlidesAiPreviewCall>,
          _isc.getType<_ixaahmd2.SlidesAiRewriteRequest>,
          _isc.getType<_i7q1o3oi.ChartLinkProbe>,
          _isc.getType<_i3ysrjbx.ChartLinkState>,
          _isc.getType<_is6z3tpy.ChartLinkStatus>,
          _isc.getType<_iua8dx49.ChartSnapshotView>,
          _isc.getType<_iq1h9id2.ChartSourceList>,
          _isc.getType<_inygrvyi.ChartSourceSummary>,
          _isc.getType<_ipok3hcm.BuildKind>,
          _isc.getType<_isb6wks2.BuildTrigger>,
          _isc.getType<_isf9v7y6.DeckAppearance>,
          _isc.getType<_i4oq3vgh.PlaceholderType>,
          _isc.getType<_isah8148.SlideElementKind>,
          _isc.getType<_isghg0k1.SlideSizePreset>,
          _isc.getType<_i5m4q7yg.TableDimension>,
          _isc.getType<_iz9vxb2f.PresentationCommandEvent>,
          _isc.getType<_ijdad65m.PresentationCommandUpdate>,
          _isc.getType<_ijdad65m.PresentationEndUpdate>,
          _isc.getType<_iz9vxb2f.PresentationEndedEvent>,
          _isc.getType<_iz9vxb2f.PresentationInkEvent>,
          _isc.getType<_iz9vxb2f.PresentationLaserEvent>,
          _isc.getType<_iz9vxb2f.PresentationPairingEvent>,
          _isc.getType<_iz9vxb2f.PresentationPresenterEvent>,
          _isc.getType<_iz9vxb2f.PresentationRosterEvent>,
          _isc.getType<_iz9vxb2f.PresentationStateEvent>,
          _isc.getType<_iz9vxb2f.PresentationWelcome>,
          _isc.getType<_ijdad65m.PresentationInkUpdate>,
          _isc.getType<_ih25cwup.PresentationJoin>,
          _isc.getType<_ijdad65m.PresentationLaserUpdate>,
          _isc.getType<_i6know5x.PresentationPairingTarget>,
          _isc.getType<_ijdad65m.PresentationPairingUpdate>,
          _isc.getType<_ijgt5qi7.PresentationParticipant>,
          _isc.getType<_i4d7um9r.PresentationRole>,
          _isc.getType<_ig7ln54r.PresentationSessionInfo>,
          _isc.getType<_i95fngt4.PresentationState>,
          _isc.getType<_ijdad65m.PresentationStateUpdate>,
          _isc.getType<_icpkpcrn.DocAck>,
          _isc.getType<_imbts8if.DocCursorUpdate>,
          _isc.getType<_imbts8if.DocHashCheck>,
          _isc.getType<_imbts8if.DocPing>,
          _isc.getType<_imbts8if.DocRequestOps>,
          _isc.getType<_imbts8if.DocSubmitOp>,
          _isc.getType<_icpkpcrn.DocHashResult>,
          _isc.getType<_icpkpcrn.DocInit>,
          _isc.getType<_icpkpcrn.DocMetaChanged>,
          _isc.getType<_icpkpcrn.DocOpRejected>,
          _isc.getType<_icpkpcrn.DocParticipantJoined>,
          _isc.getType<_icpkpcrn.DocParticipantLeft>,
          _isc.getType<_icpkpcrn.DocPong>,
          _isc.getType<_icpkpcrn.DocRemoteCursor>,
          _isc.getType<_icpkpcrn.DocRemoteOp>,
          _isc.getType<_icpkpcrn.DocRoleChanged>,
          _isc.getType<_igqu3xcv.ConvertForInsertResult>,
          _isc.getType<_i5srcd7q.DocRejectCode>,
          _isc.getType<_i4sx4pml.Document>,
          _isc.getType<_iu022vpf.DocumentInfo>,
          _isc.getType<_ir38bcqq.DocumentMetaChange>,
          _isc.getType<_inkjv0lb.DocumentMetaPatch>,
          _isc.getType<_icsyekcn.DocumentMetaView>,
          _isc.getType<_iufsprkx.DocumentOp>,
          _isc.getType<_igr6xq1c.DocumentOpKind>,
          _isc.getType<_issmv319.DocumentOpView>,
          _isc.getType<_i2cnn8i8.DocumentSnapshot>,
          _isc.getType<_i0cy62lm.DocumentSnapshotView>,
          _isc.getType<_is1ql5wp.ExportProgressEvent>,
          _isc.getType<_isdjhzgs.ExportProgressKind>,
          _isc.getType<_if2sngze.ExportResultView>,
          _isc.getType<_ittnhawp.ThemeConflictException>,
          _isc.getType<_ii88i7dv.WriteDiffAuthor>,
          _isc.getType<_idky93gt.WriteDiffView>,
          _isc.getType<_iynqrh33.WriteTheme>,
          _isc.getType<_i7pbwt05.WriteThemeRevision>,
          _isc.getType<_ick3mhj2.WriteThemeRevisionView>,
          _isc.getType<_ixbjd26z.WriteThemeView>,
          _isc.getType<_is9bkd9t.WriteVersionDocument>,
          _isc.getType<_izr1y672.ActivityDashboard?>,
          _isc.getType<_iatdjl5p.ActivityEvent?>,
          _isc.getType<_isa7sjzq.ActivityEventView?>,
          _isc.getType<_ighcq381.ActivityTrendPoint?>,
          _isc.getType<_i50cy468.ActivityType?>,
          _isc.getType<_ikcwdr17.ActivityViewer?>,
          _isc.getType<_iyja8k5e.AiApplyMode?>,
          _isc.getType<_ir7z75mb.AiProvider?>,
          _isc.getType<_ic2q2fwi.AiProviderKeyView?>,
          _isc.getType<_iviyoyk9.AiQuality?>,
          _isc.getType<_i7i53on7.AiUsage?>,
          _isc.getType<_imx2nn1q.AiUserSetting?>,
          _isc.getType<_ic7e83wd.AssistantContextHints?>,
          _isc.getType<_imp4tsxo.AssistantEvent?>,
          _isc.getType<_id6kvqt9.AssistantEventType?>,
          _isc.getType<_i8cittxq.AssistantMessage?>,
          _isc.getType<_i4rkdm2k.AssistantMessageView?>,
          _isc.getType<_ia2m3j3v.AssistantStatus?>,
          _isc.getType<_iaq6rutx.AssistantThread?>,
          _isc.getType<_i4iv0swm.AssistantThreadDetail?>,
          _isc.getType<_iohdfqf1.AssistantThreadView?>,
          _isc.getType<_i8ghcs7p.InlineAiEvent?>,
          _isc.getType<_i6pcz5z6.InlineAiEventType?>,
          _isc.getType<_i4m43iwr.InlineAiRequest?>,
          _isc.getType<_ie0jt2ne.ProofreadEvent?>,
          _isc.getType<_ivmxemza.ProofreadIssue?>,
          _isc.getType<_i0ag0upm.BoardArea?>,
          _isc.getType<_ika8r7fc.BoardAuthor?>,
          _isc.getType<_ilo15wk2.BoardBundleSuggestion?>,
          _isc.getType<_iin47lv0.BoardBundleSuggestionView?>,
          _isc.getType<_ijz5flk6.BoardComment?>,
          _isc.getType<_ipkjmsg5.BoardCommentView?>,
          _isc.getType<_iswbp1jv.BoardCounts?>,
          _isc.getType<_ita8snxr.BoardEventKind?>,
          _isc.getType<_i0y7d0xd.BoardFlag?>,
          _isc.getType<_iwc3b6vo.BoardFlagReason?>,
          _isc.getType<_i5pjfe5s.BoardFlagView?>,
          _isc.getType<_igcoqerx.BoardListQuery?>,
          _isc.getType<_iu9hvv8z.BoardMe?>,
          _isc.getType<_in0hwjmy.BoardModeration?>,
          _isc.getType<_i5jfu168.BoardModerationAction?>,
          _isc.getType<_i7xps6dm.BoardPost?>,
          _isc.getType<_izvgi5ni.BoardPostDraft?>,
          _isc.getType<_ibl25moa.BoardPostEvent?>,
          _isc.getType<_iui4x9zg.BoardPostKind?>,
          _isc.getType<_iq3f61ec.BoardPostListItem?>,
          _isc.getType<_i1stsytz.BoardPostPage?>,
          _isc.getType<_il200dga.BoardPostStatus?>,
          _isc.getType<_ijjd81zg.BoardPostView?>,
          _isc.getType<_im7v2irk.BoardReviewCounts?>,
          _isc.getType<_id33cro1.BoardReviewItem?>,
          _isc.getType<_izs2n8vy.BoardReviewSection?>,
          _isc.getType<_ieemxbgb.BoardSignal?>,
          _isc.getType<_in3cjdcj.BoardSimilarPost?>,
          _isc.getType<_ivbgicm7.BoardSize?>,
          _isc.getType<_itz4727j.BoardSort?>,
          _isc.getType<_i2gir90g.BoardTargetKind?>,
          _isc.getType<_iv26y3a1.BoardTask?>,
          _isc.getType<_illpt7x2.BoardTaskPage?>,
          _isc.getType<_idsjzf6h.BoardTaskRef?>,
          _isc.getType<_i4a2ekwp.BoardTaskStatus?>,
          _isc.getType<_ifz7dmuf.BoardTaskView?>,
          _isc.getType<_iso7mdvm.BoardTriageState?>,
          _isc.getType<_i516sz1w.BoardUserProfile?>,
          _isc.getType<_ifuo09i6.BoardVote?>,
          _isc.getType<_ie24iiog.BoardVoteResult?>,
          _isc.getType<_iyixppck.Comment?>,
          _isc.getType<_iw81twtc.CommentAnchorKind?>,
          _isc.getType<_imlsyj2p.CommentEvent?>,
          _isc.getType<_ih1mb6x5.CommentEventKind?>,
          _isc.getType<_il5y6tzr.CommentFilter?>,
          _isc.getType<_iowdswxe.CommentStatus?>,
          _isc.getType<_i94wr3td.CommentSystemEvent?>,
          _isc.getType<_ijog60vm.CommentThread?>,
          _isc.getType<_i818olql.CommentThreadView?>,
          _isc.getType<_i4xrxro7.CommentView?>,
          _isc.getType<_ii98prcs.AccessRole?>,
          _isc.getType<_i2wc4tyi.ActorKind?>,
          _isc.getType<_inb0isem.WonkyErrorCode?>,
          _isc.getType<_igdswlrw.WonkyException?>,
          _isc.getType<_iktwt5zz.DriveChange?>,
          _isc.getType<_ijoqbs82.DriveChangeKind?>,
          _isc.getType<_ig2nixhn.DriveImportOptions?>,
          _isc.getType<_inge8yy2.DriveItem?>,
          _isc.getType<_i8mh39wa.DriveItemKind?>,
          _isc.getType<_i0g2m831.DriveItemUserState?>,
          _isc.getType<_infxyf98.DriveItemView?>,
          _isc.getType<_ivypvw0m.DriveListFilter?>,
          _isc.getType<_iavdhzsq.DriveListPage?>,
          _isc.getType<_if1dhg5z.DriveOwnerFilter?>,
          _isc.getType<_i6k3d1nc.DriveSearchFilters?>,
          _isc.getType<_iu13r4v2.DriveSort?>,
          _isc.getType<_ix0g8yw4.DriveSortField?>,
          _isc.getType<_ipww3kqy.DriveView?>,
          _isc.getType<_iez45i4u.FileCategory?>,
          _isc.getType<_ilt75p4e.FileUploadProgress?>,
          _isc.getType<_iqpb2qv1.FileUploadRequest?>,
          _isc.getType<_imf3tnfq.FileUploadStart?>,
          _isc.getType<_ia04wt6m.FileUploadState?>,
          _isc.getType<_i68yhxa0.ImportReportView?>,
          _isc.getType<_i48sm9f2.ImportWarningView?>,
          _isc.getType<_i8hnug6t.StorageListFilter?>,
          _isc.getType<_i26hsnhw.StorageUsage?>,
          _isc.getType<_iiedu4vz.TemplateCategory?>,
          _isc.getType<_i6rg3vdh.TemplatePreviewStyle?>,
          _isc.getType<_i2ox7ta1.TemplateView?>,
          _isc.getType<_io3ccr8w.UploadConflictMode?>,
          _isc.getType<_iv1sk0e8.FeedbackKind?>,
          _isc.getType<_ilhpki98.FeedbackSubmission?>,
          _isc.getType<_irrzp8p9.FileUploadTicket?>,
          _isc.getType<_itzt3x6d.FileUrlView?>,
          _isc.getType<_im8eh74x.StoredFile?>,
          _isc.getType<_i45dmz4a.StoredFileKind?>,
          _isc.getType<_ik7q11oy.StoredFileStatus?>,
          _isc.getType<_ichw8k0i.UiBridgeCancel?>,
          _isc.getType<_ichw8k0i.UiBridgeHello?>,
          _isc.getType<_ichw8k0i.UiBridgeRequest?>,
          _isc.getType<_ichw8k0i.UiBridgeResponse?>,
          _isc.getType<_ichw8k0i.UiBridgeStatus?>,
          _isc.getType<_ichw8k0i.UiBridgeStop?>,
          _isc.getType<_ichw8k0i.UiBridgeWelcome?>,
          _isc.getType<_ivk6eyvx.FeatureFlags?>,
          _isc.getType<_ib575x0y.ProtocolInfo?>,
          _isc.getType<_i28el0at.ServerLimits?>,
          _isc.getType<_iexg4yzt.NotificationEvent?>,
          _isc.getType<_iqlnbbfp.NotificationKind?>,
          _isc.getType<_i3r1eo8q.NotificationPage?>,
          _isc.getType<_izfzk9h3.NotificationView?>,
          _isc.getType<_ik59hiyp.UserNotification?>,
          _isc.getType<_iylgyc33.Participant?>,
          _isc.getType<_i8r9afjv.PresenceFollowerCount?>,
          _isc.getType<_i8r9afjv.PresenceHints?>,
          _isc.getType<_i8r9afjv.PresenceJoined?>,
          _isc.getType<_i8r9afjv.PresenceLeft?>,
          _isc.getType<_i8r9afjv.PresenceNotice?>,
          _isc.getType<_i8r9afjv.PresenceRoster?>,
          _isc.getType<_i8r9afjv.PresenceUpdated?>,
          _isc.getType<_ik055xb9.PresenceState?>,
          _isc.getType<_isz2sju0.PresenceUpdate?>,
          _isc.getType<_ie6clghy.RevAck?>,
          _isc.getType<_i6ck957q.RevPing?>,
          _isc.getType<_i6ck957q.RevRequestOps?>,
          _isc.getType<_i6ck957q.RevSubmit?>,
          _isc.getType<_ie6clghy.RevInit?>,
          _isc.getType<_ie6clghy.RevPong?>,
          _isc.getType<_ie6clghy.RevRejected?>,
          _isc.getType<_ie6clghy.RevRemoteOp?>,
          _isc.getType<_ie6clghy.RevResync?>,
          _isc.getType<_ie6clghy.RevRoleChanged?>,
          _isc.getType<_ihwy023l.RevFileInfo?>,
          _isc.getType<_iwkehf4e.RevFileKind?>,
          _isc.getType<_it4o2pk5.RevOpView?>,
          _isc.getType<_ium7xjeg.RevPage?>,
          _isc.getType<_i3q3ua5p.RevPageKind?>,
          _isc.getType<_if03ikx4.RevPageRequest?>,
          _isc.getType<_iilsyt4b.RevRejectCode?>,
          _isc.getType<_i8scn8dm.AccessRequest?>,
          _isc.getType<_i7trut12.AccessRequestOutcome?>,
          _isc.getType<_iimp60a4.AccessRequestView?>,
          _isc.getType<_iuzgacy4.DriveItemPermission?>,
          _isc.getType<_ikeljole.InviteResolution?>,
          _isc.getType<_ih3711er.ItemSharingSettings?>,
          _isc.getType<_ijwxtu30.OwnershipTransfer?>,
          _isc.getType<_iilpsf9g.OwnershipTransferView?>,
          _isc.getType<_iead0ok9.PermissionView?>,
          _isc.getType<_it712lg1.ShareLink?>,
          _isc.getType<_iw2xoohn.ShareLinkView?>,
          _isc.getType<_itd24os1.SharingInfo?>,
          _isc.getType<_ifxa4vxf.QuotaExceededDetails?>,
          _isc.getType<_izha9j5m.AccessTokenView?>,
          _isc.getType<_iq4dupwy.AccountDeletionPreview?>,
          _isc.getType<_i6azdr3n.AppThemeMode?>,
          _isc.getType<_iru4pv75.CreatedAccessToken?>,
          _isc.getType<_i5lc4gt0.UiDensity?>,
          _isc.getType<_i501u5m5.UserPreferences?>,
          _isc.getType<_id95rrz2.UserPreferencesPatch?>,
          _isc.getType<_ihzl7wbq.UserProfile?>,
          _isc.getType<_iufqmqtc.UserProfileView?>,
          _isc.getType<_i6y7tspy.UserSummary?>,
          _isc.getType<_i7jb115m.ItemVersion?>,
          _isc.getType<_ipbapjbz.ItemVersionView?>,
          _isc.getType<_in0fdl1f.VersionKind?>,
          _isc.getType<_in38zbga.VersionRestoreResult?>,
          _isc.getType<_i5u6d6t4.VersionStorage?>,
          _isc.getType<_iuzj1jin.SheetsAiApplyResult?>,
          _isc.getType<_iljqbz3a.SheetsAiCellRequest?>,
          _isc.getType<_im85lt6z.SheetsAiCellResult?>,
          _isc.getType<_i4t3jyqe.SheetsAiPreview?>,
          _isc.getType<_idzstekp.SheetsAiPreviewCall?>,
          _isc.getType<_i49726iv.SheetsAiPreviewCell?>,
          _isc.getType<_izbpavhd.SheetsFillProposal?>,
          _isc.getType<_i1gi0ui2.SheetsFillRow?>,
          _isc.getType<_i2bhah0l.SheetsFormulaSuggestion?>,
          _isc.getType<_iaf43n69.SheetsImportProgress?>,
          _isc.getType<_i8d83qca.SheetsImportStatus?>,
          _isc.getType<_ij1xvs09.CellHistoryEntry?>,
          _isc.getType<_i09xo3k8.CellHistoryPage?>,
          _isc.getType<_ilv3hlxr.RevertResult?>,
          _isc.getType<_ipqum05l.RevertSkip?>,
          _isc.getType<_ilnsyzhq.Dimension?>,
          _isc.getType<_ihfpm0ve.EmbeddedObjectKind?>,
          _isc.getType<_iofwzekn.HorizontalAlign?>,
          _isc.getType<_i0z9m4nl.RecalcMode?>,
          _isc.getType<_io4oc09s.ScriptBuildStatus?>,
          _isc.getType<_i8ne06ql.SheetKind?>,
          _isc.getType<_irmtoho8.TriggerKind?>,
          _isc.getType<_ivf2txqv.VerticalAlign?>,
          _isc.getType<_iz9rjt8b.WrapStrategy?>,
          _isc.getType<_iaehez21.SheetsActivitySummary?>,
          _isc.getType<_i9yjzgjk.SheetsContributorStat?>,
          _isc.getType<_icjzxy6x.ScriptAuthorizationView?>,
          _isc.getType<_iq0xpzf7.ScriptCompileResponse?>,
          _isc.getType<_i4bc0fek.ScriptExecution?>,
          _isc.getType<_inqz9v2t.ScriptExecutionKind?>,
          _isc.getType<_ira26pfa.ScriptExecutionStatus?>,
          _isc.getType<_is04pxv8.ScriptFetchResponse?>,
          _isc.getType<_is0mvar3.ScriptRunResponse?>,
          _isc.getType<_iy0fj18f.ScriptRuntimeKind?>,
          _isc.getType<_iwj0qehd.SlidesAiAltText?>,
          _isc.getType<_ix6z7bmu.SlidesAiApplyResult?>,
          _isc.getType<_isdksxfl.SlidesAiBuildResult?>,
          _isc.getType<_i154xjj9.SlidesAiDesignRank?>,
          _isc.getType<_itoukaix.SlidesAiNote?>,
          _isc.getType<_i225jf90.SlidesAiOutlineRequest?>,
          _isc.getType<_ioipp9xy.SlidesAiPreview?>,
          _isc.getType<_iuzye628.SlidesAiPreviewCall?>,
          _isc.getType<_ixaahmd2.SlidesAiRewriteRequest?>,
          _isc.getType<_i7q1o3oi.ChartLinkProbe?>,
          _isc.getType<_i3ysrjbx.ChartLinkState?>,
          _isc.getType<_is6z3tpy.ChartLinkStatus?>,
          _isc.getType<_iua8dx49.ChartSnapshotView?>,
          _isc.getType<_iq1h9id2.ChartSourceList?>,
          _isc.getType<_inygrvyi.ChartSourceSummary?>,
          _isc.getType<_ipok3hcm.BuildKind?>,
          _isc.getType<_isb6wks2.BuildTrigger?>,
          _isc.getType<_isf9v7y6.DeckAppearance?>,
          _isc.getType<_i4oq3vgh.PlaceholderType?>,
          _isc.getType<_isah8148.SlideElementKind?>,
          _isc.getType<_isghg0k1.SlideSizePreset?>,
          _isc.getType<_i5m4q7yg.TableDimension?>,
          _isc.getType<_iz9vxb2f.PresentationCommandEvent?>,
          _isc.getType<_ijdad65m.PresentationCommandUpdate?>,
          _isc.getType<_ijdad65m.PresentationEndUpdate?>,
          _isc.getType<_iz9vxb2f.PresentationEndedEvent?>,
          _isc.getType<_iz9vxb2f.PresentationInkEvent?>,
          _isc.getType<_iz9vxb2f.PresentationLaserEvent?>,
          _isc.getType<_iz9vxb2f.PresentationPairingEvent?>,
          _isc.getType<_iz9vxb2f.PresentationPresenterEvent?>,
          _isc.getType<_iz9vxb2f.PresentationRosterEvent?>,
          _isc.getType<_iz9vxb2f.PresentationStateEvent?>,
          _isc.getType<_iz9vxb2f.PresentationWelcome?>,
          _isc.getType<_ijdad65m.PresentationInkUpdate?>,
          _isc.getType<_ih25cwup.PresentationJoin?>,
          _isc.getType<_ijdad65m.PresentationLaserUpdate?>,
          _isc.getType<_i6know5x.PresentationPairingTarget?>,
          _isc.getType<_ijdad65m.PresentationPairingUpdate?>,
          _isc.getType<_ijgt5qi7.PresentationParticipant?>,
          _isc.getType<_i4d7um9r.PresentationRole?>,
          _isc.getType<_ig7ln54r.PresentationSessionInfo?>,
          _isc.getType<_i95fngt4.PresentationState?>,
          _isc.getType<_ijdad65m.PresentationStateUpdate?>,
          _isc.getType<_icpkpcrn.DocAck?>,
          _isc.getType<_imbts8if.DocCursorUpdate?>,
          _isc.getType<_imbts8if.DocHashCheck?>,
          _isc.getType<_imbts8if.DocPing?>,
          _isc.getType<_imbts8if.DocRequestOps?>,
          _isc.getType<_imbts8if.DocSubmitOp?>,
          _isc.getType<_icpkpcrn.DocHashResult?>,
          _isc.getType<_icpkpcrn.DocInit?>,
          _isc.getType<_icpkpcrn.DocMetaChanged?>,
          _isc.getType<_icpkpcrn.DocOpRejected?>,
          _isc.getType<_icpkpcrn.DocParticipantJoined?>,
          _isc.getType<_icpkpcrn.DocParticipantLeft?>,
          _isc.getType<_icpkpcrn.DocPong?>,
          _isc.getType<_icpkpcrn.DocRemoteCursor?>,
          _isc.getType<_icpkpcrn.DocRemoteOp?>,
          _isc.getType<_icpkpcrn.DocRoleChanged?>,
          _isc.getType<_igqu3xcv.ConvertForInsertResult?>,
          _isc.getType<_i5srcd7q.DocRejectCode?>,
          _isc.getType<_i4sx4pml.Document?>,
          _isc.getType<_iu022vpf.DocumentInfo?>,
          _isc.getType<_ir38bcqq.DocumentMetaChange?>,
          _isc.getType<_inkjv0lb.DocumentMetaPatch?>,
          _isc.getType<_icsyekcn.DocumentMetaView?>,
          _isc.getType<_iufsprkx.DocumentOp?>,
          _isc.getType<_igr6xq1c.DocumentOpKind?>,
          _isc.getType<_issmv319.DocumentOpView?>,
          _isc.getType<_i2cnn8i8.DocumentSnapshot?>,
          _isc.getType<_i0cy62lm.DocumentSnapshotView?>,
          _isc.getType<_is1ql5wp.ExportProgressEvent?>,
          _isc.getType<_isdjhzgs.ExportProgressKind?>,
          _isc.getType<_if2sngze.ExportResultView?>,
          _isc.getType<_ittnhawp.ThemeConflictException?>,
          _isc.getType<_ii88i7dv.WriteDiffAuthor?>,
          _isc.getType<_idky93gt.WriteDiffView?>,
          _isc.getType<_iynqrh33.WriteTheme?>,
          _isc.getType<_i7pbwt05.WriteThemeRevision?>,
          _isc.getType<_ick3mhj2.WriteThemeRevisionView?>,
          _isc.getType<_ixbjd26z.WriteThemeView?>,
          _isc.getType<_is9bkd9t.WriteVersionDocument?>,
          _isc.getType<List<_ikcwdr17.ActivityViewer>>,
          _isc.getType<List<_ighcq381.ActivityTrendPoint>>,
          _isc.getType<List<String>>,
          _isc.getType<List<String>?>,
          _isc.getType<List<_i4rkdm2k.AssistantMessageView>>,
          _isc.getType<List<_ivmxemza.ProofreadIssue>>,
          _isc.getType<List<_ivmxemza.ProofreadIssue>?>,
          _isc.getType<List<int>>,
          _isc.getType<List<_iq3f61ec.BoardPostListItem>>,
          _isc.getType<List<_i5pjfe5s.BoardFlagView>>,
          _isc.getType<List<_i5pjfe5s.BoardFlagView>?>,
          _isc.getType<List<_il200dga.BoardPostStatus>>,
          _isc.getType<List<_i0ag0upm.BoardArea>>,
          _isc.getType<List<_ivbgicm7.BoardSize>>,
          _isc.getType<Map<String, double>>,
          _isc.getType<Map<String, double>?>,
          _isc.getType<List<_ifz7dmuf.BoardTaskView>>,
          _isc.getType<List<_i4xrxro7.CommentView>>,
          _isc.getType<List<_i6y7tspy.UserSummary>>,
          _isc.getType<Map<String, List<int>>>,
          _isc.getType<List<_i8mh39wa.DriveItemKind>>,
          _isc.getType<List<_i8mh39wa.DriveItemKind>?>,
          _isc.getType<List<_iez45i4u.FileCategory>>,
          _isc.getType<List<_iez45i4u.FileCategory>?>,
          _isc.getType<List<_infxyf98.DriveItemView>>,
          _isc.getType<List<_i48sm9f2.ImportWarningView>>,
          _isc.getType<List<_izfzk9h3.NotificationView>>,
          _isc.getType<List<_iylgyc33.Participant>>,
          _isc.getType<List<_it4o2pk5.RevOpView>>,
          _isc.getType<List<_it4o2pk5.RevOpView>?>,
          _isc.getType<List<_isc.UuidValue>>,
          _isc.getType<List<_isc.UuidValue>?>,
          _isc.getType<List<_iead0ok9.PermissionView>>,
          _isc.getType<List<_iimp60a4.AccessRequestView>>,
          _isc.getType<List<_idzstekp.SheetsAiPreviewCall>>,
          _isc.getType<List<_i49726iv.SheetsAiPreviewCell>>,
          _isc.getType<List<_i1gi0ui2.SheetsFillRow>>,
          _isc.getType<List<_ij1xvs09.CellHistoryEntry>>,
          _isc.getType<List<_ipqum05l.RevertSkip>>,
          _isc.getType<Map<String, Map<int, int>>>,
          _isc.getType<Map<int, int>>,
          _isc.getType<List<_i9yjzgjk.SheetsContributorStat>>,
          _isc.getType<Map<String, int>>,
          _isc.getType<List<_iuzye628.SlidesAiPreviewCall>>,
          _isc.getType<List<_inygrvyi.ChartSourceSummary>>,
          _isc.getType<List<_ijgt5qi7.PresentationParticipant>>,
          _isc.getType<List<_issmv319.DocumentOpView>>,
          _isc.getType<List<_issmv319.DocumentOpView>?>,
          _isc.getType<List<_i48sm9f2.ImportWarningView>?>,
          _isc.getType<List<_ii88i7dv.WriteDiffAuthor>>,
          _isc.getType<List<_i2rhb3qx.AssistantThreadView>>,
          _isc.getType<List<_iesojpvb.BoardCommentView>>,
          _isc.getType<List<_ikfdrh1p.BoardSimilarPost>>,
          _isc.getType<List<_i325i6jq.BoardTaskStatus>>,
          _isc.getType<List<_i3y77bov.BoardReviewItem>>,
          _isc.getType<List<int>>,
          _isc.getType<List<_i94c7q23.BoardBundleSuggestionView>>,
          _isc.getType<List<_i2c85fb0.CommentThreadView>>,
          _isc.getType<List<int>?>,
          _isc.getType<List<_iatsgjjq.DriveItemView>>,
          _isc.getType<List<_isc.UuidValue>>,
          _isc.getType<List<_i1pzk6fp.TemplateView>>,
          _isc.getType<List<_itempttd.ActivityEventView>>,
          _isc.getType<List<_i4i1hokq.FileUrlView>>,
          _isc.getType<List<String>>,
          _isc.getType<List<_ip6swqsj.AccessTokenView>>,
          _isc.getType<List<_iq7femvs.UserSummary>>,
          _isc.getType<List<_itqtmykd.ItemVersionView>>,
          _isc.getType<List<_i2syfqhi.SheetsFillRow>>,
          _isc.getType<List<String>?>,
          _isc.getType<List<_ivc6ykj9.SheetsAiCellResult>>,
          _isc.getType<List<_ibrzlkni.SheetsAiCellRequest>>,
          _isc.getType<List<_iq15rk0l.RevOpView>>,
          _isc.getType<Map<String, String>>,
          _isc.getType<Map<String, String?>>,
          _isc.getType<List<_ijdpewvc.ScriptExecution>>,
          _isc.getType<List<_iascr37x.SlidesAiNote>>,
          _isc.getType<List<_iqd8jbjp.SlidesAiAltText>>,
          _isc.getType<List<_ifavqmyp.SlidesAiDesignRank>>,
          _isc.getType<List<_idvbn12y.ChartLinkStatus>>,
          _isc.getType<List<_ipgr9tcd.ChartLinkProbe>>,
          _isc.getType<List<_i8x9070n.DocumentOpView>>,
          _isc.getType<List<_i2zuh8f2.WriteThemeView>>,
          _isc.getType<List<_igytjuh5.WriteThemeRevisionView>>,
        ],
        modules: const [
          _iaic.Protocol.new,
          _iacc.Protocol.new,
        ],
      );

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _izr1y672.ActivityDashboard) {
      return _izr1y672.ActivityDashboard.fromJson(data) as T;
    }
    if (t == _iatdjl5p.ActivityEvent) {
      return _iatdjl5p.ActivityEvent.fromJson(data) as T;
    }
    if (t == _isa7sjzq.ActivityEventView) {
      return _isa7sjzq.ActivityEventView.fromJson(data) as T;
    }
    if (t == _ighcq381.ActivityTrendPoint) {
      return _ighcq381.ActivityTrendPoint.fromJson(data) as T;
    }
    if (t == _i50cy468.ActivityType) {
      return _i50cy468.ActivityType.fromJson(data) as T;
    }
    if (t == _ikcwdr17.ActivityViewer) {
      return _ikcwdr17.ActivityViewer.fromJson(data) as T;
    }
    if (t == _iyja8k5e.AiApplyMode) {
      return _iyja8k5e.AiApplyMode.fromJson(data) as T;
    }
    if (t == _ir7z75mb.AiProvider) {
      return _ir7z75mb.AiProvider.fromJson(data) as T;
    }
    if (t == _ic2q2fwi.AiProviderKeyView) {
      return _ic2q2fwi.AiProviderKeyView.fromJson(data) as T;
    }
    if (t == _iviyoyk9.AiQuality) {
      return _iviyoyk9.AiQuality.fromJson(data) as T;
    }
    if (t == _i7i53on7.AiUsage) {
      return _i7i53on7.AiUsage.fromJson(data) as T;
    }
    if (t == _imx2nn1q.AiUserSetting) {
      return _imx2nn1q.AiUserSetting.fromJson(data) as T;
    }
    if (t == _ic7e83wd.AssistantContextHints) {
      return _ic7e83wd.AssistantContextHints.fromJson(data) as T;
    }
    if (t == _imp4tsxo.AssistantEvent) {
      return _imp4tsxo.AssistantEvent.fromJson(data) as T;
    }
    if (t == _id6kvqt9.AssistantEventType) {
      return _id6kvqt9.AssistantEventType.fromJson(data) as T;
    }
    if (t == _i8cittxq.AssistantMessage) {
      return _i8cittxq.AssistantMessage.fromJson(data) as T;
    }
    if (t == _i4rkdm2k.AssistantMessageView) {
      return _i4rkdm2k.AssistantMessageView.fromJson(data) as T;
    }
    if (t == _ia2m3j3v.AssistantStatus) {
      return _ia2m3j3v.AssistantStatus.fromJson(data) as T;
    }
    if (t == _iaq6rutx.AssistantThread) {
      return _iaq6rutx.AssistantThread.fromJson(data) as T;
    }
    if (t == _i4iv0swm.AssistantThreadDetail) {
      return _i4iv0swm.AssistantThreadDetail.fromJson(data) as T;
    }
    if (t == _iohdfqf1.AssistantThreadView) {
      return _iohdfqf1.AssistantThreadView.fromJson(data) as T;
    }
    if (t == _i8ghcs7p.InlineAiEvent) {
      return _i8ghcs7p.InlineAiEvent.fromJson(data) as T;
    }
    if (t == _i6pcz5z6.InlineAiEventType) {
      return _i6pcz5z6.InlineAiEventType.fromJson(data) as T;
    }
    if (t == _i4m43iwr.InlineAiRequest) {
      return _i4m43iwr.InlineAiRequest.fromJson(data) as T;
    }
    if (t == _ie0jt2ne.ProofreadEvent) {
      return _ie0jt2ne.ProofreadEvent.fromJson(data) as T;
    }
    if (t == _ivmxemza.ProofreadIssue) {
      return _ivmxemza.ProofreadIssue.fromJson(data) as T;
    }
    if (t == _i0ag0upm.BoardArea) {
      return _i0ag0upm.BoardArea.fromJson(data) as T;
    }
    if (t == _ika8r7fc.BoardAuthor) {
      return _ika8r7fc.BoardAuthor.fromJson(data) as T;
    }
    if (t == _ilo15wk2.BoardBundleSuggestion) {
      return _ilo15wk2.BoardBundleSuggestion.fromJson(data) as T;
    }
    if (t == _iin47lv0.BoardBundleSuggestionView) {
      return _iin47lv0.BoardBundleSuggestionView.fromJson(data) as T;
    }
    if (t == _ijz5flk6.BoardComment) {
      return _ijz5flk6.BoardComment.fromJson(data) as T;
    }
    if (t == _ipkjmsg5.BoardCommentView) {
      return _ipkjmsg5.BoardCommentView.fromJson(data) as T;
    }
    if (t == _iswbp1jv.BoardCounts) {
      return _iswbp1jv.BoardCounts.fromJson(data) as T;
    }
    if (t == _ita8snxr.BoardEventKind) {
      return _ita8snxr.BoardEventKind.fromJson(data) as T;
    }
    if (t == _i0y7d0xd.BoardFlag) {
      return _i0y7d0xd.BoardFlag.fromJson(data) as T;
    }
    if (t == _iwc3b6vo.BoardFlagReason) {
      return _iwc3b6vo.BoardFlagReason.fromJson(data) as T;
    }
    if (t == _i5pjfe5s.BoardFlagView) {
      return _i5pjfe5s.BoardFlagView.fromJson(data) as T;
    }
    if (t == _igcoqerx.BoardListQuery) {
      return _igcoqerx.BoardListQuery.fromJson(data) as T;
    }
    if (t == _iu9hvv8z.BoardMe) {
      return _iu9hvv8z.BoardMe.fromJson(data) as T;
    }
    if (t == _in0hwjmy.BoardModeration) {
      return _in0hwjmy.BoardModeration.fromJson(data) as T;
    }
    if (t == _i5jfu168.BoardModerationAction) {
      return _i5jfu168.BoardModerationAction.fromJson(data) as T;
    }
    if (t == _i7xps6dm.BoardPost) {
      return _i7xps6dm.BoardPost.fromJson(data) as T;
    }
    if (t == _izvgi5ni.BoardPostDraft) {
      return _izvgi5ni.BoardPostDraft.fromJson(data) as T;
    }
    if (t == _ibl25moa.BoardPostEvent) {
      return _ibl25moa.BoardPostEvent.fromJson(data) as T;
    }
    if (t == _iui4x9zg.BoardPostKind) {
      return _iui4x9zg.BoardPostKind.fromJson(data) as T;
    }
    if (t == _iq3f61ec.BoardPostListItem) {
      return _iq3f61ec.BoardPostListItem.fromJson(data) as T;
    }
    if (t == _i1stsytz.BoardPostPage) {
      return _i1stsytz.BoardPostPage.fromJson(data) as T;
    }
    if (t == _il200dga.BoardPostStatus) {
      return _il200dga.BoardPostStatus.fromJson(data) as T;
    }
    if (t == _ijjd81zg.BoardPostView) {
      return _ijjd81zg.BoardPostView.fromJson(data) as T;
    }
    if (t == _im7v2irk.BoardReviewCounts) {
      return _im7v2irk.BoardReviewCounts.fromJson(data) as T;
    }
    if (t == _id33cro1.BoardReviewItem) {
      return _id33cro1.BoardReviewItem.fromJson(data) as T;
    }
    if (t == _izs2n8vy.BoardReviewSection) {
      return _izs2n8vy.BoardReviewSection.fromJson(data) as T;
    }
    if (t == _ieemxbgb.BoardSignal) {
      return _ieemxbgb.BoardSignal.fromJson(data) as T;
    }
    if (t == _in3cjdcj.BoardSimilarPost) {
      return _in3cjdcj.BoardSimilarPost.fromJson(data) as T;
    }
    if (t == _ivbgicm7.BoardSize) {
      return _ivbgicm7.BoardSize.fromJson(data) as T;
    }
    if (t == _itz4727j.BoardSort) {
      return _itz4727j.BoardSort.fromJson(data) as T;
    }
    if (t == _i2gir90g.BoardTargetKind) {
      return _i2gir90g.BoardTargetKind.fromJson(data) as T;
    }
    if (t == _iv26y3a1.BoardTask) {
      return _iv26y3a1.BoardTask.fromJson(data) as T;
    }
    if (t == _illpt7x2.BoardTaskPage) {
      return _illpt7x2.BoardTaskPage.fromJson(data) as T;
    }
    if (t == _idsjzf6h.BoardTaskRef) {
      return _idsjzf6h.BoardTaskRef.fromJson(data) as T;
    }
    if (t == _i4a2ekwp.BoardTaskStatus) {
      return _i4a2ekwp.BoardTaskStatus.fromJson(data) as T;
    }
    if (t == _ifz7dmuf.BoardTaskView) {
      return _ifz7dmuf.BoardTaskView.fromJson(data) as T;
    }
    if (t == _iso7mdvm.BoardTriageState) {
      return _iso7mdvm.BoardTriageState.fromJson(data) as T;
    }
    if (t == _i516sz1w.BoardUserProfile) {
      return _i516sz1w.BoardUserProfile.fromJson(data) as T;
    }
    if (t == _ifuo09i6.BoardVote) {
      return _ifuo09i6.BoardVote.fromJson(data) as T;
    }
    if (t == _ie24iiog.BoardVoteResult) {
      return _ie24iiog.BoardVoteResult.fromJson(data) as T;
    }
    if (t == _iyixppck.Comment) {
      return _iyixppck.Comment.fromJson(data) as T;
    }
    if (t == _iw81twtc.CommentAnchorKind) {
      return _iw81twtc.CommentAnchorKind.fromJson(data) as T;
    }
    if (t == _imlsyj2p.CommentEvent) {
      return _imlsyj2p.CommentEvent.fromJson(data) as T;
    }
    if (t == _ih1mb6x5.CommentEventKind) {
      return _ih1mb6x5.CommentEventKind.fromJson(data) as T;
    }
    if (t == _il5y6tzr.CommentFilter) {
      return _il5y6tzr.CommentFilter.fromJson(data) as T;
    }
    if (t == _iowdswxe.CommentStatus) {
      return _iowdswxe.CommentStatus.fromJson(data) as T;
    }
    if (t == _i94wr3td.CommentSystemEvent) {
      return _i94wr3td.CommentSystemEvent.fromJson(data) as T;
    }
    if (t == _ijog60vm.CommentThread) {
      return _ijog60vm.CommentThread.fromJson(data) as T;
    }
    if (t == _i818olql.CommentThreadView) {
      return _i818olql.CommentThreadView.fromJson(data) as T;
    }
    if (t == _i4xrxro7.CommentView) {
      return _i4xrxro7.CommentView.fromJson(data) as T;
    }
    if (t == _ii98prcs.AccessRole) {
      return _ii98prcs.AccessRole.fromJson(data) as T;
    }
    if (t == _i2wc4tyi.ActorKind) {
      return _i2wc4tyi.ActorKind.fromJson(data) as T;
    }
    if (t == _inb0isem.WonkyErrorCode) {
      return _inb0isem.WonkyErrorCode.fromJson(data) as T;
    }
    if (t == _igdswlrw.WonkyException) {
      return _igdswlrw.WonkyException.fromJson(data) as T;
    }
    if (t == _iktwt5zz.DriveChange) {
      return _iktwt5zz.DriveChange.fromJson(data) as T;
    }
    if (t == _ijoqbs82.DriveChangeKind) {
      return _ijoqbs82.DriveChangeKind.fromJson(data) as T;
    }
    if (t == _ig2nixhn.DriveImportOptions) {
      return _ig2nixhn.DriveImportOptions.fromJson(data) as T;
    }
    if (t == _inge8yy2.DriveItem) {
      return _inge8yy2.DriveItem.fromJson(data) as T;
    }
    if (t == _i8mh39wa.DriveItemKind) {
      return _i8mh39wa.DriveItemKind.fromJson(data) as T;
    }
    if (t == _i0g2m831.DriveItemUserState) {
      return _i0g2m831.DriveItemUserState.fromJson(data) as T;
    }
    if (t == _infxyf98.DriveItemView) {
      return _infxyf98.DriveItemView.fromJson(data) as T;
    }
    if (t == _ivypvw0m.DriveListFilter) {
      return _ivypvw0m.DriveListFilter.fromJson(data) as T;
    }
    if (t == _iavdhzsq.DriveListPage) {
      return _iavdhzsq.DriveListPage.fromJson(data) as T;
    }
    if (t == _if1dhg5z.DriveOwnerFilter) {
      return _if1dhg5z.DriveOwnerFilter.fromJson(data) as T;
    }
    if (t == _i6k3d1nc.DriveSearchFilters) {
      return _i6k3d1nc.DriveSearchFilters.fromJson(data) as T;
    }
    if (t == _iu13r4v2.DriveSort) {
      return _iu13r4v2.DriveSort.fromJson(data) as T;
    }
    if (t == _ix0g8yw4.DriveSortField) {
      return _ix0g8yw4.DriveSortField.fromJson(data) as T;
    }
    if (t == _ipww3kqy.DriveView) {
      return _ipww3kqy.DriveView.fromJson(data) as T;
    }
    if (t == _iez45i4u.FileCategory) {
      return _iez45i4u.FileCategory.fromJson(data) as T;
    }
    if (t == _ilt75p4e.FileUploadProgress) {
      return _ilt75p4e.FileUploadProgress.fromJson(data) as T;
    }
    if (t == _iqpb2qv1.FileUploadRequest) {
      return _iqpb2qv1.FileUploadRequest.fromJson(data) as T;
    }
    if (t == _imf3tnfq.FileUploadStart) {
      return _imf3tnfq.FileUploadStart.fromJson(data) as T;
    }
    if (t == _ia04wt6m.FileUploadState) {
      return _ia04wt6m.FileUploadState.fromJson(data) as T;
    }
    if (t == _i68yhxa0.ImportReportView) {
      return _i68yhxa0.ImportReportView.fromJson(data) as T;
    }
    if (t == _i48sm9f2.ImportWarningView) {
      return _i48sm9f2.ImportWarningView.fromJson(data) as T;
    }
    if (t == _i8hnug6t.StorageListFilter) {
      return _i8hnug6t.StorageListFilter.fromJson(data) as T;
    }
    if (t == _i26hsnhw.StorageUsage) {
      return _i26hsnhw.StorageUsage.fromJson(data) as T;
    }
    if (t == _iiedu4vz.TemplateCategory) {
      return _iiedu4vz.TemplateCategory.fromJson(data) as T;
    }
    if (t == _i6rg3vdh.TemplatePreviewStyle) {
      return _i6rg3vdh.TemplatePreviewStyle.fromJson(data) as T;
    }
    if (t == _i2ox7ta1.TemplateView) {
      return _i2ox7ta1.TemplateView.fromJson(data) as T;
    }
    if (t == _io3ccr8w.UploadConflictMode) {
      return _io3ccr8w.UploadConflictMode.fromJson(data) as T;
    }
    if (t == _iv1sk0e8.FeedbackKind) {
      return _iv1sk0e8.FeedbackKind.fromJson(data) as T;
    }
    if (t == _ilhpki98.FeedbackSubmission) {
      return _ilhpki98.FeedbackSubmission.fromJson(data) as T;
    }
    if (t == _irrzp8p9.FileUploadTicket) {
      return _irrzp8p9.FileUploadTicket.fromJson(data) as T;
    }
    if (t == _itzt3x6d.FileUrlView) {
      return _itzt3x6d.FileUrlView.fromJson(data) as T;
    }
    if (t == _im8eh74x.StoredFile) {
      return _im8eh74x.StoredFile.fromJson(data) as T;
    }
    if (t == _i45dmz4a.StoredFileKind) {
      return _i45dmz4a.StoredFileKind.fromJson(data) as T;
    }
    if (t == _ik7q11oy.StoredFileStatus) {
      return _ik7q11oy.StoredFileStatus.fromJson(data) as T;
    }
    if (t == _ichw8k0i.UiBridgeCancel) {
      return _ichw8k0i.UiBridgeCancel.fromJson(data) as T;
    }
    if (t == _ichw8k0i.UiBridgeHello) {
      return _ichw8k0i.UiBridgeHello.fromJson(data) as T;
    }
    if (t == _ichw8k0i.UiBridgeRequest) {
      return _ichw8k0i.UiBridgeRequest.fromJson(data) as T;
    }
    if (t == _ichw8k0i.UiBridgeResponse) {
      return _ichw8k0i.UiBridgeResponse.fromJson(data) as T;
    }
    if (t == _ichw8k0i.UiBridgeStatus) {
      return _ichw8k0i.UiBridgeStatus.fromJson(data) as T;
    }
    if (t == _ichw8k0i.UiBridgeStop) {
      return _ichw8k0i.UiBridgeStop.fromJson(data) as T;
    }
    if (t == _ichw8k0i.UiBridgeWelcome) {
      return _ichw8k0i.UiBridgeWelcome.fromJson(data) as T;
    }
    if (t == _ivk6eyvx.FeatureFlags) {
      return _ivk6eyvx.FeatureFlags.fromJson(data) as T;
    }
    if (t == _ib575x0y.ProtocolInfo) {
      return _ib575x0y.ProtocolInfo.fromJson(data) as T;
    }
    if (t == _i28el0at.ServerLimits) {
      return _i28el0at.ServerLimits.fromJson(data) as T;
    }
    if (t == _iexg4yzt.NotificationEvent) {
      return _iexg4yzt.NotificationEvent.fromJson(data) as T;
    }
    if (t == _iqlnbbfp.NotificationKind) {
      return _iqlnbbfp.NotificationKind.fromJson(data) as T;
    }
    if (t == _i3r1eo8q.NotificationPage) {
      return _i3r1eo8q.NotificationPage.fromJson(data) as T;
    }
    if (t == _izfzk9h3.NotificationView) {
      return _izfzk9h3.NotificationView.fromJson(data) as T;
    }
    if (t == _ik59hiyp.UserNotification) {
      return _ik59hiyp.UserNotification.fromJson(data) as T;
    }
    if (t == _iylgyc33.Participant) {
      return _iylgyc33.Participant.fromJson(data) as T;
    }
    if (t == _i8r9afjv.PresenceFollowerCount) {
      return _i8r9afjv.PresenceFollowerCount.fromJson(data) as T;
    }
    if (t == _i8r9afjv.PresenceHints) {
      return _i8r9afjv.PresenceHints.fromJson(data) as T;
    }
    if (t == _i8r9afjv.PresenceJoined) {
      return _i8r9afjv.PresenceJoined.fromJson(data) as T;
    }
    if (t == _i8r9afjv.PresenceLeft) {
      return _i8r9afjv.PresenceLeft.fromJson(data) as T;
    }
    if (t == _i8r9afjv.PresenceNotice) {
      return _i8r9afjv.PresenceNotice.fromJson(data) as T;
    }
    if (t == _i8r9afjv.PresenceRoster) {
      return _i8r9afjv.PresenceRoster.fromJson(data) as T;
    }
    if (t == _i8r9afjv.PresenceUpdated) {
      return _i8r9afjv.PresenceUpdated.fromJson(data) as T;
    }
    if (t == _ik055xb9.PresenceState) {
      return _ik055xb9.PresenceState.fromJson(data) as T;
    }
    if (t == _isz2sju0.PresenceUpdate) {
      return _isz2sju0.PresenceUpdate.fromJson(data) as T;
    }
    if (t == _ie6clghy.RevAck) {
      return _ie6clghy.RevAck.fromJson(data) as T;
    }
    if (t == _i6ck957q.RevPing) {
      return _i6ck957q.RevPing.fromJson(data) as T;
    }
    if (t == _i6ck957q.RevRequestOps) {
      return _i6ck957q.RevRequestOps.fromJson(data) as T;
    }
    if (t == _i6ck957q.RevSubmit) {
      return _i6ck957q.RevSubmit.fromJson(data) as T;
    }
    if (t == _ie6clghy.RevInit) {
      return _ie6clghy.RevInit.fromJson(data) as T;
    }
    if (t == _ie6clghy.RevPong) {
      return _ie6clghy.RevPong.fromJson(data) as T;
    }
    if (t == _ie6clghy.RevRejected) {
      return _ie6clghy.RevRejected.fromJson(data) as T;
    }
    if (t == _ie6clghy.RevRemoteOp) {
      return _ie6clghy.RevRemoteOp.fromJson(data) as T;
    }
    if (t == _ie6clghy.RevResync) {
      return _ie6clghy.RevResync.fromJson(data) as T;
    }
    if (t == _ie6clghy.RevRoleChanged) {
      return _ie6clghy.RevRoleChanged.fromJson(data) as T;
    }
    if (t == _ihwy023l.RevFileInfo) {
      return _ihwy023l.RevFileInfo.fromJson(data) as T;
    }
    if (t == _iwkehf4e.RevFileKind) {
      return _iwkehf4e.RevFileKind.fromJson(data) as T;
    }
    if (t == _it4o2pk5.RevOpView) {
      return _it4o2pk5.RevOpView.fromJson(data) as T;
    }
    if (t == _ium7xjeg.RevPage) {
      return _ium7xjeg.RevPage.fromJson(data) as T;
    }
    if (t == _i3q3ua5p.RevPageKind) {
      return _i3q3ua5p.RevPageKind.fromJson(data) as T;
    }
    if (t == _if03ikx4.RevPageRequest) {
      return _if03ikx4.RevPageRequest.fromJson(data) as T;
    }
    if (t == _iilsyt4b.RevRejectCode) {
      return _iilsyt4b.RevRejectCode.fromJson(data) as T;
    }
    if (t == _i8scn8dm.AccessRequest) {
      return _i8scn8dm.AccessRequest.fromJson(data) as T;
    }
    if (t == _i7trut12.AccessRequestOutcome) {
      return _i7trut12.AccessRequestOutcome.fromJson(data) as T;
    }
    if (t == _iimp60a4.AccessRequestView) {
      return _iimp60a4.AccessRequestView.fromJson(data) as T;
    }
    if (t == _iuzgacy4.DriveItemPermission) {
      return _iuzgacy4.DriveItemPermission.fromJson(data) as T;
    }
    if (t == _ikeljole.InviteResolution) {
      return _ikeljole.InviteResolution.fromJson(data) as T;
    }
    if (t == _ih3711er.ItemSharingSettings) {
      return _ih3711er.ItemSharingSettings.fromJson(data) as T;
    }
    if (t == _ijwxtu30.OwnershipTransfer) {
      return _ijwxtu30.OwnershipTransfer.fromJson(data) as T;
    }
    if (t == _iilpsf9g.OwnershipTransferView) {
      return _iilpsf9g.OwnershipTransferView.fromJson(data) as T;
    }
    if (t == _iead0ok9.PermissionView) {
      return _iead0ok9.PermissionView.fromJson(data) as T;
    }
    if (t == _it712lg1.ShareLink) {
      return _it712lg1.ShareLink.fromJson(data) as T;
    }
    if (t == _iw2xoohn.ShareLinkView) {
      return _iw2xoohn.ShareLinkView.fromJson(data) as T;
    }
    if (t == _itd24os1.SharingInfo) {
      return _itd24os1.SharingInfo.fromJson(data) as T;
    }
    if (t == _ifxa4vxf.QuotaExceededDetails) {
      return _ifxa4vxf.QuotaExceededDetails.fromJson(data) as T;
    }
    if (t == _izha9j5m.AccessTokenView) {
      return _izha9j5m.AccessTokenView.fromJson(data) as T;
    }
    if (t == _iq4dupwy.AccountDeletionPreview) {
      return _iq4dupwy.AccountDeletionPreview.fromJson(data) as T;
    }
    if (t == _i6azdr3n.AppThemeMode) {
      return _i6azdr3n.AppThemeMode.fromJson(data) as T;
    }
    if (t == _iru4pv75.CreatedAccessToken) {
      return _iru4pv75.CreatedAccessToken.fromJson(data) as T;
    }
    if (t == _i5lc4gt0.UiDensity) {
      return _i5lc4gt0.UiDensity.fromJson(data) as T;
    }
    if (t == _i501u5m5.UserPreferences) {
      return _i501u5m5.UserPreferences.fromJson(data) as T;
    }
    if (t == _id95rrz2.UserPreferencesPatch) {
      return _id95rrz2.UserPreferencesPatch.fromJson(data) as T;
    }
    if (t == _ihzl7wbq.UserProfile) {
      return _ihzl7wbq.UserProfile.fromJson(data) as T;
    }
    if (t == _iufqmqtc.UserProfileView) {
      return _iufqmqtc.UserProfileView.fromJson(data) as T;
    }
    if (t == _i6y7tspy.UserSummary) {
      return _i6y7tspy.UserSummary.fromJson(data) as T;
    }
    if (t == _i7jb115m.ItemVersion) {
      return _i7jb115m.ItemVersion.fromJson(data) as T;
    }
    if (t == _ipbapjbz.ItemVersionView) {
      return _ipbapjbz.ItemVersionView.fromJson(data) as T;
    }
    if (t == _in0fdl1f.VersionKind) {
      return _in0fdl1f.VersionKind.fromJson(data) as T;
    }
    if (t == _in38zbga.VersionRestoreResult) {
      return _in38zbga.VersionRestoreResult.fromJson(data) as T;
    }
    if (t == _i5u6d6t4.VersionStorage) {
      return _i5u6d6t4.VersionStorage.fromJson(data) as T;
    }
    if (t == _iuzj1jin.SheetsAiApplyResult) {
      return _iuzj1jin.SheetsAiApplyResult.fromJson(data) as T;
    }
    if (t == _iljqbz3a.SheetsAiCellRequest) {
      return _iljqbz3a.SheetsAiCellRequest.fromJson(data) as T;
    }
    if (t == _im85lt6z.SheetsAiCellResult) {
      return _im85lt6z.SheetsAiCellResult.fromJson(data) as T;
    }
    if (t == _i4t3jyqe.SheetsAiPreview) {
      return _i4t3jyqe.SheetsAiPreview.fromJson(data) as T;
    }
    if (t == _idzstekp.SheetsAiPreviewCall) {
      return _idzstekp.SheetsAiPreviewCall.fromJson(data) as T;
    }
    if (t == _i49726iv.SheetsAiPreviewCell) {
      return _i49726iv.SheetsAiPreviewCell.fromJson(data) as T;
    }
    if (t == _izbpavhd.SheetsFillProposal) {
      return _izbpavhd.SheetsFillProposal.fromJson(data) as T;
    }
    if (t == _i1gi0ui2.SheetsFillRow) {
      return _i1gi0ui2.SheetsFillRow.fromJson(data) as T;
    }
    if (t == _i2bhah0l.SheetsFormulaSuggestion) {
      return _i2bhah0l.SheetsFormulaSuggestion.fromJson(data) as T;
    }
    if (t == _iaf43n69.SheetsImportProgress) {
      return _iaf43n69.SheetsImportProgress.fromJson(data) as T;
    }
    if (t == _i8d83qca.SheetsImportStatus) {
      return _i8d83qca.SheetsImportStatus.fromJson(data) as T;
    }
    if (t == _ij1xvs09.CellHistoryEntry) {
      return _ij1xvs09.CellHistoryEntry.fromJson(data) as T;
    }
    if (t == _i09xo3k8.CellHistoryPage) {
      return _i09xo3k8.CellHistoryPage.fromJson(data) as T;
    }
    if (t == _ilv3hlxr.RevertResult) {
      return _ilv3hlxr.RevertResult.fromJson(data) as T;
    }
    if (t == _ipqum05l.RevertSkip) {
      return _ipqum05l.RevertSkip.fromJson(data) as T;
    }
    if (t == _ilnsyzhq.Dimension) {
      return _ilnsyzhq.Dimension.fromJson(data) as T;
    }
    if (t == _ihfpm0ve.EmbeddedObjectKind) {
      return _ihfpm0ve.EmbeddedObjectKind.fromJson(data) as T;
    }
    if (t == _iofwzekn.HorizontalAlign) {
      return _iofwzekn.HorizontalAlign.fromJson(data) as T;
    }
    if (t == _i0z9m4nl.RecalcMode) {
      return _i0z9m4nl.RecalcMode.fromJson(data) as T;
    }
    if (t == _io4oc09s.ScriptBuildStatus) {
      return _io4oc09s.ScriptBuildStatus.fromJson(data) as T;
    }
    if (t == _i8ne06ql.SheetKind) {
      return _i8ne06ql.SheetKind.fromJson(data) as T;
    }
    if (t == _irmtoho8.TriggerKind) {
      return _irmtoho8.TriggerKind.fromJson(data) as T;
    }
    if (t == _ivf2txqv.VerticalAlign) {
      return _ivf2txqv.VerticalAlign.fromJson(data) as T;
    }
    if (t == _iz9rjt8b.WrapStrategy) {
      return _iz9rjt8b.WrapStrategy.fromJson(data) as T;
    }
    if (t == _iaehez21.SheetsActivitySummary) {
      return _iaehez21.SheetsActivitySummary.fromJson(data) as T;
    }
    if (t == _i9yjzgjk.SheetsContributorStat) {
      return _i9yjzgjk.SheetsContributorStat.fromJson(data) as T;
    }
    if (t == _icjzxy6x.ScriptAuthorizationView) {
      return _icjzxy6x.ScriptAuthorizationView.fromJson(data) as T;
    }
    if (t == _iq0xpzf7.ScriptCompileResponse) {
      return _iq0xpzf7.ScriptCompileResponse.fromJson(data) as T;
    }
    if (t == _i4bc0fek.ScriptExecution) {
      return _i4bc0fek.ScriptExecution.fromJson(data) as T;
    }
    if (t == _inqz9v2t.ScriptExecutionKind) {
      return _inqz9v2t.ScriptExecutionKind.fromJson(data) as T;
    }
    if (t == _ira26pfa.ScriptExecutionStatus) {
      return _ira26pfa.ScriptExecutionStatus.fromJson(data) as T;
    }
    if (t == _is04pxv8.ScriptFetchResponse) {
      return _is04pxv8.ScriptFetchResponse.fromJson(data) as T;
    }
    if (t == _is0mvar3.ScriptRunResponse) {
      return _is0mvar3.ScriptRunResponse.fromJson(data) as T;
    }
    if (t == _iy0fj18f.ScriptRuntimeKind) {
      return _iy0fj18f.ScriptRuntimeKind.fromJson(data) as T;
    }
    if (t == _iwj0qehd.SlidesAiAltText) {
      return _iwj0qehd.SlidesAiAltText.fromJson(data) as T;
    }
    if (t == _ix6z7bmu.SlidesAiApplyResult) {
      return _ix6z7bmu.SlidesAiApplyResult.fromJson(data) as T;
    }
    if (t == _isdksxfl.SlidesAiBuildResult) {
      return _isdksxfl.SlidesAiBuildResult.fromJson(data) as T;
    }
    if (t == _i154xjj9.SlidesAiDesignRank) {
      return _i154xjj9.SlidesAiDesignRank.fromJson(data) as T;
    }
    if (t == _itoukaix.SlidesAiNote) {
      return _itoukaix.SlidesAiNote.fromJson(data) as T;
    }
    if (t == _i225jf90.SlidesAiOutlineRequest) {
      return _i225jf90.SlidesAiOutlineRequest.fromJson(data) as T;
    }
    if (t == _ioipp9xy.SlidesAiPreview) {
      return _ioipp9xy.SlidesAiPreview.fromJson(data) as T;
    }
    if (t == _iuzye628.SlidesAiPreviewCall) {
      return _iuzye628.SlidesAiPreviewCall.fromJson(data) as T;
    }
    if (t == _ixaahmd2.SlidesAiRewriteRequest) {
      return _ixaahmd2.SlidesAiRewriteRequest.fromJson(data) as T;
    }
    if (t == _i7q1o3oi.ChartLinkProbe) {
      return _i7q1o3oi.ChartLinkProbe.fromJson(data) as T;
    }
    if (t == _i3ysrjbx.ChartLinkState) {
      return _i3ysrjbx.ChartLinkState.fromJson(data) as T;
    }
    if (t == _is6z3tpy.ChartLinkStatus) {
      return _is6z3tpy.ChartLinkStatus.fromJson(data) as T;
    }
    if (t == _iua8dx49.ChartSnapshotView) {
      return _iua8dx49.ChartSnapshotView.fromJson(data) as T;
    }
    if (t == _iq1h9id2.ChartSourceList) {
      return _iq1h9id2.ChartSourceList.fromJson(data) as T;
    }
    if (t == _inygrvyi.ChartSourceSummary) {
      return _inygrvyi.ChartSourceSummary.fromJson(data) as T;
    }
    if (t == _ipok3hcm.BuildKind) {
      return _ipok3hcm.BuildKind.fromJson(data) as T;
    }
    if (t == _isb6wks2.BuildTrigger) {
      return _isb6wks2.BuildTrigger.fromJson(data) as T;
    }
    if (t == _isf9v7y6.DeckAppearance) {
      return _isf9v7y6.DeckAppearance.fromJson(data) as T;
    }
    if (t == _i4oq3vgh.PlaceholderType) {
      return _i4oq3vgh.PlaceholderType.fromJson(data) as T;
    }
    if (t == _isah8148.SlideElementKind) {
      return _isah8148.SlideElementKind.fromJson(data) as T;
    }
    if (t == _isghg0k1.SlideSizePreset) {
      return _isghg0k1.SlideSizePreset.fromJson(data) as T;
    }
    if (t == _i5m4q7yg.TableDimension) {
      return _i5m4q7yg.TableDimension.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationCommandEvent) {
      return _iz9vxb2f.PresentationCommandEvent.fromJson(data) as T;
    }
    if (t == _ijdad65m.PresentationCommandUpdate) {
      return _ijdad65m.PresentationCommandUpdate.fromJson(data) as T;
    }
    if (t == _ijdad65m.PresentationEndUpdate) {
      return _ijdad65m.PresentationEndUpdate.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationEndedEvent) {
      return _iz9vxb2f.PresentationEndedEvent.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationInkEvent) {
      return _iz9vxb2f.PresentationInkEvent.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationLaserEvent) {
      return _iz9vxb2f.PresentationLaserEvent.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationPairingEvent) {
      return _iz9vxb2f.PresentationPairingEvent.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationPresenterEvent) {
      return _iz9vxb2f.PresentationPresenterEvent.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationRosterEvent) {
      return _iz9vxb2f.PresentationRosterEvent.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationStateEvent) {
      return _iz9vxb2f.PresentationStateEvent.fromJson(data) as T;
    }
    if (t == _iz9vxb2f.PresentationWelcome) {
      return _iz9vxb2f.PresentationWelcome.fromJson(data) as T;
    }
    if (t == _ijdad65m.PresentationInkUpdate) {
      return _ijdad65m.PresentationInkUpdate.fromJson(data) as T;
    }
    if (t == _ih25cwup.PresentationJoin) {
      return _ih25cwup.PresentationJoin.fromJson(data) as T;
    }
    if (t == _ijdad65m.PresentationLaserUpdate) {
      return _ijdad65m.PresentationLaserUpdate.fromJson(data) as T;
    }
    if (t == _i6know5x.PresentationPairingTarget) {
      return _i6know5x.PresentationPairingTarget.fromJson(data) as T;
    }
    if (t == _ijdad65m.PresentationPairingUpdate) {
      return _ijdad65m.PresentationPairingUpdate.fromJson(data) as T;
    }
    if (t == _ijgt5qi7.PresentationParticipant) {
      return _ijgt5qi7.PresentationParticipant.fromJson(data) as T;
    }
    if (t == _i4d7um9r.PresentationRole) {
      return _i4d7um9r.PresentationRole.fromJson(data) as T;
    }
    if (t == _ig7ln54r.PresentationSessionInfo) {
      return _ig7ln54r.PresentationSessionInfo.fromJson(data) as T;
    }
    if (t == _i95fngt4.PresentationState) {
      return _i95fngt4.PresentationState.fromJson(data) as T;
    }
    if (t == _ijdad65m.PresentationStateUpdate) {
      return _ijdad65m.PresentationStateUpdate.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocAck) {
      return _icpkpcrn.DocAck.fromJson(data) as T;
    }
    if (t == _imbts8if.DocCursorUpdate) {
      return _imbts8if.DocCursorUpdate.fromJson(data) as T;
    }
    if (t == _imbts8if.DocHashCheck) {
      return _imbts8if.DocHashCheck.fromJson(data) as T;
    }
    if (t == _imbts8if.DocPing) {
      return _imbts8if.DocPing.fromJson(data) as T;
    }
    if (t == _imbts8if.DocRequestOps) {
      return _imbts8if.DocRequestOps.fromJson(data) as T;
    }
    if (t == _imbts8if.DocSubmitOp) {
      return _imbts8if.DocSubmitOp.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocHashResult) {
      return _icpkpcrn.DocHashResult.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocInit) {
      return _icpkpcrn.DocInit.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocMetaChanged) {
      return _icpkpcrn.DocMetaChanged.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocOpRejected) {
      return _icpkpcrn.DocOpRejected.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocParticipantJoined) {
      return _icpkpcrn.DocParticipantJoined.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocParticipantLeft) {
      return _icpkpcrn.DocParticipantLeft.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocPong) {
      return _icpkpcrn.DocPong.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocRemoteCursor) {
      return _icpkpcrn.DocRemoteCursor.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocRemoteOp) {
      return _icpkpcrn.DocRemoteOp.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocRoleChanged) {
      return _icpkpcrn.DocRoleChanged.fromJson(data) as T;
    }
    if (t == _igqu3xcv.ConvertForInsertResult) {
      return _igqu3xcv.ConvertForInsertResult.fromJson(data) as T;
    }
    if (t == _i5srcd7q.DocRejectCode) {
      return _i5srcd7q.DocRejectCode.fromJson(data) as T;
    }
    if (t == _i4sx4pml.Document) {
      return _i4sx4pml.Document.fromJson(data) as T;
    }
    if (t == _iu022vpf.DocumentInfo) {
      return _iu022vpf.DocumentInfo.fromJson(data) as T;
    }
    if (t == _ir38bcqq.DocumentMetaChange) {
      return _ir38bcqq.DocumentMetaChange.fromJson(data) as T;
    }
    if (t == _inkjv0lb.DocumentMetaPatch) {
      return _inkjv0lb.DocumentMetaPatch.fromJson(data) as T;
    }
    if (t == _icsyekcn.DocumentMetaView) {
      return _icsyekcn.DocumentMetaView.fromJson(data) as T;
    }
    if (t == _iufsprkx.DocumentOp) {
      return _iufsprkx.DocumentOp.fromJson(data) as T;
    }
    if (t == _igr6xq1c.DocumentOpKind) {
      return _igr6xq1c.DocumentOpKind.fromJson(data) as T;
    }
    if (t == _issmv319.DocumentOpView) {
      return _issmv319.DocumentOpView.fromJson(data) as T;
    }
    if (t == _i2cnn8i8.DocumentSnapshot) {
      return _i2cnn8i8.DocumentSnapshot.fromJson(data) as T;
    }
    if (t == _i0cy62lm.DocumentSnapshotView) {
      return _i0cy62lm.DocumentSnapshotView.fromJson(data) as T;
    }
    if (t == _is1ql5wp.ExportProgressEvent) {
      return _is1ql5wp.ExportProgressEvent.fromJson(data) as T;
    }
    if (t == _isdjhzgs.ExportProgressKind) {
      return _isdjhzgs.ExportProgressKind.fromJson(data) as T;
    }
    if (t == _if2sngze.ExportResultView) {
      return _if2sngze.ExportResultView.fromJson(data) as T;
    }
    if (t == _ittnhawp.ThemeConflictException) {
      return _ittnhawp.ThemeConflictException.fromJson(data) as T;
    }
    if (t == _ii88i7dv.WriteDiffAuthor) {
      return _ii88i7dv.WriteDiffAuthor.fromJson(data) as T;
    }
    if (t == _idky93gt.WriteDiffView) {
      return _idky93gt.WriteDiffView.fromJson(data) as T;
    }
    if (t == _iynqrh33.WriteTheme) {
      return _iynqrh33.WriteTheme.fromJson(data) as T;
    }
    if (t == _i7pbwt05.WriteThemeRevision) {
      return _i7pbwt05.WriteThemeRevision.fromJson(data) as T;
    }
    if (t == _ick3mhj2.WriteThemeRevisionView) {
      return _ick3mhj2.WriteThemeRevisionView.fromJson(data) as T;
    }
    if (t == _ixbjd26z.WriteThemeView) {
      return _ixbjd26z.WriteThemeView.fromJson(data) as T;
    }
    if (t == _is9bkd9t.WriteVersionDocument) {
      return _is9bkd9t.WriteVersionDocument.fromJson(data) as T;
    }
    if (t == _isc.getType<_izr1y672.ActivityDashboard?>()) {
      return (data != null ? _izr1y672.ActivityDashboard.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iatdjl5p.ActivityEvent?>()) {
      return (data != null ? _iatdjl5p.ActivityEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isa7sjzq.ActivityEventView?>()) {
      return (data != null ? _isa7sjzq.ActivityEventView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ighcq381.ActivityTrendPoint?>()) {
      return (data != null ? _ighcq381.ActivityTrendPoint.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i50cy468.ActivityType?>()) {
      return (data != null ? _i50cy468.ActivityType.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ikcwdr17.ActivityViewer?>()) {
      return (data != null ? _ikcwdr17.ActivityViewer.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iyja8k5e.AiApplyMode?>()) {
      return (data != null ? _iyja8k5e.AiApplyMode.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ir7z75mb.AiProvider?>()) {
      return (data != null ? _ir7z75mb.AiProvider.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ic2q2fwi.AiProviderKeyView?>()) {
      return (data != null ? _ic2q2fwi.AiProviderKeyView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iviyoyk9.AiQuality?>()) {
      return (data != null ? _iviyoyk9.AiQuality.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i7i53on7.AiUsage?>()) {
      return (data != null ? _i7i53on7.AiUsage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_imx2nn1q.AiUserSetting?>()) {
      return (data != null ? _imx2nn1q.AiUserSetting.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ic7e83wd.AssistantContextHints?>()) {
      return (data != null
              ? _ic7e83wd.AssistantContextHints.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_imp4tsxo.AssistantEvent?>()) {
      return (data != null ? _imp4tsxo.AssistantEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_id6kvqt9.AssistantEventType?>()) {
      return (data != null ? _id6kvqt9.AssistantEventType.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8cittxq.AssistantMessage?>()) {
      return (data != null ? _i8cittxq.AssistantMessage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4rkdm2k.AssistantMessageView?>()) {
      return (data != null
              ? _i4rkdm2k.AssistantMessageView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ia2m3j3v.AssistantStatus?>()) {
      return (data != null ? _ia2m3j3v.AssistantStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iaq6rutx.AssistantThread?>()) {
      return (data != null ? _iaq6rutx.AssistantThread.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4iv0swm.AssistantThreadDetail?>()) {
      return (data != null
              ? _i4iv0swm.AssistantThreadDetail.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iohdfqf1.AssistantThreadView?>()) {
      return (data != null
              ? _iohdfqf1.AssistantThreadView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i8ghcs7p.InlineAiEvent?>()) {
      return (data != null ? _i8ghcs7p.InlineAiEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6pcz5z6.InlineAiEventType?>()) {
      return (data != null ? _i6pcz5z6.InlineAiEventType.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4m43iwr.InlineAiRequest?>()) {
      return (data != null ? _i4m43iwr.InlineAiRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ie0jt2ne.ProofreadEvent?>()) {
      return (data != null ? _ie0jt2ne.ProofreadEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivmxemza.ProofreadIssue?>()) {
      return (data != null ? _ivmxemza.ProofreadIssue.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0ag0upm.BoardArea?>()) {
      return (data != null ? _i0ag0upm.BoardArea.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ika8r7fc.BoardAuthor?>()) {
      return (data != null ? _ika8r7fc.BoardAuthor.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilo15wk2.BoardBundleSuggestion?>()) {
      return (data != null
              ? _ilo15wk2.BoardBundleSuggestion.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iin47lv0.BoardBundleSuggestionView?>()) {
      return (data != null
              ? _iin47lv0.BoardBundleSuggestionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijz5flk6.BoardComment?>()) {
      return (data != null ? _ijz5flk6.BoardComment.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ipkjmsg5.BoardCommentView?>()) {
      return (data != null ? _ipkjmsg5.BoardCommentView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iswbp1jv.BoardCounts?>()) {
      return (data != null ? _iswbp1jv.BoardCounts.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ita8snxr.BoardEventKind?>()) {
      return (data != null ? _ita8snxr.BoardEventKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0y7d0xd.BoardFlag?>()) {
      return (data != null ? _i0y7d0xd.BoardFlag.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iwc3b6vo.BoardFlagReason?>()) {
      return (data != null ? _iwc3b6vo.BoardFlagReason.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5pjfe5s.BoardFlagView?>()) {
      return (data != null ? _i5pjfe5s.BoardFlagView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igcoqerx.BoardListQuery?>()) {
      return (data != null ? _igcoqerx.BoardListQuery.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iu9hvv8z.BoardMe?>()) {
      return (data != null ? _iu9hvv8z.BoardMe.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_in0hwjmy.BoardModeration?>()) {
      return (data != null ? _in0hwjmy.BoardModeration.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5jfu168.BoardModerationAction?>()) {
      return (data != null
              ? _i5jfu168.BoardModerationAction.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7xps6dm.BoardPost?>()) {
      return (data != null ? _i7xps6dm.BoardPost.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_izvgi5ni.BoardPostDraft?>()) {
      return (data != null ? _izvgi5ni.BoardPostDraft.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ibl25moa.BoardPostEvent?>()) {
      return (data != null ? _ibl25moa.BoardPostEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iui4x9zg.BoardPostKind?>()) {
      return (data != null ? _iui4x9zg.BoardPostKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iq3f61ec.BoardPostListItem?>()) {
      return (data != null ? _iq3f61ec.BoardPostListItem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i1stsytz.BoardPostPage?>()) {
      return (data != null ? _i1stsytz.BoardPostPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_il200dga.BoardPostStatus?>()) {
      return (data != null ? _il200dga.BoardPostStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ijjd81zg.BoardPostView?>()) {
      return (data != null ? _ijjd81zg.BoardPostView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_im7v2irk.BoardReviewCounts?>()) {
      return (data != null ? _im7v2irk.BoardReviewCounts.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_id33cro1.BoardReviewItem?>()) {
      return (data != null ? _id33cro1.BoardReviewItem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izs2n8vy.BoardReviewSection?>()) {
      return (data != null ? _izs2n8vy.BoardReviewSection.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ieemxbgb.BoardSignal?>()) {
      return (data != null ? _ieemxbgb.BoardSignal.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_in3cjdcj.BoardSimilarPost?>()) {
      return (data != null ? _in3cjdcj.BoardSimilarPost.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivbgicm7.BoardSize?>()) {
      return (data != null ? _ivbgicm7.BoardSize.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_itz4727j.BoardSort?>()) {
      return (data != null ? _itz4727j.BoardSort.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i2gir90g.BoardTargetKind?>()) {
      return (data != null ? _i2gir90g.BoardTargetKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv26y3a1.BoardTask?>()) {
      return (data != null ? _iv26y3a1.BoardTask.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_illpt7x2.BoardTaskPage?>()) {
      return (data != null ? _illpt7x2.BoardTaskPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idsjzf6h.BoardTaskRef?>()) {
      return (data != null ? _idsjzf6h.BoardTaskRef.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i4a2ekwp.BoardTaskStatus?>()) {
      return (data != null ? _i4a2ekwp.BoardTaskStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ifz7dmuf.BoardTaskView?>()) {
      return (data != null ? _ifz7dmuf.BoardTaskView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iso7mdvm.BoardTriageState?>()) {
      return (data != null ? _iso7mdvm.BoardTriageState.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i516sz1w.BoardUserProfile?>()) {
      return (data != null ? _i516sz1w.BoardUserProfile.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ifuo09i6.BoardVote?>()) {
      return (data != null ? _ifuo09i6.BoardVote.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie24iiog.BoardVoteResult?>()) {
      return (data != null ? _ie24iiog.BoardVoteResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iyixppck.Comment?>()) {
      return (data != null ? _iyixppck.Comment.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iw81twtc.CommentAnchorKind?>()) {
      return (data != null ? _iw81twtc.CommentAnchorKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_imlsyj2p.CommentEvent?>()) {
      return (data != null ? _imlsyj2p.CommentEvent.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ih1mb6x5.CommentEventKind?>()) {
      return (data != null ? _ih1mb6x5.CommentEventKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_il5y6tzr.CommentFilter?>()) {
      return (data != null ? _il5y6tzr.CommentFilter.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iowdswxe.CommentStatus?>()) {
      return (data != null ? _iowdswxe.CommentStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i94wr3td.CommentSystemEvent?>()) {
      return (data != null ? _i94wr3td.CommentSystemEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ijog60vm.CommentThread?>()) {
      return (data != null ? _ijog60vm.CommentThread.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i818olql.CommentThreadView?>()) {
      return (data != null ? _i818olql.CommentThreadView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4xrxro7.CommentView?>()) {
      return (data != null ? _i4xrxro7.CommentView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ii98prcs.AccessRole?>()) {
      return (data != null ? _ii98prcs.AccessRole.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i2wc4tyi.ActorKind?>()) {
      return (data != null ? _i2wc4tyi.ActorKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_inb0isem.WonkyErrorCode?>()) {
      return (data != null ? _inb0isem.WonkyErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igdswlrw.WonkyException?>()) {
      return (data != null ? _igdswlrw.WonkyException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iktwt5zz.DriveChange?>()) {
      return (data != null ? _iktwt5zz.DriveChange.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ijoqbs82.DriveChangeKind?>()) {
      return (data != null ? _ijoqbs82.DriveChangeKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ig2nixhn.DriveImportOptions?>()) {
      return (data != null ? _ig2nixhn.DriveImportOptions.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_inge8yy2.DriveItem?>()) {
      return (data != null ? _inge8yy2.DriveItem.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8mh39wa.DriveItemKind?>()) {
      return (data != null ? _i8mh39wa.DriveItemKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0g2m831.DriveItemUserState?>()) {
      return (data != null ? _i0g2m831.DriveItemUserState.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_infxyf98.DriveItemView?>()) {
      return (data != null ? _infxyf98.DriveItemView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivypvw0m.DriveListFilter?>()) {
      return (data != null ? _ivypvw0m.DriveListFilter.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iavdhzsq.DriveListPage?>()) {
      return (data != null ? _iavdhzsq.DriveListPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_if1dhg5z.DriveOwnerFilter?>()) {
      return (data != null ? _if1dhg5z.DriveOwnerFilter.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6k3d1nc.DriveSearchFilters?>()) {
      return (data != null ? _i6k3d1nc.DriveSearchFilters.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iu13r4v2.DriveSort?>()) {
      return (data != null ? _iu13r4v2.DriveSort.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ix0g8yw4.DriveSortField?>()) {
      return (data != null ? _ix0g8yw4.DriveSortField.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ipww3kqy.DriveView?>()) {
      return (data != null ? _ipww3kqy.DriveView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iez45i4u.FileCategory?>()) {
      return (data != null ? _iez45i4u.FileCategory.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilt75p4e.FileUploadProgress?>()) {
      return (data != null ? _ilt75p4e.FileUploadProgress.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iqpb2qv1.FileUploadRequest?>()) {
      return (data != null ? _iqpb2qv1.FileUploadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_imf3tnfq.FileUploadStart?>()) {
      return (data != null ? _imf3tnfq.FileUploadStart.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ia04wt6m.FileUploadState?>()) {
      return (data != null ? _ia04wt6m.FileUploadState.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i68yhxa0.ImportReportView?>()) {
      return (data != null ? _i68yhxa0.ImportReportView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i48sm9f2.ImportWarningView?>()) {
      return (data != null ? _i48sm9f2.ImportWarningView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8hnug6t.StorageListFilter?>()) {
      return (data != null ? _i8hnug6t.StorageListFilter.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i26hsnhw.StorageUsage?>()) {
      return (data != null ? _i26hsnhw.StorageUsage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iiedu4vz.TemplateCategory?>()) {
      return (data != null ? _iiedu4vz.TemplateCategory.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6rg3vdh.TemplatePreviewStyle?>()) {
      return (data != null
              ? _i6rg3vdh.TemplatePreviewStyle.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i2ox7ta1.TemplateView?>()) {
      return (data != null ? _i2ox7ta1.TemplateView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_io3ccr8w.UploadConflictMode?>()) {
      return (data != null ? _io3ccr8w.UploadConflictMode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv1sk0e8.FeedbackKind?>()) {
      return (data != null ? _iv1sk0e8.FeedbackKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilhpki98.FeedbackSubmission?>()) {
      return (data != null ? _ilhpki98.FeedbackSubmission.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_irrzp8p9.FileUploadTicket?>()) {
      return (data != null ? _irrzp8p9.FileUploadTicket.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_itzt3x6d.FileUrlView?>()) {
      return (data != null ? _itzt3x6d.FileUrlView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_im8eh74x.StoredFile?>()) {
      return (data != null ? _im8eh74x.StoredFile.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i45dmz4a.StoredFileKind?>()) {
      return (data != null ? _i45dmz4a.StoredFileKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ik7q11oy.StoredFileStatus?>()) {
      return (data != null ? _ik7q11oy.StoredFileStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ichw8k0i.UiBridgeCancel?>()) {
      return (data != null ? _ichw8k0i.UiBridgeCancel.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ichw8k0i.UiBridgeHello?>()) {
      return (data != null ? _ichw8k0i.UiBridgeHello.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ichw8k0i.UiBridgeRequest?>()) {
      return (data != null ? _ichw8k0i.UiBridgeRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ichw8k0i.UiBridgeResponse?>()) {
      return (data != null ? _ichw8k0i.UiBridgeResponse.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ichw8k0i.UiBridgeStatus?>()) {
      return (data != null ? _ichw8k0i.UiBridgeStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ichw8k0i.UiBridgeStop?>()) {
      return (data != null ? _ichw8k0i.UiBridgeStop.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ichw8k0i.UiBridgeWelcome?>()) {
      return (data != null ? _ichw8k0i.UiBridgeWelcome.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivk6eyvx.FeatureFlags?>()) {
      return (data != null ? _ivk6eyvx.FeatureFlags.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ib575x0y.ProtocolInfo?>()) {
      return (data != null ? _ib575x0y.ProtocolInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i28el0at.ServerLimits?>()) {
      return (data != null ? _i28el0at.ServerLimits.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iexg4yzt.NotificationEvent?>()) {
      return (data != null ? _iexg4yzt.NotificationEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iqlnbbfp.NotificationKind?>()) {
      return (data != null ? _iqlnbbfp.NotificationKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3r1eo8q.NotificationPage?>()) {
      return (data != null ? _i3r1eo8q.NotificationPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izfzk9h3.NotificationView?>()) {
      return (data != null ? _izfzk9h3.NotificationView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ik59hiyp.UserNotification?>()) {
      return (data != null ? _ik59hiyp.UserNotification.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iylgyc33.Participant?>()) {
      return (data != null ? _iylgyc33.Participant.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8r9afjv.PresenceFollowerCount?>()) {
      return (data != null
              ? _i8r9afjv.PresenceFollowerCount.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i8r9afjv.PresenceHints?>()) {
      return (data != null ? _i8r9afjv.PresenceHints.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8r9afjv.PresenceJoined?>()) {
      return (data != null ? _i8r9afjv.PresenceJoined.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8r9afjv.PresenceLeft?>()) {
      return (data != null ? _i8r9afjv.PresenceLeft.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8r9afjv.PresenceNotice?>()) {
      return (data != null ? _i8r9afjv.PresenceNotice.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8r9afjv.PresenceRoster?>()) {
      return (data != null ? _i8r9afjv.PresenceRoster.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8r9afjv.PresenceUpdated?>()) {
      return (data != null ? _i8r9afjv.PresenceUpdated.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ik055xb9.PresenceState?>()) {
      return (data != null ? _ik055xb9.PresenceState.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isz2sju0.PresenceUpdate?>()) {
      return (data != null ? _isz2sju0.PresenceUpdate.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ie6clghy.RevAck?>()) {
      return (data != null ? _ie6clghy.RevAck.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i6ck957q.RevPing?>()) {
      return (data != null ? _i6ck957q.RevPing.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i6ck957q.RevRequestOps?>()) {
      return (data != null ? _i6ck957q.RevRequestOps.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6ck957q.RevSubmit?>()) {
      return (data != null ? _i6ck957q.RevSubmit.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie6clghy.RevInit?>()) {
      return (data != null ? _ie6clghy.RevInit.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie6clghy.RevPong?>()) {
      return (data != null ? _ie6clghy.RevPong.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie6clghy.RevRejected?>()) {
      return (data != null ? _ie6clghy.RevRejected.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie6clghy.RevRemoteOp?>()) {
      return (data != null ? _ie6clghy.RevRemoteOp.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie6clghy.RevResync?>()) {
      return (data != null ? _ie6clghy.RevResync.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie6clghy.RevRoleChanged?>()) {
      return (data != null ? _ie6clghy.RevRoleChanged.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ihwy023l.RevFileInfo?>()) {
      return (data != null ? _ihwy023l.RevFileInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iwkehf4e.RevFileKind?>()) {
      return (data != null ? _iwkehf4e.RevFileKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_it4o2pk5.RevOpView?>()) {
      return (data != null ? _it4o2pk5.RevOpView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ium7xjeg.RevPage?>()) {
      return (data != null ? _ium7xjeg.RevPage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i3q3ua5p.RevPageKind?>()) {
      return (data != null ? _i3q3ua5p.RevPageKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_if03ikx4.RevPageRequest?>()) {
      return (data != null ? _if03ikx4.RevPageRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iilsyt4b.RevRejectCode?>()) {
      return (data != null ? _iilsyt4b.RevRejectCode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8scn8dm.AccessRequest?>()) {
      return (data != null ? _i8scn8dm.AccessRequest.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i7trut12.AccessRequestOutcome?>()) {
      return (data != null
              ? _i7trut12.AccessRequestOutcome.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iimp60a4.AccessRequestView?>()) {
      return (data != null ? _iimp60a4.AccessRequestView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iuzgacy4.DriveItemPermission?>()) {
      return (data != null
              ? _iuzgacy4.DriveItemPermission.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ikeljole.InviteResolution?>()) {
      return (data != null ? _ikeljole.InviteResolution.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ih3711er.ItemSharingSettings?>()) {
      return (data != null
              ? _ih3711er.ItemSharingSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijwxtu30.OwnershipTransfer?>()) {
      return (data != null ? _ijwxtu30.OwnershipTransfer.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iilpsf9g.OwnershipTransferView?>()) {
      return (data != null
              ? _iilpsf9g.OwnershipTransferView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iead0ok9.PermissionView?>()) {
      return (data != null ? _iead0ok9.PermissionView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_it712lg1.ShareLink?>()) {
      return (data != null ? _it712lg1.ShareLink.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iw2xoohn.ShareLinkView?>()) {
      return (data != null ? _iw2xoohn.ShareLinkView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_itd24os1.SharingInfo?>()) {
      return (data != null ? _itd24os1.SharingInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ifxa4vxf.QuotaExceededDetails?>()) {
      return (data != null
              ? _ifxa4vxf.QuotaExceededDetails.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_izha9j5m.AccessTokenView?>()) {
      return (data != null ? _izha9j5m.AccessTokenView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iq4dupwy.AccountDeletionPreview?>()) {
      return (data != null
              ? _iq4dupwy.AccountDeletionPreview.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i6azdr3n.AppThemeMode?>()) {
      return (data != null ? _i6azdr3n.AppThemeMode.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iru4pv75.CreatedAccessToken?>()) {
      return (data != null ? _iru4pv75.CreatedAccessToken.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5lc4gt0.UiDensity?>()) {
      return (data != null ? _i5lc4gt0.UiDensity.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i501u5m5.UserPreferences?>()) {
      return (data != null ? _i501u5m5.UserPreferences.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_id95rrz2.UserPreferencesPatch?>()) {
      return (data != null
              ? _id95rrz2.UserPreferencesPatch.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ihzl7wbq.UserProfile?>()) {
      return (data != null ? _ihzl7wbq.UserProfile.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iufqmqtc.UserProfileView?>()) {
      return (data != null ? _iufqmqtc.UserProfileView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6y7tspy.UserSummary?>()) {
      return (data != null ? _i6y7tspy.UserSummary.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i7jb115m.ItemVersion?>()) {
      return (data != null ? _i7jb115m.ItemVersion.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ipbapjbz.ItemVersionView?>()) {
      return (data != null ? _ipbapjbz.ItemVersionView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_in0fdl1f.VersionKind?>()) {
      return (data != null ? _in0fdl1f.VersionKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_in38zbga.VersionRestoreResult?>()) {
      return (data != null
              ? _in38zbga.VersionRestoreResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i5u6d6t4.VersionStorage?>()) {
      return (data != null ? _i5u6d6t4.VersionStorage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iuzj1jin.SheetsAiApplyResult?>()) {
      return (data != null
              ? _iuzj1jin.SheetsAiApplyResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iljqbz3a.SheetsAiCellRequest?>()) {
      return (data != null
              ? _iljqbz3a.SheetsAiCellRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_im85lt6z.SheetsAiCellResult?>()) {
      return (data != null ? _im85lt6z.SheetsAiCellResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4t3jyqe.SheetsAiPreview?>()) {
      return (data != null ? _i4t3jyqe.SheetsAiPreview.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idzstekp.SheetsAiPreviewCall?>()) {
      return (data != null
              ? _idzstekp.SheetsAiPreviewCall.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i49726iv.SheetsAiPreviewCell?>()) {
      return (data != null
              ? _i49726iv.SheetsAiPreviewCell.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_izbpavhd.SheetsFillProposal?>()) {
      return (data != null ? _izbpavhd.SheetsFillProposal.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i1gi0ui2.SheetsFillRow?>()) {
      return (data != null ? _i1gi0ui2.SheetsFillRow.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i2bhah0l.SheetsFormulaSuggestion?>()) {
      return (data != null
              ? _i2bhah0l.SheetsFormulaSuggestion.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iaf43n69.SheetsImportProgress?>()) {
      return (data != null
              ? _iaf43n69.SheetsImportProgress.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i8d83qca.SheetsImportStatus?>()) {
      return (data != null ? _i8d83qca.SheetsImportStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ij1xvs09.CellHistoryEntry?>()) {
      return (data != null ? _ij1xvs09.CellHistoryEntry.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i09xo3k8.CellHistoryPage?>()) {
      return (data != null ? _i09xo3k8.CellHistoryPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ilv3hlxr.RevertResult?>()) {
      return (data != null ? _ilv3hlxr.RevertResult.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ipqum05l.RevertSkip?>()) {
      return (data != null ? _ipqum05l.RevertSkip.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilnsyzhq.Dimension?>()) {
      return (data != null ? _ilnsyzhq.Dimension.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihfpm0ve.EmbeddedObjectKind?>()) {
      return (data != null ? _ihfpm0ve.EmbeddedObjectKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iofwzekn.HorizontalAlign?>()) {
      return (data != null ? _iofwzekn.HorizontalAlign.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0z9m4nl.RecalcMode?>()) {
      return (data != null ? _i0z9m4nl.RecalcMode.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_io4oc09s.ScriptBuildStatus?>()) {
      return (data != null ? _io4oc09s.ScriptBuildStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8ne06ql.SheetKind?>()) {
      return (data != null ? _i8ne06ql.SheetKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_irmtoho8.TriggerKind?>()) {
      return (data != null ? _irmtoho8.TriggerKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ivf2txqv.VerticalAlign?>()) {
      return (data != null ? _ivf2txqv.VerticalAlign.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iz9rjt8b.WrapStrategy?>()) {
      return (data != null ? _iz9rjt8b.WrapStrategy.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iaehez21.SheetsActivitySummary?>()) {
      return (data != null
              ? _iaehez21.SheetsActivitySummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i9yjzgjk.SheetsContributorStat?>()) {
      return (data != null
              ? _i9yjzgjk.SheetsContributorStat.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_icjzxy6x.ScriptAuthorizationView?>()) {
      return (data != null
              ? _icjzxy6x.ScriptAuthorizationView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iq0xpzf7.ScriptCompileResponse?>()) {
      return (data != null
              ? _iq0xpzf7.ScriptCompileResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4bc0fek.ScriptExecution?>()) {
      return (data != null ? _i4bc0fek.ScriptExecution.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_inqz9v2t.ScriptExecutionKind?>()) {
      return (data != null
              ? _inqz9v2t.ScriptExecutionKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ira26pfa.ScriptExecutionStatus?>()) {
      return (data != null
              ? _ira26pfa.ScriptExecutionStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_is04pxv8.ScriptFetchResponse?>()) {
      return (data != null
              ? _is04pxv8.ScriptFetchResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_is0mvar3.ScriptRunResponse?>()) {
      return (data != null ? _is0mvar3.ScriptRunResponse.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iy0fj18f.ScriptRuntimeKind?>()) {
      return (data != null ? _iy0fj18f.ScriptRuntimeKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iwj0qehd.SlidesAiAltText?>()) {
      return (data != null ? _iwj0qehd.SlidesAiAltText.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ix6z7bmu.SlidesAiApplyResult?>()) {
      return (data != null
              ? _ix6z7bmu.SlidesAiApplyResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_isdksxfl.SlidesAiBuildResult?>()) {
      return (data != null
              ? _isdksxfl.SlidesAiBuildResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i154xjj9.SlidesAiDesignRank?>()) {
      return (data != null ? _i154xjj9.SlidesAiDesignRank.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_itoukaix.SlidesAiNote?>()) {
      return (data != null ? _itoukaix.SlidesAiNote.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i225jf90.SlidesAiOutlineRequest?>()) {
      return (data != null
              ? _i225jf90.SlidesAiOutlineRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ioipp9xy.SlidesAiPreview?>()) {
      return (data != null ? _ioipp9xy.SlidesAiPreview.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iuzye628.SlidesAiPreviewCall?>()) {
      return (data != null
              ? _iuzye628.SlidesAiPreviewCall.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ixaahmd2.SlidesAiRewriteRequest?>()) {
      return (data != null
              ? _ixaahmd2.SlidesAiRewriteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7q1o3oi.ChartLinkProbe?>()) {
      return (data != null ? _i7q1o3oi.ChartLinkProbe.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3ysrjbx.ChartLinkState?>()) {
      return (data != null ? _i3ysrjbx.ChartLinkState.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_is6z3tpy.ChartLinkStatus?>()) {
      return (data != null ? _is6z3tpy.ChartLinkStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iua8dx49.ChartSnapshotView?>()) {
      return (data != null ? _iua8dx49.ChartSnapshotView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iq1h9id2.ChartSourceList?>()) {
      return (data != null ? _iq1h9id2.ChartSourceList.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_inygrvyi.ChartSourceSummary?>()) {
      return (data != null ? _inygrvyi.ChartSourceSummary.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ipok3hcm.BuildKind?>()) {
      return (data != null ? _ipok3hcm.BuildKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_isb6wks2.BuildTrigger?>()) {
      return (data != null ? _isb6wks2.BuildTrigger.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_isf9v7y6.DeckAppearance?>()) {
      return (data != null ? _isf9v7y6.DeckAppearance.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4oq3vgh.PlaceholderType?>()) {
      return (data != null ? _i4oq3vgh.PlaceholderType.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isah8148.SlideElementKind?>()) {
      return (data != null ? _isah8148.SlideElementKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isghg0k1.SlideSizePreset?>()) {
      return (data != null ? _isghg0k1.SlideSizePreset.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5m4q7yg.TableDimension?>()) {
      return (data != null ? _i5m4q7yg.TableDimension.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationCommandEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationCommandEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijdad65m.PresentationCommandUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationCommandUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijdad65m.PresentationEndUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationEndUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationEndedEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationEndedEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationInkEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationInkEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationLaserEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationLaserEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationPairingEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationPairingEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationPresenterEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationPresenterEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationRosterEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationRosterEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationStateEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationStateEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz9vxb2f.PresentationWelcome?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationWelcome.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijdad65m.PresentationInkUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationInkUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ih25cwup.PresentationJoin?>()) {
      return (data != null ? _ih25cwup.PresentationJoin.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ijdad65m.PresentationLaserUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationLaserUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i6know5x.PresentationPairingTarget?>()) {
      return (data != null
              ? _i6know5x.PresentationPairingTarget.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijdad65m.PresentationPairingUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationPairingUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ijgt5qi7.PresentationParticipant?>()) {
      return (data != null
              ? _ijgt5qi7.PresentationParticipant.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4d7um9r.PresentationRole?>()) {
      return (data != null ? _i4d7um9r.PresentationRole.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ig7ln54r.PresentationSessionInfo?>()) {
      return (data != null
              ? _ig7ln54r.PresentationSessionInfo.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i95fngt4.PresentationState?>()) {
      return (data != null ? _i95fngt4.PresentationState.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ijdad65m.PresentationStateUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationStateUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocAck?>()) {
      return (data != null ? _icpkpcrn.DocAck.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_imbts8if.DocCursorUpdate?>()) {
      return (data != null ? _imbts8if.DocCursorUpdate.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_imbts8if.DocHashCheck?>()) {
      return (data != null ? _imbts8if.DocHashCheck.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_imbts8if.DocPing?>()) {
      return (data != null ? _imbts8if.DocPing.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_imbts8if.DocRequestOps?>()) {
      return (data != null ? _imbts8if.DocRequestOps.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_imbts8if.DocSubmitOp?>()) {
      return (data != null ? _imbts8if.DocSubmitOp.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocHashResult?>()) {
      return (data != null ? _icpkpcrn.DocHashResult.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocInit?>()) {
      return (data != null ? _icpkpcrn.DocInit.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocMetaChanged?>()) {
      return (data != null ? _icpkpcrn.DocMetaChanged.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocOpRejected?>()) {
      return (data != null ? _icpkpcrn.DocOpRejected.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocParticipantJoined?>()) {
      return (data != null
              ? _icpkpcrn.DocParticipantJoined.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocParticipantLeft?>()) {
      return (data != null ? _icpkpcrn.DocParticipantLeft.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocPong?>()) {
      return (data != null ? _icpkpcrn.DocPong.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocRemoteCursor?>()) {
      return (data != null ? _icpkpcrn.DocRemoteCursor.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocRemoteOp?>()) {
      return (data != null ? _icpkpcrn.DocRemoteOp.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icpkpcrn.DocRoleChanged?>()) {
      return (data != null ? _icpkpcrn.DocRoleChanged.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igqu3xcv.ConvertForInsertResult?>()) {
      return (data != null
              ? _igqu3xcv.ConvertForInsertResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i5srcd7q.DocRejectCode?>()) {
      return (data != null ? _i5srcd7q.DocRejectCode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4sx4pml.Document?>()) {
      return (data != null ? _i4sx4pml.Document.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iu022vpf.DocumentInfo?>()) {
      return (data != null ? _iu022vpf.DocumentInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ir38bcqq.DocumentMetaChange?>()) {
      return (data != null ? _ir38bcqq.DocumentMetaChange.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_inkjv0lb.DocumentMetaPatch?>()) {
      return (data != null ? _inkjv0lb.DocumentMetaPatch.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icsyekcn.DocumentMetaView?>()) {
      return (data != null ? _icsyekcn.DocumentMetaView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iufsprkx.DocumentOp?>()) {
      return (data != null ? _iufsprkx.DocumentOp.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_igr6xq1c.DocumentOpKind?>()) {
      return (data != null ? _igr6xq1c.DocumentOpKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_issmv319.DocumentOpView?>()) {
      return (data != null ? _issmv319.DocumentOpView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i2cnn8i8.DocumentSnapshot?>()) {
      return (data != null ? _i2cnn8i8.DocumentSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0cy62lm.DocumentSnapshotView?>()) {
      return (data != null
              ? _i0cy62lm.DocumentSnapshotView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_is1ql5wp.ExportProgressEvent?>()) {
      return (data != null
              ? _is1ql5wp.ExportProgressEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_isdjhzgs.ExportProgressKind?>()) {
      return (data != null ? _isdjhzgs.ExportProgressKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_if2sngze.ExportResultView?>()) {
      return (data != null ? _if2sngze.ExportResultView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ittnhawp.ThemeConflictException?>()) {
      return (data != null
              ? _ittnhawp.ThemeConflictException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ii88i7dv.WriteDiffAuthor?>()) {
      return (data != null ? _ii88i7dv.WriteDiffAuthor.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idky93gt.WriteDiffView?>()) {
      return (data != null ? _idky93gt.WriteDiffView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iynqrh33.WriteTheme?>()) {
      return (data != null ? _iynqrh33.WriteTheme.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i7pbwt05.WriteThemeRevision?>()) {
      return (data != null ? _i7pbwt05.WriteThemeRevision.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ick3mhj2.WriteThemeRevisionView?>()) {
      return (data != null
              ? _ick3mhj2.WriteThemeRevisionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ixbjd26z.WriteThemeView?>()) {
      return (data != null ? _ixbjd26z.WriteThemeView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_is9bkd9t.WriteVersionDocument?>()) {
      return (data != null
              ? _is9bkd9t.WriteVersionDocument.fromJson(data)
              : null)
          as T;
    }
    if (t == List<_ikcwdr17.ActivityViewer>) {
      return (data as List)
              .map((e) => deserialize<_ikcwdr17.ActivityViewer>(e))
              .toList()
          as T;
    }
    if (t == List<_ighcq381.ActivityTrendPoint>) {
      return (data as List)
              .map((e) => deserialize<_ighcq381.ActivityTrendPoint>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i4rkdm2k.AssistantMessageView>) {
      return (data as List)
              .map((e) => deserialize<_i4rkdm2k.AssistantMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_ivmxemza.ProofreadIssue>) {
      return (data as List)
              .map((e) => deserialize<_ivmxemza.ProofreadIssue>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_ivmxemza.ProofreadIssue>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ivmxemza.ProofreadIssue>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_iq3f61ec.BoardPostListItem>) {
      return (data as List)
              .map((e) => deserialize<_iq3f61ec.BoardPostListItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i5pjfe5s.BoardFlagView>) {
      return (data as List)
              .map((e) => deserialize<_i5pjfe5s.BoardFlagView>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_i5pjfe5s.BoardFlagView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i5pjfe5s.BoardFlagView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_il200dga.BoardPostStatus>) {
      return (data as List)
              .map((e) => deserialize<_il200dga.BoardPostStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_i0ag0upm.BoardArea>) {
      return (data as List)
              .map((e) => deserialize<_i0ag0upm.BoardArea>(e))
              .toList()
          as T;
    }
    if (t == List<_ivbgicm7.BoardSize>) {
      return (data as List)
              .map((e) => deserialize<_ivbgicm7.BoardSize>(e))
              .toList()
          as T;
    }
    if (t == Map<String, double>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<double>(v)),
          )
          as T;
    }
    if (t == _isc.getType<Map<String, double>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<double>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_ifz7dmuf.BoardTaskView>) {
      return (data as List)
              .map((e) => deserialize<_ifz7dmuf.BoardTaskView>(e))
              .toList()
          as T;
    }
    if (t == List<_i4xrxro7.CommentView>) {
      return (data as List)
              .map((e) => deserialize<_i4xrxro7.CommentView>(e))
              .toList()
          as T;
    }
    if (t == List<_i6y7tspy.UserSummary>) {
      return (data as List)
              .map((e) => deserialize<_i6y7tspy.UserSummary>(e))
              .toList()
          as T;
    }
    if (t == Map<String, List<int>>) {
      return (data as Map).map(
            (k, v) =>
                MapEntry(deserialize<String>(k), deserialize<List<int>>(v)),
          )
          as T;
    }
    if (t == List<_i8mh39wa.DriveItemKind>) {
      return (data as List)
              .map((e) => deserialize<_i8mh39wa.DriveItemKind>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_i8mh39wa.DriveItemKind>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i8mh39wa.DriveItemKind>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_iez45i4u.FileCategory>) {
      return (data as List)
              .map((e) => deserialize<_iez45i4u.FileCategory>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_iez45i4u.FileCategory>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_iez45i4u.FileCategory>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_infxyf98.DriveItemView>) {
      return (data as List)
              .map((e) => deserialize<_infxyf98.DriveItemView>(e))
              .toList()
          as T;
    }
    if (t == List<_i48sm9f2.ImportWarningView>) {
      return (data as List)
              .map((e) => deserialize<_i48sm9f2.ImportWarningView>(e))
              .toList()
          as T;
    }
    if (t == List<_izfzk9h3.NotificationView>) {
      return (data as List)
              .map((e) => deserialize<_izfzk9h3.NotificationView>(e))
              .toList()
          as T;
    }
    if (t == List<_iylgyc33.Participant>) {
      return (data as List)
              .map((e) => deserialize<_iylgyc33.Participant>(e))
              .toList()
          as T;
    }
    if (t == List<_it4o2pk5.RevOpView>) {
      return (data as List)
              .map((e) => deserialize<_it4o2pk5.RevOpView>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_it4o2pk5.RevOpView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_it4o2pk5.RevOpView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_isc.UuidValue>) {
      return (data as List).map((e) => deserialize<_isc.UuidValue>(e)).toList()
          as T;
    }
    if (t == _isc.getType<List<_isc.UuidValue>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_isc.UuidValue>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_iead0ok9.PermissionView>) {
      return (data as List)
              .map((e) => deserialize<_iead0ok9.PermissionView>(e))
              .toList()
          as T;
    }
    if (t == List<_iimp60a4.AccessRequestView>) {
      return (data as List)
              .map((e) => deserialize<_iimp60a4.AccessRequestView>(e))
              .toList()
          as T;
    }
    if (t == List<_idzstekp.SheetsAiPreviewCall>) {
      return (data as List)
              .map((e) => deserialize<_idzstekp.SheetsAiPreviewCall>(e))
              .toList()
          as T;
    }
    if (t == List<_i49726iv.SheetsAiPreviewCell>) {
      return (data as List)
              .map((e) => deserialize<_i49726iv.SheetsAiPreviewCell>(e))
              .toList()
          as T;
    }
    if (t == List<_i1gi0ui2.SheetsFillRow>) {
      return (data as List)
              .map((e) => deserialize<_i1gi0ui2.SheetsFillRow>(e))
              .toList()
          as T;
    }
    if (t == List<_ij1xvs09.CellHistoryEntry>) {
      return (data as List)
              .map((e) => deserialize<_ij1xvs09.CellHistoryEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_ipqum05l.RevertSkip>) {
      return (data as List)
              .map((e) => deserialize<_ipqum05l.RevertSkip>(e))
              .toList()
          as T;
    }
    if (t == Map<String, Map<int, int>>) {
      return (data as Map).map(
            (k, v) =>
                MapEntry(deserialize<String>(k), deserialize<Map<int, int>>(v)),
          )
          as T;
    }
    if (t == Map<int, int>) {
      return Map.fromEntries(
            (data as List).map(
              (e) =>
                  MapEntry(deserialize<int>(e['k']), deserialize<int>(e['v'])),
            ),
          )
          as T;
    }
    if (t == List<_i9yjzgjk.SheetsContributorStat>) {
      return (data as List)
              .map((e) => deserialize<_i9yjzgjk.SheetsContributorStat>(e))
              .toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_iuzye628.SlidesAiPreviewCall>) {
      return (data as List)
              .map((e) => deserialize<_iuzye628.SlidesAiPreviewCall>(e))
              .toList()
          as T;
    }
    if (t == List<_inygrvyi.ChartSourceSummary>) {
      return (data as List)
              .map((e) => deserialize<_inygrvyi.ChartSourceSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_ijgt5qi7.PresentationParticipant>) {
      return (data as List)
              .map((e) => deserialize<_ijgt5qi7.PresentationParticipant>(e))
              .toList()
          as T;
    }
    if (t == List<_issmv319.DocumentOpView>) {
      return (data as List)
              .map((e) => deserialize<_issmv319.DocumentOpView>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_issmv319.DocumentOpView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_issmv319.DocumentOpView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _isc.getType<List<_i48sm9f2.ImportWarningView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i48sm9f2.ImportWarningView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ii88i7dv.WriteDiffAuthor>) {
      return (data as List)
              .map((e) => deserialize<_ii88i7dv.WriteDiffAuthor>(e))
              .toList()
          as T;
    }
    if (t == List<_i2rhb3qx.AssistantThreadView>) {
      return (data as List)
              .map((e) => deserialize<_i2rhb3qx.AssistantThreadView>(e))
              .toList()
          as T;
    }
    if (t == List<_iesojpvb.BoardCommentView>) {
      return (data as List)
              .map((e) => deserialize<_iesojpvb.BoardCommentView>(e))
              .toList()
          as T;
    }
    if (t == List<_ikfdrh1p.BoardSimilarPost>) {
      return (data as List)
              .map((e) => deserialize<_ikfdrh1p.BoardSimilarPost>(e))
              .toList()
          as T;
    }
    if (t == List<_i325i6jq.BoardTaskStatus>) {
      return (data as List)
              .map((e) => deserialize<_i325i6jq.BoardTaskStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_i3y77bov.BoardReviewItem>) {
      return (data as List)
              .map((e) => deserialize<_i3y77bov.BoardReviewItem>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i94c7q23.BoardBundleSuggestionView>) {
      return (data as List)
              .map((e) => deserialize<_i94c7q23.BoardBundleSuggestionView>(e))
              .toList()
          as T;
    }
    if (t == List<_i2c85fb0.CommentThreadView>) {
      return (data as List)
              .map((e) => deserialize<_i2c85fb0.CommentThreadView>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_iatsgjjq.DriveItemView>) {
      return (data as List)
              .map((e) => deserialize<_iatsgjjq.DriveItemView>(e))
              .toList()
          as T;
    }
    if (t == List<_isc.UuidValue>) {
      return (data as List).map((e) => deserialize<_isc.UuidValue>(e)).toList()
          as T;
    }
    if (t == List<_i1pzk6fp.TemplateView>) {
      return (data as List)
              .map((e) => deserialize<_i1pzk6fp.TemplateView>(e))
              .toList()
          as T;
    }
    if (t == List<_itempttd.ActivityEventView>) {
      return (data as List)
              .map((e) => deserialize<_itempttd.ActivityEventView>(e))
              .toList()
          as T;
    }
    if (t == List<_i4i1hokq.FileUrlView>) {
      return (data as List)
              .map((e) => deserialize<_i4i1hokq.FileUrlView>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_ip6swqsj.AccessTokenView>) {
      return (data as List)
              .map((e) => deserialize<_ip6swqsj.AccessTokenView>(e))
              .toList()
          as T;
    }
    if (t == List<_iq7femvs.UserSummary>) {
      return (data as List)
              .map((e) => deserialize<_iq7femvs.UserSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_itqtmykd.ItemVersionView>) {
      return (data as List)
              .map((e) => deserialize<_itqtmykd.ItemVersionView>(e))
              .toList()
          as T;
    }
    if (t == List<_i2syfqhi.SheetsFillRow>) {
      return (data as List)
              .map((e) => deserialize<_i2syfqhi.SheetsFillRow>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_ivc6ykj9.SheetsAiCellResult>) {
      return (data as List)
              .map((e) => deserialize<_ivc6ykj9.SheetsAiCellResult>(e))
              .toList()
          as T;
    }
    if (t == List<_ibrzlkni.SheetsAiCellRequest>) {
      return (data as List)
              .map((e) => deserialize<_ibrzlkni.SheetsAiCellRequest>(e))
              .toList()
          as T;
    }
    if (t == List<_iq15rk0l.RevOpView>) {
      return (data as List)
              .map((e) => deserialize<_iq15rk0l.RevOpView>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == Map<String, String?>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String?>(v)),
          )
          as T;
    }
    if (t == List<_ijdpewvc.ScriptExecution>) {
      return (data as List)
              .map((e) => deserialize<_ijdpewvc.ScriptExecution>(e))
              .toList()
          as T;
    }
    if (t == List<_iascr37x.SlidesAiNote>) {
      return (data as List)
              .map((e) => deserialize<_iascr37x.SlidesAiNote>(e))
              .toList()
          as T;
    }
    if (t == List<_iqd8jbjp.SlidesAiAltText>) {
      return (data as List)
              .map((e) => deserialize<_iqd8jbjp.SlidesAiAltText>(e))
              .toList()
          as T;
    }
    if (t == List<_ifavqmyp.SlidesAiDesignRank>) {
      return (data as List)
              .map((e) => deserialize<_ifavqmyp.SlidesAiDesignRank>(e))
              .toList()
          as T;
    }
    if (t == List<_idvbn12y.ChartLinkStatus>) {
      return (data as List)
              .map((e) => deserialize<_idvbn12y.ChartLinkStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_ipgr9tcd.ChartLinkProbe>) {
      return (data as List)
              .map((e) => deserialize<_ipgr9tcd.ChartLinkProbe>(e))
              .toList()
          as T;
    }
    if (t == List<_i8x9070n.DocumentOpView>) {
      return (data as List)
              .map((e) => deserialize<_i8x9070n.DocumentOpView>(e))
              .toList()
          as T;
    }
    if (t == List<_i2zuh8f2.WriteThemeView>) {
      return (data as List)
              .map((e) => deserialize<_i2zuh8f2.WriteThemeView>(e))
              .toList()
          as T;
    }
    if (t == List<_igytjuh5.WriteThemeRevisionView>) {
      return (data as List)
              .map((e) => deserialize<_igytjuh5.WriteThemeRevisionView>(e))
              .toList()
          as T;
    }
    final modules = dataClassName == null
        ? deserializationMetadata.modulesForType(t)
        : deserializationMetadata.modules;
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _isc.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _izr1y672.ActivityDashboard => 'ActivityDashboard',
      _iatdjl5p.ActivityEvent => 'ActivityEvent',
      _isa7sjzq.ActivityEventView => 'ActivityEventView',
      _ighcq381.ActivityTrendPoint => 'ActivityTrendPoint',
      _i50cy468.ActivityType => 'ActivityType',
      _ikcwdr17.ActivityViewer => 'ActivityViewer',
      _iyja8k5e.AiApplyMode => 'AiApplyMode',
      _ir7z75mb.AiProvider => 'AiProvider',
      _ic2q2fwi.AiProviderKeyView => 'AiProviderKeyView',
      _iviyoyk9.AiQuality => 'AiQuality',
      _i7i53on7.AiUsage => 'AiUsage',
      _imx2nn1q.AiUserSetting => 'AiUserSetting',
      _ic7e83wd.AssistantContextHints => 'AssistantContextHints',
      _imp4tsxo.AssistantEvent => 'AssistantEvent',
      _id6kvqt9.AssistantEventType => 'AssistantEventType',
      _i8cittxq.AssistantMessage => 'AssistantMessage',
      _i4rkdm2k.AssistantMessageView => 'AssistantMessageView',
      _ia2m3j3v.AssistantStatus => 'AssistantStatus',
      _iaq6rutx.AssistantThread => 'AssistantThread',
      _i4iv0swm.AssistantThreadDetail => 'AssistantThreadDetail',
      _iohdfqf1.AssistantThreadView => 'AssistantThreadView',
      _i8ghcs7p.InlineAiEvent => 'InlineAiEvent',
      _i6pcz5z6.InlineAiEventType => 'InlineAiEventType',
      _i4m43iwr.InlineAiRequest => 'InlineAiRequest',
      _ie0jt2ne.ProofreadEvent => 'ProofreadEvent',
      _ivmxemza.ProofreadIssue => 'ProofreadIssue',
      _i0ag0upm.BoardArea => 'BoardArea',
      _ika8r7fc.BoardAuthor => 'BoardAuthor',
      _ilo15wk2.BoardBundleSuggestion => 'BoardBundleSuggestion',
      _iin47lv0.BoardBundleSuggestionView => 'BoardBundleSuggestionView',
      _ijz5flk6.BoardComment => 'BoardComment',
      _ipkjmsg5.BoardCommentView => 'BoardCommentView',
      _iswbp1jv.BoardCounts => 'BoardCounts',
      _ita8snxr.BoardEventKind => 'BoardEventKind',
      _i0y7d0xd.BoardFlag => 'BoardFlag',
      _iwc3b6vo.BoardFlagReason => 'BoardFlagReason',
      _i5pjfe5s.BoardFlagView => 'BoardFlagView',
      _igcoqerx.BoardListQuery => 'BoardListQuery',
      _iu9hvv8z.BoardMe => 'BoardMe',
      _in0hwjmy.BoardModeration => 'BoardModeration',
      _i5jfu168.BoardModerationAction => 'BoardModerationAction',
      _i7xps6dm.BoardPost => 'BoardPost',
      _izvgi5ni.BoardPostDraft => 'BoardPostDraft',
      _ibl25moa.BoardPostEvent => 'BoardPostEvent',
      _iui4x9zg.BoardPostKind => 'BoardPostKind',
      _iq3f61ec.BoardPostListItem => 'BoardPostListItem',
      _i1stsytz.BoardPostPage => 'BoardPostPage',
      _il200dga.BoardPostStatus => 'BoardPostStatus',
      _ijjd81zg.BoardPostView => 'BoardPostView',
      _im7v2irk.BoardReviewCounts => 'BoardReviewCounts',
      _id33cro1.BoardReviewItem => 'BoardReviewItem',
      _izs2n8vy.BoardReviewSection => 'BoardReviewSection',
      _ieemxbgb.BoardSignal => 'BoardSignal',
      _in3cjdcj.BoardSimilarPost => 'BoardSimilarPost',
      _ivbgicm7.BoardSize => 'BoardSize',
      _itz4727j.BoardSort => 'BoardSort',
      _i2gir90g.BoardTargetKind => 'BoardTargetKind',
      _iv26y3a1.BoardTask => 'BoardTask',
      _illpt7x2.BoardTaskPage => 'BoardTaskPage',
      _idsjzf6h.BoardTaskRef => 'BoardTaskRef',
      _i4a2ekwp.BoardTaskStatus => 'BoardTaskStatus',
      _ifz7dmuf.BoardTaskView => 'BoardTaskView',
      _iso7mdvm.BoardTriageState => 'BoardTriageState',
      _i516sz1w.BoardUserProfile => 'BoardUserProfile',
      _ifuo09i6.BoardVote => 'BoardVote',
      _ie24iiog.BoardVoteResult => 'BoardVoteResult',
      _iyixppck.Comment => 'Comment',
      _iw81twtc.CommentAnchorKind => 'CommentAnchorKind',
      _imlsyj2p.CommentEvent => 'CommentEvent',
      _ih1mb6x5.CommentEventKind => 'CommentEventKind',
      _il5y6tzr.CommentFilter => 'CommentFilter',
      _iowdswxe.CommentStatus => 'CommentStatus',
      _i94wr3td.CommentSystemEvent => 'CommentSystemEvent',
      _ijog60vm.CommentThread => 'CommentThread',
      _i818olql.CommentThreadView => 'CommentThreadView',
      _i4xrxro7.CommentView => 'CommentView',
      _ii98prcs.AccessRole => 'AccessRole',
      _i2wc4tyi.ActorKind => 'ActorKind',
      _inb0isem.WonkyErrorCode => 'WonkyErrorCode',
      _igdswlrw.WonkyException => 'WonkyException',
      _iktwt5zz.DriveChange => 'DriveChange',
      _ijoqbs82.DriveChangeKind => 'DriveChangeKind',
      _ig2nixhn.DriveImportOptions => 'DriveImportOptions',
      _inge8yy2.DriveItem => 'DriveItem',
      _i8mh39wa.DriveItemKind => 'DriveItemKind',
      _i0g2m831.DriveItemUserState => 'DriveItemUserState',
      _infxyf98.DriveItemView => 'DriveItemView',
      _ivypvw0m.DriveListFilter => 'DriveListFilter',
      _iavdhzsq.DriveListPage => 'DriveListPage',
      _if1dhg5z.DriveOwnerFilter => 'DriveOwnerFilter',
      _i6k3d1nc.DriveSearchFilters => 'DriveSearchFilters',
      _iu13r4v2.DriveSort => 'DriveSort',
      _ix0g8yw4.DriveSortField => 'DriveSortField',
      _ipww3kqy.DriveView => 'DriveView',
      _iez45i4u.FileCategory => 'FileCategory',
      _ilt75p4e.FileUploadProgress => 'FileUploadProgress',
      _iqpb2qv1.FileUploadRequest => 'FileUploadRequest',
      _imf3tnfq.FileUploadStart => 'FileUploadStart',
      _ia04wt6m.FileUploadState => 'FileUploadState',
      _i68yhxa0.ImportReportView => 'ImportReportView',
      _i48sm9f2.ImportWarningView => 'ImportWarningView',
      _i8hnug6t.StorageListFilter => 'StorageListFilter',
      _i26hsnhw.StorageUsage => 'StorageUsage',
      _iiedu4vz.TemplateCategory => 'TemplateCategory',
      _i6rg3vdh.TemplatePreviewStyle => 'TemplatePreviewStyle',
      _i2ox7ta1.TemplateView => 'TemplateView',
      _io3ccr8w.UploadConflictMode => 'UploadConflictMode',
      _iv1sk0e8.FeedbackKind => 'FeedbackKind',
      _ilhpki98.FeedbackSubmission => 'FeedbackSubmission',
      _irrzp8p9.FileUploadTicket => 'FileUploadTicket',
      _itzt3x6d.FileUrlView => 'FileUrlView',
      _im8eh74x.StoredFile => 'StoredFile',
      _i45dmz4a.StoredFileKind => 'StoredFileKind',
      _ik7q11oy.StoredFileStatus => 'StoredFileStatus',
      _ichw8k0i.UiBridgeCancel => 'UiBridgeCancel',
      _ichw8k0i.UiBridgeHello => 'UiBridgeHello',
      _ichw8k0i.UiBridgeRequest => 'UiBridgeRequest',
      _ichw8k0i.UiBridgeResponse => 'UiBridgeResponse',
      _ichw8k0i.UiBridgeStatus => 'UiBridgeStatus',
      _ichw8k0i.UiBridgeStop => 'UiBridgeStop',
      _ichw8k0i.UiBridgeWelcome => 'UiBridgeWelcome',
      _ivk6eyvx.FeatureFlags => 'FeatureFlags',
      _ib575x0y.ProtocolInfo => 'ProtocolInfo',
      _i28el0at.ServerLimits => 'ServerLimits',
      _iexg4yzt.NotificationEvent => 'NotificationEvent',
      _iqlnbbfp.NotificationKind => 'NotificationKind',
      _i3r1eo8q.NotificationPage => 'NotificationPage',
      _izfzk9h3.NotificationView => 'NotificationView',
      _ik59hiyp.UserNotification => 'UserNotification',
      _iylgyc33.Participant => 'Participant',
      _i8r9afjv.PresenceFollowerCount => 'PresenceFollowerCount',
      _i8r9afjv.PresenceHints => 'PresenceHints',
      _i8r9afjv.PresenceJoined => 'PresenceJoined',
      _i8r9afjv.PresenceLeft => 'PresenceLeft',
      _i8r9afjv.PresenceNotice => 'PresenceNotice',
      _i8r9afjv.PresenceRoster => 'PresenceRoster',
      _i8r9afjv.PresenceUpdated => 'PresenceUpdated',
      _ik055xb9.PresenceState => 'PresenceState',
      _isz2sju0.PresenceUpdate => 'PresenceUpdate',
      _ie6clghy.RevAck => 'RevAck',
      _i6ck957q.RevPing => 'RevPing',
      _i6ck957q.RevRequestOps => 'RevRequestOps',
      _i6ck957q.RevSubmit => 'RevSubmit',
      _ie6clghy.RevInit => 'RevInit',
      _ie6clghy.RevPong => 'RevPong',
      _ie6clghy.RevRejected => 'RevRejected',
      _ie6clghy.RevRemoteOp => 'RevRemoteOp',
      _ie6clghy.RevResync => 'RevResync',
      _ie6clghy.RevRoleChanged => 'RevRoleChanged',
      _ihwy023l.RevFileInfo => 'RevFileInfo',
      _iwkehf4e.RevFileKind => 'RevFileKind',
      _it4o2pk5.RevOpView => 'RevOpView',
      _ium7xjeg.RevPage => 'RevPage',
      _i3q3ua5p.RevPageKind => 'RevPageKind',
      _if03ikx4.RevPageRequest => 'RevPageRequest',
      _iilsyt4b.RevRejectCode => 'RevRejectCode',
      _i8scn8dm.AccessRequest => 'AccessRequest',
      _i7trut12.AccessRequestOutcome => 'AccessRequestOutcome',
      _iimp60a4.AccessRequestView => 'AccessRequestView',
      _iuzgacy4.DriveItemPermission => 'DriveItemPermission',
      _ikeljole.InviteResolution => 'InviteResolution',
      _ih3711er.ItemSharingSettings => 'ItemSharingSettings',
      _ijwxtu30.OwnershipTransfer => 'OwnershipTransfer',
      _iilpsf9g.OwnershipTransferView => 'OwnershipTransferView',
      _iead0ok9.PermissionView => 'PermissionView',
      _it712lg1.ShareLink => 'ShareLink',
      _iw2xoohn.ShareLinkView => 'ShareLinkView',
      _itd24os1.SharingInfo => 'SharingInfo',
      _ifxa4vxf.QuotaExceededDetails => 'QuotaExceededDetails',
      _izha9j5m.AccessTokenView => 'AccessTokenView',
      _iq4dupwy.AccountDeletionPreview => 'AccountDeletionPreview',
      _i6azdr3n.AppThemeMode => 'AppThemeMode',
      _iru4pv75.CreatedAccessToken => 'CreatedAccessToken',
      _i5lc4gt0.UiDensity => 'UiDensity',
      _i501u5m5.UserPreferences => 'UserPreferences',
      _id95rrz2.UserPreferencesPatch => 'UserPreferencesPatch',
      _ihzl7wbq.UserProfile => 'UserProfile',
      _iufqmqtc.UserProfileView => 'UserProfileView',
      _i6y7tspy.UserSummary => 'UserSummary',
      _i7jb115m.ItemVersion => 'ItemVersion',
      _ipbapjbz.ItemVersionView => 'ItemVersionView',
      _in0fdl1f.VersionKind => 'VersionKind',
      _in38zbga.VersionRestoreResult => 'VersionRestoreResult',
      _i5u6d6t4.VersionStorage => 'VersionStorage',
      _iuzj1jin.SheetsAiApplyResult => 'SheetsAiApplyResult',
      _iljqbz3a.SheetsAiCellRequest => 'SheetsAiCellRequest',
      _im85lt6z.SheetsAiCellResult => 'SheetsAiCellResult',
      _i4t3jyqe.SheetsAiPreview => 'SheetsAiPreview',
      _idzstekp.SheetsAiPreviewCall => 'SheetsAiPreviewCall',
      _i49726iv.SheetsAiPreviewCell => 'SheetsAiPreviewCell',
      _izbpavhd.SheetsFillProposal => 'SheetsFillProposal',
      _i1gi0ui2.SheetsFillRow => 'SheetsFillRow',
      _i2bhah0l.SheetsFormulaSuggestion => 'SheetsFormulaSuggestion',
      _iaf43n69.SheetsImportProgress => 'SheetsImportProgress',
      _i8d83qca.SheetsImportStatus => 'SheetsImportStatus',
      _ij1xvs09.CellHistoryEntry => 'CellHistoryEntry',
      _i09xo3k8.CellHistoryPage => 'CellHistoryPage',
      _ilv3hlxr.RevertResult => 'RevertResult',
      _ipqum05l.RevertSkip => 'RevertSkip',
      _ilnsyzhq.Dimension => 'Dimension',
      _ihfpm0ve.EmbeddedObjectKind => 'EmbeddedObjectKind',
      _iofwzekn.HorizontalAlign => 'HorizontalAlign',
      _i0z9m4nl.RecalcMode => 'RecalcMode',
      _io4oc09s.ScriptBuildStatus => 'ScriptBuildStatus',
      _i8ne06ql.SheetKind => 'SheetKind',
      _irmtoho8.TriggerKind => 'TriggerKind',
      _ivf2txqv.VerticalAlign => 'VerticalAlign',
      _iz9rjt8b.WrapStrategy => 'WrapStrategy',
      _iaehez21.SheetsActivitySummary => 'SheetsActivitySummary',
      _i9yjzgjk.SheetsContributorStat => 'SheetsContributorStat',
      _icjzxy6x.ScriptAuthorizationView => 'ScriptAuthorizationView',
      _iq0xpzf7.ScriptCompileResponse => 'ScriptCompileResponse',
      _i4bc0fek.ScriptExecution => 'ScriptExecution',
      _inqz9v2t.ScriptExecutionKind => 'ScriptExecutionKind',
      _ira26pfa.ScriptExecutionStatus => 'ScriptExecutionStatus',
      _is04pxv8.ScriptFetchResponse => 'ScriptFetchResponse',
      _is0mvar3.ScriptRunResponse => 'ScriptRunResponse',
      _iy0fj18f.ScriptRuntimeKind => 'ScriptRuntimeKind',
      _iwj0qehd.SlidesAiAltText => 'SlidesAiAltText',
      _ix6z7bmu.SlidesAiApplyResult => 'SlidesAiApplyResult',
      _isdksxfl.SlidesAiBuildResult => 'SlidesAiBuildResult',
      _i154xjj9.SlidesAiDesignRank => 'SlidesAiDesignRank',
      _itoukaix.SlidesAiNote => 'SlidesAiNote',
      _i225jf90.SlidesAiOutlineRequest => 'SlidesAiOutlineRequest',
      _ioipp9xy.SlidesAiPreview => 'SlidesAiPreview',
      _iuzye628.SlidesAiPreviewCall => 'SlidesAiPreviewCall',
      _ixaahmd2.SlidesAiRewriteRequest => 'SlidesAiRewriteRequest',
      _i7q1o3oi.ChartLinkProbe => 'ChartLinkProbe',
      _i3ysrjbx.ChartLinkState => 'ChartLinkState',
      _is6z3tpy.ChartLinkStatus => 'ChartLinkStatus',
      _iua8dx49.ChartSnapshotView => 'ChartSnapshotView',
      _iq1h9id2.ChartSourceList => 'ChartSourceList',
      _inygrvyi.ChartSourceSummary => 'ChartSourceSummary',
      _ipok3hcm.BuildKind => 'BuildKind',
      _isb6wks2.BuildTrigger => 'BuildTrigger',
      _isf9v7y6.DeckAppearance => 'DeckAppearance',
      _i4oq3vgh.PlaceholderType => 'PlaceholderType',
      _isah8148.SlideElementKind => 'SlideElementKind',
      _isghg0k1.SlideSizePreset => 'SlideSizePreset',
      _i5m4q7yg.TableDimension => 'TableDimension',
      _iz9vxb2f.PresentationCommandEvent => 'PresentationCommandEvent',
      _ijdad65m.PresentationCommandUpdate => 'PresentationCommandUpdate',
      _ijdad65m.PresentationEndUpdate => 'PresentationEndUpdate',
      _iz9vxb2f.PresentationEndedEvent => 'PresentationEndedEvent',
      _iz9vxb2f.PresentationInkEvent => 'PresentationInkEvent',
      _iz9vxb2f.PresentationLaserEvent => 'PresentationLaserEvent',
      _iz9vxb2f.PresentationPairingEvent => 'PresentationPairingEvent',
      _iz9vxb2f.PresentationPresenterEvent => 'PresentationPresenterEvent',
      _iz9vxb2f.PresentationRosterEvent => 'PresentationRosterEvent',
      _iz9vxb2f.PresentationStateEvent => 'PresentationStateEvent',
      _iz9vxb2f.PresentationWelcome => 'PresentationWelcome',
      _ijdad65m.PresentationInkUpdate => 'PresentationInkUpdate',
      _ih25cwup.PresentationJoin => 'PresentationJoin',
      _ijdad65m.PresentationLaserUpdate => 'PresentationLaserUpdate',
      _i6know5x.PresentationPairingTarget => 'PresentationPairingTarget',
      _ijdad65m.PresentationPairingUpdate => 'PresentationPairingUpdate',
      _ijgt5qi7.PresentationParticipant => 'PresentationParticipant',
      _i4d7um9r.PresentationRole => 'PresentationRole',
      _ig7ln54r.PresentationSessionInfo => 'PresentationSessionInfo',
      _i95fngt4.PresentationState => 'PresentationState',
      _ijdad65m.PresentationStateUpdate => 'PresentationStateUpdate',
      _icpkpcrn.DocAck => 'DocAck',
      _imbts8if.DocCursorUpdate => 'DocCursorUpdate',
      _imbts8if.DocHashCheck => 'DocHashCheck',
      _imbts8if.DocPing => 'DocPing',
      _imbts8if.DocRequestOps => 'DocRequestOps',
      _imbts8if.DocSubmitOp => 'DocSubmitOp',
      _icpkpcrn.DocHashResult => 'DocHashResult',
      _icpkpcrn.DocInit => 'DocInit',
      _icpkpcrn.DocMetaChanged => 'DocMetaChanged',
      _icpkpcrn.DocOpRejected => 'DocOpRejected',
      _icpkpcrn.DocParticipantJoined => 'DocParticipantJoined',
      _icpkpcrn.DocParticipantLeft => 'DocParticipantLeft',
      _icpkpcrn.DocPong => 'DocPong',
      _icpkpcrn.DocRemoteCursor => 'DocRemoteCursor',
      _icpkpcrn.DocRemoteOp => 'DocRemoteOp',
      _icpkpcrn.DocRoleChanged => 'DocRoleChanged',
      _igqu3xcv.ConvertForInsertResult => 'ConvertForInsertResult',
      _i5srcd7q.DocRejectCode => 'DocRejectCode',
      _i4sx4pml.Document => 'Document',
      _iu022vpf.DocumentInfo => 'DocumentInfo',
      _ir38bcqq.DocumentMetaChange => 'DocumentMetaChange',
      _inkjv0lb.DocumentMetaPatch => 'DocumentMetaPatch',
      _icsyekcn.DocumentMetaView => 'DocumentMetaView',
      _iufsprkx.DocumentOp => 'DocumentOp',
      _igr6xq1c.DocumentOpKind => 'DocumentOpKind',
      _issmv319.DocumentOpView => 'DocumentOpView',
      _i2cnn8i8.DocumentSnapshot => 'DocumentSnapshot',
      _i0cy62lm.DocumentSnapshotView => 'DocumentSnapshotView',
      _is1ql5wp.ExportProgressEvent => 'ExportProgressEvent',
      _isdjhzgs.ExportProgressKind => 'ExportProgressKind',
      _if2sngze.ExportResultView => 'ExportResultView',
      _ittnhawp.ThemeConflictException => 'ThemeConflictException',
      _ii88i7dv.WriteDiffAuthor => 'WriteDiffAuthor',
      _idky93gt.WriteDiffView => 'WriteDiffView',
      _iynqrh33.WriteTheme => 'WriteTheme',
      _i7pbwt05.WriteThemeRevision => 'WriteThemeRevision',
      _ick3mhj2.WriteThemeRevisionView => 'WriteThemeRevisionView',
      _ixbjd26z.WriteThemeView => 'WriteThemeView',
      _is9bkd9t.WriteVersionDocument => 'WriteVersionDocument',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('wonky.', '');
    }

    switch (data) {
      case _izr1y672.ActivityDashboard():
        return 'ActivityDashboard';
      case _iatdjl5p.ActivityEvent():
        return 'ActivityEvent';
      case _isa7sjzq.ActivityEventView():
        return 'ActivityEventView';
      case _ighcq381.ActivityTrendPoint():
        return 'ActivityTrendPoint';
      case _i50cy468.ActivityType():
        return 'ActivityType';
      case _ikcwdr17.ActivityViewer():
        return 'ActivityViewer';
      case _iyja8k5e.AiApplyMode():
        return 'AiApplyMode';
      case _ir7z75mb.AiProvider():
        return 'AiProvider';
      case _ic2q2fwi.AiProviderKeyView():
        return 'AiProviderKeyView';
      case _iviyoyk9.AiQuality():
        return 'AiQuality';
      case _i7i53on7.AiUsage():
        return 'AiUsage';
      case _imx2nn1q.AiUserSetting():
        return 'AiUserSetting';
      case _ic7e83wd.AssistantContextHints():
        return 'AssistantContextHints';
      case _imp4tsxo.AssistantEvent():
        return 'AssistantEvent';
      case _id6kvqt9.AssistantEventType():
        return 'AssistantEventType';
      case _i8cittxq.AssistantMessage():
        return 'AssistantMessage';
      case _i4rkdm2k.AssistantMessageView():
        return 'AssistantMessageView';
      case _ia2m3j3v.AssistantStatus():
        return 'AssistantStatus';
      case _iaq6rutx.AssistantThread():
        return 'AssistantThread';
      case _i4iv0swm.AssistantThreadDetail():
        return 'AssistantThreadDetail';
      case _iohdfqf1.AssistantThreadView():
        return 'AssistantThreadView';
      case _i8ghcs7p.InlineAiEvent():
        return 'InlineAiEvent';
      case _i6pcz5z6.InlineAiEventType():
        return 'InlineAiEventType';
      case _i4m43iwr.InlineAiRequest():
        return 'InlineAiRequest';
      case _ie0jt2ne.ProofreadEvent():
        return 'ProofreadEvent';
      case _ivmxemza.ProofreadIssue():
        return 'ProofreadIssue';
      case _i0ag0upm.BoardArea():
        return 'BoardArea';
      case _ika8r7fc.BoardAuthor():
        return 'BoardAuthor';
      case _ilo15wk2.BoardBundleSuggestion():
        return 'BoardBundleSuggestion';
      case _iin47lv0.BoardBundleSuggestionView():
        return 'BoardBundleSuggestionView';
      case _ijz5flk6.BoardComment():
        return 'BoardComment';
      case _ipkjmsg5.BoardCommentView():
        return 'BoardCommentView';
      case _iswbp1jv.BoardCounts():
        return 'BoardCounts';
      case _ita8snxr.BoardEventKind():
        return 'BoardEventKind';
      case _i0y7d0xd.BoardFlag():
        return 'BoardFlag';
      case _iwc3b6vo.BoardFlagReason():
        return 'BoardFlagReason';
      case _i5pjfe5s.BoardFlagView():
        return 'BoardFlagView';
      case _igcoqerx.BoardListQuery():
        return 'BoardListQuery';
      case _iu9hvv8z.BoardMe():
        return 'BoardMe';
      case _in0hwjmy.BoardModeration():
        return 'BoardModeration';
      case _i5jfu168.BoardModerationAction():
        return 'BoardModerationAction';
      case _i7xps6dm.BoardPost():
        return 'BoardPost';
      case _izvgi5ni.BoardPostDraft():
        return 'BoardPostDraft';
      case _ibl25moa.BoardPostEvent():
        return 'BoardPostEvent';
      case _iui4x9zg.BoardPostKind():
        return 'BoardPostKind';
      case _iq3f61ec.BoardPostListItem():
        return 'BoardPostListItem';
      case _i1stsytz.BoardPostPage():
        return 'BoardPostPage';
      case _il200dga.BoardPostStatus():
        return 'BoardPostStatus';
      case _ijjd81zg.BoardPostView():
        return 'BoardPostView';
      case _im7v2irk.BoardReviewCounts():
        return 'BoardReviewCounts';
      case _id33cro1.BoardReviewItem():
        return 'BoardReviewItem';
      case _izs2n8vy.BoardReviewSection():
        return 'BoardReviewSection';
      case _ieemxbgb.BoardSignal():
        return 'BoardSignal';
      case _in3cjdcj.BoardSimilarPost():
        return 'BoardSimilarPost';
      case _ivbgicm7.BoardSize():
        return 'BoardSize';
      case _itz4727j.BoardSort():
        return 'BoardSort';
      case _i2gir90g.BoardTargetKind():
        return 'BoardTargetKind';
      case _iv26y3a1.BoardTask():
        return 'BoardTask';
      case _illpt7x2.BoardTaskPage():
        return 'BoardTaskPage';
      case _idsjzf6h.BoardTaskRef():
        return 'BoardTaskRef';
      case _i4a2ekwp.BoardTaskStatus():
        return 'BoardTaskStatus';
      case _ifz7dmuf.BoardTaskView():
        return 'BoardTaskView';
      case _iso7mdvm.BoardTriageState():
        return 'BoardTriageState';
      case _i516sz1w.BoardUserProfile():
        return 'BoardUserProfile';
      case _ifuo09i6.BoardVote():
        return 'BoardVote';
      case _ie24iiog.BoardVoteResult():
        return 'BoardVoteResult';
      case _iyixppck.Comment():
        return 'Comment';
      case _iw81twtc.CommentAnchorKind():
        return 'CommentAnchorKind';
      case _imlsyj2p.CommentEvent():
        return 'CommentEvent';
      case _ih1mb6x5.CommentEventKind():
        return 'CommentEventKind';
      case _il5y6tzr.CommentFilter():
        return 'CommentFilter';
      case _iowdswxe.CommentStatus():
        return 'CommentStatus';
      case _i94wr3td.CommentSystemEvent():
        return 'CommentSystemEvent';
      case _ijog60vm.CommentThread():
        return 'CommentThread';
      case _i818olql.CommentThreadView():
        return 'CommentThreadView';
      case _i4xrxro7.CommentView():
        return 'CommentView';
      case _ii98prcs.AccessRole():
        return 'AccessRole';
      case _i2wc4tyi.ActorKind():
        return 'ActorKind';
      case _inb0isem.WonkyErrorCode():
        return 'WonkyErrorCode';
      case _igdswlrw.WonkyException():
        return 'WonkyException';
      case _iktwt5zz.DriveChange():
        return 'DriveChange';
      case _ijoqbs82.DriveChangeKind():
        return 'DriveChangeKind';
      case _ig2nixhn.DriveImportOptions():
        return 'DriveImportOptions';
      case _inge8yy2.DriveItem():
        return 'DriveItem';
      case _i8mh39wa.DriveItemKind():
        return 'DriveItemKind';
      case _i0g2m831.DriveItemUserState():
        return 'DriveItemUserState';
      case _infxyf98.DriveItemView():
        return 'DriveItemView';
      case _ivypvw0m.DriveListFilter():
        return 'DriveListFilter';
      case _iavdhzsq.DriveListPage():
        return 'DriveListPage';
      case _if1dhg5z.DriveOwnerFilter():
        return 'DriveOwnerFilter';
      case _i6k3d1nc.DriveSearchFilters():
        return 'DriveSearchFilters';
      case _iu13r4v2.DriveSort():
        return 'DriveSort';
      case _ix0g8yw4.DriveSortField():
        return 'DriveSortField';
      case _ipww3kqy.DriveView():
        return 'DriveView';
      case _iez45i4u.FileCategory():
        return 'FileCategory';
      case _ilt75p4e.FileUploadProgress():
        return 'FileUploadProgress';
      case _iqpb2qv1.FileUploadRequest():
        return 'FileUploadRequest';
      case _imf3tnfq.FileUploadStart():
        return 'FileUploadStart';
      case _ia04wt6m.FileUploadState():
        return 'FileUploadState';
      case _i68yhxa0.ImportReportView():
        return 'ImportReportView';
      case _i48sm9f2.ImportWarningView():
        return 'ImportWarningView';
      case _i8hnug6t.StorageListFilter():
        return 'StorageListFilter';
      case _i26hsnhw.StorageUsage():
        return 'StorageUsage';
      case _iiedu4vz.TemplateCategory():
        return 'TemplateCategory';
      case _i6rg3vdh.TemplatePreviewStyle():
        return 'TemplatePreviewStyle';
      case _i2ox7ta1.TemplateView():
        return 'TemplateView';
      case _io3ccr8w.UploadConflictMode():
        return 'UploadConflictMode';
      case _iv1sk0e8.FeedbackKind():
        return 'FeedbackKind';
      case _ilhpki98.FeedbackSubmission():
        return 'FeedbackSubmission';
      case _irrzp8p9.FileUploadTicket():
        return 'FileUploadTicket';
      case _itzt3x6d.FileUrlView():
        return 'FileUrlView';
      case _im8eh74x.StoredFile():
        return 'StoredFile';
      case _i45dmz4a.StoredFileKind():
        return 'StoredFileKind';
      case _ik7q11oy.StoredFileStatus():
        return 'StoredFileStatus';
      case _ichw8k0i.UiBridgeCancel():
        return 'UiBridgeCancel';
      case _ichw8k0i.UiBridgeHello():
        return 'UiBridgeHello';
      case _ichw8k0i.UiBridgeRequest():
        return 'UiBridgeRequest';
      case _ichw8k0i.UiBridgeResponse():
        return 'UiBridgeResponse';
      case _ichw8k0i.UiBridgeStatus():
        return 'UiBridgeStatus';
      case _ichw8k0i.UiBridgeStop():
        return 'UiBridgeStop';
      case _ichw8k0i.UiBridgeWelcome():
        return 'UiBridgeWelcome';
      case _ivk6eyvx.FeatureFlags():
        return 'FeatureFlags';
      case _ib575x0y.ProtocolInfo():
        return 'ProtocolInfo';
      case _i28el0at.ServerLimits():
        return 'ServerLimits';
      case _iexg4yzt.NotificationEvent():
        return 'NotificationEvent';
      case _iqlnbbfp.NotificationKind():
        return 'NotificationKind';
      case _i3r1eo8q.NotificationPage():
        return 'NotificationPage';
      case _izfzk9h3.NotificationView():
        return 'NotificationView';
      case _ik59hiyp.UserNotification():
        return 'UserNotification';
      case _iylgyc33.Participant():
        return 'Participant';
      case _i8r9afjv.PresenceFollowerCount():
        return 'PresenceFollowerCount';
      case _i8r9afjv.PresenceHints():
        return 'PresenceHints';
      case _i8r9afjv.PresenceJoined():
        return 'PresenceJoined';
      case _i8r9afjv.PresenceLeft():
        return 'PresenceLeft';
      case _i8r9afjv.PresenceNotice():
        return 'PresenceNotice';
      case _i8r9afjv.PresenceRoster():
        return 'PresenceRoster';
      case _i8r9afjv.PresenceUpdated():
        return 'PresenceUpdated';
      case _ik055xb9.PresenceState():
        return 'PresenceState';
      case _isz2sju0.PresenceUpdate():
        return 'PresenceUpdate';
      case _ie6clghy.RevAck():
        return 'RevAck';
      case _i6ck957q.RevPing():
        return 'RevPing';
      case _i6ck957q.RevRequestOps():
        return 'RevRequestOps';
      case _i6ck957q.RevSubmit():
        return 'RevSubmit';
      case _ie6clghy.RevInit():
        return 'RevInit';
      case _ie6clghy.RevPong():
        return 'RevPong';
      case _ie6clghy.RevRejected():
        return 'RevRejected';
      case _ie6clghy.RevRemoteOp():
        return 'RevRemoteOp';
      case _ie6clghy.RevResync():
        return 'RevResync';
      case _ie6clghy.RevRoleChanged():
        return 'RevRoleChanged';
      case _ihwy023l.RevFileInfo():
        return 'RevFileInfo';
      case _iwkehf4e.RevFileKind():
        return 'RevFileKind';
      case _it4o2pk5.RevOpView():
        return 'RevOpView';
      case _ium7xjeg.RevPage():
        return 'RevPage';
      case _i3q3ua5p.RevPageKind():
        return 'RevPageKind';
      case _if03ikx4.RevPageRequest():
        return 'RevPageRequest';
      case _iilsyt4b.RevRejectCode():
        return 'RevRejectCode';
      case _i8scn8dm.AccessRequest():
        return 'AccessRequest';
      case _i7trut12.AccessRequestOutcome():
        return 'AccessRequestOutcome';
      case _iimp60a4.AccessRequestView():
        return 'AccessRequestView';
      case _iuzgacy4.DriveItemPermission():
        return 'DriveItemPermission';
      case _ikeljole.InviteResolution():
        return 'InviteResolution';
      case _ih3711er.ItemSharingSettings():
        return 'ItemSharingSettings';
      case _ijwxtu30.OwnershipTransfer():
        return 'OwnershipTransfer';
      case _iilpsf9g.OwnershipTransferView():
        return 'OwnershipTransferView';
      case _iead0ok9.PermissionView():
        return 'PermissionView';
      case _it712lg1.ShareLink():
        return 'ShareLink';
      case _iw2xoohn.ShareLinkView():
        return 'ShareLinkView';
      case _itd24os1.SharingInfo():
        return 'SharingInfo';
      case _ifxa4vxf.QuotaExceededDetails():
        return 'QuotaExceededDetails';
      case _izha9j5m.AccessTokenView():
        return 'AccessTokenView';
      case _iq4dupwy.AccountDeletionPreview():
        return 'AccountDeletionPreview';
      case _i6azdr3n.AppThemeMode():
        return 'AppThemeMode';
      case _iru4pv75.CreatedAccessToken():
        return 'CreatedAccessToken';
      case _i5lc4gt0.UiDensity():
        return 'UiDensity';
      case _i501u5m5.UserPreferences():
        return 'UserPreferences';
      case _id95rrz2.UserPreferencesPatch():
        return 'UserPreferencesPatch';
      case _ihzl7wbq.UserProfile():
        return 'UserProfile';
      case _iufqmqtc.UserProfileView():
        return 'UserProfileView';
      case _i6y7tspy.UserSummary():
        return 'UserSummary';
      case _i7jb115m.ItemVersion():
        return 'ItemVersion';
      case _ipbapjbz.ItemVersionView():
        return 'ItemVersionView';
      case _in0fdl1f.VersionKind():
        return 'VersionKind';
      case _in38zbga.VersionRestoreResult():
        return 'VersionRestoreResult';
      case _i5u6d6t4.VersionStorage():
        return 'VersionStorage';
      case _iuzj1jin.SheetsAiApplyResult():
        return 'SheetsAiApplyResult';
      case _iljqbz3a.SheetsAiCellRequest():
        return 'SheetsAiCellRequest';
      case _im85lt6z.SheetsAiCellResult():
        return 'SheetsAiCellResult';
      case _i4t3jyqe.SheetsAiPreview():
        return 'SheetsAiPreview';
      case _idzstekp.SheetsAiPreviewCall():
        return 'SheetsAiPreviewCall';
      case _i49726iv.SheetsAiPreviewCell():
        return 'SheetsAiPreviewCell';
      case _izbpavhd.SheetsFillProposal():
        return 'SheetsFillProposal';
      case _i1gi0ui2.SheetsFillRow():
        return 'SheetsFillRow';
      case _i2bhah0l.SheetsFormulaSuggestion():
        return 'SheetsFormulaSuggestion';
      case _iaf43n69.SheetsImportProgress():
        return 'SheetsImportProgress';
      case _i8d83qca.SheetsImportStatus():
        return 'SheetsImportStatus';
      case _ij1xvs09.CellHistoryEntry():
        return 'CellHistoryEntry';
      case _i09xo3k8.CellHistoryPage():
        return 'CellHistoryPage';
      case _ilv3hlxr.RevertResult():
        return 'RevertResult';
      case _ipqum05l.RevertSkip():
        return 'RevertSkip';
      case _ilnsyzhq.Dimension():
        return 'Dimension';
      case _ihfpm0ve.EmbeddedObjectKind():
        return 'EmbeddedObjectKind';
      case _iofwzekn.HorizontalAlign():
        return 'HorizontalAlign';
      case _i0z9m4nl.RecalcMode():
        return 'RecalcMode';
      case _io4oc09s.ScriptBuildStatus():
        return 'ScriptBuildStatus';
      case _i8ne06ql.SheetKind():
        return 'SheetKind';
      case _irmtoho8.TriggerKind():
        return 'TriggerKind';
      case _ivf2txqv.VerticalAlign():
        return 'VerticalAlign';
      case _iz9rjt8b.WrapStrategy():
        return 'WrapStrategy';
      case _iaehez21.SheetsActivitySummary():
        return 'SheetsActivitySummary';
      case _i9yjzgjk.SheetsContributorStat():
        return 'SheetsContributorStat';
      case _icjzxy6x.ScriptAuthorizationView():
        return 'ScriptAuthorizationView';
      case _iq0xpzf7.ScriptCompileResponse():
        return 'ScriptCompileResponse';
      case _i4bc0fek.ScriptExecution():
        return 'ScriptExecution';
      case _inqz9v2t.ScriptExecutionKind():
        return 'ScriptExecutionKind';
      case _ira26pfa.ScriptExecutionStatus():
        return 'ScriptExecutionStatus';
      case _is04pxv8.ScriptFetchResponse():
        return 'ScriptFetchResponse';
      case _is0mvar3.ScriptRunResponse():
        return 'ScriptRunResponse';
      case _iy0fj18f.ScriptRuntimeKind():
        return 'ScriptRuntimeKind';
      case _iwj0qehd.SlidesAiAltText():
        return 'SlidesAiAltText';
      case _ix6z7bmu.SlidesAiApplyResult():
        return 'SlidesAiApplyResult';
      case _isdksxfl.SlidesAiBuildResult():
        return 'SlidesAiBuildResult';
      case _i154xjj9.SlidesAiDesignRank():
        return 'SlidesAiDesignRank';
      case _itoukaix.SlidesAiNote():
        return 'SlidesAiNote';
      case _i225jf90.SlidesAiOutlineRequest():
        return 'SlidesAiOutlineRequest';
      case _ioipp9xy.SlidesAiPreview():
        return 'SlidesAiPreview';
      case _iuzye628.SlidesAiPreviewCall():
        return 'SlidesAiPreviewCall';
      case _ixaahmd2.SlidesAiRewriteRequest():
        return 'SlidesAiRewriteRequest';
      case _i7q1o3oi.ChartLinkProbe():
        return 'ChartLinkProbe';
      case _i3ysrjbx.ChartLinkState():
        return 'ChartLinkState';
      case _is6z3tpy.ChartLinkStatus():
        return 'ChartLinkStatus';
      case _iua8dx49.ChartSnapshotView():
        return 'ChartSnapshotView';
      case _iq1h9id2.ChartSourceList():
        return 'ChartSourceList';
      case _inygrvyi.ChartSourceSummary():
        return 'ChartSourceSummary';
      case _ipok3hcm.BuildKind():
        return 'BuildKind';
      case _isb6wks2.BuildTrigger():
        return 'BuildTrigger';
      case _isf9v7y6.DeckAppearance():
        return 'DeckAppearance';
      case _i4oq3vgh.PlaceholderType():
        return 'PlaceholderType';
      case _isah8148.SlideElementKind():
        return 'SlideElementKind';
      case _isghg0k1.SlideSizePreset():
        return 'SlideSizePreset';
      case _i5m4q7yg.TableDimension():
        return 'TableDimension';
      case _iz9vxb2f.PresentationCommandEvent():
        return 'PresentationCommandEvent';
      case _ijdad65m.PresentationCommandUpdate():
        return 'PresentationCommandUpdate';
      case _ijdad65m.PresentationEndUpdate():
        return 'PresentationEndUpdate';
      case _iz9vxb2f.PresentationEndedEvent():
        return 'PresentationEndedEvent';
      case _iz9vxb2f.PresentationInkEvent():
        return 'PresentationInkEvent';
      case _iz9vxb2f.PresentationLaserEvent():
        return 'PresentationLaserEvent';
      case _iz9vxb2f.PresentationPairingEvent():
        return 'PresentationPairingEvent';
      case _iz9vxb2f.PresentationPresenterEvent():
        return 'PresentationPresenterEvent';
      case _iz9vxb2f.PresentationRosterEvent():
        return 'PresentationRosterEvent';
      case _iz9vxb2f.PresentationStateEvent():
        return 'PresentationStateEvent';
      case _iz9vxb2f.PresentationWelcome():
        return 'PresentationWelcome';
      case _ijdad65m.PresentationInkUpdate():
        return 'PresentationInkUpdate';
      case _ih25cwup.PresentationJoin():
        return 'PresentationJoin';
      case _ijdad65m.PresentationLaserUpdate():
        return 'PresentationLaserUpdate';
      case _i6know5x.PresentationPairingTarget():
        return 'PresentationPairingTarget';
      case _ijdad65m.PresentationPairingUpdate():
        return 'PresentationPairingUpdate';
      case _ijgt5qi7.PresentationParticipant():
        return 'PresentationParticipant';
      case _i4d7um9r.PresentationRole():
        return 'PresentationRole';
      case _ig7ln54r.PresentationSessionInfo():
        return 'PresentationSessionInfo';
      case _i95fngt4.PresentationState():
        return 'PresentationState';
      case _ijdad65m.PresentationStateUpdate():
        return 'PresentationStateUpdate';
      case _icpkpcrn.DocAck():
        return 'DocAck';
      case _imbts8if.DocCursorUpdate():
        return 'DocCursorUpdate';
      case _imbts8if.DocHashCheck():
        return 'DocHashCheck';
      case _imbts8if.DocPing():
        return 'DocPing';
      case _imbts8if.DocRequestOps():
        return 'DocRequestOps';
      case _imbts8if.DocSubmitOp():
        return 'DocSubmitOp';
      case _icpkpcrn.DocHashResult():
        return 'DocHashResult';
      case _icpkpcrn.DocInit():
        return 'DocInit';
      case _icpkpcrn.DocMetaChanged():
        return 'DocMetaChanged';
      case _icpkpcrn.DocOpRejected():
        return 'DocOpRejected';
      case _icpkpcrn.DocParticipantJoined():
        return 'DocParticipantJoined';
      case _icpkpcrn.DocParticipantLeft():
        return 'DocParticipantLeft';
      case _icpkpcrn.DocPong():
        return 'DocPong';
      case _icpkpcrn.DocRemoteCursor():
        return 'DocRemoteCursor';
      case _icpkpcrn.DocRemoteOp():
        return 'DocRemoteOp';
      case _icpkpcrn.DocRoleChanged():
        return 'DocRoleChanged';
      case _igqu3xcv.ConvertForInsertResult():
        return 'ConvertForInsertResult';
      case _i5srcd7q.DocRejectCode():
        return 'DocRejectCode';
      case _i4sx4pml.Document():
        return 'Document';
      case _iu022vpf.DocumentInfo():
        return 'DocumentInfo';
      case _ir38bcqq.DocumentMetaChange():
        return 'DocumentMetaChange';
      case _inkjv0lb.DocumentMetaPatch():
        return 'DocumentMetaPatch';
      case _icsyekcn.DocumentMetaView():
        return 'DocumentMetaView';
      case _iufsprkx.DocumentOp():
        return 'DocumentOp';
      case _igr6xq1c.DocumentOpKind():
        return 'DocumentOpKind';
      case _issmv319.DocumentOpView():
        return 'DocumentOpView';
      case _i2cnn8i8.DocumentSnapshot():
        return 'DocumentSnapshot';
      case _i0cy62lm.DocumentSnapshotView():
        return 'DocumentSnapshotView';
      case _is1ql5wp.ExportProgressEvent():
        return 'ExportProgressEvent';
      case _isdjhzgs.ExportProgressKind():
        return 'ExportProgressKind';
      case _if2sngze.ExportResultView():
        return 'ExportResultView';
      case _ittnhawp.ThemeConflictException():
        return 'ThemeConflictException';
      case _ii88i7dv.WriteDiffAuthor():
        return 'WriteDiffAuthor';
      case _idky93gt.WriteDiffView():
        return 'WriteDiffView';
      case _iynqrh33.WriteTheme():
        return 'WriteTheme';
      case _i7pbwt05.WriteThemeRevision():
        return 'WriteThemeRevision';
      case _ick3mhj2.WriteThemeRevisionView():
        return 'WriteThemeRevisionView';
      case _ixbjd26z.WriteThemeView():
        return 'WriteThemeView';
      case _is9bkd9t.WriteVersionDocument():
        return 'WriteVersionDocument';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ActivityDashboard') {
      return deserialize<_izr1y672.ActivityDashboard>(data['data']);
    }
    if (dataClassName == 'ActivityEvent') {
      return deserialize<_iatdjl5p.ActivityEvent>(data['data']);
    }
    if (dataClassName == 'ActivityEventView') {
      return deserialize<_isa7sjzq.ActivityEventView>(data['data']);
    }
    if (dataClassName == 'ActivityTrendPoint') {
      return deserialize<_ighcq381.ActivityTrendPoint>(data['data']);
    }
    if (dataClassName == 'ActivityType') {
      return deserialize<_i50cy468.ActivityType>(data['data']);
    }
    if (dataClassName == 'ActivityViewer') {
      return deserialize<_ikcwdr17.ActivityViewer>(data['data']);
    }
    if (dataClassName == 'AiApplyMode') {
      return deserialize<_iyja8k5e.AiApplyMode>(data['data']);
    }
    if (dataClassName == 'AiProvider') {
      return deserialize<_ir7z75mb.AiProvider>(data['data']);
    }
    if (dataClassName == 'AiProviderKeyView') {
      return deserialize<_ic2q2fwi.AiProviderKeyView>(data['data']);
    }
    if (dataClassName == 'AiQuality') {
      return deserialize<_iviyoyk9.AiQuality>(data['data']);
    }
    if (dataClassName == 'AiUsage') {
      return deserialize<_i7i53on7.AiUsage>(data['data']);
    }
    if (dataClassName == 'AiUserSetting') {
      return deserialize<_imx2nn1q.AiUserSetting>(data['data']);
    }
    if (dataClassName == 'AssistantContextHints') {
      return deserialize<_ic7e83wd.AssistantContextHints>(data['data']);
    }
    if (dataClassName == 'AssistantEvent') {
      return deserialize<_imp4tsxo.AssistantEvent>(data['data']);
    }
    if (dataClassName == 'AssistantEventType') {
      return deserialize<_id6kvqt9.AssistantEventType>(data['data']);
    }
    if (dataClassName == 'AssistantMessage') {
      return deserialize<_i8cittxq.AssistantMessage>(data['data']);
    }
    if (dataClassName == 'AssistantMessageView') {
      return deserialize<_i4rkdm2k.AssistantMessageView>(data['data']);
    }
    if (dataClassName == 'AssistantStatus') {
      return deserialize<_ia2m3j3v.AssistantStatus>(data['data']);
    }
    if (dataClassName == 'AssistantThread') {
      return deserialize<_iaq6rutx.AssistantThread>(data['data']);
    }
    if (dataClassName == 'AssistantThreadDetail') {
      return deserialize<_i4iv0swm.AssistantThreadDetail>(data['data']);
    }
    if (dataClassName == 'AssistantThreadView') {
      return deserialize<_iohdfqf1.AssistantThreadView>(data['data']);
    }
    if (dataClassName == 'InlineAiEvent') {
      return deserialize<_i8ghcs7p.InlineAiEvent>(data['data']);
    }
    if (dataClassName == 'InlineAiEventType') {
      return deserialize<_i6pcz5z6.InlineAiEventType>(data['data']);
    }
    if (dataClassName == 'InlineAiRequest') {
      return deserialize<_i4m43iwr.InlineAiRequest>(data['data']);
    }
    if (dataClassName == 'ProofreadEvent') {
      return deserialize<_ie0jt2ne.ProofreadEvent>(data['data']);
    }
    if (dataClassName == 'ProofreadIssue') {
      return deserialize<_ivmxemza.ProofreadIssue>(data['data']);
    }
    if (dataClassName == 'BoardArea') {
      return deserialize<_i0ag0upm.BoardArea>(data['data']);
    }
    if (dataClassName == 'BoardAuthor') {
      return deserialize<_ika8r7fc.BoardAuthor>(data['data']);
    }
    if (dataClassName == 'BoardBundleSuggestion') {
      return deserialize<_ilo15wk2.BoardBundleSuggestion>(data['data']);
    }
    if (dataClassName == 'BoardBundleSuggestionView') {
      return deserialize<_iin47lv0.BoardBundleSuggestionView>(data['data']);
    }
    if (dataClassName == 'BoardComment') {
      return deserialize<_ijz5flk6.BoardComment>(data['data']);
    }
    if (dataClassName == 'BoardCommentView') {
      return deserialize<_ipkjmsg5.BoardCommentView>(data['data']);
    }
    if (dataClassName == 'BoardCounts') {
      return deserialize<_iswbp1jv.BoardCounts>(data['data']);
    }
    if (dataClassName == 'BoardEventKind') {
      return deserialize<_ita8snxr.BoardEventKind>(data['data']);
    }
    if (dataClassName == 'BoardFlag') {
      return deserialize<_i0y7d0xd.BoardFlag>(data['data']);
    }
    if (dataClassName == 'BoardFlagReason') {
      return deserialize<_iwc3b6vo.BoardFlagReason>(data['data']);
    }
    if (dataClassName == 'BoardFlagView') {
      return deserialize<_i5pjfe5s.BoardFlagView>(data['data']);
    }
    if (dataClassName == 'BoardListQuery') {
      return deserialize<_igcoqerx.BoardListQuery>(data['data']);
    }
    if (dataClassName == 'BoardMe') {
      return deserialize<_iu9hvv8z.BoardMe>(data['data']);
    }
    if (dataClassName == 'BoardModeration') {
      return deserialize<_in0hwjmy.BoardModeration>(data['data']);
    }
    if (dataClassName == 'BoardModerationAction') {
      return deserialize<_i5jfu168.BoardModerationAction>(data['data']);
    }
    if (dataClassName == 'BoardPost') {
      return deserialize<_i7xps6dm.BoardPost>(data['data']);
    }
    if (dataClassName == 'BoardPostDraft') {
      return deserialize<_izvgi5ni.BoardPostDraft>(data['data']);
    }
    if (dataClassName == 'BoardPostEvent') {
      return deserialize<_ibl25moa.BoardPostEvent>(data['data']);
    }
    if (dataClassName == 'BoardPostKind') {
      return deserialize<_iui4x9zg.BoardPostKind>(data['data']);
    }
    if (dataClassName == 'BoardPostListItem') {
      return deserialize<_iq3f61ec.BoardPostListItem>(data['data']);
    }
    if (dataClassName == 'BoardPostPage') {
      return deserialize<_i1stsytz.BoardPostPage>(data['data']);
    }
    if (dataClassName == 'BoardPostStatus') {
      return deserialize<_il200dga.BoardPostStatus>(data['data']);
    }
    if (dataClassName == 'BoardPostView') {
      return deserialize<_ijjd81zg.BoardPostView>(data['data']);
    }
    if (dataClassName == 'BoardReviewCounts') {
      return deserialize<_im7v2irk.BoardReviewCounts>(data['data']);
    }
    if (dataClassName == 'BoardReviewItem') {
      return deserialize<_id33cro1.BoardReviewItem>(data['data']);
    }
    if (dataClassName == 'BoardReviewSection') {
      return deserialize<_izs2n8vy.BoardReviewSection>(data['data']);
    }
    if (dataClassName == 'BoardSignal') {
      return deserialize<_ieemxbgb.BoardSignal>(data['data']);
    }
    if (dataClassName == 'BoardSimilarPost') {
      return deserialize<_in3cjdcj.BoardSimilarPost>(data['data']);
    }
    if (dataClassName == 'BoardSize') {
      return deserialize<_ivbgicm7.BoardSize>(data['data']);
    }
    if (dataClassName == 'BoardSort') {
      return deserialize<_itz4727j.BoardSort>(data['data']);
    }
    if (dataClassName == 'BoardTargetKind') {
      return deserialize<_i2gir90g.BoardTargetKind>(data['data']);
    }
    if (dataClassName == 'BoardTask') {
      return deserialize<_iv26y3a1.BoardTask>(data['data']);
    }
    if (dataClassName == 'BoardTaskPage') {
      return deserialize<_illpt7x2.BoardTaskPage>(data['data']);
    }
    if (dataClassName == 'BoardTaskRef') {
      return deserialize<_idsjzf6h.BoardTaskRef>(data['data']);
    }
    if (dataClassName == 'BoardTaskStatus') {
      return deserialize<_i4a2ekwp.BoardTaskStatus>(data['data']);
    }
    if (dataClassName == 'BoardTaskView') {
      return deserialize<_ifz7dmuf.BoardTaskView>(data['data']);
    }
    if (dataClassName == 'BoardTriageState') {
      return deserialize<_iso7mdvm.BoardTriageState>(data['data']);
    }
    if (dataClassName == 'BoardUserProfile') {
      return deserialize<_i516sz1w.BoardUserProfile>(data['data']);
    }
    if (dataClassName == 'BoardVote') {
      return deserialize<_ifuo09i6.BoardVote>(data['data']);
    }
    if (dataClassName == 'BoardVoteResult') {
      return deserialize<_ie24iiog.BoardVoteResult>(data['data']);
    }
    if (dataClassName == 'Comment') {
      return deserialize<_iyixppck.Comment>(data['data']);
    }
    if (dataClassName == 'CommentAnchorKind') {
      return deserialize<_iw81twtc.CommentAnchorKind>(data['data']);
    }
    if (dataClassName == 'CommentEvent') {
      return deserialize<_imlsyj2p.CommentEvent>(data['data']);
    }
    if (dataClassName == 'CommentEventKind') {
      return deserialize<_ih1mb6x5.CommentEventKind>(data['data']);
    }
    if (dataClassName == 'CommentFilter') {
      return deserialize<_il5y6tzr.CommentFilter>(data['data']);
    }
    if (dataClassName == 'CommentStatus') {
      return deserialize<_iowdswxe.CommentStatus>(data['data']);
    }
    if (dataClassName == 'CommentSystemEvent') {
      return deserialize<_i94wr3td.CommentSystemEvent>(data['data']);
    }
    if (dataClassName == 'CommentThread') {
      return deserialize<_ijog60vm.CommentThread>(data['data']);
    }
    if (dataClassName == 'CommentThreadView') {
      return deserialize<_i818olql.CommentThreadView>(data['data']);
    }
    if (dataClassName == 'CommentView') {
      return deserialize<_i4xrxro7.CommentView>(data['data']);
    }
    if (dataClassName == 'AccessRole') {
      return deserialize<_ii98prcs.AccessRole>(data['data']);
    }
    if (dataClassName == 'ActorKind') {
      return deserialize<_i2wc4tyi.ActorKind>(data['data']);
    }
    if (dataClassName == 'WonkyErrorCode') {
      return deserialize<_inb0isem.WonkyErrorCode>(data['data']);
    }
    if (dataClassName == 'WonkyException') {
      return deserialize<_igdswlrw.WonkyException>(data['data']);
    }
    if (dataClassName == 'DriveChange') {
      return deserialize<_iktwt5zz.DriveChange>(data['data']);
    }
    if (dataClassName == 'DriveChangeKind') {
      return deserialize<_ijoqbs82.DriveChangeKind>(data['data']);
    }
    if (dataClassName == 'DriveImportOptions') {
      return deserialize<_ig2nixhn.DriveImportOptions>(data['data']);
    }
    if (dataClassName == 'DriveItem') {
      return deserialize<_inge8yy2.DriveItem>(data['data']);
    }
    if (dataClassName == 'DriveItemKind') {
      return deserialize<_i8mh39wa.DriveItemKind>(data['data']);
    }
    if (dataClassName == 'DriveItemUserState') {
      return deserialize<_i0g2m831.DriveItemUserState>(data['data']);
    }
    if (dataClassName == 'DriveItemView') {
      return deserialize<_infxyf98.DriveItemView>(data['data']);
    }
    if (dataClassName == 'DriveListFilter') {
      return deserialize<_ivypvw0m.DriveListFilter>(data['data']);
    }
    if (dataClassName == 'DriveListPage') {
      return deserialize<_iavdhzsq.DriveListPage>(data['data']);
    }
    if (dataClassName == 'DriveOwnerFilter') {
      return deserialize<_if1dhg5z.DriveOwnerFilter>(data['data']);
    }
    if (dataClassName == 'DriveSearchFilters') {
      return deserialize<_i6k3d1nc.DriveSearchFilters>(data['data']);
    }
    if (dataClassName == 'DriveSort') {
      return deserialize<_iu13r4v2.DriveSort>(data['data']);
    }
    if (dataClassName == 'DriveSortField') {
      return deserialize<_ix0g8yw4.DriveSortField>(data['data']);
    }
    if (dataClassName == 'DriveView') {
      return deserialize<_ipww3kqy.DriveView>(data['data']);
    }
    if (dataClassName == 'FileCategory') {
      return deserialize<_iez45i4u.FileCategory>(data['data']);
    }
    if (dataClassName == 'FileUploadProgress') {
      return deserialize<_ilt75p4e.FileUploadProgress>(data['data']);
    }
    if (dataClassName == 'FileUploadRequest') {
      return deserialize<_iqpb2qv1.FileUploadRequest>(data['data']);
    }
    if (dataClassName == 'FileUploadStart') {
      return deserialize<_imf3tnfq.FileUploadStart>(data['data']);
    }
    if (dataClassName == 'FileUploadState') {
      return deserialize<_ia04wt6m.FileUploadState>(data['data']);
    }
    if (dataClassName == 'ImportReportView') {
      return deserialize<_i68yhxa0.ImportReportView>(data['data']);
    }
    if (dataClassName == 'ImportWarningView') {
      return deserialize<_i48sm9f2.ImportWarningView>(data['data']);
    }
    if (dataClassName == 'StorageListFilter') {
      return deserialize<_i8hnug6t.StorageListFilter>(data['data']);
    }
    if (dataClassName == 'StorageUsage') {
      return deserialize<_i26hsnhw.StorageUsage>(data['data']);
    }
    if (dataClassName == 'TemplateCategory') {
      return deserialize<_iiedu4vz.TemplateCategory>(data['data']);
    }
    if (dataClassName == 'TemplatePreviewStyle') {
      return deserialize<_i6rg3vdh.TemplatePreviewStyle>(data['data']);
    }
    if (dataClassName == 'TemplateView') {
      return deserialize<_i2ox7ta1.TemplateView>(data['data']);
    }
    if (dataClassName == 'UploadConflictMode') {
      return deserialize<_io3ccr8w.UploadConflictMode>(data['data']);
    }
    if (dataClassName == 'FeedbackKind') {
      return deserialize<_iv1sk0e8.FeedbackKind>(data['data']);
    }
    if (dataClassName == 'FeedbackSubmission') {
      return deserialize<_ilhpki98.FeedbackSubmission>(data['data']);
    }
    if (dataClassName == 'FileUploadTicket') {
      return deserialize<_irrzp8p9.FileUploadTicket>(data['data']);
    }
    if (dataClassName == 'FileUrlView') {
      return deserialize<_itzt3x6d.FileUrlView>(data['data']);
    }
    if (dataClassName == 'StoredFile') {
      return deserialize<_im8eh74x.StoredFile>(data['data']);
    }
    if (dataClassName == 'StoredFileKind') {
      return deserialize<_i45dmz4a.StoredFileKind>(data['data']);
    }
    if (dataClassName == 'StoredFileStatus') {
      return deserialize<_ik7q11oy.StoredFileStatus>(data['data']);
    }
    if (dataClassName == 'UiBridgeCancel') {
      return deserialize<_ichw8k0i.UiBridgeCancel>(data['data']);
    }
    if (dataClassName == 'UiBridgeHello') {
      return deserialize<_ichw8k0i.UiBridgeHello>(data['data']);
    }
    if (dataClassName == 'UiBridgeRequest') {
      return deserialize<_ichw8k0i.UiBridgeRequest>(data['data']);
    }
    if (dataClassName == 'UiBridgeResponse') {
      return deserialize<_ichw8k0i.UiBridgeResponse>(data['data']);
    }
    if (dataClassName == 'UiBridgeStatus') {
      return deserialize<_ichw8k0i.UiBridgeStatus>(data['data']);
    }
    if (dataClassName == 'UiBridgeStop') {
      return deserialize<_ichw8k0i.UiBridgeStop>(data['data']);
    }
    if (dataClassName == 'UiBridgeWelcome') {
      return deserialize<_ichw8k0i.UiBridgeWelcome>(data['data']);
    }
    if (dataClassName == 'FeatureFlags') {
      return deserialize<_ivk6eyvx.FeatureFlags>(data['data']);
    }
    if (dataClassName == 'ProtocolInfo') {
      return deserialize<_ib575x0y.ProtocolInfo>(data['data']);
    }
    if (dataClassName == 'ServerLimits') {
      return deserialize<_i28el0at.ServerLimits>(data['data']);
    }
    if (dataClassName == 'NotificationEvent') {
      return deserialize<_iexg4yzt.NotificationEvent>(data['data']);
    }
    if (dataClassName == 'NotificationKind') {
      return deserialize<_iqlnbbfp.NotificationKind>(data['data']);
    }
    if (dataClassName == 'NotificationPage') {
      return deserialize<_i3r1eo8q.NotificationPage>(data['data']);
    }
    if (dataClassName == 'NotificationView') {
      return deserialize<_izfzk9h3.NotificationView>(data['data']);
    }
    if (dataClassName == 'UserNotification') {
      return deserialize<_ik59hiyp.UserNotification>(data['data']);
    }
    if (dataClassName == 'Participant') {
      return deserialize<_iylgyc33.Participant>(data['data']);
    }
    if (dataClassName == 'PresenceFollowerCount') {
      return deserialize<_i8r9afjv.PresenceFollowerCount>(data['data']);
    }
    if (dataClassName == 'PresenceHints') {
      return deserialize<_i8r9afjv.PresenceHints>(data['data']);
    }
    if (dataClassName == 'PresenceJoined') {
      return deserialize<_i8r9afjv.PresenceJoined>(data['data']);
    }
    if (dataClassName == 'PresenceLeft') {
      return deserialize<_i8r9afjv.PresenceLeft>(data['data']);
    }
    if (dataClassName == 'PresenceNotice') {
      return deserialize<_i8r9afjv.PresenceNotice>(data['data']);
    }
    if (dataClassName == 'PresenceRoster') {
      return deserialize<_i8r9afjv.PresenceRoster>(data['data']);
    }
    if (dataClassName == 'PresenceUpdated') {
      return deserialize<_i8r9afjv.PresenceUpdated>(data['data']);
    }
    if (dataClassName == 'PresenceState') {
      return deserialize<_ik055xb9.PresenceState>(data['data']);
    }
    if (dataClassName == 'PresenceUpdate') {
      return deserialize<_isz2sju0.PresenceUpdate>(data['data']);
    }
    if (dataClassName == 'RevAck') {
      return deserialize<_ie6clghy.RevAck>(data['data']);
    }
    if (dataClassName == 'RevPing') {
      return deserialize<_i6ck957q.RevPing>(data['data']);
    }
    if (dataClassName == 'RevRequestOps') {
      return deserialize<_i6ck957q.RevRequestOps>(data['data']);
    }
    if (dataClassName == 'RevSubmit') {
      return deserialize<_i6ck957q.RevSubmit>(data['data']);
    }
    if (dataClassName == 'RevInit') {
      return deserialize<_ie6clghy.RevInit>(data['data']);
    }
    if (dataClassName == 'RevPong') {
      return deserialize<_ie6clghy.RevPong>(data['data']);
    }
    if (dataClassName == 'RevRejected') {
      return deserialize<_ie6clghy.RevRejected>(data['data']);
    }
    if (dataClassName == 'RevRemoteOp') {
      return deserialize<_ie6clghy.RevRemoteOp>(data['data']);
    }
    if (dataClassName == 'RevResync') {
      return deserialize<_ie6clghy.RevResync>(data['data']);
    }
    if (dataClassName == 'RevRoleChanged') {
      return deserialize<_ie6clghy.RevRoleChanged>(data['data']);
    }
    if (dataClassName == 'RevFileInfo') {
      return deserialize<_ihwy023l.RevFileInfo>(data['data']);
    }
    if (dataClassName == 'RevFileKind') {
      return deserialize<_iwkehf4e.RevFileKind>(data['data']);
    }
    if (dataClassName == 'RevOpView') {
      return deserialize<_it4o2pk5.RevOpView>(data['data']);
    }
    if (dataClassName == 'RevPage') {
      return deserialize<_ium7xjeg.RevPage>(data['data']);
    }
    if (dataClassName == 'RevPageKind') {
      return deserialize<_i3q3ua5p.RevPageKind>(data['data']);
    }
    if (dataClassName == 'RevPageRequest') {
      return deserialize<_if03ikx4.RevPageRequest>(data['data']);
    }
    if (dataClassName == 'RevRejectCode') {
      return deserialize<_iilsyt4b.RevRejectCode>(data['data']);
    }
    if (dataClassName == 'AccessRequest') {
      return deserialize<_i8scn8dm.AccessRequest>(data['data']);
    }
    if (dataClassName == 'AccessRequestOutcome') {
      return deserialize<_i7trut12.AccessRequestOutcome>(data['data']);
    }
    if (dataClassName == 'AccessRequestView') {
      return deserialize<_iimp60a4.AccessRequestView>(data['data']);
    }
    if (dataClassName == 'DriveItemPermission') {
      return deserialize<_iuzgacy4.DriveItemPermission>(data['data']);
    }
    if (dataClassName == 'InviteResolution') {
      return deserialize<_ikeljole.InviteResolution>(data['data']);
    }
    if (dataClassName == 'ItemSharingSettings') {
      return deserialize<_ih3711er.ItemSharingSettings>(data['data']);
    }
    if (dataClassName == 'OwnershipTransfer') {
      return deserialize<_ijwxtu30.OwnershipTransfer>(data['data']);
    }
    if (dataClassName == 'OwnershipTransferView') {
      return deserialize<_iilpsf9g.OwnershipTransferView>(data['data']);
    }
    if (dataClassName == 'PermissionView') {
      return deserialize<_iead0ok9.PermissionView>(data['data']);
    }
    if (dataClassName == 'ShareLink') {
      return deserialize<_it712lg1.ShareLink>(data['data']);
    }
    if (dataClassName == 'ShareLinkView') {
      return deserialize<_iw2xoohn.ShareLinkView>(data['data']);
    }
    if (dataClassName == 'SharingInfo') {
      return deserialize<_itd24os1.SharingInfo>(data['data']);
    }
    if (dataClassName == 'QuotaExceededDetails') {
      return deserialize<_ifxa4vxf.QuotaExceededDetails>(data['data']);
    }
    if (dataClassName == 'AccessTokenView') {
      return deserialize<_izha9j5m.AccessTokenView>(data['data']);
    }
    if (dataClassName == 'AccountDeletionPreview') {
      return deserialize<_iq4dupwy.AccountDeletionPreview>(data['data']);
    }
    if (dataClassName == 'AppThemeMode') {
      return deserialize<_i6azdr3n.AppThemeMode>(data['data']);
    }
    if (dataClassName == 'CreatedAccessToken') {
      return deserialize<_iru4pv75.CreatedAccessToken>(data['data']);
    }
    if (dataClassName == 'UiDensity') {
      return deserialize<_i5lc4gt0.UiDensity>(data['data']);
    }
    if (dataClassName == 'UserPreferences') {
      return deserialize<_i501u5m5.UserPreferences>(data['data']);
    }
    if (dataClassName == 'UserPreferencesPatch') {
      return deserialize<_id95rrz2.UserPreferencesPatch>(data['data']);
    }
    if (dataClassName == 'UserProfile') {
      return deserialize<_ihzl7wbq.UserProfile>(data['data']);
    }
    if (dataClassName == 'UserProfileView') {
      return deserialize<_iufqmqtc.UserProfileView>(data['data']);
    }
    if (dataClassName == 'UserSummary') {
      return deserialize<_i6y7tspy.UserSummary>(data['data']);
    }
    if (dataClassName == 'ItemVersion') {
      return deserialize<_i7jb115m.ItemVersion>(data['data']);
    }
    if (dataClassName == 'ItemVersionView') {
      return deserialize<_ipbapjbz.ItemVersionView>(data['data']);
    }
    if (dataClassName == 'VersionKind') {
      return deserialize<_in0fdl1f.VersionKind>(data['data']);
    }
    if (dataClassName == 'VersionRestoreResult') {
      return deserialize<_in38zbga.VersionRestoreResult>(data['data']);
    }
    if (dataClassName == 'VersionStorage') {
      return deserialize<_i5u6d6t4.VersionStorage>(data['data']);
    }
    if (dataClassName == 'SheetsAiApplyResult') {
      return deserialize<_iuzj1jin.SheetsAiApplyResult>(data['data']);
    }
    if (dataClassName == 'SheetsAiCellRequest') {
      return deserialize<_iljqbz3a.SheetsAiCellRequest>(data['data']);
    }
    if (dataClassName == 'SheetsAiCellResult') {
      return deserialize<_im85lt6z.SheetsAiCellResult>(data['data']);
    }
    if (dataClassName == 'SheetsAiPreview') {
      return deserialize<_i4t3jyqe.SheetsAiPreview>(data['data']);
    }
    if (dataClassName == 'SheetsAiPreviewCall') {
      return deserialize<_idzstekp.SheetsAiPreviewCall>(data['data']);
    }
    if (dataClassName == 'SheetsAiPreviewCell') {
      return deserialize<_i49726iv.SheetsAiPreviewCell>(data['data']);
    }
    if (dataClassName == 'SheetsFillProposal') {
      return deserialize<_izbpavhd.SheetsFillProposal>(data['data']);
    }
    if (dataClassName == 'SheetsFillRow') {
      return deserialize<_i1gi0ui2.SheetsFillRow>(data['data']);
    }
    if (dataClassName == 'SheetsFormulaSuggestion') {
      return deserialize<_i2bhah0l.SheetsFormulaSuggestion>(data['data']);
    }
    if (dataClassName == 'SheetsImportProgress') {
      return deserialize<_iaf43n69.SheetsImportProgress>(data['data']);
    }
    if (dataClassName == 'SheetsImportStatus') {
      return deserialize<_i8d83qca.SheetsImportStatus>(data['data']);
    }
    if (dataClassName == 'CellHistoryEntry') {
      return deserialize<_ij1xvs09.CellHistoryEntry>(data['data']);
    }
    if (dataClassName == 'CellHistoryPage') {
      return deserialize<_i09xo3k8.CellHistoryPage>(data['data']);
    }
    if (dataClassName == 'RevertResult') {
      return deserialize<_ilv3hlxr.RevertResult>(data['data']);
    }
    if (dataClassName == 'RevertSkip') {
      return deserialize<_ipqum05l.RevertSkip>(data['data']);
    }
    if (dataClassName == 'Dimension') {
      return deserialize<_ilnsyzhq.Dimension>(data['data']);
    }
    if (dataClassName == 'EmbeddedObjectKind') {
      return deserialize<_ihfpm0ve.EmbeddedObjectKind>(data['data']);
    }
    if (dataClassName == 'HorizontalAlign') {
      return deserialize<_iofwzekn.HorizontalAlign>(data['data']);
    }
    if (dataClassName == 'RecalcMode') {
      return deserialize<_i0z9m4nl.RecalcMode>(data['data']);
    }
    if (dataClassName == 'ScriptBuildStatus') {
      return deserialize<_io4oc09s.ScriptBuildStatus>(data['data']);
    }
    if (dataClassName == 'SheetKind') {
      return deserialize<_i8ne06ql.SheetKind>(data['data']);
    }
    if (dataClassName == 'TriggerKind') {
      return deserialize<_irmtoho8.TriggerKind>(data['data']);
    }
    if (dataClassName == 'VerticalAlign') {
      return deserialize<_ivf2txqv.VerticalAlign>(data['data']);
    }
    if (dataClassName == 'WrapStrategy') {
      return deserialize<_iz9rjt8b.WrapStrategy>(data['data']);
    }
    if (dataClassName == 'SheetsActivitySummary') {
      return deserialize<_iaehez21.SheetsActivitySummary>(data['data']);
    }
    if (dataClassName == 'SheetsContributorStat') {
      return deserialize<_i9yjzgjk.SheetsContributorStat>(data['data']);
    }
    if (dataClassName == 'ScriptAuthorizationView') {
      return deserialize<_icjzxy6x.ScriptAuthorizationView>(data['data']);
    }
    if (dataClassName == 'ScriptCompileResponse') {
      return deserialize<_iq0xpzf7.ScriptCompileResponse>(data['data']);
    }
    if (dataClassName == 'ScriptExecution') {
      return deserialize<_i4bc0fek.ScriptExecution>(data['data']);
    }
    if (dataClassName == 'ScriptExecutionKind') {
      return deserialize<_inqz9v2t.ScriptExecutionKind>(data['data']);
    }
    if (dataClassName == 'ScriptExecutionStatus') {
      return deserialize<_ira26pfa.ScriptExecutionStatus>(data['data']);
    }
    if (dataClassName == 'ScriptFetchResponse') {
      return deserialize<_is04pxv8.ScriptFetchResponse>(data['data']);
    }
    if (dataClassName == 'ScriptRunResponse') {
      return deserialize<_is0mvar3.ScriptRunResponse>(data['data']);
    }
    if (dataClassName == 'ScriptRuntimeKind') {
      return deserialize<_iy0fj18f.ScriptRuntimeKind>(data['data']);
    }
    if (dataClassName == 'SlidesAiAltText') {
      return deserialize<_iwj0qehd.SlidesAiAltText>(data['data']);
    }
    if (dataClassName == 'SlidesAiApplyResult') {
      return deserialize<_ix6z7bmu.SlidesAiApplyResult>(data['data']);
    }
    if (dataClassName == 'SlidesAiBuildResult') {
      return deserialize<_isdksxfl.SlidesAiBuildResult>(data['data']);
    }
    if (dataClassName == 'SlidesAiDesignRank') {
      return deserialize<_i154xjj9.SlidesAiDesignRank>(data['data']);
    }
    if (dataClassName == 'SlidesAiNote') {
      return deserialize<_itoukaix.SlidesAiNote>(data['data']);
    }
    if (dataClassName == 'SlidesAiOutlineRequest') {
      return deserialize<_i225jf90.SlidesAiOutlineRequest>(data['data']);
    }
    if (dataClassName == 'SlidesAiPreview') {
      return deserialize<_ioipp9xy.SlidesAiPreview>(data['data']);
    }
    if (dataClassName == 'SlidesAiPreviewCall') {
      return deserialize<_iuzye628.SlidesAiPreviewCall>(data['data']);
    }
    if (dataClassName == 'SlidesAiRewriteRequest') {
      return deserialize<_ixaahmd2.SlidesAiRewriteRequest>(data['data']);
    }
    if (dataClassName == 'ChartLinkProbe') {
      return deserialize<_i7q1o3oi.ChartLinkProbe>(data['data']);
    }
    if (dataClassName == 'ChartLinkState') {
      return deserialize<_i3ysrjbx.ChartLinkState>(data['data']);
    }
    if (dataClassName == 'ChartLinkStatus') {
      return deserialize<_is6z3tpy.ChartLinkStatus>(data['data']);
    }
    if (dataClassName == 'ChartSnapshotView') {
      return deserialize<_iua8dx49.ChartSnapshotView>(data['data']);
    }
    if (dataClassName == 'ChartSourceList') {
      return deserialize<_iq1h9id2.ChartSourceList>(data['data']);
    }
    if (dataClassName == 'ChartSourceSummary') {
      return deserialize<_inygrvyi.ChartSourceSummary>(data['data']);
    }
    if (dataClassName == 'BuildKind') {
      return deserialize<_ipok3hcm.BuildKind>(data['data']);
    }
    if (dataClassName == 'BuildTrigger') {
      return deserialize<_isb6wks2.BuildTrigger>(data['data']);
    }
    if (dataClassName == 'DeckAppearance') {
      return deserialize<_isf9v7y6.DeckAppearance>(data['data']);
    }
    if (dataClassName == 'PlaceholderType') {
      return deserialize<_i4oq3vgh.PlaceholderType>(data['data']);
    }
    if (dataClassName == 'SlideElementKind') {
      return deserialize<_isah8148.SlideElementKind>(data['data']);
    }
    if (dataClassName == 'SlideSizePreset') {
      return deserialize<_isghg0k1.SlideSizePreset>(data['data']);
    }
    if (dataClassName == 'TableDimension') {
      return deserialize<_i5m4q7yg.TableDimension>(data['data']);
    }
    if (dataClassName == 'PresentationCommandEvent') {
      return deserialize<_iz9vxb2f.PresentationCommandEvent>(data['data']);
    }
    if (dataClassName == 'PresentationCommandUpdate') {
      return deserialize<_ijdad65m.PresentationCommandUpdate>(data['data']);
    }
    if (dataClassName == 'PresentationEndUpdate') {
      return deserialize<_ijdad65m.PresentationEndUpdate>(data['data']);
    }
    if (dataClassName == 'PresentationEndedEvent') {
      return deserialize<_iz9vxb2f.PresentationEndedEvent>(data['data']);
    }
    if (dataClassName == 'PresentationInkEvent') {
      return deserialize<_iz9vxb2f.PresentationInkEvent>(data['data']);
    }
    if (dataClassName == 'PresentationLaserEvent') {
      return deserialize<_iz9vxb2f.PresentationLaserEvent>(data['data']);
    }
    if (dataClassName == 'PresentationPairingEvent') {
      return deserialize<_iz9vxb2f.PresentationPairingEvent>(data['data']);
    }
    if (dataClassName == 'PresentationPresenterEvent') {
      return deserialize<_iz9vxb2f.PresentationPresenterEvent>(data['data']);
    }
    if (dataClassName == 'PresentationRosterEvent') {
      return deserialize<_iz9vxb2f.PresentationRosterEvent>(data['data']);
    }
    if (dataClassName == 'PresentationStateEvent') {
      return deserialize<_iz9vxb2f.PresentationStateEvent>(data['data']);
    }
    if (dataClassName == 'PresentationWelcome') {
      return deserialize<_iz9vxb2f.PresentationWelcome>(data['data']);
    }
    if (dataClassName == 'PresentationInkUpdate') {
      return deserialize<_ijdad65m.PresentationInkUpdate>(data['data']);
    }
    if (dataClassName == 'PresentationJoin') {
      return deserialize<_ih25cwup.PresentationJoin>(data['data']);
    }
    if (dataClassName == 'PresentationLaserUpdate') {
      return deserialize<_ijdad65m.PresentationLaserUpdate>(data['data']);
    }
    if (dataClassName == 'PresentationPairingTarget') {
      return deserialize<_i6know5x.PresentationPairingTarget>(data['data']);
    }
    if (dataClassName == 'PresentationPairingUpdate') {
      return deserialize<_ijdad65m.PresentationPairingUpdate>(data['data']);
    }
    if (dataClassName == 'PresentationParticipant') {
      return deserialize<_ijgt5qi7.PresentationParticipant>(data['data']);
    }
    if (dataClassName == 'PresentationRole') {
      return deserialize<_i4d7um9r.PresentationRole>(data['data']);
    }
    if (dataClassName == 'PresentationSessionInfo') {
      return deserialize<_ig7ln54r.PresentationSessionInfo>(data['data']);
    }
    if (dataClassName == 'PresentationState') {
      return deserialize<_i95fngt4.PresentationState>(data['data']);
    }
    if (dataClassName == 'PresentationStateUpdate') {
      return deserialize<_ijdad65m.PresentationStateUpdate>(data['data']);
    }
    if (dataClassName == 'DocAck') {
      return deserialize<_icpkpcrn.DocAck>(data['data']);
    }
    if (dataClassName == 'DocCursorUpdate') {
      return deserialize<_imbts8if.DocCursorUpdate>(data['data']);
    }
    if (dataClassName == 'DocHashCheck') {
      return deserialize<_imbts8if.DocHashCheck>(data['data']);
    }
    if (dataClassName == 'DocPing') {
      return deserialize<_imbts8if.DocPing>(data['data']);
    }
    if (dataClassName == 'DocRequestOps') {
      return deserialize<_imbts8if.DocRequestOps>(data['data']);
    }
    if (dataClassName == 'DocSubmitOp') {
      return deserialize<_imbts8if.DocSubmitOp>(data['data']);
    }
    if (dataClassName == 'DocHashResult') {
      return deserialize<_icpkpcrn.DocHashResult>(data['data']);
    }
    if (dataClassName == 'DocInit') {
      return deserialize<_icpkpcrn.DocInit>(data['data']);
    }
    if (dataClassName == 'DocMetaChanged') {
      return deserialize<_icpkpcrn.DocMetaChanged>(data['data']);
    }
    if (dataClassName == 'DocOpRejected') {
      return deserialize<_icpkpcrn.DocOpRejected>(data['data']);
    }
    if (dataClassName == 'DocParticipantJoined') {
      return deserialize<_icpkpcrn.DocParticipantJoined>(data['data']);
    }
    if (dataClassName == 'DocParticipantLeft') {
      return deserialize<_icpkpcrn.DocParticipantLeft>(data['data']);
    }
    if (dataClassName == 'DocPong') {
      return deserialize<_icpkpcrn.DocPong>(data['data']);
    }
    if (dataClassName == 'DocRemoteCursor') {
      return deserialize<_icpkpcrn.DocRemoteCursor>(data['data']);
    }
    if (dataClassName == 'DocRemoteOp') {
      return deserialize<_icpkpcrn.DocRemoteOp>(data['data']);
    }
    if (dataClassName == 'DocRoleChanged') {
      return deserialize<_icpkpcrn.DocRoleChanged>(data['data']);
    }
    if (dataClassName == 'ConvertForInsertResult') {
      return deserialize<_igqu3xcv.ConvertForInsertResult>(data['data']);
    }
    if (dataClassName == 'DocRejectCode') {
      return deserialize<_i5srcd7q.DocRejectCode>(data['data']);
    }
    if (dataClassName == 'Document') {
      return deserialize<_i4sx4pml.Document>(data['data']);
    }
    if (dataClassName == 'DocumentInfo') {
      return deserialize<_iu022vpf.DocumentInfo>(data['data']);
    }
    if (dataClassName == 'DocumentMetaChange') {
      return deserialize<_ir38bcqq.DocumentMetaChange>(data['data']);
    }
    if (dataClassName == 'DocumentMetaPatch') {
      return deserialize<_inkjv0lb.DocumentMetaPatch>(data['data']);
    }
    if (dataClassName == 'DocumentMetaView') {
      return deserialize<_icsyekcn.DocumentMetaView>(data['data']);
    }
    if (dataClassName == 'DocumentOp') {
      return deserialize<_iufsprkx.DocumentOp>(data['data']);
    }
    if (dataClassName == 'DocumentOpKind') {
      return deserialize<_igr6xq1c.DocumentOpKind>(data['data']);
    }
    if (dataClassName == 'DocumentOpView') {
      return deserialize<_issmv319.DocumentOpView>(data['data']);
    }
    if (dataClassName == 'DocumentSnapshot') {
      return deserialize<_i2cnn8i8.DocumentSnapshot>(data['data']);
    }
    if (dataClassName == 'DocumentSnapshotView') {
      return deserialize<_i0cy62lm.DocumentSnapshotView>(data['data']);
    }
    if (dataClassName == 'ExportProgressEvent') {
      return deserialize<_is1ql5wp.ExportProgressEvent>(data['data']);
    }
    if (dataClassName == 'ExportProgressKind') {
      return deserialize<_isdjhzgs.ExportProgressKind>(data['data']);
    }
    if (dataClassName == 'ExportResultView') {
      return deserialize<_if2sngze.ExportResultView>(data['data']);
    }
    if (dataClassName == 'ThemeConflictException') {
      return deserialize<_ittnhawp.ThemeConflictException>(data['data']);
    }
    if (dataClassName == 'WriteDiffAuthor') {
      return deserialize<_ii88i7dv.WriteDiffAuthor>(data['data']);
    }
    if (dataClassName == 'WriteDiffView') {
      return deserialize<_idky93gt.WriteDiffView>(data['data']);
    }
    if (dataClassName == 'WriteTheme') {
      return deserialize<_iynqrh33.WriteTheme>(data['data']);
    }
    if (dataClassName == 'WriteThemeRevision') {
      return deserialize<_i7pbwt05.WriteThemeRevision>(data['data']);
    }
    if (dataClassName == 'WriteThemeRevisionView') {
      return deserialize<_ick3mhj2.WriteThemeRevisionView>(data['data']);
    }
    if (dataClassName == 'WriteThemeView') {
      return deserialize<_ixbjd26z.WriteThemeView>(data['data']);
    }
    if (dataClassName == 'WriteVersionDocument') {
      return deserialize<_is9bkd9t.WriteVersionDocument>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('wonky', this);
    _iacc.Protocol().registerHostProtocol('wonky', this);
  }

  @override
  String getModuleName() => 'wonky';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
