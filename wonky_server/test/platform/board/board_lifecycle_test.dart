import 'dart:io';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/board/board_sweep.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/platform/storage/storage_service.dart';

import '../../support/file_fixtures.dart';
import '../../support/test_files.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';
import 'support/board_harness.dart';

Matcher _code(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

void main() {
  withWonkyServerpod('Given the board', (sessionBuilder, endpoints) {
    late BoardHarness h;
    late TestUser anna;
    late TestUser bo;
    late TestUser admin;
    setUp(() async {
      h = BoardHarness.install();
      h.ai.jev = false;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      admin = await BoardHarness.admin(sessionBuilder);
    });
    tearDown(() => h.uninstall());

    /// Uploads [bytes] as a board screenshot of [who]; returns its uuid.
    Future<UuidValue> screenshot(
      TestUser who, {
      String fixture = 'image.png',
      String mime = 'image/png',
    }) async {
      final bytes = FileFixtures.bytes(fixture);
      final uuid = const Uuid().v7obj();
      await endpoints.board.createScreenshotUpload(
        who.endpointSession,
        uuid,
        mime,
        bytes.length,
      );
      await TestFiles.putBytes(sessionBuilder.build(), uuid, bytes);
      await endpoints.file.completeUpload(who.endpointSession, uuid);
      return uuid;
    }

    group('when uploading screenshots', () {
      final refused = <(String, String, int, WonkyErrorCode)>[
        ('a GIF', 'image/gif', 1000, WonkyErrorCode.invalidArgument),
        ('a WebP', 'image/webp', 1000, WonkyErrorCode.invalidArgument),
        (
          'a 6 MB PNG',
          'image/png',
          6 * 1024 * 1024,
          WonkyErrorCode.tooLarge,
        ),
      ];
      for (final (name, mime, size, code) in refused) {
        test('of $name then it is refused', () async {
          await expectLater(
            endpoints.board.createScreenshotUpload(
              anna.endpointSession,
              const Uuid().v7obj(),
              mime,
              size,
            ),
            _code(code),
          );
        });
      }

      test('signed out then it is refused', () async {
        await expectLater(
          endpoints.board.createScreenshotUpload(
            TestUsers.unauthenticated(sessionBuilder),
            const Uuid().v7obj(),
            'image/png',
            100,
          ),
          _code(WonkyErrorCode.forbidden),
        );
      });

      test(
        'whose bytes are not the declared type then completing fails',
        () async {
          await expectLater(
            screenshot(anna, fixture: 'photo.jpg'),
            _code(WonkyErrorCode.invalidArgument),
          );
        },
      );

      test(
        'then the file has no item, expires in a day and costs no quota',
        () async {
          final before = await StorageService.instance.usage(
            sessionBuilder.build(),
            anna.id,
          );
          final uuid = await screenshot(anna);
          final file = await FileService.byUuid(sessionBuilder.build(), uuid);
          final after = await StorageService.instance.usage(
            sessionBuilder.build(),
            anna.id,
          );

          expect(file!.kind, StoredFileKind.boardScreenshot);
          expect(file.itemId, isNull);
          expect(file.storageId, 'private');
          expect(file.expiresAt, isNotNull);
          expect(
            (after.bytesUsed, after.reservedBytes),
            (before.bytesUsed, before.reservedBytes),
          );
        },
      );

      test('then an unattached screenshot is cleaned up after a day', () async {
        final uuid = await screenshot(anna);

        await FileService.cleanupExpired(
          sessionBuilder.build(),
          now: DateTime.now().toUtc().add(const Duration(hours: 25)),
        );

        expect(await FileService.byUuid(sessionBuilder.build(), uuid), isNull);
      });

      test('then a post shows it to everyone through a signed url, and other '
          'users cannot read the file directly', () async {
        final uuid = await screenshot(anna);
        final post = await endpoints.board.createPost(
          anna.endpointSession,
          BoardHarness.draft(screenshot: uuid),
        );

        final url = await endpoints.board.getScreenshotUrl(
          TestUsers.unauthenticated(sessionBuilder),
          post.number,
        );
        final file = await FileService.byUuid(sessionBuilder.build(), uuid);

        expect(post.hasScreenshot, isTrue);
        expect(url, isNotNull);
        expect(file!.expiresAt, isNull);
        await expectLater(
          endpoints.file.getUrl(bo.endpointSession, uuid),
          _code(WonkyErrorCode.notFound),
        );
      });

      test("then someone else's screenshot cannot be attached", () async {
        final uuid = await screenshot(anna);

        await expectLater(
          endpoints.board.createPost(
            bo.endpointSession,
            BoardHarness.draft(screenshot: uuid),
          ),
          _code(WonkyErrorCode.notFound),
        );
      });

      test('then removing it deletes the bytes at once', () async {
        final uuid = await screenshot(anna);
        final post = await endpoints.board.createPost(
          anna.endpointSession,
          BoardHarness.draft(screenshot: uuid),
        );

        final view = await endpoints.board.removeScreenshot(
          admin.endpointSession,
          post.number,
        );

        expect(view.hasScreenshot, isFalse);
        expect(await FileService.byUuid(sessionBuilder.build(), uuid), isNull);
      });
    });

    group('when posting fast', () {
      test('then the hourly post limit applies', () async {
        BoardConfig.current = BoardConfig(
          limits: const BoardLimits(postsPerHour: 2),
        );
        await BoardHarness.post(endpoints, anna);
        await BoardHarness.post(endpoints, anna);

        await expectLater(
          BoardHarness.post(endpoints, anna),
          _code(WonkyErrorCode.limitExceeded),
        );
        await expectLater(BoardHarness.post(endpoints, bo), completes);
      });

      test('then the comment limit applies', () async {
        BoardConfig.current = BoardConfig(
          limits: const BoardLimits(commentsPerHour: 1),
        );
        final post = await BoardHarness.post(endpoints, anna);
        Future<Object?> add() => endpoints.board.addComment(
          bo.endpointSession,
          const Uuid().v4obj(),
          post.number,
          null,
          'Hi',
        );
        await add();

        await expectLater(add(), _code(WonkyErrorCode.limitExceeded));
      });

      test('then the vote limit applies', () async {
        BoardConfig.current = BoardConfig(
          limits: const BoardLimits(votesPerHour: 2),
        );
        final post = await BoardHarness.post(
          endpoints,
          anna,
          kind: BoardPostKind.idea,
        );
        await endpoints.board.vote(bo.endpointSession, post.number, 1);
        await endpoints.board.vote(bo.endpointSession, post.number, -1);

        await expectLater(
          endpoints.board.vote(bo.endpointSession, post.number, 0),
          _code(WonkyErrorCode.limitExceeded),
        );
      });

      test('then the flag limit applies', () async {
        BoardConfig.current = BoardConfig(
          limits: const BoardLimits(flagsPerDay: 1),
          flagsToHold: 100,
        );
        final a = await BoardHarness.post(endpoints, anna);
        final b = await BoardHarness.post(endpoints, anna);
        await endpoints.board.flag(
          bo.endpointSession,
          a.number,
          null,
          BoardFlagReason.spam,
          null,
        );

        await expectLater(
          endpoints.board.flag(
            bo.endpointSession,
            b.number,
            null,
            BoardFlagReason.spam,
            null,
          ),
          _code(WonkyErrorCode.limitExceeded),
        );
      });

      test('then the similar-post limit applies', () async {
        BoardConfig.current = BoardConfig(
          limits: const BoardLimits(similarPerMinute: 1),
        );
        await endpoints.board.similar(bo.endpointSession, 'a b c', '', null);

        await expectLater(
          endpoints.board.similar(bo.endpointSession, 'a b c', '', null),
          _code(WonkyErrorCode.limitExceeded),
        );
      });

      test('then an admin has no limits', () async {
        BoardConfig.current = BoardConfig(
          limits: const BoardLimits(
            postsPerHour: 1,
            postsPerDay: 1,
            commentsPerHour: 1,
            votesPerHour: 1,
            flagsPerDay: 1,
            similarPerMinute: 1,
          ),
          flagsToHold: 100,
        );
        final s = admin.endpointSession;
        final a = await BoardHarness.post(endpoints, admin);
        final b = await BoardHarness.post(
          endpoints,
          admin,
          kind: BoardPostKind.idea,
        );
        await BoardHarness.post(endpoints, admin);
        final other = await BoardHarness.post(endpoints, anna);
        for (var i = 0; i < 2; i++) {
          await endpoints.board.addComment(
            s,
            const Uuid().v4obj(),
            a.number,
            null,
            'Note $i',
          );
          await endpoints.board.similar(s, 'a b c', '', null);
        }
        await endpoints.board.vote(s, b.number, 1);
        await endpoints.board.vote(s, b.number, -1);
        await endpoints.board.vote(s, b.number, 0);
        for (final post in [a, other]) {
          await endpoints.board.flag(
            s,
            post.number,
            null,
            BoardFlagReason.spam,
            null,
          );
        }

        // Everyone else still has them.
        await expectLater(
          BoardHarness.post(endpoints, anna),
          _code(WonkyErrorCode.limitExceeded),
        );
      });
    });

    group('when the retention sweep runs', () {
      test('then removed posts older than 90 days and deleted posts older '
          'than 30 days are purged with their screenshots', () async {
        final uuid = await screenshot(anna);
        final removed = await endpoints.board.createPost(
          anna.endpointSession,
          BoardHarness.draft(screenshot: uuid),
        );
        await endpoints.board.moderatePost(
          admin.endpointSession,
          removed.number,
          BoardModerationAction.remove,
          'Spam',
        );
        final deleted = await BoardHarness.post(endpoints, anna);
        await endpoints.board.deletePost(anna.endpointSession, deleted.number);
        final recent = await BoardHarness.post(endpoints, anna);
        await endpoints.board.deletePost(anna.endpointSession, recent.number);
        final session = sessionBuilder.build();

        await withClock(
          Clock.fixed(DateTime.now().toUtc().add(const Duration(days: 91))),
          () async {
            // Only the old ones: the recent delete is moved forward.
            final r = await BoardPost.db.findById(session, recent.number);
            await BoardPost.db.updateRow(
              session,
              r!.copyWith(deletedAt: clock.now().toUtc()),
            );
            await BoardSweep.purge(session);
          },
        );

        expect(await BoardPost.db.findById(session, removed.number), isNull);
        expect(await BoardPost.db.findById(session, deleted.number), isNull);
        expect(await BoardPost.db.findById(session, recent.number), isNotNull);
        expect(await FileService.byUuid(session, uuid), isNull);
      });
    });

    test('when an account is deleted then its posts outside tasks, votes and '
        'screenshots go and the rest is anonymized', () async {
      final uuid = await screenshot(anna);
      final alone = await endpoints.board.createPost(
        anna.endpointSession,
        BoardHarness.draft(screenshot: uuid),
      );
      final inTask = await BoardHarness.post(endpoints, anna);
      await endpoints.board.createTask(
        admin.endpointSession,
        [inTask.number],
        'Keep it',
        BoardArea.sheets,
        BoardSize.small,
      );
      final bos = await BoardHarness.post(endpoints, bo);
      await endpoints.board.vote(anna.endpointSession, bos.number, 1);
      await endpoints.board.addComment(
        anna.endpointSession,
        const Uuid().v4obj(),
        bos.number,
        null,
        'Me too',
      );

      await endpoints.user.deleteAccount(anna.endpointSession, anna.email);

      final session = sessionBuilder.build();
      final kept = await endpoints.board.getPost(
        bo.endpointSession,
        inTask.number,
      );
      final bosPost = await endpoints.board.getPost(
        bo.endpointSession,
        bos.number,
      );
      final comments = await endpoints.board.listComments(
        bo.endpointSession,
        bos.number,
      );
      expect(await BoardPost.db.findById(session, alone.number), isNull);
      expect(await FileService.byUuid(session, uuid), isNull);
      expect(kept.author, isNull);
      expect(bosPost.score, 1);
      expect(comments.single.author, isNull);
      expect(comments.single.body, 'Me too');
    });

    test('when the server starts then the sweep is a recurring job every 10 '
        'minutes', () {
      expect(
        File('lib/server.dart').readAsStringSync(),
        contains(
          "'wonky.boardSweep': ('*/10 * * * *', (r) => r.board.sweep())",
        ),
      );
    });
  });
}
