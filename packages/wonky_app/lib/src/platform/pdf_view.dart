/// The in-app PDF viewer and printing (Write 07 §8.1, Slides 10 §12, Sheets
/// 11 §7.7; CQ-53): the browser's own viewer in an `<iframe>` on the web, a
/// summary on desktop.
library;

export 'pdf_view_io.dart' if (dart.library.js_interop) 'pdf_view_web.dart';
