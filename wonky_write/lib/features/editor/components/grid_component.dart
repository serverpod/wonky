import 'package:flutter/material.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show GridBullets, GridEmbed, InlineMarkdown, InlineRun, WonkyEmbed;

import '../../../l10n/write_l10n.dart';
import '../mapping/wonky_embed_node.dart';
import '../mapping/wonky_schema.dart';
import '../styles/editor_theme.dart';

/// A legacy Wonky Markdown grid embed (Write 11 §7.2), read-only until the
/// server upgrades it to grid item lines (Write 12 §1.5): its items in
/// `columns` columns (fewer when the content is narrow), each with its
/// bullet.
class WonkyGridComponentBuilder implements ComponentBuilder {
  const WonkyGridComponentBuilder({required this.theme, required this.zoom});

  final EditorTheme theme;
  final double zoom;

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
    return Semantics(
      label: l.editorGridLabel(grid.items.length, grid.columns),
      child: BoxComponent(
        key: componentContext.componentKey,
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
            ),
            child: _GridItems(grid: grid, theme: theme, zoom: zoom),
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
  });

  final GridEmbed grid;
  final EditorTheme theme;
  final double zoom;

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
  });

  final GridEmbed grid;
  final int index;
  final EditorTheme theme;
  final double zoom;

  TextStyle get _base =>
      theme.body.copyWith(fontSize: (theme.body.fontSize ?? 14.67) * zoom);

  @override
  Widget build(BuildContext context) {
    final size = (_base.fontSize ?? 14.67) * 1.3;
    final bullet = gridBullet(theme, grid.bullets, size);
    final content = _rendered(context);
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
}

/// The bullet of a grid item (Write 11 §7.2), `null` for [GridBullets.none].
Widget? gridBullet(EditorTheme theme, GridBullets bullets, double size) =>
    switch (bullets) {
      GridBullets.check => Icon(
        LucideIcons.check,
        size: size,
        color: theme.wonky.gridBulletColor,
      ),
      GridBullets.circle => Icon(
        LucideIcons.circleSmall,
        size: size,
        color: theme.wonky.gridBulletColor,
      ),
      GridBullets.none => null,
    };
