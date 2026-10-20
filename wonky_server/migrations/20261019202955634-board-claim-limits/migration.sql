BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "board_task" ADD COLUMN "promptExcludedCommentIds" json;

--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261019202955634-board-claim-limits', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261019202955634-board-claim-limits', "timestamp" = now();

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
