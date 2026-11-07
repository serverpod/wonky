import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:shad/shad.dart' show ShadInput, LucideIcons;
import 'package:wonky_ui/wonky_ui.dart' show WonkyMenuEntry, WonkyMenuItem;
import 'package:wonky_ui/testing.dart';

/// A document adapter recording what the panel asks for.
class _Adapter extends ChangeNotifier implements AssistantDocumentAdapter {
  _Adapter();

  @override
  final UuidValue itemUuid = UuidValue.fromString(
    '0192f000-0000-7000-8000-000000000001',
  );

  @override
  Role role = Role.editor;

  List<AssistantContextChip> chipList = const [
    AssistantContextChip(id: 'selection', label: 'Selection: 2 paragraphs'),
  ];
  final shown = <AssistantActivity>[];
  final undone = <String>[];
  final finished = <String>[];
  final inserted = <String>[];
  bool canUndo = true;
  Set<String>? lastChips;

  @override
  List<AssistantContextChip> get chips => chipList;

  @override
  List<AssistantQuickPrompt> get quickPrompts => const [
    AssistantQuickPrompt(label: 'Summarize', prompt: 'Summarize this document'),
  ];

  @override
  AssistantContextHints hints({
    required AiApplyMode applyMode,
    required Set<String> chips,
    bool includeComments = false,
  }) {
    lastChips = chips;
    return AssistantContextHints(
      applyMode: applyMode,
      selectionText: chips.contains('selection') ? 'Hello' : null,
      includeComments: includeComments,
    );
  }

  @override
  void show(AssistantActivity activity) => shown.add(activity);

  @override
  Future<bool> undoRun(String runId) async {
    undone.add(runId);
    return canUndo;
  }

  @override
  void runFinished(String runId, String summary) => finished.add(summary);

  @override
  Future<bool> insertMarkdown(String markdown, {bool atTop = false}) async {
    inserted.add(markdown);
    return true;
  }
}

/// An adapter with Write's panel extras (quick actions, suggestions only).
class _WriteLikeAdapter extends _Adapter implements AssistantPanelExtras {
  final pressed = <String>[];
  AssistantController? controller;

  @override
  bool get alwaysSuggests => true;

  @override
  List<AssistantQuickActionButton> get quickActions => [
    AssistantQuickActionButton(
      id: 'proofread',
      label: 'Proofread',
      icon: LucideIcons.spellCheck,
      onPressed: () {
        pressed.add('proofread');
        controller?.runQuickAction(
          AssistantQuickAction.proofread,
          workingLabel: 'Proofreading…',
        );
      },
    ),
  ];

  @override
  List<WonkyMenuEntry> moreMenuEntries() => [
    WonkyMenuItem(label: 'Style guides…', onSelected: () {}),
  ];

  @override
  Widget? errorAction(BuildContext context, AssistantReplyEntry reply) =>
      reply.errorCode == 'no_style'
      ? const Text('Choose a style guide', key: ValueKey('chooseStyle'))
      : null;
}

void main() {
  late CommandTestHarness h;
  late FakeAssistantApi api;
  late _Adapter adapter;
  late AssistantController controller;
  late ValueNotifier<AssistantStatus?> status;

  setUp(() {
    h = CommandTestHarness();
    api = FakeAssistantApi();
    adapter = _Adapter();
    status = ValueNotifier(api.status);
    controller = AssistantController(
      api: api,
      adapter: adapter,
      status: status,
    );
  });
  tearDown(() {
    controller.dispose();
    h.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness b = Brightness.light,
  }) async {
    await pumpWonky(
      tester,
      SizedBox(
        width: 420,
        height: 900,
        child: AssistantPanel(services: h.services, controller: controller),
      ),
      brightness: b,
      size: const Size(420, 900),
      extraDelegates: const [WonkyAppLocalizations.delegate],
      wrap: (context, child) =>
          Provider<ShellServices>.value(value: h.services, child: child!),
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendText(
    WidgetTester tester,
    String text, {
    bool settle = true,
  }) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('assistant.input')),
        matching: find.byType(EditableText),
      ),
      text,
    );
    // Enter sends (there is no Send button).
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final b in Brightness.values) {
    testWidgets(
      'Given an empty chat in ${b.name} when the panel shows then the '
      'composer, quick prompts, context chip and privacy notice are there',
      (tester) async {
        await pump(tester, b: b);
        expect(
          find.byKey(const ValueKey<String>('assistant.input')),
          findsOneWidget,
        );
        expect(find.text('Summarize'), findsOneWidget);
        expect(find.text('Selection: 2 paragraphs'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('assistant.notice')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Given a reply with a tool change when it streams then Markdown and '
    'the chip with Show and Undo appear',
    (tester) async {
      api.chatScripts.add([
        AssistantEvent(
          type: AssistantEventType.toolStarted,
          toolUseId: 't1',
          toolName: 'write.replace_text',
          toolSummary: 'Replacing text',
        ),
        AssistantEvent(
          type: AssistantEventType.toolFinished,
          toolUseId: 't1',
          toolName: 'write.replace_text',
          toolSummary: 'Replaced 1 occurrence',
          toolError: false,
          changeId: 'c1',
          rangeStart: 4,
          rangeLength: 3,
          revision: 2,
        ),
        AssistantEvent(
          type: AssistantEventType.textDelta,
          text: 'I **fixed** it.',
        ),
        AssistantEvent(type: AssistantEventType.done),
      ]);
      await pump(tester);
      await sendText(tester, 'Fix the typo');

      expect(api.sent, ['Fix the typo']);
      expect(adapter.lastChips, {'selection'});
      expect(find.text('Fix the typo'), findsWidgets);
      expect(find.text('Replaced 1 occurrence'), findsOneWidget);
      expect(find.textContaining('fixed', findRichText: true), findsOneWidget);
      expect(adapter.finished, ['Replaced 1 occurrence']);

      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.activity.show')),
      );
      expect(adapter.shown.single.rangeStart, 4);

      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.activity.undo')),
      );
      await tester.pumpAndSettle();
      expect(adapter.undone.single, startsWith('run-'));
      expect(find.text('Undone'), findsOneWidget);
    },
  );

  testWidgets(
    "Given the client's undo step is gone when undoing then each change is "
    'reverted on the server',
    (tester) async {
      adapter.canUndo = false;
      api.chatScripts.add([
        AssistantEvent(
          type: AssistantEventType.toolFinished,
          toolUseId: 'a',
          toolSummary: 'Edit A',
          changeId: 'cA',
        ),
        AssistantEvent(
          type: AssistantEventType.toolFinished,
          toolUseId: 'b',
          toolSummary: 'Edit B',
          changeId: 'cB',
        ),
        AssistantEvent(type: AssistantEventType.done),
      ]);
      await pump(tester);
      await sendText(tester, 'Edit twice');
      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.reply.undo')),
      );
      await tester.pumpAndSettle();
      expect(api.reverted, ['cB', 'cA']);
    },
  );

  testWidgets('Given a streaming answer when Stop is pressed then it stops', (
    tester,
  ) async {
    api
      ..holdChats = true
      ..chatScripts.add([
        AssistantEvent(type: AssistantEventType.textDelta, text: 'Working'),
      ]);
    await pump(tester);
    await sendText(tester, 'Write a lot');
    expect(
      find.byKey(const ValueKey<String>('assistant.stop')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('assistant.stop')));
    await tester.pumpAndSettle();
    expect(api.stops, 1);
    expect(find.text('Stopped'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('assistant.stop')), findsNothing);
  });

  testWidgets(
    'Given a destructive change when the assistant asks then Allow answers '
    'the confirmation',
    (tester) async {
      api
        ..holdChats = true
        ..chatScripts.add([
          AssistantEvent(
            type: AssistantEventType.confirmationRequired,
            confirmationId: 'conf',
            toolSummary: 'The assistant wants to delete 4 paragraphs (Budget)',
          ),
        ]);
      await pump(tester);
      await sendText(tester, 'Remove the budget', settle: false);
      expect(find.textContaining('delete 4 paragraphs'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.confirm.allow')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.confirmations, [('conf', true)]);
      await api.releaseChat();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Given a refusal when it arrives then the notice is shown', (
    tester,
  ) async {
    api.chatScripts.add([
      AssistantEvent(
        type: AssistantEventType.refusal,
        text: "The assistant can't help with that request.",
      ),
      AssistantEvent(type: AssistantEventType.done),
    ]);
    await pump(tester);
    await sendText(tester, 'Bad request');
    expect(
      find.text("The assistant can't help with that request."),
      findsOneWidget,
    );
  });

  testWidgets('Given a cut-off answer when Continue is pressed then it sends', (
    tester,
  ) async {
    api.chatScripts.add([
      AssistantEvent(type: AssistantEventType.textDelta, text: 'Part one'),
      AssistantEvent(type: AssistantEventType.maxTokens),
      AssistantEvent(type: AssistantEventType.done),
    ]);
    await pump(tester);
    await sendText(tester, 'Write a book');
    await tester.tap(find.byKey(const ValueKey<String>('assistant.continue')));
    await tester.pumpAndSettle();
    expect(api.sent.last, 'Continue');
  });

  testWidgets(
    'Given a removed context chip when sending then it is not part of the '
    'context',
    (tester) async {
      await pump(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.chip.selection.remove')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Selection: 2 paragraphs'), findsNothing);
      await sendText(tester, 'Hello');
      expect(adapter.lastChips, isEmpty);
      expect(api.sentHints.single.selectionText, isNull);
    },
  );

  testWidgets(
    'Given Suggest mode when sending then the hints ask for suggestions',
    (tester) async {
      await pump(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.mode.suggest')),
      );
      await tester.pumpAndSettle();
      await sendText(tester, 'Tighten it');
      expect(api.sentHints.single.applyMode, AiApplyMode.suggest);
    },
  );

  testWidgets('Given a commenter when the panel shows then Suggest is forced', (
    tester,
  ) async {
    adapter.role = Role.commenter;
    await pump(tester);
    await sendText(tester, 'Fix');
    expect(api.sentHints.single.applyMode, AiApplyMode.suggest);
  });

  testWidgets(
    "Given AI isn't configured when the panel shows then it says so and "
    'sending is disabled',
    (tester) async {
      status.value = AssistantStatus(
        available: false,
        reason: 'notConfigured',
        message: "AI isn't configured on this server.",
        quality: AiQuality.best,
        tokensUsedToday: 0,
        dailyTokenBudget: 0,
      );
      await pump(tester);
      expect(find.text("AI isn't configured on this server."), findsOneWidget);
      final input = tester.widget<ShadInput>(
        find.byKey(const ValueKey<String>('assistant.input')),
      );
      expect(input.enabled, isFalse);
    },
  );

  testWidgets(
    'Given no server key when the panel shows then it offers to add an API '
    'key and the button opens Settings › AI providers',
    (tester) async {
      h.services.router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '/settings/:section',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      status.value = AssistantStatus(
        available: false,
        reason: 'notConfigured',
        quality: AiQuality.best,
        tokensUsedToday: 0,
        dailyTokenBudget: 0,
        userKeysAllowed: true,
      );
      await pump(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.addApiKey')),
      );
      await tester.pumpAndSettle();

      expect(
        h.services.router.routeInformationProvider.value.uri.path,
        '/settings/ai-providers',
      );
    },
  );

  testWidgets(
    'Given personal keys are off when AI is not configured then no key '
    'button is offered',
    (tester) async {
      status.value = AssistantStatus(
        available: false,
        reason: 'notConfigured',
        quality: AiQuality.best,
        tokensUsedToday: 0,
        dailyTokenBudget: 0,
      );
      await pump(tester);

      expect(
        find.byKey(const ValueKey<String>('assistant.addApiKey')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Given a provider when the panel shows then the privacy notice names it',
    (tester) async {
      status.value = api.status.copyWith(provider: AiProvider.gemini);
      await pump(tester);

      expect(find.textContaining('Google Gemini'), findsOneWidget);
    },
  );

  testWidgets(
    'Given an earlier thread when the panel loads then its messages are '
    'shown and runs are merged',
    (tester) async {
      api.threads[7] = AssistantThreadDetail(
        thread: AssistantThreadView(
          id: 7,
          title: 'Earlier',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        messages: [
          AssistantMessageView(
            id: 1,
            role: 'user',
            displayText: 'Question',
            createdAt: DateTime.utc(2026),
          ),
          AssistantMessageView(
            id: 2,
            role: 'assistant',
            displayText: '',
            toolCallsJson:
                '[{"toolUseId":"x","toolName":"write.search","summary":"Found 2"}]',
            runId: 'r',
            createdAt: DateTime.utc(2026),
          ),
          AssistantMessageView(
            id: 3,
            role: 'assistant',
            displayText: 'Answer',
            runId: 'r',
            createdAt: DateTime.utc(2026),
          ),
        ],
      );
      await pump(tester);
      expect(find.text('Earlier'), findsOneWidget);
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('Found 2'), findsOneWidget);
      expect(find.textContaining('Answer', findRichText: true), findsOneWidget);
      expect(controller.entries.whereType<AssistantReplyEntry>(), hasLength(1));
    },
  );

  group('Given the composer', () {
    Finder editable() => find.descendant(
      of: find.byKey(const ValueKey<String>('assistant.input')),
      matching: find.byType(EditableText),
    );

    testWidgets('when it shows then there is no Send button', (tester) async {
      await pump(tester);
      expect(
        find.byKey(const ValueKey<String>('assistant.send')),
        findsNothing,
      );
      expect(find.text('Send'), findsNothing);
    });

    testWidgets(
      'when Shift+Enter is pressed then nothing is sent, and Enter sends',
      (tester) async {
        await pump(tester);
        await tester.enterText(editable(), 'First line');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(api.sent, isEmpty);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(api.sent, ['First line']);
      },
    );

    testWidgets(
      'when empty then the field is one line and the placeholder starts '
      'where typed text starts',
      (tester) async {
        await pump(tester);
        final placeholder = find.text('Ask the assistant…');
        final emptyHeight = tester
            .getSize(find.byKey(const ValueKey<String>('assistant.input')))
            .height;
        final placeholderTop = tester.getTopLeft(placeholder);

        await tester.enterText(editable(), 'Hi');
        await tester.pump();
        final textTop = tester.getTopLeft(editable());
        final oneLineHeight = tester
            .getSize(find.byKey(const ValueKey<String>('assistant.input')))
            .height;
        await tester.enterText(editable(), 'One\nTwo\nThree');
        await tester.pump();
        final threeLineHeight = tester
            .getSize(find.byKey(const ValueKey<String>('assistant.input')))
            .height;

        expect((placeholderTop.dy - textTop.dy).abs(), lessThan(2));
        expect((placeholderTop.dx - textTop.dx).abs(), lessThan(2));
        expect(emptyHeight, oneLineHeight);
        expect(threeLineHeight, greaterThan(oneLineHeight + 20));
      },
    );
  });

  group('Given an adapter with quick actions (Write)', () {
    late _WriteLikeAdapter write;
    late AssistantController writeController;

    Future<void> pumpWrite(WidgetTester tester) async {
      await pumpWonky(
        tester,
        SizedBox(
          width: 420,
          height: 900,
          child: AssistantPanel(
            services: h.services,
            controller: writeController,
          ),
        ),
        size: const Size(420, 900),
        extraDelegates: const [WonkyAppLocalizations.delegate],
        wrap: (context, child) =>
            Provider<ShellServices>.value(value: h.services, child: child!),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      write = _WriteLikeAdapter();
      writeController = AssistantController(
        api: api,
        adapter: write,
        status: status,
      );
      write.controller = writeController;
    });
    tearDown(() => writeController.dispose());

    testWidgets(
      'when the panel shows then the actions replace the quick prompts and '
      'there is no Edit / Suggest toggle',
      (tester) async {
        await pumpWrite(tester);
        expect(
          find.byKey(const ValueKey<String>('assistant.action.proofread')),
          findsOneWidget,
        );
        expect(find.text('Summarize'), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('assistant.mode.edit')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('assistant.mode.suggest')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'when a quick action runs then no prompt is shown and the result '
      'streams in',
      (tester) async {
        api
          ..holdChats = true
          ..quickScripts.add([
            AssistantEvent(
              type: AssistantEventType.textDelta,
              text: 'Suggested 2 corrections.',
            ),
          ]);
        await pumpWrite(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('assistant.action.proofread')),
        );
        await tester.pump();
        await tester.pump();

        expect(api.quickActions, [AssistantQuickAction.proofread]);
        expect(
          writeController.entries.whereType<AssistantUserEntry>(),
          isEmpty,
        );
        expect(find.text('Proofreading…'), findsNothing);
        await api.releaseChat();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Suggested 2 corrections.', findRichText: true),
          findsOneWidget,
        );
      },
    );

    testWidgets('when a quick action is working then its label shows', (
      tester,
    ) async {
      api
        ..holdChats = true
        ..quickScripts.add([]);
      await pumpWrite(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.action.proofread')),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Proofreading…'), findsOneWidget);
      await api.releaseChat();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'when a quick action fails with no_style then the follow-up shows',
      (tester) async {
        api.quickScripts.add([
          AssistantEvent(
            type: AssistantEventType.error,
            error: 'This document has no style guide yet.',
            errorCode: 'no_style',
          ),
          AssistantEvent(type: AssistantEventType.done),
        ]);
        await pumpWrite(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('assistant.action.proofread')),
        );
        await tester.pumpAndSettle();
        expect(find.text('This document has no style guide yet.'), findsOne);
        expect(find.byKey(const ValueKey('chooseStyle')), findsOneWidget);
      },
    );

    testWidgets('when a run made many changes then the chips collapse', (
      tester,
    ) async {
      api.quickScripts.add([
        for (var i = 0; i < 9; i++) ...[
          AssistantEvent(
            type: AssistantEventType.toolStarted,
            toolUseId: 't$i',
            toolName: 'write.replace_text',
            toolSummary: 'Change $i',
          ),
          AssistantEvent(
            type: AssistantEventType.toolFinished,
            toolUseId: 't$i',
            toolName: 'write.replace_text',
            toolSummary: 'Change $i',
            changeId: 'c$i',
          ),
        ],
        AssistantEvent(type: AssistantEventType.done),
      ]);
      await pumpWrite(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('assistant.action.proofread')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Change 3'), findsOneWidget);
      expect(find.text('Change 4'), findsNothing);
      await tester.tap(find.text('+5 more'));
      await tester.pumpAndSettle();
      expect(find.text('Change 8'), findsOneWidget);
    });

    testWidgets('when the ⋮ menu opens then the app items are there', (
      tester,
    ) async {
      await pumpWrite(tester);
      await tester.tap(find.byKey(const ValueKey<String>('assistant.more')));
      await tester.pumpAndSettle();
      expect(find.text('Style guides…'), findsOneWidget);
    });
  });

  group('Given Markdown blocks', () {
    test('when parsed then headings, lists, code and tables are found', () {
      final blocks = MarkdownBlocks.parse(
        '# Title\n\nText **bold**\n\n- a\n  - b\n1. one\n\n```dart\nx\n```\n'
        '| A | B |\n|---|---|\n| 1 | 2 |\n',
      );
      expect(blocks.map((b) => b.kind), [
        MdKind.heading,
        MdKind.paragraph,
        MdKind.listItem,
        MdKind.listItem,
        MdKind.listItem,
        MdKind.code,
        MdKind.table,
      ]);
      expect(blocks[3].level, 1);
      expect(blocks[4].marker, '1.');
    });
  });
}
