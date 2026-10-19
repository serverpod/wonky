@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_config.dart';
import 'package:wonky_server/src/platform/ai/ai_keys.dart';
import 'package:wonky_server/src/platform/ai/llm/fake_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

const _key = 'sk-test-0123456789-personal-wxyz';

void main() {
  late FakeAiModelClient fake;

  setUp(() {
    fake = FakeAiModelClient(provider: AiProvider.openai);
    AiConfig.current = AiConfig();
    AiConfig.clientOverride = fake;
  });
  tearDown(() => AiConfig.clientOverride = null);

  withWonkyServerpod('Given a server without AI keys', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });

    test(
      'when a user adds a key then AI is available with their provider and '
      'the key is never returned',
      () async {
        final status = await endpoints.assistant.setProviderKey(
          anna.endpointSession,
          AiProvider.openai,
          _key,
        );

        expect(status.available, isTrue);
        expect(status.provider, AiProvider.openai);
        expect(status.keySource, 'user');
        expect(status.userKey?.provider, AiProvider.openai);
        expect(status.userKey?.last4, 'wxyz');
        final again = await endpoints.assistant.getStatus(anna.endpointSession);
        expect(jsonEncode(again.toJson()), isNot(contains(_key)));
        expect(jsonEncode(status.toJson()), isNot(contains(_key)));
      },
    );

    test(
      "when a user adds a key then their requests use it and the provider's "
      'models',
      () async {
        await endpoints.assistant.setProviderKey(
          anna.endpointSession,
          AiProvider.openai,
          _key,
        );
        fake.enqueue((AiScript()..text('Hi')).response);
        final doc = await TestDrive.document(endpoints, anna, markdown: 'Hi\n');

        await endpoints.assistant
            .chat(
              anna.endpointSession,
              null,
              doc.uuid,
              'Hello',
              AssistantContextHints(
                applyMode: AiApplyMode.edit,
                includeComments: false,
              ),
            )
            .toList();

        final c = await AiKeys.forUser(anna.session, anna.id);
        expect(c?.apiKey, _key);
        expect(c?.source, AiKeySource.user);
        expect(fake.requests.single.model, 'gpt-5');
      },
    );

    test("when another user asks then they don't get the key", () async {
      await endpoints.assistant.setProviderKey(
        anna.endpointSession,
        AiProvider.gemini,
        _key,
      );
      final bob = await TestUsers.create(sessionBuilder, name: 'Bob');

      final status = await endpoints.assistant.getStatus(bob.endpointSession);

      expect(status.available, isFalse);
      expect(status.reason, 'notConfigured');
      expect(status.userKey, isNull);
      expect(await AiKeys.forUser(bob.session, bob.id), isNull);
    });

    test('when the key is removed then AI is not configured again', () async {
      await endpoints.assistant.setProviderKey(
        anna.endpointSession,
        AiProvider.anthropic,
        _key,
      );

      final status = await endpoints.assistant.removeProviderKey(
        anna.endpointSession,
      );

      expect(status.reason, 'notConfigured');
      expect(status.userKey, isNull);
      expect(await AiKeys.userKey(anna.session, anna.id), isNull);
    });

    test('when a key is replaced then the newest one is used', () async {
      await endpoints.assistant.setProviderKey(
        anna.endpointSession,
        AiProvider.anthropic,
        _key,
      );

      final status = await endpoints.assistant.setProviderKey(
        anna.endpointSession,
        AiProvider.gemini,
        'AIza-0123456789-other-key-1234',
      );

      expect(status.provider, AiProvider.gemini);
      expect(status.userKey?.last4, '1234');
    });

    test('when the key is malformed then it is refused', () async {
      await expectLater(
        endpoints.assistant.setProviderKey(
          anna.endpointSession,
          AiProvider.openai,
          'short',
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.invalidArgument,
          ),
        ),
      );
    });
  });

  withWonkyServerpod('Given a server with its own key', (
    sessionBuilder,
    endpoints,
  ) {
    setUp(() {
      AiConfig.current = AiConfig(serverKeys: {AiProvider.anthropic: 'k'});
    });

    test('when a user tries to add a key then it is refused', () async {
      final u = await TestUsers.create(sessionBuilder);

      await expectLater(
        endpoints.assistant.setProviderKey(
          u.endpointSession,
          AiProvider.openai,
          _key,
        ),
        throwsA(isA<WonkyException>()),
      );
      final status = await endpoints.assistant.getStatus(u.endpointSession);
      expect(status.keySource, 'server');
      expect(status.provider, AiProvider.anthropic);
      expect(status.userKeysAllowed, isFalse);
    });
  });
}
