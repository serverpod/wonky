import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matcher for an expected formula result: a number (relative tolerance 1e-12), an error
/// literal (`'#NUM!'`) or a text (complex numbers are text).
Matcher _result(Object want) => switch (want) {
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, n.abs() * 1e-12 + 1e-15),
  ),
  final String s when s.startsWith('#') => isA<FError>().having(
    (v) => v.kind.literal,
    'error',
    s,
  ),
  final String s => isA<FText>().having((v) => v.v, 'text', s),
  _ => throw ArgumentError(want),
};

void main() {
  // Reference values: Microsoft Excel IM* documentation examples (15 significant digits);
  // functions without an Excel example are checked against Python's cmath.
  group('Given complex number functions', () {
    final t = FormulaTestBench();
    t.setColumn('A1', ['3+4i', '5-3i', null, '1']);
    t.setColumn('B1', ['1+i', '2j']);

    const cases = <(String, Object)>[
      // COMPLEX
      ('=COMPLEX(3, 4)', '3+4i'),
      ('=COMPLEX(3, 4, "j")', '3+4j'),
      ('=COMPLEX(0, 1)', 'i'),
      ('=COMPLEX(0, -1)', '-i'),
      ('=COMPLEX(1, 0)', '1'),
      ('=COMPLEX(0, 0)', '0'),
      ('=COMPLEX(1.5, -2.5)', '1.5-2.5i'),
      ('=COMPLEX(3, 4, "k")', '#VALUE!'),
      ('=COMPLEX("a", 1)', '#VALUE!'),
      // IMREAL / IMAGINARY / IMABS / IMARGUMENT / IMCONJUGATE
      ('=IMREAL("6-9i")', 6),
      ('=IMREAL("-2.5e1+3i")', -25),
      ('=IMREAL("j")', 0),
      ('=IMREAL("1+2i+3")', '#NUM!'),
      ('=IMAGINARY("3+4i")', 4),
      ('=IMAGINARY("0-j")', -1),
      ('=IMAGINARY(4)', 0),
      ('=IMAGINARY("3+4")', '#NUM!'),
      ('=IMABS("5+12i")', 13),
      ('=IMABS(-3)', 3),
      ('=IMABS("x")', '#NUM!'),
      ('=IMABS(TRUE)', '#VALUE!'),
      ('=IMARGUMENT("3+4i")', 0.927295218001612),
      ('=IMARGUMENT("-1")', 3.14159265358979),
      ('=IMARGUMENT("-i")', -1.5707963267949),
      ('=IMARGUMENT("0")', '#DIV/0!'),
      ('=IMCONJUGATE("3+4i")', '3-4i'),
      ('=IMCONJUGATE("-j")', 'j'),
      ('=IMCONJUGATE(5)', '5'),
      ('=IMCONJUGATE("abc")', '#NUM!'),
      // exponentials and logarithms
      ('=IMEXP("1+i")', '1.46869393991589+2.28735528717884i'),
      ('=IMEXP("0")', '1'),
      ('=IMEXP("1000")', '#NUM!'),
      ('=IMLN("3+4i")', '1.6094379124341+0.927295218001612i'),
      ('=IMLN("1")', '0'),
      ('=IMLN("0")', '#NUM!'),
      ('=IMLOG10("3+4i")', '0.698970004336019+0.402719196273373i'),
      ('=IMLOG10("100")', '2'),
      ('=IMLOG10("0")', '#NUM!'),
      ('=IMLOG2("3+4i")', '2.32192809488736+1.33780421245098i'),
      ('=IMLOG2("8")', '3'),
      ('=IMLOG2("")', '#NUM!'),
      ('=IMLOG("42+2i", 4)', '2.69697563984786+0.0343239535639057i'),
      ('=IMLOG("16", 2)', '4'),
      ('=IMLOG("1+i", 1)', '#NUM!'),
      ('=IMPOWER("2+3i", 3)', '-46+9i'),
      ('=IMPOWER("i", 2)', '-1'),
      ('=IMPOWER("4", 0.5)', '2'),
      ('=IMPOWER("0", -1)', '#NUM!'),
      ('=IMSQRT("1+i")', '1.09868411346781+0.455089860562227i'),
      ('=IMSQRT("-4")', '2i'),
      ('=IMSQRT("0")', '0'),
      ('=IMSQRT("bad")', '#NUM!'),
      // trigonometric
      ('=IMSIN("4+3i")', '-7.61923172032141-6.548120040911i'),
      ('=IMSIN("0")', '0'),
      ('=IMSIN("x")', '#NUM!'),
      ('=IMCOS("1+i")', '0.833730025131149-0.988897705762865i'),
      ('=IMCOS("0")', '1'),
      ('=IMCOS("x")', '#NUM!'),
      ('=IMTAN("4+3i")', '0.00490825806749606+1.00070953606723i'),
      ('=IMTAN("0")', '0'),
      ('=IMTAN("x")', '#NUM!'),
      ('=IMCOT("4+3i")', '0.00490118239430447-0.999266927805902i'),
      ('=IMCOT("4+3j")', '0.00490118239430447-0.999266927805902j'),
      ('=IMCOT("0")', '#NUM!'),
      ('=IMSEC("4+3i")', '-0.065294027857947-0.0752249603027732i'),
      ('=IMSEC("0")', '1'),
      ('=IMSEC("x")', '#NUM!'),
      ('=IMCSC("4+3i")', '-0.0754898329158637+0.0648774713706355i'),
      ('=IMCSC("i")', '-0.850918128239322i'),
      ('=IMCSC("0")', '#NUM!'),
      // hyperbolic
      ('=IMSINH("4+3i")', '-27.0168132580039+3.85373803791938i'),
      ('=IMSINH("0")', '0'),
      ('=IMSINH("x")', '#NUM!'),
      ('=IMCOSH("4+3i")', '-27.0349456030742+3.85115333481178i'),
      ('=IMCOSH("0")', '1'),
      ('=IMCOSH("x")', '#NUM!'),
      ('=IMTANH("4+3i")', '0.999355987381473-0.000187346204629478i'),
      ('=IMTANH("0")', '0'),
      ('=IMTANH("x")', '#NUM!'),
      ('=IMTANH("400")', '1'),
      ('=IMCOTH("4+3i")', '1.00064439247156+0.000187587737983659i'),
      ('=IMCOTH("0")', '#NUM!'),
      ('=IMCOTH("x")', '#NUM!'),
      ('=IMSECH("4+3i")', '-0.0362534969158689-0.00516434460775318i'),
      ('=IMSECH("0")', '1'),
      ('=IMSECH("x")', '#NUM!'),
      ('=IMCSCH("4+3i")', '-0.036275889628626-0.0051744731840194i'),
      ('=IMCSCH("0")', '#NUM!'),
      ('=IMCSCH("x")', '#NUM!'),
      // arithmetic
      ('=IMDIV("-238+240i", "10+24i")', '5+12i'),
      ('=IMDIV("4", "2")', '2'),
      ('=IMDIV("1", "0")', '#NUM!'),
      ('=IMDIV("1+i", "1-j")', '#VALUE!'),
      ('=IMSUB("13+4i", "5+3i")', '8+i'),
      ('=IMSUB("1", "1")', '0'),
      ('=IMSUB("1j", "1i")', '#VALUE!'),
      ('=IMSUM("3+4i", "5-3i")', '8+i'),
      ('=IMSUM(A1:A4)', '9+i'),
      ('=IMSUM({"1+i", "2"}, 3)', '6+i'),
      ('=IMSUM("1", "x")', '#NUM!'),
      ('=IMSUM(A1:B2)', '#VALUE!'),
      ('=IMPRODUCT("3+4i", "5-3i")', '27+11i'),
      ('=IMPRODUCT("1+2i", 30)', '30+60i'),
      ('=IMPRODUCT(A1:A4)', '27+11i'),
      ('=IMPRODUCT("1+i", "1-i")', '2'),
      ('=IMPRODUCT("x")', '#NUM!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        final v = t.eval(f);

        expect(v, _result(want));
      });
    }
  });
}
