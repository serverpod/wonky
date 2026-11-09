# Wonky Drive

Every file of Wonky Work in one place: the unified drive with all kinds
(documents, spreadsheets, presentations, folders and uploaded files), file
uploads and previews, and the storage page. Web only (specs/01-architecture.md
A13).

- Specs: `specs/wonky_drive/` (start with `01-overview.md`; build plan
  `05-implementation-plan.md`, status `STATUS.md`).
- Served at `/drive/` by `wonky_server`. In development, start it on demand
  from the `serverpod start` UI or the `spawn_flutter_app` MCP tool: it runs
  in debug mode from `lib/driver.dart` at http://localhost:8100/
  (`flutter_apps: drive`; `AGENTS.md`, *Running locally*).
- Release build for the server:
  `flutter build web --wasm --base-href /drive/ --output ../wonky_server/web/drive`.
