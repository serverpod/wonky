import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
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
  AccessRole _role = AccessRole.editor;
  bool _notify = true;
  List<UserSummary> _suggestions = const [];
  Timer? _debounce;

  // The link selects follow `_info` (also after a failed change).
  final _linkMode = ShadSelectController<String>();
  final _linkRole = ShadSelectController<AccessRole>();

  ShellServices get s => widget.services;

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
    _linkMode.dispose();
    _linkRole.dispose();
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

  /// Shows the link mode and role of `_info` in the link selects.
  void _syncLinkSelects() {
    final role = _info?.link?.role;
    final mode = {role == null ? 'restricted' : 'link'};
    if (!setEquals(_linkMode.value, mode)) _linkMode.value = mode;
    if (role != null && !setEquals(_linkRole.value, {role})) {
      _linkRole.value = {role};
    }
  }

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
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final r = await s.repositories.users.searchUsers(q, limit: 6);
        if (mounted && _input.text.trim() == q) {
          setState(() => _suggestions = r);
        }
      } catch (_) {}
    });
  }

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _addRecipient(String raw) {
    final v = raw.trim().toLowerCase();
    setState(() {
      if (_email.hasMatch(v) && !_recipients.contains(v)) _recipients.add(v);
      _input.clear();
      _suggestions = const [];
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
        message: _message.text.trim().isEmpty ? null : _message.text.trim(),
      ),
    );
    // On failure the recipients stay for a retry (the error toast showed).
    if (!shared || !mounted) return;
    setState(() {
      _recipients.clear();
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
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.share'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Row(
          children: [
            if (_settings)
              ShadIconButton.ghost(
                width: 28,
                height: 28,
                iconSize: 16,
                semanticLabel: l.actionBack,
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => setState(() => _settings = false),
              ),
            Expanded(
              child: Text(
                _settings
                    ? l.shareSettingsTitle
                    : l.shareTitle(widget.item.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_settings && isOwner)
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
        child: SizedBox(width: 540, child: body),
      ),
    );
  }

  Widget _mainPage(BuildContext context, SharingInfo info) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final canShare = info.canShare;
    final me = s.me?.id;
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
          _composer(context),
          const SizedBox(height: 14),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l.shareCannotShare, style: theme.textTheme.muted),
          ),
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
        const SizedBox(height: 16),
        Row(
          children: [
            ShadButton.outline(
              key: const ValueKey<String>('dialog.share.copyLink'),
              leading: const Icon(LucideIcons.link, size: 16),
              onPressed: _copyLink,
              child: Text(l.cmdCopyLink),
            ),
            const Spacer(),
            ShadButton(
              key: const ValueKey<String>('dialog.share.done'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.actionDone),
            ),
          ],
        ),
      ],
    );
  }

  Widget _composer(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final expanded = _recipients.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minHeight: 36),
                decoration: BoxDecoration(
                  // Same fill as a plain field, so chips + input read as one.
                  color: theme.inputTheme.decoration?.color,
                  border: Border.all(color: theme.colorScheme.input),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final r in _recipients)
                      ShadBadge.secondary(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(r),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _recipients.remove(r)),
                              child: Semantics(
                                button: true,
                                label: l.shareRemoveRecipient(r),
                                child: const Icon(LucideIcons.x, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 200,
                        maxWidth: 360,
                      ),
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.enter): () {
                            if (_suggestions.isNotEmpty &&
                                _input.text.isNotEmpty) {
                              _addRecipient(_suggestions.first.email);
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
                          // The bordered container is the field: no second
                          // fill or border inside it.
                          decoration: const ShadDecoration(
                            color: Color(0x00000000),
                            border: ShadBorder.none,
                            focusedBorder: ShadBorder.none,
                            disableSecondaryBorder: true,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          placeholder: Text(l.shareAddPeople),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: _onInput,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _roleSelect(
              context,
              _role,
              (r) => setState(() => _role = r),
              key: 'dialog.share.role',
            ),
          ],
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
                    onPressed: () => _addRecipient(u.email),
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
        if (expanded) ...[
          const SizedBox(height: 8),
          ShadCheckbox(
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
            label: Text(l.shareNotify),
          ),
          if (_notify) ...[
            const SizedBox(height: 8),
            ShadTextarea(
              controller: _message,
              placeholder: Text(l.shareMessage),
              minHeight: 60,
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton(
              key: const ValueKey<String>('dialog.share.send'),
              enabled: !_busy,
              onPressed: _send,
              child: Text(_notify ? l.actionSend : l.actionShare),
            ),
          ),
        ],
      ],
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
    final linkRole = info.link?.role;
    final restricted = linkRole == null;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: restricted
                ? theme.colorScheme.muted
                : theme.colorScheme.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            restricted ? LucideIcons.lock : LucideIcons.globe,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadSelect<String>(
                key: const ValueKey<String>('dialog.share.linkMode'),
                controller: _linkMode,
                enabled: info.canShare && !_busy,
                options: [
                  ShadOption(
                    value: 'restricted',
                    child: Text(l.shareRestricted),
                  ),
                  ShadOption(value: 'link', child: Text(l.shareAnyoneWithLink)),
                ],
                selectedOptionBuilder: (context, v) => Text(
                  v == 'restricted' ? l.shareRestricted : l.shareAnyoneWithLink,
                ),
                onChanged: (v) {
                  if (v == null) return;
                  _run(
                    () => s.repositories.sharing.setLink(
                      widget.item.uuid,
                      v == 'restricted' ? null : AccessRole.viewer,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                restricted ? l.shareRestrictedHint : l.shareLinkHint,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        if (!restricted) ...[
          const SizedBox(width: 8),
          _roleSelect(
            context,
            linkRole,
            (r) =>
                _run(() => s.repositories.sharing.setLink(widget.item.uuid, r)),
            key: 'dialog.share.linkRole',
            controller: _linkRole,
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
        if (info.link != null)
          ShadButton.outline(
            onPressed: () =>
                _run(() => s.repositories.sharing.rotateLink(widget.item.uuid)),
            leading: const Icon(LucideIcons.refreshCw, size: 16),
            child: Text(l.shareRotateLink),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton(
            onPressed: () => setState(() => _settings = false),
            child: Text(l.actionDone),
          ),
        ),
      ],
    );
  }
}
