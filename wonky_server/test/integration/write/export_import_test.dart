@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/write/export/server_fonts.dart';
import 'package:wonky_server/src/write/export/server_images.dart';
import 'package:wonky_server/src/write/export/write_export_service.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// A 3×2 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAIAAAASFvFNAAAAEklEQVR4nGORq7jDAAYsDDAAABnSAXu4ADnlAAAAAElFTkSuQmCC',
);

Future<Uint8List> _bytesOf(Session session, ExportResultView r) async {
  final files = await StoredFile.db.find(
    session,
    where: (t) => t.kind.equals(StoredFileKind.exportResult),
  );
  files.sort((a, b) => a.id!.compareTo(b.id!));
  final file = files.lastOrNull;
  final data = await FileService.readBytes(session, file!);
  expect(data.lengthInBytes, r.sizeBytes);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

Future<Delta> _content(
  TestEndpoints endpoints,
  TestUser user,
  UuidValue documentUuid,
) async {
  final snapshot = await endpoints.document.getSnapshot(
    user.endpointSession,
    documentUuid,
    null,
  );
  return Delta.fromJson(jsonDecode(snapshot.deltaJson) as List);
}

Future<UuidValue> _upload(
  TestUser user,
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) async {
  final file = await FileService.storeServerFile(
    user.session,
    ownerId: user.id,
    kind: StoredFileKind.importSource,
    fileName: fileName,
    mimeType: mimeType,
    bytes: bytes,
  );
  return file.fileUuid;
}

void main() {
  withWonkyServerpod('Given a document with images', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView item;
    late UuidValue imageUuid;

    setUp(() async {
      WriteExportService.fetchRemoteImage = (src) async => _png;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final image = await FileService.storeServerFile(
        anna.session,
        ownerId: anna.id,
        kind: StoredFileKind.image,
        fileName: 'dot.png',
        mimeType: 'image/png',
        bytes: _png,
      );
      imageUuid = image.fileUuid;
      item = await TestDrive.document(
        endpoints,
        anna,
        name: 'Report',
        markdown:
            '# Report\n\nПривет, κόσμε — **bold** and a [link](https://example.com).\n\n'
            '- one\n- two\n\n![Stored](wonky-file://${imageUuid.uuid})\n\n'
            '![Remote](https://images.example.com/r.png)\n\n'
            '| A | B |\n| --- | ---: |\n| 1 | 2 |\n',
      );
    });

    tearDown(() {
      WriteExportService.fetchRemoteImage = SafeImageFetcher.fetch;
    });

    for (final format in [
      'md',
      'md_zip',
      'pdf',
      'html',
      'html_zip',
      'docx',
      'odt',
      'rtf',
      'epub',
      'txt',
    ]) {
      test('when exporting as $format then a file is produced', () async {
        final r = await endpoints.writeExport.export(
          anna.endpointSession,
          item.contentRef!,
          format,
          '{}',
          null,
        );

        final f = ExportFormat.fromMcpName(format)!;
        expect(r.fileName, 'Report.${f.extension}');
        expect(r.mimeType, f.mimeType);
        expect(r.sizeBytes, greaterThan(0));
        expect(r.downloadUrl, isNotEmpty);
        expect(
          r.warnings.where((w) => w.kind == 'image_unavailable'),
          isEmpty,
          reason: r.warnings.map((w) => w.message).join(', '),
        );
        final bytes = await _bytesOf(anna.session, r);
        switch (format) {
          case 'md' || 'txt':
            expect(r.inlineText, contains('Привет'));
          case 'pdf':
            expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
            expect(r.pageCount, greaterThanOrEqualTo(1));
            expect(r.warnings.where((w) => w.kind == 'font_fallback'), isEmpty);
          case 'html':
            expect(utf8.decode(bytes), contains('data:image/png;base64,'));
          case 'docx':
            final files = DeterministicZip.decode(bytes);
            expect(files.keys, contains('word/document.xml'));
            expect(
              files.keys.where((k) => k.startsWith('word/media/')),
              hasLength(2),
            );
          case 'rtf':
            expect(latin1.decode(bytes.sublist(0, 5)), r'{\rtf');
          default:
            expect(DeterministicZip.decode(bytes), isNotEmpty);
        }
      });
    }

    test(
      'when exporting with the progress API then it ends with done',
      () async {
        final events = await endpoints.writeExport
            .exportWithProgress(
              anna.endpointSession,
              item.contentRef!,
              'docx',
              '{"includeToc": true}',
              null,
            )
            .toList();
        expect(events.last.kind, ExportProgressKind.done);
        expect(events.last.result!.fileName, 'Report.docx');
      },
    );

    test('when the format is unknown then the export is rejected', () async {
      await expectLater(
        endpoints.writeExport.export(
          anna.endpointSession,
          item.contentRef!,
          'xls',
          '{}',
          null,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when a viewer exports with downloads disabled then it is forbidden',
      () async {
        final ben = await TestUsers.create(sessionBuilder, name: 'Ben');
        await TestDrive.share(endpoints, item, anna, ben, AccessRole.viewer);
        await endpoints.sharing.updateSettings(
          anna.endpointSession,
          item.uuid,
          ItemSharingSettings(
            editorsCanShare: true,
            nonEditorsCanExport: false,
            viewersSeeComments: true,
          ),
        );
        await expectLater(
          endpoints.writeExport.export(
            ben.endpointSession,
            item.contentRef!,
            'pdf',
            '{}',
            null,
          ),
          throwsA(isA<WonkyException>()),
        );
      },
    );
  });

  withWonkyServerpod('Given files to import', (sessionBuilder, endpoints) {
    late TestUser anna;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });

    Future<Uint8List> docx(
      String markdown, {
      Map<String, ResolvedImage>? images,
    }) async {
      var n = 0;
      final delta = const MarkdownCodec()
          .importMarkdown(
            markdown,
            options: ImportOptions(idGenerator: () => 'x${n++}'),
          )
          .delta;
      final a = await const DocxExporter().export(
        ExportInput(
          document: delta,
          meta: const DocMeta(title: 'From Word', language: 'en-GB'),
          theme: BuiltinThemes.wonkyDefault.theme,
          pageSetup: const PageSetup(paper: PaperSize.a4),
          images: MapImageResolver(images ?? const {}),
          fonts: FileSystemFontProvider.instance,
          now: DateTime.utc(2026),
        ),
        const OfficeExportOptions(),
      );
      return a.bytes;
    }

    test(
      'when importing a DOCX then content, images, language and page setup are kept',
      () async {
        final bytes = await docx(
          '# Plan\n\nSome **bold** text.\n\n1. a\n2. b\n\n![Dot](https://x.example/d.png)\n',
          images: {
            'https://x.example/d.png': ServerImageResolver.describe(_png)!,
          },
        );
        final upload = await _upload(anna, 'plan.docx', bytes);

        final report = await endpoints.drive.import(
          anna.endpointSession,
          upload,
          DriveItemKind.document,
          DriveImportOptions(),
        );

        expect(report.item.name, 'From Word');
        final content = await _content(
          endpoints,
          anna,
          report.item.contentRef!,
        );
        final md = const MarkdownCodec().exportMarkdown(content);
        expect(
          md,
          startsWith(
            '# Plan\n\nSome **bold** text.\n\n1. a\n2. b\n\n![Dot](wonky-file://',
          ),
        );
        final imageUuid = RegExp(
          r'wonky-file://([0-9a-f-]+)',
        ).firstMatch(md)!.group(1)!;
        final stored = await FileService.byUuid(
          anna.session,
          UuidValue.withValidation(imageUuid),
        );
        final doc = await Document.db.findFirstRow(
          anna.session,
          where: (t) => t.uuid.equals(report.item.contentRef!),
        );
        expect(stored!.itemId, doc!.itemId);
        expect(doc.language, 'en-GB');
        final setup = PageSetup.fromJson(
          jsonDecode(doc.pageSetupJson) as Map<String, dynamic>,
        );
        expect(setup.paper, PaperSize.a4);

        final info = await endpoints.document.getInfo(
          anna.endpointSession,
          report.item.contentRef!,
        );
        expect(
          info.importWarnings?.map((w) => w.kind),
          contains('headersFootersDropped'),
        );
      },
    );

    test('when importing HTML then headings and formatting are kept', () async {
      final upload = await _upload(
        anna,
        'page.html',
        Uint8List.fromList(
          utf8.encode(
            '<!doctype html><html lang="fr"><title>Page</title><h1>Bonjour</h1>'
            '<p><b>gras</b> <i>it</i></p><ul><li>x</li></ul></html>',
          ),
        ),
      );

      final report = await endpoints.drive.import(
        anna.endpointSession,
        upload,
        DriveItemKind.document,
        DriveImportOptions(),
      );

      final content = await _content(endpoints, anna, report.item.contentRef!);
      expect(
        const MarkdownCodec().exportMarkdown(content),
        '# Bonjour\n\n**gras** *it*\n\n- x\n',
      );
      expect(report.item.name, 'Page');
    });

    test('when importing an unsupported file then it is rejected', () async {
      final upload = await _upload(
        anna,
        'sheet.xlsx',
        Uint8List.fromList([1, 2, 3]),
      );
      await expectLater(
        endpoints.drive.import(
          anna.endpointSession,
          upload,
          DriveItemKind.document,
          DriveImportOptions(),
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when converting a DOCX for insertion then the delta has stored images',
      () async {
        final target = await TestDrive.document(endpoints, anna, name: 'T');
        final bytes = await docx(
          'Inserted *text*\n\n![Dot](https://x.example/d.png)\n',
          images: {
            'https://x.example/d.png': ServerImageResolver.describe(_png)!,
          },
        );
        final upload = await _upload(anna, 'part.docx', bytes);

        final r = await endpoints.writeExport.convertForInsert(
          anna.endpointSession,
          upload,
          'docx',
          jsonEncode({'documentUuid': target.contentRef!.uuid}),
        );

        final delta = Delta.fromJson(jsonDecode(r.deltaJson) as List);
        final md = const MarkdownCodec().exportMarkdown(delta);
        expect(md, startsWith('Inserted *text*\n\n![Dot](wonky-file://'));
      },
    );
  });
}
