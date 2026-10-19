// Tests for the Wonky patches DE-1 … DE-22 (PATCHES.md).
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_internals.dart' as internals;
import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart' show $Type;
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

Object? run(String source, [String function = 'main']) =>
    eval(source, function: function);

void main() {
  group('DE-1 scope labels', () {
    test('frames carry library and offset', () {
      final program = Compiler().compile({
        'p': {'main.dart': 'int main() { return f(); } int f() { throw "x"; }'},
      });
      final runtime = Runtime.ofProgram(program);
      expect(
        () => runtime.executeLib('package:p/main.dart', 'main'),
        throwsA(anything),
      );
      expect(runtime.throwScopes!.last, startsWith('f()@'));
      final lib = int.parse(
        runtime.throwScopes!.last.split('@')[1].split(':')[0],
      );
      expect(runtime.libraryUriOf(lib), 'package:p/main.dart');
    });
  });

  group('DE-2 checkpoints', () {
    test('onCheckpoint can abort an infinite loop', () {
      final program = Compiler().compile({
        'p': {'main.dart': 'int main() { var i = 0; while (true) { i++; } }'},
      });
      final runtime = Runtime.ofProgram(program)
        ..checkpointInterval = 1000
        ..onCheckpoint = () => throw _Abort();
      expect(
        () => runtime.executeLib('package:p/main.dart', 'main'),
        throwsA(
          isA<RuntimeException>().having(
            (e) => e.caughtException,
            'cause',
            isA<_Abort>(),
          ),
        ),
      );
      runtime.resetExecutionState();
      expect(runtime.checkpoints, greaterThan(0));
    });
  });

  group('DE-7 dynamic calls', () {
    test('interpolation calls overridden toString', () {
      expect(
        run(
          "class A { String toString() => 'A!'; } String main() { Object o = A(); return 'x \$o'; }",
        ),
        'x A!',
      );
    });
    test('methods of bridge objects through dynamic', () {
      expect(
        run("String main() { dynamic d = 'abc'; return d.substring(1); }"),
        'bc',
      );
      expect(
        run('bool main() { dynamic d = [1, 2]; return d.contains(2); }'),
        true,
      );
    });
    test('default toString of script objects', () {
      expect(
        run("class A {} String main() { return 'x \${A()}'; }"),
        'x object Object',
      );
    });
  });

  group('DE-5 / DE-17 null handling', () {
    test('interpolating null', () {
      expect(run("String main() { Object? x; return 'v=\$x'; }"), 'v=null');
    });
    test('omitted optional arguments of static methods are null', () {
      expect(
        run(
          'class S { static bool f([Object? o]) => o == null; } bool main() => S.f();',
        ),
        true,
      );
    });
  });

  group('DE-8 DateTime', () {
    test('utc and fromMillisecondsSinceEpoch', () {
      expect(run('int main() => DateTime.utc(2024, 2, 3, 4).hour;'), 4);
      expect(
        run(
          'int main() => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).year;',
        ),
        1970,
      );
      expect(run('int main() => DateTime.sunday;'), 7);
    });
  });

  group('DE-9 / DE-13 / DE-14 try', () {
    test('try/catch inside a nested block keeps the caller frame', () {
      expect(
        run(
          "Object? main() { if (true) { return t(); } return null; } "
          "Object? t() { var r = 'x'; try { r = 'y'; } catch (e) { r = 'z'; } return r; }",
        ),
        'y',
      );
    });
    test('return inside try with finally', () {
      expect(run("String main() { try { return 'a'; } finally {} }"), 'a');
    });
    test('finally block sees the right representation of locals', () {
      final r = run(
        "List main() { final l = <String>[]; try { l.add('a'); } finally { l.add('b'); } return l; }",
      );
      expect([for (final v in r! as List) (v as $Value).$value], ['a', 'b']);
    });
  });

  group('DE-10 / DE-11 / DE-6 boxing', () {
    test('null assertion on script objects', () {
      expect(
        run(
          'class A {} A? f() => A(); int main() { final a = f()!; return 1; }',
        ),
        1,
      );
    });
    test('conditional with null and int', () {
      expect(
        run(
          'class A { int get h => 3; } Object? g(A? a) => a == null ? null : a.h; Object? main() => g(null);',
        ),
        null,
      );
    });
  });

  test('DE-12 large integer literals', () {
    expect(run('int main() => 1000000000000;'), 1000000000000);
  });

  test('DE-15 subclasses without constructors', () {
    expect(
      run('class A { int x = 1; } class B extends A {} int main() => B().x;'),
      1,
    );
  });

  test('DE-16 boxing null into a list', () {
    final r = run('List main() { String? s; return [s]; }');
    expect((r! as List).single, isA<$null>());
  });

  test('DE-18 nullable casts', () {
    expect(run('Object? main() { Object? x; return x as String?; }'), null);
  });

  test('DE-19 exceptions thrown in setters can be caught', () {
    expect(
      run(
        "class Q { set v(int x) { throw StateError('s'); } } String main() { try { Q().v = 1; return 'no'; } catch (e) { return 'caught'; } }",
      ),
      'caught',
    );
  });

  test('DE-20 interpolating a null String?', () {
    expect(run("String main() { String? s; return 'v \$s'; }"), 'v null');
  });

  test('DE-4 static getters of source classes', () {
    expect(run('class A { static int get x => 4; } int main() => A.x;'), 4);
  });

  test('DE-3 caught exceptions do not leave stale scope names', () {
    final program = Compiler().compile({
      'p': {
        'main.dart':
            "int main() { try { f(); } catch (e) {} return g(); } void f() { throw 'a'; } int g() { throw 'b'; }",
      },
    });
    final runtime = Runtime.ofProgram(program);
    expect(
      () => runtime.executeLib('package:p/main.dart', 'main'),
      throwsA(anything),
    );
    expect(runtime.throwScopes!.any((s) => s.startsWith('f()')), isFalse);
  });

  test('DE-21 \$Type does not implement dart:core Type (dart2wasm)', () {
    // A second implementation of `Type` makes dart2wasm compile dynamic
    // closure calls to `unreachable`; keep `$Type` a plain wrapper.
    expect($Type(int), isNot(isA<Type>()));
    expect($Type(int).$value, int);
  });

  test('DE-19 UncatchableException is exported', () {
    expect(_Abort(), isA<UncatchableException>());
    expect($null(), isA<$Value>());
  });

  test('DE-22 the internals library exports what the script host uses', () {
    expect(internals.CompileError('x'), isA<Exception>());
    expect(internals.RuntimeException, isNotNull);
    expect(internals.WrappedException, isNotNull);
    expect(internals.$InstanceImpl, isNotNull);
  });
}

class _Abort implements UncatchableException {}
