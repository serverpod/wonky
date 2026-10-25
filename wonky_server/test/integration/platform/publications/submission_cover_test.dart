@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/publications/publication_rules.dart';
import 'package:wonky_server/src/web/routes/publication_api_route.dart';

import '../../../support/publications/publication_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_files.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// A 1×1 PNG.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  ),
);

/// The cover image uploaded in the submit dialog (specs/18 §4.2, T-19): an
/// image file of the document that is not in its text.
void main() {
  withWonkyServerpod('Given a publication that requires a cover image', (
    sessionBuilder,
    endpoints,
  ) {
    final h = PublicationHarness();
    final client = HttpClient();
    late Uri base;
    late TestUser owner;
    late TestUser anna;
    late TestPublication pub;
    late UuidValue doc;

    setUpAll(() async {
      final pod = sessionBuilder.build().serverpod;
      pod.webServer.addRoute(PublicationApiRoute(pod: pod), '/api/pub/v1/**');
      if (!pod.webServer.running) await pod.webServer.start();
      base = Uri.parse('http://localhost:${pod.webServer.port}/api/pub/v1/');
    });
    tearDownAll(() => client.close(force: true));

    setUp(() async {
      h.install();
      owner = await TestUsers.create(sessionBuilder, name: 'Owner');
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      pub = await h.create(
        endpoints,
        owner,
        input: PublicationHarness.input(
          fields: PublicationRules.defaultFields().copyWith(
            coverImage: PublicationFieldMode.required,
          ),
        ),
      );
      doc = await h.start(endpoints, anna, pub);
    });
    tearDown(h.uninstall);

    /// The last [uploadImage]'s ready file (a WebP, specs/12 §1.1).
    late FileUrlView uploaded;

    /// Uploads [_png] as an image of [itemUuid], like the submit dialog.
    Future<UuidValue> uploadImage(UuidValue itemUuid) async {
      final fileUuid = const Uuid().v7obj();
      await endpoints.file.createUpload(
        anna.endpointSession,
        fileUuid,
        itemUuid,
        'cover.png',
        'image/png',
        _png.length,
        imageProfile: ImageProfile.cover,
      );
      await TestFiles.putBytes(sessionBuilder.build(), fileUuid, _png);
      uploaded = await endpoints.file.completeUpload(
        anna.endpointSession,
        fileUuid,
      );
      return fileUuid;
    }

    Future<SubmissionView> submit(UuidValue? cover) =>
        endpoints.submission.submit(
          anna.endpointSession,
          doc,
          PublicationHarness.values(
            title: 'Faster CI',
          ).copyWith(coverImage: cover),
          false,
        );

    test('when submitting with an uploaded cover then the webhook names it '
        'and lists it as an asset, and the API serves its bytes', () async {
      final cover = await uploadImage(doc);

      final view = await submit(cover);

      final json = h.blog.ofType('submission.submitted').single.json;
      final assetId = 'ast_${cover.uuid}';
      expect(view.values.coverImage, cover);
      expect((json['fields']! as Map)['coverImage'], assetId);
      final assets = (json['assets']! as List).cast<Map<String, Object?>>();
      expect(assets.single['id'], assetId);
      expect(assets.single['name'], 'cover.webp');
      expect(assets.single['type'], 'image/webp');
      expect(assets.single['bytes'], uploaded.sizeBytes);
      // Not in the text: blogs that show the cover don't show it twice.
      expect(json['markdown'], isNot(contains(assetId)));

      final req = await client.getUrl(base.resolve('assets/$assetId'));
      req.headers.set('authorization', 'Bearer ${pub.apiKey}');
      final res = await req.close();
      final bytes = await res.fold<List<int>>([], (a, b) => a..addAll(b));
      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'image/webp');
      expect(bytes, hasLength(uploaded.sizeBytes));
    });

    test('when submitting without a cover then it is refused', () async {
      await expectLater(submit(null), throwsA(isA<WonkyException>()));
      expect(h.blog.received, isEmpty);
    });

    test('when the cover is an image of another document then it is '
        'refused', () async {
      final other = await TestDrive.document(endpoints, anna, name: 'Other');
      final cover = await uploadImage(other.uuid);

      await expectLater(submit(cover), throwsA(isA<WonkyException>()));
      expect(h.blog.received, isEmpty);
    });

    test('when submitting again with a new cover then the new one is sent '
        'and stored', () async {
      await submit(await uploadImage(doc));
      final second = await uploadImage(doc);
      h.blog.received.clear();

      final view = await submit(second);

      final json = h.blog.ofType('submission.submitted').single.json;
      expect(view.values.coverImage, second);
      expect((json['fields']! as Map)['coverImage'], 'ast_${second.uuid}');
      expect(json['sequence'], 2);
    });
  });
}
