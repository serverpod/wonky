# 15 · Writing Tests

How to write tests in this repository. *What* has to be covered is defined elsewhere:
the test levels and critical journeys in [11 §1](11-quality-testing-accessibility.md), command
tests in [08 §4](08-commands-and-undo.md), and the *Tests* section of each feature spec (plus
the testing strategies in [Write 10 §9](wonky_write/10-implementation-plan.md) and
[Sheets 13 §7](wonky_sheets/13-implementation-plan.md)). This spec is the shared *how*:
layout, naming, helpers, determinism and how to run everything.

Agent skills cover the tooling details: `serverpod-testing`, `flutter-add-widget-test`,
`flutter-add-integration-test`, `flutter-add-widget-preview`, `petitparser-test` (formula
grammar).

## 1. Principles

1. **Test at the lowest level that can catch the bug.** Logic goes in pure-Dart packages and
   is unit tested there; widget tests check UI behavior; server tests check endpoints,
   permissions and persistence; E2E covers only the critical journeys.
2. **Every behavior change ships with tests in the same change**; every bug fix starts with a
   failing regression test.
3. **Deterministic**: no real time, randomness, network or sleeps (§4). A flaky test is a bug.
4. **Independent**: tests don't depend on order or on each other's data.
5. **Test public behavior, not internals**: go through the package's public API, the
   `CommandDispatcher`, the endpoint, or the widget as a user would.
6. **Real code over mocks**: prefer real implementations and in-memory fakes (§5).
7. **Fast**: unit tests in milliseconds; slow suites are tagged (§3) so the default run stays
   quick.

## 2. Where tests live

File names mirror `lib/`: `lib/src/markdown/markdown_codec.dart` →
`test/markdown/markdown_codec_test.dart`.

| Package kind | Folder | Content |
|--------------|--------|---------|
| Pure Dart (`packages/wonky_core`, `*_core`, `wonky_sheets_script`, `wonky_revlog`, `wonky_sync_models`) | `test/` | Unit tests, mirroring `lib/` |
| | `test/property/` | Property/fuzz tests (§8) |
| | `test/support/` | Generators, builders, fakes for this package's own tests |
| | `lib/testing.dart` | Public test helpers other packages reuse (fakes, builders, generators); never imported from `lib/` code |
| `wonky_server` | `test/unit/` | Pure logic without Serverpod (no `withServerpod`) |
| | `test/integration/` | `withServerpod` tests: endpoints, services, streams, MCP, permissions |
| | `test/integration/test_tools/` | **Generated** (`serverpod_test_tools.dart`), never edit |
| | `test/support/` | `TestUsers`, `TestDrive`, fakes for external services |
| Flutter (`wonky_ui`, `wonky_app`, apps) | `test/` | Widget and controller tests, mirroring `lib/` |
| | `test/goldens/` | Golden tests and their `.png` masters (§7) |
| | `integration_test/` | App E2E tests (§9) |
| | `lib/testing.dart` | `wonky_ui`: `pumpWonky`; `wonky_app`: `CommandTestHarness`, fake repositories |
| Fixtures / corpora | `test/fixtures/` or the corpora named in the app specs (`wonky_write/test_corpus/`, Sheets JSON vectors) | Loaded through a small loader, never by relative path from the test file |

The template's `widget_test.dart` (counter demo) in both apps is deleted in M0.

## 3. Naming, structure and tags

Use **Given / when / then**, spread over groups and the test name, so a failure explains
itself without reading the code. Same style as the template's server test:

```dart
void main() {
  group('Given a document with a bold word', () {
    late WriteDocumentSession doc;
    setUp(() => doc = TestDocs.fromMarkdown('Hello **world**'));

    test('when toggling bold on it then the word is plain', () { … });
    test('when undoing the toggle then the word is bold again', () { … });
  });
}
```

- One behavior per test; arrange / act / assert, visibly separated.
- No logic (loops, conditionals) in assertions; use table-driven tests for vectors:
  `for (final (input, expected) in cases) test('when parsing "$input" …', …)`.
- Prefer precise matchers (`equals`, `isA<T>().having(…)`, `throwsA(isA<X>())`) over
  `isTrue` on a computed boolean.

**Tags** (declared in each package's `dart_test.yaml`; the server declares `integration`, `slow`
and `live-ai`). package:test has no folder-level tags: every server file under
`test/integration/` starts with `@Tags(['integration'])` + `library;` (`withServerpod` also tags its
group), and `test/unit/source_rules_test.dart` checks that and that Serverpod tests live there.
CI runs the server tests with `-x slow`:

| Tag | Meaning | Default run |
|-----|---------|-------------|
| `integration` | Needs `withServerpod` / a database | yes in server package |
| `property` | Property/fuzz tests with fixed seeds | yes (fast seeds); long runs nightly |
| `golden` | Golden image comparison | CI Linux only (§7) |
| `slow` | > 2 s per test (packages that exclude it in `dart_test.yaml` run it with `-P slow`) | nightly (`nightly.yml`) |
| `e2e` | Full app against a running server | nightly / pre-merge |
| `perf` | Timed perf suites with budgets (`wonky_write/test/perf/`, Write 04 §36; `wonky_slides/test/perf/`, Slides 03 §18); skipped unless `-t perf --run-skipped` | nightly (`nightly.yml`) |

## 4. Determinism

- **Time**: never call `DateTime.now()` in code under test, nor in tests: tests read
  `clock.now()` (so a `withClock` around them applies) or use fixed instants, and wait with a
  `Stopwatch` deadline, never the wall clock (CQ-64j; only the E2E journeys against a live
  server use real time). Services take a clock: pure Dart
  uses `package:clock` (`clock.now()`, tests wrap with `withClock(Clock.fixed(…))`); Sheets'
  formula engine uses its own `EngineClock` ([Sheets 05](wonky_sheets/05-formula-engine.md)).
  Timers and debounces are tested with `fake_async` (pure Dart) or `tester.pump(duration)`
  (widgets), never with real delays.
- **Randomness and ids**: inject `Random` / id generators (UUIDv7, fractional indexes, Sheets'
  `DeterministicRandom`) and seed them in tests.
- **Async**: await the operation or the stream event; for Serverpod streams use
  `flushEventQueue()`. `Future.delayed` in a test is not allowed.
- **Network**: no outgoing calls. External services (AI providers, email, URL fetch proxy,
  cloud storage) are behind interfaces with fakes (§5).
- **Locale and fonts**: tests set locale and time zone explicitly (Sheets parsing/formatting
  depends on them); goldens load bundled fonts only.

## 5. Test doubles

| Need | Use |
|------|-----|
| Collaborator with simple state (repository, store, clock) | **In-memory fake** implementing the real interface, shipped from the owning package's `lib/testing.dart` (e.g. `FakeDriveRepository` in `wonky_app`) |
| External service (AI providers via `dartantic_ai`, email, HTTP fetch) | Fake implementation with scripted responses (`FakeAiModelClient` replays scripted model turns; records requests for assertions) |
| Verify an interaction at a boundary (e.g. "notification sent once") | `mocktail` mock, sparingly |
| Generated Serverpod client | **Never mock it.** UI talks to repositories ([03 §5](03-app-shell-and-navigation.md)); fake the repository instead. Client ↔ server behavior is covered by server tests |
| Database | Real (embedded Postgres via `withServerpod`, in-memory/temporary SQLite for the RevLog client cache) |
| RevLog server (client, Sheets and Slides tests) | `FakeRevServer` (`wonky_revlog/testing.dart`: an in-memory sequencer with the real apply rules, plus `RevTestReplica` clients) and `FakeRevHub` / `FakeRevTransport` (`wonky_revlog_flutter/testing.dart`: the same server behind the client transport, with drop/reconnect hooks). Never a mocked client ([17](17-revlog-sync.md) As built 16) |

Fakes must honor the interface's contract; a shared contract test suite
(`runDriveRepositoryContract(() => impl)`) runs against both the fake and the real
implementation where a fake is widely used.

## 6. Server tests (`wonky_server`)

Built on the generated test tools (`import 'test_tools/serverpod_test_tools.dart'`); see the
`serverpod-testing` skill for the API. Nothing has to be started first: `config/test.yaml`
sets `database.dataPath`, so `withServerpod` boots an embedded Postgres itself. After changing
endpoints the test tools are regenerated (automatic under `serverpod start`, otherwise
`serverpod generate`).

- **Always call endpoints through `endpoints`**, never by instantiating endpoint classes.
  Services (`*_service.dart`) are tested with `sessionBuilder.build()` and the `endpoints`
  parameter ignored.
- **Users**: `TestUsers.create(session, name: 'Anna')` (in `test/support/`) creates the auth
  user and `UserProfile` and returns a `TestUser` with `.session(sessionBuilder)`, a
  `sessionBuilder.copyWith(authentication: AuthenticationOverride.authenticationInfo(…))`.
  Unauthenticated calls use `AuthenticationOverride.unauthenticated()`.
- **Data**: builders with defaults (`TestDrive.document(session, owner: anna, name: …)`,
  `TestDrive.share(session, item, with: bo, role: Role.commenter)`) instead of long manual
  inserts.
- **Permission matrix**: every endpoint method gets role tests ([11 §1](11-quality-testing-accessibility.md)
  contract tests). Use the shared helper so the matrix is complete and uniform:

  ```dart
  forEachRole(
    'Given a shared document', endpoints, sessionBuilder,
    allowed: {Role.owner, Role.editor},
    act: (session, item) => endpoints.document.rename(session, item.uuid, 'New'),
  ); // generates one test per role incl. no access and unauthenticated
  ```

- **Rollback**: default `RollbackDatabase.afterEach`. Use `RollbackDatabase.disabled` only for
  code that runs concurrent transactions (Write OT, RevLog commits); each `withServerpod` group
  gets its own database, so no manual cleanup across groups.
- **Streams** (Write document sessions, presence, UI bridge): open the stream, then
  `await flushEventQueue()`, then act as the second user and assert with
  `emitsInOrder`/`emitsThrough`. Wait for a subscription with `subscribed()` and for events with
  `nextWhere()` (`test/support/streams.dart`); presence through `TestPresence` (`join` returns once
  the roster arrived, `send` once another session saw the update). Never a fixed delay.
- **Future calls / scheduled jobs**: call the job's handler directly with a fixed clock;
  scheduling itself is tested once per job (it is registered with the right delay).
- **External services**: injected through the server's service registry; `withServerpod`
  tests register fakes in `setUp` (e.g. `AiConfig.clientOverride = FakeAiModelClient()`).
- **MCP**: tool logic is tested through `ToolExecutor` with a token-resolved user; each tool
  also has one test through the `/mcp` route (JSON-RPC in, result out) — 09 contract rule.
  If the test tools don't expose the web server, the route tests start the server on port 0
  (as `config/test.yaml` does) and call it over HTTP; decided in the M0 MCP spike.
- **Multi-client sync**: RevLog (Sheets, Slides) with several clients on `FakeRevServer` /
  `FakeRevHub` in one process (pure and client tests), and the sequencer itself with real
  connections in `wonky_server/test/integration/platform/revlog/`; Write's in-process
  `WriteSimulator` ([Write 10](wonky_write/10-implementation-plan.md) WS-W0).
- **(v2) Storage quota**: give the test user a small quota with
  `StorageTestHelpers.setQuota(session, user, bytes)` (writes `UserStorage.quotaBytesOverride`)
  instead of uploading 50 MB; assert counters with `StorageService.usage` and, after each test
  of a byte-adding path, that `StorageReconcile.recompute(user)` equals the maintained row
  ([Drive 03 §4.3](wonky_drive/03-storage-quota.md)). Upload tests use the in-memory cloud
  storage of the test config and small byte arrays; sniffing tests read fixtures from
  `wonky_server/test/fixtures/files/`.

## 7. Flutter tests (`wonky_ui`, `wonky_app`, apps)

- **Pump helper**: `pumpWonky(tester, child, {brightness, density, locale, size})` from
  `package:wonky_ui/testing.dart` wraps the widget in `ShadApp` with `WonkyTheme`,
  localizations and a sensible surface size. `wonky_app`'s `pumpShell` adds the providers
  (fake repositories, `CommandRegistry`, `UndoService`, `KeymapService`).
- **Both themes**: every `wonky_ui` widget test runs in light and dark
  (`for (final b in Brightness.values)`), matching the widget preview requirement of
  [02 §4](02-design-system.md).
- **Finding widgets**: by semantics label (`find.bySemanticsLabel`), text, or a stable key.
  Stable keys are `ValueKey<String>` ids in the form `<area>.<element>` (e.g.
  `shell.topBar.share`, `write.toolbar.bold`) defined as constants next to the widget, so
  widget tests, `flutter_driver` and the MCP UI bridge use the same ids. Never find by
  widget index or private types.
- **Keyboard**: shortcuts and focus traversal are tested with `tester.sendKeyEvent` /
  `sendKeyDownEvent` and `Mod` resolved per platform (`debugDefaultTargetPlatformOverride`
  for macOS vs others).
- **Commands**: `CommandTestHarness` (from `wonky_app/testing.dart`; Sheets extends it in
  `wonky_sheets/test/harness/`) dispatches through the real `CommandDispatcher` and offers
  the 08 §4 round trip:

  ```dart
  test('when bolding the selection then undo and redo round-trip', () async {
    final h = await WriteCommandHarness.fromMarkdown('Hello [world]');  // [] = selection
    await h.expectUndoRedoRoundTrip('write.format.bold');
  });
  ```

- **Accessibility**: `expect(tester, meetsGuideline(textContrastGuideline))`,
  and `labeledTapTargetGuideline` on every screen-level test;
  semantics announcements asserted via `tester.takeAnnouncements()` where specs require them.
- **Goldens**: `test/goldens/<area>/<name>_<variant>_<light|dark>.png`, tagged `golden`.
  Masters are generated and compared **only on Linux** in the pinned
  `ghcr.io/cirruslabs/flutter:<version>` container with bundled fonts (OS font rendering
  differs); locally run `flutter test -x golden`. Update masters with `tool/update_goldens.sh
  [package…]` (Docker: copies the checkout into the container, runs `flutter test
  --update-goldens -t golden test/goldens` and copies only the PNGs back) or the `Goldens`
  workflow run manually with `update` (masters as the `golden-masters` artifact) — never
  commit masters rendered on macOS or Windows. CI (`goldens.yml`) compares every package that
  has committed masters (`tool/golden_packages.sh --with-masters`) and uploads `failures/` on
  a mismatch; a package with golden tests but no masters is listed in the job summary.

## 8. Property and fuzz tests

- Generators live in `test/support/generators/` (or `lib/testing.dart` when shared:
  `DeltaGen`, `EditGen`, Sheets op generators).
- Every property test takes its seed from `WONKY_SEED` (default: a fixed list) and the run
  count from `WONKY_PROPERTY_RUNS`; the seed is printed on failure so it can be replayed:
  `WONKY_SEED=12345 dart test test/property/ot_convergence_test.dart`.
- CI runs the fixed seeds plus one random seed per run (logged); nightly runs long counts.
- Failing cases are shrunk to a minimal sequence and added as a regular regression test.
- RevLog property tests (`wonky_revlog/test/property/`: codec round-trip, chunker, overlay,
  convergence of several clients with offline periods; `wonky_sheets_core`: plans list every
  descendant they delete) run in one process against `FakeRevServer`. Tests that need several
  real Serverpod clients run each client in its own isolate (`serverpod_database` has a
  process-wide encoder — [11 §1](11-quality-testing-accessibility.md)).

## 9. Integration and E2E tests

- App E2E tests live in `integration_test/` and run against a running server
  (`serverpod start`) in development mode; they cover the critical journeys of
  [11 §1.1](11-quality-testing-accessibility.md).
- Agents explore with `flutter_driver` through the `dart` and `serverpod` MCPs (AGENTS.md:
  `get_flutter_app_dtd` → `connect_dart_tooling_daemon`; the apps start from
  `lib/driver.dart`) and turn the flows they verified into permanent `integration_test`
  tests (skill `flutter-add-integration-test`), using the stable keys of §7.
- **Test accounts**: each E2E test creates its own users with unique emails
  (`e2e+<run>-<name>@example.test`). Sign-up needs the verification code; in development and
  test run modes the server exposes an `e2eSupport` endpoint that returns the latest code for
  an `@example.test` address. It refuses all calls unless the run mode is `development` or
  `test`, and a server test asserts that it does in `production` and `staging`
  ([13](13-security-and-operations.md)).
- **Multi-client journeys** (co-editing, presence, sharing) run two app instances, or one
  app instance plus a scripted second client through the generated client.
- **Offline**: toggled through the app's connectivity service test hook (driven through the
  UI bridge), not by killing the server.
- **Write journeys today** (`wonky_write/integration_test/`, tagged `e2e`): 1 sign-up → type →
  reopen, 2 co-editing + own undo, 5 share/comment/suggest/accept, 6 restore + undo, 8 MCP
  create/edit (partial). Helpers in `integration_test/support/e2e.dart`: `launchSignedOut`
  (1440×900 surface, in-memory session via `WonkyClient.sessionStorageOverride`, so runs never
  touch the OS keychain), `pumpUntil`/`pumpUntilTrue` (real delays: pumping alone does not
  yield to the event loop on the live binding), `runCommand` (the app's dispatcher), IME
  typing (`typeImeText` with `testTextInput.register()`), `E2eClient` (second user on the
  generated client: sign-up via `emailIdp` + `e2eSupport`, `document.connect` ops,
  sharing, tokens) and `E2eMcp` (JSON-RPC on `/mcp`). End every journey with `endJourney`.
- **Devices**: `flutter test integration_test/<file>.dart -d macos --run-skipped`, one file per
  run (several files in one run fail to reattach to the relaunched macOS app; the CI
  workflow `e2e.yml`, nightly). `flutter test` does not support web devices; on web use
  `flutter drive -d chrome --driver=test_driver/integration_test.dart --target=…` with a
  chromedriver on port 4444.
- **Web runner for the v2 journeys** (Drive 05 §6, J-D1…J-D10; not set up yet — D-18 found no
  chromedriver on the development machine): (1) install a chromedriver matching the local
  Chrome (`npx @puppeteer/browsers install chromedriver@stable`, or `brew install
  chromedriver`) and start it with `chromedriver --port=4444`; (2) `serverpod start`; (3) in
  the app folder (`wonky_drive`, `wonky_write`, `wonky_sheets`) add
  `test_driver/integration_test.dart` (`integrationDriver()`) and run one journey per call:
  `flutter drive -d chrome --release --driver=test_driver/integration_test.dart
  --target=integration_test/<journey>_test.dart --web-header=Cross-Origin-Opener-Policy=same-origin
  --web-header=Cross-Origin-Embedder-Policy=require-corp` (the apps need cross-origin
  isolation for OPFS and the sqlite worker, as `wonky_server` serves them); (4) CI: a Linux
  job installing Chrome + chromedriver (`browser-actions/setup-chrome`), the same server
  start as `e2e.yml`, then the loop above. Uploads can't come from a real OS drop in
  automation (`webkitGetAsEntry()` is null for synthetic `DataTransfer`s): journeys stage
  files through the upload command (`drive.upload.files` with staged bytes) or the
  `file_picker` input.

## 10. Running tests

| What | Command (in the package folder) |
|------|---------------------------------|
| Pure Dart package | `dart test` |
| Server (unit + integration) | `dart test` in `wonky_server` (`-x integration` for unit only) |
| Flutter package / app | `flutter test -x golden` locally; CI runs with goldens on Linux |
| One test | `dart test path/to/file_test.dart --name "when undoing"` |
| Replay a property failure | `WONKY_SEED=<seed> dart test test/property/<file>` |
| E2E | `flutter test integration_test/<file>.dart -d macos --run-skipped` with the server running (web: `flutter drive`, §9) |
| Coverage | `dart test --coverage=coverage` / `flutter test --coverage` |

CI (`.github/workflows/tests.yml`, see [01 §2](01-architecture.md)) runs every workspace
package that has tests, one job per package, on every PR: `dart test -x slow,e2e` for pure-Dart
packages, `flutter test -x golden,slow,e2e` for Flutter packages and apps, `dart test` in
`wonky_server`, plus the vendored packages' own suites (`third_party/super_editor`,
`third_party/attributed_text`). Exclude tags in one comma-separated `-x`: `flutter test` keeps only
the last of repeated `-x` options. The job *All tests* passes only when every test job passed;
it is the Tests check the `main` ruleset requires (with `analyze`, `format`, `dependencies`,
`server` and *Wonky task*, 16 §13.4), so new packages need no ruleset change. Also on every PR: image goldens in the golden container (`goldens.yml`, §7), the `--wasm` web
build with bundle-size budgets (`build.yml`) and the generated-code check (`analyze.yml`,
`generated`). Nightly (`nightly.yml`): `slow` tests of every member and the server, the `perf`
suites and the Sheets core benchmarks, and long property runs (`WONKY_PROPERTY_RUNS=2000`, the
fixed seeds and one random seed, printed for replay); `e2e.yml` runs the Write journeys.
Still to be added: export validation (LibreOffice, epubcheck, poppler), the web E2E runner
and the coverage gate below.

**Coverage**: logic folders of `*_core`, `wonky_sheets_script` and `wonky_sync_models` keep
≥ 90 % line coverage ([Sheets 13 §7.1](wonky_sheets/13-implementation-plan.md)); other
packages report coverage without a gate.

## 11. Checklist for a change

- [ ] New behavior is tested at the lowest useful level; bug fixes have a regression test.
- [ ] New commands have the execute → undo → redo test; new endpoints the role matrix; new MCP
      tools a `ToolExecutor` test and a `/mcp` test.
- [ ] New `wonky_ui` widgets have light + dark widget tests and a widget preview.
- [ ] (v2) New byte-adding paths have a quota test (refusal + counters); shell UI that differs per
      app is tested for every `HomeScope` (Drive and one app home at least), with
      `FakeStorage` from `wonky_app/testing.dart`.
- [ ] No real time, randomness, network or sleeps; seeds and clocks are injected.
- [ ] Tests pass locally (`dart test` / `flutter test -x golden`) and are tagged if slow.
