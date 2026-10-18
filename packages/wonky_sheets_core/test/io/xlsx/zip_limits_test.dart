import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:wonky_sheets_core/model.dart';

import '../support/ooxml_builder.dart';

/// A zip of [parts] (stored as deflate).
Uint8List _zip(Map<String, String> parts) {
  final archive = Archive();
  for (final e in parts.entries) {
    archive.addFile(ArchiveFile.string(e.key, e.value));
  }
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

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

void main() {
  group('Given a zip package (W-06 / zip bombs)', () {
    test('when its parts declare more than the unpacked limit then opening '
        'it is refused before anything is inflated', () {
      final bytes = _zip({'a.xml': 'x' * 4000, 'b.xml': 'y' * 4000});

      expect(
        () => ZipPackage.open(bytes, maxUnpackedBytes: 6000),
        throwsA(
          isA<XlsxFormatException>().having(
            (e) => e.message,
            'message',
            contains('too large to import'),
          ),
        ),
      );
      expect(
        ZipPackage.open(bytes, maxUnpackedBytes: 8000).names,
        hasLength(2),
      );
    });

    test('when it has more entries than allowed then opening it is '
        'refused', () {
      final bytes = _zip({for (var i = 0; i < 5; i++) '$i.xml': '<a/>'});

      expect(
        () => ZipPackage.open(bytes, maxEntries: 4),
        throwsA(
          isA<XlsxFormatException>().having(
            (e) => e.message,
            'message',
            contains('more than 4 parts'),
          ),
        ),
      );
    });

    test('when an XLSX sheet part declares 4 GB then the import is refused '
        'with a clear error', () {
      final xlsx = _declare(
        buildXlsx([const TestSheet('Sheet1')]),
        'xl/worksheets/sheet1.xml',
        0xFFFFFFF0,
      );

      expect(
        () => XlsxImporter.import(xlsx),
        throwsA(
          isA<XlsxFormatException>().having(
            (e) => e.message,
            'message',
            contains('unpacks to more than 256 MB'),
          ),
        ),
      );
      expect(
        () => XlsxImporter.listSheets(xlsx),
        throwsA(isA<XlsxFormatException>()),
      );
    });

    test('when an ODS content part declares 4 GB then the import is '
        'refused', () {
      final ods = _declare(
        _zip({
          'mimetype': 'application/vnd.oasis.opendocument.spreadsheet',
          'content.xml': '<office:document-content/>',
        }),
        'content.xml',
        0xFFFFFFF0,
      );

      expect(
        () => OdsImporter.import(ods),
        throwsA(
          isA<XlsxFormatException>().having(
            (e) => e.message,
            'message',
            contains('too large to import'),
          ),
        ),
      );
    });

    test('when a part inflates past the size it declares then reading it '
        'fails instead of growing', () {
      final pkg = ZipPackage.open(
        _declare(_zip({'a.xml': 'x' * 100000}), 'a.xml', 10),
      );

      expect(() => pkg.bytes('a.xml'), throwsA(isA<XlsxFormatException>()));
    });
  });
}
