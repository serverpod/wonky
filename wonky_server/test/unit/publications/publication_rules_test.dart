import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/publications/publication_rules.dart';

void main() {
  group('Given the status transitions of the blog', () {
    const s = SubmissionStatus.values;
    final allowed = <(SubmissionStatus, SubmissionStatus)>{
      for (final from in [
        SubmissionStatus.inReview,
        SubmissionStatus.changesRequested,
      ])
        for (final to in [
          SubmissionStatus.inReview,
          SubmissionStatus.changesRequested,
          SubmissionStatus.declined,
          SubmissionStatus.published,
        ])
          (from, to),
      (SubmissionStatus.published, SubmissionStatus.published),
    };
    for (final from in s) {
      for (final to in s) {
        final ok = allowed.contains((from, to));
        test('when moving from ${from.name} to ${to.name} then it is '
            '${ok ? 'allowed' : 'refused'}', () {
          expect(PublicationRules.blogMayMove(from, to), ok);
        });
      }
    }
  });

  group('Given URLs of a publication', () {
    final cases = <(String, bool)>[
      ('https://blog.example.com', true),
      ('https://blog.example.com/', true),
      ('http://blog.example.com', false),
      ('https://blog.example.com:8443', false),
      ('https://user:pw@blog.example.com', false),
      ('https://blog.example.com/path', false),
      ('ftp://blog.example.com', false),
    ];
    for (final (url, ok) in cases) {
      test('when "$url" is the site URL then it is '
          '${ok ? 'accepted' : 'refused'}', () {
        expect(
          () => PublicationRules.httpsUrl(url, 'site URL', originOnly: true),
          ok ? returnsNormally : throwsA(isA<WonkyException>()),
        );
      });
    }

    test('when a webhook URL has a path then it is accepted', () {
      expect(
        PublicationRules.httpsUrl(
          'https://blog.example.com/api/wonky?x=1',
          'webhook URL',
        ).path,
        '/api/wonky',
      );
    });
  });

  group('Given the fields of a publication with required tags from a list', () {
    final fields = PublicationRules.defaultFields().copyWith(
      tags: PublicationFieldMode.required,
      allowedTags: ['Dart', 'Flutter'],
      summary: PublicationFieldMode.off,
    );

    test('when the values have duplicate tags in other cases then they are '
        'kept once and the summary is dropped', () {
      final v = PublicationRules.values(
        SubmissionValues(
          title: '  Title ',
          summary: 'dropped',
          tags: ['dart', 'Dart', ' flutter '],
        ),
        fields,
      );

      expect(v.title, 'Title');
      expect(v.summary, isNull);
      expect(v.tags, ['dart', 'flutter']);
    });

    test('when a tag is not in the list then it is refused', () {
      expect(
        () => PublicationRules.values(
          SubmissionValues(title: 'T', tags: ['go']),
          fields,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when there are no tags then it is refused', () {
      expect(
        () => PublicationRules.values(
          SubmissionValues(title: 'T', tags: []),
          fields,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when the title is empty then it is refused', () {
      expect(
        () => PublicationRules.values(
          SubmissionValues(title: ' ', tags: ['Dart']),
          fields,
        ),
        throwsA(isA<WonkyException>()),
      );
    });
  });
}
