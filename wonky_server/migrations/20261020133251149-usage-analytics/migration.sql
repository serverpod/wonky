BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "usage_counter_day" (
    "id" bigserial PRIMARY KEY,
    "day" timestamp without time zone NOT NULL,
    "name" text NOT NULL,
    "value" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "usage_counter_day_idx" ON "usage_counter_day" USING btree ("day", "name");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_activity_day" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "day" timestamp without time zone NOT NULL,
    "app" text NOT NULL,
    "edited" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "user_activity_day_idx" ON "user_activity_day" USING btree ("userId", "day", "app");
CREATE INDEX "user_activity_day_day_idx" ON "user_activity_day" USING btree ("day");


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261020133251149-usage-analytics', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261020133251149-usage-analytics', "timestamp" = now();

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
