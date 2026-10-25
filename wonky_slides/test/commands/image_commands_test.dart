import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_app/uploads.dart' show MemoryPendingUploadStore;
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/features/canvas/slide_canvas_controller.dart';
import 'package:wonky_slides/features/elements/image/image_geometry.dart';
import 'package:wonky_slides/features/uploads/slides_image_service.dart';
import 'package:wonky_slides/features/uploads/slides_pending_uploads.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/scene.dart' show SlideImageRef;
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../harness/deck_harness.dart';

/// The files service: records uploads, refuses on quota while [full].
class FakeFiles implements FileRepository {
  bool full = false;
  final List<String> stored = [];

  @override
  Future<FileUrlView> upload({
    required UuidValue fileUuid,
    UuidValue? itemUuid,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    StoredFileKind kind = StoredFileKind.image,
    ImageProfile? imageProfile,
  }) async {
    if (full) throw FakeStorage.quotaError(neededBytes: bytes.length);
    stored.add(fileUuid.uuid);
    return FileUrlView(
      fileUuid: fileUuid,
      status: StoredFileStatus.ready,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }

  @override
  Future<FileUrlView> getUrl(UuidValue fileUuid) => throw UnimplementedError();
}

/// A [w] × [h] PNG.
Future<Uint8List> png(int w, int h) async {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF3366CC),
  );
  final img = await rec.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeckBuilder b;
  late String slide, photo, pictureSlide;
  late DeckHarness d;
  late FakeFiles files;
  late ConnectivityService net;
  late SlidesPendingUploads queue;
  late Uint8List wide;

  setUpAll(() async {
    wide = await png(400, 200);
  });

  setUp(() {
    b = DeckBuilder(title: 'Images');
    slide = b.slide(layoutKey: 'blank');
    photo = b.element(
      slide,
      ElementKind.image,
      x: 100,
      y: 100,
      width: 300,
      height: 300,
      columns: {
        ElementCols.dataJson: jsonEncode({
          'v': 1,
          'src': 'wonky-file://0190a000-0000-7000-8000-0000000000aa',
          'naturalWidth': 600,
          'naturalHeight': 600,
          'fileName': 'square.png',
          'mimeType': 'image/png',
        }),
      },
    );
    pictureSlide = b.slide(layoutKey: 'imageLeft');
    d = DeckHarness.open(fixture: b);
    d.editor.setCurrentSlide(slide);
    files = FakeFiles();
    net = ConnectivityService(ping: () async {});
    queue = SlidesPendingUploads(
      store: MemoryPendingUploadStore(),
      files: files,
      connectivity: net,
    );
    SlidesPendingUploads.installQueue(d.services, queue);
    SlidesImageService.of(d.editor).remoteLoader = (src) async =>
        src.startsWith('https://') ? wide : null;
  });

  tearDown(() async {
    queue.dispose();
    await d.dispose();
  });

  Map<String, Object?> data(String id) =>
      jsonDecode(d.model.element(id)!.str(ElementCols.dataJson)!)
          as Map<String, Object?>;

  Future<CommandResult> agent(String id, Map<String, Object?> args) =>
      d.h.invoke(id, args, InvocationSource.mcp);

  /// Runs [id] (agent) and checks execute → undo → redo as one step.
  Future<CommandResult> roundTrip(String id, Map<String, Object?> args) async {
    final before = d.model.dump();
    final steps = d.undoLabels.length;
    final r = await agent(id, args);
    expect(r.status, CommandStatus.ok, reason: '$id: ${r.message}');
    final after = d.model.dump();
    expect(after, isNot(equals(before)), reason: '$id changed nothing');
    expect(d.undoLabels.length, steps + 1, reason: '$id: one undo step');
    await d.undo();
    expect(d.model.dump(), before, reason: '$id undo');
    await d.redo();
    expect(d.model.dump(), after, reason: '$id redo');
    return r;
  }

  String fileOf(String id) =>
      SlidesImageService.fileUuidOf(data(id)['src']! as String)!;

  group('Given insert image by URL', () {
    test(
      'when an agent inserts an image then it is placed at its natural '
      'size, centered, references a client file uuid and round-trips',
      () async {
        final r = await roundTrip('slides.insert.image', {
          'source': 'url',
          'url': 'https://example.com/wide.png',
        });
        final id = (r.data! as Map)['elementId'] as String;
        final e = d.model.element(id)!;
        expect(e.kind, ElementKind.image);
        expect((e.x, e.y, e.width, e.height), (760.0, 440.0, 400.0, 200.0));
        expect(data(id)['naturalWidth'], 400);
        expect(data(id)['fileName'], 'wide.png');
        expect(d.editor.selectedElementIds, [id]);
        // The bytes render locally before the upload finished.
        final service = SlidesImageService.of(d.editor);
        expect(
          service.cachedBytes(SlideImageRef(data(id)['src']! as String)),
          wide,
        );
      },
    );

    test('when the URL is not https then nothing is inserted', () async {
      final before = d.model.dump();
      final r = await agent('slides.insert.image', {
        'source': 'url',
        'url': 'http://example.com/a.png',
      });
      expect(r.status, CommandStatus.failed);
      expect(d.model.dump(), before);
    });

    test('when the bytes are not an image then it is refused with the '
        'unsupported-type message', () async {
      SlidesImageService.of(d.editor).remoteLoader = (_) async =>
          Uint8List.fromList('not an image'.codeUnits);
      final r = await agent('slides.insert.image', {
        'source': 'url',
        'url': 'https://example.com/x.heic',
      });
      expect(r.status, CommandStatus.failed);
      expect(r.message, contains("isn't supported"));
    });
  });

  group('Given the upload queue (offline-first, 12 §1.1)', () {
    test('when an image is inserted offline then it stays on the device and '
        'uploads once online', () async {
      net.forceOffline(true);
      await queue.start();
      final r = await agent('slides.insert.image', {
        'source': 'url',
        'url': 'https://example.com/wide.png',
      });
      final id = (r.data! as Map)['elementId'] as String;
      final uuid = fileOf(id);
      await queue.flush();
      expect(files.stored, isEmpty);
      expect(queue.contains(uuid), isTrue);
      expect(await queue.bytesOf(uuid), wide);
      expect(SlidesImageService.of(d.editor).isUploading(uuid), isTrue);

      net.forceOffline(false);
      await queue.flush();
      expect(files.stored, [uuid]);
      expect(queue.contains(uuid), isFalse);
      // The upload is not an undo step of its own (03 §15).
      expect(d.undoLabels, hasLength(1));
    });

    test(
      'when the server refuses the upload on quota then the image is '
      '"out of storage"; Retry uploads it, Remove deletes it (one step)',
      () async {
        files.full = true;
        await queue.start();
        final r = await agent('slides.insert.image', {
          'source': 'url',
          'url': 'https://example.com/wide.png',
        });
        final id = (r.data! as Map)['elementId'] as String;
        final uuid = fileOf(id);
        await queue.flush();
        final service = SlidesImageService.of(d.editor);
        expect(service.isOutOfStorage(uuid), isTrue);
        expect(
          d.services.dispatcher.stateOf('slides.image.retryUpload').enabled,
          isTrue,
        );

        files.full = false;
        await d.run('slides.image.retryUpload', {'id': id});
        await queue.flush();
        expect(files.stored, [uuid]);
        expect(service.isOutOfStorage(uuid), isFalse);
      },
    );

    test('when Remove is chosen on a refused image then it is deleted and '
        'forgotten', () async {
      files.full = true;
      await queue.start();
      final r = await agent('slides.insert.image', {
        'source': 'url',
        'url': 'https://example.com/wide.png',
      });
      final id = (r.data! as Map)['elementId'] as String;
      final uuid = fileOf(id);
      await queue.flush();

      await roundTrip('slides.image.removeNotUploaded', {'id': id});
      await d.undo();
      await d.redo();
      expect(d.model.element(id), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(queue.contains(uuid), isFalse);
    });
  });

  group('Given an image on the slide', () {
    test('when it is replaced then the frame stays and the new image covers '
        'it', () async {
      final before = d.model.element(photo)!;
      await roundTrip('slides.image.replace', {
        'id': photo,
        'source': 'url',
        'url': 'https://example.com/wide.png',
      });
      final e = d.model.element(photo)!;
      expect(
        (e.x, e.y, e.width, e.height),
        (before.x, before.y, before.width, before.height),
      );
      expect(data(photo)['naturalWidth'], 400);
      expect(
        ImageCrop.fromJson(data(photo)['crop']),
        const ImageCrop(l: .25, r: .25),
      );
    });

    test('when masked then the mask is stored; none removes it', () async {
      await roundTrip('slides.image.mask', {
        'id': photo,
        'geometry': 'ellipse',
      });
      expect(data(photo)['mask'], 'ellipse');
      await roundTrip('slides.image.mask', {'id': photo, 'geometry': 'none'});
      expect(data(photo)['mask'], isNull);
    });

    test('when cropped with a new frame then crop and frame change in one '
        'step', () async {
      await roundTrip('slides.image.crop', {
        'id': photo,
        'crop': {'l': 0.1, 't': 0, 'r': 0.2, 'b': 0},
        'x': 120,
        'y': 100,
        'width': 210,
        'height': 300,
      });
      expect(
        ImageCrop.fromJson(data(photo)['crop']),
        const ImageCrop(l: .1, r: .2),
      );
      expect(d.model.element(photo)!.width, 210);
    });

    test(
      'when an agent asks for crop mode then it needs the crop values',
      () async {
        final r = await agent('slides.image.crop', {'id': photo});
        expect(r.status, CommandStatus.failed);
      },
    );

    test('when adjusted then the values are stored as fractions; reset '
        'clears them', () async {
      await roundTrip('slides.image.adjust', {
        'id': photo,
        'brightness': 40,
        'grayscale': true,
        'blur': 4,
      });
      final adj = data(photo)['adjust']! as Map;
      expect(adj['brightness'], 0.4);
      expect(adj['grayscale'], true);
      expect(adj['blur'], 4.0);
      await roundTrip('slides.image.adjust', {'id': photo, 'reset': true});
      expect(data(photo)['adjust'], isNull);
    });

    test('when reset then crop, mask and adjustments go and the natural '
        'aspect comes back', () async {
      await agent('slides.image.mask', {'id': photo, 'geometry': 'ellipse'});
      await agent('slides.image.crop', {
        'id': photo,
        'crop': {'l': 0.5, 't': 0, 'r': 0, 'b': 0},
        'width': 150,
      });
      await roundTrip('slides.image.reset', {'id': photo});
      expect(data(photo).containsKey('crop'), isFalse);
      expect(data(photo).containsKey('mask'), isFalse);
      final e = d.model.element(photo)!;
      expect(e.height, e.width);
    });
  });

  group('Given an empty picture placeholder', () {
    test('when an image is inserted with it selected then it fills the '
        'placeholder', () async {
      d.editor.setCurrentSlide(pictureSlide);
      final slideRes = d.editor.resolver.resolve(pictureSlide)!;
      final ph = slideRes.elements.firstWhere(
        (e) => e.placeholderType == SlidePlaceholderType.picture,
      );
      selectionOf(d.editor).select([ph.id]);
      final r = await roundTrip('slides.insert.image', {
        'source': 'url',
        'url': 'https://example.com/wide.png',
      });
      expect((r.data! as Map)['elementId'], ph.id);
      expect(data(ph.id)['src'], startsWith('wonky-file://'));
    });
  });

  group('Given Insert image from Wonky Drive', () {
    test('when an image file is chosen then the server copies it into the '
        'deck and the copy is referenced', () async {
      final item = d.h.drive.seed(
        name: 'photo.png',
        kind: DriveItemKind.file,
        fileCategory: FileCategory.image,
        contentRef: UuidValue.fromString(
          '0190a000-0000-7000-8000-0000000000bb',
        ),
      );
      final copies = <(String, String)>[];
      final service = SlidesImageService.of(d.editor)
        ..driveCopier = ((src, copy) async => copies.add((src.uuid, copy.uuid)))
        ..remoteLoader = (_) async => wide;
      final r = await roundTrip('slides.insert.image', {
        'source': 'drive',
        'fileItemUuid': item.uuid.uuid,
      });
      final id = (r.data! as Map)['elementId'] as String;
      expect(copies.single.$1, '0190a000-0000-7000-8000-0000000000bb');
      expect(fileOf(id), copies.single.$2);
      // Copied on the server: nothing queued for upload.
      expect(queue.contains(copies.single.$2), isFalse);
      expect(service.isUploading(copies.single.$2), isFalse);
    });
  });
}
