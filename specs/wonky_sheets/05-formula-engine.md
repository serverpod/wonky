# Sheets 05 · Formula Engine

Read first: [02-data-model.md](02-data-model.md) (authoritative for storage: content encoding,
reference tokens, computed values never synced, overlays), suite
[01-architecture.md](../01-architecture.md) (package rules),
[08-commands-and-undo.md](../08-commands-and-undo.md) and
[09-mcp.md](../09-mcp.md). Related Sheets specs:
[03-grid-and-editing.md](03-grid-and-editing.md) (cell editor, formula bar, fill, copy/paste),
[06-formatting.md](06-formatting.md) (number-format engine used by `TEXT`, auto-formats),
[07-data-tools.md](07-data-tools.md) (filters, pivots, named ranges/functions — the parts of the
engine they use), [08-charts-and-objects.md](08-charts-and-objects.md) (SPARKLINE/IMAGE
rendering), [09-scripting.md](09-scripting.md) (custom functions),
[11-import-export-print.md](11-import-export-print.md) (XLSX/ODS formula translation),
[12-mcp-and-ai.md](12-mcp-and-ai.md) (tool implementations).

## 1. Scope and goals

The formula engine is a **pure-Dart library inside `wonky_sheets_core`** (no Flutter imports). The
same code runs:

| Host | Use |
|------|-----|
| Flutter client (web via dart2wasm/dart2js, desktop native AOT) | Interactive recalculation of the open spreadsheet, editor services (highlighting, autocomplete, signature help), filters/CF/DV custom formulas, pivots. |
| Server (`wonky_server`, native AOT/JIT) | Headless evaluation for MCP (`sheets.evaluate`, `sheets.get_values`), server-side scripts/triggers, IMPORTRANGE sources, version snapshots and exports (cached values in XLSX), AI context building. |
| Script runtime (`wonky_sheets_script`) | `Range.getValues()` on formula cells, `setFormula`, `setFormulaR1C1`. |

Goals, in priority order:

1. **Google Sheets compatibility** of syntax, values, coercions, errors and function behavior.
   Where Google and Excel differ we follow Google, unless stated otherwise (§3.9 lists the
   deliberate deviations).
2. **Offline correctness on stable ids**: formulas are stored with id-based references
   ([02 §2](02-data-model.md#2-identifiers-and-encodings-wonky_sync_modelslibsrc)); concurrent
   row/column inserts never rewrite formulas.
3. **Determinism**: same inputs + same `engineVersion` ⇒ bit-identical results on every client and
   on the server (§12).
4. **Scale**: 10M-cell spreadsheets with up to 1M formula cells; viewport results in < 100 ms
   after open from cache; incremental recalc proportional to the dirty set (§21).
5. **Introspectable**: every function carries help metadata used by autocomplete, the function help
   card, the Insert › Function menu, the AI assistant and MCP.

Non-goals (v1): Excel 3-D references (`Sheet1:Sheet3!A1`), the reference intersection (space) and
union (`(A1,B1)`) operators, R1C1 *input* in the cell editor, localized function names, external
workbook references other than `IMPORTRANGE`.

---

## 2. Package and folder layout

### 2.1 `packages/wonky_sheets_core/lib/`

Each folder is an independent unit of work with its own `*_test.dart` mirror under `test/`.

```
formula/
  formula.dart                    # public barrel (exports engine API only)
  ast/                            # sealed AST node classes, visitors, pretty-printer
    ast.dart, visitor.dart, printer.dart
  parser/                         # lexing & parsing (petitparser) — WS-S6 in 13
    formula_grammar.dart          # GrammarDefinition<Expr> composed from mixins below
    lexical_grammar.dart          # numbers, strings, errors, identifiers, whitespace (mixin)
    reference_grammar.dart        # A1 refs, stored ⟦…⟧ tokens, sheet prefixes (mixin)
    expression_grammar.dart       # ExpressionBuilder precedence table (mixin)
    lexer.dart                    # FormulaLexer: error-tolerant tokenizer for editor & codec (no AST)
    formula_locale.dart           # FormulaLocale: separators per Spreadsheet.locale
    parse_error.dart              # FormulaParseError {offset, length, messageKey, message}
  codec/
    formula_codec.dart            # FormulaCodec: toStored / toA1 / normalize / translate (copy & fill)
    reference_rewriter.dart       # ReferenceRewriter: remap (move/cut), repairBoundaries (delete), renameName
    ref_token.dart                # ⟦S:…;R:…;C:…;$R;$C;K:…⟧ encode/decode, base-62 ids
    r1c1.dart                     # R1C1 ⇄ stored (scripts, XLSX shared formulas) — P1
  lexer.dart, codec.dart, reference_rewriter.dart   # re-export barrels (paths used by 03)
  model/                          # interfaces the engine needs from a workbook
    workbook_view.dart            # WorkbookView, SheetView, AxisView, CellInput, NamedRangeView
    headless_workbook.dart        # adapter over lib/model/ (server, tests, scripts)
    id_interner.dart              # UUID/base-62 id ⇄ int handle
  values/
    fvalue.dart                   # sealed FValue hierarchy (§6)
    coercion.dart                 # toNumber/toText/toBool, locale-aware parsing
    compare.dart                  # Sheets ordering & equality (+ tolerance)
    errors.dart                   # ErrorKind, messages, ERROR.TYPE codes
    format_hint.dart              # result format hints (date, time, currency, percent…)
    numeric.dart                  # decimal-correct rounding, 15-digit display, snapping
  eval/
    compiler.dart                 # AST → closure tree (CompiledExpr), template cache
    eval_context.dart             # host cell, array mode, lambda env, recursion depth, clock, rng
    arguments.dart                # ArgKind handling, implicit intersection, lifting/broadcasting
    range_access.dart             # RangeRef resolution, sparse iteration, criteria matching
    spill.dart                    # spill/overlay index, collision rules
    lambda.dart                   # LAMBDA/LET closures, invocation, named functions
  graph/
    dependency_graph.dart         # nodes, precedents, reverse indexes
    range_index.dart              # interval index over id-bounded ranges (§8.3)
    scc.dart                      # Tarjan SCC (cycles), topological ordering
  recalc/
    formula_engine.dart           # FormulaEngine facade (§7.1)
    scheduler.dart                # dirty sets, priorities, time-sliced drain (§10)
    iteration.dart                # iterative calculation for cycles
    volatile.dart                 # volatile & timer-driven recalc
    lookup_cache.dart             # hash/sorted indexes for lookups & criteria (§11.2)
  functions/
    registry.dart                 # FunctionRegistry, FunctionSpec, ArgSpec (§14)
    builtins.dart                 # registers every category
    math/          statistical/   lookup/        logical/      text/
    date_time/     financial/     info/          array/        database/
    engineering/   parser/        operator/      web/          google/   # QUERY, SPARKLINE, IMAGE…
    lambda_helpers/               # MAP, REDUCE, SCAN, BYROW, BYCOL, MAKEARRAY
    query/                        # Google Visualization query language for QUERY() (§16)
  external/
    external_data.dart            # ExternalDataProvider interface (IMPORTRANGE, IMPORT*, AI, scripts)
    pending.dart                  # pending/async result protocol (§13)
  services/                       # editor services consumed by the Flutter UI and MCP
    highlighter.dart              # token spans + reference color assignment
    signature_help.dart           # enclosing call, active argument
    autocomplete.dart             # ranked completions (functions, names, sheets)
    explain.dart                  # evaluation trace tree (Explain formula, MCP)
    auto_fix.dart                 # close parens/quotes on commit, suggestions
address/                          # A1 address parsing/printing, ColumnLetters (shared with 03)
model/                            # AxisIndex, CellStore, HeadlessWorkbook implementing formula/model interfaces (WS-S3)
rules/conditions/                 # Condition model + evaluator shared by CF/DV/filters (see 07 §3.3)
pivot/                            # pivot engine (see 07 §7)
data_tools/                       # sort, filter, dedupe, split, stats engines (see 07)
format/                           # number format engine (owned by 06-formatting)
bin/compute_worker.dart           # web-worker / isolate entrypoint for offload jobs (§10.3)
```

Dependencies: `wonky_core`, `petitparser` (^7), `intl`, `timezone` (pure-Dart tz database for
`NOW()/TODAY()` in `Spreadsheet.timeZone`; **addition** to the dependency rule in suite
[01 §2.1](../01-architecture.md#21-package-dependency-rules-enforced-by-a-ci-script)),
`collection`, `meta`.

### 2.2 `wonky_sheets/lib/`

```
features/calc/                    # RecalcHost: owns FormulaEngine per open spreadsheet,
  recalc_host.dart                #   adapts WorkbookModel → WorkbookView, time-slices the scheduler,
  time_slicer.dart                #   exposes ValueListenable<RecalcEpoch> to the grid
  computed_value_cache_repo.dart  #   ComputedValueCache read/write (02 §4)
  external_data_client.dart       #   ExternalDataProvider over Serverpod (IMPORTRANGE, IMPORT*, AI)
  compute_offload.dart            #   Isolate.run (native) / Web Worker (web) offload jobs
features/formula_inspect/         # Explain formula panel, trace precedents/dependents, circular path (P1)
commands/formula_commands.dart    # sheets.formula.* (§19)
mcp/formula_ui_tools.dart         # ui.sheets.* helpers related to formulas (see 12)
```

The cell editor, formula bar, function autocomplete popup, signature-help card and error tooltip
widgets are owned by [03-grid-and-editing.md](03-grid-and-editing.md) §1/§8.7
(`features/cell_editor/formula/*`, `features/in_cell/error_tooltip.dart`); the Function help dialog
by [04 §11.20](04-screens-menus-toolbar.md#11-dialogs). They consume `formula/services/*` and the
registry from core; this spec defines the data they show (§18).

### 2.3 Server (`wonky_server/lib/src/sheets/`)

```
engine/
  headless_engine_service.dart    # LRU of HeadlessWorkbook+FormulaEngine per spreadsheet (max 20, idle 10 min)
  workbook_loader.dart            # builds HeadlessWorkbook from the file's tables (HeadlessFileCache, suite 17 part 5 §9)
  changelog_patch.dart            # applies the applied changes of committed ops (the cache follows the file's ops)
external/
  import_range_service.dart       # IMPORTRANGE grants + value fetch (§13.3)
  fetch_proxy_service.dart        # IMPORTDATA/HTML/XML/FEED fetch with SSRF guard (§13.4); shares the guard with 08's /files/proxy
  ai_function_service.dart        # AI() and translate functions (§13.5)
endpoints/sheets_external_endpoint.dart
```

---

## 3. Formula language

### 3.1 Overview

A cell whose input starts with `=` (or `+`/`-` followed by a valid expression, Google behavior:
`+A1` is committed as `=+A1`) is a formula. The **A1 form** is what users type and see; the
**stored form** ([02 §2](02-data-model.md)) replaces every resolvable reference with an id token
and is locale-neutral. Both forms share one grammar (§3.3); the stored form additionally allows
`⟦…⟧` tokens and always uses the canonical (en_US) separators.

### 3.2 Locale

`FormulaLocale` is derived from `Spreadsheet.locale` (number symbols via `intl`'s
`NumberSymbols`):

| Locale group | Decimal | Argument separator | Array column sep | Array row sep | Example |
|--------------|---------|--------------------|------------------|---------------|---------|
| `.` decimal (en_US, en_GB, ja_JP, zh_CN, …) | `.` | `,` | `,` | `;` | `=ROUND(1.5, 0)`, `{1,2;3,4}` |
| `,` decimal (de_DE, fr_FR, es_ES, it_IT, pt_BR, nl_NL, ru_RU, …) | `,` | `;` | `\` | `;` | `=ROUND(1,5; 0)`, `{1\2;3\4}` |

- Stored form always uses the `.`-decimal column. Changing `Spreadsheet.locale` therefore never
  rewrites formulas; the A1 rendering changes.
- When editing, the parser additionally accepts the canonical separators if unambiguous (pasting
  `=SUM(A1,B1)` into a de_DE sheet parses because `,` cannot be a decimal separator after a
  reference). If ambiguous, locale rules win.
- Thousands separators are never allowed in numeric literals.
- Function names are English only (localized names: P2, a per-locale alias table in the
  registry; stored form always English).
- Date/number **text** coerced inside formulas (`="1,5"+1`, `DATEVALUE("31.12.2024")`) uses the
  spreadsheet locale (§6.3).

### 3.3 Grammar (EBNF)

Whitespace (`ws` = space, tab, CR, LF) is allowed between any two tokens and is preserved by the
codec (users may format long formulas over several lines with `Alt+Enter`). Keywords, function
names, column letters and booleans are case-insensitive.

```ebnf
formula          = "=" , ws , expression , ws ;               (* leading "=" stripped by CellContent *)

expression       = comparison ;
comparison       = concatenation , { ws , compare_op , ws , concatenation } ;     (* left-assoc *)
compare_op       = "=" | "<>" | "<=" | ">=" | "<" | ">" ;
concatenation    = additive , { ws , "&" , ws , additive } ;
additive         = multiplicative , { ws , ( "+" | "-" ) , ws , multiplicative } ;
multiplicative   = power , { ws , ( "*" | "/" ) , ws , power } ;
power            = percent , { ws , "^" , ws , percent } ;                        (* left-assoc: 2^3^2 = 64 *)
percent          = unary , { ws , "%" } ;
unary            = { ( "+" | "-" ) , ws } , range_expr ;                          (* -2^2 = 4 *)
range_expr       = postfix , { ws , ":" , ws , postfix } ;                        (* dynamic range: A1:INDEX(B:B,5) *)
postfix          = primary , { "(" , arg_list , ")" } ;                           (* LAMBDA(x,x+1)(5) *)

primary          = number
                 | string
                 | boolean
                 | error_literal
                 | array_literal
                 | function_call
                 | reference                                                      (* see 3.4 *)
                 | name                                                           (* named range/function, LET/LAMBDA variable *)
                 | "(" , ws , expression , ws , ")" ;

function_call    = function_name , "(" , arg_list , ")" ;                         (* no space before "(" *)
function_name    = identifier ;
arg_list         = ws , [ argument , { ws , ARG_SEP , ws , argument } ] , ws ;
argument         = [ expression ] ;                                               (* empty = omitted arg *)

array_literal    = "{" , ws , array_row , { ws , ROW_SEP , ws , array_row } , ws , "}" ;
array_row        = expression , { ws , COL_SEP , ws , expression } ;              (* elements may be ranges/arrays: stacking *)

number           = ( digits , [ DECIMAL , [ digits ] ] | DECIMAL , digits ) , [ exponent ] ;
exponent         = ( "e" | "E" ) , [ "+" | "-" ] , digits ;
digits           = digit , { digit } ;
string           = '"' , { char - '"' | '""' } , '"' ;
boolean          = ( "TRUE" | "FALSE" ) , ? not followed by "(" or identifier char ? ;
error_literal    = "#N/A" | "#REF!" | "#NAME?" | "#VALUE!" | "#DIV/0!" | "#NUM!" | "#NULL!"
                 | "#ERROR!" | "#SPILL!" | "#CALC!" ;

identifier       = ( letter | "_" | "\" ) , { letter | digit | "_" | "." } ;

(* separators from FormulaLocale *)
ARG_SEP          = "," | ";" ;      DECIMAL = "." | "," ;
COL_SEP          = "," | "\" ;      ROW_SEP = ";" ;
```

### 3.4 References

```ebnf
reference        = stored_ref_range | a1_reference ;

a1_reference     = [ sheet_prefix ] , area ;
sheet_prefix     = ( quoted_sheet | bare_sheet ) , "!" ;
quoted_sheet     = "'" , { char - "'" | "''" } , "'" ;
bare_sheet       = ( letter | "_" ) , { letter | digit | "_" } ;                  (* only if not cell-like / reserved *)
area             = cell , [ ":" , ( cell | col | row ) ]                          (* A1, A1:B2, A2:B (rows open), B3:5 (cols open) *)
                 | col , ":" , col                                                (* A:C *)
                 | row , ":" , row ;                                              (* 1:3 *)
cell             = [ "$" ] , col_letters , [ "$" ] , row_number ;
col              = [ "$" ] , col_letters ;
row              = [ "$" ] , row_number ;
col_letters      = letter , [ letter , [ letter ] ] ;                             (* A … ZZZ = 18,278 columns *)
row_number       = nonzero_digit , { digit } ;                                    (* ≤ 10,000,000 *)

stored_ref_range = stored_ref , [ ":" , stored_ref ] ;
stored_ref       = "⟦" , field , { ";" , field } , "⟧" ;
field            = "S:" , id22 | "R:" , id22 | "C:" , id22 | "$R" | "$C"
                 | "K:" , sort_key | "KC:" , sort_key                             (* row / column sortKey, §5.4 *)
                 | "X:" , a1_text ;                                               (* unbound A1 remainder, §5.3 *)
```

Semantics:

| Form | Meaning | Stored |
|------|---------|--------|
| `A1`, `$A$1`, `A$1`, `$A1` | Cell; `$` marks absolute for copy/fill only | `⟦R:r;C:c⟧` with `$R`/`$C` flags |
| `A1:B5` | Rectangle (endpoints normalized so the range is top-left → bottom-right at evaluation) | `⟦…⟧:⟦…⟧` |
| `A:C`, `1:3` | Whole columns / rows | `⟦C:a⟧:⟦C:c⟧`, `⟦R:a⟧:⟦R:c⟧` |
| `A2:B` | Columns A–B from row 2 to the last row ("open-ended") | `⟦R:r;C:a⟧:⟦C:b⟧` |
| `B3:5` | Rows 3–5 from column B to the last column | `⟦R:r;C:b⟧:⟦R:s⟧` |
| `Sheet1!A1`, `'Q3 plan'!A1:B2` | Other sheet (`''` escapes `'` in quoted names) | `S:` field on the first token only |
| `A1:INDEX(B:B, 5)` | `:` between reference-valued expressions (INDEX, OFFSET, INDIRECT, CHOOSE, IF results) | kept as AST `RangeOp` |

Disambiguation (checked in this order):

1. `identifier "("` ⇒ function call, even if the identifier looks like a cell (`LOG10(`, `ATAN2(`).
2. `TRUE`/`FALSE` not followed by `(` ⇒ boolean literal.
3. Cell-like text (`col_letters row_number` within limits, optionally `$`) ⇒ reference.
4. Otherwise ⇒ `name` (resolved at bind time, §7.6).

Sheet names must be quoted when they are not a valid `bare_sheet`, look like a cell or R1C1
reference, are `TRUE`/`FALSE`, or contain anything but letters/digits/underscore. The codec quotes
automatically when rendering.

### 3.5 Operators

Precedence from highest to lowest (Google Sheets = Excel order):

| Level | Operator | Assoc. | Function equivalent | Notes |
|-------|----------|--------|---------------------|-------|
| 1 | `:` range | left | — | operands must be references; otherwise `#VALUE!` "Range operator requires references" |
| 2 | unary `-` `+` | prefix | `UMINUS`, `UPLUS` | binds tighter than `^`: `-2^2 = 4` (Sheets parity) |
| 3 | `%` | postfix | `UNARY_PERCENT` | `50%` = 0.5 with percent format hint |
| 4 | `^` | left | `POW` | `0^0 = 1` (Sheets); negative base with fractional exponent → `#NUM!` |
| 5 | `*` `/` | left | `MULTIPLY`, `DIVIDE` | `/0` → `#DIV/0!` |
| 6 | `+` `-` | left | `ADD`, `MINUS` | cancellation snapping §6.5 |
| 7 | `&` | left | `CONCAT` | number→text uses 15 significant digits, no format |
| 8 | `=` `<>` `<` `>` `<=` `>=` | left | `EQ`, `NE`, `LT`, `GT`, `LTE`, `GTE` | ordering §6.4 |

Not supported (parse error `#ERROR!`): reference intersection (space operator), reference union
`(A1:A3,C1:C3)` outside function arguments, Excel's implicit-intersection operator `@`, spill
operator `A1#` (P2 for Excel import fidelity), structured references `Table1[Col]` (P2 with
tables, see [07 §17](07-data-tools.md)).

### 3.6 Array literals

- `{1,2,3}` is a 1×3 row; `{1;2;3}` a 3×1 column; `{1,2;3,4}` 2×2 (en_US separators).
- Elements may be any expression, including ranges and nested arrays, which are **stacked**
  (Google semantics): `{A1:A3, B1:B3}` is a 3×2 array, `{A1:B1; A5:B10}` a 7×2 array. Row
  stacking requires equal widths and column stacking equal heights, otherwise `#VALUE!` "In
  ARRAY_LITERAL, an Array Literal was missing values for one or more rows." (column variant: "…for
  one or more columns").
- Empty elements (`{1,,3}`) are parse errors.
- An array literal always spills (§7.5).

### 3.7 Names, LET, LAMBDA, named functions

- **Named ranges** (`NamedRange.rangeJson`) are referenced by name: `=SUM(Sales)`. Names are
  case-insensitive; the codec renders them with their defined casing.
- **Named functions** (`NamedRange.formula` holding a stored-form `LAMBDA`, see
  [07 §9](07-data-tools.md)) are called like built-ins: `=TAX(B2)`. They may call other named
  functions and themselves (recursion limit §7.6). They cannot shadow built-in names.
- **LET(name1, value1, [name2, value2, …], expression)** binds names left to right; later values
  may use earlier names. Names follow identifier rules and must not look like cell references.
- **LAMBDA(param1, …, body)** creates a function value. It can be invoked immediately
  (`=LAMBDA(x, x*2)(A1)`), bound with LET and called by name (`=LET(f, LAMBDA(x, x+1), f(5))`),
  passed to helpers (`MAP`, `REDUCE`, `SCAN`, `BYROW`, `BYCOL`, `MAKEARRAY`) or stored as a named
  function. A LAMBDA value that ends up as a cell result yields `#CALC!` "Formula result is a
  function; did you forget to call it?" (Sheets shows `#N/A`; we deviate for clarity — §3.9).
- **ISOMITTED(param)** tells whether a LAMBDA parameter was omitted by the caller
  (`f(1,)` or fewer args than params).
- Scope resolution for a `name` token: innermost LET/LAMBDA binding → named range/function of the
  spreadsheet → script custom function (only callable form) → `#NAME?`.

### 3.8 Limits

| Limit | Value | Error |
|-------|-------|-------|
| Formula length (A1 form) | 32,768 chars (same as 03 §8.4) | input rejected in editor: "Formula is too long" |
| Nesting depth (parens/calls) | 256 | `#ERROR!` "Formula is too deeply nested" |
| Function arguments | 255 (variadic) | `#N/A` "Wrong number of arguments to X. Expected between a and b arguments, but got n arguments." |
| Array literal elements | 100,000 | `#VALUE!` |
| Array/spill result size | 2,000,000 cells | `#NUM!` "Result too large" |
| String length | 50,000 chars per cell value | `#VALUE!` "Text result of X is longer than the limit of 50000 characters." |
| LAMBDA recursion depth | 512 frames | `#CALC!` "Recursion limit exceeded" |

### 3.9 Deliberate deviations from Google Sheets

| Topic | Google | Wonky | Why |
|-------|--------|-------|-----|
| Spill collision error | `#REF!` "Array result was not expanded because it would overwrite data in B3." | `#SPILL!` with the same message | Distinct, catchable, maps 1:1 to XLSX. `ISREF`/`ERROR.TYPE` documented (code 9). |
| Lambda as cell result | `#N/A` | `#CALC!` | Clearer; Excel parity. |
| Regex flavor | RE2 | Dart `RegExp` (ECMAScript) + RE2 syntax shim (§15.5) | No RE2 in pure Dart. |
| `GOOGLEFINANCE` | live market data | not available (`#NAME?` with explanation) | No data source. |
| `GOOGLETRANSLATE`/`DETECTLANGUAGE` | Google Translate | AI-backed (P2), cached | §13.5 |
| RAND family | server value shared by all | deterministic seed shared by all clients (§12) | Local computation. |

---

## 4. Parsing and editor services

### 4.1 Two front ends, one lexical definition

| Component | Input | Output | Used by |
|-----------|-------|--------|---------|
| `FormulaLexer` | any text (incl. incomplete) | `List<FormulaToken>` with spans, never throws | highlighting, signature help, autocomplete, codec, auto-fix |
| `FormulaParser` (`GrammarDefinition<Expr>`) | complete formula | `Expr` AST or `FormulaParseError` | compiler, explain, validation, MCP |

Both are built from the same mixins (`LexicalGrammar`, `ReferenceGrammar`), so token
classification is identical. The tokenizer is a flat `ChoiceParser` of token productions run in a
loop with a fallback `unknown` token (one char) for error tolerance.

```dart
enum TokenKind {
  number, string, boolean, error, cellRef, rangeRef, columnRange, rowRange, storedRef,
  sheetPrefix, functionName, name, operator, argSeparator, arrayColSep, arrayRowSep,
  openParen, closeParen, openBrace, closeBrace, whitespace, unterminatedString, unknown,
}

final class FormulaToken {
  final TokenKind kind;
  final int start, end;          // UTF-16 offsets into the A1 text
  final String text;
  final int depth;               // paren depth (for bracket matching / rainbow parens)
  final RefInfo? ref;            // parsed A1/stored ref (sheet, row/col, absolute flags)
}
```

### 4.2 Parser construction (petitparser)

Follow the repository's petitparser skills (`petitparser-architecting`, `-authoring`, `-test`):

- Single-tier, strongly typed `GrammarDefinition<Expr>`; mixins for lexical, reference and
  expression concerns; `ref0`/`ref1` for productions.
- Operator precedence with `ExpressionBuilder<Expr>`; groups declared highest → lowest exactly as
  §3.5 (`:` as `left`, unary as `prefix`, `%` as `postfix`, `^` `left`, …). Parentheses via
  `builder.group().wrapper(...)`.
- Locale is a constructor parameter: `FormulaGrammar(FormulaLocale locale, {bool storedForm})`.
  Parsers are cached per `(locale, storedForm)`.
- Use `.flatten(message:)`/`plusString()` for terminals (fast mode), `.token()` to keep spans on
  every AST node (`Expr.span`) for error positions and Explain.
- Ordered choice for `primary`: number, string, boolean (with negative lookahead), error,
  array, function call (identifier followed by `(`), stored ref, A1 ref (with negative lookahead
  on identifier chars so `A1B` is a name), name, parenthesized.
- Parse failures produce `FormulaParseError(offset, messageKey)`; the most useful failure is the
  furthest failure position (petitparser `Failure.position`); message keys:
  `unexpectedToken`, `missingCloseParen`, `unterminatedString`, `emptyArrayElement`,
  `invalidReference`, `tooDeep`, `trailingInput`.

```dart
sealed class Expr { SourceSpan get span; }
final class NumberLit extends Expr { final double value; }
final class StringLit extends Expr { final String value; }
final class BoolLit extends Expr { final bool value; }
final class ErrorLit extends Expr { final ErrorKind kind; }
final class ArrayLit extends Expr { final List<List<Expr>> rows; }
final class RefExpr extends Expr { final RefSpec ref; }            // single cell / area, id-based or unbound
final class NameExpr extends Expr { final String name; }
final class CallExpr extends Expr { final String name; final List<Expr?> args; }   // null = omitted
final class InvokeExpr extends Expr { final Expr callee; final List<Expr?> args; } // LAMBDA(...)(...)
final class UnaryExpr extends Expr { final UnaryOp op; final Expr operand; }
final class PercentExpr extends Expr { final Expr operand; }
final class BinaryExpr extends Expr { final BinaryOp op; final Expr left, right; }
final class RangeOpExpr extends Expr { final Expr left, right; }
final class ParenExpr extends Expr { final Expr inner; }            // kept for printing fidelity
```

### 4.3 Editor services (consumed by [03](03-grid-and-editing.md))

| Service | API | Behavior |
|---------|-----|----------|
| Highlighting | `highlight(text, ctx) → List<HighlightSpan>` | Each distinct reference (by normalized target) gets a colour index 0..9 in order of first appearance — the same index drives the coloured range outlines drawn on the grid while editing. Functions, strings, numbers, errors, names have token classes mapped to theme colours (light/dark) by 03. Matching paren of the caret is highlighted. |
| Signature help | `signatureAt(text, caret) → SignatureInfo?` | Finds innermost unclosed `CallExpr` via the token stream; returns `{function, activeArgIndex (accounting for repeatable groups), spec}`. Works for named functions (params from metadata) and LET/LAMBDA. |
| Autocomplete | `completionsAt(text, caret, ctx) → CompletionList` | Triggered when the caret ends an identifier prefix in an expression position. Candidates: built-in functions, named functions, named ranges, script custom functions, LET/LAMBDA names in scope, sheet names (after `'`). Ranking: exact prefix > word-start match inside dotted names (`DIST` → `NORM.DIST`) > fuzzy; ties by usage frequency table shipped with the registry, then alphabetic. Max 20 items. |
| Reference insertion | `refInsertionPoint(text, caret) → bool` | True when the caret is at a position where a reference may be inserted (after `(`, operator, separator, `=`); 03 enters range-pick mode so clicking cells inserts/updates the reference token under the caret. |
| Reference cycling (F4) | `cycleAbsolute(text, caret) → Edit` | Cycles the ref under/before the caret `A1 → $A$1 → A$1 → $A1 → A1` (ranges: both endpoints). |
| Auto-fix on commit | `autoFix(text) → AutoFixResult` | Appends missing `)` and closing `"` (Google behavior), converts `+A1` → `=+A1`, trims trailing argument separators. If still unparseable → stored as formula; evaluates to `#ERROR!` (§5.3). |
| Error explanation | `describeError(cellValue) → ErrorTooltip` | Title ("Error", "Formula parse error", "Circular dependency"…) + message for the red-triangle tooltip on cells. |

Performance: `highlight` and `signatureAt` < 1 ms for 1,000-char formulas (they run on every
keystroke).

---

## 5. FormulaCodec (A1 ⇄ stored form)

### 5.1 API

```dart
final class CodecContext {
  final WorkbookView workbook;
  final SheetId hostSheet;
  final int hostRow, hostCol;        // current indices of the formula's cell (or range top-left
                                     // for CF/DV/filter custom formulas)
  final FormulaLocale locale;
}

abstract final class FormulaCodec {
  /// User A1 text (with or without "=") → stored formula text (canonical separators).
  static String toStored(String a1, CodecContext ctx);
  /// Stored text → A1 text in ctx.locale. Missing ids render "#REF!".
  static String toA1(String stored, CodecContext ctx);
  /// Copy/fill/paste (03 §10, §12.3): shift relative parts by the index delta between hosts.
  static String translate(String stored, CellPos from, CellPos to, WorkbookView wb);
  /// R1C1 (scripts, XLSX shared formulas, clipboard `data-sheets-formula`). P1.
  static String toR1C1(String stored, CodecContext ctx);
  static String fromR1C1(String r1c1, CodecContext ctx);
}

/// Rewrites of *other* formulas/ranges caused by an operation (03 §11, §12.6, §13.2, §13.3).
abstract final class ReferenceRewriter {
  /// Cut/paste, drag-move, insert/delete cells with shift: every formula (and GridRange) that
  /// references cells inside [source] is retargeted to [dest] (dependents from the graph).
  static List<FormulaRewrite> remap(GridRect source, GridRect dest, DependencyGraph g, WorkbookView wb);
  /// Row/column delete: move range endpoints on deleted ids inward (§5.4); single refs → #REF!.
  /// Used by 03's RangeBoundaryRepair in the same transaction as the delete.
  static String? repairBoundaries(String stored, Set<IdHandle> deletedIds, WorkbookView wb);
  /// Rename of a named range/function: rewrites NameExpr tokens (case-insensitive) only.
  static String renameName(String stored, String oldName, String newName);
  /// Full-row sort/randomize by sortKey permutation (07 §2.2): references and range endpoints
  /// pointing into [block] are re-pinned to the ids now at the same positions.
  static List<FormulaRewrite> repinPermutation(SheetId sheet, IndexRange block, Int32List permutation,
      DependencyGraph g, WorkbookView wb);
}
```

### 5.2 Token-level rewriting

The codec works on the **token stream**, not by re-printing the AST, so user whitespace, line
breaks, parentheses and literal spelling survive round-trips. Rules applied by `toStored`:

1. Function names → canonical upper case (`sum(` → `SUM(`); named functions/ranges → defined
   casing; booleans → `TRUE`/`FALSE`.
2. Locale separators → canonical (`;`→`,` for args, `\`→`,` in arrays, `,`→`.` decimals).
3. Each A1 reference → id token: resolve sheet by name (case-insensitive; host sheet omitted),
   column letters → `AxisView.idAt(colIndex)`, row number → `idAt(rowIndex)`, `$` → flags.
4. A range's second token omits `S:` (same sheet as the first by definition). Both endpoint tokens
   of a range carry the encode-time `sortKey` of their row (`K:`) and column (`KC:`) for each
   dimension present (§5.4); single-cell tokens don't. Example: `=SUM(B2:B10)` →
   `=SUM(⟦R:5Kq…;C:9zA…;K:a0V;KC:a1⟧:⟦R:7Hb…;C:9zA…;K:a0d;KC:a1⟧)`.

`toA1` reverses: id → current index → letters/number; `S:` → current sheet name (quoted if
needed); canonical → locale separators. `toA1(toStored(x)) == normalize(x)` is a property test.

### 5.3 Unbound references

A reference that cannot be resolved at commit time — unknown sheet name (`'Budget 2027'!A1`
before that sheet exists) or a row/column beyond the current grid (`A5000` in a 1,000-row sheet) —
is stored as an **unbound token** `⟦S:<id>?;X:'Budget 2027'!A1⟧` (the `X:` field holds the A1
text, `S:` only when the sheet resolved). Evaluation resolves unbound tokens **positionally/by name
every time** and records a `SheetNamesDep`/`AxisLengthDep` so they re-evaluate when sheets are
added/renamed or the grid grows. Until resolvable they evaluate to `#REF!` "Unresolved sheet name
'Budget 2027'." / "Range A5000 is out of bounds.". The maintenance pass
([02 §8](02-data-model.md#8-invariants--maintenance-client-side-idempotent)) re-encodes unbound
tokens into id tokens once resolvable (deterministic, idempotent; written by the first client that
notices).

Unparseable formulas (`=SUM(A1`, after auto-fix failed) are still stored with `=` prefix: the
codec converts whatever reference tokens it recognizes and leaves the rest verbatim; evaluation
yields `#ERROR!` "Formula parse error." with the error offset (shown in the tooltip and by
underlining the offending token in the editor).

### 5.4 Deleted rows/columns and range endpoints (refines 02)

- A **single-cell** reference whose row, column or sheet no longer exists evaluates to `#REF!`
  and renders `#REF!` (02).
- A **range endpoint** whose row/column was deleted must behave like Google/Excel (the range
  *shrinks*: deleting row 10 turns `SUM(A1:A10)` into `SUM(A1:A9)`). Two mechanisms, both
  deterministic:
  1. **Write-time normalization (primary).** Row/column delete commands
     ([03 §13.2](03-grid-and-editing.md), `RangeBoundaryRepair`) call
     `ReferenceRewriter.repairBoundaries` for every formula that
     has a range endpoint on a deleted id (found via the dependency graph's endpoint index,
     §8.3) and for CF/DV/filter/pivot/chart/named ranges (`GridRange` bounds), rewriting
     endpoints to the nearest surviving row/column *inside* the range, in the same undo
     transaction. A range whose rows are all deleted becomes `#REF!`.
  2. **Evaluation-time fallback (concurrent edits).** Every range-endpoint token carries `K:`
     (row) / `KC:` (column) fields with the endpoint's `sortKey` at encode time (**addition to
     02**, §24). If an endpoint id is missing at evaluation (a collaborator deleted the row while
     this formula was written offline), the endpoint is placed at the position the key `(K, id)` would
     occupy in the current axis order, i.e. the range covers exactly the surviving rows between
     the endpoints. Since `K` is part of the stored text, all clients agree. `K` may be stale if
     the row was *moved* before deletion; that only affects this rare fallback.
- Whole sheet deleted → all tokens with that `S:` render/evaluate `#REF!` (undoing the delete
  revives the sheet with the same id and the formulas work again).

### 5.5 Copy, fill, move, structural operations

| Operation | Formula behavior | Implementation |
|-----------|------------------|----------------|
| Insert rows/cols anywhere | Nothing rewritten. Refs follow their ids; ranges include rows inserted between their endpoints. | — |
| Delete rows/cols | Single refs → `#REF!`; range endpoints shrink | §5.4 |
| Move rows/cols (drag headers) | Refs follow the moved rows (same ids). Range coverage follows endpoint ids (Excel semantics). | — (dependency index re-sorts, §8.3) |
| Copy/paste, fill handle, `Mod+Enter` fill | Relative parts shift by the host delta; absolute parts stay. Cross-sheet paste: refs without `S:` re-resolve on the destination sheet by index (rows/cols are per-sheet entities). Shift out of bounds → `#REF!` literal. | `FormulaCodec.translate`: per token, `newIndex = oldIndex + delta` for relative dims; `idAt(newIndex)` (equivalent to the A1-level shift, without re-printing) |
| Cut/paste, drag-move cells, insert/delete cells with shift | Moved formulas keep pointing at the same data: refs to cells outside the block are unchanged, refs into the moved block follow it. Other formulas referencing cells **fully inside** the moved block are retargeted (single cells, and ranges entirely inside). Partially overlapping ranges are unchanged. | `ReferenceRewriter.remap` (writes are part of the move/paste undo step) |
| Sort / randomize range ([07 §2](07-data-tools.md)) | Formulas inside moved rows get copy semantics (delta = new row − old row). External refs and ranges keep pointing at positions. | Partial-range sorts: `FormulaCodec.translate` per moved cell. Full-row sorts (rows reordered by `sortKey`): `ReferenceRewriter.repinPermutation` re-pins refs/range endpoints into the block and rewrites moved formulas only where copy semantics differ |
| Rename sheet | Nothing rewritten (`S:` ids). Unbound/INDIRECT text refs re-resolve. | — |
| Rename named range/function | Formulas using it are rewritten in the same undo step | `ReferenceRewriter.renameName` over dependents (graph `NameDep`) |
| Delete named range | Formulas keep the text → `#NAME?` "Unknown range name: 'X'." until re-created | — |

---

## 6. Values, coercion and precision

### 6.1 Value types

```dart
sealed class FValue { const FValue(); }
final class FNumber extends FValue { final double v; final FormatHint hint; }  // dates/times are numbers
final class FText extends FValue { final String v; }
final class FBool extends FValue { final bool v; }
final class FError extends FValue { final ErrorKind kind; final String? message; final bool pending; }
final class FEmpty extends FValue { const FEmpty(); }                // blank cell / omitted value
final class FArray extends FValue {                                  // dense, row-major, immutable
  final int rows, cols; final List<FValue> cells;                    // FEmpty allowed
}
final class FRef extends FValue { final List<ResolvedArea> areas; }  // 1 area except CHOOSE/IF unions (never >1 in v1)
final class FLambda extends FValue { final LambdaClosure closure; }
final class FOmitted extends FValue { const FOmitted(); }            // missing argument marker
final class FRich extends FValue {                                   // renderable cell value
  final RichKind kind;                                               // sparkline, image, hyperlink
  final FValue scalar;                                               // value seen by other formulas
  final Object payload;                                              // SparklineSpec / ImageSpec / LinkSpec
}
```

- `ResolvedArea` = `{sheetId, rowStart, rowEnd, colStart, colEnd}` in **current indices** plus the
  originating `RefSpec` (ids) for dependency recording. `rowEnd = axisLength-1` for open/whole
  references, clamped to the used range for iteration (§8.4).
- Large ranges are **not** materialized into `FArray` unless a function needs random access;
  functions iterate `RangeAccess` (sparse column-major iteration over non-empty cells).
- `FRich.scalar`: `SPARKLINE` → `FEmpty`; `IMAGE` → `FEmpty`; `HYPERLINK(url, label)` →
  `FText(label)` (numbers stay numbers: `HYPERLINK(u, 5)` → 5).
- `FRich.payload` types are the ones painted by [08](08-charts-and-objects.md):
  `SparklineValue` (08 §2, reuses `ChartScene`) and `ImageValue` (08 §10.2); `LinkValue` for
  HYPERLINK is painted by 03 §14.4. (08 refers to the engine's value type as `FormulaValue`; it is
  the same sealed type as `FValue` — `typedef FormulaValue = FValue` is exported for readability.)
- The pending value (§13.1) is what [09 §8.6](09-scripting.md) calls `#LOADING`.

### 6.2 Format hints (automatic number formats)

When a formula cell has no explicit `numberFormat` (automatic), its display format comes from the
result's `FormatHint`. Hints: `none, date, time, dateTime, duration, percent, currency(code),
scientific, fromCell(numberFormat)`.

| Source | Hint |
|--------|------|
| `DATE`, `DATEVALUE`, `EDATE`, `EOMONTH`, `WORKDAY*`, `TODAY`, `TO_DATE`, `EPOCHTODATE`, date literals in QUERY | `date` (EPOCHTODATE: `dateTime`) |
| `NOW` | `dateTime` |
| `TIME`, `TIMEVALUE` | `time` |
| `%` operator, `TO_PERCENT` | `percent` |
| `PMT`, `IPMT`, `PPMT`, `FV`, `PV`, `NPV`, `TO_DOLLARS`, `DOLLAR`* | `currency(locale default)` (*text result) |
| Bare reference `=A1`, `=A1:A10`, lookups returning cell values (`VLOOKUP`, `INDEX`, `XLOOKUP`, `FILTER`, `SORT`…) | `fromCell` of the source cell (per element for arrays) |
| `date ± number` | `date`; `date − date` → `none`; `time + time` → `time`; `dateTime − dateTime` → `none` |
| `SUM`, `MIN`, `MAX`, `AVERAGE` (+`IFS` variants), `MEDIAN` over a range whose first numeric cell has a date/currency/percent format | that format (Sheets behavior) |
| Anything else | `none` (General) |

Hints are part of the computed value (cached) but never synced. Explicit cell formats always win.

### 6.3 Coercion

| To | From number | From text | From bool | From empty | From error |
|----|-------------|-----------|-----------|-----------|------------|
| number | itself | parse with locale: plain numbers, `1e3`, `$1,234.50` (locale currency & grouping), `12%`, dates/times/datetimes accepted by `DATEVALUE`/`TIMEVALUE`, leading/trailing spaces trimmed; failure → `#VALUE!` "Function F parameter n expects number values. But 'abc' is a text and cannot be coerced to a number." | `TRUE`=1, `FALSE`=0 | 0 | propagate |
| text | shortest repr with ≤ 15 significant digits, `.`→locale decimal, no grouping, no format (`=1/3&""` → `0.333333333333333`) | itself | `TRUE`/`FALSE` | `""` | propagate |
| boolean | 0 → FALSE, else TRUE | `"TRUE"`/`"FALSE"` (case-insensitive) else `#VALUE!` | itself | FALSE | propagate |

Range-context rules (Sheets/Excel standard):

- **Aggregates over references/arrays** (`SUM`, `AVERAGE`, `MIN`, `MAX`, `PRODUCT`, `STDEV`, …):
  only numbers are used; text, booleans and blanks inside ranges are **ignored**; errors propagate.
  The `…A` variants (`AVERAGEA`, `COUNTA`, `MAXA`, …) count text as 0 and booleans as 0/1.
- **Direct scalar arguments** (`SUM("2", TRUE)` = 3): coerced; uncoercible text → `#VALUE!`.
- Array literals passed to aggregates behave like ranges (text ignored) — Google parity.
- A reference to an empty cell yields `FEmpty`, which becomes 0 or `""` depending on the
  consumer. `FEmpty` is a valid final result: `=A1` with an empty A1 renders **blank** (Sheets
  behavior; Excel would show 0), while `=A1+0` is 0 and `=A1&""` is `""`.

### 6.4 Comparison and ordering

- Type order for `<`, `>`, sorting and MATCH/LOOKUP approximate search: **numbers < text <
  booleans**; errors propagate in operators and are sorted after booleans in SORT (§07);
  blanks compare as `0`, `""` or `FALSE` depending on the other operand's type (`=A1=0`,
  `=A1=""` and `=A1=FALSE` are all TRUE for an empty A1).
- Text comparison is **case-insensitive** for operators and lookups (`"a"="A"` TRUE); `EXACT`,
  `FIND`, `REGEX*`, `SORT` tie-breaking are case-sensitive. Case-insensitive compare uses
  Unicode simple case folding plus ordinal compare of the folded strings (no locale collation in
  formulas; deterministic across platforms).
- Numeric equality uses a tolerance: `a == b || |a − b| ≤ 2⁻⁴⁹·max(|a|,|b|)` (≈ 1.8e-15
  relative), so `=0.1+0.2=0.3` is TRUE (Sheets/Excel parity). `<`/`>` apply the same tolerance
  (i.e., `a < b` iff `a < b` and not approximately equal).

### 6.5 Precision

- All numbers are IEEE-754 doubles; integers exact to 2⁵³.
- **Cancellation snapping** for `+`/`-` (Excel/LibreOffice `approxAdd`): if
  `|a ± b| ≤ 2⁻⁴⁹·max(|a|,|b|)` the result is exactly 0 (`=0.3-0.2-0.1` → 0).
- **Rounding functions** (`ROUND`, `ROUNDUP`, `ROUNDDOWN`, `MROUND`, `FIXED`, `DOLLAR`, `TEXT`)
  round the 15-significant-digit decimal representation (via `toStringAsPrecision(15)` then
  decimal arithmetic), so `ROUND(2.675, 2)` = 2.68 and `ROUND(1.005, 2)` = 1.01 as in Sheets.
- Display (General format) uses at most 15 significant digits; number→text coercion likewise.
- Overflow (`±Infinity`) and `NaN` never escape a function: they become `#NUM!`.
- Dates: serial days since 1899-12-30 (02); negative serials allowed (dates before 1899, Sheets
  parity); time is the fractional part; no Excel 1900 leap-year bug (serials ≥ 61 match Excel).

### 6.6 Errors

| Literal | `ErrorKind` | `ERROR.TYPE` | Typical cause / message (Sheets wording) |
|---------|-------------|--------------|-------------------------------------------|
| `#NULL!` | `nullRef` | 1 | Imported only (intersection not supported) |
| `#DIV/0!` | `div0` | 2 | "Function DIVIDE parameter 2 cannot be zero." |
| `#VALUE!` | `value` | 3 | Type mismatch; "Function ADD parameter 1 expects number values. But 'x' is a text and cannot be coerced to a number." |
| `#REF!` | `ref` | 4 | Deleted reference; "Reference does not exist."; "Circular dependency detected. To resolve with iterative calculation, see File > Settings."; "Unresolved sheet name 'X'." |
| `#NAME?` | `name` | 5 | "Unknown function: 'FOO'."; "Unknown range name: 'Sales'." |
| `#NUM!` | `num` | 6 | Invalid numeric domain, overflow, no convergence ("IRR could not find a result.") |
| `#N/A` | `na` | 7 | Lookup miss ("Did not find value 'x' in VLOOKUP evaluation."); wrong arg count; pending (`pending: true`, message "Loading…") |
| `#ERROR!` | `parse` | 8 | "Formula parse error." (with offset) |
| `#SPILL!` | `spill` | 9 | "Array result was not expanded because it would overwrite data in B3." |
| `#CALC!` | `calc` | 14 | Lambda as cell result; recursion limit. (Empty `FILTER` keeps Sheets' `#N/A` "No matches are found in FILTER evaluation.") |

Propagation: the first error encountered in **left-to-right argument order** is returned unless the
function handles errors (`IFERROR`, `IFNA`, `ISERROR`, `ISERR`, `ISNA`, `ERROR.TYPE`, `COUNT*`,
`AGGREGATE` options, `IF` on the untaken branch, `CHOOSE`/`SWITCH` unselected branches).
Messages are English strings produced from message keys (`ErrorMessages.unknownFunction(name)`)
and localized in the UI layer (P2).

---

## 7. Evaluation

### 7.1 Engine facade

```dart
final class FormulaEngine {
  FormulaEngine({
    required WorkbookView workbook,
    required FunctionRegistry registry,
    required EngineClock clock,                 // server-corrected time (§12)
    ExternalDataProvider? external,             // IMPORTRANGE, IMPORT*, AI
    CustomFunctionProvider? customFunctions,    // script custom functions (09-scripting §8.6)
    EngineConfig config = const EngineConfig(),
  });

  // ---- change ingestion (called by RecalcHost / server patcher) ----
  void cellsChanged(SheetId sheet, Iterable<CellKey> cells);   // content changed (local or remote)
  void axisChanged(SheetId sheet, Dimension dim, AxisChange change); // insert/delete/move/resize-length
  void sheetsChanged();                                        // add/remove/rename/reorder sheets
  void namesChanged(Set<String> names);
  void settingsChanged(CalcSettings settings);                 // locale, tz, iterative, recalcMode
  void filterVisibilityChanged(SheetId sheet);                 // SUBTOTAL/AGGREGATE hidden-row semantics

  // ---- reading ----
  ComputedValue valueAt(SheetId sheet, int row, int col);       // cached; dirty → evaluates on demand
  ComputedValue? peekValueAt(SheetId sheet, int row, int col);  // never evaluates (painting)
  OverlayCell? overlayAt(SheetId sheet, int row, int col);      // spill/pivot overlay content
  bool get isIdle;
  Stream<RecalcBatch> get changes;                              // changed cells per drain slice

  // ---- control ----
  RecalcBudgetResult drain(Duration budget, {Viewport? priority}); // cooperative scheduling (§10)
  Future<void> recalcAll({CancellationToken? cancel});
  void setViewport(SheetId sheet, GridRect visible);

  // ---- headless / preview ----
  FValue evaluate(String a1Formula, {required SheetId sheet, int row = 0, int col = 0});
  /// Rule formulas (CF/DV/filter custom formulas and `=` values, 06 §15.3, 07 §3.3): compile once
  /// relative to [anchor]; evaluate per cell with an offset. Registers a ConditionNode (§8.1).
  CompiledRelative compileRelative(String stored, CellPos anchor);
  /// Live preview while typing (03 §8.7): evaluates without registering the formula in the graph,
  /// aborts with null when [budget] is exceeded or > 1M cells would be read.
  ComputedValue? evaluateDetached(String a1Formula, {required CellPos at, Duration budget = const Duration(milliseconds: 50)});
  ExplainNode explain(SheetId sheet, int row, int col);
  DependencyInfo dependencies(SheetId sheet, int row, int col, {bool transitive = false});
}

final class ComputedValue { final FValue value; final FormatHint hint; final SpillInfo? spill; final bool stale; }
```

### 7.2 Compilation

- Parsed ASTs are compiled into **closure trees** (`typedef CompiledExpr = FValue Function(EvalContext)`),
  constant-folded where safe (literal arithmetic, non-volatile pure functions over literals).
  Closure compilation is 3–10× faster than AST walking on AOT and wasm and avoids a bytecode VM.
- **Templates**: most formula cells are fill-down copies. The compiler replaces every id token
  with a slot (`⟦#0⟧`, `⟦#1⟧`, …) to compute a *template key*; the compiled closure tree is shared
  across all cells with the same key, and each cell stores only its slot array
  (`List<RefSpec>`, interned ids). Cache: LRU of 50,000 templates (bounded memory).
- Function resolution happens at compile time (built-in index or named/custom function handle);
  unknown names compile to a `#NAME?` thunk but the name is recorded as a `NameDep` so defining
  the function/range later recompiles the dependents.

### 7.3 Evaluation context and argument kinds

```dart
final class EvalContext {
  final FormulaEngine engine;
  final SheetId hostSheet; final int hostRow, hostCol;
  bool arrayMode;                    // true inside ARRAYFORMULA / array-evaluated args
  LambdaEnv? env;                    // LET/LAMBDA bindings
  int callDepth;                     // recursion guard
  final DependencyRecorder deps;     // records dynamic deps (INDIRECT, OFFSET, unbound refs)
  final EngineClock clock; final DeterministicRandom rng;
}

enum ArgKind {
  scalar,      // single value; refs/arrays → implicit intersection (or lifting in array mode)
  number, text, boolean,             // scalar + coercion
  reference,   // must be a reference (ROW, COLUMN, OFFSET base, CELL, ISREF, ISFORMULA, SUBTOTAL ranges)
  range,       // reference or array, NOT lifted, not intersected (SUM, VLOOKUP table, COUNTIF range)
  array,       // argument expression evaluated in array mode, result as FArray (SUMPRODUCT, MMULT, FILTER cond)
  lambda,      // FLambda (MAP, REDUCE…)
  lazy,        // unevaluated thunk (IF, IFS, IFERROR, IFNA, SWITCH, CHOOSE, LET, AND/OR are NOT lazy)
  any,         // passes value as-is
}
```

### 7.4 Implicit intersection and ARRAYFORMULA lifting

Google Sheets semantics:

1. A **scalar** parameter that receives a multi-cell reference outside array mode uses
   **implicit intersection**: single cell → its value; single column whose rows include the host
   row → the cell in the host row; single row whose columns include the host column → the cell in
   the host column; otherwise `#VALUE!` "An array value could not be found." A multi-cell
   **array** (not a reference) in scalar position yields its top-left element.
2. In **array mode** (inside `ARRAYFORMULA(...)`, or a formula committed with `Mod+Shift+Enter`
   which wraps it in `ARRAYFORMULA`, or inside an `ArgKind.array` argument), scalar functions and
   operators are **lifted** element-wise:
   - Shapes broadcast: scalar × array → array; 1×n with m×1 → m×n; equal shapes element-wise;
     other mismatches → `#VALUE!` "Array arguments to ADD are of different size."
   - Lifting is per function: `FunctionSpec.liftable` (default true for scalar-only functions;
     false for aggregates, lookups, and functions with `range`/`array` params at that position).
3. Functions that inherently return arrays (`FILTER`, `SORT`, `UNIQUE`, `SEQUENCE`, `SPLIT`,
   `TRANSPOSE`, `MMULT`, `QUERY`, `IMPORTRANGE`, array literals, a bare multi-cell reference
   `=A1:B5`, …) **always spill**, with or without ARRAYFORMULA.
4. `ArgKind.array` parameters evaluate their argument expression in array mode even without
   ARRAYFORMULA — this is why `=SUMPRODUCT((A1:A10>5)*B1:B10)` works without wrapping (Sheets
   parity). Parameters declared `array`: all `SUMPRODUCT`/`SUMX2…` args, `MMULT`/`MINVERSE`/
   `MDETERM`, `FILTER` conditions, `SORT`/`SORTN` sort-by arrays, `INDEX` array, `MATCH`/`XMATCH`/
   `XLOOKUP` lookup and return arrays, `TEXTJOIN`/`JOIN` values, `FREQUENCY`, `LINEST` family,
   `TRANSPOSE`, `UNIQUE`, and the array arguments of `MAP`/`REDUCE`/`SCAN`/`BYROW`/`BYCOL`.
   Aggregate value arguments (`SUM`, `MAX`, `AVERAGE`, …) are `range`: references and arrays are
   accepted as-is, but an *expression* such as `A1:A3*2` is evaluated in the caller's mode, so
   `=SUM(A1:A3*2)` needs `ARRAYFORMULA` (implicit intersection otherwise) — the editor shows the
   Sheets-style hint "Did you mean ARRAYFORMULA?" with a one-click fix (`Mod+Shift+Enter`).
   Compatibility vectors must confirm this against Google Sheets (open question §25).
   `COUNTIF(S)`/`SUMIF(S)`/`AVERAGEIF(S)` criteria ranges must be references; an array →
   `#VALUE!` "Argument must be a range.".

### 7.5 Spilling and computed overlays

- A formula whose final value is `FArray` (or a multi-cell `FRef`) with more than one cell
  **spills**: the top-left element is the host cell's value; the others become **overlay cells**
  at `(hostRow + i, hostCol + j)` (02: overlays are computed, never stored).
- Spill target cells must be **empty of content** (formats, notes, DV are fine) and not covered by
  another overlay (spill or pivot). Otherwise the host shows `#SPILL!` "Array result was not
  expanded because it would overwrite data in <first blocking cell A1>." and no overlay is
  produced.
- **Deterministic collision rule** between two overlays (spill vs spill, spill vs pivot): the
  owner whose anchor is first in (sheet order, row index, column index) wins; the other gets
  `#SPILL!` (spill) or the pivot error state ([07 §7.6](07-data-tools.md)). Pivots and spills share
  the `OverlayIndex` (interval index of rectangles per sheet).
- Results are never clipped at the grid edge. Like Sheets, a result that does not fit within the
  grid yields `#REF!` "Result was not automatically expanded, please insert more rows (n)."
  (columns analogous). The error tooltip offers a one-click *Insert n rows* fix.
- Reading an overlay cell (`=B3` where B3 is inside A1's spill) depends on the **host**; the graph
  records an `OverlayDep(host)` edge.
- Editing a cell inside a spill area (typing content) blocks the spill → host becomes `#SPILL!`
  (the content is kept). Deleting the blocking content restores the spill.
- Grid display: overlay cells render with the host's computed per-element format hints and the
  overlay cell's own explicit format; formula bar shows the host formula in grey (03).

### 7.6 Names, lambdas and calls

- `NameExpr` resolution at compile time: LET/LAMBDA scope → named range (`FRef`) → named
  function used as a value (`FLambda`, allowed: `=MAP(A1:A3, TAX)`) → `#NAME?`.
- Named function call: arguments are evaluated per the LAMBDA's parameter list (all `any`;
  references are passed as references so `ROW(param)` works). Body evaluated with a new
  `LambdaEnv`; `callDepth` incremented; > 512 → `#CALC!`.
- Named function bodies are compiled once per definition; dependents of a named function have a
  `NameDep(fnName)` so redefinition recompiles them.
- Script custom functions (`ScriptBuild.exportsJson`) resolve after named functions; they are
  **async** and go through the pending protocol (§13.6).

---

## 8. Dependency graph

### 8.1 Nodes and identity

- A **node** is a formula cell `CellKey(sheetHandle, rowHandle, colHandle)` where handles are
  `int`s from `IdInterner` (UUID ⇄ int, never reused within a session). Other node kinds share the
  graph: `PivotNode(pivotId)`, `ConditionNode` (CF/DV/filter custom formulas, see 07 — evaluated
  lazily per visible cell, not stored per cell), `NamedFormulaNode(name)` (P2 non-LAMBDA named
  formulas).
- Identity is by **ids**, so inserting/moving rows never invalidates node keys; only positions
  change.

### 8.2 Edges

Each node stores its **precedents** as a compact list:

| Precedent kind | Recorded from | Reverse index |
|----------------|---------------|---------------|
| `CellDep(sheet,row,col)` | single-cell refs (static) | `HashMap<CellKey, NodeSet>` |
| `RangeDep(sheet, r1?, r2?, c1?, c2?)` (ids, null = open) | ranges, whole rows/cols, open-ended | `RangeIndex` per sheet (§8.3) |
| `OverlayDep(hostNode)` | reading cells inside a spill/pivot area | via `OverlayIndex` |
| `NameDep(name)` | named ranges/functions (incl. unknown names) | `HashMap<String, NodeSet>` |
| `SheetNamesDep` | unbound sheet refs, `INDIRECT`, `CELL("address")` with sheet | global set |
| `AxisDep(sheet, dim)` | position-sensitive functions (`ROW()`, `COLUMN()`, `ROWS`, `COLUMNS`, `ADDRESS`, `CELL`, `OFFSET`, unbound A1 refs) | per sheet set |
| `FilterDep(sheet)` | `SUBTOTAL`/`AGGREGATE` hidden-row modes | per sheet set |
| `VolatileDep` | `NOW`, `TODAY`, `RAND*` | global set |
| `ExternalDep(key)` | IMPORT*, AI, custom functions | `HashMap<ExternalKey, NodeSet>` |

**Dynamic dependencies** (`INDIRECT`, `OFFSET`, `INDEX` returning references used with `:`,
`CHOOSE`/`IF` returning references, `XLOOKUP` returning ranges) are recorded by the
`DependencyRecorder` during each evaluation and **replace** the node's previous dynamic edges
(static edges from the template stay).

### 8.3 Range index

```dart
abstract interface class RangeIndex {
  void add(NodeId node, RangeDep range);
  void remove(NodeId node, RangeDep range);
  /// All nodes whose range contains (row, col) — row/col are current indices.
  void stab(int row, int col, void Function(NodeId) sink);
  /// All nodes whose range intersects the rectangle (used for bulk edits, axis changes).
  void intersect(GridRect rect, void Function(NodeId) sink);
  /// Nodes having a range endpoint on one of [ids] (delete normalization §5.4).
  Iterable<NodeId> endpointsOn(Set<IdHandle> ids);
  void onAxisMoved(Dimension dim, Set<IdHandle> movedIds);   // re-sort affected entries
}
```

Implementation (v1):

- Per sheet: **whole-column** ranges in `Map<colHandle, NodeSet>` per covered column (bounded
  column spans of ≤ 64 columns are expanded; wider ones go to a column interval list), **whole-row**
  ranges likewise, and **bounded/open-ended** ranges in an **augmented interval tree over the row
  dimension** whose endpoints are row *ids* compared through `AxisView.indexOf` (with the `K:`
  fallback for missing endpoints). Each tree entry carries its column bounds; stab queries filter
  by column.
- Why ids with index comparison: inserting or deleting rows **preserves the relative order** of
  existing ids, so the tree stays valid without any update. Only **moves** change relative order;
  `onAxisMoved` removes and reinserts entries whose endpoints are among the moved ids (via an
  endpoint → entries map).
- Complexity: stab O(log n + k); add/remove O(log n). Memory ≤ 64 bytes per range dep.
- Bulk changes (paste of 100k cells) use `intersect` per changed rectangle (changes are coalesced
  into rectangles first), not per-cell stabs.

### 8.4 Used-range clamping

Open-ended and whole-column ranges are logically as long as the axis (up to 10M rows). Range
iteration clamps to the sheet's **used extent** (max row/col index with content or overlay,
maintained by `SheetView`; the model's `CellStore` keeps it incrementally from per-row and
per-column content counts, O(1) per edit and recomputed after structural changes), so `SUM(A:A)`
costs O(non-empty cells). Tall, narrow ranges (≥ 256 rows, ≤ 8 columns) are read through dense
per-column caches of the cell inputs by row index (valid for the row order and the column's
content version), not through per-cell id lookups. Spilled whole-column results
(`=A:A`, `=ARRAYFORMULA(A:A*2)`) logically have the full axis length (Sheets parity: the spill
area reaches the last row, so typing below the data blocks the spill), but `FArray` storage is a
**sparse/lazy array** (`LazyArray` subclass of `FArray` with an element function over the used
extent; elements beyond it are `FEmpty` and cost nothing).

---

## 9. Recalculation

### 9.1 Dirty marking (push)

On `cellsChanged(cells)`:

1. Recompile changed formula cells (template lookup); update their static edges.
2. Collect **direct dependents**: `CellDep` reverse index ∪ `RangeIndex.stab`/`intersect` ∪
   overlay hosts whose spill area contains a changed cell (spill may now be blocked/unblocked).
3. Mark them and their transitive dependents **dirty** (iterative BFS with a visited bitset;
   dirty flags live in a `Uint8List` per sheet indexed by node slot).
4. Changed spill/pivot extents dirty dependents of both the old and the new overlay rectangle.

`axisChanged(sheet, dim, change)`:

- **Insert at k (n items)**: dirty nodes whose `RangeDep` spans position k (their coverage grew),
  all `AxisDep(sheet, dim)` nodes, and overlay hosts whose area crosses k (spill collision may
  change). No rewrite, no edge changes.
- **Delete**: as insert, plus nodes with `CellDep` on deleted ids (→ `#REF!`) and endpoint-fallback
  ranges.
- **Move**: `RangeIndex.onAxisMoved`; dirty nodes whose ranges' coverage changed (entries
  re-inserted) plus `AxisDep` nodes.
- Example: `SUM(A1:A10)` includes a row inserted at position 5 automatically because the new row's
  id is between the endpoint ids in axis order; the node is dirtied because its range spans the
  insertion point (its value is unchanged unless the row gets content, but `COUNTBLANK`/`ROWS`
  change).

### 9.2 Evaluation order (drain)

- The scheduler keeps the dirty set partitioned by priority (§10.1). Within a batch it computes a
  **topological order of the dirty subgraph** with Kahn's algorithm (in-degree counted only over
  dirty precedents). Nodes left over (non-zero in-degree) belong to cycles → Tarjan SCC (§9.4).
- Evaluating a node: run the compiled closure; precedents are guaranteed clean (topological) except
  **dynamic** precedents discovered during evaluation; if a dynamic precedent is dirty, the node is
  re-queued after it (`NeedsPrecedent` signal, implemented as a sentinel return value, not an
  exception) — evaluation is restartable because functions are pure.
- **Pull evaluation** for `valueAt` on a dirty node (viewport painting, MCP reads): compute the
  dirty-precedent closure via static edges, evaluate it in topological order iteratively (no deep
  recursion: a 1M-long chain `=A1+1` down a column must not overflow the stack), then the node.
- Value change detection: a node whose new value equals the old (`identical` type + value +
  hint) does **not** dirty its dependents further during the same drain if they were dirtied only
  through it (early cut-off; tracked with per-node "changed" bits).

### 9.3 Volatile functions and recalculation modes

| Function | Volatile | Recomputed when |
|----------|----------|------------------|
| `NOW`, `TODAY` | yes | every committed change in the spreadsheet (local or remote batch), plus timer per `recalcMode`, plus local midnight in `Spreadsheet.timeZone` for TODAY |
| `RAND`, `RANDBETWEEN`, `RANDARRAY` | yes | same as NOW (new seed epoch, §12) |
| `INDIRECT`, `OFFSET` | no (dynamic deps) | precedents change; `INDIRECT` also on `SheetNamesDep`/`NameDep` |
| `CELL` (address/col/row/width) | no | `AxisDep`; `CELL("width")` on column width change |
| IMPORT*, AI, custom functions | no (async) | args change; refresh timer (§13); new script build |

`Spreadsheet.recalcMode` ([02 §3.1](02-data-model.md)): `onChange` (default),
`onChangeAndEveryMinute`, `onChangeAndEveryHour` add a timer that dirties `VolatileDep` nodes.
Timer ticks are aligned to wall-clock boundaries (`floor(now/60s)`) so every client recomputes at
the same epoch (§12).

### 9.4 Circular references and iterative calculation

- Cycles are detected per drain with Tarjan SCC on the dirty subgraph (plus dynamic edges).
  Self-loops (`A1: =A1+1`) are SCCs of size 1.
- *Implementation note:* `FormulaEngine` evaluates depth-first with an explicit work stack (no
  recursion), detects a cycle when a node on the evaluation chain is re-entered, and then runs an
  iterative Tarjan only over that node's component (static + dynamic precedents, spill hosts,
  limited to nodes of the current pass). The visible results are those described here; references
  in untaken branches (`IF(c, ref, …)`) count as edges.
- `Spreadsheet.iterativeCalc == false`: every node in a cyclic SCC gets `#REF!` "Circular
  dependency detected. To resolve with iterative calculation, see File > Settings." Dependents of
  the SCC receive the error by propagation.
- `iterativeCalc == true`: SCCs are evaluated in topological order of the condensation. For each
  SCC: nodes ordered deterministically (sheet order, row index, column index); initial values =
  previous computed values (0/empty if none); repeat Gauss–Seidel sweeps until
  `max |Δ| < convergenceThreshold` (numeric nodes; non-numeric change counts as ∞) or
  `maxIterations` sweeps reached. Final values are those of the last sweep (no error, Sheets
  behavior). Each recalculation of the SCC starts from the previous values, so `A1: =A1+1`
  increments by `maxIterations` per recalculation (Excel/Sheets behavior).
- Settings UI and commands live in File › Settings › Calculation (owned by
  [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md)); changing them calls
  `settingsChanged` which dirties all cyclic SCC members.

---

## 10. Scheduling and threading

### 10.1 Priorities

| Priority | Work |
|----------|------|
| P-0 (sync, same frame) | Pull evaluation of the edited cell(s) so the committed cell shows its value immediately |
| P-1 | Dirty nodes in the current viewport (+ 1 screen margin) and their dirty precedents |
| P-2 | Dirty nodes feeding visible objects: charts, pivots, CF/DV/filter conditions of visible rows, slicers |
| P-3 | Dirty nodes on the active sheet |
| P-4 | Everything else (other sheets), then ComputedValueCache persistence |

### 10.2 Decision: engine on the UI isolate with cooperative time-slicing

The engine runs **on the UI isolate on both web and native**, driven by `RecalcHost`'s
`TimeSlicer`:

- After each frame (`SchedulerBinding.addPostFrameCallback`) and on idle (`Timer.run` loop), call
  `engine.drain(budget)` with **budget = 6 ms** when idle, **2 ms** while the user is scrolling,
  dragging or typing (input in the last 200 ms), and **unbounded** for P-0.
- The scheduler checks a `Stopwatch` every 64 node evaluations; a single expensive node (e.g.
  `SORT` over 500k rows) cannot be interrupted and may exceed the budget — such functions are
  marked `FunctionSpec.cost: heavy` and the scheduler starts them only at the beginning of a
  slice.
- While dirty work remains, the status bar shows a thin progress indicator ("Calculating…
  12,400 cells left") after 500 ms; affected cells paint their **previous value in grey italics**
  (`ComputedValue.stale`) or `Loading…` when no previous value exists.

Justification:

| Option | Verdict |
|--------|---------|
| Engine in a background isolate (native) / Web Worker (web) | Rejected for v1. Isolates share no memory: the 10M-cell model would have to be **duplicated** in the worker (2× memory) and every local and remote edit serialized across; viewport reads become async (grid painting needs synchronous access). On web, workers also need a separate compiled entrypoint and cannot share the OPFS connection with the UI thread's DB layer cheaply. |
| UI isolate, time-sliced | **Chosen.** Single source of truth (`WorkbookModel`), synchronous viewport reads, no serialization, simplest determinism. Interactive cost bounded by the slice budget; incremental recalc is usually ≪ 1 frame. |
| UI isolate + offload of bulk pure jobs | **Chosen in addition** (§10.3) for operations over column snapshots that are naturally isolated. |

P2 (desktop only, if profiling demands): `EngineIsolate` mode for spreadsheets > 2M formula cells
— full engine + model mirror in a worker isolate, UI keeps a viewport value cache. The
`FormulaEngine` API above is designed so `RecalcHost` can switch implementations.

### 10.3 Offload jobs

`ComputeOffload.run(job)` runs **pure** jobs on immutable column snapshots
(`Float64List` numbers + `Uint8List` type tags + interned string table, transferred with
`TransferableTypedData` on native / transferable `ArrayBuffer`s on web):

| Job | Threshold for offloading |
|-----|--------------------------|
| Sort permutation ([07 §2](07-data-tools.md)) | > 50k rows |
| Filter visibility mask ([07 §3](07-data-tools.md)) | > 100k rows |
| Pivot aggregation ([07 §7](07-data-tools.md)) | > 100k source rows |
| Column stats, remove duplicates, find-all | > 100k cells |
| Initial full recalc of sheets with no cache | never offloaded (needs graph); time-sliced |

Native: `Isolate.run`. Web: a dedicated **Web Worker** compiled from
`wonky_sheets_core/bin/compute_worker.dart` (`dart compile js -O4`, shipped as
`web/sheets/compute_worker.js`); P1 — until it lands, web runs the same jobs time-sliced on the
UI thread (jobs are written as resumable chunked loops over `CancellationToken` + yield points).
Every job supports cancellation and progress callbacks.

### 10.4 Server

The server never runs a full recalc on load. `HeadlessEngineService` evaluates **on demand**
(pull) only the cells requested by MCP/scripts/exports and their precedents; values stay cached
while the workbook is in the LRU; committed ops applied to the cached model dirty affected nodes. Exports
(XLSX cached values, PDF) trigger a full recalc in a server isolate with a 60 s budget.

---

## 11. Caching and memory

### 11.1 ComputedValueCache (02 §4)

- Written by `RecalcHost` when the engine is idle (debounced 5 s, chunked transactions of 5,000
  rows), only for formula cells and spill hosts; `valueJson` is a compact encoding:
  `{"n":42.5,"h":"date"}`, `{"s":"x"}`, `{"b":1}`, `{"e":"#N/A","m":"…"}`, spill host:
  `{"a":[[…],[…]],"h":[…]}` (arrays > 10k cells are not cached).
- On open: cache rows with matching `engineVersion` and the spreadsheet's cached **data stamp**
  (`ComputedValueCacheMeta.dataStamp` = the file revision the cache holds plus the number of
  outbox ops, addition §24) are loaded as `stale: false` values → instant first paint. If the stamp differs, values load
  as `stale: true` (shown normally, recalculated in the background in viewport-first order).
- Volatile nodes are always dirtied on open.

### 11.2 Lookup and criteria caches

To avoid O(n²) patterns (`VLOOKUP` / `COUNTIF` filled down 100k rows):

| Cache | Key | Content | Invalidation |
|-------|-----|---------|--------------|
| `ExactMatchIndex` | (resolved column area, case mode) | `HashMap<normalizedValue, firstIndex>` + optional all-indices | per-column generation counter (bumped on any content/computed change in that column) |
| `SortedIndex` | (column area) | sorted (value, index) array for approximate MATCH/VLOOKUP/XLOOKUP binary search | generation |
| `CriteriaCount` | (range area, criteria string) | count/sum results for `COUNTIF/SUMIF/AVERAGEIF` single-criterion | generation of range + sum range |
| `ParsedCriteria` | criteria string | compiled matcher (operator, value, wildcard regex) | never (LRU) |
| Compiled rule formula (`EngineFormulaHooks`) | (stored formula, sheet, anchor) | `CompiledRelative`: template and slots of a CF/DV/filter formula, evaluated per cell with offsets | none needed: a changed rule has another text (512 entries, oldest dropped) |

Built lazily on the second use within a drain (first use scans linearly). Total cache memory
capped at 64 MB (LRU eviction).

### 11.3 Memory budget (native / web)

| Item | Budget |
|------|--------|
| Graph per formula node (edges, flags, slot array) | ≤ 96 bytes average |
| Range index per range dep | ≤ 64 bytes |
| Computed scalar value | ≤ 16 bytes (columnar `Float64List` + tag byte + string table index) |
| Template cache | ≤ 32 MB |
| Total engine overhead for 1M formula cells | ≤ 200 MB native, ≤ 250 MB web |

---

## 12. Determinism

Same `engineVersion` + same file state ⇒ identical values on every client and on the server:

- No locale/platform-dependent APIs in evaluation: number parsing/formatting uses the
  spreadsheet locale tables bundled in core (not the OS); text case folding is
  Unicode-table-based; `SORT()`/`SORTN()` order text with the shared `Collation` of
  [07](07-data-tools.md) §2.3 (the same order as Data › Sort).
- `Math` functions: Dart's `dart:math` maps to platform libm on native and JS `Math` on web, which
  can differ in the last ulp for `sin`, `exp`, `pow`, `log`. Results are passed through
  `stabilize(x)` = round to 15 significant digits **only for transcendental functions** (`EXP`,
  `LN`, `LOG*`, `POWER` with non-integer exponent, trig/hyperbolic, distributions), which removes
  last-ulp differences while staying within Sheets' display precision.
- **Clock**: `EngineClock.now()` = device time + server offset (measured on each connection),
  truncated to whole seconds; time zone = `Spreadsheet.timeZone` (IANA, via
  `timezone` package).
- **Randomness**: `RAND()` in cell X = `splitmix64(hash(spreadsheetId, cellId, callIndex,
  epoch))`, where `epoch = (the file revision the client has applied, minute/hour bucket if a
  timer recalc mode is set)`. Revisions are assigned by the server, so all clients at the same
  revision compute the same random numbers; any edit produces a new revision (fresh values),
  matching the user-visible behavior of Sheets. Unsent local edits use a provisional epoch (the
  revision plus the number of outbox ops). **As built:** the client engine uses its own change
  counter (`FormulaEngine.randomEpoch`; `setRandomEpoch` is not called), so `RAND` values agree
  within one device only.
- Iteration order everywhere (SCCs, spill collision, pivot output) is defined by (sheet order,
  row index, column index), never by hash-map order.
- `engineVersion` (semver string constant in core) is stored with cached values; minor behavior
  fixes bump it and invalidate caches.

---

## 13. Async and external data

### 13.1 Pending protocol

Functions that need data the engine cannot compute synchronously (`IMPORTRANGE`, `IMPORTDATA`,
`IMPORTHTML`, `IMPORTXML`, `IMPORTFEED`, `AI`, script custom functions) implement
`AsyncFunction`:

```dart
abstract interface class ExternalDataProvider {
  /// Returns a cached result if present (fresh or stale), else schedules a fetch and returns null.
  ExternalResult? lookup(ExternalKey key);
  void request(ExternalKey key, ExternalRequest req);
  Stream<ExternalKey> get updates;                     // engine dirties ExternalDep(key) nodes
}
final class ExternalKey { final String function; final String argsHash; }   // normalized args
```

- If no result is cached, the function returns `FError(na, pending: true, "Loading…")`; the cell
  renders "Loading…" (muted italic). Pending values propagate to dependents like errors, but are
  **not caught** by `IFERROR`/`IFNA`/`ISERROR` (dependents "wait", 09 §8.6); `ERROR.TYPE` → 7.
  When the result arrives the provider emits `updates`, the engine dirties `ExternalDep` nodes.
- Results are cached in a client-local table `ExternalResultCache` (**addition**, §24) so they are
  available offline and across reloads; offline with no cache → `#N/A` "This function needs an
  internet connection." (no fetch attempted until online).
- Determinism: external results come from server-side caches keyed by the same `ExternalKey`, so
  all clients see the same snapshot.

### 13.2 Server endpoint

`SheetsExternalEndpoint` (`sheetsExternal`): `importRange(destSpreadsheetUuid, sourceRef,
rangeA1)`, `grantImportRange(destSpreadsheetUuid, sourceItemUuid)`, `fetch(kind, url, params)`,
`aiEvaluate(spreadsheetUuid, cellRef, prompt, inputsJson)`. All require at least viewer access to
the destination spreadsheet.

### 13.3 IMPORTRANGE

`IMPORTRANGE(spreadsheet_url_or_id, range_string)` — source is a Wonky spreadsheet identified by
its URL (`https://<host>/sheets/d/<uuid>` or any route containing the item uuid) or the bare uuid;
`range_string` like `"Sheet1!A1:C10"` or a named range.

- **Permission grant (Sheets parity)**: the first time a destination imports from a source, the
  cell shows `#REF!` "You need to connect these sheets." with an **Allow access** button in the
  error tooltip (command `sheets.formula.allowImportRange`). Only an editor of the destination who
  has at least viewer access to the source may grant. Grant stored server-side in
  `ImportRangeGrant(destSpreadsheetUuid, sourceItemId, grantedByUserId, at)` (Postgres).
  Afterwards anyone who can view the destination sees the imported data (even without source
  access) — same as Sheets.
- Values are computed by the server's `HeadlessEngineService` on the source and returned as a
  values array with format hints (max 10M cells/request is far above limits; practical cap 500k
  cells → `#REF!` "Result too large").
- Refresh: on open, every 5 minutes while the destination is open and online, and immediately
  when the server signals source changes (`sheetsExternal` change channel driven by the source's
  post-commit hooks, suite 17 part 5 §6, debounced 30 s).
- Errors: source missing/trashed → `#REF!` "Spreadsheet not found."; access revoked from granter
  → grant invalidated, `#REF!` "You don't have permissions to access that sheet."

### 13.4 IMPORTDATA, IMPORTHTML, IMPORTXML, IMPORTFEED (P2) and IMAGE

Fetched by the **server fetch proxy** (`FetchProxyService`), never by clients directly (CORS,
privacy, SSRF):

- Only `http`/`https`, ports 80/443; DNS resolved server-side and the connection **pinned** to the
  resolved IP; deny private, loopback, link-local, CGNAT, multicast and metadata ranges (IPv4 and
  IPv6, incl. `169.254.169.254`, `fd00::/8`); redirects ≤ 5, each re-validated; response ≤ 10 MB;
  timeout 10 s; `User-Agent: WonkySheets-Fetcher/1.0`.
- Server cache `ExternalFetchCache(urlHash, kind, paramsHash, fetchedAt, status, payload)` with
  TTL 1 hour (Sheets refreshes hourly); per-spreadsheet limit of 50 distinct URLs per hour and
  per-user 500/hour.
- Parsing in core (`functions/web/`): CSV/TSV (IMPORTDATA), HTML tables/lists (IMPORTHTML via
  `package:html`-free minimal parser in core — or server-side `html` package; decision: parse on
  server, return `FArray`), XPath 1.0 subset (IMPORTXML, `xml` package + XPath evaluator P2),
  RSS/Atom (IMPORTFEED P2).
- `IMAGE(url, [mode], [height], [width], [alt_text])` returns `FRich(ImageValue)` without any
  fetch in the engine (it is synchronous; image bytes are loaded by the painter). Rules owned by
  [08 §10.2](08-charts-and-objects.md): `wonky-file://<fileUuid>` resolves via the files service,
  `https://` loads through the server image proxy `/files/proxy?url=…` (same SSRF guard as above,
  cached 24 h, ≤ 10 MB); disallowed hosts (private IPs) → `#REF!` "Image URL not allowed". The
  5th `alt_text` argument is a Wonky extension (P1).

### 13.5 AI and language functions (P2)

- `AI(prompt, [range])` (Google's 2025 function): evaluated on the server by
  `AiFunctionService` using `claude-haiku-5-5` (suite [10-ai-assistant.md](../10-ai-assistant.md)),
  result text cached in `AiFunctionResult(spreadsheetUuid, cellId, inputHash, text, at)`
  (Postgres) so every client sees the same output; not volatile. A cell's result regenerates only
  when its inputs change **and** the user confirms (*Refresh* in the cell tooltip, or command
  `sheets.formula.refreshAi`). Bulk fills over 200 AI cells ask for confirmation. Requires AI
  enabled (server & user); otherwise `#NAME?` "AI functions are disabled."
- `GOOGLETRANSLATE(text, [source], [target])` and `DETECTLANGUAGE(text)` are kept as names for
  import compatibility and implemented through the same AI service (P2); before P2 they return
  `#NAME?` "GOOGLETRANSLATE isn't available in Wonky Sheets yet."
- `GOOGLEFINANCE` → `#NAME?` "GOOGLEFINANCE isn't available in Wonky Sheets." (formula text is
  preserved for round-tripping).

### 13.6 Script custom functions

Custom functions exported by the bound script are specified in
[09-scripting.md §8.6](09-scripting.md) (authoritative for execution, batching, time limits —
3 s per call — caching and errors). The engine side:

- `FormulaEngine` takes a `CustomFunctionProvider` (interface defined in 09 §8.6: `has`, `help`,
  `lookup`) as its `customFunctions` parameter; `CustomFunctionLayer` in the registry resolves
  names after built-ins and named functions (built-ins shadow custom functions).
- `lookup` returning null ⇒ pending value (§13.1) and an `ExternalDep(custom:<name>:<argsHash>)`
  edge; misses of one drain are batched by the provider.
- Range arguments are converted per 09 (2-D lists, row-major); array returns spill (§7.5).
- `FunctionHelp` for autocomplete/signature help comes from `help(name)` (built from
  `ScriptBuild.exportsJson`).
- A new `ScriptBuild` (different `sourceHash`) dirties every node with a custom-function edge.

---

## 14. Function registry

### 14.1 Types

```dart
enum FunctionCategory {
  math, statistical, lookup, logical, text, dateTime, financial, info, array, filter,
  database, engineering, parser, operator, web, google, lambdaHelper,
}
enum ReturnKind { scalar, array, reference, lambda, rich }
enum FunctionCost { light, heavy }          // heavy: may scan > 100k cells (scheduler hint)
enum Priority { p0, p1, p2 }

final class ArgSpec {
  final String name;                        // "search_key" (Sheets naming, snake_case)
  final ArgKind kind;                       // §7.3
  final bool optional;
  final Object? defaultValue;               // documented default (e.g. is_sorted = TRUE)
  final bool repeatable;                    // part of the trailing repeat group
}

final class FunctionSpec {
  final String name;                        // canonical upper case, may contain '.' and '_'
  final List<String> aliases;               // e.g. legacy/compat names mapping to same impl
  final FunctionCategory category;
  final List<ArgSpec> params;
  final int minArgs;
  final int maxArgs;                        // 255 when variadic
  final int repeatGroupSize;                // SUMIFS = 2, IFS = 2, SWITCH = 2, CHOOSECOLS = 1 …
  final ReturnKind returns;
  final bool liftable;                      // element-wise lifting in array mode (§7.4)
  final bool volatile;
  final bool positionSensitive;             // records AxisDep (ROW(), COLUMN(), ADDRESS…)
  final bool usesFilterVisibility;          // SUBTOTAL/AGGREGATE → FilterDep
  final bool async;                         // pending protocol (§13)
  final FunctionCost cost;
  final Priority priority;
  final FunctionImpl impl;                  // FValue Function(EvalContext ctx, ArgValues args)
  final FunctionHelp help;
}

final class FunctionHelp {
  final String summary;                     // one sentence (autocomplete, MCP description)
  final String syntax;                      // "VLOOKUP(search_key, range, index, [is_sorted])"
  final List<ArgHelp> args;                 // name + description (+ "optional, default TRUE")
  final List<String> examples;              // A1 formulas in en_US form
  final List<String> seeAlso;
  final String? notes;                      // Sheets-specific remarks
  final String? learnMoreSlug;              // docs page anchor
}
```

### 14.2 Sources and code generation

- Implementation: one Dart file per function family in
  `lib/formula/functions/<category>/<family>.dart` (e.g. `math/rounding.dart` holds ROUND,
  ROUNDUP, ROUNDDOWN, MROUND, CEILING*, FLOOR*, INT, TRUNC, EVEN, ODD), each exporting a
  `void register<Family>(FunctionRegistryBuilder b)`.
- Help metadata (reviewed text written for humans **and** LLMs) is declared **inline** with each
  registration (summary, syntax, argument descriptions, examples). The YAML + codegen pipeline
  sketched below was not adopted; instead `test/formula/services/catalog_test.dart` fails if an
  implemented function lacks complete help, if an example does not parse, or if a §15 name is not
  registered. The YAML below shows the content each entry carries.

```yaml
# tool/function_docs/lookup.yaml
VLOOKUP:
  summary: Vertical lookup. Searches down the first column of a range for a key and returns the value of a specified cell in the row found.
  syntax: VLOOKUP(search_key, range, index, [is_sorted])
  args:
    search_key: The value to search for. For example, 42, "Cats", or I24.
    range: The range to consider for the search. The first column in the range is searched for the key.
    index: The column index of the value to be returned, where the first column in range is numbered 1.
    is_sorted: "[optional, TRUE by default] Whether the column to be searched is sorted. FALSE is recommended: exact match."
  examples: ["VLOOKUP(10003, A2:B26, 2, FALSE)"]
  seeAlso: [XLOOKUP, HLOOKUP, INDEX, MATCH]
```

- Registration:

```dart
void registerRounding(FunctionRegistryBuilder b) {
  b.fn('ROUND', [num('value'), num('places', optional: true, defaultValue: 0)],
      priority: Priority.p0,
      impl: (ctx, a) => FNumber(Numeric.roundHalfAway(a.number(0), a.intOr(1, 0))));
}
```

- `FunctionRegistry` is immutable after build; lookup by canonical name and aliases is a single
  `HashMap`. Dynamic layers on top (per spreadsheet): `NamedFunctionLayer` (from `NamedRange`
  rows), `CustomFunctionLayer` (from `ScriptBuild.exportsJson`). Resolution order: built-in →
  named function → custom function → `#NAME?`. Named/custom functions cannot use built-in names
  (validation in their editors).
- **Known-unsupported** entries (`GOOGLEFINANCE`, Excel-only `CUBE*`, `WEBSERVICE`, `RTD`,
  `INFO`, …) are registered as stubs with a specific `#NAME?` message so imported formulas
  round-trip and users get a clear explanation instead of "Unknown function".
- Build gating: functions are registered regardless of priority, but P1/P2 functions that are not
  implemented yet register as stubs returning `#NAME?` "X isn't available in Wonky Sheets yet."
  and are hidden from autocomplete (flag `implemented: false`).

### 14.3 Consumers of the registry

| Consumer | Uses |
|----------|------|
| Compiler | name → impl, arg kinds, lift/volatile/position flags |
| Autocomplete / signature help / function help card ([§18](#18-formula-help-ui-data)) | `FunctionHelp`, params |
| Insert › Function menu | categories (P0/P1 functions grouped; "All" submenu alphabetical) |
| MCP `sheets.list_functions` / `sheets.get_function_help` | JSON export of specs + help |
| AI assistant | compact catalog (name + syntax + summary) in the system prompt cache prefix |
| XLSX/ODS import/export ([11](11-import-export-print.md)) | `_xlfn.` prefix mapping, compat names |

---

## 15. Function catalog

Legend: **P** = priority (P0 first Sheets release M3; P1 parity wave; P2 later). Syntax follows
Google Sheets naming; `[x]` optional, `…` repeatable. "Sheets:" notes describe behavior that
differs from Excel and must be honored. Unless stated otherwise: numeric args are coerced (§6.3),
range args ignore text/booleans/blanks, errors propagate (§6.6), results are scalar.

### 15.1 Math & trigonometry

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| ABS | `ABS(value)` | Absolute value | P0 | |
| ACOS | `ACOS(value)` | Inverse cosine (radians) | P1 | \|value\|>1 → `#NUM!` |
| ACOSH | `ACOSH(value)` | Inverse hyperbolic cosine | P1 | value<1 → `#NUM!` |
| ACOT | `ACOT(value)` | Inverse cotangent | P1 | |
| ACOTH | `ACOTH(value)` | Inverse hyperbolic cotangent | P1 | \|value\|≤1 → `#NUM!` |
| ASIN | `ASIN(value)` | Inverse sine | P1 | |
| ASINH | `ASINH(value)` | Inverse hyperbolic sine | P1 | |
| ATAN | `ATAN(value)` | Inverse tangent | P1 | |
| ATAN2 | `ATAN2(x, y)` | Angle of point (x,y) from x-axis | P1 | Excel arg order (x first); (0,0) → `#DIV/0!` |
| ATANH | `ATANH(value)` | Inverse hyperbolic tangent | P1 | |
| BASE | `BASE(value, base, [min_length])` | Number → text in base 2–36 | P1 | |
| CEILING | `CEILING(value, [factor])` | Round up to multiple of factor | P0 | Sheets: factor default 1; negative value with positive factor rounds toward 0; opposite signs with positive value → `#NUM!` |
| CEILING.MATH | `CEILING.MATH(number, [significance], [mode])` | Round up, mode controls negatives | P1 | |
| CEILING.PRECISE | `CEILING.PRECISE(number, [significance])` | Round up regardless of sign of significance | P1 | |
| ISO.CEILING | `ISO.CEILING(number, [significance])` | Same as CEILING.PRECISE | P2 | |
| COMBIN | `COMBIN(n, k)` | Combinations | P1 | args truncated |
| COMBINA | `COMBINA(n, k)` | Combinations with repetition | P1 | |
| COS | `COS(angle)` | Cosine | P0 | |
| COSH | `COSH(value)` | Hyperbolic cosine | P1 | |
| COT | `COT(angle)` | Cotangent | P1 | 0 → `#DIV/0!` |
| COTH | `COTH(value)` | Hyperbolic cotangent | P1 | |
| CSC | `CSC(angle)` | Cosecant | P1 | |
| CSCH | `CSCH(value)` | Hyperbolic cosecant | P1 | |
| DECIMAL | `DECIMAL(value, base)` | Text in base → number | P1 | |
| DEGREES | `DEGREES(angle)` | Radians → degrees | P0 | |
| EVEN | `EVEN(value)` | Round away from 0 to even integer | P1 | |
| EXP | `EXP(exponent)` | e^x | P0 | |
| FACT | `FACT(value)` | Factorial | P1 | >170 → `#NUM!` |
| FACTDOUBLE | `FACTDOUBLE(value)` | Double factorial | P1 | |
| FLOOR | `FLOOR(value, [factor])` | Round down to multiple | P0 | Sheets rules mirror CEILING |
| FLOOR.MATH | `FLOOR.MATH(number, [significance], [mode])` | Round down, mode for negatives | P1 | |
| FLOOR.PRECISE | `FLOOR.PRECISE(number, [significance])` | Round down regardless of sign | P1 | |
| GAMMALN | `GAMMALN(value)` | ln Γ(x) | P1 | |
| GAMMALN.PRECISE | `GAMMALN.PRECISE(value)` | ln Γ(x) | P1 | alias impl |
| GCD | `GCD(value1, [value2, …])` | Greatest common divisor | P1 | |
| INT | `INT(value)` | Round down to integer | P0 | toward −∞ |
| LCM | `LCM(value1, [value2, …])` | Least common multiple | P1 | |
| LN | `LN(value)` | Natural log | P0 | ≤0 → `#NUM!` |
| LOG | `LOG(value, [base])` | Log, base default 10 | P0 | |
| LOG10 | `LOG10(value)` | Base-10 log | P0 | |
| MOD | `MOD(dividend, divisor)` | Remainder | P0 | Sign of divisor; divisor 0 → `#DIV/0!` |
| MROUND | `MROUND(value, factor)` | Round to nearest multiple | P1 | different signs → `#NUM!` |
| MULTINOMIAL | `MULTINOMIAL(value1, [value2, …])` | Multinomial coefficient | P2 | |
| MUNIT | `MUNIT(dimension)` | Identity matrix | P1 | array |
| ODD | `ODD(value)` | Round away from 0 to odd integer | P1 | |
| PI | `PI()` | π | P0 | |
| POWER | `POWER(base, exponent)` | Power | P0 | = `^` |
| PRODUCT | `PRODUCT(factor1, [factor2, …])` | Product | P0 | |
| QUOTIENT | `QUOTIENT(dividend, divisor)` | Integer division (truncate) | P1 | |
| RADIANS | `RADIANS(angle)` | Degrees → radians | P0 | |
| RAND | `RAND()` | Uniform [0,1) | P0 | volatile, deterministic seed §12 |
| RANDARRAY | `RANDARRAY([rows], [columns])` | Array of RAND | P1 | Sheets signature; Excel's `min,max,integer` extras accepted (P2) |
| RANDBETWEEN | `RANDBETWEEN(low, high)` | Random integer | P0 | volatile; low/high ceiling/floor |
| ROUND | `ROUND(value, [places])` | Round half away from 0 | P0 | decimal-correct §6.5; negative places allowed |
| ROUNDDOWN | `ROUNDDOWN(value, [places])` | Round toward 0 | P0 | |
| ROUNDUP | `ROUNDUP(value, [places])` | Round away from 0 | P0 | |
| SEC | `SEC(angle)` | Secant | P1 | |
| SECH | `SECH(value)` | Hyperbolic secant | P1 | |
| SEQUENCE | `SEQUENCE(rows, [columns], [start], [step])` | Array of sequential numbers | P0 | spills |
| SERIESSUM | `SERIESSUM(x, n, m, a)` | Power series sum | P2 | |
| SIGN | `SIGN(value)` | −1/0/1 | P0 | |
| SIN | `SIN(angle)` | Sine | P0 | |
| SINH | `SINH(value)` | Hyperbolic sine | P1 | |
| SQRT | `SQRT(value)` | Square root | P0 | <0 → `#NUM!` |
| SQRTPI | `SQRTPI(value)` | √(x·π) | P1 | |
| SUBTOTAL | `SUBTOTAL(function_code, range1, [range2, …])` | Aggregate ignoring nested SUBTOTALs | P0 | codes 1–11 (AVERAGE, COUNT, COUNTA, MAX, MIN, PRODUCT, STDEV, STDEVP, SUM, VAR, VARP) ignore **filter-hidden** rows (basic filter/slicers only — not filter views, §07); 101–111 also ignore user-hidden and group-collapsed rows; `usesFilterVisibility` |
| AGGREGATE | `AGGREGATE(function_num, options, ref1, [ref2, …])` | Excel aggregate with error/hidden options | P1 | Excel compat (19 functions, options 0–7) |
| SUM | `SUM(value1, [value2, …])` | Sum | P0 | |
| SUMIF | `SUMIF(range, criterion, [sum_range])` | Conditional sum | P0 | criteria syntax §15.14; sum_range resized to range's shape from its top-left (Excel/Sheets) |
| SUMIFS | `SUMIFS(sum_range, criteria_range1, criterion1, [criteria_range2, criterion2, …])` | Multi-criteria sum | P0 | ranges must be same size → `#VALUE!` "Array arguments to SUMIFS are of different size." |
| SUMSQ | `SUMSQ(value1, [value2, …])` | Sum of squares | P1 | |
| TAN | `TAN(angle)` | Tangent | P0 | |
| TANH | `TANH(value)` | Hyperbolic tangent | P1 | |
| TRUNC | `TRUNC(value, [places])` | Truncate | P0 | |
| ROMAN | `ROMAN(number, [rule_relaxation])` | Number → Roman numerals | P2 | 1–3999 |
| ARABIC | `ARABIC(roman_numeral)` | Roman → number | P2 | |

### 15.2 Statistical

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| AVEDEV | `AVEDEV(value1, [value2, …])` | Mean absolute deviation | P1 | |
| AVERAGE | `AVERAGE(value1, [value2, …])` | Arithmetic mean | P0 | no numbers → `#DIV/0!` "Evaluation of function AVERAGE caused a divide by zero error." |
| AVERAGE.WEIGHTED | `AVERAGE.WEIGHTED(values, weights, [additional_values, additional_weights, …])` | Weighted mean | P1 | Sheets-only |
| AVERAGEA | `AVERAGEA(value1, [value2, …])` | Mean counting text as 0 | P1 | |
| AVERAGEIF | `AVERAGEIF(criteria_range, criterion, [average_range])` | Conditional mean | P0 | |
| AVERAGEIFS | `AVERAGEIFS(average_range, criteria_range1, criterion1, …)` | Multi-criteria mean | P0 | |
| BETA.DIST | `BETA.DIST(value, alpha, beta, cumulative, [lower_bound], [upper_bound])` | Beta distribution | P2 | |
| BETA.INV | `BETA.INV(probability, alpha, beta, [lower_bound], [upper_bound])` | Inverse beta | P2 | |
| BETADIST | `BETADIST(value, alpha, beta, [lower_bound], [upper_bound])` | Cumulative beta (legacy) | P2 | |
| BETAINV | `BETAINV(probability, alpha, beta, [lower_bound], [upper_bound])` | Legacy | P2 | |
| BINOM.DIST | `BINOM.DIST(num_successes, num_trials, prob_success, cumulative)` | Binomial distribution | P1 | alias BINOMDIST |
| BINOM.INV | `BINOM.INV(num_trials, prob_success, target_prob)` | Smallest k with CDF ≥ target | P2 | alias CRITBINOM |
| CHISQ.DIST | `CHISQ.DIST(x, degrees_freedom, cumulative)` | Left-tailed χ² | P1 | |
| CHISQ.DIST.RT | `CHISQ.DIST.RT(x, degrees_freedom)` | Right-tailed χ² | P1 | alias CHIDIST |
| CHISQ.INV | `CHISQ.INV(probability, degrees_freedom)` | Inverse left-tailed χ² | P1 | |
| CHISQ.INV.RT | `CHISQ.INV.RT(probability, degrees_freedom)` | Inverse right-tailed χ² | P1 | alias CHIINV |
| CHISQ.TEST | `CHISQ.TEST(observed_range, expected_range)` | χ² test p-value | P1 | alias CHITEST |
| CONFIDENCE.NORM | `CONFIDENCE.NORM(alpha, standard_deviation, pop_size)` | Normal CI half-width | P1 | alias CONFIDENCE |
| CONFIDENCE.T | `CONFIDENCE.T(alpha, standard_deviation, size)` | Student-t CI half-width | P1 | |
| CORREL | `CORREL(data_y, data_x)` | Pearson correlation | P0 | pairs with non-numbers dropped |
| COUNT | `COUNT(value1, [value2, …])` | Count numbers | P0 | Sheets: numeric text in ranges not counted; direct numeric-text args counted |
| COUNTA | `COUNTA(value1, [value2, …])` | Count non-empty | P0 | counts `""` results of formulas (Sheets) |
| COUNTBLANK | `COUNTBLANK(range)` | Count empty | P0 | counts cells with `""` results as blank |
| COUNTIF | `COUNTIF(range, criterion)` | Conditional count | P0 | criteria §15.14 |
| COUNTIFS | `COUNTIFS(criteria_range1, criterion1, [criteria_range2, criterion2, …])` | Multi-criteria count | P0 | |
| COUNTUNIQUE | `COUNTUNIQUE(value1, [value2, …])` | Count distinct values | P0 | Sheets-only; case-insensitive text |
| COUNTUNIQUEIFS | `COUNTUNIQUEIFS(count_unique_range, criteria_range1, criterion1, …)` | Distinct count with criteria | P1 | Sheets-only |
| COVARIANCE.P | `COVARIANCE.P(data_y, data_x)` | Population covariance | P1 | alias COVAR |
| COVARIANCE.S | `COVARIANCE.S(data_y, data_x)` | Sample covariance | P1 | |
| DEVSQ | `DEVSQ(value1, [value2, …])` | Sum of squared deviations | P1 | |
| EXPON.DIST | `EXPON.DIST(x, lambda, cumulative)` | Exponential distribution | P1 | alias EXPONDIST |
| F.DIST | `F.DIST(x, df1, df2, cumulative)` | Left-tailed F | P1 | |
| F.DIST.RT | `F.DIST.RT(x, df1, df2)` | Right-tailed F | P1 | alias FDIST |
| F.INV | `F.INV(probability, df1, df2)` | Inverse left-tailed F | P1 | |
| F.INV.RT | `F.INV.RT(probability, df1, df2)` | Inverse right-tailed F | P1 | alias FINV |
| F.TEST | `F.TEST(range1, range2)` | F-test p-value | P1 | alias FTEST |
| FISHER | `FISHER(value)` | Fisher transform | P1 | |
| FISHERINV | `FISHERINV(value)` | Inverse Fisher | P1 | |
| FORECAST | `FORECAST(x, data_y, data_x)` | Linear prediction | P1 | alias FORECAST.LINEAR |
| GAMMA | `GAMMA(number)` | Γ(x) | P1 | |
| GAMMA.DIST | `GAMMA.DIST(x, alpha, beta, cumulative)` | Gamma distribution | P1 | alias GAMMADIST |
| GAMMA.INV | `GAMMA.INV(probability, alpha, beta)` | Inverse gamma | P1 | alias GAMMAINV |
| GAUSS | `GAUSS(z)` | P(0 ≤ Z ≤ z) | P1 | |
| GEOMEAN | `GEOMEAN(value1, [value2, …])` | Geometric mean | P1 | ≤0 → `#NUM!` |
| HARMEAN | `HARMEAN(value1, [value2, …])` | Harmonic mean | P1 | |
| HYPGEOM.DIST | `HYPGEOM.DIST(num_successes, num_draws, successes_in_pop, pop_size, cumulative)` | Hypergeometric | P1 | alias HYPGEOMDIST (non-cumulative) |
| INTERCEPT | `INTERCEPT(data_y, data_x)` | Regression intercept | P1 | |
| KURT | `KURT(value1, [value2, …])` | Excess kurtosis | P1 | n<4 → `#DIV/0!` |
| LARGE | `LARGE(data, n)` | n-th largest | P0 | |
| LOGNORM.DIST | `LOGNORM.DIST(x, mean, standard_deviation, cumulative)` | Lognormal | P1 | alias LOGNORMDIST (cumulative) |
| LOGNORM.INV | `LOGNORM.INV(probability, mean, standard_deviation)` | Inverse lognormal | P1 | alias LOGINV |
| MARGINOFERROR | `MARGINOFERROR(range, confidence)` | Margin of error of sample | P2 | Sheets-only |
| MAX | `MAX(value1, [value2, …])` | Maximum | P0 | no numbers → 0 |
| MAXA | `MAXA(value1, [value2, …])` | Max counting text 0, bool 0/1 | P1 | |
| MAXIFS | `MAXIFS(range, criteria_range1, criterion1, …)` | Conditional max | P0 | |
| MEDIAN | `MEDIAN(value1, [value2, …])` | Median | P0 | |
| MIN | `MIN(value1, [value2, …])` | Minimum | P0 | |
| MINA | `MINA(value1, [value2, …])` | Min counting text/bools | P1 | |
| MINIFS | `MINIFS(range, criteria_range1, criterion1, …)` | Conditional min | P0 | |
| MODE | `MODE(value1, [value2, …])` | Most common value | P0 | alias MODE.SNGL; none repeated → `#N/A` |
| MODE.MULT | `MODE.MULT(value1, [value2, …])` | All modes (vertical array) | P1 | |
| NEGBINOM.DIST | `NEGBINOM.DIST(num_failures, num_successes, prob_success, cumulative)` | Negative binomial | P2 | alias NEGBINOMDIST |
| NORM.DIST | `NORM.DIST(x, mean, standard_deviation, cumulative)` | Normal distribution | P1 | alias NORMDIST |
| NORM.INV | `NORM.INV(probability, mean, standard_deviation)` | Inverse normal | P1 | alias NORMINV; AS241 algorithm |
| NORM.S.DIST | `NORM.S.DIST(x, [cumulative])` | Standard normal | P1 | alias NORMSDIST (cumulative only) |
| NORM.S.INV | `NORM.S.INV(probability)` | Inverse standard normal | P1 | alias NORMSINV |
| PEARSON | `PEARSON(data_y, data_x)` | = CORREL | P1 | |
| PERCENTILE | `PERCENTILE(data, percentile)` | Inclusive percentile | P0 | alias PERCENTILE.INC |
| PERCENTILE.EXC | `PERCENTILE.EXC(data, percentile)` | Exclusive percentile | P1 | |
| PERCENTRANK | `PERCENTRANK(data, value, [significant_digits])` | Inclusive rank % | P1 | alias PERCENTRANK.INC; default 3 digits (truncated) |
| PERCENTRANK.EXC | `PERCENTRANK.EXC(data, value, [significant_digits])` | Exclusive rank % | P1 | |
| PERMUT | `PERMUT(n, k)` | Permutations | P1 | |
| PERMUTATIONA | `PERMUTATIONA(number, number_chosen)` | Permutations with repetition | P2 | |
| PHI | `PHI(x)` | Standard normal density | P2 | |
| POISSON.DIST | `POISSON.DIST(x, mean, [cumulative])` | Poisson | P1 | alias POISSON |
| PROB | `PROB(data, probabilities, low_limit, [high_limit])` | Probability of range | P2 | |
| QUARTILE | `QUARTILE(data, quartile_number)` | Inclusive quartile | P0 | alias QUARTILE.INC |
| QUARTILE.EXC | `QUARTILE.EXC(data, quartile_number)` | Exclusive quartile | P1 | |
| RANK | `RANK(value, data, [is_ascending])` | Rank (ties same) | P0 | alias RANK.EQ; default descending |
| RANK.AVG | `RANK.AVG(value, data, [is_ascending])` | Rank, ties averaged | P1 | |
| RSQ | `RSQ(data_y, data_x)` | r² | P1 | |
| SKEW | `SKEW(value1, [value2, …])` | Sample skewness | P1 | |
| SKEW.P | `SKEW.P(value1, [value2, …])` | Population skewness | P1 | |
| SLOPE | `SLOPE(data_y, data_x)` | Regression slope | P1 | |
| SMALL | `SMALL(data, n)` | n-th smallest | P0 | |
| STANDARDIZE | `STANDARDIZE(value, mean, standard_deviation)` | z-score | P1 | |
| STDEV | `STDEV(value1, [value2, …])` | Sample std dev | P0 | alias STDEV.S |
| STDEV.P | `STDEV.P(value1, [value2, …])` | Population std dev | P0 | alias STDEVP |
| STDEVA | `STDEVA(value1, [value2, …])` | Sample, text as 0 | P1 | |
| STDEVPA | `STDEVPA(value1, [value2, …])` | Population, text as 0 | P1 | |
| STEYX | `STEYX(data_y, data_x)` | Std error of regression | P1 | |
| T.DIST | `T.DIST(x, degrees_freedom, cumulative)` | Left-tailed t | P1 | |
| T.DIST.2T | `T.DIST.2T(x, degrees_freedom)` | Two-tailed t | P1 | |
| T.DIST.RT | `T.DIST.RT(x, degrees_freedom)` | Right-tailed t | P1 | TDIST(x, df, tails) legacy alias P2 |
| T.INV | `T.INV(probability, degrees_freedom)` | Inverse left-tailed t | P1 | |
| T.INV.2T | `T.INV.2T(probability, degrees_freedom)` | Inverse two-tailed t | P1 | alias TINV |
| T.TEST | `T.TEST(range1, range2, tails, type)` | t-test p-value | P1 | alias TTEST |
| TRIMMEAN | `TRIMMEAN(data, exclude_proportion)` | Trimmed mean | P1 | |
| VAR | `VAR(value1, [value2, …])` | Sample variance | P0 | alias VAR.S |
| VAR.P | `VAR.P(value1, [value2, …])` | Population variance | P0 | alias VARP |
| VARA | `VARA(value1, [value2, …])` | Sample, text as 0 | P1 | |
| VARPA | `VARPA(value1, [value2, …])` | Population, text as 0 | P1 | |
| WEIBULL.DIST | `WEIBULL.DIST(x, shape, scale, cumulative)` | Weibull | P2 | alias WEIBULL |
| Z.TEST | `Z.TEST(data, value, [standard_deviation])` | One-tailed z-test p-value | P2 | alias ZTEST |

Numerical kernels live in `functions/statistical/special.dart`: erf/erfc (Cody), Φ⁻¹ (Wichura
AS241), regularized incomplete gamma (series + Lentz continued fraction), incomplete beta (Lentz),
lnΓ (Lanczos g=7), with inverse distributions by bracketed Newton/bisection (max 100 iterations,
tolerance 1e-12 relative, else `#NUM!`).

### 15.3 Lookup & reference

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| ADDRESS | `ADDRESS(row, column, [absolute_relative_mode], [use_a1_notation], [sheet])` | Build reference text | P1 | modes 1–4; R1C1 when FALSE |
| CHOOSE | `CHOOSE(index, choice1, [choice2, …])` | Pick n-th argument | P0 | choices lazy; may return references |
| CHOOSECOLS | `CHOOSECOLS(array, col_num1, [col_num2, …])` | Select columns | P1 | negative = from end |
| CHOOSEROWS | `CHOOSEROWS(array, row_num1, [row_num2, …])` | Select rows | P1 | |
| COLUMN | `COLUMN([cell_reference])` | Column number | P0 | no arg = host; range in array mode → row array; positionSensitive |
| COLUMNS | `COLUMNS(range)` | Number of columns | P0 | |
| FORMULATEXT | `FORMULATEXT(cell)` | Formula as A1 text (locale) | P1 | non-formula → `#N/A` |
| GETPIVOTDATA | `GETPIVOTDATA(value_name, any_pivot_table_cell, [original_column, pivot_item, …])` | Value from a pivot table | P1 | reads `PivotResult` (07 §7.8) |
| HLOOKUP | `HLOOKUP(search_key, range, index, [is_sorted])` | Horizontal lookup | P0 | as VLOOKUP |
| INDEX | `INDEX(reference, [row], [column])` | Cell/row/column of range | P0 | 0 → whole row/col; returns reference (usable with `:`) |
| INDIRECT | `INDIRECT(cell_reference_as_string, [is_A1_notation])` | Reference from text | P0 | dynamic deps; R1C1 when FALSE; sheet names resolved now (rename breaks text, as Sheets) |
| LOOKUP | `LOOKUP(search_key, search_range_or_array, [result_range])` | Approximate lookup in sorted data | P1 | |
| MATCH | `MATCH(search_key, range, [search_type])` | Position of key | P0 | default 1 (sorted asc, largest ≤); 0 exact with wildcards; −1 desc |
| OFFSET | `OFFSET(cell_reference, offset_rows, offset_columns, [height], [width])` | Shifted reference | P0 | dynamic deps; outside grid → `#REF!` |
| ROW | `ROW([cell_reference])` | Row number | P0 | positionSensitive |
| ROWS | `ROWS(range)` | Number of rows | P0 | |
| VLOOKUP | `VLOOKUP(search_key, range, index, [is_sorted])` | Vertical lookup | P0 | Sheets: is_sorted default TRUE; exact mode supports wildcards `*?~`; miss → `#N/A` "Did not find value 'x' in VLOOKUP evaluation."; index > cols → `#REF!` |
| XLOOKUP | `XLOOKUP(search_key, lookup_range, result_range, [missing_value], [match_mode], [search_mode])` | Modern lookup | P0 | match_mode 0 exact, −1 next smaller, 1 next larger, 2 wildcard; search_mode 1, −1, 2, −2 (binary); returns row/col of result_range (spills) |
| XMATCH | `XMATCH(search_key, lookup_range, [match_mode], [search_mode])` | Position (XLOOKUP rules) | P1 | |

Lookup implementation uses `lookup_cache.dart` (§11.2) for exact and binary searches.

### 15.4 Logical

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| AND | `AND(logical_expression1, [logical_expression2, …])` | All true | P0 | ranges: text ignored; all args evaluated |
| FALSE | `FALSE()` | FALSE | P0 | |
| IF | `IF(logical_expression, value_if_true, [value_if_false])` | Conditional | P0 | lazy branches; omitted false → FALSE; liftable in array mode on condition |
| IFERROR | `IFERROR(value, [value_if_error])` | Catch errors | P0 | default `""` (empty) |
| IFNA | `IFNA(value, value_if_na)` | Catch `#N/A` | P0 | pending values are not caught (stay "Loading…") |
| IFS | `IFS(condition1, value1, [condition2, value2, …])` | First true condition | P0 | none → `#N/A` "No match." |
| LAMBDA | `LAMBDA([name, …], formula_expression)` | Create function | P1 | §3.7 |
| LET | `LET(name1, value_expression1, [name2, value_expression2, …], formula_expression)` | Named locals | P1 | |
| NOT | `NOT(logical_expression)` | Negation | P0 | |
| OR | `OR(logical_expression1, [logical_expression2, …])` | Any true | P0 | |
| SWITCH | `SWITCH(expression, case1, value1, [case2, value2, …], [default])` | Match cases | P0 | no match & no default → `#N/A` |
| TRUE | `TRUE()` | TRUE | P0 | |
| XOR | `XOR(logical_expression1, [logical_expression2, …])` | Odd number true | P1 | |
| ISOMITTED | `ISOMITTED(argument)` | LAMBDA param omitted? | P2 | |

### 15.5 Text

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| ARABIC | see §15.1 | | | |
| ASC | `ASC(text)` | Full-width → half-width | P2 | |
| CHAR | `CHAR(table_number)` | Character from **Unicode** code point | P0 | Sheets (Excel uses ANSI) |
| CLEAN | `CLEAN(text)` | Remove non-printable ASCII 0–31 | P1 | |
| CODE | `CODE(string)` | Unicode code point of first char | P0 | |
| CONCAT | `CONCAT(value1, value2)` | Join two values | P0 | Sheets: exactly 2 args (Excel's variadic CONCAT imported as CONCATENATE) |
| CONCATENATE | `CONCATENATE(string1, [string2, …])` | Join values | P0 | ranges joined row-major without delimiter |
| DOLLAR | `DOLLAR(number, [number_of_places])` | Currency text | P1 | locale currency |
| EXACT | `EXACT(string1, string2)` | Case-sensitive equality | P0 | |
| FIND | `FIND(search_for, text_to_search, [starting_at])` | Case-sensitive position | P0 | not found → `#VALUE!` |
| FINDB | `FINDB(search_for, text_to_search, [starting_at])` | Byte-based FIND | P2 | DBCS = 2 bytes |
| FIXED | `FIXED(number, [number_of_places], [suppress_separator])` | Fixed decimals text | P1 | |
| JOIN | `JOIN(delimiter, value_or_array1, [value_or_array2, …])` | Join with delimiter | P0 | Sheets-only; 1-D arrays only |
| LEFT | `LEFT(string, [number_of_characters])` | Left substring | P0 | UTF-16 units |
| LEFTB | `LEFTB(string, num_of_bytes)` | Byte-based | P2 | |
| LEN | `LEN(text)` | Length | P0 | UTF-16 code units (Sheets/Excel parity: emoji = 2) |
| LENB | `LENB(string)` | Byte length | P2 | |
| LOWER | `LOWER(text)` | Lowercase | P0 | Unicode default case mapping |
| MID | `MID(string, starting_at, extract_length)` | Substring | P0 | |
| MIDB | `MIDB(string, starting_at, extract_length_bytes)` | Byte-based | P2 | |
| NUMBERVALUE | `NUMBERVALUE(text, [decimal_separator], [group_separator])` | Locale-independent parse | P1 | Excel compat |
| PROPER | `PROPER(text_to_capitalize)` | Capitalize words | P0 | word = letters run |
| REGEXEXTRACT | `REGEXEXTRACT(text, regular_expression)` | First match / capture groups | P0 | groups → horizontal array; no match → `#N/A` |
| REGEXMATCH | `REGEXMATCH(text, regular_expression)` | Partial match test | P0 | |
| REGEXREPLACE | `REGEXREPLACE(text, regular_expression, replacement)` | Replace all matches | P0 | `$1`…`$9`, `$0`; `\$` literal |
| REGEXTEST | `REGEXTEST(text, pattern, [case_sensitivity])` | Excel 2024 compat | P2 | |
| REPLACE | `REPLACE(text, position, length, new_text)` | Replace by position | P0 | |
| REPLACEB | `REPLACEB(text, position, num_bytes, new_text)` | Byte-based | P2 | |
| REPT | `REPT(text_to_repeat, number_of_repetitions)` | Repeat | P0 | result > 50k chars → `#VALUE!` |
| RIGHT | `RIGHT(string, [number_of_characters])` | Right substring | P0 | |
| RIGHTB | `RIGHTB(string, num_of_bytes)` | Byte-based | P2 | |
| ROMAN | see §15.1 | | | |
| SEARCH | `SEARCH(search_for, text_to_search, [starting_at])` | Case-insensitive position | P0 | |
| SEARCHB | `SEARCHB(search_for, text_to_search, [starting_at])` | Byte-based | P2 | |
| SPLIT | `SPLIT(text, delimiter, [split_by_each], [remove_empty_text])` | Split to columns | P0 | Sheets-only; split_by_each default TRUE (each char is a delimiter); remove_empty default TRUE; numeric-looking parts become numbers |
| SUBSTITUTE | `SUBSTITUTE(text_to_search, search_for, replace_with, [occurrence_number])` | Replace text | P0 | case-sensitive |
| T | `T(value)` | Text or empty | P1 | |
| TEXT | `TEXT(number, format)` | Format number as text | P0 | uses the `format/` number-format engine (06); locale-aware |
| TEXTAFTER | `TEXTAFTER(text, delimiter, [instance_num], [match_mode], [match_end], [if_not_found])` | Text after delimiter | P1 | Excel compat |
| TEXTBEFORE | `TEXTBEFORE(text, delimiter, [instance_num], [match_mode], [match_end], [if_not_found])` | Text before delimiter | P1 | Excel compat |
| TEXTJOIN | `TEXTJOIN(delimiter, ignore_empty, text1, [text2, …])` | Join with delimiter | P0 | |
| TEXTSPLIT | `TEXTSPLIT(text, col_delimiter, [row_delimiter], [ignore_empty], [match_mode], [pad_with])` | Excel split | P2 | |
| TRIM | `TRIM(text)` | Remove leading/trailing spaces, collapse inner runs | P0 | U+0020 only (parity) |
| UNICHAR | `UNICHAR(number)` | Char from code point | P1 | |
| UNICODE | `UNICODE(text)` | Code point of first char | P1 | |
| UPPER | `UPPER(text)` | Uppercase | P0 | |
| VALUE | `VALUE(text)` | Text → number | P0 | locale-aware (§6.3) incl. dates/times |
| VALUETOTEXT / ARRAYTOTEXT | `VALUETOTEXT(value, [format])` | Excel compat | P2 | |

**Regex flavor**: patterns are Dart `RegExp` (ECMAScript) with `unicode: true`. A small RE2→Dart
shim rewrites RE2-only syntax: `(?P<name>…)` → `(?<name>…)`; leading inline flags `(?i)`, `(?s)`,
`(?m)` → `RegExp` options (inline flags elsewhere → `#VALUE!` "Unsupported regular expression
syntax"); `\z` → `$(?![\s\S])`; `\A` → `^` (non-multiline); POSIX classes such as `[[:alpha:]]`
→ Unicode property escapes. Lookaround and backreferences (not in RE2) are accepted (superset).
Catastrophic backtracking cannot be interrupted in Dart, so input strings are capped at 50k chars
and patterns at 1,000 chars. An invalid pattern yields `#VALUE!` "Function REGEXMATCH parameter 2
value '(' is not a valid regular expression." (Sheets uses `#REF!` here in some cases; we use
`#VALUE!` consistently — documented deviation).

### 15.6 Date & time

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| DATE | `DATE(year, month, day)` | Serial date | P0 | year 0–1899 → +1900 (Sheets/Excel); month/day overflow rolls |
| DATEDIF | `DATEDIF(start_date, end_date, unit)` | Difference | P0 | units Y, M, D, MD, YM, YD; start>end → `#NUM!` |
| DATEVALUE | `DATEVALUE(date_string)` | Parse date | P0 | locale formats, ISO 8601, month names (locale + English) |
| DAY | `DAY(date)` | Day of month | P0 | |
| DAYS | `DAYS(end_date, start_date)` | Days between | P1 | |
| DAYS360 | `DAYS360(start_date, end_date, [method])` | 30/360 days | P1 | |
| EDATE | `EDATE(start_date, months)` | Add months | P0 | |
| EOMONTH | `EOMONTH(start_date, months)` | End of month | P0 | |
| EPOCHTODATE | `EPOCHTODATE(timestamp, [unit])` | Unix epoch → datetime (UTC) | P1 | unit 1 s, 2 ms, 3 µs |
| HOUR | `HOUR(time)` | Hour | P0 | |
| ISOWEEKNUM | `ISOWEEKNUM(date)` | ISO week | P1 | |
| MINUTE | `MINUTE(time)` | Minute | P0 | |
| MONTH | `MONTH(date)` | Month | P0 | |
| NETWORKDAYS | `NETWORKDAYS(start_date, end_date, [holidays])` | Working days | P0 | |
| NETWORKDAYS.INTL | `NETWORKDAYS.INTL(start_date, end_date, [weekend], [holidays])` | Custom weekends | P1 | weekend codes 1–7, 11–17 or `"0000011"` |
| NOW | `NOW()` | Current date-time | P0 | volatile; spreadsheet time zone |
| SECOND | `SECOND(time)` | Second | P0 | |
| TIME | `TIME(hour, minute, second)` | Serial time | P0 | wraps at 24h |
| TIMEVALUE | `TIMEVALUE(time_string)` | Parse time | P0 | |
| TODAY | `TODAY()` | Current date | P0 | volatile |
| WEEKDAY | `WEEKDAY(date, [type])` | Day of week | P0 | types 1, 2, 3 (+ Excel 11–17 P1) |
| WEEKNUM | `WEEKNUM(date, [type])` | Week number | P0 | types 1, 2, 11–17, 21 |
| WORKDAY | `WORKDAY(start_date, num_days, [holidays])` | Add working days | P0 | |
| WORKDAY.INTL | `WORKDAY.INTL(start_date, num_days, [weekend], [holidays])` | Custom weekends | P1 | |
| YEAR | `YEAR(date)` | Year | P0 | |
| YEARFRAC | `YEARFRAC(start_date, end_date, [day_count_convention])` | Year fraction | P1 | bases 0–4 |

Text arguments to date functions are coerced with `DATEVALUE` rules (`=YEAR("2024-03-01")` works).

### 15.7 Financial

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| PMT | `PMT(rate, number_of_periods, present_value, [future_value], [end_or_beginning])` | Payment | P0 | currency hint |
| FV | `FV(rate, number_of_periods, payment_amount, [present_value], [end_or_beginning])` | Future value | P0 | |
| PV | `PV(rate, number_of_periods, payment_amount, [future_value], [end_or_beginning])` | Present value | P0 | |
| NPER | `NPER(rate, payment_amount, present_value, [future_value], [end_or_beginning])` | Number of periods | P0 | |
| RATE | `RATE(number_of_periods, payment_per_period, present_value, [future_value], [end_or_beginning], [rate_guess])` | Interest rate | P0 | Newton, 100 iterations, 1e-10 → else `#NUM!` |
| NPV | `NPV(discount, cashflow1, [cashflow2, …])` | Net present value | P0 | |
| IRR | `IRR(cashflow_amounts, [rate_guess])` | Internal rate of return | P0 | Newton + bisection fallback; no sign change → `#NUM!` |
| IPMT | `IPMT(rate, period, number_of_periods, present_value, [future_value], [end_or_beginning])` | Interest part | P1 | |
| PPMT | `PPMT(rate, period, number_of_periods, present_value, [future_value], [end_or_beginning])` | Principal part | P1 | |
| ISPMT | `ISPMT(rate, period, number_of_periods, present_value)` | Interest (straight-line) | P1 | |
| CUMIPMT | `CUMIPMT(rate, number_of_periods, present_value, first_period, last_period, end_or_beginning)` | Cumulative interest | P1 | |
| CUMPRINC | `CUMPRINC(rate, number_of_periods, present_value, first_period, last_period, end_or_beginning)` | Cumulative principal | P1 | |
| XNPV | `XNPV(discount, cashflow_amounts, cashflow_dates)` | NPV irregular | P1 | |
| XIRR | `XIRR(cashflow_amounts, cashflow_dates, [rate_guess])` | IRR irregular | P1 | |
| MIRR | `MIRR(cashflow_amounts, financing_rate, reinvestment_return_rate)` | Modified IRR | P1 | |
| EFFECT | `EFFECT(nominal_rate, periods_per_year)` | Effective rate | P1 | |
| NOMINAL | `NOMINAL(effective_rate, periods_per_year)` | Nominal rate | P1 | |
| PDURATION | `PDURATION(rate, present_value, future_value)` | Periods to reach value | P1 | |
| RRI | `RRI(number_of_periods, present_value, future_value)` | Equivalent rate | P1 | |
| FVSCHEDULE | `FVSCHEDULE(principal, rate_schedule)` | FV with variable rates | P1 | |
| DB | `DB(cost, salvage, life, period, [month])` | Fixed-declining depreciation | P1 | |
| DDB | `DDB(cost, salvage, life, period, [factor])` | Double-declining | P1 | |
| SLN | `SLN(cost, salvage, life)` | Straight-line | P1 | |
| SYD | `SYD(cost, salvage, life, period)` | Sum-of-years | P1 | |
| VDB | `VDB(cost, salvage, life, start_period, end_period, [factor], [no_switch])` | Variable declining | P1 | |
| DOLLARDE | `DOLLARDE(fractional_price, unit)` | Fraction → decimal price | P1 | |
| DOLLARFR | `DOLLARFR(decimal_price, unit)` | Decimal → fraction price | P1 | |
| ACCRINT | `ACCRINT(issue, first_payment, settlement, rate, redemption, frequency, [day_count_convention])` | Accrued interest | P2 | |
| ACCRINTM | `ACCRINTM(issue, maturity, rate, [redemption], [day_count_convention])` | Accrued at maturity | P2 | |
| AMORLINC | `AMORLINC(cost, purchase_date, first_period_end, salvage, period, rate, [basis])` | French depreciation | P2 | |
| COUPDAYBS | `COUPDAYBS(settlement, maturity, frequency, [day_count_convention])` | Days from coupon start | P2 | |
| COUPDAYS | `COUPDAYS(settlement, maturity, frequency, [day_count_convention])` | Days in coupon period | P2 | |
| COUPDAYSNC | `COUPDAYSNC(settlement, maturity, frequency, [day_count_convention])` | Days to next coupon | P2 | |
| COUPNCD | `COUPNCD(settlement, maturity, frequency, [day_count_convention])` | Next coupon date | P2 | |
| COUPNUM | `COUPNUM(settlement, maturity, frequency, [day_count_convention])` | Coupons payable | P2 | |
| COUPPCD | `COUPPCD(settlement, maturity, frequency, [day_count_convention])` | Previous coupon date | P2 | |
| DISC | `DISC(settlement, maturity, price, redemption, [day_count_convention])` | Discount rate | P2 | |
| DURATION | `DURATION(settlement, maturity, rate, yield, frequency, [day_count_convention])` | Macaulay duration | P2 | |
| MDURATION | `MDURATION(settlement, maturity, rate, yield, frequency, [day_count_convention])` | Modified duration | P2 | |
| INTRATE | `INTRATE(buy_date, sell_date, buy_price, sell_price, [day_count_convention])` | Interest rate | P2 | |
| PRICE | `PRICE(settlement, maturity, rate, yield, redemption, frequency, [day_count_convention])` | Bond price | P2 | |
| PRICEDISC | `PRICEDISC(settlement, maturity, discount, redemption, [day_count_convention])` | Discount security price | P2 | |
| PRICEMAT | `PRICEMAT(settlement, maturity, issue, rate, yield, [day_count_convention])` | Price at maturity | P2 | |
| RECEIVED | `RECEIVED(settlement, maturity, investment, discount, [day_count_convention])` | Amount at maturity | P2 | |
| TBILLEQ | `TBILLEQ(settlement, maturity, discount)` | T-bill bond-equivalent yield | P2 | |
| TBILLPRICE | `TBILLPRICE(settlement, maturity, discount)` | T-bill price | P2 | |
| TBILLYIELD | `TBILLYIELD(settlement, maturity, price)` | T-bill yield | P2 | |
| YIELD | `YIELD(settlement, maturity, rate, price, redemption, frequency, [day_count_convention])` | Bond yield | P2 | |
| YIELDDISC | `YIELDDISC(settlement, maturity, price, redemption, [day_count_convention])` | Discount yield | P2 | |
| YIELDMAT | `YIELDMAT(settlement, maturity, issue, rate, price, [day_count_convention])` | Yield at maturity | P2 | |

Not supported (Excel-only, rare): `ODDFPRICE`, `ODDFYIELD`, `ODDLPRICE`, `ODDLYIELD`,
`AMORDEGRC` → `#NAME?` stubs.

### 15.8 Information

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| CELL | `CELL(info_type, reference)` | Info about a cell | P1 | `address`, `col`, `row`, `contents`, `type` (b/l/v), `width`, `prefix`, `format` (P2), `color`/`protect` (P2) |
| ERROR.TYPE | `ERROR.TYPE(reference)` | Error code | P0 | §6.6; non-error → `#N/A` |
| ISBLANK | `ISBLANK(value)` | Empty cell? | P0 | `""` result is not blank |
| ISDATE | `ISDATE(value)` | Is date? | P1 | TRUE for numbers with date/dateTime hint or date-formatted cells, and date-parseable text |
| ISEMAIL | `ISEMAIL(value)` | Valid email? | P1 | |
| ISERR | `ISERR(value)` | Error other than `#N/A` | P0 | |
| ISERROR | `ISERROR(value)` | Any error | P0 | |
| ISEVEN | `ISEVEN(value)` | Even? | P1 | |
| ISFORMULA | `ISFORMULA(cell)` | Has formula? | P1 | |
| ISLOGICAL | `ISLOGICAL(value)` | Boolean? | P0 | |
| ISNA | `ISNA(value)` | `#N/A`? | P0 | |
| ISNONTEXT | `ISNONTEXT(value)` | Not text | P0 | |
| ISNUMBER | `ISNUMBER(value)` | Number? | P0 | |
| ISODD | `ISODD(value)` | Odd? | P1 | |
| ISREF | `ISREF(value)` | Reference? | P1 | `reference` arg kind, lazy |
| ISTEXT | `ISTEXT(value)` | Text? | P0 | |
| ISURL | `ISURL(value)` | URL? | P1 | |
| N | `N(value)` | To number (text → 0) | P1 | |
| NA | `NA()` | `#N/A` | P0 | |
| TYPE | `TYPE(value)` | 1 number, 2 text, 4 bool, 16 error, 64 array, 128 lambda | P1 | |
| SHEET / SHEETS | `SHEET([value])`, `SHEETS([reference])` | Sheet index / count | P2 | Excel compat |

`INFO` → unsupported stub.

### 15.9 Array & matrix

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| ARRAY_CONSTRAIN | `ARRAY_CONSTRAIN(input_range, num_rows, num_cols)` | Truncate array | P1 | Sheets-only |
| ARRAYFORMULA | `ARRAYFORMULA(array_formula)` | Evaluate in array mode | P0 | §7.4 |
| DROP | `DROP(array, rows, [columns])` | Remove rows/cols | P1 | Excel compat |
| EXPAND | `EXPAND(array, rows, [columns], [pad_with])` | Pad array | P1 | Excel compat; default pad `#N/A` |
| FLATTEN | `FLATTEN(range1, [range2, …])` | To single column (row-major) | P1 | Sheets-only |
| FREQUENCY | `FREQUENCY(data, classes)` | Histogram counts (n+1) | P1 | |
| GROWTH | `GROWTH(known_data_y, [known_data_x], [new_data_x], [b])` | Exponential trend | P2 | |
| HSTACK | `HSTACK(range1, [range2, …])` | Horizontal stack | P0 | pads with `#N/A` |
| LINEST | `LINEST(known_data_y, [known_data_x], [calculate_b], [verbose])` | Linear regression stats | P2 | QR decomposition |
| LOGEST | `LOGEST(known_data_y, [known_data_x], [b], [verbose])` | Exponential regression | P2 | |
| MDETERM | `MDETERM(square_matrix)` | Determinant | P1 | LU with partial pivoting |
| MINVERSE | `MINVERSE(square_matrix)` | Inverse | P1 | singular → `#NUM!` |
| MMULT | `MMULT(matrix1, matrix2)` | Matrix product | P1 | dims mismatch → `#VALUE!` |
| SUMPRODUCT | `SUMPRODUCT(array1, [array2, …])` | Sum of products | P0 | args in array mode; text → 0 |
| SUMX2MY2 | `SUMX2MY2(array_x, array_y)` | Σ(x²−y²) | P2 | |
| SUMX2PY2 | `SUMX2PY2(array_x, array_y)` | Σ(x²+y²) | P2 | |
| SUMXMY2 | `SUMXMY2(array_x, array_y)` | Σ(x−y)² | P2 | |
| TAKE | `TAKE(array, rows, [columns])` | First/last rows/cols | P1 | Excel compat |
| TOCOL | `TOCOL(array_or_range, [ignore], [scan_by_column])` | To one column | P1 | ignore 0–3 |
| TOROW | `TOROW(array_or_range, [ignore], [scan_by_column])` | To one row | P1 | |
| TRANSPOSE | `TRANSPOSE(array_or_range)` | Transpose | P0 | |
| TREND | `TREND(known_data_y, [known_data_x], [new_data_x], [b])` | Linear trend | P2 | |
| VSTACK | `VSTACK(range1, [range2, …])` | Vertical stack | P0 | |
| WRAPCOLS | `WRAPCOLS(range, wrap_count, [pad_with])` | Wrap into columns | P1 | |
| WRAPROWS | `WRAPROWS(range, wrap_count, [pad_with])` | Wrap into rows | P1 | |

### 15.10 Filter & sort (dynamic arrays)

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| FILTER | `FILTER(range, condition1, [condition2, …])` | Rows/cols meeting conditions | P0 | conditions are same-length row or column arrays; none → `#N/A` "No matches are found in FILTER evaluation." |
| SORT | `SORT(range, sort_column, is_ascending, [sort_column2, is_ascending2, …])` | Sorted copy | P0 | Sheets signature (sort_column index or array); order [07 §2.3](07-data-tools.md); Excel `SORT(array, idx, ±1, by_col)` handled on XLSX import (11) |
| SORTN | `SORTN(range, [n], [display_ties_mode], [sort_column1, is_ascending1, …])` | First n sorted | P1 | ties modes 0–3 |
| SORTBY | `SORTBY(array, by_array1, [sort_order1], …)` | Excel compat | P2 | |
| UNIQUE | `UNIQUE(range, [by_column], [exactly_once])` | Distinct rows | P0 | text comparison case-sensitive (Sheets), unlike COUNTUNIQUE; confirm with golden vectors |

### 15.11 Lambda helpers

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| MAP | `MAP(array1, [array2, …], LAMBDA)` | Element-wise map | P1 | arrays same size |
| REDUCE | `REDUCE(initial_value, array_or_range, LAMBDA)` | Fold | P1 | lambda(acc, value) |
| SCAN | `SCAN(initial_value, array_or_range, LAMBDA)` | Running fold (array) | P1 | |
| BYROW | `BYROW(array_or_range, LAMBDA)` | Per row → column | P1 | lambda must return scalar |
| BYCOL | `BYCOL(array_or_range, LAMBDA)` | Per column → row | P1 | |
| MAKEARRAY | `MAKEARRAY(rows, columns, LAMBDA)` | Build array | P1 | lambda(row, col) |

### 15.12 Database

All take `(database, field, criteria)`; `field` is a header text or 1-based column index; criteria
is a range whose first row are headers and subsequent rows are OR-ed rows of AND-ed criteria
(§15.14 syntax).

| Function | Description | P | Notes |
|----------|-------------|---|-------|
| DAVERAGE | Average | P1 | |
| DCOUNT | Count numbers | P1 | |
| DCOUNTA | Count non-empty | P1 | |
| DGET | Single value | P1 | none → `#VALUE!`; more than one → `#NUM!` |
| DMAX / DMIN | Max / min | P1 | |
| DPRODUCT | Product | P1 | |
| DSTDEV / DSTDEVP | Sample / population std dev | P1 | |
| DSUM | Sum | P1 | |
| DVAR / DVARP | Sample / population variance | P1 | |

### 15.13 Engineering

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| BIN2DEC, BIN2HEX, BIN2OCT | `BIN2DEC(signed_binary_number)`, `BIN2HEX(signed_binary_number, [significant_digits])` … | Base conversions | P1 | 10-digit two's complement |
| DEC2BIN, DEC2HEX, DEC2OCT | `DEC2BIN(decimal_number, [significant_digits])` … | | P1 | ranges per Excel |
| HEX2BIN, HEX2DEC, HEX2OCT | | | P1 | |
| OCT2BIN, OCT2DEC, OCT2HEX | | | P1 | |
| BITAND, BITOR, BITXOR | `BITAND(value1, value2)` | Bitwise | P1 | 0 ≤ x < 2⁴⁸ |
| BITLSHIFT, BITRSHIFT | `BITLSHIFT(value, shift_amount)` | Shifts | P1 | |
| DELTA | `DELTA(number1, [number2])` | Equality 1/0 | P1 | |
| GESTEP | `GESTEP(value, [step])` | ≥ step 1/0 | P1 | |
| ERF | `ERF(lower_bound, [upper_bound])` | Error function | P1 | |
| ERF.PRECISE | `ERF.PRECISE(x)` | | P1 | |
| ERFC | `ERFC(z)` | Complementary erf | P1 | alias ERFC.PRECISE |
| COMPLEX | `COMPLEX(real_part, imaginary_part, [suffix])` | Complex number text | P2 | complex numbers are text `"3+4i"` |
| IMABS, IMAGINARY, IMARGUMENT, IMCONJUGATE, IMCOS, IMCOSH, IMCOT, IMCOTH, IMCSC, IMCSCH, IMDIV, IMEXP, IMLN, IMLOG, IMLOG10, IMLOG2, IMPOWER, IMPRODUCT, IMREAL, IMSEC, IMSECH, IMSIN, IMSINH, IMSQRT, IMSUB, IMSUM, IMTAN, IMTANH | `IMSUM(value1, [value2, …])`, … | Complex arithmetic | P2 | `functions/engineering/complex.dart` |

`BESSELI/J/K/Y` → unsupported stubs (not in Google Sheets).

### 15.14 Criteria syntax (COUNTIF family, SUMIF family, AVERAGEIF family, MAXIFS/MINIFS, D-functions)

- Criterion forms: a number/boolean/date value (equality), `">5"`, `">=2024-01-01"`, `"<>x"`,
  `"=abc"`, `"="` (matches empty), `"<>"` (non-empty), `"abc"` (equality, case-insensitive).
- Operators `=, <>, <, >, <=, >=` followed by a value parsed like typed input (number, date,
  boolean, else text).
- Wildcards in text equality/inequality: `*` any run, `?` one char, `~` escapes (`~*`).
- Text vs number: `"5"` criterion matches number 5 and text "5"; `">5"` only matches numbers.
- Errors in the range never match (and don't propagate).
- Compiled once per criterion string (`ParsedCriteria` cache).

### 15.15 Parser functions (Sheets-specific)

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| CONVERT | `CONVERT(value, start_unit, end_unit)` | Unit conversion | P1 | Excel unit table incl. prefixes (k, M, Ki…); incompatible → `#N/A` |
| TO_DATE | `TO_DATE(value)` | Number with date hint | P1 | |
| TO_DOLLARS | `TO_DOLLARS(value)` | Number with currency hint | P1 | |
| TO_PERCENT | `TO_PERCENT(value)` | Number with percent hint | P1 | |
| TO_PURE_NUMBER | `TO_PURE_NUMBER(value)` | Strip format hint | P1 | |
| TO_TEXT | `TO_TEXT(value)` | Display text of value | P1 | uses source cell's effective format |

### 15.16 Operator functions

All P0 (trivial; share the operator implementations): `ADD(value1, value2)`,
`MINUS(value1, value2)`, `MULTIPLY(factor1, factor2)`, `DIVIDE(dividend, divisor)`,
`POW(base, exponent)`, `CONCAT` (see Text), `EQ`, `NE`, `GT`, `GTE`, `LT`, `LTE`
(`(value1, value2)`), `UMINUS(value)`, `UPLUS(value)`, `UNARY_PERCENT(percentage)`,
`ISBETWEEN(value_to_compare, lower_value, upper_value, [lower_value_is_inclusive], [upper_value_is_inclusive])`.
Error messages for operators name these functions ("Function ADD parameter 2 …"), Sheets parity.

### 15.17 Web, Google & special

| Function | Syntax | Description | P | Notes |
|----------|--------|-------------|---|-------|
| HYPERLINK | `HYPERLINK(url, [link_label])` | Clickable link | P0 | `FRich(hyperlink)`; only http(s)/mailto/`#gid` internal links; clicking opens in-app for Wonky URLs (single window) or the OS browser for external |
| ENCODEURL | `ENCODEURL(text)` | Percent-encode | P1 | |
| IMPORTRANGE | `IMPORTRANGE(spreadsheet_url, range_string)` | Import from another Wonky spreadsheet | P1 | §13.3; async; spills |
| IMPORTDATA | `IMPORTDATA(url, [delimiter], [locale])` | CSV/TSV from URL | P2 | §13.4 |
| IMPORTHTML | `IMPORTHTML(url, query, index, [locale])` | HTML table/list | P2 | query `"table"`/`"list"` |
| IMPORTXML | `IMPORTXML(url, xpath_query, [locale])` | XPath over XML/HTML | P2 | XPath 1.0 subset |
| IMPORTFEED | `IMPORTFEED(url, [query], [headers], [num_items])` | RSS/Atom | P2 | |
| IMAGE | `IMAGE(url, [mode], [height], [width], [alt_text])` | In-cell image | P0 | `FRich(ImageValue)`; modes 1 fit, 2 stretch, 3 original, 4 custom; `wonky-file://` and proxied `https://` (08 §10.2); used by *Insert › Image in cell* |
| SPARKLINE | `SPARKLINE(data, [options])` | In-cell chart | P0 | §17; painted by 08 |
| QUERY | `QUERY(data, query, [headers])` | Query language over a range | P1 | §16; heavy |
| AI | `AI(prompt, [range])` | LLM text generation | P2 | §13.5 |
| GOOGLETRANSLATE | `GOOGLETRANSLATE(text, [source_language], [target_language])` | Translate | P2 | AI-backed |
| DETECTLANGUAGE | `DETECTLANGUAGE(text_or_range)` | Detect language code | P2 | AI-backed |
| GOOGLEFINANCE | — | — | — | unsupported stub (`#NAME?` with explanation) |
| Custom functions | `MYFUNC(…)` | Script custom functions | P1 | §13.6, [09](09-scripting.md) |
| Named functions | `TAX(…)` | LAMBDA-based | P1 | §3.7, [07 §9](07-data-tools.md) |

Catalog size: ≈ 480 names including aliases (roughly 170 P0, 230 P1, 80 P2). CI prints the
current implemented/stub counts per priority and category (parity dashboard).

---

## 16. QUERY language (P1)

`QUERY(data, query, [headers])` implements the Google Visualization API query language subset
that Sheets supports. Implementation: `lib/src/formula/functions/query/` (parser, AST, table, `query_executor.dart`, registration
in `query_function.dart`) — petitparser grammar (case-insensitive
keywords), typed AST, executor over a column-typed table built from `data`.

### 16.1 Grammar (EBNF)

```ebnf
query          = ws , [ select ] , [ where ] , [ group_by ] , [ pivot ] , [ order_by ] ,
                 [ limit ] , [ offset ] , [ label ] , [ format ] , [ options ] , ws ;   (* clause order is fixed *)

select         = "select" , ( "*" | select_item , { "," , select_item } ) ;
select_item    = expr ;
where          = "where" , bool_expr ;
group_by       = "group" , "by" , expr , { "," , expr } ;
pivot          = "pivot" , expr , { "," , expr } ;
order_by       = "order" , "by" , order_item , { "," , order_item } ;
order_item     = expr , [ "asc" | "desc" ] ;
limit          = "limit" , integer ;
offset         = "offset" , integer ;
label          = "label" , expr , string , { "," , expr , string } ;
format         = "format" , expr , string , { "," , expr , string } ;   (* number/date patterns, 06 syntax *)
options        = "options" , option , { "," , option } ;
option         = "no_format" | "no_values" ;

bool_expr      = and_expr , { "or" , and_expr } ;
and_expr       = not_expr , { "and" , not_expr } ;
not_expr       = [ "not" ] , predicate ;
predicate      = "(" , bool_expr , ")"
               | expr , "is" , [ "not" ] , "null"
               | expr , compare_op , expr
               | expr , string_op , expr ;
compare_op     = "=" | "!=" | "<>" | "<=" | ">=" | "<" | ">" ;
string_op      = "contains" | "starts" , "with" | "ends" , "with" | "matches" | "like" ;

expr           = term , { ( "+" | "-" ) , term } ;
term           = unary , { ( "*" | "/" | "%" ) , unary } ;
unary          = [ "-" ] , atom ;
atom           = literal | aggregate | scalar_fn | column | "(" , expr , ")" ;
aggregate      = ( "avg" | "count" | "max" | "min" | "sum" ) , "(" , expr , ")" ;
scalar_fn      = fn_name , "(" , [ expr , { "," , expr } ] , ")" ;
fn_name        = "year" | "month" | "day" | "hour" | "minute" | "second" | "millisecond"
               | "quarter" | "dayofweek" | "now" | "datediff" | "todate" | "upper" | "lower" ;
column         = col_letters                       (* when data is a range: sheet column letters, e.g. C, AA *)
               | "Col" , digits                    (* when data is an array/function result: Col1… *)
               | "`" , { char - "`" } , "`" ;      (* backquoted identifier *)
literal        = number | string | "true" | "false"
               | "date" , string | "datetime" , string | "timeofday" , string ;
string         = "'" , { char - "'" } , "'" | '"' , { char - '"' } , '"' ;
```

### 16.2 Semantics

- **Columns**: for a range argument, identifiers are the sheet column letters of the range
  (`QUERY(C1:E, "select D")`); for computed data (`{…}`, `FILTER(…)`, `IMPORTRANGE(…)`) they are
  `Col1…ColN`.
- **Headers**: `headers` = number of header rows (default −1 = auto-detect: the first row is a
  header if in some column its type is text while the majority of data rows in that column are
  non-text). Multiple header rows are joined with a space.
- **Column types**: each data column gets the **majority type** among non-empty data cells (number,
  string, boolean, date, datetime, timeofday — from format hints); values of minority types become
  `null` (Sheets behavior, a common source of "missing" values — documented in the help card).
- **Output**: a header row (labels: original header, or `sum Revenue`, `avg(Units)`-style
  generated labels as Sheets: `sum Revenue`; `label` overrides) followed by result rows, spilled.
- `group by` requires every non-aggregated select item to be in the group list, else
  `#VALUE!` "Unable to parse query string for Function QUERY parameter 2: ADD_COL_TO_GROUP_BY_OR_AGG: B".
- `pivot` turns distinct values of the pivot expression into columns
  (`"<pivot value> <aggregate label>"` when several aggregates).
- `month()` is **zero-based** (Jan = 0), `dayOfWeek()` 1 = Sunday — Sheets/GViz parity.
- `like`: `%` any run, `_` one char; `matches`: full-string regex (Dart RegExp with shim §15.5);
  `contains`/`starts with`/`ends with` are case-sensitive.
- `order by` uses the type ordering of §6.4 per column, nulls first ascending.
- Errors: parse failures → `#VALUE!` "Unable to parse query string for Function QUERY parameter
  2: PARSE_ERROR: Encountered "x" at line 1, column 12."; unknown column → "NO_COLUMN: F".
- Performance: executes over column snapshots; heavy (`cost: heavy`); 1M rows × 5 columns with a
  `where` + `group by` < 1.5 s native.

---

## 17. SPARKLINE (P0)

`SPARKLINE(data, [options])` returns `FRich(SparklineValue)` (data series + parsed options); the
grid's content layer renders it through the `InCellRenderer` registered by
[08-charts-and-objects.md](08-charts-and-objects.md) (reusing `ChartScene` without axes/labels).
The engine only parses/validates options and normalizes data. Options are a 2-column range/array of
`{option, value}` pairs (`{"charttype","bar";"max",100}`):

| charttype | Options |
|-----------|---------|
| `line` (default) | `xmin`, `xmax`, `ymin`, `ymax`, `color`, `empty` (`zero`/`ignore`), `nan` (`convert`/`ignore`), `rtl`, `linewidth` |
| `column` | `color`, `lowcolor`, `highcolor`, `firstcolor`, `lastcolor`, `negcolor`, `empty`, `nan`, `axis`, `axiscolor`, `ymin`, `ymax`, `rtl` |
| `winloss` | same as column (values drawn as up/down blocks) |
| `bar` | `max`, `color1`, `color2`, `empty`, `nan`, `rtl` (stacked horizontal bar of 1–2 values) |

Colors accept CSS names and `#RRGGBB`; default colors come from the theme `chart1` token so
sparklines adapt to light/dark when no explicit color is set. Invalid options →
`#VALUE!` "Invalid option for SPARKLINE: x". Data > 10,000 points is down-sampled for rendering
(min/max per pixel bucket).

---

## 18. Formula help UI data

Widget ownership: the autocomplete popup, signature-help card, reference colouring and point mode
are 03's (`features/cell_editor/formula/*`, [03 §8.7](03-grid-and-editing.md)); the error tooltip
is 03's (`features/in_cell/error_tooltip.dart`, 03 §14.7); the Function help dialog and the
Insert › Function menu are 04's ([04 §3.4, §11.20](04-screens-menus-toolbar.md)). This section
defines the **data contract** they render, all served by core (`formula/services/*`, registry).

| UI element (owner) | Data source (core) | Content rules |
|--------------------|--------------------|---------------|
| Function autocomplete popup (03) | `completionsAt` (§4.3) | Items `{kind: builtin\|namedFunction\|customFunction\|namedRange\|letName, name, summary, insertText}`; kind icons: `LucideIcons.squareFunction`, `braces`, `code`, `tag`; matched characters ranges for bold; unimplemented stubs excluded. |
| Signature-help card (03) | `signatureAt` + `FunctionHelp` | `{syntax parts with active param index, activeRepeatGroup, summary, args[{name, description, optional, default}], examples[0], learnMore → sheets.help.functionList {name}}`. Named functions use `NamedRange.metaJson` (§24 F3); script functions use `ScriptBuild.exportsJson` metadata; LAMBDA/LET calls show parameter names only. `F1` expands/collapses, `Shift+F1` shows/hides (03). |
| Live result preview chip (03) | `evaluateDetached` (§7.1) | Formatted value, error code + message, or "(3×4 array)" suffix. |
| Error tooltip (03) | `describeError(cell)` | `{title, message, actions[]}`; titles: "Error", "Formula parse error", "Circular dependency", "Loading…", "Array result too large", "Connect sheets". Actions map to commands in §19: `selectSpillBlockers`, `insertRowsForSpill`, `allowImportRange`, `refreshExternalData`, `showCircularPath` (P1). |
| Parse error underline (03) | `FormulaParseError {offset, length, message}` | Underline span in the editor after a failed commit; message in the card area. |
| Function help dialog & Insert › Function menu (04) | registry export `FunctionCatalog.forUi()` | Categories in the order of §15 plus "Named functions" and "Custom functions"; only `implemented` functions; per function `syntax, summary, args, examples, seeAlso, notes`; *Insert* runs `sheets.insert.function {name}`. |
| Explain formula panel (05, P1, `features/formula_inspect/`) | `engine.explain` | Tree of sub-expressions with values (arrays truncated to 10×10, text to 100 chars); hovering a node outlines its range on the grid via 03's `reference_highlight_layer`. |
| Show formulas view (03 §2.5) | `FormulaCodec.toA1` | A1 text in the spreadsheet locale. |

Reference colours: 03's `referenceColors[0..9]` tokens ([04 §14](04-screens-menus-toolbar.md));
the highlighter returns colour **indices** only.

---

## 19. Commands

Formula-related commands. Commands already defined by [03 §19](03-grid-and-editing.md) /
[04 §3](04-screens-menus-toolbar.md) are listed for completeness with their owner; new ones are
registered in `wonky_sheets/lib/commands/formula_commands.dart`. Undoable commands go
through the session's write path (one step, [02 §7](02-data-model.md)).

| Command id | Title | Default binding (scope) | Args | Undo | Owner / notes |
|------------|-------|-------------------------|------|------|---------------|
| `sheets.view.toggleFormulas` | Show formulas | ``Mod+` `` (grid) | — | — | 03/04; per-user view state |
| `sheets.insert.function` | Insert › Function | — | `{name}` | — | 04; starts editing the active cell with `=NAME(` or inserts at the caret |
| `sheets.help.functionList` | Function help | — | `{name?}` | — | 04 §11.20 |
| `sheets.tools.toggleAutocomplete` | Autocomplete | — | — | — | 03; per user (also gates function autocomplete) |
| `sheets.tools.toggleFormulaSuggestions` | Formula suggestions (AI) | — | — | — | 04/12 |
| `sheets.settings.update` | Spreadsheet settings › Calculation | — | `{recalcMode?, iterativeCalc?, maxIterations?, convergenceThreshold?, locale?, timeZone?}` | 1 | 04 §11.1; calls `engine.settingsChanged` |
| `sheets.calc.recalculateAll` | Recalculate all | `Mod+Shift+F9` (grid) | `{scope: all\|sheet}` | — | id shared with 09 §8.6; dirties everything incl. volatile, custom functions & external refresh; progress in status bar |
| `sheets.formula.toggleArrayFormula` | Toggle ARRAYFORMULA | `Mod+Shift+Enter` (cellEditor) | — | — | new; wraps/unwraps `ARRAYFORMULA(…)` in the editor text |
| `sheets.formula.cycleReferenceType` | Toggle absolute reference | `F4` (cellEditor) | — | — | new id for 03's F4 behavior (03 §8.7); in grid scope F4 = `sheets.edit.repeatLast` |
| `sheets.formula.toggleHelpCard` | Expand formula help | `F1` (cellEditor) | — | — | new; `Shift+F1` = `sheets.formula.toggleHelpCardVisible` |
| `sheets.formula.explain` | Explain formula | — | `{cell?}` | — | new, P1 |
| `sheets.formula.tracePrecedents` / `.traceDependents` / `.clearTraces` | Trace precedents/dependents | — | `{cell?, levels?}` | — | new, P1 (arrow overlay layer) |
| `sheets.formula.goToNextError` / `.goToPreviousError` | Next/previous error | — | `{scope?}` | — | new, P1 |
| `sheets.formula.showCircularPath` | Show circular reference path | — | `{cell}` | — | new, P1 |
| `sheets.formula.selectSpillBlockers` | Select blocking cells | — | `{cell}` | — | new |
| `sheets.formula.insertRowsForSpill` | Insert rows for result | — | `{cell}` | 1 | new; inserts the missing rows/columns |
| `sheets.formula.allowImportRange` | Allow access | — | `{cell}` | — | new; server grant (revocable in Settings › Connected spreadsheets, P1) |
| `sheets.formula.refreshExternalData` | Refresh external data | — | `{range?}` | — | new; IMPORTRANGE/IMPORT* cache bypass, image reload |
| `sheets.formula.refreshAi` | Refresh AI results | — | `{range}` | — | new, P2; confirms when > 20 cells |

---

## 20. MCP

Headless tools run on the server's `HeadlessEngineService`. [12-mcp-and-ai.md](12-mcp-and-ai.md)
owns the final names and schemas; `sheets.evaluate` already exists there, the others are
**proposed additions** for 12:

| Tool | Args | Result | Status |
|------|------|--------|--------|
| `sheets.evaluate` | `spreadsheet, formula, sheet?, cell?` | `{value, formatted, type, array?, error_message?}` — no write | in 12 §3 |
| `sheets.validate_formula` | `formula, locale?` | `{ok, error?: {offset, length, message}, functions_used, references}` (no spreadsheet needed) | proposed |
| `sheets.get_formulas` | `spreadsheet, range` | 2-D array of A1 formulas (null for non-formula cells) — or an option on `sheets.get_values` | proposed |
| `sheets.explain_formula` | `spreadsheet, cell` | Explain tree JSON (P1) | proposed |
| `sheets.get_dependencies` | `spreadsheet, cell, direction: precedents\|dependents, transitive?` | list of A1 ranges | proposed |
| `sheets.find_errors` | `spreadsheet, range?, kinds?` | `[{cell, error, message}]` (paginated) | proposed |
| `sheets.list_functions` | `category?, query?, include_unimplemented?` | `[{name, category, syntax, summary, priority, implemented}]` | proposed |
| `sheets.get_function_help` | `name` | full `FunctionHelp` | proposed |

Writing formulas uses `sheets.set_values` / `sheets.batch_set_values` (inputs starting with `=`
are encoded on the server with `FormulaCodec.toStored` at each target cell). UI-bridge access to
the commands of §19 goes through `ui.invoke_command`. Results include `engine_version`; values match
clients running the same engine version (§12). Cells pending on custom functions are awaited up to
10 s (09 §8.6).

---

## 21. Performance budgets

Measured by `packages/wonky_sheets_core/benchmark/`: `dart run benchmark/<name>.dart` for
`recalc` (full recalc, chain edit, scaling series), `range_reads` (`SUM` over 200k/1M rows,
open ranges after an edit, materializing, used range), `structural` (insert/delete/cut-paste
rows in a 200k-row sheet with 220k formulas, the axis index), `rules` (CF/DV custom formulas,
formulas using a named range) and `viewport` (one background-recalc slice). They run on the
real `WorkbookModel` + `ModelEngineBinding` with UUID ids (not the test `MemoryWorkbook`) and
print the median and minimum of each scenario next to its budget; current numbers and the
budgets not met yet are in [STATUS.md](STATUS.md#benchmarks). Planned: native in CI on every PR
(regressions > 10% fail the job), web wasm + js nightly in headless Chrome (not wired yet).
Cheap scaling assertions that catch quadratic regressions run in the default test suite
(`test/formula/recalc/recalc_drain_perf_test.dart`,
`test/mutations/planner_structure_perf_test.dart`).

| Scenario | Native (desktop AOT, M1/i7-class) | Web (wasm, same machine) |
|----------|-----------------------------------|--------------------------|
| Tokenize + highlight a 200-char formula | < 30 µs | < 100 µs |
| Parse a typical formula (≤ 200 chars) | **< 50 µs** p50, < 200 µs p99 | < 150 µs p50 |
| `toStored` / `toA1` of a typical formula | < 30 µs | < 100 µs |
| Compile with template-cache hit | < 5 µs | < 15 µs |
| Edit → edited cell repainted (≤ 10k precedent cells) | < 16 ms | < 16 ms |
| Recalculate 100k dependent formula cells (arithmetic fan-out/chains) | **< 1 s** total | **< 2 s** total |
| `SUM(A:A)` over 1M numeric rows | < 10 ms | < 25 ms |
| `VLOOKUP(…, FALSE)` filled down 100k rows over a 100k-row table | < 1.5 s | < 3 s |
| `COUNTIF(A:A, A2)` filled down 100k rows | < 1 s | < 2 s |
| Open sheet with 200k formulas from ComputedValueCache → first viewport paint | < 300 ms after viewport data loaded | < 500 ms |
| Build dependency graph for 1M formula cells (background, time-sliced) | < 5 s | < 10 s |
| Full recalc of 1M formula cells without cache | < 20 s | < 45 s |
| UI frame budget during background recalc | no frame > 20 ms | no frame > 24 ms |
| Memory overhead for 1M formula cells | ≤ 200 MB | ≤ 250 MB |

---

## 22. Testing and compatibility strategy

1. **Parser** (per `petitparser-test` skill): tests per production (`buildFrom(ref0(rule))`),
   precedence table tests (`-2^2`, `2^3^2`, `1-2-3`, `"a"&1+2`), locale variants, error positions,
   petitparser linter clean, fuzzing (random token streams: tokenizer never throws; parser never
   throws, only returns failures), 10k-formula corpus from public templates must parse.
2. **Codec property tests**: random formulas × random axis operations (insert/delete/move
   rows/cols, rename/delete sheets) — evaluating the stored formula after the operations equals
   evaluating a positional A1 oracle that applies Excel's reference-adjustment rules; plus
   `toA1(toStored(x)) == normalize(x)`.
3. **Function unit tests**: every function ≥ 3 vectors including an error case and an
   edge case (table-driven vectors next to the category tests).
4. **Golden compatibility vectors**: `test/formula/golden/<category>/*.yaml`:

   ```yaml
   - id: vlookup-approx-unsorted
     setup: {A1: 1, A2: 3, A3: 2, B1: "a", B2: "b", B3: "c"}
     formula: =VLOOKUP(2.5, A1:B3, 2)
     expect: {value: "a"}
     source: gsheets            # gsheets | excel | libreoffice
     captured: 2026-09-01
   ```

   Captured by maintainers with `tool/compat/capture_gsheets.dart` (writes setup + formulas into
   a scratch Google Sheet through the Sheets API with a maintainer's credentials, reads computed
   values back; not run in CI) — results are committed. Target: ≥ 5,000 vectors, every P0
   function ≥ 10.
5. **Differential testing vs LibreOffice** for numeric/statistical/financial functions:
   `tool/compat/lo_diff.py` generates random argument sets, writes an `.ods` with formulas, runs
   `soffice --headless --convert-to csv`, compares with the engine (relative tolerance 1e-9; 1e-6
   for inverse distributions and iterative solvers). Runs nightly; disagreements are triaged:
   Sheets vector decides when Sheets and LibreOffice disagree.
   > **As built (CQ-61).** Golden vectors: `wonky_sheets_core/test/formula/golden/<category>/core.yaml`
   > (math, logical, lookup, text, date, statistical, financial, info, array; 162 vectors, format in
   > `README.yaml`, run by `golden_vectors_test.dart`; an optional `tolerance` and `skip` per vector).
   > They are `source: manual` — values from the behavior Sheets and Excel share, or Sheets' where
   > they differ (CHOOSE out of range `#NUM!`, FILTER without matches `#N/A`) — until the capture
   > tool exists. File corpus: `test/fixtures/compat/*.xlsx|*.ods` (generated by
   > `tool/compat/gen_compat_fixtures.dart` in the layout Excel and LibreOffice write: shared
   > strings and formulas, typed results, errors, dates, cross-sheet references; real saved files
   > can be added); `test/io/compat/compat_corpus_test.dart` imports each file, recalculates and
   > compares every formula with the cached result. The differential is the Dart tool
   > `tool/compat/lo_diff.dart` (instead of `lo_diff.py`: 23 function templates, an ODS without cached
   > results converted to CSV at full precision by `soffice --headless`), run by the nightly
   > `lo-diff` job (`.github/workflows/nightly.yml`); `--dry-run` evaluates the engine side only.
6. **Incremental vs full recalc oracle**: random edit sequences (cells, axis ops, names, sheets)
   on random workbooks — after each step, incremental results == full recompute results.
7. **Determinism**: the same 50 workbooks evaluated on Dart VM, AOT, dart2js and dart2wasm must
   produce byte-identical `valueJson`.
8. **Client convergence**: two simulated clients apply concurrent offline edits (inserts,
   deletes, formula writes, renames) → after sync both engines produce identical values (uses
   the in-process RevLog server `FakeRevServer`, suite 17 As built 16).
9. **Benchmarks** (§21).

---

## 23. Acceptance criteria

- [ ] Typing `=sum(a1:a3)` commits `=SUM(A1:A3)`, shows the sum, and the stored content contains
      id tokens only (no A1 text).
- [ ] Inserting a row between rows 1 and 3 makes the formula display `=SUM(A1:A4)` with the new row
      included; no formula rows are written by the insert (verified on the op's changes).
- [ ] Deleting row 3 (the range end) shrinks the range to `A1:A2`; deleting a referenced single cell's
      row shows `#REF!`; undo restores the original formula display and value.
- [ ] A collaborator inserting rows offline while another edits formulas offline: after sync both
      see identical formulas and values.
- [ ] Renaming a sheet updates every formula's display without any formula write.
- [ ] de_DE spreadsheet: `=ROUND(1,5;0)` (English names, locale separators) works and displays
      with `;`; switching the locale to en_US displays `=ROUND(1.5, 0)` without rewriting cells.
- [ ] `=FILTER(A2:C, B2:B>10)` spills; typing into a spill cell shows `#SPILL!` with the blocking
      address; clearing it restores the spill.
- [ ] `=A1+1` in A1 shows `#REF!` circular error; enabling iterative calculation (50, 0.05) makes it
      compute and increment per recalculation.
- [ ] `=NOW()` updates on every edit and per minute in "every minute" mode; all clients show the
      same RAND() values after syncing the same changes.
- [ ] Autocomplete shows `VLOOKUP` after typing `=vl`; signature card highlights the active
      argument; F4 cycles `$`; unclosed parens are auto-closed on Enter.
- [ ] Unknown function shows `#NAME?` with "Unknown function: 'FOO'."; parse errors show `#ERROR!`
      with the error position underlined.
- [ ] All P0 functions pass their golden vectors; numeric P0/P1 functions pass LibreOffice
      differential tests.
- [ ] Performance budgets of §21 are met in CI benchmarks.
- [ ] MCP `sheets.evaluate` returns the same value as the client shows for the same cell.
- [ ] Opening a 1M-cell spreadsheet with cached values paints the first viewport without waiting
      for recalculation; the status bar shows background progress.

---

## 24. Additions to 02-data-model

| # | Addition | Where | Purpose |
|---|----------|-------|---------|
| F1 | Reference token fields `K:<row sortKey>` / `KC:<column sortKey>` on **range endpoint** tokens (written by `FormulaCodec.toStored`; also allowed in `GridRange` JSON as `"r1k"`, `"r2k"`, `"c1k"`, `"c2k"`) | §2 reference tokens / GridRange | Deterministic range shrinking when an endpoint row/column is deleted concurrently (§5.4). |
| F2 | Reference token field `X:<a1 text>` for **unbound** references | §2 reference tokens | Refs to not-yet-existing sheets or beyond the grid (§5.3). |
| F3 | `NamedRange.metaJson: String?` — `{"kind":"range"\|"function"\|"formula", "description", "params":[{"name","description","example"}], "examples":[…]}` | §3.4 `NamedRange` | Named function metadata for help/autocomplete ([07 §9](07-data-tools.md)). |
| F4 | Client table `ExternalResultCache(key, function, argsHash, valueJson, fetchedAt, expiresAt, sourceStamp)` | §4 local-only | Offline availability of IMPORTRANGE/IMPORT*/AI/custom-function results. |
| F5 | Client table `ComputedValueCacheMeta(spreadsheetId, dataStamp, engineVersion, writtenAt)` | §4 local-only | Validity check for `ComputedValueCache` (§11.1). |
| F6 | `LocalViewState` key `traceOverlays` (P1); `showFormulas` is already proposed by 03 §20 | §4 local-only | View state for §18/§19. |
| F7 | Server tables `ImportRangeGrant(destSpreadsheetUuid, sourceItemId, grantedByUserId, at)`, `ExternalFetchCache(urlHash, kind, paramsHash, fetchedAt, status, payload)`, `AiFunctionResult(spreadsheetUuid, cellId, inputHash, text, model, at)` | §5 server-only | §13. |
| F8 | `UserPreferences.sheetsDefaults.formulaHelpVisible`, `formulaHelpExpanded` (03 §20 already proposes `formulaAutocomplete`, `formulaHelp`; 04 §15 `formulaSuggestions`) | suite 04 prefs | Signature card state. |

---

## 25. Open questions

Resolved: the model lives in `wonky_sheets_core/lib/model/` ([02](02-data-model.md) §6);
`timezone` is an allowed dependency (suite 01 §2.1); [06](06-formatting.md) §15 references the
shared `rules/conditions/` package.

Still open:
1. **Implicit intersection vs. array evaluation** of expression arguments inside aggregates
   (`=SUM(A1:A3*2)` without ARRAYFORMULA): the spec follows the classic Sheets behavior; golden
   vectors must confirm current Google behavior before M3 (also: case sensitivity of `UNIQUE`
   and pivot text grouping).
2. **Write-time range normalization on delete** (§5.4) rewrites formulas referencing deleted
   range endpoints; for sheets with very many such formulas this is a write burst. Alternative:
   rely only on the `K:` fallback. Decide after measuring the commit cost against the RevLog
   performance gates (suite 17 part 7).
