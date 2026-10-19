/// Where the image work of a client PDF export runs (CQ-44): an isolate on
/// native platforms, killed on Cancel; on the web there is no isolate (the
/// exporter's time-sliced default runs instead).
library;

export 'pdf_image_isolate_stub.dart'
    if (dart.library.io) 'pdf_image_isolate_io.dart';
