/// The SVG icons of the Wonky Markdown elements in exports (Write 11 §9):
/// the Lucide icons the Serverpod blog and docs use, colored with
/// `currentColor` (HTML) or a given color (PDF).
library;

const _stroke =
    'fill="none" stroke="currentColor" stroke-width="2" '
    'stroke-linecap="round" stroke-linejoin="round"';

String _svg(String body, {String? cls, String attrs = _stroke}) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"'
    '${cls == null ? '' : ' class="$cls"'} aria-hidden="true" $attrs>$body</svg>';

const _calloutBodies = <String, String>{
  'info':
      '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/>'
      '<path d="M12 8h.01"/>',
  'tip':
      '<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 '
      '6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/><path d="M9 18h6"/>'
      '<path d="M10 22h4"/>',
  'note':
      '<path d="M22 17a2 2 0 0 1-2 2H6.828a2 2 0 0 0-1.414.586l-2.202 '
      '2.202A.71.71 0 0 1 2 21.286V5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2z"/>'
      '<path d="M12 11h.01"/><path d="M16 11h.01"/><path d="M8 11h.01"/>',
  'warning':
      '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 '
      '21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  'danger':
      '<path d="M12 16h.01"/><path d="M12 8v4"/><path d="M15.312 2a2 2 '
      '0 0 1 1.414.586l4.688 4.688A2 2 0 0 1 22 8.688v6.624a2 2 0 0 1-.586 '
      '1.414l-4.688 4.688a2 2 0 0 1-1.414.586H8.688a2 2 0 0 1-1.414-.586l-'
      '4.688-4.688A2 2 0 0 1 2 15.312V8.688a2 2 0 0 1 .586-1.414l4.688-4.688A2 '
      '2 0 0 1 8.688 2z"/>',
};

/// The SVG icons of Wonky Markdown elements.
abstract final class WonkyIcons {
  /// The icon of callout type [variant] (`caution` uses `warning`'s).
  static String callout(String variant, {String? cls}) => _svg(
    _calloutBodies[variant == 'caution' ? 'warning' : variant] ??
        _calloutBodies['note']!,
    cls: cls,
  );

  /// The `bullets=check` marker.
  static String check({String? cls}) =>
      _svg('<path d="M5 13l4 4L19 7"/>', cls: cls);

  /// The `bullets=circle` marker.
  static String circle({String? cls}) => _svg(
    '<circle cx="12" cy="12" r="4"/>',
    cls: cls,
    attrs: 'fill="currentColor"',
  );

  /// The disclosure chevron of a details summary.
  static String chevron({String? cls}) =>
      _svg('<path d="M19 9l-7 7-7-7"/>', cls: cls);

  /// The trailing arrow of an arrow link.
  static String arrow({String? cls}) => _svg(
    '<path d="M7 7h10v10"/><path d="M7 17 17 7"/>',
    cls: cls,
    attrs: _stroke.replaceFirst('stroke-width="2"', 'stroke-width="2.25"'),
  );

  /// [svg] with `currentColor` replaced by [hex] (`#rrggbb`), for renderers
  /// without CSS (PDF).
  static String colored(String svg, String hex) =>
      svg.replaceAll('currentColor', hex);
}
