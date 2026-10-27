/// OpenDocument Text export (07 §5.6, 06 §7.1).
library;

import 'dart:math' as math;

import '../../delta/boxes.dart';
import '../../delta/embeds.dart';
import 'package:wonky_fonts/wonky_fonts.dart';
import '../../ir/doc_tree.dart';
import '../../layout/page_setup.dart';
import '../../theme/model/style_enums.dart';
import '../../theme/model/values.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../../theme/resolve/theme_resolver.dart';
import '../export_api.dart';
import '../markdown_file_exporter.dart';
import '../office/office_support.dart';
import '../zip.dart';

part 'odt_styles.dart';

/// Exports `.odt` (ODF 1.3) packages.
///
/// The package holds `mimetype` (stored, first), `META-INF/manifest.xml`,
/// `meta.xml`, `settings.xml`, `styles.xml` (common styles built from the
/// resolved theme: `Standard`, `Heading_20_1…6`, `Quotations`,
/// `Preformatted_20_Text`, `Source_20_Text`, `Internet_20_link`, the
/// `WonkyBullets`/`WonkyNumbers`/`WonkyTasks` list styles, table, caption,
/// header/footer styles, the heading `text:outline-style`, the page layout and
/// the `Standard` master page with header/footer slots), `content.xml` and
/// `Pictures/*`. Output is deterministic: identical inputs give identical
/// bytes.
final class OdtExporter implements DocumentExporter<OfficeExportOptions> {
  /// Creates the exporter.
  const OdtExporter();

  @override
  ExportFormat get format => ExportFormat.odt;

  @override
  Future<ExportArtifact> export(
    ExportInput input,
    OfficeExportOptions options,
  ) async {
    input.cancel?.throwIfCancelled();
    input.progress?.call(ExportPhase.loading, 0);
    final tree = exportTree(input, options).withVideosAsLinks;
    final theme = ThemeResolver.instance.resolve(input.theme, input.variant);
    final warnings = <ExportWarning>[];
    final images = await resolveOfficeImages(input, tree, warnings);
    input.cancel?.throwIfCancelled();
    final writer = _OdtWriter(input, options, tree, theme, images, warnings);
    final content = writer.contentXml();
    final styles = writer.stylesXml();
    input.progress?.call(ExportPhase.packaging, 0);
    final entries = <ZipEntry>[
      ZipEntry.text('mimetype', format.mimeType, store: true),
      ZipEntry.text('META-INF/manifest.xml', writer.manifestXml()),
      ZipEntry.text('content.xml', content),
      ZipEntry.text('styles.xml', styles),
      ZipEntry.text('meta.xml', writer.metaXml()),
      ZipEntry.text('settings.xml', _settingsXml),
      for (final p in writer.pictures)
        ZipEntry(p.path, p.image.bytes, store: true),
    ];
    final bytes = DeterministicZip.encode(
      entries,
      modified: input.meta.modifiedAt,
      first: const ['mimetype'],
    );
    input.progress?.call(ExportPhase.packaging, 1);
    return ExportArtifact(
      fileName: ExportFileNames.fileName(
        options.fileName ?? input.meta.title,
        format.extension,
      ),
      mimeType: format.mimeType,
      bytes: bytes,
      warnings: List.unmodifiable(warnings),
    );
  }
}

const _xmlDecl = '<?xml version="1.0" encoding="UTF-8"?>\n';

const _nsDecl =
    'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
    'xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" '
    'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
    'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" '
    'xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" '
    'xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" '
    'xmlns:xlink="http://www.w3.org/1999/xlink" '
    'xmlns:dc="http://purl.org/dc/elements/1.1/" '
    'xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" '
    'xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" '
    'xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"';

const _settingsXml =
    '$_xmlDecl<office:document-settings '
    'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
    'xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0" '
    'office:version="1.3"><office:settings>'
    '<config:config-item-set config:name="ooo:configuration-settings">'
    '<config:config-item config:name="PrinterIndependentLayout" '
    'config:type="string">high-resolution</config:config-item>'
    '</config:config-item-set></office:settings></office:document-settings>';

// Style names shared by styles.xml and content.xml.
const _bullets = 'WonkyBullets';
const _numbers = 'WonkyNumbers';
const _tasks = 'WonkyTasks';
const _taskChecked = 'Task_20_Checked';
const _imageStyle = 'Wonky_20_Image';
const _ruleStyle = 'Horizontal_20_Line';
const _mentionStyle = 'Wonky_20_Mention';
const _tocDepth = 3;

/// ` name="value"` pairs (null values skipped), in insertion order.
String _attrs(Map<String, String?> attrs) {
  final b = StringBuffer();
  for (final e in attrs.entries) {
    final v = e.value;
    if (v == null) continue;
    b.write(' ${e.key}="${xmlAttr(v)}"');
  }
  return b.toString();
}

String _pt(double v) => OfficeUnits.pt(v);

String _color(int argb) => '#${rgbHex(flattenAlpha(argb))}'.toLowerCase();

String _weight(int w) => switch (w) {
  400 => 'normal',
  700 => 'bold',
  _ => '${(w.clamp(100, 900) / 100).round() * 100}',
};

/// An embedded picture part.
typedef _Picture = ({String path, OfficeImage image});

/// Writes ODF paragraph content: text with `text:s`, `text:tab` and
/// `text:line-break`, honoring ODF white-space collapsing across spans.
final class _TextOut {
  _TextOut(this.b);

  final StringBuffer b;

  /// Whether the last character written was literal non-space text (a
  /// literal space after it is preserved).
  var _literal = false;

  /// Writes an element that interrupts character data.
  void raw(String xml) {
    b.write(xml);
    _literal = false;
  }

  /// Writes a span/link start or end tag (no effect on white space).
  void tag(String xml) => b.write(xml);

  /// Writes character data.
  void text(String s) {
    var i = 0;
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (c == 0x20) {
        var n = 0;
        while (i < s.length && s.codeUnitAt(i) == 0x20) {
          n++;
          i++;
        }
        if (_literal) {
          b.write(' ');
          n--;
        }
        if (n == 1) {
          b.write('<text:s/>');
        } else if (n > 1) {
          b.write('<text:s text:c="$n"/>');
        }
        _literal = false;
        continue;
      }
      if (c == 0x09) {
        b.write('<text:tab/>');
        _literal = false;
        i++;
        continue;
      }
      if (c == 0x2028 || c == 0x2029 || c == 0x0A) {
        b.write('<text:line-break/>');
        _literal = false;
        i++;
        continue;
      }
      var j = i;
      while (j < s.length) {
        final d = s.codeUnitAt(j);
        if (d == 0x20 || d == 0x09 || d == 0x0A || d == 0x2028 || d == 0x2029) {
          break;
        }
        j++;
      }
      final seg = xmlText(s.substring(i, j).replaceAll('\r', ''));
      if (seg.isNotEmpty) {
        b.write(seg);
        _literal = true;
      }
      i = j;
    }
  }
}

/// Automatic styles of `content.xml`, deduplicated by content and named in
/// order of first use (`P1`, `T1`, `Ta1`, …).
final class _AutoStyles {
  final _names = <String, String>{};
  final _counts = <String, int>{};
  final out = StringBuffer();

  String add(
    String prefix,
    String family,
    String? parent,
    String inner, {
    Map<String, String> attrs = const {},
  }) {
    final head = _attrs({
      'style:family': family,
      'style:parent-style-name': parent,
      ...attrs,
    });
    final key = '$prefix|$head|$inner';
    final existing = _names[key];
    if (existing != null) return existing;
    final n = (_counts[prefix] ?? 0) + 1;
    _counts[prefix] = n;
    final name = '$prefix$n';
    out.write('<style:style style:name="$name"$head>$inner</style:style>');
    _names[key] = name;
    return name;
  }
}

/// One open `text:list` while writing a list run.
final class _OpenList {
  _OpenList(this.kind);

  /// `bullet`, `ordered` or `task`.
  final String kind;
  var itemOpen = false;
}

final class _OdtWriter {
  _OdtWriter(
    this.input,
    this.options,
    this.tree,
    this.t,
    this.images,
    this.warnings,
  ) : contentWidth = contentWidthPt(input, t),
      contentHeight = contentHeightPt(input, t) {
    for (final f in [
      t.body.style.fontFamily,
      for (final h in t.headings) h.style.fontFamily,
      t.blockquote.style.fontFamily,
      t.codeBlock.style.fontFamily,
      t.inlineCode.fontFamily,
      t.list.style.fontFamily,
      t.task.style.fontFamily,
      t.table.style.fontFamily,
      t.table.headerStyle.fontFamily,
      t.image.caption.style.fontFamily,
      t.rule.ornamentStyle.fontFamily,
      t.header.style.fontFamily,
      t.footer.style.fontFamily,
    ]) {
      fonts.add(f);
    }
  }

  final ExportInput input;
  final OfficeExportOptions options;
  final DocTree tree;
  final ResolvedWriteTheme t;
  final Map<String, OfficeImage> images;
  final List<ExportWarning> warnings;
  final double contentWidth;
  final double contentHeight;

  /// Font families in first-use order.
  final fonts = <String>{};

  /// Embedded pictures in order of first use.
  final pictures = <_Picture>[];
  final _picturePaths = <String, String>{};

  final _auto = _AutoStyles();
  final _body = StringBuffer();
  var _firstPending = true;
  var _frames = 0;
  var _tables = 0;

  // -------------------------------------------------------------------------
  // Parts

  String contentXml() {
    if (options.includeToc) _toc();
    _blocks(tree.blocks);
    if (tree.blocks.isEmpty && !options.includeToc) {
      _body.write('<text:p text:style-name="${_p('Standard')}"/>');
    }
    input.progress?.call(ExportPhase.layout, 1);
    return '$_xmlDecl<office:document-content $_nsDecl office:version="1.3">'
        '${fontFaceDecls()}'
        '<office:automatic-styles>${_auto.out}</office:automatic-styles>'
        '<office:body><office:text>$_body</office:text></office:body>'
        '</office:document-content>';
  }

  /// Paragraph properties of the Wonky container being written (Write 11
  /// §9): shading, left border and nesting indent; empty outside one.
  var _boxProps = const <String, String>{};

  void _blocks(List<DocBlock> blocks) {
    var i = 0;
    while (i < blocks.length) {
      if (i % 64 == 0) {
        input.cancel?.throwIfCancelled();
        input.progress?.call(ExportPhase.layout, i / blocks.length);
      }
      final b = blocks[i];
      if (b is ListItemBlock || b is TaskBlock) {
        // A list inside a quote is its own run (Write 02 §1.2).
        var j = i;
        while (j < blocks.length &&
            (blocks[j] is ListItemBlock || blocks[j] is TaskBlock) &&
            isInQuote(blocks[j]) == isInQuote(b)) {
          j++;
        }
        _listRun(blocks.sublist(i, j));
        i = j;
        continue;
      }
      switch (b) {
        case ContainerBlock():
          _container(b);
        case YouTubeBlock():
          // Links ([DocTree.withVideosAsLinks]).
          break;
        case GridBlock():
          _grid(b);
        case ParagraphBlock(:final runs):
          _paragraph(_p('Standard'), runs);
        case HeadingBlock():
          _heading(b);
        case QuoteBlock(:final lines):
          _quote(lines);
        case CodeBlock():
          _code(b);
        case ImageBlock():
          _image(b);
        case RuleBlock():
          _rule();
        case TableBlock():
          _table(b);
        case ListItemBlock() || TaskBlock():
          break; // handled above
      }
      i++;
    }
  }

  /// A Wonky container: a callout's title or a details summary as a bold
  /// paragraph, then the content, all with the container's shading.
  void _container(ContainerBlock c) {
    final w = t.wonky;
    final frame = c.frame;
    final saved = _boxProps;
    final depth =
        (saved['wonky-depth'] == null ? 0 : int.parse(saved['wonky-depth']!)) +
        1;
    int? background;
    BorderPt? border;
    switch (frame.type) {
      case BoxType.callout:
        final cc = w.callout.colorsFor(
          (frame.variant ?? CalloutVariant.info).value,
        );
        background = cc.background;
        border = BorderPt(
          width: math.max(w.callout.borderWidth, 1.5) * 2,
          style: LineStyle.solid,
          color: cc.border,
        );
      case BoxType.details:
        background = w.details.background;
        border = w.details.border;
      case BoxType.card:
        background = w.card.background;
    }
    _boxProps = {
      'wonky-depth': '$depth',
      if (background != null) 'fo:background-color': _color(background),
      if (border != null && border.isVisible) ...{
        'fo:border-left': '${_pt(border.width)} solid ${_color(border.color)}',
        'fo:padding-left': _pt(6),
      },
      if (depth > 1) 'fo:margin-left': _pt(12.0 * (depth - 1)),
    };
    switch (frame.type) {
      case BoxType.callout:
        final cc = w.callout.colorsFor(
          (frame.variant ?? CalloutVariant.info).value,
        );
        final span = _textStyle({
          'fo:font-weight': 'bold',
          'fo:color': _color(cc.title),
        });
        _body
          ..write(
            '<text:p text:style-name="${_p('Standard', {'fo:keep-with-next': 'always'})}">',
          )
          ..write('<text:span text:style-name="$span">')
          ..write(xmlText(frame.calloutLabel))
          ..write('</text:span></text:p>');
      case BoxType.details:
        _paragraph(_p('Standard', {'fo:keep-with-next': 'always'}), [
          for (final r in c.summary?.runs ?? const <InlineRun>[])
            r.code ? r : r.copyWith(bold: true),
        ]);
      case BoxType.card:
        break;
    }
    _blocks(c.body);
    _boxProps = saved;
  }

  /// A Wonky grid as a borderless table (Write 11 §9).
  void _grid(GridBlock g) {
    _tables++;
    final cols = g.columns.clamp(1, 4);
    final tableStyle = _auto.add(
      'Ta',
      'table',
      null,
      '<style:table-properties${_attrs({'style:width': _pt(contentWidth), 'table:align': 'margins', 'fo:margin-top': _pt(t.wonky.grid.spaceBefore), 'fo:margin-bottom': _pt(t.wonky.grid.spaceAfter)})}/>',
    );
    final colStyle = _auto.add(
      'Co',
      'table-column',
      null,
      '<style:table-column-properties${_attrs({'style:column-width': _pt(contentWidth / cols), 'style:rel-column-width': '1000*'})}/>',
    );
    final glyph = switch (g.bullets) {
      GridBullets.check => '✓ ',
      GridBullets.circle => '• ',
      GridBullets.none => '',
    };
    final bullet = _textStyle({
      'fo:font-weight': 'bold',
      'fo:color': _color(t.wonky.grid.bulletColor),
    });
    final para = _p('Standard', {'fo:margin-bottom': _pt(t.wonky.grid.rowGap)});
    _body
      ..write(
        '<table:table table:name="Table$_tables" table:style-name="$tableStyle">',
      )
      ..write(
        '<table:table-column table:style-name="$colStyle"'
        '${cols > 1 ? ' table:number-columns-repeated="$cols"' : ''}/>',
      );
    for (var r = 0; r * cols < g.items.length; r++) {
      _body.write('<table:table-row>');
      for (var c = 0; c < cols; c++) {
        final k = r * cols + c;
        _body.write('<table:table-cell office:value-type="string">');
        if (k < g.items.length) {
          _paragraph(
            para,
            g.items[k],
            lead: glyph.isEmpty
                ? ''
                : '<text:span text:style-name="$bullet">$glyph</text:span>',
          );
        } else {
          _body.write('<text:p text:style-name="$para"/>');
        }
        _body.write('</table:table-cell>');
      }
      _body.write('</table:table-row>');
    }
    _body.write('</table:table>');
  }

  String metaXml() {
    final m = input.meta;
    final title = m.title?.trim();
    final author = exportAuthor(input)?.trim();
    final language = m.language?.trim();
    final description = m.description?.trim();
    final b = StringBuffer(_xmlDecl)
      ..write(
        '<office:document-meta '
        'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
        'xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:xlink="http://www.w3.org/1999/xlink" office:version="1.3">'
        '<office:meta>',
      )
      ..write('<meta:generator>Wonky Write</meta:generator>');
    if (title != null && title.isNotEmpty) {
      b.write('<dc:title>${xmlText(title)}</dc:title>');
    }
    if (description != null && description.isNotEmpty) {
      b.write('<dc:description>${xmlText(description)}</dc:description>');
    }
    if (author != null && author.isNotEmpty) {
      b
        ..write(
          '<meta:initial-creator>${xmlText(author)}</meta:initial-creator>',
        )
        ..write('<dc:creator>${xmlText(author)}</dc:creator>');
    }
    b
      ..write(
        '<meta:creation-date>'
        '${isoTimestamp(m.createdAt ?? m.modifiedAt)}</meta:creation-date>',
      )
      ..write('<dc:date>${isoTimestamp(m.modifiedAt)}</dc:date>');
    if (language != null && language.isNotEmpty) {
      b.write('<dc:language>${xmlText(language)}</dc:language>');
    }
    b.write('</office:meta></office:document-meta>');
    return b.toString();
  }

  String manifestXml() {
    final b = StringBuffer(_xmlDecl)
      ..write(
        '<manifest:manifest '
        'xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" '
        'manifest:version="1.3">'
        '<manifest:file-entry manifest:full-path="/" manifest:version="1.3" '
        'manifest:media-type="${ExportFormat.odt.mimeType}"/>',
      );
    for (final part in const [
      'content.xml',
      'styles.xml',
      'meta.xml',
      'settings.xml',
    ]) {
      b.write(
        '<manifest:file-entry manifest:full-path="$part" '
        'manifest:media-type="text/xml"/>',
      );
    }
    for (final p in pictures) {
      b.write(
        '<manifest:file-entry manifest:full-path="${xmlAttr(p.path)}" '
        'manifest:media-type="${p.image.mime}"/>',
      );
    }
    b.write('</manifest:manifest>');
    return b.toString();
  }

  // -------------------------------------------------------------------------
  // Automatic styles

  /// The style for a body paragraph derived from [parent] with [para]
  /// overrides. The first body paragraph also carries the master page and
  /// the page number start.
  String _p(String parent, [Map<String, String> para = const {}]) {
    var attrs = const <String, String>{};
    var props = _boxProps.isEmpty
        ? para
        : {
            for (final e in _boxProps.entries)
              if (e.key != 'wonky-depth') e.key: e.value,
            ...para,
          };
    if (_firstPending) {
      _firstPending = false;
      attrs = const {'style:master-page-name': 'Standard'};
      final start = input.pageSetup.pageNumberStart;
      if (start != 1) {
        props = {...para, 'style:page-number': '${math.max(1, start)}'};
      }
    }
    if (props.isEmpty && attrs.isEmpty) return parent;
    return _auto.add(
      'P',
      'paragraph',
      parent,
      props.isEmpty ? '' : '<style:paragraph-properties${_attrs(props)}/>',
      attrs: attrs,
    );
  }

  /// An automatic text style.
  String _textStyle(Map<String, String> props, {String? parent}) => _auto.add(
    'T',
    'text',
    parent,
    '<style:text-properties${_attrs(props)}/>',
  );

  /// Margins of item [index] of [count] grouped paragraphs.
  static Map<String, String> _groupMargins(
    int index,
    int count, {
    required double before,
    required double after,
  }) => {
    if (index == 0) 'fo:margin-top': _pt(before),
    if (index == count - 1) 'fo:margin-bottom': _pt(after),
  };

  // -------------------------------------------------------------------------
  // Inline content

  void _paragraph(
    String style,
    List<InlineRun> runs, {
    String tag = 'text:p',
    String attrs = '',
    String lead = '',
  }) {
    if (runs.isEmpty && lead.isEmpty) {
      _body.write('<$tag text:style-name="$style"$attrs/>');
      return;
    }
    _body.write('<$tag text:style-name="$style"$attrs>$lead');
    final o = _TextOut(_body);
    _runs(o, runs);
    _body.write('</$tag>');
  }

  void _runs(_TextOut o, List<InlineRun> runs) {
    var i = 0;
    while (i < runs.length) {
      final link = runs[i].link;
      var j = i + 1;
      while (j < runs.length && runs[j].link == link) {
        j++;
      }
      if (link != null) {
        final href = runs[i].mentionUserUuid != null
            ? link
            : input.links.resolve(link);
        o.tag(
          '<text:a${_attrs({'xlink:type': 'simple', 'xlink:href': href, 'text:style-name': 'Internet_20_link', 'text:visited-style-name': 'Visited_20_Internet_20_Link'})}>',
        );
      }
      for (var k = i; k < j; k++) {
        final r = runs[k];
        final style = _runStyle(r);
        if (style == null) {
          o.text(r.text);
        } else {
          o.tag('<text:span text:style-name="$style">');
          o.text(r.text);
          o.tag('</text:span>');
        }
      }
      if (link != null) o.tag('</text:a>');
      i = j;
    }
  }

  String? _runStyle(InlineRun r) {
    if (r.code) return 'Source_20_Text';
    if (r.chip) {
      return _textStyle({
        'fo:background-color': _color(t.wonky.chip.background),
        'fo:color': _color(t.wonky.chip.color),
      });
    }
    if (r.linkStyle != null) {
      return _textStyle({'fo:font-weight': 'bold'});
    }
    final parent = r.mentionUserUuid != null ? _mentionStyle : null;
    if (!r.bold && !r.italic && !r.strike) return parent;
    final props = <String, String>{
      if (r.bold) 'fo:font-weight': _weight(t.bold.fontWeight ?? 700),
      if (r.bold && t.bold.color != null) 'fo:color': _color(t.bold.color!),
      if (r.italic) 'fo:font-style': t.italic.oblique ? 'oblique' : 'italic',
      if (r.italic && t.italic.color != null && !r.bold)
        'fo:color': _color(t.italic.color!),
      if (r.strike) ...{
        'style:text-line-through-style': 'solid',
        'style:text-line-through-type': 'single',
        'style:text-line-through-width': t.strike.lineThickness > 0
            ? _pt(t.strike.lineThickness)
            : 'auto',
        'style:text-line-through-color': t.strike.lineColor == null
            ? 'font-color'
            : _color(t.strike.lineColor!),
        if (t.strike.color != null) 'fo:color': _color(t.strike.color!),
      },
    };
    return _textStyle(props, parent: parent);
  }

  // -------------------------------------------------------------------------
  // Blocks

  void _heading(HeadingBlock h) {
    final level = h.level.clamp(1, 6);
    final style = _p('Heading_20_$level');
    final bookmark =
        (h.anchorId.isEmpty
            ? ''
            : '<text:bookmark text:name="${xmlAttr(h.anchorId)}"/>') +
        (h.step == null ? '' : xmlText('${h.step}. '));
    _paragraph(
      style,
      h.runs,
      tag: 'text:h',
      attrs: ' text:outline-level="$level"',
      lead: bookmark,
    );
  }

  void _quote(List<List<InlineRun>> lines) {
    final box = t.blockquote.box;
    for (var i = 0; i < lines.length; i++) {
      _paragraph(
        _p('Quotations', {
          if (i < lines.length - 1)
            'fo:margin-bottom': _pt(t.body.box.spaceAfter),
          ..._groupMargins(
            i,
            lines.length,
            before: box.spaceBefore,
            after: box.spaceAfter,
          ),
        }),
        lines[i],
      );
    }
  }

  void _code(CodeBlock c) {
    final box = t.codeBlock.box;
    final lines = highlightedCodeLines(c.text, c.language);
    for (var i = 0; i < lines.length; i++) {
      final style = _p(
        'Preformatted_20_Text',
        _groupMargins(
          i,
          lines.length,
          before: box.spaceBefore,
          after: box.spaceAfter,
        ),
      );
      final pieces = lines[i];
      if (pieces.isEmpty) {
        _body.write('<text:p text:style-name="$style"/>');
        continue;
      }
      _body.write('<text:p text:style-name="$style">');
      final o = _TextOut(_body);
      for (final piece in pieces) {
        final ts = piece.token == null ? null : t.syntax[piece.token];
        if (ts == null) {
          o.text(piece.text);
          continue;
        }
        final style = _textStyle({
          'fo:color': _color(ts.color),
          if (ts.italic) 'fo:font-style': 'italic',
          if (ts.fontWeight != null) 'fo:font-weight': _weight(ts.fontWeight!),
        });
        o.tag('<text:span text:style-name="$style">');
        o.text(piece.text);
        o.tag('</text:span>');
      }
      _body.write('</text:p>');
    }
  }

  void _image(ImageBlock block) {
    final image = images[block.src];
    final title = block.title?.trim();
    final caption = title != null && title.isNotEmpty && t.image.caption.show;
    if (image == null) {
      final alt = block.alt.trim();
      _paragraph(_p('Standard'), [
        InlineRun(alt.isEmpty ? '[Image]' : '[Image: $alt]'),
      ]);
      return;
    }
    final path = _picturePaths.putIfAbsent(block.src, () {
      final p = 'Pictures/image${pictures.length + 1}.${image.extension}';
      pictures.add((path: p, image: image));
      return p;
    });
    final maxWidth = t.image.maxWidth
        .resolve(contentWidth)
        .clamp(1.0, contentWidth);
    final (w, h) = image.fit(maxWidth, contentHeight);
    final frameStyle = _auto.add(
      'fr',
      'graphic',
      'Graphics',
      '<style:graphic-properties${_attrs({'style:vertical-pos': 'top', 'style:vertical-rel': 'baseline', 'style:horizontal-pos': 'center', 'style:horizontal-rel': 'paragraph', 'style:mirror': 'none', 'fo:clip': 'rect(0pt, 0pt, 0pt, 0pt)'})}/>',
    );
    _frames++;
    final style = _p(_imageStyle, {if (caption) 'fo:margin-bottom': _pt(0)});
    final alt = block.alt.trim();
    _body
      ..write('<text:p text:style-name="$style">')
      ..write(
        '<draw:frame${_attrs({'draw:style-name': frameStyle, 'draw:name': 'Image$_frames', 'text:anchor-type': 'as-char', 'svg:width': _pt(w), 'svg:height': _pt(h), 'draw:z-index': '0'})}>',
      )
      ..write(
        '<draw:image${_attrs({'xlink:href': path, 'xlink:type': 'simple', 'xlink:show': 'embed', 'xlink:actuate': 'onLoad'})}/>',
      );
    if (alt.isNotEmpty) {
      _body
        ..write('<svg:title>${xmlText(alt)}</svg:title>')
        ..write('<svg:desc>${xmlText(alt)}</svg:desc>');
    }
    _body.write('</draw:frame></text:p>');
    if (caption) _paragraph('Caption', [InlineRun(title)]);
  }

  void _rule() {
    final style = _p(_ruleStyle);
    final r = t.rule;
    if (r.style == RuleStyle.ornament && r.ornament.isNotEmpty) {
      _paragraph(style, [InlineRun(r.ornament)]);
    } else {
      _body.write('<text:p text:style-name="$style"/>');
    }
  }

  // -------------------------------------------------------------------------
  // Lists

  void _listRun(List<DocBlock> items) {
    final stack = <_OpenList>[];
    final box = t.list.box;
    void closeItem(_OpenList l) {
      if (l.itemOpen) {
        _body.write('</text:list-item>');
        l.itemOpen = false;
      }
    }

    void closeTop() {
      final l = stack.removeLast();
      closeItem(l);
      _body.write('</text:list>');
    }

    void open(String kind) {
      final style = switch (kind) {
        'ordered' => _numbers,
        'task' => _tasks,
        _ => _bullets,
      };
      final restart = stack.isEmpty && kind == 'ordered'
          ? ' text:continue-numbering="false"'
          : '';
      _body.write('<text:list text:style-name="$style"$restart>');
      stack.add(_OpenList(kind));
    }

    for (var n = 0; n < items.length; n++) {
      final item = items[n];
      final (kind, indent, runs, checked) = switch (item) {
        ListItemBlock(:final kind, :final indent, :final runs) => (
          kind == ListKindIr.ordered ? 'ordered' : 'bullet',
          indent,
          runs,
          null,
        ),
        TaskBlock(:final checked, :final indent, :final runs) => (
          'task',
          indent,
          runs,
          checked,
        ),
        _ => ('bullet', 0, const <InlineRun>[], null),
      };
      final level = indent.clamp(0, 8);
      while (stack.length > level + 1) {
        closeTop();
      }
      if (stack.length == level + 1 && stack.last.kind != kind) closeTop();
      while (stack.length < level + 1) {
        if (stack.isNotEmpty && !stack.last.itemOpen) {
          _body.write('<text:list-item>');
          stack.last.itemOpen = true;
        }
        open(kind);
      }
      final list = stack.last;
      closeItem(list);
      _body.write('<text:list-item>');
      list.itemOpen = true;
      // Quoted items take the quote's bar, padding and background.
      final style = _p(
        checked == true
            ? _taskChecked
            : isInQuote(item)
            ? 'Quotations'
            : 'List_20_Paragraph',
        _groupMargins(
          n,
          items.length,
          before: box.spaceBefore,
          after: math.max(box.spaceAfter, t.list.itemSpacing),
        ),
      );
      var lead = '';
      if (checked != null) {
        final glyph = checked ? '☒' : '☐';
        lead = checked && t.task.checkedStrike
            ? '<text:span text:style-name="${_textStyle({'style:text-line-through-style': 'none'})}">$glyph</text:span> '
            : '$glyph ';
      }
      _paragraph(style, runs, lead: lead);
    }
    while (stack.isNotEmpty) {
      closeTop();
    }
  }

  // -------------------------------------------------------------------------
  // Tables

  void _table(TableBlock tb) {
    _tables++;
    final tbl = t.table;
    var cols = tb.columnCount;
    for (final r in tb.rows) {
      cols = math.max(cols, r.length);
    }
    cols = math.max(1, cols);
    final rows = tb.rows.isEmpty
        ? [List<List<InlineRun>>.filled(cols, const [])]
        : tb.rows;
    var attrs = const <String, String>{};
    final props = <String, String>{
      'style:width': _pt(contentWidth),
      'table:align': 'margins',
      'fo:margin-top': _pt(tbl.box.spaceBefore),
      'fo:margin-bottom': _pt(tbl.box.spaceAfter),
      'table:border-model': 'collapsing',
    };
    if (_firstPending) {
      _firstPending = false;
      attrs = const {'style:master-page-name': 'Standard'};
      final start = input.pageSetup.pageNumberStart;
      if (start != 1) props['style:page-number'] = '${math.max(1, start)}';
    }
    final tableStyle = _auto.add(
      'Ta',
      'table',
      null,
      '<style:table-properties${_attrs(props)}/>',
      attrs: attrs,
    );
    final colStyle = _auto.add(
      'Co',
      'table-column',
      null,
      '<style:table-column-properties${_attrs({'style:column-width': _pt(contentWidth / cols), 'style:rel-column-width': '1000*'})}/>',
    );
    _body
      ..write(
        '<table:table table:name="Table$_tables" table:style-name="$tableStyle">',
      )
      ..write(
        '<table:table-column table:style-name="$colStyle"'
        '${cols > 1 ? ' table:number-columns-repeated="$cols"' : ''}/>',
      );
    for (var r = 0; r < rows.length; r++) {
      if (r == 0) _body.write('<table:table-header-rows>');
      _body.write('<table:table-row>');
      for (var c = 0; c < cols; c++) {
        final runs = c < rows[r].length ? rows[r][c] : const <InlineRun>[];
        final align = c < tb.align.length ? tb.align[c] : null;
        _body.write(
          '<table:table-cell table:style-name="${_cellStyle(r, c, rows.length, cols)}" office:value-type="string">',
        );
        _paragraph(_cellParagraph(header: r == 0, align: align), runs);
        _body.write('</table:table-cell>');
      }
      _body.write('</table:table-row>');
      if (r == 0) _body.write('</table:table-header-rows>');
    }
    _body.write('</table:table>');
  }

  String _cellParagraph({required bool header, required CellAlign? align}) {
    final parent = header ? 'Table_20_Heading' : 'Table_20_Contents';
    if (align == null) return parent;
    final a = switch (align) {
      CellAlign.left => 'start',
      CellAlign.center => 'center',
      CellAlign.right => 'end',
    };
    return _auto.add(
      'P',
      'paragraph',
      parent,
      '<style:paragraph-properties fo:text-align="$a"/>',
    );
  }

  String _cellStyle(int r, int c, int rows, int cols) {
    final tbl = t.table;
    final border =
        '${_pt(math.max(0.1, tbl.borderWidth))} solid ${_color(tbl.borderColor)}';
    final lastRow = r == rows - 1;
    final lastCol = c == cols - 1;
    final (top, right, bottom, left) = switch (tbl.borders) {
      TableBorders.all => (r == 0, true, true, c == 0),
      TableBorders.horizontal => (r == 0, false, true, false),
      TableBorders.outer => (r == 0, lastCol, lastRow, c == 0),
      TableBorders.headerOnly => (false, false, r == 0, false),
      TableBorders.none => (false, false, false, false),
    };
    int? background;
    if (r == 0) {
      background = tbl.headerBackground;
    } else if (tbl.zebra && tbl.zebraColor != null && r.isEven) {
      background = tbl.zebraColor;
    }
    final p = tbl.cellPadding;
    final props = <String, String>{
      if (background != null) 'fo:background-color': _color(background),
      'fo:padding-top': _pt(p.top),
      'fo:padding-right': _pt(p.right),
      'fo:padding-bottom': _pt(p.bottom),
      'fo:padding-left': _pt(p.left),
      'fo:border-top': top ? border : 'none',
      'fo:border-right': right ? border : 'none',
      'fo:border-bottom': bottom ? border : 'none',
      'fo:border-left': left ? border : 'none',
    };
    return _auto.add(
      'Ce',
      'table-cell',
      null,
      '<style:table-cell-properties${_attrs(props)}/>',
    );
  }

  // -------------------------------------------------------------------------
  // Table of contents

  void _toc() {
    final labels = allHeadingLabels(tree, t);
    const title = 'Contents';
    _body
      ..write(
        '<text:table-of-content text:protected="true" text:name="Table of Contents1">',
      )
      ..write('<text:table-of-content-source text:outline-level="$_tocDepth">')
      ..write(
        '<text:index-title-template text:style-name="Contents_20_Heading">$title</text:index-title-template>',
      );
    for (var level = 1; level <= _tocDepth; level++) {
      _body.write(
        '<text:table-of-content-entry-template text:outline-level="$level" '
        'text:style-name="Contents_20_$level">'
        '<text:index-entry-link-start/>'
        '<text:index-entry-chapter/>'
        '<text:index-entry-text/>'
        '<text:index-entry-tab-stop style:type="right" style:leader-char="."/>'
        '<text:index-entry-page-number/>'
        '<text:index-entry-link-end/>'
        '</text:table-of-content-entry-template>',
      );
    }
    _body
      ..write('</text:table-of-content-source>')
      ..write('<text:index-body>')
      ..write('<text:index-title text:name="Table of Contents1_Head">');
    _paragraph(_p('Contents_20_Heading'), const [InlineRun(title)]);
    _body.write('</text:index-title>');
    // Details summaries are bold paragraphs, not headings.
    final summaries = {
      for (final c in tree.allBlocks.whereType<ContainerBlock>()) ?c.summary,
    };
    for (final b in tree.allBlocks.whereType<HeadingBlock>()) {
      if (b.level > _tocDepth || summaries.contains(b)) continue;
      final text = '${labels[b] ?? ''}${runsPlainText(b.runs)}';
      if (text.trim().isEmpty) continue;
      _body.write('<text:p text:style-name="Contents_20_${b.level}">');
      final o = _TextOut(_body);
      if (b.anchorId.isNotEmpty) {
        o.tag(
          '<text:a${_attrs({'xlink:type': 'simple', 'xlink:href': '#${b.anchorId}'})}>',
        );
      }
      o.text(text);
      if (b.anchorId.isNotEmpty) o.tag('</text:a>');
      _body.write('</text:p>');
    }
    _body.write('</text:index-body></text:table-of-content>');
  }
}
