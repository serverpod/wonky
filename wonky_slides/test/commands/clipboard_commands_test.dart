import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_app/uploads.dart' show MemoryPendingUploadStore;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_rich_text/wonky_rich_text.dart' show Delta;
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_slides/commands/clipboard_commands.dart';
import 'package:wonky_slides/config/slides_features.dart';
import 'package:wonky_slides/features/clipboard/paste_options.dart';
import 'package:wonky_slides/features/elements/chart/chart_api.dart';
import 'package:wonky_slides/features/clipboard/rehome_queue.dart';
import 'package:wonky_slides/features/clipboard/system_clipboard.dart';
import 'package:wonky_slides/features/navigator/navigator_clipboard.dart';
import 'package:wonky_slides/features/uploads/slides_image_service.dart';
import 'package:wonky_slides/features/uploads/slides_pending_uploads.dart';
import 'package:wonky_charts/wonky_charts.dart' show ChartSourceSnapshot;
import 'package:wonky_slides_core/charts.dart';
import 'package:wonky_slides_core/clipboard.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart' show SuRect;
import 'package:wonky_sync_models/ids.dart';

import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart'
    show DeckViewMode;

import '../features/elements/chart/chart_fixture.dart'
    show FakeChartApi, resolved;
import '../harness/deck_harness.dart';
import 'image_commands_test.dart' show FakeFiles, png;

const _slideRect = SuRect(0, 0, 1920, 1080);
const _deckB = '00000000-0000-7000-8000-00000000bbbb';
const _f1 = '0190a000-0000-7000-8000-0000000000f1';
const _f2 = '0190a000-0000-7000-8000-0000000000f2';
const _sheet = '0190a000-0000-7000-8000-00000000c0de';
const _chart = '0190a000-0000-7000-8000-00000000c4a7';

Map<String, Object?> _imageData(String file) => {
  'v': 1,
  'src': 'wonky-file://$file',
  'naturalWidth': 400,
  'naturalHeight': 300,
  'mimeType': 'image/png',
};

Map<String, Object?> _data(DeckModel m, String id) =>
    (jsonDecode(m.element(id)!.dataJson!) as Map).cast();

/// Deck B (another presentation) with a re-homing queue whose copies are
/// recorded (and refused while [refuse] is set).
class _DeckB {
  _DeckB({StorageController? storage}) {
    final b = DeckBuilder(deckId: _deckB, ids: SequentialIdGenerator(900));
    slide = b.slide(layoutKey: 'blank');
    h = DeckHarness.open(fixture: b, storage: storage);
    h.editor.setCurrentSlide(slide);
    net = ConnectivityService(ping: () async {});
    queue = SlidesRehomeQueue(
      store: h.services.userStore,
      connectivity: net,
      copier: (job) async {
        final e = refuse;
        if (e != null) throw e;
        copies.add(job);
      },
    );
    SlidesRehomeQueue.installQueue(h.services, queue);
  }

  late final DeckHarness h;
  late final String slide;
  late final ConnectivityService net;
  late final SlidesRehomeQueue queue;
  final copies = <RehomeJob>[];
  Object? refuse;

  DeckModel get model => h.model;

  Future<void> start() => queue.start();

  Future<void> dispose() async {
    queue.dispose();
    await h.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemorySlidesClipboard sys;

  setUp(() {
    sys = MemorySlidesClipboard();
    SlidesSystemClipboard.instance = sys;
    SlidesSlideClipboard.debugClear();
  });

  group('Given objects on a slide', () {
    late DeckHarness d;
    late String slide, box, photo;

    setUp(() {
      final b = DeckBuilder(title: 'A');
      slide = b.slide(layoutKey: 'blank');
      box = b.textBox(slide, 'Hello', x: 100, y: 100);
      photo = b.element(
        slide,
        ElementKind.image,
        x: 800,
        y: 100,
        width: 400,
        height: 300,
        columns: {ElementCols.dataJson: jsonEncode(_imageData(_f1))},
      );
      d = DeckHarness.open(fixture: b);
      d.editor.setCurrentSlide(slide);
    });

    tearDown(() => d.dispose());

    test('when copied then the system clipboard holds plain text and HTML '
        'with the embedded payload', () async {
      d.editor.selectElements([box]);
      final r = await d.run('slides.edit.copy');
      expect(r.isOk, isTrue, reason: '${r.message}');
      final w = sys.writes.single;
      expect(w.plainText, 'Hello');
      expect(w.html, contains('<p>Hello</p>'));
      expect(SlidesHtml.payloadOf(w.html!)!['kind'], 'elements');
      expect(d.undoLabels, isEmpty, reason: 'copying changes nothing');
    });

    test('when pasted on the source slide repeatedly then copies cascade by '
        '32 su, each one undo step that round-trips', () async {
      d.editor.selectElements([box]);
      await d.run('slides.edit.copy');
      final before = d.model.dump();
      final r1 = await d.run('slides.edit.paste');
      final r2 = await d.run('slides.edit.paste');
      final ids = [
        for (final r in [r1, r2])
          ((r.data! as Map)['elementIds'] as List).single as String,
      ];
      expect([for (final id in ids) d.model.element(id)!.frame!.x], [132, 164]);
      expect(d.undoLabels, ['slides.edit.paste', 'slides.edit.paste']);
      final after = d.model.dump();
      await d.undo();
      await d.undo();
      expect(d.model.dump(), before);
      await d.redo();
      await d.redo();
      expect(d.model.dump(), after);
    });

    test('when cut then the objects are gone in one step and paste puts them '
        'back in place', () async {
      d.editor.selectElements([box, photo]);
      final r = await d.run('slides.edit.cut');
      expect(r.isOk, isTrue, reason: '${r.message}');
      expect(d.model.element(box), isNull);
      expect(d.undoLabels, ['slides.edit.cut']);
      final p = await d.run('slides.edit.paste');
      final ids = ((p.data! as Map)['elementIds'] as List).cast<String>();
      expect(ids, hasLength(2));
      expect(
        {for (final id in ids) d.model.element(id)!.frame!.x},
        {100.0, 800.0},
      );
    });

    test(
      'when pasted without formatting then a plain text box arrives',
      () async {
        sys.data = const SlidesClipboardData(
          plainText: '- one\n- two',
          html: '<ul><li><b>one</b></li><li>two</li></ul>',
        );
        final r = await d.run('slides.edit.paste', {'plainText': true});
        final id = ((r.data! as Map)['elementIds'] as List).single as String;
        final text = d.model.element(id)!.text!;
        expect(SlidesText.plainText(text), '- one\n- two\n');
        expect(text, isNot(contains('bold')));
      },
    );
  });

  group('Given foreign content on the clipboard (03 §12.4–§12.5)', () {
    late DeckHarness d;
    late String slide;
    late SlidesPendingUploads uploads;
    late SlidesRehomeQueue queue;
    final copies = <RehomeJob>[];

    setUp(() {
      copies.clear();
      final b = DeckBuilder(title: 'A');
      slide = b.slide(layoutKey: 'blank');
      d = DeckHarness.open(fixture: b);
      d.editor.setCurrentSlide(slide);
      final net = ConnectivityService(ping: () async {});
      uploads = SlidesPendingUploads(
        store: MemoryPendingUploadStore(),
        files: FakeFiles(),
        connectivity: net,
      );
      SlidesPendingUploads.installQueue(d.services, uploads);
      queue = SlidesRehomeQueue(
        store: d.services.userStore,
        connectivity: net,
        copier: (job) async => copies.add(job),
      );
      SlidesRehomeQueue.installQueue(d.services, queue);
    });

    tearDown(() async {
      uploads.dispose();
      queue.dispose();
      await d.dispose();
    });

    List<String> kinds(CommandResult r) => [
      for (final id in ((r.data! as Map)['elementIds'] as List).cast<String>())
        d.model.element(id)!.kind.name,
    ];

    test('when Wonky Write copied headings, a nested list, a table, an image '
        'and a code block then they become a text box, table, image and code '
        'element in one step, and the image is re-homed', () async {
      final write = [
        {'insert': 'Plan'},
        {
          'insert': '\n',
          'attributes': {'header': 1},
        },
        {'insert': 'one'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'nested'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet', 'indent': 1},
        },
        {
          'insert': {
            'table': {
              'rows': [
                ['A', 'B'],
                ['1', '2'],
              ],
            },
          },
        },
        {
          'insert': {
            'image': {'id': 'i1', 'src': 'wonky-file://$_f2', 'alt': 'Chart'},
          },
        },
        {'insert': 'main() {}'},
        {
          'insert': '\n',
          'attributes': {'code-block': 'dart'},
        },
      ];
      sys.data = SlidesClipboardData(
        plainText: '# Plan',
        html:
            '<div data-wonky-delta="'
            '${base64Url.encode(utf8.encode(jsonEncode(write)))}">x</div>',
      );
      final r = await d.run('slides.edit.paste');
      expect(r.isOk, isTrue, reason: '${r.message}');
      expect(kinds(r), ['text', 'table', 'image', 'code']);
      expect(d.undoLabels, ['slides.edit.paste']);
      final ids = ((r.data! as Map)['elementIds'] as List).cast<String>();
      final text = SlidesText.parse(d.model.element(ids[0])!.text).toJson();
      expect(text[1], {
        'insert': '\n',
        'attributes': {'style': 'title'},
      });
      expect(text.last, {
        'insert': '\n',
        'attributes': {'list': 'bullet', 'indent': 1},
      });
      final copy = SlidesIds.themePartId(testDeckId, 'file:$_f2');
      expect(_data(d.model, ids[2])['src'], 'wonky-file://$copy');
      await queue.flush();
      expect(copies.single.toJson(), {
        'source': _f2,
        'copy': copy,
        'target': testDeckId,
      });
    });

    test('when an image is on the clipboard then an image element is '
        'inserted and uploaded', () async {
      sys.data = SlidesClipboardData(
        image: await png(200, 100),
        imageType: 'image/png',
      );
      final r = await d.run('slides.edit.paste');
      expect(r.isOk, isTrue, reason: '${r.message}');
      final images = d.model
          .elementsOf(slide)
          .where((e) => e.kind == ElementKind.image);
      expect(images, hasLength(1));
      expect(d.undoLabels, ['slides.edit.paste']);
    });

    test('when plain text with list markers is pasted then a text box with '
        'a list arrives', () async {
      sys.data = const SlidesClipboardData(plainText: 'Agenda\n- one\n- two');
      final r = await d.run('slides.edit.paste');
      expect(kinds(r), ['text']);
      final id = ((r.data! as Map)['elementIds'] as List).single as String;
      expect(SlidesText.parse(d.model.element(id)!.text).toJson().last, {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      });
    });

    test('when tab-separated text is pasted then a table arrives', () async {
      sys.data = const SlidesClipboardData(plainText: 'a\tb\nc\td');
      final r = await d.run('slides.edit.paste');
      expect(kinds(r), ['table']);
    });

    test('when a URL is pasted then a text box links it', () async {
      sys.data = const SlidesClipboardData(plainText: 'https://example.com');
      final r = await d.run('slides.edit.paste');
      final id = ((r.data! as Map)['elementIds'] as List).single as String;
      expect(
        d.model.element(id)!.text,
        contains('"link":"https://example.com"'),
      );
    });

    test(
      'when Sheets cells are pasted then a table keeps bold and fills',
      () async {
        sys.data = const SlidesClipboardData(
          plainText: 'H\tI\n1\t2',
          html:
              '<table data-wonky-clip="c"><tbody><tr>'
              '<td style="font-weight:bold">H</td><td>I</td></tr><tr>'
              '<td style="background-color:#ffcc00">1</td><td>2</td></tr>'
              '</tbody></table>',
        );
        final r = await d.run('slides.edit.paste');
        expect(kinds(r), ['table']);
        final table = ((r.data! as Map)['elementIds'] as List).single as String;
        final cells = d.model.cellsOf(table).toList();
        expect(cells.any((c) => '${c.text}'.contains('"bold":true')), isTrue);
        expect(cells.any((c) => c.fill == '#ffcc00'), isTrue);
      },
    );

    test('when a Sheets chart was copied while charts are hidden (M9) then '
        'the paste is refused with a reason and nothing arrives', () async {
      SlidesFeatures.enabled = {...SlidesFeatures.shipped}
        ..remove(SlidesFeature.charts);
      addTearDown(SlidesFeatures.reset);
      await d.services.userStore.write('clipboard.sheetsObjects', {
        'id': 'c1',
        'items': [
          {
            'kind': 'chart',
            'spec': {'type': 'column'},
            'spreadsheetItemUuid': _sheet,
            'objectId': _chart,
          },
        ],
      });
      sys.data = const SlidesClipboardData(
        plainText: 'wonky-sheets-objects:c1',
      );
      final r = await d.run('slides.edit.paste');
      expect(r.status, CommandStatus.failed);
      expect(r.message, slidesL10nEnglish.toastPasteChartsUnavailable);
      expect(d.model.elementsOf(slide), isEmpty);
    });

    test('when a Sheets chart was copied then a linked chart arrives, and '
        'the chip pastes it unlinked in place of the same step', () async {
      // Charts are SL-32's: switch them on for this test.
      SlidesFeatures.enabled = {SlidesFeature.charts};
      addTearDown(SlidesFeatures.reset);
      d.services.registry.register(
        clipboardCommands(
          d.services,
        ).firstWhere((c) => c.id.value == 'slides.edit.pasteSpecial'),
        replace: true,
      );
      await d.services.userStore.write('clipboard.sheetsObjects', {
        'id': 'c1',
        'items': [
          {
            'kind': 'chart',
            'spec': {'type': 'column'},
            'title': 'Revenue',
            'spreadsheetItemUuid': _sheet,
            'objectId': _chart,
          },
        ],
      });
      sys.data = const SlidesClipboardData(
        plainText: 'wonky-sheets-objects:c1',
      );
      final r = await d.run('slides.edit.paste');
      expect(r.isOk, isTrue, reason: '${r.message}');
      final id = ((r.data! as Map)['elementIds'] as List).single as String;
      expect(d.model.chartLinkOf(id), isNotNull);
      final chip = PasteOptions.of(d.editor);
      expect(chip.state?.kind, 'sheetsChart');
      expect(chip.isTopStep, isTrue);

      final u = await d.run('slides.edit.pasteSpecial', {'mode': 'unlinked'});
      expect(u.isOk, isTrue, reason: '${u.message}');
      final charts = d.model
          .elementsOf(slide)
          .where((e) => e.kind == ElementKind.chart)
          .toList();
      expect(charts, hasLength(1));
      expect(d.model.chartLinkOf(charts.single.id), isNull);
      expect(_data(d.model, charts.single.id)['source'], 'static');
      expect(d.undoLabels, ['slides.edit.pasteSpecial']);
    });

    test('when a Sheets chart is pasted online then its snapshot comes with '
        'it, linked or unlinked (SL-32)', () async {
      final api = FakeChartApi();
      api.snapshots[_chart] = resolved(chartObjectId: _chart);
      SlidesChartApi.install(d.services, api);
      await d.services.userStore.write('clipboard.sheetsObjects', {
        'id': 'c1',
        'items': [
          {
            'kind': 'chart',
            'spec': {'type': 'column'},
            'spreadsheetItemUuid': _sheet,
            'objectId': _chart,
          },
        ],
      });
      sys.data = const SlidesClipboardData(
        plainText: 'wonky-sheets-objects:c1',
      );
      final r = await d.run('slides.edit.paste');
      final id = ((r.data! as Map)['elementIds'] as List).single as String;
      final link = d.model.chartLinkOf(id)!;
      expect(link.sourceVersion, 'log1.1:aaaa:42');
      expect(
        ChartSourceSnapshot.fromColumns(
          link.sourceSpecJson,
          link.dataSnapshotJson,
        ).data.series,
        hasLength(2),
      );
      final u = await d.run('slides.edit.pasteSpecial', {'mode': 'unlinked'});
      expect(u.isOk, isTrue, reason: '${u.message}');
      final chart = d.model
          .elementsOf(slide)
          .singleWhere((e) => e.kind == ElementKind.chart);
      final data = ChartElementData.fromJson(chart.dataJson);
      expect(data.source, SlideChartSource.static);
      expect(data.snapshot?.data.series, hasLength(2));
    });

    test('when the navigator has focus and objects are pasted then it is '
        'refused with a reason', () async {
      sys.data = const SlidesClipboardData(plainText: 'text');
      d.editor.setMode(DeckViewMode.grid);
      final r = await d.run('slides.edit.paste');
      expect(r.status, CommandStatus.failed);
      expect(d.model.elementsOf(slide), isEmpty);
    });
  });

  group('Given a group of 5 slides with images, a linked chart, builds and '
      'code states in deck A (03 AC 8, 04 AC-4)', () {
    late DeckHarness a;
    late String group, other, s1, picture;

    setUp(() {
      final b = DeckBuilder(title: 'A', ids: SequentialIdGenerator(1));
      group = b.group('Intro', color: 'blue');
      s1 = b.slide(groupId: group, title: 'One');
      final s2 = b.slide(groupId: group, title: 'Two');
      final s3 = b.slide(groupId: group, title: 'Three', layoutKey: 'blank');
      final s4 = b.slide(groupId: group, title: 'Four', layoutKey: 'blank');
      b.slide(groupId: group, title: 'Five');
      other = b.group('Demo', color: 'green', skipped: true);
      b.slide(groupId: other, title: 'Six');
      picture = b.element(
        s1,
        ElementKind.image,
        columns: {ElementCols.dataJson: jsonEncode(_imageData(_f1))},
      );
      b.build_(s1, picture);
      b.element(
        s2,
        ElementKind.image,
        columns: {ElementCols.dataJson: jsonEncode(_imageData(_f2))},
      );
      a = DeckHarness.open(fixture: b);
      a.session.execute(
        PasteElements(
          SlidesPasteMappers.sheetsObject(
            {
              'kind': 'chart',
              'spec': {'type': 'column'},
              'spreadsheetItemUuid': _sheet,
              'objectId': _chart,
            },
            slide: _slideRect,
            userId: testUserId,
            now: testNow,
            ids: SequentialIdGenerator(70000),
          ).payload,
          s3,
        ),
      );
      a.session.execute(
        PasteElements(
          SlidesPasteMappers.writeDelta(
            Delta()
              ..insert('print(1)')
              ..insert('\n', {'code-block': 'dart'}),
            slide: _slideRect,
            ids: SequentialIdGenerator(71000),
          ).payload,
          s4,
        ),
      );
    });

    tearDown(() => a.dispose());

    Future<void> copyGroups(List<String> groups) async {
      final r = await a.run('slides.navigator.copy', {'groupIds': groups});
      expect(r.isOk, isTrue, reason: '${r.message}');
    }

    test(
      'when pasted into deck B then groups, slides, elements, builds, '
      'code states and the chart link arrive and images are re-homed',
      () async {
        await copyGroups([group]);
        final b = _DeckB();
        addTearDown(b.dispose);
        await b.start();

        final r = await b.h.run('slides.edit.paste');
        expect(r.isOk, isTrue, reason: '${r.message}');

        final m = b.model;
        final pasted = m.groups.single;
        expect((pasted.title, pasted.columns['color']), ('Intro', 'blue'));
        final slides = m.slidesInGroup(pasted.id);
        expect(slides, hasLength(5));
        final els = [for (final s in slides) ...m.allElementsOf(s.id)];
        expect(m.buildsOf(slides.first.id), hasLength(1));
        final code = els.firstWhere((e) => e.kind == ElementKind.code);
        expect(m.codeStatesOf(code.id), hasLength(1));
        final chart = els.firstWhere((e) => e.kind == ElementKind.chart);
        expect(
          m.chartLinkOf(chart.id)!.columns[ChartLinkCols.spreadsheetItemUuid],
          _sheet,
        );
        final images = [
          for (final e in els)
            if (e.kind == ElementKind.image) _data(m, e.id)['src'],
        ];
        final c1 = SlidesIds.themePartId(_deckB, 'file:$_f1');
        final c2 = SlidesIds.themePartId(_deckB, 'file:$_f2');
        expect(
          images,
          unorderedEquals(['wonky-file://$c1', 'wonky-file://$c2']),
        );
        // Pending copies render from their sources.
        expect(b.queue.sourceOf(c1), _f1);
        await b.queue.flush();
        expect(
          {for (final c in b.copies) c.sourceFileUuid: c.targetItemUuid},
          {_f1: _deckB, _f2: _deckB},
        );
        expect(b.queue.length, 0);
        expect(b.h.undoLabels, ['slides.edit.paste']);
      },
    );

    test('when Keep source formatting is chosen on the chip then the paste '
        'is redone with A\'s theme in the same undo step, and again adds no '
        'second theme copy', () async {
      await copyGroups([group]);
      final b = _DeckB();
      addTearDown(b.dispose);
      await b.start();
      await b.h.run('slides.edit.paste');
      final chip = PasteOptions.of(b.h.editor);
      expect(chip.state?.kind, 'slides');
      expect(chip.state?.current, PasteModes.useDestination);
      final themes = b.model.themes.length;

      final k = await b.h.run('slides.edit.pasteSpecial', {
        'mode': 'keepSource',
      });
      expect(k.isOk, isTrue, reason: '${k.message}');
      expect(b.model.themes.length, themes + 1);
      expect(b.model.groups, hasLength(1));
      expect(b.h.undoLabels, ['slides.edit.pasteSpecial']);
      expect(chip.state?.current, PasteModes.keepSource);

      await b.h.run('slides.edit.pasteSpecial', {'mode': 'keepSource'});
      expect(b.model.themes.length, themes + 1);
      expect(b.model.groups, hasLength(1));
      expect(b.h.undoLabels, ['slides.edit.pasteSpecial']);
    });

    test('when two groups are pasted into deck B offline then they arrive '
        'with titles, colors and skip flags; the file copies wait for the '
        'connection', () async {
      await copyGroups([group, other]);
      final b = _DeckB();
      addTearDown(b.dispose);
      b.net.forceOffline(true);
      await b.start();

      final r = await b.h.run('slides.edit.paste');
      expect(r.isOk, isTrue, reason: '${r.message}');
      expect(
        [for (final g in b.model.groups) (g.title, g.skipped)],
        [('Intro', false), ('Demo', true)],
      );
      await b.queue.flush();
      expect(b.copies, isEmpty);
      expect(b.queue.length, 2);
      expect(
        SlidesImageService.of(
          b.h.editor,
        ).isUploading(SlidesIds.themePartId(_deckB, 'file:$_f1')),
        isTrue,
      );

      b.net.forceOffline(false);
      await b.queue.flush();
      expect(b.copies, hasLength(2));
      expect(b.queue.length, 0);
    });

    test('when the copy is refused for storage then the image shows out of '
        'storage until Retry', () async {
      await copyGroups([group]);
      final b = _DeckB();
      addTearDown(b.dispose);
      await b.start();
      b.refuse = FakeStorage.quotaError(neededBytes: 100);
      await b.h.run('slides.edit.paste');
      await b.queue.flush();
      final c1 = SlidesIds.themePartId(_deckB, 'file:$_f1');
      final images = SlidesImageService.of(b.h.editor);
      expect(images.isOutOfStorage(c1), isTrue);

      b.refuse = null;
      images.retryUpload(c1);
      await b.queue.flush();
      expect(images.isOutOfStorage(c1), isFalse);
      expect(b.copies.map((c) => c.sourceFileUuid), contains(_f1));
    });

    test('when deck B\'s owner has no room for the images then nothing is '
        'pasted', () async {
      // Sizes the copying device knows (03 §12.2 `files`).
      a.editor.selectElements([picture]);
      a.editor.setCurrentSlide(s1);
      final payload = SlidesClipboardCodec.copyElements(a.model, [
        picture,
      ], sourceItemUuid: testDeckId);
      for (final f in payload['files']! as List) {
        (f as Map)['size'] = 5000;
      }
      sys.data = SlidesClipboardData(
        plainText: 'x',
        html: SlidesHtml.ofPayload(payload),
      );
      final b = _DeckB(storage: FakeStorage.used(990, quotaBytes: 1000));
      addTearDown(b.dispose);
      await b.start();

      final r = await b.h.run('slides.edit.paste');
      expect(r.status, CommandStatus.cancelled);
      expect(b.model.elementsOf(b.slide), isEmpty);
      expect(b.queue.length, 0);
    });
  });
}
