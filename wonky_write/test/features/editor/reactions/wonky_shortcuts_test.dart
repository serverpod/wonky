import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show MarkdownFlavor;

import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write/features/editor/grid/inline_grid_editing.dart';

import '../support/editor_harness.dart';

EditorHarness _wonky(Delta initial) {
  final h = EditorHarness(initial);
  h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
  return h;
}

/// The line attributes of every line of [delta], in order.
List<Map<String, dynamic>?> _lines(Delta delta) => [
  for (final op in delta.operations)
    if (op.data is String && (op.data! as String).contains('\n'))
      for (var i = 0; i < '\n'.allMatches(op.data! as String).length; i++)
        op.attributes,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EditorHarness h;
  tearDown(() => h.dispose());

  group('Wonky Markdown shortcuts (Write 11 §7.4)', () {
    test('when typing ":::warning " then the line becomes a warning', () {
      h = _wonky(Delta()..insert('\n'))..select(0);
      h.type(':::warning Careful');
      expect(h.plainText, 'Careful\n');
      final box = _lines(h.delta).single!['box'] as List;
      expect(box.single, {
        'id': 'embed-0',
        'type': 'callout',
        'variant': 'warning',
      });
    });

    test('when typing ":::tip[Pro tip] " then the callout has the title', () {
      h = _wonky(Delta()..insert('\n'))..select(0);
      h.type(':::tip[Pro tip] x');
      expect(h.plainText, 'x\n');
      final frame = (_lines(h.delta).single!['box'] as List).single as Map;
      expect(frame['variant'], 'tip');
      expect(frame['title'], 'Pro tip');
    });

    test('when typing ":::details " then a summary and a body line appear', () {
      h = _wonky(Delta()..insert('\n'))..select(0);
      h.type(':::details Summary');
      final lines = _lines(h.delta);
      expect(h.plainText, 'Summary\n\n');
      expect(lines.first!['header'], 3);
      expect(lines.first!['box'], lines.last!['box']);
      expect((lines.last!['box'] as List).single['type'], 'details');
    });

    test('when typing ":::card " inside a callout then the card nests', () {
      h = _wonky(
        Delta()..insert('\n', {
          'box': [
            {'id': 'c', 'type': 'callout', 'variant': 'info'},
          ],
        }),
      )..select(0);
      h.type(':::card ');
      final box = _lines(h.delta).single!['box'] as List;
      expect(box.map((f) => f['type']), ['callout', 'card']);
    });

    test('when typing ":::grid " then a grid is inserted before the line and '
        'its first item gets the caret', () async {
      h = _wonky(Delta()..insert('\n'))..select(0);
      final grids = h.controller.gridEditing = InlineGridEditing(
        controller: h.controller,
        commands: WriteEditorCommands(h.controller),
      );
      addTearDown(grids.dispose);
      h.type(':::grid ');
      await pumpEventQueue();
      final grid = h.delta.operations.first.data! as Map;
      expect((grid['grid'] as Map)['columns'], 3);
      expect((grid['grid'] as Map)['items'], ['', '', '']);
      expect(
        grids.active,
        GridItemRef((grid['grid'] as Map)['id'] as String, 0),
      );
    });

    test('when typing "(2) " in an H2 then it becomes step 2', () {
      h = _wonky(Delta()..insert('\n', {'header': 2}))..select(0);
      h.type('(2) Install');
      expect(h.plainText, 'Install\n');
      expect(_lines(h.delta).single, {'header': 2, 'step': 2});
    });

    test('when typing ":chip[New]" then "New" becomes a chip', () {
      h = _wonky(Delta()..insert('\n'))..select(0);
      h.type('a :chip[New] b');
      expect(
        h.delta,
        Delta()
          ..insert('a ')
          ..insert('New', {'chip': true})
          ..insert(' b\n'),
      );
    });

    test('when typing ":button[Go](https://x.dev)" then it is a button', () {
      h = _wonky(Delta()..insert('\n'))..select(0);
      h.type(':button[Go](https://x.dev) ');
      expect(
        h.delta,
        Delta()
          ..insert('Go', {'link': 'https://x.dev', 'linkStyle': 'button'})
          ..insert(' \n'),
      );
    });

    test(
      'when typing ":link[Docs](https://x.dev)" then it is an arrow link',
      () {
        h = _wonky(Delta()..insert('\n'))..select(0);
        h.type(':link[Docs](https://x.dev)');
        expect(
          h.delta,
          Delta()
            ..insert('Docs', {'link': 'https://x.dev', 'linkStyle': 'arrow'})
            ..insert('\n'),
        );
      },
    );

    test(
      'when typing "- " and Enter in a callout then the list stays in it',
      () {
        final box = [
          {'id': 'c', 'type': 'callout', 'variant': 'info'},
        ];
        h = _wonky(Delta()..insert('\n', {'box': box}))..select(0);
        h.type('- a\nb');
        expect(_lines(h.delta), [
          {'list': 'bullet', 'box': box},
          {'list': 'bullet', 'box': box},
        ]);
      },
    );

    test('when typing at the end of a chip then the chip grows, and after → '
        'the text follows it', () {
      h = _wonky(
        Delta()
          ..insert('a ')
          ..insert('New', {'chip': true})
          ..insert('\n'),
      )..select(5);
      h.type('er');
      h.controller.leavePillAtCaret();
      h.type(' b');
      expect(
        h.delta,
        Delta()
          ..insert('a ')
          ..insert('Newer', {'chip': true})
          ..insert(' b\n'),
      );
    });

    test('when typing at the end of a button then the button grows with '
        'its link', () {
      const button = {'link': 'https://x.dev', 'linkStyle': 'button'};
      h = _wonky(
        Delta()
          ..insert('Go', button)
          ..insert(' on\n'),
      )..select(2);
      h.type('!');
      expect(
        h.delta,
        Delta()
          ..insert('Go!', button)
          ..insert(' on\n'),
      );
    });

    test('when typing at the end of a plain link then it does not grow', () {
      h = _wonky(
        Delta()
          ..insert('docs', {'link': 'https://x.dev'})
          ..insert('\n'),
      )..select(4);
      h.type('!');
      expect(
        h.delta,
        Delta()
          ..insert('docs', {'link': 'https://x.dev'})
          ..insert('!\n'),
      );
    });

    test('in a GitHub-style document nothing is converted', () {
      h = EditorHarness(Delta()..insert('\n'))..select(0);
      h.type(':::warning :chip[x]');
      expect(h.plainText, ':::warning :chip[x]\n');
      expect(_lines(h.delta).single, isNull);
    });
  });
}
