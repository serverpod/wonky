import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart';

import '../data/api.dart';
import '../drive/drive_format.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/shell_services.dart';
import '../markdown/markdown_composer.dart';
import '../markdown/wonky_markdown.dart';
import 'comment_anchor.dart';
import 'comment_thread_actions.dart';
import 'comments_controller.dart';

/// The comments side panel (suite 07 §2.3): filters, search, sort, the
/// composer for a new comment and thread cards. Every action is a
/// `shell.comments.*` command (undoable).
class CommentsPanel extends StatelessWidget {
  const CommentsPanel({
    super.key,
    required this.services,
    required this.controller,
  });

  final ShellServices services;
  final CommentsController controller;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final threads = c.visible;
        final canComment =
            services.activeDocument.value?.role.canComment ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: CommentsFilterTabs(controller: c)),
                      const SizedBox(width: 6),
                      WonkyDropdownMenu(
                        entries: () => [
                          WonkyMenuRadioItem(
                            label: l.commentsSortPosition,
                            selected: c.sort == CommentsSort.position,
                            onSelected: () => c.setSort(CommentsSort.position),
                          ),
                          WonkyMenuRadioItem(
                            label: l.commentsSortDate,
                            selected: c.sort == CommentsSort.date,
                            onSelected: () => c.setSort(CommentsSort.date),
                          ),
                        ],
                        builder: (context, ctl) => ShadIconButton.outline(
                          semanticLabel: l.commentsSort,
                          icon: const Icon(LucideIcons.arrowDownUp, size: 14),
                          onPressed: ctl.toggle,
                        ),
                      ),
                    ],
                  ),
                  if (c.scope != null) ...[
                    const SizedBox(height: 6),
                    _ScopeTabs(controller: c),
                  ],
                ],
              ),
            ),
            Expanded(
              child: c.loading
                  ? const Center(child: ShadSpinner())
                  : _LazyList(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      children: [
                        if (c.draftAnchor != null && canComment)
                          (context) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NewCommentCard(
                              services: services,
                              controller: c,
                            ),
                          ),
                        if (threads.isEmpty && c.draftAnchor == null)
                          (context) => WonkyEmptyState(
                            illustration: EmptyIllustration.comments,
                            title: l.commentsEmptyTitle,
                            description: canComment
                                ? l.commentsEmptyBody(
                                    services.keymap.shortcutTextOf(
                                          'shell.comments.create',
                                        ) ??
                                        '',
                                  )
                                : null,
                            size: 80,
                          ),
                        for (final (i, t) in threads.indexed) ...[
                          if (_section(c, threads, i) case final sec?)
                            (context) => Padding(
                              key: ValueKey<String>(
                                'comments.section.${sec.id}',
                              ),
                              padding: EdgeInsets.only(
                                top: i == 0 ? 0 : 10,
                                bottom: 4,
                              ),
                              child: Row(
                                children: [
                                  if (sec.leading case final leading?) ...[
                                    leading(context),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      sec.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.small.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_header(c, threads, i) case final h?)
                            (context) => Padding(
                              key: ValueKey<String>('comments.group.$h'),
                              padding: EdgeInsets.only(
                                top: i == 0 ? 0 : 6,
                                bottom: 6,
                              ),
                              child: Text(
                                h,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.small.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ),
                          (context) => Padding(
                            key: ValueKey<String>(
                              'comments.card.${t.uuid.uuid}',
                            ),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CommentThreadCard(
                              key: ValueKey<String>(
                                'comments.thread.${t.uuid.uuid}',
                              ),
                              services: services,
                              controller: c,
                              thread: t,
                            ),
                          ),
                        ],
                        if (c.error != null)
                          (context) => Text(
                            errorMessage(c.error!),
                            style: theme.textTheme.muted,
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// A list whose children are built lazily (long comment lists cost only
/// their visible cards per notification, review M-2).
class _LazyList extends StatelessWidget {
  const _LazyList({required this.padding, required this.children});

  final EdgeInsetsGeometry padding;
  final List<WidgetBuilder> children;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: padding,
    itemCount: children.length,
    itemBuilder: (context, i) => children[i](context),
  );
}

/// The group header before `threads[i]` in the position sort (the app's
/// [CommentPanelOptions.groupOf], e.g. the sheet name), when it starts a
/// new group.
String? _header(CommentsController c, List<CommentThreadView> threads, int i) {
  final a = commentPanelOptionsOf(c.anchors);
  if (a == null || c.sort != CommentsSort.position) return null;
  final g = a.groupOf(threads[i]);
  if (g == null) return null;
  return i > 0 && a.groupOf(threads[i - 1]) == g ? null : g;
}

/// The section header before `threads[i]` in the position sort
/// ([CommentPanelOptions.sectionOf], Slides: the slide group), when it
/// starts a new section.
CommentPanelSection? _section(
  CommentsController c,
  List<CommentThreadView> threads,
  int i,
) {
  final a = c.anchors;
  if (a is! CommentPanelSections || c.sort != CommentsSort.position) {
    return null;
  }
  final sections = a as CommentPanelSections;
  final s = sections.sectionOf(threads[i]);
  if (s == null) return null;
  return i > 0 && sections.sectionOf(threads[i - 1])?.id == s.id ? null : s;
}

/// The app's scope filter of the comments panel (Sheets: This sheet / All
/// sheets).
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.controller});

  final CommentsController controller;

  @override
  Widget build(BuildContext context) {
    final scopes =
        commentPanelOptionsOf(controller.anchors)?.scopes ??
        const <String, String>{};
    return ShadTabs<String>(
      value: controller.scope,
      onChanged: controller.setScope,
      tabs: [
        for (final e in scopes.entries)
          ShadTab(
            key: ValueKey<String>('comments.scope.${e.key}'),
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

/// The Open / For you filter of the comments (suite 07 §2.3), shared by the
/// comments panel and Write's comment margin.
class CommentsFilterTabs extends StatelessWidget {
  const CommentsFilterTabs({super.key, required this.controller});

  final CommentsController controller;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return ShadTabs<CommentsFilter>(
      value: controller.filter,
      onChanged: controller.setFilter,
      tabs: [
        for (final f in CommentsFilter.values)
          ShadTab(
            key: ValueKey<String>('comments.filter.${f.name}'),
            value: f,
            child: Text(switch (f) {
              CommentsFilter.open => l.commentsOpen,
              CommentsFilter.forYou => l.commentsForYou,
            }),
          ),
      ],
    );
  }
}

class MentionField extends StatefulWidget {
  const MentionField({
    super.key,
    required this.services,
    required this.controller,
    required this.onSubmit,
    this.placeholder,
    this.autofocus = false,
    this.onMentionsChanged,
    this.fieldKey,
  });

  final ShellServices services;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? placeholder;
  final bool autofocus;
  final ValueChanged<List<UserSummary>>? onMentionsChanged;
  final String? fieldKey;

  @override
  State<MentionField> createState() => MentionFieldState();
}

class MentionFieldState extends State<MentionField> {
  final List<UserSummary> mentions = [];
  List<UserSummary> _suggestions = const [];
  int _active = 0;
  Timer? _debounce;
  String? _query;
  final _focus = FocusNode(debugLabel: 'MentionField');

  @override
  void initState() {
    super.initState();
    // `autofocus` only focuses when nothing in the focus scope is focused;
    // a reply box opened inside a focused card (Slides' docked comment
    // card) stayed unfocused and the first keystrokes went nowhere.
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focus.hasFocus) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    super.dispose();
  }

  String? _mentionQuery() {
    final t = widget.controller.text;
    final sel = widget.controller.selection.baseOffset;
    if (sel < 0 || sel > t.length) return null;
    final before = t.substring(0, sel);
    final m = RegExp(r'(?:^|\s)@([^\s@]*)$').firstMatch(before);
    return m?.group(1);
  }

  void _onChanged(String _) {
    final q = _mentionQuery();
    _query = q;
    _debounce?.cancel();
    if (q == null) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      try {
        final r = await widget.services.repositories.users.searchUsers(
          q.isEmpty ? '' : q,
          limit: 6,
        );
        if (mounted && _query == q) {
          setState(() {
            _suggestions = r;
            _active = 0;
          });
        }
      } catch (_) {}
    });
  }

  void _pick(UserSummary u) {
    final c = widget.controller;
    final sel = c.selection.baseOffset;
    final before = c.text.substring(0, sel);
    final start = before.lastIndexOf('@');
    final insert = '@${u.displayName} ';
    c.value = TextEditingValue(
      text: c.text.replaceRange(start, sel, insert),
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    if (!mentions.any((m) => m.id == u.id)) mentions.add(u);
    widget.onMentionsChanged?.call(mentions);
    setState(() => _suggestions = const []);
  }

  /// Mentions still present in the text.
  List<int> get mentionIds => [
    for (final m in mentions)
      if (widget.controller.text.contains('@${m.displayName}')) m.id,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                widget.onSubmit,
            const SingleActivator(LogicalKeyboardKey.enter, control: true):
                widget.onSubmit,
            if (_suggestions.isNotEmpty) ...{
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  setState(() => _active = (_active + 1) % _suggestions.length),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () => setState(
                () => _active =
                    (_active - 1 + _suggestions.length) % _suggestions.length,
              ),
              const SingleActivator(LogicalKeyboardKey.enter): () =>
                  _pick(_suggestions[_active]),
              const SingleActivator(LogicalKeyboardKey.tab): () =>
                  _pick(_suggestions[_active]),
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  setState(() => _suggestions = const []),
            },
          },
          child: ShadTextarea(
            key: widget.fieldKey == null
                ? null
                : ValueKey<String>(widget.fieldKey!),
            controller: widget.controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            minHeight: 56,
            maxHeight: 200,
            placeholder: widget.placeholder == null
                ? null
                : Text(widget.placeholder!),
            onChanged: _onChanged,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.popover,
              border: Border.all(color: theme.colorScheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _suggestions.length; i++)
                  GestureDetector(
                    onTap: () => _pick(_suggestions[i]),
                    child: Container(
                      color: i == _active ? theme.colorScheme.accent : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          WonkyAvatar(
                            name: _suggestions[i].displayName,
                            color: parseHexColor(_suggestions[i].avatarColor),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_suggestions[i].displayName} · ${_suggestions[i].email}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The composer for a new thread at the draft anchor.
class NewCommentCard extends StatefulWidget {
  const NewCommentCard({
    super.key,
    required this.services,
    required this.controller,
  });

  final ShellServices services;
  final CommentsController controller;

  @override
  State<NewCommentCard> createState() => _NewCommentCardState();
}

class _NewCommentCardState extends State<NewCommentCard> {
  final _text = TextEditingController();
  final _field = GlobalKey<MentionFieldState>();
  bool _assign = false;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _text.text.trim();
    final anchor = widget.controller.draftAnchor;
    if (body.isEmpty || anchor == null) return;
    setState(() => _busy = true);
    final mentions = _field.currentState?.mentionIds ?? const <int>[];
    try {
      await widget.services.dispatcher.invoke(
        'shell.comments.create',
        args: {
          'body': body,
          'anchorKind': anchor.kind.name,
          'anchorJson': anchor.anchorJson,
          'quotedText': ?anchor.quotedText,
          'mentions': mentions,
          if (_assign && mentions.isNotEmpty) 'assigneeId': mentions.first,
        },
        source: InvocationSource.ui,
      );
      _text.clear();
    } catch (e) {
      widget.services.toasts.error(
        widget.services.l10n?.commentFailed ?? 'Error',
        description: errorMessage(e),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    // The draft can end (posted, cancelled) before a host stops showing
    // this card.
    final anchor = widget.controller.draftAnchor;
    if (anchor == null) return const SizedBox.shrink();
    final me = widget.services.me;
    return ShadCard(
      key: const ValueKey<String>('comments.new'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (me != null)
                WonkyAvatar(
                  name: me.displayName,
                  color: parseHexColor(me.avatarColor),
                  imageUrl: me.avatarUrl,
                  size: 24,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  me?.displayName ?? '',
                  style: theme.textTheme.small,
                ),
              ),
            ],
          ),
          if (anchor.quotedText != null || anchor.label != null) ...[
            const SizedBox(height: 8),
            _Quote(text: anchor.label ?? anchor.quotedText!),
          ],
          const SizedBox(height: 8),
          MentionField(
            key: _field,
            fieldKey: 'comments.new.body',
            services: widget.services,
            controller: _text,
            autofocus: true,
            placeholder: l.commentPlaceholder,
            onSubmit: _submit,
            onMentionsChanged: (_) => setState(() {}),
          ),
          if ((_field.currentState?.mentions.isNotEmpty ?? false)) ...[
            const SizedBox(height: 6),
            ShadCheckbox(
              value: _assign,
              onChanged: (v) => setState(() => _assign = v),
              label: Text(
                l.commentAssign(
                  _field.currentState!.mentions.first.displayName,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: widget.controller.cancelDraft,
                child: Text(l.actionCancel),
              ),
              const SizedBox(width: 6),
              ShadButton(
                key: const ValueKey<String>('comments.new.submit'),
                size: ShadButtonSize.sm,
                enabled: !_busy,
                onPressed: _submit,
                child: Text(l.commentAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.commentHighlightActive,
            width: 3,
          ),
        ),
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.muted.copyWith(fontSize: 12),
      ),
    );
  }
}

/// A thread: comments, reply box, resolve/reopen, ⋮ menu.
class CommentThreadCard extends StatefulWidget {
  const CommentThreadCard({
    super.key,
    required this.services,
    required this.controller,
    required this.thread,
    this.onTap,
  });

  final ShellServices services;
  final CommentsController controller;
  final CommentThreadView thread;

  /// Replaces the default tap (`shell.comments.activate`, which also opens
  /// the comments panel) — e.g. a document margin activates in place.
  final VoidCallback? onTap;

  @override
  State<CommentThreadCard> createState() => _CommentThreadCardState();
}

class _CommentThreadCardState extends State<CommentThreadCard> {
  bool _expanded = false;

  ShellServices get s => widget.services;

  Future<void> _invoke(String id, Map<String, Object?> args) async {
    try {
      await s.dispatcher.invoke(id, args: args, source: InvocationSource.ui);
    } catch (e) {
      s.toasts.error(
        s.l10n?.commentFailed ?? 'Error',
        description: errorMessage(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final t = widget.thread;
    final c = widget.controller;
    final active = c.activeThreadUuid == t.uuid.uuid;
    final resolved = t.status == CommentStatus.resolved;
    final orphaned = t.status == CommentStatus.orphaned;
    final collapsed = resolved && !_expanded && !active;
    final label = c.anchors?.labelFor(t) ?? t.quotedText;
    return GestureDetector(
      onTap:
          widget.onTap ??
          () => _invoke('shell.comments.activate', {'threadUuid': t.uuid.uuid}),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? theme.colorScheme.ring : theme.colorScheme.border,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x1a000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null && label.isNotEmpty) ...[
              _Quote(text: label),
              const SizedBox(height: 8),
            ],
            if (orphaned) ...[
              ShadBadge.outline(child: Text(l.commentOrphaned)),
              const SizedBox(height: 6),
            ],
            if (c.isPending(t.uuid.uuid)) ...[
              Row(
                key: const ValueKey<String>('comments.pending'),
                children: [
                  Icon(
                    LucideIcons.cloudOff,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.commentPending,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (collapsed)
              Row(
                children: [
                  Icon(
                    LucideIcons.circleCheck,
                    size: 14,
                    color: theme.colorScheme.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.comments.firstOrNull?.body ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted,
                    ),
                  ),
                  ShadButton.link(
                    size: ShadButtonSize.sm,
                    onPressed: () => setState(() => _expanded = true),
                    child: Text(l.commentShow),
                  ),
                ],
              )
            else
              CommentThreadBody(services: s, controller: c, thread: t),
          ],
        ),
      ),
    );
  }
}

/// The comments of a thread and its reply box (shared by
/// [CommentThreadCard], app cards such as Write's suggestion cards, whose
/// replies are comments in the suggestion's thread, and the board).
///
/// The default constructor renders a document thread with
/// [DocumentCommentThreadActions] (`shell.comments.*`);
/// [CommentThreadBody.custom] renders [comments] whose actions go to
/// [actions] (specs/16 §7.3). Bodies render as Markdown
/// ([MarkdownProfile.comment]).
class CommentThreadBody extends StatefulWidget {
  const CommentThreadBody({
    super.key,
    required this.services,
    required CommentsController this.controller,
    required CommentThreadView this.thread,
    this.canResolve = true,
  }) : actions = null,
       comments = null;

  /// A thread whose comments and actions come from elsewhere (the board).
  const CommentThreadBody.custom({
    super.key,
    required this.services,
    required CommentThreadActions this.actions,
    required List<ThreadComment> this.comments,
  }) : controller = null,
       thread = null,
       canResolve = false;

  final ShellServices services;
  final CommentsController? controller;
  final CommentThreadView? thread;

  /// Whether the first comment offers Resolve / Reopen (document threads).
  final bool canResolve;

  /// The actions of a [CommentThreadBody.custom] thread.
  final CommentThreadActions? actions;

  /// The comments of a [CommentThreadBody.custom] thread, oldest first.
  final List<ThreadComment>? comments;

  @override
  State<CommentThreadBody> createState() => _CommentThreadBodyState();
}

class _CommentThreadBodyState extends State<CommentThreadBody> {
  final _reply = TextEditingController();
  final _field = GlobalKey<MentionFieldState>();
  bool _replying = false;
  String? _editing;
  final _edit = TextEditingController();

  ShellServices get s => widget.services;

  CommentThreadActions get _actions =>
      widget.actions ??
      DocumentCommentThreadActions(
        services: s,
        controller: widget.controller!,
        thread: widget.thread!,
        resolvable: widget.canResolve,
      );

  @override
  void dispose() {
    _reply.dispose();
    _edit.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      s.toasts.error(
        s.l10n?.commentFailed ?? 'Error',
        description: errorMessage(e),
      );
    }
  }

  Future<void> _sendReply(CommentThreadActions a) async {
    final body = _reply.text.trim();
    if (body.isEmpty) return;
    final mentions = _field.currentState?.mentionIds ?? const <int>[];
    await _run(() => a.reply(body, mentions: mentions));
    _reply.clear();
    if (mounted) setState(() => _replying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final a = _actions;
    final comments =
        widget.comments ??
        [
          for (final cm in widget.thread!.comments)
            ThreadComment.fromCommentView(cm, l),
        ];
    final p = a.keyPrefix;
    final id = a.threadId;
    final hint =
        a.replyHint(l) ?? (a.mentions ? l.replyPlaceholder : l.cmdReply);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < comments.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _commentRow(context, a, comments[i], first: i == 0),
        ],
        if (comments.isNotEmpty) const SizedBox(height: 10),
        if (a.canReply)
          _replying
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (a.mentions)
                      MentionField(
                        key: _field,
                        fieldKey: '$p.reply.$id',
                        services: s,
                        controller: _reply,
                        autofocus: true,
                        placeholder: hint,
                        onSubmit: () => _sendReply(a),
                      )
                    else
                      MarkdownComposer(
                        fieldKey: '$p.reply.$id',
                        controller: _reply,
                        autofocus: true,
                        hint: hint,
                        minLines: 2,
                        maxLines: 10,
                        maxLength: a.maxLength,
                        onSubmit: () => _sendReply(a),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ShadButton.ghost(
                          size: ShadButtonSize.sm,
                          onPressed: () => setState(() => _replying = false),
                          child: Text(l.actionCancel),
                        ),
                        const SizedBox(width: 6),
                        ShadButton(
                          key: ValueKey<String>('$p.reply.$id.send'),
                          size: ShadButtonSize.sm,
                          onPressed: () => _sendReply(a),
                          child: Text(l.cmdReply),
                        ),
                      ],
                    ),
                  ],
                )
              : Semantics(
                  button: true,
                  label: hint,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _replying = true),
                    child: FocusableActionDetector(
                      actions: {
                        ActivateIntent: CallbackAction<ActivateIntent>(
                          onInvoke: (_) {
                            setState(() => _replying = true);
                            return null;
                          },
                        ),
                      },
                      mouseCursor: SystemMouseCursors.text,
                      child: Container(
                        key: ValueKey<String>('$p.reply.$id.open'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        // The radius of the composer it opens (the
                        // suite's text inputs), not a pill.
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.input),
                          borderRadius: composerRadius(theme),
                        ),
                        child: Text(hint, style: theme.textTheme.muted),
                      ),
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _commentRow(
    BuildContext context,
    CommentThreadActions a,
    ThreadComment cm, {
    required bool first,
  }) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final p = a.keyPrefix;
    final system = cm.systemText;
    if (system != null) {
      return Text(
        system,
        key: ValueKey<String>('$p.event.${cm.id}'),
        style: theme.textTheme.muted.copyWith(fontSize: 12),
      );
    }
    final canEdit = !cm.deleted && a.canEdit(cm);
    final canDelete = !cm.deleted && a.canDelete(cm);
    final resolved = a.resolved;
    final copyLink = a.copyLink;
    final react = a.react;
    final selected = cm.deleted ? null : a.selected(cm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (selected != null) ...[
              Semantics(
                label: a.selectLabel(l, cm),
                child: ShadCheckbox(
                  key: ValueKey<String>('$p.comment.${cm.id}.select'),
                  value: selected,
                  onChanged: (v) => a.select(cm, v),
                ),
              ),
              const SizedBox(width: 10),
            ],
            WonkyAvatar(
              name: cm.authorName ?? '?',
              color: cm.authorColor == null
                  ? theme.colorScheme.muted
                  : parseHexColor(cm.authorColor!),
              imageUrl: cm.authorAvatarUrl,
              icon: cm.authorIsAgent ? LucideIcons.bot : null,
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cm.authorName ?? l.someone,
                          style: theme.textTheme.small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cm.authorBadge != null) ...[
                        const SizedBox(width: 6),
                        ShadBadge.secondary(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                          child: Text(
                            cm.authorBadge!,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${timeAgo(l, cm.createdAt)}${cm.editedAt != null ? ' · ${l.commentEdited}' : ''}',
                    style: theme.textTheme.muted.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (first && a.canResolve)
              ShadTooltip(
                builder: (_) => Text(resolved ? l.cmdReopen : l.cmdResolve),
                child: ShadIconButton.ghost(
                  key: ValueKey<String>(
                    '$p.thread.${a.threadId}.${resolved ? 'reopen' : 'resolve'}',
                  ),
                  width: 28,
                  height: 28,
                  iconSize: 16,
                  semanticLabel: resolved ? l.cmdReopen : l.cmdResolve,
                  icon: Icon(
                    resolved ? LucideIcons.rotateCcw : LucideIcons.check,
                  ),
                  onPressed: () => _run(() => a.setResolved(!resolved)),
                ),
              ),
            if (canEdit || canDelete)
              WonkyDropdownMenu(
                anchor: const ShadAnchor(
                  childAlignment: AlignmentDirectional.bottomEnd,
                  overlayAlignment: AlignmentDirectional.topEnd,
                ),
                entries: () => [
                  if (canEdit)
                    WonkyMenuItem(
                      label: l.commentEdit,
                      icon: LucideIcons.pencil,
                      onSelected: () => setState(() {
                        _editing = cm.id;
                        _edit.text = cm.body;
                      }),
                    ),
                  if (canDelete)
                    WonkyMenuItem(
                      label: a.deletesThread(cm)
                          ? l.commentDeleteThread
                          : l.commentDelete,
                      icon: LucideIcons.trash2,
                      destructive: true,
                      onSelected: () => _run(() => a.delete(cm)),
                    ),
                  if (copyLink != null)
                    WonkyMenuItem(
                      label: l.commentLink,
                      icon: LucideIcons.link,
                      onSelected: () => copyLink(cm),
                    ),
                ],
                builder: (context, ctl) => ShadIconButton.ghost(
                  key: ValueKey<String>('$p.comment.${cm.id}.menu'),
                  width: 28,
                  height: 28,
                  iconSize: 16,
                  semanticLabel: l.moreActions,
                  icon: const Icon(LucideIcons.ellipsisVertical),
                  onPressed: ctl.toggle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_editing == cm.id)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (a.mentions)
                ShadTextarea(controller: _edit, minHeight: 56)
              else
                MarkdownComposer(
                  fieldKey: '$p.comment.${cm.id}.edit',
                  controller: _edit,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 10,
                  maxLength: a.maxLength,
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: () => setState(() => _editing = null),
                    child: Text(l.actionCancel),
                  ),
                  ShadButton(
                    key: ValueKey<String>('$p.comment.${cm.id}.save'),
                    size: ShadButtonSize.sm,
                    onPressed: () async {
                      final body = _edit.text.trim();
                      setState(() => _editing = null);
                      if (body.isNotEmpty && body != cm.body) {
                        await _run(() => a.edit(cm, body));
                      }
                    },
                    child: Text(l.actionSave),
                  ),
                ],
              ),
            ],
          )
        else if (cm.deleted)
          Text(l.commentDeleted, style: theme.textTheme.muted)
        else
          WonkyMarkdown(
            cm.body,
            key: ValueKey<String>('$p.comment.${cm.id}.body'),
            profile: MarkdownProfile.comment,
            style: theme.textTheme.small.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
        if (react != null && !cm.deleted) _reactions(context, a, cm, react),
      ],
    );
  }

  static const _quickReactions = ['👍', '❤️', '🎉', '😄', '👀', '🚀'];

  Widget _reactions(
    BuildContext context,
    CommentThreadActions a,
    ThreadComment cm,
    Future<void> Function(ThreadComment c, String emoji) react,
  ) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final p = a.keyPrefix;
    final me = a.meId;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final e in cm.reactions.entries)
            if (e.value.isNotEmpty)
              Semantics(
                button: true,
                toggled: me != null && e.value.contains(me),
                label: l.commentReaction(e.key, e.value.length),
                excludeSemantics: true,
                child: ShadButton.outline(
                  key: ValueKey<String>(
                    '$p.comment.${cm.id}.reaction.${e.key}',
                  ),
                  size: ShadButtonSize.sm,
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: me != null && e.value.contains(me)
                      ? cs.accent
                      : null,
                  onPressed: () => _run(() => react(cm, e.key)),
                  child: Text('${e.key} ${e.value.length}'),
                ),
              ),
          WonkyDropdownMenu(
            entries: () => [
              for (final emoji in _quickReactions)
                WonkyMenuItem(
                  label: emoji,
                  onSelected: () => _run(() => react(cm, emoji)),
                ),
            ],
            builder: (context, ctl) => ShadIconButton.ghost(
              key: ValueKey<String>('$p.comment.${cm.id}.react'),
              width: 24,
              height: 24,
              iconSize: 14,
              semanticLabel: l.commentAddReaction,
              icon: const Icon(LucideIcons.smilePlus),
              onPressed: ctl.toggle,
            ),
          ),
        ],
      ),
    );
  }
}
