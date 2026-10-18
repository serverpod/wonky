/// Wonky patch DE-22 (PATCHES.md): the compiler and runtime types the Wonky
/// script host (`wonky_sheets_script`) needs that upstream keeps under
/// `src/`, so the host never imports `package:dart_eval/src/…`
/// (`implementation_imports`). An upgrade checks this one file.
library;

export 'src/eval/compiler/errors.dart';
export 'src/eval/runtime/class.dart' show $InstanceImpl;
export 'src/eval/runtime/runtime.dart' show RuntimeException, WrappedException;
