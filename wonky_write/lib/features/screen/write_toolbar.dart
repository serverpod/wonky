import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../commands/command_icons.dart';
import '../../config/write_menus.dart' show calloutVariantLabels;
import '../editor/commands/write_editor_commands.dart';
import '../editor/controller/editor_types.dart';
import '../../l10n/write_l10n.dart';
import 'command_invoke.dart';
import 'write_document_controller.dart';

/// Resolves command state/titles/shortcuts for controls and invokes them
/// (every control is bound to a command id — Write 05 §1).
class CommandUi {
  CommandUi(this.context, this.s);

  final BuildContext context;
  final ShellServices s;

  /// The Write strings of [context].
  WriteLocalizations get l => writeL10n(context);

  CommandState state(String id, [Map<String, Object?> args = const {}]) =>
      s.dispatcher.stateOf(id, args);

  String title(String id) => s.registry.byId(id)?.title(context) ?? id;

  List<String>? shortcut(String id) => s.keymap.labelsOf(id);

  void run(
    String id, [
    Map<String, Object?> args = const {},
    InvocationSource source = InvocationSource.toolbar,
  ]) => invokeWith(s, id, args: args, source: source, context: context);

  /// A toolbar button bound to [id].
  ToolbarItem button(
    String id, {
    IconData? icon,
    int priority = 3,
    Map<String, Object?> args = const {},
    String? label,
    VoidCallback? onLongPress,
  }) {
    final st = state(id, args);
    return ToolbarButton(
      id: 'write.toolbar.${id.split('.').skip(1).join('.')}',
      priority: priority,
      icon:
          icon ??
          commandIcons[id] ??
          s.registry.byId(id)?.icon ??
          LucideIcons.circle,
      label: label ?? title(id),
      shortcut: args.isEmpty ? shortcut(id) : null,
      enabled: st.enabled,
      disabledReason: st.disabledReason,
      onPressed: () => run(id, args),
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
    );
  }

  /// A toggle bound to [id] (checked state from the command).
  ToolbarItem toggle(
    String id, {
    IconData? icon,
    int priority = 3,
    Map<String, Object?> args = const {},
    String? label,
    String? keyName,
  }) {
    final st = state(id, args);
    return ToolbarToggleButton(
      id: 'write.toolbar.${keyName ?? id.split('.').skip(1).join('.')}',
      priority: priority,
      icon: icon ?? commandIcons[id] ?? LucideIcons.circle,
      label: label ?? title(id),
      value: st.checked ?? false,
      shortcut: shortcut(id),
      enabled: st.enabled,
      disabledReason: st.disabledReason,
      onChanged: (_) => run(id, args),
    );
  }

  /// A menu entry bound to [id].
  WonkyMenuEntry item(
    String id, {
    Map<String, Object?> args = const {},
    String? label,
    IconData? icon,
    bool radio = false,
    String? keyName,
  }) {
    final st = state(id, args);
    final l = label ?? title(id);
    final k = ValueKey<String>('menu.${keyName ?? id}');
    final sc = args.isEmpty ? shortcut(id) : null;
    void go() => run(id, args, InvocationSource.menu);
    if (st.checked != null) {
      return radio
          ? WonkyMenuRadioItem(
              key: k,
              label: l,
              selected: st.checked!,
              shortcut: sc,
              enabled: st.enabled,
              disabledReason: st.disabledReason,
              onSelected: go,
            )
          : WonkyMenuCheckItem(
              key: k,
              label: l,
              checked: st.checked!,
              shortcut: sc,
              enabled: st.enabled,
              disabledReason: st.disabledReason,
              onSelected: go,
            );
    }
    return WonkyMenuItem(
      key: k,
      label: l,
      icon: icon ?? commandIconFor(id, args),
      shortcut: sc,
      enabled: st.enabled,
      disabledReason: st.disabledReason,
      onSelected: go,
    );
  }
}

/// Paragraph styles of the style dropdown (Write 05 §4.1).
const paragraphStyles = <BlockKind>[
  BlockKind.paragraph,
  BlockKind.heading1,
  BlockKind.heading2,
  BlockKind.heading3,
  BlockKind.heading4,
  BlockKind.heading5,
  BlockKind.heading6,
  BlockKind.quote,
  BlockKind.codeBlock,
];

/// Display name of the paragraph style [kind] (lists and other blocks show
/// as "Normal text").
String blockKindLabel(WriteLocalizations l, BlockKind kind) => switch (kind) {
  BlockKind.heading1 => l.cmdFormatBlockTypeHeading1,
  BlockKind.heading2 => l.cmdFormatBlockTypeHeading2,
  BlockKind.heading3 => l.cmdFormatBlockTypeHeading3,
  BlockKind.heading4 => l.cmdFormatBlockTypeHeading4,
  BlockKind.heading5 => l.cmdFormatBlockTypeHeading5,
  BlockKind.heading6 => l.cmdFormatBlockTypeHeading6,
  BlockKind.quote => l.cmdFormatBlockTypeQuote,
  BlockKind.codeBlock => l.cmdFormatBlockTypeCodeBlock,
  BlockKind.bulleted => l.cmdListToggleBulleted,
  BlockKind.numbered => l.cmdListToggleNumbered,
  BlockKind.checklist => l.cmdListToggleChecklist,
  _ => l.cmdFormatBlockTypeParagraph,
};

/// Label of the current paragraph style ("Normal text" when mixed / not a
/// paragraph style).
String paragraphStyleLabel(WriteLocalizations l, BlockKind? kind) =>
    kind != null && paragraphStyles.contains(kind)
    ? blockKindLabel(l, kind)
    : l.cmdFormatBlockTypeParagraph;

/// Zoom presets of the zoom dropdown (Write 05 §4 item 6).
const zoomPresets = [50, 75, 90, 100, 125, 150, 200];

/// Paragraph style menu entries (toolbar dropdown, Format menu, selection
/// toolbar).
List<WonkyMenuEntry> paragraphStyleEntries(
  CommandUi ui,
  BlockKind? current,
) => [
  for (final kind in paragraphStyles)
    WonkyMenuRadioItem(
      key: ValueKey<String>('menu.style.${kind.name}'),
      label: blockKindLabel(ui.l, kind),
      selected: current == kind,
      shortcut: ui.shortcut('write.format.blockType.${kind.name}'),
      enabled: ui.state('write.format.blockType', {'type': kind.name}).enabled,
      onSelected: () => ui.run('write.format.blockType', {
        'type': kind.name,
      }, InvocationSource.menu),
    ),
];

/// The formatting toolbar of the editor screen (Write 05 §4).
/// Gives an icon-only toolbar item (empty visible label) an accessible
/// name: the inline control's semantics are merged into one labeled node.
class LabeledToolbarItem extends ToolbarItem {
  LabeledToolbarItem(this.item, {required this.label})
    : super(id: item.id, priority: item.priority, pinned: item.pinned);

  final ToolbarItem item;
  final String label;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(label: label, child: item.build(context)),
  );

  @override
  List<WonkyMenuEntry> overflowEntries(BuildContext context) =>
      item.overflowEntries(context);
}

class WriteToolbar extends StatelessWidget {
  const WriteToolbar({
    super.key,
    required this.services,
    required this.doc,
    this.controller,
  });

  final ShellServices services;
  final WriteDocumentController doc;
  final WonkyToolbarController? controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        doc,
        services.registry,
        services.undo,
        services.panels,
      ]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final ui = CommandUi(context, services);
    final l = ui.l;
    final viewing = doc.editor.mode == EditorMode.viewing;
    final zoom = (doc.view.zoom * 100).round();
    final undoLabel = services.undo.undoLabel.value;
    final redoLabel = services.undo.redoLabel.value;
    final kind = doc.commands.selectedBlockKind;

    final history = ToolbarGroup([
      ui.button(
        'shell.edit.undo',
        icon: LucideIcons.undo2,
        priority: 1,
        label: undoLabel == null ? l.commonUndo : l.toolbarUndo(undoLabel),
        onLongPress: () => ui.run('shell.edit.undoHistory'),
      ),
      ui.button(
        'shell.edit.redo',
        icon: LucideIcons.redo2,
        priority: 1,
        label: redoLabel == null
            ? l.toolbarRedo
            : l.toolbarRedoAction(redoLabel),
      ),
      ui.button('write.file.print', icon: LucideIcons.printer, priority: 4),
    ], id: 'history');

    final zoomGroup = ToolbarGroup([
      ToolbarDropdownButton(
        id: 'write.toolbar.zoom',
        priority: 3,
        label: l.screenZoomPercent(zoom),
        tooltip: l.toolbarZoom,
        minWidth: 34,
        entries: () => [
          for (final p in zoomPresets)
            WonkyMenuRadioItem(
              key: ValueKey<String>('menu.zoom.$p'),
              label: l.screenZoomPercent(p),
              selected: zoom == p,
              onSelected: () => ui.run('write.view.zoomSet', {'percent': p}),
            ),
          const WonkyMenuSeparator(),
          ui.item(
            'write.view.zoomFit',
            args: {'mode': 'width'},
            label: l.menuFitWidth,
          ),
          ui.item(
            'write.view.zoomFit',
            args: {'mode': 'page'},
            label: l.menuFitPage,
          ),
        ],
      ),
    ], id: 'zoom');

    if (viewing) {
      return WonkyToolbar(
        controller: controller,
        semanticLabel: l.toolbarLabel,
        onEscape: doc.focusEditor,
        groups: [history, zoomGroup],
        trailing: [_commentsItem(ui), _modeItem(context, ui)],
      );
    }

    final styleState = ui.state('write.format.blockType', {
      'type': 'paragraph',
    });
    return WonkyToolbar(
      controller: controller,
      semanticLabel: l.toolbarLabel,
      onEscape: doc.focusEditor,
      groups: [
        history,
        zoomGroup,
        ToolbarGroup([
          ToolbarDropdownButton(
            id: 'write.toolbar.style',
            priority: 1,
            label: paragraphStyleLabel(l, kind),
            tooltip: l.toolbarStyles,
            minWidth: 96,
            enabled: styleState.enabled,
            entries: () => [
              ...paragraphStyleEntries(ui, kind),
              // Wonky Markdown (Write 11 §7.5).
              if (doc.isWonky) ...[
                const WonkyMenuSeparator(),
                ui.item('write.heading.toggleStep'),
              ],
            ],
          ),
        ], id: 'style'),
        ToolbarGroup([
          ui.toggle('write.format.bold', priority: 1),
          ui.toggle('write.format.italic', priority: 1),
          ui.toggle('write.format.strikethrough', priority: 2),
          ui.toggle('write.format.inlineCode', priority: 2),
        ], id: 'inline'),
        ToolbarGroup([
          _linkToggle(ui),
          ui.button(
            'shell.comments.create',
            icon: LucideIcons.messageSquarePlus,
            priority: 2,
          ),
          ToolbarSplitButton(
            id: 'write.toolbar.image',
            priority: 2,
            icon: LucideIcons.image,
            label: l.toolbarInsertImage,
            enabled: ui.state('write.insert.image').enabled,
            onPressed: () => ui.run('write.insert.image'),
            entries: () => [
              ui.item('write.insert.image', label: l.toolbarImageUpload),
              ui.item('write.insert.imageFromUrl', label: l.menuImageByUrl),
            ],
          ),
          LabeledToolbarItem(
            label: l.toolbarInsertTable,
            ToolbarDropdownButton(
              id: 'write.toolbar.table',
              priority: 3,
              label: '',
              icon: LucideIcons.table,
              tooltip: l.toolbarInsertTable,
              enabled: ui.state('write.insert.table').enabled,
              entries: () => [
                WonkyMenuCustom(
                  label: l.menuTableSize,
                  builder: (context, close) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: WonkyTableSizePicker(
                      key: const ValueKey<String>('write.toolbar.tablePicker'),
                      onSelected: (rows, cols) {
                        close();
                        ui.run('write.insert.table', {
                          'rows': rows,
                          'cols': cols,
                        });
                      },
                    ),
                  ),
                ),
                const WonkyMenuSeparator(),
                ui.item(
                  'write.insert.tableDialog',
                  label: l.menuTableCustomSize,
                ),
              ],
            ),
          ),
          if (doc.isWonky) _wonkyInsert(ui),
          ui.button(
            'write.insert.divider',
            priority: 6,
            label: l.cmdInsertDivider,
          ),
        ], id: 'insert'),
        ToolbarGroup([
          ui.toggle('write.list.toggleBulleted', priority: 1),
          ui.toggle('write.list.toggleNumbered', priority: 1),
          ui.toggle('write.list.toggleChecklist', priority: 2),
          ui.button('write.list.outdent', priority: 3),
          ui.button('write.list.indent', priority: 3),
        ], id: 'lists'),
        ToolbarGroup([
          ui.toggle(
            'write.format.blockType.quote',
            priority: 4,
            keyName: 'quote',
            label: l.cmdFormatBlockTypeQuote,
          ),
          ui.toggle(
            'write.format.blockType.codeBlock',
            priority: 4,
            keyName: 'codeBlock',
            label: l.cmdFormatBlockTypeCodeBlock,
          ),
          ui.button('write.format.clearFormatting', priority: 4),
        ], id: 'blocks'),
        ToolbarGroup([
          ui.button('write.theme.openPicker', priority: 5, label: l.menuTheme),
        ], id: 'theme'),
      ],
      trailing: [_commentsItem(ui), _modeItem(context, ui)],
    );
  }

  /// *Insert element*: the Wonky Markdown elements (Write 11 §7.5).
  ToolbarItem _wonkyInsert(CommandUi ui) {
    final l = ui.l;
    return LabeledToolbarItem(
      label: l.toolbarInsertElement,
      ToolbarDropdownButton(
        id: 'write.toolbar.wonky',
        priority: 2,
        label: '',
        icon: LucideIcons.layoutTemplate,
        tooltip: l.toolbarInsertElement,
        enabled: ui.state('write.insert.card').enabled,
        entries: () => [
          WonkyMenuSubmenu(
            key: const ValueKey<String>('menu.toolbar.callout'),
            label: l.cmdInsertCallout,
            icon: LucideIcons.info,
            enabled: ui.state('write.insert.callout').enabled,
            children: [
              for (final (variant, name) in calloutVariantLabels(l))
                ui.item(
                  'write.insert.callout',
                  args: {'variant': variant},
                  label: name,
                  keyName: 'toolbar.callout.$variant',
                ),
            ],
          ),
          ui.item('write.insert.details'),
          ui.item('write.insert.card'),
          ui.item('write.insert.grid'),
          ui.item('write.insert.youtube', label: l.cmdInsertYouTube),
          const WonkyMenuSeparator(),
          ui.item('write.insert.button', label: l.menuButtonEllipsis),
          ui.item(
            'write.insert.button',
            args: {'variant': 'secondary'},
            label: l.menuSecondaryButtonEllipsis,
            keyName: 'toolbar.buttonSecondary',
          ),
          ui.item('write.insert.arrowLink', label: l.menuArrowLinkEllipsis),
          ui.item('write.format.chip'),
          const WonkyMenuSeparator(),
          ui.item('write.heading.toggleStep'),
        ],
      ),
    );
  }

  ToolbarItem _linkToggle(CommandUi ui) {
    final st = ui.state('write.link.insert');
    final inLink = doc.commands.linkAt() != null;
    return ToolbarToggleButton(
      id: 'write.toolbar.link',
      priority: 1,
      icon: LucideIcons.link,
      label: inLink ? ui.l.toolbarEditLink : ui.l.cmdLinkInsert,
      value: inLink,
      shortcut: ui.shortcut('write.link.insert'),
      enabled: st.enabled,
      disabledReason: st.disabledReason,
      onChanged: (_) => ui.run('write.link.insert'),
    );
  }

  ToolbarItem _commentsItem(CommandUi ui) => ToolbarCustom(
    id: 'write.toolbar.comments',
    pinned: true,
    priority: 1,
    // Space before the mode switcher next to it.
    builder: (context) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CommentsToggle(doc: doc, ui: ui),
    ),
    overflow: [
      ui.item('shell.comments.togglePanel', label: ui.l.menuShowComments),
    ],
  );

  ToolbarItem _modeItem(BuildContext context, CommandUi ui) => ToolbarCustom(
    id: 'write.toolbar.mode',
    pinned: true,
    priority: 1,
    builder: (context) => ModeSwitcher(doc: doc, ui: ui),
    overflow: modeEntries(ui, doc),
  );
}

/// Mode menu entries (View › Mode, mode switcher).
List<WonkyMenuEntry> modeEntries(CommandUi ui, WriteDocumentController doc) => [
  for (final mode in EditorMode.values)
    ui.item(
      'write.mode.${mode.name}',
      label: ModeSwitcher.describe(ui.l, mode).$2,
      radio: true,
    ),
];

/// Shows / hides comments and suggestions in the margin
/// (`shell.comments.togglePanel`, Write 05 §4): styled like the mode
/// switcher next to it, filled with the comment highlight yellow (no
/// darker edge) while they are shown, with the number of open threads.
class CommentsToggle extends StatelessWidget {
  const CommentsToggle({super.key, required this.doc, required this.ui});

  final WriteDocumentController doc;
  final CommandUi ui;

  @override
  Widget build(BuildContext context) {
    final l = ui.l;
    return ListenableBuilder(
      listenable: Listenable.merge([
        doc.viewPrefs,
        doc.session.comments,
        doc.documentTheme,
      ]),
      builder: (context, _) {
        final shown = doc.viewPrefs.showCommentMargin;
        // The same yellow as commented text.
        final yellow = doc.documentTheme
            .editorTheme(ShadTheme.of(context).brightness)
            .commentHighlight;
        final count = doc.session.comments.controller?.openCount ?? 0;
        final shortcut = ui.shortcut('shell.comments.togglePanel');
        final tooltip = shortcut == null || shortcut.isEmpty
            ? l.menuShowComments
            : '${l.menuShowComments} (${shortcut.join()})';
        // Merged so the tap target carries the label and toggle state.
        return MergeSemantics(
          child: Semantics(
            toggled: shown,
            label: l.menuShowComments,
            child: ShadTooltip(
              builder: (_) => Text(tooltip),
              child: ShadButton.outline(
                key: const ValueKey<String>('write.toolbar.comments'),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: shown ? yellow : null,
                hoverBackgroundColor: shown ? yellow : null,
                pressedBackgroundColor: shown ? yellow : null,
                decoration: shown
                    ? ShadDecoration(
                        border: ShadBorder.all(color: yellow, width: 1),
                      )
                    : null,
                leading: Icon(
                  shown
                      ? LucideIcons.messageSquareText
                      : LucideIcons.messageSquare,
                  size: 15,
                ),
                onPressed: () => ui.run('shell.comments.togglePanel'),
                child: count == 0 ? const SizedBox.shrink() : Text('$count'),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Editing / Suggesting / Viewing switcher (Write 05 §15).
class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key, required this.doc, required this.ui});

  final WriteDocumentController doc;
  final CommandUi ui;

  /// Icon, name and description of the mode [m].
  static (IconData, String, String) describe(
    WriteLocalizations l,
    EditorMode m,
  ) => switch (m) {
    EditorMode.editing => (
      LucideIcons.pencil,
      l.screenModeEditing,
      l.screenModeEditingDescription,
    ),
    EditorMode.suggesting => (
      LucideIcons.messageSquareDiff,
      l.screenModeSuggesting,
      l.screenModeSuggestingDescription,
    ),
    EditorMode.viewing => (
      LucideIcons.eye,
      l.screenModeViewing,
      l.screenModeViewingDescription,
    ),
  };

  /// "Editing mode" / "Suggesting mode" / "Viewing mode".
  static String modeName(WriteLocalizations l, EditorMode m) => switch (m) {
    EditorMode.editing => l.cmdModeEditing,
    EditorMode.suggesting => l.cmdModeSuggesting,
    EditorMode.viewing => l.cmdModeViewing,
  };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = writeL10n(context);
    final mode = doc.editor.mode;
    final (icon, label, _) = describe(l, mode);
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final suggesting = mode == EditorMode.suggesting;
    return WonkyDropdownMenu(
      anchor: const ShadAnchor(
        childAlignment: AlignmentDirectional.bottomEnd,
        overlayAlignment: AlignmentDirectional.topEnd,
        offset: Offset(0, 4),
      ),
      constraints: const BoxConstraints(minWidth: 280),
      entries: () => [
        for (final m in EditorMode.values)
          WonkyMenuCustom(
            label: describe(l, m).$2,
            builder: (context, close) =>
                _ModeRow(mode: m, ui: ui, current: mode, close: close),
          ),
      ],
      builder: (context, c) => ShadTooltip(
        builder: (_) => Text(l.toolbarMode),
        child: ShadButton.outline(
          key: const ValueKey<String>('write.toolbar.modeSwitcher'),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: suggesting
              ? ShadDecoration(
                  border: ShadBorder.all(color: cs.success, width: 1),
                )
              : null,
          foregroundColor: suggesting ? cs.success : null,
          leading: Icon(icon, size: 15),
          trailing: Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: cs.mutedForeground,
          ),
          onPressed: c.toggle,
          // Icon-only when narrow: name the mode for screen readers.
          child: wide
              ? Text(label)
              : Semantics(
                  label: modeName(l, mode),
                  child: const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.mode,
    required this.ui,
    required this.current,
    required this.close,
  });

  final EditorMode mode;
  final CommandUi ui;
  final EditorMode current;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = writeL10n(context);
    final (icon, label, description) = ModeSwitcher.describe(l, mode);
    final st = ui.state('write.mode.set', {'mode': mode.name});
    final selected = mode == current;
    final shortcut = ui.s.keymap.labelsOf('write.mode.${mode.name}');
    final row = Opacity(
      opacity: st.enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? cs.primary : cs.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.small),
                  Text(
                    description,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (shortcut != null) ...[
              const SizedBox(width: 8),
              ShadKbd.group(shortcut, height: 18),
            ],
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              child: selected
                  ? Icon(LucideIcons.check, size: 16, color: cs.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
    return ShadTooltip(
      builder: (_) => Text(
        st.enabled ? label : (st.disabledReason ?? l.reasonNotAvailable),
      ),
      child: MouseRegion(
        cursor: st.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          key: ValueKey<String>('write.mode.option.${mode.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: st.enabled
              ? () {
                  close();
                  ui.run('write.mode.set', {'mode': mode.name});
                }
              : null,
          child: row,
        ),
      ),
    );
  }
}
