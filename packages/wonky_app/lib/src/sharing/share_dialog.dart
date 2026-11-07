import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../commands/shell_commands/drive_commands.dart';
import '../data/api.dart';
import '../drive/drive_format.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/dialogs.dart';
import '../shell/shell_services.dart';

/// The share dialog (suite 06 §5). Sharing changes are not undoable;
/// removing access and transferring ownership confirm.
Future<void> showShareDialog(
  BuildContext context,
  ShellServices s,
  DriveItemView item,
) => showShadDialog<void>(
  context: context,
  builder: (_) => ShareDialog(services: s, item: item),
);

String roleLabel(WonkyAppLocalizations l, AccessRole r) => switch (r) {
  AccessRole.viewer => l.roleViewer,
  AccessRole.commenter => l.roleCommenter,
  AccessRole.editor => l.roleEditor,
  AccessRole.owner => l.roleOwner,
};

class ShareDialog extends StatefulWidget {
  const ShareDialog({super.key, required this.services, required this.item});

  final ShellServices services;
  final DriveItemView item;

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  SharingInfo? _info;
  Object? _error;
  bool _busy = false;
  bool _settings = false;

  // Composer
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _message = TextEditingController();
  final List<String> _recipients = [];

  /// The people picked from suggestions, by email: their chips show the
  /// name and avatar (a typed address shows itself).
  final Map<String, UserSummary> _people = {};
  AccessRole _role = AccessRole.editor;
  bool _notify = true;
  List<UserSummary> _suggestions = const [];

  /// The last search found no one (the field then hints at full emails).
  bool _noMatches = false;
  Timer? _debounce;

  // The general access selects follow `_info` (also after a failed change).
  final _accessMode = ShadSelectController<GeneralAccess>();
  final _accessRole = ShadSelectController<AccessRole>();

  ShellServices get s => widget.services;

  /// Adding people (suite 06 §5): something is typed or picked. The dialog
  /// then shows only the composer, with *Cancel* and *Send*/*Share*.
  bool get _adding => _recipients.isNotEmpty || _input.text.trim().isNotEmpty;

  /// Whether *Send*/*Share* can share: a recipient, or a valid typed email
  /// that isn't a chip yet.
  bool get _canSend =>
      _recipients.isNotEmpty || _email.hasMatch(_input.text.trim());

  /// Leaves adding: drops the recipients, the typed text and the message.
  void _cancelAdding() {
    _debounce?.cancel();
    setState(() {
      _recipients.clear();
      _input.clear();
      _message.clear();
      _suggestions = const [];
      _noMatches = false;
    });
    _inputFocus.requestFocus();
  }

  /// Backspace in the empty input removes the last recipient chip whole.
  KeyEventResult _onInputKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace ||
        _input.text.isNotEmpty ||
        _recipients.isEmpty) {
      return KeyEventResult.ignored;
    }
    setState(() => _recipients.removeLast());
    return KeyEventResult.handled;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _message.dispose();
    _debounce?.cancel();
    _accessMode.dispose();
    _accessRole.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final info = await s.repositories.sharing.getSharing(widget.item.uuid);
      if (mounted) _setInfo(info);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _setInfo(SharingInfo info) {
    setState(() => _info = info);
    _syncLinkSelects();
  }

  /// Shows the general access and its role of `_info` in their selects.
  void _syncLinkSelects() {
    final info = _info;
    if (info == null) return;
    final mode = {info.generalAccess};
    if (!setEquals(_accessMode.value, mode)) _accessMode.value = mode;
    final role = _generalRole(info);
    if (role != null && !setEquals(_accessRole.value, {role})) {
      _accessRole.value = {role};
    }
  }

  /// The role of the organization or link access (null when restricted).
  static AccessRole? _generalRole(SharingInfo info) =>
      switch (info.generalAccess) {
        GeneralAccess.restricted => null,
        GeneralAccess.organization => info.orgAccess?.role,
        GeneralAccess.link => info.link?.role,
      };

  void _setGeneralAccess(GeneralAccess access, AccessRole? role) => _run(
    () =>
        s.repositories.sharing.setGeneralAccess(widget.item.uuid, access, role),
  );

  /// Runs a sharing change; false (after an error toast) when it failed.
  Future<bool> _run(Future<SharingInfo> Function() op) async {
    setState(() => _busy = true);
    try {
      final info = await op();
      if (mounted) _setInfo(info);
      return true;
    } catch (e) {
      // A select already shows the value that was not applied.
      if (mounted) _syncLinkSelects();
      s.toasts.error(
        s.l10n?.shareFailed ?? 'Error',
        description: errorMessage(e),
      );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onInput(String v) {
    if (v.endsWith(',') || v.endsWith(' ') || v.endsWith(';')) {
      _addRecipient(v.substring(0, v.length - 1));
      return;
    }
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = const [];
        _noMatches = false;
      });
      return;
    }
    // Adding mode and *Send* follow the text.
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final r = await s.repositories.users.searchUsers(q, limit: 6);
        if (mounted && _input.text.trim() == q) {
          setState(() {
            _suggestions = r;
            _noMatches = r.isEmpty;
          });
        }
      } catch (_) {}
    });
  }

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Longest share message (the server's limit, specs/06 §4).
  static const _maxMessage = 1000;

  void _addRecipient(String raw, {UserSummary? user}) {
    final v = raw.trim().toLowerCase();
    if (user != null) _people[v] = user;
    setState(() {
      if (_email.hasMatch(v) && !_recipients.contains(v)) _recipients.add(v);
      _input.clear();
      _suggestions = const [];
      _noMatches = false;
    });
    _inputFocus.requestFocus();
  }

  Future<void> _send() async {
    if (_input.text.trim().isNotEmpty) _addRecipient(_input.text);
    if (_recipients.isEmpty) return;
    final l = WonkyAppLocalizations.of(context);
    final emails = [..._recipients];
    final shared = await _run(
      () => s.repositories.sharing.share(
        widget.item.uuid,
        emails: emails,
        role: _role,
        notify: _notify,
        // The message only goes with an email.
        message: !_notify || _message.text.trim().isEmpty
            ? null
            : _message.text.trim(),
      ),
    );
    // On failure the recipients stay for a retry (the error toast showed).
    if (!shared || !mounted) return;
    setState(() {
      _recipients.clear();
      _input.clear();
      _message.clear();
    });
    s.toasts.show(l.shareSent(emails.length));
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: itemUrl(s, widget.item)));
    s.toasts.show(s.l10n?.toastLinkCopied ?? 'Link copied');
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final info = _info;
    Widget body;
    if (_error != null) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(errorMessage(_error!), style: theme.textTheme.muted),
      );
    } else if (info == null) {
      body = const SizedBox(height: 200, child: Center(child: ShadSpinner()));
    } else if (_settings) {
      body = _settingsPage(context, info);
    } else {
      body = _mainPage(context, info);
    }
    final isOwner = info?.myRole == AccessRole.owner;
    final actions = _actions(context, info);
    return CallbackShortcuts(
      bindings: {
        // Esc leaves adding people first, then closes.
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _adding && !_settings
            ? _cancelAdding()
            : Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.share'),
        // Keyed: the actions appear once the sharing info is loaded, and a
        // const close button would keep the X of the loading state.
        closeIcon: WonkyDialogCloseButton(key: ValueKey<bool>(actions.isEmpty)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _settings
                    ? l.shareSettingsTitle
                    : l.shareTitle(widget.item.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_settings && isOwner && !_adding)
              ShadTooltip(
                builder: (_) => Text(l.shareSettingsTitle),
                child: ShadIconButton.ghost(
                  key: const ValueKey<String>('dialog.share.settings'),
                  width: 28,
                  height: 28,
                  iconSize: 16,
                  semanticLabel: l.shareSettingsTitle,
                  icon: const Icon(LucideIcons.settings),
                  onPressed: () => setState(() => _settings = true),
                ),
              ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 580),
        actions: actions,
        // A full-width row: *Copy link* on the left, *Done* on the right.
        actionsMainAxisSize: MainAxisSize.max,
        actionsMainAxisAlignment: _settings || _adding
            ? MainAxisAlignment.end
            : MainAxisAlignment.spaceBetween,
        child: SizedBox(width: 540, child: body),
      ),
    );
  }

  Widget _mainPage(BuildContext context, SharingInfo info) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final canShare = info.canShare;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (info.pendingRequests.isNotEmpty && canShare)
          for (final r in info.pendingRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShadAlert(
                icon: const Icon(LucideIcons.keyRound),
                title: Text(
                  l.shareRequestTitle(
                    r.requester.displayName,
                    roleLabel(l, r.requestedRole),
                  ),
                ),
                description: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.message != null) Text(r.message!),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ShadButton(
                          size: ShadButtonSize.sm,
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => s.repositories.sharing
                                      .handleAccessRequest(
                                        r.id,
                                        true,
                                        r.requestedRole,
                                      ),
                                ),
                          child: Text(l.shareApprove),
                        ),
                        const SizedBox(width: 6),
                        ShadButton.outline(
                          size: ShadButtonSize.sm,
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => s.repositories.sharing
                                      .handleAccessRequest(r.id, false, null),
                                ),
                          child: Text(l.shareDeny),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        if (canShare) ...[
          _composer(context, info),
          if (!_adding) const SizedBox(height: 10),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l.shareCannotShare, style: theme.textTheme.muted),
          ),
        // While adding people only the composer shows (suite 06 §5).
        if (!_adding) ..._accessSections(context, info),
      ],
    );
  }

  List<Widget> _accessSections(BuildContext context, SharingInfo info) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final canShare = info.canShare;
    final me = s.me?.id;
    return [
      Text(
        l.sharePeopleWithAccess,
        style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          shrinkWrap: true,
          children: [
            _personRow(
              context,
              info.owner,
              info.owner.email,
              AccessRole.owner,
              isOwnerRow: true,
              isMe: info.owner.id == me,
            ),
            for (final p in info.permissions)
              if (p.user?.id != info.owner.id)
                _personRow(
                  context,
                  p.user,
                  p.user?.email ?? p.invitedEmail ?? '',
                  p.role,
                  invitedEmail: p.user == null ? p.invitedEmail : null,
                  inheritedFrom: p.inheritedFromName,
                  moderatorOf: p.viaPublication,
                  isMe: p.user?.id == me,
                  editable: canShare && p.inheritedFromUuid == null,
                ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Text(
        l.shareGeneralAccess,
        style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      _generalAccess(context, info),
    ];
  }

  /// The footer buttons, in `ShadDialog.actions` so the dialog has no X
  /// (suite 02 §4.20): *Copy link* (left) and *Done* on the main page,
  /// *Cancel* and *Send*/*Share* while adding people, *Done* (back to the
  /// main page) on the settings page; none while loading.
  List<Widget> _actions(BuildContext context, SharingInfo? info) {
    final l = WonkyAppLocalizations.of(context);
    if (info == null) return const [];
    if (_settings) {
      return [
        ShadButton(
          key: const ValueKey<String>('dialog.share.settingsDone'),
          onPressed: () => setState(() => _settings = false),
          child: Text(l.actionDone),
        ),
      ];
    }
    if (_adding) {
      return [
        ShadButton.outline(
          key: const ValueKey<String>('dialog.share.cancel'),
          onPressed: _cancelAdding,
          child: Text(l.actionCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('dialog.share.send'),
          enabled: !_busy && _canSend,
          onPressed: _send,
          child: Text(_notify ? l.actionSend : l.actionShare),
        ),
      ];
    }
    return [
      ShadButton.outline(
        key: const ValueKey<String>('dialog.share.copyLink'),
        leading: const Icon(LucideIcons.link, size: 16),
        onPressed: _copyLink,
        child: Text(l.cmdCopyLink),
      ),
      ShadButton(
        key: const ValueKey<String>('dialog.share.done'),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l.actionDone),
      ),
    ];
  }

  Widget _composer(BuildContext context, SharingInfo info) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final adding = _adding;
    final query = _input.text.trim();
    final org = info.organization;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _peopleField(context)),
            const SizedBox(width: 8),
            _roleSelect(
              context,
              _role,
              (r) => setState(() => _role = r),
              key: 'dialog.share.role',
            ),
          ],
        ),
        // The hint's line is always there (empty without it), so nothing
        // below moves when it appears.
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Visibility(
            visible: _noMatches && query.isNotEmpty && !_email.hasMatch(query),
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              org == null
                  ? l.shareSearchFullEmail
                  : l.shareSearchOutsideOrg(org),
              key: const ValueKey<String>('dialog.share.searchHint'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
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
                for (final u in _suggestions)
                  ShadButton.ghost(
                    mainAxisAlignment: MainAxisAlignment.start,
                    height: 40,
                    leading: WonkyAvatar(
                      name: u.displayName,
                      color: ShadTheme.of(
                        context,
                      ).colorScheme.presence(u.colorIndex),
                      imageUrl: u.avatarUrl,
                      size: 24,
                    ),
                    onPressed: () => _addRecipient(u.email, user: u),
                    child: Expanded(
                      child: Text(
                        '${u.displayName} · ${u.email}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (adding) ...[
          const SizedBox(height: 8),
          // Send an email (specs/06 §4): existing users get a share email,
          // addresses without an account an invitation to sign up.
          ShadCheckbox(
            key: const ValueKey<String>('dialog.share.sendEmail'),
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
            label: Text(l.shareNotify),
          ),
          if (_notify) ...[
            const SizedBox(height: 8),
            ShadTextarea(
              key: const ValueKey<String>('dialog.share.message'),
              controller: _message,
              placeholder: Text(l.shareMessage),
              minHeight: 60,
              maxLength: _maxMessage,
            ),
          ],
        ],
      ],
    );
  }

  /// The recipients' chips and the search input, drawn as one field: the
  /// theme's field decoration (border, fill, focus ring) is on the box, the
  /// input inside has none, and the box is as tall as a select next to it.
  Widget _peopleField(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final padding = theme.inputTheme.padding?.resolve(
      Directionality.of(context),
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: _inputFocus.requestFocus,
      child: ConstrainedBox(
        key: const ValueKey<String>('dialog.share.field'),
        constraints: BoxConstraints(
          minHeight: theme.selectTheme.minHeight ?? 36,
        ),
        child: ListenableBuilder(
          listenable: _inputFocus,
          builder: (context, child) => ShadDecorator(
            decoration: theme.inputTheme.decoration,
            focused: _inputFocus.hasFocus,
            child: child,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: Padding(
              padding: _recipients.isEmpty
                  ? EdgeInsets.zero
                  : const EdgeInsetsDirectional.fromSTEB(4, 3, 0, 3),
              // Chips flow like words; the input takes the rest of the
              // last line (the next line when too little is left).
              child: _InlineFlow(
                children: [
                  for (final r in _recipients)
                    _RecipientChip(
                      key: ValueKey<String>('dialog.share.chip.$r'),
                      email: r,
                      person: _people[r],
                      removeLabel: l.shareRemoveRecipient(r),
                      onRemove: () => setState(() => _recipients.remove(r)),
                    ),
                  Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onKeyEvent: _onInputKey,
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): () {
                          if (_suggestions.isNotEmpty &&
                              _input.text.isNotEmpty) {
                            _addRecipient(
                              _suggestions.first.email,
                              user: _suggestions.first,
                            );
                          } else if (_input.text.trim().isNotEmpty) {
                            _addRecipient(_input.text);
                          } else {
                            _send();
                          }
                        },
                      },
                      child: ShadInput(
                        key: const ValueKey<String>('dialog.share.input'),
                        controller: _input,
                        focusNode: _inputFocus,
                        autofocus: true,
                        // The box around is the field: no second border,
                        // fill, shadow or focus ring, and no minimum height
                        // of its own (the box sets it).
                        decoration: ShadDecoration.none,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.symmetric(
                          horizontal: _recipients.isEmpty
                              ? (padding?.left ?? 10)
                              : 4,
                          vertical: padding?.top ?? 4,
                        ),
                        // Only in the empty field: after chips the
                        // input reads as the rest of a line of text.
                        placeholder: _recipients.isEmpty
                            ? Text(l.shareAddPeople)
                            : null,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _onInput,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelect(
    BuildContext context,
    AccessRole value,
    ValueChanged<AccessRole> onChanged, {
    String? key,
    bool enabled = true,
    ShadSelectController<AccessRole>? controller,
  }) {
    final l = WonkyAppLocalizations.of(context);
    return ShadSelect<AccessRole>(
      key: key == null ? null : ValueKey<String>(key),
      controller: controller,
      initialValue: value,
      enabled: enabled && !_busy,
      minWidth: 130,
      options: [
        for (final r in [
          AccessRole.viewer,
          AccessRole.commenter,
          AccessRole.editor,
        ])
          ShadOption(value: r, child: Text(roleLabel(l, r))),
      ],
      selectedOptionBuilder: (context, v) => Text(roleLabel(l, v)),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _personRow(
    BuildContext context,
    UserSummary? user,
    String email,
    AccessRole role, {
    bool isOwnerRow = false,
    bool isMe = false,
    bool editable = false,
    String? invitedEmail,
    String? inheritedFrom,
    String? moderatorOf,
  }) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final name = user == null
        ? (invitedEmail ?? email)
        : (isMe ? l.shareYou(user.displayName) : user.displayName);
    final subtitle = [
      if (user != null) email,
      if (invitedEmail != null) l.sharePending,
      if (inheritedFrom != null) l.shareInherited(inheritedFrom),
      if (moderatorOf != null) l.shareModerator(moderatorOf),
    ].join(' · ');
    Widget trailing;
    if (isOwnerRow || !editable || isMe) {
      trailing = Text(roleLabel(l, role), style: theme.textTheme.muted);
    } else {
      trailing = WonkyDropdownMenu(
        anchor: const ShadAnchor(
          childAlignment: AlignmentDirectional.bottomEnd,
          overlayAlignment: AlignmentDirectional.topEnd,
          offset: Offset(0, 4),
        ),
        entries: () => [
          for (final r in [
            AccessRole.viewer,
            AccessRole.commenter,
            AccessRole.editor,
          ])
            WonkyMenuRadioItem(
              label: roleLabel(l, r),
              selected: r == role,
              enabled: user != null,
              onSelected: () => _run(
                () => s.repositories.sharing.updateRole(
                  widget.item.uuid,
                  userId: user!.id,
                  role: r,
                ),
              ),
            ),
          const WonkyMenuSeparator(),
          if (user != null && _info?.myRole == AccessRole.owner)
            WonkyMenuItem(
              label: l.shareTransferOwnership,
              icon: LucideIcons.crown,
              onSelected: () => _transfer(user),
            ),
          WonkyMenuItem(
            label: l.shareRemoveAccess,
            icon: LucideIcons.userMinus,
            destructive: true,
            onSelected: () => _remove(user, invitedEmail),
          ),
        ],
        builder: (context, c) => ShadButton.ghost(
          key: ValueKey<String>(
            'dialog.share.person.${user?.id ?? invitedEmail}',
          ),
          size: ShadButtonSize.sm,
          trailing: const Icon(LucideIcons.chevronDown, size: 14),
          onPressed: c.toggle,
          child: Text(roleLabel(l, role)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          WonkyAvatar(
            name: user?.displayName ?? email,
            color: user == null
                ? theme.colorScheme.muted
                : parseHexColor(user.avatarColor),
            imageUrl: user?.avatarUrl,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Future<void> _remove(UserSummary? user, String? invitedEmail) async {
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.shareRemoveTitle,
      description: l.shareRemoveBody(user?.displayName ?? invitedEmail ?? ''),
      confirmLabel: l.shareRemoveAccess,
      destructive: true,
    );
    if (!ok) return;
    await _run(
      () => s.repositories.sharing.remove(
        widget.item.uuid,
        userId: user?.id,
        invitedEmail: invitedEmail,
      ),
    );
  }

  Future<void> _transfer(UserSummary user) async {
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.shareTransferTitle,
      description: l.shareTransferBody(user.displayName),
      confirmLabel: l.shareTransferOwnership,
      destructive: true,
    );
    if (!ok) return;
    await _run(
      () => s.repositories.sharing.transferOwnership(widget.item.uuid, user.id),
    );
    s.toasts.show(l.shareTransferSent(user.displayName));
  }

  Widget _generalAccess(BuildContext context, SharingInfo info) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final access = info.generalAccess;
    final role = _generalRole(info);
    // The organization option: the caller's, or the one the item is
    // already shared with (an outside editor keeps seeing it).
    final domain = info.orgAccess?.domain ?? info.organization;
    final roleName = (role ?? AccessRole.viewer).name;
    // Signed-out visitors can view documents, spreadsheets and
    // presentations; files and folders need signing in.
    final signInOnly =
        info.itemKind == DriveItemKind.file ||
        info.itemKind == DriveItemKind.folder;
    final hint = switch (access) {
      GeneralAccess.restricted => l.shareRestrictedHint,
      GeneralAccess.organization => l.shareOrgHint(domain ?? '', roleName),
      GeneralAccess.link =>
        signInOnly
            ? l.shareLinkHintSignIn(roleName)
            : l.shareLinkHint(roleName),
    };
    final inherited = info.inheritedOrgAccess;
    String label(GeneralAccess a) => switch (a) {
      GeneralAccess.restricted => l.shareRestricted,
      GeneralAccess.organization => l.shareAnyoneAtOrg(domain ?? ''),
      GeneralAccess.link => l.shareAnyoneWithLink,
    };
    IconData icon(GeneralAccess a) => switch (a) {
      GeneralAccess.restricted => LucideIcons.lock,
      GeneralAccess.organization => LucideIcons.building2,
      GeneralAccess.link => LucideIcons.globe,
    };
    final muted = theme.textTheme.muted.copyWith(fontSize: 12);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Level with the select (as tall as a field).
          padding: EdgeInsets.only(
            top: ((theme.selectTheme.minHeight ?? 36) - 32) / 2,
          ),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: access == GeneralAccess.restricted
                  ? theme.colorScheme.muted
                  : theme.colorScheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon(access), size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadSelect<GeneralAccess>(
                key: const ValueKey<String>('dialog.share.linkMode'),
                controller: _accessMode,
                enabled: info.canShare && !_busy,
                options: [
                  for (final a in GeneralAccess.values)
                    if (a != GeneralAccess.organization || domain != null)
                      ShadOption(
                        value: a,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            Icon(icon(a), size: 14),
                            Flexible(
                              child: Text(
                                label(a),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
                selectedOptionBuilder: (context, v) =>
                    Text(label(v), overflow: TextOverflow.ellipsis),
                onChanged: (v) {
                  if (v == null || v == _info?.generalAccess) return;
                  _setGeneralAccess(
                    v,
                    v == GeneralAccess.restricted ? null : AccessRole.viewer,
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                key: const ValueKey<String>('dialog.share.accessHint'),
                style: muted,
              ),
              if (inherited != null &&
                  access != GeneralAccess.organization) ...[
                const SizedBox(height: 2),
                Text(
                  l.shareOrgInherited(
                    inherited.domain,
                    inherited.role.name,
                    inherited.inheritedFromName ?? '',
                  ),
                  key: const ValueKey<String>('dialog.share.orgInherited'),
                  style: muted,
                ),
              ],
            ],
          ),
        ),
        if (role != null) ...[
          const SizedBox(width: 8),
          _roleSelect(
            context,
            role,
            (r) {
              final current = _info?.generalAccess;
              if (current == null || current == GeneralAccess.restricted) {
                return;
              }
              _setGeneralAccess(current, r);
            },
            key: access == GeneralAccess.organization
                ? 'dialog.share.orgRole'
                : 'dialog.share.linkRole',
            controller: _accessRole,
            enabled: info.canShare,
          ),
        ],
      ],
    );
  }

  Widget _settingsPage(BuildContext context, SharingInfo info) {
    final l = WonkyAppLocalizations.of(context);
    final st = info.settings;
    void update(ItemSharingSettings next) => _run(
      () => s.repositories.sharing.updateSettings(widget.item.uuid, next),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        ShadCheckbox(
          value: st.editorsCanShare,
          onChanged: (v) => update(st.copyWith(editorsCanShare: v)),
          label: Text(l.shareSettingEditors),
        ),
        ShadCheckbox(
          value: st.nonEditorsCanExport,
          onChanged: (v) => update(st.copyWith(nonEditorsCanExport: v)),
          label: Text(l.shareSettingExport),
        ),
        ShadCheckbox(
          value: st.viewersSeeComments,
          onChanged: (v) => update(st.copyWith(viewersSeeComments: v)),
          label: Text(l.shareSettingComments),
        ),
      ],
    );
  }
}

/// A recipient in the people field: a rounded chip with the person's
/// avatar and name (picked from suggestions; the email in a tooltip) or
/// the typed address, and an × that removes it.
class _RecipientChip extends StatelessWidget {
  const _RecipientChip({
    super.key,
    required this.email,
    required this.person,
    required this.removeLabel,
    required this.onRemove,
  });

  final String email;
  final UserSummary? person;
  final String removeLabel;
  final VoidCallback onRemove;

  static const height = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final p = person;
    final chip = Container(
      height: height,
      padding: const EdgeInsetsDirectional.fromSTEB(3, 0, 3, 0),
      decoration: ShapeDecoration(
        color: cs.secondary,
        shape: StadiumBorder(side: BorderSide(color: cs.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WonkyAvatar(
            name: p?.displayName ?? email,
            // A typed address: blue (the info color), not gray.
            color: p == null ? cs.info : cs.presence(p.colorIndex),
            imageUrl: p?.avatarUrl,
            size: height - 6,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              p?.displayName ?? email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.small.copyWith(
                color: cs.secondaryForeground,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Semantics(
            button: true,
            label: removeLabel,
            excludeSemantics: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: SizedBox.square(
                  dimension: height - 6,
                  child: Icon(
                    LucideIcons.x,
                    size: 12,
                    color: cs.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return p == null
        ? chip
        : ShadTooltip(builder: (_) => Text(email), child: chip);
  }
}

/// Lays out its children like words in a line of text: left to right with
/// [spacing], wrapping to a new line with [runSpacing], each line's
/// children centered vertically. The **last** child (the input) gets the
/// rest of its line, or the whole next line when less than [minLastWidth]
/// is left.
class _InlineFlow extends MultiChildRenderObjectWidget {
  const _InlineFlow({required super.children});

  static const spacing = 4.0;
  static const runSpacing = 4.0;
  static const minLastWidth = 120.0;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderInlineFlow();
}

class _InlineFlowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderInlineFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _InlineFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _InlineFlowParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _InlineFlowParentData) {
      child.parentData = _InlineFlowParentData();
    }
  }

  /// Lays out (or, [dry], measures) the children; returns the size and,
  /// unless [dry], positions them.
  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : 600.0;
    final lines = <List<(RenderBox, Size)>>[[]];
    var x = 0.0;
    var child = firstChild;
    while (child != null) {
      final last = child == lastChild;
      Size size;
      if (last) {
        var left = maxWidth - x;
        if (lines.last.isNotEmpty && left < _InlineFlow.minLastWidth) {
          lines.add([]);
          x = 0;
          left = maxWidth;
        }
        final c = BoxConstraints.tightFor(width: left);
        size = dry ? child.getDryLayout(c) : _lay(child, c);
      } else {
        final c = BoxConstraints(maxWidth: maxWidth);
        size = dry ? child.getDryLayout(c) : _lay(child, c);
        if (lines.last.isNotEmpty && x + size.width > maxWidth) {
          lines.add([]);
          x = 0;
        }
      }
      lines.last.add((child, size));
      x += size.width + _InlineFlow.spacing;
      child = childAfter(child);
    }
    var y = 0.0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      final height = line.fold<double>(
        0,
        (h, e) => h > e.$2.height ? h : e.$2.height,
      );
      if (!dry) {
        var lx = 0.0;
        for (final (box, size) in line) {
          (box.parentData! as _InlineFlowParentData).offset = Offset(
            lx,
            y + (height - size.height) / 2,
          );
          lx += size.width + _InlineFlow.spacing;
        }
      }
      y += height + (i < lines.length - 1 ? _InlineFlow.runSpacing : 0);
    }
    return constraints.constrain(Size(maxWidth, y));
  }

  static Size _lay(RenderBox child, BoxConstraints c) {
    child.layout(c, parentUsesSize: true);
    return child.size;
  }

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  double computeMinIntrinsicWidth(double height) => _InlineFlow.minLastWidth;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var w = 0.0;
    var child = firstChild;
    while (child != null) {
      w += child.getMaxIntrinsicWidth(height) + _InlineFlow.spacing;
      child = childAfter(child);
    }
    return w;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _layout(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
