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
-- ACTION DROP TABLE
--
DROP TABLE "change_log" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "banding" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "basic_filter" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "cell" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "cell_history" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "conditional_format_rule" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "data_validation_rule" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "dimension_group" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "embedded_object" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "filter_view" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "macro" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "merged_range" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "named_range" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "pivot_table" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "protected_range" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "script_build" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "script_file" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "script_project" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "script_property" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "script_trigger" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "script_user_property" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION ALTER TABLE
--
ALTER TABLE "server_change_record" ADD COLUMN "recordId" uuid;
CREATE INDEX "server_change_record_idx" ON "server_change_record" USING btree ("recordId");
--
-- ACTION DROP TABLE
--
DROP TABLE "sheet" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "sheet_column" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "sheet_row" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION DROP TABLE
--
DROP TABLE "spreadsheet" CASCADE;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "cell"
    ADD CONSTRAINT "cell_fk_0"
    FOREIGN KEY("sheetId")
    REFERENCES "sheet"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "script_user_property"
    ADD CONSTRAINT "script_user_property_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "spreadsheet"
    ADD CONSTRAINT "spreadsheet_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261018092420485-sheets-revlog', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261018092420485-sheets-revlog', "timestamp" = now();

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
-- MIGRATION VERSION FOR serverpod_offline_sync
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_offline_sync', '20260914143806119', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260914143806119', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
