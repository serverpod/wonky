import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_internals.dart' show CompileError;
import 'package:wonky_sheets_core/formula.dart' show FunctionRegistry;

import '../api/api_source.dart';
import '../build/script_exports.dart';
import '../guest/cell_error_binding.dart';
import '../guest/guest_runtime.dart';
import '../guest/runtime_plugin.dart';
import 'diagnostics.dart';
import 'subset_lint.dart';

/// A source file of a script project.
final class ScriptSourceFile {
  /// Creates a file.
  const ScriptSourceFile(this.name, this.source);

  /// File name (`main.dart`).
  final String name;

  /// Dart source.
  final String source;
}

/// Result of [ScriptCompiler.compile] (09 §9.1).
final class ScriptCompileResult {
  /// Creates a result.
  const ScriptCompileResult({
    required this.sourceHash,
    required this.diagnostics,
    required this.exports,
    this.bytecode,
    required this.duration,
  });

  /// `sha256(apiVersion ‖ compilerVersion ‖ sorted(name ‖ \0 ‖ source))`.
  final String sourceHash;

  /// Errors, warnings and hints.
  final List<ScriptDiagnostic> diagnostics;

  /// Exports metadata (also computed for builds with errors when parsing
  /// succeeded).
  final ScriptExports exports;

  /// EVC bytecode; null when there are errors.
  final Uint8List? bytecode;

  /// Compile time.
  final Duration duration;

  /// Whether the build succeeded.
  bool get ok => bytecode != null;

  /// Number of errors.
  int get errorCount => diagnostics.where((d) => d.isError).length;

  /// The program for runners.
  ScriptProgram? get program => bytecode == null
      ? null
      : ScriptProgram(
          buildHash: sourceHash,
          bytecode: bytecode!,
          exports: exports,
        );
}

/// The compile-time half of the Wonky script plugin: the API library source,
/// the host bridge declarations and the `CellError` binding.
final class WonkyCompilerPlugin implements EvalPlugin {
  /// Creates the plugin.
  const WonkyCompilerPlugin();

  @override
  String get identifier => 'wonky';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction(WonkyHostDeclarations.hostCall);
    registry.defineBridgeTopLevelFunction(WonkyHostDeclarations.hostError);
    registry.defineBridgeClass($CellError.$declaration);
    registry.addSource(DartSource(wonkyApiLibrary, wonkyApiSource));
  }

  @override
  void configureForRuntime(Runtime runtime) {
    throw UnsupportedError('Use WonkyRuntimePlugin in runtimes.');
  }
}

/// Compiles script projects to dart_eval bytecode (server only; 09 §9).
///
/// Steps: validate files → parse with the analyzer and run the [SubsetLint]
/// → extract exports → generate the dispatcher `package:script/__exports.dart`
/// → compile with dart_eval and the [WonkyCompilerPlugin].
///
/// Compiling is CPU heavy and synchronous; servers run it in an isolate
/// (`Isolate.run`).
final class ScriptCompiler {
  /// Creates a compiler.
  const ScriptCompiler();

  /// Compiler version recorded in `ScriptBuild.compilerVersion`.
  static const compilerVersion = 'dart_eval-0.8.5+wonky.1';

  /// Max files per project (09 §4).
  static const maxFiles = 50;

  /// Max bytes per file.
  static const maxFileBytes = 500 * 1024;

  /// Max bytes per project.
  static const maxProjectBytes = 2 * 1024 * 1024;

  static final _fileName = RegExp(r'^[a-z][a-z0-9_]{0,63}\.dart$');

  /// The source hash of [files] (09 §9.1 step 2).
  static String sourceHash(List<ScriptSourceFile> files) {
    final sorted = [...files]..sort((a, b) => a.name.compareTo(b.name));
    final b = BytesBuilder(copy: false)
      ..add(utf8.encode('$wonkyApiVersion\u0000$compilerVersion\u0000'));
    for (final f in sorted) {
      b
        ..add(utf8.encode(f.name))
        ..addByte(0)
        ..add(utf8.encode(f.source))
        ..addByte(0);
    }
    return sha256.convert(b.takeBytes()).toString();
  }

  /// sha256 hex of one file (`ScriptFile.contentHash`).
  static String contentHash(String source) =>
      sha256.convert(utf8.encode(source)).toString();

  static bool _isBuiltin(String upper) =>
      FunctionRegistry.standard.lookup(upper) != null;

  /// Diagnostics for unsaved editor content (09 §9.5): parse errors and the
  /// subset lint, no bytecode.
  List<ScriptDiagnostic> analyze(
    String fileName,
    String source, {
    Set<String> projectFiles = const {},
  }) {
    final parsed = _parse(ScriptSourceFile(fileName, source));
    final lint = SubsetLint(
      file: fileName,
      lineInfo: parsed.lineInfo,
      projectFiles: {...projectFiles, fileName},
      isBuiltinFunction: _isBuiltin,
    );
    parsed.unit.accept(lint);
    return [...parsed.diagnostics, ...lint.diagnostics];
  }

  /// Compiles [files].
  ScriptCompileResult compile(List<ScriptSourceFile> files) {
    final watch = Stopwatch()..start();
    final hash = sourceHash(files);
    final diagnostics = <ScriptDiagnostic>[..._validateFiles(files)];
    final names = {for (final f in files) f.name};
    final parsed = <String, _Parsed>{};
    for (final f in files) {
      final p = _parse(f);
      parsed[f.name] = p;
      diagnostics.addAll(p.diagnostics);
      final lint = SubsetLint(
        file: f.name,
        lineInfo: p.lineInfo,
        projectFiles: names,
        isBuiltinFunction: _isBuiltin,
      );
      p.unit.accept(lint);
      diagnostics.addAll(lint.diagnostics);
    }
    final exports = _extractExports(parsed, diagnostics);
    ScriptCompileResult result(Uint8List? bytes) => ScriptCompileResult(
      sourceHash: hash,
      diagnostics: diagnostics,
      exports: ScriptExports(
        apiVersion: exports.apiVersion,
        functions: exports.functions,
        triggers: exports.triggers,
        scopes: exports.scopes,
        customFunctionScopes: exports.customFunctionScopes,
        warnings: diagnostics
            .where((d) => d.severity == DiagnosticSeverity.warning)
            .length,
        lineStarts: exports.lineStarts,
      ),
      bytecode: bytes,
      duration: watch.elapsed,
    );
    if (diagnostics.any((d) => d.isError)) return result(null);

    final dispatcher = generateDispatcher(exports, names);
    final compiler = Compiler()
      ..addPlugin(const WonkyCompilerPlugin())
      ..entrypoints.addAll([
        'package:wonky/wonky.dart',
        'package:script/__exports.dart',
      ]);
    try {
      final program = compiler.compile({
        'script': {
          for (final f in files) f.name: f.source,
          '__exports.dart': dispatcher,
        },
      });
      return result(program.write());
    } on CompileError catch (e) {
      diagnostics.add(_compileErrorDiagnostic(e, parsed));
      return result(null);
    } on Object catch (e) {
      diagnostics.add(
        ScriptDiagnostic(
          severity: DiagnosticSeverity.error,
          code: 'wonky_compiler',
          message: 'The script could not be compiled: $e',
        ),
      );
      return result(null);
    }
  }

  List<ScriptDiagnostic> _validateFiles(List<ScriptSourceFile> files) {
    final out = <ScriptDiagnostic>[];
    ScriptDiagnostic err(String message, [String? file]) => ScriptDiagnostic(
      severity: DiagnosticSeverity.error,
      code: 'wonky_project',
      message: message,
      file: file,
    );
    if (files.isEmpty) out.add(err('The project has no files.'));
    if (files.length > maxFiles) {
      out.add(err('A project can have at most $maxFiles files.'));
    }
    var total = 0;
    final seen = <String>{};
    for (final f in files) {
      final size = utf8.encode(f.source).length;
      total += size;
      if (!_fileName.hasMatch(f.name) || f.name == '__exports.dart') {
        out.add(
          err(
            'Invalid file name "${f.name}": use lower case letters, digits '
            'and "_", ending in ".dart".',
            f.name,
          ),
        );
      }
      if (!seen.add(f.name)) out.add(err('Duplicate file ${f.name}.', f.name));
      if (size > maxFileBytes) {
        out.add(err('${f.name} is larger than 500 KB.', f.name));
      }
    }
    if (total > maxProjectBytes) {
      out.add(err('The project is larger than 2 MB.'));
    }
    return out;
  }

  _Parsed _parse(ScriptSourceFile f) {
    final r = parseString(
      content: f.source,
      featureSet: FeatureSet.latestLanguageVersion(),
      path: '/script/${f.name}',
      throwIfDiagnostics: false,
    );
    final diagnostics = <ScriptDiagnostic>[];
    for (final e in r.errors) {
      final s = r.lineInfo.getLocation(e.offset);
      final end = r.lineInfo.getLocation(e.offset + e.length);
      diagnostics.add(
        ScriptDiagnostic(
          severity: DiagnosticSeverity.error,
          code: e.diagnosticCode.name.toLowerCase(),
          message: e.message,
          file: f.name,
          line: s.lineNumber,
          column: s.columnNumber,
          endLine: end.lineNumber,
          endColumn: end.columnNumber,
          fix: e.correctionMessage,
        ),
      );
    }
    return _Parsed(f, r.unit, r.lineInfo, diagnostics);
  }

  ScriptExports _extractExports(
    Map<String, _Parsed> parsed,
    List<ScriptDiagnostic> diagnostics,
  ) {
    final functions = <ScriptFunctionInfo>[];
    final triggers = <String, String?>{
      for (final t in simpleTriggerNames) t: null,
    };
    final scopes = <String>{};
    final customScopes = <String>{};
    final seen = <String, String>{};
    for (final p in parsed.values) {
      final library = 'package:script/${p.file.name}';
      final scopeScan = _ScopeScanner();
      p.unit.accept(scopeScan);
      scopes.addAll(scopeScan.scopes);
      for (final d in p.unit.declarations) {
        if (d is! FunctionDeclaration || d.isGetter || d.isSetter) continue;
        final name = d.name.lexeme;
        if (name.startsWith('_')) continue;
        final start = p.lineInfo.getLocation(d.name.offset);
        final previous = seen[name];
        if (previous != null) {
          diagnostics.add(
            ScriptDiagnostic(
              severity: DiagnosticSeverity.error,
              code: 'wonky_duplicate_function',
              message:
                  'The function "$name" is also declared in $previous; '
                  'function names must be unique in a project.',
              file: p.file.name,
              line: start.lineNumber,
              column: start.columnNumber,
            ),
          );
          continue;
        }
        seen[name] = p.file.name;
        final info = _functionInfo(d, library, p.lineInfo);
        functions.add(info);
        if (triggers.containsKey(name)) triggers[name] = library;
        if (info.customFunction != null) {
          final s = _ScopeScanner();
          d.accept(s);
          customScopes.addAll(s.scopes);
        }
      }
    }
    return ScriptExports(
      apiVersion: wonkyApiVersion,
      functions: functions,
      triggers: triggers,
      scopes: ['spreadsheet.current', 'ui', ...scopes.toList()..sort()],
      customFunctionScopes: customScopes.toList()..sort(),
      lineStarts: {
        for (final p in parsed.values) p.file.name: p.lineInfo.lineStarts,
      },
    );
  }

  ScriptFunctionInfo _functionInfo(
    FunctionDeclaration d,
    String library,
    LineInfo lineInfo,
  ) {
    final doc = _Doc.parse(d.documentationComment);
    final params = <ScriptParamInfo>[];
    var runnable = true;
    for (final p
        in d.functionExpression.parameters?.parameters ??
            const <FormalParameter>[]) {
      final normal = p is DefaultFormalParameter ? p.parameter : p;
      final type = normal is SimpleFormalParameter ? normal.type : null;
      final name = p.name?.lexeme ?? '';
      if (p.isRequired) runnable = false;
      params.add(
        ScriptParamInfo(
          name: name,
          type: type?.toSource() ?? 'dynamic',
          optional: p.isOptional,
          doc: doc.params[name],
        ),
      );
    }
    final name = d.name.lexeme;
    // Simple triggers take one event parameter; they are runnable.
    if (simpleTriggerNames.contains(name)) runnable = true;
    return ScriptFunctionInfo(
      name: name,
      library: library,
      line: lineInfo.getLocation(d.name.offset).lineNumber,
      endLine: lineInfo.getLocation(d.end).lineNumber,
      params: params,
      returns: d.returnType?.toSource() ?? 'dynamic',
      isAsync: d.functionExpression.body.isAsynchronous,
      doc: doc.summary,
      customFunction: doc.isCustomFunction
          ? CustomFunctionInfo(
              formulaName: name.toUpperCase(),
              examples: doc.examples,
              returnDoc: doc.returns,
            )
          : null,
      runnable: runnable,
    );
  }

  ScriptDiagnostic _compileErrorDiagnostic(
    CompileError e,
    Map<String, _Parsed> parsed,
  ) {
    String? file;
    int? line, column;
    final ctx = e.context;
    final libIndex = e.library ?? ctx?.library;
    if (ctx != null && libIndex != null) {
      for (final entry in ctx.libraryMap.entries) {
        if (entry.value == libIndex) {
          final uri = entry.key;
          if (uri.startsWith('package:script/')) {
            file = uri.substring('package:script/'.length);
          }
        }
      }
    }
    final node = e.node;
    final p = file == null ? null : parsed[file];
    if (node != null && p != null) {
      final loc = p.lineInfo.getLocation(node.offset);
      line = loc.lineNumber;
      column = loc.columnNumber;
    }
    if (file == '__exports.dart') {
      file = null;
      line = null;
      column = null;
    }
    var message = _friendlyCompileMessage(e.message);
    if (file == null) {
      // Error outside the project files (API or dispatcher): keep the
      // compiler's location for bug reports.
      message = '$message ($e)';
    }
    return ScriptDiagnostic(
      severity: DiagnosticSeverity.error,
      code: 'wonky_compile',
      message: message,
      file: file,
      line: line,
      column: column,
    );
  }

  static String _friendlyCompileMessage(String message) {
    if (message.startsWith('Cannot find static method') ||
        message.startsWith('Unknown method') ||
        message.contains('Cannot find')) {
      return '$message. The member may not exist or may not be supported '
          'by the Wonky Dart runtime.';
    }
    return message;
  }

  /// The dispatcher library: references every export (no tree shaking),
  /// builds event objects and passes custom function arguments.
  static String generateDispatcher(ScriptExports exports, Set<String> files) {
    final b = StringBuffer()
      ..writeln("import 'package:wonky/wonky.dart';")
      ..writeln();
    for (final f in files.toList()..sort()) {
      b.writeln("import '$f';");
    }
    b
      ..writeln()
      ..writeln(
        'Object? $scriptInvokeFunction(String name, List<Object?> args, '
        'Map<String, Object?>? event) {',
      );
    for (final f in exports.functions) {
      final isVoid = f.returns == 'void' && !f.isAsync;
      final call = StringBuffer('${f.name}(');
      final isTrigger = simpleTriggerNames.contains(f.name);
      for (var i = 0; i < f.params.length; i++) {
        final p = f.params[i];
        if (i > 0) call.write(', ');
        if (i == 0 && (isTrigger || _isEventType(p.type))) {
          final t = p.type == 'dynamic' ? null : p.type.replaceAll('?', '');
          call.write(
            t == null ? 'wonkyEvent(event)' : 'wonkyEvent(event) as $t',
          );
        } else {
          final cast =
              p.type == 'dynamic' || p.type == 'Object?' || p.type == 'Object'
              ? ''
              : ' as ${p.type}';
          call.write('(args.length > $i ? args[$i] : null)$cast');
        }
      }
      call.write(')');
      b.writeln("  if (name == '${f.name}') {");
      if (isVoid) {
        b
          ..writeln('    $call;')
          ..writeln('    return null;');
      } else {
        b.writeln('    return $call;');
      }
      b.writeln('  }');
    }
    b
      ..writeln(
        "  throw ScriptException('not_found', 'Unknown function \$name');",
      )
      ..writeln('}');
    return b.toString();
  }

  static bool _isEventType(String type) => const {
    'OpenEvent',
    'EditEvent',
    'SelectionChangeEvent',
    'ChangeEvent',
    'TimeEvent',
    'UiEvent',
    'UiEvent?',
    'OpenEvent?',
    'EditEvent?',
    'SelectionChangeEvent?',
    'ChangeEvent?',
    'TimeEvent?',
  }.contains(type);
}

final class _Parsed {
  _Parsed(this.file, this.unit, this.lineInfo, this.diagnostics);
  final ScriptSourceFile file;
  final CompilationUnit unit;
  final LineInfo lineInfo;
  final List<ScriptDiagnostic> diagnostics;
}

/// Detects scopes statically (09 §11.1): references to API members map to
/// scopes.
final class _ScopeScanner extends RecursiveAstVisitor<void> {
  final scopes = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    switch (node.name) {
      case 'UrlFetchApp':
        scopes.add('external_request');
      case 'ScriptApp':
        scopes.add('script.triggers');
      case 'email':
        scopes.add('user.email');
    }
    super.visitSimpleIdentifier(node);
  }
}

/// Parsed doc comment tags (09 §5).
final class _Doc {
  _Doc(
    this.summary,
    this.isCustomFunction,
    this.params,
    this.returns,
    this.examples,
  );

  final String? summary;
  final bool isCustomFunction;
  final Map<String, String> params;
  final String? returns;
  final List<String> examples;

  static _Doc parse(Comment? comment) {
    if (comment == null) return _Doc(null, false, const {}, null, const []);
    final lines = [
      for (final t in comment.tokens)
        t.lexeme.replaceFirst(RegExp(r'^///\s?'), '').trimRight(),
    ];
    final summary = <String>[];
    var inSummary = true;
    var custom = false;
    final params = <String, String>{};
    String? returns;
    final examples = <String>[];
    for (final l in lines) {
      final t = l.trim();
      if (t.startsWith('@')) {
        inSummary = false;
        if (t == '@customfunction') {
          custom = true;
        } else if (t.startsWith('@param ')) {
          final rest = t.substring(7).trim();
          final sp = rest.indexOf(' ');
          if (sp > 0) {
            params[rest.substring(0, sp)] = rest.substring(sp + 1).trim();
          } else if (rest.isNotEmpty) {
            params[rest] = '';
          }
        } else if (t.startsWith('@return')) {
          returns = t.replaceFirst(RegExp(r'^@returns?\s*'), '');
        } else if (t.startsWith('@example')) {
          examples.add(t.substring(8).trim());
        }
        continue;
      }
      if (t.isEmpty) {
        if (summary.isNotEmpty) inSummary = false;
        continue;
      }
      if (inSummary) summary.add(t);
    }
    return _Doc(
      summary.isEmpty ? null : summary.join(' '),
      custom,
      params,
      returns,
      examples,
    );
  }
}
