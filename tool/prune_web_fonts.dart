// Drops font families an app never uses from a Flutter web build (CQ-45,
// shared-packages H-5).
//
// Flutter web downloads every font of `assets/FontManifest.json` while the
// engine starts, and a package's fonts reach every app that depends on it
// (no per-app opt-out). This removes the families an app doesn't use from
// the manifest and deletes their files:
//
// - the Lucide stroke-weight families (`Lucide100`…`Lucide600`): only Slides
//   draws icons with other stroke widths (`wonky_slides_core` lucide_glyphs);
// - `wonky_ui`'s `Inter`: the UI uses Geist; only chart text (Sheets,
//   Slides) uses it (`wonky_charts_flutter` chart_painter);
// - `golden_toolkit`'s Roboto, a test package (in case it comes back as a
//   regular dependency of the vendored super_editor).
//
// Usage (run by `serverpod run flutter_build` after each app's build):
//
//   dart run tool/prune_web_fonts.dart <app> <web build directory>
//
// `<app>` is drive, write, sheets or slides.
import 'dart:convert';
import 'dart:io';

/// Families each app's build drops.
const Map<String, Set<String>> unusedFamilies = {
  'drive': {..._lucideWeights, _inter, _testRoboto},
  'write': {..._lucideWeights, _inter, _testRoboto},
  'sheets': {..._lucideWeights, _testRoboto},
  'slides': {_testRoboto},
};

const _lucideWeights = {
  'packages/lucide_icons_flutter/Lucide100',
  'packages/lucide_icons_flutter/Lucide200',
  'packages/lucide_icons_flutter/Lucide300',
  'packages/lucide_icons_flutter/Lucide400',
  'packages/lucide_icons_flutter/Lucide500',
  'packages/lucide_icons_flutter/Lucide600',
};
const _inter = 'packages/wonky_ui/Inter';
const _testRoboto = 'packages/golden_toolkit/Roboto';

void main(List<String> args) {
  if (args.length != 2 || !unusedFamilies.containsKey(args[0])) {
    stderr.writeln(
      'Usage: dart run tool/prune_web_fonts.dart '
      '<${unusedFamilies.keys.join('|')}> <web build directory>',
    );
    exit(64);
  }
  final dropped = pruneWebFonts(Directory(args[1]), unusedFamilies[args[0]]!);
  stdout.writeln(
    'Pruned ${dropped.length} font families from ${args[0]}'
    '${dropped.isEmpty ? '' : ': ${dropped.join(', ')}'}',
  );
}

/// Removes [families] from the manifest of the build in [web] and deletes
/// their font files; returns the families removed.
List<String> pruneWebFonts(Directory web, Set<String> families) {
  final manifest = File('${web.path}/assets/FontManifest.json');
  if (!manifest.existsSync()) {
    stderr.writeln('No ${manifest.path}');
    exit(66);
  }
  final entries = (jsonDecode(manifest.readAsStringSync()) as List)
      .cast<Map<String, Object?>>();
  final kept = <Map<String, Object?>>[];
  final dropped = <String>[];
  for (final e in entries) {
    if (!families.contains(e['family'])) {
      kept.add(e);
      continue;
    }
    dropped.add('${e['family']}');
    for (final f in (e['fonts'] as List? ?? const []).cast<Map>()) {
      // Flutter writes the file under the manifest's (URL-encoded) name,
      // e.g. `Inter%5Bopsz,wght%5D.ttf` (some versions used the decoded name).
      final asset = '${f['asset']}';
      for (final name in {asset, Uri.decodeFull(asset)}) {
        final file = File('${web.path}/assets/$name');
        if (file.existsSync()) file.deleteSync();
      }
    }
  }
  manifest.writeAsStringSync(jsonEncode(kept));
  return dropped;
}
