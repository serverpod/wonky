import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/pagination/pagination.dart';
import 'package:wonky_write/features/editor/view/editor_view_state.dart';

/// A4 at 100 %: page 1123 high, 96 px margins, 16 px between pages. Page 0's
/// content area is 96–1027, page 1's starts at 1139 + 96 = 1235.
const _page1ContentTop = 1235.0;

/// A block of the fake layout: its natural (unpaginated) text rect.
typedef _Block = ({String id, double top, double height, bool heading});

_Block _p(String id, double top, double height) =>
    (id: id, top: top, height: height, heading: false);

_Block _h(String id, double top, double height) =>
    (id: id, top: top, height: height, heading: true);

_Block _img(String id, double top, double height) =>
    (id: id, top: top, height: height, heading: false);

/// A document laid out at fixed natural positions, shifted by the gaps the
/// [PaginationController] injected (like [PaginationStylePhase] does).
class _Paged {
  _Paged(this.blocks) {
    document = MutableDocument(
      nodes: [
        for (final block in blocks)
          if (block.id.startsWith('img'))
            ImageNode(id: block.id, imageUrl: 'https://x.dev/${block.id}.png')
          else
            ParagraphNode(
              id: block.id,
              text: AttributedText('Text of ${block.id}'),
              metadata: {
                if (block.heading) NodeMetadata.blockType: header1Attribution,
              },
            ),
      ],
    );
    pagination.configure(EditorPageSetup.a4, 1);
    layout = _FakeLayout(this);
  }

  final List<_Block> blocks;
  final pagination = PaginationController();
  late final MutableDocument document;
  late final _FakeLayout layout;

  /// Gaps the current "layout" was built with.
  Map<String, double> applied = const {};

  /// Measures and re-lays out until the gaps are stable; returns the number
  /// of measures that changed the gaps.
  int paginate() {
    var passes = 0;
    while (measure()) {
      passes += 1;
      relayout();
      if (passes > 10) fail('pagination does not converge');
    }
    return passes;
  }

  /// One measure, with component sizes from the blocks' heights.
  bool measure() => pagination.measure(
    layout,
    document,
    componentSize: (id) =>
        Size(600, blocks.firstWhere((b) => b.id == id).height),
  );

  /// Applies the controller's current gaps to the layout.
  void relayout() {
    applied = pagination.gaps;
    pagination.markApplied(applied);
  }

  Rect rectOf(String id) {
    var shift = 0.0;
    for (final block in blocks) {
      shift += applied[block.id] ?? 0;
      if (block.id == id) {
        return Rect.fromLTWH(0, block.top + shift, 600, block.height);
      }
    }
    throw StateError('no block $id');
  }
}

class _FakeLayout implements DocumentLayout {
  _FakeLayout(this.paged);

  final _Paged paged;

  @override
  Rect? getRectForSelection(DocumentPosition base, DocumentPosition extent) =>
      paged.rectOf(base.nodeId);

  @override
  Rect? getRectForPosition(DocumentPosition position) {
    final rect = paged.rectOf(position.nodeId);
    // A text block's first line is 20 px; a box is one piece.
    return position.nodePosition is TextNodePosition
        ? Rect.fromLTWH(rect.left, rect.top, rect.width, 20)
        : rect;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Given A4 pages at 100 %', () {
    test('when a paragraph starts in the bottom margin then it starts at the '
        'next page\'s content top', () {
      // p0 ends at 1016, inside the content area; the paragraph spacing puts
      // p1's first line at 1030, inside the bottom margin (1027–1123).
      final paged = _Paged([_p('p0', 96, 920), _p('p1', 1030, 40)]);

      paged.paginate();

      expect(paged.rectOf('p1').top, closeTo(_page1ContentTop, 0.01));
      expect(paged.pagination.pageCount, 2);
    });

    test('when a paragraph starts in the gap between two pages then it starts '
        'at the next page\'s content top', () {
      final paged = _Paged([_p('p0', 96, 920), _p('p1', 1130, 40)]);

      paged.paginate();

      expect(paged.rectOf('p1').top, closeTo(_page1ContentTop, 0.01));
    });

    test('when the blocks after a pushed paragraph follow it then they keep '
        'their spacing', () {
      final paged = _Paged([
        _p('p0', 96, 920),
        _p('p1', 1030, 40),
        _p('p2', 1082, 40),
      ]);

      paged.paginate();

      expect(
        paged.rectOf('p2').top - paged.rectOf('p1').top,
        closeTo(52, 0.01),
      );
    });

    test('when an image is taller than the space left on the page then it '
        'moves to the next page', () {
      final paged = _Paged([_p('p0', 96, 700), _img('img0', 808, 400)]);

      paged.paginate();

      expect(paged.rectOf('img0').top, closeTo(_page1ContentTop, 0.01));
      expect(paged.rectOf('img0').bottom, lessThanOrEqualTo(1235 + 931));
    });

    test('when a heading\'s next line doesn\'t fit then the heading moves with '
        'it (AC-29.3)', () {
      final paged = _Paged([
        _p('p0', 96, 880),
        _h('h0', 990, 30),
        _p('p1', 1032, 40),
      ]);

      paged.paginate();

      expect(paged.rectOf('h0').top, closeTo(_page1ContentTop, 0.01));
      expect(paged.rectOf('p1').top, greaterThan(paged.rectOf('h0').bottom));
    });

    test('when a block is taller than a page then it is not pushed and '
        'overflows across the seam', () {
      final paged = _Paged([_p('p0', 96, 1500), _p('p1', 1610, 40)]);

      paged.paginate();

      expect(paged.pagination.gaps.containsKey('p0'), isFalse);
      expect(paged.pagination.pageCount, 2);
    });

    test('when measuring again before the layout applied the new gaps then '
        'the gaps are unchanged', () {
      final paged = _Paged([_p('p0', 96, 920), _p('p1', 1030, 40)]);

      final first = paged.measure();
      final second = paged.measure();

      expect((first, second), (true, false));
    });

    test('when a block grows after pagination then measuring again '
        'converges with every block inside one page', () {
      final blocks = [_p('p0', 96, 600), _img('img0', 708, 200)];
      final paged = _Paged(blocks);
      paged.paginate();
      expect(paged.pagination.gaps, isEmpty);

      // The image finishes loading: 200 → 500 px, pushing it off page 0.
      paged.blocks[1] = _img('img0', 708, 500);
      final passes = paged.paginate();

      expect(passes, 1);
      expect(paged.rectOf('img0').top, closeTo(_page1ContentTop, 0.01));
    });
  });

  group('Given a paginated document (incremental measure, Write 04 §36)', () {
    List<_Block> blocks() => [
      for (var i = 0; i < 40; i++) _p('p$i', 96.0 + i * 60, 40),
    ];

    test('when measuring again without changes (a caret move) then no '
        'block is measured through the layout', () {
      final paged = _Paged(blocks())..paginate();

      paged.measure();

      expect(paged.pagination.debugLastQueries, 0);
    });

    test('when a block grows then only it and the next block are measured '
        'and the page breaks equal a full measure', () {
      final paged = _Paged(blocks())..paginate();
      // p10 grows by 300 px; the blocks below it move down with it.
      final grown = [
        for (final (i, b) in paged.blocks.indexed)
          i == 10
              ? _p(b.id, b.top, b.height + 300)
              : (i > 10 ? _p(b.id, b.top + 300, b.height) : b),
      ];
      paged.blocks.setAll(0, grown);

      paged.measure();
      final queries = paged.pagination.debugLastQueries;
      paged.paginate();
      final fresh = _Paged(grown)..paginate();

      expect(queries, 2);
      expect(paged.pagination.gaps, fresh.pagination.gaps);
      expect(paged.pagination.pageCount, fresh.pagination.pageCount);
    });
  });
}
