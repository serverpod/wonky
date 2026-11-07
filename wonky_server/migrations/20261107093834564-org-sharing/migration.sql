BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "perm_item_user_idx";
ALTER TABLE "drive_item_permission" ADD COLUMN "orgKey" text;
CREATE INDEX "perm_org_idx" ON "drive_item_permission" USING btree ("orgKey", "itemId");
CREATE UNIQUE INDEX "perm_item_user_idx" ON "drive_item_permission" USING btree ("itemId", "userId", "inheritedFromId", "invitedEmail", "orgKey") NULLS NOT DISTINCT;

--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261107093834564-org-sharing', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261107093834564-org-sharing', "timestamp" = now();

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
    VALUES ('serverpod_auth_idp', '20261015164015382', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261015164015382', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
