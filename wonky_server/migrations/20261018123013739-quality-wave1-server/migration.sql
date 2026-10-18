BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE INDEX "drive_item_trashed_idx" ON "drive_item" USING btree ("trashedAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "perm_expires_idx" ON "drive_item_permission" USING btree ("expiresAt");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "item_version_state" ADD COLUMN "capturingSince" timestamp without time zone;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "notification" ADD COLUMN "emailPending" boolean DEFAULT false;
CREATE INDEX "notification_email_idx" ON "notification" USING btree ("emailPending", "createdAt");
CREATE INDEX "notification_created_idx" ON "notification" USING brin ("createdAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "stored_file_owner_kind_idx" ON "stored_file" USING btree ("ownerId", "kind", "createdAt");
CREATE INDEX "stored_file_status_idx" ON "stored_file" USING btree ("status", "createdAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "write_diff_cache_created_idx" ON "write_diff_cache" USING brin ("createdAt");

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
