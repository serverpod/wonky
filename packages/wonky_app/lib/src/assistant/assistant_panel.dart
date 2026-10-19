import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../l10n/wonky_app_localizations.dart';
import '../shell/shell_services.dart';
import 'assistant_adapter.dart' show AssistantPanelTexts, AssistantRunHooks;
import 'assistant_controller.dart';
import 'assistant_markdown.dart';
import 'assistant_models.dart';
import 'shell_assistant.dart'
    show
        aiProviderName,
        assistantPrivacyNotice,
        assistantStatusMessage,
        openAiProviderSettings;

/// The assistant side panel (suite 10 §3): thread picker, streaming
/// Markdown replies with tool chips (Show / Undo), the composer with
/// context chips, Stop, quick prompts, the Edit directly / Suggest toggle
/// and the privacy notice.
class AssistantPanel extends StatefulWidget {
  const AssistantPanel({
    super.key,
    required this.services,
    required this.controller,
  });

  final ShellServices services;
  final AssistantController controller;

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  final _input = TextEditingController();
  final _focus = FocusNode(debugLabel: 'assistant.input');
  final _scroll = ScrollController();
  int _lastCount = 0;
  int _lastLength = 0;

  AssistantController get c => widget.controller;

  /// The app's texts ("this spreadsheet"), when its adapter has them.
  AssistantPanelTexts? get _texts {
    final a = c.adapter;
    return a is AssistantPanelTexts ? a as AssistantPanelTexts : null;
  }

  String _privacyNotice(WonkyAppLocalizations l) {
    final status = c.status.value;
    final p = status?.provider;
    return _texts?.privacyNotice(p == null ? null : aiProviderName(l, p)) ??
        assistantPrivacyNotice(l, status);
  }

  @override
  void initState() {
    super.initState();
    unawaited(c.ensureLoaded());
    c.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(AssistantPanel old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      unawaited(c.ensureLoaded());
    }
  }

  @override
  void dispose() {
    c.removeListener(_onChanged);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    final length = c.currentReply?.markdown.length ?? 0;
    if (c.entries.length != _lastCount || length != _lastLength) {
      _lastCount = c.entries.length;
      _lastLength = length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _send([String? text, bool includeComments = false]) async {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty || c.busy) return;
    if (text == null) _input.clear();
    await c.send(t, includeComments: includeComments);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final status = c.status.value;
        return Column(
          key: const ValueKey<String>('assistant.panel'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            if (status != null && !status.available)
              _unavailable(context, status),
            Expanded(child: _messages(context)),
            _composer(context, enabled: status?.available ?? false),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final current = c.threads.where((t) => t.id == c.threadId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: WonkyDropdownMenu(
              entries: () => [
                WonkyMenuItem(
                  label: l.assistantNewChat,
                  icon: LucideIcons.squarePen,
                  onSelected: () => unawaited(c.newThread()),
                ),
                if (c.threads.isNotEmpty) const WonkyMenuSeparator(),
                for (final t in c.threads)
                  WonkyMenuRadioItem(
                    label: t.title,
                    selected: t.id == c.threadId,
                    onSelected: () => unawaited(c.selectThread(t.id)),
                  ),
              ],
              builder: (context, ctl) => ShadButton.ghost(
                key: const ValueKey<String>('assistant.threadPicker'),
                mainAxisAlignment: MainAxisAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                trailing: const Icon(LucideIcons.chevronDown, size: 14),
                onPressed: ctl.toggle,
                child: Flexible(
                  child: Text(
                    current?.title ?? l.assistantNewChat,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small,
                  ),
                ),
              ),
            ),
          ),
          ShadTooltip(
            builder: (_) => Text(l.assistantNewChat),
            child: ShadIconButton.ghost(
              key: const ValueKey<String>('assistant.newThread'),
              width: 30,
              height: 30,
              iconSize: 16,
              semanticLabel: l.assistantNewChat,
              icon: const Icon(LucideIcons.squarePen),
              onPressed: () => unawaited(c.newThread()),
            ),
          ),
          WonkyDropdownMenu(
            entries: () => [
              WonkyMenuItem(
                label: l.assistantClearChat,
                icon: LucideIcons.eraser,
                onSelected: () => unawaited(c.newThread()),
              ),
              WonkyMenuItem(
                label: l.assistantDeleteChat,
                icon: LucideIcons.trash2,
                onSelected: () => unawaited(_delete(context)),
              ),
              const WonkyMenuSeparator(),
              WonkyMenuItem(
                label: l.assistantAiSettings,
                icon: LucideIcons.settings,
                onSelected: () => widget.services.router.go('/settings/ai'),
              ),
            ],
            builder: (context, ctl) => ShadTooltip(
              builder: (_) => Text(l.moreActions),
              child: ShadIconButton.ghost(
                key: const ValueKey<String>('assistant.more'),
                width: 30,
                height: 30,
                iconSize: 16,
                semanticLabel: l.moreActions,
                icon: const Icon(LucideIcons.ellipsisVertical),
                onPressed: ctl.toggle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final failed = WonkyAppLocalizations.of(context).assistantDeleteChatFailed;
    try {
      await c.deleteThread();
    } on Object {
      widget.services.toasts.error(failed);
    }
  }

  Widget _unavailable(BuildContext context, AssistantStatus status) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final optedOut = status.reason == 'optedOut';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ShadAlert(
        key: const ValueKey<String>('assistant.unavailable'),
        icon: const Icon(LucideIcons.sparkles),
        title: Text(
          assistantStatusMessage(l, status),
          style: theme.textTheme.small,
        ),
        description: optedOut
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: () => widget.services.router.go('/settings/ai'),
                  child: Text(l.assistantOpenAiSettings),
                ),
              )
            : status.reason == 'notConfigured'
            ? _notConfigured(context, status)
            : null,
      ),
    );
  }

  /// AI isn't configured: when the server has no key, the user can add
  /// their own in Settings › AI providers.
  Widget _notConfigured(BuildContext context, AssistantStatus status) {
    final l = WonkyAppLocalizations.of(context);
    if (!status.userKeysAllowed) return Text(l.aiNotConfiguredAdminHint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.aiNotConfiguredHint),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ShadButton.outline(
            key: const ValueKey<String>('assistant.addApiKey'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.keyRound, size: 13),
            onPressed: () => openAiProviderSettings(widget.services, context),
            child: Text(l.aiAddApiKey),
          ),
        ),
      ],
    );
  }

  Widget _messages(BuildContext context) {
    if (c.loading && c.entries.isEmpty) {
      return const Center(child: ShadSpinner());
    }
    if (c.entries.isEmpty) return _empty(context);
    // Built lazily: a streamed delta rebuilds the visible entries only,
    // not the whole conversation (review M-2).
    final entries = c.entries;
    final error = c.loadError;
    final offset = error == null ? 0 : 1;
    return ListView.builder(
      key: const ValueKey<String>('assistant.messages'),
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: entries.length + offset,
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        final i = entries.indexWhere(
          (e) => key.value == 'assistant.entry.${e.key}',
        );
        return i < 0 ? null : i + offset;
      },
      itemBuilder: (context, i) {
        if (i < offset) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error!, style: ShadTheme.of(context).textTheme.muted),
          );
        }
        final e = entries[i - offset];
        return Padding(
          key: ValueKey<String>('assistant.entry.${e.key}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: switch (e) {
            AssistantUserEntry() => _UserBubble(text: e.text),
            AssistantReplyEntry() => _ReplyView(controller: c, reply: e),
            AssistantResultEntry() => _ResultView(controller: c, result: e),
          },
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      children: [
        Icon(LucideIcons.sparkles, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 10),
        Text(
          _texts?.emptyTitle ?? l.assistantEmptyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.small,
        ),
        const SizedBox(height: 4),
        Text(
          l.assistantEmptyBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.muted.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _composer(BuildContext context, {required bool enabled}) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final cs = theme.colorScheme;
    final chips = c.chips;
    final prompts = c.adapter.quickPrompts;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.border)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          if (prompts.isNotEmpty && !c.busy)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in prompts)
                  ShadButton.outline(
                    key: ValueKey<String>('assistant.quick.${p.label}'),
                    size: ShadButtonSize.sm,
                    enabled: enabled,
                    leading: p.icon == null ? null : Icon(p.icon, size: 13),
                    onPressed: () =>
                        unawaited(_send(p.prompt, p.includeComments)),
                    child: Text(p.label),
                  ),
              ],
            ),
          if (chips.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final chip in chips)
                  _Chip(
                    key: ValueKey<String>('assistant.chip.${chip.id}'),
                    chip: chip,
                    onRemove: () => c.removeChip(chip.id),
                  ),
              ],
            ),
          CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): () =>
                  unawaited(_send()),
              const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                  unawaited(_send()),
            },
            child: ShadInput(
              key: const ValueKey<String>('assistant.input'),
              controller: _input,
              focusNode: _focus,
              enabled: enabled,
              minLines: 2,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              placeholder: Text(l.assistantPlaceholder),
            ),
          ),
          LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                // Icon-only mode buttons when the panel is narrow (300 px).
                _ModeToggle(
                  controller: c,
                  texts: _texts,
                  compact: box.maxWidth < 330,
                ),
                const Spacer(),
                if (c.busy)
                  ShadButton.outline(
                    key: const ValueKey<String>('assistant.stop'),
                    size: ShadButtonSize.sm,
                    leading: const Icon(LucideIcons.square, size: 12),
                    onPressed: () => unawaited(c.stop()),
                    child: Text(l.actionStop),
                  )
                else
                  ShadButton(
                    key: const ValueKey<String>('assistant.send'),
                    size: ShadButtonSize.sm,
                    enabled: enabled,
                    leading: const Icon(LucideIcons.sendHorizontal, size: 13),
                    onPressed: () => unawaited(_send()),
                    child: Text(l.actionSend),
                  ),
              ],
            ),
          ),
          Text(
            _privacyNotice(l),
            key: const ValueKey<String>('assistant.notice'),
            style: theme.textTheme.muted.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.controller,
    this.texts,
    this.compact = false,
  });

  final AssistantController controller;
  final AssistantPanelTexts? texts;

  /// Icons only (the labels are the tooltips' first words).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = WonkyAppLocalizations.of(context);
    Widget option(AiApplyMode mode, String label, IconData icon, String tip) {
      final selected = c.applyMode == mode;
      final enabled = mode == AiApplyMode.suggest || c.canEditDirectly;
      final key = ValueKey<String>('assistant.mode.${mode.name}');
      final Widget button;
      if (compact) {
        button = selected
            ? ShadIconButton.secondary(
                key: key,
                width: 30,
                height: 30,
                iconSize: 14,
                semanticLabel: label,
                icon: Icon(icon),
                onPressed: () {},
              )
            : ShadIconButton.ghost(
                key: key,
                width: 30,
                height: 30,
                iconSize: 14,
                enabled: enabled,
                semanticLabel: label,
                icon: Icon(icon),
                onPressed: () => c.setApplyMode(mode),
              );
      } else {
        button = selected
            ? ShadButton.secondary(
                key: key,
                size: ShadButtonSize.sm,
                leading: Icon(icon, size: 13),
                onPressed: () {},
                child: Text(label),
              )
            : ShadButton.ghost(
                key: key,
                size: ShadButtonSize.sm,
                enabled: enabled,
                leading: Icon(icon, size: 13),
                onPressed: () => c.setApplyMode(mode),
                child: Text(label),
              );
      }
      return ShadTooltip(builder: (_) => Text(tip), child: button);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        option(
          AiApplyMode.edit,
          l.assistantModeEdit,
          LucideIcons.pencil,
          c.canEditDirectly
              ? texts?.modeEditHint ?? l.assistantModeEditHint
              : texts?.modeEditUnavailable ?? l.assistantModeEditUnavailable,
        ),
        option(
          AiApplyMode.suggest,
          l.assistantModeSuggest,
          LucideIcons.gitPullRequestArrow,
          texts?.modeSuggestHint ?? l.assistantModeSuggestHint,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.chip, required this.onRemove});

  final AssistantContextChip chip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 2, 2),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon ?? LucideIcons.textSelect, size: 12),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              chip.label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.small.copyWith(fontSize: 12),
            ),
          ),
          ShadIconButton.ghost(
            key: ValueKey<String>('assistant.chip.${chip.id}.remove'),
            width: 20,
            height: 20,
            iconSize: 11,
            semanticLabel: WonkyAppLocalizations.of(
              context,
            ).assistantRemoveChip(chip.label),
            icon: const Icon(LucideIcons.x),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: cs.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text, style: theme.textTheme.small),
        ),
      ),
    );
  }
}

class _ReplyView extends StatelessWidget {
  const _ReplyView({required this.controller, required this.reply});

  final AssistantController controller;
  final AssistantReplyEntry reply;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = WonkyAppLocalizations.of(context);
    final r = reply;
    final md = r.markdown.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        if (r.activities.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in r.activities)
                _ActivityChip(controller: controller, reply: r, activity: a),
            ],
          ),
        if (md.isNotEmpty) AssistantMarkdown(md),
        if (r.streaming && md.isEmpty && r.activities.every((a) => !a.running))
          Row(
            children: [
              const SizedBox(width: 14, height: 14, child: ShadSpinner()),
              const SizedBox(width: 8),
              Text(
                r.progress ?? l.assistantThinking,
                style: theme.textTheme.muted,
              ),
            ],
          )
        else if (r.streaming && r.progress != null)
          Text(
            r.progress!,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        if (r.confirmation != null) _confirmation(context, r.confirmation!),
        ?_footer(context),
        if (r.status == AssistantReplyStatus.refused)
          _note(
            context,
            LucideIcons.ban,
            r.error == null || r.error == AssistantController.refusalText
                ? l.assistantRefused
                : r.error!,
          ),
        if (r.status == AssistantReplyStatus.failed)
          _note(context, LucideIcons.circleAlert, r.error ?? l.assistantFailed),
        if (r.status == AssistantReplyStatus.stopped)
          _note(context, LucideIcons.square, l.assistantStopped),
        if (r.status == AssistantReplyStatus.cutOff)
          Align(
            alignment: Alignment.centerLeft,
            child: ShadButton.outline(
              key: const ValueKey<String>('assistant.continue'),
              size: ShadButtonSize.sm,
              enabled: !controller.busy,
              onPressed: () => unawaited(controller.continueAnswer()),
              child: Text(l.assistantContinue),
            ),
          ),
        if (!r.streaming && r.hasChanges)
          Wrap(
            children: [
              ShadButton.ghost(
                key: const ValueKey<String>('assistant.reply.undo'),
                size: ShadButtonSize.sm,
                enabled: !r.undone,
                leading: const Icon(LucideIcons.undo2, size: 13),
                onPressed: () => unawaited(controller.undoReply(r)),
                child: Text(
                  r.undone ? l.assistantUndone : l.assistantUndoChanges,
                ),
              ),
              if (md.isNotEmpty)
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  leading: const Icon(LucideIcons.copy, size: 13),
                  onPressed: () => Clipboard.setData(ClipboardData(text: md)),
                  child: Text(l.actionCopy),
                ),
            ],
          )
        else if (!r.streaming && md.isNotEmpty)
          Wrap(
            children: [
              ShadButton.ghost(
                key: const ValueKey<String>('assistant.reply.insert'),
                size: ShadButtonSize.sm,
                enabled: controller.adapter.role.canComment,
                leading: const Icon(LucideIcons.textCursorInput, size: 13),
                onPressed: () =>
                    unawaited(controller.adapter.insertMarkdown(md)),
                child: Text(l.assistantInsertAtCursor),
              ),
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.copy, size: 13),
                onPressed: () => Clipboard.setData(ClipboardData(text: md)),
                child: Text(l.actionCopy),
              ),
            ],
          ),
        if (r.streaming)
          Container(height: 1, color: cs.border.withValues(alpha: 0.5)),
      ],
    );
  }

  /// The app's widgets under the reply (Sheets: review the AI changes).
  Widget? _footer(BuildContext context) {
    final a = controller.adapter;
    return a is AssistantRunHooks
        ? (a as AssistantRunHooks).replyFooter(context, reply)
        : null;
  }

  Widget _note(BuildContext context, IconData icon, String text) {
    final theme = ShadTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: theme.textTheme.muted)),
      ],
    );
  }

  Widget _confirmation(BuildContext context, AssistantConfirmation conf) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    return ShadCard(
      key: const ValueKey<String>('assistant.confirmation'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(conf.summary, style: theme.textTheme.small),
          Row(
            spacing: 6,
            children: [
              ShadButton.destructive(
                key: const ValueKey<String>('assistant.confirm.allow'),
                size: ShadButtonSize.sm,
                onPressed: () => unawaited(controller.confirm(true)),
                child: Text(l.assistantAllow),
              ),
              ShadButton.outline(
                key: const ValueKey<String>('assistant.confirm.deny'),
                size: ShadButtonSize.sm,
                onPressed: () => unawaited(controller.confirm(false)),
                child: Text(l.assistantDeny),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.controller,
    required this.reply,
    required this.activity,
  });

  final AssistantController controller;
  final AssistantReplyEntry reply;
  final AssistantActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = WonkyAppLocalizations.of(context);
    final a = activity;
    return Container(
      key: ValueKey<String>('assistant.activity.${a.toolUseId}'),
      padding: const EdgeInsets.fromLTRB(8, 3, 3, 3),
      decoration: BoxDecoration(
        border: Border.all(color: a.error ? cs.destructive : cs.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (a.running)
            const SizedBox(width: 12, height: 12, child: ShadSpinner())
          else
            Icon(
              a.error
                  ? LucideIcons.circleAlert
                  : a.changed
                  ? LucideIcons.pencilLine
                  : LucideIcons.eye,
              size: 12,
              color: a.error ? cs.destructive : cs.mutedForeground,
            ),
          const SizedBox(width: 6),
          // Shrinks (ellipsis) before the chip outgrows a narrow panel.
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                a.summary.isEmpty ? a.toolName : a.summary,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: theme.textTheme.small.copyWith(fontSize: 12),
              ),
            ),
          ),
          if (a.hasRange && !a.running)
            ShadButton.link(
              key: const ValueKey<String>('assistant.activity.show'),
              size: ShadButtonSize.sm,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () => controller.show(a),
              child: Text(l.assistantShow),
            ),
          if (a.changed && !a.running)
            ShadButton.link(
              key: const ValueKey<String>('assistant.activity.undo'),
              size: ShadButtonSize.sm,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              enabled: !reply.undone && !reply.streaming,
              onPressed: () => unawaited(controller.undoReply(reply)),
              child: Text(l.actionUndo),
            )
          else
            const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.controller, required this.result});

  final AssistantController controller;
  final AssistantResultEntry result;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final r = result;
    final md = r.markdown.trim();
    final streaming = r.status == AssistantReplyStatus.streaming;
    return ShadCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 13,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(r.title, style: theme.textTheme.small)),
              if (streaming)
                const SizedBox(width: 12, height: 12, child: ShadSpinner()),
              ShadIconButton.ghost(
                width: 24,
                height: 24,
                iconSize: 12,
                semanticLabel: WonkyAppLocalizations.of(context).actionClose,
                icon: const Icon(LucideIcons.x),
                onPressed: () => controller.removeEntry(r),
              ),
            ],
          ),
          if (r.builder != null)
            r.builder!(context)
          else if (md.isNotEmpty)
            AssistantMarkdown(md),
          if (r.error != null) Text(r.error!, style: theme.textTheme.muted),
          if (r.status == AssistantReplyStatus.done &&
              md.isNotEmpty &&
              r.actions.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in r.actions)
                  ShadButton.outline(
                    key: a.id == null
                        ? null
                        : ValueKey<String>('assistant.result.${a.id}'),
                    size: ShadButtonSize.sm,
                    leading: a.icon == null ? null : Icon(a.icon, size: 13),
                    onPressed: () => a.onPressed(md),
                    child: Text(a.label),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
