/// The typefaces bundled with `wonky_ui` (suite 02 §2): Geist for the UI,
/// GeistMono for code and formulas, and Inter, the default document and chart
/// font. They are declared under `fonts:` in this package, so Flutter
/// qualifies their families with `packages/wonky_ui/`.
abstract final class WonkyFonts {
  /// The package that declares the fonts (for `TextStyle.package`).
  static const package = 'wonky_ui';

  /// Inter (variable: weight and optical size).
  static const inter = 'packages/$package/Inter';

  /// Geist, the UI font.
  static const geist = 'packages/$package/Geist';

  /// Geist Mono, the monospace UI font.
  static const geistMono = 'packages/$package/GeistMono';
}
