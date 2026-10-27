import 'package:super_editor/super_editor.dart';

import 'wonky_schema.dart';

/// A block embed without a node class of its own: a Wonky Markdown grid
/// (Write 11 §7.1) or an embed type the editor can't render. It keeps the raw
/// embed value in its metadata so that it round-trips unchanged.
class WonkyEmbedNode extends BlockNode {
  WonkyEmbedNode({required this.id, super.metadata}) {
    initAddToMetadata({
      NodeMetadata.blockType: const NamedAttribution('wonkyEmbed'),
    });
  }

  @override
  final String id;

  /// The embed type (first key of the embed value), e.g. `video`.
  String get embedType {
    final embed = getMetadataValue(WonkyNodeMetadata.embed);
    return embed is Map && embed.isNotEmpty ? '${embed.keys.first}' : 'unknown';
  }

  @override
  String? copyContent(NodeSelection selection) => null;

  @override
  bool hasEquivalentContent(DocumentNode other) =>
      other is WonkyEmbedNode && super.hasEquivalentContent(other);

  @override
  DocumentNode copyWithAddedMetadata(Map<String, dynamic> newProperties) =>
      WonkyEmbedNode(id: id, metadata: {...metadata, ...newProperties});

  @override
  DocumentNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) =>
      WonkyEmbedNode(id: id, metadata: newMetadata);
}
