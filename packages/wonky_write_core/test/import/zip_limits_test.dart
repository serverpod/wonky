import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:wonky_write_core/src/import/xml_support.dart' show ZipPackage;
import 'package:wonky_write_core/wonky_write_core.dart';

/// [zip] with the central-directory entry of [name] declaring [size]
/// uncompressed bytes (what a zip bomb's directory says).
Uint8List _declare(Uint8List zip, String name, int size) {
  final out = Uint8List.fromList(zip);
  final data = ByteData.sublistView(out);
  for (var i = 0; i + 46 <= out.length; i++) {
    if (data.getUint32(i, Endian.little) != 0x02014b50) continue;
    final nameLength = data.getUint16(i + 28, Endian.little);
    final entry = String.fromCharCodes(
      out.sublist(i + 46, i + 46 + nameLength),
    );
    if (entry == name) {
      data.setUint32(i + 24, size, Endian.little);
      return out;
    }
  }
  throw StateError('$name is not in the zip');
}

const _docx = {
  '[Content_Types].xml':
      '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/'
      'package/2006/content-types"/>',
  'word/document.xml':
      '<w:document xmlns:w="http://schemas.openxmlformats.org/'
      'wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Hi</w:t></w:r>'
      '</w:p></w:body></w:document>',
};

Uint8List _zip(Map<String, String> parts) => DeterministicZip.encode([
  for (final e in parts.entries) ZipEntry.text(e.key, e.value),
]);

Matcher _tooLarge(ImportLimitKind kind) => throwsA(
  isA<ImportTooLargeException>()
      .having((e) => e.kind, 'kind', kind)
      .having((e) => e.message, 'message', contains('too large to import')),
);

void main() {
  group('Given a ZIP-based import (W-06 / zip bombs)', () {
    test('when a DOCX part declares 4 GB then the import is refused before '
        'it is inflated', () {
      final bytes = _declare(_zip(_docx), 'word/document.xml', 0xFFFFFFF0);

      expect(
        () => const WonkyImporters().import(
          bytes,
          ImportOptions(fileName: 'bomb.docx'),
        ),
        _tooLarge(ImportLimitKind.unpackedBytes),
      );
    });

    test('when an ODT content part declares 4 GB then the import is '
        'refused', () {
      final bytes = _declare(
        _zip({
          'mimetype': 'application/vnd.oasis.opendocument.text',
          'content.xml': '<office:document-content/>',
        }),
        'content.xml',
        0xFFFFFFF0,
      );

      expect(
        () => const OdtImporter().importSync(bytes, ImportOptions()),
        _tooLarge(ImportLimitKind.unpackedBytes),
      );
    });

    test('when a Markdown zip declares 4 GB then the import is refused', () {
      final bytes = _declare(
        _zip({'notes.md': '# Hi', 'big.png': 'x' * 100}),
        'big.png',
        0xFFFFFFF0,
      );

      expect(
        () => const WonkyImporters().import(
          bytes,
          ImportOptions(fileName: 'notes.zip'),
        ),
        _tooLarge(ImportLimitKind.unpackedBytes),
      );
    });

    test('when the package has more entries than allowed then it is '
        'refused', () {
      final archive = ZipDecoder().decodeBytes(
        _zip({for (var i = 0; i < 5; i++) '$i.xml': '<a/>'}),
      );

      expect(
        () => const ArchiveLimits(maxEntries: 4).check(archive),
        _tooLarge(ImportLimitKind.archiveEntries),
      );
      expect(
        () => const ArchiveLimits(maxUnpackedBytes: 19).check(archive),
        _tooLarge(ImportLimitKind.unpackedBytes),
      );
      const ArchiveLimits(maxUnpackedBytes: 20, maxEntries: 5).check(archive);
    });

    test('when a part inflates past the size it declares then it is not '
        'read in full', () {
      final bytes = _declare(
        _zip({..._docx, 'word/document.xml': 'x' * 100000}),
        'word/document.xml',
        10,
      );
      final pkg = ZipPackage.open(bytes)!;

      // The archive stops at the declared size; the part reads as missing.
      expect(pkg.bytes('word/document.xml'), isNull);
    });

    test(
      'when a normal DOCX is imported then the limits let it through',
      () async {
        final r = await const WonkyImporters().import(
          _zip(_docx),
          ImportOptions(fileName: 'ok.docx'),
        );

        expect(r.delta.toJson().first['insert'], contains('Hi'));
      },
    );
  });
}
