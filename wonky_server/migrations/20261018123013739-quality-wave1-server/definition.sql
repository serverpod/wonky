BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- Class AccessRequest as table access_request
--
CREATE TABLE "access_request" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "requesterId" bigint NOT NULL,
    "requestedRole" text NOT NULL,
    "message" text,
    "createdAt" timestamp without time zone NOT NULL,
    "handledAt" timestamp without time zone,
    "handledById" bigint,
    "outcome" text
);

-- Indexes
CREATE INDEX "access_request_item_idx" ON "access_request" USING btree ("itemId", "handledAt");

--
-- Class ActivityEvent as table activity_event
--
CREATE TABLE "activity_event" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "actorId" bigint,
    "actorKind" text NOT NULL,
    "type" text NOT NULL,
    "summary" text NOT NULL,
    "at" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "activity_item_idx" ON "activity_event" USING btree ("itemId", "at");

--
-- Class AiFunctionCache as table ai_function_cache
--
CREATE TABLE "ai_function_cache" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "model" text NOT NULL,
    "value" text NOT NULL,
    "error" text,
    "createdAt" timestamp without time zone NOT NULL,
    "hits" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "ai_function_cache_key_idx" ON "ai_function_cache" USING btree ("key");
CREATE INDEX "ai_function_cache_sheet_idx" ON "ai_function_cache" USING btree ("spreadsheetUuid");

--
-- Class AiUsage as table ai_usage
--
CREATE TABLE "ai_usage" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "model" text NOT NULL,
    "feature" text NOT NULL,
    "inputTokens" bigint NOT NULL,
    "outputTokens" bigint NOT NULL,
    "cacheReadTokens" bigint NOT NULL,
    "cacheWriteTokens" bigint NOT NULL,
    "at" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "ai_usage_user_at_idx" ON "ai_usage" USING btree ("userId", "at");

--
-- Class AiUserKey as table ai_user_key
--
CREATE TABLE "ai_user_key" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "provider" text NOT NULL,
    "apiKey" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "ai_user_key_user_idx" ON "ai_user_key" USING btree ("userId");

--
-- Class AiUserSetting as table ai_user_setting
--
CREATE TABLE "ai_user_setting" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "quality" text NOT NULL DEFAULT 'best'::text,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "ai_user_setting_user_idx" ON "ai_user_setting" USING btree ("userId");

--
-- Class AssistantMessage as table assistant_message
--
CREATE TABLE "assistant_message" (
    "id" bigserial PRIMARY KEY,
    "threadId" bigint NOT NULL,
    "role" text NOT NULL,
    "contentJson" text,
    "displayText" text NOT NULL,
    "toolCallsJson" text,
    "visible" boolean NOT NULL DEFAULT true,
    "replay" boolean NOT NULL DEFAULT true,
    "runId" text,
    "stopReason" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "assistant_message_thread_idx" ON "assistant_message" USING btree ("threadId", "id");

--
-- Class AssistantThread as table assistant_thread
--
CREATE TABLE "assistant_thread" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "itemId" bigint,
    "title" text NOT NULL,
    "contextRevision" bigint,
    "contextMarkdown" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "assistant_thread_user_item_idx" ON "assistant_thread" USING btree ("userId", "itemId", "updatedAt");

--
-- Class Banding as table banding
--
CREATE TABLE "banding" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "rangeJson" text NOT NULL,
    "styleJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "banding_file_idx" ON "banding" USING btree ("fileId", "id");

--
-- Class BasicFilter as table basic_filter
--
CREATE TABLE "basic_filter" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "rangeJson" text NOT NULL,
    "criteriaJson" text NOT NULL,
    "sortJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "basic_filter_file_idx" ON "basic_filter" USING btree ("fileId", "id");

--
-- Class BoardAiUsage as table board_ai_usage
--
CREATE TABLE "board_ai_usage" (
    "id" bigserial PRIMARY KEY,
    "day" text NOT NULL,
    "provider" text NOT NULL,
    "model" text NOT NULL,
    "feature" text NOT NULL,
    "requests" bigint NOT NULL,
    "inputTokens" bigint NOT NULL,
    "outputTokens" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "board_ai_usage_idx" ON "board_ai_usage" USING btree ("day", "provider", "model", "feature");

--
-- Class BoardBundleSuggestion as table board_bundle_suggestion
--
CREATE TABLE "board_bundle_suggestion" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "rationale" text NOT NULL,
    "area" text,
    "postIds" json NOT NULL,
    "state" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- Class BoardComment as table board_comment
--
CREATE TABLE "board_comment" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "postId" bigint,
    "taskId" bigint,
    "authorId" bigint,
    "body" text NOT NULL,
    "systemEvent" text,
    "moderation" text NOT NULL,
    "moderationReason" text,
    "needsCheck" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL,
    "editedAt" timestamp without time zone,
    "deletedAt" timestamp without time zone,
    "removedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "board_comment_uuid_idx" ON "board_comment" USING btree ("uuid");
CREATE INDEX "board_comment_post_idx" ON "board_comment" USING btree ("postId", "createdAt");
CREATE INDEX "board_comment_task_idx" ON "board_comment" USING btree ("taskId", "createdAt");

--
-- Class BoardFlag as table board_flag
--
CREATE TABLE "board_flag" (
    "id" bigserial PRIMARY KEY,
    "postId" bigint,
    "commentId" bigint,
    "userId" bigint NOT NULL,
    "reason" text NOT NULL,
    "note" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "board_flag_post_idx" ON "board_flag" USING btree ("postId", "userId");
CREATE INDEX "board_flag_comment_idx" ON "board_flag" USING btree ("commentId", "userId");

--
-- Class BoardGithubDelivery as table board_github_delivery
--
CREATE TABLE "board_github_delivery" (
    "id" bigserial PRIMARY KEY,
    "deliveryId" text NOT NULL,
    "event" text NOT NULL,
    "receivedAt" timestamp without time zone NOT NULL,
    "payload" text,
    "processedAt" timestamp without time zone,
    "attempts" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "board_github_delivery_idx" ON "board_github_delivery" USING btree ("deliveryId");

--
-- Class BoardModerationLog as table board_moderation_log
--
CREATE TABLE "board_moderation_log" (
    "id" bigserial PRIMARY KEY,
    "adminId" bigint NOT NULL,
    "action" text NOT NULL,
    "targetKind" text NOT NULL,
    "targetId" bigint NOT NULL,
    "beforeJson" text,
    "afterJson" text,
    "reason" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "board_moderation_log_target_idx" ON "board_moderation_log" USING btree ("targetKind", "targetId");

--
-- Class BoardPost as table board_post
--
CREATE TABLE "board_post" (
    "id" bigserial PRIMARY KEY,
    "authorId" bigint,
    "kind" text NOT NULL,
    "reportedKind" text NOT NULL,
    "area" text,
    "size" text,
    "aiLabels" boolean NOT NULL DEFAULT true,
    "title" text NOT NULL,
    "body" text NOT NULL,
    "contextJson" text,
    "appHint" text NOT NULL,
    "screenshotFileId" bigint,
    "status" text NOT NULL,
    "moderation" text NOT NULL,
    "moderationReason" text,
    "needsCheck" boolean NOT NULL DEFAULT false,
    "editedByModerator" boolean NOT NULL DEFAULT false,
    "triageState" text NOT NULL,
    "triageJson" text,
    "triageAttempts" bigint NOT NULL DEFAULT 0,
    "suggestedTitle" text,
    "summary" text,
    "duplicateOfId" bigint,
    "possibleDuplicateOfId" bigint,
    "duplicateHintDismissed" boolean NOT NULL DEFAULT false,
    "declineReason" text,
    "taskId" bigint,
    "score" bigint NOT NULL DEFAULT 0,
    "voteCount" bigint NOT NULL DEFAULT 0,
    "commentCount" bigint NOT NULL DEFAULT 0,
    "flagCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "editedAt" timestamp without time zone,
    "deletedAt" timestamp without time zone,
    "removedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "board_post_list_idx" ON "board_post" USING btree ("moderation", "kind", "status", "score");
CREATE INDEX "board_post_author_idx" ON "board_post" USING btree ("authorId");
CREATE INDEX "board_post_task_idx" ON "board_post" USING btree ("taskId");

--
-- Class BoardPullRequest as table board_pull_request
--
CREATE TABLE "board_pull_request" (
    "id" bigserial PRIMARY KEY,
    "prNumber" bigint NOT NULL,
    "taskId" bigint,
    "authorLogin" text NOT NULL,
    "headSha" text NOT NULL,
    "state" text NOT NULL,
    "gateState" text NOT NULL,
    "gateReason" text,
    "gateFirstFailedAt" timestamp without time zone,
    "gateCommentId" bigint,
    "reviewCommentId" bigint,
    "lastReviewSha" text,
    "lastReviewJson" text,
    "lastReviewAt" timestamp without time zone,
    "reviewDay" text,
    "reviewCount" bigint NOT NULL DEFAULT 0,
    "mergeCommitSha" text,
    "reviewPendingSha" text,
    "reviewDueAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "board_pull_request_number_idx" ON "board_pull_request" USING btree ("prNumber");

--
-- Class BoardTask as table board_task
--
CREATE TABLE "board_task" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "area" text NOT NULL,
    "size" text NOT NULL,
    "status" text NOT NULL,
    "promptBody" text NOT NULL,
    "promptGeneratedAt" timestamp without time zone,
    "promptRequestedAt" timestamp without time zone,
    "promptNote" text,
    "promptEditedById" bigint,
    "promptEditedAt" timestamp without time zone,
    "createdById" bigint NOT NULL,
    "publishedAt" timestamp without time zone,
    "claimedById" bigint,
    "claimedAt" timestamp without time zone,
    "claimExpiresAt" timestamp without time zone,
    "claimWarnedAt" timestamp without time zone,
    "claimCode" text,
    "pullRequestUrl" text,
    "prNumber" bigint,
    "prAuthorLogin" text,
    "mergeCommitSha" text,
    "doneAt" timestamp without time zone,
    "shippedDeploySha" text,
    "shippedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "board_task_status_idx" ON "board_task" USING btree ("status");
CREATE INDEX "board_task_claim_idx" ON "board_task" USING btree ("claimedById");

--
-- Class BoardUserProfile as table board_user_profile
--
CREATE TABLE "board_user_profile" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "githubLogin" text,
    "blockedAt" timestamp without time zone,
    "blockedUntil" timestamp without time zone,
    "blockedReason" text,
    "blockedById" bigint
);

-- Indexes
CREATE UNIQUE INDEX "board_user_profile_user_idx" ON "board_user_profile" USING btree ("userId");

--
-- Class BoardVote as table board_vote
--
CREATE TABLE "board_vote" (
    "id" bigserial PRIMARY KEY,
    "postId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "value" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "board_vote_unique_idx" ON "board_vote" USING btree ("postId", "userId");
CREATE INDEX "board_vote_recent_idx" ON "board_vote" USING btree ("postId", "createdAt");

--
-- Class Cell as table cell
--
CREATE TABLE "cell" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "rowId" uuid NOT NULL,
    "columnId" uuid NOT NULL,
    "content" text,
    "note" text,
    "numberFormat" text,
    "fontFamily" text,
    "fontSize" double precision,
    "bold" boolean,
    "italic" boolean,
    "underline" boolean,
    "strikethrough" boolean,
    "textColor" text,
    "fillColor" text,
    "hAlign" text,
    "vAlign" text,
    "wrap" text,
    "rotation" bigint,
    "borderTop" text,
    "borderRight" text,
    "borderBottom" text,
    "borderLeft" text,
    "linkUrl" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "cell_row_idx" ON "cell" USING btree ("sheetId", "rowId");
CREATE INDEX "cell_col_idx" ON "cell" USING btree ("sheetId", "columnId");

--
-- Class CellHistory as table cell_history
--
CREATE TABLE "cell_history" (
    "id" bigserial PRIMARY KEY,
    "fileUuid" uuid NOT NULL,
    "sheetId" uuid NOT NULL,
    "rowId" uuid NOT NULL,
    "colId" uuid NOT NULL,
    "revision" bigint NOT NULL,
    "userUuid" uuid NOT NULL,
    "actorKind" text NOT NULL,
    "label" text NOT NULL,
    "at" timestamp without time zone NOT NULL,
    "before" text,
    "after" text
);

-- Indexes
CREATE INDEX "cell_history_cell_idx" ON "cell_history" USING btree ("fileUuid", "sheetId", "rowId", "colId", "at");
CREATE UNIQUE INDEX "cell_history_change_idx" ON "cell_history" USING btree ("fileUuid", "revision", "rowId", "colId");

--
-- Class ChartLink as table chart_link
--
CREATE TABLE "chart_link" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "elementId" uuid NOT NULL,
    "spreadsheetItemUuid" uuid NOT NULL,
    "chartObjectId" uuid NOT NULL,
    "sheetId" text,
    "sourceSpecJson" text NOT NULL,
    "dataSnapshotJson" text NOT NULL,
    "sourceVersion" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "updatedBy" uuid NOT NULL,
    "autoUpdate" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "chart_link_file_idx" ON "chart_link" USING btree ("fileId", "id");
CREATE INDEX "chart_link_element_idx" ON "chart_link" USING btree ("elementId");

--
-- Class CodeState as table code_state
--
CREATE TABLE "code_state" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "elementId" uuid NOT NULL,
    "sortKey" text NOT NULL,
    "label" text,
    "code" text NOT NULL,
    "language" text,
    "title" text,
    "highlight" text,
    "annotationsJson" text,
    "transitionJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "code_state_file_idx" ON "code_state" USING btree ("fileId", "id");
CREATE INDEX "code_state_element_idx" ON "code_state" USING btree ("elementId", "sortKey");

--
-- Class Comment as table comment
--
CREATE TABLE "comment" (
    "id" bigserial PRIMARY KEY,
    "threadId" bigint NOT NULL,
    "uuid" uuid,
    "authorId" bigint,
    "authorKind" text NOT NULL,
    "body" text NOT NULL,
    "mentions" json NOT NULL,
    "reactions" text NOT NULL DEFAULT '{}'::text,
    "createdAt" timestamp without time zone NOT NULL,
    "editedAt" timestamp without time zone,
    "deletedAt" timestamp without time zone,
    "systemEvent" text
);

-- Indexes
CREATE INDEX "comment_thread_idx" ON "comment" USING btree ("threadId", "createdAt");
CREATE UNIQUE INDEX "comment_uuid_idx" ON "comment" USING btree ("uuid");

--
-- Class CommentThread as table comment_thread
--
CREATE TABLE "comment_thread" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "itemId" bigint NOT NULL,
    "anchorKind" text NOT NULL,
    "anchorJson" text NOT NULL,
    "quotedText" text,
    "status" text NOT NULL DEFAULT 'open'::text,
    "createdById" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "resolvedById" bigint,
    "resolvedAt" timestamp without time zone,
    "assigneeId" bigint,
    "statusBeforeOrphan" text,
    "orphanReasonJson" text,
    "suggestionId" text
);

-- Indexes
CREATE INDEX "comment_thread_item_idx" ON "comment_thread" USING btree ("itemId", "status");
CREATE UNIQUE INDEX "comment_thread_uuid_idx" ON "comment_thread" USING btree ("uuid");

--
-- Class ConditionalFormatRule as table conditional_format_rule
--
CREATE TABLE "conditional_format_rule" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "sortKey" text NOT NULL,
    "rangesJson" text NOT NULL,
    "ruleJson" text NOT NULL,
    "enabled" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "conditional_format_rule_file_idx" ON "conditional_format_rule" USING btree ("fileId", "id");

--
-- Class DataValidationRule as table data_validation_rule
--
CREATE TABLE "data_validation_rule" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "rangesJson" text NOT NULL,
    "criteriaJson" text NOT NULL,
    "strict" boolean NOT NULL DEFAULT false,
    "showDropdown" boolean NOT NULL DEFAULT true,
    "displayStyle" text,
    "helpText" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "data_validation_rule_file_idx" ON "data_validation_rule" USING btree ("fileId", "id");

--
-- Class Deck as table deck
--
CREATE TABLE "deck" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "title" text NOT NULL,
    "width" double precision NOT NULL DEFAULT 1920.0,
    "height" double precision NOT NULL DEFAULT 1080.0,
    "sizePreset" text NOT NULL DEFAULT 'widescreen16x9'::text,
    "themeId" uuid,
    "appearance" text NOT NULL DEFAULT 'light'::text,
    "language" text,
    "showSlideNumbers" boolean NOT NULL DEFAULT false,
    "hideNumberOnTitle" boolean NOT NULL DEFAULT true,
    "firstSlideNumber" bigint NOT NULL DEFAULT 1,
    "footerText" text,
    "defaultsJson" text,
    "guidesJson" text,
    "presentJson" text,
    "createdBy" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "deck_file_idx" ON "deck" USING btree ("fileId", "id");

--
-- Class DeckTheme as table deck_theme
--
CREATE TABLE "deck_theme" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "deckId" uuid NOT NULL,
    "name" text NOT NULL,
    "sourceKey" text,
    "colorsJson" text NOT NULL,
    "fontsJson" text NOT NULL,
    "textStylesJson" text NOT NULL,
    "backgroundJson" text NOT NULL,
    "shapeStyleJson" text,
    "tableStyleJson" text,
    "codeStyleJson" text,
    "chartStyleJson" text,
    "sortKey" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "deck_theme_file_idx" ON "deck_theme" USING btree ("fileId", "id");
CREATE INDEX "deck_theme_deck_idx" ON "deck_theme" USING btree ("deckId");

--
-- Class DimensionGroup as table dimension_group
--
CREATE TABLE "dimension_group" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "dimension" text NOT NULL,
    "startId" uuid NOT NULL,
    "endId" uuid NOT NULL,
    "depth" bigint NOT NULL,
    "collapsed" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "dimension_group_file_idx" ON "dimension_group" USING btree ("fileId", "id");

--
-- Class Document as table document
--
CREATE TABLE "document" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "itemId" bigint NOT NULL,
    "headRevision" bigint NOT NULL DEFAULT 0,
    "latestSnapshotRevision" bigint NOT NULL DEFAULT 0,
    "themeId" uuid,
    "pageSetupJson" text NOT NULL DEFAULT '{}'::text,
    "language" text,
    "frontMatter" text,
    "charCount" bigint NOT NULL DEFAULT 0,
    "wordCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "document_uuid_idx" ON "document" USING btree ("uuid");
CREATE UNIQUE INDEX "document_item_idx" ON "document" USING btree ("itemId");

--
-- Class DocumentImportReport as table document_import_report
--
CREATE TABLE "document_import_report" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "warningsJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "seenAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "document_import_report_idx" ON "document_import_report" USING btree ("documentId", "userId");

--
-- Class DocumentMetaChange as table document_meta_change
--
CREATE TABLE "document_meta_change" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "field" text NOT NULL,
    "clientOpId" uuid,
    "beforeJson" text NOT NULL,
    "afterJson" text NOT NULL,
    "authorId" bigint,
    "actorKind" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "document_meta_change_idx" ON "document_meta_change" USING btree ("documentId", "createdAt");
CREATE UNIQUE INDEX "document_meta_change_client_idx" ON "document_meta_change" USING btree ("documentId", "clientOpId");

--
-- Class DocumentOp as table document_op
--
CREATE TABLE "document_op" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "revision" bigint NOT NULL,
    "clientOpId" uuid NOT NULL,
    "authorId" bigint,
    "actorKind" text NOT NULL,
    "sessionId" text,
    "kind" text NOT NULL,
    "baseRevision" bigint NOT NULL,
    "deltaJson" text NOT NULL,
    "inverseJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "document_op_rev_idx" ON "document_op" USING btree ("documentId", "revision");
CREATE UNIQUE INDEX "document_op_client_idx" ON "document_op" USING btree ("documentId", "clientOpId");
CREATE INDEX "document_op_created_idx" ON "document_op" USING brin ("createdAt");

--
-- Class DocumentSnapshot as table document_snapshot
--
CREATE TABLE "document_snapshot" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "revision" bigint NOT NULL,
    "deltaJson" text NOT NULL,
    "compressed" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "document_snapshot_idx" ON "document_snapshot" USING btree ("documentId", "revision");

--
-- Class DriveItem as table drive_item
--
CREATE TABLE "drive_item" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "kind" text NOT NULL,
    "name" text NOT NULL,
    "ownerId" bigint NOT NULL,
    "parentId" bigint,
    "description" text,
    "contentRef" uuid,
    "thumbnailFileId" uuid,
    "sizeBytes" bigint NOT NULL DEFAULT 0,
    "attachmentBytes" bigint NOT NULL DEFAULT 0,
    "kindMask" bigint NOT NULL DEFAULT 0,
    "mimeType" text,
    "fileCategory" text,
    "uploadState" text,
    "fileMetaJson" text,
    "previewFileId" uuid,
    "createdAt" timestamp without time zone NOT NULL,
    "createdById" bigint NOT NULL,
    "modifiedAt" timestamp without time zone NOT NULL,
    "modifiedById" bigint,
    "trashedAt" timestamp without time zone,
    "trashedById" bigint,
    "templateOf" text,
    "templateKey" text,
    "editorsCanShare" boolean NOT NULL DEFAULT true,
    "nonEditorsCanExport" boolean NOT NULL DEFAULT true,
    "viewersSeeComments" boolean NOT NULL DEFAULT false,
    "searchText" text
);

-- Indexes
CREATE UNIQUE INDEX "drive_item_uuid_idx" ON "drive_item" USING btree ("uuid");
CREATE INDEX "drive_item_parent_idx" ON "drive_item" USING btree ("parentId");
CREATE INDEX "drive_item_owner_idx" ON "drive_item" USING btree ("ownerId", "trashedAt");
CREATE INDEX "drive_item_content_idx" ON "drive_item" USING btree ("contentRef");
CREATE INDEX "drive_item_template_idx" ON "drive_item" USING btree ("templateOf");
CREATE INDEX "drive_item_upload_idx" ON "drive_item" USING btree ("uploadState", "createdAt");
CREATE INDEX "drive_item_trashed_idx" ON "drive_item" USING btree ("trashedAt");

--
-- Class DriveItemPermission as table drive_item_permission
--
CREATE TABLE "drive_item_permission" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "userId" bigint,
    "invitedEmail" text,
    "role" text NOT NULL,
    "inheritedFromId" bigint,
    "grantedById" bigint NOT NULL,
    "grantedAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "perm_item_user_idx" ON "drive_item_permission" USING btree ("itemId", "userId", "inheritedFromId", "invitedEmail") NULLS NOT DISTINCT;
CREATE INDEX "perm_user_idx" ON "drive_item_permission" USING btree ("userId");
CREATE INDEX "perm_email_idx" ON "drive_item_permission" USING btree ("invitedEmail");
CREATE INDEX "perm_expires_idx" ON "drive_item_permission" USING btree ("expiresAt");

--
-- Class DriveItemUserState as table drive_item_user_state
--
CREATE TABLE "drive_item_user_state" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "starred" boolean NOT NULL DEFAULT false,
    "lastOpenedAt" timestamp without time zone,
    "lastEditedAt" timestamp without time zone,
    "pinnedOffline" boolean NOT NULL DEFAULT false,
    "shortcutParentId" bigint,
    "viaLink" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "drive_item_user_state_idx" ON "drive_item_user_state" USING btree ("itemId", "userId");
CREATE INDEX "drive_item_user_recent_idx" ON "drive_item_user_state" USING btree ("userId", "lastOpenedAt");

--
-- Class EmbeddedObject as table embedded_object
--
CREATE TABLE "embedded_object" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "kind" text NOT NULL,
    "anchorJson" text NOT NULL,
    "specJson" text NOT NULL,
    "zIndex" bigint NOT NULL DEFAULT 0,
    "title" text,
    "altText" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "embedded_object_file_idx" ON "embedded_object" USING btree ("fileId", "id");

--
-- Class FeedbackReport as table feedback_report
--
CREATE TABLE "feedback_report" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint,
    "kind" text NOT NULL,
    "message" text NOT NULL,
    "app" text NOT NULL,
    "appVersion" text NOT NULL,
    "platform" text NOT NULL,
    "route" text,
    "stackTrace" text,
    "contextJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "feedback_report_created_idx" ON "feedback_report" USING btree ("createdAt");

--
-- Class FilterView as table filter_view
--
CREATE TABLE "filter_view" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "name" text NOT NULL,
    "rangeJson" text NOT NULL,
    "criteriaJson" text NOT NULL,
    "sortJson" text,
    "createdBy" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "filter_view_file_idx" ON "filter_view" USING btree ("fileId", "id");

--
-- Class HeadlessChange as table headless_change
--
CREATE TABLE "headless_change" (
    "id" bigserial PRIMARY KEY,
    "changeId" uuid NOT NULL,
    "kind" text NOT NULL,
    "itemId" bigint NOT NULL,
    "documentId" bigint,
    "revision" bigint,
    "inverseJson" text,
    "metaField" text,
    "metaBeforeJson" text,
    "metaAfterJson" text,
    "userId" bigint NOT NULL,
    "actorKind" text NOT NULL,
    "label" text,
    "toolName" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "revertedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "headless_change_id_idx" ON "headless_change" USING btree ("changeId");
CREATE INDEX "headless_change_created_idx" ON "headless_change" USING btree ("createdAt");

--
-- Class ItemVersion as table item_version
--
CREATE TABLE "item_version" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "kind" text NOT NULL,
    "name" text,
    "createdAt" timestamp without time zone NOT NULL,
    "createdById" bigint,
    "authors" json NOT NULL,
    "storageKind" text NOT NULL,
    "revision" bigint,
    "snapshotFileId" uuid,
    "sizeBytes" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE INDEX "item_version_item_idx" ON "item_version" USING btree ("itemId", "createdAt");

--
-- Class ItemVersionState as table item_version_state
--
CREATE TABLE "item_version_state" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "lastEditAt" timestamp without time zone NOT NULL,
    "dirtySince" timestamp without time zone,
    "lastVersionAt" timestamp without time zone,
    "editorsSinceLastVersion" json NOT NULL,
    "lastRevision" bigint,
    "capturingSince" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "item_version_state_item_idx" ON "item_version_state" USING btree ("itemId");
CREATE INDEX "item_version_state_dirty_idx" ON "item_version_state" USING btree ("dirtySince");

--
-- Class ItemViewDay as table item_view_day
--
CREATE TABLE "item_view_day" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "day" timestamp without time zone NOT NULL,
    "views" bigint NOT NULL DEFAULT 1,
    "lastViewedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "item_view_day_idx" ON "item_view_day" USING btree ("itemId", "userId", "day");
CREATE INDEX "item_view_day_item_idx" ON "item_view_day" USING btree ("itemId", "day");

--
-- Class Macro as table macro
--
CREATE TABLE "macro" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "projectId" uuid NOT NULL,
    "name" text NOT NULL,
    "functionName" text NOT NULL,
    "shortcutSlot" bigint,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "macro_file_idx" ON "macro" USING btree ("fileId", "id");

--
-- Class MergedRange as table merged_range
--
CREATE TABLE "merged_range" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "rangeJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "merged_range_file_idx" ON "merged_range" USING btree ("fileId", "id");

--
-- Class NamedRange as table named_range
--
CREATE TABLE "named_range" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "spreadsheetId" uuid NOT NULL,
    "name" text NOT NULL,
    "rangeJson" text,
    "formula" text,
    "comment" text,
    "metaJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "named_range_file_idx" ON "named_range" USING btree ("fileId", "id");

--
-- Class UserNotification as table notification
--
CREATE TABLE "notification" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "kind" text NOT NULL,
    "itemId" bigint,
    "actorId" bigint,
    "payload" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "readAt" timestamp without time zone,
    "emailedAt" timestamp without time zone,
    "emailPending" boolean DEFAULT false
);

-- Indexes
CREATE INDEX "notification_user_idx" ON "notification" USING btree ("userId", "createdAt");
CREATE INDEX "notification_email_idx" ON "notification" USING btree ("emailPending", "createdAt");
CREATE INDEX "notification_created_idx" ON "notification" USING brin ("createdAt");

--
-- Class OwnershipTransfer as table ownership_transfer
--
CREATE TABLE "ownership_transfer" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "fromUserId" bigint NOT NULL,
    "toUserId" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "handledAt" timestamp without time zone,
    "accepted" boolean
);

-- Indexes
CREATE INDEX "ownership_transfer_item_idx" ON "ownership_transfer" USING btree ("itemId", "handledAt");

--
-- Class PersonalAccessToken as table personal_access_token
--
CREATE TABLE "personal_access_token" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "name" text NOT NULL,
    "tokenHash" text NOT NULL,
    "prefix" text NOT NULL,
    "scopes" json NOT NULL,
    "expiresAt" timestamp without time zone,
    "lastUsedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "revokedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "personal_access_token_user_idx" ON "personal_access_token" USING btree ("userId");
CREATE UNIQUE INDEX "personal_access_token_hash_idx" ON "personal_access_token" USING btree ("tokenHash");

--
-- Class PivotTable as table pivot_table
--
CREATE TABLE "pivot_table" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "anchorRowId" uuid NOT NULL,
    "anchorColId" uuid NOT NULL,
    "sourceRangeJson" text NOT NULL,
    "specJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "pivot_table_file_idx" ON "pivot_table" USING btree ("fileId", "id");

--
-- Class ProtectedRange as table protected_range
--
CREATE TABLE "protected_range" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "rangeJson" text,
    "exceptRangesJson" text,
    "description" text,
    "warningOnly" boolean NOT NULL DEFAULT false,
    "editorsJson" text NOT NULL,
    "createdBy" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "protected_range_file_idx" ON "protected_range" USING btree ("fileId", "id");

--
-- Class RevFile as table rev_file
--
CREATE TABLE "rev_file" (
    "id" bigserial PRIMARY KEY,
    "fileUuid" uuid NOT NULL,
    "kind" text NOT NULL,
    "itemId" bigint NOT NULL,
    "headRevision" bigint NOT NULL DEFAULT 0,
    "prunedBelow" bigint NOT NULL DEFAULT 0,
    "initPending" boolean NOT NULL DEFAULT false,
    "purging" boolean NOT NULL DEFAULT false,
    "schemaHash" text NOT NULL,
    "stats" text NOT NULL DEFAULT '{}'::text,
    "contentCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "rev_file_uuid_idx" ON "rev_file" USING btree ("fileUuid");
CREATE UNIQUE INDEX "rev_file_item_idx" ON "rev_file" USING btree ("itemId");

--
-- Class RevHookState as table rev_hook_state
--
CREATE TABLE "rev_hook_state" (
    "id" bigserial PRIMARY KEY,
    "fileId" bigint NOT NULL,
    "cursorsJson" text NOT NULL,
    "leaseOwner" text,
    "leaseUntil" timestamp without time zone,
    "attempts" bigint NOT NULL DEFAULT 0,
    "lastError" text,
    "nextAttemptAt" timestamp without time zone,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "rev_hook_state_file_idx" ON "rev_hook_state" USING btree ("fileId");
CREATE INDEX "rev_hook_state_due_idx" ON "rev_hook_state" USING btree ("nextAttemptAt");

--
-- Class RevOp as table rev_op
--
CREATE TABLE "rev_op" (
    "id" bigserial PRIMARY KEY,
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL,
    "clientOpId" uuid NOT NULL,
    "baseRevision" bigint NOT NULL,
    "authorId" bigint,
    "authorUuid" uuid,
    "sessionId" text,
    "onBehalfOfSessionId" text,
    "actorKind" text NOT NULL,
    "label" text NOT NULL,
    "groupId" text,
    "groupIndex" bigint NOT NULL DEFAULT 0,
    "groupLast" boolean NOT NULL DEFAULT true,
    "recordId" uuid,
    "offline" boolean NOT NULL DEFAULT false,
    "payload" bytea,
    "changeCount" bigint NOT NULL,
    "summaryJson" text,
    "detailJson" text,
    "outcomeJson" text,
    "appliedEqualsSubmitted" boolean NOT NULL,
    "clientCreatedAt" timestamp without time zone,
    "committedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "rev_op_rev_idx" ON "rev_op" USING btree ("fileId", "revision");
CREATE UNIQUE INDEX "rev_op_client_idx" ON "rev_op" USING btree ("fileId", "clientOpId");
CREATE INDEX "rev_op_record_idx" ON "rev_op" USING btree ("recordId");
CREATE INDEX "rev_op_committed_idx" ON "rev_op" USING brin ("committedAt");

--
-- Class ScriptAuthorization as table script_authorization
--
CREATE TABLE "script_authorization" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "scopes" json NOT NULL,
    "grantedAt" timestamp without time zone NOT NULL,
    "revokedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "script_auth_user_sheet_idx" ON "script_authorization" USING btree ("userId", "spreadsheetUuid");

--
-- Class ScriptBuild as table script_build
--
CREATE TABLE "script_build" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "projectId" uuid NOT NULL,
    "status" text NOT NULL DEFAULT 'ok'::text,
    "sourceHash" text NOT NULL,
    "bytecodeFileUuid" uuid,
    "diagnosticsJson" text NOT NULL,
    "exportsJson" text NOT NULL,
    "apiVersion" bigint NOT NULL DEFAULT 1,
    "compilerVersion" text NOT NULL DEFAULT ''::text,
    "requestedBy" uuid,
    "lastGoodSourceHash" text,
    "lastGoodBytecodeFileUuid" uuid,
    "lastGoodExportsJson" text,
    "lastGoodBuiltAt" timestamp without time zone,
    "positionsFileUuid" uuid,
    "builtAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "script_build_file_idx" ON "script_build" USING btree ("fileId", "id");

--
-- Class ScriptExecution as table script_execution
--
CREATE TABLE "script_execution" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "projectId" uuid,
    "functionName" text NOT NULL,
    "kind" text NOT NULL,
    "triggerId" uuid,
    "userId" bigint NOT NULL,
    "runAsUserId" bigint NOT NULL,
    "runtime" text NOT NULL,
    "status" text NOT NULL,
    "buildSourceHash" text NOT NULL,
    "startedAt" timestamp without time zone NOT NULL,
    "durationMs" bigint NOT NULL,
    "logs" text NOT NULL,
    "errorMessage" text,
    "errorStackJson" text,
    "changeId" uuid,
    "cellsRead" bigint NOT NULL,
    "cellsWritten" bigint NOT NULL,
    "fetchCalls" bigint NOT NULL,
    "callCount" bigint NOT NULL DEFAULT 1
);

-- Indexes
CREATE UNIQUE INDEX "script_exec_uuid_idx" ON "script_execution" USING btree ("uuid");
CREATE INDEX "script_exec_sheet_idx" ON "script_execution" USING btree ("spreadsheetUuid", "startedAt");
CREATE INDEX "script_exec_user_idx" ON "script_execution" USING btree ("userId", "startedAt");

--
-- Class ScriptFile as table script_file
--
CREATE TABLE "script_file" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "projectId" uuid NOT NULL,
    "name" text NOT NULL,
    "sortKey" text NOT NULL,
    "source" text NOT NULL,
    "contentHash" text NOT NULL,
    "updatedBy" uuid NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "script_file_file_idx" ON "script_file" USING btree ("fileId", "id");

--
-- Class ScriptJob as table script_job
--
CREATE TABLE "script_job" (
    "id" bigserial PRIMARY KEY,
    "kind" text NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "itemUuid" uuid NOT NULL,
    "triggerId" uuid,
    "runAsUserId" bigint NOT NULL,
    "functionName" text NOT NULL,
    "payloadJson" text NOT NULL,
    "status" text NOT NULL,
    "enqueuedAt" timestamp without time zone NOT NULL,
    "leaseOwner" text,
    "leaseUntil" timestamp without time zone,
    "attempts" bigint NOT NULL DEFAULT 0,
    "coalesced" bigint NOT NULL DEFAULT 0,
    "resultJson" text,
    "finishedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "script_job_status_idx" ON "script_job" USING btree ("status", "enqueuedAt");
CREATE INDEX "script_job_trigger_idx" ON "script_job" USING btree ("triggerId", "status");
CREATE INDEX "script_job_user_idx" ON "script_job" USING btree ("runAsUserId", "status");

--
-- Class ScriptProject as table script_project
--
CREATE TABLE "script_project" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "spreadsheetId" uuid NOT NULL,
    "name" text NOT NULL,
    "settingsJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "script_project_file_idx" ON "script_project" USING btree ("fileId", "id");

--
-- Class ScriptProperty as table script_property
--
CREATE TABLE "script_property" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "projectId" uuid NOT NULL,
    "key" text NOT NULL,
    "value" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "script_property_file_idx" ON "script_property" USING btree ("fileId", "id");

--
-- Class ScriptQuotaUsage as table script_quota_usage
--
CREATE TABLE "script_quota_usage" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "day" timestamp without time zone NOT NULL,
    "serverRuntimeMs" bigint NOT NULL DEFAULT 0,
    "clientRuntimeMs" bigint NOT NULL DEFAULT 0,
    "urlFetchCalls" bigint NOT NULL DEFAULT 0,
    "urlFetchBytes" bigint NOT NULL DEFAULT 0,
    "triggerRuns" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "script_quota_user_day_idx" ON "script_quota_usage" USING btree ("userId", "day");

--
-- Class ScriptTrigger as table script_trigger
--
CREATE TABLE "script_trigger" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "projectId" uuid NOT NULL,
    "kind" text NOT NULL,
    "functionName" text NOT NULL,
    "scheduleJson" text,
    "runAsUserId" uuid NOT NULL,
    "enabled" boolean NOT NULL DEFAULT true,
    "optionsJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "script_trigger_file_idx" ON "script_trigger" USING btree ("fileId", "id");

--
-- Class ScriptTriggerState as table script_trigger_state
--
CREATE TABLE "script_trigger_state" (
    "id" bigserial PRIMARY KEY,
    "triggerId" uuid NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "scheduleJson" text,
    "nextRunAt" timestamp without time zone,
    "lastRunAt" timestamp without time zone,
    "lastStatus" text,
    "consecutiveFailures" bigint NOT NULL DEFAULT 0,
    "disabledReason" text,
    "runningSince" timestamp without time zone,
    "lastNotifiedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "script_trigger_state_id_idx" ON "script_trigger_state" USING btree ("triggerId");
CREATE INDEX "script_trigger_state_due_idx" ON "script_trigger_state" USING btree ("nextRunAt");

--
-- Class ScriptUserProperty as table script_user_property
--
CREATE TABLE "script_user_property" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "fileUuid" uuid NOT NULL,
    "key" text NOT NULL,
    "value" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "script_user_property_idx" ON "script_user_property" USING btree ("userId", "fileUuid", "key");

--
-- Class ServerChangeRecord as table server_change_record
--
CREATE TABLE "server_change_record" (
    "id" bigserial PRIMARY KEY,
    "changeId" uuid NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "userId" bigint NOT NULL,
    "actorKind" text NOT NULL,
    "label" text NOT NULL,
    "inverseJson" text,
    "inverseFileId" uuid,
    "forwardFileId" uuid,
    "recordId" uuid,
    "cellsAffected" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "revertedAt" timestamp without time zone,
    "revertChangeId" uuid
);

-- Indexes
CREATE INDEX "server_change_record_idx" ON "server_change_record" USING btree ("recordId");
CREATE INDEX "server_change_sheet_idx" ON "server_change_record" USING btree ("spreadsheetUuid", "createdAt");
CREATE UNIQUE INDEX "server_change_id_idx" ON "server_change_record" USING btree ("changeId");

--
-- Class ShareLink as table share_link
--
CREATE TABLE "share_link" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "token" text NOT NULL,
    "role" text,
    "createdById" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "share_link_item_idx" ON "share_link" USING btree ("itemId");
CREATE UNIQUE INDEX "share_link_token_idx" ON "share_link" USING btree ("token");

--
-- Class Sheet as table sheet
--
CREATE TABLE "sheet" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "spreadsheetId" uuid NOT NULL,
    "name" text NOT NULL,
    "sortKey" text NOT NULL,
    "kind" text NOT NULL DEFAULT 'grid'::text,
    "hidden" boolean NOT NULL DEFAULT false,
    "tabColor" text,
    "rightToLeft" boolean NOT NULL DEFAULT false,
    "showGridlines" boolean NOT NULL DEFAULT true,
    "frozenRows" bigint NOT NULL DEFAULT 0,
    "frozenColumns" bigint NOT NULL DEFAULT 0,
    "defaultRowHeight" double precision NOT NULL DEFAULT 21.0,
    "defaultColumnWidth" double precision NOT NULL DEFAULT 100.0,
    "formatJson" text,
    "printSettingsJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "sheet_file_idx" ON "sheet" USING btree ("fileId", "id");
CREATE INDEX "sheet_order_idx" ON "sheet" USING btree ("spreadsheetId", "sortKey");

--
-- Class SheetColumn as table sheet_column
--
CREATE TABLE "sheet_column" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "sortKey" text NOT NULL,
    "width" double precision,
    "hidden" boolean NOT NULL DEFAULT false,
    "formatJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "sheet_column_file_idx" ON "sheet_column" USING btree ("fileId", "id");
CREATE INDEX "sheet_column_order_idx" ON "sheet_column" USING btree ("sheetId", "sortKey");

--
-- Class SheetRow as table sheet_row
--
CREATE TABLE "sheet_row" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "sheetId" uuid NOT NULL,
    "sortKey" text NOT NULL,
    "height" double precision,
    "hidden" boolean NOT NULL DEFAULT false,
    "formatJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "sheet_row_file_idx" ON "sheet_row" USING btree ("fileId", "id");
CREATE INDEX "sheet_row_order_idx" ON "sheet_row" USING btree ("sheetId", "sortKey");

--
-- Class SheetsAiPreviewRecord as table sheets_ai_preview_record
--
CREATE TABLE "sheets_ai_preview_record" (
    "id" bigserial PRIMARY KEY,
    "previewId" text NOT NULL,
    "userId" bigint NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "previewJson" text NOT NULL,
    "changesJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "sheets_ai_preview_id_idx" ON "sheets_ai_preview_record" USING btree ("previewId");
CREATE INDEX "sheets_ai_preview_expires_idx" ON "sheets_ai_preview_record" USING btree ("expiresAt");

--
-- Class SheetsImportJob as table sheets_import_job
--
CREATE TABLE "sheets_import_job" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "userId" bigint NOT NULL,
    "authUserId" uuid NOT NULL,
    "spreadsheetUuid" uuid NOT NULL,
    "uploadFileId" uuid NOT NULL,
    "fileName" text NOT NULL,
    "format" text NOT NULL,
    "optionsJson" text NOT NULL,
    "activeSheetId" text,
    "status" text NOT NULL,
    "progressDone" bigint NOT NULL,
    "progressTotal" bigint NOT NULL,
    "reportJson" text,
    "sheetIdsJson" text,
    "changeId" uuid,
    "errorCode" text,
    "error" text,
    "cancelRequested" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "leaseOwner" text,
    "leaseUntil" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "sheets_import_job_uuid_idx" ON "sheets_import_job" USING btree ("uuid");
CREATE INDEX "sheets_import_job_user_idx" ON "sheets_import_job" USING btree ("userId", "status");

--
-- Class SheetsSnapshotIndex as table sheets_snapshot_index
--
CREATE TABLE "sheets_snapshot_index" (
    "id" bigserial PRIMARY KEY,
    "itemVersionId" bigint NOT NULL,
    "sheetsJson" text NOT NULL,
    "changedRangesJson" text NOT NULL,
    "authorIds" json NOT NULL,
    "diffFileId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "sheets_snapshot_index_version_idx" ON "sheets_snapshot_index" USING btree ("itemVersionId");

--
-- Class Slide as table slide
--
CREATE TABLE "slide" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "deckId" uuid NOT NULL,
    "sortKey" text NOT NULL,
    "groupId" uuid,
    "layoutId" uuid,
    "backgroundJson" text,
    "skipped" boolean NOT NULL DEFAULT false,
    "notes" text,
    "transitionJson" text,
    "hideMasterElements" boolean,
    "timingsJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_file_idx" ON "slide" USING btree ("fileId", "id");
CREATE INDEX "slide_order_idx" ON "slide" USING btree ("deckId", "sortKey");

--
-- Class SlideBuild as table slide_build
--
CREATE TABLE "slide_build" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "slideId" uuid NOT NULL,
    "elementId" uuid NOT NULL,
    "kind" text NOT NULL,
    "effect" text NOT NULL,
    "sortKey" text NOT NULL,
    "trigger" text NOT NULL,
    "delayMs" bigint NOT NULL DEFAULT 0,
    "durationMs" bigint NOT NULL,
    "easing" text NOT NULL,
    "optionsJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_build_file_idx" ON "slide_build" USING btree ("fileId", "id");
CREATE INDEX "slide_build_slide_idx" ON "slide_build" USING btree ("slideId", "sortKey");
CREATE INDEX "slide_build_element_idx" ON "slide_build" USING btree ("elementId");

--
-- Class SlideElement as table slide_element
--
CREATE TABLE "slide_element" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "slideId" uuid,
    "layoutId" uuid,
    "masterId" uuid,
    "parentId" uuid,
    "kind" text NOT NULL,
    "name" text,
    "x" double precision,
    "y" double precision,
    "width" double precision,
    "height" double precision,
    "rotation" double precision,
    "flipH" boolean NOT NULL DEFAULT false,
    "flipV" boolean NOT NULL DEFAULT false,
    "zKey" text NOT NULL,
    "readingKey" text,
    "locked" boolean NOT NULL DEFAULT false,
    "hidden" boolean NOT NULL DEFAULT false,
    "placeholderType" text,
    "placeholderOf" uuid,
    "matchKey" text NOT NULL,
    "text" text,
    "textStyleJson" text,
    "fillJson" text,
    "strokeJson" text,
    "effectsJson" text,
    "opacity" double precision,
    "dataJson" text,
    "linkJson" text,
    "altText" text,
    "decorative" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_element_file_idx" ON "slide_element" USING btree ("fileId", "id");
CREATE INDEX "slide_element_slide_idx" ON "slide_element" USING btree ("slideId", "zKey");
CREATE INDEX "slide_element_layout_idx" ON "slide_element" USING btree ("layoutId");
CREATE INDEX "slide_element_master_idx" ON "slide_element" USING btree ("masterId");
CREATE INDEX "slide_element_parent_idx" ON "slide_element" USING btree ("parentId");

--
-- Class SlideGroup as table slide_group
--
CREATE TABLE "slide_group" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "deckId" uuid NOT NULL,
    "title" text NOT NULL,
    "sortKey" text NOT NULL,
    "parentId" uuid,
    "color" text,
    "skipped" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_group_file_idx" ON "slide_group" USING btree ("fileId", "id");
CREATE INDEX "slide_group_order_idx" ON "slide_group" USING btree ("deckId", "sortKey");

--
-- Class SlideLayout as table slide_layout
--
CREATE TABLE "slide_layout" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "masterId" uuid NOT NULL,
    "name" text NOT NULL,
    "key" text,
    "sortKey" text NOT NULL,
    "backgroundJson" text,
    "hideMasterElements" boolean NOT NULL DEFAULT false,
    "hidden" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_layout_file_idx" ON "slide_layout" USING btree ("fileId", "id");
CREATE INDEX "slide_layout_master_idx" ON "slide_layout" USING btree ("masterId");

--
-- Class SlideMaster as table slide_master
--
CREATE TABLE "slide_master" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "themeId" uuid NOT NULL,
    "name" text NOT NULL,
    "sortKey" text NOT NULL,
    "backgroundJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_master_file_idx" ON "slide_master" USING btree ("fileId", "id");
CREATE INDEX "slide_master_theme_idx" ON "slide_master" USING btree ("themeId");

--
-- Class SlideTableAxis as table slide_table_axis
--
CREATE TABLE "slide_table_axis" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "elementId" uuid NOT NULL,
    "dimension" text NOT NULL,
    "sortKey" text NOT NULL,
    "size" double precision,
    "header" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_table_axis_file_idx" ON "slide_table_axis" USING btree ("fileId", "id");
CREATE INDEX "slide_table_axis_element_idx" ON "slide_table_axis" USING btree ("elementId", "sortKey");

--
-- Class SlideTableCell as table slide_table_cell
--
CREATE TABLE "slide_table_cell" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "elementId" uuid NOT NULL,
    "rowId" uuid NOT NULL,
    "columnId" uuid NOT NULL,
    "text" text,
    "fill" text,
    "borderTop" text,
    "borderRight" text,
    "borderBottom" text,
    "borderLeft" text,
    "vAlign" text,
    "padding" text,
    "rowSpan" bigint,
    "colSpan" bigint,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "slide_table_cell_file_idx" ON "slide_table_cell" USING btree ("fileId", "id");
CREATE INDEX "slide_table_cell_element_idx" ON "slide_table_cell" USING btree ("elementId");

--
-- Class SlidesSnapshotIndex as table slides_snapshot_index
--
CREATE TABLE "slides_snapshot_index" (
    "id" bigserial PRIMARY KEY,
    "itemVersionId" bigint NOT NULL,
    "slidesJson" text NOT NULL,
    "changesJson" text NOT NULL,
    "authorIds" json NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "slides_snapshot_index_version_idx" ON "slides_snapshot_index" USING btree ("itemVersionId");

--
-- Class Spreadsheet as table spreadsheet
--
CREATE TABLE "spreadsheet" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "fileId" bigint NOT NULL,
    "revision" bigint NOT NULL DEFAULT 0,
    "title" text NOT NULL,
    "locale" text NOT NULL,
    "timeZone" text NOT NULL,
    "recalcMode" text NOT NULL DEFAULT 'onChange'::text,
    "iterativeCalc" boolean NOT NULL DEFAULT false,
    "maxIterations" bigint NOT NULL DEFAULT 50,
    "convergenceThreshold" double precision NOT NULL DEFAULT 0.05,
    "defaultFontFamily" text NOT NULL DEFAULT 'Inter'::text,
    "defaultFontSize" double precision NOT NULL DEFAULT 10.0,
    "themeJson" text NOT NULL,
    "displayLanguage" text,
    "createdBy" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "spreadsheet_file_idx" ON "spreadsheet" USING btree ("fileId", "id");

--
-- Class StorageReservation as table storage_reservation
--
CREATE TABLE "storage_reservation" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "fileUuid" uuid NOT NULL,
    "itemId" bigint,
    "bytes" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "storage_reservation_file_idx" ON "storage_reservation" USING btree ("fileUuid");
CREATE INDEX "storage_reservation_user_idx" ON "storage_reservation" USING btree ("userId");
CREATE INDEX "storage_reservation_expiry_idx" ON "storage_reservation" USING btree ("expiresAt");

--
-- Class StoredFile as table stored_file
--
CREATE TABLE "stored_file" (
    "id" bigserial PRIMARY KEY,
    "fileUuid" uuid NOT NULL,
    "ownerId" bigint,
    "itemId" bigint,
    "kind" text NOT NULL,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "fileName" text NOT NULL,
    "mimeType" text NOT NULL,
    "sizeBytes" bigint NOT NULL,
    "status" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "expiresAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "stored_file_uuid_idx" ON "stored_file" USING btree ("fileUuid");
CREATE INDEX "stored_file_item_idx" ON "stored_file" USING btree ("itemId");
CREATE INDEX "stored_file_expiry_idx" ON "stored_file" USING btree ("expiresAt");
CREATE INDEX "stored_file_owner_kind_idx" ON "stored_file" USING btree ("ownerId", "kind", "createdAt");
CREATE INDEX "stored_file_status_idx" ON "stored_file" USING btree ("status", "createdAt");

--
-- Class UserActivitySettings as table user_activity_settings
--
CREATE TABLE "user_activity_settings" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "showViewHistory" boolean NOT NULL DEFAULT true,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_activity_settings_user_idx" ON "user_activity_settings" USING btree ("userId");

--
-- Class UserPreferences as table user_preferences
--
CREATE TABLE "user_preferences" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "appTheme" text NOT NULL DEFAULT 'system'::text,
    "accentColor" text,
    "density" text NOT NULL DEFAULT 'comfortable'::text,
    "reduceMotion" boolean NOT NULL DEFAULT false,
    "keymapOverrides" text NOT NULL DEFAULT '{}'::text,
    "writeDefaults" text NOT NULL DEFAULT '{}'::text,
    "sheetsDefaults" text NOT NULL DEFAULT '{}'::text,
    "slidesDefaults" text NOT NULL DEFAULT '{}'::text,
    "slidesPresenter" text NOT NULL DEFAULT '{}'::text,
    "driveDefaults" text NOT NULL DEFAULT '{}'::text,
    "notificationSettings" text NOT NULL DEFAULT '{}'::text,
    "aiEnabled" boolean NOT NULL DEFAULT true,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_preferences_user_idx" ON "user_preferences" USING btree ("userId");

--
-- Class UserProfile as table user_profile
--
CREATE TABLE "user_profile" (
    "id" bigserial PRIMARY KEY,
    "authUserId" uuid NOT NULL,
    "displayName" text NOT NULL,
    "email" text NOT NULL,
    "avatarFileId" uuid,
    "avatarColor" text NOT NULL,
    "locale" text,
    "timeZone" text,
    "createdAt" timestamp without time zone NOT NULL,
    "lastSeenAt" timestamp without time zone,
    "welcomeContentAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_profile_auth_idx" ON "user_profile" USING btree ("authUserId");
CREATE UNIQUE INDEX "user_profile_email_idx" ON "user_profile" USING btree ("email");

--
-- Class UserStorage as table user_storage
--
CREATE TABLE "user_storage" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "usedBytes" bigint NOT NULL DEFAULT 0,
    "reservedBytes" bigint NOT NULL DEFAULT 0,
    "documentsBytes" bigint NOT NULL DEFAULT 0,
    "spreadsheetsBytes" bigint NOT NULL DEFAULT 0,
    "presentationsBytes" bigint NOT NULL DEFAULT 0,
    "filesBytes" bigint NOT NULL DEFAULT 0,
    "trashBytes" bigint NOT NULL DEFAULT 0,
    "quotaBytesOverride" bigint,
    "overQuotaSince" timestamp without time zone,
    "reconciledAt" timestamp without time zone,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_storage_user_idx" ON "user_storage" USING btree ("userId");

--
-- Class WriteDiffCache as table write_diff_cache
--
CREATE TABLE "write_diff_cache" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "fromRevision" bigint NOT NULL,
    "toRevision" bigint NOT NULL,
    "json" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "write_diff_cache_idx" ON "write_diff_cache" USING btree ("documentId", "fromRevision", "toRevision");
CREATE INDEX "write_diff_cache_created_idx" ON "write_diff_cache" USING brin ("createdAt");

--
-- Class WriteTheme as table write_theme
--
CREATE TABLE "write_theme" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "ownerId" bigint,
    "isBuiltin" boolean NOT NULL,
    "builtinKey" text,
    "name" text NOT NULL,
    "description" text,
    "schemaVersion" bigint NOT NULL,
    "version" bigint NOT NULL,
    "json" text NOT NULL,
    "contentHash" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "write_theme_uuid_idx" ON "write_theme" USING btree ("uuid");
CREATE INDEX "write_theme_owner_idx" ON "write_theme" USING btree ("ownerId", "deletedAt");
CREATE UNIQUE INDEX "write_theme_builtin_idx" ON "write_theme" USING btree ("builtinKey");

--
-- Class WriteThemeRevision as table write_theme_revision
--
CREATE TABLE "write_theme_revision" (
    "id" bigserial PRIMARY KEY,
    "themeId" bigint NOT NULL,
    "version" bigint NOT NULL,
    "json" text NOT NULL,
    "savedById" bigint,
    "actorKind" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "write_theme_rev_idx" ON "write_theme_revision" USING btree ("themeId", "version");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectDownloadEntry as table serverpod_cloud_storage_direct_download
--
CREATE TABLE "serverpod_cloud_storage_direct_download" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "downloadFileName" text,
    "contentType" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_download_auth_key" ON "serverpod_cloud_storage_direct_download" USING btree ("authKey");
CREATE INDEX "serverpod_cloud_storage_direct_download_expiration" ON "serverpod_cloud_storage_direct_download" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "maxFileSize" bigint NOT NULL DEFAULT 10485760,
    "contentLength" bigint,
    "preventOverwrite" boolean NOT NULL DEFAULT false,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text,
    "scheduling" json
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class FutureCallClaimEntry as table serverpod_future_call_claim
--
CREATE TABLE "serverpod_future_call_claim" (
    "id" bigserial PRIMARY KEY,
    "futureCallId" bigint,
    "lastHeartbeatTime" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "future_call_unique_idx" ON "serverpod_future_call_claim" USING btree ("futureCallId");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId", "order");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_message_log_sessionLogId_idx" ON "serverpod_message_log" USING btree ("sessionLogId", "order");

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId", "order");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Class AnonymousAccount as table serverpod_auth_idp_anonymous_account
--
CREATE TABLE "serverpod_auth_idp_anonymous_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- Class AppleAccount as table serverpod_auth_idp_apple_account
--
CREATE TABLE "serverpod_auth_idp_apple_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userIdentifier" text NOT NULL,
    "refreshToken" text NOT NULL,
    "refreshTokenRequestedWithBundleIdentifier" boolean NOT NULL,
    "lastRefreshedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text,
    "isEmailVerified" boolean,
    "isPrivateEmail" boolean,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_apple_account_identifier" ON "serverpod_auth_idp_apple_account" USING btree ("userIdentifier");

--
-- Class EmailAccount as table serverpod_auth_idp_email_account
--
CREATE TABLE "serverpod_auth_idp_email_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_email" ON "serverpod_auth_idp_email_account" USING btree ("email");

--
-- Class EmailAccountPasswordResetRequest as table serverpod_auth_idp_email_account_password_reset_request
--
CREATE TABLE "serverpod_auth_idp_email_account_password_reset_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "emailAccountId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "challengeId" uuid NOT NULL,
    "setPasswordChallengeId" uuid
);

--
-- Class EmailAccountRequest as table serverpod_auth_idp_email_account_request
--
CREATE TABLE "serverpod_auth_idp_email_account_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" text NOT NULL,
    "challengeId" uuid NOT NULL,
    "createAccountChallengeId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_request_email" ON "serverpod_auth_idp_email_account_request" USING btree ("email");

--
-- Class FacebookAccount as table serverpod_auth_idp_facebook_account
--
CREATE TABLE "serverpod_auth_idp_facebook_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "fullName" text,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_facebook_account_user_identifier" ON "serverpod_auth_idp_facebook_account" USING btree ("userIdentifier");

--
-- Class FirebaseAccount as table serverpod_auth_idp_firebase_account
--
CREATE TABLE "serverpod_auth_idp_firebase_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text,
    "phone" text,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_firebase_account_user_identifier" ON "serverpod_auth_idp_firebase_account" USING btree ("userIdentifier");

--
-- Class GitHubAccount as table serverpod_auth_idp_github_account
--
CREATE TABLE "serverpod_auth_idp_github_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_github_account_user_identifier" ON "serverpod_auth_idp_github_account" USING btree ("userIdentifier");

--
-- Class GoogleAccount as table serverpod_auth_idp_google_account
--
CREATE TABLE "serverpod_auth_idp_google_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_google_account_user_identifier" ON "serverpod_auth_idp_google_account" USING btree ("userIdentifier");

--
-- Class MicrosoftAccount as table serverpod_auth_idp_microsoft_account
--
CREATE TABLE "serverpod_auth_idp_microsoft_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_microsoft_account_user_identifier" ON "serverpod_auth_idp_microsoft_account" USING btree ("userIdentifier");

--
-- Class PasskeyAccount as table serverpod_auth_idp_passkey_account
--
CREATE TABLE "serverpod_auth_idp_passkey_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "keyId" bytea NOT NULL,
    "keyIdBase64" text NOT NULL,
    "clientDataJSON" bytea NOT NULL,
    "attestationObject" bytea NOT NULL,
    "originalChallenge" bytea NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_passkey_account_key_id_base64" ON "serverpod_auth_idp_passkey_account" USING btree ("keyIdBase64");

--
-- Class PasskeyChallenge as table serverpod_auth_idp_passkey_challenge
--
CREATE TABLE "serverpod_auth_idp_passkey_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "challenge" bytea NOT NULL
);

--
-- Class RateLimitedRequestAttempt as table serverpod_auth_idp_rate_limited_request_attempt
--
CREATE TABLE "serverpod_auth_idp_rate_limited_request_attempt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "domain" text NOT NULL,
    "source" text NOT NULL,
    "key" text NOT NULL,
    "ipAddress" text,
    "attemptedAt" timestamp without time zone NOT NULL,
    "extraData" json
);

-- Indexes
CREATE INDEX "serverpod_auth_idp_rate_limited_request_attempt_composite" ON "serverpod_auth_idp_rate_limited_request_attempt" USING btree ("domain", "source", "key", "attemptedAt");

--
-- Class SecretChallenge as table serverpod_auth_idp_secret_challenge
--
CREATE TABLE "serverpod_auth_idp_secret_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "challengeCodeHash" text NOT NULL
);

--
-- Class RefreshToken as table serverpod_auth_core_jwt_refresh_token
--
CREATE TABLE "serverpod_auth_core_jwt_refresh_token" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "extraClaims" text,
    "method" text NOT NULL,
    "fixedSecret" bytea NOT NULL,
    "rotatingSecretHash" text NOT NULL,
    "lastUpdatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "serverpod_auth_core_jwt_refresh_token_last_updated_at" ON "serverpod_auth_core_jwt_refresh_token" USING btree ("lastUpdatedAt");

--
-- Class UserProfile as table serverpod_auth_core_profile
--
CREATE TABLE "serverpod_auth_core_profile" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userName" text,
    "fullName" text,
    "email" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "imageId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_profile_user_profile_email_auth_user_id" ON "serverpod_auth_core_profile" USING btree ("authUserId");

--
-- Class UserProfileImage as table serverpod_auth_core_profile_image
--
CREATE TABLE "serverpod_auth_core_profile_image" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userProfileId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "url" text NOT NULL
);

--
-- Class ServerSideSession as table serverpod_auth_core_session
--
CREATE TABLE "serverpod_auth_core_session" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" timestamp without time zone,
    "expireAfterUnusedFor" bigint,
    "sessionKeyHash" bytea NOT NULL,
    "sessionKeySalt" bytea NOT NULL,
    "method" text NOT NULL
);

--
-- Class AuthUser as table serverpod_auth_core_user
--
CREATE TABLE "serverpod_auth_core_user" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "scopeNames" json NOT NULL,
    "blocked" boolean NOT NULL
);

--
-- Foreign relations for "access_request" table
--
ALTER TABLE ONLY "access_request"
    ADD CONSTRAINT "access_request_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "access_request"
    ADD CONSTRAINT "access_request_fk_1"
    FOREIGN KEY("requesterId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "activity_event" table
--
ALTER TABLE ONLY "activity_event"
    ADD CONSTRAINT "activity_event_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "ai_usage" table
--
ALTER TABLE ONLY "ai_usage"
    ADD CONSTRAINT "ai_usage_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "ai_user_key" table
--
ALTER TABLE ONLY "ai_user_key"
    ADD CONSTRAINT "ai_user_key_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "ai_user_setting" table
--
ALTER TABLE ONLY "ai_user_setting"
    ADD CONSTRAINT "ai_user_setting_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "assistant_message" table
--
ALTER TABLE ONLY "assistant_message"
    ADD CONSTRAINT "assistant_message_fk_0"
    FOREIGN KEY("threadId")
    REFERENCES "assistant_thread"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "assistant_thread" table
--
ALTER TABLE ONLY "assistant_thread"
    ADD CONSTRAINT "assistant_thread_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "assistant_thread"
    ADD CONSTRAINT "assistant_thread_fk_1"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "banding" table
--
ALTER TABLE ONLY "banding"
    ADD CONSTRAINT "banding_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "banding"
    ADD CONSTRAINT "banding_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "basic_filter" table
--
ALTER TABLE ONLY "basic_filter"
    ADD CONSTRAINT "basic_filter_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "basic_filter"
    ADD CONSTRAINT "basic_filter_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "board_comment" table
--
ALTER TABLE ONLY "board_comment"
    ADD CONSTRAINT "board_comment_fk_0"
    FOREIGN KEY("postId")
    REFERENCES "board_post"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "board_comment"
    ADD CONSTRAINT "board_comment_fk_1"
    FOREIGN KEY("taskId")
    REFERENCES "board_task"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "board_comment"
    ADD CONSTRAINT "board_comment_fk_2"
    FOREIGN KEY("authorId")
    REFERENCES "user_profile"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "board_flag" table
--
ALTER TABLE ONLY "board_flag"
    ADD CONSTRAINT "board_flag_fk_0"
    FOREIGN KEY("postId")
    REFERENCES "board_post"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "board_flag"
    ADD CONSTRAINT "board_flag_fk_1"
    FOREIGN KEY("commentId")
    REFERENCES "board_comment"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "board_flag"
    ADD CONSTRAINT "board_flag_fk_2"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "board_post" table
--
ALTER TABLE ONLY "board_post"
    ADD CONSTRAINT "board_post_fk_0"
    FOREIGN KEY("authorId")
    REFERENCES "user_profile"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "board_post"
    ADD CONSTRAINT "board_post_fk_1"
    FOREIGN KEY("screenshotFileId")
    REFERENCES "stored_file"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "board_post"
    ADD CONSTRAINT "board_post_fk_2"
    FOREIGN KEY("taskId")
    REFERENCES "board_task"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "board_pull_request" table
--
ALTER TABLE ONLY "board_pull_request"
    ADD CONSTRAINT "board_pull_request_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "board_task"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "board_task" table
--
ALTER TABLE ONLY "board_task"
    ADD CONSTRAINT "board_task_fk_0"
    FOREIGN KEY("claimedById")
    REFERENCES "user_profile"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "board_user_profile" table
--
ALTER TABLE ONLY "board_user_profile"
    ADD CONSTRAINT "board_user_profile_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "board_vote" table
--
ALTER TABLE ONLY "board_vote"
    ADD CONSTRAINT "board_vote_fk_0"
    FOREIGN KEY("postId")
    REFERENCES "board_post"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "board_vote"
    ADD CONSTRAINT "board_vote_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "cell" table
--
ALTER TABLE ONLY "cell"
    ADD CONSTRAINT "cell_fk_0"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "chart_link" table
--
ALTER TABLE ONLY "chart_link"
    ADD CONSTRAINT "chart_link_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "chart_link"
    ADD CONSTRAINT "chart_link_fk_1"
    FOREIGN KEY("elementId")
    REFERENCES "slide_element"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "code_state" table
--
ALTER TABLE ONLY "code_state"
    ADD CONSTRAINT "code_state_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "code_state"
    ADD CONSTRAINT "code_state_fk_1"
    FOREIGN KEY("elementId")
    REFERENCES "slide_element"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "comment" table
--
ALTER TABLE ONLY "comment"
    ADD CONSTRAINT "comment_fk_0"
    FOREIGN KEY("threadId")
    REFERENCES "comment_thread"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "comment_thread" table
--
ALTER TABLE ONLY "comment_thread"
    ADD CONSTRAINT "comment_thread_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "conditional_format_rule" table
--
ALTER TABLE ONLY "conditional_format_rule"
    ADD CONSTRAINT "conditional_format_rule_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conditional_format_rule"
    ADD CONSTRAINT "conditional_format_rule_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "data_validation_rule" table
--
ALTER TABLE ONLY "data_validation_rule"
    ADD CONSTRAINT "data_validation_rule_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "data_validation_rule"
    ADD CONSTRAINT "data_validation_rule_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "deck" table
--
ALTER TABLE ONLY "deck"
    ADD CONSTRAINT "deck_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "deck_theme" table
--
ALTER TABLE ONLY "deck_theme"
    ADD CONSTRAINT "deck_theme_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "deck_theme"
    ADD CONSTRAINT "deck_theme_fk_1"
    FOREIGN KEY("deckId")
    REFERENCES "deck"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "dimension_group" table
--
ALTER TABLE ONLY "dimension_group"
    ADD CONSTRAINT "dimension_group_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "dimension_group"
    ADD CONSTRAINT "dimension_group_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "document" table
--
ALTER TABLE ONLY "document"
    ADD CONSTRAINT "document_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "document_import_report" table
--
ALTER TABLE ONLY "document_import_report"
    ADD CONSTRAINT "document_import_report_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "document_meta_change" table
--
ALTER TABLE ONLY "document_meta_change"
    ADD CONSTRAINT "document_meta_change_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "document_op" table
--
ALTER TABLE ONLY "document_op"
    ADD CONSTRAINT "document_op_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "document_snapshot" table
--
ALTER TABLE ONLY "document_snapshot"
    ADD CONSTRAINT "document_snapshot_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "drive_item" table
--
ALTER TABLE ONLY "drive_item"
    ADD CONSTRAINT "drive_item_fk_0"
    FOREIGN KEY("ownerId")
    REFERENCES "user_profile"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "drive_item"
    ADD CONSTRAINT "drive_item_fk_1"
    FOREIGN KEY("parentId")
    REFERENCES "drive_item"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "drive_item_permission" table
--
ALTER TABLE ONLY "drive_item_permission"
    ADD CONSTRAINT "drive_item_permission_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "drive_item_permission"
    ADD CONSTRAINT "drive_item_permission_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "drive_item_user_state" table
--
ALTER TABLE ONLY "drive_item_user_state"
    ADD CONSTRAINT "drive_item_user_state_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "drive_item_user_state"
    ADD CONSTRAINT "drive_item_user_state_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "embedded_object" table
--
ALTER TABLE ONLY "embedded_object"
    ADD CONSTRAINT "embedded_object_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "embedded_object"
    ADD CONSTRAINT "embedded_object_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "filter_view" table
--
ALTER TABLE ONLY "filter_view"
    ADD CONSTRAINT "filter_view_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "filter_view"
    ADD CONSTRAINT "filter_view_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "headless_change" table
--
ALTER TABLE ONLY "headless_change"
    ADD CONSTRAINT "headless_change_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "item_version" table
--
ALTER TABLE ONLY "item_version"
    ADD CONSTRAINT "item_version_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "item_version_state" table
--
ALTER TABLE ONLY "item_version_state"
    ADD CONSTRAINT "item_version_state_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "item_view_day" table
--
ALTER TABLE ONLY "item_view_day"
    ADD CONSTRAINT "item_view_day_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "item_view_day"
    ADD CONSTRAINT "item_view_day_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "macro" table
--
ALTER TABLE ONLY "macro"
    ADD CONSTRAINT "macro_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "macro"
    ADD CONSTRAINT "macro_fk_1"
    FOREIGN KEY("projectId")
    REFERENCES "script_project"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "merged_range" table
--
ALTER TABLE ONLY "merged_range"
    ADD CONSTRAINT "merged_range_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "merged_range"
    ADD CONSTRAINT "merged_range_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "named_range" table
--
ALTER TABLE ONLY "named_range"
    ADD CONSTRAINT "named_range_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "named_range"
    ADD CONSTRAINT "named_range_fk_1"
    FOREIGN KEY("spreadsheetId")
    REFERENCES "spreadsheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "notification" table
--
ALTER TABLE ONLY "notification"
    ADD CONSTRAINT "notification_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "ownership_transfer" table
--
ALTER TABLE ONLY "ownership_transfer"
    ADD CONSTRAINT "ownership_transfer_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "ownership_transfer"
    ADD CONSTRAINT "ownership_transfer_fk_1"
    FOREIGN KEY("toUserId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "personal_access_token" table
--
ALTER TABLE ONLY "personal_access_token"
    ADD CONSTRAINT "personal_access_token_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "pivot_table" table
--
ALTER TABLE ONLY "pivot_table"
    ADD CONSTRAINT "pivot_table_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "pivot_table"
    ADD CONSTRAINT "pivot_table_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "protected_range" table
--
ALTER TABLE ONLY "protected_range"
    ADD CONSTRAINT "protected_range_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "protected_range"
    ADD CONSTRAINT "protected_range_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "rev_file" table
--
ALTER TABLE ONLY "rev_file"
    ADD CONSTRAINT "rev_file_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- Foreign relations for "rev_hook_state" table
--
ALTER TABLE ONLY "rev_hook_state"
    ADD CONSTRAINT "rev_hook_state_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "rev_op" table
--
ALTER TABLE ONLY "rev_op"
    ADD CONSTRAINT "rev_op_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "script_build" table
--
ALTER TABLE ONLY "script_build"
    ADD CONSTRAINT "script_build_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "script_build"
    ADD CONSTRAINT "script_build_fk_1"
    FOREIGN KEY("projectId")
    REFERENCES "script_project"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "script_file" table
--
ALTER TABLE ONLY "script_file"
    ADD CONSTRAINT "script_file_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "script_file"
    ADD CONSTRAINT "script_file_fk_1"
    FOREIGN KEY("projectId")
    REFERENCES "script_project"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "script_project" table
--
ALTER TABLE ONLY "script_project"
    ADD CONSTRAINT "script_project_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "script_project"
    ADD CONSTRAINT "script_project_fk_1"
    FOREIGN KEY("spreadsheetId")
    REFERENCES "spreadsheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "script_property" table
--
ALTER TABLE ONLY "script_property"
    ADD CONSTRAINT "script_property_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "script_property"
    ADD CONSTRAINT "script_property_fk_1"
    FOREIGN KEY("projectId")
    REFERENCES "script_project"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "script_trigger" table
--
ALTER TABLE ONLY "script_trigger"
    ADD CONSTRAINT "script_trigger_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "script_trigger"
    ADD CONSTRAINT "script_trigger_fk_1"
    FOREIGN KEY("projectId")
    REFERENCES "script_project"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "script_user_property" table
--
ALTER TABLE ONLY "script_user_property"
    ADD CONSTRAINT "script_user_property_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "share_link" table
--
ALTER TABLE ONLY "share_link"
    ADD CONSTRAINT "share_link_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sheet" table
--
ALTER TABLE ONLY "sheet"
    ADD CONSTRAINT "sheet_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sheet"
    ADD CONSTRAINT "sheet_fk_1"
    FOREIGN KEY("spreadsheetId")
    REFERENCES "spreadsheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "sheet_column" table
--
ALTER TABLE ONLY "sheet_column"
    ADD CONSTRAINT "sheet_column_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sheet_column"
    ADD CONSTRAINT "sheet_column_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "sheet_row" table
--
ALTER TABLE ONLY "sheet_row"
    ADD CONSTRAINT "sheet_row_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sheet_row"
    ADD CONSTRAINT "sheet_row_fk_1"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "sheets_snapshot_index" table
--
ALTER TABLE ONLY "sheets_snapshot_index"
    ADD CONSTRAINT "sheets_snapshot_index_fk_0"
    FOREIGN KEY("itemVersionId")
    REFERENCES "item_version"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "slide" table
--
ALTER TABLE ONLY "slide"
    ADD CONSTRAINT "slide_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide"
    ADD CONSTRAINT "slide_fk_1"
    FOREIGN KEY("deckId")
    REFERENCES "deck"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slide_build" table
--
ALTER TABLE ONLY "slide_build"
    ADD CONSTRAINT "slide_build_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide_build"
    ADD CONSTRAINT "slide_build_fk_1"
    FOREIGN KEY("slideId")
    REFERENCES "slide"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE ONLY "slide_build"
    ADD CONSTRAINT "slide_build_fk_2"
    FOREIGN KEY("elementId")
    REFERENCES "slide_element"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slide_element" table
--
ALTER TABLE ONLY "slide_element"
    ADD CONSTRAINT "slide_element_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide_element"
    ADD CONSTRAINT "slide_element_fk_1"
    FOREIGN KEY("slideId")
    REFERENCES "slide"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE ONLY "slide_element"
    ADD CONSTRAINT "slide_element_fk_2"
    FOREIGN KEY("layoutId")
    REFERENCES "slide_layout"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE ONLY "slide_element"
    ADD CONSTRAINT "slide_element_fk_3"
    FOREIGN KEY("masterId")
    REFERENCES "slide_master"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE ONLY "slide_element"
    ADD CONSTRAINT "slide_element_fk_4"
    FOREIGN KEY("parentId")
    REFERENCES "slide_element"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slide_group" table
--
ALTER TABLE ONLY "slide_group"
    ADD CONSTRAINT "slide_group_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide_group"
    ADD CONSTRAINT "slide_group_fk_1"
    FOREIGN KEY("deckId")
    REFERENCES "deck"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slide_layout" table
--
ALTER TABLE ONLY "slide_layout"
    ADD CONSTRAINT "slide_layout_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide_layout"
    ADD CONSTRAINT "slide_layout_fk_1"
    FOREIGN KEY("masterId")
    REFERENCES "slide_master"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slide_master" table
--
ALTER TABLE ONLY "slide_master"
    ADD CONSTRAINT "slide_master_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide_master"
    ADD CONSTRAINT "slide_master_fk_1"
    FOREIGN KEY("themeId")
    REFERENCES "deck_theme"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slide_table_axis" table
--
ALTER TABLE ONLY "slide_table_axis"
    ADD CONSTRAINT "slide_table_axis_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide_table_axis"
    ADD CONSTRAINT "slide_table_axis_fk_1"
    FOREIGN KEY("elementId")
    REFERENCES "slide_element"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slide_table_cell" table
--
ALTER TABLE ONLY "slide_table_cell"
    ADD CONSTRAINT "slide_table_cell_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "slide_table_cell"
    ADD CONSTRAINT "slide_table_cell_fk_1"
    FOREIGN KEY("elementId")
    REFERENCES "slide_element"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE ONLY "slide_table_cell"
    ADD CONSTRAINT "slide_table_cell_fk_2"
    FOREIGN KEY("rowId")
    REFERENCES "slide_table_axis"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE ONLY "slide_table_cell"
    ADD CONSTRAINT "slide_table_cell_fk_3"
    FOREIGN KEY("columnId")
    REFERENCES "slide_table_axis"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "slides_snapshot_index" table
--
ALTER TABLE ONLY "slides_snapshot_index"
    ADD CONSTRAINT "slides_snapshot_index_fk_0"
    FOREIGN KEY("itemVersionId")
    REFERENCES "item_version"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "spreadsheet" table
--
ALTER TABLE ONLY "spreadsheet"
    ADD CONSTRAINT "spreadsheet_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "storage_reservation" table
--
ALTER TABLE ONLY "storage_reservation"
    ADD CONSTRAINT "storage_reservation_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "storage_reservation"
    ADD CONSTRAINT "storage_reservation_fk_1"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "stored_file" table
--
ALTER TABLE ONLY "stored_file"
    ADD CONSTRAINT "stored_file_fk_0"
    FOREIGN KEY("ownerId")
    REFERENCES "user_profile"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "stored_file"
    ADD CONSTRAINT "stored_file_fk_1"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "user_activity_settings" table
--
ALTER TABLE ONLY "user_activity_settings"
    ADD CONSTRAINT "user_activity_settings_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "user_preferences" table
--
ALTER TABLE ONLY "user_preferences"
    ADD CONSTRAINT "user_preferences_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "user_profile" table
--
ALTER TABLE ONLY "user_profile"
    ADD CONSTRAINT "user_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "user_storage" table
--
ALTER TABLE ONLY "user_storage"
    ADD CONSTRAINT "user_storage_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "write_diff_cache" table
--
ALTER TABLE ONLY "write_diff_cache"
    ADD CONSTRAINT "write_diff_cache_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "write_theme" table
--
ALTER TABLE ONLY "write_theme"
    ADD CONSTRAINT "write_theme_fk_0"
    FOREIGN KEY("ownerId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "write_theme_revision" table
--
ALTER TABLE ONLY "write_theme_revision"
    ADD CONSTRAINT "write_theme_revision_fk_0"
    FOREIGN KEY("themeId")
    REFERENCES "write_theme"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_future_call_claim" table
--
ALTER TABLE ONLY "serverpod_future_call_claim"
    ADD CONSTRAINT "serverpod_future_call_claim_fk_0"
    FOREIGN KEY("futureCallId")
    REFERENCES "serverpod_future_call"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_anonymous_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_anonymous_account"
    ADD CONSTRAINT "serverpod_auth_idp_anonymous_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_apple_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_apple_account"
    ADD CONSTRAINT "serverpod_auth_idp_apple_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_password_reset_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_0"
    FOREIGN KEY("emailAccountId")
    REFERENCES "serverpod_auth_idp_email_account"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_1"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_2"
    FOREIGN KEY("setPasswordChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_0"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_1"
    FOREIGN KEY("createAccountChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_facebook_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_facebook_account"
    ADD CONSTRAINT "serverpod_auth_idp_facebook_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_firebase_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_firebase_account"
    ADD CONSTRAINT "serverpod_auth_idp_firebase_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_github_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_github_account"
    ADD CONSTRAINT "serverpod_auth_idp_github_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_google_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_google_account"
    ADD CONSTRAINT "serverpod_auth_idp_google_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_microsoft_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_microsoft_account"
    ADD CONSTRAINT "serverpod_auth_idp_microsoft_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_passkey_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_passkey_account"
    ADD CONSTRAINT "serverpod_auth_idp_passkey_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_jwt_refresh_token" table
--
ALTER TABLE ONLY "serverpod_auth_core_jwt_refresh_token"
    ADD CONSTRAINT "serverpod_auth_core_jwt_refresh_token_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_profile" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_1"
    FOREIGN KEY("imageId")
    REFERENCES "serverpod_auth_core_profile_image"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- Foreign relations for "serverpod_auth_core_profile_image" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile_image"
    ADD CONSTRAINT "serverpod_auth_core_profile_image_fk_0"
    FOREIGN KEY("userProfileId")
    REFERENCES "serverpod_auth_core_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_session" table
--
ALTER TABLE ONLY "serverpod_auth_core_session"
    ADD CONSTRAINT "serverpod_auth_core_session_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261018123013739-quality-wave1-server', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261018123013739-quality-wave1-server', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
