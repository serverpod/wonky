import 'package:flutter/widgets.dart';

import 'package:wonky_write_core/wonky_write_core.dart'
    show BoxType, CalloutVariant;

import '../../../l10n/write_l10n.dart';
import '../commands/write_editor_commands.dart';
import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import 'trigger_queries.dart';

/// Groups of the slash menu (Write 04 §21.2).
enum SlashGroup { basic, media, insert, wonky }

/// One slash menu item. [run] executes the command (the `/query` text has
/// already been removed in the same undo step).
@immutable
class SlashItem {
  const SlashItem({
    required this.id,
    required this.title,
    required this.group,
    required this.commandId,
    this.aliases = const [],
    this.shortcut,
    this.suggestable = true,
    required this.run,
  });

  final String id;
  final String title;
  final SlashGroup group;

  /// The command this item invokes (for the shortcut label and MCP parity).
  final String commandId;
  final List<String> aliases;
  final String? shortcut;

  /// Whether the item is available in Suggesting mode (no tables).
  final bool suggestable;

  /// Runs the item. Items that need UI (image upload, link popover) call the
  /// [SlashHost] callbacks.
  final void Function(WriteEditorCommands commands, SlashHost host) run;
}

/// UI the slash menu delegates to the screen.
@immutable
class SlashHost {
  const SlashHost({
    this.onInsertImage,
    this.onInsertImageFromUrl,
    this.onInsertLink,
    this.onTableInserted,
    this.onComment,
    this.onMention,
    this.onAskAi,
    this.onContinueWriting,
    this.onEmoji,
    this.onSpecialCharacter,
    this.isWonky,
    this.onCommand,
  });

  /// Whether the document is in Wonky Markdown (shows the Wonky items,
  /// Write 11 §7.5).
  final bool Function()? isWonky;

  /// Runs a (screen) command, e.g. `write.insert.button`.
  final void Function(String commandId, Map<String, Object?> args)? onCommand;

  final VoidCallback? onInsertImage;
  final VoidCallback? onInsertImageFromUrl;
  final VoidCallback? onInsertLink;

  /// Opens the table editor for a newly inserted table (§18.3).
  final void Function(String tableId)? onTableInserted;
  final VoidCallback? onComment;
  final VoidCallback? onMention;

  /// The inline AI prompt (`/ai`, Write 09 §5.3); null hides the AI items.
  final VoidCallback? onAskAi;

  /// Continue writing (`/ai continue`, Write 09 §5.4).
  final VoidCallback? onContinueWriting;

  /// The emoji picker (`/emoji`, Write 04 §20.1).
  final VoidCallback? onEmoji;

  /// The special characters dialog (`/special`, Write 04 §20.2).
  final VoidCallback? onSpecialCharacter;
}

/// The slash menu items.
List<SlashItem> defaultSlashItems([WriteLocalizations? strings]) {
  final l = strings ?? writeL10nEnglish;
  return [
    SlashItem(
      id: 'text',
      title: l.slashText,
      group: SlashGroup.basic,
      commandId: 'write.format.blockType',
      aliases: const ['p', 'normal', 'paragraph'],
      run: (c, h) => c.setBlockType(BlockKind.paragraph, toggle: false),
    ),
    for (var level = 1; level <= 6; level += 1)
      SlashItem(
        id: 'h$level',
        title: l.slashHeading(level),
        group: SlashGroup.basic,
        commandId: 'write.format.blockType',
        aliases: ['h$level', if (level == 1) 'title', 'heading'],
        run: (c, h) => c.setBlockType(
          BlockKind.values[BlockKind.heading1.index + level - 1],
          toggle: false,
        ),
      ),
    SlashItem(
      id: 'bulleted',
      title: l.slashBulletedList,
      group: SlashGroup.basic,
      commandId: 'write.list.toggleBulleted',
      aliases: const ['ul', 'bullet', '-'],
      run: (c, h) => c.setBlockType(BlockKind.bulleted, toggle: false),
    ),
    SlashItem(
      id: 'numbered',
      title: l.slashNumberedList,
      group: SlashGroup.basic,
      commandId: 'write.list.toggleNumbered',
      aliases: const ['ol', '1.'],
      run: (c, h) => c.setBlockType(BlockKind.numbered, toggle: false),
    ),
    SlashItem(
      id: 'checklist',
      title: l.slashChecklist,
      group: SlashGroup.basic,
      commandId: 'write.list.toggleChecklist',
      aliases: const ['todo', 'task', '[]'],
      run: (c, h) => c.setBlockType(BlockKind.checklist, toggle: false),
    ),
    SlashItem(
      id: 'quote',
      title: l.slashQuote,
      group: SlashGroup.basic,
      commandId: 'write.format.blockType',
      aliases: const ['blockquote', '>'],
      run: (c, h) => c.setBlockType(BlockKind.quote, toggle: false),
    ),
    SlashItem(
      id: 'code',
      title: l.slashCodeBlock,
      group: SlashGroup.basic,
      commandId: 'write.format.blockType',
      aliases: const ['code', 'pre', '```'],
      run: (c, h) => c.setBlockType(BlockKind.codeBlock, toggle: false),
    ),
    SlashItem(
      id: 'divider',
      title: l.slashDivider,
      group: SlashGroup.basic,
      commandId: 'write.insert.divider',
      aliases: const ['hr', '---', 'line'],
      run: (c, h) => c.insertDivider(),
    ),
    SlashItem(
      id: 'image',
      title: l.slashImage,
      group: SlashGroup.media,
      commandId: 'write.insert.image',
      aliases: const ['img', 'picture', 'upload'],
      run: (c, h) => h.onInsertImage?.call(),
    ),
    SlashItem(
      id: 'imageUrl',
      title: l.slashImageFromUrl,
      group: SlashGroup.media,
      commandId: 'write.insert.imageFromUrl',
      aliases: const ['image url', 'url'],
      run: (c, h) => h.onInsertImageFromUrl?.call(),
    ),
    SlashItem(
      id: 'table',
      title: l.slashTable,
      group: SlashGroup.media,
      commandId: 'write.insert.table',
      aliases: const ['grid'],
      suggestable: false,
      run: (c, h) {
        final id = c.insertTable();
        if (id != null) h.onTableInserted?.call(id);
      },
    ),
    SlashItem(
      id: 'link',
      title: l.slashLink,
      group: SlashGroup.insert,
      commandId: 'write.link.insert',
      aliases: const ['url', 'href'],
      run: (c, h) => h.onInsertLink?.call(),
    ),
    SlashItem(
      id: 'mention',
      title: l.slashMentionPerson,
      group: SlashGroup.insert,
      commandId: 'write.insert.mention',
      aliases: const ['@', 'person', 'user'],
      run: (c, h) {
        c.insertText('@', label: l.undoMention);
        h.onMention?.call();
      },
    ),
    SlashItem(
      id: 'comment',
      title: l.slashComment,
      group: SlashGroup.insert,
      commandId: 'shell.comments.create',
      aliases: const ['note'],
      run: (c, h) => h.onComment?.call(),
    ),
    SlashItem(
      id: 'emoji',
      title: l.slashEmoji,
      group: SlashGroup.insert,
      commandId: 'write.insert.emoji',
      aliases: const ['smiley', 'emoticon'],
      run: (c, h) => h.onEmoji?.call(),
    ),
    SlashItem(
      id: 'specialCharacter',
      title: l.slashSpecialCharacters,
      group: SlashGroup.insert,
      commandId: 'write.insert.specialCharacter',
      aliases: const ['special', 'symbol', 'character', 'unicode'],
      run: (c, h) => h.onSpecialCharacter?.call(),
    ),
    SlashItem(
      id: 'ai',
      title: l.slashAskAi,
      group: SlashGroup.insert,
      commandId: 'write.ai.inline',
      aliases: const ['ai', 'assistant', 'generate', 'write'],
      run: (c, h) => h.onAskAi?.call(),
    ),
    SlashItem(
      id: 'aiContinue',
      title: l.slashContinueWriting,
      group: SlashGroup.insert,
      commandId: 'write.ai.continue',
      aliases: const ['ai continue', 'continue', 'ai'],
      run: (c, h) => h.onContinueWriting?.call(),
    ),
    // Wonky Markdown (Write 11 §7.5).
    for (final (variant, name, aliases) in [
      ('info', l.calloutInfo, const ['callout', 'admonition', 'alert']),
      ('tip', l.calloutTip, const ['hint']),
      ('note', l.calloutNote, const <String>[]),
      ('warning', l.calloutWarning, const ['heads up']),
      ('caution', l.calloutCaution, const <String>[]),
      ('danger', l.calloutDanger, const ['error']),
    ])
      SlashItem(
        id: 'callout.$variant',
        title: l.slashCallout(name),
        group: SlashGroup.wonky,
        commandId: 'write.insert.callout',
        aliases: [variant, 'callout $variant', ...aliases],
        run: (c, h) => c.insertContainer(
          BoxType.callout,
          variant: CalloutVariant.tryParse(variant),
        ),
      ),
    SlashItem(
      id: 'details',
      title: l.cmdInsertDetails,
      group: SlashGroup.wonky,
      commandId: 'write.insert.details',
      aliases: const ['faq', 'toggle', 'collapsible', 'expandable'],
      run: (c, h) => c.insertContainer(BoxType.details),
    ),
    SlashItem(
      id: 'card',
      title: l.cmdInsertCard,
      group: SlashGroup.wonky,
      commandId: 'write.insert.card',
      aliases: const ['box', 'panel'],
      run: (c, h) => c.insertContainer(BoxType.card),
    ),
    SlashItem(
      id: 'grid',
      title: l.cmdInsertGrid,
      group: SlashGroup.wonky,
      commandId: 'write.insert.grid',
      aliases: const ['features', 'columns', 'checklist grid'],
      suggestable: false,
      run: (c, h) => c.insertGrid(),
    ),
    SlashItem(
      id: 'youtube',
      title: l.cmdInsertYouTube.replaceAll('…', ''),
      group: SlashGroup.wonky,
      commandId: 'write.insert.youtube',
      aliases: const ['video', 'embed', 'movie'],
      suggestable: false,
      run: (c, h) => h.onCommand?.call('write.insert.youtube', const {}),
    ),
    SlashItem(
      id: 'button',
      title: l.cmdInsertButton,
      group: SlashGroup.wonky,
      commandId: 'write.insert.button',
      aliases: const ['cta', 'call to action'],
      run: (c, h) => h.onCommand?.call('write.insert.button', const {}),
    ),
    SlashItem(
      id: 'buttonSecondary',
      title: l.linkStyleButtonSecondary,
      group: SlashGroup.wonky,
      commandId: 'write.insert.button',
      aliases: const ['button secondary'],
      run: (c, h) => h.onCommand?.call('write.insert.button', const {
        'variant': 'secondary',
      }),
    ),
    SlashItem(
      id: 'arrowLink',
      title: l.cmdInsertArrowLink,
      group: SlashGroup.wonky,
      commandId: 'write.insert.arrowLink',
      aliases: const ['link arrow', 'more link'],
      run: (c, h) => h.onCommand?.call('write.insert.arrowLink', const {}),
    ),
    SlashItem(
      id: 'chip',
      title: l.cmdFormatChip,
      group: SlashGroup.wonky,
      commandId: 'write.format.chip',
      aliases: const ['tag', 'pill', 'badge'],
      run: (c, h) => c.toggleChip(),
    ),
    SlashItem(
      id: 'step',
      title: l.cmdHeadingToggleStep,
      group: SlashGroup.wonky,
      commandId: 'write.heading.toggleStep',
      aliases: const ['step', 'numbered heading'],
      run: (c, h) => c.toggleStep(),
    ),
  ];
}

/// Whether [item] is available with [host] (AI items need AI).
bool slashItemAvailable(SlashItem item, SlashHost? host) => switch (item.id) {
  _ when item.group == SlashGroup.wonky => host?.isWonky?.call() ?? false,
  'ai' => host?.onAskAi != null,
  'aiContinue' => host?.onContinueWriting != null,
  'emoji' => host?.onEmoji != null,
  'specialCharacter' => host?.onSpecialCharacter != null,
  _ => true,
};

/// Filters and ranks [items] for [query] (prefix match first, then contains,
/// then group order).
List<SlashItem> filterSlashItems(
  List<SlashItem> items,
  String query, {
  required EditorMode mode,
}) {
  final q = query.toLowerCase();
  int rank(SlashItem item) {
    final names = [
      item.title.toLowerCase(),
      ...item.aliases.map((a) => a.toLowerCase()),
    ];
    if (q.isEmpty) return 2;
    if (names.any((n) => n == q)) return 0;
    if (names.any((n) => n.startsWith(q))) return 1;
    if (names.any((n) => n.contains(q))) return 3;
    return -1;
  }

  final available = items
      .where((i) => mode != EditorMode.suggesting || i.suggestable)
      .toList();
  final ranked =
      [
        for (final item in available)
          if (rank(item) >= 0) (rank(item), item),
      ]..sort((a, b) {
        final byRank = a.$1.compareTo(b.$1);
        return byRank != 0
            ? byRank
            : a.$2.group.index.compareTo(b.$2.group.index);
      });
  return [for (final (_, item) in ranked) item];
}

/// Runs a slash [item] for [query]: removes `/query` and runs the command in
/// one undo step labelled with the item title (§21.3).
void runSlashItem(
  WriteEditorController controller,
  WriteEditorCommands commands,
  TriggerQueryTracker tracker,
  TriggerQuery query,
  SlashItem item,
  SlashHost host,
) {
  controller.group(item.title, () {
    tracker.removeTriggerText(query);
    item.run(commands, host);
  });
}
