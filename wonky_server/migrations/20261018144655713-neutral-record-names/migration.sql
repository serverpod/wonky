BEGIN;

--
-- Hand-edited (AGENTS.md): renames instead of the generated drop and
-- create, so the rows survive. The resulting schema equals definition.sql.
--
ALTER TABLE "sheets_ai_preview_record" RENAME TO "ai_preview_record";
ALTER TABLE "ai_preview_record" RENAME COLUMN "spreadsheetUuid" TO "fileUuid";
ALTER SEQUENCE IF EXISTS "sheets_ai_preview_record_id_seq" RENAME TO "ai_preview_record_id_seq";
ALTER INDEX IF EXISTS "sheets_ai_preview_record_pkey" RENAME TO "ai_preview_record_pkey";
ALTER INDEX "sheets_ai_preview_id_idx" RENAME TO "ai_preview_id_idx";
ALTER INDEX "sheets_ai_preview_expires_idx" RENAME TO "ai_preview_expires_idx";

ALTER TABLE "server_change_record" RENAME COLUMN "spreadsheetUuid" TO "fileUuid";
ALTER INDEX "server_change_sheet_idx" RENAME TO "server_change_file_idx";


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261018144655713-neutral-record-names', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261018144655713-neutral-record-names', "timestamp" = now();

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
