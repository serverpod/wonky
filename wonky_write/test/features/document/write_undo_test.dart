import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show UndoService, UndoStackKey;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write/features/document/write_undo.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

const _stack = UndoStackKey('doc');

/// A document with a local undo stack, as the session drives it: local
/// changes push `write.content` entries, remote changes rebase the stacks.
class _Doc extends UndoHandler<WriteContentUndoEntry> {
  _Doc(this.doc) {
    service
      ..registerHandler(this)
      ..setActiveDocument(_stack);
  }

  Delta doc;
  final service = UndoService();
  int _ids = 0;

  @override
  String get domain => WriteContentUndoEntry.domainName;

  void local(
    Delta change, {
    String label = 'Edit',
    String? coalesceKey,
    DeltaSelection? before,
    DeltaSelection? after,
  }) {
    final inverse = WonkyOt.invert(change, doc);
    doc = WonkyOt.apply(doc, change);
    service.push(
      UndoStep(
        id: '${_ids++}',
        label: label,
        coalesceKey: coalesceKey,
        entries: [
          WriteContentUndoEntry(
            change: inverse,
            select: before,
            counterSelect: after,
          ),
        ],
      ),
      stack: _stack,
    );
  }

  void remote(Delta change) {
    doc = WonkyOt.apply(doc, change);
    final r = rebaseWriteStacks(
      service.undoStepsOf(_stack),
      service.redoStepsOf(_stack),
      change,
    );
    if (r != null) service.applyRemote(_stack, r);
  }

  WriteContentUndoEntry _run(WriteContentUndoEntry e) {
    final inverse = WonkyOt.invert(e.change, doc);
    doc = WonkyOt.apply(doc, e.change);
    return WriteContentUndoEntry(
      change: inverse,
      select: e.counterSelect,
      counterSelect: e.select,
    );
  }

  @override
  Future<WriteContentUndoEntry> undo(WriteContentUndoEntry entry) async =>
      _run(entry);

  @override
  Future<WriteContentUndoEntry> redo(WriteContentUndoEntry entry) async =>
      _run(entry);

  String get text => DeltaUtils.text(doc);
}

Delta _ins(int at, String text) => Delta()
  ..retain(at)
  ..insert(text);

void main() {
  group('Given a user who typed a word', () {
    late _Doc d;

    setUp(() {
      d = _Doc(Delta()..insert('Hello\n'));
      d.local(_ins(5, ' world'), label: 'Typing');
    });

    test(
      'when undoing then the word is gone and redo brings it back',
      () async {
        await d.service.undo();
        expect(d.text, 'Hello\n');

        await d.service.redo();
        expect(d.text, 'Hello world\n');
      },
    );

    test(
      'when a collaborator typed above it then undo removes only the own word',
      () async {
        d.remote(_ins(0, 'Hi! '));

        await d.service.undo();

        expect(d.text, 'Hi! Hello\n');
      },
    );

    test(
      'when a collaborator deleted the word then the step becomes a no-op and is dropped',
      () async {
        d.remote(
          Delta()
            ..retain(5)
            ..delete(6),
        );

        expect(d.service.canUndo.value, isFalse);
        expect(d.text, 'Hello\n');
      },
    );

    test(
      'when undone and a remote change arrives then redo is rebased too',
      () async {
        await d.service.undo();
        d.remote(_ins(0, '>> '));

        await d.service.redo();

        expect(d.text, '>> Hello world\n');
      },
    );
  });

  group('Given consecutive typing in one step', () {
    test('when coalesced then one undo removes all of it', () async {
      final d = _Doc(Delta()..insert('\n'));
      d.local(_ins(0, 'a'), coalesceKey: 'k');
      d.local(_ins(1, 'b'), coalesceKey: 'k');
      d.local(_ins(2, 'c'), coalesceKey: 'k');

      expect(d.service.undoStepsOf(_stack), hasLength(1));
      await d.service.undo();

      expect(d.text, '\n');
    });
  });

  group('Given an undo entry with selections', () {
    test('when rebased over a remote insert before them then they move', () {
      final e = WriteContentUndoEntry(
        change: Delta()
          ..retain(5)
          ..delete(3),
        select: const DeltaSelection.collapsed(5),
        counterSelect: const DeltaSelection.collapsed(8),
      );

      final (rebased, _) = e.rebaseOver(_ins(0, 'XY'));

      expect(rebased!.select, const DeltaSelection.collapsed(7));
      expect(rebased.counterSelect, const DeltaSelection.collapsed(10));
    });
  });

  group('Given a write.meta entry', () {
    const entry = WriteMetaUndoEntry(
      documentUuid: 'd',
      field: 'themeId',
      beforeJson: 'null',
      afterJson: '"t1"',
    );

    test('when the echo of the own change arrives then the entry is kept', () {
      final r = entry.rebase(
        const FieldRemoteChange(
          domain: 'write.meta',
          target: 'd',
          key: 'themeId',
          value: '"t1"',
        ),
      );
      expect(r, same(entry));
    });

    test(
      'when someone else changed the property then the entry is dropped',
      () {
        final r = entry.rebase(
          const FieldRemoteChange(
            domain: 'write.meta',
            target: 'd',
            key: 'themeId',
            value: '"t2"',
          ),
        );
        expect(r, isNull);
      },
    );

    test(
      'when undone then the before value is written and the entry swaps',
      () async {
        final written = <(String, String)>[];
        final h = WriteMetaUndoHandler((f, v) async => written.add((f, v)));

        final redo = await h.undo(entry);

        expect(written.single, ('themeId', 'null'));
        expect(redo.beforeJson, '"t1"');
        expect(redo.afterJson, 'null');
      },
    );
  });

  // Suite 08 §4: random local + remote op sequences; after undoing all local
  // steps, the document equals "initial + remote ops only". Exact equality
  // holds when local steps insert and format; with local deletions, a
  // re-inserted character and a remote insertion at the same position may
  // tie either way (no tombstones), so the text is compared without the
  // remote insertions, plus the multiset of remote insertions.
  group('Given random concurrent local and remote edits', () {
    for (final deletes in [false, true]) {
      for (final seed in List.generate(25, (i) => 31 * (i + 1))) {
        test(
          'when undoing every local step (${deletes ? 'with' : 'without'} local deletions, seed $seed) then only the remote changes remain',
          () async {
            final (doc, remoteOnly) = await _undoAllAfterRandomEdits(
              seed,
              allowDeletes: deletes,
            );
            if (!deletes) {
              expect(
                DeltaUtils.canonical(doc),
                DeltaUtils.canonical(remoteOnly),
              );
            } else {
              int remote(String t) => '§'.allMatches(t).length;
              final a = DeltaUtils.text(doc);
              final b = DeltaUtils.text(remoteOnly);
              expect(a.replaceAll('§', ''), b.replaceAll('§', ''));
              expect(remote(a), remote(b));
            }
          },
        );
      }
    }
  });

  group('Given random entries and remote changes on the same document', () {
    for (final seed in [1, 7, 42, 1234, 98765]) {
      test('when rebasing an entry (seed $seed) then the result equals the '
          'OT transforms, also for disjoint changes (W-11 fast path)', () {
        final random = Random(seed);
        final gen = DeltaGen(random);
        final edits = EditGen(random, deltaGen: gen);
        var disjoint = 0;
        for (var run = 0; run < 300; run++) {
          final doc = gen.document();
          final u = edits.change(doc);
          final r = edits.change(doc);
          if (DeltaUtils.isNoop(u) || DeltaUtils.isNoop(r)) continue;
          final len = DeltaUtils.documentLength(doc);
          final entry = WriteContentUndoEntry(
            change: u,
            select: DeltaSelection.collapsed(random.nextInt(len)),
            counterSelect: DeltaSelection.collapsed(random.nextInt(len)),
          );

          final (rebased, rPrime) = entry.rebaseOver(r);
          final uPrime = WonkyOt.transform(r, u, aWinsTies: true);
          final rExpected = WonkyOt.transform(u, r, aWinsTies: false);

          final reason = 'run $run u $u r $r';
          if (identical(rebased?.change, u)) disjoint++;
          expect(
            DeltaUtils.canonical(rPrime),
            DeltaUtils.canonical(rExpected),
            reason: reason,
          );
          if (DeltaUtils.isNoop(uPrime)) {
            expect(rebased, isNull, reason: reason);
            continue;
          }
          expect(
            DeltaUtils.canonical(rebased!.change),
            DeltaUtils.canonical(uPrime),
            reason: reason,
          );
          expect(
            rebased.select,
            entry.select!.transform(rExpected),
            reason: reason,
          );
          expect(
            rebased.counterSelect,
            entry.counterSelect!.transform(r),
            reason: reason,
          );
        }
        expect(disjoint, greaterThan(0));
      });
    }
  });

  // CQ-50 (W-16): the session rebases with `rebaseWriteStacks` (fast path,
  // identity-preserving); `WonkyOt.rebaseStack` is the core's reference of
  // the same selective-undo rule (Write 03 §4). This pins them together.
  group('Given a random undo stack and a remote change', () {
    for (final seed in [1, 7, 42, 1234, 98765]) {
      test('when rebasing the stack (seed $seed) then every entry equals the '
          'core reference WonkyOt.rebaseStack', () {
        final random = Random(seed);
        final gen = DeltaGen(random);
        final edits = EditGen(random, deltaGen: gen);
        for (var run = 0; run < 100; run++) {
          var doc = gen.document();
          final steps = <UndoStep>[];
          final inverses = <Delta>[];
          for (var i = 0; i < 4; i++) {
            final change = edits.change(doc);
            if (DeltaUtils.isNoop(change)) continue;
            final inverse = WonkyOt.invert(change, doc);
            doc = WonkyOt.apply(doc, change);
            inverses.add(inverse);
            steps.add(
              UndoStep(
                id: '$i',
                label: 'Edit',
                entries: [WriteContentUndoEntry(change: inverse)],
              ),
            );
          }
          final remote = edits.change(doc);
          if (steps.isEmpty || DeltaUtils.isNoop(remote)) continue;

          final result = rebaseWriteStacks(steps, const [], remote)!;
          final (expected, _) = WonkyOt.rebaseStack(inverses, remote);

          final actual = [
            for (final step in steps)
              DeltaUtils.canonical(
                result
                        .results[step.entries.single as WriteContentUndoEntry]
                        ?.change ??
                    Delta(),
              ),
          ];
          expect(actual, [
            for (final e in expected) DeltaUtils.canonical(e),
          ], reason: 'run $run');
        }
      });
    }
  });
}

bool _hasDelete(Delta d) => d.operations.any((o) => o.isDelete);

Future<(Delta, Delta)> _undoAllAfterRandomEdits(
  int seed, {
  required bool allowDeletes,
}) async {
  final random = Random(seed);
  final initial = DeltaGen(
    Random(seed + 1),
    options: const DeltaGenOptions(
      maxLines: 4,
      embeds: false,
      tables: false,
      unicode: false,
    ),
  ).document();
  final edits = EditGen(Random(seed + 2));
  final d = _Doc(initial);
  // The collaborator's replica: initial + remote ops only.
  var remoteOnly = initial;
  // Local changes the collaborator has not seen, against remoteOnly.
  var pending = Delta();
  for (var i = 0; i < 40; i++) {
    if (random.nextBool()) {
      final change = edits.change(d.doc);
      if (DeltaUtils.isNoop(change)) continue;
      if (!allowDeletes && _hasDelete(change)) continue;
      pending = WonkyOt.compose(pending, change);
      d.local(change, label: 'Edit $i');
    } else {
      final len = DeltaUtils.documentLength(remoteOnly);
      final original = _ins(random.nextInt(len), '§');
      remoteOnly = WonkyOt.apply(remoteOnly, original);
      final forLocal = WonkyOt.transform(pending, original, aWinsTies: false);
      pending = WonkyOt.transform(original, pending, aWinsTies: true);
      d.remote(forLocal);
    }
  }
  while (d.service.canUndo.value) {
    await d.service.undo();
  }
  return (d.doc, remoteOnly);
}
