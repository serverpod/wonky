BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE INDEX "activity_type_at_idx" ON "activity_event" USING btree ("type", "at");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "ai_usage_at_idx" ON "ai_usage" USING btree ("at");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "comment_created_idx" ON "comment" USING btree ("createdAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "perm_granted_idx" ON "drive_item_permission" USING btree ("grantedAt");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "usage_day_stats" (
    "id" bigserial PRIMARY KEY,
    "day" timestamp without time zone NOT NULL,
    "includeAdmins" boolean NOT NULL,
    "active" bigint NOT NULL,
    "editors" bigint NOT NULL,
    "drive" bigint NOT NULL,
    "write" bigint NOT NULL,
    "sheets" bigint NOT NULL,
    "slides" bigint NOT NULL,
    "mcp" bigint NOT NULL,
    "weekly" bigint NOT NULL,
    "monthly" bigint NOT NULL,
    "computedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "usage_day_stats_idx" ON "usage_day_stats" USING btree ("day", "includeAdmins");

--
-- ACTION ALTER TABLE
--
CREATE INDEX "user_profile_created_idx" ON "user_profile" USING btree ("createdAt");

--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261020142413171-analytics-indexes', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261020142413171-analytics-indexes', "timestamp" = now();

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
