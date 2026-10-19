// Differential test of the formula engine against LibreOffice Calc
// (Sheets 05 §22.5; CQ-61). Generates random argument sets for numeric,
// statistical and financial functions, writes them as formulas into an ODS
// file without cached results (so LibreOffice computes every one on load),
// converts it to CSV with `soffice --headless` (full precision, not "as
// shown"), and compares each result with the engine's.
//
//   dart run tool/compat/lo_diff.dart [--cases 300] [--seed 1] [--soffice soffice]
//                                      [--keep <dir>] [--dry-run]
//
// Tolerance: relative 1e-9, 1e-6 for inverse distributions and iterative
// solvers (RATE, IRR). Both errors count as agreement when the error kinds
// match. Exit code 1 when anything disagrees; the disagreements are printed
// with the seed for replay. Google Sheets decides when Sheets and LibreOffice
// disagree (triage: add a golden vector, test/formula/golden/).
//
// Not run by the regular test jobs: the nightly `lo-diff` job installs
// LibreOffice (.github/workflows/nightly.yml).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// A function template: [build] makes the formula (en_US separators) from a
/// random source; [loose] uses the loose tolerance.
typedef _Template = ({String Function(Random r) build, bool loose});

double _num(Random r, double lo, double hi, {int digits = 3}) {
  final v = lo + r.nextDouble() * (hi - lo);
  final p = pow(10, digits);
  return (v * p).round() / p;
}

String _list(Random r, int n, double lo, double hi) =>
    '{${List.generate(n, (_) => _num(r, lo, hi)).join(',')}}';

final _templates = <_Template>[
  (
    build: (r) =>
        '=ROUND(${_num(r, -1e4, 1e4, digits: 6)},${r.nextInt(7) - 2})',
    loose: false,
  ),
  (
    build: (r) => '=MOD(${_num(r, -100, 100)},${_num(r, 0.5, 9)})',
    loose: false,
  ),
  (build: (r) => '=POWER(${_num(r, 0.1, 9)},${_num(r, -4, 4)})', loose: false),
  (build: (r) => '=SQRT(${_num(r, 0, 1e6)})', loose: false),
  (build: (r) => '=LN(${_num(r, 0.001, 1e6)})', loose: false),
  (build: (r) => '=EXP(${_num(r, -20, 20)})', loose: false),
  (
    build: (r) => '=STDEV.S(${_list(r, 2 + r.nextInt(8), -100, 100)})',
    loose: false,
  ),
  (
    build: (r) => '=VAR.P(${_list(r, 2 + r.nextInt(8), -100, 100)})',
    loose: false,
  ),
  (
    build: (r) => '=MEDIAN(${_list(r, 1 + r.nextInt(9), -100, 100)})',
    loose: false,
  ),
  (
    build: (r) =>
        '=PERCENTILE.INC(${_list(r, 2 + r.nextInt(8), 0, 50)},${_num(r, 0, 1)})',
    loose: false,
  ),
  (
    build: (r) =>
        '=NORM.DIST(${_num(r, -5, 5)},${_num(r, -1, 1)},${_num(r, 0.5, 3)},TRUE)',
    loose: false,
  ),
  (
    build: (r) =>
        '=NORM.INV(${_num(r, 0.01, 0.99)},${_num(r, -1, 1)},${_num(r, 0.5, 3)})',
    loose: true,
  ),
  (
    build: (r) =>
        '=BINOM.DIST(${r.nextInt(10)},10,${_num(r, 0.05, 0.95)},FALSE)',
    loose: false,
  ),
  (
    build: (r) => '=POISSON.DIST(${r.nextInt(12)},${_num(r, 0.5, 8)},TRUE)',
    loose: false,
  ),
  (build: (r) => '=GAMMALN(${_num(r, 0.1, 50)})', loose: false),
  (
    build: (r) => '=T.DIST(${_num(r, -4, 4)},${1 + r.nextInt(30)},TRUE)',
    loose: false,
  ),
  (
    build: (r) => '=CHISQ.INV(${_num(r, 0.01, 0.99)},${1 + r.nextInt(20)})',
    loose: true,
  ),
  (
    build: (r) =>
        '=PMT(${_num(r, 0.001, 0.02, digits: 4)},${12 + r.nextInt(349)},${_num(r, 1e3, 5e5, digits: 0)})',
    loose: false,
  ),
  (
    build: (r) =>
        '=FV(${_num(r, 0.001, 0.02, digits: 4)},${1 + r.nextInt(120)},-${_num(r, 10, 1e3, digits: 0)})',
    loose: false,
  ),
  (
    build: (r) =>
        '=PV(${_num(r, 0.001, 0.02, digits: 4)},${1 + r.nextInt(120)},-${_num(r, 10, 1e3, digits: 0)})',
    loose: false,
  ),
  (
    build: (r) =>
        '=NPV(${_num(r, 0.01, 0.2)},${List.generate(1 + r.nextInt(6), (_) => _num(r, -100, 500)).join(',')})',
    loose: false,
  ),
  (
    build: (r) =>
        '=RATE(${12 + r.nextInt(108)},-${_num(r, 50, 500, digits: 0)},${_num(r, 2e3, 2e4, digits: 0)})',
    loose: true,
  ),
  (
    build: (r) =>
        '=IRR({-${_num(r, 500, 2000, digits: 0)},${List.generate(2 + r.nextInt(5), (_) => _num(r, 100, 900, digits: 0)).join(',')}})',
    loose: true,
  ),
];

Future<void> main(List<String> args) async {
  var cases = 300;
  var seed = 1;
  var soffice = 'soffice';
  String? keep;
  var dryRun = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--cases':
        cases = int.parse(args[++i]);
      case '--seed':
        seed = int.parse(args[++i]);
      case '--soffice':
        soffice = args[++i];
      case '--dry-run':
        dryRun = true;
      case '--keep':
        keep = args[++i];
      default:
        stderr.writeln(
          'Usage: dart run tool/compat/lo_diff.dart [--cases n] [--seed n] '
          '[--soffice path] [--keep dir] [--dry-run]',
        );
        exit(64);
    }
  }

  final random = Random(seed);
  final formulas = <(String, bool)>[
    for (var i = 0; i < cases; i++)
      () {
        final t = _templates[random.nextInt(_templates.length)];
        return (t.build(random), t.loose);
      }(),
  ];

  if (dryRun) {
    // The engine side only (checks the templates without LibreOffice).
    for (final (f, _) in formulas) {
      stdout.writeln('$f -> ${FormulaTestBench().eval(f)}');
    }
    return;
  }
  final dir = keep != null
      ? (Directory(keep)..createSync(recursive: true))
      : Directory.systemTemp.createTempSync('lo_diff');
  final ods = File('${dir.path}/lo_diff.ods')
    ..writeAsBytesSync(_ods([for (final (f, _) in formulas) f]));
  final ProcessResult r;
  try {
    r = await Process.run(soffice, [
      '--headless',
      '--norestore',
      '--convert-to',
      // Comma, double quote, UTF-8, from line 1, en-US, full precision
      // (token 9 "save cell contents as shown" = false).
      'csv:Text - txt - csv (StarCalc):44,34,76,1,,1033,false,true,false,false,false',
      '--outdir',
      dir.path,
      ods.path,
    ]);
  } on ProcessException catch (e) {
    stderr.writeln('Cannot run $soffice (install LibreOffice): ${e.message}');
    exit(2);
  }
  if (r.exitCode != 0) {
    stderr.writeln('soffice failed (${r.exitCode}): ${r.stderr}');
    exit(2);
  }
  final csv = File('${dir.path}/lo_diff.csv').readAsLinesSync();

  var disagreements = 0;
  for (var i = 0; i < formulas.length; i++) {
    final (formula, loose) = formulas[i];
    final lo = i < csv.length ? _csvCell(csv[i]) : '';
    final engine = FormulaTestBench().eval(formula);
    if (!_agree(engine, lo, loose ? 1e-6 : 1e-9)) {
      disagreements++;
      stdout.writeln('$formula\n  LibreOffice: $lo\n  engine:      $engine');
    }
  }
  stdout.writeln(
    '${formulas.length - disagreements}/${formulas.length} agree '
    '(seed $seed).',
  );
  if (keep == null) dir.deleteSync(recursive: true);
  if (disagreements > 0) exit(1);
}

/// The first CSV field of [line] (the formula result; one column).
String _csvCell(String line) {
  if (line.startsWith('"')) {
    final end = line.indexOf('"', 1);
    return line.substring(1, end < 0 ? line.length : end);
  }
  final comma = line.indexOf(',');
  return comma < 0 ? line : line.substring(0, comma);
}

bool _agree(FValue engine, String lo, double tolerance) {
  final n = double.tryParse(lo);
  return switch (engine) {
    FNumber(:final v) when n != null =>
      (v - n).abs() <= n.abs() * tolerance + 1e-12,
    FError(:final kind) =>
      lo.startsWith('#') || lo.startsWith('Err:')
          ? lo == kind.literal || lo.startsWith('Err:')
          : false,
    FBool(:final v) => lo.toUpperCase() == (v ? 'TRUE' : 'FALSE'),
    FText(:final v) => lo == v,
    _ => false,
  };
}

/// An ODS file with one formula per row in column A and no cached results.
List<int> _ods(List<String> formulas) {
  const esc = HtmlEscape(HtmlEscapeMode.attribute);
  final rows = [
    for (final f in formulas)
      '<table:table-row><table:table-cell '
          'table:formula="of:${esc.convert(f.replaceAll(',', ';'))}"/>'
          '</table:table-row>',
  ];
  final content =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<office:document-content '
      'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
      'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" '
      'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
      'xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" '
      'office:version="1.3"><office:body><office:spreadsheet>'
      '<table:table table:name="Diff">${rows.join()}</table:table>'
      '</office:spreadsheet></office:body></office:document-content>';
  final archive = Archive();
  void add(String name, String text, {bool store = false}) {
    final bytes = utf8.encode(text);
    final f = ArchiveFile(name, bytes.length, bytes);
    if (store) f.compression = CompressionType.none;
    archive.addFile(f);
  }

  add(
    'mimetype',
    'application/vnd.oasis.opendocument.spreadsheet',
    store: true,
  );
  add(
    'META-INF/manifest.xml',
    '<?xml version="1.0" encoding="UTF-8"?>'
        '<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.3">'
        '<manifest:file-entry manifest:full-path="/" manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>'
        '<manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>'
        '</manifest:manifest>',
  );
  add('content.xml', content);
  return ZipEncoder().encode(archive);
}
