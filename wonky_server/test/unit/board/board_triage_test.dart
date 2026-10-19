import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/board_ai.dart';
import 'package:wonky_server/src/platform/board/board_admins.dart';
import 'package:wonky_server/src/platform/board/board_common.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/board/board_search.dart';
import 'package:wonky_server/src/platform/board/board_triage.dart';
import 'package:wonky_server/src/platform/common/models.dart';

BoardTriage _triage({
  BoardModerationScores scores = const BoardModerationScores(),
  BoardPostKind kind = BoardPostKind.bug,
  double kindConfidence = 0.9,
  BoardArea? area,
  BoardSize? size,
  Map<int, double> duplicates = const {},
}) => BoardTriage(
  scores: scores,
  kind: kind,
  kindConfidence: kindConfidence,
  area: area,
  size: size,
  duplicates: duplicates,
);

void main() {
  // The table of specs/16 §6.2 (explicit: the defaults are tuned).
  const t = BoardAiThresholds(
    securityHold: 0.5,
    securityReview: 0.2,
    harmHold: 0.7,
    harmReview: 0.4,
    junkHold: 0.85,
    junkReview: 0.5,
    kindCorrection: 0.8,
    duplicate: 0.8,
  );

  group('Given the thresholds of the spec table', () {
    final cases = <(String, BoardModerationScores, BoardModeration, bool)>[
      (
        'all low',
        const BoardModerationScores(),
        BoardModeration.visible,
        false,
      ),
      (
        'security 0.5',
        const BoardModerationScores(security: 0.5),
        BoardModeration.held,
        false,
      ),
      (
        'security 0.2',
        const BoardModerationScores(security: 0.2),
        BoardModeration.visible,
        true,
      ),
      (
        'security 0.19',
        const BoardModerationScores(security: 0.19),
        BoardModeration.visible,
        false,
      ),
      (
        'offensive 0.7',
        const BoardModerationScores(offensive: 0.7),
        BoardModeration.held,
        false,
      ),
      (
        'offensive 0.4',
        const BoardModerationScores(offensive: 0.4),
        BoardModeration.visible,
        true,
      ),
      (
        'personal data 0.69',
        const BoardModerationScores(personalData: 0.69),
        BoardModeration.visible,
        true,
      ),
      (
        'spam 0.85',
        const BoardModerationScores(spam: 0.85),
        BoardModeration.held,
        false,
      ),
      (
        'not actionable 0.84',
        const BoardModerationScores(notActionable: 0.84),
        BoardModeration.visible,
        true,
      ),
      (
        'off topic 0.49',
        const BoardModerationScores(offTopic: 0.49),
        BoardModeration.visible,
        false,
      ),
      (
        'off topic 0.9 and security 0.3',
        const BoardModerationScores(offTopic: 0.9, security: 0.3),
        BoardModeration.held,
        false,
      ),
    ];
    for (final (name, scores, moderation, check) in cases) {
      test('when the scores are $name then the post is ${moderation.name}'
          '${check ? ' and listed for a check' : ''}', () {
        final o = applyTriage(
          _triage(scores: scores),
          t,
          reportedKind: BoardPostKind.bug,
        );

        expect(o.moderation, moderation);
        expect(o.needsCheck, check);
      });
    }

    test('when a post is held then the reason names the first decision', () {
      final o = applyTriage(
        _triage(scores: const BoardModerationScores(security: 0.9)),
        t,
        reportedKind: BoardPostKind.bug,
      );

      expect(o.reason, 'Waiting for review: it may describe a security issue.');
    });

    test(
      'when the other kind wins with 0.8 then the kind is corrected',
      () {
        final o = applyTriage(
          _triage(kind: BoardPostKind.idea, kindConfidence: 0.8),
          t,
          reportedKind: BoardPostKind.bug,
        );

        expect(o.kind, BoardPostKind.idea);
      },
    );

    test('when the other kind wins with 0.79 then the author kind stays', () {
      final o = applyTriage(
        _triage(kind: BoardPostKind.idea, kindConfidence: 0.79),
        t,
        reportedKind: BoardPostKind.bug,
      );

      expect(o.kind, BoardPostKind.bug);
    });

    test('when labels are returned then they are kept, nulls stay null', () {
      final o = applyTriage(
        _triage(area: BoardArea.write),
        t,
        reportedKind: BoardPostKind.bug,
      );

      expect((o.area, o.size), (BoardArea.write, null));
    });

    test('when duplicates are scored then the best one at 0.8 is the hint', () {
      final o = applyTriage(
        _triage(duplicates: {3: 0.81, 4: 0.95, 5: 0.5}),
        t,
        reportedKind: BoardPostKind.bug,
      );

      expect(o.possibleDuplicateOfId, 4);
    });

    test('when no duplicate reaches 0.8 then there is no hint', () {
      final o = applyTriage(
        _triage(duplicates: {3: 0.79}),
        t,
        reportedKind: BoardPostKind.bug,
      );

      expect(o.possibleDuplicateOfId, isNull);
    });

    test('when a comment scores off topic 0.99 then it stays visible '
        '(comments skip the post-only decisions)', () {
      final o = applyCommentCheck(
        const BoardModerationScores(offTopic: 0.99, notActionable: 0.99),
        t,
      );

      expect((o.moderation, o.needsCheck), (BoardModeration.visible, false));
    });

    test('when a comment scores offensive 0.75 then it is held', () {
      final o = applyCommentCheck(
        const BoardModerationScores(offensive: 0.75),
        t,
      );

      expect(o.moderation, BoardModeration.held);
    });
  });

  group('Given the admin configuration', () {
    final config = BoardConfig(adminEmails: {'ada@example.com'});
    final cases = <(String, bool)>[
      ('viktor@serverpod.dev', true),
      ('Viktor@ServerPod.DEV', true),
      ('x@mail.serverpod.dev', false),
      ('x@serverpod.dev.evil.com', false),
      ('x@notserverpod.dev', false),
      ('ADA@example.com', true),
      ('bo@example.com', false),
    ];
    for (final (email, admin) in cases) {
      test('when the email is $email then admin is $admin', () {
        expect(BoardAdmins.isAdminEmail(email, config), admin);
      });
    }
  });

  group('Given text helpers', () {
    test('when building a similar query then the words are OR-joined '
        'prefixes', () {
      expect(
        BoardSearch.orQuery('Paste into merged-cells, or not!'),
        'paste:* | into:* | merged:* | cells:* | or | not:*',
      );
    });

    test('when making plain text then Markdown and length are reduced', () {
      expect(
        BoardText.plain('## What happened\n**Bold** [link](http://x)', max: 20),
        'What happened Bold…',
      );
    });
  });
}
