import 'package:wonky_slides_core/pdf.dart' show SlidesPdfImageRunner;

/// No isolates here: null keeps the exporter's time-sliced image work on
/// this isolate.
SlidesPdfImageRunner? isolateImageRunner(bool Function()? isCancelled) => null;
