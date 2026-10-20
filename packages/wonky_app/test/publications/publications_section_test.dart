import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import '../support/screen_pump.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

void main() {
  late CommandTestHarness h;
  late FakePublicationRepository repo;

  setUp(() {
    repo = FakePublicationRepository();
    h = CommandTestHarness(publications: repo);
  });
  tearDown(() => h.dispose());

  Future<void> pump(WidgetTester tester, Brightness b) => pumpScreen(
    tester,
    h,
    SingleChildScrollView(child: PublicationsSection(services: h.services)),
    brightness: b,
  );

  for (final b in Brightness.values) {
    group('Given no publications (${b.name})', () {
      testWidgets('then the empty state shows', (tester) async {
        await pump(tester, b);

        expect(_key('settings.publications.empty'), findsOneWidget);
      });

      testWidgets('when creating one then the signing secret is shown once '
          'with the contributor link', (tester) async {
        await pump(tester, b);

        await tester.tap(_key('settings.publications.new'));
        await tester.pumpAndSettle();
        await tester.enterText(_key('dialog.publication.name'), 'My blog');
        await tester.enterText(
          _key('dialog.publication.siteUrl'),
          'https://blog.example.com',
        );
        await tester.enterText(
          _key('dialog.publication.webhookUrl'),
          'https://blog.example.com/hook',
        );
        await tester.tap(_key('dialog.publication.save'));
        await tester.pumpAndSettle();

        expect(repo.calls, contains('create'));
        expect(_key('settings.publications.secret'), findsOneWidget);
        expect(find.text('whsec_c2VjcmV0'), findsOneWidget);
        expect(
          find.text('https://wonky.work/write/new?publication=pub_${'B' * 22}'),
          findsOneWidget,
        );
        await tester.tap(find.text("I've stored it"));
        await tester.pumpAndSettle();
        expect(find.text('whsec_c2VjcmV0'), findsNothing);
      });

      testWidgets('when the webhook is not https then it is refused', (
        tester,
      ) async {
        await pump(tester, b);

        await tester.tap(_key('settings.publications.new'));
        await tester.pumpAndSettle();
        await tester.enterText(_key('dialog.publication.name'), 'My blog');
        await tester.enterText(
          _key('dialog.publication.siteUrl'),
          'https://blog.example.com',
        );
        await tester.enterText(
          _key('dialog.publication.webhookUrl'),
          'http://blog.example.com/hook',
        );
        await tester.tap(_key('dialog.publication.save'));
        await tester.pumpAndSettle();

        expect(repo.calls, isNot(contains('create')));
        expect(find.text('Use an https:// address.'), findsOneWidget);
      });
    });
  }

  group('Given a publication', () {
    setUp(() {
      repo.publications.add(
        PublicationSettings(
          publicId: 'pub_${'C' * 22}',
          name: 'Serverpod blog',
          siteUrl: 'https://blog.example.com',
          webhookUrl: 'https://blog.example.com/hook',
          fields: FakePublicationRepository.fields(),
          moderators: [],
          hasApiKey: false,
          enabled: true,
          contributorLink: 'https://wonky.work/write/new?publication=x',
          openSubmissionCount: 2,
          createdAt: DateTime.utc(2026, 10, 20),
        ),
      );
    });

    testWidgets('when managing it and creating an API key then the key is '
        'shown once', (tester) async {
      await pump(tester, Brightness.light);

      expect(find.textContaining('2 stories in review'), findsOneWidget);
      await tester.tap(_key('settings.publications.open.pub_${'C' * 22}'));
      await tester.pumpAndSettle();
      await tester.tap(_key('settings.publications.apiKey'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('createApiKey'));
      expect(find.text('wpk_${'k' * 40}'), findsOneWidget);
    });
  });
}
