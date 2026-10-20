import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import '../support/screen_pump.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

/// Runs [startPublicationStory] from a button so it gets a context below
/// the shell.
class _Starter extends StatelessWidget {
  const _Starter({required this.onDone});

  final void Function(UuidValue?) onDone;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey<String>('start'),
    behavior: HitTestBehavior.opaque,
    onTap: () async {
      final s = ShellScope.of(context);
      onDone(
        await startPublicationStory(context, s, 'pub_${'A' * 22}', ref: 'x'),
      );
    },
    child: const SizedBox(width: 100, height: 40),
  );
}

PublicationCard _card({
  bool consentNeeded = true,
  String? termsUrl,
  List<PublicationOpenSubmission> open = const [],
  bool blocked = false,
  bool verified = true,
}) => PublicationCard(
  publicId: 'pub_${'A' * 22}',
  name: 'Serverpod blog',
  shownHost: verified ? 'blog.example.com' : 'hooks.example.net',
  verified: verified,
  siteHost: 'blog.example.com',
  webhookHost: 'hooks.example.net',
  termsUrl: termsUrl,
  fields: FakePublicationRepository.fields(),
  ownerName: 'Owner',
  enabled: true,
  consentNeeded: consentNeeded,
  blocked: blocked,
  openSubmissions: open,
);

void main() {
  late CommandTestHarness h;
  late FakePublicationRepository repo;
  UuidValue? result;
  var done = false;

  Future<void> start(WidgetTester tester) async {
    done = false;
    await pumpScreen(
      tester,
      h,
      _Starter(
        onDone: (u) {
          result = u;
          done = true;
        },
      ),
    );
    await tester.tap(_key('start'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = FakePublicationRepository();
    h = CommandTestHarness(publications: repo);
  });
  tearDown(() => h.dispose());

  group('Given a contributor link of a verified publication', () {
    testWidgets('when consent is needed then the dialog explains what is '
        'shared and starting creates the story with consent', (tester) async {
      repo.card = _card();
      await start(tester);

      expect(find.textContaining('Serverpod blog receives'), findsOneWidget);
      expect(find.textContaining('blog.example.com ✓'), findsOneWidget);
      await tester.tap(find.text('Start writing'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
      expect(result, repo.startedItem);
      expect(repo.calls, contains('startSubmission:agreed'));
    });

    testWidgets('when consent was given and nothing is open then the story '
        'starts without a dialog', (tester) async {
      repo.card = _card(consentNeeded: false);
      await start(tester);

      expect(_key('dialog.publicationStart'), findsNothing);
      expect(result, repo.startedItem);
      expect(repo.calls, contains('startSubmission'));
    });

    testWidgets('when there are terms and they are not agreed to then '
        'nothing starts', (tester) async {
      repo.card = _card(termsUrl: 'https://blog.example.com/terms');
      await start(tester);

      await tester.tap(find.text('Start writing'));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(repo.calls, isNot(contains('startSubmission:agreed')));
    });

    testWidgets('when a draft is open then it is offered and continuing '
        'opens it without creating', (tester) async {
      final draft = UuidValue.fromString(
        '01900000-0000-7000-8000-0000000000d1',
      );
      repo.card = _card(
        consentNeeded: false,
        open: [
          PublicationOpenSubmission(
            itemUuid: draft,
            name: 'My draft',
            status: SubmissionStatus.draft,
            updatedAt: DateTime.utc(2026, 10, 19),
          ),
        ],
      );
      await start(tester);

      await tester.tap(find.text('Start writing'));
      await tester.pumpAndSettle();

      expect(result, draft);
      expect(repo.calls, isNot(contains('startSubmission')));
    });
  });

  group('Given an unverified publication', () {
    testWidgets('then the dialog names the webhook host', (tester) async {
      repo.card = _card(verified: false);
      await start(tester);

      expect(find.textContaining('hooks.example.net'), findsOneWidget);
      expect(find.textContaining('hasn\'t verified'), findsOneWidget);
    });
  });

  group('Given a publication that blocked the contributor', () {
    testWidgets('then it says so and nothing starts', (tester) async {
      repo.card = _card(blocked: true);
      await start(tester);

      expect(
        find.textContaining('isn\'t accepting stories from you'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(repo.calls, ['resolve']);
    });
  });

  test('when a /new query has a publication then the request carries it', () {
    final r = NewItemRequest.fromQuery({
      'publication': 'pub_${'A' * 22}',
      'ref': 'cfp',
    });

    expect(r.publicationId, 'pub_${'A' * 22}');
    expect(r.ref, 'cfp');
    expect(r.path, '/new?publication=pub_${'A' * 22}&ref=cfp');
  });
}
