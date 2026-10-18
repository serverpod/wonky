import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/board_gemini.dart';
import 'package:wonky_server/src/platform/common/models.dart';

void main() {
  group('Given the generated spec index', () {
    test('when checking it against specs/ then it is up to date', () async {
      final root = Directory.current.parent.path;
      final r = await Process.run(Platform.resolvedExecutable, [
        'run',
        '$root/tool/spec_index.dart',
        '--check',
      ], workingDirectory: root);

      expect(r.exitCode, 0, reason: '${r.stderr}');
    });

    test('when picking the index of an app area then it has the suite specs '
        'and only that app', () {
      final index = BoardGemini.specIndexFor(BoardArea.slides);

      expect(index, contains('specs/08-commands-and-undo.md'));
      expect(index, contains('specs/wonky_slides/07-code-blocks.md'));
      expect(index, isNot(contains('specs/wonky_sheets/05-formula-engine.md')));
    });

    test('when picking the index of the server area then it has the suite '
        'specs only', () {
      final index = BoardGemini.specIndexFor(BoardArea.server);

      expect(index, contains('specs/12-offline-and-sync.md'));
      expect(index, isNot(contains('specs/wonky_write/04-editor.md')));
    });
  });

  group('Given a model-written task prompt body', () {
    test('when cleaning it then the H1 and the template-owned sections are '
        'dropped', () {
      const body =
          '# Wonky task T-1: x\n## Goal\nDo it.\n## When you are done\n- Open '
          'a PR\n## Tests to add\n- A test';

      expect(
        BoardGemini.cleanTaskPromptBody(body),
        '## Goal\nDo it.\n## Tests to add\n- A test',
      );
    });
  });
}
