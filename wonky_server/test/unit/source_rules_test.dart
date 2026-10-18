/// Source rules for the server's hand-written code (specs/13 §3 "Server
/// write and job rules"; code-quality themes T1 and T2).
///
/// - **T1, stale full-row writes.** `X.db.updateRow(row)` without `columns:`
///   writes every column of a row that was read earlier, so it silently
///   reverts what another request changed in between (a resolved comment
///   thread comes back open, a removed board post visible again, a document's
///   head revision goes back). Name the changed columns, or use `updateWhere`
///   or atomic SQL. Tables whose rows have one writer at a time are listed in
///   [fullRowWrites] with the reason.
/// - **T2, failures escaping long-lived work.** Jobs, sweeps, queues and
///   connections catch `Object` (use `runGuarded` in
///   `platform/common/guarded.dart`), never only `Exception`: an `Error`
///   (`StateError`, `TypeError`, …) would otherwise abort the rest of a job
///   chain or wedge a queue. Empty `catch (_) {}` blocks are not allowed
///   anywhere.
library;

import 'dart:io';

import 'package:test/test.dart';

/// Tables (model classes) whose rows may be written as a whole, with the
/// reason. Everything else names its columns.
const fullRowWrites = <String, String>{
  // Per-user settings: the user's own save replaces the settings value.
  'UserActivitySettings': 'per-user settings, replaced by the user',
  'UserPreferences': 'per-user settings, replaced by the user',
  'AiUserKey': 'per-user key, replaced by the user',
  'AiUserSetting': 'per-user settings, replaced by the user',
  'ScriptAuthorization': 'per-user grant, replaced by the user',
  'GoogleAccount': 'per-user identity row, written at sign-in',
  'PersonalAccessToken': 'per-user token, written by its owner',
  // Caches and derived rows: recomputed from their source.
  'AiFunctionCache': 'cache row, recomputed from its inputs',
  'SheetsSnapshotIndex': 'derived index of an immutable snapshot',
  'DocumentImportReport': 'written once by the import that owns it',
  'HeadlessChange': 'written by the one headless edit that owns it',
  // Job rows owned by a lease (the lease holder is the only writer;
  // conditional lease updates are CQ-9).
  'ScriptJob': 'job row owned by its lease holder',
  'SheetsImportJob': 'job row owned by its lease holder',
  'ScriptTriggerState': 'trigger state written by the scheduler tick',
  // The assistant run owns its thread and messages while it runs.
  'AssistantThread': 'written by the run that owns the thread',
  'AssistantMessage': 'written by the run that owns the message',
  // Theme editor saves replace the theme document.
  'WriteTheme': 'the theme editor saves the whole theme',
};

/// Files with long-lived work (jobs, sweeps, queues, connections), where a
/// catch must not be limited to `Exception` (T2).
final _longLived = [
  RegExp(r'/jobs/'),
  RegExp(r'_future_call\.dart$'),
  RegExp(r'_sweep\.dart$'),
  RegExp(r'_jobs\.dart$'),
  RegExp(r'_connection\.dart$'),
  RegExp(r'_triggers\.dart$'),
  RegExp(r'/collab/overlay_lifecycle\.dart$'),
];

void main() {
  final sources = [
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File &&
          f.path.endsWith('.dart') &&
          !_path(f).startsWith('lib/src/generated/'))
        (path: _path(f), text: f.readAsStringSync()),
  ];

  group('Given the server sources', () {
    test('when scanning them then there are sources to check', () {
      expect(sources.length, greaterThan(100));
    });

    test('when a row is updated then the columns are named (T1)', () {
      final violations = <String>[];
      final usedAllowances = <String>{};
      for (final s in sources) {
        for (final call in _updateRowCalls(s.text)) {
          if (call.namesColumns) continue;
          if (fullRowWrites.containsKey(call.table)) {
            usedAllowances.add(call.table);
            continue;
          }
          violations.add('${s.path}:${call.line} ${call.table}.db.updateRow');
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Full-row updateRow writes revert concurrent changes: pass '
            '`columns:` (or use updateWhere / atomic SQL), or list the table '
            'in fullRowWrites with the reason it has a single writer.',
      );
      expect(
        fullRowWrites.keys.toSet().difference(usedAllowances),
        isEmpty,
        reason: 'Remove allowances that are no longer needed.',
      );
    });

    test(
      'when long-lived work catches failures then it catches Object (T2)',
      () {
        final violations = <String>[];
        final onException = RegExp(r'on\s+Exception\s+catch\s*\(');
        for (final s in sources) {
          if (!_longLived.any((r) => r.hasMatch(s.path))) continue;
          for (final m in onException.allMatches(s.text)) {
            violations.add('${s.path}:${_line(s.text, m.start)}');
          }
        }
        expect(
          violations,
          isEmpty,
          reason:
              'Jobs, sweeps, queues and connections catch Object '
              '(runGuarded), so an Error does not abort the work after it.',
        );
      },
    );

    test('when a failure is caught then it is never swallowed silently', () {
      final violations = <String>[];
      final empty = RegExp(r'catch\s*\(\s*_\s*\)\s*\{\s*\}');
      for (final s in sources) {
        for (final m in empty.allMatches(s.text)) {
          violations.add('${s.path}:${_line(s.text, m.start)}');
        }
      }
      expect(violations, isEmpty, reason: 'Log the failure or handle it.');
    });
  });

  group('Given the server tests (specs/15 §2–§3, CQ-58)', () {
    final tests = [
      for (final f in Directory('test').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('_test.dart') &&
            !_path(f).startsWith('test/integration/test_tools/'))
          (path: _path(f), text: f.readAsStringSync()),
    ];
    final tags = RegExp(r"^@Tags\(\[([^\]]*)\]\)", multiLine: true);
    final startsServerpod = RegExp(r'\bwith\w*Serverpod\(');

    test('when a test starts Serverpod then it is under test/integration/', () {
      expect(
        [
          for (final t in tests)
            if (startsServerpod.hasMatch(t.text) &&
                !t.path.startsWith('test/integration/'))
              t.path,
        ],
        isEmpty,
        reason:
            'Pure logic goes to test/unit/, Serverpod tests to '
            'test/integration/.',
      );
    });

    test('when a test is under test/integration/ then it is tagged '
        'integration', () {
      expect(
        [
          for (final t in tests)
            if (t.path.startsWith('test/integration/') &&
                !(tags.firstMatch(t.text)?[1]?.contains("'integration'") ??
                    false))
              t.path,
        ],
        isEmpty,
        reason:
            "Add @Tags(['integration']) + library; at the top (package:"
            'test has no folder-level tags).',
      );
    });

    test('when a test is outside test/unit/ and test/integration/ then it '
        'is flagged', () {
      expect(
        [
          for (final t in tests)
            if (!t.path.startsWith('test/unit/') &&
                !t.path.startsWith('test/integration/'))
              t.path,
        ],
        isEmpty,
      );
    });
  });
}

String _path(File f) => f.path.replaceAll(r'\', '/').replaceFirst('./', '');

int _line(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length + 1;

/// The `X.db.updateRow(...)` calls in [text], with their argument lists.
Iterable<({String table, int line, bool namesColumns})> _updateRowCalls(
  String text,
) sync* {
  final call = RegExp(r'(\w+)\.db\s*\.updateRow\(');
  final columns = RegExp(r'\bcolumns\s*:');
  for (final m in call.allMatches(text)) {
    var depth = 1;
    var i = m.end;
    while (i < text.length && depth > 0) {
      final c = text[i];
      if (c == '(') depth++;
      if (c == ')') depth--;
      i++;
    }
    yield (
      table: m[1]!,
      line: _line(text, m.start),
      namesColumns: columns.hasMatch(text.substring(m.end, i)),
    );
  }
}
