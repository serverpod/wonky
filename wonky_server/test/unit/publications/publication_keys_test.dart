import 'package:test/test.dart';
import 'package:wonky_server/src/platform/publications/publication_keys.dart';

void main() {
  group('Given the signing test vector of the blog integration guide', () {
    const secret = 'whsec_MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw';
    const id = 'msg_2KWPBgLlAfxdpx2AI54pPJ85f4W';
    const timestamp = 1674087231;
    const body =
        '{"type":"publication.ping","createdAt":"2023-01-19T00:13:51Z",'
        '"publicationId":"pub_7Hk2xQ9mR4tLwP0aZc3VbN"}';

    test('when signing it then the signature matches the guide', () {
      expect(
        PublicationKeys.sign(
          secret: secret,
          webhookId: id,
          timestamp: timestamp,
          body: body,
        ),
        'v1,4+meITVYE+3sv8v+3Jl0/CXDGdczBRF7SOHoZxKwobQ=',
      );
    });

    test('when signing with two secrets then the header has both, space '
        'separated', () {
      final header = PublicationKeys.signatureHeader(
        secrets: [secret, PublicationKeys.newSigningSecret()],
        webhookId: id,
        timestamp: timestamp,
        body: body,
      );

      expect(header.split(' '), hasLength(2));
      expect(
        header.split(' ').first,
        'v1,4+meITVYE+3sv8v+3Jl0/CXDGdczBRF7SOHoZxKwobQ=',
      );
    });
  });

  group('Given new ids and keys', () {
    test('when creating a public id then it matches the link pattern', () {
      expect(
        PublicationKeys.publicIdPattern.hasMatch(PublicationKeys.newPublicId()),
        isTrue,
      );
    });

    test('when creating an API key then it matches the key pattern and its '
        'hash is stable', () {
      final key = PublicationKeys.newApiKey();

      expect(PublicationKeys.apiKeyPattern.hasMatch(key), isTrue);
      expect(PublicationKeys.hashApiKey(key), PublicationKeys.hashApiKey(key));
      expect(PublicationKeys.hashApiKey(key), hasLength(64));
    });

    test('when creating a signing secret then it has the whsec_ prefix', () {
      expect(PublicationKeys.newSigningSecret(), startsWith('whsec_'));
    });
  });
}
