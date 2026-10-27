import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../export/export_support.dart';

ImportOptions opts() {
  var n = 0;
  return ImportOptions(idGenerator: () => 'e${n++}');
}

Uint8List bytesOf(String rtf) => Uint8List.fromList(latin1.encode(rtf));

List<RtfToken> tokens(String rtf) => RtfTokenizer(bytesOf(rtf)).tokenize();

String textOf(String rtf) =>
    tokens(rtf).whereType<RtfText>().map((t) => t.text).join();

ImportResult import(String rtf) =>
    const RtfImporter().importSync(bytesOf(rtf), opts());

String hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// An RTF in the style Microsoft Word writes it (stylesheet headings,
/// list table + `\listtext`, fields, `\trhdr` table, `\shppict` picture,
/// footnote, annotation, header, page size and `\info`).
String wordFixture(String pngHex) =>
    r'''{\rtf1\ansi\ansicpg1252\deff0\deflang1033{\fonttbl{\f0\froman\fcharset0 Times New Roman;}{\f1\fmodern\fcharset0 Courier New;}{\f2\fswiss\fcharset0 Calibri;}{\f3\fnil\fcharset2 Symbol;}}
{\colortbl;\red0\green0\blue0;\red5\green99\blue193;}
{\*\defchp \f2}
{\stylesheet{\ql \li0\ri0\widctlpar\f2\fs22 \snext0 Normal;}{\s1\ql\keepn\outlinelevel0\b\f2\fs32\cf1 \sbasedon0 \snext0 heading 1;}{\s2\ql\keepn\outlinelevel1\b\f2\fs26 \sbasedon0 \snext0 heading 2;}{\*\cs10 \additive \ssemihidden Default Paragraph Font;}{\*\cs15 \additive \ul\cf2 \sbasedon10 Hyperlink;}{\s16\ql\li720\i\f2\fs22 \sbasedon0 \snext16 Quote;}}
{\*\listtable{\list\listtemplateid1{\listlevel\levelnfc23\levelnfcn23\leveljc0\levelfollow0\levelstartat1{\leveltext\'01\u-3913 ?;}{\levelnumbers;}\f3\fi-360\li720}{\listlevel\levelnfc23\levelfollow0\levelstartat1{\leveltext\'01o;}{\levelnumbers;}\f1\fi-360\li1440}\listid100}{\list\listtemplateid2{\listlevel\levelnfc0\levelnfcn0\levelfollow0\levelstartat1{\leveltext\'02\'00.;}{\levelnumbers\'01;}\fi-360\li720}\listid200}}
{\*\listoverridetable{\listoverride\listid100\listoverridecount0\ls1}{\listoverride\listid200\listoverridecount0\ls2}}
{\info{\title Word Fixture}{\author Someone}{\creatim\yr2026\mo1\dy2}}
\paperw11906\paperh16838\margl1134\margr1134\margt1417\margb1134
{\header \pard\plain \s20 Header text\par}
{\*\generator Microsoft Word 16;}
\pard\plain \s1\ql\keepn\outlinelevel0\rtlch\fcs1 \ab\af0 \ltrch\fcs0 \b\f2\fs32\cf1 {\rtlch\fcs1 \ab \ltrch\fcs0 \b\insrsid1 Caf\'e9 heading}\par
\pard\plain \ql \f2\fs22 {Plain }{\b bold}{ and }{\i italic}{ and }{\strike gone}{ and }{\f1 mono}{.}{\cs16\super\chftn {\footnote \pard\plain \s17\f2\fs20 {\cs16\super\chftn } A note.}}\par
\pard\plain \s2\ql\keepn\outlinelevel1\b\f2\fs26 Sub\par
\pard\plain \ql\fi-360\li720\ls1\ilvl0\f2\fs22 {\listtext\pard\plain \f3 \'b7\tab}Bullet one\par
{\listtext\pard\plain \f1 o\tab}\pard\plain \ql\fi-360\li1440\ls1\ilvl1\f2\fs22 Nested\par
\pard\plain \ql\fi-360\li720\ls2\ilvl0\f2\fs22 {\listtext 1.\tab}Number one\par
\pard\plain \ql \f2\fs22 See {\field{\*\fldinst {HYPERLINK "https://example.com/" }{\*\datafield 00d0c9ea}}{\fldrslt {\cs15\ul\cf2 the site}}} and {\field{\*\fldinst PAGE}{\fldrslt 7}}.{\*\atrfstart 1}x{\*\atrfend 1}{\*\atnid A}{\*\atnauthor A}{\*\annotation hidden comment}\par
\pard\plain \s16\ql\li720\i\f2\fs22 Quoted\par
\pard\plain \ql\f1\fs20 int x = 1;\par
\pard\plain \ql\f1\fs20 int y = 2;\par
\trowd\trgaph108\trhdr\cellx3000\cellx6000
\pard\plain\intbl\ql\b H1\cell\pard\plain\intbl\qr\b H2\cell\row
\trowd\trgaph108\cellx3000\cellx6000
\pard\plain\intbl a\cell\pard\plain\intbl b\cell\row
\pard\plain \qc {\*\shppict{\pict{\*\picprop{\sp{\sn wzDescription}{\sv A logo}}}\pngblip\picw4\pich2 '''
    '$pngHex'
    r'''}}{\nonshppict{\pict\wmetafile8\picw4\pich2 0102}}\par
\pard\plain {\pict\wmetafile8\picw10\pich10 010009000003}\par
\pard\plain \u9744?\tab Todo\par
}''';

void main() {
  group('Given the RTF tokenizer', () {
    test('when reading control words then names, parameters and the '
        'delimiter space are split', () {
      expect(tokens(r'{\b0 x\fs-24 y\par}'), [
        const RtfGroupStart(),
        const RtfControl('b', 0),
        const RtfText('x'),
        const RtfControl('fs', -24),
        const RtfText('y'),
        const RtfControl('par'),
        const RtfGroupEnd(),
      ]);
    });

    test('when reading control symbols then escapes become text and \\* a '
        'symbol', () {
      expect(tokens(r'{\*\x}\{\}\\\~'), [
        const RtfGroupStart(),
        const RtfControl('*', null, true),
        const RtfControl('x'),
        const RtfGroupEnd(),
        const RtfText('{}\\\u00A0'),
      ]);
    });

    test('when a backslash ends a line then it is a paragraph mark', () {
      expect(tokens('a\\\nb'), [
        const RtfText('a'),
        const RtfControl('par'),
        const RtfText('b'),
      ]);
    });

    for (final (cp, expected) in [(1252, 'é'), (1251, 'й'), (1250, 'é')]) {
      test("when decoding \\'e9 with \\ansicpg$cp then it is $expected", () {
        expect(textOf('{\\rtf1\\ansi\\ansicpg$cp \\\'e9}'), expected);
      });
    }

    test("when a font has \\fcharset204 then \\'hh in that font uses 1251", () {
      const rtf =
          r"{\rtf1\ansi\ansicpg1252{\fonttbl{\f0 Arial;}{\f1\fcharset204 "
          r"Arial Cyr;}}\f0\'e9{\f1\'e9}\'e9}";

      expect(textOf(rtf), endsWith('éйé'));
    });

    test('when a code page is not built in then bytes fall back to 1252 '
        'and the page is reported', () {
      final t = RtfTokenizer(bytesOf(r"{\rtf1\ansi\ansicpg932 \'e9}"));

      expect(t.tokenize().whereType<RtfText>().single.text, 'é');
      expect(t.unsupportedCodePages, {932});
    });

    for (final (rtf, expected) in [
      (r'\uc1\u33636?x', '荤x'),
      (r"\uc2\u33636\'a1\'a2y", '荤y'),
      (r'\uc0\u33636 z', '荤z'),
      (r'\u-10179?\u-8704?', '😀'),
      (r'{\uc2\u33636}ab', '荤ab'),
    ]) {
      test('when reading "$rtf" then the fallback is skipped', () {
        expect(textOf(rtf), expected);
      });
    }

    test('when reading \\bin then the raw bytes are one binary token', () {
      final bytes = Uint8List.fromList([
        ...latin1.encode(r'{\pict\bin4 '),
        0x7B,
        0x7D,
        0x5C,
        0x00,
        ...latin1.encode('}'),
      ]);

      final t = RtfTokenizer(bytes).tokenize();

      expect(
        t.whereType<RtfBinary>().single,
        RtfBinary(Uint8List.fromList([0x7B, 0x7D, 0x5C, 0x00])),
      );
      expect(t.last, const RtfGroupEnd());
    });
  });

  group('Given bytes that are not RTF', () {
    test('when importing then an ImportFormatException is thrown', () {
      expect(
        () => const RtfImporter().importSync(bytesOf('hello'), opts()),
        throwsA(isA<ImportFormatException>()),
      );
    });
  });

  group('Given a Word-style RTF document', () {
    late ImportResult r;
    setUp(() => r = import(wordFixture(hex(pngBytes()))));

    test('when importing then the content maps to the delta schema', () {
      expect(CellCanon.canonical(r.delta).toJson(), [
        {'insert': 'Café heading'},
        {
          'insert': '\n',
          'attributes': {'header': 1},
        },
        {'insert': 'Plain '},
        {
          'insert': 'bold',
          'attributes': {'bold': true},
        },
        {'insert': ' and '},
        {
          'insert': 'italic',
          'attributes': {'italic': true},
        },
        {'insert': ' and '},
        {
          'insert': 'gone',
          'attributes': {'strike': true},
        },
        {'insert': ' and '},
        {
          'insert': 'mono',
          'attributes': {'code': true},
        },
        {'insert': '.[1]\nSub'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
        {'insert': 'Bullet one'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'Nested'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet', 'indent': 1},
        },
        {'insert': 'Number one'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
        {'insert': 'See '},
        {
          'insert': 'the site',
          'attributes': {'link': 'https://example.com/'},
        },
        {'insert': ' and 7.x\nQuoted'},
        {
          'insert': '\n',
          'attributes': {'blockquote': true},
        },
        {'insert': 'int x = 1;'},
        {
          'insert': '\n',
          'attributes': {'code-block': ''},
        },
        {'insert': 'int y = 2;'},
        {
          'insert': '\n',
          'attributes': {'code-block': ''},
        },
        {'insert': 'H1'},
        {
          'insert': '\n',
          'attributes': {
            'cell': {'table': 'e0', 'row': 'r0', 'align': 'left'},
          },
        },
        {'insert': 'H2'},
        {
          'insert': '\n',
          'attributes': {
            'cell': {'table': 'e0', 'row': 'r0', 'align': 'right'},
          },
        },
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {
            'cell': {'table': 'e0', 'row': 'r1', 'align': 'left'},
          },
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {
            'cell': {'table': 'e0', 'row': 'r1', 'align': 'right'},
          },
        },
        {
          'insert': {
            'image': {
              'id': 'e1',
              'src': 'import-image://img1',
              'alt': 'A logo',
            },
          },
        },
        {'insert': '\n[image]\nTodo'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
        {'insert': 'Notes'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
        {'insert': 'A note.'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
      ]);
    });

    test('when importing then the png picture is collected', () {
      expect(r.images.single.mime, 'image/png');
      expect(r.images.single.bytes, pngBytes());
    });

    test('when importing then title and page setup come from the file', () {
      expect(r.title, 'Word Fixture');
      expect(r.pageSetup?.widthPt, closeTo(595.3, 0.01));
      expect(r.pageSetup?.heightPt, closeTo(841.9, 0.01));
      expect(r.pageSetup?.marginTopPt, closeTo(70.85, 0.01));
    });

    test('when importing then dropped content is reported', () {
      expect(
        r.warnings.map((w) => w.kind),
        containsAll([
          ImportWarningKind.footnotesAppended,
          ImportWarningKind.commentsDropped,
          ImportWarningKind.headersFootersDropped,
          ImportWarningKind.unresolvedImage,
        ]),
      );
    });
  });

  group('Given a WordPad-style RTF document', () {
    test('when importing \\pn lists then bullets and numbers are '
        'recognized', () {
      const rtf =
          r'''{\rtf1\ansi\deff0{\fonttbl{\f0\fnil Calibri;}{\f1\fnil\fcharset2 Symbol;}}
\pard{\pntext\f1\'B7\tab}{\*\pn\pnlvlblt\pnf1\pnindent0{\pntxtb\'B7}}\fi-720\li720\f0 Dot\par
{\pntext\f0 1.\tab}{\*\pn\pnlvlbody\pnf0\pnindent0\pnstart1\pndec{\pntxta.}}\fi-720\li720 Num\par
\pard Plain\par
}''';

      expect(import(rtf).delta.toJson(), [
        {'insert': 'Dot'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'Num'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
        {'insert': 'Plain\n'},
      ]);
    });
  });

  group('Given a TextEdit-style RTF document', () {
    test('when importing then toggles, links, lists and line-end '
        'paragraphs are read', () {
      const rtf = r'''{\rtf1\ansi\ansicpg1252\cocoartf2870
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;\f1\fmodern\fcharset0 Courier;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
{\*\listtable{\list\listtemplateid1\listhybrid{\listlevel\levelnfc23\levelnfcn23\leveljc0\leveljcn0\levelfollow0\levelstartat1\levelspace360\levelindent0{\*\levelmarker \{disc\}}{\leveltext\leveltemplateid1\'01\uc0\u8226 ;}{\levelnumbers;}\fi-360\li720\lin720 }{\listname ;}\listid1}}
{\*\listoverridetable{\listoverride\listid1\listoverridecount0\ls1}}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx566\pardirnatural\partightenfactor0

\f0\fs24 \cf0 Hello \b bold\b0  {\field{\*\fldinst{HYPERLINK "https://x.org/"}}{\fldrslt link}}\
\pard\tx220\tx720\pardeftab720\li720\fi-720\partightenfactor0
\ls1\ilvl0\cf0 {\listtext	\uc0\u8226 	}item\
\pard\pardeftab720\partightenfactor0

\f1 \cf0 code\
}''';

      expect(import(rtf).delta.toJson(), [
        {'insert': 'Hello '},
        {
          'insert': 'bold',
          'attributes': {'bold': true},
        },
        {'insert': ' '},
        {
          'insert': 'link',
          'attributes': {'link': 'https://x.org/'},
        },
        {'insert': '\nitem'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'code'},
        {
          'insert': '\n',
          'attributes': {'code-block': ''},
        },
      ]);
    });
  });

  group('Given damaged RTF', () {
    test('when braces are unbalanced then the text is still imported', () {
      final r = import(r'{\rtf1 {\b one}} two\par}}} {three');

      expect(CellCanon.canonical(r.delta).toJson(), [
        {
          'insert': 'one',
          'attributes': {'bold': true},
        },
        {'insert': '\n two\n three\n'},
      ]);
    });

    test('when unknown starred destinations appear then they are '
        'skipped', () {
      final r = import(r'{\rtf1 a{\*\unknown {nested} text}b\par}');

      expect(CellCanon.canonical(r.delta).toJson(), [
        {'insert': 'ab\n'},
      ]);
    });
  });

  group('Given a document exported by RtfExporter', () {
    test('when importing it then the source delta is reproduced', () async {
      final logo = ResolvedImage(
        bytes: pngBytes(),
        mime: 'image/png',
        widthPx: 4,
        heightPx: 2,
      );
      final source = md(sample);
      final exported = await const RtfExporter().export(
        input(source, images: {'https://img.example.com/logo.png': logo}),
        const RtfExportOptions(),
      );

      final r = const RtfImporter().importSync(exported.bytes, opts());

      expect(
        jsonEncode(
          CellCanon.canonical(r.delta).toJson(),
        ).replaceAll('import-image://img1', 'https://img.example.com/logo.png'),
        jsonEncode(CellCanon.canonical(source).toJson()),
      );
      expect(r.title, 'Q3 planning');
    });

    test('when it has nested lists, tasks, mentions and escapes then they '
        'round trip', () async {
      const markdown = '''# Héllo 😀 {braces} \\\\back

**bold *both*** [**bold link**](https://example.com/a?b=1&c=2) `a{b}` and [@Anna](mailto:anna@example.com "wonky-mention:0192aaaa-0000-7000-8000-00000000000a")

1. one
   1. sub one
2. two

Between.

1. restart
   - bullet
     - [ ] deep task

> line one

```
\ttab line

after empty
```

| Left | Center | Plain |
| :--- | :---: | --- |
| *i* | `c` | [l](https://x.org) |
''';
      final source = md(markdown);
      final exported = await const RtfExporter().export(
        input(source),
        const RtfExportOptions(),
      );

      final r = const RtfImporter().importSync(exported.bytes, opts());

      expect(
        jsonEncode(CellCanon.canonical(r.delta).toJson()),
        jsonEncode(CellCanon.canonical(source).toJson()),
      );
    });
  });
}
