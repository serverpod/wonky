/// DOCX exporter (07 §5.4): WordprocessingML with styles from the theme,
/// numbering definitions for nested bullet/ordered lists and heading
/// numbering, code blocks with token colors, tables with header repeat and
/// column alignment, embedded images, hyperlinks, page setup, headers and
/// footers with page-number fields, an optional TOC field and core
/// properties. Output is deterministic (sorted parts, fixed timestamps).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../../delta/boxes.dart';
import '../../delta/embeds.dart';
import '../../ir/doc_tree.dart';
import '../../layout/page_setup.dart';
import '../../markdown/front_matter.dart';
import '../../markdown/inline_markdown.dart';
import '../../markdown/inline_reader.dart' show mentionTitlePrefix;
import '../../theme/model/style_enums.dart';
import '../../theme/model/values.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../../theme/resolve/theme_resolver.dart';
import '../export_api.dart';
import '../markdown_file_exporter.dart';
import '../office/office_support.dart';
import '../zip.dart';
import 'docx_styles.dart';
import 'docx_xml.dart';

/// Exports documents as Word (`.docx`) files.
final class DocxExporter implements DocumentExporter<OfficeExportOptions> {
  /// Creates the exporter.
  const DocxExporter();

  /// `docProps/app.xml` application name (the importer recognizes its own
  /// files by it).
  static const application = 'Wonky Write';

  @override
  ExportFormat get format => ExportFormat.docx;

  @override
  Future<ExportArtifact> export(
    ExportInput input,
    OfficeExportOptions options,
  ) async {
    final job = _DocxJob(input, options);
    final bytes = await job.run();
    return ExportArtifact(
      fileName: ExportFileNames.fileName(
        options.fileName ?? input.meta.title,
        'docx',
      ),
      mimeType: format.mimeType,
      bytes: bytes,
      warnings: job.warnings,
    );
  }
}

/// A package relationship of `word/document.xml`.
typedef _Rel = ({String id, String type, String target, bool external});

final class _DocxJob {
  _DocxJob(this.input, this.options);

  final ExportInput input;
  final OfficeExportOptions options;
  final warnings = <ExportWarning>[];

  late final ResolvedWriteTheme theme = ThemeResolver.instance.resolve(
    input.theme,
    input.variant,
  );
  late final DocTree tree = exportTree(input, options).withVideosAsLinks;

  /// The blocks in document order with Wonky containers flattened
  /// (Write 11 §9): a callout's title and a details summary become bold
  /// paragraphs, and every block in a container gets the container's look
  /// ([_boxes]).
  late final List<DocBlock> _blocks = _flatten(tree.blocks, null);
  final _boxes = Map<DocBlock, _Box>.identity();
  final _titleColors = Map<DocBlock, int>.identity();
  late final double contentWidth = contentWidthPt(input, theme);
  late final double contentHeight = contentHeightPt(input, theme);
  Map<String, OfficeImage> _images = const {};

  final _rels = <_Rel>[];
  final _hyperlinkRels = <String, String>{};
  final _imageRels = <String, String>{};
  final _media = <ZipEntry>[];
  final _bookmarks = <String, String>{};
  var _bookmarkId = 0;
  var _drawingId = 0;
  var _orderedNums = 0;
  final _fonts = <String>{};

  String _rel(String type, String target, {bool external = false}) {
    final id = 'rId${_rels.length + 1}';
    _rels.add((
      id: id,
      type: '${DocxNs.relType}/$type',
      target: target,
      external: external,
    ));
    return id;
  }

  Future<Uint8List> run() async {
    input.cancel?.throwIfCancelled();
    input.progress?.call(ExportPhase.loading, 0);
    _images = await resolveOfficeImages(input, tree, warnings);
    input.cancel?.throwIfCancelled();
    input.progress?.call(ExportPhase.layout, 0.5);
    _rel('styles', 'styles.xml');
    _rel('numbering', 'numbering.xml');
    _rel('settings', 'settings.xml');
    _rel('fontTable', 'fontTable.xml');
    _collectBookmarks();
    final headerParts = <ZipEntry>[];
    final sectRefs = _headersFooters(headerParts);
    final body = _body();
    input.progress?.call(ExportPhase.packaging, 0.8);

    for (final s in [
      theme.body.style,
      ...theme.headings.map((h) => h.style),
      theme.blockquote.style,
      theme.codeBlock.style,
      theme.table.style,
      theme.table.headerStyle,
      theme.header.style,
      theme.footer.style,
      theme.image.caption.style,
    ]) {
      _fonts.add(s.fontFamily);
    }
    _fonts.add(theme.inlineCode.fontFamily);

    final background = _pageBackground;
    final document = StringBuffer(_xmlHeader)
      ..write('<w:document ${DocxNs.rootDecls}>');
    if (background != null) {
      document.write('<w:background w:color="${rgbHex(background)}"/>');
    }
    document
      ..write('<w:body>')
      ..write(body)
      ..write(_sectPr(sectRefs))
      ..write('</w:body></w:document>');

    final styles = DocxStyleWriter(
      theme,
      language: _language,
    ).stylesXml(contentWidth: contentWidth);
    final writer = DocxStyleWriter(theme, language: _language);
    final entries = <ZipEntry>[
      ZipEntry.text('[Content_Types].xml', _contentTypes(headerParts)),
      ZipEntry.text('_rels/.rels', _packageRels()),
      ZipEntry.text('docProps/core.xml', _coreXml()),
      ZipEntry.text('docProps/app.xml', _appXml()),
      ZipEntry.text('word/document.xml', document.toString()),
      ZipEntry.text('word/styles.xml', styles),
      ZipEntry.text('word/numbering.xml', writer.numberingXml(_orderedNums)),
      ZipEntry.text(
        'word/settings.xml',
        writer.settingsXml(
          background: background != null,
          updateFields: options.includeToc,
        ),
      ),
      ZipEntry.text('word/fontTable.xml', writer.fontTableXml(_fonts)),
      ZipEntry.text('word/_rels/document.xml.rels', _documentRels()),
      ...headerParts,
      ..._media,
    ];
    input.progress?.call(ExportPhase.packaging, 1);
    return DeterministicZip.encode(
      entries,
      modified: input.meta.modifiedAt,
      first: const ['[Content_Types].xml'],
    );
  }

  static const _xmlHeader =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';

  String? get _language {
    final l = input.meta.language;
    if (l == null || l.isEmpty) return null;
    return l;
  }

  /// Paper color when it is not white, or always for the dark variant.
  int? get _pageBackground {
    final paper = flattenAlpha(theme.page.paperColor);
    if (input.variant == ThemeVariant.dark || (paper & 0xFFFFFF) != 0xFFFFFF) {
      return paper;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Package parts

  String _contentTypes(List<ZipEntry> headerParts) {
    final b = StringBuffer(_xmlHeader)
      ..write(
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Default Extension="png" ContentType="image/png"/>'
        '<Default Extension="jpeg" ContentType="image/jpeg"/>',
      );
    void over(String part, String type) => b.write(
      '<Override PartName="/$part" ContentType="application/vnd.openxmlformats-$type"/>',
    );
    over(
      'word/document.xml',
      'officedocument.wordprocessingml.document.main+xml',
    );
    over('word/styles.xml', 'officedocument.wordprocessingml.styles+xml');
    over('word/numbering.xml', 'officedocument.wordprocessingml.numbering+xml');
    over('word/settings.xml', 'officedocument.wordprocessingml.settings+xml');
    over('word/fontTable.xml', 'officedocument.wordprocessingml.fontTable+xml');
    for (final p in headerParts) {
      final kind = p.path.contains('header') ? 'header' : 'footer';
      over(p.path, 'officedocument.wordprocessingml.$kind+xml');
    }
    over('docProps/core.xml', 'package.core-properties+xml');
    over('docProps/app.xml', 'officedocument.extended-properties+xml');
    b.write('</Types>');
    return b.toString();
  }

  String _packageRels() =>
      '$_xmlHeader<Relationships xmlns="${DocxNs.rels}">'
      '<Relationship Id="rId1" Type="${DocxNs.relType}/officeDocument" Target="word/document.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
      '<Relationship Id="rId3" Type="${DocxNs.relType}/extended-properties" Target="docProps/app.xml"/>'
      '</Relationships>';

  String _documentRels() {
    final b = StringBuffer(_xmlHeader)
      ..write('<Relationships xmlns="${DocxNs.rels}">');
    for (final r in _rels) {
      b.write(
        '<Relationship Id="${r.id}" Type="${r.type}" '
        'Target="${xmlAttr(r.target)}"${r.external ? ' TargetMode="External"' : ''}/>',
      );
    }
    b.write('</Relationships>');
    return b.toString();
  }

  String _coreXml() {
    final m = input.meta;
    final modified = isoTimestamp(m.modifiedAt);
    final created = isoTimestamp(m.createdAt ?? m.modifiedAt);
    final author = exportAuthor(input);
    final tags = FrontMatter.tags(m.frontMatter);
    final b = StringBuffer(_xmlHeader)
      ..write(
        '<cp:coreProperties '
        'xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:dcmitype="http://purl.org/dc/dcmitype/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">',
      );
    if (m.title != null) b.write('<dc:title>${xmlText(m.title!)}</dc:title>');
    if (m.description != null && m.description!.isNotEmpty) {
      b.write('<dc:subject>${xmlText(m.description!)}</dc:subject>');
    }
    if (author != null) b.write('<dc:creator>${xmlText(author)}</dc:creator>');
    if (tags.isNotEmpty) {
      b.write('<cp:keywords>${xmlText(tags.join(', '))}</cp:keywords>');
    }
    if (_language != null) {
      b.write('<dc:language>${xmlText(_language!)}</dc:language>');
    }
    if (author != null) {
      b.write('<cp:lastModifiedBy>${xmlText(author)}</cp:lastModifiedBy>');
    }
    b.write(
      '<cp:revision>${math.max(1, input.revision)}</cp:revision>'
      '<dcterms:created xsi:type="dcterms:W3CDTF">$created</dcterms:created>'
      '<dcterms:modified xsi:type="dcterms:W3CDTF">$modified</dcterms:modified>'
      '</cp:coreProperties>',
    );
    return b.toString();
  }

  String _appXml() =>
      '$_xmlHeader<Properties '
      'xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" '
      'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
      '<Application>${DocxExporter.application}</Application>'
      '<DocSecurity>0</DocSecurity></Properties>';

  // ---------------------------------------------------------------------
  // Section, headers and footers

  /// Writes header/footer parts; returns the `sectPr` references.
  String _headersFooters(List<ZipEntry> parts) {
    final setup = input.pageSetup;
    final refs = StringBuffer();
    final headerRefs = StringBuffer();
    final footerRefs = StringBuffer();
    var n = 0;
    void add(
      HeaderFooterSpec spec, {
      required bool header,
      required bool first,
    }) {
      final enabled = spec.enabled && !spec.isEmpty;
      if (!enabled && !first) return;
      n++;
      final kind = header ? 'header' : 'footer';
      final path = '$kind$n.xml';
      final id = _rel(kind, path);
      final tag = header ? 'w:hdr' : 'w:ftr';
      final para = enabled
          ? _slotParagraph(spec, header: header)
          : '<w:p><w:pPr><w:pStyle w:val="${header ? DocxStyleIds.header : DocxStyleIds.footer}"/></w:pPr></w:p>';
      parts.add(
        ZipEntry.text(
          'word/$path',
          '$_xmlHeader<$tag ${DocxNs.rootDecls}>$para</$tag>',
        ),
      );
      final ref =
          '<w:${kind}Reference w:type="${first ? 'first' : 'default'}" r:id="$id"/>';
      (header ? headerRefs : footerRefs).write(ref);
    }

    add(setup.header, header: true, first: false);
    if (setup.differentFirstPage) {
      add(setup.firstPageHeader, header: true, first: true);
    }
    add(setup.footer, header: false, first: false);
    if (setup.differentFirstPage) {
      add(setup.firstPageFooter, header: false, first: true);
    }
    refs
      ..write(headerRefs)
      ..write(footerRefs);
    return refs.toString();
  }

  String _slotParagraph(HeaderFooterSpec spec, {required bool header}) {
    final ctx = HeaderFooterSlots.context(input);
    final style = header ? DocxStyleIds.header : DocxStyleIds.footer;
    final used = [
      if (spec.left.isNotEmpty) ThemeAlign.left,
      if (spec.center.isNotEmpty) ThemeAlign.center,
      if (spec.right.isNotEmpty) ThemeAlign.right,
    ];
    final b = StringBuffer('<w:p>');
    void slot(String template) {
      for (final part in HeaderFooterSlots.parts(template, ctx)) {
        switch (part) {
          case SlotText(:final text):
            b.write(_textRun(text, null));
          case SlotField(:final pageCount):
            b.write(pageCount ? _pagesField() : _pageField());
        }
      }
    }

    if (used.length == 1) {
      // One slot: align the paragraph instead of relying on tab stops.
      final p = ParaProps()
        ..style = style
        ..align = used.single == ThemeAlign.left ? null : used.single;
      b.write(p.xml());
      slot(switch (used.single) {
        ThemeAlign.center => spec.center,
        ThemeAlign.right => spec.right,
        _ => spec.left,
      });
    } else {
      b.write((ParaProps()..style = style).xml());
      slot(spec.left);
      if (spec.center.isNotEmpty || spec.right.isNotEmpty) {
        b.write('<w:r><w:tab/></w:r>');
        slot(spec.center);
      }
      if (spec.right.isNotEmpty) {
        b.write('<w:r><w:tab/></w:r>');
        slot(spec.right);
      }
    }
    b.write('</w:p>');
    return b.toString();
  }

  String get _numberFormatSwitch => switch (input.pageSetup.pageNumberFormat) {
    PageNumberFormat.decimal => '',
    PageNumberFormat.lowerRoman => r' \* roman',
    PageNumberFormat.upperRoman => r' \* ROMAN',
  };

  String _pageField() {
    final setup = input.pageSetup;
    return '<w:fldSimple w:instr=" PAGE "><w:r><w:t>'
        '${xmlText(setup.pageLabel(0))}</w:t></w:r></w:fldSimple>';
  }

  String _pagesField() {
    final setup = input.pageSetup;
    final offset = setup.pageNumberStart - 1;
    if (offset == 0) {
      return '<w:fldSimple w:instr=" NUMPAGES$_numberFormatSwitch ">'
          '<w:r><w:t>${xmlText(setup.pageLabel(0))}</w:t></w:r></w:fldSimple>';
    }
    String fld(String type) => '<w:r><w:fldChar w:fldCharType="$type"/></w:r>';
    String instr(String text) =>
        '<w:r><w:instrText xml:space="preserve">${xmlText(text)}</w:instrText></w:r>';
    return '${fld('begin')}${instr(' = ')}${fld('begin')}${instr(' NUMPAGES ')}'
        '${fld('separate')}<w:r><w:t>1</w:t></w:r>${fld('end')}'
        '${instr(' + $offset$_numberFormatSwitch ')}${fld('separate')}'
        '<w:r><w:t>${xmlText(setup.pageLabel(0))}</w:t></w:r>${fld('end')}';
  }

  String _sectPr(String refs) {
    final setup = input.pageSetup;
    final m = pageMarginsPt(input, theme);
    final w = OfficeUnits.twips(setup.pageWidthPt);
    final h = OfficeUnits.twips(setup.pageHeightPt);
    final landscape = setup.orientation == PageOrientation.landscape;
    final fmt = switch (setup.pageNumberFormat) {
      PageNumberFormat.decimal => 'decimal',
      PageNumberFormat.lowerRoman => 'lowerRoman',
      PageNumberFormat.upperRoman => 'upperRoman',
    };
    return '<w:sectPr>$refs'
        '<w:pgSz w:w="$w" w:h="$h"${landscape ? ' w:orient="landscape"' : ''}/>'
        '<w:pgMar w:top="${OfficeUnits.twips(m.top)}" w:right="${OfficeUnits.twips(m.right)}" '
        'w:bottom="${OfficeUnits.twips(m.bottom)}" w:left="${OfficeUnits.twips(m.left)}" '
        'w:header="${OfficeUnits.twips(setup.header.distancePt)}" '
        'w:footer="${OfficeUnits.twips(setup.footer.distancePt)}" w:gutter="0"/>'
        '<w:pgNumType w:fmt="$fmt" w:start="${setup.pageNumberStart}"/>'
        '<w:cols w:space="720"/>'
        '${setup.differentFirstPage ? '<w:titlePg/>' : ''}'
        '<w:docGrid w:linePitch="360"/></w:sectPr>';
  }

  // ---------------------------------------------------------------------
  // Body

  void _collectBookmarks() {
    final used = <String>{};
    for (final h in tree.headings) {
      if (h.anchorId.isEmpty) continue;
      var name = h.anchorId.replaceAll(RegExp('[^A-Za-z0-9_]'), '_');
      if (!RegExp('^[A-Za-z]').hasMatch(name)) name = 'h_$name';
      if (name.length > 40) name = name.substring(0, 40);
      var candidate = name;
      var k = 2;
      while (!used.add(candidate)) {
        final suffix = '_$k';
        candidate =
            (name.length + suffix.length > 40
                ? name.substring(0, 40 - suffix.length)
                : name) +
            suffix;
        k++;
      }
      _bookmarks[h.anchorId] = candidate;
    }
  }

  /// Natural (style) spacing of each block before collapsing.
  List<(double, double)> _naturalSpacing() {
    final blocks = _blocks;
    final out = <(double, double)>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final prev = i > 0 ? blocks[i - 1] : null;
      final next = i + 1 < blocks.length ? blocks[i + 1] : null;
      bool isListLike(DocBlock? x) => x is ListItemBlock || x is TaskBlock;
      switch (b) {
        case ContainerBlock():
          // Flattened ([_blocks]).
          out.add((0, 0));
        case YouTubeBlock():
          // Links ([DocTree.withVideosAsLinks]).
          out.add((0, 0));
        case GridBlock():
          final g = theme.wonky.grid;
          out.add((g.spaceBefore, g.spaceAfter));
        case ParagraphBlock():
          var before = theme.body.box.spaceBefore;
          var after = theme.body.box.spaceAfter;
          if (prev is HeadingBlock) {
            before = theme.paragraphAfterHeading.spaceBefore ?? before;
            after = theme.paragraphAfterHeading.spaceAfter ?? after;
          }
          out.add((before, after));
        case HeadingBlock(:final level):
          final box = theme.heading(level).box;
          out.add((box.spaceBefore, box.spaceAfter));
        case ListItemBlock() || TaskBlock():
          final box = b is TaskBlock ? theme.task.box : theme.list.box;
          out.add((
            isListLike(prev) ? 0 : box.spaceBefore,
            isListLike(next) ? theme.list.itemSpacing : box.spaceAfter,
          ));
        case QuoteBlock():
          final box = theme.blockquote.box;
          out.add((box.spaceBefore, box.spaceAfter));
        case CodeBlock():
          final box = theme.codeBlock.box;
          out.add((box.spaceBefore, box.spaceAfter));
        case ImageBlock():
          final box = theme.image.box;
          out.add((box.spaceBefore, box.spaceAfter));
        case RuleBlock():
          final box = theme.rule.box;
          out.add((box.spaceBefore, box.spaceAfter));
        case TableBlock():
          final box = theme.table.box;
          out.add((box.spaceBefore, box.spaceAfter));
      }
    }
    return out;
  }

  /// A list item inside a quote (Write 02 §1.2): the level's numbering indent
  /// moved right by the quote's indent, with the quote's bar and background.
  void _quoted(ParaProps p, int indent) {
    final q = theme.blockquote;
    final l = theme.list;
    final level = indent.clamp(0, 8);
    p
      ..indentLeft =
          q.box.padding.left +
          (q.bar.isVisible ? q.bar.width : 0) +
          l.indentFor(level)
      ..hanging = l.indentPerLevel;
    if (q.bar.isVisible) {
      p.left = docxBorder(
        'left',
        q.bar,
        space: q.box.padding.left.clamp(0, 31),
      );
    }
    if (q.box.background != null) p.shading = q.box.background;
  }

  String _body() {
    final b = StringBuffer();
    final blocks = _blocks;
    final natural = _naturalSpacing();
    // Collapsed: Word adds after(prev) + before(next); emit
    // before = max(0, before - after(prev)) so the gap is the max (06 §7.3).
    final spacing = <(double, double)>[
      for (var i = 0; i < blocks.length; i++)
        (
          i == 0
              ? natural[i].$1
              : math.max(0, natural[i].$1 - natural[i - 1].$2).toDouble(),
          natural[i].$2,
        ),
    ];
    final tocAfter = options.includeToc
        ? (tree.titleHeading != null ? 0 : -1)
        : null;
    if (tocAfter == -1) b.write(_toc());
    // Ordered list instance per indent level.
    final orderedNum = <int, int>{};
    for (var i = 0; i < blocks.length; i++) {
      input.cancel?.throwIfCancelled();
      final block = blocks[i];
      if (block is! ListItemBlock && block is! TaskBlock) orderedNum.clear();
      final (before, after) = spacing[i];
      final (natBefore, natAfter) = natural[i];
      switch (block) {
        case ContainerBlock():
          // Flattened ([_blocks]).
          break;
        case YouTubeBlock():
          // Links ([DocTree.withVideosAsLinks]).
          break;
        case GridBlock():
          if (i > 0 && before > 0.5) b.write(_spacer(before));
          b.write(_grid(block));
          b.write(_spacer(natAfter));
          if (i + 1 < blocks.length) {
            spacing[i + 1] = (
              math.max(0, spacing[i + 1].$1 - natAfter).toDouble(),
              spacing[i + 1].$2,
            );
          }
        case ParagraphBlock(:final runs):
          final p = ParaProps();
          final styleBefore = theme.body.box.spaceBefore;
          final styleAfter = theme.body.box.spaceAfter;
          if (before != styleBefore) p.spaceBefore = before;
          if (after != styleAfter) p.spaceAfter = after;
          if (theme.body.firstLineIndent > 0 && runs.isNotEmpty) {
            p.firstLine = theme.body.firstLineIndent;
          }
          _boxed(block, p);
          final titleColor = _titleColors[block];
          if (titleColor != null) {
            // A callout title.
            p.keepNext = true;
            final props = RunProps()
              ..bold = true
              ..color = titleColor;
            b.write(
              '<w:p>${p.xml()}${_textRun(InlineRun.plainText(runs), props)}</w:p>',
            );
          } else {
            b.write(_paragraph(p, runs));
          }
        case HeadingBlock(:final level, :final runs, :final anchorId):
          final box = theme.heading(level).box;
          final p = ParaProps()..style = DocxStyleIds.heading(level);
          if (before != box.spaceBefore) p.spaceBefore = before;
          _boxed(block, p);
          final bookmark = _bookmarks[anchorId];
          final content = StringBuffer();
          if (block.step != null) {
            // A numbered heading (Write 11 §9).
            content.write(_textRun('${block.step}. ', null));
          }
          if (bookmark != null) {
            content.write(
              '<w:bookmarkStart w:id="$_bookmarkId" w:name="$bookmark"/>',
            );
          }
          content.write(_runs(runs));
          if (bookmark != null) {
            content.write('<w:bookmarkEnd w:id="$_bookmarkId"/>');
            _bookmarkId++;
          }
          b.write('<w:p>${p.xml()}$content</w:p>');
          // Heading labels come from the numbering linked to the style.
          if (tocAfter == i) b.write(_toc());
        case ListItemBlock(
          :final kind,
          :final indent,
          :final runs,
          :final ordinal,
        ):
          orderedNum.removeWhere((level, _) => level > indent);
          final int numId;
          if (kind == ListKindIr.ordered) {
            var id = orderedNum[indent];
            if (id == null || ordinal == 1) {
              id =
                  DocxNumIds.firstOrdered(
                    headingNumbering: theme.headingNumbering.enabled,
                  ) +
                  _orderedNums++;
              orderedNum[indent] = id;
            }
            numId = id;
          } else {
            orderedNum.remove(indent);
            numId = DocxNumIds.bullets;
          }
          final p = ParaProps()
            ..style = DocxStyleIds.listParagraph
            ..numbering = (numId, indent.clamp(0, 8));
          if (before != 0) p.spaceBefore = before;
          if (after != theme.list.itemSpacing) p.spaceAfter = after;
          if (block.inQuote) _quoted(p, indent);
          _boxed(block, p);
          b.write(_paragraph(p, runs));
        case TaskBlock(:final checked, :final indent, :final runs):
          orderedNum.remove(indent);
          final p = ParaProps()
            ..style = DocxStyleIds.listParagraph
            ..numbering = (DocxNumIds.tasks, indent.clamp(0, 8));
          if (before != 0) p.spaceBefore = before;
          if (after != theme.list.itemSpacing) p.spaceAfter = after;
          if (block.inQuote) _quoted(p, indent);
          _boxed(block, p);
          final glyph = RunProps()
            ..font = 'Segoe UI Symbol'
            ..color = theme.task.checkbox.borderColor;
          final content = StringBuffer(
            '<w:r>${glyph.xml()}<w:t>${checked ? '☒' : '☐'}</w:t><w:tab/></w:r>',
          );
          content.write(
            _runs(
              runs,
              base:
                  checked &&
                      (theme.task.checkedStrike ||
                          theme.task.checkedOpacity < 1)
                  ? DocxStyleIds.taskDone
                  : null,
            ),
          );
          b.write('<w:p>${p.xml()}$content</w:p>');
        case QuoteBlock(:final lines):
          for (var l = 0; l < lines.length; l++) {
            final p = ParaProps()..style = DocxStyleIds.quote;
            final first = l == 0;
            final last = l == lines.length - 1;
            final lb = first ? before : 0.0;
            final la = last ? after : theme.body.box.spaceAfter;
            if (lb != 0) p.spaceBefore = lb;
            if (la != 0) p.spaceAfter = la;
            _boxed(block, p);
            b.write(_paragraph(p, lines[l]));
          }
        case CodeBlock(:final language, :final text):
          final lines = highlightedCodeLines(text, language);
          for (var l = 0; l < lines.length; l++) {
            final p = ParaProps()..style = DocxStyleIds.codeBlock;
            if (l == 0) {
              p.spaceBefore = before + theme.codeBlock.box.padding.top;
            }
            if (l == lines.length - 1) {
              p.spaceAfter = after + theme.codeBlock.box.padding.bottom;
            } else {
              p.keepNext = true;
            }
            b.write('<w:p>${p.xml()}${_codeLine(lines[l])}</w:p>');
          }
        case ImageBlock():
          b.write(_image(block, before, after));
        case RuleBlock():
          final p = ParaProps()..style = DocxStyleIds.rule;
          if (before != natBefore) p.spaceBefore = before;
          final content = theme.rule.style == RuleStyle.ornament
              ? _textRun(theme.rule.ornament, null)
              : '';
          b.write('<w:p>${p.xml()}$content</w:p>');
        case TableBlock():
          // Tables carry no spacing: spacer paragraphs (style WonkySpacer,
          // skipped by the importer) provide it; the one after the table
          // also keeps adjacent tables apart.
          if (i > 0 && before > 0.5) b.write(_spacer(before));
          b.write(_table(block));
          b.write(_spacer(natAfter));
          if (i + 1 < blocks.length) {
            spacing[i + 1] = (
              math.max(0, spacing[i + 1].$1 - natAfter).toDouble(),
              spacing[i + 1].$2,
            );
          }
      }
    }
    if (blocks.isEmpty) b.write('<w:p/>');
    return b.toString();
  }

  /// Flattens Wonky containers ([_blocks]).
  List<DocBlock> _flatten(List<DocBlock> blocks, _Box? box) {
    final out = <DocBlock>[];
    for (final b in blocks) {
      if (b is! ContainerBlock) {
        if (box != null) _boxes[b] = box;
        out.add(b);
        continue;
      }
      final w = theme.wonky;
      final depth = (box?.depth ?? 0) + 1;
      final frame = b.frame;
      final _Box inner;
      switch (frame.type) {
        case BoxType.callout:
          final cc = w.callout.colorsFor(
            (frame.variant ?? CalloutVariant.info).value,
          );
          inner = _Box(
            cc.background,
            BorderPt(
              width: math.max(w.callout.borderWidth, 1.5) * 2,
              style: LineStyle.solid,
              color: cc.border,
            ),
            depth,
          );
          final title = ParagraphBlock([
            InlineRun(frame.calloutLabel, bold: true),
          ]);
          _titleColors[title] = cc.title;
          _boxes[title] = inner;
          out.add(title);
        case BoxType.details:
          inner = _Box(w.details.background, w.details.border, depth);
          final summary = ParagraphBlock([
            for (final r in b.summary?.runs ?? const <InlineRun>[])
              r.code ? r : r.copyWith(bold: true),
          ]);
          _boxes[summary] = inner;
          out.add(summary);
        case BoxType.card:
          inner = _Box(w.card.background, null, depth);
      }
      out.addAll(_flatten(b.body, inner));
    }
    return out;
  }

  /// Gives a paragraph in a Wonky container the container's shading, left
  /// border and nesting indent.
  void _boxed(DocBlock block, ParaProps p) {
    final box = _boxes[block];
    if (box == null) return;
    p.shading ??= box.shading;
    final border = box.border;
    if (p.left == null && border != null && border.isVisible) {
      p.left = docxBorder('left', border, space: 6);
    }
    if (p.indentLeft == null && box.depth > 1) {
      p.indentLeft = 12.0 * (box.depth - 1);
    }
  }

  /// A Wonky grid as a borderless table (Write 11 §9).
  String _grid(GridBlock g) {
    final cols = g.columns.clamp(1, 4);
    final width = contentWidth / cols;
    final b = StringBuffer(
      '<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/>'
      '<w:tblLayout w:type="fixed"/></w:tblPr><w:tblGrid>',
    );
    for (var c = 0; c < cols; c++) {
      b.write('<w:gridCol w:w="${OfficeUnits.twips(width)}"/>');
    }
    b.write('</w:tblGrid>');
    final glyph = switch (g.bullets) {
      GridBullets.check => '✓ ',
      GridBullets.circle => '• ',
      GridBullets.none => '',
    };
    final bullet = RunProps()
      ..color = theme.wonky.grid.bulletColor
      ..bold = true;
    for (var r = 0; r * cols < g.items.length; r++) {
      b.write('<w:tr><w:trPr><w:cantSplit/></w:trPr>');
      for (var c = 0; c < cols; c++) {
        final k = r * cols + c;
        final p = ParaProps()..spaceAfter = theme.wonky.grid.rowGap;
        final content = k < g.items.length
            ? '${_textRun(glyph, bullet)}${_runs(g.items[k])}'
            : '';
        b.write(
          '<w:tc><w:tcPr><w:tcW w:w="${OfficeUnits.twips(width)}" '
          'w:type="dxa"/></w:tcPr><w:p>${p.xml()}$content</w:p></w:tc>',
        );
      }
      b.write('</w:tr>');
    }
    b.write('</w:tbl>');
    return b.toString();
  }

  String _toc() {
    final depth = 3;
    return '<w:p><w:pPr><w:pStyle w:val="${DocxStyleIds.tocHeading}"/></w:pPr>'
        '${_textRun('Contents', null)}</w:p>'
        '<w:p><w:pPr><w:pStyle w:val="${DocxStyleIds.toc(1)}"/></w:pPr>'
        '<w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r>'
        '<w:r><w:instrText xml:space="preserve"> TOC \\o "1-$depth" \\h \\z \\u </w:instrText></w:r>'
        '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
        '${_textRun('Update the field to show the table of contents.', null)}'
        '<w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>';
  }

  String _spacer(double heightPt) =>
      '<w:p><w:pPr><w:pStyle w:val="${DocxStyleIds.spacer}"/><w:spacing '
      'w:before="0" w:after="0" w:line="${math.max(20, OfficeUnits.twips(heightPt))}" '
      'w:lineRule="exact"/></w:pPr></w:p>';

  String _paragraph(ParaProps p, List<InlineRun> runs) =>
      '<w:p>${p.xml()}${_runs(runs)}</w:p>';

  /// A plain run of [text] (tabs and soft breaks converted).
  String _textRun(String text, RunProps? props) {
    if (text.isEmpty) return '';
    final rPr = props?.xml() ?? '';
    final b = StringBuffer('<w:r>$rPr');
    final buf = StringBuffer();
    void flush() {
      if (buf.isEmpty) return;
      final t = buf.toString();
      final preserve = t.startsWith(' ') || t.endsWith(' ') || t.contains('  ');
      b.write(
        '<w:t${preserve ? ' xml:space="preserve"' : ''}>${xmlText(t)}</w:t>',
      );
      buf.clear();
    }

    for (final c in text.split('')) {
      if (c == '\t') {
        flush();
        b.write('<w:tab/>');
      } else if (c == ' ' || c == '\n') {
        flush();
        b.write('<w:br/>');
      } else {
        buf.write(c);
      }
    }
    flush();
    b.write('</w:r>');
    return b.toString();
  }

  RunProps _runProps(InlineRun r, {String? base}) {
    final p = RunProps()..style = base;
    if (r.code) {
      p.style = DocxStyleIds.codeChar;
      return p;
    }
    if (r.chip) {
      // A chip: shaded text (Write 11 §9).
      p
        ..shading = theme.wonky.chip.background
        ..color = theme.wonky.chip.color;
      return p;
    }
    if (r.mentionUserUuid != null) {
      p.style = DocxStyleIds.mention;
    } else if (r.link != null) {
      p.style = DocxStyleIds.hyperlink;
    }
    if (r.linkStyle != null) p.bold = true;
    if (r.bold) {
      p.bold = true;
      if (theme.bold.color != null) p.color = theme.bold.color;
    }
    if (r.italic) {
      p.italic = true;
      if (theme.italic.color != null) p.color = theme.italic.color;
    }
    if (r.strike) {
      p.strike = true;
      if (theme.strike.color != null) p.color = theme.strike.color;
    }
    return p;
  }

  /// Runs with hyperlinks grouped.
  String _runs(List<InlineRun> runs, {String? base}) {
    final b = StringBuffer();
    var i = 0;
    while (i < runs.length) {
      final r = runs[i];
      if (r.link == null) {
        b.write(_textRun(r.text, _runProps(r, base: base)));
        i++;
        continue;
      }
      var j = i;
      while (j < runs.length &&
          runs[j].link == r.link &&
          runs[j].mentionUserUuid == r.mentionUserUuid) {
        j++;
      }
      final inner = StringBuffer();
      for (final x in runs.sublist(i, j)) {
        inner.write(_textRun(x.text, _runProps(x, base: base)));
      }
      final target = r.mentionUserUuid != null
          ? r.link!
          : input.links.resolve(r.link!);
      if (target.startsWith('#')) {
        final bookmark = _bookmarks[target.substring(1)];
        if (bookmark != null) {
          b.write(
            '<w:hyperlink w:anchor="$bookmark" w:history="1">$inner</w:hyperlink>',
          );
        } else {
          b.write(inner);
        }
      } else {
        final id = _hyperlinkRels.putIfAbsent(
          target,
          () => _rel('hyperlink', target, external: true),
        );
        final mention = r.mentionUserUuid;
        final tooltip = mention == null
            ? ''
            : ' w:tooltip="${xmlAttr('$mentionTitlePrefix$mention')}"';
        b.write(
          '<w:hyperlink r:id="$id"$tooltip w:history="1">$inner</w:hyperlink>',
        );
      }
      i = j;
    }
    return b.toString();
  }

  String _codeLine(List<CodePiece> pieces) {
    final b = StringBuffer();
    for (final piece in pieces) {
      RunProps? props;
      final token = piece.token;
      if (token != null) {
        final s = theme.syntax[token];
        if (s != null) {
          props = RunProps()..color = s.color;
          if (s.italic) props.italic = true;
          if ((s.fontWeight ?? 400) >= 600) props.bold = true;
        }
      }
      b.write(_textRun(piece.text, props));
    }
    return b.toString();
  }

  // ---------------------------------------------------------------------
  // Images

  String _image(ImageBlock block, double before, double after) {
    final image = _images[block.src];
    final title = block.title?.trim();
    final hasCaption =
        title != null && title.isNotEmpty && theme.image.caption.show;
    final p = ParaProps()..style = DocxStyleIds.figure;
    if (before != theme.image.box.spaceBefore) p.spaceBefore = before;
    if (hasCaption) {
      p.spaceAfter = theme.image.caption.gap;
    } else if (after != theme.image.box.spaceAfter) {
      p.spaceAfter = after;
    }
    if (image == null) {
      final alt = block.alt.trim();
      return _paragraph(p..style = null, [
        InlineRun(alt.isEmpty ? '[Image]' : '[Image: $alt]'),
      ]);
    }
    final relId = _imageRels.putIfAbsent(block.src, () {
      final name = 'image${_imageRels.length + 1}.${image.extension}';
      _media.add(ZipEntry('word/media/$name', image.bytes, store: true));
      return _rel('image', 'media/$name');
    });
    final maxWidth = theme.image.maxWidth.resolve(contentWidth);
    final reserve = hasCaption
        ? theme.image.caption.style.lineHeightPt + theme.image.caption.gap
        : 0;
    final (w, h) = image.fit(maxWidth, math.max(72, contentHeight - reserve));
    final cx = OfficeUnits.emu(w);
    final cy = OfficeUnits.emu(h);
    final id = ++_drawingId;
    final alt = xmlAttr(block.alt);
    final titleAttr = title == null || title.isEmpty
        ? ''
        : ' title="${xmlAttr(title)}"';
    final radius = theme.image.borderRadius;
    final geometry = radius > 0
        ? '<a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val '
              '${(radius / math.min(w, h) * 100000).round().clamp(0, 50000)}"/>'
              '</a:avLst></a:prstGeom>'
        : '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>';
    final border = theme.image.border;
    final line = border != null && border.isVisible
        ? '<a:ln w="${OfficeUnits.emu(border.width)}"><a:solidFill>'
              '<a:srgbClr val="${rgbHex(flattenAlpha(border.color))}"/></a:solidFill></a:ln>'
        : '';
    final drawing =
        '<w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
        '<wp:extent cx="$cx" cy="$cy"/><wp:effectExtent l="0" t="0" r="0" b="0"/>'
        '<wp:docPr id="$id" name="Picture $id" descr="$alt"$titleAttr/>'
        '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>'
        '<a:graphic><a:graphicData uri="${DocxNs.pic}"><pic:pic>'
        '<pic:nvPicPr><pic:cNvPr id="$id" name="image$id.${image.extension}" descr="$alt"/>'
        '<pic:cNvPicPr><a:picLocks noChangeAspect="1"/></pic:cNvPicPr></pic:nvPicPr>'
        '<pic:blipFill><a:blip r:embed="$relId"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
        '$geometry$line</pic:spPr></pic:pic></a:graphicData></a:graphic>'
        '</wp:inline></w:drawing>';
    final b = StringBuffer('<w:p>${p.xml()}<w:r>$drawing</w:r></w:p>');
    if (hasCaption) {
      final cp = ParaProps()..style = DocxStyleIds.caption;
      if (after != theme.image.box.spaceAfter) cp.spaceAfter = after;
      b.write('<w:p>${cp.xml()}${_textRun(title, null)}</w:p>');
    }
    return b.toString();
  }

  // ---------------------------------------------------------------------
  // Tables

  List<double> _columnWidths(TableBlock t) {
    final cols = math.max(1, t.columnCount);
    final weights = List<double>.filled(cols, 3);
    for (final row in t.cellMarkdown) {
      for (var c = 0; c < row.length && c < cols; c++) {
        final len = InlineMarkdown.toPlainText(row[c]).runes.length.toDouble();
        if (len > weights[c]) weights[c] = len;
      }
    }
    final em = t.rows.isEmpty ? 11.0 : theme.table.style.fontSize;
    final minWidth = 2 * em;
    final pad = theme.table.cellPadding.horizontal;
    final total = weights.fold(0.0, (a, b) => a + b);
    final full = theme.table.width == TableWidth.full;
    final natural = [for (final w in weights) w * em * 0.55 + pad];
    final naturalSum = natural.fold(0.0, (a, b) => a + b);
    final width = full ? contentWidth : math.min(contentWidth, naturalSum);
    final out = [
      for (final w in weights) math.max(minWidth, width * w / total),
    ];
    final sum = out.fold(0.0, (a, b) => a + b);
    if (sum > contentWidth) {
      return [for (final w in out) w * contentWidth / sum];
    }
    return out;
  }

  String _table(TableBlock t) {
    final tb = theme.table;
    final widths = _columnWidths(t);
    final cols = widths.length;
    final full = tb.width == TableWidth.full;
    final zebra = tb.zebra && tb.zebraColor != null;
    final look = 0x0420 | (zebra ? 0 : 0x0200);
    final b = StringBuffer(
      '<w:tbl><w:tblPr><w:tblStyle w:val="${DocxStyleIds.table}"/>'
      '${full ? '<w:tblW w:w="5000" w:type="pct"/>' : '<w:tblW w:w="${OfficeUnits.twips(widths.fold(0.0, (a, b) => a + b))}" w:type="dxa"/>'}'
      '<w:tblLayout w:type="fixed"/>'
      '<w:tblLook w:val="${look.toRadixString(16).padLeft(4, '0').toUpperCase()}" '
      'w:firstRow="1" w:lastRow="0" w:firstColumn="0" w:lastColumn="0" '
      'w:noHBand="${zebra ? 0 : 1}" w:noVBand="1"/></w:tblPr><w:tblGrid>',
    );
    for (final w in widths) {
      b.write('<w:gridCol w:w="${OfficeUnits.twips(w)}"/>');
    }
    b.write('</w:tblGrid>');
    for (var r = 0; r < t.rows.length; r++) {
      final header = r == 0;
      b.write('<w:tr>');
      if (header) b.write('<w:trPr><w:cantSplit/><w:tblHeader/></w:trPr>');
      final row = t.rows[r];
      int? fill;
      if (header) {
        fill = tb.headerBackground;
      } else if (zebra && r.isEven) {
        fill = tb.zebraColor;
      }
      for (var c = 0; c < cols; c++) {
        final runs = c < row.length ? row[c] : const <InlineRun>[];
        final align = c < t.align.length ? t.align[c] : null;
        final p = ParaProps()
          ..style = header ? DocxStyleIds.tableHeading : DocxStyleIds.tableText
          ..align = switch (align) {
            CellAlign.left => ThemeAlign.left,
            CellAlign.center => ThemeAlign.center,
            CellAlign.right => ThemeAlign.right,
            null => null,
          };
        b.write(
          '<w:tc><w:tcPr><w:tcW w:w="${OfficeUnits.twips(widths[c])}" w:type="dxa"/>'
          '${fill == null ? '' : docxShading(fill)}</w:tcPr>'
          '${_paragraph(p, runs)}</w:tc>',
        );
      }
      b.write('</w:tr>');
    }
    b.write('</w:tbl>');
    return b.toString();
  }
}

/// The look of a Wonky container in DOCX: paragraph shading, left border,
/// nesting depth.
final class _Box {
  const _Box(this.shading, this.border, this.depth);

  final int? shading;
  final BorderPt? border;
  final int depth;
}
