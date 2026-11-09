# wonky_server

The Serverpod server of Wonky Work. It also serves the release web builds of
the apps at `/drive/`, `/write/`, `/sheets/` and `/slides/`.

To run it locally (details in `AGENTS.md`, *Running locally*):

    flutter pub get                # in the repository root, once
    cd wonky_server
    cp config/passwords.example.yaml config/passwords.yaml   # once
    serverpod start

The development database is an embedded PostgreSQL, so Docker is not needed.
Start an app from the `serverpod start` UI (or the `spawn_flutter_app` MCP
tool). It runs in debug mode with hot reload: Drive on http://localhost:8100/,
Write on 8101, Sheets on 8102, Slides on 8104. Press `Q` to quit.
