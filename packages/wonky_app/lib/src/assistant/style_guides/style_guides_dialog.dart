import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../data/api.dart' show errorMessage;
import '../../l10n/wonky_app_localizations.dart';
import '../../markdown/markdown_composer.dart';
import '../../markdown/wonky_markdown.dart';
import '../../shell/shell_services.dart';
import '../../undo/undo_service.dart';
import '../shell_assistant.dart';
import 'style_guide_library.dart';

/// Opens the style guide library (suite 10 §7): browse the built-in,
/// personal and organization guides, write and edit guides in Markdown,
/// share them with the organization, set the organization default and,
/// with [itemUuid], choose the document's guide. [onUseForDocument] runs
/// the app's command for the document's choice (default: the library
/// controller, on [documentStack]).
Future<void> showStyleGuidesDialog(
  BuildContext context,
  ShellServices services, {
  UuidValue? itemUuid,
  UndoStackKey? documentStack,
  Future<void> Function(String? ref)? onUseForDocument,
}) async {
  final api = ShellAssistant.of(services)?.api;
  if (api == null) return;
  final c = StyleGuideLibraryController(
    services: services,
    api: api,
    itemUuid: itemUuid,
    documentStack: documentStack,
  );
  unawaited(c.load());
  try {
    await showShadDialog<void>(
      context: context,
      builder: (_) => StyleGuidesDialog(
        controller: c,
        services: services,
        onUseForDocument: onUseForDocument,
      ),
    );
  } finally {
    c.dispose();
  }
}

class StyleGuidesDialog extends StatefulWidget {
  const StyleGuidesDialog({
    super.key,
    required this.controller,
    required this.services,
    this.onUseForDocument,
  });

  final StyleGuideLibraryController controller;
  final ShellServices services;
  final Future<void> Function(String? ref)? onUseForDocument;

  @override
  State<StyleGuidesDialog> createState() => _StyleGuidesDialogState();
}

class _StyleGuidesDialogState extends State<StyleGuidesDialog> {
  StyleGuideLibraryController get c => widget.controller;

  /// The selected guide (`noStyleGuideRef` = "No style guide").
  String? _selected;

  /// The guide being edited (null = viewing); a new guide has no uuid.
  StyleGuideInput? _editing;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _markdown = TextEditingController();
  bool _share = false;
  String? _formError;
  bool _busy = false;

  bool get _forDocument => c.itemUuid != null;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChanged);
  }

  @override
  void dispose() {
    c.removeListener(_onChanged);
    _name.dispose();
    _description.dispose();
    _markdown.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final lib = c.library;
    if (_selected == null && lib != null) {
      _selected =
          lib.effectiveRef ??
          (_forDocument ? noStyleGuideRef : lib.guides.firstOrNull?.ref);
    }
    setState(() {});
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      widget.services.toasts.error(errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit(StyleGuideInput input) {
    _name.text = input.name;
    _description.text = input.description;
    _markdown.text = input.markdown;
    _share = input.shareWithOrg && c.library?.orgKey != null;
    _formError = null;
    setState(() => _editing = input);
  }

  void _newGuide() {
    final l = WonkyAppLocalizations.of(context);
    _edit(
      StyleGuideInput(
        name: '',
        description: '',
        markdown: l.styleGuideTemplate,
        shareWithOrg: false,
      ),
    );
  }

  Future<void> _save() async {
    final l = WonkyAppLocalizations.of(context);
    final e = _editing;
    if (e == null) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _formError = l.styleGuideNameRequired);
      return;
    }
    if (_markdown.text.trim().isEmpty) {
      setState(() => _formError = l.styleGuideEmpty);
      return;
    }
    await _run(() async {
      final saved = await c.save(
        StyleGuideInput(
          uuid: e.uuid,
          name: _name.text.trim(),
          description: _description.text.trim(),
          markdown: _markdown.text,
          shareWithOrg: _share,
        ),
      );
      if (!mounted) return;
      setState(() {
        _editing = null;
        _selected = saved.ref;
      });
    });
  }

  Future<void> _useForDocument(String? ref) => _run(() async {
    final run = widget.onUseForDocument;
    if (run != null) {
      await run(ref);
      await c.load();
    } else {
      await c.setDocument(ref);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 48).clamp(320.0, 900.0);
    final height = (size.height - 200).clamp(360.0, 600.0);
    final narrow = width < 640;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_editing != null) {
            setState(() => _editing = null);
          } else {
            Navigator.of(context).pop();
          }
        },
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.styleGuides'),
        closeIcon: const WonkyDialogCloseButton(),
        constraints: const BoxConstraints(maxWidth: 940),
        title: Text(l.styleGuidesTitle),
        description: Text(
          _forDocument
              ? l.styleGuidesDescriptionDocument
              : l.styleGuidesDescription,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: c.library == null
              ? Center(
                  child: c.error == null
                      ? const ShadSpinner()
                      : Text(
                          c.error!,
                          style: ShadTheme.of(context).textTheme.muted,
                        ),
                )
              : narrow && (_editing != null || _selected != null)
              ? _detailPane(context, showBack: true)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: narrow ? width : 260,
                      child: _list(context),
                    ),
                    if (!narrow) ...[
                      const SizedBox(width: 16),
                      Expanded(child: _detailPane(context)),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ list

  Widget _list(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final lib = c.library!;
    List<StyleGuideView> of(String source) => [
      for (final g in lib.guides)
        if (g.source == source) g,
    ];
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(
        text,
        style: theme.textTheme.muted.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final mine = of('mine');
    final org = of('organization');
    final doc = of('document');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey<String>('dialog.styleGuides.list'),
            children: [
              if (_forDocument)
                _row(
                  context,
                  ref: noStyleGuideRef,
                  name: l.styleGuideNone,
                  inUse: lib.documentRef == null && lib.effectiveRef == null,
                ),
              header(l.styleGuideSectionBuiltIn),
              for (final g in of('builtIn')) _guideRow(context, g),
              header(l.styleGuideSectionMine),
              if (mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l.styleGuideMineEmpty,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ),
              for (final g in mine) _guideRow(context, g),
              if (org.isNotEmpty || lib.orgKey != null) ...[
                header(l.styleGuideSectionOrganization(lib.orgKey ?? '')),
                for (final g in org) _guideRow(context, g),
              ],
              if (doc.isNotEmpty) ...[
                header(l.styleGuideSectionDocument),
                for (final g in doc) _guideRow(context, g),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        ShadButton.outline(
          key: const ValueKey<String>('dialog.styleGuides.new'),
          size: ShadButtonSize.sm,
          leading: const Icon(LucideIcons.plus, size: 14),
          enabled: !_busy,
          onPressed: _newGuide,
          child: Text(l.styleGuideNew),
        ),
      ],
    );
  }

  Widget _guideRow(BuildContext context, StyleGuideView g) {
    final lib = c.library!;
    return _row(
      context,
      ref: g.ref,
      name: g.name,
      inUse: _forDocument && lib.effectiveRef == g.ref,
      orgDefault: lib.orgDefaultRef == g.ref,
    );
  }

  Widget _row(
    BuildContext context, {
    required String ref,
    required String name,
    bool inUse = false,
    bool orgDefault = false,
  }) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = WonkyAppLocalizations.of(context);
    final selected = _editing == null && _selected == ref;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        key: ValueKey<String>('dialog.styleGuides.item.$ref'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _editing = null;
          _selected = ref;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? cs.accent : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small,
                ),
              ),
              if (orgDefault)
                ShadTooltip(
                  builder: (_) => Text(l.styleGuideOrgDefault),
                  child: Icon(
                    LucideIcons.building2,
                    size: 13,
                    color: cs.mutedForeground,
                  ),
                ),
              if (inUse) ...[
                const SizedBox(width: 6),
                ShadTooltip(
                  builder: (_) => Text(l.styleGuideInUse),
                  child: Icon(LucideIcons.check, size: 14, color: cs.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- detail

  Widget _detailPane(BuildContext context, {bool showBack = false}) {
    final l = WonkyAppLocalizations.of(context);
    final body = _editing != null ? _editor(context) : _detail(context);
    if (!showBack) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ShadButton.ghost(
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.chevronLeft, size: 14),
            onPressed: () => setState(() {
              _editing = null;
              _selected = null;
            }),
            child: Text(l.actionBack),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _detail(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final lib = c.library!;
    final ref = _selected;
    if (ref == null) return const SizedBox.shrink();
    if (ref == noStyleGuideRef) {
      final inUse = lib.documentRef == null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(l.styleGuideNone, style: theme.textTheme.large),
          Text(
            lib.orgDefaultRef == null
                ? l.styleGuideNoneHint
                : l.styleGuideNoneOrgHint(
                    c.byRef(lib.orgDefaultRef)?.name ?? '',
                  ),
            style: theme.textTheme.muted,
          ),
          if (lib.canSetDocument)
            ShadButton(
              key: const ValueKey<String>('dialog.styleGuides.useNone'),
              size: ShadButtonSize.sm,
              enabled: !_busy && !inUse,
              onPressed: () => unawaited(_useForDocument(null)),
              child: Text(inUse ? l.styleGuideInUse : l.styleGuideUseNone),
            ),
        ],
      );
    }
    final g = c.byRef(ref);
    if (g == null) return const SizedBox.shrink();
    final inUse = lib.documentRef == g.ref;
    final isDefault = lib.orgDefaultRef == g.ref;
    final canBeDefault =
        lib.canSetOrgDefault && (g.source == 'builtIn' || g.sharedWithOrg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Text(g.name, style: theme.textTheme.large),
        if (g.description.isNotEmpty)
          Text(g.description, style: theme.textTheme.muted),
        if (g.ownerName != null)
          Text(
            l.styleGuideByOwner(g.ownerName!),
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (_forDocument && lib.canSetDocument)
              ShadButton(
                key: const ValueKey<String>('dialog.styleGuides.use'),
                size: ShadButtonSize.sm,
                enabled: !_busy && !inUse,
                leading: Icon(
                  inUse ? LucideIcons.check : LucideIcons.fileCheck,
                  size: 14,
                ),
                onPressed: () => unawaited(_useForDocument(g.ref)),
                child: Text(inUse ? l.styleGuideInUse : l.styleGuideUse),
              ),
            if (canBeDefault)
              ShadButton.outline(
                key: const ValueKey<String>('dialog.styleGuides.orgDefault'),
                size: ShadButtonSize.sm,
                enabled: !_busy,
                onPressed: () => unawaited(
                  _run(() => c.setOrgDefault(isDefault ? null : g.ref)),
                ),
                child: Text(
                  isDefault
                      ? l.styleGuideClearOrgDefault
                      : l.styleGuideSetOrgDefault,
                ),
              ),
            ShadButton.outline(
              key: const ValueKey<String>('dialog.styleGuides.duplicate'),
              size: ShadButtonSize.sm,
              enabled: !_busy,
              onPressed: () => _edit(
                StyleGuideInput(
                  name: l.styleGuideCopyName(g.name),
                  description: g.description,
                  markdown: g.markdown,
                  shareWithOrg: false,
                ),
              ),
              child: Text(l.styleGuideDuplicate),
            ),
            if (g.editable) ...[
              ShadButton.outline(
                key: const ValueKey<String>('dialog.styleGuides.edit'),
                size: ShadButtonSize.sm,
                enabled: !_busy,
                onPressed: () => _edit(StyleGuideLibraryController.inputOf(g)),
                child: Text(l.actionEdit),
              ),
              ShadButton.ghost(
                key: const ValueKey<String>('dialog.styleGuides.delete'),
                size: ShadButtonSize.sm,
                enabled: !_busy,
                onPressed: () => unawaited(
                  _run(() async {
                    await c.delete(g);
                    if (mounted) setState(() => _selected = null);
                  }),
                ),
                child: Text(l.actionDelete),
              ),
            ],
          ],
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: WonkyMarkdown(g.markdown, profile: MarkdownProfile.post),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editor(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final org = c.library?.orgKey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        ShadInput(
          key: const ValueKey<String>('dialog.styleGuides.name'),
          controller: _name,
          maxLength: 100,
          placeholder: Text(l.styleGuideName),
        ),
        ShadInput(
          key: const ValueKey<String>('dialog.styleGuides.description'),
          controller: _description,
          maxLength: 300,
          placeholder: Text(l.styleGuideDescriptionField),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: MarkdownComposer(
              fieldKey: 'dialog.styleGuides.markdown',
              controller: _markdown,
              profile: MarkdownProfile.post,
              maxLength: 50000,
              minLines: 10,
              maxLines: 40,
              hint: l.styleGuideMarkdownHint,
            ),
          ),
        ),
        if (org != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ShadCheckbox(
              key: const ValueKey<String>('dialog.styleGuides.share'),
              value: _share,
              onChanged: (v) => setState(() => _share = v),
              label: Text(l.styleGuideShareWithOrg(org)),
            ),
          )
        else
          Text(
            l.styleGuidePersonalOnly,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
        if (_formError != null)
          Text(
            _formError!,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 6,
          children: [
            ShadButton.outline(
              key: const ValueKey<String>('dialog.styleGuides.cancel'),
              size: ShadButtonSize.sm,
              onPressed: () => setState(() => _editing = null),
              child: Text(l.actionCancel),
            ),
            ShadButton(
              key: const ValueKey<String>('dialog.styleGuides.save'),
              size: ShadButtonSize.sm,
              enabled: !_busy,
              onPressed: () => unawaited(_save()),
              child: Text(l.actionSave),
            ),
          ],
        ),
      ],
    );
  }
}
