# Patches to attributed_text

Every change is marked with `// WONKY PATCH <id>` in the code.

## AT-1 — `addAttribution` inside an existing span corrupts the markers

- **Reason**: adding a compatible attribution to a range that lies strictly inside an existing
  span of the same attribution (e.g. bolding `[3, 8]` of a bold `[2, 9]`) inserted an extra end
  marker at the new range's end. The spans then had two end markers for one start marker, and
  later operations (`copyText`, deletion) threw "unbalanced number of start and end markers".
  Found by the Write editor's random-edit property test
  (`wonky_write/test/features/editor/extractor/change_delta_extractor_test.dart`).
- **Fix**: after removing the interior markers, the new span is capped at `end` only if the
  attribution doesn't continue past `end` (i.e. the first marker of the attribution after `end`
  is not an end marker).
- **Files**: `lib/src/attributed_spans.dart`
- **Tests**: `test/wonky_patches_test.dart`
- **Spec**: Write 04 §10 (inline formatting), §2.2 SE-5 (fixes found by our test suites)
- **Upstream**: to be filed against superlistapp/super_editor (attributed_text); generally
  applicable.

## AT-2 — Log messages built only when logged

- **Reason**: `AttributedSpans` and `AttributedText` interpolated their log messages (every
  marker's and span's `toString()`) on every call, logging on or off. `collapseSpans` runs for
  each text component build, so this showed up in the Write perf suite (CQ-42): with a whole
  100-page document selected, `MultiAttributionSpan.toString` alone was ~4 % of a frame.
- **Changes**: every `_log.fine/finer/finest/info(...)` call passes a closure (`() => '…'`);
  `package:logging` evaluates it only when the level is logged.
- **Files**: `lib/src/attributed_spans.dart`, `lib/src/attributed_text.dart`
- **Tests**: the package's suite (behavior unchanged).
- **Spec**: Write 04 §36
- **Upstream**: generally useful; to be proposed.
