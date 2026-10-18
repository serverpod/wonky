import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

import 'function_vectors.dart';

void main() {
  // Reference values: Microsoft Excel and Google Sheets function documentation examples.
  final t = FormulaTestBench();
  t.setRows('A1', [
    ['a', 'b'],
    [1, null],
    ['c', true],
  ]);

  group('Given character code functions', () {
    formulaVectors(t, const [
      ('=CHAR(65)', 'A'),
      ('=CHAR(33)', '!'),
      ('=CHAR(8364)', '€'),
      ('=CHAR(65.9)', 'A'),
      ('=CHAR(128512)', '😀'),
      ('=CHAR(0)', '#VALUE!'),
      ('=CHAR(1114112)', '#VALUE!'),
      ('=CHAR("x")', '#VALUE!'),
      ('=UNICHAR(66)', 'B'),
      ('=UNICHAR(55296)', '#VALUE!'),
      ('=CODE("A")', 65),
      ('=CODE("!")', 33),
      ('=CODE(1)', 49),
      ('=CODE("€uro")', 8364),
      ('=CODE("")', '#VALUE!'),
      ('=UNICODE("B")', 66),
      ('=UNICODE("😀")', 128512),
      ('=UNICODE("")', '#VALUE!'),
    ]);
  });

  group('Given cleanup and case functions', () {
    formulaVectors(t, const [
      ('=CLEAN(CHAR(9) & "Monthly report" & CHAR(10))', 'Monthly report'),
      ('=TRIM(" First Quarter   Earnings ")', 'First Quarter Earnings'),
      ('=TRIM("   ")', ''),
      ('=LEN(TRIM(CHAR(9) & "x "))', 2),
      ('=LOWER("E. E. Cummings")', 'e. e. cummings'),
      ('=UPPER("total")', 'TOTAL'),
      ('=UPPER(1.5)', '1.5'),
      ('=PROPER("this is a TITLE")', 'This Is A Title'),
      ('=PROPER("2-way street")', '2-Way Street'),
      ('=PROPER("76BudGet")', '76Budget'),
      ('=PROPER("élan vital")', 'Élan Vital'),
      ('=ASC("ＡＢＣ　１２３")', 'ABC 123'),
      ('=ASC("ガパ")', 'ｶﾞﾊﾟ'),
      ('=ASC("abc")', 'abc'),
    ]);
  });

  group('Given LEN and LENB', () {
    formulaVectors(t, const [
      ('=LEN("Phoenix, AZ")', 11),
      ('=LEN("")', 0),
      ('=LEN(" One ")', 5),
      ('=LEN(123.45)', 6),
      ('=LEN(TRUE)', 4),
      ('=LEN("😀")', 2),
      ('=LEN(B2)', 0),
      ('=LENB("日本a")', 5),
      ('=LENB("abc")', 3),
    ]);
  });

  group('Given T, EXACT and REPT', () {
    formulaVectors(t, const [
      ('=T("Rainfall")', 'Rainfall'),
      ('=T(19)', ''),
      ('=T(TRUE)', ''),
      ('=T(1/0)', '#DIV/0!'),
      ('=EXACT("word", "word")', true),
      ('=EXACT("Word", "word")', false),
      ('=EXACT("w ord", "word")', false),
      ('=EXACT(1, "1")', true),
      ('=REPT("*-", 3)', '*-*-*-'),
      ('=REPT("-", 0)', ''),
      ('=REPT("x", 2.9)', 'xx'),
      ('=REPT("x", -1)', '#VALUE!'),
      ('=REPT("ab", 30000)', '#VALUE!'),
    ]);
  });

  group('Given LEFT, RIGHT and MID', () {
    formulaVectors(t, const [
      ('=LEFT("Sale Price", 4)', 'Sale'),
      ('=LEFT("Sweden")', 'S'),
      ('=LEFT("abc", 10)', 'abc'),
      ('=LEFT("abc", 0)', ''),
      ('=LEFT(12345, 2)', '12'),
      ('=LEFT("abc", -1)', '#VALUE!'),
      ('=RIGHT("Sale Price", 5)', 'Price'),
      ('=RIGHT("Stock Number")', 'r'),
      ('=RIGHT("abc", 5)', 'abc'),
      ('=RIGHT("abc", -1)', '#VALUE!'),
      ('=MID("Fluid Flow", 1, 5)', 'Fluid'),
      ('=MID("Fluid Flow", 7, 20)', 'Flow'),
      ('=MID("Fluid Flow", 20, 5)', ''),
      ('=MID("abc", 0, 1)', '#VALUE!'),
      ('=MID("abc", 1, -1)', '#VALUE!'),
    ]);
  });

  group('Given the byte-based substring functions', () {
    formulaVectors(t, const [
      ('=LEFTB("日本語", 4)', '日本'),
      ('=LEFTB("日本語", 3)', '日'),
      ('=LEFTB("abc", 2)', 'ab'),
      ('=RIGHTB("日本語", 4)', '本語'),
      ('=RIGHTB("日本語", 5)', '本語'),
      ('=MIDB("日本語", 3, 4)', '本語'),
      ('=MIDB("abc", 2, 1)', 'b'),
      ('=MIDB("abc", 0, 1)', '#VALUE!'),
      ('=REPLACEB("日本語", 3, 2, "X")', '日X語'),
      ('=FINDB("本", "日本")', 3),
      ('=SEARCHB("b", "日本ABC")', 6),
    ]);
  });

  group('Given FIND and SEARCH', () {
    formulaVectors(t, const [
      ('=FIND("M", "Miriam McGovern")', 1),
      ('=FIND("m", "Miriam McGovern")', 6),
      ('=FIND("M", "Miriam McGovern", 3)', 8),
      ('=FIND("", "abc")', 1),
      ('=FIND("", "abc", 4)', 4),
      ('=FIND("z", "abc")', '#VALUE!'),
      ('=FIND("a", "abc", 5)', '#VALUE!'),
      ('=FIND("a", "abc", 0)', '#VALUE!'),
      ('=SEARCH("e", "Statements", 6)', 7),
      ('=SEARCH("margin", "Profit Margin")', 8),
      ('=SEARCH("*", "a*b")', 2),
      ('=SEARCH("x", "abc")', '#VALUE!'),
    ]);
  });

  group('Given REPLACE and SUBSTITUTE', () {
    formulaVectors(t, const [
      ('=REPLACE("abcdefghijk", 6, 5, "*")', 'abcde*k'),
      ('=REPLACE("2009", 3, 2, "10")', '2010'),
      ('=REPLACE("123456", 1, 3, "@")', '@456'),
      ('=REPLACE("abc", 10, 1, "x")', 'abcx'),
      ('=REPLACE("abc", 0, 1, "x")', '#VALUE!'),
      ('=REPLACE("abc", 1, -1, "x")', '#VALUE!'),
      ('=SUBSTITUTE("Sales Data", "Sales", "Cost")', 'Cost Data'),
      ('=SUBSTITUTE("Quarter 1, 2008", "1", "2", 1)', 'Quarter 2, 2008'),
      ('=SUBSTITUTE("Quarter 1, 2011", "1", "2", 3)', 'Quarter 1, 2012'),
      ('=SUBSTITUTE("abc", "", "x")', 'abc'),
      ('=SUBSTITUTE("aaa", "a", "b", 5)', 'aaa'),
      ('=SUBSTITUTE("aaa", "aa", "b")', 'ba'),
      ('=SUBSTITUTE("Abc", "a", "x")', 'Abc'),
      ('=SUBSTITUTE("aaa", "a", "b", 0)', '#VALUE!'),
    ]);
  });

  group('Given TEXTBEFORE and TEXTAFTER', () {
    const s = '"Little red riding hood\'s red hood"';
    formulaVectors(t, const [
      ('=TEXTBEFORE($s, "red")', 'Little '),
      ('=TEXTBEFORE($s, "red", 2)', "Little red riding hood's "),
      ('=TEXTBEFORE($s, "red", -2)', 'Little '),
      ('=TEXTBEFORE($s, "Red", , 1)', 'Little '),
      ('=TEXTBEFORE($s, "Red")', '#N/A'),
      ('=TEXTBEFORE($s, "red", 3)', '#N/A'),
      ('=TEXTBEFORE($s, "red", 3, , , "none")', 'none'),
      ('=TEXTBEFORE($s, "red", 0)', '#VALUE!'),
      ('=TEXTBEFORE("abc", "x", 1, 0, 1)', 'abc'),
      ('=TEXTBEFORE("a-b_c", {"-", "_"}, 2)', 'a-b'),
      ('=TEXTBEFORE("abc", "")', ''),
      ('=TEXTAFTER($s, "hood")', "'s red hood"),
      ('=TEXTAFTER($s, "red", 2)', ' hood'),
      ('=TEXTAFTER($s, "red", -2)', " riding hood's red hood"),
      ('=TEXTAFTER($s, "RED", , 1)', " riding hood's red hood"),
      ('=TEXTAFTER($s, "basket", 1, , , "Not found")', 'Not found'),
      ('=TEXTAFTER("abc", "x", -1, , 1)', 'abc'),
      ('=TEXTAFTER("abc", "")', 'abc'),
    ]);
  });

  group('Given CONCAT and CONCATENATE', () {
    formulaVectors(t, const [
      ('=CONCAT("de", "mystify")', 'demystify'),
      ('=CONCAT(17, 76)', '1776'),
      ('=CONCAT(TRUE, "")', 'TRUE'),
      ('=CONCAT(1, 2, 3)', '#N/A'),
      ('=CONCAT("a", 1/0)', '#DIV/0!'),
      (
        '=CONCATENATE("Welcome", " ", "to", " ", "Sheets!")',
        'Welcome to Sheets!',
      ),
      ('=CONCATENATE(A1:B3)', 'ab1cTRUE'),
      ('=CONCATENATE({1, 2; 3, 4}, "x")', '1234x'),
      ('=CONCATENATE("a", 1/0)', '#DIV/0!'),
    ]);
  });

  group('Given JOIN and TEXTJOIN', () {
    formulaVectors(t, const [
      ('=JOIN(" and-a ", {1, 2, "1 2 3 4"})', '1 and-a 2 and-a 1 2 3 4'),
      ('=JOIN("-", 1, "a", TRUE)', '1-a-TRUE'),
      ('=JOIN(",", A1:A3)', 'a,1,c'),
      ('=JOIN(",", B1:B3)', 'b,,TRUE'),
      ('=JOIN(",", {1, 2; 3, 4})', '#VALUE!'),
      ('=TEXTJOIN(" ", TRUE, "The", "", "sun")', 'The sun'),
      ('=TEXTJOIN(", ", FALSE, "a", "", "b")', 'a, , b'),
      ('=TEXTJOIN({"-", "+"}, TRUE, 1, 2, 3)', '1-2+3'),
      ('=TEXTJOIN("", TRUE, {"a", "b"})', 'ab'),
      ('=TEXTJOIN(",", TRUE, B1:B3)', 'b,TRUE'),
      ('=TEXTJOIN(",", TRUE, "a", 1/0)', '#DIV/0!'),
    ]);
  });

  group('Given SPLIT', () {
    formulaVectors(t, const [
      (
        '=SPLIT("1,2,3", ",")',
        [
          [1, 2, 3],
        ],
      ),
      (
        '=SPLIT("Alas, poor Yorick", " ,")',
        [
          ['Alas', 'poor', 'Yorick'],
        ],
      ),
      (
        '=SPLIT("a,,b", ",", TRUE, FALSE)',
        [
          ['a', '', 'b'],
        ],
      ),
      (
        '=SPLIT("a--b-c", "--", FALSE)',
        [
          ['a', 'b-c'],
        ],
      ),
      (
        '=SPLIT("50%,x", ",")',
        [
          [0.5, 'x'],
        ],
      ),
      ('=SPLIT("", ",")', '#VALUE!'),
      ('=SPLIT("a", "")', '#VALUE!'),
      (
        '=SPLIT({"a,b"; "c"}, ",")',
        [
          ['a', 'b'],
          ['c', null],
        ],
      ),
    ]);
  });

  group('Given TEXTSPLIT', () {
    formulaVectors(t, const [
      (
        '=TEXTSPLIT("Dakota Texas Alabama", " ")',
        [
          ['Dakota', 'Texas', 'Alabama'],
        ],
      ),
      (
        '=TEXTSPLIT("1,2,3;4,5,6", ",", ";")',
        [
          ['1', '2', '3'],
          ['4', '5', '6'],
        ],
      ),
      (
        '=TEXTSPLIT("a,b;c", ",", ";")',
        [
          ['a', 'b'],
          ['c', '#N/A'],
        ],
      ),
      (
        '=TEXTSPLIT("a,b;c", ",", ";", , , "-")',
        [
          ['a', 'b'],
          ['c', '-'],
        ],
      ),
      (
        '=TEXTSPLIT("a,,b", ",", , TRUE)',
        [
          ['a', 'b'],
        ],
      ),
      (
        '=TEXTSPLIT("aXb", "x", , , 1)',
        [
          ['a', 'b'],
        ],
      ),
      (
        '=TEXTSPLIT("a b-c", {" ", "-"})',
        [
          ['a', 'b', 'c'],
        ],
      ),
      (
        '=TEXTSPLIT("a;b", , ";")',
        [
          ['a'],
          ['b'],
        ],
      ),
      ('=TEXTSPLIT("abc")', '#N/A'),
      ('=TEXTSPLIT("abc", "")', '#VALUE!'),
    ]);
  });

  group('Given REGEXMATCH and REGEXTEST', () {
    formulaVectors(t, const [
      ('=REGEXMATCH("Spreadsheets", "S.r")', true),
      ('=REGEXMATCH("abc", "^b")', false),
      ('=REGEXMATCH(123, "^\\d+\$")', true),
      ('=REGEXMATCH("ABC", "(?i)abc")', true),
      ('=REGEXMATCH("a" & CHAR(10) & "b", "a.b")', false),
      ('=REGEXMATCH("a" & CHAR(10) & "b", "(?s)a.b")', true),
      ('=REGEXMATCH("x" & CHAR(10) & "ab", "(?m)^ab")', true),
      ('=REGEXMATCH("ab", "(?P<first>a)b")', true),
      ('=REGEXMATCH("é", "^[[:alpha:]]\$")', true),
      ('=REGEXMATCH("1", "^[[:alpha:]]\$")', false),
      ('=REGEXMATCH("a.b", "a\\.b")', true),
      ('=REGEXMATCH("a-b", "a\\-b")', true),
      ('=REGEXMATCH("a#b", "a\\#b")', true),
      ('=REGEXMATCH("a{b", "a{b")', true),
      ('=REGEXMATCH("aab", "a{2}b")', true),
      ('=REGEXMATCH("abc", "\\Aabc\\z")', true),
      ('=REGEXMATCH("a.b", "\\Q.\\E")', true),
      ('=REGEXMATCH("Ab", "\\pLb")', true),
      ('=REGEXMATCH("x", "(")', '#VALUE!'),
      ('=REGEXMATCH("ab", "a(?i)b")', '#VALUE!'),
      ('=REGEXTEST("Hello", "^h")', false),
      ('=REGEXTEST("Hello", "^h", 1)', true),
      ('=REGEXTEST("a", "a", 2)', '#VALUE!'),
    ]);
  });

  group('Given REGEXEXTRACT and REGEXREPLACE', () {
    formulaVectors(t, const [
      ('=REGEXEXTRACT("Needle 42 in a haystack", "\\d+")', '42'),
      ('=REGEXEXTRACT("x@y.com", "@(.+)")', 'y.com'),
      (
        '=REGEXEXTRACT("abc123def", "(\\d)(\\d)")',
        [
          ['1', '2'],
        ],
      ),
      ('=REGEXEXTRACT("ab", "a(x)?")', ''),
      ('=REGEXEXTRACT("abc", "\\d")', '#N/A'),
      (
        '=ARRAYFORMULA(REGEXEXTRACT({"a1"; "b22"}, "\\d+"))',
        [
          ['1'],
          ['22'],
        ],
      ),
      ('=REGEXREPLACE("Spreadsheets", "S.*d", "Bed")', 'Bedsheets'),
      (
        '=REGEXREPLACE("John Smith", "(\\w+) (\\w+)", "\$2, \$1")',
        'Smith, John',
      ),
      ('=REGEXREPLACE("a1b2", "\\d", "")', 'ab'),
      ('=REGEXREPLACE("cost", "^", "\\\$")', '\$cost'),
      ('=REGEXREPLACE("ab", "(a)", "[\$0]")', '[a]b'),
      ('=REGEXREPLACE("ab", "(", "x")', '#VALUE!'),
    ]);
  });

  group('Given TEXT, DOLLAR and FIXED', () {
    formulaVectors(t, const [
      ('=TEXT(1234.567, "\$#,##0.00")', '\$1,234.57'),
      ('=TEXT(0.285, "0.0%")', '28.5%'),
      ('=TEXT(DATE(2024, 3, 5), "yyyy-mm-dd")', '2024-03-05'),
      ('=TEXT("2024-03-05", "mmm d")', 'Mar 5'),
      ('=TEXT("abc", "0.00")', 'abc'),
      ('=TEXT(4.34, "# ?/?")', '4 1/3'),
      ('=TEXT(TRUE, "0")', 'TRUE'),
      ('=TEXT(1, "[Red")', '#VALUE!'),
      ('=DOLLAR(1234.567)', '\$1,234.57'),
      ('=DOLLAR(1234.567, -2)', '\$1,200'),
      ('=DOLLAR(-1234.567, -2)', '-\$1,200'),
      ('=DOLLAR(-0.123, 4)', '-\$0.1230'),
      ('=DOLLAR(99.888)', '\$99.89'),
      ('=DOLLAR(1, 128)', '#VALUE!'),
      ('=FIXED(1234.567, 1)', '1,234.6'),
      ('=FIXED(1234.567, -1)', '1,230'),
      ('=FIXED(-1234.567, -1, TRUE)', '-1230'),
      ('=FIXED(44.332)', '44.33'),
      ('=FIXED("x")', '#VALUE!'),
    ]);
  });

  group('Given VALUE and NUMBERVALUE', () {
    formulaVectors(t, const [
      ('=VALUE("\$1,000")', 1000),
      ('=VALUE("16:48:00") - VALUE("12:00:00")', 0.2),
      ('=VALUE("12%")', 0.12),
      ('=VALUE("2024-01-15")', 45306),
      ('=VALUE(12)', 12),
      ('=VALUE("abc")', '#VALUE!'),
      ('=VALUE(TRUE)', '#VALUE!'),
      ('=NUMBERVALUE("2.500,27", ",", ".")', 2500.27),
      ('=NUMBERVALUE("3.5%")', 0.035),
      ('=NUMBERVALUE("12%%")', 0.0012),
      ('=NUMBERVALUE(" 1 000 ")', 1000),
      ('=NUMBERVALUE("1,234.5")', 1234.5),
      ('=NUMBERVALUE("")', 0),
      ('=NUMBERVALUE("1.2.3")', '#VALUE!'),
      ('=NUMBERVALUE("1.2,3")', '#VALUE!'),
      ('=NUMBERVALUE("1,5", ",", ",")', '#VALUE!'),
      ('=NUMBERVALUE("abc")', '#VALUE!'),
    ]);
  });

  group('Given VALUETOTEXT and ARRAYTOTEXT', () {
    formulaVectors(t, const [
      ('=VALUETOTEXT("Hello")', 'Hello'),
      ('=VALUETOTEXT("Hello", 1)', '"Hello"'),
      ('=VALUETOTEXT(1/0) = "#DIV/0!"', true),
      ('=ISTEXT(VALUETOTEXT(1/0))', true),
      ('=VALUETOTEXT(TRUE)', 'TRUE'),
      ('=VALUETOTEXT(1.5)', '1.5'),
      ('=VALUETOTEXT(1, 2)', '#VALUE!'),
      ('=ARRAYTOTEXT({1, "a"; TRUE, 2})', '1, a, TRUE, 2'),
      ('=ARRAYTOTEXT({1, "a"; TRUE, 2}, 1)', '{1,"a";TRUE,2}'),
      ('=ARRAYTOTEXT(A1:B2)', 'a, b, 1, '),
    ]);
  });

  group('Given text functions in array mode', () {
    formulaVectors(t, const [
      (
        '=ARRAYFORMULA(LEN(A1:A3))',
        [
          [1],
          [1],
          [1],
        ],
      ),
      (
        '=ARRAYFORMULA(UPPER({"a", "b"}))',
        [
          ['A', 'B'],
        ],
      ),
      (
        '=ARRAYFORMULA(TEXTBEFORE({"a-b"; "c-d"}, "-"))',
        [
          ['a'],
          ['c'],
        ],
      ),
    ]);
  });
}
