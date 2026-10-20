import 'dart:convert';

import 'package:serverpod/serverpod.dart' show UuidValue;

import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/publications/publication_common.dart';
import 'package:wonky_server/src/platform/publications/publication_http.dart';
import 'package:wonky_server/src/platform/publications/publication_keys.dart';
import 'package:wonky_server/src/platform/publications/publication_rules.dart';
import 'package:wonky_server/src/platform/publications/publication_webhooks.dart';

import '../test_users.dart';
import '../wonky_serverpod.dart';

/// One webhook the fake blog received.
class ReceivedWebhook {
  ReceivedWebhook(this.url, this.headers, this.body);

  final String url;
  final Map<String, String> headers;
  final String body;

  Map<String, Object?> get json =>
      (jsonDecode(body) as Map).cast<String, Object?>();

  String get type => json['type'] as String;
}

/// The blog's server: records webhooks and answers with [status]; answers
/// GETs from [pages] (404 otherwise). Never touches the network.
class FakeBlog implements PublicationHttp {
  final received = <ReceivedWebhook>[];
  final pages = <String, String>{};
  int status = 200;

  List<ReceivedWebhook> ofType(String type) => [
    for (final r in received)
      if (r.type == type) r,
  ];

  @override
  Future<PublicationHttpResult> post(
    String url, {
    required Map<String, String> headers,
    required String body,
  }) async {
    received.add(ReceivedWebhook(url, headers, body));
    return PublicationHttpResult(status);
  }

  @override
  Future<PublicationHttpResult> get(String url) async {
    final page = pages[url];
    return page == null
        ? const PublicationHttpResult(404)
        : PublicationHttpResult(200, body: page);
  }
}

/// Installs a [FakeBlog] and records scheduled deliveries instead of
/// running future calls (specs/15 §6).
class PublicationHarness {
  final blog = FakeBlog();
  final scheduled = <int>[];

  void install() {
    blog
      ..received.clear()
      ..pages.clear()
      ..status = 200;
    scheduled.clear();
    PublicationHttp.override = blog;
    PublicationWebhooks.scheduler = (session, id) async => scheduled.add(id);
    Publications.startLimiter.reset();
    Publications.submitLimiter.reset();
    Publications.apiLimiter.reset();
  }

  void uninstall() {
    PublicationHttp.override = null;
    PublicationWebhooks.scheduler = (session, id) async {};
  }

  /// Sends every scheduled delivery now.
  Future<void> deliverScheduled(TestSessionBuilder sessionBuilder) async {
    final ids = [...scheduled];
    scheduled.clear();
    for (final id in ids) {
      await PublicationWebhooks.attempt(sessionBuilder.build(), id);
    }
  }

  static PublicationInput input({
    String name = 'Serverpod blog',
    String siteUrl = 'https://blog.example.com',
    String webhookUrl = 'https://blog.example.com/api/wonky',
    String? termsUrl,
    UuidValue? templateItemUuid,
    PublicationFields? fields,
    bool enabled = true,
  }) => PublicationInput(
    name: name,
    siteUrl: siteUrl,
    webhookUrl: webhookUrl,
    termsUrl: termsUrl,
    templateItemUuid: templateItemUuid,
    fields: fields ?? PublicationRules.defaultFields(),
    enabled: enabled,
  );

  /// A publication of [owner] with an API key and [moderators].
  Future<TestPublication> create(
    TestEndpoints endpoints,
    TestUser owner, {
    List<TestUser> moderators = const [],
    PublicationInput? input,
  }) async {
    final created = await endpoints.publication.create(
      owner.endpointSession,
      input ?? PublicationHarness.input(),
    );
    final key = await endpoints.publication.createApiKey(
      owner.endpointSession,
      created.settings.publicId,
    );
    if (moderators.isNotEmpty) {
      await endpoints.publication.setModerators(
        owner.endpointSession,
        created.settings.publicId,
        [for (final m in moderators) m.email],
      );
    }
    blog.received.clear();
    scheduled.clear();
    return TestPublication(
      created.settings.publicId,
      created.secret,
      key.secret,
    );
  }

  /// A story of [author] for [p], started and agreed to.
  Future<UuidValue> start(
    TestEndpoints endpoints,
    TestUser author,
    TestPublication p, {
    String? ref,
  }) async => (await endpoints.publication.startSubmission(
    author.endpointSession,
    p.publicId,
    ref,
    true,
  )).itemUuid;

  static SubmissionValues values({String title = 'My story'}) =>
      SubmissionValues(title: title, tags: ['dart']);
}

class TestPublication {
  TestPublication(this.publicId, this.signingSecret, this.apiKey);

  final String publicId;
  final String signingSecret;
  final String apiKey;

  /// Whether [hook] carries a valid signature of this publication.
  bool signed(ReceivedWebhook hook) {
    final expected = PublicationKeys.sign(
      secret: signingSecret,
      webhookId: hook.headers['webhook-id']!,
      timestamp: int.parse(hook.headers['webhook-timestamp']!),
      body: hook.body,
    );
    return hook.headers['webhook-signature']!.split(' ').contains(expected);
  }
}
