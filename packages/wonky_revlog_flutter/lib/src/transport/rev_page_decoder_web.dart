import 'dart:typed_data';

import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/schema.dart';

/// Slices of decoding between yields to the event loop.
const _sliceMs = 8;

/// Decodes [body] on this thread in slices of about [_sliceMs], yielding
/// between them so frames keep painting.
Future<List<RevPageRow>> decodePage(RevSchema schema, Uint8List body) async {
  final out = <RevPageRow>[];
  final watch = Stopwatch()..start();
  for (final _ in RevPageCodec.decodeSteps(schema, body, out)) {
    if (watch.elapsedMilliseconds < _sliceMs) continue;
    await Future<void>.delayed(Duration.zero);
    watch.reset();
  }
  return out;
}
