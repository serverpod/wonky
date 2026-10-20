import 'dart:async';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/components/editor_services.dart';
import 'package:wonky_write/features/editor/components/image_size_cache.dart';
import 'package:wonky_write/features/editor/pagination/pagination.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';

import '../support/editor_harness.dart';

/// Write 04 §29.3: in Pages mode no block (up to a page tall) straddles a
/// page boundary, also when heights change after the editor was built.
Future<EditorHarness> _pumpPages(
  WidgetTester tester,
  Delta delta, {
  EditorImageServices images = const NetworkImageServices(),
  LayoutMode layout = LayoutMode.pages,
  ScrollController? scroll,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = EditorHarness(delta);
  h.controller.view.layout = layout;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WonkyEditor(
          controller: h.controller,
          documentTitle: 'Test doc',
          imageServices: images,
          scrollController: scroll,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(h.dispose);
  return h;
}

WonkyEditorState _state(WidgetTester tester) =>
    tester.state<WonkyEditorState>(find.byType(WonkyEditor));

/// The laid-out rect of [nodeId] in document-layout coordinates.
Rect _rectOf(EditorHarness h, String nodeId) {
  final node = h.controller.document.getNodeById(nodeId)!;
  return h.controller.documentLayout!.getRectForSelection(
    DocumentPosition(nodeId: node.id, nodePosition: node.beginningPosition),
    DocumentPosition(nodeId: node.id, nodePosition: node.endPosition),
  )!;
}

/// Ids of the blocks that cross a page's content boundary (blocks taller
/// than a page may overflow and are skipped).
List<String> _straddling(WidgetTester tester, EditorHarness h) {
  final pagination = _state(tester).pagination;
  return [
    for (final node in h.controller.document)
      if (_rectOf(h, node.id) case final rect
          when rect.height <= pagination.contentHeight &&
              !_insideOnePage(pagination, rect))
        node.id,
  ];
}

bool _insideOnePage(PaginationController pagination, Rect rect) {
  final page = (rect.top / pagination.pageStride).floor();
  return rect.top >= pagination.contentTopOf(page) - 1 &&
      rect.bottom <= pagination.contentBottomOf(page) + 1;
}

String _imageId(EditorHarness h) =>
    h.controller.document.firstWhere((node) => node is ImageNode).id;

Delta _paragraphs(int count, {int seed = 0}) {
  final delta = Delta();
  for (var i = 0; i < count; i += 1) {
    final words = (i * 7 + seed) % 23 + 1;
    delta.insert('${List.filled(words, 'Lorem ipsum').join(' ')}.\n');
  }
  return delta;
}

Delta _image(String src) => Delta()
  ..insert({
    'image': {'id': 'embed-$src', 'src': src, 'alt': ''},
  })
  ..insert('\n');

/// An image that finishes loading when [complete] is called.
class _DelayedImage extends ImageProvider<_DelayedImage> {
  final _info = Completer<ImageInfo>();

  void complete(ImageInfo info) => _info.complete(info);

  @override
  Future<_DelayedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _DelayedImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_info.future);
}

class _TestImages extends EditorImageServices {
  _TestImages(this.providers);

  final Map<String, ImageProvider> providers;

  @override
  FutureOr<ImageProvider?> resolve(String src, {double? displayWidth}) =>
      providers[src];
}

Future<ImageInfo> _decoded(WidgetTester tester, int width, int height) async {
  final image = await tester.runAsync(
    () => createTestImage(width: width, height: height),
  );
  return ImageInfo(image: image!);
}

void main() {
  setUp(ImageSizeCache.instance.clear);
  tearDown(ImageSizeCache.instance.clear);

  group('Given the Pages layout', () {
    testWidgets(
      'when rendering paragraphs of varied lengths then none straddles a page boundary',
      (tester) async {
        final h = await _pumpPages(tester, _paragraphs(120));

        expect(_state(tester).pagination.pageCount, greaterThan(2));
        expect(_straddling(tester, h), isEmpty);
      },
    );

    testWidgets(
      'when viewing (read-only, without suggestions) then the pages are drawn too',
      (tester) async {
        final h = await _pumpPages(tester, _paragraphs(120));
        h.controller.mode = EditorMode.viewing;
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('write.editor.reader')),
          findsOneWidget,
        );
        expect(_state(tester).pagination.pageCount, greaterThan(2));
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is PageChromePainter,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when a collaborator inserts many paragraphs then none straddles a page boundary',
      (tester) async {
        final h = await _pumpPages(tester, Delta()..insert('Start\n'));

        h.controller.applyRemote(_paragraphs(90, seed: 5));
        await tester.pumpAndSettle();

        expect(_state(tester).pagination.pageCount, greaterThan(2));
        expect(_straddling(tester, h), isEmpty);
      },
    );

    testWidgets(
      'when an image is taller than a page then it is scaled down to the page content height',
      (tester) async {
        final provider = _DelayedImage();
        final h = await _pumpPages(
          tester,
          _image('https://x.dev/tall.png'),
          images: _TestImages({'https://x.dev/tall.png': provider}),
        );

        provider.complete(await _decoded(tester, 400, 3000));
        await tester.pumpAndSettle();

        final contentHeight = _state(tester).pagination.contentHeight;
        final size = _rectOf(h, _imageId(h)).size;
        expect(size.height, closeTo(contentHeight, 0.5));
        expect(size.width, closeTo(400 * contentHeight / 3000, 0.5));
        expect(_straddling(tester, h), isEmpty);
      },
    );

    testWidgets(
      'when an image finishes loading taller than its placeholder then it moves to the next page',
      (tester) async {
        final provider = _DelayedImage();
        final h = await _pumpPages(
          tester,
          _paragraphs(6).concat(_image('https://x.dev/photo.png')),
          images: _TestImages({'https://x.dev/photo.png': provider}),
        );
        final pagination = _state(tester).pagination;
        // The 16:9 placeholder fits on page 1; the loaded image won't.
        final placeholder = _rectOf(h, _imageId(h));
        expect(placeholder.bottom, lessThan(pagination.contentBottomOf(0)));
        expect(
          placeholder.top + 800,
          greaterThan(pagination.contentBottomOf(0)),
        );

        provider.complete(await _decoded(tester, 600, 800));
        await tester.pumpAndSettle();

        final loaded = _rectOf(h, _imageId(h));
        expect(loaded.size, const Size(600, 800));
        expect(loaded.top, closeTo(pagination.contentTopOf(1), 0.5));
        expect(pagination.pageCount, 2);
      },
    );

    testWidgets(
      'when an image was loaded before then its placeholder has the loaded size',
      (tester) async {
        ImageSizeCache.instance['https://x.dev/known.png'] = const Size(
          300,
          500,
        );
        final h = await _pumpPages(
          tester,
          _image('https://x.dev/known.png'),
          images: _TestImages({'https://x.dev/known.png': _DelayedImage()}),
        );

        expect(_rectOf(h, _imageId(h)).size, const Size(300, 500));
      },
    );
  });

  group('Given the Pages layout and a page that is not full (#1)', () {
    /// How far below the top of the canvas the user can scroll to.
    double scrollableBottom(ScrollController scroll) =>
        scroll.position.maxScrollExtent + scroll.position.viewportDimension;

    testWidgets(
      'when the document is one line then it scrolls to the bottom of the page and its padding',
      (tester) async {
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await _pumpPages(tester, Delta()..insert('Short\n'), scroll: scroll);

        final pagination = _state(tester).pagination;
        final pageBottom = pagination.setup.size.height * pagination.zoom;
        expect(pagination.pageCount, 1);
        expect(
          scrollableBottom(scroll),
          greaterThanOrEqualTo(
            pageBottom + PaginationController.canvasBottomPadding,
          ),
        );

        scroll.jumpTo(scroll.position.maxScrollExtent);
        await tester.pump();
        expect(scroll.offset, greaterThan(0));
      },
    );

    testWidgets(
      'when the last page is partly full then the scroll extent reaches that page\x27s bottom',
      (tester) async {
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        final h = await _pumpPages(tester, _paragraphs(40), scroll: scroll);

        final pagination = _state(tester).pagination;
        final pages = pagination.pageCount;
        expect(pages, greaterThan(1));
        final lastPageBottom =
            (pages - 1) * pagination.pageStride +
            pagination.setup.size.height * pagination.zoom;
        final lastText = _rectOf(h, h.controller.document.last.id).bottom;
        expect(lastText, lessThan(lastPageBottom - 100));
        expect(
          scrollableBottom(scroll),
          closeTo(
            lastPageBottom + PaginationController.canvasBottomPadding,
            24,
          ),
        );
      },
    );
  });

  group('Given the Pageless layout', () {
    testWidgets(
      'when an image is taller than a page then it keeps its natural height',
      (tester) async {
        final provider = _DelayedImage();
        final h = await _pumpPages(
          tester,
          _image('https://x.dev/tall.png'),
          images: _TestImages({'https://x.dev/tall.png': provider}),
          layout: LayoutMode.pageless,
        );

        provider.complete(await _decoded(tester, 400, 3000));
        await tester.pumpAndSettle();

        expect(_rectOf(h, _imageId(h)).size, const Size(400, 3000));
      },
    );
  });
}
