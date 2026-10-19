import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/spellcheck.dart' show SpellDictionaries;
import 'package:wonky_slides/features/print/slides_client_export.dart';
import 'package:wonky_slides/features/spellcheck/slides_spelling.dart';

/// Runs before every test file of `wonky_slides` (specs/15 §4).
///
/// Every editor screen checks spelling, and the bundled Hunspell
/// dictionaries are read from the asset bundle (real I/O) and parsed in
/// 8 ms slices of real time, one per frame. In widget tests that made the
/// number of frames a `pumpAndSettle` runs — and with it the fake time that
/// passes — depend on the machine's load (the notes pane's "one undo step
/// per burst" failed under load). Tests therefore start without
/// dictionaries; spelling tests install fakes (`installFakeSpelling`) and
/// `real_dictionary_test.dart` opts into the real ones.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // PDF image work stays on the test isolate (fake async can't wait for
  // another isolate); pdf_image_isolate_test covers the isolate.
  SlidesClientExport.useImageIsolate = false;
  setUp(() {
    SlidesSpelling.debugDictionaries ??= SpellDictionaries(
      bundle: _NoDictionaries(),
    );
  });
  await testMain();
}

/// An asset bundle whose dictionary index lists nothing.
class _NoDictionaries extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final json = jsonEncode({'dictionaries': <Object>[]});
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));
  }
}
