import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../../theme/sheets_tokens.dart';
import '../explore/explore_button.dart';
import '../collab/presence/sheet_tab_presence.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import '../status/row_loading_status.dart';
import '../status/selection_stats_button.dart';
import '../toolbar/command_ui.dart';

/// The sheet tab bar (04 §6): add, all sheets, tabs (rename inline, color
/// strip, menu, drag to reorder), scroll arrows and the selection stats.
class SheetTabBar extends StatefulWidget {
  const SheetTabBar({super.key, required this.controller});

  final SheetEditorController controller;

  @override
  State<SheetTabBar> createState() => _SheetTabBarState();
}

class _SheetTabBarState extends State<SheetTabBar> {
  final _scroll = ScrollController();
  String? _dragging;
  int? _dropIndex;

  SheetEditorController get c => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBy(double d) {
    if (!_scroll.hasClients) return;
    unawaited(
      _scroll.animateTo(
        (_scroll.offset + d).clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final ui = CommandUi(context, c.services);
    final l = ui.l;
    return ListenableBuilder(
      listenable: Listenable.merge([c, c.renamingSheet, c.services.registry]),
      builder: (context, _) {
        final sheets = c.model.visibleSheets;
        final hidden = c.model.sheets.where((s) => s.record!.hidden).length;
        return Container(
          key: const ValueKey<String>('sheets.tabBar'),
          height: 36,
          decoration: BoxDecoration(
            color: cs.muted.withValues(alpha: 0.5),
            border: Border(top: BorderSide(color: cs.border)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              ShadTooltip(
                builder: (_) => Text(l.cmdSheetAdd),
                child: ShadIconButton.ghost(
                  key: const ValueKey<String>('sheets.tab.add'),
                  width: 30,
                  height: 30,
                  iconSize: 16,
                  icon: const Icon(LucideIcons.plus),
                  semanticLabel: l.cmdSheetAdd,
                  enabled: ui.state('sheets.sheet.add').enabled,
                  onPressed: () =>
                      ui.run('sheets.sheet.add', const {}, InvocationSource.ui),
                ),
              ),
              WonkyDropdownMenu(
                entries: () => [
                  for (final s in c.model.sheets)
                    WonkyMenuRadioItem(
                      key: ValueKey<String>('menu.allSheets.${s.id}'),
                      label: s.record!.hidden
                          ? l.sheetHiddenLabel(s.name)
                          : s.name,
                      selected: s.id == c.activeSheetId,
                      onSelected: () => s.record!.hidden
                          ? ui.run('sheets.sheet.unhide', {
                              'sheetId': s.id,
                            }, InvocationSource.menu)
                          : ui.run('sheets.sheet.activate', {
                              'sheetId': s.id,
                            }, InvocationSource.menu),
                    ),
                ],
                builder: (context, menu) => ShadTooltip(
                  builder: (_) => Text(l.tabAllSheets),
                  child: ShadIconButton.ghost(
                    key: const ValueKey<String>('sheets.tab.all'),
                    width: 30,
                    height: 30,
                    iconSize: 16,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(LucideIcons.menu, size: 16),
                        if (hidden > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$hidden',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: cs.primaryForeground,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    semanticLabel: l.tabAllSheets,
                    onPressed: menu.toggle,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Listener(
                  onPointerSignal: (e) {
                    if (e is PointerScrollEvent) {
                      _scrollBy(e.scrollDelta.dy + e.scrollDelta.dx);
                    }
                  },
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < sheets.length; i++) ...[
                          if (_dropIndex == i && _dragging != null)
                            _DropLine(color: cs.primary),
                          _SheetTab(
                            key: ValueKey<String>('sheets.tab.${sheets[i].id}'),
                            controller: c,
                            sheet: sheets[i],
                            ui: ui,
                            onDragStart: () =>
                                setState(() => _dragging = sheets[i].id),
                            onDragUpdate: (globalX) =>
                                _updateDrop(globalX, sheets),
                            onDragEnd: () => _finishDrag(sheets),
                          ),
                        ],
                        if (_dropIndex == sheets.length && _dragging != null)
                          _DropLine(color: cs.primary),
                      ],
                    ),
                  ),
                ),
              ),
              ShadIconButton.ghost(
                key: const ValueKey<String>('sheets.tab.scrollLeft'),
                width: 24,
                height: 30,
                iconSize: 14,
                icon: const Icon(LucideIcons.chevronLeft),
                semanticLabel: l.tabScrollLeft,
                onPressed: () => _scrollBy(-120),
              ),
              ShadIconButton.ghost(
                key: const ValueKey<String>('sheets.tab.scrollRight'),
                width: 24,
                height: 30,
                iconSize: 14,
                icon: const Icon(LucideIcons.chevronRight),
                semanticLabel: l.tabScrollRight,
                onPressed: () => _scrollBy(120),
              ),
              const SizedBox(width: 8),
              RowLoadingStatus(controller: c),
              ExploreButton(controller: c),
              const SizedBox(width: 4),
              SelectionStatsButton(controller: c),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  final Map<String, GlobalKey> _keys = {};

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  void _updateDrop(double globalX, List<SheetModel> sheets) {
    var index = sheets.length;
    for (var i = 0; i < sheets.length; i++) {
      final ctx = keyFor(sheets[i].id).currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final left = box.localToGlobal(Offset.zero).dx;
      if (globalX < left + box.size.width / 2) {
        index = i;
        break;
      }
    }
    if (index != _dropIndex) setState(() => _dropIndex = index);
  }

  void _finishDrag(List<SheetModel> sheets) {
    final id = _dragging;
    final index = _dropIndex;
    setState(() {
      _dragging = null;
      _dropIndex = null;
    });
    if (id == null || index == null) return;
    final from = sheets.indexWhere((s) => s.id == id);
    if (index == from || index == from + 1) return;
    final before = index >= sheets.length ? null : sheets[index].id;
    unawaited(
      c.invokeCommand('sheets.sheet.move', {
        'sheetId': id,
        'beforeSheetId': before,
      }),
    );
  }
}

class _DropLine extends StatelessWidget {
  const _DropLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 3, height: 26, color: color);
}

class _SheetTab extends StatefulWidget {
  const _SheetTab({
    super.key,
    required this.controller,
    required this.sheet,
    required this.ui,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final SheetEditorController controller;
  final SheetModel sheet;
  final CommandUi ui;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  State<_SheetTab> createState() => _SheetTabState();
}

class _SheetTabState extends State<_SheetTab> {
  final _menu = ShadContextMenuController();
  final _rename = TextEditingController();
  final _renameFocus = FocusNode(debugLabel: 'sheets.tab.rename');
  bool _dragged = false;

  SheetEditorController get c => widget.controller;

  @override
  void dispose() {
    _menu.dispose();
    _rename.dispose();
    _renameFocus.dispose();
    super.dispose();
  }

  void _commitRename() {
    final name = _rename.text.trim();
    c.renamingSheet.value = null;
    if (name.isNotEmpty && name != widget.sheet.name) {
      unawaited(
        c.invokeCommand('sheets.sheet.rename', {
          'sheetId': widget.sheet.id,
          'name': name,
        }),
      );
    }
    c.gridFocus.requestFocus();
  }

  List<WonkyMenuEntry> _entries() {
    final ui = widget.ui;
    final l = ui.l;
    final args = {'sheetId': widget.sheet.id};
    return [
      ui.item('sheets.sheet.delete', args: args, keyName: 'tab.delete'),
      ui.item('sheets.sheet.duplicate', args: args, keyName: 'tab.duplicate'),
      WonkyMenuSubmenu(
        label: l.tabCopyTo,
        children: [
          ui.item(
            'sheets.sheet.copyToNew',
            args: args,
            keyName: 'tab.copyToNew',
          ),
          ui.item(
            'sheets.sheet.copyToExisting',
            args: args,
            keyName: 'tab.copyToExisting',
          ),
        ],
      ),
      ui.item('sheets.sheet.startRename', args: args, keyName: 'tab.rename'),
      WonkyMenuSubmenu(
        label: l.cmdSheetSetColor,
        children: [
          WonkyMenuCustom(
            label: l.cmdSheetSetColor,
            builder: (context, close) => WonkyColorPicker(
              value: widget.sheet.record?.tabColor == null
                  ? null
                  : WonkyColor.tryParse(widget.sheet.record!.tabColor!),
              resetLabel: l.colorNone,
              onChanged: (col) {
                close();
                ui.run('sheets.sheet.setColor', {
                  'sheetId': widget.sheet.id,
                  'color': col?.hex.toUpperCase(),
                }, InvocationSource.contextMenu);
              },
            ),
          ),
        ],
      ),
      ui.item(
        'sheets.protect.openPanel',
        args: const {},
        keyName: 'tab.protect',
      ),
      ui.item('sheets.sheet.hide', args: args, keyName: 'tab.hide'),
      ui.item('sheets.comments.openPanel', keyName: 'tab.comments'),
      const WonkyMenuSeparator(),
      ui.item('sheets.sheet.moveRight', args: args, keyName: 'tab.moveRight'),
      ui.item('sheets.sheet.moveLeft', args: args, keyName: 'tab.moveLeft'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final active = widget.sheet.id == c.activeSheetId;
    final renaming = c.renamingSheet.value == widget.sheet.id;
    final color = hexToColor(widget.sheet.record?.tabColor);
    final duplicate =
        c.model.sheets
            .where(
              (s) => s.name.toLowerCase() == widget.sheet.name.toLowerCase(),
            )
            .length >
        1;
    if (renaming && !_renameFocus.hasFocus) {
      _rename.text = widget.sheet.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _renameFocus.requestFocus();
        _rename.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _rename.text.length,
        );
      });
    }
    final label = renaming
        ? SizedBox(
            width: 120,
            child: Focus(
              onKeyEvent: (n, e) {
                if (e is KeyDownEvent &&
                    e.logicalKey == LogicalKeyboardKey.escape) {
                  c.renamingSheet.value = null;
                  c.gridFocus.requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: EditableText(
                key: const ValueKey<String>('sheets.tab.renameField'),
                controller: _rename,
                focusNode: _renameFocus,
                style: theme.textTheme.small,
                cursorColor: cs.primary,
                backgroundCursorColor: cs.mutedForeground,
                maxLines: 1,
                onSubmitted: (_) => _commitRename(),
                onTapOutside: (_) => _commitRename(),
              ),
            ),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chart sheets show a chart icon (08 §11).
                if (widget.sheet.record?.kind == SheetKind.chart) ...[
                  Icon(
                    LucideIcons.chartColumn,
                    key: const ValueKey<String>('sheets.tab.chartIcon'),
                    size: 13,
                    color: active ? cs.foreground : cs.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    widget.sheet.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      color: active ? cs.foreground : cs.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          );
    final tab = Container(
      height: 30,
      margin: const EdgeInsets.only(right: 2, top: 3),
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: active ? cs.background : cs.muted,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
        border: active ? Border.all(color: cs.border) : null,
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (duplicate) ...[
                ShadTooltip(
                  builder: (_) => Text(widget.ui.l.tabDuplicateName),
                  child: Icon(
                    LucideIcons.triangleAlert,
                    size: 12,
                    color: cs.destructive,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              label,
              SheetTabPresence(controller: c, sheetId: widget.sheet.id),
              WonkyDropdownMenu(
                controller: _menu,
                entries: _entries,
                builder: (context, menu) => ShadIconButton.ghost(
                  key: ValueKey<String>('sheets.tab.menu.${widget.sheet.id}'),
                  width: 22,
                  height: 22,
                  iconSize: 12,
                  icon: Icon(
                    LucideIcons.chevronDown,
                    color: cs.mutedForeground,
                  ),
                  semanticLabel: widget.ui.l.tabMenu(widget.sheet.name),
                  onPressed: menu.toggle,
                ),
              ),
            ],
          ),
          if (color != null)
            Positioned(
              left: -10,
              right: -2,
              bottom: 0,
              child: Container(height: 3, color: color),
            ),
        ],
      ),
    );
    return Listener(
      onPointerDown: (e) {
        if (e.buttons == kSecondaryMouseButton) _menu.show();
      },
      child: GestureDetector(
        key: (context.findAncestorStateOfType<_SheetTabBarState>())?.keyFor(
          widget.sheet.id,
        ),
        onTap: () {
          if (!renaming) {
            unawaited(
              c.invokeCommand('sheets.sheet.activate', {
                'sheetId': widget.sheet.id,
              }),
            );
          }
        },
        onDoubleTap: () {
          if (c.canEdit) c.renamingSheet.value = widget.sheet.id;
        },
        onHorizontalDragStart: c.canEdit && !renaming
            ? (_) {
                _dragged = true;
                widget.onDragStart();
              }
            : null,
        onHorizontalDragUpdate: c.canEdit && !renaming
            ? (d) => widget.onDragUpdate(d.globalPosition.dx)
            : null,
        onHorizontalDragEnd: c.canEdit && !renaming
            ? (_) {
                if (_dragged) widget.onDragEnd();
                _dragged = false;
              }
            : null,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: tab),
      ),
    );
  }
}

/// Grid tokens re-exported for the tab bar tests.
typedef TabTokens = GridPaintTokens;

/// The localized label of the tab bar region (a11y).
String tabBarLabel(SheetsLocalizations l) => l.tabBarLabel;
