import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write/commands/screen_commands.dart';
import 'package:wonky_write/features/ai/ai_commands.dart';
import 'package:wonky_write/features/ai/ai_preview_overlay.dart' show wordDiff;
import 'package:wonky_write/features/ai/proofread_results.dart';
import 'package:wonky_write/features/ai/write_ai_controller.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/screen/write_document_controller.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDocumentServer server;
  late SessionHarness h;
  late WriteDocumentController doc;
  late FakeAssistantApi api;
  late WriteAiController ai;

  String text() => DeltaUtils.text(h.session.editor.delta);

  Future<CommandResult> run(
    String id, [
    Map<String, Object?> args = const {},
  ]) => h.services.dispatcher.invoke(
    id,
    args: args,
    source: InvocationSource.mcp,
  );

  setUp(() async {
    server = FakeDocumentServer(
      initial: Delta()..insert('Teh quick fox jumpd.\nSecond line.\n'),
    );
    h = SessionHarness(server);
    await h.open();
    final catalog = WriteThemeCatalog();
    h.services.registry.registerAll([
      ...writeCommands(h.services, catalog),
      ...writeAiCommands(h.services),
    ]);
    doc = WriteDocumentController(
      services: h.services,
      session: h.session,
      themes: catalog,
    );
    h.services.activate(doc);
    api = FakeAssistantApi();
    final assistant = ShellAssistant.install(h.services, api: api);
    await assistant.refreshStatus();
    ai = WriteAiController(services: h.services, session: h.session, doc: doc);
    await pumpEventQueue();
  });

  tearDown(() async {
    ai.dispose();
    ShellAssistant.uninstall(h.services);
    h.services.deactivate(doc);
    doc.dispose();
    await h.dispose();
  });

  group('Given a selection and an inline rewrite', () {
    setUp(() {
      api.inlineScripts.add([
        InlineAiEvent(type: InlineAiEventType.textDelta, text: 'The quick '),
        InlineAiEvent(type: InlineAiEventType.textDelta, text: 'fox jumped.'),
        InlineAiEvent(
          type: InlineAiEventType.done,
          markdown: 'The quick fox jumped.',
        ),
      ]);
      doc.editor.select(const DeltaSelection(0, 20));
    });

    test('when the preview is replaced then the text changes in one undo step '
        'labelled "AI: …"', () async {
      final r = await run('write.ai.rewriteSelection', {'mode': 'fixGrammar'});
      expect(r.isOk, isTrue);
      await pumpEventQueue();
      final req = api.inlineRequests.single;
      expect(req.action, 'fixGrammar');
      expect(req.selectedMarkdown, 'Teh quick fox jumpd.');
      expect(req.contextAfter, contains('Second line.'));
      expect(ai.preview?.canApply, isTrue);

      await run('write.ai.previewReplace');
      await pumpEventQueue();
      expect(text(), 'The quick fox jumped.\nSecond line.\n');
      expect(ai.preview, isNull);
      expect(h.undo.undoLabel.value, 'AI: Fix spelling & grammar');
      expect(DeltaUtils.text(server.document), text());

      await h.undo.undo();
      await pumpEventQueue();
      expect(text(), 'Teh quick fox jumpd.\nSecond line.\n');
    });

    test(
      'when Suggest mode is on then the result becomes an AI suggestion',
      () async {
        final chat = ai.chat!..setApplyMode(AiApplyMode.suggest);
        expect(chat.applyMode, AiApplyMode.suggest);
        await run('write.ai.rewriteSelection', {'mode': 'fixGrammar'});
        await pumpEventQueue();
        expect(ai.replace(), isTrue);
        await pumpEventQueue();
        final suggestions = SuggestionIndex.list(h.session.editor.delta);
        expect(suggestions, isNotEmpty);
        expect(
          h.session.editor.delta.toList().any(
            (op) =>
                op.attributes?.values.any(
                  (v) => v is Map && v['via'] == 'ai',
                ) ??
                false,
          ),
          isTrue,
        );
      },
    );

    test('when discarded then nothing changes', () async {
      await run('write.ai.rewriteSelection', {'mode': 'improve'});
      await pumpEventQueue();
      await run('write.ai.previewDiscard');
      expect(ai.preview, isNull);
      expect(text(), 'Teh quick fox jumpd.\nSecond line.\n');
    });

    test('when someone else changes the selected text then only Insert below '
        'remains', () async {
      await run('write.ai.rewriteSelection', {'mode': 'improve'});
      await pumpEventQueue();
      server.commitExternal(
        Delta()
          ..retain(4)
          ..delete(5)
          ..insert('slow'),
      );
      await pumpEventQueue();
      expect(ai.preview!.originalChanged, isTrue);
      expect(ai.replace(), isFalse);
      expect(ai.insert(below: true), isTrue);
      await pumpEventQueue();
      expect(text(), contains('The quick fox jumped.'));
      expect(text(), startsWith('Teh slow fox'));
    });

    test(
      'when text is inserted before the selection then the preview follows it',
      () async {
        await run('write.ai.rewriteSelection', {'mode': 'improve'});
        await pumpEventQueue();
        server.commitExternal(Delta()..insert('Intro.\n'));
        await pumpEventQueue();
        expect(ai.preview!.originalChanged, isFalse);
        expect(ai.preview!.start, 7);
        expect(ai.replace(), isTrue);
        await pumpEventQueue();
        expect(text(), 'Intro.\nThe quick fox jumped.\nSecond line.\n');
      },
    );

    test('when refining then the previous output is sent along', () async {
      await run('write.ai.rewriteSelection', {'mode': 'improve'});
      await pumpEventQueue();
      api.inlineScripts.add([
        InlineAiEvent(
          type: InlineAiEventType.done,
          markdown: 'A quick fox leapt.',
        ),
      ]);
      await ai.refine('more vivid');
      expect(api.inlineRequests.last.previousOutput, 'The quick fox jumped.');
      expect(ai.preview!.markdown, 'A quick fox leapt.');
    });
  });

  test('a refusal leaves nothing to insert', () async {
    api.inlineScripts.add([
      InlineAiEvent(
        type: InlineAiEventType.refusal,
        error: "The assistant can't help with that request.",
      ),
    ]);
    doc.editor.select(const DeltaSelection(0, 5));
    await ai.rewriteSelection('improve');
    expect(ai.preview!.status, AiPreviewStatus.refused);
    expect(ai.preview!.canApply, isFalse);
  });

  test('continue writing inserts the ghost text after the caret', () async {
    api.inlineScripts.add([
      InlineAiEvent(type: InlineAiEventType.done, markdown: 'It ran away.'),
    ]);
    doc.editor.select(const DeltaSelection.collapsed(20));
    await run('write.ai.continue');
    await pumpEventQueue();
    expect(ai.preview!.kind, AiPreviewKind.continuation);
    expect(ai.insert(), isTrue);
    await pumpEventQueue();
    expect(text(), 'Teh quick fox jumpd. It ran away.\nSecond line.\n');
    expect(h.undo.undoLabel.value, 'AI: Continue writing');
  });

  test(
    'Mod+J opens the prompt only in an empty paragraph or a selection',
    () async {
      doc.editor.select(const DeltaSelection.collapsed(3));
      expect(h.services.dispatcher.stateOf('write.ai.inline').enabled, isFalse);
      doc.editor.select(const DeltaSelection(0, 3));
      expect(h.services.dispatcher.stateOf('write.ai.inline').enabled, isTrue);
    },
  );

  test('the prompt generates content at an empty caret', () async {
    h.session.editor.applyLocal(
      Delta()
        ..retain(34)
        ..insert('\n'),
      label: 'Typing',
      source: LocalChangeSource.input,
    );
    await pumpEventQueue();
    doc.editor.select(const DeltaSelection.collapsed(34));
    expect(ai.caretInEmptyParagraph, isTrue);
    api.inlineScripts.add([
      InlineAiEvent(type: InlineAiEventType.done, markdown: 'A new idea.'),
    ]);
    ai.openPrompt();
    await ai.submitPrompt('Write one sentence about ideas');
    expect(ai.preview!.kind, AiPreviewKind.generate);
    expect(ai.insert(), isTrue);
    await pumpEventQueue();
    expect(text(), contains('A new idea.'));
  });

  test(
    'proofread issues are accepted by quote; stale ones are greyed',
    () async {
      api.proofreadScripts.add([
        ProofreadEvent(
          type: 'issues',
          issues: [
            ProofreadIssue(
              id: 'a',
              quote: 'Teh',
              occurrence: 1,
              replacement: 'The',
              category: 'spelling',
              explanation: 'Typo',
              start: 0,
              length: 3,
            ),
            ProofreadIssue(
              id: 'b',
              quote: 'jumpd',
              occurrence: 1,
              replacement: 'jumped',
              category: 'spelling',
              explanation: 'Typo',
              start: 14,
              length: 5,
            ),
            ProofreadIssue(
              id: 'c',
              quote: 'Second',
              occurrence: 1,
              replacement: '2nd',
              category: 'style',
              explanation: 'Shorter',
              start: 21,
              length: 6,
            ),
          ],
          sectionsDone: 1,
          sectionsTotal: 1,
        ),
        ProofreadEvent(type: 'done'),
      ]);
      await ai.proofread();
      final results = ai.proofreadResults!;
      expect(results.issues, hasLength(3));

      await run('write.ai.acceptIssue', {'issueId': 'a'});
      await pumpEventQueue();
      expect(text(), startsWith('The quick'));
      expect(h.undo.undoLabel.value, 'AI: Fix “Teh”');

      server.commitExternal(
        Delta()
          ..retain(21)
          ..delete(6)
          ..insert('Other'),
      );
      await pumpEventQueue();
      await run('write.ai.acceptAllIssues');
      await pumpEventQueue();
      expect(text(), 'The quick fox jumped.\nOther line.\n');
      expect(
        results.issues.firstWhere((i) => i.issue.id == 'c').status,
        ProofreadIssueStatus.stale,
      );
    },
  );

  test('the word diff marks removed and added words', () {
    final d = wordDiff('Teh quick fox', 'The quick fox');
    expect(d.first, (-1, 'Teh'));
    expect(d[1], (1, 'The'));
    expect(d.last, (0, ' quick fox'));
  });

  test('an outline converts to a bullet list', () {
    expect(
      WriteAiController.outlineAsList('# A\n## B\n### C'),
      '- A\n  - B\n    - C',
    );
  });
}
