import 'package:super_editor/super_editor.dart';

/// Delta attribute keys of the Wonky Delta Schema v1 used by the editor
/// mapping (Write 02 §1). Mirrors `WonkyAttr` of `wonky_write_core`.
abstract final class DeltaKeys {
  static const bold = 'bold';
  static const italic = 'italic';
  static const strike = 'strike';
  static const code = 'code';
  static const link = 'link';
  static const mention = 'mention';

  static const header = 'header';
  static const blockquote = 'blockquote';
  static const codeBlock = 'code-block';
  static const list = 'list';
  static const indent = 'indent';

  static const commentPrefix = 'cmt_';
  static const suggestionPrefix = 'sug_';

  /// Inline formatting keys (excluding links and mentions).
  static const formattingKeys = {bold, italic, strike, code};

  /// All inline keys.
  static const inlineKeys = {bold, italic, strike, code, link, mention};

  /// Block attribute keys.
  static const blockKeys = {header, blockquote, codeBlock, list, indent};

  static bool isComment(String key) =>
      key.startsWith(commentPrefix) && key.length > commentPrefix.length;

  static bool isSuggestion(String key) =>
      key.startsWith(suggestionPrefix) && key.length > suggestionPrefix.length;

  static bool isOverlay(String key) => isComment(key) || isSuggestion(key);

  /// Embed types.
  static const imageEmbed = 'image';
  static const dividerEmbed = 'divider';
  static const tableEmbed = 'table';

  /// The soft line break character inside a line (Shift+Enter).
  static const softBreak = ' ';

  /// Maximum list indent (levels 0–8).
  static const maxIndent = 8;
}

/// Node metadata keys the Write editor stores on super_editor nodes.
abstract final class WonkyNodeMetadata {
  /// Overlay attributes (`cmt_*`, `sug_*`) of the line-end `"\n"` of a node.
  static const lineAttributes = 'wonkyLineAttrs';

  /// The raw embed insert value of an embed node, e.g. `{"image": {...}}`.
  static const embed = 'wonkyEmbed';

  /// Overlay attributes of the embed insert itself.
  static const embedAttributes = 'wonkyEmbedAttrs';

  /// Language of a code block node (`""` = plain text). Shared with the
  /// vendored super_editor Quill serializer (patch SE-1).
  static const codeLanguage = codeLanguageMetadataKey;

  /// `true` on a list or task item inside a quote (Write 04 §14).
  static const quoted = 'wonkyQuoted';
}

/// Heading block type attributions by level (index 0 = level 1).
const headerAttributions = [
  header1Attribution,
  header2Attribution,
  header3Attribution,
  header4Attribution,
  header5Attribution,
  header6Attribution,
];

/// Returns the heading level (1–6) of [blockType], or `null`.
int? headingLevelOf(Object? blockType) {
  if (blockType is! NamedAttribution) {
    return null;
  }
  final index = headerAttributions.indexOf(blockType);
  return index < 0 ? null : index + 1;
}

/// The block type attribution of super_editor task nodes.
const taskBlockAttribution = NamedAttribution('task');

/// Whether [node] is a code block paragraph.
bool isCodeBlockNode(DocumentNode? node) =>
    node is ParagraphNode &&
    node.getMetadataValue(NodeMetadata.blockType) == codeAttribution;

/// The code language of a code block node (`""` when unset).
String codeLanguageOf(DocumentNode node) {
  final language = node.getMetadataValue(WonkyNodeMetadata.codeLanguage);
  return language is String ? language : '';
}

/// Whether [node] is a list or task item inside a quote (`blockquote: true`
/// next to `list`, Write 02 §1.2).
bool isQuotedListNode(DocumentNode? node) =>
    (node is ListItemNode || node is TaskNode) &&
    node!.getMetadataValue(WonkyNodeMetadata.quoted) == true;

/// Whether [node] is part of a quote: a quote line or a quoted list item.
bool isInQuoteNode(DocumentNode? node) =>
    isQuotedListNode(node) ||
    (node is ParagraphNode &&
        node.getMetadataValue(NodeMetadata.blockType) == blockquoteAttribution);
