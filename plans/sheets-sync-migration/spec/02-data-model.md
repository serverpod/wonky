# RevLog spec 02 · Data model

All models are Serverpod `.spy.yaml`. Field lists of today's domain tables are in
`packages/wonky_sync_models/lib/src/models/**`; only the changes are listed here.

## 1. New server tables (`wonky_server/lib/src/platform/revlog/models/`)

```yaml
class: RevFile
table: rev_file
serverOnly: true
fields:
  fileUuid: UuidValue              # = drive item uuid = root row id
  kind: RevFileKind                # spreadsheet | deck
  item: DriveItem?, relation(onDelete=Restrict)   # itemId; purge deletes rev_file first (05 §10)
  headRevision: int, default=0
  prunedBelow: int, default=0      # ops < prunedBelow have no payload (05 §10); RevInit uses it
  initPending: bool, default=false # createFile wrote the row but not all initial ops yet (05 §8.3)
  purging: bool, default=false     # purge in progress: refuse connects/submits (05 §10)
  schemaHash: String               # RevSchema hash of the last write
  stats: String, default='{}'      # JSON, binding-defined (§1.1)
  contentCount: int, default=0     # Sheets: grid cells (Σ rows × cols); Slides: elements (informational)
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  rev_file_uuid_idx: { fields: fileUuid, unique: true }
  rev_file_item_idx: { fields: itemId, unique: true }

class: RevOp
table: rev_op
serverOnly: true
fields:
  file: RevFile?, relation(onDelete=Cascade)     # fileId
  revision: int
  clientOpId: UuidValue
  baseRevision: int
  authorId: int?                   # user_profile id (null for system)
  authorUuid: UuidValue?           # auth user uuid (sent to clients)
  sessionId: String?               # client connection session id, or "server:<runId>"
  onBehalfOfSessionId: String?
  actorKind: ActorKind
  label: String
  groupId: String?                 # chunk group of one plan (RD-21)
  groupIndex: int, default=0
  groupLast: bool, default=true
  recordId: UuidValue?             # ServerChangeRecord / assistant run (RD-21)
  offline: bool, default=false
  payload: ByteData?               # gzip codec JSON of the APPLIED changes incl. before (RD-20); null once pruned
  changeCount: int
  summaryJson: String?             # null once pruned
  detailJson: String?              # ≤ 200 cells; null once pruned
  outcomeJson: String?             # full outcome (04 §2.2) for idempotent re-acks; null once pruned
  appliedEqualsSubmitted: bool     # true: the applied form is exactly the submitted changes
  clientCreatedAt: DateTime?
  committedAt: DateTime
indexes:
  rev_op_rev_idx: { fields: fileId, revision, unique: true }
  rev_op_client_idx: { fields: fileId, clientOpId, unique: true }
  rev_op_record_idx: { fields: recordId }
  rev_op_committed_idx: { fields: committedAt, type: brin }   # prune jobs

class: RevHookState
table: rev_hook_state
serverOnly: true
fields:
  file: RevFile?, relation(onDelete=Cascade)
  cursorsJson: String              # {"<hookId>": <last processed revision>, …}
  leaseOwner: String?              # instance id draining this file
  leaseUntil: DateTime?
  attempts: int, default=0
  lastError: String?
  nextAttemptAt: DateTime?
  updatedAt: DateTime
indexes:
  rev_hook_state_file_idx: { fields: fileId, unique: true }
  rev_hook_state_due_idx: { fields: nextAttemptAt }

enum: RevFileKind
serialized: byName
values: [spreadsheet, deck]
```

### 1.1 `rev_file.stats` (also sent as `RevInit.stats` and `RevFileInfo.stats`)

| Binding | JSON |
|---------|------|
| Sheets | `{"tables":{"sheet":3,"sheet_row":3000,"sheet_column":78,"cell":312,…},"sheets":{"<sheetId>":{"rows":1000,"cols":26,"cells":312}}}`. `contentCount` = Σ rows × cols over grid sheets, the quantity capped by `sheets.maxCellsPerSpreadsheet` (Sheets 02 §3.2: "the grid size counts") |
| Slides | `{"tables":{"slide":12,"slide_element":340,…}}`; `contentCount` = elements |

`tables` gives per-table row counts. The client uses them to plan structure loading (06 §5.2); the sequencer uses `tables.protected_range` to skip the protection check on files without protections (05 §3.5).
The sequencer keeps the stats in the same transaction from the applied op's insert and delete
counts (05 §3.2); `revlog.repairStats` recomputes them (05 §10).

## 2. Domain tables

### 2.1 Location and declaration

| | Sheets | Slides |
|--|--------|--------|
| Move from | `packages/wonky_sync_models/lib/src/models/*.spy.yaml` | `…/models/slides/*.spy.yaml` |
| Move to | `wonky_server/lib/src/sheets/models/rows/` | `wonky_server/lib/src/slides/models/rows/` |
| Tables moved | **22** (the 24 files minus `change_log` and `script_user_property`) | **12** (the 13 files minus `deck_change_log`) |
| Enums | 10 Sheets enums | 7 Slides enums |

Per model:

| Change | Detail |
|--------|--------|
| `database: sync` | **removed** → a server table; add `serverOnly: true` (Q3) |
| `spaceId` (implicit) | gone |
| new `file: RevFile?, relation(onDelete=Cascade)` | `fileId` on **every** domain table. Set by the sequencer, never by clients; not part of `RevSchema` |
| new `revision: int` | The revision that last wrote the row. Set by the sequencer; not part of `RevSchema`. Used for debugging and as the starting point of conflict attribution (03 §4.5, 05 §3.2) |
| domain FKs | unchanged `relation(onDelete=Cascade, deferred)`, **except `cell.row` and `cell.column`**: they become plain `rowId: UuidValue` and `columnId: UuidValue` fields with no DB FK. The sequencer cascades cells explicitly by `(sheetId, rowId)` / `(sheetId, columnId)` using the existing indexes (05 §3.3). A DB FK on them would need `(rowId)` and `(columnId)` indexes on the largest table so that row/column deletes don't scan it. `cell.sheet` keeps its FK; its index `(sheetId, …)` serves it |
| `id`, `createdAt` | unchanged |

**Enums.** The server gets Serverpod enums (`.spy.yaml`, `serialized: byName`) in the same
folders. The cores and apps use hand-written pure-Dart enums with identical names and values in
`packages/wonky_sync_models/lib/enums.dart` (RD-5). On the wire and in column maps, enums are
names, so no conversion code is needed beyond `byName`. A guard test compares the value lists.
`ActorKind` moves to `platform/revlog/models/` (the platform uses it) and also has a pure-Dart
twin.

### 2.2 Indexes

- Keep every existing index (inventory models §1–§2).
- Add `<table>_file_idx (fileId, id)` to **every domain table except `cell`**, for structure pages, purge and headless loads.
- **`cell` is never read or deleted by `fileId`.** Whole-file cell access goes sheet by sheet (`WHERE "sheetId" = ANY(@sheets)` or one sheet at a time), using `cell_row_idx (sheetId, rowId)`. This rule applies to headless loads, version capture, search text, content size, stats repair and purge (05 §§6, 9, 10). A `cell (fileId)` index would cost about 40 MB per million cells and is not needed.

### 2.3 Removed tables

| Removed | Replaced by |
|---------|-------------|
| `change_log` (Sheets, synced) | `rev_op` |
| `deck_change_log` (Slides, synced) | `rev_op` |
| `script_user_property` (synced, personal space) | server table `script_user_property` (§2.4) |
| `space_subscription`, `space_reservation` (server) | nothing (RD-9, RD-13) |
| `sheets_change_log_receipt`, `deck_change_log_receipt` (server) | `rev_hook_state` |
| `reserved_space`, `sheets_dirty_space`, `sheets_journal_space`, `sheets_row_journal` (client) | the client cache tables (§3) |
| `crdt_*`, `offline_sync_*` (engine, server and client) | nothing |
| `SheetsMergedSignal` (bus message) | `RevBusMessage` (05 §5) |

**Client database migrations.** `wonky_client/lib/migrations/` is one generated linear chain
(Sheets client migrations followed by `slides-s1`). Never edit it by hand.

- **R5:** once the Sheets synced models and client tables are gone, regenerate the client migrations. The generator produces a migration that drops them.
- **R8:** once the Slides ones are gone too and no `database: client`/`sync` model is left, the server's `config/generator.yaml` loses `experimental_features.databaseSync`, the `serverpod_offline_sync` module and the `shared_packages` entry. The client database is then removed through the generator.

### 2.4 `script_user_property` (server)

```yaml
class: ScriptUserProperty
table: script_user_property
serverOnly: true
fields:
  user: UserProfile?, relation(onDelete=Cascade)
  fileUuid: UuidValue
  key: String
  value: String
  updatedAt: DateTime
indexes:
  script_user_property_idx: { fields: userId, fileUuid, key, unique: true }
```

Endpoints `sheets.getUserProperties(fileUuid)` and
`sheets.setUserProperties(fileUuid, Map<String,String?> changes)` (null = delete); Viewer+, since
the properties are private per user. The client cache and offline queue are in 06 §7.1. Server
scripts read and write the table directly (`ServerUserProperties`, today
`script_service.dart:1209-1300`).

### 2.5 Changed server tables

| Table | Change |
|-------|--------|
| `server_change_record` | `spreadsheetUuid` → `fileUuid`. **Remove** `inverseJson`, `inverseFileId`, `forwardFileId`. **Add** `recordId: UuidValue` (= `rev_op.recordId` of its ops). Revert/reapply compute the changes from the ops' applied payloads (05 §8.2). Keep `changeId`, `cellsAffected`, `expiresAt` (≤ 30 days, within payload retention), `revertedAt`, `revertChangeId` |
| `cell_history` | `changeLogId: UuidValue` → `revision: int`; `spreadsheetUuid` → `fileUuid`. Unique `(fileUuid, revision, rowId, colId)` |
| `sheets_snapshot_index`, `slides_snapshot_index` | Add `revision: int` (the file revision captured). `changedRangesJson` / `changesJson` are built from `rev_op.summaryJson` between two capture revisions |
| `sheets_ai_preview_record` | Rename to `ai_preview_record`; `spreadsheetUuid` → `fileUuid` (Slides uses it too) |
| `item_version` (platform) | For spreadsheets and decks the captured revision goes into the existing `ItemVersion.revision: int?` (`platform/versions/item_version.spy.yaml:13`, used by Write today). `VersionRestoreResult.revision` reports the restore's last revision |
| `sheets_import_job`, `script_execution`, `script_trigger_state`, `script_job`, `script_authorization`, `ai_function_cache` | Unchanged; their `spreadsheetUuid` columns hold the file uuid |
| `drive_item` | `contentRef` = file uuid (unchanged) |

## 3. Client cache schema (SQLite, per user and app)

File `<app>_cache_<userUuid>.db` (`sheets_cache_…`, `slides_cache_…`), opened with
`LocalDatabases.open(…, migrations: revCacheMigrations(schema))` (06 §2). The old
`sheets_<userUuid>.db` / `slides_<userUuid>.db` replica files are removed on first start
(06 §2.1).

```sql
-- Bookkeeping (fixed DDL, in wonky_revlog_flutter)
CREATE TABLE rev_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
   -- 'schemaHash' = RevSchema hash the domain tables were created with (06 §2.4)

CREATE TABLE rev_local_file (
  file_uuid TEXT PRIMARY KEY,
  item_json TEXT,                  -- DriveItemView JSON (offline open, titles)
  role TEXT,
  revision INTEGER NOT NULL,       -- server state stored = state at this revision; only ever increases (06 §2.6)
  complete INTEGER NOT NULL DEFAULT 0,   -- 1 = every row loaded (available offline)
  pinned INTEGER NOT NULL DEFAULT 0,
  last_opened_at INTEGER,
  size_bytes INTEGER NOT NULL DEFAULT 0,
  created_locally INTEGER NOT NULL DEFAULT 0,  -- waiting for the queued drive create (06 §7.1)
  orphaned INTEGER NOT NULL DEFAULT 0          -- queued create failed permanently (06 §8)
);

CREATE TABLE rev_coverage (           -- bootstrap coverage while incomplete (06 §5.3–5.4)
  file_uuid TEXT NOT NULL,
  key TEXT NOT NULL,                  -- 'tbl:<table>:<fromId>:<toId>' (structure ranges) or 'row:<sheetId>:<rowId>' (cells)
  revision INTEGER NOT NULL,          -- page revision Rp
  PRIMARY KEY (file_uuid, key)
);                                    -- collapsed to 'sheet:<sheetId>' once a sheet's cells are all loaded

CREATE TABLE rev_local_op (           -- recent op metadata for offline history (06 §3.3)
  file_uuid TEXT NOT NULL,
  revision INTEGER NOT NULL,
  author_uuid TEXT, session_id TEXT, actor_kind TEXT NOT NULL,
  label TEXT NOT NULL, group_id TEXT, record_id TEXT,
  summary_json TEXT, detail_json TEXT, offline INTEGER NOT NULL DEFAULT 0,
  committed_at INTEGER NOT NULL,
  PRIMARY KEY (file_uuid, revision)
);

CREATE TABLE rev_outbox (
  file_uuid TEXT NOT NULL,
  seq INTEGER NOT NULL,              -- local order
  tab_id TEXT NOT NULL,              -- creating tab/process (RD-22)
  client_op_id TEXT NOT NULL,
  base_revision INTEGER NOT NULL,
  payload TEXT NOT NULL,             -- codec JSON incl. sum/det (uncompressed)
  schema_hash TEXT NOT NULL,         -- hash the payload was encoded with (06 §2.4)
  label TEXT NOT NULL, actor_kind TEXT NOT NULL,
  group_id TEXT, group_index INTEGER NOT NULL DEFAULT 0, group_last INTEGER NOT NULL DEFAULT 1,
  offline INTEGER NOT NULL DEFAULT 0,
  inflight INTEGER NOT NULL DEFAULT 0, -- may have been sent; resend with the same id
  created_at INTEGER NOT NULL,
  PRIMARY KEY (file_uuid, client_op_id)
);
CREATE INDEX rev_outbox_seq ON rev_outbox (file_uuid, seq);

CREATE TABLE rev_outcome (            -- acked outcomes awaiting the review UI (06 §6)
  file_uuid TEXT NOT NULL, revision INTEGER NOT NULL, outcome_json TEXT NOT NULL,
  PRIMARY KEY (file_uuid, revision)
);

-- Domain tables, generated from RevSchema (§4), one per table:
--   CREATE TABLE <table> (id TEXT PRIMARY KEY, file_uuid TEXT NOT NULL, <columns…>);
--   CREATE INDEX <table>_file ON <table> (file_uuid);
--   plus the table's client indexes from RevSchema (e.g. cell (sheetId, rowId)).
-- Column types: uuid/string/json/enumName → TEXT; int/bool/dateTime → INTEGER (dateTime = UTC ms);
-- double → REAL. No foreign keys: cascades arrive as explicit deletes in applied ops and pages.
```

The domain tables hold **server state only**. Unacknowledged local changes live only in
`rev_outbox` and in the in-memory model (the overlay; 03 §7).

## 4. `RevSchema`

Types in `packages/wonky_revlog/lib/src/schema/`; instances in the cores:
`wonky_sheets_core/lib/src/revlog/sheets_schema.dart` and
`wonky_slides_core/lib/src/revlog/slides_schema.dart` (RD-5).

```dart
enum RevColumnType { uuid, string, int, double, bool, dateTime, enumName, json }

final class RevColumn {
  const RevColumn(this.name, this.type, {
    this.nullable = false,
    this.defaultValue,             // applied on insert when the column is missing (03 §4.2)
    this.enumValues,               // for enumName
    this.maxLength,                // string/json (01 §4)
    this.clientWritable = true,    // false: columns only the server writes
    this.immutable = false,        // may not change by update (cell sheetId/rowId/columnId, deterministic-id keys)
  });
}

final class RevParent {
  const RevParent(this.column, this.table, {this.optional = false}); // cascade on delete (sequencer)
}

final class RevTable {
  const RevTable(this.name, this.columns, {
    this.parents = const [],
    this.plainRefs = const [],     // documentation + repair hints; never cascaded
    this.indexes = const [],       // client cache indexes
    this.rank = 0,                 // dependency order (parents first)
    this.deterministicIds = false, // cell, basic_filter, script_build, slide_table_cell, chart_link, theme copies…
    this.clientWritable = true,    // false: script_build
    this.isRoot = false,           // spreadsheet / deck
    this.coverage = RevCoverage.structure, // how bootstrap pages cover this table (06 §5.3)
  });
}

enum RevCoverage { structure, cellsByRow /* Sheets cell: key = sheetId + rowId */ }

final class RevSchema {
  const RevSchema(this.app, this.tables, {required this.coupled, required this.columnwise,
      this.compatibleWith = const {}});
  final String app;                          // 'sheets' | 'slides'
  final Set<String> compatibleWith;          // older hashes whose payloads this schema accepts (additive changes only)
  RevTable table(String name);               // throws on unknown
  RevTable? tryTable(String name);           // decoders: unknown tables/columns of a compatible newer schema are skipped
  int rank(String table);
  String get hash;                           // UUIDv5 over canonical JSON of tables/columns/types/enums
}
```

- **The cores' table constants become part of the schemas.** `SheetsTables`, `SlidesTables`, `SheetsUndo.columnwise` and `SlidesUndoHooks` move onto `sheetsSchema`/`slidesSchema` (`coupled`, `columnwise`). This replaces `SyncedTables`, `SlidesSyncedTables`, `SyncedTableSpec` and `SyncTableSet`.
- **Plan-less summaries move.** Plan-less change summaries are needed by the client (undo, redo, repairs) and the server (server changes). They move from the Sheets app (`SheetsWriter.summarize`, `wonky_sheets/lib/features/sync/sheets_writer.dart:68`) into `wonky_sheets_core` as `SheetsChangeSummary.ofChanges(changes, current)`. Slides keeps `SlidesChangeSummary.of(changes, wasDeleted: …, current: …)` (`change_summary.dart:89`) in its core.

### 4.1 Guard tests

- **Server** (`wonky_server/test/unit/revlog/schema_guard_test.dart`): for every `RevTable`, the generated server table has the same columns, types and nullability, plus `fileId` and `revision`. Parents match the FKs, except `cell.rowId`/`columnId`, which have no FK (§2.1). Server and pure enums have equal value names.
- **Cores:** every table name the planner uses exists in the schema; `coupled`/`columnwise` reference existing columns; `immutable` columns are never updated by any planner op (property test).

### 4.2 Value conversion

Everything is driven by `RevColumn.type`:

- `RevValues.toWire/fromWire` (codec, 03 §3.2);
- `RevValues.toSql` (server parameters with explicit casts);
- `RevValues.toSqlite/fromSqlite` (client cache).

In memory the column-map conventions stay as today: lower-case UUID strings, enum names, UTC
`DateTime`, `double`. So `WorkbookModel` and `DeckModel` ingestion doesn't change.

### 4.3 Hash, compatibility and versioning

| Rule | Detail |
|------|--------|
| Where the hash travels | Every payload (`"s"`), `RevInit.schemaHash` + `RevInit.acceptedHashes` (current + `compatibleWith` still inside `schemaWindowDays`), `ProtocolInfo.revSchemaHash` |
| Server accepts a payload | if its `"s"` is the current hash or in `compatibleWith` within the window. Otherwise `schemaMismatch` |
| Client, older than the server | If its hash is in `RevInit.acceptedHashes`: continue; the decoders **skip** unknown tables and columns of the newer schema (additive changes only). If not: stop sending and show "Update required" (suite 01 §7) |
| Client after an update | It **re-encodes and re-stamps** its outbox with the new schema on load (06 §2.4). Changes to tables or columns that no longer exist are dropped and reported once, so a stale hash never deadlocks the outbox |
| What counts as additive | A new nullable column or a new table. Each additive release adds the previous hash to `compatibleWith`. Anything else (rename, type change, removal) is a breaking release: bump `minClientVersion` |
