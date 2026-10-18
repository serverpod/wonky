/// Delimits untrusted text (document, cell, slide, post and pull request
/// contents) in prompts (suite 10 §1 "Privacy", CQ-31): one rule for every
/// AI feature, so text can never close its delimiter and pose as an
/// instruction.
abstract final class UntrustedText {
  /// [text] with every opening or closing [tag] (any case, spacing or
  /// attributes) defused: `</document>` becomes `<\/document>`,
  /// `<document x="1">` becomes `<\document x="1">`.
  static String escape(String text, String tag) => text.replaceAllMapped(
    RegExp(
      r'<(\s*/?\s*'
      '${RegExp.escape(tag)}'
      r'(?=[\s/>])[^>]*)>',
      caseSensitive: false,
    ),
    (m) => '<\\${m[1]!.trimLeft()}>',
  );

  /// [text] inside `<tag …>` with [attributes] (values escaped for a
  /// double-quoted attribute) and its own [tag]s defused.
  static String wrap(
    String tag,
    String text, {
    Map<String, Object?> attributes = const {},
  }) {
    final attrs = [
      for (final e in attributes.entries)
        if (e.value != null) ' ${e.key}="${attribute('${e.value}')}"',
    ].join();
    return '<$tag$attrs>\n${escape(text, tag)}\n</$tag>';
  }

  /// [value] for a double-quoted attribute.
  static String attribute(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;');
}
