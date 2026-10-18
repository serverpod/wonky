export 'package:wonky_app/platform.dart' show printPdf;

/// Whether `printPdf` opens a print dialog on this platform: the browser's
/// print dialog from a hidden `<iframe>` in this tab (11 §7.7; no new tab or
/// window, suite 03 §1), shared with Write and Slides (`wonky_app`, CQ-53).
const bool canPrintPdf = true;
