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
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:wonky_server/src/generated/platform/activity/activity_event_view.dart'
    as _iiw0494r;
import 'package:wonky_server/src/generated/platform/ai/models/assistant_thread_view.dart'
    as _i1372x0g;
import 'package:wonky_server/src/generated/platform/board/models/board_bundle_suggestion_view.dart'
    as _i8qikgvy;
import 'package:wonky_server/src/generated/platform/board/models/board_comment_view.dart'
    as _ilh4w69x;
import 'package:wonky_server/src/generated/platform/board/models/board_review_item.dart'
    as _id1usvpt;
import 'package:wonky_server/src/generated/platform/board/models/board_similar_post.dart'
    as _iv1j9wri;
import 'package:wonky_server/src/generated/platform/board/models/board_task_status.dart'
    as _ihypagkt;
import 'package:wonky_server/src/generated/platform/comments/comment_thread_view.dart'
    as _ixzwh8hc;
import 'package:wonky_server/src/generated/platform/drive/drive_item_view.dart'
    as _ily3pmy5;
import 'package:wonky_server/src/generated/platform/drive/template_view.dart'
    as _ibinmr4r;
import 'package:wonky_server/src/generated/platform/files/file_url_view.dart'
    as _i28n3m1r;
import 'package:wonky_server/src/generated/platform/publications/models/publication_delivery_view.dart'
    as _idovycpn;
import 'package:wonky_server/src/generated/platform/publications/models/publication_settings.dart'
    as _i9ilkmgj;
import 'package:wonky_server/src/generated/platform/revlog/models/rev_op_view.dart'
    as _iu7aww0d;
import 'package:wonky_server/src/generated/platform/users/access_token_view.dart'
    as _ioyb7a1p;
import 'package:wonky_server/src/generated/platform/users/user_summary.dart'
    as _i8uuoam6;
import 'package:wonky_server/src/generated/platform/versions/item_version_view.dart'
    as _ir2w0lzm;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_ai_cell_request.dart'
    as _ifqit8uo;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_ai_cell_result.dart'
    as _iq57nmvp;
import 'package:wonky_server/src/generated/sheets/ai/models/sheets_fill_row.dart'
    as _isuyxaqz;
import 'package:wonky_server/src/generated/sheets/scripts/models/script_execution.dart'
    as _isf59hoo;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_alt_text.dart'
    as _iqoob7q4;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_design_rank.dart'
    as _ixtuoo5p;
import 'package:wonky_server/src/generated/slides/ai/models/slides_ai_note.dart'
    as _iug1yx01;
import 'package:wonky_server/src/generated/slides/charts/models/chart_link_probe.dart'
    as _izmhos0v;
import 'package:wonky_server/src/generated/slides/charts/models/chart_link_status.dart'
    as _imx2esrl;
import 'package:wonky_server/src/generated/write/models/document_op_view.dart'
    as _icjb0pei;
import 'package:wonky_server/src/generated/write/models/write_theme_revision_view.dart'
    as _iu3gmhy1;
import 'package:wonky_server/src/generated/write/models/write_theme_view.dart'
    as _ipbzt39t;
import 'future_calls_generated_models/acl_future_call_fan_out_model.dart'
    as _ihl3axv2;
import 'future_calls_generated_models/board_future_call_summarize_model.dart'
    as _icgheary;
import 'future_calls_generated_models/board_future_call_triage_model.dart'
    as _if8h900w;
import 'future_calls_generated_models/board_future_call_write_prompt_model.dart'
    as _ixkvo7h1;
import 'future_calls_generated_models/board_github_future_call_handle_model.dart'
    as _ip0bwzb4;
import 'future_calls_generated_models/board_github_future_call_review_model.dart'
    as _i5z3lvv6;
import 'future_calls_generated_models/file_preview_future_call_generate_model.dart'
    as _ilpvgw0t;
import 'future_calls_generated_models/notification_email_future_call_send_model.dart'
    as _inb6x2l0;
import 'future_calls_generated_models/publications_future_call_deliver_model.dart'
    as _il37cz87;
import 'future_calls_generated_models/storage_future_call_refresh_item_size_model.dart'
    as _io4auc29;
import 'platform/activity/activity_dashboard.dart' as _izr1y672;
import 'platform/activity/activity_event.dart' as _iatdjl5p;
import 'platform/activity/activity_event_view.dart' as _isa7sjzq;
import 'platform/activity/activity_trend_point.dart' as _ighcq381;
import 'platform/activity/activity_type.dart' as _i50cy468;
import 'platform/activity/activity_viewer.dart' as _ikcwdr17;
import 'platform/activity/item_view_day.dart' as _ixdmbuaj;
import 'platform/activity/user_activity_settings.dart' as _ifmsnq1y;
import 'platform/ai/models/ai_apply_mode.dart' as _iyja8k5e;
import 'platform/ai/models/ai_preview_record.dart' as _iuq1eobh;
import 'platform/ai/models/ai_provider.dart' as _ir7z75mb;
import 'platform/ai/models/ai_provider_key_view.dart' as _ic2q2fwi;
import 'platform/ai/models/ai_quality.dart' as _iviyoyk9;
import 'platform/ai/models/ai_usage.dart' as _i7i53on7;
import 'platform/ai/models/ai_user_key.dart' as _ivv7zvxt;
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
import 'platform/analytics/models/analytics_cohort.dart' as _ixradasp;
import 'platform/analytics/models/analytics_count.dart' as _innm1rwe;
import 'platform/analytics/models/analytics_day.dart' as _is2u4stz;
import 'platform/analytics/models/analytics_overview.dart' as _i61uxw4p;
import 'platform/analytics/models/usage_app.dart' as _id3chnrt;
import 'platform/analytics/models/usage_counter_day.dart' as _iamkojeb;
import 'platform/analytics/models/usage_day_stats.dart' as _ibanfcrx;
import 'platform/analytics/models/user_activity_day.dart' as _ik0bapqg;
import 'platform/board/models/board_ai_usage.dart' as _icowsqvh;
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
import 'platform/board/models/board_github_delivery.dart' as _i5r22jl8;
import 'platform/board/models/board_list_query.dart' as _igcoqerx;
import 'platform/board/models/board_me.dart' as _iu9hvv8z;
import 'platform/board/models/board_moderation.dart' as _in0hwjmy;
import 'platform/board/models/board_moderation_action.dart' as _i5jfu168;
import 'platform/board/models/board_moderation_log.dart' as _idxofexa;
import 'platform/board/models/board_post.dart' as _i7xps6dm;
import 'platform/board/models/board_post_draft.dart' as _izvgi5ni;
import 'platform/board/models/board_post_event.dart' as _ibl25moa;
import 'platform/board/models/board_post_kind.dart' as _iui4x9zg;
import 'platform/board/models/board_post_list_item.dart' as _iq3f61ec;
import 'platform/board/models/board_post_page.dart' as _i1stsytz;
import 'platform/board/models/board_post_status.dart' as _il200dga;
import 'platform/board/models/board_post_view.dart' as _ijjd81zg;
import 'platform/board/models/board_pull_request.dart' as _i36hp4a6;
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
import 'platform/cluster/cluster_bus_batch.dart' as _i4piktk8;
import 'platform/cluster/cluster_signal.dart' as _ipkzl9y7;
import 'platform/comments/comment.dart' as _iyixppck;
import 'platform/comments/comment_anchor_kind.dart' as _iw81twtc;
import 'platform/comments/comment_event.dart' as _imlsyj2p;
import 'platform/comments/comment_event_kind.dart' as _ih1mb6x5;
import 'platform/comments/comment_filter.dart' as _il5y6tzr;
import 'platform/comments/comment_signal.dart' as _ix3p7034;
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
import 'platform/drive/drive_change_signal.dart' as _i0atxq9l;
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
import 'platform/feedback/feedback_report.dart' as _iu565i0a;
import 'platform/feedback/feedback_submission.dart' as _ilhpki98;
import 'platform/files/file_upload_ticket.dart' as _irrzp8p9;
import 'platform/files/file_url_view.dart' as _itzt3x6d;
import 'platform/files/image_profile.dart' as _iymtdptb;
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
import 'platform/notifications/notification_signal.dart' as _iqsxdr4a;
import 'platform/notifications/notification_view.dart' as _izfzk9h3;
import 'platform/notifications/user_notification.dart' as _ik59hiyp;
import 'platform/presence/participant.dart' as _iylgyc33;
import 'platform/presence/presence_bus_message.dart' as _i7dp90q0;
import 'platform/presence/presence_event.dart' as _i8r9afjv;
import 'platform/presence/presence_state.dart' as _ik055xb9;
import 'platform/presence/presence_update.dart' as _isz2sju0;
import 'platform/publications/models/publication.dart' as _ikkxb56h;
import 'platform/publications/models/publication_block.dart' as _i5vk42yw;
import 'platform/publications/models/publication_card.dart' as _i9g6l3wu;
import 'platform/publications/models/publication_check_result.dart'
    as _i0a1sw0a;
import 'platform/publications/models/publication_consent.dart' as _iqa48qn0;
import 'platform/publications/models/publication_delivery.dart' as _ihiygfti;
import 'platform/publications/models/publication_delivery_view.dart'
    as _iz1gego0;
import 'platform/publications/models/publication_field_mode.dart' as _iucp51pg;
import 'platform/publications/models/publication_fields.dart' as _i63wbtw0;
import 'platform/publications/models/publication_input.dart' as _iv6bey6s;
import 'platform/publications/models/publication_moderator.dart' as _i1u9dlta;
import 'platform/publications/models/publication_moderator_view.dart'
    as _ij9tsbn9;
import 'platform/publications/models/publication_open_submission.dart'
    as _ivvukfve;
import 'platform/publications/models/publication_secret.dart' as _iyqlj2kr;
import 'platform/publications/models/publication_settings.dart' as _i5i48220;
import 'platform/publications/models/submission.dart' as _ipbg6o7y;
import 'platform/publications/models/submission_asset.dart' as _i49gtkgr;
import 'platform/publications/models/submission_delivery_state.dart'
    as _ip6l83ta;
import 'platform/publications/models/submission_revision.dart' as _i71zy0hy;
import 'platform/publications/models/submission_revision_view.dart'
    as _iegijpud;
import 'platform/publications/models/submission_started.dart' as _ijb8v3k4;
import 'platform/publications/models/submission_status.dart' as _i7hbulg4;
import 'platform/publications/models/submission_values.dart' as _iq9uje8l;
import 'platform/publications/models/submission_view.dart' as _iakndug7;
import 'platform/revlog/messages/rev_client_message.dart' as _i6ck957q;
import 'platform/revlog/messages/rev_server_message.dart' as _ie6clghy;
import 'platform/revlog/models/rev_bus_message.dart' as _iyewfisw;
import 'platform/revlog/models/rev_file.dart' as _ip7h3lg0;
import 'platform/revlog/models/rev_file_info.dart' as _ihwy023l;
import 'platform/revlog/models/rev_file_kind.dart' as _iwkehf4e;
import 'platform/revlog/models/rev_hook_state.dart' as _ivfqwl6l;
import 'platform/revlog/models/rev_op.dart' as _iax01zbg;
import 'platform/revlog/models/rev_op_view.dart' as _it4o2pk5;
import 'platform/revlog/models/rev_page.dart' as _ium7xjeg;
import 'platform/revlog/models/rev_page_kind.dart' as _i3q3ua5p;
import 'platform/revlog/models/rev_page_request.dart' as _if03ikx4;
import 'platform/revlog/models/rev_reject_code.dart' as _iilsyt4b;
import 'platform/revlog/models/server_change_record.dart' as _ibw3povl;
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
import 'platform/storage/storage_reservation.dart' as _if4kaxov;
import 'platform/storage/user_storage.dart' as _is05u0nw;
import 'platform/users/access_token_view.dart' as _izha9j5m;
import 'platform/users/account_deletion_preview.dart' as _iq4dupwy;
import 'platform/users/app_theme_mode.dart' as _i6azdr3n;
import 'platform/users/created_access_token.dart' as _iru4pv75;
import 'platform/users/personal_access_token.dart' as _ijodrcyd;
import 'platform/users/ui_density.dart' as _i5lc4gt0;
import 'platform/users/user_preferences.dart' as _i501u5m5;
import 'platform/users/user_preferences_patch.dart' as _id95rrz2;
import 'platform/users/user_profile.dart' as _ihzl7wbq;
import 'platform/users/user_profile_view.dart' as _iufqmqtc;
import 'platform/users/user_summary.dart' as _i6y7tspy;
import 'platform/versions/item_version.dart' as _i7jb115m;
import 'platform/versions/item_version_state.dart' as _ibe5uno1;
import 'platform/versions/item_version_view.dart' as _ipbapjbz;
import 'platform/versions/version_kind.dart' as _in0fdl1f;
import 'platform/versions/version_restore_result.dart' as _in38zbga;
import 'platform/versions/version_storage.dart' as _i5u6d6t4;
import 'sheets/ai/models/ai_function_cache.dart' as _i5vk0z7t;
import 'sheets/ai/models/sheets_ai_apply_result.dart' as _iuzj1jin;
import 'sheets/ai/models/sheets_ai_cell_request.dart' as _iljqbz3a;
import 'sheets/ai/models/sheets_ai_cell_result.dart' as _im85lt6z;
import 'sheets/ai/models/sheets_ai_preview.dart' as _i4t3jyqe;
import 'sheets/ai/models/sheets_ai_preview_call.dart' as _idzstekp;
import 'sheets/ai/models/sheets_ai_preview_cell.dart' as _i49726iv;
import 'sheets/ai/models/sheets_fill_proposal.dart' as _izbpavhd;
import 'sheets/ai/models/sheets_fill_row.dart' as _i1gi0ui2;
import 'sheets/ai/models/sheets_formula_suggestion.dart' as _i2bhah0l;
import 'sheets/imports/models/sheets_import_job.dart' as _i74ohdg2;
import 'sheets/imports/models/sheets_import_progress.dart' as _iaf43n69;
import 'sheets/imports/models/sheets_import_status.dart' as _i8d83qca;
import 'sheets/models/cell_history.dart' as _ik5lpvx4;
import 'sheets/models/cell_history_entry.dart' as _ij1xvs09;
import 'sheets/models/cell_history_page.dart' as _i09xo3k8;
import 'sheets/models/revert_result.dart' as _ilv3hlxr;
import 'sheets/models/revert_skip.dart' as _ipqum05l;
import 'sheets/models/rows/banding.dart' as _i3p6on16;
import 'sheets/models/rows/basic_filter.dart' as _iofnuqg9;
import 'sheets/models/rows/cell.dart' as _ifc5vn9h;
import 'sheets/models/rows/conditional_format_rule.dart' as _iy4zsn6m;
import 'sheets/models/rows/data_validation_rule.dart' as _i5c2bsv2;
import 'sheets/models/rows/dimension_group.dart' as _i145vl5m;
import 'sheets/models/rows/embedded_object.dart' as _iye9c0co;
import 'sheets/models/rows/enums/dimension.dart' as _ilnsyzhq;
import 'sheets/models/rows/enums/embedded_object_kind.dart' as _ihfpm0ve;
import 'sheets/models/rows/enums/horizontal_align.dart' as _iofwzekn;
import 'sheets/models/rows/enums/recalc_mode.dart' as _i0z9m4nl;
import 'sheets/models/rows/enums/script_build_status.dart' as _io4oc09s;
import 'sheets/models/rows/enums/sheet_kind.dart' as _i8ne06ql;
import 'sheets/models/rows/enums/trigger_kind.dart' as _irmtoho8;
import 'sheets/models/rows/enums/vertical_align.dart' as _ivf2txqv;
import 'sheets/models/rows/enums/wrap_strategy.dart' as _iz9rjt8b;
import 'sheets/models/rows/filter_view.dart' as _igzd7u0m;
import 'sheets/models/rows/macro.dart' as _iiq43rv8;
import 'sheets/models/rows/merged_range.dart' as _i57rr32y;
import 'sheets/models/rows/named_range.dart' as _irrybuvb;
import 'sheets/models/rows/pivot_table.dart' as _iz580og3;
import 'sheets/models/rows/protected_range.dart' as _iz1b7y52;
import 'sheets/models/rows/script_build.dart' as _ibdybin0;
import 'sheets/models/rows/script_file.dart' as _iplsajic;
import 'sheets/models/rows/script_project.dart' as _iy6gs0qh;
import 'sheets/models/rows/script_property.dart' as _ig9hff0r;
import 'sheets/models/rows/script_trigger.dart' as _irlm292d;
import 'sheets/models/rows/sheet.dart' as _i8c5x9aj;
import 'sheets/models/rows/sheet_column.dart' as _i6chd4x2;
import 'sheets/models/rows/sheet_row.dart' as _i4k3x536;
import 'sheets/models/rows/spreadsheet.dart' as _ib6gxu4b;
import 'sheets/models/script_user_property.dart' as _ijtj1mph;
import 'sheets/models/sheets_activity_summary.dart' as _iaehez21;
import 'sheets/models/sheets_contributor_stat.dart' as _i9yjzgjk;
import 'sheets/models/sheets_snapshot_index.dart' as _iwl8v9t3;
import 'sheets/scripts/models/script_authorization.dart' as _ibv2hdjr;
import 'sheets/scripts/models/script_authorization_view.dart' as _icjzxy6x;
import 'sheets/scripts/models/script_compile_response.dart' as _iq0xpzf7;
import 'sheets/scripts/models/script_execution.dart' as _i4bc0fek;
import 'sheets/scripts/models/script_execution_kind.dart' as _inqz9v2t;
import 'sheets/scripts/models/script_execution_status.dart' as _ira26pfa;
import 'sheets/scripts/models/script_fetch_response.dart' as _is04pxv8;
import 'sheets/scripts/models/script_job.dart' as _i4e1yb8z;
import 'sheets/scripts/models/script_quota_usage.dart' as _itn7c5zm;
import 'sheets/scripts/models/script_run_response.dart' as _is0mvar3;
import 'sheets/scripts/models/script_runtime_kind.dart' as _iy0fj18f;
import 'sheets/scripts/models/script_trigger_state.dart' as _ixysij0q;
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
import 'slides/models/rows/chart_link.dart' as _ihkglt8b;
import 'slides/models/rows/code_state.dart' as _i6svv371;
import 'slides/models/rows/deck.dart' as _ioalf2ve;
import 'slides/models/rows/deck_theme.dart' as _i5vaufan;
import 'slides/models/rows/enums/build_kind.dart' as _ipok3hcm;
import 'slides/models/rows/enums/build_trigger.dart' as _isb6wks2;
import 'slides/models/rows/enums/deck_appearance.dart' as _isf9v7y6;
import 'slides/models/rows/enums/placeholder_type.dart' as _i4oq3vgh;
import 'slides/models/rows/enums/slide_element_kind.dart' as _isah8148;
import 'slides/models/rows/enums/slide_size_preset.dart' as _isghg0k1;
import 'slides/models/rows/enums/table_dimension.dart' as _i5m4q7yg;
import 'slides/models/rows/slide.dart' as _ipsr29xb;
import 'slides/models/rows/slide_build.dart' as _izfj14nk;
import 'slides/models/rows/slide_element.dart' as _ih1q77t5;
import 'slides/models/rows/slide_group.dart' as _ic2hhlok;
import 'slides/models/rows/slide_layout.dart' as _i3k3vjpp;
import 'slides/models/rows/slide_master.dart' as _igjrafa0;
import 'slides/models/rows/slide_table_axis.dart' as _iewd9d8j;
import 'slides/models/rows/slide_table_cell.dart' as _ibnoy0fr;
import 'slides/present/models/presentation_bus_message.dart' as _ildgqgkz;
import 'slides/present/models/presentation_event.dart' as _iz9vxb2f;
import 'slides/present/models/presentation_join.dart' as _ih25cwup;
import 'slides/present/models/presentation_pairing_target.dart' as _i6know5x;
import 'slides/present/models/presentation_participant.dart' as _ijgt5qi7;
import 'slides/present/models/presentation_role.dart' as _i4d7um9r;
import 'slides/present/models/presentation_session_info.dart' as _ig7ln54r;
import 'slides/present/models/presentation_state.dart' as _i95fngt4;
import 'slides/present/models/presentation_update.dart' as _ijdad65m;
import 'slides/versions/slides_snapshot_index.dart' as _iy6ry83r;
import 'write/mcp/headless_change.dart' as _iilidizm;
import 'write/messages/doc_bus_message.dart' as _i8zfu67r;
import 'write/messages/doc_client_message.dart' as _imbts8if;
import 'write/messages/doc_server_message.dart' as _icpkpcrn;
import 'write/models/convert_for_insert_result.dart' as _igqu3xcv;
import 'write/models/doc_reject_code.dart' as _i5srcd7q;
import 'write/models/document.dart' as _i4sx4pml;
import 'write/models/document_import_report.dart' as _ixppud51;
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
import 'write/models/write_diff_cache.dart' as _ig4xquf5;
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
export 'platform/activity/item_view_day.dart';
export 'platform/activity/user_activity_settings.dart';
export 'platform/ai/models/ai_apply_mode.dart';
export 'platform/ai/models/ai_preview_record.dart';
export 'platform/ai/models/ai_provider.dart';
export 'platform/ai/models/ai_provider_key_view.dart';
export 'platform/ai/models/ai_quality.dart';
export 'platform/ai/models/ai_usage.dart';
export 'platform/ai/models/ai_user_key.dart';
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
export 'platform/analytics/models/analytics_cohort.dart';
export 'platform/analytics/models/analytics_count.dart';
export 'platform/analytics/models/analytics_day.dart';
export 'platform/analytics/models/analytics_overview.dart';
export 'platform/analytics/models/usage_app.dart';
export 'platform/analytics/models/usage_counter_day.dart';
export 'platform/analytics/models/usage_day_stats.dart';
export 'platform/analytics/models/user_activity_day.dart';
export 'platform/board/models/board_ai_usage.dart';
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
export 'platform/board/models/board_github_delivery.dart';
export 'platform/board/models/board_list_query.dart';
export 'platform/board/models/board_me.dart';
export 'platform/board/models/board_moderation.dart';
export 'platform/board/models/board_moderation_action.dart';
export 'platform/board/models/board_moderation_log.dart';
export 'platform/board/models/board_post.dart';
export 'platform/board/models/board_post_draft.dart';
export 'platform/board/models/board_post_event.dart';
export 'platform/board/models/board_post_kind.dart';
export 'platform/board/models/board_post_list_item.dart';
export 'platform/board/models/board_post_page.dart';
export 'platform/board/models/board_post_status.dart';
export 'platform/board/models/board_post_view.dart';
export 'platform/board/models/board_pull_request.dart';
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
export 'platform/cluster/cluster_bus_batch.dart';
export 'platform/cluster/cluster_signal.dart';
export 'platform/comments/comment.dart';
export 'platform/comments/comment_anchor_kind.dart';
export 'platform/comments/comment_event.dart';
export 'platform/comments/comment_event_kind.dart';
export 'platform/comments/comment_filter.dart';
export 'platform/comments/comment_signal.dart';
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
export 'platform/drive/drive_change_signal.dart';
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
export 'platform/feedback/feedback_report.dart';
export 'platform/feedback/feedback_submission.dart';
export 'platform/files/file_upload_ticket.dart';
export 'platform/files/file_url_view.dart';
export 'platform/files/image_profile.dart';
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
export 'platform/notifications/notification_signal.dart';
export 'platform/notifications/notification_view.dart';
export 'platform/notifications/user_notification.dart';
export 'platform/presence/participant.dart';
export 'platform/presence/presence_bus_message.dart';
export 'platform/presence/presence_event.dart';
export 'platform/presence/presence_state.dart';
export 'platform/presence/presence_update.dart';
export 'platform/publications/models/publication.dart';
export 'platform/publications/models/publication_block.dart';
export 'platform/publications/models/publication_card.dart';
export 'platform/publications/models/publication_check_result.dart';
export 'platform/publications/models/publication_consent.dart';
export 'platform/publications/models/publication_delivery.dart';
export 'platform/publications/models/publication_delivery_view.dart';
export 'platform/publications/models/publication_field_mode.dart';
export 'platform/publications/models/publication_fields.dart';
export 'platform/publications/models/publication_input.dart';
export 'platform/publications/models/publication_moderator.dart';
export 'platform/publications/models/publication_moderator_view.dart';
export 'platform/publications/models/publication_open_submission.dart';
export 'platform/publications/models/publication_secret.dart';
export 'platform/publications/models/publication_settings.dart';
export 'platform/publications/models/submission.dart';
export 'platform/publications/models/submission_asset.dart';
export 'platform/publications/models/submission_delivery_state.dart';
export 'platform/publications/models/submission_revision.dart';
export 'platform/publications/models/submission_revision_view.dart';
export 'platform/publications/models/submission_started.dart';
export 'platform/publications/models/submission_status.dart';
export 'platform/publications/models/submission_values.dart';
export 'platform/publications/models/submission_view.dart';
export 'platform/revlog/messages/rev_client_message.dart';
export 'platform/revlog/messages/rev_server_message.dart';
export 'platform/revlog/models/rev_bus_message.dart';
export 'platform/revlog/models/rev_file.dart';
export 'platform/revlog/models/rev_file_info.dart';
export 'platform/revlog/models/rev_file_kind.dart';
export 'platform/revlog/models/rev_hook_state.dart';
export 'platform/revlog/models/rev_op.dart';
export 'platform/revlog/models/rev_op_view.dart';
export 'platform/revlog/models/rev_page.dart';
export 'platform/revlog/models/rev_page_kind.dart';
export 'platform/revlog/models/rev_page_request.dart';
export 'platform/revlog/models/rev_reject_code.dart';
export 'platform/revlog/models/server_change_record.dart';
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
export 'platform/storage/storage_reservation.dart';
export 'platform/storage/user_storage.dart';
export 'platform/users/access_token_view.dart';
export 'platform/users/account_deletion_preview.dart';
export 'platform/users/app_theme_mode.dart';
export 'platform/users/created_access_token.dart';
export 'platform/users/personal_access_token.dart';
export 'platform/users/ui_density.dart';
export 'platform/users/user_preferences.dart';
export 'platform/users/user_preferences_patch.dart';
export 'platform/users/user_profile.dart';
export 'platform/users/user_profile_view.dart';
export 'platform/users/user_summary.dart';
export 'platform/versions/item_version.dart';
export 'platform/versions/item_version_state.dart';
export 'platform/versions/item_version_view.dart';
export 'platform/versions/version_kind.dart';
export 'platform/versions/version_restore_result.dart';
export 'platform/versions/version_storage.dart';
export 'sheets/ai/models/ai_function_cache.dart';
export 'sheets/ai/models/sheets_ai_apply_result.dart';
export 'sheets/ai/models/sheets_ai_cell_request.dart';
export 'sheets/ai/models/sheets_ai_cell_result.dart';
export 'sheets/ai/models/sheets_ai_preview.dart';
export 'sheets/ai/models/sheets_ai_preview_call.dart';
export 'sheets/ai/models/sheets_ai_preview_cell.dart';
export 'sheets/ai/models/sheets_fill_proposal.dart';
export 'sheets/ai/models/sheets_fill_row.dart';
export 'sheets/ai/models/sheets_formula_suggestion.dart';
export 'sheets/imports/models/sheets_import_job.dart';
export 'sheets/imports/models/sheets_import_progress.dart';
export 'sheets/imports/models/sheets_import_status.dart';
export 'sheets/models/cell_history.dart';
export 'sheets/models/cell_history_entry.dart';
export 'sheets/models/cell_history_page.dart';
export 'sheets/models/revert_result.dart';
export 'sheets/models/revert_skip.dart';
export 'sheets/models/rows/banding.dart';
export 'sheets/models/rows/basic_filter.dart';
export 'sheets/models/rows/cell.dart';
export 'sheets/models/rows/conditional_format_rule.dart';
export 'sheets/models/rows/data_validation_rule.dart';
export 'sheets/models/rows/dimension_group.dart';
export 'sheets/models/rows/embedded_object.dart';
export 'sheets/models/rows/enums/dimension.dart';
export 'sheets/models/rows/enums/embedded_object_kind.dart';
export 'sheets/models/rows/enums/horizontal_align.dart';
export 'sheets/models/rows/enums/recalc_mode.dart';
export 'sheets/models/rows/enums/script_build_status.dart';
export 'sheets/models/rows/enums/sheet_kind.dart';
export 'sheets/models/rows/enums/trigger_kind.dart';
export 'sheets/models/rows/enums/vertical_align.dart';
export 'sheets/models/rows/enums/wrap_strategy.dart';
export 'sheets/models/rows/filter_view.dart';
export 'sheets/models/rows/macro.dart';
export 'sheets/models/rows/merged_range.dart';
export 'sheets/models/rows/named_range.dart';
export 'sheets/models/rows/pivot_table.dart';
export 'sheets/models/rows/protected_range.dart';
export 'sheets/models/rows/script_build.dart';
export 'sheets/models/rows/script_file.dart';
export 'sheets/models/rows/script_project.dart';
export 'sheets/models/rows/script_property.dart';
export 'sheets/models/rows/script_trigger.dart';
export 'sheets/models/rows/sheet.dart';
export 'sheets/models/rows/sheet_column.dart';
export 'sheets/models/rows/sheet_row.dart';
export 'sheets/models/rows/spreadsheet.dart';
export 'sheets/models/script_user_property.dart';
export 'sheets/models/sheets_activity_summary.dart';
export 'sheets/models/sheets_contributor_stat.dart';
export 'sheets/models/sheets_snapshot_index.dart';
export 'sheets/scripts/models/script_authorization.dart';
export 'sheets/scripts/models/script_authorization_view.dart';
export 'sheets/scripts/models/script_compile_response.dart';
export 'sheets/scripts/models/script_execution.dart';
export 'sheets/scripts/models/script_execution_kind.dart';
export 'sheets/scripts/models/script_execution_status.dart';
export 'sheets/scripts/models/script_fetch_response.dart';
export 'sheets/scripts/models/script_job.dart';
export 'sheets/scripts/models/script_quota_usage.dart';
export 'sheets/scripts/models/script_run_response.dart';
export 'sheets/scripts/models/script_runtime_kind.dart';
export 'sheets/scripts/models/script_trigger_state.dart';
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
export 'slides/models/rows/chart_link.dart';
export 'slides/models/rows/code_state.dart';
export 'slides/models/rows/deck.dart';
export 'slides/models/rows/deck_theme.dart';
export 'slides/models/rows/enums/build_kind.dart';
export 'slides/models/rows/enums/build_trigger.dart';
export 'slides/models/rows/enums/deck_appearance.dart';
export 'slides/models/rows/enums/placeholder_type.dart';
export 'slides/models/rows/enums/slide_element_kind.dart';
export 'slides/models/rows/enums/slide_size_preset.dart';
export 'slides/models/rows/enums/table_dimension.dart';
export 'slides/models/rows/slide.dart';
export 'slides/models/rows/slide_build.dart';
export 'slides/models/rows/slide_element.dart';
export 'slides/models/rows/slide_group.dart';
export 'slides/models/rows/slide_layout.dart';
export 'slides/models/rows/slide_master.dart';
export 'slides/models/rows/slide_table_axis.dart';
export 'slides/models/rows/slide_table_cell.dart';
export 'slides/present/models/presentation_bus_message.dart';
export 'slides/present/models/presentation_event.dart';
export 'slides/present/models/presentation_join.dart';
export 'slides/present/models/presentation_pairing_target.dart';
export 'slides/present/models/presentation_participant.dart';
export 'slides/present/models/presentation_role.dart';
export 'slides/present/models/presentation_session_info.dart';
export 'slides/present/models/presentation_state.dart';
export 'slides/present/models/presentation_update.dart';
export 'slides/versions/slides_snapshot_index.dart';
export 'write/mcp/headless_change.dart';
export 'write/messages/doc_bus_message.dart';
export 'write/messages/doc_client_message.dart';
export 'write/messages/doc_server_message.dart';
export 'write/models/convert_for_insert_result.dart';
export 'write/models/doc_reject_code.dart';
export 'write/models/document.dart';
export 'write/models/document_import_report.dart';
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
export 'write/models/write_diff_cache.dart';
export 'write/models/write_diff_view.dart';
export 'write/models/write_theme.dart';
export 'write/models/write_theme_revision.dart';
export 'write/models/write_theme_revision_view.dart';
export 'write/models/write_theme_view.dart';
export 'write/models/write_version_document.dart';

class Protocol extends _is.DatabaseSerializationManager
    implements _is.DatabaseProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _is.ProtocolDeserialization get deserializationMetadata =>
      _is.ProtocolDeserialization.cached(
        this,
        types: const [
          _is.getType<_ihl3axv2.AclFutureCallFanOutModel>,
          _is.getType<_icgheary.BoardFutureCallSummarizeModel>,
          _is.getType<_if8h900w.BoardFutureCallTriageModel>,
          _is.getType<_ixkvo7h1.BoardFutureCallWritePromptModel>,
          _is.getType<_ip0bwzb4.BoardGithubFutureCallHandleModel>,
          _is.getType<_i5z3lvv6.BoardGithubFutureCallReviewModel>,
          _is.getType<_ilpvgw0t.FilePreviewFutureCallGenerateModel>,
          _is.getType<_inb6x2l0.NotificationEmailFutureCallSendModel>,
          _is.getType<_il37cz87.PublicationsFutureCallDeliverModel>,
          _is.getType<_io4auc29.StorageFutureCallRefreshItemSizeModel>,
          _is.getType<_izr1y672.ActivityDashboard>,
          _is.getType<_iatdjl5p.ActivityEvent>,
          _is.getType<_isa7sjzq.ActivityEventView>,
          _is.getType<_ighcq381.ActivityTrendPoint>,
          _is.getType<_i50cy468.ActivityType>,
          _is.getType<_ikcwdr17.ActivityViewer>,
          _is.getType<_ixdmbuaj.ItemViewDay>,
          _is.getType<_ifmsnq1y.UserActivitySettings>,
          _is.getType<_iyja8k5e.AiApplyMode>,
          _is.getType<_iuq1eobh.AiPreviewRecord>,
          _is.getType<_ir7z75mb.AiProvider>,
          _is.getType<_ic2q2fwi.AiProviderKeyView>,
          _is.getType<_iviyoyk9.AiQuality>,
          _is.getType<_i7i53on7.AiUsage>,
          _is.getType<_ivv7zvxt.AiUserKey>,
          _is.getType<_imx2nn1q.AiUserSetting>,
          _is.getType<_ic7e83wd.AssistantContextHints>,
          _is.getType<_imp4tsxo.AssistantEvent>,
          _is.getType<_id6kvqt9.AssistantEventType>,
          _is.getType<_i8cittxq.AssistantMessage>,
          _is.getType<_i4rkdm2k.AssistantMessageView>,
          _is.getType<_ia2m3j3v.AssistantStatus>,
          _is.getType<_iaq6rutx.AssistantThread>,
          _is.getType<_i4iv0swm.AssistantThreadDetail>,
          _is.getType<_iohdfqf1.AssistantThreadView>,
          _is.getType<_i8ghcs7p.InlineAiEvent>,
          _is.getType<_i6pcz5z6.InlineAiEventType>,
          _is.getType<_i4m43iwr.InlineAiRequest>,
          _is.getType<_ie0jt2ne.ProofreadEvent>,
          _is.getType<_ivmxemza.ProofreadIssue>,
          _is.getType<_ixradasp.AnalyticsCohort>,
          _is.getType<_innm1rwe.AnalyticsCount>,
          _is.getType<_is2u4stz.AnalyticsDay>,
          _is.getType<_i61uxw4p.AnalyticsOverview>,
          _is.getType<_id3chnrt.UsageApp>,
          _is.getType<_iamkojeb.UsageCounterDay>,
          _is.getType<_ibanfcrx.UsageDayStats>,
          _is.getType<_ik0bapqg.UserActivityDay>,
          _is.getType<_icowsqvh.BoardAiUsage>,
          _is.getType<_i0ag0upm.BoardArea>,
          _is.getType<_ika8r7fc.BoardAuthor>,
          _is.getType<_ilo15wk2.BoardBundleSuggestion>,
          _is.getType<_iin47lv0.BoardBundleSuggestionView>,
          _is.getType<_ijz5flk6.BoardComment>,
          _is.getType<_ipkjmsg5.BoardCommentView>,
          _is.getType<_iswbp1jv.BoardCounts>,
          _is.getType<_ita8snxr.BoardEventKind>,
          _is.getType<_i0y7d0xd.BoardFlag>,
          _is.getType<_iwc3b6vo.BoardFlagReason>,
          _is.getType<_i5pjfe5s.BoardFlagView>,
          _is.getType<_i5r22jl8.BoardGithubDelivery>,
          _is.getType<_igcoqerx.BoardListQuery>,
          _is.getType<_iu9hvv8z.BoardMe>,
          _is.getType<_in0hwjmy.BoardModeration>,
          _is.getType<_i5jfu168.BoardModerationAction>,
          _is.getType<_idxofexa.BoardModerationLog>,
          _is.getType<_i7xps6dm.BoardPost>,
          _is.getType<_izvgi5ni.BoardPostDraft>,
          _is.getType<_ibl25moa.BoardPostEvent>,
          _is.getType<_iui4x9zg.BoardPostKind>,
          _is.getType<_iq3f61ec.BoardPostListItem>,
          _is.getType<_i1stsytz.BoardPostPage>,
          _is.getType<_il200dga.BoardPostStatus>,
          _is.getType<_ijjd81zg.BoardPostView>,
          _is.getType<_i36hp4a6.BoardPullRequest>,
          _is.getType<_im7v2irk.BoardReviewCounts>,
          _is.getType<_id33cro1.BoardReviewItem>,
          _is.getType<_izs2n8vy.BoardReviewSection>,
          _is.getType<_ieemxbgb.BoardSignal>,
          _is.getType<_in3cjdcj.BoardSimilarPost>,
          _is.getType<_ivbgicm7.BoardSize>,
          _is.getType<_itz4727j.BoardSort>,
          _is.getType<_i2gir90g.BoardTargetKind>,
          _is.getType<_iv26y3a1.BoardTask>,
          _is.getType<_illpt7x2.BoardTaskPage>,
          _is.getType<_idsjzf6h.BoardTaskRef>,
          _is.getType<_i4a2ekwp.BoardTaskStatus>,
          _is.getType<_ifz7dmuf.BoardTaskView>,
          _is.getType<_iso7mdvm.BoardTriageState>,
          _is.getType<_i516sz1w.BoardUserProfile>,
          _is.getType<_ifuo09i6.BoardVote>,
          _is.getType<_ie24iiog.BoardVoteResult>,
          _is.getType<_i4piktk8.ClusterBusBatch>,
          _is.getType<_ipkzl9y7.ClusterSignal>,
          _is.getType<_iyixppck.Comment>,
          _is.getType<_iw81twtc.CommentAnchorKind>,
          _is.getType<_imlsyj2p.CommentEvent>,
          _is.getType<_ih1mb6x5.CommentEventKind>,
          _is.getType<_il5y6tzr.CommentFilter>,
          _is.getType<_ix3p7034.CommentSignal>,
          _is.getType<_iowdswxe.CommentStatus>,
          _is.getType<_i94wr3td.CommentSystemEvent>,
          _is.getType<_ijog60vm.CommentThread>,
          _is.getType<_i818olql.CommentThreadView>,
          _is.getType<_i4xrxro7.CommentView>,
          _is.getType<_ii98prcs.AccessRole>,
          _is.getType<_i2wc4tyi.ActorKind>,
          _is.getType<_inb0isem.WonkyErrorCode>,
          _is.getType<_igdswlrw.WonkyException>,
          _is.getType<_iktwt5zz.DriveChange>,
          _is.getType<_ijoqbs82.DriveChangeKind>,
          _is.getType<_i0atxq9l.DriveChangeSignal>,
          _is.getType<_ig2nixhn.DriveImportOptions>,
          _is.getType<_inge8yy2.DriveItem>,
          _is.getType<_i8mh39wa.DriveItemKind>,
          _is.getType<_i0g2m831.DriveItemUserState>,
          _is.getType<_infxyf98.DriveItemView>,
          _is.getType<_ivypvw0m.DriveListFilter>,
          _is.getType<_iavdhzsq.DriveListPage>,
          _is.getType<_if1dhg5z.DriveOwnerFilter>,
          _is.getType<_i6k3d1nc.DriveSearchFilters>,
          _is.getType<_iu13r4v2.DriveSort>,
          _is.getType<_ix0g8yw4.DriveSortField>,
          _is.getType<_ipww3kqy.DriveView>,
          _is.getType<_iez45i4u.FileCategory>,
          _is.getType<_ilt75p4e.FileUploadProgress>,
          _is.getType<_iqpb2qv1.FileUploadRequest>,
          _is.getType<_imf3tnfq.FileUploadStart>,
          _is.getType<_ia04wt6m.FileUploadState>,
          _is.getType<_i68yhxa0.ImportReportView>,
          _is.getType<_i48sm9f2.ImportWarningView>,
          _is.getType<_i8hnug6t.StorageListFilter>,
          _is.getType<_i26hsnhw.StorageUsage>,
          _is.getType<_iiedu4vz.TemplateCategory>,
          _is.getType<_i6rg3vdh.TemplatePreviewStyle>,
          _is.getType<_i2ox7ta1.TemplateView>,
          _is.getType<_io3ccr8w.UploadConflictMode>,
          _is.getType<_iv1sk0e8.FeedbackKind>,
          _is.getType<_iu565i0a.FeedbackReport>,
          _is.getType<_ilhpki98.FeedbackSubmission>,
          _is.getType<_irrzp8p9.FileUploadTicket>,
          _is.getType<_itzt3x6d.FileUrlView>,
          _is.getType<_iymtdptb.ImageProfile>,
          _is.getType<_im8eh74x.StoredFile>,
          _is.getType<_i45dmz4a.StoredFileKind>,
          _is.getType<_ik7q11oy.StoredFileStatus>,
          _is.getType<_ichw8k0i.UiBridgeCancel>,
          _is.getType<_ichw8k0i.UiBridgeHello>,
          _is.getType<_ichw8k0i.UiBridgeRequest>,
          _is.getType<_ichw8k0i.UiBridgeResponse>,
          _is.getType<_ichw8k0i.UiBridgeStatus>,
          _is.getType<_ichw8k0i.UiBridgeStop>,
          _is.getType<_ichw8k0i.UiBridgeWelcome>,
          _is.getType<_ivk6eyvx.FeatureFlags>,
          _is.getType<_ib575x0y.ProtocolInfo>,
          _is.getType<_i28el0at.ServerLimits>,
          _is.getType<_iexg4yzt.NotificationEvent>,
          _is.getType<_iqlnbbfp.NotificationKind>,
          _is.getType<_i3r1eo8q.NotificationPage>,
          _is.getType<_iqsxdr4a.NotificationSignal>,
          _is.getType<_izfzk9h3.NotificationView>,
          _is.getType<_ik59hiyp.UserNotification>,
          _is.getType<_iylgyc33.Participant>,
          _is.getType<_i7dp90q0.PresenceBusMessage>,
          _is.getType<_i8r9afjv.PresenceFollowerCount>,
          _is.getType<_i8r9afjv.PresenceHints>,
          _is.getType<_i8r9afjv.PresenceJoined>,
          _is.getType<_i8r9afjv.PresenceLeft>,
          _is.getType<_i8r9afjv.PresenceNotice>,
          _is.getType<_i8r9afjv.PresenceRoster>,
          _is.getType<_i8r9afjv.PresenceUpdated>,
          _is.getType<_ik055xb9.PresenceState>,
          _is.getType<_isz2sju0.PresenceUpdate>,
          _is.getType<_ikkxb56h.Publication>,
          _is.getType<_i5vk42yw.PublicationBlock>,
          _is.getType<_i9g6l3wu.PublicationCard>,
          _is.getType<_i0a1sw0a.PublicationCheckResult>,
          _is.getType<_iqa48qn0.PublicationConsent>,
          _is.getType<_ihiygfti.PublicationDelivery>,
          _is.getType<_iz1gego0.PublicationDeliveryView>,
          _is.getType<_iucp51pg.PublicationFieldMode>,
          _is.getType<_i63wbtw0.PublicationFields>,
          _is.getType<_iv6bey6s.PublicationInput>,
          _is.getType<_i1u9dlta.PublicationModerator>,
          _is.getType<_ij9tsbn9.PublicationModeratorView>,
          _is.getType<_ivvukfve.PublicationOpenSubmission>,
          _is.getType<_iyqlj2kr.PublicationSecret>,
          _is.getType<_i5i48220.PublicationSettings>,
          _is.getType<_ipbg6o7y.Submission>,
          _is.getType<_i49gtkgr.SubmissionAsset>,
          _is.getType<_ip6l83ta.SubmissionDeliveryState>,
          _is.getType<_i71zy0hy.SubmissionRevision>,
          _is.getType<_iegijpud.SubmissionRevisionView>,
          _is.getType<_ijb8v3k4.SubmissionStarted>,
          _is.getType<_i7hbulg4.SubmissionStatus>,
          _is.getType<_iq9uje8l.SubmissionValues>,
          _is.getType<_iakndug7.SubmissionView>,
          _is.getType<_ie6clghy.RevAck>,
          _is.getType<_i6ck957q.RevPing>,
          _is.getType<_i6ck957q.RevRequestOps>,
          _is.getType<_i6ck957q.RevSubmit>,
          _is.getType<_ie6clghy.RevInit>,
          _is.getType<_ie6clghy.RevPong>,
          _is.getType<_ie6clghy.RevRejected>,
          _is.getType<_ie6clghy.RevRemoteOp>,
          _is.getType<_ie6clghy.RevResync>,
          _is.getType<_ie6clghy.RevRoleChanged>,
          _is.getType<_iyewfisw.RevBusMessage>,
          _is.getType<_ip7h3lg0.RevFile>,
          _is.getType<_ihwy023l.RevFileInfo>,
          _is.getType<_iwkehf4e.RevFileKind>,
          _is.getType<_ivfqwl6l.RevHookState>,
          _is.getType<_iax01zbg.RevOp>,
          _is.getType<_it4o2pk5.RevOpView>,
          _is.getType<_ium7xjeg.RevPage>,
          _is.getType<_i3q3ua5p.RevPageKind>,
          _is.getType<_if03ikx4.RevPageRequest>,
          _is.getType<_iilsyt4b.RevRejectCode>,
          _is.getType<_ibw3povl.ServerChangeRecord>,
          _is.getType<_i8scn8dm.AccessRequest>,
          _is.getType<_i7trut12.AccessRequestOutcome>,
          _is.getType<_iimp60a4.AccessRequestView>,
          _is.getType<_iuzgacy4.DriveItemPermission>,
          _is.getType<_ikeljole.InviteResolution>,
          _is.getType<_ih3711er.ItemSharingSettings>,
          _is.getType<_ijwxtu30.OwnershipTransfer>,
          _is.getType<_iilpsf9g.OwnershipTransferView>,
          _is.getType<_iead0ok9.PermissionView>,
          _is.getType<_it712lg1.ShareLink>,
          _is.getType<_iw2xoohn.ShareLinkView>,
          _is.getType<_itd24os1.SharingInfo>,
          _is.getType<_ifxa4vxf.QuotaExceededDetails>,
          _is.getType<_if4kaxov.StorageReservation>,
          _is.getType<_is05u0nw.UserStorage>,
          _is.getType<_izha9j5m.AccessTokenView>,
          _is.getType<_iq4dupwy.AccountDeletionPreview>,
          _is.getType<_i6azdr3n.AppThemeMode>,
          _is.getType<_iru4pv75.CreatedAccessToken>,
          _is.getType<_ijodrcyd.PersonalAccessToken>,
          _is.getType<_i5lc4gt0.UiDensity>,
          _is.getType<_i501u5m5.UserPreferences>,
          _is.getType<_id95rrz2.UserPreferencesPatch>,
          _is.getType<_ihzl7wbq.UserProfile>,
          _is.getType<_iufqmqtc.UserProfileView>,
          _is.getType<_i6y7tspy.UserSummary>,
          _is.getType<_i7jb115m.ItemVersion>,
          _is.getType<_ibe5uno1.ItemVersionState>,
          _is.getType<_ipbapjbz.ItemVersionView>,
          _is.getType<_in0fdl1f.VersionKind>,
          _is.getType<_in38zbga.VersionRestoreResult>,
          _is.getType<_i5u6d6t4.VersionStorage>,
          _is.getType<_i5vk0z7t.AiFunctionCache>,
          _is.getType<_iuzj1jin.SheetsAiApplyResult>,
          _is.getType<_iljqbz3a.SheetsAiCellRequest>,
          _is.getType<_im85lt6z.SheetsAiCellResult>,
          _is.getType<_i4t3jyqe.SheetsAiPreview>,
          _is.getType<_idzstekp.SheetsAiPreviewCall>,
          _is.getType<_i49726iv.SheetsAiPreviewCell>,
          _is.getType<_izbpavhd.SheetsFillProposal>,
          _is.getType<_i1gi0ui2.SheetsFillRow>,
          _is.getType<_i2bhah0l.SheetsFormulaSuggestion>,
          _is.getType<_i74ohdg2.SheetsImportJob>,
          _is.getType<_iaf43n69.SheetsImportProgress>,
          _is.getType<_i8d83qca.SheetsImportStatus>,
          _is.getType<_ik5lpvx4.CellHistory>,
          _is.getType<_ij1xvs09.CellHistoryEntry>,
          _is.getType<_i09xo3k8.CellHistoryPage>,
          _is.getType<_ilv3hlxr.RevertResult>,
          _is.getType<_ipqum05l.RevertSkip>,
          _is.getType<_i3p6on16.Banding>,
          _is.getType<_iofnuqg9.BasicFilter>,
          _is.getType<_ifc5vn9h.Cell>,
          _is.getType<_iy4zsn6m.ConditionalFormatRule>,
          _is.getType<_i5c2bsv2.DataValidationRule>,
          _is.getType<_i145vl5m.DimensionGroup>,
          _is.getType<_iye9c0co.EmbeddedObject>,
          _is.getType<_ilnsyzhq.Dimension>,
          _is.getType<_ihfpm0ve.EmbeddedObjectKind>,
          _is.getType<_iofwzekn.HorizontalAlign>,
          _is.getType<_i0z9m4nl.RecalcMode>,
          _is.getType<_io4oc09s.ScriptBuildStatus>,
          _is.getType<_i8ne06ql.SheetKind>,
          _is.getType<_irmtoho8.TriggerKind>,
          _is.getType<_ivf2txqv.VerticalAlign>,
          _is.getType<_iz9rjt8b.WrapStrategy>,
          _is.getType<_igzd7u0m.FilterView>,
          _is.getType<_iiq43rv8.Macro>,
          _is.getType<_i57rr32y.MergedRange>,
          _is.getType<_irrybuvb.NamedRange>,
          _is.getType<_iz580og3.PivotTable>,
          _is.getType<_iz1b7y52.ProtectedRange>,
          _is.getType<_ibdybin0.ScriptBuild>,
          _is.getType<_iplsajic.ScriptFile>,
          _is.getType<_iy6gs0qh.ScriptProject>,
          _is.getType<_ig9hff0r.ScriptProperty>,
          _is.getType<_irlm292d.ScriptTrigger>,
          _is.getType<_i8c5x9aj.Sheet>,
          _is.getType<_i6chd4x2.SheetColumn>,
          _is.getType<_i4k3x536.SheetRow>,
          _is.getType<_ib6gxu4b.Spreadsheet>,
          _is.getType<_ijtj1mph.ScriptUserProperty>,
          _is.getType<_iaehez21.SheetsActivitySummary>,
          _is.getType<_i9yjzgjk.SheetsContributorStat>,
          _is.getType<_iwl8v9t3.SheetsSnapshotIndex>,
          _is.getType<_ibv2hdjr.ScriptAuthorization>,
          _is.getType<_icjzxy6x.ScriptAuthorizationView>,
          _is.getType<_iq0xpzf7.ScriptCompileResponse>,
          _is.getType<_i4bc0fek.ScriptExecution>,
          _is.getType<_inqz9v2t.ScriptExecutionKind>,
          _is.getType<_ira26pfa.ScriptExecutionStatus>,
          _is.getType<_is04pxv8.ScriptFetchResponse>,
          _is.getType<_i4e1yb8z.ScriptJob>,
          _is.getType<_itn7c5zm.ScriptQuotaUsage>,
          _is.getType<_is0mvar3.ScriptRunResponse>,
          _is.getType<_iy0fj18f.ScriptRuntimeKind>,
          _is.getType<_ixysij0q.ScriptTriggerState>,
          _is.getType<_iwj0qehd.SlidesAiAltText>,
          _is.getType<_ix6z7bmu.SlidesAiApplyResult>,
          _is.getType<_isdksxfl.SlidesAiBuildResult>,
          _is.getType<_i154xjj9.SlidesAiDesignRank>,
          _is.getType<_itoukaix.SlidesAiNote>,
          _is.getType<_i225jf90.SlidesAiOutlineRequest>,
          _is.getType<_ioipp9xy.SlidesAiPreview>,
          _is.getType<_iuzye628.SlidesAiPreviewCall>,
          _is.getType<_ixaahmd2.SlidesAiRewriteRequest>,
          _is.getType<_i7q1o3oi.ChartLinkProbe>,
          _is.getType<_i3ysrjbx.ChartLinkState>,
          _is.getType<_is6z3tpy.ChartLinkStatus>,
          _is.getType<_iua8dx49.ChartSnapshotView>,
          _is.getType<_iq1h9id2.ChartSourceList>,
          _is.getType<_inygrvyi.ChartSourceSummary>,
          _is.getType<_ihkglt8b.ChartLink>,
          _is.getType<_i6svv371.CodeState>,
          _is.getType<_ioalf2ve.Deck>,
          _is.getType<_i5vaufan.DeckTheme>,
          _is.getType<_ipok3hcm.BuildKind>,
          _is.getType<_isb6wks2.BuildTrigger>,
          _is.getType<_isf9v7y6.DeckAppearance>,
          _is.getType<_i4oq3vgh.PlaceholderType>,
          _is.getType<_isah8148.SlideElementKind>,
          _is.getType<_isghg0k1.SlideSizePreset>,
          _is.getType<_i5m4q7yg.TableDimension>,
          _is.getType<_ipsr29xb.Slide>,
          _is.getType<_izfj14nk.SlideBuild>,
          _is.getType<_ih1q77t5.SlideElement>,
          _is.getType<_ic2hhlok.SlideGroup>,
          _is.getType<_i3k3vjpp.SlideLayout>,
          _is.getType<_igjrafa0.SlideMaster>,
          _is.getType<_iewd9d8j.SlideTableAxis>,
          _is.getType<_ibnoy0fr.SlideTableCell>,
          _is.getType<_ildgqgkz.PresentationBusMessage>,
          _is.getType<_iz9vxb2f.PresentationCommandEvent>,
          _is.getType<_ijdad65m.PresentationCommandUpdate>,
          _is.getType<_ijdad65m.PresentationEndUpdate>,
          _is.getType<_iz9vxb2f.PresentationEndedEvent>,
          _is.getType<_iz9vxb2f.PresentationInkEvent>,
          _is.getType<_iz9vxb2f.PresentationLaserEvent>,
          _is.getType<_iz9vxb2f.PresentationPairingEvent>,
          _is.getType<_iz9vxb2f.PresentationPresenterEvent>,
          _is.getType<_iz9vxb2f.PresentationRosterEvent>,
          _is.getType<_iz9vxb2f.PresentationStateEvent>,
          _is.getType<_iz9vxb2f.PresentationWelcome>,
          _is.getType<_ijdad65m.PresentationInkUpdate>,
          _is.getType<_ih25cwup.PresentationJoin>,
          _is.getType<_ijdad65m.PresentationLaserUpdate>,
          _is.getType<_i6know5x.PresentationPairingTarget>,
          _is.getType<_ijdad65m.PresentationPairingUpdate>,
          _is.getType<_ijgt5qi7.PresentationParticipant>,
          _is.getType<_i4d7um9r.PresentationRole>,
          _is.getType<_ig7ln54r.PresentationSessionInfo>,
          _is.getType<_i95fngt4.PresentationState>,
          _is.getType<_ijdad65m.PresentationStateUpdate>,
          _is.getType<_iy6ry83r.SlidesSnapshotIndex>,
          _is.getType<_iilidizm.HeadlessChange>,
          _is.getType<_icpkpcrn.DocAck>,
          _is.getType<_i8zfu67r.DocBusMessage>,
          _is.getType<_imbts8if.DocCursorUpdate>,
          _is.getType<_imbts8if.DocHashCheck>,
          _is.getType<_imbts8if.DocPing>,
          _is.getType<_imbts8if.DocRequestOps>,
          _is.getType<_imbts8if.DocSubmitOp>,
          _is.getType<_icpkpcrn.DocHashResult>,
          _is.getType<_icpkpcrn.DocInit>,
          _is.getType<_icpkpcrn.DocMetaChanged>,
          _is.getType<_icpkpcrn.DocOpRejected>,
          _is.getType<_icpkpcrn.DocParticipantJoined>,
          _is.getType<_icpkpcrn.DocParticipantLeft>,
          _is.getType<_icpkpcrn.DocPong>,
          _is.getType<_icpkpcrn.DocRemoteCursor>,
          _is.getType<_icpkpcrn.DocRemoteOp>,
          _is.getType<_icpkpcrn.DocRoleChanged>,
          _is.getType<_igqu3xcv.ConvertForInsertResult>,
          _is.getType<_i5srcd7q.DocRejectCode>,
          _is.getType<_i4sx4pml.Document>,
          _is.getType<_ixppud51.DocumentImportReport>,
          _is.getType<_iu022vpf.DocumentInfo>,
          _is.getType<_ir38bcqq.DocumentMetaChange>,
          _is.getType<_inkjv0lb.DocumentMetaPatch>,
          _is.getType<_icsyekcn.DocumentMetaView>,
          _is.getType<_iufsprkx.DocumentOp>,
          _is.getType<_igr6xq1c.DocumentOpKind>,
          _is.getType<_issmv319.DocumentOpView>,
          _is.getType<_i2cnn8i8.DocumentSnapshot>,
          _is.getType<_i0cy62lm.DocumentSnapshotView>,
          _is.getType<_is1ql5wp.ExportProgressEvent>,
          _is.getType<_isdjhzgs.ExportProgressKind>,
          _is.getType<_if2sngze.ExportResultView>,
          _is.getType<_ittnhawp.ThemeConflictException>,
          _is.getType<_ii88i7dv.WriteDiffAuthor>,
          _is.getType<_ig4xquf5.WriteDiffCache>,
          _is.getType<_idky93gt.WriteDiffView>,
          _is.getType<_iynqrh33.WriteTheme>,
          _is.getType<_i7pbwt05.WriteThemeRevision>,
          _is.getType<_ick3mhj2.WriteThemeRevisionView>,
          _is.getType<_ixbjd26z.WriteThemeView>,
          _is.getType<_is9bkd9t.WriteVersionDocument>,
          _is.getType<_ihl3axv2.AclFutureCallFanOutModel?>,
          _is.getType<_icgheary.BoardFutureCallSummarizeModel?>,
          _is.getType<_if8h900w.BoardFutureCallTriageModel?>,
          _is.getType<_ixkvo7h1.BoardFutureCallWritePromptModel?>,
          _is.getType<_ip0bwzb4.BoardGithubFutureCallHandleModel?>,
          _is.getType<_i5z3lvv6.BoardGithubFutureCallReviewModel?>,
          _is.getType<_ilpvgw0t.FilePreviewFutureCallGenerateModel?>,
          _is.getType<_inb6x2l0.NotificationEmailFutureCallSendModel?>,
          _is.getType<_il37cz87.PublicationsFutureCallDeliverModel?>,
          _is.getType<_io4auc29.StorageFutureCallRefreshItemSizeModel?>,
          _is.getType<_izr1y672.ActivityDashboard?>,
          _is.getType<_iatdjl5p.ActivityEvent?>,
          _is.getType<_isa7sjzq.ActivityEventView?>,
          _is.getType<_ighcq381.ActivityTrendPoint?>,
          _is.getType<_i50cy468.ActivityType?>,
          _is.getType<_ikcwdr17.ActivityViewer?>,
          _is.getType<_ixdmbuaj.ItemViewDay?>,
          _is.getType<_ifmsnq1y.UserActivitySettings?>,
          _is.getType<_iyja8k5e.AiApplyMode?>,
          _is.getType<_iuq1eobh.AiPreviewRecord?>,
          _is.getType<_ir7z75mb.AiProvider?>,
          _is.getType<_ic2q2fwi.AiProviderKeyView?>,
          _is.getType<_iviyoyk9.AiQuality?>,
          _is.getType<_i7i53on7.AiUsage?>,
          _is.getType<_ivv7zvxt.AiUserKey?>,
          _is.getType<_imx2nn1q.AiUserSetting?>,
          _is.getType<_ic7e83wd.AssistantContextHints?>,
          _is.getType<_imp4tsxo.AssistantEvent?>,
          _is.getType<_id6kvqt9.AssistantEventType?>,
          _is.getType<_i8cittxq.AssistantMessage?>,
          _is.getType<_i4rkdm2k.AssistantMessageView?>,
          _is.getType<_ia2m3j3v.AssistantStatus?>,
          _is.getType<_iaq6rutx.AssistantThread?>,
          _is.getType<_i4iv0swm.AssistantThreadDetail?>,
          _is.getType<_iohdfqf1.AssistantThreadView?>,
          _is.getType<_i8ghcs7p.InlineAiEvent?>,
          _is.getType<_i6pcz5z6.InlineAiEventType?>,
          _is.getType<_i4m43iwr.InlineAiRequest?>,
          _is.getType<_ie0jt2ne.ProofreadEvent?>,
          _is.getType<_ivmxemza.ProofreadIssue?>,
          _is.getType<_ixradasp.AnalyticsCohort?>,
          _is.getType<_innm1rwe.AnalyticsCount?>,
          _is.getType<_is2u4stz.AnalyticsDay?>,
          _is.getType<_i61uxw4p.AnalyticsOverview?>,
          _is.getType<_id3chnrt.UsageApp?>,
          _is.getType<_iamkojeb.UsageCounterDay?>,
          _is.getType<_ibanfcrx.UsageDayStats?>,
          _is.getType<_ik0bapqg.UserActivityDay?>,
          _is.getType<_icowsqvh.BoardAiUsage?>,
          _is.getType<_i0ag0upm.BoardArea?>,
          _is.getType<_ika8r7fc.BoardAuthor?>,
          _is.getType<_ilo15wk2.BoardBundleSuggestion?>,
          _is.getType<_iin47lv0.BoardBundleSuggestionView?>,
          _is.getType<_ijz5flk6.BoardComment?>,
          _is.getType<_ipkjmsg5.BoardCommentView?>,
          _is.getType<_iswbp1jv.BoardCounts?>,
          _is.getType<_ita8snxr.BoardEventKind?>,
          _is.getType<_i0y7d0xd.BoardFlag?>,
          _is.getType<_iwc3b6vo.BoardFlagReason?>,
          _is.getType<_i5pjfe5s.BoardFlagView?>,
          _is.getType<_i5r22jl8.BoardGithubDelivery?>,
          _is.getType<_igcoqerx.BoardListQuery?>,
          _is.getType<_iu9hvv8z.BoardMe?>,
          _is.getType<_in0hwjmy.BoardModeration?>,
          _is.getType<_i5jfu168.BoardModerationAction?>,
          _is.getType<_idxofexa.BoardModerationLog?>,
          _is.getType<_i7xps6dm.BoardPost?>,
          _is.getType<_izvgi5ni.BoardPostDraft?>,
          _is.getType<_ibl25moa.BoardPostEvent?>,
          _is.getType<_iui4x9zg.BoardPostKind?>,
          _is.getType<_iq3f61ec.BoardPostListItem?>,
          _is.getType<_i1stsytz.BoardPostPage?>,
          _is.getType<_il200dga.BoardPostStatus?>,
          _is.getType<_ijjd81zg.BoardPostView?>,
          _is.getType<_i36hp4a6.BoardPullRequest?>,
          _is.getType<_im7v2irk.BoardReviewCounts?>,
          _is.getType<_id33cro1.BoardReviewItem?>,
          _is.getType<_izs2n8vy.BoardReviewSection?>,
          _is.getType<_ieemxbgb.BoardSignal?>,
          _is.getType<_in3cjdcj.BoardSimilarPost?>,
          _is.getType<_ivbgicm7.BoardSize?>,
          _is.getType<_itz4727j.BoardSort?>,
          _is.getType<_i2gir90g.BoardTargetKind?>,
          _is.getType<_iv26y3a1.BoardTask?>,
          _is.getType<_illpt7x2.BoardTaskPage?>,
          _is.getType<_idsjzf6h.BoardTaskRef?>,
          _is.getType<_i4a2ekwp.BoardTaskStatus?>,
          _is.getType<_ifz7dmuf.BoardTaskView?>,
          _is.getType<_iso7mdvm.BoardTriageState?>,
          _is.getType<_i516sz1w.BoardUserProfile?>,
          _is.getType<_ifuo09i6.BoardVote?>,
          _is.getType<_ie24iiog.BoardVoteResult?>,
          _is.getType<_i4piktk8.ClusterBusBatch?>,
          _is.getType<_ipkzl9y7.ClusterSignal?>,
          _is.getType<_iyixppck.Comment?>,
          _is.getType<_iw81twtc.CommentAnchorKind?>,
          _is.getType<_imlsyj2p.CommentEvent?>,
          _is.getType<_ih1mb6x5.CommentEventKind?>,
          _is.getType<_il5y6tzr.CommentFilter?>,
          _is.getType<_ix3p7034.CommentSignal?>,
          _is.getType<_iowdswxe.CommentStatus?>,
          _is.getType<_i94wr3td.CommentSystemEvent?>,
          _is.getType<_ijog60vm.CommentThread?>,
          _is.getType<_i818olql.CommentThreadView?>,
          _is.getType<_i4xrxro7.CommentView?>,
          _is.getType<_ii98prcs.AccessRole?>,
          _is.getType<_i2wc4tyi.ActorKind?>,
          _is.getType<_inb0isem.WonkyErrorCode?>,
          _is.getType<_igdswlrw.WonkyException?>,
          _is.getType<_iktwt5zz.DriveChange?>,
          _is.getType<_ijoqbs82.DriveChangeKind?>,
          _is.getType<_i0atxq9l.DriveChangeSignal?>,
          _is.getType<_ig2nixhn.DriveImportOptions?>,
          _is.getType<_inge8yy2.DriveItem?>,
          _is.getType<_i8mh39wa.DriveItemKind?>,
          _is.getType<_i0g2m831.DriveItemUserState?>,
          _is.getType<_infxyf98.DriveItemView?>,
          _is.getType<_ivypvw0m.DriveListFilter?>,
          _is.getType<_iavdhzsq.DriveListPage?>,
          _is.getType<_if1dhg5z.DriveOwnerFilter?>,
          _is.getType<_i6k3d1nc.DriveSearchFilters?>,
          _is.getType<_iu13r4v2.DriveSort?>,
          _is.getType<_ix0g8yw4.DriveSortField?>,
          _is.getType<_ipww3kqy.DriveView?>,
          _is.getType<_iez45i4u.FileCategory?>,
          _is.getType<_ilt75p4e.FileUploadProgress?>,
          _is.getType<_iqpb2qv1.FileUploadRequest?>,
          _is.getType<_imf3tnfq.FileUploadStart?>,
          _is.getType<_ia04wt6m.FileUploadState?>,
          _is.getType<_i68yhxa0.ImportReportView?>,
          _is.getType<_i48sm9f2.ImportWarningView?>,
          _is.getType<_i8hnug6t.StorageListFilter?>,
          _is.getType<_i26hsnhw.StorageUsage?>,
          _is.getType<_iiedu4vz.TemplateCategory?>,
          _is.getType<_i6rg3vdh.TemplatePreviewStyle?>,
          _is.getType<_i2ox7ta1.TemplateView?>,
          _is.getType<_io3ccr8w.UploadConflictMode?>,
          _is.getType<_iv1sk0e8.FeedbackKind?>,
          _is.getType<_iu565i0a.FeedbackReport?>,
          _is.getType<_ilhpki98.FeedbackSubmission?>,
          _is.getType<_irrzp8p9.FileUploadTicket?>,
          _is.getType<_itzt3x6d.FileUrlView?>,
          _is.getType<_iymtdptb.ImageProfile?>,
          _is.getType<_im8eh74x.StoredFile?>,
          _is.getType<_i45dmz4a.StoredFileKind?>,
          _is.getType<_ik7q11oy.StoredFileStatus?>,
          _is.getType<_ichw8k0i.UiBridgeCancel?>,
          _is.getType<_ichw8k0i.UiBridgeHello?>,
          _is.getType<_ichw8k0i.UiBridgeRequest?>,
          _is.getType<_ichw8k0i.UiBridgeResponse?>,
          _is.getType<_ichw8k0i.UiBridgeStatus?>,
          _is.getType<_ichw8k0i.UiBridgeStop?>,
          _is.getType<_ichw8k0i.UiBridgeWelcome?>,
          _is.getType<_ivk6eyvx.FeatureFlags?>,
          _is.getType<_ib575x0y.ProtocolInfo?>,
          _is.getType<_i28el0at.ServerLimits?>,
          _is.getType<_iexg4yzt.NotificationEvent?>,
          _is.getType<_iqlnbbfp.NotificationKind?>,
          _is.getType<_i3r1eo8q.NotificationPage?>,
          _is.getType<_iqsxdr4a.NotificationSignal?>,
          _is.getType<_izfzk9h3.NotificationView?>,
          _is.getType<_ik59hiyp.UserNotification?>,
          _is.getType<_iylgyc33.Participant?>,
          _is.getType<_i7dp90q0.PresenceBusMessage?>,
          _is.getType<_i8r9afjv.PresenceFollowerCount?>,
          _is.getType<_i8r9afjv.PresenceHints?>,
          _is.getType<_i8r9afjv.PresenceJoined?>,
          _is.getType<_i8r9afjv.PresenceLeft?>,
          _is.getType<_i8r9afjv.PresenceNotice?>,
          _is.getType<_i8r9afjv.PresenceRoster?>,
          _is.getType<_i8r9afjv.PresenceUpdated?>,
          _is.getType<_ik055xb9.PresenceState?>,
          _is.getType<_isz2sju0.PresenceUpdate?>,
          _is.getType<_ikkxb56h.Publication?>,
          _is.getType<_i5vk42yw.PublicationBlock?>,
          _is.getType<_i9g6l3wu.PublicationCard?>,
          _is.getType<_i0a1sw0a.PublicationCheckResult?>,
          _is.getType<_iqa48qn0.PublicationConsent?>,
          _is.getType<_ihiygfti.PublicationDelivery?>,
          _is.getType<_iz1gego0.PublicationDeliveryView?>,
          _is.getType<_iucp51pg.PublicationFieldMode?>,
          _is.getType<_i63wbtw0.PublicationFields?>,
          _is.getType<_iv6bey6s.PublicationInput?>,
          _is.getType<_i1u9dlta.PublicationModerator?>,
          _is.getType<_ij9tsbn9.PublicationModeratorView?>,
          _is.getType<_ivvukfve.PublicationOpenSubmission?>,
          _is.getType<_iyqlj2kr.PublicationSecret?>,
          _is.getType<_i5i48220.PublicationSettings?>,
          _is.getType<_ipbg6o7y.Submission?>,
          _is.getType<_i49gtkgr.SubmissionAsset?>,
          _is.getType<_ip6l83ta.SubmissionDeliveryState?>,
          _is.getType<_i71zy0hy.SubmissionRevision?>,
          _is.getType<_iegijpud.SubmissionRevisionView?>,
          _is.getType<_ijb8v3k4.SubmissionStarted?>,
          _is.getType<_i7hbulg4.SubmissionStatus?>,
          _is.getType<_iq9uje8l.SubmissionValues?>,
          _is.getType<_iakndug7.SubmissionView?>,
          _is.getType<_ie6clghy.RevAck?>,
          _is.getType<_i6ck957q.RevPing?>,
          _is.getType<_i6ck957q.RevRequestOps?>,
          _is.getType<_i6ck957q.RevSubmit?>,
          _is.getType<_ie6clghy.RevInit?>,
          _is.getType<_ie6clghy.RevPong?>,
          _is.getType<_ie6clghy.RevRejected?>,
          _is.getType<_ie6clghy.RevRemoteOp?>,
          _is.getType<_ie6clghy.RevResync?>,
          _is.getType<_ie6clghy.RevRoleChanged?>,
          _is.getType<_iyewfisw.RevBusMessage?>,
          _is.getType<_ip7h3lg0.RevFile?>,
          _is.getType<_ihwy023l.RevFileInfo?>,
          _is.getType<_iwkehf4e.RevFileKind?>,
          _is.getType<_ivfqwl6l.RevHookState?>,
          _is.getType<_iax01zbg.RevOp?>,
          _is.getType<_it4o2pk5.RevOpView?>,
          _is.getType<_ium7xjeg.RevPage?>,
          _is.getType<_i3q3ua5p.RevPageKind?>,
          _is.getType<_if03ikx4.RevPageRequest?>,
          _is.getType<_iilsyt4b.RevRejectCode?>,
          _is.getType<_ibw3povl.ServerChangeRecord?>,
          _is.getType<_i8scn8dm.AccessRequest?>,
          _is.getType<_i7trut12.AccessRequestOutcome?>,
          _is.getType<_iimp60a4.AccessRequestView?>,
          _is.getType<_iuzgacy4.DriveItemPermission?>,
          _is.getType<_ikeljole.InviteResolution?>,
          _is.getType<_ih3711er.ItemSharingSettings?>,
          _is.getType<_ijwxtu30.OwnershipTransfer?>,
          _is.getType<_iilpsf9g.OwnershipTransferView?>,
          _is.getType<_iead0ok9.PermissionView?>,
          _is.getType<_it712lg1.ShareLink?>,
          _is.getType<_iw2xoohn.ShareLinkView?>,
          _is.getType<_itd24os1.SharingInfo?>,
          _is.getType<_ifxa4vxf.QuotaExceededDetails?>,
          _is.getType<_if4kaxov.StorageReservation?>,
          _is.getType<_is05u0nw.UserStorage?>,
          _is.getType<_izha9j5m.AccessTokenView?>,
          _is.getType<_iq4dupwy.AccountDeletionPreview?>,
          _is.getType<_i6azdr3n.AppThemeMode?>,
          _is.getType<_iru4pv75.CreatedAccessToken?>,
          _is.getType<_ijodrcyd.PersonalAccessToken?>,
          _is.getType<_i5lc4gt0.UiDensity?>,
          _is.getType<_i501u5m5.UserPreferences?>,
          _is.getType<_id95rrz2.UserPreferencesPatch?>,
          _is.getType<_ihzl7wbq.UserProfile?>,
          _is.getType<_iufqmqtc.UserProfileView?>,
          _is.getType<_i6y7tspy.UserSummary?>,
          _is.getType<_i7jb115m.ItemVersion?>,
          _is.getType<_ibe5uno1.ItemVersionState?>,
          _is.getType<_ipbapjbz.ItemVersionView?>,
          _is.getType<_in0fdl1f.VersionKind?>,
          _is.getType<_in38zbga.VersionRestoreResult?>,
          _is.getType<_i5u6d6t4.VersionStorage?>,
          _is.getType<_i5vk0z7t.AiFunctionCache?>,
          _is.getType<_iuzj1jin.SheetsAiApplyResult?>,
          _is.getType<_iljqbz3a.SheetsAiCellRequest?>,
          _is.getType<_im85lt6z.SheetsAiCellResult?>,
          _is.getType<_i4t3jyqe.SheetsAiPreview?>,
          _is.getType<_idzstekp.SheetsAiPreviewCall?>,
          _is.getType<_i49726iv.SheetsAiPreviewCell?>,
          _is.getType<_izbpavhd.SheetsFillProposal?>,
          _is.getType<_i1gi0ui2.SheetsFillRow?>,
          _is.getType<_i2bhah0l.SheetsFormulaSuggestion?>,
          _is.getType<_i74ohdg2.SheetsImportJob?>,
          _is.getType<_iaf43n69.SheetsImportProgress?>,
          _is.getType<_i8d83qca.SheetsImportStatus?>,
          _is.getType<_ik5lpvx4.CellHistory?>,
          _is.getType<_ij1xvs09.CellHistoryEntry?>,
          _is.getType<_i09xo3k8.CellHistoryPage?>,
          _is.getType<_ilv3hlxr.RevertResult?>,
          _is.getType<_ipqum05l.RevertSkip?>,
          _is.getType<_i3p6on16.Banding?>,
          _is.getType<_iofnuqg9.BasicFilter?>,
          _is.getType<_ifc5vn9h.Cell?>,
          _is.getType<_iy4zsn6m.ConditionalFormatRule?>,
          _is.getType<_i5c2bsv2.DataValidationRule?>,
          _is.getType<_i145vl5m.DimensionGroup?>,
          _is.getType<_iye9c0co.EmbeddedObject?>,
          _is.getType<_ilnsyzhq.Dimension?>,
          _is.getType<_ihfpm0ve.EmbeddedObjectKind?>,
          _is.getType<_iofwzekn.HorizontalAlign?>,
          _is.getType<_i0z9m4nl.RecalcMode?>,
          _is.getType<_io4oc09s.ScriptBuildStatus?>,
          _is.getType<_i8ne06ql.SheetKind?>,
          _is.getType<_irmtoho8.TriggerKind?>,
          _is.getType<_ivf2txqv.VerticalAlign?>,
          _is.getType<_iz9rjt8b.WrapStrategy?>,
          _is.getType<_igzd7u0m.FilterView?>,
          _is.getType<_iiq43rv8.Macro?>,
          _is.getType<_i57rr32y.MergedRange?>,
          _is.getType<_irrybuvb.NamedRange?>,
          _is.getType<_iz580og3.PivotTable?>,
          _is.getType<_iz1b7y52.ProtectedRange?>,
          _is.getType<_ibdybin0.ScriptBuild?>,
          _is.getType<_iplsajic.ScriptFile?>,
          _is.getType<_iy6gs0qh.ScriptProject?>,
          _is.getType<_ig9hff0r.ScriptProperty?>,
          _is.getType<_irlm292d.ScriptTrigger?>,
          _is.getType<_i8c5x9aj.Sheet?>,
          _is.getType<_i6chd4x2.SheetColumn?>,
          _is.getType<_i4k3x536.SheetRow?>,
          _is.getType<_ib6gxu4b.Spreadsheet?>,
          _is.getType<_ijtj1mph.ScriptUserProperty?>,
          _is.getType<_iaehez21.SheetsActivitySummary?>,
          _is.getType<_i9yjzgjk.SheetsContributorStat?>,
          _is.getType<_iwl8v9t3.SheetsSnapshotIndex?>,
          _is.getType<_ibv2hdjr.ScriptAuthorization?>,
          _is.getType<_icjzxy6x.ScriptAuthorizationView?>,
          _is.getType<_iq0xpzf7.ScriptCompileResponse?>,
          _is.getType<_i4bc0fek.ScriptExecution?>,
          _is.getType<_inqz9v2t.ScriptExecutionKind?>,
          _is.getType<_ira26pfa.ScriptExecutionStatus?>,
          _is.getType<_is04pxv8.ScriptFetchResponse?>,
          _is.getType<_i4e1yb8z.ScriptJob?>,
          _is.getType<_itn7c5zm.ScriptQuotaUsage?>,
          _is.getType<_is0mvar3.ScriptRunResponse?>,
          _is.getType<_iy0fj18f.ScriptRuntimeKind?>,
          _is.getType<_ixysij0q.ScriptTriggerState?>,
          _is.getType<_iwj0qehd.SlidesAiAltText?>,
          _is.getType<_ix6z7bmu.SlidesAiApplyResult?>,
          _is.getType<_isdksxfl.SlidesAiBuildResult?>,
          _is.getType<_i154xjj9.SlidesAiDesignRank?>,
          _is.getType<_itoukaix.SlidesAiNote?>,
          _is.getType<_i225jf90.SlidesAiOutlineRequest?>,
          _is.getType<_ioipp9xy.SlidesAiPreview?>,
          _is.getType<_iuzye628.SlidesAiPreviewCall?>,
          _is.getType<_ixaahmd2.SlidesAiRewriteRequest?>,
          _is.getType<_i7q1o3oi.ChartLinkProbe?>,
          _is.getType<_i3ysrjbx.ChartLinkState?>,
          _is.getType<_is6z3tpy.ChartLinkStatus?>,
          _is.getType<_iua8dx49.ChartSnapshotView?>,
          _is.getType<_iq1h9id2.ChartSourceList?>,
          _is.getType<_inygrvyi.ChartSourceSummary?>,
          _is.getType<_ihkglt8b.ChartLink?>,
          _is.getType<_i6svv371.CodeState?>,
          _is.getType<_ioalf2ve.Deck?>,
          _is.getType<_i5vaufan.DeckTheme?>,
          _is.getType<_ipok3hcm.BuildKind?>,
          _is.getType<_isb6wks2.BuildTrigger?>,
          _is.getType<_isf9v7y6.DeckAppearance?>,
          _is.getType<_i4oq3vgh.PlaceholderType?>,
          _is.getType<_isah8148.SlideElementKind?>,
          _is.getType<_isghg0k1.SlideSizePreset?>,
          _is.getType<_i5m4q7yg.TableDimension?>,
          _is.getType<_ipsr29xb.Slide?>,
          _is.getType<_izfj14nk.SlideBuild?>,
          _is.getType<_ih1q77t5.SlideElement?>,
          _is.getType<_ic2hhlok.SlideGroup?>,
          _is.getType<_i3k3vjpp.SlideLayout?>,
          _is.getType<_igjrafa0.SlideMaster?>,
          _is.getType<_iewd9d8j.SlideTableAxis?>,
          _is.getType<_ibnoy0fr.SlideTableCell?>,
          _is.getType<_ildgqgkz.PresentationBusMessage?>,
          _is.getType<_iz9vxb2f.PresentationCommandEvent?>,
          _is.getType<_ijdad65m.PresentationCommandUpdate?>,
          _is.getType<_ijdad65m.PresentationEndUpdate?>,
          _is.getType<_iz9vxb2f.PresentationEndedEvent?>,
          _is.getType<_iz9vxb2f.PresentationInkEvent?>,
          _is.getType<_iz9vxb2f.PresentationLaserEvent?>,
          _is.getType<_iz9vxb2f.PresentationPairingEvent?>,
          _is.getType<_iz9vxb2f.PresentationPresenterEvent?>,
          _is.getType<_iz9vxb2f.PresentationRosterEvent?>,
          _is.getType<_iz9vxb2f.PresentationStateEvent?>,
          _is.getType<_iz9vxb2f.PresentationWelcome?>,
          _is.getType<_ijdad65m.PresentationInkUpdate?>,
          _is.getType<_ih25cwup.PresentationJoin?>,
          _is.getType<_ijdad65m.PresentationLaserUpdate?>,
          _is.getType<_i6know5x.PresentationPairingTarget?>,
          _is.getType<_ijdad65m.PresentationPairingUpdate?>,
          _is.getType<_ijgt5qi7.PresentationParticipant?>,
          _is.getType<_i4d7um9r.PresentationRole?>,
          _is.getType<_ig7ln54r.PresentationSessionInfo?>,
          _is.getType<_i95fngt4.PresentationState?>,
          _is.getType<_ijdad65m.PresentationStateUpdate?>,
          _is.getType<_iy6ry83r.SlidesSnapshotIndex?>,
          _is.getType<_iilidizm.HeadlessChange?>,
          _is.getType<_icpkpcrn.DocAck?>,
          _is.getType<_i8zfu67r.DocBusMessage?>,
          _is.getType<_imbts8if.DocCursorUpdate?>,
          _is.getType<_imbts8if.DocHashCheck?>,
          _is.getType<_imbts8if.DocPing?>,
          _is.getType<_imbts8if.DocRequestOps?>,
          _is.getType<_imbts8if.DocSubmitOp?>,
          _is.getType<_icpkpcrn.DocHashResult?>,
          _is.getType<_icpkpcrn.DocInit?>,
          _is.getType<_icpkpcrn.DocMetaChanged?>,
          _is.getType<_icpkpcrn.DocOpRejected?>,
          _is.getType<_icpkpcrn.DocParticipantJoined?>,
          _is.getType<_icpkpcrn.DocParticipantLeft?>,
          _is.getType<_icpkpcrn.DocPong?>,
          _is.getType<_icpkpcrn.DocRemoteCursor?>,
          _is.getType<_icpkpcrn.DocRemoteOp?>,
          _is.getType<_icpkpcrn.DocRoleChanged?>,
          _is.getType<_igqu3xcv.ConvertForInsertResult?>,
          _is.getType<_i5srcd7q.DocRejectCode?>,
          _is.getType<_i4sx4pml.Document?>,
          _is.getType<_ixppud51.DocumentImportReport?>,
          _is.getType<_iu022vpf.DocumentInfo?>,
          _is.getType<_ir38bcqq.DocumentMetaChange?>,
          _is.getType<_inkjv0lb.DocumentMetaPatch?>,
          _is.getType<_icsyekcn.DocumentMetaView?>,
          _is.getType<_iufsprkx.DocumentOp?>,
          _is.getType<_igr6xq1c.DocumentOpKind?>,
          _is.getType<_issmv319.DocumentOpView?>,
          _is.getType<_i2cnn8i8.DocumentSnapshot?>,
          _is.getType<_i0cy62lm.DocumentSnapshotView?>,
          _is.getType<_is1ql5wp.ExportProgressEvent?>,
          _is.getType<_isdjhzgs.ExportProgressKind?>,
          _is.getType<_if2sngze.ExportResultView?>,
          _is.getType<_ittnhawp.ThemeConflictException?>,
          _is.getType<_ii88i7dv.WriteDiffAuthor?>,
          _is.getType<_ig4xquf5.WriteDiffCache?>,
          _is.getType<_idky93gt.WriteDiffView?>,
          _is.getType<_iynqrh33.WriteTheme?>,
          _is.getType<_i7pbwt05.WriteThemeRevision?>,
          _is.getType<_ick3mhj2.WriteThemeRevisionView?>,
          _is.getType<_ixbjd26z.WriteThemeView?>,
          _is.getType<_is9bkd9t.WriteVersionDocument?>,
          _is.getType<List<int>>,
          _is.getType<List<_ikcwdr17.ActivityViewer>>,
          _is.getType<List<_ighcq381.ActivityTrendPoint>>,
          _is.getType<List<String>>,
          _is.getType<List<String>?>,
          _is.getType<List<_i4rkdm2k.AssistantMessageView>>,
          _is.getType<List<_ivmxemza.ProofreadIssue>>,
          _is.getType<List<_ivmxemza.ProofreadIssue>?>,
          _is.getType<List<int?>>,
          _is.getType<List<_is2u4stz.AnalyticsDay>>,
          _is.getType<List<_innm1rwe.AnalyticsCount>>,
          _is.getType<List<_ixradasp.AnalyticsCohort>>,
          _is.getType<List<int>>,
          _is.getType<List<_iq3f61ec.BoardPostListItem>>,
          _is.getType<List<_i5pjfe5s.BoardFlagView>>,
          _is.getType<List<_i5pjfe5s.BoardFlagView>?>,
          _is.getType<List<_il200dga.BoardPostStatus>>,
          _is.getType<List<_i0ag0upm.BoardArea>>,
          _is.getType<List<_ivbgicm7.BoardSize>>,
          _is.getType<Map<String, double>>,
          _is.getType<Map<String, double>?>,
          _is.getType<List<int>?>,
          _is.getType<List<_ifz7dmuf.BoardTaskView>>,
          _is.getType<List<_i4xrxro7.CommentView>>,
          _is.getType<List<_i6y7tspy.UserSummary>>,
          _is.getType<Map<String, List<int>>>,
          _is.getType<List<_is.UuidValue>>,
          _is.getType<List<_is.UuidValue>?>,
          _is.getType<List<_i8mh39wa.DriveItemKind>>,
          _is.getType<List<_i8mh39wa.DriveItemKind>?>,
          _is.getType<List<_iez45i4u.FileCategory>>,
          _is.getType<List<_iez45i4u.FileCategory>?>,
          _is.getType<List<_infxyf98.DriveItemView>>,
          _is.getType<List<_i48sm9f2.ImportWarningView>>,
          _is.getType<List<_izfzk9h3.NotificationView>>,
          _is.getType<List<_iylgyc33.Participant>>,
          _is.getType<List<_ivvukfve.PublicationOpenSubmission>>,
          _is.getType<List<_ij9tsbn9.PublicationModeratorView>>,
          _is.getType<List<_iegijpud.SubmissionRevisionView>>,
          _is.getType<List<_it4o2pk5.RevOpView>>,
          _is.getType<List<_it4o2pk5.RevOpView>?>,
          _is.getType<List<_iead0ok9.PermissionView>>,
          _is.getType<List<_iimp60a4.AccessRequestView>>,
          _is.getType<List<_idzstekp.SheetsAiPreviewCall>>,
          _is.getType<List<_i49726iv.SheetsAiPreviewCell>>,
          _is.getType<List<_i1gi0ui2.SheetsFillRow>>,
          _is.getType<List<_ij1xvs09.CellHistoryEntry>>,
          _is.getType<List<_ipqum05l.RevertSkip>>,
          _is.getType<Map<String, Map<int, int>>>,
          _is.getType<Map<int, int>>,
          _is.getType<List<_i9yjzgjk.SheetsContributorStat>>,
          _is.getType<Map<String, int>>,
          _is.getType<List<_iuzye628.SlidesAiPreviewCall>>,
          _is.getType<List<_inygrvyi.ChartSourceSummary>>,
          _is.getType<List<_ijgt5qi7.PresentationParticipant>>,
          _is.getType<List<_issmv319.DocumentOpView>>,
          _is.getType<List<_issmv319.DocumentOpView>?>,
          _is.getType<List<_i48sm9f2.ImportWarningView>?>,
          _is.getType<List<_ii88i7dv.WriteDiffAuthor>>,
          _is.getType<List<_i1372x0g.AssistantThreadView>>,
          _is.getType<List<_ilh4w69x.BoardCommentView>>,
          _is.getType<List<_iv1j9wri.BoardSimilarPost>>,
          _is.getType<List<_ihypagkt.BoardTaskStatus>>,
          _is.getType<List<_id1usvpt.BoardReviewItem>>,
          _is.getType<List<_is.UuidValue>>,
          _is.getType<List<_is.UuidValue>?>,
          _is.getType<List<_i8qikgvy.BoardBundleSuggestionView>>,
          _is.getType<List<_ixzwh8hc.CommentThreadView>>,
          _is.getType<List<int>?>,
          _is.getType<List<_ily3pmy5.DriveItemView>>,
          _is.getType<List<_ibinmr4r.TemplateView>>,
          _is.getType<List<_iiw0494r.ActivityEventView>>,
          _is.getType<List<_i28n3m1r.FileUrlView>>,
          _is.getType<List<_i9ilkmgj.PublicationSettings>>,
          _is.getType<List<String>>,
          _is.getType<List<_idovycpn.PublicationDeliveryView>>,
          _is.getType<List<_ioyb7a1p.AccessTokenView>>,
          _is.getType<List<_i8uuoam6.UserSummary>>,
          _is.getType<List<_ir2w0lzm.ItemVersionView>>,
          _is.getType<List<_isuyxaqz.SheetsFillRow>>,
          _is.getType<List<String>?>,
          _is.getType<List<_iq57nmvp.SheetsAiCellResult>>,
          _is.getType<List<_ifqit8uo.SheetsAiCellRequest>>,
          _is.getType<List<_iu7aww0d.RevOpView>>,
          _is.getType<Map<String, String>>,
          _is.getType<Map<String, String?>>,
          _is.getType<List<_isf59hoo.ScriptExecution>>,
          _is.getType<List<_iug1yx01.SlidesAiNote>>,
          _is.getType<List<_iqoob7q4.SlidesAiAltText>>,
          _is.getType<List<_ixtuoo5p.SlidesAiDesignRank>>,
          _is.getType<List<_imx2esrl.ChartLinkStatus>>,
          _is.getType<List<_izmhos0v.ChartLinkProbe>>,
          _is.getType<List<_icjb0pei.DocumentOpView>>,
          _is.getType<List<_ipbzt39t.WriteThemeView>>,
          _is.getType<List<_iu3gmhy1.WriteThemeRevisionView>>,
        ],
        modules: const [
          _iais.Protocol.new,
          _iacs.Protocol.new,
          _isp.Protocol.new,
        ],
      );

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'access_request',
      dartName: 'AccessRequest',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'requesterId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'requestedRole',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AccessRole',
        ),
        _isp.ColumnDefinition(
          name: 'message',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'handledAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'handledById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'outcome',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:AccessRequestOutcome?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'access_request_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'access_request_fk_1',
          columns: ['requesterId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'access_request_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'handledAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'activity_event',
      dartName: 'ActivityEvent',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'actorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActivityType',
        ),
        _isp.ColumnDefinition(
          name: 'summary',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'activity_event_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'activity_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'at',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'activity_type_at_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'type',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'at',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ai_function_cache',
      dartName: 'AiFunctionCache',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'key',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'model',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'value',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'error',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'hits',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_function_cache_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'key',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'ai_function_cache_sheet_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spreadsheetUuid',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ai_preview_record',
      dartName: 'AiPreviewRecord',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'previewId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'previewJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'changesJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_preview_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'previewId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'ai_preview_expires_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ai_usage',
      dartName: 'AiUsage',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'model',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'feature',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'inputTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'outputTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'cacheReadTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'cacheWriteTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'ai_usage_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_usage_user_at_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'at',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'ai_usage_at_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'at',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ai_user_key',
      dartName: 'AiUserKey',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'provider',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AiProvider',
        ),
        _isp.ColumnDefinition(
          name: 'apiKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'ai_user_key_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_user_key_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ai_user_setting',
      dartName: 'AiUserSetting',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'quality',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AiQuality',
          columnDefault: '\'best\'',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'ai_user_setting_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_user_setting_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'assistant_message',
      dartName: 'AssistantMessage',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'threadId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contentJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'displayText',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'toolCallsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'visible',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'replay',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'runId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stopReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'assistant_message_fk_0',
          columns: ['threadId'],
          referenceTable: 'assistant_thread',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'assistant_message_thread_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'threadId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'assistant_thread',
      dartName: 'AssistantThread',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contextRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'contextMarkdown',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'assistant_thread_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'assistant_thread_fk_1',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'assistant_thread_user_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'banding',
      dartName: 'Banding',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rangeJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'styleJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'banding_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'banding_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'banding_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'basic_filter',
      dartName: 'BasicFilter',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rangeJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'criteriaJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sortJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'basic_filter_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'basic_filter_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'basic_filter_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_ai_usage',
      dartName: 'BoardAiUsage',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'provider',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'model',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'feature',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'requests',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'inputTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'outputTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_ai_usage_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'provider',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'model',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'feature',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_bundle_suggestion',
      dartName: 'BoardBundleSuggestion',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'rationale',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'area',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:BoardArea?',
        ),
        _isp.ColumnDefinition(
          name: 'postIds',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<int>',
        ),
        _isp.ColumnDefinition(
          name: 'state',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_comment',
      dartName: 'BoardComment',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'postId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'taskId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'systemEvent',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'moderation',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardModeration',
        ),
        _isp.ColumnDefinition(
          name: 'moderationReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'needsCheck',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'editedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'removedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_comment_fk_0',
          columns: ['postId'],
          referenceTable: 'board_post',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'board_comment_fk_1',
          columns: ['taskId'],
          referenceTable: 'board_task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'board_comment_fk_2',
          columns: ['authorId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_comment_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'board_comment_post_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'board_comment_task_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_flag',
      dartName: 'BoardFlag',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'postId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'commentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardFlagReason',
        ),
        _isp.ColumnDefinition(
          name: 'note',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_flag_fk_0',
          columns: ['postId'],
          referenceTable: 'board_post',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'board_flag_fk_1',
          columns: ['commentId'],
          referenceTable: 'board_comment',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'board_flag_fk_2',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_flag_post_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'board_flag_comment_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'commentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_github_delivery',
      dartName: 'BoardGithubDelivery',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'deliveryId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'event',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'receivedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'payload',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'processedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_github_delivery_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'deliveryId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_moderation_log',
      dartName: 'BoardModerationLog',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'adminId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'action',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'targetKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardTargetKind',
        ),
        _isp.ColumnDefinition(
          name: 'targetId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'beforeJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'afterJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_moderation_log_target_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetKind',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_post',
      dartName: 'BoardPost',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardPostKind',
        ),
        _isp.ColumnDefinition(
          name: 'reportedKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardPostKind',
        ),
        _isp.ColumnDefinition(
          name: 'area',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:BoardArea?',
        ),
        _isp.ColumnDefinition(
          name: 'size',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:BoardSize?',
        ),
        _isp.ColumnDefinition(
          name: 'aiLabels',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contextJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'appHint',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'screenshotFileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardPostStatus',
        ),
        _isp.ColumnDefinition(
          name: 'moderation',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardModeration',
        ),
        _isp.ColumnDefinition(
          name: 'moderationReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'needsCheck',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'editedByModerator',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'triageState',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardTriageState',
        ),
        _isp.ColumnDefinition(
          name: 'triageJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'triageAttempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'suggestedTitle',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'summary',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'duplicateOfId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'possibleDuplicateOfId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'duplicateHintDismissed',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'declineReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'taskId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'score',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'voteCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'commentCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'flagCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'editedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'removedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_post_fk_0',
          columns: ['authorId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'board_post_fk_1',
          columns: ['screenshotFileId'],
          referenceTable: 'stored_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'board_post_fk_2',
          columns: ['taskId'],
          referenceTable: 'board_task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_post_list_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'moderation',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'kind',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'score',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'board_post_author_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authorId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'board_post_task_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_pull_request',
      dartName: 'BoardPullRequest',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'prNumber',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'taskId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'authorLogin',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'headSha',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'state',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'gateState',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'gateReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'gateFirstFailedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'gateCommentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewCommentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'lastReviewSha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lastReviewJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lastReviewAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewDay',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'mergeCommitSha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewPendingSha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewDueAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_pull_request_fk_0',
          columns: ['taskId'],
          referenceTable: 'board_task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_pull_request_number_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'prNumber',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_task',
      dartName: 'BoardTask',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'area',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardArea',
        ),
        _isp.ColumnDefinition(
          name: 'size',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardSize',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BoardTaskStatus',
        ),
        _isp.ColumnDefinition(
          name: 'promptBody',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'promptGeneratedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'promptRequestedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'promptNote',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'promptExcludedCommentIds',
          columnType: _isp.ColumnType.json,
          isNullable: true,
          dartType: 'List<int>?',
        ),
        _isp.ColumnDefinition(
          name: 'promptEditedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'promptEditedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdById',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'publishedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'claimedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'claimedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'claimExpiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'claimWarnedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'claimCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'pullRequestUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'prNumber',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'prAuthorLogin',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'mergeCommitSha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'doneAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'shippedDeploySha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'shippedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_task_fk_0',
          columns: ['claimedById'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_task_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'board_task_claim_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'claimedById',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_user_profile',
      dartName: 'BoardUserProfile',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'githubLogin',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'blockedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'blockedUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'blockedReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'blockedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_user_profile_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_user_profile_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board_vote',
      dartName: 'BoardVote',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'postId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'value',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_vote_fk_0',
          columns: ['postId'],
          referenceTable: 'board_post',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'board_vote_fk_1',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_vote_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'board_vote_recent_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'cell',
      dartName: 'Cell',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rowId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'columnId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'content',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'note',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'numberFormat',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fontFamily',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fontSize',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'bold',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'italic',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'underline',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'strikethrough',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'textColor',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fillColor',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'hAlign',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:HorizontalAlign?',
        ),
        _isp.ColumnDefinition(
          name: 'vAlign',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:VerticalAlign?',
        ),
        _isp.ColumnDefinition(
          name: 'wrap',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:WrapStrategy?',
        ),
        _isp.ColumnDefinition(
          name: 'rotation',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'borderTop',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'borderRight',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'borderBottom',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'borderLeft',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'linkUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'cell_fk_0',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'cell_row_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sheetId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'rowId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'cell_col_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sheetId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'columnId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'cell_history',
      dartName: 'CellHistory',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rowId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'colId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'before',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'after',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'cell_history_cell_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sheetId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'rowId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'colId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'at',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'cell_history_change_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'revision',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'rowId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'colId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'chart_link',
      dartName: 'ChartLink',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'elementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetItemUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'chartObjectId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sourceSpecJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'dataSnapshotJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sourceVersion',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'autoUpdate',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'chart_link_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'chart_link_fk_1',
          columns: ['elementId'],
          referenceTable: 'slide_element',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'chart_link_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'chart_link_element_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'elementId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'code_state',
      dartName: 'CodeState',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'elementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'code',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'language',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'highlight',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'annotationsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'transitionJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'code_state_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'code_state_fk_1',
          columns: ['elementId'],
          referenceTable: 'slide_element',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'code_state_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'code_state_element_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'elementId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'comment',
      dartName: 'Comment',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'threadId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'authorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'mentions',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<int>',
        ),
        _isp.ColumnDefinition(
          name: 'reactions',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'editedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'systemEvent',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:CommentSystemEvent?',
        ),
        _isp.ColumnDefinition(
          name: 'publicationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'comment_fk_0',
          columns: ['threadId'],
          referenceTable: 'comment_thread',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'comment_fk_1',
          columns: ['publicationId'],
          referenceTable: 'publication',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'comment_thread_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'threadId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'comment_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'comment_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'comment_thread',
      dartName: 'CommentThread',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'anchorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:CommentAnchorKind',
        ),
        _isp.ColumnDefinition(
          name: 'anchorJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'quotedText',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:CommentStatus',
          columnDefault: '\'open\'',
        ),
        _isp.ColumnDefinition(
          name: 'createdById',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'assigneeId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'statusBeforeOrphan',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:CommentStatus?',
        ),
        _isp.ColumnDefinition(
          name: 'orphanReasonJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'suggestionId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'comment_thread_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'comment_thread_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'comment_thread_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'conditional_format_rule',
      dartName: 'ConditionalFormatRule',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'rangesJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'ruleJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'enabled',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'conditional_format_rule_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'conditional_format_rule_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'conditional_format_rule_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'data_validation_rule',
      dartName: 'DataValidationRule',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rangesJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'criteriaJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'strict',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'showDropdown',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'displayStyle',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'helpText',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'data_validation_rule_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'data_validation_rule_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'data_validation_rule_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'deck',
      dartName: 'Deck',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'width',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '1920.0',
        ),
        _isp.ColumnDefinition(
          name: 'height',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '1080.0',
        ),
        _isp.ColumnDefinition(
          name: 'sizePreset',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SlideSizePreset',
          columnDefault: '\'widescreen16x9\'',
        ),
        _isp.ColumnDefinition(
          name: 'themeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'appearance',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DeckAppearance',
          columnDefault: '\'light\'',
        ),
        _isp.ColumnDefinition(
          name: 'language',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'showSlideNumbers',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'hideNumberOnTitle',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'firstSlideNumber',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'footerText',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'defaultsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'guidesJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'presentJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'deck_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'deck_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'deck_theme',
      dartName: 'DeckTheme',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'deckId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sourceKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'colorsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'fontsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'textStylesJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'backgroundJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'shapeStyleJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'tableStyleJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'codeStyleJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'chartStyleJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'deck_theme_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'deck_theme_fk_1',
          columns: ['deckId'],
          referenceTable: 'deck',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'deck_theme_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'deck_theme_deck_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'deckId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dimension_group',
      dartName: 'DimensionGroup',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'dimension',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:Dimension',
        ),
        _isp.ColumnDefinition(
          name: 'startId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'endId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'depth',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'collapsed',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'dimension_group_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'dimension_group_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'dimension_group_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document',
      dartName: 'Document',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'headRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'latestSnapshotRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'themeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'pageSetupJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'language',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'frontMatter',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'charCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'wordCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'document_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'document_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document_import_report',
      dartName: 'DocumentImportReport',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'warningsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'seenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'document_import_report_fk_0',
          columns: ['documentId'],
          referenceTable: 'document',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_import_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document_meta_change',
      dartName: 'DocumentMetaChange',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'field',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'clientOpId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'beforeJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'afterJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'document_meta_change_fk_0',
          columns: ['documentId'],
          referenceTable: 'document',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_meta_change_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'document_meta_change_client_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'clientOpId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document_op',
      dartName: 'DocumentOp',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'clientOpId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'sessionId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DocumentOpKind',
        ),
        _isp.ColumnDefinition(
          name: 'baseRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'deltaJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'inverseJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'document_op_fk_0',
          columns: ['documentId'],
          referenceTable: 'document',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_op_rev_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'revision',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'document_op_client_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'clientOpId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'document_op_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'brin',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document_snapshot',
      dartName: 'DocumentSnapshot',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'deltaJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'compressed',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'document_snapshot_fk_0',
          columns: ['documentId'],
          referenceTable: 'document',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_snapshot_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'revision',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'drive_item',
      dartName: 'DriveItem',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DriveItemKind',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'ownerId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'parentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'contentRef',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'thumbnailFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'sizeBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'attachmentBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'kindMask',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'mimeType',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fileCategory',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:FileCategory?',
        ),
        _isp.ColumnDefinition(
          name: 'uploadState',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:FileUploadState?',
        ),
        _isp.ColumnDefinition(
          name: 'fileMetaJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'previewFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'createdById',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'modifiedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'modifiedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'trashedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'trashedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'templateOf',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:TemplateCategory?',
        ),
        _isp.ColumnDefinition(
          name: 'templateKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'editorsCanShare',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'nonEditorsCanExport',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'viewersSeeComments',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'searchText',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'drive_item_fk_0',
          columns: ['ownerId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'drive_item_fk_1',
          columns: ['parentId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'drive_item_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'drive_item_parent_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'parentId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'drive_item_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'ownerId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'trashedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'drive_item_content_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'contentRef',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'drive_item_template_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'templateOf',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'drive_item_upload_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uploadState',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'drive_item_trashed_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'trashedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'drive_item_permission',
      dartName: 'DriveItemPermission',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'invitedEmail',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AccessRole',
        ),
        _isp.ColumnDefinition(
          name: 'inheritedFromId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'grantedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'grantedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'viaPublicationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'drive_item_permission_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'drive_item_permission_fk_1',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'drive_item_permission_fk_2',
          columns: ['viaPublicationId'],
          referenceTable: 'publication',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'perm_item_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'inheritedFromId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'invitedEmail',
            ),
          ],
          type: 'btree',
          isUnique: true,
          nullsDistinct: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'perm_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'perm_email_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'invitedEmail',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'perm_expires_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'perm_granted_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'grantedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'drive_item_user_state',
      dartName: 'DriveItemUserState',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'starred',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'lastOpenedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastEditedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'pinnedOffline',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'shortcutParentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'viaLink',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'drive_item_user_state_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'drive_item_user_state_fk_1',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'drive_item_user_state_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'drive_item_user_recent_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lastOpenedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'embedded_object',
      dartName: 'EmbeddedObject',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EmbeddedObjectKind',
        ),
        _isp.ColumnDefinition(
          name: 'anchorJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'specJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'zIndex',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'altText',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'embedded_object_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'embedded_object_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'embedded_object_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'feedback_report',
      dartName: 'FeedbackReport',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FeedbackKind',
        ),
        _isp.ColumnDefinition(
          name: 'message',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'app',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'appVersion',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'platform',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'route',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stackTrace',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'contextJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'feedback_report_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'filter_view',
      dartName: 'FilterView',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'rangeJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'criteriaJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sortJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'filter_view_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'filter_view_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'filter_view_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'headless_change',
      dartName: 'HeadlessChange',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'changeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'inverseJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'metaField',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'metaBeforeJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'metaAfterJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'toolName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'revertedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'headless_change_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'headless_change_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'changeId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'headless_change_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'item_version',
      dartName: 'ItemVersion',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:VersionKind',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'createdById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'authors',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<int>',
        ),
        _isp.ColumnDefinition(
          name: 'storageKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:VersionStorage',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'snapshotFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'sizeBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'item_version_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'item_version_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'item_version_state',
      dartName: 'ItemVersionState',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'lastEditAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'dirtySince',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastVersionAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'editorsSinceLastVersion',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<int>',
        ),
        _isp.ColumnDefinition(
          name: 'lastRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'capturingSince',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'item_version_state_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'item_version_state_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'item_version_state_dirty_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'dirtySince',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'item_view_day',
      dartName: 'ItemViewDay',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'views',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'lastViewedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'item_view_day_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'item_view_day_fk_1',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'item_view_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'item_view_day_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'macro',
      dartName: 'Macro',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'projectId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'functionName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'shortcutSlot',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'macro_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'macro_fk_1',
          columns: ['projectId'],
          referenceTable: 'script_project',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'macro_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'merged_range',
      dartName: 'MergedRange',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rangeJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'merged_range_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'merged_range_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'merged_range_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'named_range',
      dartName: 'NamedRange',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'rangeJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'formula',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'comment',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'metaJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'named_range_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'named_range_fk_1',
          columns: ['spreadsheetId'],
          referenceTable: 'spreadsheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'named_range_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'notification',
      dartName: 'UserNotification',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:NotificationKind',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'actorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'payload',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'readAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'emailedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'emailPending',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'notification_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'notification_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'notification_email_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'emailPending',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'notification_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'brin',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ownership_transfer',
      dartName: 'OwnershipTransfer',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fromUserId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'toUserId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'handledAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'accepted',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'ownership_transfer_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'ownership_transfer_fk_1',
          columns: ['toUserId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ownership_transfer_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'handledAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'personal_access_token',
      dartName: 'PersonalAccessToken',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tokenHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'prefix',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'scopes',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastUsedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'revokedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'personal_access_token_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'personal_access_token_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'personal_access_token_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tokenHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'pivot_table',
      dartName: 'PivotTable',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'anchorRowId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'anchorColId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sourceRangeJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'specJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'pivot_table_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'pivot_table_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'pivot_table_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'protected_range',
      dartName: 'ProtectedRange',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rangeJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'exceptRangesJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'warningOnly',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'editorsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'protected_range_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'protected_range_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'protected_range_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'publication',
      dartName: 'Publication',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'publicId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'ownerId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'siteUrl',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'webhookUrl',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'verifiedHost',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'verifiedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'templateItemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'termsUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fields',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'protocol:PublicationFields',
        ),
        _isp.ColumnDefinition(
          name: 'signingSecret',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'previousSigningSecret',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'previousSecretUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'apiKeyHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'apiKeyLast4',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'enabled',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_fk_0',
          columns: ['ownerId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_fk_1',
          columns: ['templateItemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'publication_public_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'publicId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'publication_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'ownerId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'publication_api_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'apiKeyHash',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'publication_block',
      dartName: 'PublicationBlock',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'publicationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_block_fk_0',
          columns: ['publicationId'],
          referenceTable: 'publication',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_block_fk_1',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'publication_block_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'publicationId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'publication_consent',
      dartName: 'PublicationConsent',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'publicationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'consentKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'at',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_consent_fk_0',
          columns: ['publicationId'],
          referenceTable: 'publication',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_consent_fk_1',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'publication_consent_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'publicationId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'publication_delivery',
      dartName: 'PublicationDelivery',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'publicationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'submissionId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'webhookId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sequence',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'payload',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'nextAttemptAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'leaseUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastStatus',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'lastError',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'deliveredAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'failedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_delivery_fk_0',
          columns: ['publicationId'],
          referenceTable: 'publication',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_delivery_fk_1',
          columns: ['submissionId'],
          referenceTable: 'submission',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'publication_delivery_webhook_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'webhookId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'publication_delivery_due_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'nextAttemptAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'publication_delivery_publication_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'publicationId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'publication_moderator',
      dartName: 'PublicationModerator',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'publicationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'email',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_moderator_fk_0',
          columns: ['publicationId'],
          referenceTable: 'publication',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'publication_moderator_fk_1',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'publication_moderator_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'publicationId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'publication_moderator_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'rev_file',
      dartName: 'RevFile',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RevFileKind',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'headRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'prunedBelow',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'initPending',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'purging',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'schemaHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'stats',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'contentCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'rev_file_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'rev_file_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'rev_file_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'rev_hook_state',
      dartName: 'RevHookState',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'cursorsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'leaseOwner',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'leaseUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'lastError',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'nextAttemptAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'rev_hook_state_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'rev_hook_state_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'rev_hook_state_due_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'nextAttemptAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'rev_op',
      dartName: 'RevOp',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'clientOpId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'baseRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'authorUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'sessionId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'onBehalfOfSessionId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'groupId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'groupIndex',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'groupLast',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'recordId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'offline',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'payload',
          columnType: _isp.ColumnType.bytea,
          isNullable: true,
          dartType: 'dart:typed_data:ByteData?',
        ),
        _isp.ColumnDefinition(
          name: 'changeCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'summaryJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'detailJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'outcomeJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'appliedEqualsSubmitted',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'clientCreatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'committedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'rev_op_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'rev_op_rev_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'revision',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'rev_op_client_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'clientOpId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'rev_op_record_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'recordId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'rev_op_committed_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'committedAt',
            ),
          ],
          type: 'brin',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_authorization',
      dartName: 'ScriptAuthorization',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'scopes',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'grantedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'revokedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_auth_user_sheet_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spreadsheetUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_build',
      dartName: 'ScriptBuild',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'projectId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScriptBuildStatus',
          columnDefault: '\'ok\'',
        ),
        _isp.ColumnDefinition(
          name: 'sourceHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'bytecodeFileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'diagnosticsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'exportsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'apiVersion',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'compilerVersion',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'requestedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'lastGoodSourceHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lastGoodBytecodeFileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'lastGoodExportsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'lastGoodBuiltAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'positionsFileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'builtAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'script_build_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'script_build_fk_1',
          columns: ['projectId'],
          referenceTable: 'script_project',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_build_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_execution',
      dartName: 'ScriptExecution',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'projectId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'functionName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScriptExecutionKind',
        ),
        _isp.ColumnDefinition(
          name: 'triggerId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'runAsUserId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'runtime',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScriptRuntimeKind',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScriptExecutionStatus',
        ),
        _isp.ColumnDefinition(
          name: 'buildSourceHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'durationMs',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'logs',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'errorMessage',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'errorStackJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'changeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'cellsRead',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'cellsWritten',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fetchCalls',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'callCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_exec_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'script_exec_sheet_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spreadsheetUuid',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'startedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'script_exec_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'startedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_file',
      dartName: 'ScriptFile',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'projectId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'source',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contentHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'updatedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'script_file_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'script_file_fk_1',
          columns: ['projectId'],
          referenceTable: 'script_project',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_file_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_job',
      dartName: 'ScriptJob',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScriptExecutionKind',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'itemUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'triggerId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'runAsUserId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'functionName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'payloadJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScriptExecutionStatus',
        ),
        _isp.ColumnDefinition(
          name: 'enqueuedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'leaseOwner',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'leaseUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'coalesced',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'resultJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'finishedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_job_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'enqueuedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'script_job_trigger_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'triggerId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'script_job_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'runAsUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_project',
      dartName: 'ScriptProject',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'settingsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'script_project_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'script_project_fk_1',
          columns: ['spreadsheetId'],
          referenceTable: 'spreadsheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_project_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_property',
      dartName: 'ScriptProperty',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'projectId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'key',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'value',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'script_property_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'script_property_fk_1',
          columns: ['projectId'],
          referenceTable: 'script_project',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_property_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_quota_usage',
      dartName: 'ScriptQuotaUsage',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'serverRuntimeMs',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'clientRuntimeMs',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'urlFetchCalls',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'urlFetchBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'triggerRuns',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_quota_user_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_trigger',
      dartName: 'ScriptTrigger',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'projectId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:TriggerKind',
        ),
        _isp.ColumnDefinition(
          name: 'functionName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'scheduleJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'runAsUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'enabled',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'optionsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'script_trigger_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'script_trigger_fk_1',
          columns: ['projectId'],
          referenceTable: 'script_project',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_trigger_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_trigger_state',
      dartName: 'ScriptTriggerState',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'triggerId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'scheduleJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'nextRunAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastRunAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastStatus',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:ScriptExecutionStatus?',
        ),
        _isp.ColumnDefinition(
          name: 'consecutiveFailures',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'disabledReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'runningSince',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastNotifiedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_trigger_state_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'triggerId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'script_trigger_state_due_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'nextRunAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'script_user_property',
      dartName: 'ScriptUserProperty',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'key',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'value',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'script_user_property_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'script_user_property_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'key',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'server_change_record',
      dartName: 'ServerChangeRecord',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'changeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'inverseJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'inverseFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'forwardFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'recordId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'cellsAffected',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'revertedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'revertChangeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'server_change_record_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'recordId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'server_change_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'server_change_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'changeId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'share_link',
      dartName: 'ShareLink',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'token',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:AccessRole?',
        ),
        _isp.ColumnDefinition(
          name: 'createdById',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'share_link_fk_0',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'share_link_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'share_link_token_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'token',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'sheet',
      dartName: 'Sheet',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SheetKind',
          columnDefault: '\'grid\'',
        ),
        _isp.ColumnDefinition(
          name: 'hidden',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'tabColor',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'rightToLeft',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'showGridlines',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'frozenRows',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'frozenColumns',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'defaultRowHeight',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '21.0',
        ),
        _isp.ColumnDefinition(
          name: 'defaultColumnWidth',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '100.0',
        ),
        _isp.ColumnDefinition(
          name: 'formatJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'printSettingsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'sheet_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'sheet_fk_1',
          columns: ['spreadsheetId'],
          referenceTable: 'spreadsheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'sheet_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'sheet_order_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spreadsheetId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'sheet_column',
      dartName: 'SheetColumn',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'width',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'hidden',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'formatJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'sheet_column_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'sheet_column_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'sheet_column_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'sheet_column_order_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sheetId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'sheet_row',
      dartName: 'SheetRow',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sheetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'height',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'hidden',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'formatJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'sheet_row_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'sheet_row_fk_1',
          columns: ['sheetId'],
          referenceTable: 'sheet',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'sheet_row_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'sheet_row_order_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sheetId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'sheets_import_job',
      dartName: 'SheetsImportJob',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'uploadFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'fileName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'format',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'optionsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'activeSheetId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SheetsImportStatus',
        ),
        _isp.ColumnDefinition(
          name: 'progressDone',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'progressTotal',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'reportJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sheetIdsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'changeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'errorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'error',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'cancelRequested',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'leaseOwner',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'leaseUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'sheets_import_job_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'sheets_import_job_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'sheets_snapshot_index',
      dartName: 'SheetsSnapshotIndex',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemVersionId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'sheetsJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'changedRangesJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'authorIds',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<int>',
        ),
        _isp.ColumnDefinition(
          name: 'diffFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'sheets_snapshot_index_fk_0',
          columns: ['itemVersionId'],
          referenceTable: 'item_version',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'sheets_snapshot_index_version_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemVersionId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide',
      dartName: 'Slide',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'deckId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'groupId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'layoutId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'backgroundJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'skipped',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'notes',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'transitionJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'hideMasterElements',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'timingsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_fk_1',
          columns: ['deckId'],
          referenceTable: 'deck',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_order_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'deckId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide_build',
      dartName: 'SlideBuild',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'slideId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'elementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BuildKind',
        ),
        _isp.ColumnDefinition(
          name: 'effect',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'trigger',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:BuildTrigger',
        ),
        _isp.ColumnDefinition(
          name: 'delayMs',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'durationMs',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'easing',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'optionsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_build_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_build_fk_1',
          columns: ['slideId'],
          referenceTable: 'slide',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_build_fk_2',
          columns: ['elementId'],
          referenceTable: 'slide_element',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_build_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_build_slide_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'slideId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_build_element_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'elementId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide_element',
      dartName: 'SlideElement',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'slideId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'layoutId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'masterId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'parentId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SlideElementKind',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'x',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'y',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'width',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'height',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'rotation',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'flipH',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'flipV',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'zKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'readingKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'locked',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'hidden',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'placeholderType',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:PlaceholderType?',
        ),
        _isp.ColumnDefinition(
          name: 'placeholderOf',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'matchKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'text',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'textStyleJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fillJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'strokeJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'effectsJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'opacity',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'dataJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'linkJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'altText',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'decorative',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_element_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_element_fk_1',
          columns: ['slideId'],
          referenceTable: 'slide',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_element_fk_2',
          columns: ['layoutId'],
          referenceTable: 'slide_layout',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_element_fk_3',
          columns: ['masterId'],
          referenceTable: 'slide_master',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_element_fk_4',
          columns: ['parentId'],
          referenceTable: 'slide_element',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_element_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_element_slide_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'slideId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'zKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_element_layout_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'layoutId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_element_master_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'masterId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_element_parent_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'parentId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide_group',
      dartName: 'SlideGroup',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'deckId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'parentId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'color',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'skipped',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_group_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_group_fk_1',
          columns: ['deckId'],
          referenceTable: 'deck',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_group_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_group_order_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'deckId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide_layout',
      dartName: 'SlideLayout',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'masterId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'key',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'backgroundJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'hideMasterElements',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'hidden',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_layout_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_layout_fk_1',
          columns: ['masterId'],
          referenceTable: 'slide_master',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_layout_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_layout_master_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'masterId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide_master',
      dartName: 'SlideMaster',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'themeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'backgroundJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_master_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_master_fk_1',
          columns: ['themeId'],
          referenceTable: 'deck_theme',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_master_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_master_theme_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'themeId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide_table_axis',
      dartName: 'SlideTableAxis',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'elementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'dimension',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:TableDimension',
        ),
        _isp.ColumnDefinition(
          name: 'sortKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'size',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'header',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_table_axis_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_table_axis_fk_1',
          columns: ['elementId'],
          referenceTable: 'slide_element',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_table_axis_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_table_axis_element_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'elementId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sortKey',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slide_table_cell',
      dartName: 'SlideTableCell',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'elementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'rowId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'columnId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'text',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fill',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'borderTop',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'borderRight',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'borderBottom',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'borderLeft',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'vAlign',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'padding',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'rowSpan',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'colSpan',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_table_cell_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_table_cell_fk_1',
          columns: ['elementId'],
          referenceTable: 'slide_element',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_table_cell_fk_2',
          columns: ['rowId'],
          referenceTable: 'slide_table_axis',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'slide_table_cell_fk_3',
          columns: ['columnId'],
          referenceTable: 'slide_table_axis',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slide_table_cell_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'slide_table_cell_element_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'elementId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'slides_snapshot_index',
      dartName: 'SlidesSnapshotIndex',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'itemVersionId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'slidesJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'changesJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'authorIds',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<int>',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'slides_snapshot_index_fk_0',
          columns: ['itemVersionId'],
          referenceTable: 'item_version',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'slides_snapshot_index_version_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemVersionId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'spreadsheet',
      dartName: 'Spreadsheet',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'fileId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'locale',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'timeZone',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'recalcMode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RecalcMode',
          columnDefault: '\'onChange\'',
        ),
        _isp.ColumnDefinition(
          name: 'iterativeCalc',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'maxIterations',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '50',
        ),
        _isp.ColumnDefinition(
          name: 'convergenceThreshold',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.05',
        ),
        _isp.ColumnDefinition(
          name: 'defaultFontFamily',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'Inter\'',
        ),
        _isp.ColumnDefinition(
          name: 'defaultFontSize',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '10.0',
        ),
        _isp.ColumnDefinition(
          name: 'themeJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'displayLanguage',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'spreadsheet_fk_0',
          columns: ['fileId'],
          referenceTable: 'rev_file',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'spreadsheet_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'storage_reservation',
      dartName: 'StorageReservation',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'bytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'storage_reservation_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'storage_reservation_fk_1',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'storage_reservation_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'storage_reservation_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'storage_reservation_expiry_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'stored_file',
      dartName: 'StoredFile',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'ownerId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:StoredFileKind',
        ),
        _isp.ColumnDefinition(
          name: 'storageId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'path',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'fileName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'mimeType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sizeBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:StoredFileStatus',
        ),
        _isp.ColumnDefinition(
          name: 'imageProfile',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:ImageProfile?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'completedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'stored_file_fk_0',
          columns: ['ownerId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'stored_file_fk_1',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'stored_file_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'stored_file_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'stored_file_expiry_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'stored_file_owner_kind_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'ownerId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'kind',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'stored_file_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'submission',
      dartName: 'Submission',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'publicationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'itemId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ref',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SubmissionStatus',
        ),
        _isp.ColumnDefinition(
          name: 'statusBeforeSubmit',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:SubmissionStatus?',
        ),
        _isp.ColumnDefinition(
          name: 'delivery',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:SubmissionDeliveryState?',
        ),
        _isp.ColumnDefinition(
          name: 'values',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'protocol:SubmissionValues',
        ),
        _isp.ColumnDefinition(
          name: 'publicUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'feedbackThreadId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'createdById',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'disconnectedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'submission_fk_0',
          columns: ['publicationId'],
          referenceTable: 'publication',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'submission_fk_1',
          columns: ['itemId'],
          referenceTable: 'drive_item',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'submission_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'submission_item_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'submission_publication_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'publicationId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'submission_asset',
      dartName: 'SubmissionAsset',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'submissionId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fileUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'submission_asset_fk_0',
          columns: ['submissionId'],
          referenceTable: 'submission',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'submission_asset_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'submissionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'submission_asset_file_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fileUuid',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'submission_revision',
      dartName: 'SubmissionRevision',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'submissionId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'sequence',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'versionId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'values',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'protocol:SubmissionValues',
        ),
        _isp.ColumnDefinition(
          name: 'payload',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'submittedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'submittedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'submission_revision_fk_0',
          columns: ['submissionId'],
          referenceTable: 'submission',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'submission_revision_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'submissionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sequence',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'usage_counter_day',
      dartName: 'UsageCounterDay',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'value',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'usage_counter_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'usage_day_stats',
      dartName: 'UsageDayStats',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'includeAdmins',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'active',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'editors',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'drive',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'write',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'sheets',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'slides',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'mcp',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'weekly',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'monthly',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'computedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'usage_day_stats_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'includeAdmins',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'user_activity_day',
      dartName: 'UserActivityDay',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'app',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:UsageApp',
        ),
        _isp.ColumnDefinition(
          name: 'edited',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'user_activity_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'app',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'user_activity_day_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'user_activity_settings',
      dartName: 'UserActivitySettings',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'showViewHistory',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'user_activity_settings_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'user_activity_settings_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'user_preferences',
      dartName: 'UserPreferences',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'appTheme',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AppThemeMode',
          columnDefault: '\'system\'',
        ),
        _isp.ColumnDefinition(
          name: 'accentColor',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'density',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:UiDensity',
          columnDefault: '\'comfortable\'',
        ),
        _isp.ColumnDefinition(
          name: 'reduceMotion',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'keymapOverrides',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'writeDefaults',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'sheetsDefaults',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'slidesDefaults',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'slidesPresenter',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'driveDefaults',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'notificationSettings',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'{}\'',
        ),
        _isp.ColumnDefinition(
          name: 'aiEnabled',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'user_preferences_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'user_preferences_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'user_profile',
      dartName: 'UserProfile',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'displayName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'email',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'avatarFileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'avatarColor',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'locale',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'timeZone',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastSeenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'welcomeContentAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'user_profile_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'user_profile_auth_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'user_profile_email_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'user_profile_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'user_storage',
      dartName: 'UserStorage',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'usedBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'reservedBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'documentsBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'spreadsheetsBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'presentationsBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'filesBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'trashBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'quotaBytesOverride',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'overQuotaSince',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'reconciledAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'user_storage_fk_0',
          columns: ['userId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'user_storage_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'write_diff_cache',
      dartName: 'WriteDiffCache',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'fromRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'toRevision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'json',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'write_diff_cache_fk_0',
          columns: ['documentId'],
          referenceTable: 'document',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'write_diff_cache_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fromRevision',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'toRevision',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'write_diff_cache_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'brin',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'write_theme',
      dartName: 'WriteTheme',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'uuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'ownerId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'isBuiltin',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'builtinKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'schemaVersion',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'json',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contentHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'deletedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'write_theme_fk_0',
          columns: ['ownerId'],
          referenceTable: 'user_profile',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'write_theme_uuid_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'write_theme_owner_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'ownerId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'deletedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'write_theme_builtin_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'builtinKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'write_theme_revision',
      dartName: 'WriteThemeRevision',
      schema: 'public',
      module: 'wonky',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'themeId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'json',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'savedById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'actorKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActorKind',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'write_theme_revision_fk_0',
          columns: ['themeId'],
          referenceTable: 'write_theme',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'write_theme_rev_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'themeId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'version',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ihl3axv2.AclFutureCallFanOutModel) {
      return _ihl3axv2.AclFutureCallFanOutModel.fromJson(data) as T;
    }
    if (t == _icgheary.BoardFutureCallSummarizeModel) {
      return _icgheary.BoardFutureCallSummarizeModel.fromJson(data) as T;
    }
    if (t == _if8h900w.BoardFutureCallTriageModel) {
      return _if8h900w.BoardFutureCallTriageModel.fromJson(data) as T;
    }
    if (t == _ixkvo7h1.BoardFutureCallWritePromptModel) {
      return _ixkvo7h1.BoardFutureCallWritePromptModel.fromJson(data) as T;
    }
    if (t == _ip0bwzb4.BoardGithubFutureCallHandleModel) {
      return _ip0bwzb4.BoardGithubFutureCallHandleModel.fromJson(data) as T;
    }
    if (t == _i5z3lvv6.BoardGithubFutureCallReviewModel) {
      return _i5z3lvv6.BoardGithubFutureCallReviewModel.fromJson(data) as T;
    }
    if (t == _ilpvgw0t.FilePreviewFutureCallGenerateModel) {
      return _ilpvgw0t.FilePreviewFutureCallGenerateModel.fromJson(data) as T;
    }
    if (t == _inb6x2l0.NotificationEmailFutureCallSendModel) {
      return _inb6x2l0.NotificationEmailFutureCallSendModel.fromJson(data) as T;
    }
    if (t == _il37cz87.PublicationsFutureCallDeliverModel) {
      return _il37cz87.PublicationsFutureCallDeliverModel.fromJson(data) as T;
    }
    if (t == _io4auc29.StorageFutureCallRefreshItemSizeModel) {
      return _io4auc29.StorageFutureCallRefreshItemSizeModel.fromJson(data)
          as T;
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
    if (t == _ixdmbuaj.ItemViewDay) {
      return _ixdmbuaj.ItemViewDay.fromJson(data) as T;
    }
    if (t == _ifmsnq1y.UserActivitySettings) {
      return _ifmsnq1y.UserActivitySettings.fromJson(data) as T;
    }
    if (t == _iyja8k5e.AiApplyMode) {
      return _iyja8k5e.AiApplyMode.fromJson(data) as T;
    }
    if (t == _iuq1eobh.AiPreviewRecord) {
      return _iuq1eobh.AiPreviewRecord.fromJson(data) as T;
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
    if (t == _ivv7zvxt.AiUserKey) {
      return _ivv7zvxt.AiUserKey.fromJson(data) as T;
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
    if (t == _ixradasp.AnalyticsCohort) {
      return _ixradasp.AnalyticsCohort.fromJson(data) as T;
    }
    if (t == _innm1rwe.AnalyticsCount) {
      return _innm1rwe.AnalyticsCount.fromJson(data) as T;
    }
    if (t == _is2u4stz.AnalyticsDay) {
      return _is2u4stz.AnalyticsDay.fromJson(data) as T;
    }
    if (t == _i61uxw4p.AnalyticsOverview) {
      return _i61uxw4p.AnalyticsOverview.fromJson(data) as T;
    }
    if (t == _id3chnrt.UsageApp) {
      return _id3chnrt.UsageApp.fromJson(data) as T;
    }
    if (t == _iamkojeb.UsageCounterDay) {
      return _iamkojeb.UsageCounterDay.fromJson(data) as T;
    }
    if (t == _ibanfcrx.UsageDayStats) {
      return _ibanfcrx.UsageDayStats.fromJson(data) as T;
    }
    if (t == _ik0bapqg.UserActivityDay) {
      return _ik0bapqg.UserActivityDay.fromJson(data) as T;
    }
    if (t == _icowsqvh.BoardAiUsage) {
      return _icowsqvh.BoardAiUsage.fromJson(data) as T;
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
    if (t == _i5r22jl8.BoardGithubDelivery) {
      return _i5r22jl8.BoardGithubDelivery.fromJson(data) as T;
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
    if (t == _idxofexa.BoardModerationLog) {
      return _idxofexa.BoardModerationLog.fromJson(data) as T;
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
    if (t == _i36hp4a6.BoardPullRequest) {
      return _i36hp4a6.BoardPullRequest.fromJson(data) as T;
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
    if (t == _i4piktk8.ClusterBusBatch) {
      return _i4piktk8.ClusterBusBatch.fromJson(data) as T;
    }
    if (t == _ipkzl9y7.ClusterSignal) {
      return _ipkzl9y7.ClusterSignal.fromJson(data) as T;
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
    if (t == _ix3p7034.CommentSignal) {
      return _ix3p7034.CommentSignal.fromJson(data) as T;
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
    if (t == _i0atxq9l.DriveChangeSignal) {
      return _i0atxq9l.DriveChangeSignal.fromJson(data) as T;
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
    if (t == _iu565i0a.FeedbackReport) {
      return _iu565i0a.FeedbackReport.fromJson(data) as T;
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
    if (t == _iymtdptb.ImageProfile) {
      return _iymtdptb.ImageProfile.fromJson(data) as T;
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
    if (t == _iqsxdr4a.NotificationSignal) {
      return _iqsxdr4a.NotificationSignal.fromJson(data) as T;
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
    if (t == _i7dp90q0.PresenceBusMessage) {
      return _i7dp90q0.PresenceBusMessage.fromJson(data) as T;
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
    if (t == _ikkxb56h.Publication) {
      return _ikkxb56h.Publication.fromJson(data) as T;
    }
    if (t == _i5vk42yw.PublicationBlock) {
      return _i5vk42yw.PublicationBlock.fromJson(data) as T;
    }
    if (t == _i9g6l3wu.PublicationCard) {
      return _i9g6l3wu.PublicationCard.fromJson(data) as T;
    }
    if (t == _i0a1sw0a.PublicationCheckResult) {
      return _i0a1sw0a.PublicationCheckResult.fromJson(data) as T;
    }
    if (t == _iqa48qn0.PublicationConsent) {
      return _iqa48qn0.PublicationConsent.fromJson(data) as T;
    }
    if (t == _ihiygfti.PublicationDelivery) {
      return _ihiygfti.PublicationDelivery.fromJson(data) as T;
    }
    if (t == _iz1gego0.PublicationDeliveryView) {
      return _iz1gego0.PublicationDeliveryView.fromJson(data) as T;
    }
    if (t == _iucp51pg.PublicationFieldMode) {
      return _iucp51pg.PublicationFieldMode.fromJson(data) as T;
    }
    if (t == _i63wbtw0.PublicationFields) {
      return _i63wbtw0.PublicationFields.fromJson(data) as T;
    }
    if (t == _iv6bey6s.PublicationInput) {
      return _iv6bey6s.PublicationInput.fromJson(data) as T;
    }
    if (t == _i1u9dlta.PublicationModerator) {
      return _i1u9dlta.PublicationModerator.fromJson(data) as T;
    }
    if (t == _ij9tsbn9.PublicationModeratorView) {
      return _ij9tsbn9.PublicationModeratorView.fromJson(data) as T;
    }
    if (t == _ivvukfve.PublicationOpenSubmission) {
      return _ivvukfve.PublicationOpenSubmission.fromJson(data) as T;
    }
    if (t == _iyqlj2kr.PublicationSecret) {
      return _iyqlj2kr.PublicationSecret.fromJson(data) as T;
    }
    if (t == _i5i48220.PublicationSettings) {
      return _i5i48220.PublicationSettings.fromJson(data) as T;
    }
    if (t == _ipbg6o7y.Submission) {
      return _ipbg6o7y.Submission.fromJson(data) as T;
    }
    if (t == _i49gtkgr.SubmissionAsset) {
      return _i49gtkgr.SubmissionAsset.fromJson(data) as T;
    }
    if (t == _ip6l83ta.SubmissionDeliveryState) {
      return _ip6l83ta.SubmissionDeliveryState.fromJson(data) as T;
    }
    if (t == _i71zy0hy.SubmissionRevision) {
      return _i71zy0hy.SubmissionRevision.fromJson(data) as T;
    }
    if (t == _iegijpud.SubmissionRevisionView) {
      return _iegijpud.SubmissionRevisionView.fromJson(data) as T;
    }
    if (t == _ijb8v3k4.SubmissionStarted) {
      return _ijb8v3k4.SubmissionStarted.fromJson(data) as T;
    }
    if (t == _i7hbulg4.SubmissionStatus) {
      return _i7hbulg4.SubmissionStatus.fromJson(data) as T;
    }
    if (t == _iq9uje8l.SubmissionValues) {
      return _iq9uje8l.SubmissionValues.fromJson(data) as T;
    }
    if (t == _iakndug7.SubmissionView) {
      return _iakndug7.SubmissionView.fromJson(data) as T;
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
    if (t == _iyewfisw.RevBusMessage) {
      return _iyewfisw.RevBusMessage.fromJson(data) as T;
    }
    if (t == _ip7h3lg0.RevFile) {
      return _ip7h3lg0.RevFile.fromJson(data) as T;
    }
    if (t == _ihwy023l.RevFileInfo) {
      return _ihwy023l.RevFileInfo.fromJson(data) as T;
    }
    if (t == _iwkehf4e.RevFileKind) {
      return _iwkehf4e.RevFileKind.fromJson(data) as T;
    }
    if (t == _ivfqwl6l.RevHookState) {
      return _ivfqwl6l.RevHookState.fromJson(data) as T;
    }
    if (t == _iax01zbg.RevOp) {
      return _iax01zbg.RevOp.fromJson(data) as T;
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
    if (t == _ibw3povl.ServerChangeRecord) {
      return _ibw3povl.ServerChangeRecord.fromJson(data) as T;
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
    if (t == _if4kaxov.StorageReservation) {
      return _if4kaxov.StorageReservation.fromJson(data) as T;
    }
    if (t == _is05u0nw.UserStorage) {
      return _is05u0nw.UserStorage.fromJson(data) as T;
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
    if (t == _ijodrcyd.PersonalAccessToken) {
      return _ijodrcyd.PersonalAccessToken.fromJson(data) as T;
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
    if (t == _ibe5uno1.ItemVersionState) {
      return _ibe5uno1.ItemVersionState.fromJson(data) as T;
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
    if (t == _i5vk0z7t.AiFunctionCache) {
      return _i5vk0z7t.AiFunctionCache.fromJson(data) as T;
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
    if (t == _i74ohdg2.SheetsImportJob) {
      return _i74ohdg2.SheetsImportJob.fromJson(data) as T;
    }
    if (t == _iaf43n69.SheetsImportProgress) {
      return _iaf43n69.SheetsImportProgress.fromJson(data) as T;
    }
    if (t == _i8d83qca.SheetsImportStatus) {
      return _i8d83qca.SheetsImportStatus.fromJson(data) as T;
    }
    if (t == _ik5lpvx4.CellHistory) {
      return _ik5lpvx4.CellHistory.fromJson(data) as T;
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
    if (t == _i3p6on16.Banding) {
      return _i3p6on16.Banding.fromJson(data) as T;
    }
    if (t == _iofnuqg9.BasicFilter) {
      return _iofnuqg9.BasicFilter.fromJson(data) as T;
    }
    if (t == _ifc5vn9h.Cell) {
      return _ifc5vn9h.Cell.fromJson(data) as T;
    }
    if (t == _iy4zsn6m.ConditionalFormatRule) {
      return _iy4zsn6m.ConditionalFormatRule.fromJson(data) as T;
    }
    if (t == _i5c2bsv2.DataValidationRule) {
      return _i5c2bsv2.DataValidationRule.fromJson(data) as T;
    }
    if (t == _i145vl5m.DimensionGroup) {
      return _i145vl5m.DimensionGroup.fromJson(data) as T;
    }
    if (t == _iye9c0co.EmbeddedObject) {
      return _iye9c0co.EmbeddedObject.fromJson(data) as T;
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
    if (t == _igzd7u0m.FilterView) {
      return _igzd7u0m.FilterView.fromJson(data) as T;
    }
    if (t == _iiq43rv8.Macro) {
      return _iiq43rv8.Macro.fromJson(data) as T;
    }
    if (t == _i57rr32y.MergedRange) {
      return _i57rr32y.MergedRange.fromJson(data) as T;
    }
    if (t == _irrybuvb.NamedRange) {
      return _irrybuvb.NamedRange.fromJson(data) as T;
    }
    if (t == _iz580og3.PivotTable) {
      return _iz580og3.PivotTable.fromJson(data) as T;
    }
    if (t == _iz1b7y52.ProtectedRange) {
      return _iz1b7y52.ProtectedRange.fromJson(data) as T;
    }
    if (t == _ibdybin0.ScriptBuild) {
      return _ibdybin0.ScriptBuild.fromJson(data) as T;
    }
    if (t == _iplsajic.ScriptFile) {
      return _iplsajic.ScriptFile.fromJson(data) as T;
    }
    if (t == _iy6gs0qh.ScriptProject) {
      return _iy6gs0qh.ScriptProject.fromJson(data) as T;
    }
    if (t == _ig9hff0r.ScriptProperty) {
      return _ig9hff0r.ScriptProperty.fromJson(data) as T;
    }
    if (t == _irlm292d.ScriptTrigger) {
      return _irlm292d.ScriptTrigger.fromJson(data) as T;
    }
    if (t == _i8c5x9aj.Sheet) {
      return _i8c5x9aj.Sheet.fromJson(data) as T;
    }
    if (t == _i6chd4x2.SheetColumn) {
      return _i6chd4x2.SheetColumn.fromJson(data) as T;
    }
    if (t == _i4k3x536.SheetRow) {
      return _i4k3x536.SheetRow.fromJson(data) as T;
    }
    if (t == _ib6gxu4b.Spreadsheet) {
      return _ib6gxu4b.Spreadsheet.fromJson(data) as T;
    }
    if (t == _ijtj1mph.ScriptUserProperty) {
      return _ijtj1mph.ScriptUserProperty.fromJson(data) as T;
    }
    if (t == _iaehez21.SheetsActivitySummary) {
      return _iaehez21.SheetsActivitySummary.fromJson(data) as T;
    }
    if (t == _i9yjzgjk.SheetsContributorStat) {
      return _i9yjzgjk.SheetsContributorStat.fromJson(data) as T;
    }
    if (t == _iwl8v9t3.SheetsSnapshotIndex) {
      return _iwl8v9t3.SheetsSnapshotIndex.fromJson(data) as T;
    }
    if (t == _ibv2hdjr.ScriptAuthorization) {
      return _ibv2hdjr.ScriptAuthorization.fromJson(data) as T;
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
    if (t == _i4e1yb8z.ScriptJob) {
      return _i4e1yb8z.ScriptJob.fromJson(data) as T;
    }
    if (t == _itn7c5zm.ScriptQuotaUsage) {
      return _itn7c5zm.ScriptQuotaUsage.fromJson(data) as T;
    }
    if (t == _is0mvar3.ScriptRunResponse) {
      return _is0mvar3.ScriptRunResponse.fromJson(data) as T;
    }
    if (t == _iy0fj18f.ScriptRuntimeKind) {
      return _iy0fj18f.ScriptRuntimeKind.fromJson(data) as T;
    }
    if (t == _ixysij0q.ScriptTriggerState) {
      return _ixysij0q.ScriptTriggerState.fromJson(data) as T;
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
    if (t == _ihkglt8b.ChartLink) {
      return _ihkglt8b.ChartLink.fromJson(data) as T;
    }
    if (t == _i6svv371.CodeState) {
      return _i6svv371.CodeState.fromJson(data) as T;
    }
    if (t == _ioalf2ve.Deck) {
      return _ioalf2ve.Deck.fromJson(data) as T;
    }
    if (t == _i5vaufan.DeckTheme) {
      return _i5vaufan.DeckTheme.fromJson(data) as T;
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
    if (t == _ipsr29xb.Slide) {
      return _ipsr29xb.Slide.fromJson(data) as T;
    }
    if (t == _izfj14nk.SlideBuild) {
      return _izfj14nk.SlideBuild.fromJson(data) as T;
    }
    if (t == _ih1q77t5.SlideElement) {
      return _ih1q77t5.SlideElement.fromJson(data) as T;
    }
    if (t == _ic2hhlok.SlideGroup) {
      return _ic2hhlok.SlideGroup.fromJson(data) as T;
    }
    if (t == _i3k3vjpp.SlideLayout) {
      return _i3k3vjpp.SlideLayout.fromJson(data) as T;
    }
    if (t == _igjrafa0.SlideMaster) {
      return _igjrafa0.SlideMaster.fromJson(data) as T;
    }
    if (t == _iewd9d8j.SlideTableAxis) {
      return _iewd9d8j.SlideTableAxis.fromJson(data) as T;
    }
    if (t == _ibnoy0fr.SlideTableCell) {
      return _ibnoy0fr.SlideTableCell.fromJson(data) as T;
    }
    if (t == _ildgqgkz.PresentationBusMessage) {
      return _ildgqgkz.PresentationBusMessage.fromJson(data) as T;
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
    if (t == _iy6ry83r.SlidesSnapshotIndex) {
      return _iy6ry83r.SlidesSnapshotIndex.fromJson(data) as T;
    }
    if (t == _iilidizm.HeadlessChange) {
      return _iilidizm.HeadlessChange.fromJson(data) as T;
    }
    if (t == _icpkpcrn.DocAck) {
      return _icpkpcrn.DocAck.fromJson(data) as T;
    }
    if (t == _i8zfu67r.DocBusMessage) {
      return _i8zfu67r.DocBusMessage.fromJson(data) as T;
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
    if (t == _ixppud51.DocumentImportReport) {
      return _ixppud51.DocumentImportReport.fromJson(data) as T;
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
    if (t == _ig4xquf5.WriteDiffCache) {
      return _ig4xquf5.WriteDiffCache.fromJson(data) as T;
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
    if (t == _is.getType<_ihl3axv2.AclFutureCallFanOutModel?>()) {
      return (data != null
              ? _ihl3axv2.AclFutureCallFanOutModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_icgheary.BoardFutureCallSummarizeModel?>()) {
      return (data != null
              ? _icgheary.BoardFutureCallSummarizeModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_if8h900w.BoardFutureCallTriageModel?>()) {
      return (data != null
              ? _if8h900w.BoardFutureCallTriageModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ixkvo7h1.BoardFutureCallWritePromptModel?>()) {
      return (data != null
              ? _ixkvo7h1.BoardFutureCallWritePromptModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ip0bwzb4.BoardGithubFutureCallHandleModel?>()) {
      return (data != null
              ? _ip0bwzb4.BoardGithubFutureCallHandleModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i5z3lvv6.BoardGithubFutureCallReviewModel?>()) {
      return (data != null
              ? _i5z3lvv6.BoardGithubFutureCallReviewModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ilpvgw0t.FilePreviewFutureCallGenerateModel?>()) {
      return (data != null
              ? _ilpvgw0t.FilePreviewFutureCallGenerateModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_inb6x2l0.NotificationEmailFutureCallSendModel?>()) {
      return (data != null
              ? _inb6x2l0.NotificationEmailFutureCallSendModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_il37cz87.PublicationsFutureCallDeliverModel?>()) {
      return (data != null
              ? _il37cz87.PublicationsFutureCallDeliverModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_io4auc29.StorageFutureCallRefreshItemSizeModel?>()) {
      return (data != null
              ? _io4auc29.StorageFutureCallRefreshItemSizeModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izr1y672.ActivityDashboard?>()) {
      return (data != null ? _izr1y672.ActivityDashboard.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iatdjl5p.ActivityEvent?>()) {
      return (data != null ? _iatdjl5p.ActivityEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_isa7sjzq.ActivityEventView?>()) {
      return (data != null ? _isa7sjzq.ActivityEventView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ighcq381.ActivityTrendPoint?>()) {
      return (data != null ? _ighcq381.ActivityTrendPoint.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i50cy468.ActivityType?>()) {
      return (data != null ? _i50cy468.ActivityType.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ikcwdr17.ActivityViewer?>()) {
      return (data != null ? _ikcwdr17.ActivityViewer.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixdmbuaj.ItemViewDay?>()) {
      return (data != null ? _ixdmbuaj.ItemViewDay.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ifmsnq1y.UserActivitySettings?>()) {
      return (data != null
              ? _ifmsnq1y.UserActivitySettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iyja8k5e.AiApplyMode?>()) {
      return (data != null ? _iyja8k5e.AiApplyMode.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iuq1eobh.AiPreviewRecord?>()) {
      return (data != null ? _iuq1eobh.AiPreviewRecord.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ir7z75mb.AiProvider?>()) {
      return (data != null ? _ir7z75mb.AiProvider.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ic2q2fwi.AiProviderKeyView?>()) {
      return (data != null ? _ic2q2fwi.AiProviderKeyView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iviyoyk9.AiQuality?>()) {
      return (data != null ? _iviyoyk9.AiQuality.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i7i53on7.AiUsage?>()) {
      return (data != null ? _i7i53on7.AiUsage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivv7zvxt.AiUserKey?>()) {
      return (data != null ? _ivv7zvxt.AiUserKey.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_imx2nn1q.AiUserSetting?>()) {
      return (data != null ? _imx2nn1q.AiUserSetting.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ic7e83wd.AssistantContextHints?>()) {
      return (data != null
              ? _ic7e83wd.AssistantContextHints.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_imp4tsxo.AssistantEvent?>()) {
      return (data != null ? _imp4tsxo.AssistantEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_id6kvqt9.AssistantEventType?>()) {
      return (data != null ? _id6kvqt9.AssistantEventType.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8cittxq.AssistantMessage?>()) {
      return (data != null ? _i8cittxq.AssistantMessage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4rkdm2k.AssistantMessageView?>()) {
      return (data != null
              ? _i4rkdm2k.AssistantMessageView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ia2m3j3v.AssistantStatus?>()) {
      return (data != null ? _ia2m3j3v.AssistantStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaq6rutx.AssistantThread?>()) {
      return (data != null ? _iaq6rutx.AssistantThread.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4iv0swm.AssistantThreadDetail?>()) {
      return (data != null
              ? _i4iv0swm.AssistantThreadDetail.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iohdfqf1.AssistantThreadView?>()) {
      return (data != null
              ? _iohdfqf1.AssistantThreadView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i8ghcs7p.InlineAiEvent?>()) {
      return (data != null ? _i8ghcs7p.InlineAiEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6pcz5z6.InlineAiEventType?>()) {
      return (data != null ? _i6pcz5z6.InlineAiEventType.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4m43iwr.InlineAiRequest?>()) {
      return (data != null ? _i4m43iwr.InlineAiRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ie0jt2ne.ProofreadEvent?>()) {
      return (data != null ? _ie0jt2ne.ProofreadEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivmxemza.ProofreadIssue?>()) {
      return (data != null ? _ivmxemza.ProofreadIssue.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixradasp.AnalyticsCohort?>()) {
      return (data != null ? _ixradasp.AnalyticsCohort.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_innm1rwe.AnalyticsCount?>()) {
      return (data != null ? _innm1rwe.AnalyticsCount.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_is2u4stz.AnalyticsDay?>()) {
      return (data != null ? _is2u4stz.AnalyticsDay.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i61uxw4p.AnalyticsOverview?>()) {
      return (data != null ? _i61uxw4p.AnalyticsOverview.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_id3chnrt.UsageApp?>()) {
      return (data != null ? _id3chnrt.UsageApp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iamkojeb.UsageCounterDay?>()) {
      return (data != null ? _iamkojeb.UsageCounterDay.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibanfcrx.UsageDayStats?>()) {
      return (data != null ? _ibanfcrx.UsageDayStats.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ik0bapqg.UserActivityDay?>()) {
      return (data != null ? _ik0bapqg.UserActivityDay.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icowsqvh.BoardAiUsage?>()) {
      return (data != null ? _icowsqvh.BoardAiUsage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i0ag0upm.BoardArea?>()) {
      return (data != null ? _i0ag0upm.BoardArea.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ika8r7fc.BoardAuthor?>()) {
      return (data != null ? _ika8r7fc.BoardAuthor.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ilo15wk2.BoardBundleSuggestion?>()) {
      return (data != null
              ? _ilo15wk2.BoardBundleSuggestion.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iin47lv0.BoardBundleSuggestionView?>()) {
      return (data != null
              ? _iin47lv0.BoardBundleSuggestionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijz5flk6.BoardComment?>()) {
      return (data != null ? _ijz5flk6.BoardComment.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ipkjmsg5.BoardCommentView?>()) {
      return (data != null ? _ipkjmsg5.BoardCommentView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iswbp1jv.BoardCounts?>()) {
      return (data != null ? _iswbp1jv.BoardCounts.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ita8snxr.BoardEventKind?>()) {
      return (data != null ? _ita8snxr.BoardEventKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0y7d0xd.BoardFlag?>()) {
      return (data != null ? _i0y7d0xd.BoardFlag.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iwc3b6vo.BoardFlagReason?>()) {
      return (data != null ? _iwc3b6vo.BoardFlagReason.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5pjfe5s.BoardFlagView?>()) {
      return (data != null ? _i5pjfe5s.BoardFlagView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5r22jl8.BoardGithubDelivery?>()) {
      return (data != null
              ? _i5r22jl8.BoardGithubDelivery.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_igcoqerx.BoardListQuery?>()) {
      return (data != null ? _igcoqerx.BoardListQuery.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iu9hvv8z.BoardMe?>()) {
      return (data != null ? _iu9hvv8z.BoardMe.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_in0hwjmy.BoardModeration?>()) {
      return (data != null ? _in0hwjmy.BoardModeration.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5jfu168.BoardModerationAction?>()) {
      return (data != null
              ? _i5jfu168.BoardModerationAction.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_idxofexa.BoardModerationLog?>()) {
      return (data != null ? _idxofexa.BoardModerationLog.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i7xps6dm.BoardPost?>()) {
      return (data != null ? _i7xps6dm.BoardPost.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_izvgi5ni.BoardPostDraft?>()) {
      return (data != null ? _izvgi5ni.BoardPostDraft.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibl25moa.BoardPostEvent?>()) {
      return (data != null ? _ibl25moa.BoardPostEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iui4x9zg.BoardPostKind?>()) {
      return (data != null ? _iui4x9zg.BoardPostKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iq3f61ec.BoardPostListItem?>()) {
      return (data != null ? _iq3f61ec.BoardPostListItem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i1stsytz.BoardPostPage?>()) {
      return (data != null ? _i1stsytz.BoardPostPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_il200dga.BoardPostStatus?>()) {
      return (data != null ? _il200dga.BoardPostStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijjd81zg.BoardPostView?>()) {
      return (data != null ? _ijjd81zg.BoardPostView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i36hp4a6.BoardPullRequest?>()) {
      return (data != null ? _i36hp4a6.BoardPullRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_im7v2irk.BoardReviewCounts?>()) {
      return (data != null ? _im7v2irk.BoardReviewCounts.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_id33cro1.BoardReviewItem?>()) {
      return (data != null ? _id33cro1.BoardReviewItem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_izs2n8vy.BoardReviewSection?>()) {
      return (data != null ? _izs2n8vy.BoardReviewSection.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ieemxbgb.BoardSignal?>()) {
      return (data != null ? _ieemxbgb.BoardSignal.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_in3cjdcj.BoardSimilarPost?>()) {
      return (data != null ? _in3cjdcj.BoardSimilarPost.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivbgicm7.BoardSize?>()) {
      return (data != null ? _ivbgicm7.BoardSize.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itz4727j.BoardSort?>()) {
      return (data != null ? _itz4727j.BoardSort.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i2gir90g.BoardTargetKind?>()) {
      return (data != null ? _i2gir90g.BoardTargetKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv26y3a1.BoardTask?>()) {
      return (data != null ? _iv26y3a1.BoardTask.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_illpt7x2.BoardTaskPage?>()) {
      return (data != null ? _illpt7x2.BoardTaskPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idsjzf6h.BoardTaskRef?>()) {
      return (data != null ? _idsjzf6h.BoardTaskRef.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i4a2ekwp.BoardTaskStatus?>()) {
      return (data != null ? _i4a2ekwp.BoardTaskStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifz7dmuf.BoardTaskView?>()) {
      return (data != null ? _ifz7dmuf.BoardTaskView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iso7mdvm.BoardTriageState?>()) {
      return (data != null ? _iso7mdvm.BoardTriageState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i516sz1w.BoardUserProfile?>()) {
      return (data != null ? _i516sz1w.BoardUserProfile.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifuo09i6.BoardVote?>()) {
      return (data != null ? _ifuo09i6.BoardVote.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie24iiog.BoardVoteResult?>()) {
      return (data != null ? _ie24iiog.BoardVoteResult.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4piktk8.ClusterBusBatch?>()) {
      return (data != null ? _i4piktk8.ClusterBusBatch.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipkzl9y7.ClusterSignal?>()) {
      return (data != null ? _ipkzl9y7.ClusterSignal.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iyixppck.Comment?>()) {
      return (data != null ? _iyixppck.Comment.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iw81twtc.CommentAnchorKind?>()) {
      return (data != null ? _iw81twtc.CommentAnchorKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imlsyj2p.CommentEvent?>()) {
      return (data != null ? _imlsyj2p.CommentEvent.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ih1mb6x5.CommentEventKind?>()) {
      return (data != null ? _ih1mb6x5.CommentEventKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_il5y6tzr.CommentFilter?>()) {
      return (data != null ? _il5y6tzr.CommentFilter.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ix3p7034.CommentSignal?>()) {
      return (data != null ? _ix3p7034.CommentSignal.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iowdswxe.CommentStatus?>()) {
      return (data != null ? _iowdswxe.CommentStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i94wr3td.CommentSystemEvent?>()) {
      return (data != null ? _i94wr3td.CommentSystemEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijog60vm.CommentThread?>()) {
      return (data != null ? _ijog60vm.CommentThread.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i818olql.CommentThreadView?>()) {
      return (data != null ? _i818olql.CommentThreadView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4xrxro7.CommentView?>()) {
      return (data != null ? _i4xrxro7.CommentView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ii98prcs.AccessRole?>()) {
      return (data != null ? _ii98prcs.AccessRole.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i2wc4tyi.ActorKind?>()) {
      return (data != null ? _i2wc4tyi.ActorKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_inb0isem.WonkyErrorCode?>()) {
      return (data != null ? _inb0isem.WonkyErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igdswlrw.WonkyException?>()) {
      return (data != null ? _igdswlrw.WonkyException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iktwt5zz.DriveChange?>()) {
      return (data != null ? _iktwt5zz.DriveChange.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ijoqbs82.DriveChangeKind?>()) {
      return (data != null ? _ijoqbs82.DriveChangeKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0atxq9l.DriveChangeSignal?>()) {
      return (data != null ? _i0atxq9l.DriveChangeSignal.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ig2nixhn.DriveImportOptions?>()) {
      return (data != null ? _ig2nixhn.DriveImportOptions.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_inge8yy2.DriveItem?>()) {
      return (data != null ? _inge8yy2.DriveItem.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i8mh39wa.DriveItemKind?>()) {
      return (data != null ? _i8mh39wa.DriveItemKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0g2m831.DriveItemUserState?>()) {
      return (data != null ? _i0g2m831.DriveItemUserState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_infxyf98.DriveItemView?>()) {
      return (data != null ? _infxyf98.DriveItemView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivypvw0m.DriveListFilter?>()) {
      return (data != null ? _ivypvw0m.DriveListFilter.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iavdhzsq.DriveListPage?>()) {
      return (data != null ? _iavdhzsq.DriveListPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_if1dhg5z.DriveOwnerFilter?>()) {
      return (data != null ? _if1dhg5z.DriveOwnerFilter.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6k3d1nc.DriveSearchFilters?>()) {
      return (data != null ? _i6k3d1nc.DriveSearchFilters.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iu13r4v2.DriveSort?>()) {
      return (data != null ? _iu13r4v2.DriveSort.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ix0g8yw4.DriveSortField?>()) {
      return (data != null ? _ix0g8yw4.DriveSortField.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipww3kqy.DriveView?>()) {
      return (data != null ? _ipww3kqy.DriveView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iez45i4u.FileCategory?>()) {
      return (data != null ? _iez45i4u.FileCategory.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ilt75p4e.FileUploadProgress?>()) {
      return (data != null ? _ilt75p4e.FileUploadProgress.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iqpb2qv1.FileUploadRequest?>()) {
      return (data != null ? _iqpb2qv1.FileUploadRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imf3tnfq.FileUploadStart?>()) {
      return (data != null ? _imf3tnfq.FileUploadStart.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ia04wt6m.FileUploadState?>()) {
      return (data != null ? _ia04wt6m.FileUploadState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i68yhxa0.ImportReportView?>()) {
      return (data != null ? _i68yhxa0.ImportReportView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i48sm9f2.ImportWarningView?>()) {
      return (data != null ? _i48sm9f2.ImportWarningView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8hnug6t.StorageListFilter?>()) {
      return (data != null ? _i8hnug6t.StorageListFilter.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i26hsnhw.StorageUsage?>()) {
      return (data != null ? _i26hsnhw.StorageUsage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iiedu4vz.TemplateCategory?>()) {
      return (data != null ? _iiedu4vz.TemplateCategory.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6rg3vdh.TemplatePreviewStyle?>()) {
      return (data != null
              ? _i6rg3vdh.TemplatePreviewStyle.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i2ox7ta1.TemplateView?>()) {
      return (data != null ? _i2ox7ta1.TemplateView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_io3ccr8w.UploadConflictMode?>()) {
      return (data != null ? _io3ccr8w.UploadConflictMode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv1sk0e8.FeedbackKind?>()) {
      return (data != null ? _iv1sk0e8.FeedbackKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iu565i0a.FeedbackReport?>()) {
      return (data != null ? _iu565i0a.FeedbackReport.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilhpki98.FeedbackSubmission?>()) {
      return (data != null ? _ilhpki98.FeedbackSubmission.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_irrzp8p9.FileUploadTicket?>()) {
      return (data != null ? _irrzp8p9.FileUploadTicket.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_itzt3x6d.FileUrlView?>()) {
      return (data != null ? _itzt3x6d.FileUrlView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iymtdptb.ImageProfile?>()) {
      return (data != null ? _iymtdptb.ImageProfile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_im8eh74x.StoredFile?>()) {
      return (data != null ? _im8eh74x.StoredFile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i45dmz4a.StoredFileKind?>()) {
      return (data != null ? _i45dmz4a.StoredFileKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ik7q11oy.StoredFileStatus?>()) {
      return (data != null ? _ik7q11oy.StoredFileStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ichw8k0i.UiBridgeCancel?>()) {
      return (data != null ? _ichw8k0i.UiBridgeCancel.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ichw8k0i.UiBridgeHello?>()) {
      return (data != null ? _ichw8k0i.UiBridgeHello.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ichw8k0i.UiBridgeRequest?>()) {
      return (data != null ? _ichw8k0i.UiBridgeRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ichw8k0i.UiBridgeResponse?>()) {
      return (data != null ? _ichw8k0i.UiBridgeResponse.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ichw8k0i.UiBridgeStatus?>()) {
      return (data != null ? _ichw8k0i.UiBridgeStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ichw8k0i.UiBridgeStop?>()) {
      return (data != null ? _ichw8k0i.UiBridgeStop.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ichw8k0i.UiBridgeWelcome?>()) {
      return (data != null ? _ichw8k0i.UiBridgeWelcome.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivk6eyvx.FeatureFlags?>()) {
      return (data != null ? _ivk6eyvx.FeatureFlags.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ib575x0y.ProtocolInfo?>()) {
      return (data != null ? _ib575x0y.ProtocolInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i28el0at.ServerLimits?>()) {
      return (data != null ? _i28el0at.ServerLimits.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iexg4yzt.NotificationEvent?>()) {
      return (data != null ? _iexg4yzt.NotificationEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iqlnbbfp.NotificationKind?>()) {
      return (data != null ? _iqlnbbfp.NotificationKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3r1eo8q.NotificationPage?>()) {
      return (data != null ? _i3r1eo8q.NotificationPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iqsxdr4a.NotificationSignal?>()) {
      return (data != null ? _iqsxdr4a.NotificationSignal.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_izfzk9h3.NotificationView?>()) {
      return (data != null ? _izfzk9h3.NotificationView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ik59hiyp.UserNotification?>()) {
      return (data != null ? _ik59hiyp.UserNotification.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iylgyc33.Participant?>()) {
      return (data != null ? _iylgyc33.Participant.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i7dp90q0.PresenceBusMessage?>()) {
      return (data != null ? _i7dp90q0.PresenceBusMessage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8r9afjv.PresenceFollowerCount?>()) {
      return (data != null
              ? _i8r9afjv.PresenceFollowerCount.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i8r9afjv.PresenceHints?>()) {
      return (data != null ? _i8r9afjv.PresenceHints.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8r9afjv.PresenceJoined?>()) {
      return (data != null ? _i8r9afjv.PresenceJoined.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8r9afjv.PresenceLeft?>()) {
      return (data != null ? _i8r9afjv.PresenceLeft.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i8r9afjv.PresenceNotice?>()) {
      return (data != null ? _i8r9afjv.PresenceNotice.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8r9afjv.PresenceRoster?>()) {
      return (data != null ? _i8r9afjv.PresenceRoster.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8r9afjv.PresenceUpdated?>()) {
      return (data != null ? _i8r9afjv.PresenceUpdated.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ik055xb9.PresenceState?>()) {
      return (data != null ? _ik055xb9.PresenceState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_isz2sju0.PresenceUpdate?>()) {
      return (data != null ? _isz2sju0.PresenceUpdate.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ikkxb56h.Publication?>()) {
      return (data != null ? _ikkxb56h.Publication.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5vk42yw.PublicationBlock?>()) {
      return (data != null ? _i5vk42yw.PublicationBlock.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i9g6l3wu.PublicationCard?>()) {
      return (data != null ? _i9g6l3wu.PublicationCard.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0a1sw0a.PublicationCheckResult?>()) {
      return (data != null
              ? _i0a1sw0a.PublicationCheckResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqa48qn0.PublicationConsent?>()) {
      return (data != null ? _iqa48qn0.PublicationConsent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ihiygfti.PublicationDelivery?>()) {
      return (data != null
              ? _ihiygfti.PublicationDelivery.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz1gego0.PublicationDeliveryView?>()) {
      return (data != null
              ? _iz1gego0.PublicationDeliveryView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iucp51pg.PublicationFieldMode?>()) {
      return (data != null
              ? _iucp51pg.PublicationFieldMode.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i63wbtw0.PublicationFields?>()) {
      return (data != null ? _i63wbtw0.PublicationFields.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv6bey6s.PublicationInput?>()) {
      return (data != null ? _iv6bey6s.PublicationInput.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i1u9dlta.PublicationModerator?>()) {
      return (data != null
              ? _i1u9dlta.PublicationModerator.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ij9tsbn9.PublicationModeratorView?>()) {
      return (data != null
              ? _ij9tsbn9.PublicationModeratorView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ivvukfve.PublicationOpenSubmission?>()) {
      return (data != null
              ? _ivvukfve.PublicationOpenSubmission.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iyqlj2kr.PublicationSecret?>()) {
      return (data != null ? _iyqlj2kr.PublicationSecret.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5i48220.PublicationSettings?>()) {
      return (data != null
              ? _i5i48220.PublicationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ipbg6o7y.Submission?>()) {
      return (data != null ? _ipbg6o7y.Submission.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i49gtkgr.SubmissionAsset?>()) {
      return (data != null ? _i49gtkgr.SubmissionAsset.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ip6l83ta.SubmissionDeliveryState?>()) {
      return (data != null
              ? _ip6l83ta.SubmissionDeliveryState.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i71zy0hy.SubmissionRevision?>()) {
      return (data != null ? _i71zy0hy.SubmissionRevision.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iegijpud.SubmissionRevisionView?>()) {
      return (data != null
              ? _iegijpud.SubmissionRevisionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijb8v3k4.SubmissionStarted?>()) {
      return (data != null ? _ijb8v3k4.SubmissionStarted.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i7hbulg4.SubmissionStatus?>()) {
      return (data != null ? _i7hbulg4.SubmissionStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iq9uje8l.SubmissionValues?>()) {
      return (data != null ? _iq9uje8l.SubmissionValues.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iakndug7.SubmissionView?>()) {
      return (data != null ? _iakndug7.SubmissionView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ie6clghy.RevAck?>()) {
      return (data != null ? _ie6clghy.RevAck.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6ck957q.RevPing?>()) {
      return (data != null ? _i6ck957q.RevPing.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6ck957q.RevRequestOps?>()) {
      return (data != null ? _i6ck957q.RevRequestOps.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6ck957q.RevSubmit?>()) {
      return (data != null ? _i6ck957q.RevSubmit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie6clghy.RevInit?>()) {
      return (data != null ? _ie6clghy.RevInit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie6clghy.RevPong?>()) {
      return (data != null ? _ie6clghy.RevPong.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie6clghy.RevRejected?>()) {
      return (data != null ? _ie6clghy.RevRejected.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie6clghy.RevRemoteOp?>()) {
      return (data != null ? _ie6clghy.RevRemoteOp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie6clghy.RevResync?>()) {
      return (data != null ? _ie6clghy.RevResync.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie6clghy.RevRoleChanged?>()) {
      return (data != null ? _ie6clghy.RevRoleChanged.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iyewfisw.RevBusMessage?>()) {
      return (data != null ? _iyewfisw.RevBusMessage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ip7h3lg0.RevFile?>()) {
      return (data != null ? _ip7h3lg0.RevFile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihwy023l.RevFileInfo?>()) {
      return (data != null ? _ihwy023l.RevFileInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iwkehf4e.RevFileKind?>()) {
      return (data != null ? _iwkehf4e.RevFileKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivfqwl6l.RevHookState?>()) {
      return (data != null ? _ivfqwl6l.RevHookState.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iax01zbg.RevOp?>()) {
      return (data != null ? _iax01zbg.RevOp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_it4o2pk5.RevOpView?>()) {
      return (data != null ? _it4o2pk5.RevOpView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ium7xjeg.RevPage?>()) {
      return (data != null ? _ium7xjeg.RevPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3q3ua5p.RevPageKind?>()) {
      return (data != null ? _i3q3ua5p.RevPageKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_if03ikx4.RevPageRequest?>()) {
      return (data != null ? _if03ikx4.RevPageRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iilsyt4b.RevRejectCode?>()) {
      return (data != null ? _iilsyt4b.RevRejectCode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibw3povl.ServerChangeRecord?>()) {
      return (data != null ? _ibw3povl.ServerChangeRecord.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8scn8dm.AccessRequest?>()) {
      return (data != null ? _i8scn8dm.AccessRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i7trut12.AccessRequestOutcome?>()) {
      return (data != null
              ? _i7trut12.AccessRequestOutcome.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iimp60a4.AccessRequestView?>()) {
      return (data != null ? _iimp60a4.AccessRequestView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iuzgacy4.DriveItemPermission?>()) {
      return (data != null
              ? _iuzgacy4.DriveItemPermission.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ikeljole.InviteResolution?>()) {
      return (data != null ? _ikeljole.InviteResolution.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ih3711er.ItemSharingSettings?>()) {
      return (data != null
              ? _ih3711er.ItemSharingSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijwxtu30.OwnershipTransfer?>()) {
      return (data != null ? _ijwxtu30.OwnershipTransfer.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iilpsf9g.OwnershipTransferView?>()) {
      return (data != null
              ? _iilpsf9g.OwnershipTransferView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iead0ok9.PermissionView?>()) {
      return (data != null ? _iead0ok9.PermissionView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_it712lg1.ShareLink?>()) {
      return (data != null ? _it712lg1.ShareLink.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iw2xoohn.ShareLinkView?>()) {
      return (data != null ? _iw2xoohn.ShareLinkView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_itd24os1.SharingInfo?>()) {
      return (data != null ? _itd24os1.SharingInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ifxa4vxf.QuotaExceededDetails?>()) {
      return (data != null
              ? _ifxa4vxf.QuotaExceededDetails.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_if4kaxov.StorageReservation?>()) {
      return (data != null ? _if4kaxov.StorageReservation.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_is05u0nw.UserStorage?>()) {
      return (data != null ? _is05u0nw.UserStorage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_izha9j5m.AccessTokenView?>()) {
      return (data != null ? _izha9j5m.AccessTokenView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iq4dupwy.AccountDeletionPreview?>()) {
      return (data != null
              ? _iq4dupwy.AccountDeletionPreview.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i6azdr3n.AppThemeMode?>()) {
      return (data != null ? _i6azdr3n.AppThemeMode.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iru4pv75.CreatedAccessToken?>()) {
      return (data != null ? _iru4pv75.CreatedAccessToken.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijodrcyd.PersonalAccessToken?>()) {
      return (data != null
              ? _ijodrcyd.PersonalAccessToken.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i5lc4gt0.UiDensity?>()) {
      return (data != null ? _i5lc4gt0.UiDensity.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i501u5m5.UserPreferences?>()) {
      return (data != null ? _i501u5m5.UserPreferences.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_id95rrz2.UserPreferencesPatch?>()) {
      return (data != null
              ? _id95rrz2.UserPreferencesPatch.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ihzl7wbq.UserProfile?>()) {
      return (data != null ? _ihzl7wbq.UserProfile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iufqmqtc.UserProfileView?>()) {
      return (data != null ? _iufqmqtc.UserProfileView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6y7tspy.UserSummary?>()) {
      return (data != null ? _i6y7tspy.UserSummary.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i7jb115m.ItemVersion?>()) {
      return (data != null ? _i7jb115m.ItemVersion.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ibe5uno1.ItemVersionState?>()) {
      return (data != null ? _ibe5uno1.ItemVersionState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipbapjbz.ItemVersionView?>()) {
      return (data != null ? _ipbapjbz.ItemVersionView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_in0fdl1f.VersionKind?>()) {
      return (data != null ? _in0fdl1f.VersionKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_in38zbga.VersionRestoreResult?>()) {
      return (data != null
              ? _in38zbga.VersionRestoreResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i5u6d6t4.VersionStorage?>()) {
      return (data != null ? _i5u6d6t4.VersionStorage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5vk0z7t.AiFunctionCache?>()) {
      return (data != null ? _i5vk0z7t.AiFunctionCache.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iuzj1jin.SheetsAiApplyResult?>()) {
      return (data != null
              ? _iuzj1jin.SheetsAiApplyResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iljqbz3a.SheetsAiCellRequest?>()) {
      return (data != null
              ? _iljqbz3a.SheetsAiCellRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_im85lt6z.SheetsAiCellResult?>()) {
      return (data != null ? _im85lt6z.SheetsAiCellResult.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4t3jyqe.SheetsAiPreview?>()) {
      return (data != null ? _i4t3jyqe.SheetsAiPreview.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idzstekp.SheetsAiPreviewCall?>()) {
      return (data != null
              ? _idzstekp.SheetsAiPreviewCall.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i49726iv.SheetsAiPreviewCell?>()) {
      return (data != null
              ? _i49726iv.SheetsAiPreviewCell.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izbpavhd.SheetsFillProposal?>()) {
      return (data != null ? _izbpavhd.SheetsFillProposal.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i1gi0ui2.SheetsFillRow?>()) {
      return (data != null ? _i1gi0ui2.SheetsFillRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i2bhah0l.SheetsFormulaSuggestion?>()) {
      return (data != null
              ? _i2bhah0l.SheetsFormulaSuggestion.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i74ohdg2.SheetsImportJob?>()) {
      return (data != null ? _i74ohdg2.SheetsImportJob.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaf43n69.SheetsImportProgress?>()) {
      return (data != null
              ? _iaf43n69.SheetsImportProgress.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i8d83qca.SheetsImportStatus?>()) {
      return (data != null ? _i8d83qca.SheetsImportStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ik5lpvx4.CellHistory?>()) {
      return (data != null ? _ik5lpvx4.CellHistory.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ij1xvs09.CellHistoryEntry?>()) {
      return (data != null ? _ij1xvs09.CellHistoryEntry.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i09xo3k8.CellHistoryPage?>()) {
      return (data != null ? _i09xo3k8.CellHistoryPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilv3hlxr.RevertResult?>()) {
      return (data != null ? _ilv3hlxr.RevertResult.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ipqum05l.RevertSkip?>()) {
      return (data != null ? _ipqum05l.RevertSkip.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3p6on16.Banding?>()) {
      return (data != null ? _i3p6on16.Banding.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iofnuqg9.BasicFilter?>()) {
      return (data != null ? _iofnuqg9.BasicFilter.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ifc5vn9h.Cell?>()) {
      return (data != null ? _ifc5vn9h.Cell.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iy4zsn6m.ConditionalFormatRule?>()) {
      return (data != null
              ? _iy4zsn6m.ConditionalFormatRule.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i5c2bsv2.DataValidationRule?>()) {
      return (data != null ? _i5c2bsv2.DataValidationRule.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i145vl5m.DimensionGroup?>()) {
      return (data != null ? _i145vl5m.DimensionGroup.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iye9c0co.EmbeddedObject?>()) {
      return (data != null ? _iye9c0co.EmbeddedObject.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilnsyzhq.Dimension?>()) {
      return (data != null ? _ilnsyzhq.Dimension.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihfpm0ve.EmbeddedObjectKind?>()) {
      return (data != null ? _ihfpm0ve.EmbeddedObjectKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iofwzekn.HorizontalAlign?>()) {
      return (data != null ? _iofwzekn.HorizontalAlign.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0z9m4nl.RecalcMode?>()) {
      return (data != null ? _i0z9m4nl.RecalcMode.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_io4oc09s.ScriptBuildStatus?>()) {
      return (data != null ? _io4oc09s.ScriptBuildStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8ne06ql.SheetKind?>()) {
      return (data != null ? _i8ne06ql.SheetKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_irmtoho8.TriggerKind?>()) {
      return (data != null ? _irmtoho8.TriggerKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivf2txqv.VerticalAlign?>()) {
      return (data != null ? _ivf2txqv.VerticalAlign.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iz9rjt8b.WrapStrategy?>()) {
      return (data != null ? _iz9rjt8b.WrapStrategy.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_igzd7u0m.FilterView?>()) {
      return (data != null ? _igzd7u0m.FilterView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iiq43rv8.Macro?>()) {
      return (data != null ? _iiq43rv8.Macro.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i57rr32y.MergedRange?>()) {
      return (data != null ? _i57rr32y.MergedRange.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_irrybuvb.NamedRange?>()) {
      return (data != null ? _irrybuvb.NamedRange.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iz580og3.PivotTable?>()) {
      return (data != null ? _iz580og3.PivotTable.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iz1b7y52.ProtectedRange?>()) {
      return (data != null ? _iz1b7y52.ProtectedRange.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibdybin0.ScriptBuild?>()) {
      return (data != null ? _ibdybin0.ScriptBuild.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iplsajic.ScriptFile?>()) {
      return (data != null ? _iplsajic.ScriptFile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iy6gs0qh.ScriptProject?>()) {
      return (data != null ? _iy6gs0qh.ScriptProject.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ig9hff0r.ScriptProperty?>()) {
      return (data != null ? _ig9hff0r.ScriptProperty.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_irlm292d.ScriptTrigger?>()) {
      return (data != null ? _irlm292d.ScriptTrigger.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8c5x9aj.Sheet?>()) {
      return (data != null ? _i8c5x9aj.Sheet.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6chd4x2.SheetColumn?>()) {
      return (data != null ? _i6chd4x2.SheetColumn.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i4k3x536.SheetRow?>()) {
      return (data != null ? _i4k3x536.SheetRow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ib6gxu4b.Spreadsheet?>()) {
      return (data != null ? _ib6gxu4b.Spreadsheet.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ijtj1mph.ScriptUserProperty?>()) {
      return (data != null ? _ijtj1mph.ScriptUserProperty.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaehez21.SheetsActivitySummary?>()) {
      return (data != null
              ? _iaehez21.SheetsActivitySummary.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i9yjzgjk.SheetsContributorStat?>()) {
      return (data != null
              ? _i9yjzgjk.SheetsContributorStat.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iwl8v9t3.SheetsSnapshotIndex?>()) {
      return (data != null
              ? _iwl8v9t3.SheetsSnapshotIndex.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ibv2hdjr.ScriptAuthorization?>()) {
      return (data != null
              ? _ibv2hdjr.ScriptAuthorization.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_icjzxy6x.ScriptAuthorizationView?>()) {
      return (data != null
              ? _icjzxy6x.ScriptAuthorizationView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iq0xpzf7.ScriptCompileResponse?>()) {
      return (data != null
              ? _iq0xpzf7.ScriptCompileResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i4bc0fek.ScriptExecution?>()) {
      return (data != null ? _i4bc0fek.ScriptExecution.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_inqz9v2t.ScriptExecutionKind?>()) {
      return (data != null
              ? _inqz9v2t.ScriptExecutionKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ira26pfa.ScriptExecutionStatus?>()) {
      return (data != null
              ? _ira26pfa.ScriptExecutionStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_is04pxv8.ScriptFetchResponse?>()) {
      return (data != null
              ? _is04pxv8.ScriptFetchResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i4e1yb8z.ScriptJob?>()) {
      return (data != null ? _i4e1yb8z.ScriptJob.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itn7c5zm.ScriptQuotaUsage?>()) {
      return (data != null ? _itn7c5zm.ScriptQuotaUsage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_is0mvar3.ScriptRunResponse?>()) {
      return (data != null ? _is0mvar3.ScriptRunResponse.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iy0fj18f.ScriptRuntimeKind?>()) {
      return (data != null ? _iy0fj18f.ScriptRuntimeKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixysij0q.ScriptTriggerState?>()) {
      return (data != null ? _ixysij0q.ScriptTriggerState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iwj0qehd.SlidesAiAltText?>()) {
      return (data != null ? _iwj0qehd.SlidesAiAltText.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ix6z7bmu.SlidesAiApplyResult?>()) {
      return (data != null
              ? _ix6z7bmu.SlidesAiApplyResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_isdksxfl.SlidesAiBuildResult?>()) {
      return (data != null
              ? _isdksxfl.SlidesAiBuildResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i154xjj9.SlidesAiDesignRank?>()) {
      return (data != null ? _i154xjj9.SlidesAiDesignRank.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_itoukaix.SlidesAiNote?>()) {
      return (data != null ? _itoukaix.SlidesAiNote.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i225jf90.SlidesAiOutlineRequest?>()) {
      return (data != null
              ? _i225jf90.SlidesAiOutlineRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ioipp9xy.SlidesAiPreview?>()) {
      return (data != null ? _ioipp9xy.SlidesAiPreview.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iuzye628.SlidesAiPreviewCall?>()) {
      return (data != null
              ? _iuzye628.SlidesAiPreviewCall.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ixaahmd2.SlidesAiRewriteRequest?>()) {
      return (data != null
              ? _ixaahmd2.SlidesAiRewriteRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i7q1o3oi.ChartLinkProbe?>()) {
      return (data != null ? _i7q1o3oi.ChartLinkProbe.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3ysrjbx.ChartLinkState?>()) {
      return (data != null ? _i3ysrjbx.ChartLinkState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_is6z3tpy.ChartLinkStatus?>()) {
      return (data != null ? _is6z3tpy.ChartLinkStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iua8dx49.ChartSnapshotView?>()) {
      return (data != null ? _iua8dx49.ChartSnapshotView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iq1h9id2.ChartSourceList?>()) {
      return (data != null ? _iq1h9id2.ChartSourceList.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_inygrvyi.ChartSourceSummary?>()) {
      return (data != null ? _inygrvyi.ChartSourceSummary.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ihkglt8b.ChartLink?>()) {
      return (data != null ? _ihkglt8b.ChartLink.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6svv371.CodeState?>()) {
      return (data != null ? _i6svv371.CodeState.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ioalf2ve.Deck?>()) {
      return (data != null ? _ioalf2ve.Deck.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5vaufan.DeckTheme?>()) {
      return (data != null ? _i5vaufan.DeckTheme.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ipok3hcm.BuildKind?>()) {
      return (data != null ? _ipok3hcm.BuildKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_isb6wks2.BuildTrigger?>()) {
      return (data != null ? _isb6wks2.BuildTrigger.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_isf9v7y6.DeckAppearance?>()) {
      return (data != null ? _isf9v7y6.DeckAppearance.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4oq3vgh.PlaceholderType?>()) {
      return (data != null ? _i4oq3vgh.PlaceholderType.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_isah8148.SlideElementKind?>()) {
      return (data != null ? _isah8148.SlideElementKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_isghg0k1.SlideSizePreset?>()) {
      return (data != null ? _isghg0k1.SlideSizePreset.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5m4q7yg.TableDimension?>()) {
      return (data != null ? _i5m4q7yg.TableDimension.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipsr29xb.Slide?>()) {
      return (data != null ? _ipsr29xb.Slide.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_izfj14nk.SlideBuild?>()) {
      return (data != null ? _izfj14nk.SlideBuild.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ih1q77t5.SlideElement?>()) {
      return (data != null ? _ih1q77t5.SlideElement.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ic2hhlok.SlideGroup?>()) {
      return (data != null ? _ic2hhlok.SlideGroup.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3k3vjpp.SlideLayout?>()) {
      return (data != null ? _i3k3vjpp.SlideLayout.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_igjrafa0.SlideMaster?>()) {
      return (data != null ? _igjrafa0.SlideMaster.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iewd9d8j.SlideTableAxis?>()) {
      return (data != null ? _iewd9d8j.SlideTableAxis.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibnoy0fr.SlideTableCell?>()) {
      return (data != null ? _ibnoy0fr.SlideTableCell.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ildgqgkz.PresentationBusMessage?>()) {
      return (data != null
              ? _ildgqgkz.PresentationBusMessage.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationCommandEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationCommandEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijdad65m.PresentationCommandUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationCommandUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijdad65m.PresentationEndUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationEndUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationEndedEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationEndedEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationInkEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationInkEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationLaserEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationLaserEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationPairingEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationPairingEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationPresenterEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationPresenterEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationRosterEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationRosterEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationStateEvent?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationStateEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz9vxb2f.PresentationWelcome?>()) {
      return (data != null
              ? _iz9vxb2f.PresentationWelcome.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijdad65m.PresentationInkUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationInkUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ih25cwup.PresentationJoin?>()) {
      return (data != null ? _ih25cwup.PresentationJoin.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijdad65m.PresentationLaserUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationLaserUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i6know5x.PresentationPairingTarget?>()) {
      return (data != null
              ? _i6know5x.PresentationPairingTarget.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijdad65m.PresentationPairingUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationPairingUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijgt5qi7.PresentationParticipant?>()) {
      return (data != null
              ? _ijgt5qi7.PresentationParticipant.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i4d7um9r.PresentationRole?>()) {
      return (data != null ? _i4d7um9r.PresentationRole.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ig7ln54r.PresentationSessionInfo?>()) {
      return (data != null
              ? _ig7ln54r.PresentationSessionInfo.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i95fngt4.PresentationState?>()) {
      return (data != null ? _i95fngt4.PresentationState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijdad65m.PresentationStateUpdate?>()) {
      return (data != null
              ? _ijdad65m.PresentationStateUpdate.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iy6ry83r.SlidesSnapshotIndex?>()) {
      return (data != null
              ? _iy6ry83r.SlidesSnapshotIndex.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iilidizm.HeadlessChange?>()) {
      return (data != null ? _iilidizm.HeadlessChange.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icpkpcrn.DocAck?>()) {
      return (data != null ? _icpkpcrn.DocAck.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i8zfu67r.DocBusMessage?>()) {
      return (data != null ? _i8zfu67r.DocBusMessage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imbts8if.DocCursorUpdate?>()) {
      return (data != null ? _imbts8if.DocCursorUpdate.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imbts8if.DocHashCheck?>()) {
      return (data != null ? _imbts8if.DocHashCheck.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_imbts8if.DocPing?>()) {
      return (data != null ? _imbts8if.DocPing.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_imbts8if.DocRequestOps?>()) {
      return (data != null ? _imbts8if.DocRequestOps.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imbts8if.DocSubmitOp?>()) {
      return (data != null ? _imbts8if.DocSubmitOp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icpkpcrn.DocHashResult?>()) {
      return (data != null ? _icpkpcrn.DocHashResult.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icpkpcrn.DocInit?>()) {
      return (data != null ? _icpkpcrn.DocInit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icpkpcrn.DocMetaChanged?>()) {
      return (data != null ? _icpkpcrn.DocMetaChanged.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icpkpcrn.DocOpRejected?>()) {
      return (data != null ? _icpkpcrn.DocOpRejected.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icpkpcrn.DocParticipantJoined?>()) {
      return (data != null
              ? _icpkpcrn.DocParticipantJoined.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_icpkpcrn.DocParticipantLeft?>()) {
      return (data != null ? _icpkpcrn.DocParticipantLeft.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icpkpcrn.DocPong?>()) {
      return (data != null ? _icpkpcrn.DocPong.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icpkpcrn.DocRemoteCursor?>()) {
      return (data != null ? _icpkpcrn.DocRemoteCursor.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icpkpcrn.DocRemoteOp?>()) {
      return (data != null ? _icpkpcrn.DocRemoteOp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icpkpcrn.DocRoleChanged?>()) {
      return (data != null ? _icpkpcrn.DocRoleChanged.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igqu3xcv.ConvertForInsertResult?>()) {
      return (data != null
              ? _igqu3xcv.ConvertForInsertResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i5srcd7q.DocRejectCode?>()) {
      return (data != null ? _i5srcd7q.DocRejectCode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4sx4pml.Document?>()) {
      return (data != null ? _i4sx4pml.Document.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixppud51.DocumentImportReport?>()) {
      return (data != null
              ? _ixppud51.DocumentImportReport.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iu022vpf.DocumentInfo?>()) {
      return (data != null ? _iu022vpf.DocumentInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ir38bcqq.DocumentMetaChange?>()) {
      return (data != null ? _ir38bcqq.DocumentMetaChange.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_inkjv0lb.DocumentMetaPatch?>()) {
      return (data != null ? _inkjv0lb.DocumentMetaPatch.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icsyekcn.DocumentMetaView?>()) {
      return (data != null ? _icsyekcn.DocumentMetaView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iufsprkx.DocumentOp?>()) {
      return (data != null ? _iufsprkx.DocumentOp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_igr6xq1c.DocumentOpKind?>()) {
      return (data != null ? _igr6xq1c.DocumentOpKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_issmv319.DocumentOpView?>()) {
      return (data != null ? _issmv319.DocumentOpView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i2cnn8i8.DocumentSnapshot?>()) {
      return (data != null ? _i2cnn8i8.DocumentSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0cy62lm.DocumentSnapshotView?>()) {
      return (data != null
              ? _i0cy62lm.DocumentSnapshotView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_is1ql5wp.ExportProgressEvent?>()) {
      return (data != null
              ? _is1ql5wp.ExportProgressEvent.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_isdjhzgs.ExportProgressKind?>()) {
      return (data != null ? _isdjhzgs.ExportProgressKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_if2sngze.ExportResultView?>()) {
      return (data != null ? _if2sngze.ExportResultView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ittnhawp.ThemeConflictException?>()) {
      return (data != null
              ? _ittnhawp.ThemeConflictException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ii88i7dv.WriteDiffAuthor?>()) {
      return (data != null ? _ii88i7dv.WriteDiffAuthor.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ig4xquf5.WriteDiffCache?>()) {
      return (data != null ? _ig4xquf5.WriteDiffCache.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idky93gt.WriteDiffView?>()) {
      return (data != null ? _idky93gt.WriteDiffView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iynqrh33.WriteTheme?>()) {
      return (data != null ? _iynqrh33.WriteTheme.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i7pbwt05.WriteThemeRevision?>()) {
      return (data != null ? _i7pbwt05.WriteThemeRevision.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ick3mhj2.WriteThemeRevisionView?>()) {
      return (data != null
              ? _ick3mhj2.WriteThemeRevisionView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ixbjd26z.WriteThemeView?>()) {
      return (data != null ? _ixbjd26z.WriteThemeView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_is9bkd9t.WriteVersionDocument?>()) {
      return (data != null
              ? _is9bkd9t.WriteVersionDocument.fromJson(data)
              : null)
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
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
    if (t == _is.getType<List<String>?>()) {
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
    if (t == _is.getType<List<_ivmxemza.ProofreadIssue>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ivmxemza.ProofreadIssue>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<int?>) {
      return (data as List).map((e) => deserialize<int?>(e)).toList() as T;
    }
    if (t == List<_is2u4stz.AnalyticsDay>) {
      return (data as List)
              .map((e) => deserialize<_is2u4stz.AnalyticsDay>(e))
              .toList()
          as T;
    }
    if (t == List<_innm1rwe.AnalyticsCount>) {
      return (data as List)
              .map((e) => deserialize<_innm1rwe.AnalyticsCount>(e))
              .toList()
          as T;
    }
    if (t == List<_ixradasp.AnalyticsCohort>) {
      return (data as List)
              .map((e) => deserialize<_ixradasp.AnalyticsCohort>(e))
              .toList()
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
    if (t == _is.getType<List<_i5pjfe5s.BoardFlagView>?>()) {
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
    if (t == _is.getType<Map<String, double>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<double>(v)),
                )
              : null)
          as T;
    }
    if (t == _is.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
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
    if (t == List<_is.UuidValue>) {
      return (data as List).map((e) => deserialize<_is.UuidValue>(e)).toList()
          as T;
    }
    if (t == _is.getType<List<_is.UuidValue>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_is.UuidValue>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i8mh39wa.DriveItemKind>) {
      return (data as List)
              .map((e) => deserialize<_i8mh39wa.DriveItemKind>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_i8mh39wa.DriveItemKind>?>()) {
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
    if (t == _is.getType<List<_iez45i4u.FileCategory>?>()) {
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
    if (t == List<_ivvukfve.PublicationOpenSubmission>) {
      return (data as List)
              .map((e) => deserialize<_ivvukfve.PublicationOpenSubmission>(e))
              .toList()
          as T;
    }
    if (t == List<_ij9tsbn9.PublicationModeratorView>) {
      return (data as List)
              .map((e) => deserialize<_ij9tsbn9.PublicationModeratorView>(e))
              .toList()
          as T;
    }
    if (t == List<_iegijpud.SubmissionRevisionView>) {
      return (data as List)
              .map((e) => deserialize<_iegijpud.SubmissionRevisionView>(e))
              .toList()
          as T;
    }
    if (t == List<_it4o2pk5.RevOpView>) {
      return (data as List)
              .map((e) => deserialize<_it4o2pk5.RevOpView>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_it4o2pk5.RevOpView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_it4o2pk5.RevOpView>(e))
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
    if (t == _is.getType<List<_issmv319.DocumentOpView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_issmv319.DocumentOpView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _is.getType<List<_i48sm9f2.ImportWarningView>?>()) {
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
    if (t == List<_i1372x0g.AssistantThreadView>) {
      return (data as List)
              .map((e) => deserialize<_i1372x0g.AssistantThreadView>(e))
              .toList()
          as T;
    }
    if (t == List<_ilh4w69x.BoardCommentView>) {
      return (data as List)
              .map((e) => deserialize<_ilh4w69x.BoardCommentView>(e))
              .toList()
          as T;
    }
    if (t == List<_iv1j9wri.BoardSimilarPost>) {
      return (data as List)
              .map((e) => deserialize<_iv1j9wri.BoardSimilarPost>(e))
              .toList()
          as T;
    }
    if (t == List<_ihypagkt.BoardTaskStatus>) {
      return (data as List)
              .map((e) => deserialize<_ihypagkt.BoardTaskStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_id1usvpt.BoardReviewItem>) {
      return (data as List)
              .map((e) => deserialize<_id1usvpt.BoardReviewItem>(e))
              .toList()
          as T;
    }
    if (t == List<_is.UuidValue>) {
      return (data as List).map((e) => deserialize<_is.UuidValue>(e)).toList()
          as T;
    }
    if (t == _is.getType<List<_is.UuidValue>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_is.UuidValue>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i8qikgvy.BoardBundleSuggestionView>) {
      return (data as List)
              .map((e) => deserialize<_i8qikgvy.BoardBundleSuggestionView>(e))
              .toList()
          as T;
    }
    if (t == List<_ixzwh8hc.CommentThreadView>) {
      return (data as List)
              .map((e) => deserialize<_ixzwh8hc.CommentThreadView>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_ily3pmy5.DriveItemView>) {
      return (data as List)
              .map((e) => deserialize<_ily3pmy5.DriveItemView>(e))
              .toList()
          as T;
    }
    if (t == List<_ibinmr4r.TemplateView>) {
      return (data as List)
              .map((e) => deserialize<_ibinmr4r.TemplateView>(e))
              .toList()
          as T;
    }
    if (t == List<_iiw0494r.ActivityEventView>) {
      return (data as List)
              .map((e) => deserialize<_iiw0494r.ActivityEventView>(e))
              .toList()
          as T;
    }
    if (t == List<_i28n3m1r.FileUrlView>) {
      return (data as List)
              .map((e) => deserialize<_i28n3m1r.FileUrlView>(e))
              .toList()
          as T;
    }
    if (t == List<_i9ilkmgj.PublicationSettings>) {
      return (data as List)
              .map((e) => deserialize<_i9ilkmgj.PublicationSettings>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_idovycpn.PublicationDeliveryView>) {
      return (data as List)
              .map((e) => deserialize<_idovycpn.PublicationDeliveryView>(e))
              .toList()
          as T;
    }
    if (t == List<_ioyb7a1p.AccessTokenView>) {
      return (data as List)
              .map((e) => deserialize<_ioyb7a1p.AccessTokenView>(e))
              .toList()
          as T;
    }
    if (t == List<_i8uuoam6.UserSummary>) {
      return (data as List)
              .map((e) => deserialize<_i8uuoam6.UserSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_ir2w0lzm.ItemVersionView>) {
      return (data as List)
              .map((e) => deserialize<_ir2w0lzm.ItemVersionView>(e))
              .toList()
          as T;
    }
    if (t == List<_isuyxaqz.SheetsFillRow>) {
      return (data as List)
              .map((e) => deserialize<_isuyxaqz.SheetsFillRow>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_iq57nmvp.SheetsAiCellResult>) {
      return (data as List)
              .map((e) => deserialize<_iq57nmvp.SheetsAiCellResult>(e))
              .toList()
          as T;
    }
    if (t == List<_ifqit8uo.SheetsAiCellRequest>) {
      return (data as List)
              .map((e) => deserialize<_ifqit8uo.SheetsAiCellRequest>(e))
              .toList()
          as T;
    }
    if (t == List<_iu7aww0d.RevOpView>) {
      return (data as List)
              .map((e) => deserialize<_iu7aww0d.RevOpView>(e))
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
    if (t == List<_isf59hoo.ScriptExecution>) {
      return (data as List)
              .map((e) => deserialize<_isf59hoo.ScriptExecution>(e))
              .toList()
          as T;
    }
    if (t == List<_iug1yx01.SlidesAiNote>) {
      return (data as List)
              .map((e) => deserialize<_iug1yx01.SlidesAiNote>(e))
              .toList()
          as T;
    }
    if (t == List<_iqoob7q4.SlidesAiAltText>) {
      return (data as List)
              .map((e) => deserialize<_iqoob7q4.SlidesAiAltText>(e))
              .toList()
          as T;
    }
    if (t == List<_ixtuoo5p.SlidesAiDesignRank>) {
      return (data as List)
              .map((e) => deserialize<_ixtuoo5p.SlidesAiDesignRank>(e))
              .toList()
          as T;
    }
    if (t == List<_imx2esrl.ChartLinkStatus>) {
      return (data as List)
              .map((e) => deserialize<_imx2esrl.ChartLinkStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_izmhos0v.ChartLinkProbe>) {
      return (data as List)
              .map((e) => deserialize<_izmhos0v.ChartLinkProbe>(e))
              .toList()
          as T;
    }
    if (t == List<_icjb0pei.DocumentOpView>) {
      return (data as List)
              .map((e) => deserialize<_icjb0pei.DocumentOpView>(e))
              .toList()
          as T;
    }
    if (t == List<_ipbzt39t.WriteThemeView>) {
      return (data as List)
              .map((e) => deserialize<_ipbzt39t.WriteThemeView>(e))
              .toList()
          as T;
    }
    if (t == List<_iu3gmhy1.WriteThemeRevisionView>) {
      return (data as List)
              .map((e) => deserialize<_iu3gmhy1.WriteThemeRevisionView>(e))
              .toList()
          as T;
    }
    final modules = dataClassName == null
        ? deserializationMetadata.modulesForType(t)
        : deserializationMetadata.modules;
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _is.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ihl3axv2.AclFutureCallFanOutModel => 'AclFutureCallFanOutModel',
      _icgheary.BoardFutureCallSummarizeModel =>
        'BoardFutureCallSummarizeModel',
      _if8h900w.BoardFutureCallTriageModel => 'BoardFutureCallTriageModel',
      _ixkvo7h1.BoardFutureCallWritePromptModel =>
        'BoardFutureCallWritePromptModel',
      _ip0bwzb4.BoardGithubFutureCallHandleModel =>
        'BoardGithubFutureCallHandleModel',
      _i5z3lvv6.BoardGithubFutureCallReviewModel =>
        'BoardGithubFutureCallReviewModel',
      _ilpvgw0t.FilePreviewFutureCallGenerateModel =>
        'FilePreviewFutureCallGenerateModel',
      _inb6x2l0.NotificationEmailFutureCallSendModel =>
        'NotificationEmailFutureCallSendModel',
      _il37cz87.PublicationsFutureCallDeliverModel =>
        'PublicationsFutureCallDeliverModel',
      _io4auc29.StorageFutureCallRefreshItemSizeModel =>
        'StorageFutureCallRefreshItemSizeModel',
      _izr1y672.ActivityDashboard => 'ActivityDashboard',
      _iatdjl5p.ActivityEvent => 'ActivityEvent',
      _isa7sjzq.ActivityEventView => 'ActivityEventView',
      _ighcq381.ActivityTrendPoint => 'ActivityTrendPoint',
      _i50cy468.ActivityType => 'ActivityType',
      _ikcwdr17.ActivityViewer => 'ActivityViewer',
      _ixdmbuaj.ItemViewDay => 'ItemViewDay',
      _ifmsnq1y.UserActivitySettings => 'UserActivitySettings',
      _iyja8k5e.AiApplyMode => 'AiApplyMode',
      _iuq1eobh.AiPreviewRecord => 'AiPreviewRecord',
      _ir7z75mb.AiProvider => 'AiProvider',
      _ic2q2fwi.AiProviderKeyView => 'AiProviderKeyView',
      _iviyoyk9.AiQuality => 'AiQuality',
      _i7i53on7.AiUsage => 'AiUsage',
      _ivv7zvxt.AiUserKey => 'AiUserKey',
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
      _ixradasp.AnalyticsCohort => 'AnalyticsCohort',
      _innm1rwe.AnalyticsCount => 'AnalyticsCount',
      _is2u4stz.AnalyticsDay => 'AnalyticsDay',
      _i61uxw4p.AnalyticsOverview => 'AnalyticsOverview',
      _id3chnrt.UsageApp => 'UsageApp',
      _iamkojeb.UsageCounterDay => 'UsageCounterDay',
      _ibanfcrx.UsageDayStats => 'UsageDayStats',
      _ik0bapqg.UserActivityDay => 'UserActivityDay',
      _icowsqvh.BoardAiUsage => 'BoardAiUsage',
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
      _i5r22jl8.BoardGithubDelivery => 'BoardGithubDelivery',
      _igcoqerx.BoardListQuery => 'BoardListQuery',
      _iu9hvv8z.BoardMe => 'BoardMe',
      _in0hwjmy.BoardModeration => 'BoardModeration',
      _i5jfu168.BoardModerationAction => 'BoardModerationAction',
      _idxofexa.BoardModerationLog => 'BoardModerationLog',
      _i7xps6dm.BoardPost => 'BoardPost',
      _izvgi5ni.BoardPostDraft => 'BoardPostDraft',
      _ibl25moa.BoardPostEvent => 'BoardPostEvent',
      _iui4x9zg.BoardPostKind => 'BoardPostKind',
      _iq3f61ec.BoardPostListItem => 'BoardPostListItem',
      _i1stsytz.BoardPostPage => 'BoardPostPage',
      _il200dga.BoardPostStatus => 'BoardPostStatus',
      _ijjd81zg.BoardPostView => 'BoardPostView',
      _i36hp4a6.BoardPullRequest => 'BoardPullRequest',
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
      _i4piktk8.ClusterBusBatch => 'ClusterBusBatch',
      _ipkzl9y7.ClusterSignal => 'ClusterSignal',
      _iyixppck.Comment => 'Comment',
      _iw81twtc.CommentAnchorKind => 'CommentAnchorKind',
      _imlsyj2p.CommentEvent => 'CommentEvent',
      _ih1mb6x5.CommentEventKind => 'CommentEventKind',
      _il5y6tzr.CommentFilter => 'CommentFilter',
      _ix3p7034.CommentSignal => 'CommentSignal',
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
      _i0atxq9l.DriveChangeSignal => 'DriveChangeSignal',
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
      _iu565i0a.FeedbackReport => 'FeedbackReport',
      _ilhpki98.FeedbackSubmission => 'FeedbackSubmission',
      _irrzp8p9.FileUploadTicket => 'FileUploadTicket',
      _itzt3x6d.FileUrlView => 'FileUrlView',
      _iymtdptb.ImageProfile => 'ImageProfile',
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
      _iqsxdr4a.NotificationSignal => 'NotificationSignal',
      _izfzk9h3.NotificationView => 'NotificationView',
      _ik59hiyp.UserNotification => 'UserNotification',
      _iylgyc33.Participant => 'Participant',
      _i7dp90q0.PresenceBusMessage => 'PresenceBusMessage',
      _i8r9afjv.PresenceFollowerCount => 'PresenceFollowerCount',
      _i8r9afjv.PresenceHints => 'PresenceHints',
      _i8r9afjv.PresenceJoined => 'PresenceJoined',
      _i8r9afjv.PresenceLeft => 'PresenceLeft',
      _i8r9afjv.PresenceNotice => 'PresenceNotice',
      _i8r9afjv.PresenceRoster => 'PresenceRoster',
      _i8r9afjv.PresenceUpdated => 'PresenceUpdated',
      _ik055xb9.PresenceState => 'PresenceState',
      _isz2sju0.PresenceUpdate => 'PresenceUpdate',
      _ikkxb56h.Publication => 'Publication',
      _i5vk42yw.PublicationBlock => 'PublicationBlock',
      _i9g6l3wu.PublicationCard => 'PublicationCard',
      _i0a1sw0a.PublicationCheckResult => 'PublicationCheckResult',
      _iqa48qn0.PublicationConsent => 'PublicationConsent',
      _ihiygfti.PublicationDelivery => 'PublicationDelivery',
      _iz1gego0.PublicationDeliveryView => 'PublicationDeliveryView',
      _iucp51pg.PublicationFieldMode => 'PublicationFieldMode',
      _i63wbtw0.PublicationFields => 'PublicationFields',
      _iv6bey6s.PublicationInput => 'PublicationInput',
      _i1u9dlta.PublicationModerator => 'PublicationModerator',
      _ij9tsbn9.PublicationModeratorView => 'PublicationModeratorView',
      _ivvukfve.PublicationOpenSubmission => 'PublicationOpenSubmission',
      _iyqlj2kr.PublicationSecret => 'PublicationSecret',
      _i5i48220.PublicationSettings => 'PublicationSettings',
      _ipbg6o7y.Submission => 'Submission',
      _i49gtkgr.SubmissionAsset => 'SubmissionAsset',
      _ip6l83ta.SubmissionDeliveryState => 'SubmissionDeliveryState',
      _i71zy0hy.SubmissionRevision => 'SubmissionRevision',
      _iegijpud.SubmissionRevisionView => 'SubmissionRevisionView',
      _ijb8v3k4.SubmissionStarted => 'SubmissionStarted',
      _i7hbulg4.SubmissionStatus => 'SubmissionStatus',
      _iq9uje8l.SubmissionValues => 'SubmissionValues',
      _iakndug7.SubmissionView => 'SubmissionView',
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
      _iyewfisw.RevBusMessage => 'RevBusMessage',
      _ip7h3lg0.RevFile => 'RevFile',
      _ihwy023l.RevFileInfo => 'RevFileInfo',
      _iwkehf4e.RevFileKind => 'RevFileKind',
      _ivfqwl6l.RevHookState => 'RevHookState',
      _iax01zbg.RevOp => 'RevOp',
      _it4o2pk5.RevOpView => 'RevOpView',
      _ium7xjeg.RevPage => 'RevPage',
      _i3q3ua5p.RevPageKind => 'RevPageKind',
      _if03ikx4.RevPageRequest => 'RevPageRequest',
      _iilsyt4b.RevRejectCode => 'RevRejectCode',
      _ibw3povl.ServerChangeRecord => 'ServerChangeRecord',
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
      _if4kaxov.StorageReservation => 'StorageReservation',
      _is05u0nw.UserStorage => 'UserStorage',
      _izha9j5m.AccessTokenView => 'AccessTokenView',
      _iq4dupwy.AccountDeletionPreview => 'AccountDeletionPreview',
      _i6azdr3n.AppThemeMode => 'AppThemeMode',
      _iru4pv75.CreatedAccessToken => 'CreatedAccessToken',
      _ijodrcyd.PersonalAccessToken => 'PersonalAccessToken',
      _i5lc4gt0.UiDensity => 'UiDensity',
      _i501u5m5.UserPreferences => 'UserPreferences',
      _id95rrz2.UserPreferencesPatch => 'UserPreferencesPatch',
      _ihzl7wbq.UserProfile => 'UserProfile',
      _iufqmqtc.UserProfileView => 'UserProfileView',
      _i6y7tspy.UserSummary => 'UserSummary',
      _i7jb115m.ItemVersion => 'ItemVersion',
      _ibe5uno1.ItemVersionState => 'ItemVersionState',
      _ipbapjbz.ItemVersionView => 'ItemVersionView',
      _in0fdl1f.VersionKind => 'VersionKind',
      _in38zbga.VersionRestoreResult => 'VersionRestoreResult',
      _i5u6d6t4.VersionStorage => 'VersionStorage',
      _i5vk0z7t.AiFunctionCache => 'AiFunctionCache',
      _iuzj1jin.SheetsAiApplyResult => 'SheetsAiApplyResult',
      _iljqbz3a.SheetsAiCellRequest => 'SheetsAiCellRequest',
      _im85lt6z.SheetsAiCellResult => 'SheetsAiCellResult',
      _i4t3jyqe.SheetsAiPreview => 'SheetsAiPreview',
      _idzstekp.SheetsAiPreviewCall => 'SheetsAiPreviewCall',
      _i49726iv.SheetsAiPreviewCell => 'SheetsAiPreviewCell',
      _izbpavhd.SheetsFillProposal => 'SheetsFillProposal',
      _i1gi0ui2.SheetsFillRow => 'SheetsFillRow',
      _i2bhah0l.SheetsFormulaSuggestion => 'SheetsFormulaSuggestion',
      _i74ohdg2.SheetsImportJob => 'SheetsImportJob',
      _iaf43n69.SheetsImportProgress => 'SheetsImportProgress',
      _i8d83qca.SheetsImportStatus => 'SheetsImportStatus',
      _ik5lpvx4.CellHistory => 'CellHistory',
      _ij1xvs09.CellHistoryEntry => 'CellHistoryEntry',
      _i09xo3k8.CellHistoryPage => 'CellHistoryPage',
      _ilv3hlxr.RevertResult => 'RevertResult',
      _ipqum05l.RevertSkip => 'RevertSkip',
      _i3p6on16.Banding => 'Banding',
      _iofnuqg9.BasicFilter => 'BasicFilter',
      _ifc5vn9h.Cell => 'Cell',
      _iy4zsn6m.ConditionalFormatRule => 'ConditionalFormatRule',
      _i5c2bsv2.DataValidationRule => 'DataValidationRule',
      _i145vl5m.DimensionGroup => 'DimensionGroup',
      _iye9c0co.EmbeddedObject => 'EmbeddedObject',
      _ilnsyzhq.Dimension => 'Dimension',
      _ihfpm0ve.EmbeddedObjectKind => 'EmbeddedObjectKind',
      _iofwzekn.HorizontalAlign => 'HorizontalAlign',
      _i0z9m4nl.RecalcMode => 'RecalcMode',
      _io4oc09s.ScriptBuildStatus => 'ScriptBuildStatus',
      _i8ne06ql.SheetKind => 'SheetKind',
      _irmtoho8.TriggerKind => 'TriggerKind',
      _ivf2txqv.VerticalAlign => 'VerticalAlign',
      _iz9rjt8b.WrapStrategy => 'WrapStrategy',
      _igzd7u0m.FilterView => 'FilterView',
      _iiq43rv8.Macro => 'Macro',
      _i57rr32y.MergedRange => 'MergedRange',
      _irrybuvb.NamedRange => 'NamedRange',
      _iz580og3.PivotTable => 'PivotTable',
      _iz1b7y52.ProtectedRange => 'ProtectedRange',
      _ibdybin0.ScriptBuild => 'ScriptBuild',
      _iplsajic.ScriptFile => 'ScriptFile',
      _iy6gs0qh.ScriptProject => 'ScriptProject',
      _ig9hff0r.ScriptProperty => 'ScriptProperty',
      _irlm292d.ScriptTrigger => 'ScriptTrigger',
      _i8c5x9aj.Sheet => 'Sheet',
      _i6chd4x2.SheetColumn => 'SheetColumn',
      _i4k3x536.SheetRow => 'SheetRow',
      _ib6gxu4b.Spreadsheet => 'Spreadsheet',
      _ijtj1mph.ScriptUserProperty => 'ScriptUserProperty',
      _iaehez21.SheetsActivitySummary => 'SheetsActivitySummary',
      _i9yjzgjk.SheetsContributorStat => 'SheetsContributorStat',
      _iwl8v9t3.SheetsSnapshotIndex => 'SheetsSnapshotIndex',
      _ibv2hdjr.ScriptAuthorization => 'ScriptAuthorization',
      _icjzxy6x.ScriptAuthorizationView => 'ScriptAuthorizationView',
      _iq0xpzf7.ScriptCompileResponse => 'ScriptCompileResponse',
      _i4bc0fek.ScriptExecution => 'ScriptExecution',
      _inqz9v2t.ScriptExecutionKind => 'ScriptExecutionKind',
      _ira26pfa.ScriptExecutionStatus => 'ScriptExecutionStatus',
      _is04pxv8.ScriptFetchResponse => 'ScriptFetchResponse',
      _i4e1yb8z.ScriptJob => 'ScriptJob',
      _itn7c5zm.ScriptQuotaUsage => 'ScriptQuotaUsage',
      _is0mvar3.ScriptRunResponse => 'ScriptRunResponse',
      _iy0fj18f.ScriptRuntimeKind => 'ScriptRuntimeKind',
      _ixysij0q.ScriptTriggerState => 'ScriptTriggerState',
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
      _ihkglt8b.ChartLink => 'ChartLink',
      _i6svv371.CodeState => 'CodeState',
      _ioalf2ve.Deck => 'Deck',
      _i5vaufan.DeckTheme => 'DeckTheme',
      _ipok3hcm.BuildKind => 'BuildKind',
      _isb6wks2.BuildTrigger => 'BuildTrigger',
      _isf9v7y6.DeckAppearance => 'DeckAppearance',
      _i4oq3vgh.PlaceholderType => 'PlaceholderType',
      _isah8148.SlideElementKind => 'SlideElementKind',
      _isghg0k1.SlideSizePreset => 'SlideSizePreset',
      _i5m4q7yg.TableDimension => 'TableDimension',
      _ipsr29xb.Slide => 'Slide',
      _izfj14nk.SlideBuild => 'SlideBuild',
      _ih1q77t5.SlideElement => 'SlideElement',
      _ic2hhlok.SlideGroup => 'SlideGroup',
      _i3k3vjpp.SlideLayout => 'SlideLayout',
      _igjrafa0.SlideMaster => 'SlideMaster',
      _iewd9d8j.SlideTableAxis => 'SlideTableAxis',
      _ibnoy0fr.SlideTableCell => 'SlideTableCell',
      _ildgqgkz.PresentationBusMessage => 'PresentationBusMessage',
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
      _iy6ry83r.SlidesSnapshotIndex => 'SlidesSnapshotIndex',
      _iilidizm.HeadlessChange => 'HeadlessChange',
      _icpkpcrn.DocAck => 'DocAck',
      _i8zfu67r.DocBusMessage => 'DocBusMessage',
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
      _ixppud51.DocumentImportReport => 'DocumentImportReport',
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
      _ig4xquf5.WriteDiffCache => 'WriteDiffCache',
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
      case _ihl3axv2.AclFutureCallFanOutModel():
        return 'AclFutureCallFanOutModel';
      case _icgheary.BoardFutureCallSummarizeModel():
        return 'BoardFutureCallSummarizeModel';
      case _if8h900w.BoardFutureCallTriageModel():
        return 'BoardFutureCallTriageModel';
      case _ixkvo7h1.BoardFutureCallWritePromptModel():
        return 'BoardFutureCallWritePromptModel';
      case _ip0bwzb4.BoardGithubFutureCallHandleModel():
        return 'BoardGithubFutureCallHandleModel';
      case _i5z3lvv6.BoardGithubFutureCallReviewModel():
        return 'BoardGithubFutureCallReviewModel';
      case _ilpvgw0t.FilePreviewFutureCallGenerateModel():
        return 'FilePreviewFutureCallGenerateModel';
      case _inb6x2l0.NotificationEmailFutureCallSendModel():
        return 'NotificationEmailFutureCallSendModel';
      case _il37cz87.PublicationsFutureCallDeliverModel():
        return 'PublicationsFutureCallDeliverModel';
      case _io4auc29.StorageFutureCallRefreshItemSizeModel():
        return 'StorageFutureCallRefreshItemSizeModel';
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
      case _ixdmbuaj.ItemViewDay():
        return 'ItemViewDay';
      case _ifmsnq1y.UserActivitySettings():
        return 'UserActivitySettings';
      case _iyja8k5e.AiApplyMode():
        return 'AiApplyMode';
      case _iuq1eobh.AiPreviewRecord():
        return 'AiPreviewRecord';
      case _ir7z75mb.AiProvider():
        return 'AiProvider';
      case _ic2q2fwi.AiProviderKeyView():
        return 'AiProviderKeyView';
      case _iviyoyk9.AiQuality():
        return 'AiQuality';
      case _i7i53on7.AiUsage():
        return 'AiUsage';
      case _ivv7zvxt.AiUserKey():
        return 'AiUserKey';
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
      case _ixradasp.AnalyticsCohort():
        return 'AnalyticsCohort';
      case _innm1rwe.AnalyticsCount():
        return 'AnalyticsCount';
      case _is2u4stz.AnalyticsDay():
        return 'AnalyticsDay';
      case _i61uxw4p.AnalyticsOverview():
        return 'AnalyticsOverview';
      case _id3chnrt.UsageApp():
        return 'UsageApp';
      case _iamkojeb.UsageCounterDay():
        return 'UsageCounterDay';
      case _ibanfcrx.UsageDayStats():
        return 'UsageDayStats';
      case _ik0bapqg.UserActivityDay():
        return 'UserActivityDay';
      case _icowsqvh.BoardAiUsage():
        return 'BoardAiUsage';
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
      case _i5r22jl8.BoardGithubDelivery():
        return 'BoardGithubDelivery';
      case _igcoqerx.BoardListQuery():
        return 'BoardListQuery';
      case _iu9hvv8z.BoardMe():
        return 'BoardMe';
      case _in0hwjmy.BoardModeration():
        return 'BoardModeration';
      case _i5jfu168.BoardModerationAction():
        return 'BoardModerationAction';
      case _idxofexa.BoardModerationLog():
        return 'BoardModerationLog';
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
      case _i36hp4a6.BoardPullRequest():
        return 'BoardPullRequest';
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
      case _i4piktk8.ClusterBusBatch():
        return 'ClusterBusBatch';
      case _ipkzl9y7.ClusterSignal():
        return 'ClusterSignal';
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
      case _ix3p7034.CommentSignal():
        return 'CommentSignal';
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
      case _i0atxq9l.DriveChangeSignal():
        return 'DriveChangeSignal';
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
      case _iu565i0a.FeedbackReport():
        return 'FeedbackReport';
      case _ilhpki98.FeedbackSubmission():
        return 'FeedbackSubmission';
      case _irrzp8p9.FileUploadTicket():
        return 'FileUploadTicket';
      case _itzt3x6d.FileUrlView():
        return 'FileUrlView';
      case _iymtdptb.ImageProfile():
        return 'ImageProfile';
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
      case _iqsxdr4a.NotificationSignal():
        return 'NotificationSignal';
      case _izfzk9h3.NotificationView():
        return 'NotificationView';
      case _ik59hiyp.UserNotification():
        return 'UserNotification';
      case _iylgyc33.Participant():
        return 'Participant';
      case _i7dp90q0.PresenceBusMessage():
        return 'PresenceBusMessage';
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
      case _ikkxb56h.Publication():
        return 'Publication';
      case _i5vk42yw.PublicationBlock():
        return 'PublicationBlock';
      case _i9g6l3wu.PublicationCard():
        return 'PublicationCard';
      case _i0a1sw0a.PublicationCheckResult():
        return 'PublicationCheckResult';
      case _iqa48qn0.PublicationConsent():
        return 'PublicationConsent';
      case _ihiygfti.PublicationDelivery():
        return 'PublicationDelivery';
      case _iz1gego0.PublicationDeliveryView():
        return 'PublicationDeliveryView';
      case _iucp51pg.PublicationFieldMode():
        return 'PublicationFieldMode';
      case _i63wbtw0.PublicationFields():
        return 'PublicationFields';
      case _iv6bey6s.PublicationInput():
        return 'PublicationInput';
      case _i1u9dlta.PublicationModerator():
        return 'PublicationModerator';
      case _ij9tsbn9.PublicationModeratorView():
        return 'PublicationModeratorView';
      case _ivvukfve.PublicationOpenSubmission():
        return 'PublicationOpenSubmission';
      case _iyqlj2kr.PublicationSecret():
        return 'PublicationSecret';
      case _i5i48220.PublicationSettings():
        return 'PublicationSettings';
      case _ipbg6o7y.Submission():
        return 'Submission';
      case _i49gtkgr.SubmissionAsset():
        return 'SubmissionAsset';
      case _ip6l83ta.SubmissionDeliveryState():
        return 'SubmissionDeliveryState';
      case _i71zy0hy.SubmissionRevision():
        return 'SubmissionRevision';
      case _iegijpud.SubmissionRevisionView():
        return 'SubmissionRevisionView';
      case _ijb8v3k4.SubmissionStarted():
        return 'SubmissionStarted';
      case _i7hbulg4.SubmissionStatus():
        return 'SubmissionStatus';
      case _iq9uje8l.SubmissionValues():
        return 'SubmissionValues';
      case _iakndug7.SubmissionView():
        return 'SubmissionView';
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
      case _iyewfisw.RevBusMessage():
        return 'RevBusMessage';
      case _ip7h3lg0.RevFile():
        return 'RevFile';
      case _ihwy023l.RevFileInfo():
        return 'RevFileInfo';
      case _iwkehf4e.RevFileKind():
        return 'RevFileKind';
      case _ivfqwl6l.RevHookState():
        return 'RevHookState';
      case _iax01zbg.RevOp():
        return 'RevOp';
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
      case _ibw3povl.ServerChangeRecord():
        return 'ServerChangeRecord';
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
      case _if4kaxov.StorageReservation():
        return 'StorageReservation';
      case _is05u0nw.UserStorage():
        return 'UserStorage';
      case _izha9j5m.AccessTokenView():
        return 'AccessTokenView';
      case _iq4dupwy.AccountDeletionPreview():
        return 'AccountDeletionPreview';
      case _i6azdr3n.AppThemeMode():
        return 'AppThemeMode';
      case _iru4pv75.CreatedAccessToken():
        return 'CreatedAccessToken';
      case _ijodrcyd.PersonalAccessToken():
        return 'PersonalAccessToken';
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
      case _ibe5uno1.ItemVersionState():
        return 'ItemVersionState';
      case _ipbapjbz.ItemVersionView():
        return 'ItemVersionView';
      case _in0fdl1f.VersionKind():
        return 'VersionKind';
      case _in38zbga.VersionRestoreResult():
        return 'VersionRestoreResult';
      case _i5u6d6t4.VersionStorage():
        return 'VersionStorage';
      case _i5vk0z7t.AiFunctionCache():
        return 'AiFunctionCache';
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
      case _i74ohdg2.SheetsImportJob():
        return 'SheetsImportJob';
      case _iaf43n69.SheetsImportProgress():
        return 'SheetsImportProgress';
      case _i8d83qca.SheetsImportStatus():
        return 'SheetsImportStatus';
      case _ik5lpvx4.CellHistory():
        return 'CellHistory';
      case _ij1xvs09.CellHistoryEntry():
        return 'CellHistoryEntry';
      case _i09xo3k8.CellHistoryPage():
        return 'CellHistoryPage';
      case _ilv3hlxr.RevertResult():
        return 'RevertResult';
      case _ipqum05l.RevertSkip():
        return 'RevertSkip';
      case _i3p6on16.Banding():
        return 'Banding';
      case _iofnuqg9.BasicFilter():
        return 'BasicFilter';
      case _ifc5vn9h.Cell():
        return 'Cell';
      case _iy4zsn6m.ConditionalFormatRule():
        return 'ConditionalFormatRule';
      case _i5c2bsv2.DataValidationRule():
        return 'DataValidationRule';
      case _i145vl5m.DimensionGroup():
        return 'DimensionGroup';
      case _iye9c0co.EmbeddedObject():
        return 'EmbeddedObject';
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
      case _igzd7u0m.FilterView():
        return 'FilterView';
      case _iiq43rv8.Macro():
        return 'Macro';
      case _i57rr32y.MergedRange():
        return 'MergedRange';
      case _irrybuvb.NamedRange():
        return 'NamedRange';
      case _iz580og3.PivotTable():
        return 'PivotTable';
      case _iz1b7y52.ProtectedRange():
        return 'ProtectedRange';
      case _ibdybin0.ScriptBuild():
        return 'ScriptBuild';
      case _iplsajic.ScriptFile():
        return 'ScriptFile';
      case _iy6gs0qh.ScriptProject():
        return 'ScriptProject';
      case _ig9hff0r.ScriptProperty():
        return 'ScriptProperty';
      case _irlm292d.ScriptTrigger():
        return 'ScriptTrigger';
      case _i8c5x9aj.Sheet():
        return 'Sheet';
      case _i6chd4x2.SheetColumn():
        return 'SheetColumn';
      case _i4k3x536.SheetRow():
        return 'SheetRow';
      case _ib6gxu4b.Spreadsheet():
        return 'Spreadsheet';
      case _ijtj1mph.ScriptUserProperty():
        return 'ScriptUserProperty';
      case _iaehez21.SheetsActivitySummary():
        return 'SheetsActivitySummary';
      case _i9yjzgjk.SheetsContributorStat():
        return 'SheetsContributorStat';
      case _iwl8v9t3.SheetsSnapshotIndex():
        return 'SheetsSnapshotIndex';
      case _ibv2hdjr.ScriptAuthorization():
        return 'ScriptAuthorization';
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
      case _i4e1yb8z.ScriptJob():
        return 'ScriptJob';
      case _itn7c5zm.ScriptQuotaUsage():
        return 'ScriptQuotaUsage';
      case _is0mvar3.ScriptRunResponse():
        return 'ScriptRunResponse';
      case _iy0fj18f.ScriptRuntimeKind():
        return 'ScriptRuntimeKind';
      case _ixysij0q.ScriptTriggerState():
        return 'ScriptTriggerState';
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
      case _ihkglt8b.ChartLink():
        return 'ChartLink';
      case _i6svv371.CodeState():
        return 'CodeState';
      case _ioalf2ve.Deck():
        return 'Deck';
      case _i5vaufan.DeckTheme():
        return 'DeckTheme';
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
      case _ipsr29xb.Slide():
        return 'Slide';
      case _izfj14nk.SlideBuild():
        return 'SlideBuild';
      case _ih1q77t5.SlideElement():
        return 'SlideElement';
      case _ic2hhlok.SlideGroup():
        return 'SlideGroup';
      case _i3k3vjpp.SlideLayout():
        return 'SlideLayout';
      case _igjrafa0.SlideMaster():
        return 'SlideMaster';
      case _iewd9d8j.SlideTableAxis():
        return 'SlideTableAxis';
      case _ibnoy0fr.SlideTableCell():
        return 'SlideTableCell';
      case _ildgqgkz.PresentationBusMessage():
        return 'PresentationBusMessage';
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
      case _iy6ry83r.SlidesSnapshotIndex():
        return 'SlidesSnapshotIndex';
      case _iilidizm.HeadlessChange():
        return 'HeadlessChange';
      case _icpkpcrn.DocAck():
        return 'DocAck';
      case _i8zfu67r.DocBusMessage():
        return 'DocBusMessage';
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
      case _ixppud51.DocumentImportReport():
        return 'DocumentImportReport';
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
      case _ig4xquf5.WriteDiffCache():
        return 'WriteDiffCache';
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
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AclFutureCallFanOutModel') {
      return deserialize<_ihl3axv2.AclFutureCallFanOutModel>(data['data']);
    }
    if (dataClassName == 'BoardFutureCallSummarizeModel') {
      return deserialize<_icgheary.BoardFutureCallSummarizeModel>(data['data']);
    }
    if (dataClassName == 'BoardFutureCallTriageModel') {
      return deserialize<_if8h900w.BoardFutureCallTriageModel>(data['data']);
    }
    if (dataClassName == 'BoardFutureCallWritePromptModel') {
      return deserialize<_ixkvo7h1.BoardFutureCallWritePromptModel>(
        data['data'],
      );
    }
    if (dataClassName == 'BoardGithubFutureCallHandleModel') {
      return deserialize<_ip0bwzb4.BoardGithubFutureCallHandleModel>(
        data['data'],
      );
    }
    if (dataClassName == 'BoardGithubFutureCallReviewModel') {
      return deserialize<_i5z3lvv6.BoardGithubFutureCallReviewModel>(
        data['data'],
      );
    }
    if (dataClassName == 'FilePreviewFutureCallGenerateModel') {
      return deserialize<_ilpvgw0t.FilePreviewFutureCallGenerateModel>(
        data['data'],
      );
    }
    if (dataClassName == 'NotificationEmailFutureCallSendModel') {
      return deserialize<_inb6x2l0.NotificationEmailFutureCallSendModel>(
        data['data'],
      );
    }
    if (dataClassName == 'PublicationsFutureCallDeliverModel') {
      return deserialize<_il37cz87.PublicationsFutureCallDeliverModel>(
        data['data'],
      );
    }
    if (dataClassName == 'StorageFutureCallRefreshItemSizeModel') {
      return deserialize<_io4auc29.StorageFutureCallRefreshItemSizeModel>(
        data['data'],
      );
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
    if (dataClassName == 'ItemViewDay') {
      return deserialize<_ixdmbuaj.ItemViewDay>(data['data']);
    }
    if (dataClassName == 'UserActivitySettings') {
      return deserialize<_ifmsnq1y.UserActivitySettings>(data['data']);
    }
    if (dataClassName == 'AiApplyMode') {
      return deserialize<_iyja8k5e.AiApplyMode>(data['data']);
    }
    if (dataClassName == 'AiPreviewRecord') {
      return deserialize<_iuq1eobh.AiPreviewRecord>(data['data']);
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
    if (dataClassName == 'AiUserKey') {
      return deserialize<_ivv7zvxt.AiUserKey>(data['data']);
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
    if (dataClassName == 'AnalyticsCohort') {
      return deserialize<_ixradasp.AnalyticsCohort>(data['data']);
    }
    if (dataClassName == 'AnalyticsCount') {
      return deserialize<_innm1rwe.AnalyticsCount>(data['data']);
    }
    if (dataClassName == 'AnalyticsDay') {
      return deserialize<_is2u4stz.AnalyticsDay>(data['data']);
    }
    if (dataClassName == 'AnalyticsOverview') {
      return deserialize<_i61uxw4p.AnalyticsOverview>(data['data']);
    }
    if (dataClassName == 'UsageApp') {
      return deserialize<_id3chnrt.UsageApp>(data['data']);
    }
    if (dataClassName == 'UsageCounterDay') {
      return deserialize<_iamkojeb.UsageCounterDay>(data['data']);
    }
    if (dataClassName == 'UsageDayStats') {
      return deserialize<_ibanfcrx.UsageDayStats>(data['data']);
    }
    if (dataClassName == 'UserActivityDay') {
      return deserialize<_ik0bapqg.UserActivityDay>(data['data']);
    }
    if (dataClassName == 'BoardAiUsage') {
      return deserialize<_icowsqvh.BoardAiUsage>(data['data']);
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
    if (dataClassName == 'BoardGithubDelivery') {
      return deserialize<_i5r22jl8.BoardGithubDelivery>(data['data']);
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
    if (dataClassName == 'BoardModerationLog') {
      return deserialize<_idxofexa.BoardModerationLog>(data['data']);
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
    if (dataClassName == 'BoardPullRequest') {
      return deserialize<_i36hp4a6.BoardPullRequest>(data['data']);
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
    if (dataClassName == 'ClusterBusBatch') {
      return deserialize<_i4piktk8.ClusterBusBatch>(data['data']);
    }
    if (dataClassName == 'ClusterSignal') {
      return deserialize<_ipkzl9y7.ClusterSignal>(data['data']);
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
    if (dataClassName == 'CommentSignal') {
      return deserialize<_ix3p7034.CommentSignal>(data['data']);
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
    if (dataClassName == 'DriveChangeSignal') {
      return deserialize<_i0atxq9l.DriveChangeSignal>(data['data']);
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
    if (dataClassName == 'FeedbackReport') {
      return deserialize<_iu565i0a.FeedbackReport>(data['data']);
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
    if (dataClassName == 'ImageProfile') {
      return deserialize<_iymtdptb.ImageProfile>(data['data']);
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
    if (dataClassName == 'NotificationSignal') {
      return deserialize<_iqsxdr4a.NotificationSignal>(data['data']);
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
    if (dataClassName == 'PresenceBusMessage') {
      return deserialize<_i7dp90q0.PresenceBusMessage>(data['data']);
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
    if (dataClassName == 'Publication') {
      return deserialize<_ikkxb56h.Publication>(data['data']);
    }
    if (dataClassName == 'PublicationBlock') {
      return deserialize<_i5vk42yw.PublicationBlock>(data['data']);
    }
    if (dataClassName == 'PublicationCard') {
      return deserialize<_i9g6l3wu.PublicationCard>(data['data']);
    }
    if (dataClassName == 'PublicationCheckResult') {
      return deserialize<_i0a1sw0a.PublicationCheckResult>(data['data']);
    }
    if (dataClassName == 'PublicationConsent') {
      return deserialize<_iqa48qn0.PublicationConsent>(data['data']);
    }
    if (dataClassName == 'PublicationDelivery') {
      return deserialize<_ihiygfti.PublicationDelivery>(data['data']);
    }
    if (dataClassName == 'PublicationDeliveryView') {
      return deserialize<_iz1gego0.PublicationDeliveryView>(data['data']);
    }
    if (dataClassName == 'PublicationFieldMode') {
      return deserialize<_iucp51pg.PublicationFieldMode>(data['data']);
    }
    if (dataClassName == 'PublicationFields') {
      return deserialize<_i63wbtw0.PublicationFields>(data['data']);
    }
    if (dataClassName == 'PublicationInput') {
      return deserialize<_iv6bey6s.PublicationInput>(data['data']);
    }
    if (dataClassName == 'PublicationModerator') {
      return deserialize<_i1u9dlta.PublicationModerator>(data['data']);
    }
    if (dataClassName == 'PublicationModeratorView') {
      return deserialize<_ij9tsbn9.PublicationModeratorView>(data['data']);
    }
    if (dataClassName == 'PublicationOpenSubmission') {
      return deserialize<_ivvukfve.PublicationOpenSubmission>(data['data']);
    }
    if (dataClassName == 'PublicationSecret') {
      return deserialize<_iyqlj2kr.PublicationSecret>(data['data']);
    }
    if (dataClassName == 'PublicationSettings') {
      return deserialize<_i5i48220.PublicationSettings>(data['data']);
    }
    if (dataClassName == 'Submission') {
      return deserialize<_ipbg6o7y.Submission>(data['data']);
    }
    if (dataClassName == 'SubmissionAsset') {
      return deserialize<_i49gtkgr.SubmissionAsset>(data['data']);
    }
    if (dataClassName == 'SubmissionDeliveryState') {
      return deserialize<_ip6l83ta.SubmissionDeliveryState>(data['data']);
    }
    if (dataClassName == 'SubmissionRevision') {
      return deserialize<_i71zy0hy.SubmissionRevision>(data['data']);
    }
    if (dataClassName == 'SubmissionRevisionView') {
      return deserialize<_iegijpud.SubmissionRevisionView>(data['data']);
    }
    if (dataClassName == 'SubmissionStarted') {
      return deserialize<_ijb8v3k4.SubmissionStarted>(data['data']);
    }
    if (dataClassName == 'SubmissionStatus') {
      return deserialize<_i7hbulg4.SubmissionStatus>(data['data']);
    }
    if (dataClassName == 'SubmissionValues') {
      return deserialize<_iq9uje8l.SubmissionValues>(data['data']);
    }
    if (dataClassName == 'SubmissionView') {
      return deserialize<_iakndug7.SubmissionView>(data['data']);
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
    if (dataClassName == 'RevBusMessage') {
      return deserialize<_iyewfisw.RevBusMessage>(data['data']);
    }
    if (dataClassName == 'RevFile') {
      return deserialize<_ip7h3lg0.RevFile>(data['data']);
    }
    if (dataClassName == 'RevFileInfo') {
      return deserialize<_ihwy023l.RevFileInfo>(data['data']);
    }
    if (dataClassName == 'RevFileKind') {
      return deserialize<_iwkehf4e.RevFileKind>(data['data']);
    }
    if (dataClassName == 'RevHookState') {
      return deserialize<_ivfqwl6l.RevHookState>(data['data']);
    }
    if (dataClassName == 'RevOp') {
      return deserialize<_iax01zbg.RevOp>(data['data']);
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
    if (dataClassName == 'ServerChangeRecord') {
      return deserialize<_ibw3povl.ServerChangeRecord>(data['data']);
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
    if (dataClassName == 'StorageReservation') {
      return deserialize<_if4kaxov.StorageReservation>(data['data']);
    }
    if (dataClassName == 'UserStorage') {
      return deserialize<_is05u0nw.UserStorage>(data['data']);
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
    if (dataClassName == 'PersonalAccessToken') {
      return deserialize<_ijodrcyd.PersonalAccessToken>(data['data']);
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
    if (dataClassName == 'ItemVersionState') {
      return deserialize<_ibe5uno1.ItemVersionState>(data['data']);
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
    if (dataClassName == 'AiFunctionCache') {
      return deserialize<_i5vk0z7t.AiFunctionCache>(data['data']);
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
    if (dataClassName == 'SheetsImportJob') {
      return deserialize<_i74ohdg2.SheetsImportJob>(data['data']);
    }
    if (dataClassName == 'SheetsImportProgress') {
      return deserialize<_iaf43n69.SheetsImportProgress>(data['data']);
    }
    if (dataClassName == 'SheetsImportStatus') {
      return deserialize<_i8d83qca.SheetsImportStatus>(data['data']);
    }
    if (dataClassName == 'CellHistory') {
      return deserialize<_ik5lpvx4.CellHistory>(data['data']);
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
    if (dataClassName == 'Banding') {
      return deserialize<_i3p6on16.Banding>(data['data']);
    }
    if (dataClassName == 'BasicFilter') {
      return deserialize<_iofnuqg9.BasicFilter>(data['data']);
    }
    if (dataClassName == 'Cell') {
      return deserialize<_ifc5vn9h.Cell>(data['data']);
    }
    if (dataClassName == 'ConditionalFormatRule') {
      return deserialize<_iy4zsn6m.ConditionalFormatRule>(data['data']);
    }
    if (dataClassName == 'DataValidationRule') {
      return deserialize<_i5c2bsv2.DataValidationRule>(data['data']);
    }
    if (dataClassName == 'DimensionGroup') {
      return deserialize<_i145vl5m.DimensionGroup>(data['data']);
    }
    if (dataClassName == 'EmbeddedObject') {
      return deserialize<_iye9c0co.EmbeddedObject>(data['data']);
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
    if (dataClassName == 'FilterView') {
      return deserialize<_igzd7u0m.FilterView>(data['data']);
    }
    if (dataClassName == 'Macro') {
      return deserialize<_iiq43rv8.Macro>(data['data']);
    }
    if (dataClassName == 'MergedRange') {
      return deserialize<_i57rr32y.MergedRange>(data['data']);
    }
    if (dataClassName == 'NamedRange') {
      return deserialize<_irrybuvb.NamedRange>(data['data']);
    }
    if (dataClassName == 'PivotTable') {
      return deserialize<_iz580og3.PivotTable>(data['data']);
    }
    if (dataClassName == 'ProtectedRange') {
      return deserialize<_iz1b7y52.ProtectedRange>(data['data']);
    }
    if (dataClassName == 'ScriptBuild') {
      return deserialize<_ibdybin0.ScriptBuild>(data['data']);
    }
    if (dataClassName == 'ScriptFile') {
      return deserialize<_iplsajic.ScriptFile>(data['data']);
    }
    if (dataClassName == 'ScriptProject') {
      return deserialize<_iy6gs0qh.ScriptProject>(data['data']);
    }
    if (dataClassName == 'ScriptProperty') {
      return deserialize<_ig9hff0r.ScriptProperty>(data['data']);
    }
    if (dataClassName == 'ScriptTrigger') {
      return deserialize<_irlm292d.ScriptTrigger>(data['data']);
    }
    if (dataClassName == 'Sheet') {
      return deserialize<_i8c5x9aj.Sheet>(data['data']);
    }
    if (dataClassName == 'SheetColumn') {
      return deserialize<_i6chd4x2.SheetColumn>(data['data']);
    }
    if (dataClassName == 'SheetRow') {
      return deserialize<_i4k3x536.SheetRow>(data['data']);
    }
    if (dataClassName == 'Spreadsheet') {
      return deserialize<_ib6gxu4b.Spreadsheet>(data['data']);
    }
    if (dataClassName == 'ScriptUserProperty') {
      return deserialize<_ijtj1mph.ScriptUserProperty>(data['data']);
    }
    if (dataClassName == 'SheetsActivitySummary') {
      return deserialize<_iaehez21.SheetsActivitySummary>(data['data']);
    }
    if (dataClassName == 'SheetsContributorStat') {
      return deserialize<_i9yjzgjk.SheetsContributorStat>(data['data']);
    }
    if (dataClassName == 'SheetsSnapshotIndex') {
      return deserialize<_iwl8v9t3.SheetsSnapshotIndex>(data['data']);
    }
    if (dataClassName == 'ScriptAuthorization') {
      return deserialize<_ibv2hdjr.ScriptAuthorization>(data['data']);
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
    if (dataClassName == 'ScriptJob') {
      return deserialize<_i4e1yb8z.ScriptJob>(data['data']);
    }
    if (dataClassName == 'ScriptQuotaUsage') {
      return deserialize<_itn7c5zm.ScriptQuotaUsage>(data['data']);
    }
    if (dataClassName == 'ScriptRunResponse') {
      return deserialize<_is0mvar3.ScriptRunResponse>(data['data']);
    }
    if (dataClassName == 'ScriptRuntimeKind') {
      return deserialize<_iy0fj18f.ScriptRuntimeKind>(data['data']);
    }
    if (dataClassName == 'ScriptTriggerState') {
      return deserialize<_ixysij0q.ScriptTriggerState>(data['data']);
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
    if (dataClassName == 'ChartLink') {
      return deserialize<_ihkglt8b.ChartLink>(data['data']);
    }
    if (dataClassName == 'CodeState') {
      return deserialize<_i6svv371.CodeState>(data['data']);
    }
    if (dataClassName == 'Deck') {
      return deserialize<_ioalf2ve.Deck>(data['data']);
    }
    if (dataClassName == 'DeckTheme') {
      return deserialize<_i5vaufan.DeckTheme>(data['data']);
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
    if (dataClassName == 'Slide') {
      return deserialize<_ipsr29xb.Slide>(data['data']);
    }
    if (dataClassName == 'SlideBuild') {
      return deserialize<_izfj14nk.SlideBuild>(data['data']);
    }
    if (dataClassName == 'SlideElement') {
      return deserialize<_ih1q77t5.SlideElement>(data['data']);
    }
    if (dataClassName == 'SlideGroup') {
      return deserialize<_ic2hhlok.SlideGroup>(data['data']);
    }
    if (dataClassName == 'SlideLayout') {
      return deserialize<_i3k3vjpp.SlideLayout>(data['data']);
    }
    if (dataClassName == 'SlideMaster') {
      return deserialize<_igjrafa0.SlideMaster>(data['data']);
    }
    if (dataClassName == 'SlideTableAxis') {
      return deserialize<_iewd9d8j.SlideTableAxis>(data['data']);
    }
    if (dataClassName == 'SlideTableCell') {
      return deserialize<_ibnoy0fr.SlideTableCell>(data['data']);
    }
    if (dataClassName == 'PresentationBusMessage') {
      return deserialize<_ildgqgkz.PresentationBusMessage>(data['data']);
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
    if (dataClassName == 'SlidesSnapshotIndex') {
      return deserialize<_iy6ry83r.SlidesSnapshotIndex>(data['data']);
    }
    if (dataClassName == 'HeadlessChange') {
      return deserialize<_iilidizm.HeadlessChange>(data['data']);
    }
    if (dataClassName == 'DocAck') {
      return deserialize<_icpkpcrn.DocAck>(data['data']);
    }
    if (dataClassName == 'DocBusMessage') {
      return deserialize<_i8zfu67r.DocBusMessage>(data['data']);
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
    if (dataClassName == 'DocumentImportReport') {
      return deserialize<_ixppud51.DocumentImportReport>(data['data']);
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
    if (dataClassName == 'WriteDiffCache') {
      return deserialize<_ig4xquf5.WriteDiffCache>(data['data']);
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
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('wonky', this);
    _iacs.Protocol().registerHostProtocol('wonky', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _iatdjl5p.ActivityEvent:
        return _iatdjl5p.ActivityEvent.t;
      case _ixdmbuaj.ItemViewDay:
        return _ixdmbuaj.ItemViewDay.t;
      case _ifmsnq1y.UserActivitySettings:
        return _ifmsnq1y.UserActivitySettings.t;
      case _iuq1eobh.AiPreviewRecord:
        return _iuq1eobh.AiPreviewRecord.t;
      case _i7i53on7.AiUsage:
        return _i7i53on7.AiUsage.t;
      case _ivv7zvxt.AiUserKey:
        return _ivv7zvxt.AiUserKey.t;
      case _imx2nn1q.AiUserSetting:
        return _imx2nn1q.AiUserSetting.t;
      case _i8cittxq.AssistantMessage:
        return _i8cittxq.AssistantMessage.t;
      case _iaq6rutx.AssistantThread:
        return _iaq6rutx.AssistantThread.t;
      case _iamkojeb.UsageCounterDay:
        return _iamkojeb.UsageCounterDay.t;
      case _ibanfcrx.UsageDayStats:
        return _ibanfcrx.UsageDayStats.t;
      case _ik0bapqg.UserActivityDay:
        return _ik0bapqg.UserActivityDay.t;
      case _icowsqvh.BoardAiUsage:
        return _icowsqvh.BoardAiUsage.t;
      case _ilo15wk2.BoardBundleSuggestion:
        return _ilo15wk2.BoardBundleSuggestion.t;
      case _ijz5flk6.BoardComment:
        return _ijz5flk6.BoardComment.t;
      case _i0y7d0xd.BoardFlag:
        return _i0y7d0xd.BoardFlag.t;
      case _i5r22jl8.BoardGithubDelivery:
        return _i5r22jl8.BoardGithubDelivery.t;
      case _idxofexa.BoardModerationLog:
        return _idxofexa.BoardModerationLog.t;
      case _i7xps6dm.BoardPost:
        return _i7xps6dm.BoardPost.t;
      case _i36hp4a6.BoardPullRequest:
        return _i36hp4a6.BoardPullRequest.t;
      case _iv26y3a1.BoardTask:
        return _iv26y3a1.BoardTask.t;
      case _i516sz1w.BoardUserProfile:
        return _i516sz1w.BoardUserProfile.t;
      case _ifuo09i6.BoardVote:
        return _ifuo09i6.BoardVote.t;
      case _iyixppck.Comment:
        return _iyixppck.Comment.t;
      case _ijog60vm.CommentThread:
        return _ijog60vm.CommentThread.t;
      case _inge8yy2.DriveItem:
        return _inge8yy2.DriveItem.t;
      case _i0g2m831.DriveItemUserState:
        return _i0g2m831.DriveItemUserState.t;
      case _iu565i0a.FeedbackReport:
        return _iu565i0a.FeedbackReport.t;
      case _im8eh74x.StoredFile:
        return _im8eh74x.StoredFile.t;
      case _ik59hiyp.UserNotification:
        return _ik59hiyp.UserNotification.t;
      case _ikkxb56h.Publication:
        return _ikkxb56h.Publication.t;
      case _i5vk42yw.PublicationBlock:
        return _i5vk42yw.PublicationBlock.t;
      case _iqa48qn0.PublicationConsent:
        return _iqa48qn0.PublicationConsent.t;
      case _ihiygfti.PublicationDelivery:
        return _ihiygfti.PublicationDelivery.t;
      case _i1u9dlta.PublicationModerator:
        return _i1u9dlta.PublicationModerator.t;
      case _ipbg6o7y.Submission:
        return _ipbg6o7y.Submission.t;
      case _i49gtkgr.SubmissionAsset:
        return _i49gtkgr.SubmissionAsset.t;
      case _i71zy0hy.SubmissionRevision:
        return _i71zy0hy.SubmissionRevision.t;
      case _ip7h3lg0.RevFile:
        return _ip7h3lg0.RevFile.t;
      case _ivfqwl6l.RevHookState:
        return _ivfqwl6l.RevHookState.t;
      case _iax01zbg.RevOp:
        return _iax01zbg.RevOp.t;
      case _ibw3povl.ServerChangeRecord:
        return _ibw3povl.ServerChangeRecord.t;
      case _i8scn8dm.AccessRequest:
        return _i8scn8dm.AccessRequest.t;
      case _iuzgacy4.DriveItemPermission:
        return _iuzgacy4.DriveItemPermission.t;
      case _ijwxtu30.OwnershipTransfer:
        return _ijwxtu30.OwnershipTransfer.t;
      case _it712lg1.ShareLink:
        return _it712lg1.ShareLink.t;
      case _if4kaxov.StorageReservation:
        return _if4kaxov.StorageReservation.t;
      case _is05u0nw.UserStorage:
        return _is05u0nw.UserStorage.t;
      case _ijodrcyd.PersonalAccessToken:
        return _ijodrcyd.PersonalAccessToken.t;
      case _i501u5m5.UserPreferences:
        return _i501u5m5.UserPreferences.t;
      case _ihzl7wbq.UserProfile:
        return _ihzl7wbq.UserProfile.t;
      case _i7jb115m.ItemVersion:
        return _i7jb115m.ItemVersion.t;
      case _ibe5uno1.ItemVersionState:
        return _ibe5uno1.ItemVersionState.t;
      case _i5vk0z7t.AiFunctionCache:
        return _i5vk0z7t.AiFunctionCache.t;
      case _i74ohdg2.SheetsImportJob:
        return _i74ohdg2.SheetsImportJob.t;
      case _ik5lpvx4.CellHistory:
        return _ik5lpvx4.CellHistory.t;
      case _i3p6on16.Banding:
        return _i3p6on16.Banding.t;
      case _iofnuqg9.BasicFilter:
        return _iofnuqg9.BasicFilter.t;
      case _ifc5vn9h.Cell:
        return _ifc5vn9h.Cell.t;
      case _iy4zsn6m.ConditionalFormatRule:
        return _iy4zsn6m.ConditionalFormatRule.t;
      case _i5c2bsv2.DataValidationRule:
        return _i5c2bsv2.DataValidationRule.t;
      case _i145vl5m.DimensionGroup:
        return _i145vl5m.DimensionGroup.t;
      case _iye9c0co.EmbeddedObject:
        return _iye9c0co.EmbeddedObject.t;
      case _igzd7u0m.FilterView:
        return _igzd7u0m.FilterView.t;
      case _iiq43rv8.Macro:
        return _iiq43rv8.Macro.t;
      case _i57rr32y.MergedRange:
        return _i57rr32y.MergedRange.t;
      case _irrybuvb.NamedRange:
        return _irrybuvb.NamedRange.t;
      case _iz580og3.PivotTable:
        return _iz580og3.PivotTable.t;
      case _iz1b7y52.ProtectedRange:
        return _iz1b7y52.ProtectedRange.t;
      case _ibdybin0.ScriptBuild:
        return _ibdybin0.ScriptBuild.t;
      case _iplsajic.ScriptFile:
        return _iplsajic.ScriptFile.t;
      case _iy6gs0qh.ScriptProject:
        return _iy6gs0qh.ScriptProject.t;
      case _ig9hff0r.ScriptProperty:
        return _ig9hff0r.ScriptProperty.t;
      case _irlm292d.ScriptTrigger:
        return _irlm292d.ScriptTrigger.t;
      case _i8c5x9aj.Sheet:
        return _i8c5x9aj.Sheet.t;
      case _i6chd4x2.SheetColumn:
        return _i6chd4x2.SheetColumn.t;
      case _i4k3x536.SheetRow:
        return _i4k3x536.SheetRow.t;
      case _ib6gxu4b.Spreadsheet:
        return _ib6gxu4b.Spreadsheet.t;
      case _ijtj1mph.ScriptUserProperty:
        return _ijtj1mph.ScriptUserProperty.t;
      case _iwl8v9t3.SheetsSnapshotIndex:
        return _iwl8v9t3.SheetsSnapshotIndex.t;
      case _ibv2hdjr.ScriptAuthorization:
        return _ibv2hdjr.ScriptAuthorization.t;
      case _i4bc0fek.ScriptExecution:
        return _i4bc0fek.ScriptExecution.t;
      case _i4e1yb8z.ScriptJob:
        return _i4e1yb8z.ScriptJob.t;
      case _itn7c5zm.ScriptQuotaUsage:
        return _itn7c5zm.ScriptQuotaUsage.t;
      case _ixysij0q.ScriptTriggerState:
        return _ixysij0q.ScriptTriggerState.t;
      case _ihkglt8b.ChartLink:
        return _ihkglt8b.ChartLink.t;
      case _i6svv371.CodeState:
        return _i6svv371.CodeState.t;
      case _ioalf2ve.Deck:
        return _ioalf2ve.Deck.t;
      case _i5vaufan.DeckTheme:
        return _i5vaufan.DeckTheme.t;
      case _ipsr29xb.Slide:
        return _ipsr29xb.Slide.t;
      case _izfj14nk.SlideBuild:
        return _izfj14nk.SlideBuild.t;
      case _ih1q77t5.SlideElement:
        return _ih1q77t5.SlideElement.t;
      case _ic2hhlok.SlideGroup:
        return _ic2hhlok.SlideGroup.t;
      case _i3k3vjpp.SlideLayout:
        return _i3k3vjpp.SlideLayout.t;
      case _igjrafa0.SlideMaster:
        return _igjrafa0.SlideMaster.t;
      case _iewd9d8j.SlideTableAxis:
        return _iewd9d8j.SlideTableAxis.t;
      case _ibnoy0fr.SlideTableCell:
        return _ibnoy0fr.SlideTableCell.t;
      case _iy6ry83r.SlidesSnapshotIndex:
        return _iy6ry83r.SlidesSnapshotIndex.t;
      case _iilidizm.HeadlessChange:
        return _iilidizm.HeadlessChange.t;
      case _i4sx4pml.Document:
        return _i4sx4pml.Document.t;
      case _ixppud51.DocumentImportReport:
        return _ixppud51.DocumentImportReport.t;
      case _ir38bcqq.DocumentMetaChange:
        return _ir38bcqq.DocumentMetaChange.t;
      case _iufsprkx.DocumentOp:
        return _iufsprkx.DocumentOp.t;
      case _i2cnn8i8.DocumentSnapshot:
        return _i2cnn8i8.DocumentSnapshot.t;
      case _ig4xquf5.WriteDiffCache:
        return _ig4xquf5.WriteDiffCache.t;
      case _iynqrh33.WriteTheme:
        return _iynqrh33.WriteTheme.t;
      case _i7pbwt05.WriteThemeRevision:
        return _i7pbwt05.WriteThemeRevision.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
