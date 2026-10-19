import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/clipboard/system_clipboard.dart';
import 'package:wonky_sheets/features/images/image_blob_cache.dart';
import 'package:wonky_app/platform.dart'
    show ClipboardImage, ImageClipboard, MemoryImageClipboard;
import 'package:wonky_sheets/features/images/image_io.dart';
import 'package:wonky_sheets/features/images/image_object_view.dart';
import 'package:wonky_sheets/features/images/image_prepare.dart';
import 'package:wonky_sheets/features/images/image_service.dart';
import 'package:wonky_sheets/features/objects/objects_controller.dart';
import 'package:wonky_sheets_core/model.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

/// A 4×2 px PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAAEklEQVR4nGMQ2Nn4HxkzoAsAACylEkmfixcOAAAAAElFTkSuQmCC',
);

/// A 2×1 px GIF with two frames.
final _gif = base64Decode(
  'R0lGODlhAgABAPAAAP8AAAAA/yH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAAAAAgAB'
  'AAACAgQKACH5BAAKAAAALAAAAAACAAEAAAICTAoAOw==',
);

const _svg =
    '<?xml version="1.0"?>\n'
    '<svg xmlns="http://www.w3.org/2000/svg" width="40" height="20">'
    '<rect width="40" height="20" fill="#3366ff"/></svg>';

bool _isPng(Uint8List? b) =>
    b != null && b.length > 8 && b[0] == 0x89 && b[1] == 0x50;

/// A [w]×[h] PNG.
Future<Uint8List> _pngOf(int w, int h) async {
  final r = ui.PictureRecorder();
  ui.Canvas(r).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF10B981),
  );
  final img = await r.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  late SheetsHarness s;
  late MemoryImageClipboard clip;
  final platformClipboard = ImageClipboard.instance;

  ObjectsController objects() => ObjectsController.of(s.editor);

  ImageSpec specOf(String id) =>
      ImageSpec.fromJson(objects().record(id)!.specJson);

  setUp(() {
    s = SheetsHarness.open();
    clip = MemoryImageClipboard();
    ImageClipboard.instance = clip;
    SheetsImageService.of(s.editor).remoteLoader = (_) async =>
        Uint8List.fromList(_png);
  });
  tearDown(() async {
    ImageClipboard.instance = platformClipboard;
    SheetsImagePrep.maxPixels = SheetsImageRules.maxPixels;
    ObjectsController.maybeOf(s.editor)?.dispose();
    await s.dispose();
  });

  group('Given an image on the system clipboard', () {
    test('when pasting into the grid then it is inserted over cells at the '
        'active cell in one undo step', () async {
      clip.image = ClipboardImage(
        bytes: Uint8List.fromList(_png),
        mimeType: 'image/png',
      );
      await s.select('C4');
      final steps = s.h.undoLabels.length;

      final r = await s.run('sheets.edit.paste');

      expect(r.isOk, isTrue, reason: r.message);
      final list = objects().activeObjects;
      expect(list.single.kind, EmbeddedObjectKind.image);
      expect(objects().anchorCell(list.single), (3, 2));
      expect((specOf(list.single.id).naturalWidth), 4);
      expect(s.h.undoLabels.length, steps + 1);
      await s.undo();
      expect(objects().activeObjects, isEmpty);
    });

    test('when the clipboard also holds text then the text is pasted into '
        'cells instead', () async {
      clip.image = ClipboardImage(
        bytes: Uint8List.fromList(_png),
        mimeType: 'image/png',
        hasText: true,
      );
      await s.editor.clipboard.system.write(
        const SystemClipboardData(plainText: 'hello'),
      );
      await s.select('A1');
      await s.run('sheets.edit.paste');
      expect(objects().activeObjects, isEmpty);
      expect(s.text('A1'), 'hello');
    });

    test('when inserting from the clipboard source then the image is '
        'inserted; an empty clipboard fails with a message', () async {
      final empty = await s.run('sheets.image.insertOverCells', {
        'source': 'clipboard',
      });
      expect(empty.isOk, isFalse);
      expect(empty.message, 'There is no image on the clipboard');

      clip.image = ClipboardImage(
        bytes: Uint8List.fromList(_png),
        mimeType: 'image/png',
      );
      final r = await s.run('sheets.image.insertOverCells', {
        'source': 'clipboard',
      });
      expect(r.isOk, isTrue, reason: r.message);
    });
  });

  group('Given images that need processing', () {
    test('when an SVG is inserted then it is rasterized to a PNG at twice '
        'its size and keeps its own size as the natural size', () async {
      SheetsFileIo.pickImage = (_) async => PickedImage(
        name: 'logo.svg',
        bytes: Uint8List.fromList(utf8.encode(_svg)),
        mimeType: SheetsImageRules.validate(
          'logo.svg',
          Uint8List.fromList(utf8.encode(_svg)),
        ),
      );
      final r = await s.run('sheets.image.insertOverCells', {
        'source': 'upload',
      });
      expect(r.isOk, isTrue, reason: r.message);
      final spec = specOf((r.data! as Map)['objectId']! as String);
      expect(spec.mime, 'image/png');
      expect((spec.naturalWidth, spec.naturalHeight), (40, 20));
      final bytes = SheetsImageService.of(s.editor).localBytes(spec.fileUuid);
      expect(_isPng(bytes), isTrue);
      final size = await decodeImageSize(bytes!);
      expect(size, const Size(80, 40));
    });

    test('when an image exceeds the pixel limit then it is downscaled '
        'before the upload', () async {
      SheetsImagePrep.maxPixels = 100;
      final big = await _pngOf(40, 10);
      final p = await SheetsImagePrep.prepare(
        PickedImage(name: 'big.png', bytes: big, mimeType: 'image/png'),
      );
      expect(p.size.width * p.size.height, lessThanOrEqualTo(100));
      expect(p.size.width / p.size.height, closeTo(4, 0.5));
      expect(p.image.mimeType, 'image/png');
      expect(await decodeImageSize(p.image.bytes), p.size);
    });

    test('when an animated GIF is prepared then it keeps its frames', () async {
      final p = await SheetsImagePrep.prepare(
        PickedImage(
          name: 'spin.gif',
          bytes: Uint8List.fromList(_gif),
          mimeType: 'image/gif',
        ),
      );
      expect(p.frameCount, 2);
      expect(p.image.mimeType, 'image/gif');
    });
  });

  group('Given an animated GIF over cells', () {
    testWidgets('when it is shown then the editor animates it, and with '
        'reduced motion it shows the first frame', (tester) async {
      final service = SheetsImageService.of(s.editor);
      service.remoteLoader = (_) async => Uint8List.fromList(_gif);
      const uuid = '01923456-789a-7bcd-8ef0-1234567890aa';
      const spec = ImageSpec(
        fileUuid: uuid,
        mime: 'image/gif',
        naturalWidth: 2,
        naturalHeight: 1,
      );
      await tester.runAsync(() async {
        service.image(uuid);
        for (var i = 0; i < 50; i++) {
          if (service.image(uuid).value.phase == ImageLoadPhase.ready) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      expect(service.image(uuid).value.animated, isNotNull);
      for (final reduce in [false, true]) {
        await pumpSheets(
          tester,
          s,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: SizedBox(
              width: 100,
              height: 50,
              child: ImageObjectView(service: service, spec: spec),
            ),
          ),
        );
        expect(
          find.byKey(ValueKey('sheets.image.animated.$uuid')),
          reduce ? findsNothing : findsOneWidget,
        );
        expect(find.byType(RawImage), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Given the local image cache', () {
    test('when an image is inserted then its bytes are cached, and a cached '
        'image loads without the server', () async {
      final store = MemoryImageBlobStore();
      SheetsImageBlobCache.installCache(
        s.services,
        SheetsImageBlobCache(store),
      );
      final service = SheetsImageService.of(s.editor);
      service.remoteLoader = (_) async => null;
      final uuid = service.startUpload(
        PickedImage(
          name: 'a.png',
          bytes: Uint8List.fromList(_png),
          mimeType: 'image/png',
        ),
      );
      await pumpEventQueue();
      expect(store.rows[uuid]?.$1.bytes, _png);

      const other = '01923456-789a-7bcd-8ef0-1234567890ff';
      await store.put(other, Uint8List.fromList(_png), 'image/png');
      final l = service.image(other);
      for (var i = 0; i < 50 && l.value.phase != ImageLoadPhase.ready; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(l.value.phase, ImageLoadPhase.ready);
      expect(l.value.image!.width, 4);
    });

    test('when the cache is over budget then the least recently used '
        'entries are dropped', () async {
      final store = MemoryImageBlobStore();
      await store.put('a', Uint8List(10), 'image/png');
      await store.put('b', Uint8List(10), 'image/png');
      await store.put('c', Uint8List(10), 'image/png');
      await store.touch('a');
      await store.trim(20);
      expect(store.rows.keys.toSet(), {'a', 'c'});
    });
  });

  group('Given a chart', () {
    Future<String> chart() async {
      await s.type('A1', 'Region');
      await s.type('B1', 'Sales');
      await s.type('A2', 'North');
      await s.type('B2', '10');
      final r = await s.run('sheets.chart.insert', {
        'ranges': ['A1:B2'],
        'anchor': {'cell': 'D2', 'width': 200, 'height': 100},
      });
      return (r.data! as Map)['objectId']! as String;
    }

    testWidgets('when it is copied as an image then a 2× PNG goes to the '
        'clipboard', (tester) async {
      await tester.runAsync(() async {
        final id = await chart();
        final r = await s.run('sheets.chart.copyAsImage', {'objectId': id});
        expect(r.isOk, isTrue, reason: r.message);
      });
      expect(_isPng(clip.lastPng), isTrue);
      final size = await tester.runAsync(() => decodeImageSize(clip.lastPng!));
      expect(size, const Size(400, 200));
    });

    testWidgets('when it is copied as an object then the clipboard gets the '
        'paste marker and a PNG for other apps', (tester) async {
      await tester.runAsync(() async {
        final id = await chart();
        await s.run('sheets.object.copy', {
          'objectIds': [id],
        });
      });
      expect(_isPng(clip.lastPng), isTrue);
      expect(clip.lastText, startsWith('wonky-sheets-objects:'));
      final sys = await s.editor.clipboard.system.read();
      expect(sys?.plainText, clip.lastText);
      // Wonky Slides pastes the objects from the shared user store
      // (Slides 03 §12.4: a linked chart).
      final shared = await tester.runAsync(
        () => s.editor.services.userStore.read('clipboard.sheetsObjects'),
      );
      expect('wonky-sheets-objects:${(shared! as Map)['id']}', clip.lastText);
      final item = ((shared as Map)['items'] as List).single as Map;
      expect(item['objectId'], isNotNull);
      expect(item['spreadsheetItemUuid'], isNotNull);
    });
  });
}
