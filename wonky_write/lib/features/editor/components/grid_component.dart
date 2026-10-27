import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show GridBullets, GridEmbed, InlineMarkdown, InlineRun, WonkyEmbed;

import '../../../l10n/write_l10n.dart';
import '../grid/inline_grid_editing.dart';
import '../mapping/wonky_embed_node.dart';
import '../mapping/wonky_schema.dart';
import '../model/field_clicks.dart';
import '../styles/editor_theme.dart';
import 'editor_services.dart';
import 'wonky_components.dart';

/// The Wonky Markdown grid (Write 11 §7.2): its items in `columns` columns
/// (fewer when the content is narrow), each with its bullet; items are
/// edited in place ([InlineGridEditing]).
class WonkyGridComponentBuilder implements ComponentBuilder {
  const WonkyGridComponentBuilder({
    required this.theme,
    required this.zoom,
    this.editing,
    this.callbacks = const EditorBlockCallbacks(),
    this.editable = true,
  });

  final EditorTheme theme;
  final double zoom;
  final InlineGridEditing? editing;
  final EditorBlockCallbacks callbacks;
  final bool editable;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! WonkyEmbedNode) return null;
    final grid = WonkyEmbed.tryParse(
      node.getMetadataValue(WonkyNodeMetadata.embed),
    );
    if (grid is! GridEmbed) return null;
    return GridViewModel(nodeId: node.id, grid: grid);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! GridViewModel) return null;
    final selection = viewModel.selection?.nodeSelection;
    final isSelected =
        selection is UpstreamDownstreamNodeSelection && !selection.isCollapsed;
    final l = writeL10n(componentContext.context);
    final grid = viewModel.grid;
    final gridCallbacks = editable ? callbacks.grid : null;
    final chrome = gridCallbacks == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (c) => EditorChromeButton(
                  key: ValueKey('write.editor.grid.columns.${grid.id}'),
                  label: l.editorGridColumns(grid.columns),
                  tooltip: l.cmdGridSetColumns,
                  onTap: (rect) => gridCallbacks.onColumnsTap(grid.id, rect),
                ),
              ),
              const SizedBox(width: 4),
              EditorChromeButton(
                key: ValueKey('write.editor.grid.bullets.${grid.id}'),
                icon: switch (grid.bullets) {
                  GridBullets.check => LucideIcons.check,
                  GridBullets.circle => LucideIcons.circleSmall,
                  GridBullets.none => LucideIcons.minus,
                },
                tooltip: l.cmdGridSetBullets,
                onTap: (rect) => gridCallbacks.onBulletsTap(grid.id, rect),
              ),
              const SizedBox(width: 4),
              EditorChromeButton(
                key: ValueKey('write.editor.grid.add.${grid.id}'),
                icon: LucideIcons.plus,
                tooltip: l.cmdGridAddItem,
                onTap: (_) => gridCallbacks.onAddItem(grid.id),
              ),
              const SizedBox(width: 4),
              EditorChromeButton(
                key: ValueKey('write.editor.grid.menu.${grid.id}'),
                icon: LucideIcons.ellipsis,
                tooltip: l.editorGridMenu,
                onTap: (rect) => gridCallbacks.onMenu(grid.id, rect),
              ),
            ],
          );
    return Semantics(
      label: l.editorGridLabel(grid.items.length, grid.columns),
      child: BoxComponent(
        key: componentContext.componentKey,
        child: EditorHoverChrome(
          showAlways: isSelected,
          above: true,
          chrome: chrome,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: theme.ringColor, width: 2)
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: theme.wonky.gridSpaceBefore * zoom,
                bottom: theme.wonky.gridSpaceAfter * zoom,
                right: chrome == null ? 0 : 4,
              ),
              child: _GridItems(
                grid: grid,
                theme: theme,
                zoom: zoom,
                editing: editable ? editing : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The view model of a grid.
class GridViewModel extends SingleColumnLayoutComponentViewModel
    with SelectionAwareViewModelMixin {
  GridViewModel({
    required super.nodeId,
    required this.grid,
    super.createdAt,
    super.padding = EdgeInsets.zero,
    super.maxWidth,
  });

  final GridEmbed grid;

  @override
  GridViewModel copy() =>
      GridViewModel(
          nodeId: nodeId,
          grid: grid,
          padding: padding,
          maxWidth: maxWidth,
        )
        ..selection = selection
        ..selectionColor = selectionColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridViewModel &&
          other.nodeId == nodeId &&
          other.grid == grid &&
          other.padding == padding &&
          other.maxWidth == maxWidth &&
          other.selection == selection &&
          other.selectionColor == selectionColor;

  @override
  int get hashCode => Object.hash(nodeId, grid, padding, maxWidth, selection);
}

class _GridItems extends StatelessWidget {
  const _GridItems({
    required this.grid,
    required this.theme,
    required this.zoom,
    required this.editing,
  });

  final GridEmbed grid;
  final EditorTheme theme;
  final double zoom;
  final InlineGridEditing? editing;

  /// The columns that fit [width] (px): two need 320 px and three 480 px at
  /// 100 % (Write 11 §7.2).
  int _columnsFor(double width) {
    final w = width / zoom;
    final fit = w >= 480 ? 4 : (w >= 320 ? 2 : 1);
    if (grid.columns >= 3 && w >= 480) return grid.columns;
    return grid.columns < fit ? grid.columns : fit;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        final style = theme.wonky;
        final rows = <Widget>[];
        for (var start = 0; start < grid.items.length; start += columns) {
          if (rows.isNotEmpty) {
            rows.add(SizedBox(height: style.gridRowGap * zoom));
          }
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: style.gridColumnGap * zoom),
                  Expanded(
                    child: start + c < grid.items.length
                        ? _GridItem(
                            key: ValueKey(
                              'write.editor.gridItem.${grid.id}.${start + c}',
                            ),
                            grid: grid,
                            index: start + c,
                            theme: theme,
                            zoom: zoom,
                            editing: editing,
                          )
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
    super.key,
    required this.grid,
    required this.index,
    required this.theme,
    required this.zoom,
    required this.editing,
  });

  final GridEmbed grid;
  final int index;
  final EditorTheme theme;
  final double zoom;
  final InlineGridEditing? editing;

  TextStyle get _base =>
      theme.body.copyWith(fontSize: (theme.body.fontSize ?? 14.67) * zoom);

  @override
  Widget build(BuildContext context) {
    final style = theme.wonky;
    final size = (_base.fontSize ?? 14.67) * 1.3;
    final bullet = switch (grid.bullets) {
      GridBullets.check => Icon(
        LucideIcons.check,
        size: size,
        color: style.gridBulletColor,
      ),
      GridBullets.circle => Icon(
        LucideIcons.circleSmall,
        size: size,
        color: style.gridBulletColor,
      ),
      GridBullets.none => null,
    };
    final editing = this.editing;
    final content = editing == null
        ? _rendered(context)
        : ListenableBuilder(
            listenable: editing,
            builder: (context, _) {
              if (editing.active == GridItemRef(grid.id, index)) {
                return DocumentGestureOptOut(child: _field(editing));
              }
              if (!editing.canEdit(grid.id)) return _rendered(context);
              // In the field's tap region group: pressing another item is
              // not a tap outside the item being edited, which would end
              // editing (the editor showed its selection for a moment)
              // before this tap moves the editing here.
              return DocumentGestureOptOut(
                child: TapRegion(
                  groupId: editing,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.text,
                    child: Listener(
                      onPointerDown: editing.clicks.down,
                      onPointerUp: editing.clicks.up,
                      child: Builder(
                        builder: (item) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // The caret where the click was.
                          // (A fast second click can still land here:
                          // it selects the word.)
                          onTapUp: (details) {
                            final clicks = editing.clicks.count;
                            editing.activate(
                              grid.id,
                              index,
                              caret: _caretAt(item, details.globalPosition),
                            );
                            editing.selectForClicks(clicks);
                          },
                          child: _rendered(context),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bullet != null) ...[
          Padding(
            padding: EdgeInsets.only(top: size * 0.05),
            child: bullet,
          ),
          SizedBox(width: size * 0.45),
        ],
        Expanded(child: content),
      ],
    );
  }

  /// The source offset of the rendered text at [global].
  int? _caretAt(BuildContext item, Offset global) {
    final source = grid.items[index];
    final plain = InlineRun.plainText(InlineMarkdown.parseCell(source));
    if (plain.isEmpty) return 0;
    final offset = FieldClicks.renderedOffsetAt(
      item.findRenderObject(),
      global,
    );
    return offset == null
        ? null
        : FieldClicks.sourceOffset(source, plain, offset);
  }

  Widget _rendered(BuildContext context) {
    final source = grid.items[index];
    final runs = InlineMarkdown.parseCell(source);
    if (runs.isEmpty) {
      return Text(
        writeL10n(context).editorGridItemPlaceholder,
        style: _base.copyWith(color: theme.mutedColor),
      );
    }
    return Text.rich(
      TextSpan(children: [for (final r in runs) _span(r)]),
      style: _base,
    );
  }

  InlineSpan _span(InlineRun r) {
    final w = theme.wonky;
    var s = _base;
    if (r.bold) s = s.copyWith(fontWeight: FontWeight.w700);
    if (r.italic) s = s.copyWith(fontStyle: FontStyle.italic);
    if (r.strike) s = s.copyWith(decoration: TextDecoration.lineThrough);
    if (r.code) {
      s = s.copyWith(
        fontFamily: theme.monoFontFamily,
        fontSize: (s.fontSize ?? 14.67) * theme.inlineCodeSizeRatio,
        color: theme.inlineCodeColor,
        backgroundColor: theme.inlineCodeBackground,
      );
    }
    if (r.chip) {
      s = s.copyWith(
        color: w.chipColor,
        fontWeight: w.chipWeight,
        backgroundColor: w.chipBackground,
      );
    } else if (r.linkStyle == 'arrow') {
      s = s.copyWith(color: w.arrowColor, fontWeight: w.arrowWeight);
    } else if (r.linkStyle != null) {
      final secondary = r.linkStyle == 'buttonSecondary';
      s = s.copyWith(
        color: secondary ? w.secondaryButtonColor : w.buttonColor,
        backgroundColor: secondary
            ? w.secondaryButtonBackground
            : w.buttonBackground,
        fontWeight: w.buttonWeight,
      );
    } else if (r.link != null) {
      s = s.copyWith(
        color: theme.linkColor,
        decoration: theme.linkUnderline ? TextDecoration.underline : null,
      );
    }
    return TextSpan(text: r.text.replaceAll(' ', ' '), style: s);
  }

  Widget _field(InlineGridEditing editing) {
    return Focus(
      parentNode: editing.focusParent,
      canRequestFocus: false,
      skipTraversal: true,
      // After the field handled the click (a microtask), a double click's
      // second click selects the word.
      child: Listener(
        onPointerDown: editing.clicks.down,
        onPointerUp: (event) {
          final clicks = editing.clicks.up(event);
          if (clicks > 1) {
            scheduleMicrotask(() => editing.selectForClicks(clicks));
          }
        },
        child: _textField(editing),
      ),
    );
  }

  Widget _textField(InlineGridEditing editing) {
    return TextSelectionTheme(
      // The editor's selection color, not Material's.
      data: TextSelectionThemeData(
        selectionColor: theme.selectionColor,
        cursorColor: theme.caretColor,
      ),
      child: TextField(
        key: editing.fieldKey,
        controller: editing.text,
        focusNode: editing.focusNode,
        groupId: editing,
        undoController: editing.undo,
        style: _base,
        maxLines: null,
        cursorColor: theme.caretColor,
        cursorWidth: 2,
        decoration: const InputDecoration.collapsed(hintText: ''),
        inputFormatters: [
          FilteringTextInputFormatter.deny(
            RegExp(r'[\r\n]+'),
            replacementString: ' ',
          ),
        ],
        onChanged: editing.onChanged,
      ),
    );
  }
}
