import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../l10n/write_l10n.dart';
import '../screen/command_invoke.dart';
import '../screen/document_insights.dart';

/// Outline view preferences (local, not undoable; Write 05 §13.2).
class OutlineViewState extends ChangeNotifier {
  int _maxLevel = 6;
  final Set<int> _collapsed = {};

  /// Deepest heading level shown (`write.outline.setMaxLevel`).
  int get maxLevel => _maxLevel;
  set maxLevel(int value) {
    final v = value.clamp(1, 6);
    if (v == _maxLevel) return;
    _maxLevel = v;
    notifyListeners();
  }

  /// Collapsed entries, by their delta offset (stable enough while editing).
  bool isCollapsed(OutlineEntry e) => _collapsed.contains(e.deltaOffset);

  void toggle(OutlineEntry e) {
    if (!_collapsed.remove(e.deltaOffset)) _collapsed.add(e.deltaOffset);
    notifyListeners();
  }

  void collapseAll(Iterable<OutlineEntry> entries) {
    _collapsed
      ..clear()
      ..addAll(entries.map((e) => e.deltaOffset));
    notifyListeners();
  }

  void expandAll() {
    _collapsed.clear();
    notifyListeners();
  }
}

/// A visible outline row.
class OutlineRow {
  const OutlineRow(this.entry, this.depth, {required this.hasChildren});

  final OutlineEntry entry;
  final int depth;
  final bool hasChildren;
}

/// The rows of [outline] visible with [view] (levels and collapsed
/// sections), indented relative to the minimum level present.
List<OutlineRow> visibleOutlineRows(
  List<OutlineEntry> outline,
  OutlineViewState view,
) {
  final shown = [
    for (final e in outline)
      if (e.level <= view.maxLevel) e,
  ];
  if (shown.isEmpty) return const [];
  final minLevel = shown.map((e) => e.level).reduce((a, b) => a < b ? a : b);
  final rows = <OutlineRow>[];
  int? hideBelow;
  for (var i = 0; i < shown.length; i++) {
    final e = shown[i];
    if (hideBelow != null) {
      if (e.level > hideBelow) continue;
      hideBelow = null;
    }
    final hasChildren = i + 1 < shown.length && shown[i + 1].level > e.level;
    rows.add(OutlineRow(e, e.level - minLevel, hasChildren: hasChildren));
    if (hasChildren && view.isCollapsed(e)) hideBelow = e.level;
  }
  return rows;
}

/// The Outline side panel (Write 05 §10.1): live list of headings; click
/// navigates (`write.nav.goToHeading`), the caret's section is highlighted.
class OutlinePanel extends StatefulWidget {
  const OutlinePanel({
    super.key,
    required this.insights,
    required this.view,
    this.onClose,
  });

  final DocumentInsights insights;
  final OutlineViewState view;
  final VoidCallback? onClose;

  @override
  State<OutlinePanel> createState() => _OutlinePanelState();
}

class _OutlinePanelState extends State<OutlinePanel> {
  final _focus = FocusNode(debugLabel: 'outline');
  final _scroll = ScrollController();
  int? _focused;

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _go(OutlineEntry e) =>
      invokeCommand(context, 'write.nav.goToHeading', args: {'index': e.index});

  KeyEventResult _keys(FocusNode node, KeyEvent event, List<OutlineRow> rows) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (rows.isEmpty) return KeyEventResult.ignored;
    final i = (_focused ?? 0).clamp(0, rows.length - 1);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() => _focused = (i + 1).clamp(0, rows.length - 1));
      case LogicalKeyboardKey.arrowUp:
        setState(() => _focused = (i - 1).clamp(0, rows.length - 1));
      case LogicalKeyboardKey.home:
        setState(() => _focused = 0);
      case LogicalKeyboardKey.end:
        setState(() => _focused = rows.length - 1);
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.space:
        _go(rows[i].entry);
      case LogicalKeyboardKey.arrowLeft:
        if (rows[i].hasChildren && !widget.view.isCollapsed(rows[i].entry)) {
          widget.view.toggle(rows[i].entry);
        }
      case LogicalKeyboardKey.arrowRight:
        if (rows[i].hasChildren && widget.view.isCollapsed(rows[i].entry)) {
          widget.view.toggle(rows[i].entry);
        }
      case LogicalKeyboardKey.escape:
        widget.onClose?.call();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.insights, widget.view]),
      builder: (context, _) {
        final outline = widget.insights.outline;
        final rows = visibleOutlineRows(outline, widget.view);
        final current = widget.insights.currentHeading;
        if (outline.isEmpty) return _empty(context);
        final l = writeL10n(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                children: [
                  Text(
                    l.outlineHeadingCount(outline.length),
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                  const Spacer(),
                  WonkyDropdownMenu(
                    entries: () => [
                      WonkyMenuItem(
                        key: const ValueKey<String>('outline.collapseAll'),
                        label: l.outlineCollapseAll,
                        icon: LucideIcons.chevronsDownUp,
                        onSelected: () => widget.view.collapseAll(outline),
                      ),
                      WonkyMenuItem(
                        key: const ValueKey<String>('outline.expandAll'),
                        label: l.outlineExpandAll,
                        icon: LucideIcons.chevronsUpDown,
                        onSelected: widget.view.expandAll,
                      ),
                      const WonkyMenuSeparator(),
                      WonkyMenuSubmenu(
                        label: l.outlineShowLevels,
                        children: [
                          for (var level = 1; level <= 6; level++)
                            WonkyMenuRadioItem(
                              key: ValueKey<String>('outline.levels.$level'),
                              label: level == 1
                                  ? l.outlineHeading1Only
                                  : l.outlineUpToLevel(level),
                              selected: widget.view.maxLevel == level,
                              onSelected: () => invokeCommand(
                                context,
                                'write.outline.setMaxLevel',
                                args: {'level': level},
                              ),
                            ),
                        ],
                      ),
                    ],
                    builder: (context, c) => ShadTooltip(
                      builder: (_) => Text(l.outlineOptions),
                      child: ShadIconButton.ghost(
                        key: const ValueKey<String>('outline.menu'),
                        width: 28,
                        height: 28,
                        iconSize: 16,
                        semanticLabel: l.outlineOptions,
                        icon: const Icon(LucideIcons.ellipsisVertical),
                        onPressed: c.toggle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Focus(
                focusNode: _focus,
                onKeyEvent: (n, e) => _keys(n, e, rows),
                onFocusChange: (f) => setState(() {}),
                child: WonkyScrollArea(
                  controller: _scroll,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      return _OutlineRowWidget(
                        key: ValueKey<String>(
                          'outline.item.${row.entry.index}',
                        ),
                        row: row,
                        current: row.entry.index == current,
                        focused: _focus.hasFocus && i == _focused,
                        collapsed: widget.view.isCollapsed(row.entry),
                        onTap: () {
                          setState(() => _focused = i);
                          _go(row.entry);
                        },
                        onToggle: () => widget.view.toggle(row.entry),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    return Padding(
      key: const ValueKey<String>('outline.empty'),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.listTree,
            size: 24,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 12),
          Text(
            l.outlineEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 12),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () => invokeCommand(
              context,
              'write.format.blockType',
              args: {'type': 'heading1'},
            ),
            child: Text(l.outlineMakeHeading),
          ),
        ],
      ),
    );
  }
}

class _OutlineRowWidget extends StatefulWidget {
  const _OutlineRowWidget({
    super.key,
    required this.row,
    required this.current,
    required this.focused,
    required this.collapsed,
    required this.onTap,
    required this.onToggle,
  });

  final OutlineRow row;
  final bool current;
  final bool focused;
  final bool collapsed;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  State<_OutlineRowWidget> createState() => _OutlineRowWidgetState();
}

class _OutlineRowWidgetState extends State<_OutlineRowWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final e = widget.row.entry;
    final l = writeL10n(context);
    final untitled = e.text.trim().isEmpty;
    // Numbered headings show their number (Write 11 §7.4).
    final text = untitled
        ? (e.step == null
              ? l.outlineUntitledHeading
              : '(${e.step}) ${l.outlineUntitledHeading}')
        : e.label;
    final top = widget.row.depth == 0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: widget.current
                ? cs.accent
                : _hover
                ? cs.accent.withValues(alpha: 0.5)
                : null,
            borderRadius: BorderRadius.circular(6),
            border: widget.focused ? Border.all(color: cs.ring) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 2,
                height: 18,
                color: widget.current ? cs.primary : const Color(0x00000000),
              ),
              SizedBox(width: 4.0 + widget.row.depth * 12),
              SizedBox(
                width: 18,
                height: 30,
                child: widget.row.hasChildren
                    ? Semantics(
                        // Its own node with its own tap: otherwise it merges
                        // into the row, whose tap goes to the heading.
                        container: true,
                        button: true,
                        expanded: !widget.collapsed,
                        label: widget.collapsed
                            ? l.outlineExpandSection(text)
                            : l.outlineCollapseSection(text),
                        excludeSemantics: true,
                        onTap: widget.onToggle,
                        child: GestureDetector(
                          // The whole 18×30 cell toggles, not only the icon.
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onToggle,
                          child: Icon(
                            widget.collapsed
                                ? LucideIcons.chevronRight
                                : LucideIcons.chevronDown,
                            size: 14,
                            color: cs.mutedForeground,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: ShadTooltip(
                  waitDuration: const Duration(milliseconds: 800),
                  builder: (_) => Text(text),
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      fontWeight: top ? FontWeight.w600 : FontWeight.w400,
                      color: widget.current
                          ? cs.foreground
                          : cs.foreground.withValues(alpha: top ? 1 : 0.85),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
