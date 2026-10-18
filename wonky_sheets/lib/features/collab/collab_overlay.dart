import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show CommentThreadView;
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../comments/sheets_comments.dart';
import '../history/cell_history_popover.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'sheets_collab.dart';

/// The collaboration UI above the grid (Sheets 10): comment/note hover
/// cards, the docked thread card of the active cell, the follow banner and
/// the cell edit history popover. Wraps the `GridArea` (same origin, so
/// the editor's grid geometry positions the cards).
class CollabGridOverlay extends StatefulWidget {
  const CollabGridOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  final SheetEditorController controller;
  final Widget child;

  @override
  State<CollabGridOverlay> createState() => _CollabGridOverlayState();
}

class _CollabGridOverlayState extends State<CollabGridOverlay> {
  SheetEditorController get c => widget.controller;
  SheetsCollab? get collab => SheetsCollab.of(c);

  Timer? _hoverTimer;
  (int, int)? _hoverCell;
  (int, int)? _shownHover;
  bool _overCard = false;

  /// Hover delay of indicators (10 §3.3).
  static const hoverDelay = Duration(milliseconds: 300);

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _onHover(PointerHoverEvent e) {
    final g = c.geometry;
    final col = collab;
    if (g == null || col == null) return;
    final p = e.localPosition;
    (int, int)? cell;
    if (g.cellsRect.contains(p)) {
      final pane = g.paneAt(p);
      if (pane != null) cell = pane.cellAt(p);
    }
    // Name flags of collaborators show while their cell is hovered.
    col.presence.setHover(
      cell == null ? null : c.activeSheetId,
      cell?.$1 ?? 0,
      cell?.$2 ?? 0,
    );
    if (cell != null && !_hasCard(cell)) cell = null;
    if (cell == _hoverCell) return;
    _hoverCell = cell;
    _hoverTimer?.cancel();
    if (cell == null) {
      // Leave a little time to move onto the card.
      _hoverTimer = Timer(const Duration(milliseconds: 250), () {
        if (!_overCard && mounted) setState(() => _shownHover = null);
      });
      return;
    }
    _hoverTimer = Timer(hoverDelay, () {
      if (mounted) setState(() => _shownHover = _hoverCell);
    });
  }

  void _onExit(PointerExitEvent e) {
    collab?.presence.setHover(null, 0, 0);
    _hoverCell = null;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_overCard && mounted) setState(() => _shownHover = null);
    });
  }

  bool _hasCard((int, int) cell) {
    final col = collab;
    if (col == null) return false;
    final sheet = c.activeSheet;
    if (sheet == null) return false;
    final note = sheet.cellAt(cell.$1, cell.$2)?.note;
    if (note != null && note.isNotEmpty) return true;
    return col.comments.visible &&
        col.comments.indicatorsOn &&
        col.comments.threadsAt(c.activeSheetId, cell.$1, cell.$2).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final col = collab;
    if (col != null) {
      final cs = theme.colorScheme;
      col.colors
        ..presence = cs.presence
        ..dark = theme.brightness == Brightness.dark;
    }
    return MouseRegion(
      opaque: false,
      onHover: _onHover,
      onExit: _onExit,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: widget.child),
          if (col != null)
            Positioned.fill(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  c.scroll,
                  c.contentSignal,
                  c.selection,
                  col.comments,
                  col.cellHistory,
                  col.dockedDismissed,
                  col.presence.following,
                  c.services.panels,
                ]),
                builder: (context, _) => LayoutBuilder(
                  builder: (context, box) => Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      ..._docked(context, col, box.biggest),
                      ..._composer(context, col, box.biggest),
                      ..._hover(context, col, box.biggest),
                      ..._history(context, col, box.biggest),
                      ?_followBanner(context, col),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Positions a card of [width] next to the cell rect [cell] (right of
  /// it, or left when there is no room), clamped into [area].
  Positioned _place(
    Rect cell,
    Size area, {
    required double width,
    required Widget child,
    double maxHeight = 360,
  }) {
    var left = cell.right + 6;
    if (left + width > area.width - 8) left = cell.left - width - 6;
    left = left.clamp(8.0, math.max(8.0, area.width - width - 8));
    final w = math.min(width, area.width - 16);
    var top = cell.top;
    top = top.clamp(8.0, math.max(8.0, area.height - 120));
    return Positioned(
      left: left,
      top: top,
      width: math.max(160, w),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: math.max(120, math.min(maxHeight, area.height - top - 8)),
        ),
        child: child,
      ),
    );
  }

  Rect? _cellRect(int row, int col) {
    final g = c.geometry;
    if (g == null) return null;
    final sheet = c.activeSheet;
    final merge = sheet?.mergeAt(row, col);
    final r = merge == null ? g.cellRect(row, col) : g.rangeRect(merge);
    if (!g.cellsRect.overlaps(r)) return null;
    return r;
  }

  // ------------------------------------------------------------ hover card

  List<Widget> _hover(BuildContext context, SheetsCollab col, Size area) {
    final cell = _shownHover;
    if (cell == null) return const [];
    final rect = _cellRect(cell.$1, cell.$2);
    final sheet = c.activeSheet;
    if (rect == null || sheet == null) return const [];
    final note = sheet.cellAt(cell.$1, cell.$2)?.note;
    final threads = col.comments.visible && col.comments.indicatorsOn
        ? col.comments.threadsAt(c.activeSheetId, cell.$1, cell.$2)
        : const <PlacedThread>[];
    if ((note == null || note.isEmpty) && threads.isEmpty) return const [];
    return [
      _place(
        rect,
        area,
        width: 300,
        maxHeight: 240,
        child: MouseRegion(
          onEnter: (_) => _overCard = true,
          onExit: (_) {
            _overCard = false;
            if (_hoverCell != _shownHover) {
              setState(() => _shownHover = null);
            }
          },
          child: _HoverCard(
            key: const ValueKey<String>('sheets.comments.hoverCard'),
            note: note,
            threads: [for (final t in threads) t.thread],
            onOpen: threads.isEmpty
                ? null
                : () {
                    setState(() => _shownHover = null);
                    unawaited(
                      c.invokeCommand('shell.comments.activate', {
                        'threadUuid': threads.first.thread.uuid.uuid,
                      }),
                    );
                  },
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------- docked card

  /// The composer of a new comment, next to its cell (Sheets 10 §3.4)
  /// while the comments panel is closed.
  List<Widget> _composer(BuildContext context, SheetsCollab col, Size area) {
    final controller = col.comments.controller;
    final draft = controller?.draftAnchor;
    if (controller == null ||
        draft == null ||
        c.services.panels.isOpen(ShellPanels.comments)) {
      return const [];
    }
    final a = SheetsCommentAnchor.parse(draft.kind, draft.anchorJson);
    final rect = a == null || a.sheetId != c.activeSheetId
        ? null
        : a.resolve(c.model);
    final cell = rect == null ? null : _cellRect(rect.top, rect.right);
    if (cell == null) return const [];
    return [
      _place(
        cell,
        area,
        width: 320,
        maxHeight: 360,
        child: Focus(
          onKeyEvent: (node, e) {
            if (e is KeyDownEvent &&
                e.logicalKey == LogicalKeyboardKey.escape) {
              controller.cancelDraft();
              c.gridFocus.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: SingleChildScrollView(
            child: NewCommentCard(
              key: const ValueKey<String>('sheets.comments.composer'),
              services: c.services,
              controller: controller,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _docked(BuildContext context, SheetsCollab col, Size area) {
    final comments = col.comments;
    final controller = comments.controller;
    if (controller?.draftAnchor != null) return const [];
    if (controller == null ||
        !comments.visible ||
        !comments.indicatorsOn ||
        col.dockedDismissed.value ||
        col.cellHistory.value != null ||
        c.editor.isEditing ||
        c.services.panels.isOpen(ShellPanels.comments)) {
      return const [];
    }
    final sel = c.selection.resolved;
    final placed = comments.threadsCovering(
      c.activeSheetId,
      sel.activeRow,
      sel.activeCol,
    );
    if (placed.isEmpty) return const [];
    final p = placed.first;
    final rect = _cellRect(p.rect.top, p.rect.right);
    if (rect == null) return const [];
    _shownHover = null;
    return [
      _place(
        rect,
        area,
        width: 300,
        maxHeight: 420,
        child: Focus(
          onKeyEvent: (node, e) {
            if (e is KeyDownEvent &&
                e.logicalKey == LogicalKeyboardKey.escape) {
              col.dockedDismissed.value = true;
              c.gridFocus.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: _DockedThread(
            key: ValueKey<String>(
              'sheets.comments.docked.${p.thread.uuid.uuid}',
            ),
            services: c.services,
            controller: controller,
            thread: p.thread,
            onClose: () {
              col.dockedDismissed.value = true;
              c.gridFocus.requestFocus();
            },
          ),
        ),
      ),
    ];
  }

  // ------------------------------------------------------- cell history

  List<Widget> _history(BuildContext context, SheetsCollab col, Size area) {
    final h = col.cellHistory.value;
    if (h == null) return const [];
    final sheet = c.model.sheet(h.target.sheetId);
    if (sheet == null || h.target.sheetId != c.activeSheetId) return const [];
    final row = sheet.rows.indexOf(h.target.rowId);
    final colIndex = sheet.columns.indexOf(h.target.colId);
    if (row < 0 || colIndex < 0) return const [];
    final rect = _cellRect(row, colIndex);
    if (rect == null) return const [];
    return [
      _place(
        rect,
        area,
        width: 340,
        maxHeight: 280,
        child: CellHistoryPopover(
          key: const ValueKey<String>('sheets.history.cellPopover'),
          editor: c,
          controller: h,
          onClose: col.closeCellHistory,
        ),
      ),
    ];
  }

  // ------------------------------------------------------- follow banner

  Widget? _followBanner(BuildContext context, SheetsCollab col) {
    final id = col.presence.following.value;
    if (id == null) return null;
    final cursor = col.presence.cursorOf(id);
    if (cursor == null) return null;
    final theme = ShadTheme.of(context);
    final l = sheetsL10n(context);
    final color = theme.colorScheme.presence(cursor.colorIndex);
    final g = c.geometry;
    return Positioned(
      top: (g?.cellsRect.top ?? 24) + 8,
      right: 16,
      child: Container(
        key: const ValueKey<String>('sheets.presence.followBanner'),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.popover,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: color, width: 4),
            top: BorderSide(color: theme.colorScheme.border),
            right: BorderSide(color: theme.colorScheme.border),
            bottom: BorderSide(color: theme.colorScheme.border),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l.presenceFollowingName(cursor.displayName),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small,
              ),
            ),
            const SizedBox(width: 6),
            ShadButton.ghost(
              key: const ValueKey<String>('sheets.presence.stopFollowing'),
              size: ShadButtonSize.sm,
              onPressed: () =>
                  unawaited(c.invokeCommand('sheets.presence.unfollow')),
              child: Text(l.presenceStopFollowing),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hover card of a cell's comment thread(s) and note (10 §3.3).
class _HoverCard extends StatelessWidget {
  const _HoverCard({
    super.key,
    required this.note,
    required this.threads,
    required this.onOpen,
  });

  final String? note;
  final List<CommentThreadView> threads;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = sheetsL10n(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.popover,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in threads) ...[
              GestureDetector(
                onTap: onOpen,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          WonkyAvatar(
                            name:
                                t.comments.firstOrNull?.author?.displayName ??
                                '',
                            color: cs.presence(
                              t.comments.firstOrNull?.author?.colorIndex ?? 0,
                            ),
                            imageUrl: t.comments.firstOrNull?.author?.avatarUrl,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t.comments.firstOrNull?.author?.displayName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.small.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.comments.firstOrNull?.body ?? '',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small,
                      ),
                      if (t.comments.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          l.commentReplies(t.comments.length - 1),
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (note != null && note!.isNotEmpty) ...[
              if (threads.isNotEmpty)
                ShadSeparator.horizontal(
                  margin: const EdgeInsets.only(bottom: 8),
                ),
              Text(
                l.noteHeading,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(note!, style: theme.textTheme.small),
            ],
          ],
        ),
      ),
    );
  }
}

/// The thread card docked next to the active cell (10 §3.3).
class _DockedThread extends StatelessWidget {
  const _DockedThread({
    super.key,
    required this.services,
    required this.controller,
    required this.thread,
    required this.onClose,
  });

  final ShellServices services;
  final CommentsController controller;
  final CommentThreadView thread;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final cs = ShadTheme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.popover,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: CommentThreadCard(
              services: services,
              controller: controller,
              thread: thread,
              onTap: () {},
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: ShadIconButton.ghost(
              key: const ValueKey<String>('sheets.comments.docked.close'),
              width: 24,
              height: 24,
              iconSize: 14,
              semanticLabel: l.actionClose,
              icon: const Icon(LucideIcons.x),
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}
