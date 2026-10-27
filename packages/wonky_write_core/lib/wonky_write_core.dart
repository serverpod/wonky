/// Pure Dart core for Wonky Write: Delta schema, Markdown codec, OT helpers,
/// derived data, importers/exporters and the theme model.
///
/// Never imports Flutter; runs on the server (VM) and in the apps (VM + web).
library;

export 'package:dart_quill_delta/dart_quill_delta.dart' show Delta, Operation;

export 'src/delta/attributes.dart';
export 'src/delta/delta_utils.dart';
export 'src/delta/document.dart';
export 'src/delta/boxes.dart';
export 'src/delta/embeds.dart';
export 'src/delta/hash.dart';
export 'src/delta/links.dart';
export 'src/delta/normalizer.dart';
export 'src/delta/ot.dart';
export 'src/delta/validator.dart';
export 'src/derived/outline.dart';
export 'src/derived/stats.dart';
export 'src/ir/anchors.dart';
export 'src/collab/suggestion_view.dart';
export 'src/import/import_api.dart';
export 'src/ir/doc_tree.dart';
export 'src/ir/doc_tree_builder.dart';
export 'src/markdown/front_matter.dart';
export 'src/markdown/inline_markdown.dart';
export 'src/markdown/inline_reader.dart' show mentionTitlePrefix;
export 'src/markdown/inline_writer.dart';
export 'src/markdown/markdown_codec.dart';
export 'src/markdown/markdown_exporter.dart';
export 'src/markdown/wonky_to_gfm.dart';
export 'src/markdown/markdown_importer.dart'
    show MarkdownImporter, RelativeImageResolver;
export 'src/delta/delta_diff.dart';
export 'src/derived/plain_text.dart';
export 'src/edit/address.dart';
export 'src/edit/document_edits.dart';
export 'src/edit/document_reader.dart';
export 'src/edit/search.dart';
export 'src/collab/attributed_diff.dart';
export 'src/collab/overlay_index.dart';
export 'src/collab/suggestion_ops.dart';
export 'src/collab/suggestion_rewriter.dart';
export 'src/collab/op_shape_validator.dart';
export 'src/layout/header_footer_tokens.dart';
export 'src/layout/page_setup.dart';
export 'src/layout/pagination_engine.dart';
export 'src/export/docx/docx_exporter.dart' show DocxExporter;
export 'src/export/epub/epub_exporter.dart' show EpubExporter;
export 'src/export/export_api.dart';
export 'src/export/odt/odt_exporter.dart' show OdtExporter;
export 'src/export/rtf/rtf_exporter.dart' show RtfExporter;
export 'src/export/office/office_support.dart' show describeExportImage;
export 'src/export/html/html_writer.dart';
export 'src/export/markdown_file_exporter.dart';
export 'src/export/txt_exporter.dart';
export 'src/export/zip.dart';
export 'src/fonts/fonts.dart';
export 'src/highlight/highlight.dart';
export 'src/import/importers.dart';
export 'src/theme/theme.dart';
export 'src/export/html/html_exporter.dart';
export 'src/export/pdf/pdf.dart';
