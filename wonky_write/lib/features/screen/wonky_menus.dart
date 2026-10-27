import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart'
    show
        DialogButtonSpec,
        TextFieldSpec,
        WonkyAppLocalizations,
        WonkyDialogSpec,
        showWonkyFormDialog;
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show BoxType, GridBullets, YouTubeEmbed;

import '../../config/write_menus.dart' show calloutVariantLabels;
import '../../l10n/write_l10n.dart';
import '../editor/commands/write_editor_commands.dart';
import 'anchored_popover.dart';
import 'write_document_controller.dart';
import 'write_toolbar.dart';

/// Menus and popovers of the Wonky Markdown chrome (Write 11 §7.2, §7.5).

Map<String, Object?> _box(String? nodeId, int? depth) => {
  'nodeId': ?nodeId,
  'depth': ?depth,
};

/// The callout types (radio) of the container at [depth] of [nodeId].
List<WonkyMenuEntry> calloutVariantEntries(
  CommandUi ui, {
  String? nodeId,
  int? depth,
}) => [
  for (final (variant, name) in calloutVariantLabels(ui.l))
    ui.item(
      'write.box.setVariant',
      args: {..._box(nodeId, depth), 'variant': variant},
      label: name,
      radio: true,
      keyName: 'box.variant.$variant',
    ),
];

/// The actions of a container (chrome ⋯ menu, context menu). The [chrome]
/// menu leaves out what the container's header offers itself (a callout's
/// type and title, a details' chevron).
List<WonkyMenuEntry> containerEntries(
  CommandUi ui,
  WriteDocumentController doc, {
  String? nodeId,
  int? depth,
  bool chrome = false,
}) {
  final l = ui.l;
  final c = doc.commands.containerAt(nodeId: nodeId, depth: depth);
  final args = _box(nodeId, depth);
  return [
    if (c?.frame.type == BoxType.callout && !chrome) ...[
      WonkyMenuSubmenu(
        label: l.menuCalloutType,
        icon: LucideIcons.info,
        children: calloutVariantEntries(ui, nodeId: nodeId, depth: depth),
      ),
      ui.item(
        'write.box.editTitle',
        args: args,
        label: l.menuEditTitleEllipsis,
        keyName: 'box.editTitle',
      ),
    ],
    if (c?.frame.type == BoxType.details && !chrome)
      ui.item(
        'write.details.toggleCollapsed',
        args: {'nodeId': ?nodeId},
        keyName: 'details.toggleCollapsed',
      ),
    WonkyMenuSubmenu(
      label: l.menuChangeTo,
      children: [
        for (final (type, name) in [
          ('callout', l.cmdInsertCallout),
          ('details', l.cmdInsertDetails),
          ('card', l.cmdInsertCard),
        ])
          ui.item(
            'write.box.convert',
            args: {...args, 'type': type},
            label: name,
            radio: true,
            keyName: 'box.convert.$type',
          ),
      ],
    ),
    const WonkyMenuSeparator(),
    ui.item('write.box.unwrap', args: args, keyName: 'box.unwrap'),
    ui.item('write.box.delete', args: args, keyName: 'box.delete'),
  ];
}

/// Columns 1–4 of a grid.
List<WonkyMenuEntry> gridColumnsEntries(CommandUi ui, String gridId) => [
  for (var n = 1; n <= 4; n++)
    ui.item(
      'write.grid.setColumns',
      args: {'nodeId': gridId, 'columns': n},
      label: ui.l.editorGridColumns(n),
      radio: true,
      keyName: 'grid.columns.$n',
    ),
];

/// The bullets of a grid.
List<WonkyMenuEntry> gridBulletsEntries(CommandUi ui, String gridId) => [
  for (final (bullets, name) in [
    (GridBullets.check, ui.l.gridBulletsCheck),
    (GridBullets.circle, ui.l.gridBulletsCircle),
    (GridBullets.none, ui.l.gridBulletsNone),
  ])
    ui.item(
      'write.grid.setBullets',
      args: {'nodeId': gridId, 'bullets': bullets.value},
      label: name,
      radio: true,
      keyName: 'grid.bullets.${bullets.value}',
    ),
];

/// The grid's ⋯ menu (and the context menu on a grid).
List<WonkyMenuEntry> gridEntries(
  CommandUi ui,
  String gridId, {
  bool chrome = false,
}) => [
  // The chrome has buttons for these.
  if (!chrome) ...[
    WonkyMenuSubmenu(
      label: ui.l.menuColumns,
      children: gridColumnsEntries(ui, gridId),
    ),
    WonkyMenuSubmenu(
      label: ui.l.menuBullets,
      children: gridBulletsEntries(ui, gridId),
    ),
    ui.item('write.grid.addItem', args: {'nodeId': gridId}),
    const WonkyMenuSeparator(),
  ],
  ui.item(
    'write.grid.delete',
    args: {'nodeId': gridId},
    label: ui.l.menuDeleteGrid,
  ),
];

/// The actions of a YouTube video (chrome ⋯ menu, context menu); the
/// [chrome] menu leaves out Edit and Open, which have buttons there.
List<WonkyMenuEntry> youtubeEntries(
  CommandUi ui,
  String nodeId, {
  bool chrome = false,
}) => [
  if (!chrome) ...[
    ui.item('write.youtube.edit', args: {'nodeId': nodeId}),
    ui.item('write.youtube.open', args: {'nodeId': nodeId}),
    const WonkyMenuSeparator(),
  ],
  ui.item('write.youtube.delete', args: {'nodeId': nodeId}),
];

/// Asks for a YouTube link and an optional title (Write 11 §7.5); [current]
/// prefills it for editing. `null` when cancelled.
Future<({String url, String title})?> showYouTubeDialog(
  BuildContext context, {
  YouTubeEmbed? current,
}) async {
  final l = writeL10n(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: current == null
          ? l.youtubeDialogInsertTitle
          : l.youtubeDialogEditTitle,
      description: l.youtubeDialogDescription,
      dialogKey: 'dialog.youtube',
      width: 480,
      fields: [
        TextFieldSpec(
          id: 'url',
          label: l.youtubeFieldUrl,
          placeholder: l.youtubeFieldUrlHint,
          initial: current?.watchUrl ?? '',
          validator: (v) =>
              YouTubeEmbed.parseUrl(v) == null ? l.youtubeInvalidUrl : null,
        ),
        TextFieldSpec(
          id: 'title',
          label: l.youtubeFieldTitle,
          initial: current?.title ?? '',
          maxLength: 300,
        ),
      ],
      buttons: [
        DialogButtonSpec(
          id: 'cancel',
          label: WonkyAppLocalizations.of(context).actionCancel,
          validates: false,
        ),
        DialogButtonSpec(
          id: 'ok',
          label: current == null ? l.commonInsert : l.commonSave,
          primary: true,
        ),
      ],
    ),
  );
  if (r == null || r.buttonId != 'ok') return null;
  return (url: r.text('url').trim(), title: r.text('title').trim());
}

/// A small popover with one text field (callout titles, step numbers);
/// returns the text, or `null` when cancelled.
Future<String?> showTextFieldPopover(
  BuildContext context, {
  required Rect anchor,
  required String label,
  required String initial,
  String? placeholder,
  bool number = false,
  String? popoverKey,
}) => showAnchoredPopover<String>(
  context,
  anchor: anchor,
  width: 280,
  builder: (_) => _TextFieldPopover(
    key: ValueKey<String>(popoverKey ?? 'write.popover.textField'),
    label: label,
    initial: initial,
    placeholder: placeholder,
    number: number,
  ),
);

class _TextFieldPopover extends StatefulWidget {
  const _TextFieldPopover({
    super.key,
    required this.label,
    required this.initial,
    required this.placeholder,
    required this.number,
  });

  final String label;
  final String initial;
  final String? placeholder;
  final bool number;

  @override
  State<_TextFieldPopover> createState() => _TextFieldPopoverState();
}

class _TextFieldPopoverState extends State<_TextFieldPopover> {
  late final _text = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _apply() => Navigator.of(context).pop(_text.text.trim());

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Text(widget.label, style: theme.textTheme.small),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: widget.label,
            child: ShadInput(
              key: const ValueKey<String>('write.popover.textField.input'),
              controller: _text,
              autofocus: true,
              placeholder: widget.placeholder == null
                  ? null
                  : Text(widget.placeholder!),
              keyboardType: widget.number ? TextInputType.number : null,
              inputFormatters: widget.number
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              onSubmitted: (_) => _apply(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.commonCancel),
              ),
              const SizedBox(width: 8),
              ShadButton(
                key: const ValueKey<String>('write.popover.textField.apply'),
                size: ShadButtonSize.sm,
                onPressed: _apply,
                child: Text(l.commonApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Edits the title of the callout at [depth] of [nodeId] (or at the caret).
Future<void> editBoxTitle(
  BuildContext context,
  WriteDocumentController doc,
  void Function(String id, Map<String, Object?> args) invoke, {
  String? nodeId,
  int? depth,
  Rect? anchor,
}) async {
  final c = doc.commands.containerAt(nodeId: nodeId, depth: depth);
  if (c == null) return;
  final l = writeL10n(context);
  final title = await showTextFieldPopover(
    context,
    anchor:
        anchor ??
        doc.selectionRect() ??
        Rect.fromLTWH(MediaQuery.sizeOf(context).width / 2, 160, 1, 1),
    label: l.boxTitleLabel,
    initial: c.frame.title ?? '',
    placeholder: c.frame.calloutLabel,
    popoverKey: 'write.popover.boxTitle',
  );
  doc.focusEditor();
  if (title == null) return;
  invoke('write.box.editTitle', {..._box(nodeId, depth), 'title': title});
}

/// Edits the number of the numbered heading [nodeId].
Future<void> editStepNumber(
  BuildContext context,
  WriteDocumentController doc,
  void Function(String id, Map<String, Object?> args) invoke, {
  required String nodeId,
  required Rect anchor,
}) async {
  final block = doc.block(nodeId);
  final current = block?.blockAttributes?['step'];
  final l = writeL10n(context);
  final text = await showTextFieldPopover(
    context,
    anchor: anchor,
    label: l.stepNumberLabel,
    initial: '${current ?? 1}',
    number: true,
    popoverKey: 'write.popover.stepNumber',
  );
  doc.focusEditor();
  final n = int.tryParse(text ?? '');
  if (n == null) return;
  invoke('write.heading.setStepNumber', {'nodeId': nodeId, 'n': n});
}
