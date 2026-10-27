import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show BoxType, CalloutVariant, GridBullets, MarkdownFlavor;

import 'package:wonky_write/features/editor/grid/inline_grid_editing.dart';

import '../support/editor_harness.dart';

/// The line attributes of every line of [delta], in order.
List<Map<String, dynamic>?> _lines(Delta delta) => [
  for (final op in delta.operations)
    if (op.data is String)
      for (var i = 0; i < '\n'.allMatches(op.data! as String).length; i++)
        op.attributes,
];

List<Object?> _types(Map<String, dynamic>? line) => [
  for (final f in (line?['box'] as List?) ?? const []) (f as Map)['type'],
];

Map<String, dynamic> _box(String id, String type, [String? variant]) => {
  'id': id,
  'type': type,
  'variant': ?variant,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EditorHarness h;
  late WriteEditorCommands commands;

  void setUpWith(Delta delta, {int? base, int? extent}) {
    h = EditorHarness(delta);
    h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
    commands = WriteEditorCommands(h.controller);
    if (base != null) h.select(base, extent ?? base);
  }

  tearDown(() => h.dispose());

  /// Undo + redo round trip of the last change (suite 08 §4).
  void expectUndoRedo(Delta before) {
    final after = h.delta;
    final change = h.changes.last;
    h.undo(change);
    expect(h.delta, before, reason: 'undo');
    h.controller.applyLocal(
      change.delta,
      label: 'Redo',
      source: LocalChangeSource.undo,
    );
    expect(h.delta, after, reason: 'redo');
  }

  group('Given two selected paragraphs', () {
    final initial = Delta()..insert('one\ntwo\nafter\n');
    setUp(() => setUpWith(initial, base: 0, extent: 6));

    test('when inserting a warning then both lines are in one callout', () {
      expect(
        commands.insertContainer(
          BoxType.callout,
          variant: CalloutVariant.warning,
        ),
        isTrue,
      );
      final lines = _lines(h.delta);
      expect(lines[0]!['box'], lines[1]!['box']);
      expect((lines[0]!['box'] as List).single['variant'], 'warning');
      expect(lines[2], isNull);
      expectUndoRedo(initial);
    });

    test('when wrapping in a card and then a callout then they nest', () {
      commands.insertContainer(BoxType.card);
      h.select(0, 6);
      commands.insertContainer(BoxType.callout, variant: CalloutVariant.tip);
      expect(_types(_lines(h.delta)[0]), ['card', 'callout']);
    });
  });

  group('Given a callout of two lines', () {
    final frame = _box('c', 'callout', 'info');
    final initial = Delta()
      ..insert('one')
      ..insert('\n', {
        'box': [frame],
      })
      ..insert('two')
      ..insert('\n', {
        'box': [frame],
      })
      ..insert('after\n');
    setUp(() => setUpWith(initial, base: 1));

    test('when setting the type to danger then every line changes', () {
      expect(commands.setBoxVariant(CalloutVariant.danger), isTrue);
      for (final line in _lines(h.delta).take(2)) {
        expect((line!['box'] as List).single['variant'], 'danger');
      }
      expectUndoRedo(initial);
    });

    test('when setting a title then it is on every line, empty removes it', () {
      commands.setBoxTitle('Heads up');
      expect((_lines(h.delta)[1]!['box'] as List).single['title'], 'Heads up');
      commands.setBoxTitle('');
      expect(
        (_lines(h.delta)[1]!['box'] as List).single.containsKey('title'),
        isFalse,
      );
    });

    test('when converting to details then the first line is the summary', () {
      expect(commands.convertBox(BoxType.details), isTrue);
      final lines = _lines(h.delta);
      expect(lines[0]!['header'], 3);
      expect(_types(lines[1]), ['details']);
    });

    test('when unwrapping then the content stays without a box', () {
      expect(commands.unwrapBox(), isTrue);
      expect(h.delta, Delta()..insert('one\ntwo\nafter\n'));
      expectUndoRedo(initial);
    });

    test('when deleting then the container and its content go', () {
      expect(commands.deleteBox(), isTrue);
      expect(h.delta, Delta()..insert('after\n'));
    });

    test('when pressing Enter on an empty last line then it leaves the '
        'callout', () {
      h.select(7);
      h.type('\n\n');
      final lines = _lines(h.delta);
      expect(h.plainText, 'one\ntwo\n\nafter\n');
      expect(_types(lines[1]), ['callout']);
      expect(lines[2], isNull);
    });

    test('when pressing Backspace at the start of the first line then it '
        'leaves the callout', () {
      h.select(0);
      h.backspace();
      final lines = _lines(h.delta);
      expect(h.plainText, 'one\ntwo\nafter\n');
      expect(lines[0], isNull);
      expect(_types(lines[1]), ['callout']);
    });
  });

  group('Given an empty paragraph', () {
    setUp(() => setUpWith(Delta()..insert('\n'), base: 0));

    test('when inserting details then a summary and a body line appear', () {
      expect(commands.insertContainer(BoxType.details), isTrue);
      final lines = _lines(h.delta);
      expect(lines[0]!['header'], 3);
      expect(_types(lines[0]), ['details']);
      expect(_types(lines[1]), ['details']);
    });

    test('when collapsing details then the caret moves to the summary and '
        'moving it into the body expands them (AC-WM.4)', () {
      commands.insertContainer(BoxType.details);
      h.select(1);
      final frameId = commands.detailsAt()!.frame.id;
      expect(commands.toggleDetailsCollapsed(), isTrue);
      expect(h.controller.boxFrames.isCollapsed(frameId), isTrue);
      expect(h.selection, const DeltaSelection.collapsed(0));
      expect(h.changes.length, 1, reason: 'a view state is not a change');
      h.controller.boxFrames.reveal(
        h.controller.document,
        h.controller.mirror.entryAt(1).node,
      );
      expect(h.controller.boxFrames.isCollapsed(frameId), isFalse);
    });

    test('in Viewing mode details start collapsed', () {
      h.controller.mode = EditorMode.viewing;
      expect(h.controller.boxFrames.isCollapsed('any'), isTrue);
      h.controller.mode = EditorMode.editing;
      expect(h.controller.boxFrames.isCollapsed('any'), isFalse);
    });

    test('when inserting a grid then it has three items and can change', () {
      final grids = h.controller.gridEditing = InlineGridEditing(
        controller: h.controller,
        commands: commands,
      );
      addTearDown(grids.dispose);
      final id = commands.insertGrid()!;
      expect(grids.active, GridItemRef(id, 0), reason: 'caret in item 1');
      grids.deactivate();
      Map<dynamic, dynamic> grid() =>
          (h.delta.operations.first.data! as Map)['grid'] as Map;
      expect(grid()['items'], ['', '', '']);
      commands.setGridColumns(2, nodeId: id);
      commands.setGridBullets(GridBullets.circle, nodeId: id);
      commands.addGridItem(nodeId: id);
      expect(grid()['columns'], 2);
      expect(grid()['bullets'], 'circle');
      expect((grid()['items'] as List).length, 4);
      commands.removeGridItem(0, nodeId: id);
      expect((grid()['items'] as List).length, 3);
    });
  });

  group('Given an empty paragraph and a YouTube link', () {
    setUp(() => setUpWith(Delta()..insert('\n'), base: 0));

    Map<dynamic, dynamic> video() =>
        (h.delta.operations.first.data! as Map)['youtube'] as Map;

    test('when inserting it then it is a video embed, editable and '
        'deletable', () {
      final id = commands.insertYouTube(
        'https://youtu.be/AGAQ_N56wCs?t=90',
        title: 'Launch talk',
      )!;
      expect(video(), {
        'id': id,
        'videoId': 'AGAQ_N56wCs',
        'start': 90,
        'title': 'Launch talk',
      });
      expect(
        commands.setYouTube(
          nodeId: id,
          url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          title: '',
        ),
        isTrue,
      );
      expect(video(), {'id': id, 'videoId': 'dQw4w9WgXcQ'});
      expect(commands.deleteBlock(nodeId: id), isTrue);
      expect(h.delta.operations.any((op) => op.data is Map), isFalse);
    });

    test('when the link is not a YouTube video then nothing is inserted', () {
      expect(commands.insertYouTube('https://vimeo.com/1'), isNull);
      expect(h.delta, Delta()..insert('\n'));
    });
  });

  group('Given text with a link', () {
    final initial = Delta()
      ..insert('see ')
      ..insert('docs', {'link': 'https://x.dev'})
      ..insert(' now\n');
    setUp(() => setUpWith(initial, base: 5));

    test('when styling it as a button then linkStyle is set, plain resets', () {
      expect(commands.linkStyleAt(), 'plain');
      expect(commands.setLinkStyle('button'), isTrue);
      expect(commands.linkStyleAt(), 'button');
      expect(
        h.delta,
        Delta()
          ..insert('see ')
          ..insert('docs', {'link': 'https://x.dev', 'linkStyle': 'button'})
          ..insert(' now\n'),
      );
      commands.setLinkStyle('plain');
      expect(h.delta, initial);
    });

    test('when toggling a chip on "see" then it is a chip', () {
      h.select(0, 3);
      expect(commands.toggleChip(), isTrue);
      expect(h.delta.operations.first.attributes, {'chip': true});
      expect(commands.isChipActive(), isTrue);
    });
  });

  group('Given three H2 headings', () {
    final initial = Delta()
      ..insert('A')
      ..insert('\n', {'header': 2})
      ..insert('B')
      ..insert('\n', {'header': 2})
      ..insert('C')
      ..insert('\n', {'header': 2});

    test('when numbering them all then they are steps 1, 2 and 3', () {
      setUpWith(initial, base: 0, extent: 5);
      expect(commands.toggleStep(), isTrue);
      expect(_lines(h.delta).map((l) => l!['step']), [1, 2, 3]);
      expectUndoRedo(initial);
    });

    test('when numbering the last one after step 4 then it continues', () {
      setUpWith(
        Delta()
          ..insert('A')
          ..insert('\n', {'header': 2, 'step': 4})
          ..insert('B')
          ..insert('\n', {'header': 2}),
        base: 2,
      );
      commands.toggleStep();
      expect(_lines(h.delta).map((l) => l!['step']), [4, 5]);
      commands.renumberSteps();
      expect(_lines(h.delta).map((l) => l!['step']), [1, 2]);
    });
  });
}
