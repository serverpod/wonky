import '../common/errors.dart';
import '../common/models.dart';

/// Pure rules of publications and submissions (specs/18): limits, URL and
/// field validation, and the status transitions the blog may make.
abstract final class PublicationRules {
  static const maxPublicationsPerOwner = 10;
  static const maxModerators = 20;
  static const maxNameLength = 60;
  static const maxUrlLength = 2000;
  static const maxFieldLength = 2000;
  static const maxTitleLength = 300;
  static const maxTags = 20;
  static const maxTagLength = 40;
  static const maxMessageLength = 10000;
  static const maxRefLength = 64;
  static const maxMarkdownBytes = 5 * 1024 * 1024;

  /// Per user and publication per day (specs/18 §10).
  static const startsPerDay = 10;
  static const submitsPerDay = 20;

  /// Publication API calls per key and minute (specs/18 §7.3).
  static const apiCallsPerMinute = 120;

  static final refPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Parses an `https` URL; [originOnly] refuses a path, query or fragment.
  static Uri httpsUrl(String raw, String what, {bool originOnly = false}) {
    final value = raw.trim();
    if (value.isEmpty || value.length > maxUrlLength) {
      throw Errors.invalid('Enter the $what.');
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw Errors.invalid('The $what must be an https:// address.');
    }
    if (uri.hasPort && uri.port != 443) {
      throw Errors.invalid('The $what must use the standard https port.');
    }
    if (originOnly &&
        ((uri.path.isNotEmpty && uri.path != '/') || uri.hasQuery)) {
      throw Errors.invalid(
        'The $what must be the site address only, like https://blog.example.com.',
      );
    }
    return uri;
  }

  /// `https://host` of a site URL.
  static String origin(Uri uri) => 'https://${uri.host.toLowerCase()}';

  static String hostOf(String url) => Uri.parse(url).host.toLowerCase();

  /// The publication's status calls (specs/18 §2.1, §7.3): which status the
  /// blog may set from [from].
  static bool blogMayMove(SubmissionStatus from, SubmissionStatus to) =>
      switch (to) {
        SubmissionStatus.inReview ||
        SubmissionStatus.changesRequested ||
        SubmissionStatus.declined => const {
          SubmissionStatus.inReview,
          SubmissionStatus.changesRequested,
        }.contains(from),
        SubmissionStatus.published => const {
          SubmissionStatus.inReview,
          SubmissionStatus.changesRequested,
          SubmissionStatus.published,
        }.contains(from),
        SubmissionStatus.draft || SubmissionStatus.withdrawn => false,
      };

  /// Whether an editor may submit in [status].
  static bool maySubmit(SubmissionStatus status) => switch (status) {
    SubmissionStatus.draft ||
    SubmissionStatus.inReview ||
    SubmissionStatus.changesRequested ||
    SubmissionStatus.published ||
    SubmissionStatus.withdrawn => true,
    SubmissionStatus.declined => false,
  };

  /// Whether moderators hold Commenter in [status] (specs/18 §5.1).
  static bool moderatorsHaveAccess(SubmissionStatus status) => switch (status) {
    SubmissionStatus.inReview ||
    SubmissionStatus.changesRequested ||
    SubmissionStatus.published => true,
    SubmissionStatus.draft ||
    SubmissionStatus.declined ||
    SubmissionStatus.withdrawn => false,
  };

  /// Open = the blog is reviewing it or waits for the author.
  static bool isOpen(SubmissionStatus status) =>
      status == SubmissionStatus.inReview ||
      status == SubmissionStatus.changesRequested;

  /// Checks and normalizes the fields of a submit against [fields].
  static SubmissionValues values(
    SubmissionValues v,
    PublicationFields fields,
  ) {
    String? text(String? s, PublicationFieldMode mode, String label) {
      final t = s?.trim();
      if (mode == PublicationFieldMode.off) return null;
      if (t == null || t.isEmpty) {
        if (mode == PublicationFieldMode.required) {
          throw Errors.invalid('Enter the $label.');
        }
        return null;
      }
      if (t.length > maxFieldLength) {
        throw Errors.invalid('The $label is too long.');
      }
      return t;
    }

    final title = v.title.trim();
    if (title.isEmpty) throw Errors.invalid('Enter a title.');
    if (title.length > maxTitleLength) {
      throw Errors.invalid('The title is too long.');
    }
    var tags = <String>[];
    if (fields.tags != PublicationFieldMode.off) {
      final allowed = {for (final t in fields.allowedTags) t.toLowerCase()};
      final seen = <String>{};
      for (final raw in v.tags) {
        final t = raw.trim();
        if (t.isEmpty || !seen.add(t.toLowerCase())) continue;
        if (t.length > maxTagLength) {
          throw Errors.invalid('The tag "$t" is too long.');
        }
        if (allowed.isNotEmpty && !allowed.contains(t.toLowerCase())) {
          throw Errors.invalid('"$t" isn\'t one of the tags you can pick.');
        }
        tags.add(t);
      }
      if (tags.length > maxTags) {
        throw Errors.invalid('Pick at most $maxTags tags.');
      }
      if (tags.isEmpty && fields.tags == PublicationFieldMode.required) {
        throw Errors.invalid('Add at least one tag.');
      }
    }
    final cover = fields.coverImage == PublicationFieldMode.off
        ? null
        : v.coverImage;
    if (cover == null && fields.coverImage == PublicationFieldMode.required) {
      throw Errors.invalid('Pick a cover image.');
    }
    return SubmissionValues(
      title: title,
      summary: text(v.summary, fields.summary, 'summary'),
      tags: tags,
      coverImage: cover,
      authorBio: text(v.authorBio, fields.authorBio, 'author bio'),
      note: text(v.note, fields.note, 'note to the moderators'),
    );
  }

  /// The fields of a new publication: summary and tags optional.
  static PublicationFields defaultFields() => PublicationFields(
    summary: PublicationFieldMode.optional,
    tags: PublicationFieldMode.optional,
    allowedTags: [],
    coverImage: PublicationFieldMode.off,
    authorBio: PublicationFieldMode.off,
    note: PublicationFieldMode.optional,
  );
}
