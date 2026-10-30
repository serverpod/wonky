import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../bootstrap/app_urls.dart';
import '../data/api.dart';
import '../l10n/wonky_app_localizations.dart';
import '../settings/settings_screen.dart';
import '../shell/dialogs.dart';
import '../shell/form_dialog.dart';
import '../shell/shell_services.dart';
import 'publication_repository.dart';

/// The developer guide for blog owners (specs/18 §12 PUB-7).
const publicationGuideUrl =
    'https://github.com/serverpod/wonky/blob/main/docs/blog-integration.md';

/// Wonky Work settings › Publications (specs/18 §8.1): the user's
/// publications, their credentials, moderators, verification and webhook
/// deliveries.
class PublicationsSection extends StatefulWidget {
  const PublicationsSection({super.key, required this.services});

  final ShellServices services;

  @override
  State<PublicationsSection> createState() => _PublicationsSectionState();
}

class _PublicationsSectionState extends State<PublicationsSection> {
  List<PublicationSettings>? _list;
  Object? _loadError;

  /// The secret shown once: (publicId, label, value).
  (String, String, String)? _secret;

  /// The publication whose details are open.
  String? _open;
  List<PublicationDeliveryView>? _deliveries;

  ShellServices get s => widget.services;
  PublicationRepository get repo => s.repositories.publications;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final list = await repo.list();
      if (mounted) {
        setState(() {
          _list = list;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _replace(PublicationSettings p) => setState(() {
    _list = [
      for (final x in _list ?? const <PublicationSettings>[])
        x.publicId == p.publicId ? p : x,
    ];
  });

  Future<T?> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      if (mounted) {
        final l = WonkyAppLocalizations.of(context);
        s.toasts.error(l.errorGeneric, description: errorMessage(e));
      }
      return null;
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    s.toasts.show(WonkyAppLocalizations.of(context).pubCopied);
  }

  // ------------------------------------------------------------ editing

  Future<void> _edit([PublicationSettings? p]) async {
    final l = WonkyAppLocalizations.of(context);
    final f = p?.fields;
    String? required(String v) => v.trim().isEmpty ? l.pubRequired : null;
    String? https(String v) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return t.startsWith('https://') ? null : l.pubHttpsOnly;
    }

    Map<String, String> modes() => {
      'off': l.pubFieldOff,
      'optional': l.pubFieldOptional,
      'required': l.pubFieldRequired,
    };
    final r = await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: p == null ? l.pubNew : l.pubEdit(p.name),
        description: p == null ? l.pubNewHint : null,
        dialogKey: 'dialog.publication',
        width: 520,
        fields: [
          TextFieldSpec(
            id: 'name',
            label: l.pubName,
            initial: p?.name ?? '',
            maxLength: 60,
            validator: required,
          ),
          TextFieldSpec(
            id: 'siteUrl',
            label: l.pubSiteUrl,
            placeholder: 'https://blog.example.com',
            initial: p?.siteUrl ?? '',
            validator: (v) => required(v) ?? https(v),
          ),
          TextFieldSpec(
            id: 'webhookUrl',
            label: l.pubWebhookUrl,
            placeholder: 'https://blog.example.com/api/wonky/webhook',
            initial: p?.webhookUrl ?? '',
            validator: (v) => required(v) ?? https(v),
          ),
          TextFieldSpec(
            id: 'termsUrl',
            label: l.pubTermsUrl,
            initial: p?.termsUrl ?? '',
            validator: https,
          ),
          TextFieldSpec(
            id: 'template',
            label: l.pubTemplate,
            placeholder: l.pubTemplateHint,
            initial: p?.templateItemUuid == null
                ? ''
                : '${s.urls.apps[WonkyAppKind.write]}d/${p!.templateItemUuid!.uuid}',
            validator: (v) => v.trim().isEmpty || _uuidIn(v) != null
                ? null
                : l.pubTemplateInvalid,
          ),
          SelectFieldSpec(
            id: 'markdownFlavor',
            label: l.pubMarkdownFlavor,
            options: {'gfm': l.pubMarkdownGfm, 'wonky': l.pubMarkdownWonky},
            initial: p?.markdownFlavor == 'wonky' ? 'wonky' : 'gfm',
          ),
          SelectFieldSpec(
            id: 'summary',
            label: l.pubFieldSummary,
            options: modes(),
            initial: (f?.summary ?? PublicationFieldMode.optional).name,
          ),
          SelectFieldSpec(
            id: 'tags',
            label: l.pubFieldTags,
            options: modes(),
            initial: (f?.tags ?? PublicationFieldMode.optional).name,
          ),
          TextFieldSpec(
            id: 'allowedTags',
            label: l.pubAllowedTags,
            placeholder: l.pubAllowedTagsHint,
            initial: f?.allowedTags.join(', ') ?? '',
          ),
          SelectFieldSpec(
            id: 'coverImage',
            label: l.pubFieldCover,
            options: modes(),
            initial: (f?.coverImage ?? PublicationFieldMode.off).name,
          ),
          SelectFieldSpec(
            id: 'authorBio',
            label: l.pubFieldBio,
            options: modes(),
            initial: (f?.authorBio ?? PublicationFieldMode.off).name,
          ),
          SelectFieldSpec(
            id: 'note',
            label: l.pubFieldNote,
            options: modes(),
            initial: (f?.note ?? PublicationFieldMode.optional).name,
          ),
          CheckboxFieldSpec(
            id: 'enabled',
            label: l.pubEnabled,
            initial: p?.enabled ?? true,
          ),
        ],
        buttons: [
          DialogButtonSpec(
            id: 'cancel',
            label: l.actionCancel,
            validates: false,
          ),
          DialogButtonSpec(
            id: 'save',
            label: p == null ? l.actionCreate : l.actionSave,
            primary: true,
          ),
        ],
      ),
    );
    if (r == null || r.buttonId != 'save' || !mounted) return;
    PublicationFieldMode mode(String id) =>
        PublicationFieldMode.values.asNameMap()[r.text(id)] ??
        PublicationFieldMode.off;
    final input = PublicationInput(
      name: r.text('name').trim(),
      siteUrl: r.text('siteUrl').trim(),
      webhookUrl: r.text('webhookUrl').trim(),
      termsUrl: r.text('termsUrl').trim().isEmpty
          ? null
          : r.text('termsUrl').trim(),
      templateItemUuid: _uuidIn(r.text('template')),
      markdownFlavor: r.text('markdownFlavor'),
      fields: PublicationFields(
        summary: mode('summary'),
        tags: mode('tags'),
        allowedTags: [
          for (final t in r.text('allowedTags').split(','))
            if (t.trim().isNotEmpty) t.trim(),
        ],
        coverImage: mode('coverImage'),
        authorBio: mode('authorBio'),
        note: mode('note'),
      ),
      enabled: r.flag('enabled'),
    );
    if (p == null) {
      final created = await _guard<PublicationSecret>(() => repo.create(input));
      if (created == null || !mounted) return;
      setState(() {
        _list = [...?_list, created.settings];
        _open = created.settings.publicId;
        _secret = (
          created.settings.publicId,
          l.pubSigningSecret,
          created.secret,
        );
        _deliveries = null;
      });
      await _loadDeliveries(created.settings);
    } else {
      final updated = await _guard<PublicationSettings>(
        () => repo.update(p.publicId, input),
      );
      if (updated != null && mounted) _replace(updated);
    }
  }

  /// The document uuid in a pasted Wonky Write link (or a bare uuid).
  static UuidValue? _uuidIn(String text) {
    final m = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(text);
    return m == null ? null : UuidValue.fromString(m[0]!.toLowerCase());
  }

  Future<void> _moderators(PublicationSettings p) async {
    final l = WonkyAppLocalizations.of(context);
    final r = await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: l.pubModerators,
        description: l.pubModeratorsHint,
        dialogKey: 'dialog.publicationModerators',
        width: 480,
        fields: [
          TextFieldSpec(
            id: 'emails',
            label: l.pubModeratorEmails,
            multiline: true,
            initial: [for (final m in p.moderators) m.email].join('\n'),
          ),
        ],
        buttons: [
          DialogButtonSpec(
            id: 'cancel',
            label: l.actionCancel,
            validates: false,
          ),
          DialogButtonSpec(id: 'save', label: l.actionSave, primary: true),
        ],
      ),
    );
    if (r == null || r.buttonId != 'save' || !mounted) return;
    final emails = [
      for (final e in r.text('emails').split(RegExp(r'[\s,;]+')))
        if (e.trim().isNotEmpty) e.trim(),
    ];
    final updated = await _guard<PublicationSettings>(
      () => repo.setModerators(p.publicId, emails),
    );
    if (updated != null && mounted) _replace(updated);
  }

  Future<void> _verify(PublicationSettings p) async {
    final l = WonkyAppLocalizations.of(context);
    final r = await _guard<PublicationCheckResult>(
      () => repo.verify(p.publicId),
    );
    if (r == null || !mounted) return;
    _replace(r.settings);
    if (r.ok) {
      s.toasts.show(l.pubVerified(Uri.parse(p.siteUrl).host));
    } else {
      s.toasts.error(l.pubVerifyFailed, description: r.message);
    }
  }

  Future<void> _sendTest(PublicationSettings p) async {
    final l = WonkyAppLocalizations.of(context);
    final r = await _guard<PublicationCheckResult>(
      () => repo.sendTest(p.publicId),
    );
    if (r == null || !mounted) return;
    if (r.ok) {
      s.toasts.show(l.pubTestOk);
    } else {
      s.toasts.error(l.pubTestFailed, description: r.message);
    }
    await _loadDeliveries(p);
  }

  Future<void> _rotateSecret(PublicationSettings p) async {
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.pubRotateSecret,
      description: l.pubRotateSecretBody,
      confirmLabel: l.pubRotate,
    );
    if (!ok) return;
    final r = await _guard<PublicationSecret>(
      () => repo.rotateSecret(p.publicId),
    );
    if (r == null || !mounted) return;
    _replace(r.settings);
    setState(() => _secret = (p.publicId, l.pubSigningSecret, r.secret));
  }

  Future<void> _apiKey(PublicationSettings p) async {
    final l = WonkyAppLocalizations.of(context);
    if (p.hasApiKey) {
      final ok = await confirmDialog(
        context,
        title: l.pubRotateApiKey,
        description: l.pubRotateApiKeyBody,
        confirmLabel: l.pubRotate,
        destructive: true,
      );
      if (!ok) return;
    }
    final r = await _guard<PublicationSecret>(
      () => repo.createApiKey(p.publicId),
    );
    if (r == null || !mounted) return;
    _replace(r.settings);
    setState(() => _secret = (p.publicId, l.pubApiKey, r.secret));
  }

  Future<void> _delete(PublicationSettings p) async {
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.pubDeleteTitle(p.name),
      description: l.pubDeleteBody,
      confirmLabel: l.pubDelete,
      destructive: true,
    );
    if (!ok) return;
    final done = await _guard<bool>(() async {
      await repo.delete(p.publicId);
      return true;
    });
    if (done == true && mounted) {
      setState(() {
        _list = [
          for (final x in _list ?? const <PublicationSettings>[])
            if (x.publicId != p.publicId) x,
        ];
        _open = null;
      });
    }
  }

  Future<void> _loadDeliveries(PublicationSettings p) async {
    final list = await _guard<List<PublicationDeliveryView>>(
      () => repo.deliveries(p.publicId),
    );
    if (list != null && mounted && _open == p.publicId) {
      setState(() => _deliveries = list);
    }
  }

  Future<void> _resend(PublicationSettings p, PublicationDeliveryView d) async {
    await _guard<PublicationDeliveryView>(
      () => repo.resend(p.publicId, d.webhookId),
    );
    await _loadDeliveries(p);
  }

  void _toggle(PublicationSettings p) {
    setState(() {
      _open = _open == p.publicId ? null : p.publicId;
      _deliveries = null;
    });
    if (_open != null) _loadDeliveries(p);
  }

  // -------------------------------------------------------------- views

  String _date(DateTime? d) =>
      d == null ? '—' : intl.DateFormat.yMMMd().add_Hm().format(d.toLocal());

  Widget _mono(BuildContext context, String text, {Key? key}) {
    final theme = ShadTheme.of(context);
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: WonkyFonts.geistMono,
          fontSize: 12,
          color: theme.colorScheme.foreground,
        ),
      ),
    );
  }

  Widget _copyRow(BuildContext context, String label, String value, String id) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.small),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _mono(context, value)),
              const SizedBox(width: 6),
              ShadButton.ghost(
                key: ValueKey<String>('settings.publications.copy.$id'),
                size: ShadButtonSize.sm,
                onPressed: () => _copy(value),
                child: Text(l.pubCopy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, PublicationSettings p) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final host = Uri.parse(p.siteUrl).host;
    final open = _open == p.publicId;
    return Column(
      key: ValueKey<String>('settings.publications.${p.publicId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(LucideIcons.newspaper, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: theme.textTheme.small),
                    Text(
                      [
                        p.verifiedHost != null
                            ? l.pubHostVerified(host)
                            : l.pubHostUnverified(host),
                        if (!p.enabled) l.pubDisabled,
                        l.pubOpenCount(p.openSubmissionCount),
                      ].join(' · '),
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              ShadButton.ghost(
                key: ValueKey<String>(
                  'settings.publications.open.${p.publicId}',
                ),
                size: ShadButtonSize.sm,
                onPressed: () => _toggle(p),
                child: Text(open ? l.pubHide : l.pubManage),
              ),
            ],
          ),
        ),
        if (open) _details(context, p),
      ],
    );
  }

  Widget _details(BuildContext context, PublicationSettings p) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final secret = _secret;
    final deliveries = _deliveries;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 4, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (secret != null && secret.$1 == p.publicId)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShadAlert(
                key: const ValueKey<String>('settings.publications.secret'),
                icon: const Icon(LucideIcons.keyRound),
                title: Text(l.pubSecretOnce(secret.$2)),
                description: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    _mono(context, secret.$3),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ShadButton.outline(
                          size: ShadButtonSize.sm,
                          onPressed: () => _copy(secret.$3),
                          child: Text(l.pubCopy),
                        ),
                        const SizedBox(width: 6),
                        ShadButton.ghost(
                          size: ShadButtonSize.sm,
                          onPressed: () => setState(() => _secret = null),
                          child: Text(l.pubSecretSaved),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          _copyRow(context, l.pubContributorLink, p.contributorLink, 'link'),
          _copyRow(context, l.pubId, p.publicId, 'id'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ShadButton.outline(
                key: const ValueKey<String>('settings.publications.edit'),
                size: ShadButtonSize.sm,
                onPressed: () => _edit(p),
                child: Text(l.pubEditButton),
              ),
              ShadButton.outline(
                key: const ValueKey<String>('settings.publications.moderators'),
                size: ShadButtonSize.sm,
                onPressed: () => _moderators(p),
                child: Text(l.pubModeratorsButton(p.moderators.length)),
              ),
              ShadButton.ghost(
                key: const ValueKey<String>('settings.publications.delete'),
                size: ShadButtonSize.sm,
                onPressed: () => _delete(p),
                child: Text(l.pubDelete),
              ),
            ],
          ),
          heading(l.pubVerification),
          Text(
            p.verifiedHost != null
                ? l.pubVerifiedAt(p.verifiedHost!, _date(p.verifiedAt))
                : l.pubVerifyHint(Uri.parse(p.siteUrl).host),
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
          if (p.verifiedHost == null) ...[
            const SizedBox(height: 6),
            _mono(context, '{ "publications": ["${p.publicId}"] }'),
          ],
          const SizedBox(height: 6),
          ShadButton.outline(
            key: const ValueKey<String>('settings.publications.verify'),
            size: ShadButtonSize.sm,
            onPressed: () => _verify(p),
            child: Text(l.pubVerify),
          ),
          heading(l.pubCredentials),
          Text(
            p.previousSecretUntil != null
                ? l.pubRotationActive(_date(p.previousSecretUntil))
                : l.pubSecretHint,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ShadButton.outline(
                key: const ValueKey<String>('settings.publications.rotate'),
                size: ShadButtonSize.sm,
                onPressed: () => _rotateSecret(p),
                child: Text(l.pubRotateSecret),
              ),
              ShadButton.outline(
                key: const ValueKey<String>('settings.publications.apiKey'),
                size: ShadButtonSize.sm,
                onPressed: () => _apiKey(p),
                child: Text(
                  p.hasApiKey
                      ? l.pubRotateApiKeyLast4(p.apiKeyLast4 ?? '')
                      : l.pubCreateApiKey,
                ),
              ),
            ],
          ),
          heading(l.pubDeliveries),
          Row(
            children: [
              ShadButton.outline(
                key: const ValueKey<String>('settings.publications.test'),
                size: ShadButtonSize.sm,
                onPressed: () => _sendTest(p),
                child: Text(l.pubSendTest),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (deliveries == null)
            const ShadSpinner()
          else if (deliveries.isEmpty)
            Text(l.pubNoDeliveries, style: theme.textTheme.muted)
          else
            for (final d in deliveries) _delivery(context, p, d),
        ],
      ),
    );
  }

  Widget _delivery(
    BuildContext context,
    PublicationSettings p,
    PublicationDeliveryView d,
  ) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final state = d.deliveredAt != null
        ? l.pubDelivered(d.lastStatus ?? 200)
        : d.failedAt != null
        ? l.pubDeliveryFailed(d.lastError ?? '')
        : d.attempts == 0
        ? l.pubDeliveryQueued
        : l.pubDeliveryRetrying(d.lastError ?? '', _date(d.nextAttemptAt));
    return Padding(
      key: ValueKey<String>('settings.publications.delivery.${d.webhookId}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.type} · ${_date(d.createdAt)}',
                  style: theme.textTheme.small.copyWith(fontSize: 12),
                ),
                Text(
                  state,
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: () => _resend(p, d),
            child: Text(l.pubResend),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final list = _list;
    return SettingsGroup(
      title: l.settingsPublications,
      description: l.pubSectionHint,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ShadButton(
              key: const ValueKey<String>('settings.publications.new'),
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.plus, size: 16),
              onPressed: _edit,
              child: Text(l.pubNew),
            ),
            ShadButton.ghost(
              key: const ValueKey<String>('settings.publications.guide'),
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.bookOpen, size: 16),
              onPressed: () => s.crossApp.openExternal(publicationGuideUrl),
              child: Text(l.pubGuide),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loadError != null)
          Text(errorMessage(_loadError!), style: theme.textTheme.muted)
        else if (list == null)
          const ShadSpinner()
        else if (list.isEmpty)
          Text(
            l.pubEmpty,
            key: const ValueKey<String>('settings.publications.empty'),
            style: theme.textTheme.muted,
          )
        else
          for (final p in list) _row(context, p),
      ],
    );
  }
}
