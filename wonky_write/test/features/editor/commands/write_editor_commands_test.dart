import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/editor/model/document_queries.dart';
import 'package:wonky_write/features/editor/model/table_model.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show CellAlign, CellEdits, CellLines;

import '../support/editor_harness.dart';

void main() {
  late EditorHarness h;
  late WriteEditorCommands commands;

  void setUpWith(Delta delta, {int? base, int? extent}) {
    h = EditorHarness(delta);
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

  group('Given "a b c" with "b" bold, all selected', () {
    final initial = Delta()
      ..insert('a ')
      ..insert('b', {'bold': true})
      ..insert(' c\n');
    setUp(() => setUpWith(initial, base: 0, extent: 5));

    test(
      'when toggling bold then the whole range is bold, and again un-bolds it (AC-10.1)',
      () {
        commands.toggleFormat(InlineFormat.bold);
        expect(
          h.delta,
          Delta()
            ..insert('a b c', {'bold': true})
            ..insert('\n'),
        );
        expect(commands.isFormatActive(InlineFormat.bold), isTrue);

        commands.toggleFormat(InlineFormat.bold);
        expect(h.delta, Delta()..insert('a b c\n'));
      },
    );

    test('when toggling bold then undo and redo round-trip', () {
      commands.toggleFormat(InlineFormat.bold);
      expect(h.changes.last.label, 'Bold');
      expectUndoRedo(initial);
    });

    test('when making it inline code then bold is removed', () {
      commands.toggleFormat(InlineFormat.code);
      expect(
        h.delta,
        Delta()
          ..insert('a b c', {'code': true})
          ..insert('\n'),
      );
    });

    test('when clearing formatting then the text is plain', () {
      commands.clearFormatting();
      expect(h.delta, Delta()..insert('a b c\n'));
    });
  });

  group('Given text containing inline code, selected', () {
    setUp(
      () => setUpWith(
        Delta()
          ..insert('x ')
          ..insert('code', {'code': true})
          ..insert(' y\n'),
        base: 0,
        extent: 8,
      ),
    );

    test(
      'when toggling bold then only the non-code parts are bold and Bold is checked (AC-10.2)',
      () {
        commands.toggleFormat(InlineFormat.bold);
        expect(
          h.delta,
          Delta()
            ..insert('x ', {'bold': true})
            ..insert('code', {'code': true})
            ..insert(' y', {'bold': true})
            ..insert('\n'),
        );
        expect(commands.isFormatActive(InlineFormat.bold), isTrue);
      },
    );
  });

  group('Given a collapsed caret', () {
    setUp(() => setUpWith(Delta()..insert('Hello\n'), base: 5));

    test('when toggling bold then only the typing attributes change', () {
      commands.toggleFormat(InlineFormat.bold);
      expect(h.changes, isEmpty);
      expect(commands.isFormatActive(InlineFormat.bold), isTrue);
      h.type('!');
      expect(
        h.delta,
        Delta()
          ..insert('Hello')
          ..insert('!', {'bold': true})
          ..insert('\n'),
      );
    });
  });

  group('Given three paragraphs with formatting, selected', () {
    final initial = Delta()
      ..insert('one ')
      ..insert('bold', {'bold': true})
      ..insert('\ntwo\nthree\n');
    setUp(() => setUpWith(initial, base: 0, extent: 15));

    test(
      'when making them a code block then one code block with three lines results (AC-12.1)',
      () {
        commands.setBlockType(BlockKind.codeBlock);
        expect(
          h.delta,
          Delta()
            ..insert('one bold')
            ..insert('\n', {'code-block': ''})
            ..insert('two')
            ..insert('\n', {'code-block': ''})
            ..insert('three')
            ..insert('\n', {'code-block': ''}),
        );
        expect(h.controller.document.nodeCount, 1);
        expectUndoRedo(initial);
      },
    );

    test('when toggling quote twice then they are paragraphs again', () {
      commands.setBlockType(BlockKind.quote);
      expect(
        h.controller.document.every(
          (n) => commandsKind(commands, n.id) == BlockKind.quote,
        ),
        isTrue,
      );
      commands.setBlockType(BlockKind.quote);
      expect(h.delta, initial);
    });
  });

  group('Given a heading and two paragraphs, selected', () {
    setUp(
      () => setUpWith(
        Delta()
          ..insert('Title')
          ..insert('\n', {'header': 1})
          ..insert('a\nb\n'),
        base: 0,
        extent: 9,
      ),
    );

    test('when toggling bullets then all three become bullets (AC-13.1)', () {
      commands.toggleBulleted();
      expect(
        h.delta,
        Delta()
          ..insert('Title')
          ..insert('\n', {'list': 'bullet'})
          ..insert('a')
          ..insert('\n', {'list': 'bullet'})
          ..insert('b')
          ..insert('\n', {'list': 'bullet'}),
      );
    });
  });

  group('Given a list', () {
    final initial = Delta()
      ..insert('one')
      ..insert('\n', {'list': 'bullet'})
      ..insert('two')
      ..insert('\n', {'list': 'bullet'})
      ..insert('task')
      ..insert('\n', {'list': 'unchecked'});
    setUp(() => setUpWith(initial, base: 1));

    test(
      'when pressing Tab on the first item then nothing changes (AC-13.2)',
      () {
        expect(commands.canIndent(), isFalse);
        expect(commands.indent(), isFalse);
        expect(h.delta, initial);
      },
    );

    test(
      'when indenting the second item then it is one level deeper, and outdenting restores it',
      () {
        h.select(5);
        commands.indent();
        expect(h.delta.operations[3].attributes, {
          'list': 'bullet',
          'indent': 1,
        });
        commands.outdent();
        expect(h.delta, initial);
      },
    );

    test('when outdenting an item at level 0 then it becomes a paragraph', () {
      commands.outdent();
      expect(h.delta.operations.first.data, startsWith('one\ntwo'));
    });

    test('when toggling the task then it is checked and undo unchecks it', () {
      h.select(9);
      commands.toggleChecked();
      expect(h.delta.operations.last.attributes, {'list': 'checked'});
      expect(h.changes.last.label, 'Check item');
      expectUndoRedo(initial);
    });
  });

  group('Given a selected word', () {
    final initial = Delta()..insert('read the docs now\n');
    setUp(() => setUpWith(initial, base: 9, extent: 13));

    test(
      'when setting a link then the word is linked and undo restores it (AC-11.1)',
      () {
        commands.setLink('https://x.dev');
        expect(
          h.delta,
          Delta()
            ..insert('read the ')
            ..insert('docs', {'link': 'https://x.dev'})
            ..insert(' now\n'),
        );
        expectUndoRedo(initial);
      },
    );

    test('when setting a javascript: link then it is rejected (AC-11.3)', () {
      expect(
        () => commands.setLink('javascript:alert(1)'),
        throwsA(isA<EditorCommandError>()),
      );
      expect(h.delta, initial);
    });

    test(
      'when setting a link without scheme then https is added, and removing it at the caret unlinks',
      () {
        commands.setLink('x.dev');
        h.select(10);
        expect(commands.linkAt()!.url, 'https://x.dev');
        commands.removeLink();
        expect(h.delta, initial);
      },
    );
  });

  group('Given an empty paragraph between text', () {
    setUp(() => setUpWith(Delta()..insert('a\n\nb\n'), base: 2));

    test(
      'when inserting a divider then it replaces the empty paragraph and the caret goes below',
      () {
        commands.insertDivider();
        expect(
          h.delta,
          Delta()
            ..insert('a\n')
            ..insert({
              'divider': {'id': 'embed-0'},
            })
            ..insert('\nb\n'),
        );
        expect(h.selection, const DeltaSelection.collapsed(4));
      },
    );

    test('when inserting a table then it is one step and the caret goes into '
        'its first cell', () {
      final id = commands.insertTable(rows: 2, columns: 2);
      expect(id, 'embed-0');
      expect(h.changes.single.label, 'Insert table');
      expect(commands.tableOf(nodeId: id)!.rowCount, 2);
      expect(commands.caretCell(), (0, 0));
    });
  });

  group('Given a caret mid-paragraph', () {
    setUp(() => setUpWith(Delta()..insert('abcd\n'), base: 2));

    test('when inserting an image then the paragraph is split around it', () {
      commands.insertImages([(src: 'wonky-file://f', alt: '', title: null)]);
      expect(
        h.delta,
        Delta()
          ..insert('ab\n')
          ..insert({
            'image': {'id': 'embed-0', 'src': 'wonky-file://f', 'alt': ''},
          })
          ..insert('\ncd\n'),
      );
      expect(h.selection, const DeltaSelection.collapsed(5));
    });

    test('when inserting a mention then it is a chip followed by a space', () {
      commands.insertMention(
        userUuid: 'u1',
        displayName: 'Anna Berg',
        email: 'anna@x.dev',
      );
      expect(
        h.delta,
        Delta()
          ..insert('ab')
          ..insert('@Anna Berg', {'mention': 'u1', 'link': 'mailto:anna@x.dev'})
          ..insert(' cd\n'),
      );
    });
  });

  group('Given a dart code block with the caret inside', () {
    final initial = Delta()
      ..insert('a')
      ..insert('\n', {'code-block': 'dart'})
      ..insert('b')
      ..insert('\n', {'code-block': 'dart'});
    setUp(() => setUpWith(initial, base: 1));

    test(
      'when changing the language then every line changes and undo restores dart (AC-15.2)',
      () {
        commands.setCodeLanguage('py');
        expect(
          h.delta.operations
              .where((op) => op.data == '\n')
              .map((op) => op.attributes),
          everyElement({'code-block': 'python'}),
        );
        expectUndoRedo(initial);
      },
    );

    test(
      'when exiting the block then an empty paragraph follows with the caret',
      () {
        commands.exitCodeBlock();
        expect(
          h.delta,
          initial.compose(
            Delta()
              ..retain(4)
              ..insert('\n'),
          ),
        );
        expect(h.selection, const DeltaSelection.collapsed(4));
      },
    );

    test(
      'when pressing Tab then spaces are inserted up to the indent unit',
      () {
        h.select(0);
        commands.indentCodeLines();
        expect(h.plainText, '  a\nb\n');
      },
    );

    test('when selecting all then the code is selected first', () {
      commands.selectAll();
      expect(h.selection, const DeltaSelection(0, 3));
      commands.selectAll();
      expect(h.selection, const DeltaSelection(0, 3));
    });
  });

  group('Given a bullet with two indented children below a paragraph', () {
    final initial = Delta()
      ..insert('para\n')
      ..insert('parent')
      ..insert('\n', {'list': 'bullet'})
      ..insert('child1')
      ..insert('\n', {'list': 'bullet', 'indent': 1})
      ..insert('child2')
      ..insert('\n', {'list': 'bullet', 'indent': 1})
      ..insert('end\n');
    setUp(() => setUpWith(initial, base: 6));

    test(
      'when moving it up then all three items move and undo moves them back (AC-22.1)',
      () {
        commands.moveBlock(up: true);
        expect(h.plainText, 'parent\nchild1\nchild2\npara\nend\n');
        expectUndoRedo(initial);
      },
    );

    test('when on the first block then moving up is disabled (AC-22.2)', () {
      h.select(0);
      expect(commands.canMoveBlock(up: true), isFalse);
    });

    test('when duplicating the paragraph then a copy follows it', () {
      h.select(0);
      commands.duplicateBlock();
      expect(h.plainText.startsWith('para\npara\n'), isTrue);
    });

    test('when deleting the paragraph block then it is removed', () {
      h.select(0);
      commands.deleteBlock();
      expect(h.plainText.startsWith('parent\n'), isTrue);
    });
  });

  group('Given a table of cell lines', () {
    Map<String, dynamic> cell(String row) => {
      'cell': {'table': 't1', 'row': row},
    };
    final initial = Delta()
      ..insert('A')
      ..insert('\n', cell('r0'))
      ..insert('B')
      ..insert('\n', cell('r0'))
      ..insert('1')
      ..insert('\n', cell('r1'))
      ..insert('2')
      ..insert('\n', cell('r1'))
      ..insert('\n');
    setUp(() => setUpWith(initial, base: 0));

    test('when editing a cell and adding a row then each is one undo step '
        'keeping the id', () {
      commands.editCells(
        (run) => CellEdits.setCell(
          run.doc,
          run.id,
          1,
          1,
          CellLines.markdown('a | b'),
        ),
        nodeId: 't1',
        label: 'Edit table',
      );
      commands.editCells(
        (run) => CellEdits.insertRow(run.doc, run.id, 2),
        nodeId: 't1',
        label: 'Insert row',
      );
      final table = commands.tableOf(nodeId: 't1')!;
      expect(table.id, 't1');
      expect(table.rows, [
        ['A', 'B'],
        ['1', r'a \| b'],
        ['', ''],
      ]);
      expect(h.changes.map((c) => c.label), ['Edit table', 'Insert row']);
      h.undo(h.changes.last);
      h.undo(h.changes[0]);
      expect(h.delta, initial);
    });

    test('when setting a column alignment then every cell of the column has '
        'it', () {
      commands.editCells(
        (run) =>
            CellEdits.setColumnAlignment(run.doc, run.id, 1, CellAlign.right),
        nodeId: 't1',
        label: 'Align',
      );
      expect(commands.tableOf(nodeId: 't1')!.align, [
        TableAlign.none,
        TableAlign.right,
      ]);
    });

    test('when replacing the table from the editor then unchanged cells keep '
        'their lines', () {
      final edited = TableModel(
        id: 't1',
        align: const [TableAlign.none, TableAlign.none],
        rows: const [
          ['A', 'B'],
          ['one', '2'],
        ],
      );
      expect(commands.replaceTable(edited, nodeId: 't1'), isTrue);
      final deletes = h.changes.last.delta
          .toList()
          .where((op) => op.isDelete)
          .fold(0, (n, op) => n + op.length!);
      expect(deletes, 1);
      expect(commands.tableOf(nodeId: 't1')!.rows[1], ['one', '2']);
    });
  });

  group('Given an image', () {
    setUp(
      () => setUpWith(
        Delta()
          ..insert({
            'image': {'id': 'i1', 'src': 'wonky-file://f', 'alt': ''},
          })
          ..insert('\n'),
        base: 0,
        extent: 1,
      ),
    );

    test('when setting alt text then the embed keeps its id', () {
      commands.setImageAlt('A cat', title: 'Cat');
      expect(h.delta.operations.first.data, {
        'image': {
          'id': 'i1',
          'src': 'wonky-file://f',
          'alt': 'A cat',
          'title': 'Cat',
        },
      });
    });
  });

  group('Given a paragraph with the caret in the middle', () {
    setUp(() => setUpWith(Delta()..insert('Hello world\n'), base: 6));

    test(
      'when inserting a multi-line fragment then the first line merges and the last joins the rest',
      () {
        commands.insertFragment(
          Delta()
            ..insert('new ')
            ..insert('\n', {'header': 2})
            ..insert('line '),
        );
        expect(h.delta, Delta()..insert('Hello new \nline world\n'));
        expect(h.changes.single.label, 'Paste');
      },
    );

    test(
      'when inserting into an empty paragraph then the pasted types win',
      () {
        h.controller.resetDocument(
          Delta()..insert('\n'),
          selection: const DeltaSelection.collapsed(0),
        );
        commands.insertFragment(
          Delta()
            ..insert('Title')
            ..insert('\n', {'header': 1})
            ..insert('item')
            ..insert('\n', {'list': 'bullet'}),
        );
        expect(
          h.delta,
          Delta()
            ..insert('Title')
            ..insert('\n', {'header': 1})
            ..insert('item')
            ..insert('\n', {'list': 'bullet'}),
        );
      },
    );
  });
}

BlockKind commandsKind(WriteEditorCommands commands, String nodeId) =>
    WriteEditorCommands.kindOf(
      commands.controller.mirror.blockAt(
        commands.controller.mirror.indexOfNode(nodeId),
      ),
    );
