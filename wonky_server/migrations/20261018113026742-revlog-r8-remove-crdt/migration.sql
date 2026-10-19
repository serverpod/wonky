BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "offline_sync_spaces" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "offline_sync_space_nodes" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "offline_sync_space_members" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "offline_sync_integrity_violations" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "crdt_schema_tables" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "crdt_schema_columns" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "crdt_nodes" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "crdt_data_tombstone" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "crdt_data_rows" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "crdt_data_fields" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "crdt_data_attempted_value" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "space_subscription" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "space_reservation" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "sheets_change_log_receipt" CASCADE;


--
-- The offline-sync module is gone (RevLog R8): forget its migration version.
--
DELETE FROM "serverpod_migrations" WHERE "module" = 'serverpod_offline_sync';

--
-- MIGRATION VERSION FOR wonky
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('wonky', '20261018113026742-revlog-r8-remove-crdt', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261018113026742-revlog-r8-remove-crdt', "timestamp" = now();

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


--
-- MIGRATION VERSION FOR 'serverpod_offline_sync'
--
DELETE FROM "serverpod_migrations"WHERE "module" IN ('serverpod_offline_sync');

COMMIT;
