@Tags(['integration'])
library;

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_config.dart';
import 'package:wonky_server/src/platform/ai/ai_keys.dart';
import 'package:wonky_server/src/platform/ai/ai_models.dart';
import 'package:wonky_server/src/platform/ai/llm/fake_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/organizations/organization_config.dart';
import 'package:wonky_server/src/platform/organizations/organization_service.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

const _shared = 'sk-test-0123456789-shared-ORGK';
const _own = 'sk-test-0123456789-personal-wxyz';
const _other = 'AIza-test-0123456789-other-OTHK';

var _counter = 0;
String _freshDomain() =>
    'acme${clock.now().microsecondsSinceEpoch}k${_counter++}.dev';

/// The organization's shared AI key (suite 10 §1 "Keys").
void main() {
  late FakeAiModelClient fake;

  setUp(() {
    AiConfig.current = AiConfig();
    fake = FakeAiModelClient(provider: AiProvider.openai);
    AiConfig.clientOverride = fake;
    OrganizationConfig.reset();
    OrganizationService.forget();
  });
  tearDown(() {
    AiConfig.clientOverride = null;
    OrganizationConfig.reset();
  });

  withWonkyServerpod('Given a server without AI keys and an organization', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late TestUser outsider;
    late TestUser gmail;
    late String domain;

    setUp(() async {
      domain = _freshDomain();
      anna = await TestUsers.create(
        sessionBuilder,
        name: 'Anna Berg',
        email: 'anna@$domain',
      );
      bo = await TestUsers.create(
        sessionBuilder,
        name: 'Bo Chen',
        email: 'bo@$domain',
      );
      outsider = await TestUsers.create(
        sessionBuilder,
        name: 'Olle Out',
        email: 'olle@${_freshDomain()}',
      );
      gmail = await TestUsers.create(
        sessionBuilder,
        name: 'Gus Mail',
        email: 'gus.${clock.now().microsecondsSinceEpoch}@gmail.com',
      );
    });

    test('when a member adds a shared key then every member can use AI with '
        'it, and nobody sees the key', () async {
      final before = await endpoints.assistant.getStatus(bo.endpointSession);
      expect(before.available, isFalse);
      expect(before.organization, domain);

      final status = await endpoints.assistant.setOrganizationProviderKey(
        anna.endpointSession,
        AiProvider.anthropic,
        _shared,
      );
      expect(status.keySource, 'organization');
      expect(status.orgKey?.last4, 'ORGK');
      expect(status.orgKey?.addedBy, 'Anna Berg');

      final forBo = await endpoints.assistant.getStatus(bo.endpointSession);
      expect(forBo.available, isTrue);
      expect(forBo.provider, AiProvider.anthropic);
      expect(forBo.keySource, 'organization');
      expect(forBo.orgKey?.provider, AiProvider.anthropic);
      for (final s in [status, forBo]) {
        expect(jsonEncode(s.toJson()), isNot(contains(_shared)));
      }
      final c = await AiKeys.forUser(sessionBuilder.build(), bo.id);
      expect(c?.apiKey, _shared);
    });

    test('when a member has a key of their own then it wins over the '
        "organization's", () async {
      await endpoints.assistant.setOrganizationProviderKey(
        anna.endpointSession,
        AiProvider.anthropic,
        _shared,
      );
      final status = await endpoints.assistant.setProviderKey(
        bo.endpointSession,
        AiProvider.openai,
        _own,
      );

      expect(status.keySource, 'user');
      expect(status.provider, AiProvider.openai);
      expect(status.orgKey?.last4, 'ORGK');
    });

    test('when someone outside the organization or with a public mail '
        'address asks then the shared key is not theirs', () async {
      await endpoints.assistant.setOrganizationProviderKey(
        anna.endpointSession,
        AiProvider.anthropic,
        _shared,
      );

      for (final u in [outsider, gmail]) {
        final s = await endpoints.assistant.getStatus(u.endpointSession);
        expect(s.available, isFalse, reason: u.name);
        expect(s.orgKey, isNull, reason: u.name);
      }
      expect(
        (await endpoints.assistant.getStatus(
          gmail.endpointSession,
        )).organization,
        isNull,
      );
      await expectLater(
        endpoints.assistant.setOrganizationProviderKey(
          gmail.endpointSession,
          AiProvider.openai,
          _shared,
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

    test('when another member replaces or removes the shared key then it '
        'changes for everyone', () async {
      await endpoints.assistant.setOrganizationProviderKey(
        anna.endpointSession,
        AiProvider.anthropic,
        _shared,
      );
      final replaced = await endpoints.assistant.setOrganizationProviderKey(
        bo.endpointSession,
        AiProvider.gemini,
        'AIza-test-0123456789-gem-GEMK',
      );
      expect(replaced.orgKey?.provider, AiProvider.gemini);
      expect(replaced.orgKey?.addedBy, 'Bo Chen');
      expect(
        (await endpoints.assistant.getStatus(
          anna.endpointSession,
        )).orgKey?.last4,
        'GEMK',
      );

      final removed = await endpoints.assistant.removeOrganizationProviderKey(
        anna.endpointSession,
      );
      expect(removed.orgKey, isNull);
      expect(
        (await endpoints.assistant.getStatus(bo.endpointSession)).available,
        isFalse,
      );
    });

    test('when the server has a key of its own then no shared key can be '
        'added', () async {
      AiConfig.current = AiConfig(
        serverKeys: {AiProvider.anthropic: 'server-test-key-0123456789'},
      );

      await expectLater(
        endpoints.assistant.setOrganizationProviderKey(
          anna.endpointSession,
          AiProvider.openai,
          _shared,
        ),
        throwsA(isA<WonkyException>()),
      );
      final s = await endpoints.assistant.getStatus(anna.endpointSession);
      expect(s.keySource, 'server');
      expect(s.organization, isNull);
    });
  });

  withWonkyServerpod('Given a document shared by a member of an organization '
      'with a shared key', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestUser bo;
    late TestUser outsider;
    late TestUser gmail;
    late DriveItemView doc;

    /// The provider whose model served the last request.
    AiProvider lastProvider() {
      final model = fake.requests.last.model;
      return AiProvider.values.firstWhere((p) {
        final (large, small) = AiModels.defaults(p);
        return model == large || model == small;
      });
    }

    Future<List<InlineAiEvent>> improve(TestUser u) => endpoints.assistant
        .inline(
          u.endpointSession,
          InlineAiRequest(
            itemUuid: doc.uuid,
            action: 'improve',
            selectedMarkdown: 'We should ship it.',
          ),
        )
        .toList();

    setUp(() async {
      final domain = _freshDomain();
      anna = await TestUsers.create(
        sessionBuilder,
        name: 'Anna Berg',
        email: 'anna@$domain',
      );
      bo = await TestUsers.create(
        sessionBuilder,
        name: 'Bo Chen',
        email: 'bo@$domain',
      );
      outsider = await TestUsers.create(
        sessionBuilder,
        name: 'Olle Out',
        email: 'olle@${_freshDomain()}',
      );
      gmail = await TestUsers.create(
        sessionBuilder,
        name: 'Gus Mail',
        email: 'gus.${clock.now().microsecondsSinceEpoch}@gmail.com',
      );
      await endpoints.assistant.setOrganizationProviderKey(
        anna.endpointSession,
        AiProvider.anthropic,
        _shared,
      );
      doc = await TestDrive.document(
        endpoints,
        anna,
        markdown: '# Plan\n\nWe should ship it.\n',
      );
      for (final u in [bo, outsider, gmail]) {
        await TestDrive.share(endpoints, doc, anna, u, AccessRole.editor);
      }
    });

    test('when a colleague who can edit uses AI on it then the assistant is '
        "available to them and their organization's key serves it", () async {
      final status = await endpoints.assistant.getStatus(bo.endpointSession);
      expect(status.available, isTrue);
      expect(status.keySource, 'organization');

      fake.enqueue((AiScript()..text('Let us ship it.')).response);
      final events = await improve(bo);

      expect(events.last.type, InlineAiEventType.done);
      expect(lastProvider(), AiProvider.anthropic);
      final c = await AiKeys.forUser(sessionBuilder.build(), bo.id);
      expect(c?.apiKey, _shared);
      expect(c?.source, AiKeySource.organization);
    });

    test('when an editor from another organization uses AI on it then their '
        "own organization's key serves it, not the owner's", () async {
      await endpoints.assistant.setOrganizationProviderKey(
        outsider.endpointSession,
        AiProvider.gemini,
        _other,
      );

      fake.enqueue((AiScript()..text('Let us ship it.')).response);
      final events = await improve(outsider);

      expect(events.last.type, InlineAiEventType.done);
      expect(lastProvider(), AiProvider.gemini);
      final c = await AiKeys.forUser(sessionBuilder.build(), outsider.id);
      expect(c?.apiKey, _other);
    });

    test('when an editor without an organization or key uses AI on it then '
        "it is unavailable to them: the owner's key does not pay", () async {
      final status = await endpoints.assistant.getStatus(
        gmail.endpointSession,
      );
      expect(status.available, isFalse);

      await expectLater(
        improve(gmail),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.unavailable,
          ),
        ),
      );
      expect(fake.requests, isEmpty);
    });
  });
}
