BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE INDEX "document_op_created_idx" ON "document_op" USING brin ("createdAt");
--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "rev_file"
    ADD CONSTRAINT "rev_file_fk_0"
    FOREIGN KEY("itemId")
    REFERENCES "drive_item"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "rev_hook_state"
    ADD CONSTRAINT "rev_hook_state_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "rev_op"
    ADD CONSTRAINT "rev_op_fk_0"
    FOREIGN KEY("fileId")
    REFERENCES "rev_file"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261018072556241-revlog', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261018072556241-revlog', "timestamp" = now();

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
