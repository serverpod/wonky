/// The triage evaluation set (specs/16 §15) against the real, pinned Jev
/// model, plus a small live smoke of the Gemini features. Tagged `live-ai`:
/// skipped in normal runs. Run:
///
/// ```sh
/// dart test -t live-ai --run-skipped test/integration/platform/board/ai/eval
/// ```
///
/// Keys come from the environment or the development passwords
/// (`LiveKeys`). Set `WONKY_EVAL_OUT=<file>` to also write every answer as
/// JSON. Reports precision and recall per decision at the configured
/// thresholds, with the Choices in normal and reversed option order.
@Tags(['integration', 'live-ai'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/board_ai.dart';
import 'package:wonky_server/src/platform/board/ai/board_triage_questions.dart';
import 'package:wonky_server/src/platform/board/ai/jev_client.dart';
import 'package:wonky_server/src/platform/board/ai/jev_gemini_board_ai.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../../test_tools/serverpod_test_tools.dart';
import '../../../../../support/board/board_ai_builders.dart';
import 'live_keys.dart';
import 'triage_eval_set.dart';

final _keys = LiveKeys.load();
const _thresholds = BoardAiThresholds();

class _Run {
  _Run(this.example, this.reversed, this.result, this.latency);

  final EvalPost example;
  final bool reversed;
  final JevResult result;
  final Duration latency;

  BoardTriage get triage =>
      JevGeminiBoardAi.triageFrom(result, example.post, _thresholds);
}

void _report(String line) {
  // ignore: avoid_print
  print(line);
}

String _f(double v) => v.toStringAsFixed(2);

/// (review, hold) of a moderation decision.
(double, double) _bands(String decision) => switch (decision) {
  'security' => (_thresholds.securityReview, _thresholds.securityHold),
  'offensive' ||
  'personal_data' => (_thresholds.harmReview, _thresholds.harmHold),
  _ => (_thresholds.junkReview, _thresholds.junkHold),
};

String _pr(int tp, int fp, int fn) {
  final p = tp + fp == 0 ? 1.0 : tp / (tp + fp);
  final r = tp + fn == 0 ? 1.0 : tp / (tp + fn);
  return 'P=${_f(p)} R=${_f(r)} (tp=$tp fp=$fp fn=$fn)';
}

Future<List<_Run>> _evaluate(JevClient jev, {required bool reversed}) async {
  final runs = <_Run>[];
  // A few at a time: fast, within the rate limits.
  for (var i = 0; i < evalSet.length; i += 4) {
    final batch = evalSet.skip(i).take(4);
    runs.addAll(
      await Future.wait([
        for (final e in batch)
          () async {
            final request = BoardTriageQuestions.triage(
              e.post,
              candidates: [for (final id in e.candidates) existingPosts[id]!],
              reversedChoices: reversed,
            );
            final sw = Stopwatch()..start();
            final r = await jev.ask(
              request,
              timeout: const Duration(seconds: 30),
            );
            return _Run(e, reversed, r, sw.elapsed);
          }(),
      ]),
    );
  }
  return runs;
}

void _summarize(List<_Run> runs, String title) {
  _report(
    '\n=== $title (${runs.length} posts, model ${runs.first.result.model})',
  );
  for (final d in moderationDecisions) {
    final (review, hold) = _bands(d);
    var tpR = 0, fpR = 0, fnR = 0, tpH = 0, fpH = 0, fnH = 0;
    for (final run in runs) {
      final p = run.result.noul(d);
      final pos = run.example.flags.contains(d);
      if (p >= review && pos) tpR++;
      if (p >= review && !pos) fpR++;
      if (p < review && pos) fnR++;
      if (p >= hold && pos) tpH++;
      if (p >= hold && !pos) fpH++;
      if (p < hold && pos) fnH++;
    }
    _report(
      '${d.padRight(15)} review≥${_f(review)}: ${_pr(tpR, fpR, fnR)} | '
      'hold≥${_f(hold)}: ${_pr(tpH, fpH, fnH)}',
    );
  }
  void tally<T>(
    String name,
    T? Function(EvalPost) expected,
    T? Function(BoardTriage) got,
  ) {
    var labeled = 0, set = 0, correct = 0;
    for (final run in runs) {
      final want = expected(run.example);
      if (want == null) continue;
      labeled++;
      final have = got(run.triage);
      if (have == null) continue;
      set++;
      if (have == want) correct++;
    }
    _report(
      '${name.padRight(15)} labeled=$labeled set=$set correct=$correct '
      '(coverage ${_f(labeled == 0 ? 0 : set / labeled)}, accuracy when set '
      '${_f(set == 0 ? 0 : correct / set)})',
    );
  }

  tally('kind', (e) => e.kind, (t) => t.kind);
  tally('area', (e) => e.area, (t) => t.area);
  tally('size', (e) => e.size, (t) => t.size);
  var tp = 0, fp = 0, fn = 0;
  for (final run in runs) {
    for (final id in run.example.candidates) {
      final p = run.triage.duplicates[id] ?? 0;
      final pos = run.example.duplicates.contains(id);
      if (p >= _thresholds.duplicate && pos) tp++;
      if (p >= _thresholds.duplicate && !pos) fp++;
      if (p < _thresholds.duplicate && pos) fn++;
    }
  }
  _report(
    '${'duplicate'.padRight(15)} ≥${_f(_thresholds.duplicate)}: ${_pr(tp, fp, fn)}',
  );
  final ms = [for (final r in runs) r.latency.inMilliseconds]..sort();
  final tokens = runs.fold<int>(0, (s, r) => s + r.result.inputTokens);
  _report(
    'latency p50=${ms[ms.length ~/ 2]} ms p95=${ms[(ms.length * 0.95).floor().clamp(0, ms.length - 1)]} ms '
    'max=${ms.last} ms; input tokens=$tokens',
  );
}

void main() {
  test('Given the evaluation set when Jev triages every post in both Choice '
      'orders then precision and recall per decision are reported', () async {
    if (_keys.jev == null) {
      markTestSkipped('No internalJevApiKey.');
      return;
    }
    final jev = HttpJevClient(
      apiKey: _keys.jev!,
      model: BoardAiConfig().jevModel,
    );
    try {
      final normal = await _evaluate(jev, reversed: false);
      final reversed = await _evaluate(jev, reversed: true);
      _report('\n=== Per post (normal order)');
      for (final run in normal) {
        final t = run.triage;
        final r = run.result;
        final mods = [
          for (final d in moderationDecisions)
            if (r.noul(d) >= 0.1) '$d=${_f(r.noul(d))}',
        ];
        _report(
          '${run.example.name.padRight(28)} '
          'kind=${r.answers['kind']?.choice}(${_f(r.answers['kind']?.confidence ?? 0)}) '
          'area=${r.answers['area']?.choice}(${_f(r.answers['area']?.confidence ?? 0)}) '
          'size=${r.answers['size']?.choice}(${_f(r.answers['size']?.confidence ?? 0)}) '
          '${mods.join(' ')} '
          '${t.duplicates.isEmpty ? '' : 'dup=${t.duplicates.map((k, v) => MapEntry(k, _f(v)))}'} '
          '${run.latency.inMilliseconds} ms',
        );
      }
      _summarize(normal, 'Normal Choice order');
      _summarize(reversed, 'Reversed Choice order');
      var same = 0, total = 0;
      for (var i = 0; i < normal.length; i++) {
        for (final id in ['kind', 'area', 'size']) {
          total++;
          if (normal[i].result.answers[id]?.choice ==
              reversed[i].result.answers[id]?.choice) {
            same++;
          }
        }
      }
      _report('\nChoice order consistency: $same / $total');
      final out = Platform.environment['WONKY_EVAL_OUT'];
      if (out != null) {
        File(out).writeAsStringSync(
          const JsonEncoder.withIndent(' ').convert([
            for (final run in [...normal, ...reversed])
              {
                'name': run.example.name,
                'reversed': run.reversed,
                'ms': run.latency.inMilliseconds,
                'model': run.result.model,
                'inputTokens': run.result.inputTokens,
                'answers': {
                  for (final e in run.result.answers.entries)
                    e.key: e.value.toJson(),
                },
              },
          ]),
        );
      }
      expect(normal, hasLength(evalSet.length));
      expect(normal.first.result.model, BoardAiConfig().jevModel);
    } finally {
      jev.close();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  withServerpod('Given the live board AI', (sessionBuilder, _) {
    test('when summarizing, bundling and writing a task prompt with Gemini '
        'then each feature returns a usable result', () async {
      if (_keys.gemini == null || _keys.jev == null) {
        markTestSkipped('No internal keys.');
        return;
      }
      final session = sessionBuilder.build();
      final ai = JevGeminiBoardAi(
        password: _keys.password,
        // gemini-2.5-* is no longer served to new keys (October 2026).
        config: () => BoardConfig(
          ai: BoardAiConfig(
            geminiModel:
                Platform.environment['WONKY_EVAL_GEMINI_MODEL'] ??
                'gemini-3.1-pro-preview',
            geminiFastModel:
                Platform.environment['WONKY_EVAL_GEMINI_FAST_MODEL'] ??
                'gemini-3.8-flash',
          ),
        ),
      );
      final post = BoardAiBuilders.post(
        id: 412,
        title: 'bug',
        body:
            'when i copy some cells with bold and paste them into a merged '
            'cell the bold goes away. also the background color. happens '
            'every time in chrome',
      );

      var sw = Stopwatch()..start();
      final triage = await ai.triagePost(
        session,
        post,
        timeout: const Duration(seconds: 3),
      );
      _report(
        '\nLive triage via BoardAi (${sw.elapsedMilliseconds} ms): '
        '${jsonEncode(triage.toJson())}',
      );

      sw = Stopwatch()..start();
      final s = await ai.summarize(session, post);
      _report(
        'Summarize (${sw.elapsedMilliseconds} ms): title=${s.title} '
        'summary=${s.summary}',
      );
      expect(s.summary, isNotEmpty);
      expect(s.summary.length, lessThanOrEqualTo(200));

      sw = Stopwatch()..start();
      final bundles = await ai.suggestBundles(session, [
        post.copyWith(summary: s.summary, area: BoardArea.sheets),
        BoardAiBuilders.post(
          id: 413,
          title: 'Paste into merged cells loses fill color',
          summary: 'Pasting into merged cells drops the background color.',
          area: BoardArea.sheets,
        ),
        BoardAiBuilders.post(
          id: 414,
          title: 'Typo in the Slides share dialog',
          summary: 'The share dialog in Slides says "Shre".',
          area: BoardArea.slides,
          appHint: 'slides',
        ),
      ]);
      _report(
        'Bundles (${sw.elapsedMilliseconds} ms): '
        '${bundles.map((b) => '${b.title} ${b.postIds} ${b.area?.name}: ${b.rationale}').join(' | ')}',
      );

      sw = Stopwatch()..start();
      final body = await ai.writeTaskPrompt(
        session,
        task: BoardAiBuilders.task(),
        posts: [post],
        comments: {
          412: [BoardAiBuilders.comment(412, 'Same for italics here.')],
        },
        webOrigin: Uri.parse('https://wonky.work'),
      );
      _report('Task prompt (${sw.elapsedMilliseconds} ms):\n$body');
      expect(body, contains('## Goal'));
      expect(body, contains('## Acceptance criteria'));

      final usage = await BoardAiUsage.db.find(session);
      _report(
        'Usage rows: ${usage.map((u) => '${u.provider}/${u.model}/${u.feature} '
            'req=${u.requests} in=${u.inputTokens} out=${u.outputTokens}').join('; ')}',
      );
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
