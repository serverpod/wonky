import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../../l10n/write_l10n.dart';
import '../editor/styles/editor_theme.dart';
import 'document_theme.dart';
import 'theme_adapter.dart';

/// The theme picker (Write 06 §10.1 entry point, 05 §9.7): a grid of theme
/// cards with light and dark previews. Picking applies immediately
/// ([onSelect] runs `write.theme.apply`, undoable); the dialog stays open
/// so the user sees the document change behind it.
Future<void> showThemePicker(
  BuildContext context, {
  required WriteThemeCatalog catalog,
  required ValueListenable<String?> selected,
  required void Function(ThemeOption option) onSelect,
  VoidCallback? onSetDefault,
  VoidCallback? onCustomize,
  VoidCallback? onNewTheme,
  bool readOnly = false,
}) => showShadDialog<void>(
  context: context,
  builder: (_) => ThemePickerDialog(
    catalog: catalog,
    selected: selected,
    onSelect: onSelect,
    onSetDefault: onSetDefault,
    onCustomize: onCustomize,
    onNewTheme: onNewTheme,
    readOnly: readOnly,
  ),
);

class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({
    super.key,
    required this.catalog,
    required this.selected,
    required this.onSelect,
    this.onSetDefault,
    this.onCustomize,
    this.onNewTheme,
    this.readOnly = false,
  });

  final WriteThemeCatalog catalog;
  final ValueListenable<String?> selected;
  final void Function(ThemeOption option) onSelect;
  final VoidCallback? onSetDefault;

  /// Opens the theme editor on the selected theme (closes the dialog).
  final VoidCallback? onCustomize;

  /// Creates a theme from the selected one and opens it.
  final VoidCallback? onNewTheme;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final l = writeL10n(context);
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.themePicker'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.themePickerTitle),
      description: Text(
        readOnly ? l.themePickerDescriptionReadOnly : l.themePickerDescription,
      ),
      constraints: BoxConstraints(
        maxWidth: (size.width * 0.92).clamp(320, 860),
      ),
      actions: [
        if (onNewTheme != null)
          ShadButton.ghost(
            key: const ValueKey<String>('write.dialog.themePicker.new'),
            leading: const Icon(LucideIcons.plus, size: 16),
            onPressed: () {
              Navigator.of(context).pop();
              onNewTheme!();
            },
            child: Text(l.cmdThemeCreate),
          ),
        if (onCustomize != null)
          ShadButton.outline(
            key: const ValueKey<String>('write.dialog.themePicker.customize'),
            leading: const Icon(LucideIcons.paintbrush, size: 16),
            onPressed: () {
              Navigator.of(context).pop();
              onCustomize!();
            },
            child: Text(l.themePickerCustomize),
          ),
        if (onSetDefault != null)
          ShadButton.ghost(
            key: const ValueKey<String>('write.dialog.themePicker.default'),
            onPressed: onSetDefault,
            child: Text(l.cmdThemeSetUserDefault),
          ),
        ShadButton(
          key: const ValueKey<String>('write.dialog.themePicker.done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonDone),
        ),
      ],
      child: ThemeGrid(
        catalog: catalog,
        selected: selected,
        onSelect: readOnly ? null : onSelect,
      ),
    );
  }
}

/// The grid of theme cards (also used in document settings).
class ThemeGrid extends StatelessWidget {
  const ThemeGrid({
    super.key,
    required this.catalog,
    required this.selected,
    this.onSelect,
  });

  final WriteThemeCatalog catalog;
  final ValueListenable<String?> selected;
  final void Function(ThemeOption option)? onSelect;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([catalog, selected]),
      builder: (context, _) {
        final options = [...WriteThemeCatalog.builtins, ...catalog.mine];
        final current = selected.value;
        // No LayoutBuilder: the dialog measures intrinsic sizes.
        return SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final o in options)
                SizedBox(
                  width: 188,
                  child: ThemeCard(
                    key: ValueKey<String>(
                      'write.theme.card.${o.builtinKey ?? o.uuid}',
                    ),
                    option: o,
                    selected:
                        current == o.uuid ||
                        (current != null && current == o.builtinKey),
                    onTap: onSelect == null ? null : () => onSelect!(o),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One theme: light/dark split preview, name and description.
class ThemeCard extends StatefulWidget {
  const ThemeCard({
    super.key,
    required this.option,
    required this.selected,
    this.onTap,
  });

  final ThemeOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<ThemeCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final light = const EditorThemeAdapter().adapt(
      ThemeResolver.instance.resolve(widget.option.data, ThemeVariant.light),
    );
    final dark = const EditorThemeAdapter().adapt(
      ThemeResolver.instance.resolve(widget.option.data, ThemeVariant.dark),
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: writeL10n(context).themePickerCardLabel(widget.option.name),
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: ShadFocusable(
          canRequestFocus: widget.onTap != null,
          onKeyEvent: (node, e) {
            if (e is KeyDownEvent &&
                (e.logicalKey == LogicalKeyboardKey.enter ||
                    e.logicalKey == LogicalKeyboardKey.space)) {
              widget.onTap?.call();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          builder: (context, focused, child) => GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: widget.selected ? 2 : 1,
                  color: widget.selected
                      ? cs.primary
                      : (_hover || focused ? cs.ring : cs.border),
                ),
                color: _hover ? cs.accent.withValues(alpha: 0.4) : null,
              ),
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 108,
                  child: Row(
                    children: [
                      Expanded(child: _Sample(theme: light)),
                      Expanded(child: _Sample(theme: dark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.option.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.selected)
                    ExcludeSemantics(
                      child: Icon(
                        LucideIcons.check,
                        size: 16,
                        color: cs.primary,
                      ),
                    ),
                ],
              ),
              if (widget.option.description case final d?
                  when d.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  d,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sample extends StatelessWidget {
  const _Sample({required this.theme});

  final EditorTheme theme;

  @override
  Widget build(BuildContext context) {
    final h = theme.headings.first;
    final body = theme.body;
    return ColoredBox(
      color: theme.paperColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aa',
              maxLines: 1,
              style: h.copyWith(fontSize: 22, height: 1.1),
            ),
            const SizedBox(height: 6),
            Text(
              writeL10n(context).themePickerSampleText,
              maxLines: 3,
              overflow: TextOverflow.clip,
              style: body.copyWith(fontSize: 9, height: 1.35),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.linkColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.codeBlockBackground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A tiny theme swatch: light and dark paper halves with the accent color
/// (theme lists).
class ThemeSwatchPreview extends StatelessWidget {
  const ThemeSwatchPreview({super.key, required this.option, this.size = 16});

  final ThemeOption option;
  final double size;

  @override
  Widget build(BuildContext context) {
    final light = ThemeResolver.instance.resolve(
      option.data,
      ThemeVariant.light,
    );
    final dark = ThemeResolver.instance.resolve(option.data, ThemeVariant.dark);
    final accent = Color(light.link.color);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 4),
          border: Border.all(color: ShadTheme.of(context).colorScheme.border),
          gradient: LinearGradient(
            colors: [
              Color(light.page.paperColor),
              Color(light.page.paperColor),
              Color(dark.page.paperColor),
              Color(dark.page.paperColor),
            ],
            stops: const [0, 0.5, 0.5, 1],
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: size * 0.38,
          height: size * 0.38,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
