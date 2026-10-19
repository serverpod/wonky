/// Platform glue shared by the apps (CQ-53): drops from other applications
/// ([ExternalDropSource]), each with a desktop and a web implementation
/// chosen by conditional imports.
library;

export 'src/platform/external_drop.dart';
export 'src/platform/image_clipboard.dart';
export 'src/platform/pdf_view.dart';
export 'src/platform/system_clipboard.dart'
    show WonkyClipboard, WonkyClipboardData;
