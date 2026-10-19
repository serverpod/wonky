import 'dart:isolate';
import 'dart:typed_data';

import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/schema.dart';

/// Decodes [body] in a new isolate; the result moves back with
/// `Isolate.exit` (no copy on this isolate).
Future<List<RevPageRow>> decodePage(RevSchema schema, Uint8List body) =>
    Isolate.run(() => RevPageCodec.decode(schema, body));
