# Wonky Slides

Presentations of Wonky Work: slides on a canvas, themes, layouts and masters,
builds and transitions, code and charts, presenting with presenter view and
PDF export. Offline-first like Wonky Sheets. Web only (specs/01-architecture.md
A13).

- Specs: `specs/wonky_slides/` (start with `01-overview.md`; build plan
  `12-implementation-plan.md`, status `STATUS.md`).
- Served at `/slides/` by `wonky_server`. In development, start it on demand
  from the `serverpod start` UI or the `spawn_flutter_app` MCP tool: it runs
  in debug mode from `lib/driver.dart` at http://localhost:8104/
  (`flutter_apps: slides`; `AGENTS.md`, *Running locally*).
- Release build for the server:
  `flutter build web --wasm --base-href /slides/ --output ../wonky_server/web/slides`.
- State (SL-1): the app skeleton — the Slides home (presentations only) and a
  *Coming soon* deck editor at `/p/:uuid`.
