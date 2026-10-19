@Tags(['integration'])
library;

import 'dart:io';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import '../../../support/board/board_harness.dart';

/// The callers of the access matrix (specs/16 §7.1).
enum Who { signedOut, signedIn, author, admin, blocked }

const _writers = {Who.signedIn, Who.author, Who.admin};
const _everyone = {
  Who.signedOut,
  Who.signedIn,
  Who.author,
  Who.admin,
  Who.blocked,
};

void main() {
  withWonkyServerpod('Given a post and the five kinds of callers', (
    sessionBuilder,
    endpoints,
  ) {
    late BoardHarness h;
    late Map<Who, TestSessionBuilder> as;
    late TestUser author;
    late TestUser admin;
    setUp(() async {
      h = BoardHarness.install();
      h.ai.jev = false;
      author = await TestUsers.create(sessionBuilder, name: 'Author');
      admin = await BoardHarness.admin(sessionBuilder);
      final other = await TestUsers.create(sessionBuilder, name: 'Other');
      final blocked = await TestUsers.create(sessionBuilder, name: 'Blocked');
      await endpoints.board.blockUser(
        admin.endpointSession,
        blocked.id,
        'Spam',
        null,
      );
      as = {
        Who.signedOut: TestUsers.unauthenticated(sessionBuilder),
        Who.signedIn: other.endpointSession,
        Who.author: author.endpointSession,
        Who.admin: admin.endpointSession,
        Who.blocked: blocked.endpointSession,
      };
    });
    tearDown(() => h.uninstall());

    Future<int> visiblePost() async =>
        (await BoardHarness.post(endpoints, author)).number;

    Future<int> moderated(BoardModerationAction action) async {
      final n = await visiblePost();
      await endpoints.board.moderatePost(
        admin.endpointSession,
        n,
        action,
        'Contains a phone number',
      );
      return n;
    }

    void matrix(
      String what,
      Set<Who> allowed,
      Future<Object?> Function(TestSessionBuilder s, int post) act, {
      Future<int> Function()? post,
    }) {
      for (final who in Who.values) {
        final ok = allowed.contains(who);
        test('when ${who.name} ${ok ? 'can' : 'cannot'} $what', () async {
          final n = await (post ?? visiblePost)();
          final call = act(as[who]!, n);
          if (ok) {
            await expectLater(call, completes);
          } else {
            await expectLater(call, throwsA(isA<WonkyException>()));
          }
        });
      }
    }

    matrix(
      'read a visible post',
      _everyone,
      (s, n) => endpoints.board.getPost(s, n),
    );
    matrix(
      'read its comments',
      _everyone,
      (s, n) => endpoints.board.listComments(s, n),
    );
    matrix(
      'get its screenshot url',
      _everyone,
      (s, n) => endpoints.board.getScreenshotUrl(s, n),
    );
    matrix(
      'read a held post',
      {Who.author, Who.admin},
      (s, n) => endpoints.board.getPost(s, n),
      post: () => moderated(BoardModerationAction.hold),
    );
    matrix(
      'read a removed post',
      {Who.author, Who.admin},
      (s, n) => endpoints.board.getPost(s, n),
      post: () => moderated(BoardModerationAction.remove),
    );
    matrix(
      'create a post',
      _writers,
      (s, _) => endpoints.board.createPost(s, BoardHarness.draft()),
    );
    matrix('vote', _writers, (s, n) => endpoints.board.vote(s, n, 1));
    matrix(
      'comment',
      _writers,
      (s, n) => endpoints.board.addComment(
        s,
        const Uuid().v4obj(),
        n,
        null,
        'Same here',
      ),
    );
    matrix(
      'flag',
      _writers,
      (s, n) => endpoints.board.flag(s, n, null, BoardFlagReason.spam, null),
    );
    matrix(
      'edit the post',
      {Who.author},
      (s, n) => endpoints.board.editPost(s, n, 'A changed title', 'New body'),
    );
    matrix(
      'remove the screenshot',
      {Who.author, Who.admin},
      (s, n) => endpoints.board.removeScreenshot(s, n),
    );
    matrix(
      'moderate',
      {Who.admin},
      (s, n) => endpoints.board.moderatePost(
        s,
        n,
        BoardModerationAction.markChecked,
        null,
      ),
    );
    matrix('see the review counts', {
      Who.admin,
    }, (s, _) => endpoints.board.reviewCounts(s));
    matrix(
      'create a task',
      {Who.admin},
      (s, n) => endpoints.board.createTask(
        s,
        [n],
        'Fix it',
        BoardArea.sheets,
        BoardSize.small,
      ),
    );

    test('when a removed post is read by its author then the reason is '
        'shown, and for others no admin fields leak', () async {
      final n = await moderated(BoardModerationAction.remove);

      final mine = await endpoints.board.getPost(as[Who.author]!, n);

      expect(mine.moderation, BoardModeration.removed);
      expect(mine.moderationReason, 'Contains a phone number');
      expect(mine.triageJson, isNull);
      expect(mine.flags, isNull);
    });

    test('when reading a post then the author is shown without an email '
        'and the admin badge comes from the server', () async {
      final n = (await BoardHarness.post(endpoints, admin)).number;

      final view = await endpoints.board.getPost(as[Who.signedOut]!, n);

      expect(view.author!.isAdmin, isTrue);
      expect(view.author!.toJson().toString(), isNot(contains('@')));
    });

    test(
      'when asking me() then signed out, admin and blocked are reported',
      () async {
        final out = await endpoints.board.me(as[Who.signedOut]!);
        final adm = await endpoints.board.me(as[Who.admin]!);
        final blk = await endpoints.board.me(as[Who.blocked]!);

        expect((out.signedIn, out.isAdmin), (false, false));
        expect((adm.signedIn, adm.isAdmin, adm.blocked), (true, true, false));
        expect((blk.blocked, blk.blockedReason), (true, 'Spam'));
        expect(adm.repository, 'serverpod/wonky');
      },
    );

    test('when a block expires then the user can write again', () async {
      final user = await TestUsers.create(sessionBuilder, name: 'Temp');
      await endpoints.board.blockUser(
        admin.endpointSession,
        user.id,
        'Cool down',
        clock.now().toUtc().add(const Duration(hours: 1)),
      );
      await expectLater(
        endpoints.board.createPost(user.endpointSession, BoardHarness.draft()),
        throwsA(isA<WonkyException>()),
      );

      await endpoints.board.unblockUser(admin.endpointSession, user.id);

      await expectLater(
        endpoints.board.createPost(user.endpointSession, BoardHarness.draft()),
        completes,
      );
    });
  });

  group('Given the trust in the profile email (specs/16 §9.1)', () {
    test('when listing every endpoint method then none changes an email', () {
      final source = File(
        'lib/src/generated/endpoints.dart',
      ).readAsStringSync();
      final methods = [
        for (final m in RegExp(
          r"'(\w+)': _\w+\.MethodConnector\(",
        ).allMatches(source))
          m[1]!,
      ];

      expect(methods, isNotEmpty);
      expect(
        methods.where(
          (m) => RegExp(
            r'(change|update|set|edit|replace).*email|email.*(change|update)',
            caseSensitive: false,
          ).hasMatch(m),
        ),
        isEmpty,
      );
    });

    test('when reading the profile update then it cannot write the email', () {
      final source = File(
        'lib/src/platform/users/user_service.dart',
      ).readAsStringSync();
      final update = RegExp(
        r'static Future<UserProfileView> updateProfile\([\s\S]*?\n  \}',
      ).firstMatch(source)![0]!;

      expect(update, isNot(contains('email')));
    });

    test('when configuring Google sign-in then the package default check of '
        'verified emails is not overridden', () {
      final offenders = [
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              RegExp(
                r'validateGoogleAccountDetails\s*:',
              ).hasMatch(f.readAsStringSync()))
            f.path,
      ];

      expect(offenders, isEmpty);
      expect(
        File('lib/src/platform/users/google_idp.dart').readAsStringSync(),
        contains('GoogleIdpConfig('),
      );
    });
  });
}
