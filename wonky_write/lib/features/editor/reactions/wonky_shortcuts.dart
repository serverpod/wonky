import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show BoxFrame, BoxType, Boxes, CalloutVariant, GridBullets, GridEmbed;

import '../attributions/wonky_attributions.dart';
import '../mapping/attribution_mapping.dart';
import '../mapping/wonky_embed_node.dart';
import '../mapping/wonky_schema.dart';
import 'pill_boundary.dart';

/// A Wonky Markdown block shortcut: `:::warning[Title]`, `:::details`,
/// `:::card` or `:::grid{columns=n bullets=b}` (Write 11 §7.4).
class WonkyBlockShortcut {
  const WonkyBlockShortcut({
    this.type,
    this.variant,
    this.title,
    this.grid = false,
    this.columns = 3,
    this.bullets = GridBullets.check,
  });

  final BoxType? type;
  final CalloutVariant? variant;
  final String? title;
  final bool grid;
  final int columns;
  final GridBullets bullets;
}

/// The Wonky Markdown shortcuts of the editor (Write 11 §7.4).
abstract final class WonkyShortcuts {
  static final _block = RegExp(
    r'^:::(info|tip|note|warning|caution|danger|details|card)(?:\[([^\]]*)\])?$',
  );
  static final _grid = RegExp(r'^:::grid(?:\s*\{([^}]*)\})?$');

  /// The block shortcut [text] (a whole paragraph's text) stands for.
  static WonkyBlockShortcut? block(String text) {
    final m = _block.firstMatch(text.trim());
    if (m != null) {
      final name = m.group(1)!;
      return switch (name) {
        'details' => const WonkyBlockShortcut(type: BoxType.details),
        'card' => const WonkyBlockShortcut(type: BoxType.card),
        _ => WonkyBlockShortcut(
          type: BoxType.callout,
          variant: CalloutVariant.tryParse(name),
          title: BoxFrame.canonicalTitle(m.group(2)),
        ),
      };
    }
    final g = _grid.firstMatch(text.trim());
    if (g == null) return null;
    final options = <String, String>{};
    for (final token in (g.group(1) ?? '').trim().split(RegExp(r'\s+'))) {
      final eq = token.indexOf('=');
      if (eq > 0) options[token.substring(0, eq)] = token.substring(eq + 1);
    }
    return WonkyBlockShortcut(
      grid: true,
      columns: GridEmbed.canonicalColumns(options['columns']),
      bullets: options['bullets'] == null
          ? GridBullets.check
          : GridBullets.parse(options['bullets']),
    );
  }

  /// The requests turning the paragraph [node] (whose shortcut text is
  /// deleted by the caller) into [shortcut]: a container frame on it (a
  /// details' first line becomes its summary, an H3), or a grid before it.
  static List<EditRequest> requestsFor(
    WonkyBlockShortcut shortcut,
    TextNode node,
    Document document,
    String Function() newId,
  ) {
    final host = boxOf(node);
    if (shortcut.grid) {
      final grid = GridEmbed(
        id: newId(),
        columns: shortcut.columns,
        bullets: shortcut.bullets,
        items: const ['', '', ''],
      );
      return [
        InsertNodeAtIndexRequest(
          nodeIndex: document.getNodeIndexById(node.id),
          newNode: WonkyEmbedNode(
            id: grid.id,
            metadata: {
              WonkyNodeMetadata.embed: grid.toInsert(),
              if (host.isNotEmpty) WonkyNodeMetadata.box: Boxes.toValue(host),
            },
          ),
        ),
      ];
    }
    final frame = shortcut.type == BoxType.callout
        ? BoxFrame.callout(
            id: newId(),
            variant: shortcut.variant ?? CalloutVariant.info,
            title: shortcut.title,
          )
        : BoxFrame(id: newId(), type: shortcut.type!);
    final box = Boxes.toValue([...host, frame]);
    return [
      ChangeNodeMetadataRequest(
        nodeId: node.id,
        metadata: {WonkyNodeMetadata.box: box},
      ),
      if (shortcut.type == BoxType.details) ...[
        ChangeParagraphBlockTypeRequest(
          nodeId: node.id,
          blockType: header3Attribution,
        ),
        InsertNodeAfterNodeRequest(
          existingNodeId: node.id,
          newNode: ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText(''),
            metadata: {WonkyNodeMetadata.box: box},
          ),
        ),
      ],
    ];
  }
}

/// Inline Wonky Markdown typed in Wonky documents (Write 11 §7.4):
/// `:chip[label]` on typing `]`, `:button[label](url)` and
/// `:link[label](url)` on typing `)` become the chip or styled link.
class WonkyInlineShortcutReaction extends EditReaction {
  const WonkyInlineShortcutReaction({this.boundary});

  /// The new element ends at the caret: typing goes after it.
  final PillBoundary? boundary;

  static final _chip = RegExp(r':chip\[([^\]\n]+)\]$');
  static final _link = RegExp(r':(button|link)\[([^\]\n]+)\]\(([^)\s]+)\)$');

  @override
  void react(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    // Runs after auto-pair: the typed closer may have overtyped the
    // auto-inserted one (an insertion followed by a deletion right after it).
    final edits = changeList
        .whereType<DocumentEdit>()
        .map((e) => e.change)
        .toList();
    if (edits.isEmpty) return;
    var insertion = edits.last;
    if (insertion is TextDeletedEvent && edits.length >= 2) {
      final deletion = insertion;
      insertion = edits[edits.length - 2];
      if (insertion is! TextInsertionEvent ||
          deletion.nodeId != insertion.nodeId ||
          deletion.offset != insertion.offset + 1) {
        return;
      }
    }
    if (insertion is! TextInsertionEvent) return;
    final typed = insertion.text.toPlainText();
    if (typed != ']' && typed != ')') return;
    final selection = editorContext.composer.selection;
    if (selection == null ||
        !selection.isCollapsed ||
        selection.extent.nodeId != insertion.nodeId) {
      return;
    }
    final node = editorContext.document.getNodeById(insertion.nodeId);
    final caret = selection.extent.nodePosition;
    if (node is! TextNode ||
        caret is! TextNodePosition ||
        isCodeBlockNode(node)) {
      return;
    }
    final before = node.text.toPlainText().substring(0, caret.offset);
    String label;
    Set<Attribution> attributions;
    final chip = _chip.firstMatch(before);
    final link = chip == null ? _link.firstMatch(before) : null;
    if (chip != null) {
      label = chip.group(1)!;
      attributions = {ChipAttribution.plain};
    } else if (link != null) {
      label = link.group(2)!;
      final url = Uri.tryParse(link.group(3)!);
      if (url == null || !url.hasScheme) return;
      attributions = {
        AttributionMapping.linkAttributionFor(link.group(3)!),
        link.group(1) == 'link'
            ? LinkStyleAttribution.arrow
            : LinkStyleAttribution.button,
      };
    } else {
      return;
    }
    final start = caret.offset - (chip ?? link)!.group(0)!.length;
    DocumentPosition at(int offset) => DocumentPosition(
      nodeId: node.id,
      nodePosition: TextNodePosition(offset: offset),
    );
    final text = AttributedText(label);
    for (final a in attributions) {
      text.addAttribution(a, SpanRange(0, label.length - 1));
    }
    requestDispatcher.execute([
      DeleteContentRequest(
        documentRange: DocumentRange(start: at(start), end: at(caret.offset)),
      ),
      InsertAttributedTextRequest(at(start), text),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(position: at(start + label.length)),
        SelectionChangeType.placeCaret,
        SelectionReason.contentChange,
      ),
    ]);
    boundary?.leaveAt(at(start + label.length));
    editorContext.composer.preferences.removeStyles(attributions);
  }
}
