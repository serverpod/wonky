import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write/commands/screen_commands.dart';
import 'package:wonky_write/features/ai/ai_commands.dart';
import 'package:wonky_write/features/ai/ai_preview_overlay.dart' show wordDiff;
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

    test('when the editor is in Suggesting mode then the result becomes an AI '
        'suggestion', () async {
      doc.editor.mode = EditorMode.suggesting;
      await run('write.ai.rewriteSelection', {'mode': 'fixGrammar'});
      await pumpEventQueue();
      expect(ai.replace(), isTrue);
      await pumpEventQueue();
      final suggestions = SuggestionIndex.list(h.session.editor.delta);
      expect(suggestions, isNotEmpty);
      expect(
        h.session.editor.delta.toList().any(
          (op) =>
              op.attributes?.values.any((v) => v is Map && v['via'] == 'ai') ??
              false,
        ),
        isTrue,
      );
    });

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

  group('Given the quick actions', () {
    for (final (command, action) in [
      ('write.ai.summarizeDocument', AssistantQuickAction.summarize),
      ('write.ai.proofreadDocument', AssistantQuickAction.proofread),
      ('write.ai.addressComments', AssistantQuickAction.addressComments),
      ('write.ai.applyStyle', AssistantQuickAction.applyStyle),
    ]) {
      test('when $command runs then ${action.name} runs in the panel without a '
          'prompt, as suggestions', () async {
        final r = await run(command);
        await pumpEventQueue();

        expect(r.isOk, isTrue);
        expect(api.quickActions, [action]);
        expect(api.sent, isEmpty);
        expect(api.sentHints.single.applyMode, AiApplyMode.suggest);
        final entries = ai.chat!.entries;
        expect(entries.whereType<AssistantUserEntry>(), isEmpty);
        expect(
          entries.whereType<AssistantReplyEntry>().single.markdown,
          'Done.',
        );
      });
    }

    test('when the panel shows then it has the four actions and no mode '
        'toggle', () {
      final extras = ai.adapter as AssistantPanelExtras;
      expect(extras.alwaysSuggests, isTrue);
      expect(extras.quickActions.map((a) => a.id), [
        'summarize',
        'proofread',
        'addressComments',
        'applyStyle',
      ]);
      expect(ai.adapter.quickPrompts, isEmpty);
    });
  });

  test("the document's style guide is set as one undo step and undo restores "
      'it', () async {
    final r = await run('write.doc.setStyleGuide', {
      'ref': 'builtin:technical',
    });
    await pumpEventQueue();
    expect(r.isOk, isTrue);
    expect(api.documentRefs[h.session.itemUuid.uuid], 'builtin:technical');
    expect(h.undo.undoLabel.value, 'Change style guide');

    await h.undo.undo();
    await pumpEventQueue();
    expect(api.documentRefs[h.session.itemUuid.uuid], isNull);
    expect(api.styleCalls, ['document:builtin:technical', 'document:null']);
  });

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
