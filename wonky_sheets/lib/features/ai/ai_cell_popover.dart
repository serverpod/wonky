import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/formula.dart' show FormulaLocale;

import '../../l10n/sheets_l10n.dart';
import '../../theme/sheets_tokens.dart';
import '../cell_editor/formula_text_controller.dart';
import 'sheets_ai_controller.dart';

/// A formula with the editor's syntax colors (locale-aware).
class HighlightedFormula extends StatelessWidget {
  const HighlightedFormula(this.formula, {super.key, required this.locale});

  final String formula;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final c = FormulaTextController(text: formula)
      ..tokens = GridPaintTokens.ofContext(context)
      ..locale = FormulaLocale.forId(locale);
    final span = c.buildTextSpan(
      context: context,
      style: theme.textTheme.small.copyWith(
        fontFamily: 'GeistMono',
        color: theme.colorScheme.foreground,
      ),
      withComposing: false,
    );
    c.dispose();
    return Text.rich(span);
  }
}

/// Places the AI cell popover under its cell in the grid's overlay stack
/// (`GridHooks.overlays`).
class AiCellPopoverHost extends StatelessWidget {
  const AiCellPopoverHost({super.key, required this.ai});

  final SheetsAiController ai;

  static const width = 380.0;

  @override
  Widget build(BuildContext context) {
    final ed = ai.editor;
    return ListenableBuilder(
      listenable: Listenable.merge([ai.popover, ed.scroll, ed]),
      builder: (context, _) {
        final s = ai.popover.value;
        final g = ed.geometry;
        if (s == null || g == null || s.sheetId != ed.activeSheetId) {
          return const SizedBox.shrink();
        }
        final cell = g.cellRect(s.row, s.col);
        final size = g.size;
        final w = math.min(width, size.width - 16);
        final left = cell.left
            .clamp(8.0, math.max(8.0, size.width - w - 8))
            .toDouble();
        // Below the cell; above it when there is no room.
        final below = cell.bottom + 4;
        final room = size.height - below;
        final top = room >= 220 || cell.top < 260
            ? below
            : math.max(8.0, cell.top - 4 - 260);
        return Positioned(
          left: left,
          top: top,
          width: w,
          child: AiCellPopover(ai: ai, state: s),
        );
      },
    );
  }
}

/// The ✨ formula suggestion / Explain formula card (Sheets 12 §6.4–6.5).
class AiCellPopover extends StatefulWidget {
  const AiCellPopover({super.key, required this.ai, required this.state});

  final SheetsAiController ai;
  final AiPopoverState state;

  @override
  State<AiCellPopover> createState() => _AiCellPopoverState();
}

class _AiCellPopoverState extends State<AiCellPopover> {
  late final TextEditingController _prompt = TextEditingController(
    text: widget.state.prompt,
  );
  final _focus = FocusNode(debugLabel: 'sheets.ai.prompt');

  SheetsAiController get ai => widget.ai;
  AiPopoverState get s => widget.state;

  @override
  void initState() {
    super.initState();
    if (s.kind == AiPopoverKind.suggest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(AiCellPopover old) {
    super.didUpdateWidget(old);
    if (_prompt.text != s.prompt && !_focus.hasFocus) _prompt.text = s.prompt;
  }

  @override
  void dispose() {
    _prompt.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    ai.closePopover();
    ai.editor.gridFocus.requestFocus();
  }

  Future<void> _ask() async {
    s.prompt = _prompt.text.trim();
    if (s.prompt.isEmpty) return;
    await ai.runSuggest();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = sheetsL10n(context);
    final title = s.kind == AiPopoverKind.suggest
        ? l.aiSuggestTitle
        : l.aiExplainTitle;
    return IsolatedKeys(
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
        child: FocusScope(
          child: Container(
            key: ValueKey<String>('sheets.ai.popover.${s.kind.name}'),
            constraints: const BoxConstraints(maxHeight: 420),
            decoration: BoxDecoration(
              color: cs.popover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff000000).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
                  child: Row(
                    children: [
                      Icon(LucideIcons.sparkles, size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$title · ${s.cellA1}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.small,
                        ),
                      ),
                      ShadIconButton.ghost(
                        key: const ValueKey<String>('sheets.ai.popover.close'),
                        width: 26,
                        height: 26,
                        iconSize: 13,
                        semanticLabel: WonkyAppLocalizations.of(
                          context,
                        ).actionClose,
                        icon: const Icon(LucideIcons.x),
                        onPressed: _close,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: s.kind == AiPopoverKind.suggest
                        ? _suggest(context)
                        : _explain(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggest(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final f = s.suggestion;
    final reason = ai.unavailableReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): () =>
                unawaited(_ask()),
          },
          child: ShadInput(
            key: const ValueKey<String>('sheets.ai.suggest.prompt'),
            controller: _prompt,
            focusNode: _focus,
            enabled: reason == null && !s.loading,
            placeholder: Text(l.aiSuggestPlaceholder),
            onChanged: (v) => s.prompt = v,
          ),
        ),
        if (reason != null)
          Text(reason, style: theme.textTheme.muted)
        else if (s.loading)
          Row(
            children: [
              const SizedBox(width: 14, height: 14, child: ShadSpinner()),
              const SizedBox(width: 8),
              Text(l.aiWorking, style: theme.textTheme.muted),
            ],
          ),
        if (s.error != null)
          Text(
            s.error!,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
        if (f != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: HighlightedFormula(
              f.localizedFormula,
              locale: ai.editor.locale,
            ),
          ),
          if (f.previewValue != null)
            Text(
              l.aiSuggestResult(f.previewValue!),
              key: const ValueKey<String>('sheets.ai.suggest.preview'),
              style: theme.textTheme.small,
            ),
          if (f.errorMessage != null)
            Text(
              f.errorMessage!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          if (f.usesExternalData)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.globe,
                  size: 13,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.aiSuggestExternal,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          if (f.explanation.isNotEmpty)
            Text(f.explanation, style: theme.textTheme.muted),
        ],
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          children: [
            if (f != null) ...[
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.copy, size: 13),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: f.localizedFormula)),
                child: Text(la.actionCopy),
              ),
              ShadButton.outline(
                key: const ValueKey<String>('sheets.ai.suggest.retry'),
                size: ShadButtonSize.sm,
                enabled: !s.loading,
                leading: const Icon(LucideIcons.refreshCw, size: 13),
                onPressed: () => unawaited(_ask()),
                child: Text(l.aiSuggestTryAgain),
              ),
              ShadButton(
                key: const ValueKey<String>('sheets.ai.suggest.insert'),
                size: ShadButtonSize.sm,
                enabled:
                    !s.loading && ai.editor.canEdit && f.formula.isNotEmpty,
                onPressed: () => unawaited(ai.insertSuggestion()),
                child: Text(l.aiSuggestInsert),
              ),
            ] else
              ShadButton(
                key: const ValueKey<String>('sheets.ai.suggest.ask'),
                size: ShadButtonSize.sm,
                enabled: reason == null && !s.loading,
                leading: const Icon(LucideIcons.sparkles, size: 13),
                onPressed: () => unawaited(_ask()),
                child: Text(l.aiSuggestAsk),
              ),
          ],
        ),
      ],
    );
  }

  Widget _explain(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final md = s.markdown.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: HighlightedFormula(s.formula, locale: ai.editor.locale),
        ),
        if (md.isNotEmpty)
          AssistantMarkdown(md, key: const ValueKey('sheets.ai.explain.text')),
        if (s.loading)
          Row(
            children: [
              const SizedBox(width: 14, height: 14, child: ShadSpinner()),
              const SizedBox(width: 8),
              Text(l.aiWorking, style: theme.textTheme.muted),
            ],
          ),
        if (s.error != null)
          Text(
            s.error!,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
        if (!s.loading && md.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: [
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.copy, size: 13),
                onPressed: () => Clipboard.setData(ClipboardData(text: md)),
                child: Text(la.actionCopy),
              ),
              if (ai.chat != null)
                ShadButton.outline(
                  key: const ValueKey<String>('sheets.ai.explain.toPanel'),
                  size: ShadButtonSize.sm,
                  leading: const Icon(LucideIcons.panelRight, size: 13),
                  onPressed: ai.explanationToPanel,
                  child: Text(l.aiExplainToPanel),
                ),
            ],
          ),
      ],
    );
  }
}

/// Keeps key events of a text field inside the grid's widget tree away
/// from the grid (whose handlers would start cell editing or clear cells):
/// text-editing shortcuts, focus traversal and button activation are
/// handled here; everything else goes straight to the platform.
class IsolatedKeys extends StatelessWidget {
  const IsolatedKeys({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (node, e) => KeyEventResult.skipRemainingHandlers,
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
        SingleActivator(LogicalKeyboardKey.tab, shift: true):
            PreviousFocusIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: DefaultTextEditingShortcuts(child: child),
    ),
  );
}
