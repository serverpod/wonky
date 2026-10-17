import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/slides_l10n.dart';
import '../inspector/deck_inspector.dart';
import 'canvas_region.dart';
import 'deck_editor_controller.dart';
import '../grid_view/slide_grid_view.dart';
import '../masters/masters_view.dart';
import '../navigator/mobile_slide_strip.dart';
import '../navigator/slide_navigator.dart';
import '../notes/notes_pane.dart';
import '../outline_view/outline_view.dart';

/// The editor body (Slides 04 §2, §16): navigator │ canvas over the notes
/// pane │ inspector, with the view modes replacing navigator + canvas +
/// notes (Grid, Outline, Masters — SL-28's `MastersView`). Responsive: ≥ 1,200 px everything is
/// docked; 768–1,200 px the inspector overlays the canvas from the right
/// (navigator 140 px below 1,024); < 768 px the navigator is a drawer and
/// the inspector overlays over a scrim. Panes resize by dragging their
/// edges (device preferences).
class DeckBody extends StatelessWidget {
  const DeckBody({
    super.key,
    required this.services,
    required this.editor,
    required this.onContextMenu,
  });

  final ShellServices services;
  final DeckEditorController editor;
  final OpenContextMenu onContextMenu;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: editor,
    builder: (context, _) => LayoutBuilder(
      builder: (context, c) {
        editor.reportLayoutWidth(c.maxWidth);
        if (WonkyLayout.isMobile(context)) return _mobile(context);
        return _layout(context, c);
      },
    ),
  );

  /// The read-only mobile layout (04 §16.1): the slide over the compact
  /// slide selector; no notes, inspector or other views.
  Widget _mobile(BuildContext context) => Column(
    key: const ValueKey<String>('slides.mobile.body'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: CanvasRegion(
          services: services,
          editor: editor,
          onContextMenu: onContextMenu,
        ),
      ),
      MobileSlideStrip(services: services, editor: editor),
    ],
  );

  Widget _layout(BuildContext context, BoxConstraints c) {
    final ed = editor;
    final theme = ShadTheme.of(context);
    final l = slidesL10n(context);
    final normal = ed.mode == DeckViewMode.normal;

    final Widget main = switch (ed.mode) {
      DeckViewMode.normal => CanvasRegion(
        services: services,
        editor: ed,
        onContextMenu: onContextMenu,
      ),
      DeckViewMode.grid => SlideGridView(
        services: services,
        editor: ed,
        onContextMenu: onContextMenu,
      ),
      DeckViewMode.outline => OutlineView(services: services, editor: ed),
      DeckViewMode.masters => MastersView(
        services: services,
        editor: ed,
        onContextMenu: onContextMenu,
      ),
    };

    // Canvas over the notes pane (Normal view only).
    Widget center = main;
    if (normal) {
      final maxNotes = (c.maxHeight * 0.5).clamp(48.0, 2000.0);
      final notesHeight = ed.notesHeight.clamp(48.0, maxNotes);
      center = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: main),
          if (ed.notesVisible) ...[
            _ResizeHandle(
              key: const ValueKey<String>('slides.notes.resize'),
              axis: Axis.vertical,
              onDrag: (d) => ed.resizePane('notes', notesHeight - d),
              onEnd: () => ed.resizePane('notes', ed.notesHeight, commit: true),
            ),
            SizedBox(
              height: notesHeight,
              child: NotesPane(services: services, editor: ed, expanded: true),
            ),
          ] else
            NotesPane(services: services, editor: ed, expanded: false),
        ],
      );
    }

    final showNavigator = normal && ed.navigatorVisible;
    final navWidth = c.maxWidth < 1024 && !ed.isNarrow
        ? 140.0
        : ed.navigatorWidth.clamp(160.0, 400.0);
    final navigator = SlideNavigator(
      services: services,
      editor: ed,
      width: navWidth,
      onContextMenu: onContextMenu,
    );
    final inspectorWidth = ed.isNarrow
        ? (c.maxWidth - 24).clamp(200.0, 360.0)
        : ed.inspectorWidth.clamp(260.0, 420.0);
    final inspector = SizedBox(
      width: inspectorWidth,
      child: DeckInspector(
        services: services,
        editor: ed,
        onClose: () => ed.setInspectorVisible(false),
      ),
    );

    final docked = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showNavigator && !ed.isNarrow) ...[
          SizedBox(width: navWidth, child: navigator),
          _ResizeHandle(
            key: const ValueKey<String>('slides.navigator.resize'),
            axis: Axis.horizontal,
            onDrag: (d) => ed.resizePane('navigator', navWidth + d),
            onEnd: () =>
                ed.resizePane('navigator', ed.navigatorWidth, commit: true),
          ),
        ],
        Expanded(child: center),
        if (ed.inspectorVisible && !ed.inspectorOverlays) ...[
          _ResizeHandle(
            key: const ValueKey<String>('slides.inspector.resize'),
            axis: Axis.horizontal,
            onDrag: (d) => ed.resizePane('inspector', inspectorWidth - d),
            onEnd: () =>
                ed.resizePane('inspector', ed.inspectorWidth, commit: true),
          ),
          inspector,
        ],
      ],
    );

    final scrim = theme.colorScheme.foreground.withValues(alpha: 0.18);
    return Stack(
      children: [
        Positioned.fill(child: docked),
        // Narrow: the navigator drawer (04 §16).
        if (showNavigator && ed.isNarrow) ...[
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey<String>('slides.navigator.scrim'),
              onTap: () => ed.setNavigatorVisible(false),
              child: ColoredBox(color: scrim),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: (c.maxWidth * 0.75).clamp(160.0, 280.0),
            child: _elevated(context, navigator),
          ),
        ],
        if (normal && ed.isNarrow && !showNavigator)
          Positioned(
            left: 8,
            top: 8,
            child: ShadTooltip(
              builder: (_) => Text(l.cmdViewToggleNavigator),
              child: ShadIconButton.secondary(
                key: const ValueKey<String>('slides.navigator.open'),
                width: 32,
                height: 32,
                iconSize: 16,
                semanticLabel: l.navigatorOpen,
                icon: const Icon(LucideIcons.panelLeft),
                onPressed: () => ed.setNavigatorVisible(true),
              ),
            ),
          ),
        // Below 1,200 px: the inspector overlays the canvas (a scrim only
        // below 768 px).
        if (ed.inspectorVisible && ed.inspectorOverlays) ...[
          if (ed.isNarrow)
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey<String>('slides.inspector.scrim'),
                onTap: () => ed.setInspectorVisible(false),
                child: ColoredBox(color: scrim),
              ),
            ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _elevated(context, inspector),
          ),
        ],
      ],
    );
  }

  Widget _elevated(BuildContext context, Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: const Color(0x33000000),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

/// A 5 px drag handle between panes (a 1 px line, the resize cursor).
class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    super.key,
    required this.axis,
    required this.onDrag,
    required this.onEnd,
  });

  /// [Axis.horizontal] resizes widths (a vertical line).
  final Axis axis;
  final ValueChanged<double> onDrag;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final horizontal = axis == Axis.horizontal;
    return MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: horizontal ? (d) => onDrag(d.delta.dx) : null,
        onHorizontalDragEnd: horizontal ? (_) => onEnd() : null,
        onVerticalDragUpdate: horizontal ? null : (d) => onDrag(d.delta.dy),
        onVerticalDragEnd: horizontal ? null : (_) => onEnd(),
        child: SizedBox(
          width: horizontal ? 5 : null,
          height: horizontal ? null : 5,
          child: Center(
            child: Container(
              width: horizontal ? 1 : null,
              height: horizontal ? null : 1,
              color: theme.colorScheme.border,
            ),
          ),
        ),
      ),
    );
  }
}
