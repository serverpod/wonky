import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../ai/ai_selection_menu.dart';
import '../editor/commands/write_editor_commands.dart';
import '../editor/controller/editor_types.dart';
import '../editor/mapping/wonky_embed_node.dart';
import '../../l10n/write_l10n.dart';
import 'write_document_controller.dart';
import 'write_toolbar.dart';

/// The floating selection toolbar (Write 05 §5.1): appears 250 ms after a
/// pointer selection ends (600 ms for keyboard selections) above the
/// selection, hidden while the pointer is down, while typing, after a
/// scroll, or when disabled in preferences.
class SelectionToolbarLayer extends StatefulWidget {
  const SelectionToolbarLayer({
    super.key,
    required this.doc,
    required this.ui,
    required this.child,
  });

  final WriteDocumentController doc;
  final CommandUi ui;
  final Widget child;

  @override
  State<SelectionToolbarLayer> createState() => _SelectionToolbarLayerState();
}

class _SelectionToolbarLayerState extends State<SelectionToolbarLayer> {
  Timer? _timer;
  bool _visible = false;
  bool _pointerDown = false;
  Object? _dismissedFor;
  final _key = GlobalKey();

  WriteDocumentController get doc => widget.doc;

  @override
  void initState() {
    super.initState();
    doc.editor.addListener(_onEditor);
  }

  @override
  void didUpdateWidget(SelectionToolbarLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc != widget.doc) {
      oldWidget.doc.editor.removeListener(_onEditor);
      doc.editor.addListener(_onEditor);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    doc.editor.removeListener(_onEditor);
    super.dispose();
  }

  Object? _lastSelection;

  void _onEditor() {
    final s = doc.editor.selection;
    if (s == _lastSelection) return;
    _lastSelection = s;
    _timer?.cancel();
    if (_visible) setState(() => _visible = false);
    if (s == null || s.isCollapsed || !doc.viewPrefs.showSelectionToolbar) {
      return;
    }
    if (_pointerDown) return;
    _timer = Timer(const Duration(milliseconds: 600), _maybeShow);
  }

  void _maybeShow() {
    final s = doc.editor.selection;
    if (!mounted || s == null || s.isCollapsed || _pointerDown) return;
    if (_dismissedFor == s) return;
    if (!doc.viewPrefs.showSelectionToolbar) return;
    // A selected grid has its own chrome; text formatting doesn't apply.
    final ds = doc.editor.composer.selection;
    if (ds != null && ds.base.nodeId == ds.extent.nodeId) {
      final node = doc.editor.document.getNodeById(ds.base.nodeId);
      if (node is WonkyEmbedNode && node.embedType == 'grid') return;
    }
    setState(() => _visible = true);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (_visible && n is ScrollUpdateNotification) {
          setState(() => _visible = false);
          _dismissedFor = doc.editor.selection;
        }
        return false;
      },
      child: Listener(
        onPointerDown: (e) {
          _pointerDown = true;
          if (e.buttons == kSecondaryButton) {
            _timer?.cancel();
            if (_visible) setState(() => _visible = false);
          }
        },
        onPointerUp: (_) {
          _pointerDown = false;
          final s = doc.editor.selection;
          if (s != null && !s.isCollapsed) {
            _timer?.cancel();
            _timer = Timer(const Duration(milliseconds: 250), _maybeShow);
          }
        },
        onPointerCancel: (_) => _pointerDown = false,
        child: Stack(
          key: _key,
          children: [
            Positioned.fill(child: widget.child),
            if (_visible) _positioned(context),
          ],
        ),
      ),
    );
  }

  Widget _positioned(BuildContext context) {
    final rect = doc.selectionRect();
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (rect == null || box == null || !box.hasSize) {
      return const SizedBox.shrink();
    }
    final local = box.globalToLocal(rect.topLeft);
    final size = box.size;
    const height = 40.0;
    const width = 360.0;
    var top = local.dy - height - 8;
    if (top < 4) top = local.dy + rect.height + 8;
    var left = local.dx;
    if (left + width > size.width - 8) left = size.width - 8 - width;
    if (left < 8) left = 8;
    if (top > size.height - height) return const SizedBox.shrink();
    return Positioned(
      left: left,
      top: top,
      child: _SelectionToolbar(
        doc: doc,
        ui: widget.ui,
        onDismiss: () => setState(() {
          _visible = false;
          _dismissedFor = doc.editor.selection;
        }),
      ),
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.doc,
    required this.ui,
    required this.onDismiss,
  });

  final WriteDocumentController doc;
  final CommandUi ui;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = writeL10n(context);
    final viewing = doc.editor.mode == EditorMode.viewing;
    final kind = doc.commands.selectedBlockKind;
    Widget toggle(String id, IconData icon) {
      final st = ui.state(id);
      return ShadTooltip(
        builder: (_) => ToolbarTooltipContent(
          label: ui.title(id),
          shortcut: ui.shortcut(id),
        ),
        child: ShadToggle(
          key: ValueKey<String>('write.selectionToolbar.${id.split('.').last}'),
          value: st.checked ?? false,
          enabled: st.enabled,
          width: 30,
          height: 30,
          padding: EdgeInsets.zero,
          semanticLabel: ui.title(id),
          onChanged: (_) => ui.run(id),
          child: Icon(icon, size: 16),
        ),
      );
    }

    Widget button(
      String id,
      IconData icon, {
      String? label,
      Map<String, Object?> args = const {},
    }) {
      final st = ui.state(id, args);
      return ShadTooltip(
        builder: (_) => ToolbarTooltipContent(
          label: label ?? ui.title(id),
          shortcut: args.isEmpty ? ui.shortcut(id) : null,
        ),
        child: ShadIconButton.ghost(
          key: ValueKey<String>('write.selectionToolbar.${id.split('.').last}'),
          width: 30,
          height: 30,
          iconSize: 16,
          enabled: st.enabled,
          semanticLabel: label ?? ui.title(id),
          icon: Icon(icon),
          onPressed: () => ui.run(id, args),
        ),
      );
    }

    Widget heading(int level, BlockKind k) {
      final selected = kind == k;
      final st = ui.state('write.format.blockType', {'type': k.name});
      final name = blockKindLabel(l, k);
      return ShadTooltip(
        builder: (_) => ToolbarTooltipContent(
          label: name,
          shortcut: ui.shortcut('write.format.blockType.${k.name}'),
        ),
        child: ShadToggle(
          key: ValueKey<String>('write.selectionToolbar.${k.name}'),
          value: selected,
          enabled: st.enabled,
          width: 30,
          height: 30,
          padding: EdgeInsets.zero,
          semanticLabel: name,
          onChanged: (_) => ui.run('write.format.blockType', {
            'type': selected ? 'paragraph' : k.name,
          }),
          child: Text(
            l.selectionToolbarHeadingShort(level),
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    Widget sep() => Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: cs.border,
    );

    return Semantics(
      container: true,
      label: l.selectionToolbarLabel,
      child: Container(
        key: const ValueKey<String>('write.selectionToolbar'),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: cs.popover,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: viewing
              ? [
                  AiSelectionButton(doc: doc, ui: ui),
                  button(
                    'shell.comments.create',
                    LucideIcons.messageSquarePlus,
                    label: l.menuComment,
                  ),
                  button('write.edit.copy', LucideIcons.copy),
                  button(
                    'write.find.open',
                    LucideIcons.search,
                    label: l.docMenuSearchDocument,
                    args: {'query': ?doc.selectedText},
                  ),
                ]
              : [
                  AiSelectionButton(doc: doc, ui: ui),
                  heading(1, BlockKind.heading1),
                  heading(2, BlockKind.heading2),
                  heading(3, BlockKind.heading3),
                  sep(),
                  toggle('write.format.bold', LucideIcons.bold),
                  toggle('write.format.italic', LucideIcons.italic),
                  toggle(
                    'write.format.strikethrough',
                    LucideIcons.strikethrough,
                  ),
                  toggle('write.format.inlineCode', LucideIcons.code),
                  sep(),
                  button('write.link.insert', LucideIcons.link),
                  button(
                    'shell.comments.create',
                    LucideIcons.messageSquarePlus,
                    label: l.menuComment,
                  ),
                  WonkyDropdownMenu(
                    entries: () => [
                      ui.item('write.edit.copyAsMarkdown'),
                      ui.item('write.format.clearFormatting'),
                      ui.item(
                        'write.find.open',
                        args: {'query': ?doc.selectedText},
                        label: l.docMenuSearchDocument,
                        keyName: 'selection.search',
                      ),
                      const WonkyMenuSeparator(),
                      WonkyMenuItem(
                        label: l.selectionToolbarHide,
                        icon: LucideIcons.eyeOff,
                        onSelected: onDismiss,
                      ),
                    ],
                    builder: (context, c) => ShadTooltip(
                      builder: (_) => Text(l.commonMore),
                      child: ShadIconButton.ghost(
                        key: const ValueKey<String>(
                          'write.selectionToolbar.more',
                        ),
                        width: 30,
                        height: 30,
                        iconSize: 16,
                        semanticLabel: l.commonMore,
                        icon: const Icon(LucideIcons.ellipsis),
                        onPressed: c.toggle,
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
