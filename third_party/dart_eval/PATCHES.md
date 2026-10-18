# Patches

Every change is marked `// WONKY PATCH <id>` in the code and covered by
`test/wonky_patches_test.dart` (or the upstream suite).

| Id | Reason | Files | Spec | Upstream |
|----|--------|-------|------|----------|
| DE-0 | Infra: `resolution: workspace` (workspace member, see VENDORED.md); `analysis_options.yaml` ignores `unrelated_type_equality_checks` (upstream tests, CI runs `--fatal-infos`); dev dependencies `build_runner`/`json_serializable` removed (the generated `*.g.dart` files are checked in; they pulled an old analyzer into the workspace). | `pubspec.yaml` | suite 01 §2.3 | not upstreamable |
| DE-1 | Source positions for stack traces: `PushScope` pushes `name@libraryIndex:offset` labels; `Runtime.throwScopes` keeps the scope stack of the last throw; `Runtime.libraryUriOf(index)`. The script host maps offsets to lines with the build's line tables (09 §13.2). | `runtime/ops/flow.dart`, `runtime/runtime.dart` | Sheets 09 §2, §13.2 | to be upstreamed |
| DE-2 | Cooperative interrupt hook: `Runtime.onCheckpoint` runs every `checkpointInterval` (10,000) instructions and may throw to abort (time limits of the inline runner, cancellation); `Runtime.checkpoints` counts executed instructions; `Runtime.resetExecutionState()` clears the stacks after an aborted run. | `runtime/runtime.dart` | Sheets 09 §2, §8.2.3 | to be upstreamed |
| DE-3 | `$throw` pops the scope name stack together with the frames it unwinds (caught exceptions left stale names). | `runtime/runtime.dart` | Sheets 09 §21 | to be upstreamed |
| DE-4 | Static getters declared in source classes (`static Spreadsheet get active => …`), including classes without static fields. | `compiler/reference.dart` | Sheets 09 §6 | to be upstreamed |
| DE-5 | `toString` on null (string interpolation of a null value) returns `'null'`; other calls on null throw a catchable `NoSuchMethodError` text instead of crashing the runtime. | `runtime/ops/objects.dart` | Sheets 09 §21 | to be upstreamed |
| DE-6 | Boxing a value of a class type is a no-op instead of the compile error "Cannot box X". | `compiler/variable.dart` | Sheets 09 §21 | to be upstreamed |
| DE-7 | `InvokeDynamic`: call sites disagreed on whether `this` is pushed as the first argument (dynamic receivers and script-class receivers push it, operators/interpolation/bridge receivers do not). Sites that push it mark the method name with `\u0001`; script methods get `this` prepended when missing, bridge methods get it removed; members of `Object` on script objects (`toString`, `hashCode`, `==`) resolve instead of falling through to null. Fixes `'$obj'` with an overridden `toString`, operators on script objects and dynamic calls on bridge objects (`dynamic s = 'ab'; s.substring(1)`). | `runtime/ops/objects.dart`, `compiler/expression/method_invocation.dart`, `compiler/helpers/tearoff.dart` | Sheets 09 §21 | to be upstreamed |
| DE-8 | `DateTime.utc(...)`, `DateTime.fromMillisecondsSinceEpoch(ms, {isUtc})` and the weekday constants (`DateTime.monday` …). | `shared/stdlib/core/date_time.dart` | Sheets 09 §6 | to be upstreamed |
| DE-9 | try/catch corrupted the caller's frame offset (`Try` pushed onto `frameOffsetStack` without ever popping, so any function containing a try statement broke its caller when called from a nested block). The frame offset to restore is now encoded in the catch entry; `PushFinally` saves the current frame offset; leaving a try body normally consumes the enclosing finally entry; `PopCatch` is only emitted for try statements with catch clauses. | `runtime/ops/flow.dart`, `runtime/runtime.dart`, `compiler/statement/try.dart` | Sheets 09 §21 | to be upstreamed |
| DE-10 | Unboxing a value of a class type is a no-op (the `!` operator on script objects threw `UnimplementedError`). | `compiler/variable.dart` | Sheets 09 §21 | to be upstreamed |
| DE-11 | Both branches of a conditional expression store a boxed value (`x ? null : 1` crashed with a cast error). | `compiler/expression/conditional.dart` | Sheets 09 §21 | to be upstreamed |
| DE-12 | Integer literals outside the 32-bit operand range come from the constant pool (`1000000000000` overflowed). | `compiler/builtins.dart` | Sheets 09 §21 | to be upstreamed |
| DE-13 | `return` inside a try body with a finally block returned null: the finally block now completes the function's return. | `runtime/ops/flow.dart` | Sheets 09 §21 | to be upstreamed |
| DE-14 | The finally block (compiled before the try body) restores the box/unbox state of locals at its end. | `compiler/statement/try.dart` | Sheets 09 §21 | to be upstreamed |
| DE-15 | Subclasses without constructors called the superclass constructor through a malformed name (`A..`) and crashed the compiler. | `compiler/declaration/constructor.dart` | Sheets 09 §21 | to be upstreamed |
| DE-16 | Box operations pass null and already boxed values through (e.g. a null `String?` in a list literal). | `runtime/ops/primitives.dart` | Sheets 09 §21 | to be upstreamed |
| DE-17 | `==` treats a boxed null (`$null`) like a raw null (omitted optional arguments of static methods compared unequal to null). | `runtime/ops/objects.dart` | Sheets 09 §21 | to be upstreamed |
| DE-18 | Casts to nullable types accept null (`x as String?`): `IsType` gets a nullable flag (bit 1 of its flag byte) and tolerates raw nulls. | `runtime/ops/objects.dart`, `runtime/runtime.dart`, `compiler/expression/as.dart` | Sheets 09 §21 | to be upstreamed |
| DE-19 | Exceptions thrown by script setters can be caught (setters run in the current VM loop like getters instead of a nested `bridgeCall`); `UncatchableException` (exported from `dart_eval_bridge.dart`) marks host exceptions that runtime catch sites must rethrow (time limits, quotas). | `runtime/ops/objects.dart`, `runtime/exception.dart`, `dart_eval_bridge.dart` | Sheets 09 §8.2 | to be upstreamed |
| DE-20 | String interpolation of a `String?` value calls `toString` (a null `String?` crashed with a cast error instead of printing `null`). | `compiler/expression/string_interpolation.dart` | Sheets 09 §21 | to be upstreamed |
| DE-21 | `$Type` no longer implements dart:core `Type`: a second `Type` implementation changes dart2wasm's representation of `Type`, and its dynamic dispatchers then compile every dynamic closure call (`Function f; f()`, e.g. intl's date symbols, sqlite3's loader) to `unreachable`, so the Sheets wasm build crashed on startup. Nothing uses `$Type` as a `Type`. | `shared/stdlib/core/type.dart` | Sheets 09 §23 | to be upstreamed (or a dart2wasm bug report) |
| DE-22 | `lib/dart_eval_internals.dart`: a public library exporting `CompileError` (and the other compiler errors), `$InstanceImpl`, `RuntimeException` and `WrappedException`, which the Wonky script host needs and upstream keeps under `src/`; `wonky_sheets_script` imports no `package:dart_eval/src/` (CQ-64i). | `lib/dart_eval_internals.dart` (new) | Sheets 09 §9 | not upstreamable (upstream hides them on purpose) |

Known limitations that remain (documented in the Wonky Dart guide, Sheets 09 §2): `is` on
an instance creation expression of a class that only *implements* the tested type
(`A() is Exception`) is false (variables work: `final a = A(); a is Exception`); a local
whose box state changes inside a try body before an exception is thrown may be seen in the
wrong representation by the catch block; named arguments to dynamic receivers are not
supported; enums' `name`/`toString` are not supported (the Wonky API uses constant
classes instead).
