BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ai_org_key" (
    "id" bigserial PRIMARY KEY,
    "orgKey" text NOT NULL,
    "provider" text NOT NULL,
    "apiKey" text NOT NULL,
    "addedById" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "ai_org_key_org_idx" ON "ai_org_key" USING btree ("orgKey");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "ai_org_key"
    ADD CONSTRAINT "ai_org_key_fk_0"
    FOREIGN KEY("addedById")
    REFERENCES "user_profile"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261107153926054-ai-org-key', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261107153926054-ai-org-key', "timestamp" = now();

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
