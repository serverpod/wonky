// Generates the RevLog table schemas of Sheets and Slides from the
// `.spy.yaml` models (RevLog spec 02 §4):
//
//   dart run tool/gen_rev_schema.dart
//
// Writes `packages/wonky_sheets_core/lib/src/revlog/sheets_schema.g.dart` and
// `packages/wonky_slides_core/lib/src/revlog/slides_schema.g.dart`. Reads the
// models from the server (after the RevLog move) or, before it, from
// `packages/wonky_sync_models`. A server guard test compares the result with
// the generated server tables, so rerun this after every model change.
import 'dart:io';

void main(List<String> args) {
  final root = Directory.current.path;
  String pick(List<String> candidates) => candidates.firstWhere(
    (p) => Directory('$root/$p').existsSync(),
    orElse: () => throw StateError('none of $candidates exists'),
  );

  final sheetsDir = pick([
    'wonky_server/lib/src/sheets/models/rows',
    'packages/wonky_sync_models/lib/src/models',
  ]);
  final slidesDir = pick([
    'wonky_server/lib/src/slides/models/rows',
    'packages/wonky_sync_models/lib/src/models/slides',
  ]);
  final enumDirs = [
    for (final d in [
      'wonky_server/lib/src/sheets/models/rows/enums',
      'wonky_server/lib/src/slides/models/rows/enums',
      'packages/wonky_sync_models/lib/src/models/enums',
      'packages/wonky_sync_models/lib/src/models/slides/enums',
    ])
      if (Directory('$root/$d').existsSync()) '$root/$d',
  ];
  final enums = <String, List<String>>{};
  for (final d in enumDirs) {
    for (final f in Directory(d).listSync().whereType<File>()) {
      if (!f.path.endsWith('.spy.yaml')) continue;
      final e = _parseEnum(f.readAsLinesSync());
      if (e != null) enums[e.$1] = e.$2;
    }
  }

  _generate(
    app: 'sheets',
    dir: '$root/$sheetsDir',
    order: _sheetsOrder,
    excluded: {'change_log', 'script_user_property'},
    enums: enums,
    rules: _sheetsRules,
    out: '$root/packages/wonky_sheets_core/lib/src/revlog/sheets_schema.g.dart',
    variable: 'sheetsRevTables',
  );
  _generate(
    app: 'slides',
    dir: '$root/$slidesDir',
    order: _slidesOrder,
    excluded: {'deck_change_log'},
    enums: enums,
    rules: _slidesRules,
    out: '$root/packages/wonky_slides_core/lib/src/revlog/slides_schema.g.dart',
    variable: 'slidesRevTables',
  );
}

/// Table order (= writer insert order, parents first).
const _sheetsOrder = [
  'spreadsheet',
  'sheet',
  'sheet_row',
  'sheet_column',
  'cell',
  'merged_range',
  'dimension_group',
  'named_range',
  'protected_range',
  'conditional_format_rule',
  'data_validation_rule',
  'basic_filter',
  'filter_view',
  'banding',
  'embedded_object',
  'pivot_table',
  'script_project',
  'script_file',
  'script_build',
  'script_trigger',
  'macro',
  'script_property',
];

const _slidesOrder = [
  'deck',
  'deck_theme',
  'slide_master',
  'slide_layout',
  'slide_group',
  'slide',
  'slide_element',
  'slide_table_axis',
  'slide_table_cell',
  'slide_build',
  'code_state',
  'chart_link',
];

final class _Rules {
  const _Rules({
    required this.root,
    this.serverOnlyTables = const {},
    this.deterministic = const {},
    this.immutable = const {},
    this.allFksImmutable = false,
    this.cellsByRow = const {},
    this.plainParents = const {},
  });
  final String root;
  final Set<String> serverOnlyTables;
  final Set<String> deterministic;
  final Set<String> immutable; // 'table.column'
  final bool allFksImmutable;
  final Set<String> cellsByRow;

  /// Plain uuid fields that are cascade parents without a DB foreign key
  /// ('table.column' → parent table; RevLog spec 02 §2.1).
  final Map<String, String> plainParents;
}

const _sheetsRules = _Rules(
  root: 'spreadsheet',
  serverOnlyTables: {'script_build'},
  deterministic: {'cell', 'basic_filter', 'script_build'},
  allFksImmutable: true,
  cellsByRow: {'cell'},
  plainParents: {'cell.rowId': 'sheet_row', 'cell.columnId': 'sheet_column'},
);

const _slidesRules = _Rules(
  root: 'deck',
  deterministic: {
    'slide_table_cell',
    'chart_link',
    'slide_element',
    'deck_theme',
    'slide_master',
    'slide_layout',
  },
  immutable: {
    'slide_table_cell.elementId',
    'slide_table_cell.rowId',
    'slide_table_cell.columnId',
    'slide_table_axis.elementId',
    'code_state.elementId',
    'chart_link.elementId',
    'deck_theme.deckId',
    'slide.deckId',
    'slide_group.deckId',
  },
);

final class _Field {
  _Field(this.name, this.type, this.nullable, this.options);
  final String name;
  final String type;
  final bool nullable;
  final String options;
}

final class _Model {
  _Model(this.className, this.table, this.fields, this.indexes);
  final String className;
  final String table;
  final List<_Field> fields;
  final List<List<String>> indexes;
}

(String, List<String>)? _parseEnum(List<String> lines) {
  String? name;
  final values = <String>[];
  var inValues = false;
  for (final raw in lines) {
    final line = raw.replaceAll('\r', '');
    if (line.startsWith('enum:')) name = line.substring(5).trim();
    if (line.startsWith('values:')) {
      inValues = true;
      continue;
    }
    if (inValues) {
      final m = RegExp(r'^\s+-\s*(\w+)').firstMatch(line);
      if (m != null) values.add(m.group(1)!);
    }
  }
  return name == null ? null : (name, values);
}

_Model? _parseModel(List<String> lines) {
  String? cls, table;
  final fields = <_Field>[];
  final indexes = <List<String>>[];
  var section = '';
  for (final raw in lines) {
    final line = raw.replaceAll('\r', '');
    if (line.trimLeft().startsWith('#')) continue;
    if (line.startsWith('class:')) cls = line.substring(6).trim();
    if (line.startsWith('table:')) table = line.substring(6).trim();
    if (!line.startsWith(' ') && line.endsWith(':')) {
      section = line.substring(0, line.length - 1);
      continue;
    }
    if (section == 'fields') {
      final m = RegExp(
        r'^  (\w+):\s*([\w<>]+)(\?)?\s*(?:,\s*(.*))?$',
      ).firstMatch(line);
      if (m != null) {
        fields.add(
          _Field(
            m.group(1)!,
            m.group(2)!,
            m.group(3) != null,
            m.group(4) ?? '',
          ),
        );
      }
    } else if (section == 'indexes') {
      final m = RegExp(r'^\s+fields:\s*(.*)$').firstMatch(line);
      if (m != null) {
        final fields = m.group(1)!.split(',').map((s) => s.trim()).toList();
        // The `fileId` index is server bookkeeping (02 §2.1).
        if (!fields.contains('fileId')) indexes.add(fields);
      }
    }
  }
  if (cls == null || table == null) return null;
  return _Model(cls, table, fields, indexes);
}

void _generate({
  required String app,
  required String dir,
  required List<String> order,
  required Set<String> excluded,
  required Map<String, List<String>> enums,
  required _Rules rules,
  required String out,
  required String variable,
}) {
  final models = <String, _Model>{};
  for (final f in Directory(dir).listSync().whereType<File>()) {
    if (!f.path.endsWith('.spy.yaml')) continue;
    final m = _parseModel(f.readAsLinesSync());
    if (m != null) models[m.table] = m;
  }
  final byClass = {for (final m in models.values) m.className: m.table};
  final missing = order.where((t) => !models.containsKey(t)).toList();
  if (missing.isNotEmpty) throw StateError('$app: models not found: $missing');
  final unknown = models.keys.where(
    (t) => !order.contains(t) && !excluded.contains(t),
  );
  if (unknown.isNotEmpty) throw StateError('$app: table order lacks $unknown');

  final b = StringBuffer()
    ..writeln(
      '// GENERATED by tool/gen_rev_schema.dart from the .spy.yaml models.',
    )
    ..writeln('// Do not edit by hand; rerun the tool after model changes.')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln("import 'package:wonky_revlog/schema.dart';")
    ..writeln()
    ..writeln(
      '/// The $app tables of RevLog in dependency order (RevLog spec 02 §4).',
    )
    ..writeln('const List<RevTable> $variable = [');
  for (var rank = 0; rank < order.length; rank++) {
    final t = order[rank];
    final m = models[t]!;
    final cols = <String>[];
    final parents = <String>[];
    for (final f in m.fields) {
      // Server bookkeeping, not part of the schema (02 §2.1).
      if (f.name == 'id' ||
          f.name == 'file' ||
          f.name == 'fileId' ||
          f.name == 'revision') {
        continue;
      }
      final rel = RegExp(r'relation\(([^)]*)\)').firstMatch(f.options);
      String name, type;
      final extra = <String>[];
      if (rel != null) {
        final parent = byClass[f.type];
        if (parent == null)
          throw StateError('$t.${f.name}: unknown relation ${f.type}');
        name = '${f.name}Id';
        type = 'uuid';
        final optional = rel.group(1)!.contains('optional');
        parents.add(
          "RevParent('$name', '$parent'${optional ? ', optional: true' : ''})",
        );
        if (optional) extra.add('nullable: true');
        if (rules.allFksImmutable || rules.immutable.contains('$t.$name')) {
          extra.add('immutable: true');
        }
      } else {
        name = f.name;
        type = switch (f.type) {
          'UuidValue' => 'uuid',
          'String' when f.name.endsWith('Json') => 'json',
          'String' => 'string',
          'int' => 'int',
          'double' => 'double',
          'bool' => 'bool',
          'DateTime' => 'dateTime',
          _ when enums.containsKey(f.type) => 'enumName',
          _ => throw StateError('$t.${f.name}: unsupported type ${f.type}'),
        };
        if (f.nullable) extra.add('nullable: true');
        if (type == 'enumName') {
          extra.add(
            "enumValues: [${enums[f.type]!.map((v) => "'$v'").join(', ')}]",
          );
        }
        final plainParent = rules.plainParents['$t.$name'];
        if (plainParent != null) {
          parents.add("RevParent('$name', '$plainParent')");
          extra.add('immutable: true');
        } else if (rules.immutable.contains('$t.$name'))
          extra.add('immutable: true');
        final def = RegExp(
          r'default(?:Model)?=([^,]+)',
        ).firstMatch(f.options)?.group(1)?.trim();
        if (def != null && def != 'random_v7') {
          final lit = switch (def) {
            'now' => 'revDefaultNow',
            'true' || 'false' => def,
            _ when RegExp(r'^-?\d+(\.\d+)?$').hasMatch(def) =>
              type == 'double' && !def.contains('.') ? '$def.0' : def,
            _ when def.startsWith("'") => def,
            _ => "'$def'",
          };
          extra.add('defaultValue: $lit');
        }
        final max = switch ((type, name)) {
          ('string', 'source') => 2097152,
          ('string', 'content' || 'text' || 'notes' || 'note' || 'code') =>
            50000,
          ('json', 'dataSnapshotJson' || 'diagnosticsJson' || 'exportsJson') =>
            4194304,
          ('json', _) => 1048576,
          ('string', _) => 100000,
          _ => null,
        };
        if (max != null) extra.add('maxLength: $max');
      }
      cols.add(
        "RevColumn('$name', RevColumnType.$type${extra.isEmpty ? '' : ', ${extra.join(', ')}'})",
      );
    }
    final props = <String>[
      if (parents.isNotEmpty) 'parents: [${parents.join(', ')}]',
      if (m.indexes.isNotEmpty)
        'indexes: [${m.indexes.map((i) => '[${i.map((c) => "'$c'").join(', ')}]').join(', ')}]',
      'rank: $rank',
      if (rules.deterministic.contains(t)) 'deterministicIds: true',
      if (rules.serverOnlyTables.contains(t)) 'clientWritable: false',
      if (t == rules.root) 'isRoot: true',
      if (rules.cellsByRow.contains(t)) 'coverage: RevCoverage.cellsByRow',
    ];
    b
      ..writeln('  RevTable(')
      ..writeln("    '$t',")
      ..writeln('    [')
      ..writeAll(cols.map((c) => '      $c,\n'))
      ..writeln('    ],')
      ..writeAll(props.map((p) => '    $p,\n'))
      ..writeln('  ),');
  }
  b.writeln('];');
  File(out)
    ..createSync(recursive: true)
    ..writeAsStringSync(b.toString());
  stdout.writeln('wrote $out');
}
