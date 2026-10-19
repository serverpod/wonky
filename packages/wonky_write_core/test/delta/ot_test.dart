import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

Delta doc(String text) => Delta()..insert(text);

void main() {
  group('Given two concurrent inserts at the same position', () {
    final a = Delta()..insert('A');
    final b = Delta()..insert('B');
    final base = doc('x\n');

    test('when b is transformed against a with priority then a is first', () {
      final bPrime = a.transform(b, true);

      expect(base.compose(a).compose(bPrime), equals(doc('ABx\n')));
    });

    test(
      'when b is transformed against a without priority then b is first',
      () {
        final bPrime = a.transform(b, false);

        expect(base.compose(a).compose(bPrime), equals(doc('BAx\n')));
      },
    );

    test('when using WonkyOt.transform then the named convention matches', () {
      final bPrime = WonkyOt.transform(a, b, aWinsTies: true);

      expect(bPrime, equals(a.transform(b, true)));
    });

    test(
      'when the server rebases a client op then server inserts go first',
      () {
        final client = WonkyOt.rebaseOnServer(b, [a]);

        expect(base.compose(a).compose(client), equals(doc('ABx\n')));
      },
    );
  });

  group('Given a document and a change', () {
    final base = Delta()
      ..insert('Hello ')
      ..insert('world', {'bold': true})
      ..insert('\n', {'header': 1});

    test(
      'when inverting a mixed change then applying it restores the document',
      () {
        final change = Delta()
          ..retain(2)
          ..delete(3)
          ..insert('LL')
          ..retain(3, {'italic': true})
          ..retain(3, {'bold': null})
          ..retain(1, {'header': null});
        final after = WonkyOt.apply(base, change);

        final inverse = WonkyOt.invert(change, base);

        expect(
          WonkyOt.apply(after, inverse),
          equals(DeltaUtils.canonical(base)),
        );
      },
    );

    test('when a change is longer than the document then apply throws', () {
      final change = Delta()
        ..retain(100)
        ..insert('x');

      expect(
        () => WonkyOt.apply(base, change),
        throwsA(isA<DeltaApplyException>()),
      );
    });

    test('when an insert is at a caret then pushOnInsert decides the side', () {
      final change = Delta()
        ..retain(3)
        ..insert('abc');

      expect(WonkyOt.transformPosition(change, 3), 6);
      expect(WonkyOt.transformPosition(change, 3, pushOnInsert: false), 3);
    });

    test(
      'when text around a range is inserted at its boundaries then it does not grow',
      () {
        final change = Delta()
          ..retain(2)
          ..insert('xx')
          ..retain(3)
          ..insert('yy');

        expect(WonkyOt.transformRange(change, 2, 3), (4, 3));
      },
    );

    test('when a range is deleted entirely then its length becomes 0', () {
      final change = Delta()
        ..retain(1)
        ..delete(5);

      expect(WonkyOt.transformRange(change, 2, 3).$2, 0);
    });
  });

  group('Given canonicalization', () {
    test(
      'when an insert follows a delete after another insert then they merge',
      () {
        final d = Delta.fromOperations([
          Operation.insert('a'),
          Operation.delete(1),
          Operation.insert('b'),
        ]);

        expect(DeltaUtils.canonical(d).toJson(), [
          {'insert': 'ab'},
          {'delete': 1},
        ]);
      },
    );

    test('when a delta ends with a plain retain then it is trimmed', () {
      final d = Delta()
        ..insert('x')
        ..retain(3);

      expect(DeltaUtils.canonical(d).toJson(), [
        {'insert': 'x'},
      ]);
    });
  });

  group('Given random documents and concurrent changes', () {
    propertyTest('when transforming a pair then both orders converge (TP1)', (
      random,
      _,
    ) {
      final gen = DeltaGen(random);
      final edits = EditGen(random, deltaGen: gen);
      final d = gen.document();
      final a = edits.change(d);
      final b = edits.change(d);

      final (aPrime, bPrime) = WonkyOt.transformPair(a, b, aWinsTies: true);

      final viaA = WonkyOt.apply(WonkyOt.apply(d, a), bPrime);
      final viaB = WonkyOt.apply(WonkyOt.apply(d, b), aPrime);
      expect(viaA, equals(viaB));
    });

    propertyTest(
      'when inverting a change then compose with the inverse is identity',
      (random, _) {
        final gen = DeltaGen(
          random,
          options: const DeltaGenOptions(overlays: true),
        );
        final edits = EditGen(random, deltaGen: gen);
        final d = gen.document();
        final c = edits.change(d, overlays: true);

        final inverse = WonkyOt.invert(c, d);

        expect(WonkyOt.apply(WonkyOt.apply(d, c), inverse), equals(d));
      },
    );

    propertyTest(
      'when rebasing an undo stack over a remote op then undo-all keeps only the remote effect',
      (random, _) {
        final gen = DeltaGen(random);
        final edits = EditGen(random, deltaGen: gen);
        var d = gen.document();
        final start = d;
        // Two local edits with their inverses on the stack.
        final stack = <Delta>[];
        for (var i = 0; i < 2; i++) {
          final c = edits.change(d);
          stack.add(WonkyOt.invert(c, d));
          d = WonkyOt.apply(d, c);
        }
        // A remote op concurrent to nothing (applied on the current document).
        final remote = edits.change(d);
        final afterRemote = WonkyOt.apply(d, remote);
        final (rebased, _) = WonkyOt.rebaseStack(stack, remote);

        // Undo everything.
        var undone = afterRemote;
        for (final u in rebased.reversed) {
          undone = WonkyOt.apply(undone, u);
        }

        // Expected: the remote op expressed against the start document.
        var r = remote;
        for (final u in stack.reversed) {
          r = WonkyOt.transform(u, r, aWinsTies: false);
        }
        expect(undone, equals(WonkyOt.apply(start, r)));
      },
    );
  });

  group('Given hashing', () {
    test(
      'when two equal documents have different op structure then hashes match',
      () {
        final a = Delta()..insert('ab\n');
        final b = Delta.fromOperations([
          Operation.insert('a'),
          Operation.insert('b\n'),
        ]);

        expect(documentHash(a), documentHash(b));
      },
    );

    test(
      'when attribute key order differs then the canonical JSON is identical',
      () {
        final a = Delta()
          ..insert('x', {'bold': true, 'italic': true})
          ..insert('\n');
        final b = Delta()
          ..insert('x', {'italic': true, 'bold': true})
          ..insert('\n');

        expect(canonicalJson(a), canonicalJson(b));
      },
    );
  });

  group('Given a selection and a change', () {
    final insertAt2 = Delta()
      ..retain(2)
      ..insert('xy');

    test(
      'when the change inserts at a caret then the caret moves after it',
      () {
        expect(
          const DeltaSelection.collapsed(2).transform(insertAt2),
          const DeltaSelection.collapsed(4),
        );
      },
    );

    test('when the change inserts at the edges of a range then it does not '
        'grow', () {
      expect(
        const DeltaSelection(2, 5).transform(
          Delta()
            ..retain(5)
            ..insert('z'),
        ),
        const DeltaSelection(2, 5),
      );
    });

    test('when a backward range is transformed then it stays backward', () {
      expect(
        const DeltaSelection(6, 3).transform(insertAt2),
        const DeltaSelection(8, 5),
      );
    });

    test('when round-tripping JSON then the selection is equal', () {
      const s = DeltaSelection(4, 1);

      expect(DeltaSelection.fromJson(s.toJson()), s);
    });
  });
}
