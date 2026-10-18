import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../config/home_scope.dart';
import '../data/api.dart';
import '../data/models_ext.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/page_frame.dart';
import '../shell/shell_services.dart';
import 'drive_format.dart';

String templateCategoryLabel(WonkyAppLocalizations l, TemplateCategory c) =>
    switch (c) {
      TemplateCategory.personal => l.templatePersonal,
      TemplateCategory.work => l.templateWork,
      TemplateCategory.education => l.templateEducation,
      TemplateCategory.projectManagement => l.templateProjectManagement,
      TemplateCategory.finance => l.templateFinance,
    };

Future<void> _createFrom(
  BuildContext context,
  ShellServices s,
  TemplateView? t, {
  DriveItemKind? kind,
}) async {
  if (s.creatingFile.value) return;
  s.creatingFile.value = true;
  final l = WonkyAppLocalizations.of(context);
  final k = t?.kind ?? kind ?? s.config.primaryKind;
  try {
    if (k != null && k != s.config.primaryKind) {
      // Another app's kind (Wonky Drive's gallery): that app's `/new` route
      // creates it (suite 03 §2, Drive 04 §5).
      await s.crossApp.open(
        appForKind(k),
        NewItemRequest(
          folderUuid: s.currentFolder.value?.uuid,
          templateUuid: t?.uuid,
        ).path,
      );
      return;
    }
    final uuid = await s.config.createItem(
      s,
      parentUuid: s.currentFolder.value?.uuid,
      templateUuid: t?.uuid,
      name: t?.name,
    );
    if (uuid != null) {
      s.router.go(s.config.itemPath(uuid.uuid));
    }
  } catch (e) {
    s.toasts.error(l.errorGeneric, description: errorMessage(e));
    rethrow;
  } finally {
    s.creatingFile.value = false;
  }
}

/// A template preview card.
class TemplateCard extends StatefulWidget {
  const TemplateCard({
    super.key,
    required this.services,
    this.template,
    this.kind,
    this.width = 148,
  });

  final ShellServices services;

  /// null = Blank.
  final TemplateView? template;

  /// The kind of a Blank card (default: the app's kind; Drive's gallery
  /// shows one per kind).
  final DriveItemKind? kind;
  final double width;

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  bool _creating = false;

  Future<void> _handleTap() async {
    if (_creating || widget.services.creatingFile.value) return;
    setState(() => _creating = true);
    try {
      await _createFrom(
        context,
        widget.services,
        widget.template,
        kind: widget.kind,
      );
    } catch (_) {
      // Handled in _createFrom (shows error toast)
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final t = widget.template;
    final style = t?.previewStyle;
    final dark = theme.brightness == Brightness.dark;
    // (v2) Presentation cards are slide-shaped (16:9) and a little wider.
    final slide =
        (t?.kind ?? widget.kind ?? widget.services.config.primaryKind) ==
        DriveItemKind.presentation;
    final width = slide ? widget.width * 1.4 : widget.width;
    // The preview area inside the 1 px border is exactly 16:9.
    final height = slide ? (width - 2) * 9 / 16 + 2 : width * 1.25;

    return ListenableBuilder(
      listenable: widget.services.creatingFile,
      builder: (context, _) {
        final disabled = _creating || widget.services.creatingFile.value;
        final previewContent = t == null
            ? Center(
                child: _creating
                    ? const ShadSpinner()
                    : Icon(
                        LucideIcons.plus,
                        size: 40,
                        color: widget.services.config.brandColor,
                      ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  widget.services.config.templatePreview(
                        context,
                        t,
                        width: width - 2,
                        height: height - 2,
                      ) ??
                      (slide
                          ? _SlideThumbnail(text: t.previewText, style: style)
                          // Clipped, not scrolled: a miniature never
                          // scrolls.
                          : _TemplateThumbnail(
                              text: t.previewText,
                              style: style,
                            )),
                  if (_creating)
                    Container(
                      color: dark
                          ? const Color(0x99000000)
                          : const Color(0x99FFFFFF),
                      child: const Center(child: ShadSpinner()),
                    ),
                ],
              );

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: disabled && !_creating ? 0.6 : 1.0,
          child: SizedBox(
            width: width,
            child: Semantics(
              button: !disabled,
              enabled: !disabled,
              label: t?.name ?? l.templateBlank,
              child: GestureDetector(
                key: ValueKey<String>(
                  'drive.template.${t?.key ?? t?.uuid.uuid ?? (widget.kind == null ? 'blank' : 'blank.${widget.kind!.name}')}',
                ),
                onTap: disabled ? null : _handleTap,
                child: MouseRegion(
                  cursor: disabled
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: height,
                        width: width,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: style == null
                              ? theme.colorScheme.page
                              : _hex(dark ? style.darkPaper : style.paper),
                          border: Border.all(color: theme.colorScheme.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: previewContent,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t?.name ??
                            (widget.kind == null
                                ? l.templateBlank
                                : '${l.templateBlank} · ${describeKind(l, widget.kind!).toLowerCase()}'),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small,
                      ),
                      if (t != null)
                        Text(
                          templateCategoryLabel(l, t.category),
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _hex(String hex) =>
    Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);

/// A miniature page of a template's first lines (the server sends one line
/// per block, headings prefixed with "#"), drawn in the colors and with the
/// traits of the template's theme ([TemplatePreviewStyle]).
class _TemplateThumbnail extends StatelessWidget {
  const _TemplateThumbnail({required this.text, this.style});

  final String text;
  final TemplatePreviewStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final st = style;
    final fg = st == null
        ? theme.colorScheme.mutedForeground
        : _hex(dark ? st.darkText : st.text);
    final headingColor = st == null
        ? theme.colorScheme.foreground
        : _hex(dark ? st.darkHeading : st.heading);
    final accent = st == null ? null : _hex(dark ? st.darkAccent : st.accent);
    final family = switch (st?.fontCategory) {
      'serif' => const ['EB Garamond', 'Georgia', 'serif'],
      'mono' => const ['JetBrains Mono', 'Menlo', 'monospace'],
      _ => null,
    };
    final centered = st?.centeredHeadings ?? false;
    final lines = text.split('\n');
    var first = true;
    final children = <Widget>[];
    for (final line in lines) {
      if (line.startsWith('# ')) {
        final label = line.substring(2);
        children.add(
          Padding(
            padding: EdgeInsets.only(top: first ? 0 : 4, bottom: 2),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                st?.uppercaseHeadings ?? false ? label.toUpperCase() : label,
                maxLines: 2,
                overflow: TextOverflow.clip,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: first ? 10 : 7.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: headingColor,
                  fontFamilyFallback: family,
                ),
              ),
            ),
          ),
        );
        if (first && accent != null && !(st?.banner ?? false)) {
          // A short rule under the title in the accent color.
          children.add(
            Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 3),
                color: accent,
              ),
            ),
          );
        }
      } else {
        children.add(
          Text(
            line,
            maxLines: 2,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: 6.5,
              height: 1.45,
              color: fg.withValues(alpha: st == null ? 1 : 0.85),
              fontFamilyFallback: family,
            ),
          ),
        );
      }
      first = false;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (st?.banner ?? false) Container(height: 10, color: accent),
        Expanded(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// (v2) A miniature title slide of a presentation template without an
/// app-provided preview (Wonky Drive's gallery): the first `# ` line as the
/// title over an accent rule, the next line as the subtitle, in the colors
/// of the template's Slides theme.
class _SlideThumbnail extends StatelessWidget {
  const _SlideThumbnail({required this.text, this.style});

  final String text;
  final TemplatePreviewStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final st = style;
    final heading = st == null
        ? theme.colorScheme.foreground
        : _hex(dark ? st.darkHeading : st.heading);
    final fg = st == null
        ? theme.colorScheme.mutedForeground
        : _hex(dark ? st.darkText : st.text);
    final accent = st == null
        ? theme.colorScheme.primary
        : _hex(dark ? st.darkAccent : st.accent);
    final family = switch (st?.fontCategory) {
      'serif' => const ['EB Garamond', 'Georgia', 'serif'],
      'mono' => const ['JetBrains Mono', 'Menlo', 'monospace'],
      _ => null,
    };
    final lines = text.split('\n');
    final title = lines.first.replaceFirst(RegExp(r'^# '), '');
    final subtitle = lines.length > 1 ? lines[1] : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: heading,
              fontFamilyFallback: family,
            ),
          ),
          Container(
            width: 22,
            height: 2,
            margin: const EdgeInsets.symmetric(vertical: 5),
            color: accent,
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 7.5,
              height: 1.3,
              color: fg,
              fontFamilyFallback: family,
            ),
          ),
        ],
      ),
    );
  }
}

/// The collapsible "Start a new …" strip on Home (suite 05 §3.1).
class TemplateStrip extends StatefulWidget {
  const TemplateStrip({super.key, required this.services});

  final ShellServices services;

  @override
  State<TemplateStrip> createState() => _TemplateStripState();
}

class _TemplateStripState extends State<TemplateStrip> {
  late final Future<List<TemplateView>> _templates = widget.services.drive
      .listTemplates(widget.services.config.primaryKind);

  bool get _hidden =>
      widget.services.prefs.device<bool>('drive.templatesHidden') ?? false;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final s = widget.services;
    return Container(
      color: theme.colorScheme.canvas,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.templateStripTitle(
                    describeKind(
                      l,
                      s.config.primaryKind ?? DriveItemKind.document,
                    ).toLowerCase(),
                  ),
                  style: theme.textTheme.small,
                ),
              ),
              Flexible(
                child: ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () => s.router.go('/templates'),
                  trailing: const Icon(LucideIcons.chevronsUpDown, size: 14),
                  child: Flexible(
                    child: Text(
                      l.templateGallery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              ShadTooltip(
                builder: (_) =>
                    Text(_hidden ? l.templatesShow : l.templatesHide),
                child: ShadIconButton.ghost(
                  key: const ValueKey<String>('drive.templates.toggle'),
                  width: 28,
                  height: 28,
                  iconSize: 16,
                  semanticLabel: _hidden ? l.templatesShow : l.templatesHide,
                  icon: Icon(
                    _hidden ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                  ),
                  onPressed: () async {
                    await s.prefs.setDevice('drive.templatesHidden', !_hidden);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),
          if (!_hidden) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: FutureBuilder<List<TemplateView>>(
                future: _templates,
                builder: (context, snap) {
                  final list = snap.data ?? const <TemplateView>[];
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      TemplateCard(services: s),
                      for (final t in list.take(6)) ...[
                        const SizedBox(width: 16),
                        TemplateCard(services: s, template: t),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `/templates` — all templates by category.
class TemplateGalleryScreen extends StatelessWidget {
  const TemplateGalleryScreen({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return ShellPageFrame(
      services: services,
      title: l.templateGallery,
      child: FutureBuilder<List<TemplateView>>(
        future: services.drive.listTemplates(services.config.primaryKind),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: ShadSpinner());
          }
          if (snap.hasError) {
            return WonkyEmptyState(
              illustration: EmptyIllustration.error,
              title: l.errorGeneric,
              description: errorMessage(snap.error!),
            );
          }
          final byCat = <TemplateCategory, List<TemplateView>>{};
          for (final t in snap.data!) {
            byCat.putIfAbsent(t.category, () => []).add(t);
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Drive creates every kind: one Blank card per kind.
                  if (services.config.primaryKind == null)
                    for (final k
                        in services.config.homeScope?.newKinds ??
                            const [DriveItemKind.document])
                      TemplateCard(services: services, kind: k)
                  else
                    TemplateCard(services: services),
                ],
              ),
              for (final cat in TemplateCategory.values)
                if (byCat[cat] != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    templateCategoryLabel(l, cat),
                    style: theme.textTheme.h4,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final t in byCat[cat]!)
                        TemplateCard(services: services, template: t),
                    ],
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}
