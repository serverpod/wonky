# Sheets 09 · Scripting (Dart via `dart_eval`)

Wonky Sheets can be extended with **scripts written in Dart**. Scripts are bound to one
spreadsheet. They provide custom formula functions, macros, custom menus, triggers (on open,
on edit, on selection change, on change, time-driven), HTTP fetches and simple UI (alerts,
prompts, toasts). The feature set mirrors Google Apps Script for Sheets. The API is idiomatic
Dart, and execution is sandboxed with `dart_eval`.

Read first:
- Suite [01-architecture.md](../01-architecture.md) decision **A8** (compile on the
  server, run bytecode on server and client), §2 packages (`wonky_sheets_script`).
- [02-data-model.md](02-data-model.md) §3.6 (`ScriptProject`, `ScriptFile`, `ScriptBuild`,
  `ScriptTrigger`, `Macro`, `ScriptProperty`), §3.7 (op log), §7 (writes); suite
  [17](../17-revlog-sync.md) part 5 §6.2 (`scripts` hook), §8 (server changes).
- Suite [08-commands-and-undo.md](../08-commands-and-undo.md) (dynamic
  `sheets.macro.<id>` commands, undo).
- [05-formula-engine.md](05-formula-engine.md) (custom-function hook, recalculation),
  [12-mcp-and-ai.md](12-mcp-and-ai.md) (headless workbook used by server-side scripts).

Priorities: P0 = first complete release, P1 = v1 if possible, P2 = later (designed now).

---

## 1. Use cases and priorities

| Use case | Prio | Where it runs | Section |
|----------|------|---------------|---------|
| **Custom functions** callable from formulas (`=TO_F(A1:A10)`) | P0 | client (each viewer/editor evaluates), server for headless evaluation | §8.6 |
| **Run a function** from the script editor | P0 | client (UI available); P1 "Run on server" | §8.1 |
| **Simple triggers** `onOpen(e)`, `onEdit(e)`, `onSelectionChange(e)`, `onChange(e)` | P0 | client of the user who caused the event | §8.7 |
| **Custom menus** built in `onOpen` (`ui.createMenu(...)`) | P0 | client | §16 |
| **Alerts, prompts, toasts** | P0 | client (server: alerts/prompts throw, toasts are logged) | §16 |
| **Logging** `Logger.log` → execution log and editor console | P0 | both | §13 |
| **Properties** (document + user) | P0 | both | §6.9 |
| **Macros**: record actions → Dart code; run from menu/shortcut | P1 | client (server when invoked via MCP) | §15 |
| **Installable triggers**: time-driven, installable onEdit/onChange/onOpen | P1 | server, as the installing user | §8.7 |
| **HTTP fetch** `UrlFetchApp.fetch` via server proxy | P1 | client → server proxy; server | §8.3 |
| **MCP**: list/run functions, read/update script files, read executions | P1 | server | §18 |
| **Sidebars/dialogs** with a declarative UI DSL rendered with shad | P2 | client | §16.3 |
| `LockService`, `CacheService`, `DriveApp`-lite | P2 | server (lock), both | §6.12 |

Non-goals: debugger with breakpoints (logs only), deployments/versions/add-ons, web apps
(`doGet`), arbitrary Flutter UI from scripts, standalone (unbound) script projects, email
sending.

---

## 2. `dart_eval` facts that shape the design

| Fact (dart_eval **0.8.5**, eval_annotation 0.8.1) | Consequence |
|---------------------------------------------------|-------------|
| Compiler is pure Dart and uses `package:analyzer` (large). `Compiler().compile({'pkg': {'main.dart': src}})` → `Program`; `program.write()` → EVC bytecode (`Uint8List`). | **Compile only on the server** (A8). Clients never ship the compiler. |
| `Runtime(ByteData)` / `Runtime.ofProgram(program)`; `runtime.executeLib('package:script/main.dart', 'fn', [args])`. | Clients download bytecode and only instantiate `Runtime`. |
| Values cross the boundary boxed as `$Value` (`$String`, `$int`, `$double`, `$bool`, `$List`, `$Map`, `$null`, `$Closure`, …). | Bridge converts between native Dart values and `$Value`; bulk conversions have fast paths (§8.2.4). |
| Bindings: `@Bind()` on a class + `dart_eval bind` CLI → `$Foo` wrapper classes and an `EvalPlugin` (`compiler.addPlugin`, `runtime.addPlugin`). | The Wonky Script API is a set of `@Bind` classes in `wonky_sheets_script` (§6). One plugin, used by both the server compiler and every runtime. |
| Sandbox: file system, network and process access are denied by default; `runtime.grant(NetworkPermission.url(…))` etc.; custom `Permission`s possible. | We **never** grant built-in permissions. All side effects go through our bindings, which check our own `WonkyScope` permissions (§11). |
| **No CPU or memory limits.** | Every execution runs in a separate isolate (native) or Web Worker (web) that the host kills on timeout (§8.2). Memory is approximated by bridge counters plus process-level caps (§10). |
| 10–50× slower than AOT Dart. | Bulk APIs (`values`, `setValues`) are the recommended style; per-cell loops are documented as slow; the bridge batches writes. |
| Unsupported: mixins, extension methods, `late`, typedefs, sync/async generators, `await for`, switch expressions, conditional/deferred imports, isolates. Partial: records, patterns, generics, enums, null safety, streams, futures, labels, spreads, abstract classes/`implements`, const expressions. | We publish a **"Wonky Dart" language guide** (in-app help) and the compile service runs a **subset lint** that reports unsupported constructs with friendly messages before `dart_eval` sees them (§9.3). The API uses no generics-heavy or stream-based patterns. |
| `flutter_eval` exists | **Not used.** Scripts can't build Flutter widgets; UI is a declarative DSL (§16.3). |

Vendoring (rules in suite [01 §2.3](../01-architecture.md)): `third_party/dart_eval`
holds a pinned copy (0.8.5, a workspace member because the server uses it) with small,
upstreamable patches tracked in `third_party/dart_eval/PATCHES.md`:
- **DE-1** source positions: scope labels carry `name@library:offset` of the enclosing
  declaration and `Runtime.throwScopes` keeps the stack of the last throw; the host maps
  offsets to lines with the build's line tables (function-level frames, §13.2).
- **DE-2** cooperative interrupt hook: `Runtime.onCheckpoint` called every N instructions (N =
  10,000), used for the time limit of the inline (web) runner (§8.2.3) and as a second guard
  in isolates; `resetExecutionState()` after aborted runs.
- **DE-3…DE-19** fixes found by the conformance suite (§21): static getters of source
  classes, `toString`/`==` on null, dynamic calls (`this` handling of `InvokeDynamic`),
  try/catch/finally frame corruption, boxing of class types, conditional expressions with
  null, 64-bit integer literals, implicit super constructors, nullable casts, catchable
  setter exceptions, `DateTime.utc`/`fromMillisecondsSinceEpoch`, `UncatchableException`
  (time limits cannot be caught by scripts).

dart_eval 0.8.5 needs `analyzer ^8.2.0`, so the workspace resolves analyzer 8.4.1; moving to
a newer analyzer means porting the dart_eval compiler (its AST API changed in 9–13).

Remaining language gaps (documented in the Wonky Dart guide): no enums with `name`/`toString`
(the API uses constant classes such as `ButtonSet.yesNo`), `is` on a class that only
*implements* the tested type is false for an instance-creation expression, named arguments to
`dynamic` receivers, no generators/extensions/mixins/`late`/typedefs (lint errors, §9.3).

---

## 3. Architecture overview

```
 ┌──────────────── RevLog file (spreadsheet) ────────────────┐
 │ ScriptProject ─ ScriptFile* ─ ScriptBuild ─ ScriptTrigger* │
 │              └ Macro* ─ ScriptProperty*                    │
 └───────────────┬───────────────────────────────▲────────────┘
     source edits │ (ops)                         │ ScriptBuild row (system op) + bytecode StoredFile
                  ▼                               │
 ┌─────────────── wonky_server ────────────────────────────────────────────────────────┐
 │ ScriptCompileService (isolate, analyzer + dart_eval Compiler + WonkyScriptPlugin)     │
 │ ScriptScheduler (time-driven) · `scripts` hook (compile, installable onEdit/onChange) │
 │ ScriptJobQueue ──► ScriptWorker(s): isolate pool, ServerScriptHost ─► HeadlessWorkbook │
 │                                          └► server change (submitServerChange)        │
 │ UrlFetchProxy (SSRF-safe) · ScriptEndpoint · MCP sheets.* script tools                 │
 └──────────────────────────────────────────────────────────────────────────────────────┘
                  │ bytecode download (signed URL, cached locally)
                  ▼
 ┌─────────────── wonky_sheets (app) ─────────────────────────────────────────────────────┐
 │ ScriptService ─ ClientScriptHost ─► WorkbookModel + session write + UI (dialogs/toasts)│
 │      │  SyncChannel (native: Mailbox · web: SharedArrayBuffer + Atomics)              │
 │      ▼                                                                               │
 │ Sandbox: Isolate (desktop) / Web Worker (web) running dart_eval Runtime + guest proxies│
 └──────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Package `wonky_sheets_script` (pure Dart)

| Library | Imported by | Content |
|---------|-------------|---------|
| `wonky_sheets_script.dart` | app, server | `src/api/api_source.dart`: the API library `package:wonky/wonky.dart` **as Dart source** (§6) compiled with every script; `src/guest/`: `GuestRuntime`, `GuestBridge` (the two bridge functions `wonkyHostCall`/`wonkyHostError`, write batching, boxing with lazy rows), `WonkyRuntimePlugin` (bridge functions, `CellError` binding, allocation guards); `src/protocol/`: `HostCall`/`HostReply`, `ScriptError`, the binary `ValueCodec`; `src/host/`: `ScriptHost`, `WorkbookAccess`/`ModelWorkbookAccess`, `ExecutionContext`, `ScriptUiDelegate`, `PropertyStore`, `UrlFetcher`, `TriggerStore`, limits; `src/runner/`: `ScriptRunner`, `InlineScriptRunner`, `runScript`, events; `ScriptCustomFunctions`; `MacroRecorder`; `ScriptSession`; `ScriptExports`/`ScriptDiagnostic`. Web-safe. |
| `native.dart` | desktop app, server | `IsolateScriptRunner`: guest isolates with a `Mailbox` sync channel, watchdog (time, RSS). |
| `compiler.dart` | **server only** | `ScriptCompiler` (analyzer parse + subset lint, exports extraction, dispatcher generation, dart_eval `Compiler` with `WonkyCompilerPlugin`). Importing it (or `package:analyzer`, `package:dart_eval/dart_eval.dart`) from the app is forbidden (`tool/check_dependencies.dart`). |
| `testing.dart` | tests | `compileScript`, `ScriptTestBench`, fakes, the conformance corpus. |

**Decision (implementation): the API is interpreted Dart source over one bridge function**
instead of `@Bind` classes generated by `dart_eval bind`. Every API member forwards
`(handle, method, args)` to the host; only `CellError` is a bridged class. One source of truth
(the same file documents the API), exception classes scripts can catch by type, no generated
code to keep in sync. The interpretive overhead per call is small next to the host round
trip. The autocomplete index (`api_index.json`, §14.4) is generated from that source with the
analyzer (P1, not built yet).

The client depends on `dart_eval` (runtime), and therefore transitively on `analyzer` at pub
resolution time. Tree shaking removes the compiler: a probe with the client runtime
(`tool/web_bundle_probe.dart`) has no analyzer symbols. **Measured** (2026-10, Dart 3.13,
`-O4` JS / `-O2` wasm), over a baseline with the workbook model, planner and formula engine
the app already ships: **+736 KB JS (+213 KB gzip)**, **+714 KB wasm (+241 KB gzip)**; the
dart_eval `Runtime` alone is 567 KB JS / 152 KB gzip. Well under the 1.5 MB gzip budget.

**Call overhead** (`tool/benchmark.dart`, JIT, Apple M-series): the interpreter runs about
170 M simple instructions/s (1 M-iteration loop: 60–80 ms); one host call (`range.value`)
costs ≈ 14 µs inline and ≈ 30 µs through an isolate `Mailbox`; a buffered single-cell write
≈ 25–35 µs (planner included); reading 100 k cells with `values` ≈ 20 ms; writing 30 k cells
with `values` ≈ 1.1 s (planner dominated).

### 3.2 Host-side `WorkbookAccess`

Both hosts implement the same interface, so API semantics are identical on client and server:

```dart
abstract interface class WorkbookAccess {
  WorkbookModel get model;            // reads (cells, formats, structure)
  FormulaEngine get engine;           // computed values (pull-based recalculation)
  FormulaHooks get formulas;          // A1 ⇄ stored formulas
  EffectiveFormatResolver get formats;
  String get userId;                  // auth user (PlanContext.userId)
  IdGenerator get ids;
  MutationPlan apply(SheetsOperation op, {bool undoable = true}); // plan + apply to model
  List<AppliedPlan> get applied;      // the caller persists these
}
```

`ScriptHost` (shared) implements every API member on top of it, so semantics are identical on
client and server. `ModelWorkbookAccess` is the implementation over a `WorkbookModel` (it
creates or reuses a `ModelEngineBinding`). Writes are `SheetsOperation`s planned by the
`SheetsMutationPlanner` and applied to the model immediately (read-your-writes); the caller
persists `ExecutionResult.applied`: the app through its session (one undo step), the
server as a recorded server change (`SheetsBulkWriter.applyRecorded`, one `ServerChangeRecord`) after the run, on a
private copy of the `HeadlessWorkbook` model (script tables loaded from the database).

---

## 4. Script project and files

- A spreadsheet has at most one `ScriptProject`, created lazily on first open of the script
  editor (`sheets.script.openEditor`) with `name = "<spreadsheet title> script"` and one file
  `main.dart` containing the template below.
- Files: flat list (no folders in v1), ordered by `sortKey`. Names match
  `^[a-z][a-z0-9_]{0,63}\.dart$`, unique per project (client-enforced; merge duplicates are
  renamed with the same deterministic rule as sheet names).
- Each file is a library `package:script/<name>`. Files may import each other
  (`import 'utils.dart';`) and must import `package:wonky/wonky.dart` to use the API.
- Allowed imports: `dart:core` (implicit), `dart:math`, `dart:convert`, `dart:collection`,
  `dart:async` (Futures only), `package:wonky/wonky.dart`, other project files. Anything else
  is a compile error ("Import not allowed in scripts: dart:io").
- Max 50 files, 500 KB per file, 2 MB per project.

Template `main.dart`:

```dart
import 'package:wonky/wonky.dart';

/// Runs when the spreadsheet is opened. Add custom menus here.
void onOpen(OpenEvent e) {
  SpreadsheetApp.ui
      .createMenu('My tools')
      .addItem('Say hello', 'sayHello')
      .addToUi();
}

void sayHello() {
  SpreadsheetApp.active.toast('Hello from Wonky Script!');
}
```

---

## 5. Entry points and metadata

The compile service extracts **exports** from all files. Exported = every public top-level
function (name not starting with `_`).

| Kind | How it is declared | Signature rules |
|------|--------------------|-----------------|
| Runnable function | any exported function | no required parameters to be runnable from menus/editor/triggers |
| Custom function | doc comment tag `@customfunction` | params: `Object?` (scalars or `List<List<Object?>>`), returns `Object?`; name usable in formulas as `NAME` (case-insensitive, the Dart name upper-cased) |
| Simple trigger | reserved names `onOpen`, `onEdit`, `onSelectionChange`, `onChange` | one optional parameter of the matching event type |
| Macro | `Macro` row pointing to a function (recorder or *Import macro*) | no parameters |
| Menu item | `Menu.addItem(caption, 'functionName')` at runtime | no parameters |
| Installable trigger target | `ScriptTrigger.functionName` | optional event parameter |

Custom function doc comment format (shown in formula autocomplete and the function help card,
same UI as built-ins, see [05-formula-engine.md](05-formula-engine.md)):

```dart
/// Converts Celsius to Fahrenheit.
///
/// @customfunction
/// @param celsius A temperature in °C, or a range of temperatures.
/// @return The temperature(s) in °F.
/// @example =TO_F(A2:A20)
Object? TO_F(Object? celsius) { … }
```

Name conflicts: a custom function whose upper-cased name equals a built-in function is
**shadowed by the built-in** and gets a compile warning. Names must match `^[A-Z_][A-Z0-9_.]*$`
after upper-casing.

### 5.1 `exportsJson` schema (written to `ScriptBuild.exportsJson`)

```jsonc
{
  "apiVersion": 1,
  "functions": [
    { "name": "TO_F", "library": "package:script/main.dart", "line": 12,
      "params": [ { "name": "celsius", "type": "Object?", "optional": false, "doc": "A temperature…" } ],
      "returns": "Object?", "async": false, "doc": "Converts Celsius to Fahrenheit.",
      "customFunction": { "formulaName": "TO_F", "examples": ["=TO_F(A2:A20)"] },
      "runnable": false }
  ],
  "triggers": { "onOpen": "package:script/main.dart", "onEdit": null,
                "onSelectionChange": null, "onChange": null },
  "scopes": ["spreadsheet.current", "ui", "external_request"],   // §11.1, detected statically
  "customFunctionScopes": [],                                     // scopes reachable from custom functions
  "warnings": 2,
  "lineStarts": { "main.dart": [0, 35, 36] }  // DE-1 line tables (instead of a positions file)
}
```

---

## 6. The Wonky Script API

Library `package:wonky/wonky.dart`. All classes are bound with `@Bind()` (wrapper interop:
scripts can use but not extend them). Design rules:
- Idiomatic Dart: getters/setters for properties, methods for actions, named parameters for
  options, `List<List<Object?>>` for 2D data, `DateTime` for dates.
- **Synchronous** wherever possible (the sandbox blocks on the bridge, §8.2). Only
  `UrlFetchApp.fetchAll` is optionally parallel.
- Row and column numbers are **1-based** (spreadsheet convention, Apps Script parity).
- Cell values crossing the API: `null` (empty), `num` (`int` when integral, else `double`),
  `String`, `bool`, `DateTime` (cells with a date/time format; converted in the spreadsheet
  time zone), `CellError` (errors, e.g. `#N/A`). Writing a `String` that starts with `=` via
  `values` writes a formula (Apps Script parity); use `setValuesRaw` to force text.

### 6.1 Entry points

```dart
/// Static entry point for the bound spreadsheet.
abstract class SpreadsheetApp {
  /// The spreadsheet this script is bound to.
  static Spreadsheet get active;

  /// UI of the current user's window. Throws [UiUnavailableException] in
  /// server-side executions (time-driven triggers, MCP) and in custom functions.
  static Ui get ui;

  /// The active (selected) sheet / range of the user running the script, or the
  /// first sheet / A1 in server-side executions.
  static Sheet get activeSheet;
  static Range get activeRange;
  static List<Range> get activeRangeList;     // multi-range selection
  static Range? get currentCell;

  /// Applies all pending writes and recalculates formulas now. Reads flush
  /// implicitly, so this is only needed before long non-spreadsheet work.
  static void flush();
}
```

### 6.2 `Spreadsheet`

```dart
abstract class Spreadsheet {
  String get id;                              // spreadsheet (file) UUID
  String get name;  set name(String value);   // renames the Drive item (undoable)
  String get url;                             // https://<host>/sheets/s/<id>
  String get locale; set locale(String value);
  String get timeZone; set timeZone(String value);

  List<Sheet> get sheets;                     // in tab order, including hidden
  Sheet? sheetByName(String name);
  Sheet? sheetById(String id);
  Sheet get activeSheet;  set activeSheet(Sheet sheet);   // client only (no-op on server)

  Sheet insertSheet({String? name, int? index, Sheet? template});   // index: 1-based tab position
  Sheet duplicateSheet(Sheet sheet, {String? newName});
  void deleteSheet(Sheet sheet);
  void moveSheet(Sheet sheet, int index);     // 1-based tab position

  /// "Sheet1!A1:B10", "A1" (active sheet), "MyNamedRange".
  Range getRange(String a1Notation);
  RangeList getRangeList(List<String> a1Notations);

  List<NamedRange> get namedRanges;
  Range? getRangeByName(String name);
  void setNamedRange(String name, Range range);
  void removeNamedRange(String name);

  /// Bottom-right toast in every open window of the running user.
  void toast(String message, {String? title, double timeoutSeconds = 5});

  User get owner;
  List<User> get editors;                    // requires scope `spreadsheet.sharing.read` (P2)
}
```

### 6.3 `Sheet`

```dart
abstract class Sheet {
  String get id;
  String get name;  set name(String value);
  int get index;                              // 1-based tab position
  bool get isHidden;  void hide();  void show();
  String? get tabColor; set tabColor(String? hex);
  Spreadsheet get parent;

  // ---- Ranges ----
  Range getRange(String a1Notation);                       // "A1:C10", "B:B", "3:3"
  Range getRangeAt(int row, int column, [int numRows = 1, int numColumns = 1]);
  Range get dataRange;                                     // A1 to (lastRow, lastColumn)
  int get lastRow;                                         // last row with content (0 if empty)
  int get lastColumn;
  int get maxRows;
  int get maxColumns;
  Range? get activeRange;                                  // client only

  // ---- Structure ----
  void insertRowsBefore(int row, int count);
  void insertRowsAfter(int row, int count);
  void insertColumnsBefore(int column, int count);
  void insertColumnsAfter(int column, int count);
  void deleteRows(int row, [int count = 1]);
  void deleteColumns(int column, [int count = 1]);
  void hideRows(int row, [int count = 1]);
  void showRows(int row, [int count = 1]);
  void hideColumns(int column, [int count = 1]);
  void showColumns(int column, [int count = 1]);
  void setRowHeight(int row, double px);
  void setColumnWidth(int column, double px);
  void autoResizeColumns(int startColumn, int count);
  int get frozenRows;     set frozenRows(int n);
  int get frozenColumns;  set frozenColumns(int n);

  // ---- Content ----
  /// Appends after [lastRow]; extends the grid if needed.
  void appendRow(List<Object?> values);
  void clear({bool contentsOnly = false, bool formatsOnly = false});
  void sort(int column, {bool ascending = true});         // whole sheet below frozen rows

  // ---- Objects & rules ----
  List<EmbeddedChart> get charts;
  ChartBuilder newChart();                                 // P1
  void insertChart(EmbeddedChart chart);                   // P1
  void removeChart(EmbeddedChart chart);
  Filter? get filter;                                      // basic filter (P1)
  List<ConditionalFormatRule> get conditionalFormatRules;  // P1 read; P2 write
  Protection protect();                                    // sheet protection (P1)
}
```

Built (2026-10-14): `charts`, `newChart()` → `EmbeddedChartBuilder` (`setChartType`,
`addRange`, `removeRange`, `clearRanges`, `setTitle`, `setPosition(row, column)`,
`setSize`, `setOption(jsonPath, value)` = a `ChartSpec` patch, `build()`), `insertChart`
(returns the inserted chart; an empty type picks the recommended chart), `updateChart`
(for `chart.modify()…build()`), `removeChart`; `filter` → `Filter` (`range`,
`get/set/removeColumnFilterCriteria`, `sort`, `remove`) and `Range.createFilter()`;
`FilterCriteria.hideValues/condition/whenNumberGreaterThan/…`; `conditionalFormatRules`,
`addConditionalFormatRule` (boolean conditions with fill/text color/bold/italic/strikethrough,
two-color gradients; `ConditionalFormatRuleBuilder`), `removeConditionalFormatRule`;
`protect()` / `Range.protect()` / `protections` → `Protection` (`description`,
`warningOnly`, `editors`, `addEditor`, `removeEditor`, `unprotectedRanges`, `remove`). Every
write is one planner operation of the execution's undo step.

### 6.4 `Range`

```dart
abstract class Range {
  Sheet get sheet;
  String get a1Notation;                      // "B2:D10" (without sheet name)
  int get row;  int get column;               // 1-based top-left
  int get numRows;  int get numColumns;
  int get lastRow;  int get lastColumn;

  // ---- Values (top-left cell) ----
  Object? get value;          set value(Object? v);
  String get displayValue;
  String get formula;         set formula(String a1Formula);   // "" when no formula
  String? get note;           set note(String? text);

  // ---- 2D data ----
  List<List<Object?>> get values;           set values(List<List<Object?>> v);
  List<List<String>>  get displayValues;
  List<List<String>>  get formulas;         set formulas(List<List<String>> f);
  List<List<String?>> get notes;            set notes(List<List<String?>> n);
  void setValues(List<List<Object?>> values);               // same as the setter (chainable style)
  void setValuesRaw(List<List<Object?>> values);            // strings never parsed as formulas/numbers

  // ---- Formats (getter = 2D, setter = apply to all cells; plural setters take 2D) ----
  List<List<String?>> get numberFormats;    set numberFormat(String pattern);
  void setNumberFormats(List<List<String?>> patterns);
  List<List<String?>> get backgrounds;      set background(String? color);   // "#RRGGBB" or null
  void setBackgrounds(List<List<String?>> colors);
  List<List<String?>> get fontColors;       set fontColor(String? color);
  List<List<String>>  get fontWeights;      set fontWeight(String weight);   // 'bold' | 'normal'
  List<List<String>>  get fontStyles;       set fontStyle(String style);     // 'italic' | 'normal'
  List<List<String>>  get fontFamilies;     set fontFamily(String family);
  List<List<double>>  get fontSizes;        set fontSize(double size);
  List<List<String>>  get horizontalAlignments; set horizontalAlignment(String a); // left|center|right|general
  List<List<String>>  get verticalAlignments;   set verticalAlignment(String a);   // top|middle|bottom
  set wrapStrategy(String s);                                                     // overflow|wrap|clip
  set textDecoration(String d);                                                   // none|underline|lineThrough
  void setBorder({bool? top, bool? left, bool? bottom, bool? right,
                  bool? vertical, bool? horizontal, String? color, String style = 'thin'});

  // ---- Operations ----
  void clear({bool contentsOnly = false, bool formatsOnly = false, bool notesOnly = false});
  void clearContent();
  void clearFormat();
  void merge();  void mergeAcross();  void mergeVertically();  void breakApart();
  bool get isMerged;
  bool get isBlank;
  void sort(List<SortSpec> specs);                             // SortSpec(column: 2, ascending: false)
  void copyTo(Range destination, {bool contentsOnly = false, bool formatsOnly = false});
  void moveTo(Range destination);
  Range offset(int rowOffset, int columnOffset, [int? numRows, int? numColumns]);
  Range cell(int row, int column);                             // 1-based, relative to this range
  Range activate();                                            // client only: selects in UI
  void insertCheckboxes();  void removeCheckboxes();
  Range trimWhitespace();
  Range removeDuplicates([List<int>? columnsToCompare]);       // returns resulting range (P1)
  DataValidation? get dataValidation;  set dataValidation(DataValidation? rule);   // P1
  Filter createFilter();                                       // P1
}

class SortSpec { SortSpec({required int column, bool ascending = true}); }
abstract class RangeList { List<Range> get ranges; void clear(); set background(String? c); /* … */ }
abstract class NamedRange { String get name; Range get range; void remove(); }
class CellError { String get code; /* '#N/A', '#DIV/0!', … */ }
```

### 6.5 `Ui` and menus

```dart
abstract class Ui {
  /// Modal alert. Blocks the script until dismissed (time waiting does not count
  /// toward the execution limit; max 5 minutes, then returns Button.close).
  Button alert(String message, {String? title, ButtonSet buttons = ButtonSet.ok});
  PromptResponse prompt(String message, {String? title, ButtonSet buttons = ButtonSet.okCancel});
  Menu createMenu(String caption);
  void showSidebar(UiPanel panel);                       // P2 (§16.3)
  void showModalDialog(UiPanel panel, String title);     // P2
}

// Constant classes (dart_eval enums lack name/toString): ButtonSet.okCancel, b.name.
class ButtonSet { static const ok, okCancel, yesNo, yesNoCancel; String get name; }
class Button { static const ok, cancel, yes, no, close; String get name; }
abstract class PromptResponse { Button get selectedButton; String get responseText; }

abstract class Menu {
  Menu addItem(String caption, String functionName);
  Menu addSeparator();
  Menu addSubMenu(Menu menu);
  /// Adds the menu under Extensions (top-level menu in the menubar when
  /// "Show script menus in menubar" is on, the default) for this session.
  void addToUi();
}
```

### 6.6 `Session` and users

```dart
abstract class Session {
  static User get activeUser;        // the person running (or triggering) the script
  static User get effectiveUser;     // run-as user (installer for installable triggers)
  static String get scriptTimeZone;  // project time zone (defaults to spreadsheet's)
  static String get activeUserLocale;
}
abstract class User { String get email; String get name; String get id; }
```

`email` requires scope `user.email` (§11.1); without it `email` is `""` (Apps Script parity).

### 6.7 `UrlFetchApp`

```dart
abstract class UrlFetchApp {
  static HttpResponse fetch(String url, [FetchOptions? options]);
  static List<HttpResponse> fetchAll(List<FetchRequest> requests);   // P1, ≤ 20, parallel on host
}
class FetchOptions {
  FetchOptions({String method = 'get', Map<String, String>? headers, String? payload,
      String? contentType, bool followRedirects = true, bool muteHttpExceptions = false,
      int timeoutSeconds = 30});
}
abstract class HttpResponse {
  int get statusCode;
  Map<String, String> get headers;
  String get contentText;                // decoded per charset (UTF-8 default)
  List<int> get bytes;
  Object? json();                        // jsonDecode(contentText)
}
```

### 6.8 `Utilities` and `Logger`

```dart
abstract class Utilities {
  static String formatDate(DateTime date, String timeZone, String pattern);   // spreadsheet patterns ("yyyy-mm-dd")
  static DateTime parseDate(String text, String timeZone, String pattern);
  static void sleep(int milliseconds);         // ≤ 5,000 per call; counts toward the time limit
  static String uuid();                         // UUIDv4
  static String base64Encode(List<int> bytes);
  static List<int> base64Decode(String text);
  static String computeDigest(String algorithm, String value);   // md5|sha1|sha256|sha512 → hex
  static String computeHmac(String algorithm, String value, String key);  // sha256|sha512 → hex
  static String jsonEncode(Object? value);
  static Object? jsonDecode(String text);
  static String formatString(String template, List<Object?> args);  // printf-like %s %d %.2f
}

abstract class Logger {
  static void log(Object? message);      // also: print() is captured as log
  static void info(Object? message);
  static void warn(Object? message);
  static void error(Object? message);
}
```

### 6.9 `PropertiesService`

```dart
abstract class PropertiesService {
  /// Shared by everyone with access; stored in ScriptProperty (a table of the spreadsheet's file).
  static Properties get documentProperties;
  /// Per user per spreadsheet; stored in ScriptUserProperty (server table, private per user).
  static Properties get userProperties;
}
abstract class Properties {
  String? getProperty(String key);
  void setProperty(String key, String value);   // value ≤ 9 KB; store ≤ 500 KB
  void deleteProperty(String key);
  Map<String, String> getProperties();
  void setProperties(Map<String, String> values, {bool deleteAllOthers = false});
  List<String> get keys;
}
```

Property writes are **not** on the spreadsheet undo stack (Apps Script parity) but are written
as ops of the spreadsheet with the script's label (so collaborators receive them).

**User properties — where they live (suite 17 part 2 §2.4).**
`ScriptUserProperty(userId, fileUuid, key, value, updatedAt)` is a
server table, private per user and spreadsheet (unique `(userId, fileUuid, key)`; ≤ 500
properties, values ≤ 9 KB), outside the spreadsheet's RevLog file. Clients read and write it
with `sheets.getUserProperties(fileUuid)` / `sheets.setUserProperties(fileUuid, changes)`
(Viewer+, null = delete; `ScriptUserProperties` in
`wonky_server/lib/src/sheets/scripts/script_user_properties.dart`), keep the values in memory
while the script service runs (scripts read synchronously) and write changes back in the
background. A copy of the values and the unsent changes are kept in the user's local store
(`sheets.userProps.<fileUuid>`, `features/scripts/runtime/user_properties.dart`), so offline
runs read the last values and their writes are sent on the next load or write (last write wins
per key). Server runs load the run-as user's rows before the run and write the changes
after it in one transaction (`ServerUserProperties` in
`wonky_server/lib/src/sheets/scripts/script_service.dart`).

### 6.10 Event objects

```dart
abstract class OpenEvent { Spreadsheet get source; User get user; AuthMode get authMode; }
abstract class EditEvent {
  Spreadsheet get source; Range get range; User get user;
  Object? get value;          // only when a single cell was edited
  Object? get oldValue;       // only when a single cell was edited
  String? get triggerUid;     // installable only
  bool get offline;           // installable: the edit's op was made offline (`op.offline`) and synced later
}
abstract class SelectionChangeEvent { Spreadsheet get source; Range get range; User get user; }
abstract class ChangeEvent {
  Spreadsheet get source; User get user;
  String get changeType;      // EDIT | INSERT_ROW | INSERT_COLUMN | REMOVE_ROW | REMOVE_COLUMN |
                              // INSERT_GRID | REMOVE_GRID | FORMAT | OTHER
}
abstract class TimeEvent { String get triggerUid; DateTime get scheduledAt; DateTime get firedAt; }
class AuthMode { static const limited, full; }  // limited: user hasn't authorized the project (§11.2)
```

### 6.11 Triggers API (P1)

```dart
abstract class ScriptApp {
  static TriggerBuilder newTrigger(String functionName);
  static List<Trigger> get projectTriggers;        // triggers of the current user
  static void deleteTrigger(Trigger trigger);
}
abstract class TriggerBuilder {
  TimeTriggerBuilder timeBased();
  SpreadsheetTriggerBuilder forSpreadsheet();      // .onEdit() / .onChange() / .onOpen()
}
abstract class TimeTriggerBuilder {
  TimeTriggerBuilder everyMinutes(int n);          // 1, 5, 10, 15, 30
  TimeTriggerBuilder everyHours(int n);            // 1, 2, 4, 6, 8, 12
  TimeTriggerBuilder everyDays(int n);
  TimeTriggerBuilder everyWeeks(int n);
  TimeTriggerBuilder atHour(int hour);             // 0–23, ±15 min jitter
  TimeTriggerBuilder onWeekDay(int weekday);       // DateTime.monday…
  TimeTriggerBuilder onMonthDay(int day);
  TimeTriggerBuilder at(DateTime when);            // one-shot
  Trigger create();
}
abstract class Trigger { String get uid; String get functionName; String get eventType; }
```

### 6.12 P2 services

```dart
abstract class LockService { static Lock get documentLock; }      // server-side; client returns a no-op lock
abstract class Lock { bool tryLock(int timeoutMs); void waitLock(int timeoutMs); void releaseLock(); }
abstract class CacheService { static Cache get documentCache; static Cache get userCache; }
abstract class Cache { String? get(String key); void put(String key, String value, {int ttlSeconds = 600}); void remove(String key); }
abstract class DriveApp {                                          // scope drive.readonly / drive
  static List<DriveFile> search(String query);
  static Spreadsheet openSpreadsheetById(String id);               // must have access; read-only unless editor
  static Spreadsheet createSpreadsheet(String name);
}
```

Built: `LockService.documentLock/scriptLock/userLock` (`tryLock`, `waitLock`, `hasLock`,
`releaseLock`; released when the execution ends; no-op locks in the app, process-wide locks
on the server) and `CacheService.documentCache/scriptCache/userCache` (`get`, `getAll`,
`put`, `putAll`, `remove`, `removeAll`; TTL ≤ 6 h, values ≤ 100 KB, in-memory per process;
usable from custom functions). Not built: `DriveApp` (needs cross-spreadsheet workbooks and
the drive scopes).

### 6.13 Exceptions

`ScriptException` (base, `code`, `message`) with subclasses `RangeException` (invalid A1,
out of bounds), `PermissionDeniedException` (role or protected range), `ScopeNotGrantedException`,
`UiUnavailableException`, `QuotaExceededException`, `UrlFetchException` (`statusCode`,
`muteHttpExceptions`), `OfflineException`, `ExecutionTimeoutException` (not catchable, kills
the run), `CustomFunctionSideEffectException`.

---

## 7. Example scripts

### 7.1 Custom function (scalar or range, spills)

```dart
import 'package:wonky/wonky.dart';

/// Converts Celsius to Fahrenheit.
///
/// @customfunction
/// @param celsius A value or range in °C.
/// @return Value(s) in °F.
Object? TO_F(Object? celsius) {
  if (celsius is List) {
    return celsius.map((row) => (row as List).map(_convert).toList()).toList();
  }
  return _convert(celsius);
}

Object? _convert(Object? c) => c is num ? c * 9 / 5 + 32 : null;
```

### 7.2 `onEdit` timestamp

```dart
import 'package:wonky/wonky.dart';

/// Writes the edit time into column E whenever column D ("Status") changes on "Tasks".
void onEdit(EditEvent e) {
  final range = e.range;
  if (range.sheet.name != 'Tasks' || range.column > 4 || range.lastColumn < 4) return;
  final stamps = <List<Object?>>[];
  for (var i = 0; i < range.numRows; i++) {
    stamps.add([DateTime.now()]);
  }
  range.sheet.getRangeAt(range.row, 5, range.numRows, 1).values = stamps;
}
```

### 7.3 Custom menu + macro

```dart
import 'package:wonky/wonky.dart';

void onOpen(OpenEvent e) {
  SpreadsheetApp.ui
      .createMenu('Report')
      .addItem('Highlight negatives', 'highlightNegatives')
      .addSeparator()
      .addSubMenu(SpreadsheetApp.ui.createMenu('Export').addItem('Copy to Archive', 'archive'))
      .addToUi();
}

/// Registered as macro "Highlight negatives" (Mod+Alt+Shift+1).
void highlightNegatives() {
  final range = SpreadsheetApp.activeRange;
  final values = range.values;
  final colors = <List<String?>>[];
  for (final row in values) {
    colors.add(row.map((v) => v is num && v < 0 ? '#F4C7C3' : null).toList());
  }
  range.setBackgrounds(colors);
}

void archive() {
  final ss = SpreadsheetApp.active;
  final src = ss.sheetByName('Report')!;
  final dst = ss.sheetByName('Archive') ?? ss.insertSheet(name: 'Archive');
  final data = src.dataRange.values;
  dst.getRangeAt(dst.lastRow + 1, 1, data.length, data.first.length).values = data;
  ss.toast('Archived ${data.length} rows');
}
```

### 7.4 Time-driven daily summary (installable trigger)

```dart
import 'package:wonky/wonky.dart';

/// Install once from the editor: Run ▸ installDailyTrigger.
void installDailyTrigger() {
  ScriptApp.newTrigger('dailySummary').timeBased().everyDays(1).atHour(7).create();
}

void dailySummary(TimeEvent e) {
  final ss = SpreadsheetApp.active;
  final orders = ss.sheetByName('Orders')!.dataRange.values;
  var total = 0.0;
  var count = 0;
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  for (final row in orders.skip(1)) {
    final date = row[0];
    if (date is DateTime && date.year == yesterday.year && date.month == yesterday.month &&
        date.day == yesterday.day) {
      total += (row[3] as num).toDouble();
      count++;
    }
  }
  final log = ss.sheetByName('Daily') ?? ss.insertSheet(name: 'Daily');
  log.appendRow([today, count, total]);
  Logger.log('Summary written: $count orders, $total total');
}
```

### 7.5 Fetch JSON into a sheet

```dart
import 'package:wonky/wonky.dart';

void importRates() {
  final res = UrlFetchApp.fetch('https://api.example.com/rates?base=EUR',
      FetchOptions(headers: {'Accept': 'application/json'}));
  final data = res.json() as Map;
  final rates = data['rates'] as Map;
  final rows = <List<Object?>>[['Currency', 'Rate']];
  for (final key in rates.keys) {
    rows.add([key, rates[key]]);
  }
  final sheet = SpreadsheetApp.active.sheetByName('Rates') ??
      SpreadsheetApp.active.insertSheet(name: 'Rates');
  sheet.clear(contentsOnly: true);
  sheet.getRangeAt(1, 1, rows.length, 2).values = rows;
  sheet.getRange('A1:B1').fontWeight = 'bold';
  sheet.frozenRows = 1;
}
```

### 7.6 Data cleanup

```dart
import 'package:wonky/wonky.dart';

/// Trims text, normalizes e-mail case, removes empty and duplicate rows in the selection.
void cleanUpSelection() {
  final range = SpreadsheetApp.activeRange;
  final seen = <String>{};
  final out = <List<Object?>>[];
  for (final row in range.values) {
    final cleaned = row.map((v) {
      if (v is String) {
        final t = v.trim().replaceAll(RegExp(r'\s+'), ' ');
        return t.contains('@') ? t.toLowerCase() : t;
      }
      return v;
    }).toList();
    if (cleaned.every((v) => v == null || v == '')) continue;
    final key = Utilities.jsonEncode(cleaned);
    if (seen.add(key)) out.add(cleaned);
  }
  final removed = range.numRows - out.length;
  while (out.length < range.numRows) {
    out.add(List<Object?>.filled(range.numColumns, null));
  }
  range.values = out;
  SpreadsheetApp.active.toast('Removed $removed empty or duplicate rows', title: 'Cleanup');
}
```

### 7.7 Counter with document properties

```dart
import 'package:wonky/wonky.dart';

void countRuns() {
  final props = PropertiesService.documentProperties;
  final n = int.parse(props.getProperty('runs') ?? '0') + 1;
  props.setProperty('runs', '$n');
  SpreadsheetApp.ui.alert('This macro has run $n times.');
}
```

---

## 8. Execution architecture

### 8.1 Where each kind runs

| Invocation | Runtime | Run-as | UI | Time limit | Undo | Op `actorKind` |
|------------|---------|--------|----|------------|------|-----------------------|
| Custom function | client sandbox (pure worker), server for headless reads | n/a (no side effects) | no | 3 s per call, 30 s per recalc batch | — | — |
| Run from editor | client sandbox (UI worker) | current user | yes | 30 s (P1 "Run on server": 6 min) | one step "Script: fn" | `script` |
| Menu item / macro | client sandbox | current user | yes | 30 s | one step | `script` |
| Simple `onOpen` | client, after first render | current user (limited if unauthorized) | yes | 30 s | — (menu building only; writes allowed and undoable) | `script` |
| Simple `onEdit` / `onChange` | client of the editor that made the change | current user | yes (toasts) | 30 s | merged into the triggering step (§8.7.2) | `script` |
| Simple `onSelectionChange` | client | current user | toasts only | 5 s, debounced 300 ms | own step if it writes | `script` |
| Installable time-driven | server worker | installer | no | 6 min | revertible via `changes.revert` | `script` |
| Installable onEdit/onChange/onOpen | server worker | installer | no | 6 min | revertible | `script` |
| MCP `sheets.run_function` | server worker | token user | no | 6 min (or `timeout_s`) | revertible (`change_id`) | `mcp` (label "Script: fn") |
| AI assistant runs a function | server worker | user | no | 6 min | part of the AI undo step | `ai` |
| Macro via MCP UI bridge (`ui.invoke_command sheets.macro.<id>`) | client | user | yes | 30 s | one step | `script` |

### 8.2 Sandbox model

Each execution has a **host** (main isolate / main thread; owns the workbook, writer, UI,
quotas) and a **guest** (isolate or Web Worker; owns the dart_eval `Runtime`). The guest
calls the host through a **synchronous request/response channel**, so the script API can be
synchronous.

#### 8.2.1 `SyncChannel`

```dart
abstract interface class SyncChannel {
  /// Guest side: sends a request and blocks until the host replies.
  Uint8List call(Uint8List request);
  /// Host side: stream of requests with a reply callback.
  Stream<(Uint8List request, void Function(Uint8List reply))> get requests;
}
```

| Platform | Guest | Channel implementation |
|----------|-------|------------------------|
| Desktop (macOS/Windows/Linux) | `Isolate.spawn(guestMain, …)` | `package:native_synchronization` **`Mailbox`** (0.3.1, pinned). The guest sends each call through a `SendPort` (no polling) and blocks in `mailbox.take()`; the host answers asynchronously with `mailbox.put(reply)`. On kill the host closes the mailbox first (a guest blocked in a native wait cannot be interrupted by `Isolate.kill`). Implemented as `IsolateScriptRunner` (`native.dart`). |
| Server | same as desktop, inside a script worker (§8.8) | `Mailbox` |
| Web (first release) | main thread | **Inline runner** (§8.2.3): `InlineScriptRunner`, host answers synchronously, DE-2 checkpoints enforce the time limit. |
| Web (later, cross-origin isolated) | `Worker('script_worker.dart.js')` | `SharedArrayBuffer` ring buffer + `Atomics.wait` in the worker, `Atomics.notify` from the main thread. Not built (decision below). The guest code (`GuestRuntime`, `GuestTransport`) is ready to run in a worker. |

**Decision (2026-10-14): no cross-origin isolation yet; the web keeps the inline runner and
*Run on server* (with live logs) for alerts/prompts/fetch.** Investigation:
- *Google sign-in*: no longer a blocker. The suite's popup flow (`google_popup_web.dart`)
  already survives `COOP: same-origin`: the server callback `/auth/callback` relays the result
  through `localStorage` when the popup has no opener, and the opener polls it.
- *`COEP: require-corp`*: Flutter loads images and fonts with CORS (`fetch`), which satisfies
  COEP, so the app itself works; but every cross-origin no-cors subresource must send
  `Cross-Origin-Resource-Policy` (user avatars from identity providers, any future embeds), and
  cross-origin iframes need COEP themselves. Safe only once all images go through the
  same-origin `/files/` proxy.
- *`COEP: credentialless`*: tolerates no-cors subresources (sent without cookies) and is the
  better fit, but Safari does not implement it — Safari would lose isolation (and the worker)
  while still paying the restrictions. Per-browser headers are possible (user agent sniffing in
  the web server) but fragile.
- Isolation is per document: it can be enabled for `/sheets/` only, leaving `/write/` alone.
- What it needs besides headers: a separate worker entrypoint compiled with `dart compile js`,
  the SAB channel, fallbacks when `crossOriginIsolated` is false (snapshot mode or the inline
  runner), and a cross-browser live check of sign-in, image upload and printing — none of which
  can be verified without the release web build. Snapshot mode alone does not bring alerts,
  prompts or synchronous fetch (§8.2.3a), so it was not built either.
Next step when this is picked up: serve `/sheets/` with `COOP: same-origin` +
`COEP: credentialless` (Chromium/Firefox), keep Safari on the inline runner, and route avatar
images through `/files/`.

Requirements on the web deployment: the Sheets web app is served with
`Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`
(or `credentialless`), and every subresource is same-origin (fonts bundled, images via the
same-origin `/files/` proxy). Flutter's multi-threaded wasm renderer benefits from the same
headers. The script worker is a separate Dart entrypoint
(`wonky_sheets/web_worker/script_worker.dart`) compiled with `dart compile js -O4`
into `web/script_worker.dart.js` by the web build script.

#### 8.2.2 Message protocol (`protocol.dart`)

Binary codec (custom compact tag-length-value; strings UTF-8; numbers float64/int64; 2D
arrays as a typed header + column-major values). Messages:

| Message | Direction | Content |
|---------|-----------|---------|
| `Execute` | host → guest (async, not on SyncChannel) | `executionId, buildHash, bytecode (first time per guest), library, function, args, context {userId, role, scopes, sessionLocale, tz, activeSheetId, activeRange, kind}` |
| `Call` | guest → host (sync) | `callId, target (handle id), method, args` |
| `WriteBatch` | guest → host (sync, ack) | ordered list of `WriteOp`s (set values/formulas/formats/notes for a range, structure ops) |
| `Result` | host → guest | value or error `{code, message}` |
| `Log` | guest → host (async, fire-and-forget via the same channel with no-wait flag) | level, message, timestamp |
| `Done` | guest → host | return value (JSON-able), stats (instructions, bridge calls, cells read/written) |
| `Cancel` | host → guest | (web: worker terminate; native: isolate kill after unblocking the mailbox with a `Cancelled` reply) |

API objects (`Sheet`, `Range`, …) are **handles**: small guest objects holding host-side
identifiers (sheet id + A1 resolved at creation as ids, so a `Range` keeps pointing at the
same cells if rows are inserted during the script, like Apps Script).

#### 8.2.3 Web runtime of the first release: the inline runner

Implemented: `InlineScriptRunner` runs the guest on the calling (main) thread. The host answers
calls synchronously and DE-2 checkpoints (every 10,000 instructions) abort the run at its time
limit (`ExecutionTimeoutException`, not catchable). Consequences: the UI does not repaint while
a script runs (bounded by the limit: 30 s runs, 3 s custom functions); `Ui.alert`/`prompt`
throw `UiUnavailableException` and `UrlFetchApp` throws `ScriptException(unsupported)` with a
hint to use *Run on server*; `Utilities.sleep` busy-waits. Custom functions and menu/macro
writes work as on desktop. The snapshot worker below stays a P1 option.

#### 8.2.3a Snapshot mode (web worker, P1, not built)

When `crossOriginIsolated` is false (embedded contexts, some browsers), synchronous calls are
impossible. The host sends the guest a **read snapshot** of the sheets the script may read
(all sheets ≤ 200k non-empty cells; otherwise the execution is offered as *Run on server*).
Reads are served from the snapshot plus the guest's own pending writes. Writes are batched and
sent asynchronously. `values` of formula cells written during the run are **stale** until the
end (documented). UI calls (`alert`/`prompt`) are not available in snapshot mode
(`UiUnavailableException`). If DE-2 has landed, the runtime can also run on the main thread
with checkpoint-based time slicing as a last resort for custom functions.

#### 8.2.4 Batching and value conversion

- Cell-sized writes (`value`, `formula`, `note`, single-format setters, `setBorder`, `clear`,
  `appendRow`) are buffered guest-side and sent as one `batch` call when any other call
  happens (read-your-writes), on `SpreadsheetApp.flush()`, when the buffer exceeds 10,000
  cells, or when the function returns. Their errors surface on the next call (or fail the
  execution). 2-D writes (`values`, `formulas`, `notes`, `setBackgrounds`…) are sent at once so
  dimension errors throw where they happen. The host applies each batch inside the execution's **single undo
  transaction** (chunked into ≤ 5,000 row changes per DB transaction, as in
  [02-data-model.md](02-data-model.md) §7).
- Before answering a value read after writes, the host runs `recalcIfDirty()` (bounded by the
  formula engine's normal limits) so scripts see computed values.
- 2-D arrays are boxed lazily per row (`_LazyBoxedList`) so reading a 100k-cell range
  doesn't allocate all boxes up front; the bridged-value counter (§10) counts boxes.

#### 8.2.5 Host-side handling
`ScriptHost.handle(Call)` validates the handle, checks scopes (§11) and role
(`PermissionDeniedException` for viewers writing, or for protected ranges unless the user is
in the protection's editors), updates quota counters, executes against `WorkbookAccess`, and
returns. All host work for one call must finish in ≤ 2 s (except UI and fetch). Calls are
processed strictly in order.

### 8.3 `UrlFetchApp` and SSRF protection

All fetches go through the server: the client host forwards `fetch` to
`ScriptEndpoint.urlFetch(spreadsheetUuid, executionId, request)`; server-side executions call
`UrlFetchProxy` directly. Offline → `OfflineException`.

`UrlFetchProxy` rules (also used by image-by-URL and `IMAGE()` proxy, see
[08-charts-and-objects.md](08-charts-and-objects.md) §10):
1. Schemes `https` only (`http` allowed only when `scripts.allowHttp` config is true, default
   false). Ports 443/80/8443 only.
2. Resolve DNS **once**, reject if any resolved address is private, loopback, link-local,
   multicast, CGNAT (100.64/10), unique-local IPv6, IPv4-mapped private, or the metadata
   endpoints (169.254.169.254, `metadata.google.internal`, `fd00:ec2::254`), or the server's own
   hostnames. Connect to the **resolved IP** with SNI/Host set to the name (prevents DNS
   rebinding).
3. Redirects: max 5, each hop re-validated.
4. Request limits: headers ≤ 16 KB, payload ≤ 10 MB. Response limit **10 MB** (download is
   aborted beyond), timeout ≤ 60 s (default 30 s).
5. Allowlist: `ScriptProject.settingsJson.urlAllowlist` (host patterns, `*.example.com`). If
   non-empty, only those hosts are allowed. Admins can set a server-wide denylist/allowlist
   (`config: scripts.urlDenylist`).
6. Headers added: `User-Agent: WonkySheets-Script/1.0 (+https://<host>/scripts-ua)`. Cookies
   are never forwarded. The user's auth token is never forwarded.
7. Quotas (§10) counted per **run-as user**.
8. Custom functions may fetch only if the host is in the project allowlist (a non-empty
   allowlist is required). Responses for custom functions are cached server-side for 1 h keyed by
   (method, url, headers hash).

### 8.4 Client bridge (`ClientScriptHost`)

- Lives in `wonky_sheets/lib/features/scripts/runtime/`.
- Opens an undo transaction **"Script: <functionName>"** (source `script`) when the first write
  arrives; commits when `Done` arrives (or on error/timeout: commits what was applied, then
  shows the error toast "Script error in fn: message — View details · Undo").
- Writes go through the session like any command (`session.execute(op, actorKind: 'script')`),
  producing ops with `actorKind: script` and the same label.
- Structure ops (insert rows, add sheet…) call the same internal operations as the
  corresponding commands (`sheets.rows.insert…`) so maintenance invariants and id generation
  are identical.
- UI calls show `ShadDialog.alert`/prompt dialogs (via `WonkyDialogSpec`, so they're
  MCP-describable), `ShadSonner` toasts, and menus via `ScriptMenuRegistry` (§16).
- Simple triggers and menu actions never run while another execution of the same user and
  spreadsheet is running (queue, max 10 pending; drops the oldest `onSelectionChange` first).

### 8.5 Server bridge (`ServerScriptHost`)

- Uses `HeadlessWorkbook` (shared with MCP tools; the RevLog headless model of the file, which
  follows its ops; see [12-mcp-and-ai.md](12-mcp-and-ai.md) §2). The function runs against a
  private copy of it.
- Writes after the run as RevLog server changes of the **run-as user** (`SheetsBulkWriter` →
  `RevLogService.submitServerChange`, chunked; `actorKind: script`, or `mcp`/`ai` when invoked
  by those, label `"Script: <fn>"`), so the sequencer checks the run-as user's role and the
  protected ranges like any edit (RevLog spec 05 §3.5; only `system` ops, e.g. script builds,
  are exempt). The ops share one record id and one `ServerChangeRecord` per execution, so
  `changes.revert(change_id)` works for 24 h ([12-mcp-and-ai.md](12-mcp-and-ai.md) §2.5). A
  rejected commit fails the execution ("The changes could not be saved").
- `Ui` throws `UiUnavailableException`; `toast` is logged and, if the run-as user has an open
  window, relayed as a toast through the presence channel (P1).
- `activeSheet` = first visible sheet; `activeRange` = A1 of it.
- **Job queue (built)**: installable triggers are enqueued as `ScriptJob` rows
  (`ScriptJobQueue`, `wonky_server/lib/src/sheets/scripts/script_jobs.dart`) and run by
  instances with the worker role (`wonky.sheets.scriptWorker`, default true; instances without
  it only enqueue). Claims are leases (`FOR UPDATE SKIP LOCKED`, lease = server timeout + 2 min),
  serialized across instances by a transaction-scoped advisory lock so the per-user and
  per-trigger limits hold; an expired lease is queued again (3 attempts). At most
  `wonky.sheets.scriptUserConcurrency` (10) running jobs per run-as user and one per trigger; at most 100 queued per trigger, the
  overflow is merged into the newest job (`e.coalesced`, bounding range). Finished jobs are
  pruned after a day (`scriptsPrune`). *Run on server*, MCP `run_function` and AI runs stay
  synchronous request/response (`ScriptEndpoint.run`; `runLive` streams log lines first).
- `LockService` uses process-wide locks (`MemoryScriptLocks.shared`); with several worker
  instances a document lock is per instance (a Redis lock is the follow-up).

### 8.6 Custom functions

Evaluation through the formula engine's **custom function hook**
([05-formula-engine.md](05-formula-engine.md)):

```dart
abstract interface class CustomFunctionProvider {
  /// Known names (from the last good build's exports).
  bool has(String upperName);
  FunctionHelp help(String upperName);
  /// Returns a cached value synchronously, or null and schedules evaluation.
  CustomFunctionResult? lookup(String upperName, List<FormulaValue> args, CellId caller);
}
```

1. During recalculation, the engine calls `lookup`. On a cache hit (key = `buildHash, name,
   argsHash`) it returns the value. On a miss it returns `null`, and the engine stores the
   transient value **`Loading…`** for the cell (a special error-like value `#LOADING`, displayed
   as "Loading…" in muted italic; dependents see `#LOADING` and also wait).
2. Misses collected during one recalc pass are sent as **one batch** to the pure worker
   (`evaluateBatch([{callId, name, args}])`, ≤ 500 calls per message). The worker runs them
   sequentially, each with a 3 s budget.
3. Results arrive → cache (in-memory LRU 50k entries + `ComputedValueCache` persistence for
   reopen) → the engine marks the calling cells dirty → normal recalculation.
4. Args conversion: single cell → scalar; range → `List<List<Object?>>` (row-major, empty cells
   `null`); errors in args are passed as `CellError`. Return conversion: scalar → value;
   `List<List>` → array result that **spills** like array formulas; `List` (1D) → a single row;
   unsupported return types → `#VALUE!` with message.
5. Side effects are forbidden: the pure worker's host rejects every mutating call, UI call
   and property write with `CustomFunctionSideEffectException` (cell shows `#ERROR!` with
   tooltip). Reading the spreadsheet through the API is also **forbidden** (all inputs must be
   arguments; this keeps the dependency graph correct). `Utilities`, `Session.scriptTimeZone`
   and allowlisted `UrlFetchApp` are allowed.
6. Determinism: results are cached by args. Volatile behavior (`DateTime.now()`,
   `Random`) is allowed but only re-evaluated when args change, on *Recalculate all*
   (`sheets.calc.recalculateAll`), or after a new build.
7. Errors: thrown exceptions → `#ERROR!` with the message in the cell's error tooltip;
   timeouts → `#ERROR!` "Exceeded maximum execution time (3 s)"; no build/compile errors →
   `#NAME?` "Unknown function" only if the name never existed in a good build.
8. Offline: works with the last downloaded good build. If no build was ever downloaded,
   `#LOADING` stays until online.
9. Headless (MCP reads, server-side scripts, exports): the server's formula engine uses the
   same provider backed by a server pure worker; MCP reads wait up to 10 s for loading cells
   and then return `#LOADING` with `pending: true`.
10. Viewers' and commenters' clients evaluate custom functions too (they're part of rendering).

### 8.7 Triggers

#### 8.7.1 Simple triggers (client)

| Trigger | Fires when | Event | Notes |
|---------|-----------|-------|-------|
| `onOpen` | spreadsheet finished first render for this window, and again after a new build arrives (menus rebuilt) | `OpenEvent` | Runs for all roles; viewers get read-only access (writes throw). |
| `onEdit` | a local undo transaction with `kinds ∋ values` committed by a **user-initiated** command (menu, toolbar, shortcut, context menu, palette, cell editor, paste, fill, AI with live UI) | `EditEvent` (range = bounding box of changed cells on the first changed sheet) | Not fired for: script writes, remote changes, undo/redo, MCP UI-bridge commands (configurable P2). |
| `onChange` | local transaction with structure/format/sheet changes | `ChangeEvent` | P1 (installable `onChange` is the Apps Script equivalent; we also offer it as simple). |
| `onSelectionChange` | active cell/range changed, debounced 300 ms | `SelectionChangeEvent` | Only runs if the function exists; max 1 concurrent; skipped while the user drags. |

Simple triggers run in `AuthMode.limited` if the user has not authorized the project's
scopes: calls needing scopes (`UrlFetchApp`, `Session.activeUser.email`, `ScriptApp`) throw
`ScopeNotGrantedException`. They never show the authorization dialog.

#### 8.7.2 Undo integration for `onEdit`
If `onEdit` completes within **2 s** and the user hasn't started another undoable action, its
writes are **appended to the triggering undo step** (so one Mod+Z undoes the edit and the
timestamp). Otherwise they form their own step "Script: onEdit".

#### 8.7.3 Installable triggers (server)

- Created in the Triggers dialog (§14.6) or via `ScriptApp.newTrigger`. Stored as
  `ScriptTrigger` rows (`runAsUserId` = creator). Server state (next run, failures) lives in
  the server-only `ScriptTriggerState` table.
- Time-driven triggers are read from the `script_trigger` table (plain reads by file); changes
  to them reach the server as ops like any other edit.
- **Time-driven**: `ScriptScheduler` FutureCall `sheets.scripts.tick` every minute selects due
  triggers (`nextRunAt ≤ now`, `FOR UPDATE SKIP LOCKED`), enqueues `ScriptJob`s, computes the
  next run in the project time zone (with ±15 min deterministic jitter per trigger id for
  `atHour`).
- **Installable onEdit/onChange**: the `scripts` post-commit hook (suite 17 part 5 §6.2) enqueues
  one job per op whose `actorKind ∈ {user, ai}` (and `mcp` if the trigger option `fireForMcp` is set; never
  `script`). Per trigger, at most 100 jobs queued; overflow is coalesced into one job with
  `e.coalesced = true` and the bounding range. Offline edits fire when they sync, with
  `e.offline = true` (the op's `offline` flag).
- **Installable onOpen** (P1): the client calls `ScriptEndpoint.notifyOpen(spreadsheetUuid)`
  after opening online; the server enqueues the jobs.
- Run-as checks before each run: installer still has **edit** access (via `AccessService`),
  is not deleted, has scripts enabled, and is within quota. Otherwise the trigger is
  disabled (`ScriptTriggerState.disabledReason`), and the installer gets a
  `scriptFailure` notification ("Trigger dailySummary was disabled because you no longer have
  edit access to Budget 2026").
- Failure policy: 5 consecutive failures → disabled + notification; failure notifications are
  digested daily (P1 setting per trigger: immediately / daily / never).
- One execution per trigger at a time; a time-driven run that is still running when the next
  is due is skipped (logged as `skipped`).

### 8.8 Runtime pools and lifecycle

**Client:**
- Two guests per open spreadsheet, created lazily: **pure guest** (custom functions; warm;
  holds the current build's `Runtime`) and **UI guest** (everything else). A third guest is
  spawned if a run is queued while the UI guest is busy beyond 5 s (max 3).
- `Runtime` instantiation per build: the guest caches runtimes by `buildHash` (max 2). Bytecode
  is downloaded from the signed URL and stored in `LocalBlobCache` keyed by
  `bytecodeFileUuid`.
- On timeout: the host replies `Cancelled` to any pending call, kills the guest
  (`Isolate.kill(priority: immediate)` / `worker.terminate()`), records `timedOut`, and spawns
  a fresh guest on demand.

**Server:**
- Script execution happens in **script workers**: the same server binary started with
  `sheets.scripts.worker: true` (production: dedicated instances/containers with memory limits;
  development: in-process). Jobs come from the Postgres `ScriptJob` queue (lease 7 min,
  `SKIP LOCKED`). MCP `run_function` waits for job completion via `session.messages` channel
  `scriptjob:<id>`.
- Each worker keeps an isolate pool (default 8 guests, config `scripts.poolSize`). Guests are
  recycled after 200 executions or any timeout. A watchdog checks
  `ProcessInfo.currentRss` every second; above `scripts.maxWorkerRssMb` (default 1,536) it
  cancels the execution with the highest bridged-value count (`QuotaExceededException:
  memory`).

---

## 9. Compilation (server)

### 9.1 Flow

1. **Trigger**: the editor saves files (ops) and, when online, waits until they are
   acknowledged (`session.whenSynced`, 10 s) and calls `ScriptEndpoint.compile(spreadsheetUuid)`.
   The server also compiles when the `scripts` hook sees `kinds ∋ scripts` for file changes
   without a matching build (Editor+ authors; covers offline saves that synced later and MCP
   updates). The build row is written as a `system` server change (`script_build` is not
   client-writable).
2. Load all `ScriptFile` rows of the project (admin read), compute
   `sourceHash = sha256(apiVersion ‖ compilerVersion ‖ sorted(name ‖ \0 ‖ source))`. If
   `ScriptBuild.sourceHash == sourceHash` → done.
3. Compile in a dedicated **compiler isolate** (analyzer is memory-hungry; pool of 2 per
   server, 60 s timeout, queue per project with "latest wins" coalescing):
   1. Parse + resolve with `analyzer` against an in-memory resource provider containing the
      project files and a **stub** of `package:wonky/wonky.dart` (generated from `api.dart`).
      Collect errors and warnings.
   2. **Subset lint** (§9.3).
   3. Generate `package:script/__exports.dart` that imports every file and references every
      exported function (prevents dart_eval tree shaking), then
      `Compiler()..addPlugin(WonkyScriptPlugin())` → `compile({'script': files, ...})` →
      `program.write()`.
   4. Extract exports metadata from the AST (§5.1) and required scopes (§11.1).
4. Upload bytecode as a `StoredFile` (owner = the spreadsheet's DriveItem; content-addressed
   name `scripts/<projectId>/<sourceHash>.evc`).
5. Write the `ScriptBuild` row (deterministic id `SheetsIds.scriptBuildId(projectId)`) in
   a `system` server change (`submitServerChange`, attributed to the requesting user): on success set `bytecodeFileUuid`, `lastGood*` fields;
   on errors keep `lastGood*` untouched and set `bytecodeFileUuid = null` (Additions A-09-1).
6. Return diagnostics to the caller of `compile` directly (fast path) in addition to the build row.

### 9.2 Diagnostics format (`diagnosticsJson`)

```jsonc
[ { "severity": "error",              // error | warning | info
    "code": "unsupported_extension",  // analyzer code or wonky_* lint code
    "message": "Extension methods are not supported in Wonky scripts.",
    "file": "main.dart", "line": 14, "column": 1, "endLine": 18, "endColumn": 2,
    "fix": "Use a top-level function instead." } ]
```

### 9.3 Subset lint (`wonky_*` codes)

| Code | Construct |
|------|-----------|
| `wonky_mixin` | `mixin`, `with` |
| `wonky_extension` | `extension` declarations |
| `wonky_late` | `late` |
| `wonky_typedef` | `typedef` |
| `wonky_generator` | `sync*`, `async*`, `yield` |
| `wonky_await_for` | `await for` |
| `wonky_switch_expression` | switch expressions |
| `wonky_import` | disallowed imports, conditional/deferred imports |
| `wonky_isolate` | `dart:isolate` |
| `wonky_records_patterns` (warning) | records/patterns beyond the supported subset |
| `wonky_top_level_state` (warning) | mutable top-level variables (state doesn't persist between executions) |
| `wonky_custom_function_signature` | custom function with non-`Object?` params or async |
| `wonky_builtin_shadowed` (warning) | custom function name equals a built-in |

### 9.4 Offline and stale builds

- Editing and saving work offline (file saves are ops in the outbox). The editor status shows **"Will
  compile when online"** and the problems panel keeps the last known diagnostics marked
  "outdated".
- Custom functions, menus and triggers always use the **last good build** (`lastGood*`), even
  if the latest source has errors. The editor shows a banner "Running the last working version
  (2 min ago) — fix errors to update".
- `apiVersion` bump: clients that receive a build with a newer `apiVersion` than they support
  show "Update the app to run this script" and fall back to no script features.

### 9.5 Live analysis (P1)
`ScriptEndpoint.analyze(spreadsheetUuid, fileName, source)` → diagnostics for unsaved editor
content (no bytecode, no storage). Debounced 1.5 s in the editor, rate-limited 30/min per user.

---

## 10. Limits and quotas

| Limit | Value (config key under `sheets.scripts.*`) |
|-------|----------------------------------------------|
| Execution time: client run/menu/macro/simple trigger | 30 s (`clientTimeoutMs`) |
| Execution time: `onSelectionChange` | 5 s |
| Execution time: custom function call | 3 s; 30 s per recalc batch |
| Execution time: server (triggers, MCP, Run on server) | 6 min (`serverTimeoutMs`) |
| UI wait (alert/prompt) | excluded from time limit, max 5 min each |
| Daily server runtime per user | 90 min (`dailyServerRuntimeMs`) |
| Daily client runtime per user (reported, soft) | 6 h (warn only) |
| URL fetch calls per user per day | 20,000; response ≤ 10 MB; daily fetched bytes ≤ 500 MB |
| Installable triggers per user per spreadsheet / total | 20 / 200 |
| Concurrent server executions per user | 10 (more are queued) |
| Bridge cells read / written per execution | 10,000,000 / 2,000,000 (approximates memory) |
| Live bridged values in guest (boxed handles + lazy rows materialized) | 5,000,000 |
| Logs per execution | 100 KB (truncated with notice) |
| Properties | 9 KB per value, 500 KB per store |
| Files / file size / project size | 50 / 500 KB / 2 MB |
| Compile | 60 s, 20 compiles per project per hour |

Quota usage is recorded in `ScriptQuotaUsage` (server) per user per day. Client executions
report their runtime in batches (`ScriptEndpoint.reportExecutions`); client-side limits are
enforced locally (and are advisory, since a modified client can bypass them). Server limits
are enforced strictly. Quota errors surface as `QuotaExceededException` with the quota name
and reset time (UTC midnight).

---

## 11. Permissions and authorization

### 11.1 Scopes

| Scope | Granted by | Allows |
|-------|-----------|--------|
| `spreadsheet.current` | implicit | read/write the bound spreadsheet within the user's role |
| `ui` | implicit | alerts, prompts, toasts, menus, sidebars |
| `user.email` | authorization dialog | `Session.activeUser.email` |
| `external_request` | authorization dialog | `UrlFetchApp` |
| `script.triggers` | authorization dialog | `ScriptApp` (install/delete triggers) |
| `drive.readonly` / `drive` | authorization dialog (P2) | `DriveApp` over files the user can access |

Required scopes are detected statically by the compiler (references to API members are mapped
to scopes in `api_index.json`) and listed in `exportsJson.scopes`.

### 11.2 Authorization flow
- The first time a user runs a function (editor, menu, macro, MCP) and the build's scopes
  exceed the user's grant for this spreadsheet, the **Authorization dialog** appears:
  "<Project name> wants to: • Connect to external services • See your email address • Run
  when you're not present (triggers)". Buttons *Allow* / *Cancel*. The function runs after
  *Allow*.
- Grants are stored server-side in `ScriptAuthorization` (user, spreadsheet, scopes, grantedAt)
  and cached on the client (offline runs use the cached grant; server-mediated actions like
  fetch are checked server-side anyway).
- A new build with **additional** scopes requires re-authorization on next run. Simple
  triggers run limited until then (§8.7.1).
- *Extensions › Script settings › Revoke my authorization* removes the grant and disables the
  user's installable triggers for this spreadsheet.
- MCP `sheets.run_function` requires the token scope `scripts:run` **and** an existing
  authorization covering the build's scopes; otherwise it fails with
  `authorization_required` (the user must authorize once in the app). This prevents agents
  from silently granting network access.

### 11.3 Roles

| Action | Viewer | Commenter | Editor | Owner |
|--------|--------|-----------|--------|-------|
| Custom functions evaluated in their client | ✓ | ✓ | ✓ | ✓ |
| `onOpen`/menus shown | ✓ (writes fail) | ✓ (writes fail) | ✓ | ✓ |
| Run functions/macros that write | — | — | ✓ | ✓ |
| Open script editor | read-only, if "viewers can download/copy" is on | same | ✓ | ✓ |
| Edit files, triggers (own), macros | — | — | ✓ | ✓ |
| Delete other users' triggers | — | — | — | ✓ |
| Executions panel | own runs | own runs | all runs | all runs |

Users can disable scripts for themselves (Settings › Sheets › *Enable scripts*): then no
script code runs in their client (custom functions show `#LOADING`→`#ERROR!` "Scripts are
disabled") and their installable triggers pause. Admins can disable scripts server-wide
(`sheets.scripts.enabled: false`).

---

## 12. Security

- **Sandbox**: dart_eval runtime with no granted built-in permissions; only the
  `WonkyScriptPlugin` and the safe stdlib subset (`dart:core`, `dart:math`, `dart:convert`,
  `dart:collection`, `dart:async` futures) are registered. `dart:io`, `dart:isolate`,
  `dart:ffi`, `dart:html`, `dart:js_interop` are not registered at all (compile error).
- **Process isolation**: guests run in isolates/workers with no access to the host's objects
  except through the channel; handles are opaque ids validated by the host.
- **Server**: script workers run in separate containers in production, with a container memory
  cap, no outbound network except through the `UrlFetchProxy` egress (network policy), and no
  access to secrets beyond DB/storage credentials of the worker role. The DB role used by
  workers can only write the file tables through server changes (`submitServerChange`).
- **Run-as integrity**: server executions use the run-as user's `AccessService` role at
  execution time; protected ranges are enforced by the script host's guard and, authoritatively,
  by the RevLog sequencer on the run-as user's ops (RevLog spec 05 §3.5).
- **SSRF**: §8.3.
- **Denial of service**: time limits, kill, quotas, queue caps, compile rate limits.
- **Data exfiltration** by a malicious collaborator's script: scripts run with the *runner's*
  permissions (like Apps Script). The authorization dialog makes network access explicit.
  Custom functions (which run for everyone silently) cannot use network unless the project has
  an explicit allowlist, and the allowlist change itself is shown in the Executions/Activity
  log ("Anna changed the script URL allowlist").
- **Escape tests**: §21.3.

---

## 13. Errors, logs and executions

### 13.1 `ScriptExecution` (server Postgres)

```yaml
class: ScriptExecution
table: script_execution
fields:
  uuid: UuidValue, defaultPersist=random_v7
  spreadsheetUuid: UuidValue
  projectId: UuidValue
  functionName: String
  kind: ScriptExecutionKind        # editor, menu, macro, customFunction, onOpen, onEdit, onSelectionChange,
                                   # onChange, timeDriven, installableOnEdit, installableOnChange,
                                   # installableOnOpen, mcp, ai
  triggerId: UuidValue?
  userId: int                      # initiator (UserProfile id)
  runAsUserId: int
  runtime: ScriptRuntimeKind       # clientWeb, clientDesktop, server
  status: ScriptExecutionStatus    # queued, running, completed, failed, timedOut, cancelled, quotaExceeded, skipped
  buildSourceHash: String
  startedAt: DateTime
  durationMs: int
  logs: String                     # ≤ 100 KB, JSON lines {t, level, msg}
  errorMessage: String?
  errorStackJson: String?          # mapped frames [{function, file, line, column}]
  changeId: UuidValue?             # ServerChangeRecord for revert (server runs)
  cellsRead: int
  cellsWritten: int
  fetchCalls: int
  callCount: int, default=1        # custom functions: one row per recalc batch
indexes:
  script_exec_sheet_idx: { fields: spreadsheetUuid, startedAt }
  script_exec_user_idx: { fields: userId, startedAt }
```

Retention: 30 days, max 10,000 rows per spreadsheet (oldest pruned daily). Client executions
are uploaded best-effort (batched every 10 s or on route exit; queued offline in
`LocalScriptExecutionLog`, max 1,000 rows).

### 13.2 Stack traces
With patch DE-1, frames carry the library and source offset of their **declaration**; the
host maps them to `(file, line, column)` with `exportsJson.lineStarts` (no separate positions
file; `ScriptBuild.positionsFileUuid` stays null). Frames are function-level: the line is the
declaration line of each function on the stack. The error card shows: exception type, message, top frame as a link
(opens the file at the line in the editor), "Show full trace".

### 13.3 Executions panel
In the script editor (bottom tab **Executions**) and as a side panel in the spreadsheet
(*Extensions › Executions*): `ShadTable` with columns Function, Type (trigger kind badge),
Started, Duration, Status (badge colors: success/warning/destructive), User; filters (status,
type, function, "only mine"), live updates while open (`ScriptEndpoint.watchExecutions`).
Row → detail sheet with logs (monospace, level colors), error card, stats (cells read/written,
fetch calls), *Revert changes* (server runs, 24 h, Editors+), *Open in editor*.

---

## 14. Script editor

### 14.1 Route and layout
Full-screen in-app route **`/s/:uuid/script`** (suite routing table). Back arrow returns to
`/s/:uuid` keeping the grid state. The editor shares the spreadsheet's session (same file and
outbox), so it works offline.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ ← Budget 2026 · Script  [Budget script ✎]     ● Saved · Built 10:42 ✓   (avatars) ⋯ │ title row
├─────────────────────────────────────────────────────────────────────────────────────┤
│ [💾 Save ⌘S] [▶ Run ▾ highlightNegatives] [⏱ Triggers] [📋 Executions] [⚙ Settings] │ toolbar
│                                                   [✨ Generate] [?] [Find ⌘F]      │
├──────────────┬──────────────────────────────────────────────────────────────────────┤
│ Files      + │ main.dart ×  utils.dart ●×                                          │ tabs
│ ▸ main.dart  │  1  import 'package:wonky/wonky.dart';                               │
│   utils.dart │  2                                                                   │
│   macros.dart│  3  /// @customfunction                                              │
│              │  4  Object? TO_F(Object? c) { … }                                    │
│ Functions    │     ~~~~ warning squiggle                                            │
│  ƒ TO_F  fx  │                                                                      │
│  ƒ onOpen ⚡ │                                                                      │
│  ƒ archive   │                                                                      │
├──────────────┴──────────────────────────────────────────────────────────────────────┤
│ [Problems 2] [Log] [Executions]                                         ▾ collapse  │ bottom panel
│ ⚠ main.dart:4:1  Custom function names should be upper case.  (wonky_naming)        │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

- Left rail (`WonkyTreeView`): **Files** (create, rename inline, delete, drag to reorder; ●
  marks unsaved), **Functions** (from the last build's exports plus a local scan; icons for
  custom function `fx`, trigger ⚡, macro ⌨; click → jump to declaration).
- Editor tabs: multiple open files; middle-click/× closes; unsaved dot.
- Bottom panel (`ShadTabs`, resizable): **Problems** (diagnostics; click → navigate),
  **Log** (live output of runs started in this window; clear; filter by level), **Executions**
  (§13.3).
- Narrow widths (< 900 px): the file rail collapses into a dropdown, and the bottom panel
  becomes a sheet.

### 14.2 Code editor component
**Decision: `re_editor` 0.10.0** (MIT, reqable.com, published 2026; optimized for large texts;
not based on `TextField`; line numbers, folding, `CodeAutocomplete` hooks, custom find panel
builder, desktop shortcuts, web support; syntax highlighting via `re_highlight`, which includes a
Dart grammar).
Rejected: `flutter_code_editor` 0.3.5 (last release ~12 months ago, `TextField`-based, slow
on large files), `flutter_monaco` (WebView/iframe, breaks single-window/offline/theming),
`code_forge` (Rust backend, native-only concerns on web).
Fallback if `re_editor` is abandoned: fork it into `third_party/` (MIT).

Integration (`wonky_sheets/lib/features/scripts/editor/`):
- `ScriptCodeTheme.light/dark` maps `re_highlight` token classes to `wonky_ui` tokens
  (keywords → `primary`, strings → `success`, comments → `mutedForeground`, numbers → `info`,
  types → `chart3`…). Background `card`, gutter `muted`, selection `selection`, current line
  `accent` at 40 %. Font GeistMono 13 px, line height 1.5. Follows app theme live.
- Find/replace panel built with shad inputs (`findBuilder`): regex, case, whole word.
- Shortcuts (editor scope `scriptEditor`): Mod+S save, Mod+Enter run selected function,
  Mod+/ toggle comment, Mod+F find, Mod+H replace, Mod+D add next occurrence (P2), Tab/Shift+Tab
  indent, Alt+↑/↓ move line, Mod+Shift+K delete line, F8 next problem, Mod+P quick open file.
- Gutter: error/warning markers; hover shows the message.

### 14.3 Saving, concurrency and undo
- **Save** (`sheets.script.saveFile`, Mod+S; *Save all* Mod+Alt+S) writes `ScriptFile.source`,
  `contentHash`, `updatedBy`, `updatedAt` through the session. Saving is **not** an undo step on
  the spreadsheet stack: text undo/redo is editor-local (`re_editor` history, kept across saves
  for the session). Unsaved drafts are persisted every 2 s so a reload or crash loses nothing
  (built in the device's script store `sheets_scripts_<user>.db`, table `local_script_draft`,
  next to the bytecode cache and the local history; drafts can be large, so they are not in
  the small `LocalViewState` JSON).
- File create/rename/delete/reorder are commands and **are** undo steps on the spreadsheet
  stack (labels "Create script file", "Delete main.dart"…), restoring source on undo.
- After save: if online, call `compile`; the title row shows "Building…" → "Built 10:42 ✓" or
  "Build failed (3 errors)". Offline: "Saved on this device · Will compile when online".
- **Concurrent edits (LWW per file)**: the editor remembers `baseHash` (content hash at load
  or last save). On save, inside the write transaction it re-reads the row: if
  `contentHash ≠ baseHash` and `updatedBy ≠ me`, the save is paused and a **conflict dialog**
  appears: "Bo saved a newer version of utils.dart 3 minutes ago." Actions: *Compare* (opens a
  side-by-side diff view; line diff via Myers in `wonky_core/lib/diff/`), *Merge* (3-way merge
  with the local base; non-overlapping hunks auto-merge, overlapping hunks inserted with
  `<<<<<<< yours / ======= / >>>>>>> theirs` markers and the problems panel lists them),
  *Overwrite with mine*, *Discard mine*. Offline saves that later sync may still overwrite
  each other (LWW); the losing text is recoverable from the file's **local history** (last 20
  saved versions per file kept in `LocalScriptHistory`, P1) and from spreadsheet version history.
- Remote update to an open file: not dirty → reload silently with a toast "utils.dart was
  updated by Bo"; dirty → banner "A newer version is available — Compare · Reload".
- Presence: avatars in the title row show who is in the script editor; the file tab shows a
  colored dot for files others have open (presence cursor `{route: script, file}`).

### 14.4 Autocomplete and help
- Source: `api_index.json` (generated by `tool/gen_api_index.dart` in `wonky_sheets_script`
  from `api.dart` doc comments: classes, members, signatures, docs, scopes) + project symbols
  (exports metadata + a lightweight local scan of top-level declarations and local variables
  with explicit types).
- Member completion after `.` uses a small type inference over the expression chain using
  API return types (`SpreadsheetApp.active.` → `Spreadsheet` members; `final s =
  ss.sheetByName('x')!;` → `Sheet`). Unknown receivers fall back to all identifiers.
- Popup built with shad styling (via `CodeAutocomplete` builder): icon by kind, signature,
  first doc line; Enter/Tab accepts, Esc closes. Signature help (P1) and hover docs (P1).
- *Help › Script API reference* opens an in-app docs route rendered from the same index.

### 14.5 Run
`Run ▾`: split button. Main part runs the selected function; the chevron opens a picker of
runnable functions (no required params) with search. Runs use the client runtime; P1 adds
*Run on server* (enqueues a server job, streams logs back). While running, the button turns
into *Stop* (`sheets.script.stop`). Unsaved changes: run asks "Save and run?" (needs a
successful build; offline uses the last good build with a warning).

### 14.6 Triggers dialog
Lists the user's installable triggers (owner sees all: column "Owner"): Function, Event
(time-driven/edit/change/open), Schedule summary, Last run (status), Enabled switch, ⋮
(Edit, Delete, View executions). *Add trigger* form (`WonkyDialogSpec`): function select,
event source (Time-driven / From spreadsheet), event type, schedule fields (type: minutes /
hourly / daily / weekly / monthly / specific date; interval; time-of-day window; weekday;
day), failure notifications (immediately / daily / never), *Fire for agent (MCP) edits*
checkbox for edit triggers. Saving requires scope `script.triggers` (authorization dialog).

### 14.7 Project settings
Name, time zone (defaults to spreadsheet), URL allowlist (chips input), "Show script menus in
menubar" toggle, API version (read-only), build info (hash, time, size), *Revoke my
authorization*, *Delete project* (Owner; confirm; deletes files, triggers, macros).

---

## 15. Macro recorder (P1)

1. *Extensions › Macros › Record macro* (`sheets.macro.record`) shows a floating
   **recording bar** at the bottom center: "● Recording new macro…", segmented control
   **Use absolute references** / **Use relative references**, *Save*, *Cancel*.
2. While recording, the `MacroRecorder` listens to `CommandDispatcher` `CommandInvoked` events
   with sources `menu`, `toolbar`, `shortcut`, `contextMenu`, `palette`, plus cell-editor
   commits and paste/fill. Each recordable command implements an optional
   `ScriptCodegen`:

```dart
abstract interface class ScriptCodegen {
  /// Returns Dart statements reproducing the command, or null if not recordable.
  List<String>? toScript(CommandArgs args, MacroContext ctx);
}
class MacroContext {
  final MacroReferenceMode mode;          // absolute | relative
  final GridSelection selectionBefore;    // ranges as A1 + sheet name
  final GridSelection selectionAfter;
  String rangeExpr(GridRange r);          // absolute: sheet.getRange('B2:C5'); relative: active.offset(…)
}
```

3. Non-recordable commands insert a comment `// Not recorded: Insert chart`.
4. *Save* → dialog: Name (default "Macro 1"), Shortcut (optional `Mod+Alt+Shift+0..9`, shows
   conflicts with other macros). The recorder appends a function to `macros.dart` (created if
   missing), creates a `Macro` row (`functionName`, `shortcutSlot`), saves the file and
   compiles. One undo step "Record macro" (file change + macro row).

Generated code example (relative mode):

```dart
/// Macro "Format header" (recorded 2026-10-12).
void formatHeader() {
  final sheet = SpreadsheetApp.activeSheet;
  final active = SpreadsheetApp.activeRange;
  active.offset(0, 0, 1, 5).fontWeight = 'bold';
  active.offset(0, 0, 1, 5).background = '#D9EAD3';
  sheet.frozenRows = 1;
}
```

Macros: *Extensions › Macros ▸* lists macros (with shortcuts), *Manage macros* (dialog: rename,
change shortcut, edit script, remove), *Import macro* (choose an exported runnable function).
Each macro registers the dynamic command **`sheets.macro.m<macroId>`** (the UUID's 32 hex digits, since command id segments are identifiers) when the spreadsheet loads
or the macro set changes (suite 08 §1.1), with title = macro name and key binding from
`shortcutSlot`. Macros run on the client; via MCP headless they run on the server with
`sheets.run_function`.

Shortcut note: `Mod+Alt+Shift+0…9` are reserved for macros in the `grid` scope (Google Sheets
parity). This conflicts with the suite design system's `Mod+Alt+Shift+{n}` panel cycling
([02-design-system.md](../02-design-system.md) §4.5); in Sheets the grid scope wins
(more specific scope), and panel cycling stays available from other scopes. See
[13-implementation-plan.md](13-implementation-plan.md) §9.

---

## 16. Custom menus and script UI

### 16.1 Menus
- `Menu.addToUi()` sends the menu tree to the host, which registers it in `ScriptMenuRegistry`
  for this window (per-session; rebuilt on every `onOpen` run and after new builds).
- Placement: each menu appears as a **top-level menubar item** after *Extensions* (Google
  Sheets behavior) when "Show script menus in menubar" is on; always also listed under
  *Extensions ▸ <menu caption>*. Max 10 top-level script menus, 50 items each, depth 3.
- Items invoke the stable command **`sheets.script.runMenuItem`** with args
  `{functionName, caption}`; they appear in the command palette as "<Menu> › <Item>" and in
  `ui.get_menu_tree`.

### 16.2 Alerts, prompts, toasts
- `alert`/`prompt` → `WonkyFormDialog` built from a `WonkyDialogSpec` (title, message, text
  field for prompt, buttons per `ButtonSet`); MCP-operable via `ui.get_dialog`/`ui.fill_dialog`.
- `toast` → `ShadSonner` toast bottom-right with title, message, close; timeout per argument
  (−1 = until closed).

### 16.3 Sidebars and dialogs (P2) — declarative UI DSL

```dart
final panel = UiPanel(title: 'Import', children: [
  UiText('Choose a source'),
  UiSelect(id: 'source', options: ['CRM', 'Shop'], value: 'CRM'),
  UiTextField(id: 'from', label: 'From date', type: 'date'),
  UiCheckbox(id: 'clear', label: 'Clear sheet first'),
  UiRow(children: [UiButton('Import', onClick: 'runImport', primary: true), UiButton('Close', onClick: '_close')]),
]);
SpreadsheetApp.ui.showSidebar(panel);

/// Called with the current form values.
void runImport(UiEvent e) { final source = e.values['source']; … e.panel.update(...); }
```

Components: `UiText` (Markdown subset), `UiTextField`, `UiTextarea`, `UiSelect`,
`UiCheckbox`, `UiRadioGroup`, `UiButton`, `UiRow`, `UiColumn`, `UiDivider`, `UiTable`
(read-only), `UiProgress`, `UiImage` (wonky-file or https via proxy). Rendered with shad widgets in
the side panel host (`WonkySplitView` panel id `scriptSidebar`) or a `ShadDialog`. Event
callbacks start a new execution of the named function with `UiEvent {values, panel}`. No HTML,
no arbitrary widgets, no script-controlled styling beyond `primary`/`destructive` variants.

Built (2026-10-14): `Ui.showSidebar(panel)`, `Ui.showModalDialog(panel, title)`, components
`UiText` (bold/italic/code), `UiTextField` (`type` text/number/date/email), `UiTextarea`,
`UiSelect`, `UiCheckbox`, `UiRadioGroup`, `UiButton` (`onClick` = exported function or
`_close`), `UiRow` (wraps), `UiColumn`, `UiDivider`, `UiTable` (≤ 500 rows), `UiProgress`;
`UiEvent {values, panel, button}` with `panel.update(UiPanel)` / `panel.close()`. The host
validates panels (`ScriptPanelSchema`: ≤ 300 components, depth 6, button targets).
Sidebars are the side panel `sheets.panel.scriptSidebar`, dialogs a `ShadDialog`; both are
MCP-operable (fields = inputs, buttons by caption). Button runs are `menu` executions (one undo
step "Script: fn"). Not built: `UiImage`.

---

## 17. Commands

| Command id | Args | Undoable | Role |
|------------|------|----------|------|
| `sheets.script.openEditor` | `{file?, line?}` | — | Viewer+ (read-only for non-editors) |
| `sheets.script.closeEditor` | — | — | |
| `sheets.script.newFile` | `{name}` | ✓ | Editor |
| `sheets.script.renameFile` | `{fileId, name}` | ✓ | Editor |
| `sheets.script.deleteFile` | `{fileId}` | ✓ | Editor |
| `sheets.script.reorderFile` | `{fileId, index}` | ✓ | Editor |
| `sheets.script.saveFile` / `saveAll` | `{fileId?}` | — (not on stack) | Editor |
| `sheets.script.compile` | — | — | Editor |
| `sheets.script.run` | `{functionName, onServer?}` | ✓ ("Script: fn") | Editor |
| `sheets.script.stop` | `{executionId?}` | — | |
| `sheets.script.runMenuItem` | `{functionName, caption}` | ✓ | Viewer+ (writes need Editor) |
| `sheets.script.openTriggers` / `addTrigger` / `updateTrigger` / `deleteTrigger` | trigger fields | add/update/delete ✓ | Editor |
| `sheets.script.openExecutions` | `{filter?}` | — | Viewer+ |
| `sheets.script.revertExecution` | `{executionId}` | ✓ | Editor |
| `sheets.script.openSettings` / `updateSettings` | settings patch | ✓ | Editor |
| `sheets.script.authorize` / `revokeAuthorization` | — | — | Viewer+ |
| `sheets.script.generateWithAi` / `explainWithAi` / `fixErrorWithAi` | `{prompt?, fileId?, diagnosticIndex?}` | via AI step | Editor |
| `sheets.macro.record` / `saveRecording` / `cancelRecording` | `{mode}` / `{name, shortcutSlot?}` | save ✓ | Editor |
| `sheets.macro.import` | `{functionName, name, shortcutSlot?}` | ✓ | Editor |
| `sheets.macro.manage` | — | — | Editor |
| `sheets.macro.update` / `delete` | `{macroId, …}` | ✓ | Editor |
| `sheets.macro.<macroId>` (dynamic) | — | ✓ | Editor |
| `sheets.help.scriptApiReference` | `{class?}` | — | Viewer+ (headless: lists the classes) |

---

## 18. MCP tools

Headless (server; namespace `sheets.*`, token scopes in parentheses). Schemas follow suite
[09-mcp.md](../09-mcp.md) conventions; listed in [12-mcp-and-ai.md](12-mcp-and-ai.md) §3.12.

| Tool | Input | Output |
|------|-------|--------|
| `sheets.list_script_functions` (`sheets:read`) | `spreadsheet` (uuid) | `{build: {sourceHash, builtAt, status, errors}, functions: [{name, params, doc, kind: runnable\|customFunction\|trigger\|macro, macro?: {name, shortcut}}], triggers: […]}` |
| `sheets.run_function` (`scripts:run` + `sheets:edit` for writes) | `spreadsheet, function, args?: JSON[], timeout_s? (≤ 360)` | `{status, result (JSON), logs, error?: {message, stack}, change_id?, execution_id, cells_written}` |
| `sheets.get_script_files` (`sheets:read`) | `spreadsheet, names?` | `{files: [{name, source, content_hash, updated_by, updated_at}]}` |
| `sheets.update_script_file` (`sheets:edit` + `scripts:run`) | `spreadsheet, name, source, base_hash?, create_if_missing?` | `{content_hash, build: {status, diagnostics}}` (waits ≤ 30 s for the build); `conflict` error if `base_hash` mismatches |
| `sheets.delete_script_file` (same) | `spreadsheet, name` | `{ok}` |
| `sheets.get_executions` (`sheets:read`) | `spreadsheet, function?, status?, since?, limit, cursor` | executions with logs (truncated 10 KB each) |

UI bridge: `ui.invoke_command` with the commands above (e.g. `sheets.macro.<id>`),
`ui.navigate('/s/<uuid>/script')`.

---

## 19. Additions to 02-data-model

| # | Change |
|---|--------|
| A-09-1 | `ScriptBuild` gains `status: ScriptBuildStatus` (`ok`, `errors`), `apiVersion: int`, `compilerVersion: String`, `requestedBy: UuidValue`, `lastGoodSourceHash: String?`, `lastGoodBytecodeFileUuid: UuidValue?`, `lastGoodExportsJson: String?`, `lastGoodBuiltAt: DateTime?`, `positionsFileUuid: UuidValue?` (DE-1 table). |
| A-09-2 | `ScriptFile` gains `contentHash: String` (sha256 hex of `source`). |
| A-09-3 | `ScriptTrigger` gains `optionsJson: String?` (`{fireForMcp, notify: immediately\|daily\|never}`) and `createdAt`. `TriggerKind` gains `installableOnOpen`; simple triggers are not stored as rows (they're detected from exports). |
| A-09-4 | Server table `ScriptUserProperty(userId, fileUuid, key, value, updatedAt)`, unique (userId, fileUuid, key); endpoints `sheets.getUserProperties` / `setUserProperties` (suite 17 part 2 §2.4). |
| A-09-5 | The op summary (`summaryJson.kinds`) uses `scripts` for changes to script tables. |
| A-09-6 | Server tables: `ScriptExecution` (§13.1); `ScriptQuotaUsage(userId, day: DateTime (UTC date), serverRuntimeMs, clientRuntimeMs, urlFetchCalls, urlFetchBytes, triggerRuns)`; `ScriptAuthorization(userId, spreadsheetUuid, scopes: List<String>, grantedAt, revokedAt?)`; `ScriptTriggerState(triggerId: UuidValue, spreadsheetUuid, nextRunAt?, lastRunAt?, lastStatus?, consecutiveFailures, disabledReason?)`; `ScriptJob(uuid, kind, spreadsheetUuid, runAsUserId, payloadJson, status, enqueuedAt, leaseOwner?, leaseUntil?, attempts, resultJson?)`. |
| A-09-7 | Local-only client tables (built in `sheets_scripts_<user>.db`, `features/scripts/local/script_local_store.dart`): `local_script_execution_log` (pending uploads, ≤ 1000 per spreadsheet), `local_script_history(fileId, savedAt, source, note)` (last 20 per file), `local_script_draft(spreadsheet, fileId, text, baseHash, baseText)`, and the bytecode in `local_blob_cache(key, mime, bytes, createdAt)` (last 12 builds; the image cache of A-08-5 can share the table). |
| A-09-9 | `ScriptTriggerState.lastNotifiedAt` (daily failure notifications); `ScriptJob` gains `itemUuid`, `triggerId`, `functionName`, `coalesced`, `finishedAt` (status reuses `ScriptExecutionStatus`). |
| A-09-8 | `SpaceSubscription.reason` gains `script` (already listed in suite 12). |

---

## 20. Acceptance criteria

1. A user creates `main.dart` with the `TO_F` custom function, saves, and within 5 s
   (online) `=TO_F(A1:A100)` spills 100 converted values; the formula autocomplete shows
   `TO_F` with its doc. Viewers see the same values.
2. Offline: editing and saving work; the status shows "Will compile when online"; existing
   custom functions keep working with the last good build; after reconnect the server builds
   and functions update.
3. A script with an extension method shows a `wonky_extension` error at the right line; the
   previous good build keeps running.
4. `onOpen` adds a "Report" menu next to Extensions; clicking an item runs the function; its
   writes are one undo step "Script: archive"; the ops have `actorKind = script`.
5. The `onEdit` timestamp example writes the time when D changes; one Mod+Z undoes both the
   edit and the timestamp.
6. An infinite loop in a menu function is stopped after 30 s with "Exceeded maximum execution
   time"; the UI stays responsive throughout (web and desktop); a custom function infinite
   loop yields `#ERROR!` after 3 s without blocking other custom functions.
7. A time-driven trigger (every hour) runs on the server as the installer, appears in
   Executions with logs, and stops with a notification when the installer is downgraded to
   viewer.
8. `UrlFetchApp.fetch('http://169.254.169.254/')`, `https://localhost`, a DNS name resolving
   to 10.0.0.5, and a redirect to a private IP all fail with `UrlFetchException(blocked)`.
9. Responses > 10 MB abort with an error; 20,001st fetch of the day fails with
   `QuotaExceededException`.
10. Macro recorder: record bold + background + freeze, save with Mod+Alt+Shift+1, run it on
    another selection with relative references → same result; one undo step.
11. Two editors save the same file concurrently online → the second gets the conflict dialog;
    *Merge* produces a merged file with conflict markers only for overlapping hunks.
12. MCP: `sheets.update_script_file` returns diagnostics; `sheets.run_function` returns the
    function result, logs and a `change_id` that `changes.revert` undoes.
13. The web worker bundle is ≤ 1.5 MB gzip; the main web bundle contains no `analyzer` code
    (CI check by symbol scan).
14. Every command in §17 works via `ui.invoke_command` and passes the command test harness.

## 21. Test plan

### 21.1 API conformance (`wonky_sheets_script/test/conformance/`)
- A corpus of ~300 small scripts with expected workbook state/results (JSON fixtures).
  The **same corpus runs against three hosts**: `FakeWorkbookAccess` (pure Dart, CI fast),
  `ClientWorkbookAccess` (Flutter test with in-memory sync DB), `HeadlessWorkbookAccess`
  (server test with `serverpod_test`). Results must be identical.
- Covers every API member in §6, value conversions (dates in time zones, errors, empty,
  large ints), A1 parsing edge cases, handle stability across inserts, flush semantics,
  formulas written then read (recalculated values).

### 21.2 Timeouts and limits
- Infinite loops in each invocation kind (client web worker, client isolate, server worker):
  terminated within limit + 1 s; host recovers; next run succeeds.
- Memory bomb (`List.filled(1e9, 0)` in a loop) → killed by the bridged-value guard or the
  RSS watchdog; server worker stays alive (or is restarted by orchestration) and the job is
  marked failed.
- Quota counters: fetch calls, runtime, triggers per user.

### 21.3 Sandbox escape and security
- Attempted imports of `dart:io`, `dart:isolate`, `dart:ffi`, `package:http` → compile errors.
- Reflection-like tricks (`Function.apply` on bridged objects, `noSuchMethod`, accessing
  `$Value` internals, forged handle ids) → host rejects unknown/foreign handles.
- Handles from another spreadsheet/execution → rejected.
- Writes by viewers, into protected ranges, via custom functions → `PermissionDenied`/
  `CustomFunctionSideEffect`.
- SSRF matrix (IPv4/IPv6 private ranges, decimal/octal IP forms, DNS rebinding with a test DNS
  server, redirects, IDN hosts, ports).
- Authorization: running a build with a new scope without re-authorization fails; MCP cannot
  authorize.

### 21.4 Compiler
- Diagnostics positions for each `wonky_*` lint; analyzer errors mapping; exports extraction
  (doc tags, params); deterministic `sourceHash`; build coalescing under rapid saves.

### 21.5 Integration
- Flutter integration tests (flutter_driver + MCP) for the editor: create file, type, save,
  run, see log, add trigger, record macro.
- Multi-client: two clients with `onEdit` triggers editing concurrently; installable trigger
  fires once per committed op.

---

## 22. Alternatives considered and risks

### 22.1 Alternatives

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Dart via `dart_eval`** (chosen) | Same language as the whole stack; API defined once in Dart and bound by codegen; pure Dart runtime runs on web, desktop and server without native blobs; typed, documented API; Flutter developers (our audience) know Dart. | 10–50× slower than AOT; language subset; no built-in CPU/memory limits; analyzer-based compiler is big (server-only); pre-1.0 single-maintainer project. | Chosen with mitigations below. |
| JavaScript via QuickJS (FFI on native, wasm on web) | Apps Script users know JS; mature sandbox with built-in memory limit and interrupt handler; fast enough. | Two languages in the stack; separate binding layer per platform (FFI + JS interop/wasm); larger web bundle (~1 MB wasm); no shared types with our Dart API; more native build complexity for desktop. | Rejected for v1. The host protocol (§8.2.2) is engine-agnostic, so a QuickJS guest could be added later behind the same `ScriptHost`. |
| Lua (`lua_dardo` pure-Dart interpreter, or native Lua via FFI) | Small, embeddable, simple sandboxing. | `lua_dardo` is unmaintained and incomplete; Lua is unfamiliar to most spreadsheet users; same two-language problem. | Rejected. |
| Formula-only extensibility (named functions/`LAMBDA`) | No new runtime. | Can't do triggers, menus, HTTP, automation. | Kept as complement (named functions in [05-formula-engine.md](05-formula-engine.md)). |

### 22.2 Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Interpreter performance | Slow per-cell loops, slow custom functions over large ranges | Bulk APIs and lazy row conversion; write batching; custom function batching and caching; documentation and an editor hint ("Use `values` instead of reading cells in a loop") when the lint detects `getRange` inside loops. |
| Language coverage gaps / interpreter bugs | Scripts fail in surprising ways | Subset lint with friendly messages; conformance corpus; vendored dart_eval with patches upstreamed; pin versions; `apiVersion`/`compilerVersion` in builds so upgrades can be rolled out per build. |
| Web worker complexity (cross-origin isolation, SAB) | Sync bridge unavailable in some contexts | COOP/COEP headers; snapshot-mode fallback; *Run on server* option; tests in Chrome, Firefox, Safari. |
| `native_synchronization` is experimental | API changes | Wrap behind `SyncChannel`; pin; fallback implementation with `dart:ffi` pthread mutex/condvar if needed. |
| No CPU/memory limits in dart_eval | DoS | Isolate/worker kill; server workers in separate containers; bridged-value and RSS guards; DE-2 checkpoints. |
| Analyzer compile cost on server | CPU spikes | Dedicated compiler isolates with a small pool; coalescing; `sourceHash` cache; rate limits. |
| Malicious scripts in shared spreadsheets | Data exfiltration | Runner's permissions only; explicit authorization for network; custom functions need an allowlist; activity entries for allowlist changes; per-user kill switch. |

---

## 23. Implementation status (2026-10-14)

Built (package `wonky_sheets_script`, `third_party/dart_eval`, `wonky_server/lib/src/sheets/scripts`):

- API §6.1–6.11 (P0/P1 members) as interpreted source, plus charts, filters, conditional
  formats (read and write), protections (§6.3), `LockService`/`CacheService` (§6.12) and the
  UI DSL (§16.3); `api_index.json` (`lib/src/api/api_index_data.dart`, generated by
  `tool/gen_api_index.dart` from the API source with the analyzer; a test fails when stale) with
  `ApiIndex` and `ScriptCompletion` (member completion with type inference over expression
  chains, locals, for-in, project symbols; hover docs). Runners (isolate, inline); `ScriptHost`
  over `WorkbookAccess`; custom functions (§8.6) with cache, batching and `#LOADING`;
  `ScriptSession` (live log callback `onLiveLog`); macro recorder codegen (§15); compiler with
  the subset lint (§9.3), exports (§5.1) and the dispatcher; conformance corpus (~150 cases) on
  inline/isolate runners and on a database-loaded workbook; sandbox escape, time-limit and
  memory tests. `dart_eval` patch DE-20 (interpolating a null `String?`).
- Server: `ScriptEndpoint` (`compile`, `analyze`, `bytecode`, `run`, `runLive` (log lines
  streamed before the result), `executions`, `reportExecutions`, `urlFetch`,
  `authorization`/`authorize`/`revokeAuthorization`, `notifyOpen`); tables `ScriptExecution`,
  `ScriptQuotaUsage`, `ScriptAuthorization`, `ScriptTriggerState` (+ `lastNotifiedAt`),
  `ScriptJob`; the job queue and worker role (§8.5: leases, 10 running jobs per user, one per
  trigger, 100 queued per trigger with coalescing, stale-lease retry, daily pruning); SSRF-safe
  `UrlFetchProxy` with the 1 h custom-function response cache (`ScriptFetchCache`); compile
  rate limit 20/h per project and "latest wins" coalescing (`CompileCoalescer`), analysis rate
  limit 30/min per user (`ScriptRateLimiter`, in-memory per instance); failure notifications
  (`scriptFailure`: per-trigger `notify` immediately / daily (default, ≤ 1 a day) / never;
  disabling always notifies); installers with *Enable scripts* off pause (no failure count);
  time-driven scheduler (`wonky.scriptsTick`) and pruning (`wonky.scriptsPrune`); installable
  onEdit/onChange from change-log processing, installable onOpen via `notifyOpen`;
  compile-after-sync; MCP tools §18; config `wonky.features.scripting`,
  `wonky.sheets.scriptTimeoutMs`, `scriptServerTimeoutMs`, `scriptDailyQuotaMs`,
  `scriptAllowHttp`, `scriptPoolSize`, `scriptWorker`, `scriptUserConcurrency`; user
  properties of server runs (`ServerUserProperties`, §6.9).
- App (`wonky_sheets/lib/features/{scripts,macros}`, `commands/{script,macro}_commands.dart`):
  - `ScriptService` (one per editor): last good build with the persistent bytecode cache
    (`ScriptLocalStore`, SQLite `sheets_scripts_<user>.db`: blob cache, execution log queue,
    local history, drafts; offline reopen installs the cached build), `IsolateScriptRunner` on
    desktop / `InlineScriptRunner` on web, script writes through the session, **one undo step
    "Script: fn" per execution**, `onOpen` per window and per build, `onEdit`/`onChange` after a
    person's command, `onEdit` writes appended within 2 s, `onSelectionChange` debounced 300 ms,
    executions queued in `local_script_execution_log` and uploaded in 10 s batches (survive
    reloads offline), authorization dialog, *Stop* = new session; live log lines while a
    function runs (client and *Run on server*); Settings › Sheets › *Enable scripts* (off: no
    runs, triggers or menus, custom functions `#ERROR!` "Scripts are turned off…", banner in
    the editor with *Turn on scripts*).
  - Custom functions in formulas (+ autocomplete/signature help); `#LOADING` is painted as a
    muted italic "Loading…" without the error triangle.
  - Script editor `/s/:uuid/script`: title row with build status and the avatars of
    collaborators in the script editor (presence cursor `{route: script, file}`; colored dots
    on file tabs others have open), toolbar (Save, Run + picker, Run on server, Stop, Triggers,
    Executions, Settings, Generate with AI, Find, *Local history*, *Script API reference*),
    file rail with drag-reorder (`sheets.script.reorderFile`, one undo step) and Functions,
    tabs, `re_editor` with Dart highlighting, API autocomplete (popup with kind icons,
    signatures and docs; Enter accepts), hover docs, squiggle underlines (wavy, by severity)
    plus gutter markers, find/replace, Problems (live `analyze`, build diagnostics, unresolved
    merge markers) / Log (live) / Executions; drafts restored after a reload; save conflicts
    show *Compare* (side-by-side diff ≥ 640 px, unified below; Myers line diff in
    `package:wonky_core/diff.dart`), *Merge* (3-way with the local base; conflicts marked with
    `<<<<<<< yours` / `>>>>>>> theirs`), *Discard mine*, *Overwrite with mine*; the local
    history dialog (last 20 versions per file, also discarded/overwritten text) restores a
    version as a draft. Narrow (< 900 px) file dropdown; read-only for viewers.
  - *Help › Script API reference* (`sheets.help.scriptApiReference`): searchable classes and
    members from `api_index.json` (dialog, two panes ≥ 600 px, stacked below).
  - Dialogs: authorization, triggers, project settings, conflict, history, API reference,
    script alerts/prompts, script sidebars/dialogs (UI DSL); toasts via the shell.
  - Executions side panel, custom menus, macros (§15) with `Mod+Alt+Shift+1…0` — the keymap
    now matches the digit row by physical key when Shift/Alt change the typed character (web,
    macOS layouts), covered by a keymap test.
  - Commands of §17, `sheets.script.deleteProject`, `sheets.help.scriptApiReference`.

Not built yet (gaps):

- Web: SharedArrayBuffer worker and snapshot mode (decision in §8.2.1: not isolated yet;
  alerts/prompts/`UrlFetchApp` stay unavailable in the web inline runner, *Run on server*
  streams its logs instead).
- `analyzer` 8.x pin: porting `dart_eval` to analyzer 13 (assessed 2026-10-14 against 13.3.0)
  is 93 compile errors in 23 files of its compiler (NamedExpression → `NamedArgument`,
  `DefaultFormalParameter`/`SimpleFormalParameter` → `FormalParameterDefaultClause`/
  `RegularFormalParameter`, class/enum bodies for primary constructors, `DottedName`) plus 15
  in `wonky_sheets_script` (compiler, subset lint, index builder); it resolves outside the
  workspace (analyzer 13.3.0, dart_style 3.1.13, test 1.33) but changes the shared lockfile.
  Deferred to a quiet window: port, run the 435 dart_eval and 440 package tests, bump the lock.
- Editor: Tab does not accept a completion (Enter does; `re_editor` binds only Enter);
  signature help while typing arguments; Mod+D; completion/hover in non-active files.
- Limits are per instance (rate limiters, fetch cache, locks, script cache); a shared Redis
  store is the multi-instance follow-up. Digest settings beyond the per-trigger `notify`
  option; the server-wide URL denylist config (`UrlFetchProxy.deniedHosts` exists); `UiImage`;
  `DriveApp`; `editors` of `Spreadsheet` (P2).
