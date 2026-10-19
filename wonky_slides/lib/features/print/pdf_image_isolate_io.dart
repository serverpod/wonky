import 'dart:async';
import 'dart:isolate';

import 'package:wonky_slides_core/pdf.dart';

/// Runs each image job of a PDF export in a new isolate; polls
/// [isCancelled] while it runs and kills the isolate on Cancel (the export
/// then ends with [SlidesPdfCancelledException]).
SlidesPdfImageRunner? isolateImageRunner(bool Function()? isCancelled) =>
    (job) async {
      final port = ReceivePort();
      final done = Completer<List<SlidesPdfPreparedImage?>>();
      Isolate? isolate;
      Timer? poll;
      void finish([Object? error]) {
        if (done.isCompleted) return;
        poll?.cancel();
        port.close();
        if (error != null) {
          done.completeError(error);
        }
      }

      port.listen((message) {
        if (done.isCompleted) return;
        switch (message) {
          case (List<SlidesPdfPreparedImage?> result,):
            poll?.cancel();
            port.close();
            done.complete(result);
          case [final Object? error, _]:
            finish(StateError('PDF image work failed: $error'));
          default:
            finish(StateError('PDF image isolate exited'));
        }
      });
      if (isCancelled != null) {
        poll = Timer.periodic(const Duration(milliseconds: 50), (_) {
          if (!isCancelled()) return;
          isolate?.kill(priority: Isolate.immediate);
          finish(const SlidesPdfCancelledException());
        });
      }
      try {
        isolate = await Isolate.spawn(
          _run,
          (port.sendPort, job),
          onError: port.sendPort,
          onExit: port.sendPort,
          debugName: 'slides-pdf-images',
        );
        if (done.isCompleted) isolate.kill(priority: Isolate.immediate);
      } on Object catch (e) {
        finish(e);
      }
      return done.future;
    };

void _run((SendPort, SlidesPdfImageJob) args) {
  final (send, job) = args;
  Isolate.exit(send, (SlidesPdfImagePrep.runSync(job),));
}
