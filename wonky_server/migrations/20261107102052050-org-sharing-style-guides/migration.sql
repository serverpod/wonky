BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "document_style_guide" (
    "id" bigserial PRIMARY KEY,
    "itemId" bigint NOT NULL,
    "styleRef" text NOT NULL,
    "setById" bigint,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "document_style_guide_item_idx" ON "document_style_guide" USING btree ("itemId");

--
-- ACTION ALTER TABLE
--
DROP INDEX "perm_item_user_idx";
ALTER TABLE "drive_item_permission" ADD COLUMN "orgKey" text;
CREATE INDEX "perm_org_idx" ON "drive_item_permission" USING btree ("orgKey", "itemId");
CREATE UNIQUE INDEX "perm_item_user_idx" ON "drive_item_permission" USING btree ("itemId", "userId", "inheritedFromId", "invitedEmail", "orgKey") NULLS NOT DISTINCT;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "style_guide" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "ownerId" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "markdown" text NOT NULL,
    "orgKey" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "style_guide_uuid_idx" ON "style_guide" USING btree ("uuid");
CREATE INDEX "style_guide_owner_idx" ON "style_guide" USING btree ("ownerId");
CREATE INDEX "style_guide_org_idx" ON "style_guide" USING btree ("orgKey");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "style_guide_org_default" (
    "id" bigserial PRIMARY KEY,
    "orgKey" text NOT NULL,
    "styleRef" text NOT NULL,
    "setById" bigint,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "style_guide_org_default_org_idx" ON "style_guide_org_default" USING btree ("orgKey");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "document_style_guide"
    ADD CONSTRAINT "document_style_guide_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "document_style_guide"
    ADD CONSTRAINT "document_style_guide_fk_1"
    FOREIGN KEY("setById")
    REFERENCES "user_profile"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "style_guide"
    ADD CONSTRAINT "style_guide_fk_0"
    FOREIGN KEY("ownerId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "style_guide_org_default"
    ADD CONSTRAINT "style_guide_org_default_fk_0"
    FOREIGN KEY("setById")
    REFERENCES "user_profile"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261107102052050-org-sharing-style-guides', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261107102052050-org-sharing-style-guides', "timestamp" = now();

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
