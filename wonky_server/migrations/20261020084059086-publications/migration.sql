BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "comment" ADD COLUMN "publicationId" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "drive_item_permission" ADD COLUMN "viaPublicationId" bigint;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "publication" (
    "id" bigserial PRIMARY KEY,
    "publicId" text NOT NULL,
    "ownerId" bigint NOT NULL,
    "name" text NOT NULL,
    "siteUrl" text NOT NULL,
    "webhookUrl" text NOT NULL,
    "verifiedHost" text,
    "verifiedAt" timestamp without time zone,
    "templateItemId" bigint,
    "termsUrl" text,
    "fields" json NOT NULL,
    "signingSecret" text NOT NULL,
    "previousSigningSecret" text,
    "previousSecretUntil" timestamp without time zone,
    "apiKeyHash" text,
    "apiKeyLast4" text,
    "enabled" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "publication_public_idx" ON "publication" USING btree ("publicId");
CREATE INDEX "publication_owner_idx" ON "publication" USING btree ("ownerId");
CREATE INDEX "publication_api_key_idx" ON "publication" USING btree ("apiKeyHash");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "publication_block" (
    "id" bigserial PRIMARY KEY,
    "publicationId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "at" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "publication_block_idx" ON "publication_block" USING btree ("publicationId", "userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "publication_consent" (
    "id" bigserial PRIMARY KEY,
    "publicationId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "consentKey" text NOT NULL,
    "at" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "publication_consent_idx" ON "publication_consent" USING btree ("publicationId", "userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "publication_delivery" (
    "id" bigserial PRIMARY KEY,
    "publicationId" bigint NOT NULL,
    "submissionId" bigint,
    "webhookId" text NOT NULL,
    "type" text NOT NULL,
    "sequence" bigint,
    "payload" text NOT NULL,
    "attempts" bigint NOT NULL DEFAULT 0,
    "nextAttemptAt" timestamp without time zone,
    "leaseUntil" timestamp without time zone,
    "lastStatus" bigint,
    "lastError" text,
    "deliveredAt" timestamp without time zone,
    "failedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "publication_delivery_webhook_idx" ON "publication_delivery" USING btree ("webhookId");
CREATE INDEX "publication_delivery_due_idx" ON "publication_delivery" USING btree ("nextAttemptAt");
CREATE INDEX "publication_delivery_publication_idx" ON "publication_delivery" USING btree ("publicationId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "publication_moderator" (
    "id" bigserial PRIMARY KEY,
    "publicationId" bigint NOT NULL,
    "userId" bigint,
    "email" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "publication_moderator_idx" ON "publication_moderator" USING btree ("publicationId", "email");
CREATE INDEX "publication_moderator_user_idx" ON "publication_moderator" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "submission" (
    "id" bigserial PRIMARY KEY,
    "uuid" uuid NOT NULL,
    "publicationId" bigint NOT NULL,
    "itemId" bigint NOT NULL,
    "ref" text,
    "status" text NOT NULL,
    "statusBeforeSubmit" text,
    "delivery" text,
    "values" json NOT NULL,
    "publicUrl" text,
    "feedbackThreadId" bigint,
    "createdById" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "disconnectedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "submission_uuid_idx" ON "submission" USING btree ("uuid");
CREATE UNIQUE INDEX "submission_item_idx" ON "submission" USING btree ("itemId");
CREATE INDEX "submission_publication_idx" ON "submission" USING btree ("publicationId", "status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "submission_asset" (
    "id" bigserial PRIMARY KEY,
    "submissionId" bigint NOT NULL,
    "fileUuid" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "submission_asset_idx" ON "submission_asset" USING btree ("submissionId", "fileUuid");
CREATE INDEX "submission_asset_file_idx" ON "submission_asset" USING btree ("fileUuid");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "submission_revision" (
    "id" bigserial PRIMARY KEY,
    "submissionId" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "revision" bigint NOT NULL,
    "versionId" bigint,
    "values" json NOT NULL,
    "payload" text NOT NULL,
    "submittedById" bigint NOT NULL,
    "submittedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "submission_revision_idx" ON "submission_revision" USING btree ("submissionId", "sequence");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "comment"
    ADD CONSTRAINT "comment_fk_1"
    FOREIGN KEY("publicationId")
    REFERENCES "publication"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "drive_item_permission"
    ADD CONSTRAINT "drive_item_permission_fk_2"
    FOREIGN KEY("viaPublicationId")
    REFERENCES "publication"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "publication"
    ADD CONSTRAINT "publication_fk_0"
    FOREIGN KEY("ownerId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "publication"
    ADD CONSTRAINT "publication_fk_1"
    FOREIGN KEY("templateItemId")
    REFERENCES "drive_item"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "publication_block"
    ADD CONSTRAINT "publication_block_fk_0"
    FOREIGN KEY("publicationId")
    REFERENCES "publication"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "publication_block"
    ADD CONSTRAINT "publication_block_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "publication_consent"
    ADD CONSTRAINT "publication_consent_fk_0"
    FOREIGN KEY("publicationId")
    REFERENCES "publication"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "publication_consent"
    ADD CONSTRAINT "publication_consent_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "publication_delivery"
    ADD CONSTRAINT "publication_delivery_fk_0"
    FOREIGN KEY("publicationId")
    REFERENCES "publication"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "publication_delivery"
    ADD CONSTRAINT "publication_delivery_fk_1"
    FOREIGN KEY("submissionId")
    REFERENCES "submission"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "publication_moderator"
    ADD CONSTRAINT "publication_moderator_fk_0"
    FOREIGN KEY("publicationId")
    REFERENCES "publication"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "publication_moderator"
    ADD CONSTRAINT "publication_moderator_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "user_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "submission"
    ADD CONSTRAINT "submission_fk_0"
    FOREIGN KEY("publicationId")
    REFERENCES "publication"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "submission"
    ADD CONSTRAINT "submission_fk_1"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "submission_asset"
    ADD CONSTRAINT "submission_asset_fk_0"
    FOREIGN KEY("submissionId")
    REFERENCES "submission"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "submission_revision"
    ADD CONSTRAINT "submission_revision_fk_0"
    FOREIGN KEY("submissionId")
    REFERENCES "submission"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261020084059086-publications', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261020084059086-publications', "timestamp" = now();

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
