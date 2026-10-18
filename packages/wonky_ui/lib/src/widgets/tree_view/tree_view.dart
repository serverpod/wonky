import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../l10n/wonky_ui_localizations.dart';

/// A node of a [WonkyTreeView].
@immutable
class WonkyTreeNode<T> {
  const WonkyTreeNode({
    required this.id,
    required this.label,
    required this.value,
    this.icon,
    this.hasChildren = true,
    this.enabled = true,
  });

  final String id;
  final String label;
  final T value;
  final IconData? icon;

  /// Whether the node may have children (shows the chevron before loading).
  final bool hasChildren;

  /// Disabled nodes are dimmed and reject drops.
  final bool enabled;
}

/// A visible row of the flattened tree.
class WonkyTreeRow<T> {
  const WonkyTreeRow(this.node, this.depth, this.parentId);

  final WonkyTreeNode<T> node;
  final int depth;
  final String? parentId;
}

/// Where a drop lands relative to a target node.
enum WonkyTreeDropPosition { before, inside, after }

/// Loads the children of [parent] (null = roots).
typedef WonkyTreeLoader<T> =
    Future<List<WonkyTreeNode<T>>> Function(WonkyTreeNode<T>? parent);

/// State of a [WonkyTreeView]: lazily loaded children, expansion, selection
/// and focus.
class WonkyTreeController<T> extends ChangeNotifier {
  WonkyTreeController({required this.loader});

  final WonkyTreeLoader<T> loader;

  final Map<String?, List<WonkyTreeNode<T>>> _children = {};
  final Set<String> _expanded = {};
  final Set<String?> _loading = {};
  final Map<String, WonkyTreeNode<T>> _nodes = {};
  final Map<String, String?> _parents = {};
  String? _selectedId;
  String? _focusedId;
  String? _renamingId;
  Object? _error;

  String? get selectedId => _selectedId;
  String? get focusedId => _focusedId;
  String? get renamingId => _renamingId;
  Object? get error => _error;
  bool isExpanded(String id) => _expanded.contains(id);
  bool isLoading(String? id) => _loading.contains(id);
  WonkyTreeNode<T>? node(String id) => _nodes[id];
  String? parentOf(String id) => _parents[id];

  /// Whether the roots have been loaded.
  bool get loaded => _children.containsKey(null);

  /// Loads roots (if needed).
  Future<void> ensureLoaded() => _load(null);

  Future<void> _load(String? parentId, {bool force = false}) async {
    if (!force && _children.containsKey(parentId)) return;
    if (_loading.contains(parentId)) return;
    _loading.add(parentId);
    notifyListeners();
    try {
      final parent = parentId == null ? null : _nodes[parentId];
      final kids = await loader(parent);
      _children[parentId] = kids;
      for (final k in kids) {
        _nodes[k.id] = k;
        _parents[k.id] = parentId;
      }
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _loading.remove(parentId);
      notifyListeners();
    }
  }

  /// Reloads the children of [parentId] (null = roots), e.g. after a
  /// live drive change.
  Future<void> refresh([String? parentId]) => _load(parentId, force: true);

  Future<void> expand(String id) async {
    _expanded.add(id);
    notifyListeners();
    await _load(id);
  }

  void collapse(String id) {
    if (_expanded.remove(id)) notifyListeners();
  }

  Future<void> toggle(String id) async =>
      isExpanded(id) ? collapse(id) : expand(id);

  /// Expands [id] and all its ancestors (reveal a node).
  Future<void> expandPath(List<String> ids) async {
    for (final id in ids) {
      await expand(id);
    }
  }

  /// Expands every sibling of [id] (`*` key).
  Future<void> expandSiblings(String id) async {
    final siblings = _children[_parents[id]] ?? const [];
    await Future.wait([
      for (final s in siblings)
        if (s.hasChildren) expand(s.id),
    ]);
  }

  void select(String? id) {
    _selectedId = id;
    if (id != null) _focusedId = id;
    notifyListeners();
  }

  void focus(String? id) {
    if (_focusedId == id) return;
    _focusedId = id;
    notifyListeners();
  }

  void startRename(String id) {
    _renamingId = id;
    notifyListeners();
  }

  void endRename() {
    if (_renamingId == null) return;
    _renamingId = null;
    notifyListeners();
  }

  /// The flattened visible rows.
  List<WonkyTreeRow<T>> get rows {
    final out = <WonkyTreeRow<T>>[];
    void walk(String? parentId, int depth) {
      for (final WonkyTreeNode<T> n in _children[parentId] ?? const []) {
        out.add(WonkyTreeRow<T>(n, depth, parentId));
        if (_expanded.contains(n.id)) walk(n.id, depth + 1);
      }
    }

    walk(null, 0);
    return out;
  }
}

/// A lazy, virtualized tree (suite 02 §4.6): drive folder tree, document
/// outline, script files. Keyboard: ↑/↓ move, → expand / first child,
/// ← collapse / parent, Home/End, `*` expands siblings, Enter activates,
/// F2 renames. Rows are drag sources and drop targets.
class WonkyTreeView<T> extends StatefulWidget {
  const WonkyTreeView({
    super.key,
    required this.controller,
    this.onActivate,
    this.onRename,
    this.canAcceptDrop,
    this.onDrop,
    this.dragData,
    this.trailingBuilder,
    this.rowHeight = 30,
    this.indent = 16,
    this.semanticLabel,
    this.shrinkWrap = false,
    this.keyPrefix = 'tree',
  });

  final WonkyTreeController<T> controller;
  final ValueChanged<WonkyTreeNode<T>>? onActivate;

  /// Inline rename result; return false to keep the editor open.
  final FutureOr<bool> Function(WonkyTreeNode<T> node, String name)? onRename;

  /// Whether [data] (a dragged node or external payload) may be dropped.
  final bool Function(
    Object data,
    WonkyTreeNode<T> target,
    WonkyTreeDropPosition position,
  )?
  canAcceptDrop;
  final void Function(
    Object data,
    WonkyTreeNode<T> target,
    WonkyTreeDropPosition position,
  )?
  onDrop;

  /// Payload when dragging a node (null = not draggable).
  final Object? Function(WonkyTreeNode<T> node)? dragData;
  final Widget? Function(BuildContext context, WonkyTreeNode<T> node)?
  trailingBuilder;
  final double rowHeight;
  final double indent;
  final String? semanticLabel;
  final bool shrinkWrap;

  /// Row keys are `<keyPrefix>.node.<id>`.
  final String keyPrefix;

  @override
  State<WonkyTreeView<T>> createState() => _WonkyTreeViewState<T>();
}

class _WonkyTreeViewState<T> extends State<WonkyTreeView<T>> {
  final _focus = FocusNode(debugLabel: 'WonkyTreeView');
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.ensureLoaded());
  }

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _moveFocus(List<WonkyTreeRow<T>> rows, int index) {
    if (rows.isEmpty) return;
    final i = index.clamp(0, rows.length - 1);
    widget.controller.focus(rows[i].node.id);
    final top = i * widget.rowHeight;
    if (_scroll.hasClients) {
      final pos = _scroll.position;
      if (top < pos.pixels) {
        _scroll.jumpTo(top);
      } else if (top + widget.rowHeight > pos.pixels + pos.viewportDimension) {
        _scroll.jumpTo(top + widget.rowHeight - pos.viewportDimension);
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final c = widget.controller;
    if (c.renamingId != null) return KeyEventResult.ignored;
    final rows = c.rows;
    if (rows.isEmpty) return KeyEventResult.ignored;
    var index = rows.indexWhere((r) => r.node.id == c.focusedId);
    if (index < 0) index = 0;
    final row = rows[index];
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(rows, index + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(rows, index - 1);
    } else if (key == LogicalKeyboardKey.home) {
      _moveFocus(rows, 0);
    } else if (key == LogicalKeyboardKey.end) {
      _moveFocus(rows, rows.length - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (row.node.hasChildren && !c.isExpanded(row.node.id)) {
        unawaited(c.expand(row.node.id));
      } else if (c.isExpanded(row.node.id) &&
          index + 1 < rows.length &&
          rows[index + 1].parentId == row.node.id) {
        _moveFocus(rows, index + 1);
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (c.isExpanded(row.node.id)) {
        c.collapse(row.node.id);
      } else if (row.parentId != null) {
        _moveFocus(rows, rows.indexWhere((r) => r.node.id == row.parentId));
      }
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      c.select(row.node.id);
      widget.onActivate?.call(row.node);
    } else if (key == LogicalKeyboardKey.f2 && widget.onRename != null) {
      c.startRename(row.node.id);
    } else if (event.character == '*') {
      unawaited(c.expandSiblings(row.node.id));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final rows = widget.controller.rows;
        return Semantics(
          label: widget.semanticLabel,
          container: true,
          child: Focus(
            focusNode: _focus,
            onKeyEvent: _onKey,
            onFocusChange: (f) {
              if (f && widget.controller.focusedId == null && rows.isNotEmpty) {
                widget.controller.focus(
                  widget.controller.selectedId ?? rows.first.node.id,
                );
              }
              setState(() {});
            },
            child: ListView.builder(
              controller: _scroll,
              shrinkWrap: widget.shrinkWrap,
              physics: widget.shrinkWrap
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemExtent: widget.rowHeight,
              itemCount: rows.length,
              itemBuilder: (context, i) => _TreeRowWidget<T>(
                key: ValueKey<String>(
                  '${widget.keyPrefix}.node.${rows[i].node.id}',
                ),
                row: rows[i],
                view: widget,
                treeFocused: _focus.hasFocus,
                onTap: () {
                  _focus.requestFocus();
                  widget.controller.select(rows[i].node.id);
                  widget.onActivate?.call(rows[i].node);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TreeRowWidget<T> extends StatefulWidget {
  const _TreeRowWidget({
    super.key,
    required this.row,
    required this.view,
    required this.treeFocused,
    required this.onTap,
  });

  final WonkyTreeRow<T> row;
  final WonkyTreeView<T> view;
  final bool treeFocused;
  final VoidCallback onTap;

  @override
  State<_TreeRowWidget<T>> createState() => _TreeRowWidgetState<T>();
}

class _TreeRowWidgetState<T> extends State<_TreeRowWidget<T>> {
  bool _hover = false;
  WonkyTreeDropPosition? _drop;
  TextEditingController? _rename;

  @override
  void dispose() {
    _rename?.dispose();
    super.dispose();
  }

  WonkyTreeDropPosition _positionFor(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return WonkyTreeDropPosition.inside;
    final y = box.globalToLocal(global).dy / box.size.height;
    if (widget.row.node.hasChildren) {
      if (y < 0.25) return WonkyTreeDropPosition.before;
      if (y > 0.75) return WonkyTreeDropPosition.after;
      return WonkyTreeDropPosition.inside;
    }
    return y < 0.5 ? WonkyTreeDropPosition.before : WonkyTreeDropPosition.after;
  }

  Future<void> _commitRename() async {
    final c = widget.view.controller;
    final text = _rename?.text.trim() ?? '';
    if (text.isEmpty || text == widget.row.node.label) {
      c.endRename();
      return;
    }
    final ok = await widget.view.onRename?.call(widget.row.node, text) ?? true;
    if (ok) c.endRename();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = WonkyUiLocalizations.of(context);
    final c = widget.view.controller;
    final node = widget.row.node;
    final selected = c.selectedId == node.id;
    final focused = widget.treeFocused && c.focusedId == node.id;
    final expanded = c.isExpanded(node.id);
    final loading = c.isLoading(node.id);
    final renaming = c.renamingId == node.id;

    if (renaming && _rename == null) {
      _rename = TextEditingController(text: node.label)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: node.label.length,
        );
    } else if (!renaming && _rename != null) {
      _rename!.dispose();
      _rename = null;
    }

    final chevron = SizedBox(
      width: 20,
      child: node.hasChildren
          ? GestureDetector(
              onTap: () => c.toggle(node.id),
              child: Semantics(
                button: true,
                label: expanded ? l10n.treeCollapse : l10n.treeExpand,
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: ShadSpinner(size: 12),
                      )
                    : AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
              ),
            )
          : null,
    );

    Widget label = renaming
        ? SizedBox(
            height: widget.view.rowHeight - 4,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): c.endRename,
              },
              child: ShadInput(
                controller: _rename,
                autofocus: true,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                onSubmitted: (_) => _commitRename(),
                onPressedOutside: (_) => _commitRename(),
              ),
            ),
          )
        : Text(
            node.label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: node.enabled
                  ? theme.colorScheme.foreground
                  : theme.colorScheme.mutedForeground,
            ),
          );

    final trailing = widget.view.trailingBuilder?.call(context, node);
    Widget row = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: renaming ? null : widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _drop == WonkyTreeDropPosition.inside
                ? theme.colorScheme.selectionColor
                : selected
                ? theme.colorScheme.sidebarAccent
                : _hover
                ? theme.colorScheme.accent.withValues(alpha: 0.6)
                : null,
            borderRadius: BorderRadius.circular(6),
            border: Border(
              top: _drop == WonkyTreeDropPosition.before
                  ? BorderSide(color: theme.colorScheme.ring, width: 2)
                  : BorderSide.none,
              bottom: _drop == WonkyTreeDropPosition.after
                  ? BorderSide(color: theme.colorScheme.ring, width: 2)
                  : BorderSide.none,
            ),
            boxShadow: focused
                ? [BoxShadow(color: theme.colorScheme.ring, spreadRadius: 1.5)]
                : null,
          ),
          padding: EdgeInsets.only(
            left: 4 + widget.row.depth * widget.view.indent,
            right: 4,
          ),
          child: Row(
            children: [
              chevron,
              if (node.icon != null) ...[
                Icon(
                  node.icon,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(child: label),
              if (trailing != null && (_hover || selected)) trailing,
            ],
          ),
        ),
      ),
    );

    Widget result = Semantics(
      selected: selected,
      expanded: node.hasChildren ? expanded : null,
      label: node.label,
      button: true,
      child: row,
    );

    if (widget.view.onDrop != null) {
      final target = result;
      result = DragTarget<Object>(
        onWillAcceptWithDetails: (d) {
          if (!node.enabled) return false;
          final pos = _positionFor(d.offset);
          final ok = widget.view.canAcceptDrop?.call(d.data, node, pos) ?? true;
          setState(() => _drop = ok ? pos : null);
          return ok;
        },
        onMove: (d) {
          final pos = _positionFor(d.offset);
          final ok = widget.view.canAcceptDrop?.call(d.data, node, pos) ?? true;
          if (ok && pos != _drop) setState(() => _drop = pos);
        },
        onLeave: (_) => setState(() => _drop = null),
        onAcceptWithDetails: (d) {
          final pos = _drop ?? WonkyTreeDropPosition.inside;
          setState(() => _drop = null);
          widget.view.onDrop!(d.data, node, pos);
        },
        builder: (context, candidates, rejected) => target,
      );
    }

    final data = widget.view.dragData?.call(node);
    if (data != null && !renaming) {
      final child = result;
      result = Draggable<Object>(
        data: data,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _DragFeedback(label: node.label, icon: node.icon),
        childWhenDragging: Opacity(opacity: 0.5, child: child),
        child: child,
      );
    }
    return result;
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Transform.translate(
      offset: const Offset(8, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.popover,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.colorScheme.border),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 6),
            ],
            Text(label, style: theme.textTheme.small),
          ],
        ),
      ),
    );
  }
}

extension on ShadColorScheme {
  Color get selectionColor => selection;
}
