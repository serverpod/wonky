/// Checks the package dependency rules of `specs/01-architecture.md` §2.1.
///
/// Usage (from the repository root, no `pub get` needed for the script itself):
///
/// ```sh
/// dart run tool/check_dependencies.dart          # check every workspace package
/// dart run tool/check_dependencies.dart --help   # this text
/// ```
///
/// What it checks, for every member of the root `pubspec.yaml` `workspace:`:
///
/// 1. **Allowed dependencies**: each entry under `dependencies:` (not
///    `dev_dependencies:`) of the package's `pubspec.yaml` must be in the
///    package's allowed list in [rules] below. The lists mirror the spec table;
///    anything the spec does not list is an explicit, justified exception in
///    [rules] *and* in the spec ("Justified exceptions" under §2.1).
/// 2. **Imports** in `lib/**.dart` and `bin/**.dart` (`import`, `export`,
///    including conditional URIs):
///    - pure-Dart packages (the `*_core` packages, `wonky_sheets_script`,
///      `wonky_sync_models`, `wonky_mcp_stdio`, the server and the client)
///      must not import Flutter or any package that depends on Flutter;
///    - `wonky_ui` must not import client or server code (`wonky_client`,
///      `wonky_server`, `serverpod*`, `wonky_app`);
///    - app families (Write, Sheets, Slides, Drive) must not import each
///      other's packages;
///    - nothing outside `wonky_server` imports `package:wonky_server/`, and no
///      relative import leaves its package (e.g. into
///      `wonky_server/lib/src/generated`);
///    - every imported package is declared under `dependencies:` of the
///      importing package (`depend_on_referenced_packages`, minus `dart:` and
///      the package itself). Exceptions: `lib/driver.dart` (development entry
///      point) may import `dev_dependencies`, and files written by
///      `serverpod generate` are skipped for this one check.
/// 3. **Unused dependencies** (CQ-64i): every entry under `dependencies:` is
///    imported somewhere in `lib/` or `bin/` (one that only tests import
///    belongs under `dev_dependencies:`), and every `dev_dependencies:` entry
///    is imported by a test, tool or benchmark file, `lib/driver.dart`, or
///    named in `analysis_options.yaml` (`wonky_lints`). Packages that work
///    without an import are listed in [_usedWithoutImport] with the reason.
/// 4. **Test imports**: files under `test/`, `integration_test/`,
///    `test_driver/`, `tool/` and `benchmark/` import only declared packages
///    (`dependencies:` or `dev_dependencies:`).
///
/// `third_party/*` packages are external packages and are not checked
/// (01 §2.3 rule 7), also when they are workspace members (as the vendored
/// `dart_eval` is, so Serverpod Cloud uploads it). Whether an external package
/// depends on Flutter is read from `.dart_tool/package_graph.json` (written by `pub get`); without it the
/// script falls back to the package name and says so.
///
/// Output: one line per violation, `package: file:line: message`. Exit code 1
/// when there are violations, 0 otherwise, 64 for bad arguments.
///
/// Run in CI by the `dependencies` job of `.github/workflows/analyze.yml`.
library;

import 'dart:convert';
import 'dart:io';

/// The kind of a workspace package; decides which import rules apply.
enum Kind { pureDart, flutter }

/// The product family of a package: app families never import each other's
/// packages (01 §2.1).
enum Family {
  shared('Shared'),
  write('Write'),
  sheets('Sheets'),
  slides('Slides'),
  drive('Drive');

  const Family(this.label);

  final String label;
}

/// The dependency rule of one workspace package.
class PackageRule {
  const PackageRule({
    required this.kind,
    this.family = Family.shared,
    required this.spec,
    this.exceptions = const {},
    this.forbiddenImports = const [],
  });

  final Kind kind;
  final Family family;

  /// Dependencies listed for the package in the spec table (01 §2.1).
  final Set<String> spec;

  /// Dependencies outside the spec list, each with its one-line
  /// justification. Keep in sync with "Justified exceptions" in 01 §2.1.
  final Map<String, String> exceptions;

  /// Import prefixes (`package:x/` or `package:x`) the package must not use,
  /// beyond the general rules.
  final List<String> forbiddenImports;

  bool allows(String dependency) =>
      spec.contains(dependency) ||
      exceptions.containsKey(dependency) ||
      _commonPure.containsKey(dependency) ||
      (kind == Kind.flutter && _commonFlutter.containsKey(dependency));
}

/// Basic pure-Dart utilities every package may depend on (01 §2.1).
const _commonPure = {
  'collection': 'collection utilities (dart-lang)',
  'meta': 'annotations (dart-lang)',
  'clock': 'injectable time for deterministic tests (15 §4)',
  'characters': 'grapheme clusters (dart-lang)',
  'path': 'path manipulation (dart-lang)',
  'uuid': 'ids (01 §3)',
  'intl': 'number/date formatting and l10n (dart-lang)',
};

/// SDK and template basics every Flutter package may depend on (01 §2.1).
const _commonFlutter = {
  'flutter': 'Flutter SDK',
  'flutter_localizations': 'Flutter SDK l10n',
  'flutter_web_plugins': 'Flutter SDK (URL strategy)',
  'web': 'browser APIs behind conditional imports',
  'cupertino_icons': 'flutter create template',
};

/// Shared by both apps beyond the spec lists.
const _appExceptions = {
  'wonky_core': 'ids, commands and undo abstractions (pure Dart)',
  'wonky_client':
      'repositories call the app\'s endpoints (never widgets, 11 §6)',
  'shad': 'UI is built with shad (02)',
  'go_router': 'app routes (A9)',
};

/// The allowed dependencies per workspace package. Mirrors 01 §2.1.
const rules = <String, PackageRule>{
  'wonky_core': PackageRule(kind: Kind.pureDart, spec: {}),
  'wonky_write_core': PackageRule(
    kind: Kind.pureDart,
    family: Family.write,
    spec: {
      'wonky_core',
      'dart_quill_delta',
      'markdown',
      'html',
      'pdf',
      'archive',
      'xml',
      'image',
      'crypto',
      'wonky_code',
      're_highlight',
      'wonky_rich_text',
      'wonky_fonts',
    },
    exceptions: {
      'diff_match_patch':
          'minimal text diffs for overlay-preserving Delta diffs (DeltaDiff)',
    },
  ),
  'wonky_sheets_core': PackageRule(
    kind: Kind.pureDart,
    family: Family.sheets,
    spec: {
      'wonky_revlog',
      'wonky_core',
      'wonky_charts',
      'wonky_numfmt',
      'wonky_sync_models',
      'petitparser',
      'intl',
      'timezone',
      'archive',
      'xml',
      'csv',
      'pdf',
      'image',
    },
    exceptions: {
      'vector_math':
          'Matrix4 for PdfGraphics.setTransform (a dependency of pdf)',
    },
  ),
  // Shared chart engine and number formats (v2; Slides 08 §2, Sheets 08 §24).
  'wonky_numfmt': PackageRule(
    kind: Kind.pureDart,
    spec: {'intl', 'petitparser'},
  ),
  'wonky_charts': PackageRule(
    kind: Kind.pureDart,
    spec: {'wonky_core', 'wonky_numfmt', 'pdf', 'image', 'vector_math'},
    exceptions: {
      'archive':
          'gzip of large chart snapshot columns (Slides 08 §3.3, SL-27); '
          'already resolved through image',
    },
  ),
  'wonky_charts_flutter': PackageRule(
    kind: Kind.flutter,
    spec: {'wonky_charts', 'wonky_ui', 'shad', 'flutter_scene', 'vector_math'},
  ),
  // Shared code highlighting (v2; Slides 07 §2, Write 04 §15.5). Leaves:
  // no app family, shell, client or server code.
  // Shared rich text, fonts and spell checking (v2; v2 review Q4/Q23, Drive
  // 05 D-7). Leaves: no app family, shell, client or server code. Fonts and
  // dictionaries are package assets (`flutter: assets:`), the code is pure.
  'wonky_rich_text': PackageRule(
    kind: Kind.pureDart,
    spec: {'wonky_core', 'dart_quill_delta', 'markdown'},
    forbiddenImports: _sharedLeafForbidden,
  ),
  // Shared analysis options (CQ-64e): only YAML files that include the lint
  // sets; every package lists it under dev_dependencies.
  'wonky_lints': PackageRule(
    kind: Kind.pureDart,
    spec: {},
    exceptions: {
      'lints': 'lib/dart.yaml includes lints/recommended.yaml',
      'flutter_lints': 'lib/flutter.yaml includes flutter_lints/flutter.yaml',
    },
  ),
  'wonky_fonts': PackageRule(
    kind: Kind.pureDart,
    spec: {},
    forbiddenImports: _sharedLeafForbidden,
  ),
  'wonky_spellcheck': PackageRule(
    kind: Kind.pureDart,
    spec: {'wonky_core'},
    forbiddenImports: _sharedLeafForbidden,
  ),
  'wonky_code': PackageRule(
    kind: Kind.pureDart,
    spec: {'wonky_core', 'string_scanner', 'highlight'},
    forbiddenImports: [..._sharedLeafForbidden, 'package:wonky_code_flutter'],
  ),
  'wonky_code_flutter': PackageRule(
    kind: Kind.flutter,
    spec: {'wonky_code', 'wonky_ui', 'shad', 're_editor'},
    forbiddenImports: _sharedLeafForbidden,
  ),
  // Shared lightweight WYSIWYG Markdown editor (specs/16 §7.3): the
  // vendored super_editor on the shared inline Markdown codec. A Flutter
  // leaf below the shell: no app family, shell, client or server code.
  'wonky_rich_editor': PackageRule(
    kind: Kind.flutter,
    spec: {'super_editor', 'wonky_rich_text', 'wonky_ui', 'shad', 'markdown'},
    exceptions: {'flutter_test': 'enterMarkdown in lib/testing.dart (15 §7)'},
    forbiddenImports: _sharedLeafForbidden,
  ),
  // Slides core (v2; Slides 01 §7): pure Dart, never imports Write or Sheets
  // packages (v2 review Q4); the family rule enforces that.
  'wonky_slides_core': PackageRule(
    kind: Kind.pureDart,
    family: Family.slides,
    spec: {
      'wonky_revlog',
      'wonky_core',
      'wonky_sync_models',
      'wonky_charts',
      'wonky_numfmt',
      'wonky_code',
      'wonky_rich_text',
      'wonky_fonts',
      'pdf',
      'image',
      'vector_math',
      'crypto',
      // Clipboard HTML: tables and rich text pasted from other apps
      // (Slides 03 §12.5, SL-18).
      'html',
    },
    exceptions: {
      'archive':
          'gzip NDJSON version snapshots shared by server and client '
          '(Slides 09 §4.1, SL-39); already resolved through image',
    },
  ),
  'wonky_sheets_script': PackageRule(
    kind: Kind.pureDart,
    family: Family.sheets,
    spec: {
      'wonky_core',
      'wonky_sheets_core',
      'dart_eval',
      'eval_annotation',
      'native_synchronization',
    },
    exceptions: {
      'wonky_sync_models': 'id generators and table names of the script tables',
      'crypto': 'source hashes and Utilities.computeDigest/computeHmac',
      'analyzer':
          'subset lint and exports of the server-only compiler (compiler.dart)',
    },
  ),
  // Pure-Dart id helpers of Sheets and Slides (UUIDv5 ids, generators,
  // fractional indexes).
  'wonky_sync_models': PackageRule(
    kind: Kind.pureDart,
    spec: {'wonky_revlog', 'uuid'},
  ),
  // RevLog (Sheets sync migration spec 02): the server-sequenced op log's
  // shared core (schema, codec, apply rules, client state machine). Pure
  // Dart, below the app cores and the server.
  'wonky_revlog': PackageRule(
    kind: Kind.pureDart,
    spec: {'wonky_core', 'archive', 'collection', 'meta', 'uuid'},
    forbiddenImports: [
      ..._appFamilyForbidden,
      'package:wonky_app',
      'package:wonky_client',
      'package:wonky_server',
      'package:wonky_sync_models',
    ],
  ),
  // The RevLog client (Sheets sync migration spec 06): local cache,
  // transport and per-file connection, shared by the apps.
  'wonky_revlog_flutter': PackageRule(
    kind: Kind.flutter,
    spec: {
      'wonky_revlog',
      'wonky_app',
      'wonky_ui',
      'wonky_client',
      'sqlite_async',
      'clock',
      'collection',
      'meta',
      'uuid',
      'web',
    },
    exceptions: {'wonky_core': 'roles (pure Dart)'},
    forbiddenImports: [
      ..._appFamilyForbidden,
      'package:wonky_server',
      'package:wonky_sync_models',
    ],
  ),
  'wonky_mcp_stdio': PackageRule(kind: Kind.pureDart, spec: {'args', 'http'}),
  'wonky_server': PackageRule(
    kind: Kind.pureDart,
    spec: {
      'serverpod',
      'serverpod_auth_idp_server',
      'serverpod_cloud_storage',
      'wonky_core',
      'wonky_write_core',
      'wonky_sheets_core',
      'wonky_sheets_script',
      'wonky_slides_core',
      'wonky_revlog',
      'wonky_sync_models',
      'wonky_code',
      'mcp_dart',
      'http',
      'dartantic_ai',
    },
    exceptions: {
      'crypto': 'token and content hashes',
      'dart_quill_delta': 'server-authoritative OT over Deltas (A4)',
      'yaml': 'reads the wonky/mcp/ai sections of the config files',
      'image': 'Drive upload previews and thumbnails (Drive 02 §6)',
      'mime': 'MIME sniffing of uploaded files (Drive 02 §5, suite 13 §6)',
      'dart_jsonwebtoken': 'RS256 JWT of the GitHub App (specs/16 §13.3)',
    },
  ),
  'wonky_client': PackageRule(
    kind: Kind.pureDart,
    spec: {
      'serverpod_client',
      'serverpod_auth_idp_client',
      'serverpod_auth_core_client',
      'serverpod_database',
    },
  ),
  'wonky_ui': PackageRule(
    kind: Kind.flutter,
    spec: {'flutter', 'shad'},
    exceptions: {
      'flutter_svg': 'empty-state illustrations (already a dependency of shad)',
      'flutter_test': 'pumpWonky in lib/testing.dart (15 §7)',
    },
    forbiddenImports: [
      'package:wonky_client',
      'package:wonky_server',
      'package:wonky_app',
      'package:serverpod',
    ],
  ),
  'wonky_app': PackageRule(
    kind: Kind.flutter,
    spec: {
      'wonky_ui',
      'wonky_core',
      'wonky_client',
      'serverpod_flutter',
      'serverpod_auth_idp_flutter',
      'go_router',
      'provider',
      'mcp_dart',
      'wonky_spellcheck',
      'wonky_fonts',
      'wonky_rich_editor',
    },
    exceptions: {
      'shad': 'UI is built with shad (02)',
      'flutter_test':
          'pumpShell / CommandTestHarness in lib/testing.dart (15 §7)',
      'serverpod_auth_idp_client': 'auth types used by the auth controller',
      'desktop_drop': 'drop files from the OS onto the drive (desktop)',
      'url_launcher': 'opening the other app on desktop, external links',
      'shared_preferences': 'per-device settings (LocalStore)',
      'sqlite_async': 'offline cache and outbox (LocalDatabase, 12)',
      'crypto': 'PKCE code challenge of Sign in with Google on web (04 §1.6)',
      'path_provider': 'location of the desktop database file',
    },
  ),
  'wonky_write': PackageRule(
    kind: Kind.flutter,
    family: Family.write,
    spec: {
      'wonky_app',
      'wonky_ui',
      'wonky_write_core',
      'wonky_code',
      'wonky_code_flutter',
      'super_editor',
      'super_clipboard',
      'printing',
      'file_saver',
      'file_picker',
    },
    exceptions: {
      ..._appExceptions,
      'dart_quill_delta': 'client side of the Delta OT (A4)',
      'http': 'fetches server-side exports',
      'sqlite_async': 'offline document cache (with wonky_app LocalDatabase)',
    },
  ),
  'wonky_drive': PackageRule(
    kind: Kind.flutter,
    family: Family.drive,
    spec: {
      'wonky_app',
      'wonky_ui',
      'wonky_code_flutter',
      'file_picker',
      'file_saver',
      'http',
    },
    exceptions: _appExceptions,
  ),
  // The Slides app (01 §2.1, Slides 01 §7): SL-1 is the skeleton and only
  // uses the shell; the rest of the list joins with the work packages that
  // use it (Slides 12 §4).
  'wonky_slides': PackageRule(
    kind: Kind.flutter,
    family: Family.slides,
    spec: {
      'wonky_app',
      'wonky_ui',
      'wonky_slides_core',
      'wonky_revlog',
      'wonky_revlog_flutter',
      'wonky_charts',
      'wonky_charts_flutter',
      'wonky_code_flutter',
      'wonky_rich_text',
      'wonky_fonts',
      'super_editor',
      'super_clipboard',
      'printing',
      'file_saver',
      'file_picker',
      'flutter_scene',
      'vector_math',
    },
    exceptions: {
      ..._appExceptions,
      'wonky_sync_models': 'id generators and fractional indexes (pure Dart)',
      'http': 'downloading uploaded images from signed URLs (Slides 03 §6.5)',
      'flutter_svg': 'rasterizing SVG images on insert (Slides 03 §6.5.1)',
      'qr': 'QR code of the presentation audience link (Slides 10 §5.2)',
    },
  ),
  'wonky_sheets': PackageRule(
    kind: Kind.flutter,
    family: Family.sheets,
    spec: {
      'wonky_app',
      'wonky_ui',
      'wonky_sheets_core',
      'wonky_sheets_script',
      'wonky_charts_flutter',
      'wonky_revlog',
      'wonky_revlog_flutter',
      'two_dimensional_scrollables',
      'super_clipboard',
      're_editor',
      'printing',
      'file_saver',
      'file_picker',
    },
    exceptions: {
      ..._appExceptions,
      'wonky_sync_models': 'id generators and fractional indexes (pure Dart)',
      'timezone': 'IANA time zone list of the spreadsheet settings (06 §5.8)',
      'desktop_drop': 'file drops on the grid on desktop (Sheets 11 §2)',
      'http': 'fetching XLSX images and URL imports (Sheets 11 §2)',
      'pdf': 'client PDF export and print preview (Sheets 11 §7)',
      're_highlight':
          'Dart grammar for the script editor (re_editor, Sheets 09 §14.2)',
      'crypto': 'ScriptFile.contentHash sha256 (Sheets 09 A-09-2)',
      'archive': 'gunzip of version snapshots (Sheets 10 §5.1.2)',
      'flutter_svg': 'rasterizing SVG images on insert (Sheets 08 §10.1)',
    },
    // The script compiler (and the analyzer) is server only (01 A8, Sheets
    // 09 §3.1): the app only instantiates dart_eval runtimes.
    forbiddenImports: [
      'package:wonky_sheets_script/compiler.dart',
      'package:wonky_sheets_script/testing.dart',
      'package:analyzer',
      'package:dart_eval/dart_eval.dart',
    ],
  ),
};

/// Imports the shared leaf packages (`wonky_code*`, …) must not use: app
/// families, the shell, client and server code (01 §2.1).
const _sharedLeafForbidden = [
  'package:wonky_write',
  'package:wonky_write_core',
  'package:wonky_sheets',
  'package:wonky_sheets_core',
  'package:wonky_sheets_script',
  'package:wonky_slides',
  'package:wonky_slides_core',
  'package:wonky_drive',
  'package:wonky_app',
  'package:wonky_client',
  'package:wonky_server',
  'package:wonky_sync_models',
  'package:serverpod',
];

/// The packages of every app family (01 §2.1), which the shared packages
/// below the families must not import.
const _appFamilyForbidden = [
  'package:wonky_write/',
  'package:wonky_write_core/',
  'package:wonky_sheets/',
  'package:wonky_sheets_core/',
  'package:wonky_sheets_script/',
  'package:wonky_slides/',
  'package:wonky_slides_core/',
  'package:wonky_drive/',
];

/// Entry points run only in development (`target: lib/driver.dart` under
/// `serverpod: flutter_apps:`), which may import `dev_dependencies`.
const _devEntryPoints = {'lib/driver.dart'};

/// Folders of test, tool and benchmark code: their imports must be declared
/// (`dependencies:` or `dev_dependencies:`), and they are what uses the
/// `dev_dependencies:`.
const _devFolders = [
  'test',
  'integration_test',
  'test_driver',
  'tool',
  'benchmark',
];

/// Dependencies a package needs although no file imports them, per package,
/// with the reason (check 3). Keep this short: a dependency nobody imports is
/// usually dead.
const _usedWithoutImport = <String, Map<String, String>>{
  'wonky_lints': {
    'lints': 'included by lib/dart.yaml',
    'flutter_lints': 'included by lib/flutter.yaml',
  },
  'wonky_revlog_flutter': {
    'sqlite3':
        'pins the sqlite3 version whose build hook provides the native '
        'library the store tests open through sqlite_async',
  },
};

/// The first lines of files written by `serverpod generate`. Generated code
/// may import packages that the generator's runtime packages provide
/// transitively (e.g. `serverpod_auth_core_*`, `http`); the undeclared-package
/// check skips it, the other rules still apply.
const _generatedMarker = 'AUTOMATICALLY GENERATED CODE DO NOT MODIFY';

/// The packages of each app family (01 §2.1); shared packages are in none.
const _familyPackages = <Family, Set<String>>{
  Family.write: {'wonky_write', 'wonky_write_core'},
  Family.sheets: {'wonky_sheets', 'wonky_sheets_core', 'wonky_sheets_script'},
  Family.slides: {'wonky_slides', 'wonky_slides_core'},
  Family.drive: {'wonky_drive'},
};

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }
  if (args.isNotEmpty) {
    stderr.writeln('Unknown arguments: ${args.join(' ')}\n\n$_usage');
    exitCode = 64;
    return;
  }

  final root = _findRoot();
  if (root == null) {
    stderr.writeln(
      'Run from inside the repository (no workspace pubspec.yaml '
      'found in the current directory or its parents).',
    );
    exitCode = 64;
    return;
  }

  final violations = <String>[];
  final graph = _PackageGraph.load(root);
  if (!graph.available) {
    stderr.writeln(
      'Note: .dart_tool/package_graph.json not found; run '
      '`flutter pub get` for exact Flutter detection of external packages.',
    );
  }

  final members = _workspaceMembers(
    root,
  ).where((m) => !m.startsWith('third_party/')).toList();
  for (final memberPath in members) {
    final dir = Directory('${root.path}/$memberPath');
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) {
      violations.add('$memberPath: pubspec.yaml: workspace member is missing');
      continue;
    }
    final spec = _Pubspec.parse(pubspec.readAsLinesSync());
    final name = spec.name ?? memberPath;
    final rule = rules[name];
    if (rule == null) {
      violations.add(
        '$name: $memberPath/pubspec.yaml:1: no dependency rule '
        'for this package; add it to tool/check_dependencies.dart and to '
        'specs/01-architecture.md §2.1',
      );
      continue;
    }

    for (final MapEntry(key: dep, value: line) in spec.dependencies.entries) {
      if (!rule.allows(dep)) {
        violations.add(
          '$name: $memberPath/pubspec.yaml:$line: dependency '
          '"$dep" is not allowed by specs/01-architecture.md §2.1 (add it '
          'to the spec and tool/check_dependencies.dart with a '
          'justification, or remove it)',
        );
      }
      if (rule.kind == Kind.pureDart && graph.dependsOnFlutter(dep)) {
        violations.add(
          '$name: $memberPath/pubspec.yaml:$line: pure-Dart '
          'package depends on "$dep", which is or depends on Flutter',
        );
      }
    }

    // Packages imported by lib/ and bin/ (minus lib/driver.dart), and by
    // the development code (tests, tools, benchmarks, lib/driver.dart).
    final libUsed = <String>{};
    final devUsed = <String>{};
    for (final sub in ['lib', 'bin']) {
      for (final file in _dartFiles(Directory('${dir.path}/$sub'))) {
        _checkFile(
          root: root,
          packageDir: dir,
          packageName: name,
          rule: rule,
          declared: spec.dependencies.keys.toSet(),
          devDeclared: spec.devDependencies.keys.toSet(),
          graph: graph,
          file: file,
          violations: violations,
          used: libUsed,
          devUsed: devUsed,
        );
      }
    }
    for (final sub in _devFolders) {
      for (final file in _dartFiles(Directory('${dir.path}/$sub'))) {
        _checkDevFile(
          root: root,
          packageName: name,
          declared: {...spec.dependencies.keys, ...spec.devDependencies.keys},
          file: file,
          violations: violations,
          used: devUsed,
        );
      }
    }

    final options = File('${dir.path}/analysis_options.yaml');
    final optionsText = options.existsSync() ? options.readAsStringSync() : '';
    final allowed = _usedWithoutImport[name] ?? const {};
    for (final MapEntry(key: dep, value: line) in spec.dependencies.entries) {
      if (dep == 'flutter' || allowed.containsKey(dep)) continue;
      if (libUsed.contains(dep)) continue;
      violations.add(
        devUsed.contains(dep)
            ? '$name: $memberPath/pubspec.yaml:$line: dependency "$dep" '
                  'is only imported by tests or tools; move it to '
                  '`dev_dependencies:`'
            : '$name: $memberPath/pubspec.yaml:$line: dependency "$dep" '
                  'is not imported by lib/ or bin/; remove it (or list it '
                  'in _usedWithoutImport with the reason)',
      );
    }
    for (final MapEntry(key: dep, value: line)
        in spec.devDependencies.entries) {
      if (allowed.containsKey(dep)) continue;
      if (devUsed.contains(dep) || libUsed.contains(dep)) continue;
      if (optionsText.contains('package:$dep/')) continue;
      violations.add(
        '$name: $memberPath/pubspec.yaml:$line: dev dependency "$dep" is '
        'not imported by any test, tool or benchmark; remove it (or list '
        'it in _usedWithoutImport with the reason)',
      );
    }
  }

  for (final v in violations) {
    stdout.writeln(v);
  }
  if (violations.isEmpty) {
    stdout.writeln('Dependency rules OK (${members.length} packages).');
  } else {
    stdout.writeln(
      '\n${violations.length} dependency rule violation(s); see '
      'specs/01-architecture.md §2.1.',
    );
    exitCode = 1;
  }
}

const _usage = '''
Checks the package dependency rules of specs/01-architecture.md §2.1.

Usage: dart run tool/check_dependencies.dart [--help]

Checks every workspace member's pubspec `dependencies` against its allowed
list and scans lib/ and bin/ imports for forbidden edges (Flutter in pure-Dart
packages, client/server code in wonky_ui, Write <-> Sheets, wonky_server
outside the server, undeclared packages), unused dependencies and the imports
of tests and tools. Prints `package: file:line: message`
per violation; exits 1 on violations, 0 otherwise.''';

void _checkFile({
  required Directory root,
  required Directory packageDir,
  required String packageName,
  required PackageRule rule,
  required Set<String> declared,
  required Set<String> devDeclared,
  required _PackageGraph graph,
  required File file,
  required List<String> violations,
  required Set<String> used,
  required Set<String> devUsed,
}) {
  final rel = file.path.substring(root.path.length + 1);
  final packageRel = file.path
      .substring(packageDir.path.length + 1)
      .replaceAll(r'\', '/');
  final lines = file.readAsLinesSync();
  final generated = lines.take(5).any((l) => l.contains(_generatedMarker));
  final devEntryPoint = _devEntryPoints.contains(packageRel);
  for (final directive in _directives(lines)) {
    final uri = directive.uri;
    void report(String message) =>
        violations.add('$packageName: $rel:${directive.line}: $message');

    if (uri.startsWith('dart:')) continue;
    if (_importedPackage(uri) case final p?) {
      (devEntryPoint ? devUsed : used).add(p);
    }
    if (!uri.startsWith('package:')) {
      if (uri.contains(':')) continue; // Other schemes; not ours to judge.
      final target = File(file.parent.uri.resolve(uri).toFilePath());
      final pkg = packageDir.absolute.uri.toFilePath();
      if (!target.absolute.path.startsWith(pkg)) {
        report(
          'relative import "$uri" leaves the package; import through '
          'a declared package instead',
        );
      }
      continue;
    }

    final slash = uri.indexOf('/');
    final imported = uri.substring('package:'.length, slash < 0 ? null : slash);
    if (imported == packageName) continue;

    final isDeclared =
        declared.contains(imported) ||
        (devEntryPoint && devDeclared.contains(imported));
    if (!isDeclared && !generated) {
      report(
        'imports "$uri" but "$imported" is not under `dependencies:` '
        'in pubspec.yaml',
      );
    }
    if (rule.kind == Kind.pureDart && graph.dependsOnFlutter(imported)) {
      report('pure-Dart package imports "$uri", which is Flutter code');
    }
    if (imported == 'wonky_server') {
      report(
        'imports server code ("$uri"); use wonky_client or a shared '
        'core package',
      );
    }
    for (final prefix in rule.forbiddenImports) {
      if (uri.startsWith(prefix)) {
        report(
          'imports "$uri", which $packageName must not use (client, '
          'server or server-only code)',
        );
        break;
      }
    }
    if (rule.family != Family.shared) {
      for (final MapEntry(key: family, value: packages)
          in _familyPackages.entries) {
        if (family != rule.family && packages.contains(imported)) {
          report(
            '${rule.family.label} package imports ${family.label} package '
            '"$imported"',
          );
        }
      }
    }
  }
}

/// Checks the imports of a test, tool or benchmark [file] (check 4) and adds
/// the packages it imports to [used].
void _checkDevFile({
  required Directory root,
  required String packageName,
  required Set<String> declared,
  required File file,
  required List<String> violations,
  required Set<String> used,
}) {
  final rel = file.path.substring(root.path.length + 1).replaceAll(r'\', '/');
  final lines = file.readAsLinesSync();
  // The generated test tools import the generator's runtime packages.
  final generated = lines.take(5).any((l) => l.contains(_generatedMarker));
  for (final directive in _directives(lines)) {
    final imported = _importedPackage(directive.uri);
    if (imported == null || imported == packageName) continue;
    used.add(imported);
    if (!declared.contains(imported) && !generated) {
      violations.add(
        '$packageName: $rel:${directive.line}: imports '
        '"${directive.uri}" but "$imported" is not under `dependencies:` or '
        '`dev_dependencies:` in pubspec.yaml',
      );
    }
  }
}

/// The package of a `package:` [uri], or null for other URIs.
String? _importedPackage(String uri) {
  if (!uri.startsWith('package:')) return null;
  final slash = uri.indexOf('/');
  return uri.substring('package:'.length, slash < 0 ? null : slash);
}

/// The `.dart` files under [dir] (none when it doesn't exist), sorted.
List<File> _dartFiles(Directory dir) {
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// An `import`/`export` URI and the line its directive starts on.
typedef _Directive = ({String uri, int line});

final _directiveStart = RegExp(r'^(import|export)\b');
final _quoted = RegExp(r'''(==\s*)?(['"])([^'"]*)\2''');
final _preamble = RegExp(r'^(library\b|part\b|@|//|/\*|\*|import\b|export\b)');

/// The import/export directives of a Dart file. Stops at the first line that
/// is not part of the directive preamble, so code generating Dart source (in
/// string literals) is not mistaken for imports.
List<_Directive> _directives(List<String> lines) {
  final result = <_Directive>[];
  var inBlockComment = false;
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    if (inBlockComment) {
      final end = line.indexOf('*/');
      if (end < 0) continue;
      inBlockComment = false;
      line = line.substring(end + 2).trim();
    }
    if (line.isEmpty) continue;
    if (line.startsWith('/*') && !line.contains('*/')) {
      inBlockComment = true;
      continue;
    }
    if (!_preamble.hasMatch(line)) break;
    if (!_directiveStart.hasMatch(line)) {
      // `library`, `part`, annotations: skip to the end of the statement.
      continue;
    }
    final start = i;
    final buffer = StringBuffer(line);
    while (!buffer.toString().contains(';') && i + 1 < lines.length) {
      buffer.write(' ${lines[++i].trim()}');
    }
    var text = buffer.toString();
    text = text.substring(0, text.indexOf(';') + 1);
    for (final m in _quoted.allMatches(text)) {
      if (m.group(1) != null) continue; // `if (dart.library.x == 'true')`
      result.add((uri: m.group(3)!, line: start + 1));
    }
  }
  return result;
}

/// The repository root: the nearest directory with a pubspec.yaml that has a
/// `workspace:` key.
Directory? _findRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        pubspec.readAsLinesSync().any((l) => l.startsWith('workspace:'))) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// The `workspace:` entries of the root pubspec.
List<String> _workspaceMembers(Directory root) {
  final members = <String>[];
  var inWorkspace = false;
  for (final raw in File('${root.path}/pubspec.yaml').readAsLinesSync()) {
    final line = _stripComment(raw);
    if (line.trim().isEmpty) continue;
    if (!line.startsWith(' ') && !line.startsWith('-')) {
      inWorkspace = line.startsWith('workspace:');
      continue;
    }
    if (inWorkspace) {
      final m = RegExp(r'^\s*-\s*(.+?)\s*$').firstMatch(line);
      if (m != null) members.add(_unquote(m.group(1)!));
    }
  }
  return members;
}

/// The parts of a pubspec this script needs. A tiny line-based reader: the
/// workspace pubspecs use plain block YAML with two-space indentation.
class _Pubspec {
  _Pubspec(this.name, this.dependencies, this.devDependencies);

  factory _Pubspec.parse(List<String> lines) {
    String? name;
    final deps = <String, int>{};
    final devDeps = <String, int>{};
    String? section;
    int? indent;
    for (var i = 0; i < lines.length; i++) {
      final line = _stripComment(lines[i]);
      if (line.trim().isEmpty) continue;
      final lineIndent = line.length - line.trimLeft().length;
      if (lineIndent == 0) {
        final key = line.split(':').first.trim();
        section = key;
        indent = null;
        if (key == 'name') name = _unquote(line.split(':').skip(1).join(':'));
        continue;
      }
      final target = switch (section) {
        'dependencies' => deps,
        'dev_dependencies' => devDeps,
        _ => null,
      };
      if (target == null) continue;
      indent ??= lineIndent;
      if (lineIndent != indent) continue; // Nested (sdk:, path:, version:).
      final m = RegExp(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:').firstMatch(line);
      if (m != null) target[m.group(1)!] = i + 1;
    }
    return _Pubspec(name, deps, devDeps);
  }

  final String? name;

  /// Dependency name → line number in the pubspec.
  final Map<String, int> dependencies;

  /// `dev_dependencies` name → line number.
  final Map<String, int> devDependencies;
}

String _stripComment(String line) {
  // Good enough for pubspecs: `#` starts a comment unless inside quotes.
  var quote = '';
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quote.isNotEmpty) {
      if (c == quote) quote = '';
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == '#' && (i == 0 || line[i - 1] == ' ')) {
      return line.substring(0, i).trimRight();
    }
  }
  return line.trimRight();
}

String _unquote(String s) {
  s = s.trim();
  if (s.length >= 2 &&
      (s.startsWith('"') && s.endsWith('"') ||
          s.startsWith("'") && s.endsWith("'"))) {
    return s.substring(1, s.length - 1);
  }
  return s;
}

/// Package → dependencies, from `.dart_tool/package_graph.json`, to tell
/// whether a package (transitively) depends on Flutter.
class _PackageGraph {
  _PackageGraph(this._deps);

  factory _PackageGraph.load(Directory root) {
    final file = File('${root.path}/.dart_tool/package_graph.json');
    if (!file.existsSync()) return _PackageGraph(null);
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final deps = <String, List<String>>{};
      for (final p in json['packages'] as List<Object?>) {
        final pkg = p as Map<String, Object?>;
        deps[pkg['name'] as String] = [
          for (final d in (pkg['dependencies'] as List<Object?>? ?? const []))
            d as String,
        ];
      }
      return _PackageGraph(deps);
    } on Object {
      return _PackageGraph(null);
    }
  }

  final Map<String, List<String>>? _deps;
  final _cache = <String, bool>{};

  bool get available => _deps != null;

  /// Whether [package] is Flutter or depends on it. Workspace members are
  /// judged by their rule kind, so a member's own mistake is reported once,
  /// at the member.
  bool dependsOnFlutter(String package) {
    if (package == 'flutter') return true;
    final rule = rules[package];
    if (rule != null) return rule.kind == Kind.flutter;
    final deps = _deps;
    if (deps == null) return package.startsWith('flutter_');
    return _cache[package] ??= _visit(package, deps, <String>{});
  }

  bool _visit(
    String package,
    Map<String, List<String>> deps,
    Set<String> seen,
  ) {
    if (package == 'flutter') return true;
    if (!seen.add(package)) return false;
    final cached = _cache[package];
    if (cached != null) return cached;
    for (final d in deps[package] ?? const <String>[]) {
      if (_visit(d, deps, seen)) return true;
    }
    return false;
  }
}
