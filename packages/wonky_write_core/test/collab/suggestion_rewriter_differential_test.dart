import 'dart:math';

import 'package:dart_quill_delta/dart_quill_delta.dart' show DeltaIterator;
import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';
import 'support/legacy_editor_suggestion_rewriter.dart';

/// CQ-50: the editor's own `SuggestionRewriter` was merged into the core one
/// (own-insertion extension, deletes before inserts). This pins the merge:
/// on generated documents (with earlier suggestions of the user and of
/// others) and changes, the core rewriter gives the same document as the
/// editor's former copy, except where the core rules intentionally differ
/// (a formatting change with no effect adds no `fmt` suggestion, attributes
/// invalid for a piece are dropped, agent edits with `via` never extend an
/// insertion); the generator stays outside those.
void main() {
  const rewriter = SuggestionRewriter();
  const legacy = LegacyEditorSuggestionRewriter();

  Delta normalize(Delta doc) =>
      const WonkyDeltaNormalizer().normalize(doc).document;

  /// A document with suggestions: random edits rewritten for `u1` (the user
  /// under test) and `u2`, so own and foreign insertions, deletions and
  /// formatting suggestions are present.
  Delta documentWithSuggestions(Random random, DeltaGen gen, EditGen edits) {
    var doc = gen.document();
    for (var i = 0; i < 4; i++) {
      final user = random.nextBool() ? 'u1' : 'u2';
      final change = edits.change(doc);
      final rewritten = legacy.rewrite(
        doc,
        change,
        LegacySuggestionContext(
          userUuid: user,
          nowMs: 10 + i,
          suggestionId: 'p$i',
        ),
      );
      doc = normalize(WonkyOt.apply(doc, rewritten));
    }
    return doc;
  }

  group('Given generated documents with suggestions and edits', () {
    propertyTest(
      'when the core and the former editor rewriter rewrite the same edit '
      'then the documents are equal',
      (random, run) {
        final gen = DeltaGen(
          random,
          options: const DeltaGenOptions(tables: false, mentions: false),
        );
        final edits = EditGen(random, deltaGen: gen);
        final doc = documentWithSuggestions(random, gen, edits);
        final change = _changeInDomain(doc, edits);

        final expected = WonkyOt.apply(
          doc,
          legacy.rewrite(
            doc,
            change,
            LegacySuggestionContext(
              userUuid: 'u1',
              nowMs: 1000 + run,
              suggestionId: 'S',
            ),
          ),
        );
        final actual = WonkyOt.apply(
          doc,
          rewriter.rewrite(
            doc,
            change,
            SuggestionContext(
              userUuid: 'u1',
              nowMs: 1000 + run,
              suggestionId: 'S',
            ),
          ),
        );

        expect(actual.toJson(), equals(expected.toJson()));
      },
      runs: 300,
    );
  });

  group('Given text next to the user\'s own suggested insertion', () {
    final doc = Delta.fromJson([
      {'insert': 'ab'},
      {
        'insert': 'mine',
        'attributes': {
          'sug_o': {'t': 'ins', 'by': 'u1', 'at': 1},
        },
      },
      {'insert': 'cd\n'},
    ]);
    const ctx = SuggestionContext(
      userUuid: 'u1',
      nowMs: 100,
      suggestionId: 'S',
    );

    test('when typing right after it then the insertion is extended', () {
      final s = rewriter.rewrite(
        doc,
        Delta()
          ..retain(6)
          ..insert('X'),
        ctx,
      );

      expect(s.toJson(), [
        {'retain': 6},
        {
          'insert': 'X',
          'attributes': {
            'sug_o': {'t': 'ins', 'by': 'u1', 'at': 1},
          },
        },
      ]);
    });

    test('when an agent inserts right after it then the insert has its own '
        'mark', () {
      final s = rewriter.rewrite(
        doc,
        Delta()
          ..retain(6)
          ..insert('X'),
        const SuggestionContext(
          userUuid: 'u1',
          nowMs: 100,
          suggestionId: 'S',
          via: 'ai',
        ),
      );

      expect(s.toJson(), [
        {'retain': 6},
        {
          'insert': 'X',
          'attributes': {
            'sug_S': {'t': 'ins', 'by': 'u1', 'at': 100, 'via': 'ai'},
          },
        },
      ]);
    });

    test('when replacing other text then the deletion comes first', () {
      final s = rewriter.rewrite(
        doc,
        Delta()
          ..insert('Y')
          ..delete(1),
        ctx,
      );

      expect(s.toJson(), [
        {
          'retain': 1,
          'attributes': {
            'sug_S': {'t': 'del', 'by': 'u1', 'at': 100},
          },
        },
        {
          'insert': 'Y',
          'attributes': {
            'sug_S': {'t': 'ins', 'by': 'u1', 'at': 100},
          },
        },
      ]);
    });
  });
}

/// A random change of [doc] whose attribute changes have an effect on every
/// piece they cover and only use keys valid there (inline keys on text,
/// block keys on line ends), the domain where both rewriters agree.
Delta _changeInDomain(Delta doc, EditGen edits) {
  while (true) {
    final change = edits.change(doc);
    if (_inDomain(doc, change)) return change;
  }
}

bool _inDomain(Delta doc, Delta change) {
  final it = DeltaIterator(doc);
  for (final op in change.operations) {
    if (op.isInsert) continue;
    var remaining = op.length!;
    final patch = op.attributes;
    while (remaining > 0 && it.hasNext) {
      final piece = it.next(remaining);
      remaining -= piece.length!.toInt();
      if (op.isDelete || patch == null || patch.isEmpty) continue;
      final content = {
        for (final e in patch.entries)
          if (!WonkyAttr.isOverlay(e.key)) e.key: e.value,
      };
      if (content.isEmpty) continue;
      final group = piece.data == '\n'
          ? WonkyAttr.blockKeys
          : piece.data is String
          ? WonkyAttr.inlineKeys
          : const <String>{};
      if (!content.keys.every(group.contains)) return false;
      final current = Attributes.withoutOverlays(piece.attributes ?? const {});
      final after = Attributes.apply(current, content) ?? const {};
      if (Attributes.diff(current, after) == null) return false;
    }
  }
  return true;
}
