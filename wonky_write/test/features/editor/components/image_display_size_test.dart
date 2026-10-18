import 'dart:async';
import 'dart:typed_data';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/components/editor_services.dart';
import 'package:wonky_write/features/editor/components/wonky_components.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';

import '../support/editor_harness.dart';

class _MemoryImages extends EditorImageServices {
  @override
  FutureOr<ImageProvider?> resolve(String src, {double? displayWidth}) =>
      MemoryImage(Uint8List(8));
}

void main() {
  group('Given an image provider (W-05, Write 04 §36.5)', () {
    final photo = MemoryImage(Uint8List(4));

    test('when shown 640 px wide at 2× then it decodes at most 1280 px '
        'wide', () {
      final resized = atDisplaySize(photo, 640, 2);

      expect(
        resized,
        isA<ResizeImage>()
            .having((r) => r.width, 'width', 1280)
            .having((r) => r.height, 'height', isNull)
            .having((r) => r.allowUpscaling, 'allowUpscaling', isFalse)
            .having((r) => r.imageProvider, 'imageProvider', photo),
      );
    });

    test('when the width changes a little then the decode width stays the '
        'same (256 px steps)', () {
      final a = atDisplaySize(photo, 600, 1) as ResizeImage;
      final b = atDisplaySize(photo, 620, 1) as ResizeImage;

      expect((a.width, b.width), (768, 768));
    });

    test('when the width is unknown then the provider is used as it is', () {
      expect(atDisplaySize(photo, double.infinity, 1), same(photo));
    });
  });

  testWidgets('Given an image in the editor when it is shown then it is '
      'decoded at the display width', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = EditorHarness(
      Delta()
        ..insert({
          'image': {'id': 'embed-1', 'src': 'https://x.dev/a.png', 'alt': ''},
        })
        ..insert('\n'),
    );
    addTearDown(h.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WonkyEditor(
            controller: h.controller,
            imageServices: _MemoryImages(),
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image).first);

    expect(
      image.image,
      isA<ResizeImage>().having(
        (r) => r.width,
        'width',
        allOf(greaterThan(0), lessThanOrEqualTo(1024)),
      ),
    );
  });
}
