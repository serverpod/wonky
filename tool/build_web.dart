// Builds the Flutter web apps into the server's web directory and reports
// their bundle sizes (specs/01-architecture.md §2.4; CQ-64a, CQ-64h).
//
// Used by `serverpod run flutter_build` (both platforms; the Serverpod Cloud
// pre-deploy hook runs it too) and by the `web` CI job:
//
//   dart run tool/build_web.dart [app ...] [options]
//
// `app` is drive, write, sheets or slides (default: every app folder that
// exists). Each app is built with `flutter build web --wasm --base-href
// /<app>/` in `wonky_<app>`, copied into `<out>/<app>` (the build output is
// copied rather than written with `--output`, which doesn't work on Windows:
// flutter/flutter#157886), and then `tool/prune_web_fonts.dart` drops the
// font families the app never uses. The apps are built one after another
// (four parallel `--wasm` builds swap on a 16 GB machine). The script exits
// non-zero when any build fails, after trying the others.
//
// Options:
//
//   --out <dir>        target root (default: wonky_server/web)
//   --clean-retry      after a failed build, run `flutter clean` and retry once
//                      (off by default: a retry hides real errors)
//   --skip-build       don't build; only measure the existing `<out>/<app>`
//   --report <file>    also write the sizes as JSON
//   --budget <file>    fail when a size exceeds its budget (tool/web_budgets.json)
//
// Paths are relative to the repository root; the script finds the root itself,
// so it runs from any folder.
import 'dart:convert';
import 'dart:io';

import 'prune_web_fonts.dart';

const allApps = ['drive', 'write', 'sheets', 'slides'];

Future<void> main(List<String> args) async {
  final root = _repoRoot();
  final apps = <String>[];
  var out = 'wonky_server/web';
  var cleanRetry = false;
  var skipBuild = false;
  String? reportPath;
  String? budgetPath;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    String value() {
      if (i + 1 >= args.length) _usage('$a needs a value');
      return args[++i];
    }

    switch (a) {
      case '--out':
        out = value();
      case '--clean-retry':
        cleanRetry = true;
      case '--skip-build':
        skipBuild = true;
      case '--report':
        reportPath = value();
      case '--budget':
        budgetPath = value();
      default:
        if (!allApps.contains(a)) _usage('Unknown argument: $a');
        apps.add(a);
    }
  }
  final selected = apps.isNotEmpty
      ? apps
      : [
          for (final app in allApps)
            if (File('${root.path}/wonky_$app/pubspec.yaml').existsSync()) app,
        ];
  final outRoot = Directory(_resolve(root, out));

  final failed = <String>[];
  final sizes = <String, BundleSizes>{};
  for (final app in selected) {
    final target = Directory('${outRoot.path}/$app');
    if (!skipBuild) {
      stdout.writeln('Building $app...');
      final ok = await _build(root, app, target, cleanRetry: cleanRetry);
      if (!ok) {
        stderr.writeln('Building $app failed');
        failed.add(app);
        continue;
      }
      stdout.writeln('Built $app');
    }
    if (!target.existsSync()) {
      stderr.writeln('No build of $app in ${target.path}');
      failed.add(app);
      continue;
    }
    sizes[app] = BundleSizes.measure(target);
  }

  if (sizes.isNotEmpty) stdout.writeln(sizeTable(sizes));
  if (reportPath != null) {
    File(_resolve(root, reportPath)).writeAsStringSync(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({for (final e in sizes.entries) e.key: e.value.toJson()}),
    );
  }
  var overBudget = false;
  if (budgetPath != null) {
    final budgets =
        jsonDecode(File(_resolve(root, budgetPath)).readAsStringSync())
            as Map<String, Object?>;
    for (final e in sizes.entries) {
      final b = budgets[e.key];
      if (b is! Map<String, Object?>) continue;
      for (final problem in e.value.overBudget(b)) {
        stderr.writeln('${e.key}: $problem');
        overBudget = true;
      }
    }
  }
  if (failed.isNotEmpty) stderr.writeln('Failed: ${failed.join(' ')}');
  if (failed.isNotEmpty || overBudget) exit(1);
}

Future<bool> _build(
  Directory root,
  String app,
  Directory target, {
  required bool cleanRetry,
}) async {
  final appDir = '${root.path}/wonky_$app';
  final buildArgs = ['build', 'web', '--wasm', '--base-href', '/$app/'];
  var ok = await _run('flutter', buildArgs, appDir);
  if (!ok && cleanRetry) {
    stdout.writeln('Retrying $app after `flutter clean`...');
    ok =
        await _run('flutter', ['clean'], appDir) &&
        await _run('flutter', buildArgs, appDir);
  }
  if (!ok) return false;
  if (target.existsSync()) target.deleteSync(recursive: true);
  _copyDirectory(Directory('$appDir/build/web'), target);
  final dropped = pruneWebFonts(target, unusedFamilies[app]!);
  stdout.writeln(
    'Pruned ${dropped.length} font families from $app'
    '${dropped.isEmpty ? '' : ': ${dropped.join(', ')}'}',
  );
  return true;
}

Future<bool> _run(String executable, List<String> args, String dir) async {
  final p = await Process.start(
    executable,
    args,
    workingDirectory: dir,
    // `flutter` is a .bat on Windows.
    runInShell: Platform.isWindows,
    mode: ProcessStartMode.inheritStdio,
  );
  return await p.exitCode == 0;
}

void _copyDirectory(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final e in from.listSync(recursive: true, followLinks: false)) {
    final rel = e.path.substring(from.path.length + 1);
    final dest = '${to.path}/$rel';
    if (e is Directory) {
      Directory(dest).createSync(recursive: true);
    } else if (e is File) {
      File(dest).parent.createSync(recursive: true);
      e.copySync(dest);
    }
  }
}

/// Bundle sizes of one web build, in bytes.
class BundleSizes {
  BundleSizes({
    required this.wasm,
    required this.mjs,
    required this.js,
    required this.assets,
    required this.startupFonts,
    required this.total,
  });

  /// Measures the build in [dir].
  factory BundleSizes.measure(Directory dir) {
    int file(String name) {
      final f = File('${dir.path}/$name');
      return f.existsSync() ? f.lengthSync() : 0;
    }

    int tree(Directory d, {bool Function(String path)? skip}) {
      if (!d.existsSync()) return 0;
      var sum = 0;
      for (final f in d.listSync(recursive: true).whereType<File>()) {
        if (skip != null && skip(f.path)) continue;
        sum += f.lengthSync();
      }
      return sum;
    }

    var fonts = 0;
    final manifest = File('${dir.path}/assets/FontManifest.json');
    if (manifest.existsSync()) {
      for (final family
          in (jsonDecode(manifest.readAsStringSync()) as List)
              .cast<Map<String, Object?>>()) {
        for (final font
            in (family['fonts'] as List? ?? const [])
                .cast<Map<String, Object?>>()) {
          // The file has the manifest's (URL-encoded) name (some Flutter
          // versions used the decoded one).
          final asset = '${font['asset']}';
          for (final name in {asset, Uri.decodeFull(asset)}) {
            final f = File('${dir.path}/assets/$name');
            if (f.existsSync()) {
              fonts += f.lengthSync();
              break;
            }
          }
        }
      }
    }
    return BundleSizes(
      wasm: file('main.dart.wasm'),
      mjs: file('main.dart.mjs'),
      js: file('main.dart.js'),
      assets: tree(Directory('${dir.path}/assets')),
      startupFonts: fonts,
      // Without the CanvasKit debug symbols, which browsers never load.
      total: tree(dir, skip: (p) => p.endsWith('.symbols')),
    );
  }

  /// `main.dart.wasm` (the dart2wasm app).
  final int wasm;

  /// `main.dart.mjs` (the wasm loader).
  final int mjs;

  /// `main.dart.js` (the dart2js fallback for browsers without WasmGC).
  final int js;

  /// Everything under `assets/` (fonts, images, dictionaries, …).
  final int assets;

  /// The fonts of `FontManifest.json`, which the engine downloads at start-up.
  final int startupFonts;

  /// The whole build folder without `.symbols` files.
  final int total;

  Map<String, int> toJson() => {
    'wasm': wasm,
    'mjs': mjs,
    'js': js,
    'assets': assets,
    'startupFonts': startupFonts,
    'total': total,
  };

  /// The sizes above their limit in [budget] (keys of [toJson], in bytes).
  List<String> overBudget(Map<String, Object?> budget) => [
    for (final e in toJson().entries)
      if (budget[e.key] case final num limit when e.value > limit)
        '${e.key} is ${_mb(e.value)}, over its budget of ${_mb(limit)}',
  ];
}

/// The sizes as a Markdown table (also used for the CI job summary).
String sizeTable(Map<String, BundleSizes> sizes) {
  final b = StringBuffer()
    ..writeln('| App | wasm | js | assets | start-up fonts | total |')
    ..writeln('|-----|------|----|--------|----------------|-------|');
  for (final e in sizes.entries) {
    final s = e.value;
    b.writeln(
      '| ${e.key} | ${_mb(s.wasm)} | ${_mb(s.js)} | ${_mb(s.assets)} | '
      '${_mb(s.startupFonts)} | ${_mb(s.total)} |',
    );
  }
  return b.toString();
}

String _mb(num bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';

String _resolve(Directory root, String path) =>
    File(path).isAbsolute ? path : '${root.path}/$path';

Directory _repoRoot() {
  var dir = File.fromUri(Platform.script).parent;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('\nworkspace:')) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      stderr.writeln('Run this from inside the repository.');
      exit(66);
    }
    dir = parent;
  }
}

Never _usage(String message) {
  stderr
    ..writeln(message)
    ..writeln(
      'Usage: dart run tool/build_web.dart [${allApps.join('|')} ...] '
      '[--out <dir>] [--clean-retry] [--skip-build] [--report <file>] '
      '[--budget <file>]',
    );
  exit(64);
}
