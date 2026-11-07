import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/testing.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

void main() {
  late CommandTestHarness h;
  late FakeAssistantApi api;
  final item = UuidValue.fromString('0192f000-0000-7000-8000-000000000009');

  setUp(() {
    h = CommandTestHarness();
    api = FakeAssistantApi();
    ShellAssistant.install(h.services, api: api);
  });
  tearDown(() {
    ShellAssistant.uninstall(h.services);
    h.dispose();
  });

  Future<void> open(
    WidgetTester tester, {
    UuidValue? itemUuid,
    Brightness b = Brightness.light,
  }) async {
    late BuildContext ctx;
    await pumpWonky(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox.expand();
        },
      ),
      brightness: b,
      size: const Size(1200, 900),
      extraDelegates: const [WonkyAppLocalizations.delegate],
      wrap: (context, child) =>
          Provider<ShellServices>.value(value: h.services, child: child!),
    );
    unawaited(showStyleGuidesDialog(ctx, h.services, itemUuid: itemUuid));
    await tester.pumpAndSettle();
  }

  for (final b in Brightness.values) {
    testWidgets(
      'Given the library in ${b.name} when it opens then the built-in '
      'guides are listed and the selected one is shown',
      (tester) async {
        await open(tester, b: b);

        expect(_key('dialog.styleGuides'), findsOneWidget);
        expect(find.text('Built-in'), findsOneWidget);
        expect(find.text('Plain language'), findsWidgets);
        await tester.tap(_key('dialog.styleGuides.item.builtin:technical'));
        await tester.pumpAndSettle();
        expect(find.text('Technical documentation'), findsWidgets);
        expect(_key('dialog.styleGuides.duplicate'), findsOneWidget);
        // Built-ins are not editable.
        expect(_key('dialog.styleGuides.edit'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Given a document when a guide is used for it then the choice is saved '
    'and Undo restores it',
    (tester) async {
      await open(tester, itemUuid: item);
      await tester.tap(_key('dialog.styleGuides.item.builtin:technical'));
      await tester.pumpAndSettle();

      await tester.tap(_key('dialog.styleGuides.use'));
      await tester.pumpAndSettle();

      expect(api.documentRefs[item.uuid], 'builtin:technical');
      expect(find.text('Used by this document'), findsWidgets);
      expect(h.services.undo.undoLabel.value, 'Change style guide');
      await h.services.undo.undo();
      await tester.pumpAndSettle();
      expect(api.documentRefs[item.uuid], isNull);
    },
  );

  testWidgets(
    'Given the editor when a new guide is written and shared then it is '
    'saved and listed under my guides',
    (tester) async {
      await open(tester);
      await tester.tap(_key('dialog.styleGuides.new'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: _key('dialog.styleGuides.name'),
          matching: find.byType(EditableText),
        ),
        'House style',
      );
      await enterMarkdown(
        tester,
        _key('dialog.styleGuides.markdown'),
        '# Voice\n\n- Short sentences.',
      );
      await tester.tap(_key('dialog.styleGuides.share'));
      await tester.pumpAndSettle();
      expect(find.text('Share with acme.dev'), findsOneWidget);

      await tester.tap(_key('dialog.styleGuides.save'));
      await tester.pumpAndSettle();

      expect(api.styleCalls, ['save:House style']);
      final saved = api.guides.last;
      expect(saved.sharedWithOrg, isTrue);
      expect(saved.markdown, contains('Short sentences.'));
      expect(find.text('My style guides'), findsOneWidget);
      expect(_key('dialog.styleGuides.item.${saved.ref}'), findsOneWidget);
      // The user's own guide can be edited and deleted.
      expect(_key('dialog.styleGuides.edit'), findsOneWidget);
      await tester.tap(_key('dialog.styleGuides.delete'));
      await tester.pumpAndSettle();
      expect(api.guides.where((g) => g.ref == saved.ref), isEmpty);
      await h.services.undo.undo();
      await tester.pumpAndSettle();
      expect(api.guides.where((g) => g.ref == saved.ref), hasLength(1));
    },
  );

  testWidgets('Given a guide without a name when saving then it asks for one', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(_key('dialog.styleGuides.new'));
    await tester.pumpAndSettle();
    await tester.tap(_key('dialog.styleGuides.save'));
    await tester.pumpAndSettle();
    expect(find.text('Give the style guide a name.'), findsOneWidget);
    expect(api.styleCalls, isEmpty);
  });
}
