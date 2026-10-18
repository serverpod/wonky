import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/board_triage_questions.dart';
import 'package:wonky_server/src/platform/board/ai/jev_client.dart';
import 'package:wonky_server/src/platform/board/ai/jev_gemini_board_ai.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/board/board_ai_builders.dart';

String _instructions(JevQuestion q) => jsonEncode(q.instructions);

String _criteria(JevQuestion q) => jsonEncode(q.criteria);

void main() {
  group('Given a post with included details, a screenshot and two '
      'candidates', () {
    final post = BoardAiBuilders.post(
      id: 9,
      contextJson: '{"browser":"Chrome 140","route":"/sheets/s/abc"}',
      screenshotFileId: 77,
    ).copyWith(authorId: 5, suggestedTitle: 'Old', summary: 'Old summary');
    final candidates = [
      BoardAiBuilders.post(id: 3, title: 'Merged cells lose bold'),
      BoardAiBuilders.post(id: 4, title: 'Undo after paste', body: 'x' * 2000),
    ];
    final request = BoardTriageQuestions.triage(post, candidates: candidates);

    test('when building the triage request then it asks every §6.2 question '
        'and one duplicate Noul per candidate', () {
      expect(request.questions.keys, [
        'kind',
        'area',
        'size',
        'offensive',
        'spam',
        'not_actionable',
        'off_topic',
        'personal_data',
        'security',
        'duplicate_3',
        'duplicate_4',
      ]);
      expect(request.questions['kind']!.type, 'choice');
      expect(request.questions['area']!.type, 'choice');
      expect(request.questions['size']!.type, 'choice');
      expect(request.questions['offensive']!.type, 'noul');
      expect(request.questions['duplicate_3']!.type, 'noul');
    });

    test('when building the triage request then the state holds only the '
        'kind chosen by the author, title, body, app and product', () {
      expect(request.state, {
        'post': {
          'kind_chosen_by_author': 'bug',
          'title': post.title,
          'body': post.body,
        },
        'app_in_use': 'sheets',
        'product': BoardTriageQuestions.product,
      });
      final json = jsonEncode(request.toJson('jev-1.13.0'));
      expect(json, isNot(contains('Chrome 140')));
      expect(json, isNot(contains('/sheets/s/abc')));
      expect(json, isNot(contains('Old summary')));
    });

    test('when building the triage request then the Choices list every kind, '
        'area and size with a description', () {
      expect(
        (request.questions['kind']!.criteria! as Map).keys,
        BoardPostKind.values.map((k) => k.name),
      );
      expect(
        (request.questions['area']!.criteria! as Map).keys,
        BoardArea.values.map((a) => a.name),
      );
      expect(
        (request.questions['size']!.criteria! as Map).keys,
        BoardSize.values.map((s) => s.name),
      );
      for (final id in ['kind', 'area', 'size']) {
        final options = request.questions[id]!.criteria! as Map;
        expect(options.values, everyElement(isA<String>()));
      }
    });

    test('when building the duplicate question then it holds the candidate '
        'as structured data with a clipped body', () {
      final q = request.questions['duplicate_4']!.instructions as Map;
      final candidate = q['candidate'] as Map;
      expect(candidate['title'], 'Undo after paste');
      expect(
        (candidate['body'] as String).length,
        BoardTriageQuestions.maxCandidateChars + 1,
      );
      expect(q['question'], contains('`post` and `candidate`'));
    });

    test('when reversing the Choice order then the options come last to '
        'first', () {
      final reversed = BoardTriageQuestions.triage(post, reversedChoices: true);
      expect(
        (reversed.questions['area']!.criteria! as Map).keys,
        BoardArea.values.reversed.map((a) => a.name),
      );
      expect((reversed.questions['kind']!.criteria! as Map).keys, [
        'idea',
        'bug',
      ]);
    });
  });

  group('Given more than five candidates including the post itself', () {
    test('when building the triage request then at most five other posts '
        'are checked', () {
      final post = BoardAiBuilders.post(id: 1);
      final request = BoardTriageQuestions.triage(
        post,
        candidates: [for (var i = 1; i <= 8; i++) BoardAiBuilders.post(id: i)],
      );

      expect(request.questions.keys.where((k) => k.startsWith('duplicate_')), [
        'duplicate_2',
        'duplicate_3',
        'duplicate_4',
        'duplicate_5',
        'duplicate_6',
      ]);
    });
  });

  group('Given the moderation questions', () {
    final q = BoardTriageQuestions.triage(BoardAiBuilders.post()).questions;

    test('when reading offensive then rudeness about the product is '
        'explicitly not offensive', () {
      expect(_criteria(q['offensive']!), contains('about the product'));
      expect(_criteria(q['offensive']!), contains('is NOT offensive'));
      expect(_instructions(q['offensive']!), contains('slurs'));
    });

    test('when reading security then it names data of other users, account '
        'takeover, server code and permissions', () {
      final text = _instructions(q['security']!);
      expect(text, contains("other users' data"));
      expect(text, contains('take over'));
      expect(text, contains('run code on the server'));
      expect(text, contains('permissions'));
      expect(_criteria(q['security']!), contains('is NOT a security hole'));
    });

    test('when reading the rest then each states its condition', () {
      expect(_instructions(q['spam']!), contains('advertising'));
      expect(_instructions(q['not_actionable']!), contains('no report'));
      expect(_instructions(q['off_topic']!), contains('product other than'));
      expect(_instructions(q['personal_data']!), contains('email address'));
    });
  });

  group('Given a comment', () {
    test('when building its request then it has only the moderation Nouls '
        'and the comment in the state', () {
      final r = BoardTriageQuestions.comment('This is useless, fix it!');

      expect(r.questions.keys, [
        'offensive',
        'spam',
        'personal_data',
        'security',
      ]);
      expect(r.state, {
        'comment': 'This is useless, fix it!',
        'product': BoardTriageQuestions.product,
      });
      expect(_instructions(r.questions['offensive']!), contains('`comment`'));
    });
  });

  group('Given a draft and similar posts', () {
    test('when building the rerank request then there is one same_<id> '
        'Noul per candidate and the draft is the state', () {
      final r = BoardTriageQuestions.rerank(
        title: 'Bold lost',
        body: 'Pasting drops bold',
        candidates: [
          BoardAiBuilders.post(id: 7),
          BoardAiBuilders.post(id: 8),
        ],
      );

      expect(r.questions.keys, ['same_7', 'same_8']);
      expect(r.state, {
        'draft': {'title': 'Bold lost', 'body': 'Pasting drops bold'},
      });
      expect(
        _instructions(r.questions['same_7']!),
        contains('`draft` and `candidate`'),
      );
    });
  });

  group('Given Jev answers to a triage request', () {
    const thresholds = BoardAiThresholds(labelConfidence: 0.5);
    final post = BoardAiBuilders.post(kind: BoardPostKind.bug);

    JevResult result({
      double areaConfidence = 0.9,
      double sizeConfidence = 0.9,
    }) => JevResult(
      model: 'jev-1.13.0',
      answers: {
        'kind': const JevAnswer(
          type: 'choice',
          choice: 'idea',
          confidence: 0.84,
        ),
        'area': JevAnswer(
          type: 'choice',
          choice: 'sheets',
          confidence: areaConfidence,
        ),
        'size': JevAnswer(
          type: 'choice',
          choice: 'small',
          confidence: sizeConfidence,
        ),
        'offensive': const JevAnswer(type: 'noul', noul: 0.02),
        'security': const JevAnswer(type: 'noul', noul: 0.31),
        'duplicate_3': const JevAnswer(type: 'noul', noul: 0.91),
        'duplicate_4': const JevAnswer(type: 'noul', noul: 0.12),
      },
    );

    test('when the labels are confident then kind, area, size, scores and '
        'duplicates are read', () {
      final t = JevGeminiBoardAi.triageFrom(result(), post, thresholds);

      expect(t.kind, BoardPostKind.idea);
      expect(t.kindConfidence, 0.84);
      expect(t.area, BoardArea.sheets);
      expect(t.size, BoardSize.small);
      expect(t.scores.security, 0.31);
      expect(t.scores.offensive, 0.02);
      expect(t.scores.spam, 0);
      expect(t.duplicates, {3: 0.91, 4: 0.12});
      expect(t.model, 'jev-1.13.0');
    });

    test('when area and size are below the label confidence then they are '
        'left empty', () {
      final t = JevGeminiBoardAi.triageFrom(
        result(areaConfidence: 0.49, sizeConfidence: 0.2),
        post,
        thresholds,
      );

      expect(t.area, isNull);
      expect(t.size, isNull);
      expect(t.kind, BoardPostKind.idea);
    });

    test('when the kind answer is missing then the author kind is kept with '
        'confidence 0', () {
      final t = JevGeminiBoardAi.triageFrom(
        const JevResult(model: 'jev-1.13.0', answers: {}),
        post,
        thresholds,
      );

      expect(t.kind, BoardPostKind.bug);
      expect(t.kindConfidence, 0);
    });
  });
}
